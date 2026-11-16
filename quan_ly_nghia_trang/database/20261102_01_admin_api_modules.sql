/*
  Sala Garden - API administration modules.
  Run once on SQL Server database sala_garden_db after the existing additive scripts.
  This migration only adds columns, tables, and indexes. It never deletes business data.
*/
USE sala_garden_db;
GO
SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH(N'dbo.contracts', N'admin_status') IS NULL
  ALTER TABLE dbo.contracts ADD admin_status VARCHAR(20) NOT NULL CONSTRAINT DF_contracts_admin_status DEFAULT('APPROVED');
IF COL_LENGTH(N'dbo.contracts', N'beneficiary_name') IS NULL
  ALTER TABLE dbo.contracts ADD beneficiary_name NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.contracts', N'beneficiary_relationship') IS NULL
  ALTER TABLE dbo.contracts ADD beneficiary_relationship NVARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.contracts', N'installment_months') IS NULL
  ALTER TABLE dbo.contracts ADD installment_months INT NOT NULL CONSTRAINT DF_contracts_installment_months DEFAULT(0);
IF COL_LENGTH(N'dbo.contracts', N'deposit_due') IS NULL
  ALTER TABLE dbo.contracts ADD deposit_due DECIMAL(15,2) NOT NULL CONSTRAINT DF_contracts_deposit_due DEFAULT(0);
IF COL_LENGTH(N'dbo.contracts', N'admin_note') IS NULL
  ALTER TABLE dbo.contracts ADD admin_note NVARCHAR(1000) NULL;
IF COL_LENGTH(N'dbo.contracts', N'reviewed_by') IS NULL
  ALTER TABLE dbo.contracts ADD reviewed_by INT NULL;
IF COL_LENGTH(N'dbo.contracts', N'reviewed_at') IS NULL
  ALTER TABLE dbo.contracts ADD reviewed_at DATETIME2 NULL;

IF COL_LENGTH(N'dbo.deceased_profiles', N'record_code') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD record_code VARCHAR(50) NULL;
IF COL_LENGTH(N'dbo.deceased_profiles', N'qr_code') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD qr_code VARCHAR(100) NULL;
IF COL_LENGTH(N'dbo.deceased_profiles', N'workflow_status') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD workflow_status VARCHAR(30) NOT NULL CONSTRAINT DF_deceased_profiles_workflow_status DEFAULT('DRAFT');
IF COL_LENGTH(N'dbo.deceased_profiles', N'is_public') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD is_public BIT NOT NULL CONSTRAINT DF_deceased_profiles_is_public DEFAULT(0);
IF COL_LENGTH(N'dbo.deceased_profiles', N'guestbook_enabled') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD guestbook_enabled BIT NOT NULL CONSTRAINT DF_deceased_profiles_guestbook_enabled DEFAULT(1);
IF COL_LENGTH(N'dbo.deceased_profiles', N'incense_enabled') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD incense_enabled BIT NOT NULL CONSTRAINT DF_deceased_profiles_incense_enabled DEFAULT(1);
IF COL_LENGTH(N'dbo.deceased_profiles', N'updated_at') IS NULL
  ALTER TABLE dbo.deceased_profiles ADD updated_at DATETIME2 NOT NULL CONSTRAINT DF_deceased_profiles_updated_at DEFAULT(SYSUTCDATETIME());

IF COL_LENGTH(N'dbo.plots', N'latitude') IS NULL
  ALTER TABLE dbo.plots ADD latitude DECIMAL(10,7) NULL;
IF COL_LENGTH(N'dbo.plots', N'longitude') IS NULL
  ALTER TABLE dbo.plots ADD longitude DECIMAL(10,7) NULL;

-- SQL Server resolves index columns when compiling a batch. Start a new batch
-- after the ALTER TABLE statements so newly-added columns are visible below.
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.contracts') AND name = N'IX_contracts_admin_status')
  CREATE INDEX IX_contracts_admin_status ON dbo.contracts(admin_status, created_at DESC);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.deceased_profiles') AND name = N'UX_deceased_profiles_record_code')
  CREATE UNIQUE INDEX UX_deceased_profiles_record_code ON dbo.deceased_profiles(record_code) WHERE record_code IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.deceased_profiles') AND name = N'UX_deceased_profiles_qr_code')
  CREATE UNIQUE INDEX UX_deceased_profiles_qr_code ON dbo.deceased_profiles(qr_code) WHERE qr_code IS NOT NULL;

IF OBJECT_ID(N'dbo.funeral_requests', N'U') IS NULL
CREATE TABLE dbo.funeral_requests (
  id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  request_code VARCHAR(50) NOT NULL CONSTRAINT UQ_funeral_requests_code UNIQUE,
  customer_id INT NULL,
  plot_id INT NULL,
  deceased_name NVARCHAR(100) NOT NULL,
  contact_name NVARCHAR(100) NOT NULL,
  contact_phone VARCHAR(20) NOT NULL,
  scheduled_at DATETIME2 NULL,
  package_name NVARCHAR(150) NULL,
  estimated_amount DECIMAL(15,2) NULL,
  status VARCHAR(30) NOT NULL CONSTRAINT DF_funeral_requests_status DEFAULT('PENDING'),
  note NVARCHAR(2000) NULL,
  created_at DATETIME2 NOT NULL CONSTRAINT DF_funeral_requests_created_at DEFAULT(SYSUTCDATETIME()),
  updated_at DATETIME2 NOT NULL CONSTRAINT DF_funeral_requests_updated_at DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT FK_funeral_requests_customer FOREIGN KEY(customer_id) REFERENCES dbo.customers(id),
  CONSTRAINT FK_funeral_requests_plot FOREIGN KEY(plot_id) REFERENCES dbo.plots(id),
  CONSTRAINT CK_funeral_requests_status CHECK(status IN ('PENDING','CONFIRMED','IN_PROGRESS','COMPLETED','CANCELLED'))
);

IF OBJECT_ID(N'dbo.admin_audit_logs', N'U') IS NULL
CREATE TABLE dbo.admin_audit_logs (
  id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  actor_user_id INT NOT NULL,
  entity_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(80) NOT NULL,
  action_code VARCHAR(50) NOT NULL,
  detail_json NVARCHAR(MAX) NULL,
  created_at DATETIME2 NOT NULL CONSTRAINT DF_admin_audit_logs_created_at DEFAULT(SYSUTCDATETIME()),
  CONSTRAINT FK_admin_audit_logs_actor FOREIGN KEY(actor_user_id) REFERENCES dbo.users(id)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.funeral_requests') AND name = N'IX_funeral_requests_status_date')
  CREATE INDEX IX_funeral_requests_status_date ON dbo.funeral_requests(status, scheduled_at);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'dbo.admin_audit_logs') AND name = N'IX_admin_audit_logs_entity')
  CREATE INDEX IX_admin_audit_logs_entity ON dbo.admin_audit_logs(entity_type, entity_id, created_at DESC);

COMMIT TRANSACTION;
GO
