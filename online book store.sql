# 	ONLINE BOOKSTORE DATABASE SYSTEM
create database bookstore;
use bookstore;
# creation of customer table
create table customers(
cid int auto_increment primary key,
email varchar(255) unique not null,
fname varchar(100),
lname varchar(100),
created timestamp default current_timestamp
);
select * from customers;
# create table of authors
create table authors(
aid int auto_increment primary key,name varchar(20));
select * from authors;
# create table authors
create table categories(
cid int auto_increment primary key,name varchar(20) not null);
select * from categories;
# creation of table for books
create table books(
book_id int auto_increment primary key,
title varchar(20) not null,
a_id int not null,
c_id int,
price decimal(10,2) not null,
isbn varchar(10) unique,
created timestamp default current_timestamp,
foreign key(a_id) references authors(aid),
foreign key(c_id) references categories(cid)
);
select * from books;
create table inventory(
b_id int primary key,
stock int default 0,
last_restock timestamp null,
foreign key (b_id) references books(book_id));
select * from inventory;
# creation of orders
create table orders(
or_id int  auto_increment primary key,
c_id int not null,
amount decimal(12,2),
status varchar(20) default 'pending',
created timestamp default current_timestamp,
foreign key (c_id) references customers(cid)
);
select * from orders;
create table order_items(
order_item_id int auto_increment primary key,
o_id int not null,
b_id int not null,
quantity int not null,
price decimal(10,2) not null,
foreign key (o_id) references orders(or_id),
foreign key (b_id) references books(book_id)
);
select * from order_items;
create table payments(
p_id int auto_increment primary key,
or_id int unique not null,
amount decimal(12,2),
paid timestamp default current_timestamp,
method varchar(20),
foreign key(or_id) references orders(or_id));
select * from payments;
create table reviews(
review_id int auto_increment primary key,
book_id int not null,
c_id int not null,
rating int check (rating between 1 and 5),
comment text,
created timestamp default current_timestamp,
foreign key (book_id) references books(book_id),
foreign key (c_id) references customers(cid));
select * from reviews;
insert into authors(name)values('Author1'),('Authors');
insert into categories(name) values ('Fiction'),('Science'),('History');
insert into customers(email,fname,lname)values('sam@ex.com','sam','rao'),('rita@ex.com','Rita','sharma');
# insert into books
insert into books(title,a_id,c_id,price,isbn) values
('The Lost ',1,1,299.00,'978560001'),
('Science',2,2,499.50,'978110002'),
('History',1,3,350.75,'9781103'),
('AI',2,2,599.00,'97810004');
# add inventory
select * from inventory;
insert ignore into inventory(b_id,stock,last_restock) values 
(1, 50, NOW()), 
(2, 30, NOW()), 
(3, 40, NOW()), 
(4, 25, NOW());
# choose a customer to pick an order from customers table
select * from customers;
# creating an order
insert into orders(c_id,amount,status) values(1,299.00,'processing');
# get order
select last_insert_id();
# add items for the order
SELECT * FROM books WHERE book_id = 1;
# insert 
INSERT INTO order_items(o_id, b_id, quantity, price)
SELECT 1, book_id, 1, 299.00
FROM books
WHERE book_id = 1;
select * from  order_items;
# reduce inventory stock
update inventory set stock = stock - 1 where b_id = 1;
# add a payment record
insert into payments(or_id,amount,method)values(1,299.00,'credit card');
# mark order as complted
update orders set status = 'completed' where or_id = 1;
# for check order
select * from orders where or_id = 1;
# for check order items
select * from order_items where o_id = 1;
# for check inventory
select * from inventory where b_id = 1;
# for check payment
select * from payments where or_id = 1;
# total revenue
select sum(amount)as total_revenue from payments;
# revenue by day
select date(paid) as sale_date,sum(amount)as daily_revenue from payments group by date(paid)
order by sale_date;
#top selling books 
SELECT b.book_id, b.title, SUM(oi.quantity) AS total_sold FROM order_items oi
JOIN books b ON oi.b_id = b.book_id GROUP BY b.book_id, b.title ORDER BY total_sold DESC;
# customer purchase history
SELECT o.or_id, o.created, o.status, o.amount FROM orders o WHERE o.c_id = 1 ORDER BY o.created DESC;
# customer lifetime value
SELECT c.cid, c.fname, c.lname, SUM(o.amount) AS lifetime_value
FROM customers c
LEFT JOIN orders o ON c.cid = o.c_id
GROUP BY c.cid, c.fname, c.lname
ORDER BY lifetime_value DESC;
# for low cost inventory report 
SELECT b.book_id, b.title, i.stock, i.last_restock
FROM inventory i
JOIN books b ON i.b_id = b.book_id
WHERE i.stock < 10
ORDER BY i.stock ASC;
# best rated books 
SELECT b.title,
       AVG(r.rating) AS avg_rating,
       COUNT(r.review_id) AS total_reviews
