

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";




  (async () => {
    // block_range_8951998_8952098
    // block_range_8946998_8947098
    try {
      ToolBox = new (require("../utils/toolbox"))();

      console.log('start')
      let b = 5354178
      let i = 0
      while (i >= 0) {

        await ToolBox.processBlock(i, i + 35)
        i += 35
      }


    } catch (error) {
      console.log(error)
    }
  })();


