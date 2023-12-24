# xres-code-generator

## Sample Usage

### Common declare loaders

First `import "xrescode_extensions_v3.proto";` and declare loaders. See [pb_extension/xrescode_extensions_v3.proto](pb_extension/xrescode_extensions_v3.proto) for details.

```protobuf
syntax = "proto3";

import "xrescode_extensions_v3.proto";

message role_upgrade_cfg {
    option (xrescode.loader) = {
        file_path : "role_upgrade_cfg.bytes"
        indexes : {
            fields : "Id"
            index_type : EN_INDEX_KL // Key - List index: (Id) => list<role_upgrade_cfg>
        }
        indexes : {
            fields : "Id"
            fields : "Level"
            index_type : EN_INDEX_KV // Key - Value index: (Id, Level) => role_upgrade_cfg
        }
        // It's allow to add more indexes, the default name of index is [fields].join("_"), you can change name by name field.
        tags : "client"
        tags : "server"
    };

    int32  CostValue = 4;
    int32  ScoreAdd  = 5;
}
```

### For C++

1. Copy common files from [template/common/cpp](template/common/cpp)
2. Generate loader codes by template [template/config_manager.h.mako](template/config_manager.h.mako) , [template/config_manager.cpp.mako](template/config_manager.cpp.mako)  , [template/config_easy_api.h.mako](template/config_easy_api.h.mako) , [template/config_easy_api.cpp.mako](template/config_easy_api.cpp.mako) , [template/config_set.h.mako](template/config_set.h.mako) , [template/config_set.cpp.mako](template/config_set.cpp.mako)

```bash
mkdir -p "$REPO_DIR/sample/pbcpp";
cp -rvf "$REPO_DIR/template/common/cpp/"* "$REPO_DIR/sample/pbcpp";

PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")"
"$PREBUILT_PROTOC" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

# You can use --pb-include-prefix "pbdesc/" to set subdirectory for generated files. This will influence the generated #include <...FILE_PATH>
python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcpp"  \
    -g "$REPO_DIR/template/config_manager.h.mako" -g "$REPO_DIR/template/config_manager.cpp.mako"                       \
    -g "$REPO_DIR/template/config_easy_api.h.mako" -g "$REPO_DIR/template/config_easy_api.cpp.mako"                     \
    -l "H:$REPO_DIR/template/config_set.h.mako" -l "S:$REPO_DIR/template/config_set.cpp.mako"                           \
    "$@"

```

3. At last, just use the generated config_manager and config_easy_api to visit datas.

```cpp
#include <cstdio>

#include "config_manager.h"
#include "config_easy_api.h"

int main() {
    // Initialize ....
    excel::config_manager::me()->init();

    // excel::config_manager::me()->set_version_loader([] (std::string& out) {
    //     // Read version from file and write it to out
    //     out.clear(); // Set version to empty will make config_manager ingore version and always reload data files.
    //     return true; // return true if load version success
    // });

    // If you want to intergrate file loader to your system(such as UE or Unity), you should provide buffer loader handle
    // excel::config_manager::me()->set_buffer_loader([] (std::string& out, const char* file_path) {
    //     // Read binary data from file with path=file_path, and write all data into out
    //     // The value of file_path is the same as file_path field of option (xrescode.loader)
    //     return true; // return true if load file success
    // });

    // Set how much data group will be keep after reload.
    // excel::config_manager::me()->set_group_number(5);

    // Call set_override_same_version(true) to force to reload datas even version(load by set_version_loader(HANDLE)) not changed.
    // excel::config_manager::me()->set_override_same_version(true);

    // Set logger, the default logger is to write log into stdout
    // excel::config_manager::me()->set_on_log([](const log_caller_info_t& caller, const char* content) {
    //    // ...
    // });

    // Any set any other event handles

    // Call reload to generate a configure group
    excel::config_manager::me()->reload();

    // Now you can load data by easy api or config_manager's raw API
    auto cfg = excel::get_role_upgrade_cfg_by_id_level(10001, 3); // using the Key-Value index: id_level
    if (cfg) {
        printf("%s\n", cfg->DebugString().c_str());
    }
    return 0;
}
```

### For UE(UnrealEngine) Blueprint support

```bash
python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/uepbcpp"  \
    --set ue_include_prefix=ExcelLoader --set ue_type_prefix=ExcelLoader \
    --set ue_api_definition=EXCELLOADER_API --add-path "$REPO_DIR/template" \
    --set "ue_excel_loader_include_rule=ExcelLoader/%(file_path_camelname)s.h" \
    --set "ue_excel_group_api_include_rule=%(file_basename_without_ext)s.h" \
    -f "H:$REPO_DIR/template/UEExcelLoader.h.mako:ExcelLoader/\${pb_file.get_file_path_camelname()}.h" \
    -f "S:$REPO_DIR/template/UEExcelLoader.cpp.mako:ExcelLoader/\${pb_file.get_file_path_camelname()}.cpp" \
    -g "H:$REPO_DIR/template/UEExcelGroupApi.h.mako" -g "S:$REPO_DIR/template/UEExcelGroupApi.cpp.mako" \
    "$@"
```

