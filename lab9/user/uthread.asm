
user/_uthread:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <thread_init>:
extern void thread_switch(struct context* old, struct context* new); // 修改 thread_switch 函数声明
// extern void thread_switch(uint64, uint64);
              
void 
thread_init(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  // main() is thread 0, which will make the first invocation to
  // thread_schedule().  it needs a stack so that the first thread_switch() can
  // save thread 0's state.  thread_schedule() won't run the main thread ever
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.
  current_thread = &all_thread[0];
   6:	00001797          	auipc	a5,0x1
   a:	d4278793          	addi	a5,a5,-702 # d48 <all_thread>
   e:	00001717          	auipc	a4,0x1
  12:	d2f73523          	sd	a5,-726(a4) # d38 <current_thread>
  current_thread->state = RUNNING;
  16:	4785                	li	a5,1
  18:	00003717          	auipc	a4,0x3
  1c:	d2f72823          	sw	a5,-720(a4) # 2d48 <__global_pointer$+0x182f>
}
  20:	6422                	ld	s0,8(sp)
  22:	0141                	addi	sp,sp,16
  24:	8082                	ret

0000000000000026 <thread_schedule>:

void 
thread_schedule(void)
{
  26:	1141                	addi	sp,sp,-16
  28:	e406                	sd	ra,8(sp)
  2a:	e022                	sd	s0,0(sp)
  2c:	0800                	addi	s0,sp,16
  struct thread *t, *next_thread;

  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  2e:	00001317          	auipc	t1,0x1
  32:	d0a33303          	ld	t1,-758(t1) # d38 <current_thread>
  36:	6589                	lui	a1,0x2
  38:	07858593          	addi	a1,a1,120 # 2078 <__global_pointer$+0xb5f>
  3c:	959a                	add	a1,a1,t1
  3e:	4791                	li	a5,4
  for(int i = 0; i < MAX_THREAD; i++){
    if(t >= all_thread + MAX_THREAD)
  40:	00009817          	auipc	a6,0x9
  44:	ee880813          	addi	a6,a6,-280 # 8f28 <base>
      t = all_thread;
    if(t->state == RUNNABLE) {
  48:	6689                	lui	a3,0x2
  4a:	4609                	li	a2,2
      next_thread = t;
      break;
    }
    t = t + 1;
  4c:	07868893          	addi	a7,a3,120 # 2078 <__global_pointer$+0xb5f>
  50:	a809                	j	62 <thread_schedule+0x3c>
    if(t->state == RUNNABLE) {
  52:	00d58733          	add	a4,a1,a3
  56:	4318                	lw	a4,0(a4)
  58:	02c70963          	beq	a4,a2,8a <thread_schedule+0x64>
    t = t + 1;
  5c:	95c6                	add	a1,a1,a7
  for(int i = 0; i < MAX_THREAD; i++){
  5e:	37fd                	addiw	a5,a5,-1
  60:	cb81                	beqz	a5,70 <thread_schedule+0x4a>
    if(t >= all_thread + MAX_THREAD)
  62:	ff05e8e3          	bltu	a1,a6,52 <thread_schedule+0x2c>
      t = all_thread;
  66:	00001597          	auipc	a1,0x1
  6a:	ce258593          	addi	a1,a1,-798 # d48 <all_thread>
  6e:	b7d5                	j	52 <thread_schedule+0x2c>
  }

  if (next_thread == 0) {
    printf("thread_schedule: no runnable threads\n");
  70:	00001517          	auipc	a0,0x1
  74:	b9050513          	addi	a0,a0,-1136 # c00 <malloc+0xe4>
  78:	00001097          	auipc	ra,0x1
  7c:	9e6080e7          	jalr	-1562(ra) # a5e <printf>
    exit(-1);
  80:	557d                	li	a0,-1
  82:	00000097          	auipc	ra,0x0
  86:	664080e7          	jalr	1636(ra) # 6e6 <exit>
  }

  if (current_thread != next_thread) {         /* switch threads?  */
  8a:	02b30263          	beq	t1,a1,ae <thread_schedule+0x88>
    next_thread->state = RUNNING;
  8e:	6509                	lui	a0,0x2
  90:	00a587b3          	add	a5,a1,a0
  94:	4705                	li	a4,1
  96:	c398                	sw	a4,0(a5)
    t = current_thread;
    current_thread = next_thread;
  98:	00001797          	auipc	a5,0x1
  9c:	cab7b023          	sd	a1,-864(a5) # d38 <current_thread>
    /* YOUR CODE HERE
     * Invoke thread_switch to switch from t to next_thread:
     * thread_switch(??, ??);
     */
     thread_switch(&t->ctx, &next_thread->ctx); // 切换线程
  a0:	0521                	addi	a0,a0,8
  a2:	95aa                	add	a1,a1,a0
  a4:	951a                	add	a0,a0,t1
  a6:	00000097          	auipc	ra,0x0
  aa:	360080e7          	jalr	864(ra) # 406 <thread_switch>
  } else
    next_thread = 0;
}
  ae:	60a2                	ld	ra,8(sp)
  b0:	6402                	ld	s0,0(sp)
  b2:	0141                	addi	sp,sp,16
  b4:	8082                	ret

00000000000000b6 <thread_create>:

void 
thread_create(void (*func)())
{
  b6:	1141                	addi	sp,sp,-16
  b8:	e422                	sd	s0,8(sp)
  ba:	0800                	addi	s0,sp,16
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  bc:	00001797          	auipc	a5,0x1
  c0:	c8c78793          	addi	a5,a5,-884 # d48 <all_thread>
    if (t->state == FREE) break;
  c4:	6689                	lui	a3,0x2
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  c6:	07868593          	addi	a1,a3,120 # 2078 <__global_pointer$+0xb5f>
  ca:	00009617          	auipc	a2,0x9
  ce:	e5e60613          	addi	a2,a2,-418 # 8f28 <base>
    if (t->state == FREE) break;
  d2:	00d78733          	add	a4,a5,a3
  d6:	4318                	lw	a4,0(a4)
  d8:	c701                	beqz	a4,e0 <thread_create+0x2a>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  da:	97ae                	add	a5,a5,a1
  dc:	fec79be3          	bne	a5,a2,d2 <thread_create+0x1c>
  }
  t->state = RUNNABLE;
  e0:	6709                	lui	a4,0x2
  e2:	00e786b3          	add	a3,a5,a4
  e6:	4609                	li	a2,2
  e8:	c290                	sw	a2,0(a3)
  // YOUR CODE HERE
  t->ctx.ra = (uint64)func;       // 返回地址
  ea:	e688                	sd	a0,8(a3)
  // thread_switch 的结尾会返回到 ra，从而运行线程代码
  t->ctx.sp = (uint64)&t->stack + (STACK_SIZE - 1);  // 栈指针
  ec:	177d                	addi	a4,a4,-1
  ee:	97ba                	add	a5,a5,a4
  f0:	ea9c                	sd	a5,16(a3)
  // 将线程的栈指针指向其独立的栈，注意到栈的生长是从高地址到低地址，所以
  // 要将 sp 设置为指向 stack 的最高地址
}
  f2:	6422                	ld	s0,8(sp)
  f4:	0141                	addi	sp,sp,16
  f6:	8082                	ret

00000000000000f8 <thread_yield>:

void 
thread_yield(void)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e406                	sd	ra,8(sp)
  fc:	e022                	sd	s0,0(sp)
  fe:	0800                	addi	s0,sp,16
  current_thread->state = RUNNABLE;
 100:	00001797          	auipc	a5,0x1
 104:	c387b783          	ld	a5,-968(a5) # d38 <current_thread>
 108:	6709                	lui	a4,0x2
 10a:	97ba                	add	a5,a5,a4
 10c:	4709                	li	a4,2
 10e:	c398                	sw	a4,0(a5)
  thread_schedule();
 110:	00000097          	auipc	ra,0x0
 114:	f16080e7          	jalr	-234(ra) # 26 <thread_schedule>
}
 118:	60a2                	ld	ra,8(sp)
 11a:	6402                	ld	s0,0(sp)
 11c:	0141                	addi	sp,sp,16
 11e:	8082                	ret

