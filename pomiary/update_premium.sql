--turn on/off displaying on output
SET FEEDBACK OFF;
SET PAGESIZE 0;
SET VERIFY OFF;

--clear cahce
ALTER SYSTEM FLUSH buffer_cache;
ALTER SYSTEM FLUSH shared_pool;

DECLARE
  v_savepoint_name VARCHAR2(30) := 'SP';
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
        v_sql_statement VARCHAR2(100);
        v_sql_statement2 VARCHAR2(100);
        v_sql_statement3 VARCHAR2(100);
        
    BEGIN  
        v_sql_statement := 'ALTER SYSTEM FLUSH SHARED_POOL';
        v_sql_statement2 := 'ALTER SYSTEM FLUSH BUFFER_CACHE';
        EXECUTE IMMEDIATE v_sql_statement;
        EXECUTE IMMEDIATE v_sql_statement2;
                
        BEGIN
            SAVEPOINT v_savepoint_name;
            v_start_time := DBMS_UTILITY.GET_TIME;
        
            UPDATE (
                SELECT *
                FROM PACJENT p
                JOIN (
                    SELECT w.id_pacjenta AS pacjent_ID, NVl(AVG(CASE WHEN w.cena > 0 THEN w.cena END), 0) AS koszty_pacjenta_AVG
                    FROM WIZYTA w
                    GROUP BY w.id_pacjenta
                ) ON pacjent_ID = p.id
            ) sub
            SET sub.rodzaj_swiadczenia = 'Premium+'
            WHERE sub.koszty_pacjenta_AVG >= 200 AND sub.status_swiadczenia = 'Aktywne' AND sub.rodzaj_swiadczenia = 'Premium';
                    
            v_end_time := DBMS_UTILITY.GET_TIME;
            
            v_sql_statement3 := 'alter system checkpoint;';
            
            v_elapsed_time := (v_end_time - v_start_time) / 100;
            
            IF v_elapsed_time > v_max_value
            THEN v_max_value := v_elapsed_time;
            END IF;
            
            IF v_elapsed_time < v_min_value
            THEN v_min_value := v_elapsed_time;
            END IF;
            
            v_values_to_average := v_values_to_average + v_elapsed_time;
            ROLLBACK TO v_savepoint_name;
            
        END;
    END;
  END LOOP;
  INSERT INTO WYNIKI (NAZWA_TRANSAKCJI, LICZBA_URUCHOMIEN, CZAS_MIN, CZAS_MAX, CZAS_SREDNI) VALUES ('premium', v_iteration_limit, v_min_value, v_max_value, v_values_to_average/v_iteration_limit);
END;
/


--create plan
EXPLAIN PLAN FOR 
UPDATE (
    SELECT *
    FROM PACJENT p
    JOIN (
        SELECT w.id_pacjenta AS pacjent_ID, NVl(AVG(CASE WHEN w.cena > 0 THEN w.cena END), 0) AS koszty_pacjenta_AVG
        FROM WIZYTA w
        GROUP BY w.id_pacjenta
    ) ON pacjent_ID = p.id
) sub
SET sub.rodzaj_swiadczenia = 'Premium+'
WHERE sub.koszty_pacjenta_AVG >= 200 AND sub.status_swiadczenia = 'Aktywne' AND sub.rodzaj_swiadczenia = 'Premium';

--save explained plan to file
SPOOL D:\Queries\output\update_premium.txt APPEND;
SELECT * FROM TABLE(dbms_xplan.display);
SPOOL OFF;
