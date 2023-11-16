## -*- coding: utf-8 -*-
<%!
import time
import os
import re
%><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%namespace name="pb_loader" module="pb_loader"/><%
ue_bp_protocol_type_prefix = pb_set.get_custom_variable("ue_bp_protocol_type_prefix", pb_set.get_custom_variable("ue_type_prefix", ""))
ue_bp_uenum_type_prefix = pb_set.get_custom_variable("ue_bp_uclass_type_prefix", ue_bp_protocol_type_prefix + "E")
ue_bp_uclass_type_prefix = pb_set.get_custom_variable("ue_bp_uclass_type_prefix", ue_bp_protocol_type_prefix + "C")
ue_bp_ustruct_type_prefix = pb_set.get_custom_variable("ue_bp_ustruct_type_prefix", ue_bp_protocol_type_prefix + "S")
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

% for message_inst in pb_file.get_topological_sorted_messages():
<%
message_struct_name = ue_excel_utils.UECppUStructName(message_inst, ue_bp_ustruct_type_prefix)
message_with_ustruct = ue_excel_utils.UECppMessageProtocolWithUStruct(message_inst)
if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
  continue
cpp_pb_message_type = message_inst.extended_nested_full_name.replace(".", "::")
%>\
%   if message_with_ustruct:
// ========================== ${message_struct_name} ==========================
${ue_api_definition}${message_struct_name}& operator<<(${message_struct_name}& target, const ${message_inst.extended_nested_full_name.replace(".", "::")}& source)
{
%     for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst, ue_bp_uenum_type_prefix)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
message_oneof_var_name = ue_excel_utils.UECppMessageOneofName(oneof_inst.descriptor_proto)
%>
%       if oneof_class_support_blue_print:
    target.${message_oneof_var_name} = static_cast<${oneof_class_name}>(source.${ue_excel_utils.UECppMessageOneofGetterName(oneof_inst.descriptor_proto)});
%       else:
    target.${message_oneof_var_name} = static_cast<int32>(source.${ue_excel_utils.UECppMessageOneofGetterName(oneof_inst.descriptor_proto)});
%       endif
%     endfor
%     for pb_field_key in message_inst.fields:
<%
pb_field_inst = message_inst.fields[pb_field_key]
pb_field_proto = pb_field_inst.descriptor_proto
%>\
%       if not ue_excel_utils.UECppMessageFieldSupportUStruct(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support USTRUCT.
%       elif ue_excel_utils.UECppMessageFieldReferenceSelf(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support reference to self in USTRUCT.
%       elif ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_ustruct_type_prefix, False)
cpp_ue_field_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_ustruct_type_prefix, False)
%>
%         if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%           if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
    // We do not decide how to support map type yet, so we just ignore ${message_inst.full_name}.${pb_field_proto.name} field here.
%           else:
    target.${message_field_var_name}.Empty(static_cast<TArray<${cpp_ue_field_type_name}>::SizeType>(source.${cpp_pb_field_var_name}_size()));
    for (auto& item : source.${cpp_pb_field_var_name}())
    {
%              if cpp_ue_field_type_name == "FString":
        target.${message_field_var_name}.Emplace(FString(item.c_str()));
%              elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        target.${message_field_var_name}.AddDefaulted_GetRef() << item;
%              else:
        target.${message_field_var_name}.Emplace(static_cast<${cpp_ue_field_type_name}>(item));
%              endif
    }
%           endif
%         else:
%            if cpp_ue_field_type_name == "FString":
    target.${message_field_var_name} = FString(source.${cpp_pb_field_var_name}().c_str());
%            elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    target.${message_field_var_name} << source.${cpp_pb_field_var_name}();
%            else:
    target.${message_field_var_name} = static_cast<${cpp_ue_field_type_name}>(source.${cpp_pb_field_var_name}());
%            endif
%         endif
%       endif
%     endfor
    return target;
}

