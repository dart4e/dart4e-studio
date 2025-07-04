#!/usr/bin/env bash
# SPDX-FileCopyrightText: © Dart4E authors
# SPDX-FileContributor: Sebastian Thomschke
# SPDX-License-Identifier: EPL-2.0
# SPDX-ArtifactOfProjectHomePage: https://github.com/dart4e/dart4e-studio
#

set -eu

# execute script with bash if loaded with other shell interpreter
if [ -z "${BASH_VERSINFO:-}" ]; then /usr/bin/env bash "$0" "$@"; exit; fi

set -o pipefail

trap 'echo >&2 "$(date +%H:%M:%S) Error - exited with status $? at line $LINENO:"; pr -tn $0 | tail -n+$((LINENO - 3)) | head -n7' ERR

THIS_FILE_DIR=$(cd "$(dirname "$0")"; pwd -P)
cd "$THIS_FILE_DIR"

if ! hash 7z 2>/dev/null; then
  echo "Required command [7z] is not installed!"
  exit 1
fi

cd "$THIS_FILE_DIR"

echo "Cleaning..."
rm -rf \
  target/Dart4EStudioPortable* \
  target/launcher \
  target/7z.sfx

echo "Creating portable apps layout..."
cp -r src/templates/Dart4EStudioPortable target/
cp ../plugin/src/main/resources/images/logo/dart4e_logo16x16.png target/Dart4EStudioPortable/App/AppInfo/appicon_16.png
cp ../plugin/src/main/resources/images/logo/dart4e_logo32x32.png target/Dart4EStudioPortable/App/AppInfo/appicon_32.png
cp ../plugin/src/main/resources/images/logo/dart4e_logo48x48.png target/Dart4EStudioPortable/App/AppInfo/appicon_48.png
cp ../plugin/src/main/resources/images/logo/dart4e_logo128x128.png target/Dart4EStudioPortable/App/AppInfo/appicon_128.png
mv target/products/org.dart4e.studio/win32/win32/x86_64 target/Dart4EStudioPortable/App/Dart4EStudio

mkdir -p target/Dart4EStudioPortable/App/Dart4EStudio/configuration/.settings
cat <<EOF >target/Dart4EStudioPortable/App/Dart4EStudio/configuration/.settings/org.eclipse.ui.ide.prefs
eclipse.preferences.version=1
RECENT_WORKSPACES=Data\\\\workspace
RECENT_WORKSPACES_PROTOCOL=3
SHOW_RECENT_WORKSPACES=false
SHOW_WORKSPACE_SELECTION_DIALOG=true
WARN_ABOUT_WORKSPACE_INCOMPATIBILITY=false
EOF

echo "Determining PortalApps.com Launcher version..."
# LC_ALL=en_US.utf8 -> workaround for "grep: -P supports only unibyte and UTF-8 locales"
launcher_version=$(curl -sSf "https://portableapps.com/apps/development/portableapps.com_launcher" | LC_ALL=en_US.utf8 grep -oP 'href="/downloading/.*\K(\d+\.\d+\.\d+)')

echo "Downloading PortalApps.com Launcher $launcher_version..."
# https://portableapps.com/apps/development/portableapps.com_launcher
curl -sSfL "https://portableapps.com/redirect/?a=PortableApps.comLauncher&s=s&d=pa&f=PortableApps.comLauncher_${launcher_version}.paf.exe" -o target/launcher.paf.exe
7z x target/launcher.paf.exe -otarget/launcher -y

echo "Generating Dart4EStudio launcher exe..."
cd target/launcher
./PortableApps.comLauncherGenerator.exe "$(cygpath -w ../Dart4EStudioPortable)"

echo "Creating Dart4EStudioPortable.paf.exe..."
cd "$THIS_FILE_DIR/target"

# 7z switches: https://sevenzip.osdn.jp/chm/cmdline/switches/
# -mqs sorts files by type instead by name which increases compression ratio
7z a -spf -y -mqs -mx1 -bt Dart4EStudioPortable.7z Dart4EStudioPortable

curl -sSfL https://www.7-zip.org/a/7z2201-x64.exe > 7z.exe

7z x 7z.exe 7z.sfx
cp 7z.sfx Dart4EStudioPortable.paf.exe
cat Dart4EStudioPortable.7z >> Dart4EStudioPortable.paf.exe
