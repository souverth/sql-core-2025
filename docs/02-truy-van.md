# Truy vấn dữ liệu trong SQL

## 1. Câu lệnh SELECT cơ bản

### 1.1 Cú pháp cơ bản

```sql
SELECT [DISTINCT] column1, column2, ...
FROM table_name
[WHERE condition]
[GROUP BY column1, column2, ...]
[HAVING group_condition]
[ORDER BY column1 [ASC|DESC], column2 [ASC|DESC], ...]
[LIMIT n];
```

### 1.2 Ví dụ cơ bản

```sql
-- Lấy tất cả cột
SELECT * FROM employees;

-- Lấy một số cột cụ thể
SELECT first_name, last_name, salary FROM employees;

-- Loại bỏ các giá trị trùng lặp
SELECT DISTINCT department_id FROM employees;

-- Sắp xếp kết quả
SELECT first_name, salary
FROM employees
ORDER BY salary DESC;
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

## 3. JOIN

### 3.1 INNER JOIN

```sql
SELECT o.order_id, c.customer_name
FROM orders o
INNER JOIN customers c
  ON o.customer_id = c.customer_id;
```

### 3.2 LEFT JOIN

```sql
SELECT c.customer_name, o.order_id
FROM customers c
LEFT JOIN orders o
  ON c.customer_id = o.customer_id;
```

### 3.3 RIGHT JOIN

```sql
SELECT c.customer_name, o.order_id
FROM orders o
RIGHT JOIN customers c
  ON o.customer_id = c.customer_id;
```

### 3.4 FULL OUTER JOIN

```sql
SELECT c.customer_name, o.order_id
FROM customers c
FULL OUTER JOIN orders o
  ON c.customer_id = o.customer_id;
```

### 3.5 SELF JOIN

```sql
SELECT e1.last_name AS employee,
       e2.last_name AS manager
FROM employees e1
LEFT JOIN employees e2
  ON e1.manager_id = e2.employee_id;
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
