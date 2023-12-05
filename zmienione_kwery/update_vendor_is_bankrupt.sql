--turn on/off displaying on output
SET FEEDBACK OFF;
SET PAGESIZE 1;
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
        
            MERGE INTO LEKARSTWO_RECEPTY lr
            USING (
                SELECT pom_lr.id AS pom_id, MIN(zamiennik_ID) KEEP (DENSE_RANK FIRST ORDER BY 
                CASE 
                    WHEN mg IS NOT NULL THEN mg
                    WHEN g IS NOT NULL THEN g
                    WHEN ml IS NOT NULL THEN ml
                END) AS first_row
                FROM LEKARSTWO_RECEPTY pom_lr
                JOIN RECEPTY r ON pom_lr.id_recepty = r.id
                JOIN LEKARSTWO oryginalne_l ON oryginalne_l.id = pom_lr.id_lekarstwa AND oryginalne_l.nazwa_producenta = 'US Pharmacia Sp. z o.o.'
                JOIN (
                    SELECT pom_l.id AS zamiennik_ID, pom_l.nazwa_chemiczna AS zamiennik_nazwa, pom_l.nazwa_producenta AS zamiennik_producent, pom_l.wielkosc_dawki_mg AS mg, pom_l.pojemnosc_ml AS ml, pom_l.pojemnosc_g AS g
                    FROM LEKARSTWO pom_l
                ) ON oryginalne_l.nazwa_chemiczna = zamiennik_nazwa AND zamiennik_producent NOT LIKE 'US Pharmacia Sp. z o.o.'
                AND ((oryginalne_l.wielkosc_dawki_mg IS NOT NULL AND mg IS NOT NULL)
                OR (oryginalne_l.pojemnosc_ml IS NOT NULL AND ml IS NOT NULL)
                OR (oryginalne_l.pojemnosc_g IS NOT NULL AND g IS NOT NULL))
                WHERE r.status = 'aktualna'
                GROUP BY pom_lr.id
            ) ON (lr.id = pom_id)
            WHEN MATCHED THEN
            UPDATE SET lr.id_lekarstwa = first_row;
                    
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
  INSERT INTO WYNIKI (NAZWA_TRANSAKCJI, LICZBA_URUCHOMIEN, CZAS_MIN, CZAS_MAX, CZAS_SREDNI) VALUES ('update vendor is bankrupt', v_iteration_limit, v_min_value, v_max_value, v_values_to_average/v_iteration_limit);
END;
/


--create plan
EXPLAIN PLAN FOR 
MERGE INTO LEKARSTWO_RECEPTY lr
USING (
    SELECT pom_lr.id AS pom_id, MIN(zamiennik_ID) KEEP (DENSE_RANK FIRST ORDER BY 
    CASE 
        WHEN mg IS NOT NULL THEN mg
        WHEN g IS NOT NULL THEN g
        WHEN ml IS NOT NULL THEN ml
    END) AS first_row
    FROM LEKARSTWO_RECEPTY pom_lr
    JOIN RECEPTY r ON pom_lr.id_recepty = r.id
    JOIN LEKARSTWO oryginalne_l ON oryginalne_l.id = pom_lr.id_lekarstwa AND oryginalne_l.nazwa_producenta = 'US Pharmacia Sp. z o.o.'
    JOIN (
        SELECT pom_l.id AS zamiennik_ID, pom_l.nazwa_chemiczna AS zamiennik_nazwa, pom_l.nazwa_producenta AS zamiennik_producent, pom_l.wielkosc_dawki_mg AS mg, pom_l.pojemnosc_ml AS ml, pom_l.pojemnosc_g AS g
        FROM LEKARSTWO pom_l
    ) ON oryginalne_l.nazwa_chemiczna = zamiennik_nazwa AND zamiennik_producent NOT LIKE 'US Pharmacia Sp. z o.o.'
    AND ((oryginalne_l.wielkosc_dawki_mg IS NOT NULL AND mg IS NOT NULL)
    OR (oryginalne_l.pojemnosc_ml IS NOT NULL AND ml IS NOT NULL)
    OR (oryginalne_l.pojemnosc_g IS NOT NULL AND g IS NOT NULL))
    WHERE r.status = 'aktualna'
    GROUP BY pom_lr.id
) ON (lr.id = pom_id)
WHEN MATCHED THEN
UPDATE SET lr.id_lekarstwa = first_row;

--save explained plan to file
SPOOL D:\Queries\output\update_vendor_is_bankrupt.txt APPEND;
SELECT * FROM TABLE(dbms_xplan.display);
SPOOL OFF;
