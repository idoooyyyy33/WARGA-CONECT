const mongoose = require('mongoose');
const User = require('./models/User');

async function testStatsLogic() {
  try {
    const dbURI = process.env.MONGO_URI || process.env.MONGODB_URI;
    if (!dbURI) {
      console.log('No DB URI found');
      return;
    }

    await mongoose.connect(dbURI);
    console.log('Connected to DB');

    // Test the stats logic directly
    const userCount = await User.countDocuments({ role: 'warga' });
    const pengumumanCount = await require('./models/Pengumuman').countDocuments();
    const laporanCount = await require('./models/LaporanWarga').countDocuments();
    const iuranCount = await require('./models/Iuran').countDocuments();

    console.log('Stats:');
    console.log('Total Warga:', userCount);
    console.log('Total Pengumuman:', pengumumanCount);
    console.log('Total Laporan:', laporanCount);
    console.log('Total Iuran:', iuranCount);

    // Test activities logic
    const activities = [];

    // Pengumuman terbaru
    const pengumuman = await require('./models/Pengumuman')
      .find()
      .populate('penulis_id', 'nama_lengkap')
      .sort({ createdAt: -1 })
      .limit(3);

    pengumuman.forEach(item => {
      activities.push({
        tipe: 'pengumuman',
        judul: `Pengumuman baru: ${item.judul}`,
        deskripsi: item.isi.substring(0, 100) + '...',
        createdAt: item.createdAt
      });
    });

    // Laporan terbaru
    const laporan = await require('./models/LaporanWarga')
      .find()
      .populate('pelapor_id', 'nama_lengkap')
      .sort({ createdAt: -1 })
      .limit(3);

    laporan.forEach(item => {
      activities.push({
        tipe: 'laporan',
        judul: `Laporan baru: ${item.judul_laporan}`,
        deskripsi: item.isi_laporan.substring(0, 100) + '...',
        createdAt: item.createdAt
      });
    });

    console.log('Activities:', activities.length);
    activities.forEach(activity => {
      console.log(`- ${activity.tipe}: ${activity.judul}`);
    });

  } catch (error) {
    console.error('Error:', error.message);
  } finally {
    await mongoose.connection.close();
  }
}

require('dotenv').config();
testStatsLogic();
