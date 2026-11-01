/*
  Chay bo sung tren SQL Server sau khi da tao database/sala_garden.sql.
  Khong chay lai file schema cu de tranh tao trung bang.
*/

IF OBJECT_ID(N'dbo.memorial_members', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.memorial_members (
        id INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        deceased_id INT NOT NULL,
        customer_id INT NOT NULL,
        granted_by_customer_id INT NOT NULL,
        relationship NVARCHAR(80) NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_memorial_members_created_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_memorial_members_deceased FOREIGN KEY (deceased_id)
            REFERENCES dbo.deceased_profiles(id) ON DELETE CASCADE,
        CONSTRAINT FK_memorial_members_customer FOREIGN KEY (customer_id)
            REFERENCES dbo.customers(id),
        CONSTRAINT FK_memorial_members_granted_by FOREIGN KEY (granted_by_customer_id)
            REFERENCES dbo.customers(id),
        CONSTRAINT UQ_memorial_members_deceased_customer UNIQUE (deceased_id, customer_id)
    );
END;
GO

IF OBJECT_ID(N'dbo.memorial_actions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.memorial_actions (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        deceased_id INT NOT NULL,
        user_id INT NOT NULL,
        action_type VARCHAR(20) NOT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_memorial_actions_created_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_memorial_actions_deceased FOREIGN KEY (deceased_id)
            REFERENCES dbo.deceased_profiles(id) ON DELETE CASCADE,
        CONSTRAINT FK_memorial_actions_user FOREIGN KEY (user_id)
            REFERENCES dbo.users(id),
        CONSTRAINT CK_memorial_actions_type CHECK (action_type IN ('INCENSE', 'FLOWER', 'FRUIT', 'BELL'))
    );
END;
GO

IF OBJECT_ID(N'dbo.memorial_guestbook', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.memorial_guestbook (
        id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        deceased_id INT NOT NULL,
        author_customer_id INT NOT NULL,
        author_name NVARCHAR(100) NOT NULL,
        relationship NVARCHAR(80) NULL,
        message NVARCHAR(2000) NOT NULL,
        created_at DATETIME2 NOT NULL CONSTRAINT DF_memorial_guestbook_created_at DEFAULT SYSUTCDATETIME(),
        CONSTRAINT FK_memorial_guestbook_deceased FOREIGN KEY (deceased_id)
            REFERENCES dbo.deceased_profiles(id) ON DELETE CASCADE,
        CONSTRAINT FK_memorial_guestbook_customer FOREIGN KEY (author_customer_id)
            REFERENCES dbo.customers(id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_memorial_members_customer' AND object_id = OBJECT_ID(N'dbo.memorial_members'))
    CREATE INDEX IX_memorial_members_customer ON dbo.memorial_members(customer_id, deceased_id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_memorial_actions_deceased_type' AND object_id = OBJECT_ID(N'dbo.memorial_actions'))
    CREATE INDEX IX_memorial_actions_deceased_type ON dbo.memorial_actions(deceased_id, action_type, created_at DESC);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'IX_memorial_guestbook_deceased_date' AND object_id = OBJECT_ID(N'dbo.memorial_guestbook'))
    CREATE INDEX IX_memorial_guestbook_deceased_date ON dbo.memorial_guestbook(deceased_id, created_at DESC);
GO
