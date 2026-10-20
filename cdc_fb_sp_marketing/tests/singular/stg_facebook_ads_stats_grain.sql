select
    ad_id,
    ad_date,
    count(*) as row_count
from {{ ref('stg_facebook_ads_stats') }}
group by ad_id, ad_date
having count(*) > 1


