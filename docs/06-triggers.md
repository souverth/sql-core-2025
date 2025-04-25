# Triggers trong SQL

## 1. Giới thiệu về Triggers

Trigger là một đối tượng cơ sở dữ liệu được thực thi tự động khi có sự kiện xảy ra (INSERT, UPDATE, DELETE) trên bảng hoặc view.

### 1.1 Đặc điểm của Triggers

- Tự động thực thi
- Không thể gọi trực tiếp
- Không nhận tham số
- Có thể truy cập dữ liệu trước và sau khi thay đổi
- Có thể hủy bỏ thao tác gây trigger

## 2. Các loại Trigger

### 2.1 DML Triggers (Data Manipulation Language)

#### AFTER/FOR Triggers

Thực thi sau khi thao tác DML hoàn thành.

```sql
-- SQL Server
CREATE TRIGGER trg_name
ON table_name
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Code xử lý
END;

-- MySQL
DELIMITER //
CREATE TRIGGER trg_name
AFTER INSERT ON table_name
FOR EACH ROW
BEGIN
    -- Code xử lý
END //
DELIMITER ;
```

#### INSTEAD OF Triggers

Thay thế thao tác DML bằng code tùy chỉnh (chỉ có trong SQL Server).

```sql
CREATE TRIGGER trg_name
ON table_name
INSTEAD OF INSERT
AS
BEGIN
    -- Code xử lý thay thế INSERT
END;
```

### 2.2 DDL Triggers (Data Definition Language)

Phản ứng với các thay đổi cấu trúc database.

```sql
-- SQL Server
CREATE TRIGGER trg_name
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE, DROP_TABLE
AS
BEGIN
    -- Code xử lý
END;
```

### 2.3 LOGON Triggers

Phản ứng khi user đăng nhập vào database server.

```sql
-- SQL Server
CREATE TRIGGER trg_name
ON ALL SERVER
FOR LOGON
AS
BEGIN
    -- Code xử lý
END;
```

## 3. Dữ liệu trong Trigger

### 3.1 Bảng Inserted và Deleted

SQL Server sử dụng hai bảng đặc biệt:

- Inserted: Chứa dữ liệu mới (INSERT/UPDATE)
- Deleted: Chứa dữ liệu cũ (DELETE/UPDATE)

```sql
-- Ví dụ với UPDATE trigger
CREATE TRIGGER trg_audit_update
ON employees
AFTER UPDATE
AS
BEGIN
    INSERT INTO audit_log (
        employee_id,
        old_salary,
        new_salary,
        modified_date
    )
    SELECT
        i.employee_id,
        d.salary,
        i.salary,
        GETDATE()
    FROM inserted i
    JOIN deleted d ON i.employee_id = d.employee_id
    WHERE i.salary <> d.salary;
END;
```

### 3.2 NEW và OLD References (MySQL)

MySQL sử dụng NEW và OLD:

- NEW: Dữ liệu mới (INSERT/UPDATE)
- OLD: Dữ liệu cũ (DELETE/UPDATE)

```sql
CREATE TRIGGER trg_check_salary
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    IF NEW.salary < OLD.salary THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Salary cannot be decreased';
    END IF;
END;
```

## 4. Quản lý Triggers

### 4.1 Tạo Trigger

```sql
-- SQL Server
CREATE TRIGGER trg_name
ON table_name
AFTER INSERT
AS
BEGIN
    -- Code xử lý
END;

-- MySQL
CREATE TRIGGER trg_name
AFTER INSERT ON table_name
FOR EACH ROW
BEGIN
    -- Code xử lý
END;
```

### 4.2 Sửa đổi Trigger

```sql
-- SQL Server
ALTER TRIGGER trg_name
ON table_name
AFTER UPDATE
AS
BEGIN
    -- Code mới
END;

-- MySQL
DROP TRIGGER IF EXISTS trg_name;
CREATE TRIGGER trg_name
AFTER UPDATE ON table_name
FOR EACH ROW
BEGIN
    -- Code mới
END;
```

### 4.3 Xóa Trigger

```sql
-- SQL Server/MySQL
DROP TRIGGER [IF EXISTS] trg_name;
```

### 4.4 Vô hiệu hóa/Kích hoạt Trigger

```sql
-- SQL Server
DISABLE TRIGGER trg_name ON table_name;
ENABLE TRIGGER trg_name ON table_name;

-- Vô hiệu hóa tất cả triggers trên bảng
DISABLE TRIGGER ALL ON table_name;
```

## 5. Best Practices

### 5.1 Performance

- Giữ code trong trigger ngắn gọn và hiệu quả
- Tránh các vòng lặp phức tạp
- Hạn chế số lượng trigger trên mỗi bảng
- Tránh gọi stored procedures phức tạp trong trigger

### 5.2 Error Handling

```sql
-- SQL Server
BEGIN TRY
    -- Code trigger
END TRY
BEGIN CATCH
    -- Xử lý lỗi
    THROW;
END CATCH;

-- MySQL
DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
BEGIN
    -- Xử lý lỗi
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Error in trigger';
END;
```

### 5.3 Maintainability

- Comment code đầy đủ
- Đặt tên rõ ràng và có ý nghĩa
- Ghi log các thay đổi quan trọng
- Theo dõi dependencies

### 5.4 Security

- Kiểm tra quyền hạn
- Validate dữ liệu đầu vào
- Tránh SQL injection
- Giới hạn phạm vi ảnh hưởng

## 6. Use Cases phổ biến

### 6.1 Audit Trail

```sql
CREATE TRIGGER trg_audit_changes
ON table_name
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    INSERT INTO audit_log (
        action_type,
        table_name,
        modified_by,
        modified_date
    )
    VALUES (
        TRIGGER_NESTLEVEL(),
        'table_name',
        SYSTEM_USER,
        GETDATE()
    );
END;
```

### 6.2 Data Validation

```sql
CREATE TRIGGER trg_validate_data
ON employees
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE salary < 0
    )
    BEGIN
        RAISERROR ('Salary cannot be negative', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
```

### 6.3 Cross-table Updates

```sql
CREATE TRIGGER trg_update_summary
ON order_details
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT SUM(amount)
        FROM order_details
        WHERE order_id = orders.id
    )
    FROM orders
    JOIN inserted ON orders.id = inserted.order_id;
END;
```

### 6.4 Business Rules

```sql
CREATE TRIGGER trg_business_rules
ON orders
AFTER INSERT
AS
BEGIN
    -- Kiểm tra credit limit
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN customers c ON i.customer_id = c.id
        WHERE i.amount > c.credit_limit
    )
    BEGIN
        RAISERROR ('Order exceeds credit limit', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;
END;
