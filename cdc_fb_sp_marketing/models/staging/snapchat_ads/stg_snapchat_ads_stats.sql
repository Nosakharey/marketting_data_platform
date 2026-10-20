SELECT
    trim (ad_detail_id) as ad_id,
    upper(trim(ad_currency_code)) as ad_currency_code,
    upper (trim (ad_country)) as ad_country,
    try_cast (trim (ad_spend) as decimal(18,6)) as spend,
    try_cast (trim (ad_impressions) as bigint) as impressions,
    try_cast (trim (ad_clicks) as bigint) as clicks,
    try_cast(trim(ad_date) as date) as ad_date,
    trim(data_src) as data_source
FROM 
    {{source('snapchat_ads', 'ads_stats')}}