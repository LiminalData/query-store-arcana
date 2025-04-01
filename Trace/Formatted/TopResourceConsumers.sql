/*
Top Resource Consumers UI Dashboard Query
*/
declare
    @results_row_count   int,
    @interval_start_time datetimeoffset(7),
    @interval_end_time   datetimeoffset(7);

select
    @results_row_count   = 25,
    @interval_start_time = dateadd(hour,-1,getdate()),
    @interval_end_time   = getdate();

select top (@results_row_count)
    p.query_id as query_id,
    q.[object_id] as [object_id],
    isnull(object_name(q.[object_id]), '') as [object_name],
    round(
        convert(
            float, 
            sum(rs.avg_duration * rs.count_executions)
        ) * 0.001, 
        2
    ) as total_duration,
    sum(rs.count_executions) as count_executions,
    count(distinct p.plan_id) as num_plans,
    qt.query_sql_text
from sys.query_store_runtime_stats as rs
join sys.query_store_plan as p on p.plan_id = rs.plan_id
join sys.query_store_query as q on q.query_id = p.query_id
join sys.query_store_query_text as qt on q.query_text_id = qt.query_text_id
where not (
        rs.first_execution_time > @interval_end_time
        or rs.last_execution_time < @interval_start_time
    )
group by 
    p.query_id,
    qt.query_sql_text,
    q.[object_id]
having count(distinct p.plan_id) >= 1
order by total_duration desc;
