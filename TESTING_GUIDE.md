# 🧪 Testing & Troubleshooting Guide - Iuran Admin Dashboard

## ✅ Pre-Deployment Checklist

### 1. Build & Compile
```bash
# Build APK/Web
flutter build apk  # untuk Android
flutter build web  # untuk Web
flutter build ios  # untuk iOS

# Or hot reload untuk development
flutter run
```

**Expected**: ✅ Build succeeds, no errors

---

### 2. Runtime Testing

#### Test 1: Load Data
- [ ] Open Iuran page
- [ ] Check console logs untuk API response
- [ ] Verify data muncul (name, nominal, status)
- [ ] Expected: List of 8+ iuran items (dari session sebelumnya)

**Debug Logs to Look For**:
```
📄 Processing: [Map with iuran data]
📡 Response Status: 200
🔄 Parsed nominal: Rp [amount]
✅ Total transformed: [count]
```

#### Test 2: Edit Iuran
- [ ] Klik tombol edit (✏️) pada card iuran
- [ ] Dialog edit muncul dengan form
- [ ] Form sudah populated dengan data existing
- [ ] **Fields present**: Judul, Deskripsi, Nominal, Status
- [ ] Edit judul → "Iuran Kas Bulanan"
- [ ] Edit deskripsi → "Untuk operasional RT bulan ini"
- [ ] Edit nominal → "500000"
- [ ] Klik "Simpan"
- [ ] Expected: Snackbar ✓, data di-refresh

**Debug**: Check browser console untuk API response:
```json
{
  "success": true,
  "message": "Iuran updated successfully"
}
```

#### Test 3: Verify Payment
- [ ] Filter ke tab "Menunggu Verifikasi"
- [ ] Klik card iuran
- [ ] Dialog verifikasi muncul
- [ ] **Shows**: Judul, nominal, bukti pembayaran (image)
- [ ] Change status → "Lunas"
- [ ] Klik "Verifikasi"
- [ ] Expected: Status updated, card moves to "Lunas" tab

#### Test 4: View Iuran Info
- [ ] Klik menu "..." pada card
- [ ] Pilih "Lihat Info"
- [ ] Dialog info muncul dengan:
  - Warga name
  - Nominal
  - Status
  - Keterangan (description)
- [ ] Klik "Tutup"
- [ ] Expected: Dialog closes

#### Test 5: Kelola Iuran Menu
- [ ] Klik tombol "Kelola Iuran" (top bar)
- [ ] Dialog menu muncul dengan 3 options:
  1. Lihat Informasi
  2. Edit Iuran
  3. Buat Mass Iuran
- [ ] Klik "Lihat Informasi"
- [ ] Dialog jenis-jenis iuran muncul:
  - Iuran Kas (💼 green)
  - Iuran Bencana (⚠️ red)
  - Iuran Kegiatan (🎉 blue)
  - Iuran Kesehatan (🏥 yellow)
- [ ] Each memiliki icon, warna, dan deskripsi
- [ ] Expected: User memahami 4 jenis iuran

#### Test 6: Filter by Nominal Range
- [ ] Open filter section (jika ada UI untuk advanced filter)
- [ ] Input Min Nominal: "50000"
- [ ] Input Max Nominal: "200000"
- [ ] Expected: List hanya menampilkan iuran dengan nominal 50K-200K

#### Test 7: Bulk Actions
- [ ] Select 3 cards via checkbox (☑)
- [ ] Bulk action bar muncul di bawah tab
- [ ] Shows "3 dipilih"
- [ ] Klik "Mark Lunas"
- [ ] Progress indicator tampil
- [ ] Expected: After processing, 3 items berubah status → "Lunas"
- [ ] Items pindah ke tab "Lunas"

#### Test 8: Export CSV
- [ ] Select 5 items
- [ ] Klik "Export"
- [ ] Expected:
  - CSV string di clipboard
  - Snackbar "✓ CSV copied to clipboard"
  - Dapat paste ke Excel/Sheets

#### Test 9: Search & Filter
- [ ] Search dengan nama warga: "pandi"
- [ ] Expected: Hanya card dengan nama matching ditampilkan
- [ ] Filter by tab "Lunas"
- [ ] Expected: Hanya card dengan status "Lunas"
- [ ] Combine: Search "pandi" + tab "Lunas"
- [ ] Expected: Intersection dari dua filter

