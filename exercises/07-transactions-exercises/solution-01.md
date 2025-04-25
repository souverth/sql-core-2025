# Lời giải Bài tập 1: Transactions và Xử lý đồng thời

## Phần 1: Transactions cơ bản

### 1. Chuyển tiền giữa các tài khoản

```sql
CREATE PROCEDURE sp_transfer_money
    @from_account INT,
    @to_account INT,
    @amount DECIMAL(10,2),
    @transaction_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate input
    IF @amount <= 0
        THROW 50001, 'Amount must be positive', 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra số dư
        DECLARE @current_balance DECIMAL(10,2);

        SELECT @current_balance = balance
        FROM accounts WITH (UPDLOCK)
        WHERE account_id = @from_account;

        IF @current_balance < @amount
            THROW 50002, 'Insufficient funds', 1;

        -- Trừ tiền tài khoản nguồn
        UPDATE accounts
        SET
            balance = balance - @amount,
            updated_at = GETDATE()
        WHERE account_id = @from_account;

        -- Cộng tiền tài khoản đích
        UPDATE accounts
        SET
            balance = balance + @amount,
            updated_at = GETDATE()
        WHERE account_id = @to_account;

        -- Log giao dịch
        INSERT INTO transaction_log (
            from_account,
            to_account,
            amount,
            transaction_type,
            status,
            created_at
        )
        VALUES (
            @from_account,
            @to_account,
            @amount,
            'TRANSFER',
            'SUCCESS',
            GETDATE()
        );

        SET @transaction_id = SCOPE_IDENTITY();

        COMMIT;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        -- Log lỗi
        INSERT INTO error_log (
            error_number,
            error_message,
            error_procedure,
            error_line,
            error_time
        )
        VALUES (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            ERROR_PROCEDURE(),
            ERROR_LINE(),
            GETDATE()
        );

        -- Log giao dịch thất bại
        INSERT INTO transaction_log (
            from_account,
            to_account,
            amount,
            transaction_type,
            status,
            error_message,
            created_at
        )
        VALUES (
            @from_account,
            @to_account,
            @amount,
            'TRANSFER',
            'FAILED',
            ERROR_MESSAGE(),
            GETDATE()
        );

        THROW;
    END CATCH;
END;
```

### 2. Xử lý đơn hàng với retry logic

```sql
CREATE PROCEDURE sp_process_order
    @customer_id INT,
    @items OrderItemType READONLY,
    @max_retries INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @retry_count INT = 0;
    DECLARE @order_id INT;
    DECLARE @points_earned INT;

    WHILE @retry_count < @max_retries
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            -- Kiểm tra tồn kho
            IF EXISTS (
                SELECT 1
                FROM @items i
                JOIN products p WITH (UPDLOCK) ON i.product_id = p.product_id
                WHERE i.quantity > p.stock_quantity
            )
            BEGIN
                ;THROW 50001, 'Insufficient stock', 1;
            END

            -- Tạo đơn hàng
            INSERT INTO orders (
                customer_id,
                order_date,
                status,
                created_at
            )
            VALUES (
                @customer_id,
                GETDATE(),
                'PENDING',
                GETDATE()
            );

            SET @order_id = SCOPE_IDENTITY();

            -- Thêm chi tiết đơn hàng
            INSERT INTO order_details (
                order_id,
                product_id,
                quantity,
                unit_price
            )
            SELECT
                @order_id,
                i.product_id,
                i.quantity,
                p.price
            FROM @items i
            JOIN products p ON i.product_id = p.product_id;

            -- Cập nhật tồn kho
            UPDATE p
            SET
                stock_quantity = p.stock_quantity - i.quantity,
                updated_at = GETDATE()
            FROM products p
            JOIN @items i ON p.product_id = i.product_id;

            -- Tính điểm thưởng
            SET @points_earned = (
                SELECT FLOOR(SUM(quantity * unit_price) / 100)
                FROM order_details
                WHERE order_id = @order_id
            );

            -- Cập nhật điểm khách hàng
            UPDATE customers
            SET
                reward_points = reward_points + @points_earned,
                updated_at = GETDATE()
            WHERE customer_id = @customer_id;

            COMMIT;
            BREAK; -- Thoát loop nếu thành công

        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK;

            SET @retry_count += 1;

            -- Log lỗi
            INSERT INTO error_log (
                error_number,
                error_message,
                error_procedure,
                retry_count,
                error_time
            )
            VALUES (
                ERROR_NUMBER(),
                ERROR_MESSAGE(),
                ERROR_PROCEDURE(),
                @retry_count,
                GETDATE()
            );

            -- Nếu không phải deadlock hoặc đã hết số lần thử
            IF ERROR_NUMBER() <> 1205 OR @retry_count >= @max_retries
                THROW;

            -- Đợi ngẫu nhiên trước khi thử lại (tránh deadlock)
            WAITFOR DELAY '00:00:0' + CAST(RAND() * 3 AS VARCHAR(1));
        END CATCH;
    END;
END;
```

