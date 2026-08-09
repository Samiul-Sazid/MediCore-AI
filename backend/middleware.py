"""JWT authentication middleware."""
import jwt
from functools import wraps
from flask import request, jsonify, g
from config import Config


def token_required(f):
    """Decorator that verifies JWT token and sets g.current_user."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None

        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ', 1)[1]

        if not token:
            return jsonify({'error': 'Authentication token is missing. Please log in.'}), 401

        try:
            data = jwt.decode(token, Config.SECRET_KEY, algorithms=['HS256'])
            from models import User
            user = User.query.get(data.get('user_id'))
            if user is None:
                return jsonify({'error': 'User account not found. Please register again.'}), 401
            g.current_user = user
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Session expired. Please log in again.'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Invalid authentication token.'}), 401

        return f(*args, **kwargs)
    return decorated
