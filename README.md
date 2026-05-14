# 🛡️ Suraksha-Setu — Hyper-Local Safety Network

> **Empowering Communities, One Neighbourhood at a Time**

[![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android)](https://android.com)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter%203.x-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-lightgrey)](LICENSE)
[![PRD Version](https://img.shields.io/badge/PRD-v1.0-purple)](docs/PRD.pdf)

---

## 📖 Overview

**Suraksha-Setu** (meaning *Safety Bridge* in Hindi) is a hyper-local community safety Android application built for **women and elderly citizens in rural India**. Unlike conventional SOS apps that rely solely on law enforcement, Suraksha-Setu builds a **community-driven first-response network** — connecting users instantly to trusted neighbours, shopkeepers, and registered volunteers within a **500-metre radius**.

> The fastest first-responder in a village is often a neighbour — not the police.

---

## 🚨 The Problem

Rural areas in India face a critical safety gap:

| Problem | Impact |
|---|---|
| Police response time: 30–60 minutes | Victims left unprotected during the critical window |
| No community trust network exists digitally | No coordinated response from nearby people |
| SOS apps need internet for maps/server calls | Fails on patchy 2G/3G rural networks |
| Elderly cannot operate complex apps quickly | High-friction UI leads to missed alerts |
| No audio evidence to prevent false complaints | No accountability layer |

---

## ✨ Key Features

### 🆘 Emergency Triggers
- **Shake Gesture** — Shake phone at > 12 m/s² (works in background)
- **Power Button Double-Tap** — Two rapid presses within 500ms via AccessibilityService
- **10-Second Cancel Window** — Prevent false alarms before the alert fires

### 📡 Alert System
- **High-Priority FCM Push** — Wakes responder devices even in Android Doze mode
- **500 m Geofencing** — Only Verified Responders within radius receive the alarm
- **Live GPS Broadcast** — Real-time coordinates embedded in every alert payload
- **SMS Fallback** — Delivers alert via SMS when internet is unavailable

### 🎙️ Audio Evidence
- **30-Second Auto Recording** — Microphone captures ambient audio on trigger
- **AES-256 Encrypted Upload** — Audio streamed to Firebase Storage in real time
- **Auto-delete after 30 days** — Privacy-first data retention policy

### 👥 Community Network
- **Safe-Circle** — Up to 5 trusted contacts per user
- **Verified Responder Mode** — Any user can volunteer and register for their neighbourhood
- **Alert History Log** — GPS traces, timestamps, and audio clips for past incidents

### ♿ Accessibility
- SOS button ≥ 120dp × 120dp (one-thumb operable)
- Minimum font size 16sp for all critical text
- Colour contrast ratio ≥ 4.5:1 (WCAG AA)
- TalkBack (screen reader) compatible
- Available in **Hindi** and **English**

---

## 📱 Download APK

> 📦 **[Download Latest APK](https://drive.google.com/file/d/16ja-uSE5HyfRRxMx7N571_bC4XKCU6eG/view?usp=drive_link)**

*Requires Android 8.0 (Oreo) or higher.*

---

## 🏗️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter 3.x (Dart) / Native Android (Kotlin) |
| **UI Components** | Material Design 3, custom SOS widget |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Location** | Google Fused Location Provider + Geofencing API |
| **Sensor** | Android SensorManager (ACCELEROMETER) |
| **Background** | Android Foreground Service, WakeLock, AccessibilityService |
| **Database** | Firebase Realtime Database + Firestore |
| **Storage** | Firebase Storage (encrypted audio) |
| **Authentication** | Firebase Auth — Phone OTP |
| **SMS Fallback** | Twilio SMS API / Android TelephonyManager |
| **Maps** | Google Maps SDK + OpenStreetMap (offline fallback) |
| **State Management** | Riverpod / Bloc |
| **CI/CD** | GitHub Actions + Fastlane |
| **Analytics** | Firebase Crashlytics + Analytics |

---

## 🗺️ Core Emergency Flow

```
User shakes phone / double-taps power button
        ↓
10-second false-alarm cancel window shown
        ↓
Alert confirmed → GPS coordinates fetched
        ↓
FCM high-priority push → Safe-Circle + geofenced volunteers
        ↓
30-sec audio recording → Firebase Storage (AES-256)
        ↓
SMS fallback → all Safe-Circle members
        ↓
Responder acknowledges → "Help is Coming" shown to victim
        ↓
Incident resolved → Alert archived
```

---

## 👤 Target User Personas

| Persona | Profile |
|---|---|
| **Priya, 24** | Factory worker walking 2 km home after night shift. Needs one-touch SOS without unlocking phone. |
| **Ramesh, 68** | Elderly farmer returning from market. Needs large UI, shake trigger, minimal steps. |
| **Arjun, 22** | College student who volunteers as a Verified Responder for his neighbourhood. |

---

## ⚡ Performance Targets

- Alert delivery latency ≤ **5 seconds** on 3G
- Shake detection response ≤ **200ms**
- App cold-start ≤ **3 seconds** on 2 GB RAM devices
- Background CPU usage ≤ **2%** idle
- Background memory footprint ≤ **50 MB**

---

## 🔒 Security & Privacy

- Audio recordings encrypted with **AES-256** before upload
- GPS data transmitted **only during active alert** — not stored perpetually
- FCM payloads use **TLS 1.3** transport security
- Volunteer identity verified via **phone OTP**
- Users can **permanently delete** their audio history from settings

---

## 🧪 Running the Project Locally

### Prerequisites

- Flutter 3.x SDK → [Install Flutter](https://docs.flutter.dev/get-started/install)
- Android Studio / VS Code with Flutter plugin
- Firebase project with Realtime Database, Firestore, Storage, and Auth enabled
- Google Maps API key

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/GouthamKP3002/suraksha-setu.git
cd suraksha-setu

# 2. Install dependencies
flutter pub get

# 3. Add your Firebase config
# Place google-services.json inside android/app/

# 4. Add your API keys
# Update lib/config/api_keys.dart with your Google Maps API key

# 5. Run the app
flutter run
```

---

## 📂 Project Structure

```
suraksha-setu/
├── android/                  # Native Android config & manifests
├── lib/
│   ├── config/               # API keys, constants
│   ├── features/
│   │   ├── auth/             # Phone OTP authentication
│   │   ├── alert/            # SOS trigger, FCM, GPS broadcast
│   │   ├── circle/           # Safe-Circle management
│   │   ├── volunteer/        # Verified Responder registration
│   │   └── history/          # Alert history log
│   ├── services/
│   │   ├── sensor_service    # Shake detection (SensorManager)
│   │   ├── location_service  # Fused Location + Geofencing
│   │   ├── audio_service     # 30-sec recording + upload
│   │   ├── fcm_service       # Push notification handling
│   │   └── sms_service       # SMS fallback
│   └── main.dart
├── docs/
│   └── PRD.pdf               # Product Requirements Document
└── README.md
```

---

## 📊 Feature Priority (MoSCoW)

| Must Have | Should Have | Could Have | Won't Have (v1) |
|---|---|---|---|
| Shake / power-button trigger | Volunteer Responder mode | Community leaderboard | Police API integration |
| Background Foreground Service | SMS fallback | Village-level heatmap | AI threat prediction |
| FCM high-priority push | False-alarm cancel (10s) | Periodic safety check-in | Wearable pairing |
| Live GPS in alert payload | Alert history log | Responder ETA tracker | In-app VoIP calling |
| Safe-Circle (5 contacts) | Hindi + English UI | Offline map tiles | Web admin dashboard |
| 500 m Geofencing filter | Audio cloud upload | WhatsApp share alert | Paid subscriptions |
| 30-sec auto audio record | In-app tutorial | Customisable alarm sound | CCTV / IoT sensors |
| Large SOS button UI | Dark mode | | |
| OTP-based auth | | | |

---

## 🎯 Impact Goals

| 👩 Women's Safety | 🤝 Social Cohesion | 🚀 Emergency Efficiency |
|---|---|---|
| Enable rural women to travel independently with rapid community response | Digitise 'Neighbourhood Watch' culture with verified volunteer networks | Cut first-responder arrival from 30+ minutes to under 5 minutes |

---

## ⚠️ Risks & Mitigations

| Risk | Mitigation |
|---|---|
| Background process killed by Android OS | Foreground Service with persistent notification; battery optimisation exemption |
| False alarms causing alert fatigue | 10-sec cancel window; limit 3 alerts/hour |
| Low volunteer density in remote villages | SMS fallback; expand radius to 1 km if < 3 responders found |
| Weak GPS signal indoors | Fused Location (WiFi + Cell + GPS); fallback to last-known location |
| Audio privacy misuse | AES-256 encryption; auto-delete after 30 days; access restricted to Safe-Circle |
| Poor rural network | SMS fallback; compress audio < 1 MB; queue upload on reconnect |

---

## 🤝 Contributing

Contributions are welcome! Please open an issue first to discuss what you'd like to change.

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add some feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 👨‍💻 Author

**Goutham KP**
[GitHub](https://github.com/GouthamKP3002)

---

> *Suraksha-Setu — Empowering Communities, One Neighbourhood at a Time* 🛡️
