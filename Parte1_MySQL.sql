
USE chinook;

/*******************************************************************************
   1. Consulta as tabelas de catálogo e lista todos os índices existentes acompanhados
   das tabelas e colunas indexadas pelo mesmo
********************************************************************************/

SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
FROM INFORMATION_SCHEMA.STATISTICS
WHERE TABLE_SCHEMA = 'chinook';

/*******************************************************************************
   2. Cria um procedimento que remova todos os índices (permitidos) de uma tabela
   informada como parâmetro
********************************************************************************/

DROP PROCEDURE IF EXISTS index_del;

DELIMITER $$

CREATE PROCEDURE index_del(IN tableName VARCHAR(150))
/* 
	O procedimento remove todos os indices que não trabalham em colunas referenciadas de outras tabelas (chaves estrangeiras) que não poderiam
	ser deletados sem alteração das outras tabelas em si. 
 
	Para que fosse possível remover todos os indices, seria necessário verificar todas as tabelas que referenciam a tabela passada por parametro,
    e dentro dela remover as chaves estrangeiras, e para remover estas, seria necessário acessar todas as outras tabelas que referenciam esta,
    repetindo o processo recursivamente (eventualmente removendo todas as tabelas no caso do Chinook). Por isso deixamos removendo apenas indices
    que não agem sobre chaves referenciadas. Essa é uma restrição do MYSQL e talvez o procedimento seja mais simples em outros SGBDs.
    
    Ainda assim, no caso do Chinook, não há indices que não fazem referencias a outras tabelas, então o procedimento executa sem alterar nenhuma tabela.
 */

	BEGIN
		DECLARE fimIndex INT DEFAULT FALSE; 
        DECLARE v_index_name VARCHAR(150);
        DECLARE v_table_name VARCHAR(150);
        DECLARE v_column_name VARCHAR(150);
        DECLARE is_referenced INT;
        
        
		DECLARE registroIndex CURSOR FOR  -- retorna todos os indices da tabela
			SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME
			FROM INFORMATION_SCHEMA.STATISTICS
			WHERE TABLE_SCHEMA = 'dev' AND TABLE_NAME = tableName;
			
		
		DECLARE CONTINUE handler 
			FOR NOT found 
				SET fimIndex = TRUE;
		
		OPEN registroIndex;
		DROP_INDEX_LOOP:
			LOOP
				FETCH registroIndex INTO v_table_name, v_index_name, v_column_name;
				
				IF fimIndex THEN
					LEAVE DROP_INDEX_LOOP;
				END IF;
				SELECT COUNT(*) 
					FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
					WHERE REFERENCED_TABLE_SCHEMA = 'dev' and REFERENCED_COLUMN_NAME = v_column_name INTO is_referenced; -- verifica se a coluna pertence a chave estrangeira ou não
                    
				IF v_index_name NOT LIKE 'IFK%' AND is_referenced = 0 THEN
					
					SET @dropIndex = CONCAT("ALTER TABLE ", v_table_name, " DROP INDEX `", v_index_name,"`;");
					
					PREPARE dropStmt FROM @dropIndex;
					EXECUTE dropStmt;
					DEALLOCATE PREPARE dropStmt;
				END IF;
			END LOOP;
		CLOSE registroIndex;

	END $$

DELIMITER 
    
-- Para chamar função
CALL index_del('NOME DA TABELA');

/*******************************************************************************
   3. Consulta as tabelas de catálogo para listar todas as chaves estrangeiras existentes
   informando tabelas e colunas relacionadas
********************************************************************************/
SELECT TABLE_NAME,COLUMN_NAME,CONSTRAINT_NAME, REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
	WHERE REFERENCED_TABLE_SCHEMA = 'chinook';

/*******************************************************************************
   4. Constrói de  forma dinâmica a partir do catálogo os comandos create  table das  tabelas existentes
   no esquema exemplo considerando pelo  menos as  informações sobre
   colunas (nome, tipo e obrigatoriedade) e chaves primárias e estrangeiras.
********************************************************************************/

DROP PROCEDURE IF EXISTS recreate_tables;

DELIMITER $$

CREATE PROCEDURE recreate_tables()

