require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const sql = require('mssql');

const app = express();

// 1. CẤU HÌNH KẾT NỐI SQL SERVER (SQLEXPRESS)
const dbConfig = {
    user: process.env.DB_USER || 'sa',
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER || 'localhost\\SQLEXPRESS',
    database: process.env.DB_DATABASE || 'sala_garden_db',
    options: {
        encrypt: false,
        trustServerCertificate: true
    }
};

// Kết nối SQL Server Pool
const poolPromise = new sql.ConnectionPool(dbConfig)
    .connect()
    .then(pool => {
        console.log('✅ KẾT NỐI SQL SERVER (sala_garden_db) THÀNH CÔNG!');
        return pool;
    })
    .catch(err => {
        console.error('❌ LỖI KẾT NỐI SQL SERVER:', err.message);
        process.exit(1);
    });

app.use(helmet());
app.use(cors({ origin: process.env.CLIENT_ORIGIN?.split(',') || true }));
app.use(express.json({ limit: '2mb' }));

// Middleware tạo token JWT
const tokenFor = user => jwt.sign(
    { sub: user.id, role: user.role_name || user.role }, 
    process.env.JWT_SECRET || 'local-development-secret-change-me', 
    { expiresIn: '12h' }
);

// Middleware xác thực Auth Token
const auth = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.replace(/^Bearer\s+/i, '');
        if (!token) return res.status(401).json({ error: 'Vui lòng đăng nhập.' });
        req.user = jwt.verify(token, process.env.JWT_SECRET || 'local-development-secret-change-me'); 
        next();
    } catch { 
        res.status(401).json({ error: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.' }); 
    }
};

const asyncRoute = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);

// Các màn hình cấu hình hệ thống chỉ dành cho quản trị viên cấp cao.
const requireSuperAdmin = asyncRoute(async (req, res, next) => {
    if (String(req.user.role || '').toUpperCase() === 'ADMIN') return next();
    const pool = await poolPromise;
    const result = await pool.request()
        .input('userId', sql.Int, Number(req.user.sub))
        .query(`
            SELECT TOP 1 u.id, r.role_name, COALESCE(a.is_super_admin, 0) AS is_super_admin
            FROM users u
            JOIN roles r ON r.id = u.role_id
            LEFT JOIN admin_staff_access a ON a.user_id = u.id
            WHERE u.id = @userId AND u.is_active = 1
        `);
    const account = result.recordset[0];
    if (!account || (!account.is_super_admin && String(account.role_name).toUpperCase() !== 'ADMIN')) {
        return res.status(403).json({ error: 'Chỉ tài khoản quản trị cấp cao mới được truy cập cấu hình hệ thống.' });
    }
    next();
});

const requireAdmin = (req, res, next) => {
    if (String(req.user.role || '').toUpperCase() !== 'ADMIN') {
        return res.status(403).json({ error: 'Chức năng này chỉ dành cho quản trị viên.' });
    }
    next();
};

const writeAdminAudit = async (request, actorUserId, entityType, entityId, actionCode, detail = null) => {
    await request
        .input('auditActorUserId', sql.Int, Number(actorUserId))
        .input('auditEntityType', sql.VarChar(50), entityType)
        .input('auditEntityId', sql.VarChar(80), String(entityId))
        .input('auditActionCode', sql.VarChar(50), actionCode)
        .input('auditDetail', sql.NVarChar(sql.MAX), detail ? JSON.stringify(detail) : null)
        .query(`INSERT INTO dbo.admin_audit_logs(actor_user_id, entity_type, entity_id, action_code, detail_json)
                VALUES(@auditActorUserId, @auditEntityType, @auditEntityId, @auditActionCode, @auditDetail)`);
};

// ----------------------------------------------------
// 2. NHÓM API AUTH (ĐĂNG KÝ, ĐĂNG NHẬP, LẤY PROFILE)
// ----------------------------------------------------

app.get('/api/v1/health', (_req, res) => res.json({ status: 'ok', service: 'sala-garden-api' }));

// Dữ liệu cho màn hình Phân quyền & Cài đặt của Admin.
app.get('/api/v1/admin/settings', auth, requireSuperAdmin, asyncRoute(async (_req, res) => {
    const pool = await poolPromise;
    const [staff, roles, permissions, zones, services, priceRequests] = await Promise.all([
        pool.request().query(`SELECT u.id, u.username, u.full_name, u.phone, u.email, u.is_active, r.role_name, COALESCE(a.is_super_admin, 0) AS is_super_admin FROM users u JOIN roles r ON r.id = u.role_id LEFT JOIN admin_staff_access a ON a.user_id = u.id WHERE r.role_name <> 'CUSTOMER' ORDER BY u.full_name`),
        pool.request().query(`SELECT id, role_name, description FROM roles ORDER BY id`),
        pool.request().query(`SELECT role_id, permission_code, allowed FROM system_role_permissions ORDER BY role_id, permission_code`),
        pool.request().query(`SELECT id, zone_code, zone_name, total_plots FROM zones ORDER BY zone_code`),
        pool.request().query(`SELECT id, service_code, service_name, price, description FROM services ORDER BY service_name`),
        pool.request().query(`SELECT TOP 30 id, request_type, payload_json, status, requested_by, requested_at, reviewed_at, review_note FROM admin_change_requests ORDER BY requested_at DESC`)
    ]);
    res.json({ data: {
        staff: staff.recordset,
        roles: roles.recordset,
        permissions: permissions.recordset,
        zones: zones.recordset,
        services: services.recordset,
        priceRequests: priceRequests.recordset
    }});
}));

// Đăng ký tài khoản thân nhân và liên kết hồ sơ CCCD nếu đã có
app.post('/api/v1/auth/register', asyncRoute(async (req, res) => {
  const fullName = String(req.body.fullName || '').trim();
  const phone = String(req.body.phone || '').trim();
  const password = String(req.body.password || '');
  const nationalId = String(req.body.nationalId || '').trim();
  if (!fullName || !phone || !password || !nationalId) {
    return res.status(400).json({ error: 'Cần họ tên, số điện thoại, CCCD/hộ chiếu và mật khẩu.' });
  }
  if (password.length < 8) return res.status(400).json({ error: 'Mật khẩu cần ít nhất 8 ký tự.' });
  if (nationalId.length < 8 || nationalId.length > 20) {
    return res.status(400).json({ error: 'Số CCCD/hộ chiếu chưa hợp lệ.' });
  }

  const pool = await poolPromise;
  const transaction = new sql.Transaction(pool);
  await transaction.begin();
  try {
    const matched = await transaction.request()
      .input('nationalId', sql.VarChar(20), nationalId)
      .query('SELECT id, user_id FROM customers WHERE identity_card = @nationalId');
    const existingCustomer = matched.recordset[0];
    if (existingCustomer && existingCustomer.user_id != null) {
      await transaction.rollback();
      return res.status(409).json({ error: 'CCCD/hộ chiếu này đã liên kết với một tài khoản.' });
    }

    const hash = await bcrypt.hash(password, 12);
    const created = await transaction.request()
      .input('role_id', sql.Int, 4)
      .input('username', sql.VarChar(100), phone)
      .input('phone', sql.VarChar(20), phone)
      .input('password_hash', sql.VarChar(255), hash)
      .input('full_name', sql.NVarChar(100), fullName)
      .query('INSERT INTO users(role_id, username, phone, password_hash, full_name) OUTPUT INSERTED.id, INSERTED.phone, INSERTED.full_name, INSERTED.role_id VALUES(@role_id, @username, @phone, @password_hash, @full_name)');
    const newUser = created.recordset[0];

    if (existingCustomer) {
      await transaction.request()
        .input('customerId', sql.Int, existingCustomer.id)
        .input('userId', sql.Int, newUser.id)
        .query('UPDATE customers SET user_id = @userId WHERE id = @customerId AND user_id IS NULL');
    } else {
      await transaction.request()
        .input('userId', sql.Int, newUser.id)
        .input('fullName', sql.NVarChar(100), fullName)
        .input('phone', sql.VarChar(20), phone)
        .input('nationalId', sql.VarChar(20), nationalId)
        .query('INSERT INTO customers(user_id, full_name, phone_number, identity_card) VALUES(@userId, @fullName, @phone, @nationalId)');
    }

    await transaction.commit();
    res.status(201).json({ user: newUser, token: tokenFor({ id: newUser.id, role: 'CUSTOMER' }) });
  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}));
// Đăng nhập
app.post('/api/v1/auth/login', asyncRoute(async (req, res) => {
    const identifier = String(req.body.phone || req.body.username || '').trim();
    const { password } = req.body;
    if (!identifier || !password) {
        return res.status(400).json({ error: 'Vui lòng nhập số điện thoại hoặc username và mật khẩu.' });
    }
    const pool = await poolPromise;
    
    const result = await pool.request()
        .input('identifier', sql.VarChar(100), identifier)
        .query(`
            SELECT u.*, r.role_name 
            FROM users u 
            JOIN roles r ON u.role_id = r.id 
            WHERE u.phone = @identifier OR u.username = @identifier
        `);

    const user = result.recordset[0];
    if (!user || !await bcrypt.compare(password || '', user.password_hash)) {
        return res.status(401).json({ error: 'Số điện thoại, username hoặc mật khẩu không đúng.' });
    }

    delete user.password_hash;
    res.json({ user, token: tokenFor(user) });
}));

// Lấy thông tin tài khoản hiện tại
app.get('/api/v1/auth/me', auth, asyncRoute(async (req, res) => {
    const pool = await poolPromise;
    const result = await pool.request()
        .input('id', sql.Int, req.user.sub)
        .query(`
            SELECT u.id, u.phone, u.full_name, r.role_name AS role, u.email 
            FROM users u 
            JOIN roles r ON u.role_id = r.id 
            WHERE u.id = @id
        `);

    if (!result.recordset[0]) return res.status(404).json({ error: 'Không tìm thấy tài khoản.' }); 
    res.json({ user: result.recordset[0] });
}));

// Số liệu tổng quan an toàn cho trang thân nhân.
app.get('/api/v1/customer/dashboard-summary', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        return res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
    }
    const pool = await poolPromise;
    const result = await pool.request()
        .input('userId', sql.Int, req.user.sub)
        .query(`
            SELECT
                (SELECT COUNT(*) FROM plots) AS totalPlots,
                (SELECT COUNT(*) FROM deceased_profiles) AS deceasedCount,
                (SELECT COUNT(*) FROM plots WHERE status = 'AVAILABLE') AS availablePlots,
                (SELECT COUNT(*) FROM contracts c JOIN customers cust ON cust.id = c.customer_id
                    WHERE cust.user_id = @userId) AS customerContracts,
                (SELECT COUNT(*) FROM care_orders co JOIN customers cust ON cust.id = co.customer_id
                    WHERE cust.user_id = @userId) AS customerCareOrders
        `);
    res.json({ data: result.recordset[0] });
}));

