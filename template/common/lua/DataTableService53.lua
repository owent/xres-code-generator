-- Copyright 2023 xresloader. All rights reserved.

local CUSTOM_INDEX_MOD_NAME = 'DataTableCustomIndex53'
local MAX_VERSIONS = 5

local DataTableService = {
    __current_group = {},
    __history_versions = {},
    IndexModuleName = CUSTOM_INDEX_MOD_NAME,
    MaxGroupNumber = MAX_VERSIONS,
    OverrideSameVersion = true,
    VersionLoader = function()
        return ""
    end,
    OnError = nil -- Used for notice not found error, parameters is (message, data_set, indexName, keys...)
}

local DataTableSet = {}

-- ===================== DataTableSet =====================
local function __SetupIndexFromFile(data_container, index_cfg, index_file_path)
    local data_block = require(index_file_path)
    if data_block == nil then
        return
    end

    local all_rows = data_block[index_cfg.messageName]
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
        for _, keyv in ipairs(index_cfg.keys) do
            last_key = cfgv[keyv] or nil
            parent_node = cfg_item
            cfg_item = parent_node[last_key]
            if cfg_item == nil and last_key ~= nil then
                cfg_item = {}
                parent_node[last_key] = cfg_item
            end
        end

        if index_data.options.isList then
            table.insert(cfg_item, cfgv)
        elseif last_key ~= nil then
            parent_node[last_key] = cfgv
        end
    end

    data_container[index_cfg.indexName] = index_data
end

local function __SetupIndex(data_container, index_cfg)
    data_container[index_cfg.indexName] = nil
    for _, v in ipairs(index_cfg.filePath) do
        if v == nil then
            return
        end
        __SetupIndexFromFile(data_container, index_cfg, v)
    end
end

function DataTableSet.GetAllIndexes(self)
    return self.__indexes
end

function DataTableSet.GetByIndex(self, index_name, ...)
    -- lazy load index
    if self.__index_handles == nil then
        local data_container = {}

        for _, v in ipairs(self.__indexes) do
            __SetupIndex(data_container, v)
        end

        self.__index_handles = data_container
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
            __index_handles = nil
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

    self:LoadTables()
end

return DataTableService
