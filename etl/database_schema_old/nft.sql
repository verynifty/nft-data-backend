CREATE TABLE nft
(
    "address" varchar,
    "tokenid" NUMERIC,
    "id" varchar,
    "name" varchar,
    "description" varchar NULL,
    "external_url" varchar NULL,
    "original_image" varchar NULL,
    "image" varchar NULL,
    "original_animation" varchar NULL,
    "attributes" jsonb NULL,
    "apiurl" varchar NULL,
    "metadatatype" smallint NULL,
    "imagetype" smallint NULL,
    "owner" varchar NULL,
    "created_at" TIMESTAMP DEFAULT NOW(),
    CONSTRAINT data_unique_nft UNIQUE ("address", "tokenid"),
    CONSTRAINT nft_unique_collection FOREIGN KEY ("address") REFERENCES collection ("address"),
    PRIMARY KEY ("address", "tokenid")
);