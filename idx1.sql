--Select 1 - klucz obcy id_recepty w lekarstwo_recepta
CREATE INDEX idx_id_recepty_lr ON lekarstwo_recepta (id_recepty);

DROP INDEX idx_id_recepty_lr ON lekarstwo_recepta;


--Select 2 - wizyty funkcyjny

--Select 3 - klucz obcy id_lekarstwa w lekarstwo_recepta
CREATE INDEX idx_id_lekarstwa_lr ON lekarstwo_recepta (id_lekarstwa);

DROP INDEX idx_id_lekarstwa_lr ON lekarstwo_recepta;

--Select 4 pomysł Kamila
    
    
    