0000000000000120 <thread_a>:
volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
 120:	7179                	addi	sp,sp,-48
 122:	f406                	sd	ra,40(sp)
 124:	f022                	sd	s0,32(sp)
 126:	ec26                	sd	s1,24(sp)
 128:	e84a                	sd	s2,16(sp)
 12a:	e44e                	sd	s3,8(sp)
 12c:	e052                	sd	s4,0(sp)
 12e:	1800                	addi	s0,sp,48
  int i;
  printf("thread_a started\n");
 130:	00001517          	auipc	a0,0x1
 134:	af850513          	addi	a0,a0,-1288 # c28 <malloc+0x10c>
 138:	00001097          	auipc	ra,0x1
 13c:	926080e7          	jalr	-1754(ra) # a5e <printf>
  a_started = 1;
 140:	4785                	li	a5,1
 142:	00001717          	auipc	a4,0x1
 146:	bef72923          	sw	a5,-1038(a4) # d34 <a_started>
  while(b_started == 0 || c_started == 0)
 14a:	00001497          	auipc	s1,0x1
 14e:	be648493          	addi	s1,s1,-1050 # d30 <b_started>
 152:	00001917          	auipc	s2,0x1
 156:	bda90913          	addi	s2,s2,-1062 # d2c <c_started>
 15a:	a029                	j	164 <thread_a+0x44>
    thread_yield();
 15c:	00000097          	auipc	ra,0x0
 160:	f9c080e7          	jalr	-100(ra) # f8 <thread_yield>
  while(b_started == 0 || c_started == 0)
 164:	409c                	lw	a5,0(s1)
 166:	2781                	sext.w	a5,a5
 168:	dbf5                	beqz	a5,15c <thread_a+0x3c>
 16a:	00092783          	lw	a5,0(s2)
 16e:	2781                	sext.w	a5,a5
 170:	d7f5                	beqz	a5,15c <thread_a+0x3c>
  
  for (i = 0; i < 100; i++) {
 172:	4481                	li	s1,0
    printf("thread_a %d\n", i);
 174:	00001a17          	auipc	s4,0x1
 178:	acca0a13          	addi	s4,s4,-1332 # c40 <malloc+0x124>
    a_n += 1;
 17c:	00001917          	auipc	s2,0x1
 180:	bac90913          	addi	s2,s2,-1108 # d28 <a_n>
  for (i = 0; i < 100; i++) {
 184:	06400993          	li	s3,100
    printf("thread_a %d\n", i);
 188:	85a6                	mv	a1,s1
 18a:	8552                	mv	a0,s4
 18c:	00001097          	auipc	ra,0x1
 190:	8d2080e7          	jalr	-1838(ra) # a5e <printf>
    a_n += 1;
 194:	00092783          	lw	a5,0(s2)
 198:	2785                	addiw	a5,a5,1
 19a:	00f92023          	sw	a5,0(s2)
    thread_yield();
 19e:	00000097          	auipc	ra,0x0
 1a2:	f5a080e7          	jalr	-166(ra) # f8 <thread_yield>
  for (i = 0; i < 100; i++) {
 1a6:	2485                	addiw	s1,s1,1
 1a8:	ff3490e3          	bne	s1,s3,188 <thread_a+0x68>
  }
  printf("thread_a: exit after %d\n", a_n);
 1ac:	00001597          	auipc	a1,0x1
 1b0:	b7c5a583          	lw	a1,-1156(a1) # d28 <a_n>
 1b4:	00001517          	auipc	a0,0x1
 1b8:	a9c50513          	addi	a0,a0,-1380 # c50 <malloc+0x134>
 1bc:	00001097          	auipc	ra,0x1
 1c0:	8a2080e7          	jalr	-1886(ra) # a5e <printf>

  current_thread->state = FREE;
 1c4:	00001797          	auipc	a5,0x1
 1c8:	b747b783          	ld	a5,-1164(a5) # d38 <current_thread>
 1cc:	6709                	lui	a4,0x2
 1ce:	97ba                	add	a5,a5,a4
 1d0:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 1d4:	00000097          	auipc	ra,0x0
 1d8:	e52080e7          	jalr	-430(ra) # 26 <thread_schedule>
}
 1dc:	70a2                	ld	ra,40(sp)
 1de:	7402                	ld	s0,32(sp)
 1e0:	64e2                	ld	s1,24(sp)
 1e2:	6942                	ld	s2,16(sp)
 1e4:	69a2                	ld	s3,8(sp)
 1e6:	6a02                	ld	s4,0(sp)
 1e8:	6145                	addi	sp,sp,48
 1ea:	8082                	ret

00000000000001ec <thread_b>:

void 
thread_b(void)
{
 1ec:	7179                	addi	sp,sp,-48
 1ee:	f406                	sd	ra,40(sp)
 1f0:	f022                	sd	s0,32(sp)
 1f2:	ec26                	sd	s1,24(sp)
 1f4:	e84a                	sd	s2,16(sp)
 1f6:	e44e                	sd	s3,8(sp)
 1f8:	e052                	sd	s4,0(sp)
 1fa:	1800                	addi	s0,sp,48
  int i;
  printf("thread_b started\n");
 1fc:	00001517          	auipc	a0,0x1
 200:	a7450513          	addi	a0,a0,-1420 # c70 <malloc+0x154>
 204:	00001097          	auipc	ra,0x1
 208:	85a080e7          	jalr	-1958(ra) # a5e <printf>
  b_started = 1;
 20c:	4785                	li	a5,1
 20e:	00001717          	auipc	a4,0x1
 212:	b2f72123          	sw	a5,-1246(a4) # d30 <b_started>
  while(a_started == 0 || c_started == 0)
 216:	00001497          	auipc	s1,0x1
 21a:	b1e48493          	addi	s1,s1,-1250 # d34 <a_started>
 21e:	00001917          	auipc	s2,0x1
 222:	b0e90913          	addi	s2,s2,-1266 # d2c <c_started>
 226:	a029                	j	230 <thread_b+0x44>
    thread_yield();
 228:	00000097          	auipc	ra,0x0
 22c:	ed0080e7          	jalr	-304(ra) # f8 <thread_yield>
  while(a_started == 0 || c_started == 0)
 230:	409c                	lw	a5,0(s1)
 232:	2781                	sext.w	a5,a5
 234:	dbf5                	beqz	a5,228 <thread_b+0x3c>
 236:	00092783          	lw	a5,0(s2)
 23a:	2781                	sext.w	a5,a5
 23c:	d7f5                	beqz	a5,228 <thread_b+0x3c>
  
  for (i = 0; i < 100; i++) {
 23e:	4481                	li	s1,0
    printf("thread_b %d\n", i);
 240:	00001a17          	auipc	s4,0x1
 244:	a48a0a13          	addi	s4,s4,-1464 # c88 <malloc+0x16c>
    b_n += 1;
 248:	00001917          	auipc	s2,0x1
 24c:	adc90913          	addi	s2,s2,-1316 # d24 <b_n>
  for (i = 0; i < 100; i++) {
 250:	06400993          	li	s3,100
    printf("thread_b %d\n", i);
 254:	85a6                	mv	a1,s1
 256:	8552                	mv	a0,s4
 258:	00001097          	auipc	ra,0x1
 25c:	806080e7          	jalr	-2042(ra) # a5e <printf>
    b_n += 1;
 260:	00092783          	lw	a5,0(s2)
 264:	2785                	addiw	a5,a5,1
 266:	00f92023          	sw	a5,0(s2)
    thread_yield();
 26a:	00000097          	auipc	ra,0x0
 26e:	e8e080e7          	jalr	-370(ra) # f8 <thread_yield>
  for (i = 0; i < 100; i++) {
 272:	2485                	addiw	s1,s1,1
 274:	ff3490e3          	bne	s1,s3,254 <thread_b+0x68>
  }
  printf("thread_b: exit after %d\n", b_n);
 278:	00001597          	auipc	a1,0x1
 27c:	aac5a583          	lw	a1,-1364(a1) # d24 <b_n>
 280:	00001517          	auipc	a0,0x1
 284:	a1850513          	addi	a0,a0,-1512 # c98 <malloc+0x17c>
 288:	00000097          	auipc	ra,0x0
 28c:	7d6080e7          	jalr	2006(ra) # a5e <printf>

  current_thread->state = FREE;
 290:	00001797          	auipc	a5,0x1
 294:	aa87b783          	ld	a5,-1368(a5) # d38 <current_thread>
 298:	6709                	lui	a4,0x2
 29a:	97ba                	add	a5,a5,a4
 29c:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 2a0:	00000097          	auipc	ra,0x0
 2a4:	d86080e7          	jalr	-634(ra) # 26 <thread_schedule>
}
 2a8:	70a2                	ld	ra,40(sp)
 2aa:	7402                	ld	s0,32(sp)
 2ac:	64e2                	ld	s1,24(sp)
 2ae:	6942                	ld	s2,16(sp)
 2b0:	69a2                	ld	s3,8(sp)
 2b2:	6a02                	ld	s4,0(sp)
 2b4:	6145                	addi	sp,sp,48
 2b6:	8082                	ret

00000000000002b8 <thread_c>:

void 
thread_c(void)
{
 2b8:	7179                	addi	sp,sp,-48
 2ba:	f406                	sd	ra,40(sp)
 2bc:	f022                	sd	s0,32(sp)
 2be:	ec26                	sd	s1,24(sp)
 2c0:	e84a                	sd	s2,16(sp)
 2c2:	e44e                	sd	s3,8(sp)
 2c4:	e052                	sd	s4,0(sp)
 2c6:	1800                	addi	s0,sp,48
  int i;
  printf("thread_c started\n");
 2c8:	00001517          	auipc	a0,0x1
 2cc:	9f050513          	addi	a0,a0,-1552 # cb8 <malloc+0x19c>
 2d0:	00000097          	auipc	ra,0x0
 2d4:	78e080e7          	jalr	1934(ra) # a5e <printf>
  c_started = 1;
 2d8:	4785                	li	a5,1
 2da:	00001717          	auipc	a4,0x1
 2de:	a4f72923          	sw	a5,-1454(a4) # d2c <c_started>
  while(a_started == 0 || b_started == 0)
 2e2:	00001497          	auipc	s1,0x1
 2e6:	a5248493          	addi	s1,s1,-1454 # d34 <a_started>
 2ea:	00001917          	auipc	s2,0x1
 2ee:	a4690913          	addi	s2,s2,-1466 # d30 <b_started>
 2f2:	a029                	j	2fc <thread_c+0x44>
    thread_yield();
 2f4:	00000097          	auipc	ra,0x0
 2f8:	e04080e7          	jalr	-508(ra) # f8 <thread_yield>
  while(a_started == 0 || b_started == 0)
 2fc:	409c                	lw	a5,0(s1)
 2fe:	2781                	sext.w	a5,a5
 300:	dbf5                	beqz	a5,2f4 <thread_c+0x3c>
 302:	00092783          	lw	a5,0(s2)
 306:	2781                	sext.w	a5,a5
 308:	d7f5                	beqz	a5,2f4 <thread_c+0x3c>
  
  for (i = 0; i < 100; i++) {
 30a:	4481                	li	s1,0
    printf("thread_c %d\n", i);
 30c:	00001a17          	auipc	s4,0x1
 310:	9c4a0a13          	addi	s4,s4,-1596 # cd0 <malloc+0x1b4>
    c_n += 1;
 314:	00001917          	auipc	s2,0x1
 318:	a0c90913          	addi	s2,s2,-1524 # d20 <c_n>
  for (i = 0; i < 100; i++) {
 31c:	06400993          	li	s3,100
    printf("thread_c %d\n", i);
 320:	85a6                	mv	a1,s1
 322:	8552                	mv	a0,s4
 324:	00000097          	auipc	ra,0x0
 328:	73a080e7          	jalr	1850(ra) # a5e <printf>
    c_n += 1;
 32c:	00092783          	lw	a5,0(s2)
 330:	2785                	addiw	a5,a5,1
 332:	00f92023          	sw	a5,0(s2)
    thread_yield();
 336:	00000097          	auipc	ra,0x0
 33a:	dc2080e7          	jalr	-574(ra) # f8 <thread_yield>
  for (i = 0; i < 100; i++) {
 33e:	2485                	addiw	s1,s1,1
 340:	ff3490e3          	bne	s1,s3,320 <thread_c+0x68>
  }
  printf("thread_c: exit after %d\n", c_n);
 344:	00001597          	auipc	a1,0x1
 348:	9dc5a583          	lw	a1,-1572(a1) # d20 <c_n>
 34c:	00001517          	auipc	a0,0x1
 350:	99450513          	addi	a0,a0,-1644 # ce0 <malloc+0x1c4>
 354:	00000097          	auipc	ra,0x0
 358:	70a080e7          	jalr	1802(ra) # a5e <printf>

  current_thread->state = FREE;
 35c:	00001797          	auipc	a5,0x1
 360:	9dc7b783          	ld	a5,-1572(a5) # d38 <current_thread>
 364:	6709                	lui	a4,0x2
 366:	97ba                	add	a5,a5,a4
 368:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 36c:	00000097          	auipc	ra,0x0
 370:	cba080e7          	jalr	-838(ra) # 26 <thread_schedule>
}
 374:	70a2                	ld	ra,40(sp)
 376:	7402                	ld	s0,32(sp)
 378:	64e2                	ld	s1,24(sp)
 37a:	6942                	ld	s2,16(sp)
 37c:	69a2                	ld	s3,8(sp)
 37e:	6a02                	ld	s4,0(sp)
 380:	6145                	addi	sp,sp,48
 382:	8082                	ret

0000000000000384 <main>:

int 
main(int argc, char *argv[]) 
{
 384:	1141                	addi	sp,sp,-16
 386:	e406                	sd	ra,8(sp)
 388:	e022                	sd	s0,0(sp)
 38a:	0800                	addi	s0,sp,16
  a_started = b_started = c_started = 0;
 38c:	00001797          	auipc	a5,0x1
 390:	9a07a023          	sw	zero,-1632(a5) # d2c <c_started>
 394:	00001797          	auipc	a5,0x1
 398:	9807ae23          	sw	zero,-1636(a5) # d30 <b_started>
 39c:	00001797          	auipc	a5,0x1
 3a0:	9807ac23          	sw	zero,-1640(a5) # d34 <a_started>
  a_n = b_n = c_n = 0;
 3a4:	00001797          	auipc	a5,0x1
 3a8:	9607ae23          	sw	zero,-1668(a5) # d20 <c_n>
 3ac:	00001797          	auipc	a5,0x1
 3b0:	9607ac23          	sw	zero,-1672(a5) # d24 <b_n>
 3b4:	00001797          	auipc	a5,0x1
 3b8:	9607aa23          	sw	zero,-1676(a5) # d28 <a_n>
  thread_init();
 3bc:	00000097          	auipc	ra,0x0
 3c0:	c44080e7          	jalr	-956(ra) # 0 <thread_init>
  thread_create(thread_a);
 3c4:	00000517          	auipc	a0,0x0
 3c8:	d5c50513          	addi	a0,a0,-676 # 120 <thread_a>
 3cc:	00000097          	auipc	ra,0x0
 3d0:	cea080e7          	jalr	-790(ra) # b6 <thread_create>
  thread_create(thread_b);
 3d4:	00000517          	auipc	a0,0x0
 3d8:	e1850513          	addi	a0,a0,-488 # 1ec <thread_b>
 3dc:	00000097          	auipc	ra,0x0
 3e0:	cda080e7          	jalr	-806(ra) # b6 <thread_create>
  thread_create(thread_c);
 3e4:	00000517          	auipc	a0,0x0
 3e8:	ed450513          	addi	a0,a0,-300 # 2b8 <thread_c>
 3ec:	00000097          	auipc	ra,0x0
 3f0:	cca080e7          	jalr	-822(ra) # b6 <thread_create>
  thread_schedule();
 3f4:	00000097          	auipc	ra,0x0
 3f8:	c32080e7          	jalr	-974(ra) # 26 <thread_schedule>
  exit(0);
 3fc:	4501                	li	a0,0
 3fe:	00000097          	auipc	ra,0x0
 402:	2e8080e7          	jalr	744(ra) # 6e6 <exit>

0000000000000406 <thread_switch>:
         * restore the new thread's registers.
         */

	.globl thread_switch
thread_switch:
	sd ra, 0(a0)
 406:	00153023          	sd	ra,0(a0)
	sd sp, 8(a0)
 40a:	00253423          	sd	sp,8(a0)
	sd s0, 16(a0)
 40e:	e900                	sd	s0,16(a0)
	sd s1, 24(a0)
 410:	ed04                	sd	s1,24(a0)
	sd s2, 32(a0)
 412:	03253023          	sd	s2,32(a0)
	sd s3, 40(a0)
 416:	03353423          	sd	s3,40(a0)
	sd s4, 48(a0)
 41a:	03453823          	sd	s4,48(a0)
	sd s5, 56(a0)
 41e:	03553c23          	sd	s5,56(a0)
	sd s6, 64(a0)
 422:	05653023          	sd	s6,64(a0)
	sd s7, 72(a0)
 426:	05753423          	sd	s7,72(a0)
	sd s8, 80(a0)
 42a:	05853823          	sd	s8,80(a0)
	sd s9, 88(a0)
 42e:	05953c23          	sd	s9,88(a0)
	sd s10, 96(a0)
 432:	07a53023          	sd	s10,96(a0)
	sd s11, 104(a0)
 436:	07b53423          	sd	s11,104(a0)

	ld ra, 0(a1)
 43a:	0005b083          	ld	ra,0(a1)
	ld sp, 8(a1)
 43e:	0085b103          	ld	sp,8(a1)
	ld s0, 16(a1)
 442:	6980                	ld	s0,16(a1)
	ld s1, 24(a1)
 444:	6d84                	ld	s1,24(a1)
	ld s2, 32(a1)
 446:	0205b903          	ld	s2,32(a1)
	ld s3, 40(a1)
 44a:	0285b983          	ld	s3,40(a1)
	ld s4, 48(a1)
 44e:	0305ba03          	ld	s4,48(a1)
	ld s5, 56(a1)
 452:	0385ba83          	ld	s5,56(a1)
	ld s6, 64(a1)
 456:	0405bb03          	ld	s6,64(a1)
	ld s7, 72(a1)
 45a:	0485bb83          	ld	s7,72(a1)
	ld s8, 80(a1)
 45e:	0505bc03          	ld	s8,80(a1)
	ld s9, 88(a1)
 462:	0585bc83          	ld	s9,88(a1)
	ld s10, 96(a1)
 466:	0605bd03          	ld	s10,96(a1)
	ld s11, 104(a1)
 46a:	0685bd83          	ld	s11,104(a1)
	/* YOUR CODE HERE */
	ret    /* return to ra */
 46e:	8082                	ret

0000000000000470 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 470:	1141                	addi	sp,sp,-16
 472:	e422                	sd	s0,8(sp)
 474:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 476:	87aa                	mv	a5,a0
 478:	0585                	addi	a1,a1,1
 47a:	0785                	addi	a5,a5,1
 47c:	fff5c703          	lbu	a4,-1(a1)
 480:	fee78fa3          	sb	a4,-1(a5)
 484:	fb75                	bnez	a4,478 <strcpy+0x8>
    ;
  return os;
}
 486:	6422                	ld	s0,8(sp)
 488:	0141                	addi	sp,sp,16
 48a:	8082                	ret

000000000000048c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 48c:	1141                	addi	sp,sp,-16
 48e:	e422                	sd	s0,8(sp)
 490:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 492:	00054783          	lbu	a5,0(a0)
 496:	cb91                	beqz	a5,4aa <strcmp+0x1e>
 498:	0005c703          	lbu	a4,0(a1)
 49c:	00f71763          	bne	a4,a5,4aa <strcmp+0x1e>
    p++, q++;
 4a0:	0505                	addi	a0,a0,1
 4a2:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 4a4:	00054783          	lbu	a5,0(a0)
 4a8:	fbe5                	bnez	a5,498 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 4aa:	0005c503          	lbu	a0,0(a1)
}
 4ae:	40a7853b          	subw	a0,a5,a0
 4b2:	6422                	ld	s0,8(sp)
 4b4:	0141                	addi	sp,sp,16
 4b6:	8082                	ret

00000000000004b8 <strlen>:

uint
strlen(const char *s)
{
 4b8:	1141                	addi	sp,sp,-16
 4ba:	e422                	sd	s0,8(sp)
 4bc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 4be:	00054783          	lbu	a5,0(a0)
 4c2:	cf91                	beqz	a5,4de <strlen+0x26>
 4c4:	0505                	addi	a0,a0,1
 4c6:	87aa                	mv	a5,a0
 4c8:	4685                	li	a3,1
 4ca:	9e89                	subw	a3,a3,a0
 4cc:	00f6853b          	addw	a0,a3,a5
 4d0:	0785                	addi	a5,a5,1
 4d2:	fff7c703          	lbu	a4,-1(a5)
 4d6:	fb7d                	bnez	a4,4cc <strlen+0x14>
    ;
  return n;
}
 4d8:	6422                	ld	s0,8(sp)
 4da:	0141                	addi	sp,sp,16
 4dc:	8082                	ret
  for(n = 0; s[n]; n++)
 4de:	4501                	li	a0,0
 4e0:	bfe5                	j	4d8 <strlen+0x20>

00000000000004e2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 4e2:	1141                	addi	sp,sp,-16
 4e4:	e422                	sd	s0,8(sp)
 4e6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4e8:	ce09                	beqz	a2,502 <memset+0x20>
 4ea:	87aa                	mv	a5,a0
 4ec:	fff6071b          	addiw	a4,a2,-1
 4f0:	1702                	slli	a4,a4,0x20
 4f2:	9301                	srli	a4,a4,0x20
 4f4:	0705                	addi	a4,a4,1
 4f6:	972a                	add	a4,a4,a0
    cdst[i] = c;
 4f8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4fc:	0785                	addi	a5,a5,1
 4fe:	fee79de3          	bne	a5,a4,4f8 <memset+0x16>
  }
  return dst;
}
 502:	6422                	ld	s0,8(sp)
 504:	0141                	addi	sp,sp,16
 506:	8082                	ret

0000000000000508 <strchr>:

char*
strchr(const char *s, char c)
{
 508:	1141                	addi	sp,sp,-16
 50a:	e422                	sd	s0,8(sp)
 50c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 50e:	00054783          	lbu	a5,0(a0)
 512:	cb99                	beqz	a5,528 <strchr+0x20>
    if(*s == c)
 514:	00f58763          	beq	a1,a5,522 <strchr+0x1a>
  for(; *s; s++)
 518:	0505                	addi	a0,a0,1
 51a:	00054783          	lbu	a5,0(a0)
 51e:	fbfd                	bnez	a5,514 <strchr+0xc>
      return (char*)s;
  return 0;
 520:	4501                	li	a0,0
}
 522:	6422                	ld	s0,8(sp)
 524:	0141                	addi	sp,sp,16
 526:	8082                	ret
  return 0;
 528:	4501                	li	a0,0
 52a:	bfe5                	j	522 <strchr+0x1a>

000000000000052c <gets>:

char*
gets(char *buf, int max)
{
 52c:	711d                	addi	sp,sp,-96
 52e:	ec86                	sd	ra,88(sp)
 530:	e8a2                	sd	s0,80(sp)
 532:	e4a6                	sd	s1,72(sp)
 534:	e0ca                	sd	s2,64(sp)
 536:	fc4e                	sd	s3,56(sp)
 538:	f852                	sd	s4,48(sp)
 53a:	f456                	sd	s5,40(sp)
 53c:	f05a                	sd	s6,32(sp)
 53e:	ec5e                	sd	s7,24(sp)
 540:	1080                	addi	s0,sp,96
 542:	8baa                	mv	s7,a0
 544:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 546:	892a                	mv	s2,a0
 548:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 54a:	4aa9                	li	s5,10
 54c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 54e:	89a6                	mv	s3,s1
 550:	2485                	addiw	s1,s1,1
 552:	0344d863          	bge	s1,s4,582 <gets+0x56>
    cc = read(0, &c, 1);
 556:	4605                	li	a2,1
 558:	faf40593          	addi	a1,s0,-81
 55c:	4501                	li	a0,0
 55e:	00000097          	auipc	ra,0x0
 562:	1a0080e7          	jalr	416(ra) # 6fe <read>
    if(cc < 1)
 566:	00a05e63          	blez	a0,582 <gets+0x56>
    buf[i++] = c;
 56a:	faf44783          	lbu	a5,-81(s0)
 56e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 572:	01578763          	beq	a5,s5,580 <gets+0x54>
 576:	0905                	addi	s2,s2,1
 578:	fd679be3          	bne	a5,s6,54e <gets+0x22>
  for(i=0; i+1 < max; ){
 57c:	89a6                	mv	s3,s1
 57e:	a011                	j	582 <gets+0x56>
 580:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 582:	99de                	add	s3,s3,s7
 584:	00098023          	sb	zero,0(s3)
  return buf;
}
 588:	855e                	mv	a0,s7
 58a:	60e6                	ld	ra,88(sp)
 58c:	6446                	ld	s0,80(sp)
 58e:	64a6                	ld	s1,72(sp)
 590:	6906                	ld	s2,64(sp)
 592:	79e2                	ld	s3,56(sp)
 594:	7a42                	ld	s4,48(sp)
 596:	7aa2                	ld	s5,40(sp)
 598:	7b02                	ld	s6,32(sp)
 59a:	6be2                	ld	s7,24(sp)
 59c:	6125                	addi	sp,sp,96
 59e:	8082                	ret

00000000000005a0 <stat>:

int
stat(const char *n, struct stat *st)
{
 5a0:	1101                	addi	sp,sp,-32
 5a2:	ec06                	sd	ra,24(sp)
 5a4:	e822                	sd	s0,16(sp)
 5a6:	e426                	sd	s1,8(sp)
 5a8:	e04a                	sd	s2,0(sp)
 5aa:	1000                	addi	s0,sp,32
 5ac:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 5ae:	4581                	li	a1,0
 5b0:	00000097          	auipc	ra,0x0
 5b4:	176080e7          	jalr	374(ra) # 726 <open>
  if(fd < 0)
 5b8:	02054563          	bltz	a0,5e2 <stat+0x42>
 5bc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 5be:	85ca                	mv	a1,s2
 5c0:	00000097          	auipc	ra,0x0
 5c4:	17e080e7          	jalr	382(ra) # 73e <fstat>
 5c8:	892a                	mv	s2,a0
  close(fd);
 5ca:	8526                	mv	a0,s1
 5cc:	00000097          	auipc	ra,0x0
 5d0:	142080e7          	jalr	322(ra) # 70e <close>
  return r;
}
 5d4:	854a                	mv	a0,s2
 5d6:	60e2                	ld	ra,24(sp)
 5d8:	6442                	ld	s0,16(sp)
 5da:	64a2                	ld	s1,8(sp)
 5dc:	6902                	ld	s2,0(sp)
 5de:	6105                	addi	sp,sp,32
 5e0:	8082                	ret
    return -1;
 5e2:	597d                	li	s2,-1
 5e4:	bfc5                	j	5d4 <stat+0x34>

00000000000005e6 <atoi>:

int
atoi(const char *s)
{
 5e6:	1141                	addi	sp,sp,-16
 5e8:	e422                	sd	s0,8(sp)
 5ea:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5ec:	00054603          	lbu	a2,0(a0)
 5f0:	fd06079b          	addiw	a5,a2,-48
 5f4:	0ff7f793          	andi	a5,a5,255
 5f8:	4725                	li	a4,9
 5fa:	02f76963          	bltu	a4,a5,62c <atoi+0x46>
 5fe:	86aa                	mv	a3,a0
  n = 0;
 600:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 602:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 604:	0685                	addi	a3,a3,1
 606:	0025179b          	slliw	a5,a0,0x2
 60a:	9fa9                	addw	a5,a5,a0
 60c:	0017979b          	slliw	a5,a5,0x1
 610:	9fb1                	addw	a5,a5,a2
 612:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 616:	0006c603          	lbu	a2,0(a3)
 61a:	fd06071b          	addiw	a4,a2,-48
 61e:	0ff77713          	andi	a4,a4,255
 622:	fee5f1e3          	bgeu	a1,a4,604 <atoi+0x1e>
  return n;
}
 626:	6422                	ld	s0,8(sp)
 628:	0141                	addi	sp,sp,16
 62a:	8082                	ret
  n = 0;
 62c:	4501                	li	a0,0
 62e:	bfe5                	j	626 <atoi+0x40>

0000000000000630 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 630:	1141                	addi	sp,sp,-16
 632:	e422                	sd	s0,8(sp)
 634:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 636:	02b57663          	bgeu	a0,a1,662 <memmove+0x32>
    while(n-- > 0)
 63a:	02c05163          	blez	a2,65c <memmove+0x2c>
 63e:	fff6079b          	addiw	a5,a2,-1
 642:	1782                	slli	a5,a5,0x20
 644:	9381                	srli	a5,a5,0x20
 646:	0785                	addi	a5,a5,1
 648:	97aa                	add	a5,a5,a0
  dst = vdst;
 64a:	872a                	mv	a4,a0
      *dst++ = *src++;
 64c:	0585                	addi	a1,a1,1
 64e:	0705                	addi	a4,a4,1
 650:	fff5c683          	lbu	a3,-1(a1)
 654:	fed70fa3          	sb	a3,-1(a4) # 1fff <__global_pointer$+0xae6>
    while(n-- > 0)
 658:	fee79ae3          	bne	a5,a4,64c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 65c:	6422                	ld	s0,8(sp)
 65e:	0141                	addi	sp,sp,16
 660:	8082                	ret
    dst += n;
 662:	00c50733          	add	a4,a0,a2
    src += n;
 666:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 668:	fec05ae3          	blez	a2,65c <memmove+0x2c>
 66c:	fff6079b          	addiw	a5,a2,-1
 670:	1782                	slli	a5,a5,0x20
 672:	9381                	srli	a5,a5,0x20
 674:	fff7c793          	not	a5,a5
 678:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 67a:	15fd                	addi	a1,a1,-1
 67c:	177d                	addi	a4,a4,-1
 67e:	0005c683          	lbu	a3,0(a1)
 682:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 686:	fee79ae3          	bne	a5,a4,67a <memmove+0x4a>
 68a:	bfc9                	j	65c <memmove+0x2c>

000000000000068c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 68c:	1141                	addi	sp,sp,-16
 68e:	e422                	sd	s0,8(sp)
 690:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 692:	ca05                	beqz	a2,6c2 <memcmp+0x36>
 694:	fff6069b          	addiw	a3,a2,-1
 698:	1682                	slli	a3,a3,0x20
 69a:	9281                	srli	a3,a3,0x20
 69c:	0685                	addi	a3,a3,1
 69e:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 6a0:	00054783          	lbu	a5,0(a0)
 6a4:	0005c703          	lbu	a4,0(a1)
 6a8:	00e79863          	bne	a5,a4,6b8 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 6ac:	0505                	addi	a0,a0,1
    p2++;
 6ae:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 6b0:	fed518e3          	bne	a0,a3,6a0 <memcmp+0x14>
  }
  return 0;
 6b4:	4501                	li	a0,0
 6b6:	a019                	j	6bc <memcmp+0x30>
      return *p1 - *p2;
 6b8:	40e7853b          	subw	a0,a5,a4
}
 6bc:	6422                	ld	s0,8(sp)
 6be:	0141                	addi	sp,sp,16
 6c0:	8082                	ret
  return 0;
 6c2:	4501                	li	a0,0
 6c4:	bfe5                	j	6bc <memcmp+0x30>

00000000000006c6 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 6c6:	1141                	addi	sp,sp,-16
 6c8:	e406                	sd	ra,8(sp)
 6ca:	e022                	sd	s0,0(sp)
 6cc:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 6ce:	00000097          	auipc	ra,0x0
 6d2:	f62080e7          	jalr	-158(ra) # 630 <memmove>
}
 6d6:	60a2                	ld	ra,8(sp)
 6d8:	6402                	ld	s0,0(sp)
 6da:	0141                	addi	sp,sp,16
 6dc:	8082                	ret

