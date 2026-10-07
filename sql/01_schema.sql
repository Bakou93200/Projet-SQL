-- =====================================================================
-- Schéma relationnel en 3e forme normale (SQLite)
-- Ventes d'un distributeur d'électronique (magasins physiques + en ligne)
-- =====================================================================
-- Corrections par rapport au modèle initial :
--   * catégories et sous-catégories séparées (la dépendance
--     sous-catégorie -> catégorie -> nom de catégorie était transitive) ;
--   * commandes et lignes de commande séparées (date, client et magasin
--     dépendent du seul numéro de commande, pas de la ligne) ;
--   * pays -> continent extrait dans sa propre table ;
--   * clés primaires, clés étrangères, NOT NULL et CHECK déclarés ;
--   * dates stockées au format ISO 8601 (TEXT 'AAAA-MM-JJ').

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_lines;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS subcategories;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS countries;

CREATE TABLE countries (
    country    TEXT PRIMARY KEY,
    continent  TEXT NOT NULL
);

CREATE TABLE customers (
    customer_id  INTEGER PRIMARY KEY,
    name         TEXT NOT NULL,
    gender       TEXT NOT NULL CHECK (gender IN ('Male', 'Female')),
    birth_date   TEXT NOT NULL,
    city         TEXT NOT NULL,
    state_code   TEXT,
    state        TEXT NOT NULL,
    zip_code     TEXT NOT NULL,
    country      TEXT NOT NULL REFERENCES countries (country)
);

-- Le magasin 0 est la boutique en ligne : pas de pays ni de surface
CREATE TABLE stores (
    store_id     INTEGER PRIMARY KEY,
    country      TEXT REFERENCES countries (country),
    state        TEXT,
    square_meters INTEGER CHECK (square_meters >= 0),
    open_date    TEXT NOT NULL,
    is_online    INTEGER NOT NULL CHECK (is_online IN (0, 1))
);

CREATE TABLE categories (
    category_id  INTEGER PRIMARY KEY,
    name         TEXT NOT NULL UNIQUE
);

CREATE TABLE subcategories (
    subcategory_id  INTEGER PRIMARY KEY,
    name            TEXT NOT NULL,
    category_id     INTEGER NOT NULL REFERENCES categories (category_id)
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    name            TEXT NOT NULL,
    brand           TEXT NOT NULL,
    color           TEXT NOT NULL,
    unit_cost       REAL NOT NULL CHECK (unit_cost >= 0),
    unit_price      REAL NOT NULL CHECK (unit_price >= 0),
    subcategory_id  INTEGER NOT NULL REFERENCES subcategories (subcategory_id)
);

CREATE TABLE orders (
    order_number   INTEGER PRIMARY KEY,
    order_date     TEXT NOT NULL,
    delivery_date  TEXT CHECK (delivery_date IS NULL OR delivery_date >= order_date),
    customer_id    INTEGER NOT NULL REFERENCES customers (customer_id),
    store_id       INTEGER NOT NULL REFERENCES stores (store_id)
);

CREATE TABLE order_lines (
    order_number  INTEGER NOT NULL REFERENCES orders (order_number),
    line_item     INTEGER NOT NULL CHECK (line_item >= 1),
    product_id    INTEGER NOT NULL REFERENCES products (product_id),
    quantity      INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_number, line_item)
);

-- Index sur les clés étrangères les plus utilisées dans les jointures
CREATE INDEX idx_orders_customer   ON orders (customer_id);
CREATE INDEX idx_orders_store      ON orders (store_id);
CREATE INDEX idx_orders_date       ON orders (order_date);
CREATE INDEX idx_lines_product     ON order_lines (product_id);
CREATE INDEX idx_products_subcat   ON products (subcategory_id);
CREATE INDEX idx_customers_country ON customers (country);
