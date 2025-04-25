# Truy vấn dữ liệu trong SQL

## 1. Câu lệnh SELECT và Cách Sử Dụng

### 1.1 Cấu trúc và Giải thích

```sql
-- Cấu trúc cơ bản của câu lệnh SELECT
SELECT [DISTINCT] column1, column2, ... -- Chọn các cột cần lấy
FROM table_name                        -- Chỉ định bảng nguồn
[WHERE condition]                      -- Lọc dữ liệu theo điều kiện
[GROUP BY column1, column2, ...]       -- Nhóm dữ liệu
[HAVING group_condition]               -- Lọc nhóm theo điều kiện
[ORDER BY column1 [ASC|DESC], ...]     -- Sắp xếp kết quả
[LIMIT n];                            -- Giới hạn số lượng kết quả
```

### 1.2 Ví dụ Thực Tế và Giải Thích

```sql
-- 1. Lấy toàn bộ thông tin nhân viên
SELECT * FROM employees;
/*
- Dùng * để lấy tất cả các cột
- Nên tránh dùng * trong production vì ảnh hưởng hiệu năng
- Chỉ nên dùng khi cần xem nhanh dữ liệu
*/

-- 2. Lấy thông tin cụ thể với điều kiện
SELECT
    first_name,
    last_name,
    salary,
    department_id
FROM employees
WHERE salary > 5000
ORDER BY salary DESC;
/*
- Chỉ chọn các cột cần thiết
- Lọc theo điều kiện lương > 5000
- Sắp xếp giảm dần theo lương
*/

-- 3. Loại bỏ giá trị trùng lặp và đặt tên cột
SELECT DISTINCT
    department_id,
    job_id AS position,
    ROUND(salary/12, 2) AS monthly_salary
FROM employees;
/*
- DISTINCT loại bỏ các dòng trùng lặp
- AS đặt tên alias cho cột
- Có thể thực hiện tính toán trong SELECT
*/

-- 4. Giới hạn số lượng kết quả trả về
SELECT first_name, salary
FROM employees
WHERE department_id = 10
ORDER BY salary DESC
LIMIT 5;
/*
- Lấy 5 nhân viên có lương cao nhất của phòng ban 10
- LIMIT giúp tối ưu hiệu năng khi không cần lấy toàn bộ dữ liệu
*/
```

## 2. Mệnh đề WHERE

### 2.1 Điều kiện so sánh

```sql
-- So sánh cơ bản
SELECT * FROM products WHERE price > 100;

-- Kiểm tra khoảng giá trị
SELECT * FROM products
WHERE price BETWEEN 50 AND 100;

-- Kiểm tra tập hợp giá trị
SELECT * FROM products
WHERE category_id IN (1, 2, 3);

-- So khớp chuỗi
SELECT * FROM products
WHERE name LIKE 'iPhone%';
```

### 2.2 Điều kiện logic

```sql
-- Kết hợp nhiều điều kiện
SELECT * FROM employees
WHERE salary > 5000
  AND department_id = 10;

-- Điều kiện hoặc
SELECT * FROM products
WHERE category_id = 1
   OR category_id = 2;

-- Phủ định điều kiện
SELECT * FROM employees
WHERE NOT department_id = 10;
```

## 3. JOIN và Cách Kết Hợp Dữ Liệu

### 3.1 INNER JOIN
- **Mục đích**: Lấy các dòng có giá trị khớp ở cả hai bảng
- **Khi nào dùng**: Khi cần dữ liệu phải tồn tại ở cả hai bảng

```sql
-- Lấy thông tin đơn hàng và khách hàng
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    c.phone
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.total_amount > 1000;
/*
- Chỉ trả về đơn hàng có thông tin khách hàng
- Bỏ qua đơn hàng không có khách hàng
- Bỏ qua khách hàng chưa có đơn hàng
*/
```

### 3.2 LEFT JOIN
- **Mục đích**: Lấy tất cả dữ liệu từ bảng trái và dữ liệu khớp từ bảng phải
- **Khi nào dùng**: Khi cần giữ lại tất cả dữ liệu từ bảng chính, bất kể có khớp hay không

```sql
-- Kiểm tra khách hàng chưa có đơn hàng
SELECT 
    c.customer_name,
    c.email,
    COUNT(o.order_id) as order_count,
    MAX(o.order_date) as last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.email
/*
- Giữ lại tất cả khách hàng
- Đếm số đơn hàng của mỗi khách
- order_count = 0 với khách chưa mua hàng
*/
```

