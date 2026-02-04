const express = require('express');
const router = express.Router();
const auctionController = require('../controllers/auctionController');
const { verifyToken, verifyRole } = require('../middleware/authMiddleware');

router.get('/state', verifyToken, auctionController.getAuctionState);
router.get('/unsold', verifyToken, auctionController.getUnsoldPlayers);
router.post('/start', verifyToken, verifyRole(['AUCTIONEER', 'ADMIN']), auctionController.startRound);
router.post('/unsold', verifyToken, verifyRole(['AUCTIONEER', 'ADMIN']), auctionController.markUnsold);
router.post('/reset', verifyToken, verifyRole(['AUCTIONEER', 'ADMIN']), auctionController.resetState);

module.exports = router;
