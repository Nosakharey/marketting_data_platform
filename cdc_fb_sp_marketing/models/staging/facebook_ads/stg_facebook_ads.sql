SELECT
    trim(ad_id) as ad_id,
    trim(campaign_id) as campaign_id,
    trim(ad_group_id) as ad_group_id,
    trim(account_id) as account_id,
    trim(ad_name) as ad_name,
    upper(trim(ad_status) ) as ad_status,
    try_cast (trim(ad_updated_at)  as timestamp) as ad_updated_at
FROM
    {{source('facebook_ads', 'ads')}}