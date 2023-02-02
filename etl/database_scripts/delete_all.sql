DROP materialized view IF EXISTS  nft_collection_stats;
DROP trigger IF EXISTS  nft_transfer_insert ON nft_transfer;
DROP trigger IF EXISTS  nft_search_weights_update ON nft;
DROP trigger IF EXISTS  collection_search_weights_update ON collection;
DROP TABLE IF EXISTS token_transfer CASCADE;
DROP TABLE IF EXISTS nft_transfer CASCADE;
DROP TABLE IF EXISTS collection CASCADE;
DROP TABLE IF EXISTS nft  CASCADE;
DROP TABLE IF EXISTS block  CASCADE;
DROP SCHEMA if exists graphile_worker CASCADE;

DROP TABLE IF EXISTS zora_offer  CASCADE;
DROP TABLE IF EXISTS zora_ask  CASCADE;
