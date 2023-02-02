
select "key",  json_agg(json_build_object(value, count)) AS attributes from (SELECT key, value, count(*)  FROM
  (SELECT (each("attributes")).key,  (each("attributes")).value FROM  nft where nft.address = '0xc0cb97a0e22e9c14fb0b39da6cf6ccdab8078fa9') AS stat
  GROUP BY key, value 
 , key  ORDER BY count DESC) as temporary group by "key" order by "key" 