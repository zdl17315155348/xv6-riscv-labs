
user/_barrier:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int
main(int argc, char *argv[])
{
   0:	711d                	addi	sp,sp,-96
   2:	ec86                	sd	ra,88(sp)
   4:	e8a2                	sd	s0,80(sp)
   6:	e4a6                	sd	s1,72(sp)
   8:	e0ca                	sd	s2,64(sp)
   a:	fc4e                	sd	s3,56(sp)
   c:	f852                	sd	s4,48(sp)
   e:	f456                	sd	s5,40(sp)
  10:	1080                	addi	s0,sp,96
  12:	84aa                	mv	s1,a0
  14:	892e                	mv	s2,a1
  int n = 3;
  int rounds = 3;
  if(argc >= 2) n = atoi(argv[1]);
  16:	4785                	li	a5,1
  int n = 3;
  18:	4a0d                	li	s4,3
  if(argc >= 2) n = atoi(argv[1]);
  1a:	06a7ce63          	blt	a5,a0,96 <main+0x96>
  if(argc >= 3) rounds = atoi(argv[2]);
  1e:	4789                	li	a5,2
  int rounds = 3;
  20:	4a8d                	li	s5,3
  if(argc >= 3) rounds = atoi(argv[2]);
  22:	0897c163          	blt	a5,s1,a4 <main+0xa4>
  if(n <= 0) n = 1;
  if(rounds <= 0) rounds = 1;

  int ready[2];
  int release[2];
  if(pipe(ready) < 0 || pipe(release) < 0){
  26:	fb840513          	addi	a0,s0,-72
  2a:	00000097          	auipc	ra,0x0
  2e:	4ac080e7          	jalr	1196(ra) # 4d6 <pipe>
  32:	08054163          	bltz	a0,b4 <main+0xb4>
  36:	fb040513          	addi	a0,s0,-80
  3a:	00000097          	auipc	ra,0x0
  3e:	49c080e7          	jalr	1180(ra) # 4d6 <pipe>
  42:	06054963          	bltz	a0,b4 <main+0xb4>
  46:	89d2                	mv	s3,s4
  48:	09405363          	blez	s4,ce <main+0xce>
  4c:	2981                	sext.w	s3,s3
  4e:	8a56                	mv	s4,s5
  50:	09505163          	blez	s5,d2 <main+0xd2>
  54:	2a01                	sext.w	s4,s4
    printf("barrier: pipe failed\n");
    exit(1);
  }

  for(int i = 0; i < n; i++){
  56:	4901                	li	s2,0
    int pid = fork();
  58:	00000097          	auipc	ra,0x0
  5c:	466080e7          	jalr	1126(ra) # 4be <fork>
  60:	84aa                	mv	s1,a0
    if(pid < 0){
  62:	06054a63          	bltz	a0,d6 <main+0xd6>
      printf("barrier: fork failed\n");
      exit(1);
    }
    if(pid == 0){
  66:	c549                	beqz	a0,f0 <main+0xf0>
  for(int i = 0; i < n; i++){
  68:	2905                	addiw	s2,s2,1
  6a:	ff2997e3          	bne	s3,s2,58 <main+0x58>
      close(release[0]);
      exit(0);
    }
  }

  close(ready[1]);
  6e:	fbc42503          	lw	a0,-68(s0)
  72:	00000097          	auipc	ra,0x0
  76:	47c080e7          	jalr	1148(ra) # 4ee <close>
  close(release[0]);
  7a:	fb042503          	lw	a0,-80(s0)
  7e:	00000097          	auipc	ra,0x0
  82:	470080e7          	jalr	1136(ra) # 4ee <close>
  char b;
  char x = 'x';
  86:	07800793          	li	a5,120
  8a:	faf40723          	sb	a5,-82(s0)
  for(int r = 0; r < rounds; r++){
  8e:	4901                	li	s2,0
    int cnt = 0;
  90:	4481                	li	s1,0
        printf("barrier: parent read failed\n");
        exit(1);
      }
      if(m == 1) cnt++;
    }
    for(int i = 0; i < n; i++){
  92:	4a81                	li	s5,0
  94:	a21d                	j	1ba <main+0x1ba>
  if(argc >= 2) n = atoi(argv[1]);
  96:	6588                	ld	a0,8(a1)
  98:	00000097          	auipc	ra,0x0
  9c:	32e080e7          	jalr	814(ra) # 3c6 <atoi>
  a0:	8a2a                	mv	s4,a0
  a2:	bfb5                	j	1e <main+0x1e>
  if(argc >= 3) rounds = atoi(argv[2]);
  a4:	01093503          	ld	a0,16(s2)
  a8:	00000097          	auipc	ra,0x0
  ac:	31e080e7          	jalr	798(ra) # 3c6 <atoi>
  b0:	8aaa                	mv	s5,a0
  b2:	bf95                	j	26 <main+0x26>
    printf("barrier: pipe failed\n");
  b4:	00001517          	auipc	a0,0x1
  b8:	92c50513          	addi	a0,a0,-1748 # 9e0 <malloc+0xe4>
  bc:	00000097          	auipc	ra,0x0
  c0:	782080e7          	jalr	1922(ra) # 83e <printf>
    exit(1);
  c4:	4505                	li	a0,1
  c6:	00000097          	auipc	ra,0x0
  ca:	400080e7          	jalr	1024(ra) # 4c6 <exit>
  ce:	4985                	li	s3,1
  d0:	bfb5                	j	4c <main+0x4c>
  d2:	4a05                	li	s4,1
  d4:	b741                	j	54 <main+0x54>
      printf("barrier: fork failed\n");
  d6:	00001517          	auipc	a0,0x1
  da:	92250513          	addi	a0,a0,-1758 # 9f8 <malloc+0xfc>
  de:	00000097          	auipc	ra,0x0
  e2:	760080e7          	jalr	1888(ra) # 83e <printf>
      exit(1);
  e6:	4505                	li	a0,1
  e8:	00000097          	auipc	ra,0x0
  ec:	3de080e7          	jalr	990(ra) # 4c6 <exit>
      close(ready[0]);
  f0:	fb842503          	lw	a0,-72(s0)
  f4:	00000097          	auipc	ra,0x0
  f8:	3fa080e7          	jalr	1018(ra) # 4ee <close>
      close(release[1]);
  fc:	fb442503          	lw	a0,-76(s0)
 100:	00000097          	auipc	ra,0x0
 104:	3ee080e7          	jalr	1006(ra) # 4ee <close>
      char x = 'x';
 108:	07800793          	li	a5,120
 10c:	faf40623          	sb	a5,-84(s0)
        if(write(ready[1], &x, 1) != 1){
 110:	4605                	li	a2,1
 112:	fac40593          	addi	a1,s0,-84
 116:	fbc42503          	lw	a0,-68(s0)
 11a:	00000097          	auipc	ra,0x0
 11e:	3cc080e7          	jalr	972(ra) # 4e6 <write>
 122:	4785                	li	a5,1
 124:	04f51263          	bne	a0,a5,168 <main+0x168>
        if(read(release[0], &y, 1) != 1){
 128:	4605                	li	a2,1
 12a:	fad40593          	addi	a1,s0,-83
 12e:	fb042503          	lw	a0,-80(s0)
 132:	00000097          	auipc	ra,0x0
 136:	3ac080e7          	jalr	940(ra) # 4de <read>
 13a:	4785                	li	a5,1
 13c:	04f51363          	bne	a0,a5,182 <main+0x182>
      for(int r = 0; r < rounds; r++){
 140:	2485                	addiw	s1,s1,1
 142:	fc9a17e3          	bne	s4,s1,110 <main+0x110>
      close(ready[1]);
 146:	fbc42503          	lw	a0,-68(s0)
 14a:	00000097          	auipc	ra,0x0
 14e:	3a4080e7          	jalr	932(ra) # 4ee <close>
      close(release[0]);
 152:	fb042503          	lw	a0,-80(s0)
 156:	00000097          	auipc	ra,0x0
 15a:	398080e7          	jalr	920(ra) # 4ee <close>
      exit(0);
 15e:	4501                	li	a0,0
 160:	00000097          	auipc	ra,0x0
 164:	366080e7          	jalr	870(ra) # 4c6 <exit>
          printf("barrier: child write failed\n");
 168:	00001517          	auipc	a0,0x1
 16c:	8a850513          	addi	a0,a0,-1880 # a10 <malloc+0x114>
 170:	00000097          	auipc	ra,0x0
 174:	6ce080e7          	jalr	1742(ra) # 83e <printf>
          exit(1);
 178:	4505                	li	a0,1
 17a:	00000097          	auipc	ra,0x0
 17e:	34c080e7          	jalr	844(ra) # 4c6 <exit>
          printf("barrier: child read failed\n");
 182:	00001517          	auipc	a0,0x1
 186:	8ae50513          	addi	a0,a0,-1874 # a30 <malloc+0x134>
 18a:	00000097          	auipc	ra,0x0
 18e:	6b4080e7          	jalr	1716(ra) # 83e <printf>
          exit(1);
 192:	4505                	li	a0,1
 194:	00000097          	auipc	ra,0x0
 198:	332080e7          	jalr	818(ra) # 4c6 <exit>
        printf("barrier: parent read failed\n");
 19c:	00001517          	auipc	a0,0x1
 1a0:	8b450513          	addi	a0,a0,-1868 # a50 <malloc+0x154>
 1a4:	00000097          	auipc	ra,0x0
 1a8:	69a080e7          	jalr	1690(ra) # 83e <printf>
        exit(1);
 1ac:	4505                	li	a0,1
 1ae:	00000097          	auipc	ra,0x0
 1b2:	318080e7          	jalr	792(ra) # 4c6 <exit>
    while(cnt < n){
 1b6:	0334d263          	bge	s1,s3,1da <main+0x1da>
      int m = read(ready[0], &b, 1);
 1ba:	4605                	li	a2,1
 1bc:	faf40593          	addi	a1,s0,-81
 1c0:	fb842503          	lw	a0,-72(s0)
 1c4:	00000097          	auipc	ra,0x0
 1c8:	31a080e7          	jalr	794(ra) # 4de <read>
      if(m < 0){
 1cc:	fc0548e3          	bltz	a0,19c <main+0x19c>
      if(m == 1) cnt++;
 1d0:	4785                	li	a5,1
 1d2:	fef512e3          	bne	a0,a5,1b6 <main+0x1b6>
 1d6:	2485                	addiw	s1,s1,1
 1d8:	bff9                	j	1b6 <main+0x1b6>
    for(int i = 0; i < n; i++){
 1da:	84d6                	mv	s1,s5
      if(write(release[1], &x, 1) != 1){
 1dc:	4605                	li	a2,1
 1de:	fae40593          	addi	a1,s0,-82
 1e2:	fb442503          	lw	a0,-76(s0)
 1e6:	00000097          	auipc	ra,0x0
 1ea:	300080e7          	jalr	768(ra) # 4e6 <write>
 1ee:	4785                	li	a5,1
 1f0:	04f51363          	bne	a0,a5,236 <main+0x236>
    for(int i = 0; i < n; i++){
 1f4:	2485                	addiw	s1,s1,1
 1f6:	fe9993e3          	bne	s3,s1,1dc <main+0x1dc>
  for(int r = 0; r < rounds; r++){
 1fa:	2905                	addiw	s2,s2,1
    int cnt = 0;
 1fc:	84d6                	mv	s1,s5
  for(int r = 0; r < rounds; r++){
 1fe:	fb2a1ee3          	bne	s4,s2,1ba <main+0x1ba>
        printf("barrier: parent write failed\n");
        exit(1);
      }
    }
  }
  for(int i = 0; i < n; i++){
 202:	4481                	li	s1,0
    wait(0);
 204:	4501                	li	a0,0
 206:	00000097          	auipc	ra,0x0
 20a:	2c8080e7          	jalr	712(ra) # 4ce <wait>
  for(int i = 0; i < n; i++){
 20e:	2485                	addiw	s1,s1,1
 210:	fe999ae3          	bne	s3,s1,204 <main+0x204>
  }
  close(ready[0]);
 214:	fb842503          	lw	a0,-72(s0)
 218:	00000097          	auipc	ra,0x0
 21c:	2d6080e7          	jalr	726(ra) # 4ee <close>
  close(release[1]);
 220:	fb442503          	lw	a0,-76(s0)
 224:	00000097          	auipc	ra,0x0
 228:	2ca080e7          	jalr	714(ra) # 4ee <close>
  exit(0);
 22c:	4501                	li	a0,0
 22e:	00000097          	auipc	ra,0x0
 232:	298080e7          	jalr	664(ra) # 4c6 <exit>
        printf("barrier: parent write failed\n");
 236:	00001517          	auipc	a0,0x1
 23a:	83a50513          	addi	a0,a0,-1990 # a70 <malloc+0x174>
 23e:	00000097          	auipc	ra,0x0
 242:	600080e7          	jalr	1536(ra) # 83e <printf>
        exit(1);
 246:	4505                	li	a0,1
 248:	00000097          	auipc	ra,0x0
 24c:	27e080e7          	jalr	638(ra) # 4c6 <exit>

0000000000000250 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 250:	1141                	addi	sp,sp,-16
 252:	e422                	sd	s0,8(sp)
 254:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 256:	87aa                	mv	a5,a0
 258:	0585                	addi	a1,a1,1
 25a:	0785                	addi	a5,a5,1
 25c:	fff5c703          	lbu	a4,-1(a1)
 260:	fee78fa3          	sb	a4,-1(a5)
 264:	fb75                	bnez	a4,258 <strcpy+0x8>
    ;
  return os;
}
 266:	6422                	ld	s0,8(sp)
 268:	0141                	addi	sp,sp,16
 26a:	8082                	ret

000000000000026c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 26c:	1141                	addi	sp,sp,-16
 26e:	e422                	sd	s0,8(sp)
 270:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 272:	00054783          	lbu	a5,0(a0)
 276:	cb91                	beqz	a5,28a <strcmp+0x1e>
 278:	0005c703          	lbu	a4,0(a1)
 27c:	00f71763          	bne	a4,a5,28a <strcmp+0x1e>
    p++, q++;
 280:	0505                	addi	a0,a0,1
 282:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 284:	00054783          	lbu	a5,0(a0)
 288:	fbe5                	bnez	a5,278 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 28a:	0005c503          	lbu	a0,0(a1)
}
 28e:	40a7853b          	subw	a0,a5,a0
 292:	6422                	ld	s0,8(sp)
 294:	0141                	addi	sp,sp,16
 296:	8082                	ret

0000000000000298 <strlen>:

uint
strlen(const char *s)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 29e:	00054783          	lbu	a5,0(a0)
 2a2:	cf91                	beqz	a5,2be <strlen+0x26>
 2a4:	0505                	addi	a0,a0,1
 2a6:	87aa                	mv	a5,a0
 2a8:	4685                	li	a3,1
 2aa:	9e89                	subw	a3,a3,a0
 2ac:	00f6853b          	addw	a0,a3,a5
 2b0:	0785                	addi	a5,a5,1
 2b2:	fff7c703          	lbu	a4,-1(a5)
 2b6:	fb7d                	bnez	a4,2ac <strlen+0x14>
    ;
  return n;
}
 2b8:	6422                	ld	s0,8(sp)
 2ba:	0141                	addi	sp,sp,16
 2bc:	8082                	ret
  for(n = 0; s[n]; n++)
 2be:	4501                	li	a0,0
 2c0:	bfe5                	j	2b8 <strlen+0x20>

00000000000002c2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2c2:	1141                	addi	sp,sp,-16
 2c4:	e422                	sd	s0,8(sp)
 2c6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2c8:	ce09                	beqz	a2,2e2 <memset+0x20>
 2ca:	87aa                	mv	a5,a0
 2cc:	fff6071b          	addiw	a4,a2,-1
 2d0:	1702                	slli	a4,a4,0x20
 2d2:	9301                	srli	a4,a4,0x20
 2d4:	0705                	addi	a4,a4,1
 2d6:	972a                	add	a4,a4,a0
    cdst[i] = c;
 2d8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2dc:	0785                	addi	a5,a5,1
 2de:	fee79de3          	bne	a5,a4,2d8 <memset+0x16>
  }
  return dst;
}
 2e2:	6422                	ld	s0,8(sp)
 2e4:	0141                	addi	sp,sp,16
 2e6:	8082                	ret

00000000000002e8 <strchr>:

char*
strchr(const char *s, char c)
{
 2e8:	1141                	addi	sp,sp,-16
 2ea:	e422                	sd	s0,8(sp)
 2ec:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2ee:	00054783          	lbu	a5,0(a0)
 2f2:	cb99                	beqz	a5,308 <strchr+0x20>
    if(*s == c)
 2f4:	00f58763          	beq	a1,a5,302 <strchr+0x1a>
  for(; *s; s++)
 2f8:	0505                	addi	a0,a0,1
 2fa:	00054783          	lbu	a5,0(a0)
 2fe:	fbfd                	bnez	a5,2f4 <strchr+0xc>
      return (char*)s;
  return 0;
 300:	4501                	li	a0,0
}
 302:	6422                	ld	s0,8(sp)
 304:	0141                	addi	sp,sp,16
 306:	8082                	ret
  return 0;
 308:	4501                	li	a0,0
 30a:	bfe5                	j	302 <strchr+0x1a>

000000000000030c <gets>:

char*
gets(char *buf, int max)
{
 30c:	711d                	addi	sp,sp,-96
 30e:	ec86                	sd	ra,88(sp)
 310:	e8a2                	sd	s0,80(sp)
 312:	e4a6                	sd	s1,72(sp)
 314:	e0ca                	sd	s2,64(sp)
 316:	fc4e                	sd	s3,56(sp)
 318:	f852                	sd	s4,48(sp)
 31a:	f456                	sd	s5,40(sp)
 31c:	f05a                	sd	s6,32(sp)
 31e:	ec5e                	sd	s7,24(sp)
 320:	1080                	addi	s0,sp,96
 322:	8baa                	mv	s7,a0
 324:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 326:	892a                	mv	s2,a0
 328:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 32a:	4aa9                	li	s5,10
 32c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 32e:	89a6                	mv	s3,s1
 330:	2485                	addiw	s1,s1,1
 332:	0344d863          	bge	s1,s4,362 <gets+0x56>
    cc = read(0, &c, 1);
 336:	4605                	li	a2,1
 338:	faf40593          	addi	a1,s0,-81
 33c:	4501                	li	a0,0
 33e:	00000097          	auipc	ra,0x0
 342:	1a0080e7          	jalr	416(ra) # 4de <read>
    if(cc < 1)
 346:	00a05e63          	blez	a0,362 <gets+0x56>
    buf[i++] = c;
 34a:	faf44783          	lbu	a5,-81(s0)
 34e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 352:	01578763          	beq	a5,s5,360 <gets+0x54>
 356:	0905                	addi	s2,s2,1
 358:	fd679be3          	bne	a5,s6,32e <gets+0x22>
  for(i=0; i+1 < max; ){
 35c:	89a6                	mv	s3,s1
 35e:	a011                	j	362 <gets+0x56>
 360:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 362:	99de                	add	s3,s3,s7
 364:	00098023          	sb	zero,0(s3)
  return buf;
}
 368:	855e                	mv	a0,s7
 36a:	60e6                	ld	ra,88(sp)
 36c:	6446                	ld	s0,80(sp)
 36e:	64a6                	ld	s1,72(sp)
 370:	6906                	ld	s2,64(sp)
 372:	79e2                	ld	s3,56(sp)
 374:	7a42                	ld	s4,48(sp)
 376:	7aa2                	ld	s5,40(sp)
 378:	7b02                	ld	s6,32(sp)
 37a:	6be2                	ld	s7,24(sp)
 37c:	6125                	addi	sp,sp,96
 37e:	8082                	ret

0000000000000380 <stat>:

int
stat(const char *n, struct stat *st)
{
 380:	1101                	addi	sp,sp,-32
 382:	ec06                	sd	ra,24(sp)
 384:	e822                	sd	s0,16(sp)
 386:	e426                	sd	s1,8(sp)
 388:	e04a                	sd	s2,0(sp)
 38a:	1000                	addi	s0,sp,32
 38c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 38e:	4581                	li	a1,0
 390:	00000097          	auipc	ra,0x0
 394:	176080e7          	jalr	374(ra) # 506 <open>
  if(fd < 0)
 398:	02054563          	bltz	a0,3c2 <stat+0x42>
 39c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 39e:	85ca                	mv	a1,s2
 3a0:	00000097          	auipc	ra,0x0
 3a4:	17e080e7          	jalr	382(ra) # 51e <fstat>
 3a8:	892a                	mv	s2,a0
  close(fd);
 3aa:	8526                	mv	a0,s1
 3ac:	00000097          	auipc	ra,0x0
 3b0:	142080e7          	jalr	322(ra) # 4ee <close>
  return r;
}
 3b4:	854a                	mv	a0,s2
 3b6:	60e2                	ld	ra,24(sp)
 3b8:	6442                	ld	s0,16(sp)
 3ba:	64a2                	ld	s1,8(sp)
 3bc:	6902                	ld	s2,0(sp)
 3be:	6105                	addi	sp,sp,32
 3c0:	8082                	ret
    return -1;
 3c2:	597d                	li	s2,-1
 3c4:	bfc5                	j	3b4 <stat+0x34>

00000000000003c6 <atoi>:

int
atoi(const char *s)
{
 3c6:	1141                	addi	sp,sp,-16
 3c8:	e422                	sd	s0,8(sp)
 3ca:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3cc:	00054603          	lbu	a2,0(a0)
 3d0:	fd06079b          	addiw	a5,a2,-48
 3d4:	0ff7f793          	andi	a5,a5,255
 3d8:	4725                	li	a4,9
 3da:	02f76963          	bltu	a4,a5,40c <atoi+0x46>
 3de:	86aa                	mv	a3,a0
  n = 0;
 3e0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3e2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3e4:	0685                	addi	a3,a3,1
 3e6:	0025179b          	slliw	a5,a0,0x2
 3ea:	9fa9                	addw	a5,a5,a0
 3ec:	0017979b          	slliw	a5,a5,0x1
 3f0:	9fb1                	addw	a5,a5,a2
 3f2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3f6:	0006c603          	lbu	a2,0(a3)
 3fa:	fd06071b          	addiw	a4,a2,-48
 3fe:	0ff77713          	andi	a4,a4,255
 402:	fee5f1e3          	bgeu	a1,a4,3e4 <atoi+0x1e>
  return n;
}
 406:	6422                	ld	s0,8(sp)
 408:	0141                	addi	sp,sp,16
 40a:	8082                	ret
  n = 0;
 40c:	4501                	li	a0,0
 40e:	bfe5                	j	406 <atoi+0x40>

0000000000000410 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 410:	1141                	addi	sp,sp,-16
 412:	e422                	sd	s0,8(sp)
 414:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 416:	02b57663          	bgeu	a0,a1,442 <memmove+0x32>
    while(n-- > 0)
 41a:	02c05163          	blez	a2,43c <memmove+0x2c>
 41e:	fff6079b          	addiw	a5,a2,-1
 422:	1782                	slli	a5,a5,0x20
 424:	9381                	srli	a5,a5,0x20
 426:	0785                	addi	a5,a5,1
 428:	97aa                	add	a5,a5,a0
  dst = vdst;
 42a:	872a                	mv	a4,a0
      *dst++ = *src++;
 42c:	0585                	addi	a1,a1,1
 42e:	0705                	addi	a4,a4,1
 430:	fff5c683          	lbu	a3,-1(a1)
 434:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 438:	fee79ae3          	bne	a5,a4,42c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 43c:	6422                	ld	s0,8(sp)
 43e:	0141                	addi	sp,sp,16
 440:	8082                	ret
    dst += n;
 442:	00c50733          	add	a4,a0,a2
    src += n;
 446:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 448:	fec05ae3          	blez	a2,43c <memmove+0x2c>
 44c:	fff6079b          	addiw	a5,a2,-1
 450:	1782                	slli	a5,a5,0x20
 452:	9381                	srli	a5,a5,0x20
 454:	fff7c793          	not	a5,a5
 458:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 45a:	15fd                	addi	a1,a1,-1
 45c:	177d                	addi	a4,a4,-1
 45e:	0005c683          	lbu	a3,0(a1)
 462:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 466:	fee79ae3          	bne	a5,a4,45a <memmove+0x4a>
 46a:	bfc9                	j	43c <memmove+0x2c>

000000000000046c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 46c:	1141                	addi	sp,sp,-16
 46e:	e422                	sd	s0,8(sp)
 470:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 472:	ca05                	beqz	a2,4a2 <memcmp+0x36>
 474:	fff6069b          	addiw	a3,a2,-1
 478:	1682                	slli	a3,a3,0x20
 47a:	9281                	srli	a3,a3,0x20
 47c:	0685                	addi	a3,a3,1
 47e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 480:	00054783          	lbu	a5,0(a0)
 484:	0005c703          	lbu	a4,0(a1)
 488:	00e79863          	bne	a5,a4,498 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 48c:	0505                	addi	a0,a0,1
    p2++;
 48e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 490:	fed518e3          	bne	a0,a3,480 <memcmp+0x14>
  }
  return 0;
 494:	4501                	li	a0,0
 496:	a019                	j	49c <memcmp+0x30>
      return *p1 - *p2;
 498:	40e7853b          	subw	a0,a5,a4
}
 49c:	6422                	ld	s0,8(sp)
 49e:	0141                	addi	sp,sp,16
 4a0:	8082                	ret
  return 0;
 4a2:	4501                	li	a0,0
 4a4:	bfe5                	j	49c <memcmp+0x30>

00000000000004a6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4a6:	1141                	addi	sp,sp,-16
 4a8:	e406                	sd	ra,8(sp)
 4aa:	e022                	sd	s0,0(sp)
 4ac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4ae:	00000097          	auipc	ra,0x0
 4b2:	f62080e7          	jalr	-158(ra) # 410 <memmove>
}
 4b6:	60a2                	ld	ra,8(sp)
 4b8:	6402                	ld	s0,0(sp)
 4ba:	0141                	addi	sp,sp,16
 4bc:	8082                	ret

00000000000004be <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4be:	4885                	li	a7,1
 ecall
 4c0:	00000073          	ecall
 ret
 4c4:	8082                	ret

00000000000004c6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 4c6:	4889                	li	a7,2
 ecall
 4c8:	00000073          	ecall
 ret
 4cc:	8082                	ret

00000000000004ce <wait>:
.global wait
wait:
 li a7, SYS_wait
 4ce:	488d                	li	a7,3
 ecall
 4d0:	00000073          	ecall
 ret
 4d4:	8082                	ret

00000000000004d6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4d6:	4891                	li	a7,4
 ecall
 4d8:	00000073          	ecall
 ret
 4dc:	8082                	ret

00000000000004de <read>:
.global read
read:
 li a7, SYS_read
 4de:	4895                	li	a7,5
 ecall
 4e0:	00000073          	ecall
 ret
 4e4:	8082                	ret

00000000000004e6 <write>:
.global write
write:
 li a7, SYS_write
 4e6:	48c1                	li	a7,16
 ecall
 4e8:	00000073          	ecall
 ret
 4ec:	8082                	ret

00000000000004ee <close>:
.global close
close:
 li a7, SYS_close
 4ee:	48d5                	li	a7,21
 ecall
 4f0:	00000073          	ecall
 ret
 4f4:	8082                	ret

00000000000004f6 <kill>:
.global kill
kill:
 li a7, SYS_kill
 4f6:	4899                	li	a7,6
 ecall
 4f8:	00000073          	ecall
 ret
 4fc:	8082                	ret

00000000000004fe <exec>:
.global exec
exec:
 li a7, SYS_exec
 4fe:	489d                	li	a7,7
 ecall
 500:	00000073          	ecall
 ret
 504:	8082                	ret

0000000000000506 <open>:
.global open
open:
 li a7, SYS_open
 506:	48bd                	li	a7,15
 ecall
 508:	00000073          	ecall
 ret
 50c:	8082                	ret

000000000000050e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 50e:	48c5                	li	a7,17
 ecall
 510:	00000073          	ecall
 ret
 514:	8082                	ret

0000000000000516 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 516:	48c9                	li	a7,18
 ecall
 518:	00000073          	ecall
 ret
 51c:	8082                	ret

000000000000051e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 51e:	48a1                	li	a7,8
 ecall
 520:	00000073          	ecall
 ret
 524:	8082                	ret

0000000000000526 <link>:
.global link
link:
 li a7, SYS_link
 526:	48cd                	li	a7,19
 ecall
 528:	00000073          	ecall
 ret
 52c:	8082                	ret

000000000000052e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 52e:	48d1                	li	a7,20
 ecall
 530:	00000073          	ecall
 ret
 534:	8082                	ret

0000000000000536 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 536:	48a5                	li	a7,9
 ecall
 538:	00000073          	ecall
 ret
 53c:	8082                	ret

000000000000053e <dup>:
.global dup
dup:
 li a7, SYS_dup
 53e:	48a9                	li	a7,10
 ecall
 540:	00000073          	ecall
 ret
 544:	8082                	ret

0000000000000546 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 546:	48ad                	li	a7,11
 ecall
 548:	00000073          	ecall
 ret
 54c:	8082                	ret

000000000000054e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 54e:	48b1                	li	a7,12
 ecall
 550:	00000073          	ecall
 ret
 554:	8082                	ret

0000000000000556 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 556:	48b5                	li	a7,13
 ecall
 558:	00000073          	ecall
 ret
 55c:	8082                	ret

000000000000055e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 55e:	48b9                	li	a7,14
 ecall
 560:	00000073          	ecall
 ret
 564:	8082                	ret

0000000000000566 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 566:	1101                	addi	sp,sp,-32
 568:	ec06                	sd	ra,24(sp)
 56a:	e822                	sd	s0,16(sp)
 56c:	1000                	addi	s0,sp,32
 56e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 572:	4605                	li	a2,1
 574:	fef40593          	addi	a1,s0,-17
 578:	00000097          	auipc	ra,0x0
 57c:	f6e080e7          	jalr	-146(ra) # 4e6 <write>
}
 580:	60e2                	ld	ra,24(sp)
 582:	6442                	ld	s0,16(sp)
 584:	6105                	addi	sp,sp,32
 586:	8082                	ret

0000000000000588 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 588:	7139                	addi	sp,sp,-64
 58a:	fc06                	sd	ra,56(sp)
 58c:	f822                	sd	s0,48(sp)
 58e:	f426                	sd	s1,40(sp)
 590:	f04a                	sd	s2,32(sp)
 592:	ec4e                	sd	s3,24(sp)
 594:	0080                	addi	s0,sp,64
 596:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 598:	c299                	beqz	a3,59e <printint+0x16>
 59a:	0805c863          	bltz	a1,62a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 59e:	2581                	sext.w	a1,a1
  neg = 0;
 5a0:	4881                	li	a7,0
 5a2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 5a6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 5a8:	2601                	sext.w	a2,a2
 5aa:	00000517          	auipc	a0,0x0
 5ae:	4ee50513          	addi	a0,a0,1262 # a98 <digits>
 5b2:	883a                	mv	a6,a4
 5b4:	2705                	addiw	a4,a4,1
 5b6:	02c5f7bb          	remuw	a5,a1,a2
 5ba:	1782                	slli	a5,a5,0x20
 5bc:	9381                	srli	a5,a5,0x20
 5be:	97aa                	add	a5,a5,a0
 5c0:	0007c783          	lbu	a5,0(a5)
 5c4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 5c8:	0005879b          	sext.w	a5,a1
 5cc:	02c5d5bb          	divuw	a1,a1,a2
 5d0:	0685                	addi	a3,a3,1
 5d2:	fec7f0e3          	bgeu	a5,a2,5b2 <printint+0x2a>
  if(neg)
 5d6:	00088b63          	beqz	a7,5ec <printint+0x64>
    buf[i++] = '-';
 5da:	fd040793          	addi	a5,s0,-48
 5de:	973e                	add	a4,a4,a5
 5e0:	02d00793          	li	a5,45
 5e4:	fef70823          	sb	a5,-16(a4)
 5e8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 5ec:	02e05863          	blez	a4,61c <printint+0x94>
 5f0:	fc040793          	addi	a5,s0,-64
 5f4:	00e78933          	add	s2,a5,a4
 5f8:	fff78993          	addi	s3,a5,-1
 5fc:	99ba                	add	s3,s3,a4
 5fe:	377d                	addiw	a4,a4,-1
 600:	1702                	slli	a4,a4,0x20
 602:	9301                	srli	a4,a4,0x20
 604:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 608:	fff94583          	lbu	a1,-1(s2)
 60c:	8526                	mv	a0,s1
 60e:	00000097          	auipc	ra,0x0
 612:	f58080e7          	jalr	-168(ra) # 566 <putc>
  while(--i >= 0)
 616:	197d                	addi	s2,s2,-1
 618:	ff3918e3          	bne	s2,s3,608 <printint+0x80>
}
 61c:	70e2                	ld	ra,56(sp)
 61e:	7442                	ld	s0,48(sp)
 620:	74a2                	ld	s1,40(sp)
 622:	7902                	ld	s2,32(sp)
 624:	69e2                	ld	s3,24(sp)
 626:	6121                	addi	sp,sp,64
 628:	8082                	ret
    x = -xx;
 62a:	40b005bb          	negw	a1,a1
    neg = 1;
 62e:	4885                	li	a7,1
    x = -xx;
 630:	bf8d                	j	5a2 <printint+0x1a>

0000000000000632 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 632:	7119                	addi	sp,sp,-128
 634:	fc86                	sd	ra,120(sp)
 636:	f8a2                	sd	s0,112(sp)
 638:	f4a6                	sd	s1,104(sp)
 63a:	f0ca                	sd	s2,96(sp)
 63c:	ecce                	sd	s3,88(sp)
 63e:	e8d2                	sd	s4,80(sp)
 640:	e4d6                	sd	s5,72(sp)
 642:	e0da                	sd	s6,64(sp)
 644:	fc5e                	sd	s7,56(sp)
 646:	f862                	sd	s8,48(sp)
 648:	f466                	sd	s9,40(sp)
 64a:	f06a                	sd	s10,32(sp)
 64c:	ec6e                	sd	s11,24(sp)
 64e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 650:	0005c903          	lbu	s2,0(a1)
 654:	18090f63          	beqz	s2,7f2 <vprintf+0x1c0>
 658:	8aaa                	mv	s5,a0
 65a:	8b32                	mv	s6,a2
 65c:	00158493          	addi	s1,a1,1
  state = 0;
 660:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 662:	02500a13          	li	s4,37
      if(c == 'd'){
 666:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 66a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 66e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 672:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 676:	00000b97          	auipc	s7,0x0
 67a:	422b8b93          	addi	s7,s7,1058 # a98 <digits>
 67e:	a839                	j	69c <vprintf+0x6a>
        putc(fd, c);
 680:	85ca                	mv	a1,s2
 682:	8556                	mv	a0,s5
 684:	00000097          	auipc	ra,0x0
 688:	ee2080e7          	jalr	-286(ra) # 566 <putc>
 68c:	a019                	j	692 <vprintf+0x60>
    } else if(state == '%'){
 68e:	01498f63          	beq	s3,s4,6ac <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 692:	0485                	addi	s1,s1,1
 694:	fff4c903          	lbu	s2,-1(s1)
 698:	14090d63          	beqz	s2,7f2 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 69c:	0009079b          	sext.w	a5,s2
    if(state == 0){
 6a0:	fe0997e3          	bnez	s3,68e <vprintf+0x5c>
      if(c == '%'){
 6a4:	fd479ee3          	bne	a5,s4,680 <vprintf+0x4e>
        state = '%';
 6a8:	89be                	mv	s3,a5
 6aa:	b7e5                	j	692 <vprintf+0x60>
      if(c == 'd'){
 6ac:	05878063          	beq	a5,s8,6ec <vprintf+0xba>
      } else if(c == 'l') {
 6b0:	05978c63          	beq	a5,s9,708 <vprintf+0xd6>
      } else if(c == 'x') {
 6b4:	07a78863          	beq	a5,s10,724 <vprintf+0xf2>
      } else if(c == 'p') {
 6b8:	09b78463          	beq	a5,s11,740 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6bc:	07300713          	li	a4,115
 6c0:	0ce78663          	beq	a5,a4,78c <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6c4:	06300713          	li	a4,99
 6c8:	0ee78e63          	beq	a5,a4,7c4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6cc:	11478863          	beq	a5,s4,7dc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6d0:	85d2                	mv	a1,s4
 6d2:	8556                	mv	a0,s5
 6d4:	00000097          	auipc	ra,0x0
 6d8:	e92080e7          	jalr	-366(ra) # 566 <putc>
        putc(fd, c);
 6dc:	85ca                	mv	a1,s2
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	e86080e7          	jalr	-378(ra) # 566 <putc>
      }
      state = 0;
 6e8:	4981                	li	s3,0
 6ea:	b765                	j	692 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6ec:	008b0913          	addi	s2,s6,8
 6f0:	4685                	li	a3,1
 6f2:	4629                	li	a2,10
 6f4:	000b2583          	lw	a1,0(s6)
 6f8:	8556                	mv	a0,s5
 6fa:	00000097          	auipc	ra,0x0
 6fe:	e8e080e7          	jalr	-370(ra) # 588 <printint>
 702:	8b4a                	mv	s6,s2
      state = 0;
 704:	4981                	li	s3,0
 706:	b771                	j	692 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 708:	008b0913          	addi	s2,s6,8
 70c:	4681                	li	a3,0
 70e:	4629                	li	a2,10
 710:	000b2583          	lw	a1,0(s6)
 714:	8556                	mv	a0,s5
 716:	00000097          	auipc	ra,0x0
 71a:	e72080e7          	jalr	-398(ra) # 588 <printint>
 71e:	8b4a                	mv	s6,s2
      state = 0;
 720:	4981                	li	s3,0
 722:	bf85                	j	692 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 724:	008b0913          	addi	s2,s6,8
 728:	4681                	li	a3,0
 72a:	4641                	li	a2,16
 72c:	000b2583          	lw	a1,0(s6)
 730:	8556                	mv	a0,s5
 732:	00000097          	auipc	ra,0x0
 736:	e56080e7          	jalr	-426(ra) # 588 <printint>
 73a:	8b4a                	mv	s6,s2
      state = 0;
 73c:	4981                	li	s3,0
 73e:	bf91                	j	692 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 740:	008b0793          	addi	a5,s6,8
 744:	f8f43423          	sd	a5,-120(s0)
 748:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 74c:	03000593          	li	a1,48
 750:	8556                	mv	a0,s5
 752:	00000097          	auipc	ra,0x0
 756:	e14080e7          	jalr	-492(ra) # 566 <putc>
  putc(fd, 'x');
 75a:	85ea                	mv	a1,s10
 75c:	8556                	mv	a0,s5
 75e:	00000097          	auipc	ra,0x0
 762:	e08080e7          	jalr	-504(ra) # 566 <putc>
 766:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 768:	03c9d793          	srli	a5,s3,0x3c
 76c:	97de                	add	a5,a5,s7
 76e:	0007c583          	lbu	a1,0(a5)
 772:	8556                	mv	a0,s5
 774:	00000097          	auipc	ra,0x0
 778:	df2080e7          	jalr	-526(ra) # 566 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 77c:	0992                	slli	s3,s3,0x4
 77e:	397d                	addiw	s2,s2,-1
 780:	fe0914e3          	bnez	s2,768 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 784:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 788:	4981                	li	s3,0
 78a:	b721                	j	692 <vprintf+0x60>
        s = va_arg(ap, char*);
 78c:	008b0993          	addi	s3,s6,8
 790:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 794:	02090163          	beqz	s2,7b6 <vprintf+0x184>
        while(*s != 0){
 798:	00094583          	lbu	a1,0(s2)
 79c:	c9a1                	beqz	a1,7ec <vprintf+0x1ba>
          putc(fd, *s);
 79e:	8556                	mv	a0,s5
 7a0:	00000097          	auipc	ra,0x0
 7a4:	dc6080e7          	jalr	-570(ra) # 566 <putc>
          s++;
 7a8:	0905                	addi	s2,s2,1
        while(*s != 0){
 7aa:	00094583          	lbu	a1,0(s2)
 7ae:	f9e5                	bnez	a1,79e <vprintf+0x16c>
        s = va_arg(ap, char*);
 7b0:	8b4e                	mv	s6,s3
      state = 0;
 7b2:	4981                	li	s3,0
 7b4:	bdf9                	j	692 <vprintf+0x60>
          s = "(null)";
 7b6:	00000917          	auipc	s2,0x0
 7ba:	2da90913          	addi	s2,s2,730 # a90 <malloc+0x194>
        while(*s != 0){
 7be:	02800593          	li	a1,40
 7c2:	bff1                	j	79e <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 7c4:	008b0913          	addi	s2,s6,8
 7c8:	000b4583          	lbu	a1,0(s6)
 7cc:	8556                	mv	a0,s5
 7ce:	00000097          	auipc	ra,0x0
 7d2:	d98080e7          	jalr	-616(ra) # 566 <putc>
 7d6:	8b4a                	mv	s6,s2
      state = 0;
 7d8:	4981                	li	s3,0
 7da:	bd65                	j	692 <vprintf+0x60>
        putc(fd, c);
 7dc:	85d2                	mv	a1,s4
 7de:	8556                	mv	a0,s5
 7e0:	00000097          	auipc	ra,0x0
 7e4:	d86080e7          	jalr	-634(ra) # 566 <putc>
      state = 0;
 7e8:	4981                	li	s3,0
 7ea:	b565                	j	692 <vprintf+0x60>
        s = va_arg(ap, char*);
 7ec:	8b4e                	mv	s6,s3
      state = 0;
 7ee:	4981                	li	s3,0
 7f0:	b54d                	j	692 <vprintf+0x60>
    }
  }
}
 7f2:	70e6                	ld	ra,120(sp)
 7f4:	7446                	ld	s0,112(sp)
 7f6:	74a6                	ld	s1,104(sp)
 7f8:	7906                	ld	s2,96(sp)
 7fa:	69e6                	ld	s3,88(sp)
 7fc:	6a46                	ld	s4,80(sp)
 7fe:	6aa6                	ld	s5,72(sp)
 800:	6b06                	ld	s6,64(sp)
 802:	7be2                	ld	s7,56(sp)
 804:	7c42                	ld	s8,48(sp)
 806:	7ca2                	ld	s9,40(sp)
 808:	7d02                	ld	s10,32(sp)
 80a:	6de2                	ld	s11,24(sp)
 80c:	6109                	addi	sp,sp,128
 80e:	8082                	ret

0000000000000810 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 810:	715d                	addi	sp,sp,-80
 812:	ec06                	sd	ra,24(sp)
 814:	e822                	sd	s0,16(sp)
 816:	1000                	addi	s0,sp,32
 818:	e010                	sd	a2,0(s0)
 81a:	e414                	sd	a3,8(s0)
 81c:	e818                	sd	a4,16(s0)
 81e:	ec1c                	sd	a5,24(s0)
 820:	03043023          	sd	a6,32(s0)
 824:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 828:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 82c:	8622                	mv	a2,s0
 82e:	00000097          	auipc	ra,0x0
 832:	e04080e7          	jalr	-508(ra) # 632 <vprintf>
}
 836:	60e2                	ld	ra,24(sp)
 838:	6442                	ld	s0,16(sp)
 83a:	6161                	addi	sp,sp,80
 83c:	8082                	ret

000000000000083e <printf>:

void
printf(const char *fmt, ...)
{
 83e:	711d                	addi	sp,sp,-96
 840:	ec06                	sd	ra,24(sp)
 842:	e822                	sd	s0,16(sp)
 844:	1000                	addi	s0,sp,32
 846:	e40c                	sd	a1,8(s0)
 848:	e810                	sd	a2,16(s0)
 84a:	ec14                	sd	a3,24(s0)
 84c:	f018                	sd	a4,32(s0)
 84e:	f41c                	sd	a5,40(s0)
 850:	03043823          	sd	a6,48(s0)
 854:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 858:	00840613          	addi	a2,s0,8
 85c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 860:	85aa                	mv	a1,a0
 862:	4505                	li	a0,1
 864:	00000097          	auipc	ra,0x0
 868:	dce080e7          	jalr	-562(ra) # 632 <vprintf>
}
 86c:	60e2                	ld	ra,24(sp)
 86e:	6442                	ld	s0,16(sp)
 870:	6125                	addi	sp,sp,96
 872:	8082                	ret

0000000000000874 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 874:	1141                	addi	sp,sp,-16
 876:	e422                	sd	s0,8(sp)
 878:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 87a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 87e:	00000797          	auipc	a5,0x0
 882:	2327b783          	ld	a5,562(a5) # ab0 <freep>
 886:	a805                	j	8b6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 888:	4618                	lw	a4,8(a2)
 88a:	9db9                	addw	a1,a1,a4
 88c:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 890:	6398                	ld	a4,0(a5)
 892:	6318                	ld	a4,0(a4)
 894:	fee53823          	sd	a4,-16(a0)
 898:	a091                	j	8dc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 89a:	ff852703          	lw	a4,-8(a0)
 89e:	9e39                	addw	a2,a2,a4
 8a0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8a2:	ff053703          	ld	a4,-16(a0)
 8a6:	e398                	sd	a4,0(a5)
 8a8:	a099                	j	8ee <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8aa:	6398                	ld	a4,0(a5)
 8ac:	00e7e463          	bltu	a5,a4,8b4 <free+0x40>
 8b0:	00e6ea63          	bltu	a3,a4,8c4 <free+0x50>
{
 8b4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8b6:	fed7fae3          	bgeu	a5,a3,8aa <free+0x36>
 8ba:	6398                	ld	a4,0(a5)
 8bc:	00e6e463          	bltu	a3,a4,8c4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8c0:	fee7eae3          	bltu	a5,a4,8b4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 8c4:	ff852583          	lw	a1,-8(a0)
 8c8:	6390                	ld	a2,0(a5)
 8ca:	02059713          	slli	a4,a1,0x20
 8ce:	9301                	srli	a4,a4,0x20
 8d0:	0712                	slli	a4,a4,0x4
 8d2:	9736                	add	a4,a4,a3
 8d4:	fae60ae3          	beq	a2,a4,888 <free+0x14>
    bp->s.ptr = p->s.ptr;
 8d8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8dc:	4790                	lw	a2,8(a5)
 8de:	02061713          	slli	a4,a2,0x20
 8e2:	9301                	srli	a4,a4,0x20
 8e4:	0712                	slli	a4,a4,0x4
 8e6:	973e                	add	a4,a4,a5
 8e8:	fae689e3          	beq	a3,a4,89a <free+0x26>
  } else
    p->s.ptr = bp;
 8ec:	e394                	sd	a3,0(a5)
  freep = p;
 8ee:	00000717          	auipc	a4,0x0
 8f2:	1cf73123          	sd	a5,450(a4) # ab0 <freep>
}
 8f6:	6422                	ld	s0,8(sp)
 8f8:	0141                	addi	sp,sp,16
 8fa:	8082                	ret

00000000000008fc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8fc:	7139                	addi	sp,sp,-64
 8fe:	fc06                	sd	ra,56(sp)
 900:	f822                	sd	s0,48(sp)
 902:	f426                	sd	s1,40(sp)
 904:	f04a                	sd	s2,32(sp)
 906:	ec4e                	sd	s3,24(sp)
 908:	e852                	sd	s4,16(sp)
 90a:	e456                	sd	s5,8(sp)
 90c:	e05a                	sd	s6,0(sp)
 90e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 910:	02051493          	slli	s1,a0,0x20
 914:	9081                	srli	s1,s1,0x20
 916:	04bd                	addi	s1,s1,15
 918:	8091                	srli	s1,s1,0x4
 91a:	0014899b          	addiw	s3,s1,1
 91e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 920:	00000517          	auipc	a0,0x0
 924:	19053503          	ld	a0,400(a0) # ab0 <freep>
 928:	c515                	beqz	a0,954 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 92a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 92c:	4798                	lw	a4,8(a5)
 92e:	02977f63          	bgeu	a4,s1,96c <malloc+0x70>
 932:	8a4e                	mv	s4,s3
 934:	0009871b          	sext.w	a4,s3
 938:	6685                	lui	a3,0x1
 93a:	00d77363          	bgeu	a4,a3,940 <malloc+0x44>
 93e:	6a05                	lui	s4,0x1
 940:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 944:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 948:	00000917          	auipc	s2,0x0
 94c:	16890913          	addi	s2,s2,360 # ab0 <freep>
  if(p == (char*)-1)
 950:	5afd                	li	s5,-1
 952:	a88d                	j	9c4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 954:	00000797          	auipc	a5,0x0
 958:	16478793          	addi	a5,a5,356 # ab8 <base>
 95c:	00000717          	auipc	a4,0x0
 960:	14f73a23          	sd	a5,340(a4) # ab0 <freep>
 964:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 966:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 96a:	b7e1                	j	932 <malloc+0x36>
      if(p->s.size == nunits)
 96c:	02e48b63          	beq	s1,a4,9a2 <malloc+0xa6>
        p->s.size -= nunits;
 970:	4137073b          	subw	a4,a4,s3
 974:	c798                	sw	a4,8(a5)
        p += p->s.size;
 976:	1702                	slli	a4,a4,0x20
 978:	9301                	srli	a4,a4,0x20
 97a:	0712                	slli	a4,a4,0x4
 97c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 97e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 982:	00000717          	auipc	a4,0x0
 986:	12a73723          	sd	a0,302(a4) # ab0 <freep>
      return (void*)(p + 1);
 98a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 98e:	70e2                	ld	ra,56(sp)
 990:	7442                	ld	s0,48(sp)
 992:	74a2                	ld	s1,40(sp)
 994:	7902                	ld	s2,32(sp)
 996:	69e2                	ld	s3,24(sp)
 998:	6a42                	ld	s4,16(sp)
 99a:	6aa2                	ld	s5,8(sp)
 99c:	6b02                	ld	s6,0(sp)
 99e:	6121                	addi	sp,sp,64
 9a0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9a2:	6398                	ld	a4,0(a5)
 9a4:	e118                	sd	a4,0(a0)
 9a6:	bff1                	j	982 <malloc+0x86>
  hp->s.size = nu;
 9a8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 9ac:	0541                	addi	a0,a0,16
 9ae:	00000097          	auipc	ra,0x0
 9b2:	ec6080e7          	jalr	-314(ra) # 874 <free>
  return freep;
 9b6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 9ba:	d971                	beqz	a0,98e <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9bc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9be:	4798                	lw	a4,8(a5)
 9c0:	fa9776e3          	bgeu	a4,s1,96c <malloc+0x70>
    if(p == freep)
 9c4:	00093703          	ld	a4,0(s2)
 9c8:	853e                	mv	a0,a5
 9ca:	fef719e3          	bne	a4,a5,9bc <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 9ce:	8552                	mv	a0,s4
 9d0:	00000097          	auipc	ra,0x0
 9d4:	b7e080e7          	jalr	-1154(ra) # 54e <sbrk>
  if(p == (char*)-1)
 9d8:	fd5518e3          	bne	a0,s5,9a8 <malloc+0xac>
        return 0;
 9dc:	4501                	li	a0,0
 9de:	bf45                	j	98e <malloc+0x92>
