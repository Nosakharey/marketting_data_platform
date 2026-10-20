WITH un AS
(
    SELECT
        *
    FROM
        {{ ref('int_facebook_ads') }}

    union all

    SELECT 
        *
    FROM
        {{ ref('int_snapchat_ads') }}
)
,

with_month AS (
	SELECT
		*,
		CAST(DATE_TRUNC('month', ad_date) AS DATE) as ad_month

	FROM
		
		un
)
 

SELECT
	wm.*,
	ex.rate_to_usd,
	(wm.spend * ex.rate_to_usd) as spend_usd
FROM
	with_month as wm

LEFT JOIN
	{{ ref('exchange_rates') }} as ex ON wm.ad_month = ex.rate_month and wm.currency = ex.currency


