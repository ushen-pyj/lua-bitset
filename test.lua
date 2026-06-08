-- test_bitset.lua

-- 确保当前目录可以找到 bitset.so
package.cpath = "./?.so;" .. package.cpath

local bitset = require "bitset"

local function assert_eq(actual, expected, msg)
    if actual ~= expected then
        error(string.format(
            "%s\nexpected: %s\nactual:   %s",
            msg or "assert_eq failed",
            tostring(expected),
            tostring(actual)
        ), 2)
    end
end

local function assert_true(v, msg)
    assert_eq(v, true, msg)
end

local function assert_false(v, msg)
    assert_eq(v, false, msg)
end

local function assert_error(fn, msg)
    local ok = pcall(fn)
    if ok then
        error(msg or "expected error, but no error raised", 2)
    end
end

print("== basic require ==")
assert(bitset ~= nil, "require bitset failed")
assert(type(bitset.new) == "function", "bitset.new should be function")

print("== create bitset ==")
local bs = bitset.new(100)
assert(bs ~= nil, "bitset.new(100) failed")

print("== initial state ==")
assert_eq(bs:count(), 0, "new bitset count should be 0")

for i = 0, 99 do
    assert_false(bs:test(i), "new bit should be false: index=" .. i)
end

print("== set / test ==")
assert_true(bs:set(0), "set 0 failed")
assert_true(bs:test(0), "test 0 should be true")
assert_eq(bs:count(), 1, "count should be 1 after set 0")

assert_true(bs:set(10), "set 10 failed")
assert_true(bs:test(10), "test 10 should be true")
assert_eq(bs:count(), 2, "count should be 2 after set 10")

assert_true(bs:set(99), "set 99 failed")
assert_true(bs:test(99), "test 99 should be true")
assert_eq(bs:count(), 3, "count should be 3 after set 99")

print("== duplicate set ==")
assert_true(bs:set(10), "duplicate set 10 failed")
assert_true(bs:test(10), "test 10 should still be true")
assert_eq(bs:count(), 3, "duplicate set should not increase count")

print("== clear ==")
assert_true(bs:clear(10), "clear 10 failed")
assert_false(bs:test(10), "test 10 should be false after clear")
assert_eq(bs:count(), 2, "count should be 2 after clear 10")

assert_true(bs:clear(10), "duplicate clear 10 failed")
assert_false(bs:test(10), "test 10 should still be false")
assert_eq(bs:count(), 2, "duplicate clear should not change count")

print("== flip ==")
assert_false(bs:test(20), "20 should initially be false")
assert_true(bs:flip(20), "flip 20 failed")
assert_true(bs:test(20), "20 should be true after flip")
assert_eq(bs:count(), 3, "count should be 3 after flip 20 on")

assert_true(bs:flip(20), "flip 20 second time failed")
assert_false(bs:test(20), "20 should be false after second flip")
assert_eq(bs:count(), 2, "count should be 2 after flip 20 off")

print("== reset ==")
assert_true(bs:reset(), "reset failed")
assert_eq(bs:count(), 0, "count should be 0 after reset")

for i = 0, 99 do
    assert_false(bs:test(i), "bit should be false after reset: index=" .. i)
end

print("== fill ==")
assert_true(bs:fill(), "fill failed")
assert_eq(bs:count(), 100, "count should be exactly bit size after fill")

for i = 0, 99 do
    assert_true(bs:test(i), "bit should be true after fill: index=" .. i)
end

print("== boundary: size 1 ==")
local bs1 = bitset.new(1)
assert_eq(bs1:count(), 0, "size 1 initial count should be 0")
assert_false(bs1:test(0), "size 1 index 0 should initially be false")
assert_true(bs1:set(0), "size 1 set 0 failed")
assert_true(bs1:test(0), "size 1 test 0 should be true")
assert_eq(bs1:count(), 1, "size 1 count should be 1")
assert_true(bs1:clear(0), "size 1 clear 0 failed")
assert_false(bs1:test(0), "size 1 test 0 should be false after clear")
assert_eq(bs1:count(), 0, "size 1 count should be 0 after clear")
assert_true(bs1:fill(), "size 1 fill failed")
assert_eq(bs1:count(), 1, "size 1 count after fill should be 1")

