#!/bin/bash
# Lists every global read (GGET) or write (GSET) in the game's Lua sources that
# isn't part of the allowlist below. Uses LuaJIT's bytecode lister, so no deps.
# Exits non-zero if anything is found.

cd "$(dirname "$0")/.." || exit 2

ALLOWED='require|setmetatable|getmetatable|love|math|string|table|pairs|ipairs|print|tostring|tonumber|type|os|arg|error|assert|select|unpack|next|pcall|xpcall|io|rawget|rawset|rawequal|bit|_G|collectgarbage|debug'

status=0
for f in main.lua conf.lua $(find src tests -name '*.lua' -not -path 'src/vendor/*' 2>/dev/null | sort); do
    found=$(luajit -bl "$f" \
        | grep -E 'GSET|GGET' \
        | sed -E 's/.*(GSET|GGET)[^"]*"([^"]+)".*/\1 \2/' \
        | sort -u \
        | grep -vE " ($ALLOWED)\$")
    if [ -n "$found" ]; then
        status=1
        echo "$f:"
        echo "$found" | sed 's/^/    /'
    fi
done

[ $status -eq 0 ] && echo "No stray globals."
exit $status
