const express = require('express');
const router = express.Router();
const PaymentService = require('../services/PaymentService');

const paymentService = new PaymentService();

router.post('/documents/getList', async (req, res) => {
    try {
        const { classId, user } = req.body;
        const result = await paymentService.getDocumentsList(classId, user);
        res.json(result);
    } catch (err) {
        console.error('Error in FFO documents list:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

router.get('/documents/getList', async (req, res) => {
    const result = await paymentService.getDocumentsList(1, '');
    res.json(result);
});

router.get('/documents/getDraftCount', async (req, res) => {
    // const result = await ffoService.getDocumentsList(1, '');
    res.json({ count: 2 });
});

module.exports = router;