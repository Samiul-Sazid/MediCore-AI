"""Document storage and retrieval routes."""
from datetime import datetime
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import Document
from middleware import token_required

documents_bp = Blueprint('documents', __name__, url_prefix='/api/documents')


@documents_bp.route('/', methods=['GET'])
@token_required
def list_documents():
    user = g.current_user
    category = request.args.get('category', '').strip()

    q = Document.query.filter_by(user_id=user.id)
    if category and category != 'All':
        q = q.filter_by(category=category)

    docs = q.order_by(Document.uploaded_at.desc()).all()
    # Return without file_data for listing (lighter payload)
    return jsonify([d.to_dict_no_data() for d in docs]), 200


@documents_bp.route('/<int:doc_id>', methods=['GET'])
@token_required
def get_document(doc_id):
    user = g.current_user
    doc = Document.query.filter_by(id=doc_id, user_id=user.id).first()
    if not doc:
        return jsonify({'error': 'Document not found.'}), 404
    # Return full dict including file_data
    return jsonify(doc.to_dict()), 200


@documents_bp.route('/upload', methods=['POST'])
@token_required
def upload_document():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    file_name = (data.get('file_name') or '').strip()
    if not file_name:
        return jsonify({'error': 'file_name is required.'}), 400

    doc = Document(
        user_id=user.id,
        file_name=file_name,
        file_type=(data.get('file_type') or '').strip(),
        category=(data.get('category') or 'Other').strip(),
        file_data=data.get('file_data', ''),
        file_size=int(data.get('file_size', 0)),
        uploaded_at=datetime.utcnow(),
    )
    db.session.add(doc)
    db.session.commit()

    return jsonify(doc.to_dict_no_data()), 201


@documents_bp.route('/<int:doc_id>', methods=['DELETE'])
@token_required
def delete_document(doc_id):
    user = g.current_user
    doc = Document.query.filter_by(id=doc_id, user_id=user.id).first()
    if not doc:
        return jsonify({'error': 'Document not found.'}), 404

    db.session.delete(doc)
    db.session.commit()
    return jsonify({'message': 'Document deleted.'}), 200
