--turn on/off displaying on output
SET FEEDBACK OFF;
SET PAGESIZE 1;
SET VERIFY OFF;

--clear cahce
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
        
            SELECT COUNT(*) INTO v_variable
            FROM (
                SELECT nazwa_przychodni, nazwa_leku, miasto AS miasto, RANK() OVER (PARTITION BY nazwa_przychodni ORDER BY ilosc_opakowan DESC) AS ranking
                FROM (
                    SELECT l.id, prz.nazwa AS nazwa_przychodni, l.nazwa AS nazwa_leku, SUM(lr.ilosc_opakowan) AS ilosc_opakowan, prz.miasto AS miasto
                    FROM LEKARSTWO_RECEPTY lr 
                    JOIN LEKARSTWO l ON l.id = lr.id_lekarstwa
                    JOIN RECEPTY r ON r.id = lr.id_recepty
                    JOIN PACJENT p ON p.id = r.id_pacjenta
                    JOIN PRZYCHODNIA prz ON prz.id = p.id_przychodni
                    WHERE l.pojemnosc_ml > 1000 OR l.pojemnosc_g > 400 OR l.ilosc_dawek > 30
                    GROUP BY l.id, prz.nazwa, l.nazwa, prz.miasto
                    HAVING SUM(lr.ilosc_opakowan) > 0
                ) 
                GROUP BY nazwa_przychodni, nazwa_leku, miasto, ilosc_opakowan
            )
            WHERE ranking = 1 AND miasto LIKE 'Bydgoszcz%';
        
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
  INSERT INTO WYNIKI (NAZWA_TRANSAKCJI, LICZBA_URUCHOMIEN, CZAS_MIN, CZAS_MAX, CZAS_SREDNI) VALUES ('most popular medicine', v_iteration_limit, v_min_value, v_max_value, v_values_to_average/v_iteration_limit);
END;
/


--create plan
EXPLAIN PLAN FOR 
SELECT *
FROM (
    SELECT nazwa_przychodni, nazwa_leku, miasto AS miasto, RANK() OVER (PARTITION BY nazwa_przychodni ORDER BY ilosc_opakowan DESC) AS ranking
    FROM (
        SELECT l.id, prz.nazwa AS nazwa_przychodni, l.nazwa AS nazwa_leku, SUM(lr.ilosc_opakowan) AS ilosc_opakowan, prz.miasto AS miasto
        FROM LEKARSTWO_RECEPTY lr 
        JOIN LEKARSTWO l ON l.id = lr.id_lekarstwa
        JOIN RECEPTY r ON r.id = lr.id_recepty
        JOIN PACJENT p ON p.id = r.id_pacjenta
        JOIN PRZYCHODNIA prz ON prz.id = p.id_przychodni
        WHERE l.pojemnosc_ml > 1000 OR l.pojemnosc_g > 400 OR l.ilosc_dawek > 30
        GROUP BY l.id, prz.nazwa, l.nazwa, prz.miasto
        HAVING SUM(lr.ilosc_opakowan) > 0
    ) 
    GROUP BY nazwa_przychodni, nazwa_leku, miasto, ilosc_opakowan
)
WHERE ranking = 1 AND miasto LIKE 'Bydgoszcz%';

--save explained plan to file
SPOOL C:\SQL_output\select_most_popular_medicine.txt APPEND;
SELECT * FROM TABLE(dbms_xplan.display);
SPOOL OFF;
