#!/usr/bin/env node
// Demoni CLI entrypoint
// Loads the compiled CLI module.
import('../dist/cli.js').catch((err) => {
  console.error('[demoni] Failed to start:', err.message);
  process.exit(1);
});