00000000000006de <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 6de:	4885                	li	a7,1
 ecall
 6e0:	00000073          	ecall
 ret
 6e4:	8082                	ret

00000000000006e6 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6e6:	4889                	li	a7,2
 ecall
 6e8:	00000073          	ecall
 ret
 6ec:	8082                	ret

00000000000006ee <wait>:
.global wait
wait:
 li a7, SYS_wait
 6ee:	488d                	li	a7,3
 ecall
 6f0:	00000073          	ecall
 ret
 6f4:	8082                	ret

00000000000006f6 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6f6:	4891                	li	a7,4
 ecall
 6f8:	00000073          	ecall
 ret
 6fc:	8082                	ret

00000000000006fe <read>:
.global read
read:
 li a7, SYS_read
 6fe:	4895                	li	a7,5
 ecall
 700:	00000073          	ecall
 ret
 704:	8082                	ret

0000000000000706 <write>:
.global write
write:
 li a7, SYS_write
 706:	48c1                	li	a7,16
 ecall
 708:	00000073          	ecall
 ret
 70c:	8082                	ret

000000000000070e <close>:
.global close
close:
 li a7, SYS_close
 70e:	48d5                	li	a7,21
 ecall
 710:	00000073          	ecall
 ret
 714:	8082                	ret

