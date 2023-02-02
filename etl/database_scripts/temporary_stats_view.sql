        create materialized view test_nft_collection_stats AS
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
	first_transfer.first_transfer_timestamp as first_transfer_timestamp
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
   select collection, MIN("timestamp") as first_transfer_timestamp from nft_transfer GROUP BY collection
   ) first_transfer on first_transfer.collection = address 
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







 Limit  (cost=13031300.41..13033765.98 rows=10 width=310)
  ->  Hash Left Join  (cost=13031300.41..28041190.82 rows=60878 width=310)
        Hash Cond: ((c.address)::text = (first_transfer.collection)::text)
        ->  Merge Left Join  (cost=6941564.85..21950382.28 rows=60878 width=512)
              Merge Cond: ((c.address)::text = (nft.address)::text)
              ->  Merge Left Join  (cost=6941564.16..6994661.22 rows=60878 width=496)
                    Merge Cond: ((c.address)::text = (previous_week.previous_collection)::text)
                    ->  Merge Left Join  (cost=6686087.50..6735825.25 rows=60878 width=429)
                          Merge Cond: ((c.address)::text = (current_week.current_collection)::text)
                          ->  Merge Left Join  (cost=6387801.30..6433824.62 rows=60878 width=362)
                                Merge Cond: ((c.address)::text = (previous_hour.previous_collection)::text)
                                ->  Merge Left Join  (cost=6387792.69..6433663.49 rows=60878 width=295)
                                      Merge Cond: ((c.address)::text = (current_hour.current_collection)::text)
                                      ->  Merge Left Join  (cost=6387786.13..6433504.42 rows=60878 width=228)
                                            Merge Cond: ((c.address)::text = (previous_day.previous_collection)::text)
                                            ->  Merge Left Join  (cost=6313550.86..6357675.67 rows=60878 width=161)
                                                  Merge Cond: ((c.address)::text = (current_day.current_collection)::text)
                                                  ->  Merge Left Join  (cost=6238723.80..6281218.86 rows=60878 width=94)
                                                        Merge Cond: ((c.address)::text = (nt_1.collection)::text)
                                                        ->  Merge Left Join  (cost=5110770.76..5146369.89 rows=60878 width=70)
                                                              Merge Cond: ((c.address)::text = (nt.collection)::text)
                                                              ->  Sort  (cost=42831.37..42983.56 rows=60878 width=46)
                                                                    Sort Key: c.address
                                                                    ->  Bitmap Heap Scan on collection c  (cost=4150.90..36117.50 rows=60878 width=46)
                                                                          Recheck Cond: ((type = 1155) OR (type = 721))
                                                                          ->  BitmapOr  (cost=4150.90..4150.90 rows=61814 width=0)
                                                                                ->  Bitmap Index Scan on collection_type_idx  (cost=0.00..478.05 rows=7150 width=0)
                                                                                      Index Cond: (type = 1155)
                                                                                ->  Bitmap Index Scan on collection_type_idx  (cost=0.00..3642.41 rows=54665 width=0)
                                                                                      Index Cond: (type = 721)
                                                              ->  GroupAggregate  (cost=5067939.39..5103148.08 rows=6165 width=67)
                                                                    Group Key: nt.collection
                                                                    ->  Sort  (cost=5067939.39..5074968.80 rows=2811763 width=129)
                                                                          Sort Key: nt.collection
                                                                          ->  Index Scan using nft_transfer_timestamp on nft_transfer nt  (cost=0.57..4382330.79 rows=2811763 width=129)
                                                                                Index Cond: ("timestamp" > (CURRENT_DATE - '7 days'::interval))
                                                        ->  GroupAggregate  (cost=1127953.04..1134610.72 rows=6165 width=67)
                                                              Group Key: nt_1.collection
                                                              ->  Sort  (cost=1127953.04..1129272.25 rows=527682 width=129)
                                                                    Sort Key: nt_1.collection
                                                                    ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_1  (cost=0.57..1005649.69 rows=527682 width=129)
                                                                          Index Cond: ("timestamp" > (CURRENT_DATE - '1 day'::interval))
                                                  ->  Subquery Scan on current_day  (cost=74827.06..76287.29 rows=4378 width=110)
                                                        ->  GroupAggregate  (cost=74827.06..76243.51 rows=4378 width=203)
                                                              Group Key: nt_2.collection
                                                              ->  Sort  (cost=74827.06..74846.15 rows=7635 width=136)
                                                                    Sort Key: nt_2.collection
                                                                    ->  Bitmap Heap Scan on nft_transfer nt_2  (cost=44590.76..74334.66 rows=7635 width=136)
                                                                          Recheck Cond: (("timestamp" >= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                                          Filter: (trade_currency IS NULL)
                                                                          ->  BitmapAnd  (cost=44590.76..44590.76 rows=7635 width=0)
                                                                                ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..8482.82 rows=377367 width=0)
                                                                                      Index Cond: ("timestamp" >= (now() - '24:00:00'::interval))
                                                                                ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36103.86 rows=1911373 width=0)
                                                                                      Index Cond: (trade_marketplace = 1)
                                            ->  Subquery Scan on previous_day  (cost=74235.27..75659.58 rows=4286 width=110)
                                                  ->  GroupAggregate  (cost=74235.27..75616.72 rows=4286 width=203)
                                                        Group Key: nt_3.collection
                                                        ->  Sort  (cost=74235.27..74253.59 rows=7325 width=136)
                                                              Sort Key: nt_3.collection
                                                              ->  Bitmap Heap Scan on nft_transfer nt_3  (cost=45148.96..73765.06 rows=7325 width=136)
                                                                    Recheck Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                                    Filter: (trade_currency IS NULL)
                                                                    ->  BitmapAnd  (cost=45148.96..45148.96 rows=7326 width=0)
                                                                          ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..9041.18 rows=362060 width=0)
                                                                                Index Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)))
                                                                          ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36103.86 rows=1911373 width=0)
                                                                                Index Cond: (trade_marketplace = 1)
                                      ->  Subquery Scan on current_hour  (cost=6.56..6.87 rows=1 width=110)
                                            ->  GroupAggregate  (cost=6.56..6.86 rows=1 width=203)
                                                  Group Key: nt_4.collection
                                                  ->  Sort  (cost=6.56..6.56 rows=1 width=136)
                                                        Sort Key: nt_4.collection
                                                        ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_4  (cost=0.57..6.55 rows=1 width=136)
                                                              Index Cond: ("timestamp" >= ((now())::timestamp without time zone - '01:00:00'::interval))
                                                              Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                                ->  Subquery Scan on previous_hour  (cost=8.61..8.92 rows=1 width=110)
                                      ->  GroupAggregate  (cost=8.61..8.91 rows=1 width=203)
                                            Group Key: nt_5.collection
                                            ->  Sort  (cost=8.61..8.62 rows=1 width=136)
                                                  Sort Key: nt_5.collection
                                                  ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_5  (cost=0.58..8.60 rows=1 width=136)
                                                        Index Cond: (("timestamp" >= (LOCALTIMESTAMP(0) - '02:00:00'::interval)) AND ("timestamp" <= (LOCALTIMESTAMP(0) - '01:00:00'::interval)))
                                                        Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                          ->  Subquery Scan on current_week  (cost=298286.20..301824.04 rows=6164 width=110)
                                ->  GroupAggregate  (cost=298286.20..301762.40 rows=6164 width=203)
                                      Group Key: nt_6.collection
                                      ->  Sort  (cost=298286.20..298418.92 rows=53090 width=136)
                                            Sort Key: nt_6.collection
                                            ->  Bitmap Heap Scan on nft_transfer nt_6  (cost=95087.63..290490.16 rows=53090 width=136)
                                                  Recheck Cond: ((trade_marketplace = 1) AND ("timestamp" >= (now() - '7 days'::interval)))
                                                  Filter: (trade_currency IS NULL)
                                                  ->  BitmapAnd  (cost=95087.63..95087.63 rows=53093 width=0)
                                                        ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36103.86 rows=1911373 width=0)
                                                              Index Cond: (trade_marketplace = 1)
                                                        ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..58956.97 rows=2624053 width=0)
                                                              Index Cond: ("timestamp" >= (now() - '7 days'::interval))
                    ->  Subquery Scan on previous_week  (cost=255476.66..258659.39 rows=6159 width=110)
                          ->  GroupAggregate  (cost=255476.66..258597.80 rows=6159 width=203)
                                Group Key: nt_7.collection
                                ->  Sort  (cost=255476.66..255584.11 rows=42983 width=136)
                                      Sort Key: nt_7.collection
                                      ->  Bitmap Heap Scan on nft_transfer nt_7  (cost=89171.20..249228.80 rows=42983 width=136)
                                            Recheck Cond: ((trade_marketplace = 1) AND ("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
                                            Filter: (trade_currency IS NULL)
                                            ->  BitmapAnd  (cost=89171.20..89171.20 rows=42986 width=0)
                                                  ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36103.86 rows=1911373 width=0)
                                                        Index Cond: (trade_marketplace = 1)
                                                  ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..53045.60 rows=2124502 width=0)
                                                        Index Cond: (("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
              ->  GroupAggregate  (cost=0.69..14955483.11 rows=6143 width=59)
                    Group Key: nft.address
                    ->  Index Scan using nft_address on nft  (cost=0.69..14567300.07 rows=51749548 width=85)
        ->  Hash  (cost=6089658.50..6089658.50 rows=6165 width=51)
              ->  Subquery Scan on first_transfer  (cost=6089535.20..6089658.50 rows=6165 width=51)
                    ->  HashAggregate  (cost=6089535.20..6089596.85 rows=6165 width=51)
                          Group Key: nft_transfer.collection
                          ->  Seq Scan on nft_transfer  (cost=0.00..5617202.47 rows=94466547 width=51)





Limit  (cost=13035661.31..13038063.84 rows=10 width=310) (actual time=88949.935..89027.609 rows=10 loops=1)
  ->  Hash Left Join  (cost=13035661.31..28049260.71 rows=62491 width=310) (actual time=88949.934..89027.605 rows=10 loops=1)
        Hash Cond: ((c.address)::text = (first_transfer.collection)::text)
        ->  Merge Left Join  (cost=6945554.32..21958052.31 rows=62491 width=512) (actual time=15062.881..15140.436 rows=22 loops=1)
              Merge Cond: ((c.address)::text = (nft.address)::text)
              ->  Merge Left Join  (cost=6945553.63..6998704.81 rows=62491 width=496) (actual time=15062.630..15070.221 rows=22 loops=1)
                    Merge Cond: ((c.address)::text = (previous_week.previous_collection)::text)
                    ->  Merge Left Join  (cost=6689889.22..6739675.54 rows=62491 width=429) (actual time=12972.256..12974.840 rows=22 loops=1)
                          Merge Cond: ((c.address)::text = (current_week.current_collection)::text)
                          ->  Merge Left Join  (cost=6392061.36..6438132.39 rows=62491 width=362) (actual time=11007.708..11009.063 rows=22 loops=1)
                                Merge Cond: ((c.address)::text = (previous_hour.previous_collection)::text)
                                ->  Merge Left Join  (cost=6392052.75..6437967.23 rows=62491 width=295) (actual time=11007.695..11009.040 rows=22 loops=1)
                                      Merge Cond: ((c.address)::text = (current_hour.current_collection)::text)
                                      ->  Merge Left Join  (cost=6392046.19..6437804.12 rows=62491 width=228) (actual time=11007.670..11009.005 rows=22 loops=1)
                                            Merge Cond: ((c.address)::text = (previous_day.previous_collection)::text)
                                            ->  Merge Left Join  (cost=6317979.70..6362143.89 rows=62491 width=161) (actual time=10483.166..10484.223 rows=22 loops=1)
                                                  Merge Cond: ((c.address)::text = (current_day.current_collection)::text)
                                                  ->  Merge Left Join  (cost=6243329.90..6285864.15 rows=62491 width=94) (actual time=10113.026..10113.884 rows=22 loops=1)
                                                        Merge Cond: ((c.address)::text = (nt_1.collection)::text)
                                                        ->  Merge Left Join  (cost=5111372.33..5146981.91 rows=62491 width=70) (actual time=8817.263..8817.955 rows=22 loops=1)
                                                              Merge Cond: ((c.address)::text = (nt.collection)::text)
                                                              ->  Sort  (cost=43127.46..43283.69 rows=62491 width=46) (actual time=390.298..390.325 rows=22 loops=1)
                                                                    Sort Key: c.address
                                                                    Sort Method: external merge  Disk: 3552kB
                                                                    ->  Bitmap Heap Scan on collection c  (cost=4259.94..36224.63 rows=62491 width=46) (actual time=8.872..53.047 rows=62328 loops=1)
                                                                          Recheck Cond: ((type = 1155) OR (type = 721))
                                                                          Heap Blocks: exact=16260
                                                                          ->  BitmapOr  (cost=4259.94..4259.94 rows=63446 width=0) (actual time=6.558..6.559 rows=0 loops=1)
                                                                                ->  Bitmap Index Scan on collection_type_idx  (cost=0.00..473.43 rows=7067 width=0) (actual time=1.120..1.120 rows=10161 loops=1)
                                                                                      Index Cond: (type = 1155)
                                                                                ->  Bitmap Index Scan on collection_type_idx  (cost=0.00..3755.26 rows=56379 width=0) (actual time=5.437..5.437 rows=71986 loops=1)
                                                                                      Index Cond: (type = 721)
                                                              ->  GroupAggregate  (cost=5068244.87..5103455.71 rows=6165 width=67) (actual time=8426.961..8427.600 rows=4 loops=1)
                                                                    Group Key: nt.collection
                                                                    ->  Sort  (cost=5068244.87..5075274.71 rows=2811935 width=129) (actual time=8425.603..8425.761 rows=590 loops=1)
                                                                          Sort Key: nt.collection
                                                                          Sort Method: external merge  Disk: 407896kB
                                                                          ->  Index Scan using nft_transfer_timestamp on nft_transfer nt  (cost=0.57..4382595.60 rows=2811935 width=129) (actual time=0.041..1075.966 rows=2998755 loops=1)
                                                                                Index Cond: ("timestamp" > (CURRENT_DATE - '7 days'::interval))
                                                        ->  GroupAggregate  (cost=1131957.57..1138639.72 rows=6165 width=67) (actual time=1295.759..1295.904 rows=4 loops=1)
                                                              Group Key: nt_1.collection
                                                              ->  Sort  (cost=1131957.57..1133281.67 rows=529640 width=129) (actual time=1295.470..1295.530 rows=149 loops=1)
                                                                    Sort Key: nt_1.collection
                                                                    Sort Method: external merge  Disk: 89576kB
                                                                    ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_1  (cost=0.57..1009187.97 rows=529640 width=129) (actual time=0.047..232.902 rows=658150 loops=1)
                                                                          Index Cond: ("timestamp" > (CURRENT_DATE - '1 day'::interval))
                                                  ->  Subquery Scan on current_day  (cost=74649.80..76106.05 rows=4368 width=110) (actual time=370.134..370.313 rows=3 loops=1)
                                                        ->  GroupAggregate  (cost=74649.80..76062.37 rows=4368 width=203) (actual time=370.118..370.293 rows=3 loops=1)
                                                              Group Key: nt_2.collection
                                                              ->  Sort  (cost=74649.80..74668.80 rows=7599 width=136) (actual time=368.504..368.524 rows=39 loops=1)
                                                                    Sort Key: nt_2.collection
                                                                    Sort Method: external merge  Disk: 6088kB
                                                                    ->  Bitmap Heap Scan on nft_transfer nt_2  (cost=44554.24..74159.99 rows=7599 width=136) (actual time=167.328..235.008 rows=42187 loops=1)
                                                                          Recheck Cond: (("timestamp" >= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                                          Rows Removed by Index Recheck: 102567
                                                                          Filter: (trade_currency IS NULL)
                                                                          Rows Removed by Filter: 68
                                                                          Heap Blocks: exact=7275
                                                                          ->  BitmapAnd  (cost=44554.24..44554.24 rows=7599 width=0) (actual time=166.138..166.139 rows=0 loops=1)
                                                                                ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..8441.44 rows=375583 width=0) (actual time=28.631..28.631 rows=305952 loops=1)
                                                                                      Index Cond: ("timestamp" >= (now() - '24:00:00'::interval))
                                                                                ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36108.74 rows=1911490 width=0) (actual time=135.875..135.875 rows=1915582 loops=1)
                                                                                      Index Cond: (trade_marketplace = 1)
                                            ->  Subquery Scan on previous_day  (cost=74066.49..75486.92 rows=4276 width=110) (actual time=524.501..524.756 rows=4 loops=1)
                                                  ->  GroupAggregate  (cost=74066.49..75444.16 rows=4276 width=203) (actual time=524.492..524.742 rows=4 loops=1)
                                                        Group Key: nt_3.collection
                                                        ->  Sort  (cost=74066.49..74084.72 rows=7292 width=136) (actual time=524.086..524.118 rows=55 loops=1)
                                                              Sort Key: nt_3.collection
                                                              Sort Method: external merge  Disk: 11536kB
                                                              ->  Bitmap Heap Scan on nft_transfer nt_3  (cost=45113.39..73598.63 rows=7292 width=136) (actual time=212.927..340.287 rows=79950 loops=1)
                                                                    Recheck Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                                    Rows Removed by Index Recheck: 163365
                                                                    Filter: (trade_currency IS NULL)
                                                                    Rows Removed by Filter: 112
                                                                    Heap Blocks: exact=15708
                                                                    ->  BitmapAnd  (cost=45113.39..45113.39 rows=7292 width=0) (actual time=205.056..205.056 rows=0 loops=1)
                                                                          ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..9000.75 rows=360417 width=0) (actual time=71.256..71.257 rows=443986 loops=1)
                                                                                Index Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)))
                                                                          ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36108.74 rows=1911490 width=0) (actual time=130.852..130.852 rows=1915582 loops=1)
                                                                                Index Cond: (trade_marketplace = 1)
                                      ->  Subquery Scan on current_hour  (cost=6.56..6.87 rows=1 width=110) (actual time=0.023..0.024 rows=0 loops=1)
                                            ->  GroupAggregate  (cost=6.56..6.86 rows=1 width=203) (actual time=0.022..0.023 rows=0 loops=1)
                                                  Group Key: nt_4.collection
                                                  ->  Sort  (cost=6.56..6.56 rows=1 width=136) (actual time=0.022..0.022 rows=0 loops=1)
                                                        Sort Key: nt_4.collection
                                                        Sort Method: quicksort  Memory: 25kB
                                                        ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_4  (cost=0.57..6.55 rows=1 width=136) (actual time=0.020..0.020 rows=0 loops=1)
                                                              Index Cond: ("timestamp" >= ((now())::timestamp without time zone - '01:00:00'::interval))
                                                              Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                                ->  Subquery Scan on previous_hour  (cost=8.61..8.92 rows=1 width=110) (actual time=0.012..0.013 rows=0 loops=1)
                                      ->  GroupAggregate  (cost=8.61..8.91 rows=1 width=203) (actual time=0.011..0.012 rows=0 loops=1)
                                            Group Key: nt_5.collection
                                            ->  Sort  (cost=8.61..8.62 rows=1 width=136) (actual time=0.010..0.011 rows=0 loops=1)
                                                  Sort Key: nt_5.collection
                                                  Sort Method: quicksort  Memory: 25kB
                                                  ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_5  (cost=0.58..8.60 rows=1 width=136) (actual time=0.009..0.009 rows=0 loops=1)
                                                        Index Cond: (("timestamp" >= (LOCALTIMESTAMP(0) - '02:00:00'::interval)) AND ("timestamp" <= (LOCALTIMESTAMP(0) - '01:00:00'::interval)))
                                                        Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                          ->  Subquery Scan on current_week  (cost=297827.87..301362.28 rows=6164 width=110) (actual time=1964.544..1965.750 rows=4 loops=1)
                                ->  GroupAggregate  (cost=297827.87..301300.64 rows=6164 width=203) (actual time=1964.537..1965.730 rows=4 loops=1)
                                      Group Key: nt_6.collection
                                      ->  Sort  (cost=297827.87..297960.35 rows=52992 width=136) (actual time=1963.397..1963.521 rows=370 loops=1)
                                            Sort Key: nt_6.collection
                                            Sort Method: external merge  Disk: 73952kB
                                            ->  Bitmap Heap Scan on nft_transfer nt_6  (cost=94984.23..290047.22 rows=52992 width=136) (actual time=431.907..1107.412 rows=513525 loops=1)
                                                  Recheck Cond: ((trade_marketplace = 1) AND ("timestamp" >= (now() - '7 days'::interval)))
                                                  Rows Removed by Index Recheck: 1395242
                                                  Filter: (trade_currency IS NULL)
                                                  Rows Removed by Filter: 855
                                                  Heap Blocks: exact=1053 lossy=96503
                                                  ->  BitmapAnd  (cost=94984.23..94984.23 rows=52996 width=0) (actual time=428.682..428.683 rows=0 loops=1)
                                                        ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36108.74 rows=1911490 width=0) (actual time=128.213..128.213 rows=1915582 loops=1)
                                                              Index Cond: (trade_marketplace = 1)
                                                        ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..58848.74 rows=2619222 width=0) (actual time=272.706..272.707 rows=2671702 loops=1)
                                                              Index Cond: ("timestamp" >= (now() - '7 days'::interval))
                    ->  Subquery Scan on previous_week  (cost=255664.40..258848.43 rows=6159 width=110) (actual time=2090.369..2095.343 rows=4 loops=1)
                          ->  GroupAggregate  (cost=255664.40..258786.84 rows=6159 width=203) (actual time=2090.362..2095.331 rows=4 loops=1)
                                Group Key: nt_7.collection
                                ->  Sort  (cost=255664.40..255771.95 rows=43020 width=136) (actual time=2087.792..2088.113 rows=1282 loops=1)
                                      Sort Key: nt_7.collection
                                      Sort Method: external merge  Disk: 71560kB
                                      ->  Bitmap Heap Scan on nft_transfer nt_7  (cost=89222.45..249409.93 rows=43020 width=136) (actual time=517.960..1282.174 rows=496990 loops=1)
                                            Recheck Cond: ((trade_marketplace = 1) AND ("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
                                            Rows Removed by Index Recheck: 1456349
                                            Filter: (trade_currency IS NULL)
                                            Rows Removed by Filter: 1131
                                            Heap Blocks: exact=1 lossy=98259
                                            ->  BitmapAnd  (cost=89222.45..89222.45 rows=43023 width=0) (actual time=516.699..516.699 rows=0 loops=1)
                                                  ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..36108.74 rows=1911490 width=0) (actual time=128.280..128.280 rows=1915582 loops=1)
                                                        Index Cond: (trade_marketplace = 1)
                                                  ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..53091.95 rows=2126337 width=0) (actual time=365.235..365.235 rows=2252437 loops=1)
                                                        Index Cond: (("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
              ->  GroupAggregate  (cost=0.69..14959105.29 rows=6143 width=59) (actual time=0.248..70.172 rows=22 loops=1)
                    Group Key: nft.address
                    ->  Index Scan using nft_address on nft  (cost=0.69..14570807.86 rows=51764800 width=85) (actual time=0.024..17.877 rows=19417 loops=1)
        ->  Hash  (cost=6090029.94..6090029.94 rows=6165 width=51) (actual time=73887.038..73887.039 rows=62326 loops=1)
              Buckets: 65536 (originally 8192)  Batches: 2 (originally 1)  Memory Usage: 3585kB
              ->  Subquery Scan on first_transfer  (cost=6089906.63..6090029.94 rows=6165 width=51) (actual time=73848.079..73870.783 rows=62326 loops=1)
                    ->  HashAggregate  (cost=6089906.63..6089968.29 rows=6165 width=51) (actual time=73848.078..73863.691 rows=62326 loops=1)
                          Group Key: nft_transfer.collection
                          ->  Seq Scan on nft_transfer  (cost=0.00..5617545.09 rows=94472309 width=51) (actual time=1.145..47050.676 rows=94472828 loops=1)
Planning time: 4.968 ms
Execution time: 89131.886 ms




//     select collection.address, collection.name, COUNT(*), SUM(trade_price/ 1e18) from nft_transfer, collection where nft_transfer.collection = collection.address and trade_marketplace is not null and trade_currency is null and "to" in (select "from" from nft_transfer nt where trade_marketplace is NOT null and collection = '0x5af0d9827e0c53e4799bb226655a1de152a425a5' group by "from") group by collection.address , collection.name

//    select collection.address, collection.name, COUNT(*) as trades, COUNT(distinct("from")) as people, SUM(trade_price/ 1e18) as volume from nft_transfer, collection where nft_transfer.collection = collection.address and trade_marketplace is not null and trade_currency is null and "to" in (select "from" from nft_transfer nt where trade_marketplace is NOT null and collection = '0x5af0d9827e0c53e4799bb226655a1de152a425a5' group by "from") group by collection.address , collection.name


//     select collection.address, collection.name, COUNT(*) as trades, COUNT(distinct("to")) as people, SUM(trade_price/ 1e18) as volume from nft_transfer, collection where nft_transfer.collection = collection.address and trade_marketplace is not null and trade_currency is null and "to" in (select "from" from nft_transfer nt where trade_marketplace is NOT null and collection = '0x5af0d9827e0c53e4799bb226655a1de152a425a5' group by "from") group by collection.address , collection.name