// ----------------------------------------------------
// 3. NHÓM API Ô MỘ (PLOTS)
// ----------------------------------------------------

// Tra cứu công khai yêu cầu khớp đủ họ tên, mã phần mộ, mã định danh riêng và năm sinh.
app.post('/api/v1/public/graves/lookup', asyncRoute(async (req, res) => {
    const { fullName, plotCode, plotIdentifier, birthYear } = req.body;
    const year = Number(birthYear);
    if (!fullName || !plotCode || !plotIdentifier || !Number.isInteger(year) || year < 1800 || year > new Date().getFullYear()) {
        return res.status(400).json({ error: 'Vui lòng nhập đủ thông tin tra cứu hợp lệ.' });
    }
    const pool = await poolPromise;
    const result = await pool.request()
        .input('fullName', sql.NVarChar(100), String(fullName).trim())
        .input('plotCode', sql.VarChar(50), String(plotCode).trim())
        .input('plotIdentifier', sql.VarChar(80), String(plotIdentifier).trim())
        .input('birthYear', sql.Int, year)
        .query(`
            SELECT TOP (1) d.full_name, d.dharma_name, d.date_of_birth, d.date_of_death,
                p.plot_code, p.plot_type, p.status, p.row_num, p.col_num,
                p.latitude, p.longitude, z.zone_code, z.zone_name
            FROM plots p
            JOIN zones z ON z.id = p.zone_id
            JOIN deceased_profiles d ON d.plot_id = p.id
            WHERE LOWER(LTRIM(RTRIM(d.full_name))) = LOWER(@fullName)
                AND p.plot_code = @plotCode
                AND p.plot_identifier = @plotIdentifier
                AND YEAR(d.date_of_birth) = @birthYear
        `);
    if (!result.recordset[0]) {
        return res.status(404).json({ error: 'Không tìm thấy hồ sơ phù hợp. Vui lòng kiểm tra lại thông tin.' });
    }
    res.json({ data: result.recordset[0] });
}));

// Lấy danh sách ô mộ (Phân trang & Tìm kiếm)
app.get('/api/v1/plots', asyncRoute(async (req, res) => {
    const limit = Math.min(Math.max(parseInt(req.query.limit, 10) || 50, 1), 200);
    const offset = Math.max(parseInt(req.query.offset, 10) || 0, 0);

    const pool = await poolPromise;
    const request = pool.request();
    let where = 'WHERE 1=1';

    if (req.query.status) {
        request.input('status', sql.VarChar, req.query.status);
        where += ' AND p.status = @status';
    }
    if (req.query.zone) {
        request.input('zoneCode', sql.VarChar(20), String(req.query.zone).trim());
        where += ' AND z.zone_code = @zoneCode';
    }
    if (req.query.search) {
        request.input('search', sql.NVarChar, `%${req.query.search}%`);
        where += ' AND (p.plot_code LIKE @search OR z.zone_name LIKE @search)';
    }

    const totalResult = await request.query(`SELECT COUNT(*) AS total FROM plots p JOIN zones z ON p.zone_id = z.id ${where}`);
    const total = totalResult.recordset[0].total;

    request.input('limit', sql.Int, limit);
    request.input('offset', sql.Int, offset);

    // Cú pháp phân trang chuẩn T-SQL của SQL Server (OFFSET ... FETCH NEXT)
    const rowsResult = await request.query(`
        SELECT p.id, p.zone_id, p.plot_code, p.row_num, p.col_num, p.plot_type,
            p.status, p.price, p.qr_code_url, p.created_at,
            z.zone_name, z.zone_code 
        FROM plots p 
        JOIN zones z ON p.zone_id = z.id 
        ${where} 
        ORDER BY z.zone_code, p.row_num, p.col_num 
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `);

    res.json({ data: rowsResult.recordset, total, limit, offset });
}));

// Danh sách phân khu và số lượng ô mộ thực tế để dựng bộ lọc sơ đồ.
app.get('/api/v1/zones', auth, asyncRoute(async (req, res) => {
    if (!['CUSTOMER', 'ADMIN', 'STAFF'].includes(req.user.role)) {
        return res.status(403).json({ error: 'Bạn không có quyền xem sơ đồ phân khu.' });
    }
    const pool = await poolPromise;
    const result = await pool.request().query(`
        SELECT z.zone_code, z.zone_name, COUNT(p.id) AS plot_count
        FROM zones z
        LEFT JOIN plots p ON p.zone_id = z.id
        GROUP BY z.zone_code, z.zone_name
        ORDER BY z.zone_code
    `);
    res.json({ data: result.recordset });
}));

// Tổng hợp trạng thái toàn phân khu (không trả dữ liệu hồ sơ cá nhân).
app.get('/api/v1/plots/summary', auth, asyncRoute(async (req, res) => {
    if (!['CUSTOMER', 'ADMIN', 'STAFF'].includes(req.user.role)) {
        return res.status(403).json({ error: 'Bạn không có quyền xem sơ đồ phân khu.' });
    }
    const pool = await poolPromise;
    const request = pool.request();
    let where = '';
    if (req.query.zone) {
        request.input('zoneCode', sql.VarChar(20), req.query.zone);
        where = 'WHERE z.zone_code = @zoneCode';
    }
    const result = await request.query(`
        SELECT COUNT(p.id) AS total,
            COALESCE(SUM(CASE WHEN p.status = 'AVAILABLE' THEN 1 ELSE 0 END), 0) AS available,
            COALESCE(SUM(CASE WHEN p.status IN ('RESERVED', 'DEPOSITED') THEN 1 ELSE 0 END), 0) AS reserved,
            COALESCE(SUM(CASE WHEN p.status = 'OCCUPIED' THEN 1 ELSE 0 END), 0) AS occupied,
            COALESCE(SUM(CASE WHEN p.status = 'MAINTENANCE' THEN 1 ELSE 0 END), 0) AS maintenance
        FROM plots p
        JOIN zones z ON z.id = p.zone_id
        ${where}
    `);
    res.json({ data: result.recordset[0] });
}));

// Chi tiết 1 ô mộ
app.get('/api/v1/plots/:id', auth, asyncRoute(async (req, res) => {
    const pool = await poolPromise;
    const request = pool.request().input('id', sql.VarChar, req.params.id);
    let ownership = '';
    if (req.user.role === 'CUSTOMER') {
        request.input('userId', sql.Int, req.user.sub);
        ownership = `AND EXISTS (
            SELECT 1 FROM contracts c
            JOIN customers cust ON cust.id = c.customer_id
            WHERE c.plot_id = p.id AND cust.user_id = @userId
        )`;
    } else if (!['ADMIN', 'STAFF'].includes(req.user.role)) {
        return res.status(403).json({ error: 'Bạn không có quyền xem hồ sơ phần mộ này.' });
    }
    const result = await request
        .query(`
            SELECT p.id, p.zone_id, p.plot_code, p.row_num, p.col_num, p.plot_type,
                p.status, p.price, p.qr_code_url, p.created_at,
                d.full_name AS memorial_name, d.dharma_name, d.date_of_birth,
                d.date_of_death, d.burial_date, d.biography,
                contract_info.contract_code, contract_info.payment_type,
                contract_info.contract_status, contract_info.customer_name,
                contract_info.customer_phone, contract_info.customer_address
            FROM plots p 
            LEFT JOIN deceased_profiles d ON d.plot_id = p.id 
            OUTER APPLY (
                SELECT TOP 1 c.contract_code, c.payment_type,
                    c.status AS contract_status, cust.full_name AS customer_name,
                    cust.phone_number AS customer_phone, cust.address AS customer_address
                FROM contracts c
                JOIN customers cust ON cust.id = c.customer_id
                WHERE c.plot_id = p.id
                    ${req.user.role === 'CUSTOMER' ? 'AND cust.user_id = @userId' : ''}
                ORDER BY c.created_at DESC
            ) contract_info
            WHERE (CAST(p.id AS VARCHAR) = @id OR p.plot_code = @id) ${ownership}
        `);

    if (!result.recordset[0]) return res.status(404).json({ error: 'Không tìm thấy ô mộ.' }); 
    res.json({ data: result.recordset[0] });
}));

// ----------------------------------------------------
// 4. KHONG GIAN TUONG NIEM (MEMORIALS)
// ----------------------------------------------------

const customerOnly = (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
        return false;
    }
    return true;
};

async function memorialAccess(pool, memorialId, userId) {
    const result = await pool.request()
        .input('memorialId', sql.Int, memorialId)
        .input('userId', sql.Int, userId)
        .query(`
            SELECT d.id,
                CASE WHEN EXISTS (
                    SELECT 1 FROM contracts c
                    JOIN customers owner_customer ON owner_customer.id = c.customer_id
                    JOIN plots owner_plot ON owner_plot.id = c.plot_id
                    WHERE owner_plot.id = d.plot_id
                        AND owner_customer.user_id = @userId
                        AND c.status <> 'CANCELLED'
                ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS can_manage_access
            FROM deceased_profiles d
            WHERE d.id = @memorialId AND (
                EXISTS (
                    SELECT 1 FROM contracts c
                    JOIN customers cust ON cust.id = c.customer_id
                    WHERE c.plot_id = d.plot_id
                        AND cust.user_id = @userId
                        AND c.status <> 'CANCELLED'
                ) OR EXISTS (
                    SELECT 1 FROM memorial_members mm
                    JOIN customers member_customer ON member_customer.id = mm.customer_id
                    WHERE mm.deceased_id = d.id AND member_customer.user_id = @userId
                )
            )
        `);
    return result.recordset[0] || null;
}

app.get('/api/v1/customer/memorials', auth, asyncRoute(async (req, res) => {
    if (!customerOnly(req, res)) return;
    const pool = await poolPromise;
    const result = await pool.request()
        .input('userId', sql.Int, req.user.sub)
        .query(`
            SELECT DISTINCT d.id, d.full_name, d.dharma_name,
                d.date_of_birth, d.date_of_death, d.burial_date,
                d.avatar_url, d.biography, d.full_name AS memorial_name,
                p.plot_code, z.zone_name,
                (SELECT COUNT(*) FROM memorial_actions a
                    WHERE a.deceased_id = d.id AND a.action_type = 'INCENSE') AS incense_count,
                (SELECT COUNT(*) FROM memorial_actions a
                    WHERE a.deceased_id = d.id AND a.action_type = 'FLOWER') AS flower_count,
                (SELECT COUNT(*) FROM memorial_actions a
                    WHERE a.deceased_id = d.id AND a.action_type = 'FRUIT') AS fruit_count,
                (SELECT COUNT(*) FROM memorial_actions a
                    WHERE a.deceased_id = d.id AND a.action_type = 'BELL') AS bell_count,
                CASE WHEN EXISTS (
                    SELECT 1 FROM contracts c
                    JOIN customers owner_customer ON owner_customer.id = c.customer_id
                    WHERE c.plot_id = p.id
                        AND owner_customer.user_id = @userId
                        AND c.status <> 'CANCELLED'
                ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS can_manage_access
            FROM deceased_profiles d
            JOIN plots p ON p.id = d.plot_id
            JOIN zones z ON z.id = p.zone_id
            WHERE EXISTS (
                SELECT 1 FROM contracts c
                JOIN customers cust ON cust.id = c.customer_id
                WHERE c.plot_id = p.id AND cust.user_id = @userId
                    AND c.status <> 'CANCELLED'
            ) OR EXISTS (
                SELECT 1 FROM memorial_members mm
                JOIN customers member_customer ON member_customer.id = mm.customer_id
                WHERE mm.deceased_id = d.id AND member_customer.user_id = @userId
            )
            ORDER BY d.full_name
        `);
    const data = result.recordset.map(row => ({
        ...row,
        action_counts: {
            INCENSE: row.incense_count,
            FLOWER: row.flower_count,
            FRUIT: row.fruit_count,
            BELL: row.bell_count
        }
    }));
    res.json({ data });
}));

