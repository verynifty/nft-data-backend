# NFT data ETL

NFT data ETL by the [Muse DAO](https://musedao.io/) is an open source toolbox for indexing NFT transactions, sales and metadata on EVM compatible blockchains.

## Requirements

* A PostgreSQL compatible database
* NodeJS

## Installation

Clone repository 

```
git clone git@github.com:verynifty/nft-data-backend.git
cd nft-data-backend
```

Install dependencies

```
npm install
```

Add env variables:

```
touch .env
```

and edit with your own values:

```
PEPESEA_DB_USER=
PEPESEA_DB_HOST=
PEPESEA_DB_NAME=
PEPESEA_DB_PASSWORD=
PEPESEA_DB_PORT=

PEPESEA_RPC=
```

Create the DB tables by executing the content of the file:
```
etl/database_scripts/create_all.sql
```

![Database schema](https://github.com/verynifty/nft-data-backend/blob/main/table_summary.png?raw=true)


You can delete at anytime all the tables using:

```
etl/database_scripts/delete_all.sql
```

## Running

### Live mode

To listen to incoming blocks you can run:

```
node etl/live.js
```

This script will listen to incoming blocks and process them to extract relevant data and populate the database. If you stop the script, the next time it will run it will ingest blocks from the latest of your DB to the top of the blockchain.

### Metadata

The metadata ingestion for each NFT is using a worker pool based on ```graphile_workers```. You can run workers on sperated servers using the script:

```
node worker.js
```

They will pick up jobs and execute them to populate the NFT metadata in the DB. 

## Backfill history

In order to populate your DB with old chain data, you can use the script:
```
node etl/past/launch_jobs.js
```

Don't forget to change the block range you want to launch the jobs on.

# API

This repo also contains all ```expressjs``` routes to query your data from a frontend. To launch it run:
```
node api/index.js
```





