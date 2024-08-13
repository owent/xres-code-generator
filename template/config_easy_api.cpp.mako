## -*- coding: utf-8 -*-
<%!
import time
%><%
cpp_include_prefix = pb_set.get_custom_variable("cpp_include_prefix", "config/excel/")
config_manager_include = pb_set.get_custom_variable("config_manager_include", "config/excel/config_manager.h")
generated_get_version_loaders = set()
%><%namespace name="pb_loader" module="pb_loader"/>
// Copyright ${time.strftime("%Y")} xresloader. All rights reserved.
// Generated by xres-code-generator, please don't edit it
//

#include "${cpp_include_prefix}config_easy_api.h"

#include <cstdlib>
#include <cstring>
#include <map>
#include <memory>
#include <vector>

#include "${config_manager_include}"

${pb_loader.CppNamespaceBegin(global_package)}
EXCEL_CONFIG_LOADER_API const excel_config_type_traits::shared_ptr<config_group_t>& get_current_config_group() noexcept {
  return config_manager::me()->get_current_config_group();
}

EXCEL_CONFIG_LOADER_API const std::string& get_config_group_version(const excel_config_type_traits::shared_ptr<config_group_t>& group) noexcept {
  if (!group) {
    static std::string empty;
    return empty;
  }

  return group->version;
}

EXCEL_CONFIG_LOADER_API const std::string& get_config_group_version() noexcept {
  return get_config_group_version(get_current_config_group());
}


% for pb_msg in pb_set.generate_message:
%   for loader in pb_msg.loaders:
// ======================================== ${loader.code.class_name} ========================================
%     for code_index in loader.code.indexes:
<%
current_code_proto_ptr_type = 'excel_config_type_traits::shared_ptr<const ' + loader.get_pb_inner_class_name() + '>'
if code_index.is_list():
  current_code_item_value_type = 'excel_config_type_traits::shared_ptr<const std::vector<' + current_code_proto_ptr_type + ' > >'
else:
  current_code_item_value_type = current_code_proto_ptr_type
if code_index.is_vector():
  get_all_of_result = 'const std::vector<' + current_code_item_value_type + '>&'
else:
  get_all_of_result = 'const excel_config_type_traits::map_type<\n    std::tuple<' + code_index.get_key_type_list() + '>,\n    ' + current_code_item_value_type + ' >&'
if loader.code.class_name in generated_get_version_loaders:
  generate_get_version_function = False
else:
  generate_get_version_function = True
  generated_get_version_loaders.add(loader.code.class_name)
%>
%       if generate_get_version_function:
EXCEL_CONFIG_LOADER_API std::size_t get_${loader.code.class_name}_version(const excel_config_type_traits::shared_ptr<config_group_t>& group) {
  if (!group) {
    return 0;
  }

  return group->${loader.get_cpp_public_var_name()}.get_data_hash_code_verison();
}

EXCEL_CONFIG_LOADER_API std::size_t get_${loader.code.class_name}_version() {
  return get_${loader.code.class_name}_version(config_manager::me()->get_current_config_group());
}

%       endif
EXCEL_CONFIG_LOADER_API ${get_all_of_result}
  get_${loader.code.class_name}_all_of_${code_index.name}(const excel_config_type_traits::shared_ptr<config_group_t>& group) {
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
EXCEL_CONFIG_LOADER_API ${current_code_item_value_type}
  get_${loader.code.class_name}_by_${code_index.name}(const excel_config_type_traits::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}) {
  if (!group) {
    return nullptr;
  }

  return group->${loader.get_cpp_public_var_name()}.get_list_by_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API ${current_code_item_value_type}
  get_${loader.code.class_name}_by_${code_index.name}(${code_index.get_key_decl()}) {
  return get_${loader.code.class_name}_by_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API std::size_t count_${loader.code.class_name}_in_${code_index.name}(
    const excel_config_type_traits::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}) {
  if (!group) {
    return 0;
  }

  return group->${loader.get_cpp_public_var_name()}.get_sizeof_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API std::size_t count_${loader.code.class_name}_in_${code_index.name}(
    ${code_index.get_key_decl()}) {
  return count_${loader.code.class_name}_in_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API ${current_code_proto_ptr_type}
  get_${loader.code.class_name}_by_${code_index.name}(const excel_config_type_traits::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}, size_t idx) {
  if (!group) {
    return nullptr;
  }

  return group->${loader.get_cpp_public_var_name()}.get_by_${code_index.name}(${code_index.get_key_params()}, idx);
}

EXCEL_CONFIG_LOADER_API ${current_code_proto_ptr_type}
  get_${loader.code.class_name}_by_${code_index.name}(${code_index.get_key_decl()}, size_t idx) {
  return get_${loader.code.class_name}_by_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()}, idx);
}

EXCEL_CONFIG_LOADER_API bool contains_${loader.code.class_name}_in_${code_index.name}(
    const excel_config_type_traits::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}, size_t idx) {
  if (!group) {
    return false;
  }

  return group->${loader.get_cpp_public_var_name()}.contains_${code_index.name}(${code_index.get_key_params()}, idx);
}

EXCEL_CONFIG_LOADER_API bool contains_${loader.code.class_name}_in_${code_index.name}(
    ${code_index.get_key_decl()}, size_t idx) {
  return contains_${loader.code.class_name}_in_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()}, idx);
}

%       else:
EXCEL_CONFIG_LOADER_API ${current_code_item_value_type}
  get_${loader.code.class_name}_by_${code_index.name}(const excel_config_type_traits::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}) {
  if (!group) {
    return nullptr;
  }

  return group->${loader.get_cpp_public_var_name()}.get_by_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API ${current_code_item_value_type}
  get_${loader.code.class_name}_by_${code_index.name}(${code_index.get_key_decl()}) {
  return get_${loader.code.class_name}_by_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API bool contains_${loader.code.class_name}_in_${code_index.name}(
    const excel_config_type_traits::shared_ptr<config_group_t>& group, ${code_index.get_key_decl()}) {
  if (!group) {
    return false;
  }

  return group->${loader.get_cpp_public_var_name()}.contains_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API bool contains_${loader.code.class_name}_in_${code_index.name}(
    ${code_index.get_key_decl()}) {
  return contains_${loader.code.class_name}_in_${code_index.name}(config_manager::me()->get_current_config_group(), ${code_index.get_key_params()});
}

%       endif
%     endfor
%   endfor
% endfor
${pb_loader.CppNamespaceEnd(global_package)} // ${global_package}
