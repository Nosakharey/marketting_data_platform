Select 
    trim(account_id) as account_id,
    trim(account_name) as account_name,
    upper(trim(ad_currency_code)) as currency,
    try_cast(account_created_at as timestamp) as account_created_at,
    try_cast(account_updated_at as timestamp) as account_updated_at
FROM
    {{source ("facebook_ads", "accounts" )}}