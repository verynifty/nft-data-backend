var Web3 = require('web3');
function Provider(providerAddress) {
    this.providerAddress = providerAddress;
    this.w3 = new Web3(new Web3.providers.HttpProvider(providerAddress));
}

/*
 ** Returns a block with all the transactions and their receipts
 */
Provider.prototype.getBlock = async function (blockNumber, full = true) {
    var block = await this.w3.eth.getBlock(blockNumber, true);
    if (block == null) {
        console.log("Error block ", blockNumber);
        return null;
    }
    if (full) {
        for (let i = 0; i < block.transactions.length; i++) {
            let txReceipt = await this.w3.eth.getTransactionReceipt(block.transactions[i].hash);
            if (txReceipt == null) {
                console.log("Error Empty receipt ", block.transactions[i].hash)
                return null;
            }
            block.transactions[txReceipt.transactionIndex] = Object.assign(block.transactions[txReceipt.transactionIndex], txReceipt)
        }
    }
    return block;
}

Provider.prototype.normalizeHash = function (hash) {
    if (hash == null) {
        return null;
    }
    return (hash.toLowerCase())
}

Provider.prototype.getLatestBlock = async function () {
    var latestBlock = await this.w3.eth.getBlockNumber();
    return (latestBlock);
}

// A rescursive implementation to avoid issues with block range with more than 10k events
// @TODO NEED TO MERGE WITH LAMBDA content
Provider.prototype._getLogs = async function (logs, topic, start, end) {
    console.log("getting logs on range ", start, end, logs.length)
    try {
        let res = await this.w3.eth.getPastLogs({
            topics: topic,
            fromBlock: start, toBlock: end
        });
        logs = logs.concat(res)
    } catch (error) {
        console.log("Cant do chunk")
        while (start <= end) {
            console.log(start, end, logs.length);
            let res = await this.w3.eth.getPastLogs({
                topics: topic,
                fromBlock: start, toBlock: start
            });
            start += 1;
            logs = logs.concat(res);
        }
    }
    return logs;
}

Provider.prototype.getLogs = async function (logTopics, start, end, withTransactionDetails = false) {
    let events = [];
    console.log("Getting logs on", start, end)
    for (const topic of logTopics) {
        //console.log("Topic", topic)
        events = await this._getLogs(
            events,
            [topic],
            start, end
        )
    }
    let tx_cache = {}
    let block_cache = {}
    for (let index = 0; index < events.length; index++) {
        if (block_cache[events[index].blockNumber] == null) {
            block_cache[events[index].blockNumber] = await this.w3.eth.getBlock(events[index].blockNumber, false);
        }
        events[index].block = block_cache[events[index].blockNumber];
        if (withTransactionDetails) {
            if (tx_cache[events[index].transactionHash] == null) {
                tx_cache[events[index].transactionHash] = await this.w3.eth.getTransactionReceipt(events[index].transactionHash);
            }
            events[index].tx = tx_cache[events[index].transactionHash];
        }
    }
    //console.log("ev")
    return events;
}

Provider.prototype.getEvents = async function (contract, start, end, eventName = "allEvents", withTransactionDetails = false) {
    let events = [];
    let middle = end;
    while (start < end) {
        if (start == middle) {
            middle = end
        }
        try {
            events = events.concat(await contract.getPastEvents(eventName, { fromBlock: start, toBlock: middle }))
            start = middle;
            middle = end;
        } catch (error) {
            middle = start + parseInt((middle - start) / 2) + 1;

        }

    }
    let tx_cache = {}
    let block_cache = {}
    for (let index = 0; index < events.length; index++) {
        if (block_cache[events[index].blockNumber] == null) {
            block_cache[events[index].blockNumber] = await this.w3.eth.getBlock(events[index].blockNumber, false);
        }
        events[index].block = block_cache[events[index].blockNumber];
        if (withTransactionDetails) {
            if (tx_cache[events[index].transactionHash] == null) {
                tx_cache[events[index].transactionHash] = await this.w3.eth.getTransactionReceipt(events[index].transactionHash);
            }
            events[index].tx = tx_cache[events[index].transactionHash];
        }
    }
    return (events);
}

Provider.prototype.getEventsAndProcess = async function (contract, start, end, eventName = "allEvents", processor, withTransactionDetails = false) {
    let events = [];
    let middle = end;
    console.log("get events from", start, end, eventName)
    while (start < end) {
        if (start == middle) {
            middle = end
        }
        try {
            events = events.concat(await contract.getPastEvents(eventName, { fromBlock: start, toBlock: middle }))
            // console.log(events)
            start = middle;
            middle = end;
            console.log("get events from", start, middle, end, events.length)

            let tx_cache = {}
            let block_cache = {}
            for (let index = 0; index < events.length; index++) {
                // console.log(index)
                if (withTransactionDetails) {
                    if (tx_cache[events[index].transactionHash] == null) {
                        tx_cache[events[index].transactionHash] = await this.w3.eth.getTransactionReceipt(events[index].transactionHash);
                    }
                    events[index].tx = tx_cache[events[index].transactionHash];
                }

                if (block_cache[events[index].blockNumber] == null) {
                    block_cache[events[index].blockNumber] = await this.w3.eth.getBlock(events[index].blockNumber, false);
                }
                events[index].block = block_cache[events[index].blockNumber];
                events[index].topics = events[index].raw.topics;
                events[index].data = events[index].raw.data;
                delete events[index].raw
            }
            await processor.__ProcessorCallBack(events)
            events = []
        } catch (error) {
            console.log(error)
            middle = start + parseInt((middle - start) / 2) + 1;

        }

    }

    return (events);
}




//EXPERIMENTAL


Provider.prototype.getLogsAddress = async function (logTopics, address) {
    let events = [];
    console.log("Getting logs on")
    for (const topic of logTopics) {
        console.log("Topic", topic)
        events = events.concat(await this.w3.eth.getPastLogs({
            topics: [topic],
            fromBlock: 0,
            address: address
        }))
    }
    console.log(events)
    let tx_cache = {}
    let block_cache = {}
    for (let index = 0; index < events.length; index++) {
        if (block_cache[events[index].blockNumber] == null) {
            block_cache[events[index].blockNumber] = await this.w3.eth.getBlock(events[index].blockNumber, false);
        }
        events[index].block = block_cache[events[index].blockNumber];
        if (true) {
            if (tx_cache[events[index].transactionHash] == null) {
                tx_cache[events[index].transactionHash] = await this.w3.eth.getTransactionReceipt(events[index].transactionHash);
            }
            events[index].tx = tx_cache[events[index].transactionHash];
        }
    }
    return events;
}

module.exports = Provider;
