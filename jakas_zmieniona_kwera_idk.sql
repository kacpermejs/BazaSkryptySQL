SELECT COUNT(*) INTO v_variable
FROM (
    SELECT p.id, p.NAZWA, AVG(wynik.ROZ_DNI) AS srednia, wynik.kategoria_wiekowa
    FROM (
            SELECT w.ID_PACJENTA ,
                CASE WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM osoba.DATA_URODZENIA) < 13 THEN 'dziecko'
                    WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM osoba.DATA_URODZENIA) >= 13 
                        AND EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM osoba.DATA_URODZENIA) < 25 THEN 'nastolatek'
                    WHEN EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM osoba.DATA_URODZENIA) >= 25 THEN 'dorosly'
                ELSE NULL
                END AS kategoria_wiekowa,
                EXTRACT(DAY FROM (w.rozpoczecie - LAG(w.ROZPOCZECIE) OVER (PARTITION BY w.ID_PACJENTA ORDER BY w.rozpoczecie))) AS ROZ_DNI
            FROM WIZYTA w
            JOIN PACJENT pacjent ON pacjent.ID = w.ID_PACJENTA
            JOIN OSOBA osoba ON osoba.ID = pacjent.ID_OSOBY 
            WHERE (SYSDATE - (INTERVAL '30' DAY)) >= w.ROZPOCZECIE AND w.CZY_PRYWATNA = 'F' AND w.STATUS = 'zakonczona'
            ORDER BY w.ID_PACJENTA
        ) wynik
    JOIN PRZYCHODNIA p ON wynik.ID_PACJENTA = p.ID
    WHERE wynik.ROZ_DNI IS NOT NULL
    GROUP BY p.id, p.NAZWA, wynik.kategoria_wiekowa
    ORDER BY p.NAZWA, wynik.kategoria_wiekowa
);
