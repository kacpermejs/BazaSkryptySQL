PARTITION BY RANGE(ROZPOCZECIE)
INTERVAL(NUMTOYMINTERVAL(1,'YEAR'))
STORE IN (WIZYTA_TBS)
(
    PARTITION wizyta201901 VALUES LESS THAN(TO_DATE('01/01/2019','MM/DD/YYYY'))
);

ALTER TABLE pacjent
ADD PARTITION BY LIST(rodzaj_swiadczenia)(
    PARTITION pacjentpremium VALUES IN ("Premium"),
    PARTITION pacjentpremiumplus VALUES IN ("Premium+"),
    PARTITION pacjentpodstawowe VALUES IN ("Podstawowe")
);


SELECT * FROM pacjent WHERE rodzaj_swiadczenia = 'Premium+'
FETCH FIRST 3 ROWS ONLY;

SELECT rodzaj_swiadczenia, COUNT(*)
FROM pacjent
GROUP BY rodzaj_swiadczenia;


CREATE TABLE pacjent_part
(
    id INT PRIMARY KEY,
    id_osoby INT NOT NULL,
    id_przychodni INT NOT NULL,
    numer_ubezpieczenia char(10) NOT NULL,
    rodzaj_swiadczenia NVARCHAR2(20) NOT NULL,
    status_swiadczenia NVARCHAR2(10) NOT NULL,
    
    CONSTRAINT pacjent_id_osoby_fk
    FOREIGN KEY (id_osoby)
    REFERENCES osoba(id),
    
    CONSTRAINT pacjent_id_przychodni_fk
    FOREIGN KEY (id_przychodni)
    REFERENCES przychodnia(id)
)
    PARTITION BY LIST (RODZAJ_SWIADCZENIA)
(
    PARTITION pacjentpremium
        VALUES ('Premium'),
    PARTITION pacjentpremiumplus
        VALUES ('Premium+'),
    PARTITION pacjentpodstawowe
        VALUES ('Podstawowe')
);




