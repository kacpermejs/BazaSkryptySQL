--turn on/off displaying on output
SET FEEDBACK OFF;
SET PAGESIZE 1;
SET VERIFY OFF;

--clear cache
ALTER SYSTEM FLUSH buffer_cache;
ALTER SYSTEM FLUSH shared_pool;

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
        v_variable NVARCHAR2(1000);
        v_sql_statement VARCHAR2(100);
        v_sql_statement2 VARCHAR2(100);
        
    BEGIN  
        v_sql_statement := 'ALTER SYSTEM FLUSH SHARED_POOL';
        v_sql_statement2 := 'ALTER SYSTEM FLUSH BUFFER_CACHE';
        EXECUTE IMMEDIATE v_sql_statement;
        EXECUTE IMMEDIATE v_sql_statement2;
        
        BEGIN
            v_start_time := DBMS_UTILITY.GET_TIME;
        
            SELECT /*+ INDEX(wizyta idx_wiz) */ COUNT(*) INTO v_variable
            FROM PACJENT p
            JOIN OSOBA o ON o.id = p.id_osoby
            JOIN PRZYCHODNIA prz ON p.id_przychodni = prz.id
            WHERE p.rodzaj_swiadczenia = 'Premium+' AND
            p.id IN (
              SELECT /*+ INDEX(wizyta idx_wiz) */ DISTINCT w.id_pacjenta
              FROM WIZYTA w
              JOIN (
                SELECT /*+ INDEX(wizyta idx_wiz) */ r.id_pacjenta AS pacjent_ID
                FROM RECEPTY r
                JOIN LEKARSTWO_RECEPTY lr ON lr.id_recepty = r.id
                JOIN LEKARSTWO l ON l.id = lr.id_lekarstwa
                GROUP BY r.id_pacjenta
                HAVING COUNT(DISTINCT lr.id_lekarstwa) >= 3 AND COUNT(DISTINCT l.nazwa_producenta) >= 3
              ) ON w.id_pacjenta = pacjent_ID
              WHERE w.STATUS = 'zakonczona' AND w.CZY_PRYWATNA = 'T' AND w.REFUNDACJA IS NULL
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
  INSERT INTO WYNIKI (NAZWA_TRANSAKCJI, LICZBA_URUCHOMIEN, CZAS_MIN, CZAS_MAX, CZAS_SREDNI) VALUES ('patients_with_3_meds', v_iteration_limit, v_min_value, v_max_value, v_values_to_average/v_iteration_limit);
END;
/


--create plan
EXPLAIN PLAN FOR 
SELECT /*+ INDEX(wizyta idx_wiz) */ COUNT(*)
FROM PACJENT p
JOIN OSOBA o ON o.id = p.id_osoby
JOIN PRZYCHODNIA prz ON p.id_przychodni = prz.id
WHERE p.rodzaj_swiadczenia = 'Premium+' AND
p.id IN (
  SELECT /*+ INDEX(wizyta idx_wiz) */ DISTINCT w.id_pacjenta
  FROM WIZYTA w
  JOIN (
    SELECT /*+ INDEX(wizyta idx_wiz) */ r.id_pacjenta AS pacjent_ID
    FROM RECEPTY r
    JOIN LEKARSTWO_RECEPTY lr ON lr.id_recepty = r.id
    JOIN LEKARSTWO l ON l.id = lr.id_lekarstwa
    GROUP BY r.id_pacjenta
    HAVING COUNT(DISTINCT lr.id_lekarstwa) >= 3 AND COUNT(DISTINCT l.nazwa_producenta) >= 3
  ) ON w.id_pacjenta = pacjent_ID
  WHERE w.STATUS = 'zakonczona' AND w.CZY_PRYWATNA = 'T' AND w.REFUNDACJA IS NULL
);

--save explained plan to file
SPOOL C:\SQL_output\patients_3_meds.txt APPEND;
SELECT * FROM TABLE(dbms_xplan.display);
SPOOL OFF;
