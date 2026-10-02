// Parse SavedVariables as data; never execute a user's Lua file.
import fs from 'node:fs';
import {parse} from 'luaparse';
const file=process.argv[2];
if (!file) throw new Error('Usage: node tools/read-telemetry.mjs <WaylaidForever.lua SavedVariables path>');
const ast=parse(fs.readFileSync(file,'utf8'),{luaVersion:'5.1'});
function literal(node) {
  if (node?.type==='NumericLiteral') return node.value;
  if (node?.type==='StringLiteral' && /^"[\w|:., -]*"$/.test(node.raw)) return node.raw.slice(1,-1);
}
function field(node,name) {
  return node?.fields?.find(f=>literal(f.key)===name || (f.type==='TableKeyString' && f.key.name===name))?.value;
}
const assignment=ast.body.find(n=>n.type==='AssignmentStatement' && ['WaylaidForeverDB','WaylaidForeverDevDB'].includes(n.variables[0]?.name));
const inbox=field(assignment?.init[0],'telemetryInbox');
const reports=[];
for (const entry of inbox?.fields || []) {
  const body=literal(field(entry.value,'body'));
  if (typeof body!=='string' || body.length>220) continue;
  const p=body.split('|');
  if (p.length!==20 || p[0]!=='1') continue;
  reports.push({id:literal(field(entry.value,'id')),version:p[1],build:p[2],time:p[3],faction:p[4],
    classID:p[5],level:p[6],kind:({R:'route',E:'Lua error',B:'blocked action',S:'scan'})[p[7]] || 'unknown',
    mapID:p[8],x:Number(p[9])/100,y:Number(p[10])/100,writs:p[11],unresolved:p[12],
    knownFPs:p[13],scannedDepartures:p[14],routeSeconds:p[15],estimated:p[16]==='1',code:p[17],questIDs:p[18]});
}
console.log(JSON.stringify({reports:reports.length,notice:'Unverified, opt-in reports; no sender names retained.',items:reports},null,2));
