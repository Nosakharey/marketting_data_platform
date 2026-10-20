SELECT
    (concat_ws('|', cast(ad_date as string), coalesce( ad_country, 'n/a'), ad_id, data_source)) as ad_key,
    CASE
        WHEN data_source ='facebook_ads' THEN 'facebook'
        WHEN data_source = 'snapchat_ads' THEN 'snapchat'
    END as platform,
    ad_date,
    account_id,
    campaign_id,
    campaign_name,
    ad_id,
    ad_name,
    ad_country,
    spend_usd,
    impressions,
    clicks,
    (clicks/nullif(impressions,0)) as ctr,
    (spend_usd/nullif(clicks,0)) as cpc,
    (spend_usd/nullif(impressions,0) * 1000) as cpm
 
FROM
    {{ ref('int_marketing_ads') }}
