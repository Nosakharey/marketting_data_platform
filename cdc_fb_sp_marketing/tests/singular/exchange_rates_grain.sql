select
    rate_month,
    currency,
    count(*) as row_count
from {{ ref('exchange_rates') }}
group by rate_month, currency
having count(*) > 1
