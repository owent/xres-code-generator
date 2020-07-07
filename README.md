# xres-code-generator

## Sample Usage

### Common declare loaders

First ```import "xrescode_extensions_v3.proto";``` and declare loaders.

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

python "$REPO_DIR/tools/find_protoc.py" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

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
    //     return true; // return true if load version success
    // });

    // If you want to intergrate file loader to your system(such as UE or Unity), you should provide buffer loader handle
    // excel::config_manager::me()->set_buffer_loader([] (std::string& out, const char* file_path) {
    //     // Read binary data from file with path=file_path, and write all data into out
    //     // The value of file_path is the same as file_path field of option (xrescode.loader)
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

    // Now you can load data by easy api or config_manager's raw API
    auto cfg = excel::get_role_upgrade_cfg_by_id_level(10001, 3); // using the Key-Value index: id_level
    if (cfg) {
        printf("%s\n", cfg->DebugString().c_str());
    }
    return 0;
}
```

### For lua

1. Copy common files from [template/common/lua](template/common/lua)
2. Generate loader codes by template [template/DataTableCustomIndex.lua.mako](template/DataTableCustomIndex.lua.mako) , [template/DataTableCustomIndex53.lua.mako](template/DataTableCustomIndex53.lua.mako)

```bash
mkdir -p "$REPO_DIR/sample/pblua";
cp -rvf "$REPO_DIR/template/common/lua/"*.lua "$REPO_DIR/sample/pblua";

python "$REPO_DIR/tools/find_protoc.py" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pblua"  \
    -g "$REPO_DIR/template/DataTableCustomIndex.lua.mako"                                                               \
    -g "$REPO_DIR/template/DataTableCustomIndex53.lua.mako"                                                             \
    "$@"

```

3. At last, just use the generated ```DataTableService53``` to visit datas.

```lua
-- We will use require(...) to load DataTableService53,DataTableCustomIndex53 and custom data files, please ensure these can be load by require(FILE_PATH)
-- Assuming the generated lua files by xresloader is located at ../../../xresloader/sample/proto_v3
package.path = '../../../xresloader/sample/proto_v3/?.lua;' .. package.path
local excel_config_service = require('DataTableService53')

-- Set logger
-- excel_config_service:OnError = function (message, index, indexName, keys...) end

excel_config_service:ReloadTables()

local role_upgrade_cfg = excel_config_service:Get("role_upgrade_cfg")
local data = role_upgrade_cfg:GetByIndex('id_level', 10001, 3) -- using the Key-Value index: id_level
for k,v in pairs(data) do
    print(string.format("%s=%s\n", k, tostring(v)))
end
```

### For C\#/CSharp

1. Generate loader codes by template [template/ConfigSet.cs.mako](template/ConfigSet.cs.mako) , [template/ConfigSetManager.cs.mako](template/ConfigSetManager.cs.mako)

```bash
mkdir -p "$REPO_DIR/sample/pbcs";

python "$REPO_DIR/tools/find_protoc.py" -I "$REPO_DIR/sample/proto" -I "$REPO_DIR/pb_extension" "$REPO_DIR/sample/proto/"*.proto -o "$REPO_DIR/sample/sample.pb" ;

python "$REPO_DIR/xrescode-gen.py" -i "$REPO_DIR/template" -p "$REPO_DIR/sample/sample.pb" -o "$REPO_DIR/sample/pbcs"   \
    -g "$REPO_DIR/template/ConfigSet.cs.mako"                                                                           \
    -g "$REPO_DIR/template/ConfigSetManager.cs.mako"                                                                    \
    "$@"

```

2. Use the generated ```ConfigSetManager``` to visit datas.

```cs
using System;
using excel;
class Program {
    static void Main(string[] args) {
        ConfigSetManager.Instance.Reload();
        var table = config_set_role_upgrade_cfg.Instance.GetByIdLevel(10001, 3);
        if (table != null) {
            Console.WriteLine(table.ToString());
        }
    }
}
```

## Custom rule and templates

You can custom your loader codes by providing code template files which just like files in ```$REPO_DIR/template``` .

* Globale template: ```g:<template path>:<output path>```
    > Example: ```g:input.h.mako:input.generated.h```

* Message template(render for each message with loader): ```m:<header template path>:<output path rule>```
    > Example: ```m:input.h.mako:input.generated.${loader.code.class_name.lower()}.h```

* Loader template(render for loader): ```l:<header template path>:<output path rule>```
    > Example: ```l:input.h.mako:input.generated.${loader.code.class_name.lower()}.h```

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

Or you can download and build dependencies by your self

### mako

```bash
MAKO_VERSION=1.1.3 ;
cd 3rd_party ;
wget https://files.pythonhosted.org/packages/72/89/402d2b4589e120ca76a6aed8fee906a0f5ae204b50e455edd36eda6e778d/Mako-1.1.3.tar.gz ;
tar -axvf Mako-$MAKO_VERSION.tar.gz ;
rm -rf mako ;
mv Mako-$MAKO_VERSION/mako mako;
chmod 777 -R mako ;
rm -rf Mako-$MAKO_VERSION Mako-$MAKO_VERSION.tar.gz ;
```

### six

```bash
SIX_VERSION=1.15.0 ;
cd 3rd_party ;
wget https://github.com/benjaminp/six/archive/$SIX_VERSION.tar.gz -O six-$SIX_VERSION.tar.gz ;
tar -ax six-$SIX_VERSION.tar.gz ;
cp -f six-$SIX_VERSION/six.py six/six.py ;
chmod 777 -R six ;
rm -rf six-$SIX_VERSION ;
```

### protobuf

```bash
PROTOBUF_VERSION=3.12.3 ;
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
