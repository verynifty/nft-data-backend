const axios = require("axios");

/*
ALTER TABLE public.nft_transfer ADD trade_currency varchar NULL;
ALTER TABLE public.nft_transfer ADD trade_price numeric NULL;
ALTER TABLE public.nft_transfer ADD trade_marketplace smallint NULL DEFAULT 0;
*/
function OpenSea() {
    this.name = "OpenSea";
    this.version = 1;
    this.abiDecoder = abiDecoder = require("abi-decoder");
    this.abiDecoder.addABI(require("../abis/wyvern.json"));
    this.abiDecoder.addABI(require("../abis/erc20.json"));
}

OpenSea.prototype.toString = function () {
    return "Marketplace :: " + this.name + " :: " + this.version;
}

let isEventOpenseaSale = function (e) {
    return ((e.address.toLowerCase() == "0x7f268357a8c2552623316e2562d90e642bb538e5" || e.address.toLowerCase() == "0x7be8076f4ea4a4ad08075c2508e481d6c946d12b") && e.topics[0].toLowerCase() == "0xc4109843e0b7d514e4c093114b863f8e7d8d9a458c372cd51bfe526b588006c9")
}

let isEventNFTRelated = function (e) {
    return (e.topics[0].toLowerCase() == '0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925'
        || e.topics[0].toLowerCase() == '0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb'
        || e.topics[0].toLowerCase() == '0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62'
        || e.topics[0].toLowerCase() == '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef')
}
OpenSea.prototype.processTransfer = async function (event, transfer) {
    // console.log(event)
    let filteredLogs = event.tx.logs.filter(isEventOpenseaSale)
    if (filteredLogs.length == 0) {
        // console.log("No opensea sale")
        return;
    }
    //console.log(event)
    // we find the position of the transfer event
    let transferIndex = event.tx.logs.findIndex(function (e) {
        return e.id == event.id
    })
    if (event.tx.logs.length > transferIndex + 1 && isEventOpenseaSale(event.tx.logs[transferIndex + 1])) {
        //console.log("Possible sale ", event.tx, transfer)
        let decoded = this.abiDecoder.decodeLogs([event.tx.logs[transferIndex + 1]])[0]
        //console.log(decoded)
        let trade = {
            address: event.address,
            amount: transfer.amount != null ? transfer.amount : 1,
            token_id: transfer.value,
            buyer: transfer.to,
            seller: transfer.from,
            trade_price: decoded.events[4].value,
            trade_marketplacename: "opensea",
            trade_marketplace: 1,
            trade_currency: null
        }



        let acc = 1;
        while (transferIndex - acc >= 0 && isEventNFTRelated(event.tx.logs[transferIndex - acc])) {
            //console.log(acc)
            if (event.tx.logs[transferIndex - acc].topics[0] == '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef') {
                let decoded_transfer = null;
                try {
                    decoded_transfer = (this.abiDecoder.decodeLogs([event.tx.logs[transferIndex - acc]]))[0]
                    if (trade.trade_price == decoded_transfer.events[2].value && transfer.from == decoded_transfer.events[1].value && transfer.to == decoded_transfer.events[0].value) {
                        trade.trade_currency = decoded_transfer.address.toLowerCase()
                        break;
                        // NEED to flag other transfers
                    }
                } catch (error) {
                    //console.log(error)
                    // can't decode probably cause of ERC721 transfer instead of ERC20
                }
            }
            acc++
        }
        return trade;
    }
    return null
}

module.exports = OpenSea;