${ue_api_definition}const ${message_struct_name}& operator>>(const ${message_struct_name}& source, ${message_inst.extended_nested_full_name.replace(".", "::")}& target)
{
%     for pb_field_key in message_inst.fields:
<%
pb_field_inst = message_inst.fields[pb_field_key]
pb_field_proto = pb_field_inst.descriptor_proto
%>\
%       if not ue_excel_utils.UECppMessageFieldSupportUStruct(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support USTRUCT.
%       elif ue_excel_utils.UECppMessageFieldReferenceSelf(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support reference to self in USTRUCT.
%       elif ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
if ue_excel_utils.UECppMessageFieldIsEnum(pb_field_proto):
  cpp_std_field_type_name = message_inst.get_field_cpp_protobuf_type(pb_field_proto)
else:
  cpp_std_field_type_name = pb_loader.MakoPbMsgGetPbFieldCppType(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_ustruct_type_prefix, False)
%>
%         if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%           if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
    // We do not decide how to support map type yet, so we just ignore ${message_inst.full_name}.${pb_field_proto.name} field here.
%           else:
    target.mutable_${cpp_pb_field_var_name}()->Reserve(static_cast<int>(source.${message_field_var_name}.Num()));
    for (auto& item : source.${message_field_var_name})
    {
%              if cpp_ue_field_type_name == "FString":
        auto __xrescode_${cpp_pb_field_var_name} = FTCHARToUTF8((const TCHAR*)*item);
        target.add_${cpp_pb_field_var_name}((ANSICHAR*)__xrescode_${cpp_pb_field_var_name}.Get(), static_cast<std::string::size_type>(__xrescode_${cpp_pb_field_var_name}.Length()));
%              elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        item >> (*target.add_${cpp_pb_field_var_name}());
%              else:
        target.add_${cpp_pb_field_var_name}(static_cast<${cpp_std_field_type_name}>(item));
%              endif
    }
%           endif
%         else:
%            if pb_field_inst.pb_oneof is not None:
<% field_prefix_ident = "    " %>\
<% field_prefix_ident = "    " %>\
%              if ue_excel_utils.UECppUOneofEnumSupportBlueprint(pb_field_inst.pb_oneof):
    if (source.${ue_excel_utils.UECppMessageOneofName(pb_field_inst.pb_oneof.descriptor_proto)} == ${ue_excel_utils.UECppUOneofEnumName(pb_field_inst.pb_oneof, ue_bp_uenum_type_prefix)}::${ue_excel_utils.UECppUOneofEnumValueName(pb_field_inst.pb_oneof, pb_field_inst, ue_bp_uenum_type_prefix)})
%              else:
    if (source.${ue_excel_utils.UECppMessageOneofName(pb_field_inst.pb_oneof.descriptor_proto)} == static_cast<int32>(${ue_excel_utils.UECppUOneofEnumName(pb_field_inst.pb_oneof, ue_bp_uenum_type_prefix)}::${ue_excel_utils.UECppUOneofEnumValueName(pb_field_inst.pb_oneof, pb_field_inst, ue_bp_uenum_type_prefix)}))
%              endif
    {
%            else:
<% field_prefix_ident = "" %>
%            endif
%            if cpp_ue_field_type_name == "FString":
    ${field_prefix_ident}{
    ${field_prefix_ident}    auto __xrescode_${cpp_pb_field_var_name} = FTCHARToUTF8((const TCHAR*)*source.${message_field_var_name});
    ${field_prefix_ident}    target.set_${cpp_pb_field_var_name}((ANSICHAR*)__xrescode_${cpp_pb_field_var_name}.Get(), static_cast<std::string::size_type>(__xrescode_${cpp_pb_field_var_name}.Length()));
    ${field_prefix_ident}}
%            elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    ${field_prefix_ident}source.${message_field_var_name} >> *target.mutable_${cpp_pb_field_var_name}();
%            else:
    ${field_prefix_ident}target.set_${cpp_pb_field_var_name}(static_cast<${cpp_std_field_type_name}>(source.${message_field_var_name}));
%            endif
%            if pb_field_inst.pb_oneof is not None:
    }
%            endif
%         endif
%       endif
%     endfor
    return source;
}
%   endif

% endfor
% for message_full_path in pb_file.pb_msgs:
<%
message_inst = pb_file.pb_msgs[message_full_path]
message_class_name = ue_excel_utils.UECppUClassName(message_inst, ue_bp_uclass_type_prefix)
message_with_uclass = ue_excel_utils.UECppMessageProtocolWithUClass(message_inst)
if ue_excel_utils.UECppMessageIsMap(message_inst.descriptor_proto):
  continue
cpp_pb_message_type = message_inst.extended_nested_full_name.replace(".", "::")
%>\
%   if message_with_uclass:
// ========================== ${message_class_name} ==========================
${ue_api_definition}${message_class_name}::${message_class_name}() : Super()
{
}

${ue_api_definition}${message_class_name}& ${message_class_name}::operator=(const ${message_inst.extended_nested_full_name.replace(".", "::")}& other)
{
%     for oneof_name in message_inst.oneofs:
<%
oneof_inst = message_inst.oneofs[oneof_name]
oneof_class_name = ue_excel_utils.UECppUOneofEnumName(oneof_inst, ue_bp_uenum_type_prefix)
oneof_class_support_blue_print = ue_excel_utils.UECppUOneofEnumSupportBlueprint(oneof_inst)
message_oneof_var_name = ue_excel_utils.UECppMessageOneofName(oneof_inst.descriptor_proto)
%>
%       if oneof_class_support_blue_print:
    ${message_oneof_var_name} = static_cast<${oneof_class_name}>(other.${ue_excel_utils.UECppMessageOneofGetterName(oneof_inst.descriptor_proto)});
%       else:
    ${message_oneof_var_name} = static_cast<int32>(other.${ue_excel_utils.UECppMessageOneofGetterName(oneof_inst.descriptor_proto)});
%       endif
%     endfor
%     for pb_field_key in message_inst.fields:
<%
pb_field_inst = message_inst.fields[pb_field_key]
pb_field_proto = pb_field_inst.descriptor_proto
%>\
%       if not ue_excel_utils.UECppMessageFieldSupportUClass(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support UCLASS.
%       elif ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*", ue_bp_uclass_type_prefix)
cpp_ue_field_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "", ue_bp_uclass_type_prefix)
%>
%         if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%           if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
field_message_cpp_ue_key_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1], "", ue_bp_uclass_type_prefix)
field_message_cpp_ue_value_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "*", ue_bp_uclass_type_prefix)
field_message_cpp_ue_value_origin_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "", ue_bp_uclass_type_prefix)
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
%              if field_message_cpp_ue_value_type_name == "FString":
        ${message_field_var_name}.Add(${field_message_cpp_ue_key_expression}, FString(item.second.c_str()));
