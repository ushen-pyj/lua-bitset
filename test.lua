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

print("ALL TESTS PASSED")