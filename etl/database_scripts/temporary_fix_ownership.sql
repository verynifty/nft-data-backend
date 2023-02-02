#create new table with latest owner


CREATE TABLE temporary_ownership2 AS
SELECT DISTINCT ON (n.token_id) n.address , n.token_id, "to" as "last_owner", block_number, log_index
FROM nft n 
INNER JOIN nft_transfer nt ON n.address = nt.collection and n.token_id = nt.token_id 
ORDER BY n.token_id, nt.block_number desc, nt.log_index desc


refresh materialized view temporary_ownership


SELECT DISTINCT ON (n.token_id) n.address , n.token_id, "to" as "last_owner", block_number, log_index
FROM nft n 
INNER JOIN nft_transfer nt ON n.address = nt.collection and n.token_id = nt.token_id 
where n.address = '0xe3435edbf54b5126e817363900234adfee5b3cee'
ORDER BY n.token_id, nt.block_number desc, nt.log_index desc

# Test if table was created

select * from temporary_ownership where address = '0xe3435edbf54b5126e817363900234adfee5b3cee'

#speed up with an index

CREATE INDEX temporary_ownership_idx ON temporary_ownership (address, token_id);


#update all nfts at once

UPDATE nft n
SET "owner" = t.last_owner, latest_block_number = t.block_number, latest_log_index = log_index
FROM temporary_ownership t
WHERE n.address = t.address and n.token_id = t.token_id and n.address = '0xe3435edbf54b5126e817363900234adfee5b3cee';


select * from nft where address = '0xe3435edbf54b5126e817363900234adfee5b3cee'


SELECT
n.nspname as SchemaName
,c.relname as RelationName
,CASE c.relkind
WHEN 'r' THEN 'table'
WHEN 'v' THEN 'view'
WHEN 'i' THEN 'index'
WHEN 'S' THEN 'sequence'
WHEN 's' THEN 'special'
END as RelationType
,pg_catalog.pg_get_userbyid(c.relowner) as RelationOwner
,pg_size_pretty(pg_relation_size(n.nspname ||'.'|| c.relname)) as RelationSize
FROM pg_catalog.pg_class c
LEFT JOIN pg_catalog.pg_namespace n
    ON n.oid = c.relnamespace
WHERE  c.relkind IN ('r','s')
AND  (n.nspname !~ '^pg_toast' and nspname like 'pg_temp%')
ORDER BY pg_relation_size(n.nspname ||'.'|| c.relname) DESC;



do $$
declare
    item record;
begin
FOR item IN
        SELECT address FROM collection c where c."type"  = 721 group by address limit 10
    LOOP
        RAISE NOTICE 'PROCESSING(%)', item.address;
    END LOOP;
   END
   $$;




declare
    collect record;
begin
FOR collect IN
        SELECT address FROM collection c where c."type"  = 721 group by address limit 2
    loop
    	
        RAISE NOTICE 'PROCESSING ff(%)', collect.address;
       CREATE or replace view temporary_ownership AS
select DISTINCT ON (n.token_id) n.address , n.token_id, "to" as "last_owner", block_number, log_index
FROM nft n 
INNER JOIN nft_transfer nt ON n.address = nt.collection and n.token_id = nt.token_id 
where n.address = collect.address
ORDER BY n.token_id, nt.block_number desc, nt.log_index desc;
       update  nft n 
SET "owner" = t.last_owner, latest_block_number = t.block_number, latest_log_index = log_index
FROM temporary_ownership t
WHERE n.address = t.address and n.token_id = t.token_id and n.address = collect.address;
    END LOOP;
   END
   $$;




   do $$
declare
    collect record;
     addy varchar;
    counting int;
begin
	counting = 0;
FOR collect in
        SELECT address FROM collection c where c."type"  = 721 group by address order by address ASC
    loop
    counting = counting::int + 1;
    	addy = collect.address;
               RAISE NOTICE 'DOING(%, %)', addy, counting;
         update  nft n 
SET "owner" = t.last_owner, latest_block_number = t.block_number, latest_log_index = log_index
FROM (select DISTINCT ON (n.token_id) n.address , n.token_id, "to" as "last_owner", block_number, log_index
FROM nft n 
INNER JOIN nft_transfer nt ON n.address = nt.collection and n.token_id = nt.token_id 
where n.address = addy
ORDER BY n.token_id, nt.block_number desc, nt.log_index desc) t
WHERE n.token_id = t.token_id and n.address = addy;
    END LOOP;
   END
   $$;




   CREATE TABLE debug_collec
(
    "address" varchar(42) NOT NULL
);


do $$
declare
    collect record;
     addy varchar;
    counting int;
begin
	counting = 0;
FOR collect in
        SELECT address FROM collection c where c."type"  = 721 group by address order by address ASC LIMIT 1000 offset
    loop
    counting = counting::int + 1;
    	addy = collect.address;
               RAISE NOTICE 'DOING(%, %)', addy, counting;
              insert into debug_collec VALUES(addy);
         update  nft n 
SET "owner" = t.last_owner, latest_block_number = t.block_number, latest_log_index = log_index
FROM (select DISTINCT ON (n.token_id) n.address , n.token_id, "to" as "last_owner", block_number, log_index
FROM nft n 
INNER JOIN nft_transfer nt ON n.address = nt.collection and n.token_id = nt.token_id 
where n.address = addy
ORDER BY n.token_id, nt.block_number desc, nt.log_index desc) t
WHERE n.token_id = t.token_id and n.address = addy;
    END LOOP;
   END
   $$;




   do $$
declare
    collect record;
     addy varchar;
    counting int;
begin
	counting = 0;
FOR collect in
        SELECT address FROM collection c where c."type"  = 721 and address not in (select address from debug_collec) group by address order by address asc limit 400 
    loop
    counting = counting::int + 1;
    	addy = collect.address;
               RAISE NOTICE 'DOING(%, %)', addy, counting;
         update  nft n 
SET "owner" = t.last_owner, latest_block_number = t.block_number, latest_log_index = log_index
FROM (select DISTINCT ON (n.token_id) n.address , n.token_id, "to" as "last_owner", block_number, log_index
FROM nft n 
INNER JOIN nft_transfer nt ON n.address = nt.collection and n.token_id = nt.token_id 
where n.address = addy
ORDER BY n.token_id, nt.block_number desc, nt.log_index desc) t
WHERE n.token_id = t.token_id and n.address = addy;
              insert into debug_collec VALUES(addy);
    END LOOP;
   END
   $$;
  