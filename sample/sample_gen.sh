#!/bin/bash

cd "$(dirname "$0")";

REPO_DIR=".." ;

mkdir -p "$REPO_DIR/sample/pbcpp";
mkdir -p "$REPO_DIR/sample/pblua";
mkdir -p "$REPO_DIR/sample/pbcs";
cp -rvf "$REPO_DIR/template/common/lua/"*.lua "$REPO_DIR/sample/pblua";
cp -rvf "$REPO_DIR/template/common/cpp/"* "$REPO_DIR/sample/pbcpp";
cp -rvf "$REPO_DIR/template/common/cs/"* "$REPO_DIR/sample/pbcs";

PYTHON_BIN="$(which python3 2>/dev/null)";

if [[ $? -ne 0 ]]; then
    PYTHON_BIN="$(which python)";
else
    $PYTHON_BIN --version;
    if [[ $? -ne 0 ]]; then
        PYTHON_BIN="$(which python)";
    fi
fi

PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")";
"$PREBUILT_PROTOC" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

# --pb-include-prefix "pbdesc/"                                                                                       \

"$PYTHON_BIN" "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcpp"   \
    -g "$REPO_DIR/template/config_manager.h.mako" -g "$REPO_DIR/template/config_manager.cpp.mako"                               \
    -g "$REPO_DIR/template/config_easy_api.h.mako" -g "$REPO_DIR/template/config_easy_api.cpp.mako"                             \
    -l "H:$REPO_DIR/template/config_set.h.mako" -l "S:$REPO_DIR/template/config_set.cpp.mako"                                   \
    "$@"

"$PYTHON_BIN" "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pblua"   \
    -g "$REPO_DIR/template/DataTableCustomIndex.lua.mako"                                                                       \
    -g "$REPO_DIR/template/DataTableCustomIndex53.lua.mako"                                                                     \
    "$@"

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcs"   \
    -g "$REPO_DIR/template/ConfigSetManager.cs.mako"                                                                    \
    -l "$REPO_DIR/template/ConfigSet.cs.mako"                                                                           \
    "$@"

PROTOC_BIN="$(which protoc)";

if [[ $? -ne 0 ]]; then
    PROTOC_BIN="$PREBUILT_PROTOC";
    echo "system protoc not found, using $PROTOC_BIN generate cpp codes, version: $($PROTOC_BIN --version)";
fi

echo "Using protoc: $PROTOC_BIN to generate cpp codes";
echo -e "\t> $PROTOC_BIN --cpp_out=pbcpp -I proto -I ../pb_extension " proto/*.proto;

$PROTOC_BIN --cpp_out=pbcpp --csharp_out=pbcs -I proto -I ../pb_extension proto/*.proto ../pb_extension/*.proto ;

echo '#include <cstdio>

#include "config_manager.h"
#include "config_easy_api.h"

int main() {
    // Initialize ....
    excel::config_manager::me()->init();

    // excel::config_manager::me()->set_version_loader([] (std::string& out) {
    //     // Read version from file and write it to out
    //     return true; // return true if load version success
    // });

    // If you want to intergrate file loader to your system(such as UE or Unity), you should provide buffer loader handle
    // excel::config_manager::me()->set_buffer_loader([] (std::string& out, const char* file_path) {
    //     // Read binary data from file with path=file_path, and write all data into out
    //     return true; // return true if load file success
    // });

    // Set how much data group will be keep after reload.
    // excel::config_manager::me()->set_group_number(8);

    // Call set_override_same_version(true) to force to reload datas even version(load by set_version_loader(HANDLE)) not changed.
    // excel::config_manager::me()->set_override_same_version(true);

    // Set logger, the default logger is to write log into stdout
    // excel::config_manager::me()->set_on_log([](const log_caller_info_t& caller, const char* content) {
    //    // ...
    // });

    // Any set any other event handles

    // Call reload to generate a configure group
    excel::config_manager::me()->reload();

    // Now you can load data by easy api or raw API of config_manager
    auto cfg = excel::get_role_upgrade_cfg_by_id_level(10001, 3);
    if (cfg) {
        printf("%s\n", cfg->DebugString().c_str());
    }
    return 0;
}
' > pbcpp/main.cpp

echo '-- We will use require(...) to load DataTableService53,DataTableCustomIndex53 and custom data files, please ensure these can be load by require(FILE_PATH)
-- Assuming the generated lua files by xresloader is located at ../../../xresloader/sample/proto_v3
package.path = "../../../xresloader/sample/proto_v3/?.lua;" .. package.path
local excel_config_service = require("DataTableService53")

-- Set logger
-- excel_config_service:OnError = function (message, index, indexName, keys...) end

excel_config_service:ReloadTables()

local role_upgrade_cfg = excel_config_service:Get("role_upgrade_cfg")
local data = role_upgrade_cfg:GetByIndex("id_level", 10001, 3) -- using the Key-Value index: id_level
print("Data of role_upgrade_cfg: id=10001, level=3")
for k,v in pairs(data) do
    print(string.format("\t%s=%s", k, tostring(v)))
end

local current_group = excel_config_service:GetCurrentGroup()
local role_upgrade_cfg2 = excel_config_service:GetByGroup(current_group, "role_upgrade_cfg")
local data2 = role_upgrade_cfg:GetByIndex("id", 10001) -- using the Key-List index: id
print("=======================")
for _,v1 in ipairs(data2) do
    print(string.format("\tid: %s, level: %s", tostring(v1.Id), tostring(v1.Level)))
    for k,v2 in pairs(v1) do
        print(string.format("\t\t%s=%s", k, tostring(v2)))
    end
end
' > pblua/main.lua

echo 'using System;
using excel;
class Program {
    static void Main(string[] args) {
        ConfigSetManager.Instance.Reload();
        // The C# configSet now generated by Singleton Classes.
        // For the multi ConfigGroup management may be added when need.
        var table = config_set_role_upgrade_cfg.Instance.GetByIdLevel(10001, 3);
        if (table != null) {
            Console.WriteLine(table.ToString());
        }
    }
}
' > pbcs/Main.cs

PROTOBUF_PREBUILT_DIR="$(dirname "$PROTOC_BIN")";
PROTOBUF_PREBUILT_DIR="$(dirname "$PROTOBUF_PREBUILT_DIR")";

if [[ -e "$PROTOBUF_PREBUILT_DIR/include/google/protobuf/descriptor.h" ]]; then
    echo "Compile Cmd: g++ -Wall -Wextra -o pbcpp/sample.exe -I$PROTOBUF_PREBUILT_DIR/include -L$PROTOBUF_PREBUILT_DIR/lib -Ipbcpp pbcpp/*.cpp pbcpp/*.cc -lprotobuf";
else
    echo "Compile Cmd: g++ -Wall -Wextra -o pbcpp/sample.exe -I<protobuf prefix>/include -L<protobuf prefix>/lib -Ipbcpp pbcpp/*.cpp pbcpp/*.cc -lprotobuf";
fi
