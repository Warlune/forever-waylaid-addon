import { readdirSync, readFileSync } from 'node:fs';
import { parse } from 'luaparse';
const root = new URL('../ForeverWaylaid/', import.meta.url);
for (const file of readdirSync(root).filter(f => f.endsWith('.lua'))) {
  parse(readFileSync(new URL(file, root), 'utf8'), { luaVersion: '5.1' });
  console.log(`Lua 5.1 syntax OK: ${file}`);
}
