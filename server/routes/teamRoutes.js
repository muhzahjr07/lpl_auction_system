const express = require('express');
const router = express.Router();
const teamController = require('../controllers/teamController');
const { verifyToken, verifyRole } = require('../middleware/authMiddleware');

router.get('/', teamController.getAllTeams);
router.get('/:id', teamController.getTeamById);
router.post('/', verifyToken, verifyRole(['ADMIN']), teamController.createTeam);

module.exports = router;
