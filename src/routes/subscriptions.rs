use actix_web::{web, HttpResponse};
use chrono::Utc;
use sqlx::MySqlPool;

use uuid::Uuid;

#[derive(serde::Deserialize)]
pub struct FormData {
    email: String,
    name: String,
}
#[tracing::instrument(
    name= "Adding a new subscriber",
    skip(form, pool),
    fields(
        subscriber_email= %form.email,
        subscriber_name= %form.name
    )
)]
pub async fn subscribe(form: web::Form<FormData>, pool: web::Data<MySqlPool>) -> HttpResponse {
    // let request_id = Uuid::new_v4();

    // let request_span = tracing::info_span!(
    //     "Adding a new subscriber",
    //     %request_id,
    //     subscriber_email= %form.email,
    //     subscriber_name= %form.name
    // );

    // let _request_span_guard = request_span.enter();

    match insert_subscriber(&pool, &form).await {
        Ok(_) => HttpResponse::Ok().finish(),

        Err(_) => HttpResponse::InternalServerError().finish(),
    }
    //   We use `get_ref` to get an immutable reference to the `PgConnection` wrapped by `web::Data`.
}

#[tracing::instrument(
    name = "Saving new subscriber details in the database",
    skip(form, pool)
)]
pub async fn insert_subscriber(pool: &MySqlPool, form: &FormData) -> Result<(), sqlx::Error> {
    let subscribed_at = Utc::now().naive_utc();

    sqlx::query!(
        r#"
        INSERT INTO subscriptions (id, email, name, subscribed_at)
        VALUES (?, ?, ?, ?)
        "#,
        Uuid::new_v4().to_string(),
        form.email,
        form.name,
        subscribed_at
    )
    .execute(pool)
    .await
    .map_err(|e| {
        tracing::error!("Failed to execute query: {:?}", e);
        e
    })?;
    Ok(())
}
