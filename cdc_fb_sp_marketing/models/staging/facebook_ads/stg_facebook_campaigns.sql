SELECT
    trim(campaign_id) as campaign_id,
    trim(campaign_name) as campaign_name,
    try_cast (trim(campaign_updated_at) as timestamp) as campaign_updated_at
FROM
    {{source('facebook_ads', 'campaigns')}}