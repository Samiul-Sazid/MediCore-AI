"""All SQLAlchemy models for MediCore AI backend."""
import json
from datetime import datetime, date
from extensions import db


class User(db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    profile = db.relationship('Profile', backref='user', uselist=False, cascade='all, delete-orphan')
    medications = db.relationship('Medication', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    prescriptions = db.relationship('Prescription', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    appointments = db.relationship('Appointment', backref='user', lazy='dynamic', cascade='all, delete-orphan')
    notifications = db.relationship('Notification', backref='user', lazy='dynamic', cascade='all, delete-orphan')

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'email': self.email,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Profile(db.Model):
    __tablename__ = 'profiles'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), unique=True, nullable=False)
    phone = db.Column(db.String(30), default='')
    gender = db.Column(db.String(20), default='Not specified')
    blood_type = db.Column(db.String(10), default='Unknown')
    weight_kg = db.Column(db.Float, default=70.0)
    height_cm = db.Column(db.Float, default=170.0)
    _conditions = db.Column('conditions', db.Text, default='[]')
    _drug_allergies = db.Column('drug_allergies', db.Text, default='[]')
    _food_allergies = db.Column('food_allergies', db.Text, default='[]')
    emergency_contact_name = db.Column(db.String(120), default='')
    emergency_contact_phone = db.Column(db.String(30), default='')
    emergency_contact_relation = db.Column(db.String(50), default='')

    @property
    def conditions(self):
        try:
            return json.loads(self._conditions or '[]')
        except (json.JSONDecodeError, TypeError):
            return []

    @conditions.setter
    def conditions(self, value):
        self._conditions = json.dumps(value if isinstance(value, list) else [])

    @property
    def drug_allergies(self):
        try:
            return json.loads(self._drug_allergies or '[]')
        except (json.JSONDecodeError, TypeError):
            return []

    @drug_allergies.setter
    def drug_allergies(self, value):
        self._drug_allergies = json.dumps(value if isinstance(value, list) else [])

    @property
    def food_allergies(self):
        try:
            return json.loads(self._food_allergies or '[]')
        except (json.JSONDecodeError, TypeError):
            return []

    @food_allergies.setter
    def food_allergies(self, value):
        self._food_allergies = json.dumps(value if isinstance(value, list) else [])

    def to_dict(self):
        bmi = 0.0
        if self.height_cm and self.height_cm > 0:
            height_m = self.height_cm / 100.0
            bmi = self.weight_kg / (height_m * height_m) if height_m > 0 else 0.0
        return {
            'user_id': self.user_id,
            'phone': self.phone or '',
            'gender': self.gender or 'Not specified',
            'blood_type': self.blood_type or 'Unknown',
            'blood_group': self.blood_type or 'Unknown',
            'weight_kg': self.weight_kg or 70.0,
            'height_cm': self.height_cm or 170.0,
            'bmi': round(bmi, 1),
            'conditions': self.conditions,
            'drug_allergies': self.drug_allergies,
            'food_allergies': self.food_allergies,
            'emergency_contact_name': self.emergency_contact_name or '',
            'emergency_contact_phone': self.emergency_contact_phone or '',
            'emergency_contact_relation': self.emergency_contact_relation or '',
        }


class Medication(db.Model):
    __tablename__ = 'medications'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    drug_name = db.Column(db.String(120), nullable=False)
    dosage = db.Column(db.String(60), default='')
    frequency = db.Column(db.String(80), default='')
    when_to_take = db.Column(db.String(120), default='')
    prescribed_by = db.Column(db.String(120), default='')
    start_date = db.Column(db.DateTime, default=datetime.utcnow)
    end_date = db.Column(db.DateTime, nullable=True)
    status = db.Column(db.String(20), default='active', index=True)
    stop_reason = db.Column(db.String(250), nullable=True)
    notes = db.Column(db.Text, nullable=True)
    duration = db.Column(db.String(60), default='')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'drug_name': self.drug_name,
            'dosage': self.dosage or '',
            'frequency': self.frequency or '',
            'when_to_take': self.when_to_take or '',
            'prescribed_by': self.prescribed_by or '',
            'start_date': self.start_date.isoformat() if self.start_date else None,
            'end_date': self.end_date.isoformat() if self.end_date else None,
            'status': self.status,
            'stop_reason': self.stop_reason or '',
            'notes': self.notes or '',
            'duration': self.duration or '',
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Prescription(db.Model):
    __tablename__ = 'prescriptions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    prescribed_by = db.Column(db.String(120), default='')
    raw_text = db.Column(db.Text, default='')
    drug_name = db.Column(db.String(120), default='')
    dosage = db.Column(db.String(60), default='')
    frequency = db.Column(db.String(80), default='')
    duration_days = db.Column(db.Integer, default=30)
    confidence_score = db.Column(db.Float, default=0.0)
    scanned_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'prescribed_by': self.prescribed_by or '',
            'raw_text': self.raw_text or '',
            'drug_name': self.drug_name or '',
            'dosage': self.dosage or '',
            'frequency': self.frequency or '',
            'duration_days': self.duration_days,
            'confidence_score': self.confidence_score,
            'scanned_at': self.scanned_at.isoformat() if self.scanned_at else None,
        }


