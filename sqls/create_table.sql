
CREATE TABLE Books
(
  id SERIAL NOT NULL,
  title VARCHAR(225),
  authoer VARCHAR(225),
  description VARCHAR(225),
  thumbnail VARCHAR(225),
  isbn text,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);



CREATE TABLE TagMaps
(
  id SERIAL NOT NULL,
  books_id INT NOT NULL,
  tags_id INT NOT NULL
);



CREATE TABLE Tags
(
  id SERIAL NOT NULL,
  tag_name VARCHAR(20) NOT NULL,
  user_id INT NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);



CREATE TABLE Histories
(
  id SERIAL NOT NULL,
  user_lend_id INT NOT NULL,
  user_borrow_id INT NOT NULL,
  books_id INT NOT NULL,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);



CREATE TABLE Users
(
  id SERIAL NOT NULL,
  email VARCHAR(45) unique NOT NULL,
  password VARCHAR(45) NOT NULL,
  name VARCHAR(20) NOT NULL,
  thumnail_img VARCHAR(225) ,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);



CREATE TABLE AuthoerMaps
(
  id SERIAL NOT NULL,
  books_id INT NOT NULL,
  name VARCHAR(20) NOT NULL
);


CREATE TABLE BookOwnerMaps
(
  id SERIAL NOT NULL,
  user_id INT NOT NULL,
  books_id INT NOT NULL
);

