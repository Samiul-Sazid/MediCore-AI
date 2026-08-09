"""Smartwatch vital readings routes."""
from datetime import datetime
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import VitalReading
from middleware import token_required

vitals_bp = Blueprint('vitals', __name__, url_prefix='/api/vitals')


@vitals_bp.route('/', methods=['POST'])
@token_required
def record_vital():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    reading = VitalReading(
        user_id=user.id,
        heart_rate=data.get('heart_rate') or data.get('heartRate'),
        spo2=data.get('spo2') or data.get('oxygenLevel'),
        systolic_bp=data.get('systolic_bp') or data.get('systolicBP'),
        diastolic_bp=data.get('diastolic_bp') or data.get('diastolicBP'),
        temperature_c=data.get('temperature_c') or data.get('temperatureC'),
        source=data.get('source', 'smartwatch'),
        recorded_at=datetime.utcnow(),
    )
    db.session.add(reading)
    db.session.commit()

    return jsonify(reading.to_dict()), 201


@vitals_bp.route('/', methods=['GET'])
@token_required
def list_vitals():
    user = g.current_user
    limit = min(int(request.args.get('limit', 50)), 500)

    readings = VitalReading.query.filter_by(user_id=user.id).order_by(
        VitalReading.recorded_at.desc()
    ).limit(limit).all()

    return jsonify([r.to_dict() for r in readings]), 200


@vitals_bp.route('/latest', methods=['GET'])
@token_required
def latest_vital():
    user = g.current_user
    reading = VitalReading.query.filter_by(user_id=user.id).order_by(
        VitalReading.recorded_at.desc()
    ).first()

    if not reading:
        return jsonify({'message': 'No vital readings recorded yet.'}), 404

    return jsonify(reading.to_dict()), 200
