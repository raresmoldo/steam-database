
INSERT INTO developers (name, country) VALUES
('Team Cherry', 'Australia'),
('Supergiant Games', 'USA'),
('Mega Crit', NULL);

INSERT INTO publishers (name, country) VALUES
('Team Cherry', 'Australia'),
('Supergiant Games', 'USA');

INSERT INTO genres (name) VALUES ('Roguelike'), ('Metroidvania'), ('Sandbox');

INSERT INTO games (title, release_date, price, developer_id, publisher_id) VALUES
('Hollow Knight', '2017-02-24', 14.99,
    (SELECT developer_id FROM developers WHERE name = 'Team Cherry'),
    (SELECT publisher_id FROM publishers WHERE name = 'Team Cherry')),
('Hades', '2020-09-17', 24.99,
    (SELECT developer_id FROM developers WHERE name = 'Supergiant Games'),
    (SELECT publisher_id FROM publishers WHERE name = 'Supergiant Games'));

INSERT INTO game_genres (game_id, genre_id)
SELECT g.game_id, ge.genre_id
FROM games g, genres ge
WHERE (g.title = 'Hollow Knight' AND ge.name IN ('Metroidvania', 'Adventure', 'Indie'))
   OR (g.title = 'Hades'         AND ge.name IN ('Roguelike', 'Action', 'Indie'));

-- users (ghost_account has no country -> NULL)
INSERT INTO users (username, email, country, created_at, wallet_balance) VALUES
('steam_newbie',  'newbie@example.com', 'Romania', '2024-01-15', 20.00),
('ghost_account', 'ghost@example.com',  NULL,      '2024-02-01',  0.00);

-- library
INSERT INTO library (user_id, game_id, purchase_date, price_paid, hours_played)
SELECT u.user_id, g.game_id, '2024-01-16', g.price, 0.5
FROM users u, games g
WHERE u.username = 'steam_newbie'
  AND g.title IN ('Hollow Knight', 'Counter-Strike 2', 'Stardew Valley');

-- reviews (review_text is NULL on purpose)
INSERT INTO reviews (user_id, game_id, recommended, review_text, posted_at)
SELECT u.user_id, g.game_id, TRUE, NULL, '2024-02-01'
FROM users u, games g
WHERE u.username = 'steam_newbie' AND g.title = 'Hollow Knight';

-- friendships (user_id must be smaller than friend_id)
INSERT INTO friendships (user_id, friend_id, since)
SELECT a.user_id, b.user_id, '2024-01-20'
FROM users a, users b
WHERE a.username = 'pixel_knight' AND b.username = 'steam_newbie';

-- ---- INSERTS THAT VIOLATE REFERENTIAL INTEGRITY ----
-- Run each of these ALONE (Cmd+Enter); they are supposed to fail.

-- user 999 does not exist -> foreign key violation on library.user_id
INSERT INTO library (user_id, game_id, purchase_date, price_paid, hours_played)
VALUES (999, 1, '2024-03-01', 9.99, 0);

-- developer 99 does not exist -> foreign key violation on games.developer_id
INSERT INTO games (title, release_date, price, developer_id, publisher_id)
VALUES ('Ghost Game', '2024-01-01', 9.99, 99, 1);


-- games: 10% discount on old, non-free games          [<, AND]
UPDATE games
SET price = ROUND(price * 0.9, 2)
WHERE release_date < '2015-01-01' AND price > 0;

-- users: fill in missing country                      [IS NULL]
UPDATE users SET country = 'Unknown' WHERE country IS NULL;

-- developers: fill in missing country                 [IS NULL]
UPDATE developers SET country = 'Unknown' WHERE country IS NULL;

-- library: bonus hours for some users/games           [IN, BETWEEN, <>]
UPDATE library
SET hours_played = hours_played + 5
WHERE user_id IN (1, 2, 3)
  AND game_id BETWEEN 1 AND 5
  AND price_paid <> 0;

-- users: add 10 to the wallet of Romanian/Polish users who are not rich   [OR, NOT, parentheses]
UPDATE users
SET wallet_balance = wallet_balance + 10
WHERE (country = 'Romania' OR country = 'Poland')
  AND NOT (wallet_balance > 50);

-- reviews: mark reviews that mention bugs             [LIKE]
UPDATE reviews
SET review_text = review_text || ' [edited]'
WHERE review_text LIKE '%bug%';

-- reviews: give empty reviews a placeholder text      [IS NULL]
UPDATE reviews SET review_text = 'No comment' WHERE review_text IS NULL;


-- reviews: remove placeholder reviews from 2024       [LIKE, >=]
DELETE FROM reviews
WHERE review_text LIKE 'No comment%' AND posted_at >= '2024-01-01';

