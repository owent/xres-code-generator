#!/bin/bash

cd "$(dirname "$0")";

../xrescode-gen.py -i template -p sample.pb -o pbcpp                      \
    -g template/config_manager.h.mako -g template/config_manager.cpp.mako \
    -m H:template/config_set.h.mako -m S:template/config_set.cpp.mako     \
    "$@"
