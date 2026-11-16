/* Demo data for the administration APIs. Run after 20261102_01_admin_api_modules.sql.
   Idempotent: existing customer, account, plot, contract, memorial and funeral data are retained. */
USE sala_garden_db;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @CustomerRoleId INT = (SELECT id FROM dbo.roles WHERE role_name = 'CUSTOMER');
IF @CustomerRoleId IS NULL THROW 51001, N'Khong tim thay role CUSTOMER.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.zones WHERE zone_code = 'DEMO')
  INSERT INTO dbo.zones(zone_code, zone_name, religion, total_plots) VALUES('DEMO', N'Khu trình diễn quản trị', 'ALL', 6);
DECLARE @DemoZoneId INT = (SELECT id FROM dbo.zones WHERE zone_code = 'DEMO');

;WITH plots AS (
  SELECT * FROM (VALUES
    ('DEMO-A01',1,1,'SINGLE',180000000),('DEMO-A02',1,2,'SINGLE',180000000),
    ('DEMO-B01',2,1,'DOUBLE',390000000),('DEMO-B02',2,2,'DOUBLE',390000000),
    ('DEMO-C01',3,1,'FAMILY',800000000),('DEMO-C02',3,2,'FAMILY',800000000)
  ) v(plot_code,row_num,col_num,plot_type,price)
)
INSERT INTO dbo.plots(zone_id,plot_code,row_num,col_num,plot_type,status,price)
SELECT @DemoZoneId, p.plot_code,p.row_num,p.col_num,p.plot_type,'AVAILABLE',p.price FROM plots p
WHERE NOT EXISTS (SELECT 1 FROM dbo.plots x WHERE x.plot_code=p.plot_code);

DECLARE @PasswordHash VARCHAR(255) = '$2a$12$XZyRa33WKLx2hcQuAJ/msuDc3GQTYXh35ixhBpbUH1OuV1MyMH91m';
;WITH people AS (
 SELECT * FROM (VALUES
 ('demo.an','Demo Nguyễn Văn An','0909000001','DEMO000001',N'Quận 1, TP. Hồ Chí Minh'),
 ('demo.linh','Demo Phạm Mỹ Linh','0909000002','DEMO000002',N'Bình Thạnh, TP. Hồ Chí Minh'),
 ('demo.hung','Demo Đỗ Văn Hùng','0909000003','DEMO000003',N'Biên Hòa, Đồng Nai')
 ) v(username,full_name,phone,identity_card,address)
)
INSERT INTO dbo.users(role_id,username,password_hash,full_name,phone,email,is_active)
SELECT @CustomerRoleId,p.username,@PasswordHash,p.full_name,p.phone,CONCAT(p.username,'@sala.demo'),1 FROM people p
WHERE NOT EXISTS(SELECT 1 FROM dbo.users u WHERE u.phone=p.phone);

;WITH people AS (
 SELECT * FROM (VALUES
 ('0909000001','Demo Nguyễn Văn An','DEMO000001',N'Quận 1, TP. Hồ Chí Minh'),
 ('0909000002','Demo Phạm Mỹ Linh','DEMO000002',N'Bình Thạnh, TP. Hồ Chí Minh'),
 ('0909000003','Demo Đỗ Văn Hùng','DEMO000003',N'Biên Hòa, Đồng Nai')
 ) v(phone,full_name,identity_card,address)
)
INSERT INTO dbo.customers(user_id,full_name,phone_number,identity_card,address)
SELECT u.id,p.full_name,p.phone,p.identity_card,p.address FROM people p JOIN dbo.users u ON u.phone=p.phone
WHERE NOT EXISTS(SELECT 1 FROM dbo.customers c WHERE c.identity_card=p.identity_card);

DECLARE @AnId INT=(SELECT id FROM dbo.customers WHERE identity_card='DEMO000001');
DECLARE @LinhId INT=(SELECT id FROM dbo.customers WHERE identity_card='DEMO000002');
DECLARE @HungId INT=(SELECT id FROM dbo.customers WHERE identity_card='DEMO000003');
DECLARE @A01 INT=(SELECT id FROM dbo.plots WHERE plot_code='DEMO-A01');
DECLARE @A02 INT=(SELECT id FROM dbo.plots WHERE plot_code='DEMO-A02');
DECLARE @B01 INT=(SELECT id FROM dbo.plots WHERE plot_code='DEMO-B01');

