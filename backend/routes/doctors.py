"""Doctor directory and appointment booking routes."""
from datetime import datetime
from flask import Blueprint, request, jsonify, g
from extensions import db
from models import Doctor, TimeSlot, Appointment, Notification
from middleware import token_required

doctors_bp = Blueprint('doctors', __name__, url_prefix='/api/doctors')


@doctors_bp.route('/', methods=['GET'])
@token_required
def list_doctors():
    specialty = request.args.get('specialty', '').strip()
    query_text = request.args.get('query', request.args.get('q', '')).strip().lower()

    q = Doctor.query

    if specialty:
        q = q.filter(Doctor.specialty.ilike(f'%{specialty}%'))

    if query_text:
        q = q.filter(
            db.or_(
                Doctor.name.ilike(f'%{query_text}%'),
                Doctor.specialty.ilike(f'%{query_text}%'),
                Doctor.sub_specialty.ilike(f'%{query_text}%'),
                Doctor.hospital.ilike(f'%{query_text}%'),
            )
        )

    doctors = q.order_by(Doctor.rating.desc()).all()
    return jsonify([d.to_dict() for d in doctors]), 200


@doctors_bp.route('/<int:doctor_id>', methods=['GET'])
@token_required
def get_doctor(doctor_id):
    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return jsonify({'error': 'Doctor not found.'}), 404

    result = doctor.to_dict()
    slots = TimeSlot.query.filter_by(doctor_id=doctor.id).order_by(
        TimeSlot.day_of_week, TimeSlot.start_time
    ).all()
    result['time_slots'] = [s.to_dict() for s in slots]
    return jsonify(result), 200


@doctors_bp.route('/<int:doctor_id>/slots', methods=['GET'])
@token_required
def get_doctor_slots(doctor_id):
    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return jsonify({'error': 'Doctor not found.'}), 404

    day = request.args.get('day', '').strip()
    date_str = request.args.get('date', '').strip()

    q = TimeSlot.query.filter_by(doctor_id=doctor.id)
    if day:
        q = q.filter_by(day_of_week=day)

    slots = q.order_by(TimeSlot.day_of_week, TimeSlot.start_time).all()

    # Check which slots are already booked for the requested date
    slot_list = []
    for s in slots:
        slot_data = s.to_dict()
        if date_str:
            existing = Appointment.query.filter_by(
                doctor_id=doctor.id,
                appointment_date=date_str,
                start_time=s.start_time,
            ).filter(Appointment.status.in_(['pending', 'confirmed'])).first()
            slot_data['is_booked'] = existing is not None
        else:
            slot_data['is_booked'] = False
        slot_list.append(slot_data)

    return jsonify(slot_list), 200


@doctors_bp.route('/book', methods=['POST'])
@token_required
def book_appointment():
    user = g.current_user
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body is required.'}), 400

    doctor_id = data.get('doctor_id')
    appointment_date = data.get('appointment_date', '').strip()
    start_time = data.get('start_time', '').strip()
    end_time = data.get('end_time', '').strip()
    reason = data.get('reason', '').strip()

    if not doctor_id or not appointment_date or not start_time:
        return jsonify({'error': 'doctor_id, appointment_date, and start_time are required.'}), 400

    doctor = Doctor.query.get(doctor_id)
    if not doctor:
        return jsonify({'error': 'Doctor not found.'}), 404

    # Check for conflicts
    existing = Appointment.query.filter_by(
        doctor_id=doctor_id,
        appointment_date=appointment_date,
        start_time=start_time,
    ).filter(Appointment.status.in_(['pending', 'confirmed'])).first()

    if existing:
        return jsonify({'error': 'This time slot is already booked. Please choose another.'}), 409

    if not end_time:
        # Default to 30 min slot
        hour, minute = map(int, start_time.split(':'))
        minute += 30
        if minute >= 60:
            hour += 1
            minute -= 60
        end_time = f'{hour:02d}:{minute:02d}'

    appointment = Appointment(
        user_id=user.id,
        doctor_id=doctor_id,
        appointment_date=appointment_date,
        start_time=start_time,
        end_time=end_time,
        status='confirmed',
        reason=reason,
        created_at=datetime.utcnow(),
    )
    db.session.add(appointment)

    # Create notification
    notification = Notification(
        user_id=user.id,
        type='appointment',
        title='Appointment Confirmed',
        message=f'Your appointment with {doctor.name} ({doctor.specialty}) on {appointment_date} at {start_time} has been confirmed.',
    )
    db.session.add(notification)

    db.session.commit()
    return jsonify(appointment.to_dict()), 201


@doctors_bp.route('/appointments', methods=['GET'])
@token_required
def list_appointments():
    user = g.current_user
    status = request.args.get('status', '').strip()

    q = Appointment.query.filter_by(user_id=user.id)
    if status:
        q = q.filter_by(status=status)

    appointments = q.order_by(Appointment.appointment_date.desc()).all()
    return jsonify([a.to_dict() for a in appointments]), 200


@doctors_bp.route('/appointments/<int:appointment_id>/cancel', methods=['PUT'])
@token_required
def cancel_appointment(appointment_id):
    user = g.current_user
    appointment = Appointment.query.filter_by(id=appointment_id, user_id=user.id).first()
    if not appointment:
        return jsonify({'error': 'Appointment not found.'}), 404

    if appointment.status in ['cancelled', 'completed']:
        return jsonify({'error': f'Cannot cancel an appointment that is already {appointment.status}.'}), 400

    appointment.status = 'cancelled'

    doctor = Doctor.query.get(appointment.doctor_id)
    notification = Notification(
        user_id=user.id,
        type='appointment',
        title='Appointment Cancelled',
        message=f'Your appointment with {doctor.name if doctor else "Unknown"} on {appointment.appointment_date} at {appointment.start_time} has been cancelled.',
    )
    db.session.add(notification)

    db.session.commit()
    return jsonify(appointment.to_dict()), 200
