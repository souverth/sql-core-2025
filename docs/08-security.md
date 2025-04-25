# Security và Access Control trong SQL

## 1. Quản lý Users và Roles

### 1.1 Users

#### Tạo User

```sql
-- SQL Server
CREATE LOGIN login_name WITH PASSWORD = 'password123';
CREATE USER user_name FOR LOGIN login_name;

-- MySQL
CREATE USER 'username'@'host' IDENTIFIED BY 'password123';
```

#### Xóa User

```sql
-- SQL Server
DROP USER user_name;
DROP LOGIN login_name;

-- MySQL
DROP USER 'username'@'host';
```

#### Thay đổi mật khẩu

```sql
-- SQL Server
ALTER LOGIN login_name WITH PASSWORD = 'new_password';

-- MySQL
ALTER USER 'username'@'host' IDENTIFIED BY 'new_password';
```

### 1.2 Roles

#### Tạo Role

```sql
-- SQL Server
CREATE ROLE role_name;

-- MySQL
CREATE ROLE 'role_name';
```

#### Gán User vào Role

```sql
-- SQL Server
ALTER ROLE role_name ADD MEMBER user_name;

-- MySQL
GRANT 'role_name' TO 'username'@'host';
```

#### Xóa Role

```sql
-- SQL Server
DROP ROLE role_name;

-- MySQL
DROP ROLE 'role_name';
```

## 2. Permissions

### 2.1 Cấp quyền

```sql
-- Cấp quyền cụ thể
GRANT SELECT, INSERT, UPDATE
ON table_name
TO user_or_role;

-- Cấp tất cả quyền
GRANT ALL PRIVILEGES
ON table_name
TO user_or_role;

-- Cấp quyền với điều kiện
GRANT SELECT
ON table_name
TO user_or_role
WHERE column_name = value;
```

### 2.2 Thu hồi quyền

```sql
-- Thu hồi quyền cụ thể
REVOKE SELECT, INSERT
ON table_name
FROM user_or_role;

-- Thu hồi tất cả quyền
REVOKE ALL PRIVILEGES
ON table_name
FROM user_or_role;
```

### 2.3 Kiểm tra quyền

```sql
-- SQL Server
SELECT * FROM sys.database_permissions
WHERE grantee_principal_id = USER_ID('user_name');

-- MySQL
SHOW GRANTS FOR 'username'@'host';
```

## 3. Authentication

### 3.1 Windows Authentication (SQL Server)

```sql
-- Tạo login cho Windows user
CREATE LOGIN [DOMAIN\username] FROM WINDOWS;

-- Tạo user cho Windows login
CREATE USER [DOMAIN\username] FOR LOGIN [DOMAIN\username];
```

### 3.2 SQL Authentication

```sql
-- Tạo login với SQL Authentication
CREATE LOGIN login_name
WITH PASSWORD = 'StrongPass123'
MUST_CHANGE,
CHECK_EXPIRATION = ON,
CHECK_POLICY = ON;
```

### 3.3 Multi-factor Authentication

```sql
-- Yêu cầu Azure MFA (SQL Server)
ALTER LOGIN login_name
WITH PASSWORD = 'password123'
REQUIRE MFA;
```

## 4. Authorization

### 4.1 Role-based Access Control (RBAC)

```sql
-- Tạo application roles
CREATE APPLICATION ROLE app_role
WITH PASSWORD = 'password123';

-- Gán quyền cho role
GRANT SELECT, INSERT
ON schema_name.table_name
TO app_role;

-- Kích hoạt application role
sp_setapprole 'app_role', 'password123';
```

### 4.2 Row-Level Security

```sql
-- Tạo security policy
CREATE SECURITY POLICY filter_policy
ADD FILTER PREDICATE dbo.fn_securitypredicate(user_id)
ON dbo.table_name;

-- Tạo predicate function
CREATE FUNCTION dbo.fn_securitypredicate
(@user_id int)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN SELECT 1 AS fn_result
WHERE @user_id = USER_ID();
```

