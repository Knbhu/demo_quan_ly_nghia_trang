# Nạp dữ liệu demo quản trị

Các script dưới đây dùng cho **SQL Server** database `sala_garden_db`. Chạy từng file và kiểm tra không có lỗi trước khi sang bước kế tiếp. Không chạy lại `sala_garden.sql` trên database đang có dữ liệu.

1. Chạy `bo_sung_tuong_niem.sql` và `bo_sung_phan_quyen_admin.sql` nếu chúng chưa từng được chạy.
2. Chạy `20261102_01_admin_api_modules.sql` để bổ sung schema cho API quản trị. File này cũng tự kiểm tra các cột hợp đồng/GPS cần thiết.
3. Chạy `20261102_02_demo_admin_data.sql` để thêm khu `DEMO`, ba thân nhân, ba hợp đồng, hai hồ sơ QR và một yêu cầu tang lễ.
4. Khởi động lại backend: `npm start` trong thư mục `backend`.

Script demo dùng mật khẩu `trunganh` cho các tài khoản `demo.an`, `demo.linh`, `demo.hung`. Các tài khoản này chỉ là dữ liệu trình diễn; đổi mật khẩu hoặc xóa bằng quy trình quản trị trước khi đưa hệ thống vào sử dụng thực tế.

Các script đều có kiểm tra `IF NOT EXISTS` và chạy trong transaction. Chúng không có `DROP`, `DELETE` hay `TRUNCATE`.

## API mới

Tất cả endpoint dưới đây cần access token tài khoản role `ADMIN`:

- `GET /api/v1/admin/dashboard`
- `GET /api/v1/admin/contracts?q=&status=`
- `POST /api/v1/admin/contracts/:id/action` với `APPROVE`, `REJECT`, hoặc `REQUEST_CHANGES`
- `GET /api/v1/admin/families?q=` và `GET /api/v1/admin/families/:id`
- `GET|POST /api/v1/admin/memorials`, `POST /api/v1/admin/memorials/:id/action`, `POST /api/v1/admin/memorials/:id/settings`
- `GET|POST /api/v1/admin/funerals`, `POST /api/v1/admin/funerals/:id/status`
- `GET /api/v1/admin/plots/gps`, `POST /api/v1/admin/plots/:id/gps`
- `POST /api/v1/admin/roles/:id/permissions` để cập nhật từng quyền theo vai trò (upsert, không xóa quyền cũ)

Chỉ super-admin được gọi `POST /api/v1/admin/users` và `POST /api/v1/admin/services`.

Phần API/bảng dữ liệu phân công nhân sự chưa được thêm, theo đúng phạm vi đã thống nhất.
