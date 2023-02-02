const axios = require("axios");
function Zora() {
    this.name = "Zora Ask";
    this.version = 1;
    this.abiDecoder = abiDecoder = require("abi-decoder");
    let abi = require("../abis/zora.json")
    this.abiDecoder.addABI(abi);
}

Zora.prototype.toString = function () {
    return "Marketplace :: " + this.name + " :: " + this.version;
}

let isEventZoraSale = function (e) {
    return (e.address.toLowerCase() == "0x6170b3c3a54c3d8c854934cbc314ed479b2b29a3" && e.topics[0].toLowerCase() == "0x21a9d8e221211780696258a05c6225b1a24f428e2fd4d51708f1ab2be4224d39")
}

Zora.prototype.processTransfer = async function (event, transfer) {
    let filteredLogs = event.tx.logs.filter(isEventZoraSale)
    if (filteredLogs.length == 0) {
        return;
    }
    console.log("There is a ZORA sale")
    // we find the position of the transfer event
    let transferIndex = event.tx.logs.findIndex(function (e) {
        return e.id == event.id
    })
    if (event.tx.logs.length > transferIndex + 2 && isEventZoraSale(event.tx.logs[transferIndex + 2])) {
        let decoded = this.abiDecoder.decodeLogs([event.tx.logs[transferIndex + 2]])[0]

        if (decoded.events[0].value == event.address.toLowerCase() && decoded.events[1].value == transfer.value && decoded.events[2].value == transfer.to.toLowerCase()) {
            let ask_struct = ToolBox.ethereum.w3.eth.abi.decodeParameters(
                [
                    {
                        type: 'address',
                        name: 'finder'
                    },
                    {
                        type: 'address',
                        name: 'seller'
                    },
                    {
                        type: 'address',
                        name: 'sellerfundsrecipient'
                    },
                    {
                        type: 'address',
                        name: 'currency'
                    },
                    {
                        type: 'uint16',
                        name: 'fees'
                    },
                    {
                        type: 'uint256',
                        name: 'price'
                    }
                ], event.tx.logs[transferIndex + 2].data)
            let currency = ask_struct.currency.toLowerCase();
            let price = ask_struct.price.toLowerCase();
            let seller = ask_struct.seller.toLowerCase();
            if (seller.toLowerCase() == transfer.from) {
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
                return trade;
            }
        }

    }
    return null;
}

module.exports = Zora;