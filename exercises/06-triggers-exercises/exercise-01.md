# Bài tập 1: Triggers và Tự động hóa

## Mục tiêu

- Tạo và quản lý các loại triggers khác nhau
- Xử lý sự kiện INSERT, UPDATE, DELETE
- Sử dụng triggers để đảm bảo tính toàn vẹn dữ liệu
- Tối ưu hiệu năng của triggers

## Yêu cầu

### Phần 1: DML Triggers

1. Tạo trigger kiểm soát tồn kho:

```sql
-- Yêu cầu:
-- - Kiểm tra số lượng tồn kho khi có đơn hàng mới
-- - Tự động đặt hàng khi tồn kho dưới mức tối thiểu
-- - Gửi cảnh báo cho admin
CREATE TRIGGER trg_check_inventory
ON order_details
AFTER INSERT, UPDATE
```

2. Tạo trigger audit log:

```sql
-- Yêu cầu:
-- - Log lại mọi thay đổi trong bảng products
-- - Lưu giá trị cũ và mới
-- - Lưu thông tin người thực hiện
CREATE TRIGGER trg_product_audit
ON products
AFTER INSERT, UPDATE, DELETE
```

### Phần 2: DDL Triggers

3. Theo dõi thay đổi schema:

```sql
-- Yêu cầu:
-- - Theo dõi các thay đổi schema (CREATE, ALTER, DROP)
-- - Lưu lịch sử thay đổi
-- - Giới hạn thời gian thực hiện thay đổi
CREATE TRIGGER trg_track_schema_changes
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
```

4. Kiểm soát naming convention:

```sql
-- Yêu cầu:
-- - Đảm bảo tên bảng tuân theo quy ước
-- - Đảm bảo tên cột tuân theo quy ước
-- - Từ chối các tên không hợp lệ
CREATE TRIGGER trg_naming_convention
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE
```

### Phần 3: Instead Of Triggers

5. Virtual delete:

```sql
-- Yêu cầu:
-- - Không xóa dữ liệu thật sự
-- - Đánh dấu record là đã xóa
-- - Lưu thông tin xóa
CREATE TRIGGER trg_virtual_delete
ON products
INSTEAD OF DELETE
```

6. Data validation và transformation:

```sql
-- Yêu cầu:
-- - Validate dữ liệu trước khi insert
-- - Tự động chuyển đổi định dạng
-- - Từ chối dữ liệu không hợp lệ
CREATE TRIGGER trg_validate_product
ON products
INSTEAD OF INSERT
```

### Phần 4: Xử lý đồng thời

7. Triggers với AFTER và INSTEAD OF:
   - Xử lý các vấn đề về thứ tự thực thi
   - Tránh triggers gọi lẫn nhau
   - Xử lý deadlocks

8. Nested triggers:
   - Hiểu và kiểm soát RECURSIVE_TRIGGERS
   - Giới hạn độ sâu của nested triggers
   - Tránh vòng lặp vô tận

## Gợi ý

1. Sử dụng inserted và deleted tables
2. Xử lý các trường hợp NULL
3. Giới hạn số lượng thao tác trong trigger
4. Log đầy đủ để debug

## Yêu cầu nâng cao

- Kiểm soát hiệu năng của triggers
- Xử lý các trường hợp đặc biệt
- Viết unit test cho triggers
- Triển khai trong môi trường production

## Tham khảo: [solution-01.md](solution-01.md)
