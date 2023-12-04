--turn on/off displaying on output
SET FEEDBACK OFF;
SET PAGESIZE 1;
SET VERIFY OFF;

--clear cahce
ALTER SYSTEM FLUSH shared_pool;
ALTER SYSTEM FLUSH buffer_cache;


DECLARE
  v_iteration_limit NUMBER := &number_of_iterations;
  v_counter NUMBER := 1;
  v_min_value NUMBER := 1000000;
  v_max_value NUMBER := -1;
  v_values_to_average NUMBER := 0;
  
BEGIN
  FOR v_counter IN 1..v_iteration_limit LOOP
    DECLARE
        v_start_time NUMBER;
        v_end_time NUMBER;
        v_elapsed_time NUMBER; 
        v_variable NUMBER;
        v_sql_statement VARCHAR2(100);
        v_sql_statement2 VARCHAR2(100);
        
    BEGIN  
        v_sql_statement := 'ALTER SYSTEM FLUSH SHARED_POOL';
        v_sql_statement2 := 'ALTER SYSTEM FLUSH BUFFER_CACHE';
        EXECUTE IMMEDIATE v_sql_statement;
        EXECUTE IMMEDIATE v_sql_statement2;
        
        BEGIN
            v_start_time := DBMS_UTILITY.GET_TIME;
        
            WITH cte AS (
                SELECT w.ID_PACJENTA ,
                    EXTRACT(DAY FROM (w.rozpoczecie - LAG(w.ROZPOCZECIE) OVER (PARTITION BY w.ID_PACJENTA ORDER BY w.rozpoczecie))) AS ROZ_DNI
                FROM WIZYTA w
                ORDER BY w.ID_PACJENTA
                )
            SELECT COUNT(*) INTO v_variable
            FROM (
                SELECT przy.NAZWA, AVG(ROZ_DNI)
                FROM cte
                JOIN PACJENT p ON p.ID = ID_PACJENTA
                JOIN PRZYCHODNIA przy ON p.ID_PRZYCHODNI = przy.ID 
                GROUP BY przy.id, przy.NAZWA  
            );
                    
            v_end_time := DBMS_UTILITY.GET_TIME;
            v_elapsed_time := (v_end_time - v_start_time) / 100;
            
            IF v_elapsed_time > v_max_value
            THEN v_max_value := v_elapsed_time;
            END IF;
            
            IF v_elapsed_time < v_min_value
            THEN v_min_value := v_elapsed_time;
            END IF;
            
            v_values_to_average := v_values_to_average + v_elapsed_time;
            
        END;
    END;
  END LOOP;
  INSERT INTO WYNIKI (NAZWA_TRANSAKCJI, LICZBA_URUCHOMIEN, CZAS_MIN, CZAS_MAX, CZAS_SREDNI) VALUES ('avg days between visits', v_iteration_limit, v_min_value, v_max_value, v_values_to_average/v_iteration_limit);
END;
/


--create plan
EXPLAIN PLAN FOR 
WITH cte AS (
	SELECT w.ID_PACJENTA ,
		EXTRACT(DAY FROM (w.rozpoczecie - LAG(w.ROZPOCZECIE) OVER (PARTITION BY w.ID_PACJENTA ORDER BY w.rozpoczecie))) AS ROZ_DNI
	FROM WIZYTA w
	ORDER BY w.ID_PACJENTA
	)
SELECT *
FROM (
    SELECT przy.NAZWA, AVG(ROZ_DNI)
    FROM cte
    JOIN PACJENT p ON p.ID = ID_PACJENTA
    JOIN PRZYCHODNIA przy ON p.ID_PRZYCHODNI = przy.ID 
    GROUP BY przy.id, przy.NAZWA  
    ORDER BY przy.NAZWA
);

--save explained plan to file
SPOOL C:\SQL_output\avg_days_between_visits.txt APPEND;
SELECT * FROM TABLE(dbms_xplan.display);
SPOOL OFF;