0000000000000716 <kill>:
.global kill
kill:
 li a7, SYS_kill
 716:	4899                	li	a7,6
 ecall
 718:	00000073          	ecall
 ret
 71c:	8082                	ret

000000000000071e <exec>:
.global exec
exec:
 li a7, SYS_exec
 71e:	489d                	li	a7,7
 ecall
 720:	00000073          	ecall
 ret
 724:	8082                	ret

0000000000000726 <open>:
.global open
open:
 li a7, SYS_open
 726:	48bd                	li	a7,15
 ecall
 728:	00000073          	ecall
 ret
 72c:	8082                	ret

000000000000072e <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 72e:	48c5                	li	a7,17
 ecall
 730:	00000073          	ecall
 ret
 734:	8082                	ret

0000000000000736 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 736:	48c9                	li	a7,18
 ecall
 738:	00000073          	ecall
 ret
 73c:	8082                	ret

000000000000073e <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 73e:	48a1                	li	a7,8
 ecall
 740:	00000073          	ecall
 ret
 744:	8082                	ret

0000000000000746 <link>:
.global link
link:
 li a7, SYS_link
 746:	48cd                	li	a7,19
 ecall
 748:	00000073          	ecall
 ret
 74c:	8082                	ret

000000000000074e <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 74e:	48d1                	li	a7,20
 ecall
 750:	00000073          	ecall
 ret
 754:	8082                	ret

