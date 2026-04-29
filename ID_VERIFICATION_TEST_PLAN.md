# ID Verification Testing Plan

## Overview

This document provides comprehensive testing scenarios for the ID verification feature with name matching and duplicate checking.

## Prerequisites

1. Backend running with Google Vision API configured
2. Member app running (web or mobile)
3. At least one test user already registered with ID number `TEST-ID-001`

## Test Scenarios

### Scenario 1: Perfect Name Match + New ID ✅

**Setup**:
- Personal Info (Step 1): 
  - First Name: `Abebe`
  - Father Name: `Bekele`
  - Last Name: `Tadesse`
- ID Document: Contains text "Abebe Bekele Tadesse" and ID number "123456789012"

**Expected Results**:
1. OCR extracts ID number: `123456789012`
2. OCR extracts name: `Abebe Bekele Tadesse`
3. Name matching shows: ✅ **Names match** (green)
4. Duplicate check shows: ✅ **ID number is available** (green)
5. Continue button: **ENABLED**
6. User can proceed to next step

**Test Steps**:
```
1. Complete personal info with name "Abebe Bekele Tadesse"
2. Confirm information
3. On identity screen, upload ID document
4. Wait for OCR to complete
5. Verify name matching card shows green "Names match"
6. Verify ID availability card shows green "ID number is available"
7. Click "Continue to Membership"
8. Verify navigation to membership step
```

---

### Scenario 2: Partial Name Match (Acceptable) ✅

**Setup**:
- Personal Info: 
  - First Name: `Abebe`
  - Father Name: `Bekele`
  - Last Name: `Tadesse`
- ID Document: Contains "Abebe B. Tadesse" (abbreviated middle name)

**Expected Results**:
1. OCR extracts name: `Abebe B. Tadesse`
2. Name matching: ✅ **Names match** (2 tokens overlap: "Abebe", "Tadesse")
3. Continue button: **ENABLED**

**Test Steps**:
```
1. Complete personal info with full name
2. Upload ID with abbreviated middle name
3. Verify name matching shows green "Names match"
4. Verify can proceed
```

---

### Scenario 3: Name Mismatch ❌

**Setup**:
- Personal Info: `Abebe Bekele Tadesse`
- ID Document: Contains "Alemayehu Girma Haile" (completely different name)

**Expected Results**:
1. OCR extracts name: `Alemayehu Girma Haile`
2. Name matching shows: ❌ **Names do not match** (red)
3. Warning message: "The name on your ID does not match the name you entered..."
4. Side-by-side comparison:
   - Name on ID: `Alemayehu Girma Haile`
   - Name you entered: `Abebe Bekele Tadesse`
5. Continue button: **DISABLED**
6. User cannot proceed

**Test Steps**:
```
1. Complete personal info with name "Abebe Bekele Tadesse"
2. Upload ID with different name "Alemayehu Girma Haile"
3. Verify name matching card shows red "Names do not match"
4. Verify warning message is displayed
5. Verify both names shown side-by-side
6. Verify "Continue" button is disabled
7. Try clicking continue (should not work)
```

**Resolution**:
- User must either:
  - Go back and correct personal info
  - Upload correct ID document
  - Contact support if legitimate issue

---

### Scenario 4: Duplicate ID Number ❌

**Setup**:
- Personal Info: `Abebe Bekele Tadesse`
- ID Document: Contains ID number `TEST-ID-001` (already registered)

**Expected Results**:
1. OCR extracts ID: `TEST-ID-001`
2. Name matching: ✅ Match (if name matches)
3. Duplicate check shows: ❌ **ID number already registered** (red)
4. Error message: "This ID number is already registered. If this is your ID, please contact support."
5. Continue button: **DISABLED**

**Test Steps**:
```
1. Complete personal info
2. Upload ID with number TEST-ID-001
3. Wait for OCR and duplicate check
4. Verify ID availability card shows red "ID number already registered"
5. Verify error message displayed
6. Verify "Continue" button is disabled
```

**Resolution**:
- User must contact support (cannot proceed with duplicate ID)

---

### Scenario 5: OCR No Name Detected (Skipped) ℹ️

**Setup**:
- Personal Info: `Abebe Bekele Tadesse`
- ID Document: Poor quality image, OCR cannot extract name (only ID number)

