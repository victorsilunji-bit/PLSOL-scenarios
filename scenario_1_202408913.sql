
-- SCENARIO 4: CAMPUS CLINIC MEDICINE DISPENSING

-- 1. CREATE TABLES AND INSERT MEDICINES

CREATE TABLE medicines (
    medicine_id INT PRIMARY KEY,
    medicine_name VARCHAR(100),
    stock_quantity INT
);

CREATE TABLE dispensing_records (
    dispensing_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    medicine_id INT REFERENCES medicines(medicine_id),
    quantity INT,
    status VARCHAR(20)
);


-- Add at least three medicines

INSERT INTO medicines (medicine_id, medicine_name, stock_quantity)
VALUES
(1, 'Paracetamol', 50),
(2, 'Amoxicillin', 10),
(3, 'Ibuprofen', 0);



-- 2. IF ELSIF ELSE
-- Report medicine stock level

DO $$
DECLARE
    v_stock INT;
BEGIN

    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = 1;

    IF v_stock = 0 THEN

        RAISE NOTICE 'Medicine is OUT OF STOCK';

    ELSIF v_stock <= 10 THEN

        RAISE NOTICE 'Medicine is LOW ON STOCK';

    ELSE

        RAISE NOTICE 'Medicine is SUFFICIENTLY STOCKED';

    END IF;

END $$;


-- 3. WHILE LOOP
-- Show three stock review days

DO $$
DECLARE
    v_day INT := 1;
BEGIN

    WHILE v_day <= 3 LOOP

        RAISE NOTICE 'Stock Review Day: %', v_day;

        v_day := v_day + 1;

    END LOOP;

END $$;


-- NUMERIC FOR LOOP
-- Number three shelf inspections

DO $$
BEGIN

    FOR v_shelf IN 1..3 LOOP

        RAISE NOTICE 'Shelf Inspection Number: %', v_shelf;

    END LOOP;

END $$;



-- 4. CREATE DISPENSE_MEDICINE PROCEDURE

CREATE OR REPLACE PROCEDURE dispense_medicine(
    p_student_number VARCHAR,
    p_medicine_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_stock INT;
BEGIN

    -- Check for invalid quantity
    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
        'Invalid quantity. Quantity must be greater than zero';

    END IF;


    -- Get current stock
    SELECT stock_quantity
    INTO v_stock
    FROM medicines
    WHERE medicine_id = p_medicine_id;


    -- Check if medicine exists
    IF v_stock IS NULL THEN

        RAISE EXCEPTION
        'Medicine does not exist';


    -- Check if there is enough stock
    ELSIF v_stock < p_quantity THEN

        RAISE EXCEPTION
        'Insufficient stock. Available: %, Requested: %',
        v_stock,
        p_quantity;


    ELSE

        -- Reduce medicine stock
        UPDATE medicines
        SET stock_quantity = stock_quantity - p_quantity
        WHERE medicine_id = p_medicine_id;


        -- Record dispensing
        INSERT INTO dispensing_records
        (
            student_number,
            medicine_id,
            quantity,
            status
        )
        VALUES
        (
            p_student_number,
            p_medicine_id,
            p_quantity,
            'DISPENSED'
        );


        RAISE NOTICE 'Medicine dispensed successfully';

    END IF;

END;
$$;



-- 5. CALL PROCEDURE
-- Two valid quantities and one exceeding stock


-- Valid dispensing 1
CALL dispense_medicine(
    '202300001',
    1,
    10
);


-- Valid dispensing 2
CALL dispense_medicine(
    '202300002',
    2,
    3
);


-- Invalid: exceeds available stock
CALL dispense_medicine(
    '202300003',
    2,
    20
);


-- Query medicines
SELECT *
FROM medicines
ORDER BY medicine_id;


-- Query dispensing records
SELECT *
FROM dispensing_records
ORDER BY dispensing_id;



-- 6. CREATE REVERSE_DISPENSING PROCEDURE

CREATE OR REPLACE PROCEDURE reverse_dispensing(
    p_dispensing_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_medicine_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Find dispensing record
    SELECT medicine_id,
           quantity,
           status
    INTO v_medicine_id,
         v_quantity,
         v_status
    FROM dispensing_records
    WHERE dispensing_id = p_dispensing_id;


    -- Check whether record exists
    IF v_medicine_id IS NULL THEN

        RAISE EXCEPTION
        'Dispensing record does not exist';


    -- Reverse only if it has not already been reversed
    ELSIF v_status = 'DISPENSED' THEN

        -- Restore medicine stock
        UPDATE medicines
        SET stock_quantity = stock_quantity + v_quantity
        WHERE medicine_id = v_medicine_id;


        -- Mark record as reversed
        UPDATE dispensing_records
        SET status = 'REVERSED'
        WHERE dispensing_id = p_dispensing_id;


        RAISE NOTICE
        'Dispensing record reversed successfully';


    ELSE

        RAISE NOTICE
        'Record has already been reversed. Stock was not restored again';

    END IF;

END;
$$;



-- First reversal
CALL reverse_dispensing(1);


-- Second reversal of the same record
CALL reverse_dispensing(1);


-- 7. EXPLICIT CURSOR
-- Display medicines below low-stock threshold


DO $$
DECLARE

    medicine_cursor CURSOR FOR
        SELECT medicine_id,
               medicine_name,
               stock_quantity
        FROM medicines
        WHERE stock_quantity <= 10;

    v_medicine_id INT;
    v_medicine_name VARCHAR(100);
    v_stock INT;

BEGIN

    OPEN medicine_cursor;

    LOOP

        FETCH medicine_cursor
        INTO v_medicine_id,
             v_medicine_name,
             v_stock;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Medicine ID: %, Medicine: %, Stock Remaining: %',
        v_medicine_id,
        v_medicine_name,
        v_stock;

    END LOOP;

    CLOSE medicine_cursor;

END $$;



-- 8. NEGATIVE DISPENSING QUANTITY
-- Handle invalid input using EXCEPTION

DO $$
BEGIN

    BEGIN

        CALL dispense_medicine(
            '202300004',
            1,
            -5
        );

    EXCEPTION
        WHEN OTHERS THEN

            RAISE NOTICE
            'Invalid dispensing request handled: %',
            SQLERRM;

    END;

END $$;

-- 9. FINAL QUERIES


-- Final medicine stock
SELECT
    medicine_id,
    medicine_name,
    stock_quantity
FROM medicines
ORDER BY medicine_id;


-- Final dispensing records
SELECT
    dispensing_id,
    student_number,
    medicine_id,
    quantity,
    status
FROM dispensing_records
ORDER BY dispensing_id;
