#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
  int n = 3;
  int rounds = 3;
  if(argc >= 2) n = atoi(argv[1]);
  if(argc >= 3) rounds = atoi(argv[2]);
  if(n <= 0) n = 1;
  if(rounds <= 0) rounds = 1;

  int ready[2];
  int release[2];
  if(pipe(ready) < 0 || pipe(release) < 0){
    printf("barrier: pipe failed\n");
    exit(1);
  }

  for(int i = 0; i < n; i++){
    int pid = fork();
    if(pid < 0){
      printf("barrier: fork failed\n");
      exit(1);
    }
    if(pid == 0){
      close(ready[0]);
      close(release[1]);
      char x = 'x';
      char y;
      for(int r = 0; r < rounds; r++){
        if(write(ready[1], &x, 1) != 1){
          printf("barrier: child write failed\n");
          exit(1);
        }
        if(read(release[0], &y, 1) != 1){
          printf("barrier: child read failed\n");
          exit(1);
        }
      }
      close(ready[1]);
      close(release[0]);
      exit(0);
    }
  }

  close(ready[1]);
  close(release[0]);
  char b;
  char x = 'x';
  for(int r = 0; r < rounds; r++){
    int cnt = 0;
    while(cnt < n){
      int m = read(ready[0], &b, 1);
      if(m < 0){
        printf("barrier: parent read failed\n");
        exit(1);
      }
      if(m == 1) cnt++;
    }
    for(int i = 0; i < n; i++){
      if(write(release[1], &x, 1) != 1){
        printf("barrier: parent write failed\n");
        exit(1);
      }
    }
  }
  for(int i = 0; i < n; i++){
    wait(0);
  }
  close(ready[0]);
  close(release[1]);
  exit(0);
}

