import csv
import os
import random
from datetime import datetime, timedelta


def main(output_dir: str = "csv_output"):
    os.makedirs(output_dir, exist_ok=True)
    now = datetime.now()

    n_users = 500
    n_movies = 300
    n_series = 10
    eps_per_series = 10
    max_watch = 400
    max_save = 400

    ratings_pool = ["G", "PG", "PG-13", "R", "NC-17", "TV-Y", "TV-MA"]
    genres_pool = [
        "Action",
        "Drama",
        "Comedy",
        "Romance",
        "Thriller",
        "Science Fiction",
        "Mystery",
        "Documentary",
    ]

    # 1. TV_SERIES
    tv_series_rows = []
    for i in range(1, n_series + 1):
        tv_series_rows.append([i, f"Series {i}", "Auto-generated series.", 1])

    # 2a. MOVIE + CONTENT + CONTENT_GENRE (1..300)
    # Lưu ý: giữ đúng thứ tự cột theo file SQL gốc
    content_rows = []
    movie_rows = []
    episode_rows = []
    genre_rows = []
    duration_map = {}  # Content_ID -> Duration_Minutes

    for i in range(1, n_movies + 1):
        dur = 60 + random.randint(0, 90)
        duration_map[i] = dur
        release_year = 2010 + random.randint(0, 15)
        age_rating = random.choice(ratings_pool)
        genre = random.choice(genres_pool)

        content_rows.append([i, f"Movie {i}", "Auto-generated movie.", release_year, age_rating])
        movie_rows.append([i, dur, f"https://example.com/video/movie{i}"])
        genre_rows.append([i, genre])

    # 2b. EPISODE + CONTENT + CONTENT_GENRE (301..400)
    for i in range(1, n_series + 1):
        for j in range(1, eps_per_series + 1):
            cid = n_movies + (i - 1) * eps_per_series + j
            ep_num = cid - n_movies
            dur = 40 + random.randint(0, 15)
            duration_map[cid] = dur
            release_year = 2010 + random.randint(0, 15)
            age_rating = random.choice(ratings_pool)
            genre = random.choice(genres_pool)

            content_rows.append([cid, f"Ep {ep_num}", "Auto-generated episode.", release_year, age_rating])
            episode_rows.append([cid, 1, j, dur, f"https://example.com/video/ep{ep_num}", i])
            genre_rows.append([cid, genre])

    # 3. USER và PROFILE
    user_rows = []
    profile_rows = []
    all_profiles = []

    for i in range(1, n_users + 1):
        created_at = (now - timedelta(days=random.randint(0, 300))).strftime("%Y-%m-%d %H:%M:%S")
        tier = 1 + random.randint(0, 2)
        user_rows.append([i, f"user{i}", f"user{i}@example.com", "hashed_pw", created_at, tier])

        n_prof = 2 if i == 1 else (1 + random.randint(0, 4))
        for j in range(1, n_prof + 1):
            is_kids = 1 if ((i == 1 and j == 2) or random.random() < 0.2) else 0
            profile_rows.append([j, i, f"Profile {j}", "", is_kids])
            all_profiles.append((i, j))

    # 4. WATCHES và SAVES_TO
    all_cids = [row[0] for row in content_rows]
    watches_rows = []
    saves_rows = []

    for uid, pid in all_profiles:
        n_w = 1 + random.randint(0, max_watch - 1)
        n_s = random.randint(0, max_save)

        # 4a. Xem: lấy ngẫu nhiên n_w phim không trùng trong cùng hồ sơ
        watched_cids = random.sample(all_cids, k=n_w)
        for cid in watched_cids:
            watched_at = (now - timedelta(days=random.randint(0, 364))).strftime("%Y-%m-%d %H:%M:%S")
            dur_sec = duration_map[cid] * 60

            r = random.random()
            if r < 0.45:
                prog = int(0.9 * dur_sec + random.random() * 0.1 * dur_sec)
            elif r < 0.75:
                prog = int(0.2 * dur_sec + random.random() * 0.7 * dur_sec)
            else:
                prog = int(random.random() * 0.2 * dur_sec)

            # Gắn is_completed = 0 (FALSE) để trigger của bạn xử lý
            rating = (1 + random.randint(0, 4)) if (random.random() < 0.6) else ""
            watches_rows.append([uid, pid, cid, watched_at, prog, 0, rating])

        # 4b. Lưu: xáo trộn độc lập, lấy n_s phim đầu
        saved_cids = random.sample(all_cids, k=n_s)
        for cid in saved_cids:
            added_date = (now - timedelta(days=random.randint(0, 199))).strftime("%Y-%m-%d %H:%M:%S")
            saves_rows.append([uid, pid, cid, added_date])

    # Ghi ra 8 file CSV (không có header để dễ import thẳng bằng LOAD DATA hoặc Table Data Import Wizard)
    files_data = {
        "tv_series.csv": tv_series_rows,
        "content.csv": content_rows,
        "movie.csv": movie_rows,
        "episode.csv": episode_rows,
        "content_genre.csv": genre_rows,
        "user.csv": user_rows,
        "profile.csv": profile_rows,
        "watches.csv": watches_rows,
        "saves_to.csv": saves_rows,
    }

    for filename, rows in files_data.items():
        path = os.path.join(output_dir, filename)
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerows(rows)

    print(f"Đã sinh xong {len(files_data)} file CSV tại thư mục: {os.path.abspath(output_dir)}")
    for filename, rows in files_data.items():
        print(f"  - {filename}: {len(rows)} dòng")


if __name__ == "__main__":
    main()