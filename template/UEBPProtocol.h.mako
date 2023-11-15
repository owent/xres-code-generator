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
if file_path_prefix.endswith(".h"):
  file_path_prefix = file_path_prefix[:-2]
elif file_path_prefix.endswith(".hpp"):
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
excel_loader_file_include_path = ue_bp_protocol_include_rule % current_file_include_format_args
excel_loader_file_include_path = re.sub("//+", "/", current_file_include_path)

if current_file_include_path.endswith(".h"):
  current_file_include_prefix = current_file_include_path[:-2]
elif current_file_include_path.endswith(".hpp"):
  current_file_include_prefix = current_file_include_path[:-4]
else:
  current_file_include_prefix = current_file_include_path

enable_excel_loader = pb_set.get_custom_variable("ue_bp_protocol_support_loader", "").lower()
has_excel_loader = False
if enable_excel_loader != "0" and enable_excel_loader != "no" and enable_excel_loader != "false":
  for message_full_path in pb_file.pb_msgs:
    message_inst = pb_file.pb_msgs[message_full_path]
    if message_inst.has_loader():
      has_excel_loader = True
      break
%>
#pragma once

#include "CoreMinimal.h"
#include "Containers/Array.h"

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
    "directory_path": dependency_pb_file.get_directory_path(),
    "directory_camelname": dependency_pb_file.get_directory_camelname(),
  }
  dependency_file_include_path = ue_bp_protocol_include_rule % dependency_file_include_format_args
  dependency_file_include_path = re.sub("//+", "/", dependency_file_include_path)
else:
  dependency_file_include_path = None

%>
%   if dependency_file_include_path:
#include "${dependency_file_include_path}"
%   endif
% endfor
% if has_excel_loader:
#include "${excel_loader_file_include_path}"
% endif
% if pb_file.pb_msgs:
#include "${os.path.basename(current_file_include_prefix)}.generated.h"

%   for namespace_name in [x.strip() for x in pb_file.package.split(".")]:
%     if namespace_name:
namespace ${namespace_name} {
%     endif
%   endfor
%   for message_full_path in pb_file.pb_msgs:
class ${pb_file.pb_msgs[message_full_path].extended_nested_name};
%   endfor
%   for namespace_name in [x.strip() for x in pb_file.package.split(".")]:
%     if namespace_name:
}  // namespace ${namespace_name}
%     endif
%   endfor
% endif
% for enum_full_path in pb_file.pb_enums:
<%
enum_inst = pb_file.pb_enums[enum_full_path]
enum_class_name = ue_excel_utils.UECppUEnumName(enum_inst, ue_bp_protocol_type_prefix)
enum_class_support_blue_print = ue_excel_utils.UECppUEnumSupportBlueprint(enum_inst)
enum_value_has_zero = False
for pb_enum_value_proto in enum_inst.descriptor_proto.value:
  if pb_enum_value_proto.number == 0:
    enum_value_has_zero = True
    break
%>
%   if enum_class_support_blue_print:
UENUM(BlueprintType)
enum class ${enum_class_name} : uint8
%   else:
enum class ${enum_class_name} : int32
%   endif
{
%   if not enum_value_has_zero:
    ${ue_excel_utils.UECppUEnumValueName(enum_inst, None, ue_bp_protocol_type_prefix)}__UNKNOWN = 0,
%   endif
%   for pb_enum_value_proto in enum_inst.descriptor_proto.value:
%     if enum_class_support_blue_print:
    ${ue_excel_utils.UECppUEnumValueName(enum_inst, pb_enum_value_proto, ue_bp_protocol_type_prefix)} = ${pb_enum_value_proto.number} UMETA(DisplayName="${pb_enum_value_proto.name}"),
%     else:
    ${ue_excel_utils.UECppUEnumValueName(enum_inst, pb_enum_value_proto, ue_bp_protocol_type_prefix)} = ${pb_enum_value_proto.number}, // ${pb_enum_value_proto.name}
%     endif
%   endfor
};
% endfor
% for message_full_path in pb_file.pb_msgs:
<%
message_inst = pb_file.pb_msgs[message_full_path]
message_class_name = ue_excel_utils.UECppUClassName(message_inst, ue_bp_protocol_type_prefix)
message_struct_name = ue_excel_utils.UECppUStructName(message_inst, ue_bp_protocol_type_prefix)
message_with_uclass = ue_excel_utils.UECppMessageProtocolWithUClass(message_inst)
message_with_ustruct = ue_excel_utils.UECppMessageProtocolWithUStruct(message_inst)
if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
  continue
