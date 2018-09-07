-- phpMyAdmin SQL Dump
-- version 4.8.1
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Creato il: Ago 03, 2018 alle 18:31
-- Versione del server: 10.1.33-MariaDB
-- Versione PHP: 7.2.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dbOfficina`
--

DELIMITER $$
--
-- Procedure
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `insert_fattura` (IN `interv` INT, IN `imp` FLOAT, IN `ali` FLOAT, IN `tot` FLOAT)  BEGIN
	declare intervento_id int;
    
    declare imponib float;
    declare aliq float;
    declare total float;
    
    set intervento_id=interv;
                       
 		set imponib =imp;
        set aliq=ali;
        set total=tot;
        
        INSERT INTO FATTURA(data_emissione,id_intervento,imponibile,aliquota,totale)
        VALUE(curdate(),intervento_id,imponib,aliq,total);
        
        
    
    END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `AUTOMOBILE`
--

CREATE TABLE `AUTOMOBILE` (
  `targa` varchar(10) NOT NULL,
  `id_cliente` int(11) DEFAULT NULL,
  `marca` varchar(20) DEFAULT NULL,
  `modello` varchar(20) DEFAULT NULL,
  `colore` varchar(20) DEFAULT NULL,
  `km` int(11) DEFAULT NULL,
  `alim` enum('BENZINA','DIESEL','GPL','METANO','IBRIDO','ELETTRICO') NOT NULL DEFAULT 'BENZINA'
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Trigger `AUTOMOBILE`
--
DELIMITER $$
CREATE TRIGGER `upper_targa` BEFORE INSERT ON `AUTOMOBILE` FOR EACH ROW BEGIN
	set new.targa = upper(new.targa);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `CLIENTE`
--

CREATE TABLE `CLIENTE` (
  `id` int(11) NOT NULL,
  `tipo_cliente` enum('PRIVATO','AZIENDA') DEFAULT NULL,
  `c_f` char(16) DEFAULT NULL,
  `p_iva` char(11) DEFAULT NULL,
  `nome` varchar(20) DEFAULT NULL,
  `cognome` varchar(20) DEFAULT NULL,
  `ditta` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Trigger `CLIENTE`
--
DELIMITER $$
CREATE TRIGGER `privato_azienda` AFTER INSERT ON `CLIENTE` FOR EACH ROW BEGIN
	
    IF (NEW.tipo_cliente = 'PRIVATO' and 
       (NEW.p_iva <> '' or NEW.ditta <> '')) then    
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Compilare i campi c_f, nome, cognome';
    else if (New.tipo_cliente = 'AZIENDA' AND
             (NEW.cognome <> '' or NEW.nome <> '')) then
            SIGNAL SQLSTATE '45000' 
        	SET MESSAGE_TEXT = 'Compilare i campi p_iva, ditta';
    end if;
    	
             
    END IF;
    
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `upper_keys` BEFORE INSERT ON `CLIENTE` FOR EACH ROW BEGIN

	IF(new.c_f <> '') THEN
		set new.c_f = upper(new.c_f);
    END IF;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `COMPOSIZIONE`
--

CREATE TABLE `COMPOSIZIONE` (
  `id_intervento` int(11) NOT NULL,
  `id_servizio` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


-- Struttura stand-in per le viste `dettaglio_intervento`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `dettaglio_intervento` (
`n_intervento` int(11)
,`descrizione` varchar(57)
,`costo` double(19,2)
,`stato` varchar(14)
);

-- --------------------------------------------------------

--
-- Struttura della tabella `FATTURA`
--

CREATE TABLE `FATTURA` (
  `id` int(11) NOT NULL,
  `data_emissione` date NOT NULL,
  `id_intervento` int(11) DEFAULT NULL,
  `imponibile` float DEFAULT NULL,
  `aliquota` float DEFAULT NULL,
  `totale` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Struttura stand-in per le viste `fatturazione_intervento`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `fatturazione_intervento` (
`n_intervento` int(11)
,`imponibile` double(19,2)
,`aliquota` double(19,2)
,`totale` double(19,2)
);

-- --------------------------------------------------------

--
-- Struttura della tabella `IMPIEGO_PEZZI`
--

CREATE TABLE `IMPIEGO_PEZZI` (
  `id_intervento` int(11) NOT NULL,
  `id_pezzo` int(11) NOT NULL,
  `qta` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Dump dei dati per la tabella `IMPIEGO_PEZZI`
--

INSERT INTO `IMPIEGO_PEZZI` (`id_intervento`, `id_pezzo`, `qta`) VALUES
(2508, 501, 1),
(2508, 502, 1),
(2511, 502, 1);

--
-- Trigger `IMPIEGO_PEZZI`
--
DELIMITER $$
CREATE TRIGGER `check_disp` BEFORE INSERT ON `IMPIEGO_PEZZI` FOR EACH ROW BEGIN
	declare disp integer;
    declare quant integer;
    declare pz_req integer;
    declare new_qty integer;
    
    set pz_req = new.id_pezzo;
    
    set disp = (SELECT P.disponibilita FROM PEZZI P WHERE P.id=pz_req);
    
    set quant = new.qta;
   	
    if (new.qta < disp and disp > 0) THEN
    	set new_qty = disp-new.qta;
        UPDATE PEZZI set disponibilita = new_qty WHERE id=pz_req;
    else 
    	SIGNAL SQLSTATE '45000'
        set MESSAGE_TEXT = 'pezzi non disponibili';
    end if;
    
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `interventi_giornalieri`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `interventi_giornalieri` (
`n_intervento` int(11)
,`targa_auto` varchar(10)
,`ora_inizio` time
);

-- --------------------------------------------------------

--
-- Struttura della tabella `INTERVENTO`
--

CREATE TABLE `INTERVENTO` (
  `id` int(11) NOT NULL,
  `targa` varchar(10) DEFAULT NULL,
  `stato` enum('IN SVOLGIMENTO','ESPLETATO') DEFAULT NULL,
  `data_inizio` date DEFAULT NULL,
  `ora_inizio` time DEFAULT NULL,
  `data_f` date DEFAULT NULL,
  `ora_f` time DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Trigger `INTERVENTO`
--
DELIMITER $$
CREATE TRIGGER `check_interventi` BEFORE UPDATE ON `INTERVENTO` FOR EACH ROW BEGIN  
    DECLARE interv INT; 
    DECLARE imp FLOAT; 
    DECLARE aliq FLOAT; 
    DECLARE tot FLOAT;
    
     
    IF(new.stato<>old.stato and new.data_f <> '' ) THEN
     
        set interv=old.id;
        set imp=(SELECT f_i.imponibile from fatturazione_intervento f_i where f_i.n_intervento=interv);
        
        set aliq=(SELECT f_i.aliquota from fatturazione_intervento f_i where f_i.n_intervento=interv);
        
        set tot=(SELECT f_i.totale from fatturazione_intervento f_i where f_i.n_intervento=interv);
       
        
        CALL insert_fattura(interv,imp,aliq,tot);
       
        
        
END IF ;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `LAVORI`
--

CREATE TABLE `LAVORI` (
  `id_intervento` int(11) NOT NULL,
  `id_operaio` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Struttura della tabella `LIBRETTO`
--

CREATE TABLE `LIBRETTO` (
  `targa` varchar(10) NOT NULL,
  `n_telaio` char(17) DEFAULT NULL,
  `n_libretto` char(11) DEFAULT NULL,
  `anno_imm` int(11) DEFAULT NULL,
  `kw` float DEFAULT NULL,
  `cilindrata` int(11) DEFAULT NULL,
  `massa_vuoto` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Struttura della tabella `OPERAIO`
--

CREATE TABLE `OPERAIO` (
  `id` int(11) NOT NULL,
  `nome` varchar(20) DEFAULT NULL,
  `cognome` varchar(20) DEFAULT NULL,
  `telefono` char(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Struttura della tabella `PEZZI`
--

CREATE TABLE `PEZZI` (
  `id` int(11) NOT NULL,
  `descrizione` varchar(30) DEFAULT NULL,
  `costo` float DEFAULT NULL,
  `disponibilita` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Trigger `PEZZI`
--
DELIMITER $$
CREATE TRIGGER `quantityisGreater0` AFTER INSERT ON `PEZZI` FOR EACH ROW BEGIN    
    IF (NEW.costo <= 0) then    
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Il prezzo unitario deve essere > 0';
    END IF;
    IF (NEW.disponibilita < 0) then    
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La disponibilità deve essere > 0';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura della tabella `RECAPITI_CLIENTI`
--

CREATE TABLE `RECAPITI_CLIENTI` (
  `id` int(11) NOT NULL,
  `indirizzo` varchar(25) DEFAULT NULL,
  `civico` char(5) DEFAULT NULL,
  `cap` char(5) DEFAULT NULL,
  `citta` varchar(25) DEFAULT NULL,
  `prov` char(2) DEFAULT NULL,
  `tel_fisso` char(10) DEFAULT NULL,
  `cellulare` char(10) DEFAULT NULL,
  `email` varchar(40) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


--
-- Struttura della tabella `SERVIZIO`
--

CREATE TABLE `SERVIZIO` (
  `id` int(11) NOT NULL,
  `descrizione` varchar(35) DEFAULT NULL,
  `costo` float DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

--
-- Trigger `SERVIZIO`
--
DELIMITER $$
CREATE TRIGGER `costoisGreater0` AFTER INSERT ON `SERVIZIO` FOR EACH ROW BEGIN    
    IF (NEW.costo <= 0) then    
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Inserire un valore > 0';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `trova_aliquote`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `trova_aliquote` (
`n_intervento` int(11)
,`aliquota` double(19,2)
);

-- --------------------------------------------------------

--
-- Struttura stand-in per le viste `trova_imponibili`
-- (Vedi sotto per la vista effettiva)
--
CREATE TABLE `trova_imponibili` (
`n_intervento` int(11)
,`imponibile` double(19,2)
);

-- --------------------------------------------------------

--
-- Struttura per vista `dettaglio_intervento`
--
DROP TABLE IF EXISTS `dettaglio_intervento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `dettaglio_intervento`  AS  (select `I`.`id` AS `n_intervento`,`S`.`descrizione` AS `descrizione`,round(`S`.`costo`,2) AS `costo`,`I`.`stato` AS `stato` from ((`INTERVENTO` `I` join `COMPOSIZIONE` `C` on((`I`.`id` = `C`.`id_intervento`))) join `SERVIZIO` `S` on((`C`.`id_servizio` = `S`.`id`)))) union (select `I`.`id` AS `n_intervento`,concat(`P`.`descrizione`,' ',`IP`.`qta`,' * ',`P`.`costo`) AS `descrizione`,round((`IP`.`qta` * `P`.`costo`),2) AS `prezzo`,`I`.`stato` AS `stato` from ((`INTERVENTO` `I` join `IMPIEGO_PEZZI` `IP` on((`I`.`id` = `IP`.`id_intervento`))) join `PEZZI` `P` on((`IP`.`id_pezzo` = `P`.`id`)))) ;

