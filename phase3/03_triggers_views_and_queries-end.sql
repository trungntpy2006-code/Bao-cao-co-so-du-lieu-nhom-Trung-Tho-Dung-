-- =====end========================================================
-- MINI-NETFLIX: TRIGGER, VIEW VÀ TRUY VẤN (chạy sau 01 và 02)
-- =============================================================
USE mini_netflix;

-- =============================================================
-- PHẦN 1: TRIGGER VÀ VIEW
-- =============================================================

-- Trigger 1: mỗi USER tối đa 5 PROFILE
DROP TRIGGER IF EXISTS trg_limit_profiles;

DELIMITER //
CREATE TRIGGER trg_limit_profiles
BEFORE INSERT ON PROFILE
FOR EACH ROW
BEGIN
    DECLARE profile_count INT;

    SELECT COUNT(*) INTO profile_count
    FROM PROFILE
    WHERE User_ID = NEW.User_ID;

    IF profile_count >= 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Mỗi USER chỉ được tạo tối đa 5 PROFILE';
    END IF;
END//
DELIMITER ;

-- Trigger 2: tự tính is_completed khi thêm mới (ngưỡng 90%)
DROP TRIGGER IF EXISTS trg_watches_before_insert;

DELIMITER //
CREATE TRIGGER trg_watches_before_insert
BEFORE INSERT ON WATCHES
FOR EACH ROW
BEGIN
    DECLARE v_duration INT;

    SET v_duration = COALESCE(
        (SELECT Duration_Minutes FROM MOVIE   WHERE Content_ID = NEW.Content_ID),
        (SELECT Duration_Minutes FROM EPISODE WHERE Content_ID = NEW.Content_ID)
    );

    IF v_duration IS NOT NULL THEN
        SET NEW.is_completed = (NEW.Progress_Timestamp >= 0.9 * v_duration * 60);
    END IF;
END//
DELIMITER ;

-- Trigger 3: tự tính lại is_completed khi cập nhật tiến trình
DROP TRIGGER IF EXISTS trg_watches_before_update;

DELIMITER //
CREATE TRIGGER trg_watches_before_update
BEFORE UPDATE ON WATCHES
FOR EACH ROW
BEGIN
    DECLARE v_duration INT;

    SET v_duration = COALESCE(
        (SELECT Duration_Minutes FROM MOVIE   WHERE Content_ID = NEW.Content_ID),
        (SELECT Duration_Minutes FROM EPISODE WHERE Content_ID = NEW.Content_ID)
    );

    IF v_duration IS NOT NULL THEN
        SET NEW.is_completed = (NEW.Progress_Timestamp >= 0.9 * v_duration * 60);
    END IF;
END//
DELIMITER ;

-- View 1: thống kê số PROFILE của mỗi USER (báo cáo mục 4.1.2)
DROP VIEW IF EXISTS vw_user_profile_count;

CREATE VIEW vw_user_profile_count AS
SELECT u.User_ID,
       u.Username,
       COUNT(p.Profile_ID) AS Profile_Count,
       5 AS Max_Profiles
FROM `USER` AS u
LEFT JOIN PROFILE AS p ON p.User_ID = u.User_ID
GROUP BY u.User_ID, u.Username;
SELECT * FROM vw_user_profile_count;
-- View 2: nội dung an toàn cho hồ sơ trẻ em (báo cáo mục 1.2.2)
DROP VIEW IF EXISTS vw_kids_content;

CREATE VIEW vw_kids_content AS
SELECT Content_ID, Title, Maturity_Rating
FROM CONTENT
WHERE Maturity_Rating IN ('G', 'PG', 'TV-Y');
SELECT * FROM vw_kids_content;
-- =============================================================
-- PHẦN 2: TRUY VẤN NÂNG CAO
-- =============================================================

-- Q1 (Subquery NOT EXISTS): Nội dung chưa từng được lưu vào SAVES_TO
SELECT c.Content_ID, c.Title
FROM CONTENT AS c
WHERE NOT EXISTS (
    SELECT 5
    FROM SAVES_TO AS s
    WHERE s.Content_ID = c.Content_ID
);

-- Q2 (Subquery EXISTS): Hồ sơ vừa xem phim lẻ vừa lưu tập phim
SELECT p.User_ID, p.Profile_ID, p.Profile_Name
FROM PROFILE AS p
WHERE EXISTS (
    SELECT 1
    FROM WATCHES AS w
    JOIN MOVIE AS m ON m.Content_ID = w.Content_ID
    WHERE w.User_ID = p.User_ID
      AND w.Profile_ID = p.Profile_ID
)
AND EXISTS (
    SELECT 1
    FROM SAVES_TO AS s
    JOIN EPISODE AS e ON e.Content_ID = s.Content_ID
    WHERE s.User_ID = p.User_ID
      AND s.Profile_ID = p.Profile_ID
);

-- Q3 (JOIN + GROUP BY + HAVING): Top 3 nội dung có điểm trung bình cao nhất (ít nhất 2 lượt chấm)
SELECT c.Content_ID,
       c.Title,
       ROUND(AVG(w.User_Rating), 2) AS diem_tb,
       COUNT(*) AS so_luot_cham
