SELECT
    trim(campaign_id) as campaign_id,
    trim(account_id) as account_id,
    trim(campaign_name) as campaign_name
FROM
    {{source('snapchat_ads', 'campaign_history')}}