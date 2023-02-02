

const ToolBox = new (require("../utils/toolbox"))();
const NFT = require("../processors/nft");


const FIX_NFTS = false;

(async () => {

  console.log("➡️  Check number OF NFT inserted between transfers and nft table")
  let distinct_nft_in_transfer = (await ToolBox.storage.executeAsync(`select COUNT(distinct(nt.collection, nt.token_id)) from nft_transfer nt `))[0].count
  let distinct_nft_in_table = (await ToolBox.storage.executeAsync(`select COUNT(*) from nft`))[0].count
  let waiting_nft_update_jobs = (await ToolBox.storage.executeAsync(`SELECT count(*) AS "count"
  FROM "graphile_worker"."jobs"
  WHERE "graphile_worker"."jobs"."task_identifier" = 'nft_update'`))[0].count
  if (distinct_nft_in_table != distinct_nft_in_transfer) {
    console.log(`❌ Different count ${distinct_nft_in_transfer}, ${distinct_nft_in_table}, That's ${Math.abs(distinct_nft_in_table - distinct_nft_in_transfer)} NFTs`)
    console.log(`Hint: there is ${waiting_nft_update_jobs} nft_update jobs in queue`)
/*
    let missingNFTS = await ToolBox.storage.executeAsync(`select
    id
  from
    (
    select
      CONCAT(nt.collection, '_', nt.token_id) as id
    from
      nft_transfer nt
    group by
      nt.collection,
      nt.token_id) t
  where
    t.id not in (
    select
      concat(n.address, '_', n.token_id)
    from
      nft n
    group by
      n.address ,
      n.token_id 
  )`);
    console.log("🔎 Missing items:")
    for (const nft of missingNFTS) {
      console.log(nft.id)
      if (FIX_NFTS) {
        let n = new NFT(ToolBox, nft.id.split("_")[0], nft.id.split("_")[1])
        await n.update(true)
      }
    }
    */
  } else {
    console.log("✅ OK with:", distinct_nft_in_table)
  }
  console.log()
  console.log("➡️  Check if all transfers seen in blocks are in DB")
  let failed_blocks = await ToolBox.storage.executeAsync(`
select
*
from
(
select
  "public"."block"."block_number" as "block_number",
  count(*) as "count_of_transfers",
  (count(*) - (avg("public"."block"."erc1155_transfers") + avg("public"."block"."erc721_transfers"))) as "difference"
from
  "public"."block"
inner join "public"."nft_transfer" "Nft Transfer" on
  "public"."block"."block_number" = "Nft Transfer"."block_number"
group by
  "public"."block"."block_number") q
where
q.difference != 0
order by
q.difference desc
  `)

  if (failed_blocks != null && failed_blocks.length > 0) {
    console.log("❌ Some blocks are not properly indexed")
    console.log(failed_blocks)
  } else {
    console.log("✅ OK ")
  }
  console.log()
  try {


    console.log("➡️ Check if all transfers seen in blocks are in DB")
    let min = await ToolBox.storage.getMin("block", "block_number")
    let max = await ToolBox.storage.getMax("block", "block_number")
    console.log("Total blocks: ", max - min + 1, "From", min, max)
    let count = parseInt((await ToolBox.storage.executeAsync(`SELECT COUNT(*) FROM block`))[0].count)
    console.log(count)
    if (count != max - min + 1) {
      console.log("❌ Some blocks are not properly indexed: ", Math.abs(count - (max - min + 1)))

      let missing = await ToolBox.storage.executeAsync(`      select
      *
    from
      (
      select
        *
      from
        generate_series(${min}, ${max}) as n
    where
      n not in (
      select
        block_number 
      from
        block
        )) as t
   	`);
   
      console.log("🔎 Missing blocks:", missing)
      for (const block of missing) {
        console.log(block.n)
      }

    } else {
      console.log("✅ OK ")
    }
  } catch (error) {

  }



})()