const express = require('express');
const router = express.Router();
const { FFOService } = require('../services/ServiceFactory');

const ffoService = new FFOService();

/**
 * GET /api/ffo/documents
 * Get user's FFO documents using BOFFO.find_my()
 * Returns array with 19 fields matching Oracle structure
 */
router.get('/documents', async (req, res, next) => {
    try {
        const result = await ffoService.findMy();
        res.json(result);
    } catch (err) {
        next(err);
    }
});

/**
 * GET /api/ffo/documents/:id
 * Get specific FFO document by ID
 */
router.get('/documents/:id', async (req, res, next) => {
    try {
        const { id } = req.params;
        const result = await ffoService.getById(id);

        if (!result) {
            return res.status(404).json({
                error: 'FFO document not found',
                documentId: id
            });
        }

        res.json(result);
    } catch (err) {
        next(err);
    }
});

/**
 * GET /api/ffo/categories
 * Get FFO categories using BOFFO.get_categories()
 */
router.get('/categories', async (req, res, next) => {
    try {
        const result = await ffoService.getCategories();
        res.json(result);
    } catch (err) {
        next(err);
    }
});

/**
 * POST /api/ffo/documents/:id/categorize
 * Categorize FFO document using BOFFO.categorize()
 *
 * Body: {
 *   categoryId: number,
 *   subCategoryId: number,
 *   assignee: number
 * }
 */
router.post('/documents/:id/categorize', async (req, res, next) => {
    try {
        const { id } = req.params;
        const { categoryId, subCategoryId, assignee } = req.body;

        if (!categoryId || !subCategoryId || !assignee) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['categoryId', 'subCategoryId', 'assignee']
            });
        }

        const result = await ffoService.categorize(
            parseInt(id),
            categoryId,
            subCategoryId,
            assignee
        );

        res.json({
            ...result,
            message: result.success ? 'Document categorized successfully' : 'Failed to categorize document'
        });
    } catch (err) {
        next(err);
    }
});

/**
 * POST /api/ffo/documents/:id/processing
 * Set processing status using BOFFO.set_processing()
 *
 * Body: {
 *   reason: string,
 *   newStatus: number,
 *   messageId: number
 * }
 */
router.post('/documents/:id/processing', async (req, res, next) => {
    try {
        const { id } = req.params;
        const { reason, newStatus, messageId } = req.body;

        if (!reason || newStatus === undefined || messageId === undefined) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['reason', 'newStatus', 'messageId']
            });
        }

        const result = await ffoService.setProcessing(
            id,
            reason,
            newStatus,
            messageId
        );

        res.json({
            ...result,
            message: result.success ? 'Processing status updated successfully' : 'Failed to update status'
        });
    } catch (err) {
        next(err);
    }
});

module.exports = router; 