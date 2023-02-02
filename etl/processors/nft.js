require("dotenv").config();

const ERC721ABI = require("../abis/erc721.json");
const axios = require("axios");
var mime = require("mime-types");
const { quickAddJob } = require("graphile-worker");

// const { Telegraf } = require("telegraf");
const Fetcher = require("@musedao/nft-fetch-metadata");
function NFT(address, tokenId) {
  this.address = ToolBox.ethereum.normalizeHash(address);
  this.tokenId = tokenId + "";
  this.contract = new ToolBox.ethereum.w3.eth.Contract(ERC721ABI, this.address);

  const rpc = process.env.PEPESEA_RPC;

  const infuraIPFS = "https://ipfs.infura.io:5001/api/v0/cat?arg=";

  let options = [, , infuraIPFS, , rpc];

  this.metadataFetcher = new Fetcher(...options);
}

NFT.prototype.getCollection = function () {
  return new ToolBox.COLLECTION(this.address);
};

NFT.prototype.queueUpdate = async function (force = false) {
  let job = await quickAddJob(
    { pgPool: ToolBox.storage.pool },
    "nft_update",
    {
      address: this.address,
      tokenId: this.tokenId,
      force: force,
    },
    {
      jobKey: "nftupdate_" + this.address + "_" + this.tokenId,
      jobKeyMode: "preserve_run_at",
      maxAttempts: ToolBox.params.worker_update_max_retry,
      flags: ToolBox.workerFlags,
      priority: ToolBox.workerPriority,
    }
  );
};

// Internal function to get the URI of an NFT
NFT.prototype._getMetadataURIFromBase = async function (collection) {
  // changed to this to return token uri
  const { uri } = await this.metadataFetcher.fetchTokenURI(
    this.address,
    this.tokenId
  );

  return uri;
};

