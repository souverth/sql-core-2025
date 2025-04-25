# Quản lý dữ liệu và bảng trong SQL

## 1. Tạo và Quản lý Database

### 1.1 Tạo Database

```sql
CREATE DATABASE database_name
  [CHARACTER SET charset_name]
  [COLLATE collation_name];

-- Ví dụ
CREATE DATABASE ecommerce
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

### 1.2 Xóa Database

```sql
DROP DATABASE [IF EXISTS] database_name;
```

### 1.3 Sử dụng Database

```sql
USE database_name;
```

## 2. Tạo và Quản lý Bảng

### 2.1 Tạo Bảng

```sql
CREATE TABLE table_name (
    column1 datatype [constraints],
    column2 datatype [constraints],
    ...,
    [table_constraints]
);

-- Ví dụ
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE,
    hire_date DATE DEFAULT CURRENT_DATE,
    salary DECIMAL(10,2) CHECK (salary > 0),
    department_id INT,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);
```

### 2.2 Sửa đổi Bảng

```sql
-- Thêm cột
ALTER TABLE table_name
ADD column_name datatype [constraints];

-- Xóa cột
ALTER TABLE table_name
DROP COLUMN column_name;

-- Sửa đổi cột
ALTER TABLE table_name
MODIFY column_name new_datatype [constraints];

-- Đổi tên cột
ALTER TABLE table_name
RENAME COLUMN old_name TO new_name;

-- Thêm khóa ngoại
ALTER TABLE table_name
ADD FOREIGN KEY (column_name)
REFERENCES referenced_table(referenced_column);
```

### 2.3 Xóa Bảng

```sql
DROP TABLE [IF EXISTS] table_name;
```

### 2.4 Truncate Bảng

```sql
TRUNCATE TABLE table_name;
```

## 3. Constraints (Ràng buộc)

### 3.1 Primary Key

```sql
-- Khi tạo bảng
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100)
);

-- Hoặc
CREATE TABLE products (
    product_id INT,
    name VARCHAR(100),
    CONSTRAINT pk_product PRIMARY KEY (product_id)
);

-- Thêm sau
ALTER TABLE products
ADD PRIMARY KEY (product_id);
```

### 3.2 Foreign Key

```sql
-- Khi tạo bảng
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    product_id INT,
    FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);

-- Thêm sau
ALTER TABLE orders
ADD FOREIGN KEY (product_id)
REFERENCES products(product_id);
```

### 3.3 Unique

```sql
-- Cột đơn
CREATE TABLE users (
    email VARCHAR(100) UNIQUE
);

-- Nhiều cột
CREATE TABLE products (
    sku VARCHAR(50),
    store_id INT,
    UNIQUE (sku, store_id)
);
```

### 3.4 Check

```sql
CREATE TABLE employees (
    salary DECIMAL(10,2),
    CHECK (salary > 0)
);
```

### 3.5 Not Null

```sql
CREATE TABLE customers (
    name VARCHAR(100) NOT NULL
);
```

### 3.6 Default

```sql
CREATE TABLE orders (
    order_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'pending'
);
```

## 4. Thao tác với dữ liệu

### 4.1 Insert

```sql
-- Insert một dòng
INSERT INTO table_name (column1, column2)
VALUES (value1, value2);

-- Insert nhiều dòng
INSERT INTO table_name (column1, column2)
VALUES
    (value1, value2),
    (value3, value4);

-- Insert từ select
INSERT INTO table1 (column1, column2)
SELECT column1, column2
FROM table2
WHERE condition;
```

### 4.2 Update

```sql
-- Update tất cả
UPDATE table_name
SET column1 = value1, column2 = value2;

-- Update có điều kiện
UPDATE table_name
SET column1 = value1
WHERE condition;

-- Update với join
UPDATE table1 t1
JOIN table2 t2 ON t1.id = t2.id
SET t1.column1 = t2.column2;
```

### 4.3 Delete

```sql
-- Xóa tất cả
DELETE FROM table_name;

-- Xóa có điều kiện
DELETE FROM table_name
WHERE condition;

-- Xóa với join
DELETE t1
FROM table1 t1
JOIN table2 t2 ON t1.id = t2.id
WHERE t2.status = 'inactive';
```

## 5. Views

### 5.1 Tạo View

```sql
CREATE [OR REPLACE] VIEW view_name AS
SELECT column1, column2
FROM table_name
WHERE condition;

-- Ví dụ
CREATE VIEW active_employees AS
SELECT *
FROM employees
WHERE status = 'active';
```

### 5.2 Sửa View

```sql
ALTER VIEW view_name AS
SELECT new_column1, new_column2
FROM table_name
WHERE new_condition;
```

### 5.3 Xóa View

```sql
DROP VIEW [IF EXISTS] view_name;
```

## 6. Temporary Tables

### 6.1 Tạo Temporary Table

```sql
CREATE TEMPORARY TABLE temp_table (
    column1 datatype,
    column2 datatype
);
```

### 6.2 Insert vào Temporary Table

```sql
INSERT INTO temp_table
SELECT column1, column2
FROM main_table
WHERE condition;
```

## 7. Sequences và Auto-increment

### 7.1 Auto-increment

```sql
CREATE TABLE products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100)
);
```

### 7.2 Sequence (PostgreSQL)

```sql
-- Tạo sequence
CREATE SEQUENCE seq_name
START WITH 1
INCREMENT BY 1;

-- Sử dụng sequence
CREATE TABLE products (
    id INT DEFAULT NEXTVAL('seq_name') PRIMARY KEY,
    name VARCHAR(100)
);
```

## 8. Best Practices

### 8.1 Naming Conventions

- Sử dụng tên có ý nghĩa và dễ hiểu
- Nhất quán trong cách đặt tên
- Tránh từ khóa SQL làm tên
- Sử dụng số ít cho tên bảng

### 8.2 Data Integrity

- Luôn sử dụng khóa chính
- Định nghĩa khóa ngoại khi cần thiết
- Sử dụng ràng buộc phù hợp
- Xác định giá trị mặc định hợp lý

### 8.3 Performance

- Sử dụng kiểu dữ liệu phù hợp
- Tạo index cho các cột thường dùng trong tìm kiếm
- Tránh sử dụng quá nhiều NULL
- Cân nhắc khi sử dụng triggers và stored procedures