## Phần 2: Isolation Levels

### 3. Demo các Isolation Levels

```sql
-- Terminal 1: READ UNCOMMITTED
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM products WHERE product_id = 1;
    -- Có thể thấy dữ liệu chưa commit từ Terminal 2
COMMIT;

-- Terminal 2: Dirty Read Demo
BEGIN TRANSACTION;
    UPDATE products
    SET price = price * 1.1
    WHERE product_id = 1;
    WAITFOR DELAY '00:00:05';
    ROLLBACK;

-- Terminal 1: READ COMMITTED (Default)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
    SELECT * FROM products WHERE product_id = 1;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM products WHERE product_id = 1;
    -- Có thể thấy dữ liệu khác nhau giữa 2 lần đọc
COMMIT;

-- Terminal 1: REPEATABLE READ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
    SELECT * FROM products;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM products;
    -- Dữ liệu giống nhau giữa 2 lần đọc
    -- Nhưng có thể thấy rows mới (phantom)
COMMIT;

-- Terminal 1: SERIALIZABLE
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
    SELECT * FROM products;
    WAITFOR DELAY '00:00:05';
    SELECT * FROM products;
    -- Hoàn toàn cô lập với các transaction khác
COMMIT;
```

## Phần 4: Error Handling và Recovery

### 7. Retry Pattern với State Machine

```sql
CREATE TABLE process_state (
    state_id INT IDENTITY(1,1) PRIMARY KEY,
    process_name VARCHAR(50),
    current_step INT,
    max_steps INT,
    status VARCHAR(20),
    retry_count INT,
    last_error VARCHAR(MAX),
    created_at DATETIME,
    updated_at DATETIME
);

CREATE PROCEDURE sp_process_with_retry
    @process_name VARCHAR(50),
    @max_retries INT = 3
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @state_id INT;
    DECLARE @current_step INT = 1;
    DECLARE @max_steps INT = 5;
    DECLARE @retry_count INT = 0;

    -- Khởi tạo state
    INSERT INTO process_state (
        process_name,
        current_step,
        max_steps,
        status,
        retry_count,
        created_at,
        updated_at
    )
    VALUES (
        @process_name,
        @current_step,
        @max_steps,
        'RUNNING',
        0,
        GETDATE(),
        GETDATE()
    );

    SET @state_id = SCOPE_IDENTITY();

    WHILE @current_step <= @max_steps
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;

            -- Thực hiện bước hiện tại
            EXEC sp_execute_step
                @state_id = @state_id,
                @step = @current_step;

            -- Cập nhật state
            UPDATE process_state
            SET
                current_step = @current_step + 1,
                updated_at = GETDATE()
            WHERE state_id = @state_id;

            SET @current_step += 1;
            SET @retry_count = 0;

            COMMIT;

        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK;

            SET @retry_count += 1;

            -- Cập nhật lỗi
            UPDATE process_state
            SET
                status = 'ERROR',
                retry_count = @retry_count,
                last_error = ERROR_MESSAGE(),
                updated_at = GETDATE()
            WHERE state_id = @state_id;

            IF @retry_count >= @max_retries
            BEGIN
                UPDATE process_state
                SET status = 'FAILED'
                WHERE state_id = @state_id;

                THROW;
            END;

            -- Đợi trước khi thử lại
            WAITFOR DELAY '00:00:0' + CAST(@retry_count AS VARCHAR(1));
        END CATCH;
    END;

    -- Hoàn thành
    UPDATE process_state
    SET
        status = 'COMPLETED',
        updated_at = GETDATE()
    WHERE state_id = @state_id;
END;
```

## Best Practices

### Transaction Design

1. Giữ transaction ngắn gọn
2. Tránh user interaction trong transaction
3. Xử lý theo batch với dữ liệu lớn
4. Sử dụng isolation level phù hợp

### Error Handling

1. Implement retry logic
2. Log đầy đủ thông tin lỗi
3. Sử dụng compensating transactions
4. Validate input trước khi bắt đầu transaction

### Performance

1. Index cho các cột trong JOIN và WHERE
2. Giảm thiểu lock duration
3. Sử dụng optimistic concurrency khi có thể
4. Monitor deadlocks và block