-- library: remove barely played free games            [<=, NOT]
DELETE FROM library
WHERE hours_played <= 1 AND NOT (price_paid > 0);

-- friendships: remove the 2024 friendship of the new user   [IN, BETWEEN]
DELETE FROM friendships
WHERE friend_id IN (SELECT user_id FROM users WHERE username = 'steam_newbie')
  AND since BETWEEN '2024-01-01' AND '2024-12-31';

-- genres: remove genres that no game uses             [NOT IN]
DELETE FROM genres
WHERE genre_id NOT IN (SELECT genre_id FROM game_genres);

-- developers: remove developers with no games         [IS NOT NULL, NOT IN]
DELETE FROM developers
WHERE country IS NOT NULL
  AND developer_id NOT IN (SELECT developer_id FROM games);


-- a1. UNION + OR + parentheses + ORDER BY: budget/free games and premium games
SELECT title, price, 'Budget' AS category
FROM games
WHERE (price = 0 OR price < 10) AND NOT (release_date > '2024-01-01')
UNION
SELECT title, price, 'Premium'
FROM games
WHERE price >= 50
ORDER BY price;

-- a2. UNION ALL + ORDER BY + LIMIT: the 10 most recent events (purchases and reviews)
SELECT user_id, purchase_date AS event_date, 'purchase' AS event_type FROM library
UNION ALL
SELECT user_id, posted_at, 'review' FROM reviews
ORDER BY event_date DESC
LIMIT 10;


SELECT u.username
FROM users u
JOIN library l ON l.user_id = u.user_id
JOIN games g ON g.game_id = l.game_id
WHERE g.title = 'Elden Ring'
INTERSECT
SELECT u.username
FROM users u
JOIN library l ON l.user_id = u.user_id
JOIN games g ON g.game_id = l.game_id
WHERE g.title = 'Baldur''s Gate 3';

SELECT DISTINCT username
FROM users
WHERE user_id IN (SELECT user_id FROM reviews WHERE recommended = TRUE)
  AND user_id IN (SELECT user_id FROM library WHERE hours_played > 100);


SELECT title FROM games
EXCEPT
SELECT g.title
FROM games g
JOIN library l ON l.game_id = g.game_id;

-- c2. NOT IN: users who never wrote a review
SELECT username
FROM users
WHERE user_id NOT IN (SELECT user_id FROM reviews);

-- d1. INNER JOIN on 3 tables + arithmetic: games with developer, publisher and sale price
SELECT g.title, d.name AS developer, p.name AS publisher,
       g.price, ROUND(g.price * 0.8, 2) AS sale_price
FROM games g
INNER JOIN developers d ON d.developer_id = g.developer_id
INNER JOIN publishers p ON p.publisher_id = g.publisher_id
ORDER BY g.price DESC;

-- d2. LEFT JOIN over TWO many-to-many relationships
--     (users <-> games via library, games <-> genres via game_genres)
--     Users without games still appear (with NULLs)
SELECT u.username, g.title, ge.name AS genre
FROM users u
LEFT JOIN library l      ON l.user_id = u.user_id
LEFT JOIN games g        ON g.game_id = l.game_id
LEFT JOIN game_genres gg ON gg.game_id = g.game_id
LEFT JOIN genres ge      ON ge.genre_id = gg.genre_id
ORDER BY u.username, g.title;

-- d3. RIGHT JOIN: every achievement with how many users unlocked it (0 = nobody yet)
SELECT a.name AS achievement, g.title, COUNT(ua.user_id) AS unlocked_by
FROM user_achievements ua
RIGHT JOIN achievements a ON a.achievement_id = ua.achievement_id
JOIN games g ON g.game_id = a.game_id
GROUP BY a.name, g.title
ORDER BY unlocked_by;

-- d4. FULL JOIN: all games and all reviews (games without reviews show NULL review)
SELECT g.title, r.review_id, r.recommended
FROM games g
FULL JOIN reviews r ON r.game_id = g.game_id
ORDER BY g.title;

-- ---------- e. IN with subquery ----------

-- e1. Nested IN + DISTINCT: users who own at least one game made by Valve
SELECT DISTINCT username
FROM users
WHERE user_id IN (
    SELECT user_id FROM library
    WHERE game_id IN (
        SELECT game_id FROM games
        WHERE developer_id IN (SELECT developer_id FROM developers WHERE name = 'Valve')
    )
);

-- e2. IN + AND NOT + arithmetic: paid games with a negative review, and their sale price
SELECT title, price, ROUND(price * 0.8, 2) AS sale_price
FROM games
WHERE game_id IN (SELECT game_id FROM reviews WHERE recommended = FALSE)
  AND NOT (price = 0);

-- ---------- f. EXISTS ----------

