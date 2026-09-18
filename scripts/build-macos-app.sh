#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
repo_dir=${script_dir:h}
package_dir="$repo_dir/src/macos"
plist_path="$package_dir/Resources/Info.plist"

configuration="release"
bump_level=""

usage() {
  print -u2 "Usage: $0 [debug|release] [--major|--minor|--revision]"
  exit 64
}

for arg in "$@"; do
  case "$arg" in
    debug|release)
      configuration="$arg"
      ;;
    --major|--minor|--revision)
      if [[ -n "$bump_level" ]]; then
        usage
      fi
      bump_level="${arg#--}"
      ;;
    *)
      usage
      ;;
  esac
done

version_string=$(plutil -extract CFBundleShortVersionString raw "$plist_path")
build_number=$(plutil -extract CFBundleVersion raw "$plist_path")

major=${${(s:.:)version_string}[1]}
minor=${${(s:.:)version_string}[2]}
revision=${${(s:.:)version_string}[3]}

if [[ -n "$bump_level" ]]; then
  case "$bump_level" in
    major)
      (( major += 1 ))
      minor=0
      revision=0
      ;;
    minor)
      (( minor += 1 ))
      revision=0
      ;;
    revision)
      (( revision += 1 ))
      ;;
  esac
  new_version_string="${major}.${minor}.${revision}"
  new_build_number=1
else
  new_version_string="$version_string"
  new_build_number=$(( build_number + 1 ))
fi

sed -i '' \
  -e "/<key>CFBundleShortVersionString<\/key>/{n;s#<string>.*</string>#<string>${new_version_string}</string>#;}" \
  -e "/<key>CFBundleVersion<\/key>/{n;s#<string>.*</string>#<string>${new_build_number}</string>#;}" \
  "$plist_path"

print "Version: $new_version_string ($new_build_number)"

swift build --package-path "$package_dir" -c "$configuration"

binary_path=$(swift build --package-path "$package_dir" -c "$configuration" --show-bin-path)
app_dir="$package_dir/build/TeleCue.app"
contents_dir="$app_dir/Contents"

rm -rf "$app_dir"
mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"
cp "$binary_path/TeleCue" "$contents_dir/MacOS/TeleCue"
cp "$plist_path" "$contents_dir/Info.plist"
cp "$package_dir/Resources/AppIcon.icns" "$contents_dir/Resources/AppIcon.icns"
chmod +x "$contents_dir/MacOS/TeleCue"

print "$app_dir"
