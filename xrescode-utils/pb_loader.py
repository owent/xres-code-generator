#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import re
import string

from google.protobuf import descriptor_pb2 as pb2
from google.protobuf import descriptor_pool as _descriptor_pool
from google.protobuf import message_factory as _message_factory

# import xrescode_extensions_v3_pb2 as ext

from mako.runtime import supports_caller

LOCAL_PB_DB_CACHE = dict()

pb_msg_cpp_keywords = set([
  "NULL",
  "alignas",
  "alignof",
  "and",
  "and_eq",
  "asm",
  "auto",
  "bitand",
  "bitor",
  "bool",
  "break",
  "case",
  "catch",
  "char",
  "class",
  "compl",
  "const",
  "constexpr",
  "const_cast",
  "continue",
  "decltype",
  "default",
  "delete",
  "do",
  "double",
  "dynamic_cast",
  "else",
  "enum",
  "explicit",
  "export",
  "extern",
  "false",
  "float",
  "for",
  "friend",
  "goto",
  "if",
  "inline",
  "int",
  "long",
  "mutable",
  "namespace",
  "new",
  "noexcept",
  "not",
  "not_eq",
  "nullptr",
  "operator",
  "or",
  "or_eq",
  "private",
  "protected",
  "public",
  "register",
  "reinterpret_cast",
  "return",
  "short",
  "signed",
  "sizeof",
  "static",
  "static_assert",
  "static_cast",
  "struct",
  "switch",
  "template",
  "this",
  "thread_local",
  "throw",
  "true",
  "try",
  "typedef",
  "typeid",
  "typename",
  "union",
  "unsigned",
  "using",
  "virtual",
  "void",
  "volatile",
  "wchar_t",
  "while",
  "xor",
  "xor_eq"
])

pb_msg_cpp_type_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: "bool",
    pb2.FieldDescriptorProto.TYPE_BYTES: "std::string",
    pb2.FieldDescriptorProto.TYPE_DOUBLE: "double",
    pb2.FieldDescriptorProto.TYPE_ENUM: "int32_t",
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

pb_msg_cs_type_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: "bool",
    pb2.FieldDescriptorProto.TYPE_BYTES: "byte[]",
    pb2.FieldDescriptorProto.TYPE_DOUBLE: "double",
    pb2.FieldDescriptorProto.TYPE_ENUM: "int",
    pb2.FieldDescriptorProto.TYPE_FIXED32: "int",
    pb2.FieldDescriptorProto.TYPE_FIXED64: "long",
    pb2.FieldDescriptorProto.TYPE_FLOAT: "float",
    pb2.FieldDescriptorProto.TYPE_INT32: "int",
    pb2.FieldDescriptorProto.TYPE_INT64: "long",
    pb2.FieldDescriptorProto.TYPE_SFIXED32: "int",
    pb2.FieldDescriptorProto.TYPE_SFIXED64: "long",
    pb2.FieldDescriptorProto.TYPE_SINT32: "int",
    pb2.FieldDescriptorProto.TYPE_SINT64: "long",
    pb2.FieldDescriptorProto.TYPE_STRING: "string",
    pb2.FieldDescriptorProto.TYPE_UINT32: "uint",
    pb2.FieldDescriptorProto.TYPE_UINT64: "ulong"
}

pb_msg_cpp_type_is_signed_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: False,
    pb2.FieldDescriptorProto.TYPE_BYTES: False,
    pb2.FieldDescriptorProto.TYPE_DOUBLE: True,
    pb2.FieldDescriptorProto.TYPE_ENUM: True,
    pb2.FieldDescriptorProto.TYPE_FIXED32: True,
    pb2.FieldDescriptorProto.TYPE_FIXED64: True,
    pb2.FieldDescriptorProto.TYPE_FLOAT: True,
    pb2.FieldDescriptorProto.TYPE_INT32: True,
    pb2.FieldDescriptorProto.TYPE_INT64: True,
    pb2.FieldDescriptorProto.TYPE_SFIXED32: True,
    pb2.FieldDescriptorProto.TYPE_SFIXED64: True,
    pb2.FieldDescriptorProto.TYPE_SINT32: True,
    pb2.FieldDescriptorProto.TYPE_SINT64: True,
    pb2.FieldDescriptorProto.TYPE_STRING: False,
    pb2.FieldDescriptorProto.TYPE_UINT32: False,
    pb2.FieldDescriptorProto.TYPE_UINT64: False,
    pb2.FieldDescriptorProto.TYPE_MESSAGE: False
}

pb_msg_cpp_fmt_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: "%s",
    pb2.FieldDescriptorProto.TYPE_BYTES: "%s",
    pb2.FieldDescriptorProto.TYPE_DOUBLE: "%lf",
    pb2.FieldDescriptorProto.TYPE_ENUM: "%d",
    pb2.FieldDescriptorProto.TYPE_FIXED32: "%d",
    pb2.FieldDescriptorProto.TYPE_FIXED64: "%lld",
    pb2.FieldDescriptorProto.TYPE_FLOAT: "%f",
    pb2.FieldDescriptorProto.TYPE_INT32: "%d",
    pb2.FieldDescriptorProto.TYPE_INT64: "%lld",
    pb2.FieldDescriptorProto.TYPE_SFIXED32: "%d",
    pb2.FieldDescriptorProto.TYPE_SFIXED64: "%lld",
    pb2.FieldDescriptorProto.TYPE_SINT32: "%d",
    pb2.FieldDescriptorProto.TYPE_SINT64: "%lld",
    pb2.FieldDescriptorProto.TYPE_STRING: "%s",
    pb2.FieldDescriptorProto.TYPE_UINT32: "%u",
    pb2.FieldDescriptorProto.TYPE_UINT64: "%u",
    pb2.FieldDescriptorProto.TYPE_MESSAGE: "%s"
}

pb_msg_cpp_fmt_val_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: "({0}?\"true\": \"false\")",
    pb2.FieldDescriptorProto.TYPE_BYTES: "\"BYTES: {0}\"",
    pb2.FieldDescriptorProto.TYPE_DOUBLE: "{0}",
    pb2.FieldDescriptorProto.TYPE_ENUM: "static_cast<int>({0})",
    pb2.FieldDescriptorProto.TYPE_FIXED32: "static_cast<int>({0})",
    pb2.FieldDescriptorProto.TYPE_FIXED64: "static_cast<long long>({0})",
    pb2.FieldDescriptorProto.TYPE_FLOAT: "{0}",
    pb2.FieldDescriptorProto.TYPE_INT32: "static_cast<int>({0})",
    pb2.FieldDescriptorProto.TYPE_INT64: "static_cast<long long>({0})",
    pb2.FieldDescriptorProto.TYPE_SFIXED32: "static_cast<int>({0})",
    pb2.FieldDescriptorProto.TYPE_SFIXED64: "static_cast<long long>({0})",
    pb2.FieldDescriptorProto.TYPE_SINT32: "static_cast<int>({0})",
    pb2.FieldDescriptorProto.TYPE_SINT64: "static_cast<long long>({0})",
    pb2.FieldDescriptorProto.TYPE_STRING: "{0}.c_str()",
    pb2.FieldDescriptorProto.TYPE_UINT32: "static_cast<unsigned int>({0})",
    pb2.FieldDescriptorProto.TYPE_UINT64:
    "static_cast<unsigned long long>({0})",
    pb2.FieldDescriptorProto.TYPE_MESSAGE: "\"MESSAGE: {0}\""
}

