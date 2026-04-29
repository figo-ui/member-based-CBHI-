# Running Member App on Android Phone

## ✅ Setup Complete

### Device Detected
- **Phone**: Samsung SM A047F
- **Android Version**: 14 (API 34)
- **Connection**: USB (RZ8T91HFG4L)

### Build Status
- ✅ Flutter environment verified
- ✅ Dependencies installed
- ✅ Localization enabled (`generate: true`)
- ✅ Building APK for your phone...

---

## 🚀 What's Happening Now

The app is currently building and will automatically install on your phone. This process includes:

1. **Gradle Build** (in progress) - Compiling Android app
2. **APK Generation** - Creating installable package
3. **Installation** - Installing on your Samsung phone
4. **Launch** - App will open automatically

**First build takes 3-5 minutes. Subsequent builds are much faster!**

---

## 📱 Once the App Launches

### Test the Registration Flow

1. **Start Registration**
   - Tap "Start New Registration"
   - Fill in personal information
   - Use test phone: `+251935092404`

2. **Identity Verification**
   - Upload ID document (or skip in demo mode)
   - OCR will extract ID number
   - Name matching will verify

3. **Select Membership**
   - Choose benefit package
   - Review coverage details

4. **Payment**
   - Select payment method
   - Complete via Chapa (test mode)

### Test Login

**OTP Login**:
- Phone: `+251935092404`
- OTP will be sent via SMS (or shown in logs if sandbox mode)

---

## 🔧 Configuration

### API Endpoint
```
https://member-based-cbhi.vercel.app/api/v1
```

The app is configured to connect to the production backend on Vercel.

### Features Available

- ✅ Registration (multi-step with ID verification)
- ✅ OTP Login (SMS-based)
- ✅ Dashboard (coverage status, notifications)
- ✅ Digital Card (QR code)
- ✅ Payment (Chapa integration)
- ✅ Renewal
- ✅ Grievances
- ✅ Indigent Application
- ✅ Family Management
- ✅ Localization (English, Amharic, Afaan Oromo)

---

## 🐛 Troubleshooting

### If Build Fails

**Check USB Debugging**:
1. On your phone: Settings → Developer Options → USB Debugging (enabled)
2. Accept the "Allow USB debugging?" prompt on your phone

**Reconnect Phone**:
```bash
cd member_based_cbhi
flutter devices
# Should show: SM A047F (mobile) • RZ8T91HFG4L
```

**Clean and Rebuild**:
```bash
cd member_based_cbhi
flutter clean
flutter pub get
flutter run -d RZ8T91HFG4L
```

### If App Crashes on Launch

**Check Logs**:
```bash
flutter logs
```

**Common Issues**:
- **Network Error**: Check phone has internet connection
- **API Error**: Backend might be down (check health endpoint)
- **Permission Error**: Grant camera/storage permissions when prompted

---

## 📊 Build Output

The build process will show:
```
Running Gradle task 'assembleDebug'...
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XX.XMB)
Installing build/app/outputs/flutter-apk/app-debug.apk...
Waiting for SM A047F to report its views...
Debug service listening on ws://127.0.0.1:XXXXX/XXXXXXXX
Synced XX.XMB
```

When you see "Synced", the app is running on your phone!

---

## 🎯 Next Steps After Launch

1. **Test Registration Flow**
   - Complete a full registration
   - Upload ID document
   - Verify name matching works
   - Check duplicate ID prevention

2. **Test Payment**
   - Select a benefit package
   - Go through Chapa payment flow
   - Verify coverage becomes active

3. **Test Digital Card**
   - View QR code
   - Verify it displays correctly

4. **Test Localization**
   - Switch between English, Amharic, Afaan Oromo
   - Verify all strings display correctly

---

## 🔄 Hot Reload

While the app is running, you can make code changes and press:
- **`r`** in the terminal to hot reload (fast)
- **`R`** to hot restart (slower, full restart)
- **`q`** to quit

---

## 📱 Installing on Other Devices

### Build Release APK

```bash
cd member_based_cbhi
flutter build apk --release --dart-define=CBHI_API_BASE_URL=https://member-based-cbhi.vercel.app/api/v1
```

APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

Transfer this file to any Android phone and install.

### Build App Bundle (for Play Store)

```bash
flutter build appbundle --release --dart-define=CBHI_API_BASE_URL=https://member-based-cbhi.vercel.app/api/v1
```

Bundle will be at: `build/app/outputs/bundle/release/app-release.aab`

---

## ✅ Success Indicators

You'll know the app is working when you see:

1. **Splash Screen** - Maya City CBHI logo
2. **Welcome Screen** - "Start New Registration" button
3. **Language Selector** - English/Amharic/Oromo options
4. **No Errors** - App doesn't crash on launch

---

## 📞 Support

If you encounter issues:
1. Check the terminal output for error messages
2. Run `flutter logs` to see detailed logs
3. Check `INTEGRATION_VERIFICATION.md` for system status
4. Verify backend is running: `https://member-based-cbhi.vercel.app/api/v1/health`

---

**Status**: ✅ Building and installing on your Samsung phone...  
**Estimated Time**: 3-5 minutes (first build)  
**Next**: App will launch automatically when build completes
