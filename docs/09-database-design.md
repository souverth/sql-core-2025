# Database Design

## 1. Cơ sở thiết kế Database

### 1.1 Các bước thiết kế

1. Thu thập và phân tích yêu cầu
2. Thiết kế conceptual (ER diagram)
3. Thiết kế logical (DBMS-specific model)
4. Thiết kế physical (storage structure)
5. Triển khai và tối ưu hóa

### 1.2 Các nguyên tắc cơ bản

- Đảm bảo tính toàn vẹn dữ liệu
- Tránh dư thừa dữ liệu
- Duy trì tính nhất quán
- Thiết kế linh hoạt và mở rộng được
- Đảm bảo hiệu năng

## 2. Entity-Relationship Diagrams (ERD)

### 2.1 Thành phần cơ bản

#### Entities (Thực thể)

```
[Customer]
- customer_id (PK)
- name
- email
- phone
```

#### Relationships (Mối quan hệ)

```
Customer --< Order   (One-to-Many)
Order    >-- Product (Many-to-Many)
```

#### Attributes (Thuộc tính)

- Regular: tên, địa chỉ
- Composite: họ tên đầy đủ (họ, tên đệm, tên)
- Multi-valued: số điện thoại
- Derived: tuổi (tính từ ngày sinh)

### 2.2 Cardinality và Participation

```
Customer(1) --- (N)Order    // One-to-Many
Product(M) --- (N)Order     // Many-to-Many
Employee(1) --- (1)Passport // One-to-One
```

## 3. Normalization (Chuẩn hóa)

### 3.1 First Normal Form (1NF)

- Mỗi thuộc tính chứa giá trị atomic
- Không có repeating groups
- Có khóa chính

```sql
-- Không tốt
CREATE TABLE contacts (
    id INT,
    phones VARCHAR(100) -- "123,456,789"
);

-- Tốt
CREATE TABLE contacts (
    id INT,
    phone VARCHAR(20)
);
```

### 3.2 Second Normal Form (2NF)

- Đạt 1NF
- Các thuộc tính non-key phụ thuộc hoàn toàn vào khóa chính

```sql
-- Không tốt
CREATE TABLE orders (
    order_id INT,
    product_id INT,
    price DECIMAL, -- phụ thuộc vào product_id
    PRIMARY KEY (order_id, product_id)
);

-- Tốt
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    price DECIMAL
);

CREATE TABLE orders (
    order_id INT,
    product_id INT,
    PRIMARY KEY (order_id, product_id)
);
```

### 3.3 Third Normal Form (3NF)

- Đạt 2NF
- Không có phụ thuộc bắc cầu

```sql
-- Không tốt
CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    dept_id INT,
    dept_name VARCHAR(50) -- phụ thuộc vào dept_id
);

-- Tốt
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    dept_id INT REFERENCES departments(dept_id)
);
```

### 3.4 Boyce-Codd Normal Form (BCNF)

- Nâng cao của 3NF
- Mọi phụ thuộc hàm X → Y, X phải là superkey

### 3.5 Fourth Normal Form (4NF)

- Đạt BCNF
- Không có phụ thuộc đa trị

### 3.6 Fifth Normal Form (5NF)

- Đạt 4NF
- Không có join dependency

## 4. Physical Design

### 4.1 Chọn kiểu dữ liệu

```sql
-- Số nguyên
TINYINT   -- 0 to 255
SMALLINT  -- -32,768 to 32,767
INT       -- -2^31 to 2^31-1
BIGINT    -- -2^63 to 2^63-1

-- Số thực
DECIMAL(p,s) -- Chính xác
FLOAT        -- Xấp xỉ
MONEY        -- Tiền tệ

-- Chuỗi
CHAR(n)      -- Độ dài cố định
VARCHAR(n)    -- Độ dài thay đổi
TEXT         -- Chuỗi dài

-- Thời gian
DATE         -- YYYY-MM-DD
TIME         -- HH:MI:SS
DATETIME     -- DATE + TIME
TIMESTAMP    -- Với timezone
```

### 4.2 Indexing Strategy

```sql
-- Clustered Index
CREATE CLUSTERED INDEX idx_name
ON table_name (column1, column2);

-- Non-clustered Index
CREATE INDEX idx_name
ON table_name (column1, column2);

-- Filtered Index
CREATE INDEX idx_name
ON table_name (column1)
WHERE condition;
```

### 4.3 Partitioning

```sql
-- Partition Function
CREATE PARTITION FUNCTION fn_name (datatype)
AS RANGE RIGHT FOR VALUES (value1, value2, ...);

-- Partition Scheme
CREATE PARTITION SCHEME sch_name
AS PARTITION fn_name
TO (filegroup1, filegroup2, ...);

-- Partitioned Table
CREATE TABLE table_name
(
    column1 datatype,
    column2 datatype
)
ON sch_name(partition_column);
```

## 5. Performance Optimization

### 5.1 Query Optimization

- Sử dụng INDEX phù hợp
- Tránh SELECT *
- Tối ưu JOINs
- Sử dụng điều kiện có tính chọn lọc cao

### 5.2 Storage Optimization

- Chọn kiểu dữ liệu phù hợp
- Nén dữ liệu khi cần
- Phân vùng bảng lớn
- Archiving dữ liệu cũ

### 5.3 Maintenance

- Update statistics
- Rebuild/reorganize indexes
- Monitoring performance
- Backup strategy

## 6. Best Practices

### 6.1 Naming Conventions

- Sử dụng tên có ý nghĩa
- Nhất quán trong cách đặt tên
- Tiền tố cho các loại đối tượng
- Tránh từ khóa của SQL

### 6.2 Documentation

- Entity Relationship Diagrams
- Data Dictionary
- Business Rules
- Stored Procedures
- Security Policies

### 6.3 Version Control

- Database schema versions
- Migration scripts
- Rollback plans
- Change logs

### 6.4 Testing

- Unit Testing
- Integration Testing
- Performance Testing
- Security Testing
