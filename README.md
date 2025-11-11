# Node.js API Gateway with Oracle PL/SQL

This project implements an API gateway that exposes a REST endpoint to invoke an Oracle PL/SQL procedure and return JSON results. It also supports mock responses for local development.

## Setup

1. **Install dependencies**  
   ```bash
   npm install
   ```

2. **Configure environment**  
   Copy `.env.example` to `.env` and set your Oracle DB credentials:
   ```bash
   cp .env .env
   ```

3. **Run the server**  
   ```bash
   npm start
   ```

The service listens on `http://localhost:<PORT>/api/documents/getList`.

## Endpoint

- `POST /api/documents/getList`
  - Request body:
    ```json
    {
      "classId": [10, 20, 30],
      "user": "alice"
    }
    ```
  - Response body (JSON array of documents).

## Switching between mock and real DB

Control `MOCK_ENABLED` in your `.env` file:
- `MOCK_ENABLED=true` – returns hardcoded mock documents.
- `MOCK_ENABLED=false` – calls the PL/SQL procedure `PKG_DOCUMENTS.GET_DOCUMENTS_LIST`.


## Docker 
docker-compose up  #

1. **Run container**
docker-compose up
2. 