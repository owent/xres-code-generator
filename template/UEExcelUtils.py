## -*- coding: utf-8 -*-
import time
import os
import string
import re

from google.protobuf import descriptor_pb2 as pb2

from mako.runtime import supports_caller
from mako import runtime

import pb_loader

LOWERCASE_RULE = re.compile("[a-z]")

@supports_caller
def UECppUClassNameFromString(context, origin_class_name, ue_type_prefix=None):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  if ue_type_prefix is None:
    ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "U" + ue_type_prefix + pb_loader.MakoToCamelName(context, origin_class_name)

@supports_caller
def UECppUClassName(context, pb_msg, ue_type_prefix=None):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  if ue_type_prefix is None:
    ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "U" + ue_type_prefix + pb_loader.MakoToCamelName(context, pb_msg.full_name)

@supports_caller
def UECppMessageIsMap(context, pb_msg_proto):
  if pb_msg_proto.options:
    return pb_msg_proto.options.map_entry
  return False

@supports_caller
def UECppMessageGetMapKVFields(context, pb_msg_proto):
  if not UECppMessageIsMap(context, pb_msg_proto):
    return None
  key_field = None
  value_field = None
  for field in pb_msg_proto.field:
    if field.name == "key":
      key_field = field
    elif field.name == "value":
      value_field = field
  return (key_field, value_field)

@supports_caller
def UECppMessageOneofName(context, pb_oneof_proto):
  return pb_loader.MakoToCamelName(context, pb_oneof_proto.name)

@supports_caller
def UECppMessageFieldName(context, pb_field_proto):
  return pb_loader.MakoToCamelName(context, pb_field_proto.name)

@supports_caller
def UECppMessageFieldVarName(context, pb_field_proto):
  return pb_loader.MakoPbMsgGetCppFieldVarName(context, pb_field_proto)

@supports_caller
def UECppMessageFieldValid(context, pb_msg, pb_field_proto):
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_BYTES:
    return False
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE:
    pb_set = context.get("pb_set", runtime.UNDEFINED)
    pb_msg_inst = pb_set.get_msg_by_type(pb_field_proto.type_name)
    if not pb_msg_inst:
      pb_msg_inst = pb_set.get_msg_by_type(pb_msg.full_name + '.' + pb_field_proto.type_name)
    if not pb_msg_inst:
      pb_msg_inst = pb_set.get_msg_by_type(pb_msg.pb_file.package + '.' + pb_field_proto.type_name)
    return pb_msg_inst is not None
  return True

@supports_caller
def UECppMessageFieldIsEnum(context, pb_field_proto):
  return pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_ENUM

@supports_caller
def UECppMessageFieldIsMessage(context, pb_field_proto):
  return pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE

@supports_caller
def UECppMessageFieldGetPbMsg(context, pb_msg, pb_field_proto):
  if pb_field_proto.type != pb2.FieldDescriptorProto.TYPE_MESSAGE:
    return None
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  pb_msg_inst = pb_set.get_msg_by_type(pb_field_proto.type_name)
  if not pb_msg_inst:
    pb_msg_inst = pb_set.get_msg_by_type(pb_msg.full_name + '.' + pb_field_proto.type_name)
  if not pb_msg_inst:
    pb_msg_inst = pb_set.get_msg_by_type(pb_msg.pb_file.package + '.' + pb_field_proto.type_name)
  return pb_msg_inst

@supports_caller
def UECppMessageFieldIsMap(context, pb_msg, pb_field_proto):
  if pb_field_proto.type != pb2.FieldDescriptorProto.TYPE_MESSAGE:
    return False
  return UECppMessageIsMap(context, UECppMessageFieldGetPbMsg(context, pb_msg, pb_field_proto).descriptor_proto)

@supports_caller
def UECppMessageFieldGetMapKVFields(context, pb_msg, pb_field_proto):
  if pb_field_proto.type != pb2.FieldDescriptorProto.TYPE_MESSAGE:
    return None
  pb_msg_inst = UECppMessageFieldGetPbMsg(context, pb_msg, pb_field_proto)
  res = UECppMessageGetMapKVFields(context, pb_msg_inst.descriptor_proto)
  if res is None:
    return None
  return (pb_msg_inst, res[0], res[1])

@supports_caller
def UECppMessageFieldIsRepeated(context, pb_field_proto):
  return pb_field_proto.label == pb2.FieldDescriptorProto.LABEL_REPEATED

