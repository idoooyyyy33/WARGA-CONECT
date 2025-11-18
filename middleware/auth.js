const User = require('../models/User');

// Middleware untuk autentikasi user
const authenticateUser = async (req, res, next) => {
    try {
        // Ambil token dari Authorization header
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ message: 'Token tidak valid' });
        }

        // Token adalah user ID (bukan JWT, tapi ID langsung)
        const userId = authHeader.substring(7); // Ambil setelah 'Bearer '

        // Cari user berdasarkan ID
        const user = await User.findById(userId);
        if (!user) {
            return res.status(401).json({ message: 'User tidak ditemukan' });
        }

        // Tambahkan user ke request object
        req.user = {
            id: user._id,
            email: user.email,
            role: user.role,
            nama_lengkap: user.nama_lengkap
        };

        next();
    } catch (err) {
        res.status(500).json({ message: 'Terjadi kesalahan autentikasi' });
    }
};

// Middleware untuk cek role admin
const requireAdmin = (req, res, next) => {
    if (!req.user) {
        return res.status(401).json({ message: 'User tidak terautentikasi' });
    }

    if (req.user.role !== 'ketua_rt') {
        return res.status(403).json({ message: 'Akses ditolak. Hanya admin yang dapat mengakses.' });
    }

    next();
};

module.exports = {
    authenticateUser,
    requireAdmin
};