### 3.3 RIGHT JOIN
- **Mục đích**: Tương tự LEFT JOIN nhưng ưu tiên bảng phải
- **Khi nào dùng**: Hiếm khi dùng, thường viết lại thành LEFT JOIN cho dễ đọc

```sql
-- Kiểm tra đơn hàng có khách hàng bị xóa
SELECT 
    o.order_id,
    o.order_date,
    COALESCE(c.customer_name, 'DELETED') as customer
FROM orders o
RIGHT JOIN customers c ON o.customer_id = c.customer_id
/*
- Giữ lại tất cả đơn hàng
- Hiển thị DELETED nếu không tìm thấy khách hàng
*/
```

### 3.4 FULL OUTER JOIN
- **Mục đích**: Lấy tất cả dữ liệu từ cả hai bảng
- **Khi nào dùng**: Khi cần kiểm tra dữ liệu không khớp ở cả hai phía

```sql
-- Kiểm tra tính toàn vẹn dữ liệu
SELECT 
    p.product_id,
    p.product_name,
    i.quantity,
    CASE 
        WHEN p.product_id IS NULL THEN 'Missing Product'
        WHEN i.inventory_id IS NULL THEN 'Missing Inventory'
    END as issue
FROM products p
FULL OUTER JOIN inventory i ON p.product_id = i.product_id
WHERE p.product_id IS NULL OR i.inventory_id IS NULL;
/*
- Tìm sản phẩm không có trong kho
- Tìm tồn kho của sản phẩm không tồn tại
- Hữu ích cho việc kiểm tra dữ liệu
*/
```

### 3.5 SELF JOIN
- **Mục đích**: Join bảng với chính nó
- **Khi nào dùng**: Khi cần xử lý dữ liệu phân cấp hoặc quan hệ trong cùng bảng

```sql
-- Hiển thị cấu trúc quản lý nhân viên
SELECT 
    e1.employee_id,
    e1.last_name as employee_name,
    e2.last_name as manager_name,
    e3.last_name as department_head
FROM employees e1
LEFT JOIN employees e2 ON e1.manager_id = e2.employee_id
LEFT JOIN employees e3 ON e2.manager_id = e3.employee_id
ORDER BY e3.last_name, e2.last_name, e1.last_name;
/*
- e1: Nhân viên
- e2: Quản lý trực tiếp
- e3: Trưởng phòng
- Hiển thị 3 cấp quản lý
*/
```

## 4. GROUP BY và HAVING

### 4.1 Nhóm dữ liệu

```sql
-- Đếm số nhân viên theo phòng ban
SELECT department_id, COUNT(*) as employee_count
FROM employees
GROUP BY department_id;

-- Tính lương trung bình theo phòng ban
SELECT department_id,
       AVG(salary) as avg_salary,
       MAX(salary) as max_salary,
       MIN(salary) as min_salary
FROM employees
GROUP BY department_id;
```

### 4.2 Lọc nhóm với HAVING

```sql
-- Tìm phòng ban có nhiều hơn 10 nhân viên
SELECT department_id, COUNT(*) as emp_count
FROM employees
GROUP BY department_id
HAVING COUNT(*) > 10;

-- Tìm phòng ban có lương trung bình > 5000
SELECT department_id, AVG(salary) as avg_salary
FROM employees
GROUP BY department_id
HAVING AVG(salary) > 5000
ORDER BY avg_salary DESC;
```

## 5. Subqueries

### 5.1 Subquery trong WHERE

```sql
-- Tìm nhân viên có lương > lương trung bình
SELECT *
FROM employees
WHERE salary > (
    SELECT AVG(salary)
    FROM employees
);

-- Tìm sản phẩm trong danh mục hot
SELECT *
FROM products
WHERE category_id IN (
    SELECT category_id
    FROM categories
    WHERE is_hot = true
);
```

### 5.2 Subquery trong FROM

```sql
-- Phân tích lương theo phòng ban
SELECT dept_salary.department_id,
       dept_salary.avg_salary,
       (dept_salary.avg_salary - company_avg.avg_salary) as salary_diff
FROM (
    SELECT department_id, AVG(salary) as avg_salary
    FROM employees
    GROUP BY department_id
) dept_salary
CROSS JOIN (
    SELECT AVG(salary) as avg_salary
    FROM employees
) company_avg;
```

