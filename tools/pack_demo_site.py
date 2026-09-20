"""Combine the two web exports into one deployable site that shares a single engine.

Godot emits a complete standalone app per preset, so the client and the ball call
console each ship their own copy of the ~39MB engine wasm -- and they are byte for
byte identical, because it is the same engine. A visitor loading the demo page would
download it twice.

The Godot loader resolves the pack as `mainPack || ${executable}.pck`, so both apps
can share one engine by keeping `executable` pointing at the shared basename and
giving each its own `mainPack`. That puts the whole demo in one directory:

    index.wasm  index.js  ...worklets       shared engine, downloaded once
    client.pck  console.pck                 ~220KB each
    client.html console.html                same engine, different pack
    index.html                              the two-iframe embed page

Usage: python tools/pack_demo_site.py <client_export_dir> <console_export_dir> <out_dir>
"""

import json
import re
import shutil
import sys
from pathlib import Path

# Emitted per export but identical between them; taken from the client build.
SHARED = [
    "index.js",
    "index.wasm",
    "index.audio.worklet.js",
    "index.audio.position.worklet.js",
    "index.icon.png",
    "index.png",
]

EMBED_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Junkyard Jewels &mdash; Class II slot demo</title>
<style>
  :root { color-scheme: dark; }
  body { margin: 0; background: #14161a; color: #dfe4ea;
         font-family: system-ui, -apple-system, sans-serif; }
  .wrap { display: flex; flex-wrap: wrap; gap: 16px; padding: 16px;
          max-width: 1360px; margin: 0 auto; }
  .panel { flex: 1 1 640px; min-width: 300px; }
  .panel h2 { font-size: 13px; font-weight: 500; margin: 0 0 8px;
              color: #7e8b9e; letter-spacing: .02em; }
  iframe { width: 100%; aspect-ratio: 16 / 9; border: 0; display: block;
           background: #000; border-radius: 6px; }
</style>
</head>
<body>
<div class="wrap">
  <div class="panel">
    <h2>slot client</h2>
    <iframe src="client.html" title="Junkyard Jewels slot machine"></iframe>
  </div>
  <div class="panel">
    <h2>ball call server</h2>
    <iframe src="console.html" title="Bingo ball call server"></iframe>
  </div>
</div>
</body>
</html>
"""


# Injected into each shell. The engine sizes the canvas to the project resolution
# divided by the device pixel ratio, which ignores the container completely: that is
# 640x360 at dpr 1 so a desktop looks right by coincidence, but 213x120 inside a
# 343px frame at dpr 3 -- a tiny game in a correctly sized space.
#
# Stretching the element to fill its frame while leaving the backing store at 640x360
# means a phone GPU still only ever draws 640x360, and the pixel art upscales with
# hard edges instead of being resampled at some non-integer ratio.
#
# !important is load-bearing, not decorative: the engine writes width and height
# INLINE on the element at runtime, and an inline declaration beats a normal author
# rule. An author !important declaration beats a normal inline one, which is exactly
# the case this exists for. Without it the rule silently loses.
#
# This assumes the container is 16:9, which the embed page guarantees. Embedding
# client.html directly at another aspect will stretch the cabinet.
CANVAS_CSS = """<style>
#canvas {
	width: 100% !important;
	height: 100% !important;
	image-rendering: pixelated;
}
</style>
</head>"""


def patch_shell(html: str, pack_name: str) -> str:
    """Point this app's shell at the shared engine but its own pack."""
    match = re.search(r"const GODOT_CONFIG = (\{.*?\});", html, re.DOTALL)
    if not match:
        raise SystemExit("Could not find GODOT_CONFIG in the exported shell.")

    config = json.loads(match.group(1))
    config["mainPack"] = pack_name

    # The service worker caches a file list built for a standalone export and would
    # try to cache a pack that no longer sits at index.pck. The demo is embedded in
    # a page, not installed, so drop it rather than rewriting its manifest.
    config.pop("serviceWorker", None)

    sizes = config.get("fileSizes", {})
    if "index.pck" in sizes:
        sizes[pack_name] = sizes.pop("index.pck")

    html = html[: match.start()] + "const GODOT_CONFIG = %s;" % json.dumps(config) + html[match.end():]

    if "</head>" not in html:
        raise SystemExit("Exported shell has no </head> to attach the canvas rule to.")
    return html.replace("</head>", CANVAS_CSS, 1)


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)

    client, console, out = (Path(p) for p in sys.argv[1:4])
    out.mkdir(parents=True, exist_ok=True)

    for name in SHARED:
        source = client / name
        if source.exists():
            shutil.copy2(source, out / name)

    for export_dir, app in ((client, "client"), (console, "console")):
        wasm = export_dir / "index.wasm"
        shared_wasm = out / "index.wasm"
        if wasm.exists() and shared_wasm.exists() and wasm.stat().st_size != shared_wasm.stat().st_size:
            raise SystemExit(
                "%s ships a different engine build than the client; they cannot share one wasm." % app
            )

        shutil.copy2(export_dir / "index.pck", out / ("%s.pck" % app))
        shell = (export_dir / "index.html").read_text(encoding="utf-8")
        (out / ("%s.html" % app)).write_text(patch_shell(shell, "%s.pck" % app), encoding="utf-8")

    (out / "index.html").write_text(EMBED_PAGE, encoding="utf-8")

    total = sum(f.stat().st_size for f in out.rglob("*") if f.is_file())
    print("packed %s (%.1f MB, engine shared once)" % (out, total / 1048576))


if __name__ == "__main__":
    main()
