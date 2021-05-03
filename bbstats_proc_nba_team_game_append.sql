CREATE DEFINER=`root`@`localhost` PROCEDURE `proc_nba_team_game_append`()
BEGIN

INSERT INTO `nba_team_game`
	SELECT
		`Team`, `Away`, `Oppo`, `Game_Date`,
		sum(`PTS`),
		(SELECT sum(npg2.`PTS`)
			FROM `nba_player_game` AS npg2
			WHERE npg.`Game_Date`= npg2.`Game_Date` AND npg.`Oppo` = npg2.`Team`),
		`Result`,
		count(`NBA_playerId`),
		NULL,NULL,NULL,
        NULL,NULL,NULL,NULL
    
	FROM `nba_player_game` AS npg
    WHERE npg.`Game_Date` = (`max_date_nba_team_game`() + INTERVAL 1 DAY)
    GROUP BY `Team`, `Away`, `Oppo`, `Game_Date`, `Result`
    ORDER BY `Game_Date` ASC, `Team` ASC;

UPDATE `nba_team_game`
	SET `Team_Game` = if(`Away` = "",
		concat(`Team`,"_",`Game_Date`,"_(",`Oppo`,")"),
		concat(`Team`,"_",`Game_Date`,"_(@",`Oppo`,")")),
        `Game_Name` = if(`Away` = "",
		concat(`Game_Date`,"_",`Oppo`,"@",`Team`),
		concat(`Game_Date`,"_",`Team`,"@",`Oppo`))
	WHERE `Team_Game` IS NULL;

UPDATE `nba_team_game` AS ntg
    LEFT JOIN 
		(SELECT
			a.`team_game_id`,
            COUNT(b.`team_game_id`)+1 AS `team_game_seq`
			FROM `nba_team_game` AS a
				JOIN `nba_team_game` AS b
                ON a.`Team` = b.`Team` 
					AND (a.`Game_Date` > b.`Game_Date` 
					OR (a.`Game_Date` = b.`Game_Date` AND a.`team_game_id` > b.`team_game_id`))
		GROUP BY a.`team_game_id`) AS c
    ON c.`team_game_id` = ntg.`team_game_id`    
SET ntg.`team_game_seq` = c.`team_game_seq`;

UPDATE `nba_team_game`
	SET `team_game_seq` = '1'
    WHERE `team_game_seq` IS NULL;

UPDATE `nba_team_game`
	SET
		`days_gm_before` = NULL,
		`days_gm_after` = NULL,
        `B2B_Day` = NULL;

UPDATE `nba_team_game` AS ntg
	INNER JOIN `nba_team_game` AS ntg2
		ON ntg.`Team` = ntg2.`Team`
        AND ntg.`team_game_seq` = ntg2.`team_game_seq`+ 1
	SET ntg.`days_gm_before` = datediff(ntg.`Game_Date`, ntg2.`Game_Date`);

UPDATE `nba_team_game` AS ntg
	INNER JOIN `nba_team_game` AS ntg2
		ON ntg.`Team` = ntg2.`Team`
        AND ntg.`team_game_seq` = ntg2.`team_game_seq`- 1
	SET ntg.`days_gm_after` = datediff(ntg2.`Game_Date`, ntg.`Game_Date`);

UPDATE `nba_team_game`
	SET `B2B_Day` = 
	CASE
		WHEN `days_gm_before` = 1 THEN "2nd of B2B"
		WHEN `days_gm_after` = 1 THEN "1st of B2B"
		ELSE ""
	END;

SELECT `Game_Name`, count(*)
	FROM `nba_team_game`
	GROUP BY `Game_Name`
	HAVING count(*) > 2
	ORDER BY `Game_Name` DESC;

END