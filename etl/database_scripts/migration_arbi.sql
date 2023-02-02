# delete collection search weight
# delete insertion hooks  on collection

ALTER TABLE public.collection ADD transfers_total numeric NULL DEFAULT 0;
ALTER TABLE public.collection ADD metadata jsonb NULL;
ALTER TABLE public.collection ADD first_transfer timestamp NULL DEFAULT NOW();

DROP TRIGGER IF EXISTS nft_search_weights_update ON nft; 
DROP TRIGGER IF EXISTS collection_search_weights_update ON collection;


DROP INDEX nft_search_weights_idx;
DROP INDEX collection_search_weights_idx;

DROP TRIGGER IF EXISTS nft_search_weights_update ON nft; 
DROP TRIGGER IF EXISTS collection_search_weights_update ON collection;


update collection set transfers_total = 
     (select COUNT(*) from nft_transfer where nft_transfer."collection" = collection."address")
     
     
     
      UPDATE collection
SET first_transfer = subquery.minima
FROM (SELECT MIN(nft_transfer.timestamp) as minima, nft_transfer.collection as address
      FROM  nft_transfer GROUP BY 2) AS subquery
WHERE collection.address=subquery.address;


create
or replace function nft_transfer_on_insert() returns trigger language PLPGSQL as 
$$ declare target_nft nft;
begin
	
UPDATE "collection" 
   SET transfers_total = transfers_total + 1
WHERE NEW."collection" = collection."address";
select
    * into target_nft
from
    nft
where
    nft."address" = NEW."collection"
    and nft."token_id" = NEW."token_id";

if not found then
insert into
    nft (
        "address",
        "token_id",
        "latest_block_number",
        "owner"
    )
values
    (
        new."collection",
        new."token_id",
        new."block_number",
        new."to"
    );

else if target_nft."latest_block_number" < new."block_number"
OR (
    target_nft."latest_block_number" = new."block_number"
    AND target_nft."latest_log_index" <= NEW."log_index"
) then
update
    nft
set
    "owner" = NEW."to",
    "latest_block_number" = NEW."block_number",
    "latest_log_index" = NEW."log_index",
    "updated_at" = NOW()
where
    nft."address" = NEW."collection"
    and nft."token_id" = NEW."token_id";

end if;
end if;
return new;
end;
$$;



DROP MATERIALIZED VIEW



CREATE OR REPLACE FUNCTION _final_median(numeric[])
   RETURNS numeric AS
$$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$$
LANGUAGE 'sql' IMMUTABLE;

CREATE AGGREGATE median(numeric) (
  SFUNC=array_append,
  STYPE=numeric[],
  FINALFUNC=_final_median,
  INITCOND='{}'
);






         create materialized view nft_collection_stats AS
    select
    c."address",
    c."transfers_total" as transfers_total,
    supply,
    owners,
	coalesce(D.transfers_daily, 0) as transfers_daily,
	coalesce(D.receivers_daily, 0) as receivers_daily,
	coalesce(D.senders_daily, 0) as senders_daily,
	coalesce(H.transfers_hourly, 0) as transfers_hourly,
	coalesce(H.receivers_hourly, 0) as receivers_hourly,
	coalesce(H.senders_hourly, 0) as senders_hourly,
	row_to_json(current_day) as trades_current_day,
	row_to_json(previous_day)  as trades_previous_day,
	row_to_json(current_hour) as trades_current_hour,
	row_to_json(previous_hour) as trades_previous_hour,
  row_to_json(current_week) as trades_current_week,
	row_to_json(previous_week) as trades_previous_week,
		row_to_json(current_month) as trades_current_month,
	row_to_json(previous_month) as trades_previous_month
from
	collection c
left join (
	select
		collection,
		COUNT(*) as transfers_daily,
		COUNT(distinct("to")) as receivers_daily,
		COUNT(distinct("from")) as senders_daily
	from
		nft_transfer nt
	where
		nt."timestamp" > (CURRENT_DATE - '7 day' :: interval)
	group by
		collection
    ) D on
	D.collection = c.address
	left join (
	select
		collection,
		COUNT(*) as transfers_hourly,
		COUNT(distinct("to")) as receivers_hourly,
		COUNT(distinct("from")) as senders_hourly
	from
		nft_transfer nt
	where
		nt."timestamp" > (CURRENT_DATE - '1 day' :: interval)
	group by
		collection
    ) H on
	H.collection = c.address
	left join (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as current_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW() - interval '24 HOURS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) current_day on
   current_day.current_collection = address
 left join
   (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as previous_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW() - interval '48 HOURS'
     and nt."timestamp" <= NOW() - interval '24 HOURS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) previous_day on
   previous_day.previous_collection = address
   left join (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as current_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW()::timestamp - interval '1 HOURS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) current_hour on
   current_hour.current_collection = address
 left join
   (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as previous_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= LOCALTIMESTAMP(0) - interval '2 HOURS'
     and nt."timestamp" <= LOCALTIMESTAMP(0) - interval '1 HOURS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) previous_hour on
   previous_hour.previous_collection = address
   left join (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as current_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW() - interval '7 DAYS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) current_week on
   current_week.current_collection = address
 left join
   (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as previous_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW() - interval '14 DAYS'
     and nt."timestamp" <= NOW() - interval '7 DAYS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) previous_week on
   previous_week.previous_collection = address
      left join (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as current_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW() - interval '30 DAYS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) current_month on
   current_month.current_collection = address
 left join
   (
   select
     SUM(trade_price / 1e18) as volume,
     COUNT(*) as "trades",
     MIN(trade_price / 1e18) as min_price,
     MAX(trade_price / 1e18) as max_price,
     median(trade_price / 1e18) as median_price,
     COUNT(distinct("to")) as "buyers",
     COUNT(distinct("from")) as "sellers",
     COUNT(distinct(trade_marketplace)) as "marketplaces",
     collection as previous_collection
   from
     nft_transfer nt
   where
     nt."timestamp" >= NOW() - interval '60 DAYS'
     and nt."timestamp" <= NOW() - interval '30 DAYS'
     and trade_currency is null
     and trade_marketplace = 1
   group by
     collection
   ) previous_month on
   previous_month.previous_collection = address
    LEFT JOIN (
        SELECT
            address,
            COUNT(*) as supply,
            COUNT(distinct("owner")) as owners
        FROM
            nft
        GROUP BY
            address
    ) N ON N.address = c.address
where
 c.type = 1155 OR c.type = 721



    CREATE UNIQUE INDEX nft_collection_stats_idx ON nft_collection_stats (address);




    

