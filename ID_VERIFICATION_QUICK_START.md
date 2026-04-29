# ID Verification - Quick Start Guide

## 🚀 Quick Setup

### 1. Generate Localization Files

```bash
cd member_based_cbhi
flutter gen-l10n
```

### 2. Verify Backend Configuration

Ensure `.env` has Google Vision API configured:

```env
# Google Vision API (for OCR)
GOOGLE_CLOUD_PROJECT_ID=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

### 3. Create Test User (for duplicate testing)

```bash
cd backend
node scripts/seed-admin.js
```

Or manually create a user with ID number `TEST-ID-001` in the database.

---

## 🧪 Quick Test

### Test Name Match + New ID (Happy Path)

1. **Start the app**:
   ```bash
   cd member_based_cbhi
   flutter run -d chrome
   ```

2. **Register new household**:
   - Personal Info:
     - First Name: `Abebe`
     - Father Name: `Bekele`
     - Last Name: `Tadesse`
     - Phone: `+251912345678`
   - Confirm information
   
3. **Identity Verification**:
   - Select Identity Type: `National ID`
   - Upload ID document (or use test image)
   - Wait for OCR (2-5 seconds)
   
4. **Verify Results**:
   - ✅ Name matching shows green "Names match"
   - ✅ ID availability shows green "ID number is available"
   - ✅ Continue button is enabled
   
5. **Proceed**: Click "Continue to Membership"

---

## 🔴 Quick Test - Name Mismatch

1. **Personal Info**: Enter name `Abebe Bekele Tadesse`
2. **Upload ID**: Use ID with different name `Alemayehu Girma`
3. **Verify**:
   - ❌ Name matching shows red "Names do not match"
   - ⚠️ Warning message displayed
   - 🚫 Continue button is disabled

---

## 🔴 Quick Test - Duplicate ID

1. **Personal Info**: Enter any name
2. **Upload ID**: Use ID number `TEST-ID-001` (pre-registered)
3. **Verify**:
   - ❌ ID availability shows red "ID number already registered"
   - 🚫 Continue button is disabled

---

## 📱 Test on Mobile

```bash
# Android
flutter run -d android

# iOS
flutter run -d ios
```

Mobile has camera option for scanning ID documents.

---

## 🐛 Common Issues

### Issue: "flutter gen-l10n" fails

**Solution**:
```bash
flutter clean
flutter pub get
flutter gen-l10n
```

### Issue: OCR returns empty name

**Cause**: Poor image quality or Google Vision API not configured

**Solution**:
- Use higher quality image
- Verify `GOOGLE_APPLICATION_CREDENTIALS` in backend `.env`
- Check backend logs for Vision API errors

### Issue: Duplicate check always shows "available"

**Cause**: Backend not running or network error

**Solution**:
- Verify backend is running: `http://localhost:3000/api/v1/health`
- Check browser console for network errors
- Verify API URL in Flutter app

### Issue: Name matching always shows "mismatch"

**Cause**: Name format difference (e.g., Amharic vs Latin script)

**Solution**:
- Enter names in Latin script (English characters)
- Ensure ID document has Latin script text
- Check name normalization logic in `identity_cubit.dart`

---

## 📊 Monitoring

### Backend Logs

```bash
cd backend
npm run start:dev
```

Watch for:
- `[VisionService] Validating ID document...`
- `[CbhiService] Checking ID availability: 123456789012`
- `[CbhiService] ID 123456789012 is available: true`

### Frontend Debug

Add breakpoints in:
- `identity_cubit.dart` → `_runOcr()` method
- `identity_cubit.dart` → `_checkIdAvailability()` method
- `identity_verification_screen.dart` → `_canSubmit()` method

---

## 🔧 Configuration

### Adjust Name Matching Threshold

Edit `member_based_cbhi/lib/src/registration/identity/identity_cubit.dart`:

```dart
// Current: 2 tokens must match
if (matchCount >= 2) {
  return IdNameMatchStatus.matched;
}

// Stricter: 3 tokens must match
if (matchCount >= 3) {
  return IdNameMatchStatus.matched;
}
```

### Adjust Duplicate Check Timeout

Edit `member_based_cbhi/lib/src/cbhi_data.dart`:

```dart
// Current: 10 second timeout
final response = await http.get(
  uri,
  headers: headers,
).timeout(const Duration(seconds: 10));

// Longer timeout: 30 seconds
.timeout(const Duration(seconds: 30));
```

---

## 📚 Key Files

### Frontend
- `lib/src/registration/identity/identity_cubit.dart` - Business logic
- `lib/src/registration/identity/identity_verification_screen.dart` - UI
- `lib/l10n/app_en.arb` - English strings
- `lib/l10n/app_am.arb` - Amharic strings
- `lib/l10n/app_om.arb` - Afaan Oromo strings

### Backend
- `src/vision/vision.service.ts` - OCR logic
- `src/cbhi/cbhi.service.ts` - Duplicate check logic
- `src/cbhi/cbhi.controller.ts` - API endpoints

### Documentation
- `ID_VERIFICATION_IMPLEMENTATION.md` - Full implementation details
- `ID_VERIFICATION_TEST_PLAN.md` - Comprehensive test scenarios
- `ID_VERIFICATION_QUICK_START.md` - This file

---

## 🎯 Success Checklist

- [ ] Localization files generated (`flutter gen-l10n`)
- [ ] Backend running with Vision API configured
- [ ] Test user created with ID `TEST-ID-001`
- [ ] Happy path test passes (name match + new ID)
- [ ] Name mismatch blocks submission
- [ ] Duplicate ID blocks submission
- [ ] All three languages display correctly
- [ ] Mobile camera works (if testing on device)

---

## 🆘 Need Help?

1. Check `ID_VERIFICATION_IMPLEMENTATION.md` for detailed architecture
2. Check `ID_VERIFICATION_TEST_PLAN.md` for test scenarios
3. Review backend logs for API errors
4. Check browser console for frontend errors
5. Contact development team

---

## 🚢 Deployment Checklist

Before deploying to production:

- [ ] All tests pass
- [ ] Localization verified in all three languages
- [ ] Google Vision API quota sufficient
- [ ] Rate limiting configured (20 req/min on duplicate check)
- [ ] Error messages are user-friendly
- [ ] Fail-open behavior tested (network errors)
- [ ] Performance acceptable (< 10s total)
- [ ] Audit logging enabled
- [ ] Documentation updated

---

## 📈 Metrics to Monitor

After deployment, monitor:

1. **OCR Success Rate**: % of successful ID extractions
2. **Name Match Rate**: % of names that match
3. **Duplicate Attempts**: # of duplicate ID attempts
4. **Average Processing Time**: Time from upload to results
5. **Error Rate**: % of OCR failures or API errors

---

## 🔄 Rollback Plan

If issues occur in production:

1. **Disable name matching**:
   - Set `nameMatchStatus` to always return `matched`
   - Deploy hotfix

2. **Disable duplicate check**:
   - Set `idAvailabilityStatus` to always return `available`
   - Deploy hotfix

3. **Full rollback**:
   - Revert to previous version
   - Re-enable manual ID entry

---

## 📞 Support Contacts

- **Technical Issues**: dev-team@example.com
- **Google Vision API**: cloud-support@example.com
- **User Support**: support@example.com

---

**Last Updated**: 2026-04-29
**Version**: 1.0.0