%              elif ue_excel_utils.UECppMessageFieldIsMessage(field_message_with_map_kv_fields[2]):
        auto NewItem = NewObject<${field_message_cpp_ue_value_origin_type_name}>(this);
        if (NewItem != nullptr)
        {
            *NewItem = item.second;
            ${message_field_var_name}.Add(${field_message_cpp_ue_key_expression}, NewItem);
        }
%              else:
        ${message_field_var_name}.Add(${field_message_cpp_ue_key_expression}, static_cast<${field_message_cpp_ue_value_type_name}>(item.second));
%              endif
    }
%           else:
    ${message_field_var_name}.Empty(static_cast<TArray<${cpp_ue_field_type_name}>::SizeType>(other.${cpp_pb_field_var_name}_size()));
    for (auto& item : other.${cpp_pb_field_var_name}())
    {
%              if cpp_ue_field_type_name == "FString":
        ${message_field_var_name}.Emplace(FString(item.c_str()));
%              elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        auto NewItem = NewObject<${cpp_ue_field_origin_type_name}>(this);
        if (NewItem != nullptr)
        {
            *NewItem = item;
        }
        ${message_field_var_name}.Emplace(NewItem);
%              else:
        ${message_field_var_name}.Emplace(static_cast<${cpp_ue_field_type_name}>(item));
%              endif
    }
%           endif
%         else:
%            if cpp_ue_field_type_name == "FString":
    ${message_field_var_name} = FString(other.${cpp_pb_field_var_name}().c_str());
%            elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
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
%            else:
    ${message_field_var_name} = static_cast<${cpp_ue_field_type_name}>(other.${cpp_pb_field_var_name}());
%            endif
%         endif
%       endif
%     endfor
    return *this;
}

