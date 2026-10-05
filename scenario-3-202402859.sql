-- SCENARIO 3: STUDENT HOSTEL ROOM ALLOCATION

CREATE TABLE hostel_rooms (
    room_id SERIAL PRIMARY KEY,
    room_name VARCHAR(50) NOT NULL,
    available_bed_spaces INT NOT NULL
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20) NOT NULL,
    room_id INT REFERENCES hostel_rooms(room_id),
    status VARCHAR(20) NOT NULL
);

INSERT INTO hostel_rooms (room_name, available_bed_spaces)
VALUES
('Room A', 4),
('Room B', 1),
('Room C', 0);


DO $$
DECLARE
    spaces INT;
BEGIN
    SELECT available_bed_spaces INTO spaces
    FROM hostel_rooms
    WHERE room_id = 1;

    IF spaces = 0 THEN
        RAISE NOTICE 'The room is full.';
    ELSIF spaces = 1 THEN
        RAISE NOTICE 'The room has one bed space left.';
    ELSE
        RAISE NOTICE 'The room has several bed spaces available.';
    END IF;
END $$;


DO $$
DECLARE
    counter INT := 1;
BEGIN
    WHILE counter <= 3 LOOP
        RAISE NOTICE 'Hostel Inspection Day: %', counter;
        counter := counter + 1;
    END LOOP;

    FOR room_check IN 1..3 LOOP
        RAISE NOTICE 'Room Check Number: %', room_check;
    END LOOP;
END $$;


CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    available INT;
BEGIN
    IF p_student_number IS NULL
       OR TRIM(p_student_number) = '' THEN
        RAISE EXCEPTION
        'Invalid student number: student number cannot be blank.';
    END IF;

    SELECT available_bed_spaces INTO available
    FROM hostel_rooms
    WHERE room_id = p_room_id;

    IF available >= 1 THEN
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces - 1
        WHERE room_id = p_room_id;

        INSERT INTO allocations
        (student_number, room_id, status)
        VALUES
        (p_student_number, p_room_id, 'Allocated');

        RAISE NOTICE 'Room allocated successfully.';
    ELSE
        RAISE NOTICE 'No bed space available.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
END $$;


CALL allocate_room('202403005', 1);
CALL allocate_room('202403006', 2);
CALL allocate_room('202403007', 3);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    allocated_room INT;
    current_status VARCHAR;
BEGIN
    SELECT room_id, status
    INTO allocated_room, current_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;

    IF current_status = 'Allocated' THEN
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces + 1
        WHERE room_id = allocated_room;

        UPDATE allocations
        SET status = 'Completed'
        WHERE allocation_id = p_allocation_id;

        RAISE NOTICE 'Student checked out successfully.';
    ELSE
        RAISE NOTICE 'Allocation has already been completed.';
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error: %', SQLERRM;
END $$;


CALL check_out(1);
CALL check_out(1);

SELECT * FROM hostel_rooms;
SELECT * FROM allocations;


DO $$
DECLARE
    room_cursor CURSOR FOR
        SELECT room_name, available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

    room_record RECORD;
BEGIN
    OPEN room_cursor;

    LOOP
        FETCH room_cursor INTO room_record;
        EXIT WHEN NOT FOUND;

        RAISE NOTICE
            'Room: %, Bed Spaces Remaining: %',
            room_record.room_name,
            room_record.available_bed_spaces;
    END LOOP;

    CLOSE room_cursor;
END $$;


CALL allocate_room('', 1);


SELECT * FROM hostel_rooms;
SELECT * FROM allocations;