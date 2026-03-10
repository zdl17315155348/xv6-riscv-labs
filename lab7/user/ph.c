// A simple hash table benchmark adapted to run on xv6 user space.
// This is a single-threaded port of notxv6/ph.c: it ignores pthreads
// and uses xv6 system calls and libc stubs.
//
// Usage in xv6:
//   ph [nthreads]
// The nthreads argument is accepted but ignored; the program runs single-threaded.

#include "kernel/types.h"
#include "user/user.h"

#define NBUCKET 5
#define NKEYS   100000

struct entry {
  int key;
  int value;
  struct entry *next;
};

static struct entry *table[NBUCKET];
static int keys[NKEYS];
static int nthread = 1;

// xv6 doesn't have gettimeofday; use uptime() ticks.
// Return ticks since boot.
static uint
now_ticks(void) {
  return (uint)uptime();
}

static void
insert(int key, int value, struct entry **p, struct entry *n)
{
  struct entry *e = (struct entry*)malloc(sizeof(struct entry));
  if(e == 0){
    printf("ph: out of memory\n");
    exit(1);
  }
  e->key = key;
  e->value = value;
  e->next = n;
  *p = e;
}

static void
put(int key, int value)
{
  int i = key % NBUCKET;
  if(i < 0) i = -i;
  // find if present
  struct entry *e;
  for (e = table[i]; e != 0; e = e->next) {
    if (e->key == key)
      break;
  }
  if(e){
    e->value = value;
  } else {
    insert(key, value, &table[i], table[i]);
  }
}

static struct entry*
get(int key)
{
  int i = key % NBUCKET;
  if(i < 0) i = -i;
  struct entry *e;
  for (e = table[i]; e != 0; e = e->next) {
    if (e->key == key) break;
  }
  return e;
}

// simple LCG pseudo-random generator
static uint
lcg(uint *state) {
  *state = (*state) * 1103515245u + 12345u;
  return *state;
}

int
main(int argc, char *argv[])
{
  if (argc >= 2) {
    nthread = atoi(argv[1]);
  }
  // single-threaded note
  if (nthread != 1) {
    printf("ph: running single-threaded; ignoring nthreads=%d\n", nthread);
  }

  // initialize random keys deterministically
  uint rnd = 0;
  for (int i = 0; i < NKEYS; i++) {
    keys[i] = (int)lcg(&rnd);
  }

  // puts
  uint t0 = now_ticks();
  for (int i = 0; i < NKEYS; i++) {
    put(keys[i], 1);
  }
  uint t1 = now_ticks();
  printf("%d puts, %d ticks\n", NKEYS, (int)(t1 - t0));

  // gets
  int missing = 0;
  t0 = now_ticks();
  for (int i = 0; i < NKEYS; i++) {
    if (get(keys[i]) == 0) missing++;
  }
  t1 = now_ticks();
  printf("%d gets, %d ticks, missing=%d\n", NKEYS, (int)(t1 - t0), missing);

  exit(0);
}