0000000000000756 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 756:	48a5                	li	a7,9
 ecall
 758:	00000073          	ecall
 ret
 75c:	8082                	ret

000000000000075e <dup>:
.global dup
dup:
 li a7, SYS_dup
 75e:	48a9                	li	a7,10
 ecall
 760:	00000073          	ecall
 ret
 764:	8082                	ret

0000000000000766 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 766:	48ad                	li	a7,11
 ecall
 768:	00000073          	ecall
 ret
 76c:	8082                	ret

000000000000076e <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 76e:	48b1                	li	a7,12
 ecall
 770:	00000073          	ecall
 ret
 774:	8082                	ret

0000000000000776 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 776:	48b5                	li	a7,13
 ecall
 778:	00000073          	ecall
 ret
 77c:	8082                	ret

000000000000077e <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 77e:	48b9                	li	a7,14
 ecall
 780:	00000073          	ecall
 ret
 784:	8082                	ret

0000000000000786 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 786:	1101                	addi	sp,sp,-32
 788:	ec06                	sd	ra,24(sp)
 78a:	e822                	sd	s0,16(sp)
 78c:	1000                	addi	s0,sp,32
 78e:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 792:	4605                	li	a2,1
 794:	fef40593          	addi	a1,s0,-17
 798:	00000097          	auipc	ra,0x0
 79c:	f6e080e7          	jalr	-146(ra) # 706 <write>
}
 7a0:	60e2                	ld	ra,24(sp)
 7a2:	6442                	ld	s0,16(sp)
 7a4:	6105                	addi	sp,sp,32
 7a6:	8082                	ret

