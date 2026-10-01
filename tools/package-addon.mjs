import { readFileSync, mkdirSync, copyFileSync, existsSync, statSync, readdirSync } from 'node:fs';
import { resolve, dirname, relative, sep, isAbsolute } from 'node:path';
import { fileURLToPath } from 'node:url';
import { pathToFileURL } from 'node:url';
export const root = fileURLToPath(new URL('../', import.meta.url));
const source = resolve(root, 'ForeverWaylaid');
export function runtimeFiles() {
  const toc = readFileSync(resolve(source, 'ForeverWaylaid.toc'), 'utf8');
  const code = toc.split(/\r?\n/).map(line => line.trim()).filter(line => line && !line.startsWith('#'));
  for (const file of code) {
    if (!/^[A-Za-z0-9_-]+\.lua$/.test(file)) throw new Error(`Invalid TOC file: ${file}`);
  }
  const art = ['AuctionScribes', 'WaylaidPets', 'PetScenesAlliance', 'PetScenesHorde',
    ...Array.from({length: 6}, (_, i) => `PetRoster${i+1}`)].map(name => `Art/${name}.tga`);
  return ['ForeverWaylaid.toc', ...code, 'PET_GUIDE.md', ...art];
}
export function buildPackage(stage) {
  stage = resolve(stage);
  const rel = relative(resolve(root, 'release'), stage);
  if (!rel || isAbsolute(rel) || rel === '..' || rel.startsWith(`..${sep}`) || resolve(root, 'release', rel) !== stage) throw new Error('Stage must be inside release/');
  if (existsSync(stage) && readdirSync(stage).length) throw new Error('Use an empty package stage');
  let bytes = 0;
  const files = runtimeFiles();
  for (const file of files) {
    const target = resolve(stage, 'ForeverWaylaid', file);
    mkdirSync(dirname(target), {recursive: true});
    copyFileSync(resolve(source, file), target);
    bytes += statSync(target).size;
  }
  for (const file of ['README.md','LICENSE','RELEASE_NOTES.md']) copyFileSync(resolve(root, file), resolve(stage, file));
  return {files: files.length, bytes, MiB: Number((bytes / 1048576).toFixed(2)), stage};
}
if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  console.log(JSON.stringify(buildPackage(resolve(root, 'release', process.argv[2] || 'stage')), null, 2));
}
