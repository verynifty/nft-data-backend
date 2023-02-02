


const ToolBox = new (require("../utils/toolbox"))();
const NFT = require("../processors/nft");
const Fetcher = require("@musedao/nft-fetch-metadata");

const axios = require("axios");



(async () => {

    /*
    try {


        let result = await axios
            .get('https://api.opensea.io/api/v1/asset/0xb47e3cd837ddf8e4c57f05d70ab865de6e193bbb/1',
                {
                    headers: {
                        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.109 Safari/537.36',
                        'referer': 'https://www.gem.xyz/',
                        'origin': 'https://www.gem.xyz',
                        "accept-language": "en-US;q=0.8,en;q=0.7",
                        "sec-ch-ua": '" Not A;Brand";v="99", "Chromium";v="98", "Google Chrome";v="98"',
                        "sec-ch-ua-mobile": "?0",
                        "sec-ch-ua-platform": "macOS",
                        "sec-fetch-dest": "empty",
                        "sec-fetch-mode": "cors",
                        "sec-fetch-site": "cross-site",
                    }
                })

        console.log(result)
    } catch (error) {
        console.log(error)
    }
    return;
    */
    const rpc = process.env.NFT20_INFURA;

    let options = [, , , , rpc];

    let metadataFetcher = new Fetcher(...options);


    try {

        let collections = await ToolBox.storage.executeAsync(`
        select
address, name,symbol, supply
from
nft_collection_stats ncs
order by
transfers_total desc
limit 300 OFFSET 5
        `)
        for (const collection of collections) {
            console.log("working on:", collection);
            let count_total = parseInt((await ToolBox.storage.executeAsync(`
            select count(*) from nft where address = '${collection.address}'
            `))[0].count)
            let count_missing = parseInt((await ToolBox.storage.executeAsync(`
            select count(*) from nft where address = '${collection.address}' AND image IS null
            `))[0].count)
            let metadata_types_count = parseInt((await ToolBox.storage.executeAsync(`
            select count(*) from nft where address = '${collection.address}' AND metadata_type IS NOT NULL AND metadata_type <> 4 AND metadata_type <> 0
            `))[0].count)
            let image_types_count = parseInt((await ToolBox.storage.executeAsync(`
            select count(*) from nft where address = '${collection.address}' AND image_type IS NOT NULL AND image_type <> 5 AND image_type <> 0 
            `))[0].count)
            let nfts = await ToolBox.storage.executeAsync(`
            select token_id from nft where  address = '${collection.address}' order by random() limit 5 ;
            `)
            let success = 0
            for (const nft of nfts) {

                console.log(nft.token_id)
                try {
                    let f = await metadataFetcher.fetchMetadata(collection.address, nft.token_id)
                    success++
                    console.log(f)
                } catch (error) {
                    console.error(error)
                    break;
                }

            }
            console.log("Missing", count_missing, "/", count_total, "   types && images ", metadata_types_count, "/", image_types_count);
            if (success >= 5) {
                console.log("All images are accessible")
                console.log("All images are accessible")
                console.log("All images are accessible")
                /*
                let launch = await ToolBox.storage.executeAsync(`
                select
    graphile_worker.add_job(
        'nft_update',
    json_build_object(
          'address', address,
          'tokenId', token_id::text,
          'force', true
        ),
    job_key := CONCAT('nftupdate_', address, '_', token_id),
    job_key_mode := 'preserve_run_at',
    max_attempts := 2,
    priority := 90
      )
from
    (
    select
        *
    from
        nft
    where
        image is null and address = '${collection.address}' ) u
                `)
                console.log(launch)
                //return;
                */
            }

        }

    } catch (error) {
        console.log(error)
    }



})()


// Maneki rugged 		DELETE from graphile_worker.jobs j where priority = 90



