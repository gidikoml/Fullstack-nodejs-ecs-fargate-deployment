import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

const backendDir = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const port = process.env.APP_PORT || "8080";
const baseUrl = `http://127.0.0.1:${port}`;
const startupTimeoutMs = 15000;

const child = spawn(process.execPath, ["index.js"], {
  cwd: backendDir,
  env: {
    ...process.env,
    APP_PORT: port,
    DB_HOST: process.env.DB_HOST || "127.0.0.1",
    DB_PORT: process.env.DB_PORT || "3306",
    DB_USERNAME: process.env.DB_USERNAME || "root",
    DB_PASSWORD: process.env.DB_PASSWORD || "password",
    DB_NAME: process.env.DB_NAME || "test",
  },
  stdio: ["ignore", "pipe", "pipe"],
});

let output = "";

child.stdout.on("data", (chunk) => {
  output += chunk.toString();
});

child.stderr.on("data", (chunk) => {
  output += chunk.toString();
});

const cleanup = () => {
  if (!child.killed) {
    child.kill("SIGTERM");
  }
};

const fail = (message) => {
  cleanup();
  console.error(message);
  if (output.trim()) {
    console.error(output.trim());
  }
  process.exit(1);
};

process.on("exit", cleanup);
process.on("SIGINT", () => fail("Smoke test interrupted."));
process.on("SIGTERM", () => fail("Smoke test terminated."));

child.on("exit", (code) => {
  if (code !== null && code !== 0) {
    fail(`Backend exited before smoke test completed with code ${code}.`);
  }
});

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

const waitForServer = async () => {
  const startedAt = Date.now();

  while (Date.now() - startedAt < startupTimeoutMs) {
    try {
      const response = await fetch(`${baseUrl}/`);
      const payload = await response.json();

      if (response.ok && payload === "hello") {
        console.log(`Smoke test passed against ${baseUrl}/`);
        cleanup();
        process.exit(0);
      }
    } catch {
      // Keep polling until the server is reachable or timeout is hit.
    }

    await sleep(500);
  }

  fail(`Backend did not become healthy within ${startupTimeoutMs}ms.`);
};

await waitForServer();
