--First page
--1). What range of years for baseball games played does the provided database cover? 1871-2016
SELECT min(yearid) AS first_year, max(yearid) AS latest_year
FROM teams;

--2). Find the name and height of the shortest player in the database. Eddie Gaedel at 43 inches (3.53 feet)
--How many games did he play in? What is the name of the team for which he played: One game for the St. Louis Browns

SELECT SUM(po) AS total_putouts,
	CASE
		WHEN pos = 'OF' THEN 'Outfield'
		WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
		WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B' THEN 'Infield'
				ELSE 'Not playing' END AS Position
FROM fielding
WHERE yearid = 2016
GROUP BY position;


--3).Find all players in the database who played at Vanderbilt University.
-----Create a list showing each player’s first and last names as well as 
-----the total salary they earned in the major leagues.  Sort this list 
-----in descending order by the total salary earned. Which Vanderbilt player 
-----earned the most money in the majors?  David Price

SELECT DISTINCT playerid, schoolid, namelast, namefirst, SUM(salary::numeric::money) AS total_salary
FROM collegeplaying
LEFT JOIN people
USING(playerid)
INNER JOIN salaries
USING (playerid)
WHERE schoolid = 'vandy'
GROUP BY playerid, schoolid, namelast, namefirst
ORDER BY total_salary desc;

--4. Using the fielding table, group players into three groups
---based on their position: label players with position OF as "Outfield",
---those with position "SS", "1B", "2B", and "3B" as "Infield", and
---those with position "P" or "C" as "Battery". Determine the number 
---of putouts made by each of these three groups in 2016.

SELECT playerid, 
      CASE WHEN pos = 'SS' OR pos = '1B' OR pos = '2B' OR pos = '3B'  THEN 'Infield' 
	  	   WHEN pos = 'OF' THEN 'Outfield'
		   WHEN pos = 'P' OR pos = 'C' THEN 'Battery'
		   ELSE 'missing' END AS positions
FROM fielding;

--5). Find the average number of strikeouts per game by decade since 1920. 
----Round the numbers you report to 2 decimal places. Do the same for home runs per game. Do you see any trends?
--they seem to be inversely related as strikeouts increased homeruns decreased overall.
   
SELECT p.yearid/10*10 AS decade, ROUND(AVG(p.so),2) AS strikeout_average, ROUND(AVG(b.hr*b.g),2) AS homeruns_average
FROM people
INNER JOIN pitching AS p USING (playerid)
INNER JOIN batting AS b USING (playerid)
WHERE p.yearid >= 1920 AND b.yearid >=1920
GROUP BY decade
ORDER BY decade;

SELECT (p.yearid/10)*10 AS decades, ROUND(AVG(p.so),2) as Avg_SO, ROUND(AVG(b.hr),2)*100 AS Avg_HR
FROM pitching AS p
INNER JOIN batting AS b USING (playerid)
WHERE p.yearid between 1920 and 2016
GROUP BY decades
ORDER BY decades;



--QUESTION #6: Find the player who had the most success stealing bases in 2016, where __success__ is measured as the percentage of stolen base attempts which are successful.
--(A stolen base attempt results either in a stolen base or being caught stealing.) Consider only players who attempted _at least_ 20 stolen bases.

SELECT namefirst, namelast, sb, cs,yearid,
		CASE WHEN sb+cs = 0 THEN 0
			ELSE ROUND((sb::decimal/(sb+cs)*100),2)
				END AS sb_success_rate
FROM people
INNER JOIN Batting
USING(playerid)
WHERE yearid = 2016 AND (sb+cs) >= 20
ORDER BY sb_success_rate DESC
LIMIT 10;

--7).From 1970 – 2016, what is the largest number of wins for a team that did not 
--win the world series? What is the smallest number of wins for a team that did win 
--the world series? Doing this will probably result in an unusually small number of 
--wins for a world series champion – determine why this is the case. Then redo your 
--query, excluding the problem year. How often from 1970 – 2016 was it the case that
--a team with the most wins also won the world series? What percentage of the time?
--ANSWER: least wins LA Dodgers at 63, Most wins Seatle Mariners: The low total of 
--least wins including a world sereis was most likely due to a baseball strike occuring
--in 1981, which changes the result to St Louis Cardinals at 83 wins. 25% of the time, did a team 
--win both the series and have the most wins.

SELECT yearid, name, w, WSwin
FROM teams;

SELECT name, yearid, MAX(w) AS most_wins
FROM teams
WHERE yearid between 1970 and 2016 AND WSwin = 'N'
GROUP BY yearid, name
ORDER BY max(w)DESC
Limit 1;

SELECT COUNT(yearid) AS year, yearid, name, MIN(w) AS least_wins
FROM teams
WHERE yearid between 1970 and 2016 AND wswin = 'Y' 
GROUP BY yearid, name
ORDER BY least_wins;

SELECT COUNT(yearid) AS year, yearid, name, MIN(w) AS least_wins
FROM teams
WHERE yearid between 1970 and 2016 AND wswin = 'Y' AND yearid <> '1981'
GROUP BY yearid, name
ORDER BY least_wins;
--Part B)
WITH world_series_winners AS
	(SELECT yearid, name, MAX(w) AS wins
	FROM teams
	WHERE yearid BETWEEN 1970 AND 2016 AND wswin ='Y'
	GROUP BY yearid, name),
most_wins AS (SELECT yearid, MAX(w) AS max_wins
				FROM teams
				GROUP BY yearid),
