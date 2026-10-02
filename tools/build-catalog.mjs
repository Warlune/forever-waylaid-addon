import { readFileSync, writeFileSync } from 'node:fs';
const root = new URL('../', import.meta.url);
export function lua(value) {
  if (value == null) return 'nil';
  if (typeof value === 'number' || typeof value === 'boolean') return String(value);
  if (typeof value === 'string') return '"' + value.replace(/\\/g,'\\\\').replace(/"/g,'\\"').replace(/\n/g,'\\n').replace(/\r/g,'\\r') + '"';
  if (Array.isArray(value)) return '{' + value.map(lua).join(',') + '}';
  return '{' + Object.entries(value).map(([key,v]) => '[' + lua(key) + ']=' + lua(v)).join(',') + '}';
}
const catalog = JSON.parse(readFileSync(new URL('data/catalog.json', root)));
if (catalog.crates.length !== 30 || catalog.writs.length !== 150) throw new Error('Incomplete catalogue');
writeFileSync(new URL('WaylaidForever/Catalog.lua', root), `-- Generated from data/catalog.json. Sources are recorded in metadata.\nlocal _, F = ...\nF.catalog = ${lua(catalog)}\nF.cratesByID, F.writsByID, F.writsByQuest, F.catalogIDs = {}, {}, {}, {}\nfor _, crate in ipairs(F.catalog.crates) do\n F.cratesByID[crate.id] = crate; F.catalogIDs[crate.id] = true\n for _, option in ipairs(crate.options) do F.catalogIDs[option.itemId] = true end\nend\nfor _, writ in ipairs(F.catalog.writs) do\n F.writsByID[writ.id] = writ; F.writsByQuest[writ.questId] = writ\n F.catalogIDs[writ.id] = true; F.catalogIDs[writ.targetId] = true\nend\n`);
console.log('Generated 30 crates and 150 writs.');
