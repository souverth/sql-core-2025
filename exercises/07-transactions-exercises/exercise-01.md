# Bài tập 1: Transactions và Xử lý đồng thời

## Mục tiêu
- Hiểu và áp dụng các tính chất ACID
- Xử lý giao dịch phức tạp
- Quản lý đồng thời và deadlocks
- Thực hành các isolation levels
- Xử lý lỗi trong transaction

## Yêu cầu

### Phần 1: Transactions cơ bản

1. Chuyển tiền giữa các tài khoản:
```sql
-- Yêu cầu:
-- - Kiểm tra số dư
-- - Xử lý rollback khi có lỗi
-- - Log giao dịch
CREATE PROCEDURE sp_transfer_money
    @from_account INT,
    @to_account INT,
    @amount DECIMAL(10,2)
```

2. Xử lý đơn hàng:
```sql
-- Yêu cầu:
-- - Kiểm tra tồn kho
-- - Tạo đơn hàng và chi tiết
-- - Cập nhật số lượng
-- - Tính điểm thưởng
CREATE PROCEDURE sp_process_order
    @customer_id INT,
    @items OrderItemType READONLY
```

### Phần 2: Isolation Levels

3. So sánh kết quả ở các isolation levels khác nhau:
   - READ UNCOMMITTED
   - READ COMMITTED
   - REPEATABLE READ
   - SERIALIZABLE

4. Xử lý các vấn đề:
   - Dirty reads
   - Non-repeatable reads
   - Phantom reads
   - Lost updates

### Phần 3: Xử lý đồng thời

5. Giải quyết deadlock:
   - Xác định nguyên nhân
   - Implement giải pháp
   - Test với concurrent users
   - Monitor deadlocks

6. Tối ưu hiệu năng:
   - Giảm thời gian giữ lock
   - Sử dụng indexes phù hợp
   - Batch processing
   - Retry logic

### Phần 4: Xử lý lỗi

7. Implement retry pattern:
```sql
-- Yêu cầu:
-- - Thử lại khi gặp deadlock
-- - Giới hạn số lần thử
-- - Log lỗi chi tiết
-- - Thông báo trạng thái
```

8. Nested transactions:
   - Xử lý XACT_STATE
   - Save points
   - Error propagation
   - Transaction count

## Gợi ý
1. Sử dụng @@TRANCOUNT để theo dõi nested transactions
2. Implement retry logic cho deadlocks
3. Cân nhắc trade-off giữa các isolation levels
4. Log đầy đủ để debug

## Yêu cầu nâng cao
- Xử lý distributed transactions
- Implement compensating transactions
- Tối ưu hiệu năng với dữ liệu lớn
- High availability considerations

## Tham khảo: [solution-01.md](solution-01.md)
