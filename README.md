# 🏥 MediCore AI - Smart Personal Healthcare & Vitals Companion

MediCore AI is a comprehensive full-stack healthcare platform featuring a modern Flutter frontend and a robust Python Flask REST API backend. It provides intelligent health telemetry monitoring, AI-powered medical advising, medication tracking with drug-drug interaction safety checks, doctor directory & appointment booking, prescription OCR extraction, and medical document management.

---

## 🌟 Key Features

* **🔑 Full Authentication & Patient Management**: Registration, JWT session management, profile updating (blood group, height, weight, allergies, conditions), and account switching.
* **🤖 AI Health Advisor**: Interactive medical consultation assistant powered by **Anthropic Claude 3.5 Sonnet** with a built-in **MediCore Clinical AI Engine fallback** (ensures smart responses even without an external API key).
* **💊 3-Layer Drug Interaction Safety Engine**: Real-time cross-referencing of new medications against active prescriptions, patient drug allergies, and local clinical rule databases.
* **👨‍⚕️ Doctors Directory & Appointment Booking**: Specialist filtering by department (Cardiology, Neurology, Orthopedics, etc.), real-time slot availability, and instant booking confirmation.
* **⌚ Smartwatch Telemetry & Vitals Tracking**: Live vitals logging for Heart Rate, SpO2, Blood Pressure, and Temperature with interactive trend charts (`fl_chart`) and anomaly detection.
* **📄 Medical Document Vault & OCR Scanner**: Upload and store PDF/image lab results, automated text extraction from prescriptions via backend OCR, and PDF health summary exports.
* **📜 Medical Timeline & Notifications**: Chronological health event logging and automated patient reminders for appointments and medication adherence.
* **🎨 Apple Health Aesthetic**: Clean, modern UI with Pale Sage/Mint containers, dark slate typography, and sleek squircle card layouts.

---

## 🛠️ Technology Stack

### Frontend (Mobile / Web / Desktop)
* **Framework**: [Flutter](https://flutter.dev) (SDK ^3.12.2) & Dart
* **State Management**: [Provider](https://pub.dev/packages/provider)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router)
* **Local Persistence**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter)
* **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
* **PDF & Printing**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)
* **HTTP Client**: [http](https://pub.dev/packages/http) with automatic backend endpoint detection

### Backend (REST API)
* **Framework**: [Flask](https://flask.palletsprojects.com/) (Python 3.10+)
* **Database**: SQLite with [Flask-SQLAlchemy](https://flask-sqlalchemy.palletsprojects.com/) ORM
* **Authentication**: PyJWT (JSON Web Tokens) & Passlib (Bcrypt hashing)
* **AI Integration**: Anthropic Python SDK (`claude-3-5-sonnet-20241022`) & MediCore Clinical Fallback Engine
* **CORS & Environment**: Flask-CORS & python-dotenv

---

## 🔌 Backend REST API Endpoints

| Category | Endpoint | Method | Description |
| :--- | :--- | :--- | :--- |
| **Health** | `/api/health` | `GET` | Server health check |
| **Auth** | `/api/auth/register` | `POST` | Patient account registration |
| **Auth** | `/api/auth/login` | `POST` | Patient login & JWT generation |
| **Profile** | `/api/patient/profile` | `GET` / `PUT` | Retrieve or update patient clinical context |
| **Medications** | `/api/prescription/medications` | `GET` / `POST` | List or add patient active medications |
| **Drug Engine** | `/api/drugs/check-interaction` | `POST` | 3-layer interaction & allergy conflict check |
| **AI Chat** | `/api/chat` | `POST` | AI Health Advisor prompt evaluation & response |
| **Doctors** | `/api/doctors/` | `GET` | List & filter specialists by department |
| **Doctors** | `/api/doctors/<id>/slots` | `GET` | Fetch doctor available consultation slots |
| **Doctors** | `/api/doctors/book` | `POST` | Book appointment & trigger patient notification |
| **Documents** | `/api/documents/` | `GET` / `POST` | Medical vault document list & upload |
| **OCR** | `/api/ocr/parse` | `POST` | Extract structured text from prescription images |
| **Vitals** | `/api/vitals/latest` | `GET` / `POST` | Telemetry vitals logging & latest reading |

---

## 🚀 How to Run the Project

### 1. Start the Flask Backend Server

```bash
cd backend

# Option A: Seed database with doctor directory and interaction rules
py seed.py

# Option B: Run Flask REST API server
py app.py
```
*The backend server will run at `http://127.0.0.1:5000/api`.*

---

### 2. Run the Flutter Frontend Application

```bash
# Return to root workspace directory
cd ..

# Fetch Dart dependencies
flutter pub get

# Run on Windows Desktop
flutter run -d windows

# Or run on Web (Chrome)
flutter run -d chrome
```

---

## 📁 Repository Structure

```text
├── backend/                  # Python Flask REST API & SQLite Database
│   ├── app.py                # Application factory & Blueprint initialization
│   ├── config.py             # Server & DB absolute path config
│   ├── models.py             # SQLAlchemy ORM models (User, Doctor, Med, Vitals, etc.)
│   ├── seed.py               # Database seeder for doctors & drug interactions
│   ├── test_api.py           # End-to-End API test suite
│   ├── routes/               # API route modules (auth, chat, doctors, vitals, etc.)
│   └── data/                 # JSON seed data files
├── lib/                      # Flutter Frontend Application
│   ├── app.dart              # GoRouter configuration & routes
│   ├── main.dart             # Entry point & Provider tree setup
│   ├── models/               # Client-side Dart models
│   ├── providers/            # State management providers
│   ├── screens/              # UI screens (Dashboard, Advisor, Doctors, Vitals, etc.)
│   ├── services/             # API client, Hive storage, PDF generator, Claude proxy
│   ├── theme/                # Apple Health design system, colors & typography
│   └── widgets/              # Reusable components (StatCard, GlassCard, ChatBubble)
└── test/                     # Flutter unit & widget tests
```

---

## 📄 License

This project is open-source under the [MIT License](LICENSE).
