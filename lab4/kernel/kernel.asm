
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <spin-0x1a>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	006000ef          	jal	ra,8000001c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <start>:
extern void timervec();

// entry.S jumps here in machine mode on stack0.
void
start()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16

static inline uint64
r_mstatus()
{
  uint64 x;
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000022:	300027f3          	csrr	a5,mstatus
  // set M Previous Privilege mode to Supervisor, for mret.
  unsigned long x = r_mstatus();
  x &= ~MSTATUS_MPP_MASK;
    80000026:	7779                	lui	a4,0xffffe
    80000028:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    8000002c:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000002e:	6705                	lui	a4,0x1
    80000030:	80070713          	addi	a4,a4,-2048 # 800 <spin-0x7ffff81a>
    80000034:	8fd9                	or	a5,a5,a4
}

static inline void 
w_mstatus(uint64 x)
{
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000036:	30079073          	csrw	mstatus,a5
// instruction address to which a return from
// exception will go.
static inline void 
w_mepc(uint64 x)
{
  asm volatile("csrw mepc, %0" : : "r" (x));
    8000003a:	00001797          	auipc	a5,0x1
    8000003e:	ed478793          	addi	a5,a5,-300 # 80000f0e <main>
    80000042:	34179073          	csrw	mepc,a5
// supervisor address translation and protection;
// holds the address of the page table.
static inline void 
w_satp(uint64 x)
{
  asm volatile("csrw satp, %0" : : "r" (x));
    80000046:	4781                	li	a5,0
    80000048:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    8000004c:	67c1                	lui	a5,0x10
    8000004e:	17fd                	addi	a5,a5,-1
    80000050:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    80000054:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    80000058:	104027f3          	csrr	a5,sie
  w_satp(0);

  // delegate all interrupts and exceptions to supervisor mode.
  w_medeleg(0xffff);
  w_mideleg(0xffff);
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    8000005c:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    80000060:	10479073          	csrw	sie,a5
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000064:	f14027f3          	csrr	a5,mhartid

  int id = r_mhartid();
  w_tp(id);
    80000068:	2781                	sext.w	a5,a5


static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    8000006a:	823e                	mv	tp,a5

  // switch to supervisor mode and jump to main().
  asm volatile("mret");
    8000006c:	30200073          	mret
}
    80000070:	6422                	ld	s0,8(sp)
    80000072:	0141                	addi	sp,sp,16
    80000074:	8082                	ret

0000000080000076 <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    80000076:	1141                	addi	sp,sp,-16
    80000078:	e422                	sd	s0,8(sp)
    8000007a:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    8000007c:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000080:	0037969b          	slliw	a3,a5,0x3
    80000084:	02004737          	lui	a4,0x2004
    80000088:	96ba                	add	a3,a3,a4
    8000008a:	0200c737          	lui	a4,0x200c
    8000008e:	ff873603          	ld	a2,-8(a4) # 200bff8 <spin-0x7dff4022>
    80000092:	000f4737          	lui	a4,0xf4
    80000096:	24070713          	addi	a4,a4,576 # f4240 <spin-0x7ff0bdda>
    8000009a:	963a                	add	a2,a2,a4
    8000009c:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    8000009e:	0057979b          	slliw	a5,a5,0x5
    800000a2:	078e                	slli	a5,a5,0x3
    800000a4:	00009617          	auipc	a2,0x9
    800000a8:	f8c60613          	addi	a2,a2,-116 # 80009030 <mscratch0>
    800000ac:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    800000ae:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    800000b0:	f798                	sd	a4,40(a5)
  asm volatile("csrw mscratch, %0" : : "r" (x));
    800000b2:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    800000b6:	00006797          	auipc	a5,0x6
    800000ba:	caa78793          	addi	a5,a5,-854 # 80005d60 <timervec>
    800000be:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    800000c2:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    800000c6:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000ca:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    800000ce:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    800000d2:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    800000d6:	30479073          	csrw	mie,a5
}
    800000da:	6422                	ld	s0,8(sp)
    800000dc:	0141                	addi	sp,sp,16
    800000de:	8082                	ret

00000000800000e0 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000e0:	715d                	addi	sp,sp,-80
    800000e2:	e486                	sd	ra,72(sp)
    800000e4:	e0a2                	sd	s0,64(sp)
    800000e6:	fc26                	sd	s1,56(sp)
    800000e8:	f84a                	sd	s2,48(sp)
    800000ea:	f44e                	sd	s3,40(sp)
    800000ec:	f052                	sd	s4,32(sp)
    800000ee:	ec56                	sd	s5,24(sp)
    800000f0:	0880                	addi	s0,sp,80
    800000f2:	8a2a                	mv	s4,a0
    800000f4:	84ae                	mv	s1,a1
    800000f6:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    800000f8:	00011517          	auipc	a0,0x11
    800000fc:	73850513          	addi	a0,a0,1848 # 80011830 <cons>
    80000100:	00001097          	auipc	ra,0x1
    80000104:	b60080e7          	jalr	-1184(ra) # 80000c60 <acquire>
  for(i = 0; i < n; i++){
    80000108:	05305b63          	blez	s3,8000015e <consolewrite+0x7e>
    8000010c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000010e:	5afd                	li	s5,-1
    80000110:	4685                	li	a3,1
    80000112:	8626                	mv	a2,s1
    80000114:	85d2                	mv	a1,s4
    80000116:	fbf40513          	addi	a0,s0,-65
    8000011a:	00002097          	auipc	ra,0x2
    8000011e:	492080e7          	jalr	1170(ra) # 800025ac <either_copyin>
    80000122:	01550c63          	beq	a0,s5,8000013a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000126:	fbf44503          	lbu	a0,-65(s0)
    8000012a:	00001097          	auipc	ra,0x1
    8000012e:	806080e7          	jalr	-2042(ra) # 80000930 <uartputc>
  for(i = 0; i < n; i++){
    80000132:	2905                	addiw	s2,s2,1
    80000134:	0485                	addi	s1,s1,1
    80000136:	fd299de3          	bne	s3,s2,80000110 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000013a:	00011517          	auipc	a0,0x11
    8000013e:	6f650513          	addi	a0,a0,1782 # 80011830 <cons>
    80000142:	00001097          	auipc	ra,0x1
    80000146:	bd2080e7          	jalr	-1070(ra) # 80000d14 <release>

  return i;
}
    8000014a:	854a                	mv	a0,s2
    8000014c:	60a6                	ld	ra,72(sp)
    8000014e:	6406                	ld	s0,64(sp)
    80000150:	74e2                	ld	s1,56(sp)
    80000152:	7942                	ld	s2,48(sp)
    80000154:	79a2                	ld	s3,40(sp)
    80000156:	7a02                	ld	s4,32(sp)
    80000158:	6ae2                	ld	s5,24(sp)
    8000015a:	6161                	addi	sp,sp,80
    8000015c:	8082                	ret
  for(i = 0; i < n; i++){
    8000015e:	4901                	li	s2,0
    80000160:	bfe9                	j	8000013a <consolewrite+0x5a>

0000000080000162 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000162:	7119                	addi	sp,sp,-128
    80000164:	fc86                	sd	ra,120(sp)
    80000166:	f8a2                	sd	s0,112(sp)
    80000168:	f4a6                	sd	s1,104(sp)
    8000016a:	f0ca                	sd	s2,96(sp)
    8000016c:	ecce                	sd	s3,88(sp)
    8000016e:	e8d2                	sd	s4,80(sp)
    80000170:	e4d6                	sd	s5,72(sp)
    80000172:	e0da                	sd	s6,64(sp)
    80000174:	fc5e                	sd	s7,56(sp)
    80000176:	f862                	sd	s8,48(sp)
    80000178:	f466                	sd	s9,40(sp)
    8000017a:	f06a                	sd	s10,32(sp)
    8000017c:	ec6e                	sd	s11,24(sp)
    8000017e:	0100                	addi	s0,sp,128
    80000180:	8b2a                	mv	s6,a0
    80000182:	8aae                	mv	s5,a1
    80000184:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	6a650513          	addi	a0,a0,1702 # 80011830 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	ace080e7          	jalr	-1330(ra) # 80000c60 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	69648493          	addi	s1,s1,1686 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	89a6                	mv	s3,s1
    800001a4:	00011917          	auipc	s2,0x11
    800001a8:	72490913          	addi	s2,s2,1828 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ac:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ae:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b0:	4da9                	li	s11,10
  while(n > 0){
    800001b2:	07405863          	blez	s4,80000222 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b6:	0984a783          	lw	a5,152(s1)
    800001ba:	09c4a703          	lw	a4,156(s1)
    800001be:	02f71463          	bne	a4,a5,800001e6 <consoleread+0x84>
      if(myproc()->killed){
    800001c2:	00002097          	auipc	ra,0x2
    800001c6:	86c080e7          	jalr	-1940(ra) # 80001a2e <myproc>
    800001ca:	591c                	lw	a5,48(a0)
    800001cc:	e7b5                	bnez	a5,80000238 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001ce:	85ce                	mv	a1,s3
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	122080e7          	jalr	290(ra) # 800022f4 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fef700e3          	beq	a4,a5,800001c2 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e6:	0017871b          	addiw	a4,a5,1
    800001ea:	08e4ac23          	sw	a4,152(s1)
    800001ee:	07f7f713          	andi	a4,a5,127
    800001f2:	9726                	add	a4,a4,s1
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fc:	079c0663          	beq	s8,s9,80000268 <consoleread+0x106>
    cbuf = c;
    80000200:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000204:	4685                	li	a3,1
    80000206:	f8f40613          	addi	a2,s0,-113
    8000020a:	85d6                	mv	a1,s5
    8000020c:	855a                	mv	a0,s6
    8000020e:	00002097          	auipc	ra,0x2
    80000212:	348080e7          	jalr	840(ra) # 80002556 <either_copyout>
    80000216:	01a50663          	beq	a0,s10,80000222 <consoleread+0xc0>
    dst++;
    8000021a:	0a85                	addi	s5,s5,1
    --n;
    8000021c:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000021e:	f9bc1ae3          	bne	s8,s11,800001b2 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000222:	00011517          	auipc	a0,0x11
    80000226:	60e50513          	addi	a0,a0,1550 # 80011830 <cons>
    8000022a:	00001097          	auipc	ra,0x1
    8000022e:	aea080e7          	jalr	-1302(ra) # 80000d14 <release>

  return target - n;
    80000232:	414b853b          	subw	a0,s7,s4
    80000236:	a811                	j	8000024a <consoleread+0xe8>
        release(&cons.lock);
    80000238:	00011517          	auipc	a0,0x11
    8000023c:	5f850513          	addi	a0,a0,1528 # 80011830 <cons>
    80000240:	00001097          	auipc	ra,0x1
    80000244:	ad4080e7          	jalr	-1324(ra) # 80000d14 <release>
        return -1;
    80000248:	557d                	li	a0,-1
}
    8000024a:	70e6                	ld	ra,120(sp)
    8000024c:	7446                	ld	s0,112(sp)
    8000024e:	74a6                	ld	s1,104(sp)
    80000250:	7906                	ld	s2,96(sp)
    80000252:	69e6                	ld	s3,88(sp)
    80000254:	6a46                	ld	s4,80(sp)
    80000256:	6aa6                	ld	s5,72(sp)
    80000258:	6b06                	ld	s6,64(sp)
    8000025a:	7be2                	ld	s7,56(sp)
    8000025c:	7c42                	ld	s8,48(sp)
    8000025e:	7ca2                	ld	s9,40(sp)
    80000260:	7d02                	ld	s10,32(sp)
    80000262:	6de2                	ld	s11,24(sp)
    80000264:	6109                	addi	sp,sp,128
    80000266:	8082                	ret
      if(n < target){
    80000268:	000a071b          	sext.w	a4,s4
    8000026c:	fb777be3          	bgeu	a4,s7,80000222 <consoleread+0xc0>
        cons.r--;
    80000270:	00011717          	auipc	a4,0x11
    80000274:	64f72c23          	sw	a5,1624(a4) # 800118c8 <cons+0x98>
    80000278:	b76d                	j	80000222 <consoleread+0xc0>

000000008000027a <consputc>:
{
    8000027a:	1141                	addi	sp,sp,-16
    8000027c:	e406                	sd	ra,8(sp)
    8000027e:	e022                	sd	s0,0(sp)
    80000280:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000282:	10000793          	li	a5,256
    80000286:	00f50a63          	beq	a0,a5,8000029a <consputc+0x20>
    uartputc_sync(c);
    8000028a:	00000097          	auipc	ra,0x0
    8000028e:	5c0080e7          	jalr	1472(ra) # 8000084a <uartputc_sync>
}
    80000292:	60a2                	ld	ra,8(sp)
    80000294:	6402                	ld	s0,0(sp)
    80000296:	0141                	addi	sp,sp,16
    80000298:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029a:	4521                	li	a0,8
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	5ae080e7          	jalr	1454(ra) # 8000084a <uartputc_sync>
    800002a4:	02000513          	li	a0,32
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5a2080e7          	jalr	1442(ra) # 8000084a <uartputc_sync>
    800002b0:	4521                	li	a0,8
    800002b2:	00000097          	auipc	ra,0x0
    800002b6:	598080e7          	jalr	1432(ra) # 8000084a <uartputc_sync>
    800002ba:	bfe1                	j	80000292 <consputc+0x18>

00000000800002bc <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002bc:	1101                	addi	sp,sp,-32
    800002be:	ec06                	sd	ra,24(sp)
    800002c0:	e822                	sd	s0,16(sp)
    800002c2:	e426                	sd	s1,8(sp)
    800002c4:	e04a                	sd	s2,0(sp)
    800002c6:	1000                	addi	s0,sp,32
    800002c8:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002ca:	00011517          	auipc	a0,0x11
    800002ce:	56650513          	addi	a0,a0,1382 # 80011830 <cons>
    800002d2:	00001097          	auipc	ra,0x1
    800002d6:	98e080e7          	jalr	-1650(ra) # 80000c60 <acquire>

  switch(c){
    800002da:	47d5                	li	a5,21
    800002dc:	0af48663          	beq	s1,a5,80000388 <consoleintr+0xcc>
    800002e0:	0297ca63          	blt	a5,s1,80000314 <consoleintr+0x58>
    800002e4:	47a1                	li	a5,8
    800002e6:	0ef48763          	beq	s1,a5,800003d4 <consoleintr+0x118>
    800002ea:	47c1                	li	a5,16
    800002ec:	10f49a63          	bne	s1,a5,80000400 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f0:	00002097          	auipc	ra,0x2
    800002f4:	312080e7          	jalr	786(ra) # 80002602 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002f8:	00011517          	auipc	a0,0x11
    800002fc:	53850513          	addi	a0,a0,1336 # 80011830 <cons>
    80000300:	00001097          	auipc	ra,0x1
    80000304:	a14080e7          	jalr	-1516(ra) # 80000d14 <release>
}
    80000308:	60e2                	ld	ra,24(sp)
    8000030a:	6442                	ld	s0,16(sp)
    8000030c:	64a2                	ld	s1,8(sp)
    8000030e:	6902                	ld	s2,0(sp)
    80000310:	6105                	addi	sp,sp,32
    80000312:	8082                	ret
  switch(c){
    80000314:	07f00793          	li	a5,127
    80000318:	0af48e63          	beq	s1,a5,800003d4 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031c:	00011717          	auipc	a4,0x11
    80000320:	51470713          	addi	a4,a4,1300 # 80011830 <cons>
    80000324:	0a072783          	lw	a5,160(a4)
    80000328:	09872703          	lw	a4,152(a4)
    8000032c:	9f99                	subw	a5,a5,a4
    8000032e:	07f00713          	li	a4,127
    80000332:	fcf763e3          	bltu	a4,a5,800002f8 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000336:	47b5                	li	a5,13
    80000338:	0cf48763          	beq	s1,a5,80000406 <consoleintr+0x14a>
      consputc(c);
    8000033c:	8526                	mv	a0,s1
    8000033e:	00000097          	auipc	ra,0x0
    80000342:	f3c080e7          	jalr	-196(ra) # 8000027a <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000346:	00011797          	auipc	a5,0x11
    8000034a:	4ea78793          	addi	a5,a5,1258 # 80011830 <cons>
    8000034e:	0a07a703          	lw	a4,160(a5)
    80000352:	0017069b          	addiw	a3,a4,1
    80000356:	0006861b          	sext.w	a2,a3
    8000035a:	0ad7a023          	sw	a3,160(a5)
    8000035e:	07f77713          	andi	a4,a4,127
    80000362:	97ba                	add	a5,a5,a4
    80000364:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000368:	47a9                	li	a5,10
    8000036a:	0cf48563          	beq	s1,a5,80000434 <consoleintr+0x178>
    8000036e:	4791                	li	a5,4
    80000370:	0cf48263          	beq	s1,a5,80000434 <consoleintr+0x178>
    80000374:	00011797          	auipc	a5,0x11
    80000378:	5547a783          	lw	a5,1364(a5) # 800118c8 <cons+0x98>
    8000037c:	0807879b          	addiw	a5,a5,128
    80000380:	f6f61ce3          	bne	a2,a5,800002f8 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000384:	863e                	mv	a2,a5
    80000386:	a07d                	j	80000434 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000388:	00011717          	auipc	a4,0x11
    8000038c:	4a870713          	addi	a4,a4,1192 # 80011830 <cons>
    80000390:	0a072783          	lw	a5,160(a4)
    80000394:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000398:	00011497          	auipc	s1,0x11
    8000039c:	49848493          	addi	s1,s1,1176 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003a0:	4929                	li	s2,10
    800003a2:	f4f70be3          	beq	a4,a5,800002f8 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a6:	37fd                	addiw	a5,a5,-1
    800003a8:	07f7f713          	andi	a4,a5,127
    800003ac:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ae:	01874703          	lbu	a4,24(a4)
    800003b2:	f52703e3          	beq	a4,s2,800002f8 <consoleintr+0x3c>
      cons.e--;
    800003b6:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ba:	10000513          	li	a0,256
    800003be:	00000097          	auipc	ra,0x0
    800003c2:	ebc080e7          	jalr	-324(ra) # 8000027a <consputc>
    while(cons.e != cons.w &&
    800003c6:	0a04a783          	lw	a5,160(s1)
    800003ca:	09c4a703          	lw	a4,156(s1)
    800003ce:	fcf71ce3          	bne	a4,a5,800003a6 <consoleintr+0xea>
    800003d2:	b71d                	j	800002f8 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d4:	00011717          	auipc	a4,0x11
    800003d8:	45c70713          	addi	a4,a4,1116 # 80011830 <cons>
    800003dc:	0a072783          	lw	a5,160(a4)
    800003e0:	09c72703          	lw	a4,156(a4)
    800003e4:	f0f70ae3          	beq	a4,a5,800002f8 <consoleintr+0x3c>
      cons.e--;
    800003e8:	37fd                	addiw	a5,a5,-1
    800003ea:	00011717          	auipc	a4,0x11
    800003ee:	4ef72323          	sw	a5,1254(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f2:	10000513          	li	a0,256
    800003f6:	00000097          	auipc	ra,0x0
    800003fa:	e84080e7          	jalr	-380(ra) # 8000027a <consputc>
    800003fe:	bded                	j	800002f8 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000400:	ee048ce3          	beqz	s1,800002f8 <consoleintr+0x3c>
    80000404:	bf21                	j	8000031c <consoleintr+0x60>
      consputc(c);
    80000406:	4529                	li	a0,10
    80000408:	00000097          	auipc	ra,0x0
    8000040c:	e72080e7          	jalr	-398(ra) # 8000027a <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000410:	00011797          	auipc	a5,0x11
    80000414:	42078793          	addi	a5,a5,1056 # 80011830 <cons>
    80000418:	0a07a703          	lw	a4,160(a5)
    8000041c:	0017069b          	addiw	a3,a4,1
    80000420:	0006861b          	sext.w	a2,a3
    80000424:	0ad7a023          	sw	a3,160(a5)
    80000428:	07f77713          	andi	a4,a4,127
    8000042c:	97ba                	add	a5,a5,a4
    8000042e:	4729                	li	a4,10
    80000430:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000434:	00011797          	auipc	a5,0x11
    80000438:	48c7ac23          	sw	a2,1176(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    8000043c:	00011517          	auipc	a0,0x11
    80000440:	48c50513          	addi	a0,a0,1164 # 800118c8 <cons+0x98>
    80000444:	00002097          	auipc	ra,0x2
    80000448:	036080e7          	jalr	54(ra) # 8000247a <wakeup>
    8000044c:	b575                	j	800002f8 <consoleintr+0x3c>

000000008000044e <consoleinit>:

void
consoleinit(void)
{
    8000044e:	1141                	addi	sp,sp,-16
    80000450:	e406                	sd	ra,8(sp)
    80000452:	e022                	sd	s0,0(sp)
    80000454:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000456:	00008597          	auipc	a1,0x8
    8000045a:	bba58593          	addi	a1,a1,-1094 # 80008010 <etext+0x10>
    8000045e:	00011517          	auipc	a0,0x11
    80000462:	3d250513          	addi	a0,a0,978 # 80011830 <cons>
    80000466:	00000097          	auipc	ra,0x0
    8000046a:	76a080e7          	jalr	1898(ra) # 80000bd0 <initlock>

  uartinit();
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	38c080e7          	jalr	908(ra) # 800007fa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000476:	00022797          	auipc	a5,0x22
    8000047a:	f3a78793          	addi	a5,a5,-198 # 800223b0 <devsw>
    8000047e:	00000717          	auipc	a4,0x0
    80000482:	ce470713          	addi	a4,a4,-796 # 80000162 <consoleread>
    80000486:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000488:	00000717          	auipc	a4,0x0
    8000048c:	c5870713          	addi	a4,a4,-936 # 800000e0 <consolewrite>
    80000490:	ef98                	sd	a4,24(a5)
}
    80000492:	60a2                	ld	ra,8(sp)
    80000494:	6402                	ld	s0,0(sp)
    80000496:	0141                	addi	sp,sp,16
    80000498:	8082                	ret

000000008000049a <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049a:	7179                	addi	sp,sp,-48
    8000049c:	f406                	sd	ra,40(sp)
    8000049e:	f022                	sd	s0,32(sp)
    800004a0:	ec26                	sd	s1,24(sp)
    800004a2:	e84a                	sd	s2,16(sp)
    800004a4:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a6:	c219                	beqz	a2,800004ac <printint+0x12>
    800004a8:	08054663          	bltz	a0,80000534 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ac:	2501                	sext.w	a0,a0
    800004ae:	4881                	li	a7,0
    800004b0:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b4:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b6:	2581                	sext.w	a1,a1
    800004b8:	00008617          	auipc	a2,0x8
    800004bc:	b9060613          	addi	a2,a2,-1136 # 80008048 <digits>
    800004c0:	883a                	mv	a6,a4
    800004c2:	2705                	addiw	a4,a4,1
    800004c4:	02b577bb          	remuw	a5,a0,a1
    800004c8:	1782                	slli	a5,a5,0x20
    800004ca:	9381                	srli	a5,a5,0x20
    800004cc:	97b2                	add	a5,a5,a2
    800004ce:	0007c783          	lbu	a5,0(a5)
    800004d2:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d6:	0005079b          	sext.w	a5,a0
    800004da:	02b5553b          	divuw	a0,a0,a1
    800004de:	0685                	addi	a3,a3,1
    800004e0:	feb7f0e3          	bgeu	a5,a1,800004c0 <printint+0x26>

  if(sign)
    800004e4:	00088b63          	beqz	a7,800004fa <printint+0x60>
    buf[i++] = '-';
    800004e8:	fe040793          	addi	a5,s0,-32
    800004ec:	973e                	add	a4,a4,a5
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x8e>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d60080e7          	jalr	-672(ra) # 8000027a <consputc>
  while(--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7c>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
    x = -xx;
    80000534:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
    x = -xx;
    8000053a:	bf9d                	j	800004b0 <printint+0x16>

000000008000053c <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053c:	1101                	addi	sp,sp,-32
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000548:	00011797          	auipc	a5,0x11
    8000054c:	3a07a423          	sw	zero,936(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000550:	00008517          	auipc	a0,0x8
    80000554:	ac850513          	addi	a0,a0,-1336 # 80008018 <etext+0x18>
    80000558:	00000097          	auipc	ra,0x0
    8000055c:	02e080e7          	jalr	46(ra) # 80000586 <printf>
  printf(s);
    80000560:	8526                	mv	a0,s1
    80000562:	00000097          	auipc	ra,0x0
    80000566:	024080e7          	jalr	36(ra) # 80000586 <printf>
  printf("\n");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	b6650513          	addi	a0,a0,-1178 # 800080d0 <digits+0x88>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	014080e7          	jalr	20(ra) # 80000586 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057a:	4785                	li	a5,1
    8000057c:	00009717          	auipc	a4,0x9
    80000580:	a8f72223          	sw	a5,-1404(a4) # 80009000 <panicked>
  for(;;)
    80000584:	a001                	j	80000584 <panic+0x48>

0000000080000586 <printf>:
{
    80000586:	7131                	addi	sp,sp,-192
    80000588:	fc86                	sd	ra,120(sp)
    8000058a:	f8a2                	sd	s0,112(sp)
    8000058c:	f4a6                	sd	s1,104(sp)
    8000058e:	f0ca                	sd	s2,96(sp)
    80000590:	ecce                	sd	s3,88(sp)
    80000592:	e8d2                	sd	s4,80(sp)
    80000594:	e4d6                	sd	s5,72(sp)
    80000596:	e0da                	sd	s6,64(sp)
    80000598:	fc5e                	sd	s7,56(sp)
    8000059a:	f862                	sd	s8,48(sp)
    8000059c:	f466                	sd	s9,40(sp)
    8000059e:	f06a                	sd	s10,32(sp)
    800005a0:	ec6e                	sd	s11,24(sp)
    800005a2:	0100                	addi	s0,sp,128
    800005a4:	8a2a                	mv	s4,a0
    800005a6:	e40c                	sd	a1,8(s0)
    800005a8:	e810                	sd	a2,16(s0)
    800005aa:	ec14                	sd	a3,24(s0)
    800005ac:	f018                	sd	a4,32(s0)
    800005ae:	f41c                	sd	a5,40(s0)
    800005b0:	03043823          	sd	a6,48(s0)
    800005b4:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005b8:	00011d97          	auipc	s11,0x11
    800005bc:	338dad83          	lw	s11,824(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005c0:	020d9b63          	bnez	s11,800005f6 <printf+0x70>
  if (fmt == 0)
    800005c4:	040a0263          	beqz	s4,80000608 <printf+0x82>
  va_start(ap, fmt);
    800005c8:	00840793          	addi	a5,s0,8
    800005cc:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d0:	000a4503          	lbu	a0,0(s4)
    800005d4:	16050263          	beqz	a0,80000738 <printf+0x1b2>
    800005d8:	4481                	li	s1,0
    if(c != '%'){
    800005da:	02500a93          	li	s5,37
    switch(c){
    800005de:	07000b13          	li	s6,112
  consputc('x');
    800005e2:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e4:	00008b97          	auipc	s7,0x8
    800005e8:	a64b8b93          	addi	s7,s7,-1436 # 80008048 <digits>
    switch(c){
    800005ec:	07300c93          	li	s9,115
    800005f0:	06400c13          	li	s8,100
    800005f4:	a82d                	j	8000062e <printf+0xa8>
    acquire(&pr.lock);
    800005f6:	00011517          	auipc	a0,0x11
    800005fa:	2e250513          	addi	a0,a0,738 # 800118d8 <pr>
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	662080e7          	jalr	1634(ra) # 80000c60 <acquire>
    80000606:	bf7d                	j	800005c4 <printf+0x3e>
    panic("null fmt");
    80000608:	00008517          	auipc	a0,0x8
    8000060c:	a2050513          	addi	a0,a0,-1504 # 80008028 <etext+0x28>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	f2c080e7          	jalr	-212(ra) # 8000053c <panic>
      consputc(c);
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	c62080e7          	jalr	-926(ra) # 8000027a <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000620:	2485                	addiw	s1,s1,1
    80000622:	009a07b3          	add	a5,s4,s1
    80000626:	0007c503          	lbu	a0,0(a5)
    8000062a:	10050763          	beqz	a0,80000738 <printf+0x1b2>
    if(c != '%'){
    8000062e:	ff5515e3          	bne	a0,s5,80000618 <printf+0x92>
    c = fmt[++i] & 0xff;
    80000632:	2485                	addiw	s1,s1,1
    80000634:	009a07b3          	add	a5,s4,s1
    80000638:	0007c783          	lbu	a5,0(a5)
    8000063c:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000640:	cfe5                	beqz	a5,80000738 <printf+0x1b2>
    switch(c){
    80000642:	05678a63          	beq	a5,s6,80000696 <printf+0x110>
    80000646:	02fb7663          	bgeu	s6,a5,80000672 <printf+0xec>
    8000064a:	09978963          	beq	a5,s9,800006dc <printf+0x156>
    8000064e:	07800713          	li	a4,120
    80000652:	0ce79863          	bne	a5,a4,80000722 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000656:	f8843783          	ld	a5,-120(s0)
    8000065a:	00878713          	addi	a4,a5,8
    8000065e:	f8e43423          	sd	a4,-120(s0)
    80000662:	4605                	li	a2,1
    80000664:	85ea                	mv	a1,s10
    80000666:	4388                	lw	a0,0(a5)
    80000668:	00000097          	auipc	ra,0x0
    8000066c:	e32080e7          	jalr	-462(ra) # 8000049a <printint>
      break;
    80000670:	bf45                	j	80000620 <printf+0x9a>
    switch(c){
    80000672:	0b578263          	beq	a5,s5,80000716 <printf+0x190>
    80000676:	0b879663          	bne	a5,s8,80000722 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4605                	li	a2,1
    80000688:	45a9                	li	a1,10
    8000068a:	4388                	lw	a0,0(a5)
    8000068c:	00000097          	auipc	ra,0x0
    80000690:	e0e080e7          	jalr	-498(ra) # 8000049a <printint>
      break;
    80000694:	b771                	j	80000620 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a6:	03000513          	li	a0,48
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bd0080e7          	jalr	-1072(ra) # 8000027a <consputc>
  consputc('x');
    800006b2:	07800513          	li	a0,120
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bc4080e7          	jalr	-1084(ra) # 8000027a <consputc>
    800006be:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c0:	03c9d793          	srli	a5,s3,0x3c
    800006c4:	97de                	add	a5,a5,s7
    800006c6:	0007c503          	lbu	a0,0(a5)
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bb0080e7          	jalr	-1104(ra) # 8000027a <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d2:	0992                	slli	s3,s3,0x4
    800006d4:	397d                	addiw	s2,s2,-1
    800006d6:	fe0915e3          	bnez	s2,800006c0 <printf+0x13a>
    800006da:	b799                	j	80000620 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	0007b903          	ld	s2,0(a5)
    800006ec:	00090e63          	beqz	s2,80000708 <printf+0x182>
      for(; *s; s++)
    800006f0:	00094503          	lbu	a0,0(s2)
    800006f4:	d515                	beqz	a0,80000620 <printf+0x9a>
        consputc(*s);
    800006f6:	00000097          	auipc	ra,0x0
    800006fa:	b84080e7          	jalr	-1148(ra) # 8000027a <consputc>
      for(; *s; s++)
    800006fe:	0905                	addi	s2,s2,1
    80000700:	00094503          	lbu	a0,0(s2)
    80000704:	f96d                	bnez	a0,800006f6 <printf+0x170>
    80000706:	bf29                	j	80000620 <printf+0x9a>
        s = "(null)";
    80000708:	00008917          	auipc	s2,0x8
    8000070c:	91890913          	addi	s2,s2,-1768 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000710:	02800513          	li	a0,40
    80000714:	b7cd                	j	800006f6 <printf+0x170>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b62080e7          	jalr	-1182(ra) # 8000027a <consputc>
      break;
    80000720:	b701                	j	80000620 <printf+0x9a>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b56080e7          	jalr	-1194(ra) # 8000027a <consputc>
      consputc(c);
    8000072c:	854a                	mv	a0,s2
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b4c080e7          	jalr	-1204(ra) # 8000027a <consputc>
      break;
    80000736:	b5ed                	j	80000620 <printf+0x9a>
  if(locking)
    80000738:	020d9163          	bnez	s11,8000075a <printf+0x1d4>
}
    8000073c:	70e6                	ld	ra,120(sp)
    8000073e:	7446                	ld	s0,112(sp)
    80000740:	74a6                	ld	s1,104(sp)
    80000742:	7906                	ld	s2,96(sp)
    80000744:	69e6                	ld	s3,88(sp)
    80000746:	6a46                	ld	s4,80(sp)
    80000748:	6aa6                	ld	s5,72(sp)
    8000074a:	6b06                	ld	s6,64(sp)
    8000074c:	7be2                	ld	s7,56(sp)
    8000074e:	7c42                	ld	s8,48(sp)
    80000750:	7ca2                	ld	s9,40(sp)
    80000752:	7d02                	ld	s10,32(sp)
    80000754:	6de2                	ld	s11,24(sp)
    80000756:	6129                	addi	sp,sp,192
    80000758:	8082                	ret
    release(&pr.lock);
    8000075a:	00011517          	auipc	a0,0x11
    8000075e:	17e50513          	addi	a0,a0,382 # 800118d8 <pr>
    80000762:	00000097          	auipc	ra,0x0
    80000766:	5b2080e7          	jalr	1458(ra) # 80000d14 <release>
}
    8000076a:	bfc9                	j	8000073c <printf+0x1b6>

000000008000076c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076c:	1101                	addi	sp,sp,-32
    8000076e:	ec06                	sd	ra,24(sp)
    80000770:	e822                	sd	s0,16(sp)
    80000772:	e426                	sd	s1,8(sp)
    80000774:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000776:	00011497          	auipc	s1,0x11
    8000077a:	16248493          	addi	s1,s1,354 # 800118d8 <pr>
    8000077e:	00008597          	auipc	a1,0x8
    80000782:	8ba58593          	addi	a1,a1,-1862 # 80008038 <etext+0x38>
    80000786:	8526                	mv	a0,s1
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	448080e7          	jalr	1096(ra) # 80000bd0 <initlock>
  pr.locking = 1;
    80000790:	4785                	li	a5,1
    80000792:	cc9c                	sw	a5,24(s1)
}
    80000794:	60e2                	ld	ra,24(sp)
    80000796:	6442                	ld	s0,16(sp)
    80000798:	64a2                	ld	s1,8(sp)
    8000079a:	6105                	addi	sp,sp,32
    8000079c:	8082                	ret

000000008000079e <backtrace>:

void backtrace() {
    8000079e:	7179                	addi	sp,sp,-48
    800007a0:	f406                	sd	ra,40(sp)
    800007a2:	f022                	sd	s0,32(sp)
    800007a4:	ec26                	sd	s1,24(sp)
    800007a6:	e84a                	sd	s2,16(sp)
    800007a8:	e44e                	sd	s3,8(sp)
    800007aa:	e052                	sd	s4,0(sp)
    800007ac:	1800                	addi	s0,sp,48
  asm volatile("mv %0, s0" : "=r" (x));
    800007ae:	84a2                	mv	s1,s0
  uint64 fp = r_fp();
  while(fp != PGROUNDUP(fp)) { // 如果已经到达栈底
    800007b0:	6785                	lui	a5,0x1
    800007b2:	17fd                	addi	a5,a5,-1
    800007b4:	97a6                	add	a5,a5,s1
    800007b6:	777d                	lui	a4,0xfffff
    800007b8:	8ff9                	and	a5,a5,a4
    800007ba:	02f48863          	beq	s1,a5,800007ea <backtrace+0x4c>
    uint64 ra = *(uint64*)(fp - 8); // return address
    printf("%p\n", ra);
    800007be:	00008a17          	auipc	s4,0x8
    800007c2:	882a0a13          	addi	s4,s4,-1918 # 80008040 <etext+0x40>
  while(fp != PGROUNDUP(fp)) { // 如果已经到达栈底
    800007c6:	6905                	lui	s2,0x1
    800007c8:	197d                	addi	s2,s2,-1
    800007ca:	79fd                	lui	s3,0xfffff
    printf("%p\n", ra);
    800007cc:	ff84b583          	ld	a1,-8(s1)
    800007d0:	8552                	mv	a0,s4
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	db4080e7          	jalr	-588(ra) # 80000586 <printf>
    fp = *(uint64*)(fp - 16); // previous fp
    800007da:	ff04b483          	ld	s1,-16(s1)
  while(fp != PGROUNDUP(fp)) { // 如果已经到达栈底
    800007de:	012487b3          	add	a5,s1,s2
    800007e2:	0137f7b3          	and	a5,a5,s3
    800007e6:	fe9793e3          	bne	a5,s1,800007cc <backtrace+0x2e>
  }
    800007ea:	70a2                	ld	ra,40(sp)
    800007ec:	7402                	ld	s0,32(sp)
    800007ee:	64e2                	ld	s1,24(sp)
    800007f0:	6942                	ld	s2,16(sp)
    800007f2:	69a2                	ld	s3,8(sp)
    800007f4:	6a02                	ld	s4,0(sp)
    800007f6:	6145                	addi	sp,sp,48
    800007f8:	8082                	ret

00000000800007fa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007fa:	1141                	addi	sp,sp,-16
    800007fc:	e406                	sd	ra,8(sp)
    800007fe:	e022                	sd	s0,0(sp)
    80000800:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000802:	100007b7          	lui	a5,0x10000
    80000806:	000780a3          	sb	zero,1(a5) # 10000001 <spin-0x70000019>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000080a:	f8000713          	li	a4,-128
    8000080e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000812:	470d                	li	a4,3
    80000814:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000818:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000081c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000820:	469d                	li	a3,7
    80000822:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000826:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000082a:	00008597          	auipc	a1,0x8
    8000082e:	83658593          	addi	a1,a1,-1994 # 80008060 <digits+0x18>
    80000832:	00011517          	auipc	a0,0x11
    80000836:	0c650513          	addi	a0,a0,198 # 800118f8 <uart_tx_lock>
    8000083a:	00000097          	auipc	ra,0x0
    8000083e:	396080e7          	jalr	918(ra) # 80000bd0 <initlock>
}
    80000842:	60a2                	ld	ra,8(sp)
    80000844:	6402                	ld	s0,0(sp)
    80000846:	0141                	addi	sp,sp,16
    80000848:	8082                	ret

000000008000084a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000084a:	1101                	addi	sp,sp,-32
    8000084c:	ec06                	sd	ra,24(sp)
    8000084e:	e822                	sd	s0,16(sp)
    80000850:	e426                	sd	s1,8(sp)
    80000852:	1000                	addi	s0,sp,32
    80000854:	84aa                	mv	s1,a0
  push_off();
    80000856:	00000097          	auipc	ra,0x0
    8000085a:	3be080e7          	jalr	958(ra) # 80000c14 <push_off>

  if(panicked){
    8000085e:	00008797          	auipc	a5,0x8
    80000862:	7a27a783          	lw	a5,1954(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000866:	10000737          	lui	a4,0x10000
  if(panicked){
    8000086a:	c391                	beqz	a5,8000086e <uartputc_sync+0x24>
    for(;;)
    8000086c:	a001                	j	8000086c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000086e:	00574783          	lbu	a5,5(a4) # 10000005 <spin-0x70000015>
    80000872:	0ff7f793          	andi	a5,a5,255
    80000876:	0207f793          	andi	a5,a5,32
    8000087a:	dbf5                	beqz	a5,8000086e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000087c:	0ff4f793          	andi	a5,s1,255
    80000880:	10000737          	lui	a4,0x10000
    80000884:	00f70023          	sb	a5,0(a4) # 10000000 <spin-0x7000001a>

  pop_off();
    80000888:	00000097          	auipc	ra,0x0
    8000088c:	42c080e7          	jalr	1068(ra) # 80000cb4 <pop_off>
}
    80000890:	60e2                	ld	ra,24(sp)
    80000892:	6442                	ld	s0,16(sp)
    80000894:	64a2                	ld	s1,8(sp)
    80000896:	6105                	addi	sp,sp,32
    80000898:	8082                	ret

000000008000089a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000089a:	00008797          	auipc	a5,0x8
    8000089e:	76a7a783          	lw	a5,1898(a5) # 80009004 <uart_tx_r>
    800008a2:	00008717          	auipc	a4,0x8
    800008a6:	76672703          	lw	a4,1894(a4) # 80009008 <uart_tx_w>
    800008aa:	08f70263          	beq	a4,a5,8000092e <uartstart+0x94>
{
    800008ae:	7139                	addi	sp,sp,-64
    800008b0:	fc06                	sd	ra,56(sp)
    800008b2:	f822                	sd	s0,48(sp)
    800008b4:	f426                	sd	s1,40(sp)
    800008b6:	f04a                	sd	s2,32(sp)
    800008b8:	ec4e                	sd	s3,24(sp)
    800008ba:	e852                	sd	s4,16(sp)
    800008bc:	e456                	sd	s5,8(sp)
    800008be:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008c0:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008c4:	00011a17          	auipc	s4,0x11
    800008c8:	034a0a13          	addi	s4,s4,52 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008cc:	00008497          	auipc	s1,0x8
    800008d0:	73848493          	addi	s1,s1,1848 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008d4:	00008997          	auipc	s3,0x8
    800008d8:	73498993          	addi	s3,s3,1844 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008dc:	00594703          	lbu	a4,5(s2) # 10000005 <spin-0x70000015>
    800008e0:	0ff77713          	andi	a4,a4,255
    800008e4:	02077713          	andi	a4,a4,32
    800008e8:	cb15                	beqz	a4,8000091c <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008ea:	00fa0733          	add	a4,s4,a5
    800008ee:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008f2:	2785                	addiw	a5,a5,1
    800008f4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008f8:	01b7571b          	srliw	a4,a4,0x1b
    800008fc:	9fb9                	addw	a5,a5,a4
    800008fe:	8bfd                	andi	a5,a5,31
    80000900:	9f99                	subw	a5,a5,a4
    80000902:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000904:	8526                	mv	a0,s1
    80000906:	00002097          	auipc	ra,0x2
    8000090a:	b74080e7          	jalr	-1164(ra) # 8000247a <wakeup>
    
    WriteReg(THR, c);
    8000090e:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000912:	409c                	lw	a5,0(s1)
    80000914:	0009a703          	lw	a4,0(s3)
    80000918:	fcf712e3          	bne	a4,a5,800008dc <uartstart+0x42>
  }
}
    8000091c:	70e2                	ld	ra,56(sp)
    8000091e:	7442                	ld	s0,48(sp)
    80000920:	74a2                	ld	s1,40(sp)
    80000922:	7902                	ld	s2,32(sp)
    80000924:	69e2                	ld	s3,24(sp)
    80000926:	6a42                	ld	s4,16(sp)
    80000928:	6aa2                	ld	s5,8(sp)
    8000092a:	6121                	addi	sp,sp,64
    8000092c:	8082                	ret
    8000092e:	8082                	ret

0000000080000930 <uartputc>:
{
    80000930:	7179                	addi	sp,sp,-48
    80000932:	f406                	sd	ra,40(sp)
    80000934:	f022                	sd	s0,32(sp)
    80000936:	ec26                	sd	s1,24(sp)
    80000938:	e84a                	sd	s2,16(sp)
    8000093a:	e44e                	sd	s3,8(sp)
    8000093c:	e052                	sd	s4,0(sp)
    8000093e:	1800                	addi	s0,sp,48
    80000940:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000942:	00011517          	auipc	a0,0x11
    80000946:	fb650513          	addi	a0,a0,-74 # 800118f8 <uart_tx_lock>
    8000094a:	00000097          	auipc	ra,0x0
    8000094e:	316080e7          	jalr	790(ra) # 80000c60 <acquire>
  if(panicked){
    80000952:	00008797          	auipc	a5,0x8
    80000956:	6ae7a783          	lw	a5,1710(a5) # 80009000 <panicked>
    8000095a:	c391                	beqz	a5,8000095e <uartputc+0x2e>
    for(;;)
    8000095c:	a001                	j	8000095c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000095e:	00008717          	auipc	a4,0x8
    80000962:	6aa72703          	lw	a4,1706(a4) # 80009008 <uart_tx_w>
    80000966:	0017079b          	addiw	a5,a4,1
    8000096a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096e:	01b6d69b          	srliw	a3,a3,0x1b
    80000972:	9fb5                	addw	a5,a5,a3
    80000974:	8bfd                	andi	a5,a5,31
    80000976:	9f95                	subw	a5,a5,a3
    80000978:	00008697          	auipc	a3,0x8
    8000097c:	68c6a683          	lw	a3,1676(a3) # 80009004 <uart_tx_r>
    80000980:	04f69263          	bne	a3,a5,800009c4 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000984:	00011a17          	auipc	s4,0x11
    80000988:	f74a0a13          	addi	s4,s4,-140 # 800118f8 <uart_tx_lock>
    8000098c:	00008497          	auipc	s1,0x8
    80000990:	67848493          	addi	s1,s1,1656 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000994:	00008917          	auipc	s2,0x8
    80000998:	67490913          	addi	s2,s2,1652 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000099c:	85d2                	mv	a1,s4
    8000099e:	8526                	mv	a0,s1
    800009a0:	00002097          	auipc	ra,0x2
    800009a4:	954080e7          	jalr	-1708(ra) # 800022f4 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a8:	00092703          	lw	a4,0(s2)
    800009ac:	0017079b          	addiw	a5,a4,1
    800009b0:	41f7d69b          	sraiw	a3,a5,0x1f
    800009b4:	01b6d69b          	srliw	a3,a3,0x1b
    800009b8:	9fb5                	addw	a5,a5,a3
    800009ba:	8bfd                	andi	a5,a5,31
    800009bc:	9f95                	subw	a5,a5,a3
    800009be:	4094                	lw	a3,0(s1)
    800009c0:	fcf68ee3          	beq	a3,a5,8000099c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009c4:	00011497          	auipc	s1,0x11
    800009c8:	f3448493          	addi	s1,s1,-204 # 800118f8 <uart_tx_lock>
    800009cc:	9726                	add	a4,a4,s1
    800009ce:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009d2:	00008717          	auipc	a4,0x8
    800009d6:	62f72b23          	sw	a5,1590(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	ec0080e7          	jalr	-320(ra) # 8000089a <uartstart>
      release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	330080e7          	jalr	816(ra) # 80000d14 <release>
}
    800009ec:	70a2                	ld	ra,40(sp)
    800009ee:	7402                	ld	s0,32(sp)
    800009f0:	64e2                	ld	s1,24(sp)
    800009f2:	6942                	ld	s2,16(sp)
    800009f4:	69a2                	ld	s3,8(sp)
    800009f6:	6a02                	ld	s4,0(sp)
    800009f8:	6145                	addi	sp,sp,48
    800009fa:	8082                	ret

00000000800009fc <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009fc:	1141                	addi	sp,sp,-16
    800009fe:	e422                	sd	s0,8(sp)
    80000a00:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a02:	100007b7          	lui	a5,0x10000
    80000a06:	0057c783          	lbu	a5,5(a5) # 10000005 <spin-0x70000015>
    80000a0a:	8b85                	andi	a5,a5,1
    80000a0c:	cb91                	beqz	a5,80000a20 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a0e:	100007b7          	lui	a5,0x10000
    80000a12:	0007c503          	lbu	a0,0(a5) # 10000000 <spin-0x7000001a>
    80000a16:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a1a:	6422                	ld	s0,8(sp)
    80000a1c:	0141                	addi	sp,sp,16
    80000a1e:	8082                	ret
    return -1;
    80000a20:	557d                	li	a0,-1
    80000a22:	bfe5                	j	80000a1a <uartgetc+0x1e>

0000000080000a24 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a2e:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a30:	00000097          	auipc	ra,0x0
    80000a34:	fcc080e7          	jalr	-52(ra) # 800009fc <uartgetc>
    if(c == -1)
    80000a38:	00950763          	beq	a0,s1,80000a46 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	880080e7          	jalr	-1920(ra) # 800002bc <consoleintr>
  while(1){
    80000a44:	b7f5                	j	80000a30 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a46:	00011497          	auipc	s1,0x11
    80000a4a:	eb248493          	addi	s1,s1,-334 # 800118f8 <uart_tx_lock>
    80000a4e:	8526                	mv	a0,s1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	210080e7          	jalr	528(ra) # 80000c60 <acquire>
  uartstart();
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	e42080e7          	jalr	-446(ra) # 8000089a <uartstart>
  release(&uart_tx_lock);
    80000a60:	8526                	mv	a0,s1
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	2b2080e7          	jalr	690(ra) # 80000d14 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6105                	addi	sp,sp,32
    80000a72:	8082                	ret

0000000080000a74 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a74:	1101                	addi	sp,sp,-32
    80000a76:	ec06                	sd	ra,24(sp)
    80000a78:	e822                	sd	s0,16(sp)
    80000a7a:	e426                	sd	s1,8(sp)
    80000a7c:	e04a                	sd	s2,0(sp)
    80000a7e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a80:	03451793          	slli	a5,a0,0x34
    80000a84:	ebb9                	bnez	a5,80000ada <kfree+0x66>
    80000a86:	84aa                	mv	s1,a0
    80000a88:	00026797          	auipc	a5,0x26
    80000a8c:	57878793          	addi	a5,a5,1400 # 80027000 <end>
    80000a90:	04f56563          	bltu	a0,a5,80000ada <kfree+0x66>
    80000a94:	47c5                	li	a5,17
    80000a96:	07ee                	slli	a5,a5,0x1b
    80000a98:	04f57163          	bgeu	a0,a5,80000ada <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a9c:	6605                	lui	a2,0x1
    80000a9e:	4585                	li	a1,1
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	2bc080e7          	jalr	700(ra) # 80000d5c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aa8:	00011917          	auipc	s2,0x11
    80000aac:	e8890913          	addi	s2,s2,-376 # 80011930 <kmem>
    80000ab0:	854a                	mv	a0,s2
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	1ae080e7          	jalr	430(ra) # 80000c60 <acquire>
  r->next = kmem.freelist;
    80000aba:	01893783          	ld	a5,24(s2)
    80000abe:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ac0:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ac4:	854a                	mv	a0,s2
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	24e080e7          	jalr	590(ra) # 80000d14 <release>
}
    80000ace:	60e2                	ld	ra,24(sp)
    80000ad0:	6442                	ld	s0,16(sp)
    80000ad2:	64a2                	ld	s1,8(sp)
    80000ad4:	6902                	ld	s2,0(sp)
    80000ad6:	6105                	addi	sp,sp,32
    80000ad8:	8082                	ret
    panic("kfree");
    80000ada:	00007517          	auipc	a0,0x7
    80000ade:	58e50513          	addi	a0,a0,1422 # 80008068 <digits+0x20>
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	a5a080e7          	jalr	-1446(ra) # 8000053c <panic>

0000000080000aea <freerange>:
{
    80000aea:	7179                	addi	sp,sp,-48
    80000aec:	f406                	sd	ra,40(sp)
    80000aee:	f022                	sd	s0,32(sp)
    80000af0:	ec26                	sd	s1,24(sp)
    80000af2:	e84a                	sd	s2,16(sp)
    80000af4:	e44e                	sd	s3,8(sp)
    80000af6:	e052                	sd	s4,0(sp)
    80000af8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000afa:	6785                	lui	a5,0x1
    80000afc:	fff78493          	addi	s1,a5,-1 # fff <spin-0x7ffff01b>
    80000b00:	94aa                	add	s1,s1,a0
    80000b02:	757d                	lui	a0,0xfffff
    80000b04:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94be                	add	s1,s1,a5
    80000b08:	0095ee63          	bltu	a1,s1,80000b24 <freerange+0x3a>
    80000b0c:	892e                	mv	s2,a1
    kfree(p);
    80000b0e:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b10:	6985                	lui	s3,0x1
    kfree(p);
    80000b12:	01448533          	add	a0,s1,s4
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	f5e080e7          	jalr	-162(ra) # 80000a74 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1e:	94ce                	add	s1,s1,s3
    80000b20:	fe9979e3          	bgeu	s2,s1,80000b12 <freerange+0x28>
}
    80000b24:	70a2                	ld	ra,40(sp)
    80000b26:	7402                	ld	s0,32(sp)
    80000b28:	64e2                	ld	s1,24(sp)
    80000b2a:	6942                	ld	s2,16(sp)
    80000b2c:	69a2                	ld	s3,8(sp)
    80000b2e:	6a02                	ld	s4,0(sp)
    80000b30:	6145                	addi	sp,sp,48
    80000b32:	8082                	ret

0000000080000b34 <kinit>:
{
    80000b34:	1141                	addi	sp,sp,-16
    80000b36:	e406                	sd	ra,8(sp)
    80000b38:	e022                	sd	s0,0(sp)
    80000b3a:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b3c:	00007597          	auipc	a1,0x7
    80000b40:	53458593          	addi	a1,a1,1332 # 80008070 <digits+0x28>
    80000b44:	00011517          	auipc	a0,0x11
    80000b48:	dec50513          	addi	a0,a0,-532 # 80011930 <kmem>
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	084080e7          	jalr	132(ra) # 80000bd0 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b54:	45c5                	li	a1,17
    80000b56:	05ee                	slli	a1,a1,0x1b
    80000b58:	00026517          	auipc	a0,0x26
    80000b5c:	4a850513          	addi	a0,a0,1192 # 80027000 <end>
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	f8a080e7          	jalr	-118(ra) # 80000aea <freerange>
}
    80000b68:	60a2                	ld	ra,8(sp)
    80000b6a:	6402                	ld	s0,0(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b70:	1101                	addi	sp,sp,-32
    80000b72:	ec06                	sd	ra,24(sp)
    80000b74:	e822                	sd	s0,16(sp)
    80000b76:	e426                	sd	s1,8(sp)
    80000b78:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b7a:	00011497          	auipc	s1,0x11
    80000b7e:	db648493          	addi	s1,s1,-586 # 80011930 <kmem>
    80000b82:	8526                	mv	a0,s1
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	0dc080e7          	jalr	220(ra) # 80000c60 <acquire>
  r = kmem.freelist;
    80000b8c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b8e:	c885                	beqz	s1,80000bbe <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b90:	609c                	ld	a5,0(s1)
    80000b92:	00011517          	auipc	a0,0x11
    80000b96:	d9e50513          	addi	a0,a0,-610 # 80011930 <kmem>
    80000b9a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	178080e7          	jalr	376(ra) # 80000d14 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ba4:	6605                	lui	a2,0x1
    80000ba6:	4595                	li	a1,5
    80000ba8:	8526                	mv	a0,s1
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	1b2080e7          	jalr	434(ra) # 80000d5c <memset>
  return (void*)r;
}
    80000bb2:	8526                	mv	a0,s1
    80000bb4:	60e2                	ld	ra,24(sp)
    80000bb6:	6442                	ld	s0,16(sp)
    80000bb8:	64a2                	ld	s1,8(sp)
    80000bba:	6105                	addi	sp,sp,32
    80000bbc:	8082                	ret
  release(&kmem.lock);
    80000bbe:	00011517          	auipc	a0,0x11
    80000bc2:	d7250513          	addi	a0,a0,-654 # 80011930 <kmem>
    80000bc6:	00000097          	auipc	ra,0x0
    80000bca:	14e080e7          	jalr	334(ra) # 80000d14 <release>
  if(r)
    80000bce:	b7d5                	j	80000bb2 <kalloc+0x42>

0000000080000bd0 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bd0:	1141                	addi	sp,sp,-16
    80000bd2:	e422                	sd	s0,8(sp)
    80000bd4:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd6:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bd8:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bdc:	00053823          	sd	zero,16(a0)
}
    80000be0:	6422                	ld	s0,8(sp)
    80000be2:	0141                	addi	sp,sp,16
    80000be4:	8082                	ret

0000000080000be6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be6:	411c                	lw	a5,0(a0)
    80000be8:	e399                	bnez	a5,80000bee <holding+0x8>
    80000bea:	4501                	li	a0,0
  return r;
}
    80000bec:	8082                	ret
{
    80000bee:	1101                	addi	sp,sp,-32
    80000bf0:	ec06                	sd	ra,24(sp)
    80000bf2:	e822                	sd	s0,16(sp)
    80000bf4:	e426                	sd	s1,8(sp)
    80000bf6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bf8:	6904                	ld	s1,16(a0)
    80000bfa:	00001097          	auipc	ra,0x1
    80000bfe:	e18080e7          	jalr	-488(ra) # 80001a12 <mycpu>
    80000c02:	40a48533          	sub	a0,s1,a0
    80000c06:	00153513          	seqz	a0,a0
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret

0000000080000c14 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c14:	1101                	addi	sp,sp,-32
    80000c16:	ec06                	sd	ra,24(sp)
    80000c18:	e822                	sd	s0,16(sp)
    80000c1a:	e426                	sd	s1,8(sp)
    80000c1c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100024f3          	csrr	s1,sstatus
    80000c22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c28:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c2c:	00001097          	auipc	ra,0x1
    80000c30:	de6080e7          	jalr	-538(ra) # 80001a12 <mycpu>
    80000c34:	5d3c                	lw	a5,120(a0)
    80000c36:	cf89                	beqz	a5,80000c50 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	dda080e7          	jalr	-550(ra) # 80001a12 <mycpu>
    80000c40:	5d3c                	lw	a5,120(a0)
    80000c42:	2785                	addiw	a5,a5,1
    80000c44:	dd3c                	sw	a5,120(a0)
}
    80000c46:	60e2                	ld	ra,24(sp)
    80000c48:	6442                	ld	s0,16(sp)
    80000c4a:	64a2                	ld	s1,8(sp)
    80000c4c:	6105                	addi	sp,sp,32
    80000c4e:	8082                	ret
    mycpu()->intena = old;
    80000c50:	00001097          	auipc	ra,0x1
    80000c54:	dc2080e7          	jalr	-574(ra) # 80001a12 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c58:	8085                	srli	s1,s1,0x1
    80000c5a:	8885                	andi	s1,s1,1
    80000c5c:	dd64                	sw	s1,124(a0)
    80000c5e:	bfe9                	j	80000c38 <push_off+0x24>

0000000080000c60 <acquire>:
{
    80000c60:	1101                	addi	sp,sp,-32
    80000c62:	ec06                	sd	ra,24(sp)
    80000c64:	e822                	sd	s0,16(sp)
    80000c66:	e426                	sd	s1,8(sp)
    80000c68:	1000                	addi	s0,sp,32
    80000c6a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	fa8080e7          	jalr	-88(ra) # 80000c14 <push_off>
  if(holding(lk))
    80000c74:	8526                	mv	a0,s1
    80000c76:	00000097          	auipc	ra,0x0
    80000c7a:	f70080e7          	jalr	-144(ra) # 80000be6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c7e:	4705                	li	a4,1
  if(holding(lk))
    80000c80:	e115                	bnez	a0,80000ca4 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c82:	87ba                	mv	a5,a4
    80000c84:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c88:	2781                	sext.w	a5,a5
    80000c8a:	ffe5                	bnez	a5,80000c82 <acquire+0x22>
  __sync_synchronize();
    80000c8c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c90:	00001097          	auipc	ra,0x1
    80000c94:	d82080e7          	jalr	-638(ra) # 80001a12 <mycpu>
    80000c98:	e888                	sd	a0,16(s1)
}
    80000c9a:	60e2                	ld	ra,24(sp)
    80000c9c:	6442                	ld	s0,16(sp)
    80000c9e:	64a2                	ld	s1,8(sp)
    80000ca0:	6105                	addi	sp,sp,32
    80000ca2:	8082                	ret
    panic("acquire");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x30>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	890080e7          	jalr	-1904(ra) # 8000053c <panic>

0000000080000cb4 <pop_off>:

void
pop_off(void)
{
    80000cb4:	1141                	addi	sp,sp,-16
    80000cb6:	e406                	sd	ra,8(sp)
    80000cb8:	e022                	sd	s0,0(sp)
    80000cba:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cbc:	00001097          	auipc	ra,0x1
    80000cc0:	d56080e7          	jalr	-682(ra) # 80001a12 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cc8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cca:	e78d                	bnez	a5,80000cf4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ccc:	5d3c                	lw	a5,120(a0)
    80000cce:	02f05b63          	blez	a5,80000d04 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cd2:	37fd                	addiw	a5,a5,-1
    80000cd4:	0007871b          	sext.w	a4,a5
    80000cd8:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cda:	eb09                	bnez	a4,80000cec <pop_off+0x38>
    80000cdc:	5d7c                	lw	a5,124(a0)
    80000cde:	c799                	beqz	a5,80000cec <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ce4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ce8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cec:	60a2                	ld	ra,8(sp)
    80000cee:	6402                	ld	s0,0(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret
    panic("pop_off - interruptible");
    80000cf4:	00007517          	auipc	a0,0x7
    80000cf8:	38c50513          	addi	a0,a0,908 # 80008080 <digits+0x38>
    80000cfc:	00000097          	auipc	ra,0x0
    80000d00:	840080e7          	jalr	-1984(ra) # 8000053c <panic>
    panic("pop_off");
    80000d04:	00007517          	auipc	a0,0x7
    80000d08:	39450513          	addi	a0,a0,916 # 80008098 <digits+0x50>
    80000d0c:	00000097          	auipc	ra,0x0
    80000d10:	830080e7          	jalr	-2000(ra) # 8000053c <panic>

0000000080000d14 <release>:
{
    80000d14:	1101                	addi	sp,sp,-32
    80000d16:	ec06                	sd	ra,24(sp)
    80000d18:	e822                	sd	s0,16(sp)
    80000d1a:	e426                	sd	s1,8(sp)
    80000d1c:	1000                	addi	s0,sp,32
    80000d1e:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	ec6080e7          	jalr	-314(ra) # 80000be6 <holding>
    80000d28:	c115                	beqz	a0,80000d4c <release+0x38>
  lk->cpu = 0;
    80000d2a:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d2e:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d32:	0f50000f          	fence	iorw,ow
    80000d36:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d3a:	00000097          	auipc	ra,0x0
    80000d3e:	f7a080e7          	jalr	-134(ra) # 80000cb4 <pop_off>
}
    80000d42:	60e2                	ld	ra,24(sp)
    80000d44:	6442                	ld	s0,16(sp)
    80000d46:	64a2                	ld	s1,8(sp)
    80000d48:	6105                	addi	sp,sp,32
    80000d4a:	8082                	ret
    panic("release");
    80000d4c:	00007517          	auipc	a0,0x7
    80000d50:	35450513          	addi	a0,a0,852 # 800080a0 <digits+0x58>
    80000d54:	fffff097          	auipc	ra,0xfffff
    80000d58:	7e8080e7          	jalr	2024(ra) # 8000053c <panic>

0000000080000d5c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d5c:	1141                	addi	sp,sp,-16
    80000d5e:	e422                	sd	s0,8(sp)
    80000d60:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d62:	ce09                	beqz	a2,80000d7c <memset+0x20>
    80000d64:	87aa                	mv	a5,a0
    80000d66:	fff6071b          	addiw	a4,a2,-1
    80000d6a:	1702                	slli	a4,a4,0x20
    80000d6c:	9301                	srli	a4,a4,0x20
    80000d6e:	0705                	addi	a4,a4,1
    80000d70:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d72:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d76:	0785                	addi	a5,a5,1
    80000d78:	fee79de3          	bne	a5,a4,80000d72 <memset+0x16>
  }
  return dst;
}
    80000d7c:	6422                	ld	s0,8(sp)
    80000d7e:	0141                	addi	sp,sp,16
    80000d80:	8082                	ret

0000000080000d82 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d82:	1141                	addi	sp,sp,-16
    80000d84:	e422                	sd	s0,8(sp)
    80000d86:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d88:	ca05                	beqz	a2,80000db8 <memcmp+0x36>
    80000d8a:	fff6069b          	addiw	a3,a2,-1
    80000d8e:	1682                	slli	a3,a3,0x20
    80000d90:	9281                	srli	a3,a3,0x20
    80000d92:	0685                	addi	a3,a3,1
    80000d94:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d96:	00054783          	lbu	a5,0(a0)
    80000d9a:	0005c703          	lbu	a4,0(a1)
    80000d9e:	00e79863          	bne	a5,a4,80000dae <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000da2:	0505                	addi	a0,a0,1
    80000da4:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da6:	fed518e3          	bne	a0,a3,80000d96 <memcmp+0x14>
  }

  return 0;
    80000daa:	4501                	li	a0,0
    80000dac:	a019                	j	80000db2 <memcmp+0x30>
      return *s1 - *s2;
    80000dae:	40e7853b          	subw	a0,a5,a4
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret
  return 0;
    80000db8:	4501                	li	a0,0
    80000dba:	bfe5                	j	80000db2 <memcmp+0x30>

0000000080000dbc <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dbc:	1141                	addi	sp,sp,-16
    80000dbe:	e422                	sd	s0,8(sp)
    80000dc0:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dc2:	00a5f963          	bgeu	a1,a0,80000dd4 <memmove+0x18>
    80000dc6:	02061713          	slli	a4,a2,0x20
    80000dca:	9301                	srli	a4,a4,0x20
    80000dcc:	00e587b3          	add	a5,a1,a4
    80000dd0:	02f56563          	bltu	a0,a5,80000dfa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000dd4:	fff6069b          	addiw	a3,a2,-1
    80000dd8:	ce11                	beqz	a2,80000df4 <memmove+0x38>
    80000dda:	1682                	slli	a3,a3,0x20
    80000ddc:	9281                	srli	a3,a3,0x20
    80000dde:	0685                	addi	a3,a3,1
    80000de0:	96ae                	add	a3,a3,a1
    80000de2:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000de4:	0585                	addi	a1,a1,1
    80000de6:	0785                	addi	a5,a5,1
    80000de8:	fff5c703          	lbu	a4,-1(a1)
    80000dec:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000df0:	fed59ae3          	bne	a1,a3,80000de4 <memmove+0x28>

  return dst;
}
    80000df4:	6422                	ld	s0,8(sp)
    80000df6:	0141                	addi	sp,sp,16
    80000df8:	8082                	ret
    d += n;
    80000dfa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dfc:	fff6069b          	addiw	a3,a2,-1
    80000e00:	da75                	beqz	a2,80000df4 <memmove+0x38>
    80000e02:	02069613          	slli	a2,a3,0x20
    80000e06:	9201                	srli	a2,a2,0x20
    80000e08:	fff64613          	not	a2,a2
    80000e0c:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e0e:	17fd                	addi	a5,a5,-1
    80000e10:	177d                	addi	a4,a4,-1
    80000e12:	0007c683          	lbu	a3,0(a5)
    80000e16:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e1a:	fec79ae3          	bne	a5,a2,80000e0e <memmove+0x52>
    80000e1e:	bfd9                	j	80000df4 <memmove+0x38>

0000000080000e20 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e20:	1141                	addi	sp,sp,-16
    80000e22:	e406                	sd	ra,8(sp)
    80000e24:	e022                	sd	s0,0(sp)
    80000e26:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e28:	00000097          	auipc	ra,0x0
    80000e2c:	f94080e7          	jalr	-108(ra) # 80000dbc <memmove>
}
    80000e30:	60a2                	ld	ra,8(sp)
    80000e32:	6402                	ld	s0,0(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e3e:	ce11                	beqz	a2,80000e5a <strncmp+0x22>
    80000e40:	00054783          	lbu	a5,0(a0)
    80000e44:	cf89                	beqz	a5,80000e5e <strncmp+0x26>
    80000e46:	0005c703          	lbu	a4,0(a1)
    80000e4a:	00f71a63          	bne	a4,a5,80000e5e <strncmp+0x26>
    n--, p++, q++;
    80000e4e:	367d                	addiw	a2,a2,-1
    80000e50:	0505                	addi	a0,a0,1
    80000e52:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e54:	f675                	bnez	a2,80000e40 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e56:	4501                	li	a0,0
    80000e58:	a809                	j	80000e6a <strncmp+0x32>
    80000e5a:	4501                	li	a0,0
    80000e5c:	a039                	j	80000e6a <strncmp+0x32>
  if(n == 0)
    80000e5e:	ca09                	beqz	a2,80000e70 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e60:	00054503          	lbu	a0,0(a0)
    80000e64:	0005c783          	lbu	a5,0(a1)
    80000e68:	9d1d                	subw	a0,a0,a5
}
    80000e6a:	6422                	ld	s0,8(sp)
    80000e6c:	0141                	addi	sp,sp,16
    80000e6e:	8082                	ret
    return 0;
    80000e70:	4501                	li	a0,0
    80000e72:	bfe5                	j	80000e6a <strncmp+0x32>

0000000080000e74 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e74:	1141                	addi	sp,sp,-16
    80000e76:	e422                	sd	s0,8(sp)
    80000e78:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e7a:	872a                	mv	a4,a0
    80000e7c:	8832                	mv	a6,a2
    80000e7e:	367d                	addiw	a2,a2,-1
    80000e80:	01005963          	blez	a6,80000e92 <strncpy+0x1e>
    80000e84:	0705                	addi	a4,a4,1
    80000e86:	0005c783          	lbu	a5,0(a1)
    80000e8a:	fef70fa3          	sb	a5,-1(a4)
    80000e8e:	0585                	addi	a1,a1,1
    80000e90:	f7f5                	bnez	a5,80000e7c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e92:	00c05d63          	blez	a2,80000eac <strncpy+0x38>
    80000e96:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e98:	0685                	addi	a3,a3,1
    80000e9a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e9e:	fff6c793          	not	a5,a3
    80000ea2:	9fb9                	addw	a5,a5,a4
    80000ea4:	010787bb          	addw	a5,a5,a6
    80000ea8:	fef048e3          	bgtz	a5,80000e98 <strncpy+0x24>
  return os;
}
    80000eac:	6422                	ld	s0,8(sp)
    80000eae:	0141                	addi	sp,sp,16
    80000eb0:	8082                	ret

0000000080000eb2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000eb2:	1141                	addi	sp,sp,-16
    80000eb4:	e422                	sd	s0,8(sp)
    80000eb6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000eb8:	02c05363          	blez	a2,80000ede <safestrcpy+0x2c>
    80000ebc:	fff6069b          	addiw	a3,a2,-1
    80000ec0:	1682                	slli	a3,a3,0x20
    80000ec2:	9281                	srli	a3,a3,0x20
    80000ec4:	96ae                	add	a3,a3,a1
    80000ec6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ec8:	00d58963          	beq	a1,a3,80000eda <safestrcpy+0x28>
    80000ecc:	0585                	addi	a1,a1,1
    80000ece:	0785                	addi	a5,a5,1
    80000ed0:	fff5c703          	lbu	a4,-1(a1)
    80000ed4:	fee78fa3          	sb	a4,-1(a5)
    80000ed8:	fb65                	bnez	a4,80000ec8 <safestrcpy+0x16>
    ;
  *s = 0;
    80000eda:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ede:	6422                	ld	s0,8(sp)
    80000ee0:	0141                	addi	sp,sp,16
    80000ee2:	8082                	ret

0000000080000ee4 <strlen>:

int
strlen(const char *s)
{
    80000ee4:	1141                	addi	sp,sp,-16
    80000ee6:	e422                	sd	s0,8(sp)
    80000ee8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eea:	00054783          	lbu	a5,0(a0)
    80000eee:	cf91                	beqz	a5,80000f0a <strlen+0x26>
    80000ef0:	0505                	addi	a0,a0,1
    80000ef2:	87aa                	mv	a5,a0
    80000ef4:	4685                	li	a3,1
    80000ef6:	9e89                	subw	a3,a3,a0
    80000ef8:	00f6853b          	addw	a0,a3,a5
    80000efc:	0785                	addi	a5,a5,1
    80000efe:	fff7c703          	lbu	a4,-1(a5)
    80000f02:	fb7d                	bnez	a4,80000ef8 <strlen+0x14>
    ;
  return n;
}
    80000f04:	6422                	ld	s0,8(sp)
    80000f06:	0141                	addi	sp,sp,16
    80000f08:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f0a:	4501                	li	a0,0
    80000f0c:	bfe5                	j	80000f04 <strlen+0x20>

0000000080000f0e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f0e:	1141                	addi	sp,sp,-16
    80000f10:	e406                	sd	ra,8(sp)
    80000f12:	e022                	sd	s0,0(sp)
    80000f14:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f16:	00001097          	auipc	ra,0x1
    80000f1a:	aec080e7          	jalr	-1300(ra) # 80001a02 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f1e:	00008717          	auipc	a4,0x8
    80000f22:	0ee70713          	addi	a4,a4,238 # 8000900c <started>
  if(cpuid() == 0){
    80000f26:	c139                	beqz	a0,80000f6c <main+0x5e>
    while(started == 0)
    80000f28:	431c                	lw	a5,0(a4)
    80000f2a:	2781                	sext.w	a5,a5
    80000f2c:	dff5                	beqz	a5,80000f28 <main+0x1a>
      ;
    __sync_synchronize();
    80000f2e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	ad0080e7          	jalr	-1328(ra) # 80001a02 <cpuid>
    80000f3a:	85aa                	mv	a1,a0
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	18450513          	addi	a0,a0,388 # 800080c0 <digits+0x78>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	642080e7          	jalr	1602(ra) # 80000586 <printf>
    kvminithart();    // turn on paging
    80000f4c:	00000097          	auipc	ra,0x0
    80000f50:	0d8080e7          	jalr	216(ra) # 80001024 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	7ee080e7          	jalr	2030(ra) # 80002742 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	e44080e7          	jalr	-444(ra) # 80005da0 <plicinithart>
  }

  scheduler();        
    80000f64:	00001097          	auipc	ra,0x1
    80000f68:	0b4080e7          	jalr	180(ra) # 80002018 <scheduler>
    consoleinit();
    80000f6c:	fffff097          	auipc	ra,0xfffff
    80000f70:	4e2080e7          	jalr	1250(ra) # 8000044e <consoleinit>
    printfinit();
    80000f74:	fffff097          	auipc	ra,0xfffff
    80000f78:	7f8080e7          	jalr	2040(ra) # 8000076c <printfinit>
    printf("\n");
    80000f7c:	00007517          	auipc	a0,0x7
    80000f80:	15450513          	addi	a0,a0,340 # 800080d0 <digits+0x88>
    80000f84:	fffff097          	auipc	ra,0xfffff
    80000f88:	602080e7          	jalr	1538(ra) # 80000586 <printf>
    printf("xv6 kernel is booting\n");
    80000f8c:	00007517          	auipc	a0,0x7
    80000f90:	11c50513          	addi	a0,a0,284 # 800080a8 <digits+0x60>
    80000f94:	fffff097          	auipc	ra,0xfffff
    80000f98:	5f2080e7          	jalr	1522(ra) # 80000586 <printf>
    printf("\n");
    80000f9c:	00007517          	auipc	a0,0x7
    80000fa0:	13450513          	addi	a0,a0,308 # 800080d0 <digits+0x88>
    80000fa4:	fffff097          	auipc	ra,0xfffff
    80000fa8:	5e2080e7          	jalr	1506(ra) # 80000586 <printf>
    kinit();         // physical page allocator
    80000fac:	00000097          	auipc	ra,0x0
    80000fb0:	b88080e7          	jalr	-1144(ra) # 80000b34 <kinit>
    kvminit();       // create kernel page table
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	2a0080e7          	jalr	672(ra) # 80001254 <kvminit>
    kvminithart();   // turn on paging
    80000fbc:	00000097          	auipc	ra,0x0
    80000fc0:	068080e7          	jalr	104(ra) # 80001024 <kvminithart>
    procinit();      // process table
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	96e080e7          	jalr	-1682(ra) # 80001932 <procinit>
    trapinit();      // trap vectors
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	74e080e7          	jalr	1870(ra) # 8000271a <trapinit>
    trapinithart();  // install kernel trap vector
    80000fd4:	00001097          	auipc	ra,0x1
    80000fd8:	76e080e7          	jalr	1902(ra) # 80002742 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fdc:	00005097          	auipc	ra,0x5
    80000fe0:	dae080e7          	jalr	-594(ra) # 80005d8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fe4:	00005097          	auipc	ra,0x5
    80000fe8:	dbc080e7          	jalr	-580(ra) # 80005da0 <plicinithart>
    binit();         // buffer cache
    80000fec:	00002097          	auipc	ra,0x2
    80000ff0:	f62080e7          	jalr	-158(ra) # 80002f4e <binit>
    iinit();         // inode cache
    80000ff4:	00002097          	auipc	ra,0x2
    80000ff8:	5f2080e7          	jalr	1522(ra) # 800035e6 <iinit>
    fileinit();      // file table
    80000ffc:	00003097          	auipc	ra,0x3
    80001000:	58c080e7          	jalr	1420(ra) # 80004588 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001004:	00005097          	auipc	ra,0x5
    80001008:	ea4080e7          	jalr	-348(ra) # 80005ea8 <virtio_disk_init>
    userinit();      // first user process
    8000100c:	00001097          	auipc	ra,0x1
    80001010:	d3c080e7          	jalr	-708(ra) # 80001d48 <userinit>
    __sync_synchronize();
    80001014:	0ff0000f          	fence
    started = 1;
    80001018:	4785                	li	a5,1
    8000101a:	00008717          	auipc	a4,0x8
    8000101e:	fef72923          	sw	a5,-14(a4) # 8000900c <started>
    80001022:	b789                	j	80000f64 <main+0x56>

0000000080001024 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001024:	1141                	addi	sp,sp,-16
    80001026:	e422                	sd	s0,8(sp)
    80001028:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000102a:	00008797          	auipc	a5,0x8
    8000102e:	fe67b783          	ld	a5,-26(a5) # 80009010 <kernel_pagetable>
    80001032:	83b1                	srli	a5,a5,0xc
    80001034:	577d                	li	a4,-1
    80001036:	177e                	slli	a4,a4,0x3f
    80001038:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000103a:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000103e:	12000073          	sfence.vma
  sfence_vma();
}
    80001042:	6422                	ld	s0,8(sp)
    80001044:	0141                	addi	sp,sp,16
    80001046:	8082                	ret

0000000080001048 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001048:	7139                	addi	sp,sp,-64
    8000104a:	fc06                	sd	ra,56(sp)
    8000104c:	f822                	sd	s0,48(sp)
    8000104e:	f426                	sd	s1,40(sp)
    80001050:	f04a                	sd	s2,32(sp)
    80001052:	ec4e                	sd	s3,24(sp)
    80001054:	e852                	sd	s4,16(sp)
    80001056:	e456                	sd	s5,8(sp)
    80001058:	e05a                	sd	s6,0(sp)
    8000105a:	0080                	addi	s0,sp,64
    8000105c:	84aa                	mv	s1,a0
    8000105e:	89ae                	mv	s3,a1
    80001060:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001062:	57fd                	li	a5,-1
    80001064:	83e9                	srli	a5,a5,0x1a
    80001066:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001068:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000106a:	04b7f263          	bgeu	a5,a1,800010ae <walk+0x66>
    panic("walk");
    8000106e:	00007517          	auipc	a0,0x7
    80001072:	06a50513          	addi	a0,a0,106 # 800080d8 <digits+0x90>
    80001076:	fffff097          	auipc	ra,0xfffff
    8000107a:	4c6080e7          	jalr	1222(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000107e:	060a8663          	beqz	s5,800010ea <walk+0xa2>
    80001082:	00000097          	auipc	ra,0x0
    80001086:	aee080e7          	jalr	-1298(ra) # 80000b70 <kalloc>
    8000108a:	84aa                	mv	s1,a0
    8000108c:	c529                	beqz	a0,800010d6 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000108e:	6605                	lui	a2,0x1
    80001090:	4581                	li	a1,0
    80001092:	00000097          	auipc	ra,0x0
    80001096:	cca080e7          	jalr	-822(ra) # 80000d5c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000109a:	00c4d793          	srli	a5,s1,0xc
    8000109e:	07aa                	slli	a5,a5,0xa
    800010a0:	0017e793          	ori	a5,a5,1
    800010a4:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010a8:	3a5d                	addiw	s4,s4,-9
    800010aa:	036a0063          	beq	s4,s6,800010ca <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010ae:	0149d933          	srl	s2,s3,s4
    800010b2:	1ff97913          	andi	s2,s2,511
    800010b6:	090e                	slli	s2,s2,0x3
    800010b8:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010ba:	00093483          	ld	s1,0(s2)
    800010be:	0014f793          	andi	a5,s1,1
    800010c2:	dfd5                	beqz	a5,8000107e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010c4:	80a9                	srli	s1,s1,0xa
    800010c6:	04b2                	slli	s1,s1,0xc
    800010c8:	b7c5                	j	800010a8 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010ca:	00c9d513          	srli	a0,s3,0xc
    800010ce:	1ff57513          	andi	a0,a0,511
    800010d2:	050e                	slli	a0,a0,0x3
    800010d4:	9526                	add	a0,a0,s1
}
    800010d6:	70e2                	ld	ra,56(sp)
    800010d8:	7442                	ld	s0,48(sp)
    800010da:	74a2                	ld	s1,40(sp)
    800010dc:	7902                	ld	s2,32(sp)
    800010de:	69e2                	ld	s3,24(sp)
    800010e0:	6a42                	ld	s4,16(sp)
    800010e2:	6aa2                	ld	s5,8(sp)
    800010e4:	6b02                	ld	s6,0(sp)
    800010e6:	6121                	addi	sp,sp,64
    800010e8:	8082                	ret
        return 0;
    800010ea:	4501                	li	a0,0
    800010ec:	b7ed                	j	800010d6 <walk+0x8e>

00000000800010ee <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010ee:	57fd                	li	a5,-1
    800010f0:	83e9                	srli	a5,a5,0x1a
    800010f2:	00b7f463          	bgeu	a5,a1,800010fa <walkaddr+0xc>
    return 0;
    800010f6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010f8:	8082                	ret
{
    800010fa:	1141                	addi	sp,sp,-16
    800010fc:	e406                	sd	ra,8(sp)
    800010fe:	e022                	sd	s0,0(sp)
    80001100:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001102:	4601                	li	a2,0
    80001104:	00000097          	auipc	ra,0x0
    80001108:	f44080e7          	jalr	-188(ra) # 80001048 <walk>
  if(pte == 0)
    8000110c:	c105                	beqz	a0,8000112c <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000110e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001110:	0117f693          	andi	a3,a5,17
    80001114:	4745                	li	a4,17
    return 0;
    80001116:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001118:	00e68663          	beq	a3,a4,80001124 <walkaddr+0x36>
}
    8000111c:	60a2                	ld	ra,8(sp)
    8000111e:	6402                	ld	s0,0(sp)
    80001120:	0141                	addi	sp,sp,16
    80001122:	8082                	ret
  pa = PTE2PA(*pte);
    80001124:	00a7d513          	srli	a0,a5,0xa
    80001128:	0532                	slli	a0,a0,0xc
  return pa;
    8000112a:	bfcd                	j	8000111c <walkaddr+0x2e>
    return 0;
    8000112c:	4501                	li	a0,0
    8000112e:	b7fd                	j	8000111c <walkaddr+0x2e>

0000000080001130 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001130:	1101                	addi	sp,sp,-32
    80001132:	ec06                	sd	ra,24(sp)
    80001134:	e822                	sd	s0,16(sp)
    80001136:	e426                	sd	s1,8(sp)
    80001138:	1000                	addi	s0,sp,32
    8000113a:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    8000113c:	1552                	slli	a0,a0,0x34
    8000113e:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001142:	4601                	li	a2,0
    80001144:	00008517          	auipc	a0,0x8
    80001148:	ecc53503          	ld	a0,-308(a0) # 80009010 <kernel_pagetable>
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	efc080e7          	jalr	-260(ra) # 80001048 <walk>
  if(pte == 0)
    80001154:	cd09                	beqz	a0,8000116e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001156:	6108                	ld	a0,0(a0)
    80001158:	00157793          	andi	a5,a0,1
    8000115c:	c38d                	beqz	a5,8000117e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000115e:	8129                	srli	a0,a0,0xa
    80001160:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001162:	9526                	add	a0,a0,s1
    80001164:	60e2                	ld	ra,24(sp)
    80001166:	6442                	ld	s0,16(sp)
    80001168:	64a2                	ld	s1,8(sp)
    8000116a:	6105                	addi	sp,sp,32
    8000116c:	8082                	ret
    panic("kvmpa");
    8000116e:	00007517          	auipc	a0,0x7
    80001172:	f7250513          	addi	a0,a0,-142 # 800080e0 <digits+0x98>
    80001176:	fffff097          	auipc	ra,0xfffff
    8000117a:	3c6080e7          	jalr	966(ra) # 8000053c <panic>
    panic("kvmpa");
    8000117e:	00007517          	auipc	a0,0x7
    80001182:	f6250513          	addi	a0,a0,-158 # 800080e0 <digits+0x98>
    80001186:	fffff097          	auipc	ra,0xfffff
    8000118a:	3b6080e7          	jalr	950(ra) # 8000053c <panic>

000000008000118e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000118e:	715d                	addi	sp,sp,-80
    80001190:	e486                	sd	ra,72(sp)
    80001192:	e0a2                	sd	s0,64(sp)
    80001194:	fc26                	sd	s1,56(sp)
    80001196:	f84a                	sd	s2,48(sp)
    80001198:	f44e                	sd	s3,40(sp)
    8000119a:	f052                	sd	s4,32(sp)
    8000119c:	ec56                	sd	s5,24(sp)
    8000119e:	e85a                	sd	s6,16(sp)
    800011a0:	e45e                	sd	s7,8(sp)
    800011a2:	0880                	addi	s0,sp,80
    800011a4:	8aaa                	mv	s5,a0
    800011a6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011a8:	777d                	lui	a4,0xfffff
    800011aa:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011ae:	167d                	addi	a2,a2,-1
    800011b0:	00b609b3          	add	s3,a2,a1
    800011b4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011b8:	893e                	mv	s2,a5
    800011ba:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011be:	6b85                	lui	s7,0x1
    800011c0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c4:	4605                	li	a2,1
    800011c6:	85ca                	mv	a1,s2
    800011c8:	8556                	mv	a0,s5
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	e7e080e7          	jalr	-386(ra) # 80001048 <walk>
    800011d2:	c51d                	beqz	a0,80001200 <mappages+0x72>
    if(*pte & PTE_V)
    800011d4:	611c                	ld	a5,0(a0)
    800011d6:	8b85                	andi	a5,a5,1
    800011d8:	ef81                	bnez	a5,800011f0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011da:	80b1                	srli	s1,s1,0xc
    800011dc:	04aa                	slli	s1,s1,0xa
    800011de:	0164e4b3          	or	s1,s1,s6
    800011e2:	0014e493          	ori	s1,s1,1
    800011e6:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e8:	03390863          	beq	s2,s3,80001218 <mappages+0x8a>
    a += PGSIZE;
    800011ec:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011ee:	bfc9                	j	800011c0 <mappages+0x32>
      panic("remap");
    800011f0:	00007517          	auipc	a0,0x7
    800011f4:	ef850513          	addi	a0,a0,-264 # 800080e8 <digits+0xa0>
    800011f8:	fffff097          	auipc	ra,0xfffff
    800011fc:	344080e7          	jalr	836(ra) # 8000053c <panic>
      return -1;
    80001200:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001202:	60a6                	ld	ra,72(sp)
    80001204:	6406                	ld	s0,64(sp)
    80001206:	74e2                	ld	s1,56(sp)
    80001208:	7942                	ld	s2,48(sp)
    8000120a:	79a2                	ld	s3,40(sp)
    8000120c:	7a02                	ld	s4,32(sp)
    8000120e:	6ae2                	ld	s5,24(sp)
    80001210:	6b42                	ld	s6,16(sp)
    80001212:	6ba2                	ld	s7,8(sp)
    80001214:	6161                	addi	sp,sp,80
    80001216:	8082                	ret
  return 0;
    80001218:	4501                	li	a0,0
    8000121a:	b7e5                	j	80001202 <mappages+0x74>

000000008000121c <kvmmap>:
{
    8000121c:	1141                	addi	sp,sp,-16
    8000121e:	e406                	sd	ra,8(sp)
    80001220:	e022                	sd	s0,0(sp)
    80001222:	0800                	addi	s0,sp,16
    80001224:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001226:	86ae                	mv	a3,a1
    80001228:	85aa                	mv	a1,a0
    8000122a:	00008517          	auipc	a0,0x8
    8000122e:	de653503          	ld	a0,-538(a0) # 80009010 <kernel_pagetable>
    80001232:	00000097          	auipc	ra,0x0
    80001236:	f5c080e7          	jalr	-164(ra) # 8000118e <mappages>
    8000123a:	e509                	bnez	a0,80001244 <kvmmap+0x28>
}
    8000123c:	60a2                	ld	ra,8(sp)
    8000123e:	6402                	ld	s0,0(sp)
    80001240:	0141                	addi	sp,sp,16
    80001242:	8082                	ret
    panic("kvmmap");
    80001244:	00007517          	auipc	a0,0x7
    80001248:	eac50513          	addi	a0,a0,-340 # 800080f0 <digits+0xa8>
    8000124c:	fffff097          	auipc	ra,0xfffff
    80001250:	2f0080e7          	jalr	752(ra) # 8000053c <panic>

0000000080001254 <kvminit>:
{
    80001254:	1101                	addi	sp,sp,-32
    80001256:	ec06                	sd	ra,24(sp)
    80001258:	e822                	sd	s0,16(sp)
    8000125a:	e426                	sd	s1,8(sp)
    8000125c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	912080e7          	jalr	-1774(ra) # 80000b70 <kalloc>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7b523          	sd	a0,-598(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000126e:	6605                	lui	a2,0x1
    80001270:	4581                	li	a1,0
    80001272:	00000097          	auipc	ra,0x0
    80001276:	aea080e7          	jalr	-1302(ra) # 80000d5c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000127a:	4699                	li	a3,6
    8000127c:	6605                	lui	a2,0x1
    8000127e:	100005b7          	lui	a1,0x10000
    80001282:	10000537          	lui	a0,0x10000
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f96080e7          	jalr	-106(ra) # 8000121c <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000128e:	4699                	li	a3,6
    80001290:	6605                	lui	a2,0x1
    80001292:	100015b7          	lui	a1,0x10001
    80001296:	10001537          	lui	a0,0x10001
    8000129a:	00000097          	auipc	ra,0x0
    8000129e:	f82080e7          	jalr	-126(ra) # 8000121c <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012a2:	4699                	li	a3,6
    800012a4:	6641                	lui	a2,0x10
    800012a6:	020005b7          	lui	a1,0x2000
    800012aa:	02000537          	lui	a0,0x2000
    800012ae:	00000097          	auipc	ra,0x0
    800012b2:	f6e080e7          	jalr	-146(ra) # 8000121c <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012b6:	4699                	li	a3,6
    800012b8:	00400637          	lui	a2,0x400
    800012bc:	0c0005b7          	lui	a1,0xc000
    800012c0:	0c000537          	lui	a0,0xc000
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f58080e7          	jalr	-168(ra) # 8000121c <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012cc:	00007497          	auipc	s1,0x7
    800012d0:	d3448493          	addi	s1,s1,-716 # 80008000 <etext>
    800012d4:	46a9                	li	a3,10
    800012d6:	80007617          	auipc	a2,0x80007
    800012da:	d2a60613          	addi	a2,a2,-726 # 8000 <spin-0x7fff801a>
    800012de:	4585                	li	a1,1
    800012e0:	05fe                	slli	a1,a1,0x1f
    800012e2:	852e                	mv	a0,a1
    800012e4:	00000097          	auipc	ra,0x0
    800012e8:	f38080e7          	jalr	-200(ra) # 8000121c <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ec:	4699                	li	a3,6
    800012ee:	4645                	li	a2,17
    800012f0:	066e                	slli	a2,a2,0x1b
    800012f2:	8e05                	sub	a2,a2,s1
    800012f4:	85a6                	mv	a1,s1
    800012f6:	8526                	mv	a0,s1
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	f24080e7          	jalr	-220(ra) # 8000121c <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001300:	46a9                	li	a3,10
    80001302:	6605                	lui	a2,0x1
    80001304:	00006597          	auipc	a1,0x6
    80001308:	cfc58593          	addi	a1,a1,-772 # 80007000 <_trampoline>
    8000130c:	04000537          	lui	a0,0x4000
    80001310:	157d                	addi	a0,a0,-1
    80001312:	0532                	slli	a0,a0,0xc
    80001314:	00000097          	auipc	ra,0x0
    80001318:	f08080e7          	jalr	-248(ra) # 8000121c <kvmmap>
}
    8000131c:	60e2                	ld	ra,24(sp)
    8000131e:	6442                	ld	s0,16(sp)
    80001320:	64a2                	ld	s1,8(sp)
    80001322:	6105                	addi	sp,sp,32
    80001324:	8082                	ret

0000000080001326 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001326:	715d                	addi	sp,sp,-80
    80001328:	e486                	sd	ra,72(sp)
    8000132a:	e0a2                	sd	s0,64(sp)
    8000132c:	fc26                	sd	s1,56(sp)
    8000132e:	f84a                	sd	s2,48(sp)
    80001330:	f44e                	sd	s3,40(sp)
    80001332:	f052                	sd	s4,32(sp)
    80001334:	ec56                	sd	s5,24(sp)
    80001336:	e85a                	sd	s6,16(sp)
    80001338:	e45e                	sd	s7,8(sp)
    8000133a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000133c:	03459793          	slli	a5,a1,0x34
    80001340:	e795                	bnez	a5,8000136c <uvmunmap+0x46>
    80001342:	8a2a                	mv	s4,a0
    80001344:	892e                	mv	s2,a1
    80001346:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001348:	0632                	slli	a2,a2,0xc
    8000134a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000134e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001350:	6b05                	lui	s6,0x1
    80001352:	0735e863          	bltu	a1,s3,800013c2 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001356:	60a6                	ld	ra,72(sp)
    80001358:	6406                	ld	s0,64(sp)
    8000135a:	74e2                	ld	s1,56(sp)
    8000135c:	7942                	ld	s2,48(sp)
    8000135e:	79a2                	ld	s3,40(sp)
    80001360:	7a02                	ld	s4,32(sp)
    80001362:	6ae2                	ld	s5,24(sp)
    80001364:	6b42                	ld	s6,16(sp)
    80001366:	6ba2                	ld	s7,8(sp)
    80001368:	6161                	addi	sp,sp,80
    8000136a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000136c:	00007517          	auipc	a0,0x7
    80001370:	d8c50513          	addi	a0,a0,-628 # 800080f8 <digits+0xb0>
    80001374:	fffff097          	auipc	ra,0xfffff
    80001378:	1c8080e7          	jalr	456(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    8000137c:	00007517          	auipc	a0,0x7
    80001380:	d9450513          	addi	a0,a0,-620 # 80008110 <digits+0xc8>
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	1b8080e7          	jalr	440(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    8000138c:	00007517          	auipc	a0,0x7
    80001390:	d9450513          	addi	a0,a0,-620 # 80008120 <digits+0xd8>
    80001394:	fffff097          	auipc	ra,0xfffff
    80001398:	1a8080e7          	jalr	424(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    8000139c:	00007517          	auipc	a0,0x7
    800013a0:	d9c50513          	addi	a0,a0,-612 # 80008138 <digits+0xf0>
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	198080e7          	jalr	408(ra) # 8000053c <panic>
      uint64 pa = PTE2PA(*pte);
    800013ac:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ae:	0532                	slli	a0,a0,0xc
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	6c4080e7          	jalr	1732(ra) # 80000a74 <kfree>
    *pte = 0;
    800013b8:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013bc:	995a                	add	s2,s2,s6
    800013be:	f9397ce3          	bgeu	s2,s3,80001356 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013c2:	4601                	li	a2,0
    800013c4:	85ca                	mv	a1,s2
    800013c6:	8552                	mv	a0,s4
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	c80080e7          	jalr	-896(ra) # 80001048 <walk>
    800013d0:	84aa                	mv	s1,a0
    800013d2:	d54d                	beqz	a0,8000137c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013d4:	6108                	ld	a0,0(a0)
    800013d6:	00157793          	andi	a5,a0,1
    800013da:	dbcd                	beqz	a5,8000138c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013dc:	3ff57793          	andi	a5,a0,1023
    800013e0:	fb778ee3          	beq	a5,s7,8000139c <uvmunmap+0x76>
    if(do_free){
    800013e4:	fc0a8ae3          	beqz	s5,800013b8 <uvmunmap+0x92>
    800013e8:	b7d1                	j	800013ac <uvmunmap+0x86>

00000000800013ea <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	77c080e7          	jalr	1916(ra) # 80000b70 <kalloc>
    800013fc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013fe:	c519                	beqz	a0,8000140c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001400:	6605                	lui	a2,0x1
    80001402:	4581                	li	a1,0
    80001404:	00000097          	auipc	ra,0x0
    80001408:	958080e7          	jalr	-1704(ra) # 80000d5c <memset>
  return pagetable;
}
    8000140c:	8526                	mv	a0,s1
    8000140e:	60e2                	ld	ra,24(sp)
    80001410:	6442                	ld	s0,16(sp)
    80001412:	64a2                	ld	s1,8(sp)
    80001414:	6105                	addi	sp,sp,32
    80001416:	8082                	ret

0000000080001418 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001418:	7179                	addi	sp,sp,-48
    8000141a:	f406                	sd	ra,40(sp)
    8000141c:	f022                	sd	s0,32(sp)
    8000141e:	ec26                	sd	s1,24(sp)
    80001420:	e84a                	sd	s2,16(sp)
    80001422:	e44e                	sd	s3,8(sp)
    80001424:	e052                	sd	s4,0(sp)
    80001426:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001428:	6785                	lui	a5,0x1
    8000142a:	04f67863          	bgeu	a2,a5,8000147a <uvminit+0x62>
    8000142e:	8a2a                	mv	s4,a0
    80001430:	89ae                	mv	s3,a1
    80001432:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001434:	fffff097          	auipc	ra,0xfffff
    80001438:	73c080e7          	jalr	1852(ra) # 80000b70 <kalloc>
    8000143c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	91a080e7          	jalr	-1766(ra) # 80000d5c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000144a:	4779                	li	a4,30
    8000144c:	86ca                	mv	a3,s2
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	8552                	mv	a0,s4
    80001454:	00000097          	auipc	ra,0x0
    80001458:	d3a080e7          	jalr	-710(ra) # 8000118e <mappages>
  memmove(mem, src, sz);
    8000145c:	8626                	mv	a2,s1
    8000145e:	85ce                	mv	a1,s3
    80001460:	854a                	mv	a0,s2
    80001462:	00000097          	auipc	ra,0x0
    80001466:	95a080e7          	jalr	-1702(ra) # 80000dbc <memmove>
}
    8000146a:	70a2                	ld	ra,40(sp)
    8000146c:	7402                	ld	s0,32(sp)
    8000146e:	64e2                	ld	s1,24(sp)
    80001470:	6942                	ld	s2,16(sp)
    80001472:	69a2                	ld	s3,8(sp)
    80001474:	6a02                	ld	s4,0(sp)
    80001476:	6145                	addi	sp,sp,48
    80001478:	8082                	ret
    panic("inituvm: more than a page");
    8000147a:	00007517          	auipc	a0,0x7
    8000147e:	cd650513          	addi	a0,a0,-810 # 80008150 <digits+0x108>
    80001482:	fffff097          	auipc	ra,0xfffff
    80001486:	0ba080e7          	jalr	186(ra) # 8000053c <panic>

000000008000148a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000148a:	1101                	addi	sp,sp,-32
    8000148c:	ec06                	sd	ra,24(sp)
    8000148e:	e822                	sd	s0,16(sp)
    80001490:	e426                	sd	s1,8(sp)
    80001492:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001494:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001496:	00b67d63          	bgeu	a2,a1,800014b0 <uvmdealloc+0x26>
    8000149a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000149c:	6785                	lui	a5,0x1
    8000149e:	17fd                	addi	a5,a5,-1
    800014a0:	00f60733          	add	a4,a2,a5
    800014a4:	767d                	lui	a2,0xfffff
    800014a6:	8f71                	and	a4,a4,a2
    800014a8:	97ae                	add	a5,a5,a1
    800014aa:	8ff1                	and	a5,a5,a2
    800014ac:	00f76863          	bltu	a4,a5,800014bc <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014b0:	8526                	mv	a0,s1
    800014b2:	60e2                	ld	ra,24(sp)
    800014b4:	6442                	ld	s0,16(sp)
    800014b6:	64a2                	ld	s1,8(sp)
    800014b8:	6105                	addi	sp,sp,32
    800014ba:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014bc:	8f99                	sub	a5,a5,a4
    800014be:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014c0:	4685                	li	a3,1
    800014c2:	0007861b          	sext.w	a2,a5
    800014c6:	85ba                	mv	a1,a4
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	e5e080e7          	jalr	-418(ra) # 80001326 <uvmunmap>
    800014d0:	b7c5                	j	800014b0 <uvmdealloc+0x26>

00000000800014d2 <uvmalloc>:
  if(newsz < oldsz)
    800014d2:	0ab66163          	bltu	a2,a1,80001574 <uvmalloc+0xa2>
{
    800014d6:	7139                	addi	sp,sp,-64
    800014d8:	fc06                	sd	ra,56(sp)
    800014da:	f822                	sd	s0,48(sp)
    800014dc:	f426                	sd	s1,40(sp)
    800014de:	f04a                	sd	s2,32(sp)
    800014e0:	ec4e                	sd	s3,24(sp)
    800014e2:	e852                	sd	s4,16(sp)
    800014e4:	e456                	sd	s5,8(sp)
    800014e6:	0080                	addi	s0,sp,64
    800014e8:	8aaa                	mv	s5,a0
    800014ea:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ec:	6985                	lui	s3,0x1
    800014ee:	19fd                	addi	s3,s3,-1
    800014f0:	95ce                	add	a1,a1,s3
    800014f2:	79fd                	lui	s3,0xfffff
    800014f4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f8:	08c9f063          	bgeu	s3,a2,80001578 <uvmalloc+0xa6>
    800014fc:	894e                	mv	s2,s3
    mem = kalloc();
    800014fe:	fffff097          	auipc	ra,0xfffff
    80001502:	672080e7          	jalr	1650(ra) # 80000b70 <kalloc>
    80001506:	84aa                	mv	s1,a0
    if(mem == 0){
    80001508:	c51d                	beqz	a0,80001536 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000150a:	6605                	lui	a2,0x1
    8000150c:	4581                	li	a1,0
    8000150e:	00000097          	auipc	ra,0x0
    80001512:	84e080e7          	jalr	-1970(ra) # 80000d5c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001516:	4779                	li	a4,30
    80001518:	86a6                	mv	a3,s1
    8000151a:	6605                	lui	a2,0x1
    8000151c:	85ca                	mv	a1,s2
    8000151e:	8556                	mv	a0,s5
    80001520:	00000097          	auipc	ra,0x0
    80001524:	c6e080e7          	jalr	-914(ra) # 8000118e <mappages>
    80001528:	e905                	bnez	a0,80001558 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152a:	6785                	lui	a5,0x1
    8000152c:	993e                	add	s2,s2,a5
    8000152e:	fd4968e3          	bltu	s2,s4,800014fe <uvmalloc+0x2c>
  return newsz;
    80001532:	8552                	mv	a0,s4
    80001534:	a809                	j	80001546 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001536:	864e                	mv	a2,s3
    80001538:	85ca                	mv	a1,s2
    8000153a:	8556                	mv	a0,s5
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f4e080e7          	jalr	-178(ra) # 8000148a <uvmdealloc>
      return 0;
    80001544:	4501                	li	a0,0
}
    80001546:	70e2                	ld	ra,56(sp)
    80001548:	7442                	ld	s0,48(sp)
    8000154a:	74a2                	ld	s1,40(sp)
    8000154c:	7902                	ld	s2,32(sp)
    8000154e:	69e2                	ld	s3,24(sp)
    80001550:	6a42                	ld	s4,16(sp)
    80001552:	6aa2                	ld	s5,8(sp)
    80001554:	6121                	addi	sp,sp,64
    80001556:	8082                	ret
      kfree(mem);
    80001558:	8526                	mv	a0,s1
    8000155a:	fffff097          	auipc	ra,0xfffff
    8000155e:	51a080e7          	jalr	1306(ra) # 80000a74 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001562:	864e                	mv	a2,s3
    80001564:	85ca                	mv	a1,s2
    80001566:	8556                	mv	a0,s5
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	f22080e7          	jalr	-222(ra) # 8000148a <uvmdealloc>
      return 0;
    80001570:	4501                	li	a0,0
    80001572:	bfd1                	j	80001546 <uvmalloc+0x74>
    return oldsz;
    80001574:	852e                	mv	a0,a1
}
    80001576:	8082                	ret
  return newsz;
    80001578:	8532                	mv	a0,a2
    8000157a:	b7f1                	j	80001546 <uvmalloc+0x74>

000000008000157c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000157c:	7179                	addi	sp,sp,-48
    8000157e:	f406                	sd	ra,40(sp)
    80001580:	f022                	sd	s0,32(sp)
    80001582:	ec26                	sd	s1,24(sp)
    80001584:	e84a                	sd	s2,16(sp)
    80001586:	e44e                	sd	s3,8(sp)
    80001588:	e052                	sd	s4,0(sp)
    8000158a:	1800                	addi	s0,sp,48
    8000158c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000158e:	84aa                	mv	s1,a0
    80001590:	6905                	lui	s2,0x1
    80001592:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001594:	4985                	li	s3,1
    80001596:	a821                	j	800015ae <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001598:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000159a:	0532                	slli	a0,a0,0xc
    8000159c:	00000097          	auipc	ra,0x0
    800015a0:	fe0080e7          	jalr	-32(ra) # 8000157c <freewalk>
      pagetable[i] = 0;
    800015a4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015a8:	04a1                	addi	s1,s1,8
    800015aa:	03248163          	beq	s1,s2,800015cc <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015ae:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b0:	00f57793          	andi	a5,a0,15
    800015b4:	ff3782e3          	beq	a5,s3,80001598 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015b8:	8905                	andi	a0,a0,1
    800015ba:	d57d                	beqz	a0,800015a8 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015bc:	00007517          	auipc	a0,0x7
    800015c0:	bb450513          	addi	a0,a0,-1100 # 80008170 <digits+0x128>
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	f78080e7          	jalr	-136(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800015cc:	8552                	mv	a0,s4
    800015ce:	fffff097          	auipc	ra,0xfffff
    800015d2:	4a6080e7          	jalr	1190(ra) # 80000a74 <kfree>
}
    800015d6:	70a2                	ld	ra,40(sp)
    800015d8:	7402                	ld	s0,32(sp)
    800015da:	64e2                	ld	s1,24(sp)
    800015dc:	6942                	ld	s2,16(sp)
    800015de:	69a2                	ld	s3,8(sp)
    800015e0:	6a02                	ld	s4,0(sp)
    800015e2:	6145                	addi	sp,sp,48
    800015e4:	8082                	ret

00000000800015e6 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015e6:	1101                	addi	sp,sp,-32
    800015e8:	ec06                	sd	ra,24(sp)
    800015ea:	e822                	sd	s0,16(sp)
    800015ec:	e426                	sd	s1,8(sp)
    800015ee:	1000                	addi	s0,sp,32
    800015f0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015f2:	e999                	bnez	a1,80001608 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015f4:	8526                	mv	a0,s1
    800015f6:	00000097          	auipc	ra,0x0
    800015fa:	f86080e7          	jalr	-122(ra) # 8000157c <freewalk>
}
    800015fe:	60e2                	ld	ra,24(sp)
    80001600:	6442                	ld	s0,16(sp)
    80001602:	64a2                	ld	s1,8(sp)
    80001604:	6105                	addi	sp,sp,32
    80001606:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001608:	6605                	lui	a2,0x1
    8000160a:	167d                	addi	a2,a2,-1
    8000160c:	962e                	add	a2,a2,a1
    8000160e:	4685                	li	a3,1
    80001610:	8231                	srli	a2,a2,0xc
    80001612:	4581                	li	a1,0
    80001614:	00000097          	auipc	ra,0x0
    80001618:	d12080e7          	jalr	-750(ra) # 80001326 <uvmunmap>
    8000161c:	bfe1                	j	800015f4 <uvmfree+0xe>

000000008000161e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000161e:	c679                	beqz	a2,800016ec <uvmcopy+0xce>
{
    80001620:	715d                	addi	sp,sp,-80
    80001622:	e486                	sd	ra,72(sp)
    80001624:	e0a2                	sd	s0,64(sp)
    80001626:	fc26                	sd	s1,56(sp)
    80001628:	f84a                	sd	s2,48(sp)
    8000162a:	f44e                	sd	s3,40(sp)
    8000162c:	f052                	sd	s4,32(sp)
    8000162e:	ec56                	sd	s5,24(sp)
    80001630:	e85a                	sd	s6,16(sp)
    80001632:	e45e                	sd	s7,8(sp)
    80001634:	0880                	addi	s0,sp,80
    80001636:	8b2a                	mv	s6,a0
    80001638:	8aae                	mv	s5,a1
    8000163a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000163c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000163e:	4601                	li	a2,0
    80001640:	85ce                	mv	a1,s3
    80001642:	855a                	mv	a0,s6
    80001644:	00000097          	auipc	ra,0x0
    80001648:	a04080e7          	jalr	-1532(ra) # 80001048 <walk>
    8000164c:	c531                	beqz	a0,80001698 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000164e:	6118                	ld	a4,0(a0)
    80001650:	00177793          	andi	a5,a4,1
    80001654:	cbb1                	beqz	a5,800016a8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001656:	00a75593          	srli	a1,a4,0xa
    8000165a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000165e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	50e080e7          	jalr	1294(ra) # 80000b70 <kalloc>
    8000166a:	892a                	mv	s2,a0
    8000166c:	c939                	beqz	a0,800016c2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000166e:	6605                	lui	a2,0x1
    80001670:	85de                	mv	a1,s7
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	74a080e7          	jalr	1866(ra) # 80000dbc <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000167a:	8726                	mv	a4,s1
    8000167c:	86ca                	mv	a3,s2
    8000167e:	6605                	lui	a2,0x1
    80001680:	85ce                	mv	a1,s3
    80001682:	8556                	mv	a0,s5
    80001684:	00000097          	auipc	ra,0x0
    80001688:	b0a080e7          	jalr	-1270(ra) # 8000118e <mappages>
    8000168c:	e515                	bnez	a0,800016b8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000168e:	6785                	lui	a5,0x1
    80001690:	99be                	add	s3,s3,a5
    80001692:	fb49e6e3          	bltu	s3,s4,8000163e <uvmcopy+0x20>
    80001696:	a081                	j	800016d6 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001698:	00007517          	auipc	a0,0x7
    8000169c:	ae850513          	addi	a0,a0,-1304 # 80008180 <digits+0x138>
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	e9c080e7          	jalr	-356(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800016a8:	00007517          	auipc	a0,0x7
    800016ac:	af850513          	addi	a0,a0,-1288 # 800081a0 <digits+0x158>
    800016b0:	fffff097          	auipc	ra,0xfffff
    800016b4:	e8c080e7          	jalr	-372(ra) # 8000053c <panic>
      kfree(mem);
    800016b8:	854a                	mv	a0,s2
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	3ba080e7          	jalr	954(ra) # 80000a74 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016c2:	4685                	li	a3,1
    800016c4:	00c9d613          	srli	a2,s3,0xc
    800016c8:	4581                	li	a1,0
    800016ca:	8556                	mv	a0,s5
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	c5a080e7          	jalr	-934(ra) # 80001326 <uvmunmap>
  return -1;
    800016d4:	557d                	li	a0,-1
}
    800016d6:	60a6                	ld	ra,72(sp)
    800016d8:	6406                	ld	s0,64(sp)
    800016da:	74e2                	ld	s1,56(sp)
    800016dc:	7942                	ld	s2,48(sp)
    800016de:	79a2                	ld	s3,40(sp)
    800016e0:	7a02                	ld	s4,32(sp)
    800016e2:	6ae2                	ld	s5,24(sp)
    800016e4:	6b42                	ld	s6,16(sp)
    800016e6:	6ba2                	ld	s7,8(sp)
    800016e8:	6161                	addi	sp,sp,80
    800016ea:	8082                	ret
  return 0;
    800016ec:	4501                	li	a0,0
}
    800016ee:	8082                	ret

00000000800016f0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016f0:	1141                	addi	sp,sp,-16
    800016f2:	e406                	sd	ra,8(sp)
    800016f4:	e022                	sd	s0,0(sp)
    800016f6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016f8:	4601                	li	a2,0
    800016fa:	00000097          	auipc	ra,0x0
    800016fe:	94e080e7          	jalr	-1714(ra) # 80001048 <walk>
  if(pte == 0)
    80001702:	c901                	beqz	a0,80001712 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001704:	611c                	ld	a5,0(a0)
    80001706:	9bbd                	andi	a5,a5,-17
    80001708:	e11c                	sd	a5,0(a0)
}
    8000170a:	60a2                	ld	ra,8(sp)
    8000170c:	6402                	ld	s0,0(sp)
    8000170e:	0141                	addi	sp,sp,16
    80001710:	8082                	ret
    panic("uvmclear");
    80001712:	00007517          	auipc	a0,0x7
    80001716:	aae50513          	addi	a0,a0,-1362 # 800081c0 <digits+0x178>
    8000171a:	fffff097          	auipc	ra,0xfffff
    8000171e:	e22080e7          	jalr	-478(ra) # 8000053c <panic>

0000000080001722 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001722:	c6bd                	beqz	a3,80001790 <copyout+0x6e>
{
    80001724:	715d                	addi	sp,sp,-80
    80001726:	e486                	sd	ra,72(sp)
    80001728:	e0a2                	sd	s0,64(sp)
    8000172a:	fc26                	sd	s1,56(sp)
    8000172c:	f84a                	sd	s2,48(sp)
    8000172e:	f44e                	sd	s3,40(sp)
    80001730:	f052                	sd	s4,32(sp)
    80001732:	ec56                	sd	s5,24(sp)
    80001734:	e85a                	sd	s6,16(sp)
    80001736:	e45e                	sd	s7,8(sp)
    80001738:	e062                	sd	s8,0(sp)
    8000173a:	0880                	addi	s0,sp,80
    8000173c:	8b2a                	mv	s6,a0
    8000173e:	8c2e                	mv	s8,a1
    80001740:	8a32                	mv	s4,a2
    80001742:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001744:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001746:	6a85                	lui	s5,0x1
    80001748:	a015                	j	8000176c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000174a:	9562                	add	a0,a0,s8
    8000174c:	0004861b          	sext.w	a2,s1
    80001750:	85d2                	mv	a1,s4
    80001752:	41250533          	sub	a0,a0,s2
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	666080e7          	jalr	1638(ra) # 80000dbc <memmove>

    len -= n;
    8000175e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001762:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001764:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001768:	02098263          	beqz	s3,8000178c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000176c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001770:	85ca                	mv	a1,s2
    80001772:	855a                	mv	a0,s6
    80001774:	00000097          	auipc	ra,0x0
    80001778:	97a080e7          	jalr	-1670(ra) # 800010ee <walkaddr>
    if(pa0 == 0)
    8000177c:	cd01                	beqz	a0,80001794 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000177e:	418904b3          	sub	s1,s2,s8
    80001782:	94d6                	add	s1,s1,s5
    if(n > len)
    80001784:	fc99f3e3          	bgeu	s3,s1,8000174a <copyout+0x28>
    80001788:	84ce                	mv	s1,s3
    8000178a:	b7c1                	j	8000174a <copyout+0x28>
  }
  return 0;
    8000178c:	4501                	li	a0,0
    8000178e:	a021                	j	80001796 <copyout+0x74>
    80001790:	4501                	li	a0,0
}
    80001792:	8082                	ret
      return -1;
    80001794:	557d                	li	a0,-1
}
    80001796:	60a6                	ld	ra,72(sp)
    80001798:	6406                	ld	s0,64(sp)
    8000179a:	74e2                	ld	s1,56(sp)
    8000179c:	7942                	ld	s2,48(sp)
    8000179e:	79a2                	ld	s3,40(sp)
    800017a0:	7a02                	ld	s4,32(sp)
    800017a2:	6ae2                	ld	s5,24(sp)
    800017a4:	6b42                	ld	s6,16(sp)
    800017a6:	6ba2                	ld	s7,8(sp)
    800017a8:	6c02                	ld	s8,0(sp)
    800017aa:	6161                	addi	sp,sp,80
    800017ac:	8082                	ret

00000000800017ae <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ae:	c6bd                	beqz	a3,8000181c <copyin+0x6e>
{
    800017b0:	715d                	addi	sp,sp,-80
    800017b2:	e486                	sd	ra,72(sp)
    800017b4:	e0a2                	sd	s0,64(sp)
    800017b6:	fc26                	sd	s1,56(sp)
    800017b8:	f84a                	sd	s2,48(sp)
    800017ba:	f44e                	sd	s3,40(sp)
    800017bc:	f052                	sd	s4,32(sp)
    800017be:	ec56                	sd	s5,24(sp)
    800017c0:	e85a                	sd	s6,16(sp)
    800017c2:	e45e                	sd	s7,8(sp)
    800017c4:	e062                	sd	s8,0(sp)
    800017c6:	0880                	addi	s0,sp,80
    800017c8:	8b2a                	mv	s6,a0
    800017ca:	8a2e                	mv	s4,a1
    800017cc:	8c32                	mv	s8,a2
    800017ce:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017d0:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017d2:	6a85                	lui	s5,0x1
    800017d4:	a015                	j	800017f8 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017d6:	9562                	add	a0,a0,s8
    800017d8:	0004861b          	sext.w	a2,s1
    800017dc:	412505b3          	sub	a1,a0,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	fffff097          	auipc	ra,0xfffff
    800017e6:	5da080e7          	jalr	1498(ra) # 80000dbc <memmove>

    len -= n;
    800017ea:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017ee:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017f0:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017f4:	02098263          	beqz	s3,80001818 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017f8:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017fc:	85ca                	mv	a1,s2
    800017fe:	855a                	mv	a0,s6
    80001800:	00000097          	auipc	ra,0x0
    80001804:	8ee080e7          	jalr	-1810(ra) # 800010ee <walkaddr>
    if(pa0 == 0)
    80001808:	cd01                	beqz	a0,80001820 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000180a:	418904b3          	sub	s1,s2,s8
    8000180e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001810:	fc99f3e3          	bgeu	s3,s1,800017d6 <copyin+0x28>
    80001814:	84ce                	mv	s1,s3
    80001816:	b7c1                	j	800017d6 <copyin+0x28>
  }
  return 0;
    80001818:	4501                	li	a0,0
    8000181a:	a021                	j	80001822 <copyin+0x74>
    8000181c:	4501                	li	a0,0
}
    8000181e:	8082                	ret
      return -1;
    80001820:	557d                	li	a0,-1
}
    80001822:	60a6                	ld	ra,72(sp)
    80001824:	6406                	ld	s0,64(sp)
    80001826:	74e2                	ld	s1,56(sp)
    80001828:	7942                	ld	s2,48(sp)
    8000182a:	79a2                	ld	s3,40(sp)
    8000182c:	7a02                	ld	s4,32(sp)
    8000182e:	6ae2                	ld	s5,24(sp)
    80001830:	6b42                	ld	s6,16(sp)
    80001832:	6ba2                	ld	s7,8(sp)
    80001834:	6c02                	ld	s8,0(sp)
    80001836:	6161                	addi	sp,sp,80
    80001838:	8082                	ret

000000008000183a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000183a:	c6c5                	beqz	a3,800018e2 <copyinstr+0xa8>
{
    8000183c:	715d                	addi	sp,sp,-80
    8000183e:	e486                	sd	ra,72(sp)
    80001840:	e0a2                	sd	s0,64(sp)
    80001842:	fc26                	sd	s1,56(sp)
    80001844:	f84a                	sd	s2,48(sp)
    80001846:	f44e                	sd	s3,40(sp)
    80001848:	f052                	sd	s4,32(sp)
    8000184a:	ec56                	sd	s5,24(sp)
    8000184c:	e85a                	sd	s6,16(sp)
    8000184e:	e45e                	sd	s7,8(sp)
    80001850:	0880                	addi	s0,sp,80
    80001852:	8a2a                	mv	s4,a0
    80001854:	8b2e                	mv	s6,a1
    80001856:	8bb2                	mv	s7,a2
    80001858:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000185a:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000185c:	6985                	lui	s3,0x1
    8000185e:	a035                	j	8000188a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001860:	00078023          	sb	zero,0(a5) # 1000 <spin-0x7ffff01a>
    80001864:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001866:	0017b793          	seqz	a5,a5
    8000186a:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000186e:	60a6                	ld	ra,72(sp)
    80001870:	6406                	ld	s0,64(sp)
    80001872:	74e2                	ld	s1,56(sp)
    80001874:	7942                	ld	s2,48(sp)
    80001876:	79a2                	ld	s3,40(sp)
    80001878:	7a02                	ld	s4,32(sp)
    8000187a:	6ae2                	ld	s5,24(sp)
    8000187c:	6b42                	ld	s6,16(sp)
    8000187e:	6ba2                	ld	s7,8(sp)
    80001880:	6161                	addi	sp,sp,80
    80001882:	8082                	ret
    srcva = va0 + PGSIZE;
    80001884:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001888:	c8a9                	beqz	s1,800018da <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000188a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000188e:	85ca                	mv	a1,s2
    80001890:	8552                	mv	a0,s4
    80001892:	00000097          	auipc	ra,0x0
    80001896:	85c080e7          	jalr	-1956(ra) # 800010ee <walkaddr>
    if(pa0 == 0)
    8000189a:	c131                	beqz	a0,800018de <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000189c:	41790833          	sub	a6,s2,s7
    800018a0:	984e                	add	a6,a6,s3
    if(n > max)
    800018a2:	0104f363          	bgeu	s1,a6,800018a8 <copyinstr+0x6e>
    800018a6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018a8:	955e                	add	a0,a0,s7
    800018aa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ae:	fc080be3          	beqz	a6,80001884 <copyinstr+0x4a>
    800018b2:	985a                	add	a6,a6,s6
    800018b4:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018b6:	41650633          	sub	a2,a0,s6
    800018ba:	14fd                	addi	s1,s1,-1
    800018bc:	9b26                	add	s6,s6,s1
    800018be:	00f60733          	add	a4,a2,a5
    800018c2:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018c6:	df49                	beqz	a4,80001860 <copyinstr+0x26>
        *dst = *p;
    800018c8:	00e78023          	sb	a4,0(a5)
      --max;
    800018cc:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018d0:	0785                	addi	a5,a5,1
    while(n > 0){
    800018d2:	ff0796e3          	bne	a5,a6,800018be <copyinstr+0x84>
      dst++;
    800018d6:	8b42                	mv	s6,a6
    800018d8:	b775                	j	80001884 <copyinstr+0x4a>
    800018da:	4781                	li	a5,0
    800018dc:	b769                	j	80001866 <copyinstr+0x2c>
      return -1;
    800018de:	557d                	li	a0,-1
    800018e0:	b779                	j	8000186e <copyinstr+0x34>
  int got_null = 0;
    800018e2:	4781                	li	a5,0
  if(got_null){
    800018e4:	0017b793          	seqz	a5,a5
    800018e8:	40f00533          	neg	a0,a5
}
    800018ec:	8082                	ret

00000000800018ee <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018ee:	1101                	addi	sp,sp,-32
    800018f0:	ec06                	sd	ra,24(sp)
    800018f2:	e822                	sd	s0,16(sp)
    800018f4:	e426                	sd	s1,8(sp)
    800018f6:	1000                	addi	s0,sp,32
    800018f8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	2ec080e7          	jalr	748(ra) # 80000be6 <holding>
    80001902:	c909                	beqz	a0,80001914 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001904:	749c                	ld	a5,40(s1)
    80001906:	00978f63          	beq	a5,s1,80001924 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000190a:	60e2                	ld	ra,24(sp)
    8000190c:	6442                	ld	s0,16(sp)
    8000190e:	64a2                	ld	s1,8(sp)
    80001910:	6105                	addi	sp,sp,32
    80001912:	8082                	ret
    panic("wakeup1");
    80001914:	00007517          	auipc	a0,0x7
    80001918:	8bc50513          	addi	a0,a0,-1860 # 800081d0 <digits+0x188>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	c20080e7          	jalr	-992(ra) # 8000053c <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001924:	4c98                	lw	a4,24(s1)
    80001926:	4785                	li	a5,1
    80001928:	fef711e3          	bne	a4,a5,8000190a <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000192c:	4789                	li	a5,2
    8000192e:	cc9c                	sw	a5,24(s1)
}
    80001930:	bfe9                	j	8000190a <wakeup1+0x1c>

0000000080001932 <procinit>:
{
    80001932:	715d                	addi	sp,sp,-80
    80001934:	e486                	sd	ra,72(sp)
    80001936:	e0a2                	sd	s0,64(sp)
    80001938:	fc26                	sd	s1,56(sp)
    8000193a:	f84a                	sd	s2,48(sp)
    8000193c:	f44e                	sd	s3,40(sp)
    8000193e:	f052                	sd	s4,32(sp)
    80001940:	ec56                	sd	s5,24(sp)
    80001942:	e85a                	sd	s6,16(sp)
    80001944:	e45e                	sd	s7,8(sp)
    80001946:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001948:	00007597          	auipc	a1,0x7
    8000194c:	89058593          	addi	a1,a1,-1904 # 800081d8 <digits+0x190>
    80001950:	00010517          	auipc	a0,0x10
    80001954:	00050513          	mv	a0,a0
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	278080e7          	jalr	632(ra) # 80000bd0 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001960:	00010917          	auipc	s2,0x10
    80001964:	40890913          	addi	s2,s2,1032 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001968:	00007b97          	auipc	s7,0x7
    8000196c:	878b8b93          	addi	s7,s7,-1928 # 800081e0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001970:	8b4a                	mv	s6,s2
    80001972:	00006a97          	auipc	s5,0x6
    80001976:	68ea8a93          	addi	s5,s5,1678 # 80008000 <etext>
    8000197a:	040009b7          	lui	s3,0x4000
    8000197e:	19fd                	addi	s3,s3,-1
    80001980:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001982:	00016a17          	auipc	s4,0x16
    80001986:	7e6a0a13          	addi	s4,s4,2022 # 80018168 <tickslock>
      initlock(&p->lock, "proc");
    8000198a:	85de                	mv	a1,s7
    8000198c:	854a                	mv	a0,s2
    8000198e:	fffff097          	auipc	ra,0xfffff
    80001992:	242080e7          	jalr	578(ra) # 80000bd0 <initlock>
      char *pa = kalloc();
    80001996:	fffff097          	auipc	ra,0xfffff
    8000199a:	1da080e7          	jalr	474(ra) # 80000b70 <kalloc>
    8000199e:	85aa                	mv	a1,a0
      if(pa == 0)
    800019a0:	c929                	beqz	a0,800019f2 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019a2:	416904b3          	sub	s1,s2,s6
    800019a6:	8491                	srai	s1,s1,0x4
    800019a8:	000ab783          	ld	a5,0(s5)
    800019ac:	02f484b3          	mul	s1,s1,a5
    800019b0:	2485                	addiw	s1,s1,1
    800019b2:	00d4949b          	slliw	s1,s1,0xd
    800019b6:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019ba:	4699                	li	a3,6
    800019bc:	6605                	lui	a2,0x1
    800019be:	8526                	mv	a0,s1
    800019c0:	00000097          	auipc	ra,0x0
    800019c4:	85c080e7          	jalr	-1956(ra) # 8000121c <kvmmap>
      p->kstack = va;
    800019c8:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019cc:	19090913          	addi	s2,s2,400
    800019d0:	fb491de3          	bne	s2,s4,8000198a <procinit+0x58>
  kvminithart();
    800019d4:	fffff097          	auipc	ra,0xfffff
    800019d8:	650080e7          	jalr	1616(ra) # 80001024 <kvminithart>
}
    800019dc:	60a6                	ld	ra,72(sp)
    800019de:	6406                	ld	s0,64(sp)
    800019e0:	74e2                	ld	s1,56(sp)
    800019e2:	7942                	ld	s2,48(sp)
    800019e4:	79a2                	ld	s3,40(sp)
    800019e6:	7a02                	ld	s4,32(sp)
    800019e8:	6ae2                	ld	s5,24(sp)
    800019ea:	6b42                	ld	s6,16(sp)
    800019ec:	6ba2                	ld	s7,8(sp)
    800019ee:	6161                	addi	sp,sp,80
    800019f0:	8082                	ret
        panic("kalloc");
    800019f2:	00006517          	auipc	a0,0x6
    800019f6:	7f650513          	addi	a0,a0,2038 # 800081e8 <digits+0x1a0>
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	b42080e7          	jalr	-1214(ra) # 8000053c <panic>

0000000080001a02 <cpuid>:
{
    80001a02:	1141                	addi	sp,sp,-16
    80001a04:	e422                	sd	s0,8(sp)
    80001a06:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a08:	8512                	mv	a0,tp
}
    80001a0a:	2501                	sext.w	a0,a0
    80001a0c:	6422                	ld	s0,8(sp)
    80001a0e:	0141                	addi	sp,sp,16
    80001a10:	8082                	ret

0000000080001a12 <mycpu>:
mycpu(void) {
    80001a12:	1141                	addi	sp,sp,-16
    80001a14:	e422                	sd	s0,8(sp)
    80001a16:	0800                	addi	s0,sp,16
    80001a18:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a1a:	2781                	sext.w	a5,a5
    80001a1c:	079e                	slli	a5,a5,0x7
}
    80001a1e:	00010517          	auipc	a0,0x10
    80001a22:	f4a50513          	addi	a0,a0,-182 # 80011968 <cpus>
    80001a26:	953e                	add	a0,a0,a5
    80001a28:	6422                	ld	s0,8(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <myproc>:
myproc(void) {
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	1000                	addi	s0,sp,32
  push_off();
    80001a38:	fffff097          	auipc	ra,0xfffff
    80001a3c:	1dc080e7          	jalr	476(ra) # 80000c14 <push_off>
    80001a40:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a42:	2781                	sext.w	a5,a5
    80001a44:	079e                	slli	a5,a5,0x7
    80001a46:	00010717          	auipc	a4,0x10
    80001a4a:	f0a70713          	addi	a4,a4,-246 # 80011950 <pid_lock>
    80001a4e:	97ba                	add	a5,a5,a4
    80001a50:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	262080e7          	jalr	610(ra) # 80000cb4 <pop_off>
}
    80001a5a:	8526                	mv	a0,s1
    80001a5c:	60e2                	ld	ra,24(sp)
    80001a5e:	6442                	ld	s0,16(sp)
    80001a60:	64a2                	ld	s1,8(sp)
    80001a62:	6105                	addi	sp,sp,32
    80001a64:	8082                	ret

0000000080001a66 <forkret>:
{
    80001a66:	1141                	addi	sp,sp,-16
    80001a68:	e406                	sd	ra,8(sp)
    80001a6a:	e022                	sd	s0,0(sp)
    80001a6c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a6e:	00000097          	auipc	ra,0x0
    80001a72:	fc0080e7          	jalr	-64(ra) # 80001a2e <myproc>
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	29e080e7          	jalr	670(ra) # 80000d14 <release>
  if (first) {
    80001a7e:	00007797          	auipc	a5,0x7
    80001a82:	db27a783          	lw	a5,-590(a5) # 80008830 <first.1695>
    80001a86:	eb89                	bnez	a5,80001a98 <forkret+0x32>
  usertrapret();
    80001a88:	00001097          	auipc	ra,0x1
    80001a8c:	cd2080e7          	jalr	-814(ra) # 8000275a <usertrapret>
}
    80001a90:	60a2                	ld	ra,8(sp)
    80001a92:	6402                	ld	s0,0(sp)
    80001a94:	0141                	addi	sp,sp,16
    80001a96:	8082                	ret
    first = 0;
    80001a98:	00007797          	auipc	a5,0x7
    80001a9c:	d807ac23          	sw	zero,-616(a5) # 80008830 <first.1695>
    fsinit(ROOTDEV);
    80001aa0:	4505                	li	a0,1
    80001aa2:	00002097          	auipc	ra,0x2
    80001aa6:	ac4080e7          	jalr	-1340(ra) # 80003566 <fsinit>
    80001aaa:	bff9                	j	80001a88 <forkret+0x22>

0000000080001aac <allocpid>:
allocpid() {
    80001aac:	1101                	addi	sp,sp,-32
    80001aae:	ec06                	sd	ra,24(sp)
    80001ab0:	e822                	sd	s0,16(sp)
    80001ab2:	e426                	sd	s1,8(sp)
    80001ab4:	e04a                	sd	s2,0(sp)
    80001ab6:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ab8:	00010917          	auipc	s2,0x10
    80001abc:	e9890913          	addi	s2,s2,-360 # 80011950 <pid_lock>
    80001ac0:	854a                	mv	a0,s2
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	19e080e7          	jalr	414(ra) # 80000c60 <acquire>
  pid = nextpid;
    80001aca:	00007797          	auipc	a5,0x7
    80001ace:	d6a78793          	addi	a5,a5,-662 # 80008834 <nextpid>
    80001ad2:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ad4:	0014871b          	addiw	a4,s1,1
    80001ad8:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ada:	854a                	mv	a0,s2
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	238080e7          	jalr	568(ra) # 80000d14 <release>
}
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	60e2                	ld	ra,24(sp)
    80001ae8:	6442                	ld	s0,16(sp)
    80001aea:	64a2                	ld	s1,8(sp)
    80001aec:	6902                	ld	s2,0(sp)
    80001aee:	6105                	addi	sp,sp,32
    80001af0:	8082                	ret

0000000080001af2 <proc_pagetable>:
{
    80001af2:	1101                	addi	sp,sp,-32
    80001af4:	ec06                	sd	ra,24(sp)
    80001af6:	e822                	sd	s0,16(sp)
    80001af8:	e426                	sd	s1,8(sp)
    80001afa:	e04a                	sd	s2,0(sp)
    80001afc:	1000                	addi	s0,sp,32
    80001afe:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	8ea080e7          	jalr	-1814(ra) # 800013ea <uvmcreate>
    80001b08:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b0a:	c121                	beqz	a0,80001b4a <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b0c:	4729                	li	a4,10
    80001b0e:	00005697          	auipc	a3,0x5
    80001b12:	4f268693          	addi	a3,a3,1266 # 80007000 <_trampoline>
    80001b16:	6605                	lui	a2,0x1
    80001b18:	040005b7          	lui	a1,0x4000
    80001b1c:	15fd                	addi	a1,a1,-1
    80001b1e:	05b2                	slli	a1,a1,0xc
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	66e080e7          	jalr	1646(ra) # 8000118e <mappages>
    80001b28:	02054863          	bltz	a0,80001b58 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b2c:	4719                	li	a4,6
    80001b2e:	05893683          	ld	a3,88(s2)
    80001b32:	6605                	lui	a2,0x1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	650080e7          	jalr	1616(ra) # 8000118e <mappages>
    80001b46:	02054163          	bltz	a0,80001b68 <proc_pagetable+0x76>
}
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret
    uvmfree(pagetable, 0);
    80001b58:	4581                	li	a1,0
    80001b5a:	8526                	mv	a0,s1
    80001b5c:	00000097          	auipc	ra,0x0
    80001b60:	a8a080e7          	jalr	-1398(ra) # 800015e6 <uvmfree>
    return 0;
    80001b64:	4481                	li	s1,0
    80001b66:	b7d5                	j	80001b4a <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b68:	4681                	li	a3,0
    80001b6a:	4605                	li	a2,1
    80001b6c:	040005b7          	lui	a1,0x4000
    80001b70:	15fd                	addi	a1,a1,-1
    80001b72:	05b2                	slli	a1,a1,0xc
    80001b74:	8526                	mv	a0,s1
    80001b76:	fffff097          	auipc	ra,0xfffff
    80001b7a:	7b0080e7          	jalr	1968(ra) # 80001326 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b7e:	4581                	li	a1,0
    80001b80:	8526                	mv	a0,s1
    80001b82:	00000097          	auipc	ra,0x0
    80001b86:	a64080e7          	jalr	-1436(ra) # 800015e6 <uvmfree>
    return 0;
    80001b8a:	4481                	li	s1,0
    80001b8c:	bf7d                	j	80001b4a <proc_pagetable+0x58>

0000000080001b8e <proc_freepagetable>:
{
    80001b8e:	1101                	addi	sp,sp,-32
    80001b90:	ec06                	sd	ra,24(sp)
    80001b92:	e822                	sd	s0,16(sp)
    80001b94:	e426                	sd	s1,8(sp)
    80001b96:	e04a                	sd	s2,0(sp)
    80001b98:	1000                	addi	s0,sp,32
    80001b9a:	84aa                	mv	s1,a0
    80001b9c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b9e:	4681                	li	a3,0
    80001ba0:	4605                	li	a2,1
    80001ba2:	040005b7          	lui	a1,0x4000
    80001ba6:	15fd                	addi	a1,a1,-1
    80001ba8:	05b2                	slli	a1,a1,0xc
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	77c080e7          	jalr	1916(ra) # 80001326 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bb2:	4681                	li	a3,0
    80001bb4:	4605                	li	a2,1
    80001bb6:	020005b7          	lui	a1,0x2000
    80001bba:	15fd                	addi	a1,a1,-1
    80001bbc:	05b6                	slli	a1,a1,0xd
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	766080e7          	jalr	1894(ra) # 80001326 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bc8:	85ca                	mv	a1,s2
    80001bca:	8526                	mv	a0,s1
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	a1a080e7          	jalr	-1510(ra) # 800015e6 <uvmfree>
}
    80001bd4:	60e2                	ld	ra,24(sp)
    80001bd6:	6442                	ld	s0,16(sp)
    80001bd8:	64a2                	ld	s1,8(sp)
    80001bda:	6902                	ld	s2,0(sp)
    80001bdc:	6105                	addi	sp,sp,32
    80001bde:	8082                	ret

0000000080001be0 <freeproc>:
{
    80001be0:	1101                	addi	sp,sp,-32
    80001be2:	ec06                	sd	ra,24(sp)
    80001be4:	e822                	sd	s0,16(sp)
    80001be6:	e426                	sd	s1,8(sp)
    80001be8:	1000                	addi	s0,sp,32
    80001bea:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bec:	6d28                	ld	a0,88(a0)
    80001bee:	c509                	beqz	a0,80001bf8 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bf0:	fffff097          	auipc	ra,0xfffff
    80001bf4:	e84080e7          	jalr	-380(ra) # 80000a74 <kfree>
  p->trapframe = 0;
    80001bf8:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bfc:	68a8                	ld	a0,80(s1)
    80001bfe:	c511                	beqz	a0,80001c0a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c00:	64ac                	ld	a1,72(s1)
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	f8c080e7          	jalr	-116(ra) # 80001b8e <proc_freepagetable>
  if(p->alarm_trapframe)
    80001c0a:	1804b503          	ld	a0,384(s1)
    80001c0e:	c509                	beqz	a0,80001c18 <freeproc+0x38>
    kfree((void*)p->alarm_trapframe);
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	e64080e7          	jalr	-412(ra) # 80000a74 <kfree>
  p->alarm_trapframe = 0;
    80001c18:	1804b023          	sd	zero,384(s1)
  p->alarm_interval = 0;
    80001c1c:	1604a423          	sw	zero,360(s1)
  p->alarm_handler = 0;
    80001c20:	1604b823          	sd	zero,368(s1)
  p->alarm_ticks = 0;
    80001c24:	1604ac23          	sw	zero,376(s1)
  p->alarm_goingoff = 0;
    80001c28:	1804a423          	sw	zero,392(s1)
  p->state = UNUSED;
    80001c2c:	0004ac23          	sw	zero,24(s1)
  p->pagetable = 0;
    80001c30:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c34:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c38:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c3c:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c40:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c44:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c48:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c4c:	0204aa23          	sw	zero,52(s1)
}
    80001c50:	60e2                	ld	ra,24(sp)
    80001c52:	6442                	ld	s0,16(sp)
    80001c54:	64a2                	ld	s1,8(sp)
    80001c56:	6105                	addi	sp,sp,32
    80001c58:	8082                	ret

0000000080001c5a <allocproc>:
{
    80001c5a:	1101                	addi	sp,sp,-32
    80001c5c:	ec06                	sd	ra,24(sp)
    80001c5e:	e822                	sd	s0,16(sp)
    80001c60:	e426                	sd	s1,8(sp)
    80001c62:	e04a                	sd	s2,0(sp)
    80001c64:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c66:	00010497          	auipc	s1,0x10
    80001c6a:	10248493          	addi	s1,s1,258 # 80011d68 <proc>
    80001c6e:	00016917          	auipc	s2,0x16
    80001c72:	4fa90913          	addi	s2,s2,1274 # 80018168 <tickslock>
    acquire(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	fe8080e7          	jalr	-24(ra) # 80000c60 <acquire>
    if(p->state == UNUSED) {
    80001c80:	4c9c                	lw	a5,24(s1)
    80001c82:	cf81                	beqz	a5,80001c9a <allocproc+0x40>
      release(&p->lock);
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	08e080e7          	jalr	142(ra) # 80000d14 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c8e:	19048493          	addi	s1,s1,400
    80001c92:	ff2492e3          	bne	s1,s2,80001c76 <allocproc+0x1c>
  return 0;
    80001c96:	4481                	li	s1,0
    80001c98:	a0bd                	j	80001d06 <allocproc+0xac>
  p->pid = allocpid();
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	e12080e7          	jalr	-494(ra) # 80001aac <allocpid>
    80001ca2:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	ecc080e7          	jalr	-308(ra) # 80000b70 <kalloc>
    80001cac:	892a                	mv	s2,a0
    80001cae:	eca8                	sd	a0,88(s1)
    80001cb0:	c135                	beqz	a0,80001d14 <allocproc+0xba>
  if((p->alarm_trapframe = (struct trapframe *)kalloc()) == 0){
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	ebe080e7          	jalr	-322(ra) # 80000b70 <kalloc>
    80001cba:	892a                	mv	s2,a0
    80001cbc:	18a4b023          	sd	a0,384(s1)
    80001cc0:	c12d                	beqz	a0,80001d22 <allocproc+0xc8>
  p->alarm_interval = 0;
    80001cc2:	1604a423          	sw	zero,360(s1)
  p->alarm_handler = 0;
    80001cc6:	1604b823          	sd	zero,368(s1)
  p->alarm_ticks = 0;
    80001cca:	1604ac23          	sw	zero,376(s1)
  p->alarm_goingoff = 0;
    80001cce:	1804a423          	sw	zero,392(s1)
  p->pagetable = proc_pagetable(p);
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	e1e080e7          	jalr	-482(ra) # 80001af2 <proc_pagetable>
    80001cdc:	892a                	mv	s2,a0
    80001cde:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ce0:	c921                	beqz	a0,80001d30 <allocproc+0xd6>
  memset(&p->context, 0, sizeof(p->context));
    80001ce2:	07000613          	li	a2,112
    80001ce6:	4581                	li	a1,0
    80001ce8:	06048513          	addi	a0,s1,96
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	070080e7          	jalr	112(ra) # 80000d5c <memset>
  p->context.ra = (uint64)forkret;
    80001cf4:	00000797          	auipc	a5,0x0
    80001cf8:	d7278793          	addi	a5,a5,-654 # 80001a66 <forkret>
    80001cfc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cfe:	60bc                	ld	a5,64(s1)
    80001d00:	6705                	lui	a4,0x1
    80001d02:	97ba                	add	a5,a5,a4
    80001d04:	f4bc                	sd	a5,104(s1)
}
    80001d06:	8526                	mv	a0,s1
    80001d08:	60e2                	ld	ra,24(sp)
    80001d0a:	6442                	ld	s0,16(sp)
    80001d0c:	64a2                	ld	s1,8(sp)
    80001d0e:	6902                	ld	s2,0(sp)
    80001d10:	6105                	addi	sp,sp,32
    80001d12:	8082                	ret
    release(&p->lock);
    80001d14:	8526                	mv	a0,s1
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	ffe080e7          	jalr	-2(ra) # 80000d14 <release>
    return 0;
    80001d1e:	84ca                	mv	s1,s2
    80001d20:	b7dd                	j	80001d06 <allocproc+0xac>
    release(&p->lock);
    80001d22:	8526                	mv	a0,s1
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	ff0080e7          	jalr	-16(ra) # 80000d14 <release>
    return 0;
    80001d2c:	84ca                	mv	s1,s2
    80001d2e:	bfe1                	j	80001d06 <allocproc+0xac>
    freeproc(p);
    80001d30:	8526                	mv	a0,s1
    80001d32:	00000097          	auipc	ra,0x0
    80001d36:	eae080e7          	jalr	-338(ra) # 80001be0 <freeproc>
    release(&p->lock);
    80001d3a:	8526                	mv	a0,s1
    80001d3c:	fffff097          	auipc	ra,0xfffff
    80001d40:	fd8080e7          	jalr	-40(ra) # 80000d14 <release>
    return 0;
    80001d44:	84ca                	mv	s1,s2
    80001d46:	b7c1                	j	80001d06 <allocproc+0xac>

0000000080001d48 <userinit>:
{
    80001d48:	1101                	addi	sp,sp,-32
    80001d4a:	ec06                	sd	ra,24(sp)
    80001d4c:	e822                	sd	s0,16(sp)
    80001d4e:	e426                	sd	s1,8(sp)
    80001d50:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	f08080e7          	jalr	-248(ra) # 80001c5a <allocproc>
    80001d5a:	84aa                	mv	s1,a0
  initproc = p;
    80001d5c:	00007797          	auipc	a5,0x7
    80001d60:	2aa7be23          	sd	a0,700(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d64:	03400613          	li	a2,52
    80001d68:	00007597          	auipc	a1,0x7
    80001d6c:	ad858593          	addi	a1,a1,-1320 # 80008840 <initcode>
    80001d70:	6928                	ld	a0,80(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	6a6080e7          	jalr	1702(ra) # 80001418 <uvminit>
  p->sz = PGSIZE;
    80001d7a:	6785                	lui	a5,0x1
    80001d7c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d7e:	6cb8                	ld	a4,88(s1)
    80001d80:	00073c23          	sd	zero,24(a4) # 1018 <spin-0x7ffff002>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d84:	6cb8                	ld	a4,88(s1)
    80001d86:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d88:	4641                	li	a2,16
    80001d8a:	00006597          	auipc	a1,0x6
    80001d8e:	46658593          	addi	a1,a1,1126 # 800081f0 <digits+0x1a8>
    80001d92:	15848513          	addi	a0,s1,344
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	11c080e7          	jalr	284(ra) # 80000eb2 <safestrcpy>
  p->cwd = namei("/");
    80001d9e:	00006517          	auipc	a0,0x6
    80001da2:	46250513          	addi	a0,a0,1122 # 80008200 <digits+0x1b8>
    80001da6:	00002097          	auipc	ra,0x2
    80001daa:	1e8080e7          	jalr	488(ra) # 80003f8e <namei>
    80001dae:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001db2:	4789                	li	a5,2
    80001db4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001db6:	8526                	mv	a0,s1
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	f5c080e7          	jalr	-164(ra) # 80000d14 <release>
}
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6105                	addi	sp,sp,32
    80001dc8:	8082                	ret

0000000080001dca <growproc>:
{
    80001dca:	1101                	addi	sp,sp,-32
    80001dcc:	ec06                	sd	ra,24(sp)
    80001dce:	e822                	sd	s0,16(sp)
    80001dd0:	e426                	sd	s1,8(sp)
    80001dd2:	e04a                	sd	s2,0(sp)
    80001dd4:	1000                	addi	s0,sp,32
    80001dd6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	c56080e7          	jalr	-938(ra) # 80001a2e <myproc>
    80001de0:	892a                	mv	s2,a0
  sz = p->sz;
    80001de2:	652c                	ld	a1,72(a0)
    80001de4:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001de8:	00904f63          	bgtz	s1,80001e06 <growproc+0x3c>
  } else if(n < 0){
    80001dec:	0204cc63          	bltz	s1,80001e24 <growproc+0x5a>
  p->sz = sz;
    80001df0:	1602                	slli	a2,a2,0x20
    80001df2:	9201                	srli	a2,a2,0x20
    80001df4:	04c93423          	sd	a2,72(s2)
  return 0;
    80001df8:	4501                	li	a0,0
}
    80001dfa:	60e2                	ld	ra,24(sp)
    80001dfc:	6442                	ld	s0,16(sp)
    80001dfe:	64a2                	ld	s1,8(sp)
    80001e00:	6902                	ld	s2,0(sp)
    80001e02:	6105                	addi	sp,sp,32
    80001e04:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e06:	9e25                	addw	a2,a2,s1
    80001e08:	1602                	slli	a2,a2,0x20
    80001e0a:	9201                	srli	a2,a2,0x20
    80001e0c:	1582                	slli	a1,a1,0x20
    80001e0e:	9181                	srli	a1,a1,0x20
    80001e10:	6928                	ld	a0,80(a0)
    80001e12:	fffff097          	auipc	ra,0xfffff
    80001e16:	6c0080e7          	jalr	1728(ra) # 800014d2 <uvmalloc>
    80001e1a:	0005061b          	sext.w	a2,a0
    80001e1e:	fa69                	bnez	a2,80001df0 <growproc+0x26>
      return -1;
    80001e20:	557d                	li	a0,-1
    80001e22:	bfe1                	j	80001dfa <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e24:	9e25                	addw	a2,a2,s1
    80001e26:	1602                	slli	a2,a2,0x20
    80001e28:	9201                	srli	a2,a2,0x20
    80001e2a:	1582                	slli	a1,a1,0x20
    80001e2c:	9181                	srli	a1,a1,0x20
    80001e2e:	6928                	ld	a0,80(a0)
    80001e30:	fffff097          	auipc	ra,0xfffff
    80001e34:	65a080e7          	jalr	1626(ra) # 8000148a <uvmdealloc>
    80001e38:	0005061b          	sext.w	a2,a0
    80001e3c:	bf55                	j	80001df0 <growproc+0x26>

0000000080001e3e <fork>:
{
    80001e3e:	7179                	addi	sp,sp,-48
    80001e40:	f406                	sd	ra,40(sp)
    80001e42:	f022                	sd	s0,32(sp)
    80001e44:	ec26                	sd	s1,24(sp)
    80001e46:	e84a                	sd	s2,16(sp)
    80001e48:	e44e                	sd	s3,8(sp)
    80001e4a:	e052                	sd	s4,0(sp)
    80001e4c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	be0080e7          	jalr	-1056(ra) # 80001a2e <myproc>
    80001e56:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e58:	00000097          	auipc	ra,0x0
    80001e5c:	e02080e7          	jalr	-510(ra) # 80001c5a <allocproc>
    80001e60:	c175                	beqz	a0,80001f44 <fork+0x106>
    80001e62:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e64:	04893603          	ld	a2,72(s2)
    80001e68:	692c                	ld	a1,80(a0)
    80001e6a:	05093503          	ld	a0,80(s2)
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	7b0080e7          	jalr	1968(ra) # 8000161e <uvmcopy>
    80001e76:	04054863          	bltz	a0,80001ec6 <fork+0x88>
  np->sz = p->sz;
    80001e7a:	04893783          	ld	a5,72(s2)
    80001e7e:	04f9b423          	sd	a5,72(s3) # 4000048 <spin-0x7bffffd2>
  np->parent = p;
    80001e82:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e86:	05893683          	ld	a3,88(s2)
    80001e8a:	87b6                	mv	a5,a3
    80001e8c:	0589b703          	ld	a4,88(s3)
    80001e90:	12068693          	addi	a3,a3,288
    80001e94:	0007b803          	ld	a6,0(a5) # 1000 <spin-0x7ffff01a>
    80001e98:	6788                	ld	a0,8(a5)
    80001e9a:	6b8c                	ld	a1,16(a5)
    80001e9c:	6f90                	ld	a2,24(a5)
    80001e9e:	01073023          	sd	a6,0(a4)
    80001ea2:	e708                	sd	a0,8(a4)
    80001ea4:	eb0c                	sd	a1,16(a4)
    80001ea6:	ef10                	sd	a2,24(a4)
    80001ea8:	02078793          	addi	a5,a5,32
    80001eac:	02070713          	addi	a4,a4,32
    80001eb0:	fed792e3          	bne	a5,a3,80001e94 <fork+0x56>
  np->trapframe->a0 = 0;
    80001eb4:	0589b783          	ld	a5,88(s3)
    80001eb8:	0607b823          	sd	zero,112(a5)
    80001ebc:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ec0:	15000a13          	li	s4,336
    80001ec4:	a03d                	j	80001ef2 <fork+0xb4>
    freeproc(np);
    80001ec6:	854e                	mv	a0,s3
    80001ec8:	00000097          	auipc	ra,0x0
    80001ecc:	d18080e7          	jalr	-744(ra) # 80001be0 <freeproc>
    release(&np->lock);
    80001ed0:	854e                	mv	a0,s3
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	e42080e7          	jalr	-446(ra) # 80000d14 <release>
    return -1;
    80001eda:	54fd                	li	s1,-1
    80001edc:	a899                	j	80001f32 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ede:	00002097          	auipc	ra,0x2
    80001ee2:	73c080e7          	jalr	1852(ra) # 8000461a <filedup>
    80001ee6:	009987b3          	add	a5,s3,s1
    80001eea:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001eec:	04a1                	addi	s1,s1,8
    80001eee:	01448763          	beq	s1,s4,80001efc <fork+0xbe>
    if(p->ofile[i])
    80001ef2:	009907b3          	add	a5,s2,s1
    80001ef6:	6388                	ld	a0,0(a5)
    80001ef8:	f17d                	bnez	a0,80001ede <fork+0xa0>
    80001efa:	bfcd                	j	80001eec <fork+0xae>
  np->cwd = idup(p->cwd);
    80001efc:	15093503          	ld	a0,336(s2)
    80001f00:	00002097          	auipc	ra,0x2
    80001f04:	8a0080e7          	jalr	-1888(ra) # 800037a0 <idup>
    80001f08:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f0c:	4641                	li	a2,16
    80001f0e:	15890593          	addi	a1,s2,344
    80001f12:	15898513          	addi	a0,s3,344
    80001f16:	fffff097          	auipc	ra,0xfffff
    80001f1a:	f9c080e7          	jalr	-100(ra) # 80000eb2 <safestrcpy>
  pid = np->pid;
    80001f1e:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f22:	4789                	li	a5,2
    80001f24:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f28:	854e                	mv	a0,s3
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	dea080e7          	jalr	-534(ra) # 80000d14 <release>
}
    80001f32:	8526                	mv	a0,s1
    80001f34:	70a2                	ld	ra,40(sp)
    80001f36:	7402                	ld	s0,32(sp)
    80001f38:	64e2                	ld	s1,24(sp)
    80001f3a:	6942                	ld	s2,16(sp)
    80001f3c:	69a2                	ld	s3,8(sp)
    80001f3e:	6a02                	ld	s4,0(sp)
    80001f40:	6145                	addi	sp,sp,48
    80001f42:	8082                	ret
    return -1;
    80001f44:	54fd                	li	s1,-1
    80001f46:	b7f5                	j	80001f32 <fork+0xf4>

0000000080001f48 <reparent>:
{
    80001f48:	7179                	addi	sp,sp,-48
    80001f4a:	f406                	sd	ra,40(sp)
    80001f4c:	f022                	sd	s0,32(sp)
    80001f4e:	ec26                	sd	s1,24(sp)
    80001f50:	e84a                	sd	s2,16(sp)
    80001f52:	e44e                	sd	s3,8(sp)
    80001f54:	e052                	sd	s4,0(sp)
    80001f56:	1800                	addi	s0,sp,48
    80001f58:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f5a:	00010497          	auipc	s1,0x10
    80001f5e:	e0e48493          	addi	s1,s1,-498 # 80011d68 <proc>
      pp->parent = initproc;
    80001f62:	00007a17          	auipc	s4,0x7
    80001f66:	0b6a0a13          	addi	s4,s4,182 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f6a:	00016997          	auipc	s3,0x16
    80001f6e:	1fe98993          	addi	s3,s3,510 # 80018168 <tickslock>
    80001f72:	a029                	j	80001f7c <reparent+0x34>
    80001f74:	19048493          	addi	s1,s1,400
    80001f78:	03348363          	beq	s1,s3,80001f9e <reparent+0x56>
    if(pp->parent == p){
    80001f7c:	709c                	ld	a5,32(s1)
    80001f7e:	ff279be3          	bne	a5,s2,80001f74 <reparent+0x2c>
      acquire(&pp->lock);
    80001f82:	8526                	mv	a0,s1
    80001f84:	fffff097          	auipc	ra,0xfffff
    80001f88:	cdc080e7          	jalr	-804(ra) # 80000c60 <acquire>
      pp->parent = initproc;
    80001f8c:	000a3783          	ld	a5,0(s4)
    80001f90:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	d80080e7          	jalr	-640(ra) # 80000d14 <release>
    80001f9c:	bfe1                	j	80001f74 <reparent+0x2c>
}
    80001f9e:	70a2                	ld	ra,40(sp)
    80001fa0:	7402                	ld	s0,32(sp)
    80001fa2:	64e2                	ld	s1,24(sp)
    80001fa4:	6942                	ld	s2,16(sp)
    80001fa6:	69a2                	ld	s3,8(sp)
    80001fa8:	6a02                	ld	s4,0(sp)
    80001faa:	6145                	addi	sp,sp,48
    80001fac:	8082                	ret

0000000080001fae <sigalarm>:
{
    80001fae:	1101                	addi	sp,sp,-32
    80001fb0:	ec06                	sd	ra,24(sp)
    80001fb2:	e822                	sd	s0,16(sp)
    80001fb4:	e426                	sd	s1,8(sp)
    80001fb6:	e04a                	sd	s2,0(sp)
    80001fb8:	1000                	addi	s0,sp,32
    80001fba:	892a                	mv	s2,a0
    80001fbc:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	a70080e7          	jalr	-1424(ra) # 80001a2e <myproc>
  p->alarm_interval = ticks;
    80001fc6:	17252423          	sw	s2,360(a0)
  p->alarm_handler = handler;
    80001fca:	16953823          	sd	s1,368(a0)
  p->alarm_ticks = 0;
    80001fce:	16052c23          	sw	zero,376(a0)
}
    80001fd2:	4501                	li	a0,0
    80001fd4:	60e2                	ld	ra,24(sp)
    80001fd6:	6442                	ld	s0,16(sp)
    80001fd8:	64a2                	ld	s1,8(sp)
    80001fda:	6902                	ld	s2,0(sp)
    80001fdc:	6105                	addi	sp,sp,32
    80001fde:	8082                	ret

0000000080001fe0 <sigreturn>:
{
    80001fe0:	1101                	addi	sp,sp,-32
    80001fe2:	ec06                	sd	ra,24(sp)
    80001fe4:	e822                	sd	s0,16(sp)
    80001fe6:	e426                	sd	s1,8(sp)
    80001fe8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001fea:	00000097          	auipc	ra,0x0
    80001fee:	a44080e7          	jalr	-1468(ra) # 80001a2e <myproc>
  if(p->alarm_trapframe){
    80001ff2:	18053583          	ld	a1,384(a0)
    80001ff6:	c999                	beqz	a1,8000200c <sigreturn+0x2c>
    80001ff8:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_trapframe, sizeof(struct trapframe));
    80001ffa:	12000613          	li	a2,288
    80001ffe:	6d28                	ld	a0,88(a0)
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	dbc080e7          	jalr	-580(ra) # 80000dbc <memmove>
    p->alarm_goingoff = 0;
    80002008:	1804a423          	sw	zero,392(s1)
}
    8000200c:	4501                	li	a0,0
    8000200e:	60e2                	ld	ra,24(sp)
    80002010:	6442                	ld	s0,16(sp)
    80002012:	64a2                	ld	s1,8(sp)
    80002014:	6105                	addi	sp,sp,32
    80002016:	8082                	ret

0000000080002018 <scheduler>:
{
    80002018:	715d                	addi	sp,sp,-80
    8000201a:	e486                	sd	ra,72(sp)
    8000201c:	e0a2                	sd	s0,64(sp)
    8000201e:	fc26                	sd	s1,56(sp)
    80002020:	f84a                	sd	s2,48(sp)
    80002022:	f44e                	sd	s3,40(sp)
    80002024:	f052                	sd	s4,32(sp)
    80002026:	ec56                	sd	s5,24(sp)
    80002028:	e85a                	sd	s6,16(sp)
    8000202a:	e45e                	sd	s7,8(sp)
    8000202c:	e062                	sd	s8,0(sp)
    8000202e:	0880                	addi	s0,sp,80
    80002030:	8792                	mv	a5,tp
  int id = r_tp();
    80002032:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002034:	00779b13          	slli	s6,a5,0x7
    80002038:	00010717          	auipc	a4,0x10
    8000203c:	91870713          	addi	a4,a4,-1768 # 80011950 <pid_lock>
    80002040:	975a                	add	a4,a4,s6
    80002042:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002046:	00010717          	auipc	a4,0x10
    8000204a:	92a70713          	addi	a4,a4,-1750 # 80011970 <cpus+0x8>
    8000204e:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80002050:	4c0d                	li	s8,3
        c->proc = p;
    80002052:	079e                	slli	a5,a5,0x7
    80002054:	00010a17          	auipc	s4,0x10
    80002058:	8fca0a13          	addi	s4,s4,-1796 # 80011950 <pid_lock>
    8000205c:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000205e:	00016997          	auipc	s3,0x16
    80002062:	10a98993          	addi	s3,s3,266 # 80018168 <tickslock>
        found = 1;
    80002066:	4b85                	li	s7,1
    80002068:	a899                	j	800020be <scheduler+0xa6>
        p->state = RUNNING;
    8000206a:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    8000206e:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80002072:	06048593          	addi	a1,s1,96
    80002076:	855a                	mv	a0,s6
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	638080e7          	jalr	1592(ra) # 800026b0 <swtch>
        c->proc = 0;
    80002080:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80002084:	8ade                	mv	s5,s7
      release(&p->lock);
    80002086:	8526                	mv	a0,s1
    80002088:	fffff097          	auipc	ra,0xfffff
    8000208c:	c8c080e7          	jalr	-884(ra) # 80000d14 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002090:	19048493          	addi	s1,s1,400
    80002094:	01348b63          	beq	s1,s3,800020aa <scheduler+0x92>
      acquire(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bc6080e7          	jalr	-1082(ra) # 80000c60 <acquire>
      if(p->state == RUNNABLE) {
    800020a2:	4c9c                	lw	a5,24(s1)
    800020a4:	ff2791e3          	bne	a5,s2,80002086 <scheduler+0x6e>
    800020a8:	b7c9                	j	8000206a <scheduler+0x52>
    if(found == 0) {
    800020aa:	000a9a63          	bnez	s5,800020be <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020b2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020b6:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020ba:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020c2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020c6:	10079073          	csrw	sstatus,a5
    int found = 0;
    800020ca:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	00010497          	auipc	s1,0x10
    800020d0:	c9c48493          	addi	s1,s1,-868 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    800020d4:	4909                	li	s2,2
    800020d6:	b7c9                	j	80002098 <scheduler+0x80>

00000000800020d8 <sched>:
{
    800020d8:	7179                	addi	sp,sp,-48
    800020da:	f406                	sd	ra,40(sp)
    800020dc:	f022                	sd	s0,32(sp)
    800020de:	ec26                	sd	s1,24(sp)
    800020e0:	e84a                	sd	s2,16(sp)
    800020e2:	e44e                	sd	s3,8(sp)
    800020e4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020e6:	00000097          	auipc	ra,0x0
    800020ea:	948080e7          	jalr	-1720(ra) # 80001a2e <myproc>
    800020ee:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	af6080e7          	jalr	-1290(ra) # 80000be6 <holding>
    800020f8:	c93d                	beqz	a0,8000216e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fa:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020fc:	2781                	sext.w	a5,a5
    800020fe:	079e                	slli	a5,a5,0x7
    80002100:	00010717          	auipc	a4,0x10
    80002104:	85070713          	addi	a4,a4,-1968 # 80011950 <pid_lock>
    80002108:	97ba                	add	a5,a5,a4
    8000210a:	0907a703          	lw	a4,144(a5)
    8000210e:	4785                	li	a5,1
    80002110:	06f71763          	bne	a4,a5,8000217e <sched+0xa6>
  if(p->state == RUNNING)
    80002114:	4c98                	lw	a4,24(s1)
    80002116:	478d                	li	a5,3
    80002118:	06f70b63          	beq	a4,a5,8000218e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000211c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002120:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002122:	efb5                	bnez	a5,8000219e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002124:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002126:	00010917          	auipc	s2,0x10
    8000212a:	82a90913          	addi	s2,s2,-2006 # 80011950 <pid_lock>
    8000212e:	2781                	sext.w	a5,a5
    80002130:	079e                	slli	a5,a5,0x7
    80002132:	97ca                	add	a5,a5,s2
    80002134:	0947a983          	lw	s3,148(a5)
    80002138:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000213a:	2781                	sext.w	a5,a5
    8000213c:	079e                	slli	a5,a5,0x7
    8000213e:	00010597          	auipc	a1,0x10
    80002142:	83258593          	addi	a1,a1,-1998 # 80011970 <cpus+0x8>
    80002146:	95be                	add	a1,a1,a5
    80002148:	06048513          	addi	a0,s1,96
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	564080e7          	jalr	1380(ra) # 800026b0 <swtch>
    80002154:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002156:	2781                	sext.w	a5,a5
    80002158:	079e                	slli	a5,a5,0x7
    8000215a:	97ca                	add	a5,a5,s2
    8000215c:	0937aa23          	sw	s3,148(a5)
}
    80002160:	70a2                	ld	ra,40(sp)
    80002162:	7402                	ld	s0,32(sp)
    80002164:	64e2                	ld	s1,24(sp)
    80002166:	6942                	ld	s2,16(sp)
    80002168:	69a2                	ld	s3,8(sp)
    8000216a:	6145                	addi	sp,sp,48
    8000216c:	8082                	ret
    panic("sched p->lock");
    8000216e:	00006517          	auipc	a0,0x6
    80002172:	09a50513          	addi	a0,a0,154 # 80008208 <digits+0x1c0>
    80002176:	ffffe097          	auipc	ra,0xffffe
    8000217a:	3c6080e7          	jalr	966(ra) # 8000053c <panic>
    panic("sched locks");
    8000217e:	00006517          	auipc	a0,0x6
    80002182:	09a50513          	addi	a0,a0,154 # 80008218 <digits+0x1d0>
    80002186:	ffffe097          	auipc	ra,0xffffe
    8000218a:	3b6080e7          	jalr	950(ra) # 8000053c <panic>
    panic("sched running");
    8000218e:	00006517          	auipc	a0,0x6
    80002192:	09a50513          	addi	a0,a0,154 # 80008228 <digits+0x1e0>
    80002196:	ffffe097          	auipc	ra,0xffffe
    8000219a:	3a6080e7          	jalr	934(ra) # 8000053c <panic>
    panic("sched interruptible");
    8000219e:	00006517          	auipc	a0,0x6
    800021a2:	09a50513          	addi	a0,a0,154 # 80008238 <digits+0x1f0>
    800021a6:	ffffe097          	auipc	ra,0xffffe
    800021aa:	396080e7          	jalr	918(ra) # 8000053c <panic>

00000000800021ae <exit>:
{
    800021ae:	7179                	addi	sp,sp,-48
    800021b0:	f406                	sd	ra,40(sp)
    800021b2:	f022                	sd	s0,32(sp)
    800021b4:	ec26                	sd	s1,24(sp)
    800021b6:	e84a                	sd	s2,16(sp)
    800021b8:	e44e                	sd	s3,8(sp)
    800021ba:	e052                	sd	s4,0(sp)
    800021bc:	1800                	addi	s0,sp,48
    800021be:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021c0:	00000097          	auipc	ra,0x0
    800021c4:	86e080e7          	jalr	-1938(ra) # 80001a2e <myproc>
    800021c8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ca:	00007797          	auipc	a5,0x7
    800021ce:	e4e7b783          	ld	a5,-434(a5) # 80009018 <initproc>
    800021d2:	0d050493          	addi	s1,a0,208
    800021d6:	15050913          	addi	s2,a0,336
    800021da:	02a79363          	bne	a5,a0,80002200 <exit+0x52>
    panic("init exiting");
    800021de:	00006517          	auipc	a0,0x6
    800021e2:	07250513          	addi	a0,a0,114 # 80008250 <digits+0x208>
    800021e6:	ffffe097          	auipc	ra,0xffffe
    800021ea:	356080e7          	jalr	854(ra) # 8000053c <panic>
      fileclose(f);
    800021ee:	00002097          	auipc	ra,0x2
    800021f2:	47e080e7          	jalr	1150(ra) # 8000466c <fileclose>
      p->ofile[fd] = 0;
    800021f6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021fa:	04a1                	addi	s1,s1,8
    800021fc:	01248563          	beq	s1,s2,80002206 <exit+0x58>
    if(p->ofile[fd]){
    80002200:	6088                	ld	a0,0(s1)
    80002202:	f575                	bnez	a0,800021ee <exit+0x40>
    80002204:	bfdd                	j	800021fa <exit+0x4c>
  begin_op();
    80002206:	00002097          	auipc	ra,0x2
    8000220a:	f94080e7          	jalr	-108(ra) # 8000419a <begin_op>
  iput(p->cwd);
    8000220e:	1509b503          	ld	a0,336(s3)
    80002212:	00001097          	auipc	ra,0x1
    80002216:	786080e7          	jalr	1926(ra) # 80003998 <iput>
  end_op();
    8000221a:	00002097          	auipc	ra,0x2
    8000221e:	000080e7          	jalr	ra # 8000421a <end_op>
  p->cwd = 0;
    80002222:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002226:	00007497          	auipc	s1,0x7
    8000222a:	df248493          	addi	s1,s1,-526 # 80009018 <initproc>
    8000222e:	6088                	ld	a0,0(s1)
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	a30080e7          	jalr	-1488(ra) # 80000c60 <acquire>
  wakeup1(initproc);
    80002238:	6088                	ld	a0,0(s1)
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	6b4080e7          	jalr	1716(ra) # 800018ee <wakeup1>
  release(&initproc->lock);
    80002242:	6088                	ld	a0,0(s1)
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	ad0080e7          	jalr	-1328(ra) # 80000d14 <release>
  acquire(&p->lock);
    8000224c:	854e                	mv	a0,s3
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	a12080e7          	jalr	-1518(ra) # 80000c60 <acquire>
  struct proc *original_parent = p->parent;
    80002256:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000225a:	854e                	mv	a0,s3
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	ab8080e7          	jalr	-1352(ra) # 80000d14 <release>
  acquire(&original_parent->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	9fa080e7          	jalr	-1542(ra) # 80000c60 <acquire>
  acquire(&p->lock);
    8000226e:	854e                	mv	a0,s3
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	9f0080e7          	jalr	-1552(ra) # 80000c60 <acquire>
  reparent(p);
    80002278:	854e                	mv	a0,s3
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	cce080e7          	jalr	-818(ra) # 80001f48 <reparent>
  wakeup1(original_parent);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	66a080e7          	jalr	1642(ra) # 800018ee <wakeup1>
  p->xstate = status;
    8000228c:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002290:	4791                	li	a5,4
    80002292:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	a7c080e7          	jalr	-1412(ra) # 80000d14 <release>
  sched();
    800022a0:	00000097          	auipc	ra,0x0
    800022a4:	e38080e7          	jalr	-456(ra) # 800020d8 <sched>
  panic("zombie exit");
    800022a8:	00006517          	auipc	a0,0x6
    800022ac:	fb850513          	addi	a0,a0,-72 # 80008260 <digits+0x218>
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	28c080e7          	jalr	652(ra) # 8000053c <panic>

00000000800022b8 <yield>:
{
    800022b8:	1101                	addi	sp,sp,-32
    800022ba:	ec06                	sd	ra,24(sp)
    800022bc:	e822                	sd	s0,16(sp)
    800022be:	e426                	sd	s1,8(sp)
    800022c0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	76c080e7          	jalr	1900(ra) # 80001a2e <myproc>
    800022ca:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	994080e7          	jalr	-1644(ra) # 80000c60 <acquire>
  p->state = RUNNABLE;
    800022d4:	4789                	li	a5,2
    800022d6:	cc9c                	sw	a5,24(s1)
  sched();
    800022d8:	00000097          	auipc	ra,0x0
    800022dc:	e00080e7          	jalr	-512(ra) # 800020d8 <sched>
  release(&p->lock);
    800022e0:	8526                	mv	a0,s1
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	a32080e7          	jalr	-1486(ra) # 80000d14 <release>
}
    800022ea:	60e2                	ld	ra,24(sp)
    800022ec:	6442                	ld	s0,16(sp)
    800022ee:	64a2                	ld	s1,8(sp)
    800022f0:	6105                	addi	sp,sp,32
    800022f2:	8082                	ret

00000000800022f4 <sleep>:
{
    800022f4:	7179                	addi	sp,sp,-48
    800022f6:	f406                	sd	ra,40(sp)
    800022f8:	f022                	sd	s0,32(sp)
    800022fa:	ec26                	sd	s1,24(sp)
    800022fc:	e84a                	sd	s2,16(sp)
    800022fe:	e44e                	sd	s3,8(sp)
    80002300:	1800                	addi	s0,sp,48
    80002302:	89aa                	mv	s3,a0
    80002304:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	728080e7          	jalr	1832(ra) # 80001a2e <myproc>
    8000230e:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002310:	05250663          	beq	a0,s2,8000235c <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	94c080e7          	jalr	-1716(ra) # 80000c60 <acquire>
    release(lk);
    8000231c:	854a                	mv	a0,s2
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	9f6080e7          	jalr	-1546(ra) # 80000d14 <release>
  p->chan = chan;
    80002326:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000232a:	4785                	li	a5,1
    8000232c:	cc9c                	sw	a5,24(s1)
  sched();
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	daa080e7          	jalr	-598(ra) # 800020d8 <sched>
  p->chan = 0;
    80002336:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000233a:	8526                	mv	a0,s1
    8000233c:	fffff097          	auipc	ra,0xfffff
    80002340:	9d8080e7          	jalr	-1576(ra) # 80000d14 <release>
    acquire(lk);
    80002344:	854a                	mv	a0,s2
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	91a080e7          	jalr	-1766(ra) # 80000c60 <acquire>
}
    8000234e:	70a2                	ld	ra,40(sp)
    80002350:	7402                	ld	s0,32(sp)
    80002352:	64e2                	ld	s1,24(sp)
    80002354:	6942                	ld	s2,16(sp)
    80002356:	69a2                	ld	s3,8(sp)
    80002358:	6145                	addi	sp,sp,48
    8000235a:	8082                	ret
  p->chan = chan;
    8000235c:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002360:	4785                	li	a5,1
    80002362:	cd1c                	sw	a5,24(a0)
  sched();
    80002364:	00000097          	auipc	ra,0x0
    80002368:	d74080e7          	jalr	-652(ra) # 800020d8 <sched>
  p->chan = 0;
    8000236c:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002370:	bff9                	j	8000234e <sleep+0x5a>

0000000080002372 <wait>:
{
    80002372:	715d                	addi	sp,sp,-80
    80002374:	e486                	sd	ra,72(sp)
    80002376:	e0a2                	sd	s0,64(sp)
    80002378:	fc26                	sd	s1,56(sp)
    8000237a:	f84a                	sd	s2,48(sp)
    8000237c:	f44e                	sd	s3,40(sp)
    8000237e:	f052                	sd	s4,32(sp)
    80002380:	ec56                	sd	s5,24(sp)
    80002382:	e85a                	sd	s6,16(sp)
    80002384:	e45e                	sd	s7,8(sp)
    80002386:	e062                	sd	s8,0(sp)
    80002388:	0880                	addi	s0,sp,80
    8000238a:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	6a2080e7          	jalr	1698(ra) # 80001a2e <myproc>
    80002394:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002396:	8c2a                	mv	s8,a0
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	8c8080e7          	jalr	-1848(ra) # 80000c60 <acquire>
    havekids = 0;
    800023a0:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023a2:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800023a4:	00016997          	auipc	s3,0x16
    800023a8:	dc498993          	addi	s3,s3,-572 # 80018168 <tickslock>
        havekids = 1;
    800023ac:	4a85                	li	s5,1
    havekids = 0;
    800023ae:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023b0:	00010497          	auipc	s1,0x10
    800023b4:	9b848493          	addi	s1,s1,-1608 # 80011d68 <proc>
    800023b8:	a08d                	j	8000241a <wait+0xa8>
          pid = np->pid;
    800023ba:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023be:	000b0e63          	beqz	s6,800023da <wait+0x68>
    800023c2:	4691                	li	a3,4
    800023c4:	03448613          	addi	a2,s1,52
    800023c8:	85da                	mv	a1,s6
    800023ca:	05093503          	ld	a0,80(s2)
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	354080e7          	jalr	852(ra) # 80001722 <copyout>
    800023d6:	02054263          	bltz	a0,800023fa <wait+0x88>
          freeproc(np);
    800023da:	8526                	mv	a0,s1
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	804080e7          	jalr	-2044(ra) # 80001be0 <freeproc>
          release(&np->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	92e080e7          	jalr	-1746(ra) # 80000d14 <release>
          release(&p->lock);
    800023ee:	854a                	mv	a0,s2
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	924080e7          	jalr	-1756(ra) # 80000d14 <release>
          return pid;
    800023f8:	a8a9                	j	80002452 <wait+0xe0>
            release(&np->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	918080e7          	jalr	-1768(ra) # 80000d14 <release>
            release(&p->lock);
    80002404:	854a                	mv	a0,s2
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	90e080e7          	jalr	-1778(ra) # 80000d14 <release>
            return -1;
    8000240e:	59fd                	li	s3,-1
    80002410:	a089                	j	80002452 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002412:	19048493          	addi	s1,s1,400
    80002416:	03348463          	beq	s1,s3,8000243e <wait+0xcc>
      if(np->parent == p){
    8000241a:	709c                	ld	a5,32(s1)
    8000241c:	ff279be3          	bne	a5,s2,80002412 <wait+0xa0>
        acquire(&np->lock);
    80002420:	8526                	mv	a0,s1
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	83e080e7          	jalr	-1986(ra) # 80000c60 <acquire>
        if(np->state == ZOMBIE){
    8000242a:	4c9c                	lw	a5,24(s1)
    8000242c:	f94787e3          	beq	a5,s4,800023ba <wait+0x48>
        release(&np->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	fffff097          	auipc	ra,0xfffff
    80002436:	8e2080e7          	jalr	-1822(ra) # 80000d14 <release>
        havekids = 1;
    8000243a:	8756                	mv	a4,s5
    8000243c:	bfd9                	j	80002412 <wait+0xa0>
    if(!havekids || p->killed){
    8000243e:	c701                	beqz	a4,80002446 <wait+0xd4>
    80002440:	03092783          	lw	a5,48(s2)
    80002444:	c785                	beqz	a5,8000246c <wait+0xfa>
      release(&p->lock);
    80002446:	854a                	mv	a0,s2
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	8cc080e7          	jalr	-1844(ra) # 80000d14 <release>
      return -1;
    80002450:	59fd                	li	s3,-1
}
    80002452:	854e                	mv	a0,s3
    80002454:	60a6                	ld	ra,72(sp)
    80002456:	6406                	ld	s0,64(sp)
    80002458:	74e2                	ld	s1,56(sp)
    8000245a:	7942                	ld	s2,48(sp)
    8000245c:	79a2                	ld	s3,40(sp)
    8000245e:	7a02                	ld	s4,32(sp)
    80002460:	6ae2                	ld	s5,24(sp)
    80002462:	6b42                	ld	s6,16(sp)
    80002464:	6ba2                	ld	s7,8(sp)
    80002466:	6c02                	ld	s8,0(sp)
    80002468:	6161                	addi	sp,sp,80
    8000246a:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000246c:	85e2                	mv	a1,s8
    8000246e:	854a                	mv	a0,s2
    80002470:	00000097          	auipc	ra,0x0
    80002474:	e84080e7          	jalr	-380(ra) # 800022f4 <sleep>
    havekids = 0;
    80002478:	bf1d                	j	800023ae <wait+0x3c>

000000008000247a <wakeup>:
{
    8000247a:	7139                	addi	sp,sp,-64
    8000247c:	fc06                	sd	ra,56(sp)
    8000247e:	f822                	sd	s0,48(sp)
    80002480:	f426                	sd	s1,40(sp)
    80002482:	f04a                	sd	s2,32(sp)
    80002484:	ec4e                	sd	s3,24(sp)
    80002486:	e852                	sd	s4,16(sp)
    80002488:	e456                	sd	s5,8(sp)
    8000248a:	0080                	addi	s0,sp,64
    8000248c:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000248e:	00010497          	auipc	s1,0x10
    80002492:	8da48493          	addi	s1,s1,-1830 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002496:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002498:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000249a:	00016917          	auipc	s2,0x16
    8000249e:	cce90913          	addi	s2,s2,-818 # 80018168 <tickslock>
    800024a2:	a821                	j	800024ba <wakeup+0x40>
      p->state = RUNNABLE;
    800024a4:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800024a8:	8526                	mv	a0,s1
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	86a080e7          	jalr	-1942(ra) # 80000d14 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024b2:	19048493          	addi	s1,s1,400
    800024b6:	01248e63          	beq	s1,s2,800024d2 <wakeup+0x58>
    acquire(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7a4080e7          	jalr	1956(ra) # 80000c60 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800024c4:	4c9c                	lw	a5,24(s1)
    800024c6:	ff3791e3          	bne	a5,s3,800024a8 <wakeup+0x2e>
    800024ca:	749c                	ld	a5,40(s1)
    800024cc:	fd479ee3          	bne	a5,s4,800024a8 <wakeup+0x2e>
    800024d0:	bfd1                	j	800024a4 <wakeup+0x2a>
}
    800024d2:	70e2                	ld	ra,56(sp)
    800024d4:	7442                	ld	s0,48(sp)
    800024d6:	74a2                	ld	s1,40(sp)
    800024d8:	7902                	ld	s2,32(sp)
    800024da:	69e2                	ld	s3,24(sp)
    800024dc:	6a42                	ld	s4,16(sp)
    800024de:	6aa2                	ld	s5,8(sp)
    800024e0:	6121                	addi	sp,sp,64
    800024e2:	8082                	ret

00000000800024e4 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024e4:	7179                	addi	sp,sp,-48
    800024e6:	f406                	sd	ra,40(sp)
    800024e8:	f022                	sd	s0,32(sp)
    800024ea:	ec26                	sd	s1,24(sp)
    800024ec:	e84a                	sd	s2,16(sp)
    800024ee:	e44e                	sd	s3,8(sp)
    800024f0:	1800                	addi	s0,sp,48
    800024f2:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024f4:	00010497          	auipc	s1,0x10
    800024f8:	87448493          	addi	s1,s1,-1932 # 80011d68 <proc>
    800024fc:	00016997          	auipc	s3,0x16
    80002500:	c6c98993          	addi	s3,s3,-916 # 80018168 <tickslock>
    acquire(&p->lock);
    80002504:	8526                	mv	a0,s1
    80002506:	ffffe097          	auipc	ra,0xffffe
    8000250a:	75a080e7          	jalr	1882(ra) # 80000c60 <acquire>
    if(p->pid == pid){
    8000250e:	5c9c                	lw	a5,56(s1)
    80002510:	01278d63          	beq	a5,s2,8000252a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002514:	8526                	mv	a0,s1
    80002516:	ffffe097          	auipc	ra,0xffffe
    8000251a:	7fe080e7          	jalr	2046(ra) # 80000d14 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000251e:	19048493          	addi	s1,s1,400
    80002522:	ff3491e3          	bne	s1,s3,80002504 <kill+0x20>
  }
  return -1;
    80002526:	557d                	li	a0,-1
    80002528:	a829                	j	80002542 <kill+0x5e>
      p->killed = 1;
    8000252a:	4785                	li	a5,1
    8000252c:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000252e:	4c98                	lw	a4,24(s1)
    80002530:	4785                	li	a5,1
    80002532:	00f70f63          	beq	a4,a5,80002550 <kill+0x6c>
      release(&p->lock);
    80002536:	8526                	mv	a0,s1
    80002538:	ffffe097          	auipc	ra,0xffffe
    8000253c:	7dc080e7          	jalr	2012(ra) # 80000d14 <release>
      return 0;
    80002540:	4501                	li	a0,0
}
    80002542:	70a2                	ld	ra,40(sp)
    80002544:	7402                	ld	s0,32(sp)
    80002546:	64e2                	ld	s1,24(sp)
    80002548:	6942                	ld	s2,16(sp)
    8000254a:	69a2                	ld	s3,8(sp)
    8000254c:	6145                	addi	sp,sp,48
    8000254e:	8082                	ret
        p->state = RUNNABLE;
    80002550:	4789                	li	a5,2
    80002552:	cc9c                	sw	a5,24(s1)
    80002554:	b7cd                	j	80002536 <kill+0x52>

0000000080002556 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002556:	7179                	addi	sp,sp,-48
    80002558:	f406                	sd	ra,40(sp)
    8000255a:	f022                	sd	s0,32(sp)
    8000255c:	ec26                	sd	s1,24(sp)
    8000255e:	e84a                	sd	s2,16(sp)
    80002560:	e44e                	sd	s3,8(sp)
    80002562:	e052                	sd	s4,0(sp)
    80002564:	1800                	addi	s0,sp,48
    80002566:	84aa                	mv	s1,a0
    80002568:	892e                	mv	s2,a1
    8000256a:	89b2                	mv	s3,a2
    8000256c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	4c0080e7          	jalr	1216(ra) # 80001a2e <myproc>
  if(user_dst){
    80002576:	c08d                	beqz	s1,80002598 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002578:	86d2                	mv	a3,s4
    8000257a:	864e                	mv	a2,s3
    8000257c:	85ca                	mv	a1,s2
    8000257e:	6928                	ld	a0,80(a0)
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	1a2080e7          	jalr	418(ra) # 80001722 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002588:	70a2                	ld	ra,40(sp)
    8000258a:	7402                	ld	s0,32(sp)
    8000258c:	64e2                	ld	s1,24(sp)
    8000258e:	6942                	ld	s2,16(sp)
    80002590:	69a2                	ld	s3,8(sp)
    80002592:	6a02                	ld	s4,0(sp)
    80002594:	6145                	addi	sp,sp,48
    80002596:	8082                	ret
    memmove((char *)dst, src, len);
    80002598:	000a061b          	sext.w	a2,s4
    8000259c:	85ce                	mv	a1,s3
    8000259e:	854a                	mv	a0,s2
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	81c080e7          	jalr	-2020(ra) # 80000dbc <memmove>
    return 0;
    800025a8:	8526                	mv	a0,s1
    800025aa:	bff9                	j	80002588 <either_copyout+0x32>

00000000800025ac <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025ac:	7179                	addi	sp,sp,-48
    800025ae:	f406                	sd	ra,40(sp)
    800025b0:	f022                	sd	s0,32(sp)
    800025b2:	ec26                	sd	s1,24(sp)
    800025b4:	e84a                	sd	s2,16(sp)
    800025b6:	e44e                	sd	s3,8(sp)
    800025b8:	e052                	sd	s4,0(sp)
    800025ba:	1800                	addi	s0,sp,48
    800025bc:	892a                	mv	s2,a0
    800025be:	84ae                	mv	s1,a1
    800025c0:	89b2                	mv	s3,a2
    800025c2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	46a080e7          	jalr	1130(ra) # 80001a2e <myproc>
  if(user_src){
    800025cc:	c08d                	beqz	s1,800025ee <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025ce:	86d2                	mv	a3,s4
    800025d0:	864e                	mv	a2,s3
    800025d2:	85ca                	mv	a1,s2
    800025d4:	6928                	ld	a0,80(a0)
    800025d6:	fffff097          	auipc	ra,0xfffff
    800025da:	1d8080e7          	jalr	472(ra) # 800017ae <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025de:	70a2                	ld	ra,40(sp)
    800025e0:	7402                	ld	s0,32(sp)
    800025e2:	64e2                	ld	s1,24(sp)
    800025e4:	6942                	ld	s2,16(sp)
    800025e6:	69a2                	ld	s3,8(sp)
    800025e8:	6a02                	ld	s4,0(sp)
    800025ea:	6145                	addi	sp,sp,48
    800025ec:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ee:	000a061b          	sext.w	a2,s4
    800025f2:	85ce                	mv	a1,s3
    800025f4:	854a                	mv	a0,s2
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	7c6080e7          	jalr	1990(ra) # 80000dbc <memmove>
    return 0;
    800025fe:	8526                	mv	a0,s1
    80002600:	bff9                	j	800025de <either_copyin+0x32>

0000000080002602 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002602:	715d                	addi	sp,sp,-80
    80002604:	e486                	sd	ra,72(sp)
    80002606:	e0a2                	sd	s0,64(sp)
    80002608:	fc26                	sd	s1,56(sp)
    8000260a:	f84a                	sd	s2,48(sp)
    8000260c:	f44e                	sd	s3,40(sp)
    8000260e:	f052                	sd	s4,32(sp)
    80002610:	ec56                	sd	s5,24(sp)
    80002612:	e85a                	sd	s6,16(sp)
    80002614:	e45e                	sd	s7,8(sp)
    80002616:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002618:	00006517          	auipc	a0,0x6
    8000261c:	ab850513          	addi	a0,a0,-1352 # 800080d0 <digits+0x88>
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	f66080e7          	jalr	-154(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002628:	00010497          	auipc	s1,0x10
    8000262c:	89848493          	addi	s1,s1,-1896 # 80011ec0 <proc+0x158>
    80002630:	00016917          	auipc	s2,0x16
    80002634:	c9090913          	addi	s2,s2,-880 # 800182c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002638:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000263a:	00006997          	auipc	s3,0x6
    8000263e:	c3698993          	addi	s3,s3,-970 # 80008270 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002642:	00006a97          	auipc	s5,0x6
    80002646:	c36a8a93          	addi	s5,s5,-970 # 80008278 <digits+0x230>
    printf("\n");
    8000264a:	00006a17          	auipc	s4,0x6
    8000264e:	a86a0a13          	addi	s4,s4,-1402 # 800080d0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002652:	00006b97          	auipc	s7,0x6
    80002656:	c5eb8b93          	addi	s7,s7,-930 # 800082b0 <states.1735>
    8000265a:	a00d                	j	8000267c <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000265c:	ee06a583          	lw	a1,-288(a3)
    80002660:	8556                	mv	a0,s5
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	f24080e7          	jalr	-220(ra) # 80000586 <printf>
    printf("\n");
    8000266a:	8552                	mv	a0,s4
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	f1a080e7          	jalr	-230(ra) # 80000586 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002674:	19048493          	addi	s1,s1,400
    80002678:	03248163          	beq	s1,s2,8000269a <procdump+0x98>
    if(p->state == UNUSED)
    8000267c:	86a6                	mv	a3,s1
    8000267e:	ec04a783          	lw	a5,-320(s1)
    80002682:	dbed                	beqz	a5,80002674 <procdump+0x72>
      state = "???";
    80002684:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002686:	fcfb6be3          	bltu	s6,a5,8000265c <procdump+0x5a>
    8000268a:	1782                	slli	a5,a5,0x20
    8000268c:	9381                	srli	a5,a5,0x20
    8000268e:	078e                	slli	a5,a5,0x3
    80002690:	97de                	add	a5,a5,s7
    80002692:	6390                	ld	a2,0(a5)
    80002694:	f661                	bnez	a2,8000265c <procdump+0x5a>
      state = "???";
    80002696:	864e                	mv	a2,s3
    80002698:	b7d1                	j	8000265c <procdump+0x5a>
  }
}
    8000269a:	60a6                	ld	ra,72(sp)
    8000269c:	6406                	ld	s0,64(sp)
    8000269e:	74e2                	ld	s1,56(sp)
    800026a0:	7942                	ld	s2,48(sp)
    800026a2:	79a2                	ld	s3,40(sp)
    800026a4:	7a02                	ld	s4,32(sp)
    800026a6:	6ae2                	ld	s5,24(sp)
    800026a8:	6b42                	ld	s6,16(sp)
    800026aa:	6ba2                	ld	s7,8(sp)
    800026ac:	6161                	addi	sp,sp,80
    800026ae:	8082                	ret

00000000800026b0 <swtch>:
    800026b0:	00153023          	sd	ra,0(a0)
    800026b4:	00253423          	sd	sp,8(a0)
    800026b8:	e900                	sd	s0,16(a0)
    800026ba:	ed04                	sd	s1,24(a0)
    800026bc:	03253023          	sd	s2,32(a0)
    800026c0:	03353423          	sd	s3,40(a0)
    800026c4:	03453823          	sd	s4,48(a0)
    800026c8:	03553c23          	sd	s5,56(a0)
    800026cc:	05653023          	sd	s6,64(a0)
    800026d0:	05753423          	sd	s7,72(a0)
    800026d4:	05853823          	sd	s8,80(a0)
    800026d8:	05953c23          	sd	s9,88(a0)
    800026dc:	07a53023          	sd	s10,96(a0)
    800026e0:	07b53423          	sd	s11,104(a0)
    800026e4:	0005b083          	ld	ra,0(a1)
    800026e8:	0085b103          	ld	sp,8(a1)
    800026ec:	6980                	ld	s0,16(a1)
    800026ee:	6d84                	ld	s1,24(a1)
    800026f0:	0205b903          	ld	s2,32(a1)
    800026f4:	0285b983          	ld	s3,40(a1)
    800026f8:	0305ba03          	ld	s4,48(a1)
    800026fc:	0385ba83          	ld	s5,56(a1)
    80002700:	0405bb03          	ld	s6,64(a1)
    80002704:	0485bb83          	ld	s7,72(a1)
    80002708:	0505bc03          	ld	s8,80(a1)
    8000270c:	0585bc83          	ld	s9,88(a1)
    80002710:	0605bd03          	ld	s10,96(a1)
    80002714:	0685bd83          	ld	s11,104(a1)
    80002718:	8082                	ret

000000008000271a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000271a:	1141                	addi	sp,sp,-16
    8000271c:	e406                	sd	ra,8(sp)
    8000271e:	e022                	sd	s0,0(sp)
    80002720:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002722:	00006597          	auipc	a1,0x6
    80002726:	bb658593          	addi	a1,a1,-1098 # 800082d8 <states.1735+0x28>
    8000272a:	00016517          	auipc	a0,0x16
    8000272e:	a3e50513          	addi	a0,a0,-1474 # 80018168 <tickslock>
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	49e080e7          	jalr	1182(ra) # 80000bd0 <initlock>
}
    8000273a:	60a2                	ld	ra,8(sp)
    8000273c:	6402                	ld	s0,0(sp)
    8000273e:	0141                	addi	sp,sp,16
    80002740:	8082                	ret

0000000080002742 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002742:	1141                	addi	sp,sp,-16
    80002744:	e422                	sd	s0,8(sp)
    80002746:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002748:	00003797          	auipc	a5,0x3
    8000274c:	58878793          	addi	a5,a5,1416 # 80005cd0 <kernelvec>
    80002750:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002754:	6422                	ld	s0,8(sp)
    80002756:	0141                	addi	sp,sp,16
    80002758:	8082                	ret

000000008000275a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000275a:	1141                	addi	sp,sp,-16
    8000275c:	e406                	sd	ra,8(sp)
    8000275e:	e022                	sd	s0,0(sp)
    80002760:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002762:	fffff097          	auipc	ra,0xfffff
    80002766:	2cc080e7          	jalr	716(ra) # 80001a2e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000276e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002770:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002774:	00005617          	auipc	a2,0x5
    80002778:	88c60613          	addi	a2,a2,-1908 # 80007000 <_trampoline>
    8000277c:	00005697          	auipc	a3,0x5
    80002780:	88468693          	addi	a3,a3,-1916 # 80007000 <_trampoline>
    80002784:	8e91                	sub	a3,a3,a2
    80002786:	040007b7          	lui	a5,0x4000
    8000278a:	17fd                	addi	a5,a5,-1
    8000278c:	07b2                	slli	a5,a5,0xc
    8000278e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002790:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002794:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002796:	180026f3          	csrr	a3,satp
    8000279a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000279c:	6d38                	ld	a4,88(a0)
    8000279e:	6134                	ld	a3,64(a0)
    800027a0:	6585                	lui	a1,0x1
    800027a2:	96ae                	add	a3,a3,a1
    800027a4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027a6:	6d38                	ld	a4,88(a0)
    800027a8:	00000697          	auipc	a3,0x0
    800027ac:	13868693          	addi	a3,a3,312 # 800028e0 <usertrap>
    800027b0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027b2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027b4:	8692                	mv	a3,tp
    800027b6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027b8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027bc:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027c0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027c4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027c8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027ca:	6f18                	ld	a4,24(a4)
    800027cc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027d0:	692c                	ld	a1,80(a0)
    800027d2:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027d4:	00005717          	auipc	a4,0x5
    800027d8:	8bc70713          	addi	a4,a4,-1860 # 80007090 <userret>
    800027dc:	8f11                	sub	a4,a4,a2
    800027de:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027e0:	577d                	li	a4,-1
    800027e2:	177e                	slli	a4,a4,0x3f
    800027e4:	8dd9                	or	a1,a1,a4
    800027e6:	02000537          	lui	a0,0x2000
    800027ea:	157d                	addi	a0,a0,-1
    800027ec:	0536                	slli	a0,a0,0xd
    800027ee:	9782                	jalr	a5
}
    800027f0:	60a2                	ld	ra,8(sp)
    800027f2:	6402                	ld	s0,0(sp)
    800027f4:	0141                	addi	sp,sp,16
    800027f6:	8082                	ret

00000000800027f8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027f8:	1101                	addi	sp,sp,-32
    800027fa:	ec06                	sd	ra,24(sp)
    800027fc:	e822                	sd	s0,16(sp)
    800027fe:	e426                	sd	s1,8(sp)
    80002800:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002802:	00016497          	auipc	s1,0x16
    80002806:	96648493          	addi	s1,s1,-1690 # 80018168 <tickslock>
    8000280a:	8526                	mv	a0,s1
    8000280c:	ffffe097          	auipc	ra,0xffffe
    80002810:	454080e7          	jalr	1108(ra) # 80000c60 <acquire>
  ticks++;
    80002814:	00007517          	auipc	a0,0x7
    80002818:	80c50513          	addi	a0,a0,-2036 # 80009020 <ticks>
    8000281c:	411c                	lw	a5,0(a0)
    8000281e:	2785                	addiw	a5,a5,1
    80002820:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002822:	00000097          	auipc	ra,0x0
    80002826:	c58080e7          	jalr	-936(ra) # 8000247a <wakeup>
  release(&tickslock);
    8000282a:	8526                	mv	a0,s1
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	4e8080e7          	jalr	1256(ra) # 80000d14 <release>
}
    80002834:	60e2                	ld	ra,24(sp)
    80002836:	6442                	ld	s0,16(sp)
    80002838:	64a2                	ld	s1,8(sp)
    8000283a:	6105                	addi	sp,sp,32
    8000283c:	8082                	ret

000000008000283e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000283e:	1101                	addi	sp,sp,-32
    80002840:	ec06                	sd	ra,24(sp)
    80002842:	e822                	sd	s0,16(sp)
    80002844:	e426                	sd	s1,8(sp)
    80002846:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002848:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000284c:	00074d63          	bltz	a4,80002866 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002850:	57fd                	li	a5,-1
    80002852:	17fe                	slli	a5,a5,0x3f
    80002854:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002856:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002858:	06f70363          	beq	a4,a5,800028be <devintr+0x80>
  }
    8000285c:	60e2                	ld	ra,24(sp)
    8000285e:	6442                	ld	s0,16(sp)
    80002860:	64a2                	ld	s1,8(sp)
    80002862:	6105                	addi	sp,sp,32
    80002864:	8082                	ret
     (scause & 0xff) == 9){
    80002866:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000286a:	46a5                	li	a3,9
    8000286c:	fed792e3          	bne	a5,a3,80002850 <devintr+0x12>
    int irq = plic_claim();
    80002870:	00003097          	auipc	ra,0x3
    80002874:	568080e7          	jalr	1384(ra) # 80005dd8 <plic_claim>
    80002878:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000287a:	47a9                	li	a5,10
    8000287c:	02f50763          	beq	a0,a5,800028aa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002880:	4785                	li	a5,1
    80002882:	02f50963          	beq	a0,a5,800028b4 <devintr+0x76>
    return 1;
    80002886:	4505                	li	a0,1
    } else if(irq){
    80002888:	d8f1                	beqz	s1,8000285c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000288a:	85a6                	mv	a1,s1
    8000288c:	00006517          	auipc	a0,0x6
    80002890:	a5450513          	addi	a0,a0,-1452 # 800082e0 <states.1735+0x30>
    80002894:	ffffe097          	auipc	ra,0xffffe
    80002898:	cf2080e7          	jalr	-782(ra) # 80000586 <printf>
      plic_complete(irq);
    8000289c:	8526                	mv	a0,s1
    8000289e:	00003097          	auipc	ra,0x3
    800028a2:	55e080e7          	jalr	1374(ra) # 80005dfc <plic_complete>
    return 1;
    800028a6:	4505                	li	a0,1
    800028a8:	bf55                	j	8000285c <devintr+0x1e>
      uartintr();
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	17a080e7          	jalr	378(ra) # 80000a24 <uartintr>
    800028b2:	b7ed                	j	8000289c <devintr+0x5e>
      virtio_disk_intr();
    800028b4:	00004097          	auipc	ra,0x4
    800028b8:	9e2080e7          	jalr	-1566(ra) # 80006296 <virtio_disk_intr>
    800028bc:	b7c5                	j	8000289c <devintr+0x5e>
    if(cpuid() == 0){
    800028be:	fffff097          	auipc	ra,0xfffff
    800028c2:	144080e7          	jalr	324(ra) # 80001a02 <cpuid>
    800028c6:	c901                	beqz	a0,800028d6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028c8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028cc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ce:	14479073          	csrw	sip,a5
    return 2;
    800028d2:	4509                	li	a0,2
    800028d4:	b761                	j	8000285c <devintr+0x1e>
      clockintr();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	f22080e7          	jalr	-222(ra) # 800027f8 <clockintr>
    800028de:	b7ed                	j	800028c8 <devintr+0x8a>

00000000800028e0 <usertrap>:
{
    800028e0:	1101                	addi	sp,sp,-32
    800028e2:	ec06                	sd	ra,24(sp)
    800028e4:	e822                	sd	s0,16(sp)
    800028e6:	e426                	sd	s1,8(sp)
    800028e8:	e04a                	sd	s2,0(sp)
    800028ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ec:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028f0:	1007f793          	andi	a5,a5,256
    800028f4:	e3ad                	bnez	a5,80002956 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f6:	00003797          	auipc	a5,0x3
    800028fa:	3da78793          	addi	a5,a5,986 # 80005cd0 <kernelvec>
    800028fe:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	12c080e7          	jalr	300(ra) # 80001a2e <myproc>
    8000290a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000290c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290e:	14102773          	csrr	a4,sepc
    80002912:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002914:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002918:	47a1                	li	a5,8
    8000291a:	04f71c63          	bne	a4,a5,80002972 <usertrap+0x92>
    if(p->killed)
    8000291e:	591c                	lw	a5,48(a0)
    80002920:	e3b9                	bnez	a5,80002966 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002922:	6cb8                	ld	a4,88(s1)
    80002924:	6f1c                	ld	a5,24(a4)
    80002926:	0791                	addi	a5,a5,4
    80002928:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000292a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000292e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002932:	10079073          	csrw	sstatus,a5
    syscall();
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	33e080e7          	jalr	830(ra) # 80002c74 <syscall>
  if(p->killed)
    8000293e:	589c                	lw	a5,48(s1)
    80002940:	e7c5                	bnez	a5,800029e8 <usertrap+0x108>
  usertrapret();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	e18080e7          	jalr	-488(ra) # 8000275a <usertrapret>
}
    8000294a:	60e2                	ld	ra,24(sp)
    8000294c:	6442                	ld	s0,16(sp)
    8000294e:	64a2                	ld	s1,8(sp)
    80002950:	6902                	ld	s2,0(sp)
    80002952:	6105                	addi	sp,sp,32
    80002954:	8082                	ret
    panic("usertrap: not from user mode");
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	9aa50513          	addi	a0,a0,-1622 # 80008300 <states.1735+0x50>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	bde080e7          	jalr	-1058(ra) # 8000053c <panic>
      exit(-1);
    80002966:	557d                	li	a0,-1
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	846080e7          	jalr	-1978(ra) # 800021ae <exit>
    80002970:	bf4d                	j	80002922 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002972:	00000097          	auipc	ra,0x0
    80002976:	ecc080e7          	jalr	-308(ra) # 8000283e <devintr>
    8000297a:	892a                	mv	s2,a0
    8000297c:	c501                	beqz	a0,80002984 <usertrap+0xa4>
  if(p->killed)
    8000297e:	589c                	lw	a5,48(s1)
    80002980:	c3a1                	beqz	a5,800029c0 <usertrap+0xe0>
    80002982:	a815                	j	800029b6 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002984:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002988:	5c90                	lw	a2,56(s1)
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	99650513          	addi	a0,a0,-1642 # 80008320 <states.1735+0x70>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bf4080e7          	jalr	-1036(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000299a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000299e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	9ae50513          	addi	a0,a0,-1618 # 80008350 <states.1735+0xa0>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	bdc080e7          	jalr	-1060(ra) # 80000586 <printf>
    p->killed = 1;
    800029b2:	4785                	li	a5,1
    800029b4:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029b6:	557d                	li	a0,-1
    800029b8:	fffff097          	auipc	ra,0xfffff
    800029bc:	7f6080e7          	jalr	2038(ra) # 800021ae <exit>
  if(which_dev == 2) {
    800029c0:	4789                	li	a5,2
    800029c2:	f8f910e3          	bne	s2,a5,80002942 <usertrap+0x62>
    if(p->alarm_interval != 0) { // 如果设定了时钟事件
    800029c6:	1684a703          	lw	a4,360(s1)
    800029ca:	cb11                	beqz	a4,800029de <usertrap+0xfe>
      if(--p->alarm_ticks <= 0) { // 时钟倒计时 -1 tick，如果已经到达或超过设定的 tick 数
    800029cc:	1784a783          	lw	a5,376(s1)
    800029d0:	37fd                	addiw	a5,a5,-1
    800029d2:	0007869b          	sext.w	a3,a5
    800029d6:	16f4ac23          	sw	a5,376(s1)
    800029da:	00d05963          	blez	a3,800029ec <usertrap+0x10c>
    yield();
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	8da080e7          	jalr	-1830(ra) # 800022b8 <yield>
    800029e6:	bfb1                	j	80002942 <usertrap+0x62>
  int which_dev = 0;
    800029e8:	4901                	li	s2,0
    800029ea:	b7f1                	j	800029b6 <usertrap+0xd6>
        if(!p->alarm_goingoff) { // 确保没有时钟正在运行
    800029ec:	1884a783          	lw	a5,392(s1)
    800029f0:	f7fd                	bnez	a5,800029de <usertrap+0xfe>
          p->alarm_ticks = p->alarm_interval;
    800029f2:	16e4ac23          	sw	a4,376(s1)
          *p->alarm_trapframe = *p->trapframe; // backup trapframe
    800029f6:	6cb4                	ld	a3,88(s1)
    800029f8:	87b6                	mv	a5,a3
    800029fa:	1804b703          	ld	a4,384(s1)
    800029fe:	12068693          	addi	a3,a3,288
    80002a02:	0007b803          	ld	a6,0(a5)
    80002a06:	6788                	ld	a0,8(a5)
    80002a08:	6b8c                	ld	a1,16(a5)
    80002a0a:	6f90                	ld	a2,24(a5)
    80002a0c:	01073023          	sd	a6,0(a4)
    80002a10:	e708                	sd	a0,8(a4)
    80002a12:	eb0c                	sd	a1,16(a4)
    80002a14:	ef10                	sd	a2,24(a4)
    80002a16:	02078793          	addi	a5,a5,32
    80002a1a:	02070713          	addi	a4,a4,32
    80002a1e:	fed792e3          	bne	a5,a3,80002a02 <usertrap+0x122>
          p->trapframe->epc = (uint64)p->alarm_handler;
    80002a22:	6cbc                	ld	a5,88(s1)
    80002a24:	1704b703          	ld	a4,368(s1)
    80002a28:	ef98                	sd	a4,24(a5)
          p->alarm_goingoff = 1;
    80002a2a:	4785                	li	a5,1
    80002a2c:	18f4a423          	sw	a5,392(s1)
    80002a30:	b77d                	j	800029de <usertrap+0xfe>

0000000080002a32 <kerneltrap>:
{
    80002a32:	7179                	addi	sp,sp,-48
    80002a34:	f406                	sd	ra,40(sp)
    80002a36:	f022                	sd	s0,32(sp)
    80002a38:	ec26                	sd	s1,24(sp)
    80002a3a:	e84a                	sd	s2,16(sp)
    80002a3c:	e44e                	sd	s3,8(sp)
    80002a3e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a40:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a44:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a48:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a4c:	1004f793          	andi	a5,s1,256
    80002a50:	cb85                	beqz	a5,80002a80 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a52:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a56:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a58:	ef85                	bnez	a5,80002a90 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a5a:	00000097          	auipc	ra,0x0
    80002a5e:	de4080e7          	jalr	-540(ra) # 8000283e <devintr>
    80002a62:	cd1d                	beqz	a0,80002aa0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a64:	4789                	li	a5,2
    80002a66:	06f50a63          	beq	a0,a5,80002ada <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a6a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6e:	10049073          	csrw	sstatus,s1
}
    80002a72:	70a2                	ld	ra,40(sp)
    80002a74:	7402                	ld	s0,32(sp)
    80002a76:	64e2                	ld	s1,24(sp)
    80002a78:	6942                	ld	s2,16(sp)
    80002a7a:	69a2                	ld	s3,8(sp)
    80002a7c:	6145                	addi	sp,sp,48
    80002a7e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	8f050513          	addi	a0,a0,-1808 # 80008370 <states.1735+0xc0>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	ab4080e7          	jalr	-1356(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	90850513          	addi	a0,a0,-1784 # 80008398 <states.1735+0xe8>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	aa4080e7          	jalr	-1372(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002aa0:	85ce                	mv	a1,s3
    80002aa2:	00006517          	auipc	a0,0x6
    80002aa6:	91650513          	addi	a0,a0,-1770 # 800083b8 <states.1735+0x108>
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	adc080e7          	jalr	-1316(ra) # 80000586 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ab2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ab6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aba:	00006517          	auipc	a0,0x6
    80002abe:	90e50513          	addi	a0,a0,-1778 # 800083c8 <states.1735+0x118>
    80002ac2:	ffffe097          	auipc	ra,0xffffe
    80002ac6:	ac4080e7          	jalr	-1340(ra) # 80000586 <printf>
    panic("kerneltrap");
    80002aca:	00006517          	auipc	a0,0x6
    80002ace:	91650513          	addi	a0,a0,-1770 # 800083e0 <states.1735+0x130>
    80002ad2:	ffffe097          	auipc	ra,0xffffe
    80002ad6:	a6a080e7          	jalr	-1430(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	f54080e7          	jalr	-172(ra) # 80001a2e <myproc>
    80002ae2:	d541                	beqz	a0,80002a6a <kerneltrap+0x38>
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	f4a080e7          	jalr	-182(ra) # 80001a2e <myproc>
    80002aec:	4d18                	lw	a4,24(a0)
    80002aee:	478d                	li	a5,3
    80002af0:	f6f71de3          	bne	a4,a5,80002a6a <kerneltrap+0x38>
    yield();
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	7c4080e7          	jalr	1988(ra) # 800022b8 <yield>
    80002afc:	b7bd                	j	80002a6a <kerneltrap+0x38>

0000000080002afe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002afe:	1101                	addi	sp,sp,-32
    80002b00:	ec06                	sd	ra,24(sp)
    80002b02:	e822                	sd	s0,16(sp)
    80002b04:	e426                	sd	s1,8(sp)
    80002b06:	1000                	addi	s0,sp,32
    80002b08:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b0a:	fffff097          	auipc	ra,0xfffff
    80002b0e:	f24080e7          	jalr	-220(ra) # 80001a2e <myproc>
  switch (n) {
    80002b12:	4795                	li	a5,5
    80002b14:	0497e163          	bltu	a5,s1,80002b56 <argraw+0x58>
    80002b18:	048a                	slli	s1,s1,0x2
    80002b1a:	00006717          	auipc	a4,0x6
    80002b1e:	8fe70713          	addi	a4,a4,-1794 # 80008418 <states.1735+0x168>
    80002b22:	94ba                	add	s1,s1,a4
    80002b24:	409c                	lw	a5,0(s1)
    80002b26:	97ba                	add	a5,a5,a4
    80002b28:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b2a:	6d3c                	ld	a5,88(a0)
    80002b2c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b2e:	60e2                	ld	ra,24(sp)
    80002b30:	6442                	ld	s0,16(sp)
    80002b32:	64a2                	ld	s1,8(sp)
    80002b34:	6105                	addi	sp,sp,32
    80002b36:	8082                	ret
    return p->trapframe->a1;
    80002b38:	6d3c                	ld	a5,88(a0)
    80002b3a:	7fa8                	ld	a0,120(a5)
    80002b3c:	bfcd                	j	80002b2e <argraw+0x30>
    return p->trapframe->a2;
    80002b3e:	6d3c                	ld	a5,88(a0)
    80002b40:	63c8                	ld	a0,128(a5)
    80002b42:	b7f5                	j	80002b2e <argraw+0x30>
    return p->trapframe->a3;
    80002b44:	6d3c                	ld	a5,88(a0)
    80002b46:	67c8                	ld	a0,136(a5)
    80002b48:	b7dd                	j	80002b2e <argraw+0x30>
    return p->trapframe->a4;
    80002b4a:	6d3c                	ld	a5,88(a0)
    80002b4c:	6bc8                	ld	a0,144(a5)
    80002b4e:	b7c5                	j	80002b2e <argraw+0x30>
    return p->trapframe->a5;
    80002b50:	6d3c                	ld	a5,88(a0)
    80002b52:	6fc8                	ld	a0,152(a5)
    80002b54:	bfe9                	j	80002b2e <argraw+0x30>
  panic("argraw");
    80002b56:	00006517          	auipc	a0,0x6
    80002b5a:	89a50513          	addi	a0,a0,-1894 # 800083f0 <states.1735+0x140>
    80002b5e:	ffffe097          	auipc	ra,0xffffe
    80002b62:	9de080e7          	jalr	-1570(ra) # 8000053c <panic>

0000000080002b66 <fetchaddr>:
{
    80002b66:	1101                	addi	sp,sp,-32
    80002b68:	ec06                	sd	ra,24(sp)
    80002b6a:	e822                	sd	s0,16(sp)
    80002b6c:	e426                	sd	s1,8(sp)
    80002b6e:	e04a                	sd	s2,0(sp)
    80002b70:	1000                	addi	s0,sp,32
    80002b72:	84aa                	mv	s1,a0
    80002b74:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	eb8080e7          	jalr	-328(ra) # 80001a2e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b7e:	653c                	ld	a5,72(a0)
    80002b80:	02f4f863          	bgeu	s1,a5,80002bb0 <fetchaddr+0x4a>
    80002b84:	00848713          	addi	a4,s1,8
    80002b88:	02e7e663          	bltu	a5,a4,80002bb4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b8c:	46a1                	li	a3,8
    80002b8e:	8626                	mv	a2,s1
    80002b90:	85ca                	mv	a1,s2
    80002b92:	6928                	ld	a0,80(a0)
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	c1a080e7          	jalr	-998(ra) # 800017ae <copyin>
    80002b9c:	00a03533          	snez	a0,a0
    80002ba0:	40a00533          	neg	a0,a0
}
    80002ba4:	60e2                	ld	ra,24(sp)
    80002ba6:	6442                	ld	s0,16(sp)
    80002ba8:	64a2                	ld	s1,8(sp)
    80002baa:	6902                	ld	s2,0(sp)
    80002bac:	6105                	addi	sp,sp,32
    80002bae:	8082                	ret
    return -1;
    80002bb0:	557d                	li	a0,-1
    80002bb2:	bfcd                	j	80002ba4 <fetchaddr+0x3e>
    80002bb4:	557d                	li	a0,-1
    80002bb6:	b7fd                	j	80002ba4 <fetchaddr+0x3e>

0000000080002bb8 <fetchstr>:
{
    80002bb8:	7179                	addi	sp,sp,-48
    80002bba:	f406                	sd	ra,40(sp)
    80002bbc:	f022                	sd	s0,32(sp)
    80002bbe:	ec26                	sd	s1,24(sp)
    80002bc0:	e84a                	sd	s2,16(sp)
    80002bc2:	e44e                	sd	s3,8(sp)
    80002bc4:	1800                	addi	s0,sp,48
    80002bc6:	892a                	mv	s2,a0
    80002bc8:	84ae                	mv	s1,a1
    80002bca:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	e62080e7          	jalr	-414(ra) # 80001a2e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002bd4:	86ce                	mv	a3,s3
    80002bd6:	864a                	mv	a2,s2
    80002bd8:	85a6                	mv	a1,s1
    80002bda:	6928                	ld	a0,80(a0)
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	c5e080e7          	jalr	-930(ra) # 8000183a <copyinstr>
  if(err < 0)
    80002be4:	00054763          	bltz	a0,80002bf2 <fetchstr+0x3a>
  return strlen(buf);
    80002be8:	8526                	mv	a0,s1
    80002bea:	ffffe097          	auipc	ra,0xffffe
    80002bee:	2fa080e7          	jalr	762(ra) # 80000ee4 <strlen>
}
    80002bf2:	70a2                	ld	ra,40(sp)
    80002bf4:	7402                	ld	s0,32(sp)
    80002bf6:	64e2                	ld	s1,24(sp)
    80002bf8:	6942                	ld	s2,16(sp)
    80002bfa:	69a2                	ld	s3,8(sp)
    80002bfc:	6145                	addi	sp,sp,48
    80002bfe:	8082                	ret

0000000080002c00 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c00:	1101                	addi	sp,sp,-32
    80002c02:	ec06                	sd	ra,24(sp)
    80002c04:	e822                	sd	s0,16(sp)
    80002c06:	e426                	sd	s1,8(sp)
    80002c08:	1000                	addi	s0,sp,32
    80002c0a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	ef2080e7          	jalr	-270(ra) # 80002afe <argraw>
    80002c14:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c16:	4501                	li	a0,0
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c22:	1101                	addi	sp,sp,-32
    80002c24:	ec06                	sd	ra,24(sp)
    80002c26:	e822                	sd	s0,16(sp)
    80002c28:	e426                	sd	s1,8(sp)
    80002c2a:	1000                	addi	s0,sp,32
    80002c2c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	ed0080e7          	jalr	-304(ra) # 80002afe <argraw>
    80002c36:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c38:	4501                	li	a0,0
    80002c3a:	60e2                	ld	ra,24(sp)
    80002c3c:	6442                	ld	s0,16(sp)
    80002c3e:	64a2                	ld	s1,8(sp)
    80002c40:	6105                	addi	sp,sp,32
    80002c42:	8082                	ret

0000000080002c44 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	e04a                	sd	s2,0(sp)
    80002c4e:	1000                	addi	s0,sp,32
    80002c50:	84ae                	mv	s1,a1
    80002c52:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	eaa080e7          	jalr	-342(ra) # 80002afe <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c5c:	864a                	mv	a2,s2
    80002c5e:	85a6                	mv	a1,s1
    80002c60:	00000097          	auipc	ra,0x0
    80002c64:	f58080e7          	jalr	-168(ra) # 80002bb8 <fetchstr>
}
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6902                	ld	s2,0(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret

0000000080002c74 <syscall>:
[SYS_sigreturn] sys_sigreturn,
};

void
syscall(void)
{
    80002c74:	1101                	addi	sp,sp,-32
    80002c76:	ec06                	sd	ra,24(sp)
    80002c78:	e822                	sd	s0,16(sp)
    80002c7a:	e426                	sd	s1,8(sp)
    80002c7c:	e04a                	sd	s2,0(sp)
    80002c7e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c80:	fffff097          	auipc	ra,0xfffff
    80002c84:	dae080e7          	jalr	-594(ra) # 80001a2e <myproc>
    80002c88:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c8a:	05853903          	ld	s2,88(a0)
    80002c8e:	0a893783          	ld	a5,168(s2)
    80002c92:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c96:	37fd                	addiw	a5,a5,-1
    80002c98:	4759                	li	a4,22
    80002c9a:	00f76f63          	bltu	a4,a5,80002cb8 <syscall+0x44>
    80002c9e:	00369713          	slli	a4,a3,0x3
    80002ca2:	00005797          	auipc	a5,0x5
    80002ca6:	78e78793          	addi	a5,a5,1934 # 80008430 <syscalls>
    80002caa:	97ba                	add	a5,a5,a4
    80002cac:	639c                	ld	a5,0(a5)
    80002cae:	c789                	beqz	a5,80002cb8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cb0:	9782                	jalr	a5
    80002cb2:	06a93823          	sd	a0,112(s2)
    80002cb6:	a839                	j	80002cd4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cb8:	15848613          	addi	a2,s1,344
    80002cbc:	5c8c                	lw	a1,56(s1)
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	73a50513          	addi	a0,a0,1850 # 800083f8 <states.1735+0x148>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8c0080e7          	jalr	-1856(ra) # 80000586 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cce:	6cbc                	ld	a5,88(s1)
    80002cd0:	577d                	li	a4,-1
    80002cd2:	fbb8                	sd	a4,112(a5)
  }
}
    80002cd4:	60e2                	ld	ra,24(sp)
    80002cd6:	6442                	ld	s0,16(sp)
    80002cd8:	64a2                	ld	s1,8(sp)
    80002cda:	6902                	ld	s2,0(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret

0000000080002ce0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ce0:	1101                	addi	sp,sp,-32
    80002ce2:	ec06                	sd	ra,24(sp)
    80002ce4:	e822                	sd	s0,16(sp)
    80002ce6:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ce8:	fec40593          	addi	a1,s0,-20
    80002cec:	4501                	li	a0,0
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	f12080e7          	jalr	-238(ra) # 80002c00 <argint>
    return -1;
    80002cf6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cf8:	00054963          	bltz	a0,80002d0a <sys_exit+0x2a>
  exit(n);
    80002cfc:	fec42503          	lw	a0,-20(s0)
    80002d00:	fffff097          	auipc	ra,0xfffff
    80002d04:	4ae080e7          	jalr	1198(ra) # 800021ae <exit>
  return 0;  // not reached
    80002d08:	4781                	li	a5,0
}
    80002d0a:	853e                	mv	a0,a5
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	6105                	addi	sp,sp,32
    80002d12:	8082                	ret

0000000080002d14 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d14:	1141                	addi	sp,sp,-16
    80002d16:	e406                	sd	ra,8(sp)
    80002d18:	e022                	sd	s0,0(sp)
    80002d1a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	d12080e7          	jalr	-750(ra) # 80001a2e <myproc>
}
    80002d24:	5d08                	lw	a0,56(a0)
    80002d26:	60a2                	ld	ra,8(sp)
    80002d28:	6402                	ld	s0,0(sp)
    80002d2a:	0141                	addi	sp,sp,16
    80002d2c:	8082                	ret

0000000080002d2e <sys_fork>:

uint64
sys_fork(void)
{
    80002d2e:	1141                	addi	sp,sp,-16
    80002d30:	e406                	sd	ra,8(sp)
    80002d32:	e022                	sd	s0,0(sp)
    80002d34:	0800                	addi	s0,sp,16
  return fork();
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	108080e7          	jalr	264(ra) # 80001e3e <fork>
}
    80002d3e:	60a2                	ld	ra,8(sp)
    80002d40:	6402                	ld	s0,0(sp)
    80002d42:	0141                	addi	sp,sp,16
    80002d44:	8082                	ret

0000000080002d46 <sys_wait>:

uint64
sys_wait(void)
{
    80002d46:	1101                	addi	sp,sp,-32
    80002d48:	ec06                	sd	ra,24(sp)
    80002d4a:	e822                	sd	s0,16(sp)
    80002d4c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d4e:	fe840593          	addi	a1,s0,-24
    80002d52:	4501                	li	a0,0
    80002d54:	00000097          	auipc	ra,0x0
    80002d58:	ece080e7          	jalr	-306(ra) # 80002c22 <argaddr>
    80002d5c:	87aa                	mv	a5,a0
    return -1;
    80002d5e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d60:	0007c863          	bltz	a5,80002d70 <sys_wait+0x2a>
  return wait(p);
    80002d64:	fe843503          	ld	a0,-24(s0)
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	60a080e7          	jalr	1546(ra) # 80002372 <wait>
}
    80002d70:	60e2                	ld	ra,24(sp)
    80002d72:	6442                	ld	s0,16(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret

0000000080002d78 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d78:	7179                	addi	sp,sp,-48
    80002d7a:	f406                	sd	ra,40(sp)
    80002d7c:	f022                	sd	s0,32(sp)
    80002d7e:	ec26                	sd	s1,24(sp)
    80002d80:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d82:	fdc40593          	addi	a1,s0,-36
    80002d86:	4501                	li	a0,0
    80002d88:	00000097          	auipc	ra,0x0
    80002d8c:	e78080e7          	jalr	-392(ra) # 80002c00 <argint>
    80002d90:	87aa                	mv	a5,a0
    return -1;
    80002d92:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002d94:	0207c063          	bltz	a5,80002db4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	c96080e7          	jalr	-874(ra) # 80001a2e <myproc>
    80002da0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002da2:	fdc42503          	lw	a0,-36(s0)
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	024080e7          	jalr	36(ra) # 80001dca <growproc>
    80002dae:	00054863          	bltz	a0,80002dbe <sys_sbrk+0x46>
    return -1;
  return addr;
    80002db2:	8526                	mv	a0,s1
}
    80002db4:	70a2                	ld	ra,40(sp)
    80002db6:	7402                	ld	s0,32(sp)
    80002db8:	64e2                	ld	s1,24(sp)
    80002dba:	6145                	addi	sp,sp,48
    80002dbc:	8082                	ret
    return -1;
    80002dbe:	557d                	li	a0,-1
    80002dc0:	bfd5                	j	80002db4 <sys_sbrk+0x3c>

0000000080002dc2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dc2:	7139                	addi	sp,sp,-64
    80002dc4:	fc06                	sd	ra,56(sp)
    80002dc6:	f822                	sd	s0,48(sp)
    80002dc8:	f426                	sd	s1,40(sp)
    80002dca:	f04a                	sd	s2,32(sp)
    80002dcc:	ec4e                	sd	s3,24(sp)
    80002dce:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  backtrace(); // print stack backtrace.
    80002dd0:	ffffe097          	auipc	ra,0xffffe
    80002dd4:	9ce080e7          	jalr	-1586(ra) # 8000079e <backtrace>

  if(argint(0, &n) < 0)
    80002dd8:	fcc40593          	addi	a1,s0,-52
    80002ddc:	4501                	li	a0,0
    80002dde:	00000097          	auipc	ra,0x0
    80002de2:	e22080e7          	jalr	-478(ra) # 80002c00 <argint>
    return -1;
    80002de6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002de8:	06054563          	bltz	a0,80002e52 <sys_sleep+0x90>
  acquire(&tickslock);
    80002dec:	00015517          	auipc	a0,0x15
    80002df0:	37c50513          	addi	a0,a0,892 # 80018168 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	e6c080e7          	jalr	-404(ra) # 80000c60 <acquire>
  ticks0 = ticks;
    80002dfc:	00006917          	auipc	s2,0x6
    80002e00:	22492903          	lw	s2,548(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e04:	fcc42783          	lw	a5,-52(s0)
    80002e08:	cf85                	beqz	a5,80002e40 <sys_sleep+0x7e>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e0a:	00015997          	auipc	s3,0x15
    80002e0e:	35e98993          	addi	s3,s3,862 # 80018168 <tickslock>
    80002e12:	00006497          	auipc	s1,0x6
    80002e16:	20e48493          	addi	s1,s1,526 # 80009020 <ticks>
    if(myproc()->killed){
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	c14080e7          	jalr	-1004(ra) # 80001a2e <myproc>
    80002e22:	591c                	lw	a5,48(a0)
    80002e24:	ef9d                	bnez	a5,80002e62 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002e26:	85ce                	mv	a1,s3
    80002e28:	8526                	mv	a0,s1
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	4ca080e7          	jalr	1226(ra) # 800022f4 <sleep>
  while(ticks - ticks0 < n){
    80002e32:	409c                	lw	a5,0(s1)
    80002e34:	412787bb          	subw	a5,a5,s2
    80002e38:	fcc42703          	lw	a4,-52(s0)
    80002e3c:	fce7efe3          	bltu	a5,a4,80002e1a <sys_sleep+0x58>
  }
  release(&tickslock);
    80002e40:	00015517          	auipc	a0,0x15
    80002e44:	32850513          	addi	a0,a0,808 # 80018168 <tickslock>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	ecc080e7          	jalr	-308(ra) # 80000d14 <release>
  return 0;
    80002e50:	4781                	li	a5,0
}
    80002e52:	853e                	mv	a0,a5
    80002e54:	70e2                	ld	ra,56(sp)
    80002e56:	7442                	ld	s0,48(sp)
    80002e58:	74a2                	ld	s1,40(sp)
    80002e5a:	7902                	ld	s2,32(sp)
    80002e5c:	69e2                	ld	s3,24(sp)
    80002e5e:	6121                	addi	sp,sp,64
    80002e60:	8082                	ret
      release(&tickslock);
    80002e62:	00015517          	auipc	a0,0x15
    80002e66:	30650513          	addi	a0,a0,774 # 80018168 <tickslock>
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	eaa080e7          	jalr	-342(ra) # 80000d14 <release>
      return -1;
    80002e72:	57fd                	li	a5,-1
    80002e74:	bff9                	j	80002e52 <sys_sleep+0x90>

0000000080002e76 <sys_kill>:

uint64
sys_kill(void)
{
    80002e76:	1101                	addi	sp,sp,-32
    80002e78:	ec06                	sd	ra,24(sp)
    80002e7a:	e822                	sd	s0,16(sp)
    80002e7c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e7e:	fec40593          	addi	a1,s0,-20
    80002e82:	4501                	li	a0,0
    80002e84:	00000097          	auipc	ra,0x0
    80002e88:	d7c080e7          	jalr	-644(ra) # 80002c00 <argint>
    80002e8c:	87aa                	mv	a5,a0
    return -1;
    80002e8e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e90:	0007c863          	bltz	a5,80002ea0 <sys_kill+0x2a>
  return kill(pid);
    80002e94:	fec42503          	lw	a0,-20(s0)
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	64c080e7          	jalr	1612(ra) # 800024e4 <kill>
}
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	e426                	sd	s1,8(sp)
    80002eb0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eb2:	00015517          	auipc	a0,0x15
    80002eb6:	2b650513          	addi	a0,a0,694 # 80018168 <tickslock>
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	da6080e7          	jalr	-602(ra) # 80000c60 <acquire>
  xticks = ticks;
    80002ec2:	00006497          	auipc	s1,0x6
    80002ec6:	15e4a483          	lw	s1,350(s1) # 80009020 <ticks>
  release(&tickslock);
    80002eca:	00015517          	auipc	a0,0x15
    80002ece:	29e50513          	addi	a0,a0,670 # 80018168 <tickslock>
    80002ed2:	ffffe097          	auipc	ra,0xffffe
    80002ed6:	e42080e7          	jalr	-446(ra) # 80000d14 <release>
  return xticks;
}
    80002eda:	02049513          	slli	a0,s1,0x20
    80002ede:	9101                	srli	a0,a0,0x20
    80002ee0:	60e2                	ld	ra,24(sp)
    80002ee2:	6442                	ld	s0,16(sp)
    80002ee4:	64a2                	ld	s1,8(sp)
    80002ee6:	6105                	addi	sp,sp,32
    80002ee8:	8082                	ret

0000000080002eea <sys_sigalarm>:

uint64 sys_sigalarm(void) {
    80002eea:	1101                	addi	sp,sp,-32
    80002eec:	ec06                	sd	ra,24(sp)
    80002eee:	e822                	sd	s0,16(sp)
    80002ef0:	1000                	addi	s0,sp,32
  int n;
  uint64 fn;
  if(argint(0, &n) < 0)
    80002ef2:	fec40593          	addi	a1,s0,-20
    80002ef6:	4501                	li	a0,0
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	d08080e7          	jalr	-760(ra) # 80002c00 <argint>
    return -1;
    80002f00:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f02:	02054563          	bltz	a0,80002f2c <sys_sigalarm+0x42>
  if(argaddr(1, &fn) < 0)
    80002f06:	fe040593          	addi	a1,s0,-32
    80002f0a:	4505                	li	a0,1
    80002f0c:	00000097          	auipc	ra,0x0
    80002f10:	d16080e7          	jalr	-746(ra) # 80002c22 <argaddr>
    return -1;
    80002f14:	57fd                	li	a5,-1
  if(argaddr(1, &fn) < 0)
    80002f16:	00054b63          	bltz	a0,80002f2c <sys_sigalarm+0x42>
  
  return sigalarm(n, (void(*)())(fn));
    80002f1a:	fe043583          	ld	a1,-32(s0)
    80002f1e:	fec42503          	lw	a0,-20(s0)
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	08c080e7          	jalr	140(ra) # 80001fae <sigalarm>
    80002f2a:	87aa                	mv	a5,a0
}
    80002f2c:	853e                	mv	a0,a5
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <sys_sigreturn>:

uint64 sys_sigreturn(void) {
    80002f36:	1141                	addi	sp,sp,-16
    80002f38:	e406                	sd	ra,8(sp)
    80002f3a:	e022                	sd	s0,0(sp)
    80002f3c:	0800                	addi	s0,sp,16
	return sigreturn();
    80002f3e:	fffff097          	auipc	ra,0xfffff
    80002f42:	0a2080e7          	jalr	162(ra) # 80001fe0 <sigreturn>
}
    80002f46:	60a2                	ld	ra,8(sp)
    80002f48:	6402                	ld	s0,0(sp)
    80002f4a:	0141                	addi	sp,sp,16
    80002f4c:	8082                	ret

0000000080002f4e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f4e:	7179                	addi	sp,sp,-48
    80002f50:	f406                	sd	ra,40(sp)
    80002f52:	f022                	sd	s0,32(sp)
    80002f54:	ec26                	sd	s1,24(sp)
    80002f56:	e84a                	sd	s2,16(sp)
    80002f58:	e44e                	sd	s3,8(sp)
    80002f5a:	e052                	sd	s4,0(sp)
    80002f5c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f5e:	00005597          	auipc	a1,0x5
    80002f62:	59258593          	addi	a1,a1,1426 # 800084f0 <syscalls+0xc0>
    80002f66:	00015517          	auipc	a0,0x15
    80002f6a:	21a50513          	addi	a0,a0,538 # 80018180 <bcache>
    80002f6e:	ffffe097          	auipc	ra,0xffffe
    80002f72:	c62080e7          	jalr	-926(ra) # 80000bd0 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f76:	0001d797          	auipc	a5,0x1d
    80002f7a:	20a78793          	addi	a5,a5,522 # 80020180 <bcache+0x8000>
    80002f7e:	0001d717          	auipc	a4,0x1d
    80002f82:	46a70713          	addi	a4,a4,1130 # 800203e8 <bcache+0x8268>
    80002f86:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f8a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f8e:	00015497          	auipc	s1,0x15
    80002f92:	20a48493          	addi	s1,s1,522 # 80018198 <bcache+0x18>
    b->next = bcache.head.next;
    80002f96:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f98:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f9a:	00005a17          	auipc	s4,0x5
    80002f9e:	55ea0a13          	addi	s4,s4,1374 # 800084f8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002fa2:	2b893783          	ld	a5,696(s2)
    80002fa6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fa8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002fac:	85d2                	mv	a1,s4
    80002fae:	01048513          	addi	a0,s1,16
    80002fb2:	00001097          	auipc	ra,0x1
    80002fb6:	4ac080e7          	jalr	1196(ra) # 8000445e <initsleeplock>
    bcache.head.next->prev = b;
    80002fba:	2b893783          	ld	a5,696(s2)
    80002fbe:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fc0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fc4:	45848493          	addi	s1,s1,1112
    80002fc8:	fd349de3          	bne	s1,s3,80002fa2 <binit+0x54>
  }
}
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6942                	ld	s2,16(sp)
    80002fd4:	69a2                	ld	s3,8(sp)
    80002fd6:	6a02                	ld	s4,0(sp)
    80002fd8:	6145                	addi	sp,sp,48
    80002fda:	8082                	ret

0000000080002fdc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fdc:	7179                	addi	sp,sp,-48
    80002fde:	f406                	sd	ra,40(sp)
    80002fe0:	f022                	sd	s0,32(sp)
    80002fe2:	ec26                	sd	s1,24(sp)
    80002fe4:	e84a                	sd	s2,16(sp)
    80002fe6:	e44e                	sd	s3,8(sp)
    80002fe8:	1800                	addi	s0,sp,48
    80002fea:	89aa                	mv	s3,a0
    80002fec:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fee:	00015517          	auipc	a0,0x15
    80002ff2:	19250513          	addi	a0,a0,402 # 80018180 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	c6a080e7          	jalr	-918(ra) # 80000c60 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002ffe:	0001d497          	auipc	s1,0x1d
    80003002:	43a4b483          	ld	s1,1082(s1) # 80020438 <bcache+0x82b8>
    80003006:	0001d797          	auipc	a5,0x1d
    8000300a:	3e278793          	addi	a5,a5,994 # 800203e8 <bcache+0x8268>
    8000300e:	02f48f63          	beq	s1,a5,8000304c <bread+0x70>
    80003012:	873e                	mv	a4,a5
    80003014:	a021                	j	8000301c <bread+0x40>
    80003016:	68a4                	ld	s1,80(s1)
    80003018:	02e48a63          	beq	s1,a4,8000304c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000301c:	449c                	lw	a5,8(s1)
    8000301e:	ff379ce3          	bne	a5,s3,80003016 <bread+0x3a>
    80003022:	44dc                	lw	a5,12(s1)
    80003024:	ff2799e3          	bne	a5,s2,80003016 <bread+0x3a>
      b->refcnt++;
    80003028:	40bc                	lw	a5,64(s1)
    8000302a:	2785                	addiw	a5,a5,1
    8000302c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000302e:	00015517          	auipc	a0,0x15
    80003032:	15250513          	addi	a0,a0,338 # 80018180 <bcache>
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	cde080e7          	jalr	-802(ra) # 80000d14 <release>
      acquiresleep(&b->lock);
    8000303e:	01048513          	addi	a0,s1,16
    80003042:	00001097          	auipc	ra,0x1
    80003046:	456080e7          	jalr	1110(ra) # 80004498 <acquiresleep>
      return b;
    8000304a:	a8b9                	j	800030a8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000304c:	0001d497          	auipc	s1,0x1d
    80003050:	3e44b483          	ld	s1,996(s1) # 80020430 <bcache+0x82b0>
    80003054:	0001d797          	auipc	a5,0x1d
    80003058:	39478793          	addi	a5,a5,916 # 800203e8 <bcache+0x8268>
    8000305c:	00f48863          	beq	s1,a5,8000306c <bread+0x90>
    80003060:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003062:	40bc                	lw	a5,64(s1)
    80003064:	cf81                	beqz	a5,8000307c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003066:	64a4                	ld	s1,72(s1)
    80003068:	fee49de3          	bne	s1,a4,80003062 <bread+0x86>
  panic("bget: no buffers");
    8000306c:	00005517          	auipc	a0,0x5
    80003070:	49450513          	addi	a0,a0,1172 # 80008500 <syscalls+0xd0>
    80003074:	ffffd097          	auipc	ra,0xffffd
    80003078:	4c8080e7          	jalr	1224(ra) # 8000053c <panic>
      b->dev = dev;
    8000307c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003080:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003084:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003088:	4785                	li	a5,1
    8000308a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000308c:	00015517          	auipc	a0,0x15
    80003090:	0f450513          	addi	a0,a0,244 # 80018180 <bcache>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	c80080e7          	jalr	-896(ra) # 80000d14 <release>
      acquiresleep(&b->lock);
    8000309c:	01048513          	addi	a0,s1,16
    800030a0:	00001097          	auipc	ra,0x1
    800030a4:	3f8080e7          	jalr	1016(ra) # 80004498 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030a8:	409c                	lw	a5,0(s1)
    800030aa:	cb89                	beqz	a5,800030bc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030ac:	8526                	mv	a0,s1
    800030ae:	70a2                	ld	ra,40(sp)
    800030b0:	7402                	ld	s0,32(sp)
    800030b2:	64e2                	ld	s1,24(sp)
    800030b4:	6942                	ld	s2,16(sp)
    800030b6:	69a2                	ld	s3,8(sp)
    800030b8:	6145                	addi	sp,sp,48
    800030ba:	8082                	ret
    virtio_disk_rw(b, 0);
    800030bc:	4581                	li	a1,0
    800030be:	8526                	mv	a0,s1
    800030c0:	00003097          	auipc	ra,0x3
    800030c4:	f2c080e7          	jalr	-212(ra) # 80005fec <virtio_disk_rw>
    b->valid = 1;
    800030c8:	4785                	li	a5,1
    800030ca:	c09c                	sw	a5,0(s1)
  return b;
    800030cc:	b7c5                	j	800030ac <bread+0xd0>

00000000800030ce <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ce:	1101                	addi	sp,sp,-32
    800030d0:	ec06                	sd	ra,24(sp)
    800030d2:	e822                	sd	s0,16(sp)
    800030d4:	e426                	sd	s1,8(sp)
    800030d6:	1000                	addi	s0,sp,32
    800030d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030da:	0541                	addi	a0,a0,16
    800030dc:	00001097          	auipc	ra,0x1
    800030e0:	456080e7          	jalr	1110(ra) # 80004532 <holdingsleep>
    800030e4:	cd01                	beqz	a0,800030fc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030e6:	4585                	li	a1,1
    800030e8:	8526                	mv	a0,s1
    800030ea:	00003097          	auipc	ra,0x3
    800030ee:	f02080e7          	jalr	-254(ra) # 80005fec <virtio_disk_rw>
}
    800030f2:	60e2                	ld	ra,24(sp)
    800030f4:	6442                	ld	s0,16(sp)
    800030f6:	64a2                	ld	s1,8(sp)
    800030f8:	6105                	addi	sp,sp,32
    800030fa:	8082                	ret
    panic("bwrite");
    800030fc:	00005517          	auipc	a0,0x5
    80003100:	41c50513          	addi	a0,a0,1052 # 80008518 <syscalls+0xe8>
    80003104:	ffffd097          	auipc	ra,0xffffd
    80003108:	438080e7          	jalr	1080(ra) # 8000053c <panic>

000000008000310c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000310c:	1101                	addi	sp,sp,-32
    8000310e:	ec06                	sd	ra,24(sp)
    80003110:	e822                	sd	s0,16(sp)
    80003112:	e426                	sd	s1,8(sp)
    80003114:	e04a                	sd	s2,0(sp)
    80003116:	1000                	addi	s0,sp,32
    80003118:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311a:	01050913          	addi	s2,a0,16
    8000311e:	854a                	mv	a0,s2
    80003120:	00001097          	auipc	ra,0x1
    80003124:	412080e7          	jalr	1042(ra) # 80004532 <holdingsleep>
    80003128:	c92d                	beqz	a0,8000319a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000312a:	854a                	mv	a0,s2
    8000312c:	00001097          	auipc	ra,0x1
    80003130:	3c2080e7          	jalr	962(ra) # 800044ee <releasesleep>

  acquire(&bcache.lock);
    80003134:	00015517          	auipc	a0,0x15
    80003138:	04c50513          	addi	a0,a0,76 # 80018180 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b24080e7          	jalr	-1244(ra) # 80000c60 <acquire>
  b->refcnt--;
    80003144:	40bc                	lw	a5,64(s1)
    80003146:	37fd                	addiw	a5,a5,-1
    80003148:	0007871b          	sext.w	a4,a5
    8000314c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000314e:	eb05                	bnez	a4,8000317e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003150:	68bc                	ld	a5,80(s1)
    80003152:	64b8                	ld	a4,72(s1)
    80003154:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003156:	64bc                	ld	a5,72(s1)
    80003158:	68b8                	ld	a4,80(s1)
    8000315a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000315c:	0001d797          	auipc	a5,0x1d
    80003160:	02478793          	addi	a5,a5,36 # 80020180 <bcache+0x8000>
    80003164:	2b87b703          	ld	a4,696(a5)
    80003168:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000316a:	0001d717          	auipc	a4,0x1d
    8000316e:	27e70713          	addi	a4,a4,638 # 800203e8 <bcache+0x8268>
    80003172:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003174:	2b87b703          	ld	a4,696(a5)
    80003178:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000317a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000317e:	00015517          	auipc	a0,0x15
    80003182:	00250513          	addi	a0,a0,2 # 80018180 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	b8e080e7          	jalr	-1138(ra) # 80000d14 <release>
}
    8000318e:	60e2                	ld	ra,24(sp)
    80003190:	6442                	ld	s0,16(sp)
    80003192:	64a2                	ld	s1,8(sp)
    80003194:	6902                	ld	s2,0(sp)
    80003196:	6105                	addi	sp,sp,32
    80003198:	8082                	ret
    panic("brelse");
    8000319a:	00005517          	auipc	a0,0x5
    8000319e:	38650513          	addi	a0,a0,902 # 80008520 <syscalls+0xf0>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	39a080e7          	jalr	922(ra) # 8000053c <panic>

00000000800031aa <bpin>:

void
bpin(struct buf *b) {
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	e426                	sd	s1,8(sp)
    800031b2:	1000                	addi	s0,sp,32
    800031b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031b6:	00015517          	auipc	a0,0x15
    800031ba:	fca50513          	addi	a0,a0,-54 # 80018180 <bcache>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	aa2080e7          	jalr	-1374(ra) # 80000c60 <acquire>
  b->refcnt++;
    800031c6:	40bc                	lw	a5,64(s1)
    800031c8:	2785                	addiw	a5,a5,1
    800031ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031cc:	00015517          	auipc	a0,0x15
    800031d0:	fb450513          	addi	a0,a0,-76 # 80018180 <bcache>
    800031d4:	ffffe097          	auipc	ra,0xffffe
    800031d8:	b40080e7          	jalr	-1216(ra) # 80000d14 <release>
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6105                	addi	sp,sp,32
    800031e4:	8082                	ret

00000000800031e6 <bunpin>:

void
bunpin(struct buf *b) {
    800031e6:	1101                	addi	sp,sp,-32
    800031e8:	ec06                	sd	ra,24(sp)
    800031ea:	e822                	sd	s0,16(sp)
    800031ec:	e426                	sd	s1,8(sp)
    800031ee:	1000                	addi	s0,sp,32
    800031f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031f2:	00015517          	auipc	a0,0x15
    800031f6:	f8e50513          	addi	a0,a0,-114 # 80018180 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	a66080e7          	jalr	-1434(ra) # 80000c60 <acquire>
  b->refcnt--;
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	37fd                	addiw	a5,a5,-1
    80003206:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003208:	00015517          	auipc	a0,0x15
    8000320c:	f7850513          	addi	a0,a0,-136 # 80018180 <bcache>
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	b04080e7          	jalr	-1276(ra) # 80000d14 <release>
}
    80003218:	60e2                	ld	ra,24(sp)
    8000321a:	6442                	ld	s0,16(sp)
    8000321c:	64a2                	ld	s1,8(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret

0000000080003222 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	e426                	sd	s1,8(sp)
    8000322a:	e04a                	sd	s2,0(sp)
    8000322c:	1000                	addi	s0,sp,32
    8000322e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003230:	00d5d59b          	srliw	a1,a1,0xd
    80003234:	0001d797          	auipc	a5,0x1d
    80003238:	6287a783          	lw	a5,1576(a5) # 8002085c <sb+0x1c>
    8000323c:	9dbd                	addw	a1,a1,a5
    8000323e:	00000097          	auipc	ra,0x0
    80003242:	d9e080e7          	jalr	-610(ra) # 80002fdc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003246:	0074f713          	andi	a4,s1,7
    8000324a:	4785                	li	a5,1
    8000324c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003250:	14ce                	slli	s1,s1,0x33
    80003252:	90d9                	srli	s1,s1,0x36
    80003254:	00950733          	add	a4,a0,s1
    80003258:	05874703          	lbu	a4,88(a4)
    8000325c:	00e7f6b3          	and	a3,a5,a4
    80003260:	c69d                	beqz	a3,8000328e <bfree+0x6c>
    80003262:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003264:	94aa                	add	s1,s1,a0
    80003266:	fff7c793          	not	a5,a5
    8000326a:	8ff9                	and	a5,a5,a4
    8000326c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003270:	00001097          	auipc	ra,0x1
    80003274:	100080e7          	jalr	256(ra) # 80004370 <log_write>
  brelse(bp);
    80003278:	854a                	mv	a0,s2
    8000327a:	00000097          	auipc	ra,0x0
    8000327e:	e92080e7          	jalr	-366(ra) # 8000310c <brelse>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	64a2                	ld	s1,8(sp)
    80003288:	6902                	ld	s2,0(sp)
    8000328a:	6105                	addi	sp,sp,32
    8000328c:	8082                	ret
    panic("freeing free block");
    8000328e:	00005517          	auipc	a0,0x5
    80003292:	29a50513          	addi	a0,a0,666 # 80008528 <syscalls+0xf8>
    80003296:	ffffd097          	auipc	ra,0xffffd
    8000329a:	2a6080e7          	jalr	678(ra) # 8000053c <panic>

000000008000329e <balloc>:
{
    8000329e:	711d                	addi	sp,sp,-96
    800032a0:	ec86                	sd	ra,88(sp)
    800032a2:	e8a2                	sd	s0,80(sp)
    800032a4:	e4a6                	sd	s1,72(sp)
    800032a6:	e0ca                	sd	s2,64(sp)
    800032a8:	fc4e                	sd	s3,56(sp)
    800032aa:	f852                	sd	s4,48(sp)
    800032ac:	f456                	sd	s5,40(sp)
    800032ae:	f05a                	sd	s6,32(sp)
    800032b0:	ec5e                	sd	s7,24(sp)
    800032b2:	e862                	sd	s8,16(sp)
    800032b4:	e466                	sd	s9,8(sp)
    800032b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032b8:	0001d797          	auipc	a5,0x1d
    800032bc:	58c7a783          	lw	a5,1420(a5) # 80020844 <sb+0x4>
    800032c0:	cbd1                	beqz	a5,80003354 <balloc+0xb6>
    800032c2:	8baa                	mv	s7,a0
    800032c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032c6:	0001db17          	auipc	s6,0x1d
    800032ca:	57ab0b13          	addi	s6,s6,1402 # 80020840 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032d4:	6c89                	lui	s9,0x2
    800032d6:	a831                	j	800032f2 <balloc+0x54>
    brelse(bp);
    800032d8:	854a                	mv	a0,s2
    800032da:	00000097          	auipc	ra,0x0
    800032de:	e32080e7          	jalr	-462(ra) # 8000310c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032e2:	015c87bb          	addw	a5,s9,s5
    800032e6:	00078a9b          	sext.w	s5,a5
    800032ea:	004b2703          	lw	a4,4(s6)
    800032ee:	06eaf363          	bgeu	s5,a4,80003354 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032f2:	41fad79b          	sraiw	a5,s5,0x1f
    800032f6:	0137d79b          	srliw	a5,a5,0x13
    800032fa:	015787bb          	addw	a5,a5,s5
    800032fe:	40d7d79b          	sraiw	a5,a5,0xd
    80003302:	01cb2583          	lw	a1,28(s6)
    80003306:	9dbd                	addw	a1,a1,a5
    80003308:	855e                	mv	a0,s7
    8000330a:	00000097          	auipc	ra,0x0
    8000330e:	cd2080e7          	jalr	-814(ra) # 80002fdc <bread>
    80003312:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003314:	004b2503          	lw	a0,4(s6)
    80003318:	000a849b          	sext.w	s1,s5
    8000331c:	8662                	mv	a2,s8
    8000331e:	faa4fde3          	bgeu	s1,a0,800032d8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003322:	41f6579b          	sraiw	a5,a2,0x1f
    80003326:	01d7d69b          	srliw	a3,a5,0x1d
    8000332a:	00c6873b          	addw	a4,a3,a2
    8000332e:	00777793          	andi	a5,a4,7
    80003332:	9f95                	subw	a5,a5,a3
    80003334:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003338:	4037571b          	sraiw	a4,a4,0x3
    8000333c:	00e906b3          	add	a3,s2,a4
    80003340:	0586c683          	lbu	a3,88(a3)
    80003344:	00d7f5b3          	and	a1,a5,a3
    80003348:	cd91                	beqz	a1,80003364 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000334a:	2605                	addiw	a2,a2,1
    8000334c:	2485                	addiw	s1,s1,1
    8000334e:	fd4618e3          	bne	a2,s4,8000331e <balloc+0x80>
    80003352:	b759                	j	800032d8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003354:	00005517          	auipc	a0,0x5
    80003358:	1ec50513          	addi	a0,a0,492 # 80008540 <syscalls+0x110>
    8000335c:	ffffd097          	auipc	ra,0xffffd
    80003360:	1e0080e7          	jalr	480(ra) # 8000053c <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003364:	974a                	add	a4,a4,s2
    80003366:	8fd5                	or	a5,a5,a3
    80003368:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000336c:	854a                	mv	a0,s2
    8000336e:	00001097          	auipc	ra,0x1
    80003372:	002080e7          	jalr	2(ra) # 80004370 <log_write>
        brelse(bp);
    80003376:	854a                	mv	a0,s2
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	d94080e7          	jalr	-620(ra) # 8000310c <brelse>
  bp = bread(dev, bno);
    80003380:	85a6                	mv	a1,s1
    80003382:	855e                	mv	a0,s7
    80003384:	00000097          	auipc	ra,0x0
    80003388:	c58080e7          	jalr	-936(ra) # 80002fdc <bread>
    8000338c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000338e:	40000613          	li	a2,1024
    80003392:	4581                	li	a1,0
    80003394:	05850513          	addi	a0,a0,88
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	9c4080e7          	jalr	-1596(ra) # 80000d5c <memset>
  log_write(bp);
    800033a0:	854a                	mv	a0,s2
    800033a2:	00001097          	auipc	ra,0x1
    800033a6:	fce080e7          	jalr	-50(ra) # 80004370 <log_write>
  brelse(bp);
    800033aa:	854a                	mv	a0,s2
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	d60080e7          	jalr	-672(ra) # 8000310c <brelse>
}
    800033b4:	8526                	mv	a0,s1
    800033b6:	60e6                	ld	ra,88(sp)
    800033b8:	6446                	ld	s0,80(sp)
    800033ba:	64a6                	ld	s1,72(sp)
    800033bc:	6906                	ld	s2,64(sp)
    800033be:	79e2                	ld	s3,56(sp)
    800033c0:	7a42                	ld	s4,48(sp)
    800033c2:	7aa2                	ld	s5,40(sp)
    800033c4:	7b02                	ld	s6,32(sp)
    800033c6:	6be2                	ld	s7,24(sp)
    800033c8:	6c42                	ld	s8,16(sp)
    800033ca:	6ca2                	ld	s9,8(sp)
    800033cc:	6125                	addi	sp,sp,96
    800033ce:	8082                	ret

00000000800033d0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033d0:	7179                	addi	sp,sp,-48
    800033d2:	f406                	sd	ra,40(sp)
    800033d4:	f022                	sd	s0,32(sp)
    800033d6:	ec26                	sd	s1,24(sp)
    800033d8:	e84a                	sd	s2,16(sp)
    800033da:	e44e                	sd	s3,8(sp)
    800033dc:	e052                	sd	s4,0(sp)
    800033de:	1800                	addi	s0,sp,48
    800033e0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033e2:	47ad                	li	a5,11
    800033e4:	04b7fe63          	bgeu	a5,a1,80003440 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033e8:	ff45849b          	addiw	s1,a1,-12
    800033ec:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033f0:	0ff00793          	li	a5,255
    800033f4:	0ae7e363          	bltu	a5,a4,8000349a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033f8:	08052583          	lw	a1,128(a0)
    800033fc:	c5ad                	beqz	a1,80003466 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033fe:	00092503          	lw	a0,0(s2)
    80003402:	00000097          	auipc	ra,0x0
    80003406:	bda080e7          	jalr	-1062(ra) # 80002fdc <bread>
    8000340a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000340c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003410:	02049593          	slli	a1,s1,0x20
    80003414:	9181                	srli	a1,a1,0x20
    80003416:	058a                	slli	a1,a1,0x2
    80003418:	00b784b3          	add	s1,a5,a1
    8000341c:	0004a983          	lw	s3,0(s1)
    80003420:	04098d63          	beqz	s3,8000347a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003424:	8552                	mv	a0,s4
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	ce6080e7          	jalr	-794(ra) # 8000310c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000342e:	854e                	mv	a0,s3
    80003430:	70a2                	ld	ra,40(sp)
    80003432:	7402                	ld	s0,32(sp)
    80003434:	64e2                	ld	s1,24(sp)
    80003436:	6942                	ld	s2,16(sp)
    80003438:	69a2                	ld	s3,8(sp)
    8000343a:	6a02                	ld	s4,0(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003440:	02059493          	slli	s1,a1,0x20
    80003444:	9081                	srli	s1,s1,0x20
    80003446:	048a                	slli	s1,s1,0x2
    80003448:	94aa                	add	s1,s1,a0
    8000344a:	0504a983          	lw	s3,80(s1)
    8000344e:	fe0990e3          	bnez	s3,8000342e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003452:	4108                	lw	a0,0(a0)
    80003454:	00000097          	auipc	ra,0x0
    80003458:	e4a080e7          	jalr	-438(ra) # 8000329e <balloc>
    8000345c:	0005099b          	sext.w	s3,a0
    80003460:	0534a823          	sw	s3,80(s1)
    80003464:	b7e9                	j	8000342e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003466:	4108                	lw	a0,0(a0)
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	e36080e7          	jalr	-458(ra) # 8000329e <balloc>
    80003470:	0005059b          	sext.w	a1,a0
    80003474:	08b92023          	sw	a1,128(s2)
    80003478:	b759                	j	800033fe <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000347a:	00092503          	lw	a0,0(s2)
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	e20080e7          	jalr	-480(ra) # 8000329e <balloc>
    80003486:	0005099b          	sext.w	s3,a0
    8000348a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000348e:	8552                	mv	a0,s4
    80003490:	00001097          	auipc	ra,0x1
    80003494:	ee0080e7          	jalr	-288(ra) # 80004370 <log_write>
    80003498:	b771                	j	80003424 <bmap+0x54>
  panic("bmap: out of range");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	0be50513          	addi	a0,a0,190 # 80008558 <syscalls+0x128>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	09a080e7          	jalr	154(ra) # 8000053c <panic>

00000000800034aa <iget>:
{
    800034aa:	7179                	addi	sp,sp,-48
    800034ac:	f406                	sd	ra,40(sp)
    800034ae:	f022                	sd	s0,32(sp)
    800034b0:	ec26                	sd	s1,24(sp)
    800034b2:	e84a                	sd	s2,16(sp)
    800034b4:	e44e                	sd	s3,8(sp)
    800034b6:	e052                	sd	s4,0(sp)
    800034b8:	1800                	addi	s0,sp,48
    800034ba:	89aa                	mv	s3,a0
    800034bc:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034be:	0001d517          	auipc	a0,0x1d
    800034c2:	3a250513          	addi	a0,a0,930 # 80020860 <icache>
    800034c6:	ffffd097          	auipc	ra,0xffffd
    800034ca:	79a080e7          	jalr	1946(ra) # 80000c60 <acquire>
  empty = 0;
    800034ce:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034d0:	0001d497          	auipc	s1,0x1d
    800034d4:	3a848493          	addi	s1,s1,936 # 80020878 <icache+0x18>
    800034d8:	0001f697          	auipc	a3,0x1f
    800034dc:	e3068693          	addi	a3,a3,-464 # 80022308 <log>
    800034e0:	a039                	j	800034ee <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e2:	02090b63          	beqz	s2,80003518 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034e6:	08848493          	addi	s1,s1,136
    800034ea:	02d48a63          	beq	s1,a3,8000351e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034ee:	449c                	lw	a5,8(s1)
    800034f0:	fef059e3          	blez	a5,800034e2 <iget+0x38>
    800034f4:	4098                	lw	a4,0(s1)
    800034f6:	ff3716e3          	bne	a4,s3,800034e2 <iget+0x38>
    800034fa:	40d8                	lw	a4,4(s1)
    800034fc:	ff4713e3          	bne	a4,s4,800034e2 <iget+0x38>
      ip->ref++;
    80003500:	2785                	addiw	a5,a5,1
    80003502:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003504:	0001d517          	auipc	a0,0x1d
    80003508:	35c50513          	addi	a0,a0,860 # 80020860 <icache>
    8000350c:	ffffe097          	auipc	ra,0xffffe
    80003510:	808080e7          	jalr	-2040(ra) # 80000d14 <release>
      return ip;
    80003514:	8926                	mv	s2,s1
    80003516:	a03d                	j	80003544 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003518:	f7f9                	bnez	a5,800034e6 <iget+0x3c>
    8000351a:	8926                	mv	s2,s1
    8000351c:	b7e9                	j	800034e6 <iget+0x3c>
  if(empty == 0)
    8000351e:	02090c63          	beqz	s2,80003556 <iget+0xac>
  ip->dev = dev;
    80003522:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003526:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000352a:	4785                	li	a5,1
    8000352c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003530:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003534:	0001d517          	auipc	a0,0x1d
    80003538:	32c50513          	addi	a0,a0,812 # 80020860 <icache>
    8000353c:	ffffd097          	auipc	ra,0xffffd
    80003540:	7d8080e7          	jalr	2008(ra) # 80000d14 <release>
}
    80003544:	854a                	mv	a0,s2
    80003546:	70a2                	ld	ra,40(sp)
    80003548:	7402                	ld	s0,32(sp)
    8000354a:	64e2                	ld	s1,24(sp)
    8000354c:	6942                	ld	s2,16(sp)
    8000354e:	69a2                	ld	s3,8(sp)
    80003550:	6a02                	ld	s4,0(sp)
    80003552:	6145                	addi	sp,sp,48
    80003554:	8082                	ret
    panic("iget: no inodes");
    80003556:	00005517          	auipc	a0,0x5
    8000355a:	01a50513          	addi	a0,a0,26 # 80008570 <syscalls+0x140>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	fde080e7          	jalr	-34(ra) # 8000053c <panic>

0000000080003566 <fsinit>:
fsinit(int dev) {
    80003566:	7179                	addi	sp,sp,-48
    80003568:	f406                	sd	ra,40(sp)
    8000356a:	f022                	sd	s0,32(sp)
    8000356c:	ec26                	sd	s1,24(sp)
    8000356e:	e84a                	sd	s2,16(sp)
    80003570:	e44e                	sd	s3,8(sp)
    80003572:	1800                	addi	s0,sp,48
    80003574:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003576:	4585                	li	a1,1
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	a64080e7          	jalr	-1436(ra) # 80002fdc <bread>
    80003580:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003582:	0001d997          	auipc	s3,0x1d
    80003586:	2be98993          	addi	s3,s3,702 # 80020840 <sb>
    8000358a:	02000613          	li	a2,32
    8000358e:	05850593          	addi	a1,a0,88
    80003592:	854e                	mv	a0,s3
    80003594:	ffffe097          	auipc	ra,0xffffe
    80003598:	828080e7          	jalr	-2008(ra) # 80000dbc <memmove>
  brelse(bp);
    8000359c:	8526                	mv	a0,s1
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	b6e080e7          	jalr	-1170(ra) # 8000310c <brelse>
  if(sb.magic != FSMAGIC)
    800035a6:	0009a703          	lw	a4,0(s3)
    800035aa:	102037b7          	lui	a5,0x10203
    800035ae:	04078793          	addi	a5,a5,64 # 10203040 <spin-0x6fdfcfda>
    800035b2:	02f71263          	bne	a4,a5,800035d6 <fsinit+0x70>
  initlog(dev, &sb);
    800035b6:	0001d597          	auipc	a1,0x1d
    800035ba:	28a58593          	addi	a1,a1,650 # 80020840 <sb>
    800035be:	854a                	mv	a0,s2
    800035c0:	00001097          	auipc	ra,0x1
    800035c4:	b38080e7          	jalr	-1224(ra) # 800040f8 <initlog>
}
    800035c8:	70a2                	ld	ra,40(sp)
    800035ca:	7402                	ld	s0,32(sp)
    800035cc:	64e2                	ld	s1,24(sp)
    800035ce:	6942                	ld	s2,16(sp)
    800035d0:	69a2                	ld	s3,8(sp)
    800035d2:	6145                	addi	sp,sp,48
    800035d4:	8082                	ret
    panic("invalid file system");
    800035d6:	00005517          	auipc	a0,0x5
    800035da:	faa50513          	addi	a0,a0,-86 # 80008580 <syscalls+0x150>
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	f5e080e7          	jalr	-162(ra) # 8000053c <panic>

00000000800035e6 <iinit>:
{
    800035e6:	7179                	addi	sp,sp,-48
    800035e8:	f406                	sd	ra,40(sp)
    800035ea:	f022                	sd	s0,32(sp)
    800035ec:	ec26                	sd	s1,24(sp)
    800035ee:	e84a                	sd	s2,16(sp)
    800035f0:	e44e                	sd	s3,8(sp)
    800035f2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035f4:	00005597          	auipc	a1,0x5
    800035f8:	fa458593          	addi	a1,a1,-92 # 80008598 <syscalls+0x168>
    800035fc:	0001d517          	auipc	a0,0x1d
    80003600:	26450513          	addi	a0,a0,612 # 80020860 <icache>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	5cc080e7          	jalr	1484(ra) # 80000bd0 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000360c:	0001d497          	auipc	s1,0x1d
    80003610:	27c48493          	addi	s1,s1,636 # 80020888 <icache+0x28>
    80003614:	0001f997          	auipc	s3,0x1f
    80003618:	d0498993          	addi	s3,s3,-764 # 80022318 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000361c:	00005917          	auipc	s2,0x5
    80003620:	f8490913          	addi	s2,s2,-124 # 800085a0 <syscalls+0x170>
    80003624:	85ca                	mv	a1,s2
    80003626:	8526                	mv	a0,s1
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	e36080e7          	jalr	-458(ra) # 8000445e <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003630:	08848493          	addi	s1,s1,136
    80003634:	ff3498e3          	bne	s1,s3,80003624 <iinit+0x3e>
}
    80003638:	70a2                	ld	ra,40(sp)
    8000363a:	7402                	ld	s0,32(sp)
    8000363c:	64e2                	ld	s1,24(sp)
    8000363e:	6942                	ld	s2,16(sp)
    80003640:	69a2                	ld	s3,8(sp)
    80003642:	6145                	addi	sp,sp,48
    80003644:	8082                	ret

0000000080003646 <ialloc>:
{
    80003646:	715d                	addi	sp,sp,-80
    80003648:	e486                	sd	ra,72(sp)
    8000364a:	e0a2                	sd	s0,64(sp)
    8000364c:	fc26                	sd	s1,56(sp)
    8000364e:	f84a                	sd	s2,48(sp)
    80003650:	f44e                	sd	s3,40(sp)
    80003652:	f052                	sd	s4,32(sp)
    80003654:	ec56                	sd	s5,24(sp)
    80003656:	e85a                	sd	s6,16(sp)
    80003658:	e45e                	sd	s7,8(sp)
    8000365a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000365c:	0001d717          	auipc	a4,0x1d
    80003660:	1f072703          	lw	a4,496(a4) # 8002084c <sb+0xc>
    80003664:	4785                	li	a5,1
    80003666:	04e7fa63          	bgeu	a5,a4,800036ba <ialloc+0x74>
    8000366a:	8aaa                	mv	s5,a0
    8000366c:	8bae                	mv	s7,a1
    8000366e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003670:	0001da17          	auipc	s4,0x1d
    80003674:	1d0a0a13          	addi	s4,s4,464 # 80020840 <sb>
    80003678:	00048b1b          	sext.w	s6,s1
    8000367c:	0044d593          	srli	a1,s1,0x4
    80003680:	018a2783          	lw	a5,24(s4)
    80003684:	9dbd                	addw	a1,a1,a5
    80003686:	8556                	mv	a0,s5
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	954080e7          	jalr	-1708(ra) # 80002fdc <bread>
    80003690:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003692:	05850993          	addi	s3,a0,88
    80003696:	00f4f793          	andi	a5,s1,15
    8000369a:	079a                	slli	a5,a5,0x6
    8000369c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000369e:	00099783          	lh	a5,0(s3)
    800036a2:	c785                	beqz	a5,800036ca <ialloc+0x84>
    brelse(bp);
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	a68080e7          	jalr	-1432(ra) # 8000310c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036ac:	0485                	addi	s1,s1,1
    800036ae:	00ca2703          	lw	a4,12(s4)
    800036b2:	0004879b          	sext.w	a5,s1
    800036b6:	fce7e1e3          	bltu	a5,a4,80003678 <ialloc+0x32>
  panic("ialloc: no inodes");
    800036ba:	00005517          	auipc	a0,0x5
    800036be:	eee50513          	addi	a0,a0,-274 # 800085a8 <syscalls+0x178>
    800036c2:	ffffd097          	auipc	ra,0xffffd
    800036c6:	e7a080e7          	jalr	-390(ra) # 8000053c <panic>
      memset(dip, 0, sizeof(*dip));
    800036ca:	04000613          	li	a2,64
    800036ce:	4581                	li	a1,0
    800036d0:	854e                	mv	a0,s3
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	68a080e7          	jalr	1674(ra) # 80000d5c <memset>
      dip->type = type;
    800036da:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036de:	854a                	mv	a0,s2
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	c90080e7          	jalr	-880(ra) # 80004370 <log_write>
      brelse(bp);
    800036e8:	854a                	mv	a0,s2
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	a22080e7          	jalr	-1502(ra) # 8000310c <brelse>
      return iget(dev, inum);
    800036f2:	85da                	mv	a1,s6
    800036f4:	8556                	mv	a0,s5
    800036f6:	00000097          	auipc	ra,0x0
    800036fa:	db4080e7          	jalr	-588(ra) # 800034aa <iget>
}
    800036fe:	60a6                	ld	ra,72(sp)
    80003700:	6406                	ld	s0,64(sp)
    80003702:	74e2                	ld	s1,56(sp)
    80003704:	7942                	ld	s2,48(sp)
    80003706:	79a2                	ld	s3,40(sp)
    80003708:	7a02                	ld	s4,32(sp)
    8000370a:	6ae2                	ld	s5,24(sp)
    8000370c:	6b42                	ld	s6,16(sp)
    8000370e:	6ba2                	ld	s7,8(sp)
    80003710:	6161                	addi	sp,sp,80
    80003712:	8082                	ret

0000000080003714 <iupdate>:
{
    80003714:	1101                	addi	sp,sp,-32
    80003716:	ec06                	sd	ra,24(sp)
    80003718:	e822                	sd	s0,16(sp)
    8000371a:	e426                	sd	s1,8(sp)
    8000371c:	e04a                	sd	s2,0(sp)
    8000371e:	1000                	addi	s0,sp,32
    80003720:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003722:	415c                	lw	a5,4(a0)
    80003724:	0047d79b          	srliw	a5,a5,0x4
    80003728:	0001d597          	auipc	a1,0x1d
    8000372c:	1305a583          	lw	a1,304(a1) # 80020858 <sb+0x18>
    80003730:	9dbd                	addw	a1,a1,a5
    80003732:	4108                	lw	a0,0(a0)
    80003734:	00000097          	auipc	ra,0x0
    80003738:	8a8080e7          	jalr	-1880(ra) # 80002fdc <bread>
    8000373c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000373e:	05850793          	addi	a5,a0,88
    80003742:	40c8                	lw	a0,4(s1)
    80003744:	893d                	andi	a0,a0,15
    80003746:	051a                	slli	a0,a0,0x6
    80003748:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000374a:	04449703          	lh	a4,68(s1)
    8000374e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003752:	04649703          	lh	a4,70(s1)
    80003756:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000375a:	04849703          	lh	a4,72(s1)
    8000375e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003762:	04a49703          	lh	a4,74(s1)
    80003766:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000376a:	44f8                	lw	a4,76(s1)
    8000376c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000376e:	03400613          	li	a2,52
    80003772:	05048593          	addi	a1,s1,80
    80003776:	0531                	addi	a0,a0,12
    80003778:	ffffd097          	auipc	ra,0xffffd
    8000377c:	644080e7          	jalr	1604(ra) # 80000dbc <memmove>
  log_write(bp);
    80003780:	854a                	mv	a0,s2
    80003782:	00001097          	auipc	ra,0x1
    80003786:	bee080e7          	jalr	-1042(ra) # 80004370 <log_write>
  brelse(bp);
    8000378a:	854a                	mv	a0,s2
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	980080e7          	jalr	-1664(ra) # 8000310c <brelse>
}
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	64a2                	ld	s1,8(sp)
    8000379a:	6902                	ld	s2,0(sp)
    8000379c:	6105                	addi	sp,sp,32
    8000379e:	8082                	ret

00000000800037a0 <idup>:
{
    800037a0:	1101                	addi	sp,sp,-32
    800037a2:	ec06                	sd	ra,24(sp)
    800037a4:	e822                	sd	s0,16(sp)
    800037a6:	e426                	sd	s1,8(sp)
    800037a8:	1000                	addi	s0,sp,32
    800037aa:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037ac:	0001d517          	auipc	a0,0x1d
    800037b0:	0b450513          	addi	a0,a0,180 # 80020860 <icache>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	4ac080e7          	jalr	1196(ra) # 80000c60 <acquire>
  ip->ref++;
    800037bc:	449c                	lw	a5,8(s1)
    800037be:	2785                	addiw	a5,a5,1
    800037c0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037c2:	0001d517          	auipc	a0,0x1d
    800037c6:	09e50513          	addi	a0,a0,158 # 80020860 <icache>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	54a080e7          	jalr	1354(ra) # 80000d14 <release>
}
    800037d2:	8526                	mv	a0,s1
    800037d4:	60e2                	ld	ra,24(sp)
    800037d6:	6442                	ld	s0,16(sp)
    800037d8:	64a2                	ld	s1,8(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret

00000000800037de <ilock>:
{
    800037de:	1101                	addi	sp,sp,-32
    800037e0:	ec06                	sd	ra,24(sp)
    800037e2:	e822                	sd	s0,16(sp)
    800037e4:	e426                	sd	s1,8(sp)
    800037e6:	e04a                	sd	s2,0(sp)
    800037e8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ea:	c115                	beqz	a0,8000380e <ilock+0x30>
    800037ec:	84aa                	mv	s1,a0
    800037ee:	451c                	lw	a5,8(a0)
    800037f0:	00f05f63          	blez	a5,8000380e <ilock+0x30>
  acquiresleep(&ip->lock);
    800037f4:	0541                	addi	a0,a0,16
    800037f6:	00001097          	auipc	ra,0x1
    800037fa:	ca2080e7          	jalr	-862(ra) # 80004498 <acquiresleep>
  if(ip->valid == 0){
    800037fe:	40bc                	lw	a5,64(s1)
    80003800:	cf99                	beqz	a5,8000381e <ilock+0x40>
}
    80003802:	60e2                	ld	ra,24(sp)
    80003804:	6442                	ld	s0,16(sp)
    80003806:	64a2                	ld	s1,8(sp)
    80003808:	6902                	ld	s2,0(sp)
    8000380a:	6105                	addi	sp,sp,32
    8000380c:	8082                	ret
    panic("ilock");
    8000380e:	00005517          	auipc	a0,0x5
    80003812:	db250513          	addi	a0,a0,-590 # 800085c0 <syscalls+0x190>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	d26080e7          	jalr	-730(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000381e:	40dc                	lw	a5,4(s1)
    80003820:	0047d79b          	srliw	a5,a5,0x4
    80003824:	0001d597          	auipc	a1,0x1d
    80003828:	0345a583          	lw	a1,52(a1) # 80020858 <sb+0x18>
    8000382c:	9dbd                	addw	a1,a1,a5
    8000382e:	4088                	lw	a0,0(s1)
    80003830:	fffff097          	auipc	ra,0xfffff
    80003834:	7ac080e7          	jalr	1964(ra) # 80002fdc <bread>
    80003838:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000383a:	05850593          	addi	a1,a0,88
    8000383e:	40dc                	lw	a5,4(s1)
    80003840:	8bbd                	andi	a5,a5,15
    80003842:	079a                	slli	a5,a5,0x6
    80003844:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003846:	00059783          	lh	a5,0(a1)
    8000384a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000384e:	00259783          	lh	a5,2(a1)
    80003852:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003856:	00459783          	lh	a5,4(a1)
    8000385a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000385e:	00659783          	lh	a5,6(a1)
    80003862:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003866:	459c                	lw	a5,8(a1)
    80003868:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000386a:	03400613          	li	a2,52
    8000386e:	05b1                	addi	a1,a1,12
    80003870:	05048513          	addi	a0,s1,80
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	548080e7          	jalr	1352(ra) # 80000dbc <memmove>
    brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	88e080e7          	jalr	-1906(ra) # 8000310c <brelse>
    ip->valid = 1;
    80003886:	4785                	li	a5,1
    80003888:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000388a:	04449783          	lh	a5,68(s1)
    8000388e:	fbb5                	bnez	a5,80003802 <ilock+0x24>
      panic("ilock: no type");
    80003890:	00005517          	auipc	a0,0x5
    80003894:	d3850513          	addi	a0,a0,-712 # 800085c8 <syscalls+0x198>
    80003898:	ffffd097          	auipc	ra,0xffffd
    8000389c:	ca4080e7          	jalr	-860(ra) # 8000053c <panic>

00000000800038a0 <iunlock>:
{
    800038a0:	1101                	addi	sp,sp,-32
    800038a2:	ec06                	sd	ra,24(sp)
    800038a4:	e822                	sd	s0,16(sp)
    800038a6:	e426                	sd	s1,8(sp)
    800038a8:	e04a                	sd	s2,0(sp)
    800038aa:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038ac:	c905                	beqz	a0,800038dc <iunlock+0x3c>
    800038ae:	84aa                	mv	s1,a0
    800038b0:	01050913          	addi	s2,a0,16
    800038b4:	854a                	mv	a0,s2
    800038b6:	00001097          	auipc	ra,0x1
    800038ba:	c7c080e7          	jalr	-900(ra) # 80004532 <holdingsleep>
    800038be:	cd19                	beqz	a0,800038dc <iunlock+0x3c>
    800038c0:	449c                	lw	a5,8(s1)
    800038c2:	00f05d63          	blez	a5,800038dc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038c6:	854a                	mv	a0,s2
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	c26080e7          	jalr	-986(ra) # 800044ee <releasesleep>
}
    800038d0:	60e2                	ld	ra,24(sp)
    800038d2:	6442                	ld	s0,16(sp)
    800038d4:	64a2                	ld	s1,8(sp)
    800038d6:	6902                	ld	s2,0(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret
    panic("iunlock");
    800038dc:	00005517          	auipc	a0,0x5
    800038e0:	cfc50513          	addi	a0,a0,-772 # 800085d8 <syscalls+0x1a8>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	c58080e7          	jalr	-936(ra) # 8000053c <panic>

00000000800038ec <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038ec:	7179                	addi	sp,sp,-48
    800038ee:	f406                	sd	ra,40(sp)
    800038f0:	f022                	sd	s0,32(sp)
    800038f2:	ec26                	sd	s1,24(sp)
    800038f4:	e84a                	sd	s2,16(sp)
    800038f6:	e44e                	sd	s3,8(sp)
    800038f8:	e052                	sd	s4,0(sp)
    800038fa:	1800                	addi	s0,sp,48
    800038fc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038fe:	05050493          	addi	s1,a0,80
    80003902:	08050913          	addi	s2,a0,128
    80003906:	a021                	j	8000390e <itrunc+0x22>
    80003908:	0491                	addi	s1,s1,4
    8000390a:	01248d63          	beq	s1,s2,80003924 <itrunc+0x38>
    if(ip->addrs[i]){
    8000390e:	408c                	lw	a1,0(s1)
    80003910:	dde5                	beqz	a1,80003908 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	90c080e7          	jalr	-1780(ra) # 80003222 <bfree>
      ip->addrs[i] = 0;
    8000391e:	0004a023          	sw	zero,0(s1)
    80003922:	b7dd                	j	80003908 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003924:	0809a583          	lw	a1,128(s3)
    80003928:	e185                	bnez	a1,80003948 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000392a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000392e:	854e                	mv	a0,s3
    80003930:	00000097          	auipc	ra,0x0
    80003934:	de4080e7          	jalr	-540(ra) # 80003714 <iupdate>
}
    80003938:	70a2                	ld	ra,40(sp)
    8000393a:	7402                	ld	s0,32(sp)
    8000393c:	64e2                	ld	s1,24(sp)
    8000393e:	6942                	ld	s2,16(sp)
    80003940:	69a2                	ld	s3,8(sp)
    80003942:	6a02                	ld	s4,0(sp)
    80003944:	6145                	addi	sp,sp,48
    80003946:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003948:	0009a503          	lw	a0,0(s3)
    8000394c:	fffff097          	auipc	ra,0xfffff
    80003950:	690080e7          	jalr	1680(ra) # 80002fdc <bread>
    80003954:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003956:	05850493          	addi	s1,a0,88
    8000395a:	45850913          	addi	s2,a0,1112
    8000395e:	a811                	j	80003972 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003960:	0009a503          	lw	a0,0(s3)
    80003964:	00000097          	auipc	ra,0x0
    80003968:	8be080e7          	jalr	-1858(ra) # 80003222 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000396c:	0491                	addi	s1,s1,4
    8000396e:	01248563          	beq	s1,s2,80003978 <itrunc+0x8c>
      if(a[j])
    80003972:	408c                	lw	a1,0(s1)
    80003974:	dde5                	beqz	a1,8000396c <itrunc+0x80>
    80003976:	b7ed                	j	80003960 <itrunc+0x74>
    brelse(bp);
    80003978:	8552                	mv	a0,s4
    8000397a:	fffff097          	auipc	ra,0xfffff
    8000397e:	792080e7          	jalr	1938(ra) # 8000310c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003982:	0809a583          	lw	a1,128(s3)
    80003986:	0009a503          	lw	a0,0(s3)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	898080e7          	jalr	-1896(ra) # 80003222 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003992:	0809a023          	sw	zero,128(s3)
    80003996:	bf51                	j	8000392a <itrunc+0x3e>

0000000080003998 <iput>:
{
    80003998:	1101                	addi	sp,sp,-32
    8000399a:	ec06                	sd	ra,24(sp)
    8000399c:	e822                	sd	s0,16(sp)
    8000399e:	e426                	sd	s1,8(sp)
    800039a0:	e04a                	sd	s2,0(sp)
    800039a2:	1000                	addi	s0,sp,32
    800039a4:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039a6:	0001d517          	auipc	a0,0x1d
    800039aa:	eba50513          	addi	a0,a0,-326 # 80020860 <icache>
    800039ae:	ffffd097          	auipc	ra,0xffffd
    800039b2:	2b2080e7          	jalr	690(ra) # 80000c60 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b6:	4498                	lw	a4,8(s1)
    800039b8:	4785                	li	a5,1
    800039ba:	02f70363          	beq	a4,a5,800039e0 <iput+0x48>
  ip->ref--;
    800039be:	449c                	lw	a5,8(s1)
    800039c0:	37fd                	addiw	a5,a5,-1
    800039c2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039c4:	0001d517          	auipc	a0,0x1d
    800039c8:	e9c50513          	addi	a0,a0,-356 # 80020860 <icache>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	348080e7          	jalr	840(ra) # 80000d14 <release>
}
    800039d4:	60e2                	ld	ra,24(sp)
    800039d6:	6442                	ld	s0,16(sp)
    800039d8:	64a2                	ld	s1,8(sp)
    800039da:	6902                	ld	s2,0(sp)
    800039dc:	6105                	addi	sp,sp,32
    800039de:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039e0:	40bc                	lw	a5,64(s1)
    800039e2:	dff1                	beqz	a5,800039be <iput+0x26>
    800039e4:	04a49783          	lh	a5,74(s1)
    800039e8:	fbf9                	bnez	a5,800039be <iput+0x26>
    acquiresleep(&ip->lock);
    800039ea:	01048913          	addi	s2,s1,16
    800039ee:	854a                	mv	a0,s2
    800039f0:	00001097          	auipc	ra,0x1
    800039f4:	aa8080e7          	jalr	-1368(ra) # 80004498 <acquiresleep>
    release(&icache.lock);
    800039f8:	0001d517          	auipc	a0,0x1d
    800039fc:	e6850513          	addi	a0,a0,-408 # 80020860 <icache>
    80003a00:	ffffd097          	auipc	ra,0xffffd
    80003a04:	314080e7          	jalr	788(ra) # 80000d14 <release>
    itrunc(ip);
    80003a08:	8526                	mv	a0,s1
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	ee2080e7          	jalr	-286(ra) # 800038ec <itrunc>
    ip->type = 0;
    80003a12:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a16:	8526                	mv	a0,s1
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	cfc080e7          	jalr	-772(ra) # 80003714 <iupdate>
    ip->valid = 0;
    80003a20:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a24:	854a                	mv	a0,s2
    80003a26:	00001097          	auipc	ra,0x1
    80003a2a:	ac8080e7          	jalr	-1336(ra) # 800044ee <releasesleep>
    acquire(&icache.lock);
    80003a2e:	0001d517          	auipc	a0,0x1d
    80003a32:	e3250513          	addi	a0,a0,-462 # 80020860 <icache>
    80003a36:	ffffd097          	auipc	ra,0xffffd
    80003a3a:	22a080e7          	jalr	554(ra) # 80000c60 <acquire>
    80003a3e:	b741                	j	800039be <iput+0x26>

0000000080003a40 <iunlockput>:
{
    80003a40:	1101                	addi	sp,sp,-32
    80003a42:	ec06                	sd	ra,24(sp)
    80003a44:	e822                	sd	s0,16(sp)
    80003a46:	e426                	sd	s1,8(sp)
    80003a48:	1000                	addi	s0,sp,32
    80003a4a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a4c:	00000097          	auipc	ra,0x0
    80003a50:	e54080e7          	jalr	-428(ra) # 800038a0 <iunlock>
  iput(ip);
    80003a54:	8526                	mv	a0,s1
    80003a56:	00000097          	auipc	ra,0x0
    80003a5a:	f42080e7          	jalr	-190(ra) # 80003998 <iput>
}
    80003a5e:	60e2                	ld	ra,24(sp)
    80003a60:	6442                	ld	s0,16(sp)
    80003a62:	64a2                	ld	s1,8(sp)
    80003a64:	6105                	addi	sp,sp,32
    80003a66:	8082                	ret

0000000080003a68 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a68:	1141                	addi	sp,sp,-16
    80003a6a:	e422                	sd	s0,8(sp)
    80003a6c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a6e:	411c                	lw	a5,0(a0)
    80003a70:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a72:	415c                	lw	a5,4(a0)
    80003a74:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a76:	04451783          	lh	a5,68(a0)
    80003a7a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a7e:	04a51783          	lh	a5,74(a0)
    80003a82:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a86:	04c56783          	lwu	a5,76(a0)
    80003a8a:	e99c                	sd	a5,16(a1)
}
    80003a8c:	6422                	ld	s0,8(sp)
    80003a8e:	0141                	addi	sp,sp,16
    80003a90:	8082                	ret

0000000080003a92 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a92:	457c                	lw	a5,76(a0)
    80003a94:	0ed7e863          	bltu	a5,a3,80003b84 <readi+0xf2>
{
    80003a98:	7159                	addi	sp,sp,-112
    80003a9a:	f486                	sd	ra,104(sp)
    80003a9c:	f0a2                	sd	s0,96(sp)
    80003a9e:	eca6                	sd	s1,88(sp)
    80003aa0:	e8ca                	sd	s2,80(sp)
    80003aa2:	e4ce                	sd	s3,72(sp)
    80003aa4:	e0d2                	sd	s4,64(sp)
    80003aa6:	fc56                	sd	s5,56(sp)
    80003aa8:	f85a                	sd	s6,48(sp)
    80003aaa:	f45e                	sd	s7,40(sp)
    80003aac:	f062                	sd	s8,32(sp)
    80003aae:	ec66                	sd	s9,24(sp)
    80003ab0:	e86a                	sd	s10,16(sp)
    80003ab2:	e46e                	sd	s11,8(sp)
    80003ab4:	1880                	addi	s0,sp,112
    80003ab6:	8baa                	mv	s7,a0
    80003ab8:	8c2e                	mv	s8,a1
    80003aba:	8ab2                	mv	s5,a2
    80003abc:	84b6                	mv	s1,a3
    80003abe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ac0:	9f35                	addw	a4,a4,a3
    return 0;
    80003ac2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003ac4:	08d76f63          	bltu	a4,a3,80003b62 <readi+0xd0>
  if(off + n > ip->size)
    80003ac8:	00e7f463          	bgeu	a5,a4,80003ad0 <readi+0x3e>
    n = ip->size - off;
    80003acc:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad0:	0a0b0863          	beqz	s6,80003b80 <readi+0xee>
    80003ad4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ada:	5cfd                	li	s9,-1
    80003adc:	a82d                	j	80003b16 <readi+0x84>
    80003ade:	020a1d93          	slli	s11,s4,0x20
    80003ae2:	020ddd93          	srli	s11,s11,0x20
    80003ae6:	05890613          	addi	a2,s2,88
    80003aea:	86ee                	mv	a3,s11
    80003aec:	963a                	add	a2,a2,a4
    80003aee:	85d6                	mv	a1,s5
    80003af0:	8562                	mv	a0,s8
    80003af2:	fffff097          	auipc	ra,0xfffff
    80003af6:	a64080e7          	jalr	-1436(ra) # 80002556 <either_copyout>
    80003afa:	05950d63          	beq	a0,s9,80003b54 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003afe:	854a                	mv	a0,s2
    80003b00:	fffff097          	auipc	ra,0xfffff
    80003b04:	60c080e7          	jalr	1548(ra) # 8000310c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b08:	013a09bb          	addw	s3,s4,s3
    80003b0c:	009a04bb          	addw	s1,s4,s1
    80003b10:	9aee                	add	s5,s5,s11
    80003b12:	0569f663          	bgeu	s3,s6,80003b5e <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b16:	000ba903          	lw	s2,0(s7)
    80003b1a:	00a4d59b          	srliw	a1,s1,0xa
    80003b1e:	855e                	mv	a0,s7
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	8b0080e7          	jalr	-1872(ra) # 800033d0 <bmap>
    80003b28:	0005059b          	sext.w	a1,a0
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	fffff097          	auipc	ra,0xfffff
    80003b32:	4ae080e7          	jalr	1198(ra) # 80002fdc <bread>
    80003b36:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b38:	3ff4f713          	andi	a4,s1,1023
    80003b3c:	40ed07bb          	subw	a5,s10,a4
    80003b40:	413b06bb          	subw	a3,s6,s3
    80003b44:	8a3e                	mv	s4,a5
    80003b46:	2781                	sext.w	a5,a5
    80003b48:	0006861b          	sext.w	a2,a3
    80003b4c:	f8f679e3          	bgeu	a2,a5,80003ade <readi+0x4c>
    80003b50:	8a36                	mv	s4,a3
    80003b52:	b771                	j	80003ade <readi+0x4c>
      brelse(bp);
    80003b54:	854a                	mv	a0,s2
    80003b56:	fffff097          	auipc	ra,0xfffff
    80003b5a:	5b6080e7          	jalr	1462(ra) # 8000310c <brelse>
  }
  return tot;
    80003b5e:	0009851b          	sext.w	a0,s3
}
    80003b62:	70a6                	ld	ra,104(sp)
    80003b64:	7406                	ld	s0,96(sp)
    80003b66:	64e6                	ld	s1,88(sp)
    80003b68:	6946                	ld	s2,80(sp)
    80003b6a:	69a6                	ld	s3,72(sp)
    80003b6c:	6a06                	ld	s4,64(sp)
    80003b6e:	7ae2                	ld	s5,56(sp)
    80003b70:	7b42                	ld	s6,48(sp)
    80003b72:	7ba2                	ld	s7,40(sp)
    80003b74:	7c02                	ld	s8,32(sp)
    80003b76:	6ce2                	ld	s9,24(sp)
    80003b78:	6d42                	ld	s10,16(sp)
    80003b7a:	6da2                	ld	s11,8(sp)
    80003b7c:	6165                	addi	sp,sp,112
    80003b7e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b80:	89da                	mv	s3,s6
    80003b82:	bff1                	j	80003b5e <readi+0xcc>
    return 0;
    80003b84:	4501                	li	a0,0
}
    80003b86:	8082                	ret

0000000080003b88 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b88:	457c                	lw	a5,76(a0)
    80003b8a:	10d7e663          	bltu	a5,a3,80003c96 <writei+0x10e>
{
    80003b8e:	7159                	addi	sp,sp,-112
    80003b90:	f486                	sd	ra,104(sp)
    80003b92:	f0a2                	sd	s0,96(sp)
    80003b94:	eca6                	sd	s1,88(sp)
    80003b96:	e8ca                	sd	s2,80(sp)
    80003b98:	e4ce                	sd	s3,72(sp)
    80003b9a:	e0d2                	sd	s4,64(sp)
    80003b9c:	fc56                	sd	s5,56(sp)
    80003b9e:	f85a                	sd	s6,48(sp)
    80003ba0:	f45e                	sd	s7,40(sp)
    80003ba2:	f062                	sd	s8,32(sp)
    80003ba4:	ec66                	sd	s9,24(sp)
    80003ba6:	e86a                	sd	s10,16(sp)
    80003ba8:	e46e                	sd	s11,8(sp)
    80003baa:	1880                	addi	s0,sp,112
    80003bac:	8baa                	mv	s7,a0
    80003bae:	8c2e                	mv	s8,a1
    80003bb0:	8ab2                	mv	s5,a2
    80003bb2:	8936                	mv	s2,a3
    80003bb4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bb6:	00e687bb          	addw	a5,a3,a4
    80003bba:	0ed7e063          	bltu	a5,a3,80003c9a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003bbe:	00043737          	lui	a4,0x43
    80003bc2:	0cf76e63          	bltu	a4,a5,80003c9e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc6:	0a0b0763          	beqz	s6,80003c74 <writei+0xec>
    80003bca:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bcc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bd0:	5cfd                	li	s9,-1
    80003bd2:	a091                	j	80003c16 <writei+0x8e>
    80003bd4:	02099d93          	slli	s11,s3,0x20
    80003bd8:	020ddd93          	srli	s11,s11,0x20
    80003bdc:	05848513          	addi	a0,s1,88
    80003be0:	86ee                	mv	a3,s11
    80003be2:	8656                	mv	a2,s5
    80003be4:	85e2                	mv	a1,s8
    80003be6:	953a                	add	a0,a0,a4
    80003be8:	fffff097          	auipc	ra,0xfffff
    80003bec:	9c4080e7          	jalr	-1596(ra) # 800025ac <either_copyin>
    80003bf0:	07950263          	beq	a0,s9,80003c54 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bf4:	8526                	mv	a0,s1
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	77a080e7          	jalr	1914(ra) # 80004370 <log_write>
    brelse(bp);
    80003bfe:	8526                	mv	a0,s1
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	50c080e7          	jalr	1292(ra) # 8000310c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c08:	01498a3b          	addw	s4,s3,s4
    80003c0c:	0129893b          	addw	s2,s3,s2
    80003c10:	9aee                	add	s5,s5,s11
    80003c12:	056a7663          	bgeu	s4,s6,80003c5e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c16:	000ba483          	lw	s1,0(s7)
    80003c1a:	00a9559b          	srliw	a1,s2,0xa
    80003c1e:	855e                	mv	a0,s7
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	7b0080e7          	jalr	1968(ra) # 800033d0 <bmap>
    80003c28:	0005059b          	sext.w	a1,a0
    80003c2c:	8526                	mv	a0,s1
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	3ae080e7          	jalr	942(ra) # 80002fdc <bread>
    80003c36:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c38:	3ff97713          	andi	a4,s2,1023
    80003c3c:	40ed07bb          	subw	a5,s10,a4
    80003c40:	414b06bb          	subw	a3,s6,s4
    80003c44:	89be                	mv	s3,a5
    80003c46:	2781                	sext.w	a5,a5
    80003c48:	0006861b          	sext.w	a2,a3
    80003c4c:	f8f674e3          	bgeu	a2,a5,80003bd4 <writei+0x4c>
    80003c50:	89b6                	mv	s3,a3
    80003c52:	b749                	j	80003bd4 <writei+0x4c>
      brelse(bp);
    80003c54:	8526                	mv	a0,s1
    80003c56:	fffff097          	auipc	ra,0xfffff
    80003c5a:	4b6080e7          	jalr	1206(ra) # 8000310c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c5e:	04cba783          	lw	a5,76(s7)
    80003c62:	0127f463          	bgeu	a5,s2,80003c6a <writei+0xe2>
      ip->size = off;
    80003c66:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c6a:	855e                	mv	a0,s7
    80003c6c:	00000097          	auipc	ra,0x0
    80003c70:	aa8080e7          	jalr	-1368(ra) # 80003714 <iupdate>
  }

  return n;
    80003c74:	000b051b          	sext.w	a0,s6
}
    80003c78:	70a6                	ld	ra,104(sp)
    80003c7a:	7406                	ld	s0,96(sp)
    80003c7c:	64e6                	ld	s1,88(sp)
    80003c7e:	6946                	ld	s2,80(sp)
    80003c80:	69a6                	ld	s3,72(sp)
    80003c82:	6a06                	ld	s4,64(sp)
    80003c84:	7ae2                	ld	s5,56(sp)
    80003c86:	7b42                	ld	s6,48(sp)
    80003c88:	7ba2                	ld	s7,40(sp)
    80003c8a:	7c02                	ld	s8,32(sp)
    80003c8c:	6ce2                	ld	s9,24(sp)
    80003c8e:	6d42                	ld	s10,16(sp)
    80003c90:	6da2                	ld	s11,8(sp)
    80003c92:	6165                	addi	sp,sp,112
    80003c94:	8082                	ret
    return -1;
    80003c96:	557d                	li	a0,-1
}
    80003c98:	8082                	ret
    return -1;
    80003c9a:	557d                	li	a0,-1
    80003c9c:	bff1                	j	80003c78 <writei+0xf0>
    return -1;
    80003c9e:	557d                	li	a0,-1
    80003ca0:	bfe1                	j	80003c78 <writei+0xf0>

0000000080003ca2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ca2:	1141                	addi	sp,sp,-16
    80003ca4:	e406                	sd	ra,8(sp)
    80003ca6:	e022                	sd	s0,0(sp)
    80003ca8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003caa:	4639                	li	a2,14
    80003cac:	ffffd097          	auipc	ra,0xffffd
    80003cb0:	18c080e7          	jalr	396(ra) # 80000e38 <strncmp>
}
    80003cb4:	60a2                	ld	ra,8(sp)
    80003cb6:	6402                	ld	s0,0(sp)
    80003cb8:	0141                	addi	sp,sp,16
    80003cba:	8082                	ret

0000000080003cbc <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003cbc:	7139                	addi	sp,sp,-64
    80003cbe:	fc06                	sd	ra,56(sp)
    80003cc0:	f822                	sd	s0,48(sp)
    80003cc2:	f426                	sd	s1,40(sp)
    80003cc4:	f04a                	sd	s2,32(sp)
    80003cc6:	ec4e                	sd	s3,24(sp)
    80003cc8:	e852                	sd	s4,16(sp)
    80003cca:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ccc:	04451703          	lh	a4,68(a0)
    80003cd0:	4785                	li	a5,1
    80003cd2:	00f71a63          	bne	a4,a5,80003ce6 <dirlookup+0x2a>
    80003cd6:	892a                	mv	s2,a0
    80003cd8:	89ae                	mv	s3,a1
    80003cda:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cdc:	457c                	lw	a5,76(a0)
    80003cde:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ce0:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ce2:	e79d                	bnez	a5,80003d10 <dirlookup+0x54>
    80003ce4:	a8a5                	j	80003d5c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ce6:	00005517          	auipc	a0,0x5
    80003cea:	8fa50513          	addi	a0,a0,-1798 # 800085e0 <syscalls+0x1b0>
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	84e080e7          	jalr	-1970(ra) # 8000053c <panic>
      panic("dirlookup read");
    80003cf6:	00005517          	auipc	a0,0x5
    80003cfa:	90250513          	addi	a0,a0,-1790 # 800085f8 <syscalls+0x1c8>
    80003cfe:	ffffd097          	auipc	ra,0xffffd
    80003d02:	83e080e7          	jalr	-1986(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d06:	24c1                	addiw	s1,s1,16
    80003d08:	04c92783          	lw	a5,76(s2)
    80003d0c:	04f4f763          	bgeu	s1,a5,80003d5a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d10:	4741                	li	a4,16
    80003d12:	86a6                	mv	a3,s1
    80003d14:	fc040613          	addi	a2,s0,-64
    80003d18:	4581                	li	a1,0
    80003d1a:	854a                	mv	a0,s2
    80003d1c:	00000097          	auipc	ra,0x0
    80003d20:	d76080e7          	jalr	-650(ra) # 80003a92 <readi>
    80003d24:	47c1                	li	a5,16
    80003d26:	fcf518e3          	bne	a0,a5,80003cf6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d2a:	fc045783          	lhu	a5,-64(s0)
    80003d2e:	dfe1                	beqz	a5,80003d06 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d30:	fc240593          	addi	a1,s0,-62
    80003d34:	854e                	mv	a0,s3
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	f6c080e7          	jalr	-148(ra) # 80003ca2 <namecmp>
    80003d3e:	f561                	bnez	a0,80003d06 <dirlookup+0x4a>
      if(poff)
    80003d40:	000a0463          	beqz	s4,80003d48 <dirlookup+0x8c>
        *poff = off;
    80003d44:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d48:	fc045583          	lhu	a1,-64(s0)
    80003d4c:	00092503          	lw	a0,0(s2)
    80003d50:	fffff097          	auipc	ra,0xfffff
    80003d54:	75a080e7          	jalr	1882(ra) # 800034aa <iget>
    80003d58:	a011                	j	80003d5c <dirlookup+0xa0>
  return 0;
    80003d5a:	4501                	li	a0,0
}
    80003d5c:	70e2                	ld	ra,56(sp)
    80003d5e:	7442                	ld	s0,48(sp)
    80003d60:	74a2                	ld	s1,40(sp)
    80003d62:	7902                	ld	s2,32(sp)
    80003d64:	69e2                	ld	s3,24(sp)
    80003d66:	6a42                	ld	s4,16(sp)
    80003d68:	6121                	addi	sp,sp,64
    80003d6a:	8082                	ret

0000000080003d6c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d6c:	711d                	addi	sp,sp,-96
    80003d6e:	ec86                	sd	ra,88(sp)
    80003d70:	e8a2                	sd	s0,80(sp)
    80003d72:	e4a6                	sd	s1,72(sp)
    80003d74:	e0ca                	sd	s2,64(sp)
    80003d76:	fc4e                	sd	s3,56(sp)
    80003d78:	f852                	sd	s4,48(sp)
    80003d7a:	f456                	sd	s5,40(sp)
    80003d7c:	f05a                	sd	s6,32(sp)
    80003d7e:	ec5e                	sd	s7,24(sp)
    80003d80:	e862                	sd	s8,16(sp)
    80003d82:	e466                	sd	s9,8(sp)
    80003d84:	1080                	addi	s0,sp,96
    80003d86:	84aa                	mv	s1,a0
    80003d88:	8b2e                	mv	s6,a1
    80003d8a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d8c:	00054703          	lbu	a4,0(a0)
    80003d90:	02f00793          	li	a5,47
    80003d94:	02f70363          	beq	a4,a5,80003dba <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d98:	ffffe097          	auipc	ra,0xffffe
    80003d9c:	c96080e7          	jalr	-874(ra) # 80001a2e <myproc>
    80003da0:	15053503          	ld	a0,336(a0)
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	9fc080e7          	jalr	-1540(ra) # 800037a0 <idup>
    80003dac:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dae:	02f00913          	li	s2,47
  len = path - s;
    80003db2:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003db4:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003db6:	4c05                	li	s8,1
    80003db8:	a865                	j	80003e70 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003dba:	4585                	li	a1,1
    80003dbc:	4505                	li	a0,1
    80003dbe:	fffff097          	auipc	ra,0xfffff
    80003dc2:	6ec080e7          	jalr	1772(ra) # 800034aa <iget>
    80003dc6:	89aa                	mv	s3,a0
    80003dc8:	b7dd                	j	80003dae <namex+0x42>
      iunlockput(ip);
    80003dca:	854e                	mv	a0,s3
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	c74080e7          	jalr	-908(ra) # 80003a40 <iunlockput>
      return 0;
    80003dd4:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	60e6                	ld	ra,88(sp)
    80003dda:	6446                	ld	s0,80(sp)
    80003ddc:	64a6                	ld	s1,72(sp)
    80003dde:	6906                	ld	s2,64(sp)
    80003de0:	79e2                	ld	s3,56(sp)
    80003de2:	7a42                	ld	s4,48(sp)
    80003de4:	7aa2                	ld	s5,40(sp)
    80003de6:	7b02                	ld	s6,32(sp)
    80003de8:	6be2                	ld	s7,24(sp)
    80003dea:	6c42                	ld	s8,16(sp)
    80003dec:	6ca2                	ld	s9,8(sp)
    80003dee:	6125                	addi	sp,sp,96
    80003df0:	8082                	ret
      iunlock(ip);
    80003df2:	854e                	mv	a0,s3
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	aac080e7          	jalr	-1364(ra) # 800038a0 <iunlock>
      return ip;
    80003dfc:	bfe9                	j	80003dd6 <namex+0x6a>
      iunlockput(ip);
    80003dfe:	854e                	mv	a0,s3
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	c40080e7          	jalr	-960(ra) # 80003a40 <iunlockput>
      return 0;
    80003e08:	89d2                	mv	s3,s4
    80003e0a:	b7f1                	j	80003dd6 <namex+0x6a>
  len = path - s;
    80003e0c:	40b48633          	sub	a2,s1,a1
    80003e10:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e14:	094cd463          	bge	s9,s4,80003e9c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e18:	4639                	li	a2,14
    80003e1a:	8556                	mv	a0,s5
    80003e1c:	ffffd097          	auipc	ra,0xffffd
    80003e20:	fa0080e7          	jalr	-96(ra) # 80000dbc <memmove>
  while(*path == '/')
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	01279763          	bne	a5,s2,80003e36 <namex+0xca>
    path++;
    80003e2c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e2e:	0004c783          	lbu	a5,0(s1)
    80003e32:	ff278de3          	beq	a5,s2,80003e2c <namex+0xc0>
    ilock(ip);
    80003e36:	854e                	mv	a0,s3
    80003e38:	00000097          	auipc	ra,0x0
    80003e3c:	9a6080e7          	jalr	-1626(ra) # 800037de <ilock>
    if(ip->type != T_DIR){
    80003e40:	04499783          	lh	a5,68(s3)
    80003e44:	f98793e3          	bne	a5,s8,80003dca <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e48:	000b0563          	beqz	s6,80003e52 <namex+0xe6>
    80003e4c:	0004c783          	lbu	a5,0(s1)
    80003e50:	d3cd                	beqz	a5,80003df2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e52:	865e                	mv	a2,s7
    80003e54:	85d6                	mv	a1,s5
    80003e56:	854e                	mv	a0,s3
    80003e58:	00000097          	auipc	ra,0x0
    80003e5c:	e64080e7          	jalr	-412(ra) # 80003cbc <dirlookup>
    80003e60:	8a2a                	mv	s4,a0
    80003e62:	dd51                	beqz	a0,80003dfe <namex+0x92>
    iunlockput(ip);
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	bda080e7          	jalr	-1062(ra) # 80003a40 <iunlockput>
    ip = next;
    80003e6e:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	05279763          	bne	a5,s2,80003ec2 <namex+0x156>
    path++;
    80003e78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	ff278de3          	beq	a5,s2,80003e78 <namex+0x10c>
  if(*path == 0)
    80003e82:	c79d                	beqz	a5,80003eb0 <namex+0x144>
    path++;
    80003e84:	85a6                	mv	a1,s1
  len = path - s;
    80003e86:	8a5e                	mv	s4,s7
    80003e88:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e8a:	01278963          	beq	a5,s2,80003e9c <namex+0x130>
    80003e8e:	dfbd                	beqz	a5,80003e0c <namex+0xa0>
    path++;
    80003e90:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e92:	0004c783          	lbu	a5,0(s1)
    80003e96:	ff279ce3          	bne	a5,s2,80003e8e <namex+0x122>
    80003e9a:	bf8d                	j	80003e0c <namex+0xa0>
    memmove(name, s, len);
    80003e9c:	2601                	sext.w	a2,a2
    80003e9e:	8556                	mv	a0,s5
    80003ea0:	ffffd097          	auipc	ra,0xffffd
    80003ea4:	f1c080e7          	jalr	-228(ra) # 80000dbc <memmove>
    name[len] = 0;
    80003ea8:	9a56                	add	s4,s4,s5
    80003eaa:	000a0023          	sb	zero,0(s4)
    80003eae:	bf9d                	j	80003e24 <namex+0xb8>
  if(nameiparent){
    80003eb0:	f20b03e3          	beqz	s6,80003dd6 <namex+0x6a>
    iput(ip);
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	ae2080e7          	jalr	-1310(ra) # 80003998 <iput>
    return 0;
    80003ebe:	4981                	li	s3,0
    80003ec0:	bf19                	j	80003dd6 <namex+0x6a>
  if(*path == 0)
    80003ec2:	d7fd                	beqz	a5,80003eb0 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ec4:	0004c783          	lbu	a5,0(s1)
    80003ec8:	85a6                	mv	a1,s1
    80003eca:	b7d1                	j	80003e8e <namex+0x122>

0000000080003ecc <dirlink>:
{
    80003ecc:	7139                	addi	sp,sp,-64
    80003ece:	fc06                	sd	ra,56(sp)
    80003ed0:	f822                	sd	s0,48(sp)
    80003ed2:	f426                	sd	s1,40(sp)
    80003ed4:	f04a                	sd	s2,32(sp)
    80003ed6:	ec4e                	sd	s3,24(sp)
    80003ed8:	e852                	sd	s4,16(sp)
    80003eda:	0080                	addi	s0,sp,64
    80003edc:	892a                	mv	s2,a0
    80003ede:	8a2e                	mv	s4,a1
    80003ee0:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ee2:	4601                	li	a2,0
    80003ee4:	00000097          	auipc	ra,0x0
    80003ee8:	dd8080e7          	jalr	-552(ra) # 80003cbc <dirlookup>
    80003eec:	e93d                	bnez	a0,80003f62 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eee:	04c92483          	lw	s1,76(s2)
    80003ef2:	c49d                	beqz	s1,80003f20 <dirlink+0x54>
    80003ef4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef6:	4741                	li	a4,16
    80003ef8:	86a6                	mv	a3,s1
    80003efa:	fc040613          	addi	a2,s0,-64
    80003efe:	4581                	li	a1,0
    80003f00:	854a                	mv	a0,s2
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	b90080e7          	jalr	-1136(ra) # 80003a92 <readi>
    80003f0a:	47c1                	li	a5,16
    80003f0c:	06f51163          	bne	a0,a5,80003f6e <dirlink+0xa2>
    if(de.inum == 0)
    80003f10:	fc045783          	lhu	a5,-64(s0)
    80003f14:	c791                	beqz	a5,80003f20 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f16:	24c1                	addiw	s1,s1,16
    80003f18:	04c92783          	lw	a5,76(s2)
    80003f1c:	fcf4ede3          	bltu	s1,a5,80003ef6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f20:	4639                	li	a2,14
    80003f22:	85d2                	mv	a1,s4
    80003f24:	fc240513          	addi	a0,s0,-62
    80003f28:	ffffd097          	auipc	ra,0xffffd
    80003f2c:	f4c080e7          	jalr	-180(ra) # 80000e74 <strncpy>
  de.inum = inum;
    80003f30:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f34:	4741                	li	a4,16
    80003f36:	86a6                	mv	a3,s1
    80003f38:	fc040613          	addi	a2,s0,-64
    80003f3c:	4581                	li	a1,0
    80003f3e:	854a                	mv	a0,s2
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	c48080e7          	jalr	-952(ra) # 80003b88 <writei>
    80003f48:	872a                	mv	a4,a0
    80003f4a:	47c1                	li	a5,16
  return 0;
    80003f4c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f4e:	02f71863          	bne	a4,a5,80003f7e <dirlink+0xb2>
}
    80003f52:	70e2                	ld	ra,56(sp)
    80003f54:	7442                	ld	s0,48(sp)
    80003f56:	74a2                	ld	s1,40(sp)
    80003f58:	7902                	ld	s2,32(sp)
    80003f5a:	69e2                	ld	s3,24(sp)
    80003f5c:	6a42                	ld	s4,16(sp)
    80003f5e:	6121                	addi	sp,sp,64
    80003f60:	8082                	ret
    iput(ip);
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	a36080e7          	jalr	-1482(ra) # 80003998 <iput>
    return -1;
    80003f6a:	557d                	li	a0,-1
    80003f6c:	b7dd                	j	80003f52 <dirlink+0x86>
      panic("dirlink read");
    80003f6e:	00004517          	auipc	a0,0x4
    80003f72:	69a50513          	addi	a0,a0,1690 # 80008608 <syscalls+0x1d8>
    80003f76:	ffffc097          	auipc	ra,0xffffc
    80003f7a:	5c6080e7          	jalr	1478(ra) # 8000053c <panic>
    panic("dirlink");
    80003f7e:	00004517          	auipc	a0,0x4
    80003f82:	7aa50513          	addi	a0,a0,1962 # 80008728 <syscalls+0x2f8>
    80003f86:	ffffc097          	auipc	ra,0xffffc
    80003f8a:	5b6080e7          	jalr	1462(ra) # 8000053c <panic>

0000000080003f8e <namei>:

struct inode*
namei(char *path)
{
    80003f8e:	1101                	addi	sp,sp,-32
    80003f90:	ec06                	sd	ra,24(sp)
    80003f92:	e822                	sd	s0,16(sp)
    80003f94:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f96:	fe040613          	addi	a2,s0,-32
    80003f9a:	4581                	li	a1,0
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	dd0080e7          	jalr	-560(ra) # 80003d6c <namex>
}
    80003fa4:	60e2                	ld	ra,24(sp)
    80003fa6:	6442                	ld	s0,16(sp)
    80003fa8:	6105                	addi	sp,sp,32
    80003faa:	8082                	ret

0000000080003fac <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003fac:	1141                	addi	sp,sp,-16
    80003fae:	e406                	sd	ra,8(sp)
    80003fb0:	e022                	sd	s0,0(sp)
    80003fb2:	0800                	addi	s0,sp,16
    80003fb4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fb6:	4585                	li	a1,1
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	db4080e7          	jalr	-588(ra) # 80003d6c <namex>
}
    80003fc0:	60a2                	ld	ra,8(sp)
    80003fc2:	6402                	ld	s0,0(sp)
    80003fc4:	0141                	addi	sp,sp,16
    80003fc6:	8082                	ret

0000000080003fc8 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fc8:	1101                	addi	sp,sp,-32
    80003fca:	ec06                	sd	ra,24(sp)
    80003fcc:	e822                	sd	s0,16(sp)
    80003fce:	e426                	sd	s1,8(sp)
    80003fd0:	e04a                	sd	s2,0(sp)
    80003fd2:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fd4:	0001e917          	auipc	s2,0x1e
    80003fd8:	33490913          	addi	s2,s2,820 # 80022308 <log>
    80003fdc:	01892583          	lw	a1,24(s2)
    80003fe0:	02892503          	lw	a0,40(s2)
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	ff8080e7          	jalr	-8(ra) # 80002fdc <bread>
    80003fec:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fee:	02c92683          	lw	a3,44(s2)
    80003ff2:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003ff4:	02d05763          	blez	a3,80004022 <write_head+0x5a>
    80003ff8:	0001e797          	auipc	a5,0x1e
    80003ffc:	34078793          	addi	a5,a5,832 # 80022338 <log+0x30>
    80004000:	05c50713          	addi	a4,a0,92
    80004004:	36fd                	addiw	a3,a3,-1
    80004006:	1682                	slli	a3,a3,0x20
    80004008:	9281                	srli	a3,a3,0x20
    8000400a:	068a                	slli	a3,a3,0x2
    8000400c:	0001e617          	auipc	a2,0x1e
    80004010:	33060613          	addi	a2,a2,816 # 8002233c <log+0x34>
    80004014:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004016:	4390                	lw	a2,0(a5)
    80004018:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000401a:	0791                	addi	a5,a5,4
    8000401c:	0711                	addi	a4,a4,4
    8000401e:	fed79ce3          	bne	a5,a3,80004016 <write_head+0x4e>
  }
  bwrite(buf);
    80004022:	8526                	mv	a0,s1
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	0aa080e7          	jalr	170(ra) # 800030ce <bwrite>
  brelse(buf);
    8000402c:	8526                	mv	a0,s1
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	0de080e7          	jalr	222(ra) # 8000310c <brelse>
}
    80004036:	60e2                	ld	ra,24(sp)
    80004038:	6442                	ld	s0,16(sp)
    8000403a:	64a2                	ld	s1,8(sp)
    8000403c:	6902                	ld	s2,0(sp)
    8000403e:	6105                	addi	sp,sp,32
    80004040:	8082                	ret

0000000080004042 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004042:	0001e797          	auipc	a5,0x1e
    80004046:	2f27a783          	lw	a5,754(a5) # 80022334 <log+0x2c>
    8000404a:	0af05663          	blez	a5,800040f6 <install_trans+0xb4>
{
    8000404e:	7139                	addi	sp,sp,-64
    80004050:	fc06                	sd	ra,56(sp)
    80004052:	f822                	sd	s0,48(sp)
    80004054:	f426                	sd	s1,40(sp)
    80004056:	f04a                	sd	s2,32(sp)
    80004058:	ec4e                	sd	s3,24(sp)
    8000405a:	e852                	sd	s4,16(sp)
    8000405c:	e456                	sd	s5,8(sp)
    8000405e:	0080                	addi	s0,sp,64
    80004060:	0001ea97          	auipc	s5,0x1e
    80004064:	2d8a8a93          	addi	s5,s5,728 # 80022338 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004068:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000406a:	0001e997          	auipc	s3,0x1e
    8000406e:	29e98993          	addi	s3,s3,670 # 80022308 <log>
    80004072:	0189a583          	lw	a1,24(s3)
    80004076:	014585bb          	addw	a1,a1,s4
    8000407a:	2585                	addiw	a1,a1,1
    8000407c:	0289a503          	lw	a0,40(s3)
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	f5c080e7          	jalr	-164(ra) # 80002fdc <bread>
    80004088:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000408a:	000aa583          	lw	a1,0(s5)
    8000408e:	0289a503          	lw	a0,40(s3)
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	f4a080e7          	jalr	-182(ra) # 80002fdc <bread>
    8000409a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000409c:	40000613          	li	a2,1024
    800040a0:	05890593          	addi	a1,s2,88
    800040a4:	05850513          	addi	a0,a0,88
    800040a8:	ffffd097          	auipc	ra,0xffffd
    800040ac:	d14080e7          	jalr	-748(ra) # 80000dbc <memmove>
    bwrite(dbuf);  // write dst to disk
    800040b0:	8526                	mv	a0,s1
    800040b2:	fffff097          	auipc	ra,0xfffff
    800040b6:	01c080e7          	jalr	28(ra) # 800030ce <bwrite>
    bunpin(dbuf);
    800040ba:	8526                	mv	a0,s1
    800040bc:	fffff097          	auipc	ra,0xfffff
    800040c0:	12a080e7          	jalr	298(ra) # 800031e6 <bunpin>
    brelse(lbuf);
    800040c4:	854a                	mv	a0,s2
    800040c6:	fffff097          	auipc	ra,0xfffff
    800040ca:	046080e7          	jalr	70(ra) # 8000310c <brelse>
    brelse(dbuf);
    800040ce:	8526                	mv	a0,s1
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	03c080e7          	jalr	60(ra) # 8000310c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d8:	2a05                	addiw	s4,s4,1
    800040da:	0a91                	addi	s5,s5,4
    800040dc:	02c9a783          	lw	a5,44(s3)
    800040e0:	f8fa49e3          	blt	s4,a5,80004072 <install_trans+0x30>
}
    800040e4:	70e2                	ld	ra,56(sp)
    800040e6:	7442                	ld	s0,48(sp)
    800040e8:	74a2                	ld	s1,40(sp)
    800040ea:	7902                	ld	s2,32(sp)
    800040ec:	69e2                	ld	s3,24(sp)
    800040ee:	6a42                	ld	s4,16(sp)
    800040f0:	6aa2                	ld	s5,8(sp)
    800040f2:	6121                	addi	sp,sp,64
    800040f4:	8082                	ret
    800040f6:	8082                	ret

00000000800040f8 <initlog>:
{
    800040f8:	7179                	addi	sp,sp,-48
    800040fa:	f406                	sd	ra,40(sp)
    800040fc:	f022                	sd	s0,32(sp)
    800040fe:	ec26                	sd	s1,24(sp)
    80004100:	e84a                	sd	s2,16(sp)
    80004102:	e44e                	sd	s3,8(sp)
    80004104:	1800                	addi	s0,sp,48
    80004106:	892a                	mv	s2,a0
    80004108:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000410a:	0001e497          	auipc	s1,0x1e
    8000410e:	1fe48493          	addi	s1,s1,510 # 80022308 <log>
    80004112:	00004597          	auipc	a1,0x4
    80004116:	50658593          	addi	a1,a1,1286 # 80008618 <syscalls+0x1e8>
    8000411a:	8526                	mv	a0,s1
    8000411c:	ffffd097          	auipc	ra,0xffffd
    80004120:	ab4080e7          	jalr	-1356(ra) # 80000bd0 <initlock>
  log.start = sb->logstart;
    80004124:	0149a583          	lw	a1,20(s3)
    80004128:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000412a:	0109a783          	lw	a5,16(s3)
    8000412e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004130:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004134:	854a                	mv	a0,s2
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	ea6080e7          	jalr	-346(ra) # 80002fdc <bread>
  log.lh.n = lh->n;
    8000413e:	4d3c                	lw	a5,88(a0)
    80004140:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004142:	02f05563          	blez	a5,8000416c <initlog+0x74>
    80004146:	05c50713          	addi	a4,a0,92
    8000414a:	0001e697          	auipc	a3,0x1e
    8000414e:	1ee68693          	addi	a3,a3,494 # 80022338 <log+0x30>
    80004152:	37fd                	addiw	a5,a5,-1
    80004154:	1782                	slli	a5,a5,0x20
    80004156:	9381                	srli	a5,a5,0x20
    80004158:	078a                	slli	a5,a5,0x2
    8000415a:	06050613          	addi	a2,a0,96
    8000415e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004160:	4310                	lw	a2,0(a4)
    80004162:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004164:	0711                	addi	a4,a4,4
    80004166:	0691                	addi	a3,a3,4
    80004168:	fef71ce3          	bne	a4,a5,80004160 <initlog+0x68>
  brelse(buf);
    8000416c:	fffff097          	auipc	ra,0xfffff
    80004170:	fa0080e7          	jalr	-96(ra) # 8000310c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004174:	00000097          	auipc	ra,0x0
    80004178:	ece080e7          	jalr	-306(ra) # 80004042 <install_trans>
  log.lh.n = 0;
    8000417c:	0001e797          	auipc	a5,0x1e
    80004180:	1a07ac23          	sw	zero,440(a5) # 80022334 <log+0x2c>
  write_head(); // clear the log
    80004184:	00000097          	auipc	ra,0x0
    80004188:	e44080e7          	jalr	-444(ra) # 80003fc8 <write_head>
}
    8000418c:	70a2                	ld	ra,40(sp)
    8000418e:	7402                	ld	s0,32(sp)
    80004190:	64e2                	ld	s1,24(sp)
    80004192:	6942                	ld	s2,16(sp)
    80004194:	69a2                	ld	s3,8(sp)
    80004196:	6145                	addi	sp,sp,48
    80004198:	8082                	ret

000000008000419a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000419a:	1101                	addi	sp,sp,-32
    8000419c:	ec06                	sd	ra,24(sp)
    8000419e:	e822                	sd	s0,16(sp)
    800041a0:	e426                	sd	s1,8(sp)
    800041a2:	e04a                	sd	s2,0(sp)
    800041a4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041a6:	0001e517          	auipc	a0,0x1e
    800041aa:	16250513          	addi	a0,a0,354 # 80022308 <log>
    800041ae:	ffffd097          	auipc	ra,0xffffd
    800041b2:	ab2080e7          	jalr	-1358(ra) # 80000c60 <acquire>
  while(1){
    if(log.committing){
    800041b6:	0001e497          	auipc	s1,0x1e
    800041ba:	15248493          	addi	s1,s1,338 # 80022308 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041be:	4979                	li	s2,30
    800041c0:	a039                	j	800041ce <begin_op+0x34>
      sleep(&log, &log.lock);
    800041c2:	85a6                	mv	a1,s1
    800041c4:	8526                	mv	a0,s1
    800041c6:	ffffe097          	auipc	ra,0xffffe
    800041ca:	12e080e7          	jalr	302(ra) # 800022f4 <sleep>
    if(log.committing){
    800041ce:	50dc                	lw	a5,36(s1)
    800041d0:	fbed                	bnez	a5,800041c2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041d2:	509c                	lw	a5,32(s1)
    800041d4:	0017871b          	addiw	a4,a5,1
    800041d8:	0007069b          	sext.w	a3,a4
    800041dc:	0027179b          	slliw	a5,a4,0x2
    800041e0:	9fb9                	addw	a5,a5,a4
    800041e2:	0017979b          	slliw	a5,a5,0x1
    800041e6:	54d8                	lw	a4,44(s1)
    800041e8:	9fb9                	addw	a5,a5,a4
    800041ea:	00f95963          	bge	s2,a5,800041fc <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041ee:	85a6                	mv	a1,s1
    800041f0:	8526                	mv	a0,s1
    800041f2:	ffffe097          	auipc	ra,0xffffe
    800041f6:	102080e7          	jalr	258(ra) # 800022f4 <sleep>
    800041fa:	bfd1                	j	800041ce <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041fc:	0001e517          	auipc	a0,0x1e
    80004200:	10c50513          	addi	a0,a0,268 # 80022308 <log>
    80004204:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004206:	ffffd097          	auipc	ra,0xffffd
    8000420a:	b0e080e7          	jalr	-1266(ra) # 80000d14 <release>
      break;
    }
  }
}
    8000420e:	60e2                	ld	ra,24(sp)
    80004210:	6442                	ld	s0,16(sp)
    80004212:	64a2                	ld	s1,8(sp)
    80004214:	6902                	ld	s2,0(sp)
    80004216:	6105                	addi	sp,sp,32
    80004218:	8082                	ret

000000008000421a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000421a:	7139                	addi	sp,sp,-64
    8000421c:	fc06                	sd	ra,56(sp)
    8000421e:	f822                	sd	s0,48(sp)
    80004220:	f426                	sd	s1,40(sp)
    80004222:	f04a                	sd	s2,32(sp)
    80004224:	ec4e                	sd	s3,24(sp)
    80004226:	e852                	sd	s4,16(sp)
    80004228:	e456                	sd	s5,8(sp)
    8000422a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000422c:	0001e497          	auipc	s1,0x1e
    80004230:	0dc48493          	addi	s1,s1,220 # 80022308 <log>
    80004234:	8526                	mv	a0,s1
    80004236:	ffffd097          	auipc	ra,0xffffd
    8000423a:	a2a080e7          	jalr	-1494(ra) # 80000c60 <acquire>
  log.outstanding -= 1;
    8000423e:	509c                	lw	a5,32(s1)
    80004240:	37fd                	addiw	a5,a5,-1
    80004242:	0007891b          	sext.w	s2,a5
    80004246:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004248:	50dc                	lw	a5,36(s1)
    8000424a:	efb9                	bnez	a5,800042a8 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000424c:	06091663          	bnez	s2,800042b8 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004250:	0001e497          	auipc	s1,0x1e
    80004254:	0b848493          	addi	s1,s1,184 # 80022308 <log>
    80004258:	4785                	li	a5,1
    8000425a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000425c:	8526                	mv	a0,s1
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	ab6080e7          	jalr	-1354(ra) # 80000d14 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004266:	54dc                	lw	a5,44(s1)
    80004268:	06f04763          	bgtz	a5,800042d6 <end_op+0xbc>
    acquire(&log.lock);
    8000426c:	0001e497          	auipc	s1,0x1e
    80004270:	09c48493          	addi	s1,s1,156 # 80022308 <log>
    80004274:	8526                	mv	a0,s1
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	9ea080e7          	jalr	-1558(ra) # 80000c60 <acquire>
    log.committing = 0;
    8000427e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004282:	8526                	mv	a0,s1
    80004284:	ffffe097          	auipc	ra,0xffffe
    80004288:	1f6080e7          	jalr	502(ra) # 8000247a <wakeup>
    release(&log.lock);
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	a86080e7          	jalr	-1402(ra) # 80000d14 <release>
}
    80004296:	70e2                	ld	ra,56(sp)
    80004298:	7442                	ld	s0,48(sp)
    8000429a:	74a2                	ld	s1,40(sp)
    8000429c:	7902                	ld	s2,32(sp)
    8000429e:	69e2                	ld	s3,24(sp)
    800042a0:	6a42                	ld	s4,16(sp)
    800042a2:	6aa2                	ld	s5,8(sp)
    800042a4:	6121                	addi	sp,sp,64
    800042a6:	8082                	ret
    panic("log.committing");
    800042a8:	00004517          	auipc	a0,0x4
    800042ac:	37850513          	addi	a0,a0,888 # 80008620 <syscalls+0x1f0>
    800042b0:	ffffc097          	auipc	ra,0xffffc
    800042b4:	28c080e7          	jalr	652(ra) # 8000053c <panic>
    wakeup(&log);
    800042b8:	0001e497          	auipc	s1,0x1e
    800042bc:	05048493          	addi	s1,s1,80 # 80022308 <log>
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffe097          	auipc	ra,0xffffe
    800042c6:	1b8080e7          	jalr	440(ra) # 8000247a <wakeup>
  release(&log.lock);
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	a48080e7          	jalr	-1464(ra) # 80000d14 <release>
  if(do_commit){
    800042d4:	b7c9                	j	80004296 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d6:	0001ea97          	auipc	s5,0x1e
    800042da:	062a8a93          	addi	s5,s5,98 # 80022338 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042de:	0001ea17          	auipc	s4,0x1e
    800042e2:	02aa0a13          	addi	s4,s4,42 # 80022308 <log>
    800042e6:	018a2583          	lw	a1,24(s4)
    800042ea:	012585bb          	addw	a1,a1,s2
    800042ee:	2585                	addiw	a1,a1,1
    800042f0:	028a2503          	lw	a0,40(s4)
    800042f4:	fffff097          	auipc	ra,0xfffff
    800042f8:	ce8080e7          	jalr	-792(ra) # 80002fdc <bread>
    800042fc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042fe:	000aa583          	lw	a1,0(s5)
    80004302:	028a2503          	lw	a0,40(s4)
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	cd6080e7          	jalr	-810(ra) # 80002fdc <bread>
    8000430e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004310:	40000613          	li	a2,1024
    80004314:	05850593          	addi	a1,a0,88
    80004318:	05848513          	addi	a0,s1,88
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	aa0080e7          	jalr	-1376(ra) # 80000dbc <memmove>
    bwrite(to);  // write the log
    80004324:	8526                	mv	a0,s1
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	da8080e7          	jalr	-600(ra) # 800030ce <bwrite>
    brelse(from);
    8000432e:	854e                	mv	a0,s3
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	ddc080e7          	jalr	-548(ra) # 8000310c <brelse>
    brelse(to);
    80004338:	8526                	mv	a0,s1
    8000433a:	fffff097          	auipc	ra,0xfffff
    8000433e:	dd2080e7          	jalr	-558(ra) # 8000310c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004342:	2905                	addiw	s2,s2,1
    80004344:	0a91                	addi	s5,s5,4
    80004346:	02ca2783          	lw	a5,44(s4)
    8000434a:	f8f94ee3          	blt	s2,a5,800042e6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	c7a080e7          	jalr	-902(ra) # 80003fc8 <write_head>
    install_trans(); // Now install writes to home locations
    80004356:	00000097          	auipc	ra,0x0
    8000435a:	cec080e7          	jalr	-788(ra) # 80004042 <install_trans>
    log.lh.n = 0;
    8000435e:	0001e797          	auipc	a5,0x1e
    80004362:	fc07ab23          	sw	zero,-42(a5) # 80022334 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004366:	00000097          	auipc	ra,0x0
    8000436a:	c62080e7          	jalr	-926(ra) # 80003fc8 <write_head>
    8000436e:	bdfd                	j	8000426c <end_op+0x52>

0000000080004370 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004370:	1101                	addi	sp,sp,-32
    80004372:	ec06                	sd	ra,24(sp)
    80004374:	e822                	sd	s0,16(sp)
    80004376:	e426                	sd	s1,8(sp)
    80004378:	e04a                	sd	s2,0(sp)
    8000437a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000437c:	0001e717          	auipc	a4,0x1e
    80004380:	fb872703          	lw	a4,-72(a4) # 80022334 <log+0x2c>
    80004384:	47f5                	li	a5,29
    80004386:	08e7c063          	blt	a5,a4,80004406 <log_write+0x96>
    8000438a:	84aa                	mv	s1,a0
    8000438c:	0001e797          	auipc	a5,0x1e
    80004390:	f987a783          	lw	a5,-104(a5) # 80022324 <log+0x1c>
    80004394:	37fd                	addiw	a5,a5,-1
    80004396:	06f75863          	bge	a4,a5,80004406 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000439a:	0001e797          	auipc	a5,0x1e
    8000439e:	f8e7a783          	lw	a5,-114(a5) # 80022328 <log+0x20>
    800043a2:	06f05a63          	blez	a5,80004416 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043a6:	0001e917          	auipc	s2,0x1e
    800043aa:	f6290913          	addi	s2,s2,-158 # 80022308 <log>
    800043ae:	854a                	mv	a0,s2
    800043b0:	ffffd097          	auipc	ra,0xffffd
    800043b4:	8b0080e7          	jalr	-1872(ra) # 80000c60 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043b8:	02c92603          	lw	a2,44(s2)
    800043bc:	06c05563          	blez	a2,80004426 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043c0:	44cc                	lw	a1,12(s1)
    800043c2:	0001e717          	auipc	a4,0x1e
    800043c6:	f7670713          	addi	a4,a4,-138 # 80022338 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ca:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043cc:	4314                	lw	a3,0(a4)
    800043ce:	04b68d63          	beq	a3,a1,80004428 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043d2:	2785                	addiw	a5,a5,1
    800043d4:	0711                	addi	a4,a4,4
    800043d6:	fec79be3          	bne	a5,a2,800043cc <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043da:	0621                	addi	a2,a2,8
    800043dc:	060a                	slli	a2,a2,0x2
    800043de:	0001e797          	auipc	a5,0x1e
    800043e2:	f2a78793          	addi	a5,a5,-214 # 80022308 <log>
    800043e6:	963e                	add	a2,a2,a5
    800043e8:	44dc                	lw	a5,12(s1)
    800043ea:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043ec:	8526                	mv	a0,s1
    800043ee:	fffff097          	auipc	ra,0xfffff
    800043f2:	dbc080e7          	jalr	-580(ra) # 800031aa <bpin>
    log.lh.n++;
    800043f6:	0001e717          	auipc	a4,0x1e
    800043fa:	f1270713          	addi	a4,a4,-238 # 80022308 <log>
    800043fe:	575c                	lw	a5,44(a4)
    80004400:	2785                	addiw	a5,a5,1
    80004402:	d75c                	sw	a5,44(a4)
    80004404:	a83d                	j	80004442 <log_write+0xd2>
    panic("too big a transaction");
    80004406:	00004517          	auipc	a0,0x4
    8000440a:	22a50513          	addi	a0,a0,554 # 80008630 <syscalls+0x200>
    8000440e:	ffffc097          	auipc	ra,0xffffc
    80004412:	12e080e7          	jalr	302(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004416:	00004517          	auipc	a0,0x4
    8000441a:	23250513          	addi	a0,a0,562 # 80008648 <syscalls+0x218>
    8000441e:	ffffc097          	auipc	ra,0xffffc
    80004422:	11e080e7          	jalr	286(ra) # 8000053c <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004426:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004428:	00878713          	addi	a4,a5,8
    8000442c:	00271693          	slli	a3,a4,0x2
    80004430:	0001e717          	auipc	a4,0x1e
    80004434:	ed870713          	addi	a4,a4,-296 # 80022308 <log>
    80004438:	9736                	add	a4,a4,a3
    8000443a:	44d4                	lw	a3,12(s1)
    8000443c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000443e:	faf607e3          	beq	a2,a5,800043ec <log_write+0x7c>
  }
  release(&log.lock);
    80004442:	0001e517          	auipc	a0,0x1e
    80004446:	ec650513          	addi	a0,a0,-314 # 80022308 <log>
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	8ca080e7          	jalr	-1846(ra) # 80000d14 <release>
}
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6902                	ld	s2,0(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	e426                	sd	s1,8(sp)
    80004466:	e04a                	sd	s2,0(sp)
    80004468:	1000                	addi	s0,sp,32
    8000446a:	84aa                	mv	s1,a0
    8000446c:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000446e:	00004597          	auipc	a1,0x4
    80004472:	1fa58593          	addi	a1,a1,506 # 80008668 <syscalls+0x238>
    80004476:	0521                	addi	a0,a0,8
    80004478:	ffffc097          	auipc	ra,0xffffc
    8000447c:	758080e7          	jalr	1880(ra) # 80000bd0 <initlock>
  lk->name = name;
    80004480:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004484:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004488:	0204a423          	sw	zero,40(s1)
}
    8000448c:	60e2                	ld	ra,24(sp)
    8000448e:	6442                	ld	s0,16(sp)
    80004490:	64a2                	ld	s1,8(sp)
    80004492:	6902                	ld	s2,0(sp)
    80004494:	6105                	addi	sp,sp,32
    80004496:	8082                	ret

0000000080004498 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004498:	1101                	addi	sp,sp,-32
    8000449a:	ec06                	sd	ra,24(sp)
    8000449c:	e822                	sd	s0,16(sp)
    8000449e:	e426                	sd	s1,8(sp)
    800044a0:	e04a                	sd	s2,0(sp)
    800044a2:	1000                	addi	s0,sp,32
    800044a4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044a6:	00850913          	addi	s2,a0,8
    800044aa:	854a                	mv	a0,s2
    800044ac:	ffffc097          	auipc	ra,0xffffc
    800044b0:	7b4080e7          	jalr	1972(ra) # 80000c60 <acquire>
  while (lk->locked) {
    800044b4:	409c                	lw	a5,0(s1)
    800044b6:	cb89                	beqz	a5,800044c8 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044b8:	85ca                	mv	a1,s2
    800044ba:	8526                	mv	a0,s1
    800044bc:	ffffe097          	auipc	ra,0xffffe
    800044c0:	e38080e7          	jalr	-456(ra) # 800022f4 <sleep>
  while (lk->locked) {
    800044c4:	409c                	lw	a5,0(s1)
    800044c6:	fbed                	bnez	a5,800044b8 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044c8:	4785                	li	a5,1
    800044ca:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044cc:	ffffd097          	auipc	ra,0xffffd
    800044d0:	562080e7          	jalr	1378(ra) # 80001a2e <myproc>
    800044d4:	5d1c                	lw	a5,56(a0)
    800044d6:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044d8:	854a                	mv	a0,s2
    800044da:	ffffd097          	auipc	ra,0xffffd
    800044de:	83a080e7          	jalr	-1990(ra) # 80000d14 <release>
}
    800044e2:	60e2                	ld	ra,24(sp)
    800044e4:	6442                	ld	s0,16(sp)
    800044e6:	64a2                	ld	s1,8(sp)
    800044e8:	6902                	ld	s2,0(sp)
    800044ea:	6105                	addi	sp,sp,32
    800044ec:	8082                	ret

00000000800044ee <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044ee:	1101                	addi	sp,sp,-32
    800044f0:	ec06                	sd	ra,24(sp)
    800044f2:	e822                	sd	s0,16(sp)
    800044f4:	e426                	sd	s1,8(sp)
    800044f6:	e04a                	sd	s2,0(sp)
    800044f8:	1000                	addi	s0,sp,32
    800044fa:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044fc:	00850913          	addi	s2,a0,8
    80004500:	854a                	mv	a0,s2
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	75e080e7          	jalr	1886(ra) # 80000c60 <acquire>
  lk->locked = 0;
    8000450a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000450e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004512:	8526                	mv	a0,s1
    80004514:	ffffe097          	auipc	ra,0xffffe
    80004518:	f66080e7          	jalr	-154(ra) # 8000247a <wakeup>
  release(&lk->lk);
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	7f6080e7          	jalr	2038(ra) # 80000d14 <release>
}
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6902                	ld	s2,0(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret

0000000080004532 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004532:	7179                	addi	sp,sp,-48
    80004534:	f406                	sd	ra,40(sp)
    80004536:	f022                	sd	s0,32(sp)
    80004538:	ec26                	sd	s1,24(sp)
    8000453a:	e84a                	sd	s2,16(sp)
    8000453c:	e44e                	sd	s3,8(sp)
    8000453e:	1800                	addi	s0,sp,48
    80004540:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004542:	00850913          	addi	s2,a0,8
    80004546:	854a                	mv	a0,s2
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	718080e7          	jalr	1816(ra) # 80000c60 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004550:	409c                	lw	a5,0(s1)
    80004552:	ef99                	bnez	a5,80004570 <holdingsleep+0x3e>
    80004554:	4481                	li	s1,0
  release(&lk->lk);
    80004556:	854a                	mv	a0,s2
    80004558:	ffffc097          	auipc	ra,0xffffc
    8000455c:	7bc080e7          	jalr	1980(ra) # 80000d14 <release>
  return r;
}
    80004560:	8526                	mv	a0,s1
    80004562:	70a2                	ld	ra,40(sp)
    80004564:	7402                	ld	s0,32(sp)
    80004566:	64e2                	ld	s1,24(sp)
    80004568:	6942                	ld	s2,16(sp)
    8000456a:	69a2                	ld	s3,8(sp)
    8000456c:	6145                	addi	sp,sp,48
    8000456e:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004570:	0284a983          	lw	s3,40(s1)
    80004574:	ffffd097          	auipc	ra,0xffffd
    80004578:	4ba080e7          	jalr	1210(ra) # 80001a2e <myproc>
    8000457c:	5d04                	lw	s1,56(a0)
    8000457e:	413484b3          	sub	s1,s1,s3
    80004582:	0014b493          	seqz	s1,s1
    80004586:	bfc1                	j	80004556 <holdingsleep+0x24>

0000000080004588 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004588:	1141                	addi	sp,sp,-16
    8000458a:	e406                	sd	ra,8(sp)
    8000458c:	e022                	sd	s0,0(sp)
    8000458e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004590:	00004597          	auipc	a1,0x4
    80004594:	0e858593          	addi	a1,a1,232 # 80008678 <syscalls+0x248>
    80004598:	0001e517          	auipc	a0,0x1e
    8000459c:	eb850513          	addi	a0,a0,-328 # 80022450 <ftable>
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	630080e7          	jalr	1584(ra) # 80000bd0 <initlock>
}
    800045a8:	60a2                	ld	ra,8(sp)
    800045aa:	6402                	ld	s0,0(sp)
    800045ac:	0141                	addi	sp,sp,16
    800045ae:	8082                	ret

00000000800045b0 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045b0:	1101                	addi	sp,sp,-32
    800045b2:	ec06                	sd	ra,24(sp)
    800045b4:	e822                	sd	s0,16(sp)
    800045b6:	e426                	sd	s1,8(sp)
    800045b8:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045ba:	0001e517          	auipc	a0,0x1e
    800045be:	e9650513          	addi	a0,a0,-362 # 80022450 <ftable>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	69e080e7          	jalr	1694(ra) # 80000c60 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ca:	0001e497          	auipc	s1,0x1e
    800045ce:	e9e48493          	addi	s1,s1,-354 # 80022468 <ftable+0x18>
    800045d2:	0001f717          	auipc	a4,0x1f
    800045d6:	e3670713          	addi	a4,a4,-458 # 80023408 <ftable+0xfb8>
    if(f->ref == 0){
    800045da:	40dc                	lw	a5,4(s1)
    800045dc:	cf99                	beqz	a5,800045fa <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045de:	02848493          	addi	s1,s1,40
    800045e2:	fee49ce3          	bne	s1,a4,800045da <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045e6:	0001e517          	auipc	a0,0x1e
    800045ea:	e6a50513          	addi	a0,a0,-406 # 80022450 <ftable>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	726080e7          	jalr	1830(ra) # 80000d14 <release>
  return 0;
    800045f6:	4481                	li	s1,0
    800045f8:	a819                	j	8000460e <filealloc+0x5e>
      f->ref = 1;
    800045fa:	4785                	li	a5,1
    800045fc:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045fe:	0001e517          	auipc	a0,0x1e
    80004602:	e5250513          	addi	a0,a0,-430 # 80022450 <ftable>
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	70e080e7          	jalr	1806(ra) # 80000d14 <release>
}
    8000460e:	8526                	mv	a0,s1
    80004610:	60e2                	ld	ra,24(sp)
    80004612:	6442                	ld	s0,16(sp)
    80004614:	64a2                	ld	s1,8(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret

000000008000461a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000461a:	1101                	addi	sp,sp,-32
    8000461c:	ec06                	sd	ra,24(sp)
    8000461e:	e822                	sd	s0,16(sp)
    80004620:	e426                	sd	s1,8(sp)
    80004622:	1000                	addi	s0,sp,32
    80004624:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004626:	0001e517          	auipc	a0,0x1e
    8000462a:	e2a50513          	addi	a0,a0,-470 # 80022450 <ftable>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	632080e7          	jalr	1586(ra) # 80000c60 <acquire>
  if(f->ref < 1)
    80004636:	40dc                	lw	a5,4(s1)
    80004638:	02f05263          	blez	a5,8000465c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000463c:	2785                	addiw	a5,a5,1
    8000463e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004640:	0001e517          	auipc	a0,0x1e
    80004644:	e1050513          	addi	a0,a0,-496 # 80022450 <ftable>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	6cc080e7          	jalr	1740(ra) # 80000d14 <release>
  return f;
}
    80004650:	8526                	mv	a0,s1
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6105                	addi	sp,sp,32
    8000465a:	8082                	ret
    panic("filedup");
    8000465c:	00004517          	auipc	a0,0x4
    80004660:	02450513          	addi	a0,a0,36 # 80008680 <syscalls+0x250>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	ed8080e7          	jalr	-296(ra) # 8000053c <panic>

000000008000466c <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000466c:	7139                	addi	sp,sp,-64
    8000466e:	fc06                	sd	ra,56(sp)
    80004670:	f822                	sd	s0,48(sp)
    80004672:	f426                	sd	s1,40(sp)
    80004674:	f04a                	sd	s2,32(sp)
    80004676:	ec4e                	sd	s3,24(sp)
    80004678:	e852                	sd	s4,16(sp)
    8000467a:	e456                	sd	s5,8(sp)
    8000467c:	0080                	addi	s0,sp,64
    8000467e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004680:	0001e517          	auipc	a0,0x1e
    80004684:	dd050513          	addi	a0,a0,-560 # 80022450 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	5d8080e7          	jalr	1496(ra) # 80000c60 <acquire>
  if(f->ref < 1)
    80004690:	40dc                	lw	a5,4(s1)
    80004692:	06f05163          	blez	a5,800046f4 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004696:	37fd                	addiw	a5,a5,-1
    80004698:	0007871b          	sext.w	a4,a5
    8000469c:	c0dc                	sw	a5,4(s1)
    8000469e:	06e04363          	bgtz	a4,80004704 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046a2:	0004a903          	lw	s2,0(s1)
    800046a6:	0094ca83          	lbu	s5,9(s1)
    800046aa:	0104ba03          	ld	s4,16(s1)
    800046ae:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046b2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046b6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046ba:	0001e517          	auipc	a0,0x1e
    800046be:	d9650513          	addi	a0,a0,-618 # 80022450 <ftable>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	652080e7          	jalr	1618(ra) # 80000d14 <release>

  if(ff.type == FD_PIPE){
    800046ca:	4785                	li	a5,1
    800046cc:	04f90d63          	beq	s2,a5,80004726 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046d0:	3979                	addiw	s2,s2,-2
    800046d2:	4785                	li	a5,1
    800046d4:	0527e063          	bltu	a5,s2,80004714 <fileclose+0xa8>
    begin_op();
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	ac2080e7          	jalr	-1342(ra) # 8000419a <begin_op>
    iput(ff.ip);
    800046e0:	854e                	mv	a0,s3
    800046e2:	fffff097          	auipc	ra,0xfffff
    800046e6:	2b6080e7          	jalr	694(ra) # 80003998 <iput>
    end_op();
    800046ea:	00000097          	auipc	ra,0x0
    800046ee:	b30080e7          	jalr	-1232(ra) # 8000421a <end_op>
    800046f2:	a00d                	j	80004714 <fileclose+0xa8>
    panic("fileclose");
    800046f4:	00004517          	auipc	a0,0x4
    800046f8:	f9450513          	addi	a0,a0,-108 # 80008688 <syscalls+0x258>
    800046fc:	ffffc097          	auipc	ra,0xffffc
    80004700:	e40080e7          	jalr	-448(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004704:	0001e517          	auipc	a0,0x1e
    80004708:	d4c50513          	addi	a0,a0,-692 # 80022450 <ftable>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	608080e7          	jalr	1544(ra) # 80000d14 <release>
  }
}
    80004714:	70e2                	ld	ra,56(sp)
    80004716:	7442                	ld	s0,48(sp)
    80004718:	74a2                	ld	s1,40(sp)
    8000471a:	7902                	ld	s2,32(sp)
    8000471c:	69e2                	ld	s3,24(sp)
    8000471e:	6a42                	ld	s4,16(sp)
    80004720:	6aa2                	ld	s5,8(sp)
    80004722:	6121                	addi	sp,sp,64
    80004724:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004726:	85d6                	mv	a1,s5
    80004728:	8552                	mv	a0,s4
    8000472a:	00000097          	auipc	ra,0x0
    8000472e:	372080e7          	jalr	882(ra) # 80004a9c <pipeclose>
    80004732:	b7cd                	j	80004714 <fileclose+0xa8>

0000000080004734 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004734:	715d                	addi	sp,sp,-80
    80004736:	e486                	sd	ra,72(sp)
    80004738:	e0a2                	sd	s0,64(sp)
    8000473a:	fc26                	sd	s1,56(sp)
    8000473c:	f84a                	sd	s2,48(sp)
    8000473e:	f44e                	sd	s3,40(sp)
    80004740:	0880                	addi	s0,sp,80
    80004742:	84aa                	mv	s1,a0
    80004744:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004746:	ffffd097          	auipc	ra,0xffffd
    8000474a:	2e8080e7          	jalr	744(ra) # 80001a2e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000474e:	409c                	lw	a5,0(s1)
    80004750:	37f9                	addiw	a5,a5,-2
    80004752:	4705                	li	a4,1
    80004754:	04f76763          	bltu	a4,a5,800047a2 <filestat+0x6e>
    80004758:	892a                	mv	s2,a0
    ilock(f->ip);
    8000475a:	6c88                	ld	a0,24(s1)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	082080e7          	jalr	130(ra) # 800037de <ilock>
    stati(f->ip, &st);
    80004764:	fb840593          	addi	a1,s0,-72
    80004768:	6c88                	ld	a0,24(s1)
    8000476a:	fffff097          	auipc	ra,0xfffff
    8000476e:	2fe080e7          	jalr	766(ra) # 80003a68 <stati>
    iunlock(f->ip);
    80004772:	6c88                	ld	a0,24(s1)
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	12c080e7          	jalr	300(ra) # 800038a0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000477c:	46e1                	li	a3,24
    8000477e:	fb840613          	addi	a2,s0,-72
    80004782:	85ce                	mv	a1,s3
    80004784:	05093503          	ld	a0,80(s2)
    80004788:	ffffd097          	auipc	ra,0xffffd
    8000478c:	f9a080e7          	jalr	-102(ra) # 80001722 <copyout>
    80004790:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004794:	60a6                	ld	ra,72(sp)
    80004796:	6406                	ld	s0,64(sp)
    80004798:	74e2                	ld	s1,56(sp)
    8000479a:	7942                	ld	s2,48(sp)
    8000479c:	79a2                	ld	s3,40(sp)
    8000479e:	6161                	addi	sp,sp,80
    800047a0:	8082                	ret
  return -1;
    800047a2:	557d                	li	a0,-1
    800047a4:	bfc5                	j	80004794 <filestat+0x60>

00000000800047a6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047a6:	7179                	addi	sp,sp,-48
    800047a8:	f406                	sd	ra,40(sp)
    800047aa:	f022                	sd	s0,32(sp)
    800047ac:	ec26                	sd	s1,24(sp)
    800047ae:	e84a                	sd	s2,16(sp)
    800047b0:	e44e                	sd	s3,8(sp)
    800047b2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047b4:	00854783          	lbu	a5,8(a0)
    800047b8:	c3d5                	beqz	a5,8000485c <fileread+0xb6>
    800047ba:	84aa                	mv	s1,a0
    800047bc:	89ae                	mv	s3,a1
    800047be:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047c0:	411c                	lw	a5,0(a0)
    800047c2:	4705                	li	a4,1
    800047c4:	04e78963          	beq	a5,a4,80004816 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c8:	470d                	li	a4,3
    800047ca:	04e78d63          	beq	a5,a4,80004824 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ce:	4709                	li	a4,2
    800047d0:	06e79e63          	bne	a5,a4,8000484c <fileread+0xa6>
    ilock(f->ip);
    800047d4:	6d08                	ld	a0,24(a0)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	008080e7          	jalr	8(ra) # 800037de <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047de:	874a                	mv	a4,s2
    800047e0:	5094                	lw	a3,32(s1)
    800047e2:	864e                	mv	a2,s3
    800047e4:	4585                	li	a1,1
    800047e6:	6c88                	ld	a0,24(s1)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	2aa080e7          	jalr	682(ra) # 80003a92 <readi>
    800047f0:	892a                	mv	s2,a0
    800047f2:	00a05563          	blez	a0,800047fc <fileread+0x56>
      f->off += r;
    800047f6:	509c                	lw	a5,32(s1)
    800047f8:	9fa9                	addw	a5,a5,a0
    800047fa:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047fc:	6c88                	ld	a0,24(s1)
    800047fe:	fffff097          	auipc	ra,0xfffff
    80004802:	0a2080e7          	jalr	162(ra) # 800038a0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004806:	854a                	mv	a0,s2
    80004808:	70a2                	ld	ra,40(sp)
    8000480a:	7402                	ld	s0,32(sp)
    8000480c:	64e2                	ld	s1,24(sp)
    8000480e:	6942                	ld	s2,16(sp)
    80004810:	69a2                	ld	s3,8(sp)
    80004812:	6145                	addi	sp,sp,48
    80004814:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004816:	6908                	ld	a0,16(a0)
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	418080e7          	jalr	1048(ra) # 80004c30 <piperead>
    80004820:	892a                	mv	s2,a0
    80004822:	b7d5                	j	80004806 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004824:	02451783          	lh	a5,36(a0)
    80004828:	03079693          	slli	a3,a5,0x30
    8000482c:	92c1                	srli	a3,a3,0x30
    8000482e:	4725                	li	a4,9
    80004830:	02d76863          	bltu	a4,a3,80004860 <fileread+0xba>
    80004834:	0792                	slli	a5,a5,0x4
    80004836:	0001e717          	auipc	a4,0x1e
    8000483a:	b7a70713          	addi	a4,a4,-1158 # 800223b0 <devsw>
    8000483e:	97ba                	add	a5,a5,a4
    80004840:	639c                	ld	a5,0(a5)
    80004842:	c38d                	beqz	a5,80004864 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004844:	4505                	li	a0,1
    80004846:	9782                	jalr	a5
    80004848:	892a                	mv	s2,a0
    8000484a:	bf75                	j	80004806 <fileread+0x60>
    panic("fileread");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	e4c50513          	addi	a0,a0,-436 # 80008698 <syscalls+0x268>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	ce8080e7          	jalr	-792(ra) # 8000053c <panic>
    return -1;
    8000485c:	597d                	li	s2,-1
    8000485e:	b765                	j	80004806 <fileread+0x60>
      return -1;
    80004860:	597d                	li	s2,-1
    80004862:	b755                	j	80004806 <fileread+0x60>
    80004864:	597d                	li	s2,-1
    80004866:	b745                	j	80004806 <fileread+0x60>

0000000080004868 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004868:	00954783          	lbu	a5,9(a0)
    8000486c:	14078563          	beqz	a5,800049b6 <filewrite+0x14e>
{
    80004870:	715d                	addi	sp,sp,-80
    80004872:	e486                	sd	ra,72(sp)
    80004874:	e0a2                	sd	s0,64(sp)
    80004876:	fc26                	sd	s1,56(sp)
    80004878:	f84a                	sd	s2,48(sp)
    8000487a:	f44e                	sd	s3,40(sp)
    8000487c:	f052                	sd	s4,32(sp)
    8000487e:	ec56                	sd	s5,24(sp)
    80004880:	e85a                	sd	s6,16(sp)
    80004882:	e45e                	sd	s7,8(sp)
    80004884:	e062                	sd	s8,0(sp)
    80004886:	0880                	addi	s0,sp,80
    80004888:	892a                	mv	s2,a0
    8000488a:	8aae                	mv	s5,a1
    8000488c:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000488e:	411c                	lw	a5,0(a0)
    80004890:	4705                	li	a4,1
    80004892:	02e78263          	beq	a5,a4,800048b6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004896:	470d                	li	a4,3
    80004898:	02e78563          	beq	a5,a4,800048c2 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000489c:	4709                	li	a4,2
    8000489e:	10e79463          	bne	a5,a4,800049a6 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048a2:	0ec05e63          	blez	a2,8000499e <filewrite+0x136>
    int i = 0;
    800048a6:	4981                	li	s3,0
    800048a8:	6b05                	lui	s6,0x1
    800048aa:	c00b0b13          	addi	s6,s6,-1024 # c00 <spin-0x7ffff41a>
    800048ae:	6b85                	lui	s7,0x1
    800048b0:	c00b8b9b          	addiw	s7,s7,-1024
    800048b4:	a851                	j	80004948 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048b6:	6908                	ld	a0,16(a0)
    800048b8:	00000097          	auipc	ra,0x0
    800048bc:	254080e7          	jalr	596(ra) # 80004b0c <pipewrite>
    800048c0:	a85d                	j	80004976 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048c2:	02451783          	lh	a5,36(a0)
    800048c6:	03079693          	slli	a3,a5,0x30
    800048ca:	92c1                	srli	a3,a3,0x30
    800048cc:	4725                	li	a4,9
    800048ce:	0ed76663          	bltu	a4,a3,800049ba <filewrite+0x152>
    800048d2:	0792                	slli	a5,a5,0x4
    800048d4:	0001e717          	auipc	a4,0x1e
    800048d8:	adc70713          	addi	a4,a4,-1316 # 800223b0 <devsw>
    800048dc:	97ba                	add	a5,a5,a4
    800048de:	679c                	ld	a5,8(a5)
    800048e0:	cff9                	beqz	a5,800049be <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048e2:	4505                	li	a0,1
    800048e4:	9782                	jalr	a5
    800048e6:	a841                	j	80004976 <filewrite+0x10e>
    800048e8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	8ae080e7          	jalr	-1874(ra) # 8000419a <begin_op>
      ilock(f->ip);
    800048f4:	01893503          	ld	a0,24(s2)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	ee6080e7          	jalr	-282(ra) # 800037de <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004900:	8762                	mv	a4,s8
    80004902:	02092683          	lw	a3,32(s2)
    80004906:	01598633          	add	a2,s3,s5
    8000490a:	4585                	li	a1,1
    8000490c:	01893503          	ld	a0,24(s2)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	278080e7          	jalr	632(ra) # 80003b88 <writei>
    80004918:	84aa                	mv	s1,a0
    8000491a:	02a05f63          	blez	a0,80004958 <filewrite+0xf0>
        f->off += r;
    8000491e:	02092783          	lw	a5,32(s2)
    80004922:	9fa9                	addw	a5,a5,a0
    80004924:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004928:	01893503          	ld	a0,24(s2)
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	f74080e7          	jalr	-140(ra) # 800038a0 <iunlock>
      end_op();
    80004934:	00000097          	auipc	ra,0x0
    80004938:	8e6080e7          	jalr	-1818(ra) # 8000421a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000493c:	049c1963          	bne	s8,s1,8000498e <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004940:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004944:	0349d663          	bge	s3,s4,80004970 <filewrite+0x108>
      int n1 = n - i;
    80004948:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000494c:	84be                	mv	s1,a5
    8000494e:	2781                	sext.w	a5,a5
    80004950:	f8fb5ce3          	bge	s6,a5,800048e8 <filewrite+0x80>
    80004954:	84de                	mv	s1,s7
    80004956:	bf49                	j	800048e8 <filewrite+0x80>
      iunlock(f->ip);
    80004958:	01893503          	ld	a0,24(s2)
    8000495c:	fffff097          	auipc	ra,0xfffff
    80004960:	f44080e7          	jalr	-188(ra) # 800038a0 <iunlock>
      end_op();
    80004964:	00000097          	auipc	ra,0x0
    80004968:	8b6080e7          	jalr	-1866(ra) # 8000421a <end_op>
      if(r < 0)
    8000496c:	fc04d8e3          	bgez	s1,8000493c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004970:	8552                	mv	a0,s4
    80004972:	033a1863          	bne	s4,s3,800049a2 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004976:	60a6                	ld	ra,72(sp)
    80004978:	6406                	ld	s0,64(sp)
    8000497a:	74e2                	ld	s1,56(sp)
    8000497c:	7942                	ld	s2,48(sp)
    8000497e:	79a2                	ld	s3,40(sp)
    80004980:	7a02                	ld	s4,32(sp)
    80004982:	6ae2                	ld	s5,24(sp)
    80004984:	6b42                	ld	s6,16(sp)
    80004986:	6ba2                	ld	s7,8(sp)
    80004988:	6c02                	ld	s8,0(sp)
    8000498a:	6161                	addi	sp,sp,80
    8000498c:	8082                	ret
        panic("short filewrite");
    8000498e:	00004517          	auipc	a0,0x4
    80004992:	d1a50513          	addi	a0,a0,-742 # 800086a8 <syscalls+0x278>
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	ba6080e7          	jalr	-1114(ra) # 8000053c <panic>
    int i = 0;
    8000499e:	4981                	li	s3,0
    800049a0:	bfc1                	j	80004970 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049a2:	557d                	li	a0,-1
    800049a4:	bfc9                	j	80004976 <filewrite+0x10e>
    panic("filewrite");
    800049a6:	00004517          	auipc	a0,0x4
    800049aa:	d1250513          	addi	a0,a0,-750 # 800086b8 <syscalls+0x288>
    800049ae:	ffffc097          	auipc	ra,0xffffc
    800049b2:	b8e080e7          	jalr	-1138(ra) # 8000053c <panic>
    return -1;
    800049b6:	557d                	li	a0,-1
}
    800049b8:	8082                	ret
      return -1;
    800049ba:	557d                	li	a0,-1
    800049bc:	bf6d                	j	80004976 <filewrite+0x10e>
    800049be:	557d                	li	a0,-1
    800049c0:	bf5d                	j	80004976 <filewrite+0x10e>

00000000800049c2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049c2:	7179                	addi	sp,sp,-48
    800049c4:	f406                	sd	ra,40(sp)
    800049c6:	f022                	sd	s0,32(sp)
    800049c8:	ec26                	sd	s1,24(sp)
    800049ca:	e84a                	sd	s2,16(sp)
    800049cc:	e44e                	sd	s3,8(sp)
    800049ce:	e052                	sd	s4,0(sp)
    800049d0:	1800                	addi	s0,sp,48
    800049d2:	84aa                	mv	s1,a0
    800049d4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049d6:	0005b023          	sd	zero,0(a1)
    800049da:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	bd2080e7          	jalr	-1070(ra) # 800045b0 <filealloc>
    800049e6:	e088                	sd	a0,0(s1)
    800049e8:	c551                	beqz	a0,80004a74 <pipealloc+0xb2>
    800049ea:	00000097          	auipc	ra,0x0
    800049ee:	bc6080e7          	jalr	-1082(ra) # 800045b0 <filealloc>
    800049f2:	00aa3023          	sd	a0,0(s4)
    800049f6:	c92d                	beqz	a0,80004a68 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	178080e7          	jalr	376(ra) # 80000b70 <kalloc>
    80004a00:	892a                	mv	s2,a0
    80004a02:	c125                	beqz	a0,80004a62 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a04:	4985                	li	s3,1
    80004a06:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a0a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a0e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a12:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a16:	00004597          	auipc	a1,0x4
    80004a1a:	cb258593          	addi	a1,a1,-846 # 800086c8 <syscalls+0x298>
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1b2080e7          	jalr	434(ra) # 80000bd0 <initlock>
  (*f0)->type = FD_PIPE;
    80004a26:	609c                	ld	a5,0(s1)
    80004a28:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a2c:	609c                	ld	a5,0(s1)
    80004a2e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a32:	609c                	ld	a5,0(s1)
    80004a34:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a38:	609c                	ld	a5,0(s1)
    80004a3a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a3e:	000a3783          	ld	a5,0(s4)
    80004a42:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a46:	000a3783          	ld	a5,0(s4)
    80004a4a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a4e:	000a3783          	ld	a5,0(s4)
    80004a52:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a56:	000a3783          	ld	a5,0(s4)
    80004a5a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a5e:	4501                	li	a0,0
    80004a60:	a025                	j	80004a88 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a62:	6088                	ld	a0,0(s1)
    80004a64:	e501                	bnez	a0,80004a6c <pipealloc+0xaa>
    80004a66:	a039                	j	80004a74 <pipealloc+0xb2>
    80004a68:	6088                	ld	a0,0(s1)
    80004a6a:	c51d                	beqz	a0,80004a98 <pipealloc+0xd6>
    fileclose(*f0);
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	c00080e7          	jalr	-1024(ra) # 8000466c <fileclose>
  if(*f1)
    80004a74:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a78:	557d                	li	a0,-1
  if(*f1)
    80004a7a:	c799                	beqz	a5,80004a88 <pipealloc+0xc6>
    fileclose(*f1);
    80004a7c:	853e                	mv	a0,a5
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	bee080e7          	jalr	-1042(ra) # 8000466c <fileclose>
  return -1;
    80004a86:	557d                	li	a0,-1
}
    80004a88:	70a2                	ld	ra,40(sp)
    80004a8a:	7402                	ld	s0,32(sp)
    80004a8c:	64e2                	ld	s1,24(sp)
    80004a8e:	6942                	ld	s2,16(sp)
    80004a90:	69a2                	ld	s3,8(sp)
    80004a92:	6a02                	ld	s4,0(sp)
    80004a94:	6145                	addi	sp,sp,48
    80004a96:	8082                	ret
  return -1;
    80004a98:	557d                	li	a0,-1
    80004a9a:	b7fd                	j	80004a88 <pipealloc+0xc6>

0000000080004a9c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a9c:	1101                	addi	sp,sp,-32
    80004a9e:	ec06                	sd	ra,24(sp)
    80004aa0:	e822                	sd	s0,16(sp)
    80004aa2:	e426                	sd	s1,8(sp)
    80004aa4:	e04a                	sd	s2,0(sp)
    80004aa6:	1000                	addi	s0,sp,32
    80004aa8:	84aa                	mv	s1,a0
    80004aaa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004aac:	ffffc097          	auipc	ra,0xffffc
    80004ab0:	1b4080e7          	jalr	436(ra) # 80000c60 <acquire>
  if(writable){
    80004ab4:	02090d63          	beqz	s2,80004aee <pipeclose+0x52>
    pi->writeopen = 0;
    80004ab8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004abc:	21848513          	addi	a0,s1,536
    80004ac0:	ffffe097          	auipc	ra,0xffffe
    80004ac4:	9ba080e7          	jalr	-1606(ra) # 8000247a <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ac8:	2204b783          	ld	a5,544(s1)
    80004acc:	eb95                	bnez	a5,80004b00 <pipeclose+0x64>
    release(&pi->lock);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffc097          	auipc	ra,0xffffc
    80004ad4:	244080e7          	jalr	580(ra) # 80000d14 <release>
    kfree((char*)pi);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	f9a080e7          	jalr	-102(ra) # 80000a74 <kfree>
  } else
    release(&pi->lock);
}
    80004ae2:	60e2                	ld	ra,24(sp)
    80004ae4:	6442                	ld	s0,16(sp)
    80004ae6:	64a2                	ld	s1,8(sp)
    80004ae8:	6902                	ld	s2,0(sp)
    80004aea:	6105                	addi	sp,sp,32
    80004aec:	8082                	ret
    pi->readopen = 0;
    80004aee:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004af2:	21c48513          	addi	a0,s1,540
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	984080e7          	jalr	-1660(ra) # 8000247a <wakeup>
    80004afe:	b7e9                	j	80004ac8 <pipeclose+0x2c>
    release(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	212080e7          	jalr	530(ra) # 80000d14 <release>
}
    80004b0a:	bfe1                	j	80004ae2 <pipeclose+0x46>

0000000080004b0c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b0c:	7119                	addi	sp,sp,-128
    80004b0e:	fc86                	sd	ra,120(sp)
    80004b10:	f8a2                	sd	s0,112(sp)
    80004b12:	f4a6                	sd	s1,104(sp)
    80004b14:	f0ca                	sd	s2,96(sp)
    80004b16:	ecce                	sd	s3,88(sp)
    80004b18:	e8d2                	sd	s4,80(sp)
    80004b1a:	e4d6                	sd	s5,72(sp)
    80004b1c:	e0da                	sd	s6,64(sp)
    80004b1e:	fc5e                	sd	s7,56(sp)
    80004b20:	f862                	sd	s8,48(sp)
    80004b22:	f466                	sd	s9,40(sp)
    80004b24:	f06a                	sd	s10,32(sp)
    80004b26:	ec6e                	sd	s11,24(sp)
    80004b28:	0100                	addi	s0,sp,128
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	8cae                	mv	s9,a1
    80004b2e:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	efe080e7          	jalr	-258(ra) # 80001a2e <myproc>
    80004b38:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b3a:	8526                	mv	a0,s1
    80004b3c:	ffffc097          	auipc	ra,0xffffc
    80004b40:	124080e7          	jalr	292(ra) # 80000c60 <acquire>
  for(i = 0; i < n; i++){
    80004b44:	0d605963          	blez	s6,80004c16 <pipewrite+0x10a>
    80004b48:	89a6                	mv	s3,s1
    80004b4a:	3b7d                	addiw	s6,s6,-1
    80004b4c:	1b02                	slli	s6,s6,0x20
    80004b4e:	020b5b13          	srli	s6,s6,0x20
    80004b52:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b54:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b58:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b5c:	5dfd                	li	s11,-1
    80004b5e:	000b8d1b          	sext.w	s10,s7
    80004b62:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b64:	2184a783          	lw	a5,536(s1)
    80004b68:	21c4a703          	lw	a4,540(s1)
    80004b6c:	2007879b          	addiw	a5,a5,512
    80004b70:	02f71b63          	bne	a4,a5,80004ba6 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b74:	2204a783          	lw	a5,544(s1)
    80004b78:	cbad                	beqz	a5,80004bea <pipewrite+0xde>
    80004b7a:	03092783          	lw	a5,48(s2)
    80004b7e:	e7b5                	bnez	a5,80004bea <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b80:	8556                	mv	a0,s5
    80004b82:	ffffe097          	auipc	ra,0xffffe
    80004b86:	8f8080e7          	jalr	-1800(ra) # 8000247a <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b8a:	85ce                	mv	a1,s3
    80004b8c:	8552                	mv	a0,s4
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	766080e7          	jalr	1894(ra) # 800022f4 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b96:	2184a783          	lw	a5,536(s1)
    80004b9a:	21c4a703          	lw	a4,540(s1)
    80004b9e:	2007879b          	addiw	a5,a5,512
    80004ba2:	fcf709e3          	beq	a4,a5,80004b74 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba6:	4685                	li	a3,1
    80004ba8:	019b8633          	add	a2,s7,s9
    80004bac:	f8f40593          	addi	a1,s0,-113
    80004bb0:	05093503          	ld	a0,80(s2)
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	bfa080e7          	jalr	-1030(ra) # 800017ae <copyin>
    80004bbc:	05b50e63          	beq	a0,s11,80004c18 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc0:	21c4a783          	lw	a5,540(s1)
    80004bc4:	0017871b          	addiw	a4,a5,1
    80004bc8:	20e4ae23          	sw	a4,540(s1)
    80004bcc:	1ff7f793          	andi	a5,a5,511
    80004bd0:	97a6                	add	a5,a5,s1
    80004bd2:	f8f44703          	lbu	a4,-113(s0)
    80004bd6:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bda:	001d0c1b          	addiw	s8,s10,1
    80004bde:	001b8793          	addi	a5,s7,1 # 1001 <spin-0x7ffff019>
    80004be2:	036b8b63          	beq	s7,s6,80004c18 <pipewrite+0x10c>
    80004be6:	8bbe                	mv	s7,a5
    80004be8:	bf9d                	j	80004b5e <pipewrite+0x52>
        release(&pi->lock);
    80004bea:	8526                	mv	a0,s1
    80004bec:	ffffc097          	auipc	ra,0xffffc
    80004bf0:	128080e7          	jalr	296(ra) # 80000d14 <release>
        return -1;
    80004bf4:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004bf6:	8562                	mv	a0,s8
    80004bf8:	70e6                	ld	ra,120(sp)
    80004bfa:	7446                	ld	s0,112(sp)
    80004bfc:	74a6                	ld	s1,104(sp)
    80004bfe:	7906                	ld	s2,96(sp)
    80004c00:	69e6                	ld	s3,88(sp)
    80004c02:	6a46                	ld	s4,80(sp)
    80004c04:	6aa6                	ld	s5,72(sp)
    80004c06:	6b06                	ld	s6,64(sp)
    80004c08:	7be2                	ld	s7,56(sp)
    80004c0a:	7c42                	ld	s8,48(sp)
    80004c0c:	7ca2                	ld	s9,40(sp)
    80004c0e:	7d02                	ld	s10,32(sp)
    80004c10:	6de2                	ld	s11,24(sp)
    80004c12:	6109                	addi	sp,sp,128
    80004c14:	8082                	ret
  for(i = 0; i < n; i++){
    80004c16:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c18:	21848513          	addi	a0,s1,536
    80004c1c:	ffffe097          	auipc	ra,0xffffe
    80004c20:	85e080e7          	jalr	-1954(ra) # 8000247a <wakeup>
  release(&pi->lock);
    80004c24:	8526                	mv	a0,s1
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	0ee080e7          	jalr	238(ra) # 80000d14 <release>
  return i;
    80004c2e:	b7e1                	j	80004bf6 <pipewrite+0xea>

0000000080004c30 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c30:	715d                	addi	sp,sp,-80
    80004c32:	e486                	sd	ra,72(sp)
    80004c34:	e0a2                	sd	s0,64(sp)
    80004c36:	fc26                	sd	s1,56(sp)
    80004c38:	f84a                	sd	s2,48(sp)
    80004c3a:	f44e                	sd	s3,40(sp)
    80004c3c:	f052                	sd	s4,32(sp)
    80004c3e:	ec56                	sd	s5,24(sp)
    80004c40:	e85a                	sd	s6,16(sp)
    80004c42:	0880                	addi	s0,sp,80
    80004c44:	84aa                	mv	s1,a0
    80004c46:	892e                	mv	s2,a1
    80004c48:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	de4080e7          	jalr	-540(ra) # 80001a2e <myproc>
    80004c52:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c54:	8b26                	mv	s6,s1
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	008080e7          	jalr	8(ra) # 80000c60 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c60:	2184a703          	lw	a4,536(s1)
    80004c64:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c68:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6c:	02f71463          	bne	a4,a5,80004c94 <piperead+0x64>
    80004c70:	2244a783          	lw	a5,548(s1)
    80004c74:	c385                	beqz	a5,80004c94 <piperead+0x64>
    if(pr->killed){
    80004c76:	030a2783          	lw	a5,48(s4)
    80004c7a:	ebc1                	bnez	a5,80004d0a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c7c:	85da                	mv	a1,s6
    80004c7e:	854e                	mv	a0,s3
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	674080e7          	jalr	1652(ra) # 800022f4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c88:	2184a703          	lw	a4,536(s1)
    80004c8c:	21c4a783          	lw	a5,540(s1)
    80004c90:	fef700e3          	beq	a4,a5,80004c70 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c94:	09505263          	blez	s5,80004d18 <piperead+0xe8>
    80004c98:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c9a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c9c:	2184a783          	lw	a5,536(s1)
    80004ca0:	21c4a703          	lw	a4,540(s1)
    80004ca4:	02f70d63          	beq	a4,a5,80004cde <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ca8:	0017871b          	addiw	a4,a5,1
    80004cac:	20e4ac23          	sw	a4,536(s1)
    80004cb0:	1ff7f793          	andi	a5,a5,511
    80004cb4:	97a6                	add	a5,a5,s1
    80004cb6:	0187c783          	lbu	a5,24(a5)
    80004cba:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cbe:	4685                	li	a3,1
    80004cc0:	fbf40613          	addi	a2,s0,-65
    80004cc4:	85ca                	mv	a1,s2
    80004cc6:	050a3503          	ld	a0,80(s4)
    80004cca:	ffffd097          	auipc	ra,0xffffd
    80004cce:	a58080e7          	jalr	-1448(ra) # 80001722 <copyout>
    80004cd2:	01650663          	beq	a0,s6,80004cde <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cd6:	2985                	addiw	s3,s3,1
    80004cd8:	0905                	addi	s2,s2,1
    80004cda:	fd3a91e3          	bne	s5,s3,80004c9c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cde:	21c48513          	addi	a0,s1,540
    80004ce2:	ffffd097          	auipc	ra,0xffffd
    80004ce6:	798080e7          	jalr	1944(ra) # 8000247a <wakeup>
  release(&pi->lock);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	028080e7          	jalr	40(ra) # 80000d14 <release>
  return i;
}
    80004cf4:	854e                	mv	a0,s3
    80004cf6:	60a6                	ld	ra,72(sp)
    80004cf8:	6406                	ld	s0,64(sp)
    80004cfa:	74e2                	ld	s1,56(sp)
    80004cfc:	7942                	ld	s2,48(sp)
    80004cfe:	79a2                	ld	s3,40(sp)
    80004d00:	7a02                	ld	s4,32(sp)
    80004d02:	6ae2                	ld	s5,24(sp)
    80004d04:	6b42                	ld	s6,16(sp)
    80004d06:	6161                	addi	sp,sp,80
    80004d08:	8082                	ret
      release(&pi->lock);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	008080e7          	jalr	8(ra) # 80000d14 <release>
      return -1;
    80004d14:	59fd                	li	s3,-1
    80004d16:	bff9                	j	80004cf4 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d18:	4981                	li	s3,0
    80004d1a:	b7d1                	j	80004cde <piperead+0xae>

0000000080004d1c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d1c:	df010113          	addi	sp,sp,-528
    80004d20:	20113423          	sd	ra,520(sp)
    80004d24:	20813023          	sd	s0,512(sp)
    80004d28:	ffa6                	sd	s1,504(sp)
    80004d2a:	fbca                	sd	s2,496(sp)
    80004d2c:	f7ce                	sd	s3,488(sp)
    80004d2e:	f3d2                	sd	s4,480(sp)
    80004d30:	efd6                	sd	s5,472(sp)
    80004d32:	ebda                	sd	s6,464(sp)
    80004d34:	e7de                	sd	s7,456(sp)
    80004d36:	e3e2                	sd	s8,448(sp)
    80004d38:	ff66                	sd	s9,440(sp)
    80004d3a:	fb6a                	sd	s10,432(sp)
    80004d3c:	f76e                	sd	s11,424(sp)
    80004d3e:	0c00                	addi	s0,sp,528
    80004d40:	84aa                	mv	s1,a0
    80004d42:	dea43c23          	sd	a0,-520(s0)
    80004d46:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d4a:	ffffd097          	auipc	ra,0xffffd
    80004d4e:	ce4080e7          	jalr	-796(ra) # 80001a2e <myproc>
    80004d52:	892a                	mv	s2,a0

  begin_op();
    80004d54:	fffff097          	auipc	ra,0xfffff
    80004d58:	446080e7          	jalr	1094(ra) # 8000419a <begin_op>

  if((ip = namei(path)) == 0){
    80004d5c:	8526                	mv	a0,s1
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	230080e7          	jalr	560(ra) # 80003f8e <namei>
    80004d66:	c92d                	beqz	a0,80004dd8 <exec+0xbc>
    80004d68:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d6a:	fffff097          	auipc	ra,0xfffff
    80004d6e:	a74080e7          	jalr	-1420(ra) # 800037de <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d72:	04000713          	li	a4,64
    80004d76:	4681                	li	a3,0
    80004d78:	e4840613          	addi	a2,s0,-440
    80004d7c:	4581                	li	a1,0
    80004d7e:	8526                	mv	a0,s1
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	d12080e7          	jalr	-750(ra) # 80003a92 <readi>
    80004d88:	04000793          	li	a5,64
    80004d8c:	00f51a63          	bne	a0,a5,80004da0 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d90:	e4842703          	lw	a4,-440(s0)
    80004d94:	464c47b7          	lui	a5,0x464c4
    80004d98:	57f78793          	addi	a5,a5,1407 # 464c457f <spin-0x39b3ba9b>
    80004d9c:	04f70463          	beq	a4,a5,80004de4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004da0:	8526                	mv	a0,s1
    80004da2:	fffff097          	auipc	ra,0xfffff
    80004da6:	c9e080e7          	jalr	-866(ra) # 80003a40 <iunlockput>
    end_op();
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	470080e7          	jalr	1136(ra) # 8000421a <end_op>
  }
  return -1;
    80004db2:	557d                	li	a0,-1
}
    80004db4:	20813083          	ld	ra,520(sp)
    80004db8:	20013403          	ld	s0,512(sp)
    80004dbc:	74fe                	ld	s1,504(sp)
    80004dbe:	795e                	ld	s2,496(sp)
    80004dc0:	79be                	ld	s3,488(sp)
    80004dc2:	7a1e                	ld	s4,480(sp)
    80004dc4:	6afe                	ld	s5,472(sp)
    80004dc6:	6b5e                	ld	s6,464(sp)
    80004dc8:	6bbe                	ld	s7,456(sp)
    80004dca:	6c1e                	ld	s8,448(sp)
    80004dcc:	7cfa                	ld	s9,440(sp)
    80004dce:	7d5a                	ld	s10,432(sp)
    80004dd0:	7dba                	ld	s11,424(sp)
    80004dd2:	21010113          	addi	sp,sp,528
    80004dd6:	8082                	ret
    end_op();
    80004dd8:	fffff097          	auipc	ra,0xfffff
    80004ddc:	442080e7          	jalr	1090(ra) # 8000421a <end_op>
    return -1;
    80004de0:	557d                	li	a0,-1
    80004de2:	bfc9                	j	80004db4 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004de4:	854a                	mv	a0,s2
    80004de6:	ffffd097          	auipc	ra,0xffffd
    80004dea:	d0c080e7          	jalr	-756(ra) # 80001af2 <proc_pagetable>
    80004dee:	8baa                	mv	s7,a0
    80004df0:	d945                	beqz	a0,80004da0 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df2:	e6842983          	lw	s3,-408(s0)
    80004df6:	e8045783          	lhu	a5,-384(s0)
    80004dfa:	c7ad                	beqz	a5,80004e64 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dfc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dfe:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e00:	6c85                	lui	s9,0x1
    80004e02:	fffc8793          	addi	a5,s9,-1 # fff <spin-0x7ffff01b>
    80004e06:	def43823          	sd	a5,-528(s0)
    80004e0a:	a42d                	j	80005034 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e0c:	00004517          	auipc	a0,0x4
    80004e10:	8c450513          	addi	a0,a0,-1852 # 800086d0 <syscalls+0x2a0>
    80004e14:	ffffb097          	auipc	ra,0xffffb
    80004e18:	728080e7          	jalr	1832(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e1c:	8756                	mv	a4,s5
    80004e1e:	012d86bb          	addw	a3,s11,s2
    80004e22:	4581                	li	a1,0
    80004e24:	8526                	mv	a0,s1
    80004e26:	fffff097          	auipc	ra,0xfffff
    80004e2a:	c6c080e7          	jalr	-916(ra) # 80003a92 <readi>
    80004e2e:	2501                	sext.w	a0,a0
    80004e30:	1aaa9963          	bne	s5,a0,80004fe2 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e34:	6785                	lui	a5,0x1
    80004e36:	0127893b          	addw	s2,a5,s2
    80004e3a:	77fd                	lui	a5,0xfffff
    80004e3c:	01478a3b          	addw	s4,a5,s4
    80004e40:	1f897163          	bgeu	s2,s8,80005022 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e44:	02091593          	slli	a1,s2,0x20
    80004e48:	9181                	srli	a1,a1,0x20
    80004e4a:	95ea                	add	a1,a1,s10
    80004e4c:	855e                	mv	a0,s7
    80004e4e:	ffffc097          	auipc	ra,0xffffc
    80004e52:	2a0080e7          	jalr	672(ra) # 800010ee <walkaddr>
    80004e56:	862a                	mv	a2,a0
    if(pa == 0)
    80004e58:	d955                	beqz	a0,80004e0c <exec+0xf0>
      n = PGSIZE;
    80004e5a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e5c:	fd9a70e3          	bgeu	s4,s9,80004e1c <exec+0x100>
      n = sz - i;
    80004e60:	8ad2                	mv	s5,s4
    80004e62:	bf6d                	j	80004e1c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e64:	4901                	li	s2,0
  iunlockput(ip);
    80004e66:	8526                	mv	a0,s1
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	bd8080e7          	jalr	-1064(ra) # 80003a40 <iunlockput>
  end_op();
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	3aa080e7          	jalr	938(ra) # 8000421a <end_op>
  p = myproc();
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	bb6080e7          	jalr	-1098(ra) # 80001a2e <myproc>
    80004e80:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e82:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e86:	6785                	lui	a5,0x1
    80004e88:	17fd                	addi	a5,a5,-1
    80004e8a:	993e                	add	s2,s2,a5
    80004e8c:	757d                	lui	a0,0xfffff
    80004e8e:	00a977b3          	and	a5,s2,a0
    80004e92:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e96:	6609                	lui	a2,0x2
    80004e98:	963e                	add	a2,a2,a5
    80004e9a:	85be                	mv	a1,a5
    80004e9c:	855e                	mv	a0,s7
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	634080e7          	jalr	1588(ra) # 800014d2 <uvmalloc>
    80004ea6:	8b2a                	mv	s6,a0
  ip = 0;
    80004ea8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eaa:	12050c63          	beqz	a0,80004fe2 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eae:	75f9                	lui	a1,0xffffe
    80004eb0:	95aa                	add	a1,a1,a0
    80004eb2:	855e                	mv	a0,s7
    80004eb4:	ffffd097          	auipc	ra,0xffffd
    80004eb8:	83c080e7          	jalr	-1988(ra) # 800016f0 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ebc:	7c7d                	lui	s8,0xfffff
    80004ebe:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ec0:	e0043783          	ld	a5,-512(s0)
    80004ec4:	6388                	ld	a0,0(a5)
    80004ec6:	c535                	beqz	a0,80004f32 <exec+0x216>
    80004ec8:	e8840993          	addi	s3,s0,-376
    80004ecc:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ed0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	012080e7          	jalr	18(ra) # 80000ee4 <strlen>
    80004eda:	2505                	addiw	a0,a0,1
    80004edc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ee0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ee4:	13896363          	bltu	s2,s8,8000500a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ee8:	e0043d83          	ld	s11,-512(s0)
    80004eec:	000dba03          	ld	s4,0(s11)
    80004ef0:	8552                	mv	a0,s4
    80004ef2:	ffffc097          	auipc	ra,0xffffc
    80004ef6:	ff2080e7          	jalr	-14(ra) # 80000ee4 <strlen>
    80004efa:	0015069b          	addiw	a3,a0,1
    80004efe:	8652                	mv	a2,s4
    80004f00:	85ca                	mv	a1,s2
    80004f02:	855e                	mv	a0,s7
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	81e080e7          	jalr	-2018(ra) # 80001722 <copyout>
    80004f0c:	10054363          	bltz	a0,80005012 <exec+0x2f6>
    ustack[argc] = sp;
    80004f10:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f14:	0485                	addi	s1,s1,1
    80004f16:	008d8793          	addi	a5,s11,8
    80004f1a:	e0f43023          	sd	a5,-512(s0)
    80004f1e:	008db503          	ld	a0,8(s11)
    80004f22:	c911                	beqz	a0,80004f36 <exec+0x21a>
    if(argc >= MAXARG)
    80004f24:	09a1                	addi	s3,s3,8
    80004f26:	fb3c96e3          	bne	s9,s3,80004ed2 <exec+0x1b6>
  sz = sz1;
    80004f2a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f2e:	4481                	li	s1,0
    80004f30:	a84d                	j	80004fe2 <exec+0x2c6>
  sp = sz;
    80004f32:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f34:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f36:	00349793          	slli	a5,s1,0x3
    80004f3a:	f9040713          	addi	a4,s0,-112
    80004f3e:	97ba                	add	a5,a5,a4
    80004f40:	ee07bc23          	sd	zero,-264(a5) # ef8 <spin-0x7ffff122>
  sp -= (argc+1) * sizeof(uint64);
    80004f44:	00148693          	addi	a3,s1,1
    80004f48:	068e                	slli	a3,a3,0x3
    80004f4a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f4e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f52:	01897663          	bgeu	s2,s8,80004f5e <exec+0x242>
  sz = sz1;
    80004f56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5a:	4481                	li	s1,0
    80004f5c:	a059                	j	80004fe2 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f5e:	e8840613          	addi	a2,s0,-376
    80004f62:	85ca                	mv	a1,s2
    80004f64:	855e                	mv	a0,s7
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	7bc080e7          	jalr	1980(ra) # 80001722 <copyout>
    80004f6e:	0a054663          	bltz	a0,8000501a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f7a:	df843783          	ld	a5,-520(s0)
    80004f7e:	0007c703          	lbu	a4,0(a5)
    80004f82:	cf11                	beqz	a4,80004f9e <exec+0x282>
    80004f84:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f86:	02f00693          	li	a3,47
    80004f8a:	a029                	j	80004f94 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f8c:	0785                	addi	a5,a5,1
    80004f8e:	fff7c703          	lbu	a4,-1(a5)
    80004f92:	c711                	beqz	a4,80004f9e <exec+0x282>
    if(*s == '/')
    80004f94:	fed71ce3          	bne	a4,a3,80004f8c <exec+0x270>
      last = s+1;
    80004f98:	def43c23          	sd	a5,-520(s0)
    80004f9c:	bfc5                	j	80004f8c <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f9e:	4641                	li	a2,16
    80004fa0:	df843583          	ld	a1,-520(s0)
    80004fa4:	158a8513          	addi	a0,s5,344
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	f0a080e7          	jalr	-246(ra) # 80000eb2 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fb0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fb4:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004fb8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fbc:	058ab783          	ld	a5,88(s5)
    80004fc0:	e6043703          	ld	a4,-416(s0)
    80004fc4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fc6:	058ab783          	ld	a5,88(s5)
    80004fca:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fce:	85ea                	mv	a1,s10
    80004fd0:	ffffd097          	auipc	ra,0xffffd
    80004fd4:	bbe080e7          	jalr	-1090(ra) # 80001b8e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fd8:	0004851b          	sext.w	a0,s1
    80004fdc:	bbe1                	j	80004db4 <exec+0x98>
    80004fde:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fe2:	e0843583          	ld	a1,-504(s0)
    80004fe6:	855e                	mv	a0,s7
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	ba6080e7          	jalr	-1114(ra) # 80001b8e <proc_freepagetable>
  if(ip){
    80004ff0:	da0498e3          	bnez	s1,80004da0 <exec+0x84>
  return -1;
    80004ff4:	557d                	li	a0,-1
    80004ff6:	bb7d                	j	80004db4 <exec+0x98>
    80004ff8:	e1243423          	sd	s2,-504(s0)
    80004ffc:	b7dd                	j	80004fe2 <exec+0x2c6>
    80004ffe:	e1243423          	sd	s2,-504(s0)
    80005002:	b7c5                	j	80004fe2 <exec+0x2c6>
    80005004:	e1243423          	sd	s2,-504(s0)
    80005008:	bfe9                	j	80004fe2 <exec+0x2c6>
  sz = sz1;
    8000500a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500e:	4481                	li	s1,0
    80005010:	bfc9                	j	80004fe2 <exec+0x2c6>
  sz = sz1;
    80005012:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005016:	4481                	li	s1,0
    80005018:	b7e9                	j	80004fe2 <exec+0x2c6>
  sz = sz1;
    8000501a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000501e:	4481                	li	s1,0
    80005020:	b7c9                	j	80004fe2 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005022:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005026:	2b05                	addiw	s6,s6,1
    80005028:	0389899b          	addiw	s3,s3,56
    8000502c:	e8045783          	lhu	a5,-384(s0)
    80005030:	e2fb5be3          	bge	s6,a5,80004e66 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005034:	2981                	sext.w	s3,s3
    80005036:	03800713          	li	a4,56
    8000503a:	86ce                	mv	a3,s3
    8000503c:	e1040613          	addi	a2,s0,-496
    80005040:	4581                	li	a1,0
    80005042:	8526                	mv	a0,s1
    80005044:	fffff097          	auipc	ra,0xfffff
    80005048:	a4e080e7          	jalr	-1458(ra) # 80003a92 <readi>
    8000504c:	03800793          	li	a5,56
    80005050:	f8f517e3          	bne	a0,a5,80004fde <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005054:	e1042783          	lw	a5,-496(s0)
    80005058:	4705                	li	a4,1
    8000505a:	fce796e3          	bne	a5,a4,80005026 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000505e:	e3843603          	ld	a2,-456(s0)
    80005062:	e3043783          	ld	a5,-464(s0)
    80005066:	f8f669e3          	bltu	a2,a5,80004ff8 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000506a:	e2043783          	ld	a5,-480(s0)
    8000506e:	963e                	add	a2,a2,a5
    80005070:	f8f667e3          	bltu	a2,a5,80004ffe <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005074:	85ca                	mv	a1,s2
    80005076:	855e                	mv	a0,s7
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	45a080e7          	jalr	1114(ra) # 800014d2 <uvmalloc>
    80005080:	e0a43423          	sd	a0,-504(s0)
    80005084:	d141                	beqz	a0,80005004 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005086:	e2043d03          	ld	s10,-480(s0)
    8000508a:	df043783          	ld	a5,-528(s0)
    8000508e:	00fd77b3          	and	a5,s10,a5
    80005092:	fba1                	bnez	a5,80004fe2 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005094:	e1842d83          	lw	s11,-488(s0)
    80005098:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000509c:	f80c03e3          	beqz	s8,80005022 <exec+0x306>
    800050a0:	8a62                	mv	s4,s8
    800050a2:	4901                	li	s2,0
    800050a4:	b345                	j	80004e44 <exec+0x128>

00000000800050a6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050a6:	7179                	addi	sp,sp,-48
    800050a8:	f406                	sd	ra,40(sp)
    800050aa:	f022                	sd	s0,32(sp)
    800050ac:	ec26                	sd	s1,24(sp)
    800050ae:	e84a                	sd	s2,16(sp)
    800050b0:	1800                	addi	s0,sp,48
    800050b2:	892e                	mv	s2,a1
    800050b4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050b6:	fdc40593          	addi	a1,s0,-36
    800050ba:	ffffe097          	auipc	ra,0xffffe
    800050be:	b46080e7          	jalr	-1210(ra) # 80002c00 <argint>
    800050c2:	04054063          	bltz	a0,80005102 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050c6:	fdc42703          	lw	a4,-36(s0)
    800050ca:	47bd                	li	a5,15
    800050cc:	02e7ed63          	bltu	a5,a4,80005106 <argfd+0x60>
    800050d0:	ffffd097          	auipc	ra,0xffffd
    800050d4:	95e080e7          	jalr	-1698(ra) # 80001a2e <myproc>
    800050d8:	fdc42703          	lw	a4,-36(s0)
    800050dc:	01a70793          	addi	a5,a4,26
    800050e0:	078e                	slli	a5,a5,0x3
    800050e2:	953e                	add	a0,a0,a5
    800050e4:	611c                	ld	a5,0(a0)
    800050e6:	c395                	beqz	a5,8000510a <argfd+0x64>
    return -1;
  if(pfd)
    800050e8:	00090463          	beqz	s2,800050f0 <argfd+0x4a>
    *pfd = fd;
    800050ec:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050f0:	4501                	li	a0,0
  if(pf)
    800050f2:	c091                	beqz	s1,800050f6 <argfd+0x50>
    *pf = f;
    800050f4:	e09c                	sd	a5,0(s1)
}
    800050f6:	70a2                	ld	ra,40(sp)
    800050f8:	7402                	ld	s0,32(sp)
    800050fa:	64e2                	ld	s1,24(sp)
    800050fc:	6942                	ld	s2,16(sp)
    800050fe:	6145                	addi	sp,sp,48
    80005100:	8082                	ret
    return -1;
    80005102:	557d                	li	a0,-1
    80005104:	bfcd                	j	800050f6 <argfd+0x50>
    return -1;
    80005106:	557d                	li	a0,-1
    80005108:	b7fd                	j	800050f6 <argfd+0x50>
    8000510a:	557d                	li	a0,-1
    8000510c:	b7ed                	j	800050f6 <argfd+0x50>

000000008000510e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000510e:	1101                	addi	sp,sp,-32
    80005110:	ec06                	sd	ra,24(sp)
    80005112:	e822                	sd	s0,16(sp)
    80005114:	e426                	sd	s1,8(sp)
    80005116:	1000                	addi	s0,sp,32
    80005118:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	914080e7          	jalr	-1772(ra) # 80001a2e <myproc>
    80005122:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005124:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    80005128:	4501                	li	a0,0
    8000512a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000512c:	6398                	ld	a4,0(a5)
    8000512e:	cb19                	beqz	a4,80005144 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005130:	2505                	addiw	a0,a0,1
    80005132:	07a1                	addi	a5,a5,8
    80005134:	fed51ce3          	bne	a0,a3,8000512c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005138:	557d                	li	a0,-1
}
    8000513a:	60e2                	ld	ra,24(sp)
    8000513c:	6442                	ld	s0,16(sp)
    8000513e:	64a2                	ld	s1,8(sp)
    80005140:	6105                	addi	sp,sp,32
    80005142:	8082                	ret
      p->ofile[fd] = f;
    80005144:	01a50793          	addi	a5,a0,26
    80005148:	078e                	slli	a5,a5,0x3
    8000514a:	963e                	add	a2,a2,a5
    8000514c:	e204                	sd	s1,0(a2)
      return fd;
    8000514e:	b7f5                	j	8000513a <fdalloc+0x2c>

0000000080005150 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005150:	715d                	addi	sp,sp,-80
    80005152:	e486                	sd	ra,72(sp)
    80005154:	e0a2                	sd	s0,64(sp)
    80005156:	fc26                	sd	s1,56(sp)
    80005158:	f84a                	sd	s2,48(sp)
    8000515a:	f44e                	sd	s3,40(sp)
    8000515c:	f052                	sd	s4,32(sp)
    8000515e:	ec56                	sd	s5,24(sp)
    80005160:	0880                	addi	s0,sp,80
    80005162:	89ae                	mv	s3,a1
    80005164:	8ab2                	mv	s5,a2
    80005166:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005168:	fb040593          	addi	a1,s0,-80
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	e40080e7          	jalr	-448(ra) # 80003fac <nameiparent>
    80005174:	892a                	mv	s2,a0
    80005176:	12050f63          	beqz	a0,800052b4 <create+0x164>
    return 0;

  ilock(dp);
    8000517a:	ffffe097          	auipc	ra,0xffffe
    8000517e:	664080e7          	jalr	1636(ra) # 800037de <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005182:	4601                	li	a2,0
    80005184:	fb040593          	addi	a1,s0,-80
    80005188:	854a                	mv	a0,s2
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	b32080e7          	jalr	-1230(ra) # 80003cbc <dirlookup>
    80005192:	84aa                	mv	s1,a0
    80005194:	c921                	beqz	a0,800051e4 <create+0x94>
    iunlockput(dp);
    80005196:	854a                	mv	a0,s2
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	8a8080e7          	jalr	-1880(ra) # 80003a40 <iunlockput>
    ilock(ip);
    800051a0:	8526                	mv	a0,s1
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	63c080e7          	jalr	1596(ra) # 800037de <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051aa:	2981                	sext.w	s3,s3
    800051ac:	4789                	li	a5,2
    800051ae:	02f99463          	bne	s3,a5,800051d6 <create+0x86>
    800051b2:	0444d783          	lhu	a5,68(s1)
    800051b6:	37f9                	addiw	a5,a5,-2
    800051b8:	17c2                	slli	a5,a5,0x30
    800051ba:	93c1                	srli	a5,a5,0x30
    800051bc:	4705                	li	a4,1
    800051be:	00f76c63          	bltu	a4,a5,800051d6 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051c2:	8526                	mv	a0,s1
    800051c4:	60a6                	ld	ra,72(sp)
    800051c6:	6406                	ld	s0,64(sp)
    800051c8:	74e2                	ld	s1,56(sp)
    800051ca:	7942                	ld	s2,48(sp)
    800051cc:	79a2                	ld	s3,40(sp)
    800051ce:	7a02                	ld	s4,32(sp)
    800051d0:	6ae2                	ld	s5,24(sp)
    800051d2:	6161                	addi	sp,sp,80
    800051d4:	8082                	ret
    iunlockput(ip);
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	868080e7          	jalr	-1944(ra) # 80003a40 <iunlockput>
    return 0;
    800051e0:	4481                	li	s1,0
    800051e2:	b7c5                	j	800051c2 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051e4:	85ce                	mv	a1,s3
    800051e6:	00092503          	lw	a0,0(s2)
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	45c080e7          	jalr	1116(ra) # 80003646 <ialloc>
    800051f2:	84aa                	mv	s1,a0
    800051f4:	c529                	beqz	a0,8000523e <create+0xee>
  ilock(ip);
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	5e8080e7          	jalr	1512(ra) # 800037de <ilock>
  ip->major = major;
    800051fe:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005202:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005206:	4785                	li	a5,1
    80005208:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000520c:	8526                	mv	a0,s1
    8000520e:	ffffe097          	auipc	ra,0xffffe
    80005212:	506080e7          	jalr	1286(ra) # 80003714 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005216:	2981                	sext.w	s3,s3
    80005218:	4785                	li	a5,1
    8000521a:	02f98a63          	beq	s3,a5,8000524e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000521e:	40d0                	lw	a2,4(s1)
    80005220:	fb040593          	addi	a1,s0,-80
    80005224:	854a                	mv	a0,s2
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	ca6080e7          	jalr	-858(ra) # 80003ecc <dirlink>
    8000522e:	06054b63          	bltz	a0,800052a4 <create+0x154>
  iunlockput(dp);
    80005232:	854a                	mv	a0,s2
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	80c080e7          	jalr	-2036(ra) # 80003a40 <iunlockput>
  return ip;
    8000523c:	b759                	j	800051c2 <create+0x72>
    panic("create: ialloc");
    8000523e:	00003517          	auipc	a0,0x3
    80005242:	4b250513          	addi	a0,a0,1202 # 800086f0 <syscalls+0x2c0>
    80005246:	ffffb097          	auipc	ra,0xffffb
    8000524a:	2f6080e7          	jalr	758(ra) # 8000053c <panic>
    dp->nlink++;  // for ".."
    8000524e:	04a95783          	lhu	a5,74(s2)
    80005252:	2785                	addiw	a5,a5,1
    80005254:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005258:	854a                	mv	a0,s2
    8000525a:	ffffe097          	auipc	ra,0xffffe
    8000525e:	4ba080e7          	jalr	1210(ra) # 80003714 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005262:	40d0                	lw	a2,4(s1)
    80005264:	00003597          	auipc	a1,0x3
    80005268:	49c58593          	addi	a1,a1,1180 # 80008700 <syscalls+0x2d0>
    8000526c:	8526                	mv	a0,s1
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	c5e080e7          	jalr	-930(ra) # 80003ecc <dirlink>
    80005276:	00054f63          	bltz	a0,80005294 <create+0x144>
    8000527a:	00492603          	lw	a2,4(s2)
    8000527e:	00003597          	auipc	a1,0x3
    80005282:	48a58593          	addi	a1,a1,1162 # 80008708 <syscalls+0x2d8>
    80005286:	8526                	mv	a0,s1
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	c44080e7          	jalr	-956(ra) # 80003ecc <dirlink>
    80005290:	f80557e3          	bgez	a0,8000521e <create+0xce>
      panic("create dots");
    80005294:	00003517          	auipc	a0,0x3
    80005298:	47c50513          	addi	a0,a0,1148 # 80008710 <syscalls+0x2e0>
    8000529c:	ffffb097          	auipc	ra,0xffffb
    800052a0:	2a0080e7          	jalr	672(ra) # 8000053c <panic>
    panic("create: dirlink");
    800052a4:	00003517          	auipc	a0,0x3
    800052a8:	47c50513          	addi	a0,a0,1148 # 80008720 <syscalls+0x2f0>
    800052ac:	ffffb097          	auipc	ra,0xffffb
    800052b0:	290080e7          	jalr	656(ra) # 8000053c <panic>
    return 0;
    800052b4:	84aa                	mv	s1,a0
    800052b6:	b731                	j	800051c2 <create+0x72>

00000000800052b8 <sys_dup>:
{
    800052b8:	7179                	addi	sp,sp,-48
    800052ba:	f406                	sd	ra,40(sp)
    800052bc:	f022                	sd	s0,32(sp)
    800052be:	ec26                	sd	s1,24(sp)
    800052c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052c2:	fd840613          	addi	a2,s0,-40
    800052c6:	4581                	li	a1,0
    800052c8:	4501                	li	a0,0
    800052ca:	00000097          	auipc	ra,0x0
    800052ce:	ddc080e7          	jalr	-548(ra) # 800050a6 <argfd>
    return -1;
    800052d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052d4:	02054363          	bltz	a0,800052fa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052d8:	fd843503          	ld	a0,-40(s0)
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	e32080e7          	jalr	-462(ra) # 8000510e <fdalloc>
    800052e4:	84aa                	mv	s1,a0
    return -1;
    800052e6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052e8:	00054963          	bltz	a0,800052fa <sys_dup+0x42>
  filedup(f);
    800052ec:	fd843503          	ld	a0,-40(s0)
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	32a080e7          	jalr	810(ra) # 8000461a <filedup>
  return fd;
    800052f8:	87a6                	mv	a5,s1
}
    800052fa:	853e                	mv	a0,a5
    800052fc:	70a2                	ld	ra,40(sp)
    800052fe:	7402                	ld	s0,32(sp)
    80005300:	64e2                	ld	s1,24(sp)
    80005302:	6145                	addi	sp,sp,48
    80005304:	8082                	ret

0000000080005306 <sys_read>:
{
    80005306:	7179                	addi	sp,sp,-48
    80005308:	f406                	sd	ra,40(sp)
    8000530a:	f022                	sd	s0,32(sp)
    8000530c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	fe840613          	addi	a2,s0,-24
    80005312:	4581                	li	a1,0
    80005314:	4501                	li	a0,0
    80005316:	00000097          	auipc	ra,0x0
    8000531a:	d90080e7          	jalr	-624(ra) # 800050a6 <argfd>
    return -1;
    8000531e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005320:	04054163          	bltz	a0,80005362 <sys_read+0x5c>
    80005324:	fe440593          	addi	a1,s0,-28
    80005328:	4509                	li	a0,2
    8000532a:	ffffe097          	auipc	ra,0xffffe
    8000532e:	8d6080e7          	jalr	-1834(ra) # 80002c00 <argint>
    return -1;
    80005332:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005334:	02054763          	bltz	a0,80005362 <sys_read+0x5c>
    80005338:	fd840593          	addi	a1,s0,-40
    8000533c:	4505                	li	a0,1
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	8e4080e7          	jalr	-1820(ra) # 80002c22 <argaddr>
    return -1;
    80005346:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005348:	00054d63          	bltz	a0,80005362 <sys_read+0x5c>
  return fileread(f, p, n);
    8000534c:	fe442603          	lw	a2,-28(s0)
    80005350:	fd843583          	ld	a1,-40(s0)
    80005354:	fe843503          	ld	a0,-24(s0)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	44e080e7          	jalr	1102(ra) # 800047a6 <fileread>
    80005360:	87aa                	mv	a5,a0
}
    80005362:	853e                	mv	a0,a5
    80005364:	70a2                	ld	ra,40(sp)
    80005366:	7402                	ld	s0,32(sp)
    80005368:	6145                	addi	sp,sp,48
    8000536a:	8082                	ret

000000008000536c <sys_write>:
{
    8000536c:	7179                	addi	sp,sp,-48
    8000536e:	f406                	sd	ra,40(sp)
    80005370:	f022                	sd	s0,32(sp)
    80005372:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	fe840613          	addi	a2,s0,-24
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	d2a080e7          	jalr	-726(ra) # 800050a6 <argfd>
    return -1;
    80005384:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005386:	04054163          	bltz	a0,800053c8 <sys_write+0x5c>
    8000538a:	fe440593          	addi	a1,s0,-28
    8000538e:	4509                	li	a0,2
    80005390:	ffffe097          	auipc	ra,0xffffe
    80005394:	870080e7          	jalr	-1936(ra) # 80002c00 <argint>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000539a:	02054763          	bltz	a0,800053c8 <sys_write+0x5c>
    8000539e:	fd840593          	addi	a1,s0,-40
    800053a2:	4505                	li	a0,1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	87e080e7          	jalr	-1922(ra) # 80002c22 <argaddr>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ae:	00054d63          	bltz	a0,800053c8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053b2:	fe442603          	lw	a2,-28(s0)
    800053b6:	fd843583          	ld	a1,-40(s0)
    800053ba:	fe843503          	ld	a0,-24(s0)
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	4aa080e7          	jalr	1194(ra) # 80004868 <filewrite>
    800053c6:	87aa                	mv	a5,a0
}
    800053c8:	853e                	mv	a0,a5
    800053ca:	70a2                	ld	ra,40(sp)
    800053cc:	7402                	ld	s0,32(sp)
    800053ce:	6145                	addi	sp,sp,48
    800053d0:	8082                	ret

00000000800053d2 <sys_close>:
{
    800053d2:	1101                	addi	sp,sp,-32
    800053d4:	ec06                	sd	ra,24(sp)
    800053d6:	e822                	sd	s0,16(sp)
    800053d8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053da:	fe040613          	addi	a2,s0,-32
    800053de:	fec40593          	addi	a1,s0,-20
    800053e2:	4501                	li	a0,0
    800053e4:	00000097          	auipc	ra,0x0
    800053e8:	cc2080e7          	jalr	-830(ra) # 800050a6 <argfd>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ee:	02054463          	bltz	a0,80005416 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	63c080e7          	jalr	1596(ra) # 80001a2e <myproc>
    800053fa:	fec42783          	lw	a5,-20(s0)
    800053fe:	07e9                	addi	a5,a5,26
    80005400:	078e                	slli	a5,a5,0x3
    80005402:	97aa                	add	a5,a5,a0
    80005404:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005408:	fe043503          	ld	a0,-32(s0)
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	260080e7          	jalr	608(ra) # 8000466c <fileclose>
  return 0;
    80005414:	4781                	li	a5,0
}
    80005416:	853e                	mv	a0,a5
    80005418:	60e2                	ld	ra,24(sp)
    8000541a:	6442                	ld	s0,16(sp)
    8000541c:	6105                	addi	sp,sp,32
    8000541e:	8082                	ret

0000000080005420 <sys_fstat>:
{
    80005420:	1101                	addi	sp,sp,-32
    80005422:	ec06                	sd	ra,24(sp)
    80005424:	e822                	sd	s0,16(sp)
    80005426:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005428:	fe840613          	addi	a2,s0,-24
    8000542c:	4581                	li	a1,0
    8000542e:	4501                	li	a0,0
    80005430:	00000097          	auipc	ra,0x0
    80005434:	c76080e7          	jalr	-906(ra) # 800050a6 <argfd>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000543a:	02054563          	bltz	a0,80005464 <sys_fstat+0x44>
    8000543e:	fe040593          	addi	a1,s0,-32
    80005442:	4505                	li	a0,1
    80005444:	ffffd097          	auipc	ra,0xffffd
    80005448:	7de080e7          	jalr	2014(ra) # 80002c22 <argaddr>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000544e:	00054b63          	bltz	a0,80005464 <sys_fstat+0x44>
  return filestat(f, st);
    80005452:	fe043583          	ld	a1,-32(s0)
    80005456:	fe843503          	ld	a0,-24(s0)
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	2da080e7          	jalr	730(ra) # 80004734 <filestat>
    80005462:	87aa                	mv	a5,a0
}
    80005464:	853e                	mv	a0,a5
    80005466:	60e2                	ld	ra,24(sp)
    80005468:	6442                	ld	s0,16(sp)
    8000546a:	6105                	addi	sp,sp,32
    8000546c:	8082                	ret

000000008000546e <sys_link>:
{
    8000546e:	7169                	addi	sp,sp,-304
    80005470:	f606                	sd	ra,296(sp)
    80005472:	f222                	sd	s0,288(sp)
    80005474:	ee26                	sd	s1,280(sp)
    80005476:	ea4a                	sd	s2,272(sp)
    80005478:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000547a:	08000613          	li	a2,128
    8000547e:	ed040593          	addi	a1,s0,-304
    80005482:	4501                	li	a0,0
    80005484:	ffffd097          	auipc	ra,0xffffd
    80005488:	7c0080e7          	jalr	1984(ra) # 80002c44 <argstr>
    return -1;
    8000548c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000548e:	10054e63          	bltz	a0,800055aa <sys_link+0x13c>
    80005492:	08000613          	li	a2,128
    80005496:	f5040593          	addi	a1,s0,-176
    8000549a:	4505                	li	a0,1
    8000549c:	ffffd097          	auipc	ra,0xffffd
    800054a0:	7a8080e7          	jalr	1960(ra) # 80002c44 <argstr>
    return -1;
    800054a4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a6:	10054263          	bltz	a0,800055aa <sys_link+0x13c>
  begin_op();
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	cf0080e7          	jalr	-784(ra) # 8000419a <begin_op>
  if((ip = namei(old)) == 0){
    800054b2:	ed040513          	addi	a0,s0,-304
    800054b6:	fffff097          	auipc	ra,0xfffff
    800054ba:	ad8080e7          	jalr	-1320(ra) # 80003f8e <namei>
    800054be:	84aa                	mv	s1,a0
    800054c0:	c551                	beqz	a0,8000554c <sys_link+0xde>
  ilock(ip);
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	31c080e7          	jalr	796(ra) # 800037de <ilock>
  if(ip->type == T_DIR){
    800054ca:	04449703          	lh	a4,68(s1)
    800054ce:	4785                	li	a5,1
    800054d0:	08f70463          	beq	a4,a5,80005558 <sys_link+0xea>
  ip->nlink++;
    800054d4:	04a4d783          	lhu	a5,74(s1)
    800054d8:	2785                	addiw	a5,a5,1
    800054da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	234080e7          	jalr	564(ra) # 80003714 <iupdate>
  iunlock(ip);
    800054e8:	8526                	mv	a0,s1
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	3b6080e7          	jalr	950(ra) # 800038a0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054f2:	fd040593          	addi	a1,s0,-48
    800054f6:	f5040513          	addi	a0,s0,-176
    800054fa:	fffff097          	auipc	ra,0xfffff
    800054fe:	ab2080e7          	jalr	-1358(ra) # 80003fac <nameiparent>
    80005502:	892a                	mv	s2,a0
    80005504:	c935                	beqz	a0,80005578 <sys_link+0x10a>
  ilock(dp);
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	2d8080e7          	jalr	728(ra) # 800037de <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000550e:	00092703          	lw	a4,0(s2)
    80005512:	409c                	lw	a5,0(s1)
    80005514:	04f71d63          	bne	a4,a5,8000556e <sys_link+0x100>
    80005518:	40d0                	lw	a2,4(s1)
    8000551a:	fd040593          	addi	a1,s0,-48
    8000551e:	854a                	mv	a0,s2
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	9ac080e7          	jalr	-1620(ra) # 80003ecc <dirlink>
    80005528:	04054363          	bltz	a0,8000556e <sys_link+0x100>
  iunlockput(dp);
    8000552c:	854a                	mv	a0,s2
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	512080e7          	jalr	1298(ra) # 80003a40 <iunlockput>
  iput(ip);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	460080e7          	jalr	1120(ra) # 80003998 <iput>
  end_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	cda080e7          	jalr	-806(ra) # 8000421a <end_op>
  return 0;
    80005548:	4781                	li	a5,0
    8000554a:	a085                	j	800055aa <sys_link+0x13c>
    end_op();
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	cce080e7          	jalr	-818(ra) # 8000421a <end_op>
    return -1;
    80005554:	57fd                	li	a5,-1
    80005556:	a891                	j	800055aa <sys_link+0x13c>
    iunlockput(ip);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	4e6080e7          	jalr	1254(ra) # 80003a40 <iunlockput>
    end_op();
    80005562:	fffff097          	auipc	ra,0xfffff
    80005566:	cb8080e7          	jalr	-840(ra) # 8000421a <end_op>
    return -1;
    8000556a:	57fd                	li	a5,-1
    8000556c:	a83d                	j	800055aa <sys_link+0x13c>
    iunlockput(dp);
    8000556e:	854a                	mv	a0,s2
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	4d0080e7          	jalr	1232(ra) # 80003a40 <iunlockput>
  ilock(ip);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	264080e7          	jalr	612(ra) # 800037de <ilock>
  ip->nlink--;
    80005582:	04a4d783          	lhu	a5,74(s1)
    80005586:	37fd                	addiw	a5,a5,-1
    80005588:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000558c:	8526                	mv	a0,s1
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	186080e7          	jalr	390(ra) # 80003714 <iupdate>
  iunlockput(ip);
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	4a8080e7          	jalr	1192(ra) # 80003a40 <iunlockput>
  end_op();
    800055a0:	fffff097          	auipc	ra,0xfffff
    800055a4:	c7a080e7          	jalr	-902(ra) # 8000421a <end_op>
  return -1;
    800055a8:	57fd                	li	a5,-1
}
    800055aa:	853e                	mv	a0,a5
    800055ac:	70b2                	ld	ra,296(sp)
    800055ae:	7412                	ld	s0,288(sp)
    800055b0:	64f2                	ld	s1,280(sp)
    800055b2:	6952                	ld	s2,272(sp)
    800055b4:	6155                	addi	sp,sp,304
    800055b6:	8082                	ret

00000000800055b8 <sys_unlink>:
{
    800055b8:	7151                	addi	sp,sp,-240
    800055ba:	f586                	sd	ra,232(sp)
    800055bc:	f1a2                	sd	s0,224(sp)
    800055be:	eda6                	sd	s1,216(sp)
    800055c0:	e9ca                	sd	s2,208(sp)
    800055c2:	e5ce                	sd	s3,200(sp)
    800055c4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055c6:	08000613          	li	a2,128
    800055ca:	f3040593          	addi	a1,s0,-208
    800055ce:	4501                	li	a0,0
    800055d0:	ffffd097          	auipc	ra,0xffffd
    800055d4:	674080e7          	jalr	1652(ra) # 80002c44 <argstr>
    800055d8:	18054163          	bltz	a0,8000575a <sys_unlink+0x1a2>
  begin_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	bbe080e7          	jalr	-1090(ra) # 8000419a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055e4:	fb040593          	addi	a1,s0,-80
    800055e8:	f3040513          	addi	a0,s0,-208
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	9c0080e7          	jalr	-1600(ra) # 80003fac <nameiparent>
    800055f4:	84aa                	mv	s1,a0
    800055f6:	c979                	beqz	a0,800056cc <sys_unlink+0x114>
  ilock(dp);
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	1e6080e7          	jalr	486(ra) # 800037de <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005600:	00003597          	auipc	a1,0x3
    80005604:	10058593          	addi	a1,a1,256 # 80008700 <syscalls+0x2d0>
    80005608:	fb040513          	addi	a0,s0,-80
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	696080e7          	jalr	1686(ra) # 80003ca2 <namecmp>
    80005614:	14050a63          	beqz	a0,80005768 <sys_unlink+0x1b0>
    80005618:	00003597          	auipc	a1,0x3
    8000561c:	0f058593          	addi	a1,a1,240 # 80008708 <syscalls+0x2d8>
    80005620:	fb040513          	addi	a0,s0,-80
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	67e080e7          	jalr	1662(ra) # 80003ca2 <namecmp>
    8000562c:	12050e63          	beqz	a0,80005768 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005630:	f2c40613          	addi	a2,s0,-212
    80005634:	fb040593          	addi	a1,s0,-80
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	682080e7          	jalr	1666(ra) # 80003cbc <dirlookup>
    80005642:	892a                	mv	s2,a0
    80005644:	12050263          	beqz	a0,80005768 <sys_unlink+0x1b0>
  ilock(ip);
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	196080e7          	jalr	406(ra) # 800037de <ilock>
  if(ip->nlink < 1)
    80005650:	04a91783          	lh	a5,74(s2)
    80005654:	08f05263          	blez	a5,800056d8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005658:	04491703          	lh	a4,68(s2)
    8000565c:	4785                	li	a5,1
    8000565e:	08f70563          	beq	a4,a5,800056e8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005662:	4641                	li	a2,16
    80005664:	4581                	li	a1,0
    80005666:	fc040513          	addi	a0,s0,-64
    8000566a:	ffffb097          	auipc	ra,0xffffb
    8000566e:	6f2080e7          	jalr	1778(ra) # 80000d5c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005672:	4741                	li	a4,16
    80005674:	f2c42683          	lw	a3,-212(s0)
    80005678:	fc040613          	addi	a2,s0,-64
    8000567c:	4581                	li	a1,0
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	508080e7          	jalr	1288(ra) # 80003b88 <writei>
    80005688:	47c1                	li	a5,16
    8000568a:	0af51563          	bne	a0,a5,80005734 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000568e:	04491703          	lh	a4,68(s2)
    80005692:	4785                	li	a5,1
    80005694:	0af70863          	beq	a4,a5,80005744 <sys_unlink+0x18c>
  iunlockput(dp);
    80005698:	8526                	mv	a0,s1
    8000569a:	ffffe097          	auipc	ra,0xffffe
    8000569e:	3a6080e7          	jalr	934(ra) # 80003a40 <iunlockput>
  ip->nlink--;
    800056a2:	04a95783          	lhu	a5,74(s2)
    800056a6:	37fd                	addiw	a5,a5,-1
    800056a8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056ac:	854a                	mv	a0,s2
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	066080e7          	jalr	102(ra) # 80003714 <iupdate>
  iunlockput(ip);
    800056b6:	854a                	mv	a0,s2
    800056b8:	ffffe097          	auipc	ra,0xffffe
    800056bc:	388080e7          	jalr	904(ra) # 80003a40 <iunlockput>
  end_op();
    800056c0:	fffff097          	auipc	ra,0xfffff
    800056c4:	b5a080e7          	jalr	-1190(ra) # 8000421a <end_op>
  return 0;
    800056c8:	4501                	li	a0,0
    800056ca:	a84d                	j	8000577c <sys_unlink+0x1c4>
    end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	b4e080e7          	jalr	-1202(ra) # 8000421a <end_op>
    return -1;
    800056d4:	557d                	li	a0,-1
    800056d6:	a05d                	j	8000577c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056d8:	00003517          	auipc	a0,0x3
    800056dc:	05850513          	addi	a0,a0,88 # 80008730 <syscalls+0x300>
    800056e0:	ffffb097          	auipc	ra,0xffffb
    800056e4:	e5c080e7          	jalr	-420(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e8:	04c92703          	lw	a4,76(s2)
    800056ec:	02000793          	li	a5,32
    800056f0:	f6e7f9e3          	bgeu	a5,a4,80005662 <sys_unlink+0xaa>
    800056f4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056f8:	4741                	li	a4,16
    800056fa:	86ce                	mv	a3,s3
    800056fc:	f1840613          	addi	a2,s0,-232
    80005700:	4581                	li	a1,0
    80005702:	854a                	mv	a0,s2
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	38e080e7          	jalr	910(ra) # 80003a92 <readi>
    8000570c:	47c1                	li	a5,16
    8000570e:	00f51b63          	bne	a0,a5,80005724 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005712:	f1845783          	lhu	a5,-232(s0)
    80005716:	e7a1                	bnez	a5,8000575e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005718:	29c1                	addiw	s3,s3,16
    8000571a:	04c92783          	lw	a5,76(s2)
    8000571e:	fcf9ede3          	bltu	s3,a5,800056f8 <sys_unlink+0x140>
    80005722:	b781                	j	80005662 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005724:	00003517          	auipc	a0,0x3
    80005728:	02450513          	addi	a0,a0,36 # 80008748 <syscalls+0x318>
    8000572c:	ffffb097          	auipc	ra,0xffffb
    80005730:	e10080e7          	jalr	-496(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005734:	00003517          	auipc	a0,0x3
    80005738:	02c50513          	addi	a0,a0,44 # 80008760 <syscalls+0x330>
    8000573c:	ffffb097          	auipc	ra,0xffffb
    80005740:	e00080e7          	jalr	-512(ra) # 8000053c <panic>
    dp->nlink--;
    80005744:	04a4d783          	lhu	a5,74(s1)
    80005748:	37fd                	addiw	a5,a5,-1
    8000574a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	fc4080e7          	jalr	-60(ra) # 80003714 <iupdate>
    80005758:	b781                	j	80005698 <sys_unlink+0xe0>
    return -1;
    8000575a:	557d                	li	a0,-1
    8000575c:	a005                	j	8000577c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000575e:	854a                	mv	a0,s2
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	2e0080e7          	jalr	736(ra) # 80003a40 <iunlockput>
  iunlockput(dp);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	2d6080e7          	jalr	726(ra) # 80003a40 <iunlockput>
  end_op();
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	aa8080e7          	jalr	-1368(ra) # 8000421a <end_op>
  return -1;
    8000577a:	557d                	li	a0,-1
}
    8000577c:	70ae                	ld	ra,232(sp)
    8000577e:	740e                	ld	s0,224(sp)
    80005780:	64ee                	ld	s1,216(sp)
    80005782:	694e                	ld	s2,208(sp)
    80005784:	69ae                	ld	s3,200(sp)
    80005786:	616d                	addi	sp,sp,240
    80005788:	8082                	ret

000000008000578a <sys_open>:

uint64
sys_open(void)
{
    8000578a:	7131                	addi	sp,sp,-192
    8000578c:	fd06                	sd	ra,184(sp)
    8000578e:	f922                	sd	s0,176(sp)
    80005790:	f526                	sd	s1,168(sp)
    80005792:	f14a                	sd	s2,160(sp)
    80005794:	ed4e                	sd	s3,152(sp)
    80005796:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005798:	08000613          	li	a2,128
    8000579c:	f5040593          	addi	a1,s0,-176
    800057a0:	4501                	li	a0,0
    800057a2:	ffffd097          	auipc	ra,0xffffd
    800057a6:	4a2080e7          	jalr	1186(ra) # 80002c44 <argstr>
    return -1;
    800057aa:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057ac:	0c054163          	bltz	a0,8000586e <sys_open+0xe4>
    800057b0:	f4c40593          	addi	a1,s0,-180
    800057b4:	4505                	li	a0,1
    800057b6:	ffffd097          	auipc	ra,0xffffd
    800057ba:	44a080e7          	jalr	1098(ra) # 80002c00 <argint>
    800057be:	0a054863          	bltz	a0,8000586e <sys_open+0xe4>

  begin_op();
    800057c2:	fffff097          	auipc	ra,0xfffff
    800057c6:	9d8080e7          	jalr	-1576(ra) # 8000419a <begin_op>

  if(omode & O_CREATE){
    800057ca:	f4c42783          	lw	a5,-180(s0)
    800057ce:	2007f793          	andi	a5,a5,512
    800057d2:	cbdd                	beqz	a5,80005888 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057d4:	4681                	li	a3,0
    800057d6:	4601                	li	a2,0
    800057d8:	4589                	li	a1,2
    800057da:	f5040513          	addi	a0,s0,-176
    800057de:	00000097          	auipc	ra,0x0
    800057e2:	972080e7          	jalr	-1678(ra) # 80005150 <create>
    800057e6:	892a                	mv	s2,a0
    if(ip == 0){
    800057e8:	c959                	beqz	a0,8000587e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	478d                	li	a5,3
    800057f0:	00f71763          	bne	a4,a5,800057fe <sys_open+0x74>
    800057f4:	04695703          	lhu	a4,70(s2)
    800057f8:	47a5                	li	a5,9
    800057fa:	0ce7ec63          	bltu	a5,a4,800058d2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057fe:	fffff097          	auipc	ra,0xfffff
    80005802:	db2080e7          	jalr	-590(ra) # 800045b0 <filealloc>
    80005806:	89aa                	mv	s3,a0
    80005808:	10050263          	beqz	a0,8000590c <sys_open+0x182>
    8000580c:	00000097          	auipc	ra,0x0
    80005810:	902080e7          	jalr	-1790(ra) # 8000510e <fdalloc>
    80005814:	84aa                	mv	s1,a0
    80005816:	0e054663          	bltz	a0,80005902 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000581a:	04491703          	lh	a4,68(s2)
    8000581e:	478d                	li	a5,3
    80005820:	0cf70463          	beq	a4,a5,800058e8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005824:	4789                	li	a5,2
    80005826:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000582a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000582e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005832:	f4c42783          	lw	a5,-180(s0)
    80005836:	0017c713          	xori	a4,a5,1
    8000583a:	8b05                	andi	a4,a4,1
    8000583c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005840:	0037f713          	andi	a4,a5,3
    80005844:	00e03733          	snez	a4,a4
    80005848:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000584c:	4007f793          	andi	a5,a5,1024
    80005850:	c791                	beqz	a5,8000585c <sys_open+0xd2>
    80005852:	04491703          	lh	a4,68(s2)
    80005856:	4789                	li	a5,2
    80005858:	08f70f63          	beq	a4,a5,800058f6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    8000585c:	854a                	mv	a0,s2
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	042080e7          	jalr	66(ra) # 800038a0 <iunlock>
  end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	9b4080e7          	jalr	-1612(ra) # 8000421a <end_op>

  return fd;
}
    8000586e:	8526                	mv	a0,s1
    80005870:	70ea                	ld	ra,184(sp)
    80005872:	744a                	ld	s0,176(sp)
    80005874:	74aa                	ld	s1,168(sp)
    80005876:	790a                	ld	s2,160(sp)
    80005878:	69ea                	ld	s3,152(sp)
    8000587a:	6129                	addi	sp,sp,192
    8000587c:	8082                	ret
      end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	99c080e7          	jalr	-1636(ra) # 8000421a <end_op>
      return -1;
    80005886:	b7e5                	j	8000586e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005888:	f5040513          	addi	a0,s0,-176
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	702080e7          	jalr	1794(ra) # 80003f8e <namei>
    80005894:	892a                	mv	s2,a0
    80005896:	c905                	beqz	a0,800058c6 <sys_open+0x13c>
    ilock(ip);
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	f46080e7          	jalr	-186(ra) # 800037de <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058a0:	04491703          	lh	a4,68(s2)
    800058a4:	4785                	li	a5,1
    800058a6:	f4f712e3          	bne	a4,a5,800057ea <sys_open+0x60>
    800058aa:	f4c42783          	lw	a5,-180(s0)
    800058ae:	dba1                	beqz	a5,800057fe <sys_open+0x74>
      iunlockput(ip);
    800058b0:	854a                	mv	a0,s2
    800058b2:	ffffe097          	auipc	ra,0xffffe
    800058b6:	18e080e7          	jalr	398(ra) # 80003a40 <iunlockput>
      end_op();
    800058ba:	fffff097          	auipc	ra,0xfffff
    800058be:	960080e7          	jalr	-1696(ra) # 8000421a <end_op>
      return -1;
    800058c2:	54fd                	li	s1,-1
    800058c4:	b76d                	j	8000586e <sys_open+0xe4>
      end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	954080e7          	jalr	-1708(ra) # 8000421a <end_op>
      return -1;
    800058ce:	54fd                	li	s1,-1
    800058d0:	bf79                	j	8000586e <sys_open+0xe4>
    iunlockput(ip);
    800058d2:	854a                	mv	a0,s2
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	16c080e7          	jalr	364(ra) # 80003a40 <iunlockput>
    end_op();
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	93e080e7          	jalr	-1730(ra) # 8000421a <end_op>
    return -1;
    800058e4:	54fd                	li	s1,-1
    800058e6:	b761                	j	8000586e <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058e8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058ec:	04691783          	lh	a5,70(s2)
    800058f0:	02f99223          	sh	a5,36(s3)
    800058f4:	bf2d                	j	8000582e <sys_open+0xa4>
    itrunc(ip);
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	ff4080e7          	jalr	-12(ra) # 800038ec <itrunc>
    80005900:	bfb1                	j	8000585c <sys_open+0xd2>
      fileclose(f);
    80005902:	854e                	mv	a0,s3
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	d68080e7          	jalr	-664(ra) # 8000466c <fileclose>
    iunlockput(ip);
    8000590c:	854a                	mv	a0,s2
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	132080e7          	jalr	306(ra) # 80003a40 <iunlockput>
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	904080e7          	jalr	-1788(ra) # 8000421a <end_op>
    return -1;
    8000591e:	54fd                	li	s1,-1
    80005920:	b7b9                	j	8000586e <sys_open+0xe4>

0000000080005922 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005922:	7175                	addi	sp,sp,-144
    80005924:	e506                	sd	ra,136(sp)
    80005926:	e122                	sd	s0,128(sp)
    80005928:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	870080e7          	jalr	-1936(ra) # 8000419a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005932:	08000613          	li	a2,128
    80005936:	f7040593          	addi	a1,s0,-144
    8000593a:	4501                	li	a0,0
    8000593c:	ffffd097          	auipc	ra,0xffffd
    80005940:	308080e7          	jalr	776(ra) # 80002c44 <argstr>
    80005944:	02054963          	bltz	a0,80005976 <sys_mkdir+0x54>
    80005948:	4681                	li	a3,0
    8000594a:	4601                	li	a2,0
    8000594c:	4585                	li	a1,1
    8000594e:	f7040513          	addi	a0,s0,-144
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	7fe080e7          	jalr	2046(ra) # 80005150 <create>
    8000595a:	cd11                	beqz	a0,80005976 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000595c:	ffffe097          	auipc	ra,0xffffe
    80005960:	0e4080e7          	jalr	228(ra) # 80003a40 <iunlockput>
  end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	8b6080e7          	jalr	-1866(ra) # 8000421a <end_op>
  return 0;
    8000596c:	4501                	li	a0,0
}
    8000596e:	60aa                	ld	ra,136(sp)
    80005970:	640a                	ld	s0,128(sp)
    80005972:	6149                	addi	sp,sp,144
    80005974:	8082                	ret
    end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	8a4080e7          	jalr	-1884(ra) # 8000421a <end_op>
    return -1;
    8000597e:	557d                	li	a0,-1
    80005980:	b7fd                	j	8000596e <sys_mkdir+0x4c>

0000000080005982 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005982:	7135                	addi	sp,sp,-160
    80005984:	ed06                	sd	ra,152(sp)
    80005986:	e922                	sd	s0,144(sp)
    80005988:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	810080e7          	jalr	-2032(ra) # 8000419a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005992:	08000613          	li	a2,128
    80005996:	f7040593          	addi	a1,s0,-144
    8000599a:	4501                	li	a0,0
    8000599c:	ffffd097          	auipc	ra,0xffffd
    800059a0:	2a8080e7          	jalr	680(ra) # 80002c44 <argstr>
    800059a4:	04054a63          	bltz	a0,800059f8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059a8:	f6c40593          	addi	a1,s0,-148
    800059ac:	4505                	li	a0,1
    800059ae:	ffffd097          	auipc	ra,0xffffd
    800059b2:	252080e7          	jalr	594(ra) # 80002c00 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059b6:	04054163          	bltz	a0,800059f8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059ba:	f6840593          	addi	a1,s0,-152
    800059be:	4509                	li	a0,2
    800059c0:	ffffd097          	auipc	ra,0xffffd
    800059c4:	240080e7          	jalr	576(ra) # 80002c00 <argint>
     argint(1, &major) < 0 ||
    800059c8:	02054863          	bltz	a0,800059f8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059cc:	f6841683          	lh	a3,-152(s0)
    800059d0:	f6c41603          	lh	a2,-148(s0)
    800059d4:	458d                	li	a1,3
    800059d6:	f7040513          	addi	a0,s0,-144
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	776080e7          	jalr	1910(ra) # 80005150 <create>
     argint(2, &minor) < 0 ||
    800059e2:	c919                	beqz	a0,800059f8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	05c080e7          	jalr	92(ra) # 80003a40 <iunlockput>
  end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	82e080e7          	jalr	-2002(ra) # 8000421a <end_op>
  return 0;
    800059f4:	4501                	li	a0,0
    800059f6:	a031                	j	80005a02 <sys_mknod+0x80>
    end_op();
    800059f8:	fffff097          	auipc	ra,0xfffff
    800059fc:	822080e7          	jalr	-2014(ra) # 8000421a <end_op>
    return -1;
    80005a00:	557d                	li	a0,-1
}
    80005a02:	60ea                	ld	ra,152(sp)
    80005a04:	644a                	ld	s0,144(sp)
    80005a06:	610d                	addi	sp,sp,160
    80005a08:	8082                	ret

0000000080005a0a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a0a:	7135                	addi	sp,sp,-160
    80005a0c:	ed06                	sd	ra,152(sp)
    80005a0e:	e922                	sd	s0,144(sp)
    80005a10:	e526                	sd	s1,136(sp)
    80005a12:	e14a                	sd	s2,128(sp)
    80005a14:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a16:	ffffc097          	auipc	ra,0xffffc
    80005a1a:	018080e7          	jalr	24(ra) # 80001a2e <myproc>
    80005a1e:	892a                	mv	s2,a0
  
  begin_op();
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	77a080e7          	jalr	1914(ra) # 8000419a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a28:	08000613          	li	a2,128
    80005a2c:	f6040593          	addi	a1,s0,-160
    80005a30:	4501                	li	a0,0
    80005a32:	ffffd097          	auipc	ra,0xffffd
    80005a36:	212080e7          	jalr	530(ra) # 80002c44 <argstr>
    80005a3a:	04054b63          	bltz	a0,80005a90 <sys_chdir+0x86>
    80005a3e:	f6040513          	addi	a0,s0,-160
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	54c080e7          	jalr	1356(ra) # 80003f8e <namei>
    80005a4a:	84aa                	mv	s1,a0
    80005a4c:	c131                	beqz	a0,80005a90 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	d90080e7          	jalr	-624(ra) # 800037de <ilock>
  if(ip->type != T_DIR){
    80005a56:	04449703          	lh	a4,68(s1)
    80005a5a:	4785                	li	a5,1
    80005a5c:	04f71063          	bne	a4,a5,80005a9c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	e3e080e7          	jalr	-450(ra) # 800038a0 <iunlock>
  iput(p->cwd);
    80005a6a:	15093503          	ld	a0,336(s2)
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	f2a080e7          	jalr	-214(ra) # 80003998 <iput>
  end_op();
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	7a4080e7          	jalr	1956(ra) # 8000421a <end_op>
  p->cwd = ip;
    80005a7e:	14993823          	sd	s1,336(s2)
  return 0;
    80005a82:	4501                	li	a0,0
}
    80005a84:	60ea                	ld	ra,152(sp)
    80005a86:	644a                	ld	s0,144(sp)
    80005a88:	64aa                	ld	s1,136(sp)
    80005a8a:	690a                	ld	s2,128(sp)
    80005a8c:	610d                	addi	sp,sp,160
    80005a8e:	8082                	ret
    end_op();
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	78a080e7          	jalr	1930(ra) # 8000421a <end_op>
    return -1;
    80005a98:	557d                	li	a0,-1
    80005a9a:	b7ed                	j	80005a84 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a9c:	8526                	mv	a0,s1
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	fa2080e7          	jalr	-94(ra) # 80003a40 <iunlockput>
    end_op();
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	774080e7          	jalr	1908(ra) # 8000421a <end_op>
    return -1;
    80005aae:	557d                	li	a0,-1
    80005ab0:	bfd1                	j	80005a84 <sys_chdir+0x7a>

0000000080005ab2 <sys_exec>:

uint64
sys_exec(void)
{
    80005ab2:	7145                	addi	sp,sp,-464
    80005ab4:	e786                	sd	ra,456(sp)
    80005ab6:	e3a2                	sd	s0,448(sp)
    80005ab8:	ff26                	sd	s1,440(sp)
    80005aba:	fb4a                	sd	s2,432(sp)
    80005abc:	f74e                	sd	s3,424(sp)
    80005abe:	f352                	sd	s4,416(sp)
    80005ac0:	ef56                	sd	s5,408(sp)
    80005ac2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ac4:	08000613          	li	a2,128
    80005ac8:	f4040593          	addi	a1,s0,-192
    80005acc:	4501                	li	a0,0
    80005ace:	ffffd097          	auipc	ra,0xffffd
    80005ad2:	176080e7          	jalr	374(ra) # 80002c44 <argstr>
    return -1;
    80005ad6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ad8:	0c054a63          	bltz	a0,80005bac <sys_exec+0xfa>
    80005adc:	e3840593          	addi	a1,s0,-456
    80005ae0:	4505                	li	a0,1
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	140080e7          	jalr	320(ra) # 80002c22 <argaddr>
    80005aea:	0c054163          	bltz	a0,80005bac <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005aee:	10000613          	li	a2,256
    80005af2:	4581                	li	a1,0
    80005af4:	e4040513          	addi	a0,s0,-448
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	264080e7          	jalr	612(ra) # 80000d5c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b00:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b04:	89a6                	mv	s3,s1
    80005b06:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b08:	02000a13          	li	s4,32
    80005b0c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b10:	00391513          	slli	a0,s2,0x3
    80005b14:	e3040593          	addi	a1,s0,-464
    80005b18:	e3843783          	ld	a5,-456(s0)
    80005b1c:	953e                	add	a0,a0,a5
    80005b1e:	ffffd097          	auipc	ra,0xffffd
    80005b22:	048080e7          	jalr	72(ra) # 80002b66 <fetchaddr>
    80005b26:	02054a63          	bltz	a0,80005b5a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b2a:	e3043783          	ld	a5,-464(s0)
    80005b2e:	c3b9                	beqz	a5,80005b74 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	040080e7          	jalr	64(ra) # 80000b70 <kalloc>
    80005b38:	85aa                	mv	a1,a0
    80005b3a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b3e:	cd11                	beqz	a0,80005b5a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b40:	6605                	lui	a2,0x1
    80005b42:	e3043503          	ld	a0,-464(s0)
    80005b46:	ffffd097          	auipc	ra,0xffffd
    80005b4a:	072080e7          	jalr	114(ra) # 80002bb8 <fetchstr>
    80005b4e:	00054663          	bltz	a0,80005b5a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b52:	0905                	addi	s2,s2,1
    80005b54:	09a1                	addi	s3,s3,8
    80005b56:	fb491be3          	bne	s2,s4,80005b0c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b5a:	10048913          	addi	s2,s1,256
    80005b5e:	6088                	ld	a0,0(s1)
    80005b60:	c529                	beqz	a0,80005baa <sys_exec+0xf8>
    kfree(argv[i]);
    80005b62:	ffffb097          	auipc	ra,0xffffb
    80005b66:	f12080e7          	jalr	-238(ra) # 80000a74 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b6a:	04a1                	addi	s1,s1,8
    80005b6c:	ff2499e3          	bne	s1,s2,80005b5e <sys_exec+0xac>
  return -1;
    80005b70:	597d                	li	s2,-1
    80005b72:	a82d                	j	80005bac <sys_exec+0xfa>
      argv[i] = 0;
    80005b74:	0a8e                	slli	s5,s5,0x3
    80005b76:	fc040793          	addi	a5,s0,-64
    80005b7a:	9abe                	add	s5,s5,a5
    80005b7c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b80:	e4040593          	addi	a1,s0,-448
    80005b84:	f4040513          	addi	a0,s0,-192
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	194080e7          	jalr	404(ra) # 80004d1c <exec>
    80005b90:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b92:	10048993          	addi	s3,s1,256
    80005b96:	6088                	ld	a0,0(s1)
    80005b98:	c911                	beqz	a0,80005bac <sys_exec+0xfa>
    kfree(argv[i]);
    80005b9a:	ffffb097          	auipc	ra,0xffffb
    80005b9e:	eda080e7          	jalr	-294(ra) # 80000a74 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba2:	04a1                	addi	s1,s1,8
    80005ba4:	ff3499e3          	bne	s1,s3,80005b96 <sys_exec+0xe4>
    80005ba8:	a011                	j	80005bac <sys_exec+0xfa>
  return -1;
    80005baa:	597d                	li	s2,-1
}
    80005bac:	854a                	mv	a0,s2
    80005bae:	60be                	ld	ra,456(sp)
    80005bb0:	641e                	ld	s0,448(sp)
    80005bb2:	74fa                	ld	s1,440(sp)
    80005bb4:	795a                	ld	s2,432(sp)
    80005bb6:	79ba                	ld	s3,424(sp)
    80005bb8:	7a1a                	ld	s4,416(sp)
    80005bba:	6afa                	ld	s5,408(sp)
    80005bbc:	6179                	addi	sp,sp,464
    80005bbe:	8082                	ret

0000000080005bc0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bc0:	7139                	addi	sp,sp,-64
    80005bc2:	fc06                	sd	ra,56(sp)
    80005bc4:	f822                	sd	s0,48(sp)
    80005bc6:	f426                	sd	s1,40(sp)
    80005bc8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bca:	ffffc097          	auipc	ra,0xffffc
    80005bce:	e64080e7          	jalr	-412(ra) # 80001a2e <myproc>
    80005bd2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bd4:	fd840593          	addi	a1,s0,-40
    80005bd8:	4501                	li	a0,0
    80005bda:	ffffd097          	auipc	ra,0xffffd
    80005bde:	048080e7          	jalr	72(ra) # 80002c22 <argaddr>
    return -1;
    80005be2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005be4:	0e054063          	bltz	a0,80005cc4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005be8:	fc840593          	addi	a1,s0,-56
    80005bec:	fd040513          	addi	a0,s0,-48
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	dd2080e7          	jalr	-558(ra) # 800049c2 <pipealloc>
    return -1;
    80005bf8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bfa:	0c054563          	bltz	a0,80005cc4 <sys_pipe+0x104>
  fd0 = -1;
    80005bfe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c02:	fd043503          	ld	a0,-48(s0)
    80005c06:	fffff097          	auipc	ra,0xfffff
    80005c0a:	508080e7          	jalr	1288(ra) # 8000510e <fdalloc>
    80005c0e:	fca42223          	sw	a0,-60(s0)
    80005c12:	08054c63          	bltz	a0,80005caa <sys_pipe+0xea>
    80005c16:	fc843503          	ld	a0,-56(s0)
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	4f4080e7          	jalr	1268(ra) # 8000510e <fdalloc>
    80005c22:	fca42023          	sw	a0,-64(s0)
    80005c26:	06054863          	bltz	a0,80005c96 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c2a:	4691                	li	a3,4
    80005c2c:	fc440613          	addi	a2,s0,-60
    80005c30:	fd843583          	ld	a1,-40(s0)
    80005c34:	68a8                	ld	a0,80(s1)
    80005c36:	ffffc097          	auipc	ra,0xffffc
    80005c3a:	aec080e7          	jalr	-1300(ra) # 80001722 <copyout>
    80005c3e:	02054063          	bltz	a0,80005c5e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c42:	4691                	li	a3,4
    80005c44:	fc040613          	addi	a2,s0,-64
    80005c48:	fd843583          	ld	a1,-40(s0)
    80005c4c:	0591                	addi	a1,a1,4
    80005c4e:	68a8                	ld	a0,80(s1)
    80005c50:	ffffc097          	auipc	ra,0xffffc
    80005c54:	ad2080e7          	jalr	-1326(ra) # 80001722 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c58:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c5a:	06055563          	bgez	a0,80005cc4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c5e:	fc442783          	lw	a5,-60(s0)
    80005c62:	07e9                	addi	a5,a5,26
    80005c64:	078e                	slli	a5,a5,0x3
    80005c66:	97a6                	add	a5,a5,s1
    80005c68:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c6c:	fc042503          	lw	a0,-64(s0)
    80005c70:	0569                	addi	a0,a0,26
    80005c72:	050e                	slli	a0,a0,0x3
    80005c74:	9526                	add	a0,a0,s1
    80005c76:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c7a:	fd043503          	ld	a0,-48(s0)
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	9ee080e7          	jalr	-1554(ra) # 8000466c <fileclose>
    fileclose(wf);
    80005c86:	fc843503          	ld	a0,-56(s0)
    80005c8a:	fffff097          	auipc	ra,0xfffff
    80005c8e:	9e2080e7          	jalr	-1566(ra) # 8000466c <fileclose>
    return -1;
    80005c92:	57fd                	li	a5,-1
    80005c94:	a805                	j	80005cc4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c96:	fc442783          	lw	a5,-60(s0)
    80005c9a:	0007c863          	bltz	a5,80005caa <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c9e:	01a78513          	addi	a0,a5,26
    80005ca2:	050e                	slli	a0,a0,0x3
    80005ca4:	9526                	add	a0,a0,s1
    80005ca6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005caa:	fd043503          	ld	a0,-48(s0)
    80005cae:	fffff097          	auipc	ra,0xfffff
    80005cb2:	9be080e7          	jalr	-1602(ra) # 8000466c <fileclose>
    fileclose(wf);
    80005cb6:	fc843503          	ld	a0,-56(s0)
    80005cba:	fffff097          	auipc	ra,0xfffff
    80005cbe:	9b2080e7          	jalr	-1614(ra) # 8000466c <fileclose>
    return -1;
    80005cc2:	57fd                	li	a5,-1
}
    80005cc4:	853e                	mv	a0,a5
    80005cc6:	70e2                	ld	ra,56(sp)
    80005cc8:	7442                	ld	s0,48(sp)
    80005cca:	74a2                	ld	s1,40(sp)
    80005ccc:	6121                	addi	sp,sp,64
    80005cce:	8082                	ret

0000000080005cd0 <kernelvec>:
    80005cd0:	7111                	addi	sp,sp,-256
    80005cd2:	e006                	sd	ra,0(sp)
    80005cd4:	e40a                	sd	sp,8(sp)
    80005cd6:	e80e                	sd	gp,16(sp)
    80005cd8:	ec12                	sd	tp,24(sp)
    80005cda:	f016                	sd	t0,32(sp)
    80005cdc:	f41a                	sd	t1,40(sp)
    80005cde:	f81e                	sd	t2,48(sp)
    80005ce0:	fc22                	sd	s0,56(sp)
    80005ce2:	e0a6                	sd	s1,64(sp)
    80005ce4:	e4aa                	sd	a0,72(sp)
    80005ce6:	e8ae                	sd	a1,80(sp)
    80005ce8:	ecb2                	sd	a2,88(sp)
    80005cea:	f0b6                	sd	a3,96(sp)
    80005cec:	f4ba                	sd	a4,104(sp)
    80005cee:	f8be                	sd	a5,112(sp)
    80005cf0:	fcc2                	sd	a6,120(sp)
    80005cf2:	e146                	sd	a7,128(sp)
    80005cf4:	e54a                	sd	s2,136(sp)
    80005cf6:	e94e                	sd	s3,144(sp)
    80005cf8:	ed52                	sd	s4,152(sp)
    80005cfa:	f156                	sd	s5,160(sp)
    80005cfc:	f55a                	sd	s6,168(sp)
    80005cfe:	f95e                	sd	s7,176(sp)
    80005d00:	fd62                	sd	s8,184(sp)
    80005d02:	e1e6                	sd	s9,192(sp)
    80005d04:	e5ea                	sd	s10,200(sp)
    80005d06:	e9ee                	sd	s11,208(sp)
    80005d08:	edf2                	sd	t3,216(sp)
    80005d0a:	f1f6                	sd	t4,224(sp)
    80005d0c:	f5fa                	sd	t5,232(sp)
    80005d0e:	f9fe                	sd	t6,240(sp)
    80005d10:	d23fc0ef          	jal	ra,80002a32 <kerneltrap>
    80005d14:	6082                	ld	ra,0(sp)
    80005d16:	6122                	ld	sp,8(sp)
    80005d18:	61c2                	ld	gp,16(sp)
    80005d1a:	7282                	ld	t0,32(sp)
    80005d1c:	7322                	ld	t1,40(sp)
    80005d1e:	73c2                	ld	t2,48(sp)
    80005d20:	7462                	ld	s0,56(sp)
    80005d22:	6486                	ld	s1,64(sp)
    80005d24:	6526                	ld	a0,72(sp)
    80005d26:	65c6                	ld	a1,80(sp)
    80005d28:	6666                	ld	a2,88(sp)
    80005d2a:	7686                	ld	a3,96(sp)
    80005d2c:	7726                	ld	a4,104(sp)
    80005d2e:	77c6                	ld	a5,112(sp)
    80005d30:	7866                	ld	a6,120(sp)
    80005d32:	688a                	ld	a7,128(sp)
    80005d34:	692a                	ld	s2,136(sp)
    80005d36:	69ca                	ld	s3,144(sp)
    80005d38:	6a6a                	ld	s4,152(sp)
    80005d3a:	7a8a                	ld	s5,160(sp)
    80005d3c:	7b2a                	ld	s6,168(sp)
    80005d3e:	7bca                	ld	s7,176(sp)
    80005d40:	7c6a                	ld	s8,184(sp)
    80005d42:	6c8e                	ld	s9,192(sp)
    80005d44:	6d2e                	ld	s10,200(sp)
    80005d46:	6dce                	ld	s11,208(sp)
    80005d48:	6e6e                	ld	t3,216(sp)
    80005d4a:	7e8e                	ld	t4,224(sp)
    80005d4c:	7f2e                	ld	t5,232(sp)
    80005d4e:	7fce                	ld	t6,240(sp)
    80005d50:	6111                	addi	sp,sp,256
    80005d52:	10200073          	sret
    80005d56:	00000013          	nop
    80005d5a:	00000013          	nop
    80005d5e:	0001                	nop

0000000080005d60 <timervec>:
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	e10c                	sd	a1,0(a0)
    80005d66:	e510                	sd	a2,8(a0)
    80005d68:	e914                	sd	a3,16(a0)
    80005d6a:	710c                	ld	a1,32(a0)
    80005d6c:	7510                	ld	a2,40(a0)
    80005d6e:	6194                	ld	a3,0(a1)
    80005d70:	96b2                	add	a3,a3,a2
    80005d72:	e194                	sd	a3,0(a1)
    80005d74:	4589                	li	a1,2
    80005d76:	14459073          	csrw	sip,a1
    80005d7a:	6914                	ld	a3,16(a0)
    80005d7c:	6510                	ld	a2,8(a0)
    80005d7e:	610c                	ld	a1,0(a0)
    80005d80:	34051573          	csrrw	a0,mscratch,a0
    80005d84:	30200073          	mret
	...

0000000080005d8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d8a:	1141                	addi	sp,sp,-16
    80005d8c:	e422                	sd	s0,8(sp)
    80005d8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d90:	0c0007b7          	lui	a5,0xc000
    80005d94:	4705                	li	a4,1
    80005d96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d98:	c3d8                	sw	a4,4(a5)
}
    80005d9a:	6422                	ld	s0,8(sp)
    80005d9c:	0141                	addi	sp,sp,16
    80005d9e:	8082                	ret

0000000080005da0 <plicinithart>:

void
plicinithart(void)
{
    80005da0:	1141                	addi	sp,sp,-16
    80005da2:	e406                	sd	ra,8(sp)
    80005da4:	e022                	sd	s0,0(sp)
    80005da6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c5a080e7          	jalr	-934(ra) # 80001a02 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005db0:	0085171b          	slliw	a4,a0,0x8
    80005db4:	0c0027b7          	lui	a5,0xc002
    80005db8:	97ba                	add	a5,a5,a4
    80005dba:	40200713          	li	a4,1026
    80005dbe:	08e7a023          	sw	a4,128(a5) # c002080 <spin-0x73ffdf9a>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005dc2:	00d5151b          	slliw	a0,a0,0xd
    80005dc6:	0c2017b7          	lui	a5,0xc201
    80005dca:	953e                	add	a0,a0,a5
    80005dcc:	00052023          	sw	zero,0(a0)
}
    80005dd0:	60a2                	ld	ra,8(sp)
    80005dd2:	6402                	ld	s0,0(sp)
    80005dd4:	0141                	addi	sp,sp,16
    80005dd6:	8082                	ret

0000000080005dd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dd8:	1141                	addi	sp,sp,-16
    80005dda:	e406                	sd	ra,8(sp)
    80005ddc:	e022                	sd	s0,0(sp)
    80005dde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005de0:	ffffc097          	auipc	ra,0xffffc
    80005de4:	c22080e7          	jalr	-990(ra) # 80001a02 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005de8:	00d5179b          	slliw	a5,a0,0xd
    80005dec:	0c201537          	lui	a0,0xc201
    80005df0:	953e                	add	a0,a0,a5
  return irq;
}
    80005df2:	4148                	lw	a0,4(a0)
    80005df4:	60a2                	ld	ra,8(sp)
    80005df6:	6402                	ld	s0,0(sp)
    80005df8:	0141                	addi	sp,sp,16
    80005dfa:	8082                	ret

0000000080005dfc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dfc:	1101                	addi	sp,sp,-32
    80005dfe:	ec06                	sd	ra,24(sp)
    80005e00:	e822                	sd	s0,16(sp)
    80005e02:	e426                	sd	s1,8(sp)
    80005e04:	1000                	addi	s0,sp,32
    80005e06:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	bfa080e7          	jalr	-1030(ra) # 80001a02 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e10:	00d5151b          	slliw	a0,a0,0xd
    80005e14:	0c2017b7          	lui	a5,0xc201
    80005e18:	97aa                	add	a5,a5,a0
    80005e1a:	c3c4                	sw	s1,4(a5)
}
    80005e1c:	60e2                	ld	ra,24(sp)
    80005e1e:	6442                	ld	s0,16(sp)
    80005e20:	64a2                	ld	s1,8(sp)
    80005e22:	6105                	addi	sp,sp,32
    80005e24:	8082                	ret

0000000080005e26 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e26:	1141                	addi	sp,sp,-16
    80005e28:	e406                	sd	ra,8(sp)
    80005e2a:	e022                	sd	s0,0(sp)
    80005e2c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e2e:	479d                	li	a5,7
    80005e30:	04a7cc63          	blt	a5,a0,80005e88 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e34:	0001e797          	auipc	a5,0x1e
    80005e38:	1cc78793          	addi	a5,a5,460 # 80024000 <disk>
    80005e3c:	00a78733          	add	a4,a5,a0
    80005e40:	6789                	lui	a5,0x2
    80005e42:	97ba                	add	a5,a5,a4
    80005e44:	0187c783          	lbu	a5,24(a5) # 2018 <spin-0x7fffe002>
    80005e48:	eba1                	bnez	a5,80005e98 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e4a:	00451713          	slli	a4,a0,0x4
    80005e4e:	00020797          	auipc	a5,0x20
    80005e52:	1b27b783          	ld	a5,434(a5) # 80026000 <disk+0x2000>
    80005e56:	97ba                	add	a5,a5,a4
    80005e58:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e5c:	0001e797          	auipc	a5,0x1e
    80005e60:	1a478793          	addi	a5,a5,420 # 80024000 <disk>
    80005e64:	97aa                	add	a5,a5,a0
    80005e66:	6509                	lui	a0,0x2
    80005e68:	953e                	add	a0,a0,a5
    80005e6a:	4785                	li	a5,1
    80005e6c:	00f50c23          	sb	a5,24(a0) # 2018 <spin-0x7fffe002>
  wakeup(&disk.free[0]);
    80005e70:	00020517          	auipc	a0,0x20
    80005e74:	1a850513          	addi	a0,a0,424 # 80026018 <disk+0x2018>
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	602080e7          	jalr	1538(ra) # 8000247a <wakeup>
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	8e850513          	addi	a0,a0,-1816 # 80008770 <syscalls+0x340>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	6ac080e7          	jalr	1708(ra) # 8000053c <panic>
    panic("virtio_disk_intr 2");
    80005e98:	00003517          	auipc	a0,0x3
    80005e9c:	8f050513          	addi	a0,a0,-1808 # 80008788 <syscalls+0x358>
    80005ea0:	ffffa097          	auipc	ra,0xffffa
    80005ea4:	69c080e7          	jalr	1692(ra) # 8000053c <panic>

0000000080005ea8 <virtio_disk_init>:
{
    80005ea8:	1101                	addi	sp,sp,-32
    80005eaa:	ec06                	sd	ra,24(sp)
    80005eac:	e822                	sd	s0,16(sp)
    80005eae:	e426                	sd	s1,8(sp)
    80005eb0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005eb2:	00003597          	auipc	a1,0x3
    80005eb6:	8ee58593          	addi	a1,a1,-1810 # 800087a0 <syscalls+0x370>
    80005eba:	00020517          	auipc	a0,0x20
    80005ebe:	1ee50513          	addi	a0,a0,494 # 800260a8 <disk+0x20a8>
    80005ec2:	ffffb097          	auipc	ra,0xffffb
    80005ec6:	d0e080e7          	jalr	-754(ra) # 80000bd0 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eca:	100017b7          	lui	a5,0x10001
    80005ece:	4398                	lw	a4,0(a5)
    80005ed0:	2701                	sext.w	a4,a4
    80005ed2:	747277b7          	lui	a5,0x74727
    80005ed6:	97678793          	addi	a5,a5,-1674 # 74726976 <spin-0xb8d96a4>
    80005eda:	0ef71163          	bne	a4,a5,80005fbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ede:	100017b7          	lui	a5,0x10001
    80005ee2:	43dc                	lw	a5,4(a5)
    80005ee4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ee6:	4705                	li	a4,1
    80005ee8:	0ce79a63          	bne	a5,a4,80005fbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eec:	100017b7          	lui	a5,0x10001
    80005ef0:	479c                	lw	a5,8(a5)
    80005ef2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ef4:	4709                	li	a4,2
    80005ef6:	0ce79363          	bne	a5,a4,80005fbc <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005efa:	100017b7          	lui	a5,0x10001
    80005efe:	47d8                	lw	a4,12(a5)
    80005f00:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f02:	554d47b7          	lui	a5,0x554d4
    80005f06:	55178793          	addi	a5,a5,1361 # 554d4551 <spin-0x2ab2bac9>
    80005f0a:	0af71963          	bne	a4,a5,80005fbc <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0e:	100017b7          	lui	a5,0x10001
    80005f12:	4705                	li	a4,1
    80005f14:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f16:	470d                	li	a4,3
    80005f18:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f1a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f1c:	c7ffe737          	lui	a4,0xc7ffe
    80005f20:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005f24:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f26:	2701                	sext.w	a4,a4
    80005f28:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f2a:	472d                	li	a4,11
    80005f2c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f2e:	473d                	li	a4,15
    80005f30:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f32:	6705                	lui	a4,0x1
    80005f34:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f36:	0207a823          	sw	zero,48(a5) # 10001030 <spin-0x6fffefea>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f3a:	5bdc                	lw	a5,52(a5)
    80005f3c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f3e:	c7d9                	beqz	a5,80005fcc <virtio_disk_init+0x124>
  if(max < NUM)
    80005f40:	471d                	li	a4,7
    80005f42:	08f77d63          	bgeu	a4,a5,80005fdc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f46:	100014b7          	lui	s1,0x10001
    80005f4a:	47a1                	li	a5,8
    80005f4c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f4e:	6609                	lui	a2,0x2
    80005f50:	4581                	li	a1,0
    80005f52:	0001e517          	auipc	a0,0x1e
    80005f56:	0ae50513          	addi	a0,a0,174 # 80024000 <disk>
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	e02080e7          	jalr	-510(ra) # 80000d5c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f62:	0001e717          	auipc	a4,0x1e
    80005f66:	09e70713          	addi	a4,a4,158 # 80024000 <disk>
    80005f6a:	00c75793          	srli	a5,a4,0xc
    80005f6e:	2781                	sext.w	a5,a5
    80005f70:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f72:	00020797          	auipc	a5,0x20
    80005f76:	08e78793          	addi	a5,a5,142 # 80026000 <disk+0x2000>
    80005f7a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f7c:	0001e717          	auipc	a4,0x1e
    80005f80:	10470713          	addi	a4,a4,260 # 80024080 <disk+0x80>
    80005f84:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f86:	0001f717          	auipc	a4,0x1f
    80005f8a:	07a70713          	addi	a4,a4,122 # 80025000 <disk+0x1000>
    80005f8e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f90:	4705                	li	a4,1
    80005f92:	00e78c23          	sb	a4,24(a5)
    80005f96:	00e78ca3          	sb	a4,25(a5)
    80005f9a:	00e78d23          	sb	a4,26(a5)
    80005f9e:	00e78da3          	sb	a4,27(a5)
    80005fa2:	00e78e23          	sb	a4,28(a5)
    80005fa6:	00e78ea3          	sb	a4,29(a5)
    80005faa:	00e78f23          	sb	a4,30(a5)
    80005fae:	00e78fa3          	sb	a4,31(a5)
}
    80005fb2:	60e2                	ld	ra,24(sp)
    80005fb4:	6442                	ld	s0,16(sp)
    80005fb6:	64a2                	ld	s1,8(sp)
    80005fb8:	6105                	addi	sp,sp,32
    80005fba:	8082                	ret
    panic("could not find virtio disk");
    80005fbc:	00002517          	auipc	a0,0x2
    80005fc0:	7f450513          	addi	a0,a0,2036 # 800087b0 <syscalls+0x380>
    80005fc4:	ffffa097          	auipc	ra,0xffffa
    80005fc8:	578080e7          	jalr	1400(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80005fcc:	00003517          	auipc	a0,0x3
    80005fd0:	80450513          	addi	a0,a0,-2044 # 800087d0 <syscalls+0x3a0>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	568080e7          	jalr	1384(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80005fdc:	00003517          	auipc	a0,0x3
    80005fe0:	81450513          	addi	a0,a0,-2028 # 800087f0 <syscalls+0x3c0>
    80005fe4:	ffffa097          	auipc	ra,0xffffa
    80005fe8:	558080e7          	jalr	1368(ra) # 8000053c <panic>

0000000080005fec <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fec:	7119                	addi	sp,sp,-128
    80005fee:	fc86                	sd	ra,120(sp)
    80005ff0:	f8a2                	sd	s0,112(sp)
    80005ff2:	f4a6                	sd	s1,104(sp)
    80005ff4:	f0ca                	sd	s2,96(sp)
    80005ff6:	ecce                	sd	s3,88(sp)
    80005ff8:	e8d2                	sd	s4,80(sp)
    80005ffa:	e4d6                	sd	s5,72(sp)
    80005ffc:	e0da                	sd	s6,64(sp)
    80005ffe:	fc5e                	sd	s7,56(sp)
    80006000:	f862                	sd	s8,48(sp)
    80006002:	f466                	sd	s9,40(sp)
    80006004:	f06a                	sd	s10,32(sp)
    80006006:	0100                	addi	s0,sp,128
    80006008:	892a                	mv	s2,a0
    8000600a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000600c:	00c52c83          	lw	s9,12(a0)
    80006010:	001c9c9b          	slliw	s9,s9,0x1
    80006014:	1c82                	slli	s9,s9,0x20
    80006016:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000601a:	00020517          	auipc	a0,0x20
    8000601e:	08e50513          	addi	a0,a0,142 # 800260a8 <disk+0x20a8>
    80006022:	ffffb097          	auipc	ra,0xffffb
    80006026:	c3e080e7          	jalr	-962(ra) # 80000c60 <acquire>
  for(int i = 0; i < 3; i++){
    8000602a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000602c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000602e:	0001eb97          	auipc	s7,0x1e
    80006032:	fd2b8b93          	addi	s7,s7,-46 # 80024000 <disk>
    80006036:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006038:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000603a:	8a4e                	mv	s4,s3
    8000603c:	a051                	j	800060c0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000603e:	00fb86b3          	add	a3,s7,a5
    80006042:	96da                	add	a3,a3,s6
    80006044:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006048:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000604a:	0207c563          	bltz	a5,80006074 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000604e:	2485                	addiw	s1,s1,1
    80006050:	0711                	addi	a4,a4,4
    80006052:	23548d63          	beq	s1,s5,8000628c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006056:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006058:	00020697          	auipc	a3,0x20
    8000605c:	fc068693          	addi	a3,a3,-64 # 80026018 <disk+0x2018>
    80006060:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006062:	0006c583          	lbu	a1,0(a3)
    80006066:	fde1                	bnez	a1,8000603e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006068:	2785                	addiw	a5,a5,1
    8000606a:	0685                	addi	a3,a3,1
    8000606c:	ff879be3          	bne	a5,s8,80006062 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006070:	57fd                	li	a5,-1
    80006072:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006074:	02905a63          	blez	s1,800060a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006078:	f9042503          	lw	a0,-112(s0)
    8000607c:	00000097          	auipc	ra,0x0
    80006080:	daa080e7          	jalr	-598(ra) # 80005e26 <free_desc>
      for(int j = 0; j < i; j++)
    80006084:	4785                	li	a5,1
    80006086:	0297d163          	bge	a5,s1,800060a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000608a:	f9442503          	lw	a0,-108(s0)
    8000608e:	00000097          	auipc	ra,0x0
    80006092:	d98080e7          	jalr	-616(ra) # 80005e26 <free_desc>
      for(int j = 0; j < i; j++)
    80006096:	4789                	li	a5,2
    80006098:	0097d863          	bge	a5,s1,800060a8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000609c:	f9842503          	lw	a0,-104(s0)
    800060a0:	00000097          	auipc	ra,0x0
    800060a4:	d86080e7          	jalr	-634(ra) # 80005e26 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a8:	00020597          	auipc	a1,0x20
    800060ac:	00058593          	mv	a1,a1
    800060b0:	00020517          	auipc	a0,0x20
    800060b4:	f6850513          	addi	a0,a0,-152 # 80026018 <disk+0x2018>
    800060b8:	ffffc097          	auipc	ra,0xffffc
    800060bc:	23c080e7          	jalr	572(ra) # 800022f4 <sleep>
  for(int i = 0; i < 3; i++){
    800060c0:	f9040713          	addi	a4,s0,-112
    800060c4:	84ce                	mv	s1,s3
    800060c6:	bf41                	j	80006056 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800060c8:	4785                	li	a5,1
    800060ca:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800060ce:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800060d2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060d6:	f9042983          	lw	s3,-112(s0)
    800060da:	00499493          	slli	s1,s3,0x4
    800060de:	00020a17          	auipc	s4,0x20
    800060e2:	f22a0a13          	addi	s4,s4,-222 # 80026000 <disk+0x2000>
    800060e6:	000a3a83          	ld	s5,0(s4)
    800060ea:	9aa6                	add	s5,s5,s1
    800060ec:	f8040513          	addi	a0,s0,-128
    800060f0:	ffffb097          	auipc	ra,0xffffb
    800060f4:	040080e7          	jalr	64(ra) # 80001130 <kvmpa>
    800060f8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060fc:	000a3783          	ld	a5,0(s4)
    80006100:	97a6                	add	a5,a5,s1
    80006102:	4741                	li	a4,16
    80006104:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006106:	000a3783          	ld	a5,0(s4)
    8000610a:	97a6                	add	a5,a5,s1
    8000610c:	4705                	li	a4,1
    8000610e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006112:	f9442703          	lw	a4,-108(s0)
    80006116:	000a3783          	ld	a5,0(s4)
    8000611a:	97a6                	add	a5,a5,s1
    8000611c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006120:	0712                	slli	a4,a4,0x4
    80006122:	000a3783          	ld	a5,0(s4)
    80006126:	97ba                	add	a5,a5,a4
    80006128:	05890693          	addi	a3,s2,88
    8000612c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000612e:	000a3783          	ld	a5,0(s4)
    80006132:	97ba                	add	a5,a5,a4
    80006134:	40000693          	li	a3,1024
    80006138:	c794                	sw	a3,8(a5)
  if(write)
    8000613a:	100d0a63          	beqz	s10,8000624e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000613e:	00020797          	auipc	a5,0x20
    80006142:	ec27b783          	ld	a5,-318(a5) # 80026000 <disk+0x2000>
    80006146:	97ba                	add	a5,a5,a4
    80006148:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000614c:	0001e517          	auipc	a0,0x1e
    80006150:	eb450513          	addi	a0,a0,-332 # 80024000 <disk>
    80006154:	00020797          	auipc	a5,0x20
    80006158:	eac78793          	addi	a5,a5,-340 # 80026000 <disk+0x2000>
    8000615c:	6394                	ld	a3,0(a5)
    8000615e:	96ba                	add	a3,a3,a4
    80006160:	00c6d603          	lhu	a2,12(a3)
    80006164:	00166613          	ori	a2,a2,1
    80006168:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000616c:	f9842683          	lw	a3,-104(s0)
    80006170:	6390                	ld	a2,0(a5)
    80006172:	9732                	add	a4,a4,a2
    80006174:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006178:	20098613          	addi	a2,s3,512
    8000617c:	0612                	slli	a2,a2,0x4
    8000617e:	962a                	add	a2,a2,a0
    80006180:	02060823          	sb	zero,48(a2) # 2030 <spin-0x7fffdfea>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006184:	00469713          	slli	a4,a3,0x4
    80006188:	6394                	ld	a3,0(a5)
    8000618a:	96ba                	add	a3,a3,a4
    8000618c:	6589                	lui	a1,0x2
    8000618e:	03058593          	addi	a1,a1,48 # 2030 <spin-0x7fffdfea>
    80006192:	94ae                	add	s1,s1,a1
    80006194:	94aa                	add	s1,s1,a0
    80006196:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006198:	6394                	ld	a3,0(a5)
    8000619a:	96ba                	add	a3,a3,a4
    8000619c:	4585                	li	a1,1
    8000619e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061a0:	6394                	ld	a3,0(a5)
    800061a2:	96ba                	add	a3,a3,a4
    800061a4:	4509                	li	a0,2
    800061a6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800061aa:	6394                	ld	a3,0(a5)
    800061ac:	9736                	add	a4,a4,a3
    800061ae:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061b2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061b6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061ba:	6794                	ld	a3,8(a5)
    800061bc:	0026d703          	lhu	a4,2(a3)
    800061c0:	8b1d                	andi	a4,a4,7
    800061c2:	2709                	addiw	a4,a4,2
    800061c4:	0706                	slli	a4,a4,0x1
    800061c6:	9736                	add	a4,a4,a3
    800061c8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800061cc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061d0:	6798                	ld	a4,8(a5)
    800061d2:	00275783          	lhu	a5,2(a4)
    800061d6:	2785                	addiw	a5,a5,1
    800061d8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061dc:	100017b7          	lui	a5,0x10001
    800061e0:	0407a823          	sw	zero,80(a5) # 10001050 <spin-0x6fffefca>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061e4:	00492703          	lw	a4,4(s2)
    800061e8:	4785                	li	a5,1
    800061ea:	02f71163          	bne	a4,a5,8000620c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061ee:	00020997          	auipc	s3,0x20
    800061f2:	eba98993          	addi	s3,s3,-326 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061f8:	85ce                	mv	a1,s3
    800061fa:	854a                	mv	a0,s2
    800061fc:	ffffc097          	auipc	ra,0xffffc
    80006200:	0f8080e7          	jalr	248(ra) # 800022f4 <sleep>
  while(b->disk == 1) {
    80006204:	00492783          	lw	a5,4(s2)
    80006208:	fe9788e3          	beq	a5,s1,800061f8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000620c:	f9042483          	lw	s1,-112(s0)
    80006210:	20048793          	addi	a5,s1,512 # 10001200 <spin-0x6fffee1a>
    80006214:	00479713          	slli	a4,a5,0x4
    80006218:	0001e797          	auipc	a5,0x1e
    8000621c:	de878793          	addi	a5,a5,-536 # 80024000 <disk>
    80006220:	97ba                	add	a5,a5,a4
    80006222:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006226:	00020917          	auipc	s2,0x20
    8000622a:	dda90913          	addi	s2,s2,-550 # 80026000 <disk+0x2000>
    free_desc(i);
    8000622e:	8526                	mv	a0,s1
    80006230:	00000097          	auipc	ra,0x0
    80006234:	bf6080e7          	jalr	-1034(ra) # 80005e26 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006238:	0492                	slli	s1,s1,0x4
    8000623a:	00093783          	ld	a5,0(s2)
    8000623e:	94be                	add	s1,s1,a5
    80006240:	00c4d783          	lhu	a5,12(s1)
    80006244:	8b85                	andi	a5,a5,1
    80006246:	cf89                	beqz	a5,80006260 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006248:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000624c:	b7cd                	j	8000622e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000624e:	00020797          	auipc	a5,0x20
    80006252:	db27b783          	ld	a5,-590(a5) # 80026000 <disk+0x2000>
    80006256:	97ba                	add	a5,a5,a4
    80006258:	4689                	li	a3,2
    8000625a:	00d79623          	sh	a3,12(a5)
    8000625e:	b5fd                	j	8000614c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006260:	00020517          	auipc	a0,0x20
    80006264:	e4850513          	addi	a0,a0,-440 # 800260a8 <disk+0x20a8>
    80006268:	ffffb097          	auipc	ra,0xffffb
    8000626c:	aac080e7          	jalr	-1364(ra) # 80000d14 <release>
}
    80006270:	70e6                	ld	ra,120(sp)
    80006272:	7446                	ld	s0,112(sp)
    80006274:	74a6                	ld	s1,104(sp)
    80006276:	7906                	ld	s2,96(sp)
    80006278:	69e6                	ld	s3,88(sp)
    8000627a:	6a46                	ld	s4,80(sp)
    8000627c:	6aa6                	ld	s5,72(sp)
    8000627e:	6b06                	ld	s6,64(sp)
    80006280:	7be2                	ld	s7,56(sp)
    80006282:	7c42                	ld	s8,48(sp)
    80006284:	7ca2                	ld	s9,40(sp)
    80006286:	7d02                	ld	s10,32(sp)
    80006288:	6109                	addi	sp,sp,128
    8000628a:	8082                	ret
  if(write)
    8000628c:	e20d1ee3          	bnez	s10,800060c8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006290:	f8042023          	sw	zero,-128(s0)
    80006294:	bd2d                	j	800060ce <virtio_disk_rw+0xe2>

0000000080006296 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006296:	1101                	addi	sp,sp,-32
    80006298:	ec06                	sd	ra,24(sp)
    8000629a:	e822                	sd	s0,16(sp)
    8000629c:	e426                	sd	s1,8(sp)
    8000629e:	e04a                	sd	s2,0(sp)
    800062a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062a2:	00020517          	auipc	a0,0x20
    800062a6:	e0650513          	addi	a0,a0,-506 # 800260a8 <disk+0x20a8>
    800062aa:	ffffb097          	auipc	ra,0xffffb
    800062ae:	9b6080e7          	jalr	-1610(ra) # 80000c60 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062b2:	00020717          	auipc	a4,0x20
    800062b6:	d4e70713          	addi	a4,a4,-690 # 80026000 <disk+0x2000>
    800062ba:	02075783          	lhu	a5,32(a4)
    800062be:	6b18                	ld	a4,16(a4)
    800062c0:	00275683          	lhu	a3,2(a4)
    800062c4:	8ebd                	xor	a3,a3,a5
    800062c6:	8a9d                	andi	a3,a3,7
    800062c8:	cab9                	beqz	a3,8000631e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062ca:	0001e917          	auipc	s2,0x1e
    800062ce:	d3690913          	addi	s2,s2,-714 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062d2:	00020497          	auipc	s1,0x20
    800062d6:	d2e48493          	addi	s1,s1,-722 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062da:	078e                	slli	a5,a5,0x3
    800062dc:	97ba                	add	a5,a5,a4
    800062de:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062e0:	20078713          	addi	a4,a5,512
    800062e4:	0712                	slli	a4,a4,0x4
    800062e6:	974a                	add	a4,a4,s2
    800062e8:	03074703          	lbu	a4,48(a4)
    800062ec:	ef21                	bnez	a4,80006344 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062ee:	20078793          	addi	a5,a5,512
    800062f2:	0792                	slli	a5,a5,0x4
    800062f4:	97ca                	add	a5,a5,s2
    800062f6:	7798                	ld	a4,40(a5)
    800062f8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062fc:	7788                	ld	a0,40(a5)
    800062fe:	ffffc097          	auipc	ra,0xffffc
    80006302:	17c080e7          	jalr	380(ra) # 8000247a <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006306:	0204d783          	lhu	a5,32(s1)
    8000630a:	2785                	addiw	a5,a5,1
    8000630c:	8b9d                	andi	a5,a5,7
    8000630e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006312:	6898                	ld	a4,16(s1)
    80006314:	00275683          	lhu	a3,2(a4)
    80006318:	8a9d                	andi	a3,a3,7
    8000631a:	fcf690e3          	bne	a3,a5,800062da <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000631e:	10001737          	lui	a4,0x10001
    80006322:	533c                	lw	a5,96(a4)
    80006324:	8b8d                	andi	a5,a5,3
    80006326:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006328:	00020517          	auipc	a0,0x20
    8000632c:	d8050513          	addi	a0,a0,-640 # 800260a8 <disk+0x20a8>
    80006330:	ffffb097          	auipc	ra,0xffffb
    80006334:	9e4080e7          	jalr	-1564(ra) # 80000d14 <release>
}
    80006338:	60e2                	ld	ra,24(sp)
    8000633a:	6442                	ld	s0,16(sp)
    8000633c:	64a2                	ld	s1,8(sp)
    8000633e:	6902                	ld	s2,0(sp)
    80006340:	6105                	addi	sp,sp,32
    80006342:	8082                	ret
      panic("virtio_disk_intr status");
    80006344:	00002517          	auipc	a0,0x2
    80006348:	4cc50513          	addi	a0,a0,1228 # 80008810 <syscalls+0x3e0>
    8000634c:	ffffa097          	auipc	ra,0xffffa
    80006350:	1f0080e7          	jalr	496(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
