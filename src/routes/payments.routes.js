const express = require('express');
const router = express.Router();
const { PaymentService } = require('../services/ServiceFactory');

const paymentService = new PaymentService();

/**
 * POST /api/payments/find
 * Find payments with various filters
 *
 * Body: {
 *   custId?: string,
 *   custName?: string,
 *   userLogin?: string,
 *   officerId?: number,
 *   benName?: string,
 *   fromContract?: string,
 *   fromLocation?: string,
 *   pmtDetails?: string,
 *   amountFrom?: string,
 *   amountTill?: string,
 *   currencies?: string,
 *   pmtClass?: string,
 *   effectFrom?: date,
 *   effectTill?: date,
 *   paymentId?: string,
 *   channels?: string,
 *   statuses?: string,
 *   createdFrom?: date,
 *   createdTill?: date
 * }
 */
router.post('/find', async (req, res, next) => {
    try {
        const filters = req.body;
        const result = await paymentService.find(filters);
        res.json(result);
    } catch (err) {
        next(err);
    }
});

/**
 * GET /api/payments/:id
 * Get detailed payment information by ID
 */
router.get('/:id', async (req, res, next) => {
    try {
        const { id } = req.params;
        const details = await paymentService.getPaymentDetails(id);

        if (!details.userId) {
            return res.status(404).json({
                error: 'Payment not found',
                paymentId: id
            });
        }

        res.json(details);
    } catch (err) {
        next(err);
    }
});

/**
 * POST /api/payments/:id/template-group
 * Change template group for a payment
 *
 * Body: {
 *   groupId: string
 * }
 */
router.post('/:id/template-group', async (req, res, next) => {
    try {
        const { id } = req.params;
        const { groupId } = req.body;

        if (!groupId) {
            return res.status(400).json({
                error: 'Missing required field: groupId'
            });
        }

        const result = await paymentService.changeTemplateGroup(id, groupId);
        res.json({
            ...result,
            message: 'Template group changed successfully'
        });
    } catch (err) {
        next(err);
    }
});

module.exports = router;