

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



/*
6|w4  | gettling logs on range  8946598 8946623 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946598 8946610 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946598 8946604 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946598 8946601 0
6|w4  | gettling logs on range  8946601 8946604 0
3|w1  | Not supported yet 0xc011a72400e58ecd99ee497cf89e3775d4bd732f
6|w4  | gettling logs on range  8946604 8946610 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946604 8946607 0
6|w4  | gettling logs on range  8946607 8946610 0
6|w4  | gettling logs on range  8946610 8946623 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946610 8946616 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946610 8946613 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946610 8946611 0
6|w4  | gettling logs on range  8946611 8946613 0
6|w4  | gettling logs on range  8946613 8946616 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946613 8946614 0
6|w4  | gettling logs on range  8946614 8946616 0
6|w4  | gettling logs on range  8946616 8946623 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946616 8946619 0
6|w4  | gettling logs on range  8946619 8946623 0
6|w4  | Trying lower range
6|w4  | gettling logs on range  8946619 8946621 0
6|w4  | gettling logs on range  8946621 8946623 0

*/
