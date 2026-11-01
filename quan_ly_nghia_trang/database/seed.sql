-- Optional demo data for local development (7 khu x 50 hàng x 100 ô = 35,000 ô).
INSERT INTO plots (code, zone, row_code, plot_number, area_sqm, price, status)
SELECT
  'M' || lpad(zone_no::text, 2, '0') || '-R' || lpad(row_no::text, 2, '0') || '-' || lpad(plot_no::text, 3, '0'),
  'Khu M' || zone_no,
  'R-' || lpad(row_no::text, 2, '0'),
  lpad(plot_no::text, 3, '0'),
  4.8,
  180000000 + (zone_no * 5000000),
  CASE WHEN mod(n, 10) < 4 THEN 'available'
       WHEN mod(n, 10) < 6 THEN 'reserved'
       WHEN mod(n, 100) = 99 THEN 'maintenance'
       ELSE 'occupied' END
FROM generate_series(1, 35000) AS n
CROSS JOIN LATERAL (
  SELECT ((n - 1) / 5000) + 1 AS zone_no,
         (((n - 1) % 5000) / 100) + 1 AS row_no,
         ((n - 1) % 100) + 1 AS plot_no
) AS position
ON CONFLICT (code) DO NOTHING;

INSERT INTO care_services (name, description, price) VALUES
  ('Dâng hoa tươi & thắp nhang', 'Dâng hoa, thay nước và thắp nhang tại mộ phần.', 150000),
  ('Lau dọn & đánh bóng bia mộ', 'Vệ sinh khuôn viên và chăm sóc bề mặt bia mộ.', 300000),
  ('Cúng giỗ trọn gói', 'Chuẩn bị lễ vật và hỗ trợ nghi thức cúng giỗ.', 1200000),
  ('Chăm sóc cây xanh', 'Tỉa cây, chăm sóc chậu cảnh và khuôn viên mộ.', 500000)
ON CONFLICT DO NOTHING;
