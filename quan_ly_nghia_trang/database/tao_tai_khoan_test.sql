-- Tao tai khoan thu nghiem cho cong Thân Nhan Sala Garden.
-- Dang nhap bang so dien thoai 1234567890 va mat khau trunganh.
-- Mat khau duoc luu duoi dang bcrypt; khong luu ban ro trong database.

USE sala_garden_db;
GO

SET XACT_ABORT ON;

DECLARE @Phone VARCHAR(20) = '1234567890';
DECLARE @FullName NVARCHAR(100) = N'Trung Anh (Tai khoan test)';
DECLARE @IdentityCard VARCHAR(20) = 'TEST1234567890';
DECLARE @PasswordHash VARCHAR(255) = '$2a$12$XZyRa33WKLx2hcQuAJ/msuDc3GQTYXh35ixhBpbUH1OuV1MyMH91m';
DECLARE @CustomerRoleId INT;
DECLARE @UserId INT;
DECLARE @CustomerId INT;

SELECT @CustomerRoleId = id
FROM dbo.roles
WHERE role_name = 'CUSTOMER';

IF @CustomerRoleId IS NULL
    THROW 51000, 'Khong tim thay role CUSTOMER trong database.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    SELECT @UserId = id
    FROM dbo.users WITH (UPDLOCK, HOLDLOCK)
    WHERE phone = @Phone;

    IF @UserId IS NOT NULL
       AND NOT EXISTS (
           SELECT 1 FROM dbo.users
           WHERE id = @UserId AND role_id = @CustomerRoleId
       )
        THROW 51001, 'So dien thoai da duoc dung boi tai khoan khong phai CUSTOMER; khong thay doi tai khoan do.', 1;

    IF @UserId IS NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM dbo.users WHERE username = @Phone)
            THROW 51002, 'Username 1234567890 da duoc tai khoan khac su dung.', 1;

        INSERT INTO dbo.users(role_id, username, password_hash, full_name, phone, is_active)
        VALUES(@CustomerRoleId, @Phone, @PasswordHash, @FullName, @Phone, 1);

        SET @UserId = CONVERT(INT, SCOPE_IDENTITY());
    END
    ELSE
    BEGIN
        -- Neu da tao tai khoan CUSTOMER truoc do, dat lai dung mat khau test nay.
        UPDATE dbo.users
        SET password_hash = @PasswordHash,
            full_name = @FullName,
            is_active = 1
        WHERE id = @UserId;
    END;

    SELECT @CustomerId = id
    FROM dbo.customers WITH (UPDLOCK, HOLDLOCK)
    WHERE user_id = @UserId;

    IF @CustomerId IS NOT NULL
    BEGIN
        UPDATE dbo.customers
        SET full_name = @FullName,
            phone_number = @Phone
        WHERE id = @CustomerId;
    END
    ELSE
    BEGIN
        SELECT @CustomerId = id
        FROM dbo.customers WITH (UPDLOCK, HOLDLOCK)
        WHERE identity_card = @IdentityCard;

        IF @CustomerId IS NOT NULL
        BEGIN
            IF EXISTS (
                SELECT 1 FROM dbo.customers
                WHERE id = @CustomerId AND user_id IS NOT NULL AND user_id <> @UserId
            )
                THROW 51003, 'Ma ho so test da lien ket voi tai khoan khac.', 1;

            UPDATE dbo.customers
            SET user_id = @UserId,
                full_name = @FullName,
                phone_number = @Phone
            WHERE id = @CustomerId;
        END
        ELSE
        BEGIN
            INSERT INTO dbo.customers(user_id, full_name, phone_number, identity_card)
            VALUES(@UserId, @FullName, @Phone, @IdentityCard);
        END;
    END;

    COMMIT TRANSACTION;

    SELECT u.id, u.phone, u.full_name, r.role_name AS role_name,
           c.identity_card, u.is_active
    FROM dbo.users AS u
    JOIN dbo.roles AS r ON r.id = u.role_id
    JOIN dbo.customers AS c ON c.user_id = u.id
    WHERE u.id = @UserId;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
