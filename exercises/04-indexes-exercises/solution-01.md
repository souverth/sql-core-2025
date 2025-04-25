# Lời giải Bài tập 1: Thiết kế và Tối ưu Index

## Phần 1: Phân tích Index hiện tại

### 1. Kiểm tra index hiện có

```sql
-- Liệt kê tất cả index
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) as schema_name,
    OBJECT_NAME(i.object_id) as table_name,
    i.name as index_name,
    i.type_desc,
    i.is_primary_key,
    i.is_unique
FROM sys.indexes i
WHERE i.object_id > 100;

-- Phân tích mức độ sử dụng
SELECT
    OBJECT_NAME(i.object_id) as table_name,
    i.name as index_name,
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates,
    ius.last_user_seek,
    ius.last_user_scan
FROM
    sys.dm_db_index_usage_stats ius
    JOIN sys.indexes i ON ius.object_id = i.object_id
        AND ius.index_id = i.index_id
WHERE
    database_id = DB_ID();

-- Kiểm tra phân mảnh
SELECT
    OBJECT_NAME(ips.object_id) as table_name,
    i.name as index_name,
    ips.index_type_desc,
    ips.avg_fragmentation_in_percent,
    ips.page_count
FROM
    sys.dm_db_index_physical_stats(
        DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
    JOIN sys.indexes i ON ips.object_id = i.object_id
        AND ips.index_id = i.index_id
WHERE
    ips.avg_fragmentation_in_percent > 30;
```

## Phần 2: Tạo Index mới

### 2. Các loại index khác nhau

```sql
-- Index đơn với INCLUDE
CREATE INDEX idx_product_name
ON products(product_name)
INCLUDE (price, category_id)
WITH (FILLFACTOR = 90);

-- Index kết hợp với nhiều cột
CREATE INDEX idx_order_customer_date
ON orders(customer_id, order_date, status)
INCLUDE (total_amount);

-- Filtered index cho sản phẩm active
CREATE INDEX idx_active_products
ON products(product_name, price)
WHERE status = 'active'
WITH (PAD_INDEX = ON);
```

### 3. Đề xuất index cho các truy vấn

```sql
-- Query 1: Index cho tìm kiếm theo ngày
CREATE INDEX idx_order_date
ON orders(order_date)
INCLUDE (customer_id, status, total_amount);

-- Query 2: Index hỗ trợ GROUP BY
CREATE INDEX idx_order_customer_status
ON orders(customer_id, status);

-- Query 3: Index cho tìm kiếm sản phẩm
CREATE INDEX idx_product_category_price
ON products(category_id, price)
INCLUDE (product_name, description);
```

## Phần 3: Phân tích Query Plan

### 4. So sánh execution plan

```sql
-- Bật hiển thị execution plan
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- Trước khi tạo index
SELECT *
FROM orders
WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';
-- Kết quả: Table Scan, reads = 1000

-- Sau khi tạo index
CREATE INDEX idx_order_date ON orders(order_date);

SELECT *
FROM orders
WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';
-- Kết quả: Index Seek, reads = 100
```

### Phân tích hiệu năng

1. Cost comparison:
   - Table scan: 100% cost
   - Index seek + key lookup: 25% cost
   - Index seek (covering): 10% cost

2. IO Statistics:
   - Giảm số lượng logical reads
   - Giảm số lượng physical reads
   - Tăng hiệu quả buffer cache

## Phần 4: Bảo trì Index

### 5. Tác vụ bảo trì

```sql
-- Rebuild index bị phân mảnh
ALTER INDEX ALL ON products
REBUILD WITH (
    ONLINE = ON,
    SORT_IN_TEMPDB = ON,
    FILLFACTOR = 90
);

-- Reorganize index ít phân mảnh hơn
ALTER INDEX ALL ON products
REORGANIZE;

-- Cập nhật statistics
UPDATE STATISTICS products
WITH FULLSCAN;

-- Xóa index không sử dụng
DROP INDEX idx_unused ON products;

-- Script theo dõi hiệu năng
CREATE TABLE index_stats_log (
    log_id INT IDENTITY(1,1) PRIMARY KEY,
    index_name NVARCHAR(128),
    table_name NVARCHAR(128),
    user_seeks BIGINT,
    user_scans BIGINT,
    user_lookups BIGINT,
    user_updates BIGINT,
    log_date DATETIME DEFAULT GETDATE()
);

-- Lưu thống kê định kỳ
INSERT INTO index_stats_log (
    index_name, table_name,
    user_seeks, user_scans, user_lookups, user_updates
)
SELECT
    i.name,
    OBJECT_NAME(i.object_id),
    ius.user_seeks,
    ius.user_scans,
    ius.user_lookups,
    ius.user_updates
FROM
    sys.dm_db_index_usage_stats ius
    JOIN sys.indexes i ON ius.object_id = i.object_id
        AND ius.index_id = i.index_id
WHERE
    database_id = DB_ID();
```

## Best Practices và Tối ưu hóa

### 1. Chiến lược Index

- Ưu tiên covering index cho các truy vấn thường xuyên
- Sử dụng filtered index cho dữ liệu có tính chọn lọc cao
- Cân bằng giữa hiệu năng SELECT và overhead của INSERT/UPDATE

### 2. Bảo trì Index

- Lập lịch rebuild/reorganize định kỳ
- Theo dõi fragmentation level
- Cập nhật statistics thường xuyên

### 3. Monitoring

- Theo dõi index usage
- Phân tích missing index suggestions
- Đánh giá tác động của index mới

### 4. Kích thước và Hiệu năng

- Giới hạn số lượng index trên mỗi bảng
- Tránh duplicate index
- Xem xét trade-off giữa storage và performance
