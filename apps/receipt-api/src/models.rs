use serde::{Deserialize, Serialize};
use chrono::NaiveDate;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Receipt {
    pub id: Uuid,
    pub store_name: String,
    pub address: String,
    pub purchase_date: NaiveDate,
    pub subtotal: f64,
    pub tax: f64,
    pub total: f64,
    pub user: String,
    pub receipt_image_path: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
    pub updated_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateReceiptRequest {
    pub store_name: String,
    pub location: LocationData,
    pub purchase_date: String,
    pub subtotal: f64,
    pub tax: f64,
    pub total: f64,
    pub user: String,
    pub receipt_image_path: String,
}

#[derive(Debug, Deserialize)]
pub struct LocationData {
    pub address: String,
}

#[derive(Debug, Serialize)]
pub struct ReceiptResponse {
    pub id: String,
    pub store_name: String,
    pub location: LocationResponse,
    pub purchase_date: String,
    pub subtotal: f64,
    pub tax: f64,
    pub total: f64,
    pub user: String,
    pub receipt_image_path: String,
    pub created_at: String,
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
pub struct LocationResponse {
    pub address: String,
}

impl From<Receipt> for ReceiptResponse {
    fn from(receipt: Receipt) -> Self {
        ReceiptResponse {
            id: receipt.id.to_string(),
            store_name: receipt.store_name,
            location: LocationResponse {
                address: receipt.address,
            },
            purchase_date: receipt.purchase_date.to_string(),
            subtotal: receipt.subtotal,
            tax: receipt.tax,
            total: receipt.total,
            user: receipt.user,
            receipt_image_path: receipt.receipt_image_path,
            created_at: receipt.created_at.to_rfc3339(),
            updated_at: receipt.updated_at.to_rfc3339(),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct UpdateReceiptRequest {
    pub store_name: Option<String>,
    pub location: Option<LocationData>,
    pub purchase_date: Option<String>,
    pub subtotal: Option<f64>,
    pub tax: Option<f64>,
    pub total: Option<f64>,
    pub receipt_image_path: Option<String>,
}
