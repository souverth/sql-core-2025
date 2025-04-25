# Tips và Best Practices trong SQL

## 1. Tổ chức và Quản lý Code

### 1.1 Coding Standards

#### Quy ước đặt tên

- Sử dụng tiền tố cho các object types (tbl_, vw_, sp_, etc.)
- Tên rõ ràng và có ý nghĩa
- Nhất quán trong cách đặt tên
- Tránh viết tắt không chuẩn

```sql
-- Tốt
CREATE TABLE tbl_customer_orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE
);

-- Không tốt
CREATE TABLE ord (
    id INT PRIMARY KEY,
    cust INT,
    dt DATE
);
```

#### Code Format

- Thụt lề nhất quán
- Căn chỉnh các mệnh đề
- Xuống dòng hợp lý
- Comment đầy đủ

```sql
-- Tốt
SELECT
    c.customer_name,
    o.order_date,
    p.product_name,
    od.quantity
FROM
    customers c
    INNER JOIN orders o
        ON c.customer_id = o.customer_id
    INNER JOIN order_details od
        ON o.order_id = od.order_id
    INNER JOIN products p
        ON od.product_id = p.product_id
WHERE
    o.order_date >= '2025-01-01'
    AND o.status = 'completed'
ORDER BY
    o.order_date DESC;
```

### 1.2 Source Control

#### Version Control

- Sử dụng Git hoặc SVN
- Commit thường xuyên
- Comment rõ ràng
- Branch strategy phù hợp

#### Migration Scripts

```sql
-- Up migration
CREATE PROCEDURE sp_migration_001_up
AS
BEGIN
    -- Thêm cột mới
    ALTER TABLE customers
    ADD email VARCHAR(100);

    -- Cập nhật dữ liệu
    UPDATE customers
    SET email = 'default@example.com';

    -- Thêm constraint
    ALTER TABLE customers
    ALTER COLUMN email VARCHAR(100) NOT NULL;
END;

-- Down migration
CREATE PROCEDURE sp_migration_001_down
AS
BEGIN
    ALTER TABLE customers
    DROP COLUMN email;
END;
```

## 2. Query Optimization

### 2.1 Index Usage

#### Sử dụng Index hiệu quả

```sql
-- Tốt (sử dụng index)
SELECT * FROM customers
WHERE email = 'test@example.com';

-- Không tốt (không sử dụng được index)
SELECT * FROM customers
WHERE LOWER(email) = 'test@example.com';
```

#### Tránh Index Scan

```sql
-- Tốt (Index Seek)
SELECT * FROM orders
WHERE order_date = '2025-01-01';

-- Không tốt (Index Scan)
SELECT * FROM orders
WHERE order_date + 1 = '2025-01-02';
```

### 2.2 Query Structure

#### Tránh SELECT *

```sql
-- Tốt
SELECT customer_id, name, email
FROM customers;

-- Không tốt
SELECT *
FROM customers;
```

#### Sử dụng JOIN thay vì Subquery

```sql
-- Tốt
SELECT c.name, o.order_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id;

-- Không tốt
SELECT name,
    (SELECT order_date
     FROM orders
     WHERE customer_id = customers.customer_id)
FROM customers;
```

### 2.3 Batch Processing

#### Xử lý dữ liệu lớn

```sql
-- Xử lý theo batch
WHILE EXISTS (SELECT 1 FROM large_table WHERE processed = 0)
BEGIN
    UPDATE TOP (1000) large_table
    SET processed = 1
    WHERE processed = 0;

    WAITFOR DELAY '00:00:01';
END;
```

## 3. Security Best Practices

### 3.1 Input Validation

#### Tham số hóa Queries

```sql
-- Tốt
CREATE PROCEDURE sp_get_customer
    @customer_id INT
AS
BEGIN
    SELECT * FROM customers
    WHERE customer_id = @customer_id;
END;

-- Không tốt (SQL Injection risk)
DECLARE @sql NVARCHAR(MAX) =
    'SELECT * FROM customers WHERE customer_id = ' + @customer_id;
EXEC(@sql);
```

#### Validate Input

```sql
CREATE PROCEDURE sp_update_price
    @product_id INT,
    @new_price DECIMAL(10,2)
AS
BEGIN
    IF @new_price <= 0
        THROW 50000, 'Price must be positive', 1;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = @product_id)
        THROW 50001, 'Product not found', 1;

    UPDATE products
    SET price = @new_price
    WHERE product_id = @product_id;
END;
```

