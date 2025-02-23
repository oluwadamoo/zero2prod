-- Add migration script here
CREATE TABLE subscriptions(
    id CHAR(36) NOT NULL,
    PRIMARY KEY (id),
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    subscribed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);