"""Prescription upload and listing routes."""
from datetime import datetime
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import Prescription
from middleware import token_required

prescription_bp = Blueprint('prescription', __name__, url_prefix='/api/prescription')


@prescription_bp.route('/', methods=['GET'])
@token_required
def list_prescriptions():
    user = g.current_user
    prescriptions = Prescription.query.filter_by(user_id=user.id).order_by(
        Prescription.scanned_at.desc()
    ).all()
    return jsonify([p.to_dict() for p in prescriptions]), 200


@prescription_bp.route('/upload', methods=['POST'])
@token_required
def upload_prescription():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    prescription = Prescription(
        user_id=user.id,
        prescribed_by=(data.get('prescribedBy') or data.get('prescribed_by') or '').strip(),
        raw_text=(data.get('rawText') or data.get('raw_text') or '').strip(),
        drug_name=(data.get('drugName') or data.get('drug_name') or '').strip(),
        dosage=(data.get('dosage') or '').strip(),
        frequency=(data.get('frequency') or '').strip(),
        duration_days=int(data.get('durationDays', data.get('duration_days', 30))),
        confidence_score=float(data.get('confidence_score', 0.0)),
        scanned_at=datetime.utcnow(),
    )
    db.session.add(prescription)
    db.session.commit()

    return jsonify(prescription.to_dict()), 201
