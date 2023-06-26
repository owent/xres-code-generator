## -*- coding: utf-8 -*-
<%!
import time
import os
%><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%
file_path_prefix = pb_file.get_file_path_without_ext()
protobuf_include_prefix = pb_set.get_custom_variable("protobuf_include_prefix")
protobuf_include_suffix = pb_set.get_custom_variable("protobuf_include_suffix")
ue_api_definition = pb_set.get_custom_variable("ue_api_definition")
if ue_api_definition:
  ue_api_definition = ue_api_definition + " "
%>// Copyright ${time.strftime("%Y", time.localtime()) } atframework
// Created by xres-code-generator for ${pb_file.name}, please don't edit it

#pragma once

#include "${pb_set.get_custom_variable("ue_include_prefix", "ExcelLoader")}/${file_path_prefix}.h"

% if protobuf_include_prefix:
// clang-format off
#include "${protobuf_include_prefix}"
// clang-format on
% endif

#include "${file_path_prefix}.pb.h"
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
%>// ========================== ${message_class_name} ==========================
${ue_api_definition}${message_class_name}::${message_class_name}() : Super(), current_message_(nullptr)
{
}

${ue_api_definition}void ${message_class_name}::_InternalBindLifetime(std::shared_ptr<goolge::protobuf::Message> Lifetime, const goolge::protobuf::Message& CurrentMessage)
{
    current_message_ = &CurrentMessage;
    lifetime_ = Lifetime;
}

%   for pb_field_proto in message_inst.descriptor_proto.field:
%     if ue_excel_utils.UECppMessageFieldValid(pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto)
%>
%       if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
${ue_api_definition}int64 ${message_class_name}::Get${message_field_var_name}Size()
{
    return static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}_size();
}
    
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
        return ${cpp_ue_field_type_name}();
%          else:
        return static_cast<${cpp_ue_field_type_name}>(0);
%          endif
    }

%          if ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    ${cpp_ue_field_type_name} Value;
    Value._InternalBindLifetime(Lifetime, static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}(
        static_cast<int>(Index)
    ));
    return Value;
%          elif cpp_ue_field_type_name == "FString":
    return FString(static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}(
        static_cast<int>(Index)
    ).c_str());
%          else:
    return static_cast<${cpp_ue_field_type_name}>(static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}(
        static_cast<int>(Index)
    ));
%          endif
}
%       else:
${ue_api_definition}${cpp_ue_field_type_name} ${message_class_name}::Get${message_field_var_name}(bool& IsValid)
{
    IsValid = nullptr != current_message_;
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
        return ${cpp_ue_field_type_name}();
%          else:
        return static_cast<${cpp_ue_field_type_name}>(0);
%          endif
    }
%          if ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    ${cpp_ue_field_type_name} Value;
    Value._InternalBindLifetime(Lifetime, static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}());
    return Value;
%          elif cpp_ue_field_type_name == "FString":
    return FString(static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}().c_str());
%          else:
    return static_cast<${cpp_ue_field_type_name}>(static_cast<const ${cpp_pb_message_type}*>(current_message_)->${cpp_pb_field_var_name}());
%          endif
}
%       endif
%     endif
%   endfor
% endfor
