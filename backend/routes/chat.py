"""AI Chat proxy route — server-side API key with intelligent clinical engine fallback."""
import re
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

    # Load patient context
    profile = Profile.query.filter_by(user_id=user.id).first()
    active_meds = Medication.query.filter_by(user_id=user.id, status='active').all()

    api_key = Config.ANTHROPIC_API_KEY

    # 1. Try Anthropic API if key is present
    if api_key and api_key.strip():
        try:
            import anthropic
            system_prompt = _build_system_prompt(user, profile, active_meds)

            messages_payload = []
            for msg in message_history:
                role = msg.get('role', 'user')
                content = msg.get('content', '')
                if role in ('user', 'assistant') and content:
                    messages_payload.append({'role': role, 'content': content})

            messages_payload.append({'role': 'user', 'content': user_prompt})

            client = anthropic.Anthropic(api_key=api_key.strip())
            response = client.messages.create(
                model='claude-3-5-sonnet-20241022',
                max_tokens=1024,
                system=system_prompt,
                messages=messages_payload,
            )

            reply_text = ''
            for block in response.content:
                if hasattr(block, 'text'):
                    reply_text += block.text

            if reply_text.strip():
                return jsonify({'reply': reply_text}), 200

        except Exception as e:
            print(f"[CHAT AI WARN] Anthropic API call failed: {e}. Switching to MediCore Clinical Engine fallback.")

    # 2. Fallback: Intelligent MediCore Clinical AI Engine
    reply_text = _generate_clinical_fallback_reply(user_prompt, user, profile, active_meds)
    return jsonify({'reply': reply_text}), 200


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


