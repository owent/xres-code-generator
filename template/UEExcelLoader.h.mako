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

#include "${pb_set.get_custom_variable("ue_include_prefix", "ExcelLoader")}/${file_path_prefix}.generated.h"

namespace goolge {
namespace protobuf {
class Message;
}
}
% for enum_full_path in pb_file.pb_enums:
<%
enum_inst = pb_file.pb_enums[enum_full_path]
enum_class_name = ue_excel_utils.UECppUEnumName(enum_inst)
%>
UENUM(BlueprintType)
enum class ${enum_class_name} : int32
{
%   for pb_enum_value_proto in enum_inst.descriptor_proto.value:
    ${ue_excel_utils.UECppUEnumValueName(enum_inst, pb_enum_value_proto)} = ${pb_enum_value_proto.number} UMETA(DisplayName="${pb_enum_value_proto.name}"),
%   endfor
};
% endfor
% for message_full_path in pb_file.pb_msgs:
<%
message_inst = pb_file.pb_msgs[message_full_path]
message_class_name = ue_excel_utils.UECppUClassName(message_inst)
%>
UCLASS(Blueprintable, BlueprintType)
class ${ue_api_definition}${message_class_name} : public UObject
{
    GENERATED_BODY()

public:
    ${message_class_name}();

    void _InternalBindLifetime(std::shared_ptr<goolge::protobuf::Message> Lifetime, const goolge::protobuf::Message& CurrentMessage);
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
%       else:
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${message_field_var_name}")
    ${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto)} Get${message_field_var_name}(bool& IsValid);
%       endif
%     endif
%   endfor

private:
    const goolge::protobuf::Message* current_message_;
    std::shared_ptr<goolge::protobuf::Message> lifetime_;
};
% endfor
