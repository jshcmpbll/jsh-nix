# Receipt API - Development Guide

## Quick Start with Docker Compose

The easiest way to get started is using Docker Compose to run PostgreSQL:

```bash
# Start PostgreSQL container
docker-compose up -d

# Create .env file
cp .env.example .env

# Build and run the server
cargo run
```

The API will be available at `http://localhost:8080`

## Testing the API

### Health Check
```bash
curl http://localhost:8080/api/v1/health
```

### Create a Receipt
```bash
curl -X POST http://localhost:8080/api/v1/receipts \
  -H "Content-Type: application/json" \
  -d '{
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
  }'
```

### Get a Receipt
```bash
# Replace {id} with the actual receipt ID from create response
curl http://localhost:8080/api/v1/receipts/{id}
```

### Update a Receipt
```bash
curl -X PUT http://localhost:8080/api/v1/receipts/{id} \
  -H "Content-Type: application/json" \
  -d '{
    "store_name": "Updated Store Name"
  }'
```

### Delete a Receipt
```bash
curl -X DELETE http://localhost:8080/api/v1/receipts/{id}
```

### Get All Receipts for a User
```bash
curl http://localhost:8080/api/v1/receipts/user/James
```

## Development Workflow

### Running Tests
```bash
cargo test
```

### Checking Code Quality
```bash
# Format code
cargo fmt

# Lint code
cargo clippy
```

### Building for Release
```bash
cargo build --release
```

The binary will be available at `target/release/receipt-api`

## Database Management

### Connecting to PostgreSQL
```bash
# Using psql
psql -h localhost -U receipts_user -d receipts_db

# When prompted, enter password: receipts_password
```

### Viewing Tables
```sql
-- List all tables
\dt

-- View receipts table structure
\d receipts

-- View all receipts
SELECT * FROM receipts;

-- View receipts for a specific user
SELECT * FROM receipts WHERE "user" = 'James';
```

### Stopping the Database
```bash
docker-compose down

# To remove all data as well
docker-compose down -v
```

## Nix Build Instructions

### Building with Nix
```bash
# Build the package
nix build .#receipt-api

# Run the built package
./result/bin/receipt-api
```

### Adding to NixOS Configuration

In your NixOS configuration, you can add the receipt-api service:

```nix
{
  services.receipt-api = {
    enable = true;
    package = inputs.self.packages.x86_64-linux.receipt-api;
    database = {
      host = "localhost";
      port = 5432;
      user = "receipts_user";
      database = "receipts_db";
    };
  };
}
```

## Troubleshooting

### Connection Refused
- Ensure PostgreSQL is running: `docker-compose ps`
- Verify DATABASE_URL in .env file
- Check PostgreSQL is listening on port 5432

### Migration Errors
- The tables are created automatically on first run
- If you need to reset: Drop and recreate the database in PostgreSQL

### Port Already in Use
- Change the port in main.rs from 8080 to another port
- Or stop any other services using port 8080

## Project Structure

```
receipt-api/
├── src/
│   ├── main.rs          # Application entry point
│   ├── models.rs        # Data models and requests/responses
│   ├── handlers.rs      # HTTP request handlers
│   └── db.rs            # Database initialization and migrations
├── Cargo.toml           # Rust dependencies
├── Cargo.lock           # Dependency lock file
├── default.nix          # Nix build configuration
├── .env.example         # Example environment variables
├── docker-compose.yml   # PostgreSQL Docker setup
├── README.md            # API documentation
└── DEVELOPMENT.md       # This file
```

## Performance Notes

- The application uses a connection pool with max 5 connections
- Indices are created on `user` and `purchase_date` columns for faster queries
- Consider increasing `max_connections` for production use

## Production Deployment

For production:
1. Set strong PostgreSQL credentials
2. Update DATABASE_URL with production database
3. Set RUST_LOG=warn for production logging
4. Consider using a reverse proxy (nginx) in front
5. Enable HTTPS/TLS
6. Set up database backups
7. Monitor application logs and metrics
