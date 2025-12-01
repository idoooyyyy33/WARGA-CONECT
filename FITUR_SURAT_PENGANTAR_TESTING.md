# Testing Guide - Fitur Surat Pengantar Warga

## ✅ Perbaikan yang Telah Dilakukan

### 1. Backend Routes (routes/surat_pengantar.routes.js)
- ✅ Fix GET `/api/surat-pengantar/admin` - pastikan didahulukan sebelum route `:id`
- ✅ Update middleware authentication - gunakan `authenticateUser` bukannya `requireAdmin`
- ✅ Check role admin di dalam handler, bukan di middleware
- ✅ Support PUT untuk update: `status_pengajuan`, `tanggapan_admin`, `file_surat`
- ✅ Support DELETE untuk hapus pengajuan

### 2. Flutter API Service (lib/services/api_service.dart)
- ✅ Update `createSuratPengantar()` - gunakan `_getHeaders()` yang sudah ada
- ✅ Fix multipart request headers
- ✅ `getSuratPengantar()` - ambil pengajuan user sendiri
- ✅ `getSuratPengantarAdmin()` - ambil semua pengajuan untuk admin
- ✅ `updateStatusSuratPengantar()` - update status & tanggapan
- ✅ `deleteSuratPengantar()` - hapus pengajuan

### 3. User Screen (lib/screen user/surat_pengantar_screen.dart)
- ✅ Form pengajuan dengan jenis surat dropdown
- ✅ Upload lampiran dokumen (multi-file)
- ✅ List pengajuan user dengan status
- ✅ Mapping field sudah benar

### 4. Admin Screen (lib/screen admin/surat_pengantar_admin.dart)
- ✅ List semua pengajuan surat
- ✅ Update status dengan tanggapan admin
- ✅ Delete pengajuan
- ✅ Status color coding (Diajukan=Orange, Diproses=Blue, Disetujui=Green, Ditolak=Red)

---

## 📋 Database Structure

Collection: `surat_pengantar`
```javascript
{
  "_id": ObjectId,
  "pengaju_id": ObjectId (ref: User) - Required,
  "jenis_surat": String - Required
    enum: ['KTP', 'KK', 'SKCK', 'Domisili', 'Kelahiran', 'Kematian', 'Nikah', 'Lainnya'],
  "keperluan": String - Required,
  "keterangan": String - Optional,
  "status_pengajuan": String - Required
    enum: ['Diajukan', 'Diproses', 'Disetujui', 'Ditolak'],
    default: 'Diajukan',
  "tanggapan_admin": String - Optional,
  "file_surat": String - Optional (URL file surat hasil),
  "lampiran_dokumen": {
    "ktp": String - Optional (URL),
    "kk": String - Optional (URL),
    "dokumen_lain": [
      {
        "nama_dokumen": String,
        "file_url": String
      }
    ]
  },
  "createdAt": Date,
  "updatedAt": Date
}
```

---

## 🧪 Testing Flow

### Test 1: User Membuat Pengajuan Surat

**Step:**
1. Login sebagai warga/user
2. Buka halaman "Surat Pengantar"
3. Klik tombol "+ Ajukan Surat"
4. Isi form:
   - Jenis Surat: Pilih "Domisili"
   - Keperluan: "Surat domisili untuk pembukaan rekening bank"
   - Keterangan: "Diperlukan untuk dokumen administrasi"
5. (Opsional) Upload lampiran: Ambil foto KTP atau dokumen lain
6. Klik "Ajukan Surat"

**Expected Result:**
- ✅ Muncul pesan "Surat pengantar berhasil diajukan"
- ✅ Pengajuan muncul di list user dengan status "Diajukan" (warna orange)
- ✅ Data tersimpan di database MongoDB collection `surat_pengantar`
- ✅ Field `pengaju_id` otomatis terisi dengan ID user
- ✅ Field `status_pengajuan` otomatis default "Diajukan"

---

### Test 2: Admin Melihat Semua Pengajuan

**Step:**
1. Login sebagai Admin
2. Buka halaman "Kelola Surat Pengantar"
3. Lihat list pengajuan dari semua warga

**Expected Result:**
- ✅ Pengajuan dari user muncul di list admin
- ✅ Info tampil: Jenis surat, Keperluan, Nama pengaju, Email, Tanggal
- ✅ Status badge muncul dengan warna yang sesuai
- ✅ Jika ada tanggapan admin, muncul di box berwarna abu-abu

---

### Test 3: Admin Update Status - Diajukan → Diproses

**Step:**
1. Di halaman admin, lihat pengajuan dengan status "Diajukan"
2. Klik tombol "Update Status"
3. Di modal, ubah status dari "Diajukan" → "Diproses"
4. Tambahkan tanggapan: "Pengajuan sedang kami verifikasi"
5. Klik "Update Status"

**Expected Result:**
- ✅ Muncul pesan "Status berhasil diperbarui"
- ✅ Status di card berubah jadi "Diproses" dengan warna biru
- ✅ Tanggapan admin muncul di dalam box
- ✅ User yang mengajukan bisa melihat status terupdate saat refresh

---

