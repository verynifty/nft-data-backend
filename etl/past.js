require("dotenv").config();
ToolBox = new (require("./utils/toolbox"))();

// We disable metadata fetching for faster indexing
ToolBox.params.erc721_metadata = true;
ToolBox.params.erc1155_metadata = true;

const blockGap = 50;

(async () => {
  let latest_blocknumber =
    (await ToolBox.storage.getMin("block", "block_number")) + blockGap * 2;
  console.log("Past script starting at block", latest_blocknumber);
  if (latest_blocknumber == +Infinity) {
    console.log("First run: You can't run this script while DB is empty");
    return;
  }

  while (latest_blocknumber > blockGap) {
    console.log(
      "Past script for blocks ",
      latest_blocknumber - blockGap,
      latest_blocknumber
    );
    try {
      await ToolBox.processBlock(
        latest_blocknumber - blockGap,
        latest_blocknumber
      );
      latest_blocknumber -= blockGap;
    } catch (error) {
      console.log(error);
    }
    console.log("Will sleep 200 msec");
    await ToolBox.sleep(200);
  }
})();
