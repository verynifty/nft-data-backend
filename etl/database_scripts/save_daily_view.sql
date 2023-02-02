	SELECT date_trunc('hour', CAST("public"."nft_transfer"."timestamp" AS timestamp)) AS "timestamp", count(*)
          FROM "public"."nft_transfer"
          WHERE CAST("public"."nft_transfer"."timestamp" AS date) BETWEEN CAST((CAST(now() AS timestamp) + (INTERVAL '-1 day')) AS date)
             AND CAST(now() AS date)
          GROUP BY 1
          ORDER BY 1 ASC
	

    	SELECT date_trunc('hour', CAST("public"."nft_transfer"."timestamp" AS timestamp)) AS "timestamp", SUM(1)
          FROM "public"."nft_transfer"
          WHERE NOW() - INTERVAL '48 HOURS' < "timestamp"
          GROUP BY 1
          ORDER BY 1 ASC


select
	date_trunc('day', cast("public"."nft_transfer"."timestamp" as timestamp)) as "timestamp",
	SUM(1)
from
	"public"."nft_transfer"
where
	collection = '0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d'
group by
	1
order by
	1 asc


    select
	date_trunc('day', cast("public"."nft_transfer"."timestamp" as timestamp)) as "timestamp",
	SUM(1)
from
	"public"."nft_transfer"
group by
	1
order by
	1 asc