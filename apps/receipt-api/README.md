# Receipt API

A Rust-based REST API service for managing receipt data with PostgreSQL.

## Features

- Create, read, update, and delete receipts
- Multi-user receipt management
- PostgreSQL database with automatic migrations
- RESTful API endpoints
- Comprehensive error handling
- JSON request/response format

## API Endpoints

### Health Check
- `GET /api/v1/health` - Check API health status

### Receipt Management
- `POST /api/v1/receipts` - Create a new receipt
- `GET /api/v1/receipts/{id}` - Get a specific receipt
- `PUT /api/v1/receipts/{id}` - Update a receipt
- `DELETE /api/v1/receipts/{id}` - Delete a receipt
- `GET /api/v1/receipts/user/{user}` - Get all receipts for a specific user

## Request/Response Format

### Create Receipt
**POST** `/api/v1/receipts`

Request body:
```json
{
  "store_name": "Example Supermarket",
  "location": {
    "address": "123 Example Street, Cityville, Country"
  },
  "purchase_date": "2023-09-29",
  "subtotal": 10.47,
  "tax": 0.73,
  "total": 11.20,
  "user": "James",
  "receipt_image_path": "https://example.com/images/receipt/1234567890.jpg"
}
```

Response (201 Created):
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "store_name": "Example Supermarket",
  "location": {
    "address": "123 Example Street, Cityville, Country"
  },
  "purchase_date": "2023-09-29",
  "subtotal": 10.47,
  "tax": 0.73,
  "total": 11.20,
  "user": "James",
  "receipt_image_path": "https://example.com/images/receipt/1234567890.jpg",
  "created_at": "2023-09-29T10:30:00Z",
  "updated_at": "2023-09-29T10:30:00Z"
}
```

### Update Receipt
**PUT** `/api/v1/receipts/{id}`

Request body (all fields optional):
```json
{
  "store_name": "Updated Store Name",
  "location": {
    "address": "New Address"
  },
  "purchase_date": "2023-09-30",
  "subtotal": 15.00,
  "tax": 1.00,
  "total": 16.00,
  "receipt_image_path": "https://example.com/images/receipt/new.jpg"
}
```

### Get User Receipts
**GET** `/api/v1/receipts/user/{user}`

Response (200 OK):
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "store_name": "Example Supermarket",
    "location": {
      "address": "123 Example Street, Cityville, Country"
    },
    "purchase_date": "2023-09-29",
    "subtotal": 10.47,
    "tax": 0.73,
    "total": 11.20,
    "user": "James",
    "receipt_image_path": "https://example.com/images/receipt/1234567890.jpg",
    "created_at": "2023-09-29T10:30:00Z",
    "updated_at": "2023-09-29T10:30:00Z"
  }
]
```

## Setup

### Prerequisites
- PostgreSQL 12 or higher
- Rust 1.70 or higher (for local development)
- Nix (for Nix-based deployment)

### Environment Configuration

1. Create a `.env` file based on `.env.example`:
```bash
cp .env.example .env
```

2. Update the `DATABASE_URL` in `.env`:
```
DATABASE_URL=postgresql://username:password@localhost:5432/receipts_db
```

### Local Development

```bash
# Install dependencies and build
cargo build

# Run the server
cargo run

# Run tests
cargo test
```

The API will be available at `http://localhost:8080`

### Nix Deployment

Add to your flake.nix:
```nix
packages.x86_64-linux.receipt-api = pkgs.callPackage ./apps/receipt-api/default.nix { };
```

## Database Schema

The application automatically creates the following table on startup:

```sql
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  purchase_date DATE NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) NOT NULL,
  total DECIMAL(10, 2) NOT NULL,
  "user" VARCHAR(255) NOT NULL,
  receipt_image_path TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_receipts_user ON receipts("user");
CREATE INDEX idx_receipts_purchase_date ON receipts(purchase_date);
```

## Error Handling

The API returns appropriate HTTP status codes:
- `200 OK` - Successful GET request
- `201 Created` - Successful POST request
- `204 No Content` - Successful DELETE request
- `400 Bad Request` - Invalid request format or parameters
- `404 Not Found` - Resource not found
- `500 Internal Server Error` - Server error

## Logging

The application uses the `log` crate with `env_logger` for logging. Set the `RUST_LOG` environment variable to control log levels:

```bash
RUST_LOG=debug cargo run
RUST_LOG=info cargo run
RUST_LOG=warn cargo run
```

## License

MIT License
