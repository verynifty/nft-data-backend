CREATE TABLE nft_attribute
(
    "collection" varchar NOT NULL,
    "token_id" NUMERIC NOT NULL,
    "type" varchar NOT NULL,
    "value" varchar NULL,
    CONSTRAINT nft_attributes_unique UNIQUE ("collection", "token_id", "type")
);