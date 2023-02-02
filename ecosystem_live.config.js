module.exports = {
  apps: [
    {
      name: "live",
      script: "./etl/live.js",
      cron_restart: "*/20 * * * *",
      autorestart: true,
    },
    {
      name: "refreshHourly",
      script: "./etl/refreshView.js",
      cron_restart: "0 * * * *",
      autorestart: true,
    },
    {
      name: "workers",
      script: "./worker.js",
      cron_restart: "*/15 * * * *",
      autorestart: true,
      instances: -1
    },
  ],
};
