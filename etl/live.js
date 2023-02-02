
require("dotenv").config();
ToolBox = new (require("./utils/toolbox"))();

try {
  (async () => {
    try {
      ToolBox.workerFlags = ["live"];
      ToolBox.workerPriority = 80;
      let latest_blocknumber =
        Math.max(
          await ToolBox.storage.getMax("token_transfer", "block_number"),
          await ToolBox.storage.getMax("nft_transfer", "block_number")
        ) - 20;

      if (latest_blocknumber == -Infinity) {
        console.log("First run");
        latest_blocknumber =
          (await ToolBox.ethereum.getLatestBlock()) -
          ToolBox.params.reorg_buffer -
          10;
      }
      while (true) {
        let current_block =
          (await ToolBox.ethereum.getLatestBlock()) -
          ToolBox.params.reorg_buffer;
        while (latest_blocknumber < current_block) {
          console.log("Do block , ", latest_blocknumber);
          if (current_block - latest_blocknumber > 10) {
            // batch 10 blocks if possible
            try {
              console.log("Injesting chunk");
              await ToolBox.processBlock(
                latest_blocknumber,
                latest_blocknumber + 15
              );
              latest_blocknumber += 15;
            } catch (error) {
              console.log(error);
              ToolBox.error(
                "live.js/main/" + latest_blocknumber + "/" + current_block,
                error
              );
            }
          } else {
            try {
              console.log("Injesting single");
              await ToolBox.processBlock(
                latest_blocknumber,
                latest_blocknumber
              );
              latest_blocknumber++;
            } catch (error) {
              console.log(error);
              ToolBox.error(
                "live.js/main/" + latest_blocknumber + "/" + current_block,
                error
              );
            }
          }
          console.log("DONE block , ", latest_blocknumber);
        }
        await ToolBox.sleep(ToolBox.params.chain_block_time);
      }
    } catch (error) {
      console.log(error);
    }
  })();
} catch (error) {
  console.log(error);
}
