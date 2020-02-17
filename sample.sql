
CREATE TABLE users
(
  id SERIAL NOT NULL PRIMARY KEY ,
  name VARCHAR( 25 ) NOT NULL ,
  email VARCHAR( 35 ) NOT NULL ,
  password VARCHAR( 60 ) NOT NULL ,
  UNIQUE (email)
);

INSERT INTO users
  (name, email, password)
VALUES
  ('kinjo', 'kinjo@mail.com', 'kinjo')
;
3