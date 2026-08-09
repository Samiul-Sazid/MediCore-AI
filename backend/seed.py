"""Database seeder — populates drug interactions and doctors from JSON files."""
import json
import os
import sys

# Add backend dir to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app import create_app
from extensions import db
from models import DrugInteraction, Doctor, TimeSlot


def seed_drug_interactions(data_path: str):
    """Load drug interaction rules from JSON."""
    filepath = os.path.join(data_path, 'drug_interactions.json')
    if not os.path.exists(filepath):
        print(f'  [ERR] File not found: {filepath}')
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        interactions = json.load(f)

    existing_count = DrugInteraction.query.count()
    if existing_count > 0:
        print(f'  [SKIP] Drug interactions already seeded ({existing_count} rules). Skipping.')
        return

    count = 0
    for item in interactions:
        rule = DrugInteraction(
            drug_a=item['drug_a'],
            drug_b=item['drug_b'],
            severity=item['severity'],
            title=item['title'],
            mechanism=item.get('mechanism', ''),
            recommendation=item.get('recommendation', ''),
            source=item.get('source', 'DrugBank/FDA'),
        )
        db.session.add(rule)
        count += 1

    db.session.commit()
    print(f'  [OK] Seeded {count} drug interaction rules.')


def seed_doctors(data_path: str):
    """Load doctors from JSON and generate time slots."""
    filepath = os.path.join(data_path, 'doctors_seed.json')
    if not os.path.exists(filepath):
        print(f'  [ERR] File not found: {filepath}')
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        doctors_data = json.load(f)

    existing_count = Doctor.query.count()
    if existing_count > 0:
        print(f'  [SKIP] Doctors already seeded ({existing_count} doctors). Skipping.')
        return

    count = 0
    for doc_data in doctors_data:
        doctor = Doctor(
            name=doc_data['name'],
            specialty=doc_data['specialty'],
            sub_specialty=doc_data.get('sub_specialty', ''),
            hospital=doc_data.get('hospital', ''),
            experience_years=doc_data.get('experience_years', 0),
            rating=doc_data.get('rating', 4.5),
            review_count=doc_data.get('review_count', 0),
            qualifications=doc_data.get('qualifications', ''),
            consultation_fee=doc_data.get('consultation_fee', 0.0),
            photo_url=f"https://ui-avatars.com/api/?name={doc_data['name'].replace(' ', '+')}&background=0ea5e9&color=fff&size=200&bold=true",
            city=doc_data.get('city', ''),
        )
        doctor.available_days = doc_data.get('available_days', [])
        db.session.add(doctor)
        db.session.flush()  # Get doctor.id

        # Generate time slots for each available day
        for day in doc_data.get('available_days', []):
            for hour in range(9, 17):  # 9 AM to 5 PM
                for minute_start in [0, 30]:
                    minute_end = minute_start + 30
                    end_hour = hour
                    if minute_end >= 60:
                        end_hour += 1
                        minute_end -= 60

                    slot = TimeSlot(
                        doctor_id=doctor.id,
                        day_of_week=day,
                        start_time=f'{hour:02d}:{minute_start:02d}',
                        end_time=f'{end_hour:02d}:{minute_end:02d}',
                    )
                    db.session.add(slot)

        count += 1

    db.session.commit()
    print(f'  [OK] Seeded {count} doctors with time slots.')


def main():
    app = create_app()
    data_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'data')

    with app.app_context():
        print('[SEED] MediCore AI Database Seeder')
        print('-' * 40)

        print('\n[DB] Creating database tables...')
        db.create_all()
        print('  [OK] Tables created.')

        print('\n[DRUG] Seeding drug interactions...')
        seed_drug_interactions(data_path)

        print('\n[DOC] Seeding doctors...')
        seed_doctors(data_path)

        print('\n' + '-' * 40)
        print('[DONE] Seeding complete!')


if __name__ == '__main__':
    main()
