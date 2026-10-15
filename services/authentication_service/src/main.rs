#![recursion_limit = "256"]

use anyhow::Context;
use macro_entrypoint::MacroEntrypoint;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    MacroEntrypoint::default().init();

    if std::env::var("RUN_DATABASE_MIGRATIONS").as_deref() == Ok("true") {
        let database_url = std::env::var("DATABASE_URL")
            .context("DATABASE_URL is required when RUN_DATABASE_MIGRATIONS=true")?;
        let pool = sqlx::postgres::PgPoolOptions::new()
            .max_connections(2)
            .connect(&database_url)
            .await
            .context("failed to connect to MacroDB before applying migrations")?;

        tracing::info!("applying MacroDB migrations");
        macro_db_migrator::MACRO_DB_MIGRATIONS
            .run(&pool)
            .await
            .context("failed to apply MacroDB migrations")?;
        pool.close().await;
        tracing::info!("MacroDB migrations are up to date");
    }

    authentication_service::run().await
}

