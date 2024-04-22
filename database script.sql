
CREATE TABLE Movies (
    MovieID INT PRIMARY KEY,
    Title VARCHAR2(255),
    Director VARCHAR2(255),
    ReleaseDate DATE
);
INSERT ALL
    INTO Movies (MovieID, Title, Director, ReleaseDate) VALUES (1, 'Fight Club', 'David Fincher', TO_DATE('1999-10-15', 'YYYY-MM-DD'))
    INTO Movies (MovieID, Title, Director, ReleaseDate) VALUES (2, 'My Neighbor Totoro', 'Hayao Miyazaki', TO_DATE('1988-04-16', 'YYYY-MM-DD'))
    INTO Movies (MovieID, Title, Director, ReleaseDate) VALUES (3, 'Brokeback Mountain', 'Ang Lee', TO_DATE('2005-12-09', 'YYYY-MM-DD'))
    INTO Movies (MovieID, Title, Director, ReleaseDate) VALUES (4, 'Rocky', 'John G. Avildsen', TO_DATE('1976-11-21', 'YYYY-MM-DD'))
    INTO Movies (MovieID, Title, Director, ReleaseDate) VALUES (5, 'Kill Bill', 'Quentin Tarantino', TO_DATE('2003-10-10', 'YYYY-MM-DD'))
SELECT * FROM dual;



CREATE TABLE inventoryCount(
    countID INT PRIMARY KEY,
    amount INT
);

INSERT INTO inventoryCount (countID, amount) VALUES(1, 15);
INSERT INTO inventoryCount (countID, amount) VALUES(2, 20);
INSERT INTO inventoryCount (countID, amount) VALUES(3, 12);
INSERT INTO inventoryCount (countID, amount) VALUES(4, 18);
INSERT INTO inventoryCount (countID, amount) VALUES(5, 22);


CREATE TABLE movie_count(
    movieID INT,
    countID INT,
    starttime TIMESTAMP,
    endtime TIMESTAMP,
    comments VARCHAR2(1000), -- Assuming you want to store up to 1000 characters of text
    PRIMARY KEY (movieID, countID), -- Assuming a composite key is what you're after
    FOREIGN KEY (movieID) REFERENCES Movies(MovieID),
    FOREIGN KEY (countID) REFERENCES inventoryCount(countID)
);
INSERT INTO movie_count (movieID, countID, starttime, endtime, comments) VALUES
(1, 1, TIMESTAMP '2024-03-20 00:00:00', TIMESTAMP '2024-03-27 00:00:00', 'Routine check');
INSERT INTO movie_count (movieID, countID, starttime, endtime, comments) VALUES
(2, 2, TIMESTAMP '2024-03-21 00:00:00', TIMESTAMP '2024-03-28 00:00:00', 'Post-rental update');
INSERT INTO movie_count (movieID, countID, starttime, endtime, comments) VALUES
(3, 3, TIMESTAMP '2024-03-22 00:00:00', TIMESTAMP '2024-03-29 00:00:00', 'Pre-rental check');
INSERT INTO movie_count (movieID, countID, starttime, endtime, comments) VALUES
(4, 4, TIMESTAMP '2024-03-23 00:00:00', TIMESTAMP '2024-03-30 00:00:00', 'Seasonal check');
INSERT INTO movie_count (movieID, countID, starttime, endtime, comments) VALUES
(5, 5, TIMESTAMP '2024-03-24 00:00:00', TIMESTAMP '2024-03-31 00:00:00', 'Special event preparation');


-- create view 
CREATE VIEW movie_inventory_view AS
SELECT m.MovieID, m.Title, m.ReleaseDate,ic.Amount
FROM Movies m
left JOIN movie_count mc ON m.MovieID = mc.MovieID
left JOIN inventoryCount ic ON mc.CountID = ic.CountID;

CREATE SEQUENCE seq_movie_id
START WITH 100
INCREMENT BY 1;

-- trigger update 
ALTER TABLE movies DROP COLUMN director;

