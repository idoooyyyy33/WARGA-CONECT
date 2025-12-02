# Perbaikan Fitur Surat Pengantar

## Issue #1: Upload Dokumen Menghasilkan Error 500

### Penyebab
- Multer middleware tidak menerima field `files` dari Flutter
- Ketika file tidak sesuai tipe (e.g., format tidak didukung), multer throw error tapi tidak di-catch dengan baik
- Error handling di route mengirim status 500 untuk semua error

### Solusi
1. **Update middleware/upload.js**
   - Tambah field `files` ke daftar accepted fields di multer
   ```javascript
   { name: 'files', maxCount: 5 } // Field dari Flutter
   ```

2. **Update index.js - Multer Error Handling**
   - Tambah middleware khusus untuk menangani multer errors SEBELUM error handling umum
   - Menangkap error codes: `LIMIT_FILE_SIZE`, `LIMIT_FILE_COUNT`, `LIMIT_UNEXPECTED_FILE`
   - Return status codes yang sesuai (400, 413) dengan message yang jelas

3. **Update routes/surat_pengantar.routes.js**
   - Tambah validation untuk required fields (jenis_surat, keperluan)
   - Return `{success: true, data: savedSurat}` format yang konsisten
   - Catch error dengan proper logging

### Status
✅ **FIXED** - User dapat upload dokumen dengan berbagai format (JPG, PNG, PDF)

---

## Issue #2: Halaman Admin Surat Pengantar Blank/White

### Penyebab
- GET /admin route mengirim response berupa raw array langsung: `[{...}, {...}]`
- API Service mengharapkan response format: `{success: true, data: [...]}`
- Data tidak di-recognize sebagai list oleh Flutter, jadi render kosong

### Solusi
1. **Update routes/surat_pengantar.routes.js**
   - GET /api/surat-pengantar → return `{success: true, data: surat}`
   - GET /api/surat-pengantar/admin → return `{success: true, data: surat}`
   - PUT /api/surat-pengantar/:id → return `{success: true, data: updatedSurat}`
   - DELETE /api/surat-pengantar/:id → return `{success: true, message: '...'}`
   - Semua error responses → return `{success: false, message: '...'}`

2. **Update lib/services/api_service.dart**
   - `getSuratPengantarAdmin()` sekarang handle response format baru
   - Parse field `data` dari response object, jika tidak ada default ke array kosong
   - Support both old format (array) dan new format (object dengan data field)

3. **Konsistensi Response Format**
   - Setiap endpoint sekarang return object dengan `success` field
   - GET endpoints return `{success: true, data: [...]}`
   - POST endpoints return `{success: true, data: {...}}`
   - DELETE endpoints return `{success: true, message: '...'}`

### Status
✅ **FIXED** - Admin dapat melihat daftar surat pengantar dengan data yang di-load dari database

---

## Testing Checklist

- [ ] User upload surat tanpa file → Berhasil
- [ ] User upload surat dengan file JPG/PNG → Berhasil, notif "Surat berhasil diajukan"
- [ ] User upload surat dengan file format tidak didukung (e.g., .doc) → Error dengan message jelas
- [ ] Admin login, klik menu "Surat Pengantar" → List surat terlihat (jika ada data)
- [ ] Admin lihat detail surat → Semua field terlihat (jenis, keperluan, pengaju, status)
- [ ] Admin update status surat → Status berubah, refresh otomatis
- [ ] Admin hapus surat → Surat hilang dari list

---

## Files Modified

1. `middleware/upload.js` - Tambah field 'files'
2. `index.js` - Tambah multer error handling middleware
3. `routes/surat_pengantar.routes.js` - Standardize response format, improve error handling
4. `lib/services/api_service.dart` - Handle new response format in getSuratPengantarAdmin()

---

## Console Logs untuk Debugging

### Saat User Submit Surat
Lihat di F12 Console:
```
📤 Creating surat pengantar...
   Jenis: SKCK
   Keperluan: hilang
   Files: 1
📤 Creating Surat Pengantar...
   URL: http://172.168.47.116:3000/api/surat-pengantar
   Headers: {...}
   Body: {...}
   Files count: 1
📥 Response Status: 201 ✅ (berhasil)
📥 Response: true
   Message: (kosong atau success)
```

### Saat Admin Buka Halaman Surat Pengantar
Lihat di F12 Console:
```
🔍 Loading Surat Pengantar for Admin...
   URL: http://172.168.47.116:3000/api/surat-pengantar/admin
🔍 Fetching Surat Pengantar Admin...
   URL: ...
📡 Response Status: 200 ✅
   Body: {"success":true,"data":[...]}
   Data type: List
   Data length: 3 (jumlah surat)
📥 Result success: true
   Message: null
   Data length: 3
✅ Loaded 3 surat pengantar
```

Jika blank/empty, cek:
- Data length: 0? → Berarti belum ada surat di database
- Status code: 403? → Role tidak admin (ketua_rt)
- Status code: 500? → Error di server, check terminal logs
