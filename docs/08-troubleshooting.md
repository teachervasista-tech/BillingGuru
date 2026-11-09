# BillingGuru Troubleshooting Guide

Solutions for common issues and problems.

## Installation & Setup Issues

### Issue: Flutter not found in PATH

**Error**: `flutter: command not found`

**Solution**:
1. Download Flutter SDK from https://flutter.dev/docs/get-started/install
2. Extract to a folder (e.g., `C:\flutter` on Windows)
3. Add to PATH environment variable:
   - **Windows**: 
     - Right-click "This PC" → Properties
     - Advanced system settings → Environment Variables
     - Add Flutter `bin` folder to PATH
   - **macOS/Linux**: 
     - Add to ~/.bashrc or ~/.zshrc: `export PATH="$PATH:/path/to/flutter/bin"`
     - Run: `source ~/.bashrc`
4. Verify: `flutter --version`

### Issue: "pub get" fails to download packages

**Error**: `Pub cache offline` or `Connection refused`

**Solution**:
1. Check internet connection
2. Clear pub cache:
   ```bash
   flutter pub cache repair
   ```
3. Get dependencies again:
   ```bash
   flutter pub get
   ```
4. If still failing, check pub.dev status at https://pub.dev

### Issue: Dart SDK version mismatch

**Error**: `Dart SDK version X.X.X does not satisfy constraints`

**Solution**:
1. Check your Dart version: `dart --version`
2. Update Flutter: `flutter upgrade`
3. Check pubspec.yaml SDK constraint: `sdk: ^3.13.2`
4. Update constraint if needed for your version

### Issue: Database initialization fails

**Error**: `DatabaseException: Cannot open database` or `No such file or directory`

**Solution**:
1. Ensure database directory exists:
   - Check app data directory permissions
   - Windows: `%APPDATA%/billing_guru/`
   - macOS: `~/Library/Application Support/billing_guru/`

2. Reset database:
   ```dart
   // Uncomment in main.dart temporarily
   await AppDatabase.instance.deleteDatabaseForDevelopment();
   ```

3. Restart application

4. Check logs for specific database errors

## Application Runtime Issues

### Issue: App crashes on startup

**Error**: `E/AndroidRuntime: FATAL EXCEPTION` or similar

**Steps to diagnose**:
1. Check the console output for stack trace
2. Look for specific error message
3. Check if database initialization failed
4. Verify configuration files are present

**Common causes**:
- Configuration files missing from assets
- Database schema issues
- Provider initialization failure

**Solution**:
1. Run with verbose logging: `flutter run -v`
2. Check `pubspec.yaml` assets section
3. Verify all config files exist in `assets/config/`
4. Check main.dart for initialization order

### Issue: Blank screen after launch

**Cause**: Splash screen stuck or initialization not complete

**Solution**:
1. Wait 3-5 seconds for database initialization
2. If still blank, check console for errors
3. Restart application
4. Try `flutter clean` then `flutter run`

### Issue: Navigation not working

**Error**: `No route named 'xxx'` or navigation doesn't respond

**Solution**:
1. Check GoRouter configuration in `app/router/router.dart`
2. Verify route name is defined: `GoRoute(name: 'billing')`
3. Use correct navigation:
   ```dart
   context.goNamed('billing');  // Replace
   context.pushNamed('detail');  // Push
   ```
4. Check route parameters match

### Issue: Database queries returning no results

**Problem**: Products, sales, or inventory data not appearing

**Solution**:
1. Verify data was added:
   - Add a test product in Settings
   - Check database file exists
   
2. Check database integrity:
   ```dart
   final products = await db.query('products');
   print('Total products: ${products.length}');
   ```

3. Verify queries in code
4. Check WHERE clauses and conditions
5. Test with `flutter analyze`

### Issue: Payment processing fails

**Error**: `Payment processing error` or `Invalid amount`

**Solution**:
1. Verify payment method is enabled in Settings
2. Check if payment amount is valid (> 0)
3. Verify cart has items
4. Check payment details are complete
5. Test with cash payment first

### Issue: Receipt printing fails

**Error**: `No printers found` or `Print failed`

