# Lời giải Bài tập 1: Security và Access Control

## Phần 1: Users và Roles

### 1. Tạo cấu trúc phân quyền

```sql
-- Tạo roles
CREATE ROLE admin_role;
CREATE ROLE manager_role;
CREATE ROLE staff_role;
CREATE ROLE guest_role;

-- Phân quyền cho admin
GRANT CONTROL ON DATABASE::SalesDB TO admin_role;

-- Phân quyền cho manager
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO manager_role;
GRANT EXECUTE ON SCHEMA::dbo TO manager_role;

-- Phân quyền cho staff
GRANT SELECT, INSERT ON SCHEMA::dbo TO staff_role;
DENY DELETE ON SCHEMA::dbo TO staff_role;

-- Phân quyền cho guest
GRANT SELECT ON products TO guest_role;
GRANT SELECT ON categories TO guest_role;
```

### 2. Quản lý Users

```sql
-- Tạo login và user cho admin
CREATE LOGIN admin_user
WITH PASSWORD = 'StrongPass123!',
CHECK_EXPIRATION = ON,
CHECK_POLICY = ON;

CREATE USER admin_user FOR LOGIN admin_user;
ALTER ROLE admin_role ADD MEMBER admin_user;

-- Tạo login và user cho staff
CREATE LOGIN staff_user
WITH PASSWORD = 'StaffPass123!'
MUST_CHANGE,
CHECK_EXPIRATION = ON,
CHECK_POLICY = ON;

CREATE USER staff_user FOR LOGIN staff_user;
ALTER ROLE staff_role ADD MEMBER staff_user;

-- Quản lý session timeout
ALTER LOGIN staff_user
WITH SESSION_TIMEOUT = 30;  -- 30 phút

-- Reset password
ALTER LOGIN staff_user
WITH PASSWORD = 'NewPass123!'
MUST_CHANGE;
```

## Phần 2: Permissions

### 3. Row-Level Security

```sql
-- Tạo function cho security policy
CREATE FUNCTION dbo.fn_securitypredicate
(@region_id INT)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS fn_result
    WHERE
        @region_id IN (
            -- Staff chỉ thấy khu vực của mình
            SELECT region_id
            FROM dbo.staff_regions
            WHERE staff_id = DATABASE_PRINCIPAL_ID()
        )
        OR
        -- Manager thấy tất cả trong phòng ban
        IS_MEMBER('manager_role') = 1
        OR
        -- Admin thấy tất cả
        IS_MEMBER('admin_role') = 1;

-- Tạo security policy
CREATE SECURITY POLICY OrderFilter
ADD FILTER PREDICATE dbo.fn_securitypredicate(region_id)
ON dbo.orders;

-- Ngăn xóa đơn hàng hoàn thành
CREATE FUNCTION dbo.fn_preventCompletedOrderDeletion()
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS fn_result
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM dbo.orders
            WHERE status = 'Completed'
        );

CREATE SECURITY POLICY PreventDeletion
ADD BLOCK PREDICATE dbo.fn_preventCompletedOrderDeletion()
ON dbo.orders FOR DELETE;
```

## Phần 3: Data Protection

### 4. Column Encryption

```sql
-- Tạo master key
CREATE MASTER KEY ENCRYPTION
BY PASSWORD = 'MasterKeyPass123!';

-- Tạo certificate
CREATE CERTIFICATE SensitiveDataCert
WITH SUBJECT = 'Certificate for sensitive data';

-- Tạo encryption key
CREATE SYMMETRIC KEY SensitiveDataKey
WITH ALGORITHM = AES_256
ENCRYPTION BY CERTIFICATE SensitiveDataCert;

-- Mã hóa dữ liệu
UPDATE customers
SET
    credit_card = EncryptByKey(
        Key_GUID('SensitiveDataKey'),
        credit_card_number
    ),
    email = EncryptByKey(
        Key_GUID('SensitiveDataKey'),
        email
    );
```

### 5. Data Masking

