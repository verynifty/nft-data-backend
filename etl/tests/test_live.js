require("dotenv").config();

const ToolBox = new (require("../utils/toolbox"))();

const COLLECTION = require("../processors/collection");

const eventDecoder = new (require("../utils/eventDecoder"))("transfers");

(async () => {
  let collections = {};
  let latest_blocknumber = 13752739
  while (true) {
    let current_block =
      (await ToolBox.ethereum.getLatestBlock()) - ToolBox.params.reorg_buffer;
    while (latest_blocknumber <= current_block) {
      console.log(
        "Working on block",
        latest_blocknumber,
        "Latest block ",
        current_block
      );
      // logTopic for Transfer 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
      // logTopic for TransferSingle (erc1155) 0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62
      // LogTopic for TransferBatch (erc1155) 0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb
      let logs = await ToolBox.ethereum.getLogs(
        ["0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef",
          "0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62",
          "0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb"],
        latest_blocknumber,
        latest_blocknumber,
        ToolBox.params.fetch_tx_details
      );
      let decoded = eventDecoder.decodeTransferLogs(logs);
      for (const [index, ds] of decoded.entries()) {
        let ev = logs[index];
        if (collections[ToolBox.ethereum.normalizeHash(ev.address)] == null) {
          collections[ToolBox.ethereum.normalizeHash(ev.address)] =
            new COLLECTION(ToolBox, ToolBox.ethereum.normalizeHash(ev.address));
            await collections[
              ToolBox.ethereum.normalizeHash(ev.address)
            ].create();
        }
        let c = collections[ToolBox.ethereum.normalizeHash(ev.address)];
        for (const d of ds) {
          await c.addTransfer(ev, d.from, d.to, d.value, d.amount);
        }
      }
      latest_blocknumber++;
      if (latest_blocknumber % 50 == 0) {
        collections = {};
      }
      return;
    }
    await ToolBox.sleep(ToolBox.params.chain_block_time);
  }
})();
