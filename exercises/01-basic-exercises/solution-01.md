# Lời giải Bài tập 1: Truy vấn cơ bản và phép kết

## Câu 1: Liệt kê khách hàng theo alphabet
```sql
SELECT 
    CONCAT(first_name, ' ', last_name) AS full_name,
    email,
    phone,
    city
FROM 
    customers
ORDER BY 
    last_name, first_name;
```

### Giải thích:
- Sử dụng CONCAT() để ghép first_name và last_name
- ORDER BY sắp xếp theo last_name trước, nếu trùng thì sắp xếp theo first_name
- Không cần JOIN vì tất cả thông tin đều nằm trong bảng customers

## Câu 2: Tìm đơn hàng của John Doe
```sql
SELECT 
    o.order_id,
    o.order_date,
    o.total_amount,
    o.status
FROM 
    orders o
    INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE 
    c.first_name = 'John' 
    AND c.last_name = 'Doe';
```

### Giải thích:
- JOIN bảng orders với customers để lấy thông tin khách hàng
- Điều kiện WHERE lọc theo tên "John Doe"
- Nên có index trên (first_name, last_name) để tối ưu tìm kiếm

## Câu 3: Sản phẩm và danh mục
```sql
SELECT 
    p.product_name,
    p.price,
    c.category_name,
    pc.category_name AS parent_category
FROM 
    products p
    INNER JOIN product_categories pc_link ON p.product_id = pc_link.product_id
    INNER JOIN categories c ON pc_link.category_id = c.category_id
    LEFT JOIN categories pc ON c.parent_category_id = pc.category_id;
```

### Giải thích:
- Cần JOIN 4 bảng:
  1. products: thông tin sản phẩm
  2. product_categories: bảng trung gian
  3. categories: lấy tên danh mục
  4. categories (self-join): lấy tên danh mục cha
- Sử dụng LEFT JOIN với danh mục cha vì không phải danh mục nào cũng có danh mục cha

## Câu 4: Thống kê theo khách hàng
```sql
SELECT 
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_revenue
FROM 
    customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name
HAVING 
    COUNT(o.order_id) >= 2
ORDER BY 
    total_revenue DESC;
```

### Giải thích:
- JOIN customers với orders
- GROUP BY để nhóm theo khách hàng
- HAVING lọc chỉ lấy khách hàng có từ 2 đơn trở lên 
- Sắp xếp theo doanh thu giảm dần

## Câu 5: Sản phẩm chưa được đặt hàng
```sql
-- Cách 1: Sử dụng LEFT JOIN
SELECT 
    p.product_name,
    p.price,
    p.stock_quantity
FROM 
    products p
    LEFT JOIN order_details od ON p.product_id = od.product_id
WHERE 
    od.order_detail_id IS NULL;

-- Cách 2: Sử dụng NOT EXISTS
SELECT 
    p.product_name,
    p.price,
    p.stock_quantity
FROM 
    products p
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM order_details od 
        WHERE od.product_id = p.product_id
    );
```

### Giải thích:
- Cách 1: 
  - LEFT JOIN để lấy tất cả sản phẩm
  - WHERE để lọc những sản phẩm không có trong order_details
- Cách 2:
  - Sử dụng NOT EXISTS có thể hiệu quả hơn với dữ liệu lớn
  - Dễ đọc và hiểu hơn về mặt logic

## Đề xuất Index

1. Bảng customers:
   ```sql
   CREATE INDEX idx_customer_name ON customers(last_name, first_name);
   ```

2. Bảng orders:
   ```sql
   CREATE INDEX idx_customer_orders ON orders(customer_id);
   ```

3. Bảng order_details:
   ```sql
   CREATE INDEX idx_order_details_product ON order_details(product_id);
   ```

4. Bảng product_categories:
   ```sql
   CREATE INDEX idx_product_category ON product_categories(product_id, category_id);
   ```

## Phân tích hiệu năng

1. Câu 1: 
   - Scan index idx_customer_name
   - Không cần truy cập table vì có thể lấy dữ liệu từ index (covering index)

2. Câu 2:
   - Index seek trên customers theo first_name, last_name
   - Nested loop join với orders

3. Câu 3:
   - Multiple index seeks
   - Hash join hoặc merge join tùy thuộc kích thước dữ liệu

4. Câu 4:
   - Index scan trên orders
   - Hash aggregate cho GROUP BY
   - Sort cho ORDER BY

5. Câu 5:
   - Anti-join pattern
   - NOT EXISTS thường hiệu quả hơn LEFT JOIN với điều kiện IS NULL
