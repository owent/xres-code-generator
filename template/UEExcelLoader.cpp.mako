## -*- coding: utf-8 -*-
<%!
import time
import os
import re
%><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%namespace name="pb_loader" module="pb_loader"/><%
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
current_file_include_path = ue_excel_loader_include_rule % current_file_include_format_args
current_file_include_path = re.sub("//+", "/", current_file_include_path)
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
message_class_name = ue_excel_utils.UECppUClassName(message_inst)
cpp_pb_message_type = message_inst.full_name.replace(".", "::")
%>
// ========================== ${message_class_name} ==========================
${ue_api_definition}${message_class_name}::${message_class_name}() : Super(), current_message_(nullptr)
{
}

%   if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
<%
message_inst_map_kv_fields = ue_excel_utils.UECppMessageGetMapKVFields(message_inst.descriptor_proto)
message_inst_map_key_field_cpp_pb_type = message_inst.get_field_cpp_protobuf_type(message_inst_map_kv_fields[0])
message_inst_map_value_field_cpp_pb_type = message_inst.get_field_cpp_protobuf_type(message_inst_map_kv_fields[1])
%>${ue_api_definition}void ${message_class_name}::_InternalBindLifetime(std::shared_ptr<const ${protobuf_namespace_prefix}::Message> Lifetime, const void* CurrentMessage)
{
    current_message_ = CurrentMessage;
    lifetime_ = Lifetime;
}
%   else:
${ue_api_definition}void ${message_class_name}::_InternalBindLifetime(std::shared_ptr<const ${protobuf_namespace_prefix}::Message> Lifetime, const ${protobuf_namespace_prefix}::Message& CurrentMessage)
{
    current_message_ = &CurrentMessage;
    lifetime_ = Lifetime;
}

${ue_api_definition}const ${protobuf_namespace_prefix}::Message* ${message_class_name}::_InternalGetMessage() const
{
    return current_message_;
}
%   endif
%   for pb_field_proto in message_inst.descriptor_proto.field:
%     if ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*")
cpp_ue_field_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto)
%>
%       if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
${ue_api_definition}int64 ${message_class_name}::Get${message_field_var_name}Size()
{
    return reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}_size();
}
%       if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
field_message_cpp_ue_key_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1])
field_message_cpp_ue_value_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "*")
field_message_cpp_ue_value_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2])
%>
${ue_api_definition}${field_message_cpp_ue_value_type_name} ${message_class_name}::Find${message_field_var_name}(${field_message_cpp_ue_key_type_name} Index, bool& IsValid)
{
%           if field_message_cpp_ue_key_type_name == "FString":
    auto iter = reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}().find(TCHAR_TO_UTF8(*Index));
%           else:
    auto iter = reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}().find(static_cast<${pb_loader.MakoPbMsgGetPbFieldCppType(field_message_with_map_kv_fields[1])}>(Index));
%           endif
    IsValid = iter != reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}().end();
    if (!IsValid)
    {
%           if field_message_cpp_ue_value_type_name == "bool":
        return false;
%           elif field_message_cpp_ue_value_type_name == "float":
        return 0.0f;
%           elif field_message_cpp_ue_value_type_name == "FString":
        return FString();
%           elif ue_excel_utils.UECppMessageFieldIsEnum(field_message_with_map_kv_fields[2]):
        return static_cast<${field_message_cpp_ue_value_type_name}>(0);
%           elif ue_excel_utils.UECppMessageFieldIsMessage(field_message_with_map_kv_fields[2]):
        return nullptr;
%           else:
        return static_cast<${field_message_cpp_ue_value_type_name}>(0);
%           endif
    }
%           if field_message_cpp_ue_value_type_name == "FString":
    return FString(iter->second.c_str());
%           elif ue_excel_utils.UECppMessageFieldIsMessage(field_message_with_map_kv_fields[2]):
    ${field_message_cpp_ue_value_type_name} Value = NewObject<${field_message_cpp_ue_value_origin_type_name}>();
    Value->_InternalBindLifetime(lifetime_, iter->second);
    return Value;
%           else:
    return static_cast<${field_message_cpp_ue_value_type_name}>(iter->second);
