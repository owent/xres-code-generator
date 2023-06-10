## -*- coding: utf-8 -*-
<%!
import time
%><%namespace name="pb_loader" module="pb_loader"/>
// Copyright ${time.strftime("%Y")} xresloader. All rights reserved.
// Generated by xres-code-generator, please don't edit it
//

#include "config_easy_api.h"

#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <vector>

#include "config/excel/config_manager.h"


${pb_loader.CppNamespaceBegin(global_package)}
const std::shared_ptr<config_group_t>& get_current_config_group() noexcept {
  return config_manager::me()->get_current_config_group();
}

% for pb_msg in pb_set.generate_message:
%   for loader in pb_msg.loaders:
    // ======================================== ${loader.code.class_name} ========================================
<%
current_code_proto_ptr_type = 'std::shared_ptr<const ' + loader.get_pb_inner_class_name() + '>'
if code_index.is_list():
  current_code_item_value_type = 'std::vector<' + current_code_proto_ptr_type + ' >'
else:
  current_code_item_value_type = current_code_proto_ptr_type
if code_index.is_vector():
  get_all_of_result = 'const std::vector<' + current_code_item_value_type + '>&'
else:
  get_all_of_result = 'const std::map<std::tuple<' + code_index.get_key_type_list() + '>, ' + current_code_item_value_type + '>&'
%>
EXCEL_CONFIG_LOADER_API ${get_all_of_result}
  get_${loader.code.class_name}_all_of_${code_index.name}(const std::shared_ptr<config_group_t>& group) {
  static ${pb_loader.CppFullPath(global_package)}${loader.get_cpp_class_full_name()}::${code_index.name}_container_type empty;
  if (!group) {
    return empty;
  }

  return group->${loader.get_cpp_public_var_name()}.get_all_of_${code_index.name}();
}

EXCEL_CONFIG_LOADER_API ${get_all_of_result}
  get_${loader.code.class_name}_all_of_${code_index.name}() {
  return get_${loader.code.class_name}_all_of_${code_index.name}(config_manager::me()->get_current_config_group());
}

%       if code_index.is_list():
EXCEL_CONFIG_LOADER_API const ${current_code_item_value_type}*
  get_${loader.code.class_name}_by_${code_index.name}(const std::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}) {
  if (!group) {
    return nullptr;
  }

  return group->${loader.get_cpp_public_var_name()}.get_list_by_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API const ${current_code_item_value_type}*
  get_${loader.code.class_name}_by_${code_index.name}(${code_index.get_key_decl()}) {
  return get_${loader.code.class_name}_by_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API ${current_code_proto_ptr_type}
  get_${loader.code.class_name}_by_${code_index.name}(const std::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}, size_t idx) {
  if (!group) {
    return nullptr;
  }

  return group->${loader.get_cpp_public_var_name()}.get_by_${code_index.name}(${code_index.get_key_params()}, idx);
}

EXCEL_CONFIG_LOADER_API ${current_code_proto_ptr_type}
  get_${loader.code.class_name}_by_${code_index.name}(${code_index.get_key_decl()}, size_t idx) {
  return get_${loader.code.class_name}_by_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()}, idx);
}

%       else:
EXCEL_CONFIG_LOADER_API ${current_code_item_value_type}
  get_${loader.code.class_name}_by_${code_index.name}(const std::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}) {
  if (!group) {
    return nullptr;
  }

  return group->${loader.get_cpp_public_var_name()}.get_by_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API ${current_code_item_value_type}
  get_${loader.code.class_name}_by_${code_index.name}(${code_index.get_key_decl()}) {
  return get_${loader.code.class_name}_by_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()});
}
%       endif
%     endfor
%   endfor
% endfor
${pb_loader.CppNamespaceEnd(global_package)} // ${global_package}
