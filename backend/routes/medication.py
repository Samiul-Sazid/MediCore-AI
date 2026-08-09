"""Medication CRUD routes."""
from datetime import datetime
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import Medication
from middleware import token_required

medication_bp = Blueprint('medication', __name__, url_prefix='/api/prescription')


@medication_bp.route('/medications', methods=['GET'])
@token_required
def list_medications():
    user = g.current_user
    status = request.args.get('status')

    query = Medication.query.filter_by(user_id=user.id)
    if status:
        query = query.filter_by(status=status)

    meds = query.order_by(Medication.created_at.desc()).all()
    return jsonify([m.to_dict() for m in meds]), 200


@medication_bp.route('/medications', methods=['POST'])
@token_required
def add_medication():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    drug_name = (data.get('drug_name') or '').strip()
    if not drug_name:
        return jsonify({'error': 'Drug name is required.'}), 400

    med = Medication(
        user_id=user.id,
        drug_name=drug_name,
        dosage=(data.get('dosage') or '').strip(),
        frequency=(data.get('frequency') or '').strip(),
        when_to_take=(data.get('when_to_take') or '').strip(),
        prescribed_by=(data.get('prescribed_by') or '').strip(),
        start_date=datetime.utcnow(),
        status='active',
        notes=(data.get('notes') or '').strip(),
        duration=(data.get('duration') or '').strip(),
    )
    db.session.add(med)
    db.session.commit()

    return jsonify(med.to_dict()), 201


@medication_bp.route('/medications/<int:med_id>', methods=['PUT'])
@token_required
def update_medication(med_id):
    user = g.current_user
    med = Medication.query.filter_by(id=med_id, user_id=user.id).first()
    if not med:
        return jsonify({'error': 'Medication not found.'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    if 'drug_name' in data:
        med.drug_name = data['drug_name']
    if 'dosage' in data:
        med.dosage = data['dosage']
    if 'frequency' in data:
        med.frequency = data['frequency']
    if 'when_to_take' in data:
        med.when_to_take = data['when_to_take']
    if 'prescribed_by' in data:
        med.prescribed_by = data['prescribed_by']
    if 'status' in data:
        med.status = data['status']
        if data['status'] == 'stopped':
            med.end_date = datetime.utcnow()
    if 'stop_reason' in data:
        med.stop_reason = data['stop_reason']
    if 'notes' in data:
        med.notes = data['notes']

    db.session.commit()
    return jsonify(med.to_dict()), 200


@medication_bp.route('/medications/<int:med_id>', methods=['DELETE'])
@token_required
def delete_medication(med_id):
    user = g.current_user
    med = Medication.query.filter_by(id=med_id, user_id=user.id).first()
    if not med:
        return jsonify({'error': 'Medication not found.'}), 404

    db.session.delete(med)
    db.session.commit()
    return jsonify({'message': 'Medication deleted.'}), 200
