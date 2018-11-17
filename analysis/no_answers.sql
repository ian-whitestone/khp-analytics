
DROP TABLE IF EXISTS alerting;
CREATE TEMPORARY TABLE alerting AS (    
    SELECT 
        agentid, eventtime as alert_time, contactid, eventid, 
        ROW_NUMBER() OVER (PARTITION BY agentid, contactid, eventid ORDER BY eventtime ASC) AS contactid_num
    FROM stat_adr
    WHERE
        contactid is not null
        AND eventid=71 -- "Alerting" eventid
)
;

DROP TABLE IF EXISTS call_released;
CREATE TEMPORARY TABLE call_released AS (   
    SELECT 
        agentid, eventtime as call_released_time, contactid, eventid, 
        ROW_NUMBER() OVER (PARTITION BY agentid, contactid, eventid ORDER BY eventtime ASC) AS contactid_num
    FROM stat_adr
    WHERE
        contactid is not null
        AND eventid=201 -- "Alerting" eventid
)
;


DROP TABLE IF EXISTS no_answers;
CREATE TEMPORARY TABLE no_answers AS (
    select 
        a.agentid,
        a.contactid,
        a.contactid_num,
        a.alert_time,
        b.call_released_time,
        agent_release.eventtime AS agent_released_time, 
        COALESCE(agent_release.agent_released_ind, 0) AS agent_released_ind,
        call_released_time - alert_time AS no_answer_time, -- time between alerting and call released
        EXTRACT(EPOCH FROM call_released_time - alert_time) AS no_answer_time_secs -- time between alerting and call released
    from alerting as a
    join call_released as b
    on a.contactid=b.contactid
    and a.agentid=b.agentid
    and a.alert_time < b.call_released_time
    and a.contactid_num=b.contactid_num
    join (
        select agentid, eventtime, eventid, contactid
        from stat_adr
        where 
            eventid=72 -- "No Answer" event
            and eventtype=2
    ) AS no_answer
    on no_answer.agentid = a.agentid
    and no_answer.contactid=a.contactid
    and no_answer.eventtime >= a.alert_time
    and no_answer.eventtime <= b.call_released_time
    left join (
        select agentid, eventtime, eventid, 1 as agent_released_ind
        from stat_adr
        where 
            eventid=203 -- "Releasing Call" event
    ) AS agent_release
    on agent_release.agentid = a.agentid
    and agent_release.eventtime >= a.alert_time
    and agent_release.eventtime <= b.call_released_time
    GROUP BY 1,2,3,4,5,6,7,8,9 -- de-duping, not perfect but good enough
)
;

-- export for analysis, remove some outliers (there were ~4 of them)
select *
from no_answers
where no_answer_time_secs < 100
;


-- agents manually releasing calls instead of answer
SELECT agentid, sum(agent_released_ind) as agent_releases
FROM no_answers
GROUP BY 1
;


-- cases where an agent was repeatedly not answering the same contact
SELECT *
FROM (
    SELECT agentid, contactid, count(*) as cnt, sum(agent_released_ind) as agent_releases
    FROM no_answers
    group by 1,2
) AS a
where cnt > 1
;

