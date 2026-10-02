import { runtimeFiles, addons, version } from './package-addon.mjs';
import { readdirSync, readFileSync } from 'node:fs';
import { parse } from 'luaparse';
for (const addon of addons) {
const root = new URL(`../${addon}/`, import.meta.url);
for (const file of readdirSync(root).filter(f => f.endsWith('.lua'))) {
  parse(readFileSync(new URL(file, root), 'utf8'), { luaVersion: '5.1' });
  console.log(`Lua 5.1 syntax OK: ${file}`);
}
// The client consumes the TGA exports, never the non-power-of-two PNG sources.
const coreVersion = readFileSync(new URL('Core.lua', root), 'utf8').match(/F\.version\s*=\s*"([^"]+)"/)[1];
if (coreVersion !== version(addon)) throw new Error(`${addon} core and TOC versions disagree`);
for (const faction of addon === 'ForeverCompanions' ? ['Alliance', 'Horde'] : []) {
  const name = `PetScenes${faction}.tga`;
  const data = readFileSync(new URL(`Art/${name}`, root));
  const width = data.readUInt16LE(12), height = data.readUInt16LE(14);
  const powerOfTwo = value => value > 0 && (value & (value - 1)) === 0;
  if (data[2] !== 2 || data[16] !== 32 || (data[17] & 15) !== 8 ||
      !powerOfTwo(width) || !powerOfTwo(height) || data.length < 18 + width * height * 4) {
    throw new Error(`${name} must be a complete, uncompressed RGBA power-of-two texture`);
  }
  console.log(`Scene texture OK: ${name} (${width}x${height} RGBA)`);
}

const shipped = runtimeFiles(addon);
for (const file of shipped) readFileSync(new URL(file, root));
if (shipped.some(file => /Roads?Data|Roads\.lua|\.png$|Scribes8|Scribe.*16/.test(file))) throw new Error('Unused road data or source art in runtime package');
console.log(`Runtime package OK: ${shipped.length} files, no archived road engine or source PNGs`);
if (addon === 'ForeverCompanions') {
  for (const file of shipped.filter(file => file.endsWith('.lua'))) {
    const text = readFileSync(new URL(file, root), 'utf8');
    if (text.includes('AddOns\\\\ForeverWaylaid')) throw new Error(`Companion art still loads from Waylaid: ${file}`);
  }
}
if (addon === 'ForeverWaylaid' && shipped.some(file => /Pet|Companion/.test(file))) throw new Error('Pet runtime must not ship with Waylaid');
}
