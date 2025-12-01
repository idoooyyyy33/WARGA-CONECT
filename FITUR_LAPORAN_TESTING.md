# Testing Guide - Fitur Laporan Warga

## ✅ Perbaikan yang Telah Dilakukan

### 1. Backend Routes (routes/laporan.routes.js)
- ✅ Update route PUT `/api/laporan/:id` untuk support:
  - `status_laporan` (Diterima, Diproses, Selesai, Ditolak)
  - `tanggapan` (respons dari admin)
  - `kategori_laporan` (kategori laporan)
  - `lokasi` (lokasi kejadian)

### 2. Flutter API Service (lib/services/api_service.dart)
- ✅ Update `getLaporan()` - gunakan endpoint `/api/laporan` (bukan `/api/admin/laporan`)
- ✅ Update `updateStatusLaporan()` - kirim ke `/api/laporan/:id`
- ✅ Update `deleteLaporan()` - gunakan `/api/laporan/:id`
- ✅ Mapping field sudah benar:
  - `judul_laporan` → `judul`
  - `isi_laporan` → `deskripsi`
  - `status_laporan` → `status`
  - `kategori_laporan` → `kategori`

### 3. Admin UI (lib/screen admin/Laporan.dart)
- ✅ Update status options: `Pending` → `Diterima`, `Proses` → `Diproses`
- ✅ Update filter options untuk match backend
- ✅ Update status color mapping
- ✅ Update status chips di dialog update

---

## 🧪 Testing Flow

### Test 1: User/Warga Membuat Laporan

**Step:**
1. Login sebagai warga/user
2. Buka halaman "Laporan Warga"
3. Klik tombol "+ Buat Laporan"
4. Isi form:
   - Kategori: Pilih salah satu (Kebersihan, Keamanan, Infrastruktur, UMKM, Lainnya)
   - Judul Laporan: "Jalan berlubang di depan rumah"
   - Deskripsi: "Ada lubang besar di jalan RT 05 yang berbahaya"
5. Klik tombol "Kirim Laporan"

**Expected Result:**
- ✅ Muncul pesan "Laporan berhasil dibuat"
- ✅ Laporan muncul di list user dengan status "Diterima"
- ✅ Data tersimpan di database MongoDB collection `laporan_warga`

---

### Test 2: Admin Melihat Laporan yang Dikirim

**Step:**
1. Login sebagai Admin
2. Buka halaman "Laporan Warga"
3. Lihat status cards di bagian atas (Diterima, Diproses, Selesai)

**Expected Result:**
- ✅ Laporan dari user muncul di list
- ✅ Status cards menunjukkan count "Diterima: 1"
- ✅ Filter dan search berfungsi dengan baik

---

### Test 3: Admin Update Status Laporan

**Step:**
1. Di halaman Admin Laporan, klik 3 dots di laporan yang dibuat user
2. Pilih "Update Status"
3. Ubah status dari "Diterima" → "Diproses"
4. Tambahkan tanggapan: "Laporan sedang kami proses, mohon ditunggu"
5. Klik tombol "Update"

**Expected Result:**
- ✅ Muncul pesan "Status laporan berhasil diupdate"
- ✅ Status di card berubah menjadi "Diproses"
- ✅ Status cards update: Diterima berkurang, Diproses bertambah

---

### Test 4: Laporan Update Muncul di User

**Step:**
1. Login kembali sebagai user
2. Buka halaman "Laporan Warga"
3. Refresh atau buka ulang halaman (pull-to-refresh)

**Expected Result:**
- ✅ Status laporan berubah menjadi "Diproses" (icon dan warna berubah)
- ✅ Tanggapan admin muncul di detail laporan (jika implementasi detail view)

---

### Test 5: Admin Tandai Selesai

**Step:**
1. Di Admin, buka laporan yang statusnya "Diproses"
2. Klik update status
3. Ubah status menjadi "Selesai"
4. Tambahkan tanggapan: "Jalan sudah diperbaiki, terima kasih"
5. Klik "Update"

**Expected Result:**
- ✅ Status menjadi "Selesai" dengan icon checkmark dan warna hijau
- ✅ Laporan tidak lagi muncul di filter "Diproses"

---

### Test 6: Testing Filter & Search

**Step:**
1. Di halaman Admin, buat 2-3 laporan dengan kategori berbeda
2. Test filter:
   - "Semua" - tampil 3 laporan
   - "Diterima" - tampil hanya yang Diterima
   - "Diproses" - tampil hanya yang Diproses
   - "Selesai" - tampil hanya yang Selesai
3. Test search dengan judul atau nama pelapor

**Expected Result:**
- ✅ Filter berfungsi dengan benar
- ✅ Search case-insensitive dan mencocokkan semua field

---

### Test 7: Delete Laporan

**Step:**
1. Di Admin, klik 3 dots pada laporan
2. Pilih "Hapus"
3. Konfirmasi dialog "Hapus Laporan?"

**Expected Result:**
- ✅ Laporan dihapus dari database
- ✅ List terupdate, count berkurang
- ✅ User tidak bisa melihat laporan yang sudah dihapus

---

## 📊 Database Structure

Collection: `laporan_warga`
```javascript
{
  "_id": ObjectId,
  "pelapor_id": ObjectId (ref: User),
  "judul_laporan": String,
  "isi_laporan": String,
  "foto_laporan": String (optional),
  "kategori_laporan": String (enum: ['Kebersihan', 'Keamanan', 'Infrastruktur', 'UMKM', 'Lainnya']),
  "lokasi": String (optional),
  "tanggapan": String (optional),
  "status_laporan": String (enum: ['Diterima', 'Diproses', 'Selesai', 'Ditolak']),
  "createdAt": Date,
  "updatedAt": Date (auto)
}
```

---

## 🔗 API Endpoints

### User/Warga Endpoints
- `POST /api/laporan` - Buat laporan baru
- `GET /api/laporan` - Lihat semua laporan
- `GET /api/laporan/:id` - Lihat detail laporan

### Admin Endpoints
- `GET /api/laporan` - Lihat semua laporan (admin)
- `PUT /api/laporan/:id` - Update status & tanggapan
- `DELETE /api/laporan/:id` - Hapus laporan

---

## ⚠️ Notes

1. **Status Enum Backend**: `['Diterima', 'Diproses', 'Selesai', 'Ditolak']`
   - Jangan gunakan "Pending" atau "Proses"

2. **Populate Data**: API otomatis populate field `pelapor_id` dengan nama lengkap

3. **Timestamp**: Field `createdAt` otomatis tersimpan saat laporan dibuat

4. **Tanggapan Admin**: Hanya bisa diupdate oleh admin, user hanya bisa lihat

---

## 🐛 Troubleshooting

Jika ada error saat testing:

1. **Error "Failed to fetch"**
   - Pastikan backend sudah running: `npm start`
   - Cek IP address di api_service.dart: `192.168.56.1`

2. **Status tidak terupdate**
   - Reload halaman atau gunakan pull-to-refresh
   - Check console browser (F12) untuk error message

3. **Laporan tidak muncul di admin**
   - Cek apakah user sudah login dan punya token
   - Check MongoDB apakah data tersimpan

---

## ✨ Selamat Testing!

Jika ada masalah, check console/debug untuk melihat error details.
