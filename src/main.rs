use std::net::TcpListener;

use sqlx::mysql::MySqlPoolOptions;
use zero2prod::{
    configuration::get_configuration,
    startup::run,
    telemetry::{get_subscriber, init_subscriber},
};

#[tokio::main]
async fn main() -> Result<(), std::io::Error> {
    // env_logger::Builder::from_env(Env::default().default_filter_or("info")).init();
    //   Redirect all `log`'s events to our subscriber
    let subscriber = get_subscriber("zero2prod".into(), "info".into(), std::io::stdout);

    init_subscriber(subscriber);

    // Panic if we can't read configuration
    let configuration = get_configuration().expect("Failed to read configuration.");

    let connection_pool =
        MySqlPoolOptions::new().connect_lazy_with(configuration.database.with_db());

    let address = format!(
        "{}:{}",
        configuration.application.host, configuration.application.port
    );

    let listener = TcpListener::bind(address)?;

    run(listener, connection_pool)?.await
}
