-- Copyright 2022 xresloader. All rights reserved.

local CUSTOM_INDEX_MOD_NAME = 'DataTableCustomIndexLuaProtobuf'
local DataTableService = {
    __current_group = {},
    __history_versions = {},
    IndexModuleName = CUSTOM_INDEX_MOD_NAME,
    XresloaderBlockMessage = 'org.xresloader.pb.xresloader_datablocks',
    MaxGroupNumber = 5,
    OverrideSameVersion = true,
    BufferLoader = function(file_path)
        local f = io.open(file_path, "rb")
        if f == nil then
            error(string.format("Open file %s failed", file_path))
            return nil
        end
        local ret = f:read("a")
        f:close()
        return ret
    end,
    VersionLoader = function()
        return ""
    end,
    OnError = function(msg, ...) -- Used for error message, parameters is (message, data_set, indexName, keys...)
        print(string.format("[ERROR]: %s", debug.traceback(msg, 2)))
    end,
    OnInfo = function(msg, ...) -- Used for error message, parameters is (message, data_set, indexName)
        print(string.format("[INFO]: %s", msg))
    end
}

local DataTableSet = {}

-- ===================== DataTableSet =====================
local function __SetupIndexFromFile(index_loader, raw_data_containers, data_container, index_cfg, index_file_path)
    local data_set = raw_data_containers[index_file_path]
    local pb = require('pb')
    if data_set == nil then
        local data_desc_msg = pb.type(index_cfg.fullName)
        if data_desc_msg == nil then
            if 'function' == type(index_loader.__service.OnError) then
                local msg = string.format('Index "%s" of message "%s": can not find message descriptor %s',
                    index_loader.Name,
                    index_cfg.fullName, index_cfg.fullName)
                pcall(index_loader.__service.OnError, msg, index_loader, index_cfg.indexName)
            end
            return
        end

        local load_file_result, data_block = pcall(index_loader.__service.BufferLoader, index_file_path)
        if not load_file_result then
            if 'function' == type(index_loader.__service.OnError) then
                local msg = string.format('Index "%s" of message "%s": can not load file data %s: %s', index_loader.Name
                    ,
                    index_cfg.fullName, index_file_path, data_block)
                pcall(index_loader.__service.OnError, msg, index_loader, index_cfg.indexName)
            end
            return
        end

        local xresloader_result, xresloader_datablocks = pcall(pb.decode, index_loader.__service.XresloaderBlockMessage,
            data_block)
        if not xresloader_result then
            if 'function' == type(index_loader.__service.OnError) then
                local msg = string.format('Index "%s" of message "%s": can not parse file data %s: %s',
                    index_loader.Name,
                    index_cfg.fullName, index_file_path, xresloader_datablocks)
                pcall(index_loader.__service.OnError, msg, index_loader, index_cfg.indexName)
            end
            return
        end
        local all_rows = {}
        if 'function' == type(index_loader.__service.OnInfo) then
            local msg = string.format('Load data set "%s" with %d item(s), message type: %s', index_loader.Name,
                #xresloader_datablocks.data_block, index_cfg.fullName)
            pcall(index_loader.__service.OnInfo, msg, index_loader, index_cfg.indexName)
        end
        for row_index = 1, #xresloader_datablocks.data_block do
            local data_result, data_row = pcall(pb.decode, index_cfg.fullName,
                xresloader_datablocks.data_block[row_index])
            if data_result then
                table.insert(all_rows, data_row)
            else
                if 'function' == type(index_loader.__service.OnError) then
                    local msg = string.format(
                        'Index "%s" of message "%s": can not parse data row %d in file %s with message %s: %s'
                        ,
                        index_loader.Name,
                        index_cfg.fullName, row_index, index_file_path, index_cfg.fullName, data_row)
                    pcall(index_loader.__service.OnError, msg, index_loader, index_cfg.indexName)
                end
            end
        end
        local message_descriptor_inst = {
            name = index_cfg.fullName,
            pb_handle = data_desc_msg,
            fields = {},
            fields_by_number = {},
            fields_by_name = {},
        }
        local message_typeinfo = index_loader.__types[index_cfg.fullName]
        if message_typeinfo == nil then
            local typeinfo_name, typeinfo_bashname, typeinfo_type = pb.type(index_cfg.fullName)
            message_typeinfo = {
                name = typeinfo_name or index_cfg.fullName,
                bashname = typeinfo_bashname,
                type = typeinfo_type,
            }
            index_loader.__types[message_typeinfo.name] = message_typeinfo
            index_loader.__types[index_cfg.fullName] = message_typeinfo
        end
        for fd_name, fd_number, fd_type in pb.fields(index_cfg.fullName) do
            local typeinfo = index_loader.__types[fd_type]
            if typeinfo == nil then
                local typeinfo_name, typeinfo_bashname, typeinfo_type = pb.type(fd_type)
                typeinfo = {
                    name = typeinfo_name or fd_type,
                    bashname = typeinfo_bashname,
                    type = typeinfo_type,
                }
                index_loader.__types[fd_type] = typeinfo
            end
            table.insert(message_descriptor_inst.fields, {
                name = fd_name,
                number = fd_number,
                type = typeinfo,
            })
        end
        for _, fds in ipairs(message_descriptor_inst.fields) do
            message_descriptor_inst.fields_by_number[fds.number] = fds
            message_descriptor_inst.fields_by_name[fds.name] = fds
        end
        data_set = { origin = xresloader_datablocks, all_rows = all_rows, message_descriptor = message_descriptor_inst }
        raw_data_containers[index_file_path] = data_set
    end

    local all_rows = data_set.all_rows
    if all_rows == nil then
        return
    end

    if index_cfg.keys == nil or 0 == #index_cfg.keys then
        return
    end

    local index_data = data_container[index_cfg.indexName] or {
        options = index_cfg.options or {},
        data = {}
    }

    for _, cfgv in ipairs(all_rows) do
        local cfg_item = index_data.data
        local parent_node = nil
        local last_key = nil
        local last_keyv = nil
        for _, keyv in ipairs(index_cfg.keys) do
            last_keyv = keyv
            last_key = cfgv[keyv] or nil
            parent_node = cfg_item
            cfg_item = parent_node[last_key]
            if cfg_item == nil and last_key ~= nil then
                cfg_item = {}
                parent_node[last_key] = cfg_item
                local field_typeinfo = data_set.message_descriptor.fields_by_name[keyv]
                if field_typeinfo ~= nil and field_typeinfo.type.type == 'enum' then
                    local enum_number_value = pb.enum(field_typeinfo.type.name, last_key)
                    if enum_number_value ~= nil then
                        parent_node[enum_number_value] = cfg_item
                    end
                end
            end
        end

        if index_data.options.isList then
            table.insert(cfg_item, cfgv)
        elseif last_key ~= nil then
            parent_node[last_key] = cfgv
            local field_typeinfo = data_set.message_descriptor.fields_by_name[last_keyv]
            if field_typeinfo ~= nil and field_typeinfo.type.type == 'enum' then
                local enum_number_value = pb.enum(field_typeinfo.type.name, last_key)
                if enum_number_value ~= nil then
                    parent_node[enum_number_value] = cfgv
                end
            end
        end
    end

    data_container[index_cfg.indexName] = index_data
end

local function __SetupIndex(index_loader, raw_data_containers, data_container, index_cfg)
    data_container[index_cfg.indexName] = nil
    for _, v in ipairs(index_cfg.filePath) do
        if v == nil then
            return
        end
        __SetupIndexFromFile(index_loader, raw_data_containers, data_container, index_cfg, v)
    end
end

function DataTableSet.GetAllIndexes(self)
    return self.__indexes
end

function DataTableSet.GetMessageDescriptor(self)
    return self.__message_descriptor
end

function DataTableSet.GetByIndex(self, index_name, ...)
    -- lazy load index
    if self.__index_handles == nil then
        local data_container = {}
        local raw_data_containers = {}

        for _, v in ipairs(self.__indexes) do
            __SetupIndex(self, raw_data_containers, data_container, v)
            if 'function' == type(self.__service.OnInfo) then
                local msg = string.format('  - Load index: %s', v.indexName)
                pcall(self.__service.OnInfo, msg, self, v.indexName)
            end
        end

        self.__origin_datas = raw_data_containers
        self.__index_handles = data_container
        for _, v in pairs(raw_data_containers) do
            self.__message_descriptor = v.message_descriptor
            break
        end
    end

    local index_set = self.__index_handles[index_name]
    if index_set == nil then
        if 'function' == type(DataTableService.OnError) then
            local msg = string.format('Index "%s" can not be found on "%s", key(s)=(%s)', index_name, self.Name,
                table.concat({ ... }, ', '))
            pcall(DataTableService.OnError, msg, self, index_name, ...)
        end
        return nil
    end

    local data_set = index_set.data or {}
    for k, v in ipairs({ ... }) do
        local select_set = data_set[v]
        if select_set ~= nil then
            data_set = select_set
        else
            if index_set.options.isList then
                return {}
            else
                if index_set.options.allowNotFound then
                    return nil
                end

                if 'function' == type(DataTableService.OnError) then
                    local msg = string.format('Record with key(s)=(%s) can not be found on index "%s" of "%s"',
                        table.concat({ ... }, ', '), index_name, self.Name)
                    pcall(DataTableService.OnError, msg, self, index_name, ...)
                end
                return nil
            end
        end
    end

    return data_set or {}
end

-- ===================== DataTableService =====================
function DataTableService.GetByGroup(self, group, loader_name)
    if nil == loader_name then
        return nil
    end

    return group[loader_name]
end

function DataTableService.GetCurrentGroup(self)
    return self.__current_group
end

function DataTableService.GetGroupByVersion(self, version)
    for _, v in ipairs(self.__history_versions) do
        if v.version == version then
            return v.loaders
        end
    end

    return nil
end

function DataTableService.Get(self, loader_name)
    return self:GetByGroup(self.__current_group, loader_name)
end

function DataTableService.LoadTables(self)
    local current_version = self.VersionLoader()
    for index, v in ipairs(self.__history_versions) do
        if v.version == current_version then
            if self.OverrideSameVersion or current_version == nil or string.len(current_version) == 0 then
                table.remove(self.__history_versions, index)
                break
            else
                self.__current_group = v.loaders
                return self.__current_group
            end
        end
    end
    self.__current_group = {}
    local index_mapping = require(self.IndexModuleName)
    for k, v in pairs(index_mapping) do
        local loader = {
            Name = k,
            __indexes = v,
            __index_handles = nil,
            __service = self,
            __types = {},
        }
        setmetatable(loader, { __index = DataTableSet })
        self.__current_group[k] = loader
    end

    table.insert(self.__history_versions, { version = current_version, loaders = self.__current_group })
    if #self.__history_versions > self.MaxGroupNumber then
        table.remove(self.__history_versions, 1)
    end
end

function DataTableService.ReloadTables(self)
    if package.loaded[self.IndexModuleName] ~= nil then
        package.loaded[self.IndexModuleName] = nil
    end

    if package.loaded["pb"] ~= nil then
        package.loaded["pb"] = nil
    end

    self:LoadTables()
end

return DataTableService
