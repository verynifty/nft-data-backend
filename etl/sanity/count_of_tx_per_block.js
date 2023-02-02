require("dotenv").config();

const ToolBox = new (require("../utils/toolbox"))();

select count(*) from block


select MIN(blocknumber), MAX(blocknumber) from block



SELECT
    generate_series
FROM
    generate_series(13751131, 13755862)
WHERE
    SUM(erc721_transfers) + SUM(erc1155_transfers) = (select number, COUNT(*) from nft_transfer group by blocknumber);
   	
   