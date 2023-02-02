require("dotenv").config();

const LRUMap = require("lru_map").LRUMap;
const { quickAddJob } = require("graphile-worker");
function ToolBox() {
  this.COLLECTION = require("../processors/collection");
  this.NFT = require("../processors/nft");

  this.marketPlaces = [];
  //this.marketPlaces.push(new (require("../processors/opensea"))())
  //this.marketPlaces.push(new (require("../processors/looksrare"))())
  this.marketPlaces.push(new (require("../processors/zora"))())

  // Those are flags attached to jobs when they are added to the queue
  // It enables workers to filter what they have to execute or not
  this.workerFlags = null;
  this.workerPriority = 100;
  this.storage = new (require("./postgres"))({
    user: process.env.PEPESEA_DB_USER,
    host: process.env.PEPESEA_DB_HOST,
    database: process.env.PEPESEA_DB_NAME,
    password: process.env.PEPESEA_DB_PASSWORD,
    port: parseInt(process.env.PEPESEA_DB_PORT),
    ssl: true,
    ssl: { rejectUnauthorized: false },
  });
  this.ethereum = new (require("./ethereum"))(process.env.PEPESEA_RPC);
  this.transferEventDecoder = new (require("./eventDecoder"))("transfers");
  this.params = {
    erc20_transfers: false,
    erc20_history: false,
    erc721_transfers: true,
    erc721_history: true,
    erc721_metadata: true,
    erc721_attributes: true,
    erc1155_history: true,
    erc1155_metadata: true,
    erc1155_attributes: true,
    fetch_tx_details: true,
    chain_block_time: 10,
    reorg_buffer: 3,
    worker_update_max_retry: this.readParamInteger(
      "NFT_DATA_WORKER_NFT_UDPATE_MAX_RETRY",
      2
    ),
    requestTimeout: this.readParamInteger("NFT_DATA_REQUESTTIMEOUT", 5000),
    cache_collection_size: this.readParamInteger(
      "NFT_DATA_CACHE_COLLECTION_SIZE",
      300
    ),
    bucket_nft_image_path: "nft-image",
    worker_log_success: false,
    worker_log_error: true,
  };

  this.error = function (name, data) {
    console.error(name, data);
  };

  this.cache = {
    collections: new LRUMap(this.params.cache_collection_size),
  };
  // console.log("Params", this.params)
}

ToolBox.prototype.readParam = function (name) {
  let p = process.env[name];
  if (p == null || parseInt(p) != "1") {
    return false;
  }
  return true;
};

ToolBox.prototype.readParamInteger = function (name, ifnull = 0) {
  let p = process.env[name];
  if (p == null) {
    return ifnull;
  }
  return parseInt(p);
};

ToolBox.prototype.sleep = function (waitTimeInMs) {
  return new Promise((resolve) => setTimeout(resolve, waitTimeInMs));
};

ToolBox.prototype.processBlock = async function (
  startBlock,
  endBlock,
  filterContract = null
) {
  console.log(
    `Working on ${endBlock - startBlock + 1
    } blocks : (${startBlock},${endBlock})`
  );
  let block_transfers = {};
  let i = startBlock;
  while (i <= endBlock) {
    block_transfers[i] = {
      1155: 0,
      721: 0,
      20: 0,
    };
    i++;
  }
  // logTopic for Transfer 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
  // logTopic for TransferSingle (erc1155) 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
  // LogTopic for TransferBatch (erc1155) 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
  let logs = await this.ethereum.getLogs(
    [
      "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
      "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62",
      "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb",
    ],
    startBlock,
    endBlock
  );
  let decoded = this.transferEventDecoder.decodeTransferLogs(logs);
  console.log("Got events: ", decoded.length);
  let tx_cache = {};
  for (const [index, ds] of decoded.entries()) {
    // console.log("Make event ", index);
    let ev = logs[index];
    if (
      filterContract != null &&
      this.ethereum.normalizeHash(ev.address) !=
      this.ethereum.normalizeHash(filterContract)
    ) {
      continue;
    }
    let c = this.cache.collections.get(this.ethereum.normalizeHash(ev.address));
    if (c == null) {
      let newCollection = new this.COLLECTION(
        this.ethereum.normalizeHash(ev.address)
      );
      await newCollection.create();
      this.cache.collections.set(
        this.ethereum.normalizeHash(ev.address),
        newCollection
      );
      c = this.cache.collections.get(this.ethereum.normalizeHash(ev.address));
    }
    if (
      this.params.fetch_tx_details &&
      ((c.type == 721) ||
        (c.type == 1155) ||
        (c.type == 20 && this.params.erc20_transfers))
    ) {
      if (tx_cache[ev.transactionHash] == null) {
        tx_cache[ev.transactionHash] =
          await this.ethereum.w3.eth.getTransactionReceipt(ev.transactionHash);
      }
      ev.tx = tx_cache[ev.transactionHash];
    }
    let transfer_index = 0; // Transfer index are useful for ingesting ERC1155 bach transfers


    // Divide price per number of ds?
    let itemTransferred = 0n;
    for (const d of ds) {
      itemTransferred = itemTransferred + BigInt(ds.amount != null ? ds.amount : 1)
    }

    for (const d of ds) {
      let trade_info = null;
      try {
        if (c.type == 721 || c.type == 1155) {
          for (const marketPlace of this.marketPlaces) {
            // console.log(marketPlace.toString())
            trade_info = await marketPlace.processTransfer(ev, d)
            if (trade_info != null) {
              trade_info.trade_price = (BigInt(trade_info.trade_price) / itemTransferred).toString()
              break;
            }
          }
        }
      } catch (error) {
        console.error("There was an error with trade parsing", error)
      }
      await c.addTransfer(
        ev,
        d.from,
        d.to,
        d.value,
        d.amount,
        transfer_index++,
        trade_info
      );
    }
    block_transfers[ev.blockNumber][c.type] =
      block_transfers[ev.blockNumber][c.type] + ds.length;
  }
  console.log("ADD Blocks");
  i = startBlock;
  while (i <= endBlock) {
    console.log(i, endBlock);
    await this.storage.upsert("block", {
      block_number: i,
      erc721_transfers: block_transfers[i][721],
      erc1155_transfers: block_transfers[i][1155],
      erc20_transfers: block_transfers[i][20],
    }, "block_number");
    i++;
  }
  console.log(
    `Processed ${endBlock - startBlock + 1
    } blocks : (${startBlock},${endBlock})`
  );
};

ToolBox.prototype.replaceIPFSURI = function (URI) {
  if (URI == null) {
    return null;
  } else if (URI.startsWith("ipfs://")) {
    URI = URI.replace("ipfs://", "https://cloudflare-ipfs.com/ipfs/").replace(
      "/ipfs/ipfs/",
      "/ipfs/"
    );
  } else if (URI.startsWith("ipfs://ipfs/")) {
    URI = URI.replace(
      "ipfs://ipfs/",
      "https://cloudflare-ipfs.com/ipfs/"
    ).replace("/ipfs/ipfs/", "/ipfs/");
  } else if (URI.startsWith("ar://")) {
    URI = URI.replace("ar://", "https://arweave.net/");
  }
  return URI;
};

ToolBox.prototype.queueBlockRange = async function (start, end, steps) {
  let job = await quickAddJob(
    { pgPool: this.storage.pool },
    "fill_block_range",
    {
      startBlock: start,
      endBlock: end,
      steps: steps,
    },
    {
      jobKey: "block_range_" + start + "_" + end,
      jobKeyMode: "preserve_run_at",
      priority: 10,
      maxAttempts: 2,
    }
  );
};

module.exports = ToolBox;