-- SELECT *
-- FROM world_series_winners
-- INNER JOIN most_wins
-- 	USING (yearid)
max_world_series_winners AS (SELECT wsw.yearid
    				FROM world_series_winners wsw
    				INNER JOIN most_wins mw
   							 ON wsw.yearid = mw.yearid
    							AND wsw.wins = mw.max_wins)
SELECT (COUNT(max_world_series_winners.yearid) * 100/ (SELECT COUNT(DISTINCT yearid)
														FROM teams WHERE yearid BETWEEN 1970 AND 2016)) AS percentage
FROM max_world_series_winners;


--8).Using the attendance figures from the homegames table, 
--find the teams and parks which had the top 5 average attendance 
--per game in 2016 (where average attendance is defined as total 
--attendance divided by number of games). Only consider parks where 
--there were at least 10 games played. Report the park name, team
--name, and average attendance. Repeat for the lowest 5 average attendance.

SELECT park_name,name AS team_name,(h.attendance/h.games) AS avg_attendance
FROM homegames AS h
INNER JOIN parks AS p USING(park)
INNER JOIN teams AS t ON t.teamid = h.team
WHERE games >=10 AND year = 2016
GROUP BY park_name,name,avg_attendance
ORDER BY avg_attendance DESC
LIMIT 5;
--LOWEST 5
SELECT park_name,name AS team_name,(h.attendance/h.games) AS avg_attendance
FROM homegames AS h
INNER JOIN parks AS p USING(park)
INNER JOIN teams AS t ON t.teamid = h.team
WHERE games >=10 AND year = 2016
GROUP BY park_name,name,avg_attendance
ORDER BY avg_attendance ASC
LIMIT 5;

--9).Which managers have won the TSN Manager of the Year award in both the National League (NL)
---and the American League (AL)? Give their full name and the teams that they were managing when they won the award.

SELECT playerid, namefirst, namelast, teams.name AS team_name
FROM awardsmanagers
INNER JOIN people
	USING(playerid)
INNER JOIN teams
		ON awardsmanagers.yearid = teams.yearid
WHERE awardid = 'TSN Manager of the Year'
			AND awardsmanagers.lgid IN ('AL','NL')
GROUP BY playerid, namefirst, namelast, team_name
HAVING COUNT(DISTINCT awardsmanagers.lgid) = 2;

--Q10). Find all players who hit their career highest number of home runs in 2016. 
--Consider only players who have played in the league for at least 10 years, and who 
--hit at least one home run in 2016. Report the players' first and last names and the number of home runs they hit in 2016.  
WITH ten_year_players AS (SELECT namefirst, namelast, yearid, hr,debut,finalgame
FROM people AS p
INNER JOIN batting AS b USING(playerid)
WHERE EXTRACT(day from finalgame::timestamp - debut::timestamp) >=3650)
SELECT namefirst, namelast, yearid, MAX(hr) AS career_highest
FROM ten_year_players
WHERE yearid = 2016 and hr>=1
GROUP BY namefirst,namelast,yearid,debut,finalgame;



--11).






--12).




--13)It is thought that since left-handed pitchers are more rare,
--causing batters to face them less often, that they are more effective.
--Investigate this claim and present evidence to either support or dispute the claim.
--First, determine just how rare left-handed pitchers are compared with right-handed pitchers: 28% less common
--Are left-handed pitchers more likely to win the Cy Young Award?
--Are they more likely to make it into the hall of fame?


SELECT 
		(CAST(SUM(CASE WHEN  throws = 'L' THEN 1 ELSE 0 END) AS FLOAT)/CAST(COUNT(*) AS FLOAT))*100
		AS left_percent
FROM people
INNER JOIN pitching
USING(playerid);
--


WITH L_hand_throwers AS (SELECT playerid, awardid, yearid,
 CAST(SUM(CASE WHEN throws = 'L' THEN 1 ELSE 0 END) AS FLOAT) AS L_thrower,
 CAST(SUM(CASE WHEN throws = 'R' THEN 1 ELSE 0 END) AS FLOAT) AS R_thrower
FROM people
LEFT JOIN awardsplayers
USING(playerid)
WHERE awardid ILIKE '%cy young%'
GROUP BY playerid, awardid,yearid
ORDER BY yearid DESC)


	SELECT COUNT(l_thrower), (l_thrower::decimal = '1')/COUNT(R_thrower::decimal)*100 AS L_hand_percentage
	FROM L_hand_throwers;
----
--Above last calculation not working to get %
--Next query to study from and find the thought process 
----
SELECT COUNT(CASE WHEN throws = 'R' THEN 'right' END) as throws_right,
				COUNT(CASE WHEN throws = 'L' THEN 'left' END) as throws_left,
				ROUND((COUNT(CASE WHEN throws = 'L' THEN 'left' END)::numeric/COUNT(*))*100,2) as percent_left
FROM people;
SELECT COUNT(CASE WHEN throws = 'R' THEN 'right' END) as throws_right,
				COUNT(CASE WHEN throws = 'L' THEN 'left' END) as throws_left,
				ROUND((COUNT(CASE WHEN throws = 'L' THEN 'left' END)::numeric/COUNT(*))*100,2) as percent_left
FROM people
INNER JOIN awardsplayers
USING(playerid)
WHERE awardid = 'Cy Young Award';

---
SELECT * FROM people
     WHERE throws='R'
--Right handed pitchers 14480
SELECT * FROM people
     WHERE throws='L'
--Left handed pitchers are 3654. Yes, they are rare.
--Total Cy young awards are 112
--left pitchers who received the Cy Young award: 37
--Halloffame 786 L out of 4156
-- right 75 --3335
--Left handed pitchers are more likely to receive cy  young awards but thats not the same case for halloffame.
--Halloffame may have more Right handed pitchers as overall their participation is also higher.














