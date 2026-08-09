"""Patient profile routes."""
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import Profile
from middleware import token_required

patient_bp = Blueprint('patient', __name__, url_prefix='/api/patient')


@patient_bp.route('/profile', methods=['GET'])
@token_required
def get_profile():
    user = g.current_user
    profile = Profile.query.filter_by(user_id=user.id).first()
    if not profile:
        profile = Profile(user_id=user.id)
        db.session.add(profile)
        db.session.commit()

    result = profile.to_dict()
    result['name'] = user.name
    result['email'] = user.email
    return jsonify(result), 200


@patient_bp.route('/profile', methods=['POST', 'PUT'])
@token_required
def update_profile():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    profile = Profile.query.filter_by(user_id=user.id).first()
    if not profile:
        profile = Profile(user_id=user.id)
        db.session.add(profile)

    # Update fields if present
    if 'phone' in data:
        profile.phone = data['phone']
    if 'gender' in data:
        profile.gender = data['gender']
    if 'blood_type' in data or 'blood_group' in data:
        profile.blood_type = data.get('blood_type') or data.get('blood_group')
    if 'weight_kg' in data:
        profile.weight_kg = float(data['weight_kg'])
    if 'height_cm' in data:
        profile.height_cm = float(data['height_cm'])
    if 'conditions' in data:
        profile.conditions = data['conditions']
    if 'drug_allergies' in data:
        profile.drug_allergies = data['drug_allergies']
    if 'food_allergies' in data:
        profile.food_allergies = data['food_allergies']
    if 'emergency_contact_name' in data:
        profile.emergency_contact_name = data['emergency_contact_name']
    if 'emergency_contact_phone' in data:
        profile.emergency_contact_phone = data['emergency_contact_phone']
    if 'emergency_contact_relation' in data:
        profile.emergency_contact_relation = data['emergency_contact_relation']

    db.session.commit()

    result = profile.to_dict()
    result['name'] = user.name
    result['email'] = user.email
    return jsonify(result), 200
