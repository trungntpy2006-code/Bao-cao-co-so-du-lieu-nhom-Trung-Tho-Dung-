-- ============================================================
-- MINI-NETFLIX - SINH DỮ LIỆU TỰ ĐỘNG (chạy sau khi đã chạy DDL)
-- MySQL 8.0+
-- ============================================================
USE mini_netflix;
SET SQL_SAFE_UPDATES = 0;
SET SESSION cte_max_recursion_depth = 2000;

-- 0. Xóa dữ liệu mẫu cũ của WATCHES và SAVES_TO
DELETE FROM SAVES_TO;
DELETE FROM WATCHES;

-- 1. Bảng số phụ trợ 1..500
DROP TABLE IF EXISTS tmp_nums;
CREATE TABLE tmp_nums AS
WITH RECURSIVE s(n) AS (
    SELECT 1
    UNION ALL
    SELECT n + 1 FROM s WHERE n < 500
)
SELECT n FROM s;
ALTER TABLE tmp_nums ADD PRIMARY KEY (n);

-- 2. Người dùng mới: User_ID 9..508
INSERT INTO USER (User_ID, Username, Email, Password, Registration_Date, Tier_ID)
SELECT 8 + n,
       CONCAT('user', 8 + n),
       CONCAT('user', 8 + n, '@example.com'),
       'hashed_pw_auto',
       NOW() - INTERVAL MOD(n * 37, 300) DAY,
       1 + MOD(n, 5)
FROM tmp_nums
WHERE n <= 500;

-- 3. Hồ sơ: mỗi người dùng mới có 2 hồ sơ (Profile_ID 1 và 2)
INSERT INTO PROFILE (User_ID, Profile_ID, Profile_Name, Avatar_URL, is_kids_profile)
SELECT u.User_ID,
       p.pid,
       CONCAT('Profile ', p.pid),
       NULL,
       (p.pid = 2 AND MOD(u.User_ID, 4) = 0)
FROM USER u
JOIN (SELECT 1 AS pid UNION ALL SELECT 2) p
WHERE u.User_ID >= 9;

-- 4. Nội dung mới: Content_ID 11..60 (toàn bộ là phim lẻ)
INSERT INTO CONTENT (Content_ID, Title, Description, Release_Year, Maturity_Rating)
SELECT 10 + n,
       CONCAT('Generated Movie ', 10 + n),
       'Auto-generated sample content.',
       2015 + MOD(n, 11),
       ELT(1 + MOD(n, 4), 'G', 'PG', 'PG-13', 'R')
FROM tmp_nums
WHERE n <= 50;

INSERT INTO MOVIE (Content_ID, Duration_Minutes, Video_URL)
SELECT 10 + n,
       60 + MOD(n * 17, 90),
       CONCAT('https://example.com/video/gen', 10 + n)
FROM tmp_nums
WHERE n <= 50;

INSERT INTO CONTENT_GENRE (Content_ID, Genre)
SELECT 10 + n, ELT(1 + MOD(n, 6), 'Action', 'Drama', 'Comedy', 'Romance', 'Thriller', 'Science Fiction')
FROM tmp_nums
WHERE n <= 50
UNION ALL
SELECT 10 + n, ELT(1 + MOD(n + 3, 6), 'Action', 'Drama', 'Comedy', 'Romance', 'Thriller', 'Science Fiction')
FROM tmp_nums
WHERE n <= 50;

-- 5. Bảng tạm: thời lượng (phút) của mọi nội dung 1..60
DROP TABLE IF EXISTS tmp_dur;
CREATE TABLE tmp_dur AS
SELECT Content_ID, Duration_Minutes FROM MOVIE
UNION ALL
SELECT Content_ID, Duration_Minutes FROM EPISODE;

-- 6. WATCHES: mỗi hồ sơ xem 10 nội dung khác nhau
--    Tiến trình tính bằng giây, is_completed = TRUE khi tiến trình >= 90% thời lượng
INSERT INTO WATCHES (User_ID, Profile_ID, Content_ID, Watched_At, Progress_Timestamp, is_completed, User_Rating)
SELECT b.User_ID,
       b.Profile_ID,
       b.cid,
       NOW() - INTERVAL MOD(b.User_ID * 37 + b.cid * 11, 365) DAY,
       b.prog,
       b.prog >= 0.9 * b.dur_sec,
       CASE WHEN MOD(b.User_ID + b.cid, 10) < 7
            THEN 1 + MOD(b.User_ID + b.cid * 3, 5)
       END
FROM (
    SELECT a.User_ID,
           a.Profile_ID,
           a.cid,
           d.Duration_Minutes * 60 AS dur_sec,
           FLOOR(d.Duration_Minutes * 60 * MOD(a.User_ID * 7919 + a.Profile_ID * 104729 + a.cid * 1299709, 100) / 100) AS prog
    FROM (
        SELECT p.User_ID,
               p.Profile_ID,
               1 + MOD(p.User_ID * 31 + p.Profile_ID * 7 + (k.n - 1) * 7, 60) AS cid
        FROM PROFILE p
        JOIN tmp_nums k ON k.n <= 10
    ) a
    JOIN tmp_dur d ON d.Content_ID = a.cid
) b;

-- 7. SAVES_TO: mỗi hồ sơ lưu 5 nội dung khác nhau
INSERT INTO SAVES_TO (User_ID, Profile_ID, Content_ID, Added_Date)
SELECT x.User_ID,
       x.Profile_ID,
       x.cid,
       NOW() - INTERVAL MOD(x.User_ID * 17 + x.cid * 5, 200) DAY
FROM (
    SELECT p.User_ID,
           p.Profile_ID,
           1 + MOD(p.User_ID * 31 + p.Profile_ID * 7 + (k.n + 9) * 7, 60) AS cid
    FROM PROFILE p
    JOIN tmp_nums k ON k.n <= 5
) x;

-- 8. Kiểm tra số dòng
SELECT 'USER' AS bang, COUNT(*) AS so_dong FROM USER
UNION ALL SELECT 'PROFILE', COUNT(*) FROM PROFILE
UNION ALL SELECT 'CONTENT', COUNT(*) FROM CONTENT
UNION ALL SELECT 'MOVIE', COUNT(*) FROM MOVIE
UNION ALL SELECT 'CONTENT_GENRE', COUNT(*) FROM CONTENT_GENRE
UNION ALL SELECT 'WATCHES', COUNT(*) FROM WATCHES
UNION ALL SELECT 'SAVES_TO', COUNT(*) FROM SAVES_TO;

-- 9. Kiểm tra is_completed đúng quy tắc 90% (kết quả phải là 0)
SELECT COUNT(*) AS so_dong_sai
FROM WATCHES w
JOIN tmp_dur d ON d.Content_ID = w.Content_ID
WHERE w.is_completed <> (w.Progress_Timestamp >= 0.9 * d.Duration_Minutes * 60);

-- 10. Dọn bảng tạm
DROP TABLE tmp_dur;
DROP TABLE tmp_nums;