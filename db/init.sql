-- ============================================================
-- Task 4c: Database initialisation script
-- Runs automatically when the MySQL container starts for the
-- first time (mounted into /docker-entrypoint-initdb.d/).
-- ============================================================

CREATE DATABASE IF NOT EXISTS lab2db;
USE lab2db;

CREATE TABLE IF NOT EXISTS notes (
    id         INT          NOT NULL AUTO_INCREMENT,
    title      VARCHAR(255) NOT NULL,
    content    TEXT         NOT NULL,
    created_at TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seed data so the app is not empty on first launch
INSERT INTO notes (title, content) VALUES
    ('Welcome to Lab 2',  'This note was added by the database init script.'),
    ('Docker Compose',    'docker compose up --build starts all services together.'),
    ('Three-tier app',    'Frontend (Nginx) → Backend (Flask) → Database (MySQL).');
