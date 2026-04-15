# Megha Tuition Classes - Flutter Mobile App

This project is a Tuition Fees Management System built with Flutter, based on a premium Figma design.

## Prerequisites

The Flutter SDK is installed locally in this workspace at `./flutter_sdk`.

## How to Run

To run the project, you need to use the local Flutter binary. You can do this by adding it to your PATH or using the full path.

### 1. Set up Flutter Environment
Run this in your terminal to make the `flutter` command available:
```bash
export PATH="$PATH:$(pwd)/flutter_sdk/bin"
```

### 2. Run the Application
You can run the app for the web (Chrome) to preview the design layout:
```bash
flutter run -d chrome
```

If you have a mobile emulator or physical device connected, you can simply run:
```bash
flutter run
```

## Project Structure
- `lib/theme/`: Core design tokens and `AppTheme`.
- `lib/screens/`: All application screens (Splash, Login, Dashboard, etc.).
- `lib/widgets/`: Reusable UI components like `StatCard` and `StatusChip`.
- `assets/images/`: App branding and logos.

## Features Implemented
- [x] Splash & Login Flow
- [x] Dashboard with Stats & Transactions
- [x] Student List with Search/Filter
- [x] Fee Collection Interface
- [x] 4-Step Registration Wizard
