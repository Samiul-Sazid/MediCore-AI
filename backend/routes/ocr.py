"""OCR prescription parsing route — uses Claude Vision for accurate extraction."""
from flask import Blueprint, request, jsonify, g
from models import Profile, Medication
from middleware import token_required
from config import Config
import base64
import json

ocr_bp = Blueprint('ocr', __name__, url_prefix='/api/ocr')


@ocr_bp.route('/parse', methods=['POST'])
@token_required
def parse_prescription():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    image_base64 = data.get('image', '').strip()
    if not image_base64:
        return jsonify({'error': 'Base64 image data is required.'}), 400

    api_key = Config.ANTHROPIC_API_KEY
    if not api_key:
        return jsonify({'error': 'AI service is not configured. Please contact the administrator.'}), 503

    # Load patient context for safety checks
    profile = Profile.query.filter_by(user_id=user.id).first()
    active_meds = Medication.query.filter_by(user_id=user.id, status='active').all()

    drug_allergies = profile.drug_allergies if profile else []
    active_drug_names = [m.drug_name for m in active_meds]

    try:
        import anthropic
        client = anthropic.Anthropic(api_key=api_key)

        # Clean up base64 string (remove data URI prefix if present)
        if ',' in image_base64:
            image_base64 = image_base64.split(',', 1)[1]

        extraction_prompt = f"""Analyze this prescription image and extract all medication information. 
Return your response as a valid JSON object with these fields:
{{
    "drugName": "the medication name",
    "dosage": "the dosage (e.g., 500mg, 10ml)",
    "frequency": "how often to take (e.g., Twice daily, Every 8 hours)",
    "instructions": "full dosing instructions from the prescription",
    "prescribedBy": "doctor name if visible",
    "durationDays": number of days for the course (integer, estimate 30 if unclear),
    "confidenceScore": your confidence in the extraction accuracy (0-100)
}}

IMPORTANT SAFETY CHECK after extraction:
- Patient has these drug allergies: {json.dumps(drug_allergies)}
- Patient currently takes: {json.dumps(active_drug_names)}
- If the extracted drug conflicts with any allergy, add: "allergyWarning": "description of the conflict"
- If the extracted drug may interact with current medications, add: "interactionWarnings": ["warning1", "warning2"]

If you cannot read the prescription clearly, still return the JSON with best guesses and set confidenceScore below 50.
Only return the JSON object, no other text."""

        response = client.messages.create(
            model='claude-sonnet-4-20250514',
            max_tokens=1024,
            messages=[
                {
                    'role': 'user',
                    'content': [
                        {
                            'type': 'image',
                            'source': {
                                'type': 'base64',
                                'media_type': _detect_media_type(image_base64),
                                'data': image_base64,
                            }
                        },
                        {
                            'type': 'text',
                            'text': extraction_prompt,
                        }
                    ]
                }
            ],
        )

        reply_text = ''
        for block in response.content:
            if hasattr(block, 'text'):
                reply_text += block.text

        # Parse JSON from response
        parsed = _extract_json(reply_text)
        if parsed:
            return jsonify(parsed), 200
        else:
            return jsonify({
                'drugName': 'Unable to parse',
                'dosage': '',
                'frequency': '',
                'instructions': reply_text[:200] if reply_text else 'No text extracted',
                'prescribedBy': '',
                'durationDays': 30,
                'confidenceScore': 0.0,
            }), 200

    except Exception as e:
        return jsonify({'error': f'OCR processing failed: {str(e)}'}), 500


def _detect_media_type(base64_str: str) -> str:
    """Detect image media type from base64 header bytes."""
    try:
        header = base64.b64decode(base64_str[:20])
        if header[:3] == b'\xff\xd8\xff':
            return 'image/jpeg'
        if header[:8] == b'\x89PNG\r\n\x1a\n':
            return 'image/png'
        if header[:4] == b'RIFF' and header[8:12] == b'WEBP':
            return 'image/webp'
        if header[:4] == b'GIF8':
            return 'image/gif'
    except Exception:
        pass
    return 'image/jpeg'  # Default fallback


def _extract_json(text: str) -> dict | None:
    """Extract JSON object from text that may contain markdown fences or surrounding text."""
    text = text.strip()

    # Try direct parse
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try extracting from markdown code block
    if '```' in text:
        import re
        match = re.search(r'```(?:json)?\s*\n?(.*?)\n?\s*```', text, re.DOTALL)
        if match:
            try:
                return json.loads(match.group(1).strip())
            except json.JSONDecodeError:
                pass

    # Try finding first { to last }
    start = text.find('{')
    end = text.rfind('}')
    if start != -1 and end != -1 and end > start:
        try:
            return json.loads(text[start:end + 1])
        except json.JSONDecodeError:
            pass

    return None
