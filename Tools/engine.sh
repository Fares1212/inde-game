#!/usr/bin/env bash
set -euo pipefail
target="${1:?dossier de destination}"
release=https://github.com/godotengine/godot-builds/releases/download/4.5.1-stable
editor=Godot_v4.5.1-stable_linux.x86_64
templates=Godot_v4.5.1-stable_export_templates.tpz
mkdir -p "$target"
target="$(cd "$target" && pwd)"
cd "$target"
curl -fsSL --retry 3 "$release/$editor.zip" -o editor.zip
curl -fsSL --retry 3 "$release/$templates" -o templates.tpz
echo '02ec53d1cc7dbb9cc6355393c61b9ab43d1244751a124f10248a4802830788cd  editor.zip' | sha256sum -c -
echo '1998af37f1387684e2c211cdb483daf492fc64dc6b12096bddcdca25b6910c86  templates.tpz' | sha256sum -c -
unzip -oq editor.zip
mv "$editor" godot
dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/4.5.1.stable"
mkdir -p "$dir"
unzip -joq templates.tpz 'templates/version.txt' 'templates/linux_release.x86_64' 'templates/windows_release_x86_64*.exe' 'templates/macos.zip' -d "$dir"
rm editor.zip templates.tpz
