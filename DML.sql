INSERT INTO snowflake.dim_pet_types (name)
SELECT DISTINCT 
    customer_pet_type 
FROM mock_data 
WHERE customer_pet_type IS NOT NULL;

INSERT INTO snowflake.dim_pet_breeds (pet_type_id, name)
SELECT DISTINCT
    pt.pet_type_id,
    m.customer_pet_breed 
FROM mock_data m
LEFT JOIN snowflake.dim_pet_types pt ON pt.name = m.customer_pet_type 
WHERE m.customer_pet_breed IS NOT NULL;

INSERT INTO snowflake.dim_pets (pet_id, breed_id, name)
SELECT DISTINCT
    m.sale_customer_id + FLOOR((m.id - 1) / 1000) * 1000,
    pb.pet_breed_id,
    m.customer_pet_breed 
FROM mock_data m
LEFT JOIN snowflake.dim_pet_types pt ON pt.name = m.customer_pet_type 
LEFT JOIN snowflake.dim_pet_breeds pb ON pb.name = m.customer_pet_breed  AND pb.pet_type_id = pt.pet_type_id
WHERE m.customer_pet_name IS NOT NULL AND m.sale_customer_id IS NOT NULL;

INSERT INTO snowflake.dim_countries (name)
SELECT DISTINCT
    name 
FROM (
    (SELECT DISTINCT customer_country AS name FROM mock_data WHERE customer_country IS NOT NULL)
    UNION
    (SELECT DISTINCT seller_country AS name FROM mock_data WHERE seller_country IS NOT NULL)
    UNION
    (SELECT DISTINCT store_country AS name FROM mock_data WHERE store_country IS NOT NULL)
    UNION
    (SELECT DISTINCT supplier_country AS name FROM mock_data WHERE supplier_country IS NOT NULL)
) as tbl;


INSERT INTO snowflake.dim_states (name)
SELECT DISTINCT
    store_state 
FROM mock_data
WHERE store_state IS NOT NULL;

INSERT INTO snowflake.dim_cities (name)
SELECT DISTINCT
    name 
FROM (
    (SELECT DISTINCT store_city AS name FROM mock_data WHERE store_city IS NOT NULL)
    UNION
    (SELECT DISTINCT supplier_city AS name FROM mock_data WHERE supplier_city IS NOT NULL)
) AS tbl;

INSERT INTO snowflake.dim_customers (customer_id, first_name, last_name, email, age, country_id, postal_code, pet_id)
SELECT DISTINCT  -- DISTINCT перенесён сразу после SELECT
    m.sale_customer_id + FLOOR((m.id - 1) / 1000) * 1000,
    m.customer_first_name,
    m.customer_last_name,
    m.customer_email,
    m.customer_age,
    cntr.country_id,
    m.customer_postal_code,
    m.sale_customer_id + FLOOR((m.id - 1) / 1000) * 1000
FROM
    mock_data m
LEFT JOIN snowflake.dim_countries cntr ON cntr.name = m.customer_country
WHERE m.sale_customer_id IS NOT NULL;

INSERT INTO snowflake.dim_sellers (seller_id, first_name, last_name, email, country_id, postal_code)
SELECT 
    DISTINCT m.sale_seller_id + FLOOR((m.id - 1) / 1000) * 1000,
    m.seller_first_name,
    m.seller_last_name,
    m.seller_email,
    cntr.country_id,
    m.seller_postal_code
FROM
    mock_data m
LEFT JOIN snowflake.dim_countries cntr ON cntr.name = m.seller_country
WHERE m.sale_seller_id IS NOT NULL;

INSERT INTO snowflake.dim_stores (name, location, country_id, state_id, city_id, phone, email)
SELECT 
    DISTINCT m.store_name,
    m.store_location,
    cntr.country_id,
    st.state_id,
    c.city_id,
    m.store_phone,
    m.store_email
FROM 
    mock_data AS m
LEFT JOIN snowflake.dim_countries cntr ON cntr.name = m.store_country
LEFT JOIN snowflake.dim_states st ON st.name = m.store_state
LEFT JOIN snowflake.dim_cities c ON c.name = m.store_city
WHERE m.store_name IS NOT NULL;

INSERT INTO snowflake.dim_product_categories (name)
SELECT product_category FROM mock_data WHERE product_category IS NOT NULL;

