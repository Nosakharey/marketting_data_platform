> **Note:** this is my raw working journal, written as I built the project (steps, errors, fixes). Some early decisions changed later; the README describes the final state. In particular, missing clicks/impressions are kept as NULL in the final model, not set to 0.

---

DBT_MARKETTING ASSIGNMENT DOCUMENTATION

1 Understanding the data

-- What to do?
in this first half, i am understanding the data, the tables and its columns, the primary, foreign and composite keys.
also, i am understanding what the assignment wants for us. why are we using dbt? imagining how things will look like after dbt has transformed the data.
Taking a sketch of how the dbt layer will look like.

-- discovery?
during this phase, i doscoverd each tables has its own meanining, the snapchat(tables) and facebook(tables). furthermore, there are quite a number of transformations that would take place.
example, i realize that some of these tables have composite keys, in dbt, this composite key will turned into a surrogate key(hash, new columns)

--errors: Nil

--solutiins :


2. checking up up dbt & databricks & githubrepo.

-- What to do?
for setting up dbt & databricks, make sure both accounts are active and so deadline is close for the account set to end. Also, make sure GitHub repo is created for this project, and clone the GitHub project into IDE(vs_code).
--discovery? after setting up, deeper questions needs to be answered on how our final architecture will look like:
i)How detailed should the final table be?
a)One row per ad per day (Recommended)
Keeps the detail. Campaign totals can always be added up later.
b)One row per campaign per day
A summary only. Simpler, but the ad-level detail is lost for good.
ans: this questions highlights how the final mart table should look, show the table obtain one row per ad day. that is, once the ad is active in a day, the data is collected per ad day. the same ad could posted on different days. the second says one row per campaign: this means that data is coallated one row per campaign posted, this will shrink the per ad day because a particular ad posted per day that appears everyday, it still for one campaign. I choose a because i like being detailed.

ii) What do we do with Snapchat's country column?
a)Keep it (Recommended)
Facebook rows get null for country. No detail is lost.
b)Drop it by adding Snapchat's countries together
Every row means the same thing, but the country breakdown is gone.
ans: Looking through the table, the facebook platform has no country column while the snapchat has a county column. this will affect our final mart table, because the facebook sides will appear as null. thinking into this crtitically, i made up my mind to go with 'a'. why? in the long run, what if facebook decides to update the column tables aswell? also, what dont know what could happen in the nearest future, our analyst might need to query data that needs the snapchat country data, so deleting it risky.

iii)What do we do about USD vs EUR spend?
a)Add a currency column and don't convert (Recommended)
Honest, because the data has no exchange rate. Analysts split spend by currency.
b)Convert everything to one currency
One total, but you must choose an exchange rate that isn't in the data.
ans:
this is quite a unique scenario. having a currency column that has 2 difference currencies. looking through, my architecture mindset is leading towards converting everything into one currency looks a bit cool, but now we have to have a rate column or something. a rate column will be added, i understand that flunctuation might happen that is why i have decided to have a static monthly exchange rate by calculating the average of all the orders in a month. so i downloaded a csv file from the official ECB website, which shows the rate of euro to usd for the past 10 years. this will aligned in my seed file to help convert the euro to usd, since usd is dorminated.


3. Setting up dbt
-- What to do?
once the project has been cloned, uv is installed, so uv is a python package manager, it helps saves and manage python code which the depenedencies of the python running in your environment. Once uv has been installed, we start a new project with python. python helps us manage our project. with the code: "uv init --bare --name cdc_modelling --python 3.11" this is use to initialize our environment with uv, python creates the project we defined "cdc_marketting" in pyproject.toml, a manager that manages the python dependencies for our project. the pyproject.toml is written in tom's Obvious, Minimal Language. as said, the  pyproject.toml file stores and manages our Project Info(name of our project, version, description, author, etc), Dependencies (what python packages our project will depend on) etc
once the uv is initialize successfully, the dependencies part is empty dependencies = [], we will need to define the dependencies that our python project will need. Now, our project needs both dbt and databricks, dbt is the engine is used to write the sql queries while databricks is where the data is being stored. to install the dependencies we need we do ;uv add dbt-databricks. this adds dbt_databricks adapter to the dependencies in pyproject.toml it adds the exact version of every packages needed for dbt-databricks. examples:dbt-core, the Databricks SQL connector, and dozens of sub-dependencies.
uv.lock file appears = this file is to lock the exact versions of the packages. this is very essential asper when you need to share your python to someone, they will need it.
.venv = the virtual environment for python.so instead of isntalling all of this dependencies scattered in your local computer, .venv is rather created install the packages inside that folder. this folder is isolated from your local computer. everything your project needs lives inside here.
the bin = the folder contains the command line tools and entry points for the software you insalled. when dbt-databricks is installed, it dropped a dbt executable file into this folder. when you run 'uv run dbt', uv looks inside this specific bin directory to find the executable dbt command.
lib = the lib folder is the warehouse where the actual python code files for the package you installed. so in summary bin holds the command and lib holds the actual python file packages for it to run.
Now, next step is to add this dependency :uv add 'elementary-data[databricks]~=0.22.0' this command installs "Elementary", which is a popular open source data observability and monitoring tool specifically for dbt projects.it tracks dbt test results , monitors data freshness , detect anomalies. it automatically added to ur pyproject.toml once uv installs it. adding the [databricks] is the same deifnintion as before, the elementary needs datawarehouse where it can connect and track the data, without databricks, you are only installing the dbt sql engine, which will be pointless.
Now, enough fir uv, the nexr command we are creating is the dbt skeleine, since we have added the dbt inside our python package, creating the skeletine of dbt will be helped by both the
lib and bin, while one is where the python code file is stored, the other is where the dbt command is installed, to create the dbt skeleton, we run uv run dbt init cdc_marketing --skip-profile-setup. this create the dbt project structure that includes the essential dbt folders. note, we skipped project setup that tries to configure the profiles.yml imediatelly. this will enable us set up this manually yourself.Now,here are the folders that are created when we initialize dbt :

analyses/
A folder for storing ad-hoc or experimental SQL queries. You can keep queries here for documentation or team sharing, but dbt will ignore them and not build them into tables or views in Databricks.

macros/
Your custom code workshop. If you need to write the same repetitive SQL logic across multiple models, you build a reusable function here using Jinja templates.

models/
The core workspace of your project. This is where you will write your transformation SQL files (.sql) to clean, shape, and model your marketing data.

seeds/
A folder for static CSV files (like mapping lists, category codes, or targets). When you run dbt seed, dbt will automatically read these CSVs and upload them into Databricks as tables.

snapshots/
Used for tracking history over time (known as Slowly Changing Dimensions or SCD Type 2). It automatically records when rows are inserted, updated, or deleted in your source data.

tests/
Where you store custom data checks and assertions to catch bad data, missing values, or unexpected duplicates before your downstream dashboards use them.

dbt_project.yml
The main control panel of your dbt project. It defines your project name, tells dbt where to find your folders, and sets global materialization rules.

README.md
A standard text file where you can write notes, deployment steps, or instructions for anyone reading or using your repository.

4.setting up profiles.yml file

After the basic understanding of the structure of dbt, we move into creating our profiles.yml file. In any world, a profile.yml file tells dbt where to login and run. the dbt_project.yml says what to build and profile.yml says where to build it. imagine building with no profile.yml, it cant find the warehouse, it cant prove who you are, it doesn't know where to put the results(catalog & schema). in this project, we would need to define 3 environment in our profile.yml file : development, ci/cd and production
Development: this is the first contact of your project, you work here, make any changes here.its a personal environment and when you need it to connect to databricks(the WH), you only need a personal token.
ci/cd: once your development is done, you dont just push to production without testing and confirming everything works fine. now, you might be wondering what the difference between test(dbt test) and ci/cd. dbt test checks if the data itself is correct and in good shape, eg testing for duplicates or null values, Elementary is monitoring your your dbt eg result change, freshness, anomalies and a report(Is the data behaving normally, and what’s changed?”). the ci in ci/cd is the automatation that runs in every pull request.
What the CI robot does

Starts a clean machine. GitHub gives it a blank computer with nothing of yours on it.
Downloads your code. It checks out the branch from your pull request, so it tests your changes and not an old version.
Installs the tools. It runs uv sync to rebuild the .venv from your pyproject.toml and lock file.
Gets its login. It reads the Databricks host, HTTP path and token from GitHub secrets (a safe store for credentials) as environment variables. This is why your profiles.yml reads from env vars.
Connects and builds. It runs dbt with the CI target, which writes tables into ci_development. Your models are built from scratch.
Runs the tests. Your uniqueness, not-null and zero-denominator checks run against the freshly built tables.
Reports back. The pull request shows a green check if everything passed, or a red mark with a log showing which step failed.

What you do with the result

Red: you read the log, fix the problem, and push again. CI re-runs automatically on every push.
Green: you merge. In a mature setup, merging to main can then trigger a production deploy.

Production: The production environment is our live, official version of our data. the one people and tools depends on. in this project, the production is :
The tables that analysts, BI tools and the AI agent query. Your final model fct_marketing_spend lives here.
Built by a scheduled job, not by you typing commands. Nobody should be manually editing the live tables.
Built from code that has passed CI and been merged to main. Only reviewed, tested changes get here.
Run with a Service Principal, a robot identity, and not your personal login (the brief requires this).
Note: in this environment workflow, a particular stage is neglected "staging" because it is not essential for this build.
Now, we write our profiles.yml file. one of the main things needed:
type: databricks	Which database dbt is talking to	“Speak Databricks, not BigQuery”
host:	The address of your Databricks workspace	The street address of the building
http_path:	The route to one specific SQL warehouse (the compute engine) inside that workspace	The room in the building where the work happens
token:	A password that proves who you are	The key card that lets you in
catalog:	The top-level data container	The cabinet where your files are kept
schema:	A folder inside the catalog	A drawer in that cabinet
threads: How many models dbt builds at the same time	How many cooks work in parallel.

in profiles.yml file,
the essential path needs to be stated
host,path(since we are starting with dev),http, schema and catalog




-- errors: when i try to create a catalog : Metastore storage root URL does not exist. Default Storage is enabled in your account. You can use the UI to create a new catalog using Default Storage, or please provide a storage location for the catalog (for example 'CREATE CATALOG myCatalog MANAGED LOCATION '<location-path>')
solution: changed the storage location default.

now to run uv run dbt debug: this is what dbt debug does, it checks this in order
a)can it find dbt_project.ymi?
b)can it find profiles.yml and is everything valid?
c)does the profile name in both files match and all required env vars set?
d)can it actually connect to databricks with those details?

--Error : 6:09:37  Running with dbt=1.12.5
16:09:38  dbt version: 1.12.5
16:09:38  python version: 3.12.3
16:09:38  python path: /mnt/c/Users/godwi/Desktop/marketting_data_platform/.venv/bin/python
16:09:38  os info: Linux-6.6.87.2-microsoft-standard-WSL2-x86_64-with-glibc2.39
16:09:38  [ERROR]: Encountered an error:
Parsing Error
  Env var required but not provided: 'DATABRICKS_PAT_TOKEN'

--solution: i ran into a error because i forgot to set my secret paths into env.
the problem was i needed to define the varables path and add them to my environment variable. why? the varibles PAT,catalog, and schema were already defined as a variable flag on my profile.yml. Now dbt actually needs the value themselves for it to connect to databricks successfully. now, the process of adding those essential paths to our env,
first you need to create .sh file. we call it secret.sh. this is a excutable Linux file since we are in Linux, then we define each of the path using export, eg export DEV_CATALOG="dev_godwin" you can easily type this in ur terminal, its a command itself, but we have to 3 paths we want to define in our variable, doing this manually each time and noting once the actual terminal we are working with breaks, we need to define the variable manually on the terminal all over again, so the .sh file makes like easy, you just need to run this command; source ./secrets.sh.
finally its successful! our dbt can see databricks by running dbt debug.

5. Extraction process
-- what to do
In this part we extracting the data into databricks from our file storage, the tool that will be used is airbyte.
for this first step, a catalog and schema is created where the first sight of the data are landed.
my catalog nanme is bronze dev while 2 schemas are created for facebook and snapchat.
now the loading, i will first download the 2 zip folder from the cde_link. i will then unzip these 2 folders.
now, i moved to airybte so i could extract the data into databricks, i landed into an error..
after airbyte has finally installed, i got my login credentials using :sudo abctl local credentials, this provided the airbyte login credentials.


--error : the error states that where airbyte data that is stored in postgres, has been corrupted.
--solution I need to uninstall and reinstall aribyte all over again.
now i tried putting the source of data in my local storage into airbtye. oh now, i have hit a road block.
found out that my local storage link is not in HTTPS and airbyte wouldn't be able to reach it. i tried using different solution but still hit a road block, my airchetecture has changed and i have decided to focus on manaually loading the data in to databricks.
the data consist to 9 tables, 5 for facebook, 4 for snapchat.
loading the data;
ads_stats(facebook) : looking the columns, eg(ad_impressions,ad_clicks), they contain null values. we need to confirm this because, we would be transforming this much later.
Discovery: null values in ads_stats

Loaded: 92,300 rows, matches the file.
The upload kept null as the text 'null', not a real NULL (IS NULL returned 0, = 'null' returned rows).
ad_clicks = 'null' in 24,337 rows (26%). ad_impressions = 'null' in 1,474 (1.6%). ad_spend never missing.

Question I asked: Does a missing value mean “nobody clicked / nobody saw it”, or “not reported”?

How I investigated: Grouped rows by whether clicks are missing and compared averages.

	Clicks present	Clicks missing
Rows	67,963	24,337
Avg impressions	13,288	104
Avg spend	$138.39	$1.09
All 1,474 rows with missing impressions also have missing clicks. No row has clicks without impressions.
So 22,863 rows have impressions but no clicks; 1,474 have neither.

Conclusion / decision (for the final model)

Impressions present, clicks missing → clicks = 0 (ad was shown, no click recorded).
Impressions missing → both stay NULL, so CTR, CPC, CPM come out NULL, not 0.
Staging: only convert text to NULL with try_cast, no assumptions.

Limit / assumption: The source doesn’t say what a missing value means. This is inferred from the averages, not confirmed.

Still to check: spend on the 1,474 rows with missing impressions. Result: ______ (zero spend: __ , positive spend: __ ). If mostly zero spend → “not shown”. If positive → incomplete data, keep NULL.

Next: load the other 8 tables, compare row counts, then start stg_facebook_ads.

Fill in the blanks after the spend query, and keep the table of row counts as you load the rest.

after uploading all the tables for facebook, i just discovered that the marketing company is posting ads for its clients through the facebook account table.
the facebook account table consists of client bank account that pays to facebook for ads.
for this aspect, i check towards all coumnns and rows to know what each tables actually look like and what transformation that is needed. I calculated the amount of rows for each table in the databricks to be sure everything is fine.
moving forward, i also confirmed that every column in the facebook_ads table is a string using this sql query:
SELECT table_name, column_name, data_type
FROM bronze_dev.information_schema.columns
WHERE table_schema = 'facebook_ads'
  AND data_type <> 'STRING'
if this reuturns empty, then all columns are strings.
ORDER BY table_name, ordinal_position;, although, i initally converted this to string in the process of uploading the tables into databricks.

in the same process, we uplaoded the snaptchat tables into databricks, confirm all rows are complete, confirm all columns are text; this is better so that we can easily tranformed them in dbt, no room for assumptions, quick checks on each table to see how unclean they are.
i also confirm if ad_stats had duplicates with this sql query and it returned clean:
SELECT ad_id, ad_date, COUNT(*) AS n
FROM bronze_dev.facebook_ads.ads_stats
GROUP BY ad_id, ad_date
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 20;

also did for snapchat as well:
SELECT ad_detail_id, ad_date, COUNT(*) AS n
FROM bronze_dev.snapchat_ads.snapchat_ads_stats
GROUP BY ad_detail_id, ad_date,ad_country
HAVING COUNT(*) > 1
ORDER BY n DESC
LIMIT 20;

Do you know that from the  ads_stats in the Facebook table,

an ad_id could appear every day?
That means the ad is posted once but runs every day and the stats table  records one row for each day it ran.

Does that mean the ad_id can never be a unique identifier in the ad_stats table?
YES.
You can confirm by running a query that checks if the ad_id is unique.


So what was done to make it unique?
The date column was added to the ad_id. Because each the same ad_id appears in  different days. So, to find a unique identifier in ads_stats table:
ad_id and date was combined to make a unique composite key identifier.

note: per checking the data;
Missing impressions = record exists, spend 0, no delivery recorded. Possible causes (not distinguishable from the data): ad not delivered / in review, insufficient budget, or delivered with zero impressions. Business questions in the brief (spend, impressions, clicks, CTR/CPC/CPM) are unaffected. Final model sets impressions and clicks to 0 and keeps a flag column showing the source value was missing.


6. dbt staging layer(source.yml)
To me, source.yml are like pointers, letting dbt know where the actual tables live in ur databricks. when dbt gets to warehouse, it needs to know which table it is working with. this is source.yml comes in. first, we need to create the staging model folder, then create facebooks_ads folder, then inside it, we create the source.yml file and define it. that is, the table dbt did not create but reads from databricks.

sources:
  - name: facebook_ads
    database: bronze_dev
    description: data from facebook platform (static)
    schema: facebook_ads
    config:
      enabled: true
    meta:
      owner: "@nosadida"
      #freshness:
        #warn_after:
          #count: 5
          #period: day

 
    tables:
      - name: accounts
        identifier:  new_acccount_de_randomized
        description: ad stats on (will fill this later--------)

      - name: ad_groups
        identifier: new_adgroup_de_randomized
        description: ad stats on (will fill this later--------)

      - name: ads
        identifier: new_ads_de_randomized
        description: ad stats on (will fill this later--------)
 
      - name: campaigns
        identifier: new_campaign_de_randomized
        description: ad stats on (will fill this later--------)
 

      - name: ads_stats
        description: ad stats on (will fill this later--------)

above shows my dbt source.yml file in models/staging/facebook_ads/source.yml file.
things to note
a) the freshness block is commented out because my data is static and there is no changes happenening so why freshness checks if there is new data. so this will definitely be a waste. also, i would have to go back and confirm if the freshness block ought to be under meta.

b)identifier, so basically, i extracted data into my databricks without changing the table name, i think this was a slight mistake, i was supposed to change the table name to a cleaner version. the solution is what identifier does, identifier takes the real name of the table while i give it a cleaned name myself.

now running the code : uv run dbt parse
noq, what does this code?
this code is not to run any model.
uv run dbt parse is a check that reads your project file or models and makes sure dbt can understand them. It doesn’t run any models or change any data. its more like checking if u correctly write your code with proper identation given

The three parts of the command

uv run runs the command inside your project’s environment, so it uses the dbt version recorded in pyproject.toml.
dbt parse reads every file in the project and builds an internal map of it.

What parse does

Reads dbt_project.yml and profiles.yml.
Reads every .sql model and every .yml file (sources file for example).
Checks the YAML is valid, that keys are spelled correctly, and that every source() and ref() points to something that exists in your project.
Writes the result into the target/ folder (manifest.json). That’s the file that makes your first target/ appear.

What parse does not do

It doesn’t connect to Databricks to run queries (the connection is only needed for some profile checks).
It doesn’t check that the tables exist in Databricks.
It doesn’t build anything.

Why we run it now: it’s the fastest, cheapest check that your sources.yml is valid. A misplaced indent or a repeated key shows up here, not in the middle of a long run later. Think of it as a spell-check before you send the document.

How to read the result

Finishes with no errors (usually a few lines about the project version and a count of resources): the file is good.
An error naming a file and line: that’s where the YAML is wrong, and you can paste it here.

the target folder actually appeared after running : uv run dbt parse.

The target folder: the target folder is where dbt write everything it generates:
these are the files that appeared for now(since i am into just source.yml)

File	                What it is
manifest.json	The full map of your project: sources, models, tests and how they connect. The most important one.
partial_parse.msgpack	A cache, so the next parse only re-reads files you changed.
perf_info.json	How long each parsing step took.
semantic_manifest.json	Data for dbt’s Semantic Layer. Yours is empty ("saved_queries": []) because you haven’t defined any. Ignore it.
osi_document.json	A newer export for semantic tools. Also ignorable.

There’s no compiled/ or run/ folder yet, because you haven’t compiled or run any models. They’ll appear once you do.

--- warning: while running uv run dbt parse, dbt warned me about my
- name: facebook_ads
    meta:
      owner: "@nosadida",
this relates to owner of the dev, which is me. But this is an older version of doing this. Newer dbt moved all settings (enabled, meta, tags and so on) inside config:, so each thing has one standard home:

yaml
  - name: facebook_ads
    config:
      meta:
        owner: "@nosadida"

now, the next thing is to check if dbt can really reached our databricks table and we do this by this synthax: uv run dbt show --inline "select * from {{ source('facebook_ads', 'accounts') }} limit 5". this is just a test to see how the table looks like in dbt.