```sql
-- Thêm masking cho các cột nhạy cảm
ALTER TABLE customers
ALTER COLUMN credit_card
ADD MASKED WITH (FUNCTION = 'partial(0,"XXXX-XXXX-XXXX-",4)');

ALTER TABLE customers
ALTER COLUMN email
ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE customers
ALTER COLUMN phone
ADD MASKED WITH (FUNCTION = 'default()');

-- Cấp quyền xem dữ liệu không bị mask
GRANT UNMASK TO manager_role;
```

## Phần 4: Audit và Monitoring

### 6. Audit Configuration

```sql
-- Tạo server audit
CREATE SERVER AUDIT SecurityAudit
TO FILE (
    FILEPATH = 'C:\Audits\',
    MAXSIZE = 100MB,
    MAX_FILES = 10
)
WITH (
    QUEUE_DELAY = 1000,
    ON_FAILURE = CONTINUE
);

-- Tạo database audit specification
CREATE DATABASE AUDIT SPECIFICATION DatabaseAuditSpec
FOR SERVER AUDIT SecurityAudit
ADD (SELECT, INSERT, UPDATE, DELETE ON DATABASE::SalesDB BY public),
ADD (SCHEMA_OBJECT_CHANGE_GROUP),
ADD (USER_CHANGE_PASSWORD_GROUP);

-- Bật audit
ALTER SERVER AUDIT SecurityAudit WITH (STATE = ON);
ALTER DATABASE AUDIT SPECIFICATION DatabaseAuditSpec WITH (STATE = ON);
```

### 7. Security Reports

```sql
-- List tất cả permissions
CREATE PROCEDURE sp_list_permissions
AS
BEGIN
    SELECT
        dp.name AS principal_name,
        dp.type_desc AS principal_type,
        o.name AS object_name,
        p.permission_name,
        p.state_desc AS permission_state
    FROM sys.database_permissions p
    JOIN sys.database_principals dp
        ON p.grantee_principal_id = dp.principal_id
    LEFT JOIN sys.objects o
        ON p.major_id = o.object_id
    ORDER BY
        principal_name,
        object_name;
END;

-- Kiểm tra failed logins
CREATE PROCEDURE sp_check_failed_logins
AS
BEGIN
    SELECT
        event_time,
        server_principal_name,
        client_ip,
        application_name
    FROM sys.fn_get_audit_file(
        'C:\Audits\*',
        DEFAULT,
        DEFAULT
    )
    WHERE action_id = 'LGIF'
    ORDER BY event_time DESC;
END;

-- Monitor suspicious activities
CREATE PROCEDURE sp_monitor_suspicious
AS
BEGIN
    -- Kiểm tra nhiều lần login thất bại
    SELECT
        server_principal_name,
        COUNT(*) as failed_attempts,
        MAX(event_time) as last_attempt
    FROM sys.fn_get_audit_file(
        'C:\Audits\*',
        DEFAULT,
        DEFAULT
    )
    WHERE
        action_id = 'LGIF'
        AND event_time > DATEADD(HOUR, -1, GETDATE())
    GROUP BY server_principal_name
    HAVING COUNT(*) > 5;

    -- Kiểm tra truy cập ngoài giờ
    SELECT *
    FROM sys.fn_get_audit_file(
        'C:\Audits\*',
        DEFAULT,
        DEFAULT
    )
    WHERE
        DATEPART(HOUR, event_time) NOT BETWEEN 8 AND 18
        AND database_principal_name NOT IN ('sa', 'admin_user');
END;
```

## Best Practices

### Security Configuration

1. Sử dụng Windows Authentication khi có thể
2. Đặt password policy mạnh
3. Regular security reviews
4. Principle of least privilege

### Data Protection

1. Encrypt sensitive data
2. Regular key rotation
3. Secure backup encryption keys
4. Use TDE for database encryption

### Monitoring

1. Regular audit review
2. Alert on suspicious activities
3. Monitor failed logins
4. Track schema changes
