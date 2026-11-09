# BillingGuru Deployment Guide

Complete guide to building and deploying BillingGuru to production.

## Pre-Deployment Checklist

Before deploying, ensure:

- [ ] All tests passing: `flutter test`
- [ ] No analysis issues: `flutter analyze`
- [ ] Code formatted: `dart format lib`
- [ ] Version updated in `pubspec.yaml`
- [ ] CHANGELOG updated
- [ ] Configuration files validated
- [ ] Database migrations tested
- [ ] Security review completed
- [ ] Performance optimized
- [ ] UI tested on target devices
- [ ] Backup strategy in place

## Version Management

### Update Version in pubspec.yaml

```yaml
version: 1.0.0+1
# Format: major.minor.patch+buildNumber
# Example: 1.2.3+4 (Version 1.2.3, Build 4)
```

### Semantic Versioning

- **Major**: Breaking changes, major features
- **Minor**: New features, backwards compatible
- **Patch**: Bug fixes, minor improvements

**Examples**:
```
1.0.0  Initial release
1.0.1  Bug fix
1.1.0  New features added
2.0.0  Breaking changes
```

## Windows Desktop Deployment

### Build Release Package

**Step 1: Build Release**
```bash
flutter build windows --release
```

**Step 2: Output Location**
```
build/windows/x64/runner/Release/
```

**Step 3: Package Files**
- `billing_guru.exe` - Main executable
- `flutter_windows.dll` - Flutter runtime
- `data/` - Assets and configuration
- Supporting DLLs - Dependencies

### Create MSIX Installer (Windows Store)

**Step 1: Generate Certificate**

For production, obtain a code signing certificate. For testing:
```bash
dart pub global activate msix
msix create --store  # Creates test certificate
```

**Step 2: Configure MSIX**

Edit `pubspec.yaml`:
```yaml
msix_config:
  display_name: Billing Guru
  publisher_display_name: Vasista Technologies
  identity_name: Vasista.BillingGuru
  msix_version: 1.0.0.0
  logo_path: assets/icons/app_icon.png
  capabilities: internetClient
  certificate_path: "C:\\path\\to\\certificate.pfx"
  certificate_password: "YOUR_PASSWORD"
```

**Step 3: Build MSIX**
```bash
flutter build windows --release
dart pub global activate msix
msix create
```

**Step 4: Output**
```
build/windows/x64/runner/Release/BillingGuru.msix
```

### Manual Distribution

**Create ZIP Package**:
1. Navigate to `build/windows/x64/runner/Release/`
2. Select all files
3. Create ZIP: `BillingGuru-v1.0.0-windows.zip`
4. Distribute via website or file sharing

**User Installation**:
1. Download and extract ZIP
2. Run `billing_guru.exe`
3. May require .NET Runtime (included in latest Windows)

## macOS Deployment

### Build Release

```bash
flutter build macos --release
```

**Output Location**:
```
build/macos/Build/Products/Release/billing_guru.app
```

### Create DMG Installer

**Step 1: Build App Bundle**
```bash
flutter build macos --release
```

**Step 2: Create DMG**
```bash
# Install create-dmg tool if needed
brew install create-dmg

# Create DMG from app
create-dmg \
  --volname "Billing Guru" \
  --volicon "assets/icons/app_icon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "billing_guru.app" 200 190 \
  --hide-extension "billing_guru.app" \
  --app-drop-link 600 190 \
  "BillingGuru-v1.0.0.dmg" \
  "build/macos/Build/Products/Release/billing_guru.app"
```

### Code Signing & Notarization

**Step 1: Sign App**
```bash
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application" \
  build/macos/Build/Products/Release/billing_guru.app
```

**Step 2: Notarize**
```bash
xcrun notarytool submit BillingGuru-v1.0.0.dmg \
  --apple-id your-apple-id@example.com \
  --team-id YOUR_TEAM_ID \
  --password your-app-specific-password
```

## Android Deployment

### Generate Keystore

**One-time Setup**:
```bash
keytool -genkey -v -keystore billing_guru.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias billing-guru-key
```