00000000000007a8 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 7a8:	7139                	addi	sp,sp,-64
 7aa:	fc06                	sd	ra,56(sp)
 7ac:	f822                	sd	s0,48(sp)
 7ae:	f426                	sd	s1,40(sp)
 7b0:	f04a                	sd	s2,32(sp)
 7b2:	ec4e                	sd	s3,24(sp)
 7b4:	0080                	addi	s0,sp,64
 7b6:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 7b8:	c299                	beqz	a3,7be <printint+0x16>
 7ba:	0805c863          	bltz	a1,84a <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 7be:	2581                	sext.w	a1,a1
  neg = 0;
 7c0:	4881                	li	a7,0
 7c2:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 7c6:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 7c8:	2601                	sext.w	a2,a2
 7ca:	00000517          	auipc	a0,0x0
 7ce:	53e50513          	addi	a0,a0,1342 # d08 <digits>
 7d2:	883a                	mv	a6,a4
 7d4:	2705                	addiw	a4,a4,1
 7d6:	02c5f7bb          	remuw	a5,a1,a2
 7da:	1782                	slli	a5,a5,0x20
 7dc:	9381                	srli	a5,a5,0x20
 7de:	97aa                	add	a5,a5,a0
 7e0:	0007c783          	lbu	a5,0(a5)
 7e4:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 7e8:	0005879b          	sext.w	a5,a1
 7ec:	02c5d5bb          	divuw	a1,a1,a2
 7f0:	0685                	addi	a3,a3,1
 7f2:	fec7f0e3          	bgeu	a5,a2,7d2 <printint+0x2a>
  if(neg)
 7f6:	00088b63          	beqz	a7,80c <printint+0x64>
    buf[i++] = '-';
 7fa:	fd040793          	addi	a5,s0,-48
 7fe:	973e                	add	a4,a4,a5
 800:	02d00793          	li	a5,45
 804:	fef70823          	sb	a5,-16(a4)
 808:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 80c:	02e05863          	blez	a4,83c <printint+0x94>
 810:	fc040793          	addi	a5,s0,-64
 814:	00e78933          	add	s2,a5,a4
 818:	fff78993          	addi	s3,a5,-1
 81c:	99ba                	add	s3,s3,a4
 81e:	377d                	addiw	a4,a4,-1
 820:	1702                	slli	a4,a4,0x20
 822:	9301                	srli	a4,a4,0x20
 824:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 828:	fff94583          	lbu	a1,-1(s2)
 82c:	8526                	mv	a0,s1
 82e:	00000097          	auipc	ra,0x0
 832:	f58080e7          	jalr	-168(ra) # 786 <putc>
  while(--i >= 0)
 836:	197d                	addi	s2,s2,-1
 838:	ff3918e3          	bne	s2,s3,828 <printint+0x80>
}
 83c:	70e2                	ld	ra,56(sp)
 83e:	7442                	ld	s0,48(sp)
 840:	74a2                	ld	s1,40(sp)
 842:	7902                	ld	s2,32(sp)
 844:	69e2                	ld	s3,24(sp)
 846:	6121                	addi	sp,sp,64
 848:	8082                	ret
    x = -xx;
 84a:	40b005bb          	negw	a1,a1
    neg = 1;
 84e:	4885                	li	a7,1
    x = -xx;
 850:	bf8d                	j	7c2 <printint+0x1a>

