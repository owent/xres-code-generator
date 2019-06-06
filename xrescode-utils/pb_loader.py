#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

from google.protobuf import descriptor_pb2 as pb2
import xrescode_extensions_v3_pb2 as ext

def PbMsgGetPbFieldFn(self, field):
    return "{0}()".format(field.name.lower())


pb_msg_cpp_type_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: "bool",
    pb2.FieldDescriptorProto.TYPE_BYTES: "std::string",
    pb2.FieldDescriptorProto.TYPE_DOUBLE: "double",
    pb2.FieldDescriptorProto.TYPE_ENUM: "int",
    pb2.FieldDescriptorProto.TYPE_FIXED32: "int32_t",
    pb2.FieldDescriptorProto.TYPE_FIXED64: "int64_t",
    pb2.FieldDescriptorProto.TYPE_FLOAT: "float",
    pb2.FieldDescriptorProto.TYPE_INT32: "int32_t",
    pb2.FieldDescriptorProto.TYPE_INT64: "int64_t",
    pb2.FieldDescriptorProto.TYPE_SFIXED32: "int32_t",
    pb2.FieldDescriptorProto.TYPE_SFIXED64: "int64_t",
    pb2.FieldDescriptorProto.TYPE_SINT32: "int32_t",
    pb2.FieldDescriptorProto.TYPE_SINT64: "int64_t",
    pb2.FieldDescriptorProto.TYPE_STRING: "std::string",
    pb2.FieldDescriptorProto.TYPE_UINT32: "uint32_t",
    pb2.FieldDescriptorProto.TYPE_UINT64: "uint64_t"
}

def PbMsgGetPbFieldCppType(field):
    global pb_msg_cpp_type_map
    if field.type in pb_msg_cpp_type_map:
        return pb_msg_cpp_type_map[field.type]
    return field.type_name

class PbMsgIndexType:
    KV = ext.EN_INDEX_KV
    KL = ext.EN_INDEX_KL
    IV = ext.EN_INDEX_IV
    IL = ext.EN_INDEX_IL