---error :22:44:06  Running with dbt=1.12.5
22:44:21  Registered adapter: databricks=1.12.7
22:44:39  Found 2 models, 4 data tests, 1 sql operation, 5 sources, 776 macros
22:44:39
22:44:39  Concurrency: 8 threads (target='dev')
22:44:39
22:44:47  [ERROR]: Encountered an error:
Runtime Error
  Database Error in sql_operation inline_query (from remote system.sql)
 
    [PARSE_SYNTAX_ERROR] Syntax error at or near 'limit': extra input 'limit'. SQLSTATE: 42601 (line 6, pos 2)
 
    == SQL ==
    /* {"app": "dbt", "dbt_version": "1.12.5", "dbt_databricks_version": "1.12.7", "databricks_sql_connector_version": "4.4.0", "profile_name": "cdc_fb_sp_marketing", "target_name": "dev", "invocation_id": "89d9a330-1454-4f27-8d3f-2e0c0316284a", "node_id": "sql_operation.cdc_fb_sp_marketing.inline_query"} */
 
 
      select * from `bronze\_dev`.`facebook\_ads`.`new\_acccount\_de\_randomized` limit 5;
 
      limit 5
    --^^^
so i had this error, because normally, when u run this code to check if u can table in bigquery:uv run dbt show --inline "select * from {{ source('facebook_ads', 'accounts') }} limit 5", behind the scene, dbt had already limit the number of rows u could see to 5, and we still state limit as 5 as well, that why dbt was spannig error, two 'limit 5' in the sql synthax.
--solution :"select * from {{ source('facebook_ads', 'accounts') }}"

--output: godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting_data_platform/cdc_fb_sp_marketing$ uv run dbt show --inline "select * from {{ source('facebook_ads', 'accounts') }}"
00:12:47  Running with dbt=1.12.5
00:13:05  Registered adapter: databricks=1.12.7
00:13:25  Found 2 models, 4 data tests, 1 sql operation, 5 sources, 776 macros
00:13:25
00:13:25  Concurrency: 8 threads (target='dev')
00:13:25
Previewing inline node:
| account_id        | account_name         | ad_currency_code | account_created_at   | account_updated_at   |
| ----------------- | -------------------- | ---------------- | -------------------- | -------------------- |
| 10152913892614834 | Vantora Web - DAC... | USD              | 2014-12-09T10:48:... | 2026-07-30T00:09:... |
| 10153812323239834 | Solace Growth - S... | EUR              | 2015-12-11T15:57:... | 2026-07-30T00:09:... |
| 10155363828439834 | Solace Growth - L... | EUR              | 2017-05-31T12:59:... | 2026-07-30T00:09:... |
| 10156305400409834 | Lingora Acquisiti... | EUR              | 2018-04-19T09:04:... | 2026-07-30T00:09:... |
| 1694907634433329  | Vantora Performan... | EUR              | 2025-03-06T18:16:... | 2026-07-30T00:09:... |



7. Defining staging models(facebook)

-- what to do;
wrtiing of the staging layer, the first point of contact before we move to intermediate and mart.
in dbt staging layer, we do light transfromations. the staging layer is the one that read stright from the raw table.
the raw table is never touched, staging is a view on top of it, which is just a saved query.

Why we keep it as its own layer: every later step (combining Facebook and Snapchat, converting currency, building the final table) starts from clean columns. Without staging, you’d repeat the same casts and renames in every model.

Generally, the staging layer does light, mechanical cleaning only. It makes each raw table consistent and readable, and it leaves the meaning of the data alone.

Cleaning task			What it means					Example from your data
a)Rename columns	Clear, consistent names across all sources		ad_spend → spend, ad_impressions → impressions
b)Cast data types	Turn text into the right type				text "12.50" → decimal; text date → date
c)Handle fake nulls	Turn placeholder text into a real NULL			'null' → NULL (via try_cast)
d)Trim and standardize text	Remove stray spaces, make casing consistent	' Summer Sale ' → 'Summer Sale'; currency usd → USD
e)Standardize formats	Make dates and codes follow one convention		All dates as yyyy-MM-dd, country as a 2-letter code
f)Select only needed columns	Drop columns nobody will use			Skip data_src if it’s not needed
g)Basic deduplication (sometimes)Remove exact duplicate rows or keep the latest version of a record	Snapchat history tables that hold many versions of the same ad
h)Add a simple helper column	Something derived directly from one row	cast(null as string) as country for Facebook

a)stg_facebook_ads_stats.sql
so now under models/staging/facebook_ads/, we create a .sql file called stg_facebook_ads_stats.sql. this is for my first model, ad_stats.
recall what we initially discovered per light cleaning :coverting to the correct data types, treating null, changing columns name if needed, dropping columns etc.
here is the cleaning that was done at this stage:
select
    ad_id,
    account_id,
    try_cast (ad_spend as decimal(18, 4)) as spend,
    try_cast(ad_impressions as bigint) AS ad_impressions,
    try_cast (ad_clicks as bigint) AS clicks,
    try_cast (ad_date as date) As ad_date
FROM
    {{source ("facebook_ads", "ads_stats" )}}
i) changing type
ii) chaging column name
try_cast : we could have used cast, but the null values in our tables right aren't actual NULL data type but null in text format, so we cast a column like this: cast (ad_spend as decimal(18, 4)), when it gets to null text value, it returns error because 'null' was built as a string type. we use try_cast to let our table know to treat the null as NULL
biginit : naturally, we could done this:  try_cast (ad_clicks as number) AS clicks, we know that clicks are number type and it make sense to do it this way, but it launch out an error because in databricks we use biginit instead of number. they work the same way.

we then run this with :uv run dbt show --select stg_facebook_ads_stats, recall that dbt show just show us our model will look like. it is best practice to use this before building and the actual running.. it gives us 5 rows
output :
Previewing node 'stg_facebook_ads_stats':
| ad_id              | account_id        |  spend | ad_impressions | clicks |    ad_date |
| ------------------ | ----------------- | ------ | -------------- | ------ | ---------- |
| 6858573218250      | 10152913892614834 | 628.99 |          33107 |    100 | 2025-04-30 |
| 120216208152400008 | 10155363828439834 |   9.18 |            219 |      1 | 2025-05-16 |
| 6969644890050      | 10152913892614834 |   1.26 |             29 |      2 | 2025-05-02 |
| 120216208837180008 | 10155363828439834 |  44.14 |           1687 |      4 | 2025-05-12 |
| 6837556542250      | 10152913892614834 |   1.98 |             74 |      1 | 2025-05-15 |

from here, we would see that our cleaning worked! no errors so far.
now, next is the actual building... we build the models in staging as view not actual tables. that is, as a saved sql query...:
uv run dbt build select --stg_facebook_ads_stats.sql

**--**error :godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting_data_platform/cdc_fb_sp_marketing$ uv run dbt build select --stg_facebook_ads_stats.sql
Usage: dbt build [OPTIONS]
Try 'dbt build --help' for help.

Error: No such option '--stg_facebook_ads_stats.sql'.
solution: the error show i typed the  synthax incorrectly, the double dashes are supposed to be in front of the select statement.
one thing we need to also note is that, recall that i am using build right? we could still run in this spot. why?
dbt build does: dbt run + dbt test + dbt seed. in our current model, we dont have test or seed yet, so doing dbt build or dbt run at this point will provide the same result.

so we could do : uv run dbt run --select stg_facebook_ads_stats.sql or uv run dbt build select --stg_facebook_ads_stats.sql
Now, this was succesful. this was built as a view(a saved query). we would definitely call this query in our intermdeiate stage.
after a succesffuly run, 2 new folders appeared under target for the first time. recall, target folder tracks our models. the 2 new folders are named below
target/compiled/ : looking in, our models was in jinja previously in the from statement {{ source('facebook_ads', 'ads_stats') }}. but it becomes `bronze\_dev`.`facebook\_ads`.`ads\_stats`. it Shows the plain SQL that dbt worked out from your file
target/run/: The statement dbt actually sent to Databricks, which is your SQL wrapped in create or replace view ... as.  Shows exactly what ran, including where the view was created

next is to confirm if this is actuallt sucessfully in databricks. we know that the dbt show, shows us just 5 of the rows, but in good practice, its good to confirm the view is also in databricks. so we do this by running this query: select * from dev_godwin.dbt_godwin.stg_facebook_ads_stats.
in databricks if we check the schema and catalog we created for dbt to interact with, (dev_godwin,dbt_godwin), we would see the view we created sit under this schema and catalog.
simple queries to confirm everything is fine and accurate
select * from dev_godwin.dbt_godwin.stg_facebook_ads_stats
select count(*)  from dev_godwin.dbt_godwin.stg_facebook_ads_stats  output:92300 rows
select
    count(*)                          as total_rows,
    count(*) - count(spend)           as spend_null,
    count(*) - count(impressions)  as impressions_null,
    count(*) - count(clicks)          as clicks_null,
    count(*) - count(ad_date)         as date_null
from dev_godwin.dbt_godwin.stg_facebook_ads_stats  ... this count the total minus the rows without null, we give us rows with null


b) stg_facebook_accounts
very much the same process with the first...what will change is what will be cleaning, i will state it here and put out some notes.


Same process as stg_facebook_ads_stats: write the select, preview with dbt show, then run to create the view.

Final query:
select
    account_id,
    trim(account_name) as account_name,
    upper(trim(ad_currency_code)) as currency,
    try_cast(account_created_at as timestamp) as account_created_at,
    try_cast(account_updated_at as timestamp) as account_updated_at
from {{ source("facebook_ads", "accounts") }}

Cleaning done and why:
- account_id: kept as text. It is an identifier, not a number to calculate with, and long IDs can be altered if cast to a number.
- account_name: trim() removes stray spaces at the start and end, so the same name is not treated as two different names.
- ad_currency_code -> currency: renamed, trim() removes spaces, upper() makes it USD / EUR. Reason: this column will be joined to the exchange-rate seed, and 'usd' does not equal 'USD'. Whatever case I choose here, Snapchat staging and the seed must use the same one.
- account_created_at / account_updated_at: try_cast to timestamp. Each one gets an explicit "as" name so I do not depend on Databricks guessing the column name.

What dbt show returned: 5 accounts, long IDs intact, timestamps parsed, currencies in usd / eur. So we need EUR to USD in the exchange-rate seed; USD needs no conversion.

Questions I asked and what I learned:

1. If every ad has an account_id, why do we keep the accounts table?
ads_stats and ads only carry the account_id (a number). The accounts table says what the number means: the name and the currency. Facebook spend rows have no currency column, so accounts is the only place the currency exists. Without it I could not convert spend to USD and would be adding euros and dollars together. The join happens in the intermediate layer (ads_stats -> accounts on account_id).

2. Created_at vs updated_at?
created_at = when the account was first set up, never changes. updated_at = last time the row was changed. Observation: all 5 accounts have the same updated_at (2026-07-30 00:09) but created dates from 2014 to 2025. That is probably the pipeline sync stamping every row, not real edits. This is a guess from 5 rows, to confirm on the full table.

3. Why would a row be updated, is it a security problem?
No. Updating a row is normal (typo fix, rename, settings change). Security is about unauthorized or untracked changes, which is handled by permissions and audit logs, not by banning updates.

4. Why would a fixed account name change?
The name is a label. The ID is the fixed part. Clients rebrand, typos get fixed, naming conventions change. Rule: join and group by account_id, never by account_name. Grouping by name could split one account into two after a rename. The final model keeps both: ID to group, name to read.

Assumption to document: each account keeps one currency for the whole period. If an account switched currency mid-way, using today's currency on old spend would be wrong.

Tests to add later:
- unique on accounts.account_id (so the join cannot duplicate rows)
- relationships: every account_id in ads_stats must exist in accounts (otherwise a join silently drops rows or leaves currency NULL)

now, I do this: dbt build  --select stg_facebook_accounts: this build it and create a view in databricks, then count(*) in Databricks and compare with the raw table.
--error:
godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting_data_platform/cdc_fb_sp_marketing$ dbt build --select stg_facebook_accounts.sql
Command 'dbt' not found, did you mean:
  command 'dgt' from deb regina-normal (7.3-2)
  command 'dat' from deb liballegro4-dev (2:4.4.3.1-4)
  command 'dbd' from deb netatalk (3.1.15~ds-1ubuntu1)
  command 'dpt' from deb pkg-perl-tools (0.76)
  command 'dot' from deb graphviz (2.42.2-9ubuntu0.1)
  command 'mbt' from deb mbt (3.6-3)
  command 'lbt' from deb lbt (1.2.2-7)
  command 'dht' from deb pkg-haskell-tools (0.12.4build1)
  command 'dba' from deb wise (2.4.1-23)
Try: sudo apt install <deb name>

--solution, this is very important, for dbt cloud, that synthax would likely run but for dbt core, we need to ad uv run at the back. that is the langauege it understands because built dbt through python installing uv so, uv run dbt build  --select stg_facebook_accounts. now, it works and the target folder is updated as well.

c) stg_facebook_ads
very much the same process with the first...what will change is what will be cleaning, i will state it here and put out some notes.
this is different from ads_stats. while the stats talks about how each ads behave daily. this talks about what the ads is for. for example, if u go down and check its columns, you would campaign_id:..like what the ad is campaigning for..i.e the overall goal of the campaign(sales or web traffic), ad_group: the group of people the ad is leaning towards to. the ad_status: if the ad is up and running or closed. etc
aftet checking if the ad_id in this table is unique for all rows:Select count(ad_id)
from bronze_dev.facebook_ads.new_ads_de_randomized
group by ad_id
having count(ad_id) > 1,
the result returns no duplicates meaning an ad_id must linked to ad_group,campaign_id at once. thats one to one.
but a group can have many ad_id. that ad_group(one) to many (ad_id).
the cleaning done in this stage:
SELECT
    trim(ad_id) as ad_id,
    trim(campaign_id) as campaign_id,
    trim(ad_group_id) as ad_group_id,
    trim(account_id) as account_id,
    trim(ad_name) as ad_name,
    upper(trim(ad_status) ) as ad_status,
    (try_cast trim(ad_updated_at) as timestamp) as ad_updated_at
FROM
    {{source('facebook_ads', 'ads')}}

so just as explained what the ads is, so i found a column called 'ad_name', i was a bit confused because i thought it sounds more like a campaign name, but here is the catch, a campaign name can give birth to many ad_names. example shoe as a campaign name, (sneakers, boot, hills as ad_name).
so the cleaning involves heavily in trimming(removing unwanted spaces). for the ad_status, i assume to obtain sincerity through out the data, the ad_status should be in CAPs.
now, as usual, uv run dbt show...
then uv run dbt build...
and just as this, after builidng we check against the actaul table to the view if they both have same columns and rows.

d) stg_facebook_ad_groups:

What the table is:
An ad group (Facebook calls it an ad set) sits between a campaign and its ads:
account -> campaign -> ad group -> ad
The campaign is the overall goal (for example, sales). The ad group sets how that goal is pursued: who sees the ads (the audience), the budget, and the schedule. The ads are the actual creatives inside the group.
This table describes the ad group itself, not its performance. Spend, clicks and impressions are in ads_stats.

Columns:
- ad_group_id: Facebook-assigned identifier, the key of this table
- ad_group_name: the label someone gave the group, readable by humans
- ad_group_updated_at: when the record was last changed

The table has no campaign_id or account_id. The only link from an ad group to its campaign and account goes through the ads table, where each ad carries ad_group_id, campaign_id and account_id.

Uniqueness check:
group by ad_group_id having count(*) > 1 returned no rows, so ad_group_id is unique: one row per ad group.
Why it matters: ad groups will be joined to ads on ad_group_id. If an ID repeated, every ad in that group would be duplicated, and the spend with it.

Relationship:
One ad group has many ads (one-to-many). Each ad belongs to exactly one ad group (many-to-one, seen from the ad). It is not one-to-one, because that would mean a group holds only one ad.
To confirm (not checked yet): that each ad group sits under a single campaign. Query: select ad_group_id, count(distinct campaign_id) from the ads table group by ad_group_id having count(distinct campaign_id) > 1. Empty means yes.

Cleaning done and why:
- ad_group_id: trim, kept as text. It is an identifier, not a number to calculate with, and the join needs an exact match.
- ad_group_name: trim, so the same name is not treated as two because of stray spaces.
- ad_group_updated_at: try_cast(trim(...) as timestamp), so it is a real timestamp and a bad value becomes NULL instead of stopping the run.

Rule to remember: join and group by ad_group_id, never by ad_group_name. Names are labels. They can change or repeat, and grouping by name could split one group into two or merge two groups into one.

How it is used downstream:
In the intermediate layer, ads is joined to ad groups on ad_group_id to bring the ad group name into each row. The final model keeps the name so analysts can read the report without decoding IDs.

Test to add later:
unique and not_null on ad_group_id. The query I ran by hand is exactly what dbt's unique test runs on every build.

checking if ad_group and yes it came out clean and now to clean the table.
select count(ad_group_id)
from bronze_dev.facebook_ads.new_adgroup_de_randomized
group by ad_group_id
having count(ad_group_id) > 1

the cleaning :SELECT
    trim(ad_group_id) as ad_group_id,
    trim(ad_group_name) as ad_group_name,
   try_cast(trim(ad_group_updated_at) as timestamp) as ad_group_updated_at

FROM
    {{source('facebook_ads', 'ad_groups')}}

e)stg_facebook_campaigns


A campaign is the top level of an ad structure: the overall goal of the advertising (for example, sales or website traffic). It holds ad groups, which hold ads.
Columns: campaign_id (key), campaign_name (human label), campaign_updated_at (last change).
No parent column here; the link between a campaign and its ads goes through the ads table (campaign_id).
Cleaning: trim on id and name (ids kept as text), try_cast to timestamp for the update time.
Rule: group and join by campaign_id, never by name.
Built as a view; staging row count = raw row count.

