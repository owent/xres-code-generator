
local CUSTOM_INDEX_MOD_NAME = 'DataTableCustomIndex53'

local DataTableService = {
    _all_loaders = {}
}

local DataTableIndex = {}

-- ===================== DataTableIndex =====================
local function _SetupIndex(data_container, index_cfg)
    local data_block = require(index_cfg.filePath)
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

    local index_data = {
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
            if cfg_item == nil then
                cfg_item = {}
                parent_node[last_key] = cfg_item
            end
        end

        if index_data.options.isList then
            table.insert(cfg_item, cfgv)
        else
            parent_node[last_key] = cfgv
        end
    end

    data_container[index_cfg.indexName] = index_data
end

function DataTableIndex.GetByIndex(self, index_name, ...)
    -- lazy load index
    if self._index_handles == nil then
        local data_container = {}

        for _, v in ipairs(self._indexes) do
            _SetupIndex(data_container, v, allRow)
        end

        self._index_handles = data_container
    end

    local index_set = self._index_handles[index_name]
    if index_set == nil then
        return nil
    end

    local data_set = index_set.data or {}
    for k, v in ipairs({...}) do
        local select_set = data_set[v]
        if select_set ~= nil then
            data_set = select_set
        else
            if index_set.options.isList then
                return {}
            else
                -- if index_set.options.allowNotFound then
                --     return nil
                -- else
                --     return nil
                -- end
                return nil
            end
        end
    end

    return data_set or {}
end

-- ===================== DataTableService =====================
function DataTableService.Get(self, loader_name)
    if nil == loader_name then
        return nil
    end

    return self._all_loaders[loader_name]
end

function DataTableService.LoadTables(self)
    local index_mapping = require(CUSTOM_INDEX_MOD_NAME)
    for k, v in pairs(index_mapping) do
        local loader = {
            _indexes = v,
            _index_handles = nil
        }
        setmetatable(loader, {__index = DataTableIndex})
        self._all_loaders[k] = loader
    end
end

function DataTableService.ReloadTables(self)
    if package.loaded[CUSTOM_INDEX_MOD_NAME] ~= nil then
        package.loaded[CUSTOM_INDEX_MOD_NAME] = nil
    end

    self:LoadTables()
end

return DataTableService