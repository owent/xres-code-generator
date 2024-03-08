﻿## -*- coding: utf-8 -*-
<%!
import time

from pb_loader import PbMsgPbFieldisSigned,PbMsgGetPbFieldFn

%><%
cpp_include_prefix = pb_set.get_custom_variable("cpp_include_prefix", "config/excel/")
pb_msg_class_name = loader.get_cpp_class_name()
%><%namespace name="pb_loader" module="pb_loader"/>
// Copyright ${time.strftime("%Y")} xresloader. All rights reserved.
// Generated by xres-code-generator, please don't edit it
//

#include <algorithm>
#include <cstddef>
#include <cstdio>
#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <string>
#include <tuple>
#include <vector>
#include <sstream>

// 禁用掉unordered_map，我们要保证mt_core中逻辑有序
#if 0 && defined(__cplusplus) && __cplusplus >= 201103L
#include <unordered_map>
#define LIBXRESLOADER_USING_HASH_MAP 1
#else

#endif

#if defined(_MSC_VER)
#  pragma warning(push)

#  if ((defined(__cplusplus) && __cplusplus >= 201703L) || (defined(_MSVC_LANG) && _MSVC_LANG >= 201703L))
#    pragma warning(disable : 4996)
#    pragma warning(disable : 4309)
#    if _MSC_VER >= 1922
#      pragma warning(disable : 5054)
#    endif
#  endif

#  pragma warning(disable : 4100)
#  pragma warning(disable : 4244)
#  pragma warning(disable : 4251)
#  pragma warning(disable : 4267)
#  pragma warning(disable : 4668)
#  pragma warning(disable : 4715)
#  pragma warning(disable : 4800)
#  pragma warning(disable : 4946)
#  pragma warning(disable : 6001)
#  pragma warning(disable : 6244)
#  pragma warning(disable : 6246)

#  ifndef WIN32_LEAN_AND_MEAN
#    define WIN32_LEAN_AND_MEAN
#  endif
#  include <Windows.h>
#endif

#ifdef max
#undef max
#endif

#ifdef min
#undef min
#endif

#if defined(__GNUC__) && !defined(__clang__) && !defined(__apple_build_version__)
#  if (__GNUC__ * 100 + __GNUC_MINOR__ * 10) >= 460
#    pragma GCC diagnostic push
#  endif
#  pragma GCC diagnostic ignored "-Wunused-parameter"
#  pragma GCC diagnostic ignored "-Wtype-limits"
#  pragma GCC diagnostic ignored "-Wsign-compare"
#  pragma GCC diagnostic ignored "-Wsign-conversion"
#  pragma GCC diagnostic ignored "-Wshadow"
#  pragma GCC diagnostic ignored "-Wuninitialized"
#  pragma GCC diagnostic ignored "-Wconversion"
#  if (__GNUC__ * 100 + __GNUC_MINOR__) >= 409
#    pragma GCC diagnostic ignored "-Wfloat-conversion"
#  endif
#  if (__GNUC__ * 100 + __GNUC_MINOR__) >= 501
#    pragma GCC diagnostic ignored "-Wsuggest-override"
#  endif
#elif defined(__clang__) || defined(__apple_build_version__)
#pragma clang diagnostic push
#  pragma clang diagnostic ignored "-Wunused-parameter"
#  pragma clang diagnostic ignored "-Wtype-limits"
#  pragma clang diagnostic ignored "-Wsign-compare"
#  pragma clang diagnostic ignored "-Wsign-conversion"
#  pragma clang diagnostic ignored "-Wshadow"
#  pragma clang diagnostic ignored "-Wuninitialized"
#  pragma clang diagnostic ignored "-Wconversion"
#  if ((__clang_major__ * 100) + __clang_minor__) >= 305
#    pragma clang diagnostic ignored "-Wfloat-conversion"
#  endif
#  if ((__clang_major__ * 100) + __clang_minor__) >= 306
#    pragma clang diagnostic ignored "-Winconsistent-missing-override"
#  endif
#  if ((__clang_major__ * 100) + __clang_minor__) >= 1100
#    pragma clang diagnostic ignored "-Wsuggest-override"
#  endif
#endif

