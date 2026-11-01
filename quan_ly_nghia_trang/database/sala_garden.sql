-- 1. BẢNG PHÂN QUYỀN (ROLES)
CREATE TABLE roles (
    id INT PRIMARY KEY IDENTITY(1,1),
    role_name VARCHAR(50) NOT NULL UNIQUE,
    description NVARCHAR(255),
    created_at DATETIME DEFAULT GETDATE()
);

-- 2. BẢNG TÀI KHOẢN HỆ THỐNG (USERS)
CREATE TABLE users (
    id INT PRIMARY KEY IDENTITY(1,1),
    role_id INT NOT NULL,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name NVARCHAR(100) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100),
    avatar_url VARCHAR(255),
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE
);

-- 3. BẢNG HỒ SƠ THÂN NHÂN / KHÁCH HÀNG (CUSTOMERS)
CREATE TABLE customers (
    id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT UNIQUE,
    full_name NVARCHAR(100) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    identity_card VARCHAR(20) NOT NULL UNIQUE,
    address NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 4. BẢNG KHU VỰC / PHÂN KHU (ZONES)
CREATE TABLE zones (
    id INT PRIMARY KEY IDENTITY(1,1),
    zone_code VARCHAR(20) NOT NULL UNIQUE,
    zone_name NVARCHAR(100) NOT NULL,
    religion NVARCHAR(50) DEFAULT 'ALL',
    total_plots INT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE()
);

-- 5. BẢNG CHI TIẾT Ô MỘ / KIM TĨNH (PLOTS)
CREATE TABLE plots (
    id INT PRIMARY KEY IDENTITY(1,1),
    zone_id INT NOT NULL,
    plot_code VARCHAR(50) NOT NULL UNIQUE,
    row_num INT NOT NULL,
    col_num INT NOT NULL,
    plot_type VARCHAR(50) NOT NULL,
    status VARCHAR(30) DEFAULT 'AVAILABLE',
    price DECIMAL(15, 2) NOT NULL,
    qr_code_url VARCHAR(255),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (zone_id) REFERENCES zones(id) ON DELETE CASCADE
);

-- 6. BẢNG HỒ SƠ NGƯỜI QUÁ CỐ (DECEASED_PROFILES)
CREATE TABLE deceased_profiles (
    id INT PRIMARY KEY IDENTITY(1,1),
    plot_id INT NOT NULL UNIQUE,
    full_name NVARCHAR(100) NOT NULL,
    dharma_name NVARCHAR(100),
    date_of_birth DATE,
    date_of_death DATE,
    burial_date DATE,
    avatar_url VARCHAR(255),
    biography NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (plot_id) REFERENCES plots(id) ON DELETE CASCADE
);

-- 7. BẢNG HỢP ĐỒNG MUA / THUÊ (CONTRACTS)
CREATE TABLE contracts (
    id INT PRIMARY KEY IDENTITY(1,1),
    contract_code VARCHAR(50) NOT NULL UNIQUE,
    customer_id INT NOT NULL,
    plot_id INT NOT NULL,
    total_amount DECIMAL(15, 2) NOT NULL,
    deposit_amount DECIMAL(15, 2) DEFAULT 0.00,
    payment_type VARCHAR(30) DEFAULT 'LUMP_SUM',
    status VARCHAR(30) DEFAULT 'ACTIVE',
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (plot_id) REFERENCES plots(id)
);

-- 8. BẢNG LỊCH SỬ THANH TOÁN TRẢ GÓP (PAYMENTS)
CREATE TABLE payments (
    id INT PRIMARY KEY IDENTITY(1,1),
    contract_id INT NOT NULL,
    payment_phase INT NOT NULL,
    amount DECIMAL(15, 2) NOT NULL,
    payment_date DATETIME DEFAULT GETDATE(),
    payment_method VARCHAR(30) DEFAULT 'BANK_TRANSFER',
    receipt_url VARCHAR(255),
    note NVARCHAR(255),
    FOREIGN KEY (contract_id) REFERENCES contracts(id) ON DELETE CASCADE
);

-- 9. BẢNG DANH MỤC DỊCH VỤ HẬU SỰ & CHĂM SÓC (SERVICES)
CREATE TABLE services (
    id INT PRIMARY KEY IDENTITY(1,1),
    service_code VARCHAR(30) NOT NULL UNIQUE,
    service_name NVARCHAR(150) NOT NULL,
    price DECIMAL(15, 2) NOT NULL,
    description NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE()
);

-- 10. BẢNG ĐƠN ĐẶT DỊCH VỤ CHĂM SÓC (CARE_ORDERS)
CREATE TABLE care_orders (
    id INT PRIMARY KEY IDENTITY(1,1),
    order_code VARCHAR(50) NOT NULL UNIQUE,
    plot_id INT NOT NULL,
    customer_id INT NOT NULL,
    service_id INT NOT NULL,
    scheduled_date DATE NOT NULL,
    status VARCHAR(30) DEFAULT 'PENDING',
    note NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (plot_id) REFERENCES plots(id),
    FOREIGN KEY (customer_id) REFERENCES customers(id),
    FOREIGN KEY (service_id) REFERENCES services(id)
);

-- 11. BẢNG BÁO CÁO ẢNH NGHIỆM THU DỊCH VỤ (CARE_ORDER_PROOFS)
CREATE TABLE care_order_proofs (
    id INT PRIMARY KEY IDENTITY(1,1),
    care_order_id INT NOT NULL,
    worker_id INT NOT NULL,
    image_url VARCHAR(255) NOT NULL,
    note NVARCHAR(MAX),
    created_at DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (care_order_id) REFERENCES care_orders(id) ON DELETE CASCADE,
    FOREIGN KEY (worker_id) REFERENCES users(id)
);

-- DỮ LIỆU MẪU BAN ĐẦU
INSERT INTO roles (role_name, description) VALUES 
('ADMIN', N'Ban Quản Lý Hoa Viên'),
('STAFF', N'Nhân Viên Kinh Doanh'),
('WORKER', N'Công Nhân Chăm Sóc Vệ Sinh'),
('CUSTOMER', N'Thân Nhân / Khách Hàng');

INSERT INTO zones (zone_code, zone_name, religion, total_plots) VALUES 
('M1', N'Khu M1 - Mộ Đơn Tiêu Chuẩn', 'ALL', 1000),
('M7', N'Khu M7 - Mộ Gia Tộc VIP', 'ALL', 200);

INSERT INTO services (service_code, service_name, price, description) VALUES 
('FLOWER_RAM', N'Cắm Hoa Tươi & Thắp Hương Ngày Rằm', 150000, N'Dâng hoa sen tươi, thắp nhang tàn và dọn dẹp đĩa quả'),
('CLEANING_MONTH', N'Lau Dọn Mộ Đá & Trùng Tu Mảng Cỏ', 300000, N'Lau sạch mộ bằng dung dịch chuyên dụng, nhổ cỏ dại');