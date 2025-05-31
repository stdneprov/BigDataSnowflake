CREATE SCHEMA snowflake;

CREATE TABLE snowflake.dim_customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    age INTEGER,
    country VARCHAR(100),
    postal_code VARCHAR(20),
    pet_type VARCHAR(50),
    pet_name VARCHAR(100),
    pet_breed VARCHAR(100)
);

CREATE TABLE snowflake.dim_sellers (
    seller_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(255),
    country VARCHAR(100),
    postal_code VARCHAR(20)
);

CREATE TABLE snowflake.dim_stores (
    store_id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    location VARCHAR(255),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100),
    phone VARCHAR(50),
    email VARCHAR(255)
);

CREATE TABLE snowflake.dim_product_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100),
    pet_category VARCHAR(100)
);

CREATE TABLE snowflake.dim_suppliers (
    supplier_id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    contact VARCHAR(255),
    email VARCHAR(255),
    phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100)
);

CREATE TABLE snowflake.dim_products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(255),
    category_id INTEGER REFERENCES snowflake.dim_product_categories(category_id) ON DELETE SET NULL,
    price DECIMAL(10,2),
    weight DECIMAL(10,2),
    color VARCHAR(50),
    size VARCHAR(50),
    brand VARCHAR(100),
    material VARCHAR(100),
    description TEXT,
    rating DECIMAL(3,1),
    reviews INTEGER,
    release_date DATE,
    expiry_date DATE,
    supplier_id INTEGER REFERENCES snowflake.dim_suppliers(supplier_id) ON DELETE SET NULL
);

CREATE TABLE snowflake.fact_sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES snowflake.dim_customers(customer_id) ON DELETE SET NULL,
    seller_id INTEGER REFERENCES snowflake.dim_sellers(seller_id) ON DELETE SET NULL,
    product_id INTEGER REFERENCES snowflake.dim_products(product_id) ON DELETE SET NULL,
    store_id INTEGER REFERENCES snowflake.dim_stores(store_id) ON DELETE SET NULL,
    quantity INTEGER,
    total_price DECIMAL(10,2),
    date DATE
);