${ue_api_definition}${message_class_name}& ${message_class_name}::operator<<(const ${message_inst.extended_nested_full_name.replace(".", "::")}& other)
{
    return *this = other;
}

${ue_api_definition}${message_class_name}& ${message_class_name}::operator>>(${message_inst.extended_nested_full_name.replace(".", "::")}& other)
{
%     for pb_field_key in message_inst.fields:
<%
pb_field_inst = message_inst.fields[pb_field_key]
pb_field_proto = pb_field_inst.descriptor_proto
%>\
%       if not ue_excel_utils.UECppMessageFieldSupportUClass(message_inst, pb_field_proto):

    // ${message_inst.full_name}.${pb_field_proto.name} is ignored because ${pb_field_proto.type_name} do not support USTRUCT.
%       elif ue_excel_utils.UECppMessageFieldValid(message_inst, pb_field_proto):
<%
message_field_var_name = ue_excel_utils.UECppMessageFieldName(pb_field_proto)
cpp_pb_field_var_name = ue_excel_utils.UECppMessageFieldVarName(pb_field_proto)
if ue_excel_utils.UECppMessageFieldIsEnum(pb_field_proto):
  cpp_std_field_type_name = message_inst.get_field_cpp_protobuf_type(pb_field_proto)
else:
  cpp_std_field_type_name = pb_loader.MakoPbMsgGetPbFieldCppType(pb_field_proto)
cpp_ue_field_type_name = ue_excel_utils.UECppMessageFieldTypeName(message_inst, pb_field_proto, "*", ue_bp_uclass_type_prefix)
%>
%         if ue_excel_utils.UECppMessageFieldIsRepeated(pb_field_proto):
%           if ue_excel_utils.UECppMessageFieldIsMap(message_inst, pb_field_proto):
<%
field_message_with_map_kv_fields = ue_excel_utils.UECppMessageFieldGetMapKVFields(message_inst, pb_field_proto)
field_message_cpp_ue_key_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[1], "", ue_bp_uclass_type_prefix)
if ue_excel_utils.UECppMessageFieldIsEnum(field_message_with_map_kv_fields[1]):
  field_message_cpp_std_key_type_name = field_message_with_map_kv_fields[0].get_field_cpp_protobuf_type(field_message_with_map_kv_fields[1])
else:
  field_message_cpp_std_key_type_name = pb_loader.MakoPbMsgGetPbFieldCppType(field_message_with_map_kv_fields[1])
field_message_cpp_ue_value_type_name = ue_excel_utils.UECppMessageFieldTypeName(field_message_with_map_kv_fields[0], field_message_with_map_kv_fields[2], "*", ue_bp_uclass_type_prefix)
if ue_excel_utils.UECppMessageFieldIsEnum(field_message_with_map_kv_fields[2]):
  field_message_cpp_std_key_type_name = field_message_with_map_kv_fields[0].get_field_cpp_protobuf_type(field_message_with_map_kv_fields[2])
else:
  field_message_cpp_std_value_type_name = pb_loader.MakoPbMsgGetPbFieldCppType(field_message_with_map_kv_fields[2])
field_message_cpp_ue_key_init = None
if field_message_cpp_ue_key_type_name == "FString" or field_message_cpp_ue_key_type_name == "FName":
    field_message_cpp_ue_key_init = "auto __xrescode_key_of_{0} = FTCHARToUTF8((const TCHAR*)*item.Key);".format(cpp_pb_field_var_name)
    field_message_cpp_ue_key_expression = "std::string((ANSICHAR*)__xrescode_key_of_{0}.Get(), static_cast<std::string::size_type>(__xrescode_key_of_{0}.Length()))".format(cpp_pb_field_var_name)
else:
    field_message_cpp_ue_key_expression = "static_cast<{0}>(item.Key)".format(field_message_cpp_std_key_type_name)
