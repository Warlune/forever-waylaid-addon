import { readdirSync, readFileSync } from 'node:fs';
import { parse } from 'luaparse';
const root = new URL('../ForeverWaylaid/', import.meta.url);
for (const file of readdirSync(root).filter(f => f.endsWith('.lua'))) {
  parse(readFileSync(new URL(file, root), 'utf8'), { luaVersion: '5.1' });
  console.log(`Lua 5.1 syntax OK: ${file}`);
}
// The client consumes the TGA exports, never the non-power-of-two PNG sources.
for (const faction of ['Alliance', 'Horde']) {
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
