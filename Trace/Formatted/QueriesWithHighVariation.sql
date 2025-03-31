declare
    @results_row_count int,
    @interval_start_time datetimeoffset(7),
    @interval_end_time datetimeoffset(7);
select
    @results_row_count=25,
    @interval_start_time='2025-03-28 13:38:47.4896223 -04:00',
    @interval_end_time='2025-03-28 14:38:47.4896223 -04:00';

SELECT TOP (@results_row_count)
    p.query_id query_id,
    q.object_id object_id,
    ISNULL(OBJECT_NAME(q.object_id),'''') object_name,
    qt.query_sql_text query_sql_text,
    ROUND(CONVERT(float, SQRT( SUM(rs.stdev_duration*rs.stdev_duration*rs.count_executions)/NULLIF(SUM(rs.count_executions), 0)))*0.001,2) stdev_duration,
    ROUND(CONVERT(float, SUM(rs.avg_duration*rs.count_executions))/NULLIF(SUM(rs.count_executions), 0)*0.001,2) avg_duration,
    ISNULL(ROUND(CONVERT(float, (SQRT( SUM(rs.stdev_duration*rs.stdev_duration*rs.count_executions)/NULLIF(SUM(rs.count_executions), 0))*SUM(rs.count_executions)) / NULLIF(SUM(rs.avg_duration*rs.count_executions), 0)),2), 0) variation_duration,
    SUM(rs.count_executions) count_executions,
    COUNT(distinct p.plan_id) num_plans
FROM sys.query_store_runtime_stats rs
    JOIN sys.query_store_plan p ON p.plan_id = rs.plan_id
    JOIN sys.query_store_query q ON q.query_id = p.query_id
    JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
WHERE NOT (rs.first_execution_time > @interval_end_time OR rs.last_execution_time < @interval_start_time)
GROUP BY p.query_id, qt.query_sql_text, q.object_id
HAVING COUNT(distinct p.plan_id) >= 1 AND SUM(rs.count_executions) > 1
ORDER BY variation_duration DESC;
