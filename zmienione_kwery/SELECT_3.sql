SELECT COUNT(*) 
FROM PACJENT p
JOIN OSOBA o ON o.id = p.id_osoby
JOIN PRZYCHODNIA prz ON p.id_przychodni = prz.id
WHERE p.rodzaj_swiadczenia = 'Premium+' AND
p.id IN (
  SELECT DISTINCT w.id_pacjenta
  FROM WIZYTA w
  JOIN (
    SELECT r.id_pacjenta AS pacjent_ID
    FROM RECEPTY r
    JOIN LEKARSTWO_RECEPTY lr ON lr.id_recepty = r.id
    JOIN LEKARSTWO l ON l.id = lr.id_lekarstwa
    GROUP BY r.id_pacjenta
    HAVING COUNT(DISTINCT lr.id_lekarstwa) >= 3 AND COUNT(DISTINCT l.nazwa_producenta) >= 3
  ) ON w.id_pacjenta = pacjent_ID
  WHERE w.STATUS = 'zakonczona' AND w.CZY_PRYWATNA = 'T' AND w.REFUNDACJA IS NULL
);
