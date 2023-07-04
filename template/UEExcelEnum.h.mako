## -*- coding: utf-8 -*-
<%!
import time
import os
import re
%><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%namespace name="pb_loader" module="pb_loader"/><%
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

ue_excel_enum_include_rule = pb_set.get_custom_variable("ue_excel_enum_include_rule")
if not ue_excel_enum_include_rule:
  ue_excel_enum_include_rule = pb_set.get_custom_variable("ue_include_prefix", "ExcelEnum") + "/%(file_path_camelname)s.h"
%>// Copyright ${time.strftime("%Y", time.localtime()) } atframework
// Created by xres-code-generator for ${pb_file.name}, please don't edit it
<%
current_file_include_format_args = {
  "file_path_without_ext": pb_file.get_file_path_without_ext(),
  "file_basename_without_ext": pb_file.get_file_basename_without_ext(),
  "file_camelname": pb_file.get_file_camelname(),
  "file_base_camelname": pb_file.get_file_base_camelname(),
  "file_path_camelname": pb_file.get_file_path_camelname(),
}
current_file_include_path = ue_excel_enum_include_rule % current_file_include_format_args
current_file_include_path = re.sub("//+", "/", current_file_include_path)

if current_file_include_path.endswith(".h"):
  current_file_include_prefix = current_file_include_path[:-2]
elif current_file_include_path.endswith(".hpp"):
  current_file_include_prefix = current_file_include_path[:-4]
else:
  current_file_include_prefix = current_file_include_path
%>
#pragma once

#include "CoreMinimal.h"

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

% for dependency_file_path in pb_file.descriptor_proto.dependency:
<%
dependency_pb_file = pb_set.get_file_by_name(dependency_file_path)
if dependency_pb_file:
  dependency_file_include_format_args = {
    "file_path_without_ext": dependency_pb_file.get_file_path_without_ext(),
    "file_basename_without_ext": dependency_pb_file.get_file_basename_without_ext(),
    "file_camelname": dependency_pb_file.get_file_camelname(),
    "file_base_camelname": dependency_pb_file.get_file_base_camelname(),
    "file_path_camelname": dependency_pb_file.get_file_path_camelname(),
  }
  dependency_file_include_path = ue_excel_enum_include_rule % dependency_file_include_format_args
  dependency_file_include_path = re.sub("//+", "/", dependency_file_include_path)
else:
  dependency_file_include_path = None
%>
%   if dependency_file_include_path:
// #include "${dependency_file_include_path}"
%   endif
% endfor

% if pb_file.pb_enums:
// #include "${os.path.basename(current_file_include_prefix)}.generated.h"
% endif

% for enum_full_path in pb_file.pb_enums:
<%
enum_inst = pb_file.pb_enums[enum_full_path]
enum_class_name = ue_excel_utils.UECppUEnumName(enum_inst)
enum_class_support_blue_print = ue_excel_utils.UECppUEnumSupportBlueprint(enum_inst)
%>
%   if enum_class_support_blue_print:
UENUM(BlueprintType)
enum class ${enum_class_name} : uint8
%   else:
enum class ${enum_class_name} : int32
%   endif
{
%   for pb_enum_value_proto in enum_inst.descriptor_proto.value:
%   if enum_class_support_blue_print:
    ${ue_excel_utils.UECppUEnumValueName(enum_inst, pb_enum_value_proto)} = ${pb_enum_value_proto.number} UMETA(DisplayName="${pb_enum_value_proto.name}"),
%   else:
    ${ue_excel_utils.UECppUEnumValueName(enum_inst, pb_enum_value_proto)} = ${pb_enum_value_proto.number}, // ${pb_enum_value_proto.name}
%   endif
%   endfor
};
% endfor