print("== boundary: around uint64 word boundary ==")
local bs64 = bitset.new(64)
assert_true(bs64:set(0), "set 0 failed")
assert_true(bs64:set(63), "set 63 failed")
assert_true(bs64:test(0), "test 0 should be true")
assert_true(bs64:test(63), "test 63 should be true")
assert_eq(bs64:count(), 2, "size 64 count should be 2")

assert_true(bs64:fill(), "size 64 fill failed")
assert_eq(bs64:count(), 64, "size 64 count after fill should be 64")

local bs65 = bitset.new(65)
assert_true(bs65:set(0), "size 65 set 0 failed")
assert_true(bs65:set(63), "size 65 set 63 failed")
assert_true(bs65:set(64), "size 65 set 64 failed")
assert_true(bs65:test(0), "size 65 test 0 should be true")
assert_true(bs65:test(63), "size 65 test 63 should be true")
assert_true(bs65:test(64), "size 65 test 64 should be true")
assert_eq(bs65:count(), 3, "size 65 count should be 3")

assert_true(bs65:fill(), "size 65 fill failed")
assert_eq(bs65:count(), 65, "size 65 count after fill should be 65, not 128")

print("== boundary: non-64-aligned sizes ==")
for _, size in ipairs({2, 3, 7, 8, 9, 10, 31, 32, 33, 63, 64, 65, 66, 100, 127, 128, 129}) do
    local b = bitset.new(size)

    assert_eq(b:count(), 0, "initial count should be 0, size=" .. size)

    assert_true(b:set(0), "set first bit failed, size=" .. size)
    assert_true(b:test(0), "test first bit failed, size=" .. size)

    assert_true(b:set(size - 1), "set last bit failed, size=" .. size)
    assert_true(b:test(size - 1), "test last bit failed, size=" .. size)

    local expected_count = size == 1 and 1 or 2
    assert_eq(b:count(), expected_count, "count after setting first and last, size=" .. size)

    assert_true(b:reset(), "reset failed, size=" .. size)
    assert_eq(b:count(), 0, "count after reset should be 0, size=" .. size)

    assert_true(b:fill(), "fill failed, size=" .. size)
    assert_eq(b:count(), size, "count after fill should equal size, size=" .. size)
end

print("== out of range behavior ==")
local b10 = bitset.new(10)

-- 这里按你当前设计：越界 set/clear/flip 返回 false
assert_false(b10:set(10), "set index == size should fail")
assert_false(b10:set(100), "set out of range should fail")
assert_false(b10:clear(10), "clear index == size should fail")
assert_false(b10:clear(100), "clear out of range should fail")
assert_false(b10:flip(10), "flip index == size should fail")
assert_false(b10:flip(100), "flip out of range should fail")

-- test 越界这里要看你的实现。
-- 推荐设计：越界 test 返回 false。
assert_false(b10:test(10), "test index == size should be false")
assert_false(b10:test(100), "test out of range should be false")

print("== invalid arguments ==")
assert_error(function()
    bitset.new(0)
end, "bitset.new(0) should error")

assert_error(function()
    bitset.new(-1)
end, "bitset.new(-1) should error")

assert_error(function()
    b10:set(-1)
end, "set(-1) should error")

assert_error(function()
    b10:test(-1)
end, "test(-1) should error")

assert_error(function()
    b10:clear(-1)
end, "clear(-1) should error")

assert_error(function()
    b10:flip(-1)
end, "flip(-1) should error")

print("== stress small range ==")
local n = 1000
local b = bitset.new(n)

for i = 0, n - 1 do
    assert_false(b:test(i), "initial bit should be false: " .. i)
end
assert_eq(b:count(), 0, "initial count should be 0")

for i = 0, n - 1, 2 do
    assert_true(b:set(i), "set even bit failed: " .. i)
end

assert_eq(b:count(), 500, "after setting even bits, count should be 500")

for i = 0, n - 1 do
    if i % 2 == 0 then
        assert_true(b:test(i), "even bit should be true: " .. i)
    else
        assert_false(b:test(i), "odd bit should be false: " .. i)
    end
end

for i = 0, n - 1, 2 do
    assert_true(b:clear(i), "clear even bit failed: " .. i)
end

assert_eq(b:count(), 0, "after clearing even bits, count should be 0")

print("== range: set_range / test_range / clear_range basic ==")
local br = bitset.new(100)
assert_true(br:set_range(0, 10), "set_range(0, 10) failed")
assert_eq(br:count(), 10, "count should be 10 after set_range(0, 10)")

