# Stored Procedures và Functions trong SQL

## 1. Stored Procedures

### 1.1 Giới thiệu
Stored Procedure là một tập hợp các câu lệnh SQL được đặt tên và lưu trữ trong database server. Chúng có thể:
- Nhận tham số đầu vào
- Thực hiện nhiều thao tác
- Trả về kết quả hoặc tham số đầu ra
- Được tái sử dụng

### 1.2 Tạo Stored Procedure

```sql
-- SQL Server
CREATE PROCEDURE proc_name
    @param1 datatype,
    @param2 datatype OUTPUT
AS
BEGIN
    -- Code xử lý
    SET @param2 = some_value;
    
    -- Trả về kết quả
    SELECT column1, column2 FROM table_name;
END;

-- MySQL
DELIMITER //
CREATE PROCEDURE proc_name(
    IN param1 datatype,
    OUT param2 datatype
)
BEGIN
    -- Code xử lý
    SET param2 = some_value;
    
    -- Trả về kết quả
    SELECT column1, column2 FROM table_name;
END //
DELIMITER ;
```

### 1.3 Gọi Stored Procedure

```sql
-- SQL Server
DECLARE @result datatype;
EXEC proc_name @param1 = value1, @param2 = @result OUTPUT;

-- MySQL
SET @result = 0;
CALL proc_name(value1, @result);
```

### 1.4 Sửa đổi Stored Procedure

```sql
-- SQL Server
ALTER PROCEDURE proc_name
    @param1 datatype
AS
BEGIN
    -- Code mới
END;

-- MySQL
DROP PROCEDURE IF EXISTS proc_name;
CREATE PROCEDURE proc_name(
    IN param1 datatype
)
BEGIN
    -- Code mới
END;
```

## 2. Functions

### 2.1 Scalar Functions
Trả về một giá trị đơn.

```sql
-- SQL Server
CREATE FUNCTION fn_name
(
    @param1 datatype,
    @param2 datatype
)
RETURNS return_datatype
AS
BEGIN
    DECLARE @result return_datatype;
    -- Code xử lý
    RETURN @result;
END;

-- MySQL
DELIMITER //
CREATE FUNCTION fn_name(
    param1 datatype,
    param2 datatype
)
RETURNS return_datatype
DETERMINISTIC
BEGIN
    DECLARE result return_datatype;
    -- Code xử lý
    RETURN result;
END //
DELIMITER ;
```

### 2.2 Table-Valued Functions
Trả về một bảng kết quả.

```sql
-- SQL Server
CREATE FUNCTION fn_name
(
    @param1 datatype
)
RETURNS TABLE
AS
RETURN
(
    SELECT column1, column2
    FROM table_name
    WHERE condition = @param1
);

-- MySQL (Emulation using stored procedure)
CREATE PROCEDURE fn_name(
    IN param1 datatype
)
BEGIN
    SELECT column1, column2
    FROM table_name
    WHERE condition = param1;
END;
```

## 3. Parameters và Variables

### 3.1 Khai báo biến

```sql
-- SQL Server
DECLARE @variable_name datatype;
SET @variable_name = value;

-- MySQL
DECLARE variable_name datatype;
SET variable_name = value;
```

### 3.2 Loại tham số

```sql
-- SQL Server
CREATE PROCEDURE proc_name
    @param1 datatype,             -- Input parameter
    @param2 datatype OUTPUT,      -- Output parameter
    @param3 datatype READONLY     -- Read-only parameter
AS
BEGIN
    -- Code xử lý
END;

-- MySQL
CREATE PROCEDURE proc_name(
    IN param1 datatype,           -- Input parameter
    OUT param2 datatype,          -- Output parameter
    INOUT param3 datatype         -- Input/Output parameter
)
BEGIN
    -- Code xử lý
END;
```

## 4. Flow Control

### 4.1 IF...ELSE

```sql
IF condition THEN
    -- Code khi điều kiện đúng
ELSE
    -- Code khi điều kiện sai
END IF;
```

### 4.2 CASE

```sql
CASE
    WHEN condition1 THEN result1
    WHEN condition2 THEN result2
    ELSE result3
END;
```

### 4.3 Loops

```sql
-- WHILE loop
WHILE condition DO
    -- Code xử lý
END WHILE;

-- REPEAT loop (MySQL)
REPEAT
    -- Code xử lý
UNTIL condition
END REPEAT;
```

## 5. Error Handling

### 5.1 Try-Catch (SQL Server)

```sql
BEGIN TRY
    -- Code có thể gây lỗi
END TRY
BEGIN CATCH
    -- Xử lý lỗi
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
```

### 5.2 HANDLER (MySQL)

```sql
DELIMITER //
CREATE PROCEDURE proc_name()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Xử lý lỗi
        GET DIAGNOSTICS CONDITION 1
            @sqlstate = RETURNED_SQLSTATE,
            @errno = MYSQL_ERRNO,
            @text = MESSAGE_TEXT;
    END;
    
    -- Code chính
END //
DELIMITER ;
```

## 6. Debugging

### 6.1 Print Messages

```sql
-- SQL Server
PRINT 'Debug message';

-- MySQL
SELECT 'Debug message';
```

### 6.2 Transaction Control

```sql
BEGIN TRANSACTION;
    -- Code cần debug
    SAVE TRANSACTION save_point;
    -- Thêm code
ROLLBACK TRANSACTION save_point;
COMMIT;
```

## 7. Best Practices

### 7.1 Performance
- Tránh sử dụng cursors khi có thể
- Sử dụng SET NOCOUNT ON trong SQL Server
- Tối ưu hóa truy vấn bên trong stored procedure
- Sử dụng tham số có kiểu dữ liệu phù hợp

### 7.2 Bảo mật
- Kiểm tra đầu vào
- Phân quyền thích hợp
- Tránh SQL injection
- Mã hóa dữ liệu nhạy cảm

### 7.3 Maintainability
- Đặt tên có ý nghĩa
- Comment code đầy đủ
- Tuân thủ coding standards
- Quản lý version

### 7.4 Error Handling
- Xử lý tất cả các trường hợp lỗi
- Log lỗi phù hợp
- Rollback transaction khi cần
- Trả về thông báo lỗi rõ ràng
