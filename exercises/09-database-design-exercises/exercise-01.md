# Bài tập 1: Database Design và Normalization

## Mục tiêu

- Thiết kế database theo yêu cầu thực tế
- Áp dụng các nguyên tắc normalization
- Tạo relationships và constraints
- Tối ưu schema design
- Viết documentation

## Yêu cầu

### Phần 1: Database Design

1. Thiết kế database cho hệ thống bán hàng online:

```
Yêu cầu:
- Quản lý thông tin khách hàng
- Quản lý sản phẩm và danh mục
- Xử lý đơn hàng
- Quản lý kho hàng
- Thanh toán và hoàn tiền
- Chương trình khuyến mãi
- Reviews và ratings
```

2. Tạo Entity Relationship Diagram (ERD):
   - Xác định entities
   - Thiết lập relationships
   - Định nghĩa attributes
   - Xác định keys

### Phần 2: Normalization

3. Phân tích và chuẩn hóa các bảng:
   - First Normal Form (1NF)
   - Second Normal Form (2NF)
   - Third Normal Form (3NF)
   - Xem xét BCNF khi cần

4. Xử lý các trường hợp đặc biệt:
   - Recursive relationships
   - Many-to-many relationships
   - Optional relationships
   - Inheritance

### Phần 3: Physical Design

5. Thiết kế chi tiết cho mỗi bảng:

```sql
-- Ví dụ mẫu cho bảng Products
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INT,
    price DECIMAL(10,2),
    -- Thêm các cột khác
    CONSTRAINT FK_Category
        FOREIGN KEY (category_id)
        REFERENCES Categories(category_id)
);
```

6. Tạo indexes và constraints:
   - Primary và foreign keys
   - Unique constraints
   - Check constraints
   - Default values
   - Indexes cho performance

### Phần 4: Documentation

7. Schema Documentation:
   - Mô tả từng bảng và quan hệ
   - Data dictionary
   - Business rules
   - Usage patterns

8. Design Decisions:
   - Giải thích các lựa chọn thiết kế
   - Trade-offs đã cân nhắc
   - Performance considerations
   - Security implications

## Gợi ý

1. Bắt đầu với high-level design
2. Xác định các business rules
3. Cân nhắc kỹ về data types
4. Lập kế hoạch cho scalability

## Yêu cầu nâng cao

- Thiết kế cho high availability
- Schema versioning strategy
- Partitioning strategy
- Backup và recovery plan

## Tham khảo: [solution-01.md](solution-01.md)
