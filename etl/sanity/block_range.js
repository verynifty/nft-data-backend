// identify task
// select task_identifier, priority , COUNT(*) from graphile_worker.jobs j where attempts = 0 group by j.task_identifier, priority
// select task_identifier, priority , attempts, COUNT(*) from graphile_worker.jobs j where attempts >= 0 group by j.task_identifier, priority, attempts order by 2
// update graphile_worker.jobs set attempts 0 where task_identifier = 'fill_block_range'

const ToolBox = new (require("../utils/toolbox"))();
const NFT = require("../processors/nft");

function findRanges(numbers) {
  return [...numbers]
    .sort((a, b) => a - b)
    .reduce(
      (acc, x, i) => {
        if (i === 0) {
          acc.ranges.push(x);
          acc.rangeStart = x;
        } else {
          if (x === acc.last + 1) {
            acc.ranges[acc.ranges.length - 1] = {
              start: acc.rangeStart,
              end: x,
            };
          } else {
            acc.ranges.push({ start: x, end: x });
            acc.rangeStart = x;
          }
        }
        acc.last = x;
        return acc;
      },
      { ranges: [] }
    ).ranges;
}

(async () => {
  // Where you need to start from
  let current_block = 0;
  // Until where
  let maxblock = 6975848;
  // How many blocks per workers (50 is pretty safe)
  let steps = 10000;

  while (true && current_block < maxblock) {
    let range_start = current_block;
    console.log(range_start);
    let range_end = current_block + steps;
    current_block += steps;
    let q = `
    select
      * 
    from
      (
      select
        *
      from
        generate_series(${range_start}, ${range_end}) as blocknumber
    where
    blocknumber not in (
      select
        block_number 
      from
        block
        )) as t
    `;
    try {
      let missingBlocks = await ToolBox.storage.executeAsync(q);
      let res = [];
      for (const b of missingBlocks) {
        res.push(b.blocknumber);
      }
      let jobsAdded = 0;
      let ranges = findRanges(res);
      if (missingBlocks.length > 0) {
        console.log(findRanges(res));
        console.log("Found ", missingBlocks.length, " blocks");
      }
      
      for (const r of ranges) {
        console.log(
          "Adding job",
          r.start - 2,
          r.end + 2,
          r.end + 2 - (r.start - 2)
        );
        await ToolBox.queueBlockRange(
          r.start - 2,
          r.end + 2,
          r.end + 2 - (r.start - 2)
        );
        jobsAdded++;
      }
      console.log("added jobs", jobsAdded);
      
    } catch (error) {
      console.log(error);
    }
  }
})();
