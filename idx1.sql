--Select 1 - klucz obcy id_recepty w lekarstwo_recepta
CREATE INDEX idx_id_recepty_lr ON lekarstwo_recepty (id_recepty);

DROP INDEX idx_id_recepty_lrs;


--Select 2 - wizyty funkcyjny

CREATE INDEX idx_data_rozpoczecia ON WIZYTA (EXTRACT YEAR FROM(ROZPOCZECIE));

--Select 3 - klucz obcy id_lekarstwa w lekarstwo_recepta
CREATE INDEX idx_id_lekarstwa_lr ON lekarstwo_recepty (id_lekarstwa);

DROP INDEX idx_id_lekarstwa_lr;

--Select 4 pomysł Kamila
    
    
    