class PbMsgIndex:
    def __init__(self, pb_msg, pb_ext_index):
        self.name = None
        if pb_ext_index.name:
            self.name = pb_ext_index.name
        else:
            self.name = "_".join(pb_ext_index.fields)

        self.file_mapping = pb_ext_index.file_mapping
        #self.index_type
        self.fields = []
        for fd in pb_ext_index.fields:
            pb_fd = None
            for test_pb_fd in pb_msg.field:
                if test_pb_fd.name == fd:
                    pb_fd = test_pb_fd
                    break
            if pb_fd is None:
                print('[ERROR] index {0} invalid, because field {1} is not found in {2}'.format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            if pb_fd.label == pb_fd.LABEL_REPEATED:
                print('[ERROR] index {0} invalid, field {1} in {2} must not be repeated'.format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            if pb_fd.type == pb_fd.TYPE_MESSAGE:
                print('[ERROR] index {0} invalid, field {1} in {2} must not be message'.format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            self.fields.append(pb_fd)

        if pb_ext_index.index_type:
            self.index_type = pb_ext_index.index_type
        else:
            self.index_type = PbMsgIndexType.KV

    def is_valid(self):
        return len(self.fields) > 0

    def is_list(self):
        return self.index_type == PbMsgIndexType.KL or self.index_type == PbMsgIndexType.IL

    def is_vector(self):
        return self.index_type == PbMsgIndexType.IV or self.index_type == PbMsgIndexType.IL
    
    def get_key_decl(self):
        decls = []
        for fd in self.fields:
            decls.append("{0} {1}".format(PbMsgGetPbFieldCppType(fd), fd.name))
        return ", ".join(decls)

    def get_key_type_list(self):
        decls = []
        for fd in self.fields:
            decls.append(PbMsgGetPbFieldCppType(fd))
        return ", ".join(decls)

class PbMsgCodeExt:
    def __init__(self, outer_msg, inner_msg):
        self.outer_msg = outer_msg
        self.inner_msg = inner_msg
        if outer_msg.options.HasExtension(ext.file_list):
            self.file_list = outer_msg.options.Extensions[ext.file_list]
        else:
            self.file_list = None

        if outer_msg.options.HasExtension(ext.file_path):
            self.file_path = outer_msg.options.Extensions[ext.file_path]
        else:
            self.file_path = None

        self.indexes = []
        for idx in outer_msg.options.Extensions[ext.indexes]:
            index = PbMsgIndex(inner_msg, idx)
            if index.is_valid():
                self.indexes.append(index)

        self.tags = set()
        for tag in outer_msg.options.Extensions[ext.tags]:
            self.tags.add(tag)

        if outer_msg.options.HasExtension(ext.class_name):
            self.class_name = outer_msg.options.Extensions[ext.class_name]
        else:
            self.class_name = inner_msg.name

    def is_valid(self):
        return self.file_list is not None or self.file_path is not None

class PbMsg:
    def __init__(self, pb_file, pb_msg, msg_prefix):
        self.pb_file = pb_file
        self.pb_msg = pb_msg
        self.msg_prefix = msg_prefix
        self.full_name = '{0}.{1}'.format(pb_file.package, pb_msg.name)
        self.cpp_package_prefix = self.pb_file.package.replace(".", "::")
        self.code = None
        self.code_field = None
        self.pb_outer_class_name = None
        self.pb_inner_class_name = None
        self.cpp_class_name = None
        self.cpp_if_guard_name = None

    def setup_code(self, fds):
        for fd in self.pb_msg.field:
            if fd.options.HasExtension(ext.excel_row) and fd.options.Extensions[ext.excel_row]:
                inner_msg = fds.get_msg_by_type(fd.type_name)
                if inner_msg is not None:
                    code_ext = PbMsgCodeExt(self.pb_msg, inner_msg.pb_msg)
                    if code_ext.is_valid():
                        self.code = code_ext
                        self.code_field = fd
                        break
                else:
                    print('[ERROR] excel_row message {0} not found for {1}'.format(fd.type_name, self.full_name))

        if self.code is None:
            if self.pb_msg.options.HasExtension(ext.file_list):
                print('[WARNING] message {0} has file_list but withou excel_row, ignored'.format(self.full_name))
            if self.pb_msg.options.HasExtension(ext.file_path):
                print('[WARNING] message {0} has file_path but withou excel_row, ignored'.format(self.full_name))
        else:
            if self.pb_msg.options.HasExtension(ext.file_list) and self.pb_msg.options.HasExtension(ext.file_path):
                print('[WARNING] message {0} has both file_list and file_path, should only has one'.format(self.full_name))
    def has_code(self):
        return self.code is not None

    def get_pb_header_path(self):
        base_file = os.path.basename(self.pb_file.name)
        suffix_pos = base_file.rfind('.')
        if suffix_pos < 0:
            return base_file + ".pb.h"
        else:
            return base_file[0:suffix_pos] + ".pb.h"


    def get_pb_outer_class_name(self):
        if self.pb_outer_class_name is not None:
            return self.pb_outer_class_name
        self.pb_outer_class_name = self.cpp_package_prefix + "::" + self.pb_msg.name
        return self.pb_outer_class_name

    def get_pb_inner_class_name(self):
        if self.pb_inner_class_name is not None:
            return self.pb_inner_class_name

        if self.code is None:
            return ""
        self.pb_inner_class_name = self.cpp_package_prefix + "::" + self.code.inner_msg.name
        return self.pb_inner_class_name

    def get_cpp_class_name(self):
        if self.cpp_class_name is not None:
            return self.cpp_class_name

        if self.code is None:
            return ""

        if self.msg_prefix:
            self.cpp_class_name = "{0}{1}".format(self.msg_prefix, self.code.class_name)
        else:
            self.cpp_class_name = self.code.class_name
        return self.cpp_class_name

    def get_cpp_class_full_name(self):
        return self.cpp_package_prefix + "::" + self.get_cpp_class_name()

    def get_cpp_if_guard_name(self):
        if self.cpp_if_guard_name is not None:
            return self.cpp_if_guard_name
        self.cpp_if_guard_name = self.get_cpp_class_full_name().replace("::", "_").upper()
        return self.cpp_if_guard_name

    def get_cpp_public_var_name(self):
        if self.code is None:
            return ""
        
        return self.code.class_name.replace(".", "_")

    def get_cpp_private_var_name(self):
        if self.code is None:
            return ""

        return self.code.class_name.replace(".", "_").lower() + "_"

    def get_cpp_header_path(self):
        return "{0}.h".format(self.get_cpp_class_name())

    def get_cpp_source_path(self):
        return "{0}.cpp".format(self.get_cpp_class_name())

class PbDescSet:
    def __init__(self, pb_file_path, tags=[], msg_prefix='', proto_v3 = False):
        self.pb_file = pb_file_path
        self.proto_v3 = proto_v3
        self.pb_fds = pb2.FileDescriptorSet.FromString(open(pb_file_path, 'rb').read())
        self.generate_message = []
        self.pb_msgs = dict()
        for pb_file in self.pb_fds.file:
            for pb_msg in pb_file.message_type:
                msg_obj = PbMsg(pb_file, pb_msg, msg_prefix)
                self.pb_msgs[msg_obj.full_name] = msg_obj
        # print(self.pb_fds.file)
        for k in self.pb_msgs:
            v = self.pb_msgs[k]
            v.setup_code(self)
            if not v.has_code():
                continue
            if tags:
                for tag in tags:
                    if tag in v.tags:
                        self.generate_message.append(v)
                        break        
            else:
                self.generate_message.append(v)

    def get_msg_by_type(self, type_name):
        if type_name and type_name[0:1] == ".":
            type_name = type_name[1:]
        return self.pb_msgs.get(type_name, None)
