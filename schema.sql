CREATE DATABASE IF NOT EXISTS st1_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE st1_db;

CREATE TABLE IF NOT EXISTS board (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    title      VARCHAR(200)  NOT NULL,
    content    TEXT          NOT NULL,
    author     VARCHAR(50)   NOT NULL,
    created_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS guestbook (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    author     VARCHAR(50)   NOT NULL,
    message    TEXT          NOT NULL,
    created_at DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
);
