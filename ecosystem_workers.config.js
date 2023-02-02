module.exports = {
  apps: [
    {
      name: "workers",
      script: "./worker.js",
      cron_restart: "*/15 * * * *",
      autorestart: true,
      instances: "max"
    },
  ],
};
