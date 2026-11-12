{% macro date_dimension(start_date, end_date) %}
with spine as (
    select dateadd('day', seq4(), '{{ start_date }}'::date) as date_day
    from table(generator(rowcount => 5000))
)
select
    date_day,
    year(date_day)                       as year,
    quarter(date_day)                    as quarter,
    month(date_day)                      as month_number,
    monthname(date_day)                  as month_name,
    to_char(date_day, 'YYYY-MM')         as year_month,
    day(date_day)                        as day_of_month,
    dayofweekiso(date_day)               as day_of_week_number,
    dayname(date_day)                    as day_name,
    dayofweekiso(date_day) >= 6          as is_weekend
from spine
where date_day <= '{{ end_date }}'::date
{% endmacro %}