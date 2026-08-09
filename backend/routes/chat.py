"""AI Chat proxy route — server-side API key, no client input needed."""
from flask import Blueprint, request, jsonify, g
from models import Profile, Medication
from middleware import token_required
from config import Config

chat_bp = Blueprint('chat', __name__, url_prefix='/api/chat')


@chat_bp.route('', methods=['POST'])
@token_required
def send_message():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    user_prompt = (data.get('message') or data.get('userPrompt') or '').strip()
    message_history = data.get('history', [])

    if not user_prompt:
        return jsonify({'error': 'Message text is required.'}), 400

    api_key = Config.ANTHROPIC_API_KEY
    if not api_key:
        return jsonify({'error': 'AI service is not configured. Please contact the administrator.'}), 503

    # Load patient context
    profile = Profile.query.filter_by(user_id=user.id).first()
    active_meds = Medication.query.filter_by(user_id=user.id, status='active').all()

    system_prompt = _build_system_prompt(user, profile, active_meds)

    # Build messages payload for Claude API
    messages_payload = []
    for msg in message_history:
        role = msg.get('role', 'user')
        content = msg.get('content', '')
        if role in ('user', 'assistant') and content:
            messages_payload.append({'role': role, 'content': content})

    messages_payload.append({'role': 'user', 'content': user_prompt})

    try:
        import anthropic
        client = anthropic.Anthropic(api_key=api_key)

        response = client.messages.create(
            model='claude-sonnet-4-20250514',
            max_tokens=1024,
            system=system_prompt,
            messages=messages_payload,
        )

        reply_text = ''
        for block in response.content:
            if hasattr(block, 'text'):
                reply_text += block.text

        if not reply_text:
            reply_text = 'I was unable to generate a response. Please try rephrasing your question.'

        return jsonify({'reply': reply_text}), 200

    except anthropic.AuthenticationError:
        return jsonify({'error': 'AI authentication failed. Please check the API key configuration.'}), 503
    except anthropic.RateLimitError:
        return jsonify({'error': 'AI service rate limit reached. Please try again in a moment.'}), 429
    except Exception as e:
        return jsonify({'error': f'AI service error: {str(e)}'}), 500


def _build_system_prompt(user, profile, active_meds):
    meds_list = ', '.join(
        f'{m.drug_name} ({m.dosage}, {m.frequency})' for m in active_meds
    ) if active_meds else 'None currently'

    allergies = []
    conditions = []
    gender = 'Not specified'
    blood_type = 'Unknown'
    weight = 70.0
    height = 170.0

    if profile:
        allergies = (profile.drug_allergies or []) + (profile.food_allergies or [])
        conditions = profile.conditions or []
        gender = profile.gender or 'Not specified'
        blood_type = profile.blood_type or 'Unknown'
        weight = profile.weight_kg or 70.0
        height = profile.height_cm or 170.0

    allergies_str = ', '.join(allergies) if allergies else 'None reported'
    conditions_str = ', '.join(conditions) if conditions else 'None reported'

    bmi = 0.0
    if height > 0:
        height_m = height / 100.0
        bmi = weight / (height_m * height_m) if height_m > 0 else 0.0

    return f'''You are MediCore AI, an advanced medical AI assistant created to assist patients with evidence-based health information and guidance.

PATIENT MEDICAL CONTEXT & SAFETY DATA:
- Name: {user.name}
- Gender: {gender}
- Blood Type: {blood_type}
- Weight / Height / BMI: {weight} kg, {height} cm (BMI: {bmi:.1f})
- Known Conditions: {conditions_str}
- Known Allergies: {allergies_str}
- Active Medications: {meds_list}

CRITICAL MANDATORY SAFETY RULES:
1. NEVER recommend medications or active ingredients that conflict with patient allergies: [{allergies_str}].
2. ALWAYS check potential interactions with current active medications: [{meds_list}].
3. EMERGENCY TRIGGER: If the user describes life-threatening symptoms (severe chest pain, sudden numbness/paralysis, shortness of breath, loss of consciousness, severe bleeding, anaphylaxis), your response MUST START with:
"⚠ THIS MAY BE AN EMERGENCY — Call 999 or 911 immediately."
4. Maintain a reassuring, empathetic, professional tone. Include actionable guidance and ALWAYS remind the patient that AI answers do not replace consultation with a licensed doctor.
5. When suggesting medications, always mention potential side effects and recommend consulting a healthcare provider before starting any new medication.'''
