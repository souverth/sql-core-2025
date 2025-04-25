# Bài tập 1: Security và Access Control

## Mục tiêu

- Thực hành quản lý users và roles
- Phân quyền chi tiết trên database
- Xử lý authentication và authorization
- Bảo mật dữ liệu nhạy cảm
- Audit và monitoring

## Yêu cầu

### Phần 1: Users và Roles

1. Tạo cấu trúc phân quyền:

```sql
-- Tạo các roles cho từng nhóm người dùng
-- - Admin: Full quyền
-- - Manager: Xem và chỉnh sửa
-- - Staff: Chỉ xem và thêm
-- - Guest: Chỉ xem một số bảng
```

2. Quản lý users:

```sql
-- Tạo users với các roles khác nhau
-- Đặt password policy
-- Quản lý session
-- Reset password
```

### Phần 2: Permissions

3. Phân quyền chi tiết:

```sql
-- Object-level permissions
GRANT SELECT, INSERT ON orders TO staff_role;

-- Column-level permissions
GRANT SELECT ON products(product_id, name, price) TO guest_role;

-- Schema-level permissions
GRANT SELECT ON SCHEMA::inventory TO inventory_role;
```

4. Row-Level Security:

```sql
-- Tạo security policy để:
-- - Staff chỉ thấy đơn hàng của khu vực mình
-- - Manager thấy tất cả đơn hàng trong phòng ban
-- - Không cho phép xóa đơn hàng đã hoàn thành
```

### Phần 3: Data Protection

5. Mã hóa dữ liệu:

```sql
-- Mã hóa thông tin nhạy cảm:
-- - Credit card
-- - Email
-- - Phone
-- Sử dụng Column-level encryption
```

6. Data Masking:

```sql
-- Mask dữ liệu cho các roles không có quyền xem:
-- - SSN: XXX-XX-1234
-- - Credit card: XXXX-XXXX-XXXX-1234
-- - Email: j***@domain.com
```

### Phần 4: Audit và Monitoring

7. Audit logs:

```sql
-- Theo dõi:
-- - Login attempts
-- - Data changes
-- - Schema changes
-- - Permission changes
```

8. Security Reports:
   - List tất cả permissions
   - Kiểm tra users không active
   - Review failed logins
   - Theo dõi suspicious activities

## Gợi ý

1. Sử dụng built-in security functions
2. Implement principle of least privilege
3. Regular security reviews
4. Backup audit logs

## Yêu cầu nâng cao

- Implement Multi-factor Authentication
- Tích hợp với Active Directory
- Automated security monitoring
- Compliance reporting

## Tham khảo: [solution-01.md](solution-01.md)
