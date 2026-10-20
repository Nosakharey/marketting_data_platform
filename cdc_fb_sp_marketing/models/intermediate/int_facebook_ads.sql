with ads as (
    SELECT
        ad_id,
        ad_name, 
        ad_status, 
        campaign_id, 
        account_id,
        ad_group_id
    FROM
        {{ref('stg_facebook_ads')}}
)

SELECT
        data_source,
        s.ad_id,
        s.account_id,
        a.campaign_id, 
        campaign_name,
        ad_group_id,
        ad_name,
        ad_status,
        s.ad_date,
        cast(null as STRING) as ad_country,
        currency,
        spend,
        impressions,
        clicks      
FROM
    {{ref('stg_facebook_ads_stats')}} as s
LEFT JOIN
    ads as a on s.ad_id = a.ad_id
LEFT JOIN
     {{ref ('stg_facebook_campaigns') }} as c on a.campaign_id = c.campaign_id
LEFT JOIN
    {{ref ('stg_facebook_accounts')}} as cu on s.account_id = cu.account_id








































