Also, we can use `UEBPProtocol.h.mako` and `UEBPProtocol.cpp.mako` to generate protocol codes for Blueprints.

```bash
python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/uepbcpp"  \
  --set ue_include_prefix=ExcelLoader --set ue_type_prefix=ExcelLoader --set ue_bp_protocol_type_prefix=Proto \
  --set ue_api_definition=EXCELLOADER_API --add-path "$REPO_DIR/template" \
  --set "ue_excel_loader_include_rule=ExcelLoader/%(file_path_camelname)s.h" \
  --set "ue_bp_protocol_include_rule=ExcelLoader/%(directory_path)s/Proto%(file_base_camelname)s.h" \
  --set "ue_excel_group_api_include_rule=%(file_basename_without_ext)s.h" \
  --set "ue_excel_enum_include_rule=ExcelEnum/%(file_basename_without_ext)s.h" \
  --pb-exclude-file "xrescode_extensions_v3.proto" \
  -f "H:$REPO_DIR/template/UEExcelLoader.h.mako:ExcelLoader/\${pb_file.get_file_path_camelname()}.h" \
  -f "S:$REPO_DIR/template/UEExcelLoader.cpp.mako:ExcelLoader/\${pb_file.get_file_path_camelname()}.cpp" \
  -g "H:$REPO_DIR/template/UEExcelGroupApi.h.mako" -g "S:$REPO_DIR/template/UEExcelGroupApi.cpp.mako" \
  -f "H:$REPO_DIR/template/UEExcelEnum.h.mako:ExcelEnum/\${pb_file.get_file_path_camelname()}.h" \
  -f "H:$REPO_DIR/template/UEBPProtocol.h.mako:ExcelLoader/\${pb_file.get_directory_path()}/Proto\${pb_file.get_file_base_camelname()}.h" \
  -f "S:$REPO_DIR/template/UEBPProtocol.cpp.mako:ExcelLoader/\${pb_file.get_directory_path()}/Proto\${pb_file.get_file_base_camelname()}.cpp" \
  "$@"
```

### For lua

1. Copy common files from [template/common/lua](template/common/lua)
2. Generate loader codes by template [template/DataTableCustomIndex.lua.mako](template/DataTableCustomIndex.lua.mako) , [template/DataTableCustomIndex53.lua.mako](template/DataTableCustomIndex53.lua.mako)

```bash
mkdir -p "$REPO_DIR/sample/pblua";
cp -rvf "$REPO_DIR/template/common/lua/"*.lua "$REPO_DIR/sample/pblua";

PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")"
"$PREBUILT_PROTOC" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pblua"  \
    -g "$REPO_DIR/template/DataTableCustomIndex.lua.mako"                                                               \
    -g "$REPO_DIR/template/DataTableCustomIndex53.lua.mako"                                                             \
    "$@"

```

3. At last, just use the generated `DataTableService53` to visit datas.

```lua
-- We will use require(...) to load DataTableService53,DataTableCustomIndex53 and custom data files, please ensure these can be load by require(FILE_PATH)
-- Assuming the generated lua files by xresloader is located at ../../../xresloader/sample/proto_v3
package.path = '../../../xresloader/sample/proto_v3/?.lua;' .. package.path
local excel_config_service = require('DataTableService53')

-- Set logger
-- excel_config_service:OnError = function (message, data_set, indexName, keys...) end

excel_config_service:ReloadTables()

local role_upgrade_cfg = excel_config_service:Get("role_upgrade_cfg")
local data = role_upgrade_cfg:GetByIndex("id_level", 10001, 3) -- using the Key-Value index: id_level
for k,v in pairs(data) do
    print(string.format("%s=%s", k, tostring(v)))
end

-- We can also use DataTableService.GetCurrentGroup(self) and DataTableService.GetByGroup(self, group, loader_name) to support multi-version loader
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

```

### For lua - upb

1. Copy common files from [template/common/upblua](template/common/upblua)
2. Generate loader codes by template [template/DataTableCustomIndexUpb.lua.mako](template/DataTableCustomIndexUpb.lua.mako)

