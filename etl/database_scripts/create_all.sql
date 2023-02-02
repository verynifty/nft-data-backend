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

CREATE TABLE token_transfer (
    "collection" varchar(42) NULL,
    "block_number" numeric NULL,
    "transaction_hash" varchar(66) NULL,
    "transaction_index" BIGINT NULL,
    "tx_to" varchar(42) NULL,
    "tx_from" varchar(42) NULL,
    "log_index" BIGINT NULL,
    "timestamp" timestamp NULL,
    "to" varchar(42) NULL,
    "from" varchar(42) NULL,
    "amount" NUMERIC NULL,
    "created_at" TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_token_transfer UNIQUE ("transaction_hash", "log_index")
);

CREATE TABLE nft_transfer (
    "collection" varchar(42) NOT NULL,
    "block_number" BIGINT NOT NULL,
    "transaction_hash" varchar(66) NOT NULL,
    "transaction_index" NUMERIC NULL,
    "tx_to" varchar(42) NULL,
    "tx_from" varchar(42) NULL,
    "log_index" BIGINT NOT NULL,
    "transfer_index" BIGINT NOT NULL,
    "timestamp" timestamp NULL,
    "to" varchar(42) NULL,
    "from" varchar(42) NULL,
    "amount" NUMERIC NULL,
    "token_id" NUMERIC NULL,
    "gas_price" NUMERIC NULL,
    "created_at" TIMESTAMP DEFAULT NOW(),
    "trade_currency" varchar NULL,
	"trade_price" numeric NULL,
	"trade_marketplace" int2 NULL,
    CONSTRAINT unique_nft_transfer UNIQUE (
        "transaction_hash",
        "log_index",
        "transfer_index"
    )
);

CREATE INDEX nft_transfer_collection_idx ON nft_transfer (collection);

CREATE INDEX nft_transfer_to_idx ON nft_transfer ("to");

CREATE INDEX nft_transfer_to_blocknumber ON nft_transfer ("block_number");

CREATE INDEX nft_transfer_to_log_index ON nft_transfer ("log_index");

CREATE INDEX nft_transfer_order_chain ON nft_transfer ("block_number" DESC, "log_index" DESC);

CREATE INDEX nft_transfer_from_idx ON nft_transfer ("from");

CREATE INDEX nft_transfer_trade_marketplace ON nft_transfer ("trade_marketplace");

CREATE INDEX nft_transfer_trade_currency ON nft_transfer ("trade_currency");

CREATE INDEX nft_transfer_timestamp ON nft_transfer (timestamp);


     CREATE INDEX nft_trades_index_ordered_partial ON nft_transfer (timestamp desc)
WHERE  trade_currency is null
     and trade_marketplace = 1


CREATE TABLE collection (
    "address" varchar(42) NOT NULL,
    "name" varchar NULL,
    "symbol" varchar NULL,
    "default_image" varchar NULL,
    "slug" varchar NULL,
    "decimals" numeric NULL,
    "first_block_seen" numeric null,
    "type" smallint null,
    "owner" varchar null,
    "created_at" TIMESTAMP DEFAULT NOW(),
    "nft_data_base_url" varchar null,
    "nft_image_base_url" varchar null,
    "transfers_total" numeric NULL DEFAULT 0,
    "metadata" jsonb NULL,
	  "first_transfer" timestamp NULL DEFAULT now(),
    CONSTRAINT data_unique_collection UNIQUE ("address"),
    CONSTRAINT data_unique_slug UNIQUE ("slug"),
    PRIMARY KEY ("address")
);

CREATE UNIQUE INDEX collection_address_idx ON collection (address);

CREATE INDEX collection_type_idx ON collection ("type");

CREATE INDEX collection_address ON collection ("address");

CREATE extension IF NOT EXISTS hstore;

CREATE TABLE nft (
    "address" varchar(42),
    "token_id" NUMERIC,
    "name" varchar,
    "description" varchar NULL,
    "external_url" varchar NULL,
    "original_image" varchar NULL,
    "image" varchar NULL,
    "original_animation" varchar NULL,
    "attributes" hstore,
    "metadata_type" smallint NULL,
    "image_type" smallint NULL,
    "owner" varchar NULL,
    "created_at" TIMESTAMP DEFAULT NOW(),
    "updated_at" TIMESTAMP DEFAULT NOW(),
    "latest_block_number" NUMERIC DEFAULT 0,
    "latest_log_index" NUMERIC DEFAULT 0,
    CONSTRAINT data_unique_nft UNIQUE ("address", "token_id"),
    PRIMARY KEY ("address", "token_id")
);

CREATE INDEX nft_owner ON nft ("owner");

CREATE INDEX nft_address ON nft ("address");

CREATE INDEX idx_nft_update_at ON nft ("updated_at");

CREATE TABLE block (
    "erc721_transfers" NUMERIC,
    "erc1155_transfers" NUMERIC,
    "erc20_transfers" NUMERIC,
    "block_number" NUMERIC,
    "created_at" TIMESTAMP DEFAULT NOW(),
    CONSTRAINT block_unique_number UNIQUE ("block_number")
);

CREATE INDEX block_number ON block ("block_number");



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

REFRESH MATERIALIZED view CONCURRENTLY nft_collection_stats;

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
 
 
 
 

CREATE TRIGGER nft_transfer_insert BEFORE
INSERT
    ON nft_transfer FOR EACH ROW EXECUTE PROCEDURE nft_transfer_on_insert ();



return new;

end;

$ $;






CREATE TABLE zora_offer (
    "block_number" BIGINT NOT NULL,
    "timestamp" TIMESTAMP DEFAULT NULL,
    "log_index" BIGINT NOT NULL,
    "transaction_hash" varchar(66) NOT NULL,
    "offer_id" NUMERIC NULL,
    "address" varchar(42) NULL,
    "token_id" NUMERIC NULL,
    "status" int2 NULL,
    "buyer" varchar(42) NULL,
    "finder" varchar(42) NULL,
    "seller" varchar(42) NULL,
    "currency" varchar(42) NULL,
    "price" NUMERIC NULL,
    "fee" BIGINT NOT NULL,
    CONSTRAINT unique_zora_offer UNIQUE (
        "transaction_hash",
        "log_index"
    )
);

CREATE TABLE zora_ask (
    "block_number" BIGINT NOT NULL,
    "timestamp" TIMESTAMP DEFAULT NULL,
    "log_index" BIGINT NOT NULL,
    "transaction_hash" varchar(66) NOT NULL,
    "address" varchar(42) NULL,
    "token_id" NUMERIC NULL,
    "status" int2 NULL,
    "buyer" varchar(42) NULL,
    "finder" varchar(42) NULL,
    "seller" varchar(42) NULL,
    "seller_funds_recipient" varchar(42) NULL,
    "currency" varchar(42) NULL,
    "price" NUMERIC NULL,
    "fee" BIGINT NOT NULL,
    CONSTRAINT unique_zora_ask UNIQUE (
        "transaction_hash",
        "log_index"
    )
);



CREATE TABLE follow_collection (
    "follower" varchar(42) NOT NULL,
    "collection" varchar(42) NOT NULL,
    "created_at" TIMESTAMP DEFAULT NOW(),
    CONSTRAINT unique_follow_collection UNIQUE (
        "follower",
        "collection"
    )
);