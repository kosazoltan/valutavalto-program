#!/usr/bin/env node
/**
 * KAN-15: tracked forrásban ne legyen Neon-jelszó literál.
 * A találat útvonalát kiírja, a titkot soha.
 */
const { execFileSync } = require("node:child_process");

let out = "";
try {
  out = execFileSync(
    "git",
    [
      "grep",
      "-l",
      "-E",
      "npg_[A-Za-z0-9]+",
      "--",
      ":!**/node_modules/**",
      ":!**/*.lock",
    ],
    { encoding: "utf8", maxBuffer: 4 * 1024 * 1024 },
  );
} catch (err) {
  if (err.status === 1) {
    console.log("KAN-15 titok-őr zöld: nincs Neon-jelszó literál a tracked fában");
    process.exit(0);
  }
  throw err;
}

const files = out.split("\n").filter(Boolean);
console.error("KAN-15 titok-őr PIROS:");
for (const f of files) console.error(" -", f);
process.exit(1);