**Save keystore file securely** - you'll need it for future builds.

### Build Release APK

**Step 1: Create or Update Keystore Reference**

Edit `android/key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=billing-guru-key
storeFile=../billing_guru.jks
```

**Step 2: Build APK**
```bash
flutter build apk --release
```

**Output**:
```
build/app/outputs/flutter-apk/app-release.apk
```

### Build App Bundle (Google Play)

**Step 1: Build Bundle**
```bash
flutter build appbundle --release
```

**Output**:
```
build/app/outputs/bundle/release/app-release.aab
```

**Step 2: Upload to Google Play**
1. Sign in to Google Play Console
2. Create new app or update existing
3. Upload AAB file
4. Fill in app details, screenshots, description
5. Complete review and publish

### Testing Release Build

```bash
# Install on device
flutter install --release

# Run app
flutter run --release
```

## iOS Deployment

### Build Release IPA

**Step 1: Configure Code Signing**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner project
3. Go to Signing & Capabilities
4. Select development team
5. Create provisioning profiles

**Step 2: Build IPA**
```bash
flutter build ios --release
```

**Step 3: Archive in Xcode**
```bash
# If flutter build fails, use Xcode
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select Product > Archive
# 2. Select team and signing identity
# 3. Choose iOS Device as destination
```

### Upload to App Store

**Step 1: Create App Store Listing**
1. Sign in to App Store Connect
2. Create new app
3. Fill in app name, SKU, bundle identifier

**Step 2: Configure App Details**
- App Category
- Subtitle and description
- Keywords and support URLs
- Screenshots and preview videos
- App Privacy Policy

**Step 3: Set Prices and Availability**
- Free or paid
- Distribution regions
- Availability dates

**Step 4: Upload IPA**
```bash
# Validate IPA
xcrun altool --validate-app -f path/to/app.ipa \
  -t ios \
  -u your-apple-id@example.com \
  -p your-app-specific-password

# Upload IPA
xcrun altool --upload-app -f path/to/app.ipa \
  -t ios \
  -u your-apple-id@example.com \
  -p your-app-specific-password
```

**Step 5: Submit for Review**
1. In App Store Connect, click "Submit for Review"
2. Answer review questions
3. Wait for Apple's review (typically 24-48 hours)
4. App approved, then published

## Web Deployment

### Build Web Release

```bash
flutter build web --release
```

**Output**:
```
build/web/
├── index.html
├── main.dart.js
├── assets/
└── ...
```

### Deploy to Web Server

**Option 1: Firebase Hosting**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Initialize Firebase
firebase init hosting

# Deploy
flutter build web --release
firebase deploy
```

**Option 2: Manual Hosting**
1. Upload `build/web/` contents to web server
2. Configure web server for SPA routing (rewrite to index.html)
3. Ensure proper MIME types for .js files

**Nginx Configuration**:
```nginx
server {
  listen 80;
  server_name billing-guru.example.com;
  
  root /var/www/billing-guru;
  
  location / {
    try_files $uri $uri/ /index.html;
  }
  
  # Cache static assets
  location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
  }
  
  # Don't cache HTML
  location ~ \.html?$ {
    add_header Cache-Control "public, max-age=3600";
  }
}
```

## Database Migration Strategy

### Pre-Deployment

**Step 1: Test Migration**
```dart
// In database_initializer.dart
onUpgrade: (db, oldVersion, newVersion) {
  if (oldVersion < 2) {
    // Migration SQL
    db.execute('ALTER TABLE products ADD COLUMN new_field TEXT;');
  }
}
```

**Step 2: Backup Existing Data**
- Create database backup before migration
- Export data for verification
- Test with production-like data

**Step 3: Test Rollback**
- Verify you can restore old backup if needed
- Document rollback procedure

### Database Schema Updates

**Adding a Column**:
```sql
ALTER TABLE products ADD COLUMN new_field TEXT DEFAULT '';
```

**Removing a Column** (requires recreate):
```sql
-- Rename old table
ALTER TABLE products RENAME TO products_old;

-- Create new table without column
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  -- other columns
  -- removed: old_column
);

