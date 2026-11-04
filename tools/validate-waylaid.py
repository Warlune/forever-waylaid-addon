"""Run Waylaid regression checks independently of Companions development."""
from pathlib import Path
import sys
sys.path.insert(0, 'release/validation-runtime')
from lupa.lua51 import LuaRuntime
fixture = Path('tests/addon.lua').read_text(encoding='utf-8').split('local companions=')[0]
checks = ['crate-details', 'flight-network', 'route-engine', 'connecting-flights',
          'memory-performance', 'mock-routes', 'route-coverage', 'telemetry',
          'update-check', 'upgrade-preservation', 'writ-availability']
LuaRuntime().execute(fixture + '\n' + '\n'.join(
    f"assert(loadfile('tests/{name}.lua'))(F)" for name in checks))
print('WAYLAID CHECKS PASSED')