### 5.3 Correlated Subquery

```sql
-- Tìm nhân viên có lương cao nhất trong phòng ban
SELECT *
FROM employees e1
WHERE salary = (
    SELECT MAX(salary)
    FROM employees e2
    WHERE e2.department_id = e1.department_id
);
```

## 6. UNION và Phép tập hợp

### 6.1 UNION

```sql
-- Kết hợp danh sách khách hàng từ hai khu vực
SELECT customer_id, name, 'North' as region
FROM north_customers
UNION
SELECT customer_id, name, 'South' as region
FROM south_customers
ORDER BY name;
```

### 6.2 UNION ALL

```sql
-- Kết hợp tất cả giao dịch từ hai năm
SELECT * FROM transactions_2023
UNION ALL
SELECT * FROM transactions_2024;
```

### 6.3 INTERSECT

```sql
-- Tìm khách hàng mua hàng ở cả hai cửa hàng
SELECT customer_id
FROM store1_sales
INTERSECT
SELECT customer_id
FROM store2_sales;
```

### 6.4 EXCEPT

```sql
-- Tìm khách hàng chỉ mua ở cửa hàng 1
SELECT customer_id
FROM store1_sales
EXCEPT
SELECT customer_id
FROM store2_sales;
```

## 7. Common Table Expressions (CTE)

### 7.1 CTE cơ bản

```sql
WITH dept_avg AS (
    SELECT department_id, AVG(salary) as avg_salary
    FROM employees
    GROUP BY department_id
)
SELECT e.*, d.avg_salary
FROM employees e
JOIN dept_avg d ON e.department_id = d.department_id
WHERE e.salary > d.avg_salary;
```

### 7.2 CTE đệ quy

```sql
WITH RECURSIVE subordinates AS (
    -- Anchor member
    SELECT employee_id, manager_id, first_name, 0 as level
    FROM employees
    WHERE employee_id = 100

    UNION ALL

    -- Recursive member
    SELECT e.employee_id, e.manager_id, e.first_name, s.level + 1
    FROM employees e
    INNER JOIN subordinates s ON s.employee_id = e.manager_id
)
SELECT * FROM subordinates;
```

## 8. Window Functions

### 8.1 Ranking Functions

```sql
SELECT department_id,
       first_name,
       salary,
       RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) as salary_rank,
       DENSE_RANK() OVER (PARTITION BY department_id ORDER BY salary DESC) as dense_rank,
       ROW_NUMBER() OVER (PARTITION BY department_id ORDER BY salary DESC) as row_num
FROM employees;
```

### 8.2 Aggregate Functions

```sql
SELECT department_id,
       first_name,
       salary,
       AVG(salary) OVER (PARTITION BY department_id) as dept_avg,
       MAX(salary) OVER (PARTITION BY department_id) as dept_max,
       MIN(salary) OVER (PARTITION BY department_id) as dept_min
FROM employees;
```

### 8.3 Window Frame

```sql
SELECT department_id,
       hire_date,
       salary,
       SUM(salary) OVER (
           PARTITION BY department_id
           ORDER BY hire_date
           ROWS BETWEEN 1 PRECEDING AND CURRENT ROW
       ) as rolling_salary_sum
FROM employees;
```

## 9. Performance Tips

### 9.1 Index Usage

- Sử dụng các cột trong WHERE, JOIN, ORDER BY
- Tránh chuyển đổi kiểu dữ liệu trong điều kiện
- Tránh sử dụng hàm trên cột trong WHERE

### 9.2 JOIN Optimization

- Chọn loại JOIN phù hợp
- Sử dụng điều kiện JOIN trên các cột được đánh index
- Tránh cartesian products (cross join không cần thiết)

### 9.3 Subquery Optimization

- Xem xét sử dụng JOIN thay thế subquery
- Tránh correlated subqueries khi có thể
- Sử dụng EXISTS thay vì IN khi phù hợp

### 9.4 General Tips

- Chỉ SELECT các cột cần thiết
- Sử dụng điều kiện có tính chọn lọc cao trong WHERE
- Tránh sử dụng DISTINCT khi không cần thiết
- Đặt điều kiện lọc càng sớm càng tốt
