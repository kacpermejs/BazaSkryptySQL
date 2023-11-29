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
        
            WITH Subquery AS (
                SELECT w.id_personelu AS personel_ID, COUNT(*) AS liczba_recept
                FROM RECEPTY r
                JOIN WIZYTA w ON w.id = r.id_wizyty
                WHERE EXTRACT(YEAR FROM (SYSDATE)) = EXTRACT(YEAR FROM w.rozpoczecie) AND r.status LIKE 'wykupiona'
                GROUP BY w.id_personelu
            )
            SELECT COUNT(COUNT(*)) INTO v_variable
            FROM PERSONEL_MEDYCZNY pm2
            JOIN PRZYCHODNIA prz2 ON pm2.id_przychodni = prz2.id
            JOIN OSOBA o ON o.id = pm2.id_osoby
            JOIN Subquery sub ON personel_ID = pm2.id
            JOIN (
                SELECT prz.nazwa AS nazwa_przychodni, AVG(liczba_recept) AS srednia_liczba_recept, prz.data_rozpoczecia_dzialalnosci AS data
                FROM PRZYCHODNIA prz
                JOIN PERSONEL_MEDYCZNY pm ON prz.id = pm.id_przychodni
                JOIN Subquery sub ON sub.personel_id = pm.id
                GROUP BY prz.nazwa, prz.data_rozpoczecia_dzialalnosci
            ) ON prz2.nazwa = nazwa_przychodni
            WHERE liczba_recept > srednia_liczba_recept AND pm2.typ_umowy LIKE 'Umowa zlecenia'
            GROUP BY pm2.id, o.imie, o.nazwisko, prz2.nazwa, liczba_recept, srednia_liczba_recept, data
            ORDER BY data;
                    
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
  INSERT INTO WYNIKI (NAZWA_TRANSAKCJI, LICZBA_URUCHOMIEN, CZAS_MIN, CZAS_MAX, CZAS_SREDNI) VALUES ('average vs personel', v_iteration_limit, v_min_value, v_max_value, v_values_to_average/v_iteration_limit);
END;
/


--create plan
EXPLAIN PLAN FOR 
WITH Subquery AS (
    SELECT w.id_personelu AS personel_ID, COUNT(*) AS liczba_recept
    FROM RECEPTY r
    JOIN WIZYTA w ON w.id = r.id_wizyty
    WHERE EXTRACT(YEAR FROM (SYSDATE)) = EXTRACT(YEAR FROM w.rozpoczecie) AND r.status LIKE 'wykupiona'
    GROUP BY w.id_personelu
)
SELECT pm2.id, o.imie, o.nazwisko, prz2.nazwa, liczba_recept, srednia_liczba_recept, data
FROM PERSONEL_MEDYCZNY pm2
JOIN PRZYCHODNIA prz2 ON pm2.id_przychodni = prz2.id
JOIN OSOBA o ON o.id = pm2.id_osoby
JOIN Subquery sub ON personel_ID = pm2.id
JOIN (
    SELECT prz.nazwa AS nazwa_przychodni, AVG(liczba_recept) AS srednia_liczba_recept, prz.data_rozpoczecia_dzialalnosci AS data
    FROM PRZYCHODNIA prz
    JOIN PERSONEL_MEDYCZNY pm ON prz.id = pm.id_przychodni
    JOIN Subquery sub ON sub.personel_id = pm.id
    GROUP BY prz.nazwa, prz.data_rozpoczecia_dzialalnosci
) ON prz2.nazwa = nazwa_przychodni
WHERE liczba_recept > srednia_liczba_recept AND pm2.typ_umowy LIKE 'Umowa zlecenia'
GROUP BY pm2.id, o.imie, o.nazwisko, prz2.nazwa, liczba_recept, srednia_liczba_recept, data
ORDER BY data
FETCH FIRST 1000 ROWS ONLY;

--save explained plan to file
SPOOL D:\Queries\output\select_average_vs_personel.txt APPEND;
SELECT * FROM TABLE(dbms_xplan.display);
SPOOL OFF;