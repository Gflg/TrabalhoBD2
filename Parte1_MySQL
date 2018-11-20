/***************************
PARA AUXILIO
****************************/

-- lista todos os índices não únicos
SET @tableName:= 'track';
SELECT table_name AS `Table`,
       index_name AS `Index`,
       GROUP_CONCAT(column_name ORDER BY seq_in_index) AS `Columns`
FROM information_schema.statistics
WHERE NON_UNIQUE = 1 AND table_schema = 'chinook' AND table_name = @tableName
GROUP BY 1,2;


-- add all non-unique indexes , WITHOUT index length spec
SET @tableName:= 'track';
SET SESSION group_concat_max_len=10240;
SELECT CONCAT('ALTER TABLE ', `Table`, ' ADD INDEX ', GROUP_CONCAT(CONCAT(`Index`, '(', `Columns`, ')') SEPARATOR ',\n ADD INDEX ') )
FROM (
SELECT table_name AS `Table`,
       index_name AS `Index`,
        GROUP_CONCAT(column_name ORDER BY seq_in_index) AS `Columns`
FROM information_schema.statistics
WHERE NON_UNIQUE = 1 AND table_schema = 'chinook' AND table_name = @tableName
GROUP BY `Table`, `Index`) AS tmp
GROUP BY `Table`;

ALTER TABLE album ADD INDEX IFK_AlbumArtistId(ArtistId);


/*******************************************************************************
   1. Consulta as tabelas de catálogo e lista todos os índices existentes acompanhados
   das tabelas e colunas indexadas pelo mesmo
********************************************************************************/

SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'chinook';

/*******************************************************************************
   2. TODO 
   Criar um procedimento que remova todos os índices (NAO UNICOS) de uma tabela
   informada como parâmetro
********************************************************************************/

SET @tableName:= 'track';
SET SESSION group_concat_max_len=10240;

SELECT CONCAT('ALTER TABLE ', `Table`, ' DROP INDEX ', GROUP_CONCAT(`Index` SEPARATOR ', DROP INDEX '),';' )
FROM (
SELECT TABLE_NAME AS `Table`,
       INDEX_NAME AS `Index`
FROM INFORMATION_SCHEMA.STATISTICS
WHERE NON_UNIQUE = 1 AND TABLE_SCHEMA = 'chinook' AND TABLE_NAME = @tableName
GROUP BY `Table`, `Index`) AS tmp
GROUP BY `Table`;
-- Vai gerar um registro com o comando que tem que ser executado
-- PORÉM as tabelas possuem chaves primárias e estrangeiras e
-- nao dá pra excluir por causa disso




/*******************************************************************************
   3. Consulta as tabelas de catálogo e lista todas as chaves estrangeiras existentes
   informando tabelas e colunas relacionadas
********************************************************************************/
SELECT 
  TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME, REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME
FROM
  INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE
  REFERENCED_TABLE_SCHEMA = 'chinook';

/*******************************************************************************
   4. TODO
********************************************************************************/

