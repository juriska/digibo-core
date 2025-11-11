const express = require('express');
const router = express.Router();


router.get('/user/modules', async (req, res) => {
    res.json([
        { "name": "payments", "canView": true, "canEdit": false },
        { "name": "users", "canView": true }
    ]);
});

module.exports = router;

// This is a simple route to return user modules with permissions.
// The actual logic for determining permissions would likely be more complex in a real application.

