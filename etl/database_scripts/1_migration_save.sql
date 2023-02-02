ALTER TABLE public.collection ADD transfers_total numeric NULL DEFAULT 0;


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
 
 
 
 
 




 update collection set transfers_total = 
     (select COUNT(*) from nft_transfer where nft_transfer."collection" = collection."address")





     UPDATE collection
SET first_transfer = subquery.minima
FROM (SELECT MIN(nft_transfer.timestamp) as minima, nft_transfer.collection as address
      FROM  nft_transfer GROUP BY 2) AS subquery
WHERE collection.address=subquery.address;



DROP INDEX nft_search_weights_idx;
DROP INDEX collection_search_weights_idx;



DROP TRIGGER IF EXISTS nft_search_weights_update ON nft; 
DROP TRIGGER IF EXISTS collection_search_weights_update ON collection;


// block aletered tables 
// 14600458

ALTER TABLE public.collection DROP COLUMN search_weights;
ALTER TABLE public.nft DROP COLUMN search_weights;
