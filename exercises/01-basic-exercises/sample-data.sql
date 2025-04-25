-- Insert dữ liệu mẫu vào bảng customers
INSERT INTO customers (customer_id, first_name, last_name, email, phone, address, city, country) VALUES
(1, 'John', 'Doe', 'john.doe@email.com', '123-456-7890', '123 Main St', 'New York', 'USA'),
(2, 'Jane', 'Smith', 'jane.smith@email.com', '234-567-8901', '456 Oak Ave', 'Los Angeles', 'USA'),
(3, 'Michael', 'Johnson', 'michael.j@email.com', '345-678-9012', '789 Pine Rd', 'Chicago', 'USA'),
(4, 'Sarah', 'Wilson', 'sarah.w@email.com', '456-789-0123', '321 Elm St', 'Houston', 'USA'),
(5, 'David', 'Brown', 'david.b@email.com', '567-890-1234', '654 Maple Dr', 'Phoenix', 'USA');

-- Insert dữ liệu mẫu vào bảng categories
INSERT INTO categories (category_id, category_name, description, parent_category_id) VALUES
(1, 'Electronics', 'Electronic devices and accessories', NULL),
(2, 'Computers', 'Desktop and laptop computers', 1),
(3, 'Smartphones', 'Mobile phones and accessories', 1),
(4, 'Clothing', 'Apparel and accessories', NULL),
(5, 'Books', 'Books and publications', NULL);

-- Insert dữ liệu mẫu vào bảng products
INSERT INTO products (product_id, product_name, description, price, category, stock_quantity) VALUES
(1, 'Laptop Pro', 'High-performance laptop', 1299.99, 'Computers', 50),
(2, 'SmartPhone X', 'Latest smartphone model', 999.99, 'Smartphones', 100),
(3, 'Wireless Earbuds', 'Bluetooth earbuds', 159.99, 'Electronics', 200),
(4, 'Classic T-Shirt', 'Cotton t-shirt', 29.99, 'Clothing', 300),
(5, 'SQL Guide', 'Complete SQL guide book', 49.99, 'Books', 150);

-- Insert dữ liệu mẫu vào bảng product_categories
INSERT INTO product_categories (product_id, category_id) VALUES
(1, 1), (1, 2),
(2, 1), (2, 3),
(3, 1),
(4, 4),
(5, 5);

-- Insert dữ liệu mẫu vào bảng orders
INSERT INTO orders (order_id, customer_id, order_date, total_amount, status) VALUES
(1, 1, '2025-01-01 10:00:00', 1299.99, 'Completed'),
(2, 2, '2025-01-02 11:30:00', 1189.97, 'Completed'),
(3, 3, '2025-01-03 14:20:00', 209.98, 'Processing'),
(4, 4, '2025-01-04 16:45:00', 159.99, 'Shipped'),
(5, 5, '2025-01-05 09:15:00', 79.98, 'Completed');

-- Insert dữ liệu mẫu vào bảng order_details
INSERT INTO order_details (order_detail_id, order_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 1, 1299.99),
(2, 2, 2, 1, 999.99),
(3, 2, 3, 1, 189.98),
(4, 3, 4, 2, 59.98),
(5, 3, 5, 3, 149.97),
(6, 4, 3, 1, 159.99),
(7, 5, 4, 1, 29.99),
(8, 5, 5, 1, 49.99);
