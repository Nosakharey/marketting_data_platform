SELECT
    s.data_source,
    s.ad_id,
    c.account_id,
    g.campaign_id,
    c.campaign_name,
    h.ad_group_id,
    h.ad_name,
    cast(null as STRING) as ad_status,
    s.ad_date,
    s.ad_country,
    s.ad_currency_code as currency,
    s.spend,
    s.impressions,
    s.clicks
FROM
    {{ ref('stg_snapchat_ads_stats') }} as s

LEFT JOIN 
    {{ ref('stg_snapchat_ad_history') }} as h ON s.ad_id = h.ad_id

LEFT JOIN
     {{ ref('stg_snapchat_ad_groups') }} as g ON h.ad_group_id = g.ad_group_id

LEFT JOIN
    {{ ref('stg_snapchat_campaigns') }} as c ON g.campaign_id = c.campaign_id