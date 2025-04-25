# Lời giải Bài tập 1: Triggers và Tự động hóa

## Phần 1: DML Triggers

### 1. Kiểm soát tồn kho

```sql
CREATE TRIGGER trg_check_inventory
ON order_details
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @low_stock TABLE (
        product_id INT,
        current_quantity INT,
        min_quantity INT
    );

    -- Kiểm tra và cập nhật tồn kho
    INSERT INTO @low_stock
    SELECT
        p.product_id,
        p.stock_quantity - i.quantity,
        p.min_stock_quantity
    FROM
        inserted i
        JOIN products p ON i.product_id = p.product_id
    WHERE
        p.stock_quantity - i.quantity <= p.min_stock_quantity;

    -- Tự động tạo đơn đặt hàng cho sản phẩm dưới mức tồn kho tối thiểu
    INSERT INTO purchase_orders (
        product_id,
        quantity,
        status,
        created_at
    )
    SELECT
        product_id,
        (min_quantity * 2) - current_quantity,
        'Pending',
        GETDATE()
    FROM @low_stock
    WHERE current_quantity <= min_quantity;

    -- Gửi cảnh báo
    INSERT INTO admin_notifications (
        notification_type,
        message,
        created_at
    )
    SELECT
        'LowStock',
        'Product ID ' + CAST(product_id AS VARCHAR) + ' is low on stock. Current quantity: ' +
        CAST(current_quantity AS VARCHAR),
        GETDATE()
    FROM @low_stock;
END;
```

### 2. Audit Log

```sql
CREATE TRIGGER trg_product_audit
ON products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @action_type VARCHAR(10);

    -- Xác định loại thao tác
    IF EXISTS (SELECT 1 FROM inserted) AND EXISTS (SELECT 1 FROM deleted)
        SET @action_type = 'UPDATE';
    ELSE IF EXISTS (SELECT 1 FROM inserted)
        SET @action_type = 'INSERT';
    ELSE
        SET @action_type = 'DELETE';

    -- Log thay đổi
    INSERT INTO product_audit_log (
        product_id,
        action_type,
        old_data,
        new_data,
        modified_by,
        modified_at
    )
    SELECT
        COALESCE(i.product_id, d.product_id),
        @action_type,
        CASE
            WHEN d.product_id IS NOT NULL
            THEN (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
            ELSE NULL
        END,
        CASE
            WHEN i.product_id IS NOT NULL
            THEN (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER)
            ELSE NULL
        END,
        SYSTEM_USER,
        GETDATE()
    FROM inserted i
    FULL OUTER JOIN deleted d ON i.product_id = d.product_id;
END;
```

## Phần 2: DDL Triggers

### 3. Theo dõi thay đổi schema

```sql
CREATE TRIGGER trg_track_schema_changes
ON DATABASE
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @event_data XML = EVENTDATA();

    -- Kiểm tra thời gian làm việc
    IF DATEPART(HOUR, GETDATE()) NOT BETWEEN 9 AND 17
    BEGIN
        RAISERROR ('Schema changes are only allowed during business hours (9 AM - 5 PM)', 16, 1);
        ROLLBACK;
        RETURN;
    END;

    -- Log thay đổi schema
    INSERT INTO schema_changes_log (
        event_type,
        object_name,
        object_type,
        sql_command,
        affected_columns,
        modified_by,
        modified_at
    )
    SELECT
        @event_data.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(100)'),
        @event_data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(100)'),
        @event_data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(100)'),
        @event_data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)'),
        @event_data.value('(/EVENT_INSTANCE/AlterTableActionList)[1]', 'NVARCHAR(MAX)'),
        @event_data.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(100)'),
        GETDATE();
END;
```

### 4. Kiểm soát naming convention

