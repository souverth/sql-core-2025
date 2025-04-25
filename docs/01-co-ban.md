# Cơ bản về SQL

## 1. Giới thiệu

SQL (Structured Query Language) là ngôn ngữ lập trình được thiết kế đặc biệt để quản lý và truy vấn dữ liệu trong hệ quản trị cơ sở dữ liệu quan hệ (RDBMS).

### 1.1 Lịch sử

- Được phát triển bởi IBM vào những năm 1970
- Trở thành tiêu chuẩn ANSI vào năm 1986
- Tiêu chuẩn ISO từ năm 1987

### 1.2 Đặc điểm của SQL

- Ngôn ngữ phi thủ tục (declarative)
- Độc lập với nền tảng
- Dễ học và sử dụng
- Hỗ trợ xử lý tập hợp dữ liệu
- Tiêu chuẩn hóa cao

## 2. Cú pháp SQL

### 2.1 Quy tắc cơ bản

- Câu lệnh SQL không phân biệt chữ hoa chữ thường
- Câu lệnh kết thúc bằng dấu chấm phẩy (;)
- Khoảng trắng và xuống dòng được bỏ qua
- Chuỗi ký tự đặt trong dấu nháy đơn (')
- Tên đối tượng có thể đặt trong dấu ngoặc kép (") hoặc backticks (`)

### 2.2 Từ khóa phổ biến

```sql
SELECT    -- Lấy dữ liệu
FROM      -- Chỉ định bảng nguồn
WHERE     -- Điều kiện lọc
GROUP BY  -- Nhóm dữ liệu
HAVING    -- Điều kiện cho nhóm
ORDER BY  -- Sắp xếp kết quả
INSERT    -- Thêm dữ liệu
UPDATE    -- Cập nhật dữ liệu
DELETE    -- Xóa dữ liệu
CREATE    -- Tạo đối tượng mới
ALTER     -- Sửa đổi đối tượng
DROP      -- Xóa đối tượng
```

## 3. Kiểu dữ liệu

### 3.1 Kiểu số

```sql
-- Số nguyên
TINYINT    -- 0 đến 255
SMALLINT   -- -32,768 đến 32,767
INT        -- -2^31 đến 2^31-1
BIGINT     -- -2^63 đến 2^63-1

-- Số thực
DECIMAL(p,s)  -- Số thập phân chính xác
FLOAT         -- Số thực dấu phẩy động
REAL          -- Số thực dấu phẩy động (độ chính xác đơn)
```

### 3.2 Kiểu chuỗi

```sql
CHAR(n)      -- Chuỗi độ dài cố định
VARCHAR(n)    -- Chuỗi độ dài thay đổi
TEXT          -- Chuỗi dài không giới hạn
NCHAR(n)      -- Chuỗi Unicode độ dài cố định
NVARCHAR(n)   -- Chuỗi Unicode độ dài thay đổi
NTEXT         -- Chuỗi Unicode dài không giới hạn
```

### 3.3 Kiểu ngày giờ

```sql
DATE          -- Ngày (YYYY-MM-DD)
TIME          -- Thời gian (HH:MI:SS)
DATETIME      -- Ngày và giờ
TIMESTAMP     -- Dấu thời gian
```

### 3.4 Kiểu khác

```sql
BOOLEAN       -- True/False
BINARY        -- Dữ liệu nhị phân
BLOB          -- Binary Large Object
JSON          -- Dữ liệu JSON (một số RDBMS)
XML           -- Dữ liệu XML
```

## 4. Toán tử và Biểu thức

### 4.1 Toán tử số học

```sql
+    -- Cộng
-    -- Trừ
*    -- Nhân
/    -- Chia
%    -- Chia lấy dư
```

### 4.2 Toán tử so sánh

```sql
=     -- Bằng
<>    -- Khác
!=    -- Khác
>     -- Lớn hơn
<     -- Nhỏ hơn
>=    -- Lớn hơn hoặc bằng
<=    -- Nhỏ hơn hoặc bằng
```

### 4.3 Toán tử logic

```sql
AND   -- Và
OR    -- Hoặc
NOT   -- Phủ định
```

### 4.4 Toán tử đặc biệt

```sql
BETWEEN    -- Kiểm tra giá trị nằm trong khoảng
IN         -- Kiểm tra giá trị trong tập hợp
LIKE       -- So khớp chuỗi với pattern
IS NULL    -- Kiểm tra giá trị NULL
EXISTS     -- Kiểm tra sự tồn tại của subquery
```

### 4.5 Hàm tích hợp phổ biến

```sql
-- Hàm số học
COUNT()   -- Đếm số lượng
SUM()     -- Tổng
AVG()     -- Trung bình
MIN()     -- Giá trị nhỏ nhất
MAX()     -- Giá trị lớn nhất
ROUND()   -- Làm tròn số

-- Hàm chuỗi
CONCAT()  -- Nối chuỗi
TRIM()    -- Xóa khoảng trắng đầu cuối
UPPER()   -- Chuyển thành chữ hoa
LOWER()   -- Chuyển thành chữ thường
LENGTH()  -- Độ dài chuỗi
SUBSTR()  -- Trích xuất chuỗi con

-- Hàm ngày giờ
NOW()     -- Thời gian hiện tại
DATE()    -- Lấy phần ngày
YEAR()    -- Lấy năm
MONTH()   -- Lấy tháng
DAY()     -- Lấy ngày
```

## 5. Quy tắc đặt tên

### 5.1 Quy tắc chung

- Bắt đầu bằng chữ cái
- Chỉ chứa chữ cái, số và dấu gạch dưới
- Không dùng từ khóa của SQL
- Độ dài tối đa tùy thuộc RDBMS

### 5.2 Best Practices

- Sử dụng tên có ý nghĩa
- Tránh viết tắt không rõ ràng
- Nhất quán trong quy ước đặt tên
- Sử dụng số ít cho tên bảng
- Thêm tiền tố cho các loại đối tượng khác nhau

## 6. Comments

### 6.1 Single-line comment

```sql
-- Đây là comment một dòng
```

### 6.2 Multi-line comment

```sql
/* Đây là comment
   nhiều dòng */
