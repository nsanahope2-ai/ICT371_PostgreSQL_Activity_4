-- SCENARIO 2: COMPUTER LABORATORY RESERVATIONS

CREATE TABLE lab_sessions (
    session_id SERIAL PRIMARY KEY,
    session_name VARCHAR(100) NOT NULL,
    available_workstations INT NOT NULL
);

CREATE TABLE reservations (
    reservation_id SERIAL PRIMARY KEY,
    lecturer VARCHAR(100) NOT NULL,
    session_id INT REFERENCES lab_sessions(session_id),
    workstations INT NOT NULL,
    reservation_status VARCHAR(20) NOT NULL
);

INSERT INTO lab_sessions (session_name, available_workstations)
VALUES
('Database Practical', 20),
('Networking Practical', 5),
('Programming Practical', 0);


DO $$
DECLARE
    workstations INT;
BEGIN
    SELECT available_workstations INTO workstations
    FROM lab_sessions
    WHERE session_id = 1;

    IF workstations = 0 THEN
        RAISE NOTICE 'The session is full.';
    ELSIF workstations <= 5 THEN
        RAISE NOTICE 'The session is nearly full.';
    ELSE
        RAISE NOTICE 'The session has enough workstations.';
    END IF;
END $$;


DO $$
DECLARE
    counter INT := 1;
BEGIN
    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Session Preparation Reminder: %', counter;
        counter := counter + 1;
    END LOOP;

    FOR workstation IN 1..3 LOOP
        RAISE NOTICE 'Workstation Check Number: %', workstation;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE reserve_workstations(
    p_lecturer VARCHAR,
    p_session_id INT,
    p_workstations INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INT;
BEGIN
    IF p_workstations <= 0 THEN
        RAISE EXCEPTION
        'Invalid number of workstations: must be greater than zero.';
    END IF;

    SELECT available_workstations INTO available
    FROM lab_sessions
    WHERE session_id = p_session_id;

    IF available >= p_workstations THEN
        UPDATE lab_sessions
        SET available_workstations =
            available_workstations - p_workstations
        WHERE session_id = p_session_id;

        INSERT INTO reservations
        (lecturer, session_id, workstations, reservation_status)
        VALUES
        (p_lecturer, p_session_id, p_workstations, 'Reserved');

        RAISE NOTICE 'Reservation recorded successfully.';
    ELSE
        RAISE NOTICE 'Not enough workstations available.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
END $$;


CALL reserve_workstations('Dr. Banda', 1, 5);
CALL reserve_workstations('Dr. Phiri', 2, 2);
CALL reserve_workstations('Dr. Mwansa', 2, 10);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;


CREATE OR REPLACE PROCEDURE cancel_reservation(
    p_reservation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    reserved_workstations INT;
    reserved_session INT;
    current_status VARCHAR;
BEGIN
    SELECT workstations, session_id, reservation_status
    INTO reserved_workstations, reserved_session, current_status
    FROM reservations
    WHERE reservation_id = p_reservation_id;

    IF current_status = 'Reserved' THEN
        UPDATE lab_sessions
        SET available_workstations =
            available_workstations + reserved_workstations
        WHERE session_id = reserved_session;

        UPDATE reservations
        SET reservation_status = 'Cancelled'
        WHERE reservation_id = p_reservation_id;

        RAISE NOTICE 'Reservation cancelled successfully.';
    ELSE
        RAISE NOTICE 'Reservation has already been cancelled.';
    END IF;
END $$;


CALL cancel_reservation(1);
CALL cancel_reservation(1);

SELECT * FROM lab_sessions;
SELECT * FROM reservations;


DO $$
DECLARE
    session_cursor CURSOR FOR
        SELECT session_name, available_workstations
        FROM lab_sessions
        WHERE available_workstations <= 5;

    session_record RECORD;
BEGIN
    OPEN session_cursor;

    LOOP
        FETCH session_cursor INTO session_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Session: %, Workstations Remaining: %',
            session_record.session_name,
            session_record.available_workstations;
    END LOOP;

    CLOSE session_cursor;
END $$;


CALL reserve_workstations('Dr. Tembo', 1, 0);


SELECT * FROM lab_sessions;
SELECT * FROM reservations;