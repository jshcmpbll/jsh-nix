use actix_web::{web, App, HttpServer, middleware::Logger};
use sqlx::postgres::PgPoolOptions;
use std::env;

mod models;
mod handlers;
mod db;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    dotenvy::dotenv().ok();

    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");

    // Create connection pool
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await
        .expect("Failed to create pool");

    // Run migrations
    db::init(&pool)
        .await
        .expect("Failed to run migrations");

    let pool_data = web::Data::new(pool);

    log::info!("Starting Receipt API server on 0.0.0.0:8080");

    HttpServer::new(move || {
        App::new()
            .app_data(pool_data.clone())
            .wrap(Logger::default())
            .service(
                web::scope("/api/v1/receipts")
                    .route("", web::post().to(handlers::create_receipt))
                    .route("/{id}", web::get().to(handlers::get_receipt))
                    .route("/{id}", web::put().to(handlers::update_receipt))
                    .route("/{id}", web::delete().to(handlers::delete_receipt))
                    .route("/user/{user}", web::get().to(handlers::get_user_receipts))
            )
            .service(
                web::scope("/api/v1/health")
                    .route("", web::get().to(handlers::health_check))
            )
    })
    .bind("0.0.0.0:8080")?
    .run()
    .await
}
