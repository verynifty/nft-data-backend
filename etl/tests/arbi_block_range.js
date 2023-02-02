

        ToolBox = new (require("../utils/toolbox"))();


(async () => {


    try {



        let startBlock = 5896650
        while (true) {
            startBlock -= 25
            console.log(startBlock, startBlock + 25)
            //await ToolBox.processBlock(startBlock, startBlock + 25);
        }


    } catch (error) {
        console.log(error)
    }


})()