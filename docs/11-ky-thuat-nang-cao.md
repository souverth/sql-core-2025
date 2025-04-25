# Kỹ thuật Nâng cao trong SQL

## 1. Số Tự Động Tăng (Auto Increment)

### 1.1 Identity trong SQL Server

```sql
-- Tạo bảng với identity
CREATE TABLE products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100)
);

-- Kiểm tra giá trị identity tiếp theo
SELECT IDENT_CURRENT('products');

-- Bật/tắt identity insert
SET IDENTITY_INSERT products ON;
INSERT INTO products (product_id, name) VALUES (100, 'Test');
SET IDENTITY_INSERT products OFF;

-- Reset identity
DBCC CHECKIDENT ('products', RESEED, 0);
```

### 1.2 Auto Increment trong MySQL

```sql
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);

-- Thiết lập giá trị auto increment
ALTER TABLE products AUTO_INCREMENT = 1000;

-- Lấy last insert id
SELECT LAST_INSERT_ID();
```

### 1.3 Sequences trong PostgreSQL

```sql
-- Tạo sequence
CREATE SEQUENCE product_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Sử dụng sequence
CREATE TABLE products (
    product_id INT DEFAULT nextval('product_seq') PRIMARY KEY,
    name VARCHAR(100)
);

-- Lấy giá trị tiếp theo
SELECT nextval('product_seq');

-- Reset sequence
ALTER SEQUENCE product_seq RESTART WITH 1;
```

## 2. Bảng Tạm (Temporary Tables)

### 2.1 Local Temporary Tables

```sql
-- Tạo bảng tạm local (#)
CREATE TABLE #temp_orders (
    order_id INT,
    total_amount DECIMAL(10,2)
);

-- Insert dữ liệu
INSERT INTO #temp_orders
SELECT order_id, SUM(quantity * price)
FROM order_details
GROUP BY order_id;

-- Sử dụng bảng tạm
SELECT o.*, t.total_amount
FROM orders o
JOIN #temp_orders t ON o.order_id = t.order_id;

-- Bảng tự động xóa khi kết thúc session
```

### 2.2 Global Temporary Tables

```sql
-- Tạo bảng tạm global (##)
CREATE TABLE ##temp_products (
    product_id INT,
    inventory_count INT
);

-- Có thể truy cập từ nhiều sessions
INSERT INTO ##temp_products
SELECT product_id, COUNT(*)
FROM inventory
GROUP BY product_id;

-- Tồn tại cho đến khi tất cả sessions ngừng sử dụng
```

### 2.3 Table Variables

```sql
-- Khai báo table variable
DECLARE @OrderItems TABLE (
    item_id INT,
    quantity INT
);

-- Sử dụng trong stored procedure
INSERT INTO @OrderItems
SELECT item_id, quantity
FROM order_details
WHERE order_id = @order_id;

-- Phạm vi chỉ trong batch/procedure
```

### 2.4 Memory-Optimized Table Variables

```sql
-- SQL Server 2014+
DECLARE @OrderDetails TABLE (
    detail_id INT,
    order_id INT,
    product_id INT,
    quantity INT,
    INDEX idx_order NONCLUSTERED (order_id)
)
WITH (MEMORY_OPTIMIZED = ON);
```

## 3. Common Table Expressions (CTE)

### 3.1 Basic CTE

```sql
WITH OrderSummary AS (
    SELECT
        customer_id,
        COUNT(*) as total_orders,
        SUM(amount) as total_amount
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.customer_name,
    os.total_orders,
    os.total_amount
FROM customers c
JOIN OrderSummary os ON c.customer_id = os.customer_id;
```

### 3.2 Recursive CTE

```sql
WITH RECURSIVE EmployeeHierarchy AS (
    -- Anchor member
    SELECT
        employee_id,
        manager_id,
        first_name,
        0 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive member
    SELECT
        e.employee_id,
        e.manager_id,
        e.first_name,
        eh.level + 1
    FROM employees e
    INNER JOIN EmployeeHierarchy eh
        ON e.manager_id = eh.employee_id
)
SELECT * FROM EmployeeHierarchy;
```

## 4. Dynamic SQL

### 4.1 Basic Dynamic SQL

```sql
-- Tạo và thực thi dynamic SQL
DECLARE @sql NVARCHAR(MAX);
DECLARE @table_name NVARCHAR(128) = 'products';
DECLARE @column_name NVARCHAR(128) = 'product_name';

SET @sql = 'SELECT ' + @column_name +
           ' FROM ' + @table_name +
           ' WHERE price > 100';

EXEC sp_executesql @sql;
```

