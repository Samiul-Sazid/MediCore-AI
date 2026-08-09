# 🏥 MediCore AI - Smart Personal Healthcare Companion

MediCore AI is an intelligent, full-stack healthcare platform featuring a Flutter application powered by a Python Flask REST API backend. It provides medical AI advising, medication tracking with drug-interaction checks, smartwatch vitals telemetry, prescription OCR scanning, and doctor appointment booking.

---

## 🌟 App Features

* **🤖 AI Health Advisor**: Real-time clinical AI consultation assistant powered by Claude 3.5 Sonnet with an automated MediCore Clinical AI Engine fallback.
* **💊 Drug Interaction Safety Engine**: 3-layer real-time cross-referencing of prescriptions against active medications, patient drug allergies, and clinical interaction rules.
* **👨‍⚕️ Doctors Directory & Appointment Booking**: Specialist directory filtering by medical department, live time slot availability, and instant booking confirmation.
* **⌚ Smartwatch Telemetry & Vitals Tracking**: Real-time logging of Heart Rate, SpO2, Blood Pressure, and Body Temperature with interactive trend charts (`fl_chart`).
* **📄 Medical Vault & OCR Scanner**: Digital storage for medical lab reports, automated text extraction from prescriptions via OCR, and exportable PDF health summaries.
* **📜 Medical Timeline & Reminders**: Chronological medical history logging and automated patient notifications for upcoming appointments and dosage schedules.
* **🎨 Modern Interface**: Responsive, high-contrast Apple Health-inspired aesthetic with dark slate typography and squircle containers.

---

## 🚀 How to Run the App After Cloning

### 1. Clone the Repository

```bash
git clone https://github.com/Samiul-Sazid/MediCore-AI.git
cd MediCore-AI
```

### 2. Start the Backend Server (Python Flask)

Ensure Python 3.10+ is installed. Open a terminal window and run:

```bash
# Navigate to backend folder
cd backend

# Install dependencies (if needed)
pip install -r requirements.txt

# Seed the database with doctors & drug interaction rules
py seed.py

# Start the Flask API backend server
py app.py
```
*The backend server will start running at `http://127.0.0.1:5000/api`.*

### 3. Run the Frontend App (Flutter)

Open a second terminal window in the project root directory:

```bash
# Fetch Dart dependencies
flutter pub get

# Run on Windows Desktop
flutter run -d windows

# Or run on Web (Chrome)
flutter run -d chrome
```

---

## 📁 Project Structure

```text
MediCore-AI/
├── backend/                  # Python Flask REST API & Database
│   ├── app.py                # Flask Server entry point
│   ├── config.py             # Server & DB configuration
│   ├── seed.py               # Database seeder (Doctors & Drug rules)
│   ├── models.py             # Database ORM models
│   ├── routes/               # REST API Endpoints (auth, chat, doctors, vitals, etc.)
│   └── data/                 # JSON seed data files
│
├── lib/                      # Flutter Frontend Application
│   ├── main.dart             # Application Entry Point & Provider setup
│   ├── app.dart              # GoRouter setup & Navigation routes
│   ├── models/               # Client-side data models
│   ├── providers/            # State management providers
│   ├── screens/              # App UI screens (Dashboard, Advisor, Vitals, Doctors, etc.)
│   ├── services/             # API client, Hive storage, PDF generator, Claude proxy
│   ├── theme/                # Theme colors, typography & design tokens
│   └── widgets/              # Reusable UI components (StatCard, GlassCard, ChatBubble)
│
└── test/                     # Flutter unit & widget tests
```

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
