#include "bitset.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stddef.h>

struct bitset_t
{
    uint64_t *words;
    size_t word_count;
    uint64_t bit_size;
};

struct bitset_t*
bitset_new(uint64_t size)
{
    struct bitset_t *bs = malloc(sizeof(*bs));
    if (bs == NULL) {
        return NULL;
    }

    bs->word_count = (size / 64) + ((size & 63) != 0);
    bs->bit_size = size;
    if (bs->word_count > SIZE_MAX / sizeof(uint64_t)) {
        free(bs);
        return NULL;
    }
    bs->words = calloc(bs->word_count, sizeof(uint64_t));
    if (bs->words == NULL) {
        free(bs);
        return NULL;
    }
    return bs;
}

void
bitset_free(struct bitset_t *bs)
{
    if(bs == NULL) return;
    free(bs->words);
    free(bs);
}

static inline int
get_index(struct bitset_t *bs, uint64_t index, size_t *word_index, size_t *bit_index)
{
    if(index >= bs->bit_size)
    {
        return -1;
    }
    *word_index = index >> 6;
    *bit_index = index & 63;
    return 0;
}

int
bit_set(struct bitset_t *bs, uint64_t index)
{
    size_t word_index, bit_index;
    if(get_index(bs, index, &word_index, &bit_index) != 0)
    {
        return 1;
    }
    bs->words[word_index] |= (1ULL << bit_index);
    return 0;
}

int 
bit_clear(struct bitset_t *bs, uint64_t index)
{
    size_t word_index, bit_index;
    if(get_index(bs, index, &word_index, &bit_index) != 0)
    {
        return 1;
    }
    bs->words[word_index] &= ~(1ULL << bit_index);
    return 0;
}

int 
bit_test(struct bitset_t *bs, uint64_t index)
{
    size_t word_index, bit_index;
    if(get_index(bs, index, &word_index, &bit_index) != 0)
    {
        return -1;
    }
    return (bs->words[word_index] & (1ULL << bit_index)) != 0;
}

int 
bit_flip(struct bitset_t *bs, uint64_t index)
{
    size_t word_index, bit_index;
    if(get_index(bs, index, &word_index, &bit_index) != 0)
    {
        return 1;
    }
    bs->words[word_index] ^= (1ULL << bit_index);
    return 0;
}

int
bit_reset(struct bitset_t *bs)
{
    memset(bs->words, 0, sizeof(uint64_t) * bs->word_count);
    return 0;
}

int
bit_fill(struct bitset_t *bs)
{
    memset(bs->words, ~0, sizeof(uint64_t) * bs->word_count);
    int remain = bs->bit_size & 63;
    if (remain != 0 && bs->word_count > 0) {
        uint64_t mask = (1ULL << remain) - 1;
        bs->words[bs->word_count - 1] &= mask;
    }
    return 0;
}

int
bit_count(struct bitset_t *bs)
{
    int count = 0;
    for(size_t i = 0; i < bs->word_count; i++)
    {
        count += __builtin_popcountll(bs->words[i]);
    }
    return count;
}

int
bit_size(struct bitset_t *bs)
{
    return bs->bit_size;
}
int
bit_any(struct bitset_t *bs)
{
    for(size_t i = 0; i < bs->word_count; i++)
    {
        if(bs->words[i] != 0)
        {
            return 1;
        }
    }
    return 0;
}

int
bit_none(struct bitset_t *bs)
{
    for(size_t i = 0; i < bs->word_count; i++)
    {
        if(bs->words[i] != 0)
        {
            return 0;
        }
    }
    return 1;
}


