# Bài tập 1: Stored Procedures và Functions

## Mục tiêu
- Hiểu và thực hành tạo Stored Procedures
- Xử lý tham số và biến
- Sử dụng control flow
- Xử lý lỗi trong Stored Procedures
- Tối ưu hiệu năng

## Yêu cầu

### Phần 1: Stored Procedures cơ bản

1. Tạo stored procedure để thêm sản phẩm mới:
```sql
-- Yêu cầu:
-- - Kiểm tra tham số đầu vào hợp lệ
-- - Tự động sinh mã sản phẩm
-- - Log lại thao tác
CREATE PROCEDURE sp_add_product
    @product_name NVARCHAR(100),
    @price DECIMAL(10,2),
    @category_id INT
```

2. Tạo procedure xử lý đơn hàng:
```sql
-- Yêu cầu:
-- - Kiểm tra tồn kho
-- - Tính tổng tiền
-- - Cập nhật số lượng
-- - Xử lý transaction
CREATE PROCEDURE sp_process_order
    @customer_id INT,
    @order_items OrderItemType READONLY
```

### Phần 2: Functions

3. Tạo scalar function:
```sql
-- Tính giá sau khuyến mãi
CREATE FUNCTION fn_calculate_discount_price(
    @price DECIMAL(10,2),
    @discount_percent INT
)
RETURNS DECIMAL(10,2)
```

4. Tạo table-valued function:
```sql
-- Lấy lịch sử đơn hàng của khách hàng
CREATE FUNCTION fn_get_customer_orders(
    @customer_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
```

### Phần 3: Error Handling và Flow Control

5. Xử lý lỗi trong stored procedure:
```sql
-- Yêu cầu:
-- - Sử dụng TRY...CATCH
-- - Log lỗi chi tiết
-- - Rollback khi cần
-- - Throw custom error
CREATE PROCEDURE sp_transfer_money
    @from_account INT,
    @to_account INT,
    @amount DECIMAL(10,2)
```

6. Control flow nâng cao:
```sql
-- Yêu cầu:
-- - Xử lý theo trạng thái đơn hàng
-- - Gửi thông báo tương ứng
-- - Cập nhật dữ liệu liên quan
CREATE PROCEDURE sp_update_order_status
    @order_id INT,
    @new_status VARCHAR(20)
```

### Phần 4: Hiệu năng và Bảo mật

7. Tối ưu hiệu năng:
   - Sử dụng các tham số phù hợp
   - Xử lý dữ liệu theo batch
   - Tránh cursors khi có thể
   - Sử dụng temp tables khi cần

8. Bảo mật:
   - Phân quyền thích hợp
   - Validate input
   - Tránh SQL injection
   - Mã hóa dữ liệu nhạy cảm

## Gợi ý
1. Sử dụng table type để truyền nhiều dòng dữ liệu
2. Chia stored procedure lớn thành nhiều procedure nhỏ hơn
3. Sử dụng transactions cho các thao tác phức tạp
4. Log đầy đủ lỗi và thao tác quan trọng

## Yêu cầu nâng cao
- Xử lý concurrent access
- Tối ưu hiệu năng với dữ liệu lớn
- Viết unit test cho stored procedures
- Tạo deployment script

## Tham khảo: [solution-01.md](solution-01.md)
