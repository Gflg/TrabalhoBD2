USE chinook;

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

DROP TRIGGER IF EXISTS func_maior_idade_insert;
DROP TRIGGER IF EXISTS func_maior_idade_update;

DELIMITER $$

CREATE TRIGGER func_maior_idade_insert
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
	DECLARE anoNasc INT;
    DECLARE mesNasc INT;
    DECLARE diaNasc INT;
    
    DECLARE anoContratacao INT;
    DECLARE mesContratacao INT;
    DECLARE diaContratacao INT;
    
    -- De acordo com o DDL do Chinook este campo pode ser nulo. Resolvemos não mudar a definição do banco, porém sem BirthDate não tem como prosseguir
    IF NEW.BirthDate IS NULL THEN
		SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Informe data de nascimento. Funcionário não pode ter menos de 18 anos';
	END IF;
    
    SET anoNasc = CAST(EXTRACT(YEAR FROM NEW.BirthDate) AS UNSIGNED);
    SET mesNasc = CAST(EXTRACT(MONTH FROM NEW.BirthDate) AS UNSIGNED);
    SET diaNasc = CAST(EXTRACT(DAY FROM NEW.BirthDate) AS UNSIGNED);
    
    IF NEW.HireDate IS NULL THEN
		SET NEW.HireDate = CURDATE();
    END IF;
    
    SET anoContratacao = CAST(EXTRACT(YEAR FROM NEW.HireDate) AS UNSIGNED);
    SET mesContratacao = CAST(EXTRACT(MONTH FROM NEW.HireDate) AS UNSIGNED);
    SET diaContratacao = CAST(EXTRACT(DAY FROM NEW.HireDate) AS UNSIGNED);
    
    IF anoContratacao - anoNasc < 18 THEN
		SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
    ELSEIF anoContratacao - anoNasc = 18 THEN
		IF mesContratacao < mesNasc THEN
			SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
		ELSEIF mesContratacao = mesNasc AND diaContratacao < diaNasc THEN
			SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
        END IF;
	END IF;
END$$

CREATE TRIGGER func_maior_idade_update
BEFORE INSERT ON employee
FOR EACH ROW
BEGIN
	DECLARE anoNasc INT;
    DECLARE mesNasc INT;
    DECLARE diaNasc INT;
    
    DECLARE anoContratacao INT;
    DECLARE mesContratacao INT;
    DECLARE diaContratacao INT;
    
    -- De acordo com o DDL do Chinook este campo pode ser nulo. Resolvemos não mudar a definição do banco, porém sem BirthDate não tem como prosseguir
    IF NEW.BirthDate IS NULL THEN
		SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Informe data de nascimento. Funcionário não pode ter menos de 18 anos';
	END IF;
    
    SET anoNasc = CAST(EXTRACT(YEAR FROM NEW.BirthDate) AS UNSIGNED);
    SET mesNasc = CAST(EXTRACT(MONTH FROM NEW.BirthDate) AS UNSIGNED);
    SET diaNasc = CAST(EXTRACT(DAY FROM NEW.BirthDate) AS UNSIGNED);
    
    IF NEW.HireDate IS NULL THEN
		SET NEW.HireDate = CURDATE();
    END IF;
    
    SET anoContratacao = CAST(EXTRACT(YEAR FROM NEW.HireDate) AS UNSIGNED);
    SET mesContratacao = CAST(EXTRACT(MONTH FROM NEW.HireDate) AS UNSIGNED);
    SET diaContratacao = CAST(EXTRACT(DAY FROM NEW.HireDate) AS UNSIGNED);
    
    IF anoContratacao - anoNasc < 18 THEN
		SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
    ELSEIF anoContratacao - anoNasc = 18 THEN
		IF mesContratacao < mesNasc THEN
			SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
		ELSEIF mesContratacao = mesNasc AND diaContratacao < diaNasc THEN
			SIGNAL SQLSTATE 'ERR0R' SET MESSAGE_TEXT = 'Funcionário não pode ter menos de 18 anos';
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

DROP PROCEDURE IF EXISTS criar_Contratacaoizar_playlist_genero;

DELIMITER $$
CREATE PROCEDURE criar_atualizar_playlist_genero(IN nome_playlist VARCHAR(120), IN genero_nome VARCHAR(120))
BEGIN
    DECLARE genero_id int;
    DECLARE track_id int;
    DECLARE i int;
    DECLARE playlist_id int;
    
    SELECT PlaylistId FROM Playlist WHERE NAME=nome_playlist INTO playlist_id;
    IF playlist_id IS NULL THEN
		SELECT MAX(PlaylistId) FROM Playlist INTO playlist_id;
        SET playlist_id = playlist_id + 1;
		INSERT INTO Playlist (PlaylistId, Name) VALUES (playlist_id, nome_playlist);
    END IF;
	SELECT GenreId FROM Genre WHERE genero_nome=genre.name INTO genero_id;
    SET i=0;
    adicao_track:
    LOOP
		SELECT TrackId FROM Track WHERE genero_id=GenreId ORDER BY RAND() LIMIT 1 INTO track_id;
        IF ( EXISTS (SELECT * FROM PlaylistTrack WHERE PlaylistId = playlist_id AND TrackId = track_id)) THEN
			SELECT TrackId FROM Track WHERE genero_id=GenreId ORDER BY RAND() LIMIT 1 INTO track_id;
            ITERATE adicao_track;
        END IF;
        INSERT INTO PlaylistTrack (PlaylistId, TrackId) VALUES (playlist_id, track_id);
        SET i = i+1;
        IF i=3 THEN
			LEAVE adicao_track;
		END IF;
    END LOOP;
    
END$$

DELIMITER ;

CREATE USER 'corsair'@'localhost' IDENTIFIED BY 'senha';

GRANT SELECT ON chinook.PlaylistTrack TO 'corsair'@'localhost';
GRANT SELECT ON chinook.Playlist TO 'corsair'@'localhost';
GRANT SELECT ON chinook.Track TO 'corsair'@'localhost';
GRANT SELECT ON chinook.Genre TO 'corsair'@'localhost';

GRANT EXECUTE ON PROCEDURE chinook.criar_atualizar_playlist_genero TO 'corsair'@'localhost';

-- Estas últimas linhas servem para auxilio. Copiar e usar ao se conectar como o user
USE chinook;
CALL criar_atualizar_playlist_genero('Minha Playlist', 'Metal');
SELECT * FROM PlaylistTrack NATURAL JOIN Playlist WHERE Playlist.Name='Minha Playlist';