```bash
mkdir -p "$REPO_DIR/sample/upblua";
cp -rvf "$REPO_DIR/template/common/upblua/"*.lua "$REPO_DIR/sample/upblua";
cp -rvf "$REPO_DIR/template/common/lua/vardump.lua" "$REPO_DIR/sample/upblua";

PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")"
"$PREBUILT_PROTOC" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension"     \
    "--lua_out=$REPO_DIR/sample/upblua" "--plugin=protoc-gen-lua=<PATH to protoc-gen-lua>"          \
    "$REPO_DIR/pb_extension/xrescode_extensions_v3.proto" "$REPO_DIR/sample/proto/"*.proto

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/upblua" \
    -g "$REPO_DIR/template/DataTableCustomIndexUpb.lua.mako"                                                            \
    "$@"

```

3. At last, just use the generated `DataTableCustomIndexUpb` to visit datas.

```lua
-- We will use require(...) to load
--   - DataTableServiceUpb
--   - DataTableCustomIndexUpb
--   - xrescode_extensions_v3_pb
--   - pb_header_v3_pb
--   - upb
--   - google/protobuf/descriptor_pb
--   - Other custom proto files generated by protoc-gen-lua
-- Please ensure these can be load by require(FILE_PATH)
local excel_config_service = require("DataTableServiceUpb")
local upb = require('upb')

-- Set logger
-- excel_config_service:OnError = function (message, data_set, indexName, keys...) end

excel_config_service:ReloadTables()

local role_upgrade_cfg = excel_config_service:Get("role_upgrade_cfg")
print("======================= Lazy load begin =======================")
local data = role_upgrade_cfg:GetByIndex("id_level", 10001, 3) -- using the Key-Value index: id_level
print("======================= Lazy load end =======================")

print("----------------------- Get by Key-Value index -----------------------")
print(string.format("Data of role_upgrade_cfg: id=10001, level=3 -> json_encode: %s",
    upb.json_encode(data, { upb.JSONENC_PROTONAMES })))

print("----------------------- Get by reflection and Key-List index -----------------------")
local current_group = excel_config_service:GetCurrentGroup()
local role_upgrade_cfg2 = excel_config_service:GetByGroup(current_group, "role_upgrade_cfg")
local data2 = role_upgrade_cfg2:GetByIndex("id", 10001) -- using the Key-List index: id
for _, v1 in ipairs(data2) do
    print(string.format("\tid: %s, level: %s", tostring(v1.Id), tostring(v1.Level)))
    for fds in role_upgrade_cfg2:GetMessageDescriptor():fields() do
        print(string.format("\t\t%s=%s", fds:name(), tostring(v1[fds:name()])))
    end
end
```

### For lua - lua-protobuf

1. Build lua-protobuf from <https://github.com/starwing/lua-protobuf>
2. Copy common files from [template/common/lua-protobuf](template/common/lua-protobuf)
3. Generate loader codes by template [template/DataTableCustomIndexUpb.lua.mako](template/DataTableCustomIndexUpb.lua.mako) and rename the output to `DataTableCustomIndexLuaProtobuf.lua`

```bash
mkdir -p "$REPO_DIR/sample/lua-protobuf";
cp -rvf "$REPO_DIR/template/common/lua-protobuf/"*.lua "$REPO_DIR/sample/lua-protobuf";
cp -rvf "$REPO_DIR/template/common/lua/vardump.lua" "$REPO_DIR/sample/lua-protobuf";

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/lua-protobuf"   \
    -g "$REPO_DIR/template/DataTableCustomIndexUpb.lua.mako:DataTableCustomIndexLuaProtobuf.lua"                                \
    "$@"

```

4. At last, just use the generated `DataTableCustomIndexLuaProtobuf` to visit datas.

```lua
local pb = require('pb')

-- ============== Begin: load dependency pb files ==============
local function load_pb(file_path)
  local f = io.open(file_path, "rb")
  if f == nil then
    error(string.format("Open file %s failed", file_path))
    return nil
  end
  local data = f:read("a")
  f:close()
  pb.load(data)
end

load_pb('pb_header_v3.pb')
load_pb('sample.pb')
-- ============== End: load dependency pb files ==============

local excel_config_service = require("DataTableServiceLuaProtobuf")
excel_config_service:ReloadTables()

print("----------------------- Get by reflection and Key-List index -----------------------")
local current_group = excel_config_service:GetCurrentGroup()
local role_upgrade_cfg2 = excel_config_service:GetByGroup(current_group, "role_upgrade_cfg")
-- require("vardump")
-- vardump(role_upgrade_cfg2, { show_all = true })
local data2 = role_upgrade_cfg2:GetByIndex("id", 10001) -- using the Key-List index: id
for _, v1 in ipairs(data2) do
  print(string.format("\tid: %s, level: %s", tostring(v1.Id), tostring(v1.Level)))
end
print("Fields of " .. role_upgrade_cfg2:GetMessageDescriptor().name)
for _, fds in ipairs(role_upgrade_cfg2:GetMessageDescriptor().fields) do
  if fds.type.type == nil then
    print(string.format("\t%s %s=%s", fds.type.name, fds.name, tostring(fds.number)))
  else
    print(string.format("\t%s(%s) %s=%s", fds.type.name, fds.type.type, fds.name, tostring(fds.number)))
  end
end

```