-- --------------------------------------------------------

--
-- Struttura per vista `fatturazione_intervento`
--
DROP TABLE IF EXISTS `fatturazione_intervento`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fatturazione_intervento`  AS  select `ta`.`n_intervento` AS `n_intervento`,round(`ti`.`imponibile`,2) AS `imponibile`,round(`ta`.`aliquota`,2) AS `aliquota`,round((`ti`.`imponibile` + `ta`.`aliquota`),2) AS `totale` from (`trova_aliquote` `ta` join `trova_imponibili` `ti` on((`ta`.`n_intervento` = `ti`.`n_intervento`))) ;

-- --------------------------------------------------------

--
-- Struttura per vista `interventi_giornalieri`
--
DROP TABLE IF EXISTS `interventi_giornalieri`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `interventi_giornalieri`  AS  select `I`.`id` AS `n_intervento`,`I`.`targa` AS `targa_auto`,`I`.`ora_inizio` AS `ora_inizio` from `INTERVENTO` `I` where ((`I`.`data_inizio` = curdate()) and (`I`.`stato` = 'IN SVOLGIMENTO')) ;

-- --------------------------------------------------------

--
-- Struttura per vista `trova_aliquote`
--
DROP TABLE IF EXISTS `trova_aliquote`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `trova_aliquote`  AS  select `di`.`n_intervento` AS `n_intervento`,round((sum(`di`.`costo`) * 0.22),2) AS `aliquota` from `dettaglio_intervento` `di` group by `di`.`n_intervento` ;

-- --------------------------------------------------------

--
-- Struttura per vista `trova_imponibili`
--
DROP TABLE IF EXISTS `trova_imponibili`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `trova_imponibili`  AS  select `di`.`n_intervento` AS `n_intervento`,sum(`di`.`costo`) AS `imponibile` from `dettaglio_intervento` `di` group by `di`.`n_intervento` ;

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `AUTOMOBILE`
--
ALTER TABLE `AUTOMOBILE`
  ADD PRIMARY KEY (`targa`),
  ADD KEY `AUTOMOBILE_ibfk_1` (`id_cliente`);

--
-- Indici per le tabelle `CLIENTE`
--
ALTER TABLE `CLIENTE`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `c_f` (`c_f`),
  ADD UNIQUE KEY `p_iva` (`p_iva`);

--
-- Indici per le tabelle `COMPOSIZIONE`
--
ALTER TABLE `COMPOSIZIONE`
  ADD PRIMARY KEY (`id_intervento`,`id_servizio`),
  ADD KEY `id_servizio` (`id_servizio`);

--
-- Indici per le tabelle `FATTURA`
--
ALTER TABLE `FATTURA`
  ADD PRIMARY KEY (`id`,`data_emissione`),
  ADD KEY `FATTURA_ibfk_1` (`id_intervento`);

--
-- Indici per le tabelle `IMPIEGO_PEZZI`
--
ALTER TABLE `IMPIEGO_PEZZI`
  ADD PRIMARY KEY (`id_intervento`,`id_pezzo`),
  ADD KEY `id_pezzo` (`id_pezzo`);

--
-- Indici per le tabelle `INTERVENTO`
--
ALTER TABLE `INTERVENTO`
  ADD PRIMARY KEY (`id`),
  ADD KEY `targa` (`targa`);

--
-- Indici per le tabelle `LAVORI`
--
ALTER TABLE `LAVORI`
  ADD PRIMARY KEY (`id_intervento`,`id_operaio`),
  ADD KEY `LAVORI_ibfk_2` (`id_operaio`);

--
-- Indici per le tabelle `LIBRETTO`
--
ALTER TABLE `LIBRETTO`
  ADD PRIMARY KEY (`targa`),
  ADD UNIQUE KEY `n_telaio` (`n_telaio`),
  ADD UNIQUE KEY `n_libretto` (`n_libretto`);

--
-- Indici per le tabelle `OPERAIO`
--
ALTER TABLE `OPERAIO`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `telefono` (`telefono`);

--
-- Indici per le tabelle `PEZZI`
--
ALTER TABLE `PEZZI`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `descrizione` (`descrizione`);

--
-- Indici per le tabelle `RECAPITI_CLIENTI`
--
ALTER TABLE `RECAPITI_CLIENTI`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `tel_fisso` (`tel_fisso`),
  ADD UNIQUE KEY `cellulare` (`cellulare`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indici per le tabelle `SERVIZIO`
--
ALTER TABLE `SERVIZIO`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT per le tabelle scaricate
--

--
-- AUTO_INCREMENT per la tabella `CLIENTE`
--
ALTER TABLE `CLIENTE`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT per la tabella `FATTURA`
--
ALTER TABLE `FATTURA`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT per la tabella `INTERVENTO`
--
ALTER TABLE `INTERVENTO`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2512;

--
-- AUTO_INCREMENT per la tabella `OPERAIO`
--
ALTER TABLE `OPERAIO`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=26;

--
-- AUTO_INCREMENT per la tabella `PEZZI`
--
ALTER TABLE `PEZZI`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=504;

--
-- AUTO_INCREMENT per la tabella `SERVIZIO`
--
ALTER TABLE `SERVIZIO`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=107;

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `AUTOMOBILE`
--
ALTER TABLE `AUTOMOBILE`
  ADD CONSTRAINT `AUTOMOBILE_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `CLIENTE` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `COMPOSIZIONE`
