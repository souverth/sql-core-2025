# Bài tập 1: Truy vấn cơ bản và phép kết

## Mục tiêu

- Thực hành viết các câu truy vấn SELECT cơ bản
- Hiểu và áp dụng các phép JOIN
- Sử dụng các điều kiện WHERE
- Thực hành GROUP BY và HAVING
- Sắp xếp kết quả với ORDER BY

## Yêu cầu

Sử dụng cơ sở dữ liệu mẫu (file schema.sql và sample-data.sql), thực hiện các truy vấn sau:

1. Liệt kê tất cả khách hàng theo thứ tự alphabet của last_name, hiển thị các cột:
   - Họ và tên đầy đủ (ghép first_name và last_name)
   - Email
   - Số điện thoại
   - Thành phố

2. Tìm tất cả đơn hàng của khách hàng 'John Doe', hiển thị:
   - Mã đơn hàng
   - Ngày đặt hàng
   - Tổng tiền
   - Trạng thái

3. Liệt kê sản phẩm và danh mục của chúng:
   - Tên sản phẩm
   - Giá
   - Tên danh mục
   - Tên danh mục cha (nếu có)

4. Thống kê số đơn hàng và tổng doanh thu theo từng khách hàng:
   - Tên khách hàng
   - Số lượng đơn hàng
   - Tổng tiền tất cả đơn hàng
   - Chỉ hiển thị khách hàng có từ 2 đơn hàng trở lên

5. Tìm những sản phẩm chưa từng được đặt hàng:
   - Tên sản phẩm
   - Giá
   - Số lượng trong kho

## Gợi ý

1. Sử dụng CONCAT() để ghép chuỗi
2. Cần JOIN nhiều bảng
3. Sử dụng LEFT JOIN để lấy cả những sản phẩm chưa có trong đơn hàng
4. Dùng GROUP BY và HAVING
5. Có thể dùng NOT EXISTS hoặc LEFT JOIN

## Yêu cầu nâng cao

- Tối ưu câu truy vấn
- Giải thích cách hoạt động của từng câu truy vấn
- Đề xuất index nào nên được tạo để tối ưu hiệu năng

## Tham khảo: [solution-01.md](solution-01.md)