**Expected Results**:
1. OCR extracts ID number: `123456789012`
2. OCR cannot extract name: `null` or empty
3. Name matching shows: ℹ️ **Name verification skipped** (gray)
4. Message: "Name could not be extracted from ID"
5. Duplicate check: ✅ Available
6. Continue button: **ENABLED** (name check is optional)

**Test Steps**:
```
1. Complete personal info
2. Upload low-quality ID image
3. Verify name matching shows "Name verification skipped"
4. Verify can still proceed if ID is available
```

---

### Scenario 6: Network Error During Duplicate Check

**Setup**:
- Personal Info: `Abebe Bekele Tadesse`
- ID Document: Valid ID
- Network: Disconnect or backend down

**Expected Results**:
1. OCR completes successfully
2. Duplicate check starts: ⏳ **Checking ID availability...**
3. Network error occurs
4. Duplicate check: ✅ **ID number is available** (fail-open)
5. Continue button: **ENABLED** (doesn't block user)

**Test Steps**:
```
1. Complete personal info
2. Disconnect network or stop backend
3. Upload ID document
4. Wait for OCR to complete
5. Observe duplicate check shows "Checking..."
6. After timeout, verify it shows "ID number is available"
7. Verify can proceed (fail-open behavior)
```

---

### Scenario 7: OCR Low Confidence

**Setup**:
- Personal Info: `Abebe Bekele Tadesse`
- ID Document: Blurry image, OCR confidence < 60%

**Expected Results**:
1. OCR status: ⚠️ **Low confidence**
2. Extracted ID and name shown (if any)
3. "Retry validation" button available
4. Name matching: Based on extracted name (if any)
5. Continue button: **ENABLED** if ID extracted and available

**Test Steps**:
```
1. Complete personal info
2. Upload blurry ID image
3. Verify OCR shows "Low confidence" warning
4. Verify "Retry validation" button appears
5. Click retry and upload better image
6. Verify improved results
```

---

### Scenario 8: Multiple Name Formats (Ethiopian Names)

**Setup**:
- Personal Info: 
  - First Name: `አበበ` (Abebe in Amharic)
  - Father Name: `በቀለ` (Bekele)
  - Last Name: `ታደሰ` (Tadesse)
- ID Document: Contains "Abebe Bekele Tadesse" (Latin script)

**Expected Results**:
1. OCR extracts: `Abebe Bekele Tadesse`
2. Name matching: May show mismatch due to script difference
3. **Note**: Current implementation doesn't handle script conversion

**Test Steps**:
```
1. Enter name in Amharic script
2. Upload ID with Latin script
3. Observe name matching result
4. Document behavior for future enhancement
```

**Known Limitation**: Script conversion not implemented. Users should enter names in Latin script.

---

## Localization Testing

### Test All Three Languages

**English (en)**:
```
1. Set app language to English
2. Complete registration flow
3. Verify all ID verification messages in English:
   - "Name Verification"
   - "Names match"
   - "Names do not match"
   - "ID number is available"
   - "ID number already registered"
```

**Amharic (am)**:
```
1. Set app language to Amharic
2. Verify messages in Amharic:
   - "የስም ማረጋገጫ"
   - "ስሞች ይዛመዳሉ"
   - "ስሞች አይዛመዱም"
   - etc.
```

**Afaan Oromo (om)**:
```
1. Set app language to Afaan Oromo
2. Verify messages in Oromo:
   - "Mirkaneessa Maqaa"
   - "Maqaaleen wal simu"
   - "Maqaaleen hin wal siman"
   - etc.
```

---

## Performance Testing

### Test Response Times

1. **OCR Processing**:
   - Expected: 2-5 seconds
   - Measure: Time from image upload to results displayed

2. **Duplicate Check**:
   - Expected: < 1 second
   - Measure: Time from OCR complete to availability shown

3. **Overall Flow**:
   - Expected: < 10 seconds from upload to ready to proceed
   - Measure: End-to-end time

---

## Edge Cases

### Edge Case 1: Very Long Names
- Name: `Abebe Bekele Tadesse Alemayehu Girma Haile Mariam`
- Verify: UI handles long names without overflow

### Edge Case 2: Single Name
- Name: `Madonna`
- Verify: Name matching handles single-token names

### Edge Case 3: Special Characters
- Name: `O'Brien-Smith`
- Verify: Handles hyphens and apostrophes

### Edge Case 4: Numbers in Name
- Name: `Abebe 2nd`
- Verify: Handles numbers in names

### Edge Case 5: Multiple Spaces
- Name: `Abebe    Bekele` (extra spaces)
- Verify: Normalization removes extra spaces

---

## Regression Testing

After implementation, verify these existing features still work:

1. ✅ Personal info form validation
2. ✅ Confirmation screen displays correct data
3. ✅ Employment status dropdown
4. ✅ Identity type dropdown
5. ✅ Image picker (camera/gallery)
6. ✅ OCR retry functionality
7. ✅ Navigation back to previous steps
8. ✅ Language switching
9. ✅ Form state persistence

---

## Automated Test Cases

### Unit Tests (Dart)

```dart
// Test name matching logic
test('Name matching - perfect match', () {
  final result = compareNames(
    'Abebe Bekele Tadesse',
    'Abebe Bekele Tadesse',
  );
  expect(result, IdNameMatchStatus.matched);
});

test('Name matching - partial match', () {
  final result = compareNames(
    'Abebe Bekele Tadesse',
    'Abebe B. Tadesse',
  );
  expect(result, IdNameMatchStatus.matched);
});

test('Name matching - mismatch', () {
  final result = compareNames(
    'Abebe Bekele Tadesse',
    'Alemayehu Girma Haile',
  );
  expect(result, IdNameMatchStatus.mismatch);
});
```

### Integration Tests (Backend)

```typescript
// Test duplicate check endpoint
describe('GET /api/v1/cbhi/registration/check-id/:idNumber', () => {
  it('should return available for new ID', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/cbhi/registration/check-id/NEW-ID-123')
      .expect(200);
    
    expect(response.body.available).toBe(true);
  });

  it('should return taken for existing ID', async () => {
    // Create user with ID TEST-ID-001
    await createTestUser({ identityNumber: 'TEST-ID-001' });
    
    const response = await request(app.getHttpServer())
      .get('/api/v1/cbhi/registration/check-id/TEST-ID-001')
      .expect(200);
    
    expect(response.body.available).toBe(false);
  });
});
```

---

## Test Data

### Sample ID Numbers for Testing

```
NEW-ID-001  → Available (new)
NEW-ID-002  → Available (new)
TEST-ID-001 → Taken (pre-registered)
TEST-ID-002 → Taken (pre-registered)
```

### Sample Names for Testing

```
Perfect Match:
  Personal: Abebe Bekele Tadesse
  ID: Abebe Bekele Tadesse

Partial Match:
  Personal: Abebe Bekele Tadesse
  ID: Abebe B. Tadesse

Mismatch:
  Personal: Abebe Bekele Tadesse
  ID: Alemayehu Girma Haile
```

---

## Success Criteria

✅ All test scenarios pass
✅ Name matching works correctly (match/mismatch)
✅ Duplicate check prevents re-registration
✅ UI is responsive and user-friendly
✅ Error messages are clear and actionable
✅ All three languages display correctly
✅ Performance meets expectations (< 10s total)
✅ No regressions in existing features
✅ Fail-open behavior works (network errors don't block)

---

## Known Issues / Future Enhancements

1. **Script Conversion**: Add support for Amharic ↔ Latin script conversion
2. **Partial Match Status**: Implement 60-79% similarity threshold
3. **Levenshtein Distance**: Use more sophisticated string matching
4. **Manual Override**: Allow CBHI officers to override name mismatch
5. **Audit Log**: Log all name mismatch and duplicate ID attempts

---

## Test Execution Checklist

- [ ] Scenario 1: Perfect match + new ID
- [ ] Scenario 2: Partial match
- [ ] Scenario 3: Name mismatch
- [ ] Scenario 4: Duplicate ID
- [ ] Scenario 5: OCR no name
- [ ] Scenario 6: Network error
- [ ] Scenario 7: Low confidence
- [ ] Scenario 8: Multiple name formats
- [ ] Localization: English
- [ ] Localization: Amharic
- [ ] Localization: Afaan Oromo
- [ ] Performance testing
- [ ] Edge cases
- [ ] Regression testing

---

## Bug Report Template

```
**Title**: [Brief description]

**Scenario**: [Which test scenario]

**Steps to Reproduce**:
1. 
2. 
3. 

**Expected Result**:


**Actual Result**:


**Screenshots**:


**Environment**:
- Platform: [Web/Android/iOS]
- Flutter version:
- Backend version:

**Severity**: [Critical/High/Medium/Low]
```

---

## Contact

For questions or issues during testing, contact the development team.
