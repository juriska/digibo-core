const express = require('express');
const router = express.Router();
const { FFOService } = require('../services/ServiceFactory');

const ffoService = new FFOService();

router.post('/documents/getList', async (req, res) => {
  try {
    const { classId, user } = req.body;
    const result = await ffoService.getDocumentsList(classId, user);
    res.json(result);
  } catch (err) {
    console.error('Error in FFO documents list:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

router.get('/documents/getList', async (req, res) => {
    try {
        const result = await ffoService.getDocumentsList(1, 'NEW');
        res.json(result);
    } catch (err) {
        console.error('Error in FFO documents list:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/documents/all', async (req, res) => {
    try {
        const result = await ffoService.getAllDocuments();
        res.json(result);
    } catch (err) {
        console.error('Error getting all documents:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});


module.exports = router; 