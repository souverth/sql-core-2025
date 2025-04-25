# Lời giải Bài tập 1: Thao tác với dữ liệu và Quản lý bảng

## Phần 1: Thao tác với dữ liệu

### 1. Tạo bảng và thêm dữ liệu

```sql
-- Tạo bảng inventory
CREATE TABLE product_inventory (
    id INT PRIMARY KEY IDENTITY(1,1),
    product_id INT NOT NULL,
    warehouse_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    min_quantity INT NOT NULL DEFAULT 10,
    last_restock_date DATE DEFAULT GETDATE(),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Thêm dữ liệu - Cách 1: INSERT đơn giản
INSERT INTO product_inventory (product_id, warehouse_id, quantity)
VALUES (1, 1, 100);

-- Cách 2: INSERT nhiều dòng
INSERT INTO product_inventory (product_id, warehouse_id, quantity, min_quantity)
VALUES
    (2, 1, 150, 20),
    (3, 1, 200, 30),
    (4, 2, 75, 15);

-- Cách 3: INSERT từ SELECT
INSERT INTO product_inventory (product_id, warehouse_id, quantity, min_quantity)
SELECT
    product_id,
    1 as warehouse_id,
    stock_quantity as quantity,
    FLOOR(stock_quantity * 0.1) as min_quantity
FROM products
WHERE product_id NOT IN (SELECT product_id FROM product_inventory);
```

### 2. Cập nhật dữ liệu có điều kiện

```sql
-- Tăng giá sản phẩm doanh số cao
UPDATE products
SET price = price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM order_details
    GROUP BY product_id
    HAVING SUM(quantity) > 1000
);

-- Giảm giá sản phẩm tồn kho lâu
UPDATE products
SET price = price * 0.8
FROM products p
JOIN product_inventory pi ON p.product_id = pi.product_id
WHERE DATEDIFF(MONTH, pi.last_restock_date, GETDATE()) > 3;

-- Cập nhật trạng thái đơn hàng
UPDATE orders
SET status =
    CASE
        WHEN DATEDIFF(DAY, order_date, GETDATE()) > 7 THEN 'Completed'
        WHEN DATEDIFF(DAY, order_date, GETDATE()) > 3 THEN 'Shipped'
        ELSE 'Processing'
    END
WHERE status NOT IN ('Cancelled', 'Refunded');
```

### 3. Xóa dữ liệu có ràng buộc

```sql
-- Xóa sản phẩm hết hàng
BEGIN TRANSACTION;
    -- Xóa khỏi order_details trước
    DELETE od
    FROM order_details od
    JOIN products p ON od.product_id = p.product_id
    WHERE p.stock_quantity = 0;

    -- Sau đó xóa sản phẩm
    DELETE FROM products
    WHERE stock_quantity = 0;
COMMIT;

-- Xóa đơn hàng cũ
BEGIN TRANSACTION;
    -- Xóa chi tiết đơn hàng trước
    DELETE od
    FROM order_details od
    JOIN orders o ON od.order_id = o.order_id
    WHERE DATEDIFF(YEAR, o.order_date, GETDATE()) > 1;

    -- Sau đó xóa đơn hàng
    DELETE FROM orders
    WHERE DATEDIFF(YEAR, order_date, GETDATE()) > 1;
COMMIT;
```

## Phần 2: MERGE Statement

### 4. Đồng bộ dữ liệu

```sql
-- Tạo bảng log
CREATE TABLE price_change_log (
    id INT PRIMARY KEY IDENTITY(1,1),
    product_id INT,
    old_price DECIMAL(10,2),
    new_price DECIMAL(10,2),
    change_date DATETIME DEFAULT GETDATE()
);

-- MERGE statement
MERGE INTO products AS target
USING product_price_staging AS source
ON target.product_id = source.product_id
WHEN MATCHED THEN
    UPDATE SET
        price = source.new_price,
        updated_at = GETDATE()
WHEN NOT MATCHED BY TARGET THEN
    INSERT (product_id, price, created_at)
    VALUES (source.product_id, source.new_price, GETDATE())
OUTPUT
    inserted.product_id,
    deleted.price,
    inserted.price,
    GETDATE()
INTO price_change_log (product_id, old_price, new_price, change_date);
```

## Phần 3: Transaction Handling

### 5. Xử lý Transaction phức tạp

