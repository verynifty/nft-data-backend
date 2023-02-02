
select
	SUM(trade_price / 1e18),
	COUNT(*) as "trades",
	MIN(trade_price / 1e18),
	MAX(trade_price / 1e18),
	COUNT(distinct("to")) as "buyers",
	COUNT(distinct("from")) as "sellers",
	collection
from
	nft_transfer nt
where
	nt."timestamp" >= NOW() - interval '2004 HOURS'
	and trade_currency is null
	and trade_marketplace = 1
group by
	collection
order by
	1 desc
limit 20



select current.collection from 
(select
	SUM(trade_price / 1e18) as volume,
	COUNT(*) as "trades",
	MIN(trade_price / 1e18),
	MAX(trade_price / 1e18),
	COUNT(distinct("to")) as "buyers",
	COUNT(distinct("from")) as "sellers",
	COUNT(distinct(trade_marketplace)) as "marketplaces",
	collection as collection
from
	nft_transfer nt
where
	nt."timestamp" >= NOW() - interval '24 HOURS'
	and trade_currency is null
	and trade_marketplace = 1
group by
	collection
order by
	1 desc
	) current,
	(select
	SUM(trade_price / 1e18) as volume,
	COUNT(*) as "trades",
	MIN(trade_price / 1e18),
	MAX(trade_price / 1e18),
	COUNT(distinct("to")) as "buyers",
	COUNT(distinct("from")) as "sellers",
	COUNT(distinct(trade_marketplace)) as "marketplaces",
	collection as collection
from
	nft_transfer nt
where
	nt."timestamp" >= NOW() - interval '48 HOURS'
    and nt."timestamp" <= NOW() - interval '24 HOURS'
	and trade_currency is null
	and trade_marketplace = 1
group by
	collection
order by
	1 desc
	) previous
    GROUP BY collection





select address, current_volume from 
collection
 LEFT JOIN (
select
	SUM(trade_price / 1e18) as current_volume,
	COUNT(*) as "trades",
	MIN(trade_price / 1e18),
	MAX(trade_price / 1e18),
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
	) current on current.current_collection = address 
	left JOIN
	(select
	SUM(trade_price / 1e18) as volume,
	COUNT(*) as "trades",
	MIN(trade_price / 1e18),
	MAX(trade_price / 1e18),
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
	) previous on previous.previous_collection = address 
	 where "type" = 721 or "type" = 1155
    GROUP BY address, current_volume  limit 100




    select
	address,
	name,
	default_image,
	row_to_json(current) as current_period,
		row_to_json(previous) as previous_period
from
	collection
left join (
	select
		SUM(trade_price / 1e18) as volume,
		COUNT(*) as "trades",
		MIN(trade_price / 1e18),
		MAX(trade_price / 1e18),
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
	) current on
	current.current_collection = address
left join
	(
	select
		SUM(trade_price / 1e18) as volume,
		COUNT(*) as "trades",
		MIN(trade_price / 1e18),
		MAX(trade_price / 1e18),
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
	) previous on
	previous.previous_collection = address
where
	"type" = 721
	or "type" = 1155
group by
	address,
	current,
	previous,
	 current.volume
order by
	current.volume desc nulls last
limit 100



	 select
      address,
      name,
      default_image,
      row_to_json(current) as current_period,
        row_to_json(previous) as previous_period,
                row_to_json(latest_trade) as last_trade
    from
      collection
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
      ) current on
      current.current_collection = address
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
      ) previous on
      previous.previous_collection = address
      left join (
      select distinct on (collection) collection, trade_price  / 1e18, "timestamp" from nft_transfer where
         trade_currency is null
        and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
      ) latest_trade on latest_trade.collection = address 
    where
      "type" = 721
      or "type" = 1155
    group by
      address,
      current,
      previous,
      latest_trade,
       current.volume
    order by
      current.volume desc nulls last
    limit 100




    

	 select
      address,
      name,
      default_image,
      row_to_json(current) as current_period,
        row_to_json(previous) as previous_period,
                row_to_json(latest_trade) as last_trade
    from
      collection
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
      ) current on
      current.current_collection = address
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
      ) previous on
      previous.previous_collection = address
      left join (
      select distinct on (collection) collection, trade_price  / 1e18, transaction_hash, "timestamp" from nft_transfer where
         trade_currency is null
        and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
      ) latest_trade on latest_trade.collection = address 
    where
      "type" = 721
      or "type" = 1155
    group by
      address,
      current,
      previous,
      latest_trade,
       current.volume
    order by
      current.volume desc nulls last
    limit 100



    	 select
   address,
   name,
   default_image,
   symbol,
   row_to_json(current) as current_period,
     row_to_json(previous) as previous_period,
             row_to_json(latest_trade) as last_trade
 from
   collection
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
   ) current on
   current.current_collection = address
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
   ) previous on
   previous.previous_collection = address
   left join (
   select distinct on (collection) collection, trade_price  / 1e18 as price, transaction_hash, "timestamp" from nft_transfer where
      trade_currency is null
     and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
   ) latest_trade on latest_trade.collection = address 
 where
   "type" = 721
   or "type" = 1155
 group by
   address,
   current,
   previous,
   latest_trade,
    current.volume
 order by
   current.volume desc nulls last
 limit 2000 offset 0




  select
	c.address,
	c."name",
	c.symbol,
	D.transfers_daily,
	H.transfers_daily,
	row_to_json(current),
	row_to_json(previous)
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
		COUNT(*) as transfers_daily,
		COUNT(distinct("to")) as receivers_daily,
		COUNT(distinct("from")) as senders_daily
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
   ) current on
   current.current_collection = address
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
   ) previous on
   previous.previous_collection = address
   left join (
   select distinct on (collection) collection, trade_price  / 1e18 as price, transaction_hash, "timestamp" from nft_transfer where
      trade_currency is null
     and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
   ) latest_trade on latest_trade.collection = address 