#### Test 10: Delete Iuran
- [ ] Klik "..." menu
- [ ] Pilih "Hapus"
- [ ] Confirmation dialog muncul
- [ ] Klik "Hapus"
- [ ] Expected: Item dihapus, list di-refresh

---

## 🐛 Troubleshooting Guide

### Problem 1: Edit Dialog Tidak Muncul
**Symptoms**: Klik edit button → nothing happens

**Solutions**:
1. Check console untuk errors
2. Verify `_judulController`, `_deskripsiController` initialized
3. Verify `_showEditIuranDialog()` method exists
4. Check if `item` data is properly passed
5. Restart flutter

**Debug**:
```dart
// Add print in build method
print('Build called with ${_filteredIuran.length} items');
```

### Problem 2: Judul/Deskripsi Tidak Tampil di Card
**Symptoms**: Card hanya tampil nominal & status, tidak ada judul

**Possible Causes**:
1. API tidak return `judul` field
2. `judul` value is null atau empty
3. Card layout not rendering description

**Solutions**:
1. Check API response:
   ```
   Inspect Network Tab → /admin/iuran → Preview → Check "judul" field
   ```
2. Add debug print:
   ```dart
   print('Iuran: ${item['judul']} - ${item['deskripsi']}');
   ```
3. Force refresh data:
   ```dart
   _loadData(); // Call in initState or button
   ```

### Problem 3: Save Edit Tidak Work
**Symptoms**: Klik "Simpan" → nothing happens atau error

**Possible Causes**:
1. API endpoint not accessible
2. Invalid data format
3. Missing fields in request

**Solutions**:
1. Check API endpoint: `PUT /admin/iuran/:id`
2. Verify request body format:
   ```json
   {
     "jumlah": 500000,
     "judul": "Iuran Kas Bulanan",
     "deskripsi": "Untuk operasional RT",
     "status": "Lunas"
   }
   ```
3. Check network tab untuk request/response
4. Verify API returns `{"success": true}`

**Debug**:
```dart
// Add logging sebelum API call
print('📝 Updating with: $updateData');
final res = await _apiService.updateIuranInfo(id, updateData);
print('🔄 Response: $res');
```

### Problem 4: Bukti Pembayaran Tidak Muncul di Verifikasi Dialog
**Symptoms**: Dialog verifikasi kosong atau error image

**Possible Causes**:
1. `bukti_pembayaran` field kosong
2. URL file tidak valid
3. File sudah didelete dari server

**Solutions**:
1. Check if field populated:
   ```dart
   print('Bukti: ${item['bukti_pembayaran']}');
   ```
2. Verify file exists di server:
   ```
   http://10.61.28.85:3000/uploads/[filename]
   ```
3. Check network tab untuk error image load

**Debug**:
```dart
if (bukti.isEmpty) {
  print('⚠️ No bukti_pembayaran');
} else {
  print('✅ Bukti: http://10.61.28.85:3000/uploads/$bukti');
}
```

### Problem 5: Bulk Mark Lunas Tidak Jalan
**Symptoms**: Progress indicator freeze atau action tidak berfungsi

**Possible Causes**:
1. API endpoint error
2. Invalid selected IDs
3. Network timeout

**Solutions**:
1. Check selected items:
   ```dart
   print('Selected IDs: $_selectedIds');
   ```
2. Verify API bulk update endpoint exists
3. Add timeout handling
4. Check network connection

**Debug**:
```dart
for (final id in _selectedIds) {
  print('🔄 Updating: $id');
  // Call API
}
```

### Problem 6: Filter Nominal Range Tidak Work
**Symptoms**: Filter button ada tapi tidak filter hasil

**Possible Causes**:
1. Filter UI tidak implemented
2. `_filterMinNominal` tidak tersave
3. `_applyFilters()` tidak call dengan filter values

**Solutions**:
1. Check if advanced filter UI exists
2. Add print di `_applyFilters()`:
   ```dart
   print('Filtering: min=$minNom, max=$maxNom');
   ```
3. Force rebuild:
   ```dart
   setState(() {});
   ```

---

## 🔍 Debug Logging

