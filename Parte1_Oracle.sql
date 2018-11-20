/** Algumas ajudas **/
/** Criar indíce normal **/
CREATE INDEX album_name ON ALBUM(Title)
      TABLESPACE users
      STORAGE (INITIAL 20K
      NEXT 20k
      PCTINCREASE 75);

/** Criar índice único **/
CREATE UNIQUE INDEX album_unique_index ON ALBUM(Title)
      TABLESPACE indx;

/** Listar tabela, coluna, chave estrangeira e owner dado uma tabela pelo usuário **/
SELECT a.table_name, 
       a.column_name, 
       a.constraint_name, 
       c.owner
FROM ALL_CONS_COLUMNS A, ALL_CONSTRAINTS C  
where A.CONSTRAINT_NAME = C.CONSTRAINT_NAME 
  and a.table_name=:TableName 
  and C.CONSTRAINT_TYPE = 'R'

/** Fim da ajuda **/

/**Questão 1 da parte 1**/
select a.index_name "INDEX", 
       a.table_name "TABLE",
       b.column_name "COLUMN"
from all_indexes a, all_ind_columns b
where a.table_name=b.table_name;
/****/

/** Questão 2 da parte 1**/
      
BEGIN
  FOR ind IN 
    (SELECT index_name FROM user_indexes WHERE table_name = :TableName AND index_name NOT IN 
       (SELECT unique index_name FROM user_constraints WHERE 
          table_name = :TableName  AND index_name IS NOT NULL))
  LOOP
      execute immediate 'DROP INDEX '||ind.index_name;
  END LOOP;
END;
/****/

/**Questão 3 da parte 1**/
SELECT a.table_name "TABLE", 
       a.column_name "COLUMN", 
       a.constraint_name "FOREIGN KEY"
  FROM all_cons_columns a
  JOIN all_constraints c ON a.constraint_name = c.constraint_name
  JOIN all_constraints c_pk ON c.r_constraint_name = c_pk.constraint_name
 WHERE c.constraint_type = 'R';
/****/
