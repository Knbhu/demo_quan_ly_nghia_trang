/*
  QUY HOACH SO DO SALA GARDEN - 19.960 KIM TINH
  ------------------------------------------------
  Chay tren SQL Server, database: sala_garden_db.

  Script nay:
  1. Bo sung metadata de biet khu con, lo gia toc va so kim tinh trong mot lo.
  2. Giu lai du lieu mau cu (ma M?-Rxx-xx) de khong lam mat hop dong/ho so cu,
     nhung danh dau no la layout cu de khong tinh vao so do quy hoach moi.
  3. Tao dung 19.960 kim tinh theo quy uoc K01, K02... K10.

  Luu y: Tat ca o moi duoc tao o trang thai AVAILABLE. Day la du lieu khoi tao
  de kiem tra so do, KHONG phai du lieu phap ly/kinh doanh chinh thuc.
*/

USE sala_garden_db;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.zones', N'U') IS NULL
       OR OBJECT_ID(N'dbo.plots', N'U') IS NULL
    BEGIN
        THROW 51000, N'Chua tim thay bang dbo.zones hoac dbo.plots. Hay chay database/sala_garden.sql truoc.', 1;
    END;

    /* Metadata moi: khong xoa cot hay du lieu cu. */
    IF COL_LENGTH(N'dbo.plots', N'subzone_code') IS NULL
        ALTER TABLE dbo.plots ADD subzone_code VARCHAR(10) NULL;

    IF COL_LENGTH(N'dbo.plots', N'plot_group_code') IS NULL
        ALTER TABLE dbo.plots ADD plot_group_code VARCHAR(50) NULL;

    IF COL_LENGTH(N'dbo.plots', N'slot_no') IS NULL
        ALTER TABLE dbo.plots ADD slot_no SMALLINT NULL;

    IF COL_LENGTH(N'dbo.plots', N'unit_capacity') IS NULL
        ALTER TABLE dbo.plots ADD unit_capacity SMALLINT NULL;

    IF COL_LENGTH(N'dbo.plots', N'whole_unit_required') IS NULL
        ALTER TABLE dbo.plots ADD whole_unit_required BIT NOT NULL
            CONSTRAINT DF_plots_whole_unit_required DEFAULT (0);

    IF COL_LENGTH(N'dbo.plots', N'is_current_layout') IS NULL
        ALTER TABLE dbo.plots ADD is_current_layout BIT NOT NULL
            CONSTRAINT DF_plots_is_current_layout DEFAULT (1);

    /* Danh muc phan khu va tong so kim tinh da chot. */
    DECLARE @ZonePlan TABLE (
        zone_code VARCHAR(20) NOT NULL PRIMARY KEY,
        zone_name NVARCHAR(100) NOT NULL,
        religion NVARCHAR(50) NOT NULL,
        subzone_count INT NOT NULL,
        row_count INT NOT NULL,
        column_count INT NOT NULL,
        slots_per_unit INT NOT NULL,
        unit_prefix VARCHAR(10) NULL,
        plot_type VARCHAR(50) NOT NULL,
        whole_unit_required BIT NOT NULL,
        reference_price DECIMAL(15, 2) NOT NULL,
        expected_count INT NOT NULL
    );

    INSERT INTO @ZonePlan VALUES
        ('M1',  N'Mộ Đơn Tiêu Chuẩn (Phật Giáo)',  N'BUDDHIST', 10, 10, 38,  1, NULL,  'SINGLE',       0,  180000000, 3800),
        ('M2',  N'Mộ Đôi Trung Tâm (Trúc Lâm)',    N'ALL',      10, 10, 22,  2, NULL,  'DOUBLE',       0,  390000000, 4400),
        ('M3',  N'Mộ Gia Đình & Gia Tộc',          N'ALL',       5,  4, 10, 12, 'GT',  'FAMILY',       1, 2800000000, 2400),
        ('M4',  N'Khu Mộ Công Giáo',               N'CATHOLIC',  5, 10, 36,  1, NULL,  'SINGLE',       0,  210000000, 1800),
        ('M5',  N'Mộ Vạn Tuế & Vườn Tùng',         N'BUDDHIST',  5, 10, 12,  2, NULL,  'DOUBLE',       0,  460000000, 1200),
        ('M6',  N'Khu Mộ An Lạc (Đại Lộ Sala)',    N'ALL',       5, 10, 56,  1, NULL,  'SINGLE',       0,  220000000, 2800),
        ('M7',  N'Vườn Zen Đồi Vạn Phật',          N'BUDDHIST',  5, 10, 28,  1, NULL,  'SINGLE',       0,  260000000, 1400),
        ('M8',  N'Mộ Vĩnh Hằng Thượng Hạng',       N'ALL',       4,  5, 15,  4, 'VH',  'FAMILY_VIP',   1, 3600000000, 1200),
        ('M11', N'Mộ Gia Tộc Mở Rộng',             N'ALL',       2,  3, 10, 16, 'GTM', 'FAMILY_EST',   1, 6400000000,  960);

    /* Upsert zones, khong tao trung zone_code. */
    UPDATE z
       SET z.zone_name = zp.zone_name,
           z.religion = zp.religion,
           z.total_plots = zp.expected_count
    FROM dbo.zones AS z
    JOIN @ZonePlan AS zp ON zp.zone_code = z.zone_code;

    INSERT INTO dbo.zones (zone_code, zone_name, religion, total_plots)
    SELECT zp.zone_code, zp.zone_name, zp.religion, zp.expected_count
    FROM @ZonePlan AS zp
    WHERE NOT EXISTS (
        SELECT 1 FROM dbo.zones AS z WHERE z.zone_code = zp.zone_code
    );

    /*
      Cac ma cu M1-R01-01 ... M8-R08-15 van duoc giu de bao toan
      tai khoan test/ho so/hop dong cu, nhung khong tinh vao so do moi.
    */
    UPDATE p
       SET p.is_current_layout = 0
    FROM dbo.plots AS p
    JOIN dbo.zones AS z ON z.id = p.zone_id
    WHERE z.zone_code IN ('M1','M2','M3','M4','M5','M6','M7','M8')
      AND p.plot_code LIKE 'M[1-8]-R%';

    /* Tao day so 1..100 cho khu con, hang/cot va slot kim tinh. */
    DECLARE @N TABLE (n INT NOT NULL PRIMARY KEY);
    INSERT INTO @N (n)
    SELECT TOP (100) ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
    FROM sys.all_objects AS a
    CROSS JOIN sys.all_objects AS b;

    ;WITH UnitRows AS (
        SELECT
            zp.zone_code,
            zp.row_count,
            zp.column_count,
            zp.slots_per_unit,
            zp.unit_prefix,
            zp.plot_type,
            zp.whole_unit_required,
            zp.reference_price,
            sub.n AS subzone_no,
            r.n AS row_no,
            c.n AS col_no,
            ((r.n - 1) * zp.column_count + c.n) AS unit_no
        FROM @ZonePlan AS zp
        JOIN @N AS sub ON sub.n <= zp.subzone_count
        JOIN @N AS r ON r.n <= zp.row_count
        JOIN @N AS c ON c.n <= zp.column_count
    ), PhysicalPlots AS (
        SELECT u.*, s.n AS slot_no
        FROM UnitRows AS u
        JOIN @N AS s ON s.n <= u.slots_per_unit
    ), Prepared AS (
        SELECT
            pp.*,
            CONCAT('K', RIGHT(CONCAT('0', pp.subzone_no), 2)) AS subzone_code,
            CASE
                WHEN pp.unit_prefix IS NULL
                    THEN CONCAT(CHAR(64 + pp.row_no), RIGHT(CONCAT('0', pp.col_no), 2))
                ELSE CONCAT(pp.unit_prefix, RIGHT(CONCAT('0', pp.unit_no), 2))
            END AS unit_label
        FROM PhysicalPlots AS pp
    )
    INSERT INTO dbo.plots
        (zone_id, plot_code, row_num, col_num, plot_type, status, price,
         subzone_code, plot_group_code, slot_no, unit_capacity,
         whole_unit_required, is_current_layout)
    SELECT
        z.id,
        CASE
            /* M2/M5: mot lo doi gom vi tri trai (L) va phai (R). */
            WHEN p.slots_per_unit = 2 THEN CONCAT(
                p.zone_code, '-', p.subzone_code, '-', p.unit_label, '-',
                CASE WHEN p.slot_no = 1 THEN 'L' ELSE 'R' END)
            /* M3/M8/M11: mua tron mot lo gia toc, moi slot la mot kim tinh. */
            WHEN p.slots_per_unit > 2 THEN CONCAT(
                p.zone_code, '-', p.subzone_code, '-', p.unit_label, '-',
                RIGHT(CONCAT('0', p.slot_no), 2))
            /* M1/M4/M6/M7: mot o tuong ung mot kim tinh. */
            ELSE CONCAT(p.zone_code, '-', p.subzone_code, '-', p.unit_label)
        END,
        p.row_no,
        p.col_no,
        p.plot_type,
        'AVAILABLE',
        p.reference_price,
        p.subzone_code,
        CONCAT(p.zone_code, '-', p.subzone_code, '-', p.unit_label),
        p.slot_no,
        p.slots_per_unit,
        p.whole_unit_required,
        1
    FROM Prepared AS p
    JOIN dbo.zones AS z ON z.zone_code = p.zone_code
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.plots AS old_plot
        WHERE old_plot.plot_code = CASE
            WHEN p.slots_per_unit = 2 THEN CONCAT(
                p.zone_code, '-', p.subzone_code, '-', p.unit_label, '-',
                CASE WHEN p.slot_no = 1 THEN 'L' ELSE 'R' END)
            WHEN p.slots_per_unit > 2 THEN CONCAT(
                p.zone_code, '-', p.subzone_code, '-', p.unit_label, '-',
                RIGHT(CONCAT('0', p.slot_no), 2))
            ELSE CONCAT(p.zone_code, '-', p.subzone_code, '-', p.unit_label)
        END
    );

    /* Lay du lieu layout moi lam nguon tinh tong cho giao dien. */
    UPDATE z
       SET z.total_plots = zp.expected_count
    FROM dbo.zones AS z
    JOIN @ZonePlan AS zp ON zp.zone_code = z.zone_code;

    IF NOT EXISTS (
        SELECT 1 FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.plots')
          AND name = N'IX_plots_current_layout_zone_subzone'
    )
        CREATE INDEX IX_plots_current_layout_zone_subzone
        ON dbo.plots (is_current_layout, zone_id, subzone_code, row_num, col_num);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Kiem tra ket qua: tong phai la 19.960 kim tinh. */
