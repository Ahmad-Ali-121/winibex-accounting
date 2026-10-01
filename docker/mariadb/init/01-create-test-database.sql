-- Tests run against a real database, never a mock, so they need their own.
-- A test run rebuilds it, which must never be possible against development.
--
-- utf8mb4_uca1400_ai_ci is the MariaDB 11.6+ default. MySQL's
-- utf8mb4_0900_ai_ci does not exist on this server.

CREATE DATABASE IF NOT EXISTS winibex_test
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_uca1400_ai_ci;

GRANT ALL PRIVILEGES ON winibex_test.* TO 'winibex'@'%';

FLUSH PRIVILEGES;