NFT.prototype.update = async function (force = false) {
  console.log("updating NFT ", this.address, this.tokenId);

  let collection = this.getCollection();
  collection = await collection.getFromStorage();
  let storage = await this.getFromStorage();
  try {
    const toDaysAgo = function (daysAgo) {
      let date = new Date().setDate(new Date().getDate() - daysAgo);
      return new Date(date).getTime();
    };

    if (
      storage != null &&
      storage.image != null &&
      !force &&
      new Date(storage.updated_at).getTime() > toDaysAgo(4)
    ) {
      process.env.LOGS &&
        console.log(
          "NFT already exists in storage",
          storage.name,
          storage.token_id
        );
      return;
    }

    /*
      
      ===== Metadata Type:
      0 EMPTY NOTHING
      1 Hosted API
      2 Onchain JSON UTF8
      3 Onchain JSON Base64
      4 OpenSea (Cause failure or no more api)
      5 IPFS
      6 Arweave
  
      ===== Image Type:
      0 EMPTY/NOTHING
      1 Hosted on serve
      2 On chain SVG Base64
      3 On chain SVG UTF8
      4 IPFS
      5 OpenSea
      6 Arweave
      666 it's video
      
    */

    // This is where we store the Metadata of the NFT to store in DB
    let item = null;

    try {
     // console.log(collection)
      let URI = await this._getMetadataURIFromBase(collection);
      console.log(URI)
      URI = URI.trim();
      process.env.LOGS && console.log("token URI", URI);

      if (URI != "") {
        item = await this.decodeAPI();

        if (URI.indexOf("ar://") !== -1) {
          item.metadatatype = 6;
          item.api = URI;
        } else if (URI.indexOf("ipfs") !== -1) {
          item.metadatatype = 5;
          item.api = URI;
        } else if (
          URI.startsWith("data") &&
          (URI.split(",")[0].toLowerCase().includes("json") ||
            URI.split(",")[0].toLowerCase().includes("text"))
        ) {
          // this is an on chain metadata
          if (
            URI.split(",")[0].toLowerCase().includes("utf8") ||
            URI.split(",")[0].toLowerCase().includes("plain")
          ) {
            // content is in utf8
            // item = JSON.parse(URI.slice(URI.split(",")[0].length + 1));
            item.original_image = item.imageURL;
            item.metadatatype = 2;
          } else if (URI.split(",")[0].toLowerCase().includes("base64")) {
            // let text = Buffer.from(
            //   URI.slice(URI.split(",")[0].length + 1),
            //   "base64"
            // ).toString("utf-8");
            // console.log("BASE64");
            // console.log(JSON.stringify(text));
            // item = JSON.parse(text);
            item.original_image = item.imageURL;
            item.metadatatype = 3;
          }
        } else if (
          URI.toLowerCase().startsWith("https://") ||
          URI.toLowerCase().startsWith("http://")
        ) {
          item.metadatatype = 1;
          item.api = URI;
        } else {
          // There is nothing we can do to get the api data
          throw `Error2 decoding ${URI}`;
        }

        // todo check this later
        // Some NFTs don't have image and only an animation
        if (item.original_image == null && item.animation_url != null) {
          item.original_image = item.animation_url;
        }

        // todo fix this, i set this before we update schema
        item.c = item.imageURL;
        // end

        //item.imagetype = await this._uploadImage(item.imageURL);
        item.imagetype = 1;

       // process.env.LOGS && console.log("image type", item.imagetype);



        if (item.imagetype == 2 || item.imagetype == 3) {
          //TODO we don't store this this? We dont store the data of image in DB if it's on chain SVG
          item.original_image = null;
        }
      } else {
        item = {};
        item.metadatatye = 0;
        item.imagetype = 0;
      }
    } catch (error) {
      console.error(error)
      // this means we couldn't even fetch the token uri
      if (error == "Error: Cannot fetch uri from contract") {
        item = {};
        item.metadatatye = 0;
        item.imagetype = 0;
      }
      
      // for now
      item = {};
      item.metadatatye = 0;
      item.imagetype = 0;

    }

    process.env.LOGS && console.log("image type", item.imagetype);

    let image = item.original_image;

    let attributes = null;

    attributes = item.attributes;
    if (item.attributes == null && item.properties != null) {
      // This is handling "the sandbox" bad metadata format
      attributes = item.properties;
    } else if (item.attributes == null && item.traits != null) {
      // Artblock attributes
      attributes = item.traits;
    }
    attributes = await this.prepareAttributes(attributes);

    if (storage != null) {
      console.log("update", "nft",
        {
          address: this.address,
          token_id: this.tokenId,
        },
        {
          name: item.name,
          description: item.description,
          image: image || item.imageURL || item.metadata?.animation_url,
          original_image: item.imageURL || item.metadata?.animation_url,
          original_animation: item.metadata?.animation_url,
          external_url: item.tokenURL,
          metadata_type: item.metadatatype,
          image_type: item.imagetype,
          updated_at: ToolBox.storage.knex.fn.now(),
          attributes: attributes,
        })
      await ToolBox.storage.update(
        "nft",
        {
          address: this.address,
          token_id: this.tokenId,
        },
        {
          name: item.name,
          description: item.description,
          image: image || item.imageURL || item.metadata?.animation_url,
          original_image: item.imageURL || item.metadata?.animation_url,
          original_animation: item.metadata?.animation_url,
          external_url: item.tokenURL,
          metadata_type: item.metadatatype,
          image_type: item.imagetype,
          updated_at: ToolBox.storage.knex.fn.now(),
          attributes: attributes,
        }
      );
    } else {
      await ToolBox.storage.insert("nft", {
        name: item.name,
        description: item.description,
        token_id: this.tokenId,
        address: this.address,
        image: image || item.imageURL || item.metadata?.animation_url,
        original_image: item.imageURL || item.metadata?.animation_url,
        original_animation: item.metadata?.animation_url,
        external_url: item.tokenURL,
        metadata_type: item.metadatatype,
        image_type: item.imagetype,
        created_at: ToolBox.storage.knex.fn.now(),
        updated_at: ToolBox.storage.knex.fn.now(),
        attributes: attributes,
      });
    }

    process.env.LOGS &&
      console.log("Let's try to update collection image ", image, collection);
    if (image != null && collection.defaultImage == null) {
      // Here we set a default image for the collection
      ToolBox.storage.update(
        "collection",
        {
          address: this.address,
          default_image: null,
        },
        {
          default_image: image,
        }
      );
    }
  } catch (error) {
    process.env.LOGS && console.log(error);
    process.env.LOGS && console.log("IMPOSSIBLE TO GET ANY DATA");
    // If everything fails we still insert the NFT
    if (storage == null) {
      await ToolBox.storage.insert("nft", {
        token_id: this.tokenId,
        address: this.address,
      });
    }

    throw `Impossible to index  ${this.address} ${this.tokenId}`;
  }

  console.log("Done updating NFT ", this.address, this.tokenId);
};

NFT.prototype.getFromStorage = async function () {
  return await ToolBox.storage.findOne("nft", {
    address: this.address,
    token_id: this.tokenId,
  });
};

NFT.prototype.prepareAttributes = async function (attributes) {
  process.env.LOGS && console.log(attributes);
  if (attributes == null || !Array.isArray(attributes)) {
    return null;
  }
  let map = {};
  for (const attribute of attributes) {
    if (attribute.value != null && attribute.trait_type != null) {
      if (typeof attribute.value === "string") {
        map[attribute.trait_type] = attribute.value.replaceAll('"', "'");
      } else {
        map[attribute.trait_type] = attribute.value;
      }
    }
  }
  return await ToolBox.storage.hstoreStringify(map);
};

