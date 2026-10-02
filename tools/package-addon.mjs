import { readFileSync, mkdirSync, copyFileSync, existsSync, statSync, readdirSync } from 'node:fs';
import { resolve, dirname, relative, sep, isAbsolute } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
export const root = fileURLToPath(new URL('../', import.meta.url));
export const addons = ['WaylaidForever', 'CompanionsForever'];
export const compatibility = {WaylaidForever: 'ForeverWaylaid', CompanionsForever: 'ForeverCompanions'};
export function version(addon) {
  if (!addons.includes(addon)) throw new Error('Unknown addon');
  return readFileSync(resolve(root, addon, `${addon}.toc`), 'utf8').match(/^## Version: (\d+\.\d+\.\d+)\r?$/m)[1];
}
export function runtimeFiles(addon = 'WaylaidForever') {
  if (!addons.includes(addon)) throw new Error('Unknown addon');
  const toc = readFileSync(resolve(root, addon, `${addon}.toc`), 'utf8');
  const code = toc.split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('#'));
  for (const file of code) {
    if (!/^[A-Za-z0-9_-]+\.lua$/.test(file)) throw new Error(`Invalid TOC file: ${file}`);
  }
  const art = addon === 'WaylaidForever' ? ['AuctionScribes'] :
    ['WaylaidPets', 'PetScenesAlliance', 'PetScenesHorde', ...Array.from({length: 6}, (_, i) => `PetRoster${i+1}`)];
  return [`${addon}.toc`, ...code, ...(addon === 'CompanionsForever' ? ['PET_GUIDE.md'] : []), ...art.map(name => `Art/${name}.tga`)];
}
export function buildPackage(stage) {
  stage = resolve(stage);
  const rel = relative(resolve(root, 'release'), stage);
  if (!rel || isAbsolute(rel) || rel === '..' || rel.startsWith(`..${sep}`) || resolve(root, 'release', rel) !== stage) throw new Error('Stage must be inside release/');
  if (existsSync(stage) && readdirSync(stage).length) throw new Error('Use an empty package stage');
  const result = [];
  for (const addon of addons) {
    let bytes = 0;
    const files = runtimeFiles(addon);
    for (const file of files) {
      const target = resolve(stage, addon, file);
      mkdirSync(dirname(target), {recursive: true});
      copyFileSync(resolve(root, addon, file), target);
      bytes += statSync(target).size;
    }
    for (const file of ['README.md', 'LICENSE', 'RELEASE_NOTES.md']) {
      const source = addon === 'CompanionsForever' && file !== 'LICENSE' ? resolve(root, addon, file) : resolve(root, file);
      const target = resolve(stage, addon, file);
      copyFileSync(source, target);bytes += statSync(target).size;
    }
    const legacy = compatibility[addon];
    for (const file of [`${legacy}.toc`, 'Compatibility.lua']) {
      const target = resolve(stage, legacy, file);
      mkdirSync(dirname(target), {recursive: true});
      copyFileSync(resolve(root, 'compatibility', legacy, file), target);
      bytes += statSync(target).size;
    }
    result.push({addon, compatibility: legacy, version: version(addon), files: files.length + 5, bytes, MiB: Number((bytes / 1048576).toFixed(2))});
  }
  return {stage, addons: result};
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  console.log(JSON.stringify(buildPackage(resolve(root, 'release', process.argv[2] || 'stage')), null, 2));
}
