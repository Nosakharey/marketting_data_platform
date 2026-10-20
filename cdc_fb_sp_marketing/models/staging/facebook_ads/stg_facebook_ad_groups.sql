SELECT
    trim(ad_group_id) as ad_group_id,
    trim(ad_group_name) as ad_group_name,
   try_cast(trim(ad_group_updated_at) as timestamp) as ad_group_updated_at

FROM
    {{source('facebook_ads', 'ad_groups')}}