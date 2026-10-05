-- SCENARIO 1: UNIVERSITY LIBRARY BOOK LOANS

CREATE TABLE books (
    book_id SERIAL PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    available_copies INT NOT NULL
);

CREATE TABLE book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    book_id INT REFERENCES books(book_id),
    quantity INT NOT NULL,
    loan_status VARCHAR(20) NOT NULL
);

INSERT INTO books (title, available_copies)
VALUES
('Database Systems', 10),
('Computer Networks', 3),
('Programming Fundamentals', 0);


DO $$
DECLARE
    copies INT;
BEGIN
    SELECT available_copies INTO copies
    FROM books
    WHERE book_id = 1;

    IF copies = 0 THEN
        RAISE NOTICE 'The book is unavailable.';
    ELSIF copies <= 3 THEN
        RAISE NOTICE 'The book has low copies.';
    ELSE
        RAISE NOTICE 'The book is sufficiently stocked.';
    END IF;
END $$;


DO $$
DECLARE
    counter INT := 1;
BEGIN
    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Overdue Reminder Number: %', counter;
        counter := counter + 1;
    END LOOP;

    FOR shelf IN 1..3 LOOP
        RAISE NOTICE 'Library Shelf Number: %', shelf;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE borrow_book(
    p_student_number VARCHAR,
    p_book_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    copies INT;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE EXCEPTION
        'Invalid quantity: quantity must be greater than zero.';
    END IF;

    SELECT available_copies INTO copies
    FROM books
    WHERE book_id = p_book_id;

    IF copies >= p_quantity THEN
        UPDATE books
        SET available_copies = available_copies - p_quantity
        WHERE book_id = p_book_id;

        INSERT INTO book_loans
        (student_number, book_id, quantity, loan_status)
        VALUES
        (p_student_number, p_book_id, p_quantity, 'Borrowed');

        RAISE NOTICE 'Loan recorded successfully.';
    ELSE
        RAISE NOTICE 'Not enough copies available.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
END;
$$;


CALL borrow_book('202403001', 1, 2);
CALL borrow_book('202403002', 2, 1);
CALL borrow_book('202403003', 2, 10);

SELECT * FROM books;
SELECT * FROM book_loans;


CREATE OR REPLACE PROCEDURE return_book(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    loan_quantity INT;
    loan_book INT;
    current_status VARCHAR;
BEGIN
    SELECT quantity, book_id, loan_status
    INTO loan_quantity, loan_book, current_status
    FROM book_loans
    WHERE loan_id = p_loan_id;

    IF current_status = 'Borrowed' THEN
        UPDATE books
        SET available_copies = available_copies + loan_quantity
        WHERE book_id = loan_book;

        UPDATE book_loans
        SET loan_status = 'Returned'
        WHERE loan_id = p_loan_id;

        RAISE NOTICE 'Book returned successfully.';
    ELSE
        RAISE NOTICE 'Loan has already been returned.';
    END IF;
END;
$$;


CALL return_book(1);
CALL return_book(1);

SELECT * FROM books;
SELECT * FROM book_loans;


DO $$
DECLARE
    book_cursor CURSOR FOR
        SELECT title, available_copies
        FROM books
        WHERE available_copies <= 3;

    book_record RECORD;
BEGIN
    OPEN book_cursor;

    LOOP
        FETCH book_cursor INTO book_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Book: %, Copies Remaining: %',
            book_record.title,
            book_record.available_copies;
    END LOOP;

    CLOSE book_cursor;
END $$;


CALL borrow_book('202403004', 1, 0);


SELECT * FROM books;
SELECT * FROM book_loans;