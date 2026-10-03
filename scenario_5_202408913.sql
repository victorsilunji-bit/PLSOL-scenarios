
-- SCENARIO 5: ENGINEERING WORKSHOP TOOL LOANS

CREATE TABLE tools (
    tool_id INT PRIMARY KEY,
    tool_name VARCHAR(100),
    available_quantity INT
);

CREATE TABLE tool_loans (
    loan_id SERIAL PRIMARY KEY,
    student_number VARCHAR(20),
    tool_id INT REFERENCES tools(tool_id),
    quantity INT,
    status VARCHAR(20)
);


-- Add three tool types

INSERT INTO tools
(tool_id, tool_name, available_quantity)
VALUES
(1, 'Hammer', 10),
(2, 'Screwdriver', 5),
(3, 'Drill', 0);


-- 2. IF ELSIF ELSE

DO $$
DECLARE
    v_quantity INT;
BEGIN

    SELECT available_quantity
    INTO v_quantity
    FROM tools
    WHERE tool_id = 1;


    IF v_quantity = 0 THEN

        RAISE NOTICE 'Tool is UNAVAILABLE';

    ELSIF v_quantity <= 5 THEN

        RAISE NOTICE 'Tool is LOW ON STOCK';

    ELSE

        RAISE NOTICE 'Tool is READILY AVAILABLE';

    END IF;

END $$;


-- 3. WHILE LOOP

DO $$
DECLARE
    v_reminder INT := 1;
BEGIN

    WHILE v_reminder <= 3 LOOP

        RAISE NOTICE 'Workshop Safety Reminder Number: %',
                     v_reminder;

        v_reminder := v_reminder + 1;

    END LOOP;

END $$;


-- NUMERIC FOR LOOP
-- Number three tool inspections

DO $$
BEGIN

    FOR v_inspection IN 1..3 LOOP

        RAISE NOTICE 'Tool Inspection Number: %',
                     v_inspection;

    END LOOP;

END $$;



-- 4. CREATE ISSUE_TOOL PROCEDURE

CREATE OR REPLACE PROCEDURE issue_tool(
    p_student_number VARCHAR,
    p_tool_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INT;
BEGIN

    -- Check for invalid quantity
    IF p_quantity <= 0 THEN

        RAISE EXCEPTION
        'Invalid quantity. Quantity must be greater than zero';

    END IF;


    -- Get available tool quantity
    SELECT available_quantity
    INTO v_available
    FROM tools
    WHERE tool_id = p_tool_id;


    -- Check whether tool exists
    IF v_available IS NULL THEN

        RAISE EXCEPTION
        'Tool does not exist';


    -- Check whether enough tools are available
    ELSIF v_available < p_quantity THEN

        RAISE EXCEPTION
        'Insufficient tools. Available: %, Requested: %',
        v_available,
        p_quantity;


    ELSE

        -- Reduce available quantity
        UPDATE tools
        SET available_quantity =
            available_quantity - p_quantity
        WHERE tool_id = p_tool_id;


        -- Record tool loan
        INSERT INTO tool_loans
        (
            student_number,
            tool_id,
            quantity,
            status
        )
        VALUES
        (
            p_student_number,
            p_tool_id,
            p_quantity,
            'BORROWED'
        );


        RAISE NOTICE
        'Tool issued successfully';

    END IF;

END;
$$;



-- 5. CALL ISSUE_TOOL


-- Valid loan 1
CALL issue_tool(
    '202300001',
    1,
    2
);


-- Valid loan 2
CALL issue_tool(
    '202300002',
    2,
    3
);


-- Invalid loan: requests more than available
-- Screwdrivers now have 2 remaining
CALL issue_tool(
    '202300003',
    2,
    5
);


-- Query tools
SELECT *
FROM tools
ORDER BY tool_id;


-- Query tool loans
SELECT *
FROM tool_loans
ORDER BY loan_id;



-- 6. CREATE RETURN_TOOL PROCEDURE

CREATE OR REPLACE PROCEDURE return_tool(
    p_loan_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tool_id INT;
    v_quantity INT;
    v_status VARCHAR(20);
BEGIN

    -- Find the loan
    SELECT tool_id,
           quantity,
           status
    INTO v_tool_id,
         v_quantity,
         v_status
    FROM tool_loans
    WHERE loan_id = p_loan_id;


    -- Check whether loan exists
    IF v_tool_id IS NULL THEN

        RAISE EXCEPTION
        'Tool loan does not exist';


    -- Return only if currently borrowed
    ELSIF v_status = 'BORROWED' THEN

        -- Restore available tools
        UPDATE tools
        SET available_quantity =
            available_quantity + v_quantity
        WHERE tool_id = v_tool_id;


        -- Mark loan as returned
        UPDATE tool_loans
        SET status = 'RETURNED'
        WHERE loan_id = p_loan_id;


        RAISE NOTICE
        'Tool returned successfully';


    ELSE

        RAISE NOTICE
        'Tool loan has already been returned. Stock was not restored again';

    END IF;

END;
$$;



-- CALL RETURN_TOOL TWICE FOR THE SAME LOAN


-- First return
CALL return_tool(1);


-- Second return of the same loan
CALL return_tool(1);



-- 7. EXPLICIT CURSOR

DO $$
DECLARE

    tool_cursor CURSOR FOR
        SELECT tool_id,
               tool_name,
               available_quantity
        FROM tools
        WHERE available_quantity <= 5;

    v_tool_id INT;
    v_tool_name VARCHAR(100);
    v_quantity INT;

BEGIN

    OPEN tool_cursor;

    LOOP

        FETCH tool_cursor
        INTO v_tool_id,
             v_tool_name,
             v_quantity;

        EXIT WHEN NOT FOUND;

        RAISE NOTICE
        'Tool ID: %, Tool: %, Available Quantity: %',
        v_tool_id,
        v_tool_name,
        v_quantity;

    END LOOP;

    CLOSE tool_cursor;

END $$;


-- 8. TRY TO ISSUE ZERO TOOLS

DO $$
BEGIN

    BEGIN

        CALL issue_tool(
            '202300004',
            1,
            0
        );

    EXCEPTION
        WHEN OTHERS THEN

            RAISE NOTICE
            'Invalid tool issue handled: %',
            SQLERRM;

    END;

END $$;


-- 9. FINAL QUERIES


-- Final tool quantities

SELECT
    tool_id,
    tool_name,
    available_quantity
FROM tools
ORDER BY tool_id;


-- Final tool loan statuses

SELECT
    loan_id,
    student_number,
    tool_id,
    quantity,
    status
FROM tool_loans
ORDER BY loan_id;