--
ALTER TABLE `COMPOSIZIONE`
  ADD CONSTRAINT `COMPOSIZIONE_ibfk_1` FOREIGN KEY (`id_intervento`) REFERENCES `INTERVENTO` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `COMPOSIZIONE_ibfk_2` FOREIGN KEY (`id_servizio`) REFERENCES `SERVIZIO` (`id`);

--
-- Limiti per la tabella `FATTURA`
--
ALTER TABLE `FATTURA`
  ADD CONSTRAINT `FATTURA_ibfk_1` FOREIGN KEY (`id_intervento`) REFERENCES `INTERVENTO` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `IMPIEGO_PEZZI`
--
ALTER TABLE `IMPIEGO_PEZZI`
  ADD CONSTRAINT `IMPIEGO_PEZZI_ibfk_1` FOREIGN KEY (`id_intervento`) REFERENCES `INTERVENTO` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `IMPIEGO_PEZZI_ibfk_2` FOREIGN KEY (`id_pezzo`) REFERENCES `PEZZI` (`id`);

--
-- Limiti per la tabella `INTERVENTO`
--
ALTER TABLE `INTERVENTO`
  ADD CONSTRAINT `INTERVENTO_ibfk_1` FOREIGN KEY (`targa`) REFERENCES `AUTOMOBILE` (`targa`);

--
-- Limiti per la tabella `LAVORI`
--
ALTER TABLE `LAVORI`
  ADD CONSTRAINT `LAVORI_ibfk_1` FOREIGN KEY (`id_intervento`) REFERENCES `INTERVENTO` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `LAVORI_ibfk_2` FOREIGN KEY (`id_operaio`) REFERENCES `OPERAIO` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Limiti per la tabella `LIBRETTO`
--
ALTER TABLE `LIBRETTO`
  ADD CONSTRAINT `LIBRETTO_ibfk_1` FOREIGN KEY (`targa`) REFERENCES `AUTOMOBILE` (`targa`);

--
-- Limiti per la tabella `RECAPITI_CLIENTI`
--
ALTER TABLE `RECAPITI_CLIENTI`
  ADD CONSTRAINT `RECAPITI_CLIENTI_ibfk_1` FOREIGN KEY (`id`) REFERENCES `CLIENTE` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