this is the cleaning done here:
```sql

SELECT

&#x20;   trim(campaign\_id) as campaign\_id,

&#x20;   trim(campaign\_name) ascampaign\_name,

&#x20;   try\_cast (trim(campaign\_updated\_at) as timestamp) as campaign\_updated\_at

FROM

&#x20;   {{source('facebook\_ads', 'campaigns')}}

now to run dbt show and build this model, check if the row are current in terms of total.



**8. creating a description yml file.**

in this aspect, the description contain what the table and its columns are. for every table, a decription yaml file is created. an example for one of the tables below: 

version: 2



models:

&#x20; - name: stg\_facebook\_ads

&#x20;   description: >

&#x20;     Descriptive details of each Facebook ad, one row per ad. No performance

&#x20;     numbers. Links an ad to its campaign, ad group and account.

&#x20;   columns:

&#x20;     - name: ad\_id

&#x20;       description: Identifier of the ad. Unique in this model.

&#x20;     - name: campaign\_id

&#x20;       description: Campaign the ad belongs to. Joins to stg\_facebook\_campaigns.

&#x20;     - name: ad\_group\_id

&#x20;       description: Ad group the ad sits in. Joins to stg\_facebook\_ad\_groups.

&#x20;     - name: account\_id

&#x20;       description: Ad account that owns the ad. Joins to stg\_facebook\_accounts.

&#x20;     - name: ad\_name

&#x20;       description: Name of the ad (the creative). Label only, not a key.

&#x20;     - name: ad\_status

&#x20;       description: Current state of the ad, in upper case (ACTIVE, PAUSED, ARCHIVED or DELETED).

&#x20;     - name: ad\_updated\_at

&#x20;       description: When the record was last changed.



once this has been created and written, we run:

uv run dbt parse: this is a check that reads your project file or models and makes sure dbt can understand them. It doesn’t run any models or change any data. its more like checking if u correctly write your code with proper identation given.

i ran the dbt parse and i got this error:

uv run dbt parse

16:48:17  Running with dbt=1.12.5

16:48:31  Registered adapter: databricks=1.12.7

16:48:49  \[ERROR]: Encountered an error:

Compilation Error

&#x20; dbt found two sources with the name "facebook\_ads\_accounts".

&#x20; 

&#x20; Since these resources have the same name, dbt will be unable to find the correct resource

&#x20; when looking for source("facebook\_ads", "accounts").

&#x20; 

&#x20; To fix this, change the name of one of these resources:

&#x20; - source.cdc\_fb\_sp\_marketing.facebook\_ads.accounts (models/staging/snapchat\_ads/source.yml)

&#x20; - source.cdc\_fb\_sp\_marketing.facebook\_ads.accounts (models/staging/facebook\_ads/source.yml)



solutuion: lol, so i pasted the entire source.yml from facebook into snapchat because i want to just readjust it, not knowing dbt parse will catches that i have 2 same some source.yml file. so i cleaned the other one up. and it worked.



9 snapchat (source.yml)



just like facebbook, i defined the snapchat source.yml :

sources:

&#x20; - name: snapchat\_ads

&#x20;   database: bronze\_dev

&#x20;   description: data from snapchat platform (static)

&#x20;   schema: snapchat\_ads

&#x20;   config:

&#x20;     enabled: true

&#x20;     meta:

&#x20;       owner: "@nosadida"



&#x20;   tables:

&#x20;     - name: ads\_stats

&#x20;       identifier: snapchat\_ads\_stats

&#x20;       description: >

&#x20;         Daily performance per ad and country: spend, impressions, clicks, date,

&#x20;         and the currency of the spend (ad\_currency\_code, present on every row).

&#x20;         One row per ad per day per country (checked: no duplicates on

&#x20;         ad\_detail\_id + ad\_date + ad\_country). All columns are loaded as text.



&#x20;     - name: ad\_history

&#x20;       identifier: snapchat\_ads\_ad\_history\_new\_ad\_names

&#x20;       description: >

&#x20;         Descriptive details of Snapchat ads (the counterpart of the Facebook

&#x20;         ads table). A history table, so the same ad may appear in several

&#x20;         versions. TODO: list the columns and confirm the version column.



&#x20;     - name: ad\_group\_history

&#x20;       identifier: snapchat\_ads\_adgroup\_history\_new\_ad\_group\_names

&#x20;       description: >

&#x20;         Descriptive details of Snapchat ad groups. A history table, so the

&#x20;         same ad group may appear in several versions.

&#x20;         TODO: list the columns and confirm the version column.



&#x20;     - name: campaign\_history

&#x20;       identifier: snapchat\_ads\_campaign\_history\_new\_campaign\_names

&#x20;       description: >

&#x20;         Descriptive details of Snapchat campaigns. A history table, so the

&#x20;         same campaign may appear in several versions.

&#x20;         TODO: list the columns and confirm the version column. 



then i run dbt parse.

then i confirm if dbt could actually reach the snapchat tables;

uv run dbt show --inline "select \* from {{source('snaptchat\_ads', 'ads\_stats')}}"





10\. **Defining staging models(snapchat)**



**a)stg\_snapchat\_ads\_stats.sql**

Note: snapchat\_ads\_stats



What it is: the daily performance table for Snapchat. Each row is one ad, on one day, in one country, with its spend, impressions and clicks.

Columns: ad\_detail\_id (which ad), ad\_currency\_code (currency of the spend), ad\_country, ad\_spend, ad\_impressions, ad\_clicks, ad\_date (a plain yyyy-MM-dd), data\_src (always snapchat\_ads).

Quirks: 2,809 rows. Clicks has 111 text 'null' values, which become real NULLs through try\_cast. Impressions are never missing. Spend needs 6 decimals, so decimal(18,6).

Link column: stats holds only ad\_detail\_id, and every other level is reached by joining upward.



How the link columns relate (one-to-many)



From (the “one”)	To (the “many”)	Linked by

one account	many campaigns	campaign\_history.account\_id

one campaign	many ad groups	adgroup\_history.campaign\_id

one ad group	many ads	ad\_history.ad\_group\_id

one ad	many stats rows (one per day per country)	stats.ad\_detail\_id = ad\_history.ad\_id



Read in the other direction, each step is many-to-one, so a left join going upward never multiplies rows. The one exception is adgroup\_history, which has repeated ad\_group\_id values. We dedupe it first, or the join would duplicate stats rows.



Still to verify: that every ad\_detail\_id in stats exists in ad\_history.ad\_id. We’ll check that when we write the intermediate joins.

looking at the ads\_stats table, i discovered the columns are more compared to the ones on facebook, and this will strictly affect our union all. using union all means both table must have the same number of columns in the same order with compatiible parts. now, i have to go back and restructure facebook ads\_stats table by adding newer columns and cleaniing it. to add more columns, i used CTE below:

with source as (

&#x20;   select \*

&#x20;   from

&#x20;       {{source ("facebook\_ads", "ads\_stats" )}}

),



renamed as (

&#x20;   select

&#x20;       trim(ad\_id) as ad\_id,

&#x20;       trim(account\_id) as account\_id,

&#x20;       try\_cast (ad\_spend as decimal(18, 4)) as spend,

&#x20;       try\_cast(ad\_impressions as bigint) AS impressions,

&#x20;       try\_cast (ad\_clicks as bigint) AS clicks,

&#x20;       try\_cast (ad\_date as date) As ad\_date,

&#x20;       cast ('facebook\_ads' as string) AS data\_source,

&#x20;       cast (null as string) AS ad\_country



&#x20;   from

&#x20;       source

)



select

&#x20;   \*

from

&#x20;   renamed



now, i first confirm the fb ad\_stats table in databricks so that when i build the new fb stag\_ads\_stats model and i will what changed. once its done, i will do dbt show, to show me if it actually works and i will still confirm if the number of columns is correct. the reason behind adding this new column was: snap has a country and data\_source column, facebook doesnt have that, i thouhght about dropping both columns, but that is not good in implementing design structure. for future occurence, the country column might be greatly needed for analysis. I also thought abt dropping the data\_source column, but who wouldnt love to have a column where it can tell the source of a particular row when 2 tables are combined together? so i made my decision to keep it. Now, for the decison making, the country column for fb will be empty as NULL. for the data\_source column, looking at the cte above, i added that, this new columns will have 'facebook\_ads' just as snaptchat does. once this is done, i rebuild this table again.



\-- error: i just realized facebook has an account\_id column and snapchat doesn't have in this current table but in campaigns table for snapchat. ideally i wil to do the same thing i did for the ad\_country in here to. but i thought about this, all this cleaning on staging removed a great security for the source of truth in staging. so i have decided that to be consistent, i will have to add those new columns in intermediate. so i reverse what i earlier did for facebook : **cast (null as string) AS ad\_country.** But, i will leave this cast **('facebook\_ads' as string) AS data\_source**  just because the columns dont end up null, they actually have a value in it.



so reversing becomes:

with source as (

&#x20;   select \*

&#x20;   from

&#x20;       {{source ("facebook\_ads", "ads\_stats" )}}

),



renamed as (

&#x20;   select

&#x20;       trim(ad\_id) as ad\_id,

&#x20;       trim(account\_id) as account\_id,

&#x20;       try\_cast (ad\_spend as decimal(18, 4)) as spend,

&#x20;       try\_cast(ad\_impressions as bigint) AS impressions,

&#x20;       try\_cast (ad\_clicks as bigint) AS clicks,

&#x20;       try\_cast (ad\_date as date) As ad\_date,

&#x20;       cast ('facebook\_ads' as string) AS data\_source



&#x20;   from

&#x20;       source

)



select

&#x20;   \*

from

&#x20;   renamed

rebuidling once again.

**NOTE:** i will add both columns in int account\_id and ad\_country.



our final table layout is outght to look like this:

\#	Final column	From Facebook	From Snapchat

1	data\_source	data\_source	data\_source

2	ad\_id	ad\_id	ad\_detail\_id (renamed)

3	account\_id	account\_id	NULL placeholder

4	ad\_date	ad\_date	ad\_date

5	ad\_country	ad\_country (NULL)	ad\_country

6	currency	from accounts join	ad\_currency\_code (renamed)

7	spend	spend	spend

8	impressions	impressions	impressions

9	clicks	clicks	clicks



this is just for ads stats





now, moving back to snapchat:

SELECT

&#x20;   trim (ad\_detail\_id) as ad\_detail\_id,

&#x20;   upper(trim(ad\_currency\_code)) as ad\_currency\_code,

&#x20;   upper (trim (ad\_country)) as ad\_country,

&#x20;   try\_cast (trim (ad\_spend) as decimal(18,6)) as spend,

&#x20;   try\_cast (trim (ad\_impressions) as bigint) as impressions,

&#x20;   try\_cast (trim (ad\_clicks) as bigint) as clicks,

&#x20;   try\_cast(trim(ad\_date) as date) as ad\_date,

&#x20;   trim(data\_src) as data\_source

FROM 

&#x20;   {{source('snapchat\_ads', 'ads\_stats')}}



the cleaning done





b) **stg\_snapchat\_ad\_history:**

disvovery, finally understood what one to many means.

so in this table the columns are ad\_id, ad\_group\_id,ad\_name,ad\_detail\_updated at.

the ad\_id is a unique column in this table that reproduce the same group. that is three(3) the same group\_id could be in 3 different group\_id(unique). that is one to many. the ad\_histry just shows the history of the ads themselves. it has the same liking to ads table in facebook. now we uncover the truth in cleaning the table.

now we move to cleaning:

**findings:**

snaps dont have ad\_status but facebook have 

snaps have campaign\_id, account\_id but not in this table(ad\_history)select ad\_id, ad\_updated\_at from facebook\_side

union all

select ad\_id, ad\_updated\_at from snapchat\_side

snaps uses ad\_detail\_updated\_at but facebooks uses ad\_updated\_at, so i changed it to ad\_updated\_at, it is important for readability. union all doesnt know table names, it joins by postions eg :

select ad\_id, ad\_updated\_at from facebook\_side

union all

select ad\_id, ad\_updated\_at from snapchat\_side



so here is the transformation done here :

**SELECT**

&#x20;   **trim(ad\_id) as ad\_id,**

&#x20;   **trim(ad\_group\_id) as ad\_group\_id,**

&#x20;   **trim(ad\_name) as ad\_name,**

&#x20;   **try\_cast(trim(ad\_detail\_updated\_at) as timestamp ) as ad\_updated\_at**

**FROM**

&#x20;   **{{source('snapchat\_ads', 'ad\_history')}}**



now build the staging model : uv dbt run --select stg\_snapchat\_ad\_history

once build is succesfully, you can either query through dbt or databricks

for dbt: check how the table looks like: **uv run dbt show** --select **stg\_snapchat\_ad\_history**

for databricks: confirming the table total row is the same as the source; select count(ad\_id) from  dev\_godwin.dbt\_godwin.stg\_snapchat\_ad\_history.

NOTE: for consistency sake, recall from the ads\_stats table in snapchat, the ad\_id was used as ad\_detail\_id and i forgot to change it to ad\_id for consistency sake.

so i am rebuilding it;

from this;

SELECT

&#x20;   trim (ad\_detail\_id) as ad\_detail\_id,

&#x20;   upper(trim(ad\_currency\_code)) as ad\_currency\_code,

&#x20;   upper (trim (ad\_country)) as ad\_country,

&#x20;   try\_cast (trim (ad\_spend) as decimal(18,6)) as spend,

&#x20;   try\_cast (trim (ad\_impressions) as bigint) as impressions,

&#x20;   try\_cast (trim (ad\_clicks) as bigint) as clicks,

&#x20;   try\_cast(trim(ad\_date) as date) as ad\_date,

&#x20;   trim(data\_src) as data\_source

FROM 

&#x20;   {{source('snapchat\_ads', 'ads\_stats')}}



to this

SELECT

&#x20;   trim (ad\_detail\_id) as ad\_id,

&#x20;   upper(trim(ad\_currency\_code)) as ad\_currency\_code,

&#x20;   upper (trim (ad\_country)) as ad\_country,

&#x20;   try\_cast (trim (ad\_spend) as decimal(18,6)) as spend,

&#x20;   try\_cast (trim (ad\_impressions) as bigint) as impressions,

&#x20;   try\_cast (trim (ad\_clicks) as bigint) as clicks,

&#x20;   try\_cast(trim(ad\_date) as date) as ad\_date,

&#x20;   trim(data\_src) as data\_source

FROM 

&#x20;   {{source('snapchat\_ads', 'ads\_stats')}}



build now:  uv run dbt build --select stg\_facebook\_ads\_stats stg\_snapchat\_ads\_stats



our final table layout is ought to look like this.

\#	Final column	From Facebook				From Snapchat

1	ad\_id		ad\_id						ad\_id

2	ad\_name		ad\_name						ad\_name

3	ad\_group\_id	ad\_group\_id					ad\_group\_id

4	campaign\_id	campaign\_id (on the table)		via the ad group: ad\_group\_id → campaign\_id (join needed)

5	account\_id	account\_id (on the table)		via the campaign: campaign\_id → account\_id (join needed)

6	ad\_status	ad\_status				does not exist (NULL placeholder if we keep it)

7	ad\_updated\_at	ad\_updated\_at					ad\_updated\_at (renamed)



**C)stg\_snapchat\_ad\_groups**



This table confuses me alot  but i have finnaly gotten it. this is almost the same with facebook adgroup table but little difference.

firstly, the snapchat tables has the differences of having their parent columns in them, if u check the **snapchat\_ad\_groups** table,you will see the parent table (campaign) as campaign\_id in the ad\_group table. also  unique thing i found about ad\_group table is that it has previous history of the ad\_group. that means ad\_group could have a previous history in 2024 but updated in 2026. now, this is not duplicates but an history of how ad\_group as revovle. now, we dont need the previous histories rather than the latest history of the ad\_group. to do thos, we need to clean the table with row number and partition to get the latest row. the table has a surrogate key from previous model, i have decided to drop the column(surrogate column).

CTE is used for removing the older version and ranking the latest version higher. here is the synthax:



with ranked\_records as (

&#x20;   SELECT

&#x20;       trim(ad\_group\_id) as ad\_group\_id,

&#x20;       trim(campaign\_id) as campaign\_id,

&#x20;       trim(ad\_group\_name) as ad\_group\_name,

&#x20;       try\_cast (trim(ad\_group\_updated\_at) as timestamp) as ad\_group\_updated\_at,

&#x20;       ROW\_NUMBER() OVER(PARTITION BY ad\_group\_id ORDER BY  ad\_group\_updated\_at desc ) as rn

&#x20;   FROM

&#x20;       {{(source('snapchat\_ads', 'ad\_group\_history'))}}



)



SELECT

&#x20;       ad\_group\_id,

&#x20;       campaign\_id,

&#x20;       ad\_group\_name,

&#x20;       ad\_group\_updated\_at

FROM

&#x20;   ranked\_records

WHERE

&#x20;   rn=1

Now, the cleaning is done, we move to building the model:uv run dbt build --select stg\_snapchat\_ad\_groups.sql

once building is done, we confirm that the ad\_group\_id is unique with this query:



select

&#x20;   count(ad\_group\_id), ad\_group\_id

FROM

&#x20; dev\_godwin.dbt\_godwin.stg\_snapchat\_ad\_groups

group by 

&#x20; ad\_group\_id

having count(ad\_group\_id) > 1

then we confirm the number of rows are correct!



**Note: stg\_snapchat\_ad\_groups: the raw ad\_group\_history keeps every saved version of a group, so 3 groups showed up twice. They weren’t mistakes, just an older and a newer save of the same group. I numbered the versions per group, newest first (row\_number, desc), and kept number 1. Also trimmed the text columns, turned the timestamp from text into a real timestamp, and dropped \_surrogate\_key because it’s the provider’s version id and we don’t need it. 267 rows in, 264 out, no repeated ad\_group\_id.**



**d)stg\_snapchat\_campaigns.sql :**



The campaign table talks about the goal of the ads. that is all.

it has its unique id called campaign\_id. in a group table, we know that the group is a sub folder and the campaign table is a parent folder. so a camapign\_id in its sub folder is

one campaign\_id(appears in duplicate rows) to many group\_id.. example:



d\_group\_id	campaign\_id	ad\_group\_name

fc64f7b6…	fb4d60ee…	AllDevices\_FRA\_2026\_Conversions\_…

b09bcae7…	fb4d60ee…	AllDevices\_Global\_2025\_Awareness\_…

a21093ba…	fb4d60ee…	iOS\_NORDICS\_2020\_VideoViews\_…

87900df8…	fb4d60ee…	AllDevices\_POR\_2025\_VideoViews\_…

… 7 more	fb4d60ee…	…



the campaign\_id repeats so many times. and one group\_id is unique to one campaign\_id.

we use this intincts for campaign tables.

in the campaign table, it has its unique\_id but the account table is the parent, while the campaign is the child.

**so one account\_ids links to many campaign\_id.**

**many=unique**



writing the sql cleaning synthax:

SELECT

&#x20;   trim(campaign\_id) as campaign\_id,

&#x20;   trim(account\_id) as account\_id,

&#x20;   trim(campaign\_name) as campaign\_name

FROM

&#x20;   {{source('snapchat\_ads', 'campaign\_history')}}



now, building the model : uv run dbt build --select **stg\_snapchat\_campaigns.sql**

now, do the confirmations



\--findings:

after thorugh checking, i find out from campaign table that snapchat only used 2 account\_id. an account\_id means facebook or snapchat ads account not bank account.

so in the entire of snapchat, it has only 2 account\_id. so one account to many campagns. found out that 1 account had 107 campaigns the other had 19 campaigns.

now we build the desctiptive yml file for each of the snapchat models.this is how a descriptive summary looks like :

version: 2



models:

&#x20; - name: stg\_snapchat\_campaigns

&#x20;   description: >

&#x20;     One row per Snapchat campaign (109 rows). Cleaned copy of campaign\_history

&#x20;     with text trimmed. This is the only Snapchat table that carries account\_id,

&#x20;     so it is the link from a campaign up to its account.

&#x20;   columns:

&#x20;     - name: campaign\_id

&#x20;       description: Unique id of the campaign. Primary key of this table.

&#x20;     - name: account\_id

&#x20;       description: >

&#x20;         The account that owns the campaign. One account has many campaigns,

&#x20;         so this value repeats across rows (2 accounts in the data).

&#x20;     - name: campaign\_name

&#x20;       description: Name given to the campaign.



finnally all staging model is done, written and cleaned, we move to intermediate



**11) Definning intermediate model** : for int we will use ephemeral models. ephemeral models are just plain sql models. Unlike views, are just saved query. ephmeral models, ntohing gets stored in databricks. u just call it with dbt. the intermdediate model is where we do heavy transformations. we start joining here. staging had one rule, no joining.



\-- what to do: now for each table eg ads\_table, i will have to combine both snapchat and facebook together, making it one. before i start all this,

we need to go to our dbt\_project.yml to define the materialzation of our models:

**models:**

&#x20; **cdc\_fb\_sp\_marketing:**

&#x20;   **staging:**

&#x20;     **+materialized: view**

&#x20;   **intermediate:**

&#x20;     **+materialized: ephemeral**

&#x20;   **marts:**

&#x20;     **+materialized: table**

&#x20;this helps alot.

now we start:



###### a) **int\_facebook\_ads.sql**:

the two tables: 

stg\_facebook\_ads.sql + stg\_snapchat\_ad\_history.sql has to be combined to make int\_marketing\_ads.sql



stg\_facebook\_ads.sql has:

SELECT

&#x20;   trim(ad\_id) as ad\_id,

&#x20;   trim(campaign\_id) as campaign\_id,

&#x20;   trim(ad\_group\_id) as ad\_group\_id,

&#x20;   trim(account\_id) as account\_id,

&#x20;   trim(ad\_name) as ad\_name,

&#x20;   upper(trim(ad\_status) ) as ad\_status,

&#x20;   try\_cast (trim(ad\_updated\_at)  as timestamp) as ad\_updated\_at

FROM

&#x20;   {{source('facebook\_ads', 'ads')}}

stg\_snapchat\_ad\_history.sql has:

SELECT

&#x20;   trim(ad\_id) as ad\_id,

&#x20;   trim(ad\_group\_id) as ad\_group\_id,

&#x20;   trim(ad\_name) as ad\_name,

&#x20;   try\_cast(trim(ad\_detail\_updated\_at) as timestamp ) as ad\_updated\_at

FROM

&#x20;   {{source('snapchat\_ads', 'ad\_history')}}



our main job in intermediate per the business question, is to build the intermediate table from the most essential table that holds alot of the business question.

the table that holds that in facebook is the ads\_stats. the ads stats answers a lot of questions because it contains the numbers(clicks,impressions,spends). but it doesnt have the names(ad\_name,ad\_country etc). we got that from the facebook\_ads\_table per left join.

how the code below is written, first i got essential columns from the ads table with a cte(with statement). then from the cte, I left join the ads\_stats to the cte table. so i was able to get the names(from the ads table) and link it with the ad\_stats table. lastly, the facebook table doesnt have the country column as a whole but the snapchat does, for fututre scenario, the country column might appear in the facebook table so we have decided to leave it as null for now,. :

with ads as (

&#x20;   SELECT

&#x20;       ad\_id,

&#x20;       ad\_name, 

&#x20;       ad\_status, 

&#x20;       campaign\_id, 

&#x20;       account\_id,

&#x20;       ad\_group\_id

&#x20;   FROM

&#x20;       {{ref('stg\_facebook\_ads')}}

)



SELECT

&#x20;       s.ad\_id,

&#x20;       campaign\_id, 

&#x20;       s.account\_id,

&#x20;       ad\_group\_id,

&#x20;       spend,

&#x20;       impressions,

&#x20;       clicks,

&#x20;       ad\_name,

&#x20;       ad\_status,

&#x20;       cast(null as STRING) as ad\_country,

&#x20;       data\_source,

&#x20;       s.ad\_date

FROM

&#x20;   {{ref('stg\_facebook\_ads\_stats')}} as s

LEFT JOIN

&#x20;   ads as a on s.ad\_id = a.ad\_id



now, recall in emphemeral models, its just a stored query, we dont build, so we run the query,if we run dbt show, dbt will connect with datbricks print out the result on how terminal.

NOTE: This wont work for stg or mart because the model has to be built first before we can run dbt show.

now running dbt show for the emphemeral model:**uv run dbt show --select int\_marketing\_ads --limit 10**

**result:Previewing node 'int\_marketing\_ads':**

**| ad\_id              | campaign\_id        | account\_id        | ad\_group\_id        |  spend | impressions | ... |**

**| ------------------ | ------------------ | ----------------- | ------------------ | ------ | ----------- | --- |**

**| 6858573218250      | 6826670792450      | 10152913892614834 | 6826670792850      | 628.99 |       33107 | ... |**

**| 6837556542250      | 6615040755050      | 10152913892614834 | 6615040753250      |   1.98 |          74 | ... |**

**| 6863294200250      | 6778851431850      | 10152913892614834 | 6778851432450      |  19.69 |        3822 | ... |**

**| 120216208155320008 | 120214630698360008 | 10155363828439834 | 120214630698760008 |  12.66 |        1382 | ... |**

**| 6774305328450      | 6774305328650      | 10152913892614834 | 6774305350650      | 723.20 |       37916 | ... |**

**| 120216208152400008 | 120214630698410008 | 10155363828439834 | 120214630698510008 |   9.18 |         219 | ... |**

**| 120216208837180008 | 120214630698410008 | 10155363828439834 | 120214630698510008 |  44.14 |        1687 | ... |**

**| 6770658540250      | 6615040755050      | 10152913892614834 | 6615040753250      | 819.72 |       50835 | ... |**

**| 6969644890050      | 6615040755050      | 10152913892614834 | 6615040753250      |   1.26 |          29 | ... |**

**| 6858584236850      | 6858584236450      | 10152913892614834 | 6858584258650      |  15.97 |         988 | ... |**

the reuslt shows how the int model will look like.

you might wonder how the columns are not complete, dbt will only show 5 columns when u request everything.

but if u want to be specific in terms of the columns :

uv run dbt show --inline "select ad\_date, data\_source, ad\_country, ad\_name, ad\_status from {{ref('int\_marketing\_ads')}}" 



output:

**Previewing inline node:**

**|    ad\_date | data\_source  | ad\_country | ad\_name              | ad\_status |**

**| ---------- | ------------ | ---------- | -------------------- | --------- |**

**| 2025-04-30 | facebook\_ads |            | motion-co\_story\_l... | PAUSED    |**

**| 2025-05-16 | facebook\_ads |            | partner-y\_image\_t... | ARCHIVED  |**

**| 2025-05-02 | facebook\_ads |            | ugc-hub\_static-gi... | ARCHIVED  |**

**| 2025-05-12 | facebook\_ads |            | inhouse\_carousel\_... | ARCHIVED  |**

**| 2025-05-15 | facebook\_ads |            | partner-y\_reel\_po... | ARCHIVED  |**





Now, just to be sure, we count the number of rows just be sure the rows hasnt changed.:

**uv run dbt show --inline "select count(\*) as total\_rows from {{ ref('int\_marketing\_ads') }}"** 



output:Previewing inline node:

| total\_rows |

| ---------- |

|      92300 |

so the total row matches.

next we check if campaign\_id is null. if there is a null, it will be a big problem.

**uv run dbt show --inline "select count(\*) as total\_rows from {{ ref('int\_marketing\_ads') }} where campaign\_id is null"**

**output:**

**| total\_rows |**

**| ---------- |**

**|          0 |**





Now, we dont have campaign name yet. but we can get it from the campaign table. we need a left join referecing the ads\_stats+ads table with the campaign table.

we join by campaign\_id since the ads table have that key. synthax below:



**with ads as (**

&#x20;   **SELECT**

&#x20;       **ad\_id,**

&#x20;       **ad\_name,** 

&#x20;       **ad\_status,** 

&#x20;       **campaign\_id,** 

&#x20;       **account\_id,**

&#x20;       **ad\_group\_id**

&#x20;   **FROM**

&#x20;       **{{ref( 'stg\_facebook\_ads' )}}**

**)**



**SELECT**

&#x20;       **s.ad\_id,**

&#x20;       **a.campaign\_id,** 

&#x20;       **s.account\_id,**

&#x20;       **ad\_group\_id,**

&#x20;       **spend,**

&#x20;       **impressions,**

&#x20;       **clicks,**

&#x20;       **ad\_name,**

&#x20;       **campaign\_name,**

&#x20;       **ad\_status,**

&#x20;       **cast(null as STRING) as ad\_country,**

&#x20;       **data\_source,**

&#x20;       **s.ad\_date**

**FROM**

&#x20;   **{{ref('stg\_facebook\_ads\_stats')}} as s**

**LEFT JOIN**

&#x20;   **ads as a on s.ad\_id = a.ad\_id**

**LEFT JOIN**

&#x20;    **{{ref ('stg\_facebook\_campaigns') }} as c on a.campaign\_id = c.campaign\_id**



now running dbt show for the emphemeral model:**uv run dbt show --select int\_marketing\_ads --limit 10**



**| ad\_id              | campaign\_id        | account\_id        | ad\_group\_id        |  spend | impressions | ... |**

**| ------------------ | ------------------ | ----------------- | ------------------ | ------ | ----------- | --- |**

**| 6858573218250      | 6826670792450      | 10152913892614834 | 6826670792850      | 628.99 |       33107 | ... |**

**| 6837556542250      | 6615040755050      | 10152913892614834 | 6615040753250      |   1.98 |          74 | ... |**

**| 6863294200250      | 6778851431850      | 10152913892614834 | 6778851432450      |  19.69 |        3822 | ... |**

**| 120216208155320008 | 120214630698360008 | 10155363828439834 | 120214630698760008 |  12.66 |        1382 | ... |**

**| 6774305328450      | 6774305328650      | 10152913892614834 | 6774305350650      | 723.20 |       37916 | ... |**

**| 120216208152400008 | 120214630698410008 | 10155363828439834 | 120214630698510008 |   9.18 |         219 | ... |**

**| 120216208837180008 | 120214630698410008 | 10155363828439834 | 120214630698510008 |  44.14 |        1687 | ... |**

**| 6770658540250      | 6615040755050      | 10152913892614834 | 6615040753250      | 819.72 |       50835 | ... |**

**| 6969644890050      | 6615040755050      | 10152913892614834 | 6615040753250      |   1.26 |          29 | ... |**

**| 6858584236850      | 6858584236450      | 10152913892614834 | 6858584258650      |  15.97 |         988 | ... |**



confriming rows count : **uv run dbt show --inline "select count(\*) from {{ ref('int\_marketing\_ads') }}"**

output: 92,300

confirming the added campaign name is not null : **uv run dbt show --inline "select count(\*) from {{ ref('int\_marketing\_ads') }} where campaign\_name is null"**

output: 0



Now, we don't have the currency column yet. we need it to know the actual currency(conversion) that was spent.

the currency column appears to be in facebook account table. here is the synthax:

**with ads as (**

&#x20;   **SELECT**

&#x20;       **ad\_id,**

&#x20;       **ad\_name,** 

&#x20;       **ad\_status,** 

&#x20;       **campaign\_id,** 

&#x20;       **account\_id,**

&#x20;       **ad\_group\_id**

&#x20;   **FROM**

&#x20;       **{{ref('stg\_facebook\_ads')}}**

**)**



**SELECT**

&#x20;       **s.ad\_id,**

&#x20;       **a.campaign\_id,** 

&#x20;       **s.account\_id,**

&#x20;       **ad\_group\_id,**

&#x20;       **spend,**

&#x20;       **impressions,**

&#x20;       **clicks,**

&#x20;       **ad\_name,**

&#x20;       **campaign\_name,**

&#x20;       **ad\_status,**

&#x20;       **currency,**

&#x20;       **cast(null as STRING) as ad\_country,**

&#x20;       **data\_source,**

&#x20;       **s.ad\_date**

**FROM**

&#x20;   **{{ref('stg\_facebook\_ads\_stats')}} as s**

**LEFT JOIN**

&#x20;   **ads as a on s.ad\_id = a.ad\_id**

**LEFT JOIN**

&#x20;    **{{ref ('stg\_facebook\_campaigns') }} as c on a.campaign\_id = c.campaign\_id**

**LEFT JOIN**

&#x20;   **{{ref ('stg\_facebook\_accounts')}} as cu on s.account\_id = cu.account\_id**



now running dbt show for the emphemeral model:

&#x20;**uv run dbt show --inline "select count(\*) as n, currecncy from {{ ref('int\_marketing\_ads') }} group by currency" this just checks how the currency column looks like.**

**count : uv run dbt show --inline "select count(\*) from {{ref ('int\_marketing\_ads') }}"**

**missing currency :uv run dbt show --inline "select count(\*) from {{ ref('int\_marketing\_ads') }} where currency is null"**

now, this is done,

I want rearrange this table to this order.

&#x09;Column	Facebook source

1	data\_source	stats

2	ad\_id		stats

3	account\_id	stats

4	campaign\_id	ads

5	campaign\_name	campaigns

6	ad\_group\_id	ads

7	ad\_name		ads

8	ad\_status	ads

9	ad\_date		stats

10	ad\_country	NULL placeholder

11	currency	accounts

12	spend		stats

13	impressions	stats

14	clicks		stats



the order is very important when doing union all with snapchat.



###### **b) int\_snapchat\_ads.sql**  



snapchat follows the same way of facebook, the stats table is the root,he lookups are left-joined on, and the row count must never change. The difference is that the lookups form a chain, because the campaign and the account are further away.

this is the root and how it looks like:

stats ──ad\_id──▶ ad\_history ──ad\_group\_id──▶ ad\_groups ──campaign\_id──▶ campaigns

(root)           (ad\_name,                   (campaign\_id)               (account\_id,

&#x20;                 ad\_group\_id)                                            campaign\_name)



recall that snapchat table does not have ad\_status column but facebook does. i keep the column for future reference. so snapchat part will end up as null.

now here is the cleaning:

SELECT

&#x20;   s.data\_source,

&#x20;   s.ad\_id,

&#x20;   c.account\_id,

&#x20;   g.campaign\_id,

&#x20;   c.campaign\_name,

&#x20;   h.ad\_group\_id,

&#x20;   h.ad\_name,

&#x20;   cast(null as STRING) as ad\_status,

&#x20;   s.ad\_date,

&#x20;   s.ad\_country,

&#x20;   s.ad\_currency\_code as currency,

&#x20;   s.spend,

&#x20;   s.impressions,

&#x20;   s.clicks

FROM

&#x20;   {{ ref('stg\_snapchat\_ads\_stats') }} as s



LEFT JOIN 

&#x20;   {{ ref('stg\_snapchat\_ad\_history') }} as h ON s.ad\_id = h.ad\_id



LEFT JOIN

&#x20;    {{ ref('stg\_snapchat\_ad\_groups') }} as g ON h.ad\_group\_id = g.ad\_group\_id



LEFT JOIN

&#x20;   {{ ref('stg\_snapchat\_campaigns') }} as c ON g.campaign\_id = c.campaign\_id



once the int for snapchat is done, i made sure i check the correct number of rows are okay and others;

* row checks : **uv run  dbt show  --inline "select count(\*) from {{ ref('int\_snapchat\_ads') }}" output : 2809** 
* group\_id check making sure no null is involved : **uv run dbt show --inline "select ad\_group\_id from {{ ref('int\_snapchat\_ads') }} where ad\_group\_id is null" output: 0 rows**
* campaign\_id check making sure no null is involved : **uv run dbt show --inline "select campaign\_id from {{ ref('int\_snapchat\_ads') }} where ad\_group\_id is null":output: 0 rows**
* account\_id: uv run dbt show --inline "select account\_id from {{ ref('int\_snapchat\_ads') }} where account\_id is null" output: 0rows
* campaign\_name: uv run dbt show --inline "select campaign\_name from {{ ref('int\_snapchat\_ads') }} where campaign\_name is null": 0 rows



finally: int\_snapchat\_ads: stats (root) → ad\_history (ad\_group\_id, ad\_name) → ad\_groups (campaign\_id) → campaigns (account\_id, campaign\_name). Same 14 columns in the same order as the Facebook half. ad\_status is an empty text column (Snapchat has none); currency comes from the stats table itself. Checked: 2,809 rows (same as stats), 0 rows missing group, campaign, account or campaign name. All rows have data\_source = snapchat\_ads and currency = EUR.



###### **c)int\_marketing\_ads.sql**:

this is where we combine the 2 intermediate table to form one table and each columns holds snapchat and facebook identities

facebook has 92,300 rows while snapchat has 2809 rows **total: 95,109**



Now the union all synthax:

select 

&#x09;\*

FROM

&#x09;{{ ref('int\_facebook\_ads') }}



union all



select 

&#x09;\*

FROM

&#x09;{{ ref('int\_snapchat\_ads') }}



uv run dbt show --inline  'select \* from {{ ref('int\_marketing\_ads') }}'



\--error: godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting\_data\_platform/cdc\_fb\_sp\_marketing$ 

uv run dbt show --inline  'select \* from {{ ref('int\_marketing\_ads') }}'

21:00:01  Running with dbt=1.12.5

21:00:13  Registered adapter: databricks=1.12.7

21:00:30  \[WARNING]: Configuration paths exist in your dbt\_project.yml file which do not apply to any resources.

There are 1 unused configuration paths:

\- models.cdc\_fb\_sp\_marketing.marts

21:00:31  \[ERROR]: Error while parsing node: inline\_query

The name argument to ref() must be a string, got <class 'dbt\_common.clients.jinja.create\_undefined.<locals>.Undefined'>

21:00:31  \[ERROR]: Encountered an error:

Error parsing inline query



\--solution : the outer quotes around select should be " uv run dbt show --inline  "s

elect \* from {{ ref('int\_marketing\_ads') }}"



now confirming the checks

* Row check:  **uv run dbt show --inline "select count(\*) as total\_row from {{ ref('int\_marketing\_ads') }}"  :95109 rows**, this confirms that the number of rows we are correct.
* checking snapchat rows: uv run dbt show --inline "select data\_source,ad\_date, ad\_country, currency, spend, impressions, clicks from {{ ref('int\_marketing\_ads') }}

output : Previewing inline node:

| data\_source  |    ad\_date | ad\_country | currency |   spend | impressions | ... |

| ------------ | ---------- | ---------- | -------- | ------- | ----------- | --- |

| snapchat\_ads | 2024-01-23 | DE         | EUR      | 48.174… |       30475 | ... |

| snapchat\_ads | 2024-06-29 | DE         | EUR      | 55.256… |       21341 | ... |

| snapchat\_ads | 2024-12-02 | DE         | EUR      |  0.865… |          63 | ... |

| snapchat\_ads | 2024-01-05 | CH         | EUR      |  2.789… |        2286 | ... |

| snapchat\_ads | 2024-01-09 | CH         | EUR      |  2.178… |        3371 | ... |



* checking how the two platforms differentiate each other: **uv run dbt show --inline "select data\_source, count(\*) as n from {{ ref('int\_marketing\_ads') }} group by data\_source"**

output: Previewing inline node:

| data\_source  |     n |

| ------------ | ----- |

| facebook\_ads | 92300 |

| snapchat\_ads |  2809 |



uv run dbt show --inline "select count(\*) as n, max(ad\_date), min(ad\_date), currency, data\_source from {{ ref('int\_marketing\_ads') }}"





###### **12) SEEDS**

&#x20;seeds are static, csv file. when u run dbt seed, dbt builds a physical, permanent table directly in the data wh. the static file is first stored inside the seeds/ directory of ur dbt projet, when u execute dbt seed, dbt reads the file and uploads it as a parmanent physical table directly in the warehouse.

It is designed to handle small, rarely changing lookup datasets that you want to version-control in Git alongside your data models

Before we begin, we confirm to know the earlieast and latest dates of the spend currency, this will help in trajectory how the seed file will look like. so that our seed file doesnt look too outdated and not up to date. the synthax for this :

**uv run dbt show --inline "select count(\*) as n, max(ad\_date), min(ad\_date), currency, data\_source from {{ ref('int\_marketing\_ads') }}"**



output:

Previewing inline node:

|     n | max(ad\_date) | min(ad\_date) | currency | data\_source  |

| ----- | ------------ | ------------ | -------- | ------------ |

| 26088 |   2025-09-17 |   2025-01-01 | EUR      | facebook\_ads |

| 66212 |   2025-12-31 |   2025-01-01 | USD      | facebook\_ads |

|  2809 |   2024-12-02 |   2024-01-01 | EUR      | snapchat\_ads |



looking at this, when bringing the rate seed file, the earliest date must be around 2024-01-01 and the latest date must be around 2025-12-31.

now we download the seed file..

file has been downloaded:

next is to create the csv file in vscode.

touch seeds/exchange\_rates.csv.

once file has been created, i type this clean header(column names) :rate\_month,currency,rate\_to\_usd

then i pasted the csv data into the file.



Now, the next step is to run :

**uv run dbt seed :** this runs the data into databricks.

now, i go confirm on databricks. also, in my terminal, i ran this code to confirm if the csv table already exists:

**uv run dbt show --inline "select \* from {{ ref('exchange\_rates') }}".**



Now, we combined the union table to the seed table using and left join 



**WITH un AS**

**(**

&#x20;       **SELECT**

&#x20;       **\***

&#x20;   **FROM**

&#x20;       **{{ ref('int\_facebook\_ads') }}**



&#x20;   **union all**



&#x20;   **SELECT** 

&#x20;       **\***

&#x20;   **FROM**

&#x20;       **{{ ref('int\_snapchat\_ads') }}**

**)**



**SELECT**

&#x20;   **\*,**

&#x20;  **(rate\_to\_usd \* spend) as spend\_usd**

**FROM**

&#x20;   **un as u**

**LEFT JOIN**

&#x20;   **{{ ref('exchange\_rates') }} as ex ON u.ad\_date = ex.rate\_month and u.currency = ex.currency**



looking above, this won't work. if u check the ad\_date, they had several days in a particular month eg(1-30 days) between. so it wont connect with currency column in exchange rate because the dates are rounded up eg 2024-01-01. so i will have to find a way to round up those date in the ad\_table as a new column. to do that, we DATE\_TRUNC, it rounds up the date to the start of the month.

exameple : from this 2024-01-23 to this 2024-01-01. date\_trunc('month', ad\_date) cut back to the start of the month. ad\_date is the column. lastly, the ad\_date is in timestamp, once the date\_trunc works, we expect the cast to convert the timestamp to date. why? because, the exchange table uses date not timestamp.

for the table connection to work, we need to connect the both tables currencies too. WHY? what makes the coversion rate works is the time and currency. joining with just time will cause problem with the table as a row in the int table will feel that the exchange table connect with just date and brings two different currency in the same date 2024-01-01,EUR,1.0905 2024-01-01,USD,1 to multiply with one row, so we join with both with data and currency

\-- solution



WITH un AS

(

&#x20;       SELECT

&#x20;       \*

&#x20;   FROM

&#x20;       {{ ref('int\_facebook\_ads') }}



&#x20;   union all



&#x20;   SELECT 

&#x20;       \*

&#x20;   FROM

&#x20;       {{ ref('int\_snapchat\_ads') }}

**)**

**,**



with\_month AS (

&#x09;SELECT

&#x09;	\*,

&#x09;	CAST(DATE\_TRUNC('month', ad\_date) AS DATE) as ad\_month



&#x09;FROM

&#x09;	

&#x09;	un

)

&#x20;



SELECT

&#x09;wm.\*,

&#x09;ex.rate\_to\_usd,

&#x09;(wm.spend \* ex.rate\_to\_usd) as spend\_usd

FROM

&#x09;with\_month as wm



LEFT JOIN

&#x09;{{ ref('exchange\_rates') }} as ex ON wm.ad\_month = ex.rate\_month and wm.currency = ex.currency





* now, we check if the spend and spend\_usd are intact and nothing is null : **uv run dbt show --inline "select count(\*) as missing\_rate from {{ ref('int\_marketing\_ads') }} where spend\_usd is null and spend is not null"**



* we check for the total number of rows
* **uv run dbt show --inline "select currency, ad\_month, spend, rate\_to\_usd, spend\_usd from {{ ref('int\_marketing\_ads') }} where currency = 'EUR'" --limit 3** : we confirm we have cleaned and neatly tablea nd it works







###### **13) MARTS (fct\_marketing\_spend)**

The Mart is our final, production, ready table. this is what the analyst will see and query. The mart model will be stored as a physical model in databricks

Now, I query out the most important columns for the business questions. examples of the columns i neeed (impresssions,clicks, campaign\_name, campaign\_id, etc).



**--What to do:** Since I am calling the columns from int model , writing the select statement is straight forward. but one more cleaning i need to make. i dont want the business users to see the column as **data\_source but platform.** I also want each of the rows of the data\_source column to be standard example facebook\_ads turn into facebook, snapchat\_ads turned into snapchat, for this, A CASE statement is used. here is the query for all this:



SELECT

&#x20;   CASE

&#x20;   	WHEN data\_source = 'facebook\_ads' THEN facebook

&#x20;   	WHEN data\_source = 'snapchat\_ads' THEN snapchat

&#x20;   END as platform,  

&#x20;   ad\_date,

&#x20;   account\_id,

&#x20;   campaign\_id,

&#x20;   campaign\_name,

&#x20;   ad\_id,

&#x20;   ad\_name,

&#x20;   ad\_country,

&#x20;   spend\_usd,

&#x20;   impressions,

&#x20;   clicks

FROM

&#x20;   **{{ ref('int\_marketing\_ads') }}     ----(a)**



for fun, this is similar to wrting python code like this:

**As Python, which is probably the if statement you know:**



**python**

**if data\_source == "facebook\_ads":**

&#x20;   **platform = "facebook"**

**elif data\_source == "snapchat\_ads":**

&#x20;   **platform = "snapchat"**

**else:**

&#x20;   **platform = None**



before building, i take pip on how the data will look like by running:

uv run dbt show --inline "select \* from {{ ref('fct\_marketing\_spend') }}"



this will work without build, because fct\_marketing\_spend model name for marts, is just referncing the stored ephemaral model(a).

output:

Previewing node 'fct\_marketing\_spend':

| platform |    ad\_date | account\_id        | campaign\_id        | campaign\_name        | ad\_id              | ... |

| -------- | ---------- | ----------------- | ------------------ | -------------------- | ------------------ | --- |

| facebook | 2025-04-30 | 10152913892614834 | 6826670792450      | deu\_app\_paid-soci... | 6858573218250      | ... |

| facebook | 2025-05-16 | 10155363828439834 | 120214630698410008 | fra\_ios\_paid-soci... | 120216208152400008 | ... |

| facebook | 2025-05-02 | 10152913892614834 | 6615040755050      | fra\_app\_influence... | 6969644890050      | ... |

| facebook | 2025-05-12 | 10155363828439834 | 120214630698410008 | fra\_ios\_paid-soci... | 120216208837180008 | ... |

| facebook | 2025-05-15 | 10152913892614834 | 6615040755050      | fra\_app\_influence... | 6837556542250      | ... |



Now we build the mart table:

* **Build: uv run dbt build --select fct\_marketing\_spend**
* **platform check :uv run dbt show --inline "select count(\*) as n, platform from {{ ref('fct\_marketing\_spend') }}"**

**output :** 

Previewing inline node:

|     n | platform |

| ----- | -------- |

| 92300 | facebook |

|  2809 | snapchat |





###### 14\) **CTR, CPC, CPM**



a) CPM : The amount an advertiser pays for 1000 impressions. That means after every  1000 impressions(1000 people saw the ads), how much was the advertiser billed with?

* FORMULAR : CPM = (spend/impressions \*1000)

lets say a user posted an ad for 200 dollars and he has 2,000 impressions, to get the amount a advertiser pays for 1000 impressiona is :

CPM = (200/2000 \* 1000) = 100 dollars. so the user pays 100 dollars for 1,000 people to see the ads (1000 impressions)



b) CTR : This helps to get the percentage of people who saw the ads (impressions) and actually clicked it (clicks).

* FORMULAR : CTR = (clicks/impressions \*100)

lets say you have 2000 impressions and 20 people clicked it, to get the percentage of people that clicked it :

CTR = (20/2000 \* 100) = 1%/ that is out of 100% of impressions(people), 1% clicked ur ads.



c) CPC : this involves the exact amount u pay every single time someone clicks ur ads.

* FORMULAR : CTR = Total Ad spend/ Total clicks

lets say the ad ur posted cost 500 dollars and the total number of people that clicks it is 300.

CTR = 500/300 = 1.6 dollars, so every person that clicked, u spent 1.6dollars



now before i move, lets talk about nullif a little in sql.

NULLIF is a conditional function that compares 2 values and returns null if they are equal. if the two values are not equal, it returns the first value.

per checking our tables, we found out that some impressions, clicks were zero. for example,if an impression was 10 or anay number and clicks was 0, if we want to calculate CTR for example :

10/0\*100 = this will produce an error and the sql query wont work. to make this work, we do nullif. example nullif(clicks,0)..says if clicks is zero, give me null there in that row, but if its a number, go ahead and continue with the impression. for example in our model, to fuind ctr :

(clicks/ nullif(impression,0) \*100 ) as ctr once impression appears to be zero in the row, give it null.

so now, recalling our fct marketting model :



SELECT

&#x20;   CASE 

&#x20;       WHEN data\_source ='facebook\_ads' THEN 'facebook'

&#x20;       WHEN data\_source = 'snapchat\_ads' THEN 'snapchat'

&#x20;   END as platform,

&#x20;   ad\_date,

&#x20;   account\_id,

&#x20;   campaign\_id,

&#x20;   campaign\_name,

&#x20;   ad\_id,

&#x20;   ad\_name,

&#x20;   ad\_country,

&#x20;   spend\_usd,

&#x20;   impressions,

&#x20;   clicks

FROM

&#x20;   {{ ref('int\_marketing\_ads') }}



now inputting those calculations



**SELECT**

&#x20;   **CASE**

&#x20;       **WHEN data\_source ='facebook\_ads' THEN 'facebook'**

&#x20;       **WHEN data\_source = 'snapchat\_ads' THEN 'snapchat'**

&#x20;   **END as platform,**

&#x20;   **ad\_date,**

&#x20;   **account\_id,**

&#x20;   **campaign\_id,**

&#x20;   **campaign\_name,**

&#x20;   **ad\_id,**

&#x20;   **ad\_name,**

&#x20;   **ad\_country,**

&#x20;   **spend\_usd,**

&#x20;   **impressions,**

&#x20;   **clicks,**

&#x20;   **(clicks/nullif(impressions,0)) as ctr,**

&#x20;   **(spend\_usd/nullif(clicks,0)) as cpc,**

&#x20;   **(spend\_usd/nullif(impressions,0) \* 1000) as cpm**

&#x20;   

**FROM**

&#x20;   **{{ ref('int\_marketing\_ads') }}**



Now, running the 

we prview : **uv run dbt show --inline "select \* from {{ ref('fct\_marketing\_spend') }}"**

**output : Previewing inline node:**

**| platform |    ad\_date | account\_id           | campaign\_id          | campaign\_name        | ad\_id                | ... |**

**| -------- | ---------- | -------------------- | -------------------- | -------------------- | -------------------- | --- |**

**| snapchat | 2024-01-23 | a26ad22c-54b9-453... | e137ecc6-578a-4e0... | CMP\_2024\_Global\_C... | e5e34a95-94e6-47a... | ... |**

**| snapchat | 2024-06-29 | a26ad22c-54b9-453... | 364580e0-1756-417... | CMP\_2023\_ITA\_CONV... | 21760a24-7818-43a... | ... |**

**| snapchat | 2024-12-02 | a26ad22c-54b9-453... | 3f87d61b-537b-4e2... | CMP\_2023\_ITA\_CONV... | 5eaac9ae-38fd-403... | ... |**

**| snapchat | 2024-01-05 | a26ad22c-54b9-453... | e137ecc6-578a-4e0... | CMP\_2024\_Global\_C... | 782049c5-671b-47f... | ... |**

**| snapchat | 2024-01-09 | a26ad22c-54b9-453... | a53f5557-134e-4d6... | CMP\_2023\_DACH\_CON... | b7f48a70-a76a-47a... | ..**





rebuilding the model : **uv run dbt build --select fct\_marketing\_spend**

**output :  Completed successfully**



count to confirm rows are not missing : **uv run dbt show --inline "select count(\*) as n, platform from {{ ref('fct\_marketing\_spend') }} group by platform"**

output : Previewing inline node:

|     n | platform |

| ----- | -------- |

| 92300 | facebook |

|  2809 | snapchat |







###### **15) Surrogate Key** : 

5\) Surrogate key (ad\_key): fct\_marketing\_spend is almost done, but it needs one column that makes every row unique. Each source table has its own unique id. The Facebook stats table is unique by ad\_id + ad\_date. Can I use that for the final table? No. The Snapchat stats table also has a country column, so the same ad can run in 2 countries on the same day. That means the Snapchat stats table is unique by ad\_id + ad\_date + ad\_country. When I combined the two tables, Facebook got a country column too, and it is NULL for every Facebook row. So the key for the final table is data\_source + ad\_id + ad\_date + ad\_country, with the NULL country replaced by n/a, and I hash it with md5. I add data\_source so a Facebook ad and a Snapchat ad can never clash, and I use md5 so I have one column that dbt can test for unique and not\_null.



Example of why ad\_id + ad\_date alone is not enough (made-up numbers):



platform	ad\_id	ad\_date	ad\_country	spend\_usd

facebook	111	2024-01-05	(empty)	20

facebook	111	2024-01-06	(empty)	25

snapchat	900	2024-01-05	DE	10

snapchat	900	2024-01-05	CH	4



The last 2 rows are the same ad on the same day. With only ad\_id + ad\_date they would look like duplicates, but they are two real rows.

we would still confirm via dbt test that the rows are unique.



now, our four keys

data\_source,ad\_id, ad\_country, ad\_date.

before we combined these four columns :

* each has to be in string. surrogate accepts strings. the date column has to be cast to string.
* now for the ad\_country, facebook dont have a country row and its represented by null. null isnt  a string but a null.



now to solve this 2 issues

* cast(ad\_date as string): change the date type to string
* coalesce(ad\_country, 'n/a') : use country column for snapchat as ad\_country but if there is a NULL(facebook) 'use n/a' . that is if there is a null value in ad\_country, return 'n/a'



* concat\_ws :now we need to combine this 4 columns together: we use concat\_ws. concat\_ws stands for concatenate with seperator. it is used to join two or more strings into a single string. inserting a seperator between each of the strings. CONCAT\_WS(separator, string1, string2,......
* md5 : MD5 stands for "Message-Digest Algorithm 5." It is a widely used cryptographic function that takes an input (a string of text, a password, or an entire file) and converts it into a fixed-length, 32-character hexadecimal string (128-bit hash value).





so now, now synthax to get our unique ad\_key...



**select** 

&#x09;**\*,**

&#x09;**(concat\_ws('|', cast(ad\_date as string), coalesce( ad\_country, 'n/a'), ad\_id, data\_source)) as ad\_key**



this is how we create the surrogate key. now inputting all this into fct\_marketing model :





**SELECT**

&#x20;   **(concat\_ws('|', cast(ad\_date as string), coalesce( ad\_country, 'n/a'), ad\_id, data\_source)) as ad\_key,**

&#x20;   **CASE**

&#x20;       **WHEN data\_source ='facebook\_ads' THEN 'facebook'**

&#x20;       **WHEN data\_source = 'snapchat\_ads' THEN 'snapchat'**

&#x20;   **END as platform,**

&#x20;   **ad\_date,**

&#x20;   **account\_id,**

&#x20;   **campaign\_id,**

&#x20;   **campaign\_name,**

&#x20;   **ad\_id,**

&#x20;   **ad\_name,**

&#x20;   **ad\_country,**

&#x20;   **spend\_usd,**

&#x20;   **impressions,**

&#x20;   **clicks,**

&#x20;   **(clicks/nullif(impressions,0)) as ctr,**

&#x20;   **(spend\_usd/nullif(clicks,0)) as cpc,**

&#x20;   **(spend\_usd/nullif(impressions,0) \* 1000) as cpm**

&#x20;

**FROM**

&#x20;   **{{ ref('int\_marketing\_ads') }}**



rebuilding the model : **uv run dbt build --select fct\_marketing\_spend**

**output : Completed successfully**

confirming the ad\_key is unique : **uv run dbt show --inline "select count(ad\_key) as n from {{ ref('fct\_marketing\_spend') }}"**

output: 

|     n |

| ----- |

| 95109 |

&#x20;this confirms that each row has no null value, now:

confirming if ad\_id actually is unique... both rows should give me the same values

: **uv run dbt show --inline "select count(\*) as total\_rows, count(distinct ad\_key) as distinct\_keys from {{ ref('fct\_marketing\_spend') }}"**

output:

| total\_rows | distinct\_keys |

| ---------- | ------------- |

|      95109 |         95109 |





###### 

###### 

###### **16) dbt\_test :**

This is an automated check for your data, instead of manually looking at each table and making sure nothing is broken, dbt test runs automated checks to ensure your data is clean, correct and follow business rules.



the two types of test

a) generic : this is a quick pre made rules u write in ur configuration file. for example we will building a fct\_marketing yaml file and writing a text along with it. examples of the tests unique, not\_null(no row is empty), accepted\_values (the value must be the only to appear in that column, example : platform is facebook or snapchat, seed currency is EUR or USD), relationships(every value exists in another table, eg every Facebook stats ad\_id exists in the ads table)



b) singular :  Custom SQL queries you write yourself. If your query finds even a single bad row, the test fails.(must have a number. that is, no empty or null spend, lastly, seed has one rate per month and currency, no duplicate month and currencry pair.







**Here is the generic test:**

&#x20;we create a file called : fct\_marketing\_spend.yml



version: 2

models:

&#x20; - name: fct\_marketing\_spend

&#x20;   description: >

&#x20;     One row per ad per day per country, for Facebook and Snapchat together,

&#x20;     with spend in USD. Built for analysts, BI tools and the AI agent.

&#x20;     To get CTR, CPC or CPM for a bigger group, sum clicks, impressions and

&#x20;     spend first and then divide. Do not average the per-row ratios.



&#x20;   columns:

&#x20;     - name: ad\_key

&#x20;       description: Unique id of the row (source, ad id, date and country combined).

&#x20;       data\_tests:

&#x20;         - unique

&#x20;         - not\_null

&#x20;     - name: platform

&#x20;       description: Advertising platform, either facebook or snapchat.

&#x20;       data\_tests:

&#x20;         - not\_null

&#x20;         - accepted\_values:

&#x20;             arguments:

&#x20;               values: \['facebook', 'snapchat'] 



Now, we run dbt test on this model to check if this test works on this model : uv run dbt test --fct\_marketing\_spend



**error :**  uv run dbt test --fct\_marketing\_spend

Usage: dbt test \[OPTIONS]

Try 'dbt test --help' for help.



Error: No such option '--fct\_marketing\_spend'.



**solution :**

uv run dbt test --select fct\_marketing\_spend



output :

1 of 4 START test accepted\_values\_fct\_marketing\_spend\_platform\_\_facebook\_\_snapchat  \[RUN]

16:23:39  2 of 4 START test not\_null\_fct\_marketing\_spend\_ad\_key .......................... \[RUN]

16:23:39  3 of 4 START test not\_null\_fct\_marketing\_spend\_platform ........................ \[RUN]

16:23:39  4 of 4 START test unique\_fct\_marketing\_spend\_ad\_key ............................ \[RUN]

16:23:43  2 of 4 PASS not\_null\_fct\_marketing\_spend\_ad\_key ................................ \[PASS in 4.13s]

16:23:43  3 of 4 PASS not\_null\_fct\_marketing\_spend\_platform .............................. \[PASS in 4.12s]

16:23:47  1 of 4 PASS accepted\_values\_fct\_marketing\_spend\_platform\_\_facebook\_\_snapchat ... \[PASS in 8.80s]

16:23:48  4 of 4 PASS unique\_fct\_marketing\_spend\_ad\_key .................................. \[PASS in 8.96s]

16:23:48  

16:23:48  Finished running 4 data tests in 0 hours 0 minutes and 20.88 seconds (20.88s).

16:23:48  

16:23:48  Completed successfully



shows the generic test is clean.



**now, next is the singular text :**



we create a file under the test model : tests/assert\_spend\_usd\_not\_negative.sql

oh wait, after much consideration, i have decided to convert the non zero tests(spend, impressions and clicks) to generic test. this converts 3 singular tests into one generic tests. for efficiently.



**step one** : we create a folder (generic) and a file (non\_negative.sql) for the test



**step two** : write the generic format in the file:



{% test non\_negative(model, column\_name) %}



select

&#x20;   {{ column\_name }}

from {{ model }}

where {{ column\_name }} < 0



{% endtest %}





* {% test non\_negative(model, column\_name) %} starts the test and gives it its name. model and column\_name are blanks that dbt fills in each time the test is used.
* The select is the same idea as your singular test: find the bad rows, and the test passes if there are none.
* {{ column\_name }} becomes spend\_usd, then impressions, then clicks, depending on where you attach it.
* {% endtest %} closes it.







**step Three** : now attach to the yaml file we created for fct\_marketing :



models:

&#x20; - name: fct\_marketing\_spend

&#x20;   description: >

&#x20;     One row per ad per day per country, for Facebook and Snapchat together,

&#x20;     with spend in USD. Built for analysts, BI tools and the AI agent.

&#x20;     To get CTR, CPC or CPM for a bigger group, sum clicks, impressions and

&#x20;     spend first and then divide. Do not average the per-row ratios.



&#x20;   columns:

&#x20;     - name: ad\_key

&#x20;       description: Unique id of the row (source, ad id, date and country combined).

&#x20;       data\_tests:

&#x20;         - unique

&#x20;         - not\_null

&#x20;     - name: platform

&#x20;       description: Advertising platform, either facebook or snapchat.

&#x20;       data\_tests:

&#x20;         - not\_null

&#x20;         - accepted\_values:

&#x20;             arguments:

&#x20;               values: \['facebook', 'snapchat']





this now becomes





**models:**

&#x20; **- name: fct\_marketing\_spend**

&#x20;   **description: >**

&#x20;     **One row per ad per day per country, for Facebook and Snapchat together,**

&#x20;     **with spend in USD. Built for analysts, BI tools and the AI agent.**

&#x20;     **To get CTR, CPC or CPM for a bigger group, sum clicks, impressions and**

&#x20;     **spend first and then divide. Do not average the per-row ratios.**



&#x20;   **columns:**

&#x20;     **- name: ad\_key**

&#x20;       **description: Unique id of the row (source, ad id, date and country combined).**

&#x20;       **data\_tests:**

&#x20;         **- unique**

&#x20;         **- not\_null**

&#x20;     **- name: platform**

&#x20;       **description: Advertising platform, either facebook or snapchat.**

&#x20;       **data\_tests:**

&#x20;         **- not\_null**

&#x20;         **- accepted\_values:**

&#x20;             **arguments:**

&#x20;               **values: \['facebook', 'snapchat']**

&#x20;   

&#x20;     **- name: spend\_usd**

&#x20;       **description: Amount spent, converted to US dollars with the ECB monthly average rate.**

&#x20;       **data\_tests:**

&#x20;         **- non\_negative**

&#x20;     **- name: impressions**

&#x20;       **description: Number of times the ad was shown.**

&#x20;       **data\_tests:**

&#x20;         **- non\_negative**

&#x20;     **- name: clicks**

&#x20;       **description: Number of clicks on the ad. Empty when the platform did not report it.**

&#x20;       **data\_tests:**

&#x20;         **- non\_negative**





now, this referenced the non\_negative. sql file that was created, the file now sees the model name and columns needed to check the test.





step 4: run the fct\_marketing.yml file once again, to capture the recent changes and configure the test:



code : **uv run dbt test --select fct\_marketing\_spend**



\-- erorr : uv run dbt test --select fct\_marketing\_spend

17:17:27  Running with dbt=1.12.5

17:17:40  Registered adapter: databricks=1.12.7

17:17:58  Found 13 models, 1 seed, 8 data tests, 9 sources, 776 macros

17:17:58  

17:17:58  Concurrency: 8 threads (target='dev')

17:17:58  

17:18:18  1 of 7 START test accepted\_values\_fct\_marketing\_spend\_platform\_\_facebook\_\_snapchat  \[RUN]

17:18:18  2 of 7 START test non\_negative\_fct\_marketing\_spend\_clicks ...................... \[RUN]

17:18:18  3 of 7 START test non\_negative\_fct\_marketing\_spend\_impressions ................. \[RUN]

17:18:18  4 of 7 START test non\_negative\_fct\_marketing\_spend\_spend\_usd ................... \[RUN]

17:18:18  5 of 7 START test not\_null\_fct\_marketing\_spend\_ad\_key .......................... \[RUN]

17:18:18  6 of 7 START test not\_null\_fct\_marketing\_spend\_platform ........................ \[RUN]

17:18:18  7 of 7 START test unique\_fct\_marketing\_spend\_ad\_key ............................ \[RUN]

17:18:18  3 of 7 ERROR non\_negative\_fct\_marketing\_spend\_impressions ...................... \[ERROR in 0.39s]

17:18:18  4 of 7 ERROR non\_negative\_fct\_marketing\_spend\_spend\_usd ........................ \[ERROR in 0.38s]

17:18:18  2 of 7 ERROR non\_negative\_fct\_marketing\_spend\_clicks ........................... \[ERROR in 0.39s]

17:18:24  1 of 7 PASS accepted\_values\_fct\_marketing\_spend\_platform\_\_facebook\_\_snapchat ... \[PASS in 6.41s]

17:18:24  7 of 7 PASS unique\_fct\_marketing\_spend\_ad\_key .................................. \[PASS in 6.45s]

17:18:25  6 of 7 PASS not\_null\_fct\_marketing\_spend\_platform .............................. \[PASS in 6.59s]

17:18:25  5 of 7 PASS not\_null\_fct\_marketing\_spend\_ad\_key ................................ \[PASS in 6.61s]

17:18:25  

17:18:25  Finished running 7 data tests in 0 hours 0 minutes and 26.73 seconds (26.73s).

17:18:25  

17:18:25  Completed with 3 errors, 0 partial successes, and 0 warnings:

17:18:25  

17:18:25  \[ERROR]: in test non\_negative\_fct\_marketing\_spend\_impressions (models/marts/fct\_marketing\_spend.yml)

17:18:25    Compilation Error in test non\_negative\_fct\_marketing\_spend\_impressions (models/marts/fct\_marketing\_spend.yml)

&#x20; 'test\_non\_negative' is undefined. This can happen when calling a macro that does not exist. Check for typos and/or install package dependencies with "dbt deps".

17:18:25  

17:18:25  \[ERROR]: in test non\_negative\_fct\_marketing\_spend\_spend\_usd (models/marts/fct\_marketing\_spend.yml)

17:18:25    Compilation Error in test non\_negative\_fct\_marketing\_spend\_spend\_usd (models/marts/fct\_marketing\_spend.yml)

&#x20; 'test\_non\_negative' is undefined. This can happen when calling a macro that does not exist. Check for typos and/or install package dependencies with "dbt deps".

17:18:25  

17:18:25  \[ERROR]: in test non\_negative\_fct\_marketing\_spend\_clicks (models/marts/fct\_marketing\_spend.yml)

17:18:25    Compilation Error in test non\_negative\_fct\_marketing\_spend\_clicks (models/marts/fct\_marketing\_spend.yml)

&#x20; 'test\_non\_negative' is undefined. This can happen when calling a macro that does not exist. Check for typos and/or install package dependencies with "dbt deps".

17:18:25  

17:18:25  Done. PASS=4 WARN=0 ERROR=3 SKIP=0 NO-OP=0 REUSED=0 TOTAL=7



solution : i failed to input the details for the macro test file in the non\_negative.sql file, that is this : 

{% test non\_negative(model, column\_name) %}



select

&#x20;   {{ column\_name }}

from {{ model }}

where {{ column\_name }} < 0



{% endtest %}



i will input and re run again

output :

Completed successfully



now, we add the remaining description for the other columns:



&#x20;     - name: ad\_date

&#x20;       description: Day the ad ran.

&#x20;     - name: account\_id

&#x20;       description: Id of the ad account on the platform. An ad account is a billing workspace and not a customer.

&#x20;     - name: campaign\_id

&#x20;       description: Id of the campaign on the platform.

&#x20;     - name: campaign\_name

&#x20;       description: Name of the campaign, taken from the platform.

&#x20;     - name: ad\_id

&#x20;       description: Id of the ad on the platform.

&#x20;     - name: ad\_name

&#x20;       description: Name of the ad.

&#x20;     - name: ad\_country

&#x20;       description: Country the ad ran in. Only Snapchat reports it, so it is empty for Facebook rows.

&#x20;     - name: ctr

&#x20;       description: Click-through rate, clicks divided by impressions (0.02 means 2%). Empty when impressions are 0. Do not average across rows.

&#x20;     - name: cpc

&#x20;       description: Cost per click in USD, spend divided by clicks. Empty when clicks are 0 or not reported.

&#x20;     - name: cpm

&#x20;       description: Cost per thousand impressions in USD, spend divided by impressions times 1000. Empty when impressions are 0.



and it the becomes :





**models:**

&#x20; **- name: fct\_marketing\_spend**

&#x20;   **description: >**

&#x20;     **One row per ad per day per country, for Facebook and Snapchat together,**

&#x20;     **with spend in USD. Built for analysts, BI tools and the AI agent.**

&#x20;     **To get CTR, CPC or CPM for a bigger group, sum clicks, impressions and**

&#x20;     **spend first and then divide. Do not average the per-row ratios.**



&#x20;   **columns:**

&#x20;     **- name: ad\_key**

&#x20;       **description: Unique id of the row (source, ad id, date and country combined).**

&#x20;       **data\_tests:**

&#x20;         **- unique**

&#x20;         **- not\_null**

&#x20;     **- name: platform**

&#x20;       **description: Advertising platform, either facebook or snapchat.**

&#x20;       **data\_tests:**

&#x20;         **- not\_null**

&#x20;         **- accepted\_values:**

&#x20;             **arguments:**

&#x20;               **values: \['facebook', 'snapchat']**

&#x20;   

&#x20;     **- name: spend\_usd**

&#x20;       **description: Amount spent, converted to US dollars with the ECB monthly average rate.**

&#x20;       **data\_tests:**

&#x20;         **- non\_negative**

&#x20;     **- name: impressions**

&#x20;       **description: Number of times the ad was shown.**

&#x20;       **data\_tests:**

&#x20;         **- non\_negative**

&#x20;     **- name: clicks**

&#x20;       **description: Number of clicks on the ad. Empty when the platform did not report it.**

&#x20;       **data\_tests:**

&#x20;         **- non\_negative**

&#x20;         

&#x20;     **- name: ad\_date**

&#x20;       **description: Day the ad ran.**

&#x20;     **- name: account\_id**

&#x20;       **description: Id of the ad account on the platform. An ad account is a billing workspace and not a customer.**

&#x20;     **- name: campaign\_id**

&#x20;       **description: Id of the campaign on the platform.**

&#x20;     **- name: campaign\_name**

&#x20;       **description: Name of the campaign, taken from the platform.**

&#x20;     **- name: ad\_id**

&#x20;       **description: Id of the ad on the platform.**

&#x20;     **- name: ad\_name**

&#x20;       **description: Name of the ad.**

&#x20;     **- name: ad\_country**

&#x20;       **description: Country the ad ran in. Only Snapchat reports it, so it is empty for Facebook rows.**

&#x20;     **- name: ctr**

&#x20;       **description: Click-through rate, clicks divided by impressions (0.02 means 2%). Empty when impressions are 0. Do not average across rows.**

&#x20;     **- name: cpc**

&#x20;       **description: Cost per click in USD, spend divided by clicks. Empty when clicks are 0 or not reported.**

&#x20;     **- name: cpm**

&#x20;       **description: Cost per thousand impressions in USD, spend divided by impressions times 1000. Empty when impressions are 0.**



We then run **uv run dbt parse :** checks that dbt can read your project

dbt parse reads all my files and checks that dbt can understand them: yml indentation, Jinja syntax, and that every ref/source points to something real. It doesn’t connect to the database, so it can’t catch a wrong column name. It’s a fast, free first check before build, and it’ll be the first step in CI.





###### 

* ##### **staging tests:**

For each of the staging test tables, i ran some test. for both facebook and snapchat. i will send a few yml test i ran. each of this staging yml file had their own tests:

###### a)**stg\_facebook\_ad\_groups.yml** :



models:

&#x20; - name: stg\_facebook\_ad\_groups

&#x20;   description: >

&#x20;     Facebook ad groups (ad sets), one row per ad group. An ad group sits

&#x20;     inside a campaign and holds ads. It sets who sees the ads, the budget

&#x20;     and the schedule. The link to its campaign goes through stg\_facebook\_ads.

&#x20;   columns:

&#x20;     **- name: ad\_group\_id**

&#x20;       **description: Identifier of the ad group. Unique in this model.**

&#x20;       **data\_tests: \[unique, not\_null]** 

&#x20;     - name: ad\_group\_name

&#x20;       description: Name of the ad group. Label only, not a key.

&#x20;     - name: ad\_group\_updated\_at

&#x20;       description: When the record was last changed.



Expalnantion : The test that was ran is to check if the ad\_group\_id is unique and not null. the test is generic





###### b)s**tg\_facebook\_ads\_stats.yml**



version: 2



models:

&#x20;   columns:

&#x20;     - name: ad\_id

&#x20;       description: >

&#x20;         Identifier of the ad. Kept as text. Repeats across rows (one row per

&#x20;         ad per day), so it is not unique on its own; ad\_id + ad\_date is.

&#x20;         Joins to stg\_facebook\_ads.

&#x20;       data\_tests:

&#x20;         - not\_null

&#x20;         - relationships:

&#x20;             arguments:

&#x20;               to: ref('stg\_facebook\_ads')

&#x20;               field: ad\_id

&#x20;     - name: account\_id

&#x20;       description: Ad account billed for this row. Joins to stg\_facebook\_accounts.

&#x20;     - name: spend

&#x20;       description: Amount spent that day, in the ad account's currency.

&#x20;       data\_tests: \[non\_negative]

&#x20;     - name: impressions

&#x20;       description: Times the ad was shown that day. NULL means the source did not report it.

&#x20;       data\_tests: \[non\_negative]

&#x20;     - name: clicks

&#x20;       description: Clicks on the ad that day. NULL means the source did not report it.

&#x20;       data\_tests: \[non\_negative]

&#x20;     - name: ad\_date

&#x20;       description: Calendar date of the activity.

&#x20;       data\_tests: \[not\_null]



Explanation :

i ran diferent tests on this model. since the ad\_id and ad\_date combined together forms a composite key. i expect that both are unique and not null.

i ran a relationship tests from the stg\_facebook\_ads table. this relationship test is to confirm that the parent table (**stg\_facebook\_ads)** has all ad\_id in the ad\_stats table.

the test for this was succesful. 

I also did a generic test on the numbers columns(spends, clicks,impressions). this confirms that they dont have negative numbers that will affect our calculation. also, this test wasnt inbuilt on dbt, i had to write it my self and make it generic. steps for that:

* I wrote a reusuable generic macro sql synthax:



**{% test non\_negative(model, column\_name) %}**



**select**

&#x20;   **{{ column\_name }}**

**from {{ model }}**

**where {{ column\_name }} < 0**



**{% endtest %}**





and call it by its name :non\_negative.

just like here :

&#x20;  **data\_tests: \[non\_negative]**

&#x20;     **- name: impressions**

&#x20;       **data\_tests: \[non\_negative]**

&#x20;     **- name: clicks**

&#x20;       **data\_tests: \[non\_negative]**

###### 

###### **c) stg\_snapchat\_ads\_stats.ymi**



&#x20;   columns:

&#x20;     - name: ad\_id

&#x20;       description: >

&#x20;         The ad this row belongs to. Renamed from ad\_detail\_id so it matches

&#x20;         ad\_id in ad\_history and in the Facebook models. Repeats across rows

&#x20;         (one ad, many days).

&#x20;       data\_tests:

&#x20;         - not\_null

&#x20;         - relationships:

&#x20;             arguments:

&#x20;               to: ref('stg\_snapchat\_ad\_history')

&#x20;               field: ad\_id

&#x20;     - name: ad\_currency\_code

&#x20;       description: Currency the spend is in. Each stats row carries its own currency.

&#x20;       data\_tests:

&#x20;         - not\_null

&#x20;         - accepted\_values:

&#x20;             arguments:

&#x20;               values: \['USD', 'EUR']

&#x20;     - name: ad\_country

&#x20;       description: Country the ad was shown in, upper-cased.

&#x20;     - name: spend

&#x20;       description: Amount spent, in the currency of the row. Decimal with 6 places.

&#x20;       data\_tests: \[non\_negative]

&#x20;     - name: impressions

&#x20;       description: Number of times the ad was shown.

&#x20;       data\_tests: \[non\_negative]

&#x20;     - name: clicks

&#x20;       description: >

&#x20;         Number of clicks. NULL for 111 rows where the raw file had the text

&#x20;         'null' (not the same as a real zero).

&#x20;       data\_tests: \[non\_negative]

&#x20;     - name: ad\_date

&#x20;       description: The day the numbers are for.

&#x20;       data\_tests: \[not\_null]

&#x20;     - name: data\_source

&#x20;       description: Where the row came from, as given in the raw file.

&#x20;       data\_tests:

&#x20;         - accepted\_values:

&#x20;             arguments:

&#x20;               values: \['snapchat\_ads']









* Explanation : this test carries  alot of checks muost of it we have covered. we pick the ones not yet convered.

accepted\_values : this check just make sure the accepted values within a column are these----. for example in the currency column, we know we have only 2 accepted values : USD and EUR. so we defined it in our accepted values. same as data\_source in snapchat, we only know that snapchat\_ads is the only accepted value in that column, anything other than that is an error.



###### **d) singular test for both facebook ad\_stats and snapchat\_ads\_stats**

The singular test is a custom sql written by you. it doesn't aim to be generic but whereas towards specific columns:

for example, in both of ads\_stats in facebook and snapchat, they dont have one primary unique identfiier. snapchat has 3, facebook has 2. to be sure of this, we run a singular test on both of the tables

* singular test for facebook : we create a .sql file (cdc\_fb\_sp\_marketing\\tests\\singular\\**stg\_facebook\_ads\_stats\_grain.sql**) and store it under the singular file, here is the test :

**select**

&#x20;   **ad\_id,**

&#x20;   **ad\_date,**

&#x20;   **count(\*) as row\_count**

**from {{ ref('stg\_facebook\_ads\_stats') }}**

**group by ad\_id, ad\_date**

**having count(\*) > 1**



* singular test for snapchat : same principle for snapchat a .sql file was created (cdc\_fb\_sp\_marketing\\tests\\singular\\**stg\_snapchat\_ads\_stats\_grain.sql)**



**select**

&#x20;   **ad\_id,**

&#x20;   **ad\_date,**

&#x20;   **ad\_country,**

&#x20;   **count(\*) as row\_count**

**from {{ ref('stg\_snapchat\_ads\_stats') }}**

**group by ad\_id, ad\_date, ad\_country**

**having count(\*) > 1**



After running **uv run dbt test, to confirm all test works and are implemented succesfully, an error occur, one of the test wasn't succesful:**



**-- ERROR**

&#x20; 

godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting\_data\_platform/cdc\_fb\_sp\_marketing$ uv run dbt test --select stg\_snapchat\_ad\_history

22:00:00  Running with dbt=1.12.5

22:00:14  Registered adapter: databricks=1.12.7

22:00:31  Found 13 models, 1 seed, 45 data tests, 9 sources, 777 macros

22:00:31  

22:00:31  Concurrency: 8 threads (target='dev')

22:00:31  

22:00:45  1 of 5 START test not\_null\_stg\_snapchat\_ad\_history\_ad\_group\_id ................. \[RUN]

22:00:45  2 of 5 START test not\_null\_stg\_snapchat\_ad\_history\_ad\_id ....................... \[RUN]

22:00:45  3 of 5 START test relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_  \[RUN]

22:00:45  4 of 5 START test relationships\_stg\_snapchat\_ads\_stats\_ad\_id\_\_ad\_id\_\_ref\_stg\_snapchat\_ad\_history\_  \[RUN]

22:00:45  5 of 5 START test unique\_stg\_snapchat\_ad\_history\_ad\_id ......................... \[RUN]

22:00:49  5 of 5 PASS unique\_stg\_snapchat\_ad\_history\_ad\_id ............................... \[PASS in 4.59s]

22:00:50  4 of 5 PASS relationships\_stg\_snapchat\_ads\_stats\_ad\_id\_\_ad\_id\_\_ref\_stg\_snapchat\_ad\_history\_  \[PASS in 4.62s]

22:00:50  2 of 5 PASS not\_null\_stg\_snapchat\_ad\_history\_ad\_id ............................. \[PASS in 4.68s]

22:00:50  1 of 5 PASS not\_null\_stg\_snapchat\_ad\_history\_ad\_group\_id ....................... \[PASS in 4.70s]

22:00:50  3 of 5 FAIL 304 relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_  \[FAIL 304 in 4.95s]

22:00:50  

22:00:50  Finished running 5 data tests in 0 hours 0 minutes and 18.79 seconds (18.79s).

22:00:50  

22:00:50  Completed with 1 error, 0 partial successes, and 0 warnings:

22:00:50  

22:00:50  \[ERROR]: **in test relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_** (models/staging/snapchat\_ads/stg\_snapchat\_ad\_history.yml)

22:00:50    Got **304 results**, configured to fail if != 0

22:00:50  

22:00:50    compiled code at target/compiled/cdc\_fb\_sp\_marketing/models/staging/**snapchat\_ads/stg\_snapchat\_ad\_history.ym**l/relationships\_stg\_snapchat\_ad\_\_da8c29f0303cdef34e1d2cd1bba45fb5.sql

22:00:50  

22:00:50  Done. PASS=4 WARN=0 ERROR=1 SKIP=0 NO-OP=0 REUSED=0 TOTAL=5



solution:

first i traced the model that had to trace which model and table this was affected. it turned out to be ad\_history on snapchat schema. we already know that the unique identifier is ad\_id and its parent table is ad\_group\_history. automatically, the ad\_group\_id in the ad\_history table are not in the ad\_group\_history table. 304 of them. this was weird. i went to databricks to confirm that this was real using the sql query :

**select** 

**count(\*)**

**from**

&#x20;   **bronze\_dev.snapchat\_ads.snapchat\_ads\_ad\_history\_new\_ad\_names as ah**

**Left join**

&#x20;   **bronze\_dev.snapchat\_ads.snapchat\_ads\_adgroup\_history\_new\_ad\_group\_names as gh ON ah.ad\_group\_id = gh.ad\_group\_id**

**where**

&#x20;   **gh.ad\_group\_id is null**



output: found out that ad\_group\_history table when joined with ad\_history table, producces 304 of missing ad\_group\_id. this was really weird because all ad\_group\_id must appear in ad\_group history table.



to move forward with my checks, i try to confirm if those ad\_ids with missing ad\_groups have numbers(spends,impressions, clicks,) using this sql query:



**select** 

**ah.ad\_id as ad\_id ,**

**ads.ad\_detail\_id as detail\_id,**

**ad\_spend,**

**ad\_impressions,**

**ad\_clicks**

**from**

&#x20;   **bronze\_dev.snapchat\_ads.snapchat\_ads\_ad\_history\_new\_ad\_names as ah**

**Left join**

&#x20;   **bronze\_dev.snapchat\_ads.snapchat\_ads\_adgroup\_history\_new\_ad\_group\_names as gh ON ah.ad\_group\_id = gh.ad\_group\_id**

**left join**

&#x20;   **bronze\_dev.snapchat\_ads.snapchat\_ads\_stats as ads ON ah.ad\_id = ads.ad\_detail\_id**

**where**

&#x20;   **gh.ad\_group\_id is null**

**group by** 

&#x20;  **ah.ad\_id ,**

**ads.ad\_detail\_id,**

**ad\_spend,**

**ad\_impressions,**

**ad\_clicks**





**output:**



**ad\_id	detail\_id	ad\_spend	ad\_impressions	ad\_clicks**

**8580577b-bf58-4a81-b233-cc1b5192e137	null	null	null	null**

**4489ba2c-2998-4d04-9d3f-5f1df4fa28d7	null	null	null	null**

**e0599659-fe95-4004-b2c0-957b3586d0bb	null	null	null	null**

**5836acf8-14d4-421e-85c8-e164c15b8271	null	null	null	null**

**482c5591-f7f7-4abe-8e28-1743d5ec3811	null	null	null	null**

**4bcdd504-98ff-492b-8510-76f52af81093	null	null	null	null**

**8b3328c6-fa9b-4e61-b4ea-3097538c2850	null	null	null	null**

**340f3c54-f81c-413d-ad8d-85dd6cb89649	null	null	null	null**

**c62a0d16-29d2-4ebe-9529-bae932e53c8c	null	null	null    null ..................**



they all appeared as null, this was fully justified that these ads were never running. they appeared to be empty when connected to the ads\_stats table. they dont have values.	

after running this it shows that this ads were never live., no money was spent on them, boils to one question. how come a particular ad\_id has a group history on ad\_history table, but that group\_id is not in the parent table? its weirrd. because even its not up and running, it should appear in the ad\_group history. so its safe to say the source data is the issue?

I finally confirm all doubts to see the distint count between the ad\_id in ad\_history and ad\_stats. normally, this should appear as the same number but here is what happened :

**select**

&#x20;   **count(distinct ah.ad\_id) as ads,**

&#x20;   **count(distinct ads.ad\_detail\_id) as ads\_with\_stats**

**from bronze\_dev.snapchat\_ads.snapchat\_ads\_ad\_history\_new\_ad\_names as ah**

**left join bronze\_dev.snapchat\_ads.snapchat\_ads\_stats as ads**

&#x20;   **on ah.ad\_id = ads.ad\_detail\_id**



**output :**

**ads    ads\_with\_stats**

**2513    63**



**they are not the same.**

* **conclusion :**

Check 5: the raw ad history has 2,513 ads, and only 63 have any stats rows (join on ad\_id = ad\_detail\_id, confirmed working). So most ads in the history never ran, and the 304 orphan ads having no spend is consistent with the rest of the table. The issue is in the source, and the cause is unknown.

* solution: 

&#x20;- relationships:

&#x20;   arguments:

&#x20;     to: ref('stg\_snapchat\_ad\_groups')

&#x20;     field: ad\_group\_id

&#x20;   config:

&#x20;     severity: warn



**I can’t fix the source, so I didn’t touch the data or the staging SQL.**

**I set the test to severity: warn, so it stays visible in every run and in Elementary but doesn’t block the pipeline:**

**I added not\_null on campaign\_id in fct\_marketing\_spend. If an orphan ad ever starts spending, the final model fails, and that is the failure that matters.**

**I merged a duplicated ad\_group\_id entry in the yml into one**



output :

uv run dbt test

15:59:54  Running with dbt=1.12.5

16:00:07  Registered adapter: databricks=1.12.7

16:00:24  Found 13 models, 50 data tests, 1 seed, 9 sources, 777 macros

16:00:24  

16:00:24  Concurrency: 8 threads (target='dev')

16:00:24  

16:00:42  1 of 50 START test accepted\_values\_fct\_marketing\_spend\_platform\_\_facebook\_\_snapchat  \[RUN]

16:00:42  2 of 50 START test accepted\_values\_stg\_facebook\_accounts\_currency\_\_USD\_\_EUR .... \[RUN]

16:00:42  3 of 50 START test accepted\_values\_stg\_snapchat\_ads\_stats\_ad\_currency\_code\_\_USD\_\_EUR  \[RUN]

16:00:42  4 of 50 START test accepted\_values\_stg\_snapchat\_ads\_stats\_data\_source\_\_snapchat\_ads  \[RUN]

16:00:42  5 of 50 START test non\_negative\_fct\_marketing\_spend\_clicks ..................... \[RUN]

16:00:42  6 of 50 START test non\_negative\_fct\_marketing\_spend\_impressions ................ \[RUN]

16:00:42  7 of 50 START test non\_negative\_fct\_marketing\_spend\_spend\_usd .................. \[RUN]

16:00:42  8 of 50 START test non\_negative\_stg\_facebook\_ads\_stats\_clicks .................. \[RUN]

16:00:51  5 of 50 PASS non\_negative\_fct\_marketing\_spend\_clicks ........................... \[PASS in 9.08s]

16:00:51  1 of 50 PASS accepted\_values\_fct\_marketing\_spend\_platform\_\_facebook\_\_snapchat .. \[PASS in 9.09s]

16:00:51  9 of 50 START test non\_negative\_stg\_facebook\_ads\_stats\_impressions ............. \[RUN]

16:00:51  10 of 50 START test non\_negative\_stg\_facebook\_ads\_stats\_spend .................. \[RUN]

16:00:51  8 of 50 PASS non\_negative\_stg\_facebook\_ads\_stats\_clicks ........................ \[PASS in 9.24s]

16:00:51  11 of 50 START test non\_negative\_stg\_snapchat\_ads\_stats\_clicks ................. \[RUN]

16:00:52  3 of 50 PASS accepted\_values\_stg\_snapchat\_ads\_stats\_ad\_currency\_code\_\_USD\_\_EUR . \[PASS in 9.31s]

16:00:52  12 of 50 START test non\_negative\_stg\_snapchat\_ads\_stats\_impressions ............ \[RUN]

16:00:52  7 of 50 PASS non\_negative\_fct\_marketing\_spend\_spend\_usd ........................ \[PASS in 9.36s]

16:00:52  4 of 50 PASS accepted\_values\_stg\_snapchat\_ads\_stats\_data\_source\_\_snapchat\_ads .. \[PASS in 9.36s]

16:00:52  6 of 50 PASS non\_negative\_fct\_marketing\_spend\_impressions ...................... \[PASS in 9.36s]

16:00:52  13 of 50 START test non\_negative\_stg\_snapchat\_ads\_stats\_spend .................. \[RUN]

16:00:52  14 of 50 START test not\_null\_fct\_marketing\_spend\_ad\_key ........................ \[RUN]

16:00:52  15 of 50 START test not\_null\_fct\_marketing\_spend\_campaign\_id ................... \[RUN]

16:00:54  9 of 50 PASS non\_negative\_stg\_facebook\_ads\_stats\_impressions ................... \[PASS in 3.15s]

16:00:54  16 of 50 START test not\_null\_fct\_marketing\_spend\_platform ...................... \[RUN]

16:00:55  10 of 50 PASS non\_negative\_stg\_facebook\_ads\_stats\_spend ........................ \[PASS in 3.27s]

16:00:55  17 of 50 START test not\_null\_stg\_facebook\_accounts\_account\_id .................. \[RUN]

16:00:55  12 of 50 PASS non\_negative\_stg\_snapchat\_ads\_stats\_impressions .................. \[PASS in 3.16s]

16:00:55  18 of 50 START test not\_null\_stg\_facebook\_accounts\_currency .................... \[RUN]

16:00:55  13 of 50 PASS non\_negative\_stg\_snapchat\_ads\_stats\_spend ........................ \[PASS in 3.23s]

16:00:55  19 of 50 START test not\_null\_stg\_facebook\_ad\_groups\_ad\_group\_id ................ \[RUN]

16:00:55  15 of 50 PASS not\_null\_fct\_marketing\_spend\_campaign\_id ......................... \[PASS in 3.25s]

16:00:55  20 of 50 START test not\_null\_stg\_facebook\_ads\_account\_id ....................... \[RUN]

16:00:55  14 of 50 PASS not\_null\_fct\_marketing\_spend\_ad\_key .............................. \[PASS in 3.31s]

16:00:55  21 of 50 START test not\_null\_stg\_facebook\_ads\_ad\_id ............................ \[RUN]

16:00:55  11 of 50 PASS non\_negative\_stg\_snapchat\_ads\_stats\_clicks ....................... \[PASS in 3.55s]

16:00:55  22 of 50 START test not\_null\_stg\_facebook\_ads\_campaign\_id ...................... \[RUN]

16:00:56  2 of 50 PASS accepted\_values\_stg\_facebook\_accounts\_currency\_\_USD\_\_EUR .......... \[PASS in 14.01s]

16:00:56  23 of 50 START test not\_null\_stg\_facebook\_ads\_stats\_ad\_date .................... \[RUN]

16:00:59  16 of 50 PASS not\_null\_fct\_marketing\_spend\_platform ............................ \[PASS in 4.22s]

16:00:59  24 of 50 START test not\_null\_stg\_facebook\_ads\_stats\_ad\_id ...................... \[RUN]

16:00:59  17 of 50 PASS not\_null\_stg\_facebook\_accounts\_account\_id ........................ \[PASS in 4.30s]

16:00:59  25 of 50 START test not\_null\_stg\_facebook\_campaigns\_campaign\_id ................ \[RUN]

16:00:59  23 of 50 PASS not\_null\_stg\_facebook\_ads\_stats\_ad\_date .......................... \[PASS in 3.06s]

16:00:59  26 of 50 START test not\_null\_stg\_snapchat\_ad\_groups\_ad\_group\_id ................ \[RUN]

16:00:59  20 of 50 PASS not\_null\_stg\_facebook\_ads\_account\_id ............................. \[PASS in 4.53s]

16:00:59  27 of 50 START test not\_null\_stg\_snapchat\_ad\_groups\_campaign\_id ................ \[RUN]

16:01:00  19 of 50 PASS not\_null\_stg\_facebook\_ad\_groups\_ad\_group\_id ...................... \[PASS in 4.98s]

16:01:00  28 of 50 START test not\_null\_stg\_snapchat\_ad\_history\_ad\_group\_id ............... \[RUN]

16:01:00  18 of 50 PASS not\_null\_stg\_facebook\_accounts\_currency .......................... \[PASS in 5.18s]

16:01:00  29 of 50 START test not\_null\_stg\_snapchat\_ad\_history\_ad\_id ..................... \[RUN]

16:01:00  22 of 50 PASS not\_null\_stg\_facebook\_ads\_campaign\_id ............................ \[PASS in 4.91s]

16:01:00  30 of 50 START test not\_null\_stg\_snapchat\_ads\_stats\_ad\_currency\_code ........... \[RUN]

16:01:00  21 of 50 PASS not\_null\_stg\_facebook\_ads\_ad\_id .................................. \[PASS in 5.05s]

16:01:00  31 of 50 START test not\_null\_stg\_snapchat\_ads\_stats\_ad\_date .................... \[RUN]

16:01:01  24 of 50 PASS not\_null\_stg\_facebook\_ads\_stats\_ad\_id ............................ \[PASS in 2.54s]

16:01:01  32 of 50 START test not\_null\_stg\_snapchat\_ads\_stats\_ad\_id ...................... \[RUN]

16:01:02  25 of 50 PASS not\_null\_stg\_facebook\_campaigns\_campaign\_id ...................... \[PASS in 3.22s]

16:01:02  33 of 50 START test not\_null\_stg\_snapchat\_campaigns\_account\_id ................. \[RUN]

16:01:03  30 of 50 PASS not\_null\_stg\_snapchat\_ads\_stats\_ad\_currency\_code ................. \[PASS in 3.12s]

16:01:03  34 of 50 START test not\_null\_stg\_snapchat\_campaigns\_campaign\_id ................ \[RUN]

16:01:03  31 of 50 PASS not\_null\_stg\_snapchat\_ads\_stats\_ad\_date .......................... \[PASS in 3.20s]

16:01:03  35 of 50 START test relationships\_stg\_facebook\_ads\_account\_id\_\_account\_id\_\_ref\_stg\_facebook\_accounts\_  \[RUN]

16:01:03  28 of 50 PASS not\_null\_stg\_snapchat\_ad\_history\_ad\_group\_id ..................... \[PASS in 3.56s]

16:01:03  36 of 50 START test relationships\_stg\_facebook\_ads\_campaign\_id\_\_campaign\_id\_\_ref\_stg\_facebook\_campaigns\_  \[RUN]

16:01:04  29 of 50 PASS not\_null\_stg\_snapchat\_ad\_history\_ad\_id ........................... \[PASS in 3.61s]

16:01:04  37 of 50 START test relationships\_stg\_facebook\_ads\_stats\_ad\_id\_\_ad\_id\_\_ref\_stg\_facebook\_ads\_  \[RUN]

16:01:04  27 of 50 PASS not\_null\_stg\_snapchat\_ad\_groups\_campaign\_id ...................... \[PASS in 4.28s]

16:01:04  38 of 50 START test relationships\_stg\_snapchat\_ad\_groups\_campaign\_id\_\_campaign\_id\_\_ref\_stg\_snapchat\_campaigns\_  \[RUN]

16:01:04  26 of 50 PASS not\_null\_stg\_snapchat\_ad\_groups\_ad\_group\_id ...................... \[PASS in 4.40s]

16:01:04  39 of 50 START test relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_  \[RUN]

16:01:04  32 of 50 PASS not\_null\_stg\_snapchat\_ads\_stats\_ad\_id ............................ \[PASS in 2.80s]

16:01:04  40 of 50 START test relationships\_stg\_snapchat\_ads\_stats\_ad\_id\_\_ad\_id\_\_ref\_stg\_snapchat\_ad\_history\_  \[RUN]

16:01:05  33 of 50 PASS not\_null\_stg\_snapchat\_campaigns\_account\_id ....................... \[PASS in 3.00s]

16:01:05  41 of 50 START test stg\_facebook\_ads\_stats\_grain ............................... \[RUN]

16:01:07  34 of 50 PASS not\_null\_stg\_snapchat\_campaigns\_campaign\_id ...................... \[PASS in 3.49s]

16:01:07  42 of 50 START test stg\_snapchat\_ads\_stats\_grain ............................... \[RUN]

16:01:07  36 of 50 PASS relationships\_stg\_facebook\_ads\_campaign\_id\_\_campaign\_id\_\_ref\_stg\_facebook\_campaigns\_  \[PASS in 3.70s]

16:01:07  43 of 50 START test unique\_fct\_marketing\_spend\_ad\_key .......................... \[RUN]

16:01:07  35 of 50 PASS relationships\_stg\_facebook\_ads\_account\_id\_\_account\_id\_\_ref\_stg\_facebook\_accounts\_  \[PASS in 4.11s]

16:01:07  44 of 50 START test unique\_stg\_facebook\_accounts\_account\_id .................... \[RUN]

16:01:08  39 of 50 WARN 304 relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_  \[WARN 304 in 4.16s]

16:01:08  45 of 50 START test unique\_stg\_facebook\_ad\_groups\_ad\_group\_id .................. \[RUN]

16:01:08  40 of 50 PASS relationships\_stg\_snapchat\_ads\_stats\_ad\_id\_\_ad\_id\_\_ref\_stg\_snapchat\_ad\_history\_  \[PASS in 3.84s]

16:01:08  37 of 50 PASS relationships\_stg\_facebook\_ads\_stats\_ad\_id\_\_ad\_id\_\_ref\_stg\_facebook\_ads\_  \[PASS in 4.40s]

16:01:08  46 of 50 START test unique\_stg\_facebook\_ads\_ad\_id .............................. \[RUN]

16:01:08  47 of 50 START test unique\_stg\_facebook\_campaigns\_campaign\_id .................. \[RUN]

16:01:08  41 of 50 PASS stg\_facebook\_ads\_stats\_grain ..................................... \[PASS in 3.15s]

16:01:08  48 of 50 START test unique\_stg\_snapchat\_ad\_groups\_ad\_group\_id .................. \[RUN]

16:01:08  38 of 50 PASS relationships\_stg\_snapchat\_ad\_groups\_campaign\_id\_\_campaign\_id\_\_ref\_stg\_snapchat\_campaigns\_  \[PASS in 4.62s]

16:01:08  49 of 50 START test unique\_stg\_snapchat\_ad\_history\_ad\_id ....................... \[RUN]

16:01:09  42 of 50 PASS stg\_snapchat\_ads\_stats\_grain ..................................... \[PASS in 2.16s]

16:01:09  50 of 50 START test unique\_stg\_snapchat\_campaigns\_campaign\_id .................. \[RUN]

16:01:09  43 of 50 PASS unique\_fct\_marketing\_spend\_ad\_key ................................ \[PASS in 2.19s]

16:01:10  44 of 50 PASS unique\_stg\_facebook\_accounts\_account\_id .......................... \[PASS in 2.38s]

16:01:11  46 of 50 PASS unique\_stg\_facebook\_ads\_ad\_id .................................... \[PASS in 3.19s]

16:01:11  47 of 50 PASS unique\_stg\_facebook\_campaigns\_campaign\_id ........................ \[PASS in 3.24s]

16:01:11  48 of 50 PASS unique\_stg\_snapchat\_ad\_groups\_ad\_group\_id ........................ \[PASS in 2.97s]

16:01:11  45 of 50 PASS unique\_stg\_facebook\_ad\_groups\_ad\_group\_id ........................ \[PASS in 3.39s]

16:01:11  50 of 50 PASS unique\_stg\_snapchat\_campaigns\_campaign\_id ........................ \[PASS in 2.75s]

16:01:12  49 of 50 PASS unique\_stg\_snapchat\_ad\_history\_ad\_id ............................. \[PASS in 3.28s]

16:01:12  

16:01:12  Finished running 50 data tests in 0 hours 0 minutes and 47.84 seconds (47.84s).

16:01:12  

16:01:12  Completed with 1 warning:

16:01:12  

16:01:12  \[WARNING]: in test relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_ (models/staging/snapchat\_ads/stg\_snapchat\_ad\_history.yml)

16:01:12  \[WARNING]: Got 304 results, configured to warn if != 0

16:01:12  

16:01:12    compiled code at target/compiled/cdc\_fb\_sp\_marketing/models/staging/snapchat\_ads/stg\_snapchat\_ad\_history.yml/relationships\_stg\_snapchat\_ad\_\_da8c29f0303cdef34e1d2cd1bba45fb5.sql

16:01:12  

16:01:12  Done. PASS=49 WARN=1 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=50



###### **e)Generic and singular for seeds**

* Generic :

for the seed file it self, exchange \_rate.yml we run a generic test on it.

we first create a .yml file on seed folder :

and this is the test :

**version: 2**



**seeds:**

&#x20; **- name: exchange\_rates**

&#x20;   **description: >**

&#x20;     **Monthly exchange rates to USD (ECB, USD per 1 EUR). USD rows carry a**

&#x20;     **rate of 1. One row per month per currency. Updated by hand each month.**

&#x20;   **columns:**

&#x20;     **- name: rate\_month**

&#x20;       **description: First day of the month the rate applies to.**

&#x20;       **data\_tests: \[not\_null]**

&#x20;     **- name: currency**

&#x20;       **description: Currency the rate converts from (USD or EUR).**

&#x20;       **data\_tests:**

&#x20;         **- not\_null**

&#x20;         **- accepted\_values:**

&#x20;             **arguments:**

&#x20;               **values: \['USD', 'EUR']**

&#x20;     **- name: rate\_to\_usd**

&#x20;       **description: Dollars for 1 unit of the currency. Always 1 for USD.**

&#x20;       **data\_tests:**

&#x20;         **- not\_null**

&#x20;         **- non\_negative**



Explanation : exchange should not be null, currency should not be null and accepted values are USD and EUR. the rate\_to\_usd should not be null and should not be negative



* singular : 

for this test we make sure that the columns rate\_month and currency are relatively unique :

we create a file called exchange\_rates\_grain.sql and write a custom sql here.

**select**

&#x20;   **rate\_month,**

&#x20;   **currency,**

&#x20;   **count(\*) as row\_count**

**from {{ ref('exchange\_rates') }}**

**group by rate\_month, currency**

**having count(\*) > 1**





###### **f) Singular and generic test for intermediate** :

we also create a file called int\_marketing\_ads\_missing\_rate.sql and write a custom sql here:

**select**

&#x20;   **ad\_date,**

&#x20;   **currency,**

&#x20;   **spend**

**from {{ ref('int\_marketing\_ads') }}**

**where spend is not null**

&#x20; **and spend\_usd is null**



this test evaluates for the future. When a new month starts and nobody has added its rate line, the join finds no rate, so spend\_usd becomes NULL. This test fails and tells you exactly which month and currency are missing. It also settles the “rows without USD” check we had pending.



now, the YAML file for the three intermdiate files:



* int\_facebook\_ads.yml



version: 2



models:

&#x20; - name: int\_facebook\_ads

&#x20;   description: >

&#x20;     Facebook daily performance, one row per ad per day. Takes the daily

&#x20;     stats and adds the ad details, the campaign name and the billing

&#x20;     currency of the account. Spend is still in the account's currency.

&#x20;     Facebook has no country, so ad\_country is NULL here. Ephemeral: it is

&#x20;     never built as a table, only used inside int\_marketing\_ads.

* int\_snapchat\_ads.yml



version: 2



models:

&#x20; - name: int\_snapchat\_ads

&#x20;   description: >

&#x20;     Snapchat daily performance, one row per ad per day per country. Takes

&#x20;     the daily stats and adds the ad name and, through the ad group, the

&#x20;     campaign. Spend is in the currency carried on each row. Ephemeral: it

&#x20;     is never built as a table, only used inside int\_marketing\_ads.

* int\_marketing\_ads.yml



version: 2



models:

&#x20; - name: int\_marketing\_ads

&#x20;   description: >

&#x20;     Facebook and Snapchat stacked into one table with the same columns

&#x20;     (union all). Adds the month of each row, looks up the monthly exchange

&#x20;     rate for its currency, and computes spend\_usd. A row whose month has

&#x20;     no rate in the seed gets a NULL spend\_usd, which the singular test

&#x20;     int\_marketing\_ads\_missing\_rate catches. Ephemeral: used only by

&#x20;     fct\_marketing\_spend.v



now run dbt test:



**--error:**

Completed with 3 errors, 0 partial successes, and 1 warning:

16:27:10  

16:27:10  \[ERROR]: in test not\_null\_exchange\_rates\_currency (seeds/exchange\_rates.yml)

16:27:10    Got 1 result, configured to fail if != 0

16:27:10  

16:27:10    compiled code at target/compiled/cdc\_fb\_sp\_marketing/seeds/exchange\_rates.yml/not\_null\_exchange\_rates\_currency.sql

16:27:10  

16:27:10  \[ERROR]: in test not\_null\_exchange\_rates\_rate\_month (seeds/exchange\_rates.yml)

16:27:10    Got 1 result, configured to fail if != 0

16:27:10  

16:27:10    compiled code at target/compiled/cdc\_fb\_sp\_marketing/seeds/exchange\_rates.yml/not\_null\_exchange\_rates\_rate\_month.sql

16:27:10  

16:27:10  \[ERROR]: in test not\_null\_exchange\_rates\_rate\_to\_usd (seeds/exchange\_rates.yml)

16:27:10    Got 1 result, configured to fail if != 0

16:27:10  

16:27:10    compiled code at target/compiled/cdc\_fb\_sp\_marketing/seeds/exchange\_rates.yml/not\_null\_exchange\_rates\_rate\_to\_usd.sql

16:27:10  

16:27:10  \[WARNING]: in test relationships\_stg\_snapchat\_ad\_history\_ad\_group\_id\_\_ad\_group\_id\_\_ref\_stg\_snapchat\_ad\_groups\_ (models/staging/snapchat\_ads/stg\_snapchat\_ad\_history.yml)

16:27:10  \[WARNING]: Got 304 results, configured to warn if != 0

16:27:10  

16:27:10    compiled code at target/compiled/cdc\_fb\_sp\_marketing/models/staging/snapchat\_ads/stg\_snapchat\_ad\_history.yml/relationships\_stg\_snapchat\_ad\_\_da8c29f0303cdef34e1d2cd1bba45fb5.sql

16:27:10  

16:27:10  Done. PASS=53 WARN=1 ERROR=3 SKIP=0 NO-OP=0 REUSED=0 TOTAL=57



solutiion:the error appeared because in my exchange rate seed file, i had a new line(empty) aftet the orignal last line in the file, i deleted the empty lines and ran only dbt test on the seed file since i know it was the only one that failed.

synthax : uv run dbt test --select exchange\_rates



output:  Running with dbt=1.12.5

16:37:50  Registered adapter: databricks=1.12.7

16:38:10  Found 13 models, 57 data tests, 1 seed, 9 sources, 777 macros

16:38:10  

16:38:10  Concurrency: 8 threads (target='dev')

16:38:10  

16:38:19  1 of 1 START seed file dbt\_godwin.exchange\_rates ............................... \[RUN]

16:38:25  1 of 1 OK loaded seed file dbt\_godwin.exchange\_rates ........................... \[INSERT 48 in 6.12s]

16:38:25  

16:38:25  Finished running 1 seed in 0 hours 0 minutes and 14.90 seconds (14.90s).

16:38:25  

16:38:25  Completed successfully

16:38:25  

16:38:25  Done. PASS=1 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=1

it was suceesful.



###### **17) Dbt doc ,elementary, packages.yml**

dbt doc is an auntomatically generated website that serves as a visual blue print and dictionary for all the data inside the warehouse.



&#x20;What does it actually show?



If you open a dbt docs website, you will find three main things:

• The Dictionary: A clear list of every data table and column in your warehouse, along with descriptions explaining what they mean (e.g., exactly what user\_id or total\_revenue represents).

• The Blueprint: The exact SQL code used to build and transform that data so anyone can see how a specific number was calculated.

• The Map (Lineage Graph): A visual flowchart showing where your data starts, how it changes, and which final dashboards or reports it flows into.



now to generate the documentation website :

**code : uv run dbt docs generate --static**

This create a documentation website in the target folder. what to expects : your models,columns,tests and an interactive lineage graph dag(showing what depends on what).

a file called :static\_index.html was created and others,



* steps to open it:

Double-click this file in Windows Explorer:

**C:\\Users\\godwi\\Desktop\\marketting\_data\_platform\\cdc\_fb\_sp\_marketing\\target\\static\_index.html**

What to look for

a)Lineage graph (the round icon at the bottom right): click fct\_marketing\_spend. You should see the flow from the sources, through staging, to the intermediate models and the seed, ending at the final model.

b) stg\_facebook\_ad\_groups should appear as a dead end, because nothing uses it. That’s the one for the README.

c) A model page shows the description, the columns and the tests attached to them.

To open the static.html file, i had to go to my local file folder where my project live, i looked through the target folder and i found the static file i doubled clicked on it and bummmm!! a beautiful website showing all my mode;s, the tables, the descriptions , and showing the lineage of how each model depends on each other. the facebook\_ad\_group was at a dead end the staging model part that is, it wasn't called during the intermediate aspect.

i wanted to see how all my models are connected with one another i used this:

**--select +fct\_marketing\_spend**

* the left plus sign(show me everything this depends on towards the left)...it means show me everything upstream. we DE work along the upstream
* this wont work because our final model end at **fct\_marketing\_spend so if you do this --select +fct\_marketing\_spend+, it still only shows other it depends on towards to the left, note that for intermediate models, you definetely see the left and right the int depends on.**
* **--select int\_facebook\_ads+ (show me evrything towards downstream). it doesnt show anything towards the left but the right.**





**Elementary :** is an open-source observability tool for dbt. It remembers every run: it stores test results and run results over time, so I can see which tests failed and when. It has two parts: a dbt package (in packages.yml) that writes the results into its own schema in Databricks, and the edr CLI (in pyproject.toml), which builds the HTML report from those tables. The \[databricks] extra gives edr what it needs to connect to Databricks. I’m not setting up freshness monitoring because my sources are static. so instead of checking the terminal to know which test failed, you can just check from the elementary, it monitors and observes changes.



* recalling that we have already installed the elementary with dbt core.

before we continue, we will need to create the dbt **packages.yml** file. the packages.yml file is an automated app store configuration file for your dbt project. just like an appstore. we already installed elemetary into dbt core, so our packages.yml file would see it.



&#x20;**How it works in practice**



**1. You write the list: You create a file named packages.yml in your main project folder and list the packages you want. For example:yaml**

**packages:**

&#x20; **- package: dbt-labs/dbt\_utils**

&#x20;   **version: 1.1.1**

**Use code with caution.**

**2. You install them: You run the command dbt deps (short for dependencies) in your terminal. dbt reads your list, downloads the code from the internet, and plugs it right into your project.**



Data teams use packages.yml to pull in three main types of pre-built code:

• Software Connectors: If you pull data from platforms like Stripe, Google Analytics, or HubSpot, companies like Fivetran provide packages that automatically clean and organize that data into perfect tables for you.

• Helper Functions (Macros): Packages like dbt-utils give you a library of shortcut commands. For example, instead of writing 20 lines of SQL to unpivot a table or calculate a date, you can use a one-line shortcut.

• Testing Toolkits: Packages like dbt-expectations add advanced data testing capabilities, letting you easily check if your data is accurate before it hits your dashboards.



now i create the packages.yml file.

**there is one very important concept that needs to be taken note of.**

This happens when in this 2 process, at the very start, 

* we installed the elementary with databricks adapter through the python inbuilt packages. what we installed was the CLI tool(edr) the command line interface for the elementary. its the specific terminal command used to operate python elementary command line interface. While your dbt package silently collects logs and test results inside your Databricks database, the edr tool acts as the presenter. It safely logs into your database, grabs all that metadata, and turns it into human-readable results. the one installed in python acts more like the engine.the edr CLI is the dashboard screen: It sits in front of you (on your laptop) and simply reads what the engine is doing, showing you the pretty gauges, speed, and check-engine lights.
* the second aspect is the elementary installed through the dbt packages.By adding Elementary to packages.yml, you are telling dbt: "Hey, go download the pre-written Elementary code." This code contains blueprints for special hidden tables and automatic logging features. It is the heavy machinery running under the hood inside your Databricks warehouse, doing the hard work of capturing logs, processing numbers, and building data tables.

&#x20;                                                 

How it was formed:

initially, elementary does not have any business with dbt, we connect thrugh the databricks adapter witht the help of python ( this is where the elemetary commands lives). so we have 2 now databricks and elementary, now for u to connect does to dbt, u need to install the elementary package for dbt.The Elementary package for dbt powers data observability by turning your dbt artifacts, logs, and run results into structured tables inside your data warehouse.        



&#x20; \[ Your Computer / CLI ]

&#x20;     │

&#x20;     ▼  (Uses your pyproject.toml configuration)

&#x20;1. Elementary Python CLI (edr) 

&#x20;     │

&#x20;     ▼  (Connects via python through...)

&#x20;2. Databricks Adapter (dbt-databricks)

&#x20;     │

&#x20;     ▼  (Reads \& Writes to...)

&#x20;3. Databricks Data Warehouse

&#x20;     ▲

&#x20;     │  (Populates tables using...)

&#x20;4. Elementary dbt Package (packages.yml)

&#x09;



* **Note : lets use a scenario where we have an error in dbt test:**



imagine you have a test checking that user\_id is never blank (null) in your marketing data, and a bad row of data leaks in.



**Phase 1:** The dbt Package Engine goes to work (Inside Databricks)



You open your terminal and type:

bash

dbt test --select stg\_marketing\_users

Use code with caution.

1\. The Failure Happens: dbt runs the SQL test inside Databricks. It discovers 5 rows where user\_id is blank. The test officially Fails.

2\. The Engine Steps In: Because you installed the Elementary dbt package, it acts as a "hook" at the end of the test.

3\. The Engine Writes the Logs: The dbt package automatically writes a row into your Databricks warehouse in the elementary\_test\_results table. It records:

&#x09;• Test Name: not\_null\_stg\_marketing\_users\_user\_id

&#x09;• Status: fail

&#x09;• Fail Count: 5

&#x09;• Time: 2026-10-20 19:20:00

At this point, your terminal command finishes. The information is safely stored as raw rows inside your Databricks database.



**Phase 2:** The edr CLI Dashboard steps in (On your computer or CI pipeline)



Right now, you can't easily see the pretty graphs or get a Slack alert because the failure is just text inside a database table. You need your dashboard screen to read it.



Scenario A: You want to see the Visual Dashboard



You type this command into your terminal:

bash

edr report

Use code with caution.

1\. The CLI Connects: The edr CLI tool wakes up on your computer, uses your Python setup to connect to Databricks, and says: "Hey Databricks, let me see that elementary\_test\_results table."

2\. The CLI Visualizes it: It reads the row about the user\_id failure and instantly builds a local browser webpage. You open it and see a bright red box on your stg\_marketing\_users model, graphing exactly when it failed and showing you the 5 bad rows.



Scenario B: You have automated Slack Alerts



If your company has a scheduled pipeline, it might run this command immediately after dbt finishes:

bash

edr monitor

Use code with caution.

1\. The CLI Checks the Engine: The edr CLI scans the Databricks table, spots the brand-new row marked fail, and grabs the test details.

2\. The CLI pings your team: It reformats that raw row into a beautifully styled message and sends a ping directly to your marketing engineering Slack channel: "🚨 dbt Test Failure: user\_id has 5 null values in stg\_marketing\_users!"





Now, the edr was installed initally with this version:

* dependencies = \[

&#x20;   "dbt-databricks>=1.12.7",

&#x20;   "elementary-data\[databricks]\~=**0.22.0**",] this one sends the data as a report, is the one that actually creates and open the HTML file for u to see via visualization. you get by just running edr report



* \- package: elementary-data/elementary

&#x20;     version: **0.26.1**        this one is the engine that does the work, install through dbt packages, it goes to the databricks warehouse and stores the result in a structured table. while edr send us the rreport. if you notice, they have 2 different versions, this wont work, it will cause an error. that version is from the official dbt-elementary website. the edr initily installed has a different version



**--solution**

&#x20;while installing the elementary in dbt packages.yml(synthatx: uv run dbt deps), put the version as same with edr done at the start **0.22.0 this one.**



so our packages.yml file becomes.....

**packages:**

&#x20; **- package: elementary-data/elementary**

&#x20;   **version: 0.22.0**

**Now, runninng : uv run dbt deps to install the package**

output :
 Running with dbt=1.12.5
19:33:19  Updating lock file in file path: /mnt/c/Users/godwi/Desktop/marketting_data_platform/cdc_fb_sp_marketing/package-lock.yml
19:33:19  Installing elementary-data/elementary
19:34:20  Installed from version 0.22.0
19:34:20  Updated version available: 0.26.1
19:34:20  Installing dbt-labs/dbt_utils
19:34:41  Installed from version 1.4.1
19:34:41  Up to date!
19:34:41  
19:34:41  Updates available for packages: ['elementary-data/elementary']                 
Update your versions in packages.yml, then run dbt deps


succesfully installed.

next is to give elementary its own schema in dbt_project.yml, in dbt_project.yml is a general place for per-folder settings, and the materialization is only one of them.

models:
  cdc_fb_sp_marketing:        # your project
    staging:
      +materialized: view     # a setting: how to build it
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
  elementary:                 # the Elementary package
    +schema: elementary       # a setting: where to put it

The keys under your project name (staging, intermediate, marts) are your folders, and the +materialized lines are the materialization.
elementary: is a separate entry at the same level, for the package. Its models get their own setting, +schema, which says where they go (which schema), not how they’re built.

Now, we build the elemetary model, this will appear in databricks with the structured report:
uv run dbt build --select elementary

output: succesful:
godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting_data_platform/cdc_fb_sp_marketing$ uv run dbt build --select elementary
19:51:48  Running with dbt=1.12.5
19:52:10  [WARNING][CustomKeyInConfigDeprecation]: Deprecated functionality
Custom key `elementary` found in `config` at path
`cdc_fb_sp_marketing.elementary` in file `/mnt/c/Users/godwi/Desktop/marketting_
data_platform/cdc_fb_sp_marketing/dbt_project.yml`. Custom config keys should
move into the `config.meta`.
19:52:10  Registered adapter: databricks=1.12.7
19:52:23  Unable to do partial parsing because a project dependency has been added
19:52:23  Unable to do partial parsing because a project config has changed
19:52:41  Found 43 models, 57 data tests, 1 seed, 2 operations, 9 sources, 1727 macros
19:52:41  
19:52:41  Concurrency: 8 threads (target='dev')
19:52:41  
19:53:02  Elementary: Runtime data: {"config": {}, "dbt_version": "1.12.5", "elementary_version": "0.22.0", "database": "dev_godwin", "schema": "dbt_godwin"}
19:53:04  1 of 1 START hook: elementary.on-run-start.0 ................................... [RUN]
19:53:04  1 of 1 OK hook: elementary.on-run-start.0 ...................................... [OK in 1.69s]
19:53:04  
19:53:04  1 of 30 START sql incremental model dbt_godwin.data_monitoring_metrics ......... [RUN]
19:53:04  2 of 30 START sql incremental model dbt_godwin.dbt_columns ..................... [RUN]
19:53:04  3 of 30 START sql incremental model dbt_godwin.dbt_exposures ................... [RUN]
19:53:04  4 of 30 START sql incremental model dbt_godwin.dbt_groups ...................... [RUN]
19:53:04  5 of 30 START sql incremental model dbt_godwin.dbt_invocations ................. [RUN]
19:53:04  6 of 30 START sql incremental model dbt_godwin.dbt_metrics ..................... [RUN]
19:53:04  7 of 30 START sql incremental model dbt_godwin.dbt_models ...................... [RUN]
19:53:04  8 of 30 START sql incremental model dbt_godwin.dbt_run_results ................. [RUN]
19:53:20  5 of 30 OK created sql incremental model dbt_godwin.dbt_invocations ............ [OK in 15.44s]
19:53:20  1 of 30 OK created sql incremental model dbt_godwin.data_monitoring_metrics .... [OK in 15.46s]
19:53:20  9 of 30 START sql incremental model dbt_godwin.dbt_seeds ....................... [RUN]
19:53:20  10 of 30 START sql incremental model dbt_godwin.dbt_snapshots .................. [RUN]
19:53:20  8 of 30 OK created sql incremental model dbt_godwin.dbt_run_results ............ [OK in 15.73s]
19:53:20  11 of 30 START sql incremental model dbt_godwin.dbt_source_freshness_results ... [RUN]
19:53:21  6 of 30 OK created sql incremental model dbt_godwin.dbt_metrics ................ [OK in 16.97s]
19:53:21  12 of 30 START sql incremental model dbt_godwin.dbt_sources .................... [RUN]
19:53:21  3 of 30 OK created sql incremental model dbt_godwin.dbt_exposures .............. [OK in 16.99s]
19:53:21  13 of 30 START sql incremental model dbt_godwin.dbt_tests ...................... [RUN]
19:53:22  4 of 30 OK created sql incremental model dbt_godwin.dbt_groups ................. [OK in 17.21s]
19:53:22  14 of 30 START sql incremental model dbt_godwin.elementary_test_results ........ [RUN]
19:53:30  11 of 30 OK created sql incremental model dbt_godwin.dbt_source_freshness_results  [OK in 10.43s]
19:53:30  15 of 30 START sql table model dbt_godwin.metadata ............................. [RUN]
19:53:33  10 of 30 OK created sql incremental model dbt_godwin.dbt_snapshots ............. [OK in 12.93s]
19:53:33  16 of 30 START sql incremental model dbt_godwin.schema_columns_snapshot ........ [RUN]
19:53:33  14 of 30 OK created sql incremental model dbt_godwin.elementary_test_results ... [OK in 11.54s]
19:53:33  17 of 30 START sql view model dbt_godwin.job_run_results ....................... [RUN]
19:53:39  17 of 30 OK created sql view model dbt_godwin.job_run_results .................. [OK in 5.93s]
19:53:39  18 of 30 START sql view model dbt_godwin.metrics_anomaly_score ................. [RUN]
19:53:43  18 of 30 OK created sql view model dbt_godwin.metrics_anomaly_score ............ [OK in 3.95s]
19:53:43  19 of 30 START sql view model dbt_godwin.monitors_runs ......................... [RUN]
19:53:44  16 of 30 OK created sql incremental model dbt_godwin.schema_columns_snapshot ... [OK in 10.86s]
19:53:44  20 of 30 START sql view model dbt_godwin.snapshot_run_results .................. [RUN]
19:53:47  15 of 30 OK created sql table model dbt_godwin.metadata ........................ [OK in 16.27s]
19:53:47  21 of 30 START sql view model dbt_godwin.alerts_anomaly_detection .............. [RUN]
19:53:47  19 of 30 OK created sql view model dbt_godwin.monitors_runs .................... [OK in 3.75s]
19:53:47  22 of 30 START sql view model dbt_godwin.alerts_dbt_tests ...................... [RUN]
19:53:47  20 of 30 OK created sql view model dbt_godwin.snapshot_run_results ............. [OK in 3.24s]
19:53:47  23 of 30 START sql view model dbt_godwin.alerts_schema_changes ................. [RUN]
19:53:51  23 of 30 OK created sql view model dbt_godwin.alerts_schema_changes ............ [OK in 3.74s]
19:53:51  22 of 30 OK created sql view model dbt_godwin.alerts_dbt_tests ................. [OK in 3.82s]
19:53:51  24 of 30 START sql incremental model dbt_godwin.test_result_rows ............... [RUN]
19:53:51  21 of 30 OK created sql view model dbt_godwin.alerts_anomaly_detection ......... [OK in 4.13s]
19:53:51  25 of 30 START sql view model dbt_godwin.anomaly_threshold_sensitivity ......... [RUN]
19:53:53  2 of 30 OK created sql incremental model dbt_godwin.dbt_columns ................ [OK in 48.54s]
19:53:53  7 of 30 OK created sql incremental model dbt_godwin.dbt_models ................. [OK in 48.61s]
19:53:53  26 of 30 START sql view model dbt_godwin.model_run_results ..................... [RUN]
19:53:54  9 of 30 OK created sql incremental model dbt_godwin.dbt_seeds .................. [OK in 34.42s]
19:53:54  27 of 30 START sql view model dbt_godwin.seed_run_results ...................... [RUN]
19:53:57  25 of 30 OK created sql view model dbt_godwin.anomaly_threshold_sensitivity .... [OK in 3.91s]
19:53:57  13 of 30 OK created sql incremental model dbt_godwin.dbt_tests ................. [OK in 33.55s]
19:53:57  26 of 30 OK created sql view model dbt_godwin.model_run_results ................ [OK in 2.81s]
19:53:57  12 of 30 OK created sql incremental model dbt_godwin.dbt_sources ............... [OK in 33.08s]
19:53:57  28 of 30 START sql view model dbt_godwin.alerts_dbt_models ..................... [RUN]
19:53:57  29 of 30 START sql view model dbt_godwin.alerts_dbt_source_freshness ........... [RUN]
19:53:57  30 of 30 START sql view model dbt_godwin.dbt_artifacts_hashes .................. [RUN]
19:53:57  27 of 30 OK created sql view model dbt_godwin.seed_run_results ................. [OK in 2.47s]
19:53:57  24 of 30 OK created sql incremental model dbt_godwin.test_result_rows .......... [OK in 6.47s]
19:54:00  29 of 30 OK created sql view model dbt_godwin.alerts_dbt_source_freshness ...... [OK in 2.85s]
19:54:00  30 of 30 OK created sql view model dbt_godwin.dbt_artifacts_hashes ............. [OK in 3.05s]
19:54:00  28 of 30 OK created sql view model dbt_godwin.alerts_dbt_models ................ [OK in 3.28s]
19:54:00  
19:54:16  1 of 1 START hook: elementary.on-run-end.0 ..................................... [RUN]
19:54:16  1 of 1 OK hook: elementary.on-run-end.0 ........................................ [OK in 15.55s]
19:54:16  
19:54:16  Finished running 16 incremental models, 2 project hooks, 1 table model, 13 view models in 0 hours 1 minutes and 35.32 seconds (95.32s).
19:54:16  
19:54:16  Completed successfully
19:54:16  
19:54:16  Done. PASS=32 WARN=0 ERROR=0 SKIP=0 NO-OP=0 REUSED=0 TOTAL=32
19:54:16  [WARNING][DeprecationsSummary]: Deprecated functionality
Summary of encountered deprecations:
- CustomKeyInConfigDeprecation: 1 occurrence
To see all deprecation instances instead of just the first occurrence of each,
run command again with the `--show-all-deprecations` flag. You may also need to
run with `--no-partial-parse` as some deprecations are only encountered during
parsing.
godwinnosa@Nosakharey:/mnt/c/Users/godwi/Desktop/marketting_data_platform/cdc_fb_sp_marketing$ 

--error
an error occurred, after successful, i went further to check the report in databricks, i found out the elementary reports were populated in the schema i didn't define it with. this made my dev_godwin(schema) a mess as it holds the staging and mart transformed data, making the schema holding up to 42 tables. i start to debug for the error and i found out during the process of defining the elementary schema in dbt_project.yml file, i put the schema through a wrong identation: 
notice below:
 cdc_fb_sp_marketing:
    staging:
      +materialized: view
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
    elementary:                 # the Elementary package
    +schema: elementary 

notice that the elementary is inside c9c_fb_sp_marj=keting, but it should have been on the same line. i could have ran uv run dbt_parse, before buiding the elementary model, it would have helped me spot the identation issue. now, i restructure it back well myself:

models:
  cdc_fb_sp_marketing:
    staging:
      +materialized: view
    intermediate:
      +materialized: ephemeral
    marts:
      +materialized: table
  elementary:
    +schema: elementary

now, i run : uv run dbt parse, just to be sure i dont have a wrong identation.
now, next is to rebuild the elementary again, this time around i believe it will build the report to the new schema:
uv run dbt run --select elementary --full-refresh

output : successful,
now, the next task is to  build all my models, this will give the elmementary something to report:
uv run dbt build
once this is done, elementary should have a report to give me, i will then get the report with:
uv run edr report






















































































































































