app.post('/api/v1/customer/memorials/:id/actions', auth, asyncRoute(async (req, res) => {
    if (!customerOnly(req, res)) return;
    const memorialId = Number(req.params.id);
    const actionType = String(req.body.actionType || '').trim().toUpperCase();
    const allowedActions = ['INCENSE', 'FLOWER', 'FRUIT', 'BELL'];
    if (!Number.isInteger(memorialId) || !allowedActions.includes(actionType)) {
        return res.status(400).json({ error: 'Nghi lễ hoặc hồ sơ tưởng niệm không hợp lệ.' });
    }
    const pool = await poolPromise;
    if (!await memorialAccess(pool, memorialId, req.user.sub)) {
        return res.status(404).json({ error: 'Hồ sơ không tồn tại hoặc tài khoản chưa được cấp quyền xem.' });
    }
    await pool.request()
        .input('memorialId', sql.Int, memorialId)
        .input('userId', sql.Int, req.user.sub)
        .input('actionType', sql.VarChar(20), actionType)
        .query(`
            INSERT INTO memorial_actions(deceased_id, user_id, action_type)
            VALUES(@memorialId, @userId, @actionType)
        `);
    const countsResult = await pool.request()
        .input('memorialId', sql.Int, memorialId)
        .query(`
            SELECT action_type, COUNT(*) AS action_count
            FROM memorial_actions
            WHERE deceased_id = @memorialId
            GROUP BY action_type
        `);
    const actionCounts = { INCENSE: 0, FLOWER: 0, FRUIT: 0, BELL: 0 };
    for (const row of countsResult.recordset) actionCounts[row.action_type] = row.action_count;
    res.status(201).json({ data: { action_counts: actionCounts } });
}));

app.get('/api/v1/customer/memorials/:id/guestbook', auth, asyncRoute(async (req, res) => {
    if (!customerOnly(req, res)) return;
    const memorialId = Number(req.params.id);
    if (!Number.isInteger(memorialId)) return res.status(400).json({ error: 'Hồ sơ tưởng niệm không hợp lệ.' });
    const pool = await poolPromise;
    if (!await memorialAccess(pool, memorialId, req.user.sub)) {
        return res.status(404).json({ error: 'Hồ sơ không tồn tại hoặc tài khoản chưa được cấp quyền xem.' });
    }
    const result = await pool.request()
        .input('memorialId', sql.Int, memorialId)
        .query(`
            SELECT TOP 100 id, deceased_id, author_customer_id, author_name,
                relationship, message, created_at
            FROM memorial_guestbook
            WHERE deceased_id = @memorialId
            ORDER BY created_at DESC, id DESC
        `);
    res.json({ data: result.recordset });
}));

app.post('/api/v1/customer/memorials/:id/guestbook', auth, asyncRoute(async (req, res) => {
    if (!customerOnly(req, res)) return;
    const memorialId = Number(req.params.id);
    const authorName = String(req.body.authorName || '').trim();
    const relationship = String(req.body.relationship || '').trim();
    const message = String(req.body.message || '').trim();
    if (!Number.isInteger(memorialId) || !authorName || !message || message.length > 2000) {
        return res.status(400).json({ error: 'Vui lòng nhập tên người gửi và lời tri ân (tối đa 2.000 ký tự).' });
    }
    const pool = await poolPromise;
    if (!await memorialAccess(pool, memorialId, req.user.sub)) {
        return res.status(404).json({ error: 'Hồ sơ không tồn tại hoặc tài khoản chưa được cấp quyền xem.' });
    }
    const author = await pool.request()
        .input('userId', sql.Int, req.user.sub)
        .query('SELECT TOP 1 id FROM customers WHERE user_id = @userId');
    const customerId = author.recordset[0]?.id;
    if (!customerId) return res.status(403).json({ error: 'Tài khoản chưa có hồ sơ thân nhân.' });
    const result = await pool.request()
        .input('memorialId', sql.Int, memorialId)
        .input('customerId', sql.Int, customerId)
        .input('authorName', sql.NVarChar(100), authorName)
        .input('relationship', sql.NVarChar(80), relationship || null)
        .input('message', sql.NVarChar(2000), message)
        .query(`
            INSERT INTO memorial_guestbook(deceased_id, author_customer_id, author_name, relationship, message)
            OUTPUT INSERTED.id, INSERTED.deceased_id, INSERTED.author_customer_id,
                INSERTED.author_name, INSERTED.relationship, INSERTED.message, INSERTED.created_at
            VALUES(@memorialId, @customerId, @authorName, @relationship, @message)
        `);
    res.status(201).json({ data: result.recordset[0] });
}));

// Chu ho theo hop dong co the cap quyen xem cho tai khoan than nhan khac.
app.post('/api/v1/customer/memorials/:id/members', auth, asyncRoute(async (req, res) => {
    if (!customerOnly(req, res)) return;
    const memorialId = Number(req.params.id);
    const phone = String(req.body.phone || '').trim();
    const relationship = String(req.body.relationship || '').trim();
    if (!Number.isInteger(memorialId) || !phone) {
        return res.status(400).json({ error: 'Cần mã hồ sơ và số điện thoại tài khoản được mời.' });
    }
    const pool = await poolPromise;
    const memorial = await memorialAccess(pool, memorialId, req.user.sub);
    if (!memorial) return res.status(404).json({ error: 'Không tìm thấy hồ sơ tưởng niệm.' });
    if (!memorial.can_manage_access) {
        return res.status(403).json({ error: 'Chỉ thân nhân đứng tên hợp đồng mới có thể mời người xem.' });
    }
    const ownerResult = await pool.request()
        .input('userId', sql.Int, req.user.sub)
        .query('SELECT TOP 1 id FROM customers WHERE user_id = @userId');
    const ownerCustomerId = ownerResult.recordset[0]?.id;
    if (!ownerCustomerId) return res.status(403).json({ error: 'Tài khoản chưa có hồ sơ thân nhân.' });

    const targetResult = await pool.request()
        .input('phone', sql.VarChar(20), phone)
        .query(`
            SELECT TOP 1 cust.id, cust.user_id
            FROM customers cust
            JOIN users u ON u.id = cust.user_id
            WHERE cust.phone_number = @phone OR u.phone = @phone
        `);
    const target = targetResult.recordset[0];
    if (!target) return res.status(404).json({ error: 'Chưa tìm thấy tài khoản thân nhân với số điện thoại này.' });
    if (target.user_id === req.user.sub) return res.status(400).json({ error: 'Đây là tài khoản của bạn.' });

    await pool.request()
        .input('memorialId', sql.Int, memorialId)
        .input('customerId', sql.Int, target.id)
        .input('ownerCustomerId', sql.Int, ownerCustomerId)
        .input('relationship', sql.NVarChar(80), relationship || null)
        .query(`
            IF NOT EXISTS (
                SELECT 1 FROM memorial_members
                WHERE deceased_id = @memorialId AND customer_id = @customerId
            )
            INSERT INTO memorial_members(deceased_id, customer_id, granted_by_customer_id, relationship)
            VALUES(@memorialId, @customerId, @ownerCustomerId, @relationship)
        `);
    res.status(201).json({ data: { shared: true } });
}));

// ----------------------------------------------------
// 5. NHÓM API HỢP ĐỒNG (CONTRACTS)
// ----------------------------------------------------

