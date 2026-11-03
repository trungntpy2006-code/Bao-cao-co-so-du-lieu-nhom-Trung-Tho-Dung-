-- MINI-NETFLIX - PHASE 3 - 4.1 SQL DDL + DML
-- MySQL 8.0+
DROP DATABASE IF EXISTS mini_netflix;
CREATE DATABASE mini_netflix CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mini_netflix;

-- 1. SUBSCRIPTION_TIER
CREATE TABLE SUBSCRIPTION_TIER (
    Tier_ID INT NOT NULL,
    Tier_Name VARCHAR(50) NOT NULL,
    Monthly_Price DECIMAL(10,2) NOT NULL,
    Max_Screens INT NOT NULL,
    Video_Quality VARCHAR(20) NOT NULL,
    CONSTRAINT PK_SUBSCRIPTION_TIER PRIMARY KEY (Tier_ID),
    CONSTRAINT UQ_SUBSCRIPTION_TIER_NAME UNIQUE (Tier_Name),
    CONSTRAINT CK_SUBSCRIPTION_TIER_PRICE CHECK (Monthly_Price >= 0),
    CONSTRAINT CK_SUBSCRIPTION_TIER_SCREENS CHECK (Max_Screens > 0)
);

-- 2. USER
CREATE TABLE USER (
    User_ID INT NOT NULL,
    Username VARCHAR(50) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    Password VARCHAR(255) NOT NULL,
    Registration_Date DATETIME NOT NULL,
    Tier_ID INT NOT NULL,
    CONSTRAINT PK_USER PRIMARY KEY (User_ID),
    CONSTRAINT UQ_USER_USERNAME UNIQUE (Username),
    CONSTRAINT UQ_USER_EMAIL UNIQUE (Email),
    CONSTRAINT FK_USER_TIER FOREIGN KEY (Tier_ID) REFERENCES SUBSCRIPTION_TIER(Tier_ID)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- 3. TV_SERIES
CREATE TABLE TV_SERIES (
    Series_ID INT NOT NULL,
    Series_Title VARCHAR(200) NOT NULL,
    Description TEXT NULL,
    Total_Seasons INT NOT NULL,
    CONSTRAINT PK_TV_SERIES PRIMARY KEY (Series_ID),
    CONSTRAINT CK_TV_SERIES_SEASONS CHECK (Total_Seasons > 0)
);

-- 4. CONTENT
CREATE TABLE CONTENT (
    Content_ID INT NOT NULL,
    Title VARCHAR(200) NOT NULL,
    Description TEXT NULL,
    Release_Year INT NULL,
    Maturity_Rating VARCHAR(20) NULL,
    CONSTRAINT PK_CONTENT PRIMARY KEY (Content_ID),
    CONSTRAINT CK_CONTENT_RELEASE_YEAR CHECK (Release_Year IS NULL OR Release_Year BETWEEN 1888 AND 2100)
);

-- 5. CONTENT_GENRE (included because Phase 2 normalized Genre into this table)
CREATE TABLE CONTENT_GENRE (
    Content_ID INT NOT NULL,
    Genre VARCHAR(100) NOT NULL,
    CONSTRAINT PK_CONTENT_GENRE PRIMARY KEY (Content_ID, Genre),
    CONSTRAINT FK_CONTENT_GENRE_CONTENT FOREIGN KEY (Content_ID) REFERENCES CONTENT(Content_ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 6. MOVIE
CREATE TABLE MOVIE (
    Content_ID INT NOT NULL,
    Duration_Minutes INT NOT NULL,
    Video_URL VARCHAR(500) NOT NULL,
    CONSTRAINT PK_MOVIE PRIMARY KEY (Content_ID),
    CONSTRAINT FK_MOVIE_CONTENT FOREIGN KEY (Content_ID) REFERENCES CONTENT(Content_ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT CK_MOVIE_DURATION CHECK (Duration_Minutes > 0)
);

-- 7. EPISODE
CREATE TABLE EPISODE (
    Content_ID INT NOT NULL,
    Season_Number INT NOT NULL,
    Episode_Number INT NOT NULL,
    Duration_Minutes INT NOT NULL,
    Video_URL VARCHAR(500) NOT NULL,
    Series_ID INT NOT NULL,
    CONSTRAINT PK_EPISODE PRIMARY KEY (Content_ID),
    CONSTRAINT UQ_EPISODE_ORDER UNIQUE (Series_ID, Season_Number, Episode_Number),
    CONSTRAINT FK_EPISODE_CONTENT FOREIGN KEY (Content_ID) REFERENCES CONTENT(Content_ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_EPISODE_SERIES FOREIGN KEY (Series_ID) REFERENCES TV_SERIES(Series_ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT CK_EPISODE_SEASON CHECK (Season_Number > 0),
    CONSTRAINT CK_EPISODE_NUMBER CHECK (Episode_Number > 0),
    CONSTRAINT CK_EPISODE_DURATION CHECK (Duration_Minutes > 0)
);

-- 8. PROFILE
CREATE TABLE PROFILE (
    User_ID INT NOT NULL,
    Profile_ID INT NOT NULL,
    Profile_Name VARCHAR(50) NOT NULL,
    Avatar_URL VARCHAR(500) NULL,
    is_kids_profile BOOLEAN NOT NULL,
    CONSTRAINT PK_PROFILE PRIMARY KEY (User_ID, Profile_ID),
    CONSTRAINT FK_PROFILE_USER FOREIGN KEY (User_ID) REFERENCES USER(User_ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- 9. WATCHES
CREATE TABLE WATCHES (
    User_ID INT NOT NULL,
    Profile_ID INT NOT NULL,
    Content_ID INT NOT NULL,
    Watched_At DATETIME NOT NULL,
    Progress_Timestamp INT NOT NULL,
    is_completed BOOLEAN NOT NULL,
    User_Rating INT NULL,
    CONSTRAINT PK_WATCHES PRIMARY KEY (User_ID, Profile_ID, Content_ID),
    CONSTRAINT FK_WATCHES_PROFILE FOREIGN KEY (User_ID, Profile_ID) REFERENCES PROFILE(User_ID, Profile_ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_WATCHES_CONTENT FOREIGN KEY (Content_ID) REFERENCES CONTENT(Content_ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT CK_WATCHES_PROGRESS CHECK (Progress_Timestamp >= 0),
    CONSTRAINT CK_WATCHES_RATING CHECK (User_Rating IS NULL OR User_Rating BETWEEN 1.0 AND 5.0)
);

-- 10. SAVES_TO
CREATE TABLE SAVES_TO (
    User_ID INT NOT NULL,
    Profile_ID INT NOT NULL,
    Content_ID INT NOT NULL,
    Added_Date DATETIME NOT NULL,
    CONSTRAINT PK_SAVES_TO PRIMARY KEY (User_ID, Profile_ID, Content_ID),
    CONSTRAINT FK_SAVES_TO_PROFILE FOREIGN KEY (User_ID, Profile_ID) REFERENCES PROFILE(User_ID, Profile_ID)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT FK_SAVES_TO_CONTENT FOREIGN KEY (Content_ID) REFERENCES CONTENT(Content_ID)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ==================== DML: SAMPLE DATA ====================

INSERT INTO SUBSCRIPTION_TIER VALUES
(1, 'Basic', 100000.00, 2, 'HD 720p'),
(2, 'Standard', 90000.00, 3, 'Full HD 1080p'),
(3, 'Premium', 83333.33, 4, 'Ultra HD 4K'),
(4, 'Mobile', 60000.00, 1, 'HD 720p'),
(5, 'Family', 120000.00, 5, 'Ultra HD 4K');

INSERT INTO USER VALUES
(1, 'trungnguyen', 'trung@example.com', 'hashed_pw_001', '2026-01-05 08:30:00', 1),
(2, 'minhthu', 'minhthu@example.com', 'hashed_pw_002', '2026-01-10 09:15:00', 2),
(3, 'anhdung', 'dung@example.com', 'hashed_pw_003', '2026-01-15 10:00:00', 3),
(4, 'ngocmai', 'ngocmai@example.com', 'hashed_pw_004', '2026-02-01 14:20:00', 4),
(5, 'hoangnam', 'hoangnam@example.com', 'hashed_pw_005', '2026-02-12 16:45:00', 5),
(6, 'thanhha', 'thanhha@example.com', 'hashed_pw_006', '2026-02-20 11:10:00', 1),
(7, 'quanghuy', 'quanghuy@example.com', 'hashed_pw_007', '2026-03-03 19:30:00', 2),
(8, 'linhchi', 'linhchi@example.com', 'hashed_pw_008', '2026-03-18 20:00:00', 3);

INSERT INTO TV_SERIES VALUES
(1, 'The Last Horizon', 'A science fiction adventure series.', 2),
(2, 'Campus Stories', 'Stories about friendship and student life.', 3),
(3, 'Mystery House', 'A mystery series about an unusual old house.', 1),
(4, 'Code Warriors', 'A technology drama about young programmers.', 2),
(5, 'Wild Planet', 'A documentary series about nature and wildlife.', 4);

INSERT INTO CONTENT VALUES
(1, 'The Silent Sea', 'A survival movie set in a remote ocean research station.', 2022, 'PG-13'),
(2, 'Midnight Run', 'An action movie about a dangerous night journey.', 2023, 'PG-13'),
(3, 'Beyond the Stars', 'A science fiction movie about a mission into deep space.', 2024, 'PG'),
(4, 'The Last Letter', 'A drama about family, friendship, and an old letter.', 2021, 'PG'),
(5, 'Summer Rain', 'A romantic story taking place during one summer.', 2025, 'PG'),
(6, 'The Last Horizon - S01E01', 'The first episode of The Last Horizon.', 2024, 'PG-13'),
(7, 'Campus Stories - S01E01', 'The first episode of Campus Stories.', 2025, 'PG'),
(8, 'Mystery House - S01E01', 'The first episode of Mystery House.', 2023, 'PG-13'),
(9, 'Code Warriors - S01E01', 'The first episode of Code Warriors.', 2025, 'PG-13'),
(10, 'Wild Planet - S01E01', 'The first episode of Wild Planet.', 2024, 'G');

INSERT INTO CONTENT_GENRE VALUES
(1, 'Drama'), (1, 'Thriller'), (2, 'Action'), (3, 'Science Fiction'), (4, 'Drama'),
(5, 'Romance'), (6, 'Science Fiction'), (7, 'Comedy'), (8, 'Mystery'), (9, 'Technology');

INSERT INTO MOVIE VALUES
(1, 118, 'https://example.com/video/movie01'),
(2, 105, 'https://example.com/video/movie02'),
(3, 132, 'https://example.com/video/movie03'),
(4, 110, 'https://example.com/video/movie04'),
(5, 98, 'https://example.com/video/movie05');

INSERT INTO EPISODE VALUES
(6, 1, 1, 48, 'https://example.com/video/episode01', 1),
(7, 1, 1, 42, 'https://example.com/video/episode02', 2),
(8, 1, 1, 50, 'https://example.com/video/episode03', 3),
(9, 1, 1, 45, 'https://example.com/video/episode04', 4),
(10, 1, 1, 55, 'https://example.com/video/episode05', 5);

INSERT INTO PROFILE VALUES
(1, 1, 'Trung', 'https://example.com/avatar/01', FALSE),
(1, 2, 'Be Bo', 'https://example.com/avatar/02', TRUE),
(2, 1, 'Thu', 'https://example.com/avatar/03', FALSE),
(3, 1, 'Dung', 'https://example.com/avatar/04', FALSE),
(4, 1, 'Mai', 'https://example.com/avatar/05', FALSE),
(5, 1, 'Nam', 'https://example.com/avatar/06', FALSE),
(6, 1, 'Ha', 'https://example.com/avatar/07', FALSE),
(7, 1, 'Huy', 'https://example.com/avatar/08', FALSE);

INSERT INTO WATCHES VALUES
(1, 1, 1, '2026-09-01 20:00:00', 7080, TRUE, 5),     -- Movie 1: 118 phút = 7080 s, xem hết
(1, 2, 5, '2026-09-02 19:30:00', 1500, FALSE, NULL), -- Movie 5: 98 phút, xem dở 25 phút
(2, 1, 2, '2026-09-03 21:00:00', 6300, TRUE, 4),     -- Movie 2: 105 phút = 6300 s, xem hết
(3, 1, 3, '2026-09-04 20:15:00', 6000, FALSE, 4),    -- Movie 3: 132 phút = 7920 s, chỉ đạt 76%
(4, 1, 6, '2026-09-05 19:00:00', 2880, TRUE, 5),     -- Episode 6: 48 phút = 2880 s, xem hết
(5, 1, 7, '2026-09-06 20:30:00', 1800, FALSE, 3),    -- Episode 7: 42 phút = 2520 s, đạt 71%
(6, 1, 8, '2026-09-07 18:45:00', 3000, TRUE, 4),     -- Episode 8: 50 phút = 3000 s, xem hết
(7, 1, 10, '2026-09-08 21:10:00', 3300, TRUE, 5);    -- Episode 10: 55 phút = 3300 s, xem hết

INSERT INTO SAVES_TO VALUES
(1, 1, 2, '2026-09-01 18:00:00'),
(1, 2, 3, '2026-09-02 18:30:00'),
(2, 1, 4, '2026-09-03 19:00:00'),
(3, 1, 5, '2026-09-04 19:15:00'),
(4, 1, 6, '2026-09-05 17:30:00'),
(5, 1, 8, '2026-09-06 18:00:00'),
(6, 1, 9, '2026-09-07 18:15:00'),
(7, 1, 10, '2026-09-08 19:00:00');

-- END
