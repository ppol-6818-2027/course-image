#!/usr/bin/env python3
"""Package the course's VS Code extensions as .vsix files, run by install.sh.

  make-vsix.py pack DIR OUT.vsix    the course extension, from its folder
  make-vsix.py pdf IN.vsix OUT.vsix the course build of the PDF viewer

A .vsix is a zip with a manifest; this writes one without vsce or Node.

The PDF viewer is mathematic.vscode-pdf (Apache-2.0, pdf.js). Its course
build differs in two ways only, both recorded in its readme: on first use
it no longer shows the one-time "Support Mathematic" notice, and it is
published as ppol6818.vscode-pdf, so the marketplace never replaces it.
"""
import json, sys, zipfile
from xml.sax.saxutils import escape

TYPES = ('<?xml version="1.0" encoding="utf-8"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
         '<Default Extension=".json" ContentType="application/json"/><Default Extension=".js" ContentType="application/javascript"/>'
         '<Default Extension=".md" ContentType="text/markdown"/><Default Extension=".vsixmanifest" ContentType="text/xml"/></Types>')


def manifest(p):
    kind = ",".join(p.get("extensionKind", ["workspace"]))
    return (f'<?xml version="1.0" encoding="utf-8"?><PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">'
            f'<Metadata><Identity Language="en-US" Id="{p["name"]}" Version="{p["version"]}" Publisher="{p["publisher"]}"/>'
            f'<DisplayName>{escape(p["displayName"])}</DisplayName><Description xml:space="preserve">{escape(p.get("description", ""))}</Description>'
            f'<Properties><Property Id="Microsoft.VisualStudio.Code.Engine" Value="{p["engines"]["vscode"]}"/>'
            f'<Property Id="Microsoft.VisualStudio.Code.ExtensionKind" Value="{kind}"/></Properties></Metadata>'
            '<Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation><Dependencies/>'
            '<Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets></PackageManifest>')


def pack(src, out):
    import os
    p = json.load(open(os.path.join(src, "package.json")))
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("extension.vsixmanifest", manifest(p))
        z.writestr("[Content_Types].xml", TYPES)
        for f in sorted(os.listdir(src)):
            z.write(os.path.join(src, f), "extension/" + f)


def once(text, old, new, what):
    if text.count(old) != 1:
        sys.exit(f"make-vsix: {what} not found exactly once; the PDF viewer has changed, so check the patch")
    return text.replace(old, new)


NOTE = ("\n\n## PPOL 6818 course build\n\nThis is mathematic.vscode-pdf 0.2.7 (Apache-2.0), changed for the PPOL 6818 course codespaces in two ways only: "
        "it does not show the one-time notice asking for support on first use, and it is published as ppol6818.vscode-pdf so that the marketplace "
        "never replaces it. Please support the original at https://github.com/sponsors/mathematic-inc.\n")


def pdf(src, out):
    zin = zipfile.ZipFile(src)
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for info in zin.infolist():
            data = zin.read(info.filename)
            if info.filename == "extension/package.json":
                p = json.loads(data)
                p["publisher"] = "ppol6818"
                p["displayName"] = "PDF Viewer (PPOL 6818 build)"
                data = json.dumps(p, indent=2).encode()
            elif info.filename == "extension.vsixmanifest":
                t = data.decode()
                t = once(t, 'Publisher="mathematic"', 'Publisher="ppol6818"', "the manifest's publisher")
                t = once(t, "<DisplayName>PDF Viewer</DisplayName>", "<DisplayName>PDF Viewer (PPOL 6818 build)</DisplayName>", "the manifest's name")
                data = t.encode()
            elif info.filename == "extension/dist/extension.js":
                t = data.decode()
                t = once(t, 'e.globalState.get("supportPromptShown")||', "true||", "the support notice")
                data = t.encode()
            elif info.filename == "extension/readme.md":
                data = data + NOTE.encode()
            z.writestr(info, data)


if __name__ == "__main__":
    {"pack": pack, "pdf": pdf}[sys.argv[1]](sys.argv[2], sys.argv[3])