NFT.prototype.decodeOpenSea = async function () {
  let osResult = await axios.get(
    "https://api.opensea.io/api/v1/asset/" +
    this.address +
    "/" +
    this.tokenId +
    "/"
  );
  process.env.LOGS &&
    "https://api.opensea.io/api/v1/asset/" +
    this.address +
    "/" +
    this.tokenId +
    "/";
  osResult = osResult.data;
  // console.log(osResult)
  return {
    name: osResult.name,
    description: osResult.description,
    attributes: osResult.traits,
    original_image: osResult.image_url,
    animation: osResult.animation_url,
    original_animation: osResult.animation_original_url,
  };
};

NFT.prototype.decodeAPI = async function () {
  process.env.LOGS && console.log("Decoding api");

  const item = await this.metadataFetcher.fetchMetadata(
    this.address,
    this.tokenId,
    {
      method: "post",
      auth: process.env.INFURA_IPFS,
      // responseType: "arraybuffer",
      // responseEncoding: "binary",
    }
  );

  process.env.LOGS && console.log("nft metadata", item);

  return item;
};

// This functions tries to egt type of image based on metadata and upload it to storage/bucket
// Really good ressource for On chain NFT type of data https://blog.simondlr.com/posts/flavours-of-on-chain-svg-nfts-on-ethereum

// TODO simplify this?
NFT.prototype._uploadImage = async function (URL) {
  let imagetype;

  const name = `${process.env.CHAIN != "ethereum" ? `${process.env.CHAIN}/` : ""
    }${this.address}/${this.tokenId}`;

  try {
    process.env.LOGS && console.log("IMAGE URI", URL);

    if (URL == null || URL == "") {
      imagetype = 0;
    } else if (URL.startsWith("ar://")) {
      const upload = await this.uploadImageURL(
        URL.replace("ar://", "https://arweave.net/")
      );

      if (upload.type == 666) {
        imagetype = 666;
      } else {
        imagetype = 6;
      }
    }
    // check all ipfs
    else if (URL.indexOf("ipfs") !== -1) {
      const upload = await this.uploadImageURL(URL);

      if (upload.type == 666) {
        imagetype = 666;
      } else {
        imagetype = 4;
      }
    } else if (URL.toLowerCase().startsWith("data")) {
      let starter = URL.toLowerCase().split(",")[0];
      if (starter.includes("base64")) {
        // base 64 encoded on chain nft
        imagetype = 2;
        let text = Buffer.from(
          URL.slice(starter.length + 1),
          "base64"
        ).toString("utf-8");
      //  await ToolBox.bucket.uploadSVGFromString(text, name);
      } else {
        // This is UTF8
        imagetype = 3;
    /*    await ToolBox.bucket.uploadSVGFromString(
          URL.slice(starter.length + 1),
          name
        ); */
      }
    } else if (
      URL.startsWith("<svg") ||
      URL.startsWith("<?xml") ||
      URL.startsWith("<xml")
    ) {
      // Squiggly && neolastics style
      imagetype = 3;
     // await ToolBox.bucket.uploadSVGFromString(URL, name);
    } else if (URL.endsWith(".svg")) {
      imagetype = 1;

      await this.uploadImageURL(URL);
    } else if (
      URL.toLowerCase().startsWith("https://") ||
      URL.toLowerCase().startsWith("http://")
    ) {
      const upload = await this.uploadImageURL(URL);

      if (upload.type == 666) {
        imagetype = 666;
      } else {
        imagetype = 1;
      }
    }
  } catch (e) {
    process.env.LOGS && console.log(e);
    imagetype = 0;

    process.env.LOGS && console.log("couldn't upload image");
  }
  return imagetype;
};

NFT.prototype.uploadImageURL = async function (URL) {
  // here we set the name where to upload to s3 (for if we have other chains)

  const name = `${process.env.CHAIN != "ethereum" ? `${process.env.CHAIN}/` : ""
    }${this.address}/${this.tokenId}`;

  console.log("name", name);
/*
  let result = await ToolBox.bucket.uploadFromURL(
    URL,
    name,
    // this.address + "/" + this.tokenId,
    this.address,
    ToolBox.params.requestTimeout,
    this.tokenId
  );
    process.env.LOGS && console.log("Image uploaded", result);
  */
  return result;
};

NFT.prototype.getUrlExtension = async function (url) {
  return url.split(/[#?]/)[0].split(".").pop().trim();
};

module.exports = NFT;