**Solution**:
1. **Verify printer connection**:
   - Check printer is connected and powered on
   - Windows: Settings → Devices → Printers & scanners
   - macOS: System Preferences → Printers & Scanners

2. **Refresh available printers**:
   - Restart application
   - Restart printer
   - Check printer drivers installed

3. **Test print**:
   - Try printing from Notepad or Word first
   - Verify printer is default (optional)

4. **PDF Export fallback**:
   - Save receipt as PDF if printer unavailable
   - Check `assets/config/receipt_business_details.txt`

### Issue: Barcode scanner not recognized

**Error**: `Camera permission denied` or `Scanner device not found`

**Solution**:
1. **Check permissions**:
   - Windows: Grant camera access
   - Android: Grant camera permission at runtime
   - iOS: Add camera permission to Info.plist

2. **Verify scanner configuration**:
   - Settings → Scanner Settings
   - Ensure barcode types are enabled

3. **Test scanner**:
   - Try using different barcode types
   - Test with QR code if Code 128 fails

4. **Fallback to manual entry**:
   - Use SKU/product code search
   - Type product code in search field

## Performance Issues

### Issue: App is slow or laggy

**Cause**: Excessive database queries or UI rebuilds

**Solution**:
1. Check for unused provider watches:
   ```dart
   // Bad: Rebuilds on every state change
   final data = ref.watch(provider);
   
   // Good: Rebuild only on needed field
   final length = ref.watch(provider.select((p) => p.length));
   ```

2. Minimize database queries
3. Use pagination for large lists
4. Profile app: `flutter run --profile`

### Issue: Reports take too long to generate

**Cause**: Large dataset processing

**Solution**:
1. Limit date range for reports
2. Generate reports off-peak
3. Filter by category to narrow data
4. Check database indexes are created:
   - Run `flutter run -v` and check SQL execution time

### Issue: High memory usage

**Cause**: Large images or unoptimized data loading

**Solution**:
1. Limit loaded data:
   ```dart
   // Use pagination
   const pageSize = 50;
   final products = await db.query(
     'products',
     limit: pageSize,
     offset: pageNumber * pageSize,
   );
   ```

2. Dispose large objects
3. Clear image cache periodically
4. Check for memory leaks with DevTools

## Data Issues

### Issue: Lost or corrupted data

**Error**: Data not persisting between sessions

**Solution**:
1. Create backup immediately:
   - Settings → Data → Create Backup
   - Save backup file to external location

2. Check file system permissions:
   - Ensure app can write to storage
   - Check free space on disk

3. Restart application
4. If data still lost:
   - Restore from backup if available
   - Re-enter data manually

### Issue: Duplicate products

**Cause**: Product added multiple times with different IDs

**Solution**:
1. Identify duplicates:
   - Search for product name
   - Check SKU/barcode codes
   
2. Delete duplicates:
   - Inventory → Select product
   - Click delete button
   - Confirm action

3. Merge data if needed:
   - Combine stock quantities
   - Delete duplicate entry

### Issue: Incorrect totals in sales

**Error**: Subtotal, tax, or total amount wrong

**Solution**:
1. Verify item prices are correct
2. Check tax rate configuration:
   - Settings → Tax → Review tax rate
3. Review applied discounts
4. Check currency decimal places
5. Recalculate manually to verify

### Issue: Inventory stock mismatch

**Error**: Stock count doesn't match physical inventory

**Solution**:
1. **Physical count**:
   - Count products in store
   - Compare with app inventory

2. **Reconcile differences**:
   - Adjust stock in app
   - Inventory → Select product → Adjust Stock
   - Enter correct quantity with reason

3. **Audit adjustments**:
   - Check stock adjustment history
   - Review loss or damage entries

4. **Prevent future issues**:
   - Regular inventory audits
   - Train staff on inventory entry
   - Use barcode scanning to reduce errors

## Configuration Issues

### Issue: Features not appearing

**Error**: Feature disabled or not showing in UI

**Solution**:
1. Check `assets/config/features.json`:
   - Verify feature is set to `true`
   - Check JSON syntax with validator

2. Restart application
3. Verify feature is implemented for your platform
4. Check permissions (if feature requires permissions)

