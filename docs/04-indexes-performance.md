# Indexes và Performance trong SQL

## 1. Indexes

### 1.1 Khái niệm cơ bản về Index

Index là cấu trúc dữ liệu giúp tăng tốc độ truy vấn dữ liệu bằng cách tạo ra một bảng tra cứu (lookup table) cho các giá trị trong một hoặc nhiều cột.

#### Ưu điểm

- Tăng tốc độ truy vấn SELECT
- Tăng hiệu suất các mệnh đề WHERE và JOIN
- Đảm bảo tính duy nhất (với UNIQUE INDEX)

#### Nhược điểm

- Tốn không gian lưu trữ
- Chậm hơn khi INSERT, UPDATE, DELETE
- Chi phí bảo trì và cập nhật index

### 1.2 Các loại Index

#### B-tree Index

```sql
-- Index cơ bản
CREATE INDEX idx_name
ON table_name (column_name);

-- Index nhiều cột
CREATE INDEX idx_name
ON table_name (column1, column2);
```

#### Unique Index

```sql
CREATE UNIQUE INDEX idx_name
ON table_name (column_name);
```

#### Partial Index

```sql
-- Chỉ index các bản ghi thỏa điều kiện
CREATE INDEX idx_name
ON table_name (column_name)
WHERE condition;
```

#### Clustered Index

```sql
-- MySQL/SQL Server (tự động với PRIMARY KEY)
CREATE CLUSTERED INDEX idx_name
ON table_name (column_name);
```

#### Covering Index

```sql
-- Index bao gồm cả dữ liệu cần truy vấn
CREATE INDEX idx_name
ON table_name (search_column)
INCLUDE (retrieved_column);
```

### 1.3 Quản lý Index

#### Tạo Index

```sql
-- Tạo index đơn giản
CREATE INDEX idx_name
ON table_name (column_name);

-- Tạo index với các tùy chọn
CREATE INDEX idx_name
ON table_name (column_name)
[USING method]
[WITH options];
```

#### Xóa Index

```sql
DROP INDEX idx_name ON table_name;
```

#### Rebuild Index

```sql
-- SQL Server
ALTER INDEX idx_name
ON table_name REBUILD;

-- Oracle
ALTER INDEX idx_name REBUILD;
```

## 2. Query Optimization

### 2.1 Phân tích Query Plan

```sql
-- MySQL
EXPLAIN SELECT * FROM table_name WHERE condition;

-- PostgreSQL
EXPLAIN ANALYZE SELECT * FROM table_name WHERE condition;

-- SQL Server
SET SHOWPLAN_XML ON;
GO
SELECT * FROM table_name WHERE condition;
GO
```

### 2.2 Các kỹ thuật tối ưu

#### Sử dụng Index hiệu quả

```sql
-- Tốt
SELECT * FROM users WHERE email = 'test@example.com';

-- Không tốt (không sử dụng được index)
SELECT * FROM users WHERE LOWER(email) = 'test@example.com';
```

#### Tránh Select *

```sql
-- Tốt
SELECT id, name, email FROM users;

-- Không tốt
SELECT * FROM users;
```

#### Sử dụng EXISTS thay vì IN

```sql
-- Tốt
SELECT * FROM orders o
WHERE EXISTS (
    SELECT 1 FROM customers c
    WHERE c.id = o.customer_id
    AND c.status = 'active'
);

-- Không tốt
SELECT * FROM orders
WHERE customer_id IN (
    SELECT id FROM customers
    WHERE status = 'active'
);
```

### 2.3 Join Optimization

#### Chọn loại JOIN phù hợp

```sql
-- Sử dụng INNER JOIN khi cần dữ liệu khớp
SELECT * FROM orders o
INNER JOIN customers c ON o.customer_id = c.id;

-- Sử dụng LEFT JOIN khi cần giữ lại dữ liệu bên trái
SELECT * FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id;
```

#### Tối ưu điều kiện JOIN

```sql
-- Tốt (sử dụng index)
ON o.customer_id = c.id

-- Không tốt (không sử dụng được index)
ON LOWER(o.customer_code) = LOWER(c.code)
```

## 3. Statistics và Phân tích

### 3.1 Thu thập thống kê

```sql
-- MySQL
ANALYZE TABLE table_name;

-- PostgreSQL
ANALYZE table_name;

-- SQL Server
UPDATE STATISTICS table_name;
```

### 3.2 Monitoring Queries

```sql
-- MySQL
SHOW PROCESSLIST;

-- PostgreSQL
SELECT * FROM pg_stat_activity;

-- SQL Server
SELECT * FROM sys.dm_exec_requests;
```

## 4. Best Practices

### 4.1 Indexing Best Practices

- Index các cột thường xuất hiện trong WHERE, JOIN, ORDER BY
- Cân nhắc thứ tự các cột trong composite index
- Tránh index quá nhiều (overhead khi INSERT/UPDATE/DELETE)
- Định kỳ rebuild/reorganize index
- Xóa các index không sử dụng

### 4.2 Query Best Practices

- Sử dụng điều kiện có tính chọn lọc cao
- Tránh chuyển đổi kiểu dữ liệu trong điều kiện
- Sử dụng tham số hóa query
- Tránh correlated subqueries khi có thể
- Sử dụng phân trang thay vì lấy tất cả

### 4.3 Database Design Best Practices

- Thiết kế schema hợp lý
- Chuẩn hóa khi cần thiết
- Chọn kiểu dữ liệu phù hợp
- Đặt ràng buộc phù hợp
- Lập kế hoạch backup và maintenance

## 5. Monitoring và Maintenance

### 5.1 Theo dõi hiệu suất

```sql
-- Kiểm tra index usage
SELECT * FROM sys.dm_db_index_usage_stats;

-- Kiểm tra query chậm
SELECT * FROM mysql.slow_log;

-- Kiểm tra cache hit ratio
SELECT * FROM pg_statio_user_tables;
```

### 5.2 Bảo trì định kỳ

```sql
-- Cập nhật thống kê
UPDATE STATISTICS table_name;

-- Rebuild index
ALTER INDEX ALL ON table_name REBUILD;

-- Dọn dẹp không gian
VACUUM ANALYZE table_name;
```

### 5.3 Troubleshooting

- Kiểm tra execution plan
- Xác định bottlenecks
- Kiểm tra index usage
- Phân tích query patterns
- Tối ưu resource usage
