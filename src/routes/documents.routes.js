const express = require('express');
const router = express.Router();
const { DocumentsService } = require('../services/ServiceFactory');

const documentsService = new DocumentsService();

/**
 * GET /api/documents/:id
 * Get basic document information by ID
 */
router.get('/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getById(id);

        if (!result.found) {
            return res.status(404).json({
                error: 'Document not found',
                documentId: id
            });
        }

        res.json(result);
    } catch (err) {
        console.error('Error getting document by ID:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /api/documents/:id/history
 * Get document audit history
 */
router.get('/:id/history', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getHistory(id);
        res.json(result);
    } catch (err) {
        console.error('Error getting document history:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /api/documents/:id/messages
 * Get message-related history
 */
router.get('/:id/messages', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getMessageHistory(id);
        res.json(result);
    } catch (err) {
        console.error('Error getting message history:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /api/documents/:id/addresses
 * Get document addresses
 */
router.get('/:id/addresses', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getAddresses(id);
        res.json(result);
    } catch (err) {
        console.error('Error getting document addresses:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /api/documents/:id/extensions
 * Get document extensions
 */
router.get('/:id/extensions', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getExtensions(id);
        res.json(result);
    } catch (err) {
        console.error('Error getting document extensions:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /api/documents/:id/signatures
 * Get Internet Banking signatures
 */
router.get('/:id/signatures', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getIBSignatures(id);
        res.json(result);
    } catch (err) {
        console.error('Error getting document signatures:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * GET /api/documents/:id/change-officer
 * Get change officer ID for a document
 */
router.get('/:id/change-officer', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.getChangeOfficerId(id);
        res.json(result);
    } catch (err) {
        console.error('Error getting change officer ID:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/documents/:id/lock
 * Lock document for editing
 */
router.post('/:id/lock', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.setLock(id);

        if (!result.lockAcquired) {
            return res.status(423).json({
                ...result,
                message: 'Document is locked by another user'
            });
        }

        res.json({
            ...result,
            message: 'Document locked successfully'
        });
    } catch (err) {
        console.error('Error locking document:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/documents/:id/status
 * Set document status manually
 *
 * Body: {
 *   reason: string,
 *   newStatus: number,
 *   messageId: number
 * }
 */
router.post('/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { reason, newStatus, messageId } = req.body;

        if (!reason || newStatus === undefined || messageId === undefined) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['reason', 'newStatus', 'messageId']
            });
        }

        const result = await documentsService.setManualStatus(
            id,
            reason,
            newStatus,
            messageId
        );

        res.json({
            ...result,
            message: 'Document status updated successfully'
        });
    } catch (err) {
        console.error('Error setting document status:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/documents/:id/status-with-ref
 * Set document status manually with bank reference
 *
 * Body: {
 *   reason: string,
 *   newStatus: number,
 *   messageId: number,
 *   bankReference: string
 * }
 */
router.post('/:id/status-with-ref', async (req, res) => {
    try {
        const { id } = req.params;
        const { reason, newStatus, messageId, bankReference } = req.body;

        if (!reason || newStatus === undefined || messageId === undefined || !bankReference) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['reason', 'newStatus', 'messageId', 'bankReference']
            });
        }

        const result = await documentsService.setManualStatusWithRef(
            id,
            reason,
            newStatus,
            messageId,
            bankReference
        );

        res.json({
            ...result,
            message: 'Document status updated successfully with bank reference'
        });
    } catch (err) {
        console.error('Error setting document status with ref:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/documents/:id/manual-processing
 * Enable manual processing for a document
 */
router.post('/:id/manual-processing', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await documentsService.setManualProcessing(id);

        res.json({
            ...result,
            message: 'Manual processing enabled'
        });
    } catch (err) {
        console.error('Error enabling manual processing:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

/**
 * POST /api/documents/sign-owner
 * Get signature owner information
 *
 * Body: {
 *   certificateId: string,
 *   signatureDate: string (ISO 8601)
 * }
 */
router.post('/sign-owner', async (req, res) => {
    try {
        const { certificateId, signatureDate } = req.body;

        if (!certificateId || !signatureDate) {
            return res.status(400).json({
                error: 'Missing required fields',
                required: ['certificateId', 'signatureDate']
            });
        }

        const result = await documentsService.getSignOwner(certificateId, signatureDate);
        res.json(result);
    } catch (err) {
        console.error('Error getting sign owner:', err);
        res.status(500).json({ error: 'Internal server error' });
    }
});

module.exports = router;