### 4.2 Parameterized Dynamic SQL

```sql
DECLARE @sql NVARCHAR(MAX);
DECLARE @params NVARCHAR(MAX);
DECLARE @min_price DECIMAL(10,2) = 100.00;

SET @sql = N'SELECT product_name, price
            FROM products
            WHERE price > @price';

SET @params = N'@price decimal(10,2)';

EXEC sp_executesql
    @sql,
    @params,
    @price = @min_price;
```

### 4.3 Dynamic Pivot

```sql
-- Tạo pivot table động
DECLARE @columns NVARCHAR(MAX);
DECLARE @sql NVARCHAR(MAX);

-- Tạo danh sách columns
SELECT @columns = STRING_AGG(QUOTENAME(year), ',')
FROM (SELECT DISTINCT YEAR(order_date) as year
      FROM orders) AS years;

SET @sql =
    N'SELECT product_name, ' + @columns + '
    FROM (
        SELECT
            p.product_name,
            YEAR(o.order_date) as year,
            od.quantity
        FROM products p
        JOIN order_details od ON p.product_id = od.product_id
        JOIN orders o ON od.order_id = o.order_id
    ) AS source
    PIVOT (
        SUM(quantity)
        FOR year IN (' + @columns + ')
    ) AS pvt';

EXEC sp_executesql @sql;
```

## 5. Bulk Operations

### 5.1 Bulk Insert

```sql
-- Bulk insert từ file
BULK INSERT target_table
FROM 'C:\data.csv'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

-- Sử dụng OPENROWSET
INSERT INTO target_table
SELECT *
FROM OPENROWSET(
    BULK 'C:\data.csv',
    FORMATFILE = 'C:\format.fmt'
) AS a;
```

### 5.2 Table Value Constructor

```sql
-- Insert nhiều rows
INSERT INTO products (name, price)
VALUES
    ('Product 1', 10.00),
    ('Product 2', 20.00),
    ('Product 3', 30.00);

-- Merge với values
MERGE INTO products AS target
USING (VALUES
    (1, 'Product 1', 10.00),
    (2, 'Product 2', 20.00)
) AS source (id, name, price)
ON target.id = source.id
WHEN MATCHED THEN
    UPDATE SET name = source.name, price = source.price
WHEN NOT MATCHED THEN
    INSERT (id, name, price)
    VALUES (source.id, source.name, source.price);
```

## 6. Window Functions Nâng cao

### 6.1 Rolling Calculations

```sql
-- Tính toán rolling average
SELECT
    order_date,
    amount,
    AVG(amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
    ) as rolling_avg
FROM orders;

-- Cumulative sum
SELECT
    order_date,
    amount,
    SUM(amount) OVER (
        ORDER BY order_date
        ROWS UNBOUNDED PRECEDING
    ) as running_total
FROM orders;
```

### 6.2 Percentiles

```sql
-- Calculate percentile ranks
SELECT
    product_name,
    price,
    PERCENT_RANK() OVER (ORDER BY price) as price_percentile,
    NTILE(4) OVER (ORDER BY price) as price_quartile
FROM products;

-- First/last value in group
SELECT
    category_name,
    product_name,
    price,
    FIRST_VALUE(price) OVER (
        PARTITION BY category_name
        ORDER BY price DESC
    ) as highest_in_category
FROM products p
JOIN categories c ON p.category_id = c.category_id;
```

## 7. JSON Operations

### 7.1 JSON trong SQL Server

```sql
-- Tạo và lưu JSON
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    details NVARCHAR(MAX)
    CHECK (ISJSON(details) = 1)
);

-- Insert JSON data
INSERT INTO products VALUES
(1, '{"name": "Product 1", "specs": {"color": "red", "size": "L"}}');

-- Query JSON
SELECT
    product_id,
    JSON_VALUE(details, '$.name') as name,
    JSON_VALUE(details, '$.specs.color') as color
FROM products;

-- Modify JSON
UPDATE products
SET details = JSON_MODIFY(
    details,
    '$.specs.color',
    'blue'
)
WHERE product_id = 1;
```

### 7.2 JSON trong PostgreSQL

```sql
-- JSON columns
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    details JSONB
);

-- Query JSON
SELECT
    product_id,
    details->>'name' as name,
    details->'specs'->>'color' as color
FROM products;

-- JSON operators
SELECT *
FROM products
WHERE details @> '{"specs": {"color": "red"}}';
