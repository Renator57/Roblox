"""Baut KristallImperium.rbxlx aus den Skripten in src/ (ohne Rojo).

Aufruf:  python3 tools/build_place.py
"""
import itertools
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parent.parent
_ids = itertools.count(1)


def ref():
    return "RBX%032X" % next(_ids)


def item(cls, name, children="", source=None):
    props = f'<string name="Name">{escape(name)}</string>'
    if source is not None:
        if "]]>" in source:
            raise ValueError(f"{name}: ']]>' kann nicht in CDATA stehen")
        props += f'<ProtectedString name="Source"><![CDATA[{source}]]></ProtectedString>'
    return f'<Item class="{cls}" referent="{ref()}"><Properties>{props}</Properties>{children}</Item>'


def script(cls, name, path):
    return item(cls, name, source=(ROOT / path).read_text(encoding="utf-8"))


place = "".join([
    item("ReplicatedStorage", "ReplicatedStorage",
         item("Folder", "Shared", script("ModuleScript", "Config", "src/shared/Config.luau"))),
    item("ServerScriptService", "ServerScriptService",
         item("Folder", "Server",
              script("Script", "Main", "src/server/Main.server.luau")
              + script("ModuleScript", "MapBuilder", "src/server/MapBuilder.luau")
              + script("ModuleScript", "PlayerData", "src/server/PlayerData.luau")
              + script("ModuleScript", "Hub", "src/server/Hub.luau")
              + script("ModuleScript", "Pets", "src/server/Pets.luau")
              + script("ModuleScript", "Fun", "src/server/Fun.luau"))),
    item("StarterPlayer", "StarterPlayer",
         item("StarterPlayerScripts", "StarterPlayerScripts",
              script("LocalScript", "HUD", "src/client/HUD.client.luau")
              + script("LocalScript", "Extras", "src/client/Extras.client.luau"))),
])

out = ROOT / "KristallImperium.rbxlx"
out.write_text(f'<roblox version="4">{place}</roblox>\n', encoding="utf-8")
print("Geschrieben:", out)
