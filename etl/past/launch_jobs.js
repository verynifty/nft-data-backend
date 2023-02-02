ToolBox = new (require("../utils/toolbox"))();

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

(async () => {
  // ToolBox.params.erc721_metadata = false;
  // ToolBox.params.erc1155_metadata = false;
  let i = 2770967;
  let endBlock = 2772000;
  let block_numbers = 25;
  for (let index = 0; i < endBlock; index++) {
    console.log(i, index);
    await ToolBox.queueBlockRange(i, i + block_numbers - 1, block_numbers + 1);
    i += block_numbers;
  }
})();

/*

select COUNT(*) from nft_transfer nt




select COUNT(*) from block b where block_number >= 5000000 and block_number <= 7000000



UPDATE graphile_worker.jobs  set attempts = 0


UPDATE graphile_worker.jobs  set max_attempts = 1

*/