#include <google/protobuf/arena.h>
#include <google/protobuf/arenastring.h>
#include <google/protobuf/extension_set.h>  // IWYU pragma: export
#include <google/protobuf/generated_message_util.h>
#include <google/protobuf/io/coded_stream.h>
#include <google/protobuf/message_lite.h>
#include <google/protobuf/metadata_lite.h>
#include <google/protobuf/repeated_field.h>  // IWYU pragma: export
#include <google/protobuf/stubs/common.h>

#if defined(__GNUC__) && !defined(__clang__) && !defined(__apple_build_version__)
#  if (__GNUC__ * 100 + __GNUC_MINOR__ * 10) >= 460
#    pragma GCC diagnostic pop
#  endif
#elif defined(__clang__) || defined(__apple_build_version__)
#  pragma clang diagnostic pop
#endif

#if defined(_MSC_VER)
#  pragma warning(pop)
#endif

#include "${cpp_include_prefix}config_manager.h"
#include "${loader.get_cpp_header_path()}"

#ifndef UTIL_STRFUNC_SNPRINTF
// @see https://github.com/atframework/atframe_utils/blob/master/include/common/string_oprs.h

#if (defined(_MSC_VER) && _MSC_VER >= 1600) || (defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L) || defined(__STDC_LIB_EXT1__)
#ifdef _MSC_VER
#define UTIL_STRFUNC_SNPRINTF(...) sprintf_s(__VA_ARGS__)
#else
#define UTIL_STRFUNC_SNPRINTF(...) snprintf_s(__VA_ARGS__)
#endif

#define UTIL_STRFUNC_C11_SUPPORT 1
#else
#define UTIL_STRFUNC_SNPRINTF(...) snprintf(__VA_ARGS__)
#endif
#endif

${pb_loader.CppNamespaceBegin(global_package)}
${loader.get_cpp_namespace_decl_begin()}

namespace details {
  template <typename TCH>
  static inline bool is_space(const TCH &c) {
    return ' ' == c || '\t' == c || '\r' == c || '\n' == c;
  }

  template <typename TCH>
  static std::pair<const TCH *, size_t> trim(const TCH *str_begin, size_t sz) {
    if (0 == sz) {
      const TCH *str_end = str_begin;
      while (str_end && *str_end) {
        ++str_end;
      }

      sz = static_cast<size_t>(str_end - str_begin);
    }

    if (str_begin) {
      while (*str_begin && sz > 0) {
        if (!is_space(*str_begin)) {
          break;
        }

        --sz;
        ++str_begin;
      }
    }

    size_t sub_str_sz = sz;
    if (str_begin) {
      while (sub_str_sz > 0) {
        if (is_space(str_begin[sub_str_sz - 1])) {
          --sub_str_sz;
        } else {
          break;
        }
      }
    }

    return std::make_pair(str_begin, sub_str_sz);
  }
}

EXCEL_CONFIG_LOADER_API ${pb_msg_class_name}::${pb_msg_class_name}(): all_loaded_(false), enable_multithread_lock_(true), hash_code_verison_(0) {
}

EXCEL_CONFIG_LOADER_API ${pb_msg_class_name}::~${pb_msg_class_name}(){
}

EXCEL_CONFIG_LOADER_API int ${pb_msg_class_name}::on_inited(bool enable_multithread_lock) {
  enable_multithread_lock_ = enable_multithread_lock;

  ::excel::lock::write_lock_holder<::excel::lock::spin_rw_lock> wlh;
  if (enable_multithread_lock_) {
    wlh = ::excel::lock::write_lock_holder<::excel::lock::spin_rw_lock>{load_file_lock_};
  }

  file_status_.clear();
  datasource_.clear();
  return reload_file_lists();
}

