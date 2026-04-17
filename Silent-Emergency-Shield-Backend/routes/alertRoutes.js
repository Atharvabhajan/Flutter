const express = require('express');
const router = express.Router();
const protect = require('../middlewares/authMiddleware');
const emergencyController = require('../controllers/emergencyController');

router.post('/trigger', protect, emergencyController.triggerEmergency);

module.exports = router;
