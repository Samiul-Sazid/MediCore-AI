"""Notification management routes."""
from flask import Blueprint, jsonify, g
from extensions import db
from models import Notification
from middleware import token_required

notifications_bp = Blueprint('notifications', __name__, url_prefix='/api/notifications')


@notifications_bp.route('/', methods=['GET'])
@token_required
def list_notifications():
    user = g.current_user
    notifications = Notification.query.filter_by(user_id=user.id).order_by(
        Notification.created_at.desc()
    ).limit(50).all()
    return jsonify([n.to_dict() for n in notifications]), 200


@notifications_bp.route('/<int:notif_id>/read', methods=['PUT'])
@token_required
def mark_as_read(notif_id):
    user = g.current_user
    notif = Notification.query.filter_by(id=notif_id, user_id=user.id).first()
    if not notif:
        return jsonify({'error': 'Notification not found.'}), 404

    notif.is_read = True
    db.session.commit()
    return jsonify(notif.to_dict()), 200


@notifications_bp.route('/read-all', methods=['PUT'])
@token_required
def mark_all_read():
    user = g.current_user
    Notification.query.filter_by(user_id=user.id, is_read=False).update({'is_read': True})
    db.session.commit()
    return jsonify({'message': 'All notifications marked as read.'}), 200


@notifications_bp.route('/clear', methods=['DELETE'])
@token_required
def clear_all():
    user = g.current_user
    Notification.query.filter_by(user_id=user.id).delete()
    db.session.commit()
    return jsonify({'message': 'All notifications cleared.'}), 200
