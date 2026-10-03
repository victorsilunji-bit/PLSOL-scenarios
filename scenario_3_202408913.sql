-- SCENARIO 3: STUDENT HOSTEL ROOM ALLOCATION

CREATE TABLE hostel_rooms (
    room_id INT PRIMARY KEY,
    room_name VARCHAR(50),
    available_bed_spaces INT
);

CREATE TABLE allocations (
    allocation_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    room_id INT REFERENCES hostel_rooms(room_id),
    status VARCHAR(20)
);


-- Add three rooms

INSERT INTO hostel_rooms
(room_id, room_name, available_bed_spaces)
VALUES
(1, 'Room A', 4),
(2, 'Room B', 1),
(3, 'Room C', 0);




DO $$
DECLARE
    v_spaces INT;
BEGIN

    SELECT available_bed_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = 1;


    IF v_spaces = 0 THEN

        RAISE NOTICE 'Room is FULL';

    ELSIF v_spaces = 1 THEN

        RAISE NOTICE 'Room has ONE SPACE LEFT';

    ELSE

        RAISE NOTICE 'Room has SEVERAL SPACES';

    END IF;

END $$;


-- 3. WHILE LOOP
-- Show three hostel inspection days

DO $$
DECLARE
    v_day INT := 1;
BEGIN

    WHILE v_day <= 3 LOOP

        RAISE NOTICE 'Hostel Inspection Day: %', v_day;

        v_day := v_day + 1;

    END LOOP;

END $$;



-- NUMERIC FOR LOOP
-- Number three room checks

DO $$
BEGIN

    FOR v_room_check IN 1..3 LOOP

        RAISE NOTICE 'Room Check Number: %', v_room_check;

    END LOOP;

END $$;



-- 4. CREATE ALLOCATE_ROOM PROCEDURE

CREATE OR REPLACE PROCEDURE allocate_room(
    p_student_number VARCHAR,
    p_room_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_spaces INT;
BEGIN

    -- Check for blank student number
    IF TRIM(p_student_number) = '' THEN

        RAISE EXCEPTION
        'Invalid student number. Student number cannot be blank';

    END IF;


    -- Get available spaces
    SELECT available_bed_spaces
    INTO v_spaces
    FROM hostel_rooms
    WHERE room_id = p_room_id;


    -- Check if room exists
    IF v_spaces IS NULL THEN

        RAISE EXCEPTION
        'Room does not exist';


    -- Check if room is full
    ELSIF v_spaces <= 0 THEN

        RAISE EXCEPTION
        'Room is full. No bed space is available';


    ELSE

        -- Reduce available bed spaces
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces - 1
        WHERE room_id = p_room_id;


        -- Record student allocation
        INSERT INTO allocations
        (
            student_number,
            room_id,
            status
        )
        VALUES
        (
            p_student_number,
            p_room_id,
            'ALLOCATED'
        );


        RAISE NOTICE
        'Student allocated successfully';

    END IF;

END;
$$;



-- Two valid allocations and one full-room allocation


-- Valid allocation 1
CALL allocate_room(
    '202300001',
    1
);


-- Valid allocation 2
CALL allocate_room(
    '202300002',
    2
);


-- Invalid allocation because Room C is full
CALL allocate_room(
    '202300003',
    3
);


-- Query hostel rooms
SELECT *
FROM hostel_rooms
ORDER BY room_id;


-- Query allocations
SELECT *
FROM allocations
ORDER BY allocation_id;



-- 6. CREATE CHECK_OUT PROCEDURE

CREATE OR REPLACE PROCEDURE check_out(
    p_allocation_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_room_id INT;
    v_status VARCHAR(20);
BEGIN

    -- Find allocation
    SELECT room_id,
           status
    INTO v_room_id,
         v_status
    FROM allocations
    WHERE allocation_id = p_allocation_id;


    -- Check if allocation exists
    IF v_room_id IS NULL THEN

        RAISE EXCEPTION
        'Allocation does not exist';


    -- Only check out an active allocation
    ELSIF v_status = 'ALLOCATED' THEN

        -- Release the bed space
        UPDATE hostel_rooms
        SET available_bed_spaces =
            available_bed_spaces + 1
        WHERE room_id = v_room_id;


        -- Mark allocation as completed
        UPDATE allocations
        SET status = 'COMPLETED'
        WHERE allocation_id = p_allocation_id;


        RAISE NOTICE
        'Student checked out successfully';


    ELSE

        RAISE NOTICE
        'Student has already checked out. Bed space was not released again';

    END IF;

END;
$$;


-- CALL CHECK_OUT TWICE FOR THE SAME ALLOCATION


-- First checkout
CALL check_out(1);


-- Second checkout
CALL check_out(1);


-- 7. EXPLICIT CURSOR
-- Display full or nearly full rooms

DO $$
DECLARE

    room_cursor CURSOR FOR
        SELECT room_id,
               room_name,
               available_bed_spaces
        FROM hostel_rooms
        WHERE available_bed_spaces <= 1;

    v_room_id INT;
    v_room_name VARCHAR(50);
    v_spaces INT;

BEGIN

    OPEN room_cursor;

    LOOP

        FETCH room_cursor
        INTO v_room_id,
             v_room_name,
             v_spaces;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Room ID: %, Room: %, Available Spaces: %',
        v_room_id,
        v_room_name,
        v_spaces;

    END LOOP;

    CLOSE room_cursor;

END $$;

-- 8. BLANK STUDENT NUMBER
-- Handle invalid input using EXCEPTION

DO $$
BEGIN

    BEGIN

        CALL allocate_room(
            '   ',
            1
        );

    EXCEPTION
        WHEN OTHERS THEN

            RAISE NOTICE
            'Invalid allocation handled: %',
            SQLERRM;

    END;

END $$;



-- 9. FINAL QUERIES



-- Final hostel room spaces

SELECT
    room_id,
    room_name,
    available_bed_spaces
FROM hostel_rooms
ORDER BY room_id;


-- Final allocation statuses

SELECT
    allocation_id,
    student_number,
    room_id,
    status
FROM allocations
ORDER BY allocation_id;