EXCEL_CONFIG_LOADER_API int ${pb_msg_class_name}::load_all() {
  int ret = 0;
  if (all_loaded_) {
    return ret;
  }

  ::excel::lock::write_lock_holder<::excel::lock::spin_rw_lock> wlh;
  if (enable_multithread_lock_) {
    wlh = ::excel::lock::write_lock_holder<::excel::lock::spin_rw_lock>{load_file_lock_};
  }

  for (std::unordered_map<std::string, bool>::iterator iter = file_status_.begin(); iter != file_status_.end(); ++ iter) {
    if (!iter->second) {
      int res = load_file(iter->first);
      if (res < 0) {
        EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load config file %s for %s failed", iter->first.c_str(), "${pb_msg_class_name}");
        ret = res;
      } else if (ret >= 0) {
        ret += res;
      }
    }
  }

  all_loaded_ = true;
  return ret;
}

EXCEL_CONFIG_LOADER_API void ${pb_msg_class_name}::clear() {
  ::excel::lock::write_lock_holder<::excel::lock::spin_rw_lock> wlh;
  if (enable_multithread_lock_) {
    wlh = ::excel::lock::write_lock_holder<::excel::lock::spin_rw_lock>{load_file_lock_};
  }

% for code_index in loader.code.indexes:
  ${code_index.name}_data_.clear();
% endfor
  file_status_.clear();
  datasource_.clear();
  reload_file_lists();
  all_data_.clear();
  hash_code_verison_ = 0;
}

EXCEL_CONFIG_LOADER_API const std::list<org::xresloader::pb::xresloader_data_source>& ${pb_msg_class_name}::get_data_source() const {
  return datasource_;
}

EXCEL_CONFIG_LOADER_API std::size_t ${pb_msg_class_name}::get_data_hash_code_verison() const noexcept {
  return hash_code_verison_;
}

EXCEL_CONFIG_LOADER_API const std::vector<${pb_msg_class_name}::item_ptr_type>& ${pb_msg_class_name}::get_all_data() const noexcept {
  if (!all_loaded_) {
    const_cast<${pb_msg_class_name}*>(this)->load_all();
  }
  return all_data_;
}

int ${pb_msg_class_name}::load_file(const std::string& file_path) {
  std::unordered_map<std::string, bool>::iterator iter = file_status_.find(file_path);
  if (iter == file_status_.end()) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load config file %s for %s failed, not exist in any file_list/file_path", file_path.c_str(), "${pb_msg_class_name}");
    return -2;
  }

  if (iter->second) {
    return 0;
  }
  iter->second = true;

  std::string content;
  if (!config_manager::me()->load_file_data(content, file_path)) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load file %s for %s failed", file_path.c_str(), "${pb_msg_class_name}");
    return -3;
  }

  ${loader.get_pb_outer_class_name()} outer_data;
  if (!outer_data.ParseFromString(content)) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] parse file %s for %s(message type: %s) failed: %s",
      file_path.c_str(), "${pb_msg_class_name}", "${loader.get_pb_outer_class_name()}",
      outer_data.InitializationErrorString().c_str()
    );
    return -4;
  }

  if (!config_manager::me()->filter<item_type>(outer_data, file_path)) {
    return -5;
  }

  for (int i = 0; i < outer_data.header().data_source_size(); ++ i) {
    datasource_.push_back(outer_data.header().data_source(i));
  }

  // Hash combine
  hash_code_verison_ ^= std::hash<std::string>()(outer_data.header().hash_code()) + 0x9e3779b9 +
    (hash_code_verison_ << 6) + (hash_code_verison_ >> 2);

% for code_index in loader.code.indexes:
%   if code_index.is_vector():
  // vector index: ${code_index.name}
  if(${code_index.name}_data_.capacity() < static_cast<size_t>(outer_data.${loader.code_field.name.lower()}_size())) {
    ${code_index.name}_data_.reserve(static_cast<size_t>(outer_data.${loader.code_field.name.lower()}_size()));
  }
