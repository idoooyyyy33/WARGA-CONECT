# TODO: Refactoring Struktur Proyek Flutter (Bahasa Indonesia)

## Status: Sedang Berjalan

### Fase 1: Persiapan Struktur Folder
- [x] Buat folder-folder baru:
  - `lib/konfigurasi/` - untuk konstanta
  - `lib/inti/model/` - untuk model data
  - `lib/inti/utilitas/` - untuk helper functions
  - `lib/fitur/` - untuk fitur-fitur aplikasi
  - `lib/bersama/widget/` - untuk widget reusable
  - `lib/bersama/tema/` - untuk tema aplikasi

### Fase 2: Buat Konstanta dan Utilitas
- [ ] Buat `lib/konfigurasi/konstanta.dart` - URL API dan konstanta aplikasi
- [ ] Buat `lib/inti/utilitas/api_helper.dart` - helper untuk API calls
- [ ] Buat `lib/inti/utilitas/format_tanggal.dart` - helper untuk format tanggal

### Fase 3: Buat Model Classes
- [ ] `lib/inti/model/model_pengguna.dart`
- [ ] `lib/inti/model/model_pengumuman.dart`
- [ ] `lib/inti/model/model_laporan.dart`
- [ ] `lib/inti/model/model_pembayaran.dart`
- [ ] `lib/inti/model/model_kegiatan.dart`
- [ ] `lib/inti/model/model_umkm.dart`

### Fase 4: Pecah Layanan API
- [ ] `lib/fitur/otentikasi/data/layanan_otentikasi.dart` - login, register, logout
- [ ] `lib/fitur/pengguna/data/layanan_pengguna.dart` - profile, user data
- [ ] `lib/fitur/pengumuman/data/layanan_pengumuman.dart` - pengumuman
- [ ] `lib/fitur/laporan/data/layanan_laporan.dart` - laporan
- [ ] `lib/fitur/pembayaran/data/layanan_pembayaran.dart` - iuran
- [ ] `lib/fitur/kegiatan/data/layanan_kegiatan.dart` - kegiatan
- [ ] `lib/fitur/umkm/data/layanan_umkm.dart` - UMKM
- [ ] `lib/fitur/admin/data/layanan_admin.dart` - operasi admin

### Fase 5: Pindahkan File Layar
- [ ] Pindahkan layar pengguna ke `lib/fitur/*/presentasi/`
- [ ] Pindahkan layar admin ke `lib/fitur/admin/presentasi/`
- [ ] Rename folder dari 'screen admin' ke 'layar/admin' dan 'screen user' ke 'layar/pengguna'

### Fase 6: Update Import dan Dependencies
- [ ] Update semua import statements di seluruh proyek
- [ ] Update providers untuk menggunakan layanan baru
- [ ] Test aplikasi untuk memastikan tidak ada error

### Fase 7: Cleanup
- [ ] Hapus file `api_service.dart` lama
- [ ] Hapus folder kosong
- [ ] Format code dengan `flutter format`
