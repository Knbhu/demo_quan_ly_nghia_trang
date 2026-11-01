/*
   Chay mot lan trong database sala_garden_db sau khi da tao cac bang co ban.
   Script co the chay lai an toan: chi bo sung service_code va bang con thieu.
*/

IF OBJECT_ID(N'dbo.services', N'U') IS NULL
    THROW 51000, N'Chua co bang dbo.services. Hay tao database/sala_garden.sql truoc.', 1;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.services WHERE service_code = 'ANNIVERSARY_VEG')
BEGIN
    INSERT INTO dbo.services(service_code, service_name, price, description)
    VALUES (
        'ANNIVERSARY_VEG',
        N'Cúng Giỗ Trọn Gói & Mâm Cỗ Chay Thanh Tịnh',
        1200000,
        N'Chuẩn bị xôi, chè, hoa quả và mâm cỗ chay theo yêu cầu của gia đình.'
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.services WHERE service_code = 'BONSAI_MONTHLY')
BEGIN
    INSERT INTO dbo.services(service_code, service_name, price, description)
    VALUES (
        'BONSAI_MONTHLY',
        N'Chăm Sóc & Tỉa Cây Cảnh Bonsai Quanh Mộ',
        500000,
        N'Chăm sóc cây cảnh, tỉa cành và duy trì cảnh quan quanh phần mộ theo tháng.'
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.services WHERE service_code = 'LANTERN_RELEASE')
BEGIN
    INSERT INTO dbo.services(service_code, service_name, price, description)
    VALUES (
        'LANTERN_RELEASE',
        N'Thả hoa đăng cầu siêu tại Hồ Sen Tịnh Xá',
        150000,
        N'Nghi thức thả hoa đăng và hồi hướng lời nguyện cầu theo yêu cầu gia đình.'
    );
END;
GO

IF OBJECT_ID(N'dbo.care_order_reviews', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.care_order_reviews (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        care_order_id INT NOT NULL,
        customer_id INT NOT NULL,
        rating TINYINT NOT NULL,
        comment NVARCHAR(1000) NULL,
        confirmed_at DATETIME2 NOT NULL
            CONSTRAINT DF_care_order_reviews_confirmed_at DEFAULT SYSUTCDATETIME(),
        created_at DATETIME2 NOT NULL
            CONSTRAINT DF_care_order_reviews_created_at DEFAULT SYSUTCDATETIME(),
        updated_at DATETIME2 NOT NULL
            CONSTRAINT DF_care_order_reviews_updated_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_care_order_reviews_order FOREIGN KEY (care_order_id)
            REFERENCES dbo.care_orders(id) ON DELETE CASCADE,
        CONSTRAINT FK_care_order_reviews_customer FOREIGN KEY (customer_id)
            REFERENCES dbo.customers(id),
        CONSTRAINT UQ_care_order_reviews_order_customer
            UNIQUE (care_order_id, customer_id),
        CONSTRAINT CK_care_order_reviews_rating CHECK (rating BETWEEN 1 AND 5)
    );
END;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_care_order_reviews_customer'
      AND object_id = OBJECT_ID(N'dbo.care_order_reviews')
)
    CREATE INDEX IX_care_order_reviews_customer
        ON dbo.care_order_reviews(customer_id, care_order_id);
GO

IF OBJECT_ID(N'dbo.care_order_checkout_batches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.care_order_checkout_batches (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        batch_code VARCHAR(50) NOT NULL UNIQUE,
        customer_id INT NOT NULL,
        plot_id INT NOT NULL,
        scheduled_date DATE NOT NULL,
        calendar_type VARCHAR(10) NOT NULL DEFAULT 'SOLAR',
        schedule_type VARCHAR(10) NOT NULL DEFAULT 'ONCE',
        time_slot NVARCHAR(40) NULL,
        prayer_note NVARCHAR(MAX) NULL,
        report_zalo BIT NOT NULL DEFAULT 1,
        report_email BIT NOT NULL DEFAULT 1,
        report_sms BIT NOT NULL DEFAULT 1,
        payment_method VARCHAR(20) NOT NULL DEFAULT 'VIETQR',
        payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        subtotal DECIMAL(15,2) NOT NULL,
        discount_amount DECIMAL(15,2) NOT NULL DEFAULT 0,
        total_amount DECIMAL(15,2) NOT NULL,
        created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_care_checkout_customer FOREIGN KEY (customer_id) REFERENCES dbo.customers(id),
        CONSTRAINT FK_care_checkout_plot FOREIGN KEY (plot_id) REFERENCES dbo.plots(id)
    );
END;
GO

IF COL_LENGTH(N'dbo.care_orders', N'checkout_batch_id') IS NULL
    ALTER TABLE dbo.care_orders ADD checkout_batch_id INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_care_orders_checkout_batch')
    ALTER TABLE dbo.care_orders ADD CONSTRAINT FK_care_orders_checkout_batch
        FOREIGN KEY (checkout_batch_id) REFERENCES dbo.care_order_checkout_batches(id);
GO
