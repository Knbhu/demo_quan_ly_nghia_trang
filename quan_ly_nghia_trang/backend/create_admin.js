require('dotenv').config();
const sql = require('mssql');
const bcrypt = require('bcryptjs');

const phone = String(process.env.ADMIN_PHONE || '').trim();
const fullName = String(process.env.ADMIN_NAME || '').trim();
const password = String(process.env.ADMIN_PASSWORD || '');

if (!phone || !fullName || !password) {
  console.error('Thiếu ADMIN_PHONE, ADMIN_NAME hoặc ADMIN_PASSWORD trong backend/.env.');
  process.exit(1);
}
if (password.length < 8) {
  console.error('Mật khẩu admin cần ít nhất 8 ký tự.');
  process.exit(1);
}

const config = {
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD,
  server: process.env.DB_SERVER || 'localhost\\SQLEXPRESS',
  database: process.env.DB_DATABASE || 'sala_garden_db',
  options: { encrypt: false, trustServerCertificate: true },
};

async function createOnlyAdmin() {
  const pool = await sql.connect(config);
  const tx = new sql.Transaction(pool);
  await tx.begin(sql.ISOLATION_LEVEL.SERIALIZABLE);
  try {
    const role = await new sql.Request(tx)
      .query("SELECT id FROM roles WITH (UPDLOCK, HOLDLOCK) WHERE role_name = 'ADMIN'");
    if (!role.recordset.length) throw new Error("Không tìm thấy role 'ADMIN' trong bảng roles.");

    const existing = await new sql.Request(tx)
      .input('roleId', sql.Int, role.recordset[0].id)
      .query('SELECT TOP 1 id, phone FROM users WITH (UPDLOCK, HOLDLOCK) WHERE role_id = @roleId');
    if (existing.recordset.length) {
      throw new Error(`Đã có tài khoản ADMIN (ID ${existing.recordset[0].id}, SĐT ${existing.recordset[0].phone}); dừng để tránh tạo admin thứ hai.`);
    }

    const hash = await bcrypt.hash(password, 12);
    await new sql.Request(tx)
      .input('roleId', sql.Int, role.recordset[0].id)
      .input('phone', sql.VarChar(20), phone)
      .input('passwordHash', sql.VarChar(255), hash)
      .input('fullName', sql.NVarChar(100), fullName)
      .query(`INSERT INTO users(role_id, username, password_hash, full_name, phone, is_active)
              VALUES(@roleId, @phone, @passwordHash, @fullName, @phone, 1)`);

    await tx.commit();
    console.log(`Đã tạo tài khoản ADMIN duy nhất cho ${fullName} (${phone}).`);
    console.log('Đăng nhập bằng số điện thoại và ADMIN_PASSWORD đã cấu hình trong backend/.env.');
  } catch (error) {
    await tx.rollback();
    throw error;
  } finally {
    await pool.close();
  }
}

createOnlyAdmin().catch((error) => {
  console.error(`Không tạo được admin: ${error.message}`);
  process.exitCode = 1;
});