%   endif
% endfor

  for (int i = 0; i < outer_data.${loader.code_field.name.lower()}_size(); ++ i) {
    excel_config_type_traits::shared_ptr<item_type> new_item = excel_config_type_traits::make_shared<item_type>();
    if (!new_item) {
      EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] parse file %s for %s(message type: %s) and create item object %d failed",
        file_path.c_str(), "${pb_msg_class_name}", "${loader.get_pb_outer_class_name()}", i
      );
      return -5;
    }

    if (!excel_config_type_traits::const_pointer_cast<proto_type>(new_item)->ParseFromString(outer_data.${loader.code_field.name.lower()}(i))) {
      EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] parse message %d in %s for %s(message type: %s) failed: %s",
        i, file_path.c_str(), "${pb_msg_class_name}", "${loader.get_pb_outer_class_name()}",
        new_item->InitializationErrorString().c_str()
      );
      return -6;
    }
    merge_data(new_item);
  }

  EXCEL_CONFIG_MANAGER_LOGINFO("[EXCEL] load file %s for %s(message type: %s) with %d item(s) success",
    file_path.c_str(), "${pb_msg_class_name}", "${loader.get_pb_outer_class_name()}",
    outer_data.${loader.code_field.name.lower()}_size()
  );

  return 1;
}

int ${pb_msg_class_name}::load_list(const char* file_list_path) {
  std::string content;
  if (!config_manager::me()->load_file_data(content, file_list_path)) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load file %s for %s failed", file_list_path, "${pb_msg_class_name}");
    return -1;
  }

  const char* line_start = content.c_str();
  const char* line_end;
  int ret = 0;
  for (; line_start < content.c_str() + content.size() && *line_start; line_start = line_end + 1) {
    line_end = line_start;

    if ('\r' == *line_end || '\n' == *line_end || !*line_end) {
      continue;
    }

    while (*line_end && '\r' != *line_end && '\n' != *line_end) {
      ++ line_end;
    }

    std::pair<const char*, size_t> file_path_trimed = details::trim(line_start, static_cast<size_t>(line_end - line_start));
    if (file_path_trimed.second == 0) {
      continue;
    }

    std::string file_path;
    file_path.assign(file_path_trimed.first, file_path_trimed.second);
    if (file_status_.end() == file_status_.find(file_path)) {
      file_status_[file_path] = false;
    }
  }

  return ret;
}

int ${pb_msg_class_name}::reload_file_lists() {
  all_loaded_ = false;
% if loader.code.file_list:
  return load_list("${loader.code.file_list}");
% else:
%   if not isinstance(loader.code.file_path, str):
%     for one_file_path in loader.code.file_path:
  file_status_["${one_file_path}"] = false;
%     endfor
%   else:
  file_status_["${loader.code.file_path}"] = false;
%   endif
  return 0;
% endif
}

void ${pb_msg_class_name}::merge_data(item_ptr_type item) {
  if (!item) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] merge_data(nullptr) is not allowed for %s", "${pb_msg_class_name}");
    return;
  }

  all_data_.push_back(item);

% for code_index in loader.code.indexes:
  // index: ${code_index.name}
  do {
% if code_index.is_vector():
    size_t idx = 0;
%   for idx_field in code_index.fields:
%       if PbMsgPbFieldisSigned(idx_field):
    if (item->${PbMsgGetPbFieldFn(idx_field)} < 0) {
      EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] merge_data with vector index %lld for %s is not allowed",
        static_cast<long long>(item->${PbMsgGetPbFieldFn(idx_field)}), "${pb_msg_class_name}"
      );
      break;
    }
%       endif
    idx = static_cast<size_t>(item->${PbMsgGetPbFieldFn(idx_field)});
%   endfor
    if (${code_index.name}_data_.capacity() <= idx) {
      ${code_index.name}_data_.reserve(idx * 2 + 1);
    }

    if (${code_index.name}_data_.size() <= idx) {
      ${code_index.name}_data_.resize(idx + 1);
    }

%   if code_index.is_list():
    excel_config_type_traits::const_pointer_cast<std::vector<item_ptr_type> >(${code_index.name}_data_[idx])->push_back(item);