@supports_caller
def UECppUEnumName(context, pb_enum, ue_type_prefix=None):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  if ue_type_prefix is None:
    ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "E" + ue_type_prefix + pb_loader.MakoToCamelName(context, pb_enum.full_name)

@supports_caller
def UECppUEnumSupportBlueprint(context, pb_enum):
  return pb_enum.enum_value_min >= 0 and pb_enum.enum_value_max <= 255

@supports_caller
def UECppUEnumValueName(context, pb_enum, pb_enum_value_proto, ue_type_prefix=None):
  ret = UECppUEnumName(context, pb_enum, ue_type_prefix)
  if pb_enum_value_proto is None:
    return LOWERCASE_RULE.sub("", ret)
  else:
    return LOWERCASE_RULE.sub("", ret) + "_" + pb_enum_value_proto.name
  
@supports_caller
def UECppUOneofEnumName(context, pb_oneof, ue_type_prefix=None):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  if ue_type_prefix is None:
    ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "E" + ue_type_prefix + pb_loader.MakoToCamelName(context, pb_oneof.full_name)

@supports_caller
def UECppUOneofClassName(context, pb_oneof, ue_type_prefix=None):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  if ue_type_prefix is None:
    ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "U" + ue_type_prefix + "OneofHelper" + pb_loader.MakoToCamelName(context, pb_oneof.full_name)

@supports_caller
def UECppUOneofEnumSupportBlueprint(context, pb_oneof):
  for field_name in pb_oneof.fields:
    pb_field = pb_oneof.fields[field_name]
    if pb_field.descriptor_proto.number > 255:
      return False
    if pb_field.descriptor_proto.number < 0:
      return False
  return True

@supports_caller
def UECppUOneofEnumValueName(context, pb_oneof, pb_field, ue_type_prefix=None):
  ret = UECppUOneofEnumName(context, pb_oneof, ue_type_prefix)
  if pb_field is None:
    return LOWERCASE_RULE.sub("", ret) + "_NOT_SET"
  else:
    return LOWERCASE_RULE.sub("", ret) + "_" + pb_loader.MakoToCamelName(context, pb_field.descriptor_proto.name)
  
@supports_caller
def UECppUOneofClassValueName(context, pb_oneof, pb_field):
  return pb_loader.MakoToCamelName(context, pb_oneof.descriptor_proto.name) + pb_loader.MakoToCamelName(context, pb_field.descriptor_proto.name)

@supports_caller
def UECppMessageFieldTypeName(context, pb_msg, pb_field_proto, message_type_suffix="", ue_type_prefix=None):
  # pb_set = context.get("pb_set", runtime.UNDEFINED)
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE:
    return UECppUClassName(context, UECppMessageFieldGetPbMsg(context, pb_msg, pb_field_proto), ue_type_prefix) + message_type_suffix
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_ENUM:
    # UE blue print only support enum type base uint8, but protobuf use int32 instead
    return 'int32'
    # pb_enum_inst = pb_set.get_enum_by_type(pb_field_proto.type_name)
    # if not pb_enum_inst:
    #   pb_enum_inst = pb_set.get_enum_by_type(pb_msg.full_name + '.' + pb_field_proto.type_name)
    # if not pb_enum_inst:
    #   pb_enum_inst = pb_set.get_enum_by_type(pb_msg.pb_file.package + '.' + pb_field_proto.type_name)
    # return UECppUEnumName(context, pb_enum_inst)
  return pb_loader.MakoPbMsgGetPbFieldUECppType(context, pb_field_proto)

@supports_caller
def UECppGetLoaderIndexKeyDecl(context, pb_msg, pb_msg_index, ue_type_prefix=None):
    decls = []
    for fd in pb_msg_index.fields:
        decls.append("{0} {1}".format(UECppMessageFieldTypeName(context, pb_msg, fd, "", ue_type_prefix), pb_loader.MakoToCamelName(context, fd.name)))
    return ", ".join(decls)

@supports_caller
def UECppGetLoaderIndexKeyParams(context, pb_msg, pb_msg_index, ue_type_prefix=None):
    decls = []
    for fd in pb_msg_index.fields:
        fd_type = UECppMessageFieldTypeName(context, pb_msg, fd, "", ue_type_prefix)
        if fd_type == 'FString':
            decls.append("TCHAR_TO_ANSI(*" + pb_loader.MakoToCamelName(context, fd.name) + ")")
        else:
            decls.append("static_cast<" + pb_loader.MakoPbMsgGetPbFieldCppType(context, fd) + ">(" + pb_loader.MakoToCamelName(context, fd.name) + ")")
    return ", ".join(decls)
