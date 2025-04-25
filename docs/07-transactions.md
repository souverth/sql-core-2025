# Transactions trong SQL

## 1. Khái niệm cơ bản

### 1.1 Transaction là gì?

Transaction là một đơn vị công việc bao gồm một hoặc nhiều thao tác, đảm bảo tính toàn vẹn dữ liệu theo nguyên tắc "tất cả hoặc không có gì" (all-or-nothing).

### 1.2 ACID Properties

#### Atomicity (Tính nguyên tử)

- Tất cả thao tác phải thành công hoặc không có thao tác nào được thực hiện
- Nếu có lỗi, tất cả thay đổi sẽ được rollback

#### Consistency (Tính nhất quán)

- Database phải ở trạng thái hợp lệ trước và sau transaction
- Đảm bảo tuân thủ các ràng buộc và quy tắc

#### Isolation (Tính độc lập)

- Các transaction thực thi độc lập với nhau
- Thay đổi từ một transaction không ảnh hưởng đến transaction khác

#### Durability (Tính bền vững)

- Khi transaction hoàn tất, thay đổi được lưu vĩnh viễn
- Dữ liệu không bị mất kể cả khi hệ thống gặp sự cố

## 2. Transaction Control

### 2.1 Cú pháp cơ bản

```sql
-- Bắt đầu transaction
BEGIN TRANSACTION;

-- Thực hiện các thao tác
INSERT INTO accounts (account_id, balance)
VALUES (1, 1000);

UPDATE accounts
SET balance = balance - 100
WHERE account_id = 1;

-- Nếu thành công
COMMIT;

-- Nếu có lỗi
ROLLBACK;
```

### 2.2 Savepoints

```sql
BEGIN TRANSACTION;

INSERT INTO orders (order_id, amount) VALUES (1, 100);
SAVE TRANSACTION save_point1;

UPDATE inventory SET quantity = quantity - 1;
SAVE TRANSACTION save_point2;

-- Rollback đến một điểm cụ thể
ROLLBACK TRANSACTION save_point1;

COMMIT;
```

### 2.3 Transaction với Error Handling

```sql
BEGIN TRY
    BEGIN TRANSACTION;
        -- Code xử lý

        -- Kiểm tra điều kiện
        IF EXISTS (SELECT 1 FROM accounts WHERE balance < 0)
        BEGIN
            THROW 50000, 'Insufficient funds', 1;
        END;

        COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;

    -- Log lỗi
    INSERT INTO error_log (
        error_number,
        error_message,
        error_time
    )
    VALUES (
        ERROR_NUMBER(),
        ERROR_MESSAGE(),
        GETDATE()
    );

    -- Ném lỗi lên tầng trên
    THROW;
END CATCH;
```

## 3. Isolation Levels

### 3.1 READ UNCOMMITTED

- Level thấp nhất
- Cho phép dirty reads
- Hiệu năng cao nhất

```sql
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    -- Code xử lý
COMMIT;
```

### 3.2 READ COMMITTED

- Level mặc định trong nhiều DBMS
- Ngăn chặn dirty reads
- Cho phép non-repeatable reads

```sql
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    -- Code xử lý
COMMIT;
```

### 3.3 REPEATABLE READ

- Ngăn chặn dirty reads và non-repeatable reads
- Cho phép phantom reads

```sql
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    -- Code xử lý
COMMIT;
```

### 3.4 SERIALIZABLE

- Level cao nhất
- Ngăn chặn tất cả các vấn đề concurrency
- Hiệu năng thấp nhất

```sql
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    -- Code xử lý
COMMIT;
```

## 4. Deadlocks

### 4.1 Nguyên nhân

- Hai hoặc nhiều transaction chờ đợi tài nguyên của nhau
- Tạo thành vòng tròn chờ đợi

### 4.2 Phòng tránh Deadlock

```sql
-- Thứ tự truy cập nhất quán
BEGIN TRANSACTION;
    -- Luôn truy cập bảng theo thứ tự
    UPDATE table1 WITH (ROWLOCK) ...
    UPDATE table2 WITH (ROWLOCK) ...
    UPDATE table3 WITH (ROWLOCK) ...
COMMIT;

-- Sử dụng timeout
SET LOCK_TIMEOUT 10000; -- 10 giây
BEGIN TRANSACTION;
    -- Code xử lý
COMMIT;
```

### 4.3 Xử lý Deadlock

```sql
BEGIN TRY
    BEGIN TRANSACTION;
        -- Code xử lý
    COMMIT;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 1205 -- Deadlock error
    BEGIN
        -- Thử lại transaction
        -- Hoặc thông báo cho user
    END;
    ROLLBACK;
END CATCH;
```

## 5. Performance Considerations

### 5.1 Best Practices

- Giữ transaction ngắn gọn
- Tránh tương tác với user trong transaction
- Chọn isolation level phù hợp
- Tránh escalation lock không cần thiết
- Xử lý lỗi đúng cách

### 5.2 Monitoring

```sql
-- Kiểm tra active transactions
SELECT *
FROM sys.dm_tran_active_transactions;

-- Kiểm tra locks
SELECT *
FROM sys.dm_tran_locks
WHERE request_session_id = @@SPID;

-- Kiểm tra deadlocks
SELECT *
FROM sys.event_log
WHERE event_type = 'deadlock';
```

## 6. Transaction Patterns

### 6.1 Unit of Work

```sql
BEGIN TRANSACTION;
    -- Thêm đơn hàng
    INSERT INTO orders (customer_id, order_date)
    VALUES (@customer_id, GETDATE());

    -- Lấy order_id vừa thêm
    SET @order_id = SCOPE_IDENTITY();

    -- Thêm chi tiết đơn hàng
    INSERT INTO order_details (order_id, product_id, quantity)
    VALUES (@order_id, @product_id, @quantity);

    -- Cập nhật inventory
    UPDATE products
    SET stock = stock - @quantity
    WHERE product_id = @product_id;

    -- Kiểm tra điều kiện
    IF EXISTS (SELECT 1 FROM products WHERE stock < 0)
    BEGIN
        ROLLBACK;
        THROW 50000, 'Insufficient stock', 1;
    END;
COMMIT;
```

### 6.2 Retry Pattern

```sql
DECLARE @retry_count INT = 0;
DECLARE @max_retries INT = 3;

WHILE @retry_count < @max_retries
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            -- Code xử lý
        COMMIT;
        BREAK; -- Thoát loop nếu thành công
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 1205 -- Deadlock
        BEGIN
            SET @retry_count += 1;
            IF @retry_count = @max_retries
                THROW; -- Ném lỗi nếu đã thử maximum
            WAITFOR DELAY '00:00:01'; -- Đợi 1 giây
            CONTINUE; -- Thử lại
        END;
        THROW; -- Ném lỗi khác
    END CATCH;
END;
```

### 6.3 Distributed Transaction

```sql
-- Requires Microsoft Distributed Transaction Coordinator (MSDTC)
BEGIN DISTRIBUTED TRANSACTION;
    -- Thao tác trên Server 1
    INSERT INTO database1.dbo.table1 VALUES (...);

    -- Thao tác trên Server 2
    INSERT INTO database2.dbo.table2 VALUES (...);
COMMIT;
