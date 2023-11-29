
ACCEPT path CHAR PROMPT 'WprowadŸ œcie¿kê do folderu ze skryptami'
DEFINE number_of_iterations = '5'

--MODYFIKUJ¥CY UPDATE (leki danej firmy zosta³y wycofane i nale¿y dla recept niezrealizowanych znaleŸæ zamienniki) 
@&path\update_vendor_is_bankrupt.sql

--MODYFIKUJ¥CY UPDATE (z premium na premium+)
@&path\update_premium.sql

--SELECT (wyszukanie œredniej liczby dni pomiêdzy wizytami dla pacjentów)
@&path\avg_days_between_visits.sql

--SELECT (szukamy pacjentów, którzy maj¹ wiêcej ni¿ 3 ró¿ne leki przepisane na którejkolwiek recepcie) 
@&path\select_patients_with_3_meds.sql

--SELECT (œrednia liczba wystawionych w przychodni, listujemy personel, który wystawi³ wiêcej ni¿ œrednia w jego przychodni)
@&path\select_average_vs_personel.sql

--SELECT (szukamy, jakie lekarstwo by³o przepisywane na receptach (liczy sie iloœæ opakowañ) w danej przychodni)
@&path\select_most_popular_medicine.sql

--Print table with results
SELECT * FROM WYNIKI;
