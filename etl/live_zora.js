
try {
    require("dotenv").config();
    ToolBox = new (require("./utils/toolbox"))();
    const ZORA_Ask_ABI = require("./abis/zora_ask.json");
    const ZORA_Offer_ABI = require("./abis/zora_offer.json");


    (async () => {
        let ZORA_Ask = new ToolBox.ethereum.w3.eth.Contract(ZORA_Ask_ABI, "0x6170B3C3A54C3d8c854934cBC314eD479b2B29A3");
        let ZORA_Offer = new ToolBox.ethereum.w3.eth.Contract(ZORA_Offer_ABI, "0x76744367AE5A056381868f716BDF0B13ae1aEaa3");
        try {
            let latest_blocknumber = Math.max(
                await ToolBox.storage.getMax("zora_offer", "block_number"),
                await ToolBox.storage.getMax("zora_ask", "block_number")
            ) - 20; 
            while (true) {
                let current_block =
                    (await ToolBox.ethereum.getLatestBlock()) -
                    ToolBox.params.reorg_buffer;
                let logsFilter = {
                    fromBlock: latest_blocknumber,
                    toBlock: current_block
                }
                if (latest_blocknumber == -Infinity) {
                    logsFilter = {
                        fromBlock: 0,
                        toBlock: 'latest'
                    }
                }

                // Ask module
                let offerEvents = await ZORA_Offer.getPastEvents("allEvents", logsFilter)
                for (const ev of offerEvents) {
                    //console.log(ev.returnValues)
                    let eventsStatus = { // An ask can have different status, 0 means active, 1 is cancelled, 2 is filled
                        "OfferCreated": 0,
                        "OfferUpdated": 0,
                        "OfferCanceled": 1,
                        "OfferFilled": 2
                    }
                    if (eventsStatus[ev.event] != null) { // This event is tracked?
                        let block = await ToolBox.ethereum.w3.eth.getBlock(ev.blockNumber, false);
                        ToolBox.storage.insert("zora_offer", {
                            "block_number": ev.blockNumber,
                            "timestamp": new Date(
                                parseInt(parseInt(block.timestamp) * 1000)
                              ).toUTCString(),
                            "log_index": ev.logIndex,
                            "transaction_hash": ToolBox.ethereum.normalizeHash(ev.transactionHash),
                            "offer_id": ev.returnValues.id,
                            "address": ToolBox.ethereum.normalizeHash(ev.returnValues.tokenContract),
                            "token_id": ev.returnValues.tokenId,
                            "status": eventsStatus[ev.event],
                            "buyer": ToolBox.ethereum.normalizeHash(ev.returnValues.taker),
                            "finder": ToolBox.ethereum.normalizeHash(ev.returnValues.finder),
                            "seller": ToolBox.ethereum.normalizeHash(ev.returnValues.offer.maker),
                            "currency": ToolBox.ethereum.normalizeHash(ev.returnValues.offer.currency) == "0x0000000000000000000000000000000000000000" ? null : ToolBox.ethereum.normalizeHash(ev.returnValues.offer.currency),
                            "price": ev.returnValues.offer.amount,
                            "fee": ev.returnValues.offer.findersFeeBps,
                        })
                    }
                }

                // Ask module
                let askEvents = await ZORA_Ask.getPastEvents("allEvents", logsFilter)
                for (const ev of askEvents) {
                    //console.log(ev.returnValues)
                    let eventsStatus = { // An ask can have different status, 0 means active, 1 is cancelled, 2 is filled
                        "AskCreated": 0,
                        "AskPriceUpdated": 0,
                        "AskCanceled": 1,
                        "AskFilled": 2
                    }
                    if (eventsStatus[ev.event] != null) { // This event is tracked?
                        let block = await ToolBox.ethereum.w3.eth.getBlock(ev.blockNumber, false);
                        ToolBox.storage.insert("zora_ask", {
                            "block_number": ev.blockNumber,
                            "timestamp": new Date(
                                parseInt(parseInt(block.timestamp) * 1000)
                              ).toUTCString(),
                            "log_index": ev.logIndex,
                            "transaction_hash": ToolBox.ethereum.normalizeHash(ev.transactionHash),
                            "address": ToolBox.ethereum.normalizeHash(ev.returnValues.tokenContract),
                            "token_id": ev.returnValues.tokenId,
                            "status": eventsStatus[ev.event],
                            "buyer": ToolBox.ethereum.normalizeHash(ev.returnValues.buyer),
                            "finder": ToolBox.ethereum.normalizeHash(ev.returnValues.finder),
                            "seller": ToolBox.ethereum.normalizeHash(ev.returnValues.ask.seller),
                            "seller_funds_recipient": ToolBox.ethereum.normalizeHash(ev.returnValues.ask.sellerFundsRecipient),
                            "currency": ToolBox.ethereum.normalizeHash(ev.returnValues.ask.askCurrency) == "0x0000000000000000000000000000000000000000" ? null : ToolBox.ethereum.normalizeHash(ev.returnValues.ask.askCurrency),
                            "price": ev.returnValues.ask.askPrice,
                            "fee": ev.returnValues.ask.findersFeeBps,
                        })
                    }
                }
                await ToolBox.sleep(100000);
            }
        } catch (error) {
            console.log(error);
        }
    })();
} catch (error) {
    console.log(error);
}
