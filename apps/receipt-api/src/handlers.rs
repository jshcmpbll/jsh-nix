use actix_web::{web, HttpResponse, Result};
use sqlx::PgPool;
use uuid::Uuid;
use chrono::NaiveDate;

use crate::models::{Receipt, CreateReceiptRequest, UpdateReceiptRequest, ReceiptResponse};

pub async fn health_check() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "receipt-api"
    })))
}

pub async fn create_receipt(
    pool: web::Data<PgPool>,
    req: web::Json<CreateReceiptRequest>,
) -> Result<HttpResponse> {
    let purchase_date = NaiveDate::parse_from_str(&req.purchase_date, "%Y-%m-%d")
        .map_err(|e| {
            log::error!("Invalid date format: {}", e);
            actix_web::error::ErrorBadRequest("Invalid date format. Use YYYY-MM-DD")
        })?;

    let id = Uuid::new_v4();
    let now = chrono::Utc::now();

    let result = sqlx::query_as::<_, Receipt>(
        r#"
        INSERT INTO receipts (id, store_name, address, purchase_date, subtotal, tax, total, "user", receipt_image_path, created_at, updated_at)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
        RETURNING id, store_name, address, purchase_date, subtotal, tax, total, "user", receipt_image_path, created_at, updated_at
        "#,
    )
    .bind(id)
    .bind(&req.store_name)
    .bind(&req.location.address)
    .bind(purchase_date)
    .bind(req.subtotal)
    .bind(req.tax)
    .bind(req.total)
    .bind(&req.user)
    .bind(&req.receipt_image_path)
    .bind(now)
    .bind(now)
    .fetch_one(pool.get_ref())
    .await;

    match result {
        Ok(receipt) => {
            let response: ReceiptResponse = receipt.into();
            Ok(HttpResponse::Created().json(response))
        }
        Err(e) => {
            log::error!("Failed to create receipt: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to create receipt"
            })))
        }
    }
}

pub async fn get_receipt(
    pool: web::Data<PgPool>,
    id: web::Path<String>,
) -> Result<HttpResponse> {
    let receipt_id = Uuid::parse_str(&id)
        .map_err(|_| actix_web::error::ErrorBadRequest("Invalid UUID format"))?;

    match sqlx::query_as::<_, Receipt>(
        "SELECT id, store_name, address, purchase_date, subtotal, tax, total, \"user\", receipt_image_path, created_at, updated_at FROM receipts WHERE id = $1"
    )
    .bind(receipt_id)
    .fetch_optional(pool.get_ref())
    .await {
        Ok(Some(receipt)) => {
            let response: ReceiptResponse = receipt.into();
            Ok(HttpResponse::Ok().json(response))
        }
        Ok(None) => {
            Ok(HttpResponse::NotFound().json(serde_json::json!({
                "error": "Receipt not found"
            })))
        }
        Err(e) => {
            log::error!("Database error: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch receipt"
            })))
        }
    }
}