0000000000000852 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 852:	7119                	addi	sp,sp,-128
 854:	fc86                	sd	ra,120(sp)
 856:	f8a2                	sd	s0,112(sp)
 858:	f4a6                	sd	s1,104(sp)
 85a:	f0ca                	sd	s2,96(sp)
 85c:	ecce                	sd	s3,88(sp)
 85e:	e8d2                	sd	s4,80(sp)
 860:	e4d6                	sd	s5,72(sp)
 862:	e0da                	sd	s6,64(sp)
 864:	fc5e                	sd	s7,56(sp)
 866:	f862                	sd	s8,48(sp)
 868:	f466                	sd	s9,40(sp)
 86a:	f06a                	sd	s10,32(sp)
 86c:	ec6e                	sd	s11,24(sp)
 86e:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 870:	0005c903          	lbu	s2,0(a1)
 874:	18090f63          	beqz	s2,a12 <vprintf+0x1c0>
 878:	8aaa                	mv	s5,a0
 87a:	8b32                	mv	s6,a2
 87c:	00158493          	addi	s1,a1,1
  state = 0;
 880:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 882:	02500a13          	li	s4,37
      if(c == 'd'){
 886:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 88a:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 88e:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 892:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 896:	00000b97          	auipc	s7,0x0
 89a:	472b8b93          	addi	s7,s7,1138 # d08 <digits>
 89e:	a839                	j	8bc <vprintf+0x6a>
        putc(fd, c);
 8a0:	85ca                	mv	a1,s2
 8a2:	8556                	mv	a0,s5
 8a4:	00000097          	auipc	ra,0x0
 8a8:	ee2080e7          	jalr	-286(ra) # 786 <putc>
 8ac:	a019                	j	8b2 <vprintf+0x60>
    } else if(state == '%'){
 8ae:	01498f63          	beq	s3,s4,8cc <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 8b2:	0485                	addi	s1,s1,1
 8b4:	fff4c903          	lbu	s2,-1(s1)
 8b8:	14090d63          	beqz	s2,a12 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 8bc:	0009079b          	sext.w	a5,s2
    if(state == 0){
 8c0:	fe0997e3          	bnez	s3,8ae <vprintf+0x5c>
      if(c == '%'){
 8c4:	fd479ee3          	bne	a5,s4,8a0 <vprintf+0x4e>
        state = '%';
 8c8:	89be                	mv	s3,a5
 8ca:	b7e5                	j	8b2 <vprintf+0x60>
      if(c == 'd'){
 8cc:	05878063          	beq	a5,s8,90c <vprintf+0xba>
      } else if(c == 'l') {
 8d0:	05978c63          	beq	a5,s9,928 <vprintf+0xd6>
      } else if(c == 'x') {
 8d4:	07a78863          	beq	a5,s10,944 <vprintf+0xf2>
      } else if(c == 'p') {
 8d8:	09b78463          	beq	a5,s11,960 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 8dc:	07300713          	li	a4,115
 8e0:	0ce78663          	beq	a5,a4,9ac <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 8e4:	06300713          	li	a4,99
 8e8:	0ee78e63          	beq	a5,a4,9e4 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 8ec:	11478863          	beq	a5,s4,9fc <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8f0:	85d2                	mv	a1,s4
 8f2:	8556                	mv	a0,s5
 8f4:	00000097          	auipc	ra,0x0
 8f8:	e92080e7          	jalr	-366(ra) # 786 <putc>
        putc(fd, c);
 8fc:	85ca                	mv	a1,s2
 8fe:	8556                	mv	a0,s5
 900:	00000097          	auipc	ra,0x0
 904:	e86080e7          	jalr	-378(ra) # 786 <putc>
      }
      state = 0;
 908:	4981                	li	s3,0
 90a:	b765                	j	8b2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 90c:	008b0913          	addi	s2,s6,8
 910:	4685                	li	a3,1
 912:	4629                	li	a2,10
 914:	000b2583          	lw	a1,0(s6)
 918:	8556                	mv	a0,s5
 91a:	00000097          	auipc	ra,0x0
 91e:	e8e080e7          	jalr	-370(ra) # 7a8 <printint>
 922:	8b4a                	mv	s6,s2
      state = 0;
 924:	4981                	li	s3,0
 926:	b771                	j	8b2 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 928:	008b0913          	addi	s2,s6,8
 92c:	4681                	li	a3,0
 92e:	4629                	li	a2,10
 930:	000b2583          	lw	a1,0(s6)
 934:	8556                	mv	a0,s5
 936:	00000097          	auipc	ra,0x0
 93a:	e72080e7          	jalr	-398(ra) # 7a8 <printint>
 93e:	8b4a                	mv	s6,s2
      state = 0;
 940:	4981                	li	s3,0
 942:	bf85                	j	8b2 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 944:	008b0913          	addi	s2,s6,8
 948:	4681                	li	a3,0
 94a:	4641                	li	a2,16
 94c:	000b2583          	lw	a1,0(s6)
 950:	8556                	mv	a0,s5
 952:	00000097          	auipc	ra,0x0
 956:	e56080e7          	jalr	-426(ra) # 7a8 <printint>
 95a:	8b4a                	mv	s6,s2
      state = 0;
 95c:	4981                	li	s3,0
 95e:	bf91                	j	8b2 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 960:	008b0793          	addi	a5,s6,8
 964:	f8f43423          	sd	a5,-120(s0)
 968:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 96c:	03000593          	li	a1,48
 970:	8556                	mv	a0,s5
 972:	00000097          	auipc	ra,0x0
 976:	e14080e7          	jalr	-492(ra) # 786 <putc>
  putc(fd, 'x');
 97a:	85ea                	mv	a1,s10
 97c:	8556                	mv	a0,s5
 97e:	00000097          	auipc	ra,0x0
 982:	e08080e7          	jalr	-504(ra) # 786 <putc>
 986:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 988:	03c9d793          	srli	a5,s3,0x3c
 98c:	97de                	add	a5,a5,s7
 98e:	0007c583          	lbu	a1,0(a5)
 992:	8556                	mv	a0,s5
 994:	00000097          	auipc	ra,0x0
 998:	df2080e7          	jalr	-526(ra) # 786 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 99c:	0992                	slli	s3,s3,0x4
 99e:	397d                	addiw	s2,s2,-1
 9a0:	fe0914e3          	bnez	s2,988 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 9a4:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 9a8:	4981                	li	s3,0
 9aa:	b721                	j	8b2 <vprintf+0x60>
        s = va_arg(ap, char*);
 9ac:	008b0993          	addi	s3,s6,8
 9b0:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 9b4:	02090163          	beqz	s2,9d6 <vprintf+0x184>
        while(*s != 0){
 9b8:	00094583          	lbu	a1,0(s2)
 9bc:	c9a1                	beqz	a1,a0c <vprintf+0x1ba>
          putc(fd, *s);
 9be:	8556                	mv	a0,s5
 9c0:	00000097          	auipc	ra,0x0
 9c4:	dc6080e7          	jalr	-570(ra) # 786 <putc>
          s++;
 9c8:	0905                	addi	s2,s2,1
        while(*s != 0){
 9ca:	00094583          	lbu	a1,0(s2)
 9ce:	f9e5                	bnez	a1,9be <vprintf+0x16c>
        s = va_arg(ap, char*);
 9d0:	8b4e                	mv	s6,s3
      state = 0;
 9d2:	4981                	li	s3,0
 9d4:	bdf9                	j	8b2 <vprintf+0x60>
          s = "(null)";
 9d6:	00000917          	auipc	s2,0x0
 9da:	32a90913          	addi	s2,s2,810 # d00 <malloc+0x1e4>
        while(*s != 0){
 9de:	02800593          	li	a1,40
 9e2:	bff1                	j	9be <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 9e4:	008b0913          	addi	s2,s6,8
 9e8:	000b4583          	lbu	a1,0(s6)
 9ec:	8556                	mv	a0,s5
 9ee:	00000097          	auipc	ra,0x0
 9f2:	d98080e7          	jalr	-616(ra) # 786 <putc>
 9f6:	8b4a                	mv	s6,s2
      state = 0;
 9f8:	4981                	li	s3,0
 9fa:	bd65                	j	8b2 <vprintf+0x60>
        putc(fd, c);
 9fc:	85d2                	mv	a1,s4
 9fe:	8556                	mv	a0,s5
 a00:	00000097          	auipc	ra,0x0
 a04:	d86080e7          	jalr	-634(ra) # 786 <putc>
      state = 0;
 a08:	4981                	li	s3,0
 a0a:	b565                	j	8b2 <vprintf+0x60>
        s = va_arg(ap, char*);
 a0c:	8b4e                	mv	s6,s3
      state = 0;
 a0e:	4981                	li	s3,0
 a10:	b54d                	j	8b2 <vprintf+0x60>
    }
  }
}
 a12:	70e6                	ld	ra,120(sp)
 a14:	7446                	ld	s0,112(sp)
 a16:	74a6                	ld	s1,104(sp)
 a18:	7906                	ld	s2,96(sp)
 a1a:	69e6                	ld	s3,88(sp)
 a1c:	6a46                	ld	s4,80(sp)
 a1e:	6aa6                	ld	s5,72(sp)
 a20:	6b06                	ld	s6,64(sp)
 a22:	7be2                	ld	s7,56(sp)
 a24:	7c42                	ld	s8,48(sp)
 a26:	7ca2                	ld	s9,40(sp)
 a28:	7d02                	ld	s10,32(sp)
 a2a:	6de2                	ld	s11,24(sp)
 a2c:	6109                	addi	sp,sp,128
 a2e:	8082                	ret

0000000000000a30 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a30:	715d                	addi	sp,sp,-80
 a32:	ec06                	sd	ra,24(sp)
 a34:	e822                	sd	s0,16(sp)
 a36:	1000                	addi	s0,sp,32
 a38:	e010                	sd	a2,0(s0)
 a3a:	e414                	sd	a3,8(s0)
 a3c:	e818                	sd	a4,16(s0)
 a3e:	ec1c                	sd	a5,24(s0)
 a40:	03043023          	sd	a6,32(s0)
 a44:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a48:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a4c:	8622                	mv	a2,s0
 a4e:	00000097          	auipc	ra,0x0
 a52:	e04080e7          	jalr	-508(ra) # 852 <vprintf>
}
 a56:	60e2                	ld	ra,24(sp)
 a58:	6442                	ld	s0,16(sp)
 a5a:	6161                	addi	sp,sp,80
 a5c:	8082                	ret

0000000000000a5e <printf>:

void
printf(const char *fmt, ...)
{
 a5e:	711d                	addi	sp,sp,-96
 a60:	ec06                	sd	ra,24(sp)
 a62:	e822                	sd	s0,16(sp)
 a64:	1000                	addi	s0,sp,32
 a66:	e40c                	sd	a1,8(s0)
 a68:	e810                	sd	a2,16(s0)
 a6a:	ec14                	sd	a3,24(s0)
 a6c:	f018                	sd	a4,32(s0)
 a6e:	f41c                	sd	a5,40(s0)
 a70:	03043823          	sd	a6,48(s0)
 a74:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a78:	00840613          	addi	a2,s0,8
 a7c:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a80:	85aa                	mv	a1,a0
 a82:	4505                	li	a0,1
 a84:	00000097          	auipc	ra,0x0
 a88:	dce080e7          	jalr	-562(ra) # 852 <vprintf>
}
 a8c:	60e2                	ld	ra,24(sp)
 a8e:	6442                	ld	s0,16(sp)
 a90:	6125                	addi	sp,sp,96
 a92:	8082                	ret

0000000000000a94 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a94:	1141                	addi	sp,sp,-16
 a96:	e422                	sd	s0,8(sp)
 a98:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a9a:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a9e:	00000797          	auipc	a5,0x0
 aa2:	2a27b783          	ld	a5,674(a5) # d40 <freep>
 aa6:	a805                	j	ad6 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 aa8:	4618                	lw	a4,8(a2)
 aaa:	9db9                	addw	a1,a1,a4
 aac:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 ab0:	6398                	ld	a4,0(a5)
 ab2:	6318                	ld	a4,0(a4)
 ab4:	fee53823          	sd	a4,-16(a0)
 ab8:	a091                	j	afc <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 aba:	ff852703          	lw	a4,-8(a0)
 abe:	9e39                	addw	a2,a2,a4
 ac0:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 ac2:	ff053703          	ld	a4,-16(a0)
 ac6:	e398                	sd	a4,0(a5)
 ac8:	a099                	j	b0e <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 aca:	6398                	ld	a4,0(a5)
 acc:	00e7e463          	bltu	a5,a4,ad4 <free+0x40>
 ad0:	00e6ea63          	bltu	a3,a4,ae4 <free+0x50>
{
 ad4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ad6:	fed7fae3          	bgeu	a5,a3,aca <free+0x36>
 ada:	6398                	ld	a4,0(a5)
 adc:	00e6e463          	bltu	a3,a4,ae4 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 ae0:	fee7eae3          	bltu	a5,a4,ad4 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 ae4:	ff852583          	lw	a1,-8(a0)
 ae8:	6390                	ld	a2,0(a5)
 aea:	02059713          	slli	a4,a1,0x20
 aee:	9301                	srli	a4,a4,0x20
 af0:	0712                	slli	a4,a4,0x4
 af2:	9736                	add	a4,a4,a3
 af4:	fae60ae3          	beq	a2,a4,aa8 <free+0x14>
    bp->s.ptr = p->s.ptr;
 af8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 afc:	4790                	lw	a2,8(a5)
 afe:	02061713          	slli	a4,a2,0x20
 b02:	9301                	srli	a4,a4,0x20
 b04:	0712                	slli	a4,a4,0x4
 b06:	973e                	add	a4,a4,a5
 b08:	fae689e3          	beq	a3,a4,aba <free+0x26>
  } else
    p->s.ptr = bp;
 b0c:	e394                	sd	a3,0(a5)
  freep = p;
 b0e:	00000717          	auipc	a4,0x0
 b12:	22f73923          	sd	a5,562(a4) # d40 <freep>
}
 b16:	6422                	ld	s0,8(sp)
 b18:	0141                	addi	sp,sp,16
 b1a:	8082                	ret

0000000000000b1c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b1c:	7139                	addi	sp,sp,-64
 b1e:	fc06                	sd	ra,56(sp)
 b20:	f822                	sd	s0,48(sp)
 b22:	f426                	sd	s1,40(sp)
 b24:	f04a                	sd	s2,32(sp)
 b26:	ec4e                	sd	s3,24(sp)
 b28:	e852                	sd	s4,16(sp)
 b2a:	e456                	sd	s5,8(sp)
 b2c:	e05a                	sd	s6,0(sp)
 b2e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b30:	02051493          	slli	s1,a0,0x20
 b34:	9081                	srli	s1,s1,0x20
 b36:	04bd                	addi	s1,s1,15
 b38:	8091                	srli	s1,s1,0x4
 b3a:	0014899b          	addiw	s3,s1,1
 b3e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b40:	00000517          	auipc	a0,0x0
 b44:	20053503          	ld	a0,512(a0) # d40 <freep>
 b48:	c515                	beqz	a0,b74 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b4a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b4c:	4798                	lw	a4,8(a5)
 b4e:	02977f63          	bgeu	a4,s1,b8c <malloc+0x70>
 b52:	8a4e                	mv	s4,s3
 b54:	0009871b          	sext.w	a4,s3
 b58:	6685                	lui	a3,0x1
 b5a:	00d77363          	bgeu	a4,a3,b60 <malloc+0x44>
 b5e:	6a05                	lui	s4,0x1
 b60:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b64:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b68:	00000917          	auipc	s2,0x0
 b6c:	1d890913          	addi	s2,s2,472 # d40 <freep>
  if(p == (char*)-1)
 b70:	5afd                	li	s5,-1
 b72:	a88d                	j	be4 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 b74:	00008797          	auipc	a5,0x8
 b78:	3b478793          	addi	a5,a5,948 # 8f28 <base>
 b7c:	00000717          	auipc	a4,0x0
 b80:	1cf73223          	sd	a5,452(a4) # d40 <freep>
 b84:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b86:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b8a:	b7e1                	j	b52 <malloc+0x36>
      if(p->s.size == nunits)
 b8c:	02e48b63          	beq	s1,a4,bc2 <malloc+0xa6>
        p->s.size -= nunits;
 b90:	4137073b          	subw	a4,a4,s3
 b94:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b96:	1702                	slli	a4,a4,0x20
 b98:	9301                	srli	a4,a4,0x20
 b9a:	0712                	slli	a4,a4,0x4
 b9c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b9e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 ba2:	00000717          	auipc	a4,0x0
 ba6:	18a73f23          	sd	a0,414(a4) # d40 <freep>
      return (void*)(p + 1);
 baa:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 bae:	70e2                	ld	ra,56(sp)
 bb0:	7442                	ld	s0,48(sp)
 bb2:	74a2                	ld	s1,40(sp)
 bb4:	7902                	ld	s2,32(sp)
 bb6:	69e2                	ld	s3,24(sp)
 bb8:	6a42                	ld	s4,16(sp)
 bba:	6aa2                	ld	s5,8(sp)
 bbc:	6b02                	ld	s6,0(sp)
 bbe:	6121                	addi	sp,sp,64
 bc0:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 bc2:	6398                	ld	a4,0(a5)
 bc4:	e118                	sd	a4,0(a0)
 bc6:	bff1                	j	ba2 <malloc+0x86>
  hp->s.size = nu;
 bc8:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 bcc:	0541                	addi	a0,a0,16
 bce:	00000097          	auipc	ra,0x0
 bd2:	ec6080e7          	jalr	-314(ra) # a94 <free>
  return freep;
 bd6:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 bda:	d971                	beqz	a0,bae <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bdc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bde:	4798                	lw	a4,8(a5)
 be0:	fa9776e3          	bgeu	a4,s1,b8c <malloc+0x70>
    if(p == freep)
 be4:	00093703          	ld	a4,0(s2)
 be8:	853e                	mv	a0,a5
 bea:	fef719e3          	bne	a4,a5,bdc <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 bee:	8552                	mv	a0,s4
 bf0:	00000097          	auipc	ra,0x0
 bf4:	b7e080e7          	jalr	-1154(ra) # 76e <sbrk>
  if(p == (char*)-1)
 bf8:	fd5518e3          	bne	a0,s5,bc8 <malloc+0xac>
        return 0;
 bfc:	4501                	li	a0,0
 bfe:	bf45                	j	bae <malloc+0x92>
