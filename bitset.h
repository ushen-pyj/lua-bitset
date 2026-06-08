#pragma once

#include <stdint.h>
#include <string.h>

struct bitset_t;

struct bitset_t *bitset_new(uint64_t size);
void bitset_free(struct bitset_t *bs);
int bit_count(struct bitset_t *bs);
int bit_set(struct bitset_t *bs, uint64_t index);
int bit_clear(struct bitset_t *bs, uint64_t index);
int bit_test(struct bitset_t *bs, uint64_t index);
int bit_flip(struct bitset_t *bs, uint64_t index);
int bit_fill(struct bitset_t *bs);
int bit_reset(struct bitset_t *bs);
int bit_set_range(struct bitset_t *bs, uint64_t start, uint64_t count);
int bit_clear_range(struct bitset_t *bs, uint64_t start, uint64_t count);
int bit_test_range(struct bitset_t *bs, uint64_t start, uint64_t count);