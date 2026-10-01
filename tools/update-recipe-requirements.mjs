// Optional maintainer import; never runs in game or during normal builds.
// Only fill missing profession ranks from the recipe's Forever source page.
import { readFile, writeFile } from 'node:fs/promises';
const file = new URL('../data/recipes.json', import.meta.url);
const data = JSON.parse(await readFile(file, 'utf8'));
const pending = Object.values(data.recipes).flat().filter(recipe => !recipe.skill);
let next = 0, updated = 0;
const failures = [];
async function worker() {
  while (next < pending.length) {
    const recipe = pending[next++];
    try {
      const response = await fetch(recipe.sourceUrl, { signal: AbortSignal.timeout(20000) });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const html = await response.text();
      const profession = recipe.profession.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      // Some quest recipes and new dyes omit the infobox line, but publish
      // the learned-at rank in their own spell record. Match the exact ID.
      const match = html.match(new RegExp(`Requires ${profession} \\((\\d+)\\)`)) ||
        html.match(new RegExp(`"id":${recipe.spellId},"learnedat":(\\d+)`));
      const skill = Number(match?.[1]);
      if (!Number.isInteger(skill) || skill < 1 || skill > 300) throw new Error('No explicit profession rank');
      recipe.skill = skill;
      recipe.skillSource = recipe.sourceUrl;
      updated++;
    } catch (error) { failures.push(`${recipe.spellId}: ${error.message}`); }
    await new Promise(resolve => setTimeout(resolve, 250));
  }
}
await Promise.all([worker(), worker(), worker()]);
await writeFile(file, JSON.stringify(data, null, 2) + '\n');
console.log(`Imported ${updated}/${pending.length} missing skill requirements.`);
for (const failure of failures) console.log(failure);
