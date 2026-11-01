/*
  Du lieu mau cho so do Sala Garden (SQL Server).
  Chay sau database/sala_garden.sql tren database sala_garden_db.
  Moi phan khu co 8 hang x 15 cot; chay lai an toan, khong tao trung ma o.
  Day la du lieu demo phat trien, khong phai quy hoach/phap ly chinh thuc.
*/

USE sala_garden_db;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRANSACTION;

DECLARE @ZoneSeed TABLE (
    zone_code VARCHAR(20) NOT NULL PRIMARY KEY,
    zone_name NVARCHAR(100) NOT NULL,
    religion NVARCHAR(50) NOT NULL,
    default_price DECIMAL(15, 2) NOT NULL
);

INSERT INTO @ZoneSeed (zone_code, zone_name, religion, default_price) VALUES
    ('M1', N'Khu M1 - Mộ Đơn Tiêu Chuẩn Zen Garden', 'ALL', 180000000),
    ('M2', N'Khu M2 - Mộ Đôi Thượng Hạng', 'ALL', 390000000),
    ('M3', N'Khu M3 - Mộ Đơn Gia Đình', 'ALL', 180000000),
    ('M4', N'Khu M4 - Mộ Công Giáo', N'CATHOLIC', 180000000),
    ('M5', N'Khu M5 - Vườn Phật Giáo', N'BUDDHIST', 180000000),
    ('M6', N'Khu M6 - Mộ Sinh Thái', 'ALL', 180000000),
    ('M7', N'Khu M7 - Mộ Gia Tộc VIP', 'ALL', 2800000000),
    ('M8', N'Khu M8 - Mộ Gia Tộc Hoàng Gia', 'ALL', 2800000000);

INSERT INTO dbo.zones (zone_code, zone_name, religion, total_plots)
SELECT s.zone_code, s.zone_name, s.religion, 120
FROM @ZoneSeed AS s
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.zones AS z WHERE z.zone_code = s.zone_code
);

;WITH RowNumbers AS (
    SELECT row_num FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8)) AS r(row_num)
), ColumnNumbers AS (
    SELECT col_num FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),
                                (11),(12),(13),(14),(15)) AS c(col_num)
)
INSERT INTO dbo.plots
    (zone_id, plot_code, row_num, col_num, plot_type, status, price)
SELECT
    z.id,
    CONCAT(z.zone_code, '-R', RIGHT(CONCAT('0', r.row_num), 2), '-', RIGHT(CONCAT('0', c.col_num), 2)),
    r.row_num,
    c.col_num,
    CASE
        WHEN z.zone_code = 'M2' THEN 'DOUBLE'
        WHEN z.zone_code IN ('M3', 'M7', 'M8') THEN 'FAMILY'
        ELSE 'SINGLE'
    END,
    CASE
        WHEN (r.row_num = 2 AND c.col_num = 1)
          OR (r.row_num = 5 AND c.col_num = 12) THEN 'OCCUPIED'
        WHEN slot.position_no <= 39 THEN 'RESERVED'
        ELSE 'AVAILABLE'
    END,
    s.default_price
FROM dbo.zones AS z
JOIN @ZoneSeed AS s ON s.zone_code = z.zone_code
CROSS JOIN RowNumbers AS r
CROSS JOIN ColumnNumbers AS c
CROSS APPLY (SELECT (r.row_num - 1) * 15 + c.col_num AS position_no) AS slot
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.plots AS p
    WHERE p.plot_code = CONCAT(z.zone_code, '-R', RIGHT(CONCAT('0', r.row_num), 2), '-', RIGHT(CONCAT('0', c.col_num), 2))
);

UPDATE z
SET z.total_plots = counts.plot_count
FROM dbo.zones AS z
CROSS APPLY (
    SELECT COUNT(*) AS plot_count
    FROM dbo.plots AS p
    WHERE p.zone_id = z.id
) AS counts
WHERE z.zone_code IN (SELECT zone_code FROM @ZoneSeed);

COMMIT TRANSACTION;

SELECT z.zone_code, z.zone_name, z.total_plots,
       SUM(CASE WHEN p.status = 'AVAILABLE' THEN 1 ELSE 0 END) AS available,
       SUM(CASE WHEN p.status = 'RESERVED' THEN 1 ELSE 0 END) AS reserved,
       SUM(CASE WHEN p.status = 'OCCUPIED' THEN 1 ELSE 0 END) AS occupied,
       SUM(CASE WHEN p.status = 'MAINTENANCE' THEN 1 ELSE 0 END) AS maintenance
FROM dbo.zones AS z
LEFT JOIN dbo.plots AS p ON p.zone_id = z.id
WHERE z.zone_code IN ('M1','M2','M3','M4','M5','M6','M7','M8')
GROUP BY z.zone_code, z.zone_name, z.total_plots
ORDER BY z.zone_code;
GO