BEGIN
	DECLARE fim INT DEFAULT false;
    DECLARE fim_fk INT DEFAULT false;
	DECLARE tableName VARCHAR(150); 
	DECLARE coluna VARCHAR(150); 
	DECLARE tipo VARCHAR(150);
	DECLARE obrigatorio VARCHAR(150);
	DECLARE tipo_chave VARCHAR(150);
	DECLARE anterior VARCHAR(150);
	DECLARE chaveprimaria VARCHAR(150);
	DECLARE tam INT;
    
	DECLARE registro CURSOR FOR 
		SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_KEY, CHARACTER_MAXIMUM_LENGTH
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_SCHEMA = 'chinook';
	
	DECLARE CONTINUE handler 
	  FOR NOT found 
	  	SET fim = TRUE;
            
    SET anterior = "vazio";
	SET @createTable = "CREATE TABLE ";
    SET chaveprimaria = "CONSTRAINT `PK_";

  open registro; 
	READ_LOOP:
		LOOP
			FETCH registro INTO tableName,coluna,tipo,obrigatorio,tipo_chave, tam;
			SET tableName = CONCAT(tableName," ");
			IF tableName <> anterior AND anterior NOT LIKE "vazio" THEN
				SET @createTable = CONCAT(@createTable, ", ", chaveprimaria, "))");
				PREPARE createStmt FROM @createTable;
				EXECUTE createStmt;
				DEALLOCATE PREPARE createStmt;
				SET @createTable = "CREATE TABLE ";
				SET chaveprimaria = "CONSTRAINT `PK_";
			END IF;
			SET anterior = tableName;
			IF @createTable LIKE "CREATE TABLE " THEN
				SET @createTable = CONCAT(@createTable, tableName, " (");
			ELSE SET @createTable = CONCAT(@createTable, ", ");
			END IF;
			SET @createTable = CONCAT(@createTable, coluna, " ", tipo);
			IF tipo LIKE "VARCHAR" THEN
            			SET @createTable = CONCAT(@createTable, "(", tam, ")");
        		END IF;
			IF obrigatorio LIKE "YES" THEN
				SET @createTable = CONCAT(@createTable, " NOT NULL");
			END IF;
			IF tipo_chave LIKE "PRI" AND chaveprimaria LIKE "CONSTRAINT `PK_" THEN
				SET chaveprimaria = CONCAT(chaveprimaria, tableName, "` PRIMARY KEY  (`", coluna, "`"); 
			ELSEIF tipo_chave LIKE "PRI" THEN
				SET chaveprimaria = CONCAT(chaveprimaria, ", `", coluna, "`");
			END IF;
			IF fim THEN 
			LEAVE read_loop; 
			end IF;  
		end LOOP; 
	close registro;
    
BLOCK2: BEGIN
    
    DECLARE fim2 INT DEFAULT false;
    DECLARE fkColumn VARCHAR(150);
    DECLARE fkConstraintName VARCHAR(150);
	DECLARE fkReferencedTable VARCHAR(150);
    DECLARE fkReferencedColumn VARCHAR(150);
    DECLARE fkTable VARCHAR(150);
    
    DECLARE registroFK CURSOR FOR
		SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME, REFERENCED_TABLE_NAME,REFERENCED_COLUMN_NAME
		FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
		WHERE REFERENCED_TABLE_SCHEMA = 'chinook';

	DECLARE CONTINUE handler 
	  FOR NOT found 
		SET fim2 = TRUE;
            
	SET @alterTable = "ALTER TABLE ";
	SET @createIndex = "CREATE INDEX ";
	  
	open registroFK;
    FK_LOOP:
        LOOP
            FETCH registroFK INTO fkTable,fkColumn,fkConstraintName,fkReferencedTable,fkReferencedColumn;
            IF fim2 THEN 
            LEAVE FK_LOOP; 
            end IF;
            SET @alterTable = CONCAT(@alterTable,"`", fkTable,"` ADD CONSTRAINT `",fkConstraintName,"`");
            SET @alterTable = CONCAT(@alterTable, " FOREIGN KEY (`", fkColumn,"`) REFERENCES `",fkReferencedTable,"` (`");
            SET @alterTable = CONCAT(@alterTable, fkReferencedColumn,"`) ");
            SET @alterTable = CONCAT(@alterTable, "ON DELETE NO ACTION ON UPDATE NO ACTION;\n");
            PREPARE createStmt FROM @alterTable;
            EXECUTE createStmt;
            DEALLOCATE PREPARE createStmt;
            SET @alterTable = "ALTER TABLE ";
            
            SET @createIndex = CONCAT(@createIndex, " `I",fkConstraintName,"` ON `", fkTable,"` (",fkColumn,");");
            PREPARE createStmt FROM @createIndex;
            EXECUTE createStmt;
            DEALLOCATE PREPARE createStmt;
            SET @createIndex = "CREATE INDEX ";
            
            
        END LOOP;
    close registroFK;
    
	SELECT table_name FROM information_schema.tables where table_schema='dev';
	
END BLOCK2;
END$$

DELIMITER ;

-- Para chamar função
CALL recreate_tables();