CREATE VIEW movie_inventory_view AS
SELECT m.MovieID, m.Title, m.ReleaseDate,ic.Amount
FROM Movies m
left JOIN movie_count mc ON m.MovieID = mc.MovieID
left JOIN inventoryCount ic ON mc.CountID = ic.CountID;

create or replace TRIGGER trg_movie_inventory_update
INSTEAD OF INSERT OR UPDATE ON movie_inventory_view
FOR EACH ROW
DECLARE
    v_movie_exists NUMBER;

    v_count_id NUMBER;
BEGIN
    -- ????????
    SELECT COUNT(*) INTO v_movie_exists FROM Movies WHERE MovieID = :NEW.MovieID;
    
    IF v_movie_exists = 0 THEN
        -- ???????????????
        INSERT INTO Movies (MovieID, Title, ReleaseDate)
        VALUES (:NEW.MovieID, :NEW.Title,:NEW.ReleaseDate);
        
        -- ????????????ID
        SELECT seq_inventory_count.NEXTVAL INTO v_count_id FROM DUAL;
        
        -- ???????
        INSERT INTO InventoryCount (CountID, Amount)
        VALUES (v_count_id, :NEW.Amount);
        
        -- ??movie_count?????starttime??????endtime?NULL
       INSERT INTO movie_count (MovieID, CountID, starttime, endtime, comments)
       VALUES (:NEW.MovieID, v_count_id, SYSDATE, NULL,'new movie insert');

    ELSE
        -- ?????????Movies?????
        UPDATE Movies
        SET Title = :NEW.Title, ReleaseDate = :NEW.ReleaseDate
        WHERE MovieID = :NEW.MovieID;
        
        -- ???????CountID
        BEGIN
            SELECT CountID INTO v_count_id FROM movie_count 
            WHERE MovieID = :NEW.MovieID; 
            --ORDER BY starttime DESC FETCH FIRST 1 ROW ONLY;
            
            -- ??InventoryCount??amount
            UPDATE InventoryCount SET Amount = :NEW.Amount WHERE CountID = v_count_id;
--        EXCEPTION
--            WHEN NO_DATA_FOUND THEN
--                -- ??????CountID????????
--                SELECT seq_inventory_count.NEXTVAL INTO v_count_id FROM DUAL;
--                
--                -- ????InventoryCount??
--                INSERT INTO InventoryCount (CountID, Amount)
--                VALUES (v_count_id, :NEW.Amount);
        --END;

        UPDATE movie_count
        SET endtime = SYSDATE,
            comments='updated table'
        WHERE MovieID = :NEW.MovieID AND CountID = v_count_id;
       END;
        
--        -- ????movie_count??
--        INSERT INTO movie_count (MovieID, CountID, starttime, endtime, comments)
--        VALUES (:NEW.MovieID, v_count_id, SYSDATE, NULL, 'new record');
    END IF;
END;

create or replace TRIGGER trg_movie_inventory_delete
INSTEAD OF DELETE ON movie_inventory_view
FOR EACH ROW
BEGIN
    -- ?? movie_count ??????????????????
    UPDATE movie_count
    SET endtime =SYSTIMESTAMP,
        comments='this record is deleted'
    WHERE MovieID = :OLD.MovieID ;

    UPDATE Movies
    SET IsDeleted = 1
    WHERE MovieID = :OLD.MovieID;
END;
--delete
ALTER TABLE Movies
ADD IsDeleted NUMBER(1) DEFAULT 0 NOT NULL;

create or replace TRIGGER trg_movie_inventory_delete
INSTEAD OF DELETE ON movie_inventory_view
FOR EACH ROW
BEGIN
    -- ?? movie_count ??????????????????
    UPDATE movie_count
    SET endtime = SYSTIMESTAMP
    WHERE MovieID = :OLD.MovieID AND endtime IS NULL;

    -- ?? Movies ??????????????????????
    UPDATE Movies
    SET IsDeleted = 1
    WHERE MovieID = :OLD.MovieID;
END;

-- test
INSERT INTO movie_inventory_view (MovieID, Title, Director, ReleaseDate, Amount, Comments)
VALUES (6, 'The Legend of 1900', 'Giuseppe Tornatore', TO_DATE('1998-10-28', 'YYYY-MM-DD'), 7, 'New movie insertion');

