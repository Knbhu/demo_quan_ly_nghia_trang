/*
   Sala Garden - bổ sung phân quyền, nhân sự, bảng giá và nhật ký quản trị.
   Chạy một lần trong database sala_garden_db. Script có thể chạy lại an toàn;
   không xóa hoặc tạo lại các bảng/dữ liệu nghiệp vụ đang có.
*/
SET NOCOUNT ON;
GO

IF OBJECT_ID(N'dbo.admin_staff_access', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.admin_staff_access (
        user_id INT NOT NULL CONSTRAINT PK_admin_staff_access PRIMARY KEY,
        is_super_admin BIT NOT NULL CONSTRAINT DF_admin_staff_access_super DEFAULT(0),
        created_at DATETIME2 NOT NULL CONSTRAINT DF_admin_staff_access_created DEFAULT(SYSUTCDATETIME()),
        updated_at DATETIME2 NOT NULL CONSTRAINT DF_admin_staff_access_updated DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT FK_admin_staff_access_user FOREIGN KEY(user_id) REFERENCES dbo.users(id)
    );
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID(N'dbo.admin_staff_access') AND name=N'UX_admin_one_super_admin')
    CREATE UNIQUE INDEX UX_admin_one_super_admin ON dbo.admin_staff_access(is_super_admin) WHERE is_super_admin=1;
GO

