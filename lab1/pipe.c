#include "kernel/types.h"
#include "user/user.h"

static int atoi_simple(const char *s)
{
  int n = 0;
  if(s == 0) return -1;
  for(; *s; s++){
    if(*s < '0' || *s > '9')
      return -1;
    n = n * 10 + (*s - '0');
  }
  return n;
}

int main(int argc, char *argv[])
{
  int fts[2]; // father -> son
  int stf[2]; // son -> father
  char b = 'x';
  int pid;

  // 1) 创建两条管道
  if(pipe(fts) < 0 || pipe(stf) < 0){
    fprintf(2, "pipe failed\n");
    exit(1);
  }

  pid = fork();
  if(pid < 0){
    fprintf(2, "fork failed\n");
    exit(1);
  }

  int N = 10000; //default 10000 times
  if(argc >= 2){
    int x = atoi_simple(argv[1]);
    if(x <= 0){
      fprintf(2, "usage: pipe [N]\n");
      fprintf(2, "  N must be a positive integer\n");
      exit(1);
    }
    N = x;
  }

  // 2) 子进程：每轮 read(fts) -> write(stf)
  if(pid == 0){
    close(fts[1]); // 子不用写 fts
    close(stf[0]); // 子不用读 stf

    for(int i = 0; i < N; i++){
      if(read(fts[0], &b, 1) != 1){
        fprintf(2, "child read failed\n");
        exit(1);
      }
      if(write(stf[1], &b, 1) != 1){
        fprintf(2, "child write failed\n");
        exit(1);
      }
    }

    close(fts[0]);
    close(stf[1]);
    exit(0);
  }

  // 3) 父进程：计时 + 每轮 write(fts) -> read(stf)
  close(fts[0]); // 父不用读 fts
  close(stf[1]); // 父不用写 stf


  int t0 = uptime();

  for(int i = 0; i < N; i++){
    if(write(fts[1], &b, 1) != 1){
      fprintf(2, "parent write failed\n");
      exit(1);
    }
    if(read(stf[0], &b, 1) != 1){
      fprintf(2, "parent read failed\n");
      exit(1);
    }
  }

  int t1 = uptime();
  int dt = t1 - t0;

  close(fts[1]);
  close(stf[0]);

  wait(0);

  // 4) 输出性能结果
  int ticks_per_sec = 100;

  if(dt <= 0){
    printf("dt=%d ticks; try larger N\n", dt);
    exit(0);
  }

  int xps = (N * ticks_per_sec) / dt;

  printf("exchanges: %d, time: %d ticks, exchanges/sec: %d\n", N, dt, xps);
  exit(0);
}

