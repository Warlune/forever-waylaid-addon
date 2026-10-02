import {readFileSync,writeFileSync,mkdirSync,copyFileSync,existsSync,readdirSync} from 'node:fs';
import {resolve,relative,isAbsolute,sep,dirname} from 'node:path';
import {root,runtimeFiles} from './package-addon.mjs';
const stage=resolve(root,'release',process.argv[2] || 'stage-development');
const rel=relative(resolve(root,'release'),stage);
if (!rel || isAbsolute(rel) || rel==='..' || rel.startsWith('..'+sep)) throw new Error('Stage must be inside release/');
if (existsSync(stage) && readdirSync(stage).length) throw new Error('Use an empty stage');
const folder=resolve(stage,'WaylaidForeverDev');
for (const file of runtimeFiles('WaylaidForever')) {
  const source=resolve(root,'WaylaidForever',file);
  const target=resolve(folder,file==='WaylaidForever.toc' ? 'WaylaidForeverDev.toc' : file);
  mkdirSync(dirname(target),{recursive:true});
  if (!/\.(lua|toc)$/.test(file)) {copyFileSync(source,target);continue;}
  let text=readFileSync(source,'utf8')
    .replaceAll('WaylaidForever','WaylaidForeverDev')
    .replaceAll('ForeverWaylaid','ForeverWaylaidDev')
    .replaceAll('WAYLAIDFOREVER','WAYLAIDFOREVERDEV')
    .replace(/\/wf\b/g,'/wfdev').replace(/\/fwl\b/g,'/fwldev').replace(/\/waylaid\b/g,'/waylaiddev');
  if (file==='Core.lua') text=text.replace(/(F\.version = "[^"]+")/,'$1\nF.isDevelopment = true');
  if (file==='UI.lua') text=text.replace('"WAYLAID FOREVER"','"WAYLAID FOREVER • DEVELOPMENT"');
  if (file.endsWith('.toc')) text=text.replace(/^## Title: .*$/m,'## Title: Waylaid Forever (Development)')
    .replace(/^## OptionalDeps: .*$/m,'## OptionalDeps: Auctionator, Auc-Advanced, TomTom');
  writeFileSync(target,text);
}
copyFileSync(resolve(root,'LICENSE'),resolve(folder,'LICENSE'));
writeFileSync(resolve(folder,'DEVELOPMENT.txt'),
  'Local development build. Toggle Waylaid Forever (Development) in the AddOns list.\n'+
  'Commands: /wfdev, /waylaiddev, /fwldev.\n'+
  'Uses WaylaidForeverDevDB and WaylaidForeverDevCharDB. Does not import or edit production saves.\n'+
  'The installer may seed these once from a COPY of your existing save; subsequent updates preserve them.\n'+
  'Disable this addon when testing the CurseForge version. Development builds do not advertise update versions.\n');
console.log(folder);