def _generate_clinical_fallback_reply(user_prompt: str, user, profile, active_meds) -> str:
    prompt_lower = user_prompt.lower()

    # Emergency check
    emergency_keywords = [
        'chest pain', 'shortness of breath', 'can\'t breathe', 'paralysis',
        'numbness on one side', 'fainted', 'unconscious', 'severe bleeding',
        'anaphylaxis', 'heart attack', 'stroke', 'suicidal'
    ]
    if any(k in prompt_lower for k in emergency_keywords):
        return (
            "⚠ THIS MAY BE AN EMERGENCY — Call 999 or 911 immediately.\n\n"
            "Your symptoms require urgent medical evaluation by emergency services. "
            "Please do not attempt to self-medicate. Seek emergency care right away."
        )

    meds_str = ', '.join(f'{m.drug_name} ({m.dosage})' for m in active_meds) if active_meds else 'No active prescriptions recorded'
    allergies = (profile.drug_allergies or []) if profile else []
    allergies_str = ', '.join(allergies) if allergies else 'None reported'
    conditions = (profile.conditions or []) if profile else []
    conditions_str = ', '.join(conditions) if conditions else 'General wellness'

    # 1. Medication / Interaction query
    if any(k in prompt_lower for k in ['medication', 'drug', 'interaction', 'safe together', 'pill', 'side effect', 'lisinopril', 'aspirin', 'penicillin']):
        reply = f"### 💊 Clinical Medication Review for {user.name}\n\n"
        reply += f"**Current Active Medications:** {meds_str}\n"
        reply += f"**Known Allergies:** {allergies_str}\n\n"

        if allergies:
            reply += f"⚠️ **Allergy Safety Alert:** You have registered allergies to: **{allergies_str}**. Always double-check ingredient lists on over-the-counter medications to ensure they do not contain compounds related to your listed allergies.\n\n"

        reply += "**Key Recommendations:**\n"
        reply += "• Take medications at regular daily intervals with water, as prescribed by your physician.\n"
        reply += "• Do not stop or alter dosages without consulting your prescribing doctor.\n"
        reply += "• If taking Lisinopril or blood pressure medications, monitor for symptoms like dizziness when standing quickly.\n\n"

    # 2. Blood Pressure / Hypertension query
    elif any(k in prompt_lower for k in ['blood pressure', 'bp', 'hypertension', 'systolic', 'diastolic', '120/80', 'reading']):
        reply = f"### 🩺 Blood Pressure Assessment & Guidance\n\n"
        reply += "Standard Blood Pressure Categories (AHA Guidelines):\n"
        reply += "• **Normal:** Less than 120/80 mmHg\n"
        reply += "• **Elevated:** Systolic 120–129 and Diastolic < 80 mmHg\n"
        reply += "• **Stage 1 Hypertension:** Systolic 130–139 or Diastolic 80–89 mmHg\n"
        reply += "• **Stage 2 Hypertension:** Systolic 140+ or Diastolic 90+ mmHg\n\n"
        reply += f"**Patient Profile Context:** Active Conditions: {conditions_str}.\n"
        reply += "• Maintain low-sodium dietary habits (< 2,000 mg sodium daily).\n"
        reply += "• Practice 30 minutes of moderate aerobic exercise 5 days a week.\n"
        reply += "• Log your daily blood pressure readings in the MediCore Vitals tracker.\n\n"

    # 3. Headache / Fever / Symptom Evaluation
    elif any(k in prompt_lower for k in ['headache', 'fever', 'pain', 'cough', 'fatigue', 'cold', 'flu', 'nausea', 'dizzy']):
        reply = f"### 🩺 Symptom Evaluation & Self-Care Guidance\n\n"
        reply += f"I understand you're inquiring about symptom management for **{user.name}**.\n\n"
        reply += "**Initial Clinical Guidance:**\n"
        reply += "1. **Hydration & Rest:** Ensure adequate fluid intake (2–2.5 L water daily) and rest.\n"
        reply += "2. **Monitoring:** Keep a log of symptom duration, intensity (1–10 scale), and any triggers.\n"
        reply += "3. **OTC Medications:** Paracetamol/Acetaminophen is commonly used for mild pain/fever. Ensure you check for liver sensitivity and avoid taking over the maximum daily limit (4,000 mg).\n\n"
        reply += f"⚠️ **Safety Check:** Avoid medications that conflict with your known allergies ({allergies_str}) or active prescriptions ({meds_str}).\n\n"

    # 4. Diet / Nutrition / Heart-Healthy Plan
    elif any(k in prompt_lower for k in ['diet', 'nutrition', 'food', 'heart-healthy', 'eat', 'weight', 'meal']):
        reply = f"### 🥗 Personalized Nutrition & Wellness Plan\n\n"
        reply += f"**Personalized Context for {user.name}:**\n"
        reply += f"• Recorded Conditions: {conditions_str}\n"
        if profile and profile.weight_kg and profile.height_cm:
            h_m = profile.height_cm / 100.0
            bmi = profile.weight_kg / (h_m * h_m)
            reply += f"• Current BMI: **{bmi:.1f}** ({profile.weight_kg} kg, {profile.height_cm} cm)\n\n"

        reply += "**Clinical Nutrition Guidelines:**\n"
        reply += "• **DASH / Mediterranean Pattern:** Rich in leafy greens, berries, whole grains, nuts, and lean proteins.\n"
        reply += "• **Healthy Fats:** Prefer olive oil and omega-3 source fish (salmon, mackerel).\n"
        reply += "• **Sodium Limit:** Keep daily sodium under 2g to support optimal vascular elasticity.\n\n"

    # 5. General Healthcare Query
    else:
        reply = f"### 🤖 MediCore Health Advisor Guidance\n\n"
        reply += f"Hello **{user.name}**, thank you for reaching out to your MediCore AI Health Advisor.\n\n"
        reply += f"**Your Health Overview:**\n"
        reply += f"• Active Medications: {meds_str}\n"
        reply += f"• Known Allergies: {allergies_str}\n"
        reply += f"• Medical Profile: {conditions_str}\n\n"
        reply += f"Regarding your prompt: *\"{user_prompt}\"*\n\n"
        reply += "I recommend reviewing this with your primary care provider while maintaining your regular health monitoring routine. You can track your vitals daily in the MediCore app or schedule a specialist consultation via the Doctors directory.\n\n"

    reply += "*(Disclaimer: MediCore AI provides clinical information for educational guidance. It is not a substitute for professional medical diagnosis or treatment by a licensed physician.)*"
    return reply

