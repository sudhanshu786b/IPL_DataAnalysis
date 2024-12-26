use ipl;
select * from Ball_by_Ball;
select * from Batsman_Scored;
select * from Batting_Style;
select * from Bowling_Style;
select * from Extra_Runs;
select * from Player;
select * from Team;
select * from Matches;
select * from Season;
select * from Player_Match;
select * from Wicket_Taken;
select * from Toss_Decision;

-- Show all the data types & column names
describe Ball_by_Ball;

-- query for total runs scored in season 1 with extra runs
select 
    sum(coalesce(bs.runs_scored, 0) + coalesce(er.extra_runs, 0)) as total_runs_scored
from 
    matches m
join 
    team t on (m.team_1 = t.team_id or m.team_2 = t.team_id) 
             and t.team_name = 'royal challengers bangalore'
join 
    season s on m.season_id = s.season_id
join 
    ball_by_ball b on m.match_id = b.match_id
left join 
    batsman_scored bs on b.match_id = bs.match_id 
                        and b.over_id = bs.over_id 
                        and b.ball_id = bs.ball_id
                        and b.innings_no = bs.innings_no
left join 
    extra_runs er on b.match_id = er.match_id 
                    and b.over_id = er.over_id
                    and b.ball_id = er.ball_id
                    and b.innings_no = er.innings_no
where
    b.team_batting = t.team_id 
    and s.season_year = 2008;    
    
    
-- Number of players over age 25 in season 2
select count(distinct p.player_id) as players_over_25
from player p
join player_match pm on p.player_id = pm.player_id
join matches m on pm.match_id = m.match_id
join season s on m.season_id = s.season_id
where s.season_year = 2009 
  and datediff(m.match_date, p.dob) / 365.25 > 25;

-- Players name according to average runs scored
select 
    p.player_name, 
    avg(bs.runs_scored) as average_runs_scored
from 
    batsman_scored bs
join 
    ball_by_ball b on bs.match_id = b.match_id 
                    and bs.over_id = b.over_id 
                    and bs.ball_id = b.ball_id
                    and bs.innings_no = b.innings_no
join 
    player p on b.striker = p.player_id
group by 
    p.player_name;
    
    

-- Players name according to strike rates
select 
    p.player_name,
    sum(bs.runs_scored) / count(case when bs.runs_scored >= 0 then 1 end) * 100 as strike_rate
from 
    batsman_scored bs
join 
    ball_by_ball b on bs.match_id = b.match_id 
                    and bs.over_id = b.over_id 
                    and bs.ball_id = b.ball_id
                    and bs.innings_no = b.innings_no
join 
    player p on b.striker = p.player_id
join 
    matches m on bs.match_id = m.match_id
join
    season s on m.season_id = s.season_id
where 
    s.season_year >= (select max(season_year) from season) - 3  
group by 
    p.player_name
having 
    count(case when bs.runs_scored >= 0 then 1 end) >= 200 
order by 
    strike_rate desc
limit 10;


-- RCB win the matches in season 1
select count(*) as rcb_wins_season_1
from matches m
join team t1 on m.team_1 = t1.team_id
join team t2 on m.team_2 = t2.team_id
join season s on m.season_id = s.season_id
where (t1.team_name = 'royal challengers bangalore' or t2.team_name = 'royal challengers bangalore') 
  and m.match_winner = (case 
                        when t1.team_name = 'royal challengers bangalore' then t1.team_id
                        else t2.team_id
                        end)
  and s.season_year = 2008; 
  

-- Players name according to average wickets taken
select 
    p.player_name,
    count(*) / count(distinct b.match_id) as average_wickets_taken 
from 
    wicket_taken wt
join 
    ball_by_ball b on wt.match_id = b.match_id 
                    and wt.over_id = b.over_id 
                    and wt.ball_id = b.ball_id 
                    and wt.innings_no = b.innings_no
join 
    player p on b.bowler = p.player_id
group by
    p.player_name;
    

-- create rcb_record table shows wins and losses of RCB in an individual venue
create table rcb_record as
select 
    v.venue_name,
    sum(case when m.match_winner = t.team_id then 1 else 0 end) as wins,
    sum(case when m.match_winner != t.team_id and m.outcome_type = 1 then 1 else 0 end) as losses 
from 
    matches m
join 
    team t on (m.team_1 = t.team_id or m.team_2 = t.team_id) and t.team_name = 'royal challengers bangalore'
join
    venue v on m.venue_id = v.venue_id
where 
    m.outcome_type in (1, 2) 
group by 
    v.venue_name;
    
select * from rcb_record;    


