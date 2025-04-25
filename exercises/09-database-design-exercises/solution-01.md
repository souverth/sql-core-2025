# Lời giải Bài tập 1: Database Design và Normalization

## Phần 1: Database Design

### 1. E-commerce Database Schema

#### Core Entities

```sql
-- Customers
CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(50) NOT NULL,
    last_name NVARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME DEFAULT GETDATE()
);

-- Categories (Recursive relationship)
CREATE TABLE categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    description NTEXT,
    parent_category_id INT,
    status VARCHAR(20) DEFAULT 'active',
    FOREIGN KEY (parent_category_id)
        REFERENCES categories(category_id)
);

-- Products
CREATE TABLE products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(200) NOT NULL,
    description NTEXT,
    base_price DECIMAL(10,2) NOT NULL,
    current_price DECIMAL(10,2) NOT NULL,
    category_id INT,
    stock_quantity INT DEFAULT 0,
    min_stock_level INT DEFAULT 10,
    status VARCHAR(20) DEFAULT 'active',
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
);

-- Orders
CREATE TABLE orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATETIME DEFAULT GETDATE(),
    status VARCHAR(20) DEFAULT 'pending',
    total_amount DECIMAL(10,2),
    shipping_address_id INT,
    payment_id INT,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),
    FOREIGN KEY (shipping_address_id)
        REFERENCES addresses(address_id),
    FOREIGN KEY (payment_id)
        REFERENCES payments(payment_id)
);
```

#### Supporting Entities

```sql
-- Addresses
CREATE TABLE addresses (
    address_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    address_type VARCHAR(20),
    street_address NVARCHAR(200),
    city NVARCHAR(100),
    state NVARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100),
    is_default BIT DEFAULT 0,
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-- Order Details (Many-to-Many with additional attributes)
CREATE TABLE order_details (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_amount DECIMAL(10,2) DEFAULT 0,
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);

-- Payments
CREATE TABLE payments (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    payment_date DATETIME DEFAULT GETDATE(),
    payment_method VARCHAR(50),
    amount DECIMAL(10,2) NOT NULL,
    status VARCHAR(20),
    transaction_id VARCHAR(100),
    FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
);

-- Reviews
CREATE TABLE reviews (
    review_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    customer_id INT NOT NULL,
    rating TINYINT CHECK (rating BETWEEN 1 AND 5),
    comment NTEXT,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);
```

#### Inventory Management

```sql
-- Warehouses
CREATE TABLE warehouses (
    warehouse_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    location NVARCHAR(200),
    status VARCHAR(20) DEFAULT 'active'
);

-- Inventory
CREATE TABLE inventory (
    inventory_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id)
        REFERENCES warehouses(warehouse_id)
);
```

#### Promotions

```sql
-- Promotions
CREATE TABLE promotions (
    promotion_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    description NTEXT,
    discount_type VARCHAR(20),
    discount_value DECIMAL(10,2),
    start_date DATETIME,
    end_date DATETIME,
    status VARCHAR(20) DEFAULT 'active'
);

-- Product Promotions (Many-to-Many)
CREATE TABLE product_promotions (
    product_id INT,
    promotion_id INT,
    PRIMARY KEY (product_id, promotion_id),
    FOREIGN KEY (product_id)
        REFERENCES products(product_id),
    FOREIGN KEY (promotion_id)
        REFERENCES promotions(promotion_id)
);
```

## Phần 2: Data Dictionary

### Core Tables

#### Customers

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| customer_id | INT | Unique identifier | PK, Identity |
| first_name | NVARCHAR(50) | First name | NOT NULL |
| last_name | NVARCHAR(50) | Last name | NOT NULL |
| email | VARCHAR(100) | Email address | UNIQUE, NOT NULL |

#### Products

| Column | Type | Description | Constraints |
|--------|------|-------------|-------------|
| product_id | INT | Unique identifier | PK, Identity |
| name | NVARCHAR(200) | Product name | NOT NULL |
| base_price | DECIMAL(10,2) | Original price | NOT NULL |
| current_price | DECIMAL(10,2) | Current selling price | NOT NULL |

## Phần 3: Indexes và Optimizations

### Performance Indexes

```sql
-- Products
CREATE INDEX idx_product_category
ON products(category_id, status);

CREATE INDEX idx_product_price
ON products(current_price)
INCLUDE (name, stock_quantity);

-- Orders
CREATE INDEX idx_order_customer
ON orders(customer_id, order_date);

CREATE INDEX idx_order_status
ON orders(status, order_date);

-- Inventory
CREATE INDEX idx_inventory_product
ON inventory(product_id, warehouse_id);
```

### Computed Columns và Indexes

```sql
-- Add computed columns
ALTER TABLE products
ADD stock_status AS
    CASE
        WHEN stock_quantity <= min_stock_level THEN 'Low'
        WHEN stock_quantity = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END PERSISTED;

CREATE INDEX idx_product_stock_status
ON products(stock_status);
```

## Phần 4: Business Rules và Constraints

### Check Constraints

```sql
-- Price validation
ALTER TABLE products
ADD CONSTRAINT CHK_Product_Price
CHECK (current_price >= 0 AND base_price >= 0);

-- Order status
ALTER TABLE orders
ADD CONSTRAINT CHK_Order_Status
CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled'));

-- Inventory quantity
ALTER TABLE inventory
ADD CONSTRAINT CHK_Inventory_Quantity
CHECK (quantity >= 0);
```

### Trigger Examples

```sql
-- Audit price changes
CREATE TRIGGER trg_product_price_audit
ON products
AFTER UPDATE
AS
BEGIN
    IF UPDATE(current_price)
    BEGIN
        INSERT INTO price_history (
            product_id,
            old_price,
            new_price,
            change_date
        )
        SELECT
            i.product_id,
            d.current_price,
            i.current_price,
            GETDATE()
        FROM
            inserted i
            JOIN deleted d ON i.product_id = d.product_id
        WHERE
            i.current_price <> d.current_price;
    END;
END;
```

## Best Practices

### Schema Design

1. Use appropriate data types
2. Implement constraints properly
3. Follow naming conventions
4. Plan for scalability

### Indexing Strategy

1. Index foreign keys
2. Create covering indexes
3. Consider filtered indexes
4. Monitor index usage