IF OBJECT_ID(N'dbo.system_role_permissions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.system_role_permissions (
        role_id INT NOT NULL,
        permission_code NVARCHAR(100) NOT NULL,
        allowed BIT NOT NULL CONSTRAINT DF_system_role_permissions_allowed DEFAULT(0),
        updated_by INT NULL,
        updated_at DATETIME2 NOT NULL CONSTRAINT DF_system_role_permissions_updated DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT PK_system_role_permissions PRIMARY KEY(role_id, permission_code),
        CONSTRAINT FK_system_role_permissions_role FOREIGN KEY(role_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_system_role_permissions_user FOREIGN KEY(updated_by) REFERENCES dbo.users(id)
    );
END;
GO

IF OBJECT_ID(N'dbo.system_user_zones', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.system_user_zones (
        user_id INT NOT NULL,
        zone_code VARCHAR(20) NOT NULL,
        granted_by INT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_system_user_zones_created DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT PK_system_user_zones PRIMARY KEY(user_id, zone_code),
        CONSTRAINT FK_system_user_zones_user FOREIGN KEY(user_id) REFERENCES dbo.users(id) ON DELETE CASCADE,
        CONSTRAINT FK_system_user_zones_zone FOREIGN KEY(zone_code) REFERENCES dbo.zones(zone_code),
        CONSTRAINT FK_system_user_zones_grantor FOREIGN KEY(granted_by) REFERENCES dbo.users(id)
    );
END;
GO

IF OBJECT_ID(N'dbo.admin_change_requests', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.admin_change_requests (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_admin_change_requests PRIMARY KEY,
        request_type VARCHAR(30) NOT NULL,
        payload_json NVARCHAR(MAX) NOT NULL,
        status VARCHAR(20) NOT NULL CONSTRAINT DF_admin_change_requests_status DEFAULT('PENDING'),
        requested_by INT NOT NULL,
        reviewed_by INT NULL,
        requested_at DATETIME2 NOT NULL CONSTRAINT DF_admin_change_requests_requested DEFAULT(SYSUTCDATETIME()),
        reviewed_at DATETIME2 NULL,
        review_note NVARCHAR(500) NULL,
        CONSTRAINT CK_admin_change_requests_json CHECK(ISJSON(payload_json)=1),
        CONSTRAINT CK_admin_change_requests_status CHECK(status IN ('PENDING','APPROVED','REJECTED')),
        CONSTRAINT FK_admin_change_requests_requester FOREIGN KEY(requested_by) REFERENCES dbo.users(id),
        CONSTRAINT FK_admin_change_requests_reviewer FOREIGN KEY(reviewed_by) REFERENCES dbo.users(id)
    );
END;
GO

IF OBJECT_ID(N'dbo.system_audit_logs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.system_audit_logs (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_system_audit_logs PRIMARY KEY,
        actor_user_id INT NULL,
        action NVARCHAR(100) NOT NULL,
        entity_type NVARCHAR(80) NOT NULL,
        entity_id NVARCHAR(100) NULL,
        before_json NVARCHAR(MAX) NULL,
        after_json NVARCHAR(MAX) NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_system_audit_logs_created DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT FK_system_audit_logs_actor FOREIGN KEY(actor_user_id) REFERENCES dbo.users(id)
    );
END;
GO

IF OBJECT_ID(N'dbo.service_price_versions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.service_price_versions (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_service_price_versions PRIMARY KEY,
        service_id INT NOT NULL,
        version_no INT NOT NULL,
        price DECIMAL(15,2) NOT NULL,
        effective_from DATETIME2 NOT NULL,
        status VARCHAR(20) NOT NULL,
        requested_by INT NOT NULL,
        approved_by INT NULL,
        approved_at DATETIME2 NULL,
        change_request_id INT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_service_price_versions_created DEFAULT(SYSUTCDATETIME()),
        CONSTRAINT UQ_service_price_versions_service_version UNIQUE(service_id, version_no),
        CONSTRAINT FK_service_price_versions_service FOREIGN KEY(service_id) REFERENCES dbo.services(id),
        CONSTRAINT FK_service_price_versions_requester FOREIGN KEY(requested_by) REFERENCES dbo.users(id),
        CONSTRAINT FK_service_price_versions_approver FOREIGN KEY(approved_by) REFERENCES dbo.users(id),
        CONSTRAINT FK_service_price_versions_request FOREIGN KEY(change_request_id) REFERENCES dbo.admin_change_requests(id)
    );
END;
GO

/* Chọn một Super Admin đầu tiên nếu chưa có; các lần chạy sau không đổi người. */
IF NOT EXISTS (SELECT 1 FROM dbo.admin_staff_access WHERE is_super_admin=1)
BEGIN
    DECLARE @FirstAdminId INT;
    SELECT TOP(1) @FirstAdminId=u.id
    FROM dbo.users AS u INNER JOIN dbo.roles AS r ON r.id=u.role_id
    WHERE r.role_name='ADMIN' AND u.is_active=1 ORDER BY u.id;
    IF @FirstAdminId IS NOT NULL
        INSERT INTO dbo.admin_staff_access(user_id,is_super_admin) VALUES(@FirstAdminId,1);
END;
GO

/* Khai báo quyền của các phân hệ quản trị. */
DECLARE @PermissionCatalog TABLE(permission_code NVARCHAR(100) PRIMARY KEY);
INSERT INTO @PermissionCatalog(permission_code) VALUES
 (N'overview.view'),(N'map.view'),(N'map.edit'),(N'contracts.view'),(N'contracts.create'),
 (N'contracts.approve'),(N'families.view'),(N'families.edit'),(N'memorial.view'),(N'memorial.edit'),
 (N'funeral.view'),(N'funeral.edit'),(N'care.view'),(N'care.approve'),(N'staff.view'),
 (N'staff.edit'),(N'settings.roles'),(N'settings.prices'),(N'reports.export');
INSERT INTO dbo.system_role_permissions(role_id,permission_code,allowed)
SELECT r.id,p.permission_code,
       CONVERT(BIT,CASE
         WHEN r.role_name='ADMIN' THEN 1
         WHEN r.role_name='STAFF' AND p.permission_code IN (N'overview.view',N'map.view',N'contracts.view',N'contracts.create',N'families.view',N'families.edit',N'memorial.view',N'care.view',N'care.approve',N'funeral.view',N'reports.export') THEN 1
         WHEN r.role_name='WORKER' AND p.permission_code IN (N'map.view',N'care.view',N'funeral.view') THEN 1
         WHEN r.role_name='CUSTOMER' AND p.permission_code IN (N'map.view',N'contracts.view',N'families.view',N'memorial.view',N'care.view') THEN 1
         ELSE 0 END)
FROM dbo.roles AS r CROSS JOIN @PermissionCatalog AS p
WHERE NOT EXISTS(SELECT 1 FROM dbo.system_role_permissions AS x WHERE x.role_id=r.id AND x.permission_code=p.permission_code);
GO

/* Lưu giá đang dùng thành version đầu tiên, không sửa giá hiện tại. */
INSERT INTO dbo.service_price_versions(service_id,version_no,price,effective_from,status,requested_by,approved_by,approved_at)
SELECT s.id,1,s.price,SYSUTCDATETIME(),'APPROVED',u.id,u.id,SYSUTCDATETIME()
FROM dbo.services AS s
CROSS JOIN (SELECT TOP(1) u.id FROM dbo.users AS u JOIN dbo.roles AS r ON r.id=u.role_id WHERE r.role_name='ADMIN' AND u.is_active=1 ORDER BY u.id) AS u
WHERE NOT EXISTS(SELECT 1 FROM dbo.service_price_versions AS v WHERE v.service_id=s.id);
GO
PRINT N'Đã bổ sung cấu hình quyền quản trị, phân khu nhân viên, yêu cầu duyệt, nhật ký và lịch sử giá.';
GO
