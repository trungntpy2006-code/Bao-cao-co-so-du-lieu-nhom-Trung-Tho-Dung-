# ĐỒ ÁN MÔN CƠ SỞ DỮ LIỆU
**Đề tài:** On-Demand Streaming Platform (`mini_netflix`)  
**Học kỳ / Năm học:** KH1 - (2026–2027)

### Thành viên thực hiện
- **Nguyễn Thành Trung** — MSSV: `N24DCCN178`
- **Đỗ Đặng Minh Thơ** — MSSV: `N24DCCN170`
- **Phan Bùi Mạnh Dũng** — MSSV: `N24DCCN111`

---

## 1. Yêu cầu môi trường
- **MySQL Server 8.0+** và **MySQL Workbench**.
- **Phần mềm giải nén** (WinRAR, 7-Zip...) để giải nén file dữ liệu `.rar`.
- Bật `LOCAL INFILE` để MySQL Workbench nạp file CSV từ máy local:
  - **Trong MySQL Workbench:** Vào **Database** -> **Manage Connections...** -> chọn connection -> tab **Advanced** -> thêm `OPT_LOCAL_INFILE=1` vào mục **Others:** -> **Reconnect to Server**.
  - **Trên MySQL Server:** Chạy lệnh:
    ```sql
    SET GLOBAL local_infile = 1;
    SHOW VARIABLES LIKE 'local_infile'; -- Đảm bảo giá trị là ON
    ```

---

## 2. Cấu trúc tài liệu trong gói nộp
- `01_create_tables_and_sample_data.sql`: Tạo database `mini_netflix`, các bảng, ràng buộc khóa chính/khóa ngoại/check và dữ liệu gói cước mặc định (`SUBSCRIPTION_TIER`).
- `csv_output.rar` *(hoặc file `.rar` dữ liệu)*: Chứa sẵn các file `.csv` dữ liệu mẫu đã được sinh sẵn để dùng ngay.
- `<02_file_load_csv>.sql`: Xóa dữ liệu cũ (nếu cần) và nạp toàn bộ file `.csv` vào các bảng theo đúng thứ tự khóa ngoại bằng `LOAD DATA LOCAL INFILE`.
- `03_triggers_views_and_queries.sql`: Tạo trigger, view và các câu truy vấn kiểm tra/nâng cao.
- `<script_sinh_du_lieu>.py` *(tùy chọn)*: Script Python sinh dữ liệu CSV nếu muốn tự tạo bộ dữ liệu mới.

---

## 3. Thứ tự chạy chi tiết

### Bước 1: Tạo database và bảng
1. Mở file `01_create_tables_and_sample_data.sql` trong MySQL Workbench.
2. Chạy toàn bộ file để tạo database `mini_netflix`.

### Bước 2: Giải nén dữ liệu CSV
1. Giải nén file `.rar` ra một thư mục trên máy (ví dụ: `D:/python/csv_output/`).
2. Kiểm tra bên trong thư mục có đủ các file `.csv` (`tv_series.csv`, `content.csv`, `movie.csv`, `episode.csv`, `content_genre.csv`, `user.csv`, `profile.csv`, `watches.csv`, `saves_to.csv`).

### Bước 3: Nạp dữ liệu CSV vào MySQL
1. Mở file 02_file_load_csv>.sql trong MySQL Workbench.
2. **Sửa đường dẫn thư mục CSV** trong file SQL cho khớp với thư mục vừa giải nén trên máy của bạn (dùng dấu `/` hoặc `\\`, ví dụ `D:/python/csv_output/`).
3. Chạy file SQL để nạp dữ liệu theo đúng thứ tự bảng cha -> bảng con.
   - *Lưu ý:* Khi nạp bảng lớn như `WATCHES` và `SAVES_TO`, nên tạm tắt trigger `INSERT` (nếu có) và bật lại ngay sau khi nạp để chạy nhanh hơn.(thời gian chạy khoảng 10s)

### Bước 4: Tạo Trigger, View và chạy truy vấn kiểm tra
1. Mở file `03_triggers_views_and_queries.sql`.
2. Chạy phần tạo **Trigger** và **View** trước.
3. Chạy các câu lệnh `SELECT` kiểm tra số dòng từng bảng, dữ liệu view và các truy vấn nâng cao để xác nhận hệ thống hoạt động đúng.

---

## 4. Một số lỗi thường gặp khi chạy lần đầu
- **Lỗi `1452` (Foreign key constraint fails):** Kiểm tra lại thứ tự nạp hoặc kiểm tra ký tự xuống dòng (`\r\n` trên Windows) ở cột cuối của file CSV.
- **Lỗi `1366` (Incorrect integer value):** Do giá trị rỗng `""` ở cột số/rating chưa được chuyển về `NULL` (dùng `NULLIF(TRIM(@col), '')` khi `LOAD DATA`).
- **Cảnh báo `1051` khi `DROP VIEW IF EXISTS`:** Chỉ là cảnh báo nhẹ khi view chưa tồn tại trước đó, không làm hỏng quá trình tạo view mới.