FROM reviews r
JOIN books b ON r.book_id = b.book_id
GROUP BY b.title
HAVING COUNT(r.review_id) > 0
ORDER BY avg_rating DESC;
# monthly sales report
SELECT 
    DATE_FORMAT(p.paid, '%Y-%m') AS month,
    SUM(p.amount) AS monthly_sales
FROM payments p
GROUP BY DATE_FORMAT(p.paid, '%Y-%m')
ORDER BY month;
# add indexes on foreign keys
CREATE INDEX idx_books_author_id ON books(a_id);
CREATE INDEX idx_books_category_id ON books(c_id);
CREATE INDEX idx_inventory_book_id ON inventory(b_id);
CREATE INDEX idx_orders_customer_id ON orders(c_id);
CREATE INDEX idx_order_items_order_id ON order_items(o_id);
CREATE INDEX idx_order_items_book_id ON order_items(b_id);
CREATE INDEX idx_payments_order_id ON payments(or_id);
CREATE INDEX idx_reviews_book_id ON reviews(book_id);
CREATE INDEX idx_reviews_customer_id ON reviews(c_id);
# add indexes on frequently queried columns
CREATE INDEX idx_orders_created_at ON orders(created);
CREATE INDEX idx_payments_paid_at ON payments(paid);
CREATE INDEX idx_inventory_stock ON inventory(stock);
CREATE INDEX idx_books_title ON books(title);
# add composite indexes
CREATE INDEX idx_orders_customer_date ON orders(c_id, created);
CREATE INDEX idx_payments_date_amount ON payments(paid, amount);
# use explain to diagnose slow queries
explain select * from orders where c_id = 1 order by created;
select * from  books;
select title,price from books;
# use limit for large result
select * from order_items limit 100;
# stored procedure for place order
DELIMITER $$
CREATE PROCEDURE place_order(
    IN p_customer_id INT,
    IN p_book_id INT,
    IN p_quantity INT
)
BEGIN
    DECLARE v_price DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_stock INT;
#1. Get book price
SELECT price INTO v_price FROM books WHERE book_id = p_book_id;
#2. total
set v_total = v_price * p_quantity;
# 3.check stock
select stock into v_stock from inventory where book_id = p_book_id;
if v_stock < p_quantity then signal sqlstate '45000' set message_text = 'not enough stock avaliable';
end if;
#4. create order
insert into orders(customer_id,total_amount,status) values(p_customer_id,v_total,'processing');
# 5. insert order item
insert into order_items(order_id,book_id,quantity,unit_price) values
(@order_id,p_book_id,p_quantity, v_price);
# 6. reduce stock
update inventory
set stock = stock - p_quantity where book_id = p_book_id;
END $$
DELIMITER ;
# test the place order procedure
call place_order(1,1,2); # 1-customer, 1 - orders 2- quantity
select * from orders order by or_id desc;
select * from order_items order by order_item_id desc;
select * from inventory where b_id = 1;
# stored for add payment
DELIMITER $$
CREATE PROCEDURE add_payment(
    IN p_order_id INT,
    IN p_amount DECIMAL(10,2),
    IN p_method VARCHAR(50)
)
BEGIN
    INSERT INTO payments(order_id, amount, method)
    VALUES (p_order_id, p_amount, p_method);
    UPDATE orders
    SET status = 'completed'
    WHERE order_id = p_order_id;
    call add_payment(1,299.00,'credit card');
END $$
DELIMITER ;