%   else:
    ${code_index.name}_data_[idx] = item;
%   endif
% else:
%   if code_index.is_list():
    excel_config_type_traits::const_pointer_cast<std::vector<item_ptr_type> >(${code_index.name}_data_
      [std::make_tuple(${code_index.get_key_value_list("item->")})])->push_back(item);
%   else:
    std::tuple<${code_index.get_key_type_list()}> key = std::make_tuple(${code_index.get_key_value_list("item->")});
    if (${code_index.name}_data_.end() != ${code_index.name}_data_.find(key)) {
      EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] merge_data() with key=<${code_index.get_key_fmt_list()}> for %s is already exists, we will cover it with the newer value",
        ${code_index.get_key_fmt_value_list("item->")}, "${pb_msg_class_name}");
    }
    ${code_index.name}_data_[key] = item;
%   endif
% endif
  } while(false);

% endfor
}

% for code_index in loader.code.indexes:
// ------------------- index: ${code_index.name} APIs -------------------
% if code_index.is_list():
EXCEL_CONFIG_LOADER_API ${pb_msg_class_name}::${code_index.name}_value_type
  ${pb_msg_class_name}::get_list_by_${code_index.name}(${code_index.get_key_decl()}) {
  ::excel::lock::read_lock_holder<::excel::lock::spin_rw_lock> rlh;
  if (enable_multithread_lock_) {
    rlh = ::excel::lock::read_lock_holder<::excel::lock::spin_rw_lock>{load_file_lock_};
  }

  return _get_list_by_${code_index.name}(${code_index.get_key_params()});
}

EXCEL_CONFIG_LOADER_API ${pb_msg_class_name}::item_ptr_type ${pb_msg_class_name}::get_by_${code_index.name}(${code_index.get_key_decl()}, size_t index) {
  ::excel::lock::read_lock_holder<::excel::lock::spin_rw_lock> rlh;
  if (enable_multithread_lock_) {
    rlh = ::excel::lock::read_lock_holder<::excel::lock::spin_rw_lock>{load_file_lock_};
  }
  ${pb_msg_class_name}::${code_index.name}_value_type list_item = 
    _get_list_by_${code_index.name}(${code_index.get_key_params()});
  if (nullptr == list_item) {
%   if not code_index.allow_not_found:
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load index %s with key=<${code_index.get_key_fmt_list()}>, index=%llu for %s failed, list not found",
      "${code_index.name}", ${code_index.get_key_params_fmt_value_list()},
      static_cast<unsigned long long>(index), "${pb_msg_class_name}"
    );
    if (config_manager::me()->get_on_not_found()) {
      config_manager::on_not_found_event_data_t evt_data;
      evt_data.data_source = &datasource_;
      evt_data.message_descriptor = ${loader.get_pb_inner_class_name()}::descriptor();

      char keys_buffer[4096];
      int n = UTIL_STRFUNC_SNPRINTF(keys_buffer, sizeof(keys_buffer) - 1, "${code_index.get_key_fmt_list()}", ${code_index.get_key_params_fmt_value_list()});
      evt_data.index_name = "${code_index.name}";
      if (n < static_cast<int>(sizeof(keys_buffer)) && n >= 0) {
        keys_buffer[n] = 0;
      } else {
        keys_buffer[sizeof(keys_buffer) - 1] = 0;
      }
      evt_data.keys = keys_buffer;
      evt_data.is_list = true;
      evt_data.list_index = index;
      config_manager::me()->get_on_not_found()(evt_data);
    }
%   endif
    return nullptr;
  }

  if (list_item->size() <= index) {
%   if not code_index.allow_not_found:
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load index %s with key=<${code_index.get_key_fmt_list()}>, index=%llu for %s failed, index entend %llu",
      "${code_index.name}", ${code_index.get_key_params_fmt_value_list()},
      static_cast<unsigned long long>(index), "${pb_msg_class_name}", static_cast<unsigned long long>(list_item->size())
    );
    if (config_manager::me()->get_on_not_found()) {
      config_manager::on_not_found_event_data_t evt_data;
      evt_data.data_source = &datasource_;
      evt_data.message_descriptor = ${loader.get_pb_inner_class_name()}::descriptor();

      char keys_buffer[4096];
      int n = UTIL_STRFUNC_SNPRINTF(keys_buffer, sizeof(keys_buffer) - 1, "${code_index.get_key_fmt_list()}", ${code_index.get_key_params_fmt_value_list()});
      evt_data.index_name = "${code_index.name}";
      if (n < static_cast<int>(sizeof(keys_buffer)) && n >= 0) {
        keys_buffer[n] = 0;
      } else {
        keys_buffer[sizeof(keys_buffer) - 1] = 0;
      }
      evt_data.keys = keys_buffer;
      evt_data.is_list = true;
      evt_data.list_index = index;
      config_manager::me()->get_on_not_found()(evt_data);
    }
