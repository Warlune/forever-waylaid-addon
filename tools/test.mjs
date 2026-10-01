import { spawnSync } from 'node:child_process';
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const result = spawnSync(process.execPath, [require.resolve('fengari-node-cli/src/lua-cli.js'), 'tests/addon.lua'], {encoding: 'utf8', maxBuffer: 4 * 1024 * 1024});
process.stdout.write(result.stdout || '');
process.stderr.write(result.stderr || '');
if (result.error) console.error(result.error);
// Fengari can return status 0 after a Lua assertion. Require the final sentinel too.
if (result.error || result.status !== 0 || result.stderr || !result.stdout?.trimEnd().endsWith('ALL ADDON TESTS PASSED')) process.exit(1);