### Issue: Theme not applying

**Error**: Colors or theme not changing

**Solution**:
1. Verify `assets/config/color_themes.json`:
   - Check valid hex color codes
   - Ensure JSON format is correct

2. Clear app cache:
   ```bash
   flutter clean
   flutter pub get
   ```

3. Restart application
4. Try default theme first
5. Check theme compatibility with platform

### Issue: Currency not formatting correctly

**Error**: Price showing as `1000.5` instead of `₹ 1,000.50`

**Solution**:
1. Edit `assets/config/currency.txt`:
   ```
   decimal_places=2
   thousand_separator=,
   decimal_separator=.
   ```

2. Restart application
3. Verify currency code matches: `code=INR`
4. Check symbol: `symbol=₹`

### Issue: Receipt template not saving

**Error**: Custom receipt settings not persisting

**Solution**:
1. Check SharedPreferences:
   - Verify storage permissions
   - Check free storage space

2. Manually set receipt config:
   - Edit `assets/config/receipt_business_details.txt`
   - Restart application

3. Test with default template
4. Clear app cache and retry

## Platform-Specific Issues

### Windows Issues

**Issue: App won't run on Windows**
- Ensure Visual C++ redistributables installed
- Run `flutter run -d windows`
- Check Windows 10/11 version

**Issue: Printer integration not working**
- Verify printer drivers installed
- Check Windows print spooler service running
- Restart print spooler service

### macOS Issues

**Issue: Camera permission denied**
- macOS → System Preferences → Security & Privacy
- Grant camera access to app
- May need to restart application

**Issue: Notarization warning on M1/M2 Macs**
- App requires valid code signing
- Check Flutter setup: `flutter doctor -v`

### Android Issues

**Issue: App crashes on Android device**
- Check minimum SDK version: minSdkVersion 21
- Test on different Android versions
- Check permissions in AndroidManifest.xml

**Issue: Storage permission issues**
- Android 11+: Use scoped storage
- Request runtime permissions
- Check `android/app/src/main/AndroidManifest.xml`

### iOS Issues

**Issue: Camera not working on iOS**
- Add privacy description to Info.plist:
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>Camera needed for barcode scanning</string>
  ```
- Restart app after permission change

## Debug Mode

### Enable Verbose Logging

```bash
flutter run -v
```

Shows detailed logs for:
- Plugin initialization
- Database operations
- Network requests
- Widget rebuilds

### Flutter DevTools

```bash
flutter pub global activate devtools
devtools
```

Features:
- Widget inspector
- Performance profiler
- Memory debugger
- Network monitor
- Logging view

### Database Debugging

Enable SQL logging in database.dart:
```dart
// In AppDatabase
static const bool _debugMode = true;  // Set to true for logging
```

Logs all SQL queries to console.

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| `RepositoryException` | Database or network error | Check database connection, retry operation |
| `StateNotifierException` | Invalid state transition | Check provider logic, verify input |
| `FormatException` | JSON parsing error | Verify configuration file syntax |
| `SocketException` | Network connection lost | Check internet, retry |
| `FileSystemException` | File read/write error | Check permissions, disk space |
| `PlatformException` | Platform-specific error | Check platform-specific logs |

## Getting Help

### Check These First

1. **Console Output**: Full error message and stack trace
2. **Flutter Doctor**: `flutter doctor -v` diagnoses environment issues
3. **Logs**: Check app debug logs for clues
4. **Recent Changes**: Was this working before? What changed?

### Resources

- **Flutter Documentation**: https://flutter.dev/docs
- **Dart Documentation**: https://dart.dev/guides
- **pub.dev Packages**: https://pub.dev (for package issues)
- **GitHub Issues**: Check project issues
- **Stack Overflow**: Tag questions with `flutter`

### Reporting Issues

When reporting problems, include:
1. Full error message and stack trace
2. Steps to reproduce the issue
3. Expected vs actual behavior
4. Device/platform information
5. Recent configuration or code changes
6. Console output from `flutter run -v`

---

Still having issues? Check [Architecture](./05-architecture.md) for technical details or contact support.
