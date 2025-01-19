local FieldType = {
    [" - Members -----------------------------"] = "Members",
    [" - Privates -----------------------------"] = "Privates",
    [" - Objects -----------------------------"] = "Objects",
	[" - Custom data types -------------------"] = "Custom data types"
}

local CppTypeToLuaType = {
	uint64 = "integer",
	int64 = "integer",
	int32 = "integer",
    uint32_t = "integer",
    int = "integer",
	EntityID = "integer",
    EntityTypeID = "integer",
    ["LensValue<int>"] = "integer",
	["unsigned int"] = "integer",
	
	double = "number",
    float = "number",
    ["LensValue<float>"] = "number",
	
    bool = "boolean",
    ["LensValue<bool>"] = "boolean",
	
    ["std::string"] = "string",
	
    ["GAME_EFFECT::Enum"] = "noita_effect_enum",
    ["RAGDOLL_FX::Enum"] = "noita_ragdoll_fx",
	
    ["vec2"] = "field_vec2",
	["ivec2"] = "field_ivec2"
}
local comps = {

}

local function GetSplitSpaceText(t)
	local result = {}
	for word in string.gmatch(t, "%S+") do
		result[#result+1] = word
	end
	return result
end

local CurrentComp
local CurrentField
local CompList = {}

for v in io.lines("component_documentation.txt") do
	if v == "" then
		goto continue
	end

	local Field = FieldType[v]
	if Field then
		CurrentField = Field
		goto continue
	end
	local list = GetSplitSpaceText(v)
	if #list < 2 then--如果分割出来的不够多，那么应该是组件名
        CurrentComp = v
		CompList[#CompList+1] = v
		goto continue
	end

	--开始字段加载
    if comps[CurrentComp] == nil then
        comps[CurrentComp] = {}
    end
    
	if string.byte(list[2], 1, 1) == string.byte("-") or tonumber(list[2]) then --简单的字段名称合法性检测，不合法下一个
        goto continue
    end

    local fieldtype = CppTypeToLuaType[list[1]] or "unsupported"
    local desc = string.match(v, "%b\"\"")
	if desc then
        desc = string.gsub(desc, '"', "")
		if desc == "" then
			desc = nil
		end
	end
	--字段插入
    table.insert(comps[CurrentComp], {
        type = fieldtype,
        fieldname = list[2],
		field = CurrentField,
		desc = desc
	})
	::continue::
end

---生成类型注解
local file = io.open("EntityClassTypeHint.lua", "w")
file:write("---@class NoitaCompTo\n")

---生成组件索引转组件数组的注解
for _,v in ipairs(CompList) do
    local str = string.format("---@field %s %sClass[]\n", v, v)
	file:write(str)
end
file:write("\n")

---生成各个组件的字段
for _,v in ipairs(CompList) do
	local str = string.format([[---@class %sClass
---@field comp_id integer
---@field enable boolean
---@field attr %s

---@class %s]], v, v, v)
    file:write(str)
	file:write("\n")
    for _, field in ipairs(comps[v] or {}) do
        local desc = field.field
        if field.desc then
            desc = desc .. "<br>---<br>" .. field.desc
        end
        local fieldstr = string.format("---@field %s %s %s\n", field.fieldname, field.type, desc)
        file:write(fieldstr)
    end
	file:write("\n")
end

file:write("---@alias NoitaComponentNames ")
for _,v in ipairs(CompList) do
	local str = string.format("\"%s\"", v)
    file:write(str)
	file:write(" | ")
end
