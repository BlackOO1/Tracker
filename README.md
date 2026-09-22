# 💰 Budget Planner — Expense Tracker App

A beautiful, fully offline personal budget planner built with **Flutter & Dart**.

[![Build APK](https://github.com/BlackOO1/Tracker/actions/workflows/build_apk.yml/badge.svg)](https://github.com/BlackOO1/Tracker/actions/workflows/build_apk.yml)

---

## 📱 Features

| Feature | Details |
|---------|---------|
| **Dark Mode** | Deep navy `#1C1F31` with pastel accents (teal, lavender, pink) |
| **5 Budget Types** | Expenses, Bills (with due dates), Income, Debt, Savings |
| **10 Currencies** | USD, INR, EUR, GBP, JPY, PHP, AED, CAD, AUD, SGD |
| **Charts** | Pie Chart · Monthly Line Chart · Expected vs Actual Bar Chart |
| **KPI Dashboard** | Amount Left to Spend, Income, Expenses, Debt, Savings + On Track badge |
| **Live Clock** | Real date & time shown throughout the app |
| **Transaction History** | Full date/time stamp, search, filter by type, swipe to delete |
| **Paid Tracking** | Mark bills/debt as paid, track due dates |
| **100% Offline** | Hive local database — no internet, no account required |

---

## 📥 Download & Install (Android)

### Option 1: Direct APK Download (Easiest)
1. Go to [Releases](https://github.com/BlackOO1/Tracker/releases)
2. Download `app-release.apk`
3. On your Android phone: **Settings → Apps → Special Access → Install Unknown Apps → Allow for your file manager**
4. Open the downloaded APK → **Install**

### Option 2: Build with Android Studio
1. Clone this repo
2. Open the project root folder in Android Studio
3. Let it sync (File → Sync Project with Gradle)
4. Run on emulator or device (▶ button)

---

## 🛠️ Development Setup

### Requirements
- Flutter SDK ≥ 3.0  ([flutter.dev/docs/get-started/install](https://flutter.dev/docs/get-started/install))
- Android Studio (with Android SDK installed)
- Java 17

### Run Locally
```bash
flutter pub get
flutter run
```

### Build APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build Play Store Bundle
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## 🤖 Automatic Cloud Build (GitHub Actions)

Every time you push to `main`, GitHub automatically:
1. Downloads Flutter SDK & Android SDK
2. Compiles the release APK and AAB
3. Creates a new **GitHub Release** with download links

Check the [Actions tab](https://github.com/BlackOO1/Tracker/actions) to see build status.

---

## 🗂️ Project Structure

```
Tracker/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── constants/
│   │   ├── app_colors.dart          # Color palette + currency rates
│   │   └── app_theme.dart           # Material 3 dark theme
│   ├── models/
│   │   ├── transaction_model.dart   # Transaction data model (Hive)
│   │   └── category_model.dart      # Category budget model (Hive)
│   ├── services/
│   │   ├── auth_service.dart        # Google Sign-In + Firebase Auth
│   │   └── sms_parser_service.dart  # SMS transaction parsing
│   ├── state/
│   │   └── budget_provider.dart     # All business logic & calculations
│   └── ui/
│       ├── screens/
│       │   ├── main_shell.dart      # Navigation shell
│       │   ├── overview_screen.dart # Dashboard + KPI cards
│       │   ├── budgets_screen.dart  # Category budget allocations
│       │   ├── history_screen.dart  # Full transaction history
│       │   ├── analytics_screen.dart# Pie / Line / Bar charts
│       │   ├── login_screen.dart    # Login / authentication
│       │   ├── pin_screen.dart      # PIN lock screen
│       │   ├── admin_screen.dart    # Admin settings
│       │   └── sms_suggestions_screen.dart # SMS auto-detect
│       └── widgets/
│           ├── add_transaction_sheet.dart  # Add transaction form
│           ├── kpi_card.dart               # KPI card widget
│           └── section_card.dart           # Card container widget
├── android/                         # Android platform config
├── assets/
│   └── icon.png                     # App launcher icon
├── test/                            # Unit & widget tests
├── pubspec.yaml                     # Flutter dependencies
└── .github/
    └── workflows/
        └── build_apk.yml           # CI/CD: auto-build APK on push
```

---

## 🎨 Design

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#1C1F31` | App background |
| Surface | `#282C40` | Cards |
| Teal | `#5DD8D0` | Income, primary accent |
| Pink | `#ECB0CC` | Debt |
| Lavender | `#B3ACFA` | Secondary accent |
| Peach | `#F79F8F` | Expenses |
| Yellow | `#FDE288` | Bills |
| Mint | `#C6F1B2` | Savings |

---

*Built with Flutter ❤️ • Data stored locally with Hive • Zero cloud dependency*
