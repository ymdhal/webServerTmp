/**/
CREATE USER vymd@localhost;
SET PASSWORD FOR vymd@localhost=password('guitar');
CREATE DATABASE hoge;
GRANT ALL ON hoge.* TO vymd@localhost;
USE hoge;

/*USRS*/
CREATE TABLE hoge.usrs (
  id INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
  usrname VARCHAR(50) NOT NULL,
  email VARCHAR(100) NOT NULL,
  password VARCHAR(255) NOT NULL,
  register_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

/*My Account*/
INSERT INTO usrs (
  usrname,
  email,
  password
)
VALUES (
  "ymd.hal",
  "ymd.hal@gmail.com",
  "guitar"
);

/*User Account*/
INSERT INTO usrs (
  usrname,
  email,
  password
)
VALUES (
  "karasu",
  "karasu@gmail.com",
  "karasu"
);