IF NOT EXISTS(SELECT 1 FROM dbo.contracts WHERE contract_code='DEMO-HD-001')
  INSERT INTO dbo.contracts(contract_code,customer_id,plot_id,total_amount,deposit_amount,payment_type,status,beneficiary_name,beneficiary_relationship,installment_months,deposit_due,admin_status)
  VALUES('DEMO-HD-001',@AnId,@A01,180000000,36000000,'INSTALLMENT_12','PENDING',N'Cụ Nguyễn Văn An',N'Con trai',12,36000000,'PENDING');
IF NOT EXISTS(SELECT 1 FROM dbo.contracts WHERE contract_code='DEMO-HD-002')
  INSERT INTO dbo.contracts(contract_code,customer_id,plot_id,total_amount,deposit_amount,payment_type,status,beneficiary_name,beneficiary_relationship,installment_months,deposit_due,admin_status)
  VALUES('DEMO-HD-002',@LinhId,@A02,180000000,90000000,'INSTALLMENT_12','ACTIVE',N'Bà Phạm Thị Hoa',N'Con gái',12,36000000,'APPROVED');
IF NOT EXISTS(SELECT 1 FROM dbo.contracts WHERE contract_code='DEMO-HD-003')
  INSERT INTO dbo.contracts(contract_code,customer_id,plot_id,total_amount,deposit_amount,payment_type,status,beneficiary_name,beneficiary_relationship,installment_months,deposit_due,admin_status)
  VALUES('DEMO-HD-003',@HungId,@B01,390000000,390000000,'LUMP_SUM','ACTIVE',N'Ông Đỗ Văn Minh',N'Con trai',0,390000000,'APPROVED');
UPDATE dbo.plots SET status='RESERVED' WHERE plot_code IN ('DEMO-A01','DEMO-A02','DEMO-B01');

DECLARE @C2 INT=(SELECT id FROM dbo.contracts WHERE contract_code='DEMO-HD-002');
DECLARE @C3 INT=(SELECT id FROM dbo.contracts WHERE contract_code='DEMO-HD-003');
IF NOT EXISTS(SELECT 1 FROM dbo.payments WHERE contract_id=@C2 AND payment_phase=1) INSERT INTO dbo.payments(contract_id,payment_phase,amount,payment_method,note) VALUES(@C2,1,90000000,'BANK_TRANSFER',N'Thanh toán demo đợt 1');
IF NOT EXISTS(SELECT 1 FROM dbo.payments WHERE contract_id=@C3 AND payment_phase=1) INSERT INTO dbo.payments(contract_id,payment_phase,amount,payment_method,note) VALUES(@C3,1,390000000,'BANK_TRANSFER',N'Thanh toán demo hoàn tất');

IF NOT EXISTS(SELECT 1 FROM dbo.deceased_profiles WHERE plot_id=@A02)
  INSERT INTO dbo.deceased_profiles(plot_id,full_name,dharma_name,date_of_birth,date_of_death,burial_date,biography,record_code,qr_code,workflow_status,is_public,guestbook_enabled,incense_enabled)
  VALUES(@A02,N'Bà Phạm Thị Hoa',N'Diệu Tâm','1945-03-20','2021-08-14','2021-08-18',N'Hồ sơ tưởng niệm dùng để trình diễn.', 'DEMO-HS-001','QR-DEMO-A02','ACTIVE',1,1,1);
IF NOT EXISTS(SELECT 1 FROM dbo.deceased_profiles WHERE plot_id=@B01)
  INSERT INTO dbo.deceased_profiles(plot_id,full_name,dharma_name,date_of_birth,date_of_death,burial_date,biography,record_code,qr_code,workflow_status,is_public,guestbook_enabled,incense_enabled)
  VALUES(@B01,N'Ông Đỗ Văn Minh',NULL,'1938-10-02','2024-01-11','2024-01-15',N'Hồ sơ chờ kiểm duyệt.', 'DEMO-HS-002','QR-DEMO-B01','PENDING',0,1,1);

IF NOT EXISTS(SELECT 1 FROM dbo.funeral_requests WHERE request_code='DEMO-TL-001')
  INSERT INTO dbo.funeral_requests(request_code,customer_id,plot_id,deceased_name,contact_name,contact_phone,scheduled_at,package_name,estimated_amount,status,note)
  VALUES('DEMO-TL-001',@HungId,@B01,N'Ông Đỗ Văn Minh',N'Demo Đỗ Văn Hùng','0909000003',DATEADD(day,3,SYSUTCDATETIME()),N'Gói Tang lễ An Nhiên',25000000,'PENDING',N'Lịch demo cần xác nhận.');

COMMIT TRANSACTION;
GO
