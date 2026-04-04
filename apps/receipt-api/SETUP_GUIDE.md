# Receipt API - Complete Setup & Deployment Guide

## 📁 Project Structure

```
apps/receipt-api/
├── src/
│   ├── main.rs              # Application entry point & server setup
│   ├── models.rs            # Data structures & type definitions
│   ├── handlers.rs          # HTTP request handlers (CRUD operations)
│   └── db.rs                # Database initialization & migrations
├── Cargo.toml               # Rust dependencies & project config
├── default.nix              # Nix package definition
├── docker-compose.yml       # PostgreSQL dev environment
├── Makefile                 # Convenient task commands
├── .env.example             # Environment template
├── .gitignore               # Git exclusions
├── README.md                # API documentation
├── DEVELOPMENT.md           # Development guide
├── PROJECT_SUMMARY.md       # Project overview
├── migrations.sql           # Database schema reference
└── examples.sh              # Example curl commands
```

## 🚀 Quick Start (3 steps)

### Option 1: Using Docker + Local Build

```bash
# Navigate to the project
cd apps/receipt-api

# Initialize environment
make dev-setup

# Start the server
make run
```

### Option 2: Using Nix

```bash
# Build the package
nix build .#receipt-api

# Run the binary
DATABASE_URL="postgresql://user:pass@localhost:5432/db" ./result/bin/receipt-api
```

### Option 3: Manual Setup

```bash
cd apps/receipt-api

# Copy environment configuration
cp .env.example .env

# Start PostgreSQL
docker-compose up -d

# Update DATABASE_URL in .env

# Build and run
cargo build
cargo run
```

## 📝 API Documentation

### Base URL
```
http://localhost:8080/api/v1
```

### Endpoints

#### Health Check
```
GET /health
```
Response: `{"status":"healthy","service":"receipt-api"}`

#### Create Receipt
```
POST /receipts
Content-Type: application/json

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
Response: `201 Created` + Receipt object with ID and timestamps

#### Get Receipt
```
GET /receipts/{id}
```
Response: `200 OK` + Receipt object (or `404 Not Found`)

#### Update Receipt
```
PUT /receipts/{id}
Content-Type: application/json

{
  "store_name": "Updated Name",
  "subtotal": 15.00
}
```
All fields are optional. Only provided fields will be updated.
Response: `200 OK` + Updated receipt object

#### Delete Receipt
```
DELETE /receipts/{id}
```
Response: `204 No Content` (or `404 Not Found`)

#### Get User Receipts
```
GET /receipts/user/{user}
```
Returns array of receipts for the specified user, sorted by purchase_date (newest first).
Response: `200 OK` + Array of Receipt objects

## 🗄️ Database Schema

Automatically created on application startup:

```sql
receipts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  purchase_date DATE NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) NOT NULL,
  total DECIMAL(10, 2) NOT NULL,
  "user" VARCHAR(255) NOT NULL,
  receipt_image_path TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
)

Indices:
- idx_receipts_user (on "user")
- idx_receipts_purchase_date (on purchase_date)
```

## 🛠️ Makefile Commands

```bash
make help              # Show all available commands
make setup             # Initialize .env file
make dev-setup         # Full development setup with Docker
make run               # Run the server (with logging)
make build             # Build release binary
make test              # Run tests
make fmt               # Format code
make lint              # Run clippy lint checks
make watch             # Run with auto-reload (requires cargo-watch)
make clean             # Remove build artifacts
make docker-up         # Start PostgreSQL container
make docker-down       # Stop PostgreSQL container
make docker-clean      # Stop and remove all data
make build-nix         # Build with Nix
```

## 🧪 Testing

### Using Example Script
```bash
# Make the script executable
chmod +x examples.sh

# Run all example requests
./examples.sh
```

### Using curl Manually
```bash
# Health check
curl http://localhost:8080/api/v1/health

# Create receipt
curl -X POST http://localhost:8080/api/v1/receipts \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "store_name": "Test Store",
  "location": {"address": "123 Test St"},
  "purchase_date": "2023-09-29",
  "subtotal": 10.47,
  "tax": 0.73,
  "total": 11.20,
  "user": "James",
  "receipt_image_path": "https://example.com/receipt.jpg"
}
EOF

# Get user receipts
curl http://localhost:8080/api/v1/receipts/user/James
```

## 🔧 Configuration

### Environment Variables

Create `.env` file based on `.env.example`:

```env
# PostgreSQL connection string
DATABASE_URL=postgresql://user:password@host:port/database