SELECT constraint_name, table_name, column_name
FROM user_cons_columns
WHERE constraint_name = 'SYS_C007869';

update movie_inventory_view
set director='An Li'
where movieID=3;

delete movie_inventory_view
where movieID=3;


————————group2——————————
-- ??Customers?
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Name VARCHAR2(255),
    Email VARCHAR2(255)
);

-- ??Points?
CREATE TABLE Points (
   PointID INT PRIMARY KEY,
   Points INT
);

-- ??customer_points???
-- ??starttime?endtime?DATE??
CREATE TABLE customer_points (
  PointID INT,
  CustomerID INT,
  StartTime DATE,
  EndTime DATE,
  FOREIGN KEY (PointID) REFERENCES Points(PointID),
  FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- ?????????????customerid, name, email?point
CREATE VIEW CustomerPointsView AS
SELECT c.CustomerID, c.Name, c.Email, p.Points
FROM Customers c
JOIN customer_points cp ON c.CustomerID = cp.CustomerID
JOIN Points p ON cp.PointID = p.PointID;

--insert
-- ?Customers?????
INSERT INTO Customers (CustomerID, Name, Email) VALUES (1, 'Jack', 'jack@example.com');
INSERT INTO Customers (CustomerID, Name, Email) VALUES (2, 'Rose', 'rose@example.com');
INSERT INTO Customers (CustomerID, Name, Email) VALUES (3, 'Yuan', 'yuan@example.com');
INSERT INTO Customers (CustomerID, Name, Email) VALUES (4, 'Ruchen', 'ruchen@example.com');
INSERT INTO Customers (CustomerID, Name, Email) VALUES (5, 'Luisa', 'luisa@example.com');

-- ?Points?????
INSERT INTO Points (PointID, Points) VALUES (101, 100);
INSERT INTO Points (PointID, Points) VALUES (102, 150);
INSERT INTO Points (PointID, Points) VALUES (103, 200);
INSERT INTO Points (PointID, Points) VALUES (104, 250);
INSERT INTO Points (PointID, Points) VALUES (105, 300);

-- ?customer_points????????Customers?Points
-- ???????2023?????2024???
INSERT INTO customer_points (PointID, CustomerID, StartTime, EndTime) VALUES (101, 1, TO_DATE('2023-01-01', 'YYYY-MM-DD'), TO_DATE('2024-01-01', 'YYYY-MM-DD'));
INSERT INTO customer_points (PointID, CustomerID, StartTime, EndTime) VALUES (102, 2, TO_DATE('2023-02-01', 'YYYY-MM-DD'), TO_DATE('2024-02-01', 'YYYY-MM-DD'));
INSERT INTO customer_points (PointID, CustomerID, StartTime, EndTime) VALUES (103, 3, TO_DATE('2023-03-01', 'YYYY-MM-DD'), TO_DATE('2024-03-01', 'YYYY-MM-DD'));
INSERT INTO customer_points (PointID, CustomerID, StartTime, EndTime) VALUES (104, 4, TO_DATE('2023-04-01', 'YYYY-MM-DD'), TO_DATE('2024-04-01', 'YYYY-MM-DD'));
INSERT INTO customer_points (PointID, CustomerID, StartTime, EndTime) VALUES (105, 5, TO_DATE('2023-05-01', 'YYYY-MM-DD'), TO_DATE('2024-05-01', 'YYYY-MM-DD'));


--
CREATE SEQUENCE seq_points_id
START WITH 1
INCREMENT BY 1;

-- trigger
CREATE OR REPLACE TRIGGER trg_customer_points_update
INSTEAD OF INSERT OR UPDATE ON customerpointsview
FOR EACH ROW
DECLARE
    v_customer_exists NUMBER;
    v_point_id NUMBER;
BEGIN
    -- ????????
    SELECT COUNT(*) INTO v_customer_exists FROM Customers WHERE CustomerID = :NEW.CustomerID;

    IF v_customer_exists = 0 THEN
        -- ??????????Customers?Points????
        INSERT INTO Customers (CustomerID, Name, Email)
        VALUES (:NEW.CustomerID, :NEW.Name, :NEW.Email);

        -- ????????PointID
        SELECT seq_points_id.NEXTVAL INTO v_point_id FROM DUAL;

        INSERT INTO Points (PointID, Points)
        VALUES (v_point_id, :NEW.Points);

        -- ????customer_points?????starttime??????endtime?NULL
        INSERT INTO customer_points (CustomerID, PointID, StartTime, EndTime)
        VALUES (:NEW.CustomerID, v_point_id, SYSTIMESTAMP, NULL);
    ELSE
        -- ?????????Customers?Points?????
        UPDATE Customers
        SET Name = :NEW.Name, Email = :NEW.Email
        WHERE CustomerID = :NEW.CustomerID;

        -- ???????PointID
        SELECT PointID INTO v_point_id FROM customer_points 
        WHERE CustomerID = :NEW.CustomerID AND EndTime IS NULL
        ORDER BY StartTime DESC FETCH FIRST 1 ROW ONLY;

        UPDATE Points
        SET Points = :NEW.Points
        WHERE PointID = v_point_id;

        -- ???????endtime?SYSTIMESTAMP
        UPDATE customer_points
        SET EndTime = SYSTIMESTAMP
        WHERE CustomerID = :NEW.CustomerID AND PointID = v_point_id AND EndTime IS NULL;

        -- ????customer_points????????????
        INSERT INTO customer_points (CustomerID, PointID, StartTime, EndTime)
        VALUES (:NEW.CustomerID, v_point_id, SYSTIMESTAMP, NULL);
    END IF;
END;
/

--delete trigger
alter table customers
ADD IsDeleted NUMBER(1) DEFAULT 0 NOT NULL;

CREATE OR REPLACE TRIGGER trg_customer_delete
INSTEAD OF DELETE ON customerpointsview
FOR EACH ROW
BEGIN
    -- ?? customer_points ??????????????????
    UPDATE customer_points
    SET endtime = SYSTIMESTAMP
    WHERE CustomerID = :OLD.CustomerID;

    -- ?? Customers ??????????????????????
    UPDATE Customers
    SET IsDeleted = 1
    WHERE CustomerID = :OLD.CustomerID;
END;


update customerpointsview
set points=44
where CustomerID=2


——————————————group3————
CREATE TABLE Rentals (
    RentalID INT PRIMARY KEY,
    CustomerID INT,
    MovieID INT,
    ReturnDate DATE,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (MovieID) REFERENCES Movies(MovieID)
);

-- It seems like you wanted to create a separate table for rental dates, 
-- but it's not clear why, since RentalDate and ReturnDate are already part of the Rentals table.
-- If you need to track more detailed information about rental dates, clarify the purpose.
-- For the sake of example, I'm going to adjust it as a generic example table.

CREATE TABLE RentalDates (
    RentalDateID INT PRIMARY KEY,
    RentalDate DATE
);

CREATE TABLE Rental_Record (
    RentalID INT,
    RentalDateID INT,
    StartTime DATE, -- Stores the start time of the rental
    EndTime DATE,   -- Stores the end time of the rental
    FOREIGN KEY (RentalID) REFERENCES Rentals(RentalID),
    FOREIGN KEY (RentalDateID) REFERENCES RentalDates(RentalDateID)
);

INSERT INTO Rentals (RentalID, CustomerID, MovieID, ReturnDate) VALUES (1, 1, 1, DATE '2024-03-25');
INSERT INTO Rentals (RentalID, CustomerID, MovieID, ReturnDate) VALUES (2, 1, 2, DATE '2024-03-26');
INSERT INTO Rentals (RentalID, CustomerID, MovieID, ReturnDate) VALUES (3, 2, 3, DATE '2024-03-27');
INSERT INTO Rentals (RentalID, CustomerID, MovieID, ReturnDate) VALUES (4, 3, 4, DATE '2024-03-28');
INSERT INTO Rentals (RentalID, CustomerID, MovieID, ReturnDate) VALUES (5, 5, 5, DATE '2024-03-29');

INSERT INTO RentalDates (RentalDateID, RentalDate) VALUES (1, DATE '2024-03-20');
INSERT INTO RentalDates (RentalDateID, RentalDate) VALUES (2, DATE '2024-03-21');
INSERT INTO RentalDates (RentalDateID, RentalDate) VALUES (3, DATE '2024-03-22');
INSERT INTO RentalDates (RentalDateID, RentalDate) VALUES (4, DATE '2024-03-23');
INSERT INTO RentalDates (RentalDateID, RentalDate) VALUES (5, DATE '2024-03-24');

INSERT INTO Rental_Record (RentalID, RentalDateID, StartTime, EndTime) VALUES (1, 1, DATE '2024-03-20', DATE '2024-03-20');
INSERT INTO Rental_Record (RentalID, RentalDateID, StartTime, EndTime) VALUES (2, 2, DATE '2024-03-21', DATE '2024-03-21');
INSERT INTO Rental_Record (RentalID, RentalDateID, StartTime, EndTime) VALUES (3, 3, DATE '2024-03-22', DATE '2024-03-22');
INSERT INTO Rental_Record (RentalID, RentalDateID, StartTime, EndTime) VALUES (4, 4, DATE '2024-03-23', DATE '2024-03-23');
INSERT INTO Rental_Record (RentalID, RentalDateID, StartTime, EndTime) VALUES (5, 5, DATE '2024-03-24', DATE '2024-03-24');

--view
CREATE OR REPLACE VIEW RentalsView AS
SELECT r.RentalID, rd.RentalDateID,r.CustomerID, r.MovieID,rd.RentalDate, r.returndate
FROM Rentals r
JOIN Rental_Record rr ON rr.RentalID=r.rentalid
JOIN RentalDates rd ON rr.rentaldateid = rd.RentalDateID; 

--
ALTER TABLE rental_record ADD comments VARCHAR2(255);


--sequence
CREATE SEQUENCE seq_rental_date_id
START WITH 1
INCREMENT BY 1
NOCACHE;


--trigger
CREATE OR REPLACE TRIGGER trg_rentals_update
INSTEAD OF INSERT OR UPDATE ON RentalsView
FOR EACH ROW
DECLARE
    v_rental_exists NUMBER;
    v_rental_date_id NUMBER;
BEGIN
    -- ??????????
    SELECT COUNT(*) INTO v_rental_exists FROM Rentals WHERE RentalID = :NEW.RentalID;

    IF v_rental_exists = 0 THEN
    
        -- ????????????Rentals?RentalDates????
        INSERT INTO Rentals (RentalID, CustomerID, MovieID, ReturnDate)
        VALUES (:NEW.RentalID, :NEW.CustomerID, :NEW.MovieID, NULL);


        SELECT seq_rental_date_id.NEXTVAL INTO v_rental_date_id FROM DUAL;
        
        INSERT INTO RentalDates (RentalDateID, RentalDate)
        VALUES (v_rental_date_id, SYSDATE);

        -- ????Rental_Record???????????????NULL
       INSERT INTO Rental_Record (RentalID, RentalDateID, StartTime, EndTime,comments)
        VALUES (:NEW.RentalID, v_rental_date_id, SYSDATE, NULL,'Initial rental');
    ELSE
        -- ???????????Rentals?RentalDates?????
        UPDATE Rentals
        SET CustomerID = :NEW.CustomerID, MovieID = :NEW.MovieID
        WHERE RentalID = :NEW.RentalID;

     --no need update rentaldates 

        -- ??Rental_Record???EndTime????Comment
        UPDATE Rental_Record
        SET EndTime = SYSDATE, Comments = 'Updated renewal times'
        WHERE RentalID = :NEW.RentalID AND RentalDateID = v_rental_date_id;
    END IF;
END;



--trigger update test 
update rentalsview
set  movieid=3
where rentalid=9;

INSERT INTO RentalsView (RentalID, rentaldateID,CustomerID, MovieID, RentalDate,ReturnDate)
VALUES (9, 8,4, 1, SYSDATE,null);













