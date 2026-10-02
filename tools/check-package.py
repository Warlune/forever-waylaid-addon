"""Validate the actual upload ZIP, including CurseForge's root-folder rule."""
import sys
from pathlib import PurePosixPath
from zipfile import ZipFile

with ZipFile(sys.argv[1]) as archive:
    names = archive.namelist()
    assert names and len(names) == len(set(names)), "Empty archive or duplicate paths"
    addon = names[0].split('/')[0]
    assert addon in ('ForeverWaylaid', 'ForeverCompanions'), "Unknown addon root"
    if len(sys.argv) > 2:
        assert addon == sys.argv[2], "Wrong addon in this upload"
    for name in names:
        path = PurePosixPath(name)
        assert not path.is_absolute() and ".." not in path.parts and "\\" not in name, f"Unsafe path: {name}"
        assert name.startswith(addon + "/"), f"File outside addon folder: {name}"
    required = [addon + ".toc", "LICENSE", "README.md", "RELEASE_NOTES.md"]
    toc = archive.read(f"{addon}/{addon}.toc").decode("utf-8-sig")
    required += [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    for name in required:
        assert addon + "/" + name in names, f"Missing packaged file: {name}"
    if addon == 'ForeverWaylaid':
        assert not any('Pet' in name or 'Companion' in name for name in names), "Bundled pet files in Waylaid ZIP"
    else:
        assert not any('Catalog' in name or 'Recipes' in name or 'Scanner' in name for name in names), "Bundled delivery files in companion ZIP"
    assert archive.testzip() is None, "ZIP integrity check failed"
    print(f"Upload ZIP verified: {len(names)} entries, all inside {addon}/")
