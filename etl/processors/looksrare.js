const axios = require("axios");
const { collectionLaunch } = require("../../amplify/backend/function/niftyapi/src/controllers/workerController");
const ToolBox = require("../utils/toolbox");

function LooksRare() {
    this.name = "LooksRare";
    this.version = 1;
    this.abiDecoder = abiDecoder = require("abi-decoder");
    let abi = require("../abis/looksrare.json")
    this.abiDecoder.addABI(abi);
}

LooksRare.prototype.toString = function () {
    return "Marketplace :: " + this.name + " :: " + this.version;
}

let isEventLooksRareSale = function (e) {
    return (e.address.toLowerCase() == "0x59728544b08ab483533076417fbbb2fd0b17ce3a" && (e.topics[0].toLowerCase() == "0x95fb6205e23ff6bda16a2d1dba56b9ad7c783f67c96fa149785052f47696f2be" || e.topics[0].toLowerCase() == "0x68cd251d4d267c6e2034ff0088b990352b97b2002c0476587d0c4da889c11330"))
}

LooksRare.prototype.processTransfer = async function (event, transfer) {
    // console.log(event)
    let filteredLogs = event.tx.logs.filter(isEventLooksRareSale)
    if (filteredLogs.length == 0) {
        // console.log("No LooksRare sale")
        return;
    }
    console.log("There is a sale")
    //console.log(event)
    // we find the position of the transfer event
    let transferIndex = event.tx.logs.findIndex(function (e) {
        return e.id == event.id
    })
    for (let index = 1; transferIndex + index < event.tx.logs.length && index < 3; index++) {
        if (isEventLooksRareSale(event.tx.logs[transferIndex + index])) {
            let decoded = this.abiDecoder.decodeLogs([event.tx.logs[transferIndex + index]])[0];
            console.log(decoded)
            console.log(transfer)
            if (!(decoded.events[6].value.toLowerCase() == event.address.toLowerCase() && decoded.events[7].value == transfer.value && decoded.events[8].value == (transfer.amount != null ? transfer.amount : '1'))) {
                console.log(decoded.events[6].value.toLowerCase() == event.address.toLowerCase(), decoded.events[7].value == transfer.value, decoded.events[8].value == (transfer.amount != null ? transfer.amount : '1'))
                console.log("broke loop LR")
                break;
            }
            let trade = {
                address: event.address,
                amount: transfer.amount != null ? transfer.amount : 1,
                token_id: transfer.value,
                buyer: transfer.to,
                seller: transfer.from,
                currency: decoded.events[5].value,
                trade_marketplacename: "looksrare",
                trade_marketplace: 2,
                trade_currency: decoded.events[5].value,
                trade_price: decoded.events[9].value,
            }
            if (!(decoded.events[4].value.toLowerCase() == "0x56244bb70cbd3ea9dc8007399f61dfc065190031" || decoded.events[4].value.toLowerCase() == "0x86f909f70813cdb1bc733f4d97dc6b03b8e7e8f3")) {
                // We only index trades with strategies with protocol fees
                return;
            }
            if (decoded.name == "TakerBid" && decoded.events[2].value == transfer.to && decoded.events[3].value == transfer.from) {
                // This is a buy
                console.log("buy")
            } else if (decoded.name == "TakerAsk" && decoded.events[3].value == transfer.to && decoded.events[2].value == transfer.from) {
                // this is a sell
                console.log("sell")
            }
            return trade;
        }
    }
    return null;
}

module.exports = LooksRare;