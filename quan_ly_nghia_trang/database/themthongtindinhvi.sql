/*
  Chạy một lần trong database sala_garden_db.
  Mã định danh là dữ liệu riêng, chỉ dùng để đối chiếu tra cứu.
  Không đưa mã này ra API response hoặc gắn trực tiếp lên QR công khai.
*/
IF COL_LENGTH('dbo.plots', 'plot_identifier') IS NULL
    ALTER TABLE dbo.plots ADD plot_identifier VARCHAR(80) NULL;

IF COL_LENGTH('dbo.plots', 'latitude') IS NULL
    ALTER TABLE dbo.plots ADD latitude DECIMAL(10, 7) NULL;

IF COL_LENGTH('dbo.plots', 'longitude') IS NULL
    ALTER TABLE dbo.plots ADD longitude DECIMAL(10, 7) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_plots_plot_identifier' AND object_id = OBJECT_ID('dbo.plots'))
    CREATE UNIQUE NONCLUSTERED INDEX UX_plots_plot_identifier
        ON dbo.plots(plot_identifier)
        WHERE plot_identifier IS NOT NULL;

/*
  Sau khi chạy, Ban quản lý cần cập nhật plot_identifier, latitude, longitude
  cho từng phần mộ. API tra cứu không hoạt động cho hồ sơ chưa có mã định danh.
*/
