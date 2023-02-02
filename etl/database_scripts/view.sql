CREATE  MATERIALIZED VIEW nft_collection_stats AS
 SELECT c.*,
    COUNT(*) as transfers_total,
    COALESCE(count(*) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 hour'::interval)), 0::bigint) AS transfers_hour,
    COALESCE(count(*) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 day'::interval)), 0::bigint) AS transfers_today,
    COALESCE(count(*) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '7day'::interval)), 0::bigint) AS transfers_week,
    COUNT(distinct(t."to" )) as receivers_total,
    COALESCE(COUNT(distinct(t."to" )) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 day'::interval)), 0::bigint) AS receivers_hour,
    COALESCE(COUNT(distinct(t."to" )) FILTER (WHERE t."timestamp" > (CURRENT_DATE - '1 day'::interval)), 0::bigint) AS receivers_today,
    COALESCE(COUNT(distinct(t."to" ))FILTER (WHERE t."timestamp" > (CURRENT_DATE - '7day'::interval)), 0::bigint) AS receivers_week
   FROM  collection c
  LEFT JOIN nft_transfer t ON c.address = t.collection 
 where c."type" = 721
 GROUP BY address 