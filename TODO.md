# TODO: Implementasi Fitur Admin dengan Verifikasi Kode

## Step 1: Update AuthProvider ✅
- [x] Tambah state untuk admin verification (isAdminVerification, verificationCode)
- [x] Tambah method `sendAdminVerificationCode()` - kirim kode ke email admin
- [x] Tambah method `verifyAdminCode(code)` - verifikasi kode dan redirect ke admin dashboard
- [x] Update login method untuk detect admin role dan trigger verification

## Step 2: Update ApiService ✅
- [x] Tambah method `sendAdminVerificationCode(email)` - POST ke endpoint /admin/send-verification
- [x] Tambah method `verifyAdminCode(email, code)` - POST ke endpoint /admin/verify-code
- [x] Handle response untuk success/error messages

## Step 3: Update LoginScreen ✅
- [x] Tambah state untuk admin verification dialog
- [x] Tambah method `_showAdminVerificationDialog()` setelah login admin berhasil
- [x] Dialog dengan input kode 6-digit dan resend button
- [x] Handle verification success → navigate to admin dashboard

## Step 4: Buat AdminDashboard Screen ✅
- [x] Screen baru dengan layout admin (sidebar navigation)
- [x] Basic dashboard dengan statistik overview
- [x] Menu untuk: Pengumuman, Laporan, Iuran, Kegiatan, UMKM, Warga

## Step 5: Update Routing di main.dart ✅
- [x] Tambah route '/admin-dashboard'
- [x] Tambah guard untuk admin routes (cek role admin)

## Step 6: Update Navigation Logic ✅
- [x] Di AuthProvider, setelah verify admin code → navigate to '/admin-dashboard'
- [x] Tambah logout admin functionality

## Testing & Followup
- [x] Test login flow admin dengan verifikasi kode
- [ ] Implementasi fitur admin lainnya (CRUD pengumuman, dll)
- [ ] Backend integration untuk endpoints admin
