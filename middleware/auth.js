const User = require('../models/User');

// Middleware untuk autentikasi user
const authenticateUser = async (req, res, next) => {
    try {
        // Ambil token dari Authorization header
        const authHeader = req.headers.authorization;
        console.log('🔐 Auth Header:', authHeader);
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ success: false, message: 'Token tidak valid' });
        }

        // Token adalah user ID (bukan JWT, tapi ID langsung)
        const userId = authHeader.substring(7); // Ambil setelah 'Bearer '
        console.log('🔐 User ID from token:', userId);

        // Cari user berdasarkan ID
        const user = await User.findById(userId);
        if (!user) {
            console.log('❌ User not found:', userId);
            return res.status(401).json({ success: false, message: 'User tidak ditemukan' });
        }

        console.log('✅ User authenticated:', userId, 'Role:', user.role);

        // Tambahkan user ke request object
        req.user = {
            id: user._id,
            email: user.email,
            role: user.role,
            nama_lengkap: user.nama_lengkap
        };

        next();
    } catch (err) {
        console.error('❌ Auth error:', err);
        res.status(500).json({ success: false, message: 'Terjadi kesalahan autentikasi' });
    }
};

// Middleware untuk cek role admin
const requireAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ success: false, message: 'User tidak terautentikasi' });
    }

    if (req.user.role !== 'ketua_rt') {
        return res.status(403).json({ success: false, message: 'Akses ditolak. Hanya admin yang dapat mengakses.' });
    }

    next();
};

module.exports = {
    authenticateUser,
    requireAdmin
};
