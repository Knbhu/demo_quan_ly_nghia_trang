# Sala Garden — quản lý nghĩa trang

Monorepo khởi đầu gồm PostgreSQL, REST API Node.js và ứng dụng Flutter dùng chung Android/Web.

## Cấu trúc

- `database/schema.sql`: 11 bảng cốt lõi cho tài khoản, gia tộc, ô mộ, hồ sơ tưởng niệm, hợp đồng, trả góp, dịch vụ, đơn chăm sóc, ảnh nghiệm thu, thanh toán và thông báo.
- `database/seed.sql`: dữ liệu demo gồm 35.000 ô mộ và 4 dịch vụ chăm sóc.
- `backend/`: Express API, JWT, kết nối PostgreSQL.
- `frontend_app/`: Flutter với giao diện công khai, đăng nhập/đăng ký, dashboard và sơ đồ mặt bằng ban đầu.

## Chạy backend

1. Cài PostgreSQL và tạo database `sala_garden`.
2. Chạy `database/schema.sql` trong database đó. Có thể chạy tiếp `database/seed.sql` để tạo dữ liệu demo.
3. Sao chép `backend/.env.example` thành `backend/.env`, cập nhật `DATABASE_URL` và đặt `JWT_SECRET` riêng.
4. Từ thư mục `backend`, chạy `npm install`, sau đó `npm start`.

API chạy mặc định tại `http://localhost:3000`; health check: `GET /api/v1/health`.

## Chạy Flutter

Từ thư mục `frontend_app`, tạo platform scaffold bằng `flutter create --platforms=web,android --project-name sala_garden .` (nếu thư mục `android/` và `web/` chưa có), chạy `flutter pub get`, sau đó `flutter run -d chrome` cho Web hoặc `flutter run` với Android Emulator. API tự dùng `localhost` trên Web và `10.0.2.2` trên Android Emulator. Khi chạy trên điện thoại thật, đổi địa chỉ Android trong `lib/core/api_service.dart` sang IP LAN của máy chạy backend.

## API hiện có

- `POST /api/v1/auth/register`, `POST /api/v1/auth/login`, `GET /api/v1/auth/me`
- `GET /api/v1/plots`, `GET /api/v1/plots/:id`
- `POST /api/v1/contracts`, `GET /api/v1/contracts/customer/:id`, `GET /api/v1/contracts/:id/installments`
- `POST /api/v1/care-orders`, `GET /api/v1/care-orders`, `POST /api/v1/care-orders/:id/proof`

Flutter đã có các khu vực giao diện quản trị: tổng quan, mặt bằng, hợp đồng, sổ bạ thân nhân, hồ sơ QR, tang lễ, chăm sóc/ảnh nghiệm thu, GPS, phân công nhân viên và phân quyền. Đăng nhập chuyển thân nhân tới trang tài khoản và nhân viên tới cổng quản trị.

Đăng ký hiện tạo tài khoản bằng số điện thoại và mật khẩu. Gửi OTP qua SMS/Zalo cần tích hợp nhà cung cấp thực tế trước khi dùng cho người dùng cuối. Ảnh nghiệm thu hiện nhận URL; cần bổ sung dịch vụ lưu trữ ảnh để tải file trực tiếp.

Các màn quản trị trong ảnh Stitch còn nhiều nghiệp vụ lớn (quyền theo vai trò, bản đồ GIS/3D, thanh toán điện tử, lập lịch tang lễ và điều phối nhân viên). Khung này đặt nền API và giao diện để triển khai tiếp từng luồng mà không giả lập các tích hợp chưa có cấu hình.
