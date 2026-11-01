-- Bo sung du lieu cho luong lap hop dong moi va cap nhat gia tham khao.
-- Chay mot lan tren database sala_garden_db sau sala_garden.sql.
USE sala_garden_db;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH(N'dbo.contracts', N'beneficiary_name') IS NULL
    ALTER TABLE dbo.contracts ADD beneficiary_name NVARCHAR(100) NULL;

IF COL_LENGTH(N'dbo.contracts', N'beneficiary_relationship') IS NULL
    ALTER TABLE dbo.contracts ADD beneficiary_relationship NVARCHAR(100) NULL;

IF COL_LENGTH(N'dbo.contracts', N'installment_months') IS NULL
BEGIN
    ALTER TABLE dbo.contracts
        ADD installment_months INT NOT NULL
            CONSTRAINT DF_contracts_installment_months DEFAULT (0);
END;

IF COL_LENGTH(N'dbo.contracts', N'deposit_due') IS NULL
BEGIN
    ALTER TABLE dbo.contracts
        ADD deposit_due DECIMAL(15, 2) NOT NULL
            CONSTRAINT DF_contracts_deposit_due DEFAULT (0);
END;

-- Gia tam tinh: mo don 180 trieu, mo doi 390 trieu,
-- khu gia toc M7-M8 2,8 ty. Khong doi gia cac lo da co hop dong.
UPDATE p
SET p.price = CASE z.zone_code
    WHEN 'M2' THEN 390000000
    WHEN 'M7' THEN 2800000000
    WHEN 'M8' THEN 2800000000
    ELSE 180000000
END
FROM dbo.plots AS p
JOIN dbo.zones AS z ON z.id = p.zone_id
WHERE z.zone_code IN ('M1', 'M2', 'M3', 'M4', 'M5', 'M6', 'M7', 'M8')
  AND NOT EXISTS (
      SELECT 1 FROM dbo.contracts AS c WHERE c.plot_id = p.id
  );

COMMIT TRANSACTION;
GO

SELECT c.name AS cot_hop_dong_moi
FROM sys.columns AS c
WHERE c.object_id = OBJECT_ID(N'dbo.contracts')
  AND c.name IN ('beneficiary_name', 'beneficiary_relationship', 'installment_months', 'deposit_due');
GO