### Test 4: Admin Approve - Diproses → Disetujui

**Step:**
1. Di halaman admin, lihat pengajuan dengan status "Diproses"
2. Klik "Update Status"
3. Ubah status → "Disetujui"
4. Tanggapan: "Surat disetujui. File surat dapat diambil di kantor RT"
5. Klik "Update Status"

**Expected Result:**
- ✅ Status berubah menjadi "Disetujui" (warna hijau)
- ✅ Tanggapan tersimpan dan tampil di user

---

### Test 5: Admin Reject - Diajukan → Ditolak

**Step:**
1. Buat pengajuan baru (atau gunakan yang ada)
2. Di admin, klik "Update Status"
3. Ubah status → "Ditolak"
4. Tanggapan: "Dokumen tidak lengkap. Silakan upload KTP terlebih dahulu"
5. Klik "Update Status"

**Expected Result:**
- ✅ Status menjadi "Ditolak" (warna merah)
- ✅ Alasan penolakan tersimpan di tanggapan admin
- ✅ User bisa melihat alasan dan membuat pengajuan baru

---

### Test 6: User Melihat Status Terupdate

**Step:**
1. Login ulang sebagai user yang mengajukan
2. Buka halaman "Surat Pengantar"
3. Refresh atau pull-to-refresh

**Expected Result:**
- ✅ Status pengajuan menunjukkan status terbaru (Diproses/Disetujui/Ditolak)
- ✅ Warna status sesuai (Orange/Blue/Green/Red)
- ✅ Tanggapan admin muncul di card atau detail view
- ✅ Jika disetujui, bisa lihat file surat (jika ada)

---

### Test 7: Admin Delete Pengajuan

**Step:**
1. Di halaman admin, cari pengajuan
2. Klik tombol hapus (icon trash merah)
3. Konfirmasi dialog: "Apakah Anda yakin ingin menghapus pengajuan ini?"
4. Klik "Hapus"

**Expected Result:**
- ✅ Muncul pesan "Pengajuan berhasil dihapus"
- ✅ Pengajuan hilang dari list admin
- ✅ User tidak bisa melihat pengajuan yang sudah dihapus

---

### Test 8: Multiple Status Updates

**Step:**
1. Buat 3 pengajuan dengan jenis surat berbeda
2. Update status:
   - Pengajuan 1: Diajukan → Diproses → Disetujui
   - Pengajuan 2: Diajukan → Ditolak
   - Pengajuan 3: Diajukan
3. Verifikasi di user view dan admin view

**Expected Result:**
- ✅ Semua status terupdate dengan benar
- ✅ User bisa melihat history perubahan status
- ✅ Admin bisa melihat semua pengajuan dengan status berbeda

---

## 🔗 API Endpoints

### User Endpoints
- `POST /api/surat-pengantar` - Buat pengajuan surat baru
- `GET /api/surat-pengantar` - Lihat pengajuan user sendiri

### Admin Endpoints
- `GET /api/surat-pengantar/admin` - Lihat semua pengajuan
- `PUT /api/surat-pengantar/:id` - Update status & tanggapan
- `DELETE /api/surat-pengantar/:id` - Hapus pengajuan

---

## ⚠️ Important Notes

1. **Status Enum**: `['Diajukan', 'Diproses', 'Disetujui', 'Ditolak']`
   - Jangan gunakan status lain

2. **Jenis Surat Enum**: `['KTP', 'KK', 'SKCK', 'Domisili', 'Kelahiran', 'Kematian', 'Nikah', 'Lainnya']`

3. **User Authentication**: 
   - Token harus berisi user ID
   - Format: `Authorization: Bearer {user_id}`

4. **Admin Check**: 
   - Hanya user dengan role `ketua_rt` bisa access endpoint admin
   - Check di route handler, bukan middleware

5. **File Upload**: 
   - Multipart form data untuk dokumen lampiran
   - File tersimpan di folder `/uploads`

---

## 🐛 Troubleshooting

Jika ada error saat testing:

1. **Error 401 "User tidak terautentikasi"**
   - Pastikan sudah login
   - Check console untuk lihat token yang dikirim
   - Token harus format: `Bearer {user_id}`

2. **Error 403 "Akses ditolak"**
   - Hanya admin (role: ketua_rt) yang bisa access admin endpoint
   - Check apakah user sudah diadd sebagai admin di database

3. **Pengajuan tidak muncul di admin**
   - Cek apakah endpoint `/api/surat-pengantar/admin` bisa di-call
   - Verifikasi di Network tab (F12) apakah response berisi data

4. **File upload gagal**
   - Check middleware upload.js apakah sudah configured
   - Pastikan folder `/uploads` sudah ada di root project
   - Check file size limit di middleware

5. **Status tidak terupdate**
   - Refresh halaman atau gunakan pull-to-refresh
   - Check console untuk error message
   - Verifikasi status value sesuai enum di backend

---

## ✨ Selamat Testing!

Jika ada masalah, check:
- Console browser (F12 → Console tab)
- Server logs (terminal backend)
- Network tab untuk melihat request/response
- MongoDB Atlas untuk verifikasi data
