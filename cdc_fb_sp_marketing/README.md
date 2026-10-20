# Marketing Data Platform: Databricks + dbt

Raw Facebook Ads and Snapchat Ads exports are loaded into Databricks, transformed with **dbt Core** into one
analytics-ready table, tested, documented and monitored with **Elementary**, and deployed through **GitHub Actions**.

The final model, `fct_marketing_spend`, answers questions such as *"How much did we spend on Facebook last month?"*
and *"Which campaign had the most clicks?"* for three kinds of users: **analysts** (plain SQL), **BI tools**
(a stable, wide table) and an **AI agent** (clear column names and descriptions, no joins needed).

> **Quick links**
> - Static dbt docs with lineage: [`docs/dbt_docs.html`](../docs/dbt_docs.html)
> - Elementary observability report: [`docs/elementary_report.html`](../docs/elementary_report.html)
> - Lineage screenshot: [`docs/lineage.png`](../docs/lineage.png)
> - Unity Catalog grants: [`docs/grants.sql`](../docs/grants.sql)
> - My working journal (every step, error and fix, in my own words): [`docs/PROJECT_JOURNAL.md`](../docs/PROJECT_JOURNAL.md)

---

## Table of contents
1. [Architecture](#1-architecture)
2. [Repository layout](#2-repository-layout)
3. [Loading the raw data](#3-loading-the-raw-data)
4. [Data discoveries that shaped the design](#4-data-discoveries-that-shaped-the-design)
5. [Key design decisions](#5-key-design-decisions)
6. [Models layer by layer](#6-models-layer-by-layer)
7. [The final model](#7-the-final-model-fct_marketing_spend)
8. [Currency conversion](#8-currency-conversion)
9. [Testing strategy](#9-testing-strategy)
10. [A real source-data problem: the missing Snapchat ad groups](#10-a-real-source-data-problem-the-missing-snapchat-ad-groups)
11. [Documentation and observability](#11-documentation-and-observability)
12. [Environments and security](#12-environments-and-security)
13. [CI/CD](#13-cicd)
14. [How to run it](#14-how-to-run-it)
15. [Problems I hit and how I solved them](#15-problems-i-hit-and-how-i-solved-them)
16. [Assumptions and known limits](#16-assumptions-and-known-limits)
17. [Next steps](#17-next-steps)

---

## 1. Architecture

```
Raw CSVs --> Databricks bronze_dev  --> dbt staging --> dbt intermediate --> dbt marts
             facebook_ads (5 tables)    (views)         (ephemeral)          fct_marketing_spend
             snapchat_ads (4 tables)                                         (table)
                                          seed: exchange_rates (ECB monthly EUR->USD)
```

| Layer | Folder | Materialization | Why this choice |
|---|---|---|---|
| Bronze (raw) | catalog `bronze_dev`, schemas `facebook_ads`, `snapchat_ads` | loaded as-is | Untouched source of truth. Every column is stored as text so dbt, not the upload tool, decides how to cast. |
| Staging | `models/staging/` | **view** | Light cleaning only: trim, rename, cast. Cheap, always fresh, nothing to store. |
| Intermediate | `models/intermediate/` | **ephemeral** | Join and union steps that only exist to feed the final model. They are inlined as CTEs, so there are no extra tables to maintain or secure. |
| Marts | `models/marts/` | **table** | The model people query. Built once per run, fast to read, stable for BI tools and the AI agent. |

Materializations are set per folder in `dbt_project.yml`, so a new model inherits the right behaviour automatically.

## 2. Repository layout

```
marketting_data_platform/
├── README.md
├── docs/                         # static dbt docs, Elementary report, lineage, grants, journal
├── .github/workflows/            # CI (pull requests) and deploy (merge to main)
├── pyproject.toml, uv.lock       # pinned Python dependencies (dbt-databricks, elementary-data)
└── cdc_fb_sp_marketing/          # the dbt project
    ├── dbt_project.yml, profiles.yml, packages.yml
    ├── seeds/                    # exchange_rates.csv + yml
    ├── models/
    │   ├── staging/{facebook_ads,snapchat_ads}/   # 8 staging models + source.yml + yml per model
    │   ├── intermediate/         # int_facebook_ads, int_snapchat_ads, int_marketing_ads
    │   └── marts/                # fct_marketing_spend
    └── tests/{generic,singular}/ # custom tests
```

## 3. Loading the raw data

The brief points at Airbyte. I tried it and had to change plan, and I record that honestly:

1. Airbyte installed, but its internal Postgres store was corrupted; I reinstalled it.
2. Airbyte then could not read my local files, because it needs an HTTPS source and my files were local.
3. **Decision:** load the 9 CSVs (5 Facebook, 4 Snapchat) into Databricks manually, with every column as a string.

I kept everything as text on purpose: no hidden casting during upload, and every cleaning decision is visible in
dbt code where it can be reviewed and tested. After loading I compared row counts to the files and checked with
`information_schema.columns` that no column was a non-string type.

## 4. Data discoveries that shaped the design

**Missing values were stored as the text `'null'`, not real NULLs.** `IS NULL` returned 0 rows while `= 'null'`
returned thousands. Staging therefore converts text to real NULL with `try_cast`.

**Facebook `ads_stats` (92,300 rows):** `ad_clicks = 'null'` in 24,337 rows (26%) and `ad_impressions = 'null'`
in 1,474 rows (1.6%); spend is never missing. I asked whether "missing" means "nobody clicked" or "not reported",
and compared the two groups:

| | Clicks present | Clicks missing |
|---|---|---|
| Rows | 67,963 | 24,337 |
| Average impressions | 13,288 | 104 |
| Average spend | $138.39 | $1.09 |

Rows with missing clicks are tiny ads (about 100 impressions), which suggests "no click recorded". All 1,474 rows
with missing impressions also have missing clicks, and no row has clicks without impressions.

> **Decision changed during the build.** My first plan was to set missing clicks to 0. In the final model I keep
> them as **NULL** instead. The source does not say what a missing value means, and zero would silently claim
> "nobody clicked" when the truth is "unknown". NULL is ignored by `sum()`, so totals are not hurt, and CTR/CPC
> come out NULL instead of a misleading 0. (Snapchat has the same pattern: 111 rows with NULL clicks.)

**`ad_id` is not unique in the stats tables**, because one ad runs on many days. The unique key is
`ad_id + ad_date` (Facebook) and `ad_id + ad_date + ad_country` (Snapchat). I confirmed this with `GROUP BY ... HAVING COUNT(*) > 1`
and turned it into permanent tests.

**Facebook has no country column; Snapchat does.** **Both sources contain USD and EUR.**
**Facebook accounts** are the advertiser's clients who pay for ads, so account is an important grouping.

## 5. Key design decisions

| Question | Options considered | Decision and reason |
|---|---|---|
| Grain of the final table | per ad per day, or per campaign per day | **Per ad, per day, per country.** Campaign totals can always be summed up later; ad-level detail can never be recovered from a summary. |
| Snapchat `country` | keep, or sum it away | **Keep it** (Facebook rows get NULL). Dropping it destroys information the analysts may need, and Facebook may add it later. |
| USD vs EUR | leave unconverted with a currency column, or convert | **Convert to USD** with a monthly ECB rate seed, so every platform reports one comparable `spend_usd`. One comparable `spend_usd` makes the platforms comparable. |
| Missing clicks/impressions | set to 0, or keep NULL | **Keep NULL** (see section 4). |
| Fact vs dimensions | star schema or one wide table | **One wide fact table.** Two sources and few attributes: one table is the simplest thing for analysts, BI and an AI agent to query. |
| Surrogate key | composite key, or hash | **`ad_key`** built from date, country, ad_id and source, tested unique. |
| Where tests live | everywhere or selectively | Staging, seed and final model are tested; ephemeral models are covered through the final model. |
| `stg_facebook_ad_groups` | drop, or keep | **Keep** (built and tested) for future ad-group reporting; it is a visible dead end in the lineage. |
| Environments | dev / ci / staging / production | **dev, ci, production.** A separate staging environment was left out as unnecessary at this size. |

## 6. Models layer by layer

**Staging (8 models, views).** One per source table. Only cleaning: trim whitespace, upper-case status values,
`try_cast` numbers and dates, turn `'null'` into NULL, give columns clear names. No business logic.

**Intermediate (3 models, ephemeral).**
- `int_facebook_ads`: ads + campaigns + accounts + daily stats, with `ad_country` as NULL.
- `int_snapchat_ads`: ad history + groups + campaigns + stats, with the real country.
- `int_marketing_ads`: unions both platforms into one shape, adds `ad_key`, and joins the exchange-rate seed to produce `spend_usd`.

**Marts (1 model, table).** `fct_marketing_spend` selects the final columns and calculates the metrics.

## 7. The final model: `fct_marketing_spend`

**Grain: one row per ad, per day, per country.**

Columns: `ad_key`, `platform`, `ad_date`, `account_id`, `campaign_id`, `campaign_name`, `ad_id`, `ad_name`,
`ad_country`, `spend_usd`, `impressions`, `clicks`, `ctr`, `cpc`, `cpm`.

| Metric | Formula | Notes |
|---|---|---|
| `ctr` | `clicks / nullif(impressions, 0)` | Stored as a **fraction** (0.02 means 2%) |
| `cpc` | `spend_usd / nullif(clicks, 0)` | Cost per click, in USD |
| `cpm` | `spend_usd / nullif(impressions, 0) * 1000` | Cost per 1,000 impressions, in USD |

`nullif(x, 0)` turns a zero denominator into NULL, so a division by zero returns NULL instead of crashing the query.

**Rule for analysts:** a ratio is only right for one row. To get CTR/CPC/CPM for a campaign or a month, **sum the
raw columns first and divide afterwards**, for example `sum(clicks) / nullif(sum(impressions), 0)`. Averaging
per-row ratios gives a wrong answer. This warning is written into the model and column descriptions so the AI agent
sees it too.

Example questions:

```sql
-- Total spend by platform
select platform, sum(spend_usd) as spend_usd, sum(impressions) as impressions, sum(clicks) as clicks
from fct_marketing_spend group by platform;

-- Monthly spend and CTR over time
select date_trunc('month', ad_date) as month,
       sum(spend_usd) as spend_usd,
       sum(clicks) / nullif(sum(impressions), 0) as ctr
from fct_marketing_spend group by 1 order by 1;
```

## 8. Currency conversion

`seeds/exchange_rates.csv`: monthly EUR to USD rates (ECB, USD per 1 EUR), Jan 2024 to Dec 2025, 48 rows. USD rows
carry a rate of 1. The join is on month and currency.

- **If a month has no rate, `spend_usd` is NULL** and a singular test (`int_marketing_ads_missing_rate`) fails and
  names the problem, instead of silently under-reporting spend.
- **Monthly update:** add the new rows to the CSV, run `dbt seed`, open a pull request.
- **Assumption:** each account keeps one currency for the whole period, and a monthly average rate is applied to
  every day in that month.
- In production, the rates would come from an automated feed (an ECB table) rather than a CSV in Git. The seed keeps this project self-contained.

## 9. Testing strategy

**57 tests: 56 pass, 1 intentional warning.**

| Type | What it covers |
|---|---|
| Built-in generic | `unique`, `not_null`, `accepted_values` (currency, data_source), `relationships` (every foreign key) |
| Custom generic: `non_negative` | Written once, reused on spend, impressions, clicks and exchange rates |
| Singular | Composite grain of both stats tables, exchange-rate uniqueness (`month + currency`), and "every row with spend got a rate" |
| Final model | `ad_key` unique, key columns not null |

Trade-offs I thought about:
- A **generic** test is reusable across any column; a **singular** test is a one-off query for a rule that
  involves several columns. I started with three singular non-negative checks and merged them into one generic test.
- Seed test failures once came from blank lines at the end of the CSV (3 `not_null` failures); the test caught a
  real file problem, and I fixed the file.
- `dbt parse` checks structure (YAML, Jinja, refs) but not data, so `dbt build` is the real check.

## 10. A real source-data problem: the missing Snapchat ad groups

The `relationships` test from `stg_snapchat_ad_history.ad_group_id` to the ad groups table failed with **304 rows**.

How I investigated:
1. Listed the failing ads with an anti-join (`left join ... where group.id is null`): 304 ads pointed to **85 group ids** that do not exist.
2. Compared raw vs staging group counts: **264 in raw, 264 in staging**. So my transformation lost nothing; the gap is in the source export.
3. Checked the impact: of **2,513 ads, only 63 have any stats**, and **none of the 304 orphan ads has stats or spend**.
4. Checked that those ads still have a `campaign_id` (a campaign is the parent of a group, so they are still attributable).

**Decision:** keep the test but set `severity: warn` so the issue stays visible without blocking the pipeline, and
test `fct_marketing_spend.campaign_id` as `not_null` so the pipeline fails loudly if one of these ads ever starts
spending. The root cause (why the export is missing groups) is unknown and is stated as such.

## 11. Documentation and observability

- **dbt docs:** every model, column and test has a description; `dbt docs generate --static` creates one
  self-contained file with the full lineage graph (`docs/dbt_docs.html`). Source tables use identifiers so lineage links raw tables to staging.
- **Elementary** (dbt package 0.22.0 and the matching `edr` CLI 0.22.0) records every run and test result in a
  separate schema (`<schema>_elementary`), and `edr report` produces a shareable HTML report (`docs/elementary_report.html`).
  Package and CLI versions must match, so both are pinned.
- Source freshness is not monitored because the sources are static exports.

## 12. Environments and security

| Target | Catalog / schema | Used by | Auth |
|---|---|---|---|
| `dev` | `dev_godwin.dbt_godwin` | me, locally | personal token from `secrets.sh` (gitignored) |
| `ci` | CI catalog/schema | GitHub Actions on pull requests | GitHub secrets |
| `production` | production catalog/schema | GitHub Actions on merge to `main` | **Databricks Service Principal (OAuth M2M), no PAT** |

- `profiles.yml` is committed but contains **no secrets**: everything comes from `env_var(...)`.
- `secrets.sh`, `.env`, `target/`, `logs/` and `.venv/` are gitignored.
- The production service principal is granted only what it needs (see [`docs/grants.sql`](../docs/grants.sql)): use the
  production catalog, create and write in its schema, and read the bronze data. Analysts get read-only access to the marts.
- Nobody edits production tables by hand; only merged, tested code reaches them.

## 13. CI/CD

Workflows live in `.github/workflows/`:

- **`ci.yml` (pull request):** checkout, install `uv`, `uv sync`, `dbt deps`, `dbt parse`, then `dbt build --target ci`
  (models, seeds and tests). A red check blocks the merge.
- **`deploy.yml` (push to `main`):** same install steps, then `dbt build --target production` as the service principal, then
  generates docs.

All credentials are GitHub Actions secrets. Workflows run with `--project-dir cdc_fb_sp_marketing` because the dbt
project sits in a sub-folder of the repository.

## 14. How to run it

```bash
uv sync                                  # install dbt-databricks and elementary-data
source secrets.sh                        # DATABRICKS_* variables, DEV_CATALOG, DEV_SCHEMA (not in Git)
cd cdc_fb_sp_marketing
uv run dbt deps                          # install Elementary
uv run dbt seed                          # load exchange rates
uv run dbt build                         # run models and tests in dependency order
uv run dbt docs generate --static        # target/static_index.html
uv run edr report --profiles-dir . --profile-target dev    # edr_target/elementary_report.html
```

Useful selectors: `--select +fct_marketing_spend` (model and everything upstream), `--select stg_facebook_ads+` (model and downstream).

## 15. Problems I hit and how I solved them

| Problem | Cause | Fix |
|---|---|---|
| Catalog creation failed: "Metastore storage root URL does not exist" | Workspace uses default storage | Created the catalog with the default storage location |
| `dbt debug`: "Env var required but not provided" | Variables not loaded in the shell | `secrets.sh` with `export` lines, loaded with `source` |
| Airbyte corrupted / could not read local files | Broken Postgres store; non-HTTPS source | Reinstalled, then switched to manual loading |
| `dbt build select --model` / `Error: No such option` | Flag order | `--select` goes with the double dash |
| `dbt: command not found` style failures | dbt lives in the uv environment | Always `uv run dbt ...` |
| Duplicate `source.yml` blocks | Copied Facebook file into Snapchat | `dbt parse` caught it; cleaned up |
| `dbt show --inline` parse error | Quotes around the query | Wrap the query in outer double quotes |
| Custom test did nothing | `non_negative.sql` macro body was empty | Wrote the test body |
| 12 tests silently disappeared | Overwritten yml headers left `columns:` at top level (`CustomTopLevelKeyDeprecation`) | Restored headers; test count back to 50, confirmed with `dbt ls --resource-type test` |
| `[ERROR]` on a test looked like broken code | `[ERROR]` is printed for data failures too | Read the line below it ("Got N results" = data problem) |
| 3 seed `not_null` failures | Blank lines at the end of the CSV | Removed them and reseeded |
| Elementary tables in the wrong schema | `+schema` config mis-nested | Fixed `dbt_project.yml`, rebuilt with `--full-refresh`, dropped the stale objects |
| `edr report`: "Could not find profile named elementary" | `edr` looks in `~/.dbt` | `--profiles-dir . --profile-target dev` |
| Git push rejected (password / 403) | Token missing `repo`+`workflow` scope or expired | New classic token, credential cache |
| `.user.yml` staged by mistake | `.gitignore` had no trailing newline | Fixed the file and unstaged it |

## 16. Assumptions and known limits

- Exchange rates are monthly averages (one rate per month for every day). Accounts keep one currency over the period.
- Missing clicks/impressions are unknown, not zero (kept as NULL).
- 304 Snapchat ads reference groups missing from the source export; none has spend. Root cause unknown.
- `ad_country` is NULL for Facebook because the source has no country.
- CI/CD workflows and the production service principal need the GitHub secrets and grants to be set up in the target
  workspace before they run; I could not fully exercise a production run from my own laptop.
- Some `source.yml` column descriptions are still marked TODO.

## 17. Next steps

- Dimension tables (`dim_campaign`, `dim_account`) if more attributes or platforms are added.
- Automated exchange-rate feed instead of a seed.
- Incremental materialization for `fct_marketing_spend` once data volume grows.
- Elementary anomaly tests (volume, spend spikes) and Slack alerts.
- Resolve the missing Snapchat groups with the data provider.
