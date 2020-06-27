#!/bin/bash

cd "$(dirname "$0")";

REPO_DIR=".." ;

mkdir -p "$REPO_DIR/sample/pbcpp";
cp -rvf "$REPO_DIR/template/common/lua/"*.lua "$REPO_DIR/sample/pbcpp";
cp -rvf "$REPO_DIR/template/common/cpp/"* "$REPO_DIR/sample/pbcpp";

python "$REPO_DIR/tools/find_protoc.py" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcpp"  \
    -g "$REPO_DIR/template/config_manager.h.mako" -g "$REPO_DIR/template/config_manager.cpp.mako"                       \
    -g "$REPO_DIR/template/config_easy_api.h.mako" -g "$REPO_DIR/template/config_easy_api.cpp.mako"                     \
    -l "H:$REPO_DIR/template/config_set.h.mako" -l "S:$REPO_DIR/template/config_set.cpp.mako"                           \
    -g "$REPO_DIR/template/DataTableCustomIndex.lua.mako"                                                               \
    -g "$REPO_DIR/template/DataTableCustomIndex53.lua.mako"                                                             \
    --pb-include-prefix "pbdesc/"                                                                                       \
    "$@"
