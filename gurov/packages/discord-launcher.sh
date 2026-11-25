#!/bin/sh
set -eu
export PATH="@tools@${PATH:+:$PATH}"

config_home=${XDG_CONFIG_HOME:-$HOME/.config}
mkdir -p "$config_home/discord"
dir=$(CDPATH= cd -- "$config_home/discord" && pwd -P)
host=$dir/Discord

settings=$dir/settings.json
if [ -L "$settings" ]; then
    printf '%s\n' 'Discord: refusing symlinked settings.json' >&2
    exit 1
fi
tmp=$(mktemp "$dir/.settings.XXXXXXXX")
trap 'rm -f -- "$tmp"' EXIT HUP INT TERM
if [ -e "$settings" ]; then
    @jq@ 'if type == "object" then .ALLOW_OPTIONAL_UPDATES = false else error("settings must be an object") end' "$settings" > "$tmp"
    chmod --reference="$settings" "$tmp"
else
    printf '%s\n' '{"ALLOW_OPTIONAL_UPDATES":false}' > "$tmp"
fi
mv -f -- "$tmp" "$settings"
trap - EXIT HUP INT TERM
if [ ! -x "$host" ]; then
    mkdir -p "$dir"
    gui=
    [ ! -t 1 ] || gui=--no-gui
    app_dir=$(LD_LIBRARY_PATH="@libraries@${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
        @bootstrap@ $gui "$dir" stable https://updates.discord.com/) || exit 2
    host=$dir/$app_dir/Discord
fi

app=$(readlink -f -- "$host")
app_dir=${app%/Discord}
case "$app_dir" in
    "$dir"/app-*)
        case ${app_dir#"$dir"/} in */*)
            printf '%s\n' 'Discord: invalid client path' >&2; exit 1;; esac ;;
    *) printf '%s\n' 'Discord: invalid client path' >&2; exit 1;;
esac
[ "$app" = "$app_dir/Discord" ] || exit 1
app=$app_dir

find "$app" -type f \( -perm /111 -o -name '*.so*' -o -name '*.node' \) -exec sh -c '
    for file do
        rpath=$(@patchelf@ --print-rpath "$file" 2>/dev/null) || continue
        if [ -u "$file" ] || [ -g "$file" ]; then
            printf "Discord: refusing to modify privileged file %s\n" "$file" >&2
            exit 1
        fi
        interpreter=$(@patchelf@ --print-interpreter "$file" 2>/dev/null) || interpreter=
        if [ -n "$interpreter" ] && [ "$interpreter" != @interpreter@ ]; then
            @patchelf@ --set-interpreter @interpreter@ "$file" || exit 1
        fi
        case "$rpath" in
            "\$ORIGIN:@libraries@"|"\$ORIGIN:@libraries@:"*) ;;
            *) @patchelf@ --set-rpath "\$ORIGIN:@libraries@${rpath:+:$rpath}" "$file" || exit 1;;
        esac
    done
' sh {} + || exit 1
export LD_LIBRARY_PATH="@libraries@${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PATH="@opener-dir@:$PATH"
exec "$app/Discord" "$@"
