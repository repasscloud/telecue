#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
repo_dir=${script_dir:h}
package_dir="$repo_dir/src/macos"
configuration=${1:-release}

if [[ "$configuration" != "debug" && "$configuration" != "release" ]]; then
  print -u2 "Usage: $0 [debug|release]"
  exit 64
fi

swift build --package-path "$package_dir" -c "$configuration"

binary_path=$(swift build --package-path "$package_dir" -c "$configuration" --show-bin-path)
app_dir="$package_dir/build/TeleCue.app"
contents_dir="$app_dir/Contents"

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$binary_path/TeleCue" "$contents_dir/MacOS/TeleCue"
cp "$package_dir/Resources/Info.plist" "$contents_dir/Info.plist"
chmod +x "$contents_dir/MacOS/TeleCue"

print "$app_dir"
