# Lời giải Bài tập 1: Stored Procedures và Functions

## Phần 1: Stored Procedures cơ bản

### 1. Thêm sản phẩm mới

```sql
-- Tạo user-defined type cho sản phẩm
CREATE TYPE ProductType AS TABLE
(
    product_name NVARCHAR(100),
    price DECIMAL(10,2),
    category_id INT
);
GO

-- Tạo stored procedure
CREATE PROCEDURE sp_add_product
    @product_name NVARCHAR(100),
    @price DECIMAL(10,2),
    @category_id INT,
    @product_id INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validate input
    IF @price <= 0
        THROW 50001, 'Price must be positive', 1;
        
    IF NOT EXISTS (SELECT 1 FROM categories WHERE category_id = @category_id)
        THROW 50002, 'Invalid category', 1;
        
    BEGIN TRY
        BEGIN TRANSACTION;
            
        -- Tự động sinh mã sản phẩm
        DECLARE @product_code NVARCHAR(20);
        SELECT @product_code = 'PRD' + RIGHT('00000' + 
            CAST(NEXT VALUE FOR product_seq AS NVARCHAR(5)), 5);
            
        -- Thêm sản phẩm
        INSERT INTO products (
            product_code,
            product_name,
            price,
            category_id,
            created_at
        )
        VALUES (
            @product_code,
            @product_name,
            @price,
            @category_id,
            GETDATE()
        );
        
        SET @product_id = SCOPE_IDENTITY();
        
        -- Log thao tác
        INSERT INTO audit_log (
            action_type,
            table_name,
            record_id,
            action_by,
            action_time
        )
        VALUES (
            'INSERT',
            'products',
            @product_id,
            SYSTEM_USER,
            GETDATE()
        );
        
        COMMIT;
        
        -- Trả về thông tin sản phẩm
        SELECT * FROM products WHERE product_id = @product_id;
        
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
        
        THROW;
    END CATCH;
END;
```

### 2. Xử lý đơn hàng

```sql
-- Tạo user-defined type cho items
CREATE TYPE OrderItemType AS TABLE
(
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10,2)
);
GO

CREATE PROCEDURE sp_process_order
    @customer_id INT,
    @order_items OrderItemType READONLY
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @order_id INT;
    DECLARE @total_amount DECIMAL(10,2) = 0;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate customer
        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = @customer_id)
            THROW 50001, 'Invalid customer', 1;
            
        -- Kiểm tra tồn kho
        IF EXISTS (
            SELECT 1
            FROM @order_items oi
            JOIN products p ON oi.product_id = p.product_id
            WHERE oi.quantity > p.stock_quantity
        )
        BEGIN
            THROW 50002, 'Insufficient stock', 1;
        END
        
        -- Tạo đơn hàng
        INSERT INTO orders (
            customer_id,
            order_date,
            status
        )
        VALUES (
            @customer_id,
            GETDATE(),
            'Processing'
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
            product_id,
            quantity,
            unit_price
        FROM @order_items;
        
        -- Cập nhật tổng tiền
        SELECT @total_amount = SUM(quantity * unit_price)
        FROM @order_items;
        
        UPDATE orders
        SET total_amount = @total_amount
        WHERE order_id = @order_id;
        
        -- Cập nhật tồn kho
        UPDATE p
        SET stock_quantity = p.stock_quantity - oi.quantity
        FROM products p
        JOIN @order_items oi ON p.product_id = oi.product_id;
        
        COMMIT;
        
        -- Trả về thông tin đơn hàng
        SELECT 
            o.*,
            od.product_id,
            od.quantity,
            od.unit_price
        FROM orders o
        JOIN order_details od ON o.order_id = od.order_id
        WHERE o.order_id = @order_id;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        
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
        
        THROW;
    END CATCH;
END;
```

## Phần 2: Functions

### 3. Scalar Function tính giá khuyến mãi

```sql
CREATE FUNCTION fn_calculate_discount_price
(
    @price DECIMAL(10,2),
    @discount_percent INT
)
RETURNS DECIMAL(10,2)
WITH SCHEMABINDING
AS
BEGIN
    DECLARE @discount_price DECIMAL(10,2);
    
    -- Validate input
    IF @price <= 0 OR @discount_percent < 0 OR @discount_percent > 100
        RETURN 0;
        
    -- Tính giá sau khuyến mãi
    SET @discount_price = @price * (1 - @discount_percent / 100.0);
    
    -- Làm tròn đến 2 chữ số thập phân
    RETURN ROUND(@discount_price, 2);
END;
```

### 4. Table-Valued Function lấy lịch sử đơn hàng

```sql
CREATE FUNCTION fn_get_customer_orders
(
    @customer_id INT,
    @from_date DATE,
    @to_date DATE
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        o.order_id,
        o.order_date,
        o.total_amount,
        o.status,
        p.product_name,
        od.quantity,
        od.unit_price,
        od.quantity * od.unit_price as line_total
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    WHERE o.customer_id = @customer_id
    AND o.order_date BETWEEN @from_date AND @to_date
);
```

## Best Practices và Tối ưu hóa

### Hiệu năng
1. Sử dụng SET NOCOUNT ON
2. Tránh quá nhiều transactions
3. Xử lý theo batch khi có thể
4. Sử dụng table variables cho dữ liệu nhỏ

### Error Handling
1. Sử dụng TRY...CATCH
2. Log lỗi chi tiết
3. Rollback transaction khi có lỗi
4. Throw custom errors có ý nghĩa

### Bảo mật
1. Validate input
2. Tránh SQL injection
3. Phân quyền phù hợp
4. Mã hóa dữ liệu nhạy cảm

### Maintainability
1. Comment code rõ ràng
2. Chia nhỏ stored procedures
3. Sử dụng naming conventions
4. Tạo unit tests