// Lập hợp đồng mua mộ mới
app.post('/api/v1/contracts', auth, asyncRoute(async (req, res) => {
    const plotId = Number(req.body.plotId);
    const customerName = String(req.body.customerName || '').trim();
    const customerPhone = String(req.body.customerPhone || '').trim();
    const identityCard = String(req.body.identityCard || '').trim();
    const address = String(req.body.address || '').trim();
    const beneficiaryName = String(req.body.beneficiaryName || '').trim();
    const beneficiaryRelationship = String(req.body.beneficiaryRelationship || '').trim();
    const paymentType = String(req.body.paymentType || '').toUpperCase();
    const installmentMonths = paymentType === 'INSTALLMENT_12'
        ? Number(req.body.installmentMonths)
        : 0;

    if (!Number.isInteger(plotId) || plotId <= 0 ||
        !customerName || customerName.length > 100 ||
        !customerPhone || customerPhone.length > 20 ||
        !identityCard || identityCard.length > 20 ||
        !beneficiaryName || beneficiaryName.length > 100 ||
        !beneficiaryRelationship || beneficiaryRelationship.length > 100 ||
        !['INSTALLMENT_12', 'LUMP_SUM'].includes(paymentType) ||
        (paymentType === 'INSTALLMENT_12' && installmentMonths !== 12)) {
        return res.status(400).json({ error: 'Vui lòng kiểm tra đầy đủ thông tin lập hợp đồng.' });
    }

    const pool = await poolPromise;
    const transaction = new sql.Transaction(pool);
    let transactionStarted = false;

    try {
        await transaction.begin();
        transactionStarted = true;

        // Khóa lô để tránh hai tài khoản cùng lập hồ sơ cho một vị trí.
        const plotResult = await transaction.request()
            .input('plotId', sql.Int, plotId)
            .query(`
                SELECT p.id, p.status, p.plot_code, p.plot_type, z.zone_code,
                    z.zone_name,
                    CASE z.zone_code
                        WHEN 'M2' THEN CAST(390000000 AS DECIMAL(15, 2))
                        WHEN 'M7' THEN CAST(2800000000 AS DECIMAL(15, 2))
                        WHEN 'M8' THEN CAST(2800000000 AS DECIMAL(15, 2))
                        WHEN 'M1' THEN CAST(180000000 AS DECIMAL(15, 2))
                        WHEN 'M3' THEN CAST(180000000 AS DECIMAL(15, 2))
                        WHEN 'M4' THEN CAST(180000000 AS DECIMAL(15, 2))
                        WHEN 'M5' THEN CAST(180000000 AS DECIMAL(15, 2))
                        WHEN 'M6' THEN CAST(180000000 AS DECIMAL(15, 2))
                        ELSE p.price
                    END AS quote_price
                FROM dbo.plots AS p WITH (UPDLOCK, HOLDLOCK)
                JOIN dbo.zones AS z ON z.id = p.zone_id
                WHERE p.id = @plotId
            `);
        const plot = plotResult.recordset[0];
        if (!plot) {
            await transaction.rollback();
            transactionStarted = false;
            return res.status(404).json({ error: 'Không tìm thấy ô mộ.' });
        }
        if (plot.status !== 'AVAILABLE') {
            await transaction.rollback();
            transactionStarted = false;
            return res.status(409).json({ error: 'Ô mộ này không còn trống để lập hợp đồng.' });
        }

        const accountResult = await transaction.request()
            .input('userId', sql.Int, req.user.sub)
            .query(`
                SELECT u.id, c.id AS customer_id
                FROM dbo.users AS u
                LEFT JOIN dbo.customers AS c ON c.user_id = u.id
                WHERE u.id = @userId
            `);
        const account = accountResult.recordset[0];
        if (!account) {
            await transaction.rollback();
            transactionStarted = false;
            return res.status(401).json({ error: 'Phiên đăng nhập không còn hợp lệ.' });
        }

        let customerId = account.customer_id;
        if (customerId) {
            await transaction.request()
                .input('customerId', sql.Int, customerId)
                .input('customerName', sql.NVarChar(100), customerName)
                .input('customerPhone', sql.VarChar(20), customerPhone)
                .input('identityCard', sql.VarChar(20), identityCard)
                .input('address', sql.NVarChar(sql.MAX), address || null)
                .query(`
                    UPDATE dbo.customers
                    SET full_name = @customerName,
                        phone_number = @customerPhone,
                        identity_card = @identityCard,
                        address = @address
                    WHERE id = @customerId
                `);
        } else {
            const customerResult = await transaction.request()
                .input('userId', sql.Int, req.user.sub)
                .input('customerName', sql.NVarChar(100), customerName)
                .input('customerPhone', sql.VarChar(20), customerPhone)
                .input('identityCard', sql.VarChar(20), identityCard)
                .input('address', sql.NVarChar(sql.MAX), address || null)
                .query(`
                    INSERT INTO dbo.customers(user_id, full_name, phone_number, identity_card, address)
                    OUTPUT INSERTED.id
                    VALUES(@userId, @customerName, @customerPhone, @identityCard, @address)
                `);
            customerId = customerResult.recordset[0].id;
        }

        const contractCode = `SG-${Date.now()}`;
        const totalAmount = Number(plot.quote_price);
        const depositDue = paymentType === 'INSTALLMENT_12'
            ? Math.round(totalAmount * 0.2)
            : totalAmount;
        const contractResult = await transaction.request()
            .input('code', sql.VarChar(50), contractCode)
            .input('customerId', sql.Int, customerId)
            .input('plotId', sql.Int, plotId)
            .input('totalAmount', sql.Decimal(15, 2), totalAmount)
            .input('paymentType', sql.VarChar(30), paymentType)
            .input('beneficiaryName', sql.NVarChar(100), beneficiaryName)
            .input('beneficiaryRelationship', sql.NVarChar(100), beneficiaryRelationship)
            .input('installmentMonths', sql.Int, installmentMonths)
            .input('depositDue', sql.Decimal(15, 2), depositDue)
            .query(`
                INSERT INTO dbo.contracts(
                    contract_code, customer_id, plot_id, total_amount,
                    deposit_amount, payment_type, status, beneficiary_name,
                    beneficiary_relationship, installment_months, deposit_due
                )
                OUTPUT INSERTED.*
                VALUES(
                    @code, @customerId, @plotId, @totalAmount,
                    0, @paymentType, 'PENDING', @beneficiaryName,
                    @beneficiaryRelationship, @installmentMonths, @depositDue
                )
            `);

        await transaction.request()
            .input('plotId', sql.Int, plotId)
            .query("UPDATE dbo.plots SET status = 'RESERVED' WHERE id = @plotId");

        await transaction.commit();
        transactionStarted = false;
        res.status(201).json({
            data: {
                ...contractResult.recordset[0],
                plot_code: plot.plot_code,
                plot_type: plot.plot_type,
                zone_code: plot.zone_code,
                zone_name: plot.zone_name,
                quote_price: totalAmount
            }
        });
    } catch (error) {
        if (transactionStarted) await transaction.rollback();
        throw error;
    }
}));

// Lấy danh sách hợp đồng của thân nhân
app.get('/api/v1/contracts/customer/:id', auth, asyncRoute(async (req, res) => {
    if (String(req.user.sub) !== String(req.params.id) && !['ADMIN', 'STAFF'].includes(req.user.role)) {
        return res.status(403).json({ error: 'Bạn không có quyền xem hồ sơ này.' });
    }

    const pool = await poolPromise;
    const result = await pool.request()
        .input('userId', sql.Int, req.params.id)
        .query(`
            SELECT c.*, p.plot_code, p.plot_type, p.price AS plot_price,
                p.row_num, p.col_num, p.latitude, p.longitude, z.zone_code, z.zone_name,
                cust.full_name AS customer_name, cust.phone_number AS customer_phone,
                cust.address AS customer_address,
                COALESCE(deceased.full_name, c.beneficiary_name) AS beneficiary_display_name,
                c.beneficiary_relationship, c.installment_months, c.deposit_due,
                deceased.dharma_name,
                ISNULL((SELECT SUM(pay.amount) FROM payments pay WHERE pay.contract_id = c.id),
                    ISNULL(c.deposit_amount, 0)) AS amount_paid,
                (SELECT COUNT(*) FROM payments pay WHERE pay.contract_id = c.id) AS payment_count,
                (SELECT MAX(pay.payment_date) FROM payments pay WHERE pay.contract_id = c.id) AS last_payment_at
            FROM contracts c 
            JOIN customers cust ON c.customer_id = cust.id
            JOIN plots p ON p.id = c.plot_id 
            JOIN zones z ON p.zone_id = z.id
            LEFT JOIN deceased_profiles deceased ON deceased.plot_id = p.id
            WHERE cust.user_id = @userId 
            ORDER BY c.created_at DESC
        `);

    res.json({ data: result.recordset });
}));

// Lấy các giao dịch thực tế của một hợp đồng thuộc tài khoản hiện tại.
app.get('/api/v1/contracts/:id/payments', auth, asyncRoute(async (req, res) => {
    const contractId = Number(req.params.id);
    if (!Number.isInteger(contractId) || contractId <= 0) {
        return res.status(400).json({ error: 'Mã hợp đồng chưa hợp lệ.' });
    }

    const pool = await poolPromise;
    const isStaff = ['ADMIN', 'STAFF'].includes(req.user.role);
    const result = await pool.request()
        .input('contractId', sql.Int, contractId)
        .input('userId', sql.Int, req.user.sub)
        .input('isStaff', sql.Bit, isStaff)
        .query(`
            SELECT pay.id, pay.contract_id, pay.payment_phase, pay.amount,
                pay.payment_date, pay.payment_method, pay.receipt_url, pay.note
            FROM payments pay
            JOIN contracts c ON c.id = pay.contract_id
            JOIN customers cust ON cust.id = c.customer_id
            WHERE c.id = @contractId
                AND (@isStaff = 1 OR cust.user_id = @userId)
            ORDER BY pay.payment_date DESC, pay.payment_phase DESC
        `);

    // A contract with no payments is a valid empty list; unauthorized IDs are hidden.
    if (!isStaff) {
        const owned = await pool.request()
            .input('contractId', sql.Int, contractId)
            .input('userId', sql.Int, req.user.sub)
            .query(`
                SELECT c.id
                FROM contracts c
                JOIN customers cust ON cust.id = c.customer_id
                WHERE c.id = @contractId AND cust.user_id = @userId
            `);
        if (!owned.recordset[0]) {
            return res.status(404).json({ error: 'Không tìm thấy hợp đồng.' });
        }
    }

    res.json({ data: result.recordset });
}));

// ----------------------------------------------------
// 5A. NHÓM API QUẢN TRỊ (không gồm phân công nhân sự)
// ----------------------------------------------------

app.get('/api/v1/admin/dashboard', auth, requireAdmin, asyncRoute(async (_req, res) => {
    const pool = await poolPromise;
    const result = await pool.request().query(`
        SELECT
          (SELECT COUNT(*) FROM dbo.contracts) AS contracts_total,
          (SELECT COUNT(*) FROM dbo.contracts WHERE admin_status = 'PENDING') AS contracts_pending,
          (SELECT COUNT(*) FROM dbo.contracts WHERE admin_status = 'APPROVED') AS contracts_approved,
          (SELECT COUNT(*) FROM dbo.customers) AS customers_total,
          (SELECT COUNT(*) FROM dbo.deceased_profiles WHERE workflow_status IN ('PENDING','CHANGE_PENDING')) AS memorials_pending,
          (SELECT COUNT(*) FROM dbo.funeral_requests WHERE status IN ('PENDING','CONFIRMED','IN_PROGRESS')) AS funerals_open,
          (SELECT ISNULL(SUM(amount), 0) FROM dbo.payments) AS payments_collected,
          (SELECT ISNULL(SUM(total_amount), 0) FROM dbo.contracts) AS contracts_value
    `);
    res.json({ data: result.recordset[0] });
}));

app.get('/api/v1/admin/contracts', auth, requireAdmin, asyncRoute(async (req, res) => {
    const query = String(req.query.q || '').trim();
    const status = String(req.query.status || '').trim().toUpperCase();
    const pool = await poolPromise;
    const result = await pool.request()
        .input('query', sql.NVarChar(100), query || null)
        .input('status', sql.VarChar(20), status || null)
        .query(`
          SELECT c.id, c.contract_code, c.total_amount, c.deposit_amount, c.deposit_due,
            c.payment_type, c.status, c.admin_status, c.admin_note, c.created_at, c.reviewed_at,
            cust.full_name AS customer_name, cust.phone_number AS customer_phone, cust.identity_card,
            p.plot_code, p.plot_type, z.zone_code, c.beneficiary_name, c.installment_months,
            ISNULL((SELECT SUM(pay.amount) FROM dbo.payments pay WHERE pay.contract_id=c.id),0) AS amount_paid
          FROM dbo.contracts c
          JOIN dbo.customers cust ON cust.id=c.customer_id
          JOIN dbo.plots p ON p.id=c.plot_id JOIN dbo.zones z ON z.id=p.zone_id
          WHERE (@status IS NULL OR c.admin_status=@status)
            AND (@query IS NULL OR c.contract_code LIKE '%' + @query + '%' OR cust.full_name LIKE '%' + @query + '%'
              OR cust.identity_card LIKE '%' + @query + '%' OR p.plot_code LIKE '%' + @query + '%')
          ORDER BY c.created_at DESC`);
    res.json({ data: result.recordset });
}));

