"""MediCore AI Backend — Flask application factory."""
import os
import sys

# Ensure backend directory is on path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from flask import Flask
from flask_cors import CORS
from config import Config
from extensions import db


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Enable CORS for Flutter app
    CORS(app, resources={r"/api/*": {"origins": "*"}})

    # Initialize extensions
    db.init_app(app)

    # Register blueprints
    from routes.auth import auth_bp
    from routes.patient import patient_bp
    from routes.medication import medication_bp
    from routes.prescription import prescription_bp
    from routes.doctors import doctors_bp
    from routes.chat import chat_bp
    from routes.ocr import ocr_bp
    from routes.drugs import drugs_bp
    from routes.notifications import notifications_bp
    from routes.documents import documents_bp
    from routes.history import history_bp
    from routes.vitals import vitals_bp

    app.register_blueprint(auth_bp)
    app.register_blueprint(patient_bp)
    app.register_blueprint(medication_bp)
    app.register_blueprint(prescription_bp)
    app.register_blueprint(doctors_bp)
    app.register_blueprint(chat_bp)
    app.register_blueprint(ocr_bp)
    app.register_blueprint(drugs_bp)
    app.register_blueprint(notifications_bp)
    app.register_blueprint(documents_bp)
    app.register_blueprint(history_bp)
    app.register_blueprint(vitals_bp)

    # Create tables on first request
    with app.app_context():
        db.create_all()

    # Health check endpoint
    @app.route('/api/health', methods=['GET'])
    def health_check():
        return {'status': 'ok', 'service': 'MediCore AI Backend'}, 200

    return app


if __name__ == '__main__':
    app = create_app()
    port = int(os.environ.get('PORT', 5000))
    print(f'\n[MediCore AI] Backend starting on http://127.0.0.1:{port}')
    print(f'   Health check: http://127.0.0.1:{port}/api/health')
    print(f'   API docs: All endpoints under /api/*\n')
    app.run(host='0.0.0.0', port=port, debug=True)
