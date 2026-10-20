with source as (
    select *
    from
        {{source ("facebook_ads", "ads_stats" )}}
),

renamed as (
    select
        trim(ad_id) as ad_id,
        trim(account_id) as account_id,
        try_cast (ad_spend as decimal(18, 4)) as spend,
        try_cast(ad_impressions as bigint) AS impressions,
        try_cast (ad_clicks as bigint) AS clicks,
        try_cast (ad_date as date) As ad_date,
        cast ('facebook_ads' as string) AS data_source

    from
        source
)

select
    *
from
    renamed