FROM WATCHES AS w
JOIN CONTENT AS c ON c.Content_ID = w.Content_ID
WHERE w.User_Rating IS NOT NULL
GROUP BY c.Content_ID, c.Title
HAVING COUNT(*) >= 2
ORDER BY diem_tb DESC, so_luot_cham DESC
LIMIT 3;

-- Q4 (UNION): Phim lẻ từ 120 phút và tập phim từ 45 phút
SELECT c.Content_ID, c.Title, m.Duration_Minutes, 'Movie' AS Content_Type
FROM CONTENT AS c
JOIN MOVIE AS m ON m.Content_ID = c.Content_ID
WHERE m.Duration_Minutes >= 120
UNION
SELECT c.Content_ID, c.Title, e.Duration_Minutes, 'Episode' AS Content_Type
FROM CONTENT AS c
JOIN EPISODE AS e ON e.Content_ID = c.Content_ID
WHERE e.Duration_Minutes >= 45;

-- Q5 (JOIN + GROUP BY): Số người dùng và doanh thu tháng theo gói cước
SELECT t.Tier_ID,
       t.Tier_Name,
       COUNT(u.User_ID) AS so_user,
       COUNT(u.User_ID) * t.Monthly_Price AS doanh_thu_thang
FROM SUBSCRIPTION_TIER AS t
LEFT JOIN `USER` AS u ON u.Tier_ID = t.Tier_ID
GROUP BY t.Tier_ID, t.Tier_Name, t.Monthly_Price
ORDER BY t.Tier_ID;

-- Q6 (JOIN + GROUP BY + HAVING): Điểm trung bình theo thể loại (>= 4 điểm, ít nhất 2 lượt chấm)
SELECT g.Genre,
       ROUND(AVG(w.User_Rating), 2) AS diem_tb,
       COUNT(*) AS so_luot_cham
FROM WATCHES AS w
JOIN CONTENT_GENRE AS g ON g.Content_ID = w.Content_ID
WHERE w.User_Rating IS NOT NULL
GROUP BY g.Genre
HAVING AVG(w.User_Rating) >= 4 AND COUNT(*) >= 2;

-- Q7 (JOIN + điều kiện): Danh sách "Tiếp tục xem" của hồ sơ Be Bo (User 1, Profile 2)
SELECT c.Title, w.Progress_Timestamp AS giay_da_xem
FROM WATCHES AS w
JOIN CONTENT AS c ON c.Content_ID = w.Content_ID
WHERE w.User_ID = 1
  AND w.Profile_ID = 2
  AND w.is_completed = FALSE;

-- Q8 (JOIN nhiều bảng + view): Nội dung an toàn đã lưu trong hồ sơ trẻ em
SELECT p.Profile_Name, k.Title, k.Maturity_Rating
FROM PROFILE AS p
JOIN SAVES_TO AS s ON s.User_ID = p.User_ID AND s.Profile_ID = p.Profile_ID
JOIN vw_kids_content AS k ON k.Content_ID = s.Content_ID
WHERE p.is_kids_profile = TRUE;

-- Q9 (LEFT JOIN + GROUP BY): Số tập và tổng thời lượng của từng bộ phim truyền hình
SELECT s.Series_Title,
       COUNT(e.Content_ID) AS so_tap,
       SUM(e.Duration_Minutes) AS tong_phut
FROM TV_SERIES AS s
LEFT JOIN EPISODE AS e ON e.Series_ID = s.Series_ID
GROUP BY s.Series_ID, s.Series_Title;

-- Q10 (JOIN + GROUP BY): Thể loại được xem nhiều nhất
SELECT g.Genre, COUNT(*) AS luot_xem
FROM WATCHES AS w
JOIN CONTENT_GENRE AS g ON g.Content_ID = w.Content_ID
GROUP BY g.Genre
ORDER BY luot_xem DESC;

-- Q11 (Subquery trong WHERE): Người dùng thuộc gói có giá cao hơn giá trung bình
SELECT u.User_ID, u.Username, t.Tier_Name, t.Monthly_Price
FROM `USER` AS u
JOIN SUBSCRIPTION_TIER AS t ON t.Tier_ID = u.Tier_ID
WHERE t.Monthly_Price > (SELECT AVG(Monthly_Price) FROM SUBSCRIPTION_TIER);






-- USE mini_netflix;
-- SET FOREIGN_KEY_CHECKS = 0;

-- TRUNCATE TABLE SAVES_TO;
-- TRUNCATE TABLE WATCHES;
-- TRUNCATE TABLE PROFILE;
-- TRUNCATE TABLE CONTENT_GENRE;
-- TRUNCATE TABLE EPISODE;
-- TRUNCATE TABLE MOVIE;
-- TRUNCATE TABLE CONTENT;
-- TRUNCATE TABLE TV_SERIES;
-- TRUNCATE TABLE USER;
-- TRUNCATE TABLE SUBSCRIPTION_TIER;

-- SET FOREIGN_KEY_CHECKS = 1;