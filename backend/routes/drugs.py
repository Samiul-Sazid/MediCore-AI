"""Drug interaction checking route — 3-layer system: Local DB + OpenFDA + AI."""
import requests
from flask import Blueprint, request as flask_request, jsonify, g
from models import DrugInteraction, Medication
from middleware import token_required
from config import Config

drugs_bp = Blueprint('drugs', __name__, url_prefix='/api/drugs')


@drugs_bp.route('/check-interaction', methods=['POST'])
@token_required
def check_interaction():
    user = g.current_user
    data = flask_request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    new_drug = (data.get('drug_name') or '').strip()
    if not new_drug:
        return jsonify({'error': 'drug_name is required.'}), 400

    # Get user's active meds and allergies
    active_meds = Medication.query.filter_by(user_id=user.id, status='active').all()
    active_drug_names = [m.drug_name for m in active_meds]

    from models import Profile
    profile = Profile.query.filter_by(user_id=user.id).first()
    drug_allergies = profile.drug_allergies if profile else []

    results = {
        'drug': new_drug,
        'allergy_conflicts': [],
        'local_interactions': [],
        'fda_interactions': [],
        'ai_analysis': '',
    }

    # ── Layer 1: Allergy check ──
    for allergy in drug_allergies:
        if _fuzzy_match(new_drug, allergy):
            results['allergy_conflicts'].append({
                'severity': 'critical',
                'title': 'DIRECT ALLERGY CONFLICT ⚠',
                'description': f'The medication "{new_drug}" matches your documented allergy to "{allergy}". Administration may trigger severe allergic response or anaphylaxis.',
                'source': 'Patient Profile',
            })

    # ── Layer 2: Local DB interactions ──
    new_drug_lower = new_drug.lower()
    for med_name in active_drug_names:
        med_lower = med_name.lower()
        interactions = DrugInteraction.query.filter(
            ((DrugInteraction.drug_a.ilike(f'%{new_drug_lower}%')) & (DrugInteraction.drug_b.ilike(f'%{med_lower}%'))) |
            ((DrugInteraction.drug_a.ilike(f'%{med_lower}%')) & (DrugInteraction.drug_b.ilike(f'%{new_drug_lower}%')))
        ).all()

        for inter in interactions:
            results['local_interactions'].append({
                'severity': inter.severity,
                'title': inter.title,
                'mechanism': inter.mechanism,
                'recommendation': inter.recommendation,
                'drug_a': new_drug,
                'drug_b': med_name,
                'source': inter.source,
            })

    # ── Layer 3: OpenFDA adverse events (best-effort) ──
    try:
        fda_results = _check_openfda(new_drug, active_drug_names)
        results['fda_interactions'] = fda_results
    except Exception:
        results['fda_interactions'] = []

    # ── Layer 4: AI analysis (if API key available) ──
    if Config.ANTHROPIC_API_KEY and active_drug_names:
        try:
            results['ai_analysis'] = _ai_interaction_check(
                new_drug, active_drug_names, drug_allergies
            )
        except Exception:
            results['ai_analysis'] = ''

    return jsonify(results), 200


@drugs_bp.route('/check-pair', methods=['POST'])
@token_required
def check_pair():
    """Check interaction between two specific drugs."""
    data = flask_request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    drug_a = (data.get('drug_a') or '').strip()
    drug_b = (data.get('drug_b') or '').strip()

    if not drug_a or not drug_b:
        return jsonify({'error': 'Both drug_a and drug_b are required.'}), 400

    interactions = DrugInteraction.query.filter(
        ((DrugInteraction.drug_a.ilike(f'%{drug_a.lower()}%')) & (DrugInteraction.drug_b.ilike(f'%{drug_b.lower()}%'))) |
        ((DrugInteraction.drug_a.ilike(f'%{drug_b.lower()}%')) & (DrugInteraction.drug_b.ilike(f'%{drug_a.lower()}%')))
    ).all()

    return jsonify([i.to_dict() for i in interactions]), 200


def _fuzzy_match(drug_name: str, allergy: str) -> bool:
    d = drug_name.strip().lower()
    a = allergy.strip().lower()
    return d in a or a in d


def _check_openfda(new_drug: str, active_drugs: list) -> list:
    """Query OpenFDA for adverse event reports involving the drug combination."""
    results = []
    for existing_drug in active_drugs[:5]:  # Limit to avoid too many API calls
        try:
            url = 'https://api.fda.gov/drug/event.json'
            search = f'patient.drug.openfda.generic_name:"{new_drug}"+AND+patient.drug.openfda.generic_name:"{existing_drug}"'
            params = {'search': search, 'limit': 3}
            resp = requests.get(url, params=params, timeout=5)
            if resp.status_code == 200:
                data = resp.json()
                total = data.get('meta', {}).get('results', {}).get('total', 0)
                if total > 0:
                    reactions = set()
                    for result in data.get('results', [])[:3]:
                        for reaction in result.get('patient', {}).get('reaction', []):
                            term = reaction.get('reactionmeddrapt', '')
                            if term:
                                reactions.add(term)

                    if reactions:
                        results.append({
                            'drug_a': new_drug,
                            'drug_b': existing_drug,
                            'fda_reports': total,
                            'reported_reactions': list(reactions)[:5],
                            'severity': 'high' if total > 100 else 'medium' if total > 10 else 'low',
                            'source': 'FDA FAERS',
                        })
        except Exception:
            continue

    return results


def _ai_interaction_check(new_drug: str, active_drugs: list, allergies: list) -> str:
    """Use Claude AI for a plain-language interaction analysis."""
    try:
        import anthropic
        client = anthropic.Anthropic(api_key=Config.ANTHROPIC_API_KEY)

        prompt = f"""As a clinical pharmacist, briefly analyze the safety of adding "{new_drug}" for a patient currently taking: {', '.join(active_drugs)}.
Patient allergies: {', '.join(allergies) if allergies else 'None reported'}.

Provide a concise safety summary (2-3 sentences) focusing on:
1. Any significant drug interactions
2. Any allergy concerns
3. Whether it's generally safe to take together

Be direct and clinical. If there are serious concerns, start with "⚠ CAUTION:"."""

        response = client.messages.create(
            model='claude-sonnet-4-20250514',
            max_tokens=300,
            messages=[{'role': 'user', 'content': prompt}],
        )

        for block in response.content:
            if hasattr(block, 'text'):
                return block.text

    except Exception:
        pass

    return ''