class Doctor(db.Model):
    __tablename__ = 'doctors'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    specialty = db.Column(db.String(80), nullable=False, index=True)
    sub_specialty = db.Column(db.String(120), default='')
    hospital = db.Column(db.String(160), default='')
    experience_years = db.Column(db.Integer, default=0)
    rating = db.Column(db.Float, default=4.5)
    review_count = db.Column(db.Integer, default=0)
    qualifications = db.Column(db.String(200), default='')
    consultation_fee = db.Column(db.Float, default=0.0)
    photo_url = db.Column(db.String(300), default='')
    city = db.Column(db.String(80), default='')
    _available_days = db.Column('available_days', db.Text, default='[]')

    time_slots = db.relationship('TimeSlot', backref='doctor', lazy='dynamic', cascade='all, delete-orphan')
    appointments = db.relationship('Appointment', backref='doctor', lazy='dynamic', cascade='all, delete-orphan')

    @property
    def available_days(self):
        try:
            return json.loads(self._available_days or '[]')
        except (json.JSONDecodeError, TypeError):
            return []

    @available_days.setter
    def available_days(self, value):
        self._available_days = json.dumps(value if isinstance(value, list) else [])

    def to_dict(self):
        return {
            'id': self.id,
            'name': self.name,
            'specialty': self.specialty,
            'sub_specialty': self.sub_specialty or '',
            'hospital': self.hospital or '',
            'experience_years': self.experience_years,
            'rating': self.rating,
            'review_count': self.review_count,
            'qualifications': self.qualifications or '',
            'consultation_fee': self.consultation_fee,
            'photo_url': self.photo_url or '',
            'city': self.city or '',
            'available_days': self.available_days,
        }


class TimeSlot(db.Model):
    __tablename__ = 'time_slots'

    id = db.Column(db.Integer, primary_key=True)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False, index=True)
    day_of_week = db.Column(db.String(10), nullable=False)
    start_time = db.Column(db.String(10), nullable=False)
    end_time = db.Column(db.String(10), nullable=False)

    def to_dict(self):
        return {
            'id': self.id,
            'doctor_id': self.doctor_id,
            'day_of_week': self.day_of_week,
            'start_time': self.start_time,
            'end_time': self.end_time,
        }