%   endif
    return nullptr;
  }

  return (*list_item)[index];
}

${pb_msg_class_name}::${code_index.name}_value_type
  ${pb_msg_class_name}::_get_list_by_${code_index.name}(${code_index.get_key_decl()}) {
% if code_index.is_vector():
  size_t idx = 0;
%   for idx_field in code_index.fields:
%       if PbMsgPbFieldisSigned(idx_field):
  if (${idx_field.name} < 0) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] vector index %lld for %s is not allowed",
      static_cast<long long>(${idx_field.name}), "${pb_msg_class_name}"
    );
    return nullptr;
  }
%       endif
  idx = static_cast<size_t>(${idx_field.name});
%   endfor
  if (${code_index.name}_data_.size() > idx && ${code_index.name}_data_[idx]) {
    return ${code_index.name}_data_[idx];
  }
% else:
  ${code_index.name}_container_type::iterator iter = ${code_index.name}_data_.find(std::make_tuple(${code_index.get_key_params()}));
  if (iter != ${code_index.name}_data_.end()) {
    return iter->second;
  }
% endif

  int res;
%   if loader.code.file_list and code_index.file_mapping:
%       for code_line in code_index.get_load_file_code("file_path"):
  ${code_line}
%       endfor
  res = load_file(file_path);
  if (res < 0) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load file %s for %s failed, res: %d", file_path.c_str(), "${pb_msg_class_name}", res);
    return nullptr;
  }
%   else:
  for (auto& file_path : file_status_) {
    res = load_file(file_path.first);
    if (res < 0) {
      EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load file %s for %s failed, res: %d", file_path.first.c_str(), "${pb_msg_class_name}", res);
      return nullptr;
    }
  }
%   endif

% if code_index.is_vector():
  if (${code_index.name}_data_.size() > idx && ${code_index.name}_data_[idx]) {
    return ${code_index.name}_data_[idx];
  }

%   if not code_index.allow_not_found:
  EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load index %s with key=<${code_index.get_key_fmt_list()}> for %s failed, not found",
    "${code_index.name}", ${code_index.get_key_params_fmt_value_list()}, "${pb_msg_class_name}"
  );
  if (config_manager::me()->get_on_not_found()) {
    config_manager::on_not_found_event_data_t evt_data;
    evt_data.data_source = &datasource_;
    evt_data.message_descriptor = ${loader.get_pb_inner_class_name()}::descriptor();

    char keys_buffer[4096];
    int n = UTIL_STRFUNC_SNPRINTF(keys_buffer, sizeof(keys_buffer) - 1, "${code_index.get_key_fmt_list()}", ${code_index.get_key_params_fmt_value_list()});
    evt_data.index_name = "${code_index.name}";
    if (n < static_cast<int>(sizeof(keys_buffer)) && n >= 0) {
      keys_buffer[n] = 0;
    } else {
      keys_buffer[sizeof(keys_buffer) - 1] = 0;
    }
    evt_data.keys = keys_buffer;
    evt_data.is_list = true;
    evt_data.list_index = 0;
    config_manager::me()->get_on_not_found()(evt_data);
  }