-- Copy data
INSERT INTO products SELECT id, name, ... FROM products_old;

-- Drop old table
DROP TABLE products_old;
```

**Creating Index**:
```sql
CREATE INDEX idx_products_name ON products(name);
```

## Performance Optimization

### Bundle Size Optimization

**Check Size**:
```bash
flutter build apk --analyze-size --release
```

**Reduce Size**:
1. Use image compression
2. Remove unused dependencies
3. Tree-shake unused code
4. Use ProGuard rules (Android)

### Code Obfuscation

**Enable Obfuscation**:
```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=./symbols

# iOS
flutter build ios --release --obfuscate --split-debug-info=./symbols
```

**Upload symbols for crash reporting**:
```bash
# For Firebase Crashlytics or similar
```

## Monitoring & Analytics

### Crash Reporting

**Setup Firebase Crashlytics** (optional):
1. Add firebase_crashlytics to pubspec.yaml
2. Initialize in main.dart
3. Set up error handlers
4. View crashes in Firebase Console

### Performance Monitoring

**Setup Firebase Performance Monitoring**:
1. Add cloud_firestore to pubspec.yaml
2. Track custom metrics
3. Monitor app startup time
4. Track frame rendering performance

## Rollback Procedure

### If Issue Found After Release

**Step 1: Identify Issue**
- Check crash reports
- Gather user feedback
- Determine severity

**Step 2: Fix and Rebuild**
- Fix issue in code
- Increment version
- Build new release

**Step 3: Re-deploy**

**Windows**:
- Update installer/ZIP
- Notify users to re-download

**macOS**:
- Update DMG on website
- Notify users

**Android**:
- Upload new APK/AAB to Google Play
- Roll out gradually (staged rollout)
- Monitor metrics

**iOS**:
- Submit new version to App Store
- Submit for expedited review if urgent
- Monitor feedback

**Web**:
- Rebuild and redeploy immediately
- Clear CDN cache if needed
- Roll out new version

## Deployment Checklist

### Before Building

- [ ] Version number updated
- [ ] CHANGELOG updated
- [ ] All tests pass
- [ ] Code analysis clean
- [ ] No debug logging
- [ ] Configuration correct
- [ ] API endpoints correct
- [ ] Database migrations tested

### After Building

- [ ] Build file size reasonable
- [ ] No obvious errors on launch
- [ ] Basic functionality tested
- [ ] All features working
- [ ] Performance acceptable
- [ ] Storage/permissions correct

### After Deployment

- [ ] Monitor crash reports
- [ ] Check user feedback
- [ ] Track performance metrics
- [ ] Verify database migrations applied
- [ ] Ensure users can update

## Release Notes Template

```markdown
# BillingGuru v1.2.0

## New Features
- Feature 1 description
- Feature 2 description

## Improvements
- Improvement 1
- Performance optimization 1
- UI/UX enhancement 1

## Bug Fixes
- Bug fix 1
- Bug fix 2

## Known Issues
- Known issue 1 (workaround: ...)

## Installation
[Installation instructions]

## Upgrade Notes
- Breaking change (if any)
- Migration required (if any)
```

## Troubleshooting Deployment

### Windows Installer Won't Run
- Check Windows version compatibility
- Ensure Visual C++ redistributables installed
- Try administrative mode
- Check disk space

### App Crashes on Android
- Check minimum API level
- Test on different Android versions
- Review Firebase Crashlytics
- Check for permission issues

### iOS App Rejected by App Store
- Review rejection reason
- Fix issues
- Resubmit with explanation
- May need expedited review request

### Web Performance Issues
- Enable compression on server
- Minify and tree-shake code
- Optimize images
- Use CDN for static assets

## Continuous Deployment

### GitHub Actions Example

```yaml
name: Deploy BillingGuru

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.13.2'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run tests
        run: flutter test
      
      - name: Build release
        run: flutter build web --release
      
      - name: Deploy to hosting
        run: |
          # Deploy script here
```

---

For more information, see [Getting Started](./01-getting-started.md) or [Troubleshooting](./08-troubleshooting.md).