%           endif
}

${ue_api_definition}TArray<${cpp_ue_field_type_name}> ${message_class_name}::GetAllOf${message_field_var_name}()
{
    TArray<${cpp_ue_field_type_name}> Ret;
    if (nullptr == current_message_)
    {
        return Ret;
    }
    auto& map_entrys = reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}();
    Ret.Reserve(static_cast<TArray<${cpp_ue_field_type_name}>::SizeType>(map_entrys.size()));
    for(auto& item : map_entrys)
    {
        ${cpp_ue_field_type_name} Value = NewObject<${cpp_ue_field_origin_type_name}>();
        Value->_InternalBindLifetime(lifetime_, &item);
        Ret.Emplace(Value);
    }

    return Ret;
}
%         else:

${ue_api_definition}${cpp_ue_field_type_name} ${message_class_name}::Get${message_field_var_name}(int64 Index, bool& IsValid)
{
    IsValid = nullptr != current_message_ && Index >= 0 && Get${message_field_var_name}Size() > Index;
    if (!IsValid)
    {
%          if cpp_ue_field_type_name == "bool":
        return false;
%          elif cpp_ue_field_type_name == "float":
        return 0.0f;
%          elif cpp_ue_field_type_name == "FString":
        return FString();
%          elif ue_excel_utils.UECppMessageFieldIsEnum(pb_field_proto):
        return static_cast<${cpp_ue_field_type_name}>(0);
%          elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        return nullptr;
%          else:
        return static_cast<${cpp_ue_field_type_name}>(0);
%          endif
    }

%          if ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    ${cpp_ue_field_type_name} Value = NewObject<${cpp_ue_field_origin_type_name}>();
    Value->_InternalBindLifetime(lifetime_, reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}(
        static_cast<int>(Index)
    ));
    return Value;
%          elif cpp_ue_field_type_name == "FString":
    return FString(reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}(
        static_cast<int>(Index)
    ).c_str());
%          else:
    return static_cast<${cpp_ue_field_type_name}>(reinterpret_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}(
        static_cast<int>(Index)
    ));
%          endif
}
%         endif
%       else:
%         if not ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto) or pb_field_proto.name == "key" or pb_field_proto.name == "value":
${ue_api_definition}${cpp_ue_field_type_name} ${message_class_name}::Get${message_field_var_name}(bool& IsValid)
{
    IsValid = nullptr != current_message_;
    if (!IsValid)
    {
%            if cpp_ue_field_type_name == "bool":
        return false;
%            elif cpp_ue_field_type_name == "float":
        return 0.0f;
%            elif cpp_ue_field_type_name == "FString":
        return FString();
%            elif ue_excel_utils.UECppMessageFieldIsEnum(pb_field_proto):
        return static_cast<${cpp_ue_field_type_name}>(0);
%            elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        return nullptr;
%            else:
        return static_cast<${cpp_ue_field_type_name}>(0);
%            endif
    }
<%
if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
  message_field_var_get_data_codes = 'reinterpret_cast<' + protobuf_namespace_prefix + "::Map<" + message_inst_map_key_field_cpp_pb_type + ", " + message_inst_map_value_field_cpp_pb_type + ">::const_pointer>(current_message_)"
  if pb_field_proto.name == "key":
    message_field_var_get_data_codes += "->first"
  else:
    message_field_var_get_data_codes += "->second"
else:
  message_field_var_get_data_codes = 'reinterpret_cast<const ' + cpp_pb_message_type + '*>(current_message_)->' + cpp_pb_field_var_name + '()'
%>
%            if ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    ${cpp_ue_field_type_name} Value = NewObject<${cpp_ue_field_origin_type_name}>();
    Value->_InternalBindLifetime(lifetime_, ${message_field_var_get_data_codes});
    return Value;
%            elif cpp_ue_field_type_name == "FString":
    return FString(${message_field_var_get_data_codes}.c_str());
%            else:
    return static_cast<${cpp_ue_field_type_name}>(${message_field_var_get_data_codes});
%            endif
}
%         endif
%       endif
%     endif
%   endfor
% endfor
