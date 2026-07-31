# 🏥 MediCore AI - Smart Personal Healthcare & Vitals Companion

MediCore AI is a modern, cross-platform Flutter application designed for intelligent health monitoring, AI-powered medical advising, medication tracking with drug-interaction checks, smart vitals telemetry, and medical document management.

---

## 🌟 Key Features

* **🔑 Authentication & Account Switcher**: Full registration/login with password strength validation and quick demo account switching.
* **💊 Medication & Interaction Tracker**: Dose schedules, adherence calculation, refill notifications, and an automated drug-drug interaction warning engine.
* **🤖 AI Health Advisor**: Interactive chat assistant integrated with Claude AI for real-time medical guidance and advice.
* **⌚ Smartwatch Vitals Monitoring**: Live telemetry for Heart Rate, SpO2, HRV, Blood Pressure, and Sleep with dynamic charts (`fl_chart`) and anomaly alert triggers.
* **📄 Document Vault & OCR Scanner**: Medical report storage, prescription OCR text extraction, and exportable PDF health summary generation for doctor visits.
* **👨‍⚕️ Doctors Directory & History**: Specialist search, consultation booking, and a unified chronological medical timeline.
* **🎨 Modern UI & Responsive Layout**: Responsive Glassmorphism interface adapting seamlessly between mobile, tablet, and desktop form factors.

---

## 🛠️ Technology Stack

* **Framework**: [Flutter](https://flutter.dev) (SDK ^3.12.2) & Dart
* **State Management**: [Provider](https://pub.dev/packages/provider)
* **Routing**: [GoRouter](https://pub.dev/packages/go_router)
* **Local Persistence**: [Hive](https://pub.dev/packages/hive) / [Hive Flutter](https://pub.dev/packages/hive_flutter)
* **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)
* **PDF & Printing**: [pdf](https://pub.dev/packages/pdf) & [printing](https://pub.dev/packages/printing)
* **HTTP & AI**: [http](https://pub.dev/packages/http) with Claude API integration

---

## 🚀 How to Run the Project

### Prerequisites

Ensure you have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.2 or higher)
* [Git](https://git-scm.com)
* A supported target platform (Google Chrome, Edge, Windows Desktop, Android Emulator, or iOS Simulator).

### 1. Clone the Repository

```bash
git clone https://github.com/Samiul-Sazid/MediCore-AI.git
cd MediCore-AI
```

### 2. Install Dependencies

Fetch all required package dependencies:

```bash
flutter pub get
```

### 3. Run the Application

#### Option A: Run on Web (Chrome)
```bash
flutter run -d chrome
```
*Or specify a custom port:*
```bash
flutter run -d chrome --web-port 8080
```

#### Option B: Run on Windows Desktop
```bash
flutter run -d windows
```

#### Option C: Run on Mobile (Android / iOS)
Make sure an emulator/simulator is running or a device is connected:
```bash
flutter run
```

---

## 📁 Project Structure

```text
lib/
├── app.dart               # Main App Configuration & GoRouter setup
├── main.dart              # Entry Point & MultiProvider initialization
├── models/                # Data models (User, Medication, Vitals, Chat, Docs)
├── providers/             # Provider state managers
├── screens/               # Screen UI modules (Dashboard, Advisor, Vitals, Docs, etc.)
├── services/              # Hive database, Claude AI, OCR, PDF & Interaction engines
├── theme/                 # Custom App Theme, Colors & Typography
└── widgets/               # Reusable UI widgets (GlassCard, VitalGauge, StatCard)
```

---

## 📄 License

This project is open-source under the MIT License.