app.post('/api/v1/admin/contracts/:id/action', auth, requireAdmin, asyncRoute(async (req, res) => {
    const contractId = Number(req.params.id);
    const action = String(req.body.action || '').toUpperCase();
    const note = String(req.body.note || '').trim();
    if (!Number.isInteger(contractId) || !['APPROVE', 'REJECT', 'REQUEST_CHANGES'].includes(action)) {
        return res.status(400).json({ error: 'Thao tác hợp đồng không hợp lệ.' });
    }
    const pool = await poolPromise;
    const transaction = new sql.Transaction(pool);
    await transaction.begin();
    try {
        const found = await transaction.request().input('contractId', sql.Int, contractId).query(
            `SELECT c.id,c.plot_id,c.admin_status,(SELECT COUNT(*) FROM dbo.payments p WHERE p.contract_id=c.id) AS payment_count
             FROM dbo.contracts c WITH (UPDLOCK,HOLDLOCK) WHERE c.id=@contractId`);
        const contract = found.recordset[0];
        if (!contract) { await transaction.rollback(); return res.status(404).json({ error: 'Không tìm thấy hợp đồng.' }); }
        if (!['PENDING', 'CHANGE_REQUESTED'].includes(contract.admin_status)) {
            await transaction.rollback();
            return res.status(409).json({ error: 'Hợp đồng đã được xử lý, không thể thay đổi trạng thái này.' });
        }
        const adminStatus = action === 'APPROVE' ? 'APPROVED' : action === 'REJECT' ? 'REJECTED' : 'CHANGE_REQUESTED';
        const businessStatus = action === 'APPROVE' ? 'ACTIVE' : action === 'REJECT' ? 'CANCELLED' : 'PENDING';
        await transaction.request().input('contractId', sql.Int, contractId).input('adminStatus', sql.VarChar(20), adminStatus)
          .input('businessStatus', sql.VarChar(30), businessStatus).input('note', sql.NVarChar(1000), note || null)
          .input('reviewedBy', sql.Int, req.user.sub).query(`UPDATE dbo.contracts SET admin_status=@adminStatus,status=@businessStatus,admin_note=@note,reviewed_by=@reviewedBy,reviewed_at=SYSUTCDATETIME() WHERE id=@contractId`);
        if (action === 'REJECT' && Number(contract.payment_count) === 0) {
            await transaction.request().input('plotId', sql.Int, contract.plot_id).query("UPDATE dbo.plots SET status='AVAILABLE' WHERE id=@plotId AND status='RESERVED'");
        }
        await writeAdminAudit(transaction.request(), req.user.sub, 'CONTRACT', contractId, action, { note });
        await transaction.commit();
        res.json({ data: { id: contractId, admin_status: adminStatus, status: businessStatus } });
    } catch (error) { if (transaction._aborted !== true) await transaction.rollback().catch(() => {}); throw error; }
}));

app.get('/api/v1/admin/families', auth, requireAdmin, asyncRoute(async (req, res) => {
    const query = String(req.query.q || '').trim();
    const pool = await poolPromise;
    const result = await pool.request().input('query', sql.NVarChar(100), query || null).query(`
      SELECT c.id, CONCAT('KH-', RIGHT('000000' + CAST(c.id AS VARCHAR(6)), 6)) AS customer_code,
        c.full_name, c.phone_number, c.identity_card, c.address, u.email, u.is_active,
        COUNT(DISTINCT con.id) AS contract_count, COUNT(DISTINCT con.plot_id) AS plot_count,
        STRING_AGG(DISTINCT p.plot_code, ', ') AS plot_codes
      FROM dbo.customers c LEFT JOIN dbo.users u ON u.id=c.user_id
      LEFT JOIN dbo.contracts con ON con.customer_id=c.id LEFT JOIN dbo.plots p ON p.id=con.plot_id
      WHERE @query IS NULL OR c.full_name LIKE '%' + @query + '%' OR c.phone_number LIKE '%' + @query + '%'
        OR c.identity_card LIKE '%' + @query + '%' OR p.plot_code LIKE '%' + @query + '%'
      GROUP BY c.id,c.full_name,c.phone_number,c.identity_card,c.address,u.email,u.is_active ORDER BY c.full_name`);
    res.json({ data: result.recordset });
}));

app.get('/api/v1/admin/families/:id', auth, requireAdmin, asyncRoute(async (req, res) => {
    const customerId = Number(req.params.id); if (!Number.isInteger(customerId)) return res.status(400).json({ error: 'Mã thân nhân không hợp lệ.' });
    const pool = await poolPromise;
    const result = await pool.request().input('customerId', sql.Int, customerId).query(`
      SELECT c.*,u.email,u.is_active FROM dbo.customers c LEFT JOIN dbo.users u ON u.id=c.user_id WHERE c.id=@customerId;
      SELECT con.*,p.plot_code,p.plot_type,z.zone_name FROM dbo.contracts con JOIN dbo.plots p ON p.id=con.plot_id JOIN dbo.zones z ON z.id=p.zone_id WHERE con.customer_id=@customerId ORDER BY con.created_at DESC;
      SELECT d.id,d.record_code,d.full_name,d.workflow_status,d.qr_code,p.plot_code FROM dbo.memorial_members mm JOIN dbo.deceased_profiles d ON d.id=mm.deceased_id JOIN dbo.plots p ON p.id=d.plot_id WHERE mm.customer_id=@customerId;`);
    if (!result.recordsets[0][0]) return res.status(404).json({ error: 'Không tìm thấy thân nhân.' });
    res.json({ data: { profile: result.recordsets[0][0], contracts: result.recordsets[1], memorials: result.recordsets[2] } });
}));

app.post('/api/v1/admin/families', auth, requireAdmin, asyncRoute(async (req, res) => {
    const fullName = String(req.body.fullName || '').trim();
    const phone = String(req.body.phone || '').trim();
    const identityCard = String(req.body.identityCard || '').trim();
    const address = String(req.body.address || '').trim();
    if (!fullName || !phone || !identityCard) {
        return res.status(400).json({ error: 'Cần họ tên, số điện thoại và CCCD/hộ chiếu.' });
    }
    const pool = await poolPromise;
    const result = await pool.request()
        .input('fullName', sql.NVarChar(100), fullName)
        .input('phone', sql.VarChar(20), phone)
        .input('identityCard', sql.VarChar(20), identityCard)
        .input('address', sql.NVarChar(sql.MAX), address || null)
        .query(`INSERT INTO dbo.customers(full_name,phone_number,identity_card,address)
          OUTPUT INSERTED.id,INSERTED.full_name,INSERTED.phone_number,INSERTED.identity_card,INSERTED.address
          VALUES(@fullName,@phone,@identityCard,@address)`);
    await writeAdminAudit(pool.request(), req.user.sub, 'CUSTOMER', result.recordset[0].id, 'CREATE');
    res.status(201).json({ data: result.recordset[0] });
}));

app.get('/api/v1/admin/memorials', auth, requireAdmin, asyncRoute(async (req, res) => {
    const status = String(req.query.status || '').trim().toUpperCase(); const query = String(req.query.q || '').trim();
    const pool = await poolPromise;
    const result = await pool.request().input('status', sql.VarChar(30), status || null).input('query', sql.NVarChar(100), query || null).query(`
      SELECT d.*,p.plot_code,z.zone_code,c.full_name AS primary_customer_name,
        (SELECT COUNT(*) FROM dbo.memorial_members mm WHERE mm.deceased_id=d.id) AS member_count
      FROM dbo.deceased_profiles d JOIN dbo.plots p ON p.id=d.plot_id JOIN dbo.zones z ON z.id=p.zone_id
      LEFT JOIN dbo.contracts con ON con.plot_id=p.id LEFT JOIN dbo.customers c ON c.id=con.customer_id
      WHERE (@status IS NULL OR d.workflow_status=@status) AND (@query IS NULL OR d.full_name LIKE '%' + @query + '%' OR p.plot_code LIKE '%' + @query + '%' OR d.qr_code LIKE '%' + @query + '%')
      ORDER BY d.updated_at DESC`);
    res.json({ data: result.recordset });
}));

app.post('/api/v1/admin/memorials', auth, requireAdmin, asyncRoute(async (req, res) => {
    let plotId=Number(req.body.plotId); const plotCode=String(req.body.plotCode || '').trim(); const fullName=String(req.body.fullName || '').trim();
    const workflowStatus=['DRAFT','PENDING'].includes(String(req.body.workflowStatus || '').toUpperCase()) ? String(req.body.workflowStatus).toUpperCase() : 'PENDING';
    const pool=await poolPromise;
    if (!Number.isInteger(plotId) && plotCode) {
      const plot=await pool.request().input('plotCode',sql.VarChar(50),plotCode).query('SELECT id FROM dbo.plots WHERE plot_code=@plotCode');
      plotId=Number(plot.recordset[0]?.id);
    }
    if (!Number.isInteger(plotId) || !fullName) return res.status(400).json({ error: 'Cần chọn ô mộ hợp lệ và nhập họ tên người quá cố.' });
    const recordCode=`HS-${Date.now()}`; const qrCode=`QR-${Date.now()}`;
    const result=await pool.request().input('plotId',sql.Int,plotId).input('fullName',sql.NVarChar(100),fullName).input('dharmaName',sql.NVarChar(100),String(req.body.dharmaName || '').trim() || null)
      .input('recordCode',sql.VarChar(50),recordCode).input('qrCode',sql.VarChar(100),qrCode).input('workflowStatus',sql.VarChar(30),workflowStatus).input('isPublic',sql.Bit,Boolean(req.body.isPublic)).input('guestbookEnabled',sql.Bit,req.body.guestbookEnabled !== false).input('incenseEnabled',sql.Bit,req.body.incenseEnabled !== false)
      .query(`INSERT INTO dbo.deceased_profiles(plot_id,full_name,dharma_name,record_code,qr_code,workflow_status,is_public,guestbook_enabled,incense_enabled)
        OUTPUT INSERTED.* VALUES(@plotId,@fullName,@dharmaName,@recordCode,@qrCode,@workflowStatus,@isPublic,@guestbookEnabled,@incenseEnabled)`);
    await writeAdminAudit(pool.request(),req.user.sub,'MEMORIAL',result.recordset[0].id,'CREATE',{recordCode});
    res.status(201).json({ data: result.recordset[0] });
}));

