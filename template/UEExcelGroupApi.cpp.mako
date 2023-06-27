## -*- coding: utf-8 -*-
<%!
import time
import os
%><%namespace name="pb_loader" module="pb_loader"/><%namespace name="ue_excel_utils" module="UEExcelUtils"/><%
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

config_manager_include = pb_set.get_custom_variable("config_manager_include", "config/excel/config_manager.h")
config_group_wrapper_type_name = ue_excel_utils.UECppUClassNameFromString("ConfigGroupWrapper")
%>// Copyright ${time.strftime("%Y")} xresloader. All rights reserved.
// Generated by xres-code-generator, please don't edit it
//

#pragma once

#include "${file_path_prefix}.h"

#include "${config_manager_include}"

${ue_api_definition}${config_group_wrapper_type_name}::${config_group_wrapper_type_name}() : Super()
{
}

${ue_api_definition}void ${config_group_wrapper_type_name}::_InternalBindConfigGroup(const std::shared_ptr<${pb_loader.CppFullPath(global_package)}config_group_t>& ConfigGroup)
{
    config_group_ = ConfigGroup;
}

% for message_inst in pb_set.generate_message:
<%
message_class_name = ue_excel_utils.UECppUClassName(message_inst)
%>
    // ======================================== ${message_class_name} ========================================
%   for loader in message_inst.loaders:
    // ---------------------------------------- ${loader.code.class_name} ----------------------------------------
%     for code_index in loader.code.indexes:
${ue_api_definition}int64 ${config_group_wrapper_type_name}::Get${pb_loader.MakoToCamelName(loader.code.class_name)}_SizeOf_${pb_loader.MakoToCamelName(code_index.name)}()
{
    if(!config_group_)
    {
        return 0;
    }
    return static_cast<int64>(config_group_->${loader.get_cpp_public_var_name()}.get_all_of_${code_index.name}().size());
}

${ue_api_definition}TArray<${message_class_name}> ${config_group_wrapper_type_name}::GetAll${pb_loader.MakoToCamelName(loader.code.class_name)}_Of_${pb_loader.MakoToCamelName(code_index.name)}()
{
    TArray<${message_class_name}> Ret;
    if(!config_group_)
    {
      return Ret;
    }

%       if code_index.is_list():
    for(auto& item_list : config_group_->${loader.get_cpp_public_var_name()}.get_all_of_${code_index.name}())
    {
        for(auto& item : item_list.second)
        {
            ${message_class_name} Value;
            Value._InternalBindConfigItem(std::static_pointer_cast<const ::google::protobuf::Message>(item), *item);
            Ret.Emplace(${message_class_name}(item));
        }
    }
%       else:
    for(auto& item : config_group_->${loader.get_cpp_public_var_name()}.get_all_of_${code_index.name}())
    {
        ${message_class_name} Value;
        Value._InternalBindConfigItem(std::static_pointer_cast<const ::google::protobuf::Message>(item), *item);
        Ret.Emplace(${message_class_name}(item));
    }
%       endif
    return Ret;
}
%       if code_index.is_list():

${ue_api_definition}TArray<${message_class_name}> ${config_group_wrapper_type_name}::Get${pb_loader.MakoToCamelName(loader.code.class_name)}_Of_${pb_loader.MakoToCamelName(code_index.name)}(${ue_excel_utils.UECppGetLoaderIndexKeyDecl(message_inst, code_index)}, bool& IsValid)
{
    TArray<${message_class_name}> Ret;
    if(!config_group_)
    {
        IsValid = false;
        return Ret;
    }

    auto item_list = config_group_->${loader.get_cpp_public_var_name()}.get_list_by_${code_index.name}(${ue_excel_utils.UECppGetLoaderIndexKeyParams(message_inst, code_index)});
    if (nullptr == item_list)
    {
        IsValid = false;
        return Ret;
    }
    IsValid = true;

    for(auto& item : *item_list) {
        ${message_class_name} Value;
        Value._InternalBindConfigItem(std::static_pointer_cast<const ::google::protobuf::Message>(item), *item);
        Ret.Emplace(${message_class_name}(item));
    }

    return Ret;
}

${ue_api_definition}${message_class_name} ${config_group_wrapper_type_name}::Get${pb_loader.MakoToCamelName(loader.code.class_name)}_Of_${pb_loader.MakoToCamelName(code_index.name)}(${ue_excel_utils.UECppGetLoaderIndexKeyDecl(message_inst, code_index)}, int64 Index, bool& IsValid)
{
    if(!config_group_)
    {
        IsValid = false;
        return ${message_class_name}();
    }

    auto item = config_group_->${loader.get_cpp_public_var_name()}.get_by_${code_index.name}(${ue_excel_utils.UECppGetLoaderIndexKeyParams(message_inst, code_index)}, static_cast<size_t>(Index));
    if (!item)
    {
        IsValid = false;
        return ${message_class_name}();
    }

    ${message_class_name} Value;
    Value._InternalBindConfigItem(std::static_pointer_cast<const ::google::protobuf::Message>(item), *item);
    return Value;
}
%       else:

${ue_api_definition}${message_class_name} ${config_group_wrapper_type_name}::Get${pb_loader.MakoToCamelName(loader.code.class_name)}_Of_${pb_loader.MakoToCamelName(code_index.name)}(${ue_excel_utils.UECppGetLoaderIndexKeyDecl(message_inst, code_index)}, bool& IsValid)
{
    if(!config_group_)
    {
        IsValid = false;
        return ${message_class_name}();
    }

    auto item = config_group_->${loader.get_cpp_public_var_name()}.get_by_${code_index.name}(${ue_excel_utils.UECppGetLoaderIndexKeyParams(message_inst, code_index)});
    if (!item)
    {
        IsValid = false;
        return ${message_class_name}();
    }

    ${message_class_name} Value;
    Value._InternalBindConfigItem(std::static_pointer_cast<const ::google::protobuf::Message>(item), *item);
    return Value;
}
%       endif

%     endfor
%   endfor
% endfor
private:
    std::shared_ptr<${pb_loader.CppFullPath(global_package)}config_group_t> config_group_;
};
