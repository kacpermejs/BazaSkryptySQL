--Select 1 - klucz obcy id_recepty w lekarstwo_recepta

--Select 2 - wizyty funkcyjny

CREATE INDEX idx_data_rozpoczecia ON WIZYTA (EXTRACT(YEAR FROM(ROZPOCZECIE)));

--Select 3 - klucz obcy id_lekarstwa w lekarstwo_recepta

CREATE INDEX idx_wiz ON WIZYTA (STATUS, CZY_PRYWATNA, REFUNDACJA);

--Select 4 pomysł Kamila
    
-- Tu będzie też funkcyjny jak w select 2 i range jak na podstawie interwału    
    