app.post('/api/v1/admin/memorials/:id/action', auth, requireAdmin, asyncRoute(async (req, res) => {
    const memorialId=Number(req.params.id); const action=String(req.body.action || '').toUpperCase();
    const allowed={APPROVE:'ACTIVE',REJECT:'REJECTED',REQUEST_CHANGES:'CHANGE_PENDING'};
    if (!Number.isInteger(memorialId)||!allowed[action]) return res.status(400).json({ error: 'Thao tác hồ sơ không hợp lệ.' });
    const pool=await poolPromise; const result=await pool.request().input('id',sql.Int,memorialId).input('status',sql.VarChar(30),allowed[action]).query('UPDATE dbo.deceased_profiles SET workflow_status=@status, updated_at=SYSUTCDATETIME() OUTPUT INSERTED.* WHERE id=@id');
    if(!result.recordset[0]) return res.status(404).json({error:'Không tìm thấy hồ sơ tưởng niệm.'});
    await writeAdminAudit(pool.request(),req.user.sub,'MEMORIAL',memorialId,action);
    res.json({data:result.recordset[0]});
}));

app.post('/api/v1/admin/memorials/:id/settings', auth, requireAdmin, asyncRoute(async (req, res) => {
    const memorialId=Number(req.params.id); if(!Number.isInteger(memorialId)) return res.status(400).json({error:'Mã hồ sơ không hợp lệ.'});
    const pool=await poolPromise; const result=await pool.request().input('id',sql.Int,memorialId).input('isPublic',sql.Bit,Boolean(req.body.isPublic)).input('guestbookEnabled',sql.Bit,Boolean(req.body.guestbookEnabled)).input('incenseEnabled',sql.Bit,Boolean(req.body.incenseEnabled)).query(`UPDATE dbo.deceased_profiles SET is_public=@isPublic,guestbook_enabled=@guestbookEnabled,incense_enabled=@incenseEnabled,updated_at=SYSUTCDATETIME() OUTPUT INSERTED.* WHERE id=@id`);
    if(!result.recordset[0]) return res.status(404).json({error:'Không tìm thấy hồ sơ tưởng niệm.'});
    await writeAdminAudit(pool.request(),req.user.sub,'MEMORIAL',memorialId,'UPDATE_SETTINGS'); res.json({data:result.recordset[0]});
}));

app.get('/api/v1/admin/funerals', auth, requireAdmin, asyncRoute(async (_req,res)=>{
    const pool=await poolPromise; const result=await pool.request().query(`SELECT f.*,p.plot_code,c.full_name AS customer_name FROM dbo.funeral_requests f LEFT JOIN dbo.plots p ON p.id=f.plot_id LEFT JOIN dbo.customers c ON c.id=f.customer_id ORDER BY f.scheduled_at DESC,f.created_at DESC`); res.json({data:result.recordset});
}));
app.post('/api/v1/admin/funerals', auth, requireAdmin, asyncRoute(async (req,res)=>{
    const deceasedName=String(req.body.deceasedName || '').trim(),contactName=String(req.body.contactName || '').trim(),contactPhone=String(req.body.contactPhone || '').trim();
    if(!deceasedName||!contactName||!contactPhone) return res.status(400).json({error:'Cần tên người quá cố và thông tin liên hệ.'});
    const pool=await poolPromise; const code=`TL-${Date.now()}`; const result=await pool.request().input('code',sql.VarChar(50),code).input('deceasedName',sql.NVarChar(100),deceasedName).input('contactName',sql.NVarChar(100),contactName).input('contactPhone',sql.VarChar(20),contactPhone).input('scheduledAt',sql.DateTime2,req.body.scheduledAt ? new Date(req.body.scheduledAt) : null).input('packageName',sql.NVarChar(150),String(req.body.packageName || '').trim() || null).input('note',sql.NVarChar(2000),String(req.body.note || '').trim() || null).query(`INSERT INTO dbo.funeral_requests(request_code,deceased_name,contact_name,contact_phone,scheduled_at,package_name,note) OUTPUT INSERTED.* VALUES(@code,@deceasedName,@contactName,@contactPhone,@scheduledAt,@packageName,@note)`); await writeAdminAudit(pool.request(),req.user.sub,'FUNERAL',result.recordset[0].id,'CREATE');res.status(201).json({data:result.recordset[0]});
}));
app.post('/api/v1/admin/funerals/:id/status', auth, requireAdmin, asyncRoute(async (req,res)=>{
    const id=Number(req.params.id),status=String(req.body.status || '').toUpperCase(); if(!Number.isInteger(id)||!['PENDING','CONFIRMED','IN_PROGRESS','COMPLETED','CANCELLED'].includes(status)) return res.status(400).json({error:'Trạng thái tang lễ không hợp lệ.'}); const pool=await poolPromise; const result=await pool.request().input('id',sql.Int,id).input('status',sql.VarChar(30),status).query('UPDATE dbo.funeral_requests SET status=@status,updated_at=SYSUTCDATETIME() OUTPUT INSERTED.* WHERE id=@id'); if(!result.recordset[0])return res.status(404).json({error:'Không tìm thấy yêu cầu tang lễ.'}); await writeAdminAudit(pool.request(),req.user.sub,'FUNERAL',id,'UPDATE_STATUS',{status});res.json({data:result.recordset[0]});
}));

app.get('/api/v1/admin/plots/gps', auth, requireAdmin, asyncRoute(async (_req,res)=>{const pool=await poolPromise;const result=await pool.request().query('SELECT p.id,p.plot_code,p.latitude,p.longitude,p.row_num,p.col_num,z.zone_code,z.zone_name FROM dbo.plots p JOIN dbo.zones z ON z.id=p.zone_id ORDER BY z.zone_code,p.row_num,p.col_num');res.json({data:result.recordset});}));
app.post('/api/v1/admin/plots/:id/gps', auth, requireAdmin, asyncRoute(async (req,res)=>{const id=Number(req.params.id),latitude=Number(req.body.latitude),longitude=Number(req.body.longitude);if(!Number.isInteger(id)||!Number.isFinite(latitude)||!Number.isFinite(longitude)||latitude < -90||latitude>90||longitude < -180||longitude>180)return res.status(400).json({error:'Tọa độ GPS không hợp lệ.'});const pool=await poolPromise;const result=await pool.request().input('id',sql.Int,id).input('latitude',sql.Decimal(10,7),latitude).input('longitude',sql.Decimal(10,7),longitude).query('UPDATE dbo.plots SET latitude=@latitude,longitude=@longitude OUTPUT INSERTED.id,INSERTED.plot_code,INSERTED.latitude,INSERTED.longitude WHERE id=@id');if(!result.recordset[0])return res.status(404).json({error:'Không tìm thấy ô mộ.'});await writeAdminAudit(pool.request(),req.user.sub,'PLOT',id,'UPDATE_GPS');res.json({data:result.recordset[0]});}));

app.post('/api/v1/admin/users', auth, requireSuperAdmin, asyncRoute(async (req, res) => {
    const fullName=String(req.body.fullName || '').trim(), username=String(req.body.username || '').trim(), phone=String(req.body.phone || '').trim(), password=String(req.body.password || ''), roleName=String(req.body.roleName || '').toUpperCase();
    if(!fullName||!username||!phone||password.length<8||!['ADMIN','STAFF','WORKER'].includes(roleName)) return res.status(400).json({error:'Thông tin tài khoản nhân viên chưa hợp lệ.'});
    const pool=await poolPromise; const role=await pool.request().input('roleName',sql.VarChar(50),roleName).query('SELECT id FROM dbo.roles WHERE role_name=@roleName');
    if(!role.recordset[0]) return res.status(400).json({error:'Vai trò không tồn tại.'});
    const hash=await bcrypt.hash(password,12); const result=await pool.request().input('roleId',sql.Int,role.recordset[0].id).input('username',sql.VarChar(100),username).input('passwordHash',sql.VarChar(255),hash).input('fullName',sql.NVarChar(100),fullName).input('phone',sql.VarChar(20),phone).input('email',sql.VarChar(100),String(req.body.email || '').trim() || null).query(`INSERT INTO dbo.users(role_id,username,password_hash,full_name,phone,email,is_active) OUTPUT INSERTED.id,INSERTED.username,INSERTED.full_name,INSERTED.phone,INSERTED.email VALUES(@roleId,@username,@passwordHash,@fullName,@phone,@email,1)`);
    await writeAdminAudit(pool.request(),req.user.sub,'USER',result.recordset[0].id,'CREATE',{roleName}); res.status(201).json({data:result.recordset[0]});
}));

app.post('/api/v1/admin/services', auth, requireSuperAdmin, asyncRoute(async (req,res)=>{
    const serviceCode=String(req.body.serviceCode || '').trim().toUpperCase(),serviceName=String(req.body.serviceName || '').trim(),price=Number(req.body.price);
    if(!serviceCode||!serviceName||!Number.isFinite(price)||price<0)return res.status(400).json({error:'Thông tin dịch vụ chưa hợp lệ.'}); const pool=await poolPromise;
    const result=await pool.request().input('serviceCode',sql.VarChar(30),serviceCode).input('serviceName',sql.NVarChar(150),serviceName).input('price',sql.Decimal(15,2),price).input('description',sql.NVarChar(sql.MAX),String(req.body.description || '').trim() || null).query('INSERT INTO dbo.services(service_code,service_name,price,description) OUTPUT INSERTED.* VALUES(@serviceCode,@serviceName,@price,@description)');await writeAdminAudit(pool.request(),req.user.sub,'SERVICE',result.recordset[0].id,'CREATE');res.status(201).json({data:result.recordset[0]});
}));

app.post('/api/v1/admin/roles/:id/permissions', auth, requireSuperAdmin, asyncRoute(async (req,res)=>{
    const roleId=Number(req.params.id); const permissions=Array.isArray(req.body.permissions) ? req.body.permissions : [];
    if(!Number.isInteger(roleId)||permissions.length===0||permissions.some(item=>!item||typeof item.code!=='string'||typeof item.allowed!=='boolean')) return res.status(400).json({error:'Danh sách quyền không hợp lệ.'});
    const pool=await poolPromise; const transaction=new sql.Transaction(pool); await transaction.begin();
    try {
        const role=await transaction.request().input('roleId',sql.Int,roleId).query('SELECT id FROM dbo.roles WHERE id=@roleId');
        if(!role.recordset[0]) { await transaction.rollback(); return res.status(404).json({error:'Không tìm thấy vai trò.'}); }
        for(const permission of permissions) {
            const code=permission.code.trim().toUpperCase(); if(!code || code.length>100) { await transaction.rollback(); return res.status(400).json({error:'Mã quyền không hợp lệ.'}); }
            await transaction.request().input('roleId',sql.Int,roleId).input('code',sql.VarChar(100),code).input('allowed',sql.Bit,permission.allowed).query(`IF EXISTS(SELECT 1 FROM dbo.system_role_permissions WHERE role_id=@roleId AND permission_code=@code)
                UPDATE dbo.system_role_permissions SET allowed=@allowed WHERE role_id=@roleId AND permission_code=@code
              ELSE INSERT INTO dbo.system_role_permissions(role_id,permission_code,allowed) VALUES(@roleId,@code,@allowed)`);
        }
        await writeAdminAudit(transaction.request(),req.user.sub,'ROLE',roleId,'UPDATE_PERMISSIONS',{count:permissions.length}); await transaction.commit();
        res.json({data:{role_id:roleId,updated:permissions.length}});
    } catch(error) { await transaction.rollback().catch(()=>{}); throw error; }
}));

