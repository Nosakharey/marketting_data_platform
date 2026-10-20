SELECT
    trim(ad_id) as ad_id,
    trim(ad_group_id) as ad_group_id,
    trim(ad_name) as ad_name,
    try_cast(trim(ad_detail_updated_at) as timestamp ) as ad_updated_at
FROM
    {{source('snapchat_ads', 'ad_history')}}

