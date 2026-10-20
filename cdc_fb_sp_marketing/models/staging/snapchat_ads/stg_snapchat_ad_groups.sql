
with ranked_records as (
    SELECT
        trim(ad_group_id) as ad_group_id,
        trim(campaign_id) as campaign_id,
        trim(ad_group_name) as ad_group_name,
        try_cast (trim(ad_group_updated_at) as timestamp) as ad_group_updated_at,
        ROW_NUMBER() OVER(PARTITION BY ad_group_id ORDER BY  ad_group_updated_at desc ) as rn
    FROM
        {{(source('snapchat_ads', 'ad_group_history'))}}

)

SELECT
        ad_group_id,
        campaign_id,
        ad_group_name,
        ad_group_updated_at
FROM
    ranked_records
WHERE
    rn=1
