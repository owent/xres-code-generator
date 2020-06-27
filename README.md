# xres-code-generator

## Sample Usage

```bash
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

```

Then, you can use lua loader ( ```DataTableService53.lua``` and ```DataTableCustomIndex53.lua``` ) in ```$REPO_DIR/sample/pbcpp``` or c++ loader ( ```config_manager.h``` and ```config_easy_api.h``` ) in ```$REPO_DIR/sample/pbcpp``` .

Or you can custom your loader codes by providing code template files which just like files in ```$REPO_DIR/template``` .

## Custom rule

* Globale template: ```g:<template path>:<output path>```
    > Example: ```g:input.h.mako:input.generated.h```

* Message template(render for each message with loader): ```m:<header template path>:<output path rule>```
    > Example: ```m:input.h.mako:input.generated.${loader.code.class_name.lower()}.h```

* Loader template(render for loader): ```l:<header template path>:<output path rule>```
    > Example: ```l:input.h.mako:input.generated.${loader.code.class_name.lower()}.h```

## Update dependencies

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
MAKO_VERSION=1.1.2 ;
cd 3rd_party ;
wget https://files.pythonhosted.org/packages/42/64/fc7c506d14d8b6ed363e7798ffec2dfe4ba21e14dda4cfab99f4430cba3a/Mako-$MAKO_VERSION.tar.gz ;
tar -axvf Mako-$MAKO_VERSION.tar.gz ;
rm -rf mako ;
mv Mako-$MAKO_VERSION/mako mako;
chmod 777 -R mako ;
rm -rf Mako-$MAKO_VERSION Mako-$MAKO_VERSION.tar.gz ;
```

### six

```bash
SIX_VERSION=1.14.0 ;
cd 3rd_party ;
wget https://github.com/benjaminp/six/archive/$SIX_VERSION.tar.gz -O six-$SIX_VERSION.tar.gz ;
tar -ax six-$SIX_VERSION.tar.gz ;
cp -f six-$SIX_VERSION/six.py six/six.py ;
chmod 777 -R six ;
rm -rf six-$SIX_VERSION ;
```

### protobuf

```bash
PROTOBUF_VERSION=3.11.4 ;
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
