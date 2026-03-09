
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
    80000060:	c6478793          	addi	a5,a5,-924 # 80005cc0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	460080e7          	jalr	1120(ra) # 80002586 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	8f0080e7          	jalr	-1808(ra) # 80001abe <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	0f0080e7          	jalr	240(ra) # 800022ce <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	316080e7          	jalr	790(ra) # 80002530 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	2e0080e7          	jalr	736(ra) # 800025dc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	004080e7          	jalr	4(ra) # 80002454 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	b9e080e7          	jalr	-1122(ra) # 80002454 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	97e080e7          	jalr	-1666(ra) # 800022ce <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	ef8080e7          	jalr	-264(ra) # 80001aa2 <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	ec6080e7          	jalr	-314(ra) # 80001aa2 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	eba080e7          	jalr	-326(ra) # 80001aa2 <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	ea2080e7          	jalr	-350(ra) # 80001aa2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e62080e7          	jalr	-414(ra) # 80001aa2 <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e36080e7          	jalr	-458(ra) # 80001aa2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	bcc080e7          	jalr	-1076(ra) # 80001a92 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	bb0080e7          	jalr	-1104(ra) # 80001a92 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	818080e7          	jalr	-2024(ra) # 8000271c <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	df4080e7          	jalr	-524(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	0da080e7          	jalr	218(ra) # 80001fee <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	2a0080e7          	jalr	672(ra) # 80001204 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	a4e080e7          	jalr	-1458(ra) # 800019c2 <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	778080e7          	jalr	1912(ra) # 800026f4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00001097          	auipc	ra,0x1
    80000f88:	798080e7          	jalr	1944(ra) # 8000271c <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	d5e080e7          	jalr	-674(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	d6c080e7          	jalr	-660(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	f0c080e7          	jalr	-244(ra) # 80002ea8 <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	59c080e7          	jalr	1436(ra) # 80003540 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	53a080e7          	jalr	1338(ra) # 800044e6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	e54080e7          	jalr	-428(ra) # 80005e08 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	dcc080e7          	jalr	-564(ra) # 80001d88 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	00a7d513          	srli	a0,a5,0xa
    800010d8:	0532                	slli	a0,a0,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e0:	1101                	addi	sp,sp,-32
    800010e2:	ec06                	sd	ra,24(sp)
    800010e4:	e822                	sd	s0,16(sp)
    800010e6:	e426                	sd	s1,8(sp)
    800010e8:	1000                	addi	s0,sp,32
    800010ea:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010ec:	1552                	slli	a0,a0,0x34
    800010ee:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010f2:	4601                	li	a2,0
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	f1c53503          	ld	a0,-228(a0) # 80009010 <kernel_pagetable>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	efc080e7          	jalr	-260(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001104:	cd09                	beqz	a0,8000111e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001106:	6108                	ld	a0,0(a0)
    80001108:	00157793          	andi	a5,a0,1
    8000110c:	c38d                	beqz	a5,8000112e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000110e:	8129                	srli	a0,a0,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001112:	9526                	add	a0,a0,s1
    80001114:	60e2                	ld	ra,24(sp)
    80001116:	6442                	ld	s0,16(sp)
    80001118:	64a2                	ld	s1,8(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret
    panic("kvmpa");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	fba50513          	addi	a0,a0,-70 # 800080d8 <digits+0x98>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	422080e7          	jalr	1058(ra) # 80000548 <panic>
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e7e080e7          	jalr	-386(ra) # 80000ff8 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f4050513          	addi	a0,a0,-192 # 800080e0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011d6:	86ae                	mv	a3,a1
    800011d8:	85aa                	mv	a1,a0
    800011da:	00008517          	auipc	a0,0x8
    800011de:	e3653503          	ld	a0,-458(a0) # 80009010 <kernel_pagetable>
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	f5c080e7          	jalr	-164(ra) # 8000113e <mappages>
    800011ea:	e509                	bnez	a0,800011f4 <kvmmap+0x28>
}
    800011ec:	60a2                	ld	ra,8(sp)
    800011ee:	6402                	ld	s0,0(sp)
    800011f0:	0141                	addi	sp,sp,16
    800011f2:	8082                	ret
    panic("kvmmap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ef450513          	addi	a0,a0,-268 # 800080e8 <digits+0xa8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <kvminit>:
{
    80001204:	1101                	addi	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	912080e7          	jalr	-1774(ra) # 80000b20 <kalloc>
    80001216:	00008797          	auipc	a5,0x8
    8000121a:	dea7bd23          	sd	a0,-518(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	aea080e7          	jalr	-1302(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100005b7          	lui	a1,0x10000
    80001232:	10000537          	lui	a0,0x10000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f96080e7          	jalr	-106(ra) # 800011cc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6605                	lui	a2,0x1
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	10001537          	lui	a0,0x10001
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f82080e7          	jalr	-126(ra) # 800011cc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	6641                	lui	a2,0x10
    80001256:	020005b7          	lui	a1,0x2000
    8000125a:	02000537          	lui	a0,0x2000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f6e080e7          	jalr	-146(ra) # 800011cc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	00400637          	lui	a2,0x400
    8000126c:	0c0005b7          	lui	a1,0xc000
    80001270:	0c000537          	lui	a0,0xc000
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f58080e7          	jalr	-168(ra) # 800011cc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000127c:	00007497          	auipc	s1,0x7
    80001280:	d8448493          	addi	s1,s1,-636 # 80008000 <etext>
    80001284:	46a9                	li	a3,10
    80001286:	80007617          	auipc	a2,0x80007
    8000128a:	d7a60613          	addi	a2,a2,-646 # 8000 <_entry-0x7fff8000>
    8000128e:	4585                	li	a1,1
    80001290:	05fe                	slli	a1,a1,0x1f
    80001292:	852e                	mv	a0,a1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	4645                	li	a2,17
    800012a0:	066e                	slli	a2,a2,0x1b
    800012a2:	8e05                	sub	a2,a2,s1
    800012a4:	85a6                	mv	a1,s1
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f24080e7          	jalr	-220(ra) # 800011cc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b0:	46a9                	li	a3,10
    800012b2:	6605                	lui	a2,0x1
    800012b4:	00006597          	auipc	a1,0x6
    800012b8:	d4c58593          	addi	a1,a1,-692 # 80007000 <_trampoline>
    800012bc:	04000537          	lui	a0,0x4000
    800012c0:	157d                	addi	a0,a0,-1
    800012c2:	0532                	slli	a0,a0,0xc
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f08080e7          	jalr	-248(ra) # 800011cc <kvmmap>
}
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d6:	715d                	addi	sp,sp,-80
    800012d8:	e486                	sd	ra,72(sp)
    800012da:	e0a2                	sd	s0,64(sp)
    800012dc:	fc26                	sd	s1,56(sp)
    800012de:	f84a                	sd	s2,48(sp)
    800012e0:	f44e                	sd	s3,40(sp)
    800012e2:	f052                	sd	s4,32(sp)
    800012e4:	ec56                	sd	s5,24(sp)
    800012e6:	e85a                	sd	s6,16(sp)
    800012e8:	e45e                	sd	s7,8(sp)
    800012ea:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ec:	03459793          	slli	a5,a1,0x34
    800012f0:	e795                	bnez	a5,8000131c <uvmunmap+0x46>
    800012f2:	8a2a                	mv	s4,a0
    800012f4:	892e                	mv	s2,a1
    800012f6:	8b36                	mv	s6,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f8:	0632                	slli	a2,a2,0xc
    800012fa:	00b609b3          	add	s3,a2,a1
      // panic("uvmunmap: walk");
      continue;
    if((*pte & PTE_V) == 0)
      // panic("uvmunmap: not mapped");
      continue;
    if(PTE_FLAGS(*pte) == PTE_V)
    800012fe:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	6a85                	lui	s5,0x1
    80001302:	0535e963          	bltu	a1,s3,80001354 <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001306:	60a6                	ld	ra,72(sp)
    80001308:	6406                	ld	s0,64(sp)
    8000130a:	74e2                	ld	s1,56(sp)
    8000130c:	7942                	ld	s2,48(sp)
    8000130e:	79a2                	ld	s3,40(sp)
    80001310:	7a02                	ld	s4,32(sp)
    80001312:	6ae2                	ld	s5,24(sp)
    80001314:	6b42                	ld	s6,16(sp)
    80001316:	6ba2                	ld	s7,8(sp)
    80001318:	6161                	addi	sp,sp,80
    8000131a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000131c:	00007517          	auipc	a0,0x7
    80001320:	dd450513          	addi	a0,a0,-556 # 800080f0 <digits+0xb0>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	224080e7          	jalr	548(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	ddc50513          	addi	a0,a0,-548 # 80008108 <digits+0xc8>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000133c:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    8000133e:	00c79513          	slli	a0,a5,0xc
    80001342:	fffff097          	auipc	ra,0xfffff
    80001346:	6e2080e7          	jalr	1762(ra) # 80000a24 <kfree>
    *pte = 0;
    8000134a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000134e:	9956                	add	s2,s2,s5
    80001350:	fb397be3          	bgeu	s2,s3,80001306 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001354:	4601                	li	a2,0
    80001356:	85ca                	mv	a1,s2
    80001358:	8552                	mv	a0,s4
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	c9e080e7          	jalr	-866(ra) # 80000ff8 <walk>
    80001362:	84aa                	mv	s1,a0
    80001364:	d56d                	beqz	a0,8000134e <uvmunmap+0x78>
    if((*pte & PTE_V) == 0)
    80001366:	611c                	ld	a5,0(a0)
    80001368:	0017f713          	andi	a4,a5,1
    8000136c:	d36d                	beqz	a4,8000134e <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000136e:	3ff7f713          	andi	a4,a5,1023
    80001372:	fb770de3          	beq	a4,s7,8000132c <uvmunmap+0x56>
    if(do_free){
    80001376:	fc0b0ae3          	beqz	s6,8000134a <uvmunmap+0x74>
    8000137a:	b7c9                	j	8000133c <uvmunmap+0x66>

000000008000137c <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000137c:	1101                	addi	sp,sp,-32
    8000137e:	ec06                	sd	ra,24(sp)
    80001380:	e822                	sd	s0,16(sp)
    80001382:	e426                	sd	s1,8(sp)
    80001384:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001386:	fffff097          	auipc	ra,0xfffff
    8000138a:	79a080e7          	jalr	1946(ra) # 80000b20 <kalloc>
    8000138e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001390:	c519                	beqz	a0,8000139e <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001392:	6605                	lui	a2,0x1
    80001394:	4581                	li	a1,0
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	976080e7          	jalr	-1674(ra) # 80000d0c <memset>
  return pagetable;
}
    8000139e:	8526                	mv	a0,s1
    800013a0:	60e2                	ld	ra,24(sp)
    800013a2:	6442                	ld	s0,16(sp)
    800013a4:	64a2                	ld	s1,8(sp)
    800013a6:	6105                	addi	sp,sp,32
    800013a8:	8082                	ret

00000000800013aa <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013aa:	7179                	addi	sp,sp,-48
    800013ac:	f406                	sd	ra,40(sp)
    800013ae:	f022                	sd	s0,32(sp)
    800013b0:	ec26                	sd	s1,24(sp)
    800013b2:	e84a                	sd	s2,16(sp)
    800013b4:	e44e                	sd	s3,8(sp)
    800013b6:	e052                	sd	s4,0(sp)
    800013b8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013ba:	6785                	lui	a5,0x1
    800013bc:	04f67863          	bgeu	a2,a5,8000140c <uvminit+0x62>
    800013c0:	8a2a                	mv	s4,a0
    800013c2:	89ae                	mv	s3,a1
    800013c4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013c6:	fffff097          	auipc	ra,0xfffff
    800013ca:	75a080e7          	jalr	1882(ra) # 80000b20 <kalloc>
    800013ce:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013d0:	6605                	lui	a2,0x1
    800013d2:	4581                	li	a1,0
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	938080e7          	jalr	-1736(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013dc:	4779                	li	a4,30
    800013de:	86ca                	mv	a3,s2
    800013e0:	6605                	lui	a2,0x1
    800013e2:	4581                	li	a1,0
    800013e4:	8552                	mv	a0,s4
    800013e6:	00000097          	auipc	ra,0x0
    800013ea:	d58080e7          	jalr	-680(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    800013ee:	8626                	mv	a2,s1
    800013f0:	85ce                	mv	a1,s3
    800013f2:	854a                	mv	a0,s2
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	978080e7          	jalr	-1672(ra) # 80000d6c <memmove>
}
    800013fc:	70a2                	ld	ra,40(sp)
    800013fe:	7402                	ld	s0,32(sp)
    80001400:	64e2                	ld	s1,24(sp)
    80001402:	6942                	ld	s2,16(sp)
    80001404:	69a2                	ld	s3,8(sp)
    80001406:	6a02                	ld	s4,0(sp)
    80001408:	6145                	addi	sp,sp,48
    8000140a:	8082                	ret
    panic("inituvm: more than a page");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	d1450513          	addi	a0,a0,-748 # 80008120 <digits+0xe0>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	134080e7          	jalr	308(ra) # 80000548 <panic>

000000008000141c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000141c:	1101                	addi	sp,sp,-32
    8000141e:	ec06                	sd	ra,24(sp)
    80001420:	e822                	sd	s0,16(sp)
    80001422:	e426                	sd	s1,8(sp)
    80001424:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001426:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001428:	00b67d63          	bgeu	a2,a1,80001442 <uvmdealloc+0x26>
    8000142c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000142e:	6785                	lui	a5,0x1
    80001430:	17fd                	addi	a5,a5,-1
    80001432:	00f60733          	add	a4,a2,a5
    80001436:	767d                	lui	a2,0xfffff
    80001438:	8f71                	and	a4,a4,a2
    8000143a:	97ae                	add	a5,a5,a1
    8000143c:	8ff1                	and	a5,a5,a2
    8000143e:	00f76863          	bltu	a4,a5,8000144e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001442:	8526                	mv	a0,s1
    80001444:	60e2                	ld	ra,24(sp)
    80001446:	6442                	ld	s0,16(sp)
    80001448:	64a2                	ld	s1,8(sp)
    8000144a:	6105                	addi	sp,sp,32
    8000144c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000144e:	8f99                	sub	a5,a5,a4
    80001450:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001452:	4685                	li	a3,1
    80001454:	0007861b          	sext.w	a2,a5
    80001458:	85ba                	mv	a1,a4
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	e7c080e7          	jalr	-388(ra) # 800012d6 <uvmunmap>
    80001462:	b7c5                	j	80001442 <uvmdealloc+0x26>

0000000080001464 <uvmalloc>:
  if(newsz < oldsz)
    80001464:	0ab66163          	bltu	a2,a1,80001506 <uvmalloc+0xa2>
{
    80001468:	7139                	addi	sp,sp,-64
    8000146a:	fc06                	sd	ra,56(sp)
    8000146c:	f822                	sd	s0,48(sp)
    8000146e:	f426                	sd	s1,40(sp)
    80001470:	f04a                	sd	s2,32(sp)
    80001472:	ec4e                	sd	s3,24(sp)
    80001474:	e852                	sd	s4,16(sp)
    80001476:	e456                	sd	s5,8(sp)
    80001478:	0080                	addi	s0,sp,64
    8000147a:	8aaa                	mv	s5,a0
    8000147c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000147e:	6985                	lui	s3,0x1
    80001480:	19fd                	addi	s3,s3,-1
    80001482:	95ce                	add	a1,a1,s3
    80001484:	79fd                	lui	s3,0xfffff
    80001486:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	08c9f063          	bgeu	s3,a2,8000150a <uvmalloc+0xa6>
    8000148e:	894e                	mv	s2,s3
    mem = kalloc();
    80001490:	fffff097          	auipc	ra,0xfffff
    80001494:	690080e7          	jalr	1680(ra) # 80000b20 <kalloc>
    80001498:	84aa                	mv	s1,a0
    if(mem == 0){
    8000149a:	c51d                	beqz	a0,800014c8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000149c:	6605                	lui	a2,0x1
    8000149e:	4581                	li	a1,0
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	86c080e7          	jalr	-1940(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014a8:	4779                	li	a4,30
    800014aa:	86a6                	mv	a3,s1
    800014ac:	6605                	lui	a2,0x1
    800014ae:	85ca                	mv	a1,s2
    800014b0:	8556                	mv	a0,s5
    800014b2:	00000097          	auipc	ra,0x0
    800014b6:	c8c080e7          	jalr	-884(ra) # 8000113e <mappages>
    800014ba:	e905                	bnez	a0,800014ea <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014bc:	6785                	lui	a5,0x1
    800014be:	993e                	add	s2,s2,a5
    800014c0:	fd4968e3          	bltu	s2,s4,80001490 <uvmalloc+0x2c>
  return newsz;
    800014c4:	8552                	mv	a0,s4
    800014c6:	a809                	j	800014d8 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014c8:	864e                	mv	a2,s3
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	f4e080e7          	jalr	-178(ra) # 8000141c <uvmdealloc>
      return 0;
    800014d6:	4501                	li	a0,0
}
    800014d8:	70e2                	ld	ra,56(sp)
    800014da:	7442                	ld	s0,48(sp)
    800014dc:	74a2                	ld	s1,40(sp)
    800014de:	7902                	ld	s2,32(sp)
    800014e0:	69e2                	ld	s3,24(sp)
    800014e2:	6a42                	ld	s4,16(sp)
    800014e4:	6aa2                	ld	s5,8(sp)
    800014e6:	6121                	addi	sp,sp,64
    800014e8:	8082                	ret
      kfree(mem);
    800014ea:	8526                	mv	a0,s1
    800014ec:	fffff097          	auipc	ra,0xfffff
    800014f0:	538080e7          	jalr	1336(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014f4:	864e                	mv	a2,s3
    800014f6:	85ca                	mv	a1,s2
    800014f8:	8556                	mv	a0,s5
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	f22080e7          	jalr	-222(ra) # 8000141c <uvmdealloc>
      return 0;
    80001502:	4501                	li	a0,0
    80001504:	bfd1                	j	800014d8 <uvmalloc+0x74>
    return oldsz;
    80001506:	852e                	mv	a0,a1
}
    80001508:	8082                	ret
  return newsz;
    8000150a:	8532                	mv	a0,a2
    8000150c:	b7f1                	j	800014d8 <uvmalloc+0x74>

000000008000150e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000150e:	7179                	addi	sp,sp,-48
    80001510:	f406                	sd	ra,40(sp)
    80001512:	f022                	sd	s0,32(sp)
    80001514:	ec26                	sd	s1,24(sp)
    80001516:	e84a                	sd	s2,16(sp)
    80001518:	e44e                	sd	s3,8(sp)
    8000151a:	e052                	sd	s4,0(sp)
    8000151c:	1800                	addi	s0,sp,48
    8000151e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001520:	84aa                	mv	s1,a0
    80001522:	6905                	lui	s2,0x1
    80001524:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001526:	4985                	li	s3,1
    80001528:	a821                	j	80001540 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000152a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000152c:	0532                	slli	a0,a0,0xc
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	fe0080e7          	jalr	-32(ra) # 8000150e <freewalk>
      pagetable[i] = 0;
    80001536:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000153a:	04a1                	addi	s1,s1,8
    8000153c:	03248163          	beq	s1,s2,8000155e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001540:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001542:	00f57793          	andi	a5,a0,15
    80001546:	ff3782e3          	beq	a5,s3,8000152a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000154a:	8905                	andi	a0,a0,1
    8000154c:	d57d                	beqz	a0,8000153a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000154e:	00007517          	auipc	a0,0x7
    80001552:	bf250513          	addi	a0,a0,-1038 # 80008140 <digits+0x100>
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	ff2080e7          	jalr	-14(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000155e:	8552                	mv	a0,s4
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	4c4080e7          	jalr	1220(ra) # 80000a24 <kfree>
}
    80001568:	70a2                	ld	ra,40(sp)
    8000156a:	7402                	ld	s0,32(sp)
    8000156c:	64e2                	ld	s1,24(sp)
    8000156e:	6942                	ld	s2,16(sp)
    80001570:	69a2                	ld	s3,8(sp)
    80001572:	6a02                	ld	s4,0(sp)
    80001574:	6145                	addi	sp,sp,48
    80001576:	8082                	ret

0000000080001578 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001578:	1101                	addi	sp,sp,-32
    8000157a:	ec06                	sd	ra,24(sp)
    8000157c:	e822                	sd	s0,16(sp)
    8000157e:	e426                	sd	s1,8(sp)
    80001580:	1000                	addi	s0,sp,32
    80001582:	84aa                	mv	s1,a0
  if(sz > 0)
    80001584:	e999                	bnez	a1,8000159a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001586:	8526                	mv	a0,s1
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f86080e7          	jalr	-122(ra) # 8000150e <freewalk>
}
    80001590:	60e2                	ld	ra,24(sp)
    80001592:	6442                	ld	s0,16(sp)
    80001594:	64a2                	ld	s1,8(sp)
    80001596:	6105                	addi	sp,sp,32
    80001598:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000159a:	6605                	lui	a2,0x1
    8000159c:	167d                	addi	a2,a2,-1
    8000159e:	962e                	add	a2,a2,a1
    800015a0:	4685                	li	a3,1
    800015a2:	8231                	srli	a2,a2,0xc
    800015a4:	4581                	li	a1,0
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	d30080e7          	jalr	-720(ra) # 800012d6 <uvmunmap>
    800015ae:	bfe1                	j	80001586 <uvmfree+0xe>

00000000800015b0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015b0:	ca4d                	beqz	a2,80001662 <uvmcopy+0xb2>
{
    800015b2:	715d                	addi	sp,sp,-80
    800015b4:	e486                	sd	ra,72(sp)
    800015b6:	e0a2                	sd	s0,64(sp)
    800015b8:	fc26                	sd	s1,56(sp)
    800015ba:	f84a                	sd	s2,48(sp)
    800015bc:	f44e                	sd	s3,40(sp)
    800015be:	f052                	sd	s4,32(sp)
    800015c0:	ec56                	sd	s5,24(sp)
    800015c2:	e85a                	sd	s6,16(sp)
    800015c4:	e45e                	sd	s7,8(sp)
    800015c6:	0880                	addi	s0,sp,80
    800015c8:	8aaa                	mv	s5,a0
    800015ca:	8b2e                	mv	s6,a1
    800015cc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015ce:	4481                	li	s1,0
    800015d0:	a029                	j	800015da <uvmcopy+0x2a>
    800015d2:	6785                	lui	a5,0x1
    800015d4:	94be                	add	s1,s1,a5
    800015d6:	0744fa63          	bgeu	s1,s4,8000164a <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800015da:	4601                	li	a2,0
    800015dc:	85a6                	mv	a1,s1
    800015de:	8556                	mv	a0,s5
    800015e0:	00000097          	auipc	ra,0x0
    800015e4:	a18080e7          	jalr	-1512(ra) # 80000ff8 <walk>
    800015e8:	d56d                	beqz	a0,800015d2 <uvmcopy+0x22>
      // panic("uvmcopy: pte should exist");
      continue;
    if((*pte & PTE_V) == 0)
    800015ea:	6118                	ld	a4,0(a0)
    800015ec:	00177793          	andi	a5,a4,1
    800015f0:	d3ed                	beqz	a5,800015d2 <uvmcopy+0x22>
      // panic("uvmcopy: page not present");
      continue;
    pa = PTE2PA(*pte);
    800015f2:	00a75593          	srli	a1,a4,0xa
    800015f6:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015fa:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	522080e7          	jalr	1314(ra) # 80000b20 <kalloc>
    80001606:	89aa                	mv	s3,a0
    80001608:	c515                	beqz	a0,80001634 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000160a:	6605                	lui	a2,0x1
    8000160c:	85de                	mv	a1,s7
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	75e080e7          	jalr	1886(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001616:	874a                	mv	a4,s2
    80001618:	86ce                	mv	a3,s3
    8000161a:	6605                	lui	a2,0x1
    8000161c:	85a6                	mv	a1,s1
    8000161e:	855a                	mv	a0,s6
    80001620:	00000097          	auipc	ra,0x0
    80001624:	b1e080e7          	jalr	-1250(ra) # 8000113e <mappages>
    80001628:	d54d                	beqz	a0,800015d2 <uvmcopy+0x22>
      kfree(mem);
    8000162a:	854e                	mv	a0,s3
    8000162c:	fffff097          	auipc	ra,0xfffff
    80001630:	3f8080e7          	jalr	1016(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001634:	4685                	li	a3,1
    80001636:	00c4d613          	srli	a2,s1,0xc
    8000163a:	4581                	li	a1,0
    8000163c:	855a                	mv	a0,s6
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	c98080e7          	jalr	-872(ra) # 800012d6 <uvmunmap>
  return -1;
    80001646:	557d                	li	a0,-1
    80001648:	a011                	j	8000164c <uvmcopy+0x9c>
  return 0;
    8000164a:	4501                	li	a0,0
}
    8000164c:	60a6                	ld	ra,72(sp)
    8000164e:	6406                	ld	s0,64(sp)
    80001650:	74e2                	ld	s1,56(sp)
    80001652:	7942                	ld	s2,48(sp)
    80001654:	79a2                	ld	s3,40(sp)
    80001656:	7a02                	ld	s4,32(sp)
    80001658:	6ae2                	ld	s5,24(sp)
    8000165a:	6b42                	ld	s6,16(sp)
    8000165c:	6ba2                	ld	s7,8(sp)
    8000165e:	6161                	addi	sp,sp,80
    80001660:	8082                	ret
  return 0;
    80001662:	4501                	li	a0,0
}
    80001664:	8082                	ret

0000000080001666 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001666:	1141                	addi	sp,sp,-16
    80001668:	e406                	sd	ra,8(sp)
    8000166a:	e022                	sd	s0,0(sp)
    8000166c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000166e:	4601                	li	a2,0
    80001670:	00000097          	auipc	ra,0x0
    80001674:	988080e7          	jalr	-1656(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001678:	c901                	beqz	a0,80001688 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000167a:	611c                	ld	a5,0(a0)
    8000167c:	9bbd                	andi	a5,a5,-17
    8000167e:	e11c                	sd	a5,0(a0)
}
    80001680:	60a2                	ld	ra,8(sp)
    80001682:	6402                	ld	s0,0(sp)
    80001684:	0141                	addi	sp,sp,16
    80001686:	8082                	ret
    panic("uvmclear");
    80001688:	00007517          	auipc	a0,0x7
    8000168c:	ac850513          	addi	a0,a0,-1336 # 80008150 <digits+0x110>
    80001690:	fffff097          	auipc	ra,0xfffff
    80001694:	eb8080e7          	jalr	-328(ra) # 80000548 <panic>

0000000080001698 <uvmlazytouch>:

// touch a lazy-allocated page so it's mapped to an actual physical page.
void uvmlazytouch(uint64 va) {
    80001698:	7179                	addi	sp,sp,-48
    8000169a:	f406                	sd	ra,40(sp)
    8000169c:	f022                	sd	s0,32(sp)
    8000169e:	ec26                	sd	s1,24(sp)
    800016a0:	e84a                	sd	s2,16(sp)
    800016a2:	e44e                	sd	s3,8(sp)
    800016a4:	1800                	addi	s0,sp,48
    800016a6:	89aa                	mv	s3,a0
  struct proc *p = myproc();
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	416080e7          	jalr	1046(ra) # 80001abe <myproc>
    800016b0:	892a                	mv	s2,a0
  char *mem = kalloc();
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	46e080e7          	jalr	1134(ra) # 80000b20 <kalloc>
  if(mem == 0) {
    800016ba:	cd05                	beqz	a0,800016f2 <uvmlazytouch+0x5a>
    800016bc:	84aa                	mv	s1,a0
    // failed to allocate physical memory
    printf("lazy alloc: out of memory\n");
    p->killed = 1;
  } else {
    memset(mem, 0, PGSIZE);
    800016be:	6605                	lui	a2,0x1
    800016c0:	4581                	li	a1,0
    800016c2:	fffff097          	auipc	ra,0xfffff
    800016c6:	64a080e7          	jalr	1610(ra) # 80000d0c <memset>
    if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800016ca:	4779                	li	a4,30
    800016cc:	86a6                	mv	a3,s1
    800016ce:	6605                	lui	a2,0x1
    800016d0:	75fd                	lui	a1,0xfffff
    800016d2:	00b9f5b3          	and	a1,s3,a1
    800016d6:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    800016da:	00000097          	auipc	ra,0x0
    800016de:	a64080e7          	jalr	-1436(ra) # 8000113e <mappages>
    800016e2:	e505                	bnez	a0,8000170a <uvmlazytouch+0x72>
      kfree(mem);
      p->killed = 1;
    }
  }
  // printf("lazy alloc: %p, p->sz: %p\n", PGROUNDDOWN(va), p->sz);
}
    800016e4:	70a2                	ld	ra,40(sp)
    800016e6:	7402                	ld	s0,32(sp)
    800016e8:	64e2                	ld	s1,24(sp)
    800016ea:	6942                	ld	s2,16(sp)
    800016ec:	69a2                	ld	s3,8(sp)
    800016ee:	6145                	addi	sp,sp,48
    800016f0:	8082                	ret
    printf("lazy alloc: out of memory\n");
    800016f2:	00007517          	auipc	a0,0x7
    800016f6:	a6e50513          	addi	a0,a0,-1426 # 80008160 <digits+0x120>
    800016fa:	fffff097          	auipc	ra,0xfffff
    800016fe:	e98080e7          	jalr	-360(ra) # 80000592 <printf>
    p->killed = 1;
    80001702:	4785                	li	a5,1
    80001704:	02f92823          	sw	a5,48(s2)
    80001708:	bff1                	j	800016e4 <uvmlazytouch+0x4c>
      printf("lazy alloc: failed to map page\n");
    8000170a:	00007517          	auipc	a0,0x7
    8000170e:	a7650513          	addi	a0,a0,-1418 # 80008180 <digits+0x140>
    80001712:	fffff097          	auipc	ra,0xfffff
    80001716:	e80080e7          	jalr	-384(ra) # 80000592 <printf>
      kfree(mem);
    8000171a:	8526                	mv	a0,s1
    8000171c:	fffff097          	auipc	ra,0xfffff
    80001720:	308080e7          	jalr	776(ra) # 80000a24 <kfree>
      p->killed = 1;
    80001724:	4785                	li	a5,1
    80001726:	02f92823          	sw	a5,48(s2)
}
    8000172a:	bf6d                	j	800016e4 <uvmlazytouch+0x4c>

000000008000172c <uvmshouldtouch>:

// whether a page is previously lazy-allocated and needed to be touched before use.
int uvmshouldtouch(uint64 va) {
    8000172c:	1101                	addi	sp,sp,-32
    8000172e:	ec06                	sd	ra,24(sp)
    80001730:	e822                	sd	s0,16(sp)
    80001732:	e426                	sd	s1,8(sp)
    80001734:	1000                	addi	s0,sp,32
    80001736:	84aa                	mv	s1,a0
  pte_t *pte;
  struct proc *p = myproc();
    80001738:	00000097          	auipc	ra,0x0
    8000173c:	386080e7          	jalr	902(ra) # 80001abe <myproc>
  
  return va < p->sz // within size of memory for the process
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80001740:	6538                	ld	a4,72(a0)
    80001742:	02e4f863          	bgeu	s1,a4,80001772 <uvmshouldtouch+0x46>
    80001746:	87aa                	mv	a5,a0
  asm volatile("mv %0, sp" : "=r" (x) );
    80001748:	868a                	mv	a3,sp
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    8000174a:	777d                	lui	a4,0xfffff
    8000174c:	8f65                	and	a4,a4,s1
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    8000174e:	4501                	li	a0,0
    && PGROUNDDOWN(va) != r_sp() // not accessing stack guard page (it shouldn't be mapped)
    80001750:	02d70263          	beq	a4,a3,80001774 <uvmshouldtouch+0x48>
    && (((pte = walk(p->pagetable, va, 0))==0) || ((*pte & PTE_V)==0)); // page table entry does not exist
    80001754:	4601                	li	a2,0
    80001756:	85a6                	mv	a1,s1
    80001758:	6ba8                	ld	a0,80(a5)
    8000175a:	00000097          	auipc	ra,0x0
    8000175e:	89e080e7          	jalr	-1890(ra) # 80000ff8 <walk>
    80001762:	87aa                	mv	a5,a0
    80001764:	4505                	li	a0,1
    80001766:	c799                	beqz	a5,80001774 <uvmshouldtouch+0x48>
    80001768:	6388                	ld	a0,0(a5)
    8000176a:	00154513          	xori	a0,a0,1
    8000176e:	8905                	andi	a0,a0,1
    80001770:	a011                	j	80001774 <uvmshouldtouch+0x48>
    80001772:	4501                	li	a0,0
}
    80001774:	60e2                	ld	ra,24(sp)
    80001776:	6442                	ld	s0,16(sp)
    80001778:	64a2                	ld	s1,8(sp)
    8000177a:	6105                	addi	sp,sp,32
    8000177c:	8082                	ret

000000008000177e <copyout>:
// Copy from kernel to user.
// Copy len bytes from src to virtual address dstva in a given page table.
// Return 0 on success, -1 on error.
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
    8000177e:	715d                	addi	sp,sp,-80
    80001780:	e486                	sd	ra,72(sp)
    80001782:	e0a2                	sd	s0,64(sp)
    80001784:	fc26                	sd	s1,56(sp)
    80001786:	f84a                	sd	s2,48(sp)
    80001788:	f44e                	sd	s3,40(sp)
    8000178a:	f052                	sd	s4,32(sp)
    8000178c:	ec56                	sd	s5,24(sp)
    8000178e:	e85a                	sd	s6,16(sp)
    80001790:	e45e                	sd	s7,8(sp)
    80001792:	e062                	sd	s8,0(sp)
    80001794:	0880                	addi	s0,sp,80
    80001796:	8b2a                	mv	s6,a0
    80001798:	8c2e                	mv	s8,a1
    8000179a:	8a32                	mv	s4,a2
    8000179c:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(uvmshouldtouch(dstva))
    8000179e:	852e                	mv	a0,a1
    800017a0:	00000097          	auipc	ra,0x0
    800017a4:	f8c080e7          	jalr	-116(ra) # 8000172c <uvmshouldtouch>
    800017a8:	e511                	bnez	a0,800017b4 <copyout+0x36>
    uvmlazytouch(dstva);

  while(len > 0){
    800017aa:	04098e63          	beqz	s3,80001806 <copyout+0x88>
    va0 = PGROUNDDOWN(dstva);
    800017ae:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017b0:	6a85                	lui	s5,0x1
    800017b2:	a805                	j	800017e2 <copyout+0x64>
    uvmlazytouch(dstva);
    800017b4:	8562                	mv	a0,s8
    800017b6:	00000097          	auipc	ra,0x0
    800017ba:	ee2080e7          	jalr	-286(ra) # 80001698 <uvmlazytouch>
    800017be:	b7f5                	j	800017aa <copyout+0x2c>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017c0:	9562                	add	a0,a0,s8
    800017c2:	0004861b          	sext.w	a2,s1
    800017c6:	85d2                	mv	a1,s4
    800017c8:	41250533          	sub	a0,a0,s2
    800017cc:	fffff097          	auipc	ra,0xfffff
    800017d0:	5a0080e7          	jalr	1440(ra) # 80000d6c <memmove>

    len -= n;
    800017d4:	409989b3          	sub	s3,s3,s1
    src += n;
    800017d8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017da:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017de:	02098263          	beqz	s3,80001802 <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    800017e2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017e6:	85ca                	mv	a1,s2
    800017e8:	855a                	mv	a0,s6
    800017ea:	00000097          	auipc	ra,0x0
    800017ee:	8b4080e7          	jalr	-1868(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017f2:	cd01                	beqz	a0,8000180a <copyout+0x8c>
    n = PGSIZE - (dstva - va0);
    800017f4:	418904b3          	sub	s1,s2,s8
    800017f8:	94d6                	add	s1,s1,s5
    if(n > len)
    800017fa:	fc99f3e3          	bgeu	s3,s1,800017c0 <copyout+0x42>
    800017fe:	84ce                	mv	s1,s3
    80001800:	b7c1                	j	800017c0 <copyout+0x42>
  }
  return 0;
    80001802:	4501                	li	a0,0
    80001804:	a021                	j	8000180c <copyout+0x8e>
    80001806:	4501                	li	a0,0
    80001808:	a011                	j	8000180c <copyout+0x8e>
      return -1;
    8000180a:	557d                	li	a0,-1
}
    8000180c:	60a6                	ld	ra,72(sp)
    8000180e:	6406                	ld	s0,64(sp)
    80001810:	74e2                	ld	s1,56(sp)
    80001812:	7942                	ld	s2,48(sp)
    80001814:	79a2                	ld	s3,40(sp)
    80001816:	7a02                	ld	s4,32(sp)
    80001818:	6ae2                	ld	s5,24(sp)
    8000181a:	6b42                	ld	s6,16(sp)
    8000181c:	6ba2                	ld	s7,8(sp)
    8000181e:	6c02                	ld	s8,0(sp)
    80001820:	6161                	addi	sp,sp,80
    80001822:	8082                	ret

0000000080001824 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001824:	715d                	addi	sp,sp,-80
    80001826:	e486                	sd	ra,72(sp)
    80001828:	e0a2                	sd	s0,64(sp)
    8000182a:	fc26                	sd	s1,56(sp)
    8000182c:	f84a                	sd	s2,48(sp)
    8000182e:	f44e                	sd	s3,40(sp)
    80001830:	f052                	sd	s4,32(sp)
    80001832:	ec56                	sd	s5,24(sp)
    80001834:	e85a                	sd	s6,16(sp)
    80001836:	e45e                	sd	s7,8(sp)
    80001838:	e062                	sd	s8,0(sp)
    8000183a:	0880                	addi	s0,sp,80
    8000183c:	8b2a                	mv	s6,a0
    8000183e:	8a2e                	mv	s4,a1
    80001840:	8c32                	mv	s8,a2
    80001842:	89b6                	mv	s3,a3
  uint64 n, va0, pa0;

  if(uvmshouldtouch(srcva))
    80001844:	8532                	mv	a0,a2
    80001846:	00000097          	auipc	ra,0x0
    8000184a:	ee6080e7          	jalr	-282(ra) # 8000172c <uvmshouldtouch>
    8000184e:	e511                	bnez	a0,8000185a <copyin+0x36>
    uvmlazytouch(srcva);

  while(len > 0){
    80001850:	04098e63          	beqz	s3,800018ac <copyin+0x88>
    va0 = PGROUNDDOWN(srcva);
    80001854:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001856:	6a85                	lui	s5,0x1
    80001858:	a805                	j	80001888 <copyin+0x64>
    uvmlazytouch(srcva);
    8000185a:	8562                	mv	a0,s8
    8000185c:	00000097          	auipc	ra,0x0
    80001860:	e3c080e7          	jalr	-452(ra) # 80001698 <uvmlazytouch>
    80001864:	b7f5                	j	80001850 <copyin+0x2c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001866:	9562                	add	a0,a0,s8
    80001868:	0004861b          	sext.w	a2,s1
    8000186c:	412505b3          	sub	a1,a0,s2
    80001870:	8552                	mv	a0,s4
    80001872:	fffff097          	auipc	ra,0xfffff
    80001876:	4fa080e7          	jalr	1274(ra) # 80000d6c <memmove>

    len -= n;
    8000187a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000187e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001880:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001884:	02098263          	beqz	s3,800018a8 <copyin+0x84>
    va0 = PGROUNDDOWN(srcva);
    80001888:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000188c:	85ca                	mv	a1,s2
    8000188e:	855a                	mv	a0,s6
    80001890:	00000097          	auipc	ra,0x0
    80001894:	80e080e7          	jalr	-2034(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    80001898:	cd01                	beqz	a0,800018b0 <copyin+0x8c>
    n = PGSIZE - (srcva - va0);
    8000189a:	418904b3          	sub	s1,s2,s8
    8000189e:	94d6                	add	s1,s1,s5
    if(n > len)
    800018a0:	fc99f3e3          	bgeu	s3,s1,80001866 <copyin+0x42>
    800018a4:	84ce                	mv	s1,s3
    800018a6:	b7c1                	j	80001866 <copyin+0x42>
  }
  return 0;
    800018a8:	4501                	li	a0,0
    800018aa:	a021                	j	800018b2 <copyin+0x8e>
    800018ac:	4501                	li	a0,0
    800018ae:	a011                	j	800018b2 <copyin+0x8e>
      return -1;
    800018b0:	557d                	li	a0,-1
}
    800018b2:	60a6                	ld	ra,72(sp)
    800018b4:	6406                	ld	s0,64(sp)
    800018b6:	74e2                	ld	s1,56(sp)
    800018b8:	7942                	ld	s2,48(sp)
    800018ba:	79a2                	ld	s3,40(sp)
    800018bc:	7a02                	ld	s4,32(sp)
    800018be:	6ae2                	ld	s5,24(sp)
    800018c0:	6b42                	ld	s6,16(sp)
    800018c2:	6ba2                	ld	s7,8(sp)
    800018c4:	6c02                	ld	s8,0(sp)
    800018c6:	6161                	addi	sp,sp,80
    800018c8:	8082                	ret

00000000800018ca <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ca:	c6c5                	beqz	a3,80001972 <copyinstr+0xa8>
{
    800018cc:	715d                	addi	sp,sp,-80
    800018ce:	e486                	sd	ra,72(sp)
    800018d0:	e0a2                	sd	s0,64(sp)
    800018d2:	fc26                	sd	s1,56(sp)
    800018d4:	f84a                	sd	s2,48(sp)
    800018d6:	f44e                	sd	s3,40(sp)
    800018d8:	f052                	sd	s4,32(sp)
    800018da:	ec56                	sd	s5,24(sp)
    800018dc:	e85a                	sd	s6,16(sp)
    800018de:	e45e                	sd	s7,8(sp)
    800018e0:	0880                	addi	s0,sp,80
    800018e2:	8a2a                	mv	s4,a0
    800018e4:	8b2e                	mv	s6,a1
    800018e6:	8bb2                	mv	s7,a2
    800018e8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018ea:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018ec:	6985                	lui	s3,0x1
    800018ee:	a035                	j	8000191a <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018f0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018f4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018f6:	0017b793          	seqz	a5,a5
    800018fa:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018fe:	60a6                	ld	ra,72(sp)
    80001900:	6406                	ld	s0,64(sp)
    80001902:	74e2                	ld	s1,56(sp)
    80001904:	7942                	ld	s2,48(sp)
    80001906:	79a2                	ld	s3,40(sp)
    80001908:	7a02                	ld	s4,32(sp)
    8000190a:	6ae2                	ld	s5,24(sp)
    8000190c:	6b42                	ld	s6,16(sp)
    8000190e:	6ba2                	ld	s7,8(sp)
    80001910:	6161                	addi	sp,sp,80
    80001912:	8082                	ret
    srcva = va0 + PGSIZE;
    80001914:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001918:	c8a9                	beqz	s1,8000196a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000191a:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000191e:	85ca                	mv	a1,s2
    80001920:	8552                	mv	a0,s4
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	77c080e7          	jalr	1916(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    8000192a:	c131                	beqz	a0,8000196e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    8000192c:	41790833          	sub	a6,s2,s7
    80001930:	984e                	add	a6,a6,s3
    if(n > max)
    80001932:	0104f363          	bgeu	s1,a6,80001938 <copyinstr+0x6e>
    80001936:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001938:	955e                	add	a0,a0,s7
    8000193a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000193e:	fc080be3          	beqz	a6,80001914 <copyinstr+0x4a>
    80001942:	985a                	add	a6,a6,s6
    80001944:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001946:	41650633          	sub	a2,a0,s6
    8000194a:	14fd                	addi	s1,s1,-1
    8000194c:	9b26                	add	s6,s6,s1
    8000194e:	00f60733          	add	a4,a2,a5
    80001952:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001956:	df49                	beqz	a4,800018f0 <copyinstr+0x26>
        *dst = *p;
    80001958:	00e78023          	sb	a4,0(a5)
      --max;
    8000195c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001960:	0785                	addi	a5,a5,1
    while(n > 0){
    80001962:	ff0796e3          	bne	a5,a6,8000194e <copyinstr+0x84>
      dst++;
    80001966:	8b42                	mv	s6,a6
    80001968:	b775                	j	80001914 <copyinstr+0x4a>
    8000196a:	4781                	li	a5,0
    8000196c:	b769                	j	800018f6 <copyinstr+0x2c>
      return -1;
    8000196e:	557d                	li	a0,-1
    80001970:	b779                	j	800018fe <copyinstr+0x34>
  int got_null = 0;
    80001972:	4781                	li	a5,0
  if(got_null){
    80001974:	0017b793          	seqz	a5,a5
    80001978:	40f00533          	neg	a0,a5
}
    8000197c:	8082                	ret

000000008000197e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000197e:	1101                	addi	sp,sp,-32
    80001980:	ec06                	sd	ra,24(sp)
    80001982:	e822                	sd	s0,16(sp)
    80001984:	e426                	sd	s1,8(sp)
    80001986:	1000                	addi	s0,sp,32
    80001988:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000198a:	fffff097          	auipc	ra,0xfffff
    8000198e:	20c080e7          	jalr	524(ra) # 80000b96 <holding>
    80001992:	c909                	beqz	a0,800019a4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001994:	749c                	ld	a5,40(s1)
    80001996:	00978f63          	beq	a5,s1,800019b4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000199a:	60e2                	ld	ra,24(sp)
    8000199c:	6442                	ld	s0,16(sp)
    8000199e:	64a2                	ld	s1,8(sp)
    800019a0:	6105                	addi	sp,sp,32
    800019a2:	8082                	ret
    panic("wakeup1");
    800019a4:	00006517          	auipc	a0,0x6
    800019a8:	7fc50513          	addi	a0,a0,2044 # 800081a0 <digits+0x160>
    800019ac:	fffff097          	auipc	ra,0xfffff
    800019b0:	b9c080e7          	jalr	-1124(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019b4:	4c98                	lw	a4,24(s1)
    800019b6:	4785                	li	a5,1
    800019b8:	fef711e3          	bne	a4,a5,8000199a <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019bc:	4789                	li	a5,2
    800019be:	cc9c                	sw	a5,24(s1)
}
    800019c0:	bfe9                	j	8000199a <wakeup1+0x1c>

00000000800019c2 <procinit>:
{
    800019c2:	715d                	addi	sp,sp,-80
    800019c4:	e486                	sd	ra,72(sp)
    800019c6:	e0a2                	sd	s0,64(sp)
    800019c8:	fc26                	sd	s1,56(sp)
    800019ca:	f84a                	sd	s2,48(sp)
    800019cc:	f44e                	sd	s3,40(sp)
    800019ce:	f052                	sd	s4,32(sp)
    800019d0:	ec56                	sd	s5,24(sp)
    800019d2:	e85a                	sd	s6,16(sp)
    800019d4:	e45e                	sd	s7,8(sp)
    800019d6:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019d8:	00006597          	auipc	a1,0x6
    800019dc:	7d058593          	addi	a1,a1,2000 # 800081a8 <digits+0x168>
    800019e0:	00010517          	auipc	a0,0x10
    800019e4:	f7050513          	addi	a0,a0,-144 # 80011950 <pid_lock>
    800019e8:	fffff097          	auipc	ra,0xfffff
    800019ec:	198080e7          	jalr	408(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f0:	00010917          	auipc	s2,0x10
    800019f4:	37890913          	addi	s2,s2,888 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019f8:	00006b97          	auipc	s7,0x6
    800019fc:	7b8b8b93          	addi	s7,s7,1976 # 800081b0 <digits+0x170>
      uint64 va = KSTACK((int) (p - proc));
    80001a00:	8b4a                	mv	s6,s2
    80001a02:	00006a97          	auipc	s5,0x6
    80001a06:	5fea8a93          	addi	s5,s5,1534 # 80008000 <etext>
    80001a0a:	040009b7          	lui	s3,0x4000
    80001a0e:	19fd                	addi	s3,s3,-1
    80001a10:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a12:	00016a17          	auipc	s4,0x16
    80001a16:	d56a0a13          	addi	s4,s4,-682 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a1a:	85de                	mv	a1,s7
    80001a1c:	854a                	mv	a0,s2
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	162080e7          	jalr	354(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	0fa080e7          	jalr	250(ra) # 80000b20 <kalloc>
    80001a2e:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a30:	c929                	beqz	a0,80001a82 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a32:	416904b3          	sub	s1,s2,s6
    80001a36:	848d                	srai	s1,s1,0x3
    80001a38:	000ab783          	ld	a5,0(s5)
    80001a3c:	02f484b3          	mul	s1,s1,a5
    80001a40:	2485                	addiw	s1,s1,1
    80001a42:	00d4949b          	slliw	s1,s1,0xd
    80001a46:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a4a:	4699                	li	a3,6
    80001a4c:	6605                	lui	a2,0x1
    80001a4e:	8526                	mv	a0,s1
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	77c080e7          	jalr	1916(ra) # 800011cc <kvmmap>
      p->kstack = va;
    80001a58:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5c:	16890913          	addi	s2,s2,360
    80001a60:	fb491de3          	bne	s2,s4,80001a1a <procinit+0x58>
  kvminithart();
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	570080e7          	jalr	1392(ra) # 80000fd4 <kvminithart>
}
    80001a6c:	60a6                	ld	ra,72(sp)
    80001a6e:	6406                	ld	s0,64(sp)
    80001a70:	74e2                	ld	s1,56(sp)
    80001a72:	7942                	ld	s2,48(sp)
    80001a74:	79a2                	ld	s3,40(sp)
    80001a76:	7a02                	ld	s4,32(sp)
    80001a78:	6ae2                	ld	s5,24(sp)
    80001a7a:	6b42                	ld	s6,16(sp)
    80001a7c:	6ba2                	ld	s7,8(sp)
    80001a7e:	6161                	addi	sp,sp,80
    80001a80:	8082                	ret
        panic("kalloc");
    80001a82:	00006517          	auipc	a0,0x6
    80001a86:	73650513          	addi	a0,a0,1846 # 800081b8 <digits+0x178>
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	abe080e7          	jalr	-1346(ra) # 80000548 <panic>

0000000080001a92 <cpuid>:
{
    80001a92:	1141                	addi	sp,sp,-16
    80001a94:	e422                	sd	s0,8(sp)
    80001a96:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a98:	8512                	mv	a0,tp
}
    80001a9a:	2501                	sext.w	a0,a0
    80001a9c:	6422                	ld	s0,8(sp)
    80001a9e:	0141                	addi	sp,sp,16
    80001aa0:	8082                	ret

0000000080001aa2 <mycpu>:
mycpu(void) {
    80001aa2:	1141                	addi	sp,sp,-16
    80001aa4:	e422                	sd	s0,8(sp)
    80001aa6:	0800                	addi	s0,sp,16
    80001aa8:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001aaa:	2781                	sext.w	a5,a5
    80001aac:	079e                	slli	a5,a5,0x7
}
    80001aae:	00010517          	auipc	a0,0x10
    80001ab2:	eba50513          	addi	a0,a0,-326 # 80011968 <cpus>
    80001ab6:	953e                	add	a0,a0,a5
    80001ab8:	6422                	ld	s0,8(sp)
    80001aba:	0141                	addi	sp,sp,16
    80001abc:	8082                	ret

0000000080001abe <myproc>:
myproc(void) {
    80001abe:	1101                	addi	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	1000                	addi	s0,sp,32
  push_off();
    80001ac8:	fffff097          	auipc	ra,0xfffff
    80001acc:	0fc080e7          	jalr	252(ra) # 80000bc4 <push_off>
    80001ad0:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ad2:	2781                	sext.w	a5,a5
    80001ad4:	079e                	slli	a5,a5,0x7
    80001ad6:	00010717          	auipc	a4,0x10
    80001ada:	e7a70713          	addi	a4,a4,-390 # 80011950 <pid_lock>
    80001ade:	97ba                	add	a5,a5,a4
    80001ae0:	6f84                	ld	s1,24(a5)
  pop_off();
    80001ae2:	fffff097          	auipc	ra,0xfffff
    80001ae6:	182080e7          	jalr	386(ra) # 80000c64 <pop_off>
}
    80001aea:	8526                	mv	a0,s1
    80001aec:	60e2                	ld	ra,24(sp)
    80001aee:	6442                	ld	s0,16(sp)
    80001af0:	64a2                	ld	s1,8(sp)
    80001af2:	6105                	addi	sp,sp,32
    80001af4:	8082                	ret

0000000080001af6 <forkret>:
{
    80001af6:	1141                	addi	sp,sp,-16
    80001af8:	e406                	sd	ra,8(sp)
    80001afa:	e022                	sd	s0,0(sp)
    80001afc:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001afe:	00000097          	auipc	ra,0x0
    80001b02:	fc0080e7          	jalr	-64(ra) # 80001abe <myproc>
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	1be080e7          	jalr	446(ra) # 80000cc4 <release>
  if (first) {
    80001b0e:	00007797          	auipc	a5,0x7
    80001b12:	ce27a783          	lw	a5,-798(a5) # 800087f0 <first.1666>
    80001b16:	eb89                	bnez	a5,80001b28 <forkret+0x32>
  usertrapret();
    80001b18:	00001097          	auipc	ra,0x1
    80001b1c:	c1c080e7          	jalr	-996(ra) # 80002734 <usertrapret>
}
    80001b20:	60a2                	ld	ra,8(sp)
    80001b22:	6402                	ld	s0,0(sp)
    80001b24:	0141                	addi	sp,sp,16
    80001b26:	8082                	ret
    first = 0;
    80001b28:	00007797          	auipc	a5,0x7
    80001b2c:	cc07a423          	sw	zero,-824(a5) # 800087f0 <first.1666>
    fsinit(ROOTDEV);
    80001b30:	4505                	li	a0,1
    80001b32:	00002097          	auipc	ra,0x2
    80001b36:	98e080e7          	jalr	-1650(ra) # 800034c0 <fsinit>
    80001b3a:	bff9                	j	80001b18 <forkret+0x22>

0000000080001b3c <allocpid>:
allocpid() {
    80001b3c:	1101                	addi	sp,sp,-32
    80001b3e:	ec06                	sd	ra,24(sp)
    80001b40:	e822                	sd	s0,16(sp)
    80001b42:	e426                	sd	s1,8(sp)
    80001b44:	e04a                	sd	s2,0(sp)
    80001b46:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b48:	00010917          	auipc	s2,0x10
    80001b4c:	e0890913          	addi	s2,s2,-504 # 80011950 <pid_lock>
    80001b50:	854a                	mv	a0,s2
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	0be080e7          	jalr	190(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001b5a:	00007797          	auipc	a5,0x7
    80001b5e:	c9a78793          	addi	a5,a5,-870 # 800087f4 <nextpid>
    80001b62:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b64:	0014871b          	addiw	a4,s1,1
    80001b68:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b6a:	854a                	mv	a0,s2
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	158080e7          	jalr	344(ra) # 80000cc4 <release>
}
    80001b74:	8526                	mv	a0,s1
    80001b76:	60e2                	ld	ra,24(sp)
    80001b78:	6442                	ld	s0,16(sp)
    80001b7a:	64a2                	ld	s1,8(sp)
    80001b7c:	6902                	ld	s2,0(sp)
    80001b7e:	6105                	addi	sp,sp,32
    80001b80:	8082                	ret

0000000080001b82 <proc_pagetable>:
{
    80001b82:	1101                	addi	sp,sp,-32
    80001b84:	ec06                	sd	ra,24(sp)
    80001b86:	e822                	sd	s0,16(sp)
    80001b88:	e426                	sd	s1,8(sp)
    80001b8a:	e04a                	sd	s2,0(sp)
    80001b8c:	1000                	addi	s0,sp,32
    80001b8e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b90:	fffff097          	auipc	ra,0xfffff
    80001b94:	7ec080e7          	jalr	2028(ra) # 8000137c <uvmcreate>
    80001b98:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b9a:	c121                	beqz	a0,80001bda <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b9c:	4729                	li	a4,10
    80001b9e:	00005697          	auipc	a3,0x5
    80001ba2:	46268693          	addi	a3,a3,1122 # 80007000 <_trampoline>
    80001ba6:	6605                	lui	a2,0x1
    80001ba8:	040005b7          	lui	a1,0x4000
    80001bac:	15fd                	addi	a1,a1,-1
    80001bae:	05b2                	slli	a1,a1,0xc
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	58e080e7          	jalr	1422(ra) # 8000113e <mappages>
    80001bb8:	02054863          	bltz	a0,80001be8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bbc:	4719                	li	a4,6
    80001bbe:	05893683          	ld	a3,88(s2)
    80001bc2:	6605                	lui	a2,0x1
    80001bc4:	020005b7          	lui	a1,0x2000
    80001bc8:	15fd                	addi	a1,a1,-1
    80001bca:	05b6                	slli	a1,a1,0xd
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	570080e7          	jalr	1392(ra) # 8000113e <mappages>
    80001bd6:	02054163          	bltz	a0,80001bf8 <proc_pagetable+0x76>
}
    80001bda:	8526                	mv	a0,s1
    80001bdc:	60e2                	ld	ra,24(sp)
    80001bde:	6442                	ld	s0,16(sp)
    80001be0:	64a2                	ld	s1,8(sp)
    80001be2:	6902                	ld	s2,0(sp)
    80001be4:	6105                	addi	sp,sp,32
    80001be6:	8082                	ret
    uvmfree(pagetable, 0);
    80001be8:	4581                	li	a1,0
    80001bea:	8526                	mv	a0,s1
    80001bec:	00000097          	auipc	ra,0x0
    80001bf0:	98c080e7          	jalr	-1652(ra) # 80001578 <uvmfree>
    return 0;
    80001bf4:	4481                	li	s1,0
    80001bf6:	b7d5                	j	80001bda <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bf8:	4681                	li	a3,0
    80001bfa:	4605                	li	a2,1
    80001bfc:	040005b7          	lui	a1,0x4000
    80001c00:	15fd                	addi	a1,a1,-1
    80001c02:	05b2                	slli	a1,a1,0xc
    80001c04:	8526                	mv	a0,s1
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	6d0080e7          	jalr	1744(ra) # 800012d6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c0e:	4581                	li	a1,0
    80001c10:	8526                	mv	a0,s1
    80001c12:	00000097          	auipc	ra,0x0
    80001c16:	966080e7          	jalr	-1690(ra) # 80001578 <uvmfree>
    return 0;
    80001c1a:	4481                	li	s1,0
    80001c1c:	bf7d                	j	80001bda <proc_pagetable+0x58>

0000000080001c1e <proc_freepagetable>:
{
    80001c1e:	1101                	addi	sp,sp,-32
    80001c20:	ec06                	sd	ra,24(sp)
    80001c22:	e822                	sd	s0,16(sp)
    80001c24:	e426                	sd	s1,8(sp)
    80001c26:	e04a                	sd	s2,0(sp)
    80001c28:	1000                	addi	s0,sp,32
    80001c2a:	84aa                	mv	s1,a0
    80001c2c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c2e:	4681                	li	a3,0
    80001c30:	4605                	li	a2,1
    80001c32:	040005b7          	lui	a1,0x4000
    80001c36:	15fd                	addi	a1,a1,-1
    80001c38:	05b2                	slli	a1,a1,0xc
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	69c080e7          	jalr	1692(ra) # 800012d6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c42:	4681                	li	a3,0
    80001c44:	4605                	li	a2,1
    80001c46:	020005b7          	lui	a1,0x2000
    80001c4a:	15fd                	addi	a1,a1,-1
    80001c4c:	05b6                	slli	a1,a1,0xd
    80001c4e:	8526                	mv	a0,s1
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	686080e7          	jalr	1670(ra) # 800012d6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c58:	85ca                	mv	a1,s2
    80001c5a:	8526                	mv	a0,s1
    80001c5c:	00000097          	auipc	ra,0x0
    80001c60:	91c080e7          	jalr	-1764(ra) # 80001578 <uvmfree>
}
    80001c64:	60e2                	ld	ra,24(sp)
    80001c66:	6442                	ld	s0,16(sp)
    80001c68:	64a2                	ld	s1,8(sp)
    80001c6a:	6902                	ld	s2,0(sp)
    80001c6c:	6105                	addi	sp,sp,32
    80001c6e:	8082                	ret

0000000080001c70 <freeproc>:
{
    80001c70:	1101                	addi	sp,sp,-32
    80001c72:	ec06                	sd	ra,24(sp)
    80001c74:	e822                	sd	s0,16(sp)
    80001c76:	e426                	sd	s1,8(sp)
    80001c78:	1000                	addi	s0,sp,32
    80001c7a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c7c:	6d28                	ld	a0,88(a0)
    80001c7e:	c509                	beqz	a0,80001c88 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	da4080e7          	jalr	-604(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001c88:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c8c:	68a8                	ld	a0,80(s1)
    80001c8e:	c511                	beqz	a0,80001c9a <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c90:	64ac                	ld	a1,72(s1)
    80001c92:	00000097          	auipc	ra,0x0
    80001c96:	f8c080e7          	jalr	-116(ra) # 80001c1e <proc_freepagetable>
  p->pagetable = 0;
    80001c9a:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c9e:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ca2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ca6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001caa:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cae:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001cb2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cb6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cba:	0004ac23          	sw	zero,24(s1)
}
    80001cbe:	60e2                	ld	ra,24(sp)
    80001cc0:	6442                	ld	s0,16(sp)
    80001cc2:	64a2                	ld	s1,8(sp)
    80001cc4:	6105                	addi	sp,sp,32
    80001cc6:	8082                	ret

0000000080001cc8 <allocproc>:
{
    80001cc8:	1101                	addi	sp,sp,-32
    80001cca:	ec06                	sd	ra,24(sp)
    80001ccc:	e822                	sd	s0,16(sp)
    80001cce:	e426                	sd	s1,8(sp)
    80001cd0:	e04a                	sd	s2,0(sp)
    80001cd2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd4:	00010497          	auipc	s1,0x10
    80001cd8:	09448493          	addi	s1,s1,148 # 80011d68 <proc>
    80001cdc:	00016917          	auipc	s2,0x16
    80001ce0:	a8c90913          	addi	s2,s2,-1396 # 80017768 <tickslock>
    acquire(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	f2a080e7          	jalr	-214(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001cee:	4c9c                	lw	a5,24(s1)
    80001cf0:	cf81                	beqz	a5,80001d08 <allocproc+0x40>
      release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	fd0080e7          	jalr	-48(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cfc:	16848493          	addi	s1,s1,360
    80001d00:	ff2492e3          	bne	s1,s2,80001ce4 <allocproc+0x1c>
  return 0;
    80001d04:	4481                	li	s1,0
    80001d06:	a0b9                	j	80001d54 <allocproc+0x8c>
  p->pid = allocpid();
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	e34080e7          	jalr	-460(ra) # 80001b3c <allocpid>
    80001d10:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	e0e080e7          	jalr	-498(ra) # 80000b20 <kalloc>
    80001d1a:	892a                	mv	s2,a0
    80001d1c:	eca8                	sd	a0,88(s1)
    80001d1e:	c131                	beqz	a0,80001d62 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d20:	8526                	mv	a0,s1
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	e60080e7          	jalr	-416(ra) # 80001b82 <proc_pagetable>
    80001d2a:	892a                	mv	s2,a0
    80001d2c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d2e:	c129                	beqz	a0,80001d70 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d30:	07000613          	li	a2,112
    80001d34:	4581                	li	a1,0
    80001d36:	06048513          	addi	a0,s1,96
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	fd2080e7          	jalr	-46(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001d42:	00000797          	auipc	a5,0x0
    80001d46:	db478793          	addi	a5,a5,-588 # 80001af6 <forkret>
    80001d4a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d4c:	60bc                	ld	a5,64(s1)
    80001d4e:	6705                	lui	a4,0x1
    80001d50:	97ba                	add	a5,a5,a4
    80001d52:	f4bc                	sd	a5,104(s1)
}
    80001d54:	8526                	mv	a0,s1
    80001d56:	60e2                	ld	ra,24(sp)
    80001d58:	6442                	ld	s0,16(sp)
    80001d5a:	64a2                	ld	s1,8(sp)
    80001d5c:	6902                	ld	s2,0(sp)
    80001d5e:	6105                	addi	sp,sp,32
    80001d60:	8082                	ret
    release(&p->lock);
    80001d62:	8526                	mv	a0,s1
    80001d64:	fffff097          	auipc	ra,0xfffff
    80001d68:	f60080e7          	jalr	-160(ra) # 80000cc4 <release>
    return 0;
    80001d6c:	84ca                	mv	s1,s2
    80001d6e:	b7dd                	j	80001d54 <allocproc+0x8c>
    freeproc(p);
    80001d70:	8526                	mv	a0,s1
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	efe080e7          	jalr	-258(ra) # 80001c70 <freeproc>
    release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f48080e7          	jalr	-184(ra) # 80000cc4 <release>
    return 0;
    80001d84:	84ca                	mv	s1,s2
    80001d86:	b7f9                	j	80001d54 <allocproc+0x8c>

0000000080001d88 <userinit>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d92:	00000097          	auipc	ra,0x0
    80001d96:	f36080e7          	jalr	-202(ra) # 80001cc8 <allocproc>
    80001d9a:	84aa                	mv	s1,a0
  initproc = p;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	26a7be23          	sd	a0,636(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001da4:	03400613          	li	a2,52
    80001da8:	00007597          	auipc	a1,0x7
    80001dac:	a5858593          	addi	a1,a1,-1448 # 80008800 <initcode>
    80001db0:	6928                	ld	a0,80(a0)
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	5f8080e7          	jalr	1528(ra) # 800013aa <uvminit>
  p->sz = PGSIZE;
    80001dba:	6785                	lui	a5,0x1
    80001dbc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001dbe:	6cb8                	ld	a4,88(s1)
    80001dc0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001dc4:	6cb8                	ld	a4,88(s1)
    80001dc6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dc8:	4641                	li	a2,16
    80001dca:	00006597          	auipc	a1,0x6
    80001dce:	3f658593          	addi	a1,a1,1014 # 800081c0 <digits+0x180>
    80001dd2:	15848513          	addi	a0,s1,344
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	08c080e7          	jalr	140(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001dde:	00006517          	auipc	a0,0x6
    80001de2:	3f250513          	addi	a0,a0,1010 # 800081d0 <digits+0x190>
    80001de6:	00002097          	auipc	ra,0x2
    80001dea:	106080e7          	jalr	262(ra) # 80003eec <namei>
    80001dee:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001df2:	4789                	li	a5,2
    80001df4:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001df6:	8526                	mv	a0,s1
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	ecc080e7          	jalr	-308(ra) # 80000cc4 <release>
}
    80001e00:	60e2                	ld	ra,24(sp)
    80001e02:	6442                	ld	s0,16(sp)
    80001e04:	64a2                	ld	s1,8(sp)
    80001e06:	6105                	addi	sp,sp,32
    80001e08:	8082                	ret

0000000080001e0a <growproc>:
{
    80001e0a:	1101                	addi	sp,sp,-32
    80001e0c:	ec06                	sd	ra,24(sp)
    80001e0e:	e822                	sd	s0,16(sp)
    80001e10:	e426                	sd	s1,8(sp)
    80001e12:	e04a                	sd	s2,0(sp)
    80001e14:	1000                	addi	s0,sp,32
    80001e16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	ca6080e7          	jalr	-858(ra) # 80001abe <myproc>
    80001e20:	892a                	mv	s2,a0
  sz = p->sz;
    80001e22:	652c                	ld	a1,72(a0)
    80001e24:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e28:	00904f63          	bgtz	s1,80001e46 <growproc+0x3c>
  } else if(n < 0){
    80001e2c:	0204cc63          	bltz	s1,80001e64 <growproc+0x5a>
  p->sz = sz;
    80001e30:	1602                	slli	a2,a2,0x20
    80001e32:	9201                	srli	a2,a2,0x20
    80001e34:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e38:	4501                	li	a0,0
}
    80001e3a:	60e2                	ld	ra,24(sp)
    80001e3c:	6442                	ld	s0,16(sp)
    80001e3e:	64a2                	ld	s1,8(sp)
    80001e40:	6902                	ld	s2,0(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e46:	9e25                	addw	a2,a2,s1
    80001e48:	1602                	slli	a2,a2,0x20
    80001e4a:	9201                	srli	a2,a2,0x20
    80001e4c:	1582                	slli	a1,a1,0x20
    80001e4e:	9181                	srli	a1,a1,0x20
    80001e50:	6928                	ld	a0,80(a0)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	612080e7          	jalr	1554(ra) # 80001464 <uvmalloc>
    80001e5a:	0005061b          	sext.w	a2,a0
    80001e5e:	fa69                	bnez	a2,80001e30 <growproc+0x26>
      return -1;
    80001e60:	557d                	li	a0,-1
    80001e62:	bfe1                	j	80001e3a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e64:	9e25                	addw	a2,a2,s1
    80001e66:	1602                	slli	a2,a2,0x20
    80001e68:	9201                	srli	a2,a2,0x20
    80001e6a:	1582                	slli	a1,a1,0x20
    80001e6c:	9181                	srli	a1,a1,0x20
    80001e6e:	6928                	ld	a0,80(a0)
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	5ac080e7          	jalr	1452(ra) # 8000141c <uvmdealloc>
    80001e78:	0005061b          	sext.w	a2,a0
    80001e7c:	bf55                	j	80001e30 <growproc+0x26>

0000000080001e7e <fork>:
{
    80001e7e:	7179                	addi	sp,sp,-48
    80001e80:	f406                	sd	ra,40(sp)
    80001e82:	f022                	sd	s0,32(sp)
    80001e84:	ec26                	sd	s1,24(sp)
    80001e86:	e84a                	sd	s2,16(sp)
    80001e88:	e44e                	sd	s3,8(sp)
    80001e8a:	e052                	sd	s4,0(sp)
    80001e8c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e8e:	00000097          	auipc	ra,0x0
    80001e92:	c30080e7          	jalr	-976(ra) # 80001abe <myproc>
    80001e96:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	e30080e7          	jalr	-464(ra) # 80001cc8 <allocproc>
    80001ea0:	c175                	beqz	a0,80001f84 <fork+0x106>
    80001ea2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001ea4:	04893603          	ld	a2,72(s2)
    80001ea8:	692c                	ld	a1,80(a0)
    80001eaa:	05093503          	ld	a0,80(s2)
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	702080e7          	jalr	1794(ra) # 800015b0 <uvmcopy>
    80001eb6:	04054863          	bltz	a0,80001f06 <fork+0x88>
  np->sz = p->sz;
    80001eba:	04893783          	ld	a5,72(s2)
    80001ebe:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001ec2:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ec6:	05893683          	ld	a3,88(s2)
    80001eca:	87b6                	mv	a5,a3
    80001ecc:	0589b703          	ld	a4,88(s3)
    80001ed0:	12068693          	addi	a3,a3,288
    80001ed4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001ed8:	6788                	ld	a0,8(a5)
    80001eda:	6b8c                	ld	a1,16(a5)
    80001edc:	6f90                	ld	a2,24(a5)
    80001ede:	01073023          	sd	a6,0(a4)
    80001ee2:	e708                	sd	a0,8(a4)
    80001ee4:	eb0c                	sd	a1,16(a4)
    80001ee6:	ef10                	sd	a2,24(a4)
    80001ee8:	02078793          	addi	a5,a5,32
    80001eec:	02070713          	addi	a4,a4,32
    80001ef0:	fed792e3          	bne	a5,a3,80001ed4 <fork+0x56>
  np->trapframe->a0 = 0;
    80001ef4:	0589b783          	ld	a5,88(s3)
    80001ef8:	0607b823          	sd	zero,112(a5)
    80001efc:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f00:	15000a13          	li	s4,336
    80001f04:	a03d                	j	80001f32 <fork+0xb4>
    freeproc(np);
    80001f06:	854e                	mv	a0,s3
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	d68080e7          	jalr	-664(ra) # 80001c70 <freeproc>
    release(&np->lock);
    80001f10:	854e                	mv	a0,s3
    80001f12:	fffff097          	auipc	ra,0xfffff
    80001f16:	db2080e7          	jalr	-590(ra) # 80000cc4 <release>
    return -1;
    80001f1a:	54fd                	li	s1,-1
    80001f1c:	a899                	j	80001f72 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f1e:	00002097          	auipc	ra,0x2
    80001f22:	65a080e7          	jalr	1626(ra) # 80004578 <filedup>
    80001f26:	009987b3          	add	a5,s3,s1
    80001f2a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f2c:	04a1                	addi	s1,s1,8
    80001f2e:	01448763          	beq	s1,s4,80001f3c <fork+0xbe>
    if(p->ofile[i])
    80001f32:	009907b3          	add	a5,s2,s1
    80001f36:	6388                	ld	a0,0(a5)
    80001f38:	f17d                	bnez	a0,80001f1e <fork+0xa0>
    80001f3a:	bfcd                	j	80001f2c <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f3c:	15093503          	ld	a0,336(s2)
    80001f40:	00001097          	auipc	ra,0x1
    80001f44:	7ba080e7          	jalr	1978(ra) # 800036fa <idup>
    80001f48:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f4c:	4641                	li	a2,16
    80001f4e:	15890593          	addi	a1,s2,344
    80001f52:	15898513          	addi	a0,s3,344
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	f0c080e7          	jalr	-244(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001f5e:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f62:	4789                	li	a5,2
    80001f64:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f68:	854e                	mv	a0,s3
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	d5a080e7          	jalr	-678(ra) # 80000cc4 <release>
}
    80001f72:	8526                	mv	a0,s1
    80001f74:	70a2                	ld	ra,40(sp)
    80001f76:	7402                	ld	s0,32(sp)
    80001f78:	64e2                	ld	s1,24(sp)
    80001f7a:	6942                	ld	s2,16(sp)
    80001f7c:	69a2                	ld	s3,8(sp)
    80001f7e:	6a02                	ld	s4,0(sp)
    80001f80:	6145                	addi	sp,sp,48
    80001f82:	8082                	ret
    return -1;
    80001f84:	54fd                	li	s1,-1
    80001f86:	b7f5                	j	80001f72 <fork+0xf4>

0000000080001f88 <reparent>:
{
    80001f88:	7179                	addi	sp,sp,-48
    80001f8a:	f406                	sd	ra,40(sp)
    80001f8c:	f022                	sd	s0,32(sp)
    80001f8e:	ec26                	sd	s1,24(sp)
    80001f90:	e84a                	sd	s2,16(sp)
    80001f92:	e44e                	sd	s3,8(sp)
    80001f94:	e052                	sd	s4,0(sp)
    80001f96:	1800                	addi	s0,sp,48
    80001f98:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f9a:	00010497          	auipc	s1,0x10
    80001f9e:	dce48493          	addi	s1,s1,-562 # 80011d68 <proc>
      pp->parent = initproc;
    80001fa2:	00007a17          	auipc	s4,0x7
    80001fa6:	076a0a13          	addi	s4,s4,118 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001faa:	00015997          	auipc	s3,0x15
    80001fae:	7be98993          	addi	s3,s3,1982 # 80017768 <tickslock>
    80001fb2:	a029                	j	80001fbc <reparent+0x34>
    80001fb4:	16848493          	addi	s1,s1,360
    80001fb8:	03348363          	beq	s1,s3,80001fde <reparent+0x56>
    if(pp->parent == p){
    80001fbc:	709c                	ld	a5,32(s1)
    80001fbe:	ff279be3          	bne	a5,s2,80001fb4 <reparent+0x2c>
      acquire(&pp->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c4c080e7          	jalr	-948(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001fcc:	000a3783          	ld	a5,0(s4)
    80001fd0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cf0080e7          	jalr	-784(ra) # 80000cc4 <release>
    80001fdc:	bfe1                	j	80001fb4 <reparent+0x2c>
}
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6a02                	ld	s4,0(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret

0000000080001fee <scheduler>:
{
    80001fee:	711d                	addi	sp,sp,-96
    80001ff0:	ec86                	sd	ra,88(sp)
    80001ff2:	e8a2                	sd	s0,80(sp)
    80001ff4:	e4a6                	sd	s1,72(sp)
    80001ff6:	e0ca                	sd	s2,64(sp)
    80001ff8:	fc4e                	sd	s3,56(sp)
    80001ffa:	f852                	sd	s4,48(sp)
    80001ffc:	f456                	sd	s5,40(sp)
    80001ffe:	f05a                	sd	s6,32(sp)
    80002000:	ec5e                	sd	s7,24(sp)
    80002002:	e862                	sd	s8,16(sp)
    80002004:	e466                	sd	s9,8(sp)
    80002006:	1080                	addi	s0,sp,96
    80002008:	8792                	mv	a5,tp
  int id = r_tp();
    8000200a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000200c:	00779c13          	slli	s8,a5,0x7
    80002010:	00010717          	auipc	a4,0x10
    80002014:	94070713          	addi	a4,a4,-1728 # 80011950 <pid_lock>
    80002018:	9762                	add	a4,a4,s8
    8000201a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000201e:	00010717          	auipc	a4,0x10
    80002022:	95270713          	addi	a4,a4,-1710 # 80011970 <cpus+0x8>
    80002026:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002028:	4a89                	li	s5,2
        c->proc = p;
    8000202a:	079e                	slli	a5,a5,0x7
    8000202c:	00010b17          	auipc	s6,0x10
    80002030:	924b0b13          	addi	s6,s6,-1756 # 80011950 <pid_lock>
    80002034:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002036:	00015a17          	auipc	s4,0x15
    8000203a:	732a0a13          	addi	s4,s4,1842 # 80017768 <tickslock>
    int nproc = 0;
    8000203e:	4c81                	li	s9,0
    80002040:	a8a1                	j	80002098 <scheduler+0xaa>
        p->state = RUNNING;
    80002042:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002046:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000204a:	06048593          	addi	a1,s1,96
    8000204e:	8562                	mv	a0,s8
    80002050:	00000097          	auipc	ra,0x0
    80002054:	63a080e7          	jalr	1594(ra) # 8000268a <swtch>
        c->proc = 0;
    80002058:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000205c:	8526                	mv	a0,s1
    8000205e:	fffff097          	auipc	ra,0xfffff
    80002062:	c66080e7          	jalr	-922(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002066:	16848493          	addi	s1,s1,360
    8000206a:	01448d63          	beq	s1,s4,80002084 <scheduler+0x96>
      acquire(&p->lock);
    8000206e:	8526                	mv	a0,s1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	ba0080e7          	jalr	-1120(ra) # 80000c10 <acquire>
      if(p->state != UNUSED) {
    80002078:	4c9c                	lw	a5,24(s1)
    8000207a:	d3ed                	beqz	a5,8000205c <scheduler+0x6e>
        nproc++;
    8000207c:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000207e:	fd579fe3          	bne	a5,s5,8000205c <scheduler+0x6e>
    80002082:	b7c1                	j	80002042 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002084:	013aca63          	blt	s5,s3,80002098 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002088:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000208c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002090:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002094:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002098:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000209c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020a0:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800020a4:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800020a6:	00010497          	auipc	s1,0x10
    800020aa:	cc248493          	addi	s1,s1,-830 # 80011d68 <proc>
        p->state = RUNNING;
    800020ae:	4b8d                	li	s7,3
    800020b0:	bf7d                	j	8000206e <scheduler+0x80>

00000000800020b2 <sched>:
{
    800020b2:	7179                	addi	sp,sp,-48
    800020b4:	f406                	sd	ra,40(sp)
    800020b6:	f022                	sd	s0,32(sp)
    800020b8:	ec26                	sd	s1,24(sp)
    800020ba:	e84a                	sd	s2,16(sp)
    800020bc:	e44e                	sd	s3,8(sp)
    800020be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020c0:	00000097          	auipc	ra,0x0
    800020c4:	9fe080e7          	jalr	-1538(ra) # 80001abe <myproc>
    800020c8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	acc080e7          	jalr	-1332(ra) # 80000b96 <holding>
    800020d2:	c93d                	beqz	a0,80002148 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020d6:	2781                	sext.w	a5,a5
    800020d8:	079e                	slli	a5,a5,0x7
    800020da:	00010717          	auipc	a4,0x10
    800020de:	87670713          	addi	a4,a4,-1930 # 80011950 <pid_lock>
    800020e2:	97ba                	add	a5,a5,a4
    800020e4:	0907a703          	lw	a4,144(a5)
    800020e8:	4785                	li	a5,1
    800020ea:	06f71763          	bne	a4,a5,80002158 <sched+0xa6>
  if(p->state == RUNNING)
    800020ee:	4c98                	lw	a4,24(s1)
    800020f0:	478d                	li	a5,3
    800020f2:	06f70b63          	beq	a4,a5,80002168 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020fa:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020fc:	efb5                	bnez	a5,80002178 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002100:	00010917          	auipc	s2,0x10
    80002104:	85090913          	addi	s2,s2,-1968 # 80011950 <pid_lock>
    80002108:	2781                	sext.w	a5,a5
    8000210a:	079e                	slli	a5,a5,0x7
    8000210c:	97ca                	add	a5,a5,s2
    8000210e:	0947a983          	lw	s3,148(a5)
    80002112:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002114:	2781                	sext.w	a5,a5
    80002116:	079e                	slli	a5,a5,0x7
    80002118:	00010597          	auipc	a1,0x10
    8000211c:	85858593          	addi	a1,a1,-1960 # 80011970 <cpus+0x8>
    80002120:	95be                	add	a1,a1,a5
    80002122:	06048513          	addi	a0,s1,96
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	564080e7          	jalr	1380(ra) # 8000268a <swtch>
    8000212e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002130:	2781                	sext.w	a5,a5
    80002132:	079e                	slli	a5,a5,0x7
    80002134:	97ca                	add	a5,a5,s2
    80002136:	0937aa23          	sw	s3,148(a5)
}
    8000213a:	70a2                	ld	ra,40(sp)
    8000213c:	7402                	ld	s0,32(sp)
    8000213e:	64e2                	ld	s1,24(sp)
    80002140:	6942                	ld	s2,16(sp)
    80002142:	69a2                	ld	s3,8(sp)
    80002144:	6145                	addi	sp,sp,48
    80002146:	8082                	ret
    panic("sched p->lock");
    80002148:	00006517          	auipc	a0,0x6
    8000214c:	09050513          	addi	a0,a0,144 # 800081d8 <digits+0x198>
    80002150:	ffffe097          	auipc	ra,0xffffe
    80002154:	3f8080e7          	jalr	1016(ra) # 80000548 <panic>
    panic("sched locks");
    80002158:	00006517          	auipc	a0,0x6
    8000215c:	09050513          	addi	a0,a0,144 # 800081e8 <digits+0x1a8>
    80002160:	ffffe097          	auipc	ra,0xffffe
    80002164:	3e8080e7          	jalr	1000(ra) # 80000548 <panic>
    panic("sched running");
    80002168:	00006517          	auipc	a0,0x6
    8000216c:	09050513          	addi	a0,a0,144 # 800081f8 <digits+0x1b8>
    80002170:	ffffe097          	auipc	ra,0xffffe
    80002174:	3d8080e7          	jalr	984(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002178:	00006517          	auipc	a0,0x6
    8000217c:	09050513          	addi	a0,a0,144 # 80008208 <digits+0x1c8>
    80002180:	ffffe097          	auipc	ra,0xffffe
    80002184:	3c8080e7          	jalr	968(ra) # 80000548 <panic>

0000000080002188 <exit>:
{
    80002188:	7179                	addi	sp,sp,-48
    8000218a:	f406                	sd	ra,40(sp)
    8000218c:	f022                	sd	s0,32(sp)
    8000218e:	ec26                	sd	s1,24(sp)
    80002190:	e84a                	sd	s2,16(sp)
    80002192:	e44e                	sd	s3,8(sp)
    80002194:	e052                	sd	s4,0(sp)
    80002196:	1800                	addi	s0,sp,48
    80002198:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	924080e7          	jalr	-1756(ra) # 80001abe <myproc>
    800021a2:	89aa                	mv	s3,a0
  if(p == initproc)
    800021a4:	00007797          	auipc	a5,0x7
    800021a8:	e747b783          	ld	a5,-396(a5) # 80009018 <initproc>
    800021ac:	0d050493          	addi	s1,a0,208
    800021b0:	15050913          	addi	s2,a0,336
    800021b4:	02a79363          	bne	a5,a0,800021da <exit+0x52>
    panic("init exiting");
    800021b8:	00006517          	auipc	a0,0x6
    800021bc:	06850513          	addi	a0,a0,104 # 80008220 <digits+0x1e0>
    800021c0:	ffffe097          	auipc	ra,0xffffe
    800021c4:	388080e7          	jalr	904(ra) # 80000548 <panic>
      fileclose(f);
    800021c8:	00002097          	auipc	ra,0x2
    800021cc:	402080e7          	jalr	1026(ra) # 800045ca <fileclose>
      p->ofile[fd] = 0;
    800021d0:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021d4:	04a1                	addi	s1,s1,8
    800021d6:	01248563          	beq	s1,s2,800021e0 <exit+0x58>
    if(p->ofile[fd]){
    800021da:	6088                	ld	a0,0(s1)
    800021dc:	f575                	bnez	a0,800021c8 <exit+0x40>
    800021de:	bfdd                	j	800021d4 <exit+0x4c>
  begin_op();
    800021e0:	00002097          	auipc	ra,0x2
    800021e4:	f18080e7          	jalr	-232(ra) # 800040f8 <begin_op>
  iput(p->cwd);
    800021e8:	1509b503          	ld	a0,336(s3)
    800021ec:	00001097          	auipc	ra,0x1
    800021f0:	706080e7          	jalr	1798(ra) # 800038f2 <iput>
  end_op();
    800021f4:	00002097          	auipc	ra,0x2
    800021f8:	f84080e7          	jalr	-124(ra) # 80004178 <end_op>
  p->cwd = 0;
    800021fc:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002200:	00007497          	auipc	s1,0x7
    80002204:	e1848493          	addi	s1,s1,-488 # 80009018 <initproc>
    80002208:	6088                	ld	a0,0(s1)
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	a06080e7          	jalr	-1530(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    80002212:	6088                	ld	a0,0(s1)
    80002214:	fffff097          	auipc	ra,0xfffff
    80002218:	76a080e7          	jalr	1898(ra) # 8000197e <wakeup1>
  release(&initproc->lock);
    8000221c:	6088                	ld	a0,0(s1)
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	aa6080e7          	jalr	-1370(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002226:	854e                	mv	a0,s3
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	9e8080e7          	jalr	-1560(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    80002230:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002234:	854e                	mv	a0,s3
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    8000223e:	8526                	mv	a0,s1
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9d0080e7          	jalr	-1584(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002248:	854e                	mv	a0,s3
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	9c6080e7          	jalr	-1594(ra) # 80000c10 <acquire>
  reparent(p);
    80002252:	854e                	mv	a0,s3
    80002254:	00000097          	auipc	ra,0x0
    80002258:	d34080e7          	jalr	-716(ra) # 80001f88 <reparent>
  wakeup1(original_parent);
    8000225c:	8526                	mv	a0,s1
    8000225e:	fffff097          	auipc	ra,0xfffff
    80002262:	720080e7          	jalr	1824(ra) # 8000197e <wakeup1>
  p->xstate = status;
    80002266:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000226a:	4791                	li	a5,4
    8000226c:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	a52080e7          	jalr	-1454(ra) # 80000cc4 <release>
  sched();
    8000227a:	00000097          	auipc	ra,0x0
    8000227e:	e38080e7          	jalr	-456(ra) # 800020b2 <sched>
  panic("zombie exit");
    80002282:	00006517          	auipc	a0,0x6
    80002286:	fae50513          	addi	a0,a0,-82 # 80008230 <digits+0x1f0>
    8000228a:	ffffe097          	auipc	ra,0xffffe
    8000228e:	2be080e7          	jalr	702(ra) # 80000548 <panic>

0000000080002292 <yield>:
{
    80002292:	1101                	addi	sp,sp,-32
    80002294:	ec06                	sd	ra,24(sp)
    80002296:	e822                	sd	s0,16(sp)
    80002298:	e426                	sd	s1,8(sp)
    8000229a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000229c:	00000097          	auipc	ra,0x0
    800022a0:	822080e7          	jalr	-2014(ra) # 80001abe <myproc>
    800022a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	96a080e7          	jalr	-1686(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800022ae:	4789                	li	a5,2
    800022b0:	cc9c                	sw	a5,24(s1)
  sched();
    800022b2:	00000097          	auipc	ra,0x0
    800022b6:	e00080e7          	jalr	-512(ra) # 800020b2 <sched>
  release(&p->lock);
    800022ba:	8526                	mv	a0,s1
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	a08080e7          	jalr	-1528(ra) # 80000cc4 <release>
}
    800022c4:	60e2                	ld	ra,24(sp)
    800022c6:	6442                	ld	s0,16(sp)
    800022c8:	64a2                	ld	s1,8(sp)
    800022ca:	6105                	addi	sp,sp,32
    800022cc:	8082                	ret

00000000800022ce <sleep>:
{
    800022ce:	7179                	addi	sp,sp,-48
    800022d0:	f406                	sd	ra,40(sp)
    800022d2:	f022                	sd	s0,32(sp)
    800022d4:	ec26                	sd	s1,24(sp)
    800022d6:	e84a                	sd	s2,16(sp)
    800022d8:	e44e                	sd	s3,8(sp)
    800022da:	1800                	addi	s0,sp,48
    800022dc:	89aa                	mv	s3,a0
    800022de:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	7de080e7          	jalr	2014(ra) # 80001abe <myproc>
    800022e8:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022ea:	05250663          	beq	a0,s2,80002336 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	922080e7          	jalr	-1758(ra) # 80000c10 <acquire>
    release(lk);
    800022f6:	854a                	mv	a0,s2
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	9cc080e7          	jalr	-1588(ra) # 80000cc4 <release>
  p->chan = chan;
    80002300:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002304:	4785                	li	a5,1
    80002306:	cc9c                	sw	a5,24(s1)
  sched();
    80002308:	00000097          	auipc	ra,0x0
    8000230c:	daa080e7          	jalr	-598(ra) # 800020b2 <sched>
  p->chan = 0;
    80002310:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	9ae080e7          	jalr	-1618(ra) # 80000cc4 <release>
    acquire(lk);
    8000231e:	854a                	mv	a0,s2
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8f0080e7          	jalr	-1808(ra) # 80000c10 <acquire>
}
    80002328:	70a2                	ld	ra,40(sp)
    8000232a:	7402                	ld	s0,32(sp)
    8000232c:	64e2                	ld	s1,24(sp)
    8000232e:	6942                	ld	s2,16(sp)
    80002330:	69a2                	ld	s3,8(sp)
    80002332:	6145                	addi	sp,sp,48
    80002334:	8082                	ret
  p->chan = chan;
    80002336:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000233a:	4785                	li	a5,1
    8000233c:	cd1c                	sw	a5,24(a0)
  sched();
    8000233e:	00000097          	auipc	ra,0x0
    80002342:	d74080e7          	jalr	-652(ra) # 800020b2 <sched>
  p->chan = 0;
    80002346:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000234a:	bff9                	j	80002328 <sleep+0x5a>

000000008000234c <wait>:
{
    8000234c:	715d                	addi	sp,sp,-80
    8000234e:	e486                	sd	ra,72(sp)
    80002350:	e0a2                	sd	s0,64(sp)
    80002352:	fc26                	sd	s1,56(sp)
    80002354:	f84a                	sd	s2,48(sp)
    80002356:	f44e                	sd	s3,40(sp)
    80002358:	f052                	sd	s4,32(sp)
    8000235a:	ec56                	sd	s5,24(sp)
    8000235c:	e85a                	sd	s6,16(sp)
    8000235e:	e45e                	sd	s7,8(sp)
    80002360:	e062                	sd	s8,0(sp)
    80002362:	0880                	addi	s0,sp,80
    80002364:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	758080e7          	jalr	1880(ra) # 80001abe <myproc>
    8000236e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002370:	8c2a                	mv	s8,a0
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	89e080e7          	jalr	-1890(ra) # 80000c10 <acquire>
    havekids = 0;
    8000237a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000237c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000237e:	00015997          	auipc	s3,0x15
    80002382:	3ea98993          	addi	s3,s3,1002 # 80017768 <tickslock>
        havekids = 1;
    80002386:	4a85                	li	s5,1
    havekids = 0;
    80002388:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000238a:	00010497          	auipc	s1,0x10
    8000238e:	9de48493          	addi	s1,s1,-1570 # 80011d68 <proc>
    80002392:	a08d                	j	800023f4 <wait+0xa8>
          pid = np->pid;
    80002394:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002398:	000b0e63          	beqz	s6,800023b4 <wait+0x68>
    8000239c:	4691                	li	a3,4
    8000239e:	03448613          	addi	a2,s1,52
    800023a2:	85da                	mv	a1,s6
    800023a4:	05093503          	ld	a0,80(s2)
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	3d6080e7          	jalr	982(ra) # 8000177e <copyout>
    800023b0:	02054263          	bltz	a0,800023d4 <wait+0x88>
          freeproc(np);
    800023b4:	8526                	mv	a0,s1
    800023b6:	00000097          	auipc	ra,0x0
    800023ba:	8ba080e7          	jalr	-1862(ra) # 80001c70 <freeproc>
          release(&np->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	904080e7          	jalr	-1788(ra) # 80000cc4 <release>
          release(&p->lock);
    800023c8:	854a                	mv	a0,s2
    800023ca:	fffff097          	auipc	ra,0xfffff
    800023ce:	8fa080e7          	jalr	-1798(ra) # 80000cc4 <release>
          return pid;
    800023d2:	a8a9                	j	8000242c <wait+0xe0>
            release(&np->lock);
    800023d4:	8526                	mv	a0,s1
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8ee080e7          	jalr	-1810(ra) # 80000cc4 <release>
            release(&p->lock);
    800023de:	854a                	mv	a0,s2
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	8e4080e7          	jalr	-1820(ra) # 80000cc4 <release>
            return -1;
    800023e8:	59fd                	li	s3,-1
    800023ea:	a089                	j	8000242c <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023ec:	16848493          	addi	s1,s1,360
    800023f0:	03348463          	beq	s1,s3,80002418 <wait+0xcc>
      if(np->parent == p){
    800023f4:	709c                	ld	a5,32(s1)
    800023f6:	ff279be3          	bne	a5,s2,800023ec <wait+0xa0>
        acquire(&np->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	814080e7          	jalr	-2028(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    80002404:	4c9c                	lw	a5,24(s1)
    80002406:	f94787e3          	beq	a5,s4,80002394 <wait+0x48>
        release(&np->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	8b8080e7          	jalr	-1864(ra) # 80000cc4 <release>
        havekids = 1;
    80002414:	8756                	mv	a4,s5
    80002416:	bfd9                	j	800023ec <wait+0xa0>
    if(!havekids || p->killed){
    80002418:	c701                	beqz	a4,80002420 <wait+0xd4>
    8000241a:	03092783          	lw	a5,48(s2)
    8000241e:	c785                	beqz	a5,80002446 <wait+0xfa>
      release(&p->lock);
    80002420:	854a                	mv	a0,s2
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	8a2080e7          	jalr	-1886(ra) # 80000cc4 <release>
      return -1;
    8000242a:	59fd                	li	s3,-1
}
    8000242c:	854e                	mv	a0,s3
    8000242e:	60a6                	ld	ra,72(sp)
    80002430:	6406                	ld	s0,64(sp)
    80002432:	74e2                	ld	s1,56(sp)
    80002434:	7942                	ld	s2,48(sp)
    80002436:	79a2                	ld	s3,40(sp)
    80002438:	7a02                	ld	s4,32(sp)
    8000243a:	6ae2                	ld	s5,24(sp)
    8000243c:	6b42                	ld	s6,16(sp)
    8000243e:	6ba2                	ld	s7,8(sp)
    80002440:	6c02                	ld	s8,0(sp)
    80002442:	6161                	addi	sp,sp,80
    80002444:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002446:	85e2                	mv	a1,s8
    80002448:	854a                	mv	a0,s2
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	e84080e7          	jalr	-380(ra) # 800022ce <sleep>
    havekids = 0;
    80002452:	bf1d                	j	80002388 <wait+0x3c>

0000000080002454 <wakeup>:
{
    80002454:	7139                	addi	sp,sp,-64
    80002456:	fc06                	sd	ra,56(sp)
    80002458:	f822                	sd	s0,48(sp)
    8000245a:	f426                	sd	s1,40(sp)
    8000245c:	f04a                	sd	s2,32(sp)
    8000245e:	ec4e                	sd	s3,24(sp)
    80002460:	e852                	sd	s4,16(sp)
    80002462:	e456                	sd	s5,8(sp)
    80002464:	0080                	addi	s0,sp,64
    80002466:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002468:	00010497          	auipc	s1,0x10
    8000246c:	90048493          	addi	s1,s1,-1792 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002470:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002472:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002474:	00015917          	auipc	s2,0x15
    80002478:	2f490913          	addi	s2,s2,756 # 80017768 <tickslock>
    8000247c:	a821                	j	80002494 <wakeup+0x40>
      p->state = RUNNABLE;
    8000247e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fffff097          	auipc	ra,0xfffff
    80002488:	840080e7          	jalr	-1984(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000248c:	16848493          	addi	s1,s1,360
    80002490:	01248e63          	beq	s1,s2,800024ac <wakeup+0x58>
    acquire(&p->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	ffffe097          	auipc	ra,0xffffe
    8000249a:	77a080e7          	jalr	1914(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000249e:	4c9c                	lw	a5,24(s1)
    800024a0:	ff3791e3          	bne	a5,s3,80002482 <wakeup+0x2e>
    800024a4:	749c                	ld	a5,40(s1)
    800024a6:	fd479ee3          	bne	a5,s4,80002482 <wakeup+0x2e>
    800024aa:	bfd1                	j	8000247e <wakeup+0x2a>
}
    800024ac:	70e2                	ld	ra,56(sp)
    800024ae:	7442                	ld	s0,48(sp)
    800024b0:	74a2                	ld	s1,40(sp)
    800024b2:	7902                	ld	s2,32(sp)
    800024b4:	69e2                	ld	s3,24(sp)
    800024b6:	6a42                	ld	s4,16(sp)
    800024b8:	6aa2                	ld	s5,8(sp)
    800024ba:	6121                	addi	sp,sp,64
    800024bc:	8082                	ret

00000000800024be <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024be:	7179                	addi	sp,sp,-48
    800024c0:	f406                	sd	ra,40(sp)
    800024c2:	f022                	sd	s0,32(sp)
    800024c4:	ec26                	sd	s1,24(sp)
    800024c6:	e84a                	sd	s2,16(sp)
    800024c8:	e44e                	sd	s3,8(sp)
    800024ca:	1800                	addi	s0,sp,48
    800024cc:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024ce:	00010497          	auipc	s1,0x10
    800024d2:	89a48493          	addi	s1,s1,-1894 # 80011d68 <proc>
    800024d6:	00015997          	auipc	s3,0x15
    800024da:	29298993          	addi	s3,s3,658 # 80017768 <tickslock>
    acquire(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	730080e7          	jalr	1840(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800024e8:	5c9c                	lw	a5,56(s1)
    800024ea:	01278d63          	beq	a5,s2,80002504 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ee:	8526                	mv	a0,s1
    800024f0:	ffffe097          	auipc	ra,0xffffe
    800024f4:	7d4080e7          	jalr	2004(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024f8:	16848493          	addi	s1,s1,360
    800024fc:	ff3491e3          	bne	s1,s3,800024de <kill+0x20>
  }
  return -1;
    80002500:	557d                	li	a0,-1
    80002502:	a829                	j	8000251c <kill+0x5e>
      p->killed = 1;
    80002504:	4785                	li	a5,1
    80002506:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002508:	4c98                	lw	a4,24(s1)
    8000250a:	4785                	li	a5,1
    8000250c:	00f70f63          	beq	a4,a5,8000252a <kill+0x6c>
      release(&p->lock);
    80002510:	8526                	mv	a0,s1
    80002512:	ffffe097          	auipc	ra,0xffffe
    80002516:	7b2080e7          	jalr	1970(ra) # 80000cc4 <release>
      return 0;
    8000251a:	4501                	li	a0,0
}
    8000251c:	70a2                	ld	ra,40(sp)
    8000251e:	7402                	ld	s0,32(sp)
    80002520:	64e2                	ld	s1,24(sp)
    80002522:	6942                	ld	s2,16(sp)
    80002524:	69a2                	ld	s3,8(sp)
    80002526:	6145                	addi	sp,sp,48
    80002528:	8082                	ret
        p->state = RUNNABLE;
    8000252a:	4789                	li	a5,2
    8000252c:	cc9c                	sw	a5,24(s1)
    8000252e:	b7cd                	j	80002510 <kill+0x52>

0000000080002530 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002530:	7179                	addi	sp,sp,-48
    80002532:	f406                	sd	ra,40(sp)
    80002534:	f022                	sd	s0,32(sp)
    80002536:	ec26                	sd	s1,24(sp)
    80002538:	e84a                	sd	s2,16(sp)
    8000253a:	e44e                	sd	s3,8(sp)
    8000253c:	e052                	sd	s4,0(sp)
    8000253e:	1800                	addi	s0,sp,48
    80002540:	84aa                	mv	s1,a0
    80002542:	892e                	mv	s2,a1
    80002544:	89b2                	mv	s3,a2
    80002546:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	576080e7          	jalr	1398(ra) # 80001abe <myproc>
  if(user_dst){
    80002550:	c08d                	beqz	s1,80002572 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002552:	86d2                	mv	a3,s4
    80002554:	864e                	mv	a2,s3
    80002556:	85ca                	mv	a1,s2
    80002558:	6928                	ld	a0,80(a0)
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	224080e7          	jalr	548(ra) # 8000177e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002562:	70a2                	ld	ra,40(sp)
    80002564:	7402                	ld	s0,32(sp)
    80002566:	64e2                	ld	s1,24(sp)
    80002568:	6942                	ld	s2,16(sp)
    8000256a:	69a2                	ld	s3,8(sp)
    8000256c:	6a02                	ld	s4,0(sp)
    8000256e:	6145                	addi	sp,sp,48
    80002570:	8082                	ret
    memmove((char *)dst, src, len);
    80002572:	000a061b          	sext.w	a2,s4
    80002576:	85ce                	mv	a1,s3
    80002578:	854a                	mv	a0,s2
    8000257a:	ffffe097          	auipc	ra,0xffffe
    8000257e:	7f2080e7          	jalr	2034(ra) # 80000d6c <memmove>
    return 0;
    80002582:	8526                	mv	a0,s1
    80002584:	bff9                	j	80002562 <either_copyout+0x32>

0000000080002586 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002586:	7179                	addi	sp,sp,-48
    80002588:	f406                	sd	ra,40(sp)
    8000258a:	f022                	sd	s0,32(sp)
    8000258c:	ec26                	sd	s1,24(sp)
    8000258e:	e84a                	sd	s2,16(sp)
    80002590:	e44e                	sd	s3,8(sp)
    80002592:	e052                	sd	s4,0(sp)
    80002594:	1800                	addi	s0,sp,48
    80002596:	892a                	mv	s2,a0
    80002598:	84ae                	mv	s1,a1
    8000259a:	89b2                	mv	s3,a2
    8000259c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000259e:	fffff097          	auipc	ra,0xfffff
    800025a2:	520080e7          	jalr	1312(ra) # 80001abe <myproc>
  if(user_src){
    800025a6:	c08d                	beqz	s1,800025c8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800025a8:	86d2                	mv	a3,s4
    800025aa:	864e                	mv	a2,s3
    800025ac:	85ca                	mv	a1,s2
    800025ae:	6928                	ld	a0,80(a0)
    800025b0:	fffff097          	auipc	ra,0xfffff
    800025b4:	274080e7          	jalr	628(ra) # 80001824 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025b8:	70a2                	ld	ra,40(sp)
    800025ba:	7402                	ld	s0,32(sp)
    800025bc:	64e2                	ld	s1,24(sp)
    800025be:	6942                	ld	s2,16(sp)
    800025c0:	69a2                	ld	s3,8(sp)
    800025c2:	6a02                	ld	s4,0(sp)
    800025c4:	6145                	addi	sp,sp,48
    800025c6:	8082                	ret
    memmove(dst, (char*)src, len);
    800025c8:	000a061b          	sext.w	a2,s4
    800025cc:	85ce                	mv	a1,s3
    800025ce:	854a                	mv	a0,s2
    800025d0:	ffffe097          	auipc	ra,0xffffe
    800025d4:	79c080e7          	jalr	1948(ra) # 80000d6c <memmove>
    return 0;
    800025d8:	8526                	mv	a0,s1
    800025da:	bff9                	j	800025b8 <either_copyin+0x32>

00000000800025dc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025dc:	715d                	addi	sp,sp,-80
    800025de:	e486                	sd	ra,72(sp)
    800025e0:	e0a2                	sd	s0,64(sp)
    800025e2:	fc26                	sd	s1,56(sp)
    800025e4:	f84a                	sd	s2,48(sp)
    800025e6:	f44e                	sd	s3,40(sp)
    800025e8:	f052                	sd	s4,32(sp)
    800025ea:	ec56                	sd	s5,24(sp)
    800025ec:	e85a                	sd	s6,16(sp)
    800025ee:	e45e                	sd	s7,8(sp)
    800025f0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025f2:	00006517          	auipc	a0,0x6
    800025f6:	ad650513          	addi	a0,a0,-1322 # 800080c8 <digits+0x88>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f98080e7          	jalr	-104(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002602:	00010497          	auipc	s1,0x10
    80002606:	8be48493          	addi	s1,s1,-1858 # 80011ec0 <proc+0x158>
    8000260a:	00015917          	auipc	s2,0x15
    8000260e:	2b690913          	addi	s2,s2,694 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002612:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002614:	00006997          	auipc	s3,0x6
    80002618:	c2c98993          	addi	s3,s3,-980 # 80008240 <digits+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    8000261c:	00006a97          	auipc	s5,0x6
    80002620:	c2ca8a93          	addi	s5,s5,-980 # 80008248 <digits+0x208>
    printf("\n");
    80002624:	00006a17          	auipc	s4,0x6
    80002628:	aa4a0a13          	addi	s4,s4,-1372 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000262c:	00006b97          	auipc	s7,0x6
    80002630:	c54b8b93          	addi	s7,s7,-940 # 80008280 <states.1706>
    80002634:	a00d                	j	80002656 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002636:	ee06a583          	lw	a1,-288(a3)
    8000263a:	8556                	mv	a0,s5
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	f56080e7          	jalr	-170(ra) # 80000592 <printf>
    printf("\n");
    80002644:	8552                	mv	a0,s4
    80002646:	ffffe097          	auipc	ra,0xffffe
    8000264a:	f4c080e7          	jalr	-180(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264e:	16848493          	addi	s1,s1,360
    80002652:	03248163          	beq	s1,s2,80002674 <procdump+0x98>
    if(p->state == UNUSED)
    80002656:	86a6                	mv	a3,s1
    80002658:	ec04a783          	lw	a5,-320(s1)
    8000265c:	dbed                	beqz	a5,8000264e <procdump+0x72>
      state = "???";
    8000265e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002660:	fcfb6be3          	bltu	s6,a5,80002636 <procdump+0x5a>
    80002664:	1782                	slli	a5,a5,0x20
    80002666:	9381                	srli	a5,a5,0x20
    80002668:	078e                	slli	a5,a5,0x3
    8000266a:	97de                	add	a5,a5,s7
    8000266c:	6390                	ld	a2,0(a5)
    8000266e:	f661                	bnez	a2,80002636 <procdump+0x5a>
      state = "???";
    80002670:	864e                	mv	a2,s3
    80002672:	b7d1                	j	80002636 <procdump+0x5a>
  }
}
    80002674:	60a6                	ld	ra,72(sp)
    80002676:	6406                	ld	s0,64(sp)
    80002678:	74e2                	ld	s1,56(sp)
    8000267a:	7942                	ld	s2,48(sp)
    8000267c:	79a2                	ld	s3,40(sp)
    8000267e:	7a02                	ld	s4,32(sp)
    80002680:	6ae2                	ld	s5,24(sp)
    80002682:	6b42                	ld	s6,16(sp)
    80002684:	6ba2                	ld	s7,8(sp)
    80002686:	6161                	addi	sp,sp,80
    80002688:	8082                	ret

000000008000268a <swtch>:
    8000268a:	00153023          	sd	ra,0(a0)
    8000268e:	00253423          	sd	sp,8(a0)
    80002692:	e900                	sd	s0,16(a0)
    80002694:	ed04                	sd	s1,24(a0)
    80002696:	03253023          	sd	s2,32(a0)
    8000269a:	03353423          	sd	s3,40(a0)
    8000269e:	03453823          	sd	s4,48(a0)
    800026a2:	03553c23          	sd	s5,56(a0)
    800026a6:	05653023          	sd	s6,64(a0)
    800026aa:	05753423          	sd	s7,72(a0)
    800026ae:	05853823          	sd	s8,80(a0)
    800026b2:	05953c23          	sd	s9,88(a0)
    800026b6:	07a53023          	sd	s10,96(a0)
    800026ba:	07b53423          	sd	s11,104(a0)
    800026be:	0005b083          	ld	ra,0(a1)
    800026c2:	0085b103          	ld	sp,8(a1)
    800026c6:	6980                	ld	s0,16(a1)
    800026c8:	6d84                	ld	s1,24(a1)
    800026ca:	0205b903          	ld	s2,32(a1)
    800026ce:	0285b983          	ld	s3,40(a1)
    800026d2:	0305ba03          	ld	s4,48(a1)
    800026d6:	0385ba83          	ld	s5,56(a1)
    800026da:	0405bb03          	ld	s6,64(a1)
    800026de:	0485bb83          	ld	s7,72(a1)
    800026e2:	0505bc03          	ld	s8,80(a1)
    800026e6:	0585bc83          	ld	s9,88(a1)
    800026ea:	0605bd03          	ld	s10,96(a1)
    800026ee:	0685bd83          	ld	s11,104(a1)
    800026f2:	8082                	ret

00000000800026f4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026f4:	1141                	addi	sp,sp,-16
    800026f6:	e406                	sd	ra,8(sp)
    800026f8:	e022                	sd	s0,0(sp)
    800026fa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026fc:	00006597          	auipc	a1,0x6
    80002700:	bac58593          	addi	a1,a1,-1108 # 800082a8 <states.1706+0x28>
    80002704:	00015517          	auipc	a0,0x15
    80002708:	06450513          	addi	a0,a0,100 # 80017768 <tickslock>
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	474080e7          	jalr	1140(ra) # 80000b80 <initlock>
}
    80002714:	60a2                	ld	ra,8(sp)
    80002716:	6402                	ld	s0,0(sp)
    80002718:	0141                	addi	sp,sp,16
    8000271a:	8082                	ret

000000008000271c <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000271c:	1141                	addi	sp,sp,-16
    8000271e:	e422                	sd	s0,8(sp)
    80002720:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002722:	00003797          	auipc	a5,0x3
    80002726:	50e78793          	addi	a5,a5,1294 # 80005c30 <kernelvec>
    8000272a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000272e:	6422                	ld	s0,8(sp)
    80002730:	0141                	addi	sp,sp,16
    80002732:	8082                	ret

0000000080002734 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002734:	1141                	addi	sp,sp,-16
    80002736:	e406                	sd	ra,8(sp)
    80002738:	e022                	sd	s0,0(sp)
    8000273a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000273c:	fffff097          	auipc	ra,0xfffff
    80002740:	382080e7          	jalr	898(ra) # 80001abe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002744:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002748:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000274a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000274e:	00005617          	auipc	a2,0x5
    80002752:	8b260613          	addi	a2,a2,-1870 # 80007000 <_trampoline>
    80002756:	00005697          	auipc	a3,0x5
    8000275a:	8aa68693          	addi	a3,a3,-1878 # 80007000 <_trampoline>
    8000275e:	8e91                	sub	a3,a3,a2
    80002760:	040007b7          	lui	a5,0x4000
    80002764:	17fd                	addi	a5,a5,-1
    80002766:	07b2                	slli	a5,a5,0xc
    80002768:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000276a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000276e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002770:	180026f3          	csrr	a3,satp
    80002774:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002776:	6d38                	ld	a4,88(a0)
    80002778:	6134                	ld	a3,64(a0)
    8000277a:	6585                	lui	a1,0x1
    8000277c:	96ae                	add	a3,a3,a1
    8000277e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002780:	6d38                	ld	a4,88(a0)
    80002782:	00000697          	auipc	a3,0x0
    80002786:	13868693          	addi	a3,a3,312 # 800028ba <usertrap>
    8000278a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000278c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000278e:	8692                	mv	a3,tp
    80002790:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002792:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002796:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000279a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000279e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027a2:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027a4:	6f18                	ld	a4,24(a4)
    800027a6:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027aa:	692c                	ld	a1,80(a0)
    800027ac:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027ae:	00005717          	auipc	a4,0x5
    800027b2:	8e270713          	addi	a4,a4,-1822 # 80007090 <userret>
    800027b6:	8f11                	sub	a4,a4,a2
    800027b8:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ba:	577d                	li	a4,-1
    800027bc:	177e                	slli	a4,a4,0x3f
    800027be:	8dd9                	or	a1,a1,a4
    800027c0:	02000537          	lui	a0,0x2000
    800027c4:	157d                	addi	a0,a0,-1
    800027c6:	0536                	slli	a0,a0,0xd
    800027c8:	9782                	jalr	a5
}
    800027ca:	60a2                	ld	ra,8(sp)
    800027cc:	6402                	ld	s0,0(sp)
    800027ce:	0141                	addi	sp,sp,16
    800027d0:	8082                	ret

00000000800027d2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027d2:	1101                	addi	sp,sp,-32
    800027d4:	ec06                	sd	ra,24(sp)
    800027d6:	e822                	sd	s0,16(sp)
    800027d8:	e426                	sd	s1,8(sp)
    800027da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027dc:	00015497          	auipc	s1,0x15
    800027e0:	f8c48493          	addi	s1,s1,-116 # 80017768 <tickslock>
    800027e4:	8526                	mv	a0,s1
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	42a080e7          	jalr	1066(ra) # 80000c10 <acquire>
  ticks++;
    800027ee:	00007517          	auipc	a0,0x7
    800027f2:	83250513          	addi	a0,a0,-1998 # 80009020 <ticks>
    800027f6:	411c                	lw	a5,0(a0)
    800027f8:	2785                	addiw	a5,a5,1
    800027fa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027fc:	00000097          	auipc	ra,0x0
    80002800:	c58080e7          	jalr	-936(ra) # 80002454 <wakeup>
  release(&tickslock);
    80002804:	8526                	mv	a0,s1
    80002806:	ffffe097          	auipc	ra,0xffffe
    8000280a:	4be080e7          	jalr	1214(ra) # 80000cc4 <release>
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret

0000000080002818 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002822:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002826:	00074d63          	bltz	a4,80002840 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000282a:	57fd                	li	a5,-1
    8000282c:	17fe                	slli	a5,a5,0x3f
    8000282e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002830:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002832:	06f70363          	beq	a4,a5,80002898 <devintr+0x80>
  }
}
    80002836:	60e2                	ld	ra,24(sp)
    80002838:	6442                	ld	s0,16(sp)
    8000283a:	64a2                	ld	s1,8(sp)
    8000283c:	6105                	addi	sp,sp,32
    8000283e:	8082                	ret
     (scause & 0xff) == 9){
    80002840:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002844:	46a5                	li	a3,9
    80002846:	fed792e3          	bne	a5,a3,8000282a <devintr+0x12>
    int irq = plic_claim();
    8000284a:	00003097          	auipc	ra,0x3
    8000284e:	4ee080e7          	jalr	1262(ra) # 80005d38 <plic_claim>
    80002852:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002854:	47a9                	li	a5,10
    80002856:	02f50763          	beq	a0,a5,80002884 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000285a:	4785                	li	a5,1
    8000285c:	02f50963          	beq	a0,a5,8000288e <devintr+0x76>
    return 1;
    80002860:	4505                	li	a0,1
    } else if(irq){
    80002862:	d8f1                	beqz	s1,80002836 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002864:	85a6                	mv	a1,s1
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	a4a50513          	addi	a0,a0,-1462 # 800082b0 <states.1706+0x30>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d24080e7          	jalr	-732(ra) # 80000592 <printf>
      plic_complete(irq);
    80002876:	8526                	mv	a0,s1
    80002878:	00003097          	auipc	ra,0x3
    8000287c:	4e4080e7          	jalr	1252(ra) # 80005d5c <plic_complete>
    return 1;
    80002880:	4505                	li	a0,1
    80002882:	bf55                	j	80002836 <devintr+0x1e>
      uartintr();
    80002884:	ffffe097          	auipc	ra,0xffffe
    80002888:	150080e7          	jalr	336(ra) # 800009d4 <uartintr>
    8000288c:	b7ed                	j	80002876 <devintr+0x5e>
      virtio_disk_intr();
    8000288e:	00004097          	auipc	ra,0x4
    80002892:	968080e7          	jalr	-1688(ra) # 800061f6 <virtio_disk_intr>
    80002896:	b7c5                	j	80002876 <devintr+0x5e>
    if(cpuid() == 0){
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	1fa080e7          	jalr	506(ra) # 80001a92 <cpuid>
    800028a0:	c901                	beqz	a0,800028b0 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028a2:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028a6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028a8:	14479073          	csrw	sip,a5
    return 2;
    800028ac:	4509                	li	a0,2
    800028ae:	b761                	j	80002836 <devintr+0x1e>
      clockintr();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	f22080e7          	jalr	-222(ra) # 800027d2 <clockintr>
    800028b8:	b7ed                	j	800028a2 <devintr+0x8a>

00000000800028ba <usertrap>:
{
    800028ba:	7179                	addi	sp,sp,-48
    800028bc:	f406                	sd	ra,40(sp)
    800028be:	f022                	sd	s0,32(sp)
    800028c0:	ec26                	sd	s1,24(sp)
    800028c2:	e84a                	sd	s2,16(sp)
    800028c4:	e44e                	sd	s3,8(sp)
    800028c6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028cc:	1007f793          	andi	a5,a5,256
    800028d0:	e3b5                	bnez	a5,80002934 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028d2:	00003797          	auipc	a5,0x3
    800028d6:	35e78793          	addi	a5,a5,862 # 80005c30 <kernelvec>
    800028da:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	1e0080e7          	jalr	480(ra) # 80001abe <myproc>
    800028e6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028e8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ea:	14102773          	csrr	a4,sepc
    800028ee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028f4:	47a1                	li	a5,8
    800028f6:	04f71d63          	bne	a4,a5,80002950 <usertrap+0x96>
    if(p->killed)
    800028fa:	591c                	lw	a5,48(a0)
    800028fc:	e7a1                	bnez	a5,80002944 <usertrap+0x8a>
    p->trapframe->epc += 4;
    800028fe:	6cb8                	ld	a4,88(s1)
    80002900:	6f1c                	ld	a5,24(a4)
    80002902:	0791                	addi	a5,a5,4
    80002904:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002906:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000290e:	10079073          	csrw	sstatus,a5
    syscall();
    80002912:	00000097          	auipc	ra,0x0
    80002916:	312080e7          	jalr	786(ra) # 80002c24 <syscall>
  if(p->killed)
    8000291a:	589c                	lw	a5,48(s1)
    8000291c:	e3e9                	bnez	a5,800029de <usertrap+0x124>
  usertrapret();
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	e16080e7          	jalr	-490(ra) # 80002734 <usertrapret>
}
    80002926:	70a2                	ld	ra,40(sp)
    80002928:	7402                	ld	s0,32(sp)
    8000292a:	64e2                	ld	s1,24(sp)
    8000292c:	6942                	ld	s2,16(sp)
    8000292e:	69a2                	ld	s3,8(sp)
    80002930:	6145                	addi	sp,sp,48
    80002932:	8082                	ret
    panic("usertrap: not from user mode");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	99c50513          	addi	a0,a0,-1636 # 800082d0 <states.1706+0x50>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c0c080e7          	jalr	-1012(ra) # 80000548 <panic>
      exit(-1);
    80002944:	557d                	li	a0,-1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	842080e7          	jalr	-1982(ra) # 80002188 <exit>
    8000294e:	bf45                	j	800028fe <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    80002950:	00000097          	auipc	ra,0x0
    80002954:	ec8080e7          	jalr	-312(ra) # 80002818 <devintr>
    80002958:	892a                	mv	s2,a0
    8000295a:	ed3d                	bnez	a0,800029d8 <usertrap+0x11e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295c:	143029f3          	csrr	s3,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	14202773          	csrr	a4,scause
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){ // 缺页异常，并且发生异常的地址进行过懒分配
    80002964:	47b5                	li	a5,13
    80002966:	04f70d63          	beq	a4,a5,800029c0 <usertrap+0x106>
    8000296a:	14202773          	csrr	a4,scause
    8000296e:	47bd                	li	a5,15
    80002970:	04f70863          	beq	a4,a5,800029c0 <usertrap+0x106>
    80002974:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002978:	5c90                	lw	a2,56(s1)
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	97650513          	addi	a0,a0,-1674 # 800082f0 <states.1706+0x70>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c10080e7          	jalr	-1008(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000298e:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002992:	00006517          	auipc	a0,0x6
    80002996:	98e50513          	addi	a0,a0,-1650 # 80008320 <states.1706+0xa0>
    8000299a:	ffffe097          	auipc	ra,0xffffe
    8000299e:	bf8080e7          	jalr	-1032(ra) # 80000592 <printf>
      p->killed = 1;
    800029a2:	4785                	li	a5,1
    800029a4:	d89c                	sw	a5,48(s1)
    exit(-1);
    800029a6:	557d                	li	a0,-1
    800029a8:	fffff097          	auipc	ra,0xfffff
    800029ac:	7e0080e7          	jalr	2016(ra) # 80002188 <exit>
  if(which_dev == 2)
    800029b0:	4789                	li	a5,2
    800029b2:	f6f916e3          	bne	s2,a5,8000291e <usertrap+0x64>
    yield();
    800029b6:	00000097          	auipc	ra,0x0
    800029ba:	8dc080e7          	jalr	-1828(ra) # 80002292 <yield>
    800029be:	b785                	j	8000291e <usertrap+0x64>
    if((r_scause() == 13 || r_scause() == 15) && uvmshouldtouch(va)){ // 缺页异常，并且发生异常的地址进行过懒分配
    800029c0:	854e                	mv	a0,s3
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	d6a080e7          	jalr	-662(ra) # 8000172c <uvmshouldtouch>
    800029ca:	d54d                	beqz	a0,80002974 <usertrap+0xba>
      uvmlazytouch(va); // 分配物理内存，并在页表创建映射
    800029cc:	854e                	mv	a0,s3
    800029ce:	fffff097          	auipc	ra,0xfffff
    800029d2:	cca080e7          	jalr	-822(ra) # 80001698 <uvmlazytouch>
    800029d6:	b791                	j	8000291a <usertrap+0x60>
  if(p->killed)
    800029d8:	589c                	lw	a5,48(s1)
    800029da:	dbf9                	beqz	a5,800029b0 <usertrap+0xf6>
    800029dc:	b7e9                	j	800029a6 <usertrap+0xec>
    800029de:	4901                	li	s2,0
    800029e0:	b7d9                	j	800029a6 <usertrap+0xec>

00000000800029e2 <kerneltrap>:
{
    800029e2:	7179                	addi	sp,sp,-48
    800029e4:	f406                	sd	ra,40(sp)
    800029e6:	f022                	sd	s0,32(sp)
    800029e8:	ec26                	sd	s1,24(sp)
    800029ea:	e84a                	sd	s2,16(sp)
    800029ec:	e44e                	sd	s3,8(sp)
    800029ee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029fc:	1004f793          	andi	a5,s1,256
    80002a00:	cb85                	beqz	a5,80002a30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a08:	ef85                	bnez	a5,80002a40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0a:	00000097          	auipc	ra,0x0
    80002a0e:	e0e080e7          	jalr	-498(ra) # 80002818 <devintr>
    80002a12:	cd1d                	beqz	a0,80002a50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a14:	4789                	li	a5,2
    80002a16:	06f50a63          	beq	a0,a5,80002a8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a1e:	10049073          	csrw	sstatus,s1
}
    80002a22:	70a2                	ld	ra,40(sp)
    80002a24:	7402                	ld	s0,32(sp)
    80002a26:	64e2                	ld	s1,24(sp)
    80002a28:	6942                	ld	s2,16(sp)
    80002a2a:	69a2                	ld	s3,8(sp)
    80002a2c:	6145                	addi	sp,sp,48
    80002a2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	91050513          	addi	a0,a0,-1776 # 80008340 <states.1706+0xc0>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b10080e7          	jalr	-1264(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	92850513          	addi	a0,a0,-1752 # 80008368 <states.1706+0xe8>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b00080e7          	jalr	-1280(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a50:	85ce                	mv	a1,s3
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	93650513          	addi	a0,a0,-1738 # 80008388 <states.1706+0x108>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b38080e7          	jalr	-1224(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6a:	00006517          	auipc	a0,0x6
    80002a6e:	92e50513          	addi	a0,a0,-1746 # 80008398 <states.1706+0x118>
    80002a72:	ffffe097          	auipc	ra,0xffffe
    80002a76:	b20080e7          	jalr	-1248(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	93650513          	addi	a0,a0,-1738 # 800083b0 <states.1706+0x130>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	ac6080e7          	jalr	-1338(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	034080e7          	jalr	52(ra) # 80001abe <myproc>
    80002a92:	d541                	beqz	a0,80002a1a <kerneltrap+0x38>
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	02a080e7          	jalr	42(ra) # 80001abe <myproc>
    80002a9c:	4d18                	lw	a4,24(a0)
    80002a9e:	478d                	li	a5,3
    80002aa0:	f6f71de3          	bne	a4,a5,80002a1a <kerneltrap+0x38>
    yield();
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	7ee080e7          	jalr	2030(ra) # 80002292 <yield>
    80002aac:	b7bd                	j	80002a1a <kerneltrap+0x38>

0000000080002aae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aae:	1101                	addi	sp,sp,-32
    80002ab0:	ec06                	sd	ra,24(sp)
    80002ab2:	e822                	sd	s0,16(sp)
    80002ab4:	e426                	sd	s1,8(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aba:	fffff097          	auipc	ra,0xfffff
    80002abe:	004080e7          	jalr	4(ra) # 80001abe <myproc>
  switch (n) {
    80002ac2:	4795                	li	a5,5
    80002ac4:	0497e163          	bltu	a5,s1,80002b06 <argraw+0x58>
    80002ac8:	048a                	slli	s1,s1,0x2
    80002aca:	00006717          	auipc	a4,0x6
    80002ace:	91e70713          	addi	a4,a4,-1762 # 800083e8 <states.1706+0x168>
    80002ad2:	94ba                	add	s1,s1,a4
    80002ad4:	409c                	lw	a5,0(s1)
    80002ad6:	97ba                	add	a5,a5,a4
    80002ad8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ada:	6d3c                	ld	a5,88(a0)
    80002adc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ade:	60e2                	ld	ra,24(sp)
    80002ae0:	6442                	ld	s0,16(sp)
    80002ae2:	64a2                	ld	s1,8(sp)
    80002ae4:	6105                	addi	sp,sp,32
    80002ae6:	8082                	ret
    return p->trapframe->a1;
    80002ae8:	6d3c                	ld	a5,88(a0)
    80002aea:	7fa8                	ld	a0,120(a5)
    80002aec:	bfcd                	j	80002ade <argraw+0x30>
    return p->trapframe->a2;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	63c8                	ld	a0,128(a5)
    80002af2:	b7f5                	j	80002ade <argraw+0x30>
    return p->trapframe->a3;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	67c8                	ld	a0,136(a5)
    80002af8:	b7dd                	j	80002ade <argraw+0x30>
    return p->trapframe->a4;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	6bc8                	ld	a0,144(a5)
    80002afe:	b7c5                	j	80002ade <argraw+0x30>
    return p->trapframe->a5;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6fc8                	ld	a0,152(a5)
    80002b04:	bfe9                	j	80002ade <argraw+0x30>
  panic("argraw");
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	8ba50513          	addi	a0,a0,-1862 # 800083c0 <states.1706+0x140>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a3a080e7          	jalr	-1478(ra) # 80000548 <panic>

0000000080002b16 <fetchaddr>:
{
    80002b16:	1101                	addi	sp,sp,-32
    80002b18:	ec06                	sd	ra,24(sp)
    80002b1a:	e822                	sd	s0,16(sp)
    80002b1c:	e426                	sd	s1,8(sp)
    80002b1e:	e04a                	sd	s2,0(sp)
    80002b20:	1000                	addi	s0,sp,32
    80002b22:	84aa                	mv	s1,a0
    80002b24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	f98080e7          	jalr	-104(ra) # 80001abe <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b2e:	653c                	ld	a5,72(a0)
    80002b30:	02f4f863          	bgeu	s1,a5,80002b60 <fetchaddr+0x4a>
    80002b34:	00848713          	addi	a4,s1,8
    80002b38:	02e7e663          	bltu	a5,a4,80002b64 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b3c:	46a1                	li	a3,8
    80002b3e:	8626                	mv	a2,s1
    80002b40:	85ca                	mv	a1,s2
    80002b42:	6928                	ld	a0,80(a0)
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	ce0080e7          	jalr	-800(ra) # 80001824 <copyin>
    80002b4c:	00a03533          	snez	a0,a0
    80002b50:	40a00533          	neg	a0,a0
}
    80002b54:	60e2                	ld	ra,24(sp)
    80002b56:	6442                	ld	s0,16(sp)
    80002b58:	64a2                	ld	s1,8(sp)
    80002b5a:	6902                	ld	s2,0(sp)
    80002b5c:	6105                	addi	sp,sp,32
    80002b5e:	8082                	ret
    return -1;
    80002b60:	557d                	li	a0,-1
    80002b62:	bfcd                	j	80002b54 <fetchaddr+0x3e>
    80002b64:	557d                	li	a0,-1
    80002b66:	b7fd                	j	80002b54 <fetchaddr+0x3e>

0000000080002b68 <fetchstr>:
{
    80002b68:	7179                	addi	sp,sp,-48
    80002b6a:	f406                	sd	ra,40(sp)
    80002b6c:	f022                	sd	s0,32(sp)
    80002b6e:	ec26                	sd	s1,24(sp)
    80002b70:	e84a                	sd	s2,16(sp)
    80002b72:	e44e                	sd	s3,8(sp)
    80002b74:	1800                	addi	s0,sp,48
    80002b76:	892a                	mv	s2,a0
    80002b78:	84ae                	mv	s1,a1
    80002b7a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	f42080e7          	jalr	-190(ra) # 80001abe <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b84:	86ce                	mv	a3,s3
    80002b86:	864a                	mv	a2,s2
    80002b88:	85a6                	mv	a1,s1
    80002b8a:	6928                	ld	a0,80(a0)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	d3e080e7          	jalr	-706(ra) # 800018ca <copyinstr>
  if(err < 0)
    80002b94:	00054763          	bltz	a0,80002ba2 <fetchstr+0x3a>
  return strlen(buf);
    80002b98:	8526                	mv	a0,s1
    80002b9a:	ffffe097          	auipc	ra,0xffffe
    80002b9e:	2fa080e7          	jalr	762(ra) # 80000e94 <strlen>
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6145                	addi	sp,sp,48
    80002bae:	8082                	ret

0000000080002bb0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb0:	1101                	addi	sp,sp,-32
    80002bb2:	ec06                	sd	ra,24(sp)
    80002bb4:	e822                	sd	s0,16(sp)
    80002bb6:	e426                	sd	s1,8(sp)
    80002bb8:	1000                	addi	s0,sp,32
    80002bba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	ef2080e7          	jalr	-270(ra) # 80002aae <argraw>
    80002bc4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bc6:	4501                	li	a0,0
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6105                	addi	sp,sp,32
    80002bd0:	8082                	ret

0000000080002bd2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bd2:	1101                	addi	sp,sp,-32
    80002bd4:	ec06                	sd	ra,24(sp)
    80002bd6:	e822                	sd	s0,16(sp)
    80002bd8:	e426                	sd	s1,8(sp)
    80002bda:	1000                	addi	s0,sp,32
    80002bdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bde:	00000097          	auipc	ra,0x0
    80002be2:	ed0080e7          	jalr	-304(ra) # 80002aae <argraw>
    80002be6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	64a2                	ld	s1,8(sp)
    80002bf0:	6105                	addi	sp,sp,32
    80002bf2:	8082                	ret

0000000080002bf4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bf4:	1101                	addi	sp,sp,-32
    80002bf6:	ec06                	sd	ra,24(sp)
    80002bf8:	e822                	sd	s0,16(sp)
    80002bfa:	e426                	sd	s1,8(sp)
    80002bfc:	e04a                	sd	s2,0(sp)
    80002bfe:	1000                	addi	s0,sp,32
    80002c00:	84ae                	mv	s1,a1
    80002c02:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c04:	00000097          	auipc	ra,0x0
    80002c08:	eaa080e7          	jalr	-342(ra) # 80002aae <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c0c:	864a                	mv	a2,s2
    80002c0e:	85a6                	mv	a1,s1
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	f58080e7          	jalr	-168(ra) # 80002b68 <fetchstr>
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret

0000000080002c24 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c24:	1101                	addi	sp,sp,-32
    80002c26:	ec06                	sd	ra,24(sp)
    80002c28:	e822                	sd	s0,16(sp)
    80002c2a:	e426                	sd	s1,8(sp)
    80002c2c:	e04a                	sd	s2,0(sp)
    80002c2e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	e8e080e7          	jalr	-370(ra) # 80001abe <myproc>
    80002c38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c3a:	05853903          	ld	s2,88(a0)
    80002c3e:	0a893783          	ld	a5,168(s2)
    80002c42:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c46:	37fd                	addiw	a5,a5,-1
    80002c48:	4751                	li	a4,20
    80002c4a:	00f76f63          	bltu	a4,a5,80002c68 <syscall+0x44>
    80002c4e:	00369713          	slli	a4,a3,0x3
    80002c52:	00005797          	auipc	a5,0x5
    80002c56:	7ae78793          	addi	a5,a5,1966 # 80008400 <syscalls>
    80002c5a:	97ba                	add	a5,a5,a4
    80002c5c:	639c                	ld	a5,0(a5)
    80002c5e:	c789                	beqz	a5,80002c68 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c60:	9782                	jalr	a5
    80002c62:	06a93823          	sd	a0,112(s2)
    80002c66:	a839                	j	80002c84 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c68:	15848613          	addi	a2,s1,344
    80002c6c:	5c8c                	lw	a1,56(s1)
    80002c6e:	00005517          	auipc	a0,0x5
    80002c72:	75a50513          	addi	a0,a0,1882 # 800083c8 <states.1706+0x148>
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	91c080e7          	jalr	-1764(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c7e:	6cbc                	ld	a5,88(s1)
    80002c80:	577d                	li	a4,-1
    80002c82:	fbb8                	sd	a4,112(a5)
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6902                	ld	s2,0(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c98:	fec40593          	addi	a1,s0,-20
    80002c9c:	4501                	li	a0,0
    80002c9e:	00000097          	auipc	ra,0x0
    80002ca2:	f12080e7          	jalr	-238(ra) # 80002bb0 <argint>
    return -1;
    80002ca6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca8:	00054963          	bltz	a0,80002cba <sys_exit+0x2a>
  exit(n);
    80002cac:	fec42503          	lw	a0,-20(s0)
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	4d8080e7          	jalr	1240(ra) # 80002188 <exit>
  return 0;  // not reached
    80002cb8:	4781                	li	a5,0
}
    80002cba:	853e                	mv	a0,a5
    80002cbc:	60e2                	ld	ra,24(sp)
    80002cbe:	6442                	ld	s0,16(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cc4:	1141                	addi	sp,sp,-16
    80002cc6:	e406                	sd	ra,8(sp)
    80002cc8:	e022                	sd	s0,0(sp)
    80002cca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	df2080e7          	jalr	-526(ra) # 80001abe <myproc>
}
    80002cd4:	5d08                	lw	a0,56(a0)
    80002cd6:	60a2                	ld	ra,8(sp)
    80002cd8:	6402                	ld	s0,0(sp)
    80002cda:	0141                	addi	sp,sp,16
    80002cdc:	8082                	ret

0000000080002cde <sys_fork>:

uint64
sys_fork(void)
{
    80002cde:	1141                	addi	sp,sp,-16
    80002ce0:	e406                	sd	ra,8(sp)
    80002ce2:	e022                	sd	s0,0(sp)
    80002ce4:	0800                	addi	s0,sp,16
  return fork();
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	198080e7          	jalr	408(ra) # 80001e7e <fork>
}
    80002cee:	60a2                	ld	ra,8(sp)
    80002cf0:	6402                	ld	s0,0(sp)
    80002cf2:	0141                	addi	sp,sp,16
    80002cf4:	8082                	ret

0000000080002cf6 <sys_wait>:

uint64
sys_wait(void)
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cfe:	fe840593          	addi	a1,s0,-24
    80002d02:	4501                	li	a0,0
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	ece080e7          	jalr	-306(ra) # 80002bd2 <argaddr>
    80002d0c:	87aa                	mv	a5,a0
    return -1;
    80002d0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002d10:	0007c863          	bltz	a5,80002d20 <sys_wait+0x2a>
  return wait(p);
    80002d14:	fe843503          	ld	a0,-24(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	634080e7          	jalr	1588(ra) # 8000234c <wait>
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	6105                	addi	sp,sp,32
    80002d26:	8082                	ret

0000000080002d28 <sys_sbrk>:
//     return -1;
//   return addr;
// }
uint64
sys_sbrk(void)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	e84a                	sd	s2,16(sp)
    80002d32:	1800                	addi	s0,sp,48
  int addr;
  int n;
  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	d8a080e7          	jalr	-630(ra) # 80001abe <myproc>
    80002d3c:	84aa                	mv	s1,a0
  if(argint(0, &n) < 0)
    80002d3e:	fdc40593          	addi	a1,s0,-36
    80002d42:	4501                	li	a0,0
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	e6c080e7          	jalr	-404(ra) # 80002bb0 <argint>
    80002d4c:	02054c63          	bltz	a0,80002d84 <sys_sbrk+0x5c>
    return -1;
  addr = p->sz;
    80002d50:	64ac                	ld	a1,72(s1)
    80002d52:	0005891b          	sext.w	s2,a1
  if(n < 0) {
    80002d56:	fdc42603          	lw	a2,-36(s0)
    80002d5a:	00064e63          	bltz	a2,80002d76 <sys_sbrk+0x4e>
    uvmdealloc(p->pagetable, p->sz, p->sz+n); // 如果是缩小空间，则马上释放
  }
  p->sz += n; // 懒分配
    80002d5e:	fdc42703          	lw	a4,-36(s0)
    80002d62:	64bc                	ld	a5,72(s1)
    80002d64:	97ba                	add	a5,a5,a4
    80002d66:	e4bc                	sd	a5,72(s1)
  return addr;
    80002d68:	854a                	mv	a0,s2
}
    80002d6a:	70a2                	ld	ra,40(sp)
    80002d6c:	7402                	ld	s0,32(sp)
    80002d6e:	64e2                	ld	s1,24(sp)
    80002d70:	6942                	ld	s2,16(sp)
    80002d72:	6145                	addi	sp,sp,48
    80002d74:	8082                	ret
    uvmdealloc(p->pagetable, p->sz, p->sz+n); // 如果是缩小空间，则马上释放
    80002d76:	962e                	add	a2,a2,a1
    80002d78:	68a8                	ld	a0,80(s1)
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	6a2080e7          	jalr	1698(ra) # 8000141c <uvmdealloc>
    80002d82:	bff1                	j	80002d5e <sys_sbrk+0x36>
    return -1;
    80002d84:	557d                	li	a0,-1
    80002d86:	b7d5                	j	80002d6a <sys_sbrk+0x42>

0000000080002d88 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d88:	7139                	addi	sp,sp,-64
    80002d8a:	fc06                	sd	ra,56(sp)
    80002d8c:	f822                	sd	s0,48(sp)
    80002d8e:	f426                	sd	s1,40(sp)
    80002d90:	f04a                	sd	s2,32(sp)
    80002d92:	ec4e                	sd	s3,24(sp)
    80002d94:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d96:	fcc40593          	addi	a1,s0,-52
    80002d9a:	4501                	li	a0,0
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	e14080e7          	jalr	-492(ra) # 80002bb0 <argint>
    return -1;
    80002da4:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002da6:	06054563          	bltz	a0,80002e10 <sys_sleep+0x88>
  acquire(&tickslock);
    80002daa:	00015517          	auipc	a0,0x15
    80002dae:	9be50513          	addi	a0,a0,-1602 # 80017768 <tickslock>
    80002db2:	ffffe097          	auipc	ra,0xffffe
    80002db6:	e5e080e7          	jalr	-418(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002dba:	00006917          	auipc	s2,0x6
    80002dbe:	26692903          	lw	s2,614(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002dc2:	fcc42783          	lw	a5,-52(s0)
    80002dc6:	cf85                	beqz	a5,80002dfe <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dc8:	00015997          	auipc	s3,0x15
    80002dcc:	9a098993          	addi	s3,s3,-1632 # 80017768 <tickslock>
    80002dd0:	00006497          	auipc	s1,0x6
    80002dd4:	25048493          	addi	s1,s1,592 # 80009020 <ticks>
    if(myproc()->killed){
    80002dd8:	fffff097          	auipc	ra,0xfffff
    80002ddc:	ce6080e7          	jalr	-794(ra) # 80001abe <myproc>
    80002de0:	591c                	lw	a5,48(a0)
    80002de2:	ef9d                	bnez	a5,80002e20 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002de4:	85ce                	mv	a1,s3
    80002de6:	8526                	mv	a0,s1
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	4e6080e7          	jalr	1254(ra) # 800022ce <sleep>
  while(ticks - ticks0 < n){
    80002df0:	409c                	lw	a5,0(s1)
    80002df2:	412787bb          	subw	a5,a5,s2
    80002df6:	fcc42703          	lw	a4,-52(s0)
    80002dfa:	fce7efe3          	bltu	a5,a4,80002dd8 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002dfe:	00015517          	auipc	a0,0x15
    80002e02:	96a50513          	addi	a0,a0,-1686 # 80017768 <tickslock>
    80002e06:	ffffe097          	auipc	ra,0xffffe
    80002e0a:	ebe080e7          	jalr	-322(ra) # 80000cc4 <release>
  return 0;
    80002e0e:	4781                	li	a5,0
}
    80002e10:	853e                	mv	a0,a5
    80002e12:	70e2                	ld	ra,56(sp)
    80002e14:	7442                	ld	s0,48(sp)
    80002e16:	74a2                	ld	s1,40(sp)
    80002e18:	7902                	ld	s2,32(sp)
    80002e1a:	69e2                	ld	s3,24(sp)
    80002e1c:	6121                	addi	sp,sp,64
    80002e1e:	8082                	ret
      release(&tickslock);
    80002e20:	00015517          	auipc	a0,0x15
    80002e24:	94850513          	addi	a0,a0,-1720 # 80017768 <tickslock>
    80002e28:	ffffe097          	auipc	ra,0xffffe
    80002e2c:	e9c080e7          	jalr	-356(ra) # 80000cc4 <release>
      return -1;
    80002e30:	57fd                	li	a5,-1
    80002e32:	bff9                	j	80002e10 <sys_sleep+0x88>

0000000080002e34 <sys_kill>:

uint64
sys_kill(void)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e3c:	fec40593          	addi	a1,s0,-20
    80002e40:	4501                	li	a0,0
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	d6e080e7          	jalr	-658(ra) # 80002bb0 <argint>
    80002e4a:	87aa                	mv	a5,a0
    return -1;
    80002e4c:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002e4e:	0007c863          	bltz	a5,80002e5e <sys_kill+0x2a>
  return kill(pid);
    80002e52:	fec42503          	lw	a0,-20(s0)
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	668080e7          	jalr	1640(ra) # 800024be <kill>
}
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	6105                	addi	sp,sp,32
    80002e64:	8082                	ret

0000000080002e66 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e70:	00015517          	auipc	a0,0x15
    80002e74:	8f850513          	addi	a0,a0,-1800 # 80017768 <tickslock>
    80002e78:	ffffe097          	auipc	ra,0xffffe
    80002e7c:	d98080e7          	jalr	-616(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002e80:	00006497          	auipc	s1,0x6
    80002e84:	1a04a483          	lw	s1,416(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e88:	00015517          	auipc	a0,0x15
    80002e8c:	8e050513          	addi	a0,a0,-1824 # 80017768 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	e34080e7          	jalr	-460(ra) # 80000cc4 <release>
  return xticks;
}
    80002e98:	02049513          	slli	a0,s1,0x20
    80002e9c:	9101                	srli	a0,a0,0x20
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	64a2                	ld	s1,8(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ea8:	7179                	addi	sp,sp,-48
    80002eaa:	f406                	sd	ra,40(sp)
    80002eac:	f022                	sd	s0,32(sp)
    80002eae:	ec26                	sd	s1,24(sp)
    80002eb0:	e84a                	sd	s2,16(sp)
    80002eb2:	e44e                	sd	s3,8(sp)
    80002eb4:	e052                	sd	s4,0(sp)
    80002eb6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eb8:	00005597          	auipc	a1,0x5
    80002ebc:	5f858593          	addi	a1,a1,1528 # 800084b0 <syscalls+0xb0>
    80002ec0:	00015517          	auipc	a0,0x15
    80002ec4:	8c050513          	addi	a0,a0,-1856 # 80017780 <bcache>
    80002ec8:	ffffe097          	auipc	ra,0xffffe
    80002ecc:	cb8080e7          	jalr	-840(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed0:	0001d797          	auipc	a5,0x1d
    80002ed4:	8b078793          	addi	a5,a5,-1872 # 8001f780 <bcache+0x8000>
    80002ed8:	0001d717          	auipc	a4,0x1d
    80002edc:	b1070713          	addi	a4,a4,-1264 # 8001f9e8 <bcache+0x8268>
    80002ee0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ee8:	00015497          	auipc	s1,0x15
    80002eec:	8b048493          	addi	s1,s1,-1872 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef4:	00005a17          	auipc	s4,0x5
    80002ef8:	5c4a0a13          	addi	s4,s4,1476 # 800084b8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002efc:	2b893783          	ld	a5,696(s2)
    80002f00:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f02:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f06:	85d2                	mv	a1,s4
    80002f08:	01048513          	addi	a0,s1,16
    80002f0c:	00001097          	auipc	ra,0x1
    80002f10:	4b0080e7          	jalr	1200(ra) # 800043bc <initsleeplock>
    bcache.head.next->prev = b;
    80002f14:	2b893783          	ld	a5,696(s2)
    80002f18:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f1e:	45848493          	addi	s1,s1,1112
    80002f22:	fd349de3          	bne	s1,s3,80002efc <binit+0x54>
  }
}
    80002f26:	70a2                	ld	ra,40(sp)
    80002f28:	7402                	ld	s0,32(sp)
    80002f2a:	64e2                	ld	s1,24(sp)
    80002f2c:	6942                	ld	s2,16(sp)
    80002f2e:	69a2                	ld	s3,8(sp)
    80002f30:	6a02                	ld	s4,0(sp)
    80002f32:	6145                	addi	sp,sp,48
    80002f34:	8082                	ret

0000000080002f36 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f36:	7179                	addi	sp,sp,-48
    80002f38:	f406                	sd	ra,40(sp)
    80002f3a:	f022                	sd	s0,32(sp)
    80002f3c:	ec26                	sd	s1,24(sp)
    80002f3e:	e84a                	sd	s2,16(sp)
    80002f40:	e44e                	sd	s3,8(sp)
    80002f42:	1800                	addi	s0,sp,48
    80002f44:	89aa                	mv	s3,a0
    80002f46:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f48:	00015517          	auipc	a0,0x15
    80002f4c:	83850513          	addi	a0,a0,-1992 # 80017780 <bcache>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	cc0080e7          	jalr	-832(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f58:	0001d497          	auipc	s1,0x1d
    80002f5c:	ae04b483          	ld	s1,-1312(s1) # 8001fa38 <bcache+0x82b8>
    80002f60:	0001d797          	auipc	a5,0x1d
    80002f64:	a8878793          	addi	a5,a5,-1400 # 8001f9e8 <bcache+0x8268>
    80002f68:	02f48f63          	beq	s1,a5,80002fa6 <bread+0x70>
    80002f6c:	873e                	mv	a4,a5
    80002f6e:	a021                	j	80002f76 <bread+0x40>
    80002f70:	68a4                	ld	s1,80(s1)
    80002f72:	02e48a63          	beq	s1,a4,80002fa6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f76:	449c                	lw	a5,8(s1)
    80002f78:	ff379ce3          	bne	a5,s3,80002f70 <bread+0x3a>
    80002f7c:	44dc                	lw	a5,12(s1)
    80002f7e:	ff2799e3          	bne	a5,s2,80002f70 <bread+0x3a>
      b->refcnt++;
    80002f82:	40bc                	lw	a5,64(s1)
    80002f84:	2785                	addiw	a5,a5,1
    80002f86:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f88:	00014517          	auipc	a0,0x14
    80002f8c:	7f850513          	addi	a0,a0,2040 # 80017780 <bcache>
    80002f90:	ffffe097          	auipc	ra,0xffffe
    80002f94:	d34080e7          	jalr	-716(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002f98:	01048513          	addi	a0,s1,16
    80002f9c:	00001097          	auipc	ra,0x1
    80002fa0:	45a080e7          	jalr	1114(ra) # 800043f6 <acquiresleep>
      return b;
    80002fa4:	a8b9                	j	80003002 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fa6:	0001d497          	auipc	s1,0x1d
    80002faa:	a8a4b483          	ld	s1,-1398(s1) # 8001fa30 <bcache+0x82b0>
    80002fae:	0001d797          	auipc	a5,0x1d
    80002fb2:	a3a78793          	addi	a5,a5,-1478 # 8001f9e8 <bcache+0x8268>
    80002fb6:	00f48863          	beq	s1,a5,80002fc6 <bread+0x90>
    80002fba:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fbc:	40bc                	lw	a5,64(s1)
    80002fbe:	cf81                	beqz	a5,80002fd6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc0:	64a4                	ld	s1,72(s1)
    80002fc2:	fee49de3          	bne	s1,a4,80002fbc <bread+0x86>
  panic("bget: no buffers");
    80002fc6:	00005517          	auipc	a0,0x5
    80002fca:	4fa50513          	addi	a0,a0,1274 # 800084c0 <syscalls+0xc0>
    80002fce:	ffffd097          	auipc	ra,0xffffd
    80002fd2:	57a080e7          	jalr	1402(ra) # 80000548 <panic>
      b->dev = dev;
    80002fd6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fda:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fde:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe2:	4785                	li	a5,1
    80002fe4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe6:	00014517          	auipc	a0,0x14
    80002fea:	79a50513          	addi	a0,a0,1946 # 80017780 <bcache>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	cd6080e7          	jalr	-810(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80002ff6:	01048513          	addi	a0,s1,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	3fc080e7          	jalr	1020(ra) # 800043f6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003002:	409c                	lw	a5,0(s1)
    80003004:	cb89                	beqz	a5,80003016 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003006:	8526                	mv	a0,s1
    80003008:	70a2                	ld	ra,40(sp)
    8000300a:	7402                	ld	s0,32(sp)
    8000300c:	64e2                	ld	s1,24(sp)
    8000300e:	6942                	ld	s2,16(sp)
    80003010:	69a2                	ld	s3,8(sp)
    80003012:	6145                	addi	sp,sp,48
    80003014:	8082                	ret
    virtio_disk_rw(b, 0);
    80003016:	4581                	li	a1,0
    80003018:	8526                	mv	a0,s1
    8000301a:	00003097          	auipc	ra,0x3
    8000301e:	f32080e7          	jalr	-206(ra) # 80005f4c <virtio_disk_rw>
    b->valid = 1;
    80003022:	4785                	li	a5,1
    80003024:	c09c                	sw	a5,0(s1)
  return b;
    80003026:	b7c5                	j	80003006 <bread+0xd0>

0000000080003028 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	e426                	sd	s1,8(sp)
    80003030:	1000                	addi	s0,sp,32
    80003032:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003034:	0541                	addi	a0,a0,16
    80003036:	00001097          	auipc	ra,0x1
    8000303a:	45a080e7          	jalr	1114(ra) # 80004490 <holdingsleep>
    8000303e:	cd01                	beqz	a0,80003056 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003040:	4585                	li	a1,1
    80003042:	8526                	mv	a0,s1
    80003044:	00003097          	auipc	ra,0x3
    80003048:	f08080e7          	jalr	-248(ra) # 80005f4c <virtio_disk_rw>
}
    8000304c:	60e2                	ld	ra,24(sp)
    8000304e:	6442                	ld	s0,16(sp)
    80003050:	64a2                	ld	s1,8(sp)
    80003052:	6105                	addi	sp,sp,32
    80003054:	8082                	ret
    panic("bwrite");
    80003056:	00005517          	auipc	a0,0x5
    8000305a:	48250513          	addi	a0,a0,1154 # 800084d8 <syscalls+0xd8>
    8000305e:	ffffd097          	auipc	ra,0xffffd
    80003062:	4ea080e7          	jalr	1258(ra) # 80000548 <panic>

0000000080003066 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	e426                	sd	s1,8(sp)
    8000306e:	e04a                	sd	s2,0(sp)
    80003070:	1000                	addi	s0,sp,32
    80003072:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003074:	01050913          	addi	s2,a0,16
    80003078:	854a                	mv	a0,s2
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	416080e7          	jalr	1046(ra) # 80004490 <holdingsleep>
    80003082:	c92d                	beqz	a0,800030f4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003084:	854a                	mv	a0,s2
    80003086:	00001097          	auipc	ra,0x1
    8000308a:	3c6080e7          	jalr	966(ra) # 8000444c <releasesleep>

  acquire(&bcache.lock);
    8000308e:	00014517          	auipc	a0,0x14
    80003092:	6f250513          	addi	a0,a0,1778 # 80017780 <bcache>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	b7a080e7          	jalr	-1158(ra) # 80000c10 <acquire>
  b->refcnt--;
    8000309e:	40bc                	lw	a5,64(s1)
    800030a0:	37fd                	addiw	a5,a5,-1
    800030a2:	0007871b          	sext.w	a4,a5
    800030a6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030a8:	eb05                	bnez	a4,800030d8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030aa:	68bc                	ld	a5,80(s1)
    800030ac:	64b8                	ld	a4,72(s1)
    800030ae:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b0:	64bc                	ld	a5,72(s1)
    800030b2:	68b8                	ld	a4,80(s1)
    800030b4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b6:	0001c797          	auipc	a5,0x1c
    800030ba:	6ca78793          	addi	a5,a5,1738 # 8001f780 <bcache+0x8000>
    800030be:	2b87b703          	ld	a4,696(a5)
    800030c2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c4:	0001d717          	auipc	a4,0x1d
    800030c8:	92470713          	addi	a4,a4,-1756 # 8001f9e8 <bcache+0x8268>
    800030cc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ce:	2b87b703          	ld	a4,696(a5)
    800030d2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030d8:	00014517          	auipc	a0,0x14
    800030dc:	6a850513          	addi	a0,a0,1704 # 80017780 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	be4080e7          	jalr	-1052(ra) # 80000cc4 <release>
}
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6902                	ld	s2,0(sp)
    800030f0:	6105                	addi	sp,sp,32
    800030f2:	8082                	ret
    panic("brelse");
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	3ec50513          	addi	a0,a0,1004 # 800084e0 <syscalls+0xe0>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	44c080e7          	jalr	1100(ra) # 80000548 <panic>

0000000080003104 <bpin>:

void
bpin(struct buf *b) {
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	e426                	sd	s1,8(sp)
    8000310c:	1000                	addi	s0,sp,32
    8000310e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003110:	00014517          	auipc	a0,0x14
    80003114:	67050513          	addi	a0,a0,1648 # 80017780 <bcache>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	af8080e7          	jalr	-1288(ra) # 80000c10 <acquire>
  b->refcnt++;
    80003120:	40bc                	lw	a5,64(s1)
    80003122:	2785                	addiw	a5,a5,1
    80003124:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003126:	00014517          	auipc	a0,0x14
    8000312a:	65a50513          	addi	a0,a0,1626 # 80017780 <bcache>
    8000312e:	ffffe097          	auipc	ra,0xffffe
    80003132:	b96080e7          	jalr	-1130(ra) # 80000cc4 <release>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret

0000000080003140 <bunpin>:

void
bunpin(struct buf *b) {
    80003140:	1101                	addi	sp,sp,-32
    80003142:	ec06                	sd	ra,24(sp)
    80003144:	e822                	sd	s0,16(sp)
    80003146:	e426                	sd	s1,8(sp)
    80003148:	1000                	addi	s0,sp,32
    8000314a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	63450513          	addi	a0,a0,1588 # 80017780 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	abc080e7          	jalr	-1348(ra) # 80000c10 <acquire>
  b->refcnt--;
    8000315c:	40bc                	lw	a5,64(s1)
    8000315e:	37fd                	addiw	a5,a5,-1
    80003160:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003162:	00014517          	auipc	a0,0x14
    80003166:	61e50513          	addi	a0,a0,1566 # 80017780 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	b5a080e7          	jalr	-1190(ra) # 80000cc4 <release>
}
    80003172:	60e2                	ld	ra,24(sp)
    80003174:	6442                	ld	s0,16(sp)
    80003176:	64a2                	ld	s1,8(sp)
    80003178:	6105                	addi	sp,sp,32
    8000317a:	8082                	ret

000000008000317c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000317c:	1101                	addi	sp,sp,-32
    8000317e:	ec06                	sd	ra,24(sp)
    80003180:	e822                	sd	s0,16(sp)
    80003182:	e426                	sd	s1,8(sp)
    80003184:	e04a                	sd	s2,0(sp)
    80003186:	1000                	addi	s0,sp,32
    80003188:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000318a:	00d5d59b          	srliw	a1,a1,0xd
    8000318e:	0001d797          	auipc	a5,0x1d
    80003192:	cce7a783          	lw	a5,-818(a5) # 8001fe5c <sb+0x1c>
    80003196:	9dbd                	addw	a1,a1,a5
    80003198:	00000097          	auipc	ra,0x0
    8000319c:	d9e080e7          	jalr	-610(ra) # 80002f36 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a0:	0074f713          	andi	a4,s1,7
    800031a4:	4785                	li	a5,1
    800031a6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031aa:	14ce                	slli	s1,s1,0x33
    800031ac:	90d9                	srli	s1,s1,0x36
    800031ae:	00950733          	add	a4,a0,s1
    800031b2:	05874703          	lbu	a4,88(a4)
    800031b6:	00e7f6b3          	and	a3,a5,a4
    800031ba:	c69d                	beqz	a3,800031e8 <bfree+0x6c>
    800031bc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031be:	94aa                	add	s1,s1,a0
    800031c0:	fff7c793          	not	a5,a5
    800031c4:	8ff9                	and	a5,a5,a4
    800031c6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031ca:	00001097          	auipc	ra,0x1
    800031ce:	104080e7          	jalr	260(ra) # 800042ce <log_write>
  brelse(bp);
    800031d2:	854a                	mv	a0,s2
    800031d4:	00000097          	auipc	ra,0x0
    800031d8:	e92080e7          	jalr	-366(ra) # 80003066 <brelse>
}
    800031dc:	60e2                	ld	ra,24(sp)
    800031de:	6442                	ld	s0,16(sp)
    800031e0:	64a2                	ld	s1,8(sp)
    800031e2:	6902                	ld	s2,0(sp)
    800031e4:	6105                	addi	sp,sp,32
    800031e6:	8082                	ret
    panic("freeing free block");
    800031e8:	00005517          	auipc	a0,0x5
    800031ec:	30050513          	addi	a0,a0,768 # 800084e8 <syscalls+0xe8>
    800031f0:	ffffd097          	auipc	ra,0xffffd
    800031f4:	358080e7          	jalr	856(ra) # 80000548 <panic>

00000000800031f8 <balloc>:
{
    800031f8:	711d                	addi	sp,sp,-96
    800031fa:	ec86                	sd	ra,88(sp)
    800031fc:	e8a2                	sd	s0,80(sp)
    800031fe:	e4a6                	sd	s1,72(sp)
    80003200:	e0ca                	sd	s2,64(sp)
    80003202:	fc4e                	sd	s3,56(sp)
    80003204:	f852                	sd	s4,48(sp)
    80003206:	f456                	sd	s5,40(sp)
    80003208:	f05a                	sd	s6,32(sp)
    8000320a:	ec5e                	sd	s7,24(sp)
    8000320c:	e862                	sd	s8,16(sp)
    8000320e:	e466                	sd	s9,8(sp)
    80003210:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003212:	0001d797          	auipc	a5,0x1d
    80003216:	c327a783          	lw	a5,-974(a5) # 8001fe44 <sb+0x4>
    8000321a:	cbd1                	beqz	a5,800032ae <balloc+0xb6>
    8000321c:	8baa                	mv	s7,a0
    8000321e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003220:	0001db17          	auipc	s6,0x1d
    80003224:	c20b0b13          	addi	s6,s6,-992 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003228:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000322a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000322e:	6c89                	lui	s9,0x2
    80003230:	a831                	j	8000324c <balloc+0x54>
    brelse(bp);
    80003232:	854a                	mv	a0,s2
    80003234:	00000097          	auipc	ra,0x0
    80003238:	e32080e7          	jalr	-462(ra) # 80003066 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000323c:	015c87bb          	addw	a5,s9,s5
    80003240:	00078a9b          	sext.w	s5,a5
    80003244:	004b2703          	lw	a4,4(s6)
    80003248:	06eaf363          	bgeu	s5,a4,800032ae <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000324c:	41fad79b          	sraiw	a5,s5,0x1f
    80003250:	0137d79b          	srliw	a5,a5,0x13
    80003254:	015787bb          	addw	a5,a5,s5
    80003258:	40d7d79b          	sraiw	a5,a5,0xd
    8000325c:	01cb2583          	lw	a1,28(s6)
    80003260:	9dbd                	addw	a1,a1,a5
    80003262:	855e                	mv	a0,s7
    80003264:	00000097          	auipc	ra,0x0
    80003268:	cd2080e7          	jalr	-814(ra) # 80002f36 <bread>
    8000326c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326e:	004b2503          	lw	a0,4(s6)
    80003272:	000a849b          	sext.w	s1,s5
    80003276:	8662                	mv	a2,s8
    80003278:	faa4fde3          	bgeu	s1,a0,80003232 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000327c:	41f6579b          	sraiw	a5,a2,0x1f
    80003280:	01d7d69b          	srliw	a3,a5,0x1d
    80003284:	00c6873b          	addw	a4,a3,a2
    80003288:	00777793          	andi	a5,a4,7
    8000328c:	9f95                	subw	a5,a5,a3
    8000328e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003292:	4037571b          	sraiw	a4,a4,0x3
    80003296:	00e906b3          	add	a3,s2,a4
    8000329a:	0586c683          	lbu	a3,88(a3)
    8000329e:	00d7f5b3          	and	a1,a5,a3
    800032a2:	cd91                	beqz	a1,800032be <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a4:	2605                	addiw	a2,a2,1
    800032a6:	2485                	addiw	s1,s1,1
    800032a8:	fd4618e3          	bne	a2,s4,80003278 <balloc+0x80>
    800032ac:	b759                	j	80003232 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032ae:	00005517          	auipc	a0,0x5
    800032b2:	25250513          	addi	a0,a0,594 # 80008500 <syscalls+0x100>
    800032b6:	ffffd097          	auipc	ra,0xffffd
    800032ba:	292080e7          	jalr	658(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032be:	974a                	add	a4,a4,s2
    800032c0:	8fd5                	or	a5,a5,a3
    800032c2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032c6:	854a                	mv	a0,s2
    800032c8:	00001097          	auipc	ra,0x1
    800032cc:	006080e7          	jalr	6(ra) # 800042ce <log_write>
        brelse(bp);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	d94080e7          	jalr	-620(ra) # 80003066 <brelse>
  bp = bread(dev, bno);
    800032da:	85a6                	mv	a1,s1
    800032dc:	855e                	mv	a0,s7
    800032de:	00000097          	auipc	ra,0x0
    800032e2:	c58080e7          	jalr	-936(ra) # 80002f36 <bread>
    800032e6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032e8:	40000613          	li	a2,1024
    800032ec:	4581                	li	a1,0
    800032ee:	05850513          	addi	a0,a0,88
    800032f2:	ffffe097          	auipc	ra,0xffffe
    800032f6:	a1a080e7          	jalr	-1510(ra) # 80000d0c <memset>
  log_write(bp);
    800032fa:	854a                	mv	a0,s2
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	fd2080e7          	jalr	-46(ra) # 800042ce <log_write>
  brelse(bp);
    80003304:	854a                	mv	a0,s2
    80003306:	00000097          	auipc	ra,0x0
    8000330a:	d60080e7          	jalr	-672(ra) # 80003066 <brelse>
}
    8000330e:	8526                	mv	a0,s1
    80003310:	60e6                	ld	ra,88(sp)
    80003312:	6446                	ld	s0,80(sp)
    80003314:	64a6                	ld	s1,72(sp)
    80003316:	6906                	ld	s2,64(sp)
    80003318:	79e2                	ld	s3,56(sp)
    8000331a:	7a42                	ld	s4,48(sp)
    8000331c:	7aa2                	ld	s5,40(sp)
    8000331e:	7b02                	ld	s6,32(sp)
    80003320:	6be2                	ld	s7,24(sp)
    80003322:	6c42                	ld	s8,16(sp)
    80003324:	6ca2                	ld	s9,8(sp)
    80003326:	6125                	addi	sp,sp,96
    80003328:	8082                	ret

000000008000332a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000332a:	7179                	addi	sp,sp,-48
    8000332c:	f406                	sd	ra,40(sp)
    8000332e:	f022                	sd	s0,32(sp)
    80003330:	ec26                	sd	s1,24(sp)
    80003332:	e84a                	sd	s2,16(sp)
    80003334:	e44e                	sd	s3,8(sp)
    80003336:	e052                	sd	s4,0(sp)
    80003338:	1800                	addi	s0,sp,48
    8000333a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000333c:	47ad                	li	a5,11
    8000333e:	04b7fe63          	bgeu	a5,a1,8000339a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003342:	ff45849b          	addiw	s1,a1,-12
    80003346:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000334a:	0ff00793          	li	a5,255
    8000334e:	0ae7e363          	bltu	a5,a4,800033f4 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003352:	08052583          	lw	a1,128(a0)
    80003356:	c5ad                	beqz	a1,800033c0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003358:	00092503          	lw	a0,0(s2)
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	bda080e7          	jalr	-1062(ra) # 80002f36 <bread>
    80003364:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003366:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000336a:	02049593          	slli	a1,s1,0x20
    8000336e:	9181                	srli	a1,a1,0x20
    80003370:	058a                	slli	a1,a1,0x2
    80003372:	00b784b3          	add	s1,a5,a1
    80003376:	0004a983          	lw	s3,0(s1)
    8000337a:	04098d63          	beqz	s3,800033d4 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000337e:	8552                	mv	a0,s4
    80003380:	00000097          	auipc	ra,0x0
    80003384:	ce6080e7          	jalr	-794(ra) # 80003066 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003388:	854e                	mv	a0,s3
    8000338a:	70a2                	ld	ra,40(sp)
    8000338c:	7402                	ld	s0,32(sp)
    8000338e:	64e2                	ld	s1,24(sp)
    80003390:	6942                	ld	s2,16(sp)
    80003392:	69a2                	ld	s3,8(sp)
    80003394:	6a02                	ld	s4,0(sp)
    80003396:	6145                	addi	sp,sp,48
    80003398:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000339a:	02059493          	slli	s1,a1,0x20
    8000339e:	9081                	srli	s1,s1,0x20
    800033a0:	048a                	slli	s1,s1,0x2
    800033a2:	94aa                	add	s1,s1,a0
    800033a4:	0504a983          	lw	s3,80(s1)
    800033a8:	fe0990e3          	bnez	s3,80003388 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033ac:	4108                	lw	a0,0(a0)
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	e4a080e7          	jalr	-438(ra) # 800031f8 <balloc>
    800033b6:	0005099b          	sext.w	s3,a0
    800033ba:	0534a823          	sw	s3,80(s1)
    800033be:	b7e9                	j	80003388 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033c0:	4108                	lw	a0,0(a0)
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	e36080e7          	jalr	-458(ra) # 800031f8 <balloc>
    800033ca:	0005059b          	sext.w	a1,a0
    800033ce:	08b92023          	sw	a1,128(s2)
    800033d2:	b759                	j	80003358 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033d4:	00092503          	lw	a0,0(s2)
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	e20080e7          	jalr	-480(ra) # 800031f8 <balloc>
    800033e0:	0005099b          	sext.w	s3,a0
    800033e4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033e8:	8552                	mv	a0,s4
    800033ea:	00001097          	auipc	ra,0x1
    800033ee:	ee4080e7          	jalr	-284(ra) # 800042ce <log_write>
    800033f2:	b771                	j	8000337e <bmap+0x54>
  panic("bmap: out of range");
    800033f4:	00005517          	auipc	a0,0x5
    800033f8:	12450513          	addi	a0,a0,292 # 80008518 <syscalls+0x118>
    800033fc:	ffffd097          	auipc	ra,0xffffd
    80003400:	14c080e7          	jalr	332(ra) # 80000548 <panic>

0000000080003404 <iget>:
{
    80003404:	7179                	addi	sp,sp,-48
    80003406:	f406                	sd	ra,40(sp)
    80003408:	f022                	sd	s0,32(sp)
    8000340a:	ec26                	sd	s1,24(sp)
    8000340c:	e84a                	sd	s2,16(sp)
    8000340e:	e44e                	sd	s3,8(sp)
    80003410:	e052                	sd	s4,0(sp)
    80003412:	1800                	addi	s0,sp,48
    80003414:	89aa                	mv	s3,a0
    80003416:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003418:	0001d517          	auipc	a0,0x1d
    8000341c:	a4850513          	addi	a0,a0,-1464 # 8001fe60 <icache>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	7f0080e7          	jalr	2032(ra) # 80000c10 <acquire>
  empty = 0;
    80003428:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000342a:	0001d497          	auipc	s1,0x1d
    8000342e:	a4e48493          	addi	s1,s1,-1458 # 8001fe78 <icache+0x18>
    80003432:	0001e697          	auipc	a3,0x1e
    80003436:	4d668693          	addi	a3,a3,1238 # 80021908 <log>
    8000343a:	a039                	j	80003448 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000343c:	02090b63          	beqz	s2,80003472 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003440:	08848493          	addi	s1,s1,136
    80003444:	02d48a63          	beq	s1,a3,80003478 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003448:	449c                	lw	a5,8(s1)
    8000344a:	fef059e3          	blez	a5,8000343c <iget+0x38>
    8000344e:	4098                	lw	a4,0(s1)
    80003450:	ff3716e3          	bne	a4,s3,8000343c <iget+0x38>
    80003454:	40d8                	lw	a4,4(s1)
    80003456:	ff4713e3          	bne	a4,s4,8000343c <iget+0x38>
      ip->ref++;
    8000345a:	2785                	addiw	a5,a5,1
    8000345c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000345e:	0001d517          	auipc	a0,0x1d
    80003462:	a0250513          	addi	a0,a0,-1534 # 8001fe60 <icache>
    80003466:	ffffe097          	auipc	ra,0xffffe
    8000346a:	85e080e7          	jalr	-1954(ra) # 80000cc4 <release>
      return ip;
    8000346e:	8926                	mv	s2,s1
    80003470:	a03d                	j	8000349e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003472:	f7f9                	bnez	a5,80003440 <iget+0x3c>
    80003474:	8926                	mv	s2,s1
    80003476:	b7e9                	j	80003440 <iget+0x3c>
  if(empty == 0)
    80003478:	02090c63          	beqz	s2,800034b0 <iget+0xac>
  ip->dev = dev;
    8000347c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003480:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003484:	4785                	li	a5,1
    80003486:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000348a:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000348e:	0001d517          	auipc	a0,0x1d
    80003492:	9d250513          	addi	a0,a0,-1582 # 8001fe60 <icache>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	82e080e7          	jalr	-2002(ra) # 80000cc4 <release>
}
    8000349e:	854a                	mv	a0,s2
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6a02                	ld	s4,0(sp)
    800034ac:	6145                	addi	sp,sp,48
    800034ae:	8082                	ret
    panic("iget: no inodes");
    800034b0:	00005517          	auipc	a0,0x5
    800034b4:	08050513          	addi	a0,a0,128 # 80008530 <syscalls+0x130>
    800034b8:	ffffd097          	auipc	ra,0xffffd
    800034bc:	090080e7          	jalr	144(ra) # 80000548 <panic>

00000000800034c0 <fsinit>:
fsinit(int dev) {
    800034c0:	7179                	addi	sp,sp,-48
    800034c2:	f406                	sd	ra,40(sp)
    800034c4:	f022                	sd	s0,32(sp)
    800034c6:	ec26                	sd	s1,24(sp)
    800034c8:	e84a                	sd	s2,16(sp)
    800034ca:	e44e                	sd	s3,8(sp)
    800034cc:	1800                	addi	s0,sp,48
    800034ce:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d0:	4585                	li	a1,1
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	a64080e7          	jalr	-1436(ra) # 80002f36 <bread>
    800034da:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034dc:	0001d997          	auipc	s3,0x1d
    800034e0:	96498993          	addi	s3,s3,-1692 # 8001fe40 <sb>
    800034e4:	02000613          	li	a2,32
    800034e8:	05850593          	addi	a1,a0,88
    800034ec:	854e                	mv	a0,s3
    800034ee:	ffffe097          	auipc	ra,0xffffe
    800034f2:	87e080e7          	jalr	-1922(ra) # 80000d6c <memmove>
  brelse(bp);
    800034f6:	8526                	mv	a0,s1
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	b6e080e7          	jalr	-1170(ra) # 80003066 <brelse>
  if(sb.magic != FSMAGIC)
    80003500:	0009a703          	lw	a4,0(s3)
    80003504:	102037b7          	lui	a5,0x10203
    80003508:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000350c:	02f71263          	bne	a4,a5,80003530 <fsinit+0x70>
  initlog(dev, &sb);
    80003510:	0001d597          	auipc	a1,0x1d
    80003514:	93058593          	addi	a1,a1,-1744 # 8001fe40 <sb>
    80003518:	854a                	mv	a0,s2
    8000351a:	00001097          	auipc	ra,0x1
    8000351e:	b3c080e7          	jalr	-1220(ra) # 80004056 <initlog>
}
    80003522:	70a2                	ld	ra,40(sp)
    80003524:	7402                	ld	s0,32(sp)
    80003526:	64e2                	ld	s1,24(sp)
    80003528:	6942                	ld	s2,16(sp)
    8000352a:	69a2                	ld	s3,8(sp)
    8000352c:	6145                	addi	sp,sp,48
    8000352e:	8082                	ret
    panic("invalid file system");
    80003530:	00005517          	auipc	a0,0x5
    80003534:	01050513          	addi	a0,a0,16 # 80008540 <syscalls+0x140>
    80003538:	ffffd097          	auipc	ra,0xffffd
    8000353c:	010080e7          	jalr	16(ra) # 80000548 <panic>

0000000080003540 <iinit>:
{
    80003540:	7179                	addi	sp,sp,-48
    80003542:	f406                	sd	ra,40(sp)
    80003544:	f022                	sd	s0,32(sp)
    80003546:	ec26                	sd	s1,24(sp)
    80003548:	e84a                	sd	s2,16(sp)
    8000354a:	e44e                	sd	s3,8(sp)
    8000354c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000354e:	00005597          	auipc	a1,0x5
    80003552:	00a58593          	addi	a1,a1,10 # 80008558 <syscalls+0x158>
    80003556:	0001d517          	auipc	a0,0x1d
    8000355a:	90a50513          	addi	a0,a0,-1782 # 8001fe60 <icache>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	622080e7          	jalr	1570(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003566:	0001d497          	auipc	s1,0x1d
    8000356a:	92248493          	addi	s1,s1,-1758 # 8001fe88 <icache+0x28>
    8000356e:	0001e997          	auipc	s3,0x1e
    80003572:	3aa98993          	addi	s3,s3,938 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003576:	00005917          	auipc	s2,0x5
    8000357a:	fea90913          	addi	s2,s2,-22 # 80008560 <syscalls+0x160>
    8000357e:	85ca                	mv	a1,s2
    80003580:	8526                	mv	a0,s1
    80003582:	00001097          	auipc	ra,0x1
    80003586:	e3a080e7          	jalr	-454(ra) # 800043bc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000358a:	08848493          	addi	s1,s1,136
    8000358e:	ff3498e3          	bne	s1,s3,8000357e <iinit+0x3e>
}
    80003592:	70a2                	ld	ra,40(sp)
    80003594:	7402                	ld	s0,32(sp)
    80003596:	64e2                	ld	s1,24(sp)
    80003598:	6942                	ld	s2,16(sp)
    8000359a:	69a2                	ld	s3,8(sp)
    8000359c:	6145                	addi	sp,sp,48
    8000359e:	8082                	ret

00000000800035a0 <ialloc>:
{
    800035a0:	715d                	addi	sp,sp,-80
    800035a2:	e486                	sd	ra,72(sp)
    800035a4:	e0a2                	sd	s0,64(sp)
    800035a6:	fc26                	sd	s1,56(sp)
    800035a8:	f84a                	sd	s2,48(sp)
    800035aa:	f44e                	sd	s3,40(sp)
    800035ac:	f052                	sd	s4,32(sp)
    800035ae:	ec56                	sd	s5,24(sp)
    800035b0:	e85a                	sd	s6,16(sp)
    800035b2:	e45e                	sd	s7,8(sp)
    800035b4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035b6:	0001d717          	auipc	a4,0x1d
    800035ba:	89672703          	lw	a4,-1898(a4) # 8001fe4c <sb+0xc>
    800035be:	4785                	li	a5,1
    800035c0:	04e7fa63          	bgeu	a5,a4,80003614 <ialloc+0x74>
    800035c4:	8aaa                	mv	s5,a0
    800035c6:	8bae                	mv	s7,a1
    800035c8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035ca:	0001da17          	auipc	s4,0x1d
    800035ce:	876a0a13          	addi	s4,s4,-1930 # 8001fe40 <sb>
    800035d2:	00048b1b          	sext.w	s6,s1
    800035d6:	0044d593          	srli	a1,s1,0x4
    800035da:	018a2783          	lw	a5,24(s4)
    800035de:	9dbd                	addw	a1,a1,a5
    800035e0:	8556                	mv	a0,s5
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	954080e7          	jalr	-1708(ra) # 80002f36 <bread>
    800035ea:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035ec:	05850993          	addi	s3,a0,88
    800035f0:	00f4f793          	andi	a5,s1,15
    800035f4:	079a                	slli	a5,a5,0x6
    800035f6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035f8:	00099783          	lh	a5,0(s3)
    800035fc:	c785                	beqz	a5,80003624 <ialloc+0x84>
    brelse(bp);
    800035fe:	00000097          	auipc	ra,0x0
    80003602:	a68080e7          	jalr	-1432(ra) # 80003066 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003606:	0485                	addi	s1,s1,1
    80003608:	00ca2703          	lw	a4,12(s4)
    8000360c:	0004879b          	sext.w	a5,s1
    80003610:	fce7e1e3          	bltu	a5,a4,800035d2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003614:	00005517          	auipc	a0,0x5
    80003618:	f5450513          	addi	a0,a0,-172 # 80008568 <syscalls+0x168>
    8000361c:	ffffd097          	auipc	ra,0xffffd
    80003620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003624:	04000613          	li	a2,64
    80003628:	4581                	li	a1,0
    8000362a:	854e                	mv	a0,s3
    8000362c:	ffffd097          	auipc	ra,0xffffd
    80003630:	6e0080e7          	jalr	1760(ra) # 80000d0c <memset>
      dip->type = type;
    80003634:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003638:	854a                	mv	a0,s2
    8000363a:	00001097          	auipc	ra,0x1
    8000363e:	c94080e7          	jalr	-876(ra) # 800042ce <log_write>
      brelse(bp);
    80003642:	854a                	mv	a0,s2
    80003644:	00000097          	auipc	ra,0x0
    80003648:	a22080e7          	jalr	-1502(ra) # 80003066 <brelse>
      return iget(dev, inum);
    8000364c:	85da                	mv	a1,s6
    8000364e:	8556                	mv	a0,s5
    80003650:	00000097          	auipc	ra,0x0
    80003654:	db4080e7          	jalr	-588(ra) # 80003404 <iget>
}
    80003658:	60a6                	ld	ra,72(sp)
    8000365a:	6406                	ld	s0,64(sp)
    8000365c:	74e2                	ld	s1,56(sp)
    8000365e:	7942                	ld	s2,48(sp)
    80003660:	79a2                	ld	s3,40(sp)
    80003662:	7a02                	ld	s4,32(sp)
    80003664:	6ae2                	ld	s5,24(sp)
    80003666:	6b42                	ld	s6,16(sp)
    80003668:	6ba2                	ld	s7,8(sp)
    8000366a:	6161                	addi	sp,sp,80
    8000366c:	8082                	ret

000000008000366e <iupdate>:
{
    8000366e:	1101                	addi	sp,sp,-32
    80003670:	ec06                	sd	ra,24(sp)
    80003672:	e822                	sd	s0,16(sp)
    80003674:	e426                	sd	s1,8(sp)
    80003676:	e04a                	sd	s2,0(sp)
    80003678:	1000                	addi	s0,sp,32
    8000367a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000367c:	415c                	lw	a5,4(a0)
    8000367e:	0047d79b          	srliw	a5,a5,0x4
    80003682:	0001c597          	auipc	a1,0x1c
    80003686:	7d65a583          	lw	a1,2006(a1) # 8001fe58 <sb+0x18>
    8000368a:	9dbd                	addw	a1,a1,a5
    8000368c:	4108                	lw	a0,0(a0)
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	8a8080e7          	jalr	-1880(ra) # 80002f36 <bread>
    80003696:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003698:	05850793          	addi	a5,a0,88
    8000369c:	40c8                	lw	a0,4(s1)
    8000369e:	893d                	andi	a0,a0,15
    800036a0:	051a                	slli	a0,a0,0x6
    800036a2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036a4:	04449703          	lh	a4,68(s1)
    800036a8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036ac:	04649703          	lh	a4,70(s1)
    800036b0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036b4:	04849703          	lh	a4,72(s1)
    800036b8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036bc:	04a49703          	lh	a4,74(s1)
    800036c0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036c4:	44f8                	lw	a4,76(s1)
    800036c6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036c8:	03400613          	li	a2,52
    800036cc:	05048593          	addi	a1,s1,80
    800036d0:	0531                	addi	a0,a0,12
    800036d2:	ffffd097          	auipc	ra,0xffffd
    800036d6:	69a080e7          	jalr	1690(ra) # 80000d6c <memmove>
  log_write(bp);
    800036da:	854a                	mv	a0,s2
    800036dc:	00001097          	auipc	ra,0x1
    800036e0:	bf2080e7          	jalr	-1038(ra) # 800042ce <log_write>
  brelse(bp);
    800036e4:	854a                	mv	a0,s2
    800036e6:	00000097          	auipc	ra,0x0
    800036ea:	980080e7          	jalr	-1664(ra) # 80003066 <brelse>
}
    800036ee:	60e2                	ld	ra,24(sp)
    800036f0:	6442                	ld	s0,16(sp)
    800036f2:	64a2                	ld	s1,8(sp)
    800036f4:	6902                	ld	s2,0(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret

00000000800036fa <idup>:
{
    800036fa:	1101                	addi	sp,sp,-32
    800036fc:	ec06                	sd	ra,24(sp)
    800036fe:	e822                	sd	s0,16(sp)
    80003700:	e426                	sd	s1,8(sp)
    80003702:	1000                	addi	s0,sp,32
    80003704:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003706:	0001c517          	auipc	a0,0x1c
    8000370a:	75a50513          	addi	a0,a0,1882 # 8001fe60 <icache>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	502080e7          	jalr	1282(ra) # 80000c10 <acquire>
  ip->ref++;
    80003716:	449c                	lw	a5,8(s1)
    80003718:	2785                	addiw	a5,a5,1
    8000371a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000371c:	0001c517          	auipc	a0,0x1c
    80003720:	74450513          	addi	a0,a0,1860 # 8001fe60 <icache>
    80003724:	ffffd097          	auipc	ra,0xffffd
    80003728:	5a0080e7          	jalr	1440(ra) # 80000cc4 <release>
}
    8000372c:	8526                	mv	a0,s1
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6105                	addi	sp,sp,32
    80003736:	8082                	ret

0000000080003738 <ilock>:
{
    80003738:	1101                	addi	sp,sp,-32
    8000373a:	ec06                	sd	ra,24(sp)
    8000373c:	e822                	sd	s0,16(sp)
    8000373e:	e426                	sd	s1,8(sp)
    80003740:	e04a                	sd	s2,0(sp)
    80003742:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003744:	c115                	beqz	a0,80003768 <ilock+0x30>
    80003746:	84aa                	mv	s1,a0
    80003748:	451c                	lw	a5,8(a0)
    8000374a:	00f05f63          	blez	a5,80003768 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000374e:	0541                	addi	a0,a0,16
    80003750:	00001097          	auipc	ra,0x1
    80003754:	ca6080e7          	jalr	-858(ra) # 800043f6 <acquiresleep>
  if(ip->valid == 0){
    80003758:	40bc                	lw	a5,64(s1)
    8000375a:	cf99                	beqz	a5,80003778 <ilock+0x40>
}
    8000375c:	60e2                	ld	ra,24(sp)
    8000375e:	6442                	ld	s0,16(sp)
    80003760:	64a2                	ld	s1,8(sp)
    80003762:	6902                	ld	s2,0(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret
    panic("ilock");
    80003768:	00005517          	auipc	a0,0x5
    8000376c:	e1850513          	addi	a0,a0,-488 # 80008580 <syscalls+0x180>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	dd8080e7          	jalr	-552(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003778:	40dc                	lw	a5,4(s1)
    8000377a:	0047d79b          	srliw	a5,a5,0x4
    8000377e:	0001c597          	auipc	a1,0x1c
    80003782:	6da5a583          	lw	a1,1754(a1) # 8001fe58 <sb+0x18>
    80003786:	9dbd                	addw	a1,a1,a5
    80003788:	4088                	lw	a0,0(s1)
    8000378a:	fffff097          	auipc	ra,0xfffff
    8000378e:	7ac080e7          	jalr	1964(ra) # 80002f36 <bread>
    80003792:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003794:	05850593          	addi	a1,a0,88
    80003798:	40dc                	lw	a5,4(s1)
    8000379a:	8bbd                	andi	a5,a5,15
    8000379c:	079a                	slli	a5,a5,0x6
    8000379e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a0:	00059783          	lh	a5,0(a1)
    800037a4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037a8:	00259783          	lh	a5,2(a1)
    800037ac:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b0:	00459783          	lh	a5,4(a1)
    800037b4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037b8:	00659783          	lh	a5,6(a1)
    800037bc:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c0:	459c                	lw	a5,8(a1)
    800037c2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037c4:	03400613          	li	a2,52
    800037c8:	05b1                	addi	a1,a1,12
    800037ca:	05048513          	addi	a0,s1,80
    800037ce:	ffffd097          	auipc	ra,0xffffd
    800037d2:	59e080e7          	jalr	1438(ra) # 80000d6c <memmove>
    brelse(bp);
    800037d6:	854a                	mv	a0,s2
    800037d8:	00000097          	auipc	ra,0x0
    800037dc:	88e080e7          	jalr	-1906(ra) # 80003066 <brelse>
    ip->valid = 1;
    800037e0:	4785                	li	a5,1
    800037e2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037e4:	04449783          	lh	a5,68(s1)
    800037e8:	fbb5                	bnez	a5,8000375c <ilock+0x24>
      panic("ilock: no type");
    800037ea:	00005517          	auipc	a0,0x5
    800037ee:	d9e50513          	addi	a0,a0,-610 # 80008588 <syscalls+0x188>
    800037f2:	ffffd097          	auipc	ra,0xffffd
    800037f6:	d56080e7          	jalr	-682(ra) # 80000548 <panic>

00000000800037fa <iunlock>:
{
    800037fa:	1101                	addi	sp,sp,-32
    800037fc:	ec06                	sd	ra,24(sp)
    800037fe:	e822                	sd	s0,16(sp)
    80003800:	e426                	sd	s1,8(sp)
    80003802:	e04a                	sd	s2,0(sp)
    80003804:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003806:	c905                	beqz	a0,80003836 <iunlock+0x3c>
    80003808:	84aa                	mv	s1,a0
    8000380a:	01050913          	addi	s2,a0,16
    8000380e:	854a                	mv	a0,s2
    80003810:	00001097          	auipc	ra,0x1
    80003814:	c80080e7          	jalr	-896(ra) # 80004490 <holdingsleep>
    80003818:	cd19                	beqz	a0,80003836 <iunlock+0x3c>
    8000381a:	449c                	lw	a5,8(s1)
    8000381c:	00f05d63          	blez	a5,80003836 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	c2a080e7          	jalr	-982(ra) # 8000444c <releasesleep>
}
    8000382a:	60e2                	ld	ra,24(sp)
    8000382c:	6442                	ld	s0,16(sp)
    8000382e:	64a2                	ld	s1,8(sp)
    80003830:	6902                	ld	s2,0(sp)
    80003832:	6105                	addi	sp,sp,32
    80003834:	8082                	ret
    panic("iunlock");
    80003836:	00005517          	auipc	a0,0x5
    8000383a:	d6250513          	addi	a0,a0,-670 # 80008598 <syscalls+0x198>
    8000383e:	ffffd097          	auipc	ra,0xffffd
    80003842:	d0a080e7          	jalr	-758(ra) # 80000548 <panic>

0000000080003846 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003846:	7179                	addi	sp,sp,-48
    80003848:	f406                	sd	ra,40(sp)
    8000384a:	f022                	sd	s0,32(sp)
    8000384c:	ec26                	sd	s1,24(sp)
    8000384e:	e84a                	sd	s2,16(sp)
    80003850:	e44e                	sd	s3,8(sp)
    80003852:	e052                	sd	s4,0(sp)
    80003854:	1800                	addi	s0,sp,48
    80003856:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003858:	05050493          	addi	s1,a0,80
    8000385c:	08050913          	addi	s2,a0,128
    80003860:	a021                	j	80003868 <itrunc+0x22>
    80003862:	0491                	addi	s1,s1,4
    80003864:	01248d63          	beq	s1,s2,8000387e <itrunc+0x38>
    if(ip->addrs[i]){
    80003868:	408c                	lw	a1,0(s1)
    8000386a:	dde5                	beqz	a1,80003862 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000386c:	0009a503          	lw	a0,0(s3)
    80003870:	00000097          	auipc	ra,0x0
    80003874:	90c080e7          	jalr	-1780(ra) # 8000317c <bfree>
      ip->addrs[i] = 0;
    80003878:	0004a023          	sw	zero,0(s1)
    8000387c:	b7dd                	j	80003862 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000387e:	0809a583          	lw	a1,128(s3)
    80003882:	e185                	bnez	a1,800038a2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003884:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003888:	854e                	mv	a0,s3
    8000388a:	00000097          	auipc	ra,0x0
    8000388e:	de4080e7          	jalr	-540(ra) # 8000366e <iupdate>
}
    80003892:	70a2                	ld	ra,40(sp)
    80003894:	7402                	ld	s0,32(sp)
    80003896:	64e2                	ld	s1,24(sp)
    80003898:	6942                	ld	s2,16(sp)
    8000389a:	69a2                	ld	s3,8(sp)
    8000389c:	6a02                	ld	s4,0(sp)
    8000389e:	6145                	addi	sp,sp,48
    800038a0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a2:	0009a503          	lw	a0,0(s3)
    800038a6:	fffff097          	auipc	ra,0xfffff
    800038aa:	690080e7          	jalr	1680(ra) # 80002f36 <bread>
    800038ae:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b0:	05850493          	addi	s1,a0,88
    800038b4:	45850913          	addi	s2,a0,1112
    800038b8:	a811                	j	800038cc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038ba:	0009a503          	lw	a0,0(s3)
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	8be080e7          	jalr	-1858(ra) # 8000317c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038c6:	0491                	addi	s1,s1,4
    800038c8:	01248563          	beq	s1,s2,800038d2 <itrunc+0x8c>
      if(a[j])
    800038cc:	408c                	lw	a1,0(s1)
    800038ce:	dde5                	beqz	a1,800038c6 <itrunc+0x80>
    800038d0:	b7ed                	j	800038ba <itrunc+0x74>
    brelse(bp);
    800038d2:	8552                	mv	a0,s4
    800038d4:	fffff097          	auipc	ra,0xfffff
    800038d8:	792080e7          	jalr	1938(ra) # 80003066 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038dc:	0809a583          	lw	a1,128(s3)
    800038e0:	0009a503          	lw	a0,0(s3)
    800038e4:	00000097          	auipc	ra,0x0
    800038e8:	898080e7          	jalr	-1896(ra) # 8000317c <bfree>
    ip->addrs[NDIRECT] = 0;
    800038ec:	0809a023          	sw	zero,128(s3)
    800038f0:	bf51                	j	80003884 <itrunc+0x3e>

00000000800038f2 <iput>:
{
    800038f2:	1101                	addi	sp,sp,-32
    800038f4:	ec06                	sd	ra,24(sp)
    800038f6:	e822                	sd	s0,16(sp)
    800038f8:	e426                	sd	s1,8(sp)
    800038fa:	e04a                	sd	s2,0(sp)
    800038fc:	1000                	addi	s0,sp,32
    800038fe:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003900:	0001c517          	auipc	a0,0x1c
    80003904:	56050513          	addi	a0,a0,1376 # 8001fe60 <icache>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	308080e7          	jalr	776(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003910:	4498                	lw	a4,8(s1)
    80003912:	4785                	li	a5,1
    80003914:	02f70363          	beq	a4,a5,8000393a <iput+0x48>
  ip->ref--;
    80003918:	449c                	lw	a5,8(s1)
    8000391a:	37fd                	addiw	a5,a5,-1
    8000391c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000391e:	0001c517          	auipc	a0,0x1c
    80003922:	54250513          	addi	a0,a0,1346 # 8001fe60 <icache>
    80003926:	ffffd097          	auipc	ra,0xffffd
    8000392a:	39e080e7          	jalr	926(ra) # 80000cc4 <release>
}
    8000392e:	60e2                	ld	ra,24(sp)
    80003930:	6442                	ld	s0,16(sp)
    80003932:	64a2                	ld	s1,8(sp)
    80003934:	6902                	ld	s2,0(sp)
    80003936:	6105                	addi	sp,sp,32
    80003938:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000393a:	40bc                	lw	a5,64(s1)
    8000393c:	dff1                	beqz	a5,80003918 <iput+0x26>
    8000393e:	04a49783          	lh	a5,74(s1)
    80003942:	fbf9                	bnez	a5,80003918 <iput+0x26>
    acquiresleep(&ip->lock);
    80003944:	01048913          	addi	s2,s1,16
    80003948:	854a                	mv	a0,s2
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	aac080e7          	jalr	-1364(ra) # 800043f6 <acquiresleep>
    release(&icache.lock);
    80003952:	0001c517          	auipc	a0,0x1c
    80003956:	50e50513          	addi	a0,a0,1294 # 8001fe60 <icache>
    8000395a:	ffffd097          	auipc	ra,0xffffd
    8000395e:	36a080e7          	jalr	874(ra) # 80000cc4 <release>
    itrunc(ip);
    80003962:	8526                	mv	a0,s1
    80003964:	00000097          	auipc	ra,0x0
    80003968:	ee2080e7          	jalr	-286(ra) # 80003846 <itrunc>
    ip->type = 0;
    8000396c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003970:	8526                	mv	a0,s1
    80003972:	00000097          	auipc	ra,0x0
    80003976:	cfc080e7          	jalr	-772(ra) # 8000366e <iupdate>
    ip->valid = 0;
    8000397a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000397e:	854a                	mv	a0,s2
    80003980:	00001097          	auipc	ra,0x1
    80003984:	acc080e7          	jalr	-1332(ra) # 8000444c <releasesleep>
    acquire(&icache.lock);
    80003988:	0001c517          	auipc	a0,0x1c
    8000398c:	4d850513          	addi	a0,a0,1240 # 8001fe60 <icache>
    80003990:	ffffd097          	auipc	ra,0xffffd
    80003994:	280080e7          	jalr	640(ra) # 80000c10 <acquire>
    80003998:	b741                	j	80003918 <iput+0x26>

000000008000399a <iunlockput>:
{
    8000399a:	1101                	addi	sp,sp,-32
    8000399c:	ec06                	sd	ra,24(sp)
    8000399e:	e822                	sd	s0,16(sp)
    800039a0:	e426                	sd	s1,8(sp)
    800039a2:	1000                	addi	s0,sp,32
    800039a4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039a6:	00000097          	auipc	ra,0x0
    800039aa:	e54080e7          	jalr	-428(ra) # 800037fa <iunlock>
  iput(ip);
    800039ae:	8526                	mv	a0,s1
    800039b0:	00000097          	auipc	ra,0x0
    800039b4:	f42080e7          	jalr	-190(ra) # 800038f2 <iput>
}
    800039b8:	60e2                	ld	ra,24(sp)
    800039ba:	6442                	ld	s0,16(sp)
    800039bc:	64a2                	ld	s1,8(sp)
    800039be:	6105                	addi	sp,sp,32
    800039c0:	8082                	ret

00000000800039c2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c2:	1141                	addi	sp,sp,-16
    800039c4:	e422                	sd	s0,8(sp)
    800039c6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039c8:	411c                	lw	a5,0(a0)
    800039ca:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039cc:	415c                	lw	a5,4(a0)
    800039ce:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d0:	04451783          	lh	a5,68(a0)
    800039d4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039d8:	04a51783          	lh	a5,74(a0)
    800039dc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e0:	04c56783          	lwu	a5,76(a0)
    800039e4:	e99c                	sd	a5,16(a1)
}
    800039e6:	6422                	ld	s0,8(sp)
    800039e8:	0141                	addi	sp,sp,16
    800039ea:	8082                	ret

00000000800039ec <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039ec:	457c                	lw	a5,76(a0)
    800039ee:	0ed7e963          	bltu	a5,a3,80003ae0 <readi+0xf4>
{
    800039f2:	7159                	addi	sp,sp,-112
    800039f4:	f486                	sd	ra,104(sp)
    800039f6:	f0a2                	sd	s0,96(sp)
    800039f8:	eca6                	sd	s1,88(sp)
    800039fa:	e8ca                	sd	s2,80(sp)
    800039fc:	e4ce                	sd	s3,72(sp)
    800039fe:	e0d2                	sd	s4,64(sp)
    80003a00:	fc56                	sd	s5,56(sp)
    80003a02:	f85a                	sd	s6,48(sp)
    80003a04:	f45e                	sd	s7,40(sp)
    80003a06:	f062                	sd	s8,32(sp)
    80003a08:	ec66                	sd	s9,24(sp)
    80003a0a:	e86a                	sd	s10,16(sp)
    80003a0c:	e46e                	sd	s11,8(sp)
    80003a0e:	1880                	addi	s0,sp,112
    80003a10:	8baa                	mv	s7,a0
    80003a12:	8c2e                	mv	s8,a1
    80003a14:	8ab2                	mv	s5,a2
    80003a16:	84b6                	mv	s1,a3
    80003a18:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a1a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a1c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a1e:	0ad76063          	bltu	a4,a3,80003abe <readi+0xd2>
  if(off + n > ip->size)
    80003a22:	00e7f463          	bgeu	a5,a4,80003a2a <readi+0x3e>
    n = ip->size - off;
    80003a26:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a2a:	0a0b0963          	beqz	s6,80003adc <readi+0xf0>
    80003a2e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a30:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a34:	5cfd                	li	s9,-1
    80003a36:	a82d                	j	80003a70 <readi+0x84>
    80003a38:	020a1d93          	slli	s11,s4,0x20
    80003a3c:	020ddd93          	srli	s11,s11,0x20
    80003a40:	05890613          	addi	a2,s2,88
    80003a44:	86ee                	mv	a3,s11
    80003a46:	963a                	add	a2,a2,a4
    80003a48:	85d6                	mv	a1,s5
    80003a4a:	8562                	mv	a0,s8
    80003a4c:	fffff097          	auipc	ra,0xfffff
    80003a50:	ae4080e7          	jalr	-1308(ra) # 80002530 <either_copyout>
    80003a54:	05950d63          	beq	a0,s9,80003aae <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a58:	854a                	mv	a0,s2
    80003a5a:	fffff097          	auipc	ra,0xfffff
    80003a5e:	60c080e7          	jalr	1548(ra) # 80003066 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a62:	013a09bb          	addw	s3,s4,s3
    80003a66:	009a04bb          	addw	s1,s4,s1
    80003a6a:	9aee                	add	s5,s5,s11
    80003a6c:	0569f763          	bgeu	s3,s6,80003aba <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a70:	000ba903          	lw	s2,0(s7)
    80003a74:	00a4d59b          	srliw	a1,s1,0xa
    80003a78:	855e                	mv	a0,s7
    80003a7a:	00000097          	auipc	ra,0x0
    80003a7e:	8b0080e7          	jalr	-1872(ra) # 8000332a <bmap>
    80003a82:	0005059b          	sext.w	a1,a0
    80003a86:	854a                	mv	a0,s2
    80003a88:	fffff097          	auipc	ra,0xfffff
    80003a8c:	4ae080e7          	jalr	1198(ra) # 80002f36 <bread>
    80003a90:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a92:	3ff4f713          	andi	a4,s1,1023
    80003a96:	40ed07bb          	subw	a5,s10,a4
    80003a9a:	413b06bb          	subw	a3,s6,s3
    80003a9e:	8a3e                	mv	s4,a5
    80003aa0:	2781                	sext.w	a5,a5
    80003aa2:	0006861b          	sext.w	a2,a3
    80003aa6:	f8f679e3          	bgeu	a2,a5,80003a38 <readi+0x4c>
    80003aaa:	8a36                	mv	s4,a3
    80003aac:	b771                	j	80003a38 <readi+0x4c>
      brelse(bp);
    80003aae:	854a                	mv	a0,s2
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	5b6080e7          	jalr	1462(ra) # 80003066 <brelse>
      tot = -1;
    80003ab8:	59fd                	li	s3,-1
  }
  return tot;
    80003aba:	0009851b          	sext.w	a0,s3
}
    80003abe:	70a6                	ld	ra,104(sp)
    80003ac0:	7406                	ld	s0,96(sp)
    80003ac2:	64e6                	ld	s1,88(sp)
    80003ac4:	6946                	ld	s2,80(sp)
    80003ac6:	69a6                	ld	s3,72(sp)
    80003ac8:	6a06                	ld	s4,64(sp)
    80003aca:	7ae2                	ld	s5,56(sp)
    80003acc:	7b42                	ld	s6,48(sp)
    80003ace:	7ba2                	ld	s7,40(sp)
    80003ad0:	7c02                	ld	s8,32(sp)
    80003ad2:	6ce2                	ld	s9,24(sp)
    80003ad4:	6d42                	ld	s10,16(sp)
    80003ad6:	6da2                	ld	s11,8(sp)
    80003ad8:	6165                	addi	sp,sp,112
    80003ada:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003adc:	89da                	mv	s3,s6
    80003ade:	bff1                	j	80003aba <readi+0xce>
    return 0;
    80003ae0:	4501                	li	a0,0
}
    80003ae2:	8082                	ret

0000000080003ae4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae4:	457c                	lw	a5,76(a0)
    80003ae6:	10d7e763          	bltu	a5,a3,80003bf4 <writei+0x110>
{
    80003aea:	7159                	addi	sp,sp,-112
    80003aec:	f486                	sd	ra,104(sp)
    80003aee:	f0a2                	sd	s0,96(sp)
    80003af0:	eca6                	sd	s1,88(sp)
    80003af2:	e8ca                	sd	s2,80(sp)
    80003af4:	e4ce                	sd	s3,72(sp)
    80003af6:	e0d2                	sd	s4,64(sp)
    80003af8:	fc56                	sd	s5,56(sp)
    80003afa:	f85a                	sd	s6,48(sp)
    80003afc:	f45e                	sd	s7,40(sp)
    80003afe:	f062                	sd	s8,32(sp)
    80003b00:	ec66                	sd	s9,24(sp)
    80003b02:	e86a                	sd	s10,16(sp)
    80003b04:	e46e                	sd	s11,8(sp)
    80003b06:	1880                	addi	s0,sp,112
    80003b08:	8baa                	mv	s7,a0
    80003b0a:	8c2e                	mv	s8,a1
    80003b0c:	8ab2                	mv	s5,a2
    80003b0e:	8936                	mv	s2,a3
    80003b10:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b12:	00e687bb          	addw	a5,a3,a4
    80003b16:	0ed7e163          	bltu	a5,a3,80003bf8 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1a:	00043737          	lui	a4,0x43
    80003b1e:	0cf76f63          	bltu	a4,a5,80003bfc <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b22:	0a0b0863          	beqz	s6,80003bd2 <writei+0xee>
    80003b26:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b28:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b2c:	5cfd                	li	s9,-1
    80003b2e:	a091                	j	80003b72 <writei+0x8e>
    80003b30:	02099d93          	slli	s11,s3,0x20
    80003b34:	020ddd93          	srli	s11,s11,0x20
    80003b38:	05848513          	addi	a0,s1,88
    80003b3c:	86ee                	mv	a3,s11
    80003b3e:	8656                	mv	a2,s5
    80003b40:	85e2                	mv	a1,s8
    80003b42:	953a                	add	a0,a0,a4
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	a42080e7          	jalr	-1470(ra) # 80002586 <either_copyin>
    80003b4c:	07950263          	beq	a0,s9,80003bb0 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003b50:	8526                	mv	a0,s1
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	77c080e7          	jalr	1916(ra) # 800042ce <log_write>
    brelse(bp);
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	fffff097          	auipc	ra,0xfffff
    80003b60:	50a080e7          	jalr	1290(ra) # 80003066 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b64:	01498a3b          	addw	s4,s3,s4
    80003b68:	0129893b          	addw	s2,s3,s2
    80003b6c:	9aee                	add	s5,s5,s11
    80003b6e:	056a7763          	bgeu	s4,s6,80003bbc <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b72:	000ba483          	lw	s1,0(s7)
    80003b76:	00a9559b          	srliw	a1,s2,0xa
    80003b7a:	855e                	mv	a0,s7
    80003b7c:	fffff097          	auipc	ra,0xfffff
    80003b80:	7ae080e7          	jalr	1966(ra) # 8000332a <bmap>
    80003b84:	0005059b          	sext.w	a1,a0
    80003b88:	8526                	mv	a0,s1
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	3ac080e7          	jalr	940(ra) # 80002f36 <bread>
    80003b92:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b94:	3ff97713          	andi	a4,s2,1023
    80003b98:	40ed07bb          	subw	a5,s10,a4
    80003b9c:	414b06bb          	subw	a3,s6,s4
    80003ba0:	89be                	mv	s3,a5
    80003ba2:	2781                	sext.w	a5,a5
    80003ba4:	0006861b          	sext.w	a2,a3
    80003ba8:	f8f674e3          	bgeu	a2,a5,80003b30 <writei+0x4c>
    80003bac:	89b6                	mv	s3,a3
    80003bae:	b749                	j	80003b30 <writei+0x4c>
      brelse(bp);
    80003bb0:	8526                	mv	a0,s1
    80003bb2:	fffff097          	auipc	ra,0xfffff
    80003bb6:	4b4080e7          	jalr	1204(ra) # 80003066 <brelse>
      n = -1;
    80003bba:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003bbc:	04cba783          	lw	a5,76(s7)
    80003bc0:	0127f463          	bgeu	a5,s2,80003bc8 <writei+0xe4>
      ip->size = off;
    80003bc4:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bc8:	855e                	mv	a0,s7
    80003bca:	00000097          	auipc	ra,0x0
    80003bce:	aa4080e7          	jalr	-1372(ra) # 8000366e <iupdate>
  }

  return n;
    80003bd2:	000b051b          	sext.w	a0,s6
}
    80003bd6:	70a6                	ld	ra,104(sp)
    80003bd8:	7406                	ld	s0,96(sp)
    80003bda:	64e6                	ld	s1,88(sp)
    80003bdc:	6946                	ld	s2,80(sp)
    80003bde:	69a6                	ld	s3,72(sp)
    80003be0:	6a06                	ld	s4,64(sp)
    80003be2:	7ae2                	ld	s5,56(sp)
    80003be4:	7b42                	ld	s6,48(sp)
    80003be6:	7ba2                	ld	s7,40(sp)
    80003be8:	7c02                	ld	s8,32(sp)
    80003bea:	6ce2                	ld	s9,24(sp)
    80003bec:	6d42                	ld	s10,16(sp)
    80003bee:	6da2                	ld	s11,8(sp)
    80003bf0:	6165                	addi	sp,sp,112
    80003bf2:	8082                	ret
    return -1;
    80003bf4:	557d                	li	a0,-1
}
    80003bf6:	8082                	ret
    return -1;
    80003bf8:	557d                	li	a0,-1
    80003bfa:	bff1                	j	80003bd6 <writei+0xf2>
    return -1;
    80003bfc:	557d                	li	a0,-1
    80003bfe:	bfe1                	j	80003bd6 <writei+0xf2>

0000000080003c00 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c00:	1141                	addi	sp,sp,-16
    80003c02:	e406                	sd	ra,8(sp)
    80003c04:	e022                	sd	s0,0(sp)
    80003c06:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c08:	4639                	li	a2,14
    80003c0a:	ffffd097          	auipc	ra,0xffffd
    80003c0e:	1de080e7          	jalr	478(ra) # 80000de8 <strncmp>
}
    80003c12:	60a2                	ld	ra,8(sp)
    80003c14:	6402                	ld	s0,0(sp)
    80003c16:	0141                	addi	sp,sp,16
    80003c18:	8082                	ret

0000000080003c1a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c1a:	7139                	addi	sp,sp,-64
    80003c1c:	fc06                	sd	ra,56(sp)
    80003c1e:	f822                	sd	s0,48(sp)
    80003c20:	f426                	sd	s1,40(sp)
    80003c22:	f04a                	sd	s2,32(sp)
    80003c24:	ec4e                	sd	s3,24(sp)
    80003c26:	e852                	sd	s4,16(sp)
    80003c28:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c2a:	04451703          	lh	a4,68(a0)
    80003c2e:	4785                	li	a5,1
    80003c30:	00f71a63          	bne	a4,a5,80003c44 <dirlookup+0x2a>
    80003c34:	892a                	mv	s2,a0
    80003c36:	89ae                	mv	s3,a1
    80003c38:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3a:	457c                	lw	a5,76(a0)
    80003c3c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c3e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c40:	e79d                	bnez	a5,80003c6e <dirlookup+0x54>
    80003c42:	a8a5                	j	80003cba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c44:	00005517          	auipc	a0,0x5
    80003c48:	95c50513          	addi	a0,a0,-1700 # 800085a0 <syscalls+0x1a0>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	8fc080e7          	jalr	-1796(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c54:	00005517          	auipc	a0,0x5
    80003c58:	96450513          	addi	a0,a0,-1692 # 800085b8 <syscalls+0x1b8>
    80003c5c:	ffffd097          	auipc	ra,0xffffd
    80003c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c64:	24c1                	addiw	s1,s1,16
    80003c66:	04c92783          	lw	a5,76(s2)
    80003c6a:	04f4f763          	bgeu	s1,a5,80003cb8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c6e:	4741                	li	a4,16
    80003c70:	86a6                	mv	a3,s1
    80003c72:	fc040613          	addi	a2,s0,-64
    80003c76:	4581                	li	a1,0
    80003c78:	854a                	mv	a0,s2
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	d72080e7          	jalr	-654(ra) # 800039ec <readi>
    80003c82:	47c1                	li	a5,16
    80003c84:	fcf518e3          	bne	a0,a5,80003c54 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c88:	fc045783          	lhu	a5,-64(s0)
    80003c8c:	dfe1                	beqz	a5,80003c64 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c8e:	fc240593          	addi	a1,s0,-62
    80003c92:	854e                	mv	a0,s3
    80003c94:	00000097          	auipc	ra,0x0
    80003c98:	f6c080e7          	jalr	-148(ra) # 80003c00 <namecmp>
    80003c9c:	f561                	bnez	a0,80003c64 <dirlookup+0x4a>
      if(poff)
    80003c9e:	000a0463          	beqz	s4,80003ca6 <dirlookup+0x8c>
        *poff = off;
    80003ca2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ca6:	fc045583          	lhu	a1,-64(s0)
    80003caa:	00092503          	lw	a0,0(s2)
    80003cae:	fffff097          	auipc	ra,0xfffff
    80003cb2:	756080e7          	jalr	1878(ra) # 80003404 <iget>
    80003cb6:	a011                	j	80003cba <dirlookup+0xa0>
  return 0;
    80003cb8:	4501                	li	a0,0
}
    80003cba:	70e2                	ld	ra,56(sp)
    80003cbc:	7442                	ld	s0,48(sp)
    80003cbe:	74a2                	ld	s1,40(sp)
    80003cc0:	7902                	ld	s2,32(sp)
    80003cc2:	69e2                	ld	s3,24(sp)
    80003cc4:	6a42                	ld	s4,16(sp)
    80003cc6:	6121                	addi	sp,sp,64
    80003cc8:	8082                	ret

0000000080003cca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cca:	711d                	addi	sp,sp,-96
    80003ccc:	ec86                	sd	ra,88(sp)
    80003cce:	e8a2                	sd	s0,80(sp)
    80003cd0:	e4a6                	sd	s1,72(sp)
    80003cd2:	e0ca                	sd	s2,64(sp)
    80003cd4:	fc4e                	sd	s3,56(sp)
    80003cd6:	f852                	sd	s4,48(sp)
    80003cd8:	f456                	sd	s5,40(sp)
    80003cda:	f05a                	sd	s6,32(sp)
    80003cdc:	ec5e                	sd	s7,24(sp)
    80003cde:	e862                	sd	s8,16(sp)
    80003ce0:	e466                	sd	s9,8(sp)
    80003ce2:	1080                	addi	s0,sp,96
    80003ce4:	84aa                	mv	s1,a0
    80003ce6:	8b2e                	mv	s6,a1
    80003ce8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cea:	00054703          	lbu	a4,0(a0)
    80003cee:	02f00793          	li	a5,47
    80003cf2:	02f70363          	beq	a4,a5,80003d18 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cf6:	ffffe097          	auipc	ra,0xffffe
    80003cfa:	dc8080e7          	jalr	-568(ra) # 80001abe <myproc>
    80003cfe:	15053503          	ld	a0,336(a0)
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	9f8080e7          	jalr	-1544(ra) # 800036fa <idup>
    80003d0a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d0c:	02f00913          	li	s2,47
  len = path - s;
    80003d10:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d12:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d14:	4c05                	li	s8,1
    80003d16:	a865                	j	80003dce <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d18:	4585                	li	a1,1
    80003d1a:	4505                	li	a0,1
    80003d1c:	fffff097          	auipc	ra,0xfffff
    80003d20:	6e8080e7          	jalr	1768(ra) # 80003404 <iget>
    80003d24:	89aa                	mv	s3,a0
    80003d26:	b7dd                	j	80003d0c <namex+0x42>
      iunlockput(ip);
    80003d28:	854e                	mv	a0,s3
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	c70080e7          	jalr	-912(ra) # 8000399a <iunlockput>
      return 0;
    80003d32:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d34:	854e                	mv	a0,s3
    80003d36:	60e6                	ld	ra,88(sp)
    80003d38:	6446                	ld	s0,80(sp)
    80003d3a:	64a6                	ld	s1,72(sp)
    80003d3c:	6906                	ld	s2,64(sp)
    80003d3e:	79e2                	ld	s3,56(sp)
    80003d40:	7a42                	ld	s4,48(sp)
    80003d42:	7aa2                	ld	s5,40(sp)
    80003d44:	7b02                	ld	s6,32(sp)
    80003d46:	6be2                	ld	s7,24(sp)
    80003d48:	6c42                	ld	s8,16(sp)
    80003d4a:	6ca2                	ld	s9,8(sp)
    80003d4c:	6125                	addi	sp,sp,96
    80003d4e:	8082                	ret
      iunlock(ip);
    80003d50:	854e                	mv	a0,s3
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	aa8080e7          	jalr	-1368(ra) # 800037fa <iunlock>
      return ip;
    80003d5a:	bfe9                	j	80003d34 <namex+0x6a>
      iunlockput(ip);
    80003d5c:	854e                	mv	a0,s3
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	c3c080e7          	jalr	-964(ra) # 8000399a <iunlockput>
      return 0;
    80003d66:	89d2                	mv	s3,s4
    80003d68:	b7f1                	j	80003d34 <namex+0x6a>
  len = path - s;
    80003d6a:	40b48633          	sub	a2,s1,a1
    80003d6e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d72:	094cd463          	bge	s9,s4,80003dfa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d76:	4639                	li	a2,14
    80003d78:	8556                	mv	a0,s5
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	ff2080e7          	jalr	-14(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003d82:	0004c783          	lbu	a5,0(s1)
    80003d86:	01279763          	bne	a5,s2,80003d94 <namex+0xca>
    path++;
    80003d8a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d8c:	0004c783          	lbu	a5,0(s1)
    80003d90:	ff278de3          	beq	a5,s2,80003d8a <namex+0xc0>
    ilock(ip);
    80003d94:	854e                	mv	a0,s3
    80003d96:	00000097          	auipc	ra,0x0
    80003d9a:	9a2080e7          	jalr	-1630(ra) # 80003738 <ilock>
    if(ip->type != T_DIR){
    80003d9e:	04499783          	lh	a5,68(s3)
    80003da2:	f98793e3          	bne	a5,s8,80003d28 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003da6:	000b0563          	beqz	s6,80003db0 <namex+0xe6>
    80003daa:	0004c783          	lbu	a5,0(s1)
    80003dae:	d3cd                	beqz	a5,80003d50 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003db0:	865e                	mv	a2,s7
    80003db2:	85d6                	mv	a1,s5
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	e64080e7          	jalr	-412(ra) # 80003c1a <dirlookup>
    80003dbe:	8a2a                	mv	s4,a0
    80003dc0:	dd51                	beqz	a0,80003d5c <namex+0x92>
    iunlockput(ip);
    80003dc2:	854e                	mv	a0,s3
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	bd6080e7          	jalr	-1066(ra) # 8000399a <iunlockput>
    ip = next;
    80003dcc:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dce:	0004c783          	lbu	a5,0(s1)
    80003dd2:	05279763          	bne	a5,s2,80003e20 <namex+0x156>
    path++;
    80003dd6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dd8:	0004c783          	lbu	a5,0(s1)
    80003ddc:	ff278de3          	beq	a5,s2,80003dd6 <namex+0x10c>
  if(*path == 0)
    80003de0:	c79d                	beqz	a5,80003e0e <namex+0x144>
    path++;
    80003de2:	85a6                	mv	a1,s1
  len = path - s;
    80003de4:	8a5e                	mv	s4,s7
    80003de6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003de8:	01278963          	beq	a5,s2,80003dfa <namex+0x130>
    80003dec:	dfbd                	beqz	a5,80003d6a <namex+0xa0>
    path++;
    80003dee:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	ff279ce3          	bne	a5,s2,80003dec <namex+0x122>
    80003df8:	bf8d                	j	80003d6a <namex+0xa0>
    memmove(name, s, len);
    80003dfa:	2601                	sext.w	a2,a2
    80003dfc:	8556                	mv	a0,s5
    80003dfe:	ffffd097          	auipc	ra,0xffffd
    80003e02:	f6e080e7          	jalr	-146(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003e06:	9a56                	add	s4,s4,s5
    80003e08:	000a0023          	sb	zero,0(s4)
    80003e0c:	bf9d                	j	80003d82 <namex+0xb8>
  if(nameiparent){
    80003e0e:	f20b03e3          	beqz	s6,80003d34 <namex+0x6a>
    iput(ip);
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	ade080e7          	jalr	-1314(ra) # 800038f2 <iput>
    return 0;
    80003e1c:	4981                	li	s3,0
    80003e1e:	bf19                	j	80003d34 <namex+0x6a>
  if(*path == 0)
    80003e20:	d7fd                	beqz	a5,80003e0e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e22:	0004c783          	lbu	a5,0(s1)
    80003e26:	85a6                	mv	a1,s1
    80003e28:	b7d1                	j	80003dec <namex+0x122>

0000000080003e2a <dirlink>:
{
    80003e2a:	7139                	addi	sp,sp,-64
    80003e2c:	fc06                	sd	ra,56(sp)
    80003e2e:	f822                	sd	s0,48(sp)
    80003e30:	f426                	sd	s1,40(sp)
    80003e32:	f04a                	sd	s2,32(sp)
    80003e34:	ec4e                	sd	s3,24(sp)
    80003e36:	e852                	sd	s4,16(sp)
    80003e38:	0080                	addi	s0,sp,64
    80003e3a:	892a                	mv	s2,a0
    80003e3c:	8a2e                	mv	s4,a1
    80003e3e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e40:	4601                	li	a2,0
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	dd8080e7          	jalr	-552(ra) # 80003c1a <dirlookup>
    80003e4a:	e93d                	bnez	a0,80003ec0 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4c:	04c92483          	lw	s1,76(s2)
    80003e50:	c49d                	beqz	s1,80003e7e <dirlink+0x54>
    80003e52:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e54:	4741                	li	a4,16
    80003e56:	86a6                	mv	a3,s1
    80003e58:	fc040613          	addi	a2,s0,-64
    80003e5c:	4581                	li	a1,0
    80003e5e:	854a                	mv	a0,s2
    80003e60:	00000097          	auipc	ra,0x0
    80003e64:	b8c080e7          	jalr	-1140(ra) # 800039ec <readi>
    80003e68:	47c1                	li	a5,16
    80003e6a:	06f51163          	bne	a0,a5,80003ecc <dirlink+0xa2>
    if(de.inum == 0)
    80003e6e:	fc045783          	lhu	a5,-64(s0)
    80003e72:	c791                	beqz	a5,80003e7e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e74:	24c1                	addiw	s1,s1,16
    80003e76:	04c92783          	lw	a5,76(s2)
    80003e7a:	fcf4ede3          	bltu	s1,a5,80003e54 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e7e:	4639                	li	a2,14
    80003e80:	85d2                	mv	a1,s4
    80003e82:	fc240513          	addi	a0,s0,-62
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	f9e080e7          	jalr	-98(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003e8e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e92:	4741                	li	a4,16
    80003e94:	86a6                	mv	a3,s1
    80003e96:	fc040613          	addi	a2,s0,-64
    80003e9a:	4581                	li	a1,0
    80003e9c:	854a                	mv	a0,s2
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	c46080e7          	jalr	-954(ra) # 80003ae4 <writei>
    80003ea6:	872a                	mv	a4,a0
    80003ea8:	47c1                	li	a5,16
  return 0;
    80003eaa:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eac:	02f71863          	bne	a4,a5,80003edc <dirlink+0xb2>
}
    80003eb0:	70e2                	ld	ra,56(sp)
    80003eb2:	7442                	ld	s0,48(sp)
    80003eb4:	74a2                	ld	s1,40(sp)
    80003eb6:	7902                	ld	s2,32(sp)
    80003eb8:	69e2                	ld	s3,24(sp)
    80003eba:	6a42                	ld	s4,16(sp)
    80003ebc:	6121                	addi	sp,sp,64
    80003ebe:	8082                	ret
    iput(ip);
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	a32080e7          	jalr	-1486(ra) # 800038f2 <iput>
    return -1;
    80003ec8:	557d                	li	a0,-1
    80003eca:	b7dd                	j	80003eb0 <dirlink+0x86>
      panic("dirlink read");
    80003ecc:	00004517          	auipc	a0,0x4
    80003ed0:	6fc50513          	addi	a0,a0,1788 # 800085c8 <syscalls+0x1c8>
    80003ed4:	ffffc097          	auipc	ra,0xffffc
    80003ed8:	674080e7          	jalr	1652(ra) # 80000548 <panic>
    panic("dirlink");
    80003edc:	00005517          	auipc	a0,0x5
    80003ee0:	80c50513          	addi	a0,a0,-2036 # 800086e8 <syscalls+0x2e8>
    80003ee4:	ffffc097          	auipc	ra,0xffffc
    80003ee8:	664080e7          	jalr	1636(ra) # 80000548 <panic>

0000000080003eec <namei>:

struct inode*
namei(char *path)
{
    80003eec:	1101                	addi	sp,sp,-32
    80003eee:	ec06                	sd	ra,24(sp)
    80003ef0:	e822                	sd	s0,16(sp)
    80003ef2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef4:	fe040613          	addi	a2,s0,-32
    80003ef8:	4581                	li	a1,0
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	dd0080e7          	jalr	-560(ra) # 80003cca <namex>
}
    80003f02:	60e2                	ld	ra,24(sp)
    80003f04:	6442                	ld	s0,16(sp)
    80003f06:	6105                	addi	sp,sp,32
    80003f08:	8082                	ret

0000000080003f0a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f0a:	1141                	addi	sp,sp,-16
    80003f0c:	e406                	sd	ra,8(sp)
    80003f0e:	e022                	sd	s0,0(sp)
    80003f10:	0800                	addi	s0,sp,16
    80003f12:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f14:	4585                	li	a1,1
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	db4080e7          	jalr	-588(ra) # 80003cca <namex>
}
    80003f1e:	60a2                	ld	ra,8(sp)
    80003f20:	6402                	ld	s0,0(sp)
    80003f22:	0141                	addi	sp,sp,16
    80003f24:	8082                	ret

0000000080003f26 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f26:	1101                	addi	sp,sp,-32
    80003f28:	ec06                	sd	ra,24(sp)
    80003f2a:	e822                	sd	s0,16(sp)
    80003f2c:	e426                	sd	s1,8(sp)
    80003f2e:	e04a                	sd	s2,0(sp)
    80003f30:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f32:	0001e917          	auipc	s2,0x1e
    80003f36:	9d690913          	addi	s2,s2,-1578 # 80021908 <log>
    80003f3a:	01892583          	lw	a1,24(s2)
    80003f3e:	02892503          	lw	a0,40(s2)
    80003f42:	fffff097          	auipc	ra,0xfffff
    80003f46:	ff4080e7          	jalr	-12(ra) # 80002f36 <bread>
    80003f4a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f4c:	02c92683          	lw	a3,44(s2)
    80003f50:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f52:	02d05763          	blez	a3,80003f80 <write_head+0x5a>
    80003f56:	0001e797          	auipc	a5,0x1e
    80003f5a:	9e278793          	addi	a5,a5,-1566 # 80021938 <log+0x30>
    80003f5e:	05c50713          	addi	a4,a0,92
    80003f62:	36fd                	addiw	a3,a3,-1
    80003f64:	1682                	slli	a3,a3,0x20
    80003f66:	9281                	srli	a3,a3,0x20
    80003f68:	068a                	slli	a3,a3,0x2
    80003f6a:	0001e617          	auipc	a2,0x1e
    80003f6e:	9d260613          	addi	a2,a2,-1582 # 8002193c <log+0x34>
    80003f72:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f74:	4390                	lw	a2,0(a5)
    80003f76:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f78:	0791                	addi	a5,a5,4
    80003f7a:	0711                	addi	a4,a4,4
    80003f7c:	fed79ce3          	bne	a5,a3,80003f74 <write_head+0x4e>
  }
  bwrite(buf);
    80003f80:	8526                	mv	a0,s1
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	0a6080e7          	jalr	166(ra) # 80003028 <bwrite>
  brelse(buf);
    80003f8a:	8526                	mv	a0,s1
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	0da080e7          	jalr	218(ra) # 80003066 <brelse>
}
    80003f94:	60e2                	ld	ra,24(sp)
    80003f96:	6442                	ld	s0,16(sp)
    80003f98:	64a2                	ld	s1,8(sp)
    80003f9a:	6902                	ld	s2,0(sp)
    80003f9c:	6105                	addi	sp,sp,32
    80003f9e:	8082                	ret

0000000080003fa0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa0:	0001e797          	auipc	a5,0x1e
    80003fa4:	9947a783          	lw	a5,-1644(a5) # 80021934 <log+0x2c>
    80003fa8:	0af05663          	blez	a5,80004054 <install_trans+0xb4>
{
    80003fac:	7139                	addi	sp,sp,-64
    80003fae:	fc06                	sd	ra,56(sp)
    80003fb0:	f822                	sd	s0,48(sp)
    80003fb2:	f426                	sd	s1,40(sp)
    80003fb4:	f04a                	sd	s2,32(sp)
    80003fb6:	ec4e                	sd	s3,24(sp)
    80003fb8:	e852                	sd	s4,16(sp)
    80003fba:	e456                	sd	s5,8(sp)
    80003fbc:	0080                	addi	s0,sp,64
    80003fbe:	0001ea97          	auipc	s5,0x1e
    80003fc2:	97aa8a93          	addi	s5,s5,-1670 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fc8:	0001e997          	auipc	s3,0x1e
    80003fcc:	94098993          	addi	s3,s3,-1728 # 80021908 <log>
    80003fd0:	0189a583          	lw	a1,24(s3)
    80003fd4:	014585bb          	addw	a1,a1,s4
    80003fd8:	2585                	addiw	a1,a1,1
    80003fda:	0289a503          	lw	a0,40(s3)
    80003fde:	fffff097          	auipc	ra,0xfffff
    80003fe2:	f58080e7          	jalr	-168(ra) # 80002f36 <bread>
    80003fe6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fe8:	000aa583          	lw	a1,0(s5)
    80003fec:	0289a503          	lw	a0,40(s3)
    80003ff0:	fffff097          	auipc	ra,0xfffff
    80003ff4:	f46080e7          	jalr	-186(ra) # 80002f36 <bread>
    80003ff8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ffa:	40000613          	li	a2,1024
    80003ffe:	05890593          	addi	a1,s2,88
    80004002:	05850513          	addi	a0,a0,88
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	d66080e7          	jalr	-666(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000400e:	8526                	mv	a0,s1
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	018080e7          	jalr	24(ra) # 80003028 <bwrite>
    bunpin(dbuf);
    80004018:	8526                	mv	a0,s1
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	126080e7          	jalr	294(ra) # 80003140 <bunpin>
    brelse(lbuf);
    80004022:	854a                	mv	a0,s2
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	042080e7          	jalr	66(ra) # 80003066 <brelse>
    brelse(dbuf);
    8000402c:	8526                	mv	a0,s1
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	038080e7          	jalr	56(ra) # 80003066 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004036:	2a05                	addiw	s4,s4,1
    80004038:	0a91                	addi	s5,s5,4
    8000403a:	02c9a783          	lw	a5,44(s3)
    8000403e:	f8fa49e3          	blt	s4,a5,80003fd0 <install_trans+0x30>
}
    80004042:	70e2                	ld	ra,56(sp)
    80004044:	7442                	ld	s0,48(sp)
    80004046:	74a2                	ld	s1,40(sp)
    80004048:	7902                	ld	s2,32(sp)
    8000404a:	69e2                	ld	s3,24(sp)
    8000404c:	6a42                	ld	s4,16(sp)
    8000404e:	6aa2                	ld	s5,8(sp)
    80004050:	6121                	addi	sp,sp,64
    80004052:	8082                	ret
    80004054:	8082                	ret

0000000080004056 <initlog>:
{
    80004056:	7179                	addi	sp,sp,-48
    80004058:	f406                	sd	ra,40(sp)
    8000405a:	f022                	sd	s0,32(sp)
    8000405c:	ec26                	sd	s1,24(sp)
    8000405e:	e84a                	sd	s2,16(sp)
    80004060:	e44e                	sd	s3,8(sp)
    80004062:	1800                	addi	s0,sp,48
    80004064:	892a                	mv	s2,a0
    80004066:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004068:	0001e497          	auipc	s1,0x1e
    8000406c:	8a048493          	addi	s1,s1,-1888 # 80021908 <log>
    80004070:	00004597          	auipc	a1,0x4
    80004074:	56858593          	addi	a1,a1,1384 # 800085d8 <syscalls+0x1d8>
    80004078:	8526                	mv	a0,s1
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	b06080e7          	jalr	-1274(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004082:	0149a583          	lw	a1,20(s3)
    80004086:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004088:	0109a783          	lw	a5,16(s3)
    8000408c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000408e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004092:	854a                	mv	a0,s2
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	ea2080e7          	jalr	-350(ra) # 80002f36 <bread>
  log.lh.n = lh->n;
    8000409c:	4d3c                	lw	a5,88(a0)
    8000409e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040a0:	02f05563          	blez	a5,800040ca <initlog+0x74>
    800040a4:	05c50713          	addi	a4,a0,92
    800040a8:	0001e697          	auipc	a3,0x1e
    800040ac:	89068693          	addi	a3,a3,-1904 # 80021938 <log+0x30>
    800040b0:	37fd                	addiw	a5,a5,-1
    800040b2:	1782                	slli	a5,a5,0x20
    800040b4:	9381                	srli	a5,a5,0x20
    800040b6:	078a                	slli	a5,a5,0x2
    800040b8:	06050613          	addi	a2,a0,96
    800040bc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040be:	4310                	lw	a2,0(a4)
    800040c0:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040c2:	0711                	addi	a4,a4,4
    800040c4:	0691                	addi	a3,a3,4
    800040c6:	fef71ce3          	bne	a4,a5,800040be <initlog+0x68>
  brelse(buf);
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	f9c080e7          	jalr	-100(ra) # 80003066 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040d2:	00000097          	auipc	ra,0x0
    800040d6:	ece080e7          	jalr	-306(ra) # 80003fa0 <install_trans>
  log.lh.n = 0;
    800040da:	0001e797          	auipc	a5,0x1e
    800040de:	8407ad23          	sw	zero,-1958(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	e44080e7          	jalr	-444(ra) # 80003f26 <write_head>
}
    800040ea:	70a2                	ld	ra,40(sp)
    800040ec:	7402                	ld	s0,32(sp)
    800040ee:	64e2                	ld	s1,24(sp)
    800040f0:	6942                	ld	s2,16(sp)
    800040f2:	69a2                	ld	s3,8(sp)
    800040f4:	6145                	addi	sp,sp,48
    800040f6:	8082                	ret

00000000800040f8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040f8:	1101                	addi	sp,sp,-32
    800040fa:	ec06                	sd	ra,24(sp)
    800040fc:	e822                	sd	s0,16(sp)
    800040fe:	e426                	sd	s1,8(sp)
    80004100:	e04a                	sd	s2,0(sp)
    80004102:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004104:	0001e517          	auipc	a0,0x1e
    80004108:	80450513          	addi	a0,a0,-2044 # 80021908 <log>
    8000410c:	ffffd097          	auipc	ra,0xffffd
    80004110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004114:	0001d497          	auipc	s1,0x1d
    80004118:	7f448493          	addi	s1,s1,2036 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411c:	4979                	li	s2,30
    8000411e:	a039                	j	8000412c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004120:	85a6                	mv	a1,s1
    80004122:	8526                	mv	a0,s1
    80004124:	ffffe097          	auipc	ra,0xffffe
    80004128:	1aa080e7          	jalr	426(ra) # 800022ce <sleep>
    if(log.committing){
    8000412c:	50dc                	lw	a5,36(s1)
    8000412e:	fbed                	bnez	a5,80004120 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004130:	509c                	lw	a5,32(s1)
    80004132:	0017871b          	addiw	a4,a5,1
    80004136:	0007069b          	sext.w	a3,a4
    8000413a:	0027179b          	slliw	a5,a4,0x2
    8000413e:	9fb9                	addw	a5,a5,a4
    80004140:	0017979b          	slliw	a5,a5,0x1
    80004144:	54d8                	lw	a4,44(s1)
    80004146:	9fb9                	addw	a5,a5,a4
    80004148:	00f95963          	bge	s2,a5,8000415a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414c:	85a6                	mv	a1,s1
    8000414e:	8526                	mv	a0,s1
    80004150:	ffffe097          	auipc	ra,0xffffe
    80004154:	17e080e7          	jalr	382(ra) # 800022ce <sleep>
    80004158:	bfd1                	j	8000412c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000415a:	0001d517          	auipc	a0,0x1d
    8000415e:	7ae50513          	addi	a0,a0,1966 # 80021908 <log>
    80004162:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	b60080e7          	jalr	-1184(ra) # 80000cc4 <release>
      break;
    }
  }
}
    8000416c:	60e2                	ld	ra,24(sp)
    8000416e:	6442                	ld	s0,16(sp)
    80004170:	64a2                	ld	s1,8(sp)
    80004172:	6902                	ld	s2,0(sp)
    80004174:	6105                	addi	sp,sp,32
    80004176:	8082                	ret

0000000080004178 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004178:	7139                	addi	sp,sp,-64
    8000417a:	fc06                	sd	ra,56(sp)
    8000417c:	f822                	sd	s0,48(sp)
    8000417e:	f426                	sd	s1,40(sp)
    80004180:	f04a                	sd	s2,32(sp)
    80004182:	ec4e                	sd	s3,24(sp)
    80004184:	e852                	sd	s4,16(sp)
    80004186:	e456                	sd	s5,8(sp)
    80004188:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000418a:	0001d497          	auipc	s1,0x1d
    8000418e:	77e48493          	addi	s1,s1,1918 # 80021908 <log>
    80004192:	8526                	mv	a0,s1
    80004194:	ffffd097          	auipc	ra,0xffffd
    80004198:	a7c080e7          	jalr	-1412(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    8000419c:	509c                	lw	a5,32(s1)
    8000419e:	37fd                	addiw	a5,a5,-1
    800041a0:	0007891b          	sext.w	s2,a5
    800041a4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a6:	50dc                	lw	a5,36(s1)
    800041a8:	efb9                	bnez	a5,80004206 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041aa:	06091663          	bnez	s2,80004216 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041ae:	0001d497          	auipc	s1,0x1d
    800041b2:	75a48493          	addi	s1,s1,1882 # 80021908 <log>
    800041b6:	4785                	li	a5,1
    800041b8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041ba:	8526                	mv	a0,s1
    800041bc:	ffffd097          	auipc	ra,0xffffd
    800041c0:	b08080e7          	jalr	-1272(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c4:	54dc                	lw	a5,44(s1)
    800041c6:	06f04763          	bgtz	a5,80004234 <end_op+0xbc>
    acquire(&log.lock);
    800041ca:	0001d497          	auipc	s1,0x1d
    800041ce:	73e48493          	addi	s1,s1,1854 # 80021908 <log>
    800041d2:	8526                	mv	a0,s1
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	a3c080e7          	jalr	-1476(ra) # 80000c10 <acquire>
    log.committing = 0;
    800041dc:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041e0:	8526                	mv	a0,s1
    800041e2:	ffffe097          	auipc	ra,0xffffe
    800041e6:	272080e7          	jalr	626(ra) # 80002454 <wakeup>
    release(&log.lock);
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffd097          	auipc	ra,0xffffd
    800041f0:	ad8080e7          	jalr	-1320(ra) # 80000cc4 <release>
}
    800041f4:	70e2                	ld	ra,56(sp)
    800041f6:	7442                	ld	s0,48(sp)
    800041f8:	74a2                	ld	s1,40(sp)
    800041fa:	7902                	ld	s2,32(sp)
    800041fc:	69e2                	ld	s3,24(sp)
    800041fe:	6a42                	ld	s4,16(sp)
    80004200:	6aa2                	ld	s5,8(sp)
    80004202:	6121                	addi	sp,sp,64
    80004204:	8082                	ret
    panic("log.committing");
    80004206:	00004517          	auipc	a0,0x4
    8000420a:	3da50513          	addi	a0,a0,986 # 800085e0 <syscalls+0x1e0>
    8000420e:	ffffc097          	auipc	ra,0xffffc
    80004212:	33a080e7          	jalr	826(ra) # 80000548 <panic>
    wakeup(&log);
    80004216:	0001d497          	auipc	s1,0x1d
    8000421a:	6f248493          	addi	s1,s1,1778 # 80021908 <log>
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffe097          	auipc	ra,0xffffe
    80004224:	234080e7          	jalr	564(ra) # 80002454 <wakeup>
  release(&log.lock);
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	a9a080e7          	jalr	-1382(ra) # 80000cc4 <release>
  if(do_commit){
    80004232:	b7c9                	j	800041f4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004234:	0001da97          	auipc	s5,0x1d
    80004238:	704a8a93          	addi	s5,s5,1796 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423c:	0001da17          	auipc	s4,0x1d
    80004240:	6cca0a13          	addi	s4,s4,1740 # 80021908 <log>
    80004244:	018a2583          	lw	a1,24(s4)
    80004248:	012585bb          	addw	a1,a1,s2
    8000424c:	2585                	addiw	a1,a1,1
    8000424e:	028a2503          	lw	a0,40(s4)
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	ce4080e7          	jalr	-796(ra) # 80002f36 <bread>
    8000425a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425c:	000aa583          	lw	a1,0(s5)
    80004260:	028a2503          	lw	a0,40(s4)
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	cd2080e7          	jalr	-814(ra) # 80002f36 <bread>
    8000426c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000426e:	40000613          	li	a2,1024
    80004272:	05850593          	addi	a1,a0,88
    80004276:	05848513          	addi	a0,s1,88
    8000427a:	ffffd097          	auipc	ra,0xffffd
    8000427e:	af2080e7          	jalr	-1294(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004282:	8526                	mv	a0,s1
    80004284:	fffff097          	auipc	ra,0xfffff
    80004288:	da4080e7          	jalr	-604(ra) # 80003028 <bwrite>
    brelse(from);
    8000428c:	854e                	mv	a0,s3
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	dd8080e7          	jalr	-552(ra) # 80003066 <brelse>
    brelse(to);
    80004296:	8526                	mv	a0,s1
    80004298:	fffff097          	auipc	ra,0xfffff
    8000429c:	dce080e7          	jalr	-562(ra) # 80003066 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a0:	2905                	addiw	s2,s2,1
    800042a2:	0a91                	addi	s5,s5,4
    800042a4:	02ca2783          	lw	a5,44(s4)
    800042a8:	f8f94ee3          	blt	s2,a5,80004244 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ac:	00000097          	auipc	ra,0x0
    800042b0:	c7a080e7          	jalr	-902(ra) # 80003f26 <write_head>
    install_trans(); // Now install writes to home locations
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	cec080e7          	jalr	-788(ra) # 80003fa0 <install_trans>
    log.lh.n = 0;
    800042bc:	0001d797          	auipc	a5,0x1d
    800042c0:	6607ac23          	sw	zero,1656(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c4:	00000097          	auipc	ra,0x0
    800042c8:	c62080e7          	jalr	-926(ra) # 80003f26 <write_head>
    800042cc:	bdfd                	j	800041ca <end_op+0x52>

00000000800042ce <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042ce:	1101                	addi	sp,sp,-32
    800042d0:	ec06                	sd	ra,24(sp)
    800042d2:	e822                	sd	s0,16(sp)
    800042d4:	e426                	sd	s1,8(sp)
    800042d6:	e04a                	sd	s2,0(sp)
    800042d8:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042da:	0001d717          	auipc	a4,0x1d
    800042de:	65a72703          	lw	a4,1626(a4) # 80021934 <log+0x2c>
    800042e2:	47f5                	li	a5,29
    800042e4:	08e7c063          	blt	a5,a4,80004364 <log_write+0x96>
    800042e8:	84aa                	mv	s1,a0
    800042ea:	0001d797          	auipc	a5,0x1d
    800042ee:	63a7a783          	lw	a5,1594(a5) # 80021924 <log+0x1c>
    800042f2:	37fd                	addiw	a5,a5,-1
    800042f4:	06f75863          	bge	a4,a5,80004364 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042f8:	0001d797          	auipc	a5,0x1d
    800042fc:	6307a783          	lw	a5,1584(a5) # 80021928 <log+0x20>
    80004300:	06f05a63          	blez	a5,80004374 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004304:	0001d917          	auipc	s2,0x1d
    80004308:	60490913          	addi	s2,s2,1540 # 80021908 <log>
    8000430c:	854a                	mv	a0,s2
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	902080e7          	jalr	-1790(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004316:	02c92603          	lw	a2,44(s2)
    8000431a:	06c05563          	blez	a2,80004384 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000431e:	44cc                	lw	a1,12(s1)
    80004320:	0001d717          	auipc	a4,0x1d
    80004324:	61870713          	addi	a4,a4,1560 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004328:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000432a:	4314                	lw	a3,0(a4)
    8000432c:	04b68d63          	beq	a3,a1,80004386 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004330:	2785                	addiw	a5,a5,1
    80004332:	0711                	addi	a4,a4,4
    80004334:	fec79be3          	bne	a5,a2,8000432a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004338:	0621                	addi	a2,a2,8
    8000433a:	060a                	slli	a2,a2,0x2
    8000433c:	0001d797          	auipc	a5,0x1d
    80004340:	5cc78793          	addi	a5,a5,1484 # 80021908 <log>
    80004344:	963e                	add	a2,a2,a5
    80004346:	44dc                	lw	a5,12(s1)
    80004348:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000434a:	8526                	mv	a0,s1
    8000434c:	fffff097          	auipc	ra,0xfffff
    80004350:	db8080e7          	jalr	-584(ra) # 80003104 <bpin>
    log.lh.n++;
    80004354:	0001d717          	auipc	a4,0x1d
    80004358:	5b470713          	addi	a4,a4,1460 # 80021908 <log>
    8000435c:	575c                	lw	a5,44(a4)
    8000435e:	2785                	addiw	a5,a5,1
    80004360:	d75c                	sw	a5,44(a4)
    80004362:	a83d                	j	800043a0 <log_write+0xd2>
    panic("too big a transaction");
    80004364:	00004517          	auipc	a0,0x4
    80004368:	28c50513          	addi	a0,a0,652 # 800085f0 <syscalls+0x1f0>
    8000436c:	ffffc097          	auipc	ra,0xffffc
    80004370:	1dc080e7          	jalr	476(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004374:	00004517          	auipc	a0,0x4
    80004378:	29450513          	addi	a0,a0,660 # 80008608 <syscalls+0x208>
    8000437c:	ffffc097          	auipc	ra,0xffffc
    80004380:	1cc080e7          	jalr	460(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004384:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004386:	00878713          	addi	a4,a5,8
    8000438a:	00271693          	slli	a3,a4,0x2
    8000438e:	0001d717          	auipc	a4,0x1d
    80004392:	57a70713          	addi	a4,a4,1402 # 80021908 <log>
    80004396:	9736                	add	a4,a4,a3
    80004398:	44d4                	lw	a3,12(s1)
    8000439a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000439c:	faf607e3          	beq	a2,a5,8000434a <log_write+0x7c>
  }
  release(&log.lock);
    800043a0:	0001d517          	auipc	a0,0x1d
    800043a4:	56850513          	addi	a0,a0,1384 # 80021908 <log>
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	91c080e7          	jalr	-1764(ra) # 80000cc4 <release>
}
    800043b0:	60e2                	ld	ra,24(sp)
    800043b2:	6442                	ld	s0,16(sp)
    800043b4:	64a2                	ld	s1,8(sp)
    800043b6:	6902                	ld	s2,0(sp)
    800043b8:	6105                	addi	sp,sp,32
    800043ba:	8082                	ret

00000000800043bc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043bc:	1101                	addi	sp,sp,-32
    800043be:	ec06                	sd	ra,24(sp)
    800043c0:	e822                	sd	s0,16(sp)
    800043c2:	e426                	sd	s1,8(sp)
    800043c4:	e04a                	sd	s2,0(sp)
    800043c6:	1000                	addi	s0,sp,32
    800043c8:	84aa                	mv	s1,a0
    800043ca:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043cc:	00004597          	auipc	a1,0x4
    800043d0:	25c58593          	addi	a1,a1,604 # 80008628 <syscalls+0x228>
    800043d4:	0521                	addi	a0,a0,8
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	7aa080e7          	jalr	1962(ra) # 80000b80 <initlock>
  lk->name = name;
    800043de:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e6:	0204a423          	sw	zero,40(s1)
}
    800043ea:	60e2                	ld	ra,24(sp)
    800043ec:	6442                	ld	s0,16(sp)
    800043ee:	64a2                	ld	s1,8(sp)
    800043f0:	6902                	ld	s2,0(sp)
    800043f2:	6105                	addi	sp,sp,32
    800043f4:	8082                	ret

00000000800043f6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f6:	1101                	addi	sp,sp,-32
    800043f8:	ec06                	sd	ra,24(sp)
    800043fa:	e822                	sd	s0,16(sp)
    800043fc:	e426                	sd	s1,8(sp)
    800043fe:	e04a                	sd	s2,0(sp)
    80004400:	1000                	addi	s0,sp,32
    80004402:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004404:	00850913          	addi	s2,a0,8
    80004408:	854a                	mv	a0,s2
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	806080e7          	jalr	-2042(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004412:	409c                	lw	a5,0(s1)
    80004414:	cb89                	beqz	a5,80004426 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004416:	85ca                	mv	a1,s2
    80004418:	8526                	mv	a0,s1
    8000441a:	ffffe097          	auipc	ra,0xffffe
    8000441e:	eb4080e7          	jalr	-332(ra) # 800022ce <sleep>
  while (lk->locked) {
    80004422:	409c                	lw	a5,0(s1)
    80004424:	fbed                	bnez	a5,80004416 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004426:	4785                	li	a5,1
    80004428:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	694080e7          	jalr	1684(ra) # 80001abe <myproc>
    80004432:	5d1c                	lw	a5,56(a0)
    80004434:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004436:	854a                	mv	a0,s2
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	88c080e7          	jalr	-1908(ra) # 80000cc4 <release>
}
    80004440:	60e2                	ld	ra,24(sp)
    80004442:	6442                	ld	s0,16(sp)
    80004444:	64a2                	ld	s1,8(sp)
    80004446:	6902                	ld	s2,0(sp)
    80004448:	6105                	addi	sp,sp,32
    8000444a:	8082                	ret

000000008000444c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	e04a                	sd	s2,0(sp)
    80004456:	1000                	addi	s0,sp,32
    80004458:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000445a:	00850913          	addi	s2,a0,8
    8000445e:	854a                	mv	a0,s2
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	7b0080e7          	jalr	1968(ra) # 80000c10 <acquire>
  lk->locked = 0;
    80004468:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004470:	8526                	mv	a0,s1
    80004472:	ffffe097          	auipc	ra,0xffffe
    80004476:	fe2080e7          	jalr	-30(ra) # 80002454 <wakeup>
  release(&lk->lk);
    8000447a:	854a                	mv	a0,s2
    8000447c:	ffffd097          	auipc	ra,0xffffd
    80004480:	848080e7          	jalr	-1976(ra) # 80000cc4 <release>
}
    80004484:	60e2                	ld	ra,24(sp)
    80004486:	6442                	ld	s0,16(sp)
    80004488:	64a2                	ld	s1,8(sp)
    8000448a:	6902                	ld	s2,0(sp)
    8000448c:	6105                	addi	sp,sp,32
    8000448e:	8082                	ret

0000000080004490 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004490:	7179                	addi	sp,sp,-48
    80004492:	f406                	sd	ra,40(sp)
    80004494:	f022                	sd	s0,32(sp)
    80004496:	ec26                	sd	s1,24(sp)
    80004498:	e84a                	sd	s2,16(sp)
    8000449a:	e44e                	sd	s3,8(sp)
    8000449c:	1800                	addi	s0,sp,48
    8000449e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044a0:	00850913          	addi	s2,a0,8
    800044a4:	854a                	mv	a0,s2
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	76a080e7          	jalr	1898(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ae:	409c                	lw	a5,0(s1)
    800044b0:	ef99                	bnez	a5,800044ce <holdingsleep+0x3e>
    800044b2:	4481                	li	s1,0
  release(&lk->lk);
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffd097          	auipc	ra,0xffffd
    800044ba:	80e080e7          	jalr	-2034(ra) # 80000cc4 <release>
  return r;
}
    800044be:	8526                	mv	a0,s1
    800044c0:	70a2                	ld	ra,40(sp)
    800044c2:	7402                	ld	s0,32(sp)
    800044c4:	64e2                	ld	s1,24(sp)
    800044c6:	6942                	ld	s2,16(sp)
    800044c8:	69a2                	ld	s3,8(sp)
    800044ca:	6145                	addi	sp,sp,48
    800044cc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ce:	0284a983          	lw	s3,40(s1)
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	5ec080e7          	jalr	1516(ra) # 80001abe <myproc>
    800044da:	5d04                	lw	s1,56(a0)
    800044dc:	413484b3          	sub	s1,s1,s3
    800044e0:	0014b493          	seqz	s1,s1
    800044e4:	bfc1                	j	800044b4 <holdingsleep+0x24>

00000000800044e6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e6:	1141                	addi	sp,sp,-16
    800044e8:	e406                	sd	ra,8(sp)
    800044ea:	e022                	sd	s0,0(sp)
    800044ec:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044ee:	00004597          	auipc	a1,0x4
    800044f2:	14a58593          	addi	a1,a1,330 # 80008638 <syscalls+0x238>
    800044f6:	0001d517          	auipc	a0,0x1d
    800044fa:	55a50513          	addi	a0,a0,1370 # 80021a50 <ftable>
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	682080e7          	jalr	1666(ra) # 80000b80 <initlock>
}
    80004506:	60a2                	ld	ra,8(sp)
    80004508:	6402                	ld	s0,0(sp)
    8000450a:	0141                	addi	sp,sp,16
    8000450c:	8082                	ret

000000008000450e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000450e:	1101                	addi	sp,sp,-32
    80004510:	ec06                	sd	ra,24(sp)
    80004512:	e822                	sd	s0,16(sp)
    80004514:	e426                	sd	s1,8(sp)
    80004516:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004518:	0001d517          	auipc	a0,0x1d
    8000451c:	53850513          	addi	a0,a0,1336 # 80021a50 <ftable>
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	6f0080e7          	jalr	1776(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004528:	0001d497          	auipc	s1,0x1d
    8000452c:	54048493          	addi	s1,s1,1344 # 80021a68 <ftable+0x18>
    80004530:	0001e717          	auipc	a4,0x1e
    80004534:	4d870713          	addi	a4,a4,1240 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    80004538:	40dc                	lw	a5,4(s1)
    8000453a:	cf99                	beqz	a5,80004558 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453c:	02848493          	addi	s1,s1,40
    80004540:	fee49ce3          	bne	s1,a4,80004538 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004544:	0001d517          	auipc	a0,0x1d
    80004548:	50c50513          	addi	a0,a0,1292 # 80021a50 <ftable>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	778080e7          	jalr	1912(ra) # 80000cc4 <release>
  return 0;
    80004554:	4481                	li	s1,0
    80004556:	a819                	j	8000456c <filealloc+0x5e>
      f->ref = 1;
    80004558:	4785                	li	a5,1
    8000455a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000455c:	0001d517          	auipc	a0,0x1d
    80004560:	4f450513          	addi	a0,a0,1268 # 80021a50 <ftable>
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	760080e7          	jalr	1888(ra) # 80000cc4 <release>
}
    8000456c:	8526                	mv	a0,s1
    8000456e:	60e2                	ld	ra,24(sp)
    80004570:	6442                	ld	s0,16(sp)
    80004572:	64a2                	ld	s1,8(sp)
    80004574:	6105                	addi	sp,sp,32
    80004576:	8082                	ret

0000000080004578 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004578:	1101                	addi	sp,sp,-32
    8000457a:	ec06                	sd	ra,24(sp)
    8000457c:	e822                	sd	s0,16(sp)
    8000457e:	e426                	sd	s1,8(sp)
    80004580:	1000                	addi	s0,sp,32
    80004582:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	4cc50513          	addi	a0,a0,1228 # 80021a50 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	684080e7          	jalr	1668(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004594:	40dc                	lw	a5,4(s1)
    80004596:	02f05263          	blez	a5,800045ba <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000459a:	2785                	addiw	a5,a5,1
    8000459c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000459e:	0001d517          	auipc	a0,0x1d
    800045a2:	4b250513          	addi	a0,a0,1202 # 80021a50 <ftable>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	71e080e7          	jalr	1822(ra) # 80000cc4 <release>
  return f;
}
    800045ae:	8526                	mv	a0,s1
    800045b0:	60e2                	ld	ra,24(sp)
    800045b2:	6442                	ld	s0,16(sp)
    800045b4:	64a2                	ld	s1,8(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret
    panic("filedup");
    800045ba:	00004517          	auipc	a0,0x4
    800045be:	08650513          	addi	a0,a0,134 # 80008640 <syscalls+0x240>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	f86080e7          	jalr	-122(ra) # 80000548 <panic>

00000000800045ca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045ca:	7139                	addi	sp,sp,-64
    800045cc:	fc06                	sd	ra,56(sp)
    800045ce:	f822                	sd	s0,48(sp)
    800045d0:	f426                	sd	s1,40(sp)
    800045d2:	f04a                	sd	s2,32(sp)
    800045d4:	ec4e                	sd	s3,24(sp)
    800045d6:	e852                	sd	s4,16(sp)
    800045d8:	e456                	sd	s5,8(sp)
    800045da:	0080                	addi	s0,sp,64
    800045dc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045de:	0001d517          	auipc	a0,0x1d
    800045e2:	47250513          	addi	a0,a0,1138 # 80021a50 <ftable>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	62a080e7          	jalr	1578(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800045ee:	40dc                	lw	a5,4(s1)
    800045f0:	06f05163          	blez	a5,80004652 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045f4:	37fd                	addiw	a5,a5,-1
    800045f6:	0007871b          	sext.w	a4,a5
    800045fa:	c0dc                	sw	a5,4(s1)
    800045fc:	06e04363          	bgtz	a4,80004662 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004600:	0004a903          	lw	s2,0(s1)
    80004604:	0094ca83          	lbu	s5,9(s1)
    80004608:	0104ba03          	ld	s4,16(s1)
    8000460c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004610:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004614:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	43850513          	addi	a0,a0,1080 # 80021a50 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	6a4080e7          	jalr	1700(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    80004628:	4785                	li	a5,1
    8000462a:	04f90d63          	beq	s2,a5,80004684 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000462e:	3979                	addiw	s2,s2,-2
    80004630:	4785                	li	a5,1
    80004632:	0527e063          	bltu	a5,s2,80004672 <fileclose+0xa8>
    begin_op();
    80004636:	00000097          	auipc	ra,0x0
    8000463a:	ac2080e7          	jalr	-1342(ra) # 800040f8 <begin_op>
    iput(ff.ip);
    8000463e:	854e                	mv	a0,s3
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	2b2080e7          	jalr	690(ra) # 800038f2 <iput>
    end_op();
    80004648:	00000097          	auipc	ra,0x0
    8000464c:	b30080e7          	jalr	-1232(ra) # 80004178 <end_op>
    80004650:	a00d                	j	80004672 <fileclose+0xa8>
    panic("fileclose");
    80004652:	00004517          	auipc	a0,0x4
    80004656:	ff650513          	addi	a0,a0,-10 # 80008648 <syscalls+0x248>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	eee080e7          	jalr	-274(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004662:	0001d517          	auipc	a0,0x1d
    80004666:	3ee50513          	addi	a0,a0,1006 # 80021a50 <ftable>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	65a080e7          	jalr	1626(ra) # 80000cc4 <release>
  }
}
    80004672:	70e2                	ld	ra,56(sp)
    80004674:	7442                	ld	s0,48(sp)
    80004676:	74a2                	ld	s1,40(sp)
    80004678:	7902                	ld	s2,32(sp)
    8000467a:	69e2                	ld	s3,24(sp)
    8000467c:	6a42                	ld	s4,16(sp)
    8000467e:	6aa2                	ld	s5,8(sp)
    80004680:	6121                	addi	sp,sp,64
    80004682:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004684:	85d6                	mv	a1,s5
    80004686:	8552                	mv	a0,s4
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	372080e7          	jalr	882(ra) # 800049fa <pipeclose>
    80004690:	b7cd                	j	80004672 <fileclose+0xa8>

0000000080004692 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004692:	715d                	addi	sp,sp,-80
    80004694:	e486                	sd	ra,72(sp)
    80004696:	e0a2                	sd	s0,64(sp)
    80004698:	fc26                	sd	s1,56(sp)
    8000469a:	f84a                	sd	s2,48(sp)
    8000469c:	f44e                	sd	s3,40(sp)
    8000469e:	0880                	addi	s0,sp,80
    800046a0:	84aa                	mv	s1,a0
    800046a2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046a4:	ffffd097          	auipc	ra,0xffffd
    800046a8:	41a080e7          	jalr	1050(ra) # 80001abe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ac:	409c                	lw	a5,0(s1)
    800046ae:	37f9                	addiw	a5,a5,-2
    800046b0:	4705                	li	a4,1
    800046b2:	04f76763          	bltu	a4,a5,80004700 <filestat+0x6e>
    800046b6:	892a                	mv	s2,a0
    ilock(f->ip);
    800046b8:	6c88                	ld	a0,24(s1)
    800046ba:	fffff097          	auipc	ra,0xfffff
    800046be:	07e080e7          	jalr	126(ra) # 80003738 <ilock>
    stati(f->ip, &st);
    800046c2:	fb840593          	addi	a1,s0,-72
    800046c6:	6c88                	ld	a0,24(s1)
    800046c8:	fffff097          	auipc	ra,0xfffff
    800046cc:	2fa080e7          	jalr	762(ra) # 800039c2 <stati>
    iunlock(f->ip);
    800046d0:	6c88                	ld	a0,24(s1)
    800046d2:	fffff097          	auipc	ra,0xfffff
    800046d6:	128080e7          	jalr	296(ra) # 800037fa <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046da:	46e1                	li	a3,24
    800046dc:	fb840613          	addi	a2,s0,-72
    800046e0:	85ce                	mv	a1,s3
    800046e2:	05093503          	ld	a0,80(s2)
    800046e6:	ffffd097          	auipc	ra,0xffffd
    800046ea:	098080e7          	jalr	152(ra) # 8000177e <copyout>
    800046ee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046f2:	60a6                	ld	ra,72(sp)
    800046f4:	6406                	ld	s0,64(sp)
    800046f6:	74e2                	ld	s1,56(sp)
    800046f8:	7942                	ld	s2,48(sp)
    800046fa:	79a2                	ld	s3,40(sp)
    800046fc:	6161                	addi	sp,sp,80
    800046fe:	8082                	ret
  return -1;
    80004700:	557d                	li	a0,-1
    80004702:	bfc5                	j	800046f2 <filestat+0x60>

0000000080004704 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004704:	7179                	addi	sp,sp,-48
    80004706:	f406                	sd	ra,40(sp)
    80004708:	f022                	sd	s0,32(sp)
    8000470a:	ec26                	sd	s1,24(sp)
    8000470c:	e84a                	sd	s2,16(sp)
    8000470e:	e44e                	sd	s3,8(sp)
    80004710:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004712:	00854783          	lbu	a5,8(a0)
    80004716:	c3d5                	beqz	a5,800047ba <fileread+0xb6>
    80004718:	84aa                	mv	s1,a0
    8000471a:	89ae                	mv	s3,a1
    8000471c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000471e:	411c                	lw	a5,0(a0)
    80004720:	4705                	li	a4,1
    80004722:	04e78963          	beq	a5,a4,80004774 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004726:	470d                	li	a4,3
    80004728:	04e78d63          	beq	a5,a4,80004782 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000472c:	4709                	li	a4,2
    8000472e:	06e79e63          	bne	a5,a4,800047aa <fileread+0xa6>
    ilock(f->ip);
    80004732:	6d08                	ld	a0,24(a0)
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	004080e7          	jalr	4(ra) # 80003738 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000473c:	874a                	mv	a4,s2
    8000473e:	5094                	lw	a3,32(s1)
    80004740:	864e                	mv	a2,s3
    80004742:	4585                	li	a1,1
    80004744:	6c88                	ld	a0,24(s1)
    80004746:	fffff097          	auipc	ra,0xfffff
    8000474a:	2a6080e7          	jalr	678(ra) # 800039ec <readi>
    8000474e:	892a                	mv	s2,a0
    80004750:	00a05563          	blez	a0,8000475a <fileread+0x56>
      f->off += r;
    80004754:	509c                	lw	a5,32(s1)
    80004756:	9fa9                	addw	a5,a5,a0
    80004758:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000475a:	6c88                	ld	a0,24(s1)
    8000475c:	fffff097          	auipc	ra,0xfffff
    80004760:	09e080e7          	jalr	158(ra) # 800037fa <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004764:	854a                	mv	a0,s2
    80004766:	70a2                	ld	ra,40(sp)
    80004768:	7402                	ld	s0,32(sp)
    8000476a:	64e2                	ld	s1,24(sp)
    8000476c:	6942                	ld	s2,16(sp)
    8000476e:	69a2                	ld	s3,8(sp)
    80004770:	6145                	addi	sp,sp,48
    80004772:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004774:	6908                	ld	a0,16(a0)
    80004776:	00000097          	auipc	ra,0x0
    8000477a:	418080e7          	jalr	1048(ra) # 80004b8e <piperead>
    8000477e:	892a                	mv	s2,a0
    80004780:	b7d5                	j	80004764 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004782:	02451783          	lh	a5,36(a0)
    80004786:	03079693          	slli	a3,a5,0x30
    8000478a:	92c1                	srli	a3,a3,0x30
    8000478c:	4725                	li	a4,9
    8000478e:	02d76863          	bltu	a4,a3,800047be <fileread+0xba>
    80004792:	0792                	slli	a5,a5,0x4
    80004794:	0001d717          	auipc	a4,0x1d
    80004798:	21c70713          	addi	a4,a4,540 # 800219b0 <devsw>
    8000479c:	97ba                	add	a5,a5,a4
    8000479e:	639c                	ld	a5,0(a5)
    800047a0:	c38d                	beqz	a5,800047c2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047a2:	4505                	li	a0,1
    800047a4:	9782                	jalr	a5
    800047a6:	892a                	mv	s2,a0
    800047a8:	bf75                	j	80004764 <fileread+0x60>
    panic("fileread");
    800047aa:	00004517          	auipc	a0,0x4
    800047ae:	eae50513          	addi	a0,a0,-338 # 80008658 <syscalls+0x258>
    800047b2:	ffffc097          	auipc	ra,0xffffc
    800047b6:	d96080e7          	jalr	-618(ra) # 80000548 <panic>
    return -1;
    800047ba:	597d                	li	s2,-1
    800047bc:	b765                	j	80004764 <fileread+0x60>
      return -1;
    800047be:	597d                	li	s2,-1
    800047c0:	b755                	j	80004764 <fileread+0x60>
    800047c2:	597d                	li	s2,-1
    800047c4:	b745                	j	80004764 <fileread+0x60>

00000000800047c6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047c6:	00954783          	lbu	a5,9(a0)
    800047ca:	14078563          	beqz	a5,80004914 <filewrite+0x14e>
{
    800047ce:	715d                	addi	sp,sp,-80
    800047d0:	e486                	sd	ra,72(sp)
    800047d2:	e0a2                	sd	s0,64(sp)
    800047d4:	fc26                	sd	s1,56(sp)
    800047d6:	f84a                	sd	s2,48(sp)
    800047d8:	f44e                	sd	s3,40(sp)
    800047da:	f052                	sd	s4,32(sp)
    800047dc:	ec56                	sd	s5,24(sp)
    800047de:	e85a                	sd	s6,16(sp)
    800047e0:	e45e                	sd	s7,8(sp)
    800047e2:	e062                	sd	s8,0(sp)
    800047e4:	0880                	addi	s0,sp,80
    800047e6:	892a                	mv	s2,a0
    800047e8:	8aae                	mv	s5,a1
    800047ea:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ec:	411c                	lw	a5,0(a0)
    800047ee:	4705                	li	a4,1
    800047f0:	02e78263          	beq	a5,a4,80004814 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047f4:	470d                	li	a4,3
    800047f6:	02e78563          	beq	a5,a4,80004820 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047fa:	4709                	li	a4,2
    800047fc:	10e79463          	bne	a5,a4,80004904 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004800:	0ec05e63          	blez	a2,800048fc <filewrite+0x136>
    int i = 0;
    80004804:	4981                	li	s3,0
    80004806:	6b05                	lui	s6,0x1
    80004808:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000480c:	6b85                	lui	s7,0x1
    8000480e:	c00b8b9b          	addiw	s7,s7,-1024
    80004812:	a851                	j	800048a6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004814:	6908                	ld	a0,16(a0)
    80004816:	00000097          	auipc	ra,0x0
    8000481a:	254080e7          	jalr	596(ra) # 80004a6a <pipewrite>
    8000481e:	a85d                	j	800048d4 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004820:	02451783          	lh	a5,36(a0)
    80004824:	03079693          	slli	a3,a5,0x30
    80004828:	92c1                	srli	a3,a3,0x30
    8000482a:	4725                	li	a4,9
    8000482c:	0ed76663          	bltu	a4,a3,80004918 <filewrite+0x152>
    80004830:	0792                	slli	a5,a5,0x4
    80004832:	0001d717          	auipc	a4,0x1d
    80004836:	17e70713          	addi	a4,a4,382 # 800219b0 <devsw>
    8000483a:	97ba                	add	a5,a5,a4
    8000483c:	679c                	ld	a5,8(a5)
    8000483e:	cff9                	beqz	a5,8000491c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004840:	4505                	li	a0,1
    80004842:	9782                	jalr	a5
    80004844:	a841                	j	800048d4 <filewrite+0x10e>
    80004846:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000484a:	00000097          	auipc	ra,0x0
    8000484e:	8ae080e7          	jalr	-1874(ra) # 800040f8 <begin_op>
      ilock(f->ip);
    80004852:	01893503          	ld	a0,24(s2)
    80004856:	fffff097          	auipc	ra,0xfffff
    8000485a:	ee2080e7          	jalr	-286(ra) # 80003738 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000485e:	8762                	mv	a4,s8
    80004860:	02092683          	lw	a3,32(s2)
    80004864:	01598633          	add	a2,s3,s5
    80004868:	4585                	li	a1,1
    8000486a:	01893503          	ld	a0,24(s2)
    8000486e:	fffff097          	auipc	ra,0xfffff
    80004872:	276080e7          	jalr	630(ra) # 80003ae4 <writei>
    80004876:	84aa                	mv	s1,a0
    80004878:	02a05f63          	blez	a0,800048b6 <filewrite+0xf0>
        f->off += r;
    8000487c:	02092783          	lw	a5,32(s2)
    80004880:	9fa9                	addw	a5,a5,a0
    80004882:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004886:	01893503          	ld	a0,24(s2)
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	f70080e7          	jalr	-144(ra) # 800037fa <iunlock>
      end_op();
    80004892:	00000097          	auipc	ra,0x0
    80004896:	8e6080e7          	jalr	-1818(ra) # 80004178 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000489a:	049c1963          	bne	s8,s1,800048ec <filewrite+0x126>
        panic("short filewrite");
      i += r;
    8000489e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a2:	0349d663          	bge	s3,s4,800048ce <filewrite+0x108>
      int n1 = n - i;
    800048a6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048aa:	84be                	mv	s1,a5
    800048ac:	2781                	sext.w	a5,a5
    800048ae:	f8fb5ce3          	bge	s6,a5,80004846 <filewrite+0x80>
    800048b2:	84de                	mv	s1,s7
    800048b4:	bf49                	j	80004846 <filewrite+0x80>
      iunlock(f->ip);
    800048b6:	01893503          	ld	a0,24(s2)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	f40080e7          	jalr	-192(ra) # 800037fa <iunlock>
      end_op();
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	8b6080e7          	jalr	-1866(ra) # 80004178 <end_op>
      if(r < 0)
    800048ca:	fc04d8e3          	bgez	s1,8000489a <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048ce:	8552                	mv	a0,s4
    800048d0:	033a1863          	bne	s4,s3,80004900 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048d4:	60a6                	ld	ra,72(sp)
    800048d6:	6406                	ld	s0,64(sp)
    800048d8:	74e2                	ld	s1,56(sp)
    800048da:	7942                	ld	s2,48(sp)
    800048dc:	79a2                	ld	s3,40(sp)
    800048de:	7a02                	ld	s4,32(sp)
    800048e0:	6ae2                	ld	s5,24(sp)
    800048e2:	6b42                	ld	s6,16(sp)
    800048e4:	6ba2                	ld	s7,8(sp)
    800048e6:	6c02                	ld	s8,0(sp)
    800048e8:	6161                	addi	sp,sp,80
    800048ea:	8082                	ret
        panic("short filewrite");
    800048ec:	00004517          	auipc	a0,0x4
    800048f0:	d7c50513          	addi	a0,a0,-644 # 80008668 <syscalls+0x268>
    800048f4:	ffffc097          	auipc	ra,0xffffc
    800048f8:	c54080e7          	jalr	-940(ra) # 80000548 <panic>
    int i = 0;
    800048fc:	4981                	li	s3,0
    800048fe:	bfc1                	j	800048ce <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004900:	557d                	li	a0,-1
    80004902:	bfc9                	j	800048d4 <filewrite+0x10e>
    panic("filewrite");
    80004904:	00004517          	auipc	a0,0x4
    80004908:	d7450513          	addi	a0,a0,-652 # 80008678 <syscalls+0x278>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	c3c080e7          	jalr	-964(ra) # 80000548 <panic>
    return -1;
    80004914:	557d                	li	a0,-1
}
    80004916:	8082                	ret
      return -1;
    80004918:	557d                	li	a0,-1
    8000491a:	bf6d                	j	800048d4 <filewrite+0x10e>
    8000491c:	557d                	li	a0,-1
    8000491e:	bf5d                	j	800048d4 <filewrite+0x10e>

0000000080004920 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004920:	7179                	addi	sp,sp,-48
    80004922:	f406                	sd	ra,40(sp)
    80004924:	f022                	sd	s0,32(sp)
    80004926:	ec26                	sd	s1,24(sp)
    80004928:	e84a                	sd	s2,16(sp)
    8000492a:	e44e                	sd	s3,8(sp)
    8000492c:	e052                	sd	s4,0(sp)
    8000492e:	1800                	addi	s0,sp,48
    80004930:	84aa                	mv	s1,a0
    80004932:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004934:	0005b023          	sd	zero,0(a1)
    80004938:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	bd2080e7          	jalr	-1070(ra) # 8000450e <filealloc>
    80004944:	e088                	sd	a0,0(s1)
    80004946:	c551                	beqz	a0,800049d2 <pipealloc+0xb2>
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	bc6080e7          	jalr	-1082(ra) # 8000450e <filealloc>
    80004950:	00aa3023          	sd	a0,0(s4)
    80004954:	c92d                	beqz	a0,800049c6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004956:	ffffc097          	auipc	ra,0xffffc
    8000495a:	1ca080e7          	jalr	458(ra) # 80000b20 <kalloc>
    8000495e:	892a                	mv	s2,a0
    80004960:	c125                	beqz	a0,800049c0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004962:	4985                	li	s3,1
    80004964:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004968:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000496c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004970:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004974:	00004597          	auipc	a1,0x4
    80004978:	d1458593          	addi	a1,a1,-748 # 80008688 <syscalls+0x288>
    8000497c:	ffffc097          	auipc	ra,0xffffc
    80004980:	204080e7          	jalr	516(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004984:	609c                	ld	a5,0(s1)
    80004986:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000498a:	609c                	ld	a5,0(s1)
    8000498c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004990:	609c                	ld	a5,0(s1)
    80004992:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004996:	609c                	ld	a5,0(s1)
    80004998:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000499c:	000a3783          	ld	a5,0(s4)
    800049a0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049a4:	000a3783          	ld	a5,0(s4)
    800049a8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ac:	000a3783          	ld	a5,0(s4)
    800049b0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049b4:	000a3783          	ld	a5,0(s4)
    800049b8:	0127b823          	sd	s2,16(a5)
  return 0;
    800049bc:	4501                	li	a0,0
    800049be:	a025                	j	800049e6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049c0:	6088                	ld	a0,0(s1)
    800049c2:	e501                	bnez	a0,800049ca <pipealloc+0xaa>
    800049c4:	a039                	j	800049d2 <pipealloc+0xb2>
    800049c6:	6088                	ld	a0,0(s1)
    800049c8:	c51d                	beqz	a0,800049f6 <pipealloc+0xd6>
    fileclose(*f0);
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	c00080e7          	jalr	-1024(ra) # 800045ca <fileclose>
  if(*f1)
    800049d2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049d6:	557d                	li	a0,-1
  if(*f1)
    800049d8:	c799                	beqz	a5,800049e6 <pipealloc+0xc6>
    fileclose(*f1);
    800049da:	853e                	mv	a0,a5
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	bee080e7          	jalr	-1042(ra) # 800045ca <fileclose>
  return -1;
    800049e4:	557d                	li	a0,-1
}
    800049e6:	70a2                	ld	ra,40(sp)
    800049e8:	7402                	ld	s0,32(sp)
    800049ea:	64e2                	ld	s1,24(sp)
    800049ec:	6942                	ld	s2,16(sp)
    800049ee:	69a2                	ld	s3,8(sp)
    800049f0:	6a02                	ld	s4,0(sp)
    800049f2:	6145                	addi	sp,sp,48
    800049f4:	8082                	ret
  return -1;
    800049f6:	557d                	li	a0,-1
    800049f8:	b7fd                	j	800049e6 <pipealloc+0xc6>

00000000800049fa <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049fa:	1101                	addi	sp,sp,-32
    800049fc:	ec06                	sd	ra,24(sp)
    800049fe:	e822                	sd	s0,16(sp)
    80004a00:	e426                	sd	s1,8(sp)
    80004a02:	e04a                	sd	s2,0(sp)
    80004a04:	1000                	addi	s0,sp,32
    80004a06:	84aa                	mv	s1,a0
    80004a08:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	206080e7          	jalr	518(ra) # 80000c10 <acquire>
  if(writable){
    80004a12:	02090d63          	beqz	s2,80004a4c <pipeclose+0x52>
    pi->writeopen = 0;
    80004a16:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a1a:	21848513          	addi	a0,s1,536
    80004a1e:	ffffe097          	auipc	ra,0xffffe
    80004a22:	a36080e7          	jalr	-1482(ra) # 80002454 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a26:	2204b783          	ld	a5,544(s1)
    80004a2a:	eb95                	bnez	a5,80004a5e <pipeclose+0x64>
    release(&pi->lock);
    80004a2c:	8526                	mv	a0,s1
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	296080e7          	jalr	662(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004a36:	8526                	mv	a0,s1
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	fec080e7          	jalr	-20(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a40:	60e2                	ld	ra,24(sp)
    80004a42:	6442                	ld	s0,16(sp)
    80004a44:	64a2                	ld	s1,8(sp)
    80004a46:	6902                	ld	s2,0(sp)
    80004a48:	6105                	addi	sp,sp,32
    80004a4a:	8082                	ret
    pi->readopen = 0;
    80004a4c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a50:	21c48513          	addi	a0,s1,540
    80004a54:	ffffe097          	auipc	ra,0xffffe
    80004a58:	a00080e7          	jalr	-1536(ra) # 80002454 <wakeup>
    80004a5c:	b7e9                	j	80004a26 <pipeclose+0x2c>
    release(&pi->lock);
    80004a5e:	8526                	mv	a0,s1
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	264080e7          	jalr	612(ra) # 80000cc4 <release>
}
    80004a68:	bfe1                	j	80004a40 <pipeclose+0x46>

0000000080004a6a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a6a:	7119                	addi	sp,sp,-128
    80004a6c:	fc86                	sd	ra,120(sp)
    80004a6e:	f8a2                	sd	s0,112(sp)
    80004a70:	f4a6                	sd	s1,104(sp)
    80004a72:	f0ca                	sd	s2,96(sp)
    80004a74:	ecce                	sd	s3,88(sp)
    80004a76:	e8d2                	sd	s4,80(sp)
    80004a78:	e4d6                	sd	s5,72(sp)
    80004a7a:	e0da                	sd	s6,64(sp)
    80004a7c:	fc5e                	sd	s7,56(sp)
    80004a7e:	f862                	sd	s8,48(sp)
    80004a80:	f466                	sd	s9,40(sp)
    80004a82:	f06a                	sd	s10,32(sp)
    80004a84:	ec6e                	sd	s11,24(sp)
    80004a86:	0100                	addi	s0,sp,128
    80004a88:	84aa                	mv	s1,a0
    80004a8a:	8cae                	mv	s9,a1
    80004a8c:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a8e:	ffffd097          	auipc	ra,0xffffd
    80004a92:	030080e7          	jalr	48(ra) # 80001abe <myproc>
    80004a96:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a98:	8526                	mv	a0,s1
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	176080e7          	jalr	374(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004aa2:	0d605963          	blez	s6,80004b74 <pipewrite+0x10a>
    80004aa6:	89a6                	mv	s3,s1
    80004aa8:	3b7d                	addiw	s6,s6,-1
    80004aaa:	1b02                	slli	s6,s6,0x20
    80004aac:	020b5b13          	srli	s6,s6,0x20
    80004ab0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ab2:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ab6:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aba:	5dfd                	li	s11,-1
    80004abc:	000b8d1b          	sext.w	s10,s7
    80004ac0:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ac2:	2184a783          	lw	a5,536(s1)
    80004ac6:	21c4a703          	lw	a4,540(s1)
    80004aca:	2007879b          	addiw	a5,a5,512
    80004ace:	02f71b63          	bne	a4,a5,80004b04 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ad2:	2204a783          	lw	a5,544(s1)
    80004ad6:	cbad                	beqz	a5,80004b48 <pipewrite+0xde>
    80004ad8:	03092783          	lw	a5,48(s2)
    80004adc:	e7b5                	bnez	a5,80004b48 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004ade:	8556                	mv	a0,s5
    80004ae0:	ffffe097          	auipc	ra,0xffffe
    80004ae4:	974080e7          	jalr	-1676(ra) # 80002454 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ae8:	85ce                	mv	a1,s3
    80004aea:	8552                	mv	a0,s4
    80004aec:	ffffd097          	auipc	ra,0xffffd
    80004af0:	7e2080e7          	jalr	2018(ra) # 800022ce <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004af4:	2184a783          	lw	a5,536(s1)
    80004af8:	21c4a703          	lw	a4,540(s1)
    80004afc:	2007879b          	addiw	a5,a5,512
    80004b00:	fcf709e3          	beq	a4,a5,80004ad2 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b04:	4685                	li	a3,1
    80004b06:	019b8633          	add	a2,s7,s9
    80004b0a:	f8f40593          	addi	a1,s0,-113
    80004b0e:	05093503          	ld	a0,80(s2)
    80004b12:	ffffd097          	auipc	ra,0xffffd
    80004b16:	d12080e7          	jalr	-750(ra) # 80001824 <copyin>
    80004b1a:	05b50e63          	beq	a0,s11,80004b76 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b1e:	21c4a783          	lw	a5,540(s1)
    80004b22:	0017871b          	addiw	a4,a5,1
    80004b26:	20e4ae23          	sw	a4,540(s1)
    80004b2a:	1ff7f793          	andi	a5,a5,511
    80004b2e:	97a6                	add	a5,a5,s1
    80004b30:	f8f44703          	lbu	a4,-113(s0)
    80004b34:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b38:	001d0c1b          	addiw	s8,s10,1
    80004b3c:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b40:	036b8b63          	beq	s7,s6,80004b76 <pipewrite+0x10c>
    80004b44:	8bbe                	mv	s7,a5
    80004b46:	bf9d                	j	80004abc <pipewrite+0x52>
        release(&pi->lock);
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	17a080e7          	jalr	378(ra) # 80000cc4 <release>
        return -1;
    80004b52:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b54:	8562                	mv	a0,s8
    80004b56:	70e6                	ld	ra,120(sp)
    80004b58:	7446                	ld	s0,112(sp)
    80004b5a:	74a6                	ld	s1,104(sp)
    80004b5c:	7906                	ld	s2,96(sp)
    80004b5e:	69e6                	ld	s3,88(sp)
    80004b60:	6a46                	ld	s4,80(sp)
    80004b62:	6aa6                	ld	s5,72(sp)
    80004b64:	6b06                	ld	s6,64(sp)
    80004b66:	7be2                	ld	s7,56(sp)
    80004b68:	7c42                	ld	s8,48(sp)
    80004b6a:	7ca2                	ld	s9,40(sp)
    80004b6c:	7d02                	ld	s10,32(sp)
    80004b6e:	6de2                	ld	s11,24(sp)
    80004b70:	6109                	addi	sp,sp,128
    80004b72:	8082                	ret
  for(i = 0; i < n; i++){
    80004b74:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b76:	21848513          	addi	a0,s1,536
    80004b7a:	ffffe097          	auipc	ra,0xffffe
    80004b7e:	8da080e7          	jalr	-1830(ra) # 80002454 <wakeup>
  release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	140080e7          	jalr	320(ra) # 80000cc4 <release>
  return i;
    80004b8c:	b7e1                	j	80004b54 <pipewrite+0xea>

0000000080004b8e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b8e:	715d                	addi	sp,sp,-80
    80004b90:	e486                	sd	ra,72(sp)
    80004b92:	e0a2                	sd	s0,64(sp)
    80004b94:	fc26                	sd	s1,56(sp)
    80004b96:	f84a                	sd	s2,48(sp)
    80004b98:	f44e                	sd	s3,40(sp)
    80004b9a:	f052                	sd	s4,32(sp)
    80004b9c:	ec56                	sd	s5,24(sp)
    80004b9e:	e85a                	sd	s6,16(sp)
    80004ba0:	0880                	addi	s0,sp,80
    80004ba2:	84aa                	mv	s1,a0
    80004ba4:	892e                	mv	s2,a1
    80004ba6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ba8:	ffffd097          	auipc	ra,0xffffd
    80004bac:	f16080e7          	jalr	-234(ra) # 80001abe <myproc>
    80004bb0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bb2:	8b26                	mv	s6,s1
    80004bb4:	8526                	mv	a0,s1
    80004bb6:	ffffc097          	auipc	ra,0xffffc
    80004bba:	05a080e7          	jalr	90(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bbe:	2184a703          	lw	a4,536(s1)
    80004bc2:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc6:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bca:	02f71463          	bne	a4,a5,80004bf2 <piperead+0x64>
    80004bce:	2244a783          	lw	a5,548(s1)
    80004bd2:	c385                	beqz	a5,80004bf2 <piperead+0x64>
    if(pr->killed){
    80004bd4:	030a2783          	lw	a5,48(s4)
    80004bd8:	ebc1                	bnez	a5,80004c68 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bda:	85da                	mv	a1,s6
    80004bdc:	854e                	mv	a0,s3
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	6f0080e7          	jalr	1776(ra) # 800022ce <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be6:	2184a703          	lw	a4,536(s1)
    80004bea:	21c4a783          	lw	a5,540(s1)
    80004bee:	fef700e3          	beq	a4,a5,80004bce <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf2:	09505263          	blez	s5,80004c76 <piperead+0xe8>
    80004bf6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bfa:	2184a783          	lw	a5,536(s1)
    80004bfe:	21c4a703          	lw	a4,540(s1)
    80004c02:	02f70d63          	beq	a4,a5,80004c3c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c06:	0017871b          	addiw	a4,a5,1
    80004c0a:	20e4ac23          	sw	a4,536(s1)
    80004c0e:	1ff7f793          	andi	a5,a5,511
    80004c12:	97a6                	add	a5,a5,s1
    80004c14:	0187c783          	lbu	a5,24(a5)
    80004c18:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1c:	4685                	li	a3,1
    80004c1e:	fbf40613          	addi	a2,s0,-65
    80004c22:	85ca                	mv	a1,s2
    80004c24:	050a3503          	ld	a0,80(s4)
    80004c28:	ffffd097          	auipc	ra,0xffffd
    80004c2c:	b56080e7          	jalr	-1194(ra) # 8000177e <copyout>
    80004c30:	01650663          	beq	a0,s6,80004c3c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c34:	2985                	addiw	s3,s3,1
    80004c36:	0905                	addi	s2,s2,1
    80004c38:	fd3a91e3          	bne	s5,s3,80004bfa <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c3c:	21c48513          	addi	a0,s1,540
    80004c40:	ffffe097          	auipc	ra,0xffffe
    80004c44:	814080e7          	jalr	-2028(ra) # 80002454 <wakeup>
  release(&pi->lock);
    80004c48:	8526                	mv	a0,s1
    80004c4a:	ffffc097          	auipc	ra,0xffffc
    80004c4e:	07a080e7          	jalr	122(ra) # 80000cc4 <release>
  return i;
}
    80004c52:	854e                	mv	a0,s3
    80004c54:	60a6                	ld	ra,72(sp)
    80004c56:	6406                	ld	s0,64(sp)
    80004c58:	74e2                	ld	s1,56(sp)
    80004c5a:	7942                	ld	s2,48(sp)
    80004c5c:	79a2                	ld	s3,40(sp)
    80004c5e:	7a02                	ld	s4,32(sp)
    80004c60:	6ae2                	ld	s5,24(sp)
    80004c62:	6b42                	ld	s6,16(sp)
    80004c64:	6161                	addi	sp,sp,80
    80004c66:	8082                	ret
      release(&pi->lock);
    80004c68:	8526                	mv	a0,s1
    80004c6a:	ffffc097          	auipc	ra,0xffffc
    80004c6e:	05a080e7          	jalr	90(ra) # 80000cc4 <release>
      return -1;
    80004c72:	59fd                	li	s3,-1
    80004c74:	bff9                	j	80004c52 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c76:	4981                	li	s3,0
    80004c78:	b7d1                	j	80004c3c <piperead+0xae>

0000000080004c7a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c7a:	df010113          	addi	sp,sp,-528
    80004c7e:	20113423          	sd	ra,520(sp)
    80004c82:	20813023          	sd	s0,512(sp)
    80004c86:	ffa6                	sd	s1,504(sp)
    80004c88:	fbca                	sd	s2,496(sp)
    80004c8a:	f7ce                	sd	s3,488(sp)
    80004c8c:	f3d2                	sd	s4,480(sp)
    80004c8e:	efd6                	sd	s5,472(sp)
    80004c90:	ebda                	sd	s6,464(sp)
    80004c92:	e7de                	sd	s7,456(sp)
    80004c94:	e3e2                	sd	s8,448(sp)
    80004c96:	ff66                	sd	s9,440(sp)
    80004c98:	fb6a                	sd	s10,432(sp)
    80004c9a:	f76e                	sd	s11,424(sp)
    80004c9c:	0c00                	addi	s0,sp,528
    80004c9e:	84aa                	mv	s1,a0
    80004ca0:	dea43c23          	sd	a0,-520(s0)
    80004ca4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	e16080e7          	jalr	-490(ra) # 80001abe <myproc>
    80004cb0:	892a                	mv	s2,a0

  begin_op();
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	446080e7          	jalr	1094(ra) # 800040f8 <begin_op>

  if((ip = namei(path)) == 0){
    80004cba:	8526                	mv	a0,s1
    80004cbc:	fffff097          	auipc	ra,0xfffff
    80004cc0:	230080e7          	jalr	560(ra) # 80003eec <namei>
    80004cc4:	c92d                	beqz	a0,80004d36 <exec+0xbc>
    80004cc6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	a70080e7          	jalr	-1424(ra) # 80003738 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cd0:	04000713          	li	a4,64
    80004cd4:	4681                	li	a3,0
    80004cd6:	e4840613          	addi	a2,s0,-440
    80004cda:	4581                	li	a1,0
    80004cdc:	8526                	mv	a0,s1
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	d0e080e7          	jalr	-754(ra) # 800039ec <readi>
    80004ce6:	04000793          	li	a5,64
    80004cea:	00f51a63          	bne	a0,a5,80004cfe <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cee:	e4842703          	lw	a4,-440(s0)
    80004cf2:	464c47b7          	lui	a5,0x464c4
    80004cf6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cfa:	04f70463          	beq	a4,a5,80004d42 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	c9a080e7          	jalr	-870(ra) # 8000399a <iunlockput>
    end_op();
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	470080e7          	jalr	1136(ra) # 80004178 <end_op>
  }
  return -1;
    80004d10:	557d                	li	a0,-1
}
    80004d12:	20813083          	ld	ra,520(sp)
    80004d16:	20013403          	ld	s0,512(sp)
    80004d1a:	74fe                	ld	s1,504(sp)
    80004d1c:	795e                	ld	s2,496(sp)
    80004d1e:	79be                	ld	s3,488(sp)
    80004d20:	7a1e                	ld	s4,480(sp)
    80004d22:	6afe                	ld	s5,472(sp)
    80004d24:	6b5e                	ld	s6,464(sp)
    80004d26:	6bbe                	ld	s7,456(sp)
    80004d28:	6c1e                	ld	s8,448(sp)
    80004d2a:	7cfa                	ld	s9,440(sp)
    80004d2c:	7d5a                	ld	s10,432(sp)
    80004d2e:	7dba                	ld	s11,424(sp)
    80004d30:	21010113          	addi	sp,sp,528
    80004d34:	8082                	ret
    end_op();
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	442080e7          	jalr	1090(ra) # 80004178 <end_op>
    return -1;
    80004d3e:	557d                	li	a0,-1
    80004d40:	bfc9                	j	80004d12 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d42:	854a                	mv	a0,s2
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	e3e080e7          	jalr	-450(ra) # 80001b82 <proc_pagetable>
    80004d4c:	8baa                	mv	s7,a0
    80004d4e:	d945                	beqz	a0,80004cfe <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d50:	e6842983          	lw	s3,-408(s0)
    80004d54:	e8045783          	lhu	a5,-384(s0)
    80004d58:	c7ad                	beqz	a5,80004dc2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d5a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d5c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d5e:	6c85                	lui	s9,0x1
    80004d60:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d64:	def43823          	sd	a5,-528(s0)
    80004d68:	a42d                	j	80004f92 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d6a:	00004517          	auipc	a0,0x4
    80004d6e:	92650513          	addi	a0,a0,-1754 # 80008690 <syscalls+0x290>
    80004d72:	ffffb097          	auipc	ra,0xffffb
    80004d76:	7d6080e7          	jalr	2006(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d7a:	8756                	mv	a4,s5
    80004d7c:	012d86bb          	addw	a3,s11,s2
    80004d80:	4581                	li	a1,0
    80004d82:	8526                	mv	a0,s1
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	c68080e7          	jalr	-920(ra) # 800039ec <readi>
    80004d8c:	2501                	sext.w	a0,a0
    80004d8e:	1aaa9963          	bne	s5,a0,80004f40 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d92:	6785                	lui	a5,0x1
    80004d94:	0127893b          	addw	s2,a5,s2
    80004d98:	77fd                	lui	a5,0xfffff
    80004d9a:	01478a3b          	addw	s4,a5,s4
    80004d9e:	1f897163          	bgeu	s2,s8,80004f80 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004da2:	02091593          	slli	a1,s2,0x20
    80004da6:	9181                	srli	a1,a1,0x20
    80004da8:	95ea                	add	a1,a1,s10
    80004daa:	855e                	mv	a0,s7
    80004dac:	ffffc097          	auipc	ra,0xffffc
    80004db0:	2f2080e7          	jalr	754(ra) # 8000109e <walkaddr>
    80004db4:	862a                	mv	a2,a0
    if(pa == 0)
    80004db6:	d955                	beqz	a0,80004d6a <exec+0xf0>
      n = PGSIZE;
    80004db8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dba:	fd9a70e3          	bgeu	s4,s9,80004d7a <exec+0x100>
      n = sz - i;
    80004dbe:	8ad2                	mv	s5,s4
    80004dc0:	bf6d                	j	80004d7a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dc2:	4901                	li	s2,0
  iunlockput(ip);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	fffff097          	auipc	ra,0xfffff
    80004dca:	bd4080e7          	jalr	-1068(ra) # 8000399a <iunlockput>
  end_op();
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	3aa080e7          	jalr	938(ra) # 80004178 <end_op>
  p = myproc();
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	ce8080e7          	jalr	-792(ra) # 80001abe <myproc>
    80004dde:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004de0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004de4:	6785                	lui	a5,0x1
    80004de6:	17fd                	addi	a5,a5,-1
    80004de8:	993e                	add	s2,s2,a5
    80004dea:	757d                	lui	a0,0xfffff
    80004dec:	00a977b3          	and	a5,s2,a0
    80004df0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df4:	6609                	lui	a2,0x2
    80004df6:	963e                	add	a2,a2,a5
    80004df8:	85be                	mv	a1,a5
    80004dfa:	855e                	mv	a0,s7
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	668080e7          	jalr	1640(ra) # 80001464 <uvmalloc>
    80004e04:	8b2a                	mv	s6,a0
  ip = 0;
    80004e06:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e08:	12050c63          	beqz	a0,80004f40 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e0c:	75f9                	lui	a1,0xffffe
    80004e0e:	95aa                	add	a1,a1,a0
    80004e10:	855e                	mv	a0,s7
    80004e12:	ffffd097          	auipc	ra,0xffffd
    80004e16:	854080e7          	jalr	-1964(ra) # 80001666 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e1a:	7c7d                	lui	s8,0xfffff
    80004e1c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e1e:	e0043783          	ld	a5,-512(s0)
    80004e22:	6388                	ld	a0,0(a5)
    80004e24:	c535                	beqz	a0,80004e90 <exec+0x216>
    80004e26:	e8840993          	addi	s3,s0,-376
    80004e2a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e2e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	064080e7          	jalr	100(ra) # 80000e94 <strlen>
    80004e38:	2505                	addiw	a0,a0,1
    80004e3a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e3e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e42:	13896363          	bltu	s2,s8,80004f68 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e46:	e0043d83          	ld	s11,-512(s0)
    80004e4a:	000dba03          	ld	s4,0(s11)
    80004e4e:	8552                	mv	a0,s4
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	044080e7          	jalr	68(ra) # 80000e94 <strlen>
    80004e58:	0015069b          	addiw	a3,a0,1
    80004e5c:	8652                	mv	a2,s4
    80004e5e:	85ca                	mv	a1,s2
    80004e60:	855e                	mv	a0,s7
    80004e62:	ffffd097          	auipc	ra,0xffffd
    80004e66:	91c080e7          	jalr	-1764(ra) # 8000177e <copyout>
    80004e6a:	10054363          	bltz	a0,80004f70 <exec+0x2f6>
    ustack[argc] = sp;
    80004e6e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e72:	0485                	addi	s1,s1,1
    80004e74:	008d8793          	addi	a5,s11,8
    80004e78:	e0f43023          	sd	a5,-512(s0)
    80004e7c:	008db503          	ld	a0,8(s11)
    80004e80:	c911                	beqz	a0,80004e94 <exec+0x21a>
    if(argc >= MAXARG)
    80004e82:	09a1                	addi	s3,s3,8
    80004e84:	fb3c96e3          	bne	s9,s3,80004e30 <exec+0x1b6>
  sz = sz1;
    80004e88:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e8c:	4481                	li	s1,0
    80004e8e:	a84d                	j	80004f40 <exec+0x2c6>
  sp = sz;
    80004e90:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e92:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e94:	00349793          	slli	a5,s1,0x3
    80004e98:	f9040713          	addi	a4,s0,-112
    80004e9c:	97ba                	add	a5,a5,a4
    80004e9e:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ea2:	00148693          	addi	a3,s1,1
    80004ea6:	068e                	slli	a3,a3,0x3
    80004ea8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eac:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eb0:	01897663          	bgeu	s2,s8,80004ebc <exec+0x242>
  sz = sz1;
    80004eb4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eb8:	4481                	li	s1,0
    80004eba:	a059                	j	80004f40 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ebc:	e8840613          	addi	a2,s0,-376
    80004ec0:	85ca                	mv	a1,s2
    80004ec2:	855e                	mv	a0,s7
    80004ec4:	ffffd097          	auipc	ra,0xffffd
    80004ec8:	8ba080e7          	jalr	-1862(ra) # 8000177e <copyout>
    80004ecc:	0a054663          	bltz	a0,80004f78 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ed0:	058ab783          	ld	a5,88(s5)
    80004ed4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ed8:	df843783          	ld	a5,-520(s0)
    80004edc:	0007c703          	lbu	a4,0(a5)
    80004ee0:	cf11                	beqz	a4,80004efc <exec+0x282>
    80004ee2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ee4:	02f00693          	li	a3,47
    80004ee8:	a029                	j	80004ef2 <exec+0x278>
  for(last=s=path; *s; s++)
    80004eea:	0785                	addi	a5,a5,1
    80004eec:	fff7c703          	lbu	a4,-1(a5)
    80004ef0:	c711                	beqz	a4,80004efc <exec+0x282>
    if(*s == '/')
    80004ef2:	fed71ce3          	bne	a4,a3,80004eea <exec+0x270>
      last = s+1;
    80004ef6:	def43c23          	sd	a5,-520(s0)
    80004efa:	bfc5                	j	80004eea <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004efc:	4641                	li	a2,16
    80004efe:	df843583          	ld	a1,-520(s0)
    80004f02:	158a8513          	addi	a0,s5,344
    80004f06:	ffffc097          	auipc	ra,0xffffc
    80004f0a:	f5c080e7          	jalr	-164(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f0e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f12:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f16:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f1a:	058ab783          	ld	a5,88(s5)
    80004f1e:	e6043703          	ld	a4,-416(s0)
    80004f22:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f24:	058ab783          	ld	a5,88(s5)
    80004f28:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f2c:	85ea                	mv	a1,s10
    80004f2e:	ffffd097          	auipc	ra,0xffffd
    80004f32:	cf0080e7          	jalr	-784(ra) # 80001c1e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f36:	0004851b          	sext.w	a0,s1
    80004f3a:	bbe1                	j	80004d12 <exec+0x98>
    80004f3c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f40:	e0843583          	ld	a1,-504(s0)
    80004f44:	855e                	mv	a0,s7
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	cd8080e7          	jalr	-808(ra) # 80001c1e <proc_freepagetable>
  if(ip){
    80004f4e:	da0498e3          	bnez	s1,80004cfe <exec+0x84>
  return -1;
    80004f52:	557d                	li	a0,-1
    80004f54:	bb7d                	j	80004d12 <exec+0x98>
    80004f56:	e1243423          	sd	s2,-504(s0)
    80004f5a:	b7dd                	j	80004f40 <exec+0x2c6>
    80004f5c:	e1243423          	sd	s2,-504(s0)
    80004f60:	b7c5                	j	80004f40 <exec+0x2c6>
    80004f62:	e1243423          	sd	s2,-504(s0)
    80004f66:	bfe9                	j	80004f40 <exec+0x2c6>
  sz = sz1;
    80004f68:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f6c:	4481                	li	s1,0
    80004f6e:	bfc9                	j	80004f40 <exec+0x2c6>
  sz = sz1;
    80004f70:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f74:	4481                	li	s1,0
    80004f76:	b7e9                	j	80004f40 <exec+0x2c6>
  sz = sz1;
    80004f78:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f7c:	4481                	li	s1,0
    80004f7e:	b7c9                	j	80004f40 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f80:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f84:	2b05                	addiw	s6,s6,1
    80004f86:	0389899b          	addiw	s3,s3,56
    80004f8a:	e8045783          	lhu	a5,-384(s0)
    80004f8e:	e2fb5be3          	bge	s6,a5,80004dc4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f92:	2981                	sext.w	s3,s3
    80004f94:	03800713          	li	a4,56
    80004f98:	86ce                	mv	a3,s3
    80004f9a:	e1040613          	addi	a2,s0,-496
    80004f9e:	4581                	li	a1,0
    80004fa0:	8526                	mv	a0,s1
    80004fa2:	fffff097          	auipc	ra,0xfffff
    80004fa6:	a4a080e7          	jalr	-1462(ra) # 800039ec <readi>
    80004faa:	03800793          	li	a5,56
    80004fae:	f8f517e3          	bne	a0,a5,80004f3c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fb2:	e1042783          	lw	a5,-496(s0)
    80004fb6:	4705                	li	a4,1
    80004fb8:	fce796e3          	bne	a5,a4,80004f84 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fbc:	e3843603          	ld	a2,-456(s0)
    80004fc0:	e3043783          	ld	a5,-464(s0)
    80004fc4:	f8f669e3          	bltu	a2,a5,80004f56 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fc8:	e2043783          	ld	a5,-480(s0)
    80004fcc:	963e                	add	a2,a2,a5
    80004fce:	f8f667e3          	bltu	a2,a5,80004f5c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd2:	85ca                	mv	a1,s2
    80004fd4:	855e                	mv	a0,s7
    80004fd6:	ffffc097          	auipc	ra,0xffffc
    80004fda:	48e080e7          	jalr	1166(ra) # 80001464 <uvmalloc>
    80004fde:	e0a43423          	sd	a0,-504(s0)
    80004fe2:	d141                	beqz	a0,80004f62 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004fe4:	e2043d03          	ld	s10,-480(s0)
    80004fe8:	df043783          	ld	a5,-528(s0)
    80004fec:	00fd77b3          	and	a5,s10,a5
    80004ff0:	fba1                	bnez	a5,80004f40 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ff2:	e1842d83          	lw	s11,-488(s0)
    80004ff6:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ffa:	f80c03e3          	beqz	s8,80004f80 <exec+0x306>
    80004ffe:	8a62                	mv	s4,s8
    80005000:	4901                	li	s2,0
    80005002:	b345                	j	80004da2 <exec+0x128>

0000000080005004 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005004:	7179                	addi	sp,sp,-48
    80005006:	f406                	sd	ra,40(sp)
    80005008:	f022                	sd	s0,32(sp)
    8000500a:	ec26                	sd	s1,24(sp)
    8000500c:	e84a                	sd	s2,16(sp)
    8000500e:	1800                	addi	s0,sp,48
    80005010:	892e                	mv	s2,a1
    80005012:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005014:	fdc40593          	addi	a1,s0,-36
    80005018:	ffffe097          	auipc	ra,0xffffe
    8000501c:	b98080e7          	jalr	-1128(ra) # 80002bb0 <argint>
    80005020:	04054063          	bltz	a0,80005060 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005024:	fdc42703          	lw	a4,-36(s0)
    80005028:	47bd                	li	a5,15
    8000502a:	02e7ed63          	bltu	a5,a4,80005064 <argfd+0x60>
    8000502e:	ffffd097          	auipc	ra,0xffffd
    80005032:	a90080e7          	jalr	-1392(ra) # 80001abe <myproc>
    80005036:	fdc42703          	lw	a4,-36(s0)
    8000503a:	01a70793          	addi	a5,a4,26
    8000503e:	078e                	slli	a5,a5,0x3
    80005040:	953e                	add	a0,a0,a5
    80005042:	611c                	ld	a5,0(a0)
    80005044:	c395                	beqz	a5,80005068 <argfd+0x64>
    return -1;
  if(pfd)
    80005046:	00090463          	beqz	s2,8000504e <argfd+0x4a>
    *pfd = fd;
    8000504a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000504e:	4501                	li	a0,0
  if(pf)
    80005050:	c091                	beqz	s1,80005054 <argfd+0x50>
    *pf = f;
    80005052:	e09c                	sd	a5,0(s1)
}
    80005054:	70a2                	ld	ra,40(sp)
    80005056:	7402                	ld	s0,32(sp)
    80005058:	64e2                	ld	s1,24(sp)
    8000505a:	6942                	ld	s2,16(sp)
    8000505c:	6145                	addi	sp,sp,48
    8000505e:	8082                	ret
    return -1;
    80005060:	557d                	li	a0,-1
    80005062:	bfcd                	j	80005054 <argfd+0x50>
    return -1;
    80005064:	557d                	li	a0,-1
    80005066:	b7fd                	j	80005054 <argfd+0x50>
    80005068:	557d                	li	a0,-1
    8000506a:	b7ed                	j	80005054 <argfd+0x50>

000000008000506c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000506c:	1101                	addi	sp,sp,-32
    8000506e:	ec06                	sd	ra,24(sp)
    80005070:	e822                	sd	s0,16(sp)
    80005072:	e426                	sd	s1,8(sp)
    80005074:	1000                	addi	s0,sp,32
    80005076:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	a46080e7          	jalr	-1466(ra) # 80001abe <myproc>
    80005080:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005082:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005086:	4501                	li	a0,0
    80005088:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000508a:	6398                	ld	a4,0(a5)
    8000508c:	cb19                	beqz	a4,800050a2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000508e:	2505                	addiw	a0,a0,1
    80005090:	07a1                	addi	a5,a5,8
    80005092:	fed51ce3          	bne	a0,a3,8000508a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005096:	557d                	li	a0,-1
}
    80005098:	60e2                	ld	ra,24(sp)
    8000509a:	6442                	ld	s0,16(sp)
    8000509c:	64a2                	ld	s1,8(sp)
    8000509e:	6105                	addi	sp,sp,32
    800050a0:	8082                	ret
      p->ofile[fd] = f;
    800050a2:	01a50793          	addi	a5,a0,26
    800050a6:	078e                	slli	a5,a5,0x3
    800050a8:	963e                	add	a2,a2,a5
    800050aa:	e204                	sd	s1,0(a2)
      return fd;
    800050ac:	b7f5                	j	80005098 <fdalloc+0x2c>

00000000800050ae <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ae:	715d                	addi	sp,sp,-80
    800050b0:	e486                	sd	ra,72(sp)
    800050b2:	e0a2                	sd	s0,64(sp)
    800050b4:	fc26                	sd	s1,56(sp)
    800050b6:	f84a                	sd	s2,48(sp)
    800050b8:	f44e                	sd	s3,40(sp)
    800050ba:	f052                	sd	s4,32(sp)
    800050bc:	ec56                	sd	s5,24(sp)
    800050be:	0880                	addi	s0,sp,80
    800050c0:	89ae                	mv	s3,a1
    800050c2:	8ab2                	mv	s5,a2
    800050c4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050c6:	fb040593          	addi	a1,s0,-80
    800050ca:	fffff097          	auipc	ra,0xfffff
    800050ce:	e40080e7          	jalr	-448(ra) # 80003f0a <nameiparent>
    800050d2:	892a                	mv	s2,a0
    800050d4:	12050f63          	beqz	a0,80005212 <create+0x164>
    return 0;

  ilock(dp);
    800050d8:	ffffe097          	auipc	ra,0xffffe
    800050dc:	660080e7          	jalr	1632(ra) # 80003738 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050e0:	4601                	li	a2,0
    800050e2:	fb040593          	addi	a1,s0,-80
    800050e6:	854a                	mv	a0,s2
    800050e8:	fffff097          	auipc	ra,0xfffff
    800050ec:	b32080e7          	jalr	-1230(ra) # 80003c1a <dirlookup>
    800050f0:	84aa                	mv	s1,a0
    800050f2:	c921                	beqz	a0,80005142 <create+0x94>
    iunlockput(dp);
    800050f4:	854a                	mv	a0,s2
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	8a4080e7          	jalr	-1884(ra) # 8000399a <iunlockput>
    ilock(ip);
    800050fe:	8526                	mv	a0,s1
    80005100:	ffffe097          	auipc	ra,0xffffe
    80005104:	638080e7          	jalr	1592(ra) # 80003738 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005108:	2981                	sext.w	s3,s3
    8000510a:	4789                	li	a5,2
    8000510c:	02f99463          	bne	s3,a5,80005134 <create+0x86>
    80005110:	0444d783          	lhu	a5,68(s1)
    80005114:	37f9                	addiw	a5,a5,-2
    80005116:	17c2                	slli	a5,a5,0x30
    80005118:	93c1                	srli	a5,a5,0x30
    8000511a:	4705                	li	a4,1
    8000511c:	00f76c63          	bltu	a4,a5,80005134 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005120:	8526                	mv	a0,s1
    80005122:	60a6                	ld	ra,72(sp)
    80005124:	6406                	ld	s0,64(sp)
    80005126:	74e2                	ld	s1,56(sp)
    80005128:	7942                	ld	s2,48(sp)
    8000512a:	79a2                	ld	s3,40(sp)
    8000512c:	7a02                	ld	s4,32(sp)
    8000512e:	6ae2                	ld	s5,24(sp)
    80005130:	6161                	addi	sp,sp,80
    80005132:	8082                	ret
    iunlockput(ip);
    80005134:	8526                	mv	a0,s1
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	864080e7          	jalr	-1948(ra) # 8000399a <iunlockput>
    return 0;
    8000513e:	4481                	li	s1,0
    80005140:	b7c5                	j	80005120 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005142:	85ce                	mv	a1,s3
    80005144:	00092503          	lw	a0,0(s2)
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	458080e7          	jalr	1112(ra) # 800035a0 <ialloc>
    80005150:	84aa                	mv	s1,a0
    80005152:	c529                	beqz	a0,8000519c <create+0xee>
  ilock(ip);
    80005154:	ffffe097          	auipc	ra,0xffffe
    80005158:	5e4080e7          	jalr	1508(ra) # 80003738 <ilock>
  ip->major = major;
    8000515c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005160:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005164:	4785                	li	a5,1
    80005166:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000516a:	8526                	mv	a0,s1
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	502080e7          	jalr	1282(ra) # 8000366e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005174:	2981                	sext.w	s3,s3
    80005176:	4785                	li	a5,1
    80005178:	02f98a63          	beq	s3,a5,800051ac <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000517c:	40d0                	lw	a2,4(s1)
    8000517e:	fb040593          	addi	a1,s0,-80
    80005182:	854a                	mv	a0,s2
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	ca6080e7          	jalr	-858(ra) # 80003e2a <dirlink>
    8000518c:	06054b63          	bltz	a0,80005202 <create+0x154>
  iunlockput(dp);
    80005190:	854a                	mv	a0,s2
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	808080e7          	jalr	-2040(ra) # 8000399a <iunlockput>
  return ip;
    8000519a:	b759                	j	80005120 <create+0x72>
    panic("create: ialloc");
    8000519c:	00003517          	auipc	a0,0x3
    800051a0:	51450513          	addi	a0,a0,1300 # 800086b0 <syscalls+0x2b0>
    800051a4:	ffffb097          	auipc	ra,0xffffb
    800051a8:	3a4080e7          	jalr	932(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051ac:	04a95783          	lhu	a5,74(s2)
    800051b0:	2785                	addiw	a5,a5,1
    800051b2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051b6:	854a                	mv	a0,s2
    800051b8:	ffffe097          	auipc	ra,0xffffe
    800051bc:	4b6080e7          	jalr	1206(ra) # 8000366e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c0:	40d0                	lw	a2,4(s1)
    800051c2:	00003597          	auipc	a1,0x3
    800051c6:	4fe58593          	addi	a1,a1,1278 # 800086c0 <syscalls+0x2c0>
    800051ca:	8526                	mv	a0,s1
    800051cc:	fffff097          	auipc	ra,0xfffff
    800051d0:	c5e080e7          	jalr	-930(ra) # 80003e2a <dirlink>
    800051d4:	00054f63          	bltz	a0,800051f2 <create+0x144>
    800051d8:	00492603          	lw	a2,4(s2)
    800051dc:	00003597          	auipc	a1,0x3
    800051e0:	4ec58593          	addi	a1,a1,1260 # 800086c8 <syscalls+0x2c8>
    800051e4:	8526                	mv	a0,s1
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	c44080e7          	jalr	-956(ra) # 80003e2a <dirlink>
    800051ee:	f80557e3          	bgez	a0,8000517c <create+0xce>
      panic("create dots");
    800051f2:	00003517          	auipc	a0,0x3
    800051f6:	4de50513          	addi	a0,a0,1246 # 800086d0 <syscalls+0x2d0>
    800051fa:	ffffb097          	auipc	ra,0xffffb
    800051fe:	34e080e7          	jalr	846(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005202:	00003517          	auipc	a0,0x3
    80005206:	4de50513          	addi	a0,a0,1246 # 800086e0 <syscalls+0x2e0>
    8000520a:	ffffb097          	auipc	ra,0xffffb
    8000520e:	33e080e7          	jalr	830(ra) # 80000548 <panic>
    return 0;
    80005212:	84aa                	mv	s1,a0
    80005214:	b731                	j	80005120 <create+0x72>

0000000080005216 <sys_dup>:
{
    80005216:	7179                	addi	sp,sp,-48
    80005218:	f406                	sd	ra,40(sp)
    8000521a:	f022                	sd	s0,32(sp)
    8000521c:	ec26                	sd	s1,24(sp)
    8000521e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005220:	fd840613          	addi	a2,s0,-40
    80005224:	4581                	li	a1,0
    80005226:	4501                	li	a0,0
    80005228:	00000097          	auipc	ra,0x0
    8000522c:	ddc080e7          	jalr	-548(ra) # 80005004 <argfd>
    return -1;
    80005230:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005232:	02054363          	bltz	a0,80005258 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005236:	fd843503          	ld	a0,-40(s0)
    8000523a:	00000097          	auipc	ra,0x0
    8000523e:	e32080e7          	jalr	-462(ra) # 8000506c <fdalloc>
    80005242:	84aa                	mv	s1,a0
    return -1;
    80005244:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005246:	00054963          	bltz	a0,80005258 <sys_dup+0x42>
  filedup(f);
    8000524a:	fd843503          	ld	a0,-40(s0)
    8000524e:	fffff097          	auipc	ra,0xfffff
    80005252:	32a080e7          	jalr	810(ra) # 80004578 <filedup>
  return fd;
    80005256:	87a6                	mv	a5,s1
}
    80005258:	853e                	mv	a0,a5
    8000525a:	70a2                	ld	ra,40(sp)
    8000525c:	7402                	ld	s0,32(sp)
    8000525e:	64e2                	ld	s1,24(sp)
    80005260:	6145                	addi	sp,sp,48
    80005262:	8082                	ret

0000000080005264 <sys_read>:
{
    80005264:	7179                	addi	sp,sp,-48
    80005266:	f406                	sd	ra,40(sp)
    80005268:	f022                	sd	s0,32(sp)
    8000526a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526c:	fe840613          	addi	a2,s0,-24
    80005270:	4581                	li	a1,0
    80005272:	4501                	li	a0,0
    80005274:	00000097          	auipc	ra,0x0
    80005278:	d90080e7          	jalr	-624(ra) # 80005004 <argfd>
    return -1;
    8000527c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527e:	04054163          	bltz	a0,800052c0 <sys_read+0x5c>
    80005282:	fe440593          	addi	a1,s0,-28
    80005286:	4509                	li	a0,2
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	928080e7          	jalr	-1752(ra) # 80002bb0 <argint>
    return -1;
    80005290:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005292:	02054763          	bltz	a0,800052c0 <sys_read+0x5c>
    80005296:	fd840593          	addi	a1,s0,-40
    8000529a:	4505                	li	a0,1
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	936080e7          	jalr	-1738(ra) # 80002bd2 <argaddr>
    return -1;
    800052a4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a6:	00054d63          	bltz	a0,800052c0 <sys_read+0x5c>
  return fileread(f, p, n);
    800052aa:	fe442603          	lw	a2,-28(s0)
    800052ae:	fd843583          	ld	a1,-40(s0)
    800052b2:	fe843503          	ld	a0,-24(s0)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	44e080e7          	jalr	1102(ra) # 80004704 <fileread>
    800052be:	87aa                	mv	a5,a0
}
    800052c0:	853e                	mv	a0,a5
    800052c2:	70a2                	ld	ra,40(sp)
    800052c4:	7402                	ld	s0,32(sp)
    800052c6:	6145                	addi	sp,sp,48
    800052c8:	8082                	ret

00000000800052ca <sys_write>:
{
    800052ca:	7179                	addi	sp,sp,-48
    800052cc:	f406                	sd	ra,40(sp)
    800052ce:	f022                	sd	s0,32(sp)
    800052d0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	fe840613          	addi	a2,s0,-24
    800052d6:	4581                	li	a1,0
    800052d8:	4501                	li	a0,0
    800052da:	00000097          	auipc	ra,0x0
    800052de:	d2a080e7          	jalr	-726(ra) # 80005004 <argfd>
    return -1;
    800052e2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e4:	04054163          	bltz	a0,80005326 <sys_write+0x5c>
    800052e8:	fe440593          	addi	a1,s0,-28
    800052ec:	4509                	li	a0,2
    800052ee:	ffffe097          	auipc	ra,0xffffe
    800052f2:	8c2080e7          	jalr	-1854(ra) # 80002bb0 <argint>
    return -1;
    800052f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f8:	02054763          	bltz	a0,80005326 <sys_write+0x5c>
    800052fc:	fd840593          	addi	a1,s0,-40
    80005300:	4505                	li	a0,1
    80005302:	ffffe097          	auipc	ra,0xffffe
    80005306:	8d0080e7          	jalr	-1840(ra) # 80002bd2 <argaddr>
    return -1;
    8000530a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530c:	00054d63          	bltz	a0,80005326 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005310:	fe442603          	lw	a2,-28(s0)
    80005314:	fd843583          	ld	a1,-40(s0)
    80005318:	fe843503          	ld	a0,-24(s0)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	4aa080e7          	jalr	1194(ra) # 800047c6 <filewrite>
    80005324:	87aa                	mv	a5,a0
}
    80005326:	853e                	mv	a0,a5
    80005328:	70a2                	ld	ra,40(sp)
    8000532a:	7402                	ld	s0,32(sp)
    8000532c:	6145                	addi	sp,sp,48
    8000532e:	8082                	ret

0000000080005330 <sys_close>:
{
    80005330:	1101                	addi	sp,sp,-32
    80005332:	ec06                	sd	ra,24(sp)
    80005334:	e822                	sd	s0,16(sp)
    80005336:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005338:	fe040613          	addi	a2,s0,-32
    8000533c:	fec40593          	addi	a1,s0,-20
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	cc2080e7          	jalr	-830(ra) # 80005004 <argfd>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000534c:	02054463          	bltz	a0,80005374 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005350:	ffffc097          	auipc	ra,0xffffc
    80005354:	76e080e7          	jalr	1902(ra) # 80001abe <myproc>
    80005358:	fec42783          	lw	a5,-20(s0)
    8000535c:	07e9                	addi	a5,a5,26
    8000535e:	078e                	slli	a5,a5,0x3
    80005360:	97aa                	add	a5,a5,a0
    80005362:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005366:	fe043503          	ld	a0,-32(s0)
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	260080e7          	jalr	608(ra) # 800045ca <fileclose>
  return 0;
    80005372:	4781                	li	a5,0
}
    80005374:	853e                	mv	a0,a5
    80005376:	60e2                	ld	ra,24(sp)
    80005378:	6442                	ld	s0,16(sp)
    8000537a:	6105                	addi	sp,sp,32
    8000537c:	8082                	ret

000000008000537e <sys_fstat>:
{
    8000537e:	1101                	addi	sp,sp,-32
    80005380:	ec06                	sd	ra,24(sp)
    80005382:	e822                	sd	s0,16(sp)
    80005384:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005386:	fe840613          	addi	a2,s0,-24
    8000538a:	4581                	li	a1,0
    8000538c:	4501                	li	a0,0
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	c76080e7          	jalr	-906(ra) # 80005004 <argfd>
    return -1;
    80005396:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005398:	02054563          	bltz	a0,800053c2 <sys_fstat+0x44>
    8000539c:	fe040593          	addi	a1,s0,-32
    800053a0:	4505                	li	a0,1
    800053a2:	ffffe097          	auipc	ra,0xffffe
    800053a6:	830080e7          	jalr	-2000(ra) # 80002bd2 <argaddr>
    return -1;
    800053aa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ac:	00054b63          	bltz	a0,800053c2 <sys_fstat+0x44>
  return filestat(f, st);
    800053b0:	fe043583          	ld	a1,-32(s0)
    800053b4:	fe843503          	ld	a0,-24(s0)
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	2da080e7          	jalr	730(ra) # 80004692 <filestat>
    800053c0:	87aa                	mv	a5,a0
}
    800053c2:	853e                	mv	a0,a5
    800053c4:	60e2                	ld	ra,24(sp)
    800053c6:	6442                	ld	s0,16(sp)
    800053c8:	6105                	addi	sp,sp,32
    800053ca:	8082                	ret

00000000800053cc <sys_link>:
{
    800053cc:	7169                	addi	sp,sp,-304
    800053ce:	f606                	sd	ra,296(sp)
    800053d0:	f222                	sd	s0,288(sp)
    800053d2:	ee26                	sd	s1,280(sp)
    800053d4:	ea4a                	sd	s2,272(sp)
    800053d6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d8:	08000613          	li	a2,128
    800053dc:	ed040593          	addi	a1,s0,-304
    800053e0:	4501                	li	a0,0
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	812080e7          	jalr	-2030(ra) # 80002bf4 <argstr>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ec:	10054e63          	bltz	a0,80005508 <sys_link+0x13c>
    800053f0:	08000613          	li	a2,128
    800053f4:	f5040593          	addi	a1,s0,-176
    800053f8:	4505                	li	a0,1
    800053fa:	ffffd097          	auipc	ra,0xffffd
    800053fe:	7fa080e7          	jalr	2042(ra) # 80002bf4 <argstr>
    return -1;
    80005402:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005404:	10054263          	bltz	a0,80005508 <sys_link+0x13c>
  begin_op();
    80005408:	fffff097          	auipc	ra,0xfffff
    8000540c:	cf0080e7          	jalr	-784(ra) # 800040f8 <begin_op>
  if((ip = namei(old)) == 0){
    80005410:	ed040513          	addi	a0,s0,-304
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	ad8080e7          	jalr	-1320(ra) # 80003eec <namei>
    8000541c:	84aa                	mv	s1,a0
    8000541e:	c551                	beqz	a0,800054aa <sys_link+0xde>
  ilock(ip);
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	318080e7          	jalr	792(ra) # 80003738 <ilock>
  if(ip->type == T_DIR){
    80005428:	04449703          	lh	a4,68(s1)
    8000542c:	4785                	li	a5,1
    8000542e:	08f70463          	beq	a4,a5,800054b6 <sys_link+0xea>
  ip->nlink++;
    80005432:	04a4d783          	lhu	a5,74(s1)
    80005436:	2785                	addiw	a5,a5,1
    80005438:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543c:	8526                	mv	a0,s1
    8000543e:	ffffe097          	auipc	ra,0xffffe
    80005442:	230080e7          	jalr	560(ra) # 8000366e <iupdate>
  iunlock(ip);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	3b2080e7          	jalr	946(ra) # 800037fa <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005450:	fd040593          	addi	a1,s0,-48
    80005454:	f5040513          	addi	a0,s0,-176
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	ab2080e7          	jalr	-1358(ra) # 80003f0a <nameiparent>
    80005460:	892a                	mv	s2,a0
    80005462:	c935                	beqz	a0,800054d6 <sys_link+0x10a>
  ilock(dp);
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	2d4080e7          	jalr	724(ra) # 80003738 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000546c:	00092703          	lw	a4,0(s2)
    80005470:	409c                	lw	a5,0(s1)
    80005472:	04f71d63          	bne	a4,a5,800054cc <sys_link+0x100>
    80005476:	40d0                	lw	a2,4(s1)
    80005478:	fd040593          	addi	a1,s0,-48
    8000547c:	854a                	mv	a0,s2
    8000547e:	fffff097          	auipc	ra,0xfffff
    80005482:	9ac080e7          	jalr	-1620(ra) # 80003e2a <dirlink>
    80005486:	04054363          	bltz	a0,800054cc <sys_link+0x100>
  iunlockput(dp);
    8000548a:	854a                	mv	a0,s2
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	50e080e7          	jalr	1294(ra) # 8000399a <iunlockput>
  iput(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	45c080e7          	jalr	1116(ra) # 800038f2 <iput>
  end_op();
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	cda080e7          	jalr	-806(ra) # 80004178 <end_op>
  return 0;
    800054a6:	4781                	li	a5,0
    800054a8:	a085                	j	80005508 <sys_link+0x13c>
    end_op();
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	cce080e7          	jalr	-818(ra) # 80004178 <end_op>
    return -1;
    800054b2:	57fd                	li	a5,-1
    800054b4:	a891                	j	80005508 <sys_link+0x13c>
    iunlockput(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	4e2080e7          	jalr	1250(ra) # 8000399a <iunlockput>
    end_op();
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	cb8080e7          	jalr	-840(ra) # 80004178 <end_op>
    return -1;
    800054c8:	57fd                	li	a5,-1
    800054ca:	a83d                	j	80005508 <sys_link+0x13c>
    iunlockput(dp);
    800054cc:	854a                	mv	a0,s2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	4cc080e7          	jalr	1228(ra) # 8000399a <iunlockput>
  ilock(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	260080e7          	jalr	608(ra) # 80003738 <ilock>
  ip->nlink--;
    800054e0:	04a4d783          	lhu	a5,74(s1)
    800054e4:	37fd                	addiw	a5,a5,-1
    800054e6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ea:	8526                	mv	a0,s1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	182080e7          	jalr	386(ra) # 8000366e <iupdate>
  iunlockput(ip);
    800054f4:	8526                	mv	a0,s1
    800054f6:	ffffe097          	auipc	ra,0xffffe
    800054fa:	4a4080e7          	jalr	1188(ra) # 8000399a <iunlockput>
  end_op();
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	c7a080e7          	jalr	-902(ra) # 80004178 <end_op>
  return -1;
    80005506:	57fd                	li	a5,-1
}
    80005508:	853e                	mv	a0,a5
    8000550a:	70b2                	ld	ra,296(sp)
    8000550c:	7412                	ld	s0,288(sp)
    8000550e:	64f2                	ld	s1,280(sp)
    80005510:	6952                	ld	s2,272(sp)
    80005512:	6155                	addi	sp,sp,304
    80005514:	8082                	ret

0000000080005516 <sys_unlink>:
{
    80005516:	7151                	addi	sp,sp,-240
    80005518:	f586                	sd	ra,232(sp)
    8000551a:	f1a2                	sd	s0,224(sp)
    8000551c:	eda6                	sd	s1,216(sp)
    8000551e:	e9ca                	sd	s2,208(sp)
    80005520:	e5ce                	sd	s3,200(sp)
    80005522:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005524:	08000613          	li	a2,128
    80005528:	f3040593          	addi	a1,s0,-208
    8000552c:	4501                	li	a0,0
    8000552e:	ffffd097          	auipc	ra,0xffffd
    80005532:	6c6080e7          	jalr	1734(ra) # 80002bf4 <argstr>
    80005536:	18054163          	bltz	a0,800056b8 <sys_unlink+0x1a2>
  begin_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	bbe080e7          	jalr	-1090(ra) # 800040f8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005542:	fb040593          	addi	a1,s0,-80
    80005546:	f3040513          	addi	a0,s0,-208
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	9c0080e7          	jalr	-1600(ra) # 80003f0a <nameiparent>
    80005552:	84aa                	mv	s1,a0
    80005554:	c979                	beqz	a0,8000562a <sys_unlink+0x114>
  ilock(dp);
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	1e2080e7          	jalr	482(ra) # 80003738 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000555e:	00003597          	auipc	a1,0x3
    80005562:	16258593          	addi	a1,a1,354 # 800086c0 <syscalls+0x2c0>
    80005566:	fb040513          	addi	a0,s0,-80
    8000556a:	ffffe097          	auipc	ra,0xffffe
    8000556e:	696080e7          	jalr	1686(ra) # 80003c00 <namecmp>
    80005572:	14050a63          	beqz	a0,800056c6 <sys_unlink+0x1b0>
    80005576:	00003597          	auipc	a1,0x3
    8000557a:	15258593          	addi	a1,a1,338 # 800086c8 <syscalls+0x2c8>
    8000557e:	fb040513          	addi	a0,s0,-80
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	67e080e7          	jalr	1662(ra) # 80003c00 <namecmp>
    8000558a:	12050e63          	beqz	a0,800056c6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000558e:	f2c40613          	addi	a2,s0,-212
    80005592:	fb040593          	addi	a1,s0,-80
    80005596:	8526                	mv	a0,s1
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	682080e7          	jalr	1666(ra) # 80003c1a <dirlookup>
    800055a0:	892a                	mv	s2,a0
    800055a2:	12050263          	beqz	a0,800056c6 <sys_unlink+0x1b0>
  ilock(ip);
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	192080e7          	jalr	402(ra) # 80003738 <ilock>
  if(ip->nlink < 1)
    800055ae:	04a91783          	lh	a5,74(s2)
    800055b2:	08f05263          	blez	a5,80005636 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055b6:	04491703          	lh	a4,68(s2)
    800055ba:	4785                	li	a5,1
    800055bc:	08f70563          	beq	a4,a5,80005646 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055c0:	4641                	li	a2,16
    800055c2:	4581                	li	a1,0
    800055c4:	fc040513          	addi	a0,s0,-64
    800055c8:	ffffb097          	auipc	ra,0xffffb
    800055cc:	744080e7          	jalr	1860(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d0:	4741                	li	a4,16
    800055d2:	f2c42683          	lw	a3,-212(s0)
    800055d6:	fc040613          	addi	a2,s0,-64
    800055da:	4581                	li	a1,0
    800055dc:	8526                	mv	a0,s1
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	506080e7          	jalr	1286(ra) # 80003ae4 <writei>
    800055e6:	47c1                	li	a5,16
    800055e8:	0af51563          	bne	a0,a5,80005692 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ec:	04491703          	lh	a4,68(s2)
    800055f0:	4785                	li	a5,1
    800055f2:	0af70863          	beq	a4,a5,800056a2 <sys_unlink+0x18c>
  iunlockput(dp);
    800055f6:	8526                	mv	a0,s1
    800055f8:	ffffe097          	auipc	ra,0xffffe
    800055fc:	3a2080e7          	jalr	930(ra) # 8000399a <iunlockput>
  ip->nlink--;
    80005600:	04a95783          	lhu	a5,74(s2)
    80005604:	37fd                	addiw	a5,a5,-1
    80005606:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000560a:	854a                	mv	a0,s2
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	062080e7          	jalr	98(ra) # 8000366e <iupdate>
  iunlockput(ip);
    80005614:	854a                	mv	a0,s2
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	384080e7          	jalr	900(ra) # 8000399a <iunlockput>
  end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	b5a080e7          	jalr	-1190(ra) # 80004178 <end_op>
  return 0;
    80005626:	4501                	li	a0,0
    80005628:	a84d                	j	800056da <sys_unlink+0x1c4>
    end_op();
    8000562a:	fffff097          	auipc	ra,0xfffff
    8000562e:	b4e080e7          	jalr	-1202(ra) # 80004178 <end_op>
    return -1;
    80005632:	557d                	li	a0,-1
    80005634:	a05d                	j	800056da <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005636:	00003517          	auipc	a0,0x3
    8000563a:	0ba50513          	addi	a0,a0,186 # 800086f0 <syscalls+0x2f0>
    8000563e:	ffffb097          	auipc	ra,0xffffb
    80005642:	f0a080e7          	jalr	-246(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005646:	04c92703          	lw	a4,76(s2)
    8000564a:	02000793          	li	a5,32
    8000564e:	f6e7f9e3          	bgeu	a5,a4,800055c0 <sys_unlink+0xaa>
    80005652:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005656:	4741                	li	a4,16
    80005658:	86ce                	mv	a3,s3
    8000565a:	f1840613          	addi	a2,s0,-232
    8000565e:	4581                	li	a1,0
    80005660:	854a                	mv	a0,s2
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	38a080e7          	jalr	906(ra) # 800039ec <readi>
    8000566a:	47c1                	li	a5,16
    8000566c:	00f51b63          	bne	a0,a5,80005682 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005670:	f1845783          	lhu	a5,-232(s0)
    80005674:	e7a1                	bnez	a5,800056bc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005676:	29c1                	addiw	s3,s3,16
    80005678:	04c92783          	lw	a5,76(s2)
    8000567c:	fcf9ede3          	bltu	s3,a5,80005656 <sys_unlink+0x140>
    80005680:	b781                	j	800055c0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005682:	00003517          	auipc	a0,0x3
    80005686:	08650513          	addi	a0,a0,134 # 80008708 <syscalls+0x308>
    8000568a:	ffffb097          	auipc	ra,0xffffb
    8000568e:	ebe080e7          	jalr	-322(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005692:	00003517          	auipc	a0,0x3
    80005696:	08e50513          	addi	a0,a0,142 # 80008720 <syscalls+0x320>
    8000569a:	ffffb097          	auipc	ra,0xffffb
    8000569e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
    dp->nlink--;
    800056a2:	04a4d783          	lhu	a5,74(s1)
    800056a6:	37fd                	addiw	a5,a5,-1
    800056a8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ac:	8526                	mv	a0,s1
    800056ae:	ffffe097          	auipc	ra,0xffffe
    800056b2:	fc0080e7          	jalr	-64(ra) # 8000366e <iupdate>
    800056b6:	b781                	j	800055f6 <sys_unlink+0xe0>
    return -1;
    800056b8:	557d                	li	a0,-1
    800056ba:	a005                	j	800056da <sys_unlink+0x1c4>
    iunlockput(ip);
    800056bc:	854a                	mv	a0,s2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	2dc080e7          	jalr	732(ra) # 8000399a <iunlockput>
  iunlockput(dp);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	2d2080e7          	jalr	722(ra) # 8000399a <iunlockput>
  end_op();
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	aa8080e7          	jalr	-1368(ra) # 80004178 <end_op>
  return -1;
    800056d8:	557d                	li	a0,-1
}
    800056da:	70ae                	ld	ra,232(sp)
    800056dc:	740e                	ld	s0,224(sp)
    800056de:	64ee                	ld	s1,216(sp)
    800056e0:	694e                	ld	s2,208(sp)
    800056e2:	69ae                	ld	s3,200(sp)
    800056e4:	616d                	addi	sp,sp,240
    800056e6:	8082                	ret

00000000800056e8 <sys_open>:

uint64
sys_open(void)
{
    800056e8:	7131                	addi	sp,sp,-192
    800056ea:	fd06                	sd	ra,184(sp)
    800056ec:	f922                	sd	s0,176(sp)
    800056ee:	f526                	sd	s1,168(sp)
    800056f0:	f14a                	sd	s2,160(sp)
    800056f2:	ed4e                	sd	s3,152(sp)
    800056f4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f6:	08000613          	li	a2,128
    800056fa:	f5040593          	addi	a1,s0,-176
    800056fe:	4501                	li	a0,0
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	4f4080e7          	jalr	1268(ra) # 80002bf4 <argstr>
    return -1;
    80005708:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570a:	0c054163          	bltz	a0,800057cc <sys_open+0xe4>
    8000570e:	f4c40593          	addi	a1,s0,-180
    80005712:	4505                	li	a0,1
    80005714:	ffffd097          	auipc	ra,0xffffd
    80005718:	49c080e7          	jalr	1180(ra) # 80002bb0 <argint>
    8000571c:	0a054863          	bltz	a0,800057cc <sys_open+0xe4>

  begin_op();
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	9d8080e7          	jalr	-1576(ra) # 800040f8 <begin_op>

  if(omode & O_CREATE){
    80005728:	f4c42783          	lw	a5,-180(s0)
    8000572c:	2007f793          	andi	a5,a5,512
    80005730:	cbdd                	beqz	a5,800057e6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005732:	4681                	li	a3,0
    80005734:	4601                	li	a2,0
    80005736:	4589                	li	a1,2
    80005738:	f5040513          	addi	a0,s0,-176
    8000573c:	00000097          	auipc	ra,0x0
    80005740:	972080e7          	jalr	-1678(ra) # 800050ae <create>
    80005744:	892a                	mv	s2,a0
    if(ip == 0){
    80005746:	c959                	beqz	a0,800057dc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005748:	04491703          	lh	a4,68(s2)
    8000574c:	478d                	li	a5,3
    8000574e:	00f71763          	bne	a4,a5,8000575c <sys_open+0x74>
    80005752:	04695703          	lhu	a4,70(s2)
    80005756:	47a5                	li	a5,9
    80005758:	0ce7ec63          	bltu	a5,a4,80005830 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	db2080e7          	jalr	-590(ra) # 8000450e <filealloc>
    80005764:	89aa                	mv	s3,a0
    80005766:	10050263          	beqz	a0,8000586a <sys_open+0x182>
    8000576a:	00000097          	auipc	ra,0x0
    8000576e:	902080e7          	jalr	-1790(ra) # 8000506c <fdalloc>
    80005772:	84aa                	mv	s1,a0
    80005774:	0e054663          	bltz	a0,80005860 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005778:	04491703          	lh	a4,68(s2)
    8000577c:	478d                	li	a5,3
    8000577e:	0cf70463          	beq	a4,a5,80005846 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005782:	4789                	li	a5,2
    80005784:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005788:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000578c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005790:	f4c42783          	lw	a5,-180(s0)
    80005794:	0017c713          	xori	a4,a5,1
    80005798:	8b05                	andi	a4,a4,1
    8000579a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000579e:	0037f713          	andi	a4,a5,3
    800057a2:	00e03733          	snez	a4,a4
    800057a6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057aa:	4007f793          	andi	a5,a5,1024
    800057ae:	c791                	beqz	a5,800057ba <sys_open+0xd2>
    800057b0:	04491703          	lh	a4,68(s2)
    800057b4:	4789                	li	a5,2
    800057b6:	08f70f63          	beq	a4,a5,80005854 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057ba:	854a                	mv	a0,s2
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	03e080e7          	jalr	62(ra) # 800037fa <iunlock>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	9b4080e7          	jalr	-1612(ra) # 80004178 <end_op>

  return fd;
}
    800057cc:	8526                	mv	a0,s1
    800057ce:	70ea                	ld	ra,184(sp)
    800057d0:	744a                	ld	s0,176(sp)
    800057d2:	74aa                	ld	s1,168(sp)
    800057d4:	790a                	ld	s2,160(sp)
    800057d6:	69ea                	ld	s3,152(sp)
    800057d8:	6129                	addi	sp,sp,192
    800057da:	8082                	ret
      end_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	99c080e7          	jalr	-1636(ra) # 80004178 <end_op>
      return -1;
    800057e4:	b7e5                	j	800057cc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057e6:	f5040513          	addi	a0,s0,-176
    800057ea:	ffffe097          	auipc	ra,0xffffe
    800057ee:	702080e7          	jalr	1794(ra) # 80003eec <namei>
    800057f2:	892a                	mv	s2,a0
    800057f4:	c905                	beqz	a0,80005824 <sys_open+0x13c>
    ilock(ip);
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	f42080e7          	jalr	-190(ra) # 80003738 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	4785                	li	a5,1
    80005804:	f4f712e3          	bne	a4,a5,80005748 <sys_open+0x60>
    80005808:	f4c42783          	lw	a5,-180(s0)
    8000580c:	dba1                	beqz	a5,8000575c <sys_open+0x74>
      iunlockput(ip);
    8000580e:	854a                	mv	a0,s2
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	18a080e7          	jalr	394(ra) # 8000399a <iunlockput>
      end_op();
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	960080e7          	jalr	-1696(ra) # 80004178 <end_op>
      return -1;
    80005820:	54fd                	li	s1,-1
    80005822:	b76d                	j	800057cc <sys_open+0xe4>
      end_op();
    80005824:	fffff097          	auipc	ra,0xfffff
    80005828:	954080e7          	jalr	-1708(ra) # 80004178 <end_op>
      return -1;
    8000582c:	54fd                	li	s1,-1
    8000582e:	bf79                	j	800057cc <sys_open+0xe4>
    iunlockput(ip);
    80005830:	854a                	mv	a0,s2
    80005832:	ffffe097          	auipc	ra,0xffffe
    80005836:	168080e7          	jalr	360(ra) # 8000399a <iunlockput>
    end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	93e080e7          	jalr	-1730(ra) # 80004178 <end_op>
    return -1;
    80005842:	54fd                	li	s1,-1
    80005844:	b761                	j	800057cc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005846:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000584a:	04691783          	lh	a5,70(s2)
    8000584e:	02f99223          	sh	a5,36(s3)
    80005852:	bf2d                	j	8000578c <sys_open+0xa4>
    itrunc(ip);
    80005854:	854a                	mv	a0,s2
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	ff0080e7          	jalr	-16(ra) # 80003846 <itrunc>
    8000585e:	bfb1                	j	800057ba <sys_open+0xd2>
      fileclose(f);
    80005860:	854e                	mv	a0,s3
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	d68080e7          	jalr	-664(ra) # 800045ca <fileclose>
    iunlockput(ip);
    8000586a:	854a                	mv	a0,s2
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	12e080e7          	jalr	302(ra) # 8000399a <iunlockput>
    end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	904080e7          	jalr	-1788(ra) # 80004178 <end_op>
    return -1;
    8000587c:	54fd                	li	s1,-1
    8000587e:	b7b9                	j	800057cc <sys_open+0xe4>

0000000080005880 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005880:	7175                	addi	sp,sp,-144
    80005882:	e506                	sd	ra,136(sp)
    80005884:	e122                	sd	s0,128(sp)
    80005886:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	870080e7          	jalr	-1936(ra) # 800040f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005890:	08000613          	li	a2,128
    80005894:	f7040593          	addi	a1,s0,-144
    80005898:	4501                	li	a0,0
    8000589a:	ffffd097          	auipc	ra,0xffffd
    8000589e:	35a080e7          	jalr	858(ra) # 80002bf4 <argstr>
    800058a2:	02054963          	bltz	a0,800058d4 <sys_mkdir+0x54>
    800058a6:	4681                	li	a3,0
    800058a8:	4601                	li	a2,0
    800058aa:	4585                	li	a1,1
    800058ac:	f7040513          	addi	a0,s0,-144
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	7fe080e7          	jalr	2046(ra) # 800050ae <create>
    800058b8:	cd11                	beqz	a0,800058d4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	0e0080e7          	jalr	224(ra) # 8000399a <iunlockput>
  end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	8b6080e7          	jalr	-1866(ra) # 80004178 <end_op>
  return 0;
    800058ca:	4501                	li	a0,0
}
    800058cc:	60aa                	ld	ra,136(sp)
    800058ce:	640a                	ld	s0,128(sp)
    800058d0:	6149                	addi	sp,sp,144
    800058d2:	8082                	ret
    end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	8a4080e7          	jalr	-1884(ra) # 80004178 <end_op>
    return -1;
    800058dc:	557d                	li	a0,-1
    800058de:	b7fd                	j	800058cc <sys_mkdir+0x4c>

00000000800058e0 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058e0:	7135                	addi	sp,sp,-160
    800058e2:	ed06                	sd	ra,152(sp)
    800058e4:	e922                	sd	s0,144(sp)
    800058e6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	810080e7          	jalr	-2032(ra) # 800040f8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f0:	08000613          	li	a2,128
    800058f4:	f7040593          	addi	a1,s0,-144
    800058f8:	4501                	li	a0,0
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	2fa080e7          	jalr	762(ra) # 80002bf4 <argstr>
    80005902:	04054a63          	bltz	a0,80005956 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005906:	f6c40593          	addi	a1,s0,-148
    8000590a:	4505                	li	a0,1
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	2a4080e7          	jalr	676(ra) # 80002bb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005914:	04054163          	bltz	a0,80005956 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005918:	f6840593          	addi	a1,s0,-152
    8000591c:	4509                	li	a0,2
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	292080e7          	jalr	658(ra) # 80002bb0 <argint>
     argint(1, &major) < 0 ||
    80005926:	02054863          	bltz	a0,80005956 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000592a:	f6841683          	lh	a3,-152(s0)
    8000592e:	f6c41603          	lh	a2,-148(s0)
    80005932:	458d                	li	a1,3
    80005934:	f7040513          	addi	a0,s0,-144
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	776080e7          	jalr	1910(ra) # 800050ae <create>
     argint(2, &minor) < 0 ||
    80005940:	c919                	beqz	a0,80005956 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	058080e7          	jalr	88(ra) # 8000399a <iunlockput>
  end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	82e080e7          	jalr	-2002(ra) # 80004178 <end_op>
  return 0;
    80005952:	4501                	li	a0,0
    80005954:	a031                	j	80005960 <sys_mknod+0x80>
    end_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	822080e7          	jalr	-2014(ra) # 80004178 <end_op>
    return -1;
    8000595e:	557d                	li	a0,-1
}
    80005960:	60ea                	ld	ra,152(sp)
    80005962:	644a                	ld	s0,144(sp)
    80005964:	610d                	addi	sp,sp,160
    80005966:	8082                	ret

0000000080005968 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005968:	7135                	addi	sp,sp,-160
    8000596a:	ed06                	sd	ra,152(sp)
    8000596c:	e922                	sd	s0,144(sp)
    8000596e:	e526                	sd	s1,136(sp)
    80005970:	e14a                	sd	s2,128(sp)
    80005972:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005974:	ffffc097          	auipc	ra,0xffffc
    80005978:	14a080e7          	jalr	330(ra) # 80001abe <myproc>
    8000597c:	892a                	mv	s2,a0
  
  begin_op();
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	77a080e7          	jalr	1914(ra) # 800040f8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005986:	08000613          	li	a2,128
    8000598a:	f6040593          	addi	a1,s0,-160
    8000598e:	4501                	li	a0,0
    80005990:	ffffd097          	auipc	ra,0xffffd
    80005994:	264080e7          	jalr	612(ra) # 80002bf4 <argstr>
    80005998:	04054b63          	bltz	a0,800059ee <sys_chdir+0x86>
    8000599c:	f6040513          	addi	a0,s0,-160
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	54c080e7          	jalr	1356(ra) # 80003eec <namei>
    800059a8:	84aa                	mv	s1,a0
    800059aa:	c131                	beqz	a0,800059ee <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	d8c080e7          	jalr	-628(ra) # 80003738 <ilock>
  if(ip->type != T_DIR){
    800059b4:	04449703          	lh	a4,68(s1)
    800059b8:	4785                	li	a5,1
    800059ba:	04f71063          	bne	a4,a5,800059fa <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059be:	8526                	mv	a0,s1
    800059c0:	ffffe097          	auipc	ra,0xffffe
    800059c4:	e3a080e7          	jalr	-454(ra) # 800037fa <iunlock>
  iput(p->cwd);
    800059c8:	15093503          	ld	a0,336(s2)
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	f26080e7          	jalr	-218(ra) # 800038f2 <iput>
  end_op();
    800059d4:	ffffe097          	auipc	ra,0xffffe
    800059d8:	7a4080e7          	jalr	1956(ra) # 80004178 <end_op>
  p->cwd = ip;
    800059dc:	14993823          	sd	s1,336(s2)
  return 0;
    800059e0:	4501                	li	a0,0
}
    800059e2:	60ea                	ld	ra,152(sp)
    800059e4:	644a                	ld	s0,144(sp)
    800059e6:	64aa                	ld	s1,136(sp)
    800059e8:	690a                	ld	s2,128(sp)
    800059ea:	610d                	addi	sp,sp,160
    800059ec:	8082                	ret
    end_op();
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	78a080e7          	jalr	1930(ra) # 80004178 <end_op>
    return -1;
    800059f6:	557d                	li	a0,-1
    800059f8:	b7ed                	j	800059e2 <sys_chdir+0x7a>
    iunlockput(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	f9e080e7          	jalr	-98(ra) # 8000399a <iunlockput>
    end_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	774080e7          	jalr	1908(ra) # 80004178 <end_op>
    return -1;
    80005a0c:	557d                	li	a0,-1
    80005a0e:	bfd1                	j	800059e2 <sys_chdir+0x7a>

0000000080005a10 <sys_exec>:

uint64
sys_exec(void)
{
    80005a10:	7145                	addi	sp,sp,-464
    80005a12:	e786                	sd	ra,456(sp)
    80005a14:	e3a2                	sd	s0,448(sp)
    80005a16:	ff26                	sd	s1,440(sp)
    80005a18:	fb4a                	sd	s2,432(sp)
    80005a1a:	f74e                	sd	s3,424(sp)
    80005a1c:	f352                	sd	s4,416(sp)
    80005a1e:	ef56                	sd	s5,408(sp)
    80005a20:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a22:	08000613          	li	a2,128
    80005a26:	f4040593          	addi	a1,s0,-192
    80005a2a:	4501                	li	a0,0
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	1c8080e7          	jalr	456(ra) # 80002bf4 <argstr>
    return -1;
    80005a34:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a36:	0c054a63          	bltz	a0,80005b0a <sys_exec+0xfa>
    80005a3a:	e3840593          	addi	a1,s0,-456
    80005a3e:	4505                	li	a0,1
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	192080e7          	jalr	402(ra) # 80002bd2 <argaddr>
    80005a48:	0c054163          	bltz	a0,80005b0a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a4c:	10000613          	li	a2,256
    80005a50:	4581                	li	a1,0
    80005a52:	e4040513          	addi	a0,s0,-448
    80005a56:	ffffb097          	auipc	ra,0xffffb
    80005a5a:	2b6080e7          	jalr	694(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a5e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a62:	89a6                	mv	s3,s1
    80005a64:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a66:	02000a13          	li	s4,32
    80005a6a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a6e:	00391513          	slli	a0,s2,0x3
    80005a72:	e3040593          	addi	a1,s0,-464
    80005a76:	e3843783          	ld	a5,-456(s0)
    80005a7a:	953e                	add	a0,a0,a5
    80005a7c:	ffffd097          	auipc	ra,0xffffd
    80005a80:	09a080e7          	jalr	154(ra) # 80002b16 <fetchaddr>
    80005a84:	02054a63          	bltz	a0,80005ab8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a88:	e3043783          	ld	a5,-464(s0)
    80005a8c:	c3b9                	beqz	a5,80005ad2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	092080e7          	jalr	146(ra) # 80000b20 <kalloc>
    80005a96:	85aa                	mv	a1,a0
    80005a98:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a9c:	cd11                	beqz	a0,80005ab8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005a9e:	6605                	lui	a2,0x1
    80005aa0:	e3043503          	ld	a0,-464(s0)
    80005aa4:	ffffd097          	auipc	ra,0xffffd
    80005aa8:	0c4080e7          	jalr	196(ra) # 80002b68 <fetchstr>
    80005aac:	00054663          	bltz	a0,80005ab8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ab0:	0905                	addi	s2,s2,1
    80005ab2:	09a1                	addi	s3,s3,8
    80005ab4:	fb491be3          	bne	s2,s4,80005a6a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ab8:	10048913          	addi	s2,s1,256
    80005abc:	6088                	ld	a0,0(s1)
    80005abe:	c529                	beqz	a0,80005b08 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ac0:	ffffb097          	auipc	ra,0xffffb
    80005ac4:	f64080e7          	jalr	-156(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ac8:	04a1                	addi	s1,s1,8
    80005aca:	ff2499e3          	bne	s1,s2,80005abc <sys_exec+0xac>
  return -1;
    80005ace:	597d                	li	s2,-1
    80005ad0:	a82d                	j	80005b0a <sys_exec+0xfa>
      argv[i] = 0;
    80005ad2:	0a8e                	slli	s5,s5,0x3
    80005ad4:	fc040793          	addi	a5,s0,-64
    80005ad8:	9abe                	add	s5,s5,a5
    80005ada:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ade:	e4040593          	addi	a1,s0,-448
    80005ae2:	f4040513          	addi	a0,s0,-192
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	194080e7          	jalr	404(ra) # 80004c7a <exec>
    80005aee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af0:	10048993          	addi	s3,s1,256
    80005af4:	6088                	ld	a0,0(s1)
    80005af6:	c911                	beqz	a0,80005b0a <sys_exec+0xfa>
    kfree(argv[i]);
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	f2c080e7          	jalr	-212(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b00:	04a1                	addi	s1,s1,8
    80005b02:	ff3499e3          	bne	s1,s3,80005af4 <sys_exec+0xe4>
    80005b06:	a011                	j	80005b0a <sys_exec+0xfa>
  return -1;
    80005b08:	597d                	li	s2,-1
}
    80005b0a:	854a                	mv	a0,s2
    80005b0c:	60be                	ld	ra,456(sp)
    80005b0e:	641e                	ld	s0,448(sp)
    80005b10:	74fa                	ld	s1,440(sp)
    80005b12:	795a                	ld	s2,432(sp)
    80005b14:	79ba                	ld	s3,424(sp)
    80005b16:	7a1a                	ld	s4,416(sp)
    80005b18:	6afa                	ld	s5,408(sp)
    80005b1a:	6179                	addi	sp,sp,464
    80005b1c:	8082                	ret

0000000080005b1e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b1e:	7139                	addi	sp,sp,-64
    80005b20:	fc06                	sd	ra,56(sp)
    80005b22:	f822                	sd	s0,48(sp)
    80005b24:	f426                	sd	s1,40(sp)
    80005b26:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b28:	ffffc097          	auipc	ra,0xffffc
    80005b2c:	f96080e7          	jalr	-106(ra) # 80001abe <myproc>
    80005b30:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b32:	fd840593          	addi	a1,s0,-40
    80005b36:	4501                	li	a0,0
    80005b38:	ffffd097          	auipc	ra,0xffffd
    80005b3c:	09a080e7          	jalr	154(ra) # 80002bd2 <argaddr>
    return -1;
    80005b40:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b42:	0e054063          	bltz	a0,80005c22 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b46:	fc840593          	addi	a1,s0,-56
    80005b4a:	fd040513          	addi	a0,s0,-48
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	dd2080e7          	jalr	-558(ra) # 80004920 <pipealloc>
    return -1;
    80005b56:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b58:	0c054563          	bltz	a0,80005c22 <sys_pipe+0x104>
  fd0 = -1;
    80005b5c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b60:	fd043503          	ld	a0,-48(s0)
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	508080e7          	jalr	1288(ra) # 8000506c <fdalloc>
    80005b6c:	fca42223          	sw	a0,-60(s0)
    80005b70:	08054c63          	bltz	a0,80005c08 <sys_pipe+0xea>
    80005b74:	fc843503          	ld	a0,-56(s0)
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	4f4080e7          	jalr	1268(ra) # 8000506c <fdalloc>
    80005b80:	fca42023          	sw	a0,-64(s0)
    80005b84:	06054863          	bltz	a0,80005bf4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b88:	4691                	li	a3,4
    80005b8a:	fc440613          	addi	a2,s0,-60
    80005b8e:	fd843583          	ld	a1,-40(s0)
    80005b92:	68a8                	ld	a0,80(s1)
    80005b94:	ffffc097          	auipc	ra,0xffffc
    80005b98:	bea080e7          	jalr	-1046(ra) # 8000177e <copyout>
    80005b9c:	02054063          	bltz	a0,80005bbc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba0:	4691                	li	a3,4
    80005ba2:	fc040613          	addi	a2,s0,-64
    80005ba6:	fd843583          	ld	a1,-40(s0)
    80005baa:	0591                	addi	a1,a1,4
    80005bac:	68a8                	ld	a0,80(s1)
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	bd0080e7          	jalr	-1072(ra) # 8000177e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb8:	06055563          	bgez	a0,80005c22 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bbc:	fc442783          	lw	a5,-60(s0)
    80005bc0:	07e9                	addi	a5,a5,26
    80005bc2:	078e                	slli	a5,a5,0x3
    80005bc4:	97a6                	add	a5,a5,s1
    80005bc6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bca:	fc042503          	lw	a0,-64(s0)
    80005bce:	0569                	addi	a0,a0,26
    80005bd0:	050e                	slli	a0,a0,0x3
    80005bd2:	9526                	add	a0,a0,s1
    80005bd4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bd8:	fd043503          	ld	a0,-48(s0)
    80005bdc:	fffff097          	auipc	ra,0xfffff
    80005be0:	9ee080e7          	jalr	-1554(ra) # 800045ca <fileclose>
    fileclose(wf);
    80005be4:	fc843503          	ld	a0,-56(s0)
    80005be8:	fffff097          	auipc	ra,0xfffff
    80005bec:	9e2080e7          	jalr	-1566(ra) # 800045ca <fileclose>
    return -1;
    80005bf0:	57fd                	li	a5,-1
    80005bf2:	a805                	j	80005c22 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bf4:	fc442783          	lw	a5,-60(s0)
    80005bf8:	0007c863          	bltz	a5,80005c08 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bfc:	01a78513          	addi	a0,a5,26
    80005c00:	050e                	slli	a0,a0,0x3
    80005c02:	9526                	add	a0,a0,s1
    80005c04:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c08:	fd043503          	ld	a0,-48(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	9be080e7          	jalr	-1602(ra) # 800045ca <fileclose>
    fileclose(wf);
    80005c14:	fc843503          	ld	a0,-56(s0)
    80005c18:	fffff097          	auipc	ra,0xfffff
    80005c1c:	9b2080e7          	jalr	-1614(ra) # 800045ca <fileclose>
    return -1;
    80005c20:	57fd                	li	a5,-1
}
    80005c22:	853e                	mv	a0,a5
    80005c24:	70e2                	ld	ra,56(sp)
    80005c26:	7442                	ld	s0,48(sp)
    80005c28:	74a2                	ld	s1,40(sp)
    80005c2a:	6121                	addi	sp,sp,64
    80005c2c:	8082                	ret
	...

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	d73fc0ef          	jal	ra,800029e2 <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	710c                	ld	a1,32(a0)
    80005ccc:	7510                	ld	a2,40(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	d8a080e7          	jalr	-630(ra) # 80001a92 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	00052023          	sw	zero,0(a0)
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	d52080e7          	jalr	-686(ra) # 80001a92 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5179b          	slliw	a5,a0,0xd
    80005d4c:	0c201537          	lui	a0,0xc201
    80005d50:	953e                	add	a0,a0,a5
  return irq;
}
    80005d52:	4148                	lw	a0,4(a0)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	d2a080e7          	jalr	-726(ra) # 80001a92 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	04a7cc63          	blt	a5,a0,80005de8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	26c78793          	addi	a5,a5,620 # 80023000 <disk>
    80005d9c:	00a78733          	add	a4,a5,a0
    80005da0:	6789                	lui	a5,0x2
    80005da2:	97ba                	add	a5,a5,a4
    80005da4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005da8:	eba1                	bnez	a5,80005df8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005daa:	00451713          	slli	a4,a0,0x4
    80005dae:	0001f797          	auipc	a5,0x1f
    80005db2:	2527b783          	ld	a5,594(a5) # 80025000 <disk+0x2000>
    80005db6:	97ba                	add	a5,a5,a4
    80005db8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dbc:	0001d797          	auipc	a5,0x1d
    80005dc0:	24478793          	addi	a5,a5,580 # 80023000 <disk>
    80005dc4:	97aa                	add	a5,a5,a0
    80005dc6:	6509                	lui	a0,0x2
    80005dc8:	953e                	add	a0,a0,a5
    80005dca:	4785                	li	a5,1
    80005dcc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dd0:	0001f517          	auipc	a0,0x1f
    80005dd4:	24850513          	addi	a0,a0,584 # 80025018 <disk+0x2018>
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	67c080e7          	jalr	1660(ra) # 80002454 <wakeup>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	94850513          	addi	a0,a0,-1720 # 80008730 <syscalls+0x330>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	758080e7          	jalr	1880(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005df8:	00003517          	auipc	a0,0x3
    80005dfc:	95050513          	addi	a0,a0,-1712 # 80008748 <syscalls+0x348>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	748080e7          	jalr	1864(ra) # 80000548 <panic>

0000000080005e08 <virtio_disk_init>:
{
    80005e08:	1101                	addi	sp,sp,-32
    80005e0a:	ec06                	sd	ra,24(sp)
    80005e0c:	e822                	sd	s0,16(sp)
    80005e0e:	e426                	sd	s1,8(sp)
    80005e10:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e12:	00003597          	auipc	a1,0x3
    80005e16:	94e58593          	addi	a1,a1,-1714 # 80008760 <syscalls+0x360>
    80005e1a:	0001f517          	auipc	a0,0x1f
    80005e1e:	28e50513          	addi	a0,a0,654 # 800250a8 <disk+0x20a8>
    80005e22:	ffffb097          	auipc	ra,0xffffb
    80005e26:	d5e080e7          	jalr	-674(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e2a:	100017b7          	lui	a5,0x10001
    80005e2e:	4398                	lw	a4,0(a5)
    80005e30:	2701                	sext.w	a4,a4
    80005e32:	747277b7          	lui	a5,0x74727
    80005e36:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e3a:	0ef71163          	bne	a4,a5,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	43dc                	lw	a5,4(a5)
    80005e44:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e46:	4705                	li	a4,1
    80005e48:	0ce79a63          	bne	a5,a4,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4c:	100017b7          	lui	a5,0x10001
    80005e50:	479c                	lw	a5,8(a5)
    80005e52:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e54:	4709                	li	a4,2
    80005e56:	0ce79363          	bne	a5,a4,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	47d8                	lw	a4,12(a5)
    80005e60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e62:	554d47b7          	lui	a5,0x554d4
    80005e66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e6a:	0af71963          	bne	a4,a5,80005f1c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	4705                	li	a4,1
    80005e74:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e76:	470d                	li	a4,3
    80005e78:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e7a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e7c:	c7ffe737          	lui	a4,0xc7ffe
    80005e80:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e84:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e86:	2701                	sext.w	a4,a4
    80005e88:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8a:	472d                	li	a4,11
    80005e8c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	473d                	li	a4,15
    80005e90:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e92:	6705                	lui	a4,0x1
    80005e94:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e96:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e9a:	5bdc                	lw	a5,52(a5)
    80005e9c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e9e:	c7d9                	beqz	a5,80005f2c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ea0:	471d                	li	a4,7
    80005ea2:	08f77d63          	bgeu	a4,a5,80005f3c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ea6:	100014b7          	lui	s1,0x10001
    80005eaa:	47a1                	li	a5,8
    80005eac:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eae:	6609                	lui	a2,0x2
    80005eb0:	4581                	li	a1,0
    80005eb2:	0001d517          	auipc	a0,0x1d
    80005eb6:	14e50513          	addi	a0,a0,334 # 80023000 <disk>
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	e52080e7          	jalr	-430(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ec2:	0001d717          	auipc	a4,0x1d
    80005ec6:	13e70713          	addi	a4,a4,318 # 80023000 <disk>
    80005eca:	00c75793          	srli	a5,a4,0xc
    80005ece:	2781                	sext.w	a5,a5
    80005ed0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ed2:	0001f797          	auipc	a5,0x1f
    80005ed6:	12e78793          	addi	a5,a5,302 # 80025000 <disk+0x2000>
    80005eda:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005edc:	0001d717          	auipc	a4,0x1d
    80005ee0:	1a470713          	addi	a4,a4,420 # 80023080 <disk+0x80>
    80005ee4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ee6:	0001e717          	auipc	a4,0x1e
    80005eea:	11a70713          	addi	a4,a4,282 # 80024000 <disk+0x1000>
    80005eee:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ef0:	4705                	li	a4,1
    80005ef2:	00e78c23          	sb	a4,24(a5)
    80005ef6:	00e78ca3          	sb	a4,25(a5)
    80005efa:	00e78d23          	sb	a4,26(a5)
    80005efe:	00e78da3          	sb	a4,27(a5)
    80005f02:	00e78e23          	sb	a4,28(a5)
    80005f06:	00e78ea3          	sb	a4,29(a5)
    80005f0a:	00e78f23          	sb	a4,30(a5)
    80005f0e:	00e78fa3          	sb	a4,31(a5)
}
    80005f12:	60e2                	ld	ra,24(sp)
    80005f14:	6442                	ld	s0,16(sp)
    80005f16:	64a2                	ld	s1,8(sp)
    80005f18:	6105                	addi	sp,sp,32
    80005f1a:	8082                	ret
    panic("could not find virtio disk");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	85450513          	addi	a0,a0,-1964 # 80008770 <syscalls+0x370>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f2c:	00003517          	auipc	a0,0x3
    80005f30:	86450513          	addi	a0,a0,-1948 # 80008790 <syscalls+0x390>
    80005f34:	ffffa097          	auipc	ra,0xffffa
    80005f38:	614080e7          	jalr	1556(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	87450513          	addi	a0,a0,-1932 # 800087b0 <syscalls+0x3b0>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>

0000000080005f4c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f4c:	7119                	addi	sp,sp,-128
    80005f4e:	fc86                	sd	ra,120(sp)
    80005f50:	f8a2                	sd	s0,112(sp)
    80005f52:	f4a6                	sd	s1,104(sp)
    80005f54:	f0ca                	sd	s2,96(sp)
    80005f56:	ecce                	sd	s3,88(sp)
    80005f58:	e8d2                	sd	s4,80(sp)
    80005f5a:	e4d6                	sd	s5,72(sp)
    80005f5c:	e0da                	sd	s6,64(sp)
    80005f5e:	fc5e                	sd	s7,56(sp)
    80005f60:	f862                	sd	s8,48(sp)
    80005f62:	f466                	sd	s9,40(sp)
    80005f64:	f06a                	sd	s10,32(sp)
    80005f66:	0100                	addi	s0,sp,128
    80005f68:	892a                	mv	s2,a0
    80005f6a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f6c:	00c52c83          	lw	s9,12(a0)
    80005f70:	001c9c9b          	slliw	s9,s9,0x1
    80005f74:	1c82                	slli	s9,s9,0x20
    80005f76:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f7a:	0001f517          	auipc	a0,0x1f
    80005f7e:	12e50513          	addi	a0,a0,302 # 800250a8 <disk+0x20a8>
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	c8e080e7          	jalr	-882(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    80005f8a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f8c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f8e:	0001db97          	auipc	s7,0x1d
    80005f92:	072b8b93          	addi	s7,s7,114 # 80023000 <disk>
    80005f96:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f98:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f9a:	8a4e                	mv	s4,s3
    80005f9c:	a051                	j	80006020 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f9e:	00fb86b3          	add	a3,s7,a5
    80005fa2:	96da                	add	a3,a3,s6
    80005fa4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fa8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005faa:	0207c563          	bltz	a5,80005fd4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fae:	2485                	addiw	s1,s1,1
    80005fb0:	0711                	addi	a4,a4,4
    80005fb2:	23548d63          	beq	s1,s5,800061ec <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fb6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fb8:	0001f697          	auipc	a3,0x1f
    80005fbc:	06068693          	addi	a3,a3,96 # 80025018 <disk+0x2018>
    80005fc0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fc2:	0006c583          	lbu	a1,0(a3)
    80005fc6:	fde1                	bnez	a1,80005f9e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fc8:	2785                	addiw	a5,a5,1
    80005fca:	0685                	addi	a3,a3,1
    80005fcc:	ff879be3          	bne	a5,s8,80005fc2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fd0:	57fd                	li	a5,-1
    80005fd2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fd4:	02905a63          	blez	s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd8:	f9042503          	lw	a0,-112(s0)
    80005fdc:	00000097          	auipc	ra,0x0
    80005fe0:	daa080e7          	jalr	-598(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe4:	4785                	li	a5,1
    80005fe6:	0297d163          	bge	a5,s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fea:	f9442503          	lw	a0,-108(s0)
    80005fee:	00000097          	auipc	ra,0x0
    80005ff2:	d98080e7          	jalr	-616(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff6:	4789                	li	a5,2
    80005ff8:	0097d863          	bge	a5,s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ffc:	f9842503          	lw	a0,-104(s0)
    80006000:	00000097          	auipc	ra,0x0
    80006004:	d86080e7          	jalr	-634(ra) # 80005d86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	0001f597          	auipc	a1,0x1f
    8000600c:	0a058593          	addi	a1,a1,160 # 800250a8 <disk+0x20a8>
    80006010:	0001f517          	auipc	a0,0x1f
    80006014:	00850513          	addi	a0,a0,8 # 80025018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	2b6080e7          	jalr	694(ra) # 800022ce <sleep>
  for(int i = 0; i < 3; i++){
    80006020:	f9040713          	addi	a4,s0,-112
    80006024:	84ce                	mv	s1,s3
    80006026:	bf41                	j	80005fb6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006028:	4785                	li	a5,1
    8000602a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000602e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006032:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006036:	f9042983          	lw	s3,-112(s0)
    8000603a:	00499493          	slli	s1,s3,0x4
    8000603e:	0001fa17          	auipc	s4,0x1f
    80006042:	fc2a0a13          	addi	s4,s4,-62 # 80025000 <disk+0x2000>
    80006046:	000a3a83          	ld	s5,0(s4)
    8000604a:	9aa6                	add	s5,s5,s1
    8000604c:	f8040513          	addi	a0,s0,-128
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	090080e7          	jalr	144(ra) # 800010e0 <kvmpa>
    80006058:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000605c:	000a3783          	ld	a5,0(s4)
    80006060:	97a6                	add	a5,a5,s1
    80006062:	4741                	li	a4,16
    80006064:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006066:	000a3783          	ld	a5,0(s4)
    8000606a:	97a6                	add	a5,a5,s1
    8000606c:	4705                	li	a4,1
    8000606e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006072:	f9442703          	lw	a4,-108(s0)
    80006076:	000a3783          	ld	a5,0(s4)
    8000607a:	97a6                	add	a5,a5,s1
    8000607c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006080:	0712                	slli	a4,a4,0x4
    80006082:	000a3783          	ld	a5,0(s4)
    80006086:	97ba                	add	a5,a5,a4
    80006088:	05890693          	addi	a3,s2,88
    8000608c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000608e:	000a3783          	ld	a5,0(s4)
    80006092:	97ba                	add	a5,a5,a4
    80006094:	40000693          	li	a3,1024
    80006098:	c794                	sw	a3,8(a5)
  if(write)
    8000609a:	100d0a63          	beqz	s10,800061ae <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000609e:	0001f797          	auipc	a5,0x1f
    800060a2:	f627b783          	ld	a5,-158(a5) # 80025000 <disk+0x2000>
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	f5450513          	addi	a0,a0,-172 # 80023000 <disk>
    800060b4:	0001f797          	auipc	a5,0x1f
    800060b8:	f4c78793          	addi	a5,a5,-180 # 80025000 <disk+0x2000>
    800060bc:	6394                	ld	a3,0(a5)
    800060be:	96ba                	add	a3,a3,a4
    800060c0:	00c6d603          	lhu	a2,12(a3)
    800060c4:	00166613          	ori	a2,a2,1
    800060c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060cc:	f9842683          	lw	a3,-104(s0)
    800060d0:	6390                	ld	a2,0(a5)
    800060d2:	9732                	add	a4,a4,a2
    800060d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060d8:	20098613          	addi	a2,s3,512
    800060dc:	0612                	slli	a2,a2,0x4
    800060de:	962a                	add	a2,a2,a0
    800060e0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060e4:	00469713          	slli	a4,a3,0x4
    800060e8:	6394                	ld	a3,0(a5)
    800060ea:	96ba                	add	a3,a3,a4
    800060ec:	6589                	lui	a1,0x2
    800060ee:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060f2:	94ae                	add	s1,s1,a1
    800060f4:	94aa                	add	s1,s1,a0
    800060f6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060f8:	6394                	ld	a3,0(a5)
    800060fa:	96ba                	add	a3,a3,a4
    800060fc:	4585                	li	a1,1
    800060fe:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006100:	6394                	ld	a3,0(a5)
    80006102:	96ba                	add	a3,a3,a4
    80006104:	4509                	li	a0,2
    80006106:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000610a:	6394                	ld	a3,0(a5)
    8000610c:	9736                	add	a4,a4,a3
    8000610e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006112:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006116:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000611a:	6794                	ld	a3,8(a5)
    8000611c:	0026d703          	lhu	a4,2(a3)
    80006120:	8b1d                	andi	a4,a4,7
    80006122:	2709                	addiw	a4,a4,2
    80006124:	0706                	slli	a4,a4,0x1
    80006126:	9736                	add	a4,a4,a3
    80006128:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000612c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006130:	6798                	ld	a4,8(a5)
    80006132:	00275783          	lhu	a5,2(a4)
    80006136:	2785                	addiw	a5,a5,1
    80006138:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006144:	00492703          	lw	a4,4(s2)
    80006148:	4785                	li	a5,1
    8000614a:	02f71163          	bne	a4,a5,8000616c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000614e:	0001f997          	auipc	s3,0x1f
    80006152:	f5a98993          	addi	s3,s3,-166 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006156:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006158:	85ce                	mv	a1,s3
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffc097          	auipc	ra,0xffffc
    80006160:	172080e7          	jalr	370(ra) # 800022ce <sleep>
  while(b->disk == 1) {
    80006164:	00492783          	lw	a5,4(s2)
    80006168:	fe9788e3          	beq	a5,s1,80006158 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000616c:	f9042483          	lw	s1,-112(s0)
    80006170:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006174:	00479713          	slli	a4,a5,0x4
    80006178:	0001d797          	auipc	a5,0x1d
    8000617c:	e8878793          	addi	a5,a5,-376 # 80023000 <disk>
    80006180:	97ba                	add	a5,a5,a4
    80006182:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006186:	0001f917          	auipc	s2,0x1f
    8000618a:	e7a90913          	addi	s2,s2,-390 # 80025000 <disk+0x2000>
    free_desc(i);
    8000618e:	8526                	mv	a0,s1
    80006190:	00000097          	auipc	ra,0x0
    80006194:	bf6080e7          	jalr	-1034(ra) # 80005d86 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006198:	0492                	slli	s1,s1,0x4
    8000619a:	00093783          	ld	a5,0(s2)
    8000619e:	94be                	add	s1,s1,a5
    800061a0:	00c4d783          	lhu	a5,12(s1)
    800061a4:	8b85                	andi	a5,a5,1
    800061a6:	cf89                	beqz	a5,800061c0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061a8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ac:	b7cd                	j	8000618e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ae:	0001f797          	auipc	a5,0x1f
    800061b2:	e527b783          	ld	a5,-430(a5) # 80025000 <disk+0x2000>
    800061b6:	97ba                	add	a5,a5,a4
    800061b8:	4689                	li	a3,2
    800061ba:	00d79623          	sh	a3,12(a5)
    800061be:	b5fd                	j	800060ac <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061c0:	0001f517          	auipc	a0,0x1f
    800061c4:	ee850513          	addi	a0,a0,-280 # 800250a8 <disk+0x20a8>
    800061c8:	ffffb097          	auipc	ra,0xffffb
    800061cc:	afc080e7          	jalr	-1284(ra) # 80000cc4 <release>
}
    800061d0:	70e6                	ld	ra,120(sp)
    800061d2:	7446                	ld	s0,112(sp)
    800061d4:	74a6                	ld	s1,104(sp)
    800061d6:	7906                	ld	s2,96(sp)
    800061d8:	69e6                	ld	s3,88(sp)
    800061da:	6a46                	ld	s4,80(sp)
    800061dc:	6aa6                	ld	s5,72(sp)
    800061de:	6b06                	ld	s6,64(sp)
    800061e0:	7be2                	ld	s7,56(sp)
    800061e2:	7c42                	ld	s8,48(sp)
    800061e4:	7ca2                	ld	s9,40(sp)
    800061e6:	7d02                	ld	s10,32(sp)
    800061e8:	6109                	addi	sp,sp,128
    800061ea:	8082                	ret
  if(write)
    800061ec:	e20d1ee3          	bnez	s10,80006028 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061f0:	f8042023          	sw	zero,-128(s0)
    800061f4:	bd2d                	j	8000602e <virtio_disk_rw+0xe2>

00000000800061f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061f6:	1101                	addi	sp,sp,-32
    800061f8:	ec06                	sd	ra,24(sp)
    800061fa:	e822                	sd	s0,16(sp)
    800061fc:	e426                	sd	s1,8(sp)
    800061fe:	e04a                	sd	s2,0(sp)
    80006200:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006202:	0001f517          	auipc	a0,0x1f
    80006206:	ea650513          	addi	a0,a0,-346 # 800250a8 <disk+0x20a8>
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	a06080e7          	jalr	-1530(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006212:	0001f717          	auipc	a4,0x1f
    80006216:	dee70713          	addi	a4,a4,-530 # 80025000 <disk+0x2000>
    8000621a:	02075783          	lhu	a5,32(a4)
    8000621e:	6b18                	ld	a4,16(a4)
    80006220:	00275683          	lhu	a3,2(a4)
    80006224:	8ebd                	xor	a3,a3,a5
    80006226:	8a9d                	andi	a3,a3,7
    80006228:	cab9                	beqz	a3,8000627e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000622a:	0001d917          	auipc	s2,0x1d
    8000622e:	dd690913          	addi	s2,s2,-554 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006232:	0001f497          	auipc	s1,0x1f
    80006236:	dce48493          	addi	s1,s1,-562 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000623a:	078e                	slli	a5,a5,0x3
    8000623c:	97ba                	add	a5,a5,a4
    8000623e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006240:	20078713          	addi	a4,a5,512
    80006244:	0712                	slli	a4,a4,0x4
    80006246:	974a                	add	a4,a4,s2
    80006248:	03074703          	lbu	a4,48(a4)
    8000624c:	ef21                	bnez	a4,800062a4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000624e:	20078793          	addi	a5,a5,512
    80006252:	0792                	slli	a5,a5,0x4
    80006254:	97ca                	add	a5,a5,s2
    80006256:	7798                	ld	a4,40(a5)
    80006258:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000625c:	7788                	ld	a0,40(a5)
    8000625e:	ffffc097          	auipc	ra,0xffffc
    80006262:	1f6080e7          	jalr	502(ra) # 80002454 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006266:	0204d783          	lhu	a5,32(s1)
    8000626a:	2785                	addiw	a5,a5,1
    8000626c:	8b9d                	andi	a5,a5,7
    8000626e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006272:	6898                	ld	a4,16(s1)
    80006274:	00275683          	lhu	a3,2(a4)
    80006278:	8a9d                	andi	a3,a3,7
    8000627a:	fcf690e3          	bne	a3,a5,8000623a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000627e:	10001737          	lui	a4,0x10001
    80006282:	533c                	lw	a5,96(a4)
    80006284:	8b8d                	andi	a5,a5,3
    80006286:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006288:	0001f517          	auipc	a0,0x1f
    8000628c:	e2050513          	addi	a0,a0,-480 # 800250a8 <disk+0x20a8>
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	a34080e7          	jalr	-1484(ra) # 80000cc4 <release>
}
    80006298:	60e2                	ld	ra,24(sp)
    8000629a:	6442                	ld	s0,16(sp)
    8000629c:	64a2                	ld	s1,8(sp)
    8000629e:	6902                	ld	s2,0(sp)
    800062a0:	6105                	addi	sp,sp,32
    800062a2:	8082                	ret
      panic("virtio_disk_intr status");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	52c50513          	addi	a0,a0,1324 # 800087d0 <syscalls+0x3d0>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	29c080e7          	jalr	668(ra) # 80000548 <panic>
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
