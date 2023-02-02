

const ToolBox = new (require("../utils/toolbox"))();
const NFT = require("../processors/nft");


(async () => {

    function findRanges(numbers) {
        return [...numbers].sort((a, b) => a - b).reduce((acc, x, i) => {
            if (i === 0) {
                acc.ranges.push(x);
                acc.rangeStart = x;
            } else {
                if (x === acc.last + 1) {
                    acc.ranges[acc.ranges.length - 1] = { start: acc.rangeStart, end: x };
                } else {
                    acc.ranges.push({ start: x, end: x });
                    acc.rangeStart = x;
                }
            }
            acc.last = x;
            return acc;
        }, { ranges: [] }).ranges;
    }
    

    try {
        
        let latest_block_chain = await ToolBox.ethereum.getLatestBlock()
        let latest_block_db = ((await ToolBox.storage.executeAsync(`select max(block_number) from nft_transfer`))[0].max)
        if (latest_block_chain + 20 >= latest_block_db && latest_block_chain - 20 <= latest_block_db) {
            console.log("✅ DB is synced live")
        } else {
            console.log("⭕ DB is synced live")

        }
        let pending_jobs = await ToolBox.storage.executeAsync(`select COUNT(*) from graphile_worker.jobs where attempts = 0`)
        if (pending_jobs[0].count < 100) {
            console.log("✅ Workers catched up")
        } else {
            console.log("⭕ Workers are left behing ", pending_jobs[0].count)
        }
        console.log("=> Cleaning failed jobs")
        await ToolBox.storage.executeAsync(`delete from graphile_worker.jobs where attempts = 1`)
        console.log("✅ Cleaned")

        let missingPastBlocks = (await ToolBox.storage.executeAsync(`select
        * 
      from
        (	
        select
          *
        from
          generate_series(${latest_block_chain - 500000}, ${latest_block_chain - 20}) as blocknumber
      where
      blocknumber not in (
        select
          block_number 
        from
          block
          )) as t `))
        if (missingPastBlocks.length == 0) {
            console.log("✅ No blocks missing")
        } else {
            console.log("⭕ some blocks missing ", missingPastBlocks.length)
            console.log("=> Adding missing jobs")
            let res = [];
            for (const b of missingPastBlocks) {
                res.push(b.blocknumber)
            }
            let jobsAdded = 0;
            let ranges = findRanges(res);
            console.log(findRanges(res))
            console.log("Found ", missingPastBlocks.length, " blocks")
            for (const r of ranges) {
                console.log("Adding job", r.start - 2, r.end + 2, r.end + 2 - (r.start - 2))
                //await ToolBox.queueBlockRange(r.start - 2, r.end + 2, r.end + 2 - (r.start - 2))
                jobsAdded++;
            }
            console.log("added jobs", jobsAdded)
        }
    } catch (error) {
        console.log(error)
    }



})()