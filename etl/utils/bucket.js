require("dotenv").config();

const AWS = require("aws-sdk");
const axios = require("axios");

const sharp = require("sharp");
// const gifResize = require("@gumlet/gif-resize");
const pixelmatch = require("pixelmatch");

const ffmpeg = require("ffmpeg-static");
const genThumbnail = require("simple-thumbnail");
const { Readable } = require("stream");
var streamBuffers = require("stream-buffers");
const e = require("cors");

const Fetcher = require("@musedao/nft-fetch-metadata");

function Bucket(connectInfos) {
  this.connectInfos = connectInfos;
  this.s3 = new AWS.S3({
    endpoint: connectInfos.endpoint,
    accessKeyId: connectInfos.accessKeyId,
    secretAccessKey: connectInfos.secretAccessKey,
    params: { Bucket: connectInfos.bucket_name },
    s3ForcePathStyle: true,
  });
  // console.log(this.s3)
  this.s3.headBucket({}, function (err, data) {
    // console.log(err)
    if (!err && data) {
    } else {
      this.bucket.createBucket({ ACL: "public-read" });
    }
  });

  // new
  // const rpc = `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY}`;
  const rpc = process.env.NFT20_INFURA;

  const infuraIPFS = "https://ipfs.infura.io:5001/api/v0/cat?arg=";

  let options = [, , infuraIPFS, , rpc];
  this.metadataFetcher = new Fetcher(...options);
}

Bucket.prototype.uploadFromURL = async function (
  url,
  name,
  address,
  timeout = 1000,
  id
) {
  console.log(url);
  let img = await this.metadataFetcher.fetchURI(url, {
    responseType: "arraybuffer",
    responseEncoding: "binary",
    method: "post",
    auth: process.env.INFURA_IPFS,
  });

  let shouldUpdateImage = true;

  process.env.LOGS && console.log("name", name);

  // implement the validate status later into the package
  // let oldImage = await this.metadataFetcher.fetchURI(
  //   `https://media.niftyapi.xyz/${name}`,
  //   {
  //     responseType: "arraybuffer",
  //     responseEncoding: "binary",
  //     validateStatus: () => true,
  //   }
  // );

  let { data: oldImage } = await axios(`https://media.niftyapi.xyz/${name}`, {
    responseType: "arraybuffer",
    responseEncoding: "binary",
    validateStatus: () => true,
  });

  process.env.LOGS && console.log("oldImage", oldImage);

  if (oldImage) {
    shouldUpdateImage = !Buffer.compare(img, oldImage) == 0;

    process.env.LOGS && console.log("Should update img?", shouldUpdateImage);
  }

  let imageType = inferImageType(img);

  if (!shouldUpdateImage) {
    img = oldImage;

    process.env.LOGS &&
      console.log(
        "skipping optimization of image as it is same as we already have"
      );
  } else {
    // should update image so we do the processing
    process.env.LOGS && console.log("image type on bucket.js", imageType);
    if (imageType == "video/webm" || imageType == "video/mp4") {
      // Get thumbnail of video
      process.env.LOGS && console.log("This is a video");
      // var myWritableStreamBuffer = new streamBuffers.WritableStreamBuffer();
      // const stream = Readable.from(img);
      // await genThumbnail(stream, myWritableStreamBuffer, "800x?", {
      //   path: ffmpeg,
      // });
      // process.env.LOGS && console.log("generated thumbnail");
      // img = myWritableStreamBuffer.getContents();

      return { status: true, type: 666 };
    } else if (imageType == undefined) {
      //here if undefined means svg most likely.

      process.env.LOGS && console.log("likely an SVG!");
      img = img;
    } else if (imageType == "image/gif") {
      // console.log("Its a gif!");
      // img = await gifResize({
      //   width: 250,
      //   optimizationLevel: 2,
      // })(img);
      img = img;
    } else {
      // if we want to manipulate svg later
    }
  }

  const imgSize = img.toString().length / 1024;

  // If img sze > 6mb amazon won't show it so we need to make sure we resize before we get here

  const content_type =
    imageType != undefined
      ? imageType
      : await this.metadataFetcher.fetchMimeType(url);

  if (imgSize < 6000) {
    const params = {
      ContentType: content_type,

      //   ContentLength: response.data.length.toString(), //keep this commented for sharp to work
      Bucket: this.connectInfos.bucket_name,
      Body: img,
      Key: name,
      ACL: "public-read",
    };

    await this.s3.putObject(params).promise();
  } else {
    // for now lets still store
    const params = {
      ContentType: content_type,
      //   ContentLength: response.data.length.toString(), //keep this commented for sharp to work
      Bucket: this.connectInfos.bucket_name,
      Body: img,
      Key: name,
      ACL: "public-read",
    };

    await this.s3.putObject(params).promise();

    // throw "Image Too Big";
  }

  // console.log("about to return ", imageType);
  // return imageType;
  return true;
};

Bucket.prototype.uploadSVGFromString = async function (content, name) {
  const params = {
    ContentType: "image/svg+xml",
    Bucket: this.connectInfos.bucket_name,
    Body: content,
    Key: name,
    ACL: "public-read",
  };
  await this.s3.putObject(params).promise();
  return true;
};

function inferImageType(imageBuffer) {
  const fileSig = imageBuffer.toString("hex").substring(0, 8).toUpperCase();
  process.env.LOGS && console.log("With file sig", fileSig);
  switch (fileSig) {
    case "89504E47":
      return "image/png";
    case "FFD8FFDB":
      return "image/jpeg";
    case "FFD8FFE0":
      return "image/jpeg";
    case "FFD8FFEE":
      return "image/jpeg";
    case "FFD8FFE1":
      return "image/jpeg";
    case "52494646":
      return "image/webp";
    case "49492A00":
      return "image/tiff";
    case "4D4D002A":
      return "image/tiff";
    case "47494638":
      return "image/gif";
    case "1A45DFA3":
      return "video/webm";
    case "66747970":
      return "video/mp4";
    case "00000018":
      return "video/mp4";
    default:
      undefined;
    // console.log(
    //   "The file does not have an extension and the file type could not be inferred"
    // );
  }
}

module.exports = Bucket;
