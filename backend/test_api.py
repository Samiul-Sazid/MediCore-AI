import requests
import json
import sys

BASE_URL = 'http://127.0.0.1:5000/api'

def test_backend():
    print("=======================================")
    print("   MediCore AI Full End-to-End Test    ")
    print("=======================================")

    # 1. Health check
    print("\n1. Testing GET /api/health ...")
    r = requests.get(f"{BASE_URL}/health")
    assert r.status_code == 200, f"Health check failed: {r.text}"
    print("   [OK] Health status:", r.json())

    # 2. Auth - Register
    import time
    email = f"test_user_{int(time.time() * 1000)}@example.com"
    password = "password123"
    print(f"\n2. Testing POST /api/auth/register ({email}) ...")
    r = requests.post(f"{BASE_URL}/auth/register", json={
        "name": "Test Patient",
        "email": email,
        "password": password
    })
    assert r.status_code == 201, f"Registration failed: {r.text}"
    data = r.json()
    token = data['token']
    user_id = data['user']['id']
    headers = {"Authorization": f"Bearer {token}"}
    print(f"   [OK] Registered user_id: {user_id}")

    # 3. Auth - Login
    print(f"\n3. Testing POST /api/auth/login ...")
    r = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": password
    })
    assert r.status_code == 200, f"Login failed: {r.text}"
    print("   [OK] Logged in successfully")

    # 4. Patient Profile
    print("\n4. Testing GET & PUT /api/patient/profile ...")
    r = requests.get(f"{BASE_URL}/patient/profile", headers=headers)
    assert r.status_code == 200, f"Get profile failed: {r.text}"
    print("   [OK] Initial profile fetched:", r.json().get('name'))

    r = requests.put(f"{BASE_URL}/patient/profile", headers=headers, json={
        "phone": "+1234567890",
        "gender": "Female",
        "blood_group": "O+",
        "weight_kg": 65.5,
        "height_cm": 168.0,
        "conditions": ["Hypertension"],
        "drug_allergies": ["Penicillin"]
    })
    assert r.status_code == 200, f"Update profile failed: {r.text}"
    print("   [OK] Updated profile successfully. Blood group:", r.json().get('blood_group'))

    # 5. Medications CRUD
    print("\n5. Testing Medications CRUD (/api/prescription/medications) ...")
    r = requests.post(f"{BASE_URL}/prescription/medications", headers=headers, json={
        "drug_name": "Lisinopril",
        "dosage": "10mg",
        "frequency": "Once daily",
        "when_to_take": "Morning after breakfast",
        "prescribed_by": "Dr. Sarah Jenkins",
        "notes": "30 days course"
    })
    assert r.status_code == 201, f"Add medication failed: {r.text}"
    med = r.json()
    med_id = med['id']
    print(f"   [OK] Added medication ID {med_id}: {med['drug_name']}")

    r = requests.get(f"{BASE_URL}/prescription/medications", headers=headers)
    assert r.status_code == 200 and len(r.json()) > 0, "List medications failed"
    print(f"   [OK] Listed {len(r.json())} medication(s)")

    # 6. Doctors & Appointment Booking
    print("\n6. Testing Doctors Directory & Booking (/api/doctors) ...")
    r = requests.get(f"{BASE_URL}/doctors/", headers=headers)
    assert r.status_code == 200, f"List doctors failed: {r.text}"
    doctors = r.json()
    assert len(doctors) > 0, "No seeded doctors found!"
    doc = doctors[0]
    print(f"   [OK] Found {len(doctors)} doctors. Selected: {doc['name']} ({doc['specialty']})")

    r = requests.get(f"{BASE_URL}/doctors/{doc['id']}/slots", headers=headers)
    assert r.status_code == 200, f"Get slots failed: {r.text}"
    slots = r.json()
    print(f"   [OK] Found {len(slots)} time slots for doctor")

    # Book appointment
    booking_date = f"2026-09-{(int(time.time()) % 20) + 1:02d}"
    r = requests.post(f"{BASE_URL}/doctors/book", headers=headers, json={
        "doctor_id": doc['id'],
        "appointment_date": booking_date,
        "start_time": "10:00",
        "reason": "Routine Checkup"
    })
    assert r.status_code == 201, f"Booking appointment failed: {r.text}"
    appt = r.json()
    print(f"   [OK] Booked appointment ID {appt['id']} on {appt['appointment_date']} at {appt['start_time']}")

    r = requests.get(f"{BASE_URL}/doctors/appointments", headers=headers)
    assert r.status_code == 200 and len(r.json()) > 0, "Fetch appointments failed"
    print(f"   [OK] User appointments list count: {len(r.json())}")

    # 7. Drug Interaction Check (3-Layer)
    print("\n7. Testing Drug Interaction Engine (/api/drugs/check-interaction) ...")
    # Check "Aspirin" against active "Lisinopril" and allergy "Penicillin"
    r = requests.post(f"{BASE_URL}/drugs/check-interaction", headers=headers, json={
        "drug_name": "Penicillin"
    })
    assert r.status_code == 200, f"Interaction check failed: {r.text}"
    res = r.json()
    print(f"   [OK] Interaction check for 'Penicillin':")
    print(f"        Allergy Conflicts: {len(res['allergy_conflicts'])}")
    print(f"        Local Rule Conflicts: {len(res['local_interactions'])}")

    # 8. Notifications
    print("\n8. Testing Notifications API (/api/notifications) ...")
    r = requests.get(f"{BASE_URL}/notifications/", headers=headers)
    assert r.status_code == 200, f"Get notifications failed: {r.text}"
    notifs = r.json()
    print(f"   [OK] Found {len(notifs)} notification(s)")

    # 9. Documents API
    print("\n9. Testing Documents API (/api/documents) ...")
    r = requests.post(f"{BASE_URL}/documents/upload", headers=headers, json={
        "file_name": "Blood_Test_Report.pdf",
        "file_type": "pdf",
        "category": "Lab Results",
        "file_data": "JVBERi0xLjQK...",
        "file_size": 1024
    })
    assert r.status_code == 201, f"Upload document failed: {r.text}"
    doc_res = r.json()
    print(f"   [OK] Uploaded document ID {doc_res['id']}: {doc_res['file_name']}")

    r = requests.get(f"{BASE_URL}/documents/", headers=headers)
    assert r.status_code == 200 and len(r.json()) > 0, "List documents failed"
    print(f"   [OK] Listed {len(r.json())} document(s)")

    # 10. History Events API
    print("\n10. Testing Health History API (/api/history) ...")
    r = requests.post(f"{BASE_URL}/history/", headers=headers, json={
        "type": "vitals",
        "title": "Smartwatch Sync",
        "description": "Average HR 72 bpm, SpO2 98%"
    })
    assert r.status_code == 201, f"Create history event failed: {r.text}"
    print(f"   [OK] Created health event: {r.json()['title']}")

    r = requests.get(f"{BASE_URL}/history/", headers=headers)
    assert r.status_code == 200 and len(r.json()) > 0, "List history failed"
    print(f"   [OK] History events count: {len(r.json())}")

    # 11. Vitals API
    print("\n11. Testing Vitals API (/api/vitals) ...")
    r = requests.post(f"{BASE_URL}/vitals/", headers=headers, json={
        "heart_rate": 74,
        "spo2": 98.5,
        "systolic_bp": 120,
        "diastolic_bp": 80,
        "temperature_c": 36.6,
        "source": "smartwatch"
    })
    assert r.status_code == 201, f"Record vitals failed: {r.text}"
    print(f"   [OK] Recorded vital reading HR={r.json()['heart_rate']}, SpO2={r.json()['spo2']}")

    r = requests.get(f"{BASE_URL}/vitals/latest", headers=headers)
    assert r.status_code == 200, f"Get latest vitals failed: {r.text}"
    print(f"   [OK] Latest vital reading fetched successfully")

    print("\n=======================================")
    print("   ALL BACKEND API TESTS PASSED 100%!  ")
    print("=======================================")

if __name__ == '__main__':
    test_backend()