-- f1. EXISTS + OR: users who have at least one friend
SELECT u.username
FROM users u
WHERE EXISTS (
    SELECT 1 FROM friendships f
    WHERE f.user_id = u.user_id OR f.friend_id = u.user_id
);

-- f2. EXISTS + AND NOT: users who reviewed a game they played a lot (100h or more)
SELECT u.username
FROM users u
WHERE EXISTS (
    SELECT 1
    FROM reviews r
    JOIN library l ON l.user_id = r.user_id AND l.game_id = r.game_id
    WHERE r.user_id = u.user_id AND NOT (l.hours_played < 100)
);

-- ---------- g. Subquery in FROM ----------

-- g1. Games whose average playtime is above 100 hours
SELECT g.title, ROUND(t.avg_hours, 1) AS avg_hours
FROM (SELECT game_id, AVG(hours_played) AS avg_hours
      FROM library
      GROUP BY game_id) AS t
JOIN games g ON g.game_id = t.game_id
WHERE t.avg_hours > 100
ORDER BY t.avg_hours DESC;

-- g2. Top 3 spenders, with average price paid per game (arithmetic) + LIMIT
SELECT u.username, s.total_spent, s.games_owned,
       ROUND(s.total_spent / s.games_owned, 2) AS avg_price_per_game
FROM (SELECT user_id, SUM(price_paid) AS total_spent, COUNT(*) AS games_owned
      FROM library
      GROUP BY user_id) AS s
JOIN users u ON u.user_id = s.user_id
ORDER BY s.total_spent DESC
LIMIT 3;

-- ---------- h. GROUP BY / HAVING ----------

-- h1. GROUP BY (no HAVING) - COUNT, MIN, MAX: games and price range per developer
SELECT d.name AS developer, COUNT(*) AS games,
       MIN(g.price) AS cheapest, MAX(g.price) AS priciest
FROM developers d
JOIN games g ON g.developer_id = d.developer_id
GROUP BY d.name
ORDER BY games DESC;

-- h2. HAVING (no subquery) + arithmetic: % of positive reviews for games with 2+ reviews
SELECT g.title, COUNT(*) AS reviews,
       ROUND(100.0 * SUM(CASE WHEN r.recommended THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_positive
FROM reviews r
JOIN games g ON g.game_id = r.game_id
GROUP BY g.title
HAVING COUNT(*) >= 2
ORDER BY pct_positive DESC;

-- h3. HAVING with subquery - AVG: games played more than the overall average
SELECT g.title, ROUND(AVG(l.hours_played), 1) AS avg_hours
FROM games g
JOIN library l ON l.game_id = g.game_id
GROUP BY g.title
HAVING AVG(l.hours_played) > (SELECT AVG(hours_played) FROM library)
ORDER BY avg_hours DESC;

-- h4. HAVING with subquery (that has its own subquery in FROM) - SUM:
--     users who spent more than the average user
SELECT u.username, SUM(l.price_paid) AS total_spent
FROM users u
JOIN library l ON l.user_id = u.user_id
GROUP BY u.username
HAVING SUM(l.price_paid) > (
    SELECT AVG(total)
    FROM (SELECT SUM(price_paid) AS total FROM library GROUP BY user_id) AS t
)
ORDER BY total_spent DESC;

-- ---------- i. ANY / ALL (each followed by its rewrite) ----------

-- i1. > ANY: games more expensive than at least one CD Projekt Red game
SELECT title, price FROM games
WHERE price > ANY (SELECT price FROM games
                   WHERE developer_id = (SELECT developer_id FROM developers WHERE name = 'CD Projekt Red'));
-- i1 rewritten with an aggregate (MIN)
SELECT title, price FROM games
WHERE price > (SELECT MIN(price) FROM games
               WHERE developer_id = (SELECT developer_id FROM developers WHERE name = 'CD Projekt Red'));

-- i2. > ALL: library entries played more than every game of user 3
SELECT user_id, game_id, hours_played FROM library
WHERE hours_played > ALL (SELECT hours_played FROM library WHERE user_id = 3);
-- i2 rewritten with an aggregate (MAX)
SELECT user_id, game_id, hours_played FROM library
WHERE hours_played > (SELECT MAX(hours_played) FROM library WHERE user_id = 3);

-- i3. = ANY: users who wrote at least one negative review
SELECT DISTINCT username FROM users
WHERE user_id = ANY (SELECT user_id FROM reviews WHERE recommended = FALSE);
-- i3 rewritten with IN
SELECT DISTINCT username FROM users
WHERE user_id IN (SELECT user_id FROM reviews WHERE recommended = FALSE);

-- i4. <> ALL: games that are not in any library
SELECT title FROM games
WHERE game_id <> ALL (SELECT game_id FROM library);
-- i4 rewritten with NOT IN
SELECT title FROM games
WHERE game_id NOT IN (SELECT game_id FROM library);
