"""Validate the actual upload ZIP, including CurseForge's root-folder rule."""
import sys
import re
from pathlib import PurePosixPath
from zipfile import ZipFile

with ZipFile(sys.argv[1]) as archive:
    names = archive.namelist()
    assert names and len(names) == len(set(names)), "Empty archive or duplicate paths"
    roots = {name.split('/')[0] for name in names}
    primary = roots & {'WaylaidForever', 'CompanionsForever'}
    assert len(primary) == 1, "Expected exactly one primary addon"
    addon = next(iter(primary))
    legacy = {'WaylaidForever': 'ForeverWaylaid', 'CompanionsForever': 'ForeverCompanions'}[addon]
    assert roots == {addon, legacy}, "Unexpected or missing addon folder"
    if len(sys.argv) > 2:
        assert addon == sys.argv[2], "Wrong addon in this upload"
    for name in names:
        path = PurePosixPath(name)
        assert not path.is_absolute() and ".." not in path.parts and "\\" not in name, f"Unsafe path: {name}"
        assert len(path.parts) > 1 or name.endswith('/'), f"File outside addon folder: {name}"
    required = [addon + ".toc", "LICENSE", "README.md", "RELEASE_NOTES.md"]
    toc = archive.read(f"{addon}/{addon}.toc").decode("utf-8-sig")
    required += [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    for name in required:
        assert addon + "/" + name in names, f"Missing packaged file: {name}"
    legacy_files = {name for name in names if name.startswith(legacy + '/') and not name.endswith('/')}
    assert legacy_files == {f'{legacy}/{legacy}.toc', f'{legacy}/Compatibility.lua'}, "Compatibility folder must not include an old game engine"
    legacy_toc = archive.read(f'{legacy}/{legacy}.toc').decode('utf-8-sig')
    assert [line.strip() for line in legacy_toc.splitlines() if line.strip() and not line.startswith('#')] == ['Compatibility.lua']
    if addon == 'WaylaidForever':
        assert not any('Pet' in name or 'Companion' in name for name in names), "Bundled pet files in Waylaid ZIP"
        for name in names:
            if name.endswith(('.lua', '.md', '.toc')):
                text = archive.read(name).decode('utf-8-sig')
                assert not re.search(r'\b(?:pets?|companions?)\b', text, re.I), f"Pet reference in Waylaid package: {name}"
    else:
        assert not any('Catalog' in name or 'Recipes' in name or 'Scanner' in name for name in names), "Bundled delivery files in companion ZIP"
    assert archive.testzip() is None, "ZIP integrity check failed"
    print(f"Upload ZIP verified: {len(names)} entries inside {addon}/ and its save compatibility folder")