%   endif
  return nullptr;

% else:
  iter = ${code_index.name}_data_.find(std::make_tuple(${code_index.get_key_params()}));
  if (iter == ${code_index.name}_data_.end()) {
%   if not code_index.allow_not_found:
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load index %s with key=<${code_index.get_key_fmt_list()}> for %s failed, not found",
      "${code_index.name}", ${code_index.get_key_params_fmt_value_list()}, "${pb_msg_class_name}"
    );
    if (config_manager::me()->get_on_not_found()) {
      config_manager::on_not_found_event_data_t evt_data;
      evt_data.data_source = &datasource_;
      evt_data.message_descriptor = ${loader.get_pb_inner_class_name()}::descriptor();

      char keys_buffer[4096];
      int n = UTIL_STRFUNC_SNPRINTF(keys_buffer, sizeof(keys_buffer) - 1, "${code_index.get_key_fmt_list()}", ${code_index.get_key_params_fmt_value_list()});
      evt_data.index_name = "${code_index.name}";
      if (n < static_cast<int>(sizeof(keys_buffer)) && n >= 0) {
        keys_buffer[n] = 0;
      } else {
        keys_buffer[sizeof(keys_buffer) - 1] = 0;
      }
      evt_data.keys = keys_buffer;
      evt_data.is_list = true;
      evt_data.list_index = 0;
      config_manager::me()->get_on_not_found()(evt_data);
    }
%   endif
    return nullptr;
  }

%   if code_index.sort_by:
  using mutable_${code_index.name}_container_vector_type = std::vector<item_ptr_type>;
  mutable_${code_index.name}_container_vector_type resort;
  resort.reserve(iter->second->size());
  resort.assign(iter->second->begin(), iter->second->end());

  std::sort(resort.begin(), resort.end(),
    [](const item_ptr_type& l, const item_ptr_type& r) {
%     for sort_fd in code_index.sort_by:
      if (l->${PbMsgGetPbFieldFn(sort_fd)} != r->${PbMsgGetPbFieldFn(sort_fd)}) {
        return l->${PbMsgGetPbFieldFn(sort_fd)} < r->${PbMsgGetPbFieldFn(sort_fd)};
      }
%     endfor
      return false;
    });
  const_cast<std::vector<item_ptr_type>*>(iter->second.get())->clear();
  const_cast<std::vector<item_ptr_type>*>(iter->second.get())->reserve(resort.size());
  const_cast<std::vector<item_ptr_type>*>(iter->second.get())->assign(resort.begin(), resort.end());
%   endif
  return iter->second;

% endif
}

% else:
EXCEL_CONFIG_LOADER_API ${pb_msg_class_name}::${code_index.name}_value_type ${pb_msg_class_name}::get_by_${code_index.name}(${code_index.get_key_decl()}) {
% if code_index.is_vector():
  size_t idx = 0;
%   for idx_field in code_index.fields:
%       if PbMsgPbFieldisSigned(idx_field):
  if (${idx_field.name} < 0) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] vector index %lld for %s is not allowed",
      static_cast<long long>(${idx_field.name}), "${pb_msg_class_name}"
    );
    return nullptr;
  }
%       endif
  idx = static_cast<size_t>(${idx_field.name});
%   endfor
  if (${code_index.name}_data_.size() > idx && ${code_index.name}_data_[idx]) {
    return ${code_index.name}_data_[idx];
  }
% else:
  ::excel::lock::read_lock_holder<::excel::lock::spin_rw_lock> rlh;
  if (enable_multithread_lock_) {
    rlh = ::excel::lock::read_lock_holder<::excel::lock::spin_rw_lock>{load_file_lock_};
  }
  ${code_index.name}_container_type::iterator iter = ${code_index.name}_data_.find(std::make_tuple(${code_index.get_key_params()}));
  if (iter != ${code_index.name}_data_.end()) {
    return iter->second;
  }
% endif

  int res;
