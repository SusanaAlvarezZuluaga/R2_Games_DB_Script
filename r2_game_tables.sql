use NETA;

-- ------------------------------------------------------- ------------------------------------------------------- -----------------------------------------------------
-- -- -----------------------------------------------------CREATE COLUMNS-- -----------------------------------------------------
-- ------------------------------------------------------- ------------------------------------------------------- -----------------------------------------------------
-- -----------------------------------------------------
-- Table `game_type`
-- -----------------------------------------------------
CREATE TABLE `NETA`.`game_type` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Name` VARCHAR(50) NOT NULL,
  PRIMARY KEY (`Id`));
  
  
-- -----------------------------------------------------
-- Table `game_prize`
-- -----------------------------------------------------
DROP table game_prize;
CREATE TABLE `NETA`.`game_prize` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `Type` VARCHAR(30) NOT NULL,
  `ImageURL` VARCHAR(500) NOT NULL,
  `Amount` INT,
  `ProductId` INT,
  `Probability` FLOAT(3,2) NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT CHK_valid_probability_ CHECK (`Probability`>=0 AND `Probability`<=1),
  CONSTRAINT `Game_Prize_product_Id_Fk`
    FOREIGN KEY (`ProductId`)
    REFERENCES `NETA`.`product` (`Id`)
);
-- -----------------------------------------------------
-- Table `game_configuration`
-- -----------------------------------------------------
CREATE TABLE `NETA`.`game_configuration` 
(
  `Id` INT NOT NULL AUTO_INCREMENT,
  `TypeId` INT NOT NULL,
  `TicketCost` INT NOT NULL,
  `Description` VARCHAR(100) NOT NULL,
  `NumberOfPrizes` INT NOT NULL,
  `PrizeList` VARCHAR(100) NOT NULL,
  `StartDateUTC` DATETIME NOT NULL,
  `EndDateUTC` DATETIME NOT NULL,
  `CanPlayStartTimeUTC` TIME NOT NULL,
  `CanPlayEndTimeUTC` TIME NOT NULL,
  `CreatedOnUTC` DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `IsActive` TINYINT(1) NOT NULL,
  CONSTRAINT CHK_is_active CHECK (`isActive`=0 OR `isActive`=1),
  CONSTRAINT CHK_Correct_Dates CHECK (`StartDateUTC`<`EndDateUTC`),
  PRIMARY KEY (`Id`),
  CONSTRAINT `Type_Id_Fk`
    FOREIGN KEY (`TypeId`)
    REFERENCES `NETA`.`game_type` (`Id`)
);

-- -----------------------------------------------------
-- Table `winner_game`
-- -----------------------------------------------------
CREATE TABLE `NETA`.`winner_game` 
(
  `Id` INT NOT NULL AUTO_INCREMENT,
  `CreatedOnUTC` DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `GameId` INT NOT NULL,
  `PrizeId` INT NOT NULL,
  `CustomerId` INT NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT `Game_Id_Fk`
    FOREIGN KEY (`GameId`)
    REFERENCES `NETA`.`game_configuration` (`Id`),
  CONSTRAINT `Prize_Id_Fk`
    FOREIGN KEY (`PrizeId`)
    REFERENCES `NETA`.`game_prize` (`Id`),
  CONSTRAINT `Customer_Id_Fk`
    FOREIGN KEY (`CustomerId`)
    REFERENCES `NETA`.`customer` (`Id`)
);


-- -----------------------------------------------------
-- Table `ledger_customer_neta_tickets`
-- -----------------------------------------------------
CREATE TABLE `NETA`.`ledger_customer_neta_tickets` (
  `Id` INT NOT NULL AUTO_INCREMENT,
  `CustomerId` INT NOT NULL,
  `PreviousBalance` INT NOT NULL,
  `NewBalance` INT NOT NULL,
  `MovementTypeId` INT NOT NULL,
  `MovementAmount` INT NOT NULL,
  `MovementDescription` VARCHAR(500) NOT NULL,
  `CreatedOnUTC` DATETIME NOT NULL DEFAULT (CURRENT_TIMESTAMP),
  `MovementDescriptionForEU` VARCHAR(100) NOT NULL,
  PRIMARY KEY (`Id`),
  CONSTRAINT CHK_MovementAmount_Is_Positive CHECK (`MovementAmount`>=0),
   CONSTRAINT `Customer_Id_Ledger_Fk`
    FOREIGN KEY (`CustomerId`)
    REFERENCES `NETA`.`customer` (`Id`)
);

-- ------------------------------------------------------- ------------------------------------------------------- -----------------------------------------------------
-- -- -----------------------------------------------------MODIFY EXISTING TABLES-- -----------------------------------------------------
-- ------------------------------------------------------- ------------------------------------------------------- -----------------------------------------------------


ALTER TABLE customer
ADD CustomerCurrentNetaTickets INT DEFAULT 0;
-- ------------------------------------------------------- ------------------------------------------------------- -----------------------------------------------------
-- -- -----------------------------------------------------CREATE TABLE TRIGGERS-- -----------------------------------------------------
-- ------------------------------------------------------- ------------------------------------------------------- -----------------------------------------------------
DROP TRIGGER checkProbabiltyAndNumberOfPrizesInsert

delimiter $$
CREATE TRIGGER checkProbabiltyAndNumberOfPrizesInsert  BEFORE INSERT  
ON NETA.game_configuration FOR EACH ROW  
BEGIN  
	DECLARE prizeId VARCHAR(100);
    DECLARE numberOfPrizes INT;
    DECLARE probabilitySum FLOAT(3,2);
	DECLARE prizeProbability FLOAT(3,2);
    DECLARE commaIndex INT;
    DECLARE PrizeList VARCHAR(100);
    SET PrizeList=NEW.PrizeList;
    SET probabilitySum=0;
	SET numberOfPrizes = LENGTH(PrizeList)-LENGTH(REPLACE(PrizeList, ',', ''))+1;
    IF numberOfPrizes!=NEW.NumberOfPrizes THEN 
		signal sqlstate '45000' set message_text = "The number of prizes defined doesn't match the length of PrizeList";
	END IF;
    iterator: 
    WHILE LOCATE(',', PrizeList)>0 DO
        SET commaIndex=LOCATE(',', PrizeList);
		SET prizeId=SUBSTR(PrizeList,1,commaIndex-1);
        SET PrizeList=SUBSTR(PrizeList,commaIndex+1);
        SELECT Probability INTO prizeProbability FROM game_prize WHERE Id=prizeId;
        IF ISNULL(prizeProbability)THEN 
			signal sqlstate '45000' set message_text = "There is no game_prize with one of the ids specified in a the list";
		END IF;
        SET probabilitySum=probabilitySum+prizeProbability;
	END
	WHILE iterator;
    SELECT Probability INTO prizeProbability FROM game_prize WHERE Id=PrizeList;
	SET probabilitySum=probabilitySum+prizeProbability;
    IF probabilitySum!=1.00 THEN
		signal sqlstate '45000' set message_text = "Probabilities don't sum up to one";
	END IF;
END
$$
delimiter ;

DROP TRIGGER checkProbabiltyAndNumberOfPrizesUpdate
delimiter |
CREATE TRIGGER checkProbabiltyAndNumberOfPrizesUpdate BEFORE UPDATE  
ON NETA.game_configuration FOR EACH ROW  
BEGIN  
	DECLARE prizeId VARCHAR(100);
    DECLARE numberOfPrizes INT;
    DECLARE probabilitySum FLOAT(3,2);
	DECLARE prizeProbability FLOAT(3,2);
    DECLARE commaIndex INT;
    DECLARE PrizeList VARCHAR(100);
    SET PrizeList=NEW.PrizeList;
    SET probabilitySum=0;
	SET numberOfPrizes = LENGTH(PrizeList)-LENGTH(REPLACE(PrizeList, ',', ''))+1;
    IF numberOfPrizes!=NEW.NumberOfPrizes THEN 
		signal sqlstate '45000' set message_text = "The number of prizes defined doesn't match the length of PrizeList";
	END IF;
    iterator: 
    WHILE LOCATE(',', PrizeList)>0 DO
        SET commaIndex=LOCATE(',', PrizeList);
		SET prizeId=SUBSTR(PrizeList,1,commaIndex-1);
        SET PrizeList=SUBSTR(PrizeList,commaIndex+1);
        SELECT Probability INTO prizeProbability FROM game_prize WHERE Id=prizeId;
        IF ISNULL(prizeProbability)THEN 
			signal sqlstate '45000' set message_text = "There is no game_prize with one of the ids specified in a the list";
		END IF;
        SET probabilitySum=probabilitySum+prizeProbability;
	END
	WHILE iterator;
    SELECT Probability INTO prizeProbability FROM game_prize WHERE Id=PrizeList;
	SET probabilitySum=probabilitySum+prizeProbability;
    IF probabilitySum!=1.00 THEN
		signal sqlstate '45000' set message_text = "Probabilities don't sum up to one";
	END IF;
END
|
delimiter ;