-- impact of bowling style on wicket taken
select 
    bs.bowling_skill,
    count(*) as total_wickets,
    count(distinct b.match_id) as total_matches,
    count(*) / count(distinct b.match_id) as avg_wickets_per_match
from 
    wicket_taken wt
join 
    ball_by_ball b on wt.match_id = b.match_id 
                    and wt.over_id = b.over_id 
                    and wt.ball_id = b.ball_id 
                    and wt.innings_no = b.innings_no
join 
    player p on b.bowler = p.player_id
join 
    bowling_style bs on p.bowling_skill = bs.bowling_id
group by 
    bs.bowling_skill;
    

--  find out average wickets taken by each bowler in each venue. Also rank the gender according to the average value ?
select
    p.player_name,
    v.venue_name,
    count(*) / count(distinct b.match_id) as avg_wickets_taken,
    dense_rank() over (order by count(*) / count(distinct b.match_id) desc) as rnk
from
    wicket_taken wt
join
    ball_by_ball b on wt.match_id = b.match_id
                    and wt.over_id = b.over_id
                    and wt.ball_id = b.ball_id
                    and wt.innings_no = b.innings_no
join
    player p on b.bowler = p.player_id
join 
    matches m on b.match_id = m.match_id
join
    venue v on m.venue_id = v.venue_id
group by
    p.player_name, v.venue_name
order by
    avg_wickets_taken desc;

-- overall average runs scored per batsman
select avg(runs_per_batsman) as overall_average_runs_scored
from (
    select 
        b.striker,
        sum(bs.runs_scored) / count(case when bs.runs_scored >= 0 then 1 end) as runs_per_batsman
    from 
        batsman_scored bs
    join 
        ball_by_ball b on bs.match_id = b.match_id 
                        and bs.over_id = b.over_id 
                        and bs.ball_id = b.ball_id
                        and bs.innings_no = b.innings_no
    group by 
        b.striker
) as subquery;


-- overall average wicket taken per bowler
select avg(wickets_per_bowler) as overall_average_wicken_taken
from (
    select 
        b.bowler,
        count(*) / count(distinct b.match_id) as wickets_per_bowler
    from 
        wicket_taken wt
    join 
        ball_by_ball b on wt.match_id = b.match_id 
                        and wt.over_id = b.over_id 
                        and wt.ball_id = b.ball_id 
                        and wt.innings_no = b.innings_no
    group by
        b.bowler
) as subquery;






    
-- players name according to their batting performance by venue
select
    p.player_name,
    v.venue_name,
    sum(bs.runs_scored) / count(case when bs.runs_scored >= 0 then 1 end) as batting_average,
    (sum(bs.runs_scored) / count(case when bs.runs_scored >= 0 then 1 end)) * 100 as strike_rate
from
    batsman_scored bs
join
    ball_by_ball b on bs.match_id = b.match_id and bs.over_id = b.over_id and bs.ball_id = b.ball_id and bs.innings_no = b.innings_no
join
    player p on b.striker = p.player_id
join
    matches m on b.match_id = m.match_id
join
    venue v on m.venue_id = v.venue_id
group by
    p.player_name, v.venue_name;


-- -- players name according to their bowling performance by venue
select 
    p.player_name,
    v.venue_name,
    count(*) / count(distinct b.match_id) as bowling_average,
    sum(coalesce(bs.runs_scored, 0)) / count(b.over_id) as economy_rate 
from 
    wicket_taken wt
join 
    ball_by_ball b on wt.match_id = b.match_id 
                    and wt.over_id = b.over_id 
                    and wt.ball_id = b.ball_id 
                    and wt.innings_no = b.innings_no
join 
    player p on b.bowler = p.player_id
join 
    matches m on b.match_id = m.match_id
join
    venue v on m.venue_id = v.venue_id
left join 
    batsman_scored bs on b.match_id = bs.match_id 
                        and b.over_id = bs.over_id 
                        and b.ball_id = bs.ball_id
                        and b.innings_no = bs.innings_no
group by
    p.player_name, v.venue_name
order by
    bowling_average desc;
    
-- impact of toss decision on match
select 
    td.toss_name,
    count(*) as total_matches,
    sum(case when m.toss_winner = m.match_winner then 1 else 0 end) as toss_winner_wins,
    (sum(case when m.toss_winner = m.match_winner then 1 else 0 end) / count(*)) * 100 as toss_win_percentage
from 
    matches m
join 
    toss_decision td on m.toss_decide = td.toss_id
group by 
    td.toss_name;




-- query to replace all occurrences of "Delhi_Capitals" with "Delhi_Daredevils"?
update matches
set opponent_team = 'delhi daredevils'
where opponent_team = 'delhi_capitals';