-- test_range should return true when all bits in range are set
assert_true(br:test_range(0, 10), "test_range(0, 10) should be true")

-- test_range should return false when some bits are clear
assert_false(br:test_range(0, 11), "test_range(0, 11) should be false (bit 10 not set)")

-- clear range
assert_true(br:clear_range(0, 5), "clear_range(0, 5) failed")
assert_eq(br:count(), 5, "count should be 5 after clear_range(0, 5)")
assert_false(br:test_range(0, 5), "test_range(0, 5) should be false after clear")
assert_true(br:test_range(5, 5), "test_range(5, 5) should still be true")

-- clear remaining
assert_true(br:clear_range(5, 5), "clear_range(5, 5) failed")
assert_eq(br:count(), 0, "count should be 0 after clearing all")

print("== range: count=1 degenerate (single bit) ==")
local b1 = bitset.new(10)
assert_true(b1:set_range(3, 1), "set_range(3, 1) failed")
assert_true(b1:test(3), "test(3) should be true")
assert_eq(b1:count(), 1, "count should be 1")
assert_true(b1:test_range(3, 1), "test_range(3, 1) should be true")
assert_true(b1:clear_range(3, 1), "clear_range(3, 1) failed")
assert_false(b1:test(3), "test(3) should be false after clear_range")

print("== range: full word boundary ==")
local bw = bitset.new(128)
assert_true(bw:set_range(60, 10), "set_range(60, 10) cross boundary failed")
assert_eq(bw:count(), 10, "count should be 10")
assert_true(bw:test_range(60, 10), "test_range(60, 10) should be true")

-- verify individual bits
for i = 0, 127 do
    if i >= 60 and i < 70 then
        assert_true(bw:test(i), "bit " .. i .. " should be true")
    else
        assert_false(bw:test(i), "bit " .. i .. " should be false")
    end
end

assert_true(bw:clear_range(60, 10), "clear_range(60, 10) failed")
assert_eq(bw:count(), 0, "count should be 0 after clear_range cross boundary")

print("== range: entire bitset ==")
local be = bitset.new(200)
assert_true(be:set_range(0, 200), "set_range(0, 200) failed")
assert_eq(be:count(), 200, "count should be 200")
assert_true(be:test_range(0, 200), "test_range(0, 200) should be true")

assert_true(be:clear_range(0, 200), "clear_range(0, 200) failed")
assert_eq(be:count(), 0, "count should be 0")

-- fill and test range 0..size
assert_true(be:fill(), "fill failed")
assert_true(be:test_range(0, 200), "test_range(0, 200) should be true after fill")

print("== range: set_range after fill (no-op) ==")
local bf = bitset.new(64)
assert_true(bf:fill(), "fill failed")
assert_true(bf:test_range(0, 64), "test_range(0, 64) should be true after fill")
-- setting already-set bits should be fine
assert_true(bf:set_range(0, 64), "set_range(0, 64) on filled bitset failed")
assert_eq(bf:count(), 64, "count should still be 64")

print("== range: out of bounds ==")
local bo = bitset.new(50)
assert_false(bo:set_range(0, 51), "set_range(0, 51) should fail (exceeds size)")
assert_false(bo:set_range(50, 1), "set_range(50, 1) should fail (start == size)")
assert_false(bo:set_range(49, 2), "set_range(49, 2) should fail (start+count > size)")
assert_false(bo:clear_range(0, 51), "clear_range(0, 51) should fail")
assert_false(bo:clear_range(50, 1), "clear_range(50, 1) should fail")
assert_false(bo:test_range(50, 1), "test_range(50, 1) should be false (out of bounds)")
assert_false(bo:test_range(0, 51), "test_range(0, 51) should be false (out of bounds)")

print("== range: count=0 edge case ==")
local bz = bitset.new(10)
assert_false(bz:set_range(0, 0), "set_range(0, 0) should fail")
assert_false(bz:clear_range(0, 0), "clear_range(0, 0) should fail")
assert_false(bz:test_range(0, 0), "test_range(0, 0) should fail")

print("== range: stress multi-word ==")
local bs = bitset.new(1000)
-- set every other block of 10
for i = 0, 99 do
    local start = i * 10
    if i % 2 == 0 then
        assert_true(bs:set_range(start, 10), "set_range(" .. start .. ", 10) failed")
    end