### For C\#/CSharp

1. Generate loader codes by template [template/ConfigSet.cs.mako](template/ConfigSet.cs.mako) , [template/ConfigSetManager.cs.mako](template/ConfigSetManager.cs.mako)

```bash
mkdir -p "$REPO_DIR/sample/pbcs";

PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")"
"$PREBUILT_PROTOC" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcs"   \
    -g "$REPO_DIR/template/ConfigSet.cs.mako"                                                                           \
    -l "$REPO_DIR/template/ConfigSetManager.cs.mako"                                                                    \
    "$@"

```

2. Use the generated `ConfigSetManager` to visit datas.

```cs
using System;
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
```

## Custom rule and templates

You can custom your loader codes by providing code template files which just like files in `$REPO_DIR/template` .

* Globale template: `g:<template path>:<output path>`
    > Example: `g:input.h.mako:input.generated.h`

* Message template(render for each message with loader): `m:<header template path>:<output path rule>`
    > Example: `m:input.h.mako:input.generated.${loader.code.class_name.lower()}.h`

* Loader template(render for loader): `l:<header template path>:<output path rule>`
    > Example: `l:input.h.mako:input.generated.${loader.code.class_name.lower()}.h`

* File template(render for loader): `f:<header template path>:<output path rule>`
    > Example: `f:input.h.mako:input.generated.h`

## For developers

### Update dependencies

Use pip to instal all dependencies:

```bash
# For python2
env PATH="$HOME/.local/bin:$PATH" pip install Mako --user -f requirements.txt
# For python3 on Linux or macOS
env PATH="$HOME/.local/bin:$PATH" python3 -m pip install Mako --user -f requirements.txt

```

```powershell
# For python3 on Windows(powershell)
$ENV:PATH="$ENV:HOMEDRIVE$ENV:HOMEPATH\\.local\\bin;$ENV:PATH"
python -m pip install Mako --user -f requirements.txt
```

Or you can download and build dependencies by your self as below and use `--add-path <custom module install path>/--add-package-prefix <custom module install prefix>` to add them to search paths.

#### mako

```bash
MAKO_VERSION=1.2.1 ;
cd 3rd_party ;
wget https://files.pythonhosted.org/packages/ad/dd/34201dae727bb183ca14fd8417e61f936fa068d6f503991f09ee3cac6697/Mako-1.2.1.tar.gz ;
tar -axvf Mako-$MAKO_VERSION.tar.gz ;
rm -rf mako ;
mv Mako-$MAKO_VERSION/mako mako;
chmod 777 -R mako ;
rm -rf Mako-$MAKO_VERSION Mako-$MAKO_VERSION.tar.gz ;
```

#### six

```bash
SIX_VERSION=1.16.0 ;
cd 3rd_party ;
wget https://github.com/benjaminp/six/archive/$SIX_VERSION.tar.gz -O six-$SIX_VERSION.tar.gz ;
tar -ax six-$SIX_VERSION.tar.gz ;
cp -f six-$SIX_VERSION/six.py six/six.py ;
chmod 777 -R six ;
rm -rf six-$SIX_VERSION ;
```

#### protobuf

```bash
PROTOBUF_VERSION=3.21.1 ;
cd 3rd_party ;
wget https://github.com/protocolbuffers/protobuf/releases/download/v$PROTOBUF_VERSION/protobuf-python-$PROTOBUF_VERSION.tar.gz ;
tar -axvf protobuf-python-$PROTOBUF_VERSION.tar.gz ;
cd protobuf-$PROTOBUF_VERSION ;
./configure ;
make -j16 ;
cd python ;
python setup.py build ;
python setup sdist ;

cd ../../ ;
rm -rf protobuf/* ;

mkdir -p protobuf ;
cp -rf protobuf-$PROTOBUF_VERSION/python/dist/protobuf-$PROTOBUF_VERSION/* protobuf/ ;
chmod 777 -R protobuf ;

```

### Update extension codes

```bash
PREBUILT_PROTOC="$("$PYTHON_BIN" "$REPO_DIR/tools/find_protoc.py")"
"$PREBUILT_PROTOC" -I "$REPO_DIR/pb_extension" "--python_out=$REPO_DIR/pb_extension" "$REPO_DIR/pb_extension/xrescode_extensions_v3.proto"
```