pub async fn update_receipt(
    pool: web::Data<PgPool>,
    id: web::Path<String>,
    req: web::Json<UpdateReceiptRequest>,
) -> Result<HttpResponse> {
    let receipt_id = Uuid::parse_str(&id)
        .map_err(|_| actix_web::error::ErrorBadRequest("Invalid UUID format"))?;

    // First check if receipt exists
    let existing = sqlx::query_as::<_, Receipt>(
        "SELECT id, store_name, address, purchase_date, subtotal, tax, total, \"user\", receipt_image_path, created_at, updated_at FROM receipts WHERE id = $1"
    )
    .bind(receipt_id)
    .fetch_optional(pool.get_ref())
    .await;

    match existing {
        Ok(Some(mut receipt)) => {
            // Update fields if provided
            if let Some(store_name) = &req.store_name {
                receipt.store_name = store_name.clone();
            }
            if let Some(location) = &req.location {
                receipt.address = location.address.clone();
            }
            if let Some(purchase_date_str) = &req.purchase_date {
                receipt.purchase_date = NaiveDate::parse_from_str(purchase_date_str, "%Y-%m-%d")
                    .map_err(|_| actix_web::error::ErrorBadRequest("Invalid date format"))?;
            }
            if let Some(subtotal) = req.subtotal {
                receipt.subtotal = subtotal;
            }
            if let Some(tax) = req.tax {
                receipt.tax = tax;
            }
            if let Some(total) = req.total {
                receipt.total = total;
            }
            if let Some(receipt_image_path) = &req.receipt_image_path {
                receipt.receipt_image_path = receipt_image_path.clone();
            }

            let now = chrono::Utc::now();
            receipt.updated_at = now;

            let result = sqlx::query_as::<_, Receipt>(
                r#"
                UPDATE receipts
                SET store_name = $2, address = $3, purchase_date = $4, subtotal = $5, tax = $6, total = $7, receipt_image_path = $8, updated_at = $9
                WHERE id = $1
                RETURNING id, store_name, address, purchase_date, subtotal, tax, total, "user", receipt_image_path, created_at, updated_at
                "#,
            )
            .bind(receipt_id)
            .bind(&receipt.store_name)
            .bind(&receipt.address)
            .bind(receipt.purchase_date)
            .bind(receipt.subtotal)
            .bind(receipt.tax)
            .bind(receipt.total)
            .bind(&receipt.receipt_image_path)
            .bind(now)
            .fetch_one(pool.get_ref())
            .await;

            match result {
                Ok(updated_receipt) => {
                    let response: ReceiptResponse = updated_receipt.into();
                    Ok(HttpResponse::Ok().json(response))
                }
                Err(e) => {
                    log::error!("Failed to update receipt: {}", e);
                    Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                        "error": "Failed to update receipt"
                    })))
                }
            }
        }
        Ok(None) => {
            Ok(HttpResponse::NotFound().json(serde_json::json!({
                "error": "Receipt not found"
            })))
        }
        Err(e) => {
            log::error!("Database error: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch receipt"
            })))
        }
    }
}

pub async fn delete_receipt(
    pool: web::Data<PgPool>,
    id: web::Path<String>,
) -> Result<HttpResponse> {
    let receipt_id = Uuid::parse_str(&id)
        .map_err(|_| actix_web::error::ErrorBadRequest("Invalid UUID format"))?;

    let result = sqlx::query("DELETE FROM receipts WHERE id = $1")
        .bind(receipt_id)
        .execute(pool.get_ref())
        .await;

    match result {
        Ok(query_result) => {
            if query_result.rows_affected() == 0 {
                Ok(HttpResponse::NotFound().json(serde_json::json!({
                    "error": "Receipt not found"
                })))
            } else {
                Ok(HttpResponse::NoContent().finish())
            }
        }
        Err(e) => {
            log::error!("Failed to delete receipt: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to delete receipt"
            })))
        }
    }
}

pub async fn get_user_receipts(
    pool: web::Data<PgPool>,
    user: web::Path<String>,
) -> Result<HttpResponse> {
    match sqlx::query_as::<_, Receipt>(
        "SELECT id, store_name, address, purchase_date, subtotal, tax, total, \"user\", receipt_image_path, created_at, updated_at FROM receipts WHERE \"user\" = $1 ORDER BY purchase_date DESC"
    )
    .bind(user.into_inner())
    .fetch_all(pool.get_ref())
    .await {
        Ok(receipts) => {
            let responses: Vec<ReceiptResponse> = receipts.into_iter().map(|r| r.into()).collect();
            Ok(HttpResponse::Ok().json(responses))
        }
        Err(e) => {
            log::error!("Database error: {}", e);
            Ok(HttpResponse::InternalServerError().json(serde_json::json!({
                "error": "Failed to fetch receipts"
            })))
        }
    }
}
