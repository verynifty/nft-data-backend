CREATE TABLE token_transfer
(
    "collection" varchar NULL,
    "blocknumber" numeric NULL,
    "transactionhash" varchar NULL,
    "transactionindex" NUMERIC NULL,
    "tx_to" varchar NULL,
    "tx_from" varchar NULL,
    "logindex" numeric NULL,
    "timestamp" timestamp NULL,
    "to" varchar NULL,
    "from" varchar NULL,
    "amount" NUMERIC NULL,
        "created_at" TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_token_transfer UNIQUE ("transactionhash", "logindex")
);

CREATE TABLE nft_transfer
(
    "collection" varchar NULL,
    "blocknumber" numeric NULL,
    "transactionhash" varchar NULL,
    "transactionindex" NUMERIC NULL,
    "tx_to" varchar NULL,
    "tx_from" varchar NULL,
    "logindex" numeric NULL,
    "timestamp" timestamp NULL,
    "to" varchar NULL,
    "from" varchar NULL,
    "amount" NUMERIC NULL,
    "tokenid" NUMERIC NULL,
        "created_at" TIMESTAMP DEFAULT NOW(),

    CONSTRAINT unique_nft_transfer UNIQUE ("transactionhash", "logindex")
);