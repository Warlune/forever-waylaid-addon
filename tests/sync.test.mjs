import assert from 'node:assert/strict';
import {test} from 'node:test';
import {mkdtemp,writeFile,readFile,rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {parseTable,renderLua,sync} from '../tools/sync-prices.mjs';
const market='forever.pvp.horde.us';
const raw=(t=100,price=42)=>`AHL1|forever/pvp/horde/us|${t}|1\n123:50:${price}:20`;
test('strict market, timestamp, row count and copper parsing',()=>{
  assert.equal(parseTable(raw(),market,100).items[123][0],42);
  assert.throws(()=>parseTable(raw(), 'forever.pvp.alliance.us',100));
  assert.throws(()=>parseTable(raw(1000),market,100));
  assert.throws(()=>parseTable(raw().replace('|1\n','|2\n'),market,100));
  assert.throws(()=>parseTable(raw().replace(':42:',':-42:'),market,100));
  assert.throws(()=>renderLua({[market]:{time:100,items:{'1];error()': [42,1]}}}));
  assert.match(renderLua({[market]:parseTable(raw(),market,100)}),/\[123\]=\{42,20\}/);
});
test('failed and older downloads preserve snapshots; 30 minute cache prevents polling',async()=>{
  const directory=await mkdtemp(join(tmpdir(),'fwl-test-'));
  try {
    await writeFile(join(directory,'ForeverWaylaid.toc'),'test');
    let calls=0,fail=false,body=raw();
    const fetcher=async()=>{calls++;if(fail)throw Error('offline');return{ok:true,text:async()=>body,headers:new Headers({'cache-control':'public, max-age=3600'})};};
    await sync({directory,markets:[market],now:100,fetcher});
    const initial=await readFile(join(directory,'Prices.lua'),'utf8');
    await sync({directory,markets:[market],now:1900,fetcher});assert.equal(calls,1);
    fail=true;const failed=await sync({directory,markets:[market],now:3701,fetcher});
    assert.equal(failed.errors.length,1);assert.equal(await readFile(join(directory,'Prices.lua'),'utf8'),initial);
    fail=false;body=raw(50,1);await sync({directory,markets:[market],now:3702,fetcher});
    assert.equal(await readFile(join(directory,'Prices.lua'),'utf8'),initial);
    body=raw(8000,80);await sync({directory,markets:[market],now:8000,fetcher});
    assert.match(await readFile(join(directory,'Prices.lua'),'utf8'),/\[123\]=\{80,20\}/);
  } finally {
    assert.ok(resolve(directory).startsWith(resolve(tmpdir()) + '\\fwl-test-') || resolve(directory).startsWith(resolve(tmpdir()) + '/fwl-test-'));
    await rm(directory,{recursive:true});
  }
});
