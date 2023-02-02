https://explain.dalibo.com/plan/4Iu


EXPLAIN analyze 
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
	row_to_json(previous_week) as trades_previous_week
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
 c.type = 1155 OR c.type = 721 limit 100




Limit  (cost=2781330.74..2786239.84 rows=20 width=302) (actual time=16344.591..16420.356 rows=20 loops=1)
  ->  Merge Left Join  (cost=2781330.74..18238629.93 rows=62974 width=302) (actual time=16344.591..16420.349 rows=20 loops=1)
        Merge Cond: ((c.address)::text = (nft.address)::text)
        ->  Merge Left Join  (cost=2781330.05..2924464.21 rows=62974 width=496) (actual time=16344.340..16350.537 rows=20 loops=1)
              Merge Cond: ((c.address)::text = (previous_week.previous_collection)::text)
              ->  Merge Left Join  (cost=2476957.67..2616384.60 rows=62974 width=429) (actual time=13472.251..13477.772 rows=20 loops=1)
                    Merge Cond: ((c.address)::text = (current_week.current_collection)::text)
                    ->  Merge Left Join  (cost=2343213.92..2480176.02 rows=62974 width=362) (actual time=11316.890..11322.052 rows=20 loops=1)
                          Merge Cond: ((c.address)::text = (previous_hour.previous_collection)::text)
                          ->  Merge Left Join  (cost=2343205.31..2480009.65 rows=62974 width=295) (actual time=11316.875..11322.028 rows=20 loops=1)
                                Merge Cond: ((c.address)::text = (current_hour.current_collection)::text)
                                ->  Merge Left Join  (cost=2343198.75..2479845.33 rows=62974 width=228) (actual time=11316.853..11321.996 rows=20 loops=1)
                                      Merge Cond: ((c.address)::text = (previous_day.previous_collection)::text)
                                      ->  Merge Left Join  (cost=2291889.97..2427676.56 rows=62974 width=161) (actual time=10776.411..10781.384 rows=20 loops=1)
                                            Merge Cond: ((c.address)::text = (current_day.current_collection)::text)
                                            ->  Merge Left Join  (cost=2240954.45..2375881.75 rows=62974 width=94) (actual time=10374.125..10378.931 rows=20 loops=1)
                                                  Merge Cond: ((c.address)::text = (nt_1.collection)::text)
                                                  ->  Merge Left Join  (cost=1966864.90..2099884.02 rows=62974 width=70) (actual time=9460.794..9465.488 rows=20 loops=1)
                                                        Merge Cond: ((c.address)::text = (nt.collection)::text)
                                                        ->  Index Scan using collection_address on collection c  (cost=0.42..120838.69 rows=62974 width=46) (actual time=0.028..4.299 rows=20 loops=1)
                                                              Filter: ((type = 1155) OR (type = 721))
                                                              Rows Removed by Filter: 95
                                                        ->  GroupAggregate  (cost=1966864.48..1978801.60 rows=6165 width=67) (actual time=9460.763..9461.162 rows=4 loops=1)
                                                              Group Key: nt.collection
                                                              ->  Sort  (cost=1966864.48..1969239.57 rows=950038 width=129) (actual time=9459.023..9459.211 rows=602 loops=1)
                                                                    Sort Key: nt.collection
                                                                    Sort Method: external merge  Disk: 426728kB
                                                                    ->  Index Scan using nft_transfer_timestamp on nft_transfer nt  (cost=0.57..1742644.98 rows=950038 width=129) (actual time=0.046..1591.659 rows=3137132 loops=1)
                                                                          Index Cond: ("timestamp" > (CURRENT_DATE - '7 days'::interval))
                                                  ->  GroupAggregate  (cost=274089.55..275754.01 rows=6165 width=67) (actual time=913.327..913.420 rows=4 loops=1)
                                                        Group Key: nt_1.collection
                                                        ->  Sort  (cost=274089.55..274410.11 rows=128225 width=129) (actual time=912.951..913.026 rows=160 loops=1)
                                                              Sort Key: nt_1.collection
                                                              Sort Method: external merge  Disk: 55008kB
                                                              ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_1  (cost=0.57..254443.24 rows=128225 width=129) (actual time=0.048..177.486 rows=404005 loops=1)
                                                                    Index Cond: ("timestamp" > (CURRENT_DATE - '1 day'::interval))
                                            ->  Subquery Scan on current_day  (cost=50935.52..51628.61 rows=2195 width=110) (actual time=402.281..402.429 rows=3 loops=1)
                                                  ->  GroupAggregate  (cost=50935.52..51606.66 rows=2195 width=203) (actual time=402.267..402.411 rows=3 loops=1)
                                                        Group Key: nt_2.collection
                                                        ->  Sort  (cost=50935.52..50942.30 rows=2713 width=136) (actual time=400.248..400.265 rows=28 loops=1)
                                                              Sort Key: nt_2.collection
                                                              Sort Method: external merge  Disk: 5464kB
                                                              ->  Bitmap Heap Scan on nft_transfer nt_2  (cost=40064.09..50780.80 rows=2713 width=136) (actual time=204.180..271.948 rows=37976 loops=1)
                                                                    Recheck Cond: (("timestamp" >= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                                    Rows Removed by Index Recheck: 104403
                                                                    Filter: (trade_currency IS NULL)
                                                                    Rows Removed by Filter: 93
                                                                    Heap Blocks: exact=7159
                                                                    ->  BitmapAnd  (cost=40064.09..40064.09 rows=2714 width=0) (actual time=203.019..203.020 rows=0 loops=1)
                                                                          ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..2998.46 rows=134118 width=0) (actual time=33.204..33.204 rows=280511 loops=1)
                                                                                Index Cond: ("timestamp" >= (now() - '24:00:00'::interval))
                                                                          ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.03 rows=1960995 width=0) (actual time=168.336..168.336 rows=2232883 loops=1)
                                                                                Index Cond: (trade_marketplace = 1)
                                      ->  Subquery Scan on previous_day  (cost=51308.78..52002.56 rows=2197 width=110) (actual time=540.437..540.589 rows=4 loops=1)
                                            ->  GroupAggregate  (cost=51308.78..51980.59 rows=2197 width=203) (actual time=540.430..540.576 rows=4 loops=1)
                                                  Group Key: nt_3.collection
                                                  ->  Sort  (cost=51308.78..51315.57 rows=2717 width=136) (actual time=539.780..539.813 rows=86 loops=1)
                                                        Sort Key: nt_3.collection
                                                        Sort Method: external merge  Disk: 10672kB
                                                        ->  Bitmap Heap Scan on nft_transfer nt_3  (cost=40404.99..51153.81 rows=2717 width=136) (actual time=244.891..367.570 rows=73973 loops=1)
                                                              Recheck Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                              Rows Removed by Index Recheck: 160935
                                                              Filter: (trade_currency IS NULL)
                                                              Rows Removed by Filter: 178
                                                              Heap Blocks: exact=11822
                                                              ->  BitmapAnd  (cost=40404.99..40404.99 rows=2717 width=0) (actual time=242.649..242.650 rows=0 loops=1)
                                                                    ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..3339.35 rows=134277 width=0) (actual time=79.219..79.219 rows=479136 loops=1)
                                                                          Index Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)))
                                                                    ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.03 rows=1960995 width=0) (actual time=161.131..161.131 rows=2232883 loops=1)
                                                                          Index Cond: (trade_marketplace = 1)
                                ->  Subquery Scan on current_hour  (cost=6.56..6.87 rows=1 width=110) (actual time=0.021..0.022 rows=0 loops=1)
                                      ->  GroupAggregate  (cost=6.56..6.86 rows=1 width=203) (actual time=0.020..0.021 rows=0 loops=1)
                                            Group Key: nt_4.collection
                                            ->  Sort  (cost=6.56..6.56 rows=1 width=136) (actual time=0.019..0.020 rows=0 loops=1)
                                                  Sort Key: nt_4.collection
                                                  Sort Method: quicksort  Memory: 25kB
                                                  ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_4  (cost=0.57..6.55 rows=1 width=136) (actual time=0.017..0.017 rows=0 loops=1)
                                                        Index Cond: ("timestamp" >= ((now())::timestamp without time zone - '01:00:00'::interval))
                                                        Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                          ->  Subquery Scan on previous_hour  (cost=8.61..8.92 rows=1 width=110) (actual time=0.013..0.015 rows=0 loops=1)
                                ->  GroupAggregate  (cost=8.61..8.91 rows=1 width=203) (actual time=0.013..0.014 rows=0 loops=1)
                                      Group Key: nt_5.collection
                                      ->  Sort  (cost=8.61..8.62 rows=1 width=136) (actual time=0.012..0.013 rows=0 loops=1)
                                            Sort Key: nt_5.collection
                                            Sort Method: quicksort  Memory: 25kB
                                            ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_5  (cost=0.58..8.60 rows=1 width=136) (actual time=0.011..0.011 rows=0 loops=1)
                                                  Index Cond: (("timestamp" >= (LOCALTIMESTAMP(0) - '02:00:00'::interval)) AND ("timestamp" <= (LOCALTIMESTAMP(0) - '01:00:00'::interval)))
                                                  Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                    ->  Subquery Scan on current_week  (cost=133743.75..136027.58 rows=5897 width=110) (actual time=2155.357..2155.690 rows=4 loops=1)
                          ->  GroupAggregate  (cost=133743.75..135968.61 rows=5897 width=203) (actual time=2155.348..2155.678 rows=4 loops=1)
                                Group Key: nt_6.collection
                                ->  Sort  (cost=133743.75..133792.10 rows=19340 width=136) (actual time=2154.115..2154.199 rows=292 loops=1)
                                      Sort Key: nt_6.collection
                                      Sort Method: external merge  Disk: 67856kB
                                      ->  Bitmap Heap Scan on nft_transfer nt_6  (cost=58436.00..132366.81 rows=19340 width=136) (actual time=574.402..1341.418 rows=471190 loops=1)
                                            Recheck Cond: (("timestamp" >= (now() - '7 days'::interval)) AND (trade_marketplace = 1))
                                            Rows Removed by Index Recheck: 1212030
                                            Filter: (trade_currency IS NULL)
                                            Rows Removed by Filter: 1124
                                            Heap Blocks: exact=21795 lossy=62792
                                            ->  BitmapAnd  (cost=58436.00..58436.00 rows=19342 width=0) (actual time=529.245..529.247 rows=0 loops=1)
                                                  ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..21362.06 rows=955931 width=0) (actual time=345.430..345.430 rows=3012213 loops=1)
                                                        Index Cond: ("timestamp" >= (now() - '7 days'::interval))
                                                  ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.03 rows=1960995 width=0) (actual time=176.830..176.830 rows=2232883 loops=1)
                                                        Index Cond: (trade_marketplace = 1)
              ->  Subquery Scan on previous_week  (cost=304372.38..307897.55 rows=6164 width=110) (actual time=2872.084..2872.741 rows=4 loops=1)
                    ->  GroupAggregate  (cost=304372.38..307835.91 rows=6164 width=203) (actual time=2872.078..2872.731 rows=4 loops=1)
                          Group Key: nt_7.collection
                          ->  Sort  (cost=304372.38..304504.20 rows=52728 width=136) (actual time=2870.808..2870.974 rows=373 loops=1)
                                Sort Key: nt_7.collection
                                Sort Method: external merge  Disk: 78880kB
                                ->  Bitmap Heap Scan on nft_transfer nt_7  (cost=101845.12..296631.84 rows=52728 width=136) (actual time=638.448..1908.535 rows=547862 loops=1)
                                      Recheck Cond: ((trade_marketplace = 1) AND ("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
                                      Rows Removed by Index Recheck: 1354333
                                      Filter: (trade_currency IS NULL)
                                      Rows Removed by Filter: 956
                                      Heap Blocks: exact=564 lossy=96661
                                      ->  BitmapAnd  (cost=101845.12..101845.12 rows=52732 width=0) (actual time=627.440..627.441 rows=0 loops=1)
                                            ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.03 rows=1960995 width=0) (actual time=147.744..147.745 rows=2232883 loops=1)
                                                  Index Cond: (trade_marketplace = 1)
                                            ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..64754.48 rows=2606190 width=0) (actual time=453.732..453.732 rows=2642978 loops=1)
                                                  Index Cond: (("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
        ->  GroupAggregate  (cost=0.69..15312970.93 rows=6627 width=59) (actual time=0.247..69.709 rows=20 loops=1)
              Group Key: nft.address
              ->  Index Scan using nft_address on nft  (cost=0.69..14918539.34 rows=52582043 width=85) (actual time=0.023..26.535 rows=19488 loops=1)
Planning time: 4.773 ms
Execution time: 16517.834 ms


100 res https://explain.dalibo.com/plan/rQWZ


Limit  (cost=2782771.17..2807514.30 rows=100 width=302) (actual time=15932.522..16137.365 rows=100 loops=1)
  ->  Merge Left Join  (cost=2782771.17..18240788.14 rows=62474 width=302) (actual time=15932.521..16137.343 rows=100 loops=1)
        Merge Cond: ((c.address)::text = (nft.address)::text)
        ->  Merge Left Join  (cost=2782770.48..2925897.52 rows=62474 width=496) (actual time=15932.262..15944.935 rows=100 loops=1)
              Merge Cond: ((c.address)::text = (previous_week.previous_collection)::text)
              ->  Merge Left Join  (cost=2478512.70..2617934.67 rows=62474 width=429) (actual time=13324.377..13333.623 rows=100 loops=1)
                    Merge Cond: ((c.address)::text = (current_week.current_collection)::text)
                    ->  Merge Left Join  (cost=2344855.66..2481814.75 rows=62474 width=362) (actual time=11086.977..11094.337 rows=100 loops=1)
                          Merge Cond: ((c.address)::text = (previous_hour.previous_collection)::text)
                          ->  Merge Left Join  (cost=2344847.05..2481649.64 rows=62474 width=295) (actual time=11086.962..11094.282 rows=100 loops=1)
                                Merge Cond: ((c.address)::text = (current_hour.current_collection)::text)
                                ->  Merge Left Join  (cost=2344840.49..2481486.57 rows=62474 width=228) (actual time=11086.934..11094.223 rows=100 loops=1)
                                      Merge Cond: ((c.address)::text = (previous_day.previous_collection)::text)
                                      ->  Merge Left Join  (cost=2293544.31..2429332.32 rows=62474 width=161) (actual time=10613.173..10619.783 rows=100 loops=1)
                                            Merge Cond: ((c.address)::text = (current_day.current_collection)::text)
                                            ->  Merge Left Join  (cost=2242633.64..2377564.61 rows=62474 width=94) (actual time=10276.852..10282.923 rows=100 loops=1)
                                                  Merge Cond: ((c.address)::text = (nt_1.collection)::text)
                                                  ->  Merge Left Join  (cost=1966978.00..2099992.88 rows=62474 width=70) (actual time=9158.434..9164.030 rows=100 loops=1)
                                                        Merge Cond: ((c.address)::text = (nt.collection)::text)
                                                        ->  Index Scan using collection_address on collection c  (cost=0.42..120835.09 rows=62474 width=46) (actual time=0.026..0.917 rows=100 loops=1)
                                                              Filter: ((type = 1155) OR (type = 721))
                                                              Rows Removed by Filter: 471
                                                        ->  GroupAggregate  (cost=1966977.58..1978915.40 rows=6165 width=67) (actual time=9158.405..9163.008 rows=25 loops=1)
                                                              Group Key: nt.collection
                                                              ->  Sort  (cost=1966977.58..1969352.81 rows=950094 width=129) (actual time=9157.243..9158.039 rows=2347 loops=1)
                                                                    Sort Key: nt.collection
                                                                    Sort Method: external merge  Disk: 427096kB
                                                                    ->  Index Scan using nft_transfer_timestamp on nft_transfer nt  (cost=0.57..1742745.12 rows=950094 width=129) (actual time=0.031..1134.491 rows=3139846 loops=1)
                                                                          Index Cond: ("timestamp" > (CURRENT_DATE - '7 days'::interval))
                                                  ->  GroupAggregate  (cost=275655.64..277329.34 rows=6165 width=67) (actual time=1118.415..1118.799 rows=15 loops=1)
                                                        Group Key: nt_1.collection
                                                        ->  Sort  (cost=275655.64..275978.05 rows=128964 width=129) (actual time=1118.171..1118.327 rows=258 loops=1)
                                                              Sort Key: nt_1.collection
                                                              Sort Method: external merge  Disk: 55384kB
                                                              ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_1  (cost=0.57..255892.28 rows=128964 width=129) (actual time=0.039..126.834 rows=406719 loops=1)
                                                                    Index Cond: ("timestamp" > (CURRENT_DATE - '1 day'::interval))
                                            ->  Subquery Scan on current_day  (cost=50910.67..51602.80 rows=2192 width=110) (actual time=336.316..336.764 rows=7 loops=1)
                                                  ->  GroupAggregate  (cost=50910.67..51580.88 rows=2192 width=203) (actual time=336.309..336.747 rows=7 loops=1)
                                                        Group Key: nt_2.collection
                                                        ->  Sort  (cost=50910.67..50917.44 rows=2709 width=136) (actual time=335.874..335.913 rows=36 loops=1)
                                                              Sort Key: nt_2.collection
                                                              Sort Method: external merge  Disk: 5504kB
                                                              ->  Bitmap Heap Scan on nft_transfer nt_2  (cost=40059.06..50756.21 rows=2709 width=136) (actual time=165.515..224.510 rows=38208 loops=1)
                                                                    Recheck Cond: (("timestamp" >= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                                    Rows Removed by Index Recheck: 105070
                                                                    Filter: (trade_currency IS NULL)
                                                                    Rows Removed by Filter: 97
                                                                    Heap Blocks: exact=7203
                                                                    ->  BitmapAnd  (cost=40059.06..40059.06 rows=2709 width=0) (actual time=164.381..164.382 rows=0 loops=1)
                                                                          ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..2992.85 rows=133904 width=0) (actual time=26.538..26.538 rows=281486 loops=1)
                                                                                Index Cond: ("timestamp" >= (now() - '24:00:00'::interval))
                                                                          ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.61 rows=1961072 width=0) (actual time=136.372..136.373 rows=2233463 loops=1)
                                                                                Index Cond: (trade_marketplace = 1)
                                      ->  Subquery Scan on previous_day  (cost=51296.19..51989.32 rows=2195 width=110) (actual time=473.757..474.353 rows=10 loops=1)
                                            ->  GroupAggregate  (cost=51296.19..51967.37 rows=2195 width=203) (actual time=473.751..474.336 rows=10 loops=1)
                                                  Group Key: nt_3.collection
                                                  ->  Sort  (cost=51296.19..51302.97 rows=2714 width=136) (actual time=473.280..473.344 rows=115 loops=1)
                                                        Sort Key: nt_3.collection
                                                        Sort Method: external merge  Disk: 10640kB
                                                        ->  Bitmap Heap Scan on nft_transfer nt_3  (cost=40400.42..51141.41 rows=2714 width=136) (actual time=209.138..317.926 rows=73771 loops=1)
                                                              Recheck Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)) AND (trade_marketplace = 1))
                                                              Rows Removed by Index Recheck: 160360
                                                              Filter: (trade_currency IS NULL)
                                                              Rows Removed by Filter: 176
                                                              Heap Blocks: exact=11783
                                                              ->  BitmapAnd  (cost=40400.42..40400.42 rows=2715 width=0) (actual time=207.387..207.387 rows=0 loops=1)
                                                                    ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..3334.21 rows=134163 width=0) (actual time=69.493..69.493 rows=477741 loops=1)
                                                                          Index Cond: (("timestamp" >= (now() - '48:00:00'::interval)) AND ("timestamp" <= (now() - '24:00:00'::interval)))
                                                                    ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.61 rows=1961072 width=0) (actual time=136.083..136.083 rows=2233463 loops=1)
                                                                          Index Cond: (trade_marketplace = 1)
                                ->  Subquery Scan on current_hour  (cost=6.56..6.87 rows=1 width=110) (actual time=0.026..0.028 rows=0 loops=1)
                                      ->  GroupAggregate  (cost=6.56..6.86 rows=1 width=203) (actual time=0.025..0.026 rows=0 loops=1)
                                            Group Key: nt_4.collection
                                            ->  Sort  (cost=6.56..6.56 rows=1 width=136) (actual time=0.025..0.025 rows=0 loops=1)
                                                  Sort Key: nt_4.collection
                                                  Sort Method: quicksort  Memory: 25kB
                                                  ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_4  (cost=0.57..6.55 rows=1 width=136) (actual time=0.023..0.023 rows=0 loops=1)
                                                        Index Cond: ("timestamp" >= ((now())::timestamp without time zone - '01:00:00'::interval))
                                                        Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                          ->  Subquery Scan on previous_hour  (cost=8.61..8.92 rows=1 width=110) (actual time=0.014..0.016 rows=0 loops=1)
                                ->  GroupAggregate  (cost=8.61..8.91 rows=1 width=203) (actual time=0.013..0.015 rows=0 loops=1)
                                      Group Key: nt_5.collection
                                      ->  Sort  (cost=8.61..8.62 rows=1 width=136) (actual time=0.013..0.014 rows=0 loops=1)
                                            Sort Key: nt_5.collection
                                            Sort Method: quicksort  Memory: 25kB
                                            ->  Index Scan using nft_transfer_timestamp on nft_transfer nt_5  (cost=0.58..8.60 rows=1 width=136) (actual time=0.012..0.012 rows=0 loops=1)
                                                  Index Cond: (("timestamp" >= (LOCALTIMESTAMP(0) - '02:00:00'::interval)) AND ("timestamp" <= (LOCALTIMESTAMP(0) - '01:00:00'::interval)))
                                                  Filter: ((trade_currency IS NULL) AND (trade_marketplace = 1))
                    ->  Subquery Scan on current_week  (cost=133657.04..135940.24 rows=5897 width=110) (actual time=2237.396..2239.191 rows=13 loops=1)
                          ->  GroupAggregate  (cost=133657.04..135881.27 rows=5897 width=203) (actual time=2237.388..2239.167 rows=13 loops=1)
                                Group Key: nt_6.collection
                                ->  Sort  (cost=133657.04..133705.34 rows=19322 width=136) (actual time=2236.197..2236.409 rows=511 loops=1)
                                      Sort Key: nt_6.collection
                                      Sort Method: external merge  Disk: 67888kB
                                      ->  Bitmap Heap Scan on nft_transfer nt_6  (cost=58417.85..132281.51 rows=19322 width=136) (actual time=480.844..1311.537 rows=471426 loops=1)
                                            Recheck Cond: (("timestamp" >= (now() - '7 days'::interval)) AND (trade_marketplace = 1))
                                            Rows Removed by Index Recheck: 1211312
                                            Filter: (trade_currency IS NULL)
                                            Rows Removed by Filter: 1127
                                            Heap Blocks: exact=21630 lossy=62933
                                            ->  BitmapAnd  (cost=58417.85..58417.85 rows=19324 width=0) (actual time=436.252..436.253 rows=0 loops=1)
                                                  ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..21343.33 rows=955035 width=0) (actual time=292.131..292.131 rows=3011539 loops=1)
                                                        Index Cond: ("timestamp" >= (now() - '7 days'::interval))
                                                  ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.61 rows=1961072 width=0) (actual time=136.647..136.648 rows=2233463 loops=1)
                                                        Index Cond: (trade_marketplace = 1)
              ->  Subquery Scan on previous_week  (cost=304257.79..307782.12 rows=6164 width=110) (actual time=2607.880..2611.217 rows=15 loops=1)
                    ->  GroupAggregate  (cost=304257.79..307720.48 rows=6164 width=203) (actual time=2607.871..2611.180 rows=15 loops=1)
                          Group Key: nt_7.collection
                          ->  Sort  (cost=304257.79..304389.55 rows=52704 width=136) (actual time=2606.616..2606.950 rows=720 loops=1)
                                Sort Key: nt_7.collection
                                Sort Method: external merge  Disk: 78856kB
                                ->  Bitmap Heap Scan on nft_transfer nt_7  (cost=101817.64..296519.31 rows=52704 width=136) (actual time=601.121..1519.730 rows=547692 loops=1)
                                      Recheck Cond: ((trade_marketplace = 1) AND ("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
                                      Rows Removed by Index Recheck: 1355165
                                      Filter: (trade_currency IS NULL)
                                      Rows Removed by Filter: 957
                                      Heap Blocks: exact=569 lossy=96691
                                      ->  BitmapAnd  (cost=101817.64..101817.64 rows=52708 width=0) (actual time=598.141..598.142 rows=0 loops=1)
                                            ->  Bitmap Index Scan on nft_transfer_trade_marketplace  (cost=0.00..37064.61 rows=1961072 width=0) (actual time=147.500..147.500 rows=2233463 loops=1)
                                                  Index Cond: (trade_marketplace = 1)
                                            ->  Bitmap Index Scan on nft_transfer_timestamp  (cost=0.00..64726.43 rows=2604985 width=0) (actual time=425.353..425.353 rows=2643356 loops=1)
                                                  Index Cond: (("timestamp" >= (now() - '14 days'::interval)) AND ("timestamp" <= (now() - '7 days'::interval)))
        ->  GroupAggregate  (cost=0.69..15313704.65 rows=6627 width=59) (actual time=0.256..191.928 rows=100 loops=1)
              Group Key: nft.address
              ->  Index Scan using nft_address on nft  (cost=0.69..14919250.84 rows=52585006 width=85) (actual time=0.020..63.398 rows=56851 loops=1)
Planning time: 3.537 ms
Execution time: 16246.274 ms