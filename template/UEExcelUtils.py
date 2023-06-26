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
def UECppUClassName(context, pb_msg):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "U" + ue_type_prefix + pb_loader.MakoToCamelName(context, pb_msg.full_name)

@supports_caller
def UECppMessageFieldName(context, pb_field_proto):
  return pb_loader.MakoToCamelName(context, pb_field_proto.name)

@supports_caller
def UECppMessageFieldVarName(context, pb_field_proto):
  return pb_loader.MakoPbMsgGetCppFieldVarName(context, pb_field_proto)

@supports_caller
def UECppMessageFieldValid(context, pb_field_proto):
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_BYTES:
    return False
  return True

@supports_caller
def UECppMessageFieldIsEnum(context, pb_field_proto):
  return pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_ENUM

@supports_caller
def UECppMessageFieldIsMessage(context, pb_field_proto):
  return pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE

@supports_caller
def UECppMessageFieldIsRepeated(context, pb_field_proto):
  return pb_field_proto.label == pb2.FieldDescriptorProto.LABEL_REPEATED

@supports_caller
def UECppUEnumName(context, pb_enum):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  ue_type_prefix = pb_set.get_custom_variable("ue_type_prefix", "")
  return "E" + ue_type_prefix + pb_loader.MakoToCamelName(context, pb_enum.full_name)

@supports_caller
def UECppUEnumValueName(context, pb_enum, pb_enum_value_proto):
  ret = UECppUEnumName(context, pb_enum)
  return LOWERCASE_RULE.sub("", ret) + "_" + pb_enum_value_proto.name

@supports_caller
def UECppMessageFieldTypeName(context, pb_msg, pb_field_proto):
  pb_set = context.get("pb_set", runtime.UNDEFINED)
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_MESSAGE:
    pb_msg_inst = pb_set.get_msg_by_type(pb_field_proto.type_name)
    if not pb_msg_inst:
      pb_msg_inst = pb_set.get_msg_by_type(pb_msg.full_name + '.' + pb_field_proto.type_name)
    if not pb_msg_inst:
      pb_msg_inst = pb_set.get_msg_by_type(pb_msg.pb_file.package + '.' + pb_field_proto.type_name)
    return UECppUClassName(context, pb_msg_inst)
  if pb_field_proto.type == pb2.FieldDescriptorProto.TYPE_ENUM:
    pb_enum_inst = pb_set.get_enum_by_type(pb_field_proto.type_name)
    if not pb_enum_inst:
      pb_enum_inst = pb_set.get_enum_by_type(pb_msg.full_name + '.' + pb_field_proto.type_name)
    if not pb_enum_inst:
      pb_enum_inst = pb_set.get_enum_by_type(pb_msg.pb_file.package + '.' + pb_field_proto.type_name)
    return UECppUEnumName(context, pb_enum_inst)
  return pb_loader.MakoPbMsgGetPbFieldUECppType(context, pb_field_proto)
