"""Validate the actual upload ZIP, including CurseForge's root-folder rule."""
import sys
from pathlib import PurePosixPath
from zipfile import ZipFile

with ZipFile(sys.argv[1]) as archive:
    names = archive.namelist()
    assert names and len(names) == len(set(names)), "Empty archive or duplicate paths"
    for name in names:
        path = PurePosixPath(name)
        assert not path.is_absolute() and ".." not in path.parts and "\\" not in name, f"Unsafe path: {name}"
        assert name.startswith("ForeverWaylaid/"), f"File outside addon folder: {name}"
    required = ["ForeverWaylaid.toc", "LICENSE", "README.md", "RELEASE_NOTES.md"]
    toc = archive.read("ForeverWaylaid/ForeverWaylaid.toc").decode("utf-8-sig")
    required += [line.strip() for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    for name in required:
        assert "ForeverWaylaid/" + name in names, f"Missing packaged file: {name}"
    assert archive.testzip() is None, "ZIP integrity check failed"
    print(f"Upload ZIP verified: {len(names)} entries, all inside ForeverWaylaid/")
