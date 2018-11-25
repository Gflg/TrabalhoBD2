USE dev;

/*******************************************************************************
   2. Implementar triggers que garantam a validação das regras semânticas criadas
********************************************************************************/

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

/*******************************************************************************
   3. Implementar procedimentos armazenados (stored procedures) que garantam a validação das regras semânticas criadas
   TODO: tentei fazer uma stored procedure pra ser chamada pelas duas triggers acima mas não funcionou
********************************************************************************/

DROP PROCEDURE IF EXISTS  min_tempo_pago_prc;

DELIMITER $$

CREATE PROCEDURE min_tempo_pago_prc(tempo INT, preco NUMERIC(10,2))
BEGIN
	IF tempo < 30000 THEN
		SET preco = 0;
	END IF;
END$$
DELIMITER ;