// ----------------------------------------------------
// 5. NHÓM API DỊCH VỤ CHĂM SÓC (CARE ORDERS)
// ----------------------------------------------------

// Danh mục dịch vụ chăm sóc dành cho thân nhân.
app.get('/api/v1/care-services', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        return res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
    }
    const pool = await poolPromise;
    const result = await pool.request().query(`
        SELECT id, service_code, service_name, price, description
        FROM services
        WHERE service_code IN ('FLOWER_RAM', 'CLEANING_MONTH', 'ANNIVERSARY_VEG', 'BONSAI_MONTHLY', 'LANTERN_RELEASE')
        ORDER BY id
    `);
    res.json({ data: result.recordset });
}));

// Chỉ trả về đơn chăm sóc thuộc khách hàng đang đăng nhập.
app.get('/api/v1/care-orders', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        return res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
    }
    const pool = await poolPromise;
    const result = await pool.request()
        .input('userId', sql.Int, req.user.sub)
        .query(`
            SELECT co.id, co.order_code, co.plot_id, co.scheduled_date,
                co.status, co.note, s.service_name, s.price AS service_price,
                p.plot_code, z.zone_name, proof_data.proof_images_json
            FROM care_orders co
            JOIN customers cust ON cust.id = co.customer_id
            JOIN services s ON s.id = co.service_id
            JOIN plots p ON p.id = co.plot_id
            JOIN zones z ON z.id = p.zone_id
            OUTER APPLY (
                SELECT (
                    SELECT TOP (4) proof.id, proof.image_url, proof.note,
                        proof.created_at, worker.full_name AS worker_name
                    FROM care_order_proofs proof
                    LEFT JOIN users worker ON worker.id = proof.worker_id
                    WHERE proof.care_order_id = co.id
                    ORDER BY proof.created_at DESC, proof.id DESC
                    FOR JSON PATH
                ) AS proof_images_json
            ) proof_data
            WHERE cust.user_id = @userId
            ORDER BY co.created_at DESC, co.scheduled_date DESC
        `);
    // The review table is added by the optional care-service migration. Keep
    // existing dashboards and care reports available if that script has not
    // been applied yet; only review submission requires the new table.
    let reviewByOrder = new Map();
    try {
        const reviews = await pool.request()
            .input('userId', sql.Int, req.user.sub)
            .query(`
                SELECT r.care_order_id, r.rating, r.comment
                FROM care_order_reviews r
                JOIN care_orders co ON co.id = r.care_order_id
                JOIN customers cust ON cust.id = co.customer_id
                WHERE cust.user_id = @userId
            `);
        reviewByOrder = new Map(reviews.recordset.map(review => [review.care_order_id, review]));
    } catch (error) {
        if (error.number !== 208) throw error;
    }
    const data = result.recordset.map(row => {
        let proofImages = [];
        if (row.proof_images_json) {
            try {
                proofImages = JSON.parse(row.proof_images_json);
            } catch (error) {
                console.error('Không đọc được ảnh nghiệm thu dịch vụ:', error);
            }
        }
        const { proof_images_json, ...order } = row;
        const review = reviewByOrder.get(row.id);
        return {
            ...order,
            proof_images: proofImages,
            review_rating: review?.rating ?? null,
            review_comment: review?.comment ?? null,
        };
    });
    res.json({ data });
}));

// Danh sách đơn do thân nhân đặt, chỉ Ban Quản Lý được xem để duyệt.
app.get('/api/v1/admin/care-orders', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'ADMIN') {
        return res.status(403).json({ error: 'Chỉ quản trị viên mới được xem danh sách duyệt đơn.' });
    }
    const pool = await poolPromise;
    const result = await pool.request().query(`
        SELECT co.id, co.order_code, co.plot_id, co.scheduled_date,
            co.status, co.note, co.created_at,
            s.service_name, s.price AS service_price,
            cust.full_name AS customer_name, cust.phone_number AS customer_phone,
            p.plot_code, z.zone_name, proof_data.proof_images_json
        FROM care_orders co
        JOIN customers cust ON cust.id = co.customer_id
        JOIN services s ON s.id = co.service_id
        JOIN plots p ON p.id = co.plot_id
        JOIN zones z ON z.id = p.zone_id
        OUTER APPLY (
            SELECT (
                SELECT TOP (4) proof.id, proof.image_url, proof.note,
                    proof.created_at, worker.full_name AS worker_name
                FROM care_order_proofs proof
                LEFT JOIN users worker ON worker.id = proof.worker_id
                WHERE proof.care_order_id = co.id
                ORDER BY proof.created_at DESC, proof.id DESC
                FOR JSON PATH
            ) AS proof_images_json
        ) proof_data
        ORDER BY
            CASE WHEN UPPER(co.status) IN ('PENDING', 'WAITING', 'SUBMITTED') THEN 0 ELSE 1 END,
            co.created_at DESC, co.id DESC
    `);
    const data = result.recordset.map(row => {
        let proofImages = [];
        if (row.proof_images_json) {
            try {
                proofImages = JSON.parse(row.proof_images_json);
            } catch (error) {
                console.error('Không đọc được ảnh minh chứng đơn chăm sóc:', error);
            }
        }
        const { proof_images_json, ...order } = row;
        return { ...order, proof_images: proofImages };
    });
    res.json({ data });
}));

// Xác nhận duyệt đơn đặt dịch vụ chăm sóc. Cập nhật có điều kiện để tránh duyệt lặp.
app.post('/api/v1/admin/care-orders/:id/approve', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'ADMIN') {
        return res.status(403).json({ error: 'Chỉ quản trị viên mới được duyệt đơn chăm sóc.' });
    }
    const orderId = Number(req.params.id);
    if (!Number.isInteger(orderId) || orderId <= 0) {
        return res.status(400).json({ error: 'Mã đơn chăm sóc không hợp lệ.' });
    }

    const pool = await poolPromise;
    const updated = await pool.request()
        .input('orderId', sql.Int, orderId)
        .query(`
            UPDATE care_orders
            SET status = 'CONFIRMED'
            OUTPUT INSERTED.id, INSERTED.order_code, INSERTED.status,
                INSERTED.scheduled_date, INSERTED.created_at
            WHERE id = @orderId
                AND UPPER(ISNULL(status, '')) IN ('PENDING', 'WAITING', 'SUBMITTED')
        `);
    if (updated.recordset[0]) {
        return res.json({ data: updated.recordset[0] });
    }

    const current = await pool.request()
        .input('orderId', sql.Int, orderId)
        .query('SELECT id, status FROM care_orders WHERE id = @orderId');
    if (!current.recordset[0]) {
        return res.status(404).json({ error: 'Không tìm thấy đơn chăm sóc.' });
    }
    return res.status(409).json({
        error: `Đơn không còn ở trạng thái chờ duyệt (hiện tại: ${current.recordset[0].status}).`
    });
}));

// Lưu một phiếu đăng ký gồm nhiều dịch vụ và thông tin thanh toán dự kiến.
app.post('/api/v1/care-orders/checkout', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        return res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
    }
    const plotId = Number(req.body.plotId);
    const serviceIds = [...new Set((Array.isArray(req.body.serviceIds) ? req.body.serviceIds : []).map(Number))];
    const scheduledAt = req.body.scheduledAt;
    const calendarType = String(req.body.calendarType || 'SOLAR').toUpperCase();
    const scheduleType = String(req.body.scheduleType || 'ONCE').toUpperCase();
    const paymentMethod = String(req.body.paymentMethod || 'VIETQR').toUpperCase();
    const timeSlot = String(req.body.timeSlot || '').slice(0, 40);
    const prayerNote = String(req.body.prayerNote || '').trim();
    const channels = req.body.reportChannels || {};
    if (!Number.isInteger(plotId) || plotId <= 0 || serviceIds.length === 0 ||
        serviceIds.some(id => !Number.isInteger(id) || id <= 0) ||
        !/^\d{4}-\d{2}-\d{2}$/.test(String(scheduledAt || '')) ||
        !['SOLAR', 'LUNAR'].includes(calendarType) ||
        !['ONCE', 'ANNUAL'].includes(scheduleType) ||
        !['VIETQR', 'MOMO', 'CARD', 'COUNTER'].includes(paymentMethod) ||
        prayerNote.length > 2000) {
        return res.status(400).json({ error: 'Vui lòng kiểm tra dịch vụ, ngày thực hiện và thông tin thanh toán.' });
    }

    const pool = await poolPromise;
    const customer = await pool.request().input('userId', sql.Int, req.user.sub)
        .query('SELECT id FROM customers WHERE user_id = @userId');
    const customerId = customer.recordset[0]?.id;
    if (!customerId) return res.status(403).json({ error: 'Tài khoản chưa có hồ sơ thân nhân.' });
    const owned = await pool.request().input('plotId', sql.Int, plotId).input('userId', sql.Int, req.user.sub).query(`
        SELECT p.id FROM plots p WHERE p.id = @plotId AND EXISTS (
            SELECT 1 FROM contracts c JOIN customers owner ON owner.id = c.customer_id
            WHERE c.plot_id = p.id AND owner.user_id = @userId AND c.status <> 'CANCELLED'
        )
    `);
    if (!owned.recordset[0]) return res.status(403).json({ error: 'Mộ phần chưa được liên kết với hợp đồng của tài khoản.' });

    const serviceInputs = serviceIds.map((id, index) => `@service${index}`).join(',');
    const serviceRequest = pool.request();
    serviceIds.forEach((id, index) => serviceRequest.input(`service${index}`, sql.Int, id));
    const services = await serviceRequest.query(`SELECT id, price FROM services WHERE id IN (${serviceInputs}) AND service_code IN ('FLOWER_RAM','CLEANING_MONTH','ANNIVERSARY_VEG','BONSAI_MONTHLY','LANTERN_RELEASE')`);
    if (services.recordset.length !== serviceIds.length) return res.status(400).json({ error: 'Danh mục có dịch vụ không hợp lệ hoặc đã ngừng phục vụ.' });

    const subtotal = services.recordset.reduce((sum, row) => sum + Number(row.price), 0);
    const discount = scheduleType === 'ANNUAL' ? Math.round(subtotal * 0.1) : 0;
    const total = subtotal - discount;
    const batchCode = `CARE-${Date.now()}`;
    const transaction = new sql.Transaction(pool);
    let started = false;
    try {
        await transaction.begin();
        started = true;
        const batch = await transaction.request()
            .input('code', sql.VarChar(50), batchCode)
            .input('customerId', sql.Int, customerId)
            .input('plotId', sql.Int, plotId)
            .input('date', sql.Date, scheduledAt)
            .input('calendar', sql.VarChar(10), calendarType)
            .input('schedule', sql.VarChar(10), scheduleType)
            .input('time', sql.NVarChar(40), timeSlot || null)
            .input('prayer', sql.NVarChar(sql.MAX), prayerNote || null)
            .input('zalo', sql.Bit, Boolean(channels.Zalo))
            .input('email', sql.Bit, Boolean(channels.Email))
            .input('sms', sql.Bit, Boolean(channels.SMS))
            .input('method', sql.VarChar(20), paymentMethod)
            .input('subtotal', sql.Decimal(15, 2), subtotal)
            .input('discount', sql.Decimal(15, 2), discount)
            .input('total', sql.Decimal(15, 2), total)
            .query(`INSERT INTO care_order_checkout_batches(batch_code,customer_id,plot_id,scheduled_date,calendar_type,schedule_type,time_slot,prayer_note,report_zalo,report_email,report_sms,payment_method,subtotal,discount_amount,total_amount)
                OUTPUT INSERTED.id, INSERTED.batch_code, INSERTED.payment_status, INSERTED.total_amount
                VALUES(@code,@customerId,@plotId,@date,@calendar,@schedule,@time,@prayer,@zalo,@email,@sms,@method,@subtotal,@discount,@total)`);
        const batchId = batch.recordset[0].id;
        for (let index = 0; index < serviceIds.length; index++) {
            await transaction.request()
                .input('code', sql.VarChar(50), `${batchCode}-${index + 1}`)
                .input('batchId', sql.Int, batchId)
                .input('plotId', sql.Int, plotId)
                .input('customerId', sql.Int, customerId)
                .input('serviceId', sql.Int, serviceIds[index])
                .input('date', sql.Date, scheduledAt)
                .input('note', sql.NVarChar(sql.MAX), prayerNote || null)
                .query(`INSERT INTO care_orders(order_code,checkout_batch_id,plot_id,customer_id,service_id,scheduled_date,note)
                    VALUES(@code,@batchId,@plotId,@customerId,@serviceId,@date,@note)`);
        }
        await transaction.commit();
        started = false;
        res.status(201).json({ data: { ...batch.recordset[0], subtotal, discount_amount: discount, total_amount: total, service_count: serviceIds.length } });
    } catch (error) {
        if (started) await transaction.rollback();
        throw error;
    }
}));

