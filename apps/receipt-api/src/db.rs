use sqlx::PgPool;

pub async fn init(pool: &PgPool) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS receipts (
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
        )
        "#,
    )
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        CREATE INDEX IF NOT EXISTS idx_receipts_user ON receipts("user")
        "#,
    )
    .execute(pool)
    .await?;

    sqlx::query(
        r#"
        CREATE INDEX IF NOT EXISTS idx_receipts_purchase_date ON receipts(purchase_date)
        "#,
    )
    .execute(pool)
    .await?;

    log::info!("Database initialized successfully");
    Ok(())
}