%>
%   if message_with_ustruct or message_with_uclass:
%     for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst, ue_bp_protocol_type_prefix)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
%>\
%       if oneof_class_support_blue_print:
UENUM(BlueprintType)
enum class ${oneof_class_name} : uint8
%       else:
enum class ${oneof_class_name} : int32
%       endif
{
    ${ue_excel_utils.UECppUOneofEnumValueName(oneof_inst, None, ue_bp_protocol_type_prefix)} = 0,
%       for pb_field_name in oneof_inst.fields:
<%
pb_field_inst = oneof_inst.fields[pb_field_name]
current_enum_field_name = ue_excel_utils.UECppUOneofEnumValueName(oneof_inst, pb_field_inst, ue_bp_protocol_type_prefix)
%>
%         if oneof_class_support_blue_print:
    ${current_enum_field_name} = ${pb_field_inst.descriptor_proto.number} UMETA(DisplayName="${current_enum_field_name}"),
%         else:
    ${current_enum_field_name} = ${pb_field_inst.descriptor_proto.number}, // ${pb_field_inst.descriptor_proto.name}
%         endif
%       endfor
};

%     endfor
%   endif
%   if message_with_ustruct:
// ========================== ${message_struct_name} ==========================
USTRUCT(BlueprintType)
struct ${ue_api_definition}${message_struct_name}
{
    GENERATED_BODY()
%     for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst, ue_bp_protocol_type_prefix)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
message_oneof_var_name = ue_excel_utils.UECppMessageOneofName(oneof_inst.descriptor_proto)
%>
%       if oneof_class_support_blue_print:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name}")
    ${oneof_class_name} ${message_oneof_var_name};
%       else:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name} for ${oneof_class_name}")
    int32 ${message_oneof_var_name};
%       endif
%     endfor
%     for pb_field_proto in message_inst.descriptor_proto.field:
%       if not ue_excel_utils.UECppMessageFieldSupportUStruct(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support USTRUCT.
%       elif ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
%>
%         if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%           if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
%>    // We do not decide how to support map type yet, so we just ignore ${pb_field_proto.name} field here.
    // UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name}")
    // TMap<${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1], "", ue_bp_protocol_type_prefix)}, ${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "", ue_bp_protocol_type_prefix)}> ${message_field_var_name};
%           else:

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name}")
    TArray<${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_protocol_type_prefix)}> ${message_field_var_name};
%           endif
%         else:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name}")
    ${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_protocol_type_prefix)} ${message_field_var_name};
%         endif
%       endif
%     endfor
};

${ue_api_definition}${message_struct_name}& operator<<(${message_struct_name}& target, const ${message_inst.extended_nested_full_name.replace(".", "::")}& source);

${ue_api_definition}const ${message_struct_name}& operator>>(const ${message_struct_name}& source, ${message_inst.extended_nested_full_name.replace(".", "::")}& target);

%   endif
%   if message_with_uclass:
// ========================== ${message_class_name} ==========================
UCLASS(Blueprintable, BlueprintType)
class ${ue_api_definition}${message_class_name} : public UObject
{
    GENERATED_BODY()

public:
    ${message_class_name}();

    ${message_class_name}& operator=(const ${message_inst.extended_nested_full_name.replace(".", "::")}& other);

    ${message_class_name}& operator<<(const ${message_inst.extended_nested_full_name.replace(".", "::")}& other);

    ${message_class_name}& operator>>(${message_inst.extended_nested_full_name.replace(".", "::")}& other);
%     for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst, ue_bp_protocol_type_prefix)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
message_oneof_var_name = ue_excel_utils.UECppMessageOneofName(oneof_inst.descriptor_proto)
%>
%       if oneof_class_support_blue_print:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name}")
    ${oneof_class_name} ${message_oneof_var_name};
%       else:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_struct_name} for ${oneof_class_name}")
    int32 ${message_oneof_var_name};
%       endif
%     endfor
%     for pb_field_proto in message_inst.descriptor_proto.field:
%       if not ue_excel_utils.UECppMessageFieldSupportUClass(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support UCLASS.
%       elif ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
%>
%         if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%           if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
%>
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_class_name}")
    TMap<${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1], "", ue_bp_protocol_type_prefix)}, ${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "*", ue_bp_protocol_type_prefix)}> ${message_field_var_name};
%           else:

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_class_name}")
    TArray<${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*", ue_bp_protocol_type_prefix)}> ${message_field_var_name};
%           endif
%         else:
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Protocol ${message_class_name}")
    ${ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*", ue_bp_protocol_type_prefix)} ${message_field_var_name};
%         endif
%       endif
%     endfor
};
%   endif
% endfor
