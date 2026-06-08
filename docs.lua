---@meta bitset

---@class bitset
---@field [1] fun(self: bitset, index: integer): boolean Set a bit (returns true on success)
---@field [2] fun(self: bitset, index: integer): boolean Clear a bit (returns true on success)
---@field [3] fun(self: bitset, index: integer): boolean Test a bit
---@field [4] fun(self: bitset, index: integer): boolean Flip a bit (returns true on success)
---@field [5] fun(self: bitset): integer Count of set bits
---@field [6] fun(self: bitset): boolean Fill all bits (returns true on success)
---@field [7] fun(self: bitset): boolean Reset all bits (returns true on success)
---@field [8] fun(self: bitset, start: integer, count: integer): boolean Set a range of bits (returns true on success)
---@field [9] fun(self: bitset, start: integer, count: integer): boolean Clear a range of bits (returns true on success)
---@field [10] fun(self: bitset, start: integer, count: integer): boolean Test if all bits in a range are set
local bitset_methods = {}

local bitset = {}

---@param index integer
---@return boolean
function bitset_methods:set(index) end

---@param index integer
---@return boolean
function bitset_methods:clear(index) end

---@param index integer
---@return boolean
function bitset_methods:test(index) end

---@param index integer
---@return boolean
function bitset_methods:flip(index) end

---@return integer
function bitset_methods:count() end

---@return boolean
function bitset_methods:fill() end

---@return boolean
function bitset_methods:reset() end

---@param start integer
---@param count integer
---@return boolean
function bitset_methods:set_range(start, count) end

---@param start integer
---@param count integer
---@return boolean
function bitset_methods:clear_range(start, count) end

---@param start integer
---@param count integer
---@return boolean
function bitset_methods:test_range(start, count) end

---@return string
function bitset_methods:pack() end

---@param size integer
---@return bitset
function bitset.new(size) end

---@param data string
---@return bitset
function bitset.unpack(data) end
