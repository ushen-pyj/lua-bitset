# 编译器
CC ?= gcc


LUA_VERSION ?= 5.5

LUA_INC ?= /usr/include/lua$(LUA_VERSION)

TARGET = bitset.so

SRCS = bitset.c lua-bitset.c

CFLAGS += -O2 -Wall -Wextra -fPIC -I$(LUA_INC)

LDFLAGS += -shared

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(SRCS) bitset.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $(SRCS)

clean:
	rm -f $(TARGET) *.o

test: $(TARGET)
	lua -e 'local bitset = require("bitset"); local bs = bitset.new(100); print(bs:set(10)); print(bs:test(10)); print(bs:count())'