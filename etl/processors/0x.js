const axios = require("axios");

function ZeroX() {
    this.name = "0X";
    this.version = 1;
    this.abiDecoder = abiDecoder = require("abi-decoder");
    let abi = require("../abis/0x.json")
    this.abiDecoder.addABI(abi);
}

ZeroX.prototype.toString = function () {
    return "Marketplace :: " + this.name + " :: " + this.version;
}

let isEventFill = function (e) {
    return (e.address.toLowerCase() == "0x080bf510fcbf18b91105470639e9561022937712" && e.topics[0].toLowerCase() == "0x0bcc4c97732e47d9946f229edb95f5b6323f601300e4690de719993f3c371129")
}

ZeroX.prototype.processTransfer = async function (event, transfer) {
    // we find the position of the transfer event
    let transferIndex = event.tx.logs.findIndex(function (e) {
        return e.id == event.id
    })
    if (transferIndex == 0) {
        return;
    }
    let filteredLogs = event.tx.logs.slice(0, transferIndex).filter(isEventFill)
    if (filteredLogs.length == 0) {
        return;
    }
    let decoded = this.abiDecoder.decodeLogs(filteredLogs);
    for (const fillev of decoded) {

    }

    /*
    let trade = {
        address: event.address.toLowerCase(),
        amount: transfer.amount != null ? transfer.amount : 1,
        token_id: transfer.value,
        buyer: transfer.to,
        seller: transfer.from,
        trade_price: price,
        trade_currency: currency,
        trade_marketplacename: "zora",
        trade_marketplace: 3,
    }
    */
    return null;
}

module.exports = ZeroX;