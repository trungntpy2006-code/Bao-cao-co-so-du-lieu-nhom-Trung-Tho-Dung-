-- =============================================================================
-- HE THONG CSDL MINI-NETFLIX (MUC 4.1 VA 4.2)
-- Cú pháp: MySQL
-- =============================================================================

-- -----------------------------------------------------------------------------
-- MỤC 4.1: TRIGGER VÀ VIEW
-- -----------------------------------------------------------------------------

-- 4.1.1. Trigger giới hạn tối đa 5 PROFILE cho mỗi USER
DELIMITER //

CREATE TRIGGER trg_limit_profiles
BEFORE INSERT ON PROFILE
FOR EACH ROW
BEGIN
    DECLARE profile_count INT;
    
    SELECT COUNT(*)
    INTO profile_count
    FROM PROFILE
    WHERE User_ID = NEW.User_ID;
    
    IF profile_count >= 5 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Moi USER chi duoc tao toi da 5 PROFILE';
    END IF;
END//

DELIMITER ;

-- 4.1.2. View thống kê số PROFILE của mỗi USER
CREATE VIEW vw_user_profile_count AS
SELECT 
    u.User_ID,
    u.Username,
    COUNT(p.Profile_ID) AS Profile_Count,
    5 AS Max_Profiles
FROM `USER` AS u
LEFT JOIN PROFILE AS p 
    ON p.User_ID = u.User_ID
GROUP BY u.User_ID, u.Username;


-- -----------------------------------------------------------------------------
-- MỤC 4.2: CÁC TRUY VẤN SQL NÂNG CAO
-- -----------------------------------------------------------------------------

-- Phần 1: Tìm nội dung chưa từng được lưu vào SAVES_TO
SELECT c.Content_ID, c.Title
FROM CONTENT AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM SAVES_TO AS s
    WHERE s.Content_ID = c.Content_ID
);

-- Phần 2: Tìm hồ sơ vừa xem phim lẻ vừa lưu tập phim
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

-- Phần 3: Tìm nội dung được tất cả hồ sơ xem
SELECT c.Content_ID, c.Title
FROM CONTENT AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM PROFILE AS p
    WHERE NOT EXISTS (
        SELECT 1
        FROM WATCHES AS w
        WHERE w.User_ID = p.User_ID
          AND w.Profile_ID = p.Profile_ID
          AND w.Content_ID = c.Content_ID
    )
);

-- Phần 4: UNION phim lẻ dài (>= 120 phút) và tập phim dài (>= 45 phút)
SELECT c.Content_ID, c.Title, m.Duration_Minutes, 'Movie' AS Content_Type
FROM CONTENT AS c
JOIN MOVIE AS m ON m.Content_ID = c.Content_ID
WHERE m.Duration_Minutes >= 120

UNION

SELECT c.Content_ID, c.Title, e.Duration_Minutes, 'Episode' AS Content_Type
FROM CONTENT AS c
JOIN EPISODE AS e ON e.Content_ID = c.Content_ID
WHERE e.Duration_Minutes >= 45;