### 3.2 Error Handling

#### Structured Error Handling

```sql
BEGIN TRY
    -- Code có thể gây lỗi
    UPDATE accounts
    SET balance = balance - @amount
    WHERE account_id = @from_account;

    IF @@ROWCOUNT = 0
        THROW 50000, 'Account not found', 1;

    IF (SELECT balance FROM accounts WHERE account_id = @from_account) < 0
        THROW 50001, 'Insufficient funds', 1;
END TRY
BEGIN CATCH
    -- Log lỗi
    INSERT INTO error_log (
        error_number,
        error_message,
        error_line,
        error_time
    )
    VALUES (
        ERROR_NUMBER(),
        ERROR_MESSAGE(),
        ERROR_LINE(),
        GETDATE()
    );

    -- Rollback transaction nếu cần
    IF @@TRANCOUNT > 0
        ROLLBACK;

    -- Ném lỗi lên tầng trên
    THROW;
END CATCH;
```

## 4. Performance Monitoring

### 4.1 Query Performance

#### Execution Plans

```sql
-- Analyze query plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
GO

-- Query cần analyze
SELECT /*+ MONITOR */
    *
FROM large_table
WHERE complex_condition;
GO

-- Xem kết quả
SELECT *
FROM sys.dm_exec_query_stats
CROSS APPLY sys.dm_exec_sql_text(sql_handle);
```

#### Index Usage Statistics

```sql
SELECT
    OBJECT_NAME(i.object_id) as table_name,
    i.name as index_name,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM
    sys.dm_db_index_usage_stats ius
    INNER JOIN sys.indexes i
        ON ius.object_id = i.object_id
        AND ius.index_id = i.index_id
WHERE
    database_id = DB_ID();
```

### 4.2 Resource Usage

#### Memory Usage

```sql
SELECT
    (physical_memory_in_use_kb/1024) AS memory_use_MB,
    (locked_page_allocations_kb/1024) AS locked_pages_MB,
    (virtual_address_space_committed_kb/1024) AS virtual_memory_committed_MB
FROM sys.dm_os_process_memory;
```

#### CPU Usage

```sql
SELECT
    session_id,
    request_id,
    cpu_time,
    total_elapsed_time,
    reads,
    writes
FROM sys.dm_exec_requests
WHERE session_id > 50;
```

## 5. Maintenance

### 5.1 Database Maintenance

#### Index Maintenance

```sql
-- Rebuild tất cả indexes
ALTER INDEX ALL ON table_name
REBUILD WITH (
    ONLINE = ON,
    SORT_IN_TEMPDB = ON
);

-- Reorganize và update statistics
ALTER INDEX ALL ON table_name
REORGANIZE;
GO
UPDATE STATISTICS table_name;
```

#### Database Backups

```sql
-- Full backup
BACKUP DATABASE database_name
TO DISK = 'path\backup.bak'
WITH INIT;

-- Differential backup
BACKUP DATABASE database_name
TO DISK = 'path\backup_diff.bak'
WITH DIFFERENTIAL;

-- Log backup
BACKUP LOG database_name
TO DISK = 'path\backup_log.bak';
```

### 5.2 Data Archiving

#### Archiving Strategy

```sql
-- Archive old data
INSERT INTO orders_archive
SELECT *
FROM orders
WHERE order_date < DATEADD(YEAR, -1, GETDATE());

-- Delete archived data
DELETE FROM orders
WHERE order_date < DATEADD(YEAR, -1, GETDATE());
```

## 6. Documentation

### 6.1 Code Documentation

```sql
-- =============================================
-- Author:      Developer Name
-- Create date: 2025-01-01
-- Description: This procedure processes orders
-- Parameters:
--   @customer_id - Customer identifier
--   @order_date - Date of the order
-- Returns: Order ID
-- =============================================
CREATE PROCEDURE sp_process_order
    @customer_id INT,
    @order_date DATE
AS
BEGIN
    -- Code implementation
END;
```

### 6.2 Database Documentation

- ERD diagrams
- Data dictionary
- Dependency mapping
- Deployment guides
- Disaster recovery plans
