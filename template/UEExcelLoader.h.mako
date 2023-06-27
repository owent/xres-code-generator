## -*- coding: utf-8 -*-
<%!
import time
import os
%><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%
protobuf_include_prefix = pb_set.get_custom_variable("protobuf_include_prefix")
protobuf_include_suffix = pb_set.get_custom_variable("protobuf_include_suffix")
ue_api_definition = pb_set.get_custom_variable("ue_api_definition")
if ue_api_definition:
  ue_api_definition = ue_api_definition + " "

file_path_prefix = os.path.relpath(output_file, output_dir).replace("\\", "/")
if file_path_prefix.endswith(".h"):
  file_path_prefix = file_path_prefix[:-2]
elif file_path_prefix.endswith(".hpp"):
  file_path_prefix = file_path_prefix[:-4]
else:
  file_path_prefix = file_path_prefix

%>// Copyright ${time.strftime("%Y", time.localtime()) } atframework
// Created by xres-code-generator for ${pb_file.name}, please don't edit it

#pragma once

#include "CoreMinimal.h"

#include <memory>

% if include_headers:
%   if protobuf_include_prefix:
// clang-format off
#include "${protobuf_include_prefix}"
// clang-format on
%   endif

%   for include_header in include_headers:
#include "${include_header}"
%   endfor

%   if protobuf_include_suffix:
// clang-format off
#include "${protobuf_include_suffix}"
// clang-format on
%   endif
% endif

#include "${file_path_prefix}.generated.h"

namespace goolge {
namespace protobuf {
class Message;
}
}
% for message_full_path in pb_file.pb_msgs:
<%
message_inst = pb_file.pb_msgs[message_full_path]
message_class_name = ue_excel_utils.UECppUClassName(message_inst)
%>
// ========================== ${message_class_name} ==========================
UCLASS(Blueprintable, BlueprintType)
class ${ue_api_definition}${message_class_name} : public UObject
{
    GENERATED_BODY()

public:
    ${message_class_name}();

    /**
      * @brief Bind to a config item to keep lifeime and bind to the real config message
      * @note It's a internal function, please don't call it
      * @param Lifetime config group
      * @param CurrentMessage real message
      */
    void _InternalBindLifetime(std::shared_ptr<const goolge::protobuf::Message> Lifetime, const goolge::protobuf::Message& CurrentMessage);
%   for pb_field_proto in message_inst.descriptor_proto.field:
%     if ue_excel_utils.UECppMessageFieldValid(pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
%>
%       if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get Size Of ${message_field_var_name}")
    int64 Get${message_field_var_name}Size();

    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${message_field_var_name}")
    ${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto)} Get${message_field_var_name}(int64 Index, bool& IsValid);
%         if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
%>
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${message_field_var_name} By Key")
    ${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2])} Find${message_field_var_name}(${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1])} Index, bool& IsValid);
%         endif
%       else:
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${message_field_var_name}")
    ${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto)} Get${message_field_var_name}(bool& IsValid);
%       endif
%     endif
%   endfor

private:
    // The real message type is ${message_full_path}
    const goolge::protobuf::Message* current_message_;
    std::shared_ptr<const goolge::protobuf::Message> lifetime_;
};
% endfor
