const express = require('express');
const router = express.Router();


router.get('/show', async (req, res) => {
    try {
      const { docId } = req.query;
      
      if (!docId) {
        return res.status(400).send('Document ID is required');
      }
  
      const html = `
        <!DOCTYPE html>
        <html>
          <head>
            <title>Document Viewer</title>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
          </head>
          <body>
            <div id="document-container">
              <h1>Document ID: ${docId}</h1>
            </div>
          </body>
        </html>
      `;
  
      res.setHeader('Content-Type', 'text/html');
      res.send(html);
    } catch (err) {
      console.error('Error in bodi/show:', err);
      res.status(500).send('Internal server error');
    }
  });

module.exports = router;