%>
    for (auto& item : ${message_field_var_name})
    {
%              if field_message_cpp_ue_key_init:
        ${field_message_cpp_ue_key_init}
%              endif
%              if field_message_cpp_ue_value_type_name == "FString":
        auto __xrescode_value_of_${cpp_pb_field_var_name} = FTCHARToUTF8((const TCHAR*)*item.Value);
        other.mutable_${cpp_pb_field_var_name}()->emplace(${field_message_cpp_ue_key_expression}, std::string{(ANSICHAR*)__xrescode_value_of_${cpp_pb_field_var_name}.Get(), static_cast<std::string::size_type>(__xrescode_value_of_${cpp_pb_field_var_name}.Length())});
%              elif ue_excel_utils.UECppMessageFieldIsMessage(field_message_with_map_kv_fields[2]):
        if(item.Value != nullptr)
        {
            (*item.Value) >> (*other.mutable_${cpp_pb_field_var_name}())[${field_message_cpp_ue_key_expression}];
        }
%              else:
        other.mutable_${cpp_pb_field_var_name}()->emplace(${field_message_cpp_ue_key_expression}, static_cast<${field_message_cpp_std_value_type_name}>(item.Value));
%              endif
    }
%           else:
    other.mutable_${cpp_pb_field_var_name}()->Reserve(static_cast<int>(${message_field_var_name}.Num()));
    for (auto& item : ${message_field_var_name})
    {
%              if cpp_ue_field_type_name == "FString":
        auto __xrescode_${cpp_pb_field_var_name} = FTCHARToUTF8((const TCHAR*)*item);
        other.add_${cpp_pb_field_var_name}((ANSICHAR*)__xrescode_${cpp_pb_field_var_name}.Get(), static_cast<std::string::size_type>(__xrescode_${cpp_pb_field_var_name}.Length()));
%              elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
        if (item != nullptr)
        {
            (*item) >> (*other.add_${cpp_pb_field_var_name}());
        }
%              else:
        other.add_${cpp_pb_field_var_name}(static_cast<${cpp_std_field_type_name}>(item));
%              endif
    }
%           endif
%         else:
%            if pb_field_inst.pb_oneof is not None:
<% field_prefix_ident = "    " %>\
%              if ue_excel_utils.UECppUOneofEnumSupportBlueprint(pb_field_inst.pb_oneof):
    if (${ue_excel_utils.UECppMessageOneofName(pb_field_inst.pb_oneof.descriptor_proto)} == ${ue_excel_utils.UECppUOneofEnumName(pb_field_inst.pb_oneof, ue_bp_uenum_type_prefix)}::${ue_excel_utils.UECppUOneofEnumValueName(pb_field_inst.pb_oneof, pb_field_inst, ue_bp_uenum_type_prefix)})
%              else:
    if (${ue_excel_utils.UECppMessageOneofName(pb_field_inst.pb_oneof.descriptor_proto)} == static_cast<int32>(${ue_excel_utils.UECppUOneofEnumName(pb_field_inst.pb_oneof, ue_bp_uenum_type_prefix)}::${ue_excel_utils.UECppUOneofEnumValueName(pb_field_inst.pb_oneof, pb_field_inst, ue_bp_uenum_type_prefix)}))
%              endif
    {
%            else:
<% field_prefix_ident = "" %>
%            endif
%            if cpp_ue_field_type_name == "FString":
    ${field_prefix_ident}{
    ${field_prefix_ident}    auto __xrescode_${cpp_pb_field_var_name} = FTCHARToUTF8((const TCHAR*)*${message_field_var_name});
    ${field_prefix_ident}    other.set_${cpp_pb_field_var_name}((ANSICHAR*)__xrescode_${cpp_pb_field_var_name}.Get(), static_cast<std::string::size_type>(__xrescode_${cpp_pb_field_var_name}.Length()));
    ${field_prefix_ident}}
%            elif ue_excel_utils.UECppMessageFieldIsMessage(pb_field_proto):
    ${field_prefix_ident}if(${message_field_var_name} != nullptr)
    ${field_prefix_ident}{
    ${field_prefix_ident}    (*${message_field_var_name}) >> *other.mutable_${cpp_pb_field_var_name}();
    ${field_prefix_ident}}
%            else:
    ${field_prefix_ident}other.set_${cpp_pb_field_var_name}(static_cast<${cpp_std_field_type_name}>(${message_field_var_name}));
%            endif
%            if pb_field_inst.pb_oneof is not None:
    }
%            endif
%         endif
%       endif
%     endfor
    return *this;
}
%   endif
% endfor
