select * from v$OPTION;

ALTER TABLE wizyta MODIFY
PARTITION BY RANGE (rozpoczecie)
INTERVAL
(
    NUMTOYMINTERVAL(1, 'MONTH')
)
(
    PARTITION P_DEC2018 VALUES LESS THAN (TO_DATE('01/01/2019','DD/MM/YYYY'))
);


ALTER TABLE pacjent MODIFY
PARTITION BY LIST(rodzaj_swiadczenia)(
    PARTITION pacjentpremium VALUES ('Premium'),
    PARTITION pacjentpremiumplus VALUES ('Premium+'),
    PARTITION pacjentpodstawowe VALUES ('Podstawowe')
);

ALTER TABLE pacjent DROP PARTITION pacjentpremium, pacjentpremiumplus, pacjentpodstawowe;



SELECT * FROM pacjent WHERE rodzaj_swiadczenia = 'Premium+'
FETCH FIRST 3 ROWS ONLY;

SELECT rodzaj_swiadczenia, COUNT(*)
FROM pacjent
GROUP BY rodzaj_swiadczenia;




