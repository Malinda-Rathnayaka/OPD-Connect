# 🏥 OPD Connect — Government Hospital Booking & Queue Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-4CAF50?style=for-the-badge)](https://flutter.dev)
[![Figma Design](https://img.shields.io/badge/Figma-OPD%20Connect%20UI-F24E1E?style=for-the-badge&logo=figma&logoColor=white)](https://www.figma.com/design/Uuu84aeXApggGVkASJ4D4x/OPD-Connect-UI?node-id=134-3068)

> **OPD Connect** is a mobile healthcare solution developed for government hospitals in Sri Lanka. It eliminates early-morning physical queues by enabling remote Outpatient Department (OPD) slot reservations, real-time live queue tracking, automated departure alerts, and administrative management.

---

## 📌 Table of Contents

- [Features by User Role](#-features-by-user-role)
- [Design & UI System](#-design--ui-system)
- [Architecture & Tech Stack](#-architecture--tech-stack)
- [Project Directory Structure](#-project-directory-structure)
- [Getting Started](#-getting-started)
- [Environment Configuration (.env)](#-environment-configuration-env)
- [Authentication & Approval Workflow](#-authentication--approval-workflow)
- [Security & Best Practices](#-security--best-practices)
- [Changelog & Roadmap](#-changelog--roadmap)
- [Authors & Acknowledgments](#-authors--acknowledgments)

---

## 🚀 Features by User Role

### 👤 Patient
* **Remote Slot Booking**: Reserve morning/evening OPD slots from home for selected hospitals and departments.
* **Live Queue Tracker**: Real-time position tracking in the doctor's queue.
* **Smart Departure Alerts**: Notifies patients when to leave home based on estimated waiting times.
* **Medical Profile**: View past appointments and consultation histories.

### 🩺 Doctor
* **Queue Management**: View list of waiting patients, call next token, and mark consultations complete.
* **Consultation Notes**: Record diagnoses and digital prescriptions.
* **Admin Verification Gate**: Newly registered doctors require approval by a hospital administrator before accessing doctor features.

### 🛡️ Administrator
* **Executive Dashboard**: Real-time overview of total registered users, patients, doctors, and pending doctor registrations.
* **Doctor Approvals**: Review doctor credentials, approve, or reject registrations.
* **User Management (CRUD)**: Search, view detailed profile information, edit user details, and delete accounts.
* **Role-Based Access Control**: Enforces security policies across Firestore and UI routing.

---

## 🎨 Design & UI System

The application UI is designed based on the **[OPD Connect Figma Design](https://www.figma.com/design/Uuu84aeXApggGVkASJ4D4x/OPD-Connect-UI?node-id=134-3068)**.

### Color Palette

| Token | Hex Code | Usage |
|---|---|---|
| **Primary Brand** | `#1E40AF` / `#2563EB` | App bars, primary action buttons, branding |
| **Dark Surface** | `#0F172A` | Admin header, typography headers |
| **Medical Teal** | `#0D9488` / `#059669` | Patients, success states, confirmed slots |
| **Specialist Violet** | `#7C3AED` / `#6D28D9` | Doctors, specialization badges |
| **Alert Amber** | `#F59E0B` / `#D97706` | Pending approvals, queue warnings |
| **Background** | `#F8FAFC` | Screen backgrounds, cards, list surfaces |

---

## 🛠️ Architecture & Tech Stack

* **Frontend Framework**: Flutter (Dart)
* **Authentication**: Firebase Authentication (Email/Password) & EmailJS OTP
* **Database**: Google Cloud Firestore (Real-time streams & collections)
* **Environment Management**: `flutter_dotenv`
* **Design Standards**: Material 3 Design Guidelines

---

## 📁 Project Directory Structure

```text
opd_connect/
├── assets/
│   └── images/                     # Splash & onboarding illustrations
├── lib/
│   ├── main.dart                   # Application entry point & dotenv loader
│   ├── firebase_options.dart       # Firebase platform configuration
│   ├── models/
│   │   └── user_model.dart         # User data model & role definitions
│   ├── services/
│   │   ├── auth_service.dart       # Authentication, EmailJS OTP & profile management
│   │   ├── admin_service.dart      # Admin statistics & approval actions
│   │   └── seed_service.dart       # Automatic admin account initialization
│   ├── widgets/
│   │   └── auth_wrapper.dart       # Role-based route guard & redirector
│   └── screens/
│       ├── auth/
│       │   ├── splash_screen.dart   # Onboarding carousel
│       │   ├── login_screen.dart    # Login with role verification
│       │   └── register_screen.dart # Multi-role registration & Email OTP
│       └── admin/
│           ├── admin_dashboard_screen.dart       # Main admin overview & stats
│           ├── admin_user_list_screen.dart       # Patient & Doctor lists (CRUD)
│           ├── admin_user_detail_screen.dart     # User profile view/edit
│           └── admin_pending_doctors_screen.dart # Doctor approval queue
├── .env.example                    # Sample environment variable template
├── .gitignore                      # Git ignore file (excludes secrets & .env)
├── pubspec.yaml                    # Dependencies & asset manifests
└── README.md                       # Project documentation