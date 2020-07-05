#!/bin/bash

cd "$(dirname "$0")";

REPO_DIR=".." ;

mkdir -p "$REPO_DIR/sample/pbcpp";
cp -rvf "$REPO_DIR/template/common/lua/"*.lua "$REPO_DIR/sample/pbcpp";
cp -rvf "$REPO_DIR/template/common/cpp/"* "$REPO_DIR/sample/pbcpp";

PYTHON_BIN="$(which python3 2>/dev/null)";

if [[ $? -ne 0 ]]; then
    PYTHON_BIN="$(which python)";
fi

PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")";
"$PREBUILT_PROTOC" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

# --pb-include-prefix "pbdesc/"                                                                                       \

"$PYTHON_BIN" "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcpp"  \
    -g "$REPO_DIR/template/config_manager.h.mako" -g "$REPO_DIR/template/config_manager.cpp.mako"                       \
    -g "$REPO_DIR/template/config_easy_api.h.mako" -g "$REPO_DIR/template/config_easy_api.cpp.mako"                     \
    -l "H:$REPO_DIR/template/config_set.h.mako" -l "S:$REPO_DIR/template/config_set.cpp.mako"                           \
    -g "$REPO_DIR/template/DataTableCustomIndex.lua.mako"                                                               \
    -g "$REPO_DIR/template/DataTableCustomIndex53.lua.mako"                                                             \
    "$@"


PROTOC_BIN="$(which protoc)";

if [[ $? -ne 0 ]]; then
    PROTOC_BIN="$PREBUILT_PROTOC";
    echo "system protoc not found, using $PROTOC_BIN generate cpp codes, version: $($PROTOC_BIN --version)";
fi

echo "Using protoc: $PROTOC_BIN to generate cpp codes";
echo -e "\t> $PROTOC_BIN --cpp_out=pbcpp -I proto -I ../pb_extension " proto/*.proto;

$PROTOC_BIN --cpp_out=pbcpp -I proto -I ../pb_extension proto/*.proto ../pb_extension/*.proto ;

echo '#include <cstdio>
#include "config_manager.h"
int main() {
    excel::config_manager::me()->init();
    excel::config_manager::me()->reload();
    return 0;
}
' > pbcpp/main.cpp

PROTOBUF_PREBUILT_DIR="$(dirname "$PROTOC_BIN")";
PROTOBUF_PREBUILT_DIR="$(dirname "$PROTOBUF_PREBUILT_DIR")";

if [[ -e "$PROTOBUF_PREBUILT_DIR/include/google/protobuf/descriptor.h" ]]; then
    echo "Compile Cmd: g++ -Wall -Wextra -o pbcpp/sample.exe -I$PROTOBUF_PREBUILT_DIR/include -L$PROTOBUF_PREBUILT_DIR/lib -Ipbcpp pbcpp/*.cpp pbcpp/*.cc -lprotobuf";
else
    echo "Compile Cmd: g++ -Wall -Wextra -o pbcpp/sample.exe -I<protobuf prefix>/include -L<protobuf prefix>/lib -Ipbcpp pbcpp/*.cpp pbcpp/*.cc -lprotobuf";
fi
