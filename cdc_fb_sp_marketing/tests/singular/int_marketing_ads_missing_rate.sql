select
    ad_date,
    currency,
    spend
from {{ ref('int_marketing_ads') }}
where spend is not null
  and spend_usd is null
