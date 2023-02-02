const { run, consoleLogFactory } = require("graphile-worker");
require("dotenv").config();
const pg = require("pg");

process.env["NODE_TLS_REJECT_UNAUTHORIZED"] = "0";

const WORKER_NUMBER = 15;

(async () => {
  const pool = new pg.Pool({
    user: process.env.NFT20_DB_USER,
    host: process.env.NFT20_DB_HOST,
    database: process.env.NFT20_DB_NAME,
    password: process.env.NFT20_DB_PASSWORD,
    port: process.env.NFT20_DB_PORT,
    max: WORKER_NUMBER + 1,
  });

  // Run a worker to execute jobs:
  const runner = await run({
    pgPool: pool,
    concurrency: WORKER_NUMBER,
    // Install signal handlers for graceful shutdown on SIGINT, SIGTERM, etc
    noHandleSignals: false,
    pollInterval: 1000,
    // you can set the taskList or taskDirectory but not both
    taskDirectory: `${__dirname}/tasks`,
    //noPreparedStatements: true,
  });

  // Catch connection issues
  pool.on("error", async function (error, client) {
    console.log("Client might have been lost", error);
    await runner.stop();
  });

  console.log("Runner stopped");
  // If the worker exits (whether through fatal error or otherwise), this
  // promise will resolve/reject:
  await runner.promise;
})();
