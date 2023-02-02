select SUM(erc721_transfers) + SUM(erc1155_transfers) from block;

select COUNT(*) from nft_transfer nt;



select count(*) from block


select MIN(blocknumber), MAX(blocknumber) from block



SELECT
    generate_series
FROM
    generate_series(13751131, 13755862)
WHERE
    SUM(erc721_transfers) + SUM(erc1155_transfers) = (select number, COUNT(*) from nft_transfer group by blocknumber);
   	
   
   
   
   SELECT "public"."block"."blocknumber" AS "blocknumber", count(*) AS "count", (count(*) - (avg("public"."block"."erc1155_transfers") + avg("public"."block"."erc721_transfers"))) AS "expression"
FROM "public"."block" INNER JOIN "public"."nft_transfer" "Nft Transfer" ON "public"."block"."blocknumber" = "Nft Transfer"."block_number"
GROUP BY "public"."block"."blocknumber"
ORDER BY "public"."block"."blocknumber" ASC



select COUNT(distinct(nt.collection, nt.token_id)) from nft_transfer nt 

select COUNT(*) from nft