pb_msg_cpp_ue_blueprint_type_map = {
    pb2.FieldDescriptorProto.TYPE_BOOL: "bool",
    pb2.FieldDescriptorProto.TYPE_BYTES: None,
    pb2.FieldDescriptorProto.TYPE_DOUBLE: "float",
    pb2.FieldDescriptorProto.TYPE_ENUM: None,
    pb2.FieldDescriptorProto.TYPE_FIXED32: "int32",
    pb2.FieldDescriptorProto.TYPE_FIXED64: "int64",
    pb2.FieldDescriptorProto.TYPE_FLOAT: "float",
    pb2.FieldDescriptorProto.TYPE_INT32: "int32",
    pb2.FieldDescriptorProto.TYPE_INT64: "int64",
    pb2.FieldDescriptorProto.TYPE_SFIXED32: "int32",
    pb2.FieldDescriptorProto.TYPE_SFIXED64: "int64",
    pb2.FieldDescriptorProto.TYPE_SINT32: "int32",
    pb2.FieldDescriptorProto.TYPE_SINT64: "int64",
    pb2.FieldDescriptorProto.TYPE_STRING: "FString",
    pb2.FieldDescriptorProto.TYPE_UINT32: "int64",
    pb2.FieldDescriptorProto.TYPE_UINT64: "int64"
}

def FirstCharUpper(str):
    return str[0:1].upper() + str[1:]

SPLIT_WORDS_RULE = re.compile("[_\\.:/\\\\]")
LOWERCASE_RULE = re.compile("[a-z]")

def ToCamelName(str):
    strlist = [x for x in filter(lambda x: x, SPLIT_WORDS_RULE.split(str))]
    for i in range(len(strlist)):
        strlist[i] = FirstCharUpper(strlist[i])
    return "".join(strlist)


def PbMsgGetPbFieldVarName(field):
    lower_name = field.name.lower()
    if lower_name in pb_msg_cpp_keywords:
        return lower_name + "_"
    else:
        return lower_name
    
def PbMsgGetPbFieldFn(field):
    return "{0}()".format(PbMsgGetPbFieldVarName(field))

def PbMsgGetPbFieldCppType(field):
    global pb_msg_cpp_type_map
    if field.type in pb_msg_cpp_type_map:
        return pb_msg_cpp_type_map[field.type]
    return field.type_name

def PbMsgGetPbFieldUECppType(field):
    global pb_msg_cpp_ue_blueprint_type_map
    if field.type in pb_msg_cpp_ue_blueprint_type_map:
        return pb_msg_cpp_ue_blueprint_type_map[field.type]
    return field.type_name

def PbMsgGetPbFieldCsType(field):
    global pb_msg_cs_type_map
    if field.type in pb_msg_cs_type_map:
        return pb_msg_cs_type_map[field.type]
    return field.type_name


def PbMsgPbFieldisSigned(field):
    global pb_msg_cpp_type_is_signed_map
    if field.type in pb_msg_cpp_type_is_signed_map:
        return pb_msg_cpp_type_is_signed_map[field.type]
    return False


def PbMsgPbFieldFmt(field):
    global pb_msg_cpp_fmt_map
    if field.type in pb_msg_cpp_fmt_map:
        return pb_msg_cpp_fmt_map[field.type]
    return "%s"


def PbMsgPbFieldFmtValue(field, input):
    global pb_msg_cpp_fmt_val_map
    if field.type in pb_msg_cpp_fmt_val_map:
        return pb_msg_cpp_fmt_val_map[field.type].format(input)
    return "\"UNKNOWN TYPE: {0}\"".format(input)


@supports_caller
def MakoPbMsgGetPbFieldCsType(context, arg):
    return PbMsgGetPbFieldCsType(arg)

@supports_caller
def MakoFirstCharUpper(context, arg):
    return FirstCharUpper(arg)

@supports_caller
def MakoToCamelName(context, str):
    return ToCamelName(str)


@supports_caller
def MakoPbMsgGetCppFieldVarName(context, arg):
    return PbMsgGetPbFieldVarName(arg)

@supports_caller
def MakoPbMsgGetCppField(context, arg):
    return PbMsgGetPbFieldFn(arg)

@supports_caller
def MakoPbMsgGetPbFieldCppType(context, arg):
    return PbMsgGetPbFieldCppType(arg)

@supports_caller
def MakoPbMsgGetPbFieldUECppType(context, arg):
    return PbMsgGetPbFieldUECppType(arg)

@supports_caller
def CppNamespaceBegin(context, arg):
    return "\n".join([("namespace {0}".format(x) + " {")
                     for x in arg.split(".")])

@supports_caller
def CppNamespaceEnd(context, arg):
    return "\n".join([("{0}  // namespace {1}".format("}", x))
                     for x in arg.split(".")])

@supports_caller
def CppFullPath(context, arg):
    return "".join(["{0}::".format(x) for x in arg.split(".")])


@supports_caller
def CsNamespaceBegin(context, arg):
    return CppNamespaceBegin(context, arg)


@supports_caller
def CsNamespaceEnd(context, arg):
    return CppNamespaceEnd(context, arg)


