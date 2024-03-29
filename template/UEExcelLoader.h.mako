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
if file_path_prefix.endswith(".h"):
  file_path_prefix = file_path_prefix[:-2]
elif file_path_prefix.endswith(".hpp"):
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

if current_file_include_path.endswith(".h"):
  current_file_include_prefix = current_file_include_path[:-2]
elif current_file_include_path.endswith(".hpp"):
  current_file_include_prefix = current_file_include_path[:-4]
else:
  current_file_include_prefix = current_file_include_path
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
  dependency_file_include_path = ue_excel_loader_include_rule % dependency_file_include_format_args
  dependency_file_include_path = re.sub("//+", "/", dependency_file_include_path)
else:
  dependency_file_include_path = None
%>
%   if dependency_file_include_path:
#include "${dependency_file_include_path}"
%   endif
% endfor

% if pb_file.pb_msgs:
#include "${os.path.basename(current_file_include_prefix)}.generated.h"

%   for namespace_name in [x.strip() for x in protobuf_namespace_prefix.split("::")]:
%     if namespace_name:
namespace ${namespace_name} {
%     endif
%   endfor
class Message;
%   for namespace_name in [x.strip() for x in protobuf_namespace_prefix.split("::")]:
%     if namespace_name:
}  // namespace ${namespace_name}
%     endif
%   endfor
% endif
% for message_full_path in pb_file.pb_msgs:
<%
message_inst = pb_file.pb_msgs[message_full_path]
message_class_name = ue_excel_utils.UECppUClassName(message_inst)
%>
// ========================== ${message_class_name} ==========================
%   for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
%>
%     if oneof_class_support_blue_print:
UENUM(BlueprintType)
enum class ${oneof_class_name} : uint8
%     else:
enum class ${oneof_class_name} : int32
%     endif
{
    ${ue_excel_utils.UECppUOneofEnumValueName(oneof_inst, None)} = 0,
%     for pb_field_name in oneof_inst.fields:
<%
pb_field_inst = oneof_inst.fields[pb_field_name]
current_enum_field_name = ue_excel_utils.UECppUOneofEnumValueName(oneof_inst, pb_field_inst)
%>
%       if oneof_class_support_blue_print:
    ${current_enum_field_name} = ${pb_field_inst.descriptor_proto.number} UMETA(DisplayName="${current_enum_field_name}"),
%       else:
    ${current_enum_field_name} = ${pb_field_inst.descriptor_proto.number}, // ${pb_field_inst.descriptor_proto.name}
%       endif
%     endfor
};
%     if not oneof_class_support_blue_print:
<%
oneof_helper_class_name = ue_excel_utils.UECppUOneofClassName(oneof_inst)
%>
UCLASS(Blueprintable, BlueprintType)
class ${ue_api_definition}${oneof_helper_class_name} : public UObject
{
    GENERATED_BODY()

public:
    ${oneof_helper_class_name}();
%     for pb_field_name in oneof_inst.fields:
<%
pb_field_inst = oneof_inst.fields[pb_field_name]
%>
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${oneof_name}")
    static int32 Get${ue_excel_utils.UECppUOneofClassValueName(oneof_inst, pb_field_inst)}();
%     endfor
};
%     endif

%   endfor
UCLASS(Blueprintable, BlueprintType)
class ${ue_api_definition}${message_class_name} : public UObject
{
    GENERATED_BODY()

public:
    ${message_class_name}();

%   if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
<%
message_inst_map_kv_fields = ue_excel_utils.UECppMessageGetMapKVFields(message_inst.descriptor_proto)
message_inst_map_key_field_cpp_pb_type = message_inst.get_field_cpp_protobuf_type(message_inst_map_kv_fields[0])
message_inst_map_value_field_cpp_pb_type = message_inst.get_field_cpp_protobuf_type(message_inst_map_kv_fields[1])
%>    /**
      * @brief Bind to a config item to keep lifeime and bind to the real config message
      * @note It's a internal function, please don't call it
      * @param Lifetime config group
      * @param CurrentMessage real data pointer of ${protobuf_namespace_prefix}::Map<${message_inst_map_key_field_cpp_pb_type}, ${message_inst_map_value_field_cpp_pb_type}>::const_pointer
      */
    void _InternalBindLifetime(std::shared_ptr<const ${protobuf_namespace_prefix}::Message> Lifetime, const void* CurrentMessage);
%   else:
    /**
      * @brief Bind to a config item to keep lifeime and bind to the real config message
      * @note It's a internal function, please don't call it
      * @param Lifetime config group
      * @param CurrentMessage real message of ${message_class_name}
      */
    void _InternalBindLifetime(std::shared_ptr<const ${protobuf_namespace_prefix}::Message> Lifetime, const ${protobuf_namespace_prefix}::Message& CurrentMessage);

    /**
      * @brief Get the internal message pointer
      * @note It's a internal function, please don't call it
      * @return The binded internal message pointer of type ${message_full_path}
      */
    const ${protobuf_namespace_prefix}::Message* _InternalGetMessage() const;
%   endif
%   for pb_field_proto in message_inst.descriptor_proto.field:
%     if ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*")
%>
%       if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name}")
    int64 Get${message_field_var_name}Size();
%         if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
%>
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name}")
    ${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "*")} Find${message_field_var_name}(${ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1])} Index, bool& IsValid);

    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get All Of ${message_field_var_name}")
    TArray<${cpp_ue_field_type_name}> GetAllOf${message_field_var_name}();
%         else:

    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get All Of ${message_field_var_name}")
    TArray<${cpp_ue_field_type_name}> GetAllOf${message_field_var_name}();

    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name}")
    ${cpp_ue_field_type_name} Get${message_field_var_name}(int64 Index, bool& IsValid);
%         endif
%       else:
%         if not ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto) or pb_field_proto.name == "key" or pb_field_proto.name == "value":
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name}")
    ${cpp_ue_field_type_name} Get${message_field_var_name}(bool& IsValid);
%         endif
%       endif
%     endif
%   endfor

%   for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst)
message_oneof_var_name = ue_excel_utils.UECppMessageOneofName(oneof_inst.descriptor_proto)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
%>
%     if oneof_class_support_blue_print:
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${message_oneof_var_name} Case")
    ${oneof_class_name} Get${message_oneof_var_name}Case();
%     else:
    UFUNCTION(BlueprintCallable, Category = "Excel Config ${message_class_name} Get ${message_oneof_var_name} Case")
    int32 Get${message_oneof_var_name}Case();
%     endif
%   endfor

private:
%   if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
    // The real message type is ${protobuf_namespace_prefix}::Map<${message_inst_map_key_field_cpp_pb_type}, ${message_inst_map_value_field_cpp_pb_type}>::const_pointer
    const void* current_message_;
%   else:
    // The real message type is ${message_full_path}
    const ${protobuf_namespace_prefix}::Message* current_message_;
%   endif
    std::shared_ptr<const ${protobuf_namespace_prefix}::Message> lifetime_;
};
% endfor
