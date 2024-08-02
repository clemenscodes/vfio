{pkgs}:
pkgs.writeShellScriptBin "qemu" ''
  set -e
  GUEST_NAME="$1"
  HOOK_NAME="$2"
  STATE_NAME="$3"
  MISC="''${@:4}"
  BASEDIR="$(dirname $0)"
  HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
  if [ -f "$HOOKPATH" ] && [ -s "$HOOKPATH"] && [ -x "$HOOKPATH" ]; then
      eval \"$HOOKPATH\" "$@"
  elif [ -d "$HOOKPATH" ]; then
      while read file; do
          if [ ! -z "$file" ]; then
            eval \"$file\" "$@"
          fi
      done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
  fi
''