where
	c."type" = 721
	or c."type" = 1155
limit 5000
 


 
 select
	c.address,
	c."name",
	c.symbol,
	coalesce(D.transfers_daily, 0) as transfers_daily,
	coalesce(H.transfers_daily, 0) as transfers_hourly,
	row_to_json(current_day) as trades_current_day,
	row_to_json(previous_day)  as trades_previous_day,
		row_to_json(current_hour) as trades_current_hour,
	row_to_json(previous_hour) as trades_prev_hour
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
		COUNT(*) as transfers_daily,
		COUNT(distinct("to")) as receivers_daily,
		COUNT(distinct("from")) as senders_daily
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
     and trade_marketplace is not NULL
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
     and trade_marketplace is not NULL
   group by
     collection
   ) previous_hour on
   previous_hour.previous_collection = address
   left join (
   select distinct on (collection) collection, trade_price  / 1e18 as price, transaction_hash, "timestamp" from nft_transfer where
      trade_currency is null
     and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
   ) latest_trade on latest_trade.collection = address 
where
 c.type = 1155 OR c.type = 721
 LIMIT 1000




 select
    c."address",
    c."name",
    c.symbol,
    c.default_image,
    c."type",
    c."slug",
	coalesce(D.transfers_daily, 0) as transfers_daily,
	coalesce(D.receivers_daily, 0) as receivers_daily,
	coalesce(D.senders_daily, 0) as senders_daily,
	coalesce(H.transfers_hourly, 0) as transfers_hourly,
	coalesce(H.receivers_hourly, 0) as receivers_hourly,
	coalesce(H.senders_hourly, 0) as senders_hourly,
	row_to_json(current_day) as trades_current_day,
	row_to_json(previous_day)  as trades_previous_day,
		row_to_json(current_hour) as trades_current_hour,
	row_to_json(previous_hour) as trades_prev_hour
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
     and trade_marketplace is not NULL
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
     and trade_marketplace is not NULL
   group by
     collection
   ) previous_hour on
   previous_hour.previous_collection = address
   left join (
   select distinct on (collection) collection, trade_price  / 1e18 as price, transaction_hash, "timestamp" from nft_transfer where
      trade_currency is null
     and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
   ) latest_trade on latest_trade.collection = address 
where
 c.type = 1155 OR c.type = 721
 LIMIT 1000
 
 
 
 
 
 


  select
    c."address",
    c."name",
    c.symbol,
    c.default_image,
    c."type",
    c."slug",
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
	row_to_json(previous_hour) as trades_prev_hour
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
     and trade_marketplace is not NULL
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
     and trade_marketplace is not NULL
   group by
     collection
   ) previous_hour on
   previous_hour.previous_collection = address
   left join (
   select distinct on (collection) collection, trade_price  / 1e18 as price, transaction_hash, "timestamp" from nft_transfer where
      trade_currency is null
     and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
   ) latest_trade on latest_trade.collection = address 
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
 LIMIT 1000

 DROP MATERIALIZED VIEW nft_collection_stats


   select
    c."address",
    c."name",
    c.symbol,
    c.default_image,
    c."type",
    c."slug",
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
	row_to_json(previous_hour) as trades_prev_hour
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
     and trade_marketplace is not NULL
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
     and trade_marketplace is not NULL
   group by
     collection
   ) previous_hour on
   previous_hour.previous_collection = address
   left join (
   select distinct on (collection) collection, trade_price  / 1e18 as price, transaction_hash, "timestamp" from nft_transfer where
      trade_currency is null
     and trade_marketplace = 1 order by collection, nft_transfer."timestamp" desc 
   ) latest_trade on latest_trade.collection = address 
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