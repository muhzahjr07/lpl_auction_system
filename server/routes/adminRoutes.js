const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, verifyRole } = require('../middleware/authMiddleware');

router.get('/stats', verifyToken, verifyRole(['ADMIN']), adminController.getDashboardStats);
router.post('/reset-db', verifyToken, verifyRole(['ADMIN']), adminController.resetDatabase);

module.exports = router;
