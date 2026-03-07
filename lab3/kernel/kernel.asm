
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	83010113          	addi	sp,sp,-2000 # 80009830 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	de478793          	addi	a5,a5,-540 # 80005e40 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e2678793          	addi	a5,a5,-474 # 80000ecc <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d0:	57fd                	li	a5,-1
    800000d2:	83a9                	srli	a5,a5,0xa
    800000d4:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000d8:	47bd                	li	a5,15
    800000da:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000de:	00000097          	auipc	ra,0x0
    800000e2:	f3e080e7          	jalr	-194(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e6:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000ea:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000ec:	823e                	mv	tp,a5
  asm volatile("mret");
    800000ee:	30200073          	mret
}
    800000f2:	60a2                	ld	ra,8(sp)
    800000f4:	6402                	ld	s0,0(sp)
    800000f6:	0141                	addi	sp,sp,16
    800000f8:	8082                	ret

00000000800000fa <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000fa:	715d                	addi	sp,sp,-80
    800000fc:	e486                	sd	ra,72(sp)
    800000fe:	e0a2                	sd	s0,64(sp)
    80000100:	fc26                	sd	s1,56(sp)
    80000102:	f84a                	sd	s2,48(sp)
    80000104:	f44e                	sd	s3,40(sp)
    80000106:	f052                	sd	s4,32(sp)
    80000108:	ec56                	sd	s5,24(sp)
    8000010a:	0880                	addi	s0,sp,80
    8000010c:	8a2a                	mv	s4,a0
    8000010e:	84ae                	mv	s1,a1
    80000110:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000112:	00011517          	auipc	a0,0x11
    80000116:	71e50513          	addi	a0,a0,1822 # 80011830 <cons>
    8000011a:	00001097          	auipc	ra,0x1
    8000011e:	b04080e7          	jalr	-1276(ra) # 80000c1e <acquire>
  for(i = 0; i < n; i++){
    80000122:	05305b63          	blez	s3,80000178 <consolewrite+0x7e>
    80000126:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000128:	5afd                	li	s5,-1
    8000012a:	4685                	li	a3,1
    8000012c:	8626                	mv	a2,s1
    8000012e:	85d2                	mv	a1,s4
    80000130:	fbf40513          	addi	a0,s0,-65
    80000134:	00002097          	auipc	ra,0x2
    80000138:	5b2080e7          	jalr	1458(ra) # 800026e6 <either_copyin>
    8000013c:	01550c63          	beq	a0,s5,80000154 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000140:	fbf44503          	lbu	a0,-65(s0)
    80000144:	00000097          	auipc	ra,0x0
    80000148:	7aa080e7          	jalr	1962(ra) # 800008ee <uartputc>
  for(i = 0; i < n; i++){
    8000014c:	2905                	addiw	s2,s2,1
    8000014e:	0485                	addi	s1,s1,1
    80000150:	fd299de3          	bne	s3,s2,8000012a <consolewrite+0x30>
  }
  release(&cons.lock);
    80000154:	00011517          	auipc	a0,0x11
    80000158:	6dc50513          	addi	a0,a0,1756 # 80011830 <cons>
    8000015c:	00001097          	auipc	ra,0x1
    80000160:	b76080e7          	jalr	-1162(ra) # 80000cd2 <release>

  return i;
}
    80000164:	854a                	mv	a0,s2
    80000166:	60a6                	ld	ra,72(sp)
    80000168:	6406                	ld	s0,64(sp)
    8000016a:	74e2                	ld	s1,56(sp)
    8000016c:	7942                	ld	s2,48(sp)
    8000016e:	79a2                	ld	s3,40(sp)
    80000170:	7a02                	ld	s4,32(sp)
    80000172:	6ae2                	ld	s5,24(sp)
    80000174:	6161                	addi	sp,sp,80
    80000176:	8082                	ret
  for(i = 0; i < n; i++){
    80000178:	4901                	li	s2,0
    8000017a:	bfe9                	j	80000154 <consolewrite+0x5a>

000000008000017c <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000017c:	7119                	addi	sp,sp,-128
    8000017e:	fc86                	sd	ra,120(sp)
    80000180:	f8a2                	sd	s0,112(sp)
    80000182:	f4a6                	sd	s1,104(sp)
    80000184:	f0ca                	sd	s2,96(sp)
    80000186:	ecce                	sd	s3,88(sp)
    80000188:	e8d2                	sd	s4,80(sp)
    8000018a:	e4d6                	sd	s5,72(sp)
    8000018c:	e0da                	sd	s6,64(sp)
    8000018e:	fc5e                	sd	s7,56(sp)
    80000190:	f862                	sd	s8,48(sp)
    80000192:	f466                	sd	s9,40(sp)
    80000194:	f06a                	sd	s10,32(sp)
    80000196:	ec6e                	sd	s11,24(sp)
    80000198:	0100                	addi	s0,sp,128
    8000019a:	8b2a                	mv	s6,a0
    8000019c:	8aae                	mv	s5,a1
    8000019e:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    800001a0:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    800001a4:	00011517          	auipc	a0,0x11
    800001a8:	68c50513          	addi	a0,a0,1676 # 80011830 <cons>
    800001ac:	00001097          	auipc	ra,0x1
    800001b0:	a72080e7          	jalr	-1422(ra) # 80000c1e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001b4:	00011497          	auipc	s1,0x11
    800001b8:	67c48493          	addi	s1,s1,1660 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001bc:	89a6                	mv	s3,s1
    800001be:	00011917          	auipc	s2,0x11
    800001c2:	70a90913          	addi	s2,s2,1802 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c6:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c8:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ca:	4da9                	li	s11,10
  while(n > 0){
    800001cc:	07405863          	blez	s4,8000023c <consoleread+0xc0>
    while(cons.r == cons.w){
    800001d0:	0984a783          	lw	a5,152(s1)
    800001d4:	09c4a703          	lw	a4,156(s1)
    800001d8:	02f71463          	bne	a4,a5,80000200 <consoleread+0x84>
      if(myproc()->killed){
    800001dc:	00002097          	auipc	ra,0x2
    800001e0:	92a080e7          	jalr	-1750(ra) # 80001b06 <myproc>
    800001e4:	591c                	lw	a5,48(a0)
    800001e6:	e7b5                	bnez	a5,80000252 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e8:	85ce                	mv	a1,s3
    800001ea:	854a                	mv	a0,s2
    800001ec:	00002097          	auipc	ra,0x2
    800001f0:	242080e7          	jalr	578(ra) # 8000242e <sleep>
    while(cons.r == cons.w){
    800001f4:	0984a783          	lw	a5,152(s1)
    800001f8:	09c4a703          	lw	a4,156(s1)
    800001fc:	fef700e3          	beq	a4,a5,800001dc <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    80000200:	0017871b          	addiw	a4,a5,1
    80000204:	08e4ac23          	sw	a4,152(s1)
    80000208:	07f7f713          	andi	a4,a5,127
    8000020c:	9726                	add	a4,a4,s1
    8000020e:	01874703          	lbu	a4,24(a4)
    80000212:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000216:	079c0663          	beq	s8,s9,80000282 <consoleread+0x106>
    cbuf = c;
    8000021a:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000021e:	4685                	li	a3,1
    80000220:	f8f40613          	addi	a2,s0,-113
    80000224:	85d6                	mv	a1,s5
    80000226:	855a                	mv	a0,s6
    80000228:	00002097          	auipc	ra,0x2
    8000022c:	468080e7          	jalr	1128(ra) # 80002690 <either_copyout>
    80000230:	01a50663          	beq	a0,s10,8000023c <consoleread+0xc0>
    dst++;
    80000234:	0a85                	addi	s5,s5,1
    --n;
    80000236:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000238:	f9bc1ae3          	bne	s8,s11,800001cc <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	5f450513          	addi	a0,a0,1524 # 80011830 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a8e080e7          	jalr	-1394(ra) # 80000cd2 <release>

  return target - n;
    8000024c:	414b853b          	subw	a0,s7,s4
    80000250:	a811                	j	80000264 <consoleread+0xe8>
        release(&cons.lock);
    80000252:	00011517          	auipc	a0,0x11
    80000256:	5de50513          	addi	a0,a0,1502 # 80011830 <cons>
    8000025a:	00001097          	auipc	ra,0x1
    8000025e:	a78080e7          	jalr	-1416(ra) # 80000cd2 <release>
        return -1;
    80000262:	557d                	li	a0,-1
}
    80000264:	70e6                	ld	ra,120(sp)
    80000266:	7446                	ld	s0,112(sp)
    80000268:	74a6                	ld	s1,104(sp)
    8000026a:	7906                	ld	s2,96(sp)
    8000026c:	69e6                	ld	s3,88(sp)
    8000026e:	6a46                	ld	s4,80(sp)
    80000270:	6aa6                	ld	s5,72(sp)
    80000272:	6b06                	ld	s6,64(sp)
    80000274:	7be2                	ld	s7,56(sp)
    80000276:	7c42                	ld	s8,48(sp)
    80000278:	7ca2                	ld	s9,40(sp)
    8000027a:	7d02                	ld	s10,32(sp)
    8000027c:	6de2                	ld	s11,24(sp)
    8000027e:	6109                	addi	sp,sp,128
    80000280:	8082                	ret
      if(n < target){
    80000282:	000a071b          	sext.w	a4,s4
    80000286:	fb777be3          	bgeu	a4,s7,8000023c <consoleread+0xc0>
        cons.r--;
    8000028a:	00011717          	auipc	a4,0x11
    8000028e:	62f72f23          	sw	a5,1598(a4) # 800118c8 <cons+0x98>
    80000292:	b76d                	j	8000023c <consoleread+0xc0>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	564080e7          	jalr	1380(ra) # 80000808 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	552080e7          	jalr	1362(ra) # 80000808 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	546080e7          	jalr	1350(ra) # 80000808 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	53c080e7          	jalr	1340(ra) # 80000808 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	e04a                	sd	s2,0(sp)
    800002e0:	1000                	addi	s0,sp,32
    800002e2:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e4:	00011517          	auipc	a0,0x11
    800002e8:	54c50513          	addi	a0,a0,1356 # 80011830 <cons>
    800002ec:	00001097          	auipc	ra,0x1
    800002f0:	932080e7          	jalr	-1742(ra) # 80000c1e <acquire>

  switch(c){
    800002f4:	47d5                	li	a5,21
    800002f6:	0af48663          	beq	s1,a5,800003a2 <consoleintr+0xcc>
    800002fa:	0297ca63          	blt	a5,s1,8000032e <consoleintr+0x58>
    800002fe:	47a1                	li	a5,8
    80000300:	0ef48763          	beq	s1,a5,800003ee <consoleintr+0x118>
    80000304:	47c1                	li	a5,16
    80000306:	10f49a63          	bne	s1,a5,8000041a <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    8000030a:	00002097          	auipc	ra,0x2
    8000030e:	432080e7          	jalr	1074(ra) # 8000273c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000312:	00011517          	auipc	a0,0x11
    80000316:	51e50513          	addi	a0,a0,1310 # 80011830 <cons>
    8000031a:	00001097          	auipc	ra,0x1
    8000031e:	9b8080e7          	jalr	-1608(ra) # 80000cd2 <release>
}
    80000322:	60e2                	ld	ra,24(sp)
    80000324:	6442                	ld	s0,16(sp)
    80000326:	64a2                	ld	s1,8(sp)
    80000328:	6902                	ld	s2,0(sp)
    8000032a:	6105                	addi	sp,sp,32
    8000032c:	8082                	ret
  switch(c){
    8000032e:	07f00793          	li	a5,127
    80000332:	0af48e63          	beq	s1,a5,800003ee <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000336:	00011717          	auipc	a4,0x11
    8000033a:	4fa70713          	addi	a4,a4,1274 # 80011830 <cons>
    8000033e:	0a072783          	lw	a5,160(a4)
    80000342:	09872703          	lw	a4,152(a4)
    80000346:	9f99                	subw	a5,a5,a4
    80000348:	07f00713          	li	a4,127
    8000034c:	fcf763e3          	bltu	a4,a5,80000312 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000350:	47b5                	li	a5,13
    80000352:	0cf48763          	beq	s1,a5,80000420 <consoleintr+0x14a>
      consputc(c);
    80000356:	8526                	mv	a0,s1
    80000358:	00000097          	auipc	ra,0x0
    8000035c:	f3c080e7          	jalr	-196(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000360:	00011797          	auipc	a5,0x11
    80000364:	4d078793          	addi	a5,a5,1232 # 80011830 <cons>
    80000368:	0a07a703          	lw	a4,160(a5)
    8000036c:	0017069b          	addiw	a3,a4,1
    80000370:	0006861b          	sext.w	a2,a3
    80000374:	0ad7a023          	sw	a3,160(a5)
    80000378:	07f77713          	andi	a4,a4,127
    8000037c:	97ba                	add	a5,a5,a4
    8000037e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000382:	47a9                	li	a5,10
    80000384:	0cf48563          	beq	s1,a5,8000044e <consoleintr+0x178>
    80000388:	4791                	li	a5,4
    8000038a:	0cf48263          	beq	s1,a5,8000044e <consoleintr+0x178>
    8000038e:	00011797          	auipc	a5,0x11
    80000392:	53a7a783          	lw	a5,1338(a5) # 800118c8 <cons+0x98>
    80000396:	0807879b          	addiw	a5,a5,128
    8000039a:	f6f61ce3          	bne	a2,a5,80000312 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000039e:	863e                	mv	a2,a5
    800003a0:	a07d                	j	8000044e <consoleintr+0x178>
    while(cons.e != cons.w &&
    800003a2:	00011717          	auipc	a4,0x11
    800003a6:	48e70713          	addi	a4,a4,1166 # 80011830 <cons>
    800003aa:	0a072783          	lw	a5,160(a4)
    800003ae:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	00011497          	auipc	s1,0x11
    800003b6:	47e48493          	addi	s1,s1,1150 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ba:	4929                	li	s2,10
    800003bc:	f4f70be3          	beq	a4,a5,80000312 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003c0:	37fd                	addiw	a5,a5,-1
    800003c2:	07f7f713          	andi	a4,a5,127
    800003c6:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c8:	01874703          	lbu	a4,24(a4)
    800003cc:	f52703e3          	beq	a4,s2,80000312 <consoleintr+0x3c>
      cons.e--;
    800003d0:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	00000097          	auipc	ra,0x0
    800003dc:	ebc080e7          	jalr	-324(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003e0:	0a04a783          	lw	a5,160(s1)
    800003e4:	09c4a703          	lw	a4,156(s1)
    800003e8:	fcf71ce3          	bne	a4,a5,800003c0 <consoleintr+0xea>
    800003ec:	b71d                	j	80000312 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003ee:	00011717          	auipc	a4,0x11
    800003f2:	44270713          	addi	a4,a4,1090 # 80011830 <cons>
    800003f6:	0a072783          	lw	a5,160(a4)
    800003fa:	09c72703          	lw	a4,156(a4)
    800003fe:	f0f70ae3          	beq	a4,a5,80000312 <consoleintr+0x3c>
      cons.e--;
    80000402:	37fd                	addiw	a5,a5,-1
    80000404:	00011717          	auipc	a4,0x11
    80000408:	4cf72623          	sw	a5,1228(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    8000040c:	10000513          	li	a0,256
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e84080e7          	jalr	-380(ra) # 80000294 <consputc>
    80000418:	bded                	j	80000312 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000041a:	ee048ce3          	beqz	s1,80000312 <consoleintr+0x3c>
    8000041e:	bf21                	j	80000336 <consoleintr+0x60>
      consputc(c);
    80000420:	4529                	li	a0,10
    80000422:	00000097          	auipc	ra,0x0
    80000426:	e72080e7          	jalr	-398(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000042a:	00011797          	auipc	a5,0x11
    8000042e:	40678793          	addi	a5,a5,1030 # 80011830 <cons>
    80000432:	0a07a703          	lw	a4,160(a5)
    80000436:	0017069b          	addiw	a3,a4,1
    8000043a:	0006861b          	sext.w	a2,a3
    8000043e:	0ad7a023          	sw	a3,160(a5)
    80000442:	07f77713          	andi	a4,a4,127
    80000446:	97ba                	add	a5,a5,a4
    80000448:	4729                	li	a4,10
    8000044a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000044e:	00011797          	auipc	a5,0x11
    80000452:	46c7af23          	sw	a2,1150(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000456:	00011517          	auipc	a0,0x11
    8000045a:	47250513          	addi	a0,a0,1138 # 800118c8 <cons+0x98>
    8000045e:	00002097          	auipc	ra,0x2
    80000462:	156080e7          	jalr	342(ra) # 800025b4 <wakeup>
    80000466:	b575                	j	80000312 <consoleintr+0x3c>

0000000080000468 <consoleinit>:

void
consoleinit(void)
{
    80000468:	1141                	addi	sp,sp,-16
    8000046a:	e406                	sd	ra,8(sp)
    8000046c:	e022                	sd	s0,0(sp)
    8000046e:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000470:	00008597          	auipc	a1,0x8
    80000474:	b9058593          	addi	a1,a1,-1136 # 80008000 <etext>
    80000478:	00011517          	auipc	a0,0x11
    8000047c:	3b850513          	addi	a0,a0,952 # 80011830 <cons>
    80000480:	00000097          	auipc	ra,0x0
    80000484:	70e080e7          	jalr	1806(ra) # 80000b8e <initlock>

  uartinit();
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	330080e7          	jalr	816(ra) # 800007b8 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000490:	00021797          	auipc	a5,0x21
    80000494:	72078793          	addi	a5,a5,1824 # 80021bb0 <devsw>
    80000498:	00000717          	auipc	a4,0x0
    8000049c:	ce470713          	addi	a4,a4,-796 # 8000017c <consoleread>
    800004a0:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004a2:	00000717          	auipc	a4,0x0
    800004a6:	c5870713          	addi	a4,a4,-936 # 800000fa <consolewrite>
    800004aa:	ef98                	sd	a4,24(a5)
}
    800004ac:	60a2                	ld	ra,8(sp)
    800004ae:	6402                	ld	s0,0(sp)
    800004b0:	0141                	addi	sp,sp,16
    800004b2:	8082                	ret

00000000800004b4 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004b4:	7179                	addi	sp,sp,-48
    800004b6:	f406                	sd	ra,40(sp)
    800004b8:	f022                	sd	s0,32(sp)
    800004ba:	ec26                	sd	s1,24(sp)
    800004bc:	e84a                	sd	s2,16(sp)
    800004be:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c0:	c219                	beqz	a2,800004c6 <printint+0x12>
    800004c2:	08054663          	bltz	a0,8000054e <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c6:	2501                	sext.w	a0,a0
    800004c8:	4881                	li	a7,0
    800004ca:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004ce:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d0:	2581                	sext.w	a1,a1
    800004d2:	00008617          	auipc	a2,0x8
    800004d6:	b5e60613          	addi	a2,a2,-1186 # 80008030 <digits>
    800004da:	883a                	mv	a6,a4
    800004dc:	2705                	addiw	a4,a4,1
    800004de:	02b577bb          	remuw	a5,a0,a1
    800004e2:	1782                	slli	a5,a5,0x20
    800004e4:	9381                	srli	a5,a5,0x20
    800004e6:	97b2                	add	a5,a5,a2
    800004e8:	0007c783          	lbu	a5,0(a5)
    800004ec:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f0:	0005079b          	sext.w	a5,a0
    800004f4:	02b5553b          	divuw	a0,a0,a1
    800004f8:	0685                	addi	a3,a3,1
    800004fa:	feb7f0e3          	bgeu	a5,a1,800004da <printint+0x26>

  if(sign)
    800004fe:	00088b63          	beqz	a7,80000514 <printint+0x60>
    buf[i++] = '-';
    80000502:	fe040793          	addi	a5,s0,-32
    80000506:	973e                	add	a4,a4,a5
    80000508:	02d00793          	li	a5,45
    8000050c:	fef70823          	sb	a5,-16(a4)
    80000510:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000514:	02e05763          	blez	a4,80000542 <printint+0x8e>
    80000518:	fd040793          	addi	a5,s0,-48
    8000051c:	00e784b3          	add	s1,a5,a4
    80000520:	fff78913          	addi	s2,a5,-1
    80000524:	993a                	add	s2,s2,a4
    80000526:	377d                	addiw	a4,a4,-1
    80000528:	1702                	slli	a4,a4,0x20
    8000052a:	9301                	srli	a4,a4,0x20
    8000052c:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000530:	fff4c503          	lbu	a0,-1(s1)
    80000534:	00000097          	auipc	ra,0x0
    80000538:	d60080e7          	jalr	-672(ra) # 80000294 <consputc>
  while(--i >= 0)
    8000053c:	14fd                	addi	s1,s1,-1
    8000053e:	ff2499e3          	bne	s1,s2,80000530 <printint+0x7c>
}
    80000542:	70a2                	ld	ra,40(sp)
    80000544:	7402                	ld	s0,32(sp)
    80000546:	64e2                	ld	s1,24(sp)
    80000548:	6942                	ld	s2,16(sp)
    8000054a:	6145                	addi	sp,sp,48
    8000054c:	8082                	ret
    x = -xx;
    8000054e:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000552:	4885                	li	a7,1
    x = -xx;
    80000554:	bf9d                	j	800004ca <printint+0x16>

0000000080000556 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000556:	1101                	addi	sp,sp,-32
    80000558:	ec06                	sd	ra,24(sp)
    8000055a:	e822                	sd	s0,16(sp)
    8000055c:	e426                	sd	s1,8(sp)
    8000055e:	1000                	addi	s0,sp,32
    80000560:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000562:	00011797          	auipc	a5,0x11
    80000566:	3807a723          	sw	zero,910(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000056a:	00008517          	auipc	a0,0x8
    8000056e:	a9e50513          	addi	a0,a0,-1378 # 80008008 <etext+0x8>
    80000572:	00000097          	auipc	ra,0x0
    80000576:	02e080e7          	jalr	46(ra) # 800005a0 <printf>
  printf(s);
    8000057a:	8526                	mv	a0,s1
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	024080e7          	jalr	36(ra) # 800005a0 <printf>
  printf("\n");
    80000584:	00008517          	auipc	a0,0x8
    80000588:	b3450513          	addi	a0,a0,-1228 # 800080b8 <digits+0x88>
    8000058c:	00000097          	auipc	ra,0x0
    80000590:	014080e7          	jalr	20(ra) # 800005a0 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000594:	4785                	li	a5,1
    80000596:	00009717          	auipc	a4,0x9
    8000059a:	a6f72523          	sw	a5,-1430(a4) # 80009000 <panicked>
  for(;;)
    8000059e:	a001                	j	8000059e <panic+0x48>

00000000800005a0 <printf>:
{
    800005a0:	7131                	addi	sp,sp,-192
    800005a2:	fc86                	sd	ra,120(sp)
    800005a4:	f8a2                	sd	s0,112(sp)
    800005a6:	f4a6                	sd	s1,104(sp)
    800005a8:	f0ca                	sd	s2,96(sp)
    800005aa:	ecce                	sd	s3,88(sp)
    800005ac:	e8d2                	sd	s4,80(sp)
    800005ae:	e4d6                	sd	s5,72(sp)
    800005b0:	e0da                	sd	s6,64(sp)
    800005b2:	fc5e                	sd	s7,56(sp)
    800005b4:	f862                	sd	s8,48(sp)
    800005b6:	f466                	sd	s9,40(sp)
    800005b8:	f06a                	sd	s10,32(sp)
    800005ba:	ec6e                	sd	s11,24(sp)
    800005bc:	0100                	addi	s0,sp,128
    800005be:	8a2a                	mv	s4,a0
    800005c0:	e40c                	sd	a1,8(s0)
    800005c2:	e810                	sd	a2,16(s0)
    800005c4:	ec14                	sd	a3,24(s0)
    800005c6:	f018                	sd	a4,32(s0)
    800005c8:	f41c                	sd	a5,40(s0)
    800005ca:	03043823          	sd	a6,48(s0)
    800005ce:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005d2:	00011d97          	auipc	s11,0x11
    800005d6:	31edad83          	lw	s11,798(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005da:	020d9b63          	bnez	s11,80000610 <printf+0x70>
  if (fmt == 0)
    800005de:	040a0263          	beqz	s4,80000622 <printf+0x82>
  va_start(ap, fmt);
    800005e2:	00840793          	addi	a5,s0,8
    800005e6:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005ea:	000a4503          	lbu	a0,0(s4)
    800005ee:	16050263          	beqz	a0,80000752 <printf+0x1b2>
    800005f2:	4481                	li	s1,0
    if(c != '%'){
    800005f4:	02500a93          	li	s5,37
    switch(c){
    800005f8:	07000b13          	li	s6,112
  consputc('x');
    800005fc:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005fe:	00008b97          	auipc	s7,0x8
    80000602:	a32b8b93          	addi	s7,s7,-1486 # 80008030 <digits>
    switch(c){
    80000606:	07300c93          	li	s9,115
    8000060a:	06400c13          	li	s8,100
    8000060e:	a82d                	j	80000648 <printf+0xa8>
    acquire(&pr.lock);
    80000610:	00011517          	auipc	a0,0x11
    80000614:	2c850513          	addi	a0,a0,712 # 800118d8 <pr>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	606080e7          	jalr	1542(ra) # 80000c1e <acquire>
    80000620:	bf7d                	j	800005de <printf+0x3e>
    panic("null fmt");
    80000622:	00008517          	auipc	a0,0x8
    80000626:	9f650513          	addi	a0,a0,-1546 # 80008018 <etext+0x18>
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	f2c080e7          	jalr	-212(ra) # 80000556 <panic>
      consputc(c);
    80000632:	00000097          	auipc	ra,0x0
    80000636:	c62080e7          	jalr	-926(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c503          	lbu	a0,0(a5)
    80000644:	10050763          	beqz	a0,80000752 <printf+0x1b2>
    if(c != '%'){
    80000648:	ff5515e3          	bne	a0,s5,80000632 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000064c:	2485                	addiw	s1,s1,1
    8000064e:	009a07b3          	add	a5,s4,s1
    80000652:	0007c783          	lbu	a5,0(a5)
    80000656:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000065a:	cfe5                	beqz	a5,80000752 <printf+0x1b2>
    switch(c){
    8000065c:	05678a63          	beq	a5,s6,800006b0 <printf+0x110>
    80000660:	02fb7663          	bgeu	s6,a5,8000068c <printf+0xec>
    80000664:	09978963          	beq	a5,s9,800006f6 <printf+0x156>
    80000668:	07800713          	li	a4,120
    8000066c:	0ce79863          	bne	a5,a4,8000073c <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000670:	f8843783          	ld	a5,-120(s0)
    80000674:	00878713          	addi	a4,a5,8
    80000678:	f8e43423          	sd	a4,-120(s0)
    8000067c:	4605                	li	a2,1
    8000067e:	85ea                	mv	a1,s10
    80000680:	4388                	lw	a0,0(a5)
    80000682:	00000097          	auipc	ra,0x0
    80000686:	e32080e7          	jalr	-462(ra) # 800004b4 <printint>
      break;
    8000068a:	bf45                	j	8000063a <printf+0x9a>
    switch(c){
    8000068c:	0b578263          	beq	a5,s5,80000730 <printf+0x190>
    80000690:	0b879663          	bne	a5,s8,8000073c <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	4605                	li	a2,1
    800006a2:	45a9                	li	a1,10
    800006a4:	4388                	lw	a0,0(a5)
    800006a6:	00000097          	auipc	ra,0x0
    800006aa:	e0e080e7          	jalr	-498(ra) # 800004b4 <printint>
      break;
    800006ae:	b771                	j	8000063a <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006b0:	f8843783          	ld	a5,-120(s0)
    800006b4:	00878713          	addi	a4,a5,8
    800006b8:	f8e43423          	sd	a4,-120(s0)
    800006bc:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006c0:	03000513          	li	a0,48
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	bd0080e7          	jalr	-1072(ra) # 80000294 <consputc>
  consputc('x');
    800006cc:	07800513          	li	a0,120
    800006d0:	00000097          	auipc	ra,0x0
    800006d4:	bc4080e7          	jalr	-1084(ra) # 80000294 <consputc>
    800006d8:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006da:	03c9d793          	srli	a5,s3,0x3c
    800006de:	97de                	add	a5,a5,s7
    800006e0:	0007c503          	lbu	a0,0(a5)
    800006e4:	00000097          	auipc	ra,0x0
    800006e8:	bb0080e7          	jalr	-1104(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ec:	0992                	slli	s3,s3,0x4
    800006ee:	397d                	addiw	s2,s2,-1
    800006f0:	fe0915e3          	bnez	s2,800006da <printf+0x13a>
    800006f4:	b799                	j	8000063a <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f6:	f8843783          	ld	a5,-120(s0)
    800006fa:	00878713          	addi	a4,a5,8
    800006fe:	f8e43423          	sd	a4,-120(s0)
    80000702:	0007b903          	ld	s2,0(a5)
    80000706:	00090e63          	beqz	s2,80000722 <printf+0x182>
      for(; *s; s++)
    8000070a:	00094503          	lbu	a0,0(s2)
    8000070e:	d515                	beqz	a0,8000063a <printf+0x9a>
        consputc(*s);
    80000710:	00000097          	auipc	ra,0x0
    80000714:	b84080e7          	jalr	-1148(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000718:	0905                	addi	s2,s2,1
    8000071a:	00094503          	lbu	a0,0(s2)
    8000071e:	f96d                	bnez	a0,80000710 <printf+0x170>
    80000720:	bf29                	j	8000063a <printf+0x9a>
        s = "(null)";
    80000722:	00008917          	auipc	s2,0x8
    80000726:	8ee90913          	addi	s2,s2,-1810 # 80008010 <etext+0x10>
      for(; *s; s++)
    8000072a:	02800513          	li	a0,40
    8000072e:	b7cd                	j	80000710 <printf+0x170>
      consputc('%');
    80000730:	8556                	mv	a0,s5
    80000732:	00000097          	auipc	ra,0x0
    80000736:	b62080e7          	jalr	-1182(ra) # 80000294 <consputc>
      break;
    8000073a:	b701                	j	8000063a <printf+0x9a>
      consputc('%');
    8000073c:	8556                	mv	a0,s5
    8000073e:	00000097          	auipc	ra,0x0
    80000742:	b56080e7          	jalr	-1194(ra) # 80000294 <consputc>
      consputc(c);
    80000746:	854a                	mv	a0,s2
    80000748:	00000097          	auipc	ra,0x0
    8000074c:	b4c080e7          	jalr	-1204(ra) # 80000294 <consputc>
      break;
    80000750:	b5ed                	j	8000063a <printf+0x9a>
  if(locking)
    80000752:	020d9163          	bnez	s11,80000774 <printf+0x1d4>
}
    80000756:	70e6                	ld	ra,120(sp)
    80000758:	7446                	ld	s0,112(sp)
    8000075a:	74a6                	ld	s1,104(sp)
    8000075c:	7906                	ld	s2,96(sp)
    8000075e:	69e6                	ld	s3,88(sp)
    80000760:	6a46                	ld	s4,80(sp)
    80000762:	6aa6                	ld	s5,72(sp)
    80000764:	6b06                	ld	s6,64(sp)
    80000766:	7be2                	ld	s7,56(sp)
    80000768:	7c42                	ld	s8,48(sp)
    8000076a:	7ca2                	ld	s9,40(sp)
    8000076c:	7d02                	ld	s10,32(sp)
    8000076e:	6de2                	ld	s11,24(sp)
    80000770:	6129                	addi	sp,sp,192
    80000772:	8082                	ret
    release(&pr.lock);
    80000774:	00011517          	auipc	a0,0x11
    80000778:	16450513          	addi	a0,a0,356 # 800118d8 <pr>
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	556080e7          	jalr	1366(ra) # 80000cd2 <release>
}
    80000784:	bfc9                	j	80000756 <printf+0x1b6>

0000000080000786 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000786:	1101                	addi	sp,sp,-32
    80000788:	ec06                	sd	ra,24(sp)
    8000078a:	e822                	sd	s0,16(sp)
    8000078c:	e426                	sd	s1,8(sp)
    8000078e:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000790:	00011497          	auipc	s1,0x11
    80000794:	14848493          	addi	s1,s1,328 # 800118d8 <pr>
    80000798:	00008597          	auipc	a1,0x8
    8000079c:	89058593          	addi	a1,a1,-1904 # 80008028 <etext+0x28>
    800007a0:	8526                	mv	a0,s1
    800007a2:	00000097          	auipc	ra,0x0
    800007a6:	3ec080e7          	jalr	1004(ra) # 80000b8e <initlock>
  pr.locking = 1;
    800007aa:	4785                	li	a5,1
    800007ac:	cc9c                	sw	a5,24(s1)
}
    800007ae:	60e2                	ld	ra,24(sp)
    800007b0:	6442                	ld	s0,16(sp)
    800007b2:	64a2                	ld	s1,8(sp)
    800007b4:	6105                	addi	sp,sp,32
    800007b6:	8082                	ret

00000000800007b8 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b8:	1141                	addi	sp,sp,-16
    800007ba:	e406                	sd	ra,8(sp)
    800007bc:	e022                	sd	s0,0(sp)
    800007be:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007c0:	100007b7          	lui	a5,0x10000
    800007c4:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c8:	f8000713          	li	a4,-128
    800007cc:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007d0:	470d                	li	a4,3
    800007d2:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d6:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007da:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007de:	469d                	li	a3,7
    800007e0:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007e4:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e8:	00008597          	auipc	a1,0x8
    800007ec:	86058593          	addi	a1,a1,-1952 # 80008048 <digits+0x18>
    800007f0:	00011517          	auipc	a0,0x11
    800007f4:	10850513          	addi	a0,a0,264 # 800118f8 <uart_tx_lock>
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	396080e7          	jalr	918(ra) # 80000b8e <initlock>
}
    80000800:	60a2                	ld	ra,8(sp)
    80000802:	6402                	ld	s0,0(sp)
    80000804:	0141                	addi	sp,sp,16
    80000806:	8082                	ret

0000000080000808 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000808:	1101                	addi	sp,sp,-32
    8000080a:	ec06                	sd	ra,24(sp)
    8000080c:	e822                	sd	s0,16(sp)
    8000080e:	e426                	sd	s1,8(sp)
    80000810:	1000                	addi	s0,sp,32
    80000812:	84aa                	mv	s1,a0
  push_off();
    80000814:	00000097          	auipc	ra,0x0
    80000818:	3be080e7          	jalr	958(ra) # 80000bd2 <push_off>

  if(panicked){
    8000081c:	00008797          	auipc	a5,0x8
    80000820:	7e47a783          	lw	a5,2020(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000824:	10000737          	lui	a4,0x10000
  if(panicked){
    80000828:	c391                	beqz	a5,8000082c <uartputc_sync+0x24>
    for(;;)
    8000082a:	a001                	j	8000082a <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000082c:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000830:	0ff7f793          	andi	a5,a5,255
    80000834:	0207f793          	andi	a5,a5,32
    80000838:	dbf5                	beqz	a5,8000082c <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000083a:	0ff4f793          	andi	a5,s1,255
    8000083e:	10000737          	lui	a4,0x10000
    80000842:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	42c080e7          	jalr	1068(ra) # 80000c72 <pop_off>
}
    8000084e:	60e2                	ld	ra,24(sp)
    80000850:	6442                	ld	s0,16(sp)
    80000852:	64a2                	ld	s1,8(sp)
    80000854:	6105                	addi	sp,sp,32
    80000856:	8082                	ret

0000000080000858 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000858:	00008797          	auipc	a5,0x8
    8000085c:	7ac7a783          	lw	a5,1964(a5) # 80009004 <uart_tx_r>
    80000860:	00008717          	auipc	a4,0x8
    80000864:	7a872703          	lw	a4,1960(a4) # 80009008 <uart_tx_w>
    80000868:	08f70263          	beq	a4,a5,800008ec <uartstart+0x94>
{
    8000086c:	7139                	addi	sp,sp,-64
    8000086e:	fc06                	sd	ra,56(sp)
    80000870:	f822                	sd	s0,48(sp)
    80000872:	f426                	sd	s1,40(sp)
    80000874:	f04a                	sd	s2,32(sp)
    80000876:	ec4e                	sd	s3,24(sp)
    80000878:	e852                	sd	s4,16(sp)
    8000087a:	e456                	sd	s5,8(sp)
    8000087c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000882:	00011a17          	auipc	s4,0x11
    80000886:	076a0a13          	addi	s4,s4,118 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000088a:	00008497          	auipc	s1,0x8
    8000088e:	77a48493          	addi	s1,s1,1914 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000892:	00008997          	auipc	s3,0x8
    80000896:	77698993          	addi	s3,s3,1910 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000089a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000089e:	0ff77713          	andi	a4,a4,255
    800008a2:	02077713          	andi	a4,a4,32
    800008a6:	cb15                	beqz	a4,800008da <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a8:	00fa0733          	add	a4,s4,a5
    800008ac:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008b0:	2785                	addiw	a5,a5,1
    800008b2:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b6:	01b7571b          	srliw	a4,a4,0x1b
    800008ba:	9fb9                	addw	a5,a5,a4
    800008bc:	8bfd                	andi	a5,a5,31
    800008be:	9f99                	subw	a5,a5,a4
    800008c0:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008c2:	8526                	mv	a0,s1
    800008c4:	00002097          	auipc	ra,0x2
    800008c8:	cf0080e7          	jalr	-784(ra) # 800025b4 <wakeup>
    
    WriteReg(THR, c);
    800008cc:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008d0:	409c                	lw	a5,0(s1)
    800008d2:	0009a703          	lw	a4,0(s3)
    800008d6:	fcf712e3          	bne	a4,a5,8000089a <uartstart+0x42>
  }
}
    800008da:	70e2                	ld	ra,56(sp)
    800008dc:	7442                	ld	s0,48(sp)
    800008de:	74a2                	ld	s1,40(sp)
    800008e0:	7902                	ld	s2,32(sp)
    800008e2:	69e2                	ld	s3,24(sp)
    800008e4:	6a42                	ld	s4,16(sp)
    800008e6:	6aa2                	ld	s5,8(sp)
    800008e8:	6121                	addi	sp,sp,64
    800008ea:	8082                	ret
    800008ec:	8082                	ret

00000000800008ee <uartputc>:
{
    800008ee:	7179                	addi	sp,sp,-48
    800008f0:	f406                	sd	ra,40(sp)
    800008f2:	f022                	sd	s0,32(sp)
    800008f4:	ec26                	sd	s1,24(sp)
    800008f6:	e84a                	sd	s2,16(sp)
    800008f8:	e44e                	sd	s3,8(sp)
    800008fa:	e052                	sd	s4,0(sp)
    800008fc:	1800                	addi	s0,sp,48
    800008fe:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000900:	00011517          	auipc	a0,0x11
    80000904:	ff850513          	addi	a0,a0,-8 # 800118f8 <uart_tx_lock>
    80000908:	00000097          	auipc	ra,0x0
    8000090c:	316080e7          	jalr	790(ra) # 80000c1e <acquire>
  if(panicked){
    80000910:	00008797          	auipc	a5,0x8
    80000914:	6f07a783          	lw	a5,1776(a5) # 80009000 <panicked>
    80000918:	c391                	beqz	a5,8000091c <uartputc+0x2e>
    for(;;)
    8000091a:	a001                	j	8000091a <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000091c:	00008717          	auipc	a4,0x8
    80000920:	6ec72703          	lw	a4,1772(a4) # 80009008 <uart_tx_w>
    80000924:	0017079b          	addiw	a5,a4,1
    80000928:	41f7d69b          	sraiw	a3,a5,0x1f
    8000092c:	01b6d69b          	srliw	a3,a3,0x1b
    80000930:	9fb5                	addw	a5,a5,a3
    80000932:	8bfd                	andi	a5,a5,31
    80000934:	9f95                	subw	a5,a5,a3
    80000936:	00008697          	auipc	a3,0x8
    8000093a:	6ce6a683          	lw	a3,1742(a3) # 80009004 <uart_tx_r>
    8000093e:	04f69263          	bne	a3,a5,80000982 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000942:	00011a17          	auipc	s4,0x11
    80000946:	fb6a0a13          	addi	s4,s4,-74 # 800118f8 <uart_tx_lock>
    8000094a:	00008497          	auipc	s1,0x8
    8000094e:	6ba48493          	addi	s1,s1,1722 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000952:	00008917          	auipc	s2,0x8
    80000956:	6b690913          	addi	s2,s2,1718 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000095a:	85d2                	mv	a1,s4
    8000095c:	8526                	mv	a0,s1
    8000095e:	00002097          	auipc	ra,0x2
    80000962:	ad0080e7          	jalr	-1328(ra) # 8000242e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000966:	00092703          	lw	a4,0(s2)
    8000096a:	0017079b          	addiw	a5,a4,1
    8000096e:	41f7d69b          	sraiw	a3,a5,0x1f
    80000972:	01b6d69b          	srliw	a3,a3,0x1b
    80000976:	9fb5                	addw	a5,a5,a3
    80000978:	8bfd                	andi	a5,a5,31
    8000097a:	9f95                	subw	a5,a5,a3
    8000097c:	4094                	lw	a3,0(s1)
    8000097e:	fcf68ee3          	beq	a3,a5,8000095a <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000982:	00011497          	auipc	s1,0x11
    80000986:	f7648493          	addi	s1,s1,-138 # 800118f8 <uart_tx_lock>
    8000098a:	9726                	add	a4,a4,s1
    8000098c:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000990:	00008717          	auipc	a4,0x8
    80000994:	66f72c23          	sw	a5,1656(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000998:	00000097          	auipc	ra,0x0
    8000099c:	ec0080e7          	jalr	-320(ra) # 80000858 <uartstart>
      release(&uart_tx_lock);
    800009a0:	8526                	mv	a0,s1
    800009a2:	00000097          	auipc	ra,0x0
    800009a6:	330080e7          	jalr	816(ra) # 80000cd2 <release>
}
    800009aa:	70a2                	ld	ra,40(sp)
    800009ac:	7402                	ld	s0,32(sp)
    800009ae:	64e2                	ld	s1,24(sp)
    800009b0:	6942                	ld	s2,16(sp)
    800009b2:	69a2                	ld	s3,8(sp)
    800009b4:	6a02                	ld	s4,0(sp)
    800009b6:	6145                	addi	sp,sp,48
    800009b8:	8082                	ret

00000000800009ba <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ba:	1141                	addi	sp,sp,-16
    800009bc:	e422                	sd	s0,8(sp)
    800009be:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009c0:	100007b7          	lui	a5,0x10000
    800009c4:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c8:	8b85                	andi	a5,a5,1
    800009ca:	cb91                	beqz	a5,800009de <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009cc:	100007b7          	lui	a5,0x10000
    800009d0:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009d4:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d8:	6422                	ld	s0,8(sp)
    800009da:	0141                	addi	sp,sp,16
    800009dc:	8082                	ret
    return -1;
    800009de:	557d                	li	a0,-1
    800009e0:	bfe5                	j	800009d8 <uartgetc+0x1e>

00000000800009e2 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009e2:	1101                	addi	sp,sp,-32
    800009e4:	ec06                	sd	ra,24(sp)
    800009e6:	e822                	sd	s0,16(sp)
    800009e8:	e426                	sd	s1,8(sp)
    800009ea:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ee:	00000097          	auipc	ra,0x0
    800009f2:	fcc080e7          	jalr	-52(ra) # 800009ba <uartgetc>
    if(c == -1)
    800009f6:	00950763          	beq	a0,s1,80000a04 <uartintr+0x22>
      break;
    consoleintr(c);
    800009fa:	00000097          	auipc	ra,0x0
    800009fe:	8dc080e7          	jalr	-1828(ra) # 800002d6 <consoleintr>
  while(1){
    80000a02:	b7f5                	j	800009ee <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a04:	00011497          	auipc	s1,0x11
    80000a08:	ef448493          	addi	s1,s1,-268 # 800118f8 <uart_tx_lock>
    80000a0c:	8526                	mv	a0,s1
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	210080e7          	jalr	528(ra) # 80000c1e <acquire>
  uartstart();
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	e42080e7          	jalr	-446(ra) # 80000858 <uartstart>
  release(&uart_tx_lock);
    80000a1e:	8526                	mv	a0,s1
    80000a20:	00000097          	auipc	ra,0x0
    80000a24:	2b2080e7          	jalr	690(ra) # 80000cd2 <release>
}
    80000a28:	60e2                	ld	ra,24(sp)
    80000a2a:	6442                	ld	s0,16(sp)
    80000a2c:	64a2                	ld	s1,8(sp)
    80000a2e:	6105                	addi	sp,sp,32
    80000a30:	8082                	ret

0000000080000a32 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a32:	1101                	addi	sp,sp,-32
    80000a34:	ec06                	sd	ra,24(sp)
    80000a36:	e822                	sd	s0,16(sp)
    80000a38:	e426                	sd	s1,8(sp)
    80000a3a:	e04a                	sd	s2,0(sp)
    80000a3c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	ebb9                	bnez	a5,80000a98 <kfree+0x66>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	00026797          	auipc	a5,0x26
    80000a4a:	5da78793          	addi	a5,a5,1498 # 80027020 <end>
    80000a4e:	04f56563          	bltu	a0,a5,80000a98 <kfree+0x66>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	04f57163          	bgeu	a0,a5,80000a98 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	2bc080e7          	jalr	700(ra) # 80000d1a <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a66:	00011917          	auipc	s2,0x11
    80000a6a:	eca90913          	addi	s2,s2,-310 # 80011930 <kmem>
    80000a6e:	854a                	mv	a0,s2
    80000a70:	00000097          	auipc	ra,0x0
    80000a74:	1ae080e7          	jalr	430(ra) # 80000c1e <acquire>
  r->next = kmem.freelist;
    80000a78:	01893783          	ld	a5,24(s2)
    80000a7c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a7e:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a82:	854a                	mv	a0,s2
    80000a84:	00000097          	auipc	ra,0x0
    80000a88:	24e080e7          	jalr	590(ra) # 80000cd2 <release>
}
    80000a8c:	60e2                	ld	ra,24(sp)
    80000a8e:	6442                	ld	s0,16(sp)
    80000a90:	64a2                	ld	s1,8(sp)
    80000a92:	6902                	ld	s2,0(sp)
    80000a94:	6105                	addi	sp,sp,32
    80000a96:	8082                	ret
    panic("kfree");
    80000a98:	00007517          	auipc	a0,0x7
    80000a9c:	5b850513          	addi	a0,a0,1464 # 80008050 <digits+0x20>
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	ab6080e7          	jalr	-1354(ra) # 80000556 <panic>

0000000080000aa8 <freerange>:
{
    80000aa8:	7179                	addi	sp,sp,-48
    80000aaa:	f406                	sd	ra,40(sp)
    80000aac:	f022                	sd	s0,32(sp)
    80000aae:	ec26                	sd	s1,24(sp)
    80000ab0:	e84a                	sd	s2,16(sp)
    80000ab2:	e44e                	sd	s3,8(sp)
    80000ab4:	e052                	sd	s4,0(sp)
    80000ab6:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ab8:	6785                	lui	a5,0x1
    80000aba:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000abe:	94aa                	add	s1,s1,a0
    80000ac0:	757d                	lui	a0,0xfffff
    80000ac2:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac4:	94be                	add	s1,s1,a5
    80000ac6:	0095ee63          	bltu	a1,s1,80000ae2 <freerange+0x3a>
    80000aca:	892e                	mv	s2,a1
    kfree(p);
    80000acc:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	6985                	lui	s3,0x1
    kfree(p);
    80000ad0:	01448533          	add	a0,s1,s4
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	f5e080e7          	jalr	-162(ra) # 80000a32 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000adc:	94ce                	add	s1,s1,s3
    80000ade:	fe9979e3          	bgeu	s2,s1,80000ad0 <freerange+0x28>
}
    80000ae2:	70a2                	ld	ra,40(sp)
    80000ae4:	7402                	ld	s0,32(sp)
    80000ae6:	64e2                	ld	s1,24(sp)
    80000ae8:	6942                	ld	s2,16(sp)
    80000aea:	69a2                	ld	s3,8(sp)
    80000aec:	6a02                	ld	s4,0(sp)
    80000aee:	6145                	addi	sp,sp,48
    80000af0:	8082                	ret

0000000080000af2 <kinit>:
{
    80000af2:	1141                	addi	sp,sp,-16
    80000af4:	e406                	sd	ra,8(sp)
    80000af6:	e022                	sd	s0,0(sp)
    80000af8:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000afa:	00007597          	auipc	a1,0x7
    80000afe:	55e58593          	addi	a1,a1,1374 # 80008058 <digits+0x28>
    80000b02:	00011517          	auipc	a0,0x11
    80000b06:	e2e50513          	addi	a0,a0,-466 # 80011930 <kmem>
    80000b0a:	00000097          	auipc	ra,0x0
    80000b0e:	084080e7          	jalr	132(ra) # 80000b8e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b12:	45c5                	li	a1,17
    80000b14:	05ee                	slli	a1,a1,0x1b
    80000b16:	00026517          	auipc	a0,0x26
    80000b1a:	50a50513          	addi	a0,a0,1290 # 80027020 <end>
    80000b1e:	00000097          	auipc	ra,0x0
    80000b22:	f8a080e7          	jalr	-118(ra) # 80000aa8 <freerange>
}
    80000b26:	60a2                	ld	ra,8(sp)
    80000b28:	6402                	ld	s0,0(sp)
    80000b2a:	0141                	addi	sp,sp,16
    80000b2c:	8082                	ret

0000000080000b2e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b2e:	1101                	addi	sp,sp,-32
    80000b30:	ec06                	sd	ra,24(sp)
    80000b32:	e822                	sd	s0,16(sp)
    80000b34:	e426                	sd	s1,8(sp)
    80000b36:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b38:	00011497          	auipc	s1,0x11
    80000b3c:	df848493          	addi	s1,s1,-520 # 80011930 <kmem>
    80000b40:	8526                	mv	a0,s1
    80000b42:	00000097          	auipc	ra,0x0
    80000b46:	0dc080e7          	jalr	220(ra) # 80000c1e <acquire>
  r = kmem.freelist;
    80000b4a:	6c84                	ld	s1,24(s1)
  if(r)
    80000b4c:	c885                	beqz	s1,80000b7c <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b4e:	609c                	ld	a5,0(s1)
    80000b50:	00011517          	auipc	a0,0x11
    80000b54:	de050513          	addi	a0,a0,-544 # 80011930 <kmem>
    80000b58:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	178080e7          	jalr	376(ra) # 80000cd2 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b62:	6605                	lui	a2,0x1
    80000b64:	4595                	li	a1,5
    80000b66:	8526                	mv	a0,s1
    80000b68:	00000097          	auipc	ra,0x0
    80000b6c:	1b2080e7          	jalr	434(ra) # 80000d1a <memset>
  return (void*)r;
}
    80000b70:	8526                	mv	a0,s1
    80000b72:	60e2                	ld	ra,24(sp)
    80000b74:	6442                	ld	s0,16(sp)
    80000b76:	64a2                	ld	s1,8(sp)
    80000b78:	6105                	addi	sp,sp,32
    80000b7a:	8082                	ret
  release(&kmem.lock);
    80000b7c:	00011517          	auipc	a0,0x11
    80000b80:	db450513          	addi	a0,a0,-588 # 80011930 <kmem>
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	14e080e7          	jalr	334(ra) # 80000cd2 <release>
  if(r)
    80000b8c:	b7d5                	j	80000b70 <kalloc+0x42>

0000000080000b8e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b8e:	1141                	addi	sp,sp,-16
    80000b90:	e422                	sd	s0,8(sp)
    80000b92:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b94:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b96:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9a:	00053823          	sd	zero,16(a0)
}
    80000b9e:	6422                	ld	s0,8(sp)
    80000ba0:	0141                	addi	sp,sp,16
    80000ba2:	8082                	ret

0000000080000ba4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba4:	411c                	lw	a5,0(a0)
    80000ba6:	e399                	bnez	a5,80000bac <holding+0x8>
    80000ba8:	4501                	li	a0,0
  return r;
}
    80000baa:	8082                	ret
{
    80000bac:	1101                	addi	sp,sp,-32
    80000bae:	ec06                	sd	ra,24(sp)
    80000bb0:	e822                	sd	s0,16(sp)
    80000bb2:	e426                	sd	s1,8(sp)
    80000bb4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb6:	6904                	ld	s1,16(a0)
    80000bb8:	00001097          	auipc	ra,0x1
    80000bbc:	f32080e7          	jalr	-206(ra) # 80001aea <mycpu>
    80000bc0:	40a48533          	sub	a0,s1,a0
    80000bc4:	00153513          	seqz	a0,a0
}
    80000bc8:	60e2                	ld	ra,24(sp)
    80000bca:	6442                	ld	s0,16(sp)
    80000bcc:	64a2                	ld	s1,8(sp)
    80000bce:	6105                	addi	sp,sp,32
    80000bd0:	8082                	ret

0000000080000bd2 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd2:	1101                	addi	sp,sp,-32
    80000bd4:	ec06                	sd	ra,24(sp)
    80000bd6:	e822                	sd	s0,16(sp)
    80000bd8:	e426                	sd	s1,8(sp)
    80000bda:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bdc:	100024f3          	csrr	s1,sstatus
    80000be0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be6:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bea:	00001097          	auipc	ra,0x1
    80000bee:	f00080e7          	jalr	-256(ra) # 80001aea <mycpu>
    80000bf2:	5d3c                	lw	a5,120(a0)
    80000bf4:	cf89                	beqz	a5,80000c0e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf6:	00001097          	auipc	ra,0x1
    80000bfa:	ef4080e7          	jalr	-268(ra) # 80001aea <mycpu>
    80000bfe:	5d3c                	lw	a5,120(a0)
    80000c00:	2785                	addiw	a5,a5,1
    80000c02:	dd3c                	sw	a5,120(a0)
}
    80000c04:	60e2                	ld	ra,24(sp)
    80000c06:	6442                	ld	s0,16(sp)
    80000c08:	64a2                	ld	s1,8(sp)
    80000c0a:	6105                	addi	sp,sp,32
    80000c0c:	8082                	ret
    mycpu()->intena = old;
    80000c0e:	00001097          	auipc	ra,0x1
    80000c12:	edc080e7          	jalr	-292(ra) # 80001aea <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c16:	8085                	srli	s1,s1,0x1
    80000c18:	8885                	andi	s1,s1,1
    80000c1a:	dd64                	sw	s1,124(a0)
    80000c1c:	bfe9                	j	80000bf6 <push_off+0x24>

0000000080000c1e <acquire>:
{
    80000c1e:	1101                	addi	sp,sp,-32
    80000c20:	ec06                	sd	ra,24(sp)
    80000c22:	e822                	sd	s0,16(sp)
    80000c24:	e426                	sd	s1,8(sp)
    80000c26:	1000                	addi	s0,sp,32
    80000c28:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	fa8080e7          	jalr	-88(ra) # 80000bd2 <push_off>
  if(holding(lk))
    80000c32:	8526                	mv	a0,s1
    80000c34:	00000097          	auipc	ra,0x0
    80000c38:	f70080e7          	jalr	-144(ra) # 80000ba4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3c:	4705                	li	a4,1
  if(holding(lk))
    80000c3e:	e115                	bnez	a0,80000c62 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c40:	87ba                	mv	a5,a4
    80000c42:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c46:	2781                	sext.w	a5,a5
    80000c48:	ffe5                	bnez	a5,80000c40 <acquire+0x22>
  __sync_synchronize();
    80000c4a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c4e:	00001097          	auipc	ra,0x1
    80000c52:	e9c080e7          	jalr	-356(ra) # 80001aea <mycpu>
    80000c56:	e888                	sd	a0,16(s1)
}
    80000c58:	60e2                	ld	ra,24(sp)
    80000c5a:	6442                	ld	s0,16(sp)
    80000c5c:	64a2                	ld	s1,8(sp)
    80000c5e:	6105                	addi	sp,sp,32
    80000c60:	8082                	ret
    panic("acquire");
    80000c62:	00007517          	auipc	a0,0x7
    80000c66:	3fe50513          	addi	a0,a0,1022 # 80008060 <digits+0x30>
    80000c6a:	00000097          	auipc	ra,0x0
    80000c6e:	8ec080e7          	jalr	-1812(ra) # 80000556 <panic>

0000000080000c72 <pop_off>:

void
pop_off(void)
{
    80000c72:	1141                	addi	sp,sp,-16
    80000c74:	e406                	sd	ra,8(sp)
    80000c76:	e022                	sd	s0,0(sp)
    80000c78:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7a:	00001097          	auipc	ra,0x1
    80000c7e:	e70080e7          	jalr	-400(ra) # 80001aea <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c82:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c86:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c88:	e78d                	bnez	a5,80000cb2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8a:	5d3c                	lw	a5,120(a0)
    80000c8c:	02f05b63          	blez	a5,80000cc2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c90:	37fd                	addiw	a5,a5,-1
    80000c92:	0007871b          	sext.w	a4,a5
    80000c96:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c98:	eb09                	bnez	a4,80000caa <pop_off+0x38>
    80000c9a:	5d7c                	lw	a5,124(a0)
    80000c9c:	c799                	beqz	a5,80000caa <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000caa:	60a2                	ld	ra,8(sp)
    80000cac:	6402                	ld	s0,0(sp)
    80000cae:	0141                	addi	sp,sp,16
    80000cb0:	8082                	ret
    panic("pop_off - interruptible");
    80000cb2:	00007517          	auipc	a0,0x7
    80000cb6:	3b650513          	addi	a0,a0,950 # 80008068 <digits+0x38>
    80000cba:	00000097          	auipc	ra,0x0
    80000cbe:	89c080e7          	jalr	-1892(ra) # 80000556 <panic>
    panic("pop_off");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3be50513          	addi	a0,a0,958 # 80008080 <digits+0x50>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	88c080e7          	jalr	-1908(ra) # 80000556 <panic>

0000000080000cd2 <release>:
{
    80000cd2:	1101                	addi	sp,sp,-32
    80000cd4:	ec06                	sd	ra,24(sp)
    80000cd6:	e822                	sd	s0,16(sp)
    80000cd8:	e426                	sd	s1,8(sp)
    80000cda:	1000                	addi	s0,sp,32
    80000cdc:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	ec6080e7          	jalr	-314(ra) # 80000ba4 <holding>
    80000ce6:	c115                	beqz	a0,80000d0a <release+0x38>
  lk->cpu = 0;
    80000ce8:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cec:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf0:	0f50000f          	fence	iorw,ow
    80000cf4:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	f7a080e7          	jalr	-134(ra) # 80000c72 <pop_off>
}
    80000d00:	60e2                	ld	ra,24(sp)
    80000d02:	6442                	ld	s0,16(sp)
    80000d04:	64a2                	ld	s1,8(sp)
    80000d06:	6105                	addi	sp,sp,32
    80000d08:	8082                	ret
    panic("release");
    80000d0a:	00007517          	auipc	a0,0x7
    80000d0e:	37e50513          	addi	a0,a0,894 # 80008088 <digits+0x58>
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	844080e7          	jalr	-1980(ra) # 80000556 <panic>

0000000080000d1a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1a:	1141                	addi	sp,sp,-16
    80000d1c:	e422                	sd	s0,8(sp)
    80000d1e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d20:	ce09                	beqz	a2,80000d3a <memset+0x20>
    80000d22:	87aa                	mv	a5,a0
    80000d24:	fff6071b          	addiw	a4,a2,-1
    80000d28:	1702                	slli	a4,a4,0x20
    80000d2a:	9301                	srli	a4,a4,0x20
    80000d2c:	0705                	addi	a4,a4,1
    80000d2e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d30:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d34:	0785                	addi	a5,a5,1
    80000d36:	fee79de3          	bne	a5,a4,80000d30 <memset+0x16>
  }
  return dst;
}
    80000d3a:	6422                	ld	s0,8(sp)
    80000d3c:	0141                	addi	sp,sp,16
    80000d3e:	8082                	ret

0000000080000d40 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d46:	ca05                	beqz	a2,80000d76 <memcmp+0x36>
    80000d48:	fff6069b          	addiw	a3,a2,-1
    80000d4c:	1682                	slli	a3,a3,0x20
    80000d4e:	9281                	srli	a3,a3,0x20
    80000d50:	0685                	addi	a3,a3,1
    80000d52:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d54:	00054783          	lbu	a5,0(a0)
    80000d58:	0005c703          	lbu	a4,0(a1)
    80000d5c:	00e79863          	bne	a5,a4,80000d6c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d60:	0505                	addi	a0,a0,1
    80000d62:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d64:	fed518e3          	bne	a0,a3,80000d54 <memcmp+0x14>
  }

  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	a019                	j	80000d70 <memcmp+0x30>
      return *s1 - *s2;
    80000d6c:	40e7853b          	subw	a0,a5,a4
}
    80000d70:	6422                	ld	s0,8(sp)
    80000d72:	0141                	addi	sp,sp,16
    80000d74:	8082                	ret
  return 0;
    80000d76:	4501                	li	a0,0
    80000d78:	bfe5                	j	80000d70 <memcmp+0x30>

0000000080000d7a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d7a:	1141                	addi	sp,sp,-16
    80000d7c:	e422                	sd	s0,8(sp)
    80000d7e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d80:	00a5f963          	bgeu	a1,a0,80000d92 <memmove+0x18>
    80000d84:	02061713          	slli	a4,a2,0x20
    80000d88:	9301                	srli	a4,a4,0x20
    80000d8a:	00e587b3          	add	a5,a1,a4
    80000d8e:	02f56563          	bltu	a0,a5,80000db8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d92:	fff6069b          	addiw	a3,a2,-1
    80000d96:	ce11                	beqz	a2,80000db2 <memmove+0x38>
    80000d98:	1682                	slli	a3,a3,0x20
    80000d9a:	9281                	srli	a3,a3,0x20
    80000d9c:	0685                	addi	a3,a3,1
    80000d9e:	96ae                	add	a3,a3,a1
    80000da0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000da2:	0585                	addi	a1,a1,1
    80000da4:	0785                	addi	a5,a5,1
    80000da6:	fff5c703          	lbu	a4,-1(a1)
    80000daa:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dae:	fed59ae3          	bne	a1,a3,80000da2 <memmove+0x28>

  return dst;
}
    80000db2:	6422                	ld	s0,8(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret
    d += n;
    80000db8:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dba:	fff6069b          	addiw	a3,a2,-1
    80000dbe:	da75                	beqz	a2,80000db2 <memmove+0x38>
    80000dc0:	02069613          	slli	a2,a3,0x20
    80000dc4:	9201                	srli	a2,a2,0x20
    80000dc6:	fff64613          	not	a2,a2
    80000dca:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dcc:	17fd                	addi	a5,a5,-1
    80000dce:	177d                	addi	a4,a4,-1
    80000dd0:	0007c683          	lbu	a3,0(a5)
    80000dd4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dd8:	fec79ae3          	bne	a5,a2,80000dcc <memmove+0x52>
    80000ddc:	bfd9                	j	80000db2 <memmove+0x38>

0000000080000dde <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e406                	sd	ra,8(sp)
    80000de2:	e022                	sd	s0,0(sp)
    80000de4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	f94080e7          	jalr	-108(ra) # 80000d7a <memmove>
}
    80000dee:	60a2                	ld	ra,8(sp)
    80000df0:	6402                	ld	s0,0(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret

0000000080000df6 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e422                	sd	s0,8(sp)
    80000dfa:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dfc:	ce11                	beqz	a2,80000e18 <strncmp+0x22>
    80000dfe:	00054783          	lbu	a5,0(a0)
    80000e02:	cf89                	beqz	a5,80000e1c <strncmp+0x26>
    80000e04:	0005c703          	lbu	a4,0(a1)
    80000e08:	00f71a63          	bne	a4,a5,80000e1c <strncmp+0x26>
    n--, p++, q++;
    80000e0c:	367d                	addiw	a2,a2,-1
    80000e0e:	0505                	addi	a0,a0,1
    80000e10:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e12:	f675                	bnez	a2,80000dfe <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e14:	4501                	li	a0,0
    80000e16:	a809                	j	80000e28 <strncmp+0x32>
    80000e18:	4501                	li	a0,0
    80000e1a:	a039                	j	80000e28 <strncmp+0x32>
  if(n == 0)
    80000e1c:	ca09                	beqz	a2,80000e2e <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e1e:	00054503          	lbu	a0,0(a0)
    80000e22:	0005c783          	lbu	a5,0(a1)
    80000e26:	9d1d                	subw	a0,a0,a5
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret
    return 0;
    80000e2e:	4501                	li	a0,0
    80000e30:	bfe5                	j	80000e28 <strncmp+0x32>

0000000080000e32 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e38:	872a                	mv	a4,a0
    80000e3a:	8832                	mv	a6,a2
    80000e3c:	367d                	addiw	a2,a2,-1
    80000e3e:	01005963          	blez	a6,80000e50 <strncpy+0x1e>
    80000e42:	0705                	addi	a4,a4,1
    80000e44:	0005c783          	lbu	a5,0(a1)
    80000e48:	fef70fa3          	sb	a5,-1(a4)
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	f7f5                	bnez	a5,80000e3a <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e50:	00c05d63          	blez	a2,80000e6a <strncpy+0x38>
    80000e54:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e56:	0685                	addi	a3,a3,1
    80000e58:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e5c:	fff6c793          	not	a5,a3
    80000e60:	9fb9                	addw	a5,a5,a4
    80000e62:	010787bb          	addw	a5,a5,a6
    80000e66:	fef048e3          	bgtz	a5,80000e56 <strncpy+0x24>
  return os;
}
    80000e6a:	6422                	ld	s0,8(sp)
    80000e6c:	0141                	addi	sp,sp,16
    80000e6e:	8082                	ret

0000000080000e70 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e70:	1141                	addi	sp,sp,-16
    80000e72:	e422                	sd	s0,8(sp)
    80000e74:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e76:	02c05363          	blez	a2,80000e9c <safestrcpy+0x2c>
    80000e7a:	fff6069b          	addiw	a3,a2,-1
    80000e7e:	1682                	slli	a3,a3,0x20
    80000e80:	9281                	srli	a3,a3,0x20
    80000e82:	96ae                	add	a3,a3,a1
    80000e84:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e86:	00d58963          	beq	a1,a3,80000e98 <safestrcpy+0x28>
    80000e8a:	0585                	addi	a1,a1,1
    80000e8c:	0785                	addi	a5,a5,1
    80000e8e:	fff5c703          	lbu	a4,-1(a1)
    80000e92:	fee78fa3          	sb	a4,-1(a5)
    80000e96:	fb65                	bnez	a4,80000e86 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e98:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e9c:	6422                	ld	s0,8(sp)
    80000e9e:	0141                	addi	sp,sp,16
    80000ea0:	8082                	ret

0000000080000ea2 <strlen>:

int
strlen(const char *s)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e422                	sd	s0,8(sp)
    80000ea6:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ea8:	00054783          	lbu	a5,0(a0)
    80000eac:	cf91                	beqz	a5,80000ec8 <strlen+0x26>
    80000eae:	0505                	addi	a0,a0,1
    80000eb0:	87aa                	mv	a5,a0
    80000eb2:	4685                	li	a3,1
    80000eb4:	9e89                	subw	a3,a3,a0
    80000eb6:	00f6853b          	addw	a0,a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	fb7d                	bnez	a4,80000eb6 <strlen+0x14>
    ;
  return n;
}
    80000ec2:	6422                	ld	s0,8(sp)
    80000ec4:	0141                	addi	sp,sp,16
    80000ec6:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ec8:	4501                	li	a0,0
    80000eca:	bfe5                	j	80000ec2 <strlen+0x20>

0000000080000ecc <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ecc:	1141                	addi	sp,sp,-16
    80000ece:	e406                	sd	ra,8(sp)
    80000ed0:	e022                	sd	s0,0(sp)
    80000ed2:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ed4:	00001097          	auipc	ra,0x1
    80000ed8:	c06080e7          	jalr	-1018(ra) # 80001ada <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000edc:	00008717          	auipc	a4,0x8
    80000ee0:	13070713          	addi	a4,a4,304 # 8000900c <started>
  if(cpuid() == 0){
    80000ee4:	c139                	beqz	a0,80000f2a <main+0x5e>
    while(started == 0)
    80000ee6:	431c                	lw	a5,0(a4)
    80000ee8:	2781                	sext.w	a5,a5
    80000eea:	dff5                	beqz	a5,80000ee6 <main+0x1a>
      ;
    __sync_synchronize();
    80000eec:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ef0:	00001097          	auipc	ra,0x1
    80000ef4:	bea080e7          	jalr	-1046(ra) # 80001ada <cpuid>
    80000ef8:	85aa                	mv	a1,a0
    80000efa:	00007517          	auipc	a0,0x7
    80000efe:	1ae50513          	addi	a0,a0,430 # 800080a8 <digits+0x78>
    80000f02:	fffff097          	auipc	ra,0xfffff
    80000f06:	69e080e7          	jalr	1694(ra) # 800005a0 <printf>
    kvminithart();    // turn on paging
    80000f0a:	00000097          	auipc	ra,0x0
    80000f0e:	232080e7          	jalr	562(ra) # 8000113c <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f12:	00002097          	auipc	ra,0x2
    80000f16:	96a080e7          	jalr	-1686(ra) # 8000287c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f1a:	00005097          	auipc	ra,0x5
    80000f1e:	f66080e7          	jalr	-154(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	214080e7          	jalr	532(ra) # 80002136 <scheduler>
    consoleinit();
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	53e080e7          	jalr	1342(ra) # 80000468 <consoleinit>
    statsinit();
    80000f32:	00005097          	auipc	ra,0x5
    80000f36:	71c080e7          	jalr	1820(ra) # 8000664e <statsinit>
    printfinit();
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	84c080e7          	jalr	-1972(ra) # 80000786 <printfinit>
    printf("\n");
    80000f42:	00007517          	auipc	a0,0x7
    80000f46:	17650513          	addi	a0,a0,374 # 800080b8 <digits+0x88>
    80000f4a:	fffff097          	auipc	ra,0xfffff
    80000f4e:	656080e7          	jalr	1622(ra) # 800005a0 <printf>
    printf("xv6 kernel is booting\n");
    80000f52:	00007517          	auipc	a0,0x7
    80000f56:	13e50513          	addi	a0,a0,318 # 80008090 <digits+0x60>
    80000f5a:	fffff097          	auipc	ra,0xfffff
    80000f5e:	646080e7          	jalr	1606(ra) # 800005a0 <printf>
    printf("\n");
    80000f62:	00007517          	auipc	a0,0x7
    80000f66:	15650513          	addi	a0,a0,342 # 800080b8 <digits+0x88>
    80000f6a:	fffff097          	auipc	ra,0xfffff
    80000f6e:	636080e7          	jalr	1590(ra) # 800005a0 <printf>
    kinit();         // physical page allocator
    80000f72:	00000097          	auipc	ra,0x0
    80000f76:	b80080e7          	jalr	-1152(ra) # 80000af2 <kinit>
    kvminit();       // create kernel page table
    80000f7a:	00000097          	auipc	ra,0x0
    80000f7e:	4cc080e7          	jalr	1228(ra) # 80001446 <kvminit>
    kvminithart();   // turn on paging
    80000f82:	00000097          	auipc	ra,0x0
    80000f86:	1ba080e7          	jalr	442(ra) # 8000113c <kvminithart>
    procinit();      // process table
    80000f8a:	00001097          	auipc	ra,0x1
    80000f8e:	ae8080e7          	jalr	-1304(ra) # 80001a72 <procinit>
    trapinit();      // trap vectors
    80000f92:	00002097          	auipc	ra,0x2
    80000f96:	8c2080e7          	jalr	-1854(ra) # 80002854 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f9a:	00002097          	auipc	ra,0x2
    80000f9e:	8e2080e7          	jalr	-1822(ra) # 8000287c <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa2:	00005097          	auipc	ra,0x5
    80000fa6:	ec8080e7          	jalr	-312(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000faa:	00005097          	auipc	ra,0x5
    80000fae:	ed6080e7          	jalr	-298(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000fb2:	00002097          	auipc	ra,0x2
    80000fb6:	00c080e7          	jalr	12(ra) # 80002fbe <binit>
    iinit();         // inode cache
    80000fba:	00002097          	auipc	ra,0x2
    80000fbe:	69c080e7          	jalr	1692(ra) # 80003656 <iinit>
    fileinit();      // file table
    80000fc2:	00003097          	auipc	ra,0x3
    80000fc6:	636080e7          	jalr	1590(ra) # 800045f8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fca:	00005097          	auipc	ra,0x5
    80000fce:	fbe080e7          	jalr	-66(ra) # 80005f88 <virtio_disk_init>
    userinit();      // first user process
    80000fd2:	00001097          	auipc	ra,0x1
    80000fd6:	e70080e7          	jalr	-400(ra) # 80001e42 <userinit>
    __sync_synchronize();
    80000fda:	0ff0000f          	fence
    started = 1;
    80000fde:	4785                	li	a5,1
    80000fe0:	00008717          	auipc	a4,0x8
    80000fe4:	02f72623          	sw	a5,44(a4) # 8000900c <started>
    80000fe8:	bf2d                	j	80000f22 <main+0x56>

0000000080000fea <pgtblprint>:
  }

  return newsz;
}

int pgtblprint(pagetable_t pagetable, int depth) {
    80000fea:	7159                	addi	sp,sp,-112
    80000fec:	f486                	sd	ra,104(sp)
    80000fee:	f0a2                	sd	s0,96(sp)
    80000ff0:	eca6                	sd	s1,88(sp)
    80000ff2:	e8ca                	sd	s2,80(sp)
    80000ff4:	e4ce                	sd	s3,72(sp)
    80000ff6:	e0d2                	sd	s4,64(sp)
    80000ff8:	fc56                	sd	s5,56(sp)
    80000ffa:	f85a                	sd	s6,48(sp)
    80000ffc:	f45e                	sd	s7,40(sp)
    80000ffe:	f062                	sd	s8,32(sp)
    80001000:	ec66                	sd	s9,24(sp)
    80001002:	e86a                	sd	s10,16(sp)
    80001004:	e46e                	sd	s11,8(sp)
    80001006:	1880                	addi	s0,sp,112
    80001008:	8aae                	mv	s5,a1
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000100a:	89aa                	mv	s3,a0
    8000100c:	4901                	li	s2,0
    pte_t pte = pagetable[i];
    if(pte & PTE_V) { // 如果页表项有效
      // 按格式打印页表项
      printf("..");
    8000100e:	00007c97          	auipc	s9,0x7
    80001012:	0b2c8c93          	addi	s9,s9,178 # 800080c0 <digits+0x90>
      for(int j=0;j<depth;j++) {
        printf(" ..");
      }
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001016:	00007c17          	auipc	s8,0x7
    8000101a:	0bac0c13          	addi	s8,s8,186 # 800080d0 <digits+0xa0>

      // 如果该节点不是叶节点，递归打印其子节点。
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
        // this PTE points to a lower-level page table.
        uint64 child = PTE2PA(pte);
        pgtblprint((pagetable_t)child,depth+1);
    8000101e:	00158d9b          	addiw	s11,a1,1
      for(int j=0;j<depth;j++) {
    80001022:	4d01                	li	s10,0
        printf(" ..");
    80001024:	00007b17          	auipc	s6,0x7
    80001028:	0a4b0b13          	addi	s6,s6,164 # 800080c8 <digits+0x98>
  for(int i = 0; i < 512; i++){
    8000102c:	20000b93          	li	s7,512
    80001030:	a029                	j	8000103a <pgtblprint+0x50>
    80001032:	2905                	addiw	s2,s2,1
    80001034:	09a1                	addi	s3,s3,8
    80001036:	05790d63          	beq	s2,s7,80001090 <pgtblprint+0xa6>
    pte_t pte = pagetable[i];
    8000103a:	0009ba03          	ld	s4,0(s3) # 1000 <_entry-0x7ffff000>
    if(pte & PTE_V) { // 如果页表项有效
    8000103e:	001a7793          	andi	a5,s4,1
    80001042:	dbe5                	beqz	a5,80001032 <pgtblprint+0x48>
      printf("..");
    80001044:	8566                	mv	a0,s9
    80001046:	fffff097          	auipc	ra,0xfffff
    8000104a:	55a080e7          	jalr	1370(ra) # 800005a0 <printf>
      for(int j=0;j<depth;j++) {
    8000104e:	01505b63          	blez	s5,80001064 <pgtblprint+0x7a>
    80001052:	84ea                	mv	s1,s10
        printf(" ..");
    80001054:	855a                	mv	a0,s6
    80001056:	fffff097          	auipc	ra,0xfffff
    8000105a:	54a080e7          	jalr	1354(ra) # 800005a0 <printf>
      for(int j=0;j<depth;j++) {
    8000105e:	2485                	addiw	s1,s1,1
    80001060:	fe9a9ae3          	bne	s5,s1,80001054 <pgtblprint+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001064:	00aa5493          	srli	s1,s4,0xa
    80001068:	04b2                	slli	s1,s1,0xc
    8000106a:	86a6                	mv	a3,s1
    8000106c:	8652                	mv	a2,s4
    8000106e:	85ca                	mv	a1,s2
    80001070:	8562                	mv	a0,s8
    80001072:	fffff097          	auipc	ra,0xfffff
    80001076:	52e080e7          	jalr	1326(ra) # 800005a0 <printf>
      if((pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000107a:	00ea7a13          	andi	s4,s4,14
    8000107e:	fa0a1ae3          	bnez	s4,80001032 <pgtblprint+0x48>
        pgtblprint((pagetable_t)child,depth+1);
    80001082:	85ee                	mv	a1,s11
    80001084:	8526                	mv	a0,s1
    80001086:	00000097          	auipc	ra,0x0
    8000108a:	f64080e7          	jalr	-156(ra) # 80000fea <pgtblprint>
    8000108e:	b755                	j	80001032 <pgtblprint+0x48>
      }
    }
  }
  return 0;
}
    80001090:	4501                	li	a0,0
    80001092:	70a6                	ld	ra,104(sp)
    80001094:	7406                	ld	s0,96(sp)
    80001096:	64e6                	ld	s1,88(sp)
    80001098:	6946                	ld	s2,80(sp)
    8000109a:	69a6                	ld	s3,72(sp)
    8000109c:	6a06                	ld	s4,64(sp)
    8000109e:	7ae2                	ld	s5,56(sp)
    800010a0:	7b42                	ld	s6,48(sp)
    800010a2:	7ba2                	ld	s7,40(sp)
    800010a4:	7c02                	ld	s8,32(sp)
    800010a6:	6ce2                	ld	s9,24(sp)
    800010a8:	6d42                	ld	s10,16(sp)
    800010aa:	6da2                	ld	s11,8(sp)
    800010ac:	6165                	addi	sp,sp,112
    800010ae:	8082                	ret

00000000800010b0 <vmprint>:

int vmprint(pagetable_t pagetable) {
    800010b0:	1101                	addi	sp,sp,-32
    800010b2:	ec06                	sd	ra,24(sp)
    800010b4:	e822                	sd	s0,16(sp)
    800010b6:	e426                	sd	s1,8(sp)
    800010b8:	1000                	addi	s0,sp,32
    800010ba:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800010bc:	85aa                	mv	a1,a0
    800010be:	00007517          	auipc	a0,0x7
    800010c2:	02a50513          	addi	a0,a0,42 # 800080e8 <digits+0xb8>
    800010c6:	fffff097          	auipc	ra,0xfffff
    800010ca:	4da080e7          	jalr	1242(ra) # 800005a0 <printf>
  return pgtblprint(pagetable, 0);
    800010ce:	4581                	li	a1,0
    800010d0:	8526                	mv	a0,s1
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	f18080e7          	jalr	-232(ra) # 80000fea <pgtblprint>
}
    800010da:	60e2                	ld	ra,24(sp)
    800010dc:	6442                	ld	s0,16(sp)
    800010de:	64a2                	ld	s1,8(sp)
    800010e0:	6105                	addi	sp,sp,32
    800010e2:	8082                	ret

00000000800010e4 <kvm_free_kernelpgtbl>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
// 递归释放一个内核页表中的所有 mapping，但是不释放其指向的物理页
void kvm_free_kernelpgtbl(pagetable_t pagetable)
{
    800010e4:	7179                	addi	sp,sp,-48
    800010e6:	f406                	sd	ra,40(sp)
    800010e8:	f022                	sd	s0,32(sp)
    800010ea:	ec26                	sd	s1,24(sp)
    800010ec:	e84a                	sd	s2,16(sp)
    800010ee:	e44e                	sd	s3,8(sp)
    800010f0:	e052                	sd	s4,0(sp)
    800010f2:	1800                	addi	s0,sp,48
    800010f4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800010f6:	84aa                	mv	s1,a0
    800010f8:	6905                	lui	s2,0x1
    800010fa:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    uint64 child = PTE2PA(pte);
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){ // 如果该页表项指向更低一级的页表
    800010fc:	4985                	li	s3,1
    800010fe:	a821                	j	80001116 <kvm_free_kernelpgtbl+0x32>
    uint64 child = PTE2PA(pte);
    80001100:	8129                	srli	a0,a0,0xa
      // 递归释放低一级页表及其页表项
      kvm_free_kernelpgtbl((pagetable_t)child);
    80001102:	0532                	slli	a0,a0,0xc
    80001104:	00000097          	auipc	ra,0x0
    80001108:	fe0080e7          	jalr	-32(ra) # 800010e4 <kvm_free_kernelpgtbl>
      pagetable[i] = 0;
    8000110c:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001110:	04a1                	addi	s1,s1,8
    80001112:	01248863          	beq	s1,s2,80001122 <kvm_free_kernelpgtbl+0x3e>
    pte_t pte = pagetable[i];
    80001116:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){ // 如果该页表项指向更低一级的页表
    80001118:	00f57793          	andi	a5,a0,15
    8000111c:	ff379ae3          	bne	a5,s3,80001110 <kvm_free_kernelpgtbl+0x2c>
    80001120:	b7c5                	j	80001100 <kvm_free_kernelpgtbl+0x1c>
    }
  }
  kfree((void*)pagetable); // 释放当前级别页表所占用空间
    80001122:	8552                	mv	a0,s4
    80001124:	00000097          	auipc	ra,0x0
    80001128:	90e080e7          	jalr	-1778(ra) # 80000a32 <kfree>
}
    8000112c:	70a2                	ld	ra,40(sp)
    8000112e:	7402                	ld	s0,32(sp)
    80001130:	64e2                	ld	s1,24(sp)
    80001132:	6942                	ld	s2,16(sp)
    80001134:	69a2                	ld	s3,8(sp)
    80001136:	6a02                	ld	s4,0(sp)
    80001138:	6145                	addi	sp,sp,48
    8000113a:	8082                	ret

000000008000113c <kvminithart>:
  kvmmap(kernel_pagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
}

void
kvminithart()
{
    8000113c:	1141                	addi	sp,sp,-16
    8000113e:	e422                	sd	s0,8(sp)
    80001140:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001142:	00008797          	auipc	a5,0x8
    80001146:	ece7b783          	ld	a5,-306(a5) # 80009010 <kernel_pagetable>
    8000114a:	83b1                	srli	a5,a5,0xc
    8000114c:	577d                	li	a4,-1
    8000114e:	177e                	slli	a4,a4,0x3f
    80001150:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001152:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001156:	12000073          	sfence.vma
  sfence_vma();
}
    8000115a:	6422                	ld	s0,8(sp)
    8000115c:	0141                	addi	sp,sp,16
    8000115e:	8082                	ret

0000000080001160 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001160:	7139                	addi	sp,sp,-64
    80001162:	fc06                	sd	ra,56(sp)
    80001164:	f822                	sd	s0,48(sp)
    80001166:	f426                	sd	s1,40(sp)
    80001168:	f04a                	sd	s2,32(sp)
    8000116a:	ec4e                	sd	s3,24(sp)
    8000116c:	e852                	sd	s4,16(sp)
    8000116e:	e456                	sd	s5,8(sp)
    80001170:	e05a                	sd	s6,0(sp)
    80001172:	0080                	addi	s0,sp,64
    80001174:	84aa                	mv	s1,a0
    80001176:	89ae                	mv	s3,a1
    80001178:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000117a:	57fd                	li	a5,-1
    8000117c:	83e9                	srli	a5,a5,0x1a
    8000117e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001180:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001182:	04b7f263          	bgeu	a5,a1,800011c6 <walk+0x66>
    panic("walk");
    80001186:	00007517          	auipc	a0,0x7
    8000118a:	f7250513          	addi	a0,a0,-142 # 800080f8 <digits+0xc8>
    8000118e:	fffff097          	auipc	ra,0xfffff
    80001192:	3c8080e7          	jalr	968(ra) # 80000556 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001196:	060a8663          	beqz	s5,80001202 <walk+0xa2>
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	994080e7          	jalr	-1644(ra) # 80000b2e <kalloc>
    800011a2:	84aa                	mv	s1,a0
    800011a4:	c529                	beqz	a0,800011ee <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	b70080e7          	jalr	-1168(ra) # 80000d1a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011b2:	00c4d793          	srli	a5,s1,0xc
    800011b6:	07aa                	slli	a5,a5,0xa
    800011b8:	0017e793          	ori	a5,a5,1
    800011bc:	00f93023          	sd	a5,0(s2) # 1000 <_entry-0x7ffff000>
  for(int level = 2; level > 0; level--) {
    800011c0:	3a5d                	addiw	s4,s4,-9
    800011c2:	036a0063          	beq	s4,s6,800011e2 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011c6:	0149d933          	srl	s2,s3,s4
    800011ca:	1ff97913          	andi	s2,s2,511
    800011ce:	090e                	slli	s2,s2,0x3
    800011d0:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011d2:	00093483          	ld	s1,0(s2)
    800011d6:	0014f793          	andi	a5,s1,1
    800011da:	dfd5                	beqz	a5,80001196 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011dc:	80a9                	srli	s1,s1,0xa
    800011de:	04b2                	slli	s1,s1,0xc
    800011e0:	b7c5                	j	800011c0 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011e2:	00c9d513          	srli	a0,s3,0xc
    800011e6:	1ff57513          	andi	a0,a0,511
    800011ea:	050e                	slli	a0,a0,0x3
    800011ec:	9526                	add	a0,a0,s1
}
    800011ee:	70e2                	ld	ra,56(sp)
    800011f0:	7442                	ld	s0,48(sp)
    800011f2:	74a2                	ld	s1,40(sp)
    800011f4:	7902                	ld	s2,32(sp)
    800011f6:	69e2                	ld	s3,24(sp)
    800011f8:	6a42                	ld	s4,16(sp)
    800011fa:	6aa2                	ld	s5,8(sp)
    800011fc:	6b02                	ld	s6,0(sp)
    800011fe:	6121                	addi	sp,sp,64
    80001200:	8082                	ret
        return 0;
    80001202:	4501                	li	a0,0
    80001204:	b7ed                	j	800011ee <walk+0x8e>

0000000080001206 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001206:	57fd                	li	a5,-1
    80001208:	83e9                	srli	a5,a5,0x1a
    8000120a:	00b7f463          	bgeu	a5,a1,80001212 <walkaddr+0xc>
    return 0;
    8000120e:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001210:	8082                	ret
{
    80001212:	1141                	addi	sp,sp,-16
    80001214:	e406                	sd	ra,8(sp)
    80001216:	e022                	sd	s0,0(sp)
    80001218:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000121a:	4601                	li	a2,0
    8000121c:	00000097          	auipc	ra,0x0
    80001220:	f44080e7          	jalr	-188(ra) # 80001160 <walk>
  if(pte == 0)
    80001224:	c105                	beqz	a0,80001244 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001226:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001228:	0117f693          	andi	a3,a5,17
    8000122c:	4745                	li	a4,17
    return 0;
    8000122e:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001230:	00e68663          	beq	a3,a4,8000123c <walkaddr+0x36>
}
    80001234:	60a2                	ld	ra,8(sp)
    80001236:	6402                	ld	s0,0(sp)
    80001238:	0141                	addi	sp,sp,16
    8000123a:	8082                	ret
  pa = PTE2PA(*pte);
    8000123c:	00a7d513          	srli	a0,a5,0xa
    80001240:	0532                	slli	a0,a0,0xc
  return pa;
    80001242:	bfcd                	j	80001234 <walkaddr+0x2e>
    return 0;
    80001244:	4501                	li	a0,0
    80001246:	b7fd                	j	80001234 <walkaddr+0x2e>

0000000080001248 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(pagetable_t pgtbl, uint64 va)
{
    80001248:	1101                	addi	sp,sp,-32
    8000124a:	ec06                	sd	ra,24(sp)
    8000124c:	e822                	sd	s0,16(sp)
    8000124e:	e426                	sd	s1,8(sp)
    80001250:	1000                	addi	s0,sp,32
  uint64 off = va % PGSIZE;
    80001252:	03459793          	slli	a5,a1,0x34
    80001256:	0347d493          	srli	s1,a5,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(pgtbl, va, 0);
    8000125a:	4601                	li	a2,0
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f04080e7          	jalr	-252(ra) # 80001160 <walk>
  if(pte == 0)
    80001264:	cd09                	beqz	a0,8000127e <kvmpa+0x36>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001266:	6108                	ld	a0,0(a0)
    80001268:	00157793          	andi	a5,a0,1
    8000126c:	c38d                	beqz	a5,8000128e <kvmpa+0x46>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000126e:	8129                	srli	a0,a0,0xa
    80001270:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001272:	9526                	add	a0,a0,s1
    80001274:	60e2                	ld	ra,24(sp)
    80001276:	6442                	ld	s0,16(sp)
    80001278:	64a2                	ld	s1,8(sp)
    8000127a:	6105                	addi	sp,sp,32
    8000127c:	8082                	ret
    panic("kvmpa");
    8000127e:	00007517          	auipc	a0,0x7
    80001282:	e8250513          	addi	a0,a0,-382 # 80008100 <digits+0xd0>
    80001286:	fffff097          	auipc	ra,0xfffff
    8000128a:	2d0080e7          	jalr	720(ra) # 80000556 <panic>
    panic("kvmpa");
    8000128e:	00007517          	auipc	a0,0x7
    80001292:	e7250513          	addi	a0,a0,-398 # 80008100 <digits+0xd0>
    80001296:	fffff097          	auipc	ra,0xfffff
    8000129a:	2c0080e7          	jalr	704(ra) # 80000556 <panic>

000000008000129e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000129e:	715d                	addi	sp,sp,-80
    800012a0:	e486                	sd	ra,72(sp)
    800012a2:	e0a2                	sd	s0,64(sp)
    800012a4:	fc26                	sd	s1,56(sp)
    800012a6:	f84a                	sd	s2,48(sp)
    800012a8:	f44e                	sd	s3,40(sp)
    800012aa:	f052                	sd	s4,32(sp)
    800012ac:	ec56                	sd	s5,24(sp)
    800012ae:	e85a                	sd	s6,16(sp)
    800012b0:	e45e                	sd	s7,8(sp)
    800012b2:	0880                	addi	s0,sp,80
    800012b4:	8aaa                	mv	s5,a0
    800012b6:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800012b8:	777d                	lui	a4,0xfffff
    800012ba:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800012be:	167d                	addi	a2,a2,-1
    800012c0:	00b609b3          	add	s3,a2,a1
    800012c4:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012c8:	893e                	mv	s2,a5
    800012ca:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012ce:	6b85                	lui	s7,0x1
    800012d0:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012d4:	4605                	li	a2,1
    800012d6:	85ca                	mv	a1,s2
    800012d8:	8556                	mv	a0,s5
    800012da:	00000097          	auipc	ra,0x0
    800012de:	e86080e7          	jalr	-378(ra) # 80001160 <walk>
    800012e2:	c51d                	beqz	a0,80001310 <mappages+0x72>
    if(*pte & PTE_V)
    800012e4:	611c                	ld	a5,0(a0)
    800012e6:	8b85                	andi	a5,a5,1
    800012e8:	ef81                	bnez	a5,80001300 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012ea:	80b1                	srli	s1,s1,0xc
    800012ec:	04aa                	slli	s1,s1,0xa
    800012ee:	0164e4b3          	or	s1,s1,s6
    800012f2:	0014e493          	ori	s1,s1,1
    800012f6:	e104                	sd	s1,0(a0)
    if(a == last)
    800012f8:	03390863          	beq	s2,s3,80001328 <mappages+0x8a>
    a += PGSIZE;
    800012fc:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012fe:	bfc9                	j	800012d0 <mappages+0x32>
      panic("remap");
    80001300:	00007517          	auipc	a0,0x7
    80001304:	e0850513          	addi	a0,a0,-504 # 80008108 <digits+0xd8>
    80001308:	fffff097          	auipc	ra,0xfffff
    8000130c:	24e080e7          	jalr	590(ra) # 80000556 <panic>
      return -1;
    80001310:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001312:	60a6                	ld	ra,72(sp)
    80001314:	6406                	ld	s0,64(sp)
    80001316:	74e2                	ld	s1,56(sp)
    80001318:	7942                	ld	s2,48(sp)
    8000131a:	79a2                	ld	s3,40(sp)
    8000131c:	7a02                	ld	s4,32(sp)
    8000131e:	6ae2                	ld	s5,24(sp)
    80001320:	6b42                	ld	s6,16(sp)
    80001322:	6ba2                	ld	s7,8(sp)
    80001324:	6161                	addi	sp,sp,80
    80001326:	8082                	ret
  return 0;
    80001328:	4501                	li	a0,0
    8000132a:	b7e5                	j	80001312 <mappages+0x74>

000000008000132c <kvmmap>:
{
    8000132c:	1141                	addi	sp,sp,-16
    8000132e:	e406                	sd	ra,8(sp)
    80001330:	e022                	sd	s0,0(sp)
    80001332:	0800                	addi	s0,sp,16
    80001334:	87b6                	mv	a5,a3
  if(mappages(pgtbl, va, sz, pa, perm) != 0)
    80001336:	86b2                	mv	a3,a2
    80001338:	863e                	mv	a2,a5
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f64080e7          	jalr	-156(ra) # 8000129e <mappages>
    80001342:	e509                	bnez	a0,8000134c <kvmmap+0x20>
}
    80001344:	60a2                	ld	ra,8(sp)
    80001346:	6402                	ld	s0,0(sp)
    80001348:	0141                	addi	sp,sp,16
    8000134a:	8082                	ret
    panic("kvmmap");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	dc450513          	addi	a0,a0,-572 # 80008110 <digits+0xe0>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	202080e7          	jalr	514(ra) # 80000556 <panic>

000000008000135c <kvm_map_pagetable>:
void kvm_map_pagetable(pagetable_t pgtbl) {
    8000135c:	1101                	addi	sp,sp,-32
    8000135e:	ec06                	sd	ra,24(sp)
    80001360:	e822                	sd	s0,16(sp)
    80001362:	e426                	sd	s1,8(sp)
    80001364:	e04a                	sd	s2,0(sp)
    80001366:	1000                	addi	s0,sp,32
    80001368:	84aa                	mv	s1,a0
  kvmmap(pgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000136a:	4719                	li	a4,6
    8000136c:	6685                	lui	a3,0x1
    8000136e:	10000637          	lui	a2,0x10000
    80001372:	100005b7          	lui	a1,0x10000
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	fb6080e7          	jalr	-74(ra) # 8000132c <kvmmap>
  kvmmap(pgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000137e:	4719                	li	a4,6
    80001380:	6685                	lui	a3,0x1
    80001382:	10001637          	lui	a2,0x10001
    80001386:	100015b7          	lui	a1,0x10001
    8000138a:	8526                	mv	a0,s1
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	fa0080e7          	jalr	-96(ra) # 8000132c <kvmmap>
  kvmmap(pgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001394:	4719                	li	a4,6
    80001396:	004006b7          	lui	a3,0x400
    8000139a:	0c000637          	lui	a2,0xc000
    8000139e:	0c0005b7          	lui	a1,0xc000
    800013a2:	8526                	mv	a0,s1
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	f88080e7          	jalr	-120(ra) # 8000132c <kvmmap>
  kvmmap(pgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013ac:	00007917          	auipc	s2,0x7
    800013b0:	c5490913          	addi	s2,s2,-940 # 80008000 <etext>
    800013b4:	4729                	li	a4,10
    800013b6:	80007697          	auipc	a3,0x80007
    800013ba:	c4a68693          	addi	a3,a3,-950 # 8000 <_entry-0x7fff8000>
    800013be:	4605                	li	a2,1
    800013c0:	067e                	slli	a2,a2,0x1f
    800013c2:	85b2                	mv	a1,a2
    800013c4:	8526                	mv	a0,s1
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	f66080e7          	jalr	-154(ra) # 8000132c <kvmmap>
  kvmmap(pgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013ce:	4719                	li	a4,6
    800013d0:	46c5                	li	a3,17
    800013d2:	06ee                	slli	a3,a3,0x1b
    800013d4:	412686b3          	sub	a3,a3,s2
    800013d8:	864a                	mv	a2,s2
    800013da:	85ca                	mv	a1,s2
    800013dc:	8526                	mv	a0,s1
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	f4e080e7          	jalr	-178(ra) # 8000132c <kvmmap>
  kvmmap(pgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013e6:	4729                	li	a4,10
    800013e8:	6685                	lui	a3,0x1
    800013ea:	00006617          	auipc	a2,0x6
    800013ee:	c1660613          	addi	a2,a2,-1002 # 80007000 <_trampoline>
    800013f2:	040005b7          	lui	a1,0x4000
    800013f6:	15fd                	addi	a1,a1,-1
    800013f8:	05b2                	slli	a1,a1,0xc
    800013fa:	8526                	mv	a0,s1
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	f30080e7          	jalr	-208(ra) # 8000132c <kvmmap>
}
    80001404:	60e2                	ld	ra,24(sp)
    80001406:	6442                	ld	s0,16(sp)
    80001408:	64a2                	ld	s1,8(sp)
    8000140a:	6902                	ld	s2,0(sp)
    8000140c:	6105                	addi	sp,sp,32
    8000140e:	8082                	ret

0000000080001410 <kvminit_newpgtbl>:
{
    80001410:	1101                	addi	sp,sp,-32
    80001412:	ec06                	sd	ra,24(sp)
    80001414:	e822                	sd	s0,16(sp)
    80001416:	e426                	sd	s1,8(sp)
    80001418:	1000                	addi	s0,sp,32
  pagetable_t pgtbl = (pagetable_t) kalloc();
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	714080e7          	jalr	1812(ra) # 80000b2e <kalloc>
    80001422:	84aa                	mv	s1,a0
  memset(pgtbl, 0, PGSIZE);
    80001424:	6605                	lui	a2,0x1
    80001426:	4581                	li	a1,0
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	8f2080e7          	jalr	-1806(ra) # 80000d1a <memset>
  kvm_map_pagetable(pgtbl);
    80001430:	8526                	mv	a0,s1
    80001432:	00000097          	auipc	ra,0x0
    80001436:	f2a080e7          	jalr	-214(ra) # 8000135c <kvm_map_pagetable>
}
    8000143a:	8526                	mv	a0,s1
    8000143c:	60e2                	ld	ra,24(sp)
    8000143e:	6442                	ld	s0,16(sp)
    80001440:	64a2                	ld	s1,8(sp)
    80001442:	6105                	addi	sp,sp,32
    80001444:	8082                	ret

0000000080001446 <kvminit>:
{
    80001446:	1141                	addi	sp,sp,-16
    80001448:	e406                	sd	ra,8(sp)
    8000144a:	e022                	sd	s0,0(sp)
    8000144c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvminit_newpgtbl(); // 仍然需要有全局的内核页表，用于内核 boot 过程，以及无进程在运行时使用。
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	fc2080e7          	jalr	-62(ra) # 80001410 <kvminit_newpgtbl>
    80001456:	00008797          	auipc	a5,0x8
    8000145a:	baa7bd23          	sd	a0,-1094(a5) # 80009010 <kernel_pagetable>
  kvmmap(kernel_pagetable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000145e:	4719                	li	a4,6
    80001460:	66c1                	lui	a3,0x10
    80001462:	02000637          	lui	a2,0x2000
    80001466:	020005b7          	lui	a1,0x2000
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	ec2080e7          	jalr	-318(ra) # 8000132c <kvmmap>
}
    80001472:	60a2                	ld	ra,8(sp)
    80001474:	6402                	ld	s0,0(sp)
    80001476:	0141                	addi	sp,sp,16
    80001478:	8082                	ret

000000008000147a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000147a:	715d                	addi	sp,sp,-80
    8000147c:	e486                	sd	ra,72(sp)
    8000147e:	e0a2                	sd	s0,64(sp)
    80001480:	fc26                	sd	s1,56(sp)
    80001482:	f84a                	sd	s2,48(sp)
    80001484:	f44e                	sd	s3,40(sp)
    80001486:	f052                	sd	s4,32(sp)
    80001488:	ec56                	sd	s5,24(sp)
    8000148a:	e85a                	sd	s6,16(sp)
    8000148c:	e45e                	sd	s7,8(sp)
    8000148e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001490:	03459793          	slli	a5,a1,0x34
    80001494:	e795                	bnez	a5,800014c0 <uvmunmap+0x46>
    80001496:	8a2a                	mv	s4,a0
    80001498:	892e                	mv	s2,a1
    8000149a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000149c:	0632                	slli	a2,a2,0xc
    8000149e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800014a2:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014a4:	6b05                	lui	s6,0x1
    800014a6:	0735e863          	bltu	a1,s3,80001516 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800014aa:	60a6                	ld	ra,72(sp)
    800014ac:	6406                	ld	s0,64(sp)
    800014ae:	74e2                	ld	s1,56(sp)
    800014b0:	7942                	ld	s2,48(sp)
    800014b2:	79a2                	ld	s3,40(sp)
    800014b4:	7a02                	ld	s4,32(sp)
    800014b6:	6ae2                	ld	s5,24(sp)
    800014b8:	6b42                	ld	s6,16(sp)
    800014ba:	6ba2                	ld	s7,8(sp)
    800014bc:	6161                	addi	sp,sp,80
    800014be:	8082                	ret
    panic("uvmunmap: not aligned");
    800014c0:	00007517          	auipc	a0,0x7
    800014c4:	c5850513          	addi	a0,a0,-936 # 80008118 <digits+0xe8>
    800014c8:	fffff097          	auipc	ra,0xfffff
    800014cc:	08e080e7          	jalr	142(ra) # 80000556 <panic>
      panic("uvmunmap: walk");
    800014d0:	00007517          	auipc	a0,0x7
    800014d4:	c6050513          	addi	a0,a0,-928 # 80008130 <digits+0x100>
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	07e080e7          	jalr	126(ra) # 80000556 <panic>
      panic("uvmunmap: not mapped");
    800014e0:	00007517          	auipc	a0,0x7
    800014e4:	c6050513          	addi	a0,a0,-928 # 80008140 <digits+0x110>
    800014e8:	fffff097          	auipc	ra,0xfffff
    800014ec:	06e080e7          	jalr	110(ra) # 80000556 <panic>
      panic("uvmunmap: not a leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c6850513          	addi	a0,a0,-920 # 80008158 <digits+0x128>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	05e080e7          	jalr	94(ra) # 80000556 <panic>
      uint64 pa = PTE2PA(*pte);
    80001500:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001502:	0532                	slli	a0,a0,0xc
    80001504:	fffff097          	auipc	ra,0xfffff
    80001508:	52e080e7          	jalr	1326(ra) # 80000a32 <kfree>
    *pte = 0;
    8000150c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001510:	995a                	add	s2,s2,s6
    80001512:	f9397ce3          	bgeu	s2,s3,800014aa <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001516:	4601                	li	a2,0
    80001518:	85ca                	mv	a1,s2
    8000151a:	8552                	mv	a0,s4
    8000151c:	00000097          	auipc	ra,0x0
    80001520:	c44080e7          	jalr	-956(ra) # 80001160 <walk>
    80001524:	84aa                	mv	s1,a0
    80001526:	d54d                	beqz	a0,800014d0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001528:	6108                	ld	a0,0(a0)
    8000152a:	00157793          	andi	a5,a0,1
    8000152e:	dbcd                	beqz	a5,800014e0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001530:	3ff57793          	andi	a5,a0,1023
    80001534:	fb778ee3          	beq	a5,s7,800014f0 <uvmunmap+0x76>
    if(do_free){
    80001538:	fc0a8ae3          	beqz	s5,8000150c <uvmunmap+0x92>
    8000153c:	b7d1                	j	80001500 <uvmunmap+0x86>

000000008000153e <kvmcopymappings>:
{
    8000153e:	7139                	addi	sp,sp,-64
    80001540:	fc06                	sd	ra,56(sp)
    80001542:	f822                	sd	s0,48(sp)
    80001544:	f426                	sd	s1,40(sp)
    80001546:	f04a                	sd	s2,32(sp)
    80001548:	ec4e                	sd	s3,24(sp)
    8000154a:	e852                	sd	s4,16(sp)
    8000154c:	e456                	sd	s5,8(sp)
    8000154e:	0080                	addi	s0,sp,64
  for(i = PGROUNDUP(start); i < start + sz; i += PGSIZE){
    80001550:	6a05                	lui	s4,0x1
    80001552:	1a7d                	addi	s4,s4,-1
    80001554:	9a32                	add	s4,s4,a2
    80001556:	77fd                	lui	a5,0xfffff
    80001558:	00fa7a33          	and	s4,s4,a5
    8000155c:	00d60933          	add	s2,a2,a3
    80001560:	092a7763          	bgeu	s4,s2,800015ee <kvmcopymappings+0xb0>
    80001564:	8aaa                	mv	s5,a0
    80001566:	89ae                	mv	s3,a1
    80001568:	84d2                	mv	s1,s4
    if((pte = walk(src, i, 0)) == 0)
    8000156a:	4601                	li	a2,0
    8000156c:	85a6                	mv	a1,s1
    8000156e:	8556                	mv	a0,s5
    80001570:	00000097          	auipc	ra,0x0
    80001574:	bf0080e7          	jalr	-1040(ra) # 80001160 <walk>
    80001578:	c51d                	beqz	a0,800015a6 <kvmcopymappings+0x68>
    if((*pte & PTE_V) == 0)
    8000157a:	6118                	ld	a4,0(a0)
    8000157c:	00177793          	andi	a5,a4,1
    80001580:	cb9d                	beqz	a5,800015b6 <kvmcopymappings+0x78>
    pa = PTE2PA(*pte);
    80001582:	00a75693          	srli	a3,a4,0xa
    if(mappages(dst, i, PGSIZE, pa, flags) != 0){
    80001586:	3ef77713          	andi	a4,a4,1007
    8000158a:	06b2                	slli	a3,a3,0xc
    8000158c:	6605                	lui	a2,0x1
    8000158e:	85a6                	mv	a1,s1
    80001590:	854e                	mv	a0,s3
    80001592:	00000097          	auipc	ra,0x0
    80001596:	d0c080e7          	jalr	-756(ra) # 8000129e <mappages>
    8000159a:	e515                	bnez	a0,800015c6 <kvmcopymappings+0x88>
  for(i = PGROUNDUP(start); i < start + sz; i += PGSIZE){
    8000159c:	6785                	lui	a5,0x1
    8000159e:	94be                	add	s1,s1,a5
    800015a0:	fd24e5e3          	bltu	s1,s2,8000156a <kvmcopymappings+0x2c>
    800015a4:	a825                	j	800015dc <kvmcopymappings+0x9e>
      panic("kvmcopymappings: pte should exist");
    800015a6:	00007517          	auipc	a0,0x7
    800015aa:	bca50513          	addi	a0,a0,-1078 # 80008170 <digits+0x140>
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	fa8080e7          	jalr	-88(ra) # 80000556 <panic>
      panic("kvmcopymappings: page not present");
    800015b6:	00007517          	auipc	a0,0x7
    800015ba:	be250513          	addi	a0,a0,-1054 # 80008198 <digits+0x168>
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	f98080e7          	jalr	-104(ra) # 80000556 <panic>
  uvmunmap(dst, PGROUNDUP(start), (i - PGROUNDUP(start)) / PGSIZE, 0);
    800015c6:	41448633          	sub	a2,s1,s4
    800015ca:	4681                	li	a3,0
    800015cc:	8231                	srli	a2,a2,0xc
    800015ce:	85d2                	mv	a1,s4
    800015d0:	854e                	mv	a0,s3
    800015d2:	00000097          	auipc	ra,0x0
    800015d6:	ea8080e7          	jalr	-344(ra) # 8000147a <uvmunmap>
  return -1;
    800015da:	557d                	li	a0,-1
}
    800015dc:	70e2                	ld	ra,56(sp)
    800015de:	7442                	ld	s0,48(sp)
    800015e0:	74a2                	ld	s1,40(sp)
    800015e2:	7902                	ld	s2,32(sp)
    800015e4:	69e2                	ld	s3,24(sp)
    800015e6:	6a42                	ld	s4,16(sp)
    800015e8:	6aa2                	ld	s5,8(sp)
    800015ea:	6121                	addi	sp,sp,64
    800015ec:	8082                	ret
  return 0;
    800015ee:	4501                	li	a0,0
    800015f0:	b7f5                	j	800015dc <kvmcopymappings+0x9e>

00000000800015f2 <kvmdealloc>:
{
    800015f2:	1101                	addi	sp,sp,-32
    800015f4:	ec06                	sd	ra,24(sp)
    800015f6:	e822                	sd	s0,16(sp)
    800015f8:	e426                	sd	s1,8(sp)
    800015fa:	1000                	addi	s0,sp,32
    return oldsz;
    800015fc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015fe:	00b67d63          	bgeu	a2,a1,80001618 <kvmdealloc+0x26>
    80001602:	84b2                	mv	s1,a2
  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001604:	6785                	lui	a5,0x1
    80001606:	17fd                	addi	a5,a5,-1
    80001608:	00f60733          	add	a4,a2,a5
    8000160c:	767d                	lui	a2,0xfffff
    8000160e:	8f71                	and	a4,a4,a2
    80001610:	97ae                	add	a5,a5,a1
    80001612:	8ff1                	and	a5,a5,a2
    80001614:	00f76863          	bltu	a4,a5,80001624 <kvmdealloc+0x32>
}
    80001618:	8526                	mv	a0,s1
    8000161a:	60e2                	ld	ra,24(sp)
    8000161c:	6442                	ld	s0,16(sp)
    8000161e:	64a2                	ld	s1,8(sp)
    80001620:	6105                	addi	sp,sp,32
    80001622:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001624:	8f99                	sub	a5,a5,a4
    80001626:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 0);
    80001628:	4681                	li	a3,0
    8000162a:	0007861b          	sext.w	a2,a5
    8000162e:	85ba                	mv	a1,a4
    80001630:	00000097          	auipc	ra,0x0
    80001634:	e4a080e7          	jalr	-438(ra) # 8000147a <uvmunmap>
    80001638:	b7c5                	j	80001618 <kvmdealloc+0x26>

000000008000163a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000163a:	1101                	addi	sp,sp,-32
    8000163c:	ec06                	sd	ra,24(sp)
    8000163e:	e822                	sd	s0,16(sp)
    80001640:	e426                	sd	s1,8(sp)
    80001642:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	4ea080e7          	jalr	1258(ra) # 80000b2e <kalloc>
    8000164c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000164e:	c519                	beqz	a0,8000165c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001650:	6605                	lui	a2,0x1
    80001652:	4581                	li	a1,0
    80001654:	fffff097          	auipc	ra,0xfffff
    80001658:	6c6080e7          	jalr	1734(ra) # 80000d1a <memset>
  return pagetable;
}
    8000165c:	8526                	mv	a0,s1
    8000165e:	60e2                	ld	ra,24(sp)
    80001660:	6442                	ld	s0,16(sp)
    80001662:	64a2                	ld	s1,8(sp)
    80001664:	6105                	addi	sp,sp,32
    80001666:	8082                	ret

0000000080001668 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001668:	7179                	addi	sp,sp,-48
    8000166a:	f406                	sd	ra,40(sp)
    8000166c:	f022                	sd	s0,32(sp)
    8000166e:	ec26                	sd	s1,24(sp)
    80001670:	e84a                	sd	s2,16(sp)
    80001672:	e44e                	sd	s3,8(sp)
    80001674:	e052                	sd	s4,0(sp)
    80001676:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001678:	6785                	lui	a5,0x1
    8000167a:	04f67863          	bgeu	a2,a5,800016ca <uvminit+0x62>
    8000167e:	8a2a                	mv	s4,a0
    80001680:	89ae                	mv	s3,a1
    80001682:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	4aa080e7          	jalr	1194(ra) # 80000b2e <kalloc>
    8000168c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000168e:	6605                	lui	a2,0x1
    80001690:	4581                	li	a1,0
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	688080e7          	jalr	1672(ra) # 80000d1a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000169a:	4779                	li	a4,30
    8000169c:	86ca                	mv	a3,s2
    8000169e:	6605                	lui	a2,0x1
    800016a0:	4581                	li	a1,0
    800016a2:	8552                	mv	a0,s4
    800016a4:	00000097          	auipc	ra,0x0
    800016a8:	bfa080e7          	jalr	-1030(ra) # 8000129e <mappages>
  memmove(mem, src, sz);
    800016ac:	8626                	mv	a2,s1
    800016ae:	85ce                	mv	a1,s3
    800016b0:	854a                	mv	a0,s2
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	6c8080e7          	jalr	1736(ra) # 80000d7a <memmove>
}
    800016ba:	70a2                	ld	ra,40(sp)
    800016bc:	7402                	ld	s0,32(sp)
    800016be:	64e2                	ld	s1,24(sp)
    800016c0:	6942                	ld	s2,16(sp)
    800016c2:	69a2                	ld	s3,8(sp)
    800016c4:	6a02                	ld	s4,0(sp)
    800016c6:	6145                	addi	sp,sp,48
    800016c8:	8082                	ret
    panic("inituvm: more than a page");
    800016ca:	00007517          	auipc	a0,0x7
    800016ce:	af650513          	addi	a0,a0,-1290 # 800081c0 <digits+0x190>
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	e84080e7          	jalr	-380(ra) # 80000556 <panic>

00000000800016da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800016da:	1101                	addi	sp,sp,-32
    800016dc:	ec06                	sd	ra,24(sp)
    800016de:	e822                	sd	s0,16(sp)
    800016e0:	e426                	sd	s1,8(sp)
    800016e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800016e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800016e6:	00b67d63          	bgeu	a2,a1,80001700 <uvmdealloc+0x26>
    800016ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800016ec:	6785                	lui	a5,0x1
    800016ee:	17fd                	addi	a5,a5,-1
    800016f0:	00f60733          	add	a4,a2,a5
    800016f4:	767d                	lui	a2,0xfffff
    800016f6:	8f71                	and	a4,a4,a2
    800016f8:	97ae                	add	a5,a5,a1
    800016fa:	8ff1                	and	a5,a5,a2
    800016fc:	00f76863          	bltu	a4,a5,8000170c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001700:	8526                	mv	a0,s1
    80001702:	60e2                	ld	ra,24(sp)
    80001704:	6442                	ld	s0,16(sp)
    80001706:	64a2                	ld	s1,8(sp)
    80001708:	6105                	addi	sp,sp,32
    8000170a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000170c:	8f99                	sub	a5,a5,a4
    8000170e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001710:	4685                	li	a3,1
    80001712:	0007861b          	sext.w	a2,a5
    80001716:	85ba                	mv	a1,a4
    80001718:	00000097          	auipc	ra,0x0
    8000171c:	d62080e7          	jalr	-670(ra) # 8000147a <uvmunmap>
    80001720:	b7c5                	j	80001700 <uvmdealloc+0x26>

0000000080001722 <uvmalloc>:
  if(newsz < oldsz)
    80001722:	0ab66163          	bltu	a2,a1,800017c4 <uvmalloc+0xa2>
{
    80001726:	7139                	addi	sp,sp,-64
    80001728:	fc06                	sd	ra,56(sp)
    8000172a:	f822                	sd	s0,48(sp)
    8000172c:	f426                	sd	s1,40(sp)
    8000172e:	f04a                	sd	s2,32(sp)
    80001730:	ec4e                	sd	s3,24(sp)
    80001732:	e852                	sd	s4,16(sp)
    80001734:	e456                	sd	s5,8(sp)
    80001736:	0080                	addi	s0,sp,64
    80001738:	8aaa                	mv	s5,a0
    8000173a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000173c:	6985                	lui	s3,0x1
    8000173e:	19fd                	addi	s3,s3,-1
    80001740:	95ce                	add	a1,a1,s3
    80001742:	79fd                	lui	s3,0xfffff
    80001744:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001748:	08c9f063          	bgeu	s3,a2,800017c8 <uvmalloc+0xa6>
    8000174c:	894e                	mv	s2,s3
    mem = kalloc();
    8000174e:	fffff097          	auipc	ra,0xfffff
    80001752:	3e0080e7          	jalr	992(ra) # 80000b2e <kalloc>
    80001756:	84aa                	mv	s1,a0
    if(mem == 0){
    80001758:	c51d                	beqz	a0,80001786 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000175a:	6605                	lui	a2,0x1
    8000175c:	4581                	li	a1,0
    8000175e:	fffff097          	auipc	ra,0xfffff
    80001762:	5bc080e7          	jalr	1468(ra) # 80000d1a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001766:	4779                	li	a4,30
    80001768:	86a6                	mv	a3,s1
    8000176a:	6605                	lui	a2,0x1
    8000176c:	85ca                	mv	a1,s2
    8000176e:	8556                	mv	a0,s5
    80001770:	00000097          	auipc	ra,0x0
    80001774:	b2e080e7          	jalr	-1234(ra) # 8000129e <mappages>
    80001778:	e905                	bnez	a0,800017a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000177a:	6785                	lui	a5,0x1
    8000177c:	993e                	add	s2,s2,a5
    8000177e:	fd4968e3          	bltu	s2,s4,8000174e <uvmalloc+0x2c>
  return newsz;
    80001782:	8552                	mv	a0,s4
    80001784:	a809                	j	80001796 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001786:	864e                	mv	a2,s3
    80001788:	85ca                	mv	a1,s2
    8000178a:	8556                	mv	a0,s5
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	f4e080e7          	jalr	-178(ra) # 800016da <uvmdealloc>
      return 0;
    80001794:	4501                	li	a0,0
}
    80001796:	70e2                	ld	ra,56(sp)
    80001798:	7442                	ld	s0,48(sp)
    8000179a:	74a2                	ld	s1,40(sp)
    8000179c:	7902                	ld	s2,32(sp)
    8000179e:	69e2                	ld	s3,24(sp)
    800017a0:	6a42                	ld	s4,16(sp)
    800017a2:	6aa2                	ld	s5,8(sp)
    800017a4:	6121                	addi	sp,sp,64
    800017a6:	8082                	ret
      kfree(mem);
    800017a8:	8526                	mv	a0,s1
    800017aa:	fffff097          	auipc	ra,0xfffff
    800017ae:	288080e7          	jalr	648(ra) # 80000a32 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800017b2:	864e                	mv	a2,s3
    800017b4:	85ca                	mv	a1,s2
    800017b6:	8556                	mv	a0,s5
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	f22080e7          	jalr	-222(ra) # 800016da <uvmdealloc>
      return 0;
    800017c0:	4501                	li	a0,0
    800017c2:	bfd1                	j	80001796 <uvmalloc+0x74>
    return oldsz;
    800017c4:	852e                	mv	a0,a1
}
    800017c6:	8082                	ret
  return newsz;
    800017c8:	8532                	mv	a0,a2
    800017ca:	b7f1                	j	80001796 <uvmalloc+0x74>

00000000800017cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800017cc:	7179                	addi	sp,sp,-48
    800017ce:	f406                	sd	ra,40(sp)
    800017d0:	f022                	sd	s0,32(sp)
    800017d2:	ec26                	sd	s1,24(sp)
    800017d4:	e84a                	sd	s2,16(sp)
    800017d6:	e44e                	sd	s3,8(sp)
    800017d8:	e052                	sd	s4,0(sp)
    800017da:	1800                	addi	s0,sp,48
    800017dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800017de:	84aa                	mv	s1,a0
    800017e0:	6905                	lui	s2,0x1
    800017e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800017e4:	4985                	li	s3,1
    800017e6:	a821                	j	800017fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800017e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800017ea:	0532                	slli	a0,a0,0xc
    800017ec:	00000097          	auipc	ra,0x0
    800017f0:	fe0080e7          	jalr	-32(ra) # 800017cc <freewalk>
      pagetable[i] = 0;
    800017f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800017f8:	04a1                	addi	s1,s1,8
    800017fa:	03248163          	beq	s1,s2,8000181c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800017fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001800:	00f57793          	andi	a5,a0,15
    80001804:	ff3782e3          	beq	a5,s3,800017e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001808:	8905                	andi	a0,a0,1
    8000180a:	d57d                	beqz	a0,800017f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000180c:	00007517          	auipc	a0,0x7
    80001810:	9d450513          	addi	a0,a0,-1580 # 800081e0 <digits+0x1b0>
    80001814:	fffff097          	auipc	ra,0xfffff
    80001818:	d42080e7          	jalr	-702(ra) # 80000556 <panic>
    }
  }
  kfree((void*)pagetable);
    8000181c:	8552                	mv	a0,s4
    8000181e:	fffff097          	auipc	ra,0xfffff
    80001822:	214080e7          	jalr	532(ra) # 80000a32 <kfree>
}
    80001826:	70a2                	ld	ra,40(sp)
    80001828:	7402                	ld	s0,32(sp)
    8000182a:	64e2                	ld	s1,24(sp)
    8000182c:	6942                	ld	s2,16(sp)
    8000182e:	69a2                	ld	s3,8(sp)
    80001830:	6a02                	ld	s4,0(sp)
    80001832:	6145                	addi	sp,sp,48
    80001834:	8082                	ret

0000000080001836 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001836:	1101                	addi	sp,sp,-32
    80001838:	ec06                	sd	ra,24(sp)
    8000183a:	e822                	sd	s0,16(sp)
    8000183c:	e426                	sd	s1,8(sp)
    8000183e:	1000                	addi	s0,sp,32
    80001840:	84aa                	mv	s1,a0
  if(sz > 0)
    80001842:	e999                	bnez	a1,80001858 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001844:	8526                	mv	a0,s1
    80001846:	00000097          	auipc	ra,0x0
    8000184a:	f86080e7          	jalr	-122(ra) # 800017cc <freewalk>
}
    8000184e:	60e2                	ld	ra,24(sp)
    80001850:	6442                	ld	s0,16(sp)
    80001852:	64a2                	ld	s1,8(sp)
    80001854:	6105                	addi	sp,sp,32
    80001856:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001858:	6605                	lui	a2,0x1
    8000185a:	167d                	addi	a2,a2,-1
    8000185c:	962e                	add	a2,a2,a1
    8000185e:	4685                	li	a3,1
    80001860:	8231                	srli	a2,a2,0xc
    80001862:	4581                	li	a1,0
    80001864:	00000097          	auipc	ra,0x0
    80001868:	c16080e7          	jalr	-1002(ra) # 8000147a <uvmunmap>
    8000186c:	bfe1                	j	80001844 <uvmfree+0xe>

000000008000186e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000186e:	c679                	beqz	a2,8000193c <uvmcopy+0xce>
{
    80001870:	715d                	addi	sp,sp,-80
    80001872:	e486                	sd	ra,72(sp)
    80001874:	e0a2                	sd	s0,64(sp)
    80001876:	fc26                	sd	s1,56(sp)
    80001878:	f84a                	sd	s2,48(sp)
    8000187a:	f44e                	sd	s3,40(sp)
    8000187c:	f052                	sd	s4,32(sp)
    8000187e:	ec56                	sd	s5,24(sp)
    80001880:	e85a                	sd	s6,16(sp)
    80001882:	e45e                	sd	s7,8(sp)
    80001884:	0880                	addi	s0,sp,80
    80001886:	8b2a                	mv	s6,a0
    80001888:	8aae                	mv	s5,a1
    8000188a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000188c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000188e:	4601                	li	a2,0
    80001890:	85ce                	mv	a1,s3
    80001892:	855a                	mv	a0,s6
    80001894:	00000097          	auipc	ra,0x0
    80001898:	8cc080e7          	jalr	-1844(ra) # 80001160 <walk>
    8000189c:	c531                	beqz	a0,800018e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000189e:	6118                	ld	a4,0(a0)
    800018a0:	00177793          	andi	a5,a4,1
    800018a4:	cbb1                	beqz	a5,800018f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800018a6:	00a75593          	srli	a1,a4,0xa
    800018aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800018ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800018b2:	fffff097          	auipc	ra,0xfffff
    800018b6:	27c080e7          	jalr	636(ra) # 80000b2e <kalloc>
    800018ba:	892a                	mv	s2,a0
    800018bc:	c939                	beqz	a0,80001912 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800018be:	6605                	lui	a2,0x1
    800018c0:	85de                	mv	a1,s7
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	4b8080e7          	jalr	1208(ra) # 80000d7a <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800018ca:	8726                	mv	a4,s1
    800018cc:	86ca                	mv	a3,s2
    800018ce:	6605                	lui	a2,0x1
    800018d0:	85ce                	mv	a1,s3
    800018d2:	8556                	mv	a0,s5
    800018d4:	00000097          	auipc	ra,0x0
    800018d8:	9ca080e7          	jalr	-1590(ra) # 8000129e <mappages>
    800018dc:	e515                	bnez	a0,80001908 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800018de:	6785                	lui	a5,0x1
    800018e0:	99be                	add	s3,s3,a5
    800018e2:	fb49e6e3          	bltu	s3,s4,8000188e <uvmcopy+0x20>
    800018e6:	a081                	j	80001926 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800018e8:	00007517          	auipc	a0,0x7
    800018ec:	90850513          	addi	a0,a0,-1784 # 800081f0 <digits+0x1c0>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	c66080e7          	jalr	-922(ra) # 80000556 <panic>
      panic("uvmcopy: page not present");
    800018f8:	00007517          	auipc	a0,0x7
    800018fc:	91850513          	addi	a0,a0,-1768 # 80008210 <digits+0x1e0>
    80001900:	fffff097          	auipc	ra,0xfffff
    80001904:	c56080e7          	jalr	-938(ra) # 80000556 <panic>
      kfree(mem);
    80001908:	854a                	mv	a0,s2
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	128080e7          	jalr	296(ra) # 80000a32 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001912:	4685                	li	a3,1
    80001914:	00c9d613          	srli	a2,s3,0xc
    80001918:	4581                	li	a1,0
    8000191a:	8556                	mv	a0,s5
    8000191c:	00000097          	auipc	ra,0x0
    80001920:	b5e080e7          	jalr	-1186(ra) # 8000147a <uvmunmap>
  return -1;
    80001924:	557d                	li	a0,-1
}
    80001926:	60a6                	ld	ra,72(sp)
    80001928:	6406                	ld	s0,64(sp)
    8000192a:	74e2                	ld	s1,56(sp)
    8000192c:	7942                	ld	s2,48(sp)
    8000192e:	79a2                	ld	s3,40(sp)
    80001930:	7a02                	ld	s4,32(sp)
    80001932:	6ae2                	ld	s5,24(sp)
    80001934:	6b42                	ld	s6,16(sp)
    80001936:	6ba2                	ld	s7,8(sp)
    80001938:	6161                	addi	sp,sp,80
    8000193a:	8082                	ret
  return 0;
    8000193c:	4501                	li	a0,0
}
    8000193e:	8082                	ret

0000000080001940 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001940:	1141                	addi	sp,sp,-16
    80001942:	e406                	sd	ra,8(sp)
    80001944:	e022                	sd	s0,0(sp)
    80001946:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001948:	4601                	li	a2,0
    8000194a:	00000097          	auipc	ra,0x0
    8000194e:	816080e7          	jalr	-2026(ra) # 80001160 <walk>
  if(pte == 0)
    80001952:	c901                	beqz	a0,80001962 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001954:	611c                	ld	a5,0(a0)
    80001956:	9bbd                	andi	a5,a5,-17
    80001958:	e11c                	sd	a5,0(a0)
}
    8000195a:	60a2                	ld	ra,8(sp)
    8000195c:	6402                	ld	s0,0(sp)
    8000195e:	0141                	addi	sp,sp,16
    80001960:	8082                	ret
    panic("uvmclear");
    80001962:	00007517          	auipc	a0,0x7
    80001966:	8ce50513          	addi	a0,a0,-1842 # 80008230 <digits+0x200>
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	bec080e7          	jalr	-1044(ra) # 80000556 <panic>

0000000080001972 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001972:	c6bd                	beqz	a3,800019e0 <copyout+0x6e>
{
    80001974:	715d                	addi	sp,sp,-80
    80001976:	e486                	sd	ra,72(sp)
    80001978:	e0a2                	sd	s0,64(sp)
    8000197a:	fc26                	sd	s1,56(sp)
    8000197c:	f84a                	sd	s2,48(sp)
    8000197e:	f44e                	sd	s3,40(sp)
    80001980:	f052                	sd	s4,32(sp)
    80001982:	ec56                	sd	s5,24(sp)
    80001984:	e85a                	sd	s6,16(sp)
    80001986:	e45e                	sd	s7,8(sp)
    80001988:	e062                	sd	s8,0(sp)
    8000198a:	0880                	addi	s0,sp,80
    8000198c:	8b2a                	mv	s6,a0
    8000198e:	8c2e                	mv	s8,a1
    80001990:	8a32                	mv	s4,a2
    80001992:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001994:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001996:	6a85                	lui	s5,0x1
    80001998:	a015                	j	800019bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000199a:	9562                	add	a0,a0,s8
    8000199c:	0004861b          	sext.w	a2,s1
    800019a0:	85d2                	mv	a1,s4
    800019a2:	41250533          	sub	a0,a0,s2
    800019a6:	fffff097          	auipc	ra,0xfffff
    800019aa:	3d4080e7          	jalr	980(ra) # 80000d7a <memmove>

    len -= n;
    800019ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800019b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800019b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800019b8:	02098263          	beqz	s3,800019dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800019bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019c0:	85ca                	mv	a1,s2
    800019c2:	855a                	mv	a0,s6
    800019c4:	00000097          	auipc	ra,0x0
    800019c8:	842080e7          	jalr	-1982(ra) # 80001206 <walkaddr>
    if(pa0 == 0)
    800019cc:	cd01                	beqz	a0,800019e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800019ce:	418904b3          	sub	s1,s2,s8
    800019d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800019d4:	fc99f3e3          	bgeu	s3,s1,8000199a <copyout+0x28>
    800019d8:	84ce                	mv	s1,s3
    800019da:	b7c1                	j	8000199a <copyout+0x28>
  }
  return 0;
    800019dc:	4501                	li	a0,0
    800019de:	a021                	j	800019e6 <copyout+0x74>
    800019e0:	4501                	li	a0,0
}
    800019e2:	8082                	ret
      return -1;
    800019e4:	557d                	li	a0,-1
}
    800019e6:	60a6                	ld	ra,72(sp)
    800019e8:	6406                	ld	s0,64(sp)
    800019ea:	74e2                	ld	s1,56(sp)
    800019ec:	7942                	ld	s2,48(sp)
    800019ee:	79a2                	ld	s3,40(sp)
    800019f0:	7a02                	ld	s4,32(sp)
    800019f2:	6ae2                	ld	s5,24(sp)
    800019f4:	6b42                	ld	s6,16(sp)
    800019f6:	6ba2                	ld	s7,8(sp)
    800019f8:	6c02                	ld	s8,0(sp)
    800019fa:	6161                	addi	sp,sp,80
    800019fc:	8082                	ret

00000000800019fe <copyin>:
int copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max);

// 将 copyin、copyinstr 改为转发到新函数
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    80001a06:	00005097          	auipc	ra,0x5
    80001a0a:	a96080e7          	jalr	-1386(ra) # 8000649c <copyin_new>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret

0000000080001a16 <copyinstr>:

int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001a16:	1141                	addi	sp,sp,-16
    80001a18:	e406                	sd	ra,8(sp)
    80001a1a:	e022                	sd	s0,0(sp)
    80001a1c:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    80001a1e:	00005097          	auipc	ra,0x5
    80001a22:	ae6080e7          	jalr	-1306(ra) # 80006504 <copyinstr_new>
}
    80001a26:	60a2                	ld	ra,8(sp)
    80001a28:	6402                	ld	s0,0(sp)
    80001a2a:	0141                	addi	sp,sp,16
    80001a2c:	8082                	ret

0000000080001a2e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a2e:	1101                	addi	sp,sp,-32
    80001a30:	ec06                	sd	ra,24(sp)
    80001a32:	e822                	sd	s0,16(sp)
    80001a34:	e426                	sd	s1,8(sp)
    80001a36:	1000                	addi	s0,sp,32
    80001a38:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	16a080e7          	jalr	362(ra) # 80000ba4 <holding>
    80001a42:	c909                	beqz	a0,80001a54 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a44:	749c                	ld	a5,40(s1)
    80001a46:	00978f63          	beq	a5,s1,80001a64 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a4a:	60e2                	ld	ra,24(sp)
    80001a4c:	6442                	ld	s0,16(sp)
    80001a4e:	64a2                	ld	s1,8(sp)
    80001a50:	6105                	addi	sp,sp,32
    80001a52:	8082                	ret
    panic("wakeup1");
    80001a54:	00006517          	auipc	a0,0x6
    80001a58:	7ec50513          	addi	a0,a0,2028 # 80008240 <digits+0x210>
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	afa080e7          	jalr	-1286(ra) # 80000556 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a64:	4c98                	lw	a4,24(s1)
    80001a66:	4785                	li	a5,1
    80001a68:	fef711e3          	bne	a4,a5,80001a4a <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a6c:	4789                	li	a5,2
    80001a6e:	cc9c                	sw	a5,24(s1)
}
    80001a70:	bfe9                	j	80001a4a <wakeup1+0x1c>

0000000080001a72 <procinit>:
{
    80001a72:	7179                	addi	sp,sp,-48
    80001a74:	f406                	sd	ra,40(sp)
    80001a76:	f022                	sd	s0,32(sp)
    80001a78:	ec26                	sd	s1,24(sp)
    80001a7a:	e84a                	sd	s2,16(sp)
    80001a7c:	e44e                	sd	s3,8(sp)
    80001a7e:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001a80:	00006597          	auipc	a1,0x6
    80001a84:	7c858593          	addi	a1,a1,1992 # 80008248 <digits+0x218>
    80001a88:	00010517          	auipc	a0,0x10
    80001a8c:	ec850513          	addi	a0,a0,-312 # 80011950 <pid_lock>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	0fe080e7          	jalr	254(ra) # 80000b8e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a98:	00010497          	auipc	s1,0x10
    80001a9c:	2d048493          	addi	s1,s1,720 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001aa0:	00006997          	auipc	s3,0x6
    80001aa4:	7b098993          	addi	s3,s3,1968 # 80008250 <digits+0x220>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aa8:	00016917          	auipc	s2,0x16
    80001aac:	ec090913          	addi	s2,s2,-320 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001ab0:	85ce                	mv	a1,s3
    80001ab2:	8526                	mv	a0,s1
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	0da080e7          	jalr	218(ra) # 80000b8e <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001abc:	17048493          	addi	s1,s1,368
    80001ac0:	ff2498e3          	bne	s1,s2,80001ab0 <procinit+0x3e>
  kvminithart();
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	678080e7          	jalr	1656(ra) # 8000113c <kvminithart>
}
    80001acc:	70a2                	ld	ra,40(sp)
    80001ace:	7402                	ld	s0,32(sp)
    80001ad0:	64e2                	ld	s1,24(sp)
    80001ad2:	6942                	ld	s2,16(sp)
    80001ad4:	69a2                	ld	s3,8(sp)
    80001ad6:	6145                	addi	sp,sp,48
    80001ad8:	8082                	ret

0000000080001ada <cpuid>:
{
    80001ada:	1141                	addi	sp,sp,-16
    80001adc:	e422                	sd	s0,8(sp)
    80001ade:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ae0:	8512                	mv	a0,tp
}
    80001ae2:	2501                	sext.w	a0,a0
    80001ae4:	6422                	ld	s0,8(sp)
    80001ae6:	0141                	addi	sp,sp,16
    80001ae8:	8082                	ret

0000000080001aea <mycpu>:
mycpu(void) {
    80001aea:	1141                	addi	sp,sp,-16
    80001aec:	e422                	sd	s0,8(sp)
    80001aee:	0800                	addi	s0,sp,16
    80001af0:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001af2:	2781                	sext.w	a5,a5
    80001af4:	079e                	slli	a5,a5,0x7
}
    80001af6:	00010517          	auipc	a0,0x10
    80001afa:	e7250513          	addi	a0,a0,-398 # 80011968 <cpus>
    80001afe:	953e                	add	a0,a0,a5
    80001b00:	6422                	ld	s0,8(sp)
    80001b02:	0141                	addi	sp,sp,16
    80001b04:	8082                	ret

0000000080001b06 <myproc>:
myproc(void) {
    80001b06:	1101                	addi	sp,sp,-32
    80001b08:	ec06                	sd	ra,24(sp)
    80001b0a:	e822                	sd	s0,16(sp)
    80001b0c:	e426                	sd	s1,8(sp)
    80001b0e:	1000                	addi	s0,sp,32
  push_off();
    80001b10:	fffff097          	auipc	ra,0xfffff
    80001b14:	0c2080e7          	jalr	194(ra) # 80000bd2 <push_off>
    80001b18:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b1a:	2781                	sext.w	a5,a5
    80001b1c:	079e                	slli	a5,a5,0x7
    80001b1e:	00010717          	auipc	a4,0x10
    80001b22:	e3270713          	addi	a4,a4,-462 # 80011950 <pid_lock>
    80001b26:	97ba                	add	a5,a5,a4
    80001b28:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b2a:	fffff097          	auipc	ra,0xfffff
    80001b2e:	148080e7          	jalr	328(ra) # 80000c72 <pop_off>
}
    80001b32:	8526                	mv	a0,s1
    80001b34:	60e2                	ld	ra,24(sp)
    80001b36:	6442                	ld	s0,16(sp)
    80001b38:	64a2                	ld	s1,8(sp)
    80001b3a:	6105                	addi	sp,sp,32
    80001b3c:	8082                	ret

0000000080001b3e <forkret>:
{
    80001b3e:	1141                	addi	sp,sp,-16
    80001b40:	e406                	sd	ra,8(sp)
    80001b42:	e022                	sd	s0,0(sp)
    80001b44:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b46:	00000097          	auipc	ra,0x0
    80001b4a:	fc0080e7          	jalr	-64(ra) # 80001b06 <myproc>
    80001b4e:	fffff097          	auipc	ra,0xfffff
    80001b52:	184080e7          	jalr	388(ra) # 80000cd2 <release>
  if (first) {
    80001b56:	00007797          	auipc	a5,0x7
    80001b5a:	d6a7a783          	lw	a5,-662(a5) # 800088c0 <first.1696>
    80001b5e:	eb89                	bnez	a5,80001b70 <forkret+0x32>
  usertrapret();
    80001b60:	00001097          	auipc	ra,0x1
    80001b64:	d34080e7          	jalr	-716(ra) # 80002894 <usertrapret>
}
    80001b68:	60a2                	ld	ra,8(sp)
    80001b6a:	6402                	ld	s0,0(sp)
    80001b6c:	0141                	addi	sp,sp,16
    80001b6e:	8082                	ret
    first = 0;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	d407a823          	sw	zero,-688(a5) # 800088c0 <first.1696>
    fsinit(ROOTDEV);
    80001b78:	4505                	li	a0,1
    80001b7a:	00002097          	auipc	ra,0x2
    80001b7e:	a5c080e7          	jalr	-1444(ra) # 800035d6 <fsinit>
    80001b82:	bff9                	j	80001b60 <forkret+0x22>

0000000080001b84 <allocpid>:
allocpid() {
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	e04a                	sd	s2,0(sp)
    80001b8e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b90:	00010917          	auipc	s2,0x10
    80001b94:	dc090913          	addi	s2,s2,-576 # 80011950 <pid_lock>
    80001b98:	854a                	mv	a0,s2
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	084080e7          	jalr	132(ra) # 80000c1e <acquire>
  pid = nextpid;
    80001ba2:	00007797          	auipc	a5,0x7
    80001ba6:	d2278793          	addi	a5,a5,-734 # 800088c4 <nextpid>
    80001baa:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bac:	0014871b          	addiw	a4,s1,1
    80001bb0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bb2:	854a                	mv	a0,s2
    80001bb4:	fffff097          	auipc	ra,0xfffff
    80001bb8:	11e080e7          	jalr	286(ra) # 80000cd2 <release>
}
    80001bbc:	8526                	mv	a0,s1
    80001bbe:	60e2                	ld	ra,24(sp)
    80001bc0:	6442                	ld	s0,16(sp)
    80001bc2:	64a2                	ld	s1,8(sp)
    80001bc4:	6902                	ld	s2,0(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <proc_pagetable>:
{
    80001bca:	1101                	addi	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	e04a                	sd	s2,0(sp)
    80001bd4:	1000                	addi	s0,sp,32
    80001bd6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bd8:	00000097          	auipc	ra,0x0
    80001bdc:	a62080e7          	jalr	-1438(ra) # 8000163a <uvmcreate>
    80001be0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001be2:	c121                	beqz	a0,80001c22 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001be4:	4729                	li	a4,10
    80001be6:	00005697          	auipc	a3,0x5
    80001bea:	41a68693          	addi	a3,a3,1050 # 80007000 <_trampoline>
    80001bee:	6605                	lui	a2,0x1
    80001bf0:	040005b7          	lui	a1,0x4000
    80001bf4:	15fd                	addi	a1,a1,-1
    80001bf6:	05b2                	slli	a1,a1,0xc
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	6a6080e7          	jalr	1702(ra) # 8000129e <mappages>
    80001c00:	02054863          	bltz	a0,80001c30 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c04:	4719                	li	a4,6
    80001c06:	05893683          	ld	a3,88(s2)
    80001c0a:	6605                	lui	a2,0x1
    80001c0c:	020005b7          	lui	a1,0x2000
    80001c10:	15fd                	addi	a1,a1,-1
    80001c12:	05b6                	slli	a1,a1,0xd
    80001c14:	8526                	mv	a0,s1
    80001c16:	fffff097          	auipc	ra,0xfffff
    80001c1a:	688080e7          	jalr	1672(ra) # 8000129e <mappages>
    80001c1e:	02054163          	bltz	a0,80001c40 <proc_pagetable+0x76>
}
    80001c22:	8526                	mv	a0,s1
    80001c24:	60e2                	ld	ra,24(sp)
    80001c26:	6442                	ld	s0,16(sp)
    80001c28:	64a2                	ld	s1,8(sp)
    80001c2a:	6902                	ld	s2,0(sp)
    80001c2c:	6105                	addi	sp,sp,32
    80001c2e:	8082                	ret
    uvmfree(pagetable, 0);
    80001c30:	4581                	li	a1,0
    80001c32:	8526                	mv	a0,s1
    80001c34:	00000097          	auipc	ra,0x0
    80001c38:	c02080e7          	jalr	-1022(ra) # 80001836 <uvmfree>
    return 0;
    80001c3c:	4481                	li	s1,0
    80001c3e:	b7d5                	j	80001c22 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c40:	4681                	li	a3,0
    80001c42:	4605                	li	a2,1
    80001c44:	040005b7          	lui	a1,0x4000
    80001c48:	15fd                	addi	a1,a1,-1
    80001c4a:	05b2                	slli	a1,a1,0xc
    80001c4c:	8526                	mv	a0,s1
    80001c4e:	00000097          	auipc	ra,0x0
    80001c52:	82c080e7          	jalr	-2004(ra) # 8000147a <uvmunmap>
    uvmfree(pagetable, 0);
    80001c56:	4581                	li	a1,0
    80001c58:	8526                	mv	a0,s1
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	bdc080e7          	jalr	-1060(ra) # 80001836 <uvmfree>
    return 0;
    80001c62:	4481                	li	s1,0
    80001c64:	bf7d                	j	80001c22 <proc_pagetable+0x58>

0000000080001c66 <proc_freepagetable>:
{
    80001c66:	1101                	addi	sp,sp,-32
    80001c68:	ec06                	sd	ra,24(sp)
    80001c6a:	e822                	sd	s0,16(sp)
    80001c6c:	e426                	sd	s1,8(sp)
    80001c6e:	e04a                	sd	s2,0(sp)
    80001c70:	1000                	addi	s0,sp,32
    80001c72:	84aa                	mv	s1,a0
    80001c74:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c76:	4681                	li	a3,0
    80001c78:	4605                	li	a2,1
    80001c7a:	040005b7          	lui	a1,0x4000
    80001c7e:	15fd                	addi	a1,a1,-1
    80001c80:	05b2                	slli	a1,a1,0xc
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	7f8080e7          	jalr	2040(ra) # 8000147a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c8a:	4681                	li	a3,0
    80001c8c:	4605                	li	a2,1
    80001c8e:	020005b7          	lui	a1,0x2000
    80001c92:	15fd                	addi	a1,a1,-1
    80001c94:	05b6                	slli	a1,a1,0xd
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	7e2080e7          	jalr	2018(ra) # 8000147a <uvmunmap>
  uvmfree(pagetable, sz);
    80001ca0:	85ca                	mv	a1,s2
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	b92080e7          	jalr	-1134(ra) # 80001836 <uvmfree>
}
    80001cac:	60e2                	ld	ra,24(sp)
    80001cae:	6442                	ld	s0,16(sp)
    80001cb0:	64a2                	ld	s1,8(sp)
    80001cb2:	6902                	ld	s2,0(sp)
    80001cb4:	6105                	addi	sp,sp,32
    80001cb6:	8082                	ret

0000000080001cb8 <freeproc>:
{
    80001cb8:	1101                	addi	sp,sp,-32
    80001cba:	ec06                	sd	ra,24(sp)
    80001cbc:	e822                	sd	s0,16(sp)
    80001cbe:	e426                	sd	s1,8(sp)
    80001cc0:	1000                	addi	s0,sp,32
    80001cc2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001cc4:	6d28                	ld	a0,88(a0)
    80001cc6:	c509                	beqz	a0,80001cd0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	d6a080e7          	jalr	-662(ra) # 80000a32 <kfree>
  p->trapframe = 0;
    80001cd0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cd4:	68a8                	ld	a0,80(s1)
    80001cd6:	c511                	beqz	a0,80001ce2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cd8:	64ac                	ld	a1,72(s1)
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	f8c080e7          	jalr	-116(ra) # 80001c66 <proc_freepagetable>
  p->pagetable = 0;
    80001ce2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ce6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cea:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cee:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cf2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cf6:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cfa:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cfe:	0204aa23          	sw	zero,52(s1)
  void *kstack_pa = (void *)kvmpa(p->kernelpgtbl, p->kstack);
    80001d02:	60ac                	ld	a1,64(s1)
    80001d04:	1684b503          	ld	a0,360(s1)
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	540080e7          	jalr	1344(ra) # 80001248 <kvmpa>
  kfree(kstack_pa);
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	d22080e7          	jalr	-734(ra) # 80000a32 <kfree>
  p->kstack = 0;
    80001d18:	0404b023          	sd	zero,64(s1)
  kvm_free_kernelpgtbl(p->kernelpgtbl);
    80001d1c:	1684b503          	ld	a0,360(s1)
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	3c4080e7          	jalr	964(ra) # 800010e4 <kvm_free_kernelpgtbl>
  p->kernelpgtbl = 0;
    80001d28:	1604b423          	sd	zero,360(s1)
  p->state = UNUSED;
    80001d2c:	0004ac23          	sw	zero,24(s1)
}
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6105                	addi	sp,sp,32
    80001d38:	8082                	ret

0000000080001d3a <allocproc>:
{
    80001d3a:	1101                	addi	sp,sp,-32
    80001d3c:	ec06                	sd	ra,24(sp)
    80001d3e:	e822                	sd	s0,16(sp)
    80001d40:	e426                	sd	s1,8(sp)
    80001d42:	e04a                	sd	s2,0(sp)
    80001d44:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d46:	00010497          	auipc	s1,0x10
    80001d4a:	02248493          	addi	s1,s1,34 # 80011d68 <proc>
    80001d4e:	00016917          	auipc	s2,0x16
    80001d52:	c1a90913          	addi	s2,s2,-998 # 80017968 <tickslock>
    acquire(&p->lock);
    80001d56:	8526                	mv	a0,s1
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	ec6080e7          	jalr	-314(ra) # 80000c1e <acquire>
    if(p->state == UNUSED) {
    80001d60:	4c9c                	lw	a5,24(s1)
    80001d62:	cf81                	beqz	a5,80001d7a <allocproc+0x40>
      release(&p->lock);
    80001d64:	8526                	mv	a0,s1
    80001d66:	fffff097          	auipc	ra,0xfffff
    80001d6a:	f6c080e7          	jalr	-148(ra) # 80000cd2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d6e:	17048493          	addi	s1,s1,368
    80001d72:	ff2492e3          	bne	s1,s2,80001d56 <allocproc+0x1c>
  return 0;
    80001d76:	4481                	li	s1,0
    80001d78:	a059                	j	80001dfe <allocproc+0xc4>
  p->pid = allocpid();
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	e0a080e7          	jalr	-502(ra) # 80001b84 <allocpid>
    80001d82:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d84:	fffff097          	auipc	ra,0xfffff
    80001d88:	daa080e7          	jalr	-598(ra) # 80000b2e <kalloc>
    80001d8c:	892a                	mv	s2,a0
    80001d8e:	eca8                	sd	a0,88(s1)
    80001d90:	cd35                	beqz	a0,80001e0c <allocproc+0xd2>
  p->pagetable = proc_pagetable(p);
    80001d92:	8526                	mv	a0,s1
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	e36080e7          	jalr	-458(ra) # 80001bca <proc_pagetable>
    80001d9c:	892a                	mv	s2,a0
    80001d9e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001da0:	cd2d                	beqz	a0,80001e1a <allocproc+0xe0>
  p->kernelpgtbl = kvminit_newpgtbl();
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	66e080e7          	jalr	1646(ra) # 80001410 <kvminit_newpgtbl>
    80001daa:	16a4b423          	sd	a0,360(s1)
  char *pa = kalloc();
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	d80080e7          	jalr	-640(ra) # 80000b2e <kalloc>
    80001db6:	862a                	mv	a2,a0
  if(pa == 0)
    80001db8:	cd2d                	beqz	a0,80001e32 <allocproc+0xf8>
  kvmmap(p->kernelpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001dba:	4719                	li	a4,6
    80001dbc:	6685                	lui	a3,0x1
    80001dbe:	04000937          	lui	s2,0x4000
    80001dc2:	1975                	addi	s2,s2,-3
    80001dc4:	00c91593          	slli	a1,s2,0xc
    80001dc8:	1684b503          	ld	a0,360(s1)
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	560080e7          	jalr	1376(ra) # 8000132c <kvmmap>
  p->kstack = va; // 记录内核栈的逻辑地址，其实已经是固定的了，依然这样记录是为了避免需要修改其他部分 xv6 代码
    80001dd4:	0932                	slli	s2,s2,0xc
    80001dd6:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001dda:	07000613          	li	a2,112
    80001dde:	4581                	li	a1,0
    80001de0:	06048513          	addi	a0,s1,96
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	f36080e7          	jalr	-202(ra) # 80000d1a <memset>
  p->context.ra = (uint64)forkret;
    80001dec:	00000797          	auipc	a5,0x0
    80001df0:	d5278793          	addi	a5,a5,-686 # 80001b3e <forkret>
    80001df4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001df6:	60bc                	ld	a5,64(s1)
    80001df8:	6705                	lui	a4,0x1
    80001dfa:	97ba                	add	a5,a5,a4
    80001dfc:	f4bc                	sd	a5,104(s1)
}
    80001dfe:	8526                	mv	a0,s1
    80001e00:	60e2                	ld	ra,24(sp)
    80001e02:	6442                	ld	s0,16(sp)
    80001e04:	64a2                	ld	s1,8(sp)
    80001e06:	6902                	ld	s2,0(sp)
    80001e08:	6105                	addi	sp,sp,32
    80001e0a:	8082                	ret
    release(&p->lock);
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	ec4080e7          	jalr	-316(ra) # 80000cd2 <release>
    return 0;
    80001e16:	84ca                	mv	s1,s2
    80001e18:	b7dd                	j	80001dfe <allocproc+0xc4>
    freeproc(p);
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	00000097          	auipc	ra,0x0
    80001e20:	e9c080e7          	jalr	-356(ra) # 80001cb8 <freeproc>
    release(&p->lock);
    80001e24:	8526                	mv	a0,s1
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	eac080e7          	jalr	-340(ra) # 80000cd2 <release>
    return 0;
    80001e2e:	84ca                	mv	s1,s2
    80001e30:	b7f9                	j	80001dfe <allocproc+0xc4>
    panic("kalloc");
    80001e32:	00006517          	auipc	a0,0x6
    80001e36:	42650513          	addi	a0,a0,1062 # 80008258 <digits+0x228>
    80001e3a:	ffffe097          	auipc	ra,0xffffe
    80001e3e:	71c080e7          	jalr	1820(ra) # 80000556 <panic>

0000000080001e42 <userinit>:
{
    80001e42:	1101                	addi	sp,sp,-32
    80001e44:	ec06                	sd	ra,24(sp)
    80001e46:	e822                	sd	s0,16(sp)
    80001e48:	e426                	sd	s1,8(sp)
    80001e4a:	e04a                	sd	s2,0(sp)
    80001e4c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e4e:	00000097          	auipc	ra,0x0
    80001e52:	eec080e7          	jalr	-276(ra) # 80001d3a <allocproc>
    80001e56:	84aa                	mv	s1,a0
  initproc = p;
    80001e58:	00007797          	auipc	a5,0x7
    80001e5c:	1ca7b023          	sd	a0,448(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e60:	03400613          	li	a2,52
    80001e64:	00007597          	auipc	a1,0x7
    80001e68:	a6c58593          	addi	a1,a1,-1428 # 800088d0 <initcode>
    80001e6c:	6928                	ld	a0,80(a0)
    80001e6e:	fffff097          	auipc	ra,0xfffff
    80001e72:	7fa080e7          	jalr	2042(ra) # 80001668 <uvminit>
  p->sz = PGSIZE;
    80001e76:	6905                	lui	s2,0x1
    80001e78:	0524b423          	sd	s2,72(s1)
  kvmcopymappings(p->pagetable, p->kernelpgtbl, 0, p->sz); // 同步程序内存映射到进程内核页表中
    80001e7c:	6685                	lui	a3,0x1
    80001e7e:	4601                	li	a2,0
    80001e80:	1684b583          	ld	a1,360(s1)
    80001e84:	68a8                	ld	a0,80(s1)
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	6b8080e7          	jalr	1720(ra) # 8000153e <kvmcopymappings>
  p->trapframe->epc = 0;      // user program counter
    80001e8e:	6cbc                	ld	a5,88(s1)
    80001e90:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e94:	6cbc                	ld	a5,88(s1)
    80001e96:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e9a:	4641                	li	a2,16
    80001e9c:	00006597          	auipc	a1,0x6
    80001ea0:	3c458593          	addi	a1,a1,964 # 80008260 <digits+0x230>
    80001ea4:	15848513          	addi	a0,s1,344
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	fc8080e7          	jalr	-56(ra) # 80000e70 <safestrcpy>
  p->cwd = namei("/");
    80001eb0:	00006517          	auipc	a0,0x6
    80001eb4:	3c050513          	addi	a0,a0,960 # 80008270 <digits+0x240>
    80001eb8:	00002097          	auipc	ra,0x2
    80001ebc:	146080e7          	jalr	326(ra) # 80003ffe <namei>
    80001ec0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ec4:	4789                	li	a5,2
    80001ec6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	e08080e7          	jalr	-504(ra) # 80000cd2 <release>
}
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6902                	ld	s2,0(sp)
    80001eda:	6105                	addi	sp,sp,32
    80001edc:	8082                	ret

0000000080001ede <growproc>:
{
    80001ede:	7179                	addi	sp,sp,-48
    80001ee0:	f406                	sd	ra,40(sp)
    80001ee2:	f022                	sd	s0,32(sp)
    80001ee4:	ec26                	sd	s1,24(sp)
    80001ee6:	e84a                	sd	s2,16(sp)
    80001ee8:	e44e                	sd	s3,8(sp)
    80001eea:	e052                	sd	s4,0(sp)
    80001eec:	1800                	addi	s0,sp,48
    80001eee:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001ef0:	00000097          	auipc	ra,0x0
    80001ef4:	c16080e7          	jalr	-1002(ra) # 80001b06 <myproc>
    80001ef8:	84aa                	mv	s1,a0
  sz = p->sz;
    80001efa:	652c                	ld	a1,72(a0)
    80001efc:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f00:	03204363          	bgtz	s2,80001f26 <growproc+0x48>
  } else if(n < 0){
    80001f04:	06094663          	bltz	s2,80001f70 <growproc+0x92>
  p->sz = sz;
    80001f08:	02061913          	slli	s2,a2,0x20
    80001f0c:	02095913          	srli	s2,s2,0x20
    80001f10:	0524b423          	sd	s2,72(s1)
  return 0;
    80001f14:	4501                	li	a0,0
}
    80001f16:	70a2                	ld	ra,40(sp)
    80001f18:	7402                	ld	s0,32(sp)
    80001f1a:	64e2                	ld	s1,24(sp)
    80001f1c:	6942                	ld	s2,16(sp)
    80001f1e:	69a2                	ld	s3,8(sp)
    80001f20:	6a02                	ld	s4,0(sp)
    80001f22:	6145                	addi	sp,sp,48
    80001f24:	8082                	ret
    if((newsz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f26:	02059993          	slli	s3,a1,0x20
    80001f2a:	0209d993          	srli	s3,s3,0x20
    80001f2e:	00c9063b          	addw	a2,s2,a2
    80001f32:	1602                	slli	a2,a2,0x20
    80001f34:	9201                	srli	a2,a2,0x20
    80001f36:	85ce                	mv	a1,s3
    80001f38:	6928                	ld	a0,80(a0)
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	7e8080e7          	jalr	2024(ra) # 80001722 <uvmalloc>
    80001f42:	8a2a                	mv	s4,a0
    80001f44:	c12d                	beqz	a0,80001fa6 <growproc+0xc8>
    if(kvmcopymappings(p->pagetable, p->kernelpgtbl, sz, n) != 0) {
    80001f46:	86ca                	mv	a3,s2
    80001f48:	864e                	mv	a2,s3
    80001f4a:	1684b583          	ld	a1,360(s1)
    80001f4e:	68a8                	ld	a0,80(s1)
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	5ee080e7          	jalr	1518(ra) # 8000153e <kvmcopymappings>
    sz = newsz;
    80001f58:	000a061b          	sext.w	a2,s4
    if(kvmcopymappings(p->pagetable, p->kernelpgtbl, sz, n) != 0) {
    80001f5c:	d555                	beqz	a0,80001f08 <growproc+0x2a>
      uvmdealloc(p->pagetable, newsz, sz);
    80001f5e:	864e                	mv	a2,s3
    80001f60:	85d2                	mv	a1,s4
    80001f62:	68a8                	ld	a0,80(s1)
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	776080e7          	jalr	1910(ra) # 800016da <uvmdealloc>
      return -1;
    80001f6c:	557d                	li	a0,-1
    80001f6e:	b765                	j	80001f16 <growproc+0x38>
    uvmdealloc(p->pagetable, sz, sz + n);
    80001f70:	02059993          	slli	s3,a1,0x20
    80001f74:	0209d993          	srli	s3,s3,0x20
    80001f78:	00c9093b          	addw	s2,s2,a2
    80001f7c:	1902                	slli	s2,s2,0x20
    80001f7e:	02095913          	srli	s2,s2,0x20
    80001f82:	864a                	mv	a2,s2
    80001f84:	85ce                	mv	a1,s3
    80001f86:	6928                	ld	a0,80(a0)
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	752080e7          	jalr	1874(ra) # 800016da <uvmdealloc>
    sz = kvmdealloc(p->kernelpgtbl, sz, sz + n);
    80001f90:	864a                	mv	a2,s2
    80001f92:	85ce                	mv	a1,s3
    80001f94:	1684b503          	ld	a0,360(s1)
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	65a080e7          	jalr	1626(ra) # 800015f2 <kvmdealloc>
    80001fa0:	0005061b          	sext.w	a2,a0
    80001fa4:	b795                	j	80001f08 <growproc+0x2a>
      return -1;
    80001fa6:	557d                	li	a0,-1
    80001fa8:	b7bd                	j	80001f16 <growproc+0x38>

0000000080001faa <fork>:
{
    80001faa:	7179                	addi	sp,sp,-48
    80001fac:	f406                	sd	ra,40(sp)
    80001fae:	f022                	sd	s0,32(sp)
    80001fb0:	ec26                	sd	s1,24(sp)
    80001fb2:	e84a                	sd	s2,16(sp)
    80001fb4:	e44e                	sd	s3,8(sp)
    80001fb6:	e052                	sd	s4,0(sp)
    80001fb8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fba:	00000097          	auipc	ra,0x0
    80001fbe:	b4c080e7          	jalr	-1204(ra) # 80001b06 <myproc>
    80001fc2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001fc4:	00000097          	auipc	ra,0x0
    80001fc8:	d76080e7          	jalr	-650(ra) # 80001d3a <allocproc>
    80001fcc:	10050063          	beqz	a0,800020cc <fork+0x122>
    80001fd0:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001fd2:	04893603          	ld	a2,72(s2) # 1048 <_entry-0x7fffefb8>
    80001fd6:	692c                	ld	a1,80(a0)
    80001fd8:	05093503          	ld	a0,80(s2)
    80001fdc:	00000097          	auipc	ra,0x0
    80001fe0:	892080e7          	jalr	-1902(ra) # 8000186e <uvmcopy>
    80001fe4:	06054563          	bltz	a0,8000204e <fork+0xa4>
      kvmcopymappings(np->pagetable, np->kernelpgtbl, 0, p->sz) < 0){
    80001fe8:	04893683          	ld	a3,72(s2)
    80001fec:	4601                	li	a2,0
    80001fee:	1689b583          	ld	a1,360(s3)
    80001ff2:	0509b503          	ld	a0,80(s3)
    80001ff6:	fffff097          	auipc	ra,0xfffff
    80001ffa:	548080e7          	jalr	1352(ra) # 8000153e <kvmcopymappings>
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0 ||
    80001ffe:	04054863          	bltz	a0,8000204e <fork+0xa4>
  np->sz = p->sz;
    80002002:	04893783          	ld	a5,72(s2)
    80002006:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    8000200a:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    8000200e:	05893683          	ld	a3,88(s2)
    80002012:	87b6                	mv	a5,a3
    80002014:	0589b703          	ld	a4,88(s3)
    80002018:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    8000201c:	0007b803          	ld	a6,0(a5)
    80002020:	6788                	ld	a0,8(a5)
    80002022:	6b8c                	ld	a1,16(a5)
    80002024:	6f90                	ld	a2,24(a5)
    80002026:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    8000202a:	e708                	sd	a0,8(a4)
    8000202c:	eb0c                	sd	a1,16(a4)
    8000202e:	ef10                	sd	a2,24(a4)
    80002030:	02078793          	addi	a5,a5,32
    80002034:	02070713          	addi	a4,a4,32
    80002038:	fed792e3          	bne	a5,a3,8000201c <fork+0x72>
  np->trapframe->a0 = 0;
    8000203c:	0589b783          	ld	a5,88(s3)
    80002040:	0607b823          	sd	zero,112(a5)
    80002044:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002048:	15000a13          	li	s4,336
    8000204c:	a03d                	j	8000207a <fork+0xd0>
    freeproc(np);
    8000204e:	854e                	mv	a0,s3
    80002050:	00000097          	auipc	ra,0x0
    80002054:	c68080e7          	jalr	-920(ra) # 80001cb8 <freeproc>
    release(&np->lock);
    80002058:	854e                	mv	a0,s3
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	c78080e7          	jalr	-904(ra) # 80000cd2 <release>
    return -1;
    80002062:	54fd                	li	s1,-1
    80002064:	a899                	j	800020ba <fork+0x110>
      np->ofile[i] = filedup(p->ofile[i]);
    80002066:	00002097          	auipc	ra,0x2
    8000206a:	624080e7          	jalr	1572(ra) # 8000468a <filedup>
    8000206e:	009987b3          	add	a5,s3,s1
    80002072:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002074:	04a1                	addi	s1,s1,8
    80002076:	01448763          	beq	s1,s4,80002084 <fork+0xda>
    if(p->ofile[i])
    8000207a:	009907b3          	add	a5,s2,s1
    8000207e:	6388                	ld	a0,0(a5)
    80002080:	f17d                	bnez	a0,80002066 <fork+0xbc>
    80002082:	bfcd                	j	80002074 <fork+0xca>
  np->cwd = idup(p->cwd);
    80002084:	15093503          	ld	a0,336(s2)
    80002088:	00001097          	auipc	ra,0x1
    8000208c:	788080e7          	jalr	1928(ra) # 80003810 <idup>
    80002090:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002094:	4641                	li	a2,16
    80002096:	15890593          	addi	a1,s2,344
    8000209a:	15898513          	addi	a0,s3,344
    8000209e:	fffff097          	auipc	ra,0xfffff
    800020a2:	dd2080e7          	jalr	-558(ra) # 80000e70 <safestrcpy>
  pid = np->pid;
    800020a6:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800020aa:	4789                	li	a5,2
    800020ac:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800020b0:	854e                	mv	a0,s3
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	c20080e7          	jalr	-992(ra) # 80000cd2 <release>
}
    800020ba:	8526                	mv	a0,s1
    800020bc:	70a2                	ld	ra,40(sp)
    800020be:	7402                	ld	s0,32(sp)
    800020c0:	64e2                	ld	s1,24(sp)
    800020c2:	6942                	ld	s2,16(sp)
    800020c4:	69a2                	ld	s3,8(sp)
    800020c6:	6a02                	ld	s4,0(sp)
    800020c8:	6145                	addi	sp,sp,48
    800020ca:	8082                	ret
    return -1;
    800020cc:	54fd                	li	s1,-1
    800020ce:	b7f5                	j	800020ba <fork+0x110>

00000000800020d0 <reparent>:
{
    800020d0:	7179                	addi	sp,sp,-48
    800020d2:	f406                	sd	ra,40(sp)
    800020d4:	f022                	sd	s0,32(sp)
    800020d6:	ec26                	sd	s1,24(sp)
    800020d8:	e84a                	sd	s2,16(sp)
    800020da:	e44e                	sd	s3,8(sp)
    800020dc:	e052                	sd	s4,0(sp)
    800020de:	1800                	addi	s0,sp,48
    800020e0:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020e2:	00010497          	auipc	s1,0x10
    800020e6:	c8648493          	addi	s1,s1,-890 # 80011d68 <proc>
      pp->parent = initproc;
    800020ea:	00007a17          	auipc	s4,0x7
    800020ee:	f2ea0a13          	addi	s4,s4,-210 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800020f2:	00016997          	auipc	s3,0x16
    800020f6:	87698993          	addi	s3,s3,-1930 # 80017968 <tickslock>
    800020fa:	a029                	j	80002104 <reparent+0x34>
    800020fc:	17048493          	addi	s1,s1,368
    80002100:	03348363          	beq	s1,s3,80002126 <reparent+0x56>
    if(pp->parent == p){
    80002104:	709c                	ld	a5,32(s1)
    80002106:	ff279be3          	bne	a5,s2,800020fc <reparent+0x2c>
      acquire(&pp->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	b12080e7          	jalr	-1262(ra) # 80000c1e <acquire>
      pp->parent = initproc;
    80002114:	000a3783          	ld	a5,0(s4)
    80002118:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	bb6080e7          	jalr	-1098(ra) # 80000cd2 <release>
    80002124:	bfe1                	j	800020fc <reparent+0x2c>
}
    80002126:	70a2                	ld	ra,40(sp)
    80002128:	7402                	ld	s0,32(sp)
    8000212a:	64e2                	ld	s1,24(sp)
    8000212c:	6942                	ld	s2,16(sp)
    8000212e:	69a2                	ld	s3,8(sp)
    80002130:	6a02                	ld	s4,0(sp)
    80002132:	6145                	addi	sp,sp,48
    80002134:	8082                	ret

0000000080002136 <scheduler>:
{
    80002136:	715d                	addi	sp,sp,-80
    80002138:	e486                	sd	ra,72(sp)
    8000213a:	e0a2                	sd	s0,64(sp)
    8000213c:	fc26                	sd	s1,56(sp)
    8000213e:	f84a                	sd	s2,48(sp)
    80002140:	f44e                	sd	s3,40(sp)
    80002142:	f052                	sd	s4,32(sp)
    80002144:	ec56                	sd	s5,24(sp)
    80002146:	e85a                	sd	s6,16(sp)
    80002148:	e45e                	sd	s7,8(sp)
    8000214a:	e062                	sd	s8,0(sp)
    8000214c:	0880                	addi	s0,sp,80
    8000214e:	8792                	mv	a5,tp
  int id = r_tp();
    80002150:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002152:	00779b13          	slli	s6,a5,0x7
    80002156:	0000f717          	auipc	a4,0xf
    8000215a:	7fa70713          	addi	a4,a4,2042 # 80011950 <pid_lock>
    8000215e:	975a                	add	a4,a4,s6
    80002160:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002164:	00010717          	auipc	a4,0x10
    80002168:	80c70713          	addi	a4,a4,-2036 # 80011970 <cpus+0x8>
    8000216c:	9b3a                	add	s6,s6,a4
        c->proc = p;
    8000216e:	079e                	slli	a5,a5,0x7
    80002170:	0000fa17          	auipc	s4,0xf
    80002174:	7e0a0a13          	addi	s4,s4,2016 # 80011950 <pid_lock>
    80002178:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kernelpgtbl));
    8000217a:	5bfd                	li	s7,-1
    8000217c:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    8000217e:	00015997          	auipc	s3,0x15
    80002182:	7ea98993          	addi	s3,s3,2026 # 80017968 <tickslock>
    80002186:	a885                	j	800021f6 <scheduler+0xc0>
        p->state = RUNNING;
    80002188:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    8000218c:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kernelpgtbl));
    80002190:	1684b783          	ld	a5,360(s1)
    80002194:	83b1                	srli	a5,a5,0xc
    80002196:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    8000219a:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000219e:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800021a2:	06048593          	addi	a1,s1,96
    800021a6:	855a                	mv	a0,s6
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	642080e7          	jalr	1602(ra) # 800027ea <swtch>
        kvminithart();
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	f8c080e7          	jalr	-116(ra) # 8000113c <kvminithart>
        c->proc = 0;
    800021b8:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800021bc:	4c05                	li	s8,1
      release(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	b12080e7          	jalr	-1262(ra) # 80000cd2 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021c8:	17048493          	addi	s1,s1,368
    800021cc:	01348b63          	beq	s1,s3,800021e2 <scheduler+0xac>
      acquire(&p->lock);
    800021d0:	8526                	mv	a0,s1
    800021d2:	fffff097          	auipc	ra,0xfffff
    800021d6:	a4c080e7          	jalr	-1460(ra) # 80000c1e <acquire>
      if(p->state == RUNNABLE) {
    800021da:	4c9c                	lw	a5,24(s1)
    800021dc:	ff2791e3          	bne	a5,s2,800021be <scheduler+0x88>
    800021e0:	b765                	j	80002188 <scheduler+0x52>
    if(found == 0) {
    800021e2:	000c1a63          	bnez	s8,800021f6 <scheduler+0xc0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021e6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021ea:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021ee:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800021f2:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021f6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021fa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021fe:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002202:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002204:	00010497          	auipc	s1,0x10
    80002208:	b6448493          	addi	s1,s1,-1180 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000220c:	4909                	li	s2,2
        p->state = RUNNING;
    8000220e:	4a8d                	li	s5,3
    80002210:	b7c1                	j	800021d0 <scheduler+0x9a>

0000000080002212 <sched>:
{
    80002212:	7179                	addi	sp,sp,-48
    80002214:	f406                	sd	ra,40(sp)
    80002216:	f022                	sd	s0,32(sp)
    80002218:	ec26                	sd	s1,24(sp)
    8000221a:	e84a                	sd	s2,16(sp)
    8000221c:	e44e                	sd	s3,8(sp)
    8000221e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002220:	00000097          	auipc	ra,0x0
    80002224:	8e6080e7          	jalr	-1818(ra) # 80001b06 <myproc>
    80002228:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	97a080e7          	jalr	-1670(ra) # 80000ba4 <holding>
    80002232:	c93d                	beqz	a0,800022a8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002234:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002236:	2781                	sext.w	a5,a5
    80002238:	079e                	slli	a5,a5,0x7
    8000223a:	0000f717          	auipc	a4,0xf
    8000223e:	71670713          	addi	a4,a4,1814 # 80011950 <pid_lock>
    80002242:	97ba                	add	a5,a5,a4
    80002244:	0907a703          	lw	a4,144(a5)
    80002248:	4785                	li	a5,1
    8000224a:	06f71763          	bne	a4,a5,800022b8 <sched+0xa6>
  if(p->state == RUNNING)
    8000224e:	4c98                	lw	a4,24(s1)
    80002250:	478d                	li	a5,3
    80002252:	06f70b63          	beq	a4,a5,800022c8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002256:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000225a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000225c:	efb5                	bnez	a5,800022d8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000225e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002260:	0000f917          	auipc	s2,0xf
    80002264:	6f090913          	addi	s2,s2,1776 # 80011950 <pid_lock>
    80002268:	2781                	sext.w	a5,a5
    8000226a:	079e                	slli	a5,a5,0x7
    8000226c:	97ca                	add	a5,a5,s2
    8000226e:	0947a983          	lw	s3,148(a5)
    80002272:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002274:	2781                	sext.w	a5,a5
    80002276:	079e                	slli	a5,a5,0x7
    80002278:	0000f597          	auipc	a1,0xf
    8000227c:	6f858593          	addi	a1,a1,1784 # 80011970 <cpus+0x8>
    80002280:	95be                	add	a1,a1,a5
    80002282:	06048513          	addi	a0,s1,96
    80002286:	00000097          	auipc	ra,0x0
    8000228a:	564080e7          	jalr	1380(ra) # 800027ea <swtch>
    8000228e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002290:	2781                	sext.w	a5,a5
    80002292:	079e                	slli	a5,a5,0x7
    80002294:	97ca                	add	a5,a5,s2
    80002296:	0937aa23          	sw	s3,148(a5)
}
    8000229a:	70a2                	ld	ra,40(sp)
    8000229c:	7402                	ld	s0,32(sp)
    8000229e:	64e2                	ld	s1,24(sp)
    800022a0:	6942                	ld	s2,16(sp)
    800022a2:	69a2                	ld	s3,8(sp)
    800022a4:	6145                	addi	sp,sp,48
    800022a6:	8082                	ret
    panic("sched p->lock");
    800022a8:	00006517          	auipc	a0,0x6
    800022ac:	fd050513          	addi	a0,a0,-48 # 80008278 <digits+0x248>
    800022b0:	ffffe097          	auipc	ra,0xffffe
    800022b4:	2a6080e7          	jalr	678(ra) # 80000556 <panic>
    panic("sched locks");
    800022b8:	00006517          	auipc	a0,0x6
    800022bc:	fd050513          	addi	a0,a0,-48 # 80008288 <digits+0x258>
    800022c0:	ffffe097          	auipc	ra,0xffffe
    800022c4:	296080e7          	jalr	662(ra) # 80000556 <panic>
    panic("sched running");
    800022c8:	00006517          	auipc	a0,0x6
    800022cc:	fd050513          	addi	a0,a0,-48 # 80008298 <digits+0x268>
    800022d0:	ffffe097          	auipc	ra,0xffffe
    800022d4:	286080e7          	jalr	646(ra) # 80000556 <panic>
    panic("sched interruptible");
    800022d8:	00006517          	auipc	a0,0x6
    800022dc:	fd050513          	addi	a0,a0,-48 # 800082a8 <digits+0x278>
    800022e0:	ffffe097          	auipc	ra,0xffffe
    800022e4:	276080e7          	jalr	630(ra) # 80000556 <panic>

00000000800022e8 <exit>:
{
    800022e8:	7179                	addi	sp,sp,-48
    800022ea:	f406                	sd	ra,40(sp)
    800022ec:	f022                	sd	s0,32(sp)
    800022ee:	ec26                	sd	s1,24(sp)
    800022f0:	e84a                	sd	s2,16(sp)
    800022f2:	e44e                	sd	s3,8(sp)
    800022f4:	e052                	sd	s4,0(sp)
    800022f6:	1800                	addi	s0,sp,48
    800022f8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022fa:	00000097          	auipc	ra,0x0
    800022fe:	80c080e7          	jalr	-2036(ra) # 80001b06 <myproc>
    80002302:	89aa                	mv	s3,a0
  if(p == initproc)
    80002304:	00007797          	auipc	a5,0x7
    80002308:	d147b783          	ld	a5,-748(a5) # 80009018 <initproc>
    8000230c:	0d050493          	addi	s1,a0,208
    80002310:	15050913          	addi	s2,a0,336
    80002314:	02a79363          	bne	a5,a0,8000233a <exit+0x52>
    panic("init exiting");
    80002318:	00006517          	auipc	a0,0x6
    8000231c:	fa850513          	addi	a0,a0,-88 # 800082c0 <digits+0x290>
    80002320:	ffffe097          	auipc	ra,0xffffe
    80002324:	236080e7          	jalr	566(ra) # 80000556 <panic>
      fileclose(f);
    80002328:	00002097          	auipc	ra,0x2
    8000232c:	3b4080e7          	jalr	948(ra) # 800046dc <fileclose>
      p->ofile[fd] = 0;
    80002330:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002334:	04a1                	addi	s1,s1,8
    80002336:	01248563          	beq	s1,s2,80002340 <exit+0x58>
    if(p->ofile[fd]){
    8000233a:	6088                	ld	a0,0(s1)
    8000233c:	f575                	bnez	a0,80002328 <exit+0x40>
    8000233e:	bfdd                	j	80002334 <exit+0x4c>
  begin_op();
    80002340:	00002097          	auipc	ra,0x2
    80002344:	eca080e7          	jalr	-310(ra) # 8000420a <begin_op>
  iput(p->cwd);
    80002348:	1509b503          	ld	a0,336(s3)
    8000234c:	00001097          	auipc	ra,0x1
    80002350:	6bc080e7          	jalr	1724(ra) # 80003a08 <iput>
  end_op();
    80002354:	00002097          	auipc	ra,0x2
    80002358:	f36080e7          	jalr	-202(ra) # 8000428a <end_op>
  p->cwd = 0;
    8000235c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002360:	00007497          	auipc	s1,0x7
    80002364:	cb848493          	addi	s1,s1,-840 # 80009018 <initproc>
    80002368:	6088                	ld	a0,0(s1)
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	8b4080e7          	jalr	-1868(ra) # 80000c1e <acquire>
  wakeup1(initproc);
    80002372:	6088                	ld	a0,0(s1)
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	6ba080e7          	jalr	1722(ra) # 80001a2e <wakeup1>
  release(&initproc->lock);
    8000237c:	6088                	ld	a0,0(s1)
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	954080e7          	jalr	-1708(ra) # 80000cd2 <release>
  acquire(&p->lock);
    80002386:	854e                	mv	a0,s3
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	896080e7          	jalr	-1898(ra) # 80000c1e <acquire>
  struct proc *original_parent = p->parent;
    80002390:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002394:	854e                	mv	a0,s3
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	93c080e7          	jalr	-1732(ra) # 80000cd2 <release>
  acquire(&original_parent->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	87e080e7          	jalr	-1922(ra) # 80000c1e <acquire>
  acquire(&p->lock);
    800023a8:	854e                	mv	a0,s3
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	874080e7          	jalr	-1932(ra) # 80000c1e <acquire>
  reparent(p);
    800023b2:	854e                	mv	a0,s3
    800023b4:	00000097          	auipc	ra,0x0
    800023b8:	d1c080e7          	jalr	-740(ra) # 800020d0 <reparent>
  wakeup1(original_parent);
    800023bc:	8526                	mv	a0,s1
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	670080e7          	jalr	1648(ra) # 80001a2e <wakeup1>
  p->xstate = status;
    800023c6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800023ca:	4791                	li	a5,4
    800023cc:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	900080e7          	jalr	-1792(ra) # 80000cd2 <release>
  sched();
    800023da:	00000097          	auipc	ra,0x0
    800023de:	e38080e7          	jalr	-456(ra) # 80002212 <sched>
  panic("zombie exit");
    800023e2:	00006517          	auipc	a0,0x6
    800023e6:	eee50513          	addi	a0,a0,-274 # 800082d0 <digits+0x2a0>
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	16c080e7          	jalr	364(ra) # 80000556 <panic>

00000000800023f2 <yield>:
{
    800023f2:	1101                	addi	sp,sp,-32
    800023f4:	ec06                	sd	ra,24(sp)
    800023f6:	e822                	sd	s0,16(sp)
    800023f8:	e426                	sd	s1,8(sp)
    800023fa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	70a080e7          	jalr	1802(ra) # 80001b06 <myproc>
    80002404:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	818080e7          	jalr	-2024(ra) # 80000c1e <acquire>
  p->state = RUNNABLE;
    8000240e:	4789                	li	a5,2
    80002410:	cc9c                	sw	a5,24(s1)
  sched();
    80002412:	00000097          	auipc	ra,0x0
    80002416:	e00080e7          	jalr	-512(ra) # 80002212 <sched>
  release(&p->lock);
    8000241a:	8526                	mv	a0,s1
    8000241c:	fffff097          	auipc	ra,0xfffff
    80002420:	8b6080e7          	jalr	-1866(ra) # 80000cd2 <release>
}
    80002424:	60e2                	ld	ra,24(sp)
    80002426:	6442                	ld	s0,16(sp)
    80002428:	64a2                	ld	s1,8(sp)
    8000242a:	6105                	addi	sp,sp,32
    8000242c:	8082                	ret

000000008000242e <sleep>:
{
    8000242e:	7179                	addi	sp,sp,-48
    80002430:	f406                	sd	ra,40(sp)
    80002432:	f022                	sd	s0,32(sp)
    80002434:	ec26                	sd	s1,24(sp)
    80002436:	e84a                	sd	s2,16(sp)
    80002438:	e44e                	sd	s3,8(sp)
    8000243a:	1800                	addi	s0,sp,48
    8000243c:	89aa                	mv	s3,a0
    8000243e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	6c6080e7          	jalr	1734(ra) # 80001b06 <myproc>
    80002448:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000244a:	05250663          	beq	a0,s2,80002496 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	7d0080e7          	jalr	2000(ra) # 80000c1e <acquire>
    release(lk);
    80002456:	854a                	mv	a0,s2
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	87a080e7          	jalr	-1926(ra) # 80000cd2 <release>
  p->chan = chan;
    80002460:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002464:	4785                	li	a5,1
    80002466:	cc9c                	sw	a5,24(s1)
  sched();
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	daa080e7          	jalr	-598(ra) # 80002212 <sched>
  p->chan = 0;
    80002470:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	85c080e7          	jalr	-1956(ra) # 80000cd2 <release>
    acquire(lk);
    8000247e:	854a                	mv	a0,s2
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	79e080e7          	jalr	1950(ra) # 80000c1e <acquire>
}
    80002488:	70a2                	ld	ra,40(sp)
    8000248a:	7402                	ld	s0,32(sp)
    8000248c:	64e2                	ld	s1,24(sp)
    8000248e:	6942                	ld	s2,16(sp)
    80002490:	69a2                	ld	s3,8(sp)
    80002492:	6145                	addi	sp,sp,48
    80002494:	8082                	ret
  p->chan = chan;
    80002496:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000249a:	4785                	li	a5,1
    8000249c:	cd1c                	sw	a5,24(a0)
  sched();
    8000249e:	00000097          	auipc	ra,0x0
    800024a2:	d74080e7          	jalr	-652(ra) # 80002212 <sched>
  p->chan = 0;
    800024a6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800024aa:	bff9                	j	80002488 <sleep+0x5a>

00000000800024ac <wait>:
{
    800024ac:	715d                	addi	sp,sp,-80
    800024ae:	e486                	sd	ra,72(sp)
    800024b0:	e0a2                	sd	s0,64(sp)
    800024b2:	fc26                	sd	s1,56(sp)
    800024b4:	f84a                	sd	s2,48(sp)
    800024b6:	f44e                	sd	s3,40(sp)
    800024b8:	f052                	sd	s4,32(sp)
    800024ba:	ec56                	sd	s5,24(sp)
    800024bc:	e85a                	sd	s6,16(sp)
    800024be:	e45e                	sd	s7,8(sp)
    800024c0:	e062                	sd	s8,0(sp)
    800024c2:	0880                	addi	s0,sp,80
    800024c4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024c6:	fffff097          	auipc	ra,0xfffff
    800024ca:	640080e7          	jalr	1600(ra) # 80001b06 <myproc>
    800024ce:	892a                	mv	s2,a0
  acquire(&p->lock);
    800024d0:	8c2a                	mv	s8,a0
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	74c080e7          	jalr	1868(ra) # 80000c1e <acquire>
    havekids = 0;
    800024da:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800024dc:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800024de:	00015997          	auipc	s3,0x15
    800024e2:	48a98993          	addi	s3,s3,1162 # 80017968 <tickslock>
        havekids = 1;
    800024e6:	4a85                	li	s5,1
    havekids = 0;
    800024e8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800024ea:	00010497          	auipc	s1,0x10
    800024ee:	87e48493          	addi	s1,s1,-1922 # 80011d68 <proc>
    800024f2:	a08d                	j	80002554 <wait+0xa8>
          pid = np->pid;
    800024f4:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800024f8:	000b0e63          	beqz	s6,80002514 <wait+0x68>
    800024fc:	4691                	li	a3,4
    800024fe:	03448613          	addi	a2,s1,52
    80002502:	85da                	mv	a1,s6
    80002504:	05093503          	ld	a0,80(s2)
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	46a080e7          	jalr	1130(ra) # 80001972 <copyout>
    80002510:	02054263          	bltz	a0,80002534 <wait+0x88>
          freeproc(np);
    80002514:	8526                	mv	a0,s1
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	7a2080e7          	jalr	1954(ra) # 80001cb8 <freeproc>
          release(&np->lock);
    8000251e:	8526                	mv	a0,s1
    80002520:	ffffe097          	auipc	ra,0xffffe
    80002524:	7b2080e7          	jalr	1970(ra) # 80000cd2 <release>
          release(&p->lock);
    80002528:	854a                	mv	a0,s2
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	7a8080e7          	jalr	1960(ra) # 80000cd2 <release>
          return pid;
    80002532:	a8a9                	j	8000258c <wait+0xe0>
            release(&np->lock);
    80002534:	8526                	mv	a0,s1
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	79c080e7          	jalr	1948(ra) # 80000cd2 <release>
            release(&p->lock);
    8000253e:	854a                	mv	a0,s2
    80002540:	ffffe097          	auipc	ra,0xffffe
    80002544:	792080e7          	jalr	1938(ra) # 80000cd2 <release>
            return -1;
    80002548:	59fd                	li	s3,-1
    8000254a:	a089                	j	8000258c <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000254c:	17048493          	addi	s1,s1,368
    80002550:	03348463          	beq	s1,s3,80002578 <wait+0xcc>
      if(np->parent == p){
    80002554:	709c                	ld	a5,32(s1)
    80002556:	ff279be3          	bne	a5,s2,8000254c <wait+0xa0>
        acquire(&np->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	6c2080e7          	jalr	1730(ra) # 80000c1e <acquire>
        if(np->state == ZOMBIE){
    80002564:	4c9c                	lw	a5,24(s1)
    80002566:	f94787e3          	beq	a5,s4,800024f4 <wait+0x48>
        release(&np->lock);
    8000256a:	8526                	mv	a0,s1
    8000256c:	ffffe097          	auipc	ra,0xffffe
    80002570:	766080e7          	jalr	1894(ra) # 80000cd2 <release>
        havekids = 1;
    80002574:	8756                	mv	a4,s5
    80002576:	bfd9                	j	8000254c <wait+0xa0>
    if(!havekids || p->killed){
    80002578:	c701                	beqz	a4,80002580 <wait+0xd4>
    8000257a:	03092783          	lw	a5,48(s2)
    8000257e:	c785                	beqz	a5,800025a6 <wait+0xfa>
      release(&p->lock);
    80002580:	854a                	mv	a0,s2
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	750080e7          	jalr	1872(ra) # 80000cd2 <release>
      return -1;
    8000258a:	59fd                	li	s3,-1
}
    8000258c:	854e                	mv	a0,s3
    8000258e:	60a6                	ld	ra,72(sp)
    80002590:	6406                	ld	s0,64(sp)
    80002592:	74e2                	ld	s1,56(sp)
    80002594:	7942                	ld	s2,48(sp)
    80002596:	79a2                	ld	s3,40(sp)
    80002598:	7a02                	ld	s4,32(sp)
    8000259a:	6ae2                	ld	s5,24(sp)
    8000259c:	6b42                	ld	s6,16(sp)
    8000259e:	6ba2                	ld	s7,8(sp)
    800025a0:	6c02                	ld	s8,0(sp)
    800025a2:	6161                	addi	sp,sp,80
    800025a4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800025a6:	85e2                	mv	a1,s8
    800025a8:	854a                	mv	a0,s2
    800025aa:	00000097          	auipc	ra,0x0
    800025ae:	e84080e7          	jalr	-380(ra) # 8000242e <sleep>
    havekids = 0;
    800025b2:	bf1d                	j	800024e8 <wait+0x3c>

00000000800025b4 <wakeup>:
{
    800025b4:	7139                	addi	sp,sp,-64
    800025b6:	fc06                	sd	ra,56(sp)
    800025b8:	f822                	sd	s0,48(sp)
    800025ba:	f426                	sd	s1,40(sp)
    800025bc:	f04a                	sd	s2,32(sp)
    800025be:	ec4e                	sd	s3,24(sp)
    800025c0:	e852                	sd	s4,16(sp)
    800025c2:	e456                	sd	s5,8(sp)
    800025c4:	0080                	addi	s0,sp,64
    800025c6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800025c8:	0000f497          	auipc	s1,0xf
    800025cc:	7a048493          	addi	s1,s1,1952 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800025d0:	4985                	li	s3,1
      p->state = RUNNABLE;
    800025d2:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800025d4:	00015917          	auipc	s2,0x15
    800025d8:	39490913          	addi	s2,s2,916 # 80017968 <tickslock>
    800025dc:	a821                	j	800025f4 <wakeup+0x40>
      p->state = RUNNABLE;
    800025de:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	6ee080e7          	jalr	1774(ra) # 80000cd2 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800025ec:	17048493          	addi	s1,s1,368
    800025f0:	01248e63          	beq	s1,s2,8000260c <wakeup+0x58>
    acquire(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	628080e7          	jalr	1576(ra) # 80000c1e <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800025fe:	4c9c                	lw	a5,24(s1)
    80002600:	ff3791e3          	bne	a5,s3,800025e2 <wakeup+0x2e>
    80002604:	749c                	ld	a5,40(s1)
    80002606:	fd479ee3          	bne	a5,s4,800025e2 <wakeup+0x2e>
    8000260a:	bfd1                	j	800025de <wakeup+0x2a>
}
    8000260c:	70e2                	ld	ra,56(sp)
    8000260e:	7442                	ld	s0,48(sp)
    80002610:	74a2                	ld	s1,40(sp)
    80002612:	7902                	ld	s2,32(sp)
    80002614:	69e2                	ld	s3,24(sp)
    80002616:	6a42                	ld	s4,16(sp)
    80002618:	6aa2                	ld	s5,8(sp)
    8000261a:	6121                	addi	sp,sp,64
    8000261c:	8082                	ret

000000008000261e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000261e:	7179                	addi	sp,sp,-48
    80002620:	f406                	sd	ra,40(sp)
    80002622:	f022                	sd	s0,32(sp)
    80002624:	ec26                	sd	s1,24(sp)
    80002626:	e84a                	sd	s2,16(sp)
    80002628:	e44e                	sd	s3,8(sp)
    8000262a:	1800                	addi	s0,sp,48
    8000262c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000262e:	0000f497          	auipc	s1,0xf
    80002632:	73a48493          	addi	s1,s1,1850 # 80011d68 <proc>
    80002636:	00015997          	auipc	s3,0x15
    8000263a:	33298993          	addi	s3,s3,818 # 80017968 <tickslock>
    acquire(&p->lock);
    8000263e:	8526                	mv	a0,s1
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	5de080e7          	jalr	1502(ra) # 80000c1e <acquire>
    if(p->pid == pid){
    80002648:	5c9c                	lw	a5,56(s1)
    8000264a:	01278d63          	beq	a5,s2,80002664 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	682080e7          	jalr	1666(ra) # 80000cd2 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002658:	17048493          	addi	s1,s1,368
    8000265c:	ff3491e3          	bne	s1,s3,8000263e <kill+0x20>
  }
  return -1;
    80002660:	557d                	li	a0,-1
    80002662:	a829                	j	8000267c <kill+0x5e>
      p->killed = 1;
    80002664:	4785                	li	a5,1
    80002666:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002668:	4c98                	lw	a4,24(s1)
    8000266a:	4785                	li	a5,1
    8000266c:	00f70f63          	beq	a4,a5,8000268a <kill+0x6c>
      release(&p->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	660080e7          	jalr	1632(ra) # 80000cd2 <release>
      return 0;
    8000267a:	4501                	li	a0,0
}
    8000267c:	70a2                	ld	ra,40(sp)
    8000267e:	7402                	ld	s0,32(sp)
    80002680:	64e2                	ld	s1,24(sp)
    80002682:	6942                	ld	s2,16(sp)
    80002684:	69a2                	ld	s3,8(sp)
    80002686:	6145                	addi	sp,sp,48
    80002688:	8082                	ret
        p->state = RUNNABLE;
    8000268a:	4789                	li	a5,2
    8000268c:	cc9c                	sw	a5,24(s1)
    8000268e:	b7cd                	j	80002670 <kill+0x52>

0000000080002690 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002690:	7179                	addi	sp,sp,-48
    80002692:	f406                	sd	ra,40(sp)
    80002694:	f022                	sd	s0,32(sp)
    80002696:	ec26                	sd	s1,24(sp)
    80002698:	e84a                	sd	s2,16(sp)
    8000269a:	e44e                	sd	s3,8(sp)
    8000269c:	e052                	sd	s4,0(sp)
    8000269e:	1800                	addi	s0,sp,48
    800026a0:	84aa                	mv	s1,a0
    800026a2:	892e                	mv	s2,a1
    800026a4:	89b2                	mv	s3,a2
    800026a6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026a8:	fffff097          	auipc	ra,0xfffff
    800026ac:	45e080e7          	jalr	1118(ra) # 80001b06 <myproc>
  if(user_dst){
    800026b0:	c08d                	beqz	s1,800026d2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026b2:	86d2                	mv	a3,s4
    800026b4:	864e                	mv	a2,s3
    800026b6:	85ca                	mv	a1,s2
    800026b8:	6928                	ld	a0,80(a0)
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	2b8080e7          	jalr	696(ra) # 80001972 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026c2:	70a2                	ld	ra,40(sp)
    800026c4:	7402                	ld	s0,32(sp)
    800026c6:	64e2                	ld	s1,24(sp)
    800026c8:	6942                	ld	s2,16(sp)
    800026ca:	69a2                	ld	s3,8(sp)
    800026cc:	6a02                	ld	s4,0(sp)
    800026ce:	6145                	addi	sp,sp,48
    800026d0:	8082                	ret
    memmove((char *)dst, src, len);
    800026d2:	000a061b          	sext.w	a2,s4
    800026d6:	85ce                	mv	a1,s3
    800026d8:	854a                	mv	a0,s2
    800026da:	ffffe097          	auipc	ra,0xffffe
    800026de:	6a0080e7          	jalr	1696(ra) # 80000d7a <memmove>
    return 0;
    800026e2:	8526                	mv	a0,s1
    800026e4:	bff9                	j	800026c2 <either_copyout+0x32>

00000000800026e6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026e6:	7179                	addi	sp,sp,-48
    800026e8:	f406                	sd	ra,40(sp)
    800026ea:	f022                	sd	s0,32(sp)
    800026ec:	ec26                	sd	s1,24(sp)
    800026ee:	e84a                	sd	s2,16(sp)
    800026f0:	e44e                	sd	s3,8(sp)
    800026f2:	e052                	sd	s4,0(sp)
    800026f4:	1800                	addi	s0,sp,48
    800026f6:	892a                	mv	s2,a0
    800026f8:	84ae                	mv	s1,a1
    800026fa:	89b2                	mv	s3,a2
    800026fc:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	408080e7          	jalr	1032(ra) # 80001b06 <myproc>
  if(user_src){
    80002706:	c08d                	beqz	s1,80002728 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002708:	86d2                	mv	a3,s4
    8000270a:	864e                	mv	a2,s3
    8000270c:	85ca                	mv	a1,s2
    8000270e:	6928                	ld	a0,80(a0)
    80002710:	fffff097          	auipc	ra,0xfffff
    80002714:	2ee080e7          	jalr	750(ra) # 800019fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002718:	70a2                	ld	ra,40(sp)
    8000271a:	7402                	ld	s0,32(sp)
    8000271c:	64e2                	ld	s1,24(sp)
    8000271e:	6942                	ld	s2,16(sp)
    80002720:	69a2                	ld	s3,8(sp)
    80002722:	6a02                	ld	s4,0(sp)
    80002724:	6145                	addi	sp,sp,48
    80002726:	8082                	ret
    memmove(dst, (char*)src, len);
    80002728:	000a061b          	sext.w	a2,s4
    8000272c:	85ce                	mv	a1,s3
    8000272e:	854a                	mv	a0,s2
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	64a080e7          	jalr	1610(ra) # 80000d7a <memmove>
    return 0;
    80002738:	8526                	mv	a0,s1
    8000273a:	bff9                	j	80002718 <either_copyin+0x32>

000000008000273c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000273c:	715d                	addi	sp,sp,-80
    8000273e:	e486                	sd	ra,72(sp)
    80002740:	e0a2                	sd	s0,64(sp)
    80002742:	fc26                	sd	s1,56(sp)
    80002744:	f84a                	sd	s2,48(sp)
    80002746:	f44e                	sd	s3,40(sp)
    80002748:	f052                	sd	s4,32(sp)
    8000274a:	ec56                	sd	s5,24(sp)
    8000274c:	e85a                	sd	s6,16(sp)
    8000274e:	e45e                	sd	s7,8(sp)
    80002750:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002752:	00006517          	auipc	a0,0x6
    80002756:	96650513          	addi	a0,a0,-1690 # 800080b8 <digits+0x88>
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	e46080e7          	jalr	-442(ra) # 800005a0 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002762:	0000f497          	auipc	s1,0xf
    80002766:	75e48493          	addi	s1,s1,1886 # 80011ec0 <proc+0x158>
    8000276a:	00015917          	auipc	s2,0x15
    8000276e:	35690913          	addi	s2,s2,854 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002772:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002774:	00006997          	auipc	s3,0x6
    80002778:	b6c98993          	addi	s3,s3,-1172 # 800082e0 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    8000277c:	00006a97          	auipc	s5,0x6
    80002780:	b6ca8a93          	addi	s5,s5,-1172 # 800082e8 <digits+0x2b8>
    printf("\n");
    80002784:	00006a17          	auipc	s4,0x6
    80002788:	934a0a13          	addi	s4,s4,-1740 # 800080b8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000278c:	00006b97          	auipc	s7,0x6
    80002790:	b94b8b93          	addi	s7,s7,-1132 # 80008320 <states.1736>
    80002794:	a00d                	j	800027b6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002796:	ee06a583          	lw	a1,-288(a3)
    8000279a:	8556                	mv	a0,s5
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	e04080e7          	jalr	-508(ra) # 800005a0 <printf>
    printf("\n");
    800027a4:	8552                	mv	a0,s4
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	dfa080e7          	jalr	-518(ra) # 800005a0 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027ae:	17048493          	addi	s1,s1,368
    800027b2:	03248163          	beq	s1,s2,800027d4 <procdump+0x98>
    if(p->state == UNUSED)
    800027b6:	86a6                	mv	a3,s1
    800027b8:	ec04a783          	lw	a5,-320(s1)
    800027bc:	dbed                	beqz	a5,800027ae <procdump+0x72>
      state = "???";
    800027be:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027c0:	fcfb6be3          	bltu	s6,a5,80002796 <procdump+0x5a>
    800027c4:	1782                	slli	a5,a5,0x20
    800027c6:	9381                	srli	a5,a5,0x20
    800027c8:	078e                	slli	a5,a5,0x3
    800027ca:	97de                	add	a5,a5,s7
    800027cc:	6390                	ld	a2,0(a5)
    800027ce:	f661                	bnez	a2,80002796 <procdump+0x5a>
      state = "???";
    800027d0:	864e                	mv	a2,s3
    800027d2:	b7d1                	j	80002796 <procdump+0x5a>
  }
}
    800027d4:	60a6                	ld	ra,72(sp)
    800027d6:	6406                	ld	s0,64(sp)
    800027d8:	74e2                	ld	s1,56(sp)
    800027da:	7942                	ld	s2,48(sp)
    800027dc:	79a2                	ld	s3,40(sp)
    800027de:	7a02                	ld	s4,32(sp)
    800027e0:	6ae2                	ld	s5,24(sp)
    800027e2:	6b42                	ld	s6,16(sp)
    800027e4:	6ba2                	ld	s7,8(sp)
    800027e6:	6161                	addi	sp,sp,80
    800027e8:	8082                	ret

00000000800027ea <swtch>:
    800027ea:	00153023          	sd	ra,0(a0)
    800027ee:	00253423          	sd	sp,8(a0)
    800027f2:	e900                	sd	s0,16(a0)
    800027f4:	ed04                	sd	s1,24(a0)
    800027f6:	03253023          	sd	s2,32(a0)
    800027fa:	03353423          	sd	s3,40(a0)
    800027fe:	03453823          	sd	s4,48(a0)
    80002802:	03553c23          	sd	s5,56(a0)
    80002806:	05653023          	sd	s6,64(a0)
    8000280a:	05753423          	sd	s7,72(a0)
    8000280e:	05853823          	sd	s8,80(a0)
    80002812:	05953c23          	sd	s9,88(a0)
    80002816:	07a53023          	sd	s10,96(a0)
    8000281a:	07b53423          	sd	s11,104(a0)
    8000281e:	0005b083          	ld	ra,0(a1)
    80002822:	0085b103          	ld	sp,8(a1)
    80002826:	6980                	ld	s0,16(a1)
    80002828:	6d84                	ld	s1,24(a1)
    8000282a:	0205b903          	ld	s2,32(a1)
    8000282e:	0285b983          	ld	s3,40(a1)
    80002832:	0305ba03          	ld	s4,48(a1)
    80002836:	0385ba83          	ld	s5,56(a1)
    8000283a:	0405bb03          	ld	s6,64(a1)
    8000283e:	0485bb83          	ld	s7,72(a1)
    80002842:	0505bc03          	ld	s8,80(a1)
    80002846:	0585bc83          	ld	s9,88(a1)
    8000284a:	0605bd03          	ld	s10,96(a1)
    8000284e:	0685bd83          	ld	s11,104(a1)
    80002852:	8082                	ret

0000000080002854 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002854:	1141                	addi	sp,sp,-16
    80002856:	e406                	sd	ra,8(sp)
    80002858:	e022                	sd	s0,0(sp)
    8000285a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000285c:	00006597          	auipc	a1,0x6
    80002860:	aec58593          	addi	a1,a1,-1300 # 80008348 <states.1736+0x28>
    80002864:	00015517          	auipc	a0,0x15
    80002868:	10450513          	addi	a0,a0,260 # 80017968 <tickslock>
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	322080e7          	jalr	802(ra) # 80000b8e <initlock>
}
    80002874:	60a2                	ld	ra,8(sp)
    80002876:	6402                	ld	s0,0(sp)
    80002878:	0141                	addi	sp,sp,16
    8000287a:	8082                	ret

000000008000287c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000287c:	1141                	addi	sp,sp,-16
    8000287e:	e422                	sd	s0,8(sp)
    80002880:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002882:	00003797          	auipc	a5,0x3
    80002886:	52e78793          	addi	a5,a5,1326 # 80005db0 <kernelvec>
    8000288a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000288e:	6422                	ld	s0,8(sp)
    80002890:	0141                	addi	sp,sp,16
    80002892:	8082                	ret

0000000080002894 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002894:	1141                	addi	sp,sp,-16
    80002896:	e406                	sd	ra,8(sp)
    80002898:	e022                	sd	s0,0(sp)
    8000289a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000289c:	fffff097          	auipc	ra,0xfffff
    800028a0:	26a080e7          	jalr	618(ra) # 80001b06 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028aa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028ae:	00004617          	auipc	a2,0x4
    800028b2:	75260613          	addi	a2,a2,1874 # 80007000 <_trampoline>
    800028b6:	00004697          	auipc	a3,0x4
    800028ba:	74a68693          	addi	a3,a3,1866 # 80007000 <_trampoline>
    800028be:	8e91                	sub	a3,a3,a2
    800028c0:	040007b7          	lui	a5,0x4000
    800028c4:	17fd                	addi	a5,a5,-1
    800028c6:	07b2                	slli	a5,a5,0xc
    800028c8:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ca:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028ce:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028d0:	180026f3          	csrr	a3,satp
    800028d4:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028d6:	6d38                	ld	a4,88(a0)
    800028d8:	6134                	ld	a3,64(a0)
    800028da:	6585                	lui	a1,0x1
    800028dc:	96ae                	add	a3,a3,a1
    800028de:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028e0:	6d38                	ld	a4,88(a0)
    800028e2:	00000697          	auipc	a3,0x0
    800028e6:	13868693          	addi	a3,a3,312 # 80002a1a <usertrap>
    800028ea:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028ec:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028ee:	8692                	mv	a3,tp
    800028f0:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f2:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028f6:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028fa:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028fe:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002902:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002904:	6f18                	ld	a4,24(a4)
    80002906:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000290a:	692c                	ld	a1,80(a0)
    8000290c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000290e:	00004717          	auipc	a4,0x4
    80002912:	78270713          	addi	a4,a4,1922 # 80007090 <userret>
    80002916:	8f11                	sub	a4,a4,a2
    80002918:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000291a:	577d                	li	a4,-1
    8000291c:	177e                	slli	a4,a4,0x3f
    8000291e:	8dd9                	or	a1,a1,a4
    80002920:	02000537          	lui	a0,0x2000
    80002924:	157d                	addi	a0,a0,-1
    80002926:	0536                	slli	a0,a0,0xd
    80002928:	9782                	jalr	a5
}
    8000292a:	60a2                	ld	ra,8(sp)
    8000292c:	6402                	ld	s0,0(sp)
    8000292e:	0141                	addi	sp,sp,16
    80002930:	8082                	ret

0000000080002932 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002932:	1101                	addi	sp,sp,-32
    80002934:	ec06                	sd	ra,24(sp)
    80002936:	e822                	sd	s0,16(sp)
    80002938:	e426                	sd	s1,8(sp)
    8000293a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000293c:	00015497          	auipc	s1,0x15
    80002940:	02c48493          	addi	s1,s1,44 # 80017968 <tickslock>
    80002944:	8526                	mv	a0,s1
    80002946:	ffffe097          	auipc	ra,0xffffe
    8000294a:	2d8080e7          	jalr	728(ra) # 80000c1e <acquire>
  ticks++;
    8000294e:	00006517          	auipc	a0,0x6
    80002952:	6d250513          	addi	a0,a0,1746 # 80009020 <ticks>
    80002956:	411c                	lw	a5,0(a0)
    80002958:	2785                	addiw	a5,a5,1
    8000295a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000295c:	00000097          	auipc	ra,0x0
    80002960:	c58080e7          	jalr	-936(ra) # 800025b4 <wakeup>
  release(&tickslock);
    80002964:	8526                	mv	a0,s1
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	36c080e7          	jalr	876(ra) # 80000cd2 <release>
}
    8000296e:	60e2                	ld	ra,24(sp)
    80002970:	6442                	ld	s0,16(sp)
    80002972:	64a2                	ld	s1,8(sp)
    80002974:	6105                	addi	sp,sp,32
    80002976:	8082                	ret

0000000080002978 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002978:	1101                	addi	sp,sp,-32
    8000297a:	ec06                	sd	ra,24(sp)
    8000297c:	e822                	sd	s0,16(sp)
    8000297e:	e426                	sd	s1,8(sp)
    80002980:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002982:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002986:	00074d63          	bltz	a4,800029a0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000298a:	57fd                	li	a5,-1
    8000298c:	17fe                	slli	a5,a5,0x3f
    8000298e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002990:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002992:	06f70363          	beq	a4,a5,800029f8 <devintr+0x80>
  }
}
    80002996:	60e2                	ld	ra,24(sp)
    80002998:	6442                	ld	s0,16(sp)
    8000299a:	64a2                	ld	s1,8(sp)
    8000299c:	6105                	addi	sp,sp,32
    8000299e:	8082                	ret
     (scause & 0xff) == 9){
    800029a0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800029a4:	46a5                	li	a3,9
    800029a6:	fed792e3          	bne	a5,a3,8000298a <devintr+0x12>
    int irq = plic_claim();
    800029aa:	00003097          	auipc	ra,0x3
    800029ae:	50e080e7          	jalr	1294(ra) # 80005eb8 <plic_claim>
    800029b2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029b4:	47a9                	li	a5,10
    800029b6:	02f50763          	beq	a0,a5,800029e4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029ba:	4785                	li	a5,1
    800029bc:	02f50963          	beq	a0,a5,800029ee <devintr+0x76>
    return 1;
    800029c0:	4505                	li	a0,1
    } else if(irq){
    800029c2:	d8f1                	beqz	s1,80002996 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029c4:	85a6                	mv	a1,s1
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	98a50513          	addi	a0,a0,-1654 # 80008350 <states.1736+0x30>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	bd2080e7          	jalr	-1070(ra) # 800005a0 <printf>
      plic_complete(irq);
    800029d6:	8526                	mv	a0,s1
    800029d8:	00003097          	auipc	ra,0x3
    800029dc:	504080e7          	jalr	1284(ra) # 80005edc <plic_complete>
    return 1;
    800029e0:	4505                	li	a0,1
    800029e2:	bf55                	j	80002996 <devintr+0x1e>
      uartintr();
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	ffe080e7          	jalr	-2(ra) # 800009e2 <uartintr>
    800029ec:	b7ed                	j	800029d6 <devintr+0x5e>
      virtio_disk_intr();
    800029ee:	00004097          	auipc	ra,0x4
    800029f2:	994080e7          	jalr	-1644(ra) # 80006382 <virtio_disk_intr>
    800029f6:	b7c5                	j	800029d6 <devintr+0x5e>
    if(cpuid() == 0){
    800029f8:	fffff097          	auipc	ra,0xfffff
    800029fc:	0e2080e7          	jalr	226(ra) # 80001ada <cpuid>
    80002a00:	c901                	beqz	a0,80002a10 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a02:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a06:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a08:	14479073          	csrw	sip,a5
    return 2;
    80002a0c:	4509                	li	a0,2
    80002a0e:	b761                	j	80002996 <devintr+0x1e>
      clockintr();
    80002a10:	00000097          	auipc	ra,0x0
    80002a14:	f22080e7          	jalr	-222(ra) # 80002932 <clockintr>
    80002a18:	b7ed                	j	80002a02 <devintr+0x8a>

0000000080002a1a <usertrap>:
{
    80002a1a:	1101                	addi	sp,sp,-32
    80002a1c:	ec06                	sd	ra,24(sp)
    80002a1e:	e822                	sd	s0,16(sp)
    80002a20:	e426                	sd	s1,8(sp)
    80002a22:	e04a                	sd	s2,0(sp)
    80002a24:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a26:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a2a:	1007f793          	andi	a5,a5,256
    80002a2e:	e3ad                	bnez	a5,80002a90 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a30:	00003797          	auipc	a5,0x3
    80002a34:	38078793          	addi	a5,a5,896 # 80005db0 <kernelvec>
    80002a38:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	0ca080e7          	jalr	202(ra) # 80001b06 <myproc>
    80002a44:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a46:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a48:	14102773          	csrr	a4,sepc
    80002a4c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a4e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a52:	47a1                	li	a5,8
    80002a54:	04f71c63          	bne	a4,a5,80002aac <usertrap+0x92>
    if(p->killed)
    80002a58:	591c                	lw	a5,48(a0)
    80002a5a:	e3b9                	bnez	a5,80002aa0 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002a5c:	6cb8                	ld	a4,88(s1)
    80002a5e:	6f1c                	ld	a5,24(a4)
    80002a60:	0791                	addi	a5,a5,4
    80002a62:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6c:	10079073          	csrw	sstatus,a5
    syscall();
    80002a70:	00000097          	auipc	ra,0x0
    80002a74:	2e0080e7          	jalr	736(ra) # 80002d50 <syscall>
  if(p->killed)
    80002a78:	589c                	lw	a5,48(s1)
    80002a7a:	ebc1                	bnez	a5,80002b0a <usertrap+0xf0>
  usertrapret();
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	e18080e7          	jalr	-488(ra) # 80002894 <usertrapret>
}
    80002a84:	60e2                	ld	ra,24(sp)
    80002a86:	6442                	ld	s0,16(sp)
    80002a88:	64a2                	ld	s1,8(sp)
    80002a8a:	6902                	ld	s2,0(sp)
    80002a8c:	6105                	addi	sp,sp,32
    80002a8e:	8082                	ret
    panic("usertrap: not from user mode");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	8e050513          	addi	a0,a0,-1824 # 80008370 <states.1736+0x50>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	abe080e7          	jalr	-1346(ra) # 80000556 <panic>
      exit(-1);
    80002aa0:	557d                	li	a0,-1
    80002aa2:	00000097          	auipc	ra,0x0
    80002aa6:	846080e7          	jalr	-1978(ra) # 800022e8 <exit>
    80002aaa:	bf4d                	j	80002a5c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	ecc080e7          	jalr	-308(ra) # 80002978 <devintr>
    80002ab4:	892a                	mv	s2,a0
    80002ab6:	c501                	beqz	a0,80002abe <usertrap+0xa4>
  if(p->killed)
    80002ab8:	589c                	lw	a5,48(s1)
    80002aba:	c3a1                	beqz	a5,80002afa <usertrap+0xe0>
    80002abc:	a815                	j	80002af0 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002abe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ac2:	5c90                	lw	a2,56(s1)
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	8cc50513          	addi	a0,a0,-1844 # 80008390 <states.1736+0x70>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	ad4080e7          	jalr	-1324(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ad8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	8e450513          	addi	a0,a0,-1820 # 800083c0 <states.1736+0xa0>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	abc080e7          	jalr	-1348(ra) # 800005a0 <printf>
    p->killed = 1;
    80002aec:	4785                	li	a5,1
    80002aee:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002af0:	557d                	li	a0,-1
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	7f6080e7          	jalr	2038(ra) # 800022e8 <exit>
  if(which_dev == 2)
    80002afa:	4789                	li	a5,2
    80002afc:	f8f910e3          	bne	s2,a5,80002a7c <usertrap+0x62>
    yield();
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	8f2080e7          	jalr	-1806(ra) # 800023f2 <yield>
    80002b08:	bf95                	j	80002a7c <usertrap+0x62>
  int which_dev = 0;
    80002b0a:	4901                	li	s2,0
    80002b0c:	b7d5                	j	80002af0 <usertrap+0xd6>

0000000080002b0e <kerneltrap>:
{
    80002b0e:	7179                	addi	sp,sp,-48
    80002b10:	f406                	sd	ra,40(sp)
    80002b12:	f022                	sd	s0,32(sp)
    80002b14:	ec26                	sd	s1,24(sp)
    80002b16:	e84a                	sd	s2,16(sp)
    80002b18:	e44e                	sd	s3,8(sp)
    80002b1a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b20:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b24:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b28:	1004f793          	andi	a5,s1,256
    80002b2c:	cb85                	beqz	a5,80002b5c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b2e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b32:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b34:	ef85                	bnez	a5,80002b6c <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	e42080e7          	jalr	-446(ra) # 80002978 <devintr>
    80002b3e:	cd1d                	beqz	a0,80002b7c <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b40:	4789                	li	a5,2
    80002b42:	06f50a63          	beq	a0,a5,80002bb6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b46:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b4a:	10049073          	csrw	sstatus,s1
}
    80002b4e:	70a2                	ld	ra,40(sp)
    80002b50:	7402                	ld	s0,32(sp)
    80002b52:	64e2                	ld	s1,24(sp)
    80002b54:	6942                	ld	s2,16(sp)
    80002b56:	69a2                	ld	s3,8(sp)
    80002b58:	6145                	addi	sp,sp,48
    80002b5a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b5c:	00006517          	auipc	a0,0x6
    80002b60:	88450513          	addi	a0,a0,-1916 # 800083e0 <states.1736+0xc0>
    80002b64:	ffffe097          	auipc	ra,0xffffe
    80002b68:	9f2080e7          	jalr	-1550(ra) # 80000556 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b6c:	00006517          	auipc	a0,0x6
    80002b70:	89c50513          	addi	a0,a0,-1892 # 80008408 <states.1736+0xe8>
    80002b74:	ffffe097          	auipc	ra,0xffffe
    80002b78:	9e2080e7          	jalr	-1566(ra) # 80000556 <panic>
    printf("scause %p\n", scause);
    80002b7c:	85ce                	mv	a1,s3
    80002b7e:	00006517          	auipc	a0,0x6
    80002b82:	8aa50513          	addi	a0,a0,-1878 # 80008428 <states.1736+0x108>
    80002b86:	ffffe097          	auipc	ra,0xffffe
    80002b8a:	a1a080e7          	jalr	-1510(ra) # 800005a0 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b8e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b92:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b96:	00006517          	auipc	a0,0x6
    80002b9a:	8a250513          	addi	a0,a0,-1886 # 80008438 <states.1736+0x118>
    80002b9e:	ffffe097          	auipc	ra,0xffffe
    80002ba2:	a02080e7          	jalr	-1534(ra) # 800005a0 <printf>
    panic("kerneltrap");
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	8aa50513          	addi	a0,a0,-1878 # 80008450 <states.1736+0x130>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9a8080e7          	jalr	-1624(ra) # 80000556 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bb6:	fffff097          	auipc	ra,0xfffff
    80002bba:	f50080e7          	jalr	-176(ra) # 80001b06 <myproc>
    80002bbe:	d541                	beqz	a0,80002b46 <kerneltrap+0x38>
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	f46080e7          	jalr	-186(ra) # 80001b06 <myproc>
    80002bc8:	4d18                	lw	a4,24(a0)
    80002bca:	478d                	li	a5,3
    80002bcc:	f6f71de3          	bne	a4,a5,80002b46 <kerneltrap+0x38>
    yield();
    80002bd0:	00000097          	auipc	ra,0x0
    80002bd4:	822080e7          	jalr	-2014(ra) # 800023f2 <yield>
    80002bd8:	b7bd                	j	80002b46 <kerneltrap+0x38>

0000000080002bda <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bda:	1101                	addi	sp,sp,-32
    80002bdc:	ec06                	sd	ra,24(sp)
    80002bde:	e822                	sd	s0,16(sp)
    80002be0:	e426                	sd	s1,8(sp)
    80002be2:	1000                	addi	s0,sp,32
    80002be4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	f20080e7          	jalr	-224(ra) # 80001b06 <myproc>
  switch (n) {
    80002bee:	4795                	li	a5,5
    80002bf0:	0497e163          	bltu	a5,s1,80002c32 <argraw+0x58>
    80002bf4:	048a                	slli	s1,s1,0x2
    80002bf6:	00006717          	auipc	a4,0x6
    80002bfa:	89270713          	addi	a4,a4,-1902 # 80008488 <states.1736+0x168>
    80002bfe:	94ba                	add	s1,s1,a4
    80002c00:	409c                	lw	a5,0(s1)
    80002c02:	97ba                	add	a5,a5,a4
    80002c04:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c06:	6d3c                	ld	a5,88(a0)
    80002c08:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c0a:	60e2                	ld	ra,24(sp)
    80002c0c:	6442                	ld	s0,16(sp)
    80002c0e:	64a2                	ld	s1,8(sp)
    80002c10:	6105                	addi	sp,sp,32
    80002c12:	8082                	ret
    return p->trapframe->a1;
    80002c14:	6d3c                	ld	a5,88(a0)
    80002c16:	7fa8                	ld	a0,120(a5)
    80002c18:	bfcd                	j	80002c0a <argraw+0x30>
    return p->trapframe->a2;
    80002c1a:	6d3c                	ld	a5,88(a0)
    80002c1c:	63c8                	ld	a0,128(a5)
    80002c1e:	b7f5                	j	80002c0a <argraw+0x30>
    return p->trapframe->a3;
    80002c20:	6d3c                	ld	a5,88(a0)
    80002c22:	67c8                	ld	a0,136(a5)
    80002c24:	b7dd                	j	80002c0a <argraw+0x30>
    return p->trapframe->a4;
    80002c26:	6d3c                	ld	a5,88(a0)
    80002c28:	6bc8                	ld	a0,144(a5)
    80002c2a:	b7c5                	j	80002c0a <argraw+0x30>
    return p->trapframe->a5;
    80002c2c:	6d3c                	ld	a5,88(a0)
    80002c2e:	6fc8                	ld	a0,152(a5)
    80002c30:	bfe9                	j	80002c0a <argraw+0x30>
  panic("argraw");
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	82e50513          	addi	a0,a0,-2002 # 80008460 <states.1736+0x140>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	91c080e7          	jalr	-1764(ra) # 80000556 <panic>

0000000080002c42 <fetchaddr>:
{
    80002c42:	1101                	addi	sp,sp,-32
    80002c44:	ec06                	sd	ra,24(sp)
    80002c46:	e822                	sd	s0,16(sp)
    80002c48:	e426                	sd	s1,8(sp)
    80002c4a:	e04a                	sd	s2,0(sp)
    80002c4c:	1000                	addi	s0,sp,32
    80002c4e:	84aa                	mv	s1,a0
    80002c50:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c52:	fffff097          	auipc	ra,0xfffff
    80002c56:	eb4080e7          	jalr	-332(ra) # 80001b06 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c5a:	653c                	ld	a5,72(a0)
    80002c5c:	02f4f863          	bgeu	s1,a5,80002c8c <fetchaddr+0x4a>
    80002c60:	00848713          	addi	a4,s1,8
    80002c64:	02e7e663          	bltu	a5,a4,80002c90 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c68:	46a1                	li	a3,8
    80002c6a:	8626                	mv	a2,s1
    80002c6c:	85ca                	mv	a1,s2
    80002c6e:	6928                	ld	a0,80(a0)
    80002c70:	fffff097          	auipc	ra,0xfffff
    80002c74:	d8e080e7          	jalr	-626(ra) # 800019fe <copyin>
    80002c78:	00a03533          	snez	a0,a0
    80002c7c:	40a00533          	neg	a0,a0
}
    80002c80:	60e2                	ld	ra,24(sp)
    80002c82:	6442                	ld	s0,16(sp)
    80002c84:	64a2                	ld	s1,8(sp)
    80002c86:	6902                	ld	s2,0(sp)
    80002c88:	6105                	addi	sp,sp,32
    80002c8a:	8082                	ret
    return -1;
    80002c8c:	557d                	li	a0,-1
    80002c8e:	bfcd                	j	80002c80 <fetchaddr+0x3e>
    80002c90:	557d                	li	a0,-1
    80002c92:	b7fd                	j	80002c80 <fetchaddr+0x3e>

0000000080002c94 <fetchstr>:
{
    80002c94:	7179                	addi	sp,sp,-48
    80002c96:	f406                	sd	ra,40(sp)
    80002c98:	f022                	sd	s0,32(sp)
    80002c9a:	ec26                	sd	s1,24(sp)
    80002c9c:	e84a                	sd	s2,16(sp)
    80002c9e:	e44e                	sd	s3,8(sp)
    80002ca0:	1800                	addi	s0,sp,48
    80002ca2:	892a                	mv	s2,a0
    80002ca4:	84ae                	mv	s1,a1
    80002ca6:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	e5e080e7          	jalr	-418(ra) # 80001b06 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002cb0:	86ce                	mv	a3,s3
    80002cb2:	864a                	mv	a2,s2
    80002cb4:	85a6                	mv	a1,s1
    80002cb6:	6928                	ld	a0,80(a0)
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	d5e080e7          	jalr	-674(ra) # 80001a16 <copyinstr>
  if(err < 0)
    80002cc0:	00054763          	bltz	a0,80002cce <fetchstr+0x3a>
  return strlen(buf);
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	1dc080e7          	jalr	476(ra) # 80000ea2 <strlen>
}
    80002cce:	70a2                	ld	ra,40(sp)
    80002cd0:	7402                	ld	s0,32(sp)
    80002cd2:	64e2                	ld	s1,24(sp)
    80002cd4:	6942                	ld	s2,16(sp)
    80002cd6:	69a2                	ld	s3,8(sp)
    80002cd8:	6145                	addi	sp,sp,48
    80002cda:	8082                	ret

0000000080002cdc <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cdc:	1101                	addi	sp,sp,-32
    80002cde:	ec06                	sd	ra,24(sp)
    80002ce0:	e822                	sd	s0,16(sp)
    80002ce2:	e426                	sd	s1,8(sp)
    80002ce4:	1000                	addi	s0,sp,32
    80002ce6:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	ef2080e7          	jalr	-270(ra) # 80002bda <argraw>
    80002cf0:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cf2:	4501                	li	a0,0
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret

0000000080002cfe <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	e426                	sd	s1,8(sp)
    80002d06:	1000                	addi	s0,sp,32
    80002d08:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d0a:	00000097          	auipc	ra,0x0
    80002d0e:	ed0080e7          	jalr	-304(ra) # 80002bda <argraw>
    80002d12:	e088                	sd	a0,0(s1)
  return 0;
}
    80002d14:	4501                	li	a0,0
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	64a2                	ld	s1,8(sp)
    80002d1c:	6105                	addi	sp,sp,32
    80002d1e:	8082                	ret

0000000080002d20 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d20:	1101                	addi	sp,sp,-32
    80002d22:	ec06                	sd	ra,24(sp)
    80002d24:	e822                	sd	s0,16(sp)
    80002d26:	e426                	sd	s1,8(sp)
    80002d28:	e04a                	sd	s2,0(sp)
    80002d2a:	1000                	addi	s0,sp,32
    80002d2c:	84ae                	mv	s1,a1
    80002d2e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d30:	00000097          	auipc	ra,0x0
    80002d34:	eaa080e7          	jalr	-342(ra) # 80002bda <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d38:	864a                	mv	a2,s2
    80002d3a:	85a6                	mv	a1,s1
    80002d3c:	00000097          	auipc	ra,0x0
    80002d40:	f58080e7          	jalr	-168(ra) # 80002c94 <fetchstr>
}
    80002d44:	60e2                	ld	ra,24(sp)
    80002d46:	6442                	ld	s0,16(sp)
    80002d48:	64a2                	ld	s1,8(sp)
    80002d4a:	6902                	ld	s2,0(sp)
    80002d4c:	6105                	addi	sp,sp,32
    80002d4e:	8082                	ret

0000000080002d50 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d50:	1101                	addi	sp,sp,-32
    80002d52:	ec06                	sd	ra,24(sp)
    80002d54:	e822                	sd	s0,16(sp)
    80002d56:	e426                	sd	s1,8(sp)
    80002d58:	e04a                	sd	s2,0(sp)
    80002d5a:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	daa080e7          	jalr	-598(ra) # 80001b06 <myproc>
    80002d64:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d66:	05853903          	ld	s2,88(a0)
    80002d6a:	0a893783          	ld	a5,168(s2)
    80002d6e:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d72:	37fd                	addiw	a5,a5,-1
    80002d74:	4751                	li	a4,20
    80002d76:	00f76f63          	bltu	a4,a5,80002d94 <syscall+0x44>
    80002d7a:	00369713          	slli	a4,a3,0x3
    80002d7e:	00005797          	auipc	a5,0x5
    80002d82:	72278793          	addi	a5,a5,1826 # 800084a0 <syscalls>
    80002d86:	97ba                	add	a5,a5,a4
    80002d88:	639c                	ld	a5,0(a5)
    80002d8a:	c789                	beqz	a5,80002d94 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d8c:	9782                	jalr	a5
    80002d8e:	06a93823          	sd	a0,112(s2)
    80002d92:	a839                	j	80002db0 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d94:	15848613          	addi	a2,s1,344
    80002d98:	5c8c                	lw	a1,56(s1)
    80002d9a:	00005517          	auipc	a0,0x5
    80002d9e:	6ce50513          	addi	a0,a0,1742 # 80008468 <states.1736+0x148>
    80002da2:	ffffd097          	auipc	ra,0xffffd
    80002da6:	7fe080e7          	jalr	2046(ra) # 800005a0 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002daa:	6cbc                	ld	a5,88(s1)
    80002dac:	577d                	li	a4,-1
    80002dae:	fbb8                	sd	a4,112(a5)
  }
}
    80002db0:	60e2                	ld	ra,24(sp)
    80002db2:	6442                	ld	s0,16(sp)
    80002db4:	64a2                	ld	s1,8(sp)
    80002db6:	6902                	ld	s2,0(sp)
    80002db8:	6105                	addi	sp,sp,32
    80002dba:	8082                	ret

0000000080002dbc <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dbc:	1101                	addi	sp,sp,-32
    80002dbe:	ec06                	sd	ra,24(sp)
    80002dc0:	e822                	sd	s0,16(sp)
    80002dc2:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002dc4:	fec40593          	addi	a1,s0,-20
    80002dc8:	4501                	li	a0,0
    80002dca:	00000097          	auipc	ra,0x0
    80002dce:	f12080e7          	jalr	-238(ra) # 80002cdc <argint>
    return -1;
    80002dd2:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dd4:	00054963          	bltz	a0,80002de6 <sys_exit+0x2a>
  exit(n);
    80002dd8:	fec42503          	lw	a0,-20(s0)
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	50c080e7          	jalr	1292(ra) # 800022e8 <exit>
  return 0;  // not reached
    80002de4:	4781                	li	a5,0
}
    80002de6:	853e                	mv	a0,a5
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	6105                	addi	sp,sp,32
    80002dee:	8082                	ret

0000000080002df0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002df0:	1141                	addi	sp,sp,-16
    80002df2:	e406                	sd	ra,8(sp)
    80002df4:	e022                	sd	s0,0(sp)
    80002df6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	d0e080e7          	jalr	-754(ra) # 80001b06 <myproc>
}
    80002e00:	5d08                	lw	a0,56(a0)
    80002e02:	60a2                	ld	ra,8(sp)
    80002e04:	6402                	ld	s0,0(sp)
    80002e06:	0141                	addi	sp,sp,16
    80002e08:	8082                	ret

0000000080002e0a <sys_fork>:

uint64
sys_fork(void)
{
    80002e0a:	1141                	addi	sp,sp,-16
    80002e0c:	e406                	sd	ra,8(sp)
    80002e0e:	e022                	sd	s0,0(sp)
    80002e10:	0800                	addi	s0,sp,16
  return fork();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	198080e7          	jalr	408(ra) # 80001faa <fork>
}
    80002e1a:	60a2                	ld	ra,8(sp)
    80002e1c:	6402                	ld	s0,0(sp)
    80002e1e:	0141                	addi	sp,sp,16
    80002e20:	8082                	ret

0000000080002e22 <sys_wait>:

uint64
sys_wait(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e2a:	fe840593          	addi	a1,s0,-24
    80002e2e:	4501                	li	a0,0
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	ece080e7          	jalr	-306(ra) # 80002cfe <argaddr>
    80002e38:	87aa                	mv	a5,a0
    return -1;
    80002e3a:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e3c:	0007c863          	bltz	a5,80002e4c <sys_wait+0x2a>
  return wait(p);
    80002e40:	fe843503          	ld	a0,-24(s0)
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	668080e7          	jalr	1640(ra) # 800024ac <wait>
}
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	6105                	addi	sp,sp,32
    80002e52:	8082                	ret

0000000080002e54 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e54:	7179                	addi	sp,sp,-48
    80002e56:	f406                	sd	ra,40(sp)
    80002e58:	f022                	sd	s0,32(sp)
    80002e5a:	ec26                	sd	s1,24(sp)
    80002e5c:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e5e:	fdc40593          	addi	a1,s0,-36
    80002e62:	4501                	li	a0,0
    80002e64:	00000097          	auipc	ra,0x0
    80002e68:	e78080e7          	jalr	-392(ra) # 80002cdc <argint>
    80002e6c:	87aa                	mv	a5,a0
    return -1;
    80002e6e:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e70:	0207c063          	bltz	a5,80002e90 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e74:	fffff097          	auipc	ra,0xfffff
    80002e78:	c92080e7          	jalr	-878(ra) # 80001b06 <myproc>
    80002e7c:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e7e:	fdc42503          	lw	a0,-36(s0)
    80002e82:	fffff097          	auipc	ra,0xfffff
    80002e86:	05c080e7          	jalr	92(ra) # 80001ede <growproc>
    80002e8a:	00054863          	bltz	a0,80002e9a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e8e:	8526                	mv	a0,s1
}
    80002e90:	70a2                	ld	ra,40(sp)
    80002e92:	7402                	ld	s0,32(sp)
    80002e94:	64e2                	ld	s1,24(sp)
    80002e96:	6145                	addi	sp,sp,48
    80002e98:	8082                	ret
    return -1;
    80002e9a:	557d                	li	a0,-1
    80002e9c:	bfd5                	j	80002e90 <sys_sbrk+0x3c>

0000000080002e9e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e9e:	7139                	addi	sp,sp,-64
    80002ea0:	fc06                	sd	ra,56(sp)
    80002ea2:	f822                	sd	s0,48(sp)
    80002ea4:	f426                	sd	s1,40(sp)
    80002ea6:	f04a                	sd	s2,32(sp)
    80002ea8:	ec4e                	sd	s3,24(sp)
    80002eaa:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002eac:	fcc40593          	addi	a1,s0,-52
    80002eb0:	4501                	li	a0,0
    80002eb2:	00000097          	auipc	ra,0x0
    80002eb6:	e2a080e7          	jalr	-470(ra) # 80002cdc <argint>
    return -1;
    80002eba:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ebc:	06054563          	bltz	a0,80002f26 <sys_sleep+0x88>
  acquire(&tickslock);
    80002ec0:	00015517          	auipc	a0,0x15
    80002ec4:	aa850513          	addi	a0,a0,-1368 # 80017968 <tickslock>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	d56080e7          	jalr	-682(ra) # 80000c1e <acquire>
  ticks0 = ticks;
    80002ed0:	00006917          	auipc	s2,0x6
    80002ed4:	15092903          	lw	s2,336(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002ed8:	fcc42783          	lw	a5,-52(s0)
    80002edc:	cf85                	beqz	a5,80002f14 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ede:	00015997          	auipc	s3,0x15
    80002ee2:	a8a98993          	addi	s3,s3,-1398 # 80017968 <tickslock>
    80002ee6:	00006497          	auipc	s1,0x6
    80002eea:	13a48493          	addi	s1,s1,314 # 80009020 <ticks>
    if(myproc()->killed){
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	c18080e7          	jalr	-1000(ra) # 80001b06 <myproc>
    80002ef6:	591c                	lw	a5,48(a0)
    80002ef8:	ef9d                	bnez	a5,80002f36 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002efa:	85ce                	mv	a1,s3
    80002efc:	8526                	mv	a0,s1
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	530080e7          	jalr	1328(ra) # 8000242e <sleep>
  while(ticks - ticks0 < n){
    80002f06:	409c                	lw	a5,0(s1)
    80002f08:	412787bb          	subw	a5,a5,s2
    80002f0c:	fcc42703          	lw	a4,-52(s0)
    80002f10:	fce7efe3          	bltu	a5,a4,80002eee <sys_sleep+0x50>
  }
  release(&tickslock);
    80002f14:	00015517          	auipc	a0,0x15
    80002f18:	a5450513          	addi	a0,a0,-1452 # 80017968 <tickslock>
    80002f1c:	ffffe097          	auipc	ra,0xffffe
    80002f20:	db6080e7          	jalr	-586(ra) # 80000cd2 <release>
  return 0;
    80002f24:	4781                	li	a5,0
}
    80002f26:	853e                	mv	a0,a5
    80002f28:	70e2                	ld	ra,56(sp)
    80002f2a:	7442                	ld	s0,48(sp)
    80002f2c:	74a2                	ld	s1,40(sp)
    80002f2e:	7902                	ld	s2,32(sp)
    80002f30:	69e2                	ld	s3,24(sp)
    80002f32:	6121                	addi	sp,sp,64
    80002f34:	8082                	ret
      release(&tickslock);
    80002f36:	00015517          	auipc	a0,0x15
    80002f3a:	a3250513          	addi	a0,a0,-1486 # 80017968 <tickslock>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	d94080e7          	jalr	-620(ra) # 80000cd2 <release>
      return -1;
    80002f46:	57fd                	li	a5,-1
    80002f48:	bff9                	j	80002f26 <sys_sleep+0x88>

0000000080002f4a <sys_kill>:

uint64
sys_kill(void)
{
    80002f4a:	1101                	addi	sp,sp,-32
    80002f4c:	ec06                	sd	ra,24(sp)
    80002f4e:	e822                	sd	s0,16(sp)
    80002f50:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f52:	fec40593          	addi	a1,s0,-20
    80002f56:	4501                	li	a0,0
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	d84080e7          	jalr	-636(ra) # 80002cdc <argint>
    80002f60:	87aa                	mv	a5,a0
    return -1;
    80002f62:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f64:	0007c863          	bltz	a5,80002f74 <sys_kill+0x2a>
  return kill(pid);
    80002f68:	fec42503          	lw	a0,-20(s0)
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	6b2080e7          	jalr	1714(ra) # 8000261e <kill>
}
    80002f74:	60e2                	ld	ra,24(sp)
    80002f76:	6442                	ld	s0,16(sp)
    80002f78:	6105                	addi	sp,sp,32
    80002f7a:	8082                	ret

0000000080002f7c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f7c:	1101                	addi	sp,sp,-32
    80002f7e:	ec06                	sd	ra,24(sp)
    80002f80:	e822                	sd	s0,16(sp)
    80002f82:	e426                	sd	s1,8(sp)
    80002f84:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f86:	00015517          	auipc	a0,0x15
    80002f8a:	9e250513          	addi	a0,a0,-1566 # 80017968 <tickslock>
    80002f8e:	ffffe097          	auipc	ra,0xffffe
    80002f92:	c90080e7          	jalr	-880(ra) # 80000c1e <acquire>
  xticks = ticks;
    80002f96:	00006497          	auipc	s1,0x6
    80002f9a:	08a4a483          	lw	s1,138(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f9e:	00015517          	auipc	a0,0x15
    80002fa2:	9ca50513          	addi	a0,a0,-1590 # 80017968 <tickslock>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	d2c080e7          	jalr	-724(ra) # 80000cd2 <release>
  return xticks;
}
    80002fae:	02049513          	slli	a0,s1,0x20
    80002fb2:	9101                	srli	a0,a0,0x20
    80002fb4:	60e2                	ld	ra,24(sp)
    80002fb6:	6442                	ld	s0,16(sp)
    80002fb8:	64a2                	ld	s1,8(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	e84a                	sd	s2,16(sp)
    80002fc8:	e44e                	sd	s3,8(sp)
    80002fca:	e052                	sd	s4,0(sp)
    80002fcc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fce:	00005597          	auipc	a1,0x5
    80002fd2:	58258593          	addi	a1,a1,1410 # 80008550 <syscalls+0xb0>
    80002fd6:	00015517          	auipc	a0,0x15
    80002fda:	9aa50513          	addi	a0,a0,-1622 # 80017980 <bcache>
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	bb0080e7          	jalr	-1104(ra) # 80000b8e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fe6:	0001d797          	auipc	a5,0x1d
    80002fea:	99a78793          	addi	a5,a5,-1638 # 8001f980 <bcache+0x8000>
    80002fee:	0001d717          	auipc	a4,0x1d
    80002ff2:	bfa70713          	addi	a4,a4,-1030 # 8001fbe8 <bcache+0x8268>
    80002ff6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ffa:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ffe:	00015497          	auipc	s1,0x15
    80003002:	99a48493          	addi	s1,s1,-1638 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003006:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003008:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000300a:	00005a17          	auipc	s4,0x5
    8000300e:	54ea0a13          	addi	s4,s4,1358 # 80008558 <syscalls+0xb8>
    b->next = bcache.head.next;
    80003012:	2b893783          	ld	a5,696(s2)
    80003016:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003018:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000301c:	85d2                	mv	a1,s4
    8000301e:	01048513          	addi	a0,s1,16
    80003022:	00001097          	auipc	ra,0x1
    80003026:	4ac080e7          	jalr	1196(ra) # 800044ce <initsleeplock>
    bcache.head.next->prev = b;
    8000302a:	2b893783          	ld	a5,696(s2)
    8000302e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003030:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003034:	45848493          	addi	s1,s1,1112
    80003038:	fd349de3          	bne	s1,s3,80003012 <binit+0x54>
  }
}
    8000303c:	70a2                	ld	ra,40(sp)
    8000303e:	7402                	ld	s0,32(sp)
    80003040:	64e2                	ld	s1,24(sp)
    80003042:	6942                	ld	s2,16(sp)
    80003044:	69a2                	ld	s3,8(sp)
    80003046:	6a02                	ld	s4,0(sp)
    80003048:	6145                	addi	sp,sp,48
    8000304a:	8082                	ret

000000008000304c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000304c:	7179                	addi	sp,sp,-48
    8000304e:	f406                	sd	ra,40(sp)
    80003050:	f022                	sd	s0,32(sp)
    80003052:	ec26                	sd	s1,24(sp)
    80003054:	e84a                	sd	s2,16(sp)
    80003056:	e44e                	sd	s3,8(sp)
    80003058:	1800                	addi	s0,sp,48
    8000305a:	89aa                	mv	s3,a0
    8000305c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000305e:	00015517          	auipc	a0,0x15
    80003062:	92250513          	addi	a0,a0,-1758 # 80017980 <bcache>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	bb8080e7          	jalr	-1096(ra) # 80000c1e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000306e:	0001d497          	auipc	s1,0x1d
    80003072:	bca4b483          	ld	s1,-1078(s1) # 8001fc38 <bcache+0x82b8>
    80003076:	0001d797          	auipc	a5,0x1d
    8000307a:	b7278793          	addi	a5,a5,-1166 # 8001fbe8 <bcache+0x8268>
    8000307e:	02f48f63          	beq	s1,a5,800030bc <bread+0x70>
    80003082:	873e                	mv	a4,a5
    80003084:	a021                	j	8000308c <bread+0x40>
    80003086:	68a4                	ld	s1,80(s1)
    80003088:	02e48a63          	beq	s1,a4,800030bc <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000308c:	449c                	lw	a5,8(s1)
    8000308e:	ff379ce3          	bne	a5,s3,80003086 <bread+0x3a>
    80003092:	44dc                	lw	a5,12(s1)
    80003094:	ff2799e3          	bne	a5,s2,80003086 <bread+0x3a>
      b->refcnt++;
    80003098:	40bc                	lw	a5,64(s1)
    8000309a:	2785                	addiw	a5,a5,1
    8000309c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000309e:	00015517          	auipc	a0,0x15
    800030a2:	8e250513          	addi	a0,a0,-1822 # 80017980 <bcache>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	c2c080e7          	jalr	-980(ra) # 80000cd2 <release>
      acquiresleep(&b->lock);
    800030ae:	01048513          	addi	a0,s1,16
    800030b2:	00001097          	auipc	ra,0x1
    800030b6:	456080e7          	jalr	1110(ra) # 80004508 <acquiresleep>
      return b;
    800030ba:	a8b9                	j	80003118 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030bc:	0001d497          	auipc	s1,0x1d
    800030c0:	b744b483          	ld	s1,-1164(s1) # 8001fc30 <bcache+0x82b0>
    800030c4:	0001d797          	auipc	a5,0x1d
    800030c8:	b2478793          	addi	a5,a5,-1244 # 8001fbe8 <bcache+0x8268>
    800030cc:	00f48863          	beq	s1,a5,800030dc <bread+0x90>
    800030d0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030d2:	40bc                	lw	a5,64(s1)
    800030d4:	cf81                	beqz	a5,800030ec <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d6:	64a4                	ld	s1,72(s1)
    800030d8:	fee49de3          	bne	s1,a4,800030d2 <bread+0x86>
  panic("bget: no buffers");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	48450513          	addi	a0,a0,1156 # 80008560 <syscalls+0xc0>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	472080e7          	jalr	1138(ra) # 80000556 <panic>
      b->dev = dev;
    800030ec:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030f0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030f4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030f8:	4785                	li	a5,1
    800030fa:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030fc:	00015517          	auipc	a0,0x15
    80003100:	88450513          	addi	a0,a0,-1916 # 80017980 <bcache>
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	bce080e7          	jalr	-1074(ra) # 80000cd2 <release>
      acquiresleep(&b->lock);
    8000310c:	01048513          	addi	a0,s1,16
    80003110:	00001097          	auipc	ra,0x1
    80003114:	3f8080e7          	jalr	1016(ra) # 80004508 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003118:	409c                	lw	a5,0(s1)
    8000311a:	cb89                	beqz	a5,8000312c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000311c:	8526                	mv	a0,s1
    8000311e:	70a2                	ld	ra,40(sp)
    80003120:	7402                	ld	s0,32(sp)
    80003122:	64e2                	ld	s1,24(sp)
    80003124:	6942                	ld	s2,16(sp)
    80003126:	69a2                	ld	s3,8(sp)
    80003128:	6145                	addi	sp,sp,48
    8000312a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000312c:	4581                	li	a1,0
    8000312e:	8526                	mv	a0,s1
    80003130:	00003097          	auipc	ra,0x3
    80003134:	f9c080e7          	jalr	-100(ra) # 800060cc <virtio_disk_rw>
    b->valid = 1;
    80003138:	4785                	li	a5,1
    8000313a:	c09c                	sw	a5,0(s1)
  return b;
    8000313c:	b7c5                	j	8000311c <bread+0xd0>

000000008000313e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	1000                	addi	s0,sp,32
    80003148:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000314a:	0541                	addi	a0,a0,16
    8000314c:	00001097          	auipc	ra,0x1
    80003150:	456080e7          	jalr	1110(ra) # 800045a2 <holdingsleep>
    80003154:	cd01                	beqz	a0,8000316c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003156:	4585                	li	a1,1
    80003158:	8526                	mv	a0,s1
    8000315a:	00003097          	auipc	ra,0x3
    8000315e:	f72080e7          	jalr	-142(ra) # 800060cc <virtio_disk_rw>
}
    80003162:	60e2                	ld	ra,24(sp)
    80003164:	6442                	ld	s0,16(sp)
    80003166:	64a2                	ld	s1,8(sp)
    80003168:	6105                	addi	sp,sp,32
    8000316a:	8082                	ret
    panic("bwrite");
    8000316c:	00005517          	auipc	a0,0x5
    80003170:	40c50513          	addi	a0,a0,1036 # 80008578 <syscalls+0xd8>
    80003174:	ffffd097          	auipc	ra,0xffffd
    80003178:	3e2080e7          	jalr	994(ra) # 80000556 <panic>

000000008000317c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000317c:	1101                	addi	sp,sp,-32
    8000317e:	ec06                	sd	ra,24(sp)
    80003180:	e822                	sd	s0,16(sp)
    80003182:	e426                	sd	s1,8(sp)
    80003184:	e04a                	sd	s2,0(sp)
    80003186:	1000                	addi	s0,sp,32
    80003188:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000318a:	01050913          	addi	s2,a0,16
    8000318e:	854a                	mv	a0,s2
    80003190:	00001097          	auipc	ra,0x1
    80003194:	412080e7          	jalr	1042(ra) # 800045a2 <holdingsleep>
    80003198:	c92d                	beqz	a0,8000320a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000319a:	854a                	mv	a0,s2
    8000319c:	00001097          	auipc	ra,0x1
    800031a0:	3c2080e7          	jalr	962(ra) # 8000455e <releasesleep>

  acquire(&bcache.lock);
    800031a4:	00014517          	auipc	a0,0x14
    800031a8:	7dc50513          	addi	a0,a0,2012 # 80017980 <bcache>
    800031ac:	ffffe097          	auipc	ra,0xffffe
    800031b0:	a72080e7          	jalr	-1422(ra) # 80000c1e <acquire>
  b->refcnt--;
    800031b4:	40bc                	lw	a5,64(s1)
    800031b6:	37fd                	addiw	a5,a5,-1
    800031b8:	0007871b          	sext.w	a4,a5
    800031bc:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031be:	eb05                	bnez	a4,800031ee <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031c0:	68bc                	ld	a5,80(s1)
    800031c2:	64b8                	ld	a4,72(s1)
    800031c4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031c6:	64bc                	ld	a5,72(s1)
    800031c8:	68b8                	ld	a4,80(s1)
    800031ca:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031cc:	0001c797          	auipc	a5,0x1c
    800031d0:	7b478793          	addi	a5,a5,1972 # 8001f980 <bcache+0x8000>
    800031d4:	2b87b703          	ld	a4,696(a5)
    800031d8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031da:	0001d717          	auipc	a4,0x1d
    800031de:	a0e70713          	addi	a4,a4,-1522 # 8001fbe8 <bcache+0x8268>
    800031e2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031e4:	2b87b703          	ld	a4,696(a5)
    800031e8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031ea:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031ee:	00014517          	auipc	a0,0x14
    800031f2:	79250513          	addi	a0,a0,1938 # 80017980 <bcache>
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	adc080e7          	jalr	-1316(ra) # 80000cd2 <release>
}
    800031fe:	60e2                	ld	ra,24(sp)
    80003200:	6442                	ld	s0,16(sp)
    80003202:	64a2                	ld	s1,8(sp)
    80003204:	6902                	ld	s2,0(sp)
    80003206:	6105                	addi	sp,sp,32
    80003208:	8082                	ret
    panic("brelse");
    8000320a:	00005517          	auipc	a0,0x5
    8000320e:	37650513          	addi	a0,a0,886 # 80008580 <syscalls+0xe0>
    80003212:	ffffd097          	auipc	ra,0xffffd
    80003216:	344080e7          	jalr	836(ra) # 80000556 <panic>

000000008000321a <bpin>:

void
bpin(struct buf *b) {
    8000321a:	1101                	addi	sp,sp,-32
    8000321c:	ec06                	sd	ra,24(sp)
    8000321e:	e822                	sd	s0,16(sp)
    80003220:	e426                	sd	s1,8(sp)
    80003222:	1000                	addi	s0,sp,32
    80003224:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003226:	00014517          	auipc	a0,0x14
    8000322a:	75a50513          	addi	a0,a0,1882 # 80017980 <bcache>
    8000322e:	ffffe097          	auipc	ra,0xffffe
    80003232:	9f0080e7          	jalr	-1552(ra) # 80000c1e <acquire>
  b->refcnt++;
    80003236:	40bc                	lw	a5,64(s1)
    80003238:	2785                	addiw	a5,a5,1
    8000323a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000323c:	00014517          	auipc	a0,0x14
    80003240:	74450513          	addi	a0,a0,1860 # 80017980 <bcache>
    80003244:	ffffe097          	auipc	ra,0xffffe
    80003248:	a8e080e7          	jalr	-1394(ra) # 80000cd2 <release>
}
    8000324c:	60e2                	ld	ra,24(sp)
    8000324e:	6442                	ld	s0,16(sp)
    80003250:	64a2                	ld	s1,8(sp)
    80003252:	6105                	addi	sp,sp,32
    80003254:	8082                	ret

0000000080003256 <bunpin>:

void
bunpin(struct buf *b) {
    80003256:	1101                	addi	sp,sp,-32
    80003258:	ec06                	sd	ra,24(sp)
    8000325a:	e822                	sd	s0,16(sp)
    8000325c:	e426                	sd	s1,8(sp)
    8000325e:	1000                	addi	s0,sp,32
    80003260:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003262:	00014517          	auipc	a0,0x14
    80003266:	71e50513          	addi	a0,a0,1822 # 80017980 <bcache>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	9b4080e7          	jalr	-1612(ra) # 80000c1e <acquire>
  b->refcnt--;
    80003272:	40bc                	lw	a5,64(s1)
    80003274:	37fd                	addiw	a5,a5,-1
    80003276:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003278:	00014517          	auipc	a0,0x14
    8000327c:	70850513          	addi	a0,a0,1800 # 80017980 <bcache>
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	a52080e7          	jalr	-1454(ra) # 80000cd2 <release>
}
    80003288:	60e2                	ld	ra,24(sp)
    8000328a:	6442                	ld	s0,16(sp)
    8000328c:	64a2                	ld	s1,8(sp)
    8000328e:	6105                	addi	sp,sp,32
    80003290:	8082                	ret

0000000080003292 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003292:	1101                	addi	sp,sp,-32
    80003294:	ec06                	sd	ra,24(sp)
    80003296:	e822                	sd	s0,16(sp)
    80003298:	e426                	sd	s1,8(sp)
    8000329a:	e04a                	sd	s2,0(sp)
    8000329c:	1000                	addi	s0,sp,32
    8000329e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032a0:	00d5d59b          	srliw	a1,a1,0xd
    800032a4:	0001d797          	auipc	a5,0x1d
    800032a8:	db87a783          	lw	a5,-584(a5) # 8002005c <sb+0x1c>
    800032ac:	9dbd                	addw	a1,a1,a5
    800032ae:	00000097          	auipc	ra,0x0
    800032b2:	d9e080e7          	jalr	-610(ra) # 8000304c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032b6:	0074f713          	andi	a4,s1,7
    800032ba:	4785                	li	a5,1
    800032bc:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032c0:	14ce                	slli	s1,s1,0x33
    800032c2:	90d9                	srli	s1,s1,0x36
    800032c4:	00950733          	add	a4,a0,s1
    800032c8:	05874703          	lbu	a4,88(a4)
    800032cc:	00e7f6b3          	and	a3,a5,a4
    800032d0:	c69d                	beqz	a3,800032fe <bfree+0x6c>
    800032d2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032d4:	94aa                	add	s1,s1,a0
    800032d6:	fff7c793          	not	a5,a5
    800032da:	8ff9                	and	a5,a5,a4
    800032dc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032e0:	00001097          	auipc	ra,0x1
    800032e4:	100080e7          	jalr	256(ra) # 800043e0 <log_write>
  brelse(bp);
    800032e8:	854a                	mv	a0,s2
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	e92080e7          	jalr	-366(ra) # 8000317c <brelse>
}
    800032f2:	60e2                	ld	ra,24(sp)
    800032f4:	6442                	ld	s0,16(sp)
    800032f6:	64a2                	ld	s1,8(sp)
    800032f8:	6902                	ld	s2,0(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret
    panic("freeing free block");
    800032fe:	00005517          	auipc	a0,0x5
    80003302:	28a50513          	addi	a0,a0,650 # 80008588 <syscalls+0xe8>
    80003306:	ffffd097          	auipc	ra,0xffffd
    8000330a:	250080e7          	jalr	592(ra) # 80000556 <panic>

000000008000330e <balloc>:
{
    8000330e:	711d                	addi	sp,sp,-96
    80003310:	ec86                	sd	ra,88(sp)
    80003312:	e8a2                	sd	s0,80(sp)
    80003314:	e4a6                	sd	s1,72(sp)
    80003316:	e0ca                	sd	s2,64(sp)
    80003318:	fc4e                	sd	s3,56(sp)
    8000331a:	f852                	sd	s4,48(sp)
    8000331c:	f456                	sd	s5,40(sp)
    8000331e:	f05a                	sd	s6,32(sp)
    80003320:	ec5e                	sd	s7,24(sp)
    80003322:	e862                	sd	s8,16(sp)
    80003324:	e466                	sd	s9,8(sp)
    80003326:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003328:	0001d797          	auipc	a5,0x1d
    8000332c:	d1c7a783          	lw	a5,-740(a5) # 80020044 <sb+0x4>
    80003330:	cbd1                	beqz	a5,800033c4 <balloc+0xb6>
    80003332:	8baa                	mv	s7,a0
    80003334:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003336:	0001db17          	auipc	s6,0x1d
    8000333a:	d0ab0b13          	addi	s6,s6,-758 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003340:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003342:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003344:	6c89                	lui	s9,0x2
    80003346:	a831                	j	80003362 <balloc+0x54>
    brelse(bp);
    80003348:	854a                	mv	a0,s2
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	e32080e7          	jalr	-462(ra) # 8000317c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003352:	015c87bb          	addw	a5,s9,s5
    80003356:	00078a9b          	sext.w	s5,a5
    8000335a:	004b2703          	lw	a4,4(s6)
    8000335e:	06eaf363          	bgeu	s5,a4,800033c4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003362:	41fad79b          	sraiw	a5,s5,0x1f
    80003366:	0137d79b          	srliw	a5,a5,0x13
    8000336a:	015787bb          	addw	a5,a5,s5
    8000336e:	40d7d79b          	sraiw	a5,a5,0xd
    80003372:	01cb2583          	lw	a1,28(s6)
    80003376:	9dbd                	addw	a1,a1,a5
    80003378:	855e                	mv	a0,s7
    8000337a:	00000097          	auipc	ra,0x0
    8000337e:	cd2080e7          	jalr	-814(ra) # 8000304c <bread>
    80003382:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003384:	004b2503          	lw	a0,4(s6)
    80003388:	000a849b          	sext.w	s1,s5
    8000338c:	8662                	mv	a2,s8
    8000338e:	faa4fde3          	bgeu	s1,a0,80003348 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003392:	41f6579b          	sraiw	a5,a2,0x1f
    80003396:	01d7d69b          	srliw	a3,a5,0x1d
    8000339a:	00c6873b          	addw	a4,a3,a2
    8000339e:	00777793          	andi	a5,a4,7
    800033a2:	9f95                	subw	a5,a5,a3
    800033a4:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033a8:	4037571b          	sraiw	a4,a4,0x3
    800033ac:	00e906b3          	add	a3,s2,a4
    800033b0:	0586c683          	lbu	a3,88(a3)
    800033b4:	00d7f5b3          	and	a1,a5,a3
    800033b8:	cd91                	beqz	a1,800033d4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ba:	2605                	addiw	a2,a2,1
    800033bc:	2485                	addiw	s1,s1,1
    800033be:	fd4618e3          	bne	a2,s4,8000338e <balloc+0x80>
    800033c2:	b759                	j	80003348 <balloc+0x3a>
  panic("balloc: out of blocks");
    800033c4:	00005517          	auipc	a0,0x5
    800033c8:	1dc50513          	addi	a0,a0,476 # 800085a0 <syscalls+0x100>
    800033cc:	ffffd097          	auipc	ra,0xffffd
    800033d0:	18a080e7          	jalr	394(ra) # 80000556 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033d4:	974a                	add	a4,a4,s2
    800033d6:	8fd5                	or	a5,a5,a3
    800033d8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033dc:	854a                	mv	a0,s2
    800033de:	00001097          	auipc	ra,0x1
    800033e2:	002080e7          	jalr	2(ra) # 800043e0 <log_write>
        brelse(bp);
    800033e6:	854a                	mv	a0,s2
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	d94080e7          	jalr	-620(ra) # 8000317c <brelse>
  bp = bread(dev, bno);
    800033f0:	85a6                	mv	a1,s1
    800033f2:	855e                	mv	a0,s7
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	c58080e7          	jalr	-936(ra) # 8000304c <bread>
    800033fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033fe:	40000613          	li	a2,1024
    80003402:	4581                	li	a1,0
    80003404:	05850513          	addi	a0,a0,88
    80003408:	ffffe097          	auipc	ra,0xffffe
    8000340c:	912080e7          	jalr	-1774(ra) # 80000d1a <memset>
  log_write(bp);
    80003410:	854a                	mv	a0,s2
    80003412:	00001097          	auipc	ra,0x1
    80003416:	fce080e7          	jalr	-50(ra) # 800043e0 <log_write>
  brelse(bp);
    8000341a:	854a                	mv	a0,s2
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	d60080e7          	jalr	-672(ra) # 8000317c <brelse>
}
    80003424:	8526                	mv	a0,s1
    80003426:	60e6                	ld	ra,88(sp)
    80003428:	6446                	ld	s0,80(sp)
    8000342a:	64a6                	ld	s1,72(sp)
    8000342c:	6906                	ld	s2,64(sp)
    8000342e:	79e2                	ld	s3,56(sp)
    80003430:	7a42                	ld	s4,48(sp)
    80003432:	7aa2                	ld	s5,40(sp)
    80003434:	7b02                	ld	s6,32(sp)
    80003436:	6be2                	ld	s7,24(sp)
    80003438:	6c42                	ld	s8,16(sp)
    8000343a:	6ca2                	ld	s9,8(sp)
    8000343c:	6125                	addi	sp,sp,96
    8000343e:	8082                	ret

0000000080003440 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003440:	7179                	addi	sp,sp,-48
    80003442:	f406                	sd	ra,40(sp)
    80003444:	f022                	sd	s0,32(sp)
    80003446:	ec26                	sd	s1,24(sp)
    80003448:	e84a                	sd	s2,16(sp)
    8000344a:	e44e                	sd	s3,8(sp)
    8000344c:	e052                	sd	s4,0(sp)
    8000344e:	1800                	addi	s0,sp,48
    80003450:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003452:	47ad                	li	a5,11
    80003454:	04b7fe63          	bgeu	a5,a1,800034b0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003458:	ff45849b          	addiw	s1,a1,-12
    8000345c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003460:	0ff00793          	li	a5,255
    80003464:	0ae7e363          	bltu	a5,a4,8000350a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003468:	08052583          	lw	a1,128(a0)
    8000346c:	c5ad                	beqz	a1,800034d6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000346e:	00092503          	lw	a0,0(s2)
    80003472:	00000097          	auipc	ra,0x0
    80003476:	bda080e7          	jalr	-1062(ra) # 8000304c <bread>
    8000347a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000347c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003480:	02049593          	slli	a1,s1,0x20
    80003484:	9181                	srli	a1,a1,0x20
    80003486:	058a                	slli	a1,a1,0x2
    80003488:	00b784b3          	add	s1,a5,a1
    8000348c:	0004a983          	lw	s3,0(s1)
    80003490:	04098d63          	beqz	s3,800034ea <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003494:	8552                	mv	a0,s4
    80003496:	00000097          	auipc	ra,0x0
    8000349a:	ce6080e7          	jalr	-794(ra) # 8000317c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000349e:	854e                	mv	a0,s3
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6a02                	ld	s4,0(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800034b0:	02059493          	slli	s1,a1,0x20
    800034b4:	9081                	srli	s1,s1,0x20
    800034b6:	048a                	slli	s1,s1,0x2
    800034b8:	94aa                	add	s1,s1,a0
    800034ba:	0504a983          	lw	s3,80(s1)
    800034be:	fe0990e3          	bnez	s3,8000349e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800034c2:	4108                	lw	a0,0(a0)
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	e4a080e7          	jalr	-438(ra) # 8000330e <balloc>
    800034cc:	0005099b          	sext.w	s3,a0
    800034d0:	0534a823          	sw	s3,80(s1)
    800034d4:	b7e9                	j	8000349e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034d6:	4108                	lw	a0,0(a0)
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	e36080e7          	jalr	-458(ra) # 8000330e <balloc>
    800034e0:	0005059b          	sext.w	a1,a0
    800034e4:	08b92023          	sw	a1,128(s2)
    800034e8:	b759                	j	8000346e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034ea:	00092503          	lw	a0,0(s2)
    800034ee:	00000097          	auipc	ra,0x0
    800034f2:	e20080e7          	jalr	-480(ra) # 8000330e <balloc>
    800034f6:	0005099b          	sext.w	s3,a0
    800034fa:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034fe:	8552                	mv	a0,s4
    80003500:	00001097          	auipc	ra,0x1
    80003504:	ee0080e7          	jalr	-288(ra) # 800043e0 <log_write>
    80003508:	b771                	j	80003494 <bmap+0x54>
  panic("bmap: out of range");
    8000350a:	00005517          	auipc	a0,0x5
    8000350e:	0ae50513          	addi	a0,a0,174 # 800085b8 <syscalls+0x118>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	044080e7          	jalr	68(ra) # 80000556 <panic>

000000008000351a <iget>:
{
    8000351a:	7179                	addi	sp,sp,-48
    8000351c:	f406                	sd	ra,40(sp)
    8000351e:	f022                	sd	s0,32(sp)
    80003520:	ec26                	sd	s1,24(sp)
    80003522:	e84a                	sd	s2,16(sp)
    80003524:	e44e                	sd	s3,8(sp)
    80003526:	e052                	sd	s4,0(sp)
    80003528:	1800                	addi	s0,sp,48
    8000352a:	89aa                	mv	s3,a0
    8000352c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000352e:	0001d517          	auipc	a0,0x1d
    80003532:	b3250513          	addi	a0,a0,-1230 # 80020060 <icache>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	6e8080e7          	jalr	1768(ra) # 80000c1e <acquire>
  empty = 0;
    8000353e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003540:	0001d497          	auipc	s1,0x1d
    80003544:	b3848493          	addi	s1,s1,-1224 # 80020078 <icache+0x18>
    80003548:	0001e697          	auipc	a3,0x1e
    8000354c:	5c068693          	addi	a3,a3,1472 # 80021b08 <log>
    80003550:	a039                	j	8000355e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003552:	02090b63          	beqz	s2,80003588 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003556:	08848493          	addi	s1,s1,136
    8000355a:	02d48a63          	beq	s1,a3,8000358e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000355e:	449c                	lw	a5,8(s1)
    80003560:	fef059e3          	blez	a5,80003552 <iget+0x38>
    80003564:	4098                	lw	a4,0(s1)
    80003566:	ff3716e3          	bne	a4,s3,80003552 <iget+0x38>
    8000356a:	40d8                	lw	a4,4(s1)
    8000356c:	ff4713e3          	bne	a4,s4,80003552 <iget+0x38>
      ip->ref++;
    80003570:	2785                	addiw	a5,a5,1
    80003572:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003574:	0001d517          	auipc	a0,0x1d
    80003578:	aec50513          	addi	a0,a0,-1300 # 80020060 <icache>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	756080e7          	jalr	1878(ra) # 80000cd2 <release>
      return ip;
    80003584:	8926                	mv	s2,s1
    80003586:	a03d                	j	800035b4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003588:	f7f9                	bnez	a5,80003556 <iget+0x3c>
    8000358a:	8926                	mv	s2,s1
    8000358c:	b7e9                	j	80003556 <iget+0x3c>
  if(empty == 0)
    8000358e:	02090c63          	beqz	s2,800035c6 <iget+0xac>
  ip->dev = dev;
    80003592:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003596:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000359a:	4785                	li	a5,1
    8000359c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035a0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800035a4:	0001d517          	auipc	a0,0x1d
    800035a8:	abc50513          	addi	a0,a0,-1348 # 80020060 <icache>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	726080e7          	jalr	1830(ra) # 80000cd2 <release>
}
    800035b4:	854a                	mv	a0,s2
    800035b6:	70a2                	ld	ra,40(sp)
    800035b8:	7402                	ld	s0,32(sp)
    800035ba:	64e2                	ld	s1,24(sp)
    800035bc:	6942                	ld	s2,16(sp)
    800035be:	69a2                	ld	s3,8(sp)
    800035c0:	6a02                	ld	s4,0(sp)
    800035c2:	6145                	addi	sp,sp,48
    800035c4:	8082                	ret
    panic("iget: no inodes");
    800035c6:	00005517          	auipc	a0,0x5
    800035ca:	00a50513          	addi	a0,a0,10 # 800085d0 <syscalls+0x130>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	f88080e7          	jalr	-120(ra) # 80000556 <panic>

00000000800035d6 <fsinit>:
fsinit(int dev) {
    800035d6:	7179                	addi	sp,sp,-48
    800035d8:	f406                	sd	ra,40(sp)
    800035da:	f022                	sd	s0,32(sp)
    800035dc:	ec26                	sd	s1,24(sp)
    800035de:	e84a                	sd	s2,16(sp)
    800035e0:	e44e                	sd	s3,8(sp)
    800035e2:	1800                	addi	s0,sp,48
    800035e4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035e6:	4585                	li	a1,1
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	a64080e7          	jalr	-1436(ra) # 8000304c <bread>
    800035f0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035f2:	0001d997          	auipc	s3,0x1d
    800035f6:	a4e98993          	addi	s3,s3,-1458 # 80020040 <sb>
    800035fa:	02000613          	li	a2,32
    800035fe:	05850593          	addi	a1,a0,88
    80003602:	854e                	mv	a0,s3
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	776080e7          	jalr	1910(ra) # 80000d7a <memmove>
  brelse(bp);
    8000360c:	8526                	mv	a0,s1
    8000360e:	00000097          	auipc	ra,0x0
    80003612:	b6e080e7          	jalr	-1170(ra) # 8000317c <brelse>
  if(sb.magic != FSMAGIC)
    80003616:	0009a703          	lw	a4,0(s3)
    8000361a:	102037b7          	lui	a5,0x10203
    8000361e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003622:	02f71263          	bne	a4,a5,80003646 <fsinit+0x70>
  initlog(dev, &sb);
    80003626:	0001d597          	auipc	a1,0x1d
    8000362a:	a1a58593          	addi	a1,a1,-1510 # 80020040 <sb>
    8000362e:	854a                	mv	a0,s2
    80003630:	00001097          	auipc	ra,0x1
    80003634:	b38080e7          	jalr	-1224(ra) # 80004168 <initlog>
}
    80003638:	70a2                	ld	ra,40(sp)
    8000363a:	7402                	ld	s0,32(sp)
    8000363c:	64e2                	ld	s1,24(sp)
    8000363e:	6942                	ld	s2,16(sp)
    80003640:	69a2                	ld	s3,8(sp)
    80003642:	6145                	addi	sp,sp,48
    80003644:	8082                	ret
    panic("invalid file system");
    80003646:	00005517          	auipc	a0,0x5
    8000364a:	f9a50513          	addi	a0,a0,-102 # 800085e0 <syscalls+0x140>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	f08080e7          	jalr	-248(ra) # 80000556 <panic>

0000000080003656 <iinit>:
{
    80003656:	7179                	addi	sp,sp,-48
    80003658:	f406                	sd	ra,40(sp)
    8000365a:	f022                	sd	s0,32(sp)
    8000365c:	ec26                	sd	s1,24(sp)
    8000365e:	e84a                	sd	s2,16(sp)
    80003660:	e44e                	sd	s3,8(sp)
    80003662:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003664:	00005597          	auipc	a1,0x5
    80003668:	f9458593          	addi	a1,a1,-108 # 800085f8 <syscalls+0x158>
    8000366c:	0001d517          	auipc	a0,0x1d
    80003670:	9f450513          	addi	a0,a0,-1548 # 80020060 <icache>
    80003674:	ffffd097          	auipc	ra,0xffffd
    80003678:	51a080e7          	jalr	1306(ra) # 80000b8e <initlock>
  for(i = 0; i < NINODE; i++) {
    8000367c:	0001d497          	auipc	s1,0x1d
    80003680:	a0c48493          	addi	s1,s1,-1524 # 80020088 <icache+0x28>
    80003684:	0001e997          	auipc	s3,0x1e
    80003688:	49498993          	addi	s3,s3,1172 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000368c:	00005917          	auipc	s2,0x5
    80003690:	f7490913          	addi	s2,s2,-140 # 80008600 <syscalls+0x160>
    80003694:	85ca                	mv	a1,s2
    80003696:	8526                	mv	a0,s1
    80003698:	00001097          	auipc	ra,0x1
    8000369c:	e36080e7          	jalr	-458(ra) # 800044ce <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036a0:	08848493          	addi	s1,s1,136
    800036a4:	ff3498e3          	bne	s1,s3,80003694 <iinit+0x3e>
}
    800036a8:	70a2                	ld	ra,40(sp)
    800036aa:	7402                	ld	s0,32(sp)
    800036ac:	64e2                	ld	s1,24(sp)
    800036ae:	6942                	ld	s2,16(sp)
    800036b0:	69a2                	ld	s3,8(sp)
    800036b2:	6145                	addi	sp,sp,48
    800036b4:	8082                	ret

00000000800036b6 <ialloc>:
{
    800036b6:	715d                	addi	sp,sp,-80
    800036b8:	e486                	sd	ra,72(sp)
    800036ba:	e0a2                	sd	s0,64(sp)
    800036bc:	fc26                	sd	s1,56(sp)
    800036be:	f84a                	sd	s2,48(sp)
    800036c0:	f44e                	sd	s3,40(sp)
    800036c2:	f052                	sd	s4,32(sp)
    800036c4:	ec56                	sd	s5,24(sp)
    800036c6:	e85a                	sd	s6,16(sp)
    800036c8:	e45e                	sd	s7,8(sp)
    800036ca:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036cc:	0001d717          	auipc	a4,0x1d
    800036d0:	98072703          	lw	a4,-1664(a4) # 8002004c <sb+0xc>
    800036d4:	4785                	li	a5,1
    800036d6:	04e7fa63          	bgeu	a5,a4,8000372a <ialloc+0x74>
    800036da:	8aaa                	mv	s5,a0
    800036dc:	8bae                	mv	s7,a1
    800036de:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036e0:	0001da17          	auipc	s4,0x1d
    800036e4:	960a0a13          	addi	s4,s4,-1696 # 80020040 <sb>
    800036e8:	00048b1b          	sext.w	s6,s1
    800036ec:	0044d593          	srli	a1,s1,0x4
    800036f0:	018a2783          	lw	a5,24(s4)
    800036f4:	9dbd                	addw	a1,a1,a5
    800036f6:	8556                	mv	a0,s5
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	954080e7          	jalr	-1708(ra) # 8000304c <bread>
    80003700:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003702:	05850993          	addi	s3,a0,88
    80003706:	00f4f793          	andi	a5,s1,15
    8000370a:	079a                	slli	a5,a5,0x6
    8000370c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000370e:	00099783          	lh	a5,0(s3)
    80003712:	c785                	beqz	a5,8000373a <ialloc+0x84>
    brelse(bp);
    80003714:	00000097          	auipc	ra,0x0
    80003718:	a68080e7          	jalr	-1432(ra) # 8000317c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000371c:	0485                	addi	s1,s1,1
    8000371e:	00ca2703          	lw	a4,12(s4)
    80003722:	0004879b          	sext.w	a5,s1
    80003726:	fce7e1e3          	bltu	a5,a4,800036e8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000372a:	00005517          	auipc	a0,0x5
    8000372e:	ede50513          	addi	a0,a0,-290 # 80008608 <syscalls+0x168>
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	e24080e7          	jalr	-476(ra) # 80000556 <panic>
      memset(dip, 0, sizeof(*dip));
    8000373a:	04000613          	li	a2,64
    8000373e:	4581                	li	a1,0
    80003740:	854e                	mv	a0,s3
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	5d8080e7          	jalr	1496(ra) # 80000d1a <memset>
      dip->type = type;
    8000374a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000374e:	854a                	mv	a0,s2
    80003750:	00001097          	auipc	ra,0x1
    80003754:	c90080e7          	jalr	-880(ra) # 800043e0 <log_write>
      brelse(bp);
    80003758:	854a                	mv	a0,s2
    8000375a:	00000097          	auipc	ra,0x0
    8000375e:	a22080e7          	jalr	-1502(ra) # 8000317c <brelse>
      return iget(dev, inum);
    80003762:	85da                	mv	a1,s6
    80003764:	8556                	mv	a0,s5
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	db4080e7          	jalr	-588(ra) # 8000351a <iget>
}
    8000376e:	60a6                	ld	ra,72(sp)
    80003770:	6406                	ld	s0,64(sp)
    80003772:	74e2                	ld	s1,56(sp)
    80003774:	7942                	ld	s2,48(sp)
    80003776:	79a2                	ld	s3,40(sp)
    80003778:	7a02                	ld	s4,32(sp)
    8000377a:	6ae2                	ld	s5,24(sp)
    8000377c:	6b42                	ld	s6,16(sp)
    8000377e:	6ba2                	ld	s7,8(sp)
    80003780:	6161                	addi	sp,sp,80
    80003782:	8082                	ret

0000000080003784 <iupdate>:
{
    80003784:	1101                	addi	sp,sp,-32
    80003786:	ec06                	sd	ra,24(sp)
    80003788:	e822                	sd	s0,16(sp)
    8000378a:	e426                	sd	s1,8(sp)
    8000378c:	e04a                	sd	s2,0(sp)
    8000378e:	1000                	addi	s0,sp,32
    80003790:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003792:	415c                	lw	a5,4(a0)
    80003794:	0047d79b          	srliw	a5,a5,0x4
    80003798:	0001d597          	auipc	a1,0x1d
    8000379c:	8c05a583          	lw	a1,-1856(a1) # 80020058 <sb+0x18>
    800037a0:	9dbd                	addw	a1,a1,a5
    800037a2:	4108                	lw	a0,0(a0)
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	8a8080e7          	jalr	-1880(ra) # 8000304c <bread>
    800037ac:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037ae:	05850793          	addi	a5,a0,88
    800037b2:	40c8                	lw	a0,4(s1)
    800037b4:	893d                	andi	a0,a0,15
    800037b6:	051a                	slli	a0,a0,0x6
    800037b8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037ba:	04449703          	lh	a4,68(s1)
    800037be:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037c2:	04649703          	lh	a4,70(s1)
    800037c6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037ca:	04849703          	lh	a4,72(s1)
    800037ce:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037d2:	04a49703          	lh	a4,74(s1)
    800037d6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037da:	44f8                	lw	a4,76(s1)
    800037dc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037de:	03400613          	li	a2,52
    800037e2:	05048593          	addi	a1,s1,80
    800037e6:	0531                	addi	a0,a0,12
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	592080e7          	jalr	1426(ra) # 80000d7a <memmove>
  log_write(bp);
    800037f0:	854a                	mv	a0,s2
    800037f2:	00001097          	auipc	ra,0x1
    800037f6:	bee080e7          	jalr	-1042(ra) # 800043e0 <log_write>
  brelse(bp);
    800037fa:	854a                	mv	a0,s2
    800037fc:	00000097          	auipc	ra,0x0
    80003800:	980080e7          	jalr	-1664(ra) # 8000317c <brelse>
}
    80003804:	60e2                	ld	ra,24(sp)
    80003806:	6442                	ld	s0,16(sp)
    80003808:	64a2                	ld	s1,8(sp)
    8000380a:	6902                	ld	s2,0(sp)
    8000380c:	6105                	addi	sp,sp,32
    8000380e:	8082                	ret

0000000080003810 <idup>:
{
    80003810:	1101                	addi	sp,sp,-32
    80003812:	ec06                	sd	ra,24(sp)
    80003814:	e822                	sd	s0,16(sp)
    80003816:	e426                	sd	s1,8(sp)
    80003818:	1000                	addi	s0,sp,32
    8000381a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000381c:	0001d517          	auipc	a0,0x1d
    80003820:	84450513          	addi	a0,a0,-1980 # 80020060 <icache>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	3fa080e7          	jalr	1018(ra) # 80000c1e <acquire>
  ip->ref++;
    8000382c:	449c                	lw	a5,8(s1)
    8000382e:	2785                	addiw	a5,a5,1
    80003830:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003832:	0001d517          	auipc	a0,0x1d
    80003836:	82e50513          	addi	a0,a0,-2002 # 80020060 <icache>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	498080e7          	jalr	1176(ra) # 80000cd2 <release>
}
    80003842:	8526                	mv	a0,s1
    80003844:	60e2                	ld	ra,24(sp)
    80003846:	6442                	ld	s0,16(sp)
    80003848:	64a2                	ld	s1,8(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret

000000008000384e <ilock>:
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	e04a                	sd	s2,0(sp)
    80003858:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000385a:	c115                	beqz	a0,8000387e <ilock+0x30>
    8000385c:	84aa                	mv	s1,a0
    8000385e:	451c                	lw	a5,8(a0)
    80003860:	00f05f63          	blez	a5,8000387e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003864:	0541                	addi	a0,a0,16
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	ca2080e7          	jalr	-862(ra) # 80004508 <acquiresleep>
  if(ip->valid == 0){
    8000386e:	40bc                	lw	a5,64(s1)
    80003870:	cf99                	beqz	a5,8000388e <ilock+0x40>
}
    80003872:	60e2                	ld	ra,24(sp)
    80003874:	6442                	ld	s0,16(sp)
    80003876:	64a2                	ld	s1,8(sp)
    80003878:	6902                	ld	s2,0(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret
    panic("ilock");
    8000387e:	00005517          	auipc	a0,0x5
    80003882:	da250513          	addi	a0,a0,-606 # 80008620 <syscalls+0x180>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	cd0080e7          	jalr	-816(ra) # 80000556 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000388e:	40dc                	lw	a5,4(s1)
    80003890:	0047d79b          	srliw	a5,a5,0x4
    80003894:	0001c597          	auipc	a1,0x1c
    80003898:	7c45a583          	lw	a1,1988(a1) # 80020058 <sb+0x18>
    8000389c:	9dbd                	addw	a1,a1,a5
    8000389e:	4088                	lw	a0,0(s1)
    800038a0:	fffff097          	auipc	ra,0xfffff
    800038a4:	7ac080e7          	jalr	1964(ra) # 8000304c <bread>
    800038a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038aa:	05850593          	addi	a1,a0,88
    800038ae:	40dc                	lw	a5,4(s1)
    800038b0:	8bbd                	andi	a5,a5,15
    800038b2:	079a                	slli	a5,a5,0x6
    800038b4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038b6:	00059783          	lh	a5,0(a1)
    800038ba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038be:	00259783          	lh	a5,2(a1)
    800038c2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038c6:	00459783          	lh	a5,4(a1)
    800038ca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038ce:	00659783          	lh	a5,6(a1)
    800038d2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038d6:	459c                	lw	a5,8(a1)
    800038d8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038da:	03400613          	li	a2,52
    800038de:	05b1                	addi	a1,a1,12
    800038e0:	05048513          	addi	a0,s1,80
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	496080e7          	jalr	1174(ra) # 80000d7a <memmove>
    brelse(bp);
    800038ec:	854a                	mv	a0,s2
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	88e080e7          	jalr	-1906(ra) # 8000317c <brelse>
    ip->valid = 1;
    800038f6:	4785                	li	a5,1
    800038f8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038fa:	04449783          	lh	a5,68(s1)
    800038fe:	fbb5                	bnez	a5,80003872 <ilock+0x24>
      panic("ilock: no type");
    80003900:	00005517          	auipc	a0,0x5
    80003904:	d2850513          	addi	a0,a0,-728 # 80008628 <syscalls+0x188>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	c4e080e7          	jalr	-946(ra) # 80000556 <panic>

0000000080003910 <iunlock>:
{
    80003910:	1101                	addi	sp,sp,-32
    80003912:	ec06                	sd	ra,24(sp)
    80003914:	e822                	sd	s0,16(sp)
    80003916:	e426                	sd	s1,8(sp)
    80003918:	e04a                	sd	s2,0(sp)
    8000391a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000391c:	c905                	beqz	a0,8000394c <iunlock+0x3c>
    8000391e:	84aa                	mv	s1,a0
    80003920:	01050913          	addi	s2,a0,16
    80003924:	854a                	mv	a0,s2
    80003926:	00001097          	auipc	ra,0x1
    8000392a:	c7c080e7          	jalr	-900(ra) # 800045a2 <holdingsleep>
    8000392e:	cd19                	beqz	a0,8000394c <iunlock+0x3c>
    80003930:	449c                	lw	a5,8(s1)
    80003932:	00f05d63          	blez	a5,8000394c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003936:	854a                	mv	a0,s2
    80003938:	00001097          	auipc	ra,0x1
    8000393c:	c26080e7          	jalr	-986(ra) # 8000455e <releasesleep>
}
    80003940:	60e2                	ld	ra,24(sp)
    80003942:	6442                	ld	s0,16(sp)
    80003944:	64a2                	ld	s1,8(sp)
    80003946:	6902                	ld	s2,0(sp)
    80003948:	6105                	addi	sp,sp,32
    8000394a:	8082                	ret
    panic("iunlock");
    8000394c:	00005517          	auipc	a0,0x5
    80003950:	cec50513          	addi	a0,a0,-788 # 80008638 <syscalls+0x198>
    80003954:	ffffd097          	auipc	ra,0xffffd
    80003958:	c02080e7          	jalr	-1022(ra) # 80000556 <panic>

000000008000395c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000395c:	7179                	addi	sp,sp,-48
    8000395e:	f406                	sd	ra,40(sp)
    80003960:	f022                	sd	s0,32(sp)
    80003962:	ec26                	sd	s1,24(sp)
    80003964:	e84a                	sd	s2,16(sp)
    80003966:	e44e                	sd	s3,8(sp)
    80003968:	e052                	sd	s4,0(sp)
    8000396a:	1800                	addi	s0,sp,48
    8000396c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000396e:	05050493          	addi	s1,a0,80
    80003972:	08050913          	addi	s2,a0,128
    80003976:	a021                	j	8000397e <itrunc+0x22>
    80003978:	0491                	addi	s1,s1,4
    8000397a:	01248d63          	beq	s1,s2,80003994 <itrunc+0x38>
    if(ip->addrs[i]){
    8000397e:	408c                	lw	a1,0(s1)
    80003980:	dde5                	beqz	a1,80003978 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003982:	0009a503          	lw	a0,0(s3)
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	90c080e7          	jalr	-1780(ra) # 80003292 <bfree>
      ip->addrs[i] = 0;
    8000398e:	0004a023          	sw	zero,0(s1)
    80003992:	b7dd                	j	80003978 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003994:	0809a583          	lw	a1,128(s3)
    80003998:	e185                	bnez	a1,800039b8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000399a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000399e:	854e                	mv	a0,s3
    800039a0:	00000097          	auipc	ra,0x0
    800039a4:	de4080e7          	jalr	-540(ra) # 80003784 <iupdate>
}
    800039a8:	70a2                	ld	ra,40(sp)
    800039aa:	7402                	ld	s0,32(sp)
    800039ac:	64e2                	ld	s1,24(sp)
    800039ae:	6942                	ld	s2,16(sp)
    800039b0:	69a2                	ld	s3,8(sp)
    800039b2:	6a02                	ld	s4,0(sp)
    800039b4:	6145                	addi	sp,sp,48
    800039b6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039b8:	0009a503          	lw	a0,0(s3)
    800039bc:	fffff097          	auipc	ra,0xfffff
    800039c0:	690080e7          	jalr	1680(ra) # 8000304c <bread>
    800039c4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039c6:	05850493          	addi	s1,a0,88
    800039ca:	45850913          	addi	s2,a0,1112
    800039ce:	a811                	j	800039e2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039d0:	0009a503          	lw	a0,0(s3)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	8be080e7          	jalr	-1858(ra) # 80003292 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039dc:	0491                	addi	s1,s1,4
    800039de:	01248563          	beq	s1,s2,800039e8 <itrunc+0x8c>
      if(a[j])
    800039e2:	408c                	lw	a1,0(s1)
    800039e4:	dde5                	beqz	a1,800039dc <itrunc+0x80>
    800039e6:	b7ed                	j	800039d0 <itrunc+0x74>
    brelse(bp);
    800039e8:	8552                	mv	a0,s4
    800039ea:	fffff097          	auipc	ra,0xfffff
    800039ee:	792080e7          	jalr	1938(ra) # 8000317c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039f2:	0809a583          	lw	a1,128(s3)
    800039f6:	0009a503          	lw	a0,0(s3)
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	898080e7          	jalr	-1896(ra) # 80003292 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a02:	0809a023          	sw	zero,128(s3)
    80003a06:	bf51                	j	8000399a <itrunc+0x3e>

0000000080003a08 <iput>:
{
    80003a08:	1101                	addi	sp,sp,-32
    80003a0a:	ec06                	sd	ra,24(sp)
    80003a0c:	e822                	sd	s0,16(sp)
    80003a0e:	e426                	sd	s1,8(sp)
    80003a10:	e04a                	sd	s2,0(sp)
    80003a12:	1000                	addi	s0,sp,32
    80003a14:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003a16:	0001c517          	auipc	a0,0x1c
    80003a1a:	64a50513          	addi	a0,a0,1610 # 80020060 <icache>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	200080e7          	jalr	512(ra) # 80000c1e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a26:	4498                	lw	a4,8(s1)
    80003a28:	4785                	li	a5,1
    80003a2a:	02f70363          	beq	a4,a5,80003a50 <iput+0x48>
  ip->ref--;
    80003a2e:	449c                	lw	a5,8(s1)
    80003a30:	37fd                	addiw	a5,a5,-1
    80003a32:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a34:	0001c517          	auipc	a0,0x1c
    80003a38:	62c50513          	addi	a0,a0,1580 # 80020060 <icache>
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	296080e7          	jalr	662(ra) # 80000cd2 <release>
}
    80003a44:	60e2                	ld	ra,24(sp)
    80003a46:	6442                	ld	s0,16(sp)
    80003a48:	64a2                	ld	s1,8(sp)
    80003a4a:	6902                	ld	s2,0(sp)
    80003a4c:	6105                	addi	sp,sp,32
    80003a4e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a50:	40bc                	lw	a5,64(s1)
    80003a52:	dff1                	beqz	a5,80003a2e <iput+0x26>
    80003a54:	04a49783          	lh	a5,74(s1)
    80003a58:	fbf9                	bnez	a5,80003a2e <iput+0x26>
    acquiresleep(&ip->lock);
    80003a5a:	01048913          	addi	s2,s1,16
    80003a5e:	854a                	mv	a0,s2
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	aa8080e7          	jalr	-1368(ra) # 80004508 <acquiresleep>
    release(&icache.lock);
    80003a68:	0001c517          	auipc	a0,0x1c
    80003a6c:	5f850513          	addi	a0,a0,1528 # 80020060 <icache>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	262080e7          	jalr	610(ra) # 80000cd2 <release>
    itrunc(ip);
    80003a78:	8526                	mv	a0,s1
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	ee2080e7          	jalr	-286(ra) # 8000395c <itrunc>
    ip->type = 0;
    80003a82:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a86:	8526                	mv	a0,s1
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	cfc080e7          	jalr	-772(ra) # 80003784 <iupdate>
    ip->valid = 0;
    80003a90:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a94:	854a                	mv	a0,s2
    80003a96:	00001097          	auipc	ra,0x1
    80003a9a:	ac8080e7          	jalr	-1336(ra) # 8000455e <releasesleep>
    acquire(&icache.lock);
    80003a9e:	0001c517          	auipc	a0,0x1c
    80003aa2:	5c250513          	addi	a0,a0,1474 # 80020060 <icache>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	178080e7          	jalr	376(ra) # 80000c1e <acquire>
    80003aae:	b741                	j	80003a2e <iput+0x26>

0000000080003ab0 <iunlockput>:
{
    80003ab0:	1101                	addi	sp,sp,-32
    80003ab2:	ec06                	sd	ra,24(sp)
    80003ab4:	e822                	sd	s0,16(sp)
    80003ab6:	e426                	sd	s1,8(sp)
    80003ab8:	1000                	addi	s0,sp,32
    80003aba:	84aa                	mv	s1,a0
  iunlock(ip);
    80003abc:	00000097          	auipc	ra,0x0
    80003ac0:	e54080e7          	jalr	-428(ra) # 80003910 <iunlock>
  iput(ip);
    80003ac4:	8526                	mv	a0,s1
    80003ac6:	00000097          	auipc	ra,0x0
    80003aca:	f42080e7          	jalr	-190(ra) # 80003a08 <iput>
}
    80003ace:	60e2                	ld	ra,24(sp)
    80003ad0:	6442                	ld	s0,16(sp)
    80003ad2:	64a2                	ld	s1,8(sp)
    80003ad4:	6105                	addi	sp,sp,32
    80003ad6:	8082                	ret

0000000080003ad8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ad8:	1141                	addi	sp,sp,-16
    80003ada:	e422                	sd	s0,8(sp)
    80003adc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ade:	411c                	lw	a5,0(a0)
    80003ae0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ae2:	415c                	lw	a5,4(a0)
    80003ae4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ae6:	04451783          	lh	a5,68(a0)
    80003aea:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003aee:	04a51783          	lh	a5,74(a0)
    80003af2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003af6:	04c56783          	lwu	a5,76(a0)
    80003afa:	e99c                	sd	a5,16(a1)
}
    80003afc:	6422                	ld	s0,8(sp)
    80003afe:	0141                	addi	sp,sp,16
    80003b00:	8082                	ret

0000000080003b02 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b02:	457c                	lw	a5,76(a0)
    80003b04:	0ed7e863          	bltu	a5,a3,80003bf4 <readi+0xf2>
{
    80003b08:	7159                	addi	sp,sp,-112
    80003b0a:	f486                	sd	ra,104(sp)
    80003b0c:	f0a2                	sd	s0,96(sp)
    80003b0e:	eca6                	sd	s1,88(sp)
    80003b10:	e8ca                	sd	s2,80(sp)
    80003b12:	e4ce                	sd	s3,72(sp)
    80003b14:	e0d2                	sd	s4,64(sp)
    80003b16:	fc56                	sd	s5,56(sp)
    80003b18:	f85a                	sd	s6,48(sp)
    80003b1a:	f45e                	sd	s7,40(sp)
    80003b1c:	f062                	sd	s8,32(sp)
    80003b1e:	ec66                	sd	s9,24(sp)
    80003b20:	e86a                	sd	s10,16(sp)
    80003b22:	e46e                	sd	s11,8(sp)
    80003b24:	1880                	addi	s0,sp,112
    80003b26:	8baa                	mv	s7,a0
    80003b28:	8c2e                	mv	s8,a1
    80003b2a:	8ab2                	mv	s5,a2
    80003b2c:	84b6                	mv	s1,a3
    80003b2e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b30:	9f35                	addw	a4,a4,a3
    return 0;
    80003b32:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b34:	08d76f63          	bltu	a4,a3,80003bd2 <readi+0xd0>
  if(off + n > ip->size)
    80003b38:	00e7f463          	bgeu	a5,a4,80003b40 <readi+0x3e>
    n = ip->size - off;
    80003b3c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b40:	0a0b0863          	beqz	s6,80003bf0 <readi+0xee>
    80003b44:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b46:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b4a:	5cfd                	li	s9,-1
    80003b4c:	a82d                	j	80003b86 <readi+0x84>
    80003b4e:	020a1d93          	slli	s11,s4,0x20
    80003b52:	020ddd93          	srli	s11,s11,0x20
    80003b56:	05890613          	addi	a2,s2,88
    80003b5a:	86ee                	mv	a3,s11
    80003b5c:	963a                	add	a2,a2,a4
    80003b5e:	85d6                	mv	a1,s5
    80003b60:	8562                	mv	a0,s8
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	b2e080e7          	jalr	-1234(ra) # 80002690 <either_copyout>
    80003b6a:	05950d63          	beq	a0,s9,80003bc4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003b6e:	854a                	mv	a0,s2
    80003b70:	fffff097          	auipc	ra,0xfffff
    80003b74:	60c080e7          	jalr	1548(ra) # 8000317c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b78:	013a09bb          	addw	s3,s4,s3
    80003b7c:	009a04bb          	addw	s1,s4,s1
    80003b80:	9aee                	add	s5,s5,s11
    80003b82:	0569f663          	bgeu	s3,s6,80003bce <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b86:	000ba903          	lw	s2,0(s7)
    80003b8a:	00a4d59b          	srliw	a1,s1,0xa
    80003b8e:	855e                	mv	a0,s7
    80003b90:	00000097          	auipc	ra,0x0
    80003b94:	8b0080e7          	jalr	-1872(ra) # 80003440 <bmap>
    80003b98:	0005059b          	sext.w	a1,a0
    80003b9c:	854a                	mv	a0,s2
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	4ae080e7          	jalr	1198(ra) # 8000304c <bread>
    80003ba6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ba8:	3ff4f713          	andi	a4,s1,1023
    80003bac:	40ed07bb          	subw	a5,s10,a4
    80003bb0:	413b06bb          	subw	a3,s6,s3
    80003bb4:	8a3e                	mv	s4,a5
    80003bb6:	2781                	sext.w	a5,a5
    80003bb8:	0006861b          	sext.w	a2,a3
    80003bbc:	f8f679e3          	bgeu	a2,a5,80003b4e <readi+0x4c>
    80003bc0:	8a36                	mv	s4,a3
    80003bc2:	b771                	j	80003b4e <readi+0x4c>
      brelse(bp);
    80003bc4:	854a                	mv	a0,s2
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	5b6080e7          	jalr	1462(ra) # 8000317c <brelse>
  }
  return tot;
    80003bce:	0009851b          	sext.w	a0,s3
}
    80003bd2:	70a6                	ld	ra,104(sp)
    80003bd4:	7406                	ld	s0,96(sp)
    80003bd6:	64e6                	ld	s1,88(sp)
    80003bd8:	6946                	ld	s2,80(sp)
    80003bda:	69a6                	ld	s3,72(sp)
    80003bdc:	6a06                	ld	s4,64(sp)
    80003bde:	7ae2                	ld	s5,56(sp)
    80003be0:	7b42                	ld	s6,48(sp)
    80003be2:	7ba2                	ld	s7,40(sp)
    80003be4:	7c02                	ld	s8,32(sp)
    80003be6:	6ce2                	ld	s9,24(sp)
    80003be8:	6d42                	ld	s10,16(sp)
    80003bea:	6da2                	ld	s11,8(sp)
    80003bec:	6165                	addi	sp,sp,112
    80003bee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf0:	89da                	mv	s3,s6
    80003bf2:	bff1                	j	80003bce <readi+0xcc>
    return 0;
    80003bf4:	4501                	li	a0,0
}
    80003bf6:	8082                	ret

0000000080003bf8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bf8:	457c                	lw	a5,76(a0)
    80003bfa:	10d7e663          	bltu	a5,a3,80003d06 <writei+0x10e>
{
    80003bfe:	7159                	addi	sp,sp,-112
    80003c00:	f486                	sd	ra,104(sp)
    80003c02:	f0a2                	sd	s0,96(sp)
    80003c04:	eca6                	sd	s1,88(sp)
    80003c06:	e8ca                	sd	s2,80(sp)
    80003c08:	e4ce                	sd	s3,72(sp)
    80003c0a:	e0d2                	sd	s4,64(sp)
    80003c0c:	fc56                	sd	s5,56(sp)
    80003c0e:	f85a                	sd	s6,48(sp)
    80003c10:	f45e                	sd	s7,40(sp)
    80003c12:	f062                	sd	s8,32(sp)
    80003c14:	ec66                	sd	s9,24(sp)
    80003c16:	e86a                	sd	s10,16(sp)
    80003c18:	e46e                	sd	s11,8(sp)
    80003c1a:	1880                	addi	s0,sp,112
    80003c1c:	8baa                	mv	s7,a0
    80003c1e:	8c2e                	mv	s8,a1
    80003c20:	8ab2                	mv	s5,a2
    80003c22:	8936                	mv	s2,a3
    80003c24:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c26:	00e687bb          	addw	a5,a3,a4
    80003c2a:	0ed7e063          	bltu	a5,a3,80003d0a <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c2e:	00043737          	lui	a4,0x43
    80003c32:	0cf76e63          	bltu	a4,a5,80003d0e <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c36:	0a0b0763          	beqz	s6,80003ce4 <writei+0xec>
    80003c3a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c40:	5cfd                	li	s9,-1
    80003c42:	a091                	j	80003c86 <writei+0x8e>
    80003c44:	02099d93          	slli	s11,s3,0x20
    80003c48:	020ddd93          	srli	s11,s11,0x20
    80003c4c:	05848513          	addi	a0,s1,88
    80003c50:	86ee                	mv	a3,s11
    80003c52:	8656                	mv	a2,s5
    80003c54:	85e2                	mv	a1,s8
    80003c56:	953a                	add	a0,a0,a4
    80003c58:	fffff097          	auipc	ra,0xfffff
    80003c5c:	a8e080e7          	jalr	-1394(ra) # 800026e6 <either_copyin>
    80003c60:	07950263          	beq	a0,s9,80003cc4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c64:	8526                	mv	a0,s1
    80003c66:	00000097          	auipc	ra,0x0
    80003c6a:	77a080e7          	jalr	1914(ra) # 800043e0 <log_write>
    brelse(bp);
    80003c6e:	8526                	mv	a0,s1
    80003c70:	fffff097          	auipc	ra,0xfffff
    80003c74:	50c080e7          	jalr	1292(ra) # 8000317c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c78:	01498a3b          	addw	s4,s3,s4
    80003c7c:	0129893b          	addw	s2,s3,s2
    80003c80:	9aee                	add	s5,s5,s11
    80003c82:	056a7663          	bgeu	s4,s6,80003cce <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c86:	000ba483          	lw	s1,0(s7)
    80003c8a:	00a9559b          	srliw	a1,s2,0xa
    80003c8e:	855e                	mv	a0,s7
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	7b0080e7          	jalr	1968(ra) # 80003440 <bmap>
    80003c98:	0005059b          	sext.w	a1,a0
    80003c9c:	8526                	mv	a0,s1
    80003c9e:	fffff097          	auipc	ra,0xfffff
    80003ca2:	3ae080e7          	jalr	942(ra) # 8000304c <bread>
    80003ca6:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ca8:	3ff97713          	andi	a4,s2,1023
    80003cac:	40ed07bb          	subw	a5,s10,a4
    80003cb0:	414b06bb          	subw	a3,s6,s4
    80003cb4:	89be                	mv	s3,a5
    80003cb6:	2781                	sext.w	a5,a5
    80003cb8:	0006861b          	sext.w	a2,a3
    80003cbc:	f8f674e3          	bgeu	a2,a5,80003c44 <writei+0x4c>
    80003cc0:	89b6                	mv	s3,a3
    80003cc2:	b749                	j	80003c44 <writei+0x4c>
      brelse(bp);
    80003cc4:	8526                	mv	a0,s1
    80003cc6:	fffff097          	auipc	ra,0xfffff
    80003cca:	4b6080e7          	jalr	1206(ra) # 8000317c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003cce:	04cba783          	lw	a5,76(s7)
    80003cd2:	0127f463          	bgeu	a5,s2,80003cda <writei+0xe2>
      ip->size = off;
    80003cd6:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cda:	855e                	mv	a0,s7
    80003cdc:	00000097          	auipc	ra,0x0
    80003ce0:	aa8080e7          	jalr	-1368(ra) # 80003784 <iupdate>
  }

  return n;
    80003ce4:	000b051b          	sext.w	a0,s6
}
    80003ce8:	70a6                	ld	ra,104(sp)
    80003cea:	7406                	ld	s0,96(sp)
    80003cec:	64e6                	ld	s1,88(sp)
    80003cee:	6946                	ld	s2,80(sp)
    80003cf0:	69a6                	ld	s3,72(sp)
    80003cf2:	6a06                	ld	s4,64(sp)
    80003cf4:	7ae2                	ld	s5,56(sp)
    80003cf6:	7b42                	ld	s6,48(sp)
    80003cf8:	7ba2                	ld	s7,40(sp)
    80003cfa:	7c02                	ld	s8,32(sp)
    80003cfc:	6ce2                	ld	s9,24(sp)
    80003cfe:	6d42                	ld	s10,16(sp)
    80003d00:	6da2                	ld	s11,8(sp)
    80003d02:	6165                	addi	sp,sp,112
    80003d04:	8082                	ret
    return -1;
    80003d06:	557d                	li	a0,-1
}
    80003d08:	8082                	ret
    return -1;
    80003d0a:	557d                	li	a0,-1
    80003d0c:	bff1                	j	80003ce8 <writei+0xf0>
    return -1;
    80003d0e:	557d                	li	a0,-1
    80003d10:	bfe1                	j	80003ce8 <writei+0xf0>

0000000080003d12 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d12:	1141                	addi	sp,sp,-16
    80003d14:	e406                	sd	ra,8(sp)
    80003d16:	e022                	sd	s0,0(sp)
    80003d18:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d1a:	4639                	li	a2,14
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	0da080e7          	jalr	218(ra) # 80000df6 <strncmp>
}
    80003d24:	60a2                	ld	ra,8(sp)
    80003d26:	6402                	ld	s0,0(sp)
    80003d28:	0141                	addi	sp,sp,16
    80003d2a:	8082                	ret

0000000080003d2c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d2c:	7139                	addi	sp,sp,-64
    80003d2e:	fc06                	sd	ra,56(sp)
    80003d30:	f822                	sd	s0,48(sp)
    80003d32:	f426                	sd	s1,40(sp)
    80003d34:	f04a                	sd	s2,32(sp)
    80003d36:	ec4e                	sd	s3,24(sp)
    80003d38:	e852                	sd	s4,16(sp)
    80003d3a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d3c:	04451703          	lh	a4,68(a0)
    80003d40:	4785                	li	a5,1
    80003d42:	00f71a63          	bne	a4,a5,80003d56 <dirlookup+0x2a>
    80003d46:	892a                	mv	s2,a0
    80003d48:	89ae                	mv	s3,a1
    80003d4a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4c:	457c                	lw	a5,76(a0)
    80003d4e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d50:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d52:	e79d                	bnez	a5,80003d80 <dirlookup+0x54>
    80003d54:	a8a5                	j	80003dcc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d56:	00005517          	auipc	a0,0x5
    80003d5a:	8ea50513          	addi	a0,a0,-1814 # 80008640 <syscalls+0x1a0>
    80003d5e:	ffffc097          	auipc	ra,0xffffc
    80003d62:	7f8080e7          	jalr	2040(ra) # 80000556 <panic>
      panic("dirlookup read");
    80003d66:	00005517          	auipc	a0,0x5
    80003d6a:	8f250513          	addi	a0,a0,-1806 # 80008658 <syscalls+0x1b8>
    80003d6e:	ffffc097          	auipc	ra,0xffffc
    80003d72:	7e8080e7          	jalr	2024(ra) # 80000556 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d76:	24c1                	addiw	s1,s1,16
    80003d78:	04c92783          	lw	a5,76(s2)
    80003d7c:	04f4f763          	bgeu	s1,a5,80003dca <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d80:	4741                	li	a4,16
    80003d82:	86a6                	mv	a3,s1
    80003d84:	fc040613          	addi	a2,s0,-64
    80003d88:	4581                	li	a1,0
    80003d8a:	854a                	mv	a0,s2
    80003d8c:	00000097          	auipc	ra,0x0
    80003d90:	d76080e7          	jalr	-650(ra) # 80003b02 <readi>
    80003d94:	47c1                	li	a5,16
    80003d96:	fcf518e3          	bne	a0,a5,80003d66 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d9a:	fc045783          	lhu	a5,-64(s0)
    80003d9e:	dfe1                	beqz	a5,80003d76 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003da0:	fc240593          	addi	a1,s0,-62
    80003da4:	854e                	mv	a0,s3
    80003da6:	00000097          	auipc	ra,0x0
    80003daa:	f6c080e7          	jalr	-148(ra) # 80003d12 <namecmp>
    80003dae:	f561                	bnez	a0,80003d76 <dirlookup+0x4a>
      if(poff)
    80003db0:	000a0463          	beqz	s4,80003db8 <dirlookup+0x8c>
        *poff = off;
    80003db4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003db8:	fc045583          	lhu	a1,-64(s0)
    80003dbc:	00092503          	lw	a0,0(s2)
    80003dc0:	fffff097          	auipc	ra,0xfffff
    80003dc4:	75a080e7          	jalr	1882(ra) # 8000351a <iget>
    80003dc8:	a011                	j	80003dcc <dirlookup+0xa0>
  return 0;
    80003dca:	4501                	li	a0,0
}
    80003dcc:	70e2                	ld	ra,56(sp)
    80003dce:	7442                	ld	s0,48(sp)
    80003dd0:	74a2                	ld	s1,40(sp)
    80003dd2:	7902                	ld	s2,32(sp)
    80003dd4:	69e2                	ld	s3,24(sp)
    80003dd6:	6a42                	ld	s4,16(sp)
    80003dd8:	6121                	addi	sp,sp,64
    80003dda:	8082                	ret

0000000080003ddc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ddc:	711d                	addi	sp,sp,-96
    80003dde:	ec86                	sd	ra,88(sp)
    80003de0:	e8a2                	sd	s0,80(sp)
    80003de2:	e4a6                	sd	s1,72(sp)
    80003de4:	e0ca                	sd	s2,64(sp)
    80003de6:	fc4e                	sd	s3,56(sp)
    80003de8:	f852                	sd	s4,48(sp)
    80003dea:	f456                	sd	s5,40(sp)
    80003dec:	f05a                	sd	s6,32(sp)
    80003dee:	ec5e                	sd	s7,24(sp)
    80003df0:	e862                	sd	s8,16(sp)
    80003df2:	e466                	sd	s9,8(sp)
    80003df4:	1080                	addi	s0,sp,96
    80003df6:	84aa                	mv	s1,a0
    80003df8:	8b2e                	mv	s6,a1
    80003dfa:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dfc:	00054703          	lbu	a4,0(a0)
    80003e00:	02f00793          	li	a5,47
    80003e04:	02f70363          	beq	a4,a5,80003e2a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e08:	ffffe097          	auipc	ra,0xffffe
    80003e0c:	cfe080e7          	jalr	-770(ra) # 80001b06 <myproc>
    80003e10:	15053503          	ld	a0,336(a0)
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	9fc080e7          	jalr	-1540(ra) # 80003810 <idup>
    80003e1c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e1e:	02f00913          	li	s2,47
  len = path - s;
    80003e22:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e24:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e26:	4c05                	li	s8,1
    80003e28:	a865                	j	80003ee0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e2a:	4585                	li	a1,1
    80003e2c:	4505                	li	a0,1
    80003e2e:	fffff097          	auipc	ra,0xfffff
    80003e32:	6ec080e7          	jalr	1772(ra) # 8000351a <iget>
    80003e36:	89aa                	mv	s3,a0
    80003e38:	b7dd                	j	80003e1e <namex+0x42>
      iunlockput(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	c74080e7          	jalr	-908(ra) # 80003ab0 <iunlockput>
      return 0;
    80003e44:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e46:	854e                	mv	a0,s3
    80003e48:	60e6                	ld	ra,88(sp)
    80003e4a:	6446                	ld	s0,80(sp)
    80003e4c:	64a6                	ld	s1,72(sp)
    80003e4e:	6906                	ld	s2,64(sp)
    80003e50:	79e2                	ld	s3,56(sp)
    80003e52:	7a42                	ld	s4,48(sp)
    80003e54:	7aa2                	ld	s5,40(sp)
    80003e56:	7b02                	ld	s6,32(sp)
    80003e58:	6be2                	ld	s7,24(sp)
    80003e5a:	6c42                	ld	s8,16(sp)
    80003e5c:	6ca2                	ld	s9,8(sp)
    80003e5e:	6125                	addi	sp,sp,96
    80003e60:	8082                	ret
      iunlock(ip);
    80003e62:	854e                	mv	a0,s3
    80003e64:	00000097          	auipc	ra,0x0
    80003e68:	aac080e7          	jalr	-1364(ra) # 80003910 <iunlock>
      return ip;
    80003e6c:	bfe9                	j	80003e46 <namex+0x6a>
      iunlockput(ip);
    80003e6e:	854e                	mv	a0,s3
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	c40080e7          	jalr	-960(ra) # 80003ab0 <iunlockput>
      return 0;
    80003e78:	89d2                	mv	s3,s4
    80003e7a:	b7f1                	j	80003e46 <namex+0x6a>
  len = path - s;
    80003e7c:	40b48633          	sub	a2,s1,a1
    80003e80:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e84:	094cd463          	bge	s9,s4,80003f0c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e88:	4639                	li	a2,14
    80003e8a:	8556                	mv	a0,s5
    80003e8c:	ffffd097          	auipc	ra,0xffffd
    80003e90:	eee080e7          	jalr	-274(ra) # 80000d7a <memmove>
  while(*path == '/')
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	01279763          	bne	a5,s2,80003ea6 <namex+0xca>
    path++;
    80003e9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e9e:	0004c783          	lbu	a5,0(s1)
    80003ea2:	ff278de3          	beq	a5,s2,80003e9c <namex+0xc0>
    ilock(ip);
    80003ea6:	854e                	mv	a0,s3
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	9a6080e7          	jalr	-1626(ra) # 8000384e <ilock>
    if(ip->type != T_DIR){
    80003eb0:	04499783          	lh	a5,68(s3)
    80003eb4:	f98793e3          	bne	a5,s8,80003e3a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003eb8:	000b0563          	beqz	s6,80003ec2 <namex+0xe6>
    80003ebc:	0004c783          	lbu	a5,0(s1)
    80003ec0:	d3cd                	beqz	a5,80003e62 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ec2:	865e                	mv	a2,s7
    80003ec4:	85d6                	mv	a1,s5
    80003ec6:	854e                	mv	a0,s3
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	e64080e7          	jalr	-412(ra) # 80003d2c <dirlookup>
    80003ed0:	8a2a                	mv	s4,a0
    80003ed2:	dd51                	beqz	a0,80003e6e <namex+0x92>
    iunlockput(ip);
    80003ed4:	854e                	mv	a0,s3
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	bda080e7          	jalr	-1062(ra) # 80003ab0 <iunlockput>
    ip = next;
    80003ede:	89d2                	mv	s3,s4
  while(*path == '/')
    80003ee0:	0004c783          	lbu	a5,0(s1)
    80003ee4:	05279763          	bne	a5,s2,80003f32 <namex+0x156>
    path++;
    80003ee8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eea:	0004c783          	lbu	a5,0(s1)
    80003eee:	ff278de3          	beq	a5,s2,80003ee8 <namex+0x10c>
  if(*path == 0)
    80003ef2:	c79d                	beqz	a5,80003f20 <namex+0x144>
    path++;
    80003ef4:	85a6                	mv	a1,s1
  len = path - s;
    80003ef6:	8a5e                	mv	s4,s7
    80003ef8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003efa:	01278963          	beq	a5,s2,80003f0c <namex+0x130>
    80003efe:	dfbd                	beqz	a5,80003e7c <namex+0xa0>
    path++;
    80003f00:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f02:	0004c783          	lbu	a5,0(s1)
    80003f06:	ff279ce3          	bne	a5,s2,80003efe <namex+0x122>
    80003f0a:	bf8d                	j	80003e7c <namex+0xa0>
    memmove(name, s, len);
    80003f0c:	2601                	sext.w	a2,a2
    80003f0e:	8556                	mv	a0,s5
    80003f10:	ffffd097          	auipc	ra,0xffffd
    80003f14:	e6a080e7          	jalr	-406(ra) # 80000d7a <memmove>
    name[len] = 0;
    80003f18:	9a56                	add	s4,s4,s5
    80003f1a:	000a0023          	sb	zero,0(s4)
    80003f1e:	bf9d                	j	80003e94 <namex+0xb8>
  if(nameiparent){
    80003f20:	f20b03e3          	beqz	s6,80003e46 <namex+0x6a>
    iput(ip);
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	ae2080e7          	jalr	-1310(ra) # 80003a08 <iput>
    return 0;
    80003f2e:	4981                	li	s3,0
    80003f30:	bf19                	j	80003e46 <namex+0x6a>
  if(*path == 0)
    80003f32:	d7fd                	beqz	a5,80003f20 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	85a6                	mv	a1,s1
    80003f3a:	b7d1                	j	80003efe <namex+0x122>

0000000080003f3c <dirlink>:
{
    80003f3c:	7139                	addi	sp,sp,-64
    80003f3e:	fc06                	sd	ra,56(sp)
    80003f40:	f822                	sd	s0,48(sp)
    80003f42:	f426                	sd	s1,40(sp)
    80003f44:	f04a                	sd	s2,32(sp)
    80003f46:	ec4e                	sd	s3,24(sp)
    80003f48:	e852                	sd	s4,16(sp)
    80003f4a:	0080                	addi	s0,sp,64
    80003f4c:	892a                	mv	s2,a0
    80003f4e:	8a2e                	mv	s4,a1
    80003f50:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f52:	4601                	li	a2,0
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	dd8080e7          	jalr	-552(ra) # 80003d2c <dirlookup>
    80003f5c:	e93d                	bnez	a0,80003fd2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5e:	04c92483          	lw	s1,76(s2)
    80003f62:	c49d                	beqz	s1,80003f90 <dirlink+0x54>
    80003f64:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f66:	4741                	li	a4,16
    80003f68:	86a6                	mv	a3,s1
    80003f6a:	fc040613          	addi	a2,s0,-64
    80003f6e:	4581                	li	a1,0
    80003f70:	854a                	mv	a0,s2
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	b90080e7          	jalr	-1136(ra) # 80003b02 <readi>
    80003f7a:	47c1                	li	a5,16
    80003f7c:	06f51163          	bne	a0,a5,80003fde <dirlink+0xa2>
    if(de.inum == 0)
    80003f80:	fc045783          	lhu	a5,-64(s0)
    80003f84:	c791                	beqz	a5,80003f90 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f86:	24c1                	addiw	s1,s1,16
    80003f88:	04c92783          	lw	a5,76(s2)
    80003f8c:	fcf4ede3          	bltu	s1,a5,80003f66 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f90:	4639                	li	a2,14
    80003f92:	85d2                	mv	a1,s4
    80003f94:	fc240513          	addi	a0,s0,-62
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	e9a080e7          	jalr	-358(ra) # 80000e32 <strncpy>
  de.inum = inum;
    80003fa0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa4:	4741                	li	a4,16
    80003fa6:	86a6                	mv	a3,s1
    80003fa8:	fc040613          	addi	a2,s0,-64
    80003fac:	4581                	li	a1,0
    80003fae:	854a                	mv	a0,s2
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	c48080e7          	jalr	-952(ra) # 80003bf8 <writei>
    80003fb8:	872a                	mv	a4,a0
    80003fba:	47c1                	li	a5,16
  return 0;
    80003fbc:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fbe:	02f71863          	bne	a4,a5,80003fee <dirlink+0xb2>
}
    80003fc2:	70e2                	ld	ra,56(sp)
    80003fc4:	7442                	ld	s0,48(sp)
    80003fc6:	74a2                	ld	s1,40(sp)
    80003fc8:	7902                	ld	s2,32(sp)
    80003fca:	69e2                	ld	s3,24(sp)
    80003fcc:	6a42                	ld	s4,16(sp)
    80003fce:	6121                	addi	sp,sp,64
    80003fd0:	8082                	ret
    iput(ip);
    80003fd2:	00000097          	auipc	ra,0x0
    80003fd6:	a36080e7          	jalr	-1482(ra) # 80003a08 <iput>
    return -1;
    80003fda:	557d                	li	a0,-1
    80003fdc:	b7dd                	j	80003fc2 <dirlink+0x86>
      panic("dirlink read");
    80003fde:	00004517          	auipc	a0,0x4
    80003fe2:	68a50513          	addi	a0,a0,1674 # 80008668 <syscalls+0x1c8>
    80003fe6:	ffffc097          	auipc	ra,0xffffc
    80003fea:	570080e7          	jalr	1392(ra) # 80000556 <panic>
    panic("dirlink");
    80003fee:	00004517          	auipc	a0,0x4
    80003ff2:	79250513          	addi	a0,a0,1938 # 80008780 <syscalls+0x2e0>
    80003ff6:	ffffc097          	auipc	ra,0xffffc
    80003ffa:	560080e7          	jalr	1376(ra) # 80000556 <panic>

0000000080003ffe <namei>:

struct inode*
namei(char *path)
{
    80003ffe:	1101                	addi	sp,sp,-32
    80004000:	ec06                	sd	ra,24(sp)
    80004002:	e822                	sd	s0,16(sp)
    80004004:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004006:	fe040613          	addi	a2,s0,-32
    8000400a:	4581                	li	a1,0
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	dd0080e7          	jalr	-560(ra) # 80003ddc <namex>
}
    80004014:	60e2                	ld	ra,24(sp)
    80004016:	6442                	ld	s0,16(sp)
    80004018:	6105                	addi	sp,sp,32
    8000401a:	8082                	ret

000000008000401c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000401c:	1141                	addi	sp,sp,-16
    8000401e:	e406                	sd	ra,8(sp)
    80004020:	e022                	sd	s0,0(sp)
    80004022:	0800                	addi	s0,sp,16
    80004024:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004026:	4585                	li	a1,1
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	db4080e7          	jalr	-588(ra) # 80003ddc <namex>
}
    80004030:	60a2                	ld	ra,8(sp)
    80004032:	6402                	ld	s0,0(sp)
    80004034:	0141                	addi	sp,sp,16
    80004036:	8082                	ret

0000000080004038 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004038:	1101                	addi	sp,sp,-32
    8000403a:	ec06                	sd	ra,24(sp)
    8000403c:	e822                	sd	s0,16(sp)
    8000403e:	e426                	sd	s1,8(sp)
    80004040:	e04a                	sd	s2,0(sp)
    80004042:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004044:	0001e917          	auipc	s2,0x1e
    80004048:	ac490913          	addi	s2,s2,-1340 # 80021b08 <log>
    8000404c:	01892583          	lw	a1,24(s2)
    80004050:	02892503          	lw	a0,40(s2)
    80004054:	fffff097          	auipc	ra,0xfffff
    80004058:	ff8080e7          	jalr	-8(ra) # 8000304c <bread>
    8000405c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000405e:	02c92683          	lw	a3,44(s2)
    80004062:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004064:	02d05763          	blez	a3,80004092 <write_head+0x5a>
    80004068:	0001e797          	auipc	a5,0x1e
    8000406c:	ad078793          	addi	a5,a5,-1328 # 80021b38 <log+0x30>
    80004070:	05c50713          	addi	a4,a0,92
    80004074:	36fd                	addiw	a3,a3,-1
    80004076:	1682                	slli	a3,a3,0x20
    80004078:	9281                	srli	a3,a3,0x20
    8000407a:	068a                	slli	a3,a3,0x2
    8000407c:	0001e617          	auipc	a2,0x1e
    80004080:	ac060613          	addi	a2,a2,-1344 # 80021b3c <log+0x34>
    80004084:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004086:	4390                	lw	a2,0(a5)
    80004088:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000408a:	0791                	addi	a5,a5,4
    8000408c:	0711                	addi	a4,a4,4
    8000408e:	fed79ce3          	bne	a5,a3,80004086 <write_head+0x4e>
  }
  bwrite(buf);
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	0aa080e7          	jalr	170(ra) # 8000313e <bwrite>
  brelse(buf);
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	0de080e7          	jalr	222(ra) # 8000317c <brelse>
}
    800040a6:	60e2                	ld	ra,24(sp)
    800040a8:	6442                	ld	s0,16(sp)
    800040aa:	64a2                	ld	s1,8(sp)
    800040ac:	6902                	ld	s2,0(sp)
    800040ae:	6105                	addi	sp,sp,32
    800040b0:	8082                	ret

00000000800040b2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b2:	0001e797          	auipc	a5,0x1e
    800040b6:	a827a783          	lw	a5,-1406(a5) # 80021b34 <log+0x2c>
    800040ba:	0af05663          	blez	a5,80004166 <install_trans+0xb4>
{
    800040be:	7139                	addi	sp,sp,-64
    800040c0:	fc06                	sd	ra,56(sp)
    800040c2:	f822                	sd	s0,48(sp)
    800040c4:	f426                	sd	s1,40(sp)
    800040c6:	f04a                	sd	s2,32(sp)
    800040c8:	ec4e                	sd	s3,24(sp)
    800040ca:	e852                	sd	s4,16(sp)
    800040cc:	e456                	sd	s5,8(sp)
    800040ce:	0080                	addi	s0,sp,64
    800040d0:	0001ea97          	auipc	s5,0x1e
    800040d4:	a68a8a93          	addi	s5,s5,-1432 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040d8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040da:	0001e997          	auipc	s3,0x1e
    800040de:	a2e98993          	addi	s3,s3,-1490 # 80021b08 <log>
    800040e2:	0189a583          	lw	a1,24(s3)
    800040e6:	014585bb          	addw	a1,a1,s4
    800040ea:	2585                	addiw	a1,a1,1
    800040ec:	0289a503          	lw	a0,40(s3)
    800040f0:	fffff097          	auipc	ra,0xfffff
    800040f4:	f5c080e7          	jalr	-164(ra) # 8000304c <bread>
    800040f8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040fa:	000aa583          	lw	a1,0(s5)
    800040fe:	0289a503          	lw	a0,40(s3)
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	f4a080e7          	jalr	-182(ra) # 8000304c <bread>
    8000410a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000410c:	40000613          	li	a2,1024
    80004110:	05890593          	addi	a1,s2,88
    80004114:	05850513          	addi	a0,a0,88
    80004118:	ffffd097          	auipc	ra,0xffffd
    8000411c:	c62080e7          	jalr	-926(ra) # 80000d7a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	01c080e7          	jalr	28(ra) # 8000313e <bwrite>
    bunpin(dbuf);
    8000412a:	8526                	mv	a0,s1
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	12a080e7          	jalr	298(ra) # 80003256 <bunpin>
    brelse(lbuf);
    80004134:	854a                	mv	a0,s2
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	046080e7          	jalr	70(ra) # 8000317c <brelse>
    brelse(dbuf);
    8000413e:	8526                	mv	a0,s1
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	03c080e7          	jalr	60(ra) # 8000317c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004148:	2a05                	addiw	s4,s4,1
    8000414a:	0a91                	addi	s5,s5,4
    8000414c:	02c9a783          	lw	a5,44(s3)
    80004150:	f8fa49e3          	blt	s4,a5,800040e2 <install_trans+0x30>
}
    80004154:	70e2                	ld	ra,56(sp)
    80004156:	7442                	ld	s0,48(sp)
    80004158:	74a2                	ld	s1,40(sp)
    8000415a:	7902                	ld	s2,32(sp)
    8000415c:	69e2                	ld	s3,24(sp)
    8000415e:	6a42                	ld	s4,16(sp)
    80004160:	6aa2                	ld	s5,8(sp)
    80004162:	6121                	addi	sp,sp,64
    80004164:	8082                	ret
    80004166:	8082                	ret

0000000080004168 <initlog>:
{
    80004168:	7179                	addi	sp,sp,-48
    8000416a:	f406                	sd	ra,40(sp)
    8000416c:	f022                	sd	s0,32(sp)
    8000416e:	ec26                	sd	s1,24(sp)
    80004170:	e84a                	sd	s2,16(sp)
    80004172:	e44e                	sd	s3,8(sp)
    80004174:	1800                	addi	s0,sp,48
    80004176:	892a                	mv	s2,a0
    80004178:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000417a:	0001e497          	auipc	s1,0x1e
    8000417e:	98e48493          	addi	s1,s1,-1650 # 80021b08 <log>
    80004182:	00004597          	auipc	a1,0x4
    80004186:	4f658593          	addi	a1,a1,1270 # 80008678 <syscalls+0x1d8>
    8000418a:	8526                	mv	a0,s1
    8000418c:	ffffd097          	auipc	ra,0xffffd
    80004190:	a02080e7          	jalr	-1534(ra) # 80000b8e <initlock>
  log.start = sb->logstart;
    80004194:	0149a583          	lw	a1,20(s3)
    80004198:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000419a:	0109a783          	lw	a5,16(s3)
    8000419e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041a0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041a4:	854a                	mv	a0,s2
    800041a6:	fffff097          	auipc	ra,0xfffff
    800041aa:	ea6080e7          	jalr	-346(ra) # 8000304c <bread>
  log.lh.n = lh->n;
    800041ae:	4d3c                	lw	a5,88(a0)
    800041b0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041b2:	02f05563          	blez	a5,800041dc <initlog+0x74>
    800041b6:	05c50713          	addi	a4,a0,92
    800041ba:	0001e697          	auipc	a3,0x1e
    800041be:	97e68693          	addi	a3,a3,-1666 # 80021b38 <log+0x30>
    800041c2:	37fd                	addiw	a5,a5,-1
    800041c4:	1782                	slli	a5,a5,0x20
    800041c6:	9381                	srli	a5,a5,0x20
    800041c8:	078a                	slli	a5,a5,0x2
    800041ca:	06050613          	addi	a2,a0,96
    800041ce:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041d0:	4310                	lw	a2,0(a4)
    800041d2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041d4:	0711                	addi	a4,a4,4
    800041d6:	0691                	addi	a3,a3,4
    800041d8:	fef71ce3          	bne	a4,a5,800041d0 <initlog+0x68>
  brelse(buf);
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	fa0080e7          	jalr	-96(ra) # 8000317c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041e4:	00000097          	auipc	ra,0x0
    800041e8:	ece080e7          	jalr	-306(ra) # 800040b2 <install_trans>
  log.lh.n = 0;
    800041ec:	0001e797          	auipc	a5,0x1e
    800041f0:	9407a423          	sw	zero,-1720(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800041f4:	00000097          	auipc	ra,0x0
    800041f8:	e44080e7          	jalr	-444(ra) # 80004038 <write_head>
}
    800041fc:	70a2                	ld	ra,40(sp)
    800041fe:	7402                	ld	s0,32(sp)
    80004200:	64e2                	ld	s1,24(sp)
    80004202:	6942                	ld	s2,16(sp)
    80004204:	69a2                	ld	s3,8(sp)
    80004206:	6145                	addi	sp,sp,48
    80004208:	8082                	ret

000000008000420a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000420a:	1101                	addi	sp,sp,-32
    8000420c:	ec06                	sd	ra,24(sp)
    8000420e:	e822                	sd	s0,16(sp)
    80004210:	e426                	sd	s1,8(sp)
    80004212:	e04a                	sd	s2,0(sp)
    80004214:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004216:	0001e517          	auipc	a0,0x1e
    8000421a:	8f250513          	addi	a0,a0,-1806 # 80021b08 <log>
    8000421e:	ffffd097          	auipc	ra,0xffffd
    80004222:	a00080e7          	jalr	-1536(ra) # 80000c1e <acquire>
  while(1){
    if(log.committing){
    80004226:	0001e497          	auipc	s1,0x1e
    8000422a:	8e248493          	addi	s1,s1,-1822 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000422e:	4979                	li	s2,30
    80004230:	a039                	j	8000423e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004232:	85a6                	mv	a1,s1
    80004234:	8526                	mv	a0,s1
    80004236:	ffffe097          	auipc	ra,0xffffe
    8000423a:	1f8080e7          	jalr	504(ra) # 8000242e <sleep>
    if(log.committing){
    8000423e:	50dc                	lw	a5,36(s1)
    80004240:	fbed                	bnez	a5,80004232 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004242:	509c                	lw	a5,32(s1)
    80004244:	0017871b          	addiw	a4,a5,1
    80004248:	0007069b          	sext.w	a3,a4
    8000424c:	0027179b          	slliw	a5,a4,0x2
    80004250:	9fb9                	addw	a5,a5,a4
    80004252:	0017979b          	slliw	a5,a5,0x1
    80004256:	54d8                	lw	a4,44(s1)
    80004258:	9fb9                	addw	a5,a5,a4
    8000425a:	00f95963          	bge	s2,a5,8000426c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000425e:	85a6                	mv	a1,s1
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	1cc080e7          	jalr	460(ra) # 8000242e <sleep>
    8000426a:	bfd1                	j	8000423e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000426c:	0001e517          	auipc	a0,0x1e
    80004270:	89c50513          	addi	a0,a0,-1892 # 80021b08 <log>
    80004274:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004276:	ffffd097          	auipc	ra,0xffffd
    8000427a:	a5c080e7          	jalr	-1444(ra) # 80000cd2 <release>
      break;
    }
  }
}
    8000427e:	60e2                	ld	ra,24(sp)
    80004280:	6442                	ld	s0,16(sp)
    80004282:	64a2                	ld	s1,8(sp)
    80004284:	6902                	ld	s2,0(sp)
    80004286:	6105                	addi	sp,sp,32
    80004288:	8082                	ret

000000008000428a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000428a:	7139                	addi	sp,sp,-64
    8000428c:	fc06                	sd	ra,56(sp)
    8000428e:	f822                	sd	s0,48(sp)
    80004290:	f426                	sd	s1,40(sp)
    80004292:	f04a                	sd	s2,32(sp)
    80004294:	ec4e                	sd	s3,24(sp)
    80004296:	e852                	sd	s4,16(sp)
    80004298:	e456                	sd	s5,8(sp)
    8000429a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000429c:	0001e497          	auipc	s1,0x1e
    800042a0:	86c48493          	addi	s1,s1,-1940 # 80021b08 <log>
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	978080e7          	jalr	-1672(ra) # 80000c1e <acquire>
  log.outstanding -= 1;
    800042ae:	509c                	lw	a5,32(s1)
    800042b0:	37fd                	addiw	a5,a5,-1
    800042b2:	0007891b          	sext.w	s2,a5
    800042b6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042b8:	50dc                	lw	a5,36(s1)
    800042ba:	efb9                	bnez	a5,80004318 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042bc:	06091663          	bnez	s2,80004328 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800042c0:	0001e497          	auipc	s1,0x1e
    800042c4:	84848493          	addi	s1,s1,-1976 # 80021b08 <log>
    800042c8:	4785                	li	a5,1
    800042ca:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042cc:	8526                	mv	a0,s1
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	a04080e7          	jalr	-1532(ra) # 80000cd2 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042d6:	54dc                	lw	a5,44(s1)
    800042d8:	06f04763          	bgtz	a5,80004346 <end_op+0xbc>
    acquire(&log.lock);
    800042dc:	0001e497          	auipc	s1,0x1e
    800042e0:	82c48493          	addi	s1,s1,-2004 # 80021b08 <log>
    800042e4:	8526                	mv	a0,s1
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	938080e7          	jalr	-1736(ra) # 80000c1e <acquire>
    log.committing = 0;
    800042ee:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042f2:	8526                	mv	a0,s1
    800042f4:	ffffe097          	auipc	ra,0xffffe
    800042f8:	2c0080e7          	jalr	704(ra) # 800025b4 <wakeup>
    release(&log.lock);
    800042fc:	8526                	mv	a0,s1
    800042fe:	ffffd097          	auipc	ra,0xffffd
    80004302:	9d4080e7          	jalr	-1580(ra) # 80000cd2 <release>
}
    80004306:	70e2                	ld	ra,56(sp)
    80004308:	7442                	ld	s0,48(sp)
    8000430a:	74a2                	ld	s1,40(sp)
    8000430c:	7902                	ld	s2,32(sp)
    8000430e:	69e2                	ld	s3,24(sp)
    80004310:	6a42                	ld	s4,16(sp)
    80004312:	6aa2                	ld	s5,8(sp)
    80004314:	6121                	addi	sp,sp,64
    80004316:	8082                	ret
    panic("log.committing");
    80004318:	00004517          	auipc	a0,0x4
    8000431c:	36850513          	addi	a0,a0,872 # 80008680 <syscalls+0x1e0>
    80004320:	ffffc097          	auipc	ra,0xffffc
    80004324:	236080e7          	jalr	566(ra) # 80000556 <panic>
    wakeup(&log);
    80004328:	0001d497          	auipc	s1,0x1d
    8000432c:	7e048493          	addi	s1,s1,2016 # 80021b08 <log>
    80004330:	8526                	mv	a0,s1
    80004332:	ffffe097          	auipc	ra,0xffffe
    80004336:	282080e7          	jalr	642(ra) # 800025b4 <wakeup>
  release(&log.lock);
    8000433a:	8526                	mv	a0,s1
    8000433c:	ffffd097          	auipc	ra,0xffffd
    80004340:	996080e7          	jalr	-1642(ra) # 80000cd2 <release>
  if(do_commit){
    80004344:	b7c9                	j	80004306 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004346:	0001da97          	auipc	s5,0x1d
    8000434a:	7f2a8a93          	addi	s5,s5,2034 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000434e:	0001da17          	auipc	s4,0x1d
    80004352:	7baa0a13          	addi	s4,s4,1978 # 80021b08 <log>
    80004356:	018a2583          	lw	a1,24(s4)
    8000435a:	012585bb          	addw	a1,a1,s2
    8000435e:	2585                	addiw	a1,a1,1
    80004360:	028a2503          	lw	a0,40(s4)
    80004364:	fffff097          	auipc	ra,0xfffff
    80004368:	ce8080e7          	jalr	-792(ra) # 8000304c <bread>
    8000436c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000436e:	000aa583          	lw	a1,0(s5)
    80004372:	028a2503          	lw	a0,40(s4)
    80004376:	fffff097          	auipc	ra,0xfffff
    8000437a:	cd6080e7          	jalr	-810(ra) # 8000304c <bread>
    8000437e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004380:	40000613          	li	a2,1024
    80004384:	05850593          	addi	a1,a0,88
    80004388:	05848513          	addi	a0,s1,88
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	9ee080e7          	jalr	-1554(ra) # 80000d7a <memmove>
    bwrite(to);  // write the log
    80004394:	8526                	mv	a0,s1
    80004396:	fffff097          	auipc	ra,0xfffff
    8000439a:	da8080e7          	jalr	-600(ra) # 8000313e <bwrite>
    brelse(from);
    8000439e:	854e                	mv	a0,s3
    800043a0:	fffff097          	auipc	ra,0xfffff
    800043a4:	ddc080e7          	jalr	-548(ra) # 8000317c <brelse>
    brelse(to);
    800043a8:	8526                	mv	a0,s1
    800043aa:	fffff097          	auipc	ra,0xfffff
    800043ae:	dd2080e7          	jalr	-558(ra) # 8000317c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043b2:	2905                	addiw	s2,s2,1
    800043b4:	0a91                	addi	s5,s5,4
    800043b6:	02ca2783          	lw	a5,44(s4)
    800043ba:	f8f94ee3          	blt	s2,a5,80004356 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043be:	00000097          	auipc	ra,0x0
    800043c2:	c7a080e7          	jalr	-902(ra) # 80004038 <write_head>
    install_trans(); // Now install writes to home locations
    800043c6:	00000097          	auipc	ra,0x0
    800043ca:	cec080e7          	jalr	-788(ra) # 800040b2 <install_trans>
    log.lh.n = 0;
    800043ce:	0001d797          	auipc	a5,0x1d
    800043d2:	7607a323          	sw	zero,1894(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	c62080e7          	jalr	-926(ra) # 80004038 <write_head>
    800043de:	bdfd                	j	800042dc <end_op+0x52>

00000000800043e0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043e0:	1101                	addi	sp,sp,-32
    800043e2:	ec06                	sd	ra,24(sp)
    800043e4:	e822                	sd	s0,16(sp)
    800043e6:	e426                	sd	s1,8(sp)
    800043e8:	e04a                	sd	s2,0(sp)
    800043ea:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043ec:	0001d717          	auipc	a4,0x1d
    800043f0:	74872703          	lw	a4,1864(a4) # 80021b34 <log+0x2c>
    800043f4:	47f5                	li	a5,29
    800043f6:	08e7c063          	blt	a5,a4,80004476 <log_write+0x96>
    800043fa:	84aa                	mv	s1,a0
    800043fc:	0001d797          	auipc	a5,0x1d
    80004400:	7287a783          	lw	a5,1832(a5) # 80021b24 <log+0x1c>
    80004404:	37fd                	addiw	a5,a5,-1
    80004406:	06f75863          	bge	a4,a5,80004476 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000440a:	0001d797          	auipc	a5,0x1d
    8000440e:	71e7a783          	lw	a5,1822(a5) # 80021b28 <log+0x20>
    80004412:	06f05a63          	blez	a5,80004486 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004416:	0001d917          	auipc	s2,0x1d
    8000441a:	6f290913          	addi	s2,s2,1778 # 80021b08 <log>
    8000441e:	854a                	mv	a0,s2
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	7fe080e7          	jalr	2046(ra) # 80000c1e <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004428:	02c92603          	lw	a2,44(s2)
    8000442c:	06c05563          	blez	a2,80004496 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004430:	44cc                	lw	a1,12(s1)
    80004432:	0001d717          	auipc	a4,0x1d
    80004436:	70670713          	addi	a4,a4,1798 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000443a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000443c:	4314                	lw	a3,0(a4)
    8000443e:	04b68d63          	beq	a3,a1,80004498 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004442:	2785                	addiw	a5,a5,1
    80004444:	0711                	addi	a4,a4,4
    80004446:	fec79be3          	bne	a5,a2,8000443c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000444a:	0621                	addi	a2,a2,8
    8000444c:	060a                	slli	a2,a2,0x2
    8000444e:	0001d797          	auipc	a5,0x1d
    80004452:	6ba78793          	addi	a5,a5,1722 # 80021b08 <log>
    80004456:	963e                	add	a2,a2,a5
    80004458:	44dc                	lw	a5,12(s1)
    8000445a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	dbc080e7          	jalr	-580(ra) # 8000321a <bpin>
    log.lh.n++;
    80004466:	0001d717          	auipc	a4,0x1d
    8000446a:	6a270713          	addi	a4,a4,1698 # 80021b08 <log>
    8000446e:	575c                	lw	a5,44(a4)
    80004470:	2785                	addiw	a5,a5,1
    80004472:	d75c                	sw	a5,44(a4)
    80004474:	a83d                	j	800044b2 <log_write+0xd2>
    panic("too big a transaction");
    80004476:	00004517          	auipc	a0,0x4
    8000447a:	21a50513          	addi	a0,a0,538 # 80008690 <syscalls+0x1f0>
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	0d8080e7          	jalr	216(ra) # 80000556 <panic>
    panic("log_write outside of trans");
    80004486:	00004517          	auipc	a0,0x4
    8000448a:	22250513          	addi	a0,a0,546 # 800086a8 <syscalls+0x208>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	0c8080e7          	jalr	200(ra) # 80000556 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004496:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004498:	00878713          	addi	a4,a5,8
    8000449c:	00271693          	slli	a3,a4,0x2
    800044a0:	0001d717          	auipc	a4,0x1d
    800044a4:	66870713          	addi	a4,a4,1640 # 80021b08 <log>
    800044a8:	9736                	add	a4,a4,a3
    800044aa:	44d4                	lw	a3,12(s1)
    800044ac:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044ae:	faf607e3          	beq	a2,a5,8000445c <log_write+0x7c>
  }
  release(&log.lock);
    800044b2:	0001d517          	auipc	a0,0x1d
    800044b6:	65650513          	addi	a0,a0,1622 # 80021b08 <log>
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	818080e7          	jalr	-2024(ra) # 80000cd2 <release>
}
    800044c2:	60e2                	ld	ra,24(sp)
    800044c4:	6442                	ld	s0,16(sp)
    800044c6:	64a2                	ld	s1,8(sp)
    800044c8:	6902                	ld	s2,0(sp)
    800044ca:	6105                	addi	sp,sp,32
    800044cc:	8082                	ret

00000000800044ce <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044ce:	1101                	addi	sp,sp,-32
    800044d0:	ec06                	sd	ra,24(sp)
    800044d2:	e822                	sd	s0,16(sp)
    800044d4:	e426                	sd	s1,8(sp)
    800044d6:	e04a                	sd	s2,0(sp)
    800044d8:	1000                	addi	s0,sp,32
    800044da:	84aa                	mv	s1,a0
    800044dc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044de:	00004597          	auipc	a1,0x4
    800044e2:	1ea58593          	addi	a1,a1,490 # 800086c8 <syscalls+0x228>
    800044e6:	0521                	addi	a0,a0,8
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	6a6080e7          	jalr	1702(ra) # 80000b8e <initlock>
  lk->name = name;
    800044f0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044f4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f8:	0204a423          	sw	zero,40(s1)
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	64a2                	ld	s1,8(sp)
    80004502:	6902                	ld	s2,0(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret

0000000080004508 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	e04a                	sd	s2,0(sp)
    80004512:	1000                	addi	s0,sp,32
    80004514:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004516:	00850913          	addi	s2,a0,8
    8000451a:	854a                	mv	a0,s2
    8000451c:	ffffc097          	auipc	ra,0xffffc
    80004520:	702080e7          	jalr	1794(ra) # 80000c1e <acquire>
  while (lk->locked) {
    80004524:	409c                	lw	a5,0(s1)
    80004526:	cb89                	beqz	a5,80004538 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004528:	85ca                	mv	a1,s2
    8000452a:	8526                	mv	a0,s1
    8000452c:	ffffe097          	auipc	ra,0xffffe
    80004530:	f02080e7          	jalr	-254(ra) # 8000242e <sleep>
  while (lk->locked) {
    80004534:	409c                	lw	a5,0(s1)
    80004536:	fbed                	bnez	a5,80004528 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004538:	4785                	li	a5,1
    8000453a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000453c:	ffffd097          	auipc	ra,0xffffd
    80004540:	5ca080e7          	jalr	1482(ra) # 80001b06 <myproc>
    80004544:	5d1c                	lw	a5,56(a0)
    80004546:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	788080e7          	jalr	1928(ra) # 80000cd2 <release>
}
    80004552:	60e2                	ld	ra,24(sp)
    80004554:	6442                	ld	s0,16(sp)
    80004556:	64a2                	ld	s1,8(sp)
    80004558:	6902                	ld	s2,0(sp)
    8000455a:	6105                	addi	sp,sp,32
    8000455c:	8082                	ret

000000008000455e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000455e:	1101                	addi	sp,sp,-32
    80004560:	ec06                	sd	ra,24(sp)
    80004562:	e822                	sd	s0,16(sp)
    80004564:	e426                	sd	s1,8(sp)
    80004566:	e04a                	sd	s2,0(sp)
    80004568:	1000                	addi	s0,sp,32
    8000456a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000456c:	00850913          	addi	s2,a0,8
    80004570:	854a                	mv	a0,s2
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	6ac080e7          	jalr	1708(ra) # 80000c1e <acquire>
  lk->locked = 0;
    8000457a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000457e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004582:	8526                	mv	a0,s1
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	030080e7          	jalr	48(ra) # 800025b4 <wakeup>
  release(&lk->lk);
    8000458c:	854a                	mv	a0,s2
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	744080e7          	jalr	1860(ra) # 80000cd2 <release>
}
    80004596:	60e2                	ld	ra,24(sp)
    80004598:	6442                	ld	s0,16(sp)
    8000459a:	64a2                	ld	s1,8(sp)
    8000459c:	6902                	ld	s2,0(sp)
    8000459e:	6105                	addi	sp,sp,32
    800045a0:	8082                	ret

00000000800045a2 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045a2:	7179                	addi	sp,sp,-48
    800045a4:	f406                	sd	ra,40(sp)
    800045a6:	f022                	sd	s0,32(sp)
    800045a8:	ec26                	sd	s1,24(sp)
    800045aa:	e84a                	sd	s2,16(sp)
    800045ac:	e44e                	sd	s3,8(sp)
    800045ae:	1800                	addi	s0,sp,48
    800045b0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045b2:	00850913          	addi	s2,a0,8
    800045b6:	854a                	mv	a0,s2
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	666080e7          	jalr	1638(ra) # 80000c1e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045c0:	409c                	lw	a5,0(s1)
    800045c2:	ef99                	bnez	a5,800045e0 <holdingsleep+0x3e>
    800045c4:	4481                	li	s1,0
  release(&lk->lk);
    800045c6:	854a                	mv	a0,s2
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	70a080e7          	jalr	1802(ra) # 80000cd2 <release>
  return r;
}
    800045d0:	8526                	mv	a0,s1
    800045d2:	70a2                	ld	ra,40(sp)
    800045d4:	7402                	ld	s0,32(sp)
    800045d6:	64e2                	ld	s1,24(sp)
    800045d8:	6942                	ld	s2,16(sp)
    800045da:	69a2                	ld	s3,8(sp)
    800045dc:	6145                	addi	sp,sp,48
    800045de:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045e0:	0284a983          	lw	s3,40(s1)
    800045e4:	ffffd097          	auipc	ra,0xffffd
    800045e8:	522080e7          	jalr	1314(ra) # 80001b06 <myproc>
    800045ec:	5d04                	lw	s1,56(a0)
    800045ee:	413484b3          	sub	s1,s1,s3
    800045f2:	0014b493          	seqz	s1,s1
    800045f6:	bfc1                	j	800045c6 <holdingsleep+0x24>

00000000800045f8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045f8:	1141                	addi	sp,sp,-16
    800045fa:	e406                	sd	ra,8(sp)
    800045fc:	e022                	sd	s0,0(sp)
    800045fe:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004600:	00004597          	auipc	a1,0x4
    80004604:	0d858593          	addi	a1,a1,216 # 800086d8 <syscalls+0x238>
    80004608:	0001d517          	auipc	a0,0x1d
    8000460c:	64850513          	addi	a0,a0,1608 # 80021c50 <ftable>
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	57e080e7          	jalr	1406(ra) # 80000b8e <initlock>
}
    80004618:	60a2                	ld	ra,8(sp)
    8000461a:	6402                	ld	s0,0(sp)
    8000461c:	0141                	addi	sp,sp,16
    8000461e:	8082                	ret

0000000080004620 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004620:	1101                	addi	sp,sp,-32
    80004622:	ec06                	sd	ra,24(sp)
    80004624:	e822                	sd	s0,16(sp)
    80004626:	e426                	sd	s1,8(sp)
    80004628:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000462a:	0001d517          	auipc	a0,0x1d
    8000462e:	62650513          	addi	a0,a0,1574 # 80021c50 <ftable>
    80004632:	ffffc097          	auipc	ra,0xffffc
    80004636:	5ec080e7          	jalr	1516(ra) # 80000c1e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463a:	0001d497          	auipc	s1,0x1d
    8000463e:	62e48493          	addi	s1,s1,1582 # 80021c68 <ftable+0x18>
    80004642:	0001e717          	auipc	a4,0x1e
    80004646:	5c670713          	addi	a4,a4,1478 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000464a:	40dc                	lw	a5,4(s1)
    8000464c:	cf99                	beqz	a5,8000466a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000464e:	02848493          	addi	s1,s1,40
    80004652:	fee49ce3          	bne	s1,a4,8000464a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004656:	0001d517          	auipc	a0,0x1d
    8000465a:	5fa50513          	addi	a0,a0,1530 # 80021c50 <ftable>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	674080e7          	jalr	1652(ra) # 80000cd2 <release>
  return 0;
    80004666:	4481                	li	s1,0
    80004668:	a819                	j	8000467e <filealloc+0x5e>
      f->ref = 1;
    8000466a:	4785                	li	a5,1
    8000466c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000466e:	0001d517          	auipc	a0,0x1d
    80004672:	5e250513          	addi	a0,a0,1506 # 80021c50 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	65c080e7          	jalr	1628(ra) # 80000cd2 <release>
}
    8000467e:	8526                	mv	a0,s1
    80004680:	60e2                	ld	ra,24(sp)
    80004682:	6442                	ld	s0,16(sp)
    80004684:	64a2                	ld	s1,8(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	1000                	addi	s0,sp,32
    80004694:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004696:	0001d517          	auipc	a0,0x1d
    8000469a:	5ba50513          	addi	a0,a0,1466 # 80021c50 <ftable>
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	580080e7          	jalr	1408(ra) # 80000c1e <acquire>
  if(f->ref < 1)
    800046a6:	40dc                	lw	a5,4(s1)
    800046a8:	02f05263          	blez	a5,800046cc <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046ac:	2785                	addiw	a5,a5,1
    800046ae:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046b0:	0001d517          	auipc	a0,0x1d
    800046b4:	5a050513          	addi	a0,a0,1440 # 80021c50 <ftable>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	61a080e7          	jalr	1562(ra) # 80000cd2 <release>
  return f;
}
    800046c0:	8526                	mv	a0,s1
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6105                	addi	sp,sp,32
    800046ca:	8082                	ret
    panic("filedup");
    800046cc:	00004517          	auipc	a0,0x4
    800046d0:	01450513          	addi	a0,a0,20 # 800086e0 <syscalls+0x240>
    800046d4:	ffffc097          	auipc	ra,0xffffc
    800046d8:	e82080e7          	jalr	-382(ra) # 80000556 <panic>

00000000800046dc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046dc:	7139                	addi	sp,sp,-64
    800046de:	fc06                	sd	ra,56(sp)
    800046e0:	f822                	sd	s0,48(sp)
    800046e2:	f426                	sd	s1,40(sp)
    800046e4:	f04a                	sd	s2,32(sp)
    800046e6:	ec4e                	sd	s3,24(sp)
    800046e8:	e852                	sd	s4,16(sp)
    800046ea:	e456                	sd	s5,8(sp)
    800046ec:	0080                	addi	s0,sp,64
    800046ee:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046f0:	0001d517          	auipc	a0,0x1d
    800046f4:	56050513          	addi	a0,a0,1376 # 80021c50 <ftable>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	526080e7          	jalr	1318(ra) # 80000c1e <acquire>
  if(f->ref < 1)
    80004700:	40dc                	lw	a5,4(s1)
    80004702:	06f05163          	blez	a5,80004764 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004706:	37fd                	addiw	a5,a5,-1
    80004708:	0007871b          	sext.w	a4,a5
    8000470c:	c0dc                	sw	a5,4(s1)
    8000470e:	06e04363          	bgtz	a4,80004774 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004712:	0004a903          	lw	s2,0(s1)
    80004716:	0094ca83          	lbu	s5,9(s1)
    8000471a:	0104ba03          	ld	s4,16(s1)
    8000471e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004722:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004726:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000472a:	0001d517          	auipc	a0,0x1d
    8000472e:	52650513          	addi	a0,a0,1318 # 80021c50 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	5a0080e7          	jalr	1440(ra) # 80000cd2 <release>

  if(ff.type == FD_PIPE){
    8000473a:	4785                	li	a5,1
    8000473c:	04f90d63          	beq	s2,a5,80004796 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004740:	3979                	addiw	s2,s2,-2
    80004742:	4785                	li	a5,1
    80004744:	0527e063          	bltu	a5,s2,80004784 <fileclose+0xa8>
    begin_op();
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	ac2080e7          	jalr	-1342(ra) # 8000420a <begin_op>
    iput(ff.ip);
    80004750:	854e                	mv	a0,s3
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	2b6080e7          	jalr	694(ra) # 80003a08 <iput>
    end_op();
    8000475a:	00000097          	auipc	ra,0x0
    8000475e:	b30080e7          	jalr	-1232(ra) # 8000428a <end_op>
    80004762:	a00d                	j	80004784 <fileclose+0xa8>
    panic("fileclose");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	f8450513          	addi	a0,a0,-124 # 800086e8 <syscalls+0x248>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dea080e7          	jalr	-534(ra) # 80000556 <panic>
    release(&ftable.lock);
    80004774:	0001d517          	auipc	a0,0x1d
    80004778:	4dc50513          	addi	a0,a0,1244 # 80021c50 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	556080e7          	jalr	1366(ra) # 80000cd2 <release>
  }
}
    80004784:	70e2                	ld	ra,56(sp)
    80004786:	7442                	ld	s0,48(sp)
    80004788:	74a2                	ld	s1,40(sp)
    8000478a:	7902                	ld	s2,32(sp)
    8000478c:	69e2                	ld	s3,24(sp)
    8000478e:	6a42                	ld	s4,16(sp)
    80004790:	6aa2                	ld	s5,8(sp)
    80004792:	6121                	addi	sp,sp,64
    80004794:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004796:	85d6                	mv	a1,s5
    80004798:	8552                	mv	a0,s4
    8000479a:	00000097          	auipc	ra,0x0
    8000479e:	372080e7          	jalr	882(ra) # 80004b0c <pipeclose>
    800047a2:	b7cd                	j	80004784 <fileclose+0xa8>

00000000800047a4 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047a4:	715d                	addi	sp,sp,-80
    800047a6:	e486                	sd	ra,72(sp)
    800047a8:	e0a2                	sd	s0,64(sp)
    800047aa:	fc26                	sd	s1,56(sp)
    800047ac:	f84a                	sd	s2,48(sp)
    800047ae:	f44e                	sd	s3,40(sp)
    800047b0:	0880                	addi	s0,sp,80
    800047b2:	84aa                	mv	s1,a0
    800047b4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047b6:	ffffd097          	auipc	ra,0xffffd
    800047ba:	350080e7          	jalr	848(ra) # 80001b06 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047be:	409c                	lw	a5,0(s1)
    800047c0:	37f9                	addiw	a5,a5,-2
    800047c2:	4705                	li	a4,1
    800047c4:	04f76763          	bltu	a4,a5,80004812 <filestat+0x6e>
    800047c8:	892a                	mv	s2,a0
    ilock(f->ip);
    800047ca:	6c88                	ld	a0,24(s1)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	082080e7          	jalr	130(ra) # 8000384e <ilock>
    stati(f->ip, &st);
    800047d4:	fb840593          	addi	a1,s0,-72
    800047d8:	6c88                	ld	a0,24(s1)
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	2fe080e7          	jalr	766(ra) # 80003ad8 <stati>
    iunlock(f->ip);
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	12c080e7          	jalr	300(ra) # 80003910 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047ec:	46e1                	li	a3,24
    800047ee:	fb840613          	addi	a2,s0,-72
    800047f2:	85ce                	mv	a1,s3
    800047f4:	05093503          	ld	a0,80(s2)
    800047f8:	ffffd097          	auipc	ra,0xffffd
    800047fc:	17a080e7          	jalr	378(ra) # 80001972 <copyout>
    80004800:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004804:	60a6                	ld	ra,72(sp)
    80004806:	6406                	ld	s0,64(sp)
    80004808:	74e2                	ld	s1,56(sp)
    8000480a:	7942                	ld	s2,48(sp)
    8000480c:	79a2                	ld	s3,40(sp)
    8000480e:	6161                	addi	sp,sp,80
    80004810:	8082                	ret
  return -1;
    80004812:	557d                	li	a0,-1
    80004814:	bfc5                	j	80004804 <filestat+0x60>

0000000080004816 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004816:	7179                	addi	sp,sp,-48
    80004818:	f406                	sd	ra,40(sp)
    8000481a:	f022                	sd	s0,32(sp)
    8000481c:	ec26                	sd	s1,24(sp)
    8000481e:	e84a                	sd	s2,16(sp)
    80004820:	e44e                	sd	s3,8(sp)
    80004822:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004824:	00854783          	lbu	a5,8(a0)
    80004828:	c3d5                	beqz	a5,800048cc <fileread+0xb6>
    8000482a:	84aa                	mv	s1,a0
    8000482c:	89ae                	mv	s3,a1
    8000482e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004830:	411c                	lw	a5,0(a0)
    80004832:	4705                	li	a4,1
    80004834:	04e78963          	beq	a5,a4,80004886 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004838:	470d                	li	a4,3
    8000483a:	04e78d63          	beq	a5,a4,80004894 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000483e:	4709                	li	a4,2
    80004840:	06e79e63          	bne	a5,a4,800048bc <fileread+0xa6>
    ilock(f->ip);
    80004844:	6d08                	ld	a0,24(a0)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	008080e7          	jalr	8(ra) # 8000384e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000484e:	874a                	mv	a4,s2
    80004850:	5094                	lw	a3,32(s1)
    80004852:	864e                	mv	a2,s3
    80004854:	4585                	li	a1,1
    80004856:	6c88                	ld	a0,24(s1)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	2aa080e7          	jalr	682(ra) # 80003b02 <readi>
    80004860:	892a                	mv	s2,a0
    80004862:	00a05563          	blez	a0,8000486c <fileread+0x56>
      f->off += r;
    80004866:	509c                	lw	a5,32(s1)
    80004868:	9fa9                	addw	a5,a5,a0
    8000486a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000486c:	6c88                	ld	a0,24(s1)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	0a2080e7          	jalr	162(ra) # 80003910 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004876:	854a                	mv	a0,s2
    80004878:	70a2                	ld	ra,40(sp)
    8000487a:	7402                	ld	s0,32(sp)
    8000487c:	64e2                	ld	s1,24(sp)
    8000487e:	6942                	ld	s2,16(sp)
    80004880:	69a2                	ld	s3,8(sp)
    80004882:	6145                	addi	sp,sp,48
    80004884:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004886:	6908                	ld	a0,16(a0)
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	418080e7          	jalr	1048(ra) # 80004ca0 <piperead>
    80004890:	892a                	mv	s2,a0
    80004892:	b7d5                	j	80004876 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004894:	02451783          	lh	a5,36(a0)
    80004898:	03079693          	slli	a3,a5,0x30
    8000489c:	92c1                	srli	a3,a3,0x30
    8000489e:	4725                	li	a4,9
    800048a0:	02d76863          	bltu	a4,a3,800048d0 <fileread+0xba>
    800048a4:	0792                	slli	a5,a5,0x4
    800048a6:	0001d717          	auipc	a4,0x1d
    800048aa:	30a70713          	addi	a4,a4,778 # 80021bb0 <devsw>
    800048ae:	97ba                	add	a5,a5,a4
    800048b0:	639c                	ld	a5,0(a5)
    800048b2:	c38d                	beqz	a5,800048d4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048b4:	4505                	li	a0,1
    800048b6:	9782                	jalr	a5
    800048b8:	892a                	mv	s2,a0
    800048ba:	bf75                	j	80004876 <fileread+0x60>
    panic("fileread");
    800048bc:	00004517          	auipc	a0,0x4
    800048c0:	e3c50513          	addi	a0,a0,-452 # 800086f8 <syscalls+0x258>
    800048c4:	ffffc097          	auipc	ra,0xffffc
    800048c8:	c92080e7          	jalr	-878(ra) # 80000556 <panic>
    return -1;
    800048cc:	597d                	li	s2,-1
    800048ce:	b765                	j	80004876 <fileread+0x60>
      return -1;
    800048d0:	597d                	li	s2,-1
    800048d2:	b755                	j	80004876 <fileread+0x60>
    800048d4:	597d                	li	s2,-1
    800048d6:	b745                	j	80004876 <fileread+0x60>

00000000800048d8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048d8:	00954783          	lbu	a5,9(a0)
    800048dc:	14078563          	beqz	a5,80004a26 <filewrite+0x14e>
{
    800048e0:	715d                	addi	sp,sp,-80
    800048e2:	e486                	sd	ra,72(sp)
    800048e4:	e0a2                	sd	s0,64(sp)
    800048e6:	fc26                	sd	s1,56(sp)
    800048e8:	f84a                	sd	s2,48(sp)
    800048ea:	f44e                	sd	s3,40(sp)
    800048ec:	f052                	sd	s4,32(sp)
    800048ee:	ec56                	sd	s5,24(sp)
    800048f0:	e85a                	sd	s6,16(sp)
    800048f2:	e45e                	sd	s7,8(sp)
    800048f4:	e062                	sd	s8,0(sp)
    800048f6:	0880                	addi	s0,sp,80
    800048f8:	892a                	mv	s2,a0
    800048fa:	8aae                	mv	s5,a1
    800048fc:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048fe:	411c                	lw	a5,0(a0)
    80004900:	4705                	li	a4,1
    80004902:	02e78263          	beq	a5,a4,80004926 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004906:	470d                	li	a4,3
    80004908:	02e78563          	beq	a5,a4,80004932 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000490c:	4709                	li	a4,2
    8000490e:	10e79463          	bne	a5,a4,80004a16 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004912:	0ec05e63          	blez	a2,80004a0e <filewrite+0x136>
    int i = 0;
    80004916:	4981                	li	s3,0
    80004918:	6b05                	lui	s6,0x1
    8000491a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000491e:	6b85                	lui	s7,0x1
    80004920:	c00b8b9b          	addiw	s7,s7,-1024
    80004924:	a851                	j	800049b8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004926:	6908                	ld	a0,16(a0)
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	254080e7          	jalr	596(ra) # 80004b7c <pipewrite>
    80004930:	a85d                	j	800049e6 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004932:	02451783          	lh	a5,36(a0)
    80004936:	03079693          	slli	a3,a5,0x30
    8000493a:	92c1                	srli	a3,a3,0x30
    8000493c:	4725                	li	a4,9
    8000493e:	0ed76663          	bltu	a4,a3,80004a2a <filewrite+0x152>
    80004942:	0792                	slli	a5,a5,0x4
    80004944:	0001d717          	auipc	a4,0x1d
    80004948:	26c70713          	addi	a4,a4,620 # 80021bb0 <devsw>
    8000494c:	97ba                	add	a5,a5,a4
    8000494e:	679c                	ld	a5,8(a5)
    80004950:	cff9                	beqz	a5,80004a2e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004952:	4505                	li	a0,1
    80004954:	9782                	jalr	a5
    80004956:	a841                	j	800049e6 <filewrite+0x10e>
    80004958:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	8ae080e7          	jalr	-1874(ra) # 8000420a <begin_op>
      ilock(f->ip);
    80004964:	01893503          	ld	a0,24(s2)
    80004968:	fffff097          	auipc	ra,0xfffff
    8000496c:	ee6080e7          	jalr	-282(ra) # 8000384e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004970:	8762                	mv	a4,s8
    80004972:	02092683          	lw	a3,32(s2)
    80004976:	01598633          	add	a2,s3,s5
    8000497a:	4585                	li	a1,1
    8000497c:	01893503          	ld	a0,24(s2)
    80004980:	fffff097          	auipc	ra,0xfffff
    80004984:	278080e7          	jalr	632(ra) # 80003bf8 <writei>
    80004988:	84aa                	mv	s1,a0
    8000498a:	02a05f63          	blez	a0,800049c8 <filewrite+0xf0>
        f->off += r;
    8000498e:	02092783          	lw	a5,32(s2)
    80004992:	9fa9                	addw	a5,a5,a0
    80004994:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004998:	01893503          	ld	a0,24(s2)
    8000499c:	fffff097          	auipc	ra,0xfffff
    800049a0:	f74080e7          	jalr	-140(ra) # 80003910 <iunlock>
      end_op();
    800049a4:	00000097          	auipc	ra,0x0
    800049a8:	8e6080e7          	jalr	-1818(ra) # 8000428a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800049ac:	049c1963          	bne	s8,s1,800049fe <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800049b0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049b4:	0349d663          	bge	s3,s4,800049e0 <filewrite+0x108>
      int n1 = n - i;
    800049b8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049bc:	84be                	mv	s1,a5
    800049be:	2781                	sext.w	a5,a5
    800049c0:	f8fb5ce3          	bge	s6,a5,80004958 <filewrite+0x80>
    800049c4:	84de                	mv	s1,s7
    800049c6:	bf49                	j	80004958 <filewrite+0x80>
      iunlock(f->ip);
    800049c8:	01893503          	ld	a0,24(s2)
    800049cc:	fffff097          	auipc	ra,0xfffff
    800049d0:	f44080e7          	jalr	-188(ra) # 80003910 <iunlock>
      end_op();
    800049d4:	00000097          	auipc	ra,0x0
    800049d8:	8b6080e7          	jalr	-1866(ra) # 8000428a <end_op>
      if(r < 0)
    800049dc:	fc04d8e3          	bgez	s1,800049ac <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049e0:	8552                	mv	a0,s4
    800049e2:	033a1863          	bne	s4,s3,80004a12 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049e6:	60a6                	ld	ra,72(sp)
    800049e8:	6406                	ld	s0,64(sp)
    800049ea:	74e2                	ld	s1,56(sp)
    800049ec:	7942                	ld	s2,48(sp)
    800049ee:	79a2                	ld	s3,40(sp)
    800049f0:	7a02                	ld	s4,32(sp)
    800049f2:	6ae2                	ld	s5,24(sp)
    800049f4:	6b42                	ld	s6,16(sp)
    800049f6:	6ba2                	ld	s7,8(sp)
    800049f8:	6c02                	ld	s8,0(sp)
    800049fa:	6161                	addi	sp,sp,80
    800049fc:	8082                	ret
        panic("short filewrite");
    800049fe:	00004517          	auipc	a0,0x4
    80004a02:	d0a50513          	addi	a0,a0,-758 # 80008708 <syscalls+0x268>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	b50080e7          	jalr	-1200(ra) # 80000556 <panic>
    int i = 0;
    80004a0e:	4981                	li	s3,0
    80004a10:	bfc1                	j	800049e0 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004a12:	557d                	li	a0,-1
    80004a14:	bfc9                	j	800049e6 <filewrite+0x10e>
    panic("filewrite");
    80004a16:	00004517          	auipc	a0,0x4
    80004a1a:	d0250513          	addi	a0,a0,-766 # 80008718 <syscalls+0x278>
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	b38080e7          	jalr	-1224(ra) # 80000556 <panic>
    return -1;
    80004a26:	557d                	li	a0,-1
}
    80004a28:	8082                	ret
      return -1;
    80004a2a:	557d                	li	a0,-1
    80004a2c:	bf6d                	j	800049e6 <filewrite+0x10e>
    80004a2e:	557d                	li	a0,-1
    80004a30:	bf5d                	j	800049e6 <filewrite+0x10e>

0000000080004a32 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a32:	7179                	addi	sp,sp,-48
    80004a34:	f406                	sd	ra,40(sp)
    80004a36:	f022                	sd	s0,32(sp)
    80004a38:	ec26                	sd	s1,24(sp)
    80004a3a:	e84a                	sd	s2,16(sp)
    80004a3c:	e44e                	sd	s3,8(sp)
    80004a3e:	e052                	sd	s4,0(sp)
    80004a40:	1800                	addi	s0,sp,48
    80004a42:	84aa                	mv	s1,a0
    80004a44:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a46:	0005b023          	sd	zero,0(a1)
    80004a4a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a4e:	00000097          	auipc	ra,0x0
    80004a52:	bd2080e7          	jalr	-1070(ra) # 80004620 <filealloc>
    80004a56:	e088                	sd	a0,0(s1)
    80004a58:	c551                	beqz	a0,80004ae4 <pipealloc+0xb2>
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	bc6080e7          	jalr	-1082(ra) # 80004620 <filealloc>
    80004a62:	00aa3023          	sd	a0,0(s4)
    80004a66:	c92d                	beqz	a0,80004ad8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	0c6080e7          	jalr	198(ra) # 80000b2e <kalloc>
    80004a70:	892a                	mv	s2,a0
    80004a72:	c125                	beqz	a0,80004ad2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a74:	4985                	li	s3,1
    80004a76:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a7a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a7e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a82:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a86:	00004597          	auipc	a1,0x4
    80004a8a:	ca258593          	addi	a1,a1,-862 # 80008728 <syscalls+0x288>
    80004a8e:	ffffc097          	auipc	ra,0xffffc
    80004a92:	100080e7          	jalr	256(ra) # 80000b8e <initlock>
  (*f0)->type = FD_PIPE;
    80004a96:	609c                	ld	a5,0(s1)
    80004a98:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a9c:	609c                	ld	a5,0(s1)
    80004a9e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004aa2:	609c                	ld	a5,0(s1)
    80004aa4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aa8:	609c                	ld	a5,0(s1)
    80004aaa:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aae:	000a3783          	ld	a5,0(s4)
    80004ab2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ab6:	000a3783          	ld	a5,0(s4)
    80004aba:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004abe:	000a3783          	ld	a5,0(s4)
    80004ac2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ac6:	000a3783          	ld	a5,0(s4)
    80004aca:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ace:	4501                	li	a0,0
    80004ad0:	a025                	j	80004af8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ad2:	6088                	ld	a0,0(s1)
    80004ad4:	e501                	bnez	a0,80004adc <pipealloc+0xaa>
    80004ad6:	a039                	j	80004ae4 <pipealloc+0xb2>
    80004ad8:	6088                	ld	a0,0(s1)
    80004ada:	c51d                	beqz	a0,80004b08 <pipealloc+0xd6>
    fileclose(*f0);
    80004adc:	00000097          	auipc	ra,0x0
    80004ae0:	c00080e7          	jalr	-1024(ra) # 800046dc <fileclose>
  if(*f1)
    80004ae4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ae8:	557d                	li	a0,-1
  if(*f1)
    80004aea:	c799                	beqz	a5,80004af8 <pipealloc+0xc6>
    fileclose(*f1);
    80004aec:	853e                	mv	a0,a5
    80004aee:	00000097          	auipc	ra,0x0
    80004af2:	bee080e7          	jalr	-1042(ra) # 800046dc <fileclose>
  return -1;
    80004af6:	557d                	li	a0,-1
}
    80004af8:	70a2                	ld	ra,40(sp)
    80004afa:	7402                	ld	s0,32(sp)
    80004afc:	64e2                	ld	s1,24(sp)
    80004afe:	6942                	ld	s2,16(sp)
    80004b00:	69a2                	ld	s3,8(sp)
    80004b02:	6a02                	ld	s4,0(sp)
    80004b04:	6145                	addi	sp,sp,48
    80004b06:	8082                	ret
  return -1;
    80004b08:	557d                	li	a0,-1
    80004b0a:	b7fd                	j	80004af8 <pipealloc+0xc6>

0000000080004b0c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b0c:	1101                	addi	sp,sp,-32
    80004b0e:	ec06                	sd	ra,24(sp)
    80004b10:	e822                	sd	s0,16(sp)
    80004b12:	e426                	sd	s1,8(sp)
    80004b14:	e04a                	sd	s2,0(sp)
    80004b16:	1000                	addi	s0,sp,32
    80004b18:	84aa                	mv	s1,a0
    80004b1a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	102080e7          	jalr	258(ra) # 80000c1e <acquire>
  if(writable){
    80004b24:	02090d63          	beqz	s2,80004b5e <pipeclose+0x52>
    pi->writeopen = 0;
    80004b28:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b2c:	21848513          	addi	a0,s1,536
    80004b30:	ffffe097          	auipc	ra,0xffffe
    80004b34:	a84080e7          	jalr	-1404(ra) # 800025b4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b38:	2204b783          	ld	a5,544(s1)
    80004b3c:	eb95                	bnez	a5,80004b70 <pipeclose+0x64>
    release(&pi->lock);
    80004b3e:	8526                	mv	a0,s1
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	192080e7          	jalr	402(ra) # 80000cd2 <release>
    kfree((char*)pi);
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	ee8080e7          	jalr	-280(ra) # 80000a32 <kfree>
  } else
    release(&pi->lock);
}
    80004b52:	60e2                	ld	ra,24(sp)
    80004b54:	6442                	ld	s0,16(sp)
    80004b56:	64a2                	ld	s1,8(sp)
    80004b58:	6902                	ld	s2,0(sp)
    80004b5a:	6105                	addi	sp,sp,32
    80004b5c:	8082                	ret
    pi->readopen = 0;
    80004b5e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b62:	21c48513          	addi	a0,s1,540
    80004b66:	ffffe097          	auipc	ra,0xffffe
    80004b6a:	a4e080e7          	jalr	-1458(ra) # 800025b4 <wakeup>
    80004b6e:	b7e9                	j	80004b38 <pipeclose+0x2c>
    release(&pi->lock);
    80004b70:	8526                	mv	a0,s1
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	160080e7          	jalr	352(ra) # 80000cd2 <release>
}
    80004b7a:	bfe1                	j	80004b52 <pipeclose+0x46>

0000000080004b7c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b7c:	7119                	addi	sp,sp,-128
    80004b7e:	fc86                	sd	ra,120(sp)
    80004b80:	f8a2                	sd	s0,112(sp)
    80004b82:	f4a6                	sd	s1,104(sp)
    80004b84:	f0ca                	sd	s2,96(sp)
    80004b86:	ecce                	sd	s3,88(sp)
    80004b88:	e8d2                	sd	s4,80(sp)
    80004b8a:	e4d6                	sd	s5,72(sp)
    80004b8c:	e0da                	sd	s6,64(sp)
    80004b8e:	fc5e                	sd	s7,56(sp)
    80004b90:	f862                	sd	s8,48(sp)
    80004b92:	f466                	sd	s9,40(sp)
    80004b94:	f06a                	sd	s10,32(sp)
    80004b96:	ec6e                	sd	s11,24(sp)
    80004b98:	0100                	addi	s0,sp,128
    80004b9a:	84aa                	mv	s1,a0
    80004b9c:	8cae                	mv	s9,a1
    80004b9e:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	f66080e7          	jalr	-154(ra) # 80001b06 <myproc>
    80004ba8:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	072080e7          	jalr	114(ra) # 80000c1e <acquire>
  for(i = 0; i < n; i++){
    80004bb4:	0d605963          	blez	s6,80004c86 <pipewrite+0x10a>
    80004bb8:	89a6                	mv	s3,s1
    80004bba:	3b7d                	addiw	s6,s6,-1
    80004bbc:	1b02                	slli	s6,s6,0x20
    80004bbe:	020b5b13          	srli	s6,s6,0x20
    80004bc2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004bc4:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bc8:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bcc:	5dfd                	li	s11,-1
    80004bce:	000b8d1b          	sext.w	s10,s7
    80004bd2:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bd4:	2184a783          	lw	a5,536(s1)
    80004bd8:	21c4a703          	lw	a4,540(s1)
    80004bdc:	2007879b          	addiw	a5,a5,512
    80004be0:	02f71b63          	bne	a4,a5,80004c16 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004be4:	2204a783          	lw	a5,544(s1)
    80004be8:	cbad                	beqz	a5,80004c5a <pipewrite+0xde>
    80004bea:	03092783          	lw	a5,48(s2)
    80004bee:	e7b5                	bnez	a5,80004c5a <pipewrite+0xde>
      wakeup(&pi->nread);
    80004bf0:	8556                	mv	a0,s5
    80004bf2:	ffffe097          	auipc	ra,0xffffe
    80004bf6:	9c2080e7          	jalr	-1598(ra) # 800025b4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bfa:	85ce                	mv	a1,s3
    80004bfc:	8552                	mv	a0,s4
    80004bfe:	ffffe097          	auipc	ra,0xffffe
    80004c02:	830080e7          	jalr	-2000(ra) # 8000242e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c06:	2184a783          	lw	a5,536(s1)
    80004c0a:	21c4a703          	lw	a4,540(s1)
    80004c0e:	2007879b          	addiw	a5,a5,512
    80004c12:	fcf709e3          	beq	a4,a5,80004be4 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c16:	4685                	li	a3,1
    80004c18:	019b8633          	add	a2,s7,s9
    80004c1c:	f8f40593          	addi	a1,s0,-113
    80004c20:	05093503          	ld	a0,80(s2)
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	dda080e7          	jalr	-550(ra) # 800019fe <copyin>
    80004c2c:	05b50e63          	beq	a0,s11,80004c88 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c30:	21c4a783          	lw	a5,540(s1)
    80004c34:	0017871b          	addiw	a4,a5,1
    80004c38:	20e4ae23          	sw	a4,540(s1)
    80004c3c:	1ff7f793          	andi	a5,a5,511
    80004c40:	97a6                	add	a5,a5,s1
    80004c42:	f8f44703          	lbu	a4,-113(s0)
    80004c46:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c4a:	001d0c1b          	addiw	s8,s10,1
    80004c4e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c52:	036b8b63          	beq	s7,s6,80004c88 <pipewrite+0x10c>
    80004c56:	8bbe                	mv	s7,a5
    80004c58:	bf9d                	j	80004bce <pipewrite+0x52>
        release(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	076080e7          	jalr	118(ra) # 80000cd2 <release>
        return -1;
    80004c64:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c66:	8562                	mv	a0,s8
    80004c68:	70e6                	ld	ra,120(sp)
    80004c6a:	7446                	ld	s0,112(sp)
    80004c6c:	74a6                	ld	s1,104(sp)
    80004c6e:	7906                	ld	s2,96(sp)
    80004c70:	69e6                	ld	s3,88(sp)
    80004c72:	6a46                	ld	s4,80(sp)
    80004c74:	6aa6                	ld	s5,72(sp)
    80004c76:	6b06                	ld	s6,64(sp)
    80004c78:	7be2                	ld	s7,56(sp)
    80004c7a:	7c42                	ld	s8,48(sp)
    80004c7c:	7ca2                	ld	s9,40(sp)
    80004c7e:	7d02                	ld	s10,32(sp)
    80004c80:	6de2                	ld	s11,24(sp)
    80004c82:	6109                	addi	sp,sp,128
    80004c84:	8082                	ret
  for(i = 0; i < n; i++){
    80004c86:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c88:	21848513          	addi	a0,s1,536
    80004c8c:	ffffe097          	auipc	ra,0xffffe
    80004c90:	928080e7          	jalr	-1752(ra) # 800025b4 <wakeup>
  release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	03c080e7          	jalr	60(ra) # 80000cd2 <release>
  return i;
    80004c9e:	b7e1                	j	80004c66 <pipewrite+0xea>

0000000080004ca0 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ca0:	715d                	addi	sp,sp,-80
    80004ca2:	e486                	sd	ra,72(sp)
    80004ca4:	e0a2                	sd	s0,64(sp)
    80004ca6:	fc26                	sd	s1,56(sp)
    80004ca8:	f84a                	sd	s2,48(sp)
    80004caa:	f44e                	sd	s3,40(sp)
    80004cac:	f052                	sd	s4,32(sp)
    80004cae:	ec56                	sd	s5,24(sp)
    80004cb0:	e85a                	sd	s6,16(sp)
    80004cb2:	0880                	addi	s0,sp,80
    80004cb4:	84aa                	mv	s1,a0
    80004cb6:	892e                	mv	s2,a1
    80004cb8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cba:	ffffd097          	auipc	ra,0xffffd
    80004cbe:	e4c080e7          	jalr	-436(ra) # 80001b06 <myproc>
    80004cc2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cc4:	8b26                	mv	s6,s1
    80004cc6:	8526                	mv	a0,s1
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	f56080e7          	jalr	-170(ra) # 80000c1e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd0:	2184a703          	lw	a4,536(s1)
    80004cd4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cd8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cdc:	02f71463          	bne	a4,a5,80004d04 <piperead+0x64>
    80004ce0:	2244a783          	lw	a5,548(s1)
    80004ce4:	c385                	beqz	a5,80004d04 <piperead+0x64>
    if(pr->killed){
    80004ce6:	030a2783          	lw	a5,48(s4)
    80004cea:	ebc1                	bnez	a5,80004d7a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cec:	85da                	mv	a1,s6
    80004cee:	854e                	mv	a0,s3
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	73e080e7          	jalr	1854(ra) # 8000242e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf8:	2184a703          	lw	a4,536(s1)
    80004cfc:	21c4a783          	lw	a5,540(s1)
    80004d00:	fef700e3          	beq	a4,a5,80004ce0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d04:	09505263          	blez	s5,80004d88 <piperead+0xe8>
    80004d08:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d0a:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d0c:	2184a783          	lw	a5,536(s1)
    80004d10:	21c4a703          	lw	a4,540(s1)
    80004d14:	02f70d63          	beq	a4,a5,80004d4e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d18:	0017871b          	addiw	a4,a5,1
    80004d1c:	20e4ac23          	sw	a4,536(s1)
    80004d20:	1ff7f793          	andi	a5,a5,511
    80004d24:	97a6                	add	a5,a5,s1
    80004d26:	0187c783          	lbu	a5,24(a5)
    80004d2a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d2e:	4685                	li	a3,1
    80004d30:	fbf40613          	addi	a2,s0,-65
    80004d34:	85ca                	mv	a1,s2
    80004d36:	050a3503          	ld	a0,80(s4)
    80004d3a:	ffffd097          	auipc	ra,0xffffd
    80004d3e:	c38080e7          	jalr	-968(ra) # 80001972 <copyout>
    80004d42:	01650663          	beq	a0,s6,80004d4e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d46:	2985                	addiw	s3,s3,1
    80004d48:	0905                	addi	s2,s2,1
    80004d4a:	fd3a91e3          	bne	s5,s3,80004d0c <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d4e:	21c48513          	addi	a0,s1,540
    80004d52:	ffffe097          	auipc	ra,0xffffe
    80004d56:	862080e7          	jalr	-1950(ra) # 800025b4 <wakeup>
  release(&pi->lock);
    80004d5a:	8526                	mv	a0,s1
    80004d5c:	ffffc097          	auipc	ra,0xffffc
    80004d60:	f76080e7          	jalr	-138(ra) # 80000cd2 <release>
  return i;
}
    80004d64:	854e                	mv	a0,s3
    80004d66:	60a6                	ld	ra,72(sp)
    80004d68:	6406                	ld	s0,64(sp)
    80004d6a:	74e2                	ld	s1,56(sp)
    80004d6c:	7942                	ld	s2,48(sp)
    80004d6e:	79a2                	ld	s3,40(sp)
    80004d70:	7a02                	ld	s4,32(sp)
    80004d72:	6ae2                	ld	s5,24(sp)
    80004d74:	6b42                	ld	s6,16(sp)
    80004d76:	6161                	addi	sp,sp,80
    80004d78:	8082                	ret
      release(&pi->lock);
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	f56080e7          	jalr	-170(ra) # 80000cd2 <release>
      return -1;
    80004d84:	59fd                	li	s3,-1
    80004d86:	bff9                	j	80004d64 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d88:	4981                	li	s3,0
    80004d8a:	b7d1                	j	80004d4e <piperead+0xae>

0000000080004d8c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d8c:	de010113          	addi	sp,sp,-544
    80004d90:	20113c23          	sd	ra,536(sp)
    80004d94:	20813823          	sd	s0,528(sp)
    80004d98:	20913423          	sd	s1,520(sp)
    80004d9c:	21213023          	sd	s2,512(sp)
    80004da0:	ffce                	sd	s3,504(sp)
    80004da2:	fbd2                	sd	s4,496(sp)
    80004da4:	f7d6                	sd	s5,488(sp)
    80004da6:	f3da                	sd	s6,480(sp)
    80004da8:	efde                	sd	s7,472(sp)
    80004daa:	ebe2                	sd	s8,464(sp)
    80004dac:	e7e6                	sd	s9,456(sp)
    80004dae:	e3ea                	sd	s10,448(sp)
    80004db0:	ff6e                	sd	s11,440(sp)
    80004db2:	1400                	addi	s0,sp,544
    80004db4:	84aa                	mv	s1,a0
    80004db6:	dea43823          	sd	a0,-528(s0)
    80004dba:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	d48080e7          	jalr	-696(ra) # 80001b06 <myproc>
    80004dc6:	892a                	mv	s2,a0

  begin_op();
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	442080e7          	jalr	1090(ra) # 8000420a <begin_op>

  if((ip = namei(path)) == 0){
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	22c080e7          	jalr	556(ra) # 80003ffe <namei>
    80004dda:	c93d                	beqz	a0,80004e50 <exec+0xc4>
    80004ddc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	a70080e7          	jalr	-1424(ra) # 8000384e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004de6:	04000713          	li	a4,64
    80004dea:	4681                	li	a3,0
    80004dec:	e4840613          	addi	a2,s0,-440
    80004df0:	4581                	li	a1,0
    80004df2:	8526                	mv	a0,s1
    80004df4:	fffff097          	auipc	ra,0xfffff
    80004df8:	d0e080e7          	jalr	-754(ra) # 80003b02 <readi>
    80004dfc:	04000793          	li	a5,64
    80004e00:	00f51a63          	bne	a0,a5,80004e14 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004e04:	e4842703          	lw	a4,-440(s0)
    80004e08:	464c47b7          	lui	a5,0x464c4
    80004e0c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e10:	04f70663          	beq	a4,a5,80004e5c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e14:	8526                	mv	a0,s1
    80004e16:	fffff097          	auipc	ra,0xfffff
    80004e1a:	c9a080e7          	jalr	-870(ra) # 80003ab0 <iunlockput>
    end_op();
    80004e1e:	fffff097          	auipc	ra,0xfffff
    80004e22:	46c080e7          	jalr	1132(ra) # 8000428a <end_op>
  }
  return -1;
    80004e26:	557d                	li	a0,-1
}
    80004e28:	21813083          	ld	ra,536(sp)
    80004e2c:	21013403          	ld	s0,528(sp)
    80004e30:	20813483          	ld	s1,520(sp)
    80004e34:	20013903          	ld	s2,512(sp)
    80004e38:	79fe                	ld	s3,504(sp)
    80004e3a:	7a5e                	ld	s4,496(sp)
    80004e3c:	7abe                	ld	s5,488(sp)
    80004e3e:	7b1e                	ld	s6,480(sp)
    80004e40:	6bfe                	ld	s7,472(sp)
    80004e42:	6c5e                	ld	s8,464(sp)
    80004e44:	6cbe                	ld	s9,456(sp)
    80004e46:	6d1e                	ld	s10,448(sp)
    80004e48:	7dfa                	ld	s11,440(sp)
    80004e4a:	22010113          	addi	sp,sp,544
    80004e4e:	8082                	ret
    end_op();
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	43a080e7          	jalr	1082(ra) # 8000428a <end_op>
    return -1;
    80004e58:	557d                	li	a0,-1
    80004e5a:	b7f9                	j	80004e28 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e5c:	854a                	mv	a0,s2
    80004e5e:	ffffd097          	auipc	ra,0xffffd
    80004e62:	d6c080e7          	jalr	-660(ra) # 80001bca <proc_pagetable>
    80004e66:	e0a43423          	sd	a0,-504(s0)
    80004e6a:	d54d                	beqz	a0,80004e14 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e6c:	e6842983          	lw	s3,-408(s0)
    80004e70:	e8045783          	lhu	a5,-384(s0)
    80004e74:	cbb5                	beqz	a5,80004ee8 <exec+0x15c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e76:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e78:	4b01                	li	s6,0
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004e7a:	0c0007b7          	lui	a5,0xc000
    80004e7e:	17f9                	addi	a5,a5,-2
    80004e80:	def43423          	sd	a5,-536(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e84:	6b85                	lui	s7,0x1
    80004e86:	fffb8793          	addi	a5,s7,-1 # fff <_entry-0x7ffff001>
    80004e8a:	def43023          	sd	a5,-544(s0)
    80004e8e:	a4bd                	j	800050fc <exec+0x370>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e90:	00004517          	auipc	a0,0x4
    80004e94:	8a050513          	addi	a0,a0,-1888 # 80008730 <syscalls+0x290>
    80004e98:	ffffb097          	auipc	ra,0xffffb
    80004e9c:	6be080e7          	jalr	1726(ra) # 80000556 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ea0:	8756                	mv	a4,s5
    80004ea2:	012d06bb          	addw	a3,s10,s2
    80004ea6:	4581                	li	a1,0
    80004ea8:	8526                	mv	a0,s1
    80004eaa:	fffff097          	auipc	ra,0xfffff
    80004eae:	c58080e7          	jalr	-936(ra) # 80003b02 <readi>
    80004eb2:	2501                	sext.w	a0,a0
    80004eb4:	1eaa9a63          	bne	s5,a0,800050a8 <exec+0x31c>
  for(i = 0; i < sz; i += PGSIZE){
    80004eb8:	6785                	lui	a5,0x1
    80004eba:	0127893b          	addw	s2,a5,s2
    80004ebe:	014d8a3b          	addw	s4,s11,s4
    80004ec2:	23897463          	bgeu	s2,s8,800050ea <exec+0x35e>
    pa = walkaddr(pagetable, va + i);
    80004ec6:	02091593          	slli	a1,s2,0x20
    80004eca:	9181                	srli	a1,a1,0x20
    80004ecc:	95e6                	add	a1,a1,s9
    80004ece:	e0843503          	ld	a0,-504(s0)
    80004ed2:	ffffc097          	auipc	ra,0xffffc
    80004ed6:	334080e7          	jalr	820(ra) # 80001206 <walkaddr>
    80004eda:	862a                	mv	a2,a0
    if(pa == 0)
    80004edc:	d955                	beqz	a0,80004e90 <exec+0x104>
      n = PGSIZE;
    80004ede:	8ade                	mv	s5,s7
    if(sz - i < PGSIZE)
    80004ee0:	fd7a70e3          	bgeu	s4,s7,80004ea0 <exec+0x114>
      n = sz - i;
    80004ee4:	8ad2                	mv	s5,s4
    80004ee6:	bf6d                	j	80004ea0 <exec+0x114>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004ee8:	4901                	li	s2,0
  iunlockput(ip);
    80004eea:	8526                	mv	a0,s1
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	bc4080e7          	jalr	-1084(ra) # 80003ab0 <iunlockput>
  end_op();
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	396080e7          	jalr	918(ra) # 8000428a <end_op>
  p = myproc();
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	c0a080e7          	jalr	-1014(ra) # 80001b06 <myproc>
    80004f04:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f06:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f0a:	6785                	lui	a5,0x1
    80004f0c:	17fd                	addi	a5,a5,-1
    80004f0e:	993e                	add	s2,s2,a5
    80004f10:	757d                	lui	a0,0xfffff
    80004f12:	00a977b3          	and	a5,s2,a0
    80004f16:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f1a:	6609                	lui	a2,0x2
    80004f1c:	963e                	add	a2,a2,a5
    80004f1e:	85be                	mv	a1,a5
    80004f20:	e0843903          	ld	s2,-504(s0)
    80004f24:	854a                	mv	a0,s2
    80004f26:	ffffc097          	auipc	ra,0xffffc
    80004f2a:	7fc080e7          	jalr	2044(ra) # 80001722 <uvmalloc>
    80004f2e:	8b2a                	mv	s6,a0
  ip = 0;
    80004f30:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004f32:	16050b63          	beqz	a0,800050a8 <exec+0x31c>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f36:	75f9                	lui	a1,0xffffe
    80004f38:	95aa                	add	a1,a1,a0
    80004f3a:	854a                	mv	a0,s2
    80004f3c:	ffffd097          	auipc	ra,0xffffd
    80004f40:	a04080e7          	jalr	-1532(ra) # 80001940 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f44:	7c7d                	lui	s8,0xfffff
    80004f46:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f48:	df843783          	ld	a5,-520(s0)
    80004f4c:	6388                	ld	a0,0(a5)
    80004f4e:	c53d                	beqz	a0,80004fbc <exec+0x230>
    80004f50:	e8840993          	addi	s3,s0,-376
    80004f54:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f58:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	f48080e7          	jalr	-184(ra) # 80000ea2 <strlen>
    80004f62:	2505                	addiw	a0,a0,1
    80004f64:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f68:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f6c:	17896363          	bltu	s2,s8,800050d2 <exec+0x346>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f70:	df843b83          	ld	s7,-520(s0)
    80004f74:	000bba03          	ld	s4,0(s7)
    80004f78:	8552                	mv	a0,s4
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	f28080e7          	jalr	-216(ra) # 80000ea2 <strlen>
    80004f82:	0015069b          	addiw	a3,a0,1
    80004f86:	8652                	mv	a2,s4
    80004f88:	85ca                	mv	a1,s2
    80004f8a:	e0843503          	ld	a0,-504(s0)
    80004f8e:	ffffd097          	auipc	ra,0xffffd
    80004f92:	9e4080e7          	jalr	-1564(ra) # 80001972 <copyout>
    80004f96:	14054263          	bltz	a0,800050da <exec+0x34e>
    ustack[argc] = sp;
    80004f9a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f9e:	0485                	addi	s1,s1,1
    80004fa0:	008b8793          	addi	a5,s7,8
    80004fa4:	def43c23          	sd	a5,-520(s0)
    80004fa8:	008bb503          	ld	a0,8(s7)
    80004fac:	c911                	beqz	a0,80004fc0 <exec+0x234>
    if(argc >= MAXARG)
    80004fae:	09a1                	addi	s3,s3,8
    80004fb0:	fb3c95e3          	bne	s9,s3,80004f5a <exec+0x1ce>
  sz = sz1;
    80004fb4:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004fb8:	4481                	li	s1,0
    80004fba:	a0fd                	j	800050a8 <exec+0x31c>
  sp = sz;
    80004fbc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fbe:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fc0:	00349793          	slli	a5,s1,0x3
    80004fc4:	f9040713          	addi	a4,s0,-112
    80004fc8:	97ba                	add	a5,a5,a4
    80004fca:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004fce:	00148693          	addi	a3,s1,1
    80004fd2:	068e                	slli	a3,a3,0x3
    80004fd4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fd8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fdc:	01897663          	bgeu	s2,s8,80004fe8 <exec+0x25c>
  sz = sz1;
    80004fe0:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004fe4:	4481                	li	s1,0
    80004fe6:	a0c9                	j	800050a8 <exec+0x31c>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fe8:	e8840613          	addi	a2,s0,-376
    80004fec:	85ca                	mv	a1,s2
    80004fee:	e0843503          	ld	a0,-504(s0)
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	980080e7          	jalr	-1664(ra) # 80001972 <copyout>
    80004ffa:	0e054463          	bltz	a0,800050e2 <exec+0x356>
  p->trapframe->a1 = sp;
    80004ffe:	058ab783          	ld	a5,88(s5)
    80005002:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005006:	df043783          	ld	a5,-528(s0)
    8000500a:	0007c703          	lbu	a4,0(a5)
    8000500e:	cf11                	beqz	a4,8000502a <exec+0x29e>
    80005010:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005012:	02f00693          	li	a3,47
    80005016:	a039                	j	80005024 <exec+0x298>
      last = s+1;
    80005018:	def43823          	sd	a5,-528(s0)
  for(last=s=path; *s; s++)
    8000501c:	0785                	addi	a5,a5,1
    8000501e:	fff7c703          	lbu	a4,-1(a5)
    80005022:	c701                	beqz	a4,8000502a <exec+0x29e>
    if(*s == '/')
    80005024:	fed71ce3          	bne	a4,a3,8000501c <exec+0x290>
    80005028:	bfc5                	j	80005018 <exec+0x28c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000502a:	4641                	li	a2,16
    8000502c:	df043583          	ld	a1,-528(s0)
    80005030:	158a8513          	addi	a0,s5,344
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	e3c080e7          	jalr	-452(ra) # 80000e70 <safestrcpy>
  uvmunmap(p->kernelpgtbl, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    8000503c:	6605                	lui	a2,0x1
    8000503e:	167d                	addi	a2,a2,-1
    80005040:	966a                	add	a2,a2,s10
    80005042:	4681                	li	a3,0
    80005044:	8231                	srli	a2,a2,0xc
    80005046:	4581                	li	a1,0
    80005048:	168ab503          	ld	a0,360(s5)
    8000504c:	ffffc097          	auipc	ra,0xffffc
    80005050:	42e080e7          	jalr	1070(ra) # 8000147a <uvmunmap>
  kvmcopymappings(pagetable, p->kernelpgtbl, 0, sz);
    80005054:	86da                	mv	a3,s6
    80005056:	4601                	li	a2,0
    80005058:	168ab583          	ld	a1,360(s5)
    8000505c:	e0843983          	ld	s3,-504(s0)
    80005060:	854e                	mv	a0,s3
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	4dc080e7          	jalr	1244(ra) # 8000153e <kvmcopymappings>
  oldpagetable = p->pagetable;
    8000506a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000506e:	053ab823          	sd	s3,80(s5)
  p->sz = sz;
    80005072:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005076:	058ab783          	ld	a5,88(s5)
    8000507a:	e6043703          	ld	a4,-416(s0)
    8000507e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005080:	058ab783          	ld	a5,88(s5)
    80005084:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005088:	85ea                	mv	a1,s10
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	bdc080e7          	jalr	-1060(ra) # 80001c66 <proc_freepagetable>
  vmprint(p->pagetable); // 按照实验要求，在 exec 返回之前打印一下页表。
    80005092:	050ab503          	ld	a0,80(s5)
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	01a080e7          	jalr	26(ra) # 800010b0 <vmprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000509e:	0004851b          	sext.w	a0,s1
    800050a2:	b359                	j	80004e28 <exec+0x9c>
    800050a4:	e1243023          	sd	s2,-512(s0)
    proc_freepagetable(pagetable, sz);
    800050a8:	e0043583          	ld	a1,-512(s0)
    800050ac:	e0843503          	ld	a0,-504(s0)
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	bb6080e7          	jalr	-1098(ra) # 80001c66 <proc_freepagetable>
  if(ip){
    800050b8:	d4049ee3          	bnez	s1,80004e14 <exec+0x88>
  return -1;
    800050bc:	557d                	li	a0,-1
    800050be:	b3ad                	j	80004e28 <exec+0x9c>
    800050c0:	e1243023          	sd	s2,-512(s0)
    800050c4:	b7d5                	j	800050a8 <exec+0x31c>
    800050c6:	e1243023          	sd	s2,-512(s0)
    800050ca:	bff9                	j	800050a8 <exec+0x31c>
    800050cc:	e1243023          	sd	s2,-512(s0)
    800050d0:	bfe1                	j	800050a8 <exec+0x31c>
  sz = sz1;
    800050d2:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050d6:	4481                	li	s1,0
    800050d8:	bfc1                	j	800050a8 <exec+0x31c>
  sz = sz1;
    800050da:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050de:	4481                	li	s1,0
    800050e0:	b7e1                	j	800050a8 <exec+0x31c>
  sz = sz1;
    800050e2:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050e6:	4481                	li	s1,0
    800050e8:	b7c1                	j	800050a8 <exec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050ea:	e0043903          	ld	s2,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ee:	2b05                	addiw	s6,s6,1
    800050f0:	0389899b          	addiw	s3,s3,56
    800050f4:	e8045783          	lhu	a5,-384(s0)
    800050f8:	defb59e3          	bge	s6,a5,80004eea <exec+0x15e>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050fc:	2981                	sext.w	s3,s3
    800050fe:	03800713          	li	a4,56
    80005102:	86ce                	mv	a3,s3
    80005104:	e1040613          	addi	a2,s0,-496
    80005108:	4581                	li	a1,0
    8000510a:	8526                	mv	a0,s1
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	9f6080e7          	jalr	-1546(ra) # 80003b02 <readi>
    80005114:	03800793          	li	a5,56
    80005118:	f8f516e3          	bne	a0,a5,800050a4 <exec+0x318>
    if(ph.type != ELF_PROG_LOAD)
    8000511c:	e1042783          	lw	a5,-496(s0)
    80005120:	4705                	li	a4,1
    80005122:	fce796e3          	bne	a5,a4,800050ee <exec+0x362>
    if(ph.memsz < ph.filesz)
    80005126:	e3843603          	ld	a2,-456(s0)
    8000512a:	e3043783          	ld	a5,-464(s0)
    8000512e:	f8f669e3          	bltu	a2,a5,800050c0 <exec+0x334>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005132:	e2043783          	ld	a5,-480(s0)
    80005136:	963e                	add	a2,a2,a5
    80005138:	f8f667e3          	bltu	a2,a5,800050c6 <exec+0x33a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000513c:	85ca                	mv	a1,s2
    8000513e:	e0843503          	ld	a0,-504(s0)
    80005142:	ffffc097          	auipc	ra,0xffffc
    80005146:	5e0080e7          	jalr	1504(ra) # 80001722 <uvmalloc>
    8000514a:	e0a43023          	sd	a0,-512(s0)
    8000514e:	fff50793          	addi	a5,a0,-1 # ffffffffffffefff <end+0xffffffff7ffd7fdf>
    80005152:	de843703          	ld	a4,-536(s0)
    80005156:	f6f76be3          	bltu	a4,a5,800050cc <exec+0x340>
    if(ph.vaddr % PGSIZE != 0)
    8000515a:	e2043c83          	ld	s9,-480(s0)
    8000515e:	de043783          	ld	a5,-544(s0)
    80005162:	00fcf7b3          	and	a5,s9,a5
    80005166:	f3a9                	bnez	a5,800050a8 <exec+0x31c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005168:	e1842d03          	lw	s10,-488(s0)
    8000516c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005170:	f60c0de3          	beqz	s8,800050ea <exec+0x35e>
    80005174:	8a62                	mv	s4,s8
    80005176:	4901                	li	s2,0
    80005178:	7dfd                	lui	s11,0xfffff
    8000517a:	b3b1                	j	80004ec6 <exec+0x13a>

000000008000517c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000517c:	7179                	addi	sp,sp,-48
    8000517e:	f406                	sd	ra,40(sp)
    80005180:	f022                	sd	s0,32(sp)
    80005182:	ec26                	sd	s1,24(sp)
    80005184:	e84a                	sd	s2,16(sp)
    80005186:	1800                	addi	s0,sp,48
    80005188:	892e                	mv	s2,a1
    8000518a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000518c:	fdc40593          	addi	a1,s0,-36
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	b4c080e7          	jalr	-1204(ra) # 80002cdc <argint>
    80005198:	04054063          	bltz	a0,800051d8 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000519c:	fdc42703          	lw	a4,-36(s0)
    800051a0:	47bd                	li	a5,15
    800051a2:	02e7ed63          	bltu	a5,a4,800051dc <argfd+0x60>
    800051a6:	ffffd097          	auipc	ra,0xffffd
    800051aa:	960080e7          	jalr	-1696(ra) # 80001b06 <myproc>
    800051ae:	fdc42703          	lw	a4,-36(s0)
    800051b2:	01a70793          	addi	a5,a4,26
    800051b6:	078e                	slli	a5,a5,0x3
    800051b8:	953e                	add	a0,a0,a5
    800051ba:	611c                	ld	a5,0(a0)
    800051bc:	c395                	beqz	a5,800051e0 <argfd+0x64>
    return -1;
  if(pfd)
    800051be:	00090463          	beqz	s2,800051c6 <argfd+0x4a>
    *pfd = fd;
    800051c2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051c6:	4501                	li	a0,0
  if(pf)
    800051c8:	c091                	beqz	s1,800051cc <argfd+0x50>
    *pf = f;
    800051ca:	e09c                	sd	a5,0(s1)
}
    800051cc:	70a2                	ld	ra,40(sp)
    800051ce:	7402                	ld	s0,32(sp)
    800051d0:	64e2                	ld	s1,24(sp)
    800051d2:	6942                	ld	s2,16(sp)
    800051d4:	6145                	addi	sp,sp,48
    800051d6:	8082                	ret
    return -1;
    800051d8:	557d                	li	a0,-1
    800051da:	bfcd                	j	800051cc <argfd+0x50>
    return -1;
    800051dc:	557d                	li	a0,-1
    800051de:	b7fd                	j	800051cc <argfd+0x50>
    800051e0:	557d                	li	a0,-1
    800051e2:	b7ed                	j	800051cc <argfd+0x50>

00000000800051e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051e4:	1101                	addi	sp,sp,-32
    800051e6:	ec06                	sd	ra,24(sp)
    800051e8:	e822                	sd	s0,16(sp)
    800051ea:	e426                	sd	s1,8(sp)
    800051ec:	1000                	addi	s0,sp,32
    800051ee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051f0:	ffffd097          	auipc	ra,0xffffd
    800051f4:	916080e7          	jalr	-1770(ra) # 80001b06 <myproc>
    800051f8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051fa:	0d050793          	addi	a5,a0,208
    800051fe:	4501                	li	a0,0
    80005200:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005202:	6398                	ld	a4,0(a5)
    80005204:	cb19                	beqz	a4,8000521a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005206:	2505                	addiw	a0,a0,1
    80005208:	07a1                	addi	a5,a5,8
    8000520a:	fed51ce3          	bne	a0,a3,80005202 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000520e:	557d                	li	a0,-1
}
    80005210:	60e2                	ld	ra,24(sp)
    80005212:	6442                	ld	s0,16(sp)
    80005214:	64a2                	ld	s1,8(sp)
    80005216:	6105                	addi	sp,sp,32
    80005218:	8082                	ret
      p->ofile[fd] = f;
    8000521a:	01a50793          	addi	a5,a0,26
    8000521e:	078e                	slli	a5,a5,0x3
    80005220:	963e                	add	a2,a2,a5
    80005222:	e204                	sd	s1,0(a2)
      return fd;
    80005224:	b7f5                	j	80005210 <fdalloc+0x2c>

0000000080005226 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005226:	715d                	addi	sp,sp,-80
    80005228:	e486                	sd	ra,72(sp)
    8000522a:	e0a2                	sd	s0,64(sp)
    8000522c:	fc26                	sd	s1,56(sp)
    8000522e:	f84a                	sd	s2,48(sp)
    80005230:	f44e                	sd	s3,40(sp)
    80005232:	f052                	sd	s4,32(sp)
    80005234:	ec56                	sd	s5,24(sp)
    80005236:	0880                	addi	s0,sp,80
    80005238:	89ae                	mv	s3,a1
    8000523a:	8ab2                	mv	s5,a2
    8000523c:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000523e:	fb040593          	addi	a1,s0,-80
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	dda080e7          	jalr	-550(ra) # 8000401c <nameiparent>
    8000524a:	892a                	mv	s2,a0
    8000524c:	12050f63          	beqz	a0,8000538a <create+0x164>
    return 0;

  ilock(dp);
    80005250:	ffffe097          	auipc	ra,0xffffe
    80005254:	5fe080e7          	jalr	1534(ra) # 8000384e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005258:	4601                	li	a2,0
    8000525a:	fb040593          	addi	a1,s0,-80
    8000525e:	854a                	mv	a0,s2
    80005260:	fffff097          	auipc	ra,0xfffff
    80005264:	acc080e7          	jalr	-1332(ra) # 80003d2c <dirlookup>
    80005268:	84aa                	mv	s1,a0
    8000526a:	c921                	beqz	a0,800052ba <create+0x94>
    iunlockput(dp);
    8000526c:	854a                	mv	a0,s2
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	842080e7          	jalr	-1982(ra) # 80003ab0 <iunlockput>
    ilock(ip);
    80005276:	8526                	mv	a0,s1
    80005278:	ffffe097          	auipc	ra,0xffffe
    8000527c:	5d6080e7          	jalr	1494(ra) # 8000384e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005280:	2981                	sext.w	s3,s3
    80005282:	4789                	li	a5,2
    80005284:	02f99463          	bne	s3,a5,800052ac <create+0x86>
    80005288:	0444d783          	lhu	a5,68(s1)
    8000528c:	37f9                	addiw	a5,a5,-2
    8000528e:	17c2                	slli	a5,a5,0x30
    80005290:	93c1                	srli	a5,a5,0x30
    80005292:	4705                	li	a4,1
    80005294:	00f76c63          	bltu	a4,a5,800052ac <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005298:	8526                	mv	a0,s1
    8000529a:	60a6                	ld	ra,72(sp)
    8000529c:	6406                	ld	s0,64(sp)
    8000529e:	74e2                	ld	s1,56(sp)
    800052a0:	7942                	ld	s2,48(sp)
    800052a2:	79a2                	ld	s3,40(sp)
    800052a4:	7a02                	ld	s4,32(sp)
    800052a6:	6ae2                	ld	s5,24(sp)
    800052a8:	6161                	addi	sp,sp,80
    800052aa:	8082                	ret
    iunlockput(ip);
    800052ac:	8526                	mv	a0,s1
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	802080e7          	jalr	-2046(ra) # 80003ab0 <iunlockput>
    return 0;
    800052b6:	4481                	li	s1,0
    800052b8:	b7c5                	j	80005298 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800052ba:	85ce                	mv	a1,s3
    800052bc:	00092503          	lw	a0,0(s2)
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	3f6080e7          	jalr	1014(ra) # 800036b6 <ialloc>
    800052c8:	84aa                	mv	s1,a0
    800052ca:	c529                	beqz	a0,80005314 <create+0xee>
  ilock(ip);
    800052cc:	ffffe097          	auipc	ra,0xffffe
    800052d0:	582080e7          	jalr	1410(ra) # 8000384e <ilock>
  ip->major = major;
    800052d4:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800052d8:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800052dc:	4785                	li	a5,1
    800052de:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800052e2:	8526                	mv	a0,s1
    800052e4:	ffffe097          	auipc	ra,0xffffe
    800052e8:	4a0080e7          	jalr	1184(ra) # 80003784 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052ec:	2981                	sext.w	s3,s3
    800052ee:	4785                	li	a5,1
    800052f0:	02f98a63          	beq	s3,a5,80005324 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800052f4:	40d0                	lw	a2,4(s1)
    800052f6:	fb040593          	addi	a1,s0,-80
    800052fa:	854a                	mv	a0,s2
    800052fc:	fffff097          	auipc	ra,0xfffff
    80005300:	c40080e7          	jalr	-960(ra) # 80003f3c <dirlink>
    80005304:	06054b63          	bltz	a0,8000537a <create+0x154>
  iunlockput(dp);
    80005308:	854a                	mv	a0,s2
    8000530a:	ffffe097          	auipc	ra,0xffffe
    8000530e:	7a6080e7          	jalr	1958(ra) # 80003ab0 <iunlockput>
  return ip;
    80005312:	b759                	j	80005298 <create+0x72>
    panic("create: ialloc");
    80005314:	00003517          	auipc	a0,0x3
    80005318:	43c50513          	addi	a0,a0,1084 # 80008750 <syscalls+0x2b0>
    8000531c:	ffffb097          	auipc	ra,0xffffb
    80005320:	23a080e7          	jalr	570(ra) # 80000556 <panic>
    dp->nlink++;  // for ".."
    80005324:	04a95783          	lhu	a5,74(s2)
    80005328:	2785                	addiw	a5,a5,1
    8000532a:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000532e:	854a                	mv	a0,s2
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	454080e7          	jalr	1108(ra) # 80003784 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005338:	40d0                	lw	a2,4(s1)
    8000533a:	00003597          	auipc	a1,0x3
    8000533e:	42658593          	addi	a1,a1,1062 # 80008760 <syscalls+0x2c0>
    80005342:	8526                	mv	a0,s1
    80005344:	fffff097          	auipc	ra,0xfffff
    80005348:	bf8080e7          	jalr	-1032(ra) # 80003f3c <dirlink>
    8000534c:	00054f63          	bltz	a0,8000536a <create+0x144>
    80005350:	00492603          	lw	a2,4(s2)
    80005354:	00003597          	auipc	a1,0x3
    80005358:	d6c58593          	addi	a1,a1,-660 # 800080c0 <digits+0x90>
    8000535c:	8526                	mv	a0,s1
    8000535e:	fffff097          	auipc	ra,0xfffff
    80005362:	bde080e7          	jalr	-1058(ra) # 80003f3c <dirlink>
    80005366:	f80557e3          	bgez	a0,800052f4 <create+0xce>
      panic("create dots");
    8000536a:	00003517          	auipc	a0,0x3
    8000536e:	3fe50513          	addi	a0,a0,1022 # 80008768 <syscalls+0x2c8>
    80005372:	ffffb097          	auipc	ra,0xffffb
    80005376:	1e4080e7          	jalr	484(ra) # 80000556 <panic>
    panic("create: dirlink");
    8000537a:	00003517          	auipc	a0,0x3
    8000537e:	3fe50513          	addi	a0,a0,1022 # 80008778 <syscalls+0x2d8>
    80005382:	ffffb097          	auipc	ra,0xffffb
    80005386:	1d4080e7          	jalr	468(ra) # 80000556 <panic>
    return 0;
    8000538a:	84aa                	mv	s1,a0
    8000538c:	b731                	j	80005298 <create+0x72>

000000008000538e <sys_dup>:
{
    8000538e:	7179                	addi	sp,sp,-48
    80005390:	f406                	sd	ra,40(sp)
    80005392:	f022                	sd	s0,32(sp)
    80005394:	ec26                	sd	s1,24(sp)
    80005396:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005398:	fd840613          	addi	a2,s0,-40
    8000539c:	4581                	li	a1,0
    8000539e:	4501                	li	a0,0
    800053a0:	00000097          	auipc	ra,0x0
    800053a4:	ddc080e7          	jalr	-548(ra) # 8000517c <argfd>
    return -1;
    800053a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053aa:	02054363          	bltz	a0,800053d0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053ae:	fd843503          	ld	a0,-40(s0)
    800053b2:	00000097          	auipc	ra,0x0
    800053b6:	e32080e7          	jalr	-462(ra) # 800051e4 <fdalloc>
    800053ba:	84aa                	mv	s1,a0
    return -1;
    800053bc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053be:	00054963          	bltz	a0,800053d0 <sys_dup+0x42>
  filedup(f);
    800053c2:	fd843503          	ld	a0,-40(s0)
    800053c6:	fffff097          	auipc	ra,0xfffff
    800053ca:	2c4080e7          	jalr	708(ra) # 8000468a <filedup>
  return fd;
    800053ce:	87a6                	mv	a5,s1
}
    800053d0:	853e                	mv	a0,a5
    800053d2:	70a2                	ld	ra,40(sp)
    800053d4:	7402                	ld	s0,32(sp)
    800053d6:	64e2                	ld	s1,24(sp)
    800053d8:	6145                	addi	sp,sp,48
    800053da:	8082                	ret

00000000800053dc <sys_read>:
{
    800053dc:	7179                	addi	sp,sp,-48
    800053de:	f406                	sd	ra,40(sp)
    800053e0:	f022                	sd	s0,32(sp)
    800053e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e4:	fe840613          	addi	a2,s0,-24
    800053e8:	4581                	li	a1,0
    800053ea:	4501                	li	a0,0
    800053ec:	00000097          	auipc	ra,0x0
    800053f0:	d90080e7          	jalr	-624(ra) # 8000517c <argfd>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	04054163          	bltz	a0,80005438 <sys_read+0x5c>
    800053fa:	fe440593          	addi	a1,s0,-28
    800053fe:	4509                	li	a0,2
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	8dc080e7          	jalr	-1828(ra) # 80002cdc <argint>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000540a:	02054763          	bltz	a0,80005438 <sys_read+0x5c>
    8000540e:	fd840593          	addi	a1,s0,-40
    80005412:	4505                	li	a0,1
    80005414:	ffffe097          	auipc	ra,0xffffe
    80005418:	8ea080e7          	jalr	-1814(ra) # 80002cfe <argaddr>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000541e:	00054d63          	bltz	a0,80005438 <sys_read+0x5c>
  return fileread(f, p, n);
    80005422:	fe442603          	lw	a2,-28(s0)
    80005426:	fd843583          	ld	a1,-40(s0)
    8000542a:	fe843503          	ld	a0,-24(s0)
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	3e8080e7          	jalr	1000(ra) # 80004816 <fileread>
    80005436:	87aa                	mv	a5,a0
}
    80005438:	853e                	mv	a0,a5
    8000543a:	70a2                	ld	ra,40(sp)
    8000543c:	7402                	ld	s0,32(sp)
    8000543e:	6145                	addi	sp,sp,48
    80005440:	8082                	ret

0000000080005442 <sys_write>:
{
    80005442:	7179                	addi	sp,sp,-48
    80005444:	f406                	sd	ra,40(sp)
    80005446:	f022                	sd	s0,32(sp)
    80005448:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000544a:	fe840613          	addi	a2,s0,-24
    8000544e:	4581                	li	a1,0
    80005450:	4501                	li	a0,0
    80005452:	00000097          	auipc	ra,0x0
    80005456:	d2a080e7          	jalr	-726(ra) # 8000517c <argfd>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545c:	04054163          	bltz	a0,8000549e <sys_write+0x5c>
    80005460:	fe440593          	addi	a1,s0,-28
    80005464:	4509                	li	a0,2
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	876080e7          	jalr	-1930(ra) # 80002cdc <argint>
    return -1;
    8000546e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005470:	02054763          	bltz	a0,8000549e <sys_write+0x5c>
    80005474:	fd840593          	addi	a1,s0,-40
    80005478:	4505                	li	a0,1
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	884080e7          	jalr	-1916(ra) # 80002cfe <argaddr>
    return -1;
    80005482:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005484:	00054d63          	bltz	a0,8000549e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005488:	fe442603          	lw	a2,-28(s0)
    8000548c:	fd843583          	ld	a1,-40(s0)
    80005490:	fe843503          	ld	a0,-24(s0)
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	444080e7          	jalr	1092(ra) # 800048d8 <filewrite>
    8000549c:	87aa                	mv	a5,a0
}
    8000549e:	853e                	mv	a0,a5
    800054a0:	70a2                	ld	ra,40(sp)
    800054a2:	7402                	ld	s0,32(sp)
    800054a4:	6145                	addi	sp,sp,48
    800054a6:	8082                	ret

00000000800054a8 <sys_close>:
{
    800054a8:	1101                	addi	sp,sp,-32
    800054aa:	ec06                	sd	ra,24(sp)
    800054ac:	e822                	sd	s0,16(sp)
    800054ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054b0:	fe040613          	addi	a2,s0,-32
    800054b4:	fec40593          	addi	a1,s0,-20
    800054b8:	4501                	li	a0,0
    800054ba:	00000097          	auipc	ra,0x0
    800054be:	cc2080e7          	jalr	-830(ra) # 8000517c <argfd>
    return -1;
    800054c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054c4:	02054463          	bltz	a0,800054ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054c8:	ffffc097          	auipc	ra,0xffffc
    800054cc:	63e080e7          	jalr	1598(ra) # 80001b06 <myproc>
    800054d0:	fec42783          	lw	a5,-20(s0)
    800054d4:	07e9                	addi	a5,a5,26
    800054d6:	078e                	slli	a5,a5,0x3
    800054d8:	97aa                	add	a5,a5,a0
    800054da:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054de:	fe043503          	ld	a0,-32(s0)
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	1fa080e7          	jalr	506(ra) # 800046dc <fileclose>
  return 0;
    800054ea:	4781                	li	a5,0
}
    800054ec:	853e                	mv	a0,a5
    800054ee:	60e2                	ld	ra,24(sp)
    800054f0:	6442                	ld	s0,16(sp)
    800054f2:	6105                	addi	sp,sp,32
    800054f4:	8082                	ret

00000000800054f6 <sys_fstat>:
{
    800054f6:	1101                	addi	sp,sp,-32
    800054f8:	ec06                	sd	ra,24(sp)
    800054fa:	e822                	sd	s0,16(sp)
    800054fc:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800054fe:	fe840613          	addi	a2,s0,-24
    80005502:	4581                	li	a1,0
    80005504:	4501                	li	a0,0
    80005506:	00000097          	auipc	ra,0x0
    8000550a:	c76080e7          	jalr	-906(ra) # 8000517c <argfd>
    return -1;
    8000550e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005510:	02054563          	bltz	a0,8000553a <sys_fstat+0x44>
    80005514:	fe040593          	addi	a1,s0,-32
    80005518:	4505                	li	a0,1
    8000551a:	ffffd097          	auipc	ra,0xffffd
    8000551e:	7e4080e7          	jalr	2020(ra) # 80002cfe <argaddr>
    return -1;
    80005522:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005524:	00054b63          	bltz	a0,8000553a <sys_fstat+0x44>
  return filestat(f, st);
    80005528:	fe043583          	ld	a1,-32(s0)
    8000552c:	fe843503          	ld	a0,-24(s0)
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	274080e7          	jalr	628(ra) # 800047a4 <filestat>
    80005538:	87aa                	mv	a5,a0
}
    8000553a:	853e                	mv	a0,a5
    8000553c:	60e2                	ld	ra,24(sp)
    8000553e:	6442                	ld	s0,16(sp)
    80005540:	6105                	addi	sp,sp,32
    80005542:	8082                	ret

0000000080005544 <sys_link>:
{
    80005544:	7169                	addi	sp,sp,-304
    80005546:	f606                	sd	ra,296(sp)
    80005548:	f222                	sd	s0,288(sp)
    8000554a:	ee26                	sd	s1,280(sp)
    8000554c:	ea4a                	sd	s2,272(sp)
    8000554e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005550:	08000613          	li	a2,128
    80005554:	ed040593          	addi	a1,s0,-304
    80005558:	4501                	li	a0,0
    8000555a:	ffffd097          	auipc	ra,0xffffd
    8000555e:	7c6080e7          	jalr	1990(ra) # 80002d20 <argstr>
    return -1;
    80005562:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005564:	10054e63          	bltz	a0,80005680 <sys_link+0x13c>
    80005568:	08000613          	li	a2,128
    8000556c:	f5040593          	addi	a1,s0,-176
    80005570:	4505                	li	a0,1
    80005572:	ffffd097          	auipc	ra,0xffffd
    80005576:	7ae080e7          	jalr	1966(ra) # 80002d20 <argstr>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557c:	10054263          	bltz	a0,80005680 <sys_link+0x13c>
  begin_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	c8a080e7          	jalr	-886(ra) # 8000420a <begin_op>
  if((ip = namei(old)) == 0){
    80005588:	ed040513          	addi	a0,s0,-304
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	a72080e7          	jalr	-1422(ra) # 80003ffe <namei>
    80005594:	84aa                	mv	s1,a0
    80005596:	c551                	beqz	a0,80005622 <sys_link+0xde>
  ilock(ip);
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	2b6080e7          	jalr	694(ra) # 8000384e <ilock>
  if(ip->type == T_DIR){
    800055a0:	04449703          	lh	a4,68(s1)
    800055a4:	4785                	li	a5,1
    800055a6:	08f70463          	beq	a4,a5,8000562e <sys_link+0xea>
  ip->nlink++;
    800055aa:	04a4d783          	lhu	a5,74(s1)
    800055ae:	2785                	addiw	a5,a5,1
    800055b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b4:	8526                	mv	a0,s1
    800055b6:	ffffe097          	auipc	ra,0xffffe
    800055ba:	1ce080e7          	jalr	462(ra) # 80003784 <iupdate>
  iunlock(ip);
    800055be:	8526                	mv	a0,s1
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	350080e7          	jalr	848(ra) # 80003910 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055c8:	fd040593          	addi	a1,s0,-48
    800055cc:	f5040513          	addi	a0,s0,-176
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	a4c080e7          	jalr	-1460(ra) # 8000401c <nameiparent>
    800055d8:	892a                	mv	s2,a0
    800055da:	c935                	beqz	a0,8000564e <sys_link+0x10a>
  ilock(dp);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	272080e7          	jalr	626(ra) # 8000384e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055e4:	00092703          	lw	a4,0(s2)
    800055e8:	409c                	lw	a5,0(s1)
    800055ea:	04f71d63          	bne	a4,a5,80005644 <sys_link+0x100>
    800055ee:	40d0                	lw	a2,4(s1)
    800055f0:	fd040593          	addi	a1,s0,-48
    800055f4:	854a                	mv	a0,s2
    800055f6:	fffff097          	auipc	ra,0xfffff
    800055fa:	946080e7          	jalr	-1722(ra) # 80003f3c <dirlink>
    800055fe:	04054363          	bltz	a0,80005644 <sys_link+0x100>
  iunlockput(dp);
    80005602:	854a                	mv	a0,s2
    80005604:	ffffe097          	auipc	ra,0xffffe
    80005608:	4ac080e7          	jalr	1196(ra) # 80003ab0 <iunlockput>
  iput(ip);
    8000560c:	8526                	mv	a0,s1
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	3fa080e7          	jalr	1018(ra) # 80003a08 <iput>
  end_op();
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	c74080e7          	jalr	-908(ra) # 8000428a <end_op>
  return 0;
    8000561e:	4781                	li	a5,0
    80005620:	a085                	j	80005680 <sys_link+0x13c>
    end_op();
    80005622:	fffff097          	auipc	ra,0xfffff
    80005626:	c68080e7          	jalr	-920(ra) # 8000428a <end_op>
    return -1;
    8000562a:	57fd                	li	a5,-1
    8000562c:	a891                	j	80005680 <sys_link+0x13c>
    iunlockput(ip);
    8000562e:	8526                	mv	a0,s1
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	480080e7          	jalr	1152(ra) # 80003ab0 <iunlockput>
    end_op();
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	c52080e7          	jalr	-942(ra) # 8000428a <end_op>
    return -1;
    80005640:	57fd                	li	a5,-1
    80005642:	a83d                	j	80005680 <sys_link+0x13c>
    iunlockput(dp);
    80005644:	854a                	mv	a0,s2
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	46a080e7          	jalr	1130(ra) # 80003ab0 <iunlockput>
  ilock(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	1fe080e7          	jalr	510(ra) # 8000384e <ilock>
  ip->nlink--;
    80005658:	04a4d783          	lhu	a5,74(s1)
    8000565c:	37fd                	addiw	a5,a5,-1
    8000565e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	120080e7          	jalr	288(ra) # 80003784 <iupdate>
  iunlockput(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	442080e7          	jalr	1090(ra) # 80003ab0 <iunlockput>
  end_op();
    80005676:	fffff097          	auipc	ra,0xfffff
    8000567a:	c14080e7          	jalr	-1004(ra) # 8000428a <end_op>
  return -1;
    8000567e:	57fd                	li	a5,-1
}
    80005680:	853e                	mv	a0,a5
    80005682:	70b2                	ld	ra,296(sp)
    80005684:	7412                	ld	s0,288(sp)
    80005686:	64f2                	ld	s1,280(sp)
    80005688:	6952                	ld	s2,272(sp)
    8000568a:	6155                	addi	sp,sp,304
    8000568c:	8082                	ret

000000008000568e <sys_unlink>:
{
    8000568e:	7151                	addi	sp,sp,-240
    80005690:	f586                	sd	ra,232(sp)
    80005692:	f1a2                	sd	s0,224(sp)
    80005694:	eda6                	sd	s1,216(sp)
    80005696:	e9ca                	sd	s2,208(sp)
    80005698:	e5ce                	sd	s3,200(sp)
    8000569a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000569c:	08000613          	li	a2,128
    800056a0:	f3040593          	addi	a1,s0,-208
    800056a4:	4501                	li	a0,0
    800056a6:	ffffd097          	auipc	ra,0xffffd
    800056aa:	67a080e7          	jalr	1658(ra) # 80002d20 <argstr>
    800056ae:	18054163          	bltz	a0,80005830 <sys_unlink+0x1a2>
  begin_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	b58080e7          	jalr	-1192(ra) # 8000420a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056ba:	fb040593          	addi	a1,s0,-80
    800056be:	f3040513          	addi	a0,s0,-208
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	95a080e7          	jalr	-1702(ra) # 8000401c <nameiparent>
    800056ca:	84aa                	mv	s1,a0
    800056cc:	c979                	beqz	a0,800057a2 <sys_unlink+0x114>
  ilock(dp);
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	180080e7          	jalr	384(ra) # 8000384e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056d6:	00003597          	auipc	a1,0x3
    800056da:	08a58593          	addi	a1,a1,138 # 80008760 <syscalls+0x2c0>
    800056de:	fb040513          	addi	a0,s0,-80
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	630080e7          	jalr	1584(ra) # 80003d12 <namecmp>
    800056ea:	14050a63          	beqz	a0,8000583e <sys_unlink+0x1b0>
    800056ee:	00003597          	auipc	a1,0x3
    800056f2:	9d258593          	addi	a1,a1,-1582 # 800080c0 <digits+0x90>
    800056f6:	fb040513          	addi	a0,s0,-80
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	618080e7          	jalr	1560(ra) # 80003d12 <namecmp>
    80005702:	12050e63          	beqz	a0,8000583e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005706:	f2c40613          	addi	a2,s0,-212
    8000570a:	fb040593          	addi	a1,s0,-80
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	61c080e7          	jalr	1564(ra) # 80003d2c <dirlookup>
    80005718:	892a                	mv	s2,a0
    8000571a:	12050263          	beqz	a0,8000583e <sys_unlink+0x1b0>
  ilock(ip);
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	130080e7          	jalr	304(ra) # 8000384e <ilock>
  if(ip->nlink < 1)
    80005726:	04a91783          	lh	a5,74(s2)
    8000572a:	08f05263          	blez	a5,800057ae <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000572e:	04491703          	lh	a4,68(s2)
    80005732:	4785                	li	a5,1
    80005734:	08f70563          	beq	a4,a5,800057be <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005738:	4641                	li	a2,16
    8000573a:	4581                	li	a1,0
    8000573c:	fc040513          	addi	a0,s0,-64
    80005740:	ffffb097          	auipc	ra,0xffffb
    80005744:	5da080e7          	jalr	1498(ra) # 80000d1a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005748:	4741                	li	a4,16
    8000574a:	f2c42683          	lw	a3,-212(s0)
    8000574e:	fc040613          	addi	a2,s0,-64
    80005752:	4581                	li	a1,0
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	4a2080e7          	jalr	1186(ra) # 80003bf8 <writei>
    8000575e:	47c1                	li	a5,16
    80005760:	0af51563          	bne	a0,a5,8000580a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005764:	04491703          	lh	a4,68(s2)
    80005768:	4785                	li	a5,1
    8000576a:	0af70863          	beq	a4,a5,8000581a <sys_unlink+0x18c>
  iunlockput(dp);
    8000576e:	8526                	mv	a0,s1
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	340080e7          	jalr	832(ra) # 80003ab0 <iunlockput>
  ip->nlink--;
    80005778:	04a95783          	lhu	a5,74(s2)
    8000577c:	37fd                	addiw	a5,a5,-1
    8000577e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005782:	854a                	mv	a0,s2
    80005784:	ffffe097          	auipc	ra,0xffffe
    80005788:	000080e7          	jalr	ra # 80003784 <iupdate>
  iunlockput(ip);
    8000578c:	854a                	mv	a0,s2
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	322080e7          	jalr	802(ra) # 80003ab0 <iunlockput>
  end_op();
    80005796:	fffff097          	auipc	ra,0xfffff
    8000579a:	af4080e7          	jalr	-1292(ra) # 8000428a <end_op>
  return 0;
    8000579e:	4501                	li	a0,0
    800057a0:	a84d                	j	80005852 <sys_unlink+0x1c4>
    end_op();
    800057a2:	fffff097          	auipc	ra,0xfffff
    800057a6:	ae8080e7          	jalr	-1304(ra) # 8000428a <end_op>
    return -1;
    800057aa:	557d                	li	a0,-1
    800057ac:	a05d                	j	80005852 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057ae:	00003517          	auipc	a0,0x3
    800057b2:	fda50513          	addi	a0,a0,-38 # 80008788 <syscalls+0x2e8>
    800057b6:	ffffb097          	auipc	ra,0xffffb
    800057ba:	da0080e7          	jalr	-608(ra) # 80000556 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057be:	04c92703          	lw	a4,76(s2)
    800057c2:	02000793          	li	a5,32
    800057c6:	f6e7f9e3          	bgeu	a5,a4,80005738 <sys_unlink+0xaa>
    800057ca:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ce:	4741                	li	a4,16
    800057d0:	86ce                	mv	a3,s3
    800057d2:	f1840613          	addi	a2,s0,-232
    800057d6:	4581                	li	a1,0
    800057d8:	854a                	mv	a0,s2
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	328080e7          	jalr	808(ra) # 80003b02 <readi>
    800057e2:	47c1                	li	a5,16
    800057e4:	00f51b63          	bne	a0,a5,800057fa <sys_unlink+0x16c>
    if(de.inum != 0)
    800057e8:	f1845783          	lhu	a5,-232(s0)
    800057ec:	e7a1                	bnez	a5,80005834 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057ee:	29c1                	addiw	s3,s3,16
    800057f0:	04c92783          	lw	a5,76(s2)
    800057f4:	fcf9ede3          	bltu	s3,a5,800057ce <sys_unlink+0x140>
    800057f8:	b781                	j	80005738 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057fa:	00003517          	auipc	a0,0x3
    800057fe:	fa650513          	addi	a0,a0,-90 # 800087a0 <syscalls+0x300>
    80005802:	ffffb097          	auipc	ra,0xffffb
    80005806:	d54080e7          	jalr	-684(ra) # 80000556 <panic>
    panic("unlink: writei");
    8000580a:	00003517          	auipc	a0,0x3
    8000580e:	fae50513          	addi	a0,a0,-82 # 800087b8 <syscalls+0x318>
    80005812:	ffffb097          	auipc	ra,0xffffb
    80005816:	d44080e7          	jalr	-700(ra) # 80000556 <panic>
    dp->nlink--;
    8000581a:	04a4d783          	lhu	a5,74(s1)
    8000581e:	37fd                	addiw	a5,a5,-1
    80005820:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	f5e080e7          	jalr	-162(ra) # 80003784 <iupdate>
    8000582e:	b781                	j	8000576e <sys_unlink+0xe0>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	a005                	j	80005852 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005834:	854a                	mv	a0,s2
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	27a080e7          	jalr	634(ra) # 80003ab0 <iunlockput>
  iunlockput(dp);
    8000583e:	8526                	mv	a0,s1
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	270080e7          	jalr	624(ra) # 80003ab0 <iunlockput>
  end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	a42080e7          	jalr	-1470(ra) # 8000428a <end_op>
  return -1;
    80005850:	557d                	li	a0,-1
}
    80005852:	70ae                	ld	ra,232(sp)
    80005854:	740e                	ld	s0,224(sp)
    80005856:	64ee                	ld	s1,216(sp)
    80005858:	694e                	ld	s2,208(sp)
    8000585a:	69ae                	ld	s3,200(sp)
    8000585c:	616d                	addi	sp,sp,240
    8000585e:	8082                	ret

0000000080005860 <sys_open>:

uint64
sys_open(void)
{
    80005860:	7131                	addi	sp,sp,-192
    80005862:	fd06                	sd	ra,184(sp)
    80005864:	f922                	sd	s0,176(sp)
    80005866:	f526                	sd	s1,168(sp)
    80005868:	f14a                	sd	s2,160(sp)
    8000586a:	ed4e                	sd	s3,152(sp)
    8000586c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000586e:	08000613          	li	a2,128
    80005872:	f5040593          	addi	a1,s0,-176
    80005876:	4501                	li	a0,0
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	4a8080e7          	jalr	1192(ra) # 80002d20 <argstr>
    return -1;
    80005880:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005882:	0c054163          	bltz	a0,80005944 <sys_open+0xe4>
    80005886:	f4c40593          	addi	a1,s0,-180
    8000588a:	4505                	li	a0,1
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	450080e7          	jalr	1104(ra) # 80002cdc <argint>
    80005894:	0a054863          	bltz	a0,80005944 <sys_open+0xe4>

  begin_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	972080e7          	jalr	-1678(ra) # 8000420a <begin_op>

  if(omode & O_CREATE){
    800058a0:	f4c42783          	lw	a5,-180(s0)
    800058a4:	2007f793          	andi	a5,a5,512
    800058a8:	cbdd                	beqz	a5,8000595e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058aa:	4681                	li	a3,0
    800058ac:	4601                	li	a2,0
    800058ae:	4589                	li	a1,2
    800058b0:	f5040513          	addi	a0,s0,-176
    800058b4:	00000097          	auipc	ra,0x0
    800058b8:	972080e7          	jalr	-1678(ra) # 80005226 <create>
    800058bc:	892a                	mv	s2,a0
    if(ip == 0){
    800058be:	c959                	beqz	a0,80005954 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058c0:	04491703          	lh	a4,68(s2)
    800058c4:	478d                	li	a5,3
    800058c6:	00f71763          	bne	a4,a5,800058d4 <sys_open+0x74>
    800058ca:	04695703          	lhu	a4,70(s2)
    800058ce:	47a5                	li	a5,9
    800058d0:	0ce7ec63          	bltu	a5,a4,800059a8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	d4c080e7          	jalr	-692(ra) # 80004620 <filealloc>
    800058dc:	89aa                	mv	s3,a0
    800058de:	10050263          	beqz	a0,800059e2 <sys_open+0x182>
    800058e2:	00000097          	auipc	ra,0x0
    800058e6:	902080e7          	jalr	-1790(ra) # 800051e4 <fdalloc>
    800058ea:	84aa                	mv	s1,a0
    800058ec:	0e054663          	bltz	a0,800059d8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058f0:	04491703          	lh	a4,68(s2)
    800058f4:	478d                	li	a5,3
    800058f6:	0cf70463          	beq	a4,a5,800059be <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058fa:	4789                	li	a5,2
    800058fc:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005900:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005904:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005908:	f4c42783          	lw	a5,-180(s0)
    8000590c:	0017c713          	xori	a4,a5,1
    80005910:	8b05                	andi	a4,a4,1
    80005912:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005916:	0037f713          	andi	a4,a5,3
    8000591a:	00e03733          	snez	a4,a4
    8000591e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005922:	4007f793          	andi	a5,a5,1024
    80005926:	c791                	beqz	a5,80005932 <sys_open+0xd2>
    80005928:	04491703          	lh	a4,68(s2)
    8000592c:	4789                	li	a5,2
    8000592e:	08f70f63          	beq	a4,a5,800059cc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005932:	854a                	mv	a0,s2
    80005934:	ffffe097          	auipc	ra,0xffffe
    80005938:	fdc080e7          	jalr	-36(ra) # 80003910 <iunlock>
  end_op();
    8000593c:	fffff097          	auipc	ra,0xfffff
    80005940:	94e080e7          	jalr	-1714(ra) # 8000428a <end_op>

  return fd;
}
    80005944:	8526                	mv	a0,s1
    80005946:	70ea                	ld	ra,184(sp)
    80005948:	744a                	ld	s0,176(sp)
    8000594a:	74aa                	ld	s1,168(sp)
    8000594c:	790a                	ld	s2,160(sp)
    8000594e:	69ea                	ld	s3,152(sp)
    80005950:	6129                	addi	sp,sp,192
    80005952:	8082                	ret
      end_op();
    80005954:	fffff097          	auipc	ra,0xfffff
    80005958:	936080e7          	jalr	-1738(ra) # 8000428a <end_op>
      return -1;
    8000595c:	b7e5                	j	80005944 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000595e:	f5040513          	addi	a0,s0,-176
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	69c080e7          	jalr	1692(ra) # 80003ffe <namei>
    8000596a:	892a                	mv	s2,a0
    8000596c:	c905                	beqz	a0,8000599c <sys_open+0x13c>
    ilock(ip);
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	ee0080e7          	jalr	-288(ra) # 8000384e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005976:	04491703          	lh	a4,68(s2)
    8000597a:	4785                	li	a5,1
    8000597c:	f4f712e3          	bne	a4,a5,800058c0 <sys_open+0x60>
    80005980:	f4c42783          	lw	a5,-180(s0)
    80005984:	dba1                	beqz	a5,800058d4 <sys_open+0x74>
      iunlockput(ip);
    80005986:	854a                	mv	a0,s2
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	128080e7          	jalr	296(ra) # 80003ab0 <iunlockput>
      end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	8fa080e7          	jalr	-1798(ra) # 8000428a <end_op>
      return -1;
    80005998:	54fd                	li	s1,-1
    8000599a:	b76d                	j	80005944 <sys_open+0xe4>
      end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	8ee080e7          	jalr	-1810(ra) # 8000428a <end_op>
      return -1;
    800059a4:	54fd                	li	s1,-1
    800059a6:	bf79                	j	80005944 <sys_open+0xe4>
    iunlockput(ip);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	106080e7          	jalr	262(ra) # 80003ab0 <iunlockput>
    end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	8d8080e7          	jalr	-1832(ra) # 8000428a <end_op>
    return -1;
    800059ba:	54fd                	li	s1,-1
    800059bc:	b761                	j	80005944 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059be:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059c2:	04691783          	lh	a5,70(s2)
    800059c6:	02f99223          	sh	a5,36(s3)
    800059ca:	bf2d                	j	80005904 <sys_open+0xa4>
    itrunc(ip);
    800059cc:	854a                	mv	a0,s2
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	f8e080e7          	jalr	-114(ra) # 8000395c <itrunc>
    800059d6:	bfb1                	j	80005932 <sys_open+0xd2>
      fileclose(f);
    800059d8:	854e                	mv	a0,s3
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	d02080e7          	jalr	-766(ra) # 800046dc <fileclose>
    iunlockput(ip);
    800059e2:	854a                	mv	a0,s2
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	0cc080e7          	jalr	204(ra) # 80003ab0 <iunlockput>
    end_op();
    800059ec:	fffff097          	auipc	ra,0xfffff
    800059f0:	89e080e7          	jalr	-1890(ra) # 8000428a <end_op>
    return -1;
    800059f4:	54fd                	li	s1,-1
    800059f6:	b7b9                	j	80005944 <sys_open+0xe4>

00000000800059f8 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059f8:	7175                	addi	sp,sp,-144
    800059fa:	e506                	sd	ra,136(sp)
    800059fc:	e122                	sd	s0,128(sp)
    800059fe:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	80a080e7          	jalr	-2038(ra) # 8000420a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a08:	08000613          	li	a2,128
    80005a0c:	f7040593          	addi	a1,s0,-144
    80005a10:	4501                	li	a0,0
    80005a12:	ffffd097          	auipc	ra,0xffffd
    80005a16:	30e080e7          	jalr	782(ra) # 80002d20 <argstr>
    80005a1a:	02054963          	bltz	a0,80005a4c <sys_mkdir+0x54>
    80005a1e:	4681                	li	a3,0
    80005a20:	4601                	li	a2,0
    80005a22:	4585                	li	a1,1
    80005a24:	f7040513          	addi	a0,s0,-144
    80005a28:	fffff097          	auipc	ra,0xfffff
    80005a2c:	7fe080e7          	jalr	2046(ra) # 80005226 <create>
    80005a30:	cd11                	beqz	a0,80005a4c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	07e080e7          	jalr	126(ra) # 80003ab0 <iunlockput>
  end_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	850080e7          	jalr	-1968(ra) # 8000428a <end_op>
  return 0;
    80005a42:	4501                	li	a0,0
}
    80005a44:	60aa                	ld	ra,136(sp)
    80005a46:	640a                	ld	s0,128(sp)
    80005a48:	6149                	addi	sp,sp,144
    80005a4a:	8082                	ret
    end_op();
    80005a4c:	fffff097          	auipc	ra,0xfffff
    80005a50:	83e080e7          	jalr	-1986(ra) # 8000428a <end_op>
    return -1;
    80005a54:	557d                	li	a0,-1
    80005a56:	b7fd                	j	80005a44 <sys_mkdir+0x4c>

0000000080005a58 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a58:	7135                	addi	sp,sp,-160
    80005a5a:	ed06                	sd	ra,152(sp)
    80005a5c:	e922                	sd	s0,144(sp)
    80005a5e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	7aa080e7          	jalr	1962(ra) # 8000420a <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a68:	08000613          	li	a2,128
    80005a6c:	f7040593          	addi	a1,s0,-144
    80005a70:	4501                	li	a0,0
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	2ae080e7          	jalr	686(ra) # 80002d20 <argstr>
    80005a7a:	04054a63          	bltz	a0,80005ace <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005a7e:	f6c40593          	addi	a1,s0,-148
    80005a82:	4505                	li	a0,1
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	258080e7          	jalr	600(ra) # 80002cdc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a8c:	04054163          	bltz	a0,80005ace <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a90:	f6840593          	addi	a1,s0,-152
    80005a94:	4509                	li	a0,2
    80005a96:	ffffd097          	auipc	ra,0xffffd
    80005a9a:	246080e7          	jalr	582(ra) # 80002cdc <argint>
     argint(1, &major) < 0 ||
    80005a9e:	02054863          	bltz	a0,80005ace <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005aa2:	f6841683          	lh	a3,-152(s0)
    80005aa6:	f6c41603          	lh	a2,-148(s0)
    80005aaa:	458d                	li	a1,3
    80005aac:	f7040513          	addi	a0,s0,-144
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	776080e7          	jalr	1910(ra) # 80005226 <create>
     argint(2, &minor) < 0 ||
    80005ab8:	c919                	beqz	a0,80005ace <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	ff6080e7          	jalr	-10(ra) # 80003ab0 <iunlockput>
  end_op();
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	7c8080e7          	jalr	1992(ra) # 8000428a <end_op>
  return 0;
    80005aca:	4501                	li	a0,0
    80005acc:	a031                	j	80005ad8 <sys_mknod+0x80>
    end_op();
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	7bc080e7          	jalr	1980(ra) # 8000428a <end_op>
    return -1;
    80005ad6:	557d                	li	a0,-1
}
    80005ad8:	60ea                	ld	ra,152(sp)
    80005ada:	644a                	ld	s0,144(sp)
    80005adc:	610d                	addi	sp,sp,160
    80005ade:	8082                	ret

0000000080005ae0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ae0:	7135                	addi	sp,sp,-160
    80005ae2:	ed06                	sd	ra,152(sp)
    80005ae4:	e922                	sd	s0,144(sp)
    80005ae6:	e526                	sd	s1,136(sp)
    80005ae8:	e14a                	sd	s2,128(sp)
    80005aea:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aec:	ffffc097          	auipc	ra,0xffffc
    80005af0:	01a080e7          	jalr	26(ra) # 80001b06 <myproc>
    80005af4:	892a                	mv	s2,a0
  
  begin_op();
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	714080e7          	jalr	1812(ra) # 8000420a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005afe:	08000613          	li	a2,128
    80005b02:	f6040593          	addi	a1,s0,-160
    80005b06:	4501                	li	a0,0
    80005b08:	ffffd097          	auipc	ra,0xffffd
    80005b0c:	218080e7          	jalr	536(ra) # 80002d20 <argstr>
    80005b10:	04054b63          	bltz	a0,80005b66 <sys_chdir+0x86>
    80005b14:	f6040513          	addi	a0,s0,-160
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	4e6080e7          	jalr	1254(ra) # 80003ffe <namei>
    80005b20:	84aa                	mv	s1,a0
    80005b22:	c131                	beqz	a0,80005b66 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	d2a080e7          	jalr	-726(ra) # 8000384e <ilock>
  if(ip->type != T_DIR){
    80005b2c:	04449703          	lh	a4,68(s1)
    80005b30:	4785                	li	a5,1
    80005b32:	04f71063          	bne	a4,a5,80005b72 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b36:	8526                	mv	a0,s1
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	dd8080e7          	jalr	-552(ra) # 80003910 <iunlock>
  iput(p->cwd);
    80005b40:	15093503          	ld	a0,336(s2)
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	ec4080e7          	jalr	-316(ra) # 80003a08 <iput>
  end_op();
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	73e080e7          	jalr	1854(ra) # 8000428a <end_op>
  p->cwd = ip;
    80005b54:	14993823          	sd	s1,336(s2)
  return 0;
    80005b58:	4501                	li	a0,0
}
    80005b5a:	60ea                	ld	ra,152(sp)
    80005b5c:	644a                	ld	s0,144(sp)
    80005b5e:	64aa                	ld	s1,136(sp)
    80005b60:	690a                	ld	s2,128(sp)
    80005b62:	610d                	addi	sp,sp,160
    80005b64:	8082                	ret
    end_op();
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	724080e7          	jalr	1828(ra) # 8000428a <end_op>
    return -1;
    80005b6e:	557d                	li	a0,-1
    80005b70:	b7ed                	j	80005b5a <sys_chdir+0x7a>
    iunlockput(ip);
    80005b72:	8526                	mv	a0,s1
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	f3c080e7          	jalr	-196(ra) # 80003ab0 <iunlockput>
    end_op();
    80005b7c:	ffffe097          	auipc	ra,0xffffe
    80005b80:	70e080e7          	jalr	1806(ra) # 8000428a <end_op>
    return -1;
    80005b84:	557d                	li	a0,-1
    80005b86:	bfd1                	j	80005b5a <sys_chdir+0x7a>

0000000080005b88 <sys_exec>:

uint64
sys_exec(void)
{
    80005b88:	7145                	addi	sp,sp,-464
    80005b8a:	e786                	sd	ra,456(sp)
    80005b8c:	e3a2                	sd	s0,448(sp)
    80005b8e:	ff26                	sd	s1,440(sp)
    80005b90:	fb4a                	sd	s2,432(sp)
    80005b92:	f74e                	sd	s3,424(sp)
    80005b94:	f352                	sd	s4,416(sp)
    80005b96:	ef56                	sd	s5,408(sp)
    80005b98:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b9a:	08000613          	li	a2,128
    80005b9e:	f4040593          	addi	a1,s0,-192
    80005ba2:	4501                	li	a0,0
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	17c080e7          	jalr	380(ra) # 80002d20 <argstr>
    return -1;
    80005bac:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005bae:	0c054a63          	bltz	a0,80005c82 <sys_exec+0xfa>
    80005bb2:	e3840593          	addi	a1,s0,-456
    80005bb6:	4505                	li	a0,1
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	146080e7          	jalr	326(ra) # 80002cfe <argaddr>
    80005bc0:	0c054163          	bltz	a0,80005c82 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bc4:	10000613          	li	a2,256
    80005bc8:	4581                	li	a1,0
    80005bca:	e4040513          	addi	a0,s0,-448
    80005bce:	ffffb097          	auipc	ra,0xffffb
    80005bd2:	14c080e7          	jalr	332(ra) # 80000d1a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bd6:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bda:	89a6                	mv	s3,s1
    80005bdc:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bde:	02000a13          	li	s4,32
    80005be2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005be6:	00391513          	slli	a0,s2,0x3
    80005bea:	e3040593          	addi	a1,s0,-464
    80005bee:	e3843783          	ld	a5,-456(s0)
    80005bf2:	953e                	add	a0,a0,a5
    80005bf4:	ffffd097          	auipc	ra,0xffffd
    80005bf8:	04e080e7          	jalr	78(ra) # 80002c42 <fetchaddr>
    80005bfc:	02054a63          	bltz	a0,80005c30 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c00:	e3043783          	ld	a5,-464(s0)
    80005c04:	c3b9                	beqz	a5,80005c4a <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c06:	ffffb097          	auipc	ra,0xffffb
    80005c0a:	f28080e7          	jalr	-216(ra) # 80000b2e <kalloc>
    80005c0e:	85aa                	mv	a1,a0
    80005c10:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c14:	cd11                	beqz	a0,80005c30 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c16:	6605                	lui	a2,0x1
    80005c18:	e3043503          	ld	a0,-464(s0)
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	078080e7          	jalr	120(ra) # 80002c94 <fetchstr>
    80005c24:	00054663          	bltz	a0,80005c30 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005c28:	0905                	addi	s2,s2,1
    80005c2a:	09a1                	addi	s3,s3,8
    80005c2c:	fb491be3          	bne	s2,s4,80005be2 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c30:	10048913          	addi	s2,s1,256
    80005c34:	6088                	ld	a0,0(s1)
    80005c36:	c529                	beqz	a0,80005c80 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c38:	ffffb097          	auipc	ra,0xffffb
    80005c3c:	dfa080e7          	jalr	-518(ra) # 80000a32 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c40:	04a1                	addi	s1,s1,8
    80005c42:	ff2499e3          	bne	s1,s2,80005c34 <sys_exec+0xac>
  return -1;
    80005c46:	597d                	li	s2,-1
    80005c48:	a82d                	j	80005c82 <sys_exec+0xfa>
      argv[i] = 0;
    80005c4a:	0a8e                	slli	s5,s5,0x3
    80005c4c:	fc040793          	addi	a5,s0,-64
    80005c50:	9abe                	add	s5,s5,a5
    80005c52:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c56:	e4040593          	addi	a1,s0,-448
    80005c5a:	f4040513          	addi	a0,s0,-192
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	12e080e7          	jalr	302(ra) # 80004d8c <exec>
    80005c66:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c68:	10048993          	addi	s3,s1,256
    80005c6c:	6088                	ld	a0,0(s1)
    80005c6e:	c911                	beqz	a0,80005c82 <sys_exec+0xfa>
    kfree(argv[i]);
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	dc2080e7          	jalr	-574(ra) # 80000a32 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c78:	04a1                	addi	s1,s1,8
    80005c7a:	ff3499e3          	bne	s1,s3,80005c6c <sys_exec+0xe4>
    80005c7e:	a011                	j	80005c82 <sys_exec+0xfa>
  return -1;
    80005c80:	597d                	li	s2,-1
}
    80005c82:	854a                	mv	a0,s2
    80005c84:	60be                	ld	ra,456(sp)
    80005c86:	641e                	ld	s0,448(sp)
    80005c88:	74fa                	ld	s1,440(sp)
    80005c8a:	795a                	ld	s2,432(sp)
    80005c8c:	79ba                	ld	s3,424(sp)
    80005c8e:	7a1a                	ld	s4,416(sp)
    80005c90:	6afa                	ld	s5,408(sp)
    80005c92:	6179                	addi	sp,sp,464
    80005c94:	8082                	ret

0000000080005c96 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c96:	7139                	addi	sp,sp,-64
    80005c98:	fc06                	sd	ra,56(sp)
    80005c9a:	f822                	sd	s0,48(sp)
    80005c9c:	f426                	sd	s1,40(sp)
    80005c9e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ca0:	ffffc097          	auipc	ra,0xffffc
    80005ca4:	e66080e7          	jalr	-410(ra) # 80001b06 <myproc>
    80005ca8:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005caa:	fd840593          	addi	a1,s0,-40
    80005cae:	4501                	li	a0,0
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	04e080e7          	jalr	78(ra) # 80002cfe <argaddr>
    return -1;
    80005cb8:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005cba:	0e054063          	bltz	a0,80005d9a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005cbe:	fc840593          	addi	a1,s0,-56
    80005cc2:	fd040513          	addi	a0,s0,-48
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	d6c080e7          	jalr	-660(ra) # 80004a32 <pipealloc>
    return -1;
    80005cce:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cd0:	0c054563          	bltz	a0,80005d9a <sys_pipe+0x104>
  fd0 = -1;
    80005cd4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cd8:	fd043503          	ld	a0,-48(s0)
    80005cdc:	fffff097          	auipc	ra,0xfffff
    80005ce0:	508080e7          	jalr	1288(ra) # 800051e4 <fdalloc>
    80005ce4:	fca42223          	sw	a0,-60(s0)
    80005ce8:	08054c63          	bltz	a0,80005d80 <sys_pipe+0xea>
    80005cec:	fc843503          	ld	a0,-56(s0)
    80005cf0:	fffff097          	auipc	ra,0xfffff
    80005cf4:	4f4080e7          	jalr	1268(ra) # 800051e4 <fdalloc>
    80005cf8:	fca42023          	sw	a0,-64(s0)
    80005cfc:	06054863          	bltz	a0,80005d6c <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d00:	4691                	li	a3,4
    80005d02:	fc440613          	addi	a2,s0,-60
    80005d06:	fd843583          	ld	a1,-40(s0)
    80005d0a:	68a8                	ld	a0,80(s1)
    80005d0c:	ffffc097          	auipc	ra,0xffffc
    80005d10:	c66080e7          	jalr	-922(ra) # 80001972 <copyout>
    80005d14:	02054063          	bltz	a0,80005d34 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d18:	4691                	li	a3,4
    80005d1a:	fc040613          	addi	a2,s0,-64
    80005d1e:	fd843583          	ld	a1,-40(s0)
    80005d22:	0591                	addi	a1,a1,4
    80005d24:	68a8                	ld	a0,80(s1)
    80005d26:	ffffc097          	auipc	ra,0xffffc
    80005d2a:	c4c080e7          	jalr	-948(ra) # 80001972 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d2e:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d30:	06055563          	bgez	a0,80005d9a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005d34:	fc442783          	lw	a5,-60(s0)
    80005d38:	07e9                	addi	a5,a5,26
    80005d3a:	078e                	slli	a5,a5,0x3
    80005d3c:	97a6                	add	a5,a5,s1
    80005d3e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d42:	fc042503          	lw	a0,-64(s0)
    80005d46:	0569                	addi	a0,a0,26
    80005d48:	050e                	slli	a0,a0,0x3
    80005d4a:	9526                	add	a0,a0,s1
    80005d4c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d50:	fd043503          	ld	a0,-48(s0)
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	988080e7          	jalr	-1656(ra) # 800046dc <fileclose>
    fileclose(wf);
    80005d5c:	fc843503          	ld	a0,-56(s0)
    80005d60:	fffff097          	auipc	ra,0xfffff
    80005d64:	97c080e7          	jalr	-1668(ra) # 800046dc <fileclose>
    return -1;
    80005d68:	57fd                	li	a5,-1
    80005d6a:	a805                	j	80005d9a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005d6c:	fc442783          	lw	a5,-60(s0)
    80005d70:	0007c863          	bltz	a5,80005d80 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005d74:	01a78513          	addi	a0,a5,26
    80005d78:	050e                	slli	a0,a0,0x3
    80005d7a:	9526                	add	a0,a0,s1
    80005d7c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005d80:	fd043503          	ld	a0,-48(s0)
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	958080e7          	jalr	-1704(ra) # 800046dc <fileclose>
    fileclose(wf);
    80005d8c:	fc843503          	ld	a0,-56(s0)
    80005d90:	fffff097          	auipc	ra,0xfffff
    80005d94:	94c080e7          	jalr	-1716(ra) # 800046dc <fileclose>
    return -1;
    80005d98:	57fd                	li	a5,-1
}
    80005d9a:	853e                	mv	a0,a5
    80005d9c:	70e2                	ld	ra,56(sp)
    80005d9e:	7442                	ld	s0,48(sp)
    80005da0:	74a2                	ld	s1,40(sp)
    80005da2:	6121                	addi	sp,sp,64
    80005da4:	8082                	ret
	...

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	d1ffc0ef          	jal	ra,80002b0e <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	710c                	ld	a1,32(a0)
    80005e4c:	7510                	ld	a2,40(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	c52080e7          	jalr	-942(ra) # 80001ada <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	c1a080e7          	jalr	-998(ra) # 80001ada <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	bf2080e7          	jalr	-1038(ra) # 80001ada <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	04a7cc63          	blt	a5,a0,80005f68 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f14:	0001d797          	auipc	a5,0x1d
    80005f18:	0ec78793          	addi	a5,a5,236 # 80023000 <disk>
    80005f1c:	00a78733          	add	a4,a5,a0
    80005f20:	6789                	lui	a5,0x2
    80005f22:	97ba                	add	a5,a5,a4
    80005f24:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f28:	eba1                	bnez	a5,80005f78 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f2a:	00451713          	slli	a4,a0,0x4
    80005f2e:	0001f797          	auipc	a5,0x1f
    80005f32:	0d27b783          	ld	a5,210(a5) # 80025000 <disk+0x2000>
    80005f36:	97ba                	add	a5,a5,a4
    80005f38:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005f3c:	0001d797          	auipc	a5,0x1d
    80005f40:	0c478793          	addi	a5,a5,196 # 80023000 <disk>
    80005f44:	97aa                	add	a5,a5,a0
    80005f46:	6509                	lui	a0,0x2
    80005f48:	953e                	add	a0,a0,a5
    80005f4a:	4785                	li	a5,1
    80005f4c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f50:	0001f517          	auipc	a0,0x1f
    80005f54:	0c850513          	addi	a0,a0,200 # 80025018 <disk+0x2018>
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	65c080e7          	jalr	1628(ra) # 800025b4 <wakeup>
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret
    panic("virtio_disk_intr 1");
    80005f68:	00003517          	auipc	a0,0x3
    80005f6c:	86050513          	addi	a0,a0,-1952 # 800087c8 <syscalls+0x328>
    80005f70:	ffffa097          	auipc	ra,0xffffa
    80005f74:	5e6080e7          	jalr	1510(ra) # 80000556 <panic>
    panic("virtio_disk_intr 2");
    80005f78:	00003517          	auipc	a0,0x3
    80005f7c:	86850513          	addi	a0,a0,-1944 # 800087e0 <syscalls+0x340>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5d6080e7          	jalr	1494(ra) # 80000556 <panic>

0000000080005f88 <virtio_disk_init>:
{
    80005f88:	1101                	addi	sp,sp,-32
    80005f8a:	ec06                	sd	ra,24(sp)
    80005f8c:	e822                	sd	s0,16(sp)
    80005f8e:	e426                	sd	s1,8(sp)
    80005f90:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f92:	00003597          	auipc	a1,0x3
    80005f96:	86658593          	addi	a1,a1,-1946 # 800087f8 <syscalls+0x358>
    80005f9a:	0001f517          	auipc	a0,0x1f
    80005f9e:	10e50513          	addi	a0,a0,270 # 800250a8 <disk+0x20a8>
    80005fa2:	ffffb097          	auipc	ra,0xffffb
    80005fa6:	bec080e7          	jalr	-1044(ra) # 80000b8e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005faa:	100017b7          	lui	a5,0x10001
    80005fae:	4398                	lw	a4,0(a5)
    80005fb0:	2701                	sext.w	a4,a4
    80005fb2:	747277b7          	lui	a5,0x74727
    80005fb6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fba:	0ef71163          	bne	a4,a5,8000609c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	43dc                	lw	a5,4(a5)
    80005fc4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc6:	4705                	li	a4,1
    80005fc8:	0ce79a63          	bne	a5,a4,8000609c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fcc:	100017b7          	lui	a5,0x10001
    80005fd0:	479c                	lw	a5,8(a5)
    80005fd2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005fd4:	4709                	li	a4,2
    80005fd6:	0ce79363          	bne	a5,a4,8000609c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fda:	100017b7          	lui	a5,0x10001
    80005fde:	47d8                	lw	a4,12(a5)
    80005fe0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe2:	554d47b7          	lui	a5,0x554d4
    80005fe6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fea:	0af71963          	bne	a4,a5,8000609c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	100017b7          	lui	a5,0x10001
    80005ff2:	4705                	li	a4,1
    80005ff4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff6:	470d                	li	a4,3
    80005ff8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ffa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ffc:	c7ffe737          	lui	a4,0xc7ffe
    80006000:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006004:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006006:	2701                	sext.w	a4,a4
    80006008:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600a:	472d                	li	a4,11
    8000600c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600e:	473d                	li	a4,15
    80006010:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006012:	6705                	lui	a4,0x1
    80006014:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006016:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000601a:	5bdc                	lw	a5,52(a5)
    8000601c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000601e:	c7d9                	beqz	a5,800060ac <virtio_disk_init+0x124>
  if(max < NUM)
    80006020:	471d                	li	a4,7
    80006022:	08f77d63          	bgeu	a4,a5,800060bc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006026:	100014b7          	lui	s1,0x10001
    8000602a:	47a1                	li	a5,8
    8000602c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000602e:	6609                	lui	a2,0x2
    80006030:	4581                	li	a1,0
    80006032:	0001d517          	auipc	a0,0x1d
    80006036:	fce50513          	addi	a0,a0,-50 # 80023000 <disk>
    8000603a:	ffffb097          	auipc	ra,0xffffb
    8000603e:	ce0080e7          	jalr	-800(ra) # 80000d1a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006042:	0001d717          	auipc	a4,0x1d
    80006046:	fbe70713          	addi	a4,a4,-66 # 80023000 <disk>
    8000604a:	00c75793          	srli	a5,a4,0xc
    8000604e:	2781                	sext.w	a5,a5
    80006050:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006052:	0001f797          	auipc	a5,0x1f
    80006056:	fae78793          	addi	a5,a5,-82 # 80025000 <disk+0x2000>
    8000605a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000605c:	0001d717          	auipc	a4,0x1d
    80006060:	02470713          	addi	a4,a4,36 # 80023080 <disk+0x80>
    80006064:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006066:	0001e717          	auipc	a4,0x1e
    8000606a:	f9a70713          	addi	a4,a4,-102 # 80024000 <disk+0x1000>
    8000606e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006070:	4705                	li	a4,1
    80006072:	00e78c23          	sb	a4,24(a5)
    80006076:	00e78ca3          	sb	a4,25(a5)
    8000607a:	00e78d23          	sb	a4,26(a5)
    8000607e:	00e78da3          	sb	a4,27(a5)
    80006082:	00e78e23          	sb	a4,28(a5)
    80006086:	00e78ea3          	sb	a4,29(a5)
    8000608a:	00e78f23          	sb	a4,30(a5)
    8000608e:	00e78fa3          	sb	a4,31(a5)
}
    80006092:	60e2                	ld	ra,24(sp)
    80006094:	6442                	ld	s0,16(sp)
    80006096:	64a2                	ld	s1,8(sp)
    80006098:	6105                	addi	sp,sp,32
    8000609a:	8082                	ret
    panic("could not find virtio disk");
    8000609c:	00002517          	auipc	a0,0x2
    800060a0:	76c50513          	addi	a0,a0,1900 # 80008808 <syscalls+0x368>
    800060a4:	ffffa097          	auipc	ra,0xffffa
    800060a8:	4b2080e7          	jalr	1202(ra) # 80000556 <panic>
    panic("virtio disk has no queue 0");
    800060ac:	00002517          	auipc	a0,0x2
    800060b0:	77c50513          	addi	a0,a0,1916 # 80008828 <syscalls+0x388>
    800060b4:	ffffa097          	auipc	ra,0xffffa
    800060b8:	4a2080e7          	jalr	1186(ra) # 80000556 <panic>
    panic("virtio disk max queue too short");
    800060bc:	00002517          	auipc	a0,0x2
    800060c0:	78c50513          	addi	a0,a0,1932 # 80008848 <syscalls+0x3a8>
    800060c4:	ffffa097          	auipc	ra,0xffffa
    800060c8:	492080e7          	jalr	1170(ra) # 80000556 <panic>

00000000800060cc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800060cc:	7119                	addi	sp,sp,-128
    800060ce:	fc86                	sd	ra,120(sp)
    800060d0:	f8a2                	sd	s0,112(sp)
    800060d2:	f4a6                	sd	s1,104(sp)
    800060d4:	f0ca                	sd	s2,96(sp)
    800060d6:	ecce                	sd	s3,88(sp)
    800060d8:	e8d2                	sd	s4,80(sp)
    800060da:	e4d6                	sd	s5,72(sp)
    800060dc:	e0da                	sd	s6,64(sp)
    800060de:	fc5e                	sd	s7,56(sp)
    800060e0:	f862                	sd	s8,48(sp)
    800060e2:	f466                	sd	s9,40(sp)
    800060e4:	f06a                	sd	s10,32(sp)
    800060e6:	0100                	addi	s0,sp,128
    800060e8:	892a                	mv	s2,a0
    800060ea:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060ec:	00c52c83          	lw	s9,12(a0)
    800060f0:	001c9c9b          	slliw	s9,s9,0x1
    800060f4:	1c82                	slli	s9,s9,0x20
    800060f6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060fa:	0001f517          	auipc	a0,0x1f
    800060fe:	fae50513          	addi	a0,a0,-82 # 800250a8 <disk+0x20a8>
    80006102:	ffffb097          	auipc	ra,0xffffb
    80006106:	b1c080e7          	jalr	-1252(ra) # 80000c1e <acquire>
  for(int i = 0; i < 3; i++){
    8000610a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000610c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000610e:	0001db97          	auipc	s7,0x1d
    80006112:	ef2b8b93          	addi	s7,s7,-270 # 80023000 <disk>
    80006116:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006118:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000611a:	8a4e                	mv	s4,s3
    8000611c:	a051                	j	800061a0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000611e:	00fb86b3          	add	a3,s7,a5
    80006122:	96da                	add	a3,a3,s6
    80006124:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006128:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000612a:	0207c563          	bltz	a5,80006154 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000612e:	2485                	addiw	s1,s1,1
    80006130:	0711                	addi	a4,a4,4
    80006132:	25548363          	beq	s1,s5,80006378 <virtio_disk_rw+0x2ac>
    idx[i] = alloc_desc();
    80006136:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006138:	0001f697          	auipc	a3,0x1f
    8000613c:	ee068693          	addi	a3,a3,-288 # 80025018 <disk+0x2018>
    80006140:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006142:	0006c583          	lbu	a1,0(a3)
    80006146:	fde1                	bnez	a1,8000611e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006148:	2785                	addiw	a5,a5,1
    8000614a:	0685                	addi	a3,a3,1
    8000614c:	ff879be3          	bne	a5,s8,80006142 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006150:	57fd                	li	a5,-1
    80006152:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006154:	02905a63          	blez	s1,80006188 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006158:	f9042503          	lw	a0,-112(s0)
    8000615c:	00000097          	auipc	ra,0x0
    80006160:	daa080e7          	jalr	-598(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006164:	4785                	li	a5,1
    80006166:	0297d163          	bge	a5,s1,80006188 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000616a:	f9442503          	lw	a0,-108(s0)
    8000616e:	00000097          	auipc	ra,0x0
    80006172:	d98080e7          	jalr	-616(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006176:	4789                	li	a5,2
    80006178:	0097d863          	bge	a5,s1,80006188 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000617c:	f9842503          	lw	a0,-104(s0)
    80006180:	00000097          	auipc	ra,0x0
    80006184:	d86080e7          	jalr	-634(ra) # 80005f06 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006188:	0001f597          	auipc	a1,0x1f
    8000618c:	f2058593          	addi	a1,a1,-224 # 800250a8 <disk+0x20a8>
    80006190:	0001f517          	auipc	a0,0x1f
    80006194:	e8850513          	addi	a0,a0,-376 # 80025018 <disk+0x2018>
    80006198:	ffffc097          	auipc	ra,0xffffc
    8000619c:	296080e7          	jalr	662(ra) # 8000242e <sleep>
  for(int i = 0; i < 3; i++){
    800061a0:	f9040713          	addi	a4,s0,-112
    800061a4:	84ce                	mv	s1,s3
    800061a6:	bf41                	j	80006136 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800061a8:	4785                	li	a5,1
    800061aa:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800061ae:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800061b2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa(myproc()->kernelpgtbl, (uint64) &buf0);
    800061b6:	ffffc097          	auipc	ra,0xffffc
    800061ba:	950080e7          	jalr	-1712(ra) # 80001b06 <myproc>
    800061be:	f9042983          	lw	s3,-112(s0)
    800061c2:	00499493          	slli	s1,s3,0x4
    800061c6:	0001fa17          	auipc	s4,0x1f
    800061ca:	e3aa0a13          	addi	s4,s4,-454 # 80025000 <disk+0x2000>
    800061ce:	000a3a83          	ld	s5,0(s4)
    800061d2:	9aa6                	add	s5,s5,s1
    800061d4:	f8040593          	addi	a1,s0,-128
    800061d8:	16853503          	ld	a0,360(a0)
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	06c080e7          	jalr	108(ra) # 80001248 <kvmpa>
    800061e4:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800061e8:	000a3783          	ld	a5,0(s4)
    800061ec:	97a6                	add	a5,a5,s1
    800061ee:	4741                	li	a4,16
    800061f0:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061f2:	000a3783          	ld	a5,0(s4)
    800061f6:	97a6                	add	a5,a5,s1
    800061f8:	4705                	li	a4,1
    800061fa:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800061fe:	f9442703          	lw	a4,-108(s0)
    80006202:	000a3783          	ld	a5,0(s4)
    80006206:	97a6                	add	a5,a5,s1
    80006208:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000620c:	0712                	slli	a4,a4,0x4
    8000620e:	000a3783          	ld	a5,0(s4)
    80006212:	97ba                	add	a5,a5,a4
    80006214:	05890693          	addi	a3,s2,88
    80006218:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000621a:	000a3783          	ld	a5,0(s4)
    8000621e:	97ba                	add	a5,a5,a4
    80006220:	40000693          	li	a3,1024
    80006224:	c794                	sw	a3,8(a5)
  if(write)
    80006226:	100d0a63          	beqz	s10,8000633a <virtio_disk_rw+0x26e>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000622a:	0001f797          	auipc	a5,0x1f
    8000622e:	dd67b783          	ld	a5,-554(a5) # 80025000 <disk+0x2000>
    80006232:	97ba                	add	a5,a5,a4
    80006234:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006238:	0001d517          	auipc	a0,0x1d
    8000623c:	dc850513          	addi	a0,a0,-568 # 80023000 <disk>
    80006240:	0001f797          	auipc	a5,0x1f
    80006244:	dc078793          	addi	a5,a5,-576 # 80025000 <disk+0x2000>
    80006248:	6394                	ld	a3,0(a5)
    8000624a:	96ba                	add	a3,a3,a4
    8000624c:	00c6d603          	lhu	a2,12(a3)
    80006250:	00166613          	ori	a2,a2,1
    80006254:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006258:	f9842683          	lw	a3,-104(s0)
    8000625c:	6390                	ld	a2,0(a5)
    8000625e:	9732                	add	a4,a4,a2
    80006260:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006264:	20098613          	addi	a2,s3,512
    80006268:	0612                	slli	a2,a2,0x4
    8000626a:	962a                	add	a2,a2,a0
    8000626c:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006270:	00469713          	slli	a4,a3,0x4
    80006274:	6394                	ld	a3,0(a5)
    80006276:	96ba                	add	a3,a3,a4
    80006278:	6589                	lui	a1,0x2
    8000627a:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    8000627e:	94ae                	add	s1,s1,a1
    80006280:	94aa                	add	s1,s1,a0
    80006282:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006284:	6394                	ld	a3,0(a5)
    80006286:	96ba                	add	a3,a3,a4
    80006288:	4585                	li	a1,1
    8000628a:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000628c:	6394                	ld	a3,0(a5)
    8000628e:	96ba                	add	a3,a3,a4
    80006290:	4509                	li	a0,2
    80006292:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006296:	6394                	ld	a3,0(a5)
    80006298:	9736                	add	a4,a4,a3
    8000629a:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000629e:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800062a2:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800062a6:	6794                	ld	a3,8(a5)
    800062a8:	0026d703          	lhu	a4,2(a3)
    800062ac:	8b1d                	andi	a4,a4,7
    800062ae:	2709                	addiw	a4,a4,2
    800062b0:	0706                	slli	a4,a4,0x1
    800062b2:	9736                	add	a4,a4,a3
    800062b4:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800062b8:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800062bc:	6798                	ld	a4,8(a5)
    800062be:	00275783          	lhu	a5,2(a4)
    800062c2:	2785                	addiw	a5,a5,1
    800062c4:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062c8:	100017b7          	lui	a5,0x10001
    800062cc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062d0:	00492703          	lw	a4,4(s2)
    800062d4:	4785                	li	a5,1
    800062d6:	02f71163          	bne	a4,a5,800062f8 <virtio_disk_rw+0x22c>
    sleep(b, &disk.vdisk_lock);
    800062da:	0001f997          	auipc	s3,0x1f
    800062de:	dce98993          	addi	s3,s3,-562 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800062e2:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062e4:	85ce                	mv	a1,s3
    800062e6:	854a                	mv	a0,s2
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	146080e7          	jalr	326(ra) # 8000242e <sleep>
  while(b->disk == 1) {
    800062f0:	00492783          	lw	a5,4(s2)
    800062f4:	fe9788e3          	beq	a5,s1,800062e4 <virtio_disk_rw+0x218>
  }

  disk.info[idx[0]].b = 0;
    800062f8:	f9042483          	lw	s1,-112(s0)
    800062fc:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006300:	00479713          	slli	a4,a5,0x4
    80006304:	0001d797          	auipc	a5,0x1d
    80006308:	cfc78793          	addi	a5,a5,-772 # 80023000 <disk>
    8000630c:	97ba                	add	a5,a5,a4
    8000630e:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006312:	0001f917          	auipc	s2,0x1f
    80006316:	cee90913          	addi	s2,s2,-786 # 80025000 <disk+0x2000>
    free_desc(i);
    8000631a:	8526                	mv	a0,s1
    8000631c:	00000097          	auipc	ra,0x0
    80006320:	bea080e7          	jalr	-1046(ra) # 80005f06 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006324:	0492                	slli	s1,s1,0x4
    80006326:	00093783          	ld	a5,0(s2)
    8000632a:	94be                	add	s1,s1,a5
    8000632c:	00c4d783          	lhu	a5,12(s1)
    80006330:	8b85                	andi	a5,a5,1
    80006332:	cf89                	beqz	a5,8000634c <virtio_disk_rw+0x280>
      i = disk.desc[i].next;
    80006334:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    80006338:	b7cd                	j	8000631a <virtio_disk_rw+0x24e>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000633a:	0001f797          	auipc	a5,0x1f
    8000633e:	cc67b783          	ld	a5,-826(a5) # 80025000 <disk+0x2000>
    80006342:	97ba                	add	a5,a5,a4
    80006344:	4689                	li	a3,2
    80006346:	00d79623          	sh	a3,12(a5)
    8000634a:	b5fd                	j	80006238 <virtio_disk_rw+0x16c>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000634c:	0001f517          	auipc	a0,0x1f
    80006350:	d5c50513          	addi	a0,a0,-676 # 800250a8 <disk+0x20a8>
    80006354:	ffffb097          	auipc	ra,0xffffb
    80006358:	97e080e7          	jalr	-1666(ra) # 80000cd2 <release>
}
    8000635c:	70e6                	ld	ra,120(sp)
    8000635e:	7446                	ld	s0,112(sp)
    80006360:	74a6                	ld	s1,104(sp)
    80006362:	7906                	ld	s2,96(sp)
    80006364:	69e6                	ld	s3,88(sp)
    80006366:	6a46                	ld	s4,80(sp)
    80006368:	6aa6                	ld	s5,72(sp)
    8000636a:	6b06                	ld	s6,64(sp)
    8000636c:	7be2                	ld	s7,56(sp)
    8000636e:	7c42                	ld	s8,48(sp)
    80006370:	7ca2                	ld	s9,40(sp)
    80006372:	7d02                	ld	s10,32(sp)
    80006374:	6109                	addi	sp,sp,128
    80006376:	8082                	ret
  if(write)
    80006378:	e20d18e3          	bnez	s10,800061a8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    8000637c:	f8042023          	sw	zero,-128(s0)
    80006380:	b53d                	j	800061ae <virtio_disk_rw+0xe2>

0000000080006382 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006382:	1101                	addi	sp,sp,-32
    80006384:	ec06                	sd	ra,24(sp)
    80006386:	e822                	sd	s0,16(sp)
    80006388:	e426                	sd	s1,8(sp)
    8000638a:	e04a                	sd	s2,0(sp)
    8000638c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000638e:	0001f517          	auipc	a0,0x1f
    80006392:	d1a50513          	addi	a0,a0,-742 # 800250a8 <disk+0x20a8>
    80006396:	ffffb097          	auipc	ra,0xffffb
    8000639a:	888080e7          	jalr	-1912(ra) # 80000c1e <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    8000639e:	0001f717          	auipc	a4,0x1f
    800063a2:	c6270713          	addi	a4,a4,-926 # 80025000 <disk+0x2000>
    800063a6:	02075783          	lhu	a5,32(a4)
    800063aa:	6b18                	ld	a4,16(a4)
    800063ac:	00275683          	lhu	a3,2(a4)
    800063b0:	8ebd                	xor	a3,a3,a5
    800063b2:	8a9d                	andi	a3,a3,7
    800063b4:	cab9                	beqz	a3,8000640a <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800063b6:	0001d917          	auipc	s2,0x1d
    800063ba:	c4a90913          	addi	s2,s2,-950 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063be:	0001f497          	auipc	s1,0x1f
    800063c2:	c4248493          	addi	s1,s1,-958 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800063c6:	078e                	slli	a5,a5,0x3
    800063c8:	97ba                	add	a5,a5,a4
    800063ca:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800063cc:	20078713          	addi	a4,a5,512
    800063d0:	0712                	slli	a4,a4,0x4
    800063d2:	974a                	add	a4,a4,s2
    800063d4:	03074703          	lbu	a4,48(a4)
    800063d8:	ef21                	bnez	a4,80006430 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800063da:	20078793          	addi	a5,a5,512
    800063de:	0792                	slli	a5,a5,0x4
    800063e0:	97ca                	add	a5,a5,s2
    800063e2:	7798                	ld	a4,40(a5)
    800063e4:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800063e8:	7788                	ld	a0,40(a5)
    800063ea:	ffffc097          	auipc	ra,0xffffc
    800063ee:	1ca080e7          	jalr	458(ra) # 800025b4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800063f2:	0204d783          	lhu	a5,32(s1)
    800063f6:	2785                	addiw	a5,a5,1
    800063f8:	8b9d                	andi	a5,a5,7
    800063fa:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800063fe:	6898                	ld	a4,16(s1)
    80006400:	00275683          	lhu	a3,2(a4)
    80006404:	8a9d                	andi	a3,a3,7
    80006406:	fcf690e3          	bne	a3,a5,800063c6 <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000640a:	10001737          	lui	a4,0x10001
    8000640e:	533c                	lw	a5,96(a4)
    80006410:	8b8d                	andi	a5,a5,3
    80006412:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006414:	0001f517          	auipc	a0,0x1f
    80006418:	c9450513          	addi	a0,a0,-876 # 800250a8 <disk+0x20a8>
    8000641c:	ffffb097          	auipc	ra,0xffffb
    80006420:	8b6080e7          	jalr	-1866(ra) # 80000cd2 <release>
}
    80006424:	60e2                	ld	ra,24(sp)
    80006426:	6442                	ld	s0,16(sp)
    80006428:	64a2                	ld	s1,8(sp)
    8000642a:	6902                	ld	s2,0(sp)
    8000642c:	6105                	addi	sp,sp,32
    8000642e:	8082                	ret
      panic("virtio_disk_intr status");
    80006430:	00002517          	auipc	a0,0x2
    80006434:	43850513          	addi	a0,a0,1080 # 80008868 <syscalls+0x3c8>
    80006438:	ffffa097          	auipc	ra,0xffffa
    8000643c:	11e080e7          	jalr	286(ra) # 80000556 <panic>

0000000080006440 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006440:	7179                	addi	sp,sp,-48
    80006442:	f406                	sd	ra,40(sp)
    80006444:	f022                	sd	s0,32(sp)
    80006446:	ec26                	sd	s1,24(sp)
    80006448:	e84a                	sd	s2,16(sp)
    8000644a:	e44e                	sd	s3,8(sp)
    8000644c:	e052                	sd	s4,0(sp)
    8000644e:	1800                	addi	s0,sp,48
    80006450:	892a                	mv	s2,a0
    80006452:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006454:	00003a17          	auipc	s4,0x3
    80006458:	bd4a0a13          	addi	s4,s4,-1068 # 80009028 <stats>
    8000645c:	000a2683          	lw	a3,0(s4)
    80006460:	00002617          	auipc	a2,0x2
    80006464:	42060613          	addi	a2,a2,1056 # 80008880 <syscalls+0x3e0>
    80006468:	00000097          	auipc	ra,0x0
    8000646c:	2c2080e7          	jalr	706(ra) # 8000672a <snprintf>
    80006470:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    80006472:	004a2683          	lw	a3,4(s4)
    80006476:	00002617          	auipc	a2,0x2
    8000647a:	41a60613          	addi	a2,a2,1050 # 80008890 <syscalls+0x3f0>
    8000647e:	85ce                	mv	a1,s3
    80006480:	954a                	add	a0,a0,s2
    80006482:	00000097          	auipc	ra,0x0
    80006486:	2a8080e7          	jalr	680(ra) # 8000672a <snprintf>
  return n;
}
    8000648a:	9d25                	addw	a0,a0,s1
    8000648c:	70a2                	ld	ra,40(sp)
    8000648e:	7402                	ld	s0,32(sp)
    80006490:	64e2                	ld	s1,24(sp)
    80006492:	6942                	ld	s2,16(sp)
    80006494:	69a2                	ld	s3,8(sp)
    80006496:	6a02                	ld	s4,0(sp)
    80006498:	6145                	addi	sp,sp,48
    8000649a:	8082                	ret

000000008000649c <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    8000649c:	7179                	addi	sp,sp,-48
    8000649e:	f406                	sd	ra,40(sp)
    800064a0:	f022                	sd	s0,32(sp)
    800064a2:	ec26                	sd	s1,24(sp)
    800064a4:	e84a                	sd	s2,16(sp)
    800064a6:	e44e                	sd	s3,8(sp)
    800064a8:	1800                	addi	s0,sp,48
    800064aa:	89ae                	mv	s3,a1
    800064ac:	84b2                	mv	s1,a2
    800064ae:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800064b0:	ffffb097          	auipc	ra,0xffffb
    800064b4:	656080e7          	jalr	1622(ra) # 80001b06 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800064b8:	653c                	ld	a5,72(a0)
    800064ba:	02f4ff63          	bgeu	s1,a5,800064f8 <copyin_new+0x5c>
    800064be:	01248733          	add	a4,s1,s2
    800064c2:	02f77d63          	bgeu	a4,a5,800064fc <copyin_new+0x60>
    800064c6:	02976d63          	bltu	a4,s1,80006500 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800064ca:	0009061b          	sext.w	a2,s2
    800064ce:	85a6                	mv	a1,s1
    800064d0:	854e                	mv	a0,s3
    800064d2:	ffffb097          	auipc	ra,0xffffb
    800064d6:	8a8080e7          	jalr	-1880(ra) # 80000d7a <memmove>
  stats.ncopyin++;   // XXX lock
    800064da:	00003717          	auipc	a4,0x3
    800064de:	b4e70713          	addi	a4,a4,-1202 # 80009028 <stats>
    800064e2:	431c                	lw	a5,0(a4)
    800064e4:	2785                	addiw	a5,a5,1
    800064e6:	c31c                	sw	a5,0(a4)
  return 0;
    800064e8:	4501                	li	a0,0
}
    800064ea:	70a2                	ld	ra,40(sp)
    800064ec:	7402                	ld	s0,32(sp)
    800064ee:	64e2                	ld	s1,24(sp)
    800064f0:	6942                	ld	s2,16(sp)
    800064f2:	69a2                	ld	s3,8(sp)
    800064f4:	6145                	addi	sp,sp,48
    800064f6:	8082                	ret
    return -1;
    800064f8:	557d                	li	a0,-1
    800064fa:	bfc5                	j	800064ea <copyin_new+0x4e>
    800064fc:	557d                	li	a0,-1
    800064fe:	b7f5                	j	800064ea <copyin_new+0x4e>
    80006500:	557d                	li	a0,-1
    80006502:	b7e5                	j	800064ea <copyin_new+0x4e>

0000000080006504 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006504:	7179                	addi	sp,sp,-48
    80006506:	f406                	sd	ra,40(sp)
    80006508:	f022                	sd	s0,32(sp)
    8000650a:	ec26                	sd	s1,24(sp)
    8000650c:	e84a                	sd	s2,16(sp)
    8000650e:	e44e                	sd	s3,8(sp)
    80006510:	1800                	addi	s0,sp,48
    80006512:	89ae                	mv	s3,a1
    80006514:	8932                	mv	s2,a2
    80006516:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    80006518:	ffffb097          	auipc	ra,0xffffb
    8000651c:	5ee080e7          	jalr	1518(ra) # 80001b06 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006520:	00003717          	auipc	a4,0x3
    80006524:	b0870713          	addi	a4,a4,-1272 # 80009028 <stats>
    80006528:	435c                	lw	a5,4(a4)
    8000652a:	2785                	addiw	a5,a5,1
    8000652c:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000652e:	cc85                	beqz	s1,80006566 <copyinstr_new+0x62>
    80006530:	00990833          	add	a6,s2,s1
    80006534:	87ca                	mv	a5,s2
    80006536:	6538                	ld	a4,72(a0)
    80006538:	00e7ff63          	bgeu	a5,a4,80006556 <copyinstr_new+0x52>
    dst[i] = s[i];
    8000653c:	0007c683          	lbu	a3,0(a5)
    80006540:	41278733          	sub	a4,a5,s2
    80006544:	974e                	add	a4,a4,s3
    80006546:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000654a:	c285                	beqz	a3,8000656a <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    8000654c:	0785                	addi	a5,a5,1
    8000654e:	ff0794e3          	bne	a5,a6,80006536 <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006552:	557d                	li	a0,-1
    80006554:	a011                	j	80006558 <copyinstr_new+0x54>
    80006556:	557d                	li	a0,-1
}
    80006558:	70a2                	ld	ra,40(sp)
    8000655a:	7402                	ld	s0,32(sp)
    8000655c:	64e2                	ld	s1,24(sp)
    8000655e:	6942                	ld	s2,16(sp)
    80006560:	69a2                	ld	s3,8(sp)
    80006562:	6145                	addi	sp,sp,48
    80006564:	8082                	ret
  return -1;
    80006566:	557d                	li	a0,-1
    80006568:	bfc5                	j	80006558 <copyinstr_new+0x54>
      return 0;
    8000656a:	4501                	li	a0,0
    8000656c:	b7f5                	j	80006558 <copyinstr_new+0x54>

000000008000656e <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    8000656e:	1141                	addi	sp,sp,-16
    80006570:	e422                	sd	s0,8(sp)
    80006572:	0800                	addi	s0,sp,16
  return -1;
}
    80006574:	557d                	li	a0,-1
    80006576:	6422                	ld	s0,8(sp)
    80006578:	0141                	addi	sp,sp,16
    8000657a:	8082                	ret

000000008000657c <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    8000657c:	7179                	addi	sp,sp,-48
    8000657e:	f406                	sd	ra,40(sp)
    80006580:	f022                	sd	s0,32(sp)
    80006582:	ec26                	sd	s1,24(sp)
    80006584:	e84a                	sd	s2,16(sp)
    80006586:	e44e                	sd	s3,8(sp)
    80006588:	e052                	sd	s4,0(sp)
    8000658a:	1800                	addi	s0,sp,48
    8000658c:	892a                	mv	s2,a0
    8000658e:	89ae                	mv	s3,a1
    80006590:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    80006592:	00020517          	auipc	a0,0x20
    80006596:	a6e50513          	addi	a0,a0,-1426 # 80026000 <stats>
    8000659a:	ffffa097          	auipc	ra,0xffffa
    8000659e:	684080e7          	jalr	1668(ra) # 80000c1e <acquire>

  if(stats.sz == 0) {
    800065a2:	00021797          	auipc	a5,0x21
    800065a6:	a767a783          	lw	a5,-1418(a5) # 80027018 <stats+0x1018>
    800065aa:	cbb5                	beqz	a5,8000661e <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800065ac:	00021797          	auipc	a5,0x21
    800065b0:	a5478793          	addi	a5,a5,-1452 # 80027000 <stats+0x1000>
    800065b4:	4fd8                	lw	a4,28(a5)
    800065b6:	4f9c                	lw	a5,24(a5)
    800065b8:	9f99                	subw	a5,a5,a4
    800065ba:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800065be:	06d05e63          	blez	a3,8000663a <statsread+0xbe>
    if(m > n)
    800065c2:	8a3e                	mv	s4,a5
    800065c4:	00d4d363          	bge	s1,a3,800065ca <statsread+0x4e>
    800065c8:	8a26                	mv	s4,s1
    800065ca:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800065ce:	86a6                	mv	a3,s1
    800065d0:	00020617          	auipc	a2,0x20
    800065d4:	a4860613          	addi	a2,a2,-1464 # 80026018 <stats+0x18>
    800065d8:	963a                	add	a2,a2,a4
    800065da:	85ce                	mv	a1,s3
    800065dc:	854a                	mv	a0,s2
    800065de:	ffffc097          	auipc	ra,0xffffc
    800065e2:	0b2080e7          	jalr	178(ra) # 80002690 <either_copyout>
    800065e6:	57fd                	li	a5,-1
    800065e8:	00f50a63          	beq	a0,a5,800065fc <statsread+0x80>
      stats.off += m;
    800065ec:	00021717          	auipc	a4,0x21
    800065f0:	a1470713          	addi	a4,a4,-1516 # 80027000 <stats+0x1000>
    800065f4:	4f5c                	lw	a5,28(a4)
    800065f6:	014787bb          	addw	a5,a5,s4
    800065fa:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    800065fc:	00020517          	auipc	a0,0x20
    80006600:	a0450513          	addi	a0,a0,-1532 # 80026000 <stats>
    80006604:	ffffa097          	auipc	ra,0xffffa
    80006608:	6ce080e7          	jalr	1742(ra) # 80000cd2 <release>
  return m;
}
    8000660c:	8526                	mv	a0,s1
    8000660e:	70a2                	ld	ra,40(sp)
    80006610:	7402                	ld	s0,32(sp)
    80006612:	64e2                	ld	s1,24(sp)
    80006614:	6942                	ld	s2,16(sp)
    80006616:	69a2                	ld	s3,8(sp)
    80006618:	6a02                	ld	s4,0(sp)
    8000661a:	6145                	addi	sp,sp,48
    8000661c:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    8000661e:	6585                	lui	a1,0x1
    80006620:	00020517          	auipc	a0,0x20
    80006624:	9f850513          	addi	a0,a0,-1544 # 80026018 <stats+0x18>
    80006628:	00000097          	auipc	ra,0x0
    8000662c:	e18080e7          	jalr	-488(ra) # 80006440 <statscopyin>
    80006630:	00021797          	auipc	a5,0x21
    80006634:	9ea7a423          	sw	a0,-1560(a5) # 80027018 <stats+0x1018>
    80006638:	bf95                	j	800065ac <statsread+0x30>
    stats.sz = 0;
    8000663a:	00021797          	auipc	a5,0x21
    8000663e:	9c678793          	addi	a5,a5,-1594 # 80027000 <stats+0x1000>
    80006642:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    80006646:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000664a:	54fd                	li	s1,-1
    8000664c:	bf45                	j	800065fc <statsread+0x80>

000000008000664e <statsinit>:

void
statsinit(void)
{
    8000664e:	1141                	addi	sp,sp,-16
    80006650:	e406                	sd	ra,8(sp)
    80006652:	e022                	sd	s0,0(sp)
    80006654:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    80006656:	00002597          	auipc	a1,0x2
    8000665a:	24a58593          	addi	a1,a1,586 # 800088a0 <syscalls+0x400>
    8000665e:	00020517          	auipc	a0,0x20
    80006662:	9a250513          	addi	a0,a0,-1630 # 80026000 <stats>
    80006666:	ffffa097          	auipc	ra,0xffffa
    8000666a:	528080e7          	jalr	1320(ra) # 80000b8e <initlock>

  devsw[STATS].read = statsread;
    8000666e:	0001b797          	auipc	a5,0x1b
    80006672:	54278793          	addi	a5,a5,1346 # 80021bb0 <devsw>
    80006676:	00000717          	auipc	a4,0x0
    8000667a:	f0670713          	addi	a4,a4,-250 # 8000657c <statsread>
    8000667e:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006680:	00000717          	auipc	a4,0x0
    80006684:	eee70713          	addi	a4,a4,-274 # 8000656e <statswrite>
    80006688:	f798                	sd	a4,40(a5)
}
    8000668a:	60a2                	ld	ra,8(sp)
    8000668c:	6402                	ld	s0,0(sp)
    8000668e:	0141                	addi	sp,sp,16
    80006690:	8082                	ret

0000000080006692 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    80006692:	1101                	addi	sp,sp,-32
    80006694:	ec22                	sd	s0,24(sp)
    80006696:	1000                	addi	s0,sp,32
    80006698:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    8000669a:	c299                	beqz	a3,800066a0 <sprintint+0xe>
    8000669c:	0805c163          	bltz	a1,8000671e <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800066a0:	2581                	sext.w	a1,a1
    800066a2:	4301                	li	t1,0

  i = 0;
    800066a4:	fe040713          	addi	a4,s0,-32
    800066a8:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800066aa:	2601                	sext.w	a2,a2
    800066ac:	00002697          	auipc	a3,0x2
    800066b0:	1fc68693          	addi	a3,a3,508 # 800088a8 <digits>
    800066b4:	88aa                	mv	a7,a0
    800066b6:	2505                	addiw	a0,a0,1
    800066b8:	02c5f7bb          	remuw	a5,a1,a2
    800066bc:	1782                	slli	a5,a5,0x20
    800066be:	9381                	srli	a5,a5,0x20
    800066c0:	97b6                	add	a5,a5,a3
    800066c2:	0007c783          	lbu	a5,0(a5)
    800066c6:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800066ca:	0005879b          	sext.w	a5,a1
    800066ce:	02c5d5bb          	divuw	a1,a1,a2
    800066d2:	0705                	addi	a4,a4,1
    800066d4:	fec7f0e3          	bgeu	a5,a2,800066b4 <sprintint+0x22>

  if(sign)
    800066d8:	00030b63          	beqz	t1,800066ee <sprintint+0x5c>
    buf[i++] = '-';
    800066dc:	ff040793          	addi	a5,s0,-16
    800066e0:	97aa                	add	a5,a5,a0
    800066e2:	02d00713          	li	a4,45
    800066e6:	fee78823          	sb	a4,-16(a5)
    800066ea:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    800066ee:	02a05c63          	blez	a0,80006726 <sprintint+0x94>
    800066f2:	fe040793          	addi	a5,s0,-32
    800066f6:	00a78733          	add	a4,a5,a0
    800066fa:	87c2                	mv	a5,a6
    800066fc:	0805                	addi	a6,a6,1
    800066fe:	fff5061b          	addiw	a2,a0,-1
    80006702:	1602                	slli	a2,a2,0x20
    80006704:	9201                	srli	a2,a2,0x20
    80006706:	9642                	add	a2,a2,a6
  *s = c;
    80006708:	fff74683          	lbu	a3,-1(a4)
    8000670c:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006710:	177d                	addi	a4,a4,-1
    80006712:	0785                	addi	a5,a5,1
    80006714:	fec79ae3          	bne	a5,a2,80006708 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006718:	6462                	ld	s0,24(sp)
    8000671a:	6105                	addi	sp,sp,32
    8000671c:	8082                	ret
    x = -xx;
    8000671e:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006722:	4305                	li	t1,1
    x = -xx;
    80006724:	b741                	j	800066a4 <sprintint+0x12>
  while(--i >= 0)
    80006726:	4501                	li	a0,0
    80006728:	bfc5                	j	80006718 <sprintint+0x86>

000000008000672a <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000672a:	7171                	addi	sp,sp,-176
    8000672c:	fc86                	sd	ra,120(sp)
    8000672e:	f8a2                	sd	s0,112(sp)
    80006730:	f4a6                	sd	s1,104(sp)
    80006732:	f0ca                	sd	s2,96(sp)
    80006734:	ecce                	sd	s3,88(sp)
    80006736:	e8d2                	sd	s4,80(sp)
    80006738:	e4d6                	sd	s5,72(sp)
    8000673a:	e0da                	sd	s6,64(sp)
    8000673c:	fc5e                	sd	s7,56(sp)
    8000673e:	f862                	sd	s8,48(sp)
    80006740:	f466                	sd	s9,40(sp)
    80006742:	f06a                	sd	s10,32(sp)
    80006744:	ec6e                	sd	s11,24(sp)
    80006746:	0100                	addi	s0,sp,128
    80006748:	e414                	sd	a3,8(s0)
    8000674a:	e818                	sd	a4,16(s0)
    8000674c:	ec1c                	sd	a5,24(s0)
    8000674e:	03043023          	sd	a6,32(s0)
    80006752:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006756:	ca0d                	beqz	a2,80006788 <snprintf+0x5e>
    80006758:	8baa                	mv	s7,a0
    8000675a:	89ae                	mv	s3,a1
    8000675c:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    8000675e:	00840793          	addi	a5,s0,8
    80006762:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    80006766:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006768:	4901                	li	s2,0
    8000676a:	02b05763          	blez	a1,80006798 <snprintf+0x6e>
    if(c != '%'){
    8000676e:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    80006772:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    80006776:	02800d93          	li	s11,40
  *s = c;
    8000677a:	02500d13          	li	s10,37
    switch(c){
    8000677e:	07800c93          	li	s9,120
    80006782:	06400c13          	li	s8,100
    80006786:	a01d                	j	800067ac <snprintf+0x82>
    panic("null fmt");
    80006788:	00002517          	auipc	a0,0x2
    8000678c:	89050513          	addi	a0,a0,-1904 # 80008018 <etext+0x18>
    80006790:	ffffa097          	auipc	ra,0xffffa
    80006794:	dc6080e7          	jalr	-570(ra) # 80000556 <panic>
  int off = 0;
    80006798:	4481                	li	s1,0
    8000679a:	a86d                	j	80006854 <snprintf+0x12a>
  *s = c;
    8000679c:	009b8733          	add	a4,s7,s1
    800067a0:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800067a4:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800067a6:	2905                	addiw	s2,s2,1
    800067a8:	0b34d663          	bge	s1,s3,80006854 <snprintf+0x12a>
    800067ac:	012a07b3          	add	a5,s4,s2
    800067b0:	0007c783          	lbu	a5,0(a5)
    800067b4:	0007871b          	sext.w	a4,a5
    800067b8:	cfd1                	beqz	a5,80006854 <snprintf+0x12a>
    if(c != '%'){
    800067ba:	ff5711e3          	bne	a4,s5,8000679c <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800067be:	2905                	addiw	s2,s2,1
    800067c0:	012a07b3          	add	a5,s4,s2
    800067c4:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800067c8:	c7d1                	beqz	a5,80006854 <snprintf+0x12a>
    switch(c){
    800067ca:	05678c63          	beq	a5,s6,80006822 <snprintf+0xf8>
    800067ce:	02fb6763          	bltu	s6,a5,800067fc <snprintf+0xd2>
    800067d2:	0b578763          	beq	a5,s5,80006880 <snprintf+0x156>
    800067d6:	0b879b63          	bne	a5,s8,8000688c <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800067da:	f8843783          	ld	a5,-120(s0)
    800067de:	00878713          	addi	a4,a5,8
    800067e2:	f8e43423          	sd	a4,-120(s0)
    800067e6:	4685                	li	a3,1
    800067e8:	4629                	li	a2,10
    800067ea:	438c                	lw	a1,0(a5)
    800067ec:	009b8533          	add	a0,s7,s1
    800067f0:	00000097          	auipc	ra,0x0
    800067f4:	ea2080e7          	jalr	-350(ra) # 80006692 <sprintint>
    800067f8:	9ca9                	addw	s1,s1,a0
      break;
    800067fa:	b775                	j	800067a6 <snprintf+0x7c>
    switch(c){
    800067fc:	09979863          	bne	a5,s9,8000688c <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006800:	f8843783          	ld	a5,-120(s0)
    80006804:	00878713          	addi	a4,a5,8
    80006808:	f8e43423          	sd	a4,-120(s0)
    8000680c:	4685                	li	a3,1
    8000680e:	4641                	li	a2,16
    80006810:	438c                	lw	a1,0(a5)
    80006812:	009b8533          	add	a0,s7,s1
    80006816:	00000097          	auipc	ra,0x0
    8000681a:	e7c080e7          	jalr	-388(ra) # 80006692 <sprintint>
    8000681e:	9ca9                	addw	s1,s1,a0
      break;
    80006820:	b759                	j	800067a6 <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006822:	f8843783          	ld	a5,-120(s0)
    80006826:	00878713          	addi	a4,a5,8
    8000682a:	f8e43423          	sd	a4,-120(s0)
    8000682e:	639c                	ld	a5,0(a5)
    80006830:	c3b1                	beqz	a5,80006874 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006832:	0007c703          	lbu	a4,0(a5)
    80006836:	db25                	beqz	a4,800067a6 <snprintf+0x7c>
    80006838:	0134de63          	bge	s1,s3,80006854 <snprintf+0x12a>
    8000683c:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006840:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006844:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006846:	0785                	addi	a5,a5,1
    80006848:	0007c703          	lbu	a4,0(a5)
    8000684c:	df29                	beqz	a4,800067a6 <snprintf+0x7c>
    8000684e:	0685                	addi	a3,a3,1
    80006850:	fe9998e3          	bne	s3,s1,80006840 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006854:	8526                	mv	a0,s1
    80006856:	70e6                	ld	ra,120(sp)
    80006858:	7446                	ld	s0,112(sp)
    8000685a:	74a6                	ld	s1,104(sp)
    8000685c:	7906                	ld	s2,96(sp)
    8000685e:	69e6                	ld	s3,88(sp)
    80006860:	6a46                	ld	s4,80(sp)
    80006862:	6aa6                	ld	s5,72(sp)
    80006864:	6b06                	ld	s6,64(sp)
    80006866:	7be2                	ld	s7,56(sp)
    80006868:	7c42                	ld	s8,48(sp)
    8000686a:	7ca2                	ld	s9,40(sp)
    8000686c:	7d02                	ld	s10,32(sp)
    8000686e:	6de2                	ld	s11,24(sp)
    80006870:	614d                	addi	sp,sp,176
    80006872:	8082                	ret
        s = "(null)";
    80006874:	00001797          	auipc	a5,0x1
    80006878:	79c78793          	addi	a5,a5,1948 # 80008010 <etext+0x10>
      for(; *s && off < sz; s++)
    8000687c:	876e                	mv	a4,s11
    8000687e:	bf6d                	j	80006838 <snprintf+0x10e>
  *s = c;
    80006880:	009b87b3          	add	a5,s7,s1
    80006884:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006888:	2485                	addiw	s1,s1,1
      break;
    8000688a:	bf31                	j	800067a6 <snprintf+0x7c>
  *s = c;
    8000688c:	009b8733          	add	a4,s7,s1
    80006890:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006894:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006898:	975e                	add	a4,a4,s7
    8000689a:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    8000689e:	2489                	addiw	s1,s1,2
      break;
    800068a0:	b719                	j	800067a6 <snprintf+0x7c>
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
