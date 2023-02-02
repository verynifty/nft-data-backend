# Compare both counts
select COUNT(distinct(token_id , collection )) from nft_transfer nt 
select COUNT(*) from nft

#
select * from "nft" where "address" = '0xe11afbb703dc6c8c717cceba526d9568015e43d9' and attributes -> 'Headwear' in ('Brain') order by "updated_at" DESC limit 40

#
select * from "nft" where "address" = '0xe3435edbf54b5126e817363900234adfee5b3cee' and attributes -> 'Armor' in ('7' order by "updated_at" DESC limit 40

#
select * from nft_transfer nt LEFT JOIN nft ON nt.collection = nft.address and nt.token_id = nft.token_id WHERE nt.collection = '0x2963ba471e265e5f51cafafca78310fe87f8e6d1' AND nt.token_id  = '2258'  order by "timestamp" desc limit 100 

#
select token_id, "attributes" -> face" from nft where address = '0x1a92f7381b9f03921564a437210bb9396471050c' 

#
CREATE MATERIALIZED VIEW public.nft_collection_stats
AS SELECT c.address,
    c.name,
    c.symbol,
    c.default_image,
    c.slug,
    c.decimals,
    c.first_block_seen,
    c.type,
    c.owner,
    c.created_at,
    c.backfilled,
    c.backfilled_at,
    c.nft_data_base_url,
    c.nft_image_base_url,
    count(*) AS transfers_total,
    COALESCE(count(*) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '01:00:00'::interval)), 0::bigint) AS transfers_hour,
    COALESCE(count(*) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 day'::interval)), 0::bigint) AS transfers_today,
    COALESCE(count(*) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '7 days'::interval)), 0::bigint) AS transfers_week,
    count(DISTINCT t."to") AS receivers_total,
    COALESCE(count(DISTINCT t."to") FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 day'::interval)), 0::bigint) AS receivers_hour,
    COALESCE(count(DISTINCT t."to") FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 day'::interval)), 0::bigint) AS receivers_today,
    COALESCE(count(DISTINCT t."to") FILTER (WHERE t."timestamp" > (CURRENT_DATE - '7 days'::interval)), 0::bigint) AS receivers_week
   FROM collection c
     LEFT JOIN nft_transfer t ON c.address::text = t.collection::text
  WHERE c.type = 721
  GROUP BY c.address
WITH DATA;

-- View indexes:
CREATE UNIQUE INDEX nft_collection_stats_idx ON public.nft_collection_stats USING btree (address);


-- Permissions

ALTER TABLE public.nft_collection_stats OWNER TO doadmin;
GRANT ALL ON TABLE public.nft_collection_stats TO doadmin;
GRANT SELECT ON TABLE public.nft_collection_stats TO reader;


#
TRUNCATE TABLE token_transfer RESTART IDENTITY CASCADE;
TRUNCATE TABLE nft_transfer RESTART IDENTITY CASCADE;
TRUNCATE TABLE collection RESTART IDENTITY CASCADE;
TRUNCATE TABLE nft RESTART IDENTITY CASCADE;
DROP SCHEMA graphile_worker CASCADE;