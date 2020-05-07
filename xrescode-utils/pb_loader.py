#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import re

from google.protobuf import descriptor_pb2 as pb2
import xrescode_extensions_v3_pb2 as ext

from mako.runtime import supports_caller

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
    pb2.FieldDescriptorProto.TYPE_UINT64: "static_cast<unsgined long long>({0})",
    pb2.FieldDescriptorProto.TYPE_MESSAGE: "\"MESSAGE: {0}\""
}


def FirstCharUpper(str):
    return str[0:1].upper() + str[1:]


def ToCamelName(str):
    strlist = str.split("_")
    for i in range(len(strlist)):
        strlist[i] = FirstCharUpper(strlist[i])
    return "".join(strlist)


def PbMsgGetPbFieldFn(field):
    return "{0}()".format(field.name.lower())


def PbMsgGetPbFieldCppType(field):
    global pb_msg_cpp_type_map
    if field.type in pb_msg_cpp_type_map:
        return pb_msg_cpp_type_map[field.type]
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
            self.name = "_".join(pb_ext_index.fields).lower()

        self.camelname = ToCamelName(self.name)

        self.file_mapping = pb_ext_index.file_mapping
        self.allow_not_found = pb_ext_index.allow_not_found
        self.get_file_expression = None
        # self.index_type
        self.fields = []
        for fd in pb_ext_index.fields:
            pb_fd = None
            for test_pb_fd in pb_msg.field:
                if test_pb_fd.name == fd:
                    pb_fd = test_pb_fd
                    break
            if pb_fd is None:
                sys.stderr.write('[XRESCODE ERROR] index {0} invalid, because field {1} is not found in {2}\n'.format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            if pb_fd.label == pb_fd.LABEL_REPEATED:
                sys.stderr.write('[XRESCODE ERROR] index {0} invalid, field {1} in {2} must not be repeated\n'.format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            if pb_fd.type == pb_fd.TYPE_MESSAGE:
                sys.stderr.write('[XRESCODE ERROR] index {0} invalid, field {1} in {2} must not be message\n'.format(self.name, fd, pb_msg.name))
                self.fields.clear()
                break
            self.fields.append(pb_fd)

        if pb_ext_index.index_type:
            self.index_type = pb_ext_index.index_type
        else:
            self.index_type = PbMsgIndexType.KV

    def is_valid(self):
        if len(self.fields) <= 0:
            return False
        if self.index_type == PbMsgIndexType.IV or self.index_type == PbMsgIndexType.IL:
            if len(self.fields) != 1:
                sys.stderr.write('[XRESCODE ERROR] index {0} invalid, vector index only can has only 1 integer key field\n'.format(self.name))
                return False
        return True

    def is_list(self):
        return self.index_type == PbMsgIndexType.KL or self.index_type == PbMsgIndexType.IL

    def is_vector(self):
        return self.index_type == PbMsgIndexType.IV or self.index_type == PbMsgIndexType.IL

    def get_key_decl(self):
        decls = []
        for fd in self.fields:
            decls.append("{0} {1}".format(PbMsgGetPbFieldCppType(fd), fd.name))
        return ", ".join(decls)

    def get_cs_key_decl(self):
        decls = []
        for fd in self.fields:
            decls.append("{0} {1}".format(
                PbMsgGetPbFieldCsType(fd), ToCamelName(fd.name)))
        return ", ".join(decls)

    def get_key_params(self):
        decls = []
        for fd in self.fields:
            decls.append(fd.name)
        return ", ".join(decls)

    def get_key_names(self, quote = '"'):
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
            self.get_file_expression.append("    std::stringstream {0}_generated_file_path;".format(self.name))
            if self.file_mapping:
                next_index = 0
                for mo in re.finditer('\{\s*([\w_]+)s*\}', self.file_mapping):
                    key_var_name = mo.group(1).lower()
                    if key_var_name not in fileds_mapping:
                        sys.stderr.write("[XRESCODE ERROR] {0} in file_mapping is not exists in key fields of index {1}\n", mo.group(1), self.name)
                    else:
                        if next_index < mo.start():
                            self.get_file_expression.append(
                                "    {0}_generated_file_path<< \"{1}\";".format(self.name, self.file_mapping[next_index:mo.start()])
                            )
                        self.get_file_expression.append(
                            "    {0}_generated_file_path<< {1};".format(self.name, fileds_mapping[key_var_name])
                        )

                    next_index = mo.end()
                if next_index < len(self.file_mapping):
                    self.get_file_expression.append(
                        "    {0}_generated_file_path<< \"{1}\";".format(self.name, self.file_mapping[next_index:])
                    )
            else:
                self.get_file_expression.append("    {0}_generated_file_path << \"{0}\";".format(self.name))
        code_lines.extend(self.get_file_expression)
        code_lines.append("    {0} = {1}_generated_file_path.str();".format(var_name, self.name))
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
            self.get_file_expression.append("    StringBuilder {0}_generated_file_path = new StringBuilder();".format(self.name))
            if self.file_mapping:
                next_index = 0
                for mo in re.finditer('\{\s*([\w_]+)s*\}', self.file_mapping):
                    key_var_name = mo.group(1).lower()
                    if key_var_name not in fileds_mapping:
                        sys.stderr.write("[XRESCODE ERROR] {0} in file_mapping is not exists in key fields of index {1}\n", mo.group(1), self.name)
                    else:
                        if next_index < mo.start():
                            self.get_file_expression.append(
                                "    {0}_generated_file_path.Append(\"{1}\");".format(self.name, self.file_mapping[next_index:mo.start()])
                            )
                        self.get_file_expression.append(
                            "    {0}_generated_file_path.Append({1});".format(self.name, fileds_mapping[key_var_name])
                        )

                    next_index = mo.end()
                if next_index < len(self.file_mapping):
                    self.get_file_expression.append(
                        "    {0}_generated_file_path.Append(\"{1}\");".format(self.name, self.file_mapping[next_index:])
                    )
            else:
                self.get_file_expression.append("    {0}_generated_file_path.Append(\"{0}\");".format(self.name))
        code_lines.extend(self.get_file_expression)
        code_lines.append("    {0} = {1}_generated_file_path.ToString();".format(var_name, self.name))
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
            decls.append(PbMsgPbFieldFmtValue(fd, "{0}{1}".format(prefix, PbMsgGetPbFieldFn(fd))))
        return ", ".join(decls)


class PbMsgCodeExt:
    def __init__(self, outer_file, outer_msg, inner_file, inner_msg, loader, package):
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

        if not self.loader:
            return

        if self.loader.file_list:
            self.file_list = self.loader.file_list

        if self.loader.file_path:
            self.file_path = self.loader.file_path

        if self.loader.indexes:
            for idx in self.loader.indexes:
                index = PbMsgIndex(inner_msg, idx)
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
    def __init__(self, pb_file, pb_msg, msg_prefix, nested_from_prefix, pb_loader):
        self.pb_file = pb_file
        self.pb_msg = pb_msg
        self.msg_prefix = msg_prefix
        self.nested_from_prefix = nested_from_prefix
        self.full_name = pb_msg.name
        if nested_from_prefix:
            self.full_name = nested_from_prefix + self.full_name
        if pb_file.package:
            self.full_name = '{0}.{1}'.format(pb_file.package, pb_msg.name)
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
                        sys.stderr.write('[XRESCODE ERROR] code field {0} of {1} must be repeated message\n'.format(fd.name, self.full_name))
                        break
                    inner_msg = fds.get_msg_by_type(fd.type_name)
                    if inner_msg is None:
                        fds.add_failed_count()
                        sys.stderr.write('[XRESCODE ERROR] can not find message {0} for code field {1} of {2}\n'.format(fd.type_name, fd.name, self.full_name))
                        break
                    code_ext = PbMsgCodeExt(self.pb_file, self.pb_msg, inner_msg.pb_file, inner_msg.pb_msg, self.pb_loader, self.pb_file.package)
                    break
            if code_ext is None:
                fds.add_failed_count()
                sys.stderr.write('[XRESCODE ERROR] code field {0} can not be found in {1}\n'.format(self.pb_loader.code_field, self.full_name))
        else:
            code_ext = PbMsgCodeExt(fds.shared_outer_msg.pb_file, fds.shared_outer_msg.pb_msg, self.pb_file, self.pb_msg, self.pb_loader, self.pb_file.package)

        if code_ext and code_ext.is_valid():
            self.code = code_ext
            if not self.code_field:
                self.code_field = fds.shared_code_field

        if self.code is None:
            if self.pb_loader.file_list:
                fds.add_failed_count()
                print('[XRESCODE WARNING] message {0} has file_list but without valid field, ignored'.format(self.full_name))
            if self.pb_loader.file_path:
                fds.add_failed_count()
                print('[XRESCODE WARNING] message {0} has file_path but without valid field, ignored'.format(self.full_name))
        else:
            if self.code.invalid_index_count > 0:
                fds.add_failed_count()
            if self.code.file_list and self.code.file_path:
                fds.add_failed_count()
                print('[XRESCODE WARNING] message {0} has both file_list and file_path, should only has one'.format(self.full_name))

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
        cpp_package_prefix = self.code.outer_file.package.replace(".", "::")
        if cpp_package_prefix:
            self.pb_outer_class_name =  "::" + cpp_package_prefix + "::" + self.code.outer_msg.name
        else:
            self.pb_outer_class_name =  "::" + self.code.outer_msg.name
        return self.pb_outer_class_name

    def get_pb_inner_class_name(self):
        if self.pb_inner_class_name is not None:
            return self.pb_inner_class_name

        if self.code is None:
            return ""
        cpp_package_prefix = self.code.inner_file.package.replace(".", "::")
        if cpp_package_prefix:
            self.pb_inner_class_name =  "::" + cpp_package_prefix + "::" + self.code.inner_msg.name
        else:
            self.pb_inner_class_name =  "::" + self.code.inner_msg.name
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

    def get_cs_class_name(self):
        if self.cs_class_name is not None:
            return self.cs_class_name

        if self.code is None:
            return ""

        if self.msg_prefix:
            self.cs_class_name = "{0}{1}".format(
                self.msg_prefix, self.code.class_name)
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
            self.cs_pb_outer_class_name =  cs_package_prefix + "." + self.code.outer_msg.name
        else:
            self.cs_pb_outer_class_name =  self.code.outer_msg.name
        return self.cs_pb_outer_class_name

    def get_cs_pb_inner_class_name(self):
        if self.cs_pb_inner_class_name is not None:
            return self.cs_pb_inner_class_name

        if self.code is None:
            return ""

        cs_package_prefix = self.code.inner_file.package
        if cs_package_prefix:
            self.cs_pb_inner_class_name =  cs_package_prefix + "." + self.code.inner_msg.name
        else:
            self.cs_pb_inner_class_name =  self.code.inner_msg.name
        return self.cs_pb_inner_class_name

    def get_cpp_class_full_name(self):
        if self.cpp_class_full_name is not None:
            return self.cpp_class_full_name

        if self.code is None:
            return ""

        cpp_package_prefix = self.code.package.replace(".", "::")
        if cpp_package_prefix:
            self.cpp_class_full_name = "::" + cpp_package_prefix + "::" + self.get_cpp_class_name()
        else:
            self.cpp_class_full_name = "::" + self.get_cpp_class_name()

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
        return " ".join(ns_ls)

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
            ns_ls.append("{0} /*{1}*/".format("}", ns))
        return " ".join(ns_ls)

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

    def get_camel_code_field_name(self):
        return ToCamelName(self.code_field.name)


class PbMsg:
    def __init__(self, pb_file, pb_msg, msg_prefix, nested_from_prefix):
        self.pb_file = pb_file
        self.pb_msg = pb_msg
        self.msg_prefix = msg_prefix
        self.nested_from_prefix = nested_from_prefix
        self.full_name = pb_msg.name
        if nested_from_prefix:
            self.full_name = nested_from_prefix + self.full_name
        if pb_file.package:
            self.full_name = '{0}.{1}'.format(pb_file.package, pb_msg.name)
        self.loaders = []

    def setup_code(self, fds, include_tags, exclude_tags):
        if self.pb_file.package == 'google.protobuf':
            return

        if ext.loader not in self.pb_msg.options.Extensions:
            return
        
        for loader in self.pb_msg.options.Extensions[ext.loader]:
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

            loader_inst = PbMsgLoader(self.pb_file, self.pb_msg, self.msg_prefix, self.nested_from_prefix, loader)
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


class PbDescSet:
    def __init__(self, pb_file_path, tags=[], msg_prefix='', proto_v3 = False, pb_include_prefix="", exclude_tags=[], 
                 shared_outer_type='org.xresloader.pb.xresloader_datablocks', shared_outer_field='data_block'):
        self.pb_file = pb_file_path
        self.proto_v3 = proto_v3
        self.pb_include_prefix = pb_include_prefix
        self.pb_fds = pb2.FileDescriptorSet.FromString(open(pb_file_path, 'rb').read())
        self.generate_message = []
        self.pb_msgs = dict()
        self.custom_blocks = dict()
        self.failed_count = 0
        self.shared_outer_msg = None
        self.shared_code_field = None
        for pb_file in self.pb_fds.file:
            for pb_msg in pb_file.message_type:
                self.setup_pb_msg(pb_file, pb_msg, msg_prefix)
        self.shared_outer_msg = self.get_msg_by_type(shared_outer_type)
        if self.shared_outer_msg:
            for fd in self.shared_outer_msg.pb_msg.field:
                if fd.name == shared_outer_field and fd.label == pb2.FieldDescriptorProto.LABEL_REPEATED:
                    self.shared_code_field = fd
                    break
        # print(self.pb_fds.file)
        for k in self.pb_msgs:
            v = self.pb_msgs[k]
            v.setup_code(self, tags, exclude_tags)
            if v.has_loader():
                self.generate_message.append(v)

    def setup_pb_msg(self, pb_file, pb_msg, msg_prefix, nested_from_prefix = ""):
        msg_obj = PbMsg(pb_file, pb_msg, msg_prefix, nested_from_prefix)
        self.pb_msgs[msg_obj.full_name] = msg_obj
        for nested_type in pb_msg.nested_type:
            self.setup_pb_msg(pb_file, nested_type, msg_prefix, nested_from_prefix + pb_msg.name + ".")

    def get_msg_by_type(self, type_name):
        if type_name and type_name[0:1] == ".":
            type_name = type_name[1:]
        return self.pb_msgs.get(type_name, None)

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
