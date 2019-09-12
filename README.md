# xres-code-generator

## Custom rule

* Globale template: ```g:<template path>:<output path>```
    > Example: ```g:input.h.mako:input.generated.h```

* Field template: ```f:<header template path>:<select field regex>:<output path rule>```
    > Example: ```f:input.h.mako:CSMsg.mcs_.*_req:input.generated.${xpath_node.get_name().lower()}.h```

## Update dependencies

### mako

```bash
MAKO_VERSION=1.1.0 ;
cd 3rd_party ;
wget https://files.pythonhosted.org/packages/b0/3c/8dcd6883d009f7cae0f3157fb53e9afb05a0d3d33b3db1268ec2e6f4a56b/Mako-$MAKO_VERSION.tar.gz ;
tar -axvf Mako-$MAKO_VERSION.tar.gz ;
rm -rf mako ;
mv Mako-$MAKO_VERSION/mako mako;
chmod 777 -R mako ;
rm -rf Mako-$MAKO_VERSION Mako-$MAKO_VERSION.tar.gz ;
```

### six

```bash
SIX_VERSION=1.12.0 ;
cd 3rd_party ;
wget https://github.com/benjaminp/six/archive/$SIX_VERSION.tar.gz -O six-$SIX_VERSION.tar.gz ;
tar -ax six-$SIX_VERSION.tar.gz ;
cp -f six-$SIX_VERSION/six.py six/six.py ;
chmod 777 -R six ;
rm -rf six-$SIX_VERSION ;
```

### protobuf

```bash
PROTOBUF_VERSION=3.9.1 ;
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
cp -rf protobuf-$PROTOBUF_VERSION/python/dist/protobuf-3.9.1/* protobuf/ ;
chmod 777 -R protobuf ;

```

