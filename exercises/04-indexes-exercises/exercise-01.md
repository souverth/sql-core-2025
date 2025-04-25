# Bài tập 1: Thiết kế và Tối ưu Index

## Mục tiêu

- Hiểu cách hoạt động của các loại index
- Thực hành tạo và quản lý index
- Phân tích hiệu năng query với và không có index
- Tối ưu hóa truy vấn sử dụng index

## Yêu cầu

### Phần 1: Phân tích Index hiện tại

1. Kiểm tra các index hiện có:
   - Liệt kê tất cả index trong database
   - Phân tích mức độ sử dụng của từng index
   - Xác định index không được sử dụng
   - Kiểm tra index bị phân mảnh

### Phần 2: Tạo Index mới

2. Tạo các loại index khác nhau:

   ```sql
   -- Tạo index đơn
   CREATE INDEX idx_product_name
   ON products(product_name);

   -- Tạo index kết hợp
   CREATE INDEX idx_order_customer
   ON orders(customer_id, order_date);

   -- Tạo filtered index
   CREATE INDEX idx_active_products
   ON products(product_name)
   WHERE status = 'active';
   ```

3. Đề xuất và tạo index cho các truy vấn sau:

   ```sql
   -- Query 1: Tìm đơn hàng theo khoảng thời gian
   SELECT *
   FROM orders
   WHERE order_date BETWEEN '2025-01-01' AND '2025-01-31';

   -- Query 2: Thống kê đơn hàng theo khách hàng và trạng thái
   SELECT
       customer_id,
       status,
       COUNT(*) as order_count
   FROM orders
   GROUP BY customer_id, status;

   -- Query 3: Tìm sản phẩm theo giá và danh mục
   SELECT *
   FROM products
   WHERE category_id = 1
   AND price BETWEEN 100 AND 1000;
   ```

### Phần 3: Phân tích Query Plan

4. So sánh execution plan trước và sau khi tạo index:
   - Chụp execution plan của các query trước khi tạo index
   - Tạo index phù hợp
   - Chụp execution plan sau khi tạo index
   - Phân tích sự khác biệt về hiệu năng

### Phần 4: Bảo trì Index

5. Thực hiện các tác vụ bảo trì:
   - Rebuild index bị phân mảnh
   - Cập nhật statistics
   - Xóa index không sử dụng
   - Theo dõi hiệu năng index

## Gợi ý

1. Sử dụng sys.dm_db_index_usage_stats để theo dõi việc sử dụng index
2. Include các cột thường truy vấn trong index để tận dụng covering index
3. Cân nhắc trade-off giữa hiệu năng SELECT và INSERT/UPDATE
4. Sử dụng filtered index cho các truy vấn có điều kiện thường xuyên

## Yêu cầu nâng cao

- So sánh hiệu năng giữa các loại index khác nhau
- Phân tích tác động của index đến các thao tác INSERT/UPDATE/DELETE
- Tối ưu hóa kích thước và số lượng index
- Đề xuất chiến lược index cho ứng dụng thực tế

## Tham khảo: [solution-01.md](solution-01.md)
