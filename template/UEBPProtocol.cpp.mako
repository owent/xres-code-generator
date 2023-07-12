## -*- coding: utf-8 -*-
<%!
import time
import os
import re
%><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%namespace name="pb_loader" module="pb_loader"/><%
ue_bp_protocol_type_prefix = pb_set.get_custom_variable("ue_bp_protocol_type_prefix", pb_set.get_custom_variable("ue_type_prefix", ""))
protobuf_include_prefix = pb_set.get_custom_variable("protobuf_include_prefix")
protobuf_include_suffix = pb_set.get_custom_variable("protobuf_include_suffix")
protobuf_namespace_prefix = pb_set.get_custom_variable("protobuf_namespace_prefix", "::google::protobuf")
ue_api_definition = pb_set.get_custom_variable("ue_api_definition")
if ue_api_definition:
  ue_api_definition = ue_api_definition + " "

file_path_prefix = os.path.relpath(output_file, output_dir).replace("\\", "/")
if file_path_prefix.endswith(".cc"):
  file_path_prefix = file_path_prefix[:-3]
elif file_path_prefix.endswith(".cpp") or file_path_prefix.endswith(".cxx"):
  file_path_prefix = file_path_prefix[:-4]
else:
  file_path_prefix = file_path_prefix

ue_excel_loader_include_rule = pb_set.get_custom_variable("ue_excel_loader_include_rule")
if not ue_excel_loader_include_rule:
  ue_excel_loader_include_rule = pb_set.get_custom_variable("ue_include_prefix", "ExcelLoader") + "/%(file_path_camelname)s.h"
ue_bp_protocol_include_rule = pb_set.get_custom_variable("ue_bp_protocol_include_rule")
if not ue_bp_protocol_include_rule:
  ue_bp_protocol_include_rule = pb_set.get_custom_variable("ue_include_prefix", "ExcelLoader") + "/%(file_path_camelname)s.h"
%>// Copyright ${time.strftime("%Y", time.localtime()) } atframework
// Created by xres-code-generator for ${pb_file.name}, please don't edit it
<%
current_file_include_format_args = {
  "file_path_without_ext": pb_file.get_file_path_without_ext(),
  "file_basename_without_ext": pb_file.get_file_basename_without_ext(),
  "file_camelname": pb_file.get_file_camelname(),
  "file_base_camelname": pb_file.get_file_base_camelname(),
  "file_path_camelname": pb_file.get_file_path_camelname(),
  "directory_path": pb_file.get_directory_path(),
  "directory_camelname": pb_file.get_directory_camelname(),
}
current_file_include_path = ue_bp_protocol_include_rule % current_file_include_format_args
current_file_include_path = re.sub("//+", "/", current_file_include_path)

enable_excel_loader = pb_set.get_custom_variable("ue_bp_protocol_support_loader", "").lower()
has_excel_loader = False
if enable_excel_loader != "0" and enable_excel_loader != "no" and enable_excel_loader != "false":
  for message_full_path in pb_file.pb_msgs:
    message_inst = pb_file.pb_msgs[message_full_path]
    if message_inst.has_loader():
      has_excel_loader = True
      break
%>
#include "${current_file_include_path}"

% if protobuf_include_prefix:
// clang-format off
#include "${protobuf_include_prefix}"
// clang-format on
% endif

#include "${pb_file.get_file_path_without_ext()}.pb.h"
% if include_headers:
%   for include_header in include_headers:
#include "${include_header}"
%   endfor
% endif

% if protobuf_include_suffix:
// clang-format off
#include "${protobuf_include_suffix}"
// clang-format on
% endif

% for message_full_path in pb_file.pb_msgs:
<%
message_inst = pb_file.pb_msgs[message_full_path]
message_class_name = ue_excel_utils.UECppUClassName(message_inst, ue_bp_protocol_type_prefix)
if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
  continue
cpp_pb_message_type = message_inst.extended_nested_full_name.replace(".", "::")
%>
// ========================== ${message_class_name} ==========================
${ue_api_definition}${message_class_name}::${message_class_name}() : Super()
{
}

${ue_api_definition}${message_class_name}& ${message_class_name}::operator=(const ${message_inst.extended_nested_full_name.replace(".", "::")}& other)
{
%   for pb_field_proto in message_inst.descriptor_proto.field:
%     if ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*", ue_bp_protocol_type_prefix)
cpp_ue_field_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_protocol_type_prefix)
%>
%       if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%         if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
field_message_cpp_ue_key_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1], "", ue_bp_protocol_type_prefix)
field_message_cpp_ue_value_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "*", ue_bp_protocol_type_prefix)
field_message_cpp_ue_value_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "", ue_bp_protocol_type_prefix)
if field_message_cpp_ue_key_type_name == "FString":
    field_message_cpp_ue_key_expression = "FString(item.first.c_str())"
elif field_message_cpp_ue_key_type_name == "FName":
    field_message_cpp_ue_key_expression = "FName(item.first.c_str())"
else:
    field_message_cpp_ue_key_expression = "static_cast<{0}>(item.first)".format(field_message_cpp_ue_key_type_name)
%>
    ${message_field_var_name}.Empty(static_cast<int32>(other.${cpp_pb_field_var_name}().size()));
    for (auto& item : other.${cpp_pb_field_var_name}())
    {
%            if field_message_cpp_ue_value_type_name == "FString":
        ${message_field_var_name}.Add(${field_message_cpp_ue_key_expression}, FString(item.second.c_str()));
%            elif ue_excel_utils.UECppMessageFieldIsMessage(field_message_with_map_kv_fields[2]):
        auto NewItem = NewObject<${field_message_cpp_ue_value_origin_type_name}>(this);
        if (NewItem != nullptr)
        {
            *NewItem = item.second;
            ${message_field_var_name}.Add(${field_message_cpp_ue_key_expression}, NewItem);
        }
%            else:
        ${message_field_var_name}.Add(${field_message_cpp_ue_key_expression}, static_cast<${field_message_cpp_ue_value_type_name}>(item.second));
%            endif
    }
%         else:
    ${message_field_var_name}.Empty(static_cast<TArray<${cpp_ue_field_type_name}>::SizeType>(other.${cpp_pb_field_var_name}_size()));
    for (auto& item : other.${cpp_pb_field_var_name}())
    {
%            if cpp_ue_field_type_name == "FString":
        ${message_field_var_name}.Emplace(FString(item.c_str()));
%            elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        auto NewItem = NewObject<${cpp_ue_field_origin_type_name}>(this);
        if (NewItem != nullptr)
        {
            *NewItem = item;
        }
%            else:
        ${message_field_var_name}.Emplace(static_cast<${cpp_ue_field_type_name}>(item));
%            endif
    }
%         endif
%       else:
%          if cpp_ue_field_type_name == "FString":
    ${message_field_var_name} = FString(other.${cpp_pb_field_var_name}().c_str());
%          elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    if(other.has_${cpp_pb_field_var_name}())
    {
        if (${message_field_var_name} == nullptr)
        {
            ${message_field_var_name} = NewObject<${cpp_ue_field_origin_type_name}>(this);
        }
        if (${message_field_var_name} != nullptr)
        {
            *${message_field_var_name} = other.${cpp_pb_field_var_name}();
        }
    }
    else
    {
        ${message_field_var_name} = nullptr;
    }
%          else:
    ${message_field_var_name} = static_cast<${cpp_ue_field_type_name}>(other.${cpp_pb_field_var_name}());
%          endif
%       endif
%     endif
%   endfor
    return *this;
}
% endfor
