CREATE TABLE collection
(
    "address" varchar NOT NULL,
    "slug" varchar NOT NULL,
    "name" varchar NULL,
    "symbol" varchar NULL,
    "decimals" numeric NULL,
    "firstblockseen" numeric null,
    "type" varchar null,
    "created_at" TIMESTAMP DEFAULT NOW(),
    "backfilled" boolean DEFAULT FALSE,
    "backfilled_at" TIMESTAMP NULL,
    CONSTRAINT data_unique_collection UNIQUE ("address"),
    PRIMARY KEY ("address")
);