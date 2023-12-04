CREATE TABLE wyniki 
(
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nazwa_transakcji NVARCHAR2(100) NOT NULL,
    liczba_uruchomien INT NOT NULL,
    czas_min NUMBER NOT NULL,
    czas_max NUMBER NOT NULL,
    czas_sredni NUMBER NOT NULL,
    data_badania TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

SELECT * FROM wyniki