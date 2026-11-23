lớp học phần: cơ sở dữ liệu
học kì/ năm học: KH1-(2026-2027)
danh sách thành viên:
Nguyễn Thành Trung:N24DCCN178
Đỗ Đặng Minh Thơ:N24DCCN170
Phan Bùi Mạnh Dũng:N24DCCN111
Đề tài đồ án: On-Demand Streaming Platform (Mini-Netflix)

# Hướng Dẫn Cài Đặt & Chạy Dự Án mini_netflix

Dự án gồm 1 file Python để sinh dữ liệu test ra file .csv và 3 file SQL để tạo cấu trúc bảng, nạp dữ liệu hàng loạt, tạo trigger/view và chạy truy vấn kiểm thử.

## 1. Yêu cầu môi trường
- MySQL Server 8.0+ và MySQL Workbench.
- Python 3.x (dùng thư viện chuẩn như csv, random, datetime...).
- Bật LOCAL INFILE để MySQL Workbench nạp file CSV từ máy local:
  - Trong MySQL Workbench: Vào Database -> Manage Connections... -> chọn connection -> tab Advanced -> thêm OPT_LOCAL_INFILE=1 vào mục Others: -> Reconnect to Server.
  - Trên MySQL Server: Chạy lệnh:
    SET GLOBAL local_infile = 1;
    SHOW VARIABLES LIKE 'local_infile'; -- Đảm bảo giá trị là ON

## 2. Cấu trúc file trong dự án (ví dụ)
- 01_create_tables_and_sample_data.sql: Tạo database mini_netflix, các bảng, ràng buộc khóa chính/khóa ngoại/check và dữ liệu danh mục mặc định (SUBSCRIPTION_TIER).
- <script_sinh_du_lieu>.py: Sinh dữ liệu mẫu ra thư mục csv_output/ (mặc định có thể chỉnh số lượng user/dòng xem).
- <file_load_csv>.sql: Xóa dữ liệu cũ (nếu cần) và nạp toàn bộ file .csv vào các bảng theo đúng thứ tự khóa ngoại bằng LOAD DATA LOCAL INFILE.
- 03_triggers_views_and_queries.sql: Tạo trigger, view và các câu truy vấn kiểm tra/nâng cao.

## 3. Thứ tự chạy chi tiết

### Bước 1: Tạo database và bảng
1. Mở file SQL tạo bảng (01_create_tables_and_sample_data.sql) trong MySQL Workbench.
2. Chạy toàn bộ file để tạo schema mini_netflix, các bảng và dữ liệu gói cước ban đầu.

### Bước 2: Sinh dữ liệu CSV bằng Python
1. Mở file .py sinh dữ liệu, kiểm tra/chỉnh thông số nếu muốn (ví dụ số lượng users hoặc số lượt xem/lưu tối đa) và đường dẫn xuất thư mục CSV (ví dụ csv_output/).
2. Chạy file Python:
   python ten_file_sinh_data.py
3. Kiểm tra thư mục xuất ra đã có đủ các file .csv tương ứng với các bảng (tv_series.csv, content.csv, movie.csv, episode.csv, content_genre.csv, user.csv, profile.csv, watches.csv, saves_to.csv).

### Bước 3: Nạp dữ liệu CSV vào MySQL
1. Mở file SQL nạp dữ liệu.
2. Sửa đường dẫn thư mục CSV trong file SQL cho đúng với máy của bạn (nhớ dùng dấu / hoặc \\, ví dụ D:/.../csv_output/).
3. Chạy file SQL để nạp dữ liệu theo đúng thứ tự bảng cha -> bảng con.
   Lưu ý: Nếu nạp bảng lớn như WATCHES, nên tạm tắt trigger INSERT (nếu có) và bật lại ngay sau khi nạp để chạy nhanh hơn.

### Bước 4: Tạo Trigger, View và chạy truy vấn kiểm tra
1. Mở file SQL chứa trigger, view và truy vấn.
2. Chạy phần tạo Trigger và View trước.
3. Chạy các câu lệnh SELECT kiểm tra số dòng từng bảng, dữ liệu view và các truy vấn nâng cao để xác nhận hệ thống hoạt động đúng.

## 4. Một số lỗi thường gặp khi chạy lần đầu
- Lỗi 1452 (Foreign key constraint fails): Kiểm tra lại thứ tự nạp hoặc kiểm tra ký tự xuống dòng (\r\n trên Windows) ở cột cuối của file CSV.
- Lỗi 1366 (Incorrect integer value): Do giá trị rỗng "" ở cột số/rating chưa được chuyển về NULL (dùng NULLIF(TRIM(@col), '') khi LOAD DATA).
- Cảnh báo 1051 khi DROP VIEW IF EXISTS: Chỉ là cảnh báo nhẹ khi view chưa tồn tại trước đó, không làm hỏng quá trình tạo view mới.