end
assert_eq(bs:count(), 500, "count should be 500 after setting 50 blocks of 10")

-- verify
for i = 0, 99 do
    local start = i * 10
    if i % 2 == 0 then
        assert_true(bs:test_range(start, 10), "test_range(" .. start .. ", 10) should be true")
    else
        assert_false(bs:test_range(start, 10), "test_range(" .. start .. ", 10) should be false")
    end
end

-- clear all
for i = 0, 99 do
    if i % 2 == 0 then
        assert_true(bs:clear_range(i * 10, 10), "clear_range failed")
    end
end
assert_eq(bs:count(), 0, "count should be 0 after clearing all blocks")

print("== range: various sizes and alignments ==")
for _, size in ipairs({1, 2, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256}) do
    local b = bitset.new(size)
    -- set the whole thing
    assert_true(b:set_range(0, size), "set_range(0, " .. size .. ") failed")
    assert_eq(b:count(), size, "count should be " .. size)
    assert_true(b:test_range(0, size), "test_range(0, " .. size .. ") should be true")
    -- clear it
    assert_true(b:clear_range(0, size), "clear_range(0, " .. size .. ") failed")
    assert_eq(b:count(), 0, "count should be 0 after clear_range for size " .. size)
end

print("== pack / unpack: basic round-trip ==")
local bp = bitset.new(100)
bp:set(0)
bp:set(50)
bp:set(99)
local packed = bp:pack()
assert(type(packed) == "string", "pack should return a string")
local bp2 = bitset.unpack(packed)
assert(bp2 ~= nil, "unpack should return a bitset")
assert_eq(bp2:count(), 3, "round-trip count should be 3")
assert_true(bp2:test(0), "round-trip bit 0 should be true")
assert_true(bp2:test(50), "round-trip bit 50 should be true")
assert_true(bp2:test(99), "round-trip bit 99 should be true")
assert_false(bp2:test(1), "round-trip bit 1 should be false")
assert_false(bp2:test(98), "round-trip bit 98 should be false")

print("== pack / unpack: empty bitset ==")
local be2 = bitset.new(200)
local pe = be2:pack()
local be3 = bitset.unpack(pe)
assert_eq(be3:count(), 0, "empty bitset count should be 0")
for i = 0, 199 do
    assert_false(be3:test(i), "empty bitset bit " .. i .. " should be false")
end

print("== pack / unpack: filled bitset ==")
local bf2 = bitset.new(128)
bf2:fill()
local pf = bf2:pack()
local bf3 = bitset.unpack(pf)
assert_eq(bf3:count(), 128, "filled bitset count should be 128")
assert_true(bf3:test_range(0, 128), "filled bitset test_range should be true")

print("== pack / unpack: various sizes ==")
for _, size in ipairs({1, 2, 31, 32, 33, 63, 64, 65, 127, 128, 129, 255, 256, 1000}) do
    local orig = bitset.new(size)
    -- set a pattern: every 3rd bit
    for i = 0, size - 1, 3 do
        orig:set(i)
    end
    local expected_count = orig:count()
    local data = orig:pack()
    local restored = bitset.unpack(data)
    assert_eq(restored:count(), expected_count,
        "count mismatch after round-trip, size=" .. size)
    for i = 0, size - 1 do
        local expected = orig:test(i)
        local actual = restored:test(i)
        if expected ~= actual then
            error(string.format(
                "bit mismatch at index %d, size=%d: expected %s, got %s",
                i, size, tostring(expected), tostring(actual)
            ), 2)
        end
    end
end

print("== pack / unpack: pattern after fill and reset ==")
local bp3 = bitset.new(64)
bp3:fill()
bp3:reset()
bp3:set(0)
bp3:set(63)
local p3 = bp3:pack()
local bp4 = bitset.unpack(p3)
assert_eq(bp4:count(), 2, "count should be 2")
assert_true(bp4:test(0), "bit 0 should be true")
assert_true(bp4:test(63), "bit 63 should be true")
assert_false(bp4:test(1), "bit 1 should be false")

print("== unpack: invalid data ==")
assert_error(function()
    bitset.unpack("")
end, "unpack empty string should error")

assert_error(function()
    bitset.unpack("short")
end, "unpack short string should error")

print("ALL TESTS PASSED")