%   if loader.code.file_list and code_index.file_mapping:
%       for code_line in code_index.get_load_file_code("file_path"):
  ${code_line}
%       endfor
  res = load_file(file_path);
  if (res < 0) {
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load file %s for %s failed, res: %d", file_path.c_str(), "${pb_msg_class_name}", res);
    return nullptr;
  }
%   else:
  for (auto& file_path : file_status_) {
    res = load_file(file_path.first);
    if (res < 0) {
      EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load file %s for %s failed, res: %d", file_path.first.c_str(), "${pb_msg_class_name}", res);
      return nullptr;
    }
  }
%   endif

% if code_index.is_vector():
  if (${code_index.name}_data_.size() > idx && ${code_index.name}_data_[idx]) {
    return ${code_index.name}_data_[idx];
  }

%   if not code_index.allow_not_found:
  EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load index %s with key=<${code_index.get_key_fmt_list()}> for %s failed, not found",
    "${code_index.name}", ${code_index.get_key_params_fmt_value_list()}, "${pb_msg_class_name}"
  );
  if (config_manager::me()->get_on_not_found()) {
    config_manager::on_not_found_event_data_t evt_data;
    evt_data.data_source = &datasource_;
    evt_data.message_descriptor = ${loader.get_pb_inner_class_name()}::descriptor();

    char keys_buffer[4096];
    int n = UTIL_STRFUNC_SNPRINTF(keys_buffer, sizeof(keys_buffer) - 1, "${code_index.get_key_fmt_list()}", ${code_index.get_key_params_fmt_value_list()});
    evt_data.index_name = "${code_index.name}";
    if (n < static_cast<int>(sizeof(keys_buffer)) && n >= 0) {
      keys_buffer[n] = 0;
    } else {
      keys_buffer[sizeof(keys_buffer) - 1] = 0;
    }
    evt_data.keys = keys_buffer;
    evt_data.is_list = false;
    evt_data.list_index = 0;
    config_manager::me()->get_on_not_found()(evt_data);
  }
%   endif
  return nullptr;

% else:
  iter = ${code_index.name}_data_.find(std::make_tuple(${code_index.get_key_params()}));
  if (iter == ${code_index.name}_data_.end()) {
%   if not code_index.allow_not_found:
    EXCEL_CONFIG_MANAGER_LOGERROR("[EXCEL] load index %s with key=<${code_index.get_key_fmt_list()}> for %s failed, not found",
      "${code_index.name}", ${code_index.get_key_params_fmt_value_list()}, "${pb_msg_class_name}"
    );
    if (config_manager::me()->get_on_not_found()) {
      config_manager::on_not_found_event_data_t evt_data;
      evt_data.data_source = &datasource_;
      evt_data.message_descriptor = ${loader.get_pb_inner_class_name()}::descriptor();

      char keys_buffer[4096];
      int n = UTIL_STRFUNC_SNPRINTF(keys_buffer, sizeof(keys_buffer) - 1, "${code_index.get_key_fmt_list()}", ${code_index.get_key_params_fmt_value_list()});
      evt_data.index_name = "${code_index.name}";
      if (n < static_cast<int>(sizeof(keys_buffer)) && n >= 0) {
        keys_buffer[n] = 0;
      } else {
        keys_buffer[sizeof(keys_buffer) - 1] = 0;
      }
      evt_data.keys = keys_buffer;
      evt_data.is_list = false;
      evt_data.list_index = 0;
      config_manager::me()->get_on_not_found()(evt_data);
    }
%   endif
    return nullptr;
  }

  return iter->second;
% endif
}
% endif

EXCEL_CONFIG_LOADER_API const ${pb_msg_class_name}::${code_index.name}_container_type& ${pb_msg_class_name}::get_all_of_${code_index.name}() const {
  if (!all_loaded_) {
    const_cast<${pb_msg_class_name}*>(this)->load_all();
  }
  return ${code_index.name}_data_;
}
% endfor

${loader.get_cpp_namespace_decl_end()}
${pb_loader.CppNamespaceEnd(global_package)} // ${global_package}
