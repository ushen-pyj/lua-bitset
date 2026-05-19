# 编译器
CC ?= gcc

# Lua 版本，可以按你的环境改
LUA_VERSION ?= 5.4

# Lua 头文件路径
# 常见路径：
# /usr/include/lua5.4
# /usr/local/include
# ./3rd/lua
LUA_INC ?= /usr/include/lua$(LUA_VERSION)

# 输出文件
TARGET = bitset.so

# 源文件
SRCS = bitset.c lua-bitset.c

# 编译参数
CFLAGS += -O2 -Wall -Wextra -fPIC -I$(LUA_INC)

# 链接参数
LDFLAGS += -shared

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRCS) bitset.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRCS)

clean:
	rm -f $(TARGET) *.o

test: $(TARGET)
	lua -e 'local bitset = require("bitset"); local bs = bitset.new(100); print(bs:set(10)); print(bs:test(10)); print(bs:count())'