class PbDatabase(object):
    def __init__(self):
        self.raw_files = dict()
        self.raw_symbols = dict()
        self.default_factory = _message_factory.MessageFactory(
            _descriptor_pool.Default())
        self.extended_factory = _message_factory.MessageFactory()
        self.extended_well_known_files = []
        self._cache_files = dict()
        self._cache_messages = dict()
        self._cache_enums = dict()
        self._cache_services = dict()

    def _register_by_pb_fds(self, factory, file_protos):
        file_by_name = {
            file_proto.name: file_proto
            for file_proto in file_protos
        }
        added_file = set()

        def _AddFile(file_proto):
            if file_proto.name in added_file:
                return
            added_file.add(file_proto.name)
            try:
                _already_exists = factory.pool.FindFileByName(file_proto.name)
                return
            except KeyError as _:
                pass
            for dependency in file_proto.dependency:
                if dependency in file_by_name:
                    # Remove from elements to be visited, in order to cut cycles.
                    _AddFile(file_by_name.pop(dependency))
            factory.pool.Add(file_proto)

        while file_by_name:
            _AddFile(file_by_name.popitem()[1])
        # call GetMessages to register all types
        return factory.GetMessages(
            [file_proto.name for file_proto in file_protos])

    def _extended_raw_message(self, package, message_proto):
        self.raw_symbols["{0}.{1}".format(package,
                                          message_proto.name)] = message_proto
        for enum_type in message_proto.enum_type:
            self._extended_raw_enum(
                "{0}.{1}".format(package, message_proto.name), enum_type)
        for nested_type in message_proto.nested_type:
            self._extended_raw_message(
                "{0}.{1}".format(package, message_proto.name), nested_type)
        for extension in message_proto.extension:
            self.raw_symbols["{0}.{1}.{2}".format(package, message_proto.name,
                                                  extension.name)] = extension
        for field in message_proto.field:
            self.raw_symbols["{0}.{1}.{2}".format(package, message_proto.name,
                                                  field.name)] = field
        for oneof_decl in message_proto.oneof_decl:
            self.raw_symbols["{0}.{1}.{2}".format(
                package, message_proto.name, oneof_decl.name)] = oneof_decl

    def _extended_raw_enum(self, package, enum_type):
        self.raw_symbols["{0}.{1}".format(package, enum_type.name)] = enum_type
        for enum_value in enum_type.value:
            self.raw_symbols["{0}.{1}.{2}".format(
                package, enum_type.name, enum_value.name)] = enum_value

    def _extended_raw_service(self, package, service_proto):
        self.raw_symbols["{0}.{1}".format(package,
                                          service_proto.name)] = service_proto
        for method in service_proto.method:
            self.raw_symbols["{0}.{1}.{2}".format(package, service_proto.name,
                                                  method.name)] = method

    def _extended_raw_file(self, file_proto):
        for enum_type in file_proto.enum_type:
            self._extended_raw_enum(file_proto.package, enum_type)
        for extension in file_proto.extension:
            self.raw_symbols["{0}.{1}".format(file_proto.package,
                                              extension.name)] = extension
        for message_type in file_proto.message_type:
            self._extended_raw_message(file_proto.package, message_type)
        for service in file_proto.service:
            self._extended_raw_service(file_proto.package, service)

    def load(self, pb_file_paths):

        # Add well known types for extend factory.
        from google.protobuf import (
            descriptor_pb2,
            any_pb2,
            api_pb2,
            duration_pb2,
            empty_pb2,
            field_mask_pb2,
            source_context_pb2,
            struct_pb2,
            timestamp_pb2,
            type_pb2,
            wrappers_pb2,
        )
        protobuf_well_known_types = []
        protobuf_well_known_type_descriptors = dict({
            descriptor_pb2.DESCRIPTOR.name:
            descriptor_pb2.DESCRIPTOR.serialized_pb,
            any_pb2.DESCRIPTOR.name:
            any_pb2.DESCRIPTOR.serialized_pb,
            api_pb2.DESCRIPTOR.name:
            api_pb2.DESCRIPTOR.serialized_pb,
            duration_pb2.DESCRIPTOR.name:
            duration_pb2.DESCRIPTOR.serialized_pb,
            empty_pb2.DESCRIPTOR.name:
            empty_pb2.DESCRIPTOR.serialized_pb,
            field_mask_pb2.DESCRIPTOR.name:
            field_mask_pb2.DESCRIPTOR.serialized_pb,
            source_context_pb2.DESCRIPTOR.name:
            source_context_pb2.DESCRIPTOR.serialized_pb,
            struct_pb2.DESCRIPTOR.name:
            struct_pb2.DESCRIPTOR.serialized_pb,
            timestamp_pb2.DESCRIPTOR.name:
            timestamp_pb2.DESCRIPTOR.serialized_pb,
            type_pb2.DESCRIPTOR.name:
            type_pb2.DESCRIPTOR.serialized_pb,
            wrappers_pb2.DESCRIPTOR.name:
            wrappers_pb2.DESCRIPTOR.serialized_pb,
        })

        pb_file_buffer_list = [open(x, "rb").read() for x in pb_file_paths]
        pb_fds_patched = []
        pb_fds_list = [
            pb2.FileDescriptorSet.FromString(x) for x in pb_file_buffer_list
        ]
        for pb_fds in pb_fds_list:
            pb_fds_patched.extend([x for x in pb_fds.file])

        for x in pb_fds_patched:
            if x.name in protobuf_well_known_type_descriptors:
                protobuf_well_known_type_descriptors[x.name] = None

        for patch_inner_name in protobuf_well_known_type_descriptors:
            patch_inner_pb_data = protobuf_well_known_type_descriptors[
                patch_inner_name]
            if patch_inner_pb_data is not None:
                protobuf_well_known_types.append(
                    pb2.FileDescriptorProto.FromString(patch_inner_pb_data))

        pb_fds_patched.extend(protobuf_well_known_types)
        self._register_by_pb_fds(self.default_factory, pb_fds_patched)

        # Extend the pool with the extended factory.
        pb_fds_patched = []
        pb_fds_list = [
            pb2.FileDescriptorSet.FromString(x) for x in pb_file_buffer_list
        ]
        for pb_fds in pb_fds_list:
            pb_fds_patched.extend([x for x in pb_fds.file])
            for file_proto in pb_fds.file:
                self.raw_files[file_proto.name] = file_proto
                self._extended_raw_file(file_proto)

        pb_fds_patched.extend(protobuf_well_known_types)
        self._register_by_pb_fds(self.extended_factory, pb_fds_patched)
        self.extended_well_known_files = protobuf_well_known_types

        # Clear all caches
        self._cache_files.clear()
        self._cache_enums.clear()
        self._cache_messages.clear()
        self._cache_services.clear()

        return pb_fds

    def get_raw_file_descriptors(self):
        return self.raw_files

    def get_raw_symbol(self, full_name):
        if full_name in self.raw_symbols:
            return self.raw_symbols[full_name]
        return None

    def get_file(self, name):
        if name in self._cache_files:
            return self._cache_files[name]

        file_desc = self.extended_factory.pool.FindFileByName(name)
        if file_desc is None:
            return None
        return file_desc

    def get_service(self, full_name):
        if not full_name:
            return None
        if full_name in self._cache_services:
            return self._cache_services[full_name]
        target_desc = self.extended_factory.pool.FindServiceByName(full_name)
        if target_desc is None:
            return None
        return target_desc

    def get_message(self, full_name):
        if not full_name:
            return None
        if full_name in self._cache_messages:
            return self._cache_messages[full_name]
        target_desc = self.extended_factory.pool.FindMessageTypeByName(
            full_name)
        if target_desc is None:
            return None
        return target_desc

    def get_enum(self, full_name):
        if not full_name:
            return None
        if full_name in self._cache_enums:
            return self._cache_enums[full_name]
        target_desc = self.extended_factory.pool.FindEnumTypeByName(full_name)
        if target_desc is None:
            return None
        return target_desc

    def get_extension(self, full_name):
        if not full_name:
            return None
        if full_name in self._cache_enums:
            return self._cache_enums[full_name]
        target_desc = self.default_factory.pool.FindExtensionByName(full_name)

        if target_desc is None:
            return None
        return target_desc