// Đặt dịch vụ chăm sóc
app.post('/api/v1/care-orders', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        return res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
    }
    const { plotId, serviceId, scheduledAt, notes } = req.body;
    if (!plotId || !serviceId) return res.status(400).json({ error: 'Chọn ô mộ và dịch vụ cần đặt.' });

    const pool = await poolPromise;
    const code = `CS-${Date.now()}`;

    const custResult = await pool.request()
        .input('userId', sql.Int, req.user.sub)
        .query('SELECT id FROM customers WHERE user_id = @userId');
    const customerId = custResult.recordset[0]?.id;
    if (!customerId) {
        return res.status(403).json({ error: 'Tài khoản chưa có hồ sơ thân nhân.' });
    }

    const ownedPlot = await pool.request()
        .input('plotId', sql.Int, plotId)
        .input('userId', sql.Int, req.user.sub)
        .query(`
            SELECT p.id
            FROM plots p
            WHERE p.id = @plotId AND EXISTS (
                SELECT 1 FROM contracts c
                JOIN customers owner ON owner.id = c.customer_id
                WHERE c.plot_id = p.id AND owner.user_id = @userId
                    AND c.status <> 'CANCELLED'
            )
        `);
    if (!ownedPlot.recordset[0]) {
        return res.status(403).json({ error: 'Mộ phần chưa được liên kết với hợp đồng của tài khoản.' });
    }

    const service = await pool.request()
        .input('serviceId', sql.Int, serviceId)
        .query('SELECT id FROM services WHERE id = @serviceId');
    if (!service.recordset[0]) {
        return res.status(404).json({ error: 'Không tìm thấy dịch vụ chăm sóc.' });
    }

    const result = await pool.request()
        .input('code', sql.VarChar, code)
        .input('plotId', sql.Int, plotId)
        .input('customerId', sql.Int, customerId)
        .input('serviceId', sql.Int, serviceId)
        .input('scheduledAt', sql.Date, scheduledAt || new Date())
        .input('notes', sql.NVarChar, notes || null)
        .query(`
            INSERT INTO care_orders(order_code, plot_id, customer_id, service_id, scheduled_date, note) 
            OUTPUT INSERTED.* 
            VALUES(@code, @plotId, @customerId, @serviceId, @scheduledAt, @notes)
        `);

    res.status(201).json({ data: result.recordset[0] });
}));

// Thân nhân xác nhận nghiệm thu và lưu đánh giá cho đơn đã hoàn tất.
app.post('/api/v1/care-orders/:id/review', auth, asyncRoute(async (req, res) => {
    if (req.user.role !== 'CUSTOMER') {
        return res.status(403).json({ error: 'Chức năng này dành cho tài khoản thân nhân.' });
    }
    const orderId = Number(req.params.id);
    const rating = Number(req.body.rating);
    const comment = String(req.body.comment || '').trim();
    if (!Number.isInteger(orderId) || orderId <= 0 ||
        !Number.isInteger(rating) || rating < 1 || rating > 5 || comment.length > 1000) {
        return res.status(400).json({ error: 'Đánh giá chưa hợp lệ.' });
    }

    const pool = await poolPromise;
    const ownedOrder = await pool.request()
        .input('orderId', sql.Int, orderId)
        .input('userId', sql.Int, req.user.sub)
        .query(`
            SELECT co.id, co.status, cust.id AS customer_id
            FROM care_orders co
            JOIN customers cust ON cust.id = co.customer_id
            WHERE co.id = @orderId AND cust.user_id = @userId
        `);
    const order = ownedOrder.recordset[0];
    if (!order) return res.status(404).json({ error: 'Không tìm thấy đơn chăm sóc.' });
    if (!['COMPLETED', 'DONE', 'FULFILLED'].includes(String(order.status).toUpperCase())) {
        return res.status(409).json({ error: 'Chỉ xác nhận nghiệm thu sau khi dịch vụ đã hoàn tất.' });
    }

    const result = await pool.request()
        .input('orderId', sql.Int, orderId)
        .input('customerId', sql.Int, order.customer_id)
        .input('rating', sql.TinyInt, rating)
        .input('comment', sql.NVarChar(1000), comment || null)
        .query(`
            UPDATE care_order_reviews
            SET rating = @rating, comment = @comment,
                confirmed_at = SYSUTCDATETIME(), updated_at = SYSUTCDATETIME()
            WHERE care_order_id = @orderId AND customer_id = @customerId;

            IF @@ROWCOUNT = 0
            BEGIN
                INSERT INTO care_order_reviews(care_order_id, customer_id, rating, comment)
                VALUES(@orderId, @customerId, @rating, @comment);
            END;

            SELECT care_order_id, rating, comment, confirmed_at
            FROM care_order_reviews
            WHERE care_order_id = @orderId AND customer_id = @customerId;
        `);
    res.json({ data: result.recordset[0] });
}));

// Tải ảnh nghiệm thu
app.post('/api/v1/care-orders/:id/proof', auth, asyncRoute(async (req, res) => {
    const { imageUrl, caption } = req.body;
    if (!imageUrl) return res.status(400).json({ error: 'Cần cung cấp đường dẫn ảnh nghiệm thu.' });

    const pool = await poolPromise;
    const orderResult = await pool.request().input('id', sql.Int, req.params.id).query('SELECT * FROM care_orders WHERE id = @id');
    
    if (!orderResult.recordset[0]) return res.status(404).json({ error: 'Không tìm thấy đơn chăm sóc.' });

    const result = await pool.request()
        .input('orderId', sql.Int, req.params.id)
        .input('workerId', sql.Int, req.user.sub)
        .input('imageUrl', sql.VarChar, imageUrl)
        .input('caption', sql.NVarChar, caption || null)
        .query(`
            INSERT INTO care_order_proofs(care_order_id, worker_id, image_url, note) 
            OUTPUT INSERTED.* 
            VALUES(@orderId, @workerId, @imageUrl, @caption)
        `);

    res.status(201).json({ data: result.recordset[0] });
}));

// ----------------------------------------------------
// 6. XỬ LÝ LỖI & CHẠY SERVER
// ----------------------------------------------------

app.use((err, req, res, _next) => {
    console.error(err);
    if (err.number === 208 && req.path.startsWith('/api/v1/admin/')) {
        return res.status(503).json({
            error: 'Cơ sở dữ liệu chưa có đủ bảng cho API quản trị. Hãy chạy database/20261102_01_admin_api_modules.sql rồi khởi động lại backend.'
        });
    }
    if (err.number === 208 && req.path.startsWith('/api/v1/care-')) {
        return res.status(503).json({
            error: 'Cơ sở dữ liệu chưa có đủ bảng dịch vụ chăm sóc từ xa. Hãy chạy database/bo_sung_cham_soc_tu_xa.sql trong database sala_garden_db rồi khởi động lại backend.'
        });
    }
    // The online memorial endpoints depend on the additive SQL migration.
    // Surface a useful setup message when the API is connected to a database
    // where one of those tables has not been created yet (SQL Server 208).
    if (err.number === 208 && req.path.startsWith('/api/v1/customer/memorials')) {
        return res.status(503).json({
            error: 'Cơ sở dữ liệu chưa có đủ bảng Tưởng niệm Online. Hãy chạy database/bo_sung_tuong_niem.sql trong database sala_garden_db rồi khởi động lại backend.'
        });
    }
    if (err.number === 208 && req.path.startsWith('/api/v1/admin/settings')) {
        return res.status(503).json({
            error: 'Cơ sở dữ liệu chưa có các bảng phân quyền Admin. Hãy chạy database/bo_sung_phan_quyen_admin.sql trong database sala_garden_db rồi khởi động lại backend.'
        });
    }
    if (err.number === 2627 || err.number === 2601) {
        return res.status(409).json({ error: 'Thông tin đã tồn tại trong hệ thống.' });
    }
    if (err.number === 547) {
        return res.status(400).json({ error: 'Dữ liệu tham chiếu không hợp lệ.' });
    }
    res.status(500).json({ error: 'Đã xảy ra lỗi máy chủ.' });
});

const port = Number(process.env.PORT) || 3000;
app.listen(port, () => console.log(`🚀 Sala Garden API listening on port ${port}`));



