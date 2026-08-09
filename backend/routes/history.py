"""Health history event routes."""
import json
from datetime import datetime
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import HealthEvent
from middleware import token_required

history_bp = Blueprint('history', __name__, url_prefix='/api/history')


@history_bp.route('/', methods=['GET'])
@token_required
def list_events():
    user = g.current_user
    event_type = request.args.get('type', '').strip()
    limit = min(int(request.args.get('limit', 100)), 500)

    q = HealthEvent.query.filter_by(user_id=user.id)
    if event_type:
        q = q.filter_by(type=event_type)

    events = q.order_by(HealthEvent.created_at.desc()).limit(limit).all()
    return jsonify([e.to_dict() for e in events]), 200


@history_bp.route('/', methods=['POST'])
@token_required
def create_event():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    title = (data.get('title') or '').strip()
    event_type = (data.get('type') or '').strip()
    if not title or not event_type:
        return jsonify({'error': 'type and title are required.'}), 400

    metadata = data.get('metadata', {})

    event = HealthEvent(
        user_id=user.id,
        type=event_type,
        title=title,
        description=(data.get('description') or '').strip(),
        metadata_json=json.dumps(metadata) if isinstance(metadata, dict) else '{}',
        created_at=datetime.utcnow(),
    )
    db.session.add(event)
    db.session.commit()

    return jsonify(event.to_dict()), 201


@history_bp.route('/<int:event_id>', methods=['DELETE'])
@token_required
def delete_event(event_id):
    user = g.current_user
    event = HealthEvent.query.filter_by(id=event_id, user_id=user.id).first()
    if not event:
        return jsonify({'error': 'Health event not found.'}), 404

    db.session.delete(event)
    db.session.commit()
    return jsonify({'message': 'Health event deleted.'}), 200