class PbMsgIndexType:
    def __init__(self, kv, kl, iv, il):
        self.KV = kv  # XRESCODE_GENERATOR_INDEX_TYPE.values_by_name['EN_INDEX_KV']
        self.KL = kl  # XRESCODE_GENERATOR_INDEX_TYPE.values_by_name['EN_INDEX_KL']
        self.IV = iv  # XRESCODE_GENERATOR_INDEX_TYPE.values_by_name['EN_INDEX_IV']
        self.IL = il  # XRESCODE_GENERATOR_INDEX_TYPE.values_by_name['EN_INDEX_IL']


class PbMsgIndex:
    def __init__(self, pb_msg, pb_ext_index, index_set):
        self.name = None
        self.index_set = index_set
        if pb_ext_index.name:
            self.name = pb_ext_index.name
        else:
            self.name = "_".join(pb_ext_index.fields).lower()

        self.camelname = ToCamelName(self.name)

        self.file_mapping = pb_ext_index.file_mapping
        self.allow_not_found = pb_ext_index.allow_not_found
        self.get_file_expression = None
        # self.index_type
        self.fields = []
        for fd in pb_ext_index.fields:
            pb_fd = None
            for test_pb_fd in pb_msg.fields:
                if test_pb_fd.name == fd:
                    pb_fd = test_pb_fd
                    break
            if pb_fd is None:
                sys.stderr.write(
                    '[XRESCODE ERROR] index {0} invalid, because field {1} is not found in {2}\n'
                    .format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            if pb_fd.label == pb_fd.LABEL_REPEATED:
                sys.stderr.write(
                    '[XRESCODE ERROR] index {0} invalid, field {1} in {2} must not be repeated\n'
                    .format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            if pb_fd.type == pb_fd.TYPE_MESSAGE:
                sys.stderr.write(
                    '[XRESCODE ERROR] index {0} invalid, field {1} in {2} must not be message\n'
                    .format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            self.fields.append(pb_fd)

        if pb_ext_index.index_type:
            self.index_type = pb_ext_index.index_type
        else:
            self.index_type = self.index_set.KV.number

    def is_valid(self):
        if len(self.fields) <= 0:
            return False
        if self.index_type == self.index_set.IV or self.index_type == self.index_set.IL:
            if len(self.fields) != 1:
                sys.stderr.write(
                    '[XRESCODE ERROR] index {0} invalid, vector index only can has only 1 integer key field\n'
                    .format(self.name))
                return False
        return True

    def is_list(self):
        return self.index_type == self.index_set.KL.number or self.index_type == self.index_set.IL.number

    def is_vector(self):
        return self.index_type == self.index_set.IV.number or self.index_type == self.index_set.IL.number

    def get_key_decl(self):
        decls = []
        for fd in self.fields:
            decls.append("{0} {1}".format(PbMsgGetPbFieldCppType(fd), fd.name))
        return ", ".join(decls)

    def get_cs_key_decl(self):
        decls = []
        for fd in self.fields:
            decls.append("{0} {1}".format(PbMsgGetPbFieldCsType(fd),
                                          ToCamelName(fd.name)))
        return ", ".join(decls)

    def get_key_params(self):
        decls = []
        for fd in self.fields:
            decls.append(fd.name)
        return ", ".join(decls)

    def get_key_names(self, quote='"'):
        decls = []
        for fd in self.fields:
            decls.append(fd.name)
        return quote + (quote + ", " + quote).join(decls) + quote

    def get_cs_key_params(self):
        decls = []
        for fd in self.fields:
            decls.append(ToCamelName(fd.name))
        return ", ".join(decls)

    def get_load_file_code(self, var_name):
        code_lines = []
        code_lines.append("std::string {0};".format(var_name))
        code_lines.append("do {")

        if not self.get_file_expression:
            fileds_mapping = dict()
            for fd in self.fields:
                fileds_mapping[fd.name.lower()] = fd.name
            self.get_file_expression = []
            self.get_file_expression.append(
                "    std::stringstream {0}_generated_file_path;".format(
                    self.name))
            if self.file_mapping:
                next_index = 0
                for mo in re.finditer('\{\s*([\w_]+)s*\}', self.file_mapping):
                    key_var_name = mo.group(1).lower()
                    if key_var_name not in fileds_mapping:
                        sys.stderr.write(
                            "[XRESCODE ERROR] {0} in file_mapping is not exists in key fields of index {1}\n",
                            mo.group(1), self.name)
                    else:
                        if next_index < mo.start():
                            self.get_file_expression.append(
                                "    {0}_generated_file_path<< \"{1}\";".
                                format(
                                    self.name,
                                    self.file_mapping[next_index:mo.start()]))
                        self.get_file_expression.append(
                            "    {0}_generated_file_path<< {1};".format(
                                self.name, fileds_mapping[key_var_name]))

                    next_index = mo.end()
                if next_index < len(self.file_mapping):
                    self.get_file_expression.append(
                        "    {0}_generated_file_path<< \"{1}\";".format(
                            self.name, self.file_mapping[next_index:]))
            else:
                self.get_file_expression.append(
                    "    {0}_generated_file_path << \"{0}\";".format(
                        self.name))
        code_lines.extend(self.get_file_expression)
        code_lines.append("    {0} = {1}_generated_file_path.str();".format(
            var_name, self.name))
        code_lines.append("} while (false);")
        return code_lines

    def get_cs_load_file_code(self, var_name):
        code_lines = []
        code_lines.append("\tstring {0};".format(var_name))

        if not self.get_file_expression:
            fileds_mapping = dict()
            for fd in self.fields:
                fileds_mapping[fd.name.lower()] = fd.name
            self.get_file_expression = []
            self.get_file_expression.append(
                "    StringBuilder {0}_generated_file_path = new StringBuilder();"
                .format(self.name))
            if self.file_mapping:
                next_index = 0
                for mo in re.finditer('\{\s*([\w_]+)s*\}', self.file_mapping):
                    key_var_name = mo.group(1).lower()
                    if key_var_name not in fileds_mapping:
                        sys.stderr.write(
                            "[XRESCODE ERROR] {0} in file_mapping is not exists in key fields of index {1}\n",
                            mo.group(1), self.name)
                    else:
                        if next_index < mo.start():
                            self.get_file_expression.append(
                                "    {0}_generated_file_path.Append(\"{1}\");".
                                format(
                                    self.name,
                                    self.file_mapping[next_index:mo.start()]))
                        self.get_file_expression.append(
                            "    {0}_generated_file_path.Append({1});".format(
                                self.name, fileds_mapping[key_var_name]))

                    next_index = mo.end()
                if next_index < len(self.file_mapping):
                    self.get_file_expression.append(
                        "    {0}_generated_file_path.Append(\"{1}\");".format(
                            self.name, self.file_mapping[next_index:]))
            else:
                self.get_file_expression.append(
                    "    {0}_generated_file_path.Append(\"{0}\");".format(
                        self.name))
        code_lines.extend(self.get_file_expression)
        code_lines.append(
            "    {0} = {1}_generated_file_path.ToString();".format(
                var_name, self.name))
        return code_lines

    def get_key_params_fmt_value_list(self):
        decls = []
        for fd in self.fields:
            decls.append(PbMsgPbFieldFmtValue(fd, fd.name))
        return ", ".join(decls)

    def get_key_type_list(self):
        decls = []
        for fd in self.fields:
            decls.append(PbMsgGetPbFieldCppType(fd))
        return ", ".join(decls)

    def get_cs_key_type_list(self):
        decls = []
        for fd in self.fields:
            decls.append(PbMsgGetPbFieldCsType(fd))
        return ", ".join(decls)

    def get_key_value_list(self, prefix=''):
        decls = []
        for fd in self.fields:
            decls.append("{0}{1}".format(prefix, PbMsgGetPbFieldFn(fd)))
        return ", ".join(decls)

    def get_key_fmt_list(self):
        decls = []
        for fd in self.fields:
            decls.append(PbMsgPbFieldFmt(fd))
        return ", ".join(decls)

    def get_key_fmt_value_list(self, prefix=''):
        decls = []
        for fd in self.fields:
            decls.append(
                PbMsgPbFieldFmtValue(
                    fd, "{0}{1}".format(prefix, PbMsgGetPbFieldFn(fd))))
        return ", ".join(decls)


class PbMsgCodeExt:
    def __init__(self, outer_file, outer_msg, inner_file, inner_msg, loader,
                 package, index_set):
        self.outer_file = outer_file
        self.outer_msg = outer_msg
        self.inner_file = inner_file
        self.inner_msg = inner_msg
        self.invalid_index_count = 0
        self.file_list = None
        self.file_path = None
        self.indexes = []
        self.tags = set()
        self.class_name = inner_msg.name
        self.loader = loader
        self.package = package
        self.index_set = index_set

        if not self.loader:
            return

        if self.loader.file_list:
            self.file_list = self.loader.file_list

        if self.loader.file_path:
            self.file_path = self.loader.file_path

        if self.loader.indexes:
            for idx in self.loader.indexes:
                index = PbMsgIndex(inner_msg, idx, self.index_set)
                if index.is_valid():
                    self.indexes.append(index)
                else:
                    self.invalid_index_count = self.invalid_index_count + 1

        if self.loader.tags:
            for tag in self.loader.tags:
                self.tags.add(tag)

        if self.loader.class_name:
            self.class_name = self.loader.class_name

    def is_valid(self):
        if self.outer_msg is None or self.inner_msg is None:
            return False
        return self.file_list is not None or self.file_path is not None


class PbMsgLoader:
    def __init__(self, pb_file, pb_msg, msg_prefix, nested_from_prefix,
                 pb_loader, index_set):
        self.pb_file = pb_file
        self.pb_msg = pb_msg
        self.msg_prefix = msg_prefix
        self.nested_from_prefix = nested_from_prefix
        self.full_name = pb_msg.name
        self.extended_nested_name = pb_msg.name
        if nested_from_prefix:
            self.full_name = nested_from_prefix + self.full_name
            self.extended_nested_name = (nested_from_prefix + self.extended_nested_name).replace(".", "_")
        self.extended_nested_full_name = self.extended_nested_name
        if pb_file.package:
            self.full_name = '{0}.{1}'.format(pb_file.package, pb_msg.name)
            self.extended_nested_full_name = '{0}.{1}'.format(pb_file.package, self.extended_nested_name)
        self.code = None
        self.code_field = None
        self.pb_outer_class_name = None
        self.pb_inner_class_name = None
        self.cpp_class_name = None
        self.cpp_class_full_name = None
        self.cpp_if_guard_name = None
        self.cs_class_name = None
        self.cs_pb_inner_class_name = None
        self.cs_pb_outer_class_name = None
        self.pb_loader = pb_loader
        self.index_set = index_set

    def setup_code(self, fds):
        if not self.pb_loader:
            return

        if self.pb_file.package == 'google.protobuf':
            return

        if self.pb_loader.code_field:
            code_ext = None
            for fd in self.pb_msg.field:
                if fd.name == self.pb_loader.code_field:
                    if not fd.type == pb2.FieldDescriptorProto.TYPE_MESSAGE or not fd.label == pb2.FieldDescriptorProto.LABEL_REPEATED:
                        fds.add_failed_count()
                        sys.stderr.write(
                            '[XRESCODE ERROR] code field {0} of {1} must be repeated message\n'
                            .format(fd.name, self.full_name))
                        break
                    inner_msg = fds.get_msg_by_type(fd.type_name)
                    if inner_msg is None:
                        fds.add_failed_count()
                        sys.stderr.write(
                            '[XRESCODE ERROR] can not find message {0} for code field {1} of {2}\n'
                            .format(fd.type_name, fd.name, self.full_name))
                        break
                    code_ext = PbMsgCodeExt(self.pb_file, self.pb_msg,
                                            inner_msg.pb_file,
                                            inner_msg.pb_msg, self.pb_loader,
                                            self.pb_file.package,
                                            self.index_set)
                    break
            if code_ext is None:
                fds.add_failed_count()
                sys.stderr.write(
                    '[XRESCODE ERROR] code field {0} can not be found in {1}\n'
                    .format(self.pb_loader.code_field, self.full_name))
        else:
            code_ext = PbMsgCodeExt(fds.shared_outer_msg.pb_file,
                                    fds.shared_outer_msg.pb_msg, self.pb_file,
                                    self.pb_msg, self.pb_loader,
                                    self.pb_file.package, self.index_set)

        if code_ext and code_ext.is_valid():
            self.code = code_ext
            if not self.code_field:
                self.code_field = fds.shared_code_field

        if self.code is None:
            if self.pb_loader.file_list:
                fds.add_failed_count()
                print(
                    '[XRESCODE WARNING] message {0} has file_list but without valid field, ignored'
                    .format(self.full_name))
            if self.pb_loader.file_path:
                fds.add_failed_count()
                print(
                    '[XRESCODE WARNING] message {0} has file_path but without valid field, ignored'
                    .format(self.full_name))
        else:
            if self.code.invalid_index_count > 0:
                fds.add_failed_count()
            if self.code.file_list and self.code.file_path:
                fds.add_failed_count()
                print(
                    '[XRESCODE WARNING] message {0} has both file_list and file_path, should only has one'
                    .format(self.full_name))

    def has_code(self):
        return self.code is not None

    def get_upb_lua_path(self):
        base_file = self.pb_file.name
        suffix_pos = base_file.rfind('.')
        if suffix_pos < 0:
            return base_file.replace('/', '.').replace('\\', '.') + "_pb"
        else:
            return base_file[0:suffix_pos].replace('/', '.').replace(
                '\\', '.') + "_pb"

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
        cpp_package_prefix = self.code.outer_file.package.replace(".", "::")
        if cpp_package_prefix:
            self.pb_outer_class_name = "::" + cpp_package_prefix + "::" + self.code.outer_msg.name
        else:
            self.pb_outer_class_name = "::" + self.code.outer_msg.name
        return self.pb_outer_class_name

    def get_pb_inner_class_name(self):
        if self.pb_inner_class_name is not None:
            return self.pb_inner_class_name

        if self.code is None:
            return ""
        cpp_package_prefix = self.code.inner_file.package.replace(".", "::")
        if cpp_package_prefix:
            self.pb_inner_class_name = "::" + cpp_package_prefix + "::" + self.code.inner_msg.name
        else:
            self.pb_inner_class_name = "::" + self.code.inner_msg.name
        return self.pb_inner_class_name

    def get_cpp_class_name(self):
        if self.cpp_class_name is not None:
            return self.cpp_class_name

        if self.code is None:
            return ""

        if self.msg_prefix:
            self.cpp_class_name = "{0}{1}".format(self.msg_prefix,
                                                  self.code.class_name)
        else:
            self.cpp_class_name = self.code.class_name
        return self.cpp_class_name

    def get_cs_class_name(self):
        if self.cs_class_name is not None:
            return self.cs_class_name

        if self.code is None:
            return ""

        if self.msg_prefix:
            self.cs_class_name = "{0}{1}".format(self.msg_prefix,
                                                 self.code.class_name)
        else:
            self.cs_class_name = self.code.class_name
        return self.cs_class_name

    def get_cs_pb_outer_class_name(self):
        if self.cs_pb_outer_class_name is not None:
            return self.pb_outer_class_name

        if self.code is None:
            return ""

        cs_package_prefix = self.code.outer_file.package
        if cs_package_prefix:
            cs_arr = self.code.outer_file.package.split('.')
            for i in range(len(cs_arr)):
                cs_arr[i] = FirstCharUpper(cs_arr[i])
            cs_package_prefix = '.'.join(cs_arr)
            self.cs_pb_outer_class_name = cs_package_prefix + "." + self.code.outer_msg.name
        else:
            self.cs_pb_outer_class_name = self.code.outer_msg.name
        return self.cs_pb_outer_class_name

    def get_cs_pb_inner_class_name(self):
        if self.cs_pb_inner_class_name is not None:
            return self.cs_pb_inner_class_name

        if self.code is None:
            return ""

        cs_package_prefix = self.code.inner_file.package
        if cs_package_prefix:
            self.cs_pb_inner_class_name = cs_package_prefix + "." + self.code.inner_msg.name
        else:
            self.cs_pb_inner_class_name = self.code.inner_msg.name
        return self.cs_pb_inner_class_name

    def get_cpp_class_full_name(self):
        if self.cpp_class_full_name is not None:
            return self.cpp_class_full_name

        if self.code is None:
            return ""

        cpp_package_prefix = self.code.package.replace(".", "::")
        if cpp_package_prefix:
            self.cpp_class_full_name = cpp_package_prefix + "::" + self.get_cpp_class_name(
            )
        else:
            self.cpp_class_full_name = self.get_cpp_class_name()

        return self.cpp_class_full_name

    def get_cpp_namespace_decl_begin(self):
        if self.code is None:
            return ""

        if not self.code.package:
            return ""

        package_names = self.code.package.strip().split(".")
        if not package_names:
            return ""

        ns_ls = []
        for ns in package_names:
            ns_ls.append("namespace {0} {1}".format(ns, "{"))
        return "\n".join(ns_ls)

    def get_cpp_namespace_decl_end(self):
        if self.code is None:
            return ""

        if not self.code.package:
            return ""

        package_names = self.code.package.strip().split(".")
        if not package_names:
            return ""

        ns_ls = []
        for ns in package_names:
            ns_ls.append("{0}  // namespace {1}".format("}", ns))
        return "\n".join(ns_ls)

    def get_cpp_if_guard_name(self):
        if self.cpp_if_guard_name is not None:
            return self.cpp_if_guard_name
        self.cpp_if_guard_name = "_" + self.get_cpp_class_full_name().replace(
            "::", "_").upper()
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

    def get_camel_code_field_name(self):
        return ToCamelName(self.code_field.name)

class PbFile:
    def __init__(self, db, pb_file, index_set):
        self.db = db
        self.name = pb_file.name
        self.base_name = os.path.basename(self.name)
        self.package = pb_file.package
        self.pb_file = db.get_file(self.name)
        self.index_set = index_set
        self.descriptor_proto = pb_file
        self.pb_msgs = dict()
        self.pb_enums = dict()

    def get_file_path_without_ext(self):
        if self.name.endswith(".proto"):
            return self.name[:-len(".proto")]
        return self.name
    
    def get_file_basename_without_ext(self):
        if self.base_name.endswith(".proto"):
            return self.base_name[:-len(".proto")]
        return self.base_name
    
    def get_file_camelname(self):
        return ToCamelName(self.get_file_path_without_ext())
    
    def get_file_base_camelname(self):
        return ToCamelName(self.get_file_basename_without_ext())
    
    def get_file_path_camelname(self, basename_prefix = ""):
        res = os.path.dirname(self.name)
        if res:
            return res + "/" + basename_prefix + self.get_file_base_camelname()
        else:
            return self.get_file_base_camelname()
        
    def get_directory_path(self):
        return os.path.dirname(self.name)
    
    def get_directory_camelname(self):
        return ToCamelName(self.get_directory_path())
    
    def get_cpp_namespace_decl_begin(self):
        if not self.package:
            return ""

        package_names = self.package.strip().split(".")
        if not package_names:
            return ""

        ns_ls = []
        for ns in package_names:
            ns_ls.append("namespace {0} {1}".format(ns, "{"))
        return "\n".join(ns_ls)

    def get_cpp_namespace_decl_end(self):
        if not self.package:
            return ""

        package_names = self.package.strip().split(".")
        if not package_names:
            return ""

        ns_ls = []
        for ns in package_names:
            ns_ls.append("{0}  // namespace {1}".format("}", ns))
        return "\n".join(ns_ls)
    
    def get_field_cpp_protobuf_type(self, pb_field_proto):
        if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_ENUM:
            enum_descriptor_proto = self.db.get_enum(pb_field_proto.type_name)
            if enum_descriptor_proto:
                return pb_field_proto.type_name.replace(".", "::")
            enum_descriptor_proto = self.db.get_enum(self.package + "." + pb_field_proto.type_name)
            if enum_descriptor_proto:
                return (self.package + "." + pb_field_proto.type_name).replace(".", "::")
        elif pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE:
            msg_descriptor_proto = self.db.get_message(pb_field_proto.type_name)
            if msg_descriptor_proto:
                return pb_field_proto.type_name.replace(".", "::")
            msg_descriptor_proto = self.db.get_message(self.package + "." + pb_field_proto.type_name)
            if msg_descriptor_proto:
                return (self.package + "." + pb_field_proto.type_name).replace(".", "::")
        return PbMsgGetPbFieldCppType(pb_field_proto)

class PbEnum:
    def __init__(self, db, pb_file, pb_enum, nested_from_prefix, index_set):
        self.db = db
        self.pb_file = pb_file
        self.nested_from_prefix = nested_from_prefix
        self.full_name = pb_enum.name
        self.extended_nested_name = pb_enum.name
        if nested_from_prefix:
            self.full_name = nested_from_prefix + self.full_name
            self.extended_nested_name = (nested_from_prefix + self.extended_nested_name).replace(".", "_")
        self.extended_nested_full_name = self.extended_nested_name
        if pb_file.package:
            self.full_name = '{0}.{1}'.format(pb_file.package, self.full_name)
            self.extended_nested_full_name = '{0}.{1}'.format(pb_file.package, self.extended_nested_full_name)
        self.pb_enum = db.get_enum(self.full_name)
        self.descriptor_proto = pb_enum
        self.index_set = index_set
        self.enum_value_min = 0
        self.enum_value_max = 0
        for enum_value in pb_enum.value:
            if enum_value.number < self.enum_value_min:
                self.enum_value_min = enum_value.number
            if enum_value.number > self.enum_value_max:
                self.enum_value_max = enum_value.number

    def get_short_prefix(self, use_full_name=False):
        if use_full_name:
            use_name = self.full_name
        else:
            use_name = self.descriptor_proto.name
        ret = "".join([x[0:1].upper() + x[1:].lower() for x in use_name.split('_')])
        return LOWERCASE_RULE.sub("", ret)

class PbMsg:
    def __init__(self, db, pb_file, pb_msg_proto, msg_prefix, nested_from_prefix,
                 index_set):
        self.db = db
        self.pb_file = pb_file
        self.msg_prefix = msg_prefix
        self.nested_from_prefix = nested_from_prefix
        self.full_name = pb_msg_proto.name
        self.extended_nested_name = pb_msg_proto.name
        if nested_from_prefix:
            self.full_name = nested_from_prefix + self.full_name
            self.extended_nested_name = (nested_from_prefix + self.extended_nested_name).replace(".", "_")
        self.extended_nested_full_name = self.extended_nested_name
        if pb_file.package:
            self.full_name = '{0}.{1}'.format(pb_file.package, self.full_name)
            self.extended_nested_full_name = '{0}.{1}'.format(pb_file.package, self.extended_nested_full_name)
        self.pb_msg = db.get_message(self.full_name)
        self.descriptor_proto = pb_msg_proto
        self.loaders = []
        self.index_set = index_set

    def setup_code(self, fds, include_tags, exclude_tags):
        if self.pb_file.package == 'google.protobuf':
            return

        loader_extension = self.db.get_extension('xrescode.loader')
        if loader_extension not in self.pb_msg.GetOptions().Extensions:
            return

        for loader in self.pb_msg.GetOptions().Extensions[loader_extension]:
            skip_message = False
            if exclude_tags:
                for tag in exclude_tags:
                    if tag in loader.tags:
                        skip_message = True
                        break
            if skip_message:
                continue
            if include_tags:
                skip_message = True
                for tag in include_tags:
                    if tag in loader.tags:
                        skip_message = False
                        break
            if skip_message:
                continue

            loader_inst = PbMsgLoader(self.pb_file, self.pb_msg,
                                      self.msg_prefix, self.nested_from_prefix,
                                      loader, self.index_set)
            loader_inst.setup_code(fds)
            if loader_inst.has_code():
                self.loaders.append(loader_inst)

    def has_loader(self):
        return len(self.loaders) > 0
    
    def get_pb_header_path(self):
        base_file = os.path.basename(self.pb_file.name)
        suffix_pos = base_file.rfind('.')
        if suffix_pos < 0:
            return base_file + ".pb.h"
        else:
            return base_file[0:suffix_pos] + ".pb.h"
        
    def get_field_cpp_protobuf_type(self, pb_field_proto):
        if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_ENUM:
            enum_descriptor_proto = self.db.get_enum(pb_field_proto.type_name)
            if enum_descriptor_proto:
                return pb_field_proto.type_name.replace(".", "::")
            enum_descriptor_proto = self.db.get_enum(self.full_name + "." + pb_field_proto.type_name)
            if enum_descriptor_proto:
                return (self.full_name + "." + pb_field_proto.type_name).replace(".", "::")
            enum_descriptor_proto = self.db.get_enum(self.pb_file.package + "." + pb_field_proto.type_name)
            if enum_descriptor_proto:
                return (self.pb_file.package + "." + pb_field_proto.type_name).replace(".", "::")
        elif pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE:
            msg_descriptor_proto = self.db.get_message(pb_field_proto.type_name)
            if msg_descriptor_proto:
                return pb_field_proto.type_name.replace(".", "::")
            msg_descriptor_proto = self.db.get_message(self.full_name + "." + pb_field_proto.type_name)
            if msg_descriptor_proto:
                return (self.full_name + "." + pb_field_proto.type_name).replace(".", "::")
            msg_descriptor_proto = self.db.get_message(self.pb_file.package + "." + pb_field_proto.type_name)
            if msg_descriptor_proto:
                return (self.pb_file.package + "." + pb_field_proto.type_name).replace(".", "::")
        return PbMsgGetPbFieldCppType(pb_field_proto)

class PbDescSet:
    def __init__(self,
                 pb_file_paths,
                 tags=[],
                 msg_prefix='',
                 proto_v3=False,
                 pb_include_prefix="",
                 exclude_tags=[],
                 shared_outer_type='org.xresloader.pb.xresloader_datablocks',
                 shared_outer_field='data_block',
                 index_extended_well_known_type=False,
                 index_include_well_known_type=set(),
                 index_exclude_well_known_type=set(),
                 pb_exclude_files=[],
                 pb_exclude_packages=[]):
        self.proto_v3 = proto_v3
        self.pb_include_prefix = pb_include_prefix
        self.custom_variables = dict()
        self.pb_exclude_files = pb_exclude_files
        self.pb_exclude_packages = pb_exclude_packages
        pb_file_has_xrescode_extension = False
        for pb_file_path in pb_file_paths:
            local_pb_fds = pb2.FileDescriptorSet.FromString(
                open(pb_file_path, 'rb').read())
            for pb_file in local_pb_fds.file:
                if os.path.basename(
                        pb_file.name) == "xrescode_extensions_v3.proto":
                    has_xrescode_loader_message = False
                    has_xrescode_loader_extension = False
                    if pb_file.package != "xrescode":
                        continue
                    for message_type in pb_file.message_type:
                        if message_type.name == "xrescode_loader":
                            has_xrescode_loader_message = True
                            break
                    for extension in pb_file.extension:
                        if extension.name == "loader":
                            has_xrescode_loader_extension = True
                            break
                    if has_xrescode_loader_message and has_xrescode_loader_extension:
                        pb_file_has_xrescode_extension = True
                        break
        self.db = PbDatabase()
        if pb_file_has_xrescode_extension:
            self.db.load(pb_file_paths)
        else:
            pendig_to_load_files = [
                os.path.join(os.path.dirname(__file__), '..', 'pb_extension',
                             'xrescode_extensions_v3.pb'), pb_file_path
            ]
            pendig_to_load_files.extend(pb_file_paths)
            self.db.load(pendig_to_load_files)
        self.index_set_type = self.db.get_enum('xrescode.xrescode_index_type')
        self.index_set = PbMsgIndexType(
            self.index_set_type.values_by_name['EN_INDEX_KV'],
            self.index_set_type.values_by_name['EN_INDEX_KL'],
            self.index_set_type.values_by_name['EN_INDEX_IV'],
            self.index_set_type.values_by_name['EN_INDEX_IL'])
        self.generate_message = []
        self.pb_files = dict()
        self.pb_msgs = dict()
        self.pb_enums = dict()
        self.custom_blocks = dict()
        self.failed_count = 0
        self.shared_outer_msg = None
        self.shared_code_field = None
        for k in self.db.get_raw_file_descriptors():
            pb_file_proto = self.db.get_raw_file_descriptors()[k]
            # skip by file pattern
            if self.pb_exclude_files:
                skip_current_file = False
                for file_pattern in self.pb_exclude_files:
                    if file_pattern.match(pb_file_proto.name):
                        skip_current_file = True
                        break
                if skip_current_file:
                    continue
            # skip by package pattern
            if self.pb_exclude_packages and pb_file_proto.package:
                skip_current_file = False
                for package_pattern in self.pb_exclude_packages:
                    if package_pattern.match(pb_file_proto.package):
                        skip_current_file = True
                        break
                if skip_current_file:
                    continue
            pb_file = PbFile(self.db, pb_file_proto, self.index_set)
            for enum_type_proto in pb_file_proto.enum_type:
                pb_enum = PbEnum(self.db, pb_file, enum_type_proto, None, self.index_set)
                self.pb_enums[pb_enum.full_name] = pb_enum
                pb_file.pb_enums[pb_enum.full_name] = pb_enum
            self.pb_files[pb_file_proto.name] = pb_file
        if index_extended_well_known_type or len(index_include_well_known_type) > 0:
            for pb_file_proto in self.db.extended_well_known_files:
                if len(index_include_well_known_type) > 0 and pb_file_proto.name not in index_include_well_known_type:
                    continue
                if pb_file_proto.name in index_exclude_well_known_type:
                    continue
                pb_file = PbFile(self.db, pb_file_proto, self.index_set)
                for enum_type_proto in pb_file_proto.enum_type:
                    pb_enum = PbEnum(self.db, pb_file, enum_type_proto, None, self.index_set)
                    self.pb_enums[pb_enum.full_name] = pb_enum
                    pb_file.pb_enums[pb_enum.full_name] = pb_enum
                self.pb_files[pb_file_proto.name] = pb_file
        for k in self.pb_files:
            pb_file = self.pb_files[k]
            for pb_msg_proto in pb_file.descriptor_proto.message_type:
                pb_msg_inst = self.setup_pb_msg(pb_file, pb_msg_proto, msg_prefix)
                if pb_msg_inst:
                    self.pb_msgs[pb_msg_inst.full_name] = pb_msg_inst
                    pb_file.pb_msgs[pb_msg_inst.full_name] = pb_msg_inst
        self.shared_outer_msg = self.get_msg_by_type(shared_outer_type)
        if self.shared_outer_msg:
            for fd in self.shared_outer_msg.pb_msg.fields:
                if fd.name == shared_outer_field and fd.label == pb2.FieldDescriptorProto.LABEL_REPEATED:
                    self.shared_code_field = fd
                    break
        for k in self.pb_msgs:
            v = self.pb_msgs[k]
            v.setup_code(self, tags, exclude_tags)
            if v.has_loader():
                self.generate_message.append(v)
        self.generate_message.sort(key=lambda x: x.full_name)

    def setup_pb_msg(self, pb_file, pb_msg_proto, msg_prefix, nested_from_prefix=""):
        msg_obj = PbMsg(self.db, pb_file, pb_msg_proto, msg_prefix,
                        nested_from_prefix, self.index_set)
        self.pb_msgs[msg_obj.full_name] = msg_obj
        pb_file.pb_msgs[msg_obj.full_name] = msg_obj
        for nested_type in pb_msg_proto.nested_type:
            self.setup_pb_msg(pb_file, nested_type, msg_prefix,
                              nested_from_prefix + pb_msg_proto.name + ".")
            
        for enum_type_proto in pb_msg_proto.enum_type:
            pb_enum = PbEnum(self.db, pb_file, enum_type_proto, nested_from_prefix + pb_msg_proto.name + ".",
                             self.index_set)
            self.pb_enums[pb_enum.full_name] = pb_enum
            pb_file.pb_enums[pb_enum.full_name] = pb_enum

        return msg_obj

    def get_msg_by_type(self, type_name):
        if type_name and type_name[0:1] == ".":
            type_name = type_name[1:]
        return self.pb_msgs.get(type_name, None)
    
    def get_enum_by_type(self, type_name):
        if type_name and type_name[0:1] == ".":
            type_name = type_name[1:]
        return self.pb_enums.get(type_name, None)
    
    def get_file_by_name(self, name):
        return self.pb_files.get(name, None)

    def get_custom_blocks(self, block_name):
        if block_name in self.custom_blocks:
            return self.custom_blocks[block_name]
        return []

    def add_custom_blocks(self, block_name, block_file):
        if block_name in self.custom_blocks:
            self.custom_blocks[block_name].append(block_file)
        else:
            self.custom_blocks[block_name] = [block_file]

    def add_failed_count(self):
        self.failed_count = self.failed_count + 1

    def get_custom_variable(self, key, default_value=None):
        return self.custom_variables.get(key, default_value)

    def set_custom_variable(self, key, value):
        self.custom_variables[key] = value