```sql
CREATE PROCEDURE sp_create_order
    @customer_id INT,
    @product_id INT,
    @quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @order_id INT;
    DECLARE @current_stock INT;
    DECLARE @points_earned INT;
    DECLARE @unit_price DECIMAL(10,2);

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra tồn kho
        SELECT @current_stock = stock_quantity,
               @unit_price = price
        FROM products
        WHERE product_id = @product_id;

        IF @current_stock < @quantity
            THROW 50001, 'Insufficient stock', 1;

        -- Tạo đơn hàng
        INSERT INTO orders (customer_id, order_date, status)
        VALUES (@customer_id, GETDATE(), 'Processing');

        SET @order_id = SCOPE_IDENTITY();

        -- Thêm chi tiết đơn hàng
        INSERT INTO order_details (order_id, product_id, quantity, unit_price)
        VALUES (@order_id, @product_id, @quantity, @unit_price);

        -- Cập nhật tồn kho
        UPDATE products
        SET stock_quantity = stock_quantity - @quantity
        WHERE product_id = @product_id;

        -- Tính điểm thưởng (1 điểm cho mỗi $10)
        SET @points_earned = FLOOR(@quantity * @unit_price / 10);

        -- Cập nhật điểm khách hàng
        UPDATE customers
        SET reward_points = ISNULL(reward_points, 0) + @points_earned
        WHERE customer_id = @customer_id;

        COMMIT TRANSACTION;

        -- Trả về kết quả
        SELECT @order_id as order_id, @points_earned as points_earned;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        INSERT INTO error_log (
            error_number,
            error_message,
            error_line,
            error_time
        )
        VALUES (
            ERROR_NUMBER(),
            ERROR_MESSAGE(),
            ERROR_LINE(),
            GETDATE()
        );

        THROW;
    END CATCH;
END;
```

## Phần 4: Temporary Tables

### 6. Sử dụng bảng tạm

```sql
-- Tính toán khuyến mãi
CREATE TABLE #product_promotions (
    product_id INT,
    base_price DECIMAL(10,2),
    discounted_price DECIMAL(10,2),
    discount_percent INT,
    valid_until DATE
);

INSERT INTO #product_promotions
SELECT
    p.product_id,
    p.price as base_price,
    CASE
        WHEN pi.quantity > 100 THEN p.price * 0.8  -- Giảm 20% cho hàng tồn nhiều
        WHEN od.total_sold < 10 THEN p.price * 0.9 -- Giảm 10% cho hàng bán chậm
        ELSE p.price
    END as discounted_price,
    CASE
        WHEN pi.quantity > 100 THEN 20
        WHEN od.total_sold < 10 THEN 10
        ELSE 0
    END as discount_percent,
    DATEADD(DAY, 30, GETDATE()) as valid_until
FROM
    products p
    LEFT JOIN product_inventory pi ON p.product_id = pi.product_id
    LEFT JOIN (
        SELECT product_id, SUM(quantity) as total_sold
        FROM order_details
        GROUP BY product_id
    ) od ON p.product_id = od.product_id;

-- So sánh hiệu năng với CTE
-- Thường bảng tạm sẽ nhanh hơn với dữ liệu lớn và tái sử dụng nhiều lần
WITH ProductPromotions AS (
    SELECT
        p.product_id,
        p.price as base_price,
        CASE
            WHEN pi.quantity > 100 THEN p.price * 0.8
            WHEN od.total_sold < 10 THEN p.price * 0.9
            ELSE p.price
        END as discounted_price
    FROM
        products p
        LEFT JOIN product_inventory pi ON p.product_id = pi.product_id
        LEFT JOIN (
            SELECT product_id, SUM(quantity) as total_sold
            FROM order_details
            GROUP BY product_id
        ) od ON p.product_id = od.product_id
)
SELECT * FROM ProductPromotions;
```

## Tối ưu hóa và Best Practices

1. **Transaction Management**:
   - Sử dụng transactions cho các thao tác phức tạp
   - Xử lý lỗi và rollback khi cần
   - Tránh transaction quá dài

2. **Error Handling**:
   - Log lỗi chi tiết
   - Throw custom error với thông tin rõ ràng
   - Xử lý các trường hợp ngoại lệ

3. **Performance**:
   - Index các cột thường dùng trong điều kiện
   - Sử dụng bảng tạm cho dữ liệu trung gian
   - Batch processing cho thao tác lớn

4. **Maintainability**:
   - Comment code rõ ràng
   - Tổ chức code thành stored procedures
   - Sử dụng meaningful names
