# Bài tập 1: Truy vấn nâng cao với Window Functions

## Mục tiêu
- Thực hành sử dụng Window Functions
- Hiểu và áp dụng phân tích dữ liệu theo nhóm
- Tính toán các chỉ số thống kê
- Sử dụng các hàm xếp hạng

## Yêu cầu
Sử dụng cơ sở dữ liệu mẫu từ phần trước, thực hiện các truy vấn sau:

1. Xếp hạng các sản phẩm theo giá trong từng danh mục:
   - Tên danh mục
   - Tên sản phẩm
   - Giá
   - Xếp hạng (1 = đắt nhất trong danh mục)

2. Tính tổng doanh thu lũy kế theo ngày:
   - Ngày
   - Doanh thu trong ngày
   - Tổng doanh thu lũy kế từ đầu
   - % tăng trưởng so với ngày trước

3. Phân tích xu hướng đặt hàng của khách hàng:
   - Tên khách hàng
   - Số đơn hàng
   - Tổng tiền
   - So sánh với trung bình của tất cả khách hàng
   - Xếp loại khách hàng (Top 10%, 10-25%, 25-50%, Bottom 50%)

4. Tìm các đơn hàng có giá trị lớn bất thường:
   - Thông tin đơn hàng
   - Giá trị trung bình của 3 đơn hàng trước đó
   - % chênh lệch so với trung bình
   - Đánh dấu nếu chênh lệch > 50%

5. Phân tích thị phần của từng danh mục sản phẩm:
   - Tên danh mục
   - Tổng doanh thu
   - % trong tổng doanh thu
   - So sánh với cùng kỳ tháng trước

## Gợi ý
1. Sử dụng RANK(), DENSE_RANK() hoặc ROW_NUMBER()
2. Dùng SUM() OVER (ORDER BY date)
3. NTILE() để phân nhóm khách hàng
4. LAG() để so sánh với các giá trị trước đó
5. Kết hợp nhiều Window Functions trong một truy vấn

## Yêu cầu nâng cao
- Sử dụng PARTITION BY hiệu quả
- Xử lý các trường hợp NULL và số liệu không đồng nhất
- Tối ưu hiệu năng của window functions
- Giải thích ảnh hưởng của frame clause (ROWS/RANGE)

## Tham khảo: [solution-01.md](solution-01.md)
