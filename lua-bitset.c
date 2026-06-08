#include "lua.h"
#include "lauxlib.h"
#include "bitset.h"

#define BITSET_MT "bitset"

struct lua_bitset
{
    struct bitset_t *bs;
};

static uint64_t
check_index(lua_State *L, int idx)
{
    lua_Integer index = luaL_checkinteger(L, idx);
    if(index < 0){
        luaL_error(L, "index must be non-negative");
    }
    return (uint64_t)index;
}

static int
lbitset_set(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t index = check_index(L, 2);
    int res = bit_set(bs->bs, index);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_test(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t index = check_index(L, 2);
    int res = bit_test(bs->bs, index);
    lua_pushboolean(L, res == 1);
    return 1;
}

static int
lbitset_flip(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t index = check_index(L, 2);
    int res = bit_flip(bs->bs, index);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_fill(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    int res = bit_fill(bs->bs);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_reset(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    int res = bit_reset(bs->bs);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_count(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    lua_pushinteger(L, bit_count(bs->bs));
    return 1;
}

static int
lbitset_clear(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t index = check_index(L, 2);
    int res = bit_clear(bs->bs, index);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_set_range(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t start = check_index(L, 2);
    uint64_t count = check_index(L, 3);
    int res = bit_set_range(bs->bs, start, count);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_clear_range(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t start = check_index(L, 2);
    uint64_t count = check_index(L, 3);
    int res = bit_clear_range(bs->bs, start, count);
    lua_pushboolean(L, res == 0);
    return 1;
}

static int
lbitset_test_range(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t start = check_index(L, 2);
    uint64_t count = check_index(L, 3);
    int res = bit_test_range(bs->bs, start, count);
    lua_pushboolean(L, res == 1);
    return 1;
}

static int
lbitset_pack(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    uint64_t bit_size = bitset_size(bs->bs);
    size_t word_count = bitset_word_count(bs->bs);
    const uint64_t *words = bitset_words(bs->bs);

    lua_pushlstring(L, (const char *)&bit_size, sizeof(uint64_t));
    lua_pushlstring(L, (const char *)words, word_count * sizeof(uint64_t));
    lua_concat(L, 2);
    return 1;
}

static int
lbitset_unpack(lua_State *L)
{
    size_t len;
    const char *data = luaL_checklstring(L, 1, &len);

    if (len < sizeof(uint64_t)) {
        return luaL_error(L, "invalid packed data: too short");
    }

    uint64_t bit_size;
    memcpy(&bit_size, data, sizeof(uint64_t));

    size_t word_count = (bit_size / 64) + ((bit_size & 63) != 0);
    size_t expected_len = sizeof(uint64_t) + word_count * sizeof(uint64_t);

    if (len < expected_len) {
        return luaL_error(L, "invalid packed data: unexpected length");
    }

    struct lua_bitset *bs = lua_newuserdata(L, sizeof(struct lua_bitset));
    bs->bs = bitset_new(bit_size);
    if (bs->bs == NULL) {
        return luaL_error(L, "bitset_unpack: allocation failed");
    }

    memcpy(bitset_words(bs->bs), data + sizeof(uint64_t), word_count * sizeof(uint64_t));

    luaL_getmetatable(L, BITSET_MT);
    lua_setmetatable(L, -2);
    return 1;
}

static int
lbitset_free(lua_State *L)
{
    struct lua_bitset *bs = luaL_checkudata(L, 1, BITSET_MT);
    if (bs->bs != NULL) {
        bitset_free(bs->bs);
        bs->bs = NULL;
    }
    return 0;
}

static const luaL_Reg bitset_mt[] = {
    { "set", lbitset_set },
    { "test", lbitset_test },
    { "flip", lbitset_flip },
    { "fill", lbitset_fill },
    { "reset", lbitset_reset },
    { "count", lbitset_count },
    { "clear", lbitset_clear },
    { "set_range", lbitset_set_range },
    { "clear_range", lbitset_clear_range },
    { "test_range", lbitset_test_range },
    { "pack", lbitset_pack },
    { NULL, NULL }
};

static int
lbitset_new(lua_State *L)
{
    lua_Integer size = luaL_checkinteger(L, 1);
    if(size <= 0){
        return luaL_error(L, "size must be positive");
    }
    struct lua_bitset *bs = lua_newuserdata(L, sizeof(struct lua_bitset));
    bs->bs = bitset_new((uint64_t)size);
    if(bs->bs == NULL){
        luaL_error(L, "bitset_new failed");
    }
    luaL_getmetatable(L, BITSET_MT);
    lua_setmetatable(L, -2);
    return 1;
}

static const luaL_Reg bitset[] = {
    { "new", lbitset_new },
    { "unpack", lbitset_unpack },
    { NULL, NULL }
};

int
luaopen_bitset(lua_State *L)
{   
    luaL_newmetatable(L, BITSET_MT);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "__index");
    luaL_setfuncs(L, bitset_mt, 0);
    lua_pushcfunction(L, lbitset_free);
    lua_setfield(L, -2, "__gc");
    luaL_newlib(L, bitset);
    return 1;
}