# TODO List for App Development

## 1. Create Directories for New Screens
- [x] Create lib/screens/laporan/
- [x] Create lib/screens/iuran/
- [x] Create lib/screens/kegiatan/
- [x] Create lib/screens/umkm/
- [x] Create lib/screens/profil/

## 2. Implement Laporan Feature
- [x] Create lib/screens/laporan/laporan_page.dart: Display list of reports (GET /api/laporan), add button to create new report
- [x] Create lib/screens/laporan/laporan_create_page.dart: Form to create new report (POST /api/laporan)

## 3. Implement Iuran Feature
- [x] Create lib/screens/iuran/iuran_page.dart: Display list of iuran bills (GET /api/iuran)

## 4. Implement Kegiatan Feature
- [x] Create lib/screens/kegiatan/kegiatan_page.dart: Display list of activities (GET /api/kegiatan)

## 5. Implement UMKM Feature
- [x] Create lib/screens/umkm/umkm_page.dart: Display list of UMKM (GET /api/umkm)

## 6. Update Main Navigation
- [x] Update lib/screens/main/main_navigation.dart: Add tabs for Kegiatan and UMKM, update _pages list and BottomNavigationBar items

## 7. Implement Profil Feature
- [x] Create lib/screens/profil/profil_page.dart: Move ProfilPage from main_navigation.dart, add logout button that navigates to login_page.dart
- [x] Update main_navigation.dart to import and use the new profil_page.dart

## 8. Testing and Verification
- [x] Run the app and test navigation between tabs
- [x] Verify API calls work (assuming server is running at http://192.168.1.30:3000)
- [ ] Test logout functionality