### Enable Verbose Logging
Add to `_loadData()`:
```dart
void _loadData() async {
  print('📋 Loading iuran data...');
  
  final iuranList = await _apiService.getIuran(
    bulan: _selectedMonth,
    tahun: _selectedYear,
  );
  
  print('✅ Loaded ${iuranList.length} items');
  for (var item in iuranList) {
    print('  - ${item['nama_warga']}: Rp ${item['nominal']}');
  }
  
  setState(() => _allIuran = iuranList);
}
```

### Check Network Requests
1. Open DevTools (F12)
2. Go to Network tab
3. Filter by "iuran" or API endpoint
4. Check:
   - Status: 200 (success) ✅
   - Response: Valid JSON
   - Time: < 2 seconds (good performance)

### Check Console Logs
1. Look untuk emojis: 📄 📡 🔄 ✅ ❌
2. Check untuk error messages
3. Verify data transformation logs

---

## 📊 Performance Checks

### Before Deployment

#### 1. Load Time
- [ ] Initial load < 2 seconds
- [ ] Filter < 500ms
- [ ] Dialog appear < 1 second

#### 2. Memory Usage
- [ ] App memory stable (tidak increasing setelah scroll)
- [ ] Dialog close properly (dispose controllers)
- [ ] No memory leak

#### 3. UI Responsiveness
- [ ] Smooth scrolling pada list
- [ ] No jank atau stutter
- [ ] Animations smooth (60 fps)

#### 4. Error Handling
- [ ] Show error snackbar jika API fail
- [ ] Graceful fallback values
- [ ] User-friendly error messages

---

## 📱 Device Testing

### Test pada berbagai ukuran screen:

#### Mobile (375x667)
- [ ] Cards readable
- [ ] Buttons accessible
- [ ] No overflow text
- [ ] Dialog fit screen

#### Tablet (768x1024)
- [ ] Layout scaling
- [ ] Cards tidak terlalu lebar
- [ ] All content visible

#### Web (1920x1080)
- [ ] Responsive layout
- [ ] Optimal use of space
- [ ] No horizontal scroll

---

## 🎯 Test Cases Summary

| Test Case | Steps | Expected | Status |
|-----------|-------|----------|--------|
| Load Data | Open page | 8+ items visible | ⏳ |
| Edit Iuran | Click edit → Change judul → Save | Data updated | ⏳ |
| Verify Payment | Open verifikasi → Change status → Verify | Status Lunas | ⏳ |
| View Info | Click info button | Detail dialog | ⏳ |
| Kelola Menu | Click menu → Lihat Info | Types info | ⏳ |
| Filter Range | Set min/max nominal | Filtered list | ⏳ |
| Bulk Select | Select 3 items | 3 dipilih, actions enabled | ⏳ |
| Mark Lunas | Bulk select → Mark Lunas | Status updated | ⏳ |
| Export CSV | Select → Export | CSV in clipboard | ⏳ |
| Search | Type nama | Filtered by nama | ⏳ |
| Tab Filter | Click "Lunas" tab | Show only lunas | ⏳ |
| Delete | Click delete → Confirm | Item removed | ⏳ |

---

## 💡 Tips & Tricks

### For Development
1. Use `flutter run -v` untuk verbose logging
2. Add `debugPrint()` untuk debugging
3. Use hot reload untuk cepat test UI changes
4. Check widget tree dengan DevTools

### For Testing
1. Create test data dengan berbagai status
2. Test dengan API yang return error (timeout, 500)
3. Test dengan empty list
4. Test dengan very large nominal (9,999,999,999)

### For Performance
1. Use `const` untuk widget yang tidak berubah
2. Dispose controllers di cleanup
3. Avoid rebuilding entire list (use key pada ListTile)
4. Cache data jika memungkinkan

---

## 📞 Common Issues & Quick Fixes

| Issue | Fix |
|-------|-----|
| Judul tidak muncul | Check API response, verify field name |
| Dialog tidak buka | Verify method exists, check console error |
| Bulk action hang | Check network, verify API endpoint |
| Filter tidak work | Check _applyFilters(), verify state update |
| Image tidak load | Verify file path, check network |

---

**Last Updated**: Development Session
**Status**: Ready for QA Testing
**Next**: Deploy to staging environment
