
DROP TABLE IF EXISTS user_achievements CASCADE;
DROP TABLE IF EXISTS achievements CASCADE;
DROP TABLE IF EXISTS friendships CASCADE;
DROP TABLE IF EXISTS reviews CASCADE;
DROP TABLE IF EXISTS library CASCADE;
DROP TABLE IF EXISTS game_genres CASCADE;
DROP TABLE IF EXISTS games CASCADE;
DROP TABLE IF EXISTS genres CASCADE;
DROP TABLE IF EXISTS publishers CASCADE;
DROP TABLE IF EXISTS developers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE developers (
    developer_id  SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    country       VARCHAR(60)
);

CREATE TABLE publishers (
    publisher_id  SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,
    country       VARCHAR(60)
);

CREATE TABLE genres (
    genre_id  SERIAL PRIMARY KEY,
    name      VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE games (
    game_id       SERIAL PRIMARY KEY,
    title         VARCHAR(150) NOT NULL,
    release_date  DATE NOT NULL,
    price         NUMERIC(6,2) NOT NULL CHECK (price >= 0),
    developer_id  INT NOT NULL REFERENCES developers(developer_id),
    publisher_id  INT NOT NULL REFERENCES publishers(publisher_id)
);

CREATE TABLE game_genres (
    game_id   INT REFERENCES games(game_id) ON DELETE CASCADE,
    genre_id  INT REFERENCES genres(genre_id) ON DELETE CASCADE,
    PRIMARY KEY (game_id, genre_id)
);

CREATE TABLE users (
    user_id         SERIAL PRIMARY KEY,
    username        VARCHAR(40) NOT NULL UNIQUE,
    email           VARCHAR(100) NOT NULL UNIQUE,
    country         VARCHAR(60),
    created_at      DATE NOT NULL DEFAULT CURRENT_DATE,
    wallet_balance  NUMERIC(8,2) NOT NULL DEFAULT 0 CHECK (wallet_balance >= 0)
);

CREATE TABLE library (
    user_id        INT REFERENCES users(user_id) ON DELETE CASCADE,
    game_id        INT REFERENCES games(game_id) ON DELETE CASCADE,
    purchase_date  DATE NOT NULL,
    price_paid     NUMERIC(6,2) NOT NULL CHECK (price_paid >= 0),
    hours_played   NUMERIC(7,1) NOT NULL DEFAULT 0 CHECK (hours_played >= 0),
    PRIMARY KEY (user_id, game_id)
);

CREATE TABLE reviews (
    review_id    SERIAL PRIMARY KEY,
    user_id      INT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    game_id      INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    recommended  BOOLEAN NOT NULL,
    review_text  TEXT,
    posted_at    DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (user_id, game_id)
);

CREATE TABLE friendships (
    user_id    INT REFERENCES users(user_id) ON DELETE CASCADE,
    friend_id  INT REFERENCES users(user_id) ON DELETE CASCADE,
    since      DATE NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (user_id, friend_id),
    CHECK (user_id < friend_id)
);

CREATE TABLE achievements (
    achievement_id  SERIAL PRIMARY KEY,
    game_id         INT NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    description     VARCHAR(255)
);

CREATE TABLE user_achievements (
    user_id         INT REFERENCES users(user_id) ON DELETE CASCADE,
    achievement_id  INT REFERENCES achievements(achievement_id) ON DELETE CASCADE,
    unlocked_at     DATE NOT NULL,
    PRIMARY KEY (user_id, achievement_id)
);


INSERT INTO developers (name, country) VALUES
('Valve', 'USA'),                 -- 1
('CD Projekt Red', 'Poland'),     -- 2
('FromSoftware', 'Japan'),        -- 3
('Re-Logic', 'USA'),              -- 4
('ConcernedApe', 'USA'),          -- 5
('Larian Studios', 'Belgium');    -- 6

INSERT INTO publishers (name, country) VALUES
('Valve', 'USA'),                 -- 1
('CD Projekt', 'Poland'),         -- 2
('Bandai Namco', 'Japan'),        -- 3
('Re-Logic', 'USA'),              -- 4
('ConcernedApe', 'USA'),          -- 5
('Larian Studios', 'Belgium');    -- 6

INSERT INTO genres (name) VALUES
('Action'),       -- 1
('RPG'),          -- 2
('Puzzle'),       -- 3
('FPS'),          -- 4
('Simulation'),   -- 5
('Adventure'),    -- 6
('Strategy'),     -- 7
('Indie'),        -- 8
('Multiplayer');  -- 9

INSERT INTO games (title, release_date, price, developer_id, publisher_id) VALUES
('Portal 2',            '2011-04-18',  9.99, 1, 1),  -- 1
('Counter-Strike 2',    '2023-09-27',  0.00, 1, 1),  -- 2
('Half-Life: Alyx',     '2020-03-23', 59.99, 1, 1),  -- 3
('The Witcher 3',       '2015-05-18', 39.99, 2, 2),  -- 4
('Cyberpunk 2077',      '2020-12-10', 59.99, 2, 2),  -- 5
('Elden Ring',          '2022-02-25', 59.99, 3, 3),  -- 6
('Dark Souls III',      '2016-04-12', 59.99, 3, 3),  -- 7
('Terraria',            '2011-05-16',  9.99, 4, 4),  -- 8
('Stardew Valley',      '2016-02-26', 14.99, 5, 5),  -- 9
('Baldur''s Gate 3',    '2023-08-03', 59.99, 6, 6),  -- 10
('Dota 2',              '2013-07-09',  0.00, 1, 1),  -- 11
('Left 4 Dead 2',       '2009-11-17',  9.99, 1, 1);  -- 12

INSERT INTO game_genres (game_id, genre_id) VALUES
(1,3),(1,6),
(2,1),(2,4),(2,9),
(3,4),(3,6),
(4,2),(4,6),
(5,1),(5,2),
(6,1),(6,2),
(7,1),(7,2),
(8,6),(8,8),
(9,5),(9,8),
(10,2),(10,7),
(11,7),(11,9),
(12,1),(12,4),(12,9);

INSERT INTO users (username, email, country, created_at, wallet_balance) VALUES
('gabe_fan99',     'gabe@example.com',     'USA',      '2015-03-12',  25.50),  -- 1
('pixel_knight',   'knight@example.com',   'Romania',  '2017-07-01',   0.00),  -- 2
('farm_queen',     'queen@example.com',    'Canada',   '2018-01-20',  12.00),  -- 3
('witcher_wolf',   'wolf@example.com',     'Poland',   '2016-11-05',  80.00),  -- 4
('headshot_hero',  'hero@example.com',     'Germany',  '2019-04-18',   5.25),  -- 5
('terra_digger',   'digger@example.com',   'UK',       '2020-02-09',  40.00),  -- 6
('souls_veteran',  'veteran@example.com',  'Japan',    '2014-09-30',   0.00),  -- 7
('alyx_vance_vr',  'vr@example.com',       'France',   '2021-06-14',  15.75),  -- 8
('cozy_gamer',     'cozy@example.com',     'Romania',  '2022-12-25',  30.00),  -- 9
('dice_roller',    'dice@example.com',     'Belgium',  '2023-08-04',   9.99);  -- 10

INSERT INTO library (user_id, game_id, purchase_date, price_paid, hours_played) VALUES
(1, 1,  '2015-04-01',  4.99,  12.5),
(1, 2,  '2023-09-28',  0.00, 640.0),
(1, 4,  '2016-01-10', 19.99, 210.3),
(1, 6,  '2022-03-01', 59.99, 145.0),
(1, 8,  '2018-12-20',  2.99,  88.4),
(2, 2,  '2023-10-01',  0.00, 320.5),
(2, 5,  '2021-01-05', 29.99,  60.2),
(2, 6,  '2022-06-15', 41.99, 190.0),
(2, 10, '2023-08-05', 59.99, 175.8),
(3, 1,  '2019-05-10',  1.99,   9.0),
(3, 8,  '2019-07-04',  4.99, 120.0),
(3, 9,  '2018-02-14', 14.99, 450.6),
(3, 12, '2020-11-27',  2.49,  35.0),
(4, 4,  '2016-11-10', 39.99, 380.0),
(4, 5,  '2020-12-10', 59.99,  92.5),
(4, 7,  '2017-03-03', 19.99,  70.0),
(4, 10, '2023-08-03', 59.99, 210.0),
(5, 2,  '2023-09-27',  0.00, 1200.0),
(5, 11, '2019-05-01',  0.00, 2300.7),
(5, 12, '2019-06-12',  1.99,  50.0),
(6, 1,  '2020-03-15',  1.99,  11.0),
(6, 8,  '2020-02-10',  9.99, 310.0),
(6, 9,  '2021-08-21',  7.49, 95.2),
(7, 6,  '2022-02-25', 59.99, 300.0),
(7, 7,  '2016-04-12', 59.99, 250.5),
(7, 10, '2023-09-01', 50.99, 120.0),
(8, 2,  '2023-09-30',  0.00,  15.0),
(8, 3,  '2020-03-23', 59.99,  22.0),
(8, 11, '2021-07-07',  0.00,  80.0),
(9, 4,  '2022-12-26', 14.99,  55.0),
(9, 9,  '2022-12-26',  7.49, 140.3),
(10, 2, '2023-08-04',  0.00,  30.0),
(10, 6, '2023-08-10', 49.99,  95.0),
(10, 10,'2023-08-04', 59.99, 330.0);

INSERT INTO reviews (user_id, game_id, recommended, review_text, posted_at) VALUES
(1, 6,  TRUE,  'Huge open world, brutal but fair.',                   '2022-04-02'),
(1, 4,  TRUE,  'Best RPG story I have ever played.',                  '2016-03-15'),
(2, 5,  FALSE, 'Too many bugs at launch.',                            '2021-01-20'),
(2, 10, TRUE,  'Incredible choices and characters.',                  '2023-10-10'),
(3, 9,  TRUE,  'Perfect cozy game.',                                  '2018-06-01'),
(4, 5,  FALSE, 'Not what was promised.',                              '2021-01-02'),
(4, 10, TRUE,  'Game of the year material.',                          '2023-11-20'),
(5, 2,  TRUE,  'Smooth gameplay, great updates.',                     '2023-12-01'),
(6, 9,  TRUE,  'Relaxing and addictive.',                             '2021-09-10'),
(7, 7,  TRUE,  'Fantastic boss fights.',                              '2017-01-12'),
(8, 3,  TRUE,  'VR at its absolute best.',                            '2020-04-01'),
(10, 6, TRUE,  'Challenging but rewarding.',                          '2023-09-15');

INSERT INTO friendships (user_id, friend_id, since) VALUES
(1, 2,  '2018-05-01'),
(1, 3,  '2018-06-10'),
(2, 4,  '2019-02-14'),
(2, 10, '2023-09-01'),
(3, 6,  '2020-03-03'),
(4, 7,  '2017-08-08'),
(5, 8,  '2021-09-09'),
(6, 9,  '2022-12-30'),
(7, 10, '2023-09-05');

INSERT INTO achievements (game_id, name, description) VALUES
(1,  'Wake Up Call',    'Complete the first chapter of Portal 2'),     -- 1
(1,  'Lab Rat',         'Finish the game on any difficulty'),          -- 2
(6,  'Elden Lord',      'Reach any ending'),                           -- 3
(6,  'Rune Collector',  'Collect 50 Great Runes worth of fragments'),  -- 4
(8,  'Boss Slayer',     'Defeat the Eye of Cthulhu'),                  -- 5
(8,  'Deep Digger',     'Reach the Underworld'),                       -- 6
(9,  'Green Thumb',     'Harvest 100 crops'),                          -- 7
(9,  'Community Hero',  'Complete the Community Center'),              -- 8
(10, 'Tavern Hero',     'Complete Act 1'),                             -- 9
(10, 'Dice Master',     'Succeed on 20 critical rolls');               -- 10

INSERT INTO user_achievements (user_id, achievement_id, unlocked_at) VALUES
(1, 1,  '2015-04-02'),
(1, 3,  '2022-05-10'),
(1, 5,  '2019-01-05'),
(1, 6,  '2019-02-11'),
(2, 3,  '2022-08-20'),
(2, 9,  '2023-08-20'),
(3, 1,  '2019-05-12'),
(3, 5,  '2019-09-01'),
(3, 7,  '2018-03-01'),
(3, 8,  '2018-09-15'),
(4, 9,  '2023-08-25'),
(4, 10, '2023-10-02'),
(6, 1,  '2020-03-16'),
(6, 7,  '2021-09-01'),
(6, 8,  '2021-11-11'),
(7, 3,  '2022-04-10'),
(7, 4,  '2022-05-30'),
(9, 7,  '2023-01-10'),
(10, 3, '2023-09-20'),
(10, 9, '2023-08-12');
