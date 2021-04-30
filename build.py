import sys
import zipfile
import glob
import os
import struct


ignore_extentions = [
    ".dbs",
    ".bak",
    ".backup1",
    ".backup2",
    ".backup3",
    ".aseprite",
]


wad_header_s = struct.Struct("<4sII")
wad_file_header_s = struct.Struct("<II8s")


def read_wad(fp):
    out = {}
    with open(fp, "rb") as f:
        _, filecount, tocloc = wad_header_s.unpack(f.read(wad_header_s.size))
        f.seek(tocloc)
        for _ in range(filecount):
            loc, size, name = wad_file_header_s.unpack(f.read(wad_file_header_s.size))
            retloc = f.tell()
            f.seek(loc)
            out[str(name, "ascii")] = f.read(size)
            f.seek(retloc)
    return out


def get_zip_path(file_path: str) -> str:
    return file_path


with zipfile.ZipFile(sys.argv[2], "w", allowZip64=False, compression=zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
    os.chdir(sys.argv[1])
    files = glob.glob("**/*", recursive=True)
    for fp in sorted(files):
        ext = os.path.splitext(os.path.split(fp)[1])[1].lower()
        if ext in ignore_extentions:
            continue
        elif ext == ".wad":
            # extract wad and dump it in
            folder = os.path.splitext(fp)[0]
            zf.writestr(folder + "/", "")
            lumps: dict[str, bytes] = read_wad(fp)
            for lump, data in lumps.items():
                zf.writestr(folder + "/" + lump, data)
        else:
            zf.write(fp, get_zip_path(fp))
