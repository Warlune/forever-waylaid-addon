import { readFileSync, writeFileSync } from 'node:fs';
import { lua } from './build-catalog.mjs';
const data = JSON.parse(readFileSync(new URL('../data/recipes.json', import.meta.url)));
if (Object.keys(data.recipes).length !== 208) throw new Error('Incomplete recipe catalogue');
writeFileSync(new URL('../WaylaidForever/Recipes.lua', import.meta.url),
  '-- Generated from data/recipes.json, imported from Waylaid Forever Ledger.\nlocal _, F = ...\nF.recipeData = ' + lua(data) + '\n' +
  'for id in pairs(F.recipeData.metadata.leaves) do F.catalogIDs[tonumber(id)] = true end\n' +
  'for id in pairs(F.recipeData.recipes) do F.catalogIDs[tonumber(id)] = true end\n');
console.log('Generated 208 recipes and ' + Object.keys(data.metadata.leaves).length + ' raw materials.');
