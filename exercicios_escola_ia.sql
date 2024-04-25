-- 1. A base possui diversos valores nulos. Preencha nas colunas onde os valores são nulls com 'NAN'.
CREATE TABLE normalized_table AS (SELECT * from netflix_titles)

DO
$$
DECLARE
	rec record;
BEGIN
	for rec in 
		select * from information_schema.columns WHERE TABLE_NAME = 'normalized_table' AND DATA_TYPE = 'integer'
	LOOP
        EXECUTE 'UPDATE normalized_table set ' || rec.column_name || '=0 WHERE ' || rec.column_name ||  '= NULL';
	end loop;
end
$$;
-- Essa normalização ficou incompleta pois o sistema não aceitou NaN escrito diretamente

-- Comando individual: UPDATE normalized_table <nome_coluna>=NaN WHERE <nome_coluna> = NULL

/*
3. Normalize a coluna CAST criando uma nova tabela 'cast_table' de modo que tenhamos separadamente,ou seja, uma coluna com o nome do elenco de cada filme.

Exemplo:
Linha: n1 joao, maria, roberto

coluna:
id CAST
n1 joao
n1 maria
n1 roberto
*/
CREATE TABLE cast_table AS (SELECT nf.show_id, unnest(string_to_array(nf.cast, ',')) FROM netflix_titles AS nf)

/*
4. Normalize a coluna listed_in criando uma nova tabela 'genre_table' de modo que tenhamos separadamente os gêneros
de cada programação. Exemplo:

Linha: n1 Ação, Aventura, Comédia

coluna:

n1 Ação
n1 Comédia
n1 Aventura
*/
CREATE TABLE genre_table AS (SELECT nf.show_id, unnest(string_to_array(nf.listed_in, ',')) FROM netflix_titles AS nf)

/*
5. Normalize a coluna date_added em uma nova base 'date_table' e construa as seguintes colunas:
- coluna day: DD
- coluna mouth: MM
- coluna year: YY
- coluna iso_date_1: YYYY-MM-DD
- coluna iso_date_2: YYYY/MM/DD
- coluna iso_date_3: YYMMDD
- coluna iso_date_4: YYYYMMDD
*/
CREATE TABLE date_table AS (
  SELECT 
  	nf.show_id, nf.title, nf.type,
  	to_char(nf.date_added, 'DD') as "day",
  	to_char(nf.date_added, 'MM') as "mouth",
    to_char(nf.date_added, 'MM') as "year",
    to_char(nf.date_added, 'YYYY-MM-DD') as "iso_date_1",
    to_char(nf.date_added, 'YYYY/MM/DD') as "iso_date_2",
    to_char(nf.date_added, 'YYMMDD') as "iso_date_3"
  FROM netflix_titles as nf
)

/*
6. Normalize a coluna duration e construa uma nova base 'time_table' e faça as seguintes conversões.
- Converta a coluna duration para horas e crie a coluna hours hh. Obs. A média de cada
season TV SHOW é 10 horas, assim também converta para horas
- Converta todas as horas para minutos e armazena na coluna minutes mm.
*/
CREATE TABLE time_table as( SELECT *, hh * 60 as mm FROM (
  SELECT 
  	nf.show_id, nf.title, nf.type,
  	CASE
  		When nf.duration LIKE '%min' THEN (to_number(REPLACE(nf.duration, ' min', ''), '99999999') / 60)
  		When nf.duration LIKE '%Season' THEN 10
        When nf.duration LIKE '%Seasons' THEN (to_number(REPLACE(nf.duration, ' Season', '') , '99999999') * 10)
  	END hh
  FROM netflix_titles as nf
))

/*
7. Normalize a coluna country criando uma nova tabela 'country_table' de modo que tenhamos separadamente
uma coluna com o nome do país de cada filme.
*/
CREATE TABLE country_table AS (SELECT nf.show_id, unnest(string_to_array(nf.country, ',')) FROM netflix_titles AS nf)

-- 8. Qual o filme de duração máxima em minutos ?
-- COMANDO:
SELECT title, mm FROM time_table WHERE mm IN (SELECT MAX(mm) FROM time_table WHERE "type" = 'Movie')
-- RESPOSTA: Black Mirror: Bandersnatch, 312 min

-- 9. Qual o filme de duraçã mínima em minutos ?
SELECT title, mm FROM time_table WHERE mm IN (SELECT MIN(mm) FROM time_table WHERE "type" = 'Movie')
-- RESPOSTA: Silent, 3 min

-- 10. Qual a série de duração máxima em minutos ?
SELECT title, mm FROM time_table WHERE mm IN (SELECT MIN(mm) FROM time_table WHERE "type" = 'TV Show')
-- RESPOSTA: Grey's Anatomy, 10200 min

-- 11. Qual a série de duração mínima em minutos ?
SELECT COUNT(*) FROM time_table WHERE mm in (SELECT MIN(mm) FROM time_table WHERE "type" = 'TV Show')
-- 1793 Series

-- 12. Qual a média de tempo de duração dos filmes?
SELECT AVG(mm) FROM time_table WHERE "type" = 'Movie'
-- RESPOSTA: 99 min

-- 13. Qual a média de tempo de duração das series?
SELECT AVG(mm) FROM time_table WHERE "type" = 'TV Show'
-- RESPOSTA: 1058 min

-- 14. Qual a lista de filmes o ator Leonardo DiCaprio participa?
SELECT nf.show_id, nf.title FROM netflix_titles as nf
INNER JOIN cast_table as ct ON ct.show_id = nf.show_id
WHERE ct.name = 'Leonardo DiCaprio' and nf.type = 'Movie'
-- OU
SELECT nf.show_id, nf.title FROM netflix_titles as nf
WHERE nf.cast LIKE '%Leonardo DiCaprio%' and nf.type = 'Movie'
-- As tabelas não foram exibidas por dificuldade de download dos resultados

-- 15. Quantas vezes o ator Tom Hanks apareceu nas telas do netflix, ou seja, tanto série quanto filmes?
SELECT COUNT(*) FROM netflix_titles as nf
WHERE nf.cast LIKE '%Tom Hanks%'
-- RESPOSTA: 8

-- 16. Quantas produções séries e filmes brasileiras já foram ao ar no netflix?
SELECT COUNT(*) FROM netflix_titles as nf
WHERE nf.country = 'Brazil'
-- RESPOSTA: 77

-- 17. Quantos filmes americanos já foram para o ar no netflix?
SELECT COUNT(*) FROM netflix_titles as nf
WHERE nf.country = 'United States' AND nf.type = 'Movie'
-- RESPOSTA: 2058

/*
18. Crie uma nova coluna com o nome last_name_director com uma nova formatação para o nome dos diretores, por exemplo. João Roberto para Roberto, João.
*/
CREATE TABLE director_table_2 AS (SELECT *,SUBSTRING(nf.director, 1, POSITION(' ' IN nf.director)) as last_name_director FROM netflix_titles AS nf)

-- 19. Procure a lista de conteúdos que tenha como temática a segunda guerra mundial (WWII)?
SELECT nf.show_id, nf.title, nf.description FROM netflix_titles as nf
WHERE nf.description LIKE '%WWII%' or nf.title LIKE '%WWII%'

-- 20. Conte o número de produções dos países que apresentaram conteúdos no netflix?
SELECT country, COUNT(*) FROM netflix_titles GROUP BY country ORDER BY COUNT(*) DESC