SELECT
    z.zone_code AS ma_khu,
    z.zone_name AS ten_phan_khu,
    COUNT(p.id) AS so_kim_tinh_layout_moi,
    SUM(CASE WHEN p.status = 'AVAILABLE' THEN 1 ELSE 0 END) AS con_trong,
    SUM(CASE WHEN p.status = 'RESERVED' THEN 1 ELSE 0 END) AS da_giu_cho,
    SUM(CASE WHEN p.status = 'OCCUPIED' THEN 1 ELSE 0 END) AS da_an_tang
FROM dbo.zones AS z
LEFT JOIN dbo.plots AS p
    ON p.zone_id = z.id AND p.is_current_layout = 1
WHERE z.zone_code IN ('M1','M2','M3','M4','M5','M6','M7','M8','M11')
GROUP BY z.zone_code, z.zone_name
ORDER BY CASE WHEN z.zone_code = 'M11' THEN 11 ELSE CAST(SUBSTRING(z.zone_code, 2, 10) AS INT) END;
GO

SELECT
    z.zone_code AS ma_khu,
    p.subzone_code AS khu_con,
    COUNT(*) AS so_kim_tinh,
    COUNT(DISTINCT p.plot_group_code) AS so_lo_quan_tri,
    MAX(p.unit_capacity) AS kim_tinh_moi_lo,
    MAX(CAST(p.whole_unit_required AS INT)) AS bat_buoc_mua_tron_lo
FROM dbo.plots AS p
JOIN dbo.zones AS z ON z.id = p.zone_id
WHERE p.is_current_layout = 1
GROUP BY z.zone_code, p.subzone_code
ORDER BY CASE WHEN z.zone_code = 'M11' THEN 11 ELSE CAST(SUBSTRING(z.zone_code, 2, 10) AS INT) END,
         p.subzone_code;
GO

SELECT COUNT(*) AS tong_kim_tinh_layout_moi
FROM dbo.plots
WHERE is_current_layout = 1;
GO
