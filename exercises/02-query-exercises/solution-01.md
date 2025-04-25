# Lời giải Bài tập 1: Truy vấn nâng cao với Window Functions

## Câu 1: Xếp hạng sản phẩm theo giá trong từng danh mục

```sql
WITH ProductCategories AS (
    SELECT
        p.product_name,
        p.price,
        c.category_name,
        -- Xếp hạng trong từng danh mục
        RANK() OVER (
            PARTITION BY c.category_id
            ORDER BY p.price DESC
        ) as price_rank
    FROM
        products p
        INNER JOIN product_categories pc ON p.product_id = pc.product_id
        INNER JOIN categories c ON pc.category_id = c.category_id
)
SELECT
    category_name,
    product_name,
    price,
    price_rank
FROM
    ProductCategories
ORDER BY
    category_name, price_rank;
```

### Giải thích

- Sử dụng CTE để tăng tính dễ đọc
- RANK() tạo xếp hạng với khoảng trống khi có giá trị bằng nhau
- PARTITION BY chia dữ liệu theo danh mục
- ORDER BY DESC để xếp hạng 1 = giá cao nhất

## Câu 2: Doanh thu lũy kế theo ngày

```sql
WITH DailyRevenue AS (
    SELECT
        CAST(order_date AS DATE) as order_day,
        SUM(total_amount) as daily_revenue
    FROM
        orders
    GROUP BY
        CAST(order_date AS DATE)
)
SELECT
    order_day,
    daily_revenue,
    -- Tổng lũy kế
    SUM(daily_revenue) OVER (
        ORDER BY order_day
        ROWS UNBOUNDED PRECEDING
    ) as cumulative_revenue,
    -- % tăng trưởng
    CASE
        WHEN LAG(daily_revenue) OVER (ORDER BY order_day) IS NULL THEN NULL
        ELSE (daily_revenue - LAG(daily_revenue) OVER (ORDER BY order_day)) * 100.0 /
             LAG(daily_revenue) OVER (ORDER BY order_day)
    END as growth_percent
FROM
    DailyRevenue
ORDER BY
    order_day;
```

### Giải thích

- CTE tính tổng doanh thu theo ngày
- SUM() OVER tính tổng lũy kế
- LAG() lấy giá trị của ngày trước để tính % tăng trưởng
- ROWS UNBOUNDED PRECEDING lấy tất cả các dòng trước đó

## Câu 3: Phân tích xu hướng đặt hàng

```sql
WITH CustomerStats AS (
    SELECT
        CONCAT(c.first_name, ' ', c.last_name) as customer_name,
        COUNT(o.order_id) as order_count,
        SUM(o.total_amount) as total_revenue,
        AVG(SUM(o.total_amount)) OVER () as avg_customer_revenue,
        NTILE(10) OVER (ORDER BY SUM(o.total_amount) DESC) as revenue_decile
    FROM
        customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY
        c.customer_id, c.first_name, c.last_name
)
SELECT
    customer_name,
    order_count,
    total_revenue,
    -- So sánh với trung bình
    (total_revenue - avg_customer_revenue) * 100.0 / avg_customer_revenue as diff_from_avg,
    -- Xếp loại khách hàng
    CASE
        WHEN revenue_decile = 1 THEN 'Top 10%'
        WHEN revenue_decile <= 3 THEN 'Top 10-25%'
        WHEN revenue_decile <= 5 THEN 'Top 25-50%'
        ELSE 'Bottom 50%'
    END as customer_segment
FROM
    CustomerStats
ORDER BY
    total_revenue DESC;
```

### Giải thích

- LEFT JOIN để bao gồm cả khách hàng chưa có đơn hàng
- NTILE(10) chia khách hàng thành 10 nhóm theo doanh thu
- Tính % chênh lệch so với trung bình
- Phân loại khách hàng dựa trên decile

## Câu 4: Đơn hàng có giá trị bất thường

```sql
WITH OrderStats AS (
    SELECT
        o.*,
        -- Tính trung bình 3 đơn trước đó
        AVG(total_amount) OVER (
            ORDER BY order_date
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ) as avg_previous_3,
        -- Tính % chênh lệch
        CASE
            WHEN AVG(total_amount) OVER (
                ORDER BY order_date
                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
            ) IS NULL THEN NULL
            ELSE (total_amount - AVG(total_amount) OVER (
                ORDER BY order_date
                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
            )) * 100.0 / AVG(total_amount) OVER (
                ORDER BY order_date
                ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
            )
        END as deviation_percent
    FROM
        orders o
)
SELECT
    order_id,
    order_date,
    total_amount,
    avg_previous_3,
    deviation_percent,
    -- Đánh dấu bất thường
    CASE
        WHEN deviation_percent > 50 THEN 'Unusual'
        ELSE 'Normal'
    END as status
FROM
    OrderStats
WHERE
    avg_previous_3 IS NOT NULL
ORDER BY
    order_date;
```

### Giải thích

- Sử dụng ROWS BETWEEN để lấy 3 đơn hàng trước đó
- Tính % chênh lệch với trung bình
- Đánh dấu bất thường nếu chênh lệch > 50%
- WHERE loại bỏ đơn hàng đầu tiên không có giá trị trung bình

## Câu 5: Phân tích thị phần

```sql
WITH CategoryRevenue AS (
    SELECT
        c.category_name,
        EXTRACT(MONTH FROM o.order_date) as month,
        SUM(od.quantity * od.unit_price) as revenue
    FROM
        categories c
        INNER JOIN product_categories pc ON c.category_id = pc.category_id
        INNER JOIN products p ON pc.product_id = p.product_id
        INNER JOIN order_details od ON p.product_id = od.product_id
        INNER JOIN orders o ON od.order_id = o.order_id
    GROUP BY
        c.category_name,
        EXTRACT(MONTH FROM o.order_date)
)
SELECT
    category_name,
    revenue,
    -- % trong tổng doanh thu
    revenue * 100.0 / SUM(revenue) OVER (PARTITION BY month) as revenue_share,
    -- So sánh với tháng trước
    revenue - LAG(revenue) OVER (
        PARTITION BY category_name
        ORDER BY month
    ) as revenue_change
FROM
    CategoryRevenue
ORDER BY
    month, revenue_share DESC;
```

### Giải thích

- CTE tính doanh thu theo danh mục và tháng
- Window function tính % trong tổng doanh thu
- LAG() so sánh với tháng trước
- PARTITION BY month để tính % trong từng tháng

## Tối ưu hiệu năng

1. Frame Clause:
   - ROWS vs RANGE: ROWS xử lý nhanh hơn vì đơn giản hơn
   - Giới hạn số hàng trong frame để giảm tài nguyên xử lý

2. Index:

   ```sql
   CREATE INDEX idx_order_date ON orders(order_date);
   CREATE INDEX idx_product_category ON product_categories(category_id, product_id);
   ```

3. Materialized Views:
   - Cân nhắc tạo materialized view cho các tính toán phức tạp
   - Cập nhật định kỳ thay vì real-time

4. Phân trang:

   ```sql
   -- Thêm OFFSET/FETCH
   OFFSET 0 ROWS
   FETCH NEXT 100 ROWS ONLY;
   ```

5. Tránh:
   - Window functions lồng nhau
   - Frame quá lớn
   - Quá nhiều PARTITION BY