class Appointment(db.Model):
    __tablename__ = 'appointments'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    doctor_id = db.Column(db.Integer, db.ForeignKey('doctors.id'), nullable=False)
    appointment_date = db.Column(db.String(20), nullable=False)
    start_time = db.Column(db.String(10), nullable=False)
    end_time = db.Column(db.String(10), nullable=False)
    status = db.Column(db.String(20), default='confirmed')
    reason = db.Column(db.Text, default='')
    notes = db.Column(db.Text, default='')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        doc = Doctor.query.get(self.doctor_id)
        return {
            'id': self.id,
            'user_id': self.user_id,
            'doctor_id': self.doctor_id,
            'doctor_name': doc.name if doc else '',
            'doctor_specialty': doc.specialty if doc else '',
            'doctor_hospital': doc.hospital if doc else '',
            'appointment_date': self.appointment_date,
            'start_time': self.start_time,
            'end_time': self.end_time,
            'status': self.status,
            'reason': self.reason or '',
            'notes': self.notes or '',
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class DrugInteraction(db.Model):
    __tablename__ = 'drug_interactions'

    id = db.Column(db.Integer, primary_key=True)
    drug_a = db.Column(db.String(120), nullable=False, index=True)
    drug_b = db.Column(db.String(120), nullable=False, index=True)
    severity = db.Column(db.String(20), nullable=False)
    title = db.Column(db.String(200), nullable=False)
    mechanism = db.Column(db.Text, default='')
    recommendation = db.Column(db.Text, default='')
    source = db.Column(db.String(100), default='DrugBank/FDA')

    def to_dict(self):
        return {
            'id': self.id,
            'drug_a': self.drug_a,
            'drug_b': self.drug_b,
            'severity': self.severity,
            'title': self.title,
            'mechanism': self.mechanism or '',
            'recommendation': self.recommendation or '',
            'source': self.source or '',
        }


class Notification(db.Model):
    __tablename__ = 'notifications'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    type = db.Column(db.String(30), default='system')
    title = db.Column(db.String(200), nullable=False)
    message = db.Column(db.Text, default='')
    is_read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'type': self.type,
            'title': self.title,
            'message': self.message or '',
            'is_read': self.is_read,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class Document(db.Model):
    __tablename__ = 'documents'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    file_name = db.Column(db.String(255), nullable=False)
    file_type = db.Column(db.String(30), default='')
    category = db.Column(db.String(60), default='Other')
    file_data = db.Column(db.Text, default='')  # base64 encoded
    file_size = db.Column(db.Integer, default=0)
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'file_name': self.file_name,
            'file_type': self.file_type or '',
            'category': self.category or 'Other',
            'file_data': self.file_data or '',
            'file_size': self.file_size,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
        }

    def to_dict_no_data(self):
        """Return dict without file_data (for listing)."""
        return {
            'id': self.id,
            'user_id': self.user_id,
            'file_name': self.file_name,
            'file_type': self.file_type or '',
            'category': self.category or 'Other',
            'file_size': self.file_size,
            'uploaded_at': self.uploaded_at.isoformat() if self.uploaded_at else None,
        }


class HealthEvent(db.Model):
    __tablename__ = 'health_events'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    type = db.Column(db.String(30), nullable=False)  # medication | scan | vitals | appointment | system
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text, default='')
    metadata_json = db.Column(db.Text, default='{}')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        metadata = {}
        try:
            metadata = json.loads(self.metadata_json or '{}')
        except (json.JSONDecodeError, TypeError):
            pass
        return {
            'id': self.id,
            'user_id': self.user_id,
            'type': self.type,
            'title': self.title,
            'description': self.description or '',
            'metadata': metadata,
            'created_at': self.created_at.isoformat() if self.created_at else None,
        }


class VitalReading(db.Model):
    __tablename__ = 'vital_readings'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False, index=True)
    heart_rate = db.Column(db.Integer)
    spo2 = db.Column(db.Float)
    systolic_bp = db.Column(db.Integer)
    diastolic_bp = db.Column(db.Integer)
    temperature_c = db.Column(db.Float)
    source = db.Column(db.String(30), default='smartwatch')
    recorded_at = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'user_id': self.user_id,
            'heart_rate': self.heart_rate,
            'spo2': self.spo2,
            'systolic_bp': self.systolic_bp,
            'diastolic_bp': self.diastolic_bp,
            'temperature_c': self.temperature_c,
            'source': self.source or 'smartwatch',
            'recorded_at': self.recorded_at.isoformat() if self.recorded_at else None,
        }
