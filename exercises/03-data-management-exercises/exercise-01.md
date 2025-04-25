# Bài tập 1: Thao tác với dữ liệu và Quản lý bảng

## Mục tiêu

- Thực hành các lệnh INSERT, UPDATE, DELETE
- Sử dụng MERGE statement
- Quản lý ràng buộc và khóa ngoại
- Thao tác với bảng tạm và transaction

## Yêu cầu

### Phần 1: Thao tác với dữ liệu

1. Tạo bảng và thêm dữ liệu:
   - Tạo bảng `product_inventory` để theo dõi kho hàng
   - Thêm các cột: id, product_id, warehouse_id, quantity, min_quantity, last_restock_date
   - Thêm dữ liệu mẫu sử dụng nhiều cách khác nhau

2. Cập nhật dữ liệu với điều kiện:
   - Tăng giá 10% cho các sản phẩm có doanh số cao (>1000)
   - Giảm giá 20% cho các sản phẩm tồn kho > 3 tháng
   - Cập nhật trạng thái đơn hàng dựa theo ngày giao hàng

3. Xóa dữ liệu có ràng buộc:
   - Xóa các sản phẩm không còn hàng
   - Xóa các đơn hàng cũ hơn 1 năm
   - Đảm bảo toàn vẹn dữ liệu khi xóa

### Phần 2: Sử dụng MERGE

4. Đồng bộ dữ liệu giữa hai bảng:

```sql
-- Tạo bảng staging
CREATE TABLE product_price_staging (
    product_id INT,
    new_price DECIMAL(10,2),
    update_date DATE
);

-- Yêu cầu: Viết MERGE statement để:
-- - Cập nhật giá nếu sản phẩm tồn tại
-- - Thêm sản phẩm mới nếu chưa tồn tại
-- - Log lại các thay đổi
```

### Phần 3: Quản lý Transaction

5. Xử lý transaction phức tạp:
   - Tạo đơn hàng mới
   - Cập nhật số lượng tồn kho
   - Tính điểm thưởng cho khách hàng
   - Xử lý lỗi và rollback khi cần

### Phần 4: Temporary Tables

6. Sử dụng bảng tạm để:
   - Tính toán khuyến mãi cho từng sản phẩm
   - Phân tích doanh số theo nhiều chiều
   - So sánh hiệu năng giữa bảng tạm và CTE

## Gợi ý

1. Sử dụng transaction để đảm bảo tính toàn vẹn
2. Tạo trigger để log các thay đổi
3. Xử lý các trường hợp NULL và ngoại lệ
4. Sử dụng bảng tạm khi cần xử lý dữ liệu trung gian

## Yêu cầu nâng cao

- Xử lý lỗi một cách chi tiết
- Tối ưu hiệu năng các câu lệnh
- So sánh hiệu năng các phương pháp khác nhau
- Viết stored procedure để đóng gói logic

## Tham khảo: [solution-01.md](solution-01.md)
