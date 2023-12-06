SELECT COUNT(*) 
FROM (
    SELECT id_lekarstwa as poprzednie_id_l FROM lekarstwo_recepty
);
