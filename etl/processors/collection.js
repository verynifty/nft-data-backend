const ERC721ABI = require("../abis/allERC.json");
const AbiFunctions = require("abi-decode-functions");
const axios = require("axios");
const { quickAddJob } = require("graphile-worker");

var slugify = require("slugify");

function Collection(address) {
  this.address = ToolBox.ethereum.normalizeHash(address);
  this.decoder = new (require("../utils/eventDecoder"))("transfers");
  this.contract = new ToolBox.ethereum.w3.eth.Contract(ERC721ABI, this.address);
  this.type = null;
}

Collection.prototype.create = async function () {
  let storage = await this.getFromStorage(false);
  // console.log("Got from storage" , storage)
  if (storage != null) {
    //console.log("This collection already exists", storage.name, storage.symbol);
    this.type = storage.type;
    this.name = storage.name;
    this.symbol = storage.symbol;
    this.backfilled = storage.backfilled;
    this.defaultImage = storage.default_image;
    this.firstBlockSeen = storage.first_block_seen;
    return;
  }
  //console.log("Fetching informations for collection", this.address)
  var decimals = 1;
  var name = null;
  var symbol = null;
  var nft_data_base_url = null;
  var nft_image_base_url = null;
  var owner = "0x0000000000000000000000000000000000000000";

  try {
    name = await this.contract.methods.name().call();
    name = name.replace(/[\u0000-\u001F\u007F-\u009F]/g, "");
  } catch (error) {}

  //console.log("Got name", name)
  try {
    symbol = await this.contract.methods.symbol().call();
    symbol = symbol.replace(/[\u0000-\u001F\u007F-\u009F]/g, "");
  } catch (error) {}
  //console.log("Got symbol", symbol)

  try {
    decimals = await this.contract.methods.decimals().call();
  } catch (error) {}

  try {
    owner = await ToolBox.ethereum.normalizeHash(
      await this.contract.methods.owner().call()
    );
  } catch (error) {}
  let type = await this.detectType();
  //console.log("Detect type", type)
  if (type != 721 && type != 20 && type != 1155) {
    console.log("Not supported yet", this.address);
    return;
  }

  // We try to fetch OpenSea data in case the contract doesn't implement those optional getters
  if ((type == 721 || type == 1155) && (name == "" || symbol == "")) {
    try {
      let osResult = await axios.get(
        "https://api.opensea.io/api/v1/asset_contract/" + this.address
      );
      osResult = osResult.data;
      if (osResult != null) {
        name = osResult.name;
        symbol = osResult.symbol;
      }
    } catch (error) {}
  }

  let currentBlock = await ToolBox.ethereum.getLatestBlock();
  let slug = slugify(name != null ? name.toLowerCase() : this.address, {
    remove: /[*+~%\<>/;.(){}?,'"!:@#^|]/g,
  });
  //console.log("Slug before", slug)
  let slugTaken = await ToolBox.storage.findOne("collection", { slug: slug });
  if (slugTaken != null) {
    slug = slugify(slug + "-" + this.address.substring(6));
  }
  let item = {
    address: this.address,
    name: name,
    slug: slug,
    symbol: symbol,
    type: type,
    decimals: decimals,
    first_block_seen: currentBlock,
    owner: owner,
    nft_data_base_url: nft_data_base_url,
    nft_image_base_url: nft_image_base_url,
  };
  this.type = type;
  await ToolBox.storage.insert("collection", item);
};

Collection.prototype.getFromStorage = async function (forceCreate = true) {
  let c = await ToolBox.storage.findOne("collection", { address: this.address });
  if (c == null && forceCreate) {
    await this.create()
    c = await ToolBox.storage.findOne("collection", { address: this.address })
  }
  return c;
};

Collection.prototype.addTransfer = async function (
  tx,
  from,
  to,
  value,
  amount = 1,
  transfer_index = 0,
  trade_info = null
) {
  t = {
    trade_marketplace: null,
    trade_price: null,
    trade_currency: null,
  }
  if (trade_info != null && trade_info.trade_marketplace != null) {
    t.trade_marketplace = trade_info.trade_marketplace
    if (trade_info.trade_currency == null || trade_info.trade_currency.toLowerCase() == "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2") {
      t.trade_currency = null; // currency is ETH 18 decimals
    } else {
      t.trade_currency = trade_info.trade_currency.toLowerCase();
    }
    t.trade_price = trade_info.trade_price;
    console.log(t)
  }
  if (this.type == 721) {
    let nft = new ToolBox.NFT(this.address, value);
    if (ToolBox.params.erc721_transfers) {
      // console.log("ADD ERC721 transfer")
      let item = {
        collection: ToolBox.ethereum.normalizeHash(this.address),
        block_number: tx.blockNumber,
        transaction_hash: ToolBox.ethereum.normalizeHash(tx.transactionHash),
        transaction_index: tx.transactionIndex,
        tx_from:
          tx.tx != null ? ToolBox.ethereum.normalizeHash(tx.tx.from) : null,
        tx_to: tx.tx != null ? ToolBox.ethereum.normalizeHash(tx.tx.to) : null,
        gas_price:
          tx.tx != null ? BigInt(tx.tx.effectiveGasPrice != null ? tx.tx.effectiveGasPrice : 0).toString(10) : null,
        log_index: tx.logIndex,
        transfer_index: transfer_index,
        timestamp: new Date(
          parseInt(parseInt(tx.block.timestamp) * 1000)
        ).toUTCString(),
        to: ToolBox.ethereum.normalizeHash(to),
        from: ToolBox.ethereum.normalizeHash(from),
        token_id: value,
        amount: 1, // ERC721 have always amount 1
        trade_currency: t.trade_currency,
        trade_price: t.trade_price,
        trade_marketplace: t.trade_marketplace
      };
      await ToolBox.storage.insert("nft_transfer", item);
      if (ToolBox.params.erc721_metadata) {
        await nft.queueUpdate();
      }
    }
  } else if (this.type == 1155) {
    let nft = new ToolBox.NFT(this.address, value);
    // console.log("ADD ERC1155 transfer")
    let item = {
      collection: ToolBox.ethereum.normalizeHash(this.address),
      block_number: tx.blockNumber,
      transaction_hash: ToolBox.ethereum.normalizeHash(tx.transactionHash),
      transaction_index: tx.transactionIndex,
      tx_from:
        tx.tx != null ? ToolBox.ethereum.normalizeHash(tx.tx.from) : null,
      tx_to: tx.tx != null ? ToolBox.ethereum.normalizeHash(tx.tx.to) : null,
      gas_price:
        tx.tx != null ? BigInt(tx.tx.effectiveGasPrice).toString(10) : null,
      log_index: tx.logIndex,
      transfer_index: transfer_index,
      timestamp: new Date(
        parseInt(parseInt(tx.block.timestamp) * 1000)
      ).toUTCString(),
      to: ToolBox.ethereum.normalizeHash(to),
      from: ToolBox.ethereum.normalizeHash(from),
      token_id: value,
      amount: amount,
      trade_currency: t.trade_currency,
      trade_price: t.trade_price,
      trade_marketplace: t.trade_marketplace
    };
    await ToolBox.storage.insert("nft_transfer", item);
    if (ToolBox.params.erc1155_metadata) {
      await nft.queueUpdate();
    }
  } else if (this.type == 20) {
    if (!ToolBox.params.erc20_transfers) return;
    // console.log("ADD ERC20 transfer")
    let item = {
      collection: ToolBox.ethereum.normalizeHash(this.address),
      block_number: tx.blockNumber,
      transaction_hash: ToolBox.ethereum.normalizeHash(tx.transactionHash),
      transaction_index: tx.transactionIndex,
      tx_from:
        tx.tx != null ? ToolBox.ethereum.normalizeHash(tx.tx.from) : null,
      tx_to: tx.tx != null ? ToolBox.ethereum.normalizeHash(tx.tx.to) : null,
      gas_price:
        tx.tx != null ? BigInt(tx.tx.effectiveGasPrice).toString(10) : null,
      log_index: tx.logIndex,
      timestamp: new Date(
        parseInt(parseInt(tx.block.timestamp) * 1000)
      ).toUTCString(),
      to: ToolBox.ethereum.normalizeHash(to),
      from: ToolBox.ethereum.normalizeHash(from),
      amount: value,
    };
    await ToolBox.storage.insert("token_transfer", item);
  }
};

Collection.prototype.arrayContainsFunction = function (array, funcsig) {
  return (
    array.indexOf(ToolBox.ethereum.w3.utils.sha3(funcsig).substring(0, 10)) > -1
  );
};

Collection.prototype.detectType = async function (address) {
  if (address == null) {
    address = this.address;
  }
  // Some legacy tokens on mainnet
  if (this.address == "0x06012c8cf97bead5deae237070f9587f8e7a266d") {
    // cryptokitties
    return 721;
  } else if (this.address == "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48") {
    // USDC
    return 20;
  }
  var bytecode = (await ToolBox.ethereum.w3.eth.getCode(address)).toLowerCase();
  if (
    bytecode.startsWith("0x363d3d373d3d3d363d73") &&
    bytecode.endsWith("5af43d82803e903d91602b57fd5bf3")
  ) {
    // We are in a EIP-1167 Minimal proxy https://eips.ethereum.org/EIPS/eip-1167
    let targetAddress = "0x" + bytecode.substring(22, 62);
    console.log("Minimal proxy", targetAddress);
    return await this.detectType(targetAddress);
  }
  const decoder = new AbiFunctions.default(bytecode);
  const functionIds = decoder.getFunctionIds();
  var isERC721 =
    this.arrayContainsFunction(
      functionIds,
      "setApprovalForAll(address,bool)"
    ) &&
    this.arrayContainsFunction(functionIds, "ownerOf(uint256)") &&
    (this.arrayContainsFunction(functionIds, "transfer(address,uint256)") ||
      this.arrayContainsFunction(
        functionIds,
        "transferFrom(address,address,uint256)"
      )) &&
    this.arrayContainsFunction(functionIds, "approve(address,uint256)");
  if (isERC721) {
    return 721;
  }
  var isERC20 =
    this.arrayContainsFunction(functionIds, "totalSupply()") &&
    this.arrayContainsFunction(functionIds, "balanceOf(address)") &&
    this.arrayContainsFunction(functionIds, "transfer(address,uint256)") &&
    this.arrayContainsFunction(
      functionIds,
      "transferFrom(address,address,uint256)"
    ) &&
    this.arrayContainsFunction(functionIds, "approve(address,uint256)") &&
    this.arrayContainsFunction(functionIds, "allowance(address,address)");
  if (isERC20) {
    return 20;
  }
  var isERC1155 =
    this.arrayContainsFunction(
      functionIds,
      "safeTransferFrom(address,address,uint256,uint256,bytes)"
    ) &&
    this.arrayContainsFunction(
      functionIds,
      "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
    ) &&
    this.arrayContainsFunction(
      functionIds,
      "balanceOfBatch(address[],uint256[])"
    );
  if (isERC1155) {
    return 1155;
  }
  /* We check if we are dealing with an upgreadable contract EIP1967 */
  let eip1967 = new ToolBox.ethereum.w3.eth.Contract(
    require("../abis/proxyContract.json"),
    address
  );
  try {
    let implementation_address = await eip1967.methods.implementation().call();
    return await this.detectType(implementation_address);
  } catch (error) {}
  /* We check if we can read the implementation directly from storage? */
  try {
    let implementation_address =
      "0x" +
      (
        await ToolBox.ethereum.w3.eth.getStorageAt(
          address,
          "0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc"
        )
      ).substring(26);
    if (
      implementation_address != "0x0000000000000000000000000000000000000000"
    ) {
      return await this.detectType(implementation_address);
    }
  } catch (error) {}
  /* We check if we can read the implementation directly from storage? */
  try {
    let implementation_address =
      "0x" +
      (
        await ToolBox.ethereum.w3.eth.getStorageAt(
          address,
          "0x7050c9e0f4ca769c69bd3a8ef740bc37934f8e2c036e5a723fd8ee048ed3f8c3"
        )
      ).substring(26);
    if (
      implementation_address != "0x0000000000000000000000000000000000000000"
    ) {
      return await this.detectType(implementation_address);
    }
  } catch (error) {}
  /* Vyper contracts Bytecode is different from Solidity */
  let vyper_contract = new ToolBox.ethereum.w3.eth.Contract(
    require("../abis/erc20.json"),
    address
  );
  try {
    let result = await vyper_contract.methods.allowance(
      "0xea674fdde714fd979de3edf0f56aa9716b898ec8",
      "0x593a59e8ca4e8c5e96914233d7308b124e6879a8"
    );
    let decimals = await this.contract.methods.decimals().call();
    /* If no error it 99% it's an ERC20 */
    return 20;
  } catch (error) {}
  return 0;
};

module.exports = Collection;
