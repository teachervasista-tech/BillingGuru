# Getting Started with BillingGuru

This guide will help you get BillingGuru up and running on your system.

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.13.2 or higher)
   - Download from: https://flutter.dev/docs/get-started/install
   - Verify installation: `flutter --version`

2. **Dart SDK** (comes with Flutter)
   - Verify: `dart --version`

3. **Git** (for version control)
   - Download from: https://git-scm.com/

### Platform-Specific Requirements

#### Windows
- Windows 10 or later
- Visual Studio Build Tools or Visual Studio Community
- Windows SDK

#### macOS
- macOS 10.11 or later
- Xcode 12 or later
- CocoaPods

#### Android
- Android Studio or Android SDK
- Android SDK version 21 or later
- Android Emulator (optional, for testing)

#### iOS
- Xcode 12 or later
- iOS 11 or later
- CocoaPods

## Installation Steps

### 1. Clone the Repository

```bash
git clone <repository-url>
cd BillingGuru
```

### 2. Install Dependencies

```bash
dart pub get
```

This command downloads all required packages defined in `pubspec.yaml`.

### 3. Format Code (Optional but Recommended)

```bash
dart format lib
```

### 4. Run Analysis

```bash
flutter analyze
```

This checks for any lint issues or errors in your code.

### 5. Run the Application

#### Windows
```bash
flutter run -d windows
```

#### macOS
```bash
flutter run -d macos
```

#### iOS
```bash
flutter run -d ios
```

#### Android
```bash
flutter run -d android
```

## Build for Production

### Windows

```bash
flutter build windows --release
```

Output: `build/windows/x64/runner/Release/`

### macOS

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/`

### iOS

```bash
flutter build ios --release
```

### Android

```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

## Initial Setup

After launching BillingGuru for the first time:

1. **Database Initialization**
   - The app automatically creates SQLite database
   - Default location: Platform-specific app data directory

2. **Configuration Files**
   The app loads several configuration files from assets:
   - `features.json` - Feature flags
   - `color_themes.json` - UI themes
   - `currency.txt` - Currency settings
   - `financial_year_start.txt` - Financial year configuration
   - `invoice_sequence.txt` - Invoice numbering
   - `receipt_business_details.txt` - Receipt header/footer

3. **First Run Setup**
   - Navigate to Settings to configure:
     - Business details
     - Tax rates
     - Payment methods
     - Receipt template preferences

## Project Structure

```
BillingGuru/
├── lib/
│   ├── main.dart              # Application entry point
│   ├── app/                   # Application-level widgets
│   │   ├── app.dart          # Main app configuration
│   │   ├── theme.dart        # App theming
│   │   ├── router/           # Navigation routing
│   │   └── screens/          # Screen layouts
│   ├── core/                 # Core utilities and services
│   │   ├── config/           # Configuration management
│   │   ├── database/         # Database layer
│   │   ├── printing/         # Receipt printing
│   │   └── tax/              # Tax calculation
│   └── features/             # Feature modules
│       ├── cart/             # Shopping cart
│       ├── checkout/         # Payment & checkout
│       ├── inventory/        # Product management
│       ├── sales/            # Sales tracking
│       ├── reports/          # Business reports
│       └── settings/         # App settings
├── assets/
│   ├── icons/               # App icons
│   ├── images/              # UI images
│   └── config/              # Configuration files
├── test/                    # Unit and widget tests
└── pubspec.yaml            # Dependencies and project config
```

## Verification

To verify the installation is successful:

1. Run the application: `flutter run -d windows` (or your platform)
2. You should see:
   - Main dashboard loading
   - Navigation menu on the left
   - No errors in the console
   - Database tables created in the database

## Environment Variables

If using environment-specific configuration, create a `.env` file (if applicable):

```
API_BASE_URL=http://localhost:8000
DEBUG_MODE=false
```

## Troubleshooting Installation Issues

### Issue: "Flutter command not found"
**Solution**: Add Flutter to your PATH
- Windows: Add Flutter bin directory to system PATH
- macOS/Linux: Add to ~/.bashrc or ~/.zshrc

### Issue: "Pub get" fails
**Solution**: 
```bash
flutter pub cache repair
flutter pub get
```

### Issue: Build fails with "SDK not found"
**Solution**: Run `flutter doctor` to diagnose issues
```bash
flutter doctor
```

### Issue: Database errors on first run
**Solution**: Clear app data and restart
- Windows: Delete the app data directory and rerun
- Android: Uninstall app and reinstall

## Next Steps

After successful installation:

1. **Read the User Guide** - Learn how to use the application
2. **Configure Settings** - Set up your business details
3. **Add Sample Data** - Create test products and categories
4. **Explore Features** - Familiarize yourself with all features

## Getting Help

- Check [Troubleshooting](./08-troubleshooting.md) for common issues
- Review [Development Guide](./09-development-guide.md) for technical details
- Check Flutter documentation: https://flutter.dev/docs

---

**Next**: Read the [User Guide](./02-user-guide.md) to learn how to use BillingGuru.