# Logging level (debug, info, warn, error)
RUST_LOG=info
```

### Using Docker Compose

The included `docker-compose.yml` starts PostgreSQL with:
- User: `receipts_user`
- Password: `receipts_password`
- Database: `receipts_db`
- Port: `5432`

Default `.env` uses these credentials.

## 📦 Building for Production

### With Cargo (Rust)
```bash
cargo build --release
# Binary at: target/release/receipt-api
```

### With Nix
```bash
nix build .#receipt-api
# Binary at: result/bin/receipt-api
```

### Docker Image (Optional - Create your own)
```dockerfile
FROM rust:latest as builder
WORKDIR /app
COPY . .
RUN cargo build --release

FROM debian:bookworm-slim
COPY --from=builder /app/target/release/receipt-api /usr/local/bin/
CMD ["receipt-api"]
```

## 🔐 Security Considerations

1. **Database Credentials**: Use strong passwords in production
2. **HTTPS/TLS**: Place behind a reverse proxy (nginx, HAProxy)
3. **Authentication**: Add auth middleware if needed
4. **Rate Limiting**: Consider adding rate limiting middleware
5. **CORS**: Configure appropriately for your frontend
6. **Input Validation**: All inputs are validated
7. **SQL Injection**: Protected by sqlx parameterized queries

## 📊 Performance Notes

- **Connection Pool**: Default 5 connections (configurable in main.rs)
- **Indices**: Automatic indices on user and purchase_date
- **Async Runtime**: Tokio for non-blocking I/O
- **Connection String**: Uses native TLS (configurable)

For production, consider:
- Increasing max_connections based on expected load
- Adding application-level caching
- Implementing database connection retry logic
- Setting up monitoring and alerting

## 🐛 Troubleshooting

### "Connection refused" error
```bash
# Verify Docker container is running
docker-compose ps

# Check DATABASE_URL in .env
cat .env | grep DATABASE_URL

# Verify PostgreSQL is accessible
psql -h localhost -U receipts_user -d receipts_db
```

### Port 8080 already in use
Edit `src/main.rs` line with `.bind()` to use different port.

### "Cannot find migrations" or database issues
Delete the existing database and restart:
```bash
docker-compose down -v
docker-compose up -d
cargo run
```

### Build errors
```bash
# Update Rust
rustup update

# Clean build
cargo clean
cargo build
```

## 📚 Additional Resources

- **Actix-web docs**: https://docs.rs/actix-web/
- **SQLx docs**: https://docs.rs/sqlx/
- **Tokio docs**: https://docs.rs/tokio/
- **PostgreSQL docs**: https://www.postgresql.org/docs/

## 🔄 Integration Examples

### With Frontend
```javascript
// JavaScript/TypeScript example
const response = await fetch('http://localhost:8080/api/v1/receipts', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    store_name: "Store Name",
    location: { address: "Address" },
    purchase_date: "2023-09-29",
    subtotal: 10.47,
    tax: 0.73,
    total: 11.20,
    user: "James",
    receipt_image_path: "https://..."
  })
});
const receipt = await response.json();
```

### With NixOS
```nix
services.receipt-api = {
  enable = true;
  package = inputs.self.packages.x86_64-linux.receipt-api;
  environment = {
    DATABASE_URL = "postgresql://...";
    RUST_LOG = "info";
  };
};

services.postgresql = {
  enable = true;
  ensureDatabases = [ "receipts_db" ];
  ensureUsers = [{
    name = "receipts_user";
    ensurePermissions = { "DATABASE receipts_db" = "ALL PRIVILEGES"; };
  }];
};
```

## 📋 Checklist for Deployment

- [ ] Update DATABASE_URL with production credentials
- [ ] Set RUST_LOG=warn for production
- [ ] Configure firewall rules
- [ ] Set up TLS/HTTPS reverse proxy
- [ ] Configure backup strategy for PostgreSQL
- [ ] Set up monitoring and alerting
- [ ] Add authentication/authorization if needed
- [ ] Test all endpoints with production data
- [ ] Document any customizations
- [ ] Set up CI/CD pipeline

## 📞 Support

For issues or questions:
1. Check DEVELOPMENT.md for development-specific help
2. Review README.md for API documentation
3. Check logs: `RUST_LOG=debug cargo run`
4. Verify PostgreSQL connection
5. Review Rust error messages carefully

## 📄 License

MIT License - See repository for details
