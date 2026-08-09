"""Authentication routes — register and login."""
from datetime import datetime, timedelta
import jwt
from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from extensions import db
from models import User, Profile, Notification
from config import Config

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')


@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    name = (data.get('name') or '').strip()
    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if not name or not email or not password:
        return jsonify({'error': 'Name, email and password are required.'}), 400

    if len(password) < 6:
        return jsonify({'error': 'Password must be at least 6 characters.'}), 400

    if User.query.filter_by(email=email).first():
        return jsonify({'error': 'An account with this email already exists.'}), 409

    user = User(
        name=name,
        email=email,
        password_hash=generate_password_hash(password),
        created_at=datetime.utcnow(),
    )
    db.session.add(user)
    db.session.flush()

    # Create default empty profile
    profile = Profile(user_id=user.id)
    db.session.add(profile)

    # Welcome notification
    notification = Notification(
        user_id=user.id,
        type='system',
        title='Welcome to MediCore AI',
        message='Your health dashboard is ready. Start by completing your profile with your medical information.',
    )
    db.session.add(notification)

    db.session.commit()

    token = _generate_token(user.id)
    return jsonify({'token': token, 'user': user.to_dict()}), 201


@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    email = (data.get('email') or '').strip().lower()
    password = data.get('password') or ''

    if not email or not password:
        return jsonify({'error': 'Email and password are required.'}), 400

    user = User.query.filter_by(email=email).first()
    if not user or not check_password_hash(user.password_hash, password):
        return jsonify({'error': 'Invalid email or password.'}), 401

    token = _generate_token(user.id)
    return jsonify({'token': token, 'user': user.to_dict()}), 200


def _generate_token(user_id: int) -> str:
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(hours=Config.JWT_EXPIRATION_HOURS),
        'iat': datetime.utcnow(),
    }
    return jwt.encode(payload, Config.SECRET_KEY, algorithm='HS256')
