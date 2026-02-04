const express = require('express');
const router = express.Router();
const playerController = require('../controllers/playerController');
const { verifyToken, verifyRole } = require('../middleware/authMiddleware');

router.get('/', playerController.getAllPlayers);
router.get('/:id', playerController.getPlayerById);
router.post('/', verifyToken, verifyRole(['ADMIN']), playerController.createPlayer);
router.put('/:id', verifyToken, verifyRole(['ADMIN']), playerController.updatePlayer);
router.delete('/:id', verifyToken, verifyRole(['ADMIN']), playerController.deletePlayer);

module.exports = router;
