#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
repo_dir=${script_dir:h}
package_dir="$repo_dir/src/macos"
plist_path="$package_dir/Resources/Info.plist"

configuration="release"
bump_level=""
no_bump=false
typeset -a archs

usage() {
  print -u2 "Usage: $0 [debug|release] [--major|--minor|--revision|--no-bump] [--arch=arm64|x86_64|universal]..."
  exit 64
}

# Maps a Swift/uname arch name to its Rust-style target triple, used for
# per-arch build output directories and (by callers, e.g. CI) archive names.
arch_to_triple() {
  case "$1" in
    arm64) print "aarch64-apple-darwin" ;;
    x86_64) print "x86_64-apple-darwin" ;;
    *)
      print -u2 "Unknown architecture: $1"
      exit 65
      ;;
  esac
}

for arg in "$@"; do
  case "$arg" in
    debug|release)
      configuration="$arg"
      ;;

    --major|--minor|--revision)
      if [[ -n "$bump_level" || "$no_bump" == true ]]; then
        usage
      fi

      bump_level="${arg#--}"
      ;;

    --no-bump)
      if [[ -n "$bump_level" ]]; then
        usage
      fi

      no_bump=true
      ;;

    --arch=*)
      arch_value="${arg#--arch=}"
      case "$arch_value" in
        arm64|x86_64)
          archs+=("$arch_value")
          ;;
        universal)
          archs+=(arm64 x86_64)
          ;;
        *)
          usage
          ;;
      esac
      ;;

    *)
      usage
      ;;
  esac
done

# No --arch passed: build for whatever CPU this machine actually has.
if (( ${#archs[@]} == 0 )); then
  case "$(uname -m)" in
    arm64)
      archs=(arm64)
      ;;
    x86_64)
      archs=(x86_64)
      ;;
    *)
      print -u2 "Unsupported host architecture: $(uname -m)"
      exit 65
      ;;
  esac
fi

# De-duplicate while preserving order (e.g. --arch=arm64 --arch=universal).
typeset -a unique_archs
for a in "${archs[@]}"; do
  if (( ! ${unique_archs[(Ie)$a]} )); then
    unique_archs+=("$a")
  fi
done
archs=("${unique_archs[@]}")

version_string=$(plutil -extract CFBundleShortVersionString raw "$plist_path")
build_number=$(plutil -extract CFBundleVersion raw "$plist_path")

new_version_string="$version_string"
new_build_number="$build_number"

if [[ "$no_bump" != true ]]; then
  if [[ -n "$bump_level" ]]; then
    version_parts=(${(s:.:)version_string})

    if (( ${#version_parts[@]} != 3 )); then
      print -u2 "Invalid CFBundleShortVersionString: $version_string"
      exit 65
    fi

    major=${version_parts[1]}
    minor=${version_parts[2]}
    revision=${version_parts[3]}

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
    new_build_number=$(( build_number + 1 ))
  fi

  sed -i '' \
    -e "/<key>CFBundleShortVersionString<\/key>/{n;s#<string>.*</string>#<string>${new_version_string}</string>#;}" \
    -e "/<key>CFBundleVersion<\/key>/{n;s#<string>.*</string>#<string>${new_build_number}</string>#;}" \
    "$plist_path"
fi

print "Version: $new_version_string ($new_build_number)"

typeset -a app_paths

for target_arch in "${archs[@]}"; do
  triple=$(arch_to_triple "$target_arch")

  print "Building $target_arch ($triple, $configuration)..."

  swift build \
    --package-path "$package_dir" \
    -c "$configuration" \
    --arch "$target_arch"

  binary_path=$(swift build \
    --package-path "$package_dir" \
    -c "$configuration" \
    --arch "$target_arch" \
    --show-bin-path)

  app_dir="$package_dir/build/$triple/TeleCue.app"
  contents_dir="$app_dir/Contents"

  rm -rf "$app_dir"

  mkdir -p \
    "$contents_dir/MacOS" \
    "$contents_dir/Resources"

  cp \
    "$binary_path/TeleCue" \
    "$contents_dir/MacOS/TeleCue"

  cp \
    "$plist_path" \
    "$contents_dir/Info.plist"

  cp \
    "$package_dir/Resources/AppIcon.icns" \
    "$contents_dir/Resources/AppIcon.icns"

  chmod +x "$contents_dir/MacOS/TeleCue"

  # Re-sign the COMPLETE bundle. The executable carries a stale ad-hoc
  # linker signature from `swift build` that covers only the raw Mach-O;
  # it does not seal Info.plist or Resources once they're copied in
  # afterward, which Gatekeeper rejects as damaged. Signing here, after
  # the bundle is fully assembled, binds Info.plist and seals resources.
  codesign_identity="${TELECUE_CODESIGN_IDENTITY:--}"

  codesign \
    --force \
    --deep \
    --sign "$codesign_identity" \
    "$app_dir"

  codesign \
    --verify \
    --deep \
    --strict \
    --verbose=4 \
    "$app_dir"

  app_paths+=("$app_dir")
done

for app_dir in "${app_paths[@]}"; do
  print "$app_dir"
done
