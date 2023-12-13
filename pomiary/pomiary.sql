
--ACCEPT path CHAR PROMPT 'Wprowad� �cie�k� do folderu ze skryptami'
DEFINE path = 'C:\Users\kacpe\Desktop\BazaSkryptySQL\pomiary'
DEFINE number_of_iterations = '1'

--MODYFIKUJ�CY UPDATE (leki danej firmy zosta�y wycofane i nale�y dla recept niezrealizowanych znale�� zamienniki) 
--@&path\update_vendor_is_bankrupt.sql

--MODYFIKUJ�CY UPDATE (z premium na premium+)
--@&path\update_premium.sql

--SELECT (wyszukanie �redniej liczby dni pomi�dzy wizytami dla pacjent�w)
@&path\avg_days_between_visits.sql

--SELECT (szukamy pacjent�w, kt�rzy maj� wi�cej ni� 3 r�ne leki przepisane na kt�rejkolwiek recepcie) 
--@&path\select_patients_with_3_meds.sql

--SELECT (�rednia liczba wystawionych w przychodni, listujemy personel, kt�ry wystawi� wi�cej ni� �rednia w jego przychodni)
--@&path\select_most_popular_medicine.sql
--@&path\select_average_vs_personel.sql

--SELECT (szukamy, jakie lekarstwo by�o przepisywane na receptach (liczy sie ilo�� opakowa�) w danej przychodni)


--Print table with results
SELECT * FROM WYNIKI;
