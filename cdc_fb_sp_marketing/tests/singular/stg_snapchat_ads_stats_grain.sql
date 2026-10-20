select
    ad_id,
    ad_date,
    ad_country,
    count(*) as row_count
from {{ ref('stg_snapchat_ads_stats') }}
group by ad_id, ad_date, ad_country
having count(*) > 1