INSERT INTO snowflake.dim_pet_categories (name)
SELECT m.pet_category 
FROM mock_data AS m
WHERE m.pet_category IS NOT NULL;

INSERT INTO snowflake.dim_suppliers (name, contact, email, phone, address, city_id, country_id)
SELECT 
    DISTINCT
    m.supplier_name,
    m.supplier_contact,
    m.supplier_email,
    m.supplier_phone,
    m.supplier_address,
    ct.city_id,
    cntr.country_id
FROM mock_data AS m
LEFT JOIN snowflake.dim_cities ct ON ct.name = m.supplier_city
LEFT JOIN snowflake.dim_countries cntr ON cntr.name = m.supplier_country
WHERE m.supplier_name IS NOT NULL;

INSERT INTO snowflake.dim_colors (name)
SELECT DISTINCT m.product_color
FROM mock_data AS m WHERE m.product_color IS NOT NULL;

INSERT INTO snowflake.dim_brands (name)
SELECT DISTINCT m.product_brand
FROM mock_data AS m WHERE m.product_brand IS NOT NULL;

INSERT INTO snowflake.dim_materials (name)
SELECT DISTINCT m.product_material
FROM mock_data AS m WHERE m.product_material IS NOT NULL;

WITH prepared_data AS (
    SELECT 
        m.sale_product_id + FLOOR((m.id - 1) / 1000) * 1000 AS product_id,
        m.product_name,
        m.product_price,
        m.product_weight,
        m.product_size,
        m.product_description,
        m.product_rating,
        m.product_reviews,
        m.product_release_date,
        m.product_expiry_date,
        m.supplier_email,
        m.pet_category,
        m.product_category,
        m.product_color,
        m.product_material,
        b.brand_id
    FROM mock_data m
    LEFT JOIN snowflake.dim_brands b ON b.name = m.product_brand
    WHERE m.sale_product_id IS NOT NULL
)
INSERT INTO snowflake.dim_products (
    product_id, name, pet_category_id, category_id, price, weight, 
    color_id, size, brand_id, material_id, description, 
    rating, reviews, release_date, expiry_date, supplier_id
)
SELECT DISTINCT
    pd.product_id,
    pd.product_name,
    (SELECT pc.pet_category_id FROM snowflake.dim_pet_categories pc WHERE pc.name = pd.pet_category LIMIT 1),
    (SELECT cat.category_id FROM snowflake.dim_product_categories cat WHERE cat.name = pd.product_category LIMIT 1),
    pd.product_price,
    pd.product_weight,
    (SELECT col.color_id FROM snowflake.dim_colors col WHERE col.name = pd.product_color LIMIT 1),
    pd.product_size,
    pd.brand_id,
    (SELECT mat.material_id FROM snowflake.dim_materials mat WHERE mat.name = pd.product_material LIMIT 1),
    pd.product_description,
    pd.product_rating,
    pd.product_reviews,
    CASE WHEN pd.product_release_date ~ '^\d{1,2}/\d{1,2}/\d{4}$' 
         THEN to_date(pd.product_release_date, 'FMMM/FMDD/YYYY') 
         ELSE NULL END,
    CASE WHEN pd.product_expiry_date ~ '^\d{1,2}/\d{1,2}/\d{4}$' 
         THEN to_date(pd.product_expiry_date, 'FMMM/FMDD/YYYY') 
         ELSE NULL END,
    (SELECT sup.supplier_id FROM snowflake.dim_suppliers sup WHERE sup.email = pd.supplier_email LIMIT 1)
FROM prepared_data pd;

INSERT INTO snowflake.fact_sales (customer_id, seller_id, product_id, store_id, quantity, total_price, date)
SELECT
    m.sale_customer_id + FLOOR((m.id - 1) / 1000) * 1000,
    m.sale_seller_id + FLOOR((m.id - 1) / 1000) * 1000,
    m.sale_product_id + FLOOR((m.id - 1) / 1000) * 1000,
    st.store_id,
    m.sale_quantity,
    m.sale_total_price,
    CASE WHEN m.sale_date ~ '^\d{1,2}/\d{1,2}/\d{4}$' 
         THEN to_date(m.sale_date, 'FMMM/FMDD/YYYY') 
         ELSE NULL END
FROM
    mock_data m
LEFT JOIN snowflake.dim_stores st ON st.email = m.store_email;