```sql
CREATE TRIGGER trg_naming_convention
ON DATABASE
FOR CREATE_TABLE, ALTER_TABLE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @event_data XML = EVENTDATA();
    DECLARE @object_name NVARCHAR(128);
    DECLARE @tsql NVARCHAR(MAX);

    SET @object_name = @event_data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(128)');
    SET @tsql = @event_data.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');

    -- Kiểm tra quy ước đặt tên bảng
    IF @object_name NOT LIKE 'tbl_%'
    BEGIN
        RAISERROR ('Table names must start with "tbl_"', 16, 1);
        ROLLBACK;
        RETURN;
    END;

    -- Kiểm tra quy ước đặt tên cột
    IF @tsql LIKE '%CREATE TABLE%' AND
       EXISTS (
           SELECT 1
           FROM string_split(@tsql, CHAR(10))
           WHERE value LIKE '%[^a-z_0-9]%' -- Chỉ cho phép chữ thường, số và dấu gạch dưới
           AND value NOT LIKE '--%' -- Bỏ qua comment
       )
    BEGIN
        RAISERROR ('Column names must contain only lowercase letters, numbers and underscores', 16, 1);
        ROLLBACK;
        RETURN;
    END;
END;
```

## Phần 3: Instead Of Triggers

### 5. Virtual Delete

```sql
CREATE TRIGGER trg_virtual_delete
ON products
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Thêm cột is_deleted nếu chưa có
    IF NOT EXISTS (
        SELECT 1
        FROM sys.columns
        WHERE object_id = OBJECT_ID('products')
        AND name = 'is_deleted'
    )
    BEGIN
        ALTER TABLE products
        ADD is_deleted BIT DEFAULT 0;
    END;

    -- Đánh dấu record là đã xóa
    UPDATE p
    SET
        is_deleted = 1,
        deleted_at = GETDATE(),
        deleted_by = SYSTEM_USER
    FROM products p
    JOIN deleted d ON p.product_id = d.product_id;

    -- Log thao tác xóa
    INSERT INTO product_deletion_log (
        product_id,
        product_name,
        deleted_by,
        deleted_at,
        reason
    )
    SELECT
        d.product_id,
        d.product_name,
        SYSTEM_USER,
        GETDATE(),
        'Soft delete by user'
    FROM deleted d;
END;
```

### 6. Data Validation

```sql
CREATE TRIGGER trg_validate_product
ON products
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate và chuyển đổi dữ liệu
    INSERT INTO products (
        product_name,
        category_id,
        price,
        description,
        created_at
    )
    SELECT
        -- Chuẩn hóa tên sản phẩm
        UPPER(LTRIM(RTRIM(i.product_name))),

        -- Validate category
        CASE
            WHEN EXISTS (
                SELECT 1 FROM categories c
                WHERE c.category_id = i.category_id
            )
            THEN i.category_id
            ELSE NULL
        END,

        -- Validate giá
        CASE
            WHEN i.price <= 0 THEN NULL
            ELSE ROUND(i.price, 2)
        END,

        -- Chuẩn hóa mô tả
        NULLIF(LTRIM(RTRIM(i.description)), ''),

        GETDATE()
    FROM inserted i
    WHERE
        -- Điều kiện validate
        LTRIM(RTRIM(i.product_name)) != '' AND
        i.price > 0 AND
        EXISTS (
            SELECT 1 FROM categories c
            WHERE c.category_id = i.category_id
        );

    -- Log các records không hợp lệ
    INSERT INTO data_validation_log (
        table_name,
        record_data,
        error_message,
        created_at
    )
    SELECT
        'products',
        (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER),
        'Invalid product data: ' +
        CASE
            WHEN LTRIM(RTRIM(i.product_name)) = '' THEN 'Empty product name'
            WHEN i.price <= 0 THEN 'Invalid price'
            WHEN NOT EXISTS (
                SELECT 1 FROM categories c
                WHERE c.category_id = i.category_id
            ) THEN 'Invalid category'
            ELSE 'Unknown error'
        END,
        GETDATE()
    FROM inserted i
    WHERE
        LTRIM(RTRIM(i.product_name)) = '' OR
        i.price <= 0 OR
        NOT EXISTS (
            SELECT 1 FROM categories c
            WHERE c.category_id = i.category_id
        );
END;
```

## Best Practices và Tối ưu hóa

### Performance

1. Sử dụng SET NOCOUNT ON
2. Tránh trigger quá phức tạp
3. Giới hạn số lượng truy vấn
4. Index các cột thường dùng

### Error Handling

1. Log lỗi chi tiết
2. Sử dụng transactions khi cần
3. Rollback khi có lỗi
4. Thông báo lỗi rõ ràng

### Testing

1. Test với nhiều loại dữ liệu
2. Test concurrent operations
3. Verify kết quả sau mỗi trigger
4. Test performance với dữ liệu lớn
