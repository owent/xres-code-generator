#!/bin/bash

cd "$(dirname "$0")";

chmod +x ../tools/find_protoc.py ;

PROTOC_BIN="$(../tools/find_protoc.py)";

chmod +x "$PROTOC_BIN";

"$PROTOC_BIN" -I proto -I ../pb_extension proto/*.proto -o sample.pb ;

../xrescode-gen.py -i template -p sample.pb -o pbcpp                      \
    -g template/config_manager.h.mako -g template/config_manager.cpp.mako \
    -l H:template/config_set.h.mako -l S:template/config_set.cpp.mako     \
    -g template/DataTableCustomIndex.lua.mako                             \
    -g template/DataTableCustomIndex53.lua.mako                           \
    --pb-include-prefix "pbdesc/"                                         \
    "$@"