### 4.3 Column-Level Security

```sql
-- Mã hóa cột
ALTER TABLE table_name
ALTER COLUMN sensitive_column
ADD MASKED WITH (FUNCTION = 'default()');

-- Cấp quyền xem dữ liệu không bị mask
GRANT UNMASK
TO user_name;
```

## 5. Encryption

### 5.1 Transparent Data Encryption (TDE)

```sql
-- Tạo master key
CREATE MASTER KEY ENCRYPTION
BY PASSWORD = 'StrongPass123';

-- Tạo certificate
CREATE CERTIFICATE TDE_Cert
WITH SUBJECT = 'TDE Certificate';

-- Tạo database encryption key
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDE_Cert;

-- Bật TDE
ALTER DATABASE database_name
SET ENCRYPTION ON;
```

### 5.2 Column-level Encryption

```sql
-- Tạo key
CREATE SYMMETRIC KEY symmetric_key_name
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE certificate_name;

-- Mã hóa dữ liệu
UPDATE table_name
SET encrypted_column = EncryptByKey(
    Key_GUID('symmetric_key_name'),
    plain_text_column
);

-- Giải mã dữ liệu
SELECT DecryptByKey(encrypted_column)
FROM table_name;
```

### 5.3 Always Encrypted

```sql
-- Tạo column master key
CREATE COLUMN MASTER KEY key_name
WITH (
    KEY_STORE_PROVIDER_NAME = 'MSSQL_CERTIFICATE_STORE',
    KEY_PATH = 'CurrentUser/My/key_guid'
);

-- Tạo column encryption key
CREATE COLUMN ENCRYPTION KEY key_name
WITH VALUES (
    COLUMN_MASTER_KEY = key_name,
    ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256',
    ENCRYPTED_VALUE = 0x01234...
);
```

## 6. Auditing

### 6.1 Server Audit

```sql
-- Tạo server audit
CREATE SERVER AUDIT audit_name
TO FILE (FILEPATH = 'C:\audit\');

-- Tạo audit specification
CREATE SERVER AUDIT SPECIFICATION audit_spec_name
FOR SERVER AUDIT audit_name
ADD (FAILED_LOGIN_GROUP),
ADD (SUCCESSFUL_LOGIN_GROUP);

-- Bật audit
ALTER SERVER AUDIT audit_name
WITH (STATE = ON);
```

### 6.2 Database Audit

```sql
-- Tạo database audit specification
CREATE DATABASE AUDIT SPECIFICATION audit_spec_name
FOR SERVER AUDIT audit_name
ADD (SELECT, INSERT, UPDATE, DELETE
     ON schema_name.table_name BY public);
```

### 6.3 Theo dõi thay đổi (Change Tracking)

```sql
-- Bật change tracking cho database
ALTER DATABASE database_name
SET CHANGE_TRACKING = ON;

-- Bật change tracking cho bảng
ALTER TABLE table_name
ENABLE CHANGE_TRACKING;

-- Lấy thay đổi
SELECT * FROM
CHANGETABLE(CHANGES table_name, @last_sync_version) AS CT;
```

## 7. Best Practices

### 7.1 Password Policies

- Yêu cầu độ phức tạp cao
- Thời hạn mật khẩu
- Lịch sử mật khẩu
- Khóa tài khoản sau số lần đăng nhập sai

### 7.2 Principle of Least Privilege

- Chỉ cấp quyền cần thiết
- Sử dụng roles thay vì cấp quyền trực tiếp
- Định kỳ review quyền
- Thu hồi quyền không sử dụng

### 7.3 Network Security

- Sử dụng SSL/TLS
- Giới hạn IP access
- Firewall rules
- VPN cho remote access

### 7.4 Monitoring và Logging

- Audit quan trọng
- Log tất cả fails
- Monitor bất thường
- Backup audit logs
