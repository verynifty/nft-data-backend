UPDATE collection SET (first_transfer) =
    (SELECT MIN(timestamp) FROM nft_transfer
     WHERE nft_transfer.collection = collection.address);


         CREATE UNIQUE INDEX nft_collection_stats_idx ON nft_collection_stats (address);
