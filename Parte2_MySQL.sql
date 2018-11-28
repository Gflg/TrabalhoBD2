USE dev;

/*******************************************************************************
   2. Implementar triggers que garantam a validação das regras semânticas criadas
********************************************************************************/

-- Regra da relação tempo/preço (se Milliseconds < 30 mili -> unitPrice = 0)

DROP TRIGGER IF EXISTS min_tempo_pago_insert;
DROP TRIGGER IF EXISTS min_tempo_pago_update;

DELIMITER $$

CREATE TRIGGER min_tempo_pago_insert
BEFORE INSERT ON track
FOR EACH ROW
BEGIN
    IF NEW.Milliseconds < 30000 THEN
		SET NEW.UnitPrice = 0;
	END IF;
END$$

CREATE TRIGGER min_tempo_pago_update
BEFORE UPDATE ON track
FOR EACH ROW
BEGIN
	IF NEW.Milliseconds < 30000 THEN
		SET NEW.UnitPrice = 0;
	END IF;
END$$

DELIMITER ;

INSERT INTO `Track` (`TrackId`, `Name`, `AlbumId`, `MediaTypeId`, `GenreId`, `Composer`, `Milliseconds`, `Bytes`, `UnitPrice`) VALUES (9000, N'Intoitus: Adorate Deum', 272, 2, 24, N'Anonymous', 100, 4123531, 0.99);
UPDATE Track SET UnitPrice = 2 WHERE TrackId = 9000;
SELECT UnitPrice FROM Track WHERE TrackId = 9000;
DELETE FROM Track WHERE TrackId = 9000;

-- Regra de que todo funcionário deve ser maior de idade

DROP TRIGGER IF EXISTS func_maior_idade;

DELIMITER $$

CREATE TRIGGER func_maior_idade
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
	DECLARE anoNasc INT;
    DECLARE mesNasc INT;
    DECLARE diaNasc INT;
    
    DECLARE anoAtual INT;
    DECLARE mesAtual INT;
    DECLARE diaAtual INT;
    
    SET anoNasc = CAST(EXTRACT(YEAR FROM NEW.BirthDate) AS UNSIGNED);
    SET mesNasc = CAST(EXTRACT(MONTH FROM NEW.BirthDate) AS UNSIGNED);
    SET diaNasc = CAST(EXTRACT(DAY FROM NEW.BirthDate) AS UNSIGNED);
    
    SET anoAtual = CAST(EXTRACT(YEAR FROM CURDATE()) AS UNSIGNED);
    SET mesAtual = CAST(EXTRACT(MONTH FROM CURDATE()) AS UNSIGNED);
    SET diaAtual = CAST(EXTRACT(DAY FROM CURDATE()) AS UNSIGNED);
    
    IF anoAtual - anoNasc < 18 THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
    ELSEIF anoAtual - anoNasc = 18 THEN
		IF mesAtual < mesNasc THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
		ELSEIF mesAtual = mesNasc AND diaAtual < diaNasc THEN
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
        END IF;
	END IF;
END$$

DELIMITER ;

INSERT INTO `Employee` (`EmployeeId`, `LastName`, `FirstName`, `Title`, `ReportsTo`, `BirthDate`, `HireDate`, `Address`, `City`, `State`, `Country`, `PostalCode`, `Phone`, `Fax`, `Email`) VALUES (9000, N'Callahan', N'Laura', N'IT Staff', 6, '2001/11/29', '2004/3/4', N'923 7 ST NW', N'Lethbridge', N'AB', N'Canada', N'T1H 1Y8', N'+1 (403) 467-3351', N'+1 (403) 467-8772', N'laura@chinookcorp.com');
SELECT * FROM Employee WHERE EmployeeId = 9000;
DELETE FROM Employee WHERE EmployeeId = 9000;

/*******************************************************************************
   3. Implementar procedimentos armazenados (stored procedures) que garantam a validação das regras semânticas criadas
********************************************************************************/
USE chinook;
CREATE USER 'rubinho'@'localhost' IDENTIFIED BY 'vrum';

DROP PROCEDURE IF EXISTS desc_genero;

DELIMITER $$
CREATE PROCEDURE desc_genero(IN genero_nome VARCHAR(120))
BEGIN
	DECLARE genero_id int;
    DECLARE track_id int;
    DECLARE i int;
    SET i=0;
	SELECT GenreId FROM Genre WHERE genero_nome=genre.name INTO genero_id;
    loop_desconto:
    LOOP
		SELECT TrackId FROM Track WHERE genero_id=GenreId ORDER BY RAND() LIMIT 1 INTO track_id;
        select Name, UnitPrice from track where TrackId=track_id;
        UPDATE Track SET UnitPrice = UnitPrice*0.9 WHERE TrackId=track_id;
        select name, UnitPrice from track where TrackId=track_id;
        SET i = i+1;
        IF i=3 THEN
			LEAVE loop_desconto;
		END IF;
    END LOOP;
END$$
DELIMITER ;

CALL desc_genero('metal');

GRANT EXECUTE ON PROCEDURE mydb.myproc TO 'rubinho'@'somehost';
