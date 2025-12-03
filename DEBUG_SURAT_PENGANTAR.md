# Debug Guide - Surat Pengantar Issues

## Issue 1: User tidak bisa submit pengajuan surat pengantar

### Debug Steps:

**1. Check Console Browser (F12 → Console Tab)**

Sebelum submit, buka console browser dan perhatikan:
- Debug logs dari Flutter akan muncul di console
- Cari logs yang dimulai dengan 📤 (send) dan 📥 (receive)

**2. Submit Form Surat Pengantar**

Isi form:
- Jenis Surat: Pilih salah satu
- Keperluan: Isi minimal 1 karakter
- Keterangan: Opsional
- Files: Opsional

Klik "Ajukan Surat"

**3. Check Console Output**

Perhatikan logs:
```
📤 Creating surat pengantar...
   Jenis: [nilai yang dipilih]
   Keperluan: [text yang diisi]
   Files: [jumlah file yang diupload]

📥 Response Status: 201 (atau 200)
   Body: {...response dari server...}
```

**Expected Console Output:**
```
✅ Status 201: Berarti berhasil di-create
✅ Status 200: Juga berarti berhasil
❌ Status 400: Ada error di body
❌ Status 401: User tidak terautentikasi (token tidak valid)
```

---

## Issue 2: Admin page Surat Pengantar Blank (Putih)

### Debug Steps:

**1. Open Browser Console (F12 → Console)**

Perhatikan logs ketika membuka halaman admin surat pengantar:
```
🔍 Fetching Surat Pengantar Admin...
   URL: http://10.61.28.85:3000/api/surat-pengantar/admin

📡 Response Status: [status code]
   Body: [response data]
   Data type: [List/Object]
   Data length: [jumlah data]
```

**2. Check Response Status**

- ✅ **200**: Data diterima dengan baik
- ❌ **401**: User tidak terautentikasi (token expired/tidak ada)
- ❌ **403**: User tidak punya akses (bukan admin)
- ❌ **500**: Error di server

**3. Check Network Tab (F12 → Network)**

Lakukan step berikut:
1. Buka F12 → Network tab
2. Refresh halaman admin surat pengantar
3. Cari request ke: `surat-pengantar/admin`
4. Lihat:
   - **Status**: Harus 200
   - **Response**: Harus array data surat atau []
   - **Headers**: Check `Authorization` header ada atau tidak

**4. Cek User Role**

Jika error 403, berarti user bukan admin.
- Check di database: apakah user punya role `ketua_rt`?
- Update user role di MongoDB:
  ```javascript
  db.users.updateOne(
    { _id: ObjectId("...") },
    { $set: { role: "ketua_rt" } }
  )
  ```

---

## Backend Debugging

Jika issue masih terjadi, check backend logs.

**1. Check Node.js Server Logs**

Di terminal backend, cari logs seperti:
```
GET /api/surat-pengantar/admin
User ID: [id]
User Role: [role]
Response: [jumlah surat]
```

**2. Test API Manual dengan Postman/cURL**

```bash
# Test GET /api/surat-pengantar/admin
curl -X GET http://10.61.28.85:3000/api/surat-pengantar/admin \
  -H "Authorization: Bearer {USER_ID}" \
  -H "Content-Type: application/json"
```

Expected response:
```json
[
  {
    "_id": "...",
    "jenis_surat": "KTP",
    "keperluan": "...",
    "status_pengajuan": "Diajukan",
    "pengaju_id": {
      "_id": "...",
      "nama_lengkap": "...",
      "email": "..."
    },
    "createdAt": "2025-11-30T..."
  }
]
```

---

## Common Issues & Solutions

### Issue: "User tidak terautentikasi" (401)

**Penyebab:**
- Token tidak dikirim dengan benar
- Token format salah
- Token expired

**Solusi:**
1. Login ulang
2. Pastikan format token: `Bearer {user_id}`
3. Check di DevTools → Application → LocalStorage
   - Cari key `token`
   - Value harus berisi user ID

### Issue: "Akses ditolak" (403)

**Penyebab:**
- User bukan admin (role ≠ ketua_rt)

**Solusi:**
1. Login dengan user yang punya role `ketua_rt`
2. Atau update role di MongoDB:
   ```bash
   db.users.updateOne(
     { email: "admin@example.com" },
     { $set: { role: "ketua_rt" } }
   )
   ```

### Issue: Data Surat tidak muncul meski API response 200

**Penyebab:**
- API return data kosong (array [])
- Flutter UI tidak render data kosong

**Solusi:**
1. Check apakah ada data di database:
   ```bash
   db.surat_pengantar.find({})
   ```
2. Jika kosong, buat pengajuan surat dari user terlebih dahulu

### Issue: Submit surat pengantar stuck/tidak response

**Penyebab:**
- File terlalu besar
- Network error
- Backend crash

**Solusi:**
1. Gunakan file yang lebih kecil (< 5MB)
2. Check backend logs untuk error
3. Restart backend server:
   ```bash
   npm start
   ```

---

## Step-by-Step Testing

Untuk memastikan semuanya bekerja, ikuti flow ini:

### 1. Login sebagai User
```
✅ Login dengan email user biasa
✅ Check console: ada token?
✅ Check Application → Storage → token ada?
```

### 2. Buat Pengajuan Surat
```
✅ Buka halaman Surat Pengantar
✅ Klik "+ Ajukan Surat"
✅ Isi form dengan:
   - Jenis: KTP
   - Keperluan: "Test"
✅ Klik "Ajukan Surat"
✅ Check console untuk logs
✅ Apakah ada success message?
```

### 3. Check Database
```
Terminal MongoDB:
db.surat_pengantar.find({})

Harus ada 1 dokumen dengan:
- jenis_surat: "KTP"
- keperluan: "Test"
- status_pengajuan: "Diajukan"
- pengaju_id: {user_id}
```

### 4. Login sebagai Admin
```
✅ Logout dari user
✅ Login dengan admin account (role: ketua_rt)
✅ Check token di console
```

### 5. Buka Halaman Surat Pengantar Admin
```
✅ Klik menu "Kelola Surat Pengantar"
✅ Check console untuk logs
✅ Apakah ada data yang muncul?
✅ Apakah list tidak blank?
```

---

## Terminal Backend - Check Logs

Buka terminal backend dan perhatikan logs:

```
🔍 GET /api/surat-pengantar/admin
✅ Auth: OK
✅ Role: ketua_rt
✅ Data: 1 surat found
```

Jika ada error:
```
❌ Auth: FAIL - User tidak terautentikasi
❌ Role: FAIL - User bukan admin
❌ Data: ERROR - Database error
```

---

## Quick Checklist

- [ ] Backend running (`npm start`)
- [ ] IP address benar (`10.61.28.85`)
- [ ] User sudah login
- [ ] Token ada di LocalStorage
- [ ] User yang admin punya role `ketua_rt`
- [ ] Database tidak kosong
- [ ] Browser console tanpa error
- [ ] Network status 200-201

Jika semua checked ✅, seharusnya fitur sudah berfungsi!
