function eventDecoder(abiName) {
  this.abiDecoder = abiDecoder = require("abi-decoder");
  this.abiDecoder.addABI(require("../abis/" + abiName + ".json"));
}

eventDecoder.prototype.logTopicToAddress = function (logTopic) {
  if (logTopic != null && logTopic.length == 66) {
    var res = logTopic.substring(26).toLowerCase();
    if (res == "0000000000000000000000000000000000000000") {
      return "0x0000000000000000000000000000000000000000";
    }
    return "0x" + res;
  }
  return null;
};

eventDecoder.prototype.logDataToAddress = function (logData, position) {
  var res = logData
    .toLowerCase()
    .substring(64 * position + 26, 64 * position + 66);
  return "0x" + res;
};

eventDecoder.prototype.logDataToNumber = function (logData, position) {
  var res = logData
    .toLowerCase()
    .substring(64 * position + 26, 64 * position + 66);
  return BigInt("0x" + res, 10).toString();
};

// How event signature are generated
// https://medium.com/mycrypto/understanding-event-logs-on-the-ethereum-blockchain-f4ae7ba50378
eventDecoder.prototype.decodeTransaction = function (undecodedLogs) {
  let results = [];
  for (const ev of undecodedLogs) {
    let res = this.abiDecoder.decodeLogs([ev]);
    if (res[0] != null) {
      res[0].logIndex = ev.logIndex;
      results.push(res[0]);
    }
  }
  // console.log(results)
  return results;
};

eventDecoder.prototype.decodeLogs = function (undecodedLogs) {
  let results = [];
  for (const ev of undecodedLogs) {
    // console.log("Decoding log", ev)
    let res = this.abiDecoder.decodeLogs([ev]);
    if (res[0] != null) {
      res[0].logIndex = ev.logIndex;
      results.push(res[0]);
    }
  }
  // console.log(results)
  return results;
};

eventDecoder.prototype.decodeTransferLogs = function (undecodedLogs) {
  let results = [];

  for (const ev of undecodedLogs) {
    let result = [];
    if (
      ev.topics[0].toLowerCase() ==
      "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62"
    ) {
      // ERC1155 TransferSingle
      let decodedEV = this.abiDecoder.decodeLogs([ev])[0];
      result = [
        {
          from: decodedEV.events[1].value.toLowerCase(),
          to: decodedEV.events[2].value.toLowerCase(),
          value: decodedEV.events[3].value,
          amount: decodedEV.events[4].value,
        },
      ];
    } else if (
      ev.topics[0].toLowerCase() ==
      "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb"
    ) {
      // ERC1155 Transfer Batch
      let decodedEV = this.abiDecoder.decodeLogs([ev])[0];
      for (const [index] of decodedEV.events[3].value.entries()) {
        let tmp = {
          from: decodedEV.events[1].value.toLowerCase(),
          to: decodedEV.events[2].value.toLowerCase(),
          value: decodedEV.events[3].value[index],
          amount: decodedEV.events[4].value[index],
        };
        result.push(tmp);
      }
    } else if (ev.data.length == 194) {
      // this is non indexed topics
      result = [
        {
          from: this.logDataToAddress(ev.data, 0),
          to: this.logDataToAddress(ev.data, 1),
          value: this.logDataToNumber(ev.data, 2),
        },
      ];
    } else if (ev.data == "0x") {
      result = [
        {
          from: this.logTopicToAddress(ev.topics[1]),
          to: this.logTopicToAddress(ev.topics[2]),
          value: BigInt(ev.topics[3], 10).toString(),
        },
      ];
    } else {
      result = [
        {
          from: this.logTopicToAddress(ev.topics[1]),
          to: this.logTopicToAddress(ev.topics[2]),
          value: BigInt(ev.data, 10).toString(),
        },
      ];
    }
    results.push(result);
  }
  return results;
};

module.exports = eventDecoder;
