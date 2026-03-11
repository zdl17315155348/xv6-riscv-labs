
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	18010113          	addi	sp,sp,384 # 80009180 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	d7c78793          	addi	a5,a5,-644 # 80005de0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdd7ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dd678793          	addi	a5,a5,-554 # 80000e84 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00002097          	auipc	ra,0x2
    80000122:	36a080e7          	jalr	874(ra) # 80002488 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	a50080e7          	jalr	-1456(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00002097          	auipc	ra,0x2
    800001ba:	80a080e7          	jalr	-2038(ra) # 800019c0 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	00a080e7          	jalr	10(ra) # 800021d0 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00002097          	auipc	ra,0x2
    80000206:	230080e7          	jalr	560(ra) # 80002432 <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	a6c080e7          	jalr	-1428(ra) # 80000c8a <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	a56080e7          	jalr	-1450(ra) # 80000c8a <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	910080e7          	jalr	-1776(ra) # 80000bd6 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00002097          	auipc	ra,0x2
    800002e8:	1fa080e7          	jalr	506(ra) # 800024de <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00002097          	auipc	ra,0x2
    8000043c:	f1e080e7          	jalr	-226(ra) # 80002356 <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00000097          	auipc	ra,0x0
    8000045e:	6ec080e7          	jalr	1772(ra) # 80000b46 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	0001c797          	auipc	a5,0x1c
    8000046e:	2a678793          	addi	a5,a5,678 # 8001c710 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b6a50513          	addi	a0,a0,-1174 # 800080c8 <digits+0x88>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	5e4080e7          	jalr	1508(ra) # 80000bd6 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	534080e7          	jalr	1332(ra) # 80000c8a <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	3ca080e7          	jalr	970(ra) # 80000b46 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	374080e7          	jalr	884(ra) # 80000b46 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	39c080e7          	jalr	924(ra) # 80000b8a <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	40a080e7          	jalr	1034(ra) # 80000c2a <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	ac4080e7          	jalr	-1340(ra) # 80002356 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	8b2080e7          	jalr	-1870(ra) # 800021d0 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00020797          	auipc	a5,0x20
    80000a02:	60278793          	addi	a5,a5,1538 # 80021000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	7c650513          	addi	a0,a0,1990 # 80011280 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00020517          	auipc	a0,0x20
    80000ad2:	53250513          	addi	a0,a0,1330 # 80021000 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	79048493          	addi	s1,s1,1936 # 80011280 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	74c50513          	addi	a0,a0,1868 # 80011280 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e34080e7          	jalr	-460(ra) # 800019a4 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	e02080e7          	jalr	-510(ra) # 800019a4 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	df6080e7          	jalr	-522(ra) # 800019a4 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dde080e7          	jalr	-546(ra) # 800019a4 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d9e080e7          	jalr	-610(ra) # 800019a4 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	90e080e7          	jalr	-1778(ra) # 80000530 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d72080e7          	jalr	-654(ra) # 800019a4 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8be080e7          	jalr	-1858(ra) # 80000530 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	866080e7          	jalr	-1946(ra) # 80000530 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ce09                	beqz	a2,80000cf2 <memset+0x20>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	fff6071b          	addiw	a4,a2,-1
    80000ce0:	1702                	slli	a4,a4,0x20
    80000ce2:	9301                	srli	a4,a4,0x20
    80000ce4:	0705                	addi	a4,a4,1
    80000ce6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000ce8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cec:	0785                	addi	a5,a5,1
    80000cee:	fee79de3          	bne	a5,a4,80000ce8 <memset+0x16>
  }
  return dst;
}
    80000cf2:	6422                	ld	s0,8(sp)
    80000cf4:	0141                	addi	sp,sp,16
    80000cf6:	8082                	ret

0000000080000cf8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf8:	1141                	addi	sp,sp,-16
    80000cfa:	e422                	sd	s0,8(sp)
    80000cfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfe:	ca05                	beqz	a2,80000d2e <memcmp+0x36>
    80000d00:	fff6069b          	addiw	a3,a2,-1
    80000d04:	1682                	slli	a3,a3,0x20
    80000d06:	9281                	srli	a3,a3,0x20
    80000d08:	0685                	addi	a3,a3,1
    80000d0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d0c:	00054783          	lbu	a5,0(a0)
    80000d10:	0005c703          	lbu	a4,0(a1)
    80000d14:	00e79863          	bne	a5,a4,80000d24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d18:	0505                	addi	a0,a0,1
    80000d1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d1c:	fed518e3          	bne	a0,a3,80000d0c <memcmp+0x14>
  }

  return 0;
    80000d20:	4501                	li	a0,0
    80000d22:	a019                	j	80000d28 <memcmp+0x30>
      return *s1 - *s2;
    80000d24:	40e7853b          	subw	a0,a5,a4
}
    80000d28:	6422                	ld	s0,8(sp)
    80000d2a:	0141                	addi	sp,sp,16
    80000d2c:	8082                	ret
  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	bfe5                	j	80000d28 <memcmp+0x30>

0000000080000d32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d38:	00a5f963          	bgeu	a1,a0,80000d4a <memmove+0x18>
    80000d3c:	02061713          	slli	a4,a2,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	00e587b3          	add	a5,a1,a4
    80000d46:	02f56563          	bltu	a0,a5,80000d70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d4a:	fff6069b          	addiw	a3,a2,-1
    80000d4e:	ce11                	beqz	a2,80000d6a <memmove+0x38>
    80000d50:	1682                	slli	a3,a3,0x20
    80000d52:	9281                	srli	a3,a3,0x20
    80000d54:	0685                	addi	a3,a3,1
    80000d56:	96ae                	add	a3,a3,a1
    80000d58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d5a:	0585                	addi	a1,a1,1
    80000d5c:	0785                	addi	a5,a5,1
    80000d5e:	fff5c703          	lbu	a4,-1(a1)
    80000d62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000d66:	fed59ae3          	bne	a1,a3,80000d5a <memmove+0x28>

  return dst;
}
    80000d6a:	6422                	ld	s0,8(sp)
    80000d6c:	0141                	addi	sp,sp,16
    80000d6e:	8082                	ret
    d += n;
    80000d70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000d72:	fff6069b          	addiw	a3,a2,-1
    80000d76:	da75                	beqz	a2,80000d6a <memmove+0x38>
    80000d78:	02069613          	slli	a2,a3,0x20
    80000d7c:	9201                	srli	a2,a2,0x20
    80000d7e:	fff64613          	not	a2,a2
    80000d82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000d84:	17fd                	addi	a5,a5,-1
    80000d86:	177d                	addi	a4,a4,-1
    80000d88:	0007c683          	lbu	a3,0(a5)
    80000d8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000d90:	fec79ae3          	bne	a5,a2,80000d84 <memmove+0x52>
    80000d94:	bfd9                	j	80000d6a <memmove+0x38>

0000000080000d96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d96:	1141                	addi	sp,sp,-16
    80000d98:	e406                	sd	ra,8(sp)
    80000d9a:	e022                	sd	s0,0(sp)
    80000d9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d9e:	00000097          	auipc	ra,0x0
    80000da2:	f94080e7          	jalr	-108(ra) # 80000d32 <memmove>
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e422                	sd	s0,8(sp)
    80000db2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000db4:	ce11                	beqz	a2,80000dd0 <strncmp+0x22>
    80000db6:	00054783          	lbu	a5,0(a0)
    80000dba:	cf89                	beqz	a5,80000dd4 <strncmp+0x26>
    80000dbc:	0005c703          	lbu	a4,0(a1)
    80000dc0:	00f71a63          	bne	a4,a5,80000dd4 <strncmp+0x26>
    n--, p++, q++;
    80000dc4:	367d                	addiw	a2,a2,-1
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dca:	f675                	bnez	a2,80000db6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dcc:	4501                	li	a0,0
    80000dce:	a809                	j	80000de0 <strncmp+0x32>
    80000dd0:	4501                	li	a0,0
    80000dd2:	a039                	j	80000de0 <strncmp+0x32>
  if(n == 0)
    80000dd4:	ca09                	beqz	a2,80000de6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dd6:	00054503          	lbu	a0,0(a0)
    80000dda:	0005c783          	lbu	a5,0(a1)
    80000dde:	9d1d                	subw	a0,a0,a5
}
    80000de0:	6422                	ld	s0,8(sp)
    80000de2:	0141                	addi	sp,sp,16
    80000de4:	8082                	ret
    return 0;
    80000de6:	4501                	li	a0,0
    80000de8:	bfe5                	j	80000de0 <strncmp+0x32>

0000000080000dea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dea:	1141                	addi	sp,sp,-16
    80000dec:	e422                	sd	s0,8(sp)
    80000dee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000df0:	872a                	mv	a4,a0
    80000df2:	8832                	mv	a6,a2
    80000df4:	367d                	addiw	a2,a2,-1
    80000df6:	01005963          	blez	a6,80000e08 <strncpy+0x1e>
    80000dfa:	0705                	addi	a4,a4,1
    80000dfc:	0005c783          	lbu	a5,0(a1)
    80000e00:	fef70fa3          	sb	a5,-1(a4)
    80000e04:	0585                	addi	a1,a1,1
    80000e06:	f7f5                	bnez	a5,80000df2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e08:	00c05d63          	blez	a2,80000e22 <strncpy+0x38>
    80000e0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e0e:	0685                	addi	a3,a3,1
    80000e10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e14:	fff6c793          	not	a5,a3
    80000e18:	9fb9                	addw	a5,a5,a4
    80000e1a:	010787bb          	addw	a5,a5,a6
    80000e1e:	fef048e3          	bgtz	a5,80000e0e <strncpy+0x24>
  return os;
}
    80000e22:	6422                	ld	s0,8(sp)
    80000e24:	0141                	addi	sp,sp,16
    80000e26:	8082                	ret

0000000080000e28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e2e:	02c05363          	blez	a2,80000e54 <safestrcpy+0x2c>
    80000e32:	fff6069b          	addiw	a3,a2,-1
    80000e36:	1682                	slli	a3,a3,0x20
    80000e38:	9281                	srli	a3,a3,0x20
    80000e3a:	96ae                	add	a3,a3,a1
    80000e3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e3e:	00d58963          	beq	a1,a3,80000e50 <safestrcpy+0x28>
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	0785                	addi	a5,a5,1
    80000e46:	fff5c703          	lbu	a4,-1(a1)
    80000e4a:	fee78fa3          	sb	a4,-1(a5)
    80000e4e:	fb65                	bnez	a4,80000e3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e54:	6422                	ld	s0,8(sp)
    80000e56:	0141                	addi	sp,sp,16
    80000e58:	8082                	ret

0000000080000e5a <strlen>:

int
strlen(const char *s)
{
    80000e5a:	1141                	addi	sp,sp,-16
    80000e5c:	e422                	sd	s0,8(sp)
    80000e5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e60:	00054783          	lbu	a5,0(a0)
    80000e64:	cf91                	beqz	a5,80000e80 <strlen+0x26>
    80000e66:	0505                	addi	a0,a0,1
    80000e68:	87aa                	mv	a5,a0
    80000e6a:	4685                	li	a3,1
    80000e6c:	9e89                	subw	a3,a3,a0
    80000e6e:	00f6853b          	addw	a0,a3,a5
    80000e72:	0785                	addi	a5,a5,1
    80000e74:	fff7c703          	lbu	a4,-1(a5)
    80000e78:	fb7d                	bnez	a4,80000e6e <strlen+0x14>
    ;
  return n;
}
    80000e7a:	6422                	ld	s0,8(sp)
    80000e7c:	0141                	addi	sp,sp,16
    80000e7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e80:	4501                	li	a0,0
    80000e82:	bfe5                	j	80000e7a <strlen+0x20>

0000000080000e84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e84:	1141                	addi	sp,sp,-16
    80000e86:	e406                	sd	ra,8(sp)
    80000e88:	e022                	sd	s0,0(sp)
    80000e8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e8c:	00001097          	auipc	ra,0x1
    80000e90:	b08080e7          	jalr	-1272(ra) # 80001994 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e94:	00008717          	auipc	a4,0x8
    80000e98:	18470713          	addi	a4,a4,388 # 80009018 <started>
  if(cpuid() == 0){
    80000e9c:	c139                	beqz	a0,80000ee2 <main+0x5e>
    while(started == 0)
    80000e9e:	431c                	lw	a5,0(a4)
    80000ea0:	2781                	sext.w	a5,a5
    80000ea2:	dff5                	beqz	a5,80000e9e <main+0x1a>
      ;
    __sync_synchronize();
    80000ea4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ea8:	00001097          	auipc	ra,0x1
    80000eac:	aec080e7          	jalr	-1300(ra) # 80001994 <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	754080e7          	jalr	1876(ra) # 8000261e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	f4e080e7          	jalr	-178(ra) # 80005e20 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	016080e7          	jalr	22(ra) # 80001ef0 <scheduler>
    consoleinit();
    80000ee2:	fffff097          	auipc	ra,0xfffff
    80000ee6:	560080e7          	jalr	1376(ra) # 80000442 <consoleinit>
    printfinit();
    80000eea:	00000097          	auipc	ra,0x0
    80000eee:	876080e7          	jalr	-1930(ra) # 80000760 <printfinit>
    printf("\n");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	1d650513          	addi	a0,a0,470 # 800080c8 <digits+0x88>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	680080e7          	jalr	1664(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	19e50513          	addi	a0,a0,414 # 800080a0 <digits+0x60>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	670080e7          	jalr	1648(ra) # 8000057a <printf>
    printf("\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	1b650513          	addi	a0,a0,438 # 800080c8 <digits+0x88>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	660080e7          	jalr	1632(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80000f22:	00000097          	auipc	ra,0x0
    80000f26:	b88080e7          	jalr	-1144(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f2a:	00000097          	auipc	ra,0x0
    80000f2e:	310080e7          	jalr	784(ra) # 8000123a <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	9c2080e7          	jalr	-1598(ra) # 800018fc <procinit>
    trapinit();      // trap vectors
    80000f42:	00001097          	auipc	ra,0x1
    80000f46:	6b4080e7          	jalr	1716(ra) # 800025f6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	6d4080e7          	jalr	1748(ra) # 8000261e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	eb8080e7          	jalr	-328(ra) # 80005e0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	ec6080e7          	jalr	-314(ra) # 80005e20 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	dfe080e7          	jalr	-514(ra) # 80002d60 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	554080e7          	jalr	1364(ra) # 800034be <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	5ae080e7          	jalr	1454(ra) # 80004520 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	fc8080e7          	jalr	-56(ra) # 80005f42 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	d08080e7          	jalr	-760(ra) # 80001c8a <userinit>
    __sync_synchronize();
    80000f8a:	0ff0000f          	fence
    started = 1;
    80000f8e:	4785                	li	a5,1
    80000f90:	00008717          	auipc	a4,0x8
    80000f94:	08f72423          	sw	a5,136(a4) # 80009018 <started>
    80000f98:	b789                	j	80000eda <main+0x56>

0000000080000f9a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f9a:	1141                	addi	sp,sp,-16
    80000f9c:	e422                	sd	s0,8(sp)
    80000f9e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fa0:	00008797          	auipc	a5,0x8
    80000fa4:	0807b783          	ld	a5,128(a5) # 80009020 <kernel_pagetable>
    80000fa8:	83b1                	srli	a5,a5,0xc
    80000faa:	577d                	li	a4,-1
    80000fac:	177e                	slli	a4,a4,0x3f
    80000fae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fb0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb4:	12000073          	sfence.vma
  sfence_vma();
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret

0000000080000fbe <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fbe:	7139                	addi	sp,sp,-64
    80000fc0:	fc06                	sd	ra,56(sp)
    80000fc2:	f822                	sd	s0,48(sp)
    80000fc4:	f426                	sd	s1,40(sp)
    80000fc6:	f04a                	sd	s2,32(sp)
    80000fc8:	ec4e                	sd	s3,24(sp)
    80000fca:	e852                	sd	s4,16(sp)
    80000fcc:	e456                	sd	s5,8(sp)
    80000fce:	e05a                	sd	s6,0(sp)
    80000fd0:	0080                	addi	s0,sp,64
    80000fd2:	84aa                	mv	s1,a0
    80000fd4:	89ae                	mv	s3,a1
    80000fd6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd8:	57fd                	li	a5,-1
    80000fda:	83e9                	srli	a5,a5,0x1a
    80000fdc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fde:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fe0:	04b7f263          	bgeu	a5,a1,80001024 <walk+0x66>
    panic("walk");
    80000fe4:	00007517          	auipc	a0,0x7
    80000fe8:	0ec50513          	addi	a0,a0,236 # 800080d0 <digits+0x90>
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	544080e7          	jalr	1348(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ff4:	060a8663          	beqz	s5,80001060 <walk+0xa2>
    80000ff8:	00000097          	auipc	ra,0x0
    80000ffc:	aee080e7          	jalr	-1298(ra) # 80000ae6 <kalloc>
    80001000:	84aa                	mv	s1,a0
    80001002:	c529                	beqz	a0,8000104c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001004:	6605                	lui	a2,0x1
    80001006:	4581                	li	a1,0
    80001008:	00000097          	auipc	ra,0x0
    8000100c:	cca080e7          	jalr	-822(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001010:	00c4d793          	srli	a5,s1,0xc
    80001014:	07aa                	slli	a5,a5,0xa
    80001016:	0017e793          	ori	a5,a5,1
    8000101a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000101e:	3a5d                	addiw	s4,s4,-9
    80001020:	036a0063          	beq	s4,s6,80001040 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001024:	0149d933          	srl	s2,s3,s4
    80001028:	1ff97913          	andi	s2,s2,511
    8000102c:	090e                	slli	s2,s2,0x3
    8000102e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001030:	00093483          	ld	s1,0(s2)
    80001034:	0014f793          	andi	a5,s1,1
    80001038:	dfd5                	beqz	a5,80000ff4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000103a:	80a9                	srli	s1,s1,0xa
    8000103c:	04b2                	slli	s1,s1,0xc
    8000103e:	b7c5                	j	8000101e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001040:	00c9d513          	srli	a0,s3,0xc
    80001044:	1ff57513          	andi	a0,a0,511
    80001048:	050e                	slli	a0,a0,0x3
    8000104a:	9526                	add	a0,a0,s1
}
    8000104c:	70e2                	ld	ra,56(sp)
    8000104e:	7442                	ld	s0,48(sp)
    80001050:	74a2                	ld	s1,40(sp)
    80001052:	7902                	ld	s2,32(sp)
    80001054:	69e2                	ld	s3,24(sp)
    80001056:	6a42                	ld	s4,16(sp)
    80001058:	6aa2                	ld	s5,8(sp)
    8000105a:	6b02                	ld	s6,0(sp)
    8000105c:	6121                	addi	sp,sp,64
    8000105e:	8082                	ret
        return 0;
    80001060:	4501                	li	a0,0
    80001062:	b7ed                	j	8000104c <walk+0x8e>

0000000080001064 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001064:	57fd                	li	a5,-1
    80001066:	83e9                	srli	a5,a5,0x1a
    80001068:	00b7f463          	bgeu	a5,a1,80001070 <walkaddr+0xc>
    return 0;
    8000106c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000106e:	8082                	ret
{
    80001070:	1141                	addi	sp,sp,-16
    80001072:	e406                	sd	ra,8(sp)
    80001074:	e022                	sd	s0,0(sp)
    80001076:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001078:	4601                	li	a2,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	f44080e7          	jalr	-188(ra) # 80000fbe <walk>
  if(pte == 0)
    80001082:	c105                	beqz	a0,800010a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001084:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001086:	0117f693          	andi	a3,a5,17
    8000108a:	4745                	li	a4,17
    return 0;
    8000108c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000108e:	00e68663          	beq	a3,a4,8000109a <walkaddr+0x36>
}
    80001092:	60a2                	ld	ra,8(sp)
    80001094:	6402                	ld	s0,0(sp)
    80001096:	0141                	addi	sp,sp,16
    80001098:	8082                	ret
  pa = PTE2PA(*pte);
    8000109a:	00a7d513          	srli	a0,a5,0xa
    8000109e:	0532                	slli	a0,a0,0xc
  return pa;
    800010a0:	bfcd                	j	80001092 <walkaddr+0x2e>
    return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7fd                	j	80001092 <walkaddr+0x2e>

00000000800010a6 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010a6:	715d                	addi	sp,sp,-80
    800010a8:	e486                	sd	ra,72(sp)
    800010aa:	e0a2                	sd	s0,64(sp)
    800010ac:	fc26                	sd	s1,56(sp)
    800010ae:	f84a                	sd	s2,48(sp)
    800010b0:	f44e                	sd	s3,40(sp)
    800010b2:	f052                	sd	s4,32(sp)
    800010b4:	ec56                	sd	s5,24(sp)
    800010b6:	e85a                	sd	s6,16(sp)
    800010b8:	e45e                	sd	s7,8(sp)
    800010ba:	0880                	addi	s0,sp,80
    800010bc:	8aaa                	mv	s5,a0
    800010be:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800010c0:	777d                	lui	a4,0xfffff
    800010c2:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c6:	167d                	addi	a2,a2,-1
    800010c8:	00b609b3          	add	s3,a2,a1
    800010cc:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010d0:	893e                	mv	s2,a5
    800010d2:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d6:	6b85                	lui	s7,0x1
    800010d8:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010dc:	4605                	li	a2,1
    800010de:	85ca                	mv	a1,s2
    800010e0:	8556                	mv	a0,s5
    800010e2:	00000097          	auipc	ra,0x0
    800010e6:	edc080e7          	jalr	-292(ra) # 80000fbe <walk>
    800010ea:	c51d                	beqz	a0,80001118 <mappages+0x72>
    if(*pte & PTE_V)
    800010ec:	611c                	ld	a5,0(a0)
    800010ee:	8b85                	andi	a5,a5,1
    800010f0:	ef81                	bnez	a5,80001108 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010f2:	80b1                	srli	s1,s1,0xc
    800010f4:	04aa                	slli	s1,s1,0xa
    800010f6:	0164e4b3          	or	s1,s1,s6
    800010fa:	0014e493          	ori	s1,s1,1
    800010fe:	e104                	sd	s1,0(a0)
    if(a == last)
    80001100:	03390863          	beq	s2,s3,80001130 <mappages+0x8a>
    a += PGSIZE;
    80001104:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001106:	bfc9                	j	800010d8 <mappages+0x32>
      panic("remap");
    80001108:	00007517          	auipc	a0,0x7
    8000110c:	fd050513          	addi	a0,a0,-48 # 800080d8 <digits+0x98>
    80001110:	fffff097          	auipc	ra,0xfffff
    80001114:	420080e7          	jalr	1056(ra) # 80000530 <panic>
      return -1;
    80001118:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000111a:	60a6                	ld	ra,72(sp)
    8000111c:	6406                	ld	s0,64(sp)
    8000111e:	74e2                	ld	s1,56(sp)
    80001120:	7942                	ld	s2,48(sp)
    80001122:	79a2                	ld	s3,40(sp)
    80001124:	7a02                	ld	s4,32(sp)
    80001126:	6ae2                	ld	s5,24(sp)
    80001128:	6b42                	ld	s6,16(sp)
    8000112a:	6ba2                	ld	s7,8(sp)
    8000112c:	6161                	addi	sp,sp,80
    8000112e:	8082                	ret
  return 0;
    80001130:	4501                	li	a0,0
    80001132:	b7e5                	j	8000111a <mappages+0x74>

0000000080001134 <kvmmap>:
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e406                	sd	ra,8(sp)
    80001138:	e022                	sd	s0,0(sp)
    8000113a:	0800                	addi	s0,sp,16
    8000113c:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000113e:	86b2                	mv	a3,a2
    80001140:	863e                	mv	a2,a5
    80001142:	00000097          	auipc	ra,0x0
    80001146:	f64080e7          	jalr	-156(ra) # 800010a6 <mappages>
    8000114a:	e509                	bnez	a0,80001154 <kvmmap+0x20>
}
    8000114c:	60a2                	ld	ra,8(sp)
    8000114e:	6402                	ld	s0,0(sp)
    80001150:	0141                	addi	sp,sp,16
    80001152:	8082                	ret
    panic("kvmmap");
    80001154:	00007517          	auipc	a0,0x7
    80001158:	f8c50513          	addi	a0,a0,-116 # 800080e0 <digits+0xa0>
    8000115c:	fffff097          	auipc	ra,0xfffff
    80001160:	3d4080e7          	jalr	980(ra) # 80000530 <panic>

0000000080001164 <kvmmake>:
{
    80001164:	1101                	addi	sp,sp,-32
    80001166:	ec06                	sd	ra,24(sp)
    80001168:	e822                	sd	s0,16(sp)
    8000116a:	e426                	sd	s1,8(sp)
    8000116c:	e04a                	sd	s2,0(sp)
    8000116e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001170:	00000097          	auipc	ra,0x0
    80001174:	976080e7          	jalr	-1674(ra) # 80000ae6 <kalloc>
    80001178:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000117a:	6605                	lui	a2,0x1
    8000117c:	4581                	li	a1,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001186:	4719                	li	a4,6
    80001188:	6685                	lui	a3,0x1
    8000118a:	10000637          	lui	a2,0x10000
    8000118e:	100005b7          	lui	a1,0x10000
    80001192:	8526                	mv	a0,s1
    80001194:	00000097          	auipc	ra,0x0
    80001198:	fa0080e7          	jalr	-96(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000119c:	4719                	li	a4,6
    8000119e:	6685                	lui	a3,0x1
    800011a0:	10001637          	lui	a2,0x10001
    800011a4:	100015b7          	lui	a1,0x10001
    800011a8:	8526                	mv	a0,s1
    800011aa:	00000097          	auipc	ra,0x0
    800011ae:	f8a080e7          	jalr	-118(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011b2:	4719                	li	a4,6
    800011b4:	004006b7          	lui	a3,0x400
    800011b8:	0c000637          	lui	a2,0xc000
    800011bc:	0c0005b7          	lui	a1,0xc000
    800011c0:	8526                	mv	a0,s1
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	f72080e7          	jalr	-142(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011ca:	00007917          	auipc	s2,0x7
    800011ce:	e3690913          	addi	s2,s2,-458 # 80008000 <etext>
    800011d2:	4729                	li	a4,10
    800011d4:	80007697          	auipc	a3,0x80007
    800011d8:	e2c68693          	addi	a3,a3,-468 # 8000 <_entry-0x7fff8000>
    800011dc:	4605                	li	a2,1
    800011de:	067e                	slli	a2,a2,0x1f
    800011e0:	85b2                	mv	a1,a2
    800011e2:	8526                	mv	a0,s1
    800011e4:	00000097          	auipc	ra,0x0
    800011e8:	f50080e7          	jalr	-176(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011ec:	4719                	li	a4,6
    800011ee:	46c5                	li	a3,17
    800011f0:	06ee                	slli	a3,a3,0x1b
    800011f2:	412686b3          	sub	a3,a3,s2
    800011f6:	864a                	mv	a2,s2
    800011f8:	85ca                	mv	a1,s2
    800011fa:	8526                	mv	a0,s1
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	f38080e7          	jalr	-200(ra) # 80001134 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001204:	4729                	li	a4,10
    80001206:	6685                	lui	a3,0x1
    80001208:	00006617          	auipc	a2,0x6
    8000120c:	df860613          	addi	a2,a2,-520 # 80007000 <_trampoline>
    80001210:	040005b7          	lui	a1,0x4000
    80001214:	15fd                	addi	a1,a1,-1
    80001216:	05b2                	slli	a1,a1,0xc
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f1a080e7          	jalr	-230(ra) # 80001134 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	642080e7          	jalr	1602(ra) # 80001866 <proc_mapstacks>
}
    8000122c:	8526                	mv	a0,s1
    8000122e:	60e2                	ld	ra,24(sp)
    80001230:	6442                	ld	s0,16(sp)
    80001232:	64a2                	ld	s1,8(sp)
    80001234:	6902                	ld	s2,0(sp)
    80001236:	6105                	addi	sp,sp,32
    80001238:	8082                	ret

000000008000123a <kvminit>:
{
    8000123a:	1141                	addi	sp,sp,-16
    8000123c:	e406                	sd	ra,8(sp)
    8000123e:	e022                	sd	s0,0(sp)
    80001240:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001242:	00000097          	auipc	ra,0x0
    80001246:	f22080e7          	jalr	-222(ra) # 80001164 <kvmmake>
    8000124a:	00008797          	auipc	a5,0x8
    8000124e:	dca7bb23          	sd	a0,-554(a5) # 80009020 <kernel_pagetable>
}
    80001252:	60a2                	ld	ra,8(sp)
    80001254:	6402                	ld	s0,0(sp)
    80001256:	0141                	addi	sp,sp,16
    80001258:	8082                	ret

000000008000125a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000125a:	715d                	addi	sp,sp,-80
    8000125c:	e486                	sd	ra,72(sp)
    8000125e:	e0a2                	sd	s0,64(sp)
    80001260:	fc26                	sd	s1,56(sp)
    80001262:	f84a                	sd	s2,48(sp)
    80001264:	f44e                	sd	s3,40(sp)
    80001266:	f052                	sd	s4,32(sp)
    80001268:	ec56                	sd	s5,24(sp)
    8000126a:	e85a                	sd	s6,16(sp)
    8000126c:	e45e                	sd	s7,8(sp)
    8000126e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001270:	03459793          	slli	a5,a1,0x34
    80001274:	e795                	bnez	a5,800012a0 <uvmunmap+0x46>
    80001276:	8a2a                	mv	s4,a0
    80001278:	892e                	mv	s2,a1
    8000127a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000127c:	0632                	slli	a2,a2,0xc
    8000127e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001282:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001284:	6b05                	lui	s6,0x1
    80001286:	0735e863          	bltu	a1,s3,800012f6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000128a:	60a6                	ld	ra,72(sp)
    8000128c:	6406                	ld	s0,64(sp)
    8000128e:	74e2                	ld	s1,56(sp)
    80001290:	7942                	ld	s2,48(sp)
    80001292:	79a2                	ld	s3,40(sp)
    80001294:	7a02                	ld	s4,32(sp)
    80001296:	6ae2                	ld	s5,24(sp)
    80001298:	6b42                	ld	s6,16(sp)
    8000129a:	6ba2                	ld	s7,8(sp)
    8000129c:	6161                	addi	sp,sp,80
    8000129e:	8082                	ret
    panic("uvmunmap: not aligned");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	288080e7          	jalr	648(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800012b0:	00007517          	auipc	a0,0x7
    800012b4:	e5050513          	addi	a0,a0,-432 # 80008100 <digits+0xc0>
    800012b8:	fffff097          	auipc	ra,0xfffff
    800012bc:	278080e7          	jalr	632(ra) # 80000530 <panic>
      panic("uvmunmap: not mapped");
    800012c0:	00007517          	auipc	a0,0x7
    800012c4:	e5050513          	addi	a0,a0,-432 # 80008110 <digits+0xd0>
    800012c8:	fffff097          	auipc	ra,0xfffff
    800012cc:	268080e7          	jalr	616(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800012d0:	00007517          	auipc	a0,0x7
    800012d4:	e5850513          	addi	a0,a0,-424 # 80008128 <digits+0xe8>
    800012d8:	fffff097          	auipc	ra,0xfffff
    800012dc:	258080e7          	jalr	600(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800012e0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012e2:	0532                	slli	a0,a0,0xc
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	706080e7          	jalr	1798(ra) # 800009ea <kfree>
    *pte = 0;
    800012ec:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f0:	995a                	add	s2,s2,s6
    800012f2:	f9397ce3          	bgeu	s2,s3,8000128a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f6:	4601                	li	a2,0
    800012f8:	85ca                	mv	a1,s2
    800012fa:	8552                	mv	a0,s4
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	cc2080e7          	jalr	-830(ra) # 80000fbe <walk>
    80001304:	84aa                	mv	s1,a0
    80001306:	d54d                	beqz	a0,800012b0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001308:	6108                	ld	a0,0(a0)
    8000130a:	00157793          	andi	a5,a0,1
    8000130e:	dbcd                	beqz	a5,800012c0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001310:	3ff57793          	andi	a5,a0,1023
    80001314:	fb778ee3          	beq	a5,s7,800012d0 <uvmunmap+0x76>
    if(do_free){
    80001318:	fc0a8ae3          	beqz	s5,800012ec <uvmunmap+0x92>
    8000131c:	b7d1                	j	800012e0 <uvmunmap+0x86>

000000008000131e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000131e:	1101                	addi	sp,sp,-32
    80001320:	ec06                	sd	ra,24(sp)
    80001322:	e822                	sd	s0,16(sp)
    80001324:	e426                	sd	s1,8(sp)
    80001326:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	7be080e7          	jalr	1982(ra) # 80000ae6 <kalloc>
    80001330:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001332:	c519                	beqz	a0,80001340 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001334:	6605                	lui	a2,0x1
    80001336:	4581                	li	a1,0
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	99a080e7          	jalr	-1638(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6105                	addi	sp,sp,32
    8000134a:	8082                	ret

000000008000134c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000134c:	7179                	addi	sp,sp,-48
    8000134e:	f406                	sd	ra,40(sp)
    80001350:	f022                	sd	s0,32(sp)
    80001352:	ec26                	sd	s1,24(sp)
    80001354:	e84a                	sd	s2,16(sp)
    80001356:	e44e                	sd	s3,8(sp)
    80001358:	e052                	sd	s4,0(sp)
    8000135a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000135c:	6785                	lui	a5,0x1
    8000135e:	04f67863          	bgeu	a2,a5,800013ae <uvminit+0x62>
    80001362:	8a2a                	mv	s4,a0
    80001364:	89ae                	mv	s3,a1
    80001366:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	77e080e7          	jalr	1918(ra) # 80000ae6 <kalloc>
    80001370:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001372:	6605                	lui	a2,0x1
    80001374:	4581                	li	a1,0
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	95c080e7          	jalr	-1700(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000137e:	4779                	li	a4,30
    80001380:	86ca                	mv	a3,s2
    80001382:	6605                	lui	a2,0x1
    80001384:	4581                	li	a1,0
    80001386:	8552                	mv	a0,s4
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	d1e080e7          	jalr	-738(ra) # 800010a6 <mappages>
  memmove(mem, src, sz);
    80001390:	8626                	mv	a2,s1
    80001392:	85ce                	mv	a1,s3
    80001394:	854a                	mv	a0,s2
    80001396:	00000097          	auipc	ra,0x0
    8000139a:	99c080e7          	jalr	-1636(ra) # 80000d32 <memmove>
}
    8000139e:	70a2                	ld	ra,40(sp)
    800013a0:	7402                	ld	s0,32(sp)
    800013a2:	64e2                	ld	s1,24(sp)
    800013a4:	6942                	ld	s2,16(sp)
    800013a6:	69a2                	ld	s3,8(sp)
    800013a8:	6a02                	ld	s4,0(sp)
    800013aa:	6145                	addi	sp,sp,48
    800013ac:	8082                	ret
    panic("inituvm: more than a page");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d9250513          	addi	a0,a0,-622 # 80008140 <digits+0x100>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	17a080e7          	jalr	378(ra) # 80000530 <panic>

00000000800013be <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013c8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013ca:	00b67d63          	bgeu	a2,a1,800013e4 <uvmdealloc+0x26>
    800013ce:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013d0:	6785                	lui	a5,0x1
    800013d2:	17fd                	addi	a5,a5,-1
    800013d4:	00f60733          	add	a4,a2,a5
    800013d8:	767d                	lui	a2,0xfffff
    800013da:	8f71                	and	a4,a4,a2
    800013dc:	97ae                	add	a5,a5,a1
    800013de:	8ff1                	and	a5,a5,a2
    800013e0:	00f76863          	bltu	a4,a5,800013f0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013e4:	8526                	mv	a0,s1
    800013e6:	60e2                	ld	ra,24(sp)
    800013e8:	6442                	ld	s0,16(sp)
    800013ea:	64a2                	ld	s1,8(sp)
    800013ec:	6105                	addi	sp,sp,32
    800013ee:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013f0:	8f99                	sub	a5,a5,a4
    800013f2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013f4:	4685                	li	a3,1
    800013f6:	0007861b          	sext.w	a2,a5
    800013fa:	85ba                	mv	a1,a4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	e5e080e7          	jalr	-418(ra) # 8000125a <uvmunmap>
    80001404:	b7c5                	j	800013e4 <uvmdealloc+0x26>

0000000080001406 <uvmalloc>:
  if(newsz < oldsz)
    80001406:	0ab66163          	bltu	a2,a1,800014a8 <uvmalloc+0xa2>
{
    8000140a:	7139                	addi	sp,sp,-64
    8000140c:	fc06                	sd	ra,56(sp)
    8000140e:	f822                	sd	s0,48(sp)
    80001410:	f426                	sd	s1,40(sp)
    80001412:	f04a                	sd	s2,32(sp)
    80001414:	ec4e                	sd	s3,24(sp)
    80001416:	e852                	sd	s4,16(sp)
    80001418:	e456                	sd	s5,8(sp)
    8000141a:	0080                	addi	s0,sp,64
    8000141c:	8aaa                	mv	s5,a0
    8000141e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001420:	6985                	lui	s3,0x1
    80001422:	19fd                	addi	s3,s3,-1
    80001424:	95ce                	add	a1,a1,s3
    80001426:	79fd                	lui	s3,0xfffff
    80001428:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000142c:	08c9f063          	bgeu	s3,a2,800014ac <uvmalloc+0xa6>
    80001430:	894e                	mv	s2,s3
    mem = kalloc();
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	6b4080e7          	jalr	1716(ra) # 80000ae6 <kalloc>
    8000143a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000143c:	c51d                	beqz	a0,8000146a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000143e:	6605                	lui	a2,0x1
    80001440:	4581                	li	a1,0
    80001442:	00000097          	auipc	ra,0x0
    80001446:	890080e7          	jalr	-1904(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000144a:	4779                	li	a4,30
    8000144c:	86a6                	mv	a3,s1
    8000144e:	6605                	lui	a2,0x1
    80001450:	85ca                	mv	a1,s2
    80001452:	8556                	mv	a0,s5
    80001454:	00000097          	auipc	ra,0x0
    80001458:	c52080e7          	jalr	-942(ra) # 800010a6 <mappages>
    8000145c:	e905                	bnez	a0,8000148c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000145e:	6785                	lui	a5,0x1
    80001460:	993e                	add	s2,s2,a5
    80001462:	fd4968e3          	bltu	s2,s4,80001432 <uvmalloc+0x2c>
  return newsz;
    80001466:	8552                	mv	a0,s4
    80001468:	a809                	j	8000147a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000146a:	864e                	mv	a2,s3
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	f4e080e7          	jalr	-178(ra) # 800013be <uvmdealloc>
      return 0;
    80001478:	4501                	li	a0,0
}
    8000147a:	70e2                	ld	ra,56(sp)
    8000147c:	7442                	ld	s0,48(sp)
    8000147e:	74a2                	ld	s1,40(sp)
    80001480:	7902                	ld	s2,32(sp)
    80001482:	69e2                	ld	s3,24(sp)
    80001484:	6a42                	ld	s4,16(sp)
    80001486:	6aa2                	ld	s5,8(sp)
    80001488:	6121                	addi	sp,sp,64
    8000148a:	8082                	ret
      kfree(mem);
    8000148c:	8526                	mv	a0,s1
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	55c080e7          	jalr	1372(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f22080e7          	jalr	-222(ra) # 800013be <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
    800014a6:	bfd1                	j	8000147a <uvmalloc+0x74>
    return oldsz;
    800014a8:	852e                	mv	a0,a1
}
    800014aa:	8082                	ret
  return newsz;
    800014ac:	8532                	mv	a0,a2
    800014ae:	b7f1                	j	8000147a <uvmalloc+0x74>

00000000800014b0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014b0:	7179                	addi	sp,sp,-48
    800014b2:	f406                	sd	ra,40(sp)
    800014b4:	f022                	sd	s0,32(sp)
    800014b6:	ec26                	sd	s1,24(sp)
    800014b8:	e84a                	sd	s2,16(sp)
    800014ba:	e44e                	sd	s3,8(sp)
    800014bc:	e052                	sd	s4,0(sp)
    800014be:	1800                	addi	s0,sp,48
    800014c0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014c2:	84aa                	mv	s1,a0
    800014c4:	6905                	lui	s2,0x1
    800014c6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014c8:	4985                	li	s3,1
    800014ca:	a821                	j	800014e2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014cc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ce:	0532                	slli	a0,a0,0xc
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	fe0080e7          	jalr	-32(ra) # 800014b0 <freewalk>
      pagetable[i] = 0;
    800014d8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014dc:	04a1                	addi	s1,s1,8
    800014de:	03248163          	beq	s1,s2,80001500 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014e2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	00f57793          	andi	a5,a0,15
    800014e8:	ff3782e3          	beq	a5,s3,800014cc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014ec:	8905                	andi	a0,a0,1
    800014ee:	d57d                	beqz	a0,800014dc <freewalk+0x2c>
      panic("freewalk: leaf");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c7050513          	addi	a0,a0,-912 # 80008160 <digits+0x120>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	038080e7          	jalr	56(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    80001500:	8552                	mv	a0,s4
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	4e8080e7          	jalr	1256(ra) # 800009ea <kfree>
}
    8000150a:	70a2                	ld	ra,40(sp)
    8000150c:	7402                	ld	s0,32(sp)
    8000150e:	64e2                	ld	s1,24(sp)
    80001510:	6942                	ld	s2,16(sp)
    80001512:	69a2                	ld	s3,8(sp)
    80001514:	6a02                	ld	s4,0(sp)
    80001516:	6145                	addi	sp,sp,48
    80001518:	8082                	ret

000000008000151a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000151a:	1101                	addi	sp,sp,-32
    8000151c:	ec06                	sd	ra,24(sp)
    8000151e:	e822                	sd	s0,16(sp)
    80001520:	e426                	sd	s1,8(sp)
    80001522:	1000                	addi	s0,sp,32
    80001524:	84aa                	mv	s1,a0
  if(sz > 0)
    80001526:	e999                	bnez	a1,8000153c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001528:	8526                	mv	a0,s1
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f86080e7          	jalr	-122(ra) # 800014b0 <freewalk>
}
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000153c:	6605                	lui	a2,0x1
    8000153e:	167d                	addi	a2,a2,-1
    80001540:	962e                	add	a2,a2,a1
    80001542:	4685                	li	a3,1
    80001544:	8231                	srli	a2,a2,0xc
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	d12080e7          	jalr	-750(ra) # 8000125a <uvmunmap>
    80001550:	bfe1                	j	80001528 <uvmfree+0xe>

0000000080001552 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001552:	c679                	beqz	a2,80001620 <uvmcopy+0xce>
{
    80001554:	715d                	addi	sp,sp,-80
    80001556:	e486                	sd	ra,72(sp)
    80001558:	e0a2                	sd	s0,64(sp)
    8000155a:	fc26                	sd	s1,56(sp)
    8000155c:	f84a                	sd	s2,48(sp)
    8000155e:	f44e                	sd	s3,40(sp)
    80001560:	f052                	sd	s4,32(sp)
    80001562:	ec56                	sd	s5,24(sp)
    80001564:	e85a                	sd	s6,16(sp)
    80001566:	e45e                	sd	s7,8(sp)
    80001568:	0880                	addi	s0,sp,80
    8000156a:	8b2a                	mv	s6,a0
    8000156c:	8aae                	mv	s5,a1
    8000156e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001570:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001572:	4601                	li	a2,0
    80001574:	85ce                	mv	a1,s3
    80001576:	855a                	mv	a0,s6
    80001578:	00000097          	auipc	ra,0x0
    8000157c:	a46080e7          	jalr	-1466(ra) # 80000fbe <walk>
    80001580:	c531                	beqz	a0,800015cc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001582:	6118                	ld	a4,0(a0)
    80001584:	00177793          	andi	a5,a4,1
    80001588:	cbb1                	beqz	a5,800015dc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000158a:	00a75593          	srli	a1,a4,0xa
    8000158e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001592:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001596:	fffff097          	auipc	ra,0xfffff
    8000159a:	550080e7          	jalr	1360(ra) # 80000ae6 <kalloc>
    8000159e:	892a                	mv	s2,a0
    800015a0:	c939                	beqz	a0,800015f6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015a2:	6605                	lui	a2,0x1
    800015a4:	85de                	mv	a1,s7
    800015a6:	fffff097          	auipc	ra,0xfffff
    800015aa:	78c080e7          	jalr	1932(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ae:	8726                	mv	a4,s1
    800015b0:	86ca                	mv	a3,s2
    800015b2:	6605                	lui	a2,0x1
    800015b4:	85ce                	mv	a1,s3
    800015b6:	8556                	mv	a0,s5
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	aee080e7          	jalr	-1298(ra) # 800010a6 <mappages>
    800015c0:	e515                	bnez	a0,800015ec <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015c2:	6785                	lui	a5,0x1
    800015c4:	99be                	add	s3,s3,a5
    800015c6:	fb49e6e3          	bltu	s3,s4,80001572 <uvmcopy+0x20>
    800015ca:	a081                	j	8000160a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015cc:	00007517          	auipc	a0,0x7
    800015d0:	ba450513          	addi	a0,a0,-1116 # 80008170 <digits+0x130>
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	f5c080e7          	jalr	-164(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    800015dc:	00007517          	auipc	a0,0x7
    800015e0:	bb450513          	addi	a0,a0,-1100 # 80008190 <digits+0x150>
    800015e4:	fffff097          	auipc	ra,0xfffff
    800015e8:	f4c080e7          	jalr	-180(ra) # 80000530 <panic>
      kfree(mem);
    800015ec:	854a                	mv	a0,s2
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	3fc080e7          	jalr	1020(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800015f6:	4685                	li	a3,1
    800015f8:	00c9d613          	srli	a2,s3,0xc
    800015fc:	4581                	li	a1,0
    800015fe:	8556                	mv	a0,s5
    80001600:	00000097          	auipc	ra,0x0
    80001604:	c5a080e7          	jalr	-934(ra) # 8000125a <uvmunmap>
  return -1;
    80001608:	557d                	li	a0,-1
}
    8000160a:	60a6                	ld	ra,72(sp)
    8000160c:	6406                	ld	s0,64(sp)
    8000160e:	74e2                	ld	s1,56(sp)
    80001610:	7942                	ld	s2,48(sp)
    80001612:	79a2                	ld	s3,40(sp)
    80001614:	7a02                	ld	s4,32(sp)
    80001616:	6ae2                	ld	s5,24(sp)
    80001618:	6b42                	ld	s6,16(sp)
    8000161a:	6ba2                	ld	s7,8(sp)
    8000161c:	6161                	addi	sp,sp,80
    8000161e:	8082                	ret
  return 0;
    80001620:	4501                	li	a0,0
}
    80001622:	8082                	ret

0000000080001624 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001624:	1141                	addi	sp,sp,-16
    80001626:	e406                	sd	ra,8(sp)
    80001628:	e022                	sd	s0,0(sp)
    8000162a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000162c:	4601                	li	a2,0
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	990080e7          	jalr	-1648(ra) # 80000fbe <walk>
  if(pte == 0)
    80001636:	c901                	beqz	a0,80001646 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001638:	611c                	ld	a5,0(a0)
    8000163a:	9bbd                	andi	a5,a5,-17
    8000163c:	e11c                	sd	a5,0(a0)
}
    8000163e:	60a2                	ld	ra,8(sp)
    80001640:	6402                	ld	s0,0(sp)
    80001642:	0141                	addi	sp,sp,16
    80001644:	8082                	ret
    panic("uvmclear");
    80001646:	00007517          	auipc	a0,0x7
    8000164a:	b6a50513          	addi	a0,a0,-1174 # 800081b0 <digits+0x170>
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	ee2080e7          	jalr	-286(ra) # 80000530 <panic>

0000000080001656 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001656:	c6bd                	beqz	a3,800016c4 <copyout+0x6e>
{
    80001658:	715d                	addi	sp,sp,-80
    8000165a:	e486                	sd	ra,72(sp)
    8000165c:	e0a2                	sd	s0,64(sp)
    8000165e:	fc26                	sd	s1,56(sp)
    80001660:	f84a                	sd	s2,48(sp)
    80001662:	f44e                	sd	s3,40(sp)
    80001664:	f052                	sd	s4,32(sp)
    80001666:	ec56                	sd	s5,24(sp)
    80001668:	e85a                	sd	s6,16(sp)
    8000166a:	e45e                	sd	s7,8(sp)
    8000166c:	e062                	sd	s8,0(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8b2a                	mv	s6,a0
    80001672:	8c2e                	mv	s8,a1
    80001674:	8a32                	mv	s4,a2
    80001676:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001678:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000167a:	6a85                	lui	s5,0x1
    8000167c:	a015                	j	800016a0 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000167e:	9562                	add	a0,a0,s8
    80001680:	0004861b          	sext.w	a2,s1
    80001684:	85d2                	mv	a1,s4
    80001686:	41250533          	sub	a0,a0,s2
    8000168a:	fffff097          	auipc	ra,0xfffff
    8000168e:	6a8080e7          	jalr	1704(ra) # 80000d32 <memmove>

    len -= n;
    80001692:	409989b3          	sub	s3,s3,s1
    src += n;
    80001696:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001698:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000169c:	02098263          	beqz	s3,800016c0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016a0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016a4:	85ca                	mv	a1,s2
    800016a6:	855a                	mv	a0,s6
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	9bc080e7          	jalr	-1604(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800016b0:	cd01                	beqz	a0,800016c8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016b2:	418904b3          	sub	s1,s2,s8
    800016b6:	94d6                	add	s1,s1,s5
    if(n > len)
    800016b8:	fc99f3e3          	bgeu	s3,s1,8000167e <copyout+0x28>
    800016bc:	84ce                	mv	s1,s3
    800016be:	b7c1                	j	8000167e <copyout+0x28>
  }
  return 0;
    800016c0:	4501                	li	a0,0
    800016c2:	a021                	j	800016ca <copyout+0x74>
    800016c4:	4501                	li	a0,0
}
    800016c6:	8082                	ret
      return -1;
    800016c8:	557d                	li	a0,-1
}
    800016ca:	60a6                	ld	ra,72(sp)
    800016cc:	6406                	ld	s0,64(sp)
    800016ce:	74e2                	ld	s1,56(sp)
    800016d0:	7942                	ld	s2,48(sp)
    800016d2:	79a2                	ld	s3,40(sp)
    800016d4:	7a02                	ld	s4,32(sp)
    800016d6:	6ae2                	ld	s5,24(sp)
    800016d8:	6b42                	ld	s6,16(sp)
    800016da:	6ba2                	ld	s7,8(sp)
    800016dc:	6c02                	ld	s8,0(sp)
    800016de:	6161                	addi	sp,sp,80
    800016e0:	8082                	ret

00000000800016e2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyin+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8a2e                	mv	s4,a1
    80001700:	8c32                	mv	s8,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	412505b3          	sub	a1,a0,s2
    80001714:	8552                	mv	a0,s4
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	61c080e7          	jalr	1564(ra) # 80000d32 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001722:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	930080e7          	jalr	-1744(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyin+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyin+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyin+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000176e:	c6c5                	beqz	a3,80001816 <copyinstr+0xa8>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	0880                	addi	s0,sp,80
    80001786:	8a2a                	mv	s4,a0
    80001788:	8b2e                	mv	s6,a1
    8000178a:	8bb2                	mv	s7,a2
    8000178c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000178e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001790:	6985                	lui	s3,0x1
    80001792:	a035                	j	800017be <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001794:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001798:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000179a:	0017b793          	seqz	a5,a5
    8000179e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6161                	addi	sp,sp,80
    800017b6:	8082                	ret
    srcva = va0 + PGSIZE;
    800017b8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017bc:	c8a9                	beqz	s1,8000180e <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017be:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017c2:	85ca                	mv	a1,s2
    800017c4:	8552                	mv	a0,s4
    800017c6:	00000097          	auipc	ra,0x0
    800017ca:	89e080e7          	jalr	-1890(ra) # 80001064 <walkaddr>
    if(pa0 == 0)
    800017ce:	c131                	beqz	a0,80001812 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d0:	41790833          	sub	a6,s2,s7
    800017d4:	984e                	add	a6,a6,s3
    if(n > max)
    800017d6:	0104f363          	bgeu	s1,a6,800017dc <copyinstr+0x6e>
    800017da:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017dc:	955e                	add	a0,a0,s7
    800017de:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017e2:	fc080be3          	beqz	a6,800017b8 <copyinstr+0x4a>
    800017e6:	985a                	add	a6,a6,s6
    800017e8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017ea:	41650633          	sub	a2,a0,s6
    800017ee:	14fd                	addi	s1,s1,-1
    800017f0:	9b26                	add	s6,s6,s1
    800017f2:	00f60733          	add	a4,a2,a5
    800017f6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffde000>
    800017fa:	df49                	beqz	a4,80001794 <copyinstr+0x26>
        *dst = *p;
    800017fc:	00e78023          	sb	a4,0(a5)
      --max;
    80001800:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001804:	0785                	addi	a5,a5,1
    while(n > 0){
    80001806:	ff0796e3          	bne	a5,a6,800017f2 <copyinstr+0x84>
      dst++;
    8000180a:	8b42                	mv	s6,a6
    8000180c:	b775                	j	800017b8 <copyinstr+0x4a>
    8000180e:	4781                	li	a5,0
    80001810:	b769                	j	8000179a <copyinstr+0x2c>
      return -1;
    80001812:	557d                	li	a0,-1
    80001814:	b779                	j	800017a2 <copyinstr+0x34>
  int got_null = 0;
    80001816:	4781                	li	a5,0
  if(got_null){
    80001818:	0017b793          	seqz	a5,a5
    8000181c:	40f00533          	neg	a0,a5
}
    80001820:	8082                	ret

0000000080001822 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001822:	1101                	addi	sp,sp,-32
    80001824:	ec06                	sd	ra,24(sp)
    80001826:	e822                	sd	s0,16(sp)
    80001828:	e426                	sd	s1,8(sp)
    8000182a:	1000                	addi	s0,sp,32
    8000182c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000182e:	fffff097          	auipc	ra,0xfffff
    80001832:	32e080e7          	jalr	814(ra) # 80000b5c <holding>
    80001836:	c909                	beqz	a0,80001848 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001838:	749c                	ld	a5,40(s1)
    8000183a:	00978f63          	beq	a5,s1,80001858 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000183e:	60e2                	ld	ra,24(sp)
    80001840:	6442                	ld	s0,16(sp)
    80001842:	64a2                	ld	s1,8(sp)
    80001844:	6105                	addi	sp,sp,32
    80001846:	8082                	ret
    panic("wakeup1");
    80001848:	00007517          	auipc	a0,0x7
    8000184c:	97850513          	addi	a0,a0,-1672 # 800081c0 <digits+0x180>
    80001850:	fffff097          	auipc	ra,0xfffff
    80001854:	ce0080e7          	jalr	-800(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001858:	4c98                	lw	a4,24(s1)
    8000185a:	4785                	li	a5,1
    8000185c:	fef711e3          	bne	a4,a5,8000183e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001860:	4789                	li	a5,2
    80001862:	cc9c                	sw	a5,24(s1)
}
    80001864:	bfe9                	j	8000183e <wakeup1+0x1c>

0000000080001866 <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    80001866:	7139                	addi	sp,sp,-64
    80001868:	fc06                	sd	ra,56(sp)
    8000186a:	f822                	sd	s0,48(sp)
    8000186c:	f426                	sd	s1,40(sp)
    8000186e:	f04a                	sd	s2,32(sp)
    80001870:	ec4e                	sd	s3,24(sp)
    80001872:	e852                	sd	s4,16(sp)
    80001874:	e456                	sd	s5,8(sp)
    80001876:	e05a                	sd	s6,0(sp)
    80001878:	0080                	addi	s0,sp,64
    8000187a:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000187c:	00010497          	auipc	s1,0x10
    80001880:	e3c48493          	addi	s1,s1,-452 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80001884:	8b26                	mv	s6,s1
    80001886:	00006a97          	auipc	s5,0x6
    8000188a:	77aa8a93          	addi	s5,s5,1914 # 80008000 <etext>
    8000188e:	04000937          	lui	s2,0x4000
    80001892:	197d                	addi	s2,s2,-1
    80001894:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001896:	00011a17          	auipc	s4,0x11
    8000189a:	c32a0a13          	addi	s4,s4,-974 # 800124c8 <tickslock>
    char *pa = kalloc();
    8000189e:	fffff097          	auipc	ra,0xfffff
    800018a2:	248080e7          	jalr	584(ra) # 80000ae6 <kalloc>
    800018a6:	862a                	mv	a2,a0
    if(pa == 0)
    800018a8:	c131                	beqz	a0,800018ec <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018aa:	416485b3          	sub	a1,s1,s6
    800018ae:	858d                	srai	a1,a1,0x3
    800018b0:	000ab783          	ld	a5,0(s5)
    800018b4:	02f585b3          	mul	a1,a1,a5
    800018b8:	2585                	addiw	a1,a1,1
    800018ba:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018be:	4719                	li	a4,6
    800018c0:	6685                	lui	a3,0x1
    800018c2:	40b905b3          	sub	a1,s2,a1
    800018c6:	854e                	mv	a0,s3
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	86c080e7          	jalr	-1940(ra) # 80001134 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018d0:	16848493          	addi	s1,s1,360
    800018d4:	fd4495e3          	bne	s1,s4,8000189e <proc_mapstacks+0x38>
}
    800018d8:	70e2                	ld	ra,56(sp)
    800018da:	7442                	ld	s0,48(sp)
    800018dc:	74a2                	ld	s1,40(sp)
    800018de:	7902                	ld	s2,32(sp)
    800018e0:	69e2                	ld	s3,24(sp)
    800018e2:	6a42                	ld	s4,16(sp)
    800018e4:	6aa2                	ld	s5,8(sp)
    800018e6:	6b02                	ld	s6,0(sp)
    800018e8:	6121                	addi	sp,sp,64
    800018ea:	8082                	ret
      panic("kalloc");
    800018ec:	00007517          	auipc	a0,0x7
    800018f0:	8dc50513          	addi	a0,a0,-1828 # 800081c8 <digits+0x188>
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	c3c080e7          	jalr	-964(ra) # 80000530 <panic>

00000000800018fc <procinit>:
{
    800018fc:	7139                	addi	sp,sp,-64
    800018fe:	fc06                	sd	ra,56(sp)
    80001900:	f822                	sd	s0,48(sp)
    80001902:	f426                	sd	s1,40(sp)
    80001904:	f04a                	sd	s2,32(sp)
    80001906:	ec4e                	sd	s3,24(sp)
    80001908:	e852                	sd	s4,16(sp)
    8000190a:	e456                	sd	s5,8(sp)
    8000190c:	e05a                	sd	s6,0(sp)
    8000190e:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8c058593          	addi	a1,a1,-1856 # 800081d0 <digits+0x190>
    80001918:	00010517          	auipc	a0,0x10
    8000191c:	98850513          	addi	a0,a0,-1656 # 800112a0 <pid_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	226080e7          	jalr	550(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001928:	00010497          	auipc	s1,0x10
    8000192c:	d9048493          	addi	s1,s1,-624 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    80001930:	00007b17          	auipc	s6,0x7
    80001934:	8a8b0b13          	addi	s6,s6,-1880 # 800081d8 <digits+0x198>
      p->kstack = KSTACK((int) (p - proc));
    80001938:	8aa6                	mv	s5,s1
    8000193a:	00006a17          	auipc	s4,0x6
    8000193e:	6c6a0a13          	addi	s4,s4,1734 # 80008000 <etext>
    80001942:	04000937          	lui	s2,0x4000
    80001946:	197d                	addi	s2,s2,-1
    80001948:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194a:	00011997          	auipc	s3,0x11
    8000194e:	b7e98993          	addi	s3,s3,-1154 # 800124c8 <tickslock>
      initlock(&p->lock, "proc");
    80001952:	85da                	mv	a1,s6
    80001954:	8526                	mv	a0,s1
    80001956:	fffff097          	auipc	ra,0xfffff
    8000195a:	1f0080e7          	jalr	496(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    8000195e:	415487b3          	sub	a5,s1,s5
    80001962:	878d                	srai	a5,a5,0x3
    80001964:	000a3703          	ld	a4,0(s4)
    80001968:	02e787b3          	mul	a5,a5,a4
    8000196c:	2785                	addiw	a5,a5,1
    8000196e:	00d7979b          	slliw	a5,a5,0xd
    80001972:	40f907b3          	sub	a5,s2,a5
    80001976:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001978:	16848493          	addi	s1,s1,360
    8000197c:	fd349be3          	bne	s1,s3,80001952 <procinit+0x56>
}
    80001980:	70e2                	ld	ra,56(sp)
    80001982:	7442                	ld	s0,48(sp)
    80001984:	74a2                	ld	s1,40(sp)
    80001986:	7902                	ld	s2,32(sp)
    80001988:	69e2                	ld	s3,24(sp)
    8000198a:	6a42                	ld	s4,16(sp)
    8000198c:	6aa2                	ld	s5,8(sp)
    8000198e:	6b02                	ld	s6,0(sp)
    80001990:	6121                	addi	sp,sp,64
    80001992:	8082                	ret

0000000080001994 <cpuid>:
{
    80001994:	1141                	addi	sp,sp,-16
    80001996:	e422                	sd	s0,8(sp)
    80001998:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    8000199a:	8512                	mv	a0,tp
}
    8000199c:	2501                	sext.w	a0,a0
    8000199e:	6422                	ld	s0,8(sp)
    800019a0:	0141                	addi	sp,sp,16
    800019a2:	8082                	ret

00000000800019a4 <mycpu>:
mycpu(void) {
    800019a4:	1141                	addi	sp,sp,-16
    800019a6:	e422                	sd	s0,8(sp)
    800019a8:	0800                	addi	s0,sp,16
    800019aa:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ac:	2781                	sext.w	a5,a5
    800019ae:	079e                	slli	a5,a5,0x7
}
    800019b0:	00010517          	auipc	a0,0x10
    800019b4:	90850513          	addi	a0,a0,-1784 # 800112b8 <cpus>
    800019b8:	953e                	add	a0,a0,a5
    800019ba:	6422                	ld	s0,8(sp)
    800019bc:	0141                	addi	sp,sp,16
    800019be:	8082                	ret

00000000800019c0 <myproc>:
myproc(void) {
    800019c0:	1101                	addi	sp,sp,-32
    800019c2:	ec06                	sd	ra,24(sp)
    800019c4:	e822                	sd	s0,16(sp)
    800019c6:	e426                	sd	s1,8(sp)
    800019c8:	1000                	addi	s0,sp,32
  push_off();
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	1c0080e7          	jalr	448(ra) # 80000b8a <push_off>
    800019d2:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800019d4:	2781                	sext.w	a5,a5
    800019d6:	079e                	slli	a5,a5,0x7
    800019d8:	00010717          	auipc	a4,0x10
    800019dc:	8c870713          	addi	a4,a4,-1848 # 800112a0 <pid_lock>
    800019e0:	97ba                	add	a5,a5,a4
    800019e2:	6f84                	ld	s1,24(a5)
  pop_off();
    800019e4:	fffff097          	auipc	ra,0xfffff
    800019e8:	246080e7          	jalr	582(ra) # 80000c2a <pop_off>
}
    800019ec:	8526                	mv	a0,s1
    800019ee:	60e2                	ld	ra,24(sp)
    800019f0:	6442                	ld	s0,16(sp)
    800019f2:	64a2                	ld	s1,8(sp)
    800019f4:	6105                	addi	sp,sp,32
    800019f6:	8082                	ret

00000000800019f8 <forkret>:
{
    800019f8:	1141                	addi	sp,sp,-16
    800019fa:	e406                	sd	ra,8(sp)
    800019fc:	e022                	sd	s0,0(sp)
    800019fe:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a00:	00000097          	auipc	ra,0x0
    80001a04:	fc0080e7          	jalr	-64(ra) # 800019c0 <myproc>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	282080e7          	jalr	642(ra) # 80000c8a <release>
  if (first) {
    80001a10:	00007797          	auipc	a5,0x7
    80001a14:	de07a783          	lw	a5,-544(a5) # 800087f0 <first.1670>
    80001a18:	eb89                	bnez	a5,80001a2a <forkret+0x32>
  usertrapret();
    80001a1a:	00001097          	auipc	ra,0x1
    80001a1e:	c1c080e7          	jalr	-996(ra) # 80002636 <usertrapret>
}
    80001a22:	60a2                	ld	ra,8(sp)
    80001a24:	6402                	ld	s0,0(sp)
    80001a26:	0141                	addi	sp,sp,16
    80001a28:	8082                	ret
    first = 0;
    80001a2a:	00007797          	auipc	a5,0x7
    80001a2e:	dc07a323          	sw	zero,-570(a5) # 800087f0 <first.1670>
    fsinit(ROOTDEV);
    80001a32:	4505                	li	a0,1
    80001a34:	00002097          	auipc	ra,0x2
    80001a38:	a0a080e7          	jalr	-1526(ra) # 8000343e <fsinit>
    80001a3c:	bff9                	j	80001a1a <forkret+0x22>

0000000080001a3e <allocpid>:
allocpid() {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	e04a                	sd	s2,0(sp)
    80001a48:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a4a:	00010917          	auipc	s2,0x10
    80001a4e:	85690913          	addi	s2,s2,-1962 # 800112a0 <pid_lock>
    80001a52:	854a                	mv	a0,s2
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	182080e7          	jalr	386(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a5c:	00007797          	auipc	a5,0x7
    80001a60:	d9878793          	addi	a5,a5,-616 # 800087f4 <nextpid>
    80001a64:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a66:	0014871b          	addiw	a4,s1,1
    80001a6a:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a6c:	854a                	mv	a0,s2
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	21c080e7          	jalr	540(ra) # 80000c8a <release>
}
    80001a76:	8526                	mv	a0,s1
    80001a78:	60e2                	ld	ra,24(sp)
    80001a7a:	6442                	ld	s0,16(sp)
    80001a7c:	64a2                	ld	s1,8(sp)
    80001a7e:	6902                	ld	s2,0(sp)
    80001a80:	6105                	addi	sp,sp,32
    80001a82:	8082                	ret

0000000080001a84 <proc_pagetable>:
{
    80001a84:	1101                	addi	sp,sp,-32
    80001a86:	ec06                	sd	ra,24(sp)
    80001a88:	e822                	sd	s0,16(sp)
    80001a8a:	e426                	sd	s1,8(sp)
    80001a8c:	e04a                	sd	s2,0(sp)
    80001a8e:	1000                	addi	s0,sp,32
    80001a90:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	88c080e7          	jalr	-1908(ra) # 8000131e <uvmcreate>
    80001a9a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a9c:	c121                	beqz	a0,80001adc <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a9e:	4729                	li	a4,10
    80001aa0:	00005697          	auipc	a3,0x5
    80001aa4:	56068693          	addi	a3,a3,1376 # 80007000 <_trampoline>
    80001aa8:	6605                	lui	a2,0x1
    80001aaa:	040005b7          	lui	a1,0x4000
    80001aae:	15fd                	addi	a1,a1,-1
    80001ab0:	05b2                	slli	a1,a1,0xc
    80001ab2:	fffff097          	auipc	ra,0xfffff
    80001ab6:	5f4080e7          	jalr	1524(ra) # 800010a6 <mappages>
    80001aba:	02054863          	bltz	a0,80001aea <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001abe:	4719                	li	a4,6
    80001ac0:	05893683          	ld	a3,88(s2)
    80001ac4:	6605                	lui	a2,0x1
    80001ac6:	020005b7          	lui	a1,0x2000
    80001aca:	15fd                	addi	a1,a1,-1
    80001acc:	05b6                	slli	a1,a1,0xd
    80001ace:	8526                	mv	a0,s1
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	5d6080e7          	jalr	1494(ra) # 800010a6 <mappages>
    80001ad8:	02054163          	bltz	a0,80001afa <proc_pagetable+0x76>
}
    80001adc:	8526                	mv	a0,s1
    80001ade:	60e2                	ld	ra,24(sp)
    80001ae0:	6442                	ld	s0,16(sp)
    80001ae2:	64a2                	ld	s1,8(sp)
    80001ae4:	6902                	ld	s2,0(sp)
    80001ae6:	6105                	addi	sp,sp,32
    80001ae8:	8082                	ret
    uvmfree(pagetable, 0);
    80001aea:	4581                	li	a1,0
    80001aec:	8526                	mv	a0,s1
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	a2c080e7          	jalr	-1492(ra) # 8000151a <uvmfree>
    return 0;
    80001af6:	4481                	li	s1,0
    80001af8:	b7d5                	j	80001adc <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001afa:	4681                	li	a3,0
    80001afc:	4605                	li	a2,1
    80001afe:	040005b7          	lui	a1,0x4000
    80001b02:	15fd                	addi	a1,a1,-1
    80001b04:	05b2                	slli	a1,a1,0xc
    80001b06:	8526                	mv	a0,s1
    80001b08:	fffff097          	auipc	ra,0xfffff
    80001b0c:	752080e7          	jalr	1874(ra) # 8000125a <uvmunmap>
    uvmfree(pagetable, 0);
    80001b10:	4581                	li	a1,0
    80001b12:	8526                	mv	a0,s1
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	a06080e7          	jalr	-1530(ra) # 8000151a <uvmfree>
    return 0;
    80001b1c:	4481                	li	s1,0
    80001b1e:	bf7d                	j	80001adc <proc_pagetable+0x58>

0000000080001b20 <proc_freepagetable>:
{
    80001b20:	1101                	addi	sp,sp,-32
    80001b22:	ec06                	sd	ra,24(sp)
    80001b24:	e822                	sd	s0,16(sp)
    80001b26:	e426                	sd	s1,8(sp)
    80001b28:	e04a                	sd	s2,0(sp)
    80001b2a:	1000                	addi	s0,sp,32
    80001b2c:	84aa                	mv	s1,a0
    80001b2e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	fffff097          	auipc	ra,0xfffff
    80001b40:	71e080e7          	jalr	1822(ra) # 8000125a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b44:	4681                	li	a3,0
    80001b46:	4605                	li	a2,1
    80001b48:	020005b7          	lui	a1,0x2000
    80001b4c:	15fd                	addi	a1,a1,-1
    80001b4e:	05b6                	slli	a1,a1,0xd
    80001b50:	8526                	mv	a0,s1
    80001b52:	fffff097          	auipc	ra,0xfffff
    80001b56:	708080e7          	jalr	1800(ra) # 8000125a <uvmunmap>
  uvmfree(pagetable, sz);
    80001b5a:	85ca                	mv	a1,s2
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	00000097          	auipc	ra,0x0
    80001b62:	9bc080e7          	jalr	-1604(ra) # 8000151a <uvmfree>
}
    80001b66:	60e2                	ld	ra,24(sp)
    80001b68:	6442                	ld	s0,16(sp)
    80001b6a:	64a2                	ld	s1,8(sp)
    80001b6c:	6902                	ld	s2,0(sp)
    80001b6e:	6105                	addi	sp,sp,32
    80001b70:	8082                	ret

0000000080001b72 <freeproc>:
{
    80001b72:	1101                	addi	sp,sp,-32
    80001b74:	ec06                	sd	ra,24(sp)
    80001b76:	e822                	sd	s0,16(sp)
    80001b78:	e426                	sd	s1,8(sp)
    80001b7a:	1000                	addi	s0,sp,32
    80001b7c:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b7e:	6d28                	ld	a0,88(a0)
    80001b80:	c509                	beqz	a0,80001b8a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	e68080e7          	jalr	-408(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b8a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b8e:	68a8                	ld	a0,80(s1)
    80001b90:	c511                	beqz	a0,80001b9c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b92:	64ac                	ld	a1,72(s1)
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	f8c080e7          	jalr	-116(ra) # 80001b20 <proc_freepagetable>
  p->pagetable = 0;
    80001b9c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba0:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ba4:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001ba8:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bac:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb0:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bb4:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bb8:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bbc:	0004ac23          	sw	zero,24(s1)
}
    80001bc0:	60e2                	ld	ra,24(sp)
    80001bc2:	6442                	ld	s0,16(sp)
    80001bc4:	64a2                	ld	s1,8(sp)
    80001bc6:	6105                	addi	sp,sp,32
    80001bc8:	8082                	ret

0000000080001bca <allocproc>:
{
    80001bca:	1101                	addi	sp,sp,-32
    80001bcc:	ec06                	sd	ra,24(sp)
    80001bce:	e822                	sd	s0,16(sp)
    80001bd0:	e426                	sd	s1,8(sp)
    80001bd2:	e04a                	sd	s2,0(sp)
    80001bd4:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd6:	00010497          	auipc	s1,0x10
    80001bda:	ae248493          	addi	s1,s1,-1310 # 800116b8 <proc>
    80001bde:	00011917          	auipc	s2,0x11
    80001be2:	8ea90913          	addi	s2,s2,-1814 # 800124c8 <tickslock>
    acquire(&p->lock);
    80001be6:	8526                	mv	a0,s1
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	fee080e7          	jalr	-18(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bf0:	4c9c                	lw	a5,24(s1)
    80001bf2:	c395                	beqz	a5,80001c16 <allocproc+0x4c>
      release(&p->lock);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	094080e7          	jalr	148(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfe:	16848493          	addi	s1,s1,360
    80001c02:	ff2492e3          	bne	s1,s2,80001be6 <allocproc+0x1c>
  return 0;
    80001c06:	4481                	li	s1,0
}
    80001c08:	8526                	mv	a0,s1
    80001c0a:	60e2                	ld	ra,24(sp)
    80001c0c:	6442                	ld	s0,16(sp)
    80001c0e:	64a2                	ld	s1,8(sp)
    80001c10:	6902                	ld	s2,0(sp)
    80001c12:	6105                	addi	sp,sp,32
    80001c14:	8082                	ret
  p->pid = allocpid();
    80001c16:	00000097          	auipc	ra,0x0
    80001c1a:	e28080e7          	jalr	-472(ra) # 80001a3e <allocpid>
    80001c1e:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	ec6080e7          	jalr	-314(ra) # 80000ae6 <kalloc>
    80001c28:	892a                	mv	s2,a0
    80001c2a:	eca8                	sd	a0,88(s1)
    80001c2c:	cd05                	beqz	a0,80001c64 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	e54080e7          	jalr	-428(ra) # 80001a84 <proc_pagetable>
    80001c38:	892a                	mv	s2,a0
    80001c3a:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3c:	c91d                	beqz	a0,80001c72 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c3e:	07000613          	li	a2,112
    80001c42:	4581                	li	a1,0
    80001c44:	06048513          	addi	a0,s1,96
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	08a080e7          	jalr	138(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c50:	00000797          	auipc	a5,0x0
    80001c54:	da878793          	addi	a5,a5,-600 # 800019f8 <forkret>
    80001c58:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c5a:	60bc                	ld	a5,64(s1)
    80001c5c:	6705                	lui	a4,0x1
    80001c5e:	97ba                	add	a5,a5,a4
    80001c60:	f4bc                	sd	a5,104(s1)
  return p;
    80001c62:	b75d                	j	80001c08 <allocproc+0x3e>
    release(&p->lock);
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	024080e7          	jalr	36(ra) # 80000c8a <release>
    return 0;
    80001c6e:	84ca                	mv	s1,s2
    80001c70:	bf61                	j	80001c08 <allocproc+0x3e>
    freeproc(p);
    80001c72:	8526                	mv	a0,s1
    80001c74:	00000097          	auipc	ra,0x0
    80001c78:	efe080e7          	jalr	-258(ra) # 80001b72 <freeproc>
    release(&p->lock);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	00c080e7          	jalr	12(ra) # 80000c8a <release>
    return 0;
    80001c86:	84ca                	mv	s1,s2
    80001c88:	b741                	j	80001c08 <allocproc+0x3e>

0000000080001c8a <userinit>:
{
    80001c8a:	1101                	addi	sp,sp,-32
    80001c8c:	ec06                	sd	ra,24(sp)
    80001c8e:	e822                	sd	s0,16(sp)
    80001c90:	e426                	sd	s1,8(sp)
    80001c92:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c94:	00000097          	auipc	ra,0x0
    80001c98:	f36080e7          	jalr	-202(ra) # 80001bca <allocproc>
    80001c9c:	84aa                	mv	s1,a0
  initproc = p;
    80001c9e:	00007797          	auipc	a5,0x7
    80001ca2:	38a7b523          	sd	a0,906(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001ca6:	03400613          	li	a2,52
    80001caa:	00007597          	auipc	a1,0x7
    80001cae:	b5658593          	addi	a1,a1,-1194 # 80008800 <initcode>
    80001cb2:	6928                	ld	a0,80(a0)
    80001cb4:	fffff097          	auipc	ra,0xfffff
    80001cb8:	698080e7          	jalr	1688(ra) # 8000134c <uvminit>
  p->sz = PGSIZE;
    80001cbc:	6785                	lui	a5,0x1
    80001cbe:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc6:	6cb8                	ld	a4,88(s1)
    80001cc8:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cca:	4641                	li	a2,16
    80001ccc:	00006597          	auipc	a1,0x6
    80001cd0:	51458593          	addi	a1,a1,1300 # 800081e0 <digits+0x1a0>
    80001cd4:	15848513          	addi	a0,s1,344
    80001cd8:	fffff097          	auipc	ra,0xfffff
    80001cdc:	150080e7          	jalr	336(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001ce0:	00006517          	auipc	a0,0x6
    80001ce4:	51050513          	addi	a0,a0,1296 # 800081f0 <digits+0x1b0>
    80001ce8:	00002097          	auipc	ra,0x2
    80001cec:	22c080e7          	jalr	556(ra) # 80003f14 <namei>
    80001cf0:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cf4:	4789                	li	a5,2
    80001cf6:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	f90080e7          	jalr	-112(ra) # 80000c8a <release>
}
    80001d02:	60e2                	ld	ra,24(sp)
    80001d04:	6442                	ld	s0,16(sp)
    80001d06:	64a2                	ld	s1,8(sp)
    80001d08:	6105                	addi	sp,sp,32
    80001d0a:	8082                	ret

0000000080001d0c <growproc>:
{
    80001d0c:	1101                	addi	sp,sp,-32
    80001d0e:	ec06                	sd	ra,24(sp)
    80001d10:	e822                	sd	s0,16(sp)
    80001d12:	e426                	sd	s1,8(sp)
    80001d14:	e04a                	sd	s2,0(sp)
    80001d16:	1000                	addi	s0,sp,32
    80001d18:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d1a:	00000097          	auipc	ra,0x0
    80001d1e:	ca6080e7          	jalr	-858(ra) # 800019c0 <myproc>
    80001d22:	892a                	mv	s2,a0
  sz = p->sz;
    80001d24:	652c                	ld	a1,72(a0)
    80001d26:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d2a:	00904f63          	bgtz	s1,80001d48 <growproc+0x3c>
  } else if(n < 0){
    80001d2e:	0204cc63          	bltz	s1,80001d66 <growproc+0x5a>
  p->sz = sz;
    80001d32:	1602                	slli	a2,a2,0x20
    80001d34:	9201                	srli	a2,a2,0x20
    80001d36:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d3a:	4501                	li	a0,0
}
    80001d3c:	60e2                	ld	ra,24(sp)
    80001d3e:	6442                	ld	s0,16(sp)
    80001d40:	64a2                	ld	s1,8(sp)
    80001d42:	6902                	ld	s2,0(sp)
    80001d44:	6105                	addi	sp,sp,32
    80001d46:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d48:	9e25                	addw	a2,a2,s1
    80001d4a:	1602                	slli	a2,a2,0x20
    80001d4c:	9201                	srli	a2,a2,0x20
    80001d4e:	1582                	slli	a1,a1,0x20
    80001d50:	9181                	srli	a1,a1,0x20
    80001d52:	6928                	ld	a0,80(a0)
    80001d54:	fffff097          	auipc	ra,0xfffff
    80001d58:	6b2080e7          	jalr	1714(ra) # 80001406 <uvmalloc>
    80001d5c:	0005061b          	sext.w	a2,a0
    80001d60:	fa69                	bnez	a2,80001d32 <growproc+0x26>
      return -1;
    80001d62:	557d                	li	a0,-1
    80001d64:	bfe1                	j	80001d3c <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d66:	9e25                	addw	a2,a2,s1
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	1582                	slli	a1,a1,0x20
    80001d6e:	9181                	srli	a1,a1,0x20
    80001d70:	6928                	ld	a0,80(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	64c080e7          	jalr	1612(ra) # 800013be <uvmdealloc>
    80001d7a:	0005061b          	sext.w	a2,a0
    80001d7e:	bf55                	j	80001d32 <growproc+0x26>

0000000080001d80 <fork>:
{
    80001d80:	7179                	addi	sp,sp,-48
    80001d82:	f406                	sd	ra,40(sp)
    80001d84:	f022                	sd	s0,32(sp)
    80001d86:	ec26                	sd	s1,24(sp)
    80001d88:	e84a                	sd	s2,16(sp)
    80001d8a:	e44e                	sd	s3,8(sp)
    80001d8c:	e052                	sd	s4,0(sp)
    80001d8e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d90:	00000097          	auipc	ra,0x0
    80001d94:	c30080e7          	jalr	-976(ra) # 800019c0 <myproc>
    80001d98:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	e30080e7          	jalr	-464(ra) # 80001bca <allocproc>
    80001da2:	c175                	beqz	a0,80001e86 <fork+0x106>
    80001da4:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da6:	04893603          	ld	a2,72(s2)
    80001daa:	692c                	ld	a1,80(a0)
    80001dac:	05093503          	ld	a0,80(s2)
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	7a2080e7          	jalr	1954(ra) # 80001552 <uvmcopy>
    80001db8:	04054863          	bltz	a0,80001e08 <fork+0x88>
  np->sz = p->sz;
    80001dbc:	04893783          	ld	a5,72(s2)
    80001dc0:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001dc4:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc8:	05893683          	ld	a3,88(s2)
    80001dcc:	87b6                	mv	a5,a3
    80001dce:	0589b703          	ld	a4,88(s3)
    80001dd2:	12068693          	addi	a3,a3,288
    80001dd6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dda:	6788                	ld	a0,8(a5)
    80001ddc:	6b8c                	ld	a1,16(a5)
    80001dde:	6f90                	ld	a2,24(a5)
    80001de0:	01073023          	sd	a6,0(a4)
    80001de4:	e708                	sd	a0,8(a4)
    80001de6:	eb0c                	sd	a1,16(a4)
    80001de8:	ef10                	sd	a2,24(a4)
    80001dea:	02078793          	addi	a5,a5,32
    80001dee:	02070713          	addi	a4,a4,32
    80001df2:	fed792e3          	bne	a5,a3,80001dd6 <fork+0x56>
  np->trapframe->a0 = 0;
    80001df6:	0589b783          	ld	a5,88(s3)
    80001dfa:	0607b823          	sd	zero,112(a5)
    80001dfe:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e02:	15000a13          	li	s4,336
    80001e06:	a03d                	j	80001e34 <fork+0xb4>
    freeproc(np);
    80001e08:	854e                	mv	a0,s3
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	d68080e7          	jalr	-664(ra) # 80001b72 <freeproc>
    release(&np->lock);
    80001e12:	854e                	mv	a0,s3
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	e76080e7          	jalr	-394(ra) # 80000c8a <release>
    return -1;
    80001e1c:	54fd                	li	s1,-1
    80001e1e:	a899                	j	80001e74 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e20:	00002097          	auipc	ra,0x2
    80001e24:	792080e7          	jalr	1938(ra) # 800045b2 <filedup>
    80001e28:	009987b3          	add	a5,s3,s1
    80001e2c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2e:	04a1                	addi	s1,s1,8
    80001e30:	01448763          	beq	s1,s4,80001e3e <fork+0xbe>
    if(p->ofile[i])
    80001e34:	009907b3          	add	a5,s2,s1
    80001e38:	6388                	ld	a0,0(a5)
    80001e3a:	f17d                	bnez	a0,80001e20 <fork+0xa0>
    80001e3c:	bfcd                	j	80001e2e <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e3e:	15093503          	ld	a0,336(s2)
    80001e42:	00002097          	auipc	ra,0x2
    80001e46:	836080e7          	jalr	-1994(ra) # 80003678 <idup>
    80001e4a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e4e:	4641                	li	a2,16
    80001e50:	15890593          	addi	a1,s2,344
    80001e54:	15898513          	addi	a0,s3,344
    80001e58:	fffff097          	auipc	ra,0xfffff
    80001e5c:	fd0080e7          	jalr	-48(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    80001e60:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001e64:	4789                	li	a5,2
    80001e66:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e6a:	854e                	mv	a0,s3
    80001e6c:	fffff097          	auipc	ra,0xfffff
    80001e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
}
    80001e74:	8526                	mv	a0,s1
    80001e76:	70a2                	ld	ra,40(sp)
    80001e78:	7402                	ld	s0,32(sp)
    80001e7a:	64e2                	ld	s1,24(sp)
    80001e7c:	6942                	ld	s2,16(sp)
    80001e7e:	69a2                	ld	s3,8(sp)
    80001e80:	6a02                	ld	s4,0(sp)
    80001e82:	6145                	addi	sp,sp,48
    80001e84:	8082                	ret
    return -1;
    80001e86:	54fd                	li	s1,-1
    80001e88:	b7f5                	j	80001e74 <fork+0xf4>

0000000080001e8a <reparent>:
{
    80001e8a:	7179                	addi	sp,sp,-48
    80001e8c:	f406                	sd	ra,40(sp)
    80001e8e:	f022                	sd	s0,32(sp)
    80001e90:	ec26                	sd	s1,24(sp)
    80001e92:	e84a                	sd	s2,16(sp)
    80001e94:	e44e                	sd	s3,8(sp)
    80001e96:	e052                	sd	s4,0(sp)
    80001e98:	1800                	addi	s0,sp,48
    80001e9a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001e9c:	00010497          	auipc	s1,0x10
    80001ea0:	81c48493          	addi	s1,s1,-2020 # 800116b8 <proc>
      pp->parent = initproc;
    80001ea4:	00007a17          	auipc	s4,0x7
    80001ea8:	184a0a13          	addi	s4,s4,388 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eac:	00010997          	auipc	s3,0x10
    80001eb0:	61c98993          	addi	s3,s3,1564 # 800124c8 <tickslock>
    80001eb4:	a029                	j	80001ebe <reparent+0x34>
    80001eb6:	16848493          	addi	s1,s1,360
    80001eba:	03348363          	beq	s1,s3,80001ee0 <reparent+0x56>
    if(pp->parent == p){
    80001ebe:	709c                	ld	a5,32(s1)
    80001ec0:	ff279be3          	bne	a5,s2,80001eb6 <reparent+0x2c>
      acquire(&pp->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	d10080e7          	jalr	-752(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    80001ece:	000a3783          	ld	a5,0(s4)
    80001ed2:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
    80001ede:	bfe1                	j	80001eb6 <reparent+0x2c>
}
    80001ee0:	70a2                	ld	ra,40(sp)
    80001ee2:	7402                	ld	s0,32(sp)
    80001ee4:	64e2                	ld	s1,24(sp)
    80001ee6:	6942                	ld	s2,16(sp)
    80001ee8:	69a2                	ld	s3,8(sp)
    80001eea:	6a02                	ld	s4,0(sp)
    80001eec:	6145                	addi	sp,sp,48
    80001eee:	8082                	ret

0000000080001ef0 <scheduler>:
{
    80001ef0:	711d                	addi	sp,sp,-96
    80001ef2:	ec86                	sd	ra,88(sp)
    80001ef4:	e8a2                	sd	s0,80(sp)
    80001ef6:	e4a6                	sd	s1,72(sp)
    80001ef8:	e0ca                	sd	s2,64(sp)
    80001efa:	fc4e                	sd	s3,56(sp)
    80001efc:	f852                	sd	s4,48(sp)
    80001efe:	f456                	sd	s5,40(sp)
    80001f00:	f05a                	sd	s6,32(sp)
    80001f02:	ec5e                	sd	s7,24(sp)
    80001f04:	e862                	sd	s8,16(sp)
    80001f06:	e466                	sd	s9,8(sp)
    80001f08:	1080                	addi	s0,sp,96
    80001f0a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f0c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0e:	00779b93          	slli	s7,a5,0x7
    80001f12:	0000f717          	auipc	a4,0xf
    80001f16:	38e70713          	addi	a4,a4,910 # 800112a0 <pid_lock>
    80001f1a:	975e                	add	a4,a4,s7
    80001f1c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f20:	0000f717          	auipc	a4,0xf
    80001f24:	3a070713          	addi	a4,a4,928 # 800112c0 <cpus+0x8>
    80001f28:	9bba                	add	s7,s7,a4
      if(p->state == RUNNABLE) {
    80001f2a:	4a89                	li	s5,2
        c->proc = p;
    80001f2c:	079e                	slli	a5,a5,0x7
    80001f2e:	0000fb17          	auipc	s6,0xf
    80001f32:	372b0b13          	addi	s6,s6,882 # 800112a0 <pid_lock>
    80001f36:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f38:	00010a17          	auipc	s4,0x10
    80001f3c:	590a0a13          	addi	s4,s4,1424 # 800124c8 <tickslock>
    int nproc = 0;
    80001f40:	4c01                	li	s8,0
    80001f42:	a8a1                	j	80001f9a <scheduler+0xaa>
        p->state = RUNNING;
    80001f44:	0194ac23          	sw	s9,24(s1)
        c->proc = p;
    80001f48:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80001f4c:	06048593          	addi	a1,s1,96
    80001f50:	855e                	mv	a0,s7
    80001f52:	00000097          	auipc	ra,0x0
    80001f56:	63a080e7          	jalr	1594(ra) # 8000258c <swtch>
        c->proc = 0;
    80001f5a:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	d2a080e7          	jalr	-726(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f68:	16848493          	addi	s1,s1,360
    80001f6c:	01448d63          	beq	s1,s4,80001f86 <scheduler+0x96>
      acquire(&p->lock);
    80001f70:	8526                	mv	a0,s1
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	c64080e7          	jalr	-924(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80001f7a:	4c9c                	lw	a5,24(s1)
    80001f7c:	d3ed                	beqz	a5,80001f5e <scheduler+0x6e>
        nproc++;
    80001f7e:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80001f80:	fd579fe3          	bne	a5,s5,80001f5e <scheduler+0x6e>
    80001f84:	b7c1                	j	80001f44 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80001f86:	013aca63          	blt	s5,s3,80001f9a <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f8a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f8e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f92:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001f96:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f9e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fa2:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80001fa6:	89e2                	mv	s3,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fa8:	0000f497          	auipc	s1,0xf
    80001fac:	71048493          	addi	s1,s1,1808 # 800116b8 <proc>
        p->state = RUNNING;
    80001fb0:	4c8d                	li	s9,3
    80001fb2:	bf7d                	j	80001f70 <scheduler+0x80>

0000000080001fb4 <sched>:
{
    80001fb4:	7179                	addi	sp,sp,-48
    80001fb6:	f406                	sd	ra,40(sp)
    80001fb8:	f022                	sd	s0,32(sp)
    80001fba:	ec26                	sd	s1,24(sp)
    80001fbc:	e84a                	sd	s2,16(sp)
    80001fbe:	e44e                	sd	s3,8(sp)
    80001fc0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fc2:	00000097          	auipc	ra,0x0
    80001fc6:	9fe080e7          	jalr	-1538(ra) # 800019c0 <myproc>
    80001fca:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fcc:	fffff097          	auipc	ra,0xfffff
    80001fd0:	b90080e7          	jalr	-1136(ra) # 80000b5c <holding>
    80001fd4:	c93d                	beqz	a0,8000204a <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fd8:	2781                	sext.w	a5,a5
    80001fda:	079e                	slli	a5,a5,0x7
    80001fdc:	0000f717          	auipc	a4,0xf
    80001fe0:	2c470713          	addi	a4,a4,708 # 800112a0 <pid_lock>
    80001fe4:	97ba                	add	a5,a5,a4
    80001fe6:	0907a703          	lw	a4,144(a5)
    80001fea:	4785                	li	a5,1
    80001fec:	06f71763          	bne	a4,a5,8000205a <sched+0xa6>
  if(p->state == RUNNING)
    80001ff0:	4c98                	lw	a4,24(s1)
    80001ff2:	478d                	li	a5,3
    80001ff4:	06f70b63          	beq	a4,a5,8000206a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ffc:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ffe:	efb5                	bnez	a5,8000207a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002000:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002002:	0000f917          	auipc	s2,0xf
    80002006:	29e90913          	addi	s2,s2,670 # 800112a0 <pid_lock>
    8000200a:	2781                	sext.w	a5,a5
    8000200c:	079e                	slli	a5,a5,0x7
    8000200e:	97ca                	add	a5,a5,s2
    80002010:	0947a983          	lw	s3,148(a5)
    80002014:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002016:	2781                	sext.w	a5,a5
    80002018:	079e                	slli	a5,a5,0x7
    8000201a:	0000f597          	auipc	a1,0xf
    8000201e:	2a658593          	addi	a1,a1,678 # 800112c0 <cpus+0x8>
    80002022:	95be                	add	a1,a1,a5
    80002024:	06048513          	addi	a0,s1,96
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	564080e7          	jalr	1380(ra) # 8000258c <swtch>
    80002030:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002032:	2781                	sext.w	a5,a5
    80002034:	079e                	slli	a5,a5,0x7
    80002036:	97ca                	add	a5,a5,s2
    80002038:	0937aa23          	sw	s3,148(a5)
}
    8000203c:	70a2                	ld	ra,40(sp)
    8000203e:	7402                	ld	s0,32(sp)
    80002040:	64e2                	ld	s1,24(sp)
    80002042:	6942                	ld	s2,16(sp)
    80002044:	69a2                	ld	s3,8(sp)
    80002046:	6145                	addi	sp,sp,48
    80002048:	8082                	ret
    panic("sched p->lock");
    8000204a:	00006517          	auipc	a0,0x6
    8000204e:	1ae50513          	addi	a0,a0,430 # 800081f8 <digits+0x1b8>
    80002052:	ffffe097          	auipc	ra,0xffffe
    80002056:	4de080e7          	jalr	1246(ra) # 80000530 <panic>
    panic("sched locks");
    8000205a:	00006517          	auipc	a0,0x6
    8000205e:	1ae50513          	addi	a0,a0,430 # 80008208 <digits+0x1c8>
    80002062:	ffffe097          	auipc	ra,0xffffe
    80002066:	4ce080e7          	jalr	1230(ra) # 80000530 <panic>
    panic("sched running");
    8000206a:	00006517          	auipc	a0,0x6
    8000206e:	1ae50513          	addi	a0,a0,430 # 80008218 <digits+0x1d8>
    80002072:	ffffe097          	auipc	ra,0xffffe
    80002076:	4be080e7          	jalr	1214(ra) # 80000530 <panic>
    panic("sched interruptible");
    8000207a:	00006517          	auipc	a0,0x6
    8000207e:	1ae50513          	addi	a0,a0,430 # 80008228 <digits+0x1e8>
    80002082:	ffffe097          	auipc	ra,0xffffe
    80002086:	4ae080e7          	jalr	1198(ra) # 80000530 <panic>

000000008000208a <exit>:
{
    8000208a:	7179                	addi	sp,sp,-48
    8000208c:	f406                	sd	ra,40(sp)
    8000208e:	f022                	sd	s0,32(sp)
    80002090:	ec26                	sd	s1,24(sp)
    80002092:	e84a                	sd	s2,16(sp)
    80002094:	e44e                	sd	s3,8(sp)
    80002096:	e052                	sd	s4,0(sp)
    80002098:	1800                	addi	s0,sp,48
    8000209a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	924080e7          	jalr	-1756(ra) # 800019c0 <myproc>
    800020a4:	89aa                	mv	s3,a0
  if(p == initproc)
    800020a6:	00007797          	auipc	a5,0x7
    800020aa:	f827b783          	ld	a5,-126(a5) # 80009028 <initproc>
    800020ae:	0d050493          	addi	s1,a0,208
    800020b2:	15050913          	addi	s2,a0,336
    800020b6:	02a79363          	bne	a5,a0,800020dc <exit+0x52>
    panic("init exiting");
    800020ba:	00006517          	auipc	a0,0x6
    800020be:	18650513          	addi	a0,a0,390 # 80008240 <digits+0x200>
    800020c2:	ffffe097          	auipc	ra,0xffffe
    800020c6:	46e080e7          	jalr	1134(ra) # 80000530 <panic>
      fileclose(f);
    800020ca:	00002097          	auipc	ra,0x2
    800020ce:	53a080e7          	jalr	1338(ra) # 80004604 <fileclose>
      p->ofile[fd] = 0;
    800020d2:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800020d6:	04a1                	addi	s1,s1,8
    800020d8:	01248563          	beq	s1,s2,800020e2 <exit+0x58>
    if(p->ofile[fd]){
    800020dc:	6088                	ld	a0,0(s1)
    800020de:	f575                	bnez	a0,800020ca <exit+0x40>
    800020e0:	bfdd                	j	800020d6 <exit+0x4c>
  begin_op();
    800020e2:	00002097          	auipc	ra,0x2
    800020e6:	04e080e7          	jalr	78(ra) # 80004130 <begin_op>
  iput(p->cwd);
    800020ea:	1509b503          	ld	a0,336(s3)
    800020ee:	00002097          	auipc	ra,0x2
    800020f2:	828080e7          	jalr	-2008(ra) # 80003916 <iput>
  end_op();
    800020f6:	00002097          	auipc	ra,0x2
    800020fa:	0ba080e7          	jalr	186(ra) # 800041b0 <end_op>
  p->cwd = 0;
    800020fe:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002102:	00007497          	auipc	s1,0x7
    80002106:	f2648493          	addi	s1,s1,-218 # 80009028 <initproc>
    8000210a:	6088                	ld	a0,0(s1)
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	aca080e7          	jalr	-1334(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    80002114:	6088                	ld	a0,0(s1)
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	70c080e7          	jalr	1804(ra) # 80001822 <wakeup1>
  release(&initproc->lock);
    8000211e:	6088                	ld	a0,0(s1)
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	b6a080e7          	jalr	-1174(ra) # 80000c8a <release>
  acquire(&p->lock);
    80002128:	854e                	mv	a0,s3
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	aac080e7          	jalr	-1364(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    80002132:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002136:	854e                	mv	a0,s3
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	b52080e7          	jalr	-1198(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    80002140:	8526                	mv	a0,s1
    80002142:	fffff097          	auipc	ra,0xfffff
    80002146:	a94080e7          	jalr	-1388(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    8000214a:	854e                	mv	a0,s3
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	a8a080e7          	jalr	-1398(ra) # 80000bd6 <acquire>
  reparent(p);
    80002154:	854e                	mv	a0,s3
    80002156:	00000097          	auipc	ra,0x0
    8000215a:	d34080e7          	jalr	-716(ra) # 80001e8a <reparent>
  wakeup1(original_parent);
    8000215e:	8526                	mv	a0,s1
    80002160:	fffff097          	auipc	ra,0xfffff
    80002164:	6c2080e7          	jalr	1730(ra) # 80001822 <wakeup1>
  p->xstate = status;
    80002168:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000216c:	4791                	li	a5,4
    8000216e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002172:	8526                	mv	a0,s1
    80002174:	fffff097          	auipc	ra,0xfffff
    80002178:	b16080e7          	jalr	-1258(ra) # 80000c8a <release>
  sched();
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	e38080e7          	jalr	-456(ra) # 80001fb4 <sched>
  panic("zombie exit");
    80002184:	00006517          	auipc	a0,0x6
    80002188:	0cc50513          	addi	a0,a0,204 # 80008250 <digits+0x210>
    8000218c:	ffffe097          	auipc	ra,0xffffe
    80002190:	3a4080e7          	jalr	932(ra) # 80000530 <panic>

0000000080002194 <yield>:
{
    80002194:	1101                	addi	sp,sp,-32
    80002196:	ec06                	sd	ra,24(sp)
    80002198:	e822                	sd	s0,16(sp)
    8000219a:	e426                	sd	s1,8(sp)
    8000219c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	822080e7          	jalr	-2014(ra) # 800019c0 <myproc>
    800021a6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a2e080e7          	jalr	-1490(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800021b0:	4789                	li	a5,2
    800021b2:	cc9c                	sw	a5,24(s1)
  sched();
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	e00080e7          	jalr	-512(ra) # 80001fb4 <sched>
  release(&p->lock);
    800021bc:	8526                	mv	a0,s1
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	acc080e7          	jalr	-1332(ra) # 80000c8a <release>
}
    800021c6:	60e2                	ld	ra,24(sp)
    800021c8:	6442                	ld	s0,16(sp)
    800021ca:	64a2                	ld	s1,8(sp)
    800021cc:	6105                	addi	sp,sp,32
    800021ce:	8082                	ret

00000000800021d0 <sleep>:
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	1800                	addi	s0,sp,48
    800021de:	89aa                	mv	s3,a0
    800021e0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	7de080e7          	jalr	2014(ra) # 800019c0 <myproc>
    800021ea:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800021ec:	05250663          	beq	a0,s2,80002238 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	9e6080e7          	jalr	-1562(ra) # 80000bd6 <acquire>
    release(lk);
    800021f8:	854a                	mv	a0,s2
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	a90080e7          	jalr	-1392(ra) # 80000c8a <release>
  p->chan = chan;
    80002202:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002206:	4785                	li	a5,1
    80002208:	cc9c                	sw	a5,24(s1)
  sched();
    8000220a:	00000097          	auipc	ra,0x0
    8000220e:	daa080e7          	jalr	-598(ra) # 80001fb4 <sched>
  p->chan = 0;
    80002212:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002216:	8526                	mv	a0,s1
    80002218:	fffff097          	auipc	ra,0xfffff
    8000221c:	a72080e7          	jalr	-1422(ra) # 80000c8a <release>
    acquire(lk);
    80002220:	854a                	mv	a0,s2
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	9b4080e7          	jalr	-1612(ra) # 80000bd6 <acquire>
}
    8000222a:	70a2                	ld	ra,40(sp)
    8000222c:	7402                	ld	s0,32(sp)
    8000222e:	64e2                	ld	s1,24(sp)
    80002230:	6942                	ld	s2,16(sp)
    80002232:	69a2                	ld	s3,8(sp)
    80002234:	6145                	addi	sp,sp,48
    80002236:	8082                	ret
  p->chan = chan;
    80002238:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000223c:	4785                	li	a5,1
    8000223e:	cd1c                	sw	a5,24(a0)
  sched();
    80002240:	00000097          	auipc	ra,0x0
    80002244:	d74080e7          	jalr	-652(ra) # 80001fb4 <sched>
  p->chan = 0;
    80002248:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000224c:	bff9                	j	8000222a <sleep+0x5a>

000000008000224e <wait>:
{
    8000224e:	715d                	addi	sp,sp,-80
    80002250:	e486                	sd	ra,72(sp)
    80002252:	e0a2                	sd	s0,64(sp)
    80002254:	fc26                	sd	s1,56(sp)
    80002256:	f84a                	sd	s2,48(sp)
    80002258:	f44e                	sd	s3,40(sp)
    8000225a:	f052                	sd	s4,32(sp)
    8000225c:	ec56                	sd	s5,24(sp)
    8000225e:	e85a                	sd	s6,16(sp)
    80002260:	e45e                	sd	s7,8(sp)
    80002262:	e062                	sd	s8,0(sp)
    80002264:	0880                	addi	s0,sp,80
    80002266:	8aaa                	mv	s5,a0
  struct proc *p = myproc();
    80002268:	fffff097          	auipc	ra,0xfffff
    8000226c:	758080e7          	jalr	1880(ra) # 800019c0 <myproc>
    80002270:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002272:	8c2a                	mv	s8,a0
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	962080e7          	jalr	-1694(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000227c:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000227e:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002280:	00010997          	auipc	s3,0x10
    80002284:	24898993          	addi	s3,s3,584 # 800124c8 <tickslock>
        havekids = 1;
    80002288:	4b05                	li	s6,1
    havekids = 0;
    8000228a:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000228c:	0000f497          	auipc	s1,0xf
    80002290:	42c48493          	addi	s1,s1,1068 # 800116b8 <proc>
    80002294:	a08d                	j	800022f6 <wait+0xa8>
          pid = np->pid;
    80002296:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000229a:	000a8e63          	beqz	s5,800022b6 <wait+0x68>
    8000229e:	4691                	li	a3,4
    800022a0:	03448613          	addi	a2,s1,52
    800022a4:	85d6                	mv	a1,s5
    800022a6:	05093503          	ld	a0,80(s2)
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	3ac080e7          	jalr	940(ra) # 80001656 <copyout>
    800022b2:	02054263          	bltz	a0,800022d6 <wait+0x88>
          freeproc(np);
    800022b6:	8526                	mv	a0,s1
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	8ba080e7          	jalr	-1862(ra) # 80001b72 <freeproc>
          release(&np->lock);
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	9c8080e7          	jalr	-1592(ra) # 80000c8a <release>
          release(&p->lock);
    800022ca:	854a                	mv	a0,s2
    800022cc:	fffff097          	auipc	ra,0xfffff
    800022d0:	9be080e7          	jalr	-1602(ra) # 80000c8a <release>
          return pid;
    800022d4:	a8a9                	j	8000232e <wait+0xe0>
            release(&np->lock);
    800022d6:	8526                	mv	a0,s1
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9b2080e7          	jalr	-1614(ra) # 80000c8a <release>
            release(&p->lock);
    800022e0:	854a                	mv	a0,s2
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	9a8080e7          	jalr	-1624(ra) # 80000c8a <release>
            return -1;
    800022ea:	59fd                	li	s3,-1
    800022ec:	a089                	j	8000232e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800022ee:	16848493          	addi	s1,s1,360
    800022f2:	03348463          	beq	s1,s3,8000231a <wait+0xcc>
      if(np->parent == p){
    800022f6:	709c                	ld	a5,32(s1)
    800022f8:	ff279be3          	bne	a5,s2,800022ee <wait+0xa0>
        acquire(&np->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	8d8080e7          	jalr	-1832(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    80002306:	4c9c                	lw	a5,24(s1)
    80002308:	f94787e3          	beq	a5,s4,80002296 <wait+0x48>
        release(&np->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	97c080e7          	jalr	-1668(ra) # 80000c8a <release>
        havekids = 1;
    80002316:	875a                	mv	a4,s6
    80002318:	bfd9                	j	800022ee <wait+0xa0>
    if(!havekids || p->killed){
    8000231a:	c701                	beqz	a4,80002322 <wait+0xd4>
    8000231c:	03092783          	lw	a5,48(s2)
    80002320:	c785                	beqz	a5,80002348 <wait+0xfa>
      release(&p->lock);
    80002322:	854a                	mv	a0,s2
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	966080e7          	jalr	-1690(ra) # 80000c8a <release>
      return -1;
    8000232c:	59fd                	li	s3,-1
}
    8000232e:	854e                	mv	a0,s3
    80002330:	60a6                	ld	ra,72(sp)
    80002332:	6406                	ld	s0,64(sp)
    80002334:	74e2                	ld	s1,56(sp)
    80002336:	7942                	ld	s2,48(sp)
    80002338:	79a2                	ld	s3,40(sp)
    8000233a:	7a02                	ld	s4,32(sp)
    8000233c:	6ae2                	ld	s5,24(sp)
    8000233e:	6b42                	ld	s6,16(sp)
    80002340:	6ba2                	ld	s7,8(sp)
    80002342:	6c02                	ld	s8,0(sp)
    80002344:	6161                	addi	sp,sp,80
    80002346:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002348:	85e2                	mv	a1,s8
    8000234a:	854a                	mv	a0,s2
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	e84080e7          	jalr	-380(ra) # 800021d0 <sleep>
    havekids = 0;
    80002354:	bf1d                	j	8000228a <wait+0x3c>

0000000080002356 <wakeup>:
{
    80002356:	7139                	addi	sp,sp,-64
    80002358:	fc06                	sd	ra,56(sp)
    8000235a:	f822                	sd	s0,48(sp)
    8000235c:	f426                	sd	s1,40(sp)
    8000235e:	f04a                	sd	s2,32(sp)
    80002360:	ec4e                	sd	s3,24(sp)
    80002362:	e852                	sd	s4,16(sp)
    80002364:	e456                	sd	s5,8(sp)
    80002366:	0080                	addi	s0,sp,64
    80002368:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000236a:	0000f497          	auipc	s1,0xf
    8000236e:	34e48493          	addi	s1,s1,846 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002372:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002374:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002376:	00010917          	auipc	s2,0x10
    8000237a:	15290913          	addi	s2,s2,338 # 800124c8 <tickslock>
    8000237e:	a821                	j	80002396 <wakeup+0x40>
      p->state = RUNNABLE;
    80002380:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002384:	8526                	mv	a0,s1
    80002386:	fffff097          	auipc	ra,0xfffff
    8000238a:	904080e7          	jalr	-1788(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000238e:	16848493          	addi	s1,s1,360
    80002392:	01248e63          	beq	s1,s2,800023ae <wakeup+0x58>
    acquire(&p->lock);
    80002396:	8526                	mv	a0,s1
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	83e080e7          	jalr	-1986(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023a0:	4c9c                	lw	a5,24(s1)
    800023a2:	ff3791e3          	bne	a5,s3,80002384 <wakeup+0x2e>
    800023a6:	749c                	ld	a5,40(s1)
    800023a8:	fd479ee3          	bne	a5,s4,80002384 <wakeup+0x2e>
    800023ac:	bfd1                	j	80002380 <wakeup+0x2a>
}
    800023ae:	70e2                	ld	ra,56(sp)
    800023b0:	7442                	ld	s0,48(sp)
    800023b2:	74a2                	ld	s1,40(sp)
    800023b4:	7902                	ld	s2,32(sp)
    800023b6:	69e2                	ld	s3,24(sp)
    800023b8:	6a42                	ld	s4,16(sp)
    800023ba:	6aa2                	ld	s5,8(sp)
    800023bc:	6121                	addi	sp,sp,64
    800023be:	8082                	ret

00000000800023c0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800023c0:	7179                	addi	sp,sp,-48
    800023c2:	f406                	sd	ra,40(sp)
    800023c4:	f022                	sd	s0,32(sp)
    800023c6:	ec26                	sd	s1,24(sp)
    800023c8:	e84a                	sd	s2,16(sp)
    800023ca:	e44e                	sd	s3,8(sp)
    800023cc:	1800                	addi	s0,sp,48
    800023ce:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800023d0:	0000f497          	auipc	s1,0xf
    800023d4:	2e848493          	addi	s1,s1,744 # 800116b8 <proc>
    800023d8:	00010997          	auipc	s3,0x10
    800023dc:	0f098993          	addi	s3,s3,240 # 800124c8 <tickslock>
    acquire(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	ffffe097          	auipc	ra,0xffffe
    800023e6:	7f4080e7          	jalr	2036(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800023ea:	5c9c                	lw	a5,56(s1)
    800023ec:	03278363          	beq	a5,s2,80002412 <kill+0x52>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023f0:	8526                	mv	a0,s1
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	898080e7          	jalr	-1896(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023fa:	16848493          	addi	s1,s1,360
    800023fe:	ff3491e3          	bne	s1,s3,800023e0 <kill+0x20>
  }
  return -1;
    80002402:	557d                	li	a0,-1
}
    80002404:	70a2                	ld	ra,40(sp)
    80002406:	7402                	ld	s0,32(sp)
    80002408:	64e2                	ld	s1,24(sp)
    8000240a:	6942                	ld	s2,16(sp)
    8000240c:	69a2                	ld	s3,8(sp)
    8000240e:	6145                	addi	sp,sp,48
    80002410:	8082                	ret
      p->killed = 1;
    80002412:	4785                	li	a5,1
    80002414:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002416:	4c98                	lw	a4,24(s1)
    80002418:	4785                	li	a5,1
    8000241a:	00f70963          	beq	a4,a5,8000242c <kill+0x6c>
      release(&p->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	86a080e7          	jalr	-1942(ra) # 80000c8a <release>
      return 0;
    80002428:	4501                	li	a0,0
    8000242a:	bfe9                	j	80002404 <kill+0x44>
        p->state = RUNNABLE;
    8000242c:	4789                	li	a5,2
    8000242e:	cc9c                	sw	a5,24(s1)
    80002430:	b7fd                	j	8000241e <kill+0x5e>

0000000080002432 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002432:	7179                	addi	sp,sp,-48
    80002434:	f406                	sd	ra,40(sp)
    80002436:	f022                	sd	s0,32(sp)
    80002438:	ec26                	sd	s1,24(sp)
    8000243a:	e84a                	sd	s2,16(sp)
    8000243c:	e44e                	sd	s3,8(sp)
    8000243e:	e052                	sd	s4,0(sp)
    80002440:	1800                	addi	s0,sp,48
    80002442:	84aa                	mv	s1,a0
    80002444:	892e                	mv	s2,a1
    80002446:	89b2                	mv	s3,a2
    80002448:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	576080e7          	jalr	1398(ra) # 800019c0 <myproc>
  if(user_dst){
    80002452:	c08d                	beqz	s1,80002474 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002454:	86d2                	mv	a3,s4
    80002456:	864e                	mv	a2,s3
    80002458:	85ca                	mv	a1,s2
    8000245a:	6928                	ld	a0,80(a0)
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	1fa080e7          	jalr	506(ra) # 80001656 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002464:	70a2                	ld	ra,40(sp)
    80002466:	7402                	ld	s0,32(sp)
    80002468:	64e2                	ld	s1,24(sp)
    8000246a:	6942                	ld	s2,16(sp)
    8000246c:	69a2                	ld	s3,8(sp)
    8000246e:	6a02                	ld	s4,0(sp)
    80002470:	6145                	addi	sp,sp,48
    80002472:	8082                	ret
    memmove((char *)dst, src, len);
    80002474:	000a061b          	sext.w	a2,s4
    80002478:	85ce                	mv	a1,s3
    8000247a:	854a                	mv	a0,s2
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	8b6080e7          	jalr	-1866(ra) # 80000d32 <memmove>
    return 0;
    80002484:	8526                	mv	a0,s1
    80002486:	bff9                	j	80002464 <either_copyout+0x32>

0000000080002488 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002488:	7179                	addi	sp,sp,-48
    8000248a:	f406                	sd	ra,40(sp)
    8000248c:	f022                	sd	s0,32(sp)
    8000248e:	ec26                	sd	s1,24(sp)
    80002490:	e84a                	sd	s2,16(sp)
    80002492:	e44e                	sd	s3,8(sp)
    80002494:	e052                	sd	s4,0(sp)
    80002496:	1800                	addi	s0,sp,48
    80002498:	892a                	mv	s2,a0
    8000249a:	84ae                	mv	s1,a1
    8000249c:	89b2                	mv	s3,a2
    8000249e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024a0:	fffff097          	auipc	ra,0xfffff
    800024a4:	520080e7          	jalr	1312(ra) # 800019c0 <myproc>
  if(user_src){
    800024a8:	c08d                	beqz	s1,800024ca <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024aa:	86d2                	mv	a3,s4
    800024ac:	864e                	mv	a2,s3
    800024ae:	85ca                	mv	a1,s2
    800024b0:	6928                	ld	a0,80(a0)
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	230080e7          	jalr	560(ra) # 800016e2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800024ba:	70a2                	ld	ra,40(sp)
    800024bc:	7402                	ld	s0,32(sp)
    800024be:	64e2                	ld	s1,24(sp)
    800024c0:	6942                	ld	s2,16(sp)
    800024c2:	69a2                	ld	s3,8(sp)
    800024c4:	6a02                	ld	s4,0(sp)
    800024c6:	6145                	addi	sp,sp,48
    800024c8:	8082                	ret
    memmove(dst, (char*)src, len);
    800024ca:	000a061b          	sext.w	a2,s4
    800024ce:	85ce                	mv	a1,s3
    800024d0:	854a                	mv	a0,s2
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	860080e7          	jalr	-1952(ra) # 80000d32 <memmove>
    return 0;
    800024da:	8526                	mv	a0,s1
    800024dc:	bff9                	j	800024ba <either_copyin+0x32>

00000000800024de <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800024de:	715d                	addi	sp,sp,-80
    800024e0:	e486                	sd	ra,72(sp)
    800024e2:	e0a2                	sd	s0,64(sp)
    800024e4:	fc26                	sd	s1,56(sp)
    800024e6:	f84a                	sd	s2,48(sp)
    800024e8:	f44e                	sd	s3,40(sp)
    800024ea:	f052                	sd	s4,32(sp)
    800024ec:	ec56                	sd	s5,24(sp)
    800024ee:	e85a                	sd	s6,16(sp)
    800024f0:	e45e                	sd	s7,8(sp)
    800024f2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800024f4:	00006517          	auipc	a0,0x6
    800024f8:	bd450513          	addi	a0,a0,-1068 # 800080c8 <digits+0x88>
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	07e080e7          	jalr	126(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002504:	0000f497          	auipc	s1,0xf
    80002508:	30c48493          	addi	s1,s1,780 # 80011810 <proc+0x158>
    8000250c:	00010917          	auipc	s2,0x10
    80002510:	11490913          	addi	s2,s2,276 # 80012620 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002514:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002516:	00006997          	auipc	s3,0x6
    8000251a:	d4a98993          	addi	s3,s3,-694 # 80008260 <digits+0x220>
    printf("%d %s %s", p->pid, state, p->name);
    8000251e:	00006a97          	auipc	s5,0x6
    80002522:	d4aa8a93          	addi	s5,s5,-694 # 80008268 <digits+0x228>
    printf("\n");
    80002526:	00006a17          	auipc	s4,0x6
    8000252a:	ba2a0a13          	addi	s4,s4,-1118 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000252e:	00006b97          	auipc	s7,0x6
    80002532:	d72b8b93          	addi	s7,s7,-654 # 800082a0 <states.1710>
    80002536:	a00d                	j	80002558 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002538:	ee06a583          	lw	a1,-288(a3)
    8000253c:	8556                	mv	a0,s5
    8000253e:	ffffe097          	auipc	ra,0xffffe
    80002542:	03c080e7          	jalr	60(ra) # 8000057a <printf>
    printf("\n");
    80002546:	8552                	mv	a0,s4
    80002548:	ffffe097          	auipc	ra,0xffffe
    8000254c:	032080e7          	jalr	50(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002550:	16848493          	addi	s1,s1,360
    80002554:	03248163          	beq	s1,s2,80002576 <procdump+0x98>
    if(p->state == UNUSED)
    80002558:	86a6                	mv	a3,s1
    8000255a:	ec04a783          	lw	a5,-320(s1)
    8000255e:	dbed                	beqz	a5,80002550 <procdump+0x72>
      state = "???";
    80002560:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002562:	fcfb6be3          	bltu	s6,a5,80002538 <procdump+0x5a>
    80002566:	1782                	slli	a5,a5,0x20
    80002568:	9381                	srli	a5,a5,0x20
    8000256a:	078e                	slli	a5,a5,0x3
    8000256c:	97de                	add	a5,a5,s7
    8000256e:	6390                	ld	a2,0(a5)
    80002570:	f661                	bnez	a2,80002538 <procdump+0x5a>
      state = "???";
    80002572:	864e                	mv	a2,s3
    80002574:	b7d1                	j	80002538 <procdump+0x5a>
  }
}
    80002576:	60a6                	ld	ra,72(sp)
    80002578:	6406                	ld	s0,64(sp)
    8000257a:	74e2                	ld	s1,56(sp)
    8000257c:	7942                	ld	s2,48(sp)
    8000257e:	79a2                	ld	s3,40(sp)
    80002580:	7a02                	ld	s4,32(sp)
    80002582:	6ae2                	ld	s5,24(sp)
    80002584:	6b42                	ld	s6,16(sp)
    80002586:	6ba2                	ld	s7,8(sp)
    80002588:	6161                	addi	sp,sp,80
    8000258a:	8082                	ret

000000008000258c <swtch>:
    8000258c:	00153023          	sd	ra,0(a0)
    80002590:	00253423          	sd	sp,8(a0)
    80002594:	e900                	sd	s0,16(a0)
    80002596:	ed04                	sd	s1,24(a0)
    80002598:	03253023          	sd	s2,32(a0)
    8000259c:	03353423          	sd	s3,40(a0)
    800025a0:	03453823          	sd	s4,48(a0)
    800025a4:	03553c23          	sd	s5,56(a0)
    800025a8:	05653023          	sd	s6,64(a0)
    800025ac:	05753423          	sd	s7,72(a0)
    800025b0:	05853823          	sd	s8,80(a0)
    800025b4:	05953c23          	sd	s9,88(a0)
    800025b8:	07a53023          	sd	s10,96(a0)
    800025bc:	07b53423          	sd	s11,104(a0)
    800025c0:	0005b083          	ld	ra,0(a1)
    800025c4:	0085b103          	ld	sp,8(a1)
    800025c8:	6980                	ld	s0,16(a1)
    800025ca:	6d84                	ld	s1,24(a1)
    800025cc:	0205b903          	ld	s2,32(a1)
    800025d0:	0285b983          	ld	s3,40(a1)
    800025d4:	0305ba03          	ld	s4,48(a1)
    800025d8:	0385ba83          	ld	s5,56(a1)
    800025dc:	0405bb03          	ld	s6,64(a1)
    800025e0:	0485bb83          	ld	s7,72(a1)
    800025e4:	0505bc03          	ld	s8,80(a1)
    800025e8:	0585bc83          	ld	s9,88(a1)
    800025ec:	0605bd03          	ld	s10,96(a1)
    800025f0:	0685bd83          	ld	s11,104(a1)
    800025f4:	8082                	ret

00000000800025f6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800025f6:	1141                	addi	sp,sp,-16
    800025f8:	e406                	sd	ra,8(sp)
    800025fa:	e022                	sd	s0,0(sp)
    800025fc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800025fe:	00006597          	auipc	a1,0x6
    80002602:	cca58593          	addi	a1,a1,-822 # 800082c8 <states.1710+0x28>
    80002606:	00010517          	auipc	a0,0x10
    8000260a:	ec250513          	addi	a0,a0,-318 # 800124c8 <tickslock>
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	538080e7          	jalr	1336(ra) # 80000b46 <initlock>
}
    80002616:	60a2                	ld	ra,8(sp)
    80002618:	6402                	ld	s0,0(sp)
    8000261a:	0141                	addi	sp,sp,16
    8000261c:	8082                	ret

000000008000261e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000261e:	1141                	addi	sp,sp,-16
    80002620:	e422                	sd	s0,8(sp)
    80002622:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002624:	00003797          	auipc	a5,0x3
    80002628:	72c78793          	addi	a5,a5,1836 # 80005d50 <kernelvec>
    8000262c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002630:	6422                	ld	s0,8(sp)
    80002632:	0141                	addi	sp,sp,16
    80002634:	8082                	ret

0000000080002636 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002636:	1141                	addi	sp,sp,-16
    80002638:	e406                	sd	ra,8(sp)
    8000263a:	e022                	sd	s0,0(sp)
    8000263c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000263e:	fffff097          	auipc	ra,0xfffff
    80002642:	382080e7          	jalr	898(ra) # 800019c0 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002646:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000264a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000264c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002650:	00005617          	auipc	a2,0x5
    80002654:	9b060613          	addi	a2,a2,-1616 # 80007000 <_trampoline>
    80002658:	00005697          	auipc	a3,0x5
    8000265c:	9a868693          	addi	a3,a3,-1624 # 80007000 <_trampoline>
    80002660:	8e91                	sub	a3,a3,a2
    80002662:	040007b7          	lui	a5,0x4000
    80002666:	17fd                	addi	a5,a5,-1
    80002668:	07b2                	slli	a5,a5,0xc
    8000266a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000266c:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002670:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002672:	180026f3          	csrr	a3,satp
    80002676:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002678:	6d38                	ld	a4,88(a0)
    8000267a:	6134                	ld	a3,64(a0)
    8000267c:	6585                	lui	a1,0x1
    8000267e:	96ae                	add	a3,a3,a1
    80002680:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002682:	6d38                	ld	a4,88(a0)
    80002684:	00000697          	auipc	a3,0x0
    80002688:	13868693          	addi	a3,a3,312 # 800027bc <usertrap>
    8000268c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000268e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002690:	8692                	mv	a3,tp
    80002692:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002694:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002698:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000269c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026a0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800026a4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800026a6:	6f18                	ld	a4,24(a4)
    800026a8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800026ac:	692c                	ld	a1,80(a0)
    800026ae:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800026b0:	00005717          	auipc	a4,0x5
    800026b4:	9e070713          	addi	a4,a4,-1568 # 80007090 <userret>
    800026b8:	8f11                	sub	a4,a4,a2
    800026ba:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800026bc:	577d                	li	a4,-1
    800026be:	177e                	slli	a4,a4,0x3f
    800026c0:	8dd9                	or	a1,a1,a4
    800026c2:	02000537          	lui	a0,0x2000
    800026c6:	157d                	addi	a0,a0,-1
    800026c8:	0536                	slli	a0,a0,0xd
    800026ca:	9782                	jalr	a5
}
    800026cc:	60a2                	ld	ra,8(sp)
    800026ce:	6402                	ld	s0,0(sp)
    800026d0:	0141                	addi	sp,sp,16
    800026d2:	8082                	ret

00000000800026d4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800026d4:	1101                	addi	sp,sp,-32
    800026d6:	ec06                	sd	ra,24(sp)
    800026d8:	e822                	sd	s0,16(sp)
    800026da:	e426                	sd	s1,8(sp)
    800026dc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800026de:	00010497          	auipc	s1,0x10
    800026e2:	dea48493          	addi	s1,s1,-534 # 800124c8 <tickslock>
    800026e6:	8526                	mv	a0,s1
    800026e8:	ffffe097          	auipc	ra,0xffffe
    800026ec:	4ee080e7          	jalr	1262(ra) # 80000bd6 <acquire>
  ticks++;
    800026f0:	00007517          	auipc	a0,0x7
    800026f4:	94050513          	addi	a0,a0,-1728 # 80009030 <ticks>
    800026f8:	411c                	lw	a5,0(a0)
    800026fa:	2785                	addiw	a5,a5,1
    800026fc:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800026fe:	00000097          	auipc	ra,0x0
    80002702:	c58080e7          	jalr	-936(ra) # 80002356 <wakeup>
  release(&tickslock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	582080e7          	jalr	1410(ra) # 80000c8a <release>
}
    80002710:	60e2                	ld	ra,24(sp)
    80002712:	6442                	ld	s0,16(sp)
    80002714:	64a2                	ld	s1,8(sp)
    80002716:	6105                	addi	sp,sp,32
    80002718:	8082                	ret

000000008000271a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000271a:	1101                	addi	sp,sp,-32
    8000271c:	ec06                	sd	ra,24(sp)
    8000271e:	e822                	sd	s0,16(sp)
    80002720:	e426                	sd	s1,8(sp)
    80002722:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002724:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002728:	00074d63          	bltz	a4,80002742 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000272c:	57fd                	li	a5,-1
    8000272e:	17fe                	slli	a5,a5,0x3f
    80002730:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002732:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002734:	06f70363          	beq	a4,a5,8000279a <devintr+0x80>
  }
}
    80002738:	60e2                	ld	ra,24(sp)
    8000273a:	6442                	ld	s0,16(sp)
    8000273c:	64a2                	ld	s1,8(sp)
    8000273e:	6105                	addi	sp,sp,32
    80002740:	8082                	ret
     (scause & 0xff) == 9){
    80002742:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002746:	46a5                	li	a3,9
    80002748:	fed792e3          	bne	a5,a3,8000272c <devintr+0x12>
    int irq = plic_claim();
    8000274c:	00003097          	auipc	ra,0x3
    80002750:	70c080e7          	jalr	1804(ra) # 80005e58 <plic_claim>
    80002754:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002756:	47a9                	li	a5,10
    80002758:	02f50763          	beq	a0,a5,80002786 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000275c:	4785                	li	a5,1
    8000275e:	02f50963          	beq	a0,a5,80002790 <devintr+0x76>
    return 1;
    80002762:	4505                	li	a0,1
    } else if(irq){
    80002764:	d8f1                	beqz	s1,80002738 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002766:	85a6                	mv	a1,s1
    80002768:	00006517          	auipc	a0,0x6
    8000276c:	b6850513          	addi	a0,a0,-1176 # 800082d0 <states.1710+0x30>
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	e0a080e7          	jalr	-502(ra) # 8000057a <printf>
      plic_complete(irq);
    80002778:	8526                	mv	a0,s1
    8000277a:	00003097          	auipc	ra,0x3
    8000277e:	702080e7          	jalr	1794(ra) # 80005e7c <plic_complete>
    return 1;
    80002782:	4505                	li	a0,1
    80002784:	bf55                	j	80002738 <devintr+0x1e>
      uartintr();
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	214080e7          	jalr	532(ra) # 8000099a <uartintr>
    8000278e:	b7ed                	j	80002778 <devintr+0x5e>
      virtio_disk_intr();
    80002790:	00004097          	auipc	ra,0x4
    80002794:	bcc080e7          	jalr	-1076(ra) # 8000635c <virtio_disk_intr>
    80002798:	b7c5                	j	80002778 <devintr+0x5e>
    if(cpuid() == 0){
    8000279a:	fffff097          	auipc	ra,0xfffff
    8000279e:	1fa080e7          	jalr	506(ra) # 80001994 <cpuid>
    800027a2:	c901                	beqz	a0,800027b2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800027a4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800027a8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800027aa:	14479073          	csrw	sip,a5
    return 2;
    800027ae:	4509                	li	a0,2
    800027b0:	b761                	j	80002738 <devintr+0x1e>
      clockintr();
    800027b2:	00000097          	auipc	ra,0x0
    800027b6:	f22080e7          	jalr	-222(ra) # 800026d4 <clockintr>
    800027ba:	b7ed                	j	800027a4 <devintr+0x8a>

00000000800027bc <usertrap>:
{
    800027bc:	1101                	addi	sp,sp,-32
    800027be:	ec06                	sd	ra,24(sp)
    800027c0:	e822                	sd	s0,16(sp)
    800027c2:	e426                	sd	s1,8(sp)
    800027c4:	e04a                	sd	s2,0(sp)
    800027c6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027c8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800027cc:	1007f793          	andi	a5,a5,256
    800027d0:	e3ad                	bnez	a5,80002832 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027d2:	00003797          	auipc	a5,0x3
    800027d6:	57e78793          	addi	a5,a5,1406 # 80005d50 <kernelvec>
    800027da:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800027de:	fffff097          	auipc	ra,0xfffff
    800027e2:	1e2080e7          	jalr	482(ra) # 800019c0 <myproc>
    800027e6:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800027e8:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800027ea:	14102773          	csrr	a4,sepc
    800027ee:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f0:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800027f4:	47a1                	li	a5,8
    800027f6:	04f71c63          	bne	a4,a5,8000284e <usertrap+0x92>
    if(p->killed)
    800027fa:	591c                	lw	a5,48(a0)
    800027fc:	e3b9                	bnez	a5,80002842 <usertrap+0x86>
    p->trapframe->epc += 4;
    800027fe:	6cb8                	ld	a4,88(s1)
    80002800:	6f1c                	ld	a5,24(a4)
    80002802:	0791                	addi	a5,a5,4
    80002804:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002806:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000280a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000280e:	10079073          	csrw	sstatus,a5
    syscall();
    80002812:	00000097          	auipc	ra,0x0
    80002816:	2e0080e7          	jalr	736(ra) # 80002af2 <syscall>
  if(p->killed)
    8000281a:	589c                	lw	a5,48(s1)
    8000281c:	ebc1                	bnez	a5,800028ac <usertrap+0xf0>
  usertrapret();
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	e18080e7          	jalr	-488(ra) # 80002636 <usertrapret>
}
    80002826:	60e2                	ld	ra,24(sp)
    80002828:	6442                	ld	s0,16(sp)
    8000282a:	64a2                	ld	s1,8(sp)
    8000282c:	6902                	ld	s2,0(sp)
    8000282e:	6105                	addi	sp,sp,32
    80002830:	8082                	ret
    panic("usertrap: not from user mode");
    80002832:	00006517          	auipc	a0,0x6
    80002836:	abe50513          	addi	a0,a0,-1346 # 800082f0 <states.1710+0x50>
    8000283a:	ffffe097          	auipc	ra,0xffffe
    8000283e:	cf6080e7          	jalr	-778(ra) # 80000530 <panic>
      exit(-1);
    80002842:	557d                	li	a0,-1
    80002844:	00000097          	auipc	ra,0x0
    80002848:	846080e7          	jalr	-1978(ra) # 8000208a <exit>
    8000284c:	bf4d                	j	800027fe <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000284e:	00000097          	auipc	ra,0x0
    80002852:	ecc080e7          	jalr	-308(ra) # 8000271a <devintr>
    80002856:	892a                	mv	s2,a0
    80002858:	c501                	beqz	a0,80002860 <usertrap+0xa4>
  if(p->killed)
    8000285a:	589c                	lw	a5,48(s1)
    8000285c:	c3a1                	beqz	a5,8000289c <usertrap+0xe0>
    8000285e:	a815                	j	80002892 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002860:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002864:	5c90                	lw	a2,56(s1)
    80002866:	00006517          	auipc	a0,0x6
    8000286a:	aaa50513          	addi	a0,a0,-1366 # 80008310 <states.1710+0x70>
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	d0c080e7          	jalr	-756(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002876:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000287a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000287e:	00006517          	auipc	a0,0x6
    80002882:	ac250513          	addi	a0,a0,-1342 # 80008340 <states.1710+0xa0>
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	cf4080e7          	jalr	-780(ra) # 8000057a <printf>
    p->killed = 1;
    8000288e:	4785                	li	a5,1
    80002890:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002892:	557d                	li	a0,-1
    80002894:	fffff097          	auipc	ra,0xfffff
    80002898:	7f6080e7          	jalr	2038(ra) # 8000208a <exit>
  if(which_dev == 2)
    8000289c:	4789                	li	a5,2
    8000289e:	f8f910e3          	bne	s2,a5,8000281e <usertrap+0x62>
    yield();
    800028a2:	00000097          	auipc	ra,0x0
    800028a6:	8f2080e7          	jalr	-1806(ra) # 80002194 <yield>
    800028aa:	bf95                	j	8000281e <usertrap+0x62>
  int which_dev = 0;
    800028ac:	4901                	li	s2,0
    800028ae:	b7d5                	j	80002892 <usertrap+0xd6>

00000000800028b0 <kerneltrap>:
{
    800028b0:	7179                	addi	sp,sp,-48
    800028b2:	f406                	sd	ra,40(sp)
    800028b4:	f022                	sd	s0,32(sp)
    800028b6:	ec26                	sd	s1,24(sp)
    800028b8:	e84a                	sd	s2,16(sp)
    800028ba:	e44e                	sd	s3,8(sp)
    800028bc:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028be:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800028ca:	1004f793          	andi	a5,s1,256
    800028ce:	cb85                	beqz	a5,800028fe <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028d4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800028d6:	ef85                	bnez	a5,8000290e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800028d8:	00000097          	auipc	ra,0x0
    800028dc:	e42080e7          	jalr	-446(ra) # 8000271a <devintr>
    800028e0:	cd1d                	beqz	a0,8000291e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800028e2:	4789                	li	a5,2
    800028e4:	06f50a63          	beq	a0,a5,80002958 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028e8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ec:	10049073          	csrw	sstatus,s1
}
    800028f0:	70a2                	ld	ra,40(sp)
    800028f2:	7402                	ld	s0,32(sp)
    800028f4:	64e2                	ld	s1,24(sp)
    800028f6:	6942                	ld	s2,16(sp)
    800028f8:	69a2                	ld	s3,8(sp)
    800028fa:	6145                	addi	sp,sp,48
    800028fc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800028fe:	00006517          	auipc	a0,0x6
    80002902:	a6250513          	addi	a0,a0,-1438 # 80008360 <states.1710+0xc0>
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c2a080e7          	jalr	-982(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    8000290e:	00006517          	auipc	a0,0x6
    80002912:	a7a50513          	addi	a0,a0,-1414 # 80008388 <states.1710+0xe8>
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	c1a080e7          	jalr	-998(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    8000291e:	85ce                	mv	a1,s3
    80002920:	00006517          	auipc	a0,0x6
    80002924:	a8850513          	addi	a0,a0,-1400 # 800083a8 <states.1710+0x108>
    80002928:	ffffe097          	auipc	ra,0xffffe
    8000292c:	c52080e7          	jalr	-942(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002930:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002934:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002938:	00006517          	auipc	a0,0x6
    8000293c:	a8050513          	addi	a0,a0,-1408 # 800083b8 <states.1710+0x118>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c3a080e7          	jalr	-966(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	a8850513          	addi	a0,a0,-1400 # 800083d0 <states.1710+0x130>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	be0080e7          	jalr	-1056(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	068080e7          	jalr	104(ra) # 800019c0 <myproc>
    80002960:	d541                	beqz	a0,800028e8 <kerneltrap+0x38>
    80002962:	fffff097          	auipc	ra,0xfffff
    80002966:	05e080e7          	jalr	94(ra) # 800019c0 <myproc>
    8000296a:	4d18                	lw	a4,24(a0)
    8000296c:	478d                	li	a5,3
    8000296e:	f6f71de3          	bne	a4,a5,800028e8 <kerneltrap+0x38>
    yield();
    80002972:	00000097          	auipc	ra,0x0
    80002976:	822080e7          	jalr	-2014(ra) # 80002194 <yield>
    8000297a:	b7bd                	j	800028e8 <kerneltrap+0x38>

000000008000297c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000297c:	1101                	addi	sp,sp,-32
    8000297e:	ec06                	sd	ra,24(sp)
    80002980:	e822                	sd	s0,16(sp)
    80002982:	e426                	sd	s1,8(sp)
    80002984:	1000                	addi	s0,sp,32
    80002986:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002988:	fffff097          	auipc	ra,0xfffff
    8000298c:	038080e7          	jalr	56(ra) # 800019c0 <myproc>
  switch (n) {
    80002990:	4795                	li	a5,5
    80002992:	0497e163          	bltu	a5,s1,800029d4 <argraw+0x58>
    80002996:	048a                	slli	s1,s1,0x2
    80002998:	00006717          	auipc	a4,0x6
    8000299c:	a7070713          	addi	a4,a4,-1424 # 80008408 <states.1710+0x168>
    800029a0:	94ba                	add	s1,s1,a4
    800029a2:	409c                	lw	a5,0(s1)
    800029a4:	97ba                	add	a5,a5,a4
    800029a6:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800029a8:	6d3c                	ld	a5,88(a0)
    800029aa:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800029ac:	60e2                	ld	ra,24(sp)
    800029ae:	6442                	ld	s0,16(sp)
    800029b0:	64a2                	ld	s1,8(sp)
    800029b2:	6105                	addi	sp,sp,32
    800029b4:	8082                	ret
    return p->trapframe->a1;
    800029b6:	6d3c                	ld	a5,88(a0)
    800029b8:	7fa8                	ld	a0,120(a5)
    800029ba:	bfcd                	j	800029ac <argraw+0x30>
    return p->trapframe->a2;
    800029bc:	6d3c                	ld	a5,88(a0)
    800029be:	63c8                	ld	a0,128(a5)
    800029c0:	b7f5                	j	800029ac <argraw+0x30>
    return p->trapframe->a3;
    800029c2:	6d3c                	ld	a5,88(a0)
    800029c4:	67c8                	ld	a0,136(a5)
    800029c6:	b7dd                	j	800029ac <argraw+0x30>
    return p->trapframe->a4;
    800029c8:	6d3c                	ld	a5,88(a0)
    800029ca:	6bc8                	ld	a0,144(a5)
    800029cc:	b7c5                	j	800029ac <argraw+0x30>
    return p->trapframe->a5;
    800029ce:	6d3c                	ld	a5,88(a0)
    800029d0:	6fc8                	ld	a0,152(a5)
    800029d2:	bfe9                	j	800029ac <argraw+0x30>
  panic("argraw");
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	a0c50513          	addi	a0,a0,-1524 # 800083e0 <states.1710+0x140>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b54080e7          	jalr	-1196(ra) # 80000530 <panic>

00000000800029e4 <fetchaddr>:
{
    800029e4:	1101                	addi	sp,sp,-32
    800029e6:	ec06                	sd	ra,24(sp)
    800029e8:	e822                	sd	s0,16(sp)
    800029ea:	e426                	sd	s1,8(sp)
    800029ec:	e04a                	sd	s2,0(sp)
    800029ee:	1000                	addi	s0,sp,32
    800029f0:	84aa                	mv	s1,a0
    800029f2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800029f4:	fffff097          	auipc	ra,0xfffff
    800029f8:	fcc080e7          	jalr	-52(ra) # 800019c0 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800029fc:	653c                	ld	a5,72(a0)
    800029fe:	02f4f863          	bgeu	s1,a5,80002a2e <fetchaddr+0x4a>
    80002a02:	00848713          	addi	a4,s1,8
    80002a06:	02e7e663          	bltu	a5,a4,80002a32 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a0a:	46a1                	li	a3,8
    80002a0c:	8626                	mv	a2,s1
    80002a0e:	85ca                	mv	a1,s2
    80002a10:	6928                	ld	a0,80(a0)
    80002a12:	fffff097          	auipc	ra,0xfffff
    80002a16:	cd0080e7          	jalr	-816(ra) # 800016e2 <copyin>
    80002a1a:	00a03533          	snez	a0,a0
    80002a1e:	40a00533          	neg	a0,a0
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6902                	ld	s2,0(sp)
    80002a2a:	6105                	addi	sp,sp,32
    80002a2c:	8082                	ret
    return -1;
    80002a2e:	557d                	li	a0,-1
    80002a30:	bfcd                	j	80002a22 <fetchaddr+0x3e>
    80002a32:	557d                	li	a0,-1
    80002a34:	b7fd                	j	80002a22 <fetchaddr+0x3e>

0000000080002a36 <fetchstr>:
{
    80002a36:	7179                	addi	sp,sp,-48
    80002a38:	f406                	sd	ra,40(sp)
    80002a3a:	f022                	sd	s0,32(sp)
    80002a3c:	ec26                	sd	s1,24(sp)
    80002a3e:	e84a                	sd	s2,16(sp)
    80002a40:	e44e                	sd	s3,8(sp)
    80002a42:	1800                	addi	s0,sp,48
    80002a44:	892a                	mv	s2,a0
    80002a46:	84ae                	mv	s1,a1
    80002a48:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	f76080e7          	jalr	-138(ra) # 800019c0 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002a52:	86ce                	mv	a3,s3
    80002a54:	864a                	mv	a2,s2
    80002a56:	85a6                	mv	a1,s1
    80002a58:	6928                	ld	a0,80(a0)
    80002a5a:	fffff097          	auipc	ra,0xfffff
    80002a5e:	d14080e7          	jalr	-748(ra) # 8000176e <copyinstr>
  if(err < 0)
    80002a62:	00054763          	bltz	a0,80002a70 <fetchstr+0x3a>
  return strlen(buf);
    80002a66:	8526                	mv	a0,s1
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	3f2080e7          	jalr	1010(ra) # 80000e5a <strlen>
}
    80002a70:	70a2                	ld	ra,40(sp)
    80002a72:	7402                	ld	s0,32(sp)
    80002a74:	64e2                	ld	s1,24(sp)
    80002a76:	6942                	ld	s2,16(sp)
    80002a78:	69a2                	ld	s3,8(sp)
    80002a7a:	6145                	addi	sp,sp,48
    80002a7c:	8082                	ret

0000000080002a7e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002a7e:	1101                	addi	sp,sp,-32
    80002a80:	ec06                	sd	ra,24(sp)
    80002a82:	e822                	sd	s0,16(sp)
    80002a84:	e426                	sd	s1,8(sp)
    80002a86:	1000                	addi	s0,sp,32
    80002a88:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002a8a:	00000097          	auipc	ra,0x0
    80002a8e:	ef2080e7          	jalr	-270(ra) # 8000297c <argraw>
    80002a92:	c088                	sw	a0,0(s1)
  return 0;
}
    80002a94:	4501                	li	a0,0
    80002a96:	60e2                	ld	ra,24(sp)
    80002a98:	6442                	ld	s0,16(sp)
    80002a9a:	64a2                	ld	s1,8(sp)
    80002a9c:	6105                	addi	sp,sp,32
    80002a9e:	8082                	ret

0000000080002aa0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	1000                	addi	s0,sp,32
    80002aaa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	ed0080e7          	jalr	-304(ra) # 8000297c <argraw>
    80002ab4:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ab6:	4501                	li	a0,0
    80002ab8:	60e2                	ld	ra,24(sp)
    80002aba:	6442                	ld	s0,16(sp)
    80002abc:	64a2                	ld	s1,8(sp)
    80002abe:	6105                	addi	sp,sp,32
    80002ac0:	8082                	ret

0000000080002ac2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ac2:	1101                	addi	sp,sp,-32
    80002ac4:	ec06                	sd	ra,24(sp)
    80002ac6:	e822                	sd	s0,16(sp)
    80002ac8:	e426                	sd	s1,8(sp)
    80002aca:	e04a                	sd	s2,0(sp)
    80002acc:	1000                	addi	s0,sp,32
    80002ace:	84ae                	mv	s1,a1
    80002ad0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ad2:	00000097          	auipc	ra,0x0
    80002ad6:	eaa080e7          	jalr	-342(ra) # 8000297c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ada:	864a                	mv	a2,s2
    80002adc:	85a6                	mv	a1,s1
    80002ade:	00000097          	auipc	ra,0x0
    80002ae2:	f58080e7          	jalr	-168(ra) # 80002a36 <fetchstr>
}
    80002ae6:	60e2                	ld	ra,24(sp)
    80002ae8:	6442                	ld	s0,16(sp)
    80002aea:	64a2                	ld	s1,8(sp)
    80002aec:	6902                	ld	s2,0(sp)
    80002aee:	6105                	addi	sp,sp,32
    80002af0:	8082                	ret

0000000080002af2 <syscall>:
[SYS_symlink] sys_symlink,
};

void
syscall(void)
{
    80002af2:	1101                	addi	sp,sp,-32
    80002af4:	ec06                	sd	ra,24(sp)
    80002af6:	e822                	sd	s0,16(sp)
    80002af8:	e426                	sd	s1,8(sp)
    80002afa:	e04a                	sd	s2,0(sp)
    80002afc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	ec2080e7          	jalr	-318(ra) # 800019c0 <myproc>
    80002b06:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b08:	05853903          	ld	s2,88(a0)
    80002b0c:	0a893783          	ld	a5,168(s2)
    80002b10:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b14:	37fd                	addiw	a5,a5,-1
    80002b16:	4755                	li	a4,21
    80002b18:	00f76f63          	bltu	a4,a5,80002b36 <syscall+0x44>
    80002b1c:	00369713          	slli	a4,a3,0x3
    80002b20:	00006797          	auipc	a5,0x6
    80002b24:	90078793          	addi	a5,a5,-1792 # 80008420 <syscalls>
    80002b28:	97ba                	add	a5,a5,a4
    80002b2a:	639c                	ld	a5,0(a5)
    80002b2c:	c789                	beqz	a5,80002b36 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002b2e:	9782                	jalr	a5
    80002b30:	06a93823          	sd	a0,112(s2)
    80002b34:	a839                	j	80002b52 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002b36:	15848613          	addi	a2,s1,344
    80002b3a:	5c8c                	lw	a1,56(s1)
    80002b3c:	00006517          	auipc	a0,0x6
    80002b40:	8ac50513          	addi	a0,a0,-1876 # 800083e8 <states.1710+0x148>
    80002b44:	ffffe097          	auipc	ra,0xffffe
    80002b48:	a36080e7          	jalr	-1482(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002b4c:	6cbc                	ld	a5,88(s1)
    80002b4e:	577d                	li	a4,-1
    80002b50:	fbb8                	sd	a4,112(a5)
  }
}
    80002b52:	60e2                	ld	ra,24(sp)
    80002b54:	6442                	ld	s0,16(sp)
    80002b56:	64a2                	ld	s1,8(sp)
    80002b58:	6902                	ld	s2,0(sp)
    80002b5a:	6105                	addi	sp,sp,32
    80002b5c:	8082                	ret

0000000080002b5e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002b5e:	1101                	addi	sp,sp,-32
    80002b60:	ec06                	sd	ra,24(sp)
    80002b62:	e822                	sd	s0,16(sp)
    80002b64:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002b66:	fec40593          	addi	a1,s0,-20
    80002b6a:	4501                	li	a0,0
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	f12080e7          	jalr	-238(ra) # 80002a7e <argint>
    return -1;
    80002b74:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002b76:	00054963          	bltz	a0,80002b88 <sys_exit+0x2a>
  exit(n);
    80002b7a:	fec42503          	lw	a0,-20(s0)
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	50c080e7          	jalr	1292(ra) # 8000208a <exit>
  return 0;  // not reached
    80002b86:	4781                	li	a5,0
}
    80002b88:	853e                	mv	a0,a5
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret

0000000080002b92 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002b92:	1141                	addi	sp,sp,-16
    80002b94:	e406                	sd	ra,8(sp)
    80002b96:	e022                	sd	s0,0(sp)
    80002b98:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002b9a:	fffff097          	auipc	ra,0xfffff
    80002b9e:	e26080e7          	jalr	-474(ra) # 800019c0 <myproc>
}
    80002ba2:	5d08                	lw	a0,56(a0)
    80002ba4:	60a2                	ld	ra,8(sp)
    80002ba6:	6402                	ld	s0,0(sp)
    80002ba8:	0141                	addi	sp,sp,16
    80002baa:	8082                	ret

0000000080002bac <sys_fork>:

uint64
sys_fork(void)
{
    80002bac:	1141                	addi	sp,sp,-16
    80002bae:	e406                	sd	ra,8(sp)
    80002bb0:	e022                	sd	s0,0(sp)
    80002bb2:	0800                	addi	s0,sp,16
  return fork();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	1cc080e7          	jalr	460(ra) # 80001d80 <fork>
}
    80002bbc:	60a2                	ld	ra,8(sp)
    80002bbe:	6402                	ld	s0,0(sp)
    80002bc0:	0141                	addi	sp,sp,16
    80002bc2:	8082                	ret

0000000080002bc4 <sys_wait>:

uint64
sys_wait(void)
{
    80002bc4:	1101                	addi	sp,sp,-32
    80002bc6:	ec06                	sd	ra,24(sp)
    80002bc8:	e822                	sd	s0,16(sp)
    80002bca:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002bcc:	fe840593          	addi	a1,s0,-24
    80002bd0:	4501                	li	a0,0
    80002bd2:	00000097          	auipc	ra,0x0
    80002bd6:	ece080e7          	jalr	-306(ra) # 80002aa0 <argaddr>
    80002bda:	87aa                	mv	a5,a0
    return -1;
    80002bdc:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002bde:	0007c863          	bltz	a5,80002bee <sys_wait+0x2a>
  return wait(p);
    80002be2:	fe843503          	ld	a0,-24(s0)
    80002be6:	fffff097          	auipc	ra,0xfffff
    80002bea:	668080e7          	jalr	1640(ra) # 8000224e <wait>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	6105                	addi	sp,sp,32
    80002bf4:	8082                	ret

0000000080002bf6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002bf6:	7179                	addi	sp,sp,-48
    80002bf8:	f406                	sd	ra,40(sp)
    80002bfa:	f022                	sd	s0,32(sp)
    80002bfc:	ec26                	sd	s1,24(sp)
    80002bfe:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002c00:	fdc40593          	addi	a1,s0,-36
    80002c04:	4501                	li	a0,0
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	e78080e7          	jalr	-392(ra) # 80002a7e <argint>
    80002c0e:	87aa                	mv	a5,a0
    return -1;
    80002c10:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002c12:	0207c063          	bltz	a5,80002c32 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002c16:	fffff097          	auipc	ra,0xfffff
    80002c1a:	daa080e7          	jalr	-598(ra) # 800019c0 <myproc>
    80002c1e:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002c20:	fdc42503          	lw	a0,-36(s0)
    80002c24:	fffff097          	auipc	ra,0xfffff
    80002c28:	0e8080e7          	jalr	232(ra) # 80001d0c <growproc>
    80002c2c:	00054863          	bltz	a0,80002c3c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002c30:	8526                	mv	a0,s1
}
    80002c32:	70a2                	ld	ra,40(sp)
    80002c34:	7402                	ld	s0,32(sp)
    80002c36:	64e2                	ld	s1,24(sp)
    80002c38:	6145                	addi	sp,sp,48
    80002c3a:	8082                	ret
    return -1;
    80002c3c:	557d                	li	a0,-1
    80002c3e:	bfd5                	j	80002c32 <sys_sbrk+0x3c>

0000000080002c40 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002c40:	7139                	addi	sp,sp,-64
    80002c42:	fc06                	sd	ra,56(sp)
    80002c44:	f822                	sd	s0,48(sp)
    80002c46:	f426                	sd	s1,40(sp)
    80002c48:	f04a                	sd	s2,32(sp)
    80002c4a:	ec4e                	sd	s3,24(sp)
    80002c4c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002c4e:	fcc40593          	addi	a1,s0,-52
    80002c52:	4501                	li	a0,0
    80002c54:	00000097          	auipc	ra,0x0
    80002c58:	e2a080e7          	jalr	-470(ra) # 80002a7e <argint>
    return -1;
    80002c5c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c5e:	06054563          	bltz	a0,80002cc8 <sys_sleep+0x88>
  acquire(&tickslock);
    80002c62:	00010517          	auipc	a0,0x10
    80002c66:	86650513          	addi	a0,a0,-1946 # 800124c8 <tickslock>
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	f6c080e7          	jalr	-148(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002c72:	00006917          	auipc	s2,0x6
    80002c76:	3be92903          	lw	s2,958(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002c7a:	fcc42783          	lw	a5,-52(s0)
    80002c7e:	cf85                	beqz	a5,80002cb6 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002c80:	00010997          	auipc	s3,0x10
    80002c84:	84898993          	addi	s3,s3,-1976 # 800124c8 <tickslock>
    80002c88:	00006497          	auipc	s1,0x6
    80002c8c:	3a848493          	addi	s1,s1,936 # 80009030 <ticks>
    if(myproc()->killed){
    80002c90:	fffff097          	auipc	ra,0xfffff
    80002c94:	d30080e7          	jalr	-720(ra) # 800019c0 <myproc>
    80002c98:	591c                	lw	a5,48(a0)
    80002c9a:	ef9d                	bnez	a5,80002cd8 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002c9c:	85ce                	mv	a1,s3
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	fffff097          	auipc	ra,0xfffff
    80002ca4:	530080e7          	jalr	1328(ra) # 800021d0 <sleep>
  while(ticks - ticks0 < n){
    80002ca8:	409c                	lw	a5,0(s1)
    80002caa:	412787bb          	subw	a5,a5,s2
    80002cae:	fcc42703          	lw	a4,-52(s0)
    80002cb2:	fce7efe3          	bltu	a5,a4,80002c90 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002cb6:	00010517          	auipc	a0,0x10
    80002cba:	81250513          	addi	a0,a0,-2030 # 800124c8 <tickslock>
    80002cbe:	ffffe097          	auipc	ra,0xffffe
    80002cc2:	fcc080e7          	jalr	-52(ra) # 80000c8a <release>
  return 0;
    80002cc6:	4781                	li	a5,0
}
    80002cc8:	853e                	mv	a0,a5
    80002cca:	70e2                	ld	ra,56(sp)
    80002ccc:	7442                	ld	s0,48(sp)
    80002cce:	74a2                	ld	s1,40(sp)
    80002cd0:	7902                	ld	s2,32(sp)
    80002cd2:	69e2                	ld	s3,24(sp)
    80002cd4:	6121                	addi	sp,sp,64
    80002cd6:	8082                	ret
      release(&tickslock);
    80002cd8:	0000f517          	auipc	a0,0xf
    80002cdc:	7f050513          	addi	a0,a0,2032 # 800124c8 <tickslock>
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	faa080e7          	jalr	-86(ra) # 80000c8a <release>
      return -1;
    80002ce8:	57fd                	li	a5,-1
    80002cea:	bff9                	j	80002cc8 <sys_sleep+0x88>

0000000080002cec <sys_kill>:

uint64
sys_kill(void)
{
    80002cec:	1101                	addi	sp,sp,-32
    80002cee:	ec06                	sd	ra,24(sp)
    80002cf0:	e822                	sd	s0,16(sp)
    80002cf2:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002cf4:	fec40593          	addi	a1,s0,-20
    80002cf8:	4501                	li	a0,0
    80002cfa:	00000097          	auipc	ra,0x0
    80002cfe:	d84080e7          	jalr	-636(ra) # 80002a7e <argint>
    80002d02:	87aa                	mv	a5,a0
    return -1;
    80002d04:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002d06:	0007c863          	bltz	a5,80002d16 <sys_kill+0x2a>
  return kill(pid);
    80002d0a:	fec42503          	lw	a0,-20(s0)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	6b2080e7          	jalr	1714(ra) # 800023c0 <kill>
}
    80002d16:	60e2                	ld	ra,24(sp)
    80002d18:	6442                	ld	s0,16(sp)
    80002d1a:	6105                	addi	sp,sp,32
    80002d1c:	8082                	ret

0000000080002d1e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d1e:	1101                	addi	sp,sp,-32
    80002d20:	ec06                	sd	ra,24(sp)
    80002d22:	e822                	sd	s0,16(sp)
    80002d24:	e426                	sd	s1,8(sp)
    80002d26:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d28:	0000f517          	auipc	a0,0xf
    80002d2c:	7a050513          	addi	a0,a0,1952 # 800124c8 <tickslock>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	ea6080e7          	jalr	-346(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002d38:	00006497          	auipc	s1,0x6
    80002d3c:	2f84a483          	lw	s1,760(s1) # 80009030 <ticks>
  release(&tickslock);
    80002d40:	0000f517          	auipc	a0,0xf
    80002d44:	78850513          	addi	a0,a0,1928 # 800124c8 <tickslock>
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	f42080e7          	jalr	-190(ra) # 80000c8a <release>
  return xticks;
}
    80002d50:	02049513          	slli	a0,s1,0x20
    80002d54:	9101                	srli	a0,a0,0x20
    80002d56:	60e2                	ld	ra,24(sp)
    80002d58:	6442                	ld	s0,16(sp)
    80002d5a:	64a2                	ld	s1,8(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002d60:	7179                	addi	sp,sp,-48
    80002d62:	f406                	sd	ra,40(sp)
    80002d64:	f022                	sd	s0,32(sp)
    80002d66:	ec26                	sd	s1,24(sp)
    80002d68:	e84a                	sd	s2,16(sp)
    80002d6a:	e44e                	sd	s3,8(sp)
    80002d6c:	e052                	sd	s4,0(sp)
    80002d6e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002d70:	00005597          	auipc	a1,0x5
    80002d74:	76858593          	addi	a1,a1,1896 # 800084d8 <syscalls+0xb8>
    80002d78:	0000f517          	auipc	a0,0xf
    80002d7c:	76850513          	addi	a0,a0,1896 # 800124e0 <bcache>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	dc6080e7          	jalr	-570(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002d88:	00017797          	auipc	a5,0x17
    80002d8c:	75878793          	addi	a5,a5,1880 # 8001a4e0 <bcache+0x8000>
    80002d90:	00018717          	auipc	a4,0x18
    80002d94:	9b870713          	addi	a4,a4,-1608 # 8001a748 <bcache+0x8268>
    80002d98:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002d9c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002da0:	0000f497          	auipc	s1,0xf
    80002da4:	75848493          	addi	s1,s1,1880 # 800124f8 <bcache+0x18>
    b->next = bcache.head.next;
    80002da8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002daa:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002dac:	00005a17          	auipc	s4,0x5
    80002db0:	734a0a13          	addi	s4,s4,1844 # 800084e0 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002db4:	2b893783          	ld	a5,696(s2)
    80002db8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002dba:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002dbe:	85d2                	mv	a1,s4
    80002dc0:	01048513          	addi	a0,s1,16
    80002dc4:	00001097          	auipc	ra,0x1
    80002dc8:	632080e7          	jalr	1586(ra) # 800043f6 <initsleeplock>
    bcache.head.next->prev = b;
    80002dcc:	2b893783          	ld	a5,696(s2)
    80002dd0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002dd2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002dd6:	45848493          	addi	s1,s1,1112
    80002dda:	fd349de3          	bne	s1,s3,80002db4 <binit+0x54>
  }
}
    80002dde:	70a2                	ld	ra,40(sp)
    80002de0:	7402                	ld	s0,32(sp)
    80002de2:	64e2                	ld	s1,24(sp)
    80002de4:	6942                	ld	s2,16(sp)
    80002de6:	69a2                	ld	s3,8(sp)
    80002de8:	6a02                	ld	s4,0(sp)
    80002dea:	6145                	addi	sp,sp,48
    80002dec:	8082                	ret

0000000080002dee <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002dee:	7179                	addi	sp,sp,-48
    80002df0:	f406                	sd	ra,40(sp)
    80002df2:	f022                	sd	s0,32(sp)
    80002df4:	ec26                	sd	s1,24(sp)
    80002df6:	e84a                	sd	s2,16(sp)
    80002df8:	e44e                	sd	s3,8(sp)
    80002dfa:	1800                	addi	s0,sp,48
    80002dfc:	89aa                	mv	s3,a0
    80002dfe:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002e00:	0000f517          	auipc	a0,0xf
    80002e04:	6e050513          	addi	a0,a0,1760 # 800124e0 <bcache>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	dce080e7          	jalr	-562(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002e10:	00018497          	auipc	s1,0x18
    80002e14:	9884b483          	ld	s1,-1656(s1) # 8001a798 <bcache+0x82b8>
    80002e18:	00018797          	auipc	a5,0x18
    80002e1c:	93078793          	addi	a5,a5,-1744 # 8001a748 <bcache+0x8268>
    80002e20:	02f48f63          	beq	s1,a5,80002e5e <bread+0x70>
    80002e24:	873e                	mv	a4,a5
    80002e26:	a021                	j	80002e2e <bread+0x40>
    80002e28:	68a4                	ld	s1,80(s1)
    80002e2a:	02e48a63          	beq	s1,a4,80002e5e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002e2e:	449c                	lw	a5,8(s1)
    80002e30:	ff379ce3          	bne	a5,s3,80002e28 <bread+0x3a>
    80002e34:	44dc                	lw	a5,12(s1)
    80002e36:	ff2799e3          	bne	a5,s2,80002e28 <bread+0x3a>
      b->refcnt++;
    80002e3a:	40bc                	lw	a5,64(s1)
    80002e3c:	2785                	addiw	a5,a5,1
    80002e3e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e40:	0000f517          	auipc	a0,0xf
    80002e44:	6a050513          	addi	a0,a0,1696 # 800124e0 <bcache>
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002e50:	01048513          	addi	a0,s1,16
    80002e54:	00001097          	auipc	ra,0x1
    80002e58:	5dc080e7          	jalr	1500(ra) # 80004430 <acquiresleep>
      return b;
    80002e5c:	a8b9                	j	80002eba <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e5e:	00018497          	auipc	s1,0x18
    80002e62:	9324b483          	ld	s1,-1742(s1) # 8001a790 <bcache+0x82b0>
    80002e66:	00018797          	auipc	a5,0x18
    80002e6a:	8e278793          	addi	a5,a5,-1822 # 8001a748 <bcache+0x8268>
    80002e6e:	00f48863          	beq	s1,a5,80002e7e <bread+0x90>
    80002e72:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002e74:	40bc                	lw	a5,64(s1)
    80002e76:	cf81                	beqz	a5,80002e8e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002e78:	64a4                	ld	s1,72(s1)
    80002e7a:	fee49de3          	bne	s1,a4,80002e74 <bread+0x86>
  panic("bget: no buffers");
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	66a50513          	addi	a0,a0,1642 # 800084e8 <syscalls+0xc8>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	6aa080e7          	jalr	1706(ra) # 80000530 <panic>
      b->dev = dev;
    80002e8e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002e92:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002e96:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002e9a:	4785                	li	a5,1
    80002e9c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002e9e:	0000f517          	auipc	a0,0xf
    80002ea2:	64250513          	addi	a0,a0,1602 # 800124e0 <bcache>
    80002ea6:	ffffe097          	auipc	ra,0xffffe
    80002eaa:	de4080e7          	jalr	-540(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002eae:	01048513          	addi	a0,s1,16
    80002eb2:	00001097          	auipc	ra,0x1
    80002eb6:	57e080e7          	jalr	1406(ra) # 80004430 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002eba:	409c                	lw	a5,0(s1)
    80002ebc:	cb89                	beqz	a5,80002ece <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ebe:	8526                	mv	a0,s1
    80002ec0:	70a2                	ld	ra,40(sp)
    80002ec2:	7402                	ld	s0,32(sp)
    80002ec4:	64e2                	ld	s1,24(sp)
    80002ec6:	6942                	ld	s2,16(sp)
    80002ec8:	69a2                	ld	s3,8(sp)
    80002eca:	6145                	addi	sp,sp,48
    80002ecc:	8082                	ret
    virtio_disk_rw(b, 0);
    80002ece:	4581                	li	a1,0
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	00003097          	auipc	ra,0x3
    80002ed6:	1b4080e7          	jalr	436(ra) # 80006086 <virtio_disk_rw>
    b->valid = 1;
    80002eda:	4785                	li	a5,1
    80002edc:	c09c                	sw	a5,0(s1)
  return b;
    80002ede:	b7c5                	j	80002ebe <bread+0xd0>

0000000080002ee0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
    80002eea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002eec:	0541                	addi	a0,a0,16
    80002eee:	00001097          	auipc	ra,0x1
    80002ef2:	5dc080e7          	jalr	1500(ra) # 800044ca <holdingsleep>
    80002ef6:	cd01                	beqz	a0,80002f0e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002ef8:	4585                	li	a1,1
    80002efa:	8526                	mv	a0,s1
    80002efc:	00003097          	auipc	ra,0x3
    80002f00:	18a080e7          	jalr	394(ra) # 80006086 <virtio_disk_rw>
}
    80002f04:	60e2                	ld	ra,24(sp)
    80002f06:	6442                	ld	s0,16(sp)
    80002f08:	64a2                	ld	s1,8(sp)
    80002f0a:	6105                	addi	sp,sp,32
    80002f0c:	8082                	ret
    panic("bwrite");
    80002f0e:	00005517          	auipc	a0,0x5
    80002f12:	5f250513          	addi	a0,a0,1522 # 80008500 <syscalls+0xe0>
    80002f16:	ffffd097          	auipc	ra,0xffffd
    80002f1a:	61a080e7          	jalr	1562(ra) # 80000530 <panic>

0000000080002f1e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f1e:	1101                	addi	sp,sp,-32
    80002f20:	ec06                	sd	ra,24(sp)
    80002f22:	e822                	sd	s0,16(sp)
    80002f24:	e426                	sd	s1,8(sp)
    80002f26:	e04a                	sd	s2,0(sp)
    80002f28:	1000                	addi	s0,sp,32
    80002f2a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f2c:	01050913          	addi	s2,a0,16
    80002f30:	854a                	mv	a0,s2
    80002f32:	00001097          	auipc	ra,0x1
    80002f36:	598080e7          	jalr	1432(ra) # 800044ca <holdingsleep>
    80002f3a:	c92d                	beqz	a0,80002fac <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80002f3c:	854a                	mv	a0,s2
    80002f3e:	00001097          	auipc	ra,0x1
    80002f42:	548080e7          	jalr	1352(ra) # 80004486 <releasesleep>

  acquire(&bcache.lock);
    80002f46:	0000f517          	auipc	a0,0xf
    80002f4a:	59a50513          	addi	a0,a0,1434 # 800124e0 <bcache>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	c88080e7          	jalr	-888(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80002f56:	40bc                	lw	a5,64(s1)
    80002f58:	37fd                	addiw	a5,a5,-1
    80002f5a:	0007871b          	sext.w	a4,a5
    80002f5e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002f60:	eb05                	bnez	a4,80002f90 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002f62:	68bc                	ld	a5,80(s1)
    80002f64:	64b8                	ld	a4,72(s1)
    80002f66:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80002f68:	64bc                	ld	a5,72(s1)
    80002f6a:	68b8                	ld	a4,80(s1)
    80002f6c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002f6e:	00017797          	auipc	a5,0x17
    80002f72:	57278793          	addi	a5,a5,1394 # 8001a4e0 <bcache+0x8000>
    80002f76:	2b87b703          	ld	a4,696(a5)
    80002f7a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002f7c:	00017717          	auipc	a4,0x17
    80002f80:	7cc70713          	addi	a4,a4,1996 # 8001a748 <bcache+0x8268>
    80002f84:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002f86:	2b87b703          	ld	a4,696(a5)
    80002f8a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002f8c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002f90:	0000f517          	auipc	a0,0xf
    80002f94:	55050513          	addi	a0,a0,1360 # 800124e0 <bcache>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	cf2080e7          	jalr	-782(ra) # 80000c8a <release>
}
    80002fa0:	60e2                	ld	ra,24(sp)
    80002fa2:	6442                	ld	s0,16(sp)
    80002fa4:	64a2                	ld	s1,8(sp)
    80002fa6:	6902                	ld	s2,0(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret
    panic("brelse");
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	55c50513          	addi	a0,a0,1372 # 80008508 <syscalls+0xe8>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	57c080e7          	jalr	1404(ra) # 80000530 <panic>

0000000080002fbc <bpin>:

void
bpin(struct buf *b) {
    80002fbc:	1101                	addi	sp,sp,-32
    80002fbe:	ec06                	sd	ra,24(sp)
    80002fc0:	e822                	sd	s0,16(sp)
    80002fc2:	e426                	sd	s1,8(sp)
    80002fc4:	1000                	addi	s0,sp,32
    80002fc6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002fc8:	0000f517          	auipc	a0,0xf
    80002fcc:	51850513          	addi	a0,a0,1304 # 800124e0 <bcache>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	c06080e7          	jalr	-1018(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80002fd8:	40bc                	lw	a5,64(s1)
    80002fda:	2785                	addiw	a5,a5,1
    80002fdc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002fde:	0000f517          	auipc	a0,0xf
    80002fe2:	50250513          	addi	a0,a0,1282 # 800124e0 <bcache>
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	ca4080e7          	jalr	-860(ra) # 80000c8a <release>
}
    80002fee:	60e2                	ld	ra,24(sp)
    80002ff0:	6442                	ld	s0,16(sp)
    80002ff2:	64a2                	ld	s1,8(sp)
    80002ff4:	6105                	addi	sp,sp,32
    80002ff6:	8082                	ret

0000000080002ff8 <bunpin>:

void
bunpin(struct buf *b) {
    80002ff8:	1101                	addi	sp,sp,-32
    80002ffa:	ec06                	sd	ra,24(sp)
    80002ffc:	e822                	sd	s0,16(sp)
    80002ffe:	e426                	sd	s1,8(sp)
    80003000:	1000                	addi	s0,sp,32
    80003002:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003004:	0000f517          	auipc	a0,0xf
    80003008:	4dc50513          	addi	a0,a0,1244 # 800124e0 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	bca080e7          	jalr	-1078(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003014:	40bc                	lw	a5,64(s1)
    80003016:	37fd                	addiw	a5,a5,-1
    80003018:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000301a:	0000f517          	auipc	a0,0xf
    8000301e:	4c650513          	addi	a0,a0,1222 # 800124e0 <bcache>
    80003022:	ffffe097          	auipc	ra,0xffffe
    80003026:	c68080e7          	jalr	-920(ra) # 80000c8a <release>
}
    8000302a:	60e2                	ld	ra,24(sp)
    8000302c:	6442                	ld	s0,16(sp)
    8000302e:	64a2                	ld	s1,8(sp)
    80003030:	6105                	addi	sp,sp,32
    80003032:	8082                	ret

0000000080003034 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003034:	1101                	addi	sp,sp,-32
    80003036:	ec06                	sd	ra,24(sp)
    80003038:	e822                	sd	s0,16(sp)
    8000303a:	e426                	sd	s1,8(sp)
    8000303c:	e04a                	sd	s2,0(sp)
    8000303e:	1000                	addi	s0,sp,32
    80003040:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003042:	00d5d59b          	srliw	a1,a1,0xd
    80003046:	00018797          	auipc	a5,0x18
    8000304a:	b767a783          	lw	a5,-1162(a5) # 8001abbc <sb+0x1c>
    8000304e:	9dbd                	addw	a1,a1,a5
    80003050:	00000097          	auipc	ra,0x0
    80003054:	d9e080e7          	jalr	-610(ra) # 80002dee <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003058:	0074f713          	andi	a4,s1,7
    8000305c:	4785                	li	a5,1
    8000305e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003062:	14ce                	slli	s1,s1,0x33
    80003064:	90d9                	srli	s1,s1,0x36
    80003066:	00950733          	add	a4,a0,s1
    8000306a:	05874703          	lbu	a4,88(a4)
    8000306e:	00e7f6b3          	and	a3,a5,a4
    80003072:	c69d                	beqz	a3,800030a0 <bfree+0x6c>
    80003074:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003076:	94aa                	add	s1,s1,a0
    80003078:	fff7c793          	not	a5,a5
    8000307c:	8ff9                	and	a5,a5,a4
    8000307e:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003082:	00001097          	auipc	ra,0x1
    80003086:	286080e7          	jalr	646(ra) # 80004308 <log_write>
  brelse(bp);
    8000308a:	854a                	mv	a0,s2
    8000308c:	00000097          	auipc	ra,0x0
    80003090:	e92080e7          	jalr	-366(ra) # 80002f1e <brelse>
}
    80003094:	60e2                	ld	ra,24(sp)
    80003096:	6442                	ld	s0,16(sp)
    80003098:	64a2                	ld	s1,8(sp)
    8000309a:	6902                	ld	s2,0(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret
    panic("freeing free block");
    800030a0:	00005517          	auipc	a0,0x5
    800030a4:	47050513          	addi	a0,a0,1136 # 80008510 <syscalls+0xf0>
    800030a8:	ffffd097          	auipc	ra,0xffffd
    800030ac:	488080e7          	jalr	1160(ra) # 80000530 <panic>

00000000800030b0 <balloc>:
{
    800030b0:	711d                	addi	sp,sp,-96
    800030b2:	ec86                	sd	ra,88(sp)
    800030b4:	e8a2                	sd	s0,80(sp)
    800030b6:	e4a6                	sd	s1,72(sp)
    800030b8:	e0ca                	sd	s2,64(sp)
    800030ba:	fc4e                	sd	s3,56(sp)
    800030bc:	f852                	sd	s4,48(sp)
    800030be:	f456                	sd	s5,40(sp)
    800030c0:	f05a                	sd	s6,32(sp)
    800030c2:	ec5e                	sd	s7,24(sp)
    800030c4:	e862                	sd	s8,16(sp)
    800030c6:	e466                	sd	s9,8(sp)
    800030c8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030ca:	00018797          	auipc	a5,0x18
    800030ce:	ada7a783          	lw	a5,-1318(a5) # 8001aba4 <sb+0x4>
    800030d2:	cbd1                	beqz	a5,80003166 <balloc+0xb6>
    800030d4:	8baa                	mv	s7,a0
    800030d6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800030d8:	00018b17          	auipc	s6,0x18
    800030dc:	ac8b0b13          	addi	s6,s6,-1336 # 8001aba0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030e0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800030e2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800030e4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800030e6:	6c89                	lui	s9,0x2
    800030e8:	a831                	j	80003104 <balloc+0x54>
    brelse(bp);
    800030ea:	854a                	mv	a0,s2
    800030ec:	00000097          	auipc	ra,0x0
    800030f0:	e32080e7          	jalr	-462(ra) # 80002f1e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800030f4:	015c87bb          	addw	a5,s9,s5
    800030f8:	00078a9b          	sext.w	s5,a5
    800030fc:	004b2703          	lw	a4,4(s6)
    80003100:	06eaf363          	bgeu	s5,a4,80003166 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003104:	41fad79b          	sraiw	a5,s5,0x1f
    80003108:	0137d79b          	srliw	a5,a5,0x13
    8000310c:	015787bb          	addw	a5,a5,s5
    80003110:	40d7d79b          	sraiw	a5,a5,0xd
    80003114:	01cb2583          	lw	a1,28(s6)
    80003118:	9dbd                	addw	a1,a1,a5
    8000311a:	855e                	mv	a0,s7
    8000311c:	00000097          	auipc	ra,0x0
    80003120:	cd2080e7          	jalr	-814(ra) # 80002dee <bread>
    80003124:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003126:	004b2503          	lw	a0,4(s6)
    8000312a:	000a849b          	sext.w	s1,s5
    8000312e:	8662                	mv	a2,s8
    80003130:	faa4fde3          	bgeu	s1,a0,800030ea <balloc+0x3a>
      m = 1 << (bi % 8);
    80003134:	41f6579b          	sraiw	a5,a2,0x1f
    80003138:	01d7d69b          	srliw	a3,a5,0x1d
    8000313c:	00c6873b          	addw	a4,a3,a2
    80003140:	00777793          	andi	a5,a4,7
    80003144:	9f95                	subw	a5,a5,a3
    80003146:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000314a:	4037571b          	sraiw	a4,a4,0x3
    8000314e:	00e906b3          	add	a3,s2,a4
    80003152:	0586c683          	lbu	a3,88(a3)
    80003156:	00d7f5b3          	and	a1,a5,a3
    8000315a:	cd91                	beqz	a1,80003176 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000315c:	2605                	addiw	a2,a2,1
    8000315e:	2485                	addiw	s1,s1,1
    80003160:	fd4618e3          	bne	a2,s4,80003130 <balloc+0x80>
    80003164:	b759                	j	800030ea <balloc+0x3a>
  panic("balloc: out of blocks");
    80003166:	00005517          	auipc	a0,0x5
    8000316a:	3c250513          	addi	a0,a0,962 # 80008528 <syscalls+0x108>
    8000316e:	ffffd097          	auipc	ra,0xffffd
    80003172:	3c2080e7          	jalr	962(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003176:	974a                	add	a4,a4,s2
    80003178:	8fd5                	or	a5,a5,a3
    8000317a:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000317e:	854a                	mv	a0,s2
    80003180:	00001097          	auipc	ra,0x1
    80003184:	188080e7          	jalr	392(ra) # 80004308 <log_write>
        brelse(bp);
    80003188:	854a                	mv	a0,s2
    8000318a:	00000097          	auipc	ra,0x0
    8000318e:	d94080e7          	jalr	-620(ra) # 80002f1e <brelse>
  bp = bread(dev, bno);
    80003192:	85a6                	mv	a1,s1
    80003194:	855e                	mv	a0,s7
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	c58080e7          	jalr	-936(ra) # 80002dee <bread>
    8000319e:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800031a0:	40000613          	li	a2,1024
    800031a4:	4581                	li	a1,0
    800031a6:	05850513          	addi	a0,a0,88
    800031aa:	ffffe097          	auipc	ra,0xffffe
    800031ae:	b28080e7          	jalr	-1240(ra) # 80000cd2 <memset>
  log_write(bp);
    800031b2:	854a                	mv	a0,s2
    800031b4:	00001097          	auipc	ra,0x1
    800031b8:	154080e7          	jalr	340(ra) # 80004308 <log_write>
  brelse(bp);
    800031bc:	854a                	mv	a0,s2
    800031be:	00000097          	auipc	ra,0x0
    800031c2:	d60080e7          	jalr	-672(ra) # 80002f1e <brelse>
}
    800031c6:	8526                	mv	a0,s1
    800031c8:	60e6                	ld	ra,88(sp)
    800031ca:	6446                	ld	s0,80(sp)
    800031cc:	64a6                	ld	s1,72(sp)
    800031ce:	6906                	ld	s2,64(sp)
    800031d0:	79e2                	ld	s3,56(sp)
    800031d2:	7a42                	ld	s4,48(sp)
    800031d4:	7aa2                	ld	s5,40(sp)
    800031d6:	7b02                	ld	s6,32(sp)
    800031d8:	6be2                	ld	s7,24(sp)
    800031da:	6c42                	ld	s8,16(sp)
    800031dc:	6ca2                	ld	s9,8(sp)
    800031de:	6125                	addi	sp,sp,96
    800031e0:	8082                	ret

00000000800031e2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800031e2:	7139                	addi	sp,sp,-64
    800031e4:	fc06                	sd	ra,56(sp)
    800031e6:	f822                	sd	s0,48(sp)
    800031e8:	f426                	sd	s1,40(sp)
    800031ea:	f04a                	sd	s2,32(sp)
    800031ec:	ec4e                	sd	s3,24(sp)
    800031ee:	e852                	sd	s4,16(sp)
    800031f0:	e456                	sd	s5,8(sp)
    800031f2:	0080                	addi	s0,sp,64
    800031f4:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800031f6:	47a9                	li	a5,10
    800031f8:	08b7fd63          	bgeu	a5,a1,80003292 <bmap+0xb0>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800031fc:	ff55849b          	addiw	s1,a1,-11
    80003200:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003204:	0ff00793          	li	a5,255
    80003208:	0ae7f863          	bgeu	a5,a4,800032b8 <bmap+0xd6>
      log_write(bp);
    }
    brelse(bp);
    return addr;
  }
  bn -= NINDIRECT;
    8000320c:	ef55849b          	addiw	s1,a1,-267
    80003210:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT * NINDIRECT) { // doubly-indirect
    80003214:	67c1                	lui	a5,0x10
    80003216:	14f77e63          	bgeu	a4,a5,80003372 <bmap+0x190>
    uint addr2, *a2;
    if((addr = ip->addrs[NDIRECT+1]) == 0)
    8000321a:	08052583          	lw	a1,128(a0)
    8000321e:	10058063          	beqz	a1,8000331e <bmap+0x13c>
      ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003222:	0009a503          	lw	a0,0(s3)
    80003226:	00000097          	auipc	ra,0x0
    8000322a:	bc8080e7          	jalr	-1080(ra) # 80002dee <bread>
    8000322e:	892a                	mv	s2,a0
    a = (uint*)bp->data;
    80003230:	05850a13          	addi	s4,a0,88
    if((addr2 = a[bn/NINDIRECT]) == 0){
    80003234:	0084d79b          	srliw	a5,s1,0x8
    80003238:	078a                	slli	a5,a5,0x2
    8000323a:	9a3e                	add	s4,s4,a5
    8000323c:	000a2a83          	lw	s5,0(s4) # 2000 <_entry-0x7fffe000>
    80003240:	0e0a8963          	beqz	s5,80003332 <bmap+0x150>
      a[bn/NINDIRECT] = addr2 = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003244:	854a                	mv	a0,s2
    80003246:	00000097          	auipc	ra,0x0
    8000324a:	cd8080e7          	jalr	-808(ra) # 80002f1e <brelse>

    bn %= NINDIRECT;
    bp = bread(ip->dev, addr2);
    8000324e:	85d6                	mv	a1,s5
    80003250:	0009a503          	lw	a0,0(s3)
    80003254:	00000097          	auipc	ra,0x0
    80003258:	b9a080e7          	jalr	-1126(ra) # 80002dee <bread>
    8000325c:	8a2a                	mv	s4,a0
    a2 = (uint*)bp->data;
    8000325e:	05850793          	addi	a5,a0,88
    if((addr = a2[bn]) == 0){
    80003262:	0ff4f593          	andi	a1,s1,255
    80003266:	058a                	slli	a1,a1,0x2
    80003268:	00b784b3          	add	s1,a5,a1
    8000326c:	0004a903          	lw	s2,0(s1)
    80003270:	0e090163          	beqz	s2,80003352 <bmap+0x170>
      a2[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003274:	8552                	mv	a0,s4
    80003276:	00000097          	auipc	ra,0x0
    8000327a:	ca8080e7          	jalr	-856(ra) # 80002f1e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000327e:	854a                	mv	a0,s2
    80003280:	70e2                	ld	ra,56(sp)
    80003282:	7442                	ld	s0,48(sp)
    80003284:	74a2                	ld	s1,40(sp)
    80003286:	7902                	ld	s2,32(sp)
    80003288:	69e2                	ld	s3,24(sp)
    8000328a:	6a42                	ld	s4,16(sp)
    8000328c:	6aa2                	ld	s5,8(sp)
    8000328e:	6121                	addi	sp,sp,64
    80003290:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003292:	02059493          	slli	s1,a1,0x20
    80003296:	9081                	srli	s1,s1,0x20
    80003298:	048a                	slli	s1,s1,0x2
    8000329a:	94aa                	add	s1,s1,a0
    8000329c:	0504a903          	lw	s2,80(s1)
    800032a0:	fc091fe3          	bnez	s2,8000327e <bmap+0x9c>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800032a4:	4108                	lw	a0,0(a0)
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	e0a080e7          	jalr	-502(ra) # 800030b0 <balloc>
    800032ae:	0005091b          	sext.w	s2,a0
    800032b2:	0524a823          	sw	s2,80(s1)
    800032b6:	b7e1                	j	8000327e <bmap+0x9c>
    if((addr = ip->addrs[NDIRECT]) == 0)
    800032b8:	5d6c                	lw	a1,124(a0)
    800032ba:	c985                	beqz	a1,800032ea <bmap+0x108>
    bp = bread(ip->dev, addr);
    800032bc:	0009a503          	lw	a0,0(s3)
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	b2e080e7          	jalr	-1234(ra) # 80002dee <bread>
    800032c8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800032ca:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800032ce:	1482                	slli	s1,s1,0x20
    800032d0:	9081                	srli	s1,s1,0x20
    800032d2:	048a                	slli	s1,s1,0x2
    800032d4:	94be                	add	s1,s1,a5
    800032d6:	0004a903          	lw	s2,0(s1)
    800032da:	02090263          	beqz	s2,800032fe <bmap+0x11c>
    brelse(bp);
    800032de:	8552                	mv	a0,s4
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	c3e080e7          	jalr	-962(ra) # 80002f1e <brelse>
    return addr;
    800032e8:	bf59                	j	8000327e <bmap+0x9c>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800032ea:	4108                	lw	a0,0(a0)
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	dc4080e7          	jalr	-572(ra) # 800030b0 <balloc>
    800032f4:	0005059b          	sext.w	a1,a0
    800032f8:	06b9ae23          	sw	a1,124(s3)
    800032fc:	b7c1                	j	800032bc <bmap+0xda>
      a[bn] = addr = balloc(ip->dev);
    800032fe:	0009a503          	lw	a0,0(s3)
    80003302:	00000097          	auipc	ra,0x0
    80003306:	dae080e7          	jalr	-594(ra) # 800030b0 <balloc>
    8000330a:	0005091b          	sext.w	s2,a0
    8000330e:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003312:	8552                	mv	a0,s4
    80003314:	00001097          	auipc	ra,0x1
    80003318:	ff4080e7          	jalr	-12(ra) # 80004308 <log_write>
    8000331c:	b7c9                	j	800032de <bmap+0xfc>
      ip->addrs[NDIRECT+1] = addr = balloc(ip->dev);
    8000331e:	4108                	lw	a0,0(a0)
    80003320:	00000097          	auipc	ra,0x0
    80003324:	d90080e7          	jalr	-624(ra) # 800030b0 <balloc>
    80003328:	0005059b          	sext.w	a1,a0
    8000332c:	08b9a023          	sw	a1,128(s3)
    80003330:	bdcd                	j	80003222 <bmap+0x40>
      a[bn/NINDIRECT] = addr2 = balloc(ip->dev);
    80003332:	0009a503          	lw	a0,0(s3)
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	d7a080e7          	jalr	-646(ra) # 800030b0 <balloc>
    8000333e:	00050a9b          	sext.w	s5,a0
    80003342:	015a2023          	sw	s5,0(s4)
      log_write(bp);
    80003346:	854a                	mv	a0,s2
    80003348:	00001097          	auipc	ra,0x1
    8000334c:	fc0080e7          	jalr	-64(ra) # 80004308 <log_write>
    80003350:	bdd5                	j	80003244 <bmap+0x62>
      a2[bn] = addr = balloc(ip->dev);
    80003352:	0009a503          	lw	a0,0(s3)
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	d5a080e7          	jalr	-678(ra) # 800030b0 <balloc>
    8000335e:	0005091b          	sext.w	s2,a0
    80003362:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003366:	8552                	mv	a0,s4
    80003368:	00001097          	auipc	ra,0x1
    8000336c:	fa0080e7          	jalr	-96(ra) # 80004308 <log_write>
    80003370:	b711                	j	80003274 <bmap+0x92>
  panic("bmap: out of range");
    80003372:	00005517          	auipc	a0,0x5
    80003376:	1ce50513          	addi	a0,a0,462 # 80008540 <syscalls+0x120>
    8000337a:	ffffd097          	auipc	ra,0xffffd
    8000337e:	1b6080e7          	jalr	438(ra) # 80000530 <panic>

0000000080003382 <iget>:
{
    80003382:	7179                	addi	sp,sp,-48
    80003384:	f406                	sd	ra,40(sp)
    80003386:	f022                	sd	s0,32(sp)
    80003388:	ec26                	sd	s1,24(sp)
    8000338a:	e84a                	sd	s2,16(sp)
    8000338c:	e44e                	sd	s3,8(sp)
    8000338e:	e052                	sd	s4,0(sp)
    80003390:	1800                	addi	s0,sp,48
    80003392:	89aa                	mv	s3,a0
    80003394:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003396:	00018517          	auipc	a0,0x18
    8000339a:	82a50513          	addi	a0,a0,-2006 # 8001abc0 <icache>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	838080e7          	jalr	-1992(ra) # 80000bd6 <acquire>
  empty = 0;
    800033a6:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033a8:	00018497          	auipc	s1,0x18
    800033ac:	83048493          	addi	s1,s1,-2000 # 8001abd8 <icache+0x18>
    800033b0:	00019697          	auipc	a3,0x19
    800033b4:	2b868693          	addi	a3,a3,696 # 8001c668 <log>
    800033b8:	a039                	j	800033c6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033ba:	02090b63          	beqz	s2,800033f0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800033be:	08848493          	addi	s1,s1,136
    800033c2:	02d48a63          	beq	s1,a3,800033f6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800033c6:	449c                	lw	a5,8(s1)
    800033c8:	fef059e3          	blez	a5,800033ba <iget+0x38>
    800033cc:	4098                	lw	a4,0(s1)
    800033ce:	ff3716e3          	bne	a4,s3,800033ba <iget+0x38>
    800033d2:	40d8                	lw	a4,4(s1)
    800033d4:	ff4713e3          	bne	a4,s4,800033ba <iget+0x38>
      ip->ref++;
    800033d8:	2785                	addiw	a5,a5,1
    800033da:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800033dc:	00017517          	auipc	a0,0x17
    800033e0:	7e450513          	addi	a0,a0,2020 # 8001abc0 <icache>
    800033e4:	ffffe097          	auipc	ra,0xffffe
    800033e8:	8a6080e7          	jalr	-1882(ra) # 80000c8a <release>
      return ip;
    800033ec:	8926                	mv	s2,s1
    800033ee:	a03d                	j	8000341c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800033f0:	f7f9                	bnez	a5,800033be <iget+0x3c>
    800033f2:	8926                	mv	s2,s1
    800033f4:	b7e9                	j	800033be <iget+0x3c>
  if(empty == 0)
    800033f6:	02090c63          	beqz	s2,8000342e <iget+0xac>
  ip->dev = dev;
    800033fa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800033fe:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003402:	4785                	li	a5,1
    80003404:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003408:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000340c:	00017517          	auipc	a0,0x17
    80003410:	7b450513          	addi	a0,a0,1972 # 8001abc0 <icache>
    80003414:	ffffe097          	auipc	ra,0xffffe
    80003418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
}
    8000341c:	854a                	mv	a0,s2
    8000341e:	70a2                	ld	ra,40(sp)
    80003420:	7402                	ld	s0,32(sp)
    80003422:	64e2                	ld	s1,24(sp)
    80003424:	6942                	ld	s2,16(sp)
    80003426:	69a2                	ld	s3,8(sp)
    80003428:	6a02                	ld	s4,0(sp)
    8000342a:	6145                	addi	sp,sp,48
    8000342c:	8082                	ret
    panic("iget: no inodes");
    8000342e:	00005517          	auipc	a0,0x5
    80003432:	12a50513          	addi	a0,a0,298 # 80008558 <syscalls+0x138>
    80003436:	ffffd097          	auipc	ra,0xffffd
    8000343a:	0fa080e7          	jalr	250(ra) # 80000530 <panic>

000000008000343e <fsinit>:
fsinit(int dev) {
    8000343e:	7179                	addi	sp,sp,-48
    80003440:	f406                	sd	ra,40(sp)
    80003442:	f022                	sd	s0,32(sp)
    80003444:	ec26                	sd	s1,24(sp)
    80003446:	e84a                	sd	s2,16(sp)
    80003448:	e44e                	sd	s3,8(sp)
    8000344a:	1800                	addi	s0,sp,48
    8000344c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000344e:	4585                	li	a1,1
    80003450:	00000097          	auipc	ra,0x0
    80003454:	99e080e7          	jalr	-1634(ra) # 80002dee <bread>
    80003458:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000345a:	00017997          	auipc	s3,0x17
    8000345e:	74698993          	addi	s3,s3,1862 # 8001aba0 <sb>
    80003462:	02000613          	li	a2,32
    80003466:	05850593          	addi	a1,a0,88
    8000346a:	854e                	mv	a0,s3
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	8c6080e7          	jalr	-1850(ra) # 80000d32 <memmove>
  brelse(bp);
    80003474:	8526                	mv	a0,s1
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	aa8080e7          	jalr	-1368(ra) # 80002f1e <brelse>
  if(sb.magic != FSMAGIC)
    8000347e:	0009a703          	lw	a4,0(s3)
    80003482:	102037b7          	lui	a5,0x10203
    80003486:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000348a:	02f71263          	bne	a4,a5,800034ae <fsinit+0x70>
  initlog(dev, &sb);
    8000348e:	00017597          	auipc	a1,0x17
    80003492:	71258593          	addi	a1,a1,1810 # 8001aba0 <sb>
    80003496:	854a                	mv	a0,s2
    80003498:	00001097          	auipc	ra,0x1
    8000349c:	bf4080e7          	jalr	-1036(ra) # 8000408c <initlog>
}
    800034a0:	70a2                	ld	ra,40(sp)
    800034a2:	7402                	ld	s0,32(sp)
    800034a4:	64e2                	ld	s1,24(sp)
    800034a6:	6942                	ld	s2,16(sp)
    800034a8:	69a2                	ld	s3,8(sp)
    800034aa:	6145                	addi	sp,sp,48
    800034ac:	8082                	ret
    panic("invalid file system");
    800034ae:	00005517          	auipc	a0,0x5
    800034b2:	0ba50513          	addi	a0,a0,186 # 80008568 <syscalls+0x148>
    800034b6:	ffffd097          	auipc	ra,0xffffd
    800034ba:	07a080e7          	jalr	122(ra) # 80000530 <panic>

00000000800034be <iinit>:
{
    800034be:	7179                	addi	sp,sp,-48
    800034c0:	f406                	sd	ra,40(sp)
    800034c2:	f022                	sd	s0,32(sp)
    800034c4:	ec26                	sd	s1,24(sp)
    800034c6:	e84a                	sd	s2,16(sp)
    800034c8:	e44e                	sd	s3,8(sp)
    800034ca:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800034cc:	00005597          	auipc	a1,0x5
    800034d0:	0b458593          	addi	a1,a1,180 # 80008580 <syscalls+0x160>
    800034d4:	00017517          	auipc	a0,0x17
    800034d8:	6ec50513          	addi	a0,a0,1772 # 8001abc0 <icache>
    800034dc:	ffffd097          	auipc	ra,0xffffd
    800034e0:	66a080e7          	jalr	1642(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800034e4:	00017497          	auipc	s1,0x17
    800034e8:	70448493          	addi	s1,s1,1796 # 8001abe8 <icache+0x28>
    800034ec:	00019997          	auipc	s3,0x19
    800034f0:	18c98993          	addi	s3,s3,396 # 8001c678 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800034f4:	00005917          	auipc	s2,0x5
    800034f8:	09490913          	addi	s2,s2,148 # 80008588 <syscalls+0x168>
    800034fc:	85ca                	mv	a1,s2
    800034fe:	8526                	mv	a0,s1
    80003500:	00001097          	auipc	ra,0x1
    80003504:	ef6080e7          	jalr	-266(ra) # 800043f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003508:	08848493          	addi	s1,s1,136
    8000350c:	ff3498e3          	bne	s1,s3,800034fc <iinit+0x3e>
}
    80003510:	70a2                	ld	ra,40(sp)
    80003512:	7402                	ld	s0,32(sp)
    80003514:	64e2                	ld	s1,24(sp)
    80003516:	6942                	ld	s2,16(sp)
    80003518:	69a2                	ld	s3,8(sp)
    8000351a:	6145                	addi	sp,sp,48
    8000351c:	8082                	ret

000000008000351e <ialloc>:
{
    8000351e:	715d                	addi	sp,sp,-80
    80003520:	e486                	sd	ra,72(sp)
    80003522:	e0a2                	sd	s0,64(sp)
    80003524:	fc26                	sd	s1,56(sp)
    80003526:	f84a                	sd	s2,48(sp)
    80003528:	f44e                	sd	s3,40(sp)
    8000352a:	f052                	sd	s4,32(sp)
    8000352c:	ec56                	sd	s5,24(sp)
    8000352e:	e85a                	sd	s6,16(sp)
    80003530:	e45e                	sd	s7,8(sp)
    80003532:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003534:	00017717          	auipc	a4,0x17
    80003538:	67872703          	lw	a4,1656(a4) # 8001abac <sb+0xc>
    8000353c:	4785                	li	a5,1
    8000353e:	04e7fa63          	bgeu	a5,a4,80003592 <ialloc+0x74>
    80003542:	8aaa                	mv	s5,a0
    80003544:	8bae                	mv	s7,a1
    80003546:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003548:	00017a17          	auipc	s4,0x17
    8000354c:	658a0a13          	addi	s4,s4,1624 # 8001aba0 <sb>
    80003550:	00048b1b          	sext.w	s6,s1
    80003554:	0044d593          	srli	a1,s1,0x4
    80003558:	018a2783          	lw	a5,24(s4)
    8000355c:	9dbd                	addw	a1,a1,a5
    8000355e:	8556                	mv	a0,s5
    80003560:	00000097          	auipc	ra,0x0
    80003564:	88e080e7          	jalr	-1906(ra) # 80002dee <bread>
    80003568:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000356a:	05850993          	addi	s3,a0,88
    8000356e:	00f4f793          	andi	a5,s1,15
    80003572:	079a                	slli	a5,a5,0x6
    80003574:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003576:	00099783          	lh	a5,0(s3)
    8000357a:	c785                	beqz	a5,800035a2 <ialloc+0x84>
    brelse(bp);
    8000357c:	00000097          	auipc	ra,0x0
    80003580:	9a2080e7          	jalr	-1630(ra) # 80002f1e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003584:	0485                	addi	s1,s1,1
    80003586:	00ca2703          	lw	a4,12(s4)
    8000358a:	0004879b          	sext.w	a5,s1
    8000358e:	fce7e1e3          	bltu	a5,a4,80003550 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003592:	00005517          	auipc	a0,0x5
    80003596:	ffe50513          	addi	a0,a0,-2 # 80008590 <syscalls+0x170>
    8000359a:	ffffd097          	auipc	ra,0xffffd
    8000359e:	f96080e7          	jalr	-106(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800035a2:	04000613          	li	a2,64
    800035a6:	4581                	li	a1,0
    800035a8:	854e                	mv	a0,s3
    800035aa:	ffffd097          	auipc	ra,0xffffd
    800035ae:	728080e7          	jalr	1832(ra) # 80000cd2 <memset>
      dip->type = type;
    800035b2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800035b6:	854a                	mv	a0,s2
    800035b8:	00001097          	auipc	ra,0x1
    800035bc:	d50080e7          	jalr	-688(ra) # 80004308 <log_write>
      brelse(bp);
    800035c0:	854a                	mv	a0,s2
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	95c080e7          	jalr	-1700(ra) # 80002f1e <brelse>
      return iget(dev, inum);
    800035ca:	85da                	mv	a1,s6
    800035cc:	8556                	mv	a0,s5
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	db4080e7          	jalr	-588(ra) # 80003382 <iget>
}
    800035d6:	60a6                	ld	ra,72(sp)
    800035d8:	6406                	ld	s0,64(sp)
    800035da:	74e2                	ld	s1,56(sp)
    800035dc:	7942                	ld	s2,48(sp)
    800035de:	79a2                	ld	s3,40(sp)
    800035e0:	7a02                	ld	s4,32(sp)
    800035e2:	6ae2                	ld	s5,24(sp)
    800035e4:	6b42                	ld	s6,16(sp)
    800035e6:	6ba2                	ld	s7,8(sp)
    800035e8:	6161                	addi	sp,sp,80
    800035ea:	8082                	ret

00000000800035ec <iupdate>:
{
    800035ec:	1101                	addi	sp,sp,-32
    800035ee:	ec06                	sd	ra,24(sp)
    800035f0:	e822                	sd	s0,16(sp)
    800035f2:	e426                	sd	s1,8(sp)
    800035f4:	e04a                	sd	s2,0(sp)
    800035f6:	1000                	addi	s0,sp,32
    800035f8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800035fa:	415c                	lw	a5,4(a0)
    800035fc:	0047d79b          	srliw	a5,a5,0x4
    80003600:	00017597          	auipc	a1,0x17
    80003604:	5b85a583          	lw	a1,1464(a1) # 8001abb8 <sb+0x18>
    80003608:	9dbd                	addw	a1,a1,a5
    8000360a:	4108                	lw	a0,0(a0)
    8000360c:	fffff097          	auipc	ra,0xfffff
    80003610:	7e2080e7          	jalr	2018(ra) # 80002dee <bread>
    80003614:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003616:	05850793          	addi	a5,a0,88
    8000361a:	40c8                	lw	a0,4(s1)
    8000361c:	893d                	andi	a0,a0,15
    8000361e:	051a                	slli	a0,a0,0x6
    80003620:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003622:	04449703          	lh	a4,68(s1)
    80003626:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000362a:	04649703          	lh	a4,70(s1)
    8000362e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003632:	04849703          	lh	a4,72(s1)
    80003636:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000363a:	04a49703          	lh	a4,74(s1)
    8000363e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003642:	44f8                	lw	a4,76(s1)
    80003644:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003646:	03400613          	li	a2,52
    8000364a:	05048593          	addi	a1,s1,80
    8000364e:	0531                	addi	a0,a0,12
    80003650:	ffffd097          	auipc	ra,0xffffd
    80003654:	6e2080e7          	jalr	1762(ra) # 80000d32 <memmove>
  log_write(bp);
    80003658:	854a                	mv	a0,s2
    8000365a:	00001097          	auipc	ra,0x1
    8000365e:	cae080e7          	jalr	-850(ra) # 80004308 <log_write>
  brelse(bp);
    80003662:	854a                	mv	a0,s2
    80003664:	00000097          	auipc	ra,0x0
    80003668:	8ba080e7          	jalr	-1862(ra) # 80002f1e <brelse>
}
    8000366c:	60e2                	ld	ra,24(sp)
    8000366e:	6442                	ld	s0,16(sp)
    80003670:	64a2                	ld	s1,8(sp)
    80003672:	6902                	ld	s2,0(sp)
    80003674:	6105                	addi	sp,sp,32
    80003676:	8082                	ret

0000000080003678 <idup>:
{
    80003678:	1101                	addi	sp,sp,-32
    8000367a:	ec06                	sd	ra,24(sp)
    8000367c:	e822                	sd	s0,16(sp)
    8000367e:	e426                	sd	s1,8(sp)
    80003680:	1000                	addi	s0,sp,32
    80003682:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003684:	00017517          	auipc	a0,0x17
    80003688:	53c50513          	addi	a0,a0,1340 # 8001abc0 <icache>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	54a080e7          	jalr	1354(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003694:	449c                	lw	a5,8(s1)
    80003696:	2785                	addiw	a5,a5,1
    80003698:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000369a:	00017517          	auipc	a0,0x17
    8000369e:	52650513          	addi	a0,a0,1318 # 8001abc0 <icache>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	5e8080e7          	jalr	1512(ra) # 80000c8a <release>
}
    800036aa:	8526                	mv	a0,s1
    800036ac:	60e2                	ld	ra,24(sp)
    800036ae:	6442                	ld	s0,16(sp)
    800036b0:	64a2                	ld	s1,8(sp)
    800036b2:	6105                	addi	sp,sp,32
    800036b4:	8082                	ret

00000000800036b6 <ilock>:
{
    800036b6:	1101                	addi	sp,sp,-32
    800036b8:	ec06                	sd	ra,24(sp)
    800036ba:	e822                	sd	s0,16(sp)
    800036bc:	e426                	sd	s1,8(sp)
    800036be:	e04a                	sd	s2,0(sp)
    800036c0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800036c2:	c115                	beqz	a0,800036e6 <ilock+0x30>
    800036c4:	84aa                	mv	s1,a0
    800036c6:	451c                	lw	a5,8(a0)
    800036c8:	00f05f63          	blez	a5,800036e6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800036cc:	0541                	addi	a0,a0,16
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	d62080e7          	jalr	-670(ra) # 80004430 <acquiresleep>
  if(ip->valid == 0){
    800036d6:	40bc                	lw	a5,64(s1)
    800036d8:	cf99                	beqz	a5,800036f6 <ilock+0x40>
}
    800036da:	60e2                	ld	ra,24(sp)
    800036dc:	6442                	ld	s0,16(sp)
    800036de:	64a2                	ld	s1,8(sp)
    800036e0:	6902                	ld	s2,0(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret
    panic("ilock");
    800036e6:	00005517          	auipc	a0,0x5
    800036ea:	ec250513          	addi	a0,a0,-318 # 800085a8 <syscalls+0x188>
    800036ee:	ffffd097          	auipc	ra,0xffffd
    800036f2:	e42080e7          	jalr	-446(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f6:	40dc                	lw	a5,4(s1)
    800036f8:	0047d79b          	srliw	a5,a5,0x4
    800036fc:	00017597          	auipc	a1,0x17
    80003700:	4bc5a583          	lw	a1,1212(a1) # 8001abb8 <sb+0x18>
    80003704:	9dbd                	addw	a1,a1,a5
    80003706:	4088                	lw	a0,0(s1)
    80003708:	fffff097          	auipc	ra,0xfffff
    8000370c:	6e6080e7          	jalr	1766(ra) # 80002dee <bread>
    80003710:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003712:	05850593          	addi	a1,a0,88
    80003716:	40dc                	lw	a5,4(s1)
    80003718:	8bbd                	andi	a5,a5,15
    8000371a:	079a                	slli	a5,a5,0x6
    8000371c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000371e:	00059783          	lh	a5,0(a1)
    80003722:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003726:	00259783          	lh	a5,2(a1)
    8000372a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000372e:	00459783          	lh	a5,4(a1)
    80003732:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003736:	00659783          	lh	a5,6(a1)
    8000373a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000373e:	459c                	lw	a5,8(a1)
    80003740:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003742:	03400613          	li	a2,52
    80003746:	05b1                	addi	a1,a1,12
    80003748:	05048513          	addi	a0,s1,80
    8000374c:	ffffd097          	auipc	ra,0xffffd
    80003750:	5e6080e7          	jalr	1510(ra) # 80000d32 <memmove>
    brelse(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	fffff097          	auipc	ra,0xfffff
    8000375a:	7c8080e7          	jalr	1992(ra) # 80002f1e <brelse>
    ip->valid = 1;
    8000375e:	4785                	li	a5,1
    80003760:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003762:	04449783          	lh	a5,68(s1)
    80003766:	fbb5                	bnez	a5,800036da <ilock+0x24>
      panic("ilock: no type");
    80003768:	00005517          	auipc	a0,0x5
    8000376c:	e4850513          	addi	a0,a0,-440 # 800085b0 <syscalls+0x190>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	dc0080e7          	jalr	-576(ra) # 80000530 <panic>

0000000080003778 <iunlock>:
{
    80003778:	1101                	addi	sp,sp,-32
    8000377a:	ec06                	sd	ra,24(sp)
    8000377c:	e822                	sd	s0,16(sp)
    8000377e:	e426                	sd	s1,8(sp)
    80003780:	e04a                	sd	s2,0(sp)
    80003782:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003784:	c905                	beqz	a0,800037b4 <iunlock+0x3c>
    80003786:	84aa                	mv	s1,a0
    80003788:	01050913          	addi	s2,a0,16
    8000378c:	854a                	mv	a0,s2
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	d3c080e7          	jalr	-708(ra) # 800044ca <holdingsleep>
    80003796:	cd19                	beqz	a0,800037b4 <iunlock+0x3c>
    80003798:	449c                	lw	a5,8(s1)
    8000379a:	00f05d63          	blez	a5,800037b4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000379e:	854a                	mv	a0,s2
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	ce6080e7          	jalr	-794(ra) # 80004486 <releasesleep>
}
    800037a8:	60e2                	ld	ra,24(sp)
    800037aa:	6442                	ld	s0,16(sp)
    800037ac:	64a2                	ld	s1,8(sp)
    800037ae:	6902                	ld	s2,0(sp)
    800037b0:	6105                	addi	sp,sp,32
    800037b2:	8082                	ret
    panic("iunlock");
    800037b4:	00005517          	auipc	a0,0x5
    800037b8:	e0c50513          	addi	a0,a0,-500 # 800085c0 <syscalls+0x1a0>
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	d74080e7          	jalr	-652(ra) # 80000530 <panic>

00000000800037c4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800037c4:	715d                	addi	sp,sp,-80
    800037c6:	e486                	sd	ra,72(sp)
    800037c8:	e0a2                	sd	s0,64(sp)
    800037ca:	fc26                	sd	s1,56(sp)
    800037cc:	f84a                	sd	s2,48(sp)
    800037ce:	f44e                	sd	s3,40(sp)
    800037d0:	f052                	sd	s4,32(sp)
    800037d2:	ec56                	sd	s5,24(sp)
    800037d4:	e85a                	sd	s6,16(sp)
    800037d6:	e45e                	sd	s7,8(sp)
    800037d8:	e062                	sd	s8,0(sp)
    800037da:	0880                	addi	s0,sp,80
    800037dc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800037de:	05050493          	addi	s1,a0,80
    800037e2:	07c50913          	addi	s2,a0,124
    800037e6:	a021                	j	800037ee <itrunc+0x2a>
    800037e8:	0491                	addi	s1,s1,4
    800037ea:	01248d63          	beq	s1,s2,80003804 <itrunc+0x40>
    if(ip->addrs[i]){
    800037ee:	408c                	lw	a1,0(s1)
    800037f0:	dde5                	beqz	a1,800037e8 <itrunc+0x24>
      bfree(ip->dev, ip->addrs[i]);
    800037f2:	0009a503          	lw	a0,0(s3)
    800037f6:	00000097          	auipc	ra,0x0
    800037fa:	83e080e7          	jalr	-1986(ra) # 80003034 <bfree>
      ip->addrs[i] = 0;
    800037fe:	0004a023          	sw	zero,0(s1)
    80003802:	b7dd                	j	800037e8 <itrunc+0x24>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003804:	07c9a583          	lw	a1,124(s3)
    80003808:	e59d                	bnez	a1,80003836 <itrunc+0x72>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  if(ip->addrs[NDIRECT+1]){
    8000380a:	0809a583          	lw	a1,128(s3)
    8000380e:	eda5                	bnez	a1,80003886 <itrunc+0xc2>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT+1]);
    ip->addrs[NDIRECT + 1] = 0;
  }

  ip->size = 0;
    80003810:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003814:	854e                	mv	a0,s3
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	dd6080e7          	jalr	-554(ra) # 800035ec <iupdate>
}
    8000381e:	60a6                	ld	ra,72(sp)
    80003820:	6406                	ld	s0,64(sp)
    80003822:	74e2                	ld	s1,56(sp)
    80003824:	7942                	ld	s2,48(sp)
    80003826:	79a2                	ld	s3,40(sp)
    80003828:	7a02                	ld	s4,32(sp)
    8000382a:	6ae2                	ld	s5,24(sp)
    8000382c:	6b42                	ld	s6,16(sp)
    8000382e:	6ba2                	ld	s7,8(sp)
    80003830:	6c02                	ld	s8,0(sp)
    80003832:	6161                	addi	sp,sp,80
    80003834:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003836:	0009a503          	lw	a0,0(s3)
    8000383a:	fffff097          	auipc	ra,0xfffff
    8000383e:	5b4080e7          	jalr	1460(ra) # 80002dee <bread>
    80003842:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003844:	05850493          	addi	s1,a0,88
    80003848:	45850913          	addi	s2,a0,1112
    8000384c:	a021                	j	80003854 <itrunc+0x90>
    8000384e:	0491                	addi	s1,s1,4
    80003850:	01248b63          	beq	s1,s2,80003866 <itrunc+0xa2>
      if(a[j])
    80003854:	408c                	lw	a1,0(s1)
    80003856:	dde5                	beqz	a1,8000384e <itrunc+0x8a>
        bfree(ip->dev, a[j]);
    80003858:	0009a503          	lw	a0,0(s3)
    8000385c:	fffff097          	auipc	ra,0xfffff
    80003860:	7d8080e7          	jalr	2008(ra) # 80003034 <bfree>
    80003864:	b7ed                	j	8000384e <itrunc+0x8a>
    brelse(bp);
    80003866:	8552                	mv	a0,s4
    80003868:	fffff097          	auipc	ra,0xfffff
    8000386c:	6b6080e7          	jalr	1718(ra) # 80002f1e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003870:	07c9a583          	lw	a1,124(s3)
    80003874:	0009a503          	lw	a0,0(s3)
    80003878:	fffff097          	auipc	ra,0xfffff
    8000387c:	7bc080e7          	jalr	1980(ra) # 80003034 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003880:	0609ae23          	sw	zero,124(s3)
    80003884:	b759                	j	8000380a <itrunc+0x46>
    bp = bread(ip->dev, ip->addrs[NDIRECT+1]);
    80003886:	0009a503          	lw	a0,0(s3)
    8000388a:	fffff097          	auipc	ra,0xfffff
    8000388e:	564080e7          	jalr	1380(ra) # 80002dee <bread>
    80003892:	8c2a                	mv	s8,a0
    for(j = 0; j < NINDIRECT; j++){
    80003894:	05850a13          	addi	s4,a0,88
    80003898:	45850b13          	addi	s6,a0,1112
    8000389c:	a82d                	j	800038d6 <itrunc+0x112>
            bfree(ip->dev, a2[k]);
    8000389e:	0009a503          	lw	a0,0(s3)
    800038a2:	fffff097          	auipc	ra,0xfffff
    800038a6:	792080e7          	jalr	1938(ra) # 80003034 <bfree>
        for(int k = 0; k < NINDIRECT; k++){
    800038aa:	0491                	addi	s1,s1,4
    800038ac:	00990563          	beq	s2,s1,800038b6 <itrunc+0xf2>
          if(a2[k])
    800038b0:	408c                	lw	a1,0(s1)
    800038b2:	dde5                	beqz	a1,800038aa <itrunc+0xe6>
    800038b4:	b7ed                	j	8000389e <itrunc+0xda>
        brelse(bp2);
    800038b6:	855e                	mv	a0,s7
    800038b8:	fffff097          	auipc	ra,0xfffff
    800038bc:	666080e7          	jalr	1638(ra) # 80002f1e <brelse>
        bfree(ip->dev, a[j]);
    800038c0:	000aa583          	lw	a1,0(s5)
    800038c4:	0009a503          	lw	a0,0(s3)
    800038c8:	fffff097          	auipc	ra,0xfffff
    800038cc:	76c080e7          	jalr	1900(ra) # 80003034 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038d0:	0a11                	addi	s4,s4,4
    800038d2:	034b0263          	beq	s6,s4,800038f6 <itrunc+0x132>
      if(a[j]) {
    800038d6:	8ad2                	mv	s5,s4
    800038d8:	000a2583          	lw	a1,0(s4)
    800038dc:	d9f5                	beqz	a1,800038d0 <itrunc+0x10c>
        struct buf *bp2 = bread(ip->dev, a[j]);
    800038de:	0009a503          	lw	a0,0(s3)
    800038e2:	fffff097          	auipc	ra,0xfffff
    800038e6:	50c080e7          	jalr	1292(ra) # 80002dee <bread>
    800038ea:	8baa                	mv	s7,a0
        for(int k = 0; k < NINDIRECT; k++){
    800038ec:	05850493          	addi	s1,a0,88
    800038f0:	45850913          	addi	s2,a0,1112
    800038f4:	bf75                	j	800038b0 <itrunc+0xec>
    brelse(bp);
    800038f6:	8562                	mv	a0,s8
    800038f8:	fffff097          	auipc	ra,0xfffff
    800038fc:	626080e7          	jalr	1574(ra) # 80002f1e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT+1]);
    80003900:	0809a583          	lw	a1,128(s3)
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	fffff097          	auipc	ra,0xfffff
    8000390c:	72c080e7          	jalr	1836(ra) # 80003034 <bfree>
    ip->addrs[NDIRECT + 1] = 0;
    80003910:	0809a023          	sw	zero,128(s3)
    80003914:	bdf5                	j	80003810 <itrunc+0x4c>

0000000080003916 <iput>:
{
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	e04a                	sd	s2,0(sp)
    80003920:	1000                	addi	s0,sp,32
    80003922:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003924:	00017517          	auipc	a0,0x17
    80003928:	29c50513          	addi	a0,a0,668 # 8001abc0 <icache>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	2aa080e7          	jalr	682(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003934:	4498                	lw	a4,8(s1)
    80003936:	4785                	li	a5,1
    80003938:	02f70363          	beq	a4,a5,8000395e <iput+0x48>
  ip->ref--;
    8000393c:	449c                	lw	a5,8(s1)
    8000393e:	37fd                	addiw	a5,a5,-1
    80003940:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003942:	00017517          	auipc	a0,0x17
    80003946:	27e50513          	addi	a0,a0,638 # 8001abc0 <icache>
    8000394a:	ffffd097          	auipc	ra,0xffffd
    8000394e:	340080e7          	jalr	832(ra) # 80000c8a <release>
}
    80003952:	60e2                	ld	ra,24(sp)
    80003954:	6442                	ld	s0,16(sp)
    80003956:	64a2                	ld	s1,8(sp)
    80003958:	6902                	ld	s2,0(sp)
    8000395a:	6105                	addi	sp,sp,32
    8000395c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000395e:	40bc                	lw	a5,64(s1)
    80003960:	dff1                	beqz	a5,8000393c <iput+0x26>
    80003962:	04a49783          	lh	a5,74(s1)
    80003966:	fbf9                	bnez	a5,8000393c <iput+0x26>
    acquiresleep(&ip->lock);
    80003968:	01048913          	addi	s2,s1,16
    8000396c:	854a                	mv	a0,s2
    8000396e:	00001097          	auipc	ra,0x1
    80003972:	ac2080e7          	jalr	-1342(ra) # 80004430 <acquiresleep>
    release(&icache.lock);
    80003976:	00017517          	auipc	a0,0x17
    8000397a:	24a50513          	addi	a0,a0,586 # 8001abc0 <icache>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	30c080e7          	jalr	780(ra) # 80000c8a <release>
    itrunc(ip);
    80003986:	8526                	mv	a0,s1
    80003988:	00000097          	auipc	ra,0x0
    8000398c:	e3c080e7          	jalr	-452(ra) # 800037c4 <itrunc>
    ip->type = 0;
    80003990:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003994:	8526                	mv	a0,s1
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	c56080e7          	jalr	-938(ra) # 800035ec <iupdate>
    ip->valid = 0;
    8000399e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039a2:	854a                	mv	a0,s2
    800039a4:	00001097          	auipc	ra,0x1
    800039a8:	ae2080e7          	jalr	-1310(ra) # 80004486 <releasesleep>
    acquire(&icache.lock);
    800039ac:	00017517          	auipc	a0,0x17
    800039b0:	21450513          	addi	a0,a0,532 # 8001abc0 <icache>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	222080e7          	jalr	546(ra) # 80000bd6 <acquire>
    800039bc:	b741                	j	8000393c <iput+0x26>

00000000800039be <iunlockput>:
{
    800039be:	1101                	addi	sp,sp,-32
    800039c0:	ec06                	sd	ra,24(sp)
    800039c2:	e822                	sd	s0,16(sp)
    800039c4:	e426                	sd	s1,8(sp)
    800039c6:	1000                	addi	s0,sp,32
    800039c8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ca:	00000097          	auipc	ra,0x0
    800039ce:	dae080e7          	jalr	-594(ra) # 80003778 <iunlock>
  iput(ip);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	f42080e7          	jalr	-190(ra) # 80003916 <iput>
}
    800039dc:	60e2                	ld	ra,24(sp)
    800039de:	6442                	ld	s0,16(sp)
    800039e0:	64a2                	ld	s1,8(sp)
    800039e2:	6105                	addi	sp,sp,32
    800039e4:	8082                	ret

00000000800039e6 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039e6:	1141                	addi	sp,sp,-16
    800039e8:	e422                	sd	s0,8(sp)
    800039ea:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039ec:	411c                	lw	a5,0(a0)
    800039ee:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039f0:	415c                	lw	a5,4(a0)
    800039f2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039f4:	04451783          	lh	a5,68(a0)
    800039f8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039fc:	04a51783          	lh	a5,74(a0)
    80003a00:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a04:	04c56783          	lwu	a5,76(a0)
    80003a08:	e99c                	sd	a5,16(a1)
}
    80003a0a:	6422                	ld	s0,8(sp)
    80003a0c:	0141                	addi	sp,sp,16
    80003a0e:	8082                	ret

0000000080003a10 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a10:	457c                	lw	a5,76(a0)
    80003a12:	0ed7e963          	bltu	a5,a3,80003b04 <readi+0xf4>
{
    80003a16:	7159                	addi	sp,sp,-112
    80003a18:	f486                	sd	ra,104(sp)
    80003a1a:	f0a2                	sd	s0,96(sp)
    80003a1c:	eca6                	sd	s1,88(sp)
    80003a1e:	e8ca                	sd	s2,80(sp)
    80003a20:	e4ce                	sd	s3,72(sp)
    80003a22:	e0d2                	sd	s4,64(sp)
    80003a24:	fc56                	sd	s5,56(sp)
    80003a26:	f85a                	sd	s6,48(sp)
    80003a28:	f45e                	sd	s7,40(sp)
    80003a2a:	f062                	sd	s8,32(sp)
    80003a2c:	ec66                	sd	s9,24(sp)
    80003a2e:	e86a                	sd	s10,16(sp)
    80003a30:	e46e                	sd	s11,8(sp)
    80003a32:	1880                	addi	s0,sp,112
    80003a34:	8baa                	mv	s7,a0
    80003a36:	8c2e                	mv	s8,a1
    80003a38:	8ab2                	mv	s5,a2
    80003a3a:	84b6                	mv	s1,a3
    80003a3c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a3e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a40:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a42:	0ad76063          	bltu	a4,a3,80003ae2 <readi+0xd2>
  if(off + n > ip->size)
    80003a46:	00e7f463          	bgeu	a5,a4,80003a4e <readi+0x3e>
    n = ip->size - off;
    80003a4a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a4e:	0a0b0963          	beqz	s6,80003b00 <readi+0xf0>
    80003a52:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a54:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a58:	5cfd                	li	s9,-1
    80003a5a:	a82d                	j	80003a94 <readi+0x84>
    80003a5c:	020a1d93          	slli	s11,s4,0x20
    80003a60:	020ddd93          	srli	s11,s11,0x20
    80003a64:	05890613          	addi	a2,s2,88
    80003a68:	86ee                	mv	a3,s11
    80003a6a:	963a                	add	a2,a2,a4
    80003a6c:	85d6                	mv	a1,s5
    80003a6e:	8562                	mv	a0,s8
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	9c2080e7          	jalr	-1598(ra) # 80002432 <either_copyout>
    80003a78:	05950d63          	beq	a0,s9,80003ad2 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	4a0080e7          	jalr	1184(ra) # 80002f1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a86:	013a09bb          	addw	s3,s4,s3
    80003a8a:	009a04bb          	addw	s1,s4,s1
    80003a8e:	9aee                	add	s5,s5,s11
    80003a90:	0569f763          	bgeu	s3,s6,80003ade <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a94:	000ba903          	lw	s2,0(s7)
    80003a98:	00a4d59b          	srliw	a1,s1,0xa
    80003a9c:	855e                	mv	a0,s7
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	744080e7          	jalr	1860(ra) # 800031e2 <bmap>
    80003aa6:	0005059b          	sext.w	a1,a0
    80003aaa:	854a                	mv	a0,s2
    80003aac:	fffff097          	auipc	ra,0xfffff
    80003ab0:	342080e7          	jalr	834(ra) # 80002dee <bread>
    80003ab4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab6:	3ff4f713          	andi	a4,s1,1023
    80003aba:	40ed07bb          	subw	a5,s10,a4
    80003abe:	413b06bb          	subw	a3,s6,s3
    80003ac2:	8a3e                	mv	s4,a5
    80003ac4:	2781                	sext.w	a5,a5
    80003ac6:	0006861b          	sext.w	a2,a3
    80003aca:	f8f679e3          	bgeu	a2,a5,80003a5c <readi+0x4c>
    80003ace:	8a36                	mv	s4,a3
    80003ad0:	b771                	j	80003a5c <readi+0x4c>
      brelse(bp);
    80003ad2:	854a                	mv	a0,s2
    80003ad4:	fffff097          	auipc	ra,0xfffff
    80003ad8:	44a080e7          	jalr	1098(ra) # 80002f1e <brelse>
      tot = -1;
    80003adc:	59fd                	li	s3,-1
  }
  return tot;
    80003ade:	0009851b          	sext.w	a0,s3
}
    80003ae2:	70a6                	ld	ra,104(sp)
    80003ae4:	7406                	ld	s0,96(sp)
    80003ae6:	64e6                	ld	s1,88(sp)
    80003ae8:	6946                	ld	s2,80(sp)
    80003aea:	69a6                	ld	s3,72(sp)
    80003aec:	6a06                	ld	s4,64(sp)
    80003aee:	7ae2                	ld	s5,56(sp)
    80003af0:	7b42                	ld	s6,48(sp)
    80003af2:	7ba2                	ld	s7,40(sp)
    80003af4:	7c02                	ld	s8,32(sp)
    80003af6:	6ce2                	ld	s9,24(sp)
    80003af8:	6d42                	ld	s10,16(sp)
    80003afa:	6da2                	ld	s11,8(sp)
    80003afc:	6165                	addi	sp,sp,112
    80003afe:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b00:	89da                	mv	s3,s6
    80003b02:	bff1                	j	80003ade <readi+0xce>
    return 0;
    80003b04:	4501                	li	a0,0
}
    80003b06:	8082                	ret

0000000080003b08 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b08:	457c                	lw	a5,76(a0)
    80003b0a:	10d7e963          	bltu	a5,a3,80003c1c <writei+0x114>
{
    80003b0e:	7159                	addi	sp,sp,-112
    80003b10:	f486                	sd	ra,104(sp)
    80003b12:	f0a2                	sd	s0,96(sp)
    80003b14:	eca6                	sd	s1,88(sp)
    80003b16:	e8ca                	sd	s2,80(sp)
    80003b18:	e4ce                	sd	s3,72(sp)
    80003b1a:	e0d2                	sd	s4,64(sp)
    80003b1c:	fc56                	sd	s5,56(sp)
    80003b1e:	f85a                	sd	s6,48(sp)
    80003b20:	f45e                	sd	s7,40(sp)
    80003b22:	f062                	sd	s8,32(sp)
    80003b24:	ec66                	sd	s9,24(sp)
    80003b26:	e86a                	sd	s10,16(sp)
    80003b28:	e46e                	sd	s11,8(sp)
    80003b2a:	1880                	addi	s0,sp,112
    80003b2c:	8b2a                	mv	s6,a0
    80003b2e:	8c2e                	mv	s8,a1
    80003b30:	8ab2                	mv	s5,a2
    80003b32:	8936                	mv	s2,a3
    80003b34:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b36:	9f35                	addw	a4,a4,a3
    80003b38:	0ed76463          	bltu	a4,a3,80003c20 <writei+0x118>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b3c:	040437b7          	lui	a5,0x4043
    80003b40:	c0078793          	addi	a5,a5,-1024 # 4042c00 <_entry-0x7bfbd400>
    80003b44:	0ee7e063          	bltu	a5,a4,80003c24 <writei+0x11c>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b48:	0c0b8863          	beqz	s7,80003c18 <writei+0x110>
    80003b4c:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b4e:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b52:	5cfd                	li	s9,-1
    80003b54:	a091                	j	80003b98 <writei+0x90>
    80003b56:	02099d93          	slli	s11,s3,0x20
    80003b5a:	020ddd93          	srli	s11,s11,0x20
    80003b5e:	05848513          	addi	a0,s1,88
    80003b62:	86ee                	mv	a3,s11
    80003b64:	8656                	mv	a2,s5
    80003b66:	85e2                	mv	a1,s8
    80003b68:	953a                	add	a0,a0,a4
    80003b6a:	fffff097          	auipc	ra,0xfffff
    80003b6e:	91e080e7          	jalr	-1762(ra) # 80002488 <either_copyin>
    80003b72:	07950263          	beq	a0,s9,80003bd6 <writei+0xce>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b76:	8526                	mv	a0,s1
    80003b78:	00000097          	auipc	ra,0x0
    80003b7c:	790080e7          	jalr	1936(ra) # 80004308 <log_write>
    brelse(bp);
    80003b80:	8526                	mv	a0,s1
    80003b82:	fffff097          	auipc	ra,0xfffff
    80003b86:	39c080e7          	jalr	924(ra) # 80002f1e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b8a:	01498a3b          	addw	s4,s3,s4
    80003b8e:	0129893b          	addw	s2,s3,s2
    80003b92:	9aee                	add	s5,s5,s11
    80003b94:	057a7663          	bgeu	s4,s7,80003be0 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b98:	000b2483          	lw	s1,0(s6)
    80003b9c:	00a9559b          	srliw	a1,s2,0xa
    80003ba0:	855a                	mv	a0,s6
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	640080e7          	jalr	1600(ra) # 800031e2 <bmap>
    80003baa:	0005059b          	sext.w	a1,a0
    80003bae:	8526                	mv	a0,s1
    80003bb0:	fffff097          	auipc	ra,0xfffff
    80003bb4:	23e080e7          	jalr	574(ra) # 80002dee <bread>
    80003bb8:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bba:	3ff97713          	andi	a4,s2,1023
    80003bbe:	40ed07bb          	subw	a5,s10,a4
    80003bc2:	414b86bb          	subw	a3,s7,s4
    80003bc6:	89be                	mv	s3,a5
    80003bc8:	2781                	sext.w	a5,a5
    80003bca:	0006861b          	sext.w	a2,a3
    80003bce:	f8f674e3          	bgeu	a2,a5,80003b56 <writei+0x4e>
    80003bd2:	89b6                	mv	s3,a3
    80003bd4:	b749                	j	80003b56 <writei+0x4e>
      brelse(bp);
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	346080e7          	jalr	838(ra) # 80002f1e <brelse>
  }

  if(off > ip->size)
    80003be0:	04cb2783          	lw	a5,76(s6)
    80003be4:	0127f463          	bgeu	a5,s2,80003bec <writei+0xe4>
    ip->size = off;
    80003be8:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bec:	855a                	mv	a0,s6
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	9fe080e7          	jalr	-1538(ra) # 800035ec <iupdate>

  return tot;
    80003bf6:	000a051b          	sext.w	a0,s4
}
    80003bfa:	70a6                	ld	ra,104(sp)
    80003bfc:	7406                	ld	s0,96(sp)
    80003bfe:	64e6                	ld	s1,88(sp)
    80003c00:	6946                	ld	s2,80(sp)
    80003c02:	69a6                	ld	s3,72(sp)
    80003c04:	6a06                	ld	s4,64(sp)
    80003c06:	7ae2                	ld	s5,56(sp)
    80003c08:	7b42                	ld	s6,48(sp)
    80003c0a:	7ba2                	ld	s7,40(sp)
    80003c0c:	7c02                	ld	s8,32(sp)
    80003c0e:	6ce2                	ld	s9,24(sp)
    80003c10:	6d42                	ld	s10,16(sp)
    80003c12:	6da2                	ld	s11,8(sp)
    80003c14:	6165                	addi	sp,sp,112
    80003c16:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c18:	8a5e                	mv	s4,s7
    80003c1a:	bfc9                	j	80003bec <writei+0xe4>
    return -1;
    80003c1c:	557d                	li	a0,-1
}
    80003c1e:	8082                	ret
    return -1;
    80003c20:	557d                	li	a0,-1
    80003c22:	bfe1                	j	80003bfa <writei+0xf2>
    return -1;
    80003c24:	557d                	li	a0,-1
    80003c26:	bfd1                	j	80003bfa <writei+0xf2>

0000000080003c28 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c28:	1141                	addi	sp,sp,-16
    80003c2a:	e406                	sd	ra,8(sp)
    80003c2c:	e022                	sd	s0,0(sp)
    80003c2e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c30:	4639                	li	a2,14
    80003c32:	ffffd097          	auipc	ra,0xffffd
    80003c36:	17c080e7          	jalr	380(ra) # 80000dae <strncmp>
}
    80003c3a:	60a2                	ld	ra,8(sp)
    80003c3c:	6402                	ld	s0,0(sp)
    80003c3e:	0141                	addi	sp,sp,16
    80003c40:	8082                	ret

0000000080003c42 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c42:	7139                	addi	sp,sp,-64
    80003c44:	fc06                	sd	ra,56(sp)
    80003c46:	f822                	sd	s0,48(sp)
    80003c48:	f426                	sd	s1,40(sp)
    80003c4a:	f04a                	sd	s2,32(sp)
    80003c4c:	ec4e                	sd	s3,24(sp)
    80003c4e:	e852                	sd	s4,16(sp)
    80003c50:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c52:	04451703          	lh	a4,68(a0)
    80003c56:	4785                	li	a5,1
    80003c58:	00f71a63          	bne	a4,a5,80003c6c <dirlookup+0x2a>
    80003c5c:	892a                	mv	s2,a0
    80003c5e:	89ae                	mv	s3,a1
    80003c60:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c62:	457c                	lw	a5,76(a0)
    80003c64:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c66:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c68:	e79d                	bnez	a5,80003c96 <dirlookup+0x54>
    80003c6a:	a8a5                	j	80003ce2 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c6c:	00005517          	auipc	a0,0x5
    80003c70:	95c50513          	addi	a0,a0,-1700 # 800085c8 <syscalls+0x1a8>
    80003c74:	ffffd097          	auipc	ra,0xffffd
    80003c78:	8bc080e7          	jalr	-1860(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003c7c:	00005517          	auipc	a0,0x5
    80003c80:	96450513          	addi	a0,a0,-1692 # 800085e0 <syscalls+0x1c0>
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	8ac080e7          	jalr	-1876(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c8c:	24c1                	addiw	s1,s1,16
    80003c8e:	04c92783          	lw	a5,76(s2)
    80003c92:	04f4f763          	bgeu	s1,a5,80003ce0 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c96:	4741                	li	a4,16
    80003c98:	86a6                	mv	a3,s1
    80003c9a:	fc040613          	addi	a2,s0,-64
    80003c9e:	4581                	li	a1,0
    80003ca0:	854a                	mv	a0,s2
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	d6e080e7          	jalr	-658(ra) # 80003a10 <readi>
    80003caa:	47c1                	li	a5,16
    80003cac:	fcf518e3          	bne	a0,a5,80003c7c <dirlookup+0x3a>
    if(de.inum == 0)
    80003cb0:	fc045783          	lhu	a5,-64(s0)
    80003cb4:	dfe1                	beqz	a5,80003c8c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cb6:	fc240593          	addi	a1,s0,-62
    80003cba:	854e                	mv	a0,s3
    80003cbc:	00000097          	auipc	ra,0x0
    80003cc0:	f6c080e7          	jalr	-148(ra) # 80003c28 <namecmp>
    80003cc4:	f561                	bnez	a0,80003c8c <dirlookup+0x4a>
      if(poff)
    80003cc6:	000a0463          	beqz	s4,80003cce <dirlookup+0x8c>
        *poff = off;
    80003cca:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cce:	fc045583          	lhu	a1,-64(s0)
    80003cd2:	00092503          	lw	a0,0(s2)
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	6ac080e7          	jalr	1708(ra) # 80003382 <iget>
    80003cde:	a011                	j	80003ce2 <dirlookup+0xa0>
  return 0;
    80003ce0:	4501                	li	a0,0
}
    80003ce2:	70e2                	ld	ra,56(sp)
    80003ce4:	7442                	ld	s0,48(sp)
    80003ce6:	74a2                	ld	s1,40(sp)
    80003ce8:	7902                	ld	s2,32(sp)
    80003cea:	69e2                	ld	s3,24(sp)
    80003cec:	6a42                	ld	s4,16(sp)
    80003cee:	6121                	addi	sp,sp,64
    80003cf0:	8082                	ret

0000000080003cf2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cf2:	711d                	addi	sp,sp,-96
    80003cf4:	ec86                	sd	ra,88(sp)
    80003cf6:	e8a2                	sd	s0,80(sp)
    80003cf8:	e4a6                	sd	s1,72(sp)
    80003cfa:	e0ca                	sd	s2,64(sp)
    80003cfc:	fc4e                	sd	s3,56(sp)
    80003cfe:	f852                	sd	s4,48(sp)
    80003d00:	f456                	sd	s5,40(sp)
    80003d02:	f05a                	sd	s6,32(sp)
    80003d04:	ec5e                	sd	s7,24(sp)
    80003d06:	e862                	sd	s8,16(sp)
    80003d08:	e466                	sd	s9,8(sp)
    80003d0a:	1080                	addi	s0,sp,96
    80003d0c:	84aa                	mv	s1,a0
    80003d0e:	8b2e                	mv	s6,a1
    80003d10:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d12:	00054703          	lbu	a4,0(a0)
    80003d16:	02f00793          	li	a5,47
    80003d1a:	02f70363          	beq	a4,a5,80003d40 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d1e:	ffffe097          	auipc	ra,0xffffe
    80003d22:	ca2080e7          	jalr	-862(ra) # 800019c0 <myproc>
    80003d26:	15053503          	ld	a0,336(a0)
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	94e080e7          	jalr	-1714(ra) # 80003678 <idup>
    80003d32:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d34:	02f00913          	li	s2,47
  len = path - s;
    80003d38:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d3a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d3c:	4c05                	li	s8,1
    80003d3e:	a865                	j	80003df6 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d40:	4585                	li	a1,1
    80003d42:	4505                	li	a0,1
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	63e080e7          	jalr	1598(ra) # 80003382 <iget>
    80003d4c:	89aa                	mv	s3,a0
    80003d4e:	b7dd                	j	80003d34 <namex+0x42>
      iunlockput(ip);
    80003d50:	854e                	mv	a0,s3
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	c6c080e7          	jalr	-916(ra) # 800039be <iunlockput>
      return 0;
    80003d5a:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d5c:	854e                	mv	a0,s3
    80003d5e:	60e6                	ld	ra,88(sp)
    80003d60:	6446                	ld	s0,80(sp)
    80003d62:	64a6                	ld	s1,72(sp)
    80003d64:	6906                	ld	s2,64(sp)
    80003d66:	79e2                	ld	s3,56(sp)
    80003d68:	7a42                	ld	s4,48(sp)
    80003d6a:	7aa2                	ld	s5,40(sp)
    80003d6c:	7b02                	ld	s6,32(sp)
    80003d6e:	6be2                	ld	s7,24(sp)
    80003d70:	6c42                	ld	s8,16(sp)
    80003d72:	6ca2                	ld	s9,8(sp)
    80003d74:	6125                	addi	sp,sp,96
    80003d76:	8082                	ret
      iunlock(ip);
    80003d78:	854e                	mv	a0,s3
    80003d7a:	00000097          	auipc	ra,0x0
    80003d7e:	9fe080e7          	jalr	-1538(ra) # 80003778 <iunlock>
      return ip;
    80003d82:	bfe9                	j	80003d5c <namex+0x6a>
      iunlockput(ip);
    80003d84:	854e                	mv	a0,s3
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	c38080e7          	jalr	-968(ra) # 800039be <iunlockput>
      return 0;
    80003d8e:	89d2                	mv	s3,s4
    80003d90:	b7f1                	j	80003d5c <namex+0x6a>
  len = path - s;
    80003d92:	40b48633          	sub	a2,s1,a1
    80003d96:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d9a:	094cd463          	bge	s9,s4,80003e22 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d9e:	4639                	li	a2,14
    80003da0:	8556                	mv	a0,s5
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	f90080e7          	jalr	-112(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003daa:	0004c783          	lbu	a5,0(s1)
    80003dae:	01279763          	bne	a5,s2,80003dbc <namex+0xca>
    path++;
    80003db2:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003db4:	0004c783          	lbu	a5,0(s1)
    80003db8:	ff278de3          	beq	a5,s2,80003db2 <namex+0xc0>
    ilock(ip);
    80003dbc:	854e                	mv	a0,s3
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	8f8080e7          	jalr	-1800(ra) # 800036b6 <ilock>
    if(ip->type != T_DIR){
    80003dc6:	04499783          	lh	a5,68(s3)
    80003dca:	f98793e3          	bne	a5,s8,80003d50 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dce:	000b0563          	beqz	s6,80003dd8 <namex+0xe6>
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	d3cd                	beqz	a5,80003d78 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003dd8:	865e                	mv	a2,s7
    80003dda:	85d6                	mv	a1,s5
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	e64080e7          	jalr	-412(ra) # 80003c42 <dirlookup>
    80003de6:	8a2a                	mv	s4,a0
    80003de8:	dd51                	beqz	a0,80003d84 <namex+0x92>
    iunlockput(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	bd2080e7          	jalr	-1070(ra) # 800039be <iunlockput>
    ip = next;
    80003df4:	89d2                	mv	s3,s4
  while(*path == '/')
    80003df6:	0004c783          	lbu	a5,0(s1)
    80003dfa:	05279763          	bne	a5,s2,80003e48 <namex+0x156>
    path++;
    80003dfe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e00:	0004c783          	lbu	a5,0(s1)
    80003e04:	ff278de3          	beq	a5,s2,80003dfe <namex+0x10c>
  if(*path == 0)
    80003e08:	c79d                	beqz	a5,80003e36 <namex+0x144>
    path++;
    80003e0a:	85a6                	mv	a1,s1
  len = path - s;
    80003e0c:	8a5e                	mv	s4,s7
    80003e0e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e10:	01278963          	beq	a5,s2,80003e22 <namex+0x130>
    80003e14:	dfbd                	beqz	a5,80003d92 <namex+0xa0>
    path++;
    80003e16:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e18:	0004c783          	lbu	a5,0(s1)
    80003e1c:	ff279ce3          	bne	a5,s2,80003e14 <namex+0x122>
    80003e20:	bf8d                	j	80003d92 <namex+0xa0>
    memmove(name, s, len);
    80003e22:	2601                	sext.w	a2,a2
    80003e24:	8556                	mv	a0,s5
    80003e26:	ffffd097          	auipc	ra,0xffffd
    80003e2a:	f0c080e7          	jalr	-244(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003e2e:	9a56                	add	s4,s4,s5
    80003e30:	000a0023          	sb	zero,0(s4)
    80003e34:	bf9d                	j	80003daa <namex+0xb8>
  if(nameiparent){
    80003e36:	f20b03e3          	beqz	s6,80003d5c <namex+0x6a>
    iput(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	ada080e7          	jalr	-1318(ra) # 80003916 <iput>
    return 0;
    80003e44:	4981                	li	s3,0
    80003e46:	bf19                	j	80003d5c <namex+0x6a>
  if(*path == 0)
    80003e48:	d7fd                	beqz	a5,80003e36 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e4a:	0004c783          	lbu	a5,0(s1)
    80003e4e:	85a6                	mv	a1,s1
    80003e50:	b7d1                	j	80003e14 <namex+0x122>

0000000080003e52 <dirlink>:
{
    80003e52:	7139                	addi	sp,sp,-64
    80003e54:	fc06                	sd	ra,56(sp)
    80003e56:	f822                	sd	s0,48(sp)
    80003e58:	f426                	sd	s1,40(sp)
    80003e5a:	f04a                	sd	s2,32(sp)
    80003e5c:	ec4e                	sd	s3,24(sp)
    80003e5e:	e852                	sd	s4,16(sp)
    80003e60:	0080                	addi	s0,sp,64
    80003e62:	892a                	mv	s2,a0
    80003e64:	8a2e                	mv	s4,a1
    80003e66:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e68:	4601                	li	a2,0
    80003e6a:	00000097          	auipc	ra,0x0
    80003e6e:	dd8080e7          	jalr	-552(ra) # 80003c42 <dirlookup>
    80003e72:	e93d                	bnez	a0,80003ee8 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e74:	04c92483          	lw	s1,76(s2)
    80003e78:	c49d                	beqz	s1,80003ea6 <dirlink+0x54>
    80003e7a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e7c:	4741                	li	a4,16
    80003e7e:	86a6                	mv	a3,s1
    80003e80:	fc040613          	addi	a2,s0,-64
    80003e84:	4581                	li	a1,0
    80003e86:	854a                	mv	a0,s2
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	b88080e7          	jalr	-1144(ra) # 80003a10 <readi>
    80003e90:	47c1                	li	a5,16
    80003e92:	06f51163          	bne	a0,a5,80003ef4 <dirlink+0xa2>
    if(de.inum == 0)
    80003e96:	fc045783          	lhu	a5,-64(s0)
    80003e9a:	c791                	beqz	a5,80003ea6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9c:	24c1                	addiw	s1,s1,16
    80003e9e:	04c92783          	lw	a5,76(s2)
    80003ea2:	fcf4ede3          	bltu	s1,a5,80003e7c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ea6:	4639                	li	a2,14
    80003ea8:	85d2                	mv	a1,s4
    80003eaa:	fc240513          	addi	a0,s0,-62
    80003eae:	ffffd097          	auipc	ra,0xffffd
    80003eb2:	f3c080e7          	jalr	-196(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003eb6:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eba:	4741                	li	a4,16
    80003ebc:	86a6                	mv	a3,s1
    80003ebe:	fc040613          	addi	a2,s0,-64
    80003ec2:	4581                	li	a1,0
    80003ec4:	854a                	mv	a0,s2
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	c42080e7          	jalr	-958(ra) # 80003b08 <writei>
    80003ece:	872a                	mv	a4,a0
    80003ed0:	47c1                	li	a5,16
  return 0;
    80003ed2:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed4:	02f71863          	bne	a4,a5,80003f04 <dirlink+0xb2>
}
    80003ed8:	70e2                	ld	ra,56(sp)
    80003eda:	7442                	ld	s0,48(sp)
    80003edc:	74a2                	ld	s1,40(sp)
    80003ede:	7902                	ld	s2,32(sp)
    80003ee0:	69e2                	ld	s3,24(sp)
    80003ee2:	6a42                	ld	s4,16(sp)
    80003ee4:	6121                	addi	sp,sp,64
    80003ee6:	8082                	ret
    iput(ip);
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	a2e080e7          	jalr	-1490(ra) # 80003916 <iput>
    return -1;
    80003ef0:	557d                	li	a0,-1
    80003ef2:	b7dd                	j	80003ed8 <dirlink+0x86>
      panic("dirlink read");
    80003ef4:	00004517          	auipc	a0,0x4
    80003ef8:	6fc50513          	addi	a0,a0,1788 # 800085f0 <syscalls+0x1d0>
    80003efc:	ffffc097          	auipc	ra,0xffffc
    80003f00:	634080e7          	jalr	1588(ra) # 80000530 <panic>
    panic("dirlink");
    80003f04:	00004517          	auipc	a0,0x4
    80003f08:	7fc50513          	addi	a0,a0,2044 # 80008700 <syscalls+0x2e0>
    80003f0c:	ffffc097          	auipc	ra,0xffffc
    80003f10:	624080e7          	jalr	1572(ra) # 80000530 <panic>

0000000080003f14 <namei>:

struct inode*
namei(char *path)
{
    80003f14:	1101                	addi	sp,sp,-32
    80003f16:	ec06                	sd	ra,24(sp)
    80003f18:	e822                	sd	s0,16(sp)
    80003f1a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f1c:	fe040613          	addi	a2,s0,-32
    80003f20:	4581                	li	a1,0
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	dd0080e7          	jalr	-560(ra) # 80003cf2 <namex>
}
    80003f2a:	60e2                	ld	ra,24(sp)
    80003f2c:	6442                	ld	s0,16(sp)
    80003f2e:	6105                	addi	sp,sp,32
    80003f30:	8082                	ret

0000000080003f32 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f32:	1141                	addi	sp,sp,-16
    80003f34:	e406                	sd	ra,8(sp)
    80003f36:	e022                	sd	s0,0(sp)
    80003f38:	0800                	addi	s0,sp,16
    80003f3a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f3c:	4585                	li	a1,1
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	db4080e7          	jalr	-588(ra) # 80003cf2 <namex>
}
    80003f46:	60a2                	ld	ra,8(sp)
    80003f48:	6402                	ld	s0,0(sp)
    80003f4a:	0141                	addi	sp,sp,16
    80003f4c:	8082                	ret

0000000080003f4e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f4e:	1101                	addi	sp,sp,-32
    80003f50:	ec06                	sd	ra,24(sp)
    80003f52:	e822                	sd	s0,16(sp)
    80003f54:	e426                	sd	s1,8(sp)
    80003f56:	e04a                	sd	s2,0(sp)
    80003f58:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f5a:	00018917          	auipc	s2,0x18
    80003f5e:	70e90913          	addi	s2,s2,1806 # 8001c668 <log>
    80003f62:	01892583          	lw	a1,24(s2)
    80003f66:	02892503          	lw	a0,40(s2)
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	e84080e7          	jalr	-380(ra) # 80002dee <bread>
    80003f72:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f74:	02c92683          	lw	a3,44(s2)
    80003f78:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f7a:	02d05763          	blez	a3,80003fa8 <write_head+0x5a>
    80003f7e:	00018797          	auipc	a5,0x18
    80003f82:	71a78793          	addi	a5,a5,1818 # 8001c698 <log+0x30>
    80003f86:	05c50713          	addi	a4,a0,92
    80003f8a:	36fd                	addiw	a3,a3,-1
    80003f8c:	1682                	slli	a3,a3,0x20
    80003f8e:	9281                	srli	a3,a3,0x20
    80003f90:	068a                	slli	a3,a3,0x2
    80003f92:	00018617          	auipc	a2,0x18
    80003f96:	70a60613          	addi	a2,a2,1802 # 8001c69c <log+0x34>
    80003f9a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f9c:	4390                	lw	a2,0(a5)
    80003f9e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fa0:	0791                	addi	a5,a5,4
    80003fa2:	0711                	addi	a4,a4,4
    80003fa4:	fed79ce3          	bne	a5,a3,80003f9c <write_head+0x4e>
  }
  bwrite(buf);
    80003fa8:	8526                	mv	a0,s1
    80003faa:	fffff097          	auipc	ra,0xfffff
    80003fae:	f36080e7          	jalr	-202(ra) # 80002ee0 <bwrite>
  brelse(buf);
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	fffff097          	auipc	ra,0xfffff
    80003fb8:	f6a080e7          	jalr	-150(ra) # 80002f1e <brelse>
}
    80003fbc:	60e2                	ld	ra,24(sp)
    80003fbe:	6442                	ld	s0,16(sp)
    80003fc0:	64a2                	ld	s1,8(sp)
    80003fc2:	6902                	ld	s2,0(sp)
    80003fc4:	6105                	addi	sp,sp,32
    80003fc6:	8082                	ret

0000000080003fc8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc8:	00018797          	auipc	a5,0x18
    80003fcc:	6cc7a783          	lw	a5,1740(a5) # 8001c694 <log+0x2c>
    80003fd0:	0af05d63          	blez	a5,8000408a <install_trans+0xc2>
{
    80003fd4:	7139                	addi	sp,sp,-64
    80003fd6:	fc06                	sd	ra,56(sp)
    80003fd8:	f822                	sd	s0,48(sp)
    80003fda:	f426                	sd	s1,40(sp)
    80003fdc:	f04a                	sd	s2,32(sp)
    80003fde:	ec4e                	sd	s3,24(sp)
    80003fe0:	e852                	sd	s4,16(sp)
    80003fe2:	e456                	sd	s5,8(sp)
    80003fe4:	e05a                	sd	s6,0(sp)
    80003fe6:	0080                	addi	s0,sp,64
    80003fe8:	8b2a                	mv	s6,a0
    80003fea:	00018a97          	auipc	s5,0x18
    80003fee:	6aea8a93          	addi	s5,s5,1710 # 8001c698 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ff4:	00018997          	auipc	s3,0x18
    80003ff8:	67498993          	addi	s3,s3,1652 # 8001c668 <log>
    80003ffc:	a035                	j	80004028 <install_trans+0x60>
      bunpin(dbuf);
    80003ffe:	8526                	mv	a0,s1
    80004000:	fffff097          	auipc	ra,0xfffff
    80004004:	ff8080e7          	jalr	-8(ra) # 80002ff8 <bunpin>
    brelse(lbuf);
    80004008:	854a                	mv	a0,s2
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	f14080e7          	jalr	-236(ra) # 80002f1e <brelse>
    brelse(dbuf);
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	f0a080e7          	jalr	-246(ra) # 80002f1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401c:	2a05                	addiw	s4,s4,1
    8000401e:	0a91                	addi	s5,s5,4
    80004020:	02c9a783          	lw	a5,44(s3)
    80004024:	04fa5963          	bge	s4,a5,80004076 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004028:	0189a583          	lw	a1,24(s3)
    8000402c:	014585bb          	addw	a1,a1,s4
    80004030:	2585                	addiw	a1,a1,1
    80004032:	0289a503          	lw	a0,40(s3)
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	db8080e7          	jalr	-584(ra) # 80002dee <bread>
    8000403e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004040:	000aa583          	lw	a1,0(s5)
    80004044:	0289a503          	lw	a0,40(s3)
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	da6080e7          	jalr	-602(ra) # 80002dee <bread>
    80004050:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004052:	40000613          	li	a2,1024
    80004056:	05890593          	addi	a1,s2,88
    8000405a:	05850513          	addi	a0,a0,88
    8000405e:	ffffd097          	auipc	ra,0xffffd
    80004062:	cd4080e7          	jalr	-812(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004066:	8526                	mv	a0,s1
    80004068:	fffff097          	auipc	ra,0xfffff
    8000406c:	e78080e7          	jalr	-392(ra) # 80002ee0 <bwrite>
    if(recovering == 0)
    80004070:	f80b1ce3          	bnez	s6,80004008 <install_trans+0x40>
    80004074:	b769                	j	80003ffe <install_trans+0x36>
}
    80004076:	70e2                	ld	ra,56(sp)
    80004078:	7442                	ld	s0,48(sp)
    8000407a:	74a2                	ld	s1,40(sp)
    8000407c:	7902                	ld	s2,32(sp)
    8000407e:	69e2                	ld	s3,24(sp)
    80004080:	6a42                	ld	s4,16(sp)
    80004082:	6aa2                	ld	s5,8(sp)
    80004084:	6b02                	ld	s6,0(sp)
    80004086:	6121                	addi	sp,sp,64
    80004088:	8082                	ret
    8000408a:	8082                	ret

000000008000408c <initlog>:
{
    8000408c:	7179                	addi	sp,sp,-48
    8000408e:	f406                	sd	ra,40(sp)
    80004090:	f022                	sd	s0,32(sp)
    80004092:	ec26                	sd	s1,24(sp)
    80004094:	e84a                	sd	s2,16(sp)
    80004096:	e44e                	sd	s3,8(sp)
    80004098:	1800                	addi	s0,sp,48
    8000409a:	892a                	mv	s2,a0
    8000409c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000409e:	00018497          	auipc	s1,0x18
    800040a2:	5ca48493          	addi	s1,s1,1482 # 8001c668 <log>
    800040a6:	00004597          	auipc	a1,0x4
    800040aa:	55a58593          	addi	a1,a1,1370 # 80008600 <syscalls+0x1e0>
    800040ae:	8526                	mv	a0,s1
    800040b0:	ffffd097          	auipc	ra,0xffffd
    800040b4:	a96080e7          	jalr	-1386(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800040b8:	0149a583          	lw	a1,20(s3)
    800040bc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040be:	0109a783          	lw	a5,16(s3)
    800040c2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040c4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040c8:	854a                	mv	a0,s2
    800040ca:	fffff097          	auipc	ra,0xfffff
    800040ce:	d24080e7          	jalr	-732(ra) # 80002dee <bread>
  log.lh.n = lh->n;
    800040d2:	4d3c                	lw	a5,88(a0)
    800040d4:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040d6:	02f05563          	blez	a5,80004100 <initlog+0x74>
    800040da:	05c50713          	addi	a4,a0,92
    800040de:	00018697          	auipc	a3,0x18
    800040e2:	5ba68693          	addi	a3,a3,1466 # 8001c698 <log+0x30>
    800040e6:	37fd                	addiw	a5,a5,-1
    800040e8:	1782                	slli	a5,a5,0x20
    800040ea:	9381                	srli	a5,a5,0x20
    800040ec:	078a                	slli	a5,a5,0x2
    800040ee:	06050613          	addi	a2,a0,96
    800040f2:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040f4:	4310                	lw	a2,0(a4)
    800040f6:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040f8:	0711                	addi	a4,a4,4
    800040fa:	0691                	addi	a3,a3,4
    800040fc:	fef71ce3          	bne	a4,a5,800040f4 <initlog+0x68>
  brelse(buf);
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	e1e080e7          	jalr	-482(ra) # 80002f1e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004108:	4505                	li	a0,1
    8000410a:	00000097          	auipc	ra,0x0
    8000410e:	ebe080e7          	jalr	-322(ra) # 80003fc8 <install_trans>
  log.lh.n = 0;
    80004112:	00018797          	auipc	a5,0x18
    80004116:	5807a123          	sw	zero,1410(a5) # 8001c694 <log+0x2c>
  write_head(); // clear the log
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	e34080e7          	jalr	-460(ra) # 80003f4e <write_head>
}
    80004122:	70a2                	ld	ra,40(sp)
    80004124:	7402                	ld	s0,32(sp)
    80004126:	64e2                	ld	s1,24(sp)
    80004128:	6942                	ld	s2,16(sp)
    8000412a:	69a2                	ld	s3,8(sp)
    8000412c:	6145                	addi	sp,sp,48
    8000412e:	8082                	ret

0000000080004130 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004130:	1101                	addi	sp,sp,-32
    80004132:	ec06                	sd	ra,24(sp)
    80004134:	e822                	sd	s0,16(sp)
    80004136:	e426                	sd	s1,8(sp)
    80004138:	e04a                	sd	s2,0(sp)
    8000413a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000413c:	00018517          	auipc	a0,0x18
    80004140:	52c50513          	addi	a0,a0,1324 # 8001c668 <log>
    80004144:	ffffd097          	auipc	ra,0xffffd
    80004148:	a92080e7          	jalr	-1390(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000414c:	00018497          	auipc	s1,0x18
    80004150:	51c48493          	addi	s1,s1,1308 # 8001c668 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004154:	4979                	li	s2,30
    80004156:	a039                	j	80004164 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004158:	85a6                	mv	a1,s1
    8000415a:	8526                	mv	a0,s1
    8000415c:	ffffe097          	auipc	ra,0xffffe
    80004160:	074080e7          	jalr	116(ra) # 800021d0 <sleep>
    if(log.committing){
    80004164:	50dc                	lw	a5,36(s1)
    80004166:	fbed                	bnez	a5,80004158 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004168:	509c                	lw	a5,32(s1)
    8000416a:	0017871b          	addiw	a4,a5,1
    8000416e:	0007069b          	sext.w	a3,a4
    80004172:	0027179b          	slliw	a5,a4,0x2
    80004176:	9fb9                	addw	a5,a5,a4
    80004178:	0017979b          	slliw	a5,a5,0x1
    8000417c:	54d8                	lw	a4,44(s1)
    8000417e:	9fb9                	addw	a5,a5,a4
    80004180:	00f95963          	bge	s2,a5,80004192 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004184:	85a6                	mv	a1,s1
    80004186:	8526                	mv	a0,s1
    80004188:	ffffe097          	auipc	ra,0xffffe
    8000418c:	048080e7          	jalr	72(ra) # 800021d0 <sleep>
    80004190:	bfd1                	j	80004164 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004192:	00018517          	auipc	a0,0x18
    80004196:	4d650513          	addi	a0,a0,1238 # 8001c668 <log>
    8000419a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000419c:	ffffd097          	auipc	ra,0xffffd
    800041a0:	aee080e7          	jalr	-1298(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041a4:	60e2                	ld	ra,24(sp)
    800041a6:	6442                	ld	s0,16(sp)
    800041a8:	64a2                	ld	s1,8(sp)
    800041aa:	6902                	ld	s2,0(sp)
    800041ac:	6105                	addi	sp,sp,32
    800041ae:	8082                	ret

00000000800041b0 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041b0:	7139                	addi	sp,sp,-64
    800041b2:	fc06                	sd	ra,56(sp)
    800041b4:	f822                	sd	s0,48(sp)
    800041b6:	f426                	sd	s1,40(sp)
    800041b8:	f04a                	sd	s2,32(sp)
    800041ba:	ec4e                	sd	s3,24(sp)
    800041bc:	e852                	sd	s4,16(sp)
    800041be:	e456                	sd	s5,8(sp)
    800041c0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041c2:	00018497          	auipc	s1,0x18
    800041c6:	4a648493          	addi	s1,s1,1190 # 8001c668 <log>
    800041ca:	8526                	mv	a0,s1
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	a0a080e7          	jalr	-1526(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800041d4:	509c                	lw	a5,32(s1)
    800041d6:	37fd                	addiw	a5,a5,-1
    800041d8:	0007891b          	sext.w	s2,a5
    800041dc:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041de:	50dc                	lw	a5,36(s1)
    800041e0:	efb9                	bnez	a5,8000423e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041e2:	06091663          	bnez	s2,8000424e <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041e6:	00018497          	auipc	s1,0x18
    800041ea:	48248493          	addi	s1,s1,1154 # 8001c668 <log>
    800041ee:	4785                	li	a5,1
    800041f0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041f2:	8526                	mv	a0,s1
    800041f4:	ffffd097          	auipc	ra,0xffffd
    800041f8:	a96080e7          	jalr	-1386(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041fc:	54dc                	lw	a5,44(s1)
    800041fe:	06f04763          	bgtz	a5,8000426c <end_op+0xbc>
    acquire(&log.lock);
    80004202:	00018497          	auipc	s1,0x18
    80004206:	46648493          	addi	s1,s1,1126 # 8001c668 <log>
    8000420a:	8526                	mv	a0,s1
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	9ca080e7          	jalr	-1590(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004214:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffe097          	auipc	ra,0xffffe
    8000421e:	13c080e7          	jalr	316(ra) # 80002356 <wakeup>
    release(&log.lock);
    80004222:	8526                	mv	a0,s1
    80004224:	ffffd097          	auipc	ra,0xffffd
    80004228:	a66080e7          	jalr	-1434(ra) # 80000c8a <release>
}
    8000422c:	70e2                	ld	ra,56(sp)
    8000422e:	7442                	ld	s0,48(sp)
    80004230:	74a2                	ld	s1,40(sp)
    80004232:	7902                	ld	s2,32(sp)
    80004234:	69e2                	ld	s3,24(sp)
    80004236:	6a42                	ld	s4,16(sp)
    80004238:	6aa2                	ld	s5,8(sp)
    8000423a:	6121                	addi	sp,sp,64
    8000423c:	8082                	ret
    panic("log.committing");
    8000423e:	00004517          	auipc	a0,0x4
    80004242:	3ca50513          	addi	a0,a0,970 # 80008608 <syscalls+0x1e8>
    80004246:	ffffc097          	auipc	ra,0xffffc
    8000424a:	2ea080e7          	jalr	746(ra) # 80000530 <panic>
    wakeup(&log);
    8000424e:	00018497          	auipc	s1,0x18
    80004252:	41a48493          	addi	s1,s1,1050 # 8001c668 <log>
    80004256:	8526                	mv	a0,s1
    80004258:	ffffe097          	auipc	ra,0xffffe
    8000425c:	0fe080e7          	jalr	254(ra) # 80002356 <wakeup>
  release(&log.lock);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	a28080e7          	jalr	-1496(ra) # 80000c8a <release>
  if(do_commit){
    8000426a:	b7c9                	j	8000422c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000426c:	00018a97          	auipc	s5,0x18
    80004270:	42ca8a93          	addi	s5,s5,1068 # 8001c698 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004274:	00018a17          	auipc	s4,0x18
    80004278:	3f4a0a13          	addi	s4,s4,1012 # 8001c668 <log>
    8000427c:	018a2583          	lw	a1,24(s4)
    80004280:	012585bb          	addw	a1,a1,s2
    80004284:	2585                	addiw	a1,a1,1
    80004286:	028a2503          	lw	a0,40(s4)
    8000428a:	fffff097          	auipc	ra,0xfffff
    8000428e:	b64080e7          	jalr	-1180(ra) # 80002dee <bread>
    80004292:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004294:	000aa583          	lw	a1,0(s5)
    80004298:	028a2503          	lw	a0,40(s4)
    8000429c:	fffff097          	auipc	ra,0xfffff
    800042a0:	b52080e7          	jalr	-1198(ra) # 80002dee <bread>
    800042a4:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042a6:	40000613          	li	a2,1024
    800042aa:	05850593          	addi	a1,a0,88
    800042ae:	05848513          	addi	a0,s1,88
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	a80080e7          	jalr	-1408(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    800042ba:	8526                	mv	a0,s1
    800042bc:	fffff097          	auipc	ra,0xfffff
    800042c0:	c24080e7          	jalr	-988(ra) # 80002ee0 <bwrite>
    brelse(from);
    800042c4:	854e                	mv	a0,s3
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	c58080e7          	jalr	-936(ra) # 80002f1e <brelse>
    brelse(to);
    800042ce:	8526                	mv	a0,s1
    800042d0:	fffff097          	auipc	ra,0xfffff
    800042d4:	c4e080e7          	jalr	-946(ra) # 80002f1e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d8:	2905                	addiw	s2,s2,1
    800042da:	0a91                	addi	s5,s5,4
    800042dc:	02ca2783          	lw	a5,44(s4)
    800042e0:	f8f94ee3          	blt	s2,a5,8000427c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042e4:	00000097          	auipc	ra,0x0
    800042e8:	c6a080e7          	jalr	-918(ra) # 80003f4e <write_head>
    install_trans(0); // Now install writes to home locations
    800042ec:	4501                	li	a0,0
    800042ee:	00000097          	auipc	ra,0x0
    800042f2:	cda080e7          	jalr	-806(ra) # 80003fc8 <install_trans>
    log.lh.n = 0;
    800042f6:	00018797          	auipc	a5,0x18
    800042fa:	3807af23          	sw	zero,926(a5) # 8001c694 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	c50080e7          	jalr	-944(ra) # 80003f4e <write_head>
    80004306:	bdf5                	j	80004202 <end_op+0x52>

0000000080004308 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004308:	1101                	addi	sp,sp,-32
    8000430a:	ec06                	sd	ra,24(sp)
    8000430c:	e822                	sd	s0,16(sp)
    8000430e:	e426                	sd	s1,8(sp)
    80004310:	e04a                	sd	s2,0(sp)
    80004312:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004314:	00018717          	auipc	a4,0x18
    80004318:	38072703          	lw	a4,896(a4) # 8001c694 <log+0x2c>
    8000431c:	47f5                	li	a5,29
    8000431e:	08e7c063          	blt	a5,a4,8000439e <log_write+0x96>
    80004322:	84aa                	mv	s1,a0
    80004324:	00018797          	auipc	a5,0x18
    80004328:	3607a783          	lw	a5,864(a5) # 8001c684 <log+0x1c>
    8000432c:	37fd                	addiw	a5,a5,-1
    8000432e:	06f75863          	bge	a4,a5,8000439e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004332:	00018797          	auipc	a5,0x18
    80004336:	3567a783          	lw	a5,854(a5) # 8001c688 <log+0x20>
    8000433a:	06f05a63          	blez	a5,800043ae <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000433e:	00018917          	auipc	s2,0x18
    80004342:	32a90913          	addi	s2,s2,810 # 8001c668 <log>
    80004346:	854a                	mv	a0,s2
    80004348:	ffffd097          	auipc	ra,0xffffd
    8000434c:	88e080e7          	jalr	-1906(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004350:	02c92603          	lw	a2,44(s2)
    80004354:	06c05563          	blez	a2,800043be <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004358:	44cc                	lw	a1,12(s1)
    8000435a:	00018717          	auipc	a4,0x18
    8000435e:	33e70713          	addi	a4,a4,830 # 8001c698 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004362:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004364:	4314                	lw	a3,0(a4)
    80004366:	04b68d63          	beq	a3,a1,800043c0 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000436a:	2785                	addiw	a5,a5,1
    8000436c:	0711                	addi	a4,a4,4
    8000436e:	fec79be3          	bne	a5,a2,80004364 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004372:	0621                	addi	a2,a2,8
    80004374:	060a                	slli	a2,a2,0x2
    80004376:	00018797          	auipc	a5,0x18
    8000437a:	2f278793          	addi	a5,a5,754 # 8001c668 <log>
    8000437e:	963e                	add	a2,a2,a5
    80004380:	44dc                	lw	a5,12(s1)
    80004382:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004384:	8526                	mv	a0,s1
    80004386:	fffff097          	auipc	ra,0xfffff
    8000438a:	c36080e7          	jalr	-970(ra) # 80002fbc <bpin>
    log.lh.n++;
    8000438e:	00018717          	auipc	a4,0x18
    80004392:	2da70713          	addi	a4,a4,730 # 8001c668 <log>
    80004396:	575c                	lw	a5,44(a4)
    80004398:	2785                	addiw	a5,a5,1
    8000439a:	d75c                	sw	a5,44(a4)
    8000439c:	a83d                	j	800043da <log_write+0xd2>
    panic("too big a transaction");
    8000439e:	00004517          	auipc	a0,0x4
    800043a2:	27a50513          	addi	a0,a0,634 # 80008618 <syscalls+0x1f8>
    800043a6:	ffffc097          	auipc	ra,0xffffc
    800043aa:	18a080e7          	jalr	394(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    800043ae:	00004517          	auipc	a0,0x4
    800043b2:	28250513          	addi	a0,a0,642 # 80008630 <syscalls+0x210>
    800043b6:	ffffc097          	auipc	ra,0xffffc
    800043ba:	17a080e7          	jalr	378(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043be:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043c0:	00878713          	addi	a4,a5,8
    800043c4:	00271693          	slli	a3,a4,0x2
    800043c8:	00018717          	auipc	a4,0x18
    800043cc:	2a070713          	addi	a4,a4,672 # 8001c668 <log>
    800043d0:	9736                	add	a4,a4,a3
    800043d2:	44d4                	lw	a3,12(s1)
    800043d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043d6:	faf607e3          	beq	a2,a5,80004384 <log_write+0x7c>
  }
  release(&log.lock);
    800043da:	00018517          	auipc	a0,0x18
    800043de:	28e50513          	addi	a0,a0,654 # 8001c668 <log>
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	8a8080e7          	jalr	-1880(ra) # 80000c8a <release>
}
    800043ea:	60e2                	ld	ra,24(sp)
    800043ec:	6442                	ld	s0,16(sp)
    800043ee:	64a2                	ld	s1,8(sp)
    800043f0:	6902                	ld	s2,0(sp)
    800043f2:	6105                	addi	sp,sp,32
    800043f4:	8082                	ret

00000000800043f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043f6:	1101                	addi	sp,sp,-32
    800043f8:	ec06                	sd	ra,24(sp)
    800043fa:	e822                	sd	s0,16(sp)
    800043fc:	e426                	sd	s1,8(sp)
    800043fe:	e04a                	sd	s2,0(sp)
    80004400:	1000                	addi	s0,sp,32
    80004402:	84aa                	mv	s1,a0
    80004404:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004406:	00004597          	auipc	a1,0x4
    8000440a:	24a58593          	addi	a1,a1,586 # 80008650 <syscalls+0x230>
    8000440e:	0521                	addi	a0,a0,8
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	736080e7          	jalr	1846(ra) # 80000b46 <initlock>
  lk->name = name;
    80004418:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000441c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004420:	0204a423          	sw	zero,40(s1)
}
    80004424:	60e2                	ld	ra,24(sp)
    80004426:	6442                	ld	s0,16(sp)
    80004428:	64a2                	ld	s1,8(sp)
    8000442a:	6902                	ld	s2,0(sp)
    8000442c:	6105                	addi	sp,sp,32
    8000442e:	8082                	ret

0000000080004430 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004430:	1101                	addi	sp,sp,-32
    80004432:	ec06                	sd	ra,24(sp)
    80004434:	e822                	sd	s0,16(sp)
    80004436:	e426                	sd	s1,8(sp)
    80004438:	e04a                	sd	s2,0(sp)
    8000443a:	1000                	addi	s0,sp,32
    8000443c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000443e:	00850913          	addi	s2,a0,8
    80004442:	854a                	mv	a0,s2
    80004444:	ffffc097          	auipc	ra,0xffffc
    80004448:	792080e7          	jalr	1938(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000444c:	409c                	lw	a5,0(s1)
    8000444e:	cb89                	beqz	a5,80004460 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004450:	85ca                	mv	a1,s2
    80004452:	8526                	mv	a0,s1
    80004454:	ffffe097          	auipc	ra,0xffffe
    80004458:	d7c080e7          	jalr	-644(ra) # 800021d0 <sleep>
  while (lk->locked) {
    8000445c:	409c                	lw	a5,0(s1)
    8000445e:	fbed                	bnez	a5,80004450 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004460:	4785                	li	a5,1
    80004462:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	55c080e7          	jalr	1372(ra) # 800019c0 <myproc>
    8000446c:	5d1c                	lw	a5,56(a0)
    8000446e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004470:	854a                	mv	a0,s2
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	818080e7          	jalr	-2024(ra) # 80000c8a <release>
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret

0000000080004486 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
    80004492:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004494:	00850913          	addi	s2,a0,8
    80004498:	854a                	mv	a0,s2
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	73c080e7          	jalr	1852(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044a6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044aa:	8526                	mv	a0,s1
    800044ac:	ffffe097          	auipc	ra,0xffffe
    800044b0:	eaa080e7          	jalr	-342(ra) # 80002356 <wakeup>
  release(&lk->lk);
    800044b4:	854a                	mv	a0,s2
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	7d4080e7          	jalr	2004(ra) # 80000c8a <release>
}
    800044be:	60e2                	ld	ra,24(sp)
    800044c0:	6442                	ld	s0,16(sp)
    800044c2:	64a2                	ld	s1,8(sp)
    800044c4:	6902                	ld	s2,0(sp)
    800044c6:	6105                	addi	sp,sp,32
    800044c8:	8082                	ret

00000000800044ca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ca:	7179                	addi	sp,sp,-48
    800044cc:	f406                	sd	ra,40(sp)
    800044ce:	f022                	sd	s0,32(sp)
    800044d0:	ec26                	sd	s1,24(sp)
    800044d2:	e84a                	sd	s2,16(sp)
    800044d4:	e44e                	sd	s3,8(sp)
    800044d6:	1800                	addi	s0,sp,48
    800044d8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044da:	00850913          	addi	s2,a0,8
    800044de:	854a                	mv	a0,s2
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	6f6080e7          	jalr	1782(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044e8:	409c                	lw	a5,0(s1)
    800044ea:	ef99                	bnez	a5,80004508 <holdingsleep+0x3e>
    800044ec:	4481                	li	s1,0
  release(&lk->lk);
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	79a080e7          	jalr	1946(ra) # 80000c8a <release>
  return r;
}
    800044f8:	8526                	mv	a0,s1
    800044fa:	70a2                	ld	ra,40(sp)
    800044fc:	7402                	ld	s0,32(sp)
    800044fe:	64e2                	ld	s1,24(sp)
    80004500:	6942                	ld	s2,16(sp)
    80004502:	69a2                	ld	s3,8(sp)
    80004504:	6145                	addi	sp,sp,48
    80004506:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004508:	0284a983          	lw	s3,40(s1)
    8000450c:	ffffd097          	auipc	ra,0xffffd
    80004510:	4b4080e7          	jalr	1204(ra) # 800019c0 <myproc>
    80004514:	5d04                	lw	s1,56(a0)
    80004516:	413484b3          	sub	s1,s1,s3
    8000451a:	0014b493          	seqz	s1,s1
    8000451e:	bfc1                	j	800044ee <holdingsleep+0x24>

0000000080004520 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004520:	1141                	addi	sp,sp,-16
    80004522:	e406                	sd	ra,8(sp)
    80004524:	e022                	sd	s0,0(sp)
    80004526:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004528:	00004597          	auipc	a1,0x4
    8000452c:	13858593          	addi	a1,a1,312 # 80008660 <syscalls+0x240>
    80004530:	00018517          	auipc	a0,0x18
    80004534:	28050513          	addi	a0,a0,640 # 8001c7b0 <ftable>
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	60e080e7          	jalr	1550(ra) # 80000b46 <initlock>
}
    80004540:	60a2                	ld	ra,8(sp)
    80004542:	6402                	ld	s0,0(sp)
    80004544:	0141                	addi	sp,sp,16
    80004546:	8082                	ret

0000000080004548 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004548:	1101                	addi	sp,sp,-32
    8000454a:	ec06                	sd	ra,24(sp)
    8000454c:	e822                	sd	s0,16(sp)
    8000454e:	e426                	sd	s1,8(sp)
    80004550:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004552:	00018517          	auipc	a0,0x18
    80004556:	25e50513          	addi	a0,a0,606 # 8001c7b0 <ftable>
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	67c080e7          	jalr	1660(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004562:	00018497          	auipc	s1,0x18
    80004566:	26648493          	addi	s1,s1,614 # 8001c7c8 <ftable+0x18>
    8000456a:	00019717          	auipc	a4,0x19
    8000456e:	1fe70713          	addi	a4,a4,510 # 8001d768 <ftable+0xfb8>
    if(f->ref == 0){
    80004572:	40dc                	lw	a5,4(s1)
    80004574:	cf99                	beqz	a5,80004592 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004576:	02848493          	addi	s1,s1,40
    8000457a:	fee49ce3          	bne	s1,a4,80004572 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000457e:	00018517          	auipc	a0,0x18
    80004582:	23250513          	addi	a0,a0,562 # 8001c7b0 <ftable>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	704080e7          	jalr	1796(ra) # 80000c8a <release>
  return 0;
    8000458e:	4481                	li	s1,0
    80004590:	a819                	j	800045a6 <filealloc+0x5e>
      f->ref = 1;
    80004592:	4785                	li	a5,1
    80004594:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004596:	00018517          	auipc	a0,0x18
    8000459a:	21a50513          	addi	a0,a0,538 # 8001c7b0 <ftable>
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	6ec080e7          	jalr	1772(ra) # 80000c8a <release>
}
    800045a6:	8526                	mv	a0,s1
    800045a8:	60e2                	ld	ra,24(sp)
    800045aa:	6442                	ld	s0,16(sp)
    800045ac:	64a2                	ld	s1,8(sp)
    800045ae:	6105                	addi	sp,sp,32
    800045b0:	8082                	ret

00000000800045b2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045b2:	1101                	addi	sp,sp,-32
    800045b4:	ec06                	sd	ra,24(sp)
    800045b6:	e822                	sd	s0,16(sp)
    800045b8:	e426                	sd	s1,8(sp)
    800045ba:	1000                	addi	s0,sp,32
    800045bc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045be:	00018517          	auipc	a0,0x18
    800045c2:	1f250513          	addi	a0,a0,498 # 8001c7b0 <ftable>
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	610080e7          	jalr	1552(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800045ce:	40dc                	lw	a5,4(s1)
    800045d0:	02f05263          	blez	a5,800045f4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045d4:	2785                	addiw	a5,a5,1
    800045d6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045d8:	00018517          	auipc	a0,0x18
    800045dc:	1d850513          	addi	a0,a0,472 # 8001c7b0 <ftable>
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6aa080e7          	jalr	1706(ra) # 80000c8a <release>
  return f;
}
    800045e8:	8526                	mv	a0,s1
    800045ea:	60e2                	ld	ra,24(sp)
    800045ec:	6442                	ld	s0,16(sp)
    800045ee:	64a2                	ld	s1,8(sp)
    800045f0:	6105                	addi	sp,sp,32
    800045f2:	8082                	ret
    panic("filedup");
    800045f4:	00004517          	auipc	a0,0x4
    800045f8:	07450513          	addi	a0,a0,116 # 80008668 <syscalls+0x248>
    800045fc:	ffffc097          	auipc	ra,0xffffc
    80004600:	f34080e7          	jalr	-204(ra) # 80000530 <panic>

0000000080004604 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004604:	7139                	addi	sp,sp,-64
    80004606:	fc06                	sd	ra,56(sp)
    80004608:	f822                	sd	s0,48(sp)
    8000460a:	f426                	sd	s1,40(sp)
    8000460c:	f04a                	sd	s2,32(sp)
    8000460e:	ec4e                	sd	s3,24(sp)
    80004610:	e852                	sd	s4,16(sp)
    80004612:	e456                	sd	s5,8(sp)
    80004614:	0080                	addi	s0,sp,64
    80004616:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004618:	00018517          	auipc	a0,0x18
    8000461c:	19850513          	addi	a0,a0,408 # 8001c7b0 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	5b6080e7          	jalr	1462(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004628:	40dc                	lw	a5,4(s1)
    8000462a:	06f05163          	blez	a5,8000468c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000462e:	37fd                	addiw	a5,a5,-1
    80004630:	0007871b          	sext.w	a4,a5
    80004634:	c0dc                	sw	a5,4(s1)
    80004636:	06e04363          	bgtz	a4,8000469c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000463a:	0004a903          	lw	s2,0(s1)
    8000463e:	0094ca83          	lbu	s5,9(s1)
    80004642:	0104ba03          	ld	s4,16(s1)
    80004646:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000464a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000464e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004652:	00018517          	auipc	a0,0x18
    80004656:	15e50513          	addi	a0,a0,350 # 8001c7b0 <ftable>
    8000465a:	ffffc097          	auipc	ra,0xffffc
    8000465e:	630080e7          	jalr	1584(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004662:	4785                	li	a5,1
    80004664:	04f90d63          	beq	s2,a5,800046be <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004668:	3979                	addiw	s2,s2,-2
    8000466a:	4785                	li	a5,1
    8000466c:	0527e063          	bltu	a5,s2,800046ac <fileclose+0xa8>
    begin_op();
    80004670:	00000097          	auipc	ra,0x0
    80004674:	ac0080e7          	jalr	-1344(ra) # 80004130 <begin_op>
    iput(ff.ip);
    80004678:	854e                	mv	a0,s3
    8000467a:	fffff097          	auipc	ra,0xfffff
    8000467e:	29c080e7          	jalr	668(ra) # 80003916 <iput>
    end_op();
    80004682:	00000097          	auipc	ra,0x0
    80004686:	b2e080e7          	jalr	-1234(ra) # 800041b0 <end_op>
    8000468a:	a00d                	j	800046ac <fileclose+0xa8>
    panic("fileclose");
    8000468c:	00004517          	auipc	a0,0x4
    80004690:	fe450513          	addi	a0,a0,-28 # 80008670 <syscalls+0x250>
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	e9c080e7          	jalr	-356(ra) # 80000530 <panic>
    release(&ftable.lock);
    8000469c:	00018517          	auipc	a0,0x18
    800046a0:	11450513          	addi	a0,a0,276 # 8001c7b0 <ftable>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	5e6080e7          	jalr	1510(ra) # 80000c8a <release>
  }
}
    800046ac:	70e2                	ld	ra,56(sp)
    800046ae:	7442                	ld	s0,48(sp)
    800046b0:	74a2                	ld	s1,40(sp)
    800046b2:	7902                	ld	s2,32(sp)
    800046b4:	69e2                	ld	s3,24(sp)
    800046b6:	6a42                	ld	s4,16(sp)
    800046b8:	6aa2                	ld	s5,8(sp)
    800046ba:	6121                	addi	sp,sp,64
    800046bc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046be:	85d6                	mv	a1,s5
    800046c0:	8552                	mv	a0,s4
    800046c2:	00000097          	auipc	ra,0x0
    800046c6:	34c080e7          	jalr	844(ra) # 80004a0e <pipeclose>
    800046ca:	b7cd                	j	800046ac <fileclose+0xa8>

00000000800046cc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046cc:	715d                	addi	sp,sp,-80
    800046ce:	e486                	sd	ra,72(sp)
    800046d0:	e0a2                	sd	s0,64(sp)
    800046d2:	fc26                	sd	s1,56(sp)
    800046d4:	f84a                	sd	s2,48(sp)
    800046d6:	f44e                	sd	s3,40(sp)
    800046d8:	0880                	addi	s0,sp,80
    800046da:	84aa                	mv	s1,a0
    800046dc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046de:	ffffd097          	auipc	ra,0xffffd
    800046e2:	2e2080e7          	jalr	738(ra) # 800019c0 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046e6:	409c                	lw	a5,0(s1)
    800046e8:	37f9                	addiw	a5,a5,-2
    800046ea:	4705                	li	a4,1
    800046ec:	04f76763          	bltu	a4,a5,8000473a <filestat+0x6e>
    800046f0:	892a                	mv	s2,a0
    ilock(f->ip);
    800046f2:	6c88                	ld	a0,24(s1)
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	fc2080e7          	jalr	-62(ra) # 800036b6 <ilock>
    stati(f->ip, &st);
    800046fc:	fb840593          	addi	a1,s0,-72
    80004700:	6c88                	ld	a0,24(s1)
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	2e4080e7          	jalr	740(ra) # 800039e6 <stati>
    iunlock(f->ip);
    8000470a:	6c88                	ld	a0,24(s1)
    8000470c:	fffff097          	auipc	ra,0xfffff
    80004710:	06c080e7          	jalr	108(ra) # 80003778 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004714:	46e1                	li	a3,24
    80004716:	fb840613          	addi	a2,s0,-72
    8000471a:	85ce                	mv	a1,s3
    8000471c:	05093503          	ld	a0,80(s2)
    80004720:	ffffd097          	auipc	ra,0xffffd
    80004724:	f36080e7          	jalr	-202(ra) # 80001656 <copyout>
    80004728:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000472c:	60a6                	ld	ra,72(sp)
    8000472e:	6406                	ld	s0,64(sp)
    80004730:	74e2                	ld	s1,56(sp)
    80004732:	7942                	ld	s2,48(sp)
    80004734:	79a2                	ld	s3,40(sp)
    80004736:	6161                	addi	sp,sp,80
    80004738:	8082                	ret
  return -1;
    8000473a:	557d                	li	a0,-1
    8000473c:	bfc5                	j	8000472c <filestat+0x60>

000000008000473e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000473e:	7179                	addi	sp,sp,-48
    80004740:	f406                	sd	ra,40(sp)
    80004742:	f022                	sd	s0,32(sp)
    80004744:	ec26                	sd	s1,24(sp)
    80004746:	e84a                	sd	s2,16(sp)
    80004748:	e44e                	sd	s3,8(sp)
    8000474a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000474c:	00854783          	lbu	a5,8(a0)
    80004750:	c3d5                	beqz	a5,800047f4 <fileread+0xb6>
    80004752:	84aa                	mv	s1,a0
    80004754:	89ae                	mv	s3,a1
    80004756:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004758:	411c                	lw	a5,0(a0)
    8000475a:	4705                	li	a4,1
    8000475c:	04e78963          	beq	a5,a4,800047ae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004760:	470d                	li	a4,3
    80004762:	04e78d63          	beq	a5,a4,800047bc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004766:	4709                	li	a4,2
    80004768:	06e79e63          	bne	a5,a4,800047e4 <fileread+0xa6>
    ilock(f->ip);
    8000476c:	6d08                	ld	a0,24(a0)
    8000476e:	fffff097          	auipc	ra,0xfffff
    80004772:	f48080e7          	jalr	-184(ra) # 800036b6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004776:	874a                	mv	a4,s2
    80004778:	5094                	lw	a3,32(s1)
    8000477a:	864e                	mv	a2,s3
    8000477c:	4585                	li	a1,1
    8000477e:	6c88                	ld	a0,24(s1)
    80004780:	fffff097          	auipc	ra,0xfffff
    80004784:	290080e7          	jalr	656(ra) # 80003a10 <readi>
    80004788:	892a                	mv	s2,a0
    8000478a:	00a05563          	blez	a0,80004794 <fileread+0x56>
      f->off += r;
    8000478e:	509c                	lw	a5,32(s1)
    80004790:	9fa9                	addw	a5,a5,a0
    80004792:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004794:	6c88                	ld	a0,24(s1)
    80004796:	fffff097          	auipc	ra,0xfffff
    8000479a:	fe2080e7          	jalr	-30(ra) # 80003778 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000479e:	854a                	mv	a0,s2
    800047a0:	70a2                	ld	ra,40(sp)
    800047a2:	7402                	ld	s0,32(sp)
    800047a4:	64e2                	ld	s1,24(sp)
    800047a6:	6942                	ld	s2,16(sp)
    800047a8:	69a2                	ld	s3,8(sp)
    800047aa:	6145                	addi	sp,sp,48
    800047ac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047ae:	6908                	ld	a0,16(a0)
    800047b0:	00000097          	auipc	ra,0x0
    800047b4:	3c8080e7          	jalr	968(ra) # 80004b78 <piperead>
    800047b8:	892a                	mv	s2,a0
    800047ba:	b7d5                	j	8000479e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047bc:	02451783          	lh	a5,36(a0)
    800047c0:	03079693          	slli	a3,a5,0x30
    800047c4:	92c1                	srli	a3,a3,0x30
    800047c6:	4725                	li	a4,9
    800047c8:	02d76863          	bltu	a4,a3,800047f8 <fileread+0xba>
    800047cc:	0792                	slli	a5,a5,0x4
    800047ce:	00018717          	auipc	a4,0x18
    800047d2:	f4270713          	addi	a4,a4,-190 # 8001c710 <devsw>
    800047d6:	97ba                	add	a5,a5,a4
    800047d8:	639c                	ld	a5,0(a5)
    800047da:	c38d                	beqz	a5,800047fc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047dc:	4505                	li	a0,1
    800047de:	9782                	jalr	a5
    800047e0:	892a                	mv	s2,a0
    800047e2:	bf75                	j	8000479e <fileread+0x60>
    panic("fileread");
    800047e4:	00004517          	auipc	a0,0x4
    800047e8:	e9c50513          	addi	a0,a0,-356 # 80008680 <syscalls+0x260>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	d44080e7          	jalr	-700(ra) # 80000530 <panic>
    return -1;
    800047f4:	597d                	li	s2,-1
    800047f6:	b765                	j	8000479e <fileread+0x60>
      return -1;
    800047f8:	597d                	li	s2,-1
    800047fa:	b755                	j	8000479e <fileread+0x60>
    800047fc:	597d                	li	s2,-1
    800047fe:	b745                	j	8000479e <fileread+0x60>

0000000080004800 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004800:	715d                	addi	sp,sp,-80
    80004802:	e486                	sd	ra,72(sp)
    80004804:	e0a2                	sd	s0,64(sp)
    80004806:	fc26                	sd	s1,56(sp)
    80004808:	f84a                	sd	s2,48(sp)
    8000480a:	f44e                	sd	s3,40(sp)
    8000480c:	f052                	sd	s4,32(sp)
    8000480e:	ec56                	sd	s5,24(sp)
    80004810:	e85a                	sd	s6,16(sp)
    80004812:	e45e                	sd	s7,8(sp)
    80004814:	e062                	sd	s8,0(sp)
    80004816:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004818:	00954783          	lbu	a5,9(a0)
    8000481c:	10078663          	beqz	a5,80004928 <filewrite+0x128>
    80004820:	892a                	mv	s2,a0
    80004822:	8aae                	mv	s5,a1
    80004824:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004826:	411c                	lw	a5,0(a0)
    80004828:	4705                	li	a4,1
    8000482a:	02e78263          	beq	a5,a4,8000484e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000482e:	470d                	li	a4,3
    80004830:	02e78663          	beq	a5,a4,8000485c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004834:	4709                	li	a4,2
    80004836:	0ee79163          	bne	a5,a4,80004918 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000483a:	0ac05d63          	blez	a2,800048f4 <filewrite+0xf4>
    int i = 0;
    8000483e:	4981                	li	s3,0
    80004840:	6b05                	lui	s6,0x1
    80004842:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004846:	6b85                	lui	s7,0x1
    80004848:	c00b8b9b          	addiw	s7,s7,-1024
    8000484c:	a861                	j	800048e4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000484e:	6908                	ld	a0,16(a0)
    80004850:	00000097          	auipc	ra,0x0
    80004854:	22e080e7          	jalr	558(ra) # 80004a7e <pipewrite>
    80004858:	8a2a                	mv	s4,a0
    8000485a:	a045                	j	800048fa <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000485c:	02451783          	lh	a5,36(a0)
    80004860:	03079693          	slli	a3,a5,0x30
    80004864:	92c1                	srli	a3,a3,0x30
    80004866:	4725                	li	a4,9
    80004868:	0cd76263          	bltu	a4,a3,8000492c <filewrite+0x12c>
    8000486c:	0792                	slli	a5,a5,0x4
    8000486e:	00018717          	auipc	a4,0x18
    80004872:	ea270713          	addi	a4,a4,-350 # 8001c710 <devsw>
    80004876:	97ba                	add	a5,a5,a4
    80004878:	679c                	ld	a5,8(a5)
    8000487a:	cbdd                	beqz	a5,80004930 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000487c:	4505                	li	a0,1
    8000487e:	9782                	jalr	a5
    80004880:	8a2a                	mv	s4,a0
    80004882:	a8a5                	j	800048fa <filewrite+0xfa>
    80004884:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004888:	00000097          	auipc	ra,0x0
    8000488c:	8a8080e7          	jalr	-1880(ra) # 80004130 <begin_op>
      ilock(f->ip);
    80004890:	01893503          	ld	a0,24(s2)
    80004894:	fffff097          	auipc	ra,0xfffff
    80004898:	e22080e7          	jalr	-478(ra) # 800036b6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000489c:	8762                	mv	a4,s8
    8000489e:	02092683          	lw	a3,32(s2)
    800048a2:	01598633          	add	a2,s3,s5
    800048a6:	4585                	li	a1,1
    800048a8:	01893503          	ld	a0,24(s2)
    800048ac:	fffff097          	auipc	ra,0xfffff
    800048b0:	25c080e7          	jalr	604(ra) # 80003b08 <writei>
    800048b4:	84aa                	mv	s1,a0
    800048b6:	00a05763          	blez	a0,800048c4 <filewrite+0xc4>
        f->off += r;
    800048ba:	02092783          	lw	a5,32(s2)
    800048be:	9fa9                	addw	a5,a5,a0
    800048c0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048c4:	01893503          	ld	a0,24(s2)
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	eb0080e7          	jalr	-336(ra) # 80003778 <iunlock>
      end_op();
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	8e0080e7          	jalr	-1824(ra) # 800041b0 <end_op>

      if(r != n1){
    800048d8:	009c1f63          	bne	s8,s1,800048f6 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048dc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048e0:	0149db63          	bge	s3,s4,800048f6 <filewrite+0xf6>
      int n1 = n - i;
    800048e4:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048e8:	84be                	mv	s1,a5
    800048ea:	2781                	sext.w	a5,a5
    800048ec:	f8fb5ce3          	bge	s6,a5,80004884 <filewrite+0x84>
    800048f0:	84de                	mv	s1,s7
    800048f2:	bf49                	j	80004884 <filewrite+0x84>
    int i = 0;
    800048f4:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800048f6:	013a1f63          	bne	s4,s3,80004914 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048fa:	8552                	mv	a0,s4
    800048fc:	60a6                	ld	ra,72(sp)
    800048fe:	6406                	ld	s0,64(sp)
    80004900:	74e2                	ld	s1,56(sp)
    80004902:	7942                	ld	s2,48(sp)
    80004904:	79a2                	ld	s3,40(sp)
    80004906:	7a02                	ld	s4,32(sp)
    80004908:	6ae2                	ld	s5,24(sp)
    8000490a:	6b42                	ld	s6,16(sp)
    8000490c:	6ba2                	ld	s7,8(sp)
    8000490e:	6c02                	ld	s8,0(sp)
    80004910:	6161                	addi	sp,sp,80
    80004912:	8082                	ret
    ret = (i == n ? n : -1);
    80004914:	5a7d                	li	s4,-1
    80004916:	b7d5                	j	800048fa <filewrite+0xfa>
    panic("filewrite");
    80004918:	00004517          	auipc	a0,0x4
    8000491c:	d7850513          	addi	a0,a0,-648 # 80008690 <syscalls+0x270>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	c10080e7          	jalr	-1008(ra) # 80000530 <panic>
    return -1;
    80004928:	5a7d                	li	s4,-1
    8000492a:	bfc1                	j	800048fa <filewrite+0xfa>
      return -1;
    8000492c:	5a7d                	li	s4,-1
    8000492e:	b7f1                	j	800048fa <filewrite+0xfa>
    80004930:	5a7d                	li	s4,-1
    80004932:	b7e1                	j	800048fa <filewrite+0xfa>

0000000080004934 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004934:	7179                	addi	sp,sp,-48
    80004936:	f406                	sd	ra,40(sp)
    80004938:	f022                	sd	s0,32(sp)
    8000493a:	ec26                	sd	s1,24(sp)
    8000493c:	e84a                	sd	s2,16(sp)
    8000493e:	e44e                	sd	s3,8(sp)
    80004940:	e052                	sd	s4,0(sp)
    80004942:	1800                	addi	s0,sp,48
    80004944:	84aa                	mv	s1,a0
    80004946:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004948:	0005b023          	sd	zero,0(a1)
    8000494c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004950:	00000097          	auipc	ra,0x0
    80004954:	bf8080e7          	jalr	-1032(ra) # 80004548 <filealloc>
    80004958:	e088                	sd	a0,0(s1)
    8000495a:	c551                	beqz	a0,800049e6 <pipealloc+0xb2>
    8000495c:	00000097          	auipc	ra,0x0
    80004960:	bec080e7          	jalr	-1044(ra) # 80004548 <filealloc>
    80004964:	00aa3023          	sd	a0,0(s4)
    80004968:	c92d                	beqz	a0,800049da <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	17c080e7          	jalr	380(ra) # 80000ae6 <kalloc>
    80004972:	892a                	mv	s2,a0
    80004974:	c125                	beqz	a0,800049d4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004976:	4985                	li	s3,1
    80004978:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000497c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004980:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004984:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004988:	00004597          	auipc	a1,0x4
    8000498c:	d1858593          	addi	a1,a1,-744 # 800086a0 <syscalls+0x280>
    80004990:	ffffc097          	auipc	ra,0xffffc
    80004994:	1b6080e7          	jalr	438(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004998:	609c                	ld	a5,0(s1)
    8000499a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000499e:	609c                	ld	a5,0(s1)
    800049a0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049a4:	609c                	ld	a5,0(s1)
    800049a6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049aa:	609c                	ld	a5,0(s1)
    800049ac:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049b0:	000a3783          	ld	a5,0(s4)
    800049b4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049b8:	000a3783          	ld	a5,0(s4)
    800049bc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049c0:	000a3783          	ld	a5,0(s4)
    800049c4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049c8:	000a3783          	ld	a5,0(s4)
    800049cc:	0127b823          	sd	s2,16(a5)
  return 0;
    800049d0:	4501                	li	a0,0
    800049d2:	a025                	j	800049fa <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049d4:	6088                	ld	a0,0(s1)
    800049d6:	e501                	bnez	a0,800049de <pipealloc+0xaa>
    800049d8:	a039                	j	800049e6 <pipealloc+0xb2>
    800049da:	6088                	ld	a0,0(s1)
    800049dc:	c51d                	beqz	a0,80004a0a <pipealloc+0xd6>
    fileclose(*f0);
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	c26080e7          	jalr	-986(ra) # 80004604 <fileclose>
  if(*f1)
    800049e6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049ea:	557d                	li	a0,-1
  if(*f1)
    800049ec:	c799                	beqz	a5,800049fa <pipealloc+0xc6>
    fileclose(*f1);
    800049ee:	853e                	mv	a0,a5
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	c14080e7          	jalr	-1004(ra) # 80004604 <fileclose>
  return -1;
    800049f8:	557d                	li	a0,-1
}
    800049fa:	70a2                	ld	ra,40(sp)
    800049fc:	7402                	ld	s0,32(sp)
    800049fe:	64e2                	ld	s1,24(sp)
    80004a00:	6942                	ld	s2,16(sp)
    80004a02:	69a2                	ld	s3,8(sp)
    80004a04:	6a02                	ld	s4,0(sp)
    80004a06:	6145                	addi	sp,sp,48
    80004a08:	8082                	ret
  return -1;
    80004a0a:	557d                	li	a0,-1
    80004a0c:	b7fd                	j	800049fa <pipealloc+0xc6>

0000000080004a0e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a0e:	1101                	addi	sp,sp,-32
    80004a10:	ec06                	sd	ra,24(sp)
    80004a12:	e822                	sd	s0,16(sp)
    80004a14:	e426                	sd	s1,8(sp)
    80004a16:	e04a                	sd	s2,0(sp)
    80004a18:	1000                	addi	s0,sp,32
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a1e:	ffffc097          	auipc	ra,0xffffc
    80004a22:	1b8080e7          	jalr	440(ra) # 80000bd6 <acquire>
  if(writable){
    80004a26:	02090d63          	beqz	s2,80004a60 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a2a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a2e:	21848513          	addi	a0,s1,536
    80004a32:	ffffe097          	auipc	ra,0xffffe
    80004a36:	924080e7          	jalr	-1756(ra) # 80002356 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a3a:	2204b783          	ld	a5,544(s1)
    80004a3e:	eb95                	bnez	a5,80004a72 <pipeclose+0x64>
    release(&pi->lock);
    80004a40:	8526                	mv	a0,s1
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	248080e7          	jalr	584(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a4a:	8526                	mv	a0,s1
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	f9e080e7          	jalr	-98(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004a54:	60e2                	ld	ra,24(sp)
    80004a56:	6442                	ld	s0,16(sp)
    80004a58:	64a2                	ld	s1,8(sp)
    80004a5a:	6902                	ld	s2,0(sp)
    80004a5c:	6105                	addi	sp,sp,32
    80004a5e:	8082                	ret
    pi->readopen = 0;
    80004a60:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a64:	21c48513          	addi	a0,s1,540
    80004a68:	ffffe097          	auipc	ra,0xffffe
    80004a6c:	8ee080e7          	jalr	-1810(ra) # 80002356 <wakeup>
    80004a70:	b7e9                	j	80004a3a <pipeclose+0x2c>
    release(&pi->lock);
    80004a72:	8526                	mv	a0,s1
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	216080e7          	jalr	534(ra) # 80000c8a <release>
}
    80004a7c:	bfe1                	j	80004a54 <pipeclose+0x46>

0000000080004a7e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a7e:	7159                	addi	sp,sp,-112
    80004a80:	f486                	sd	ra,104(sp)
    80004a82:	f0a2                	sd	s0,96(sp)
    80004a84:	eca6                	sd	s1,88(sp)
    80004a86:	e8ca                	sd	s2,80(sp)
    80004a88:	e4ce                	sd	s3,72(sp)
    80004a8a:	e0d2                	sd	s4,64(sp)
    80004a8c:	fc56                	sd	s5,56(sp)
    80004a8e:	f85a                	sd	s6,48(sp)
    80004a90:	f45e                	sd	s7,40(sp)
    80004a92:	f062                	sd	s8,32(sp)
    80004a94:	ec66                	sd	s9,24(sp)
    80004a96:	1880                	addi	s0,sp,112
    80004a98:	84aa                	mv	s1,a0
    80004a9a:	8aae                	mv	s5,a1
    80004a9c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004a9e:	ffffd097          	auipc	ra,0xffffd
    80004aa2:	f22080e7          	jalr	-222(ra) # 800019c0 <myproc>
    80004aa6:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	12c080e7          	jalr	300(ra) # 80000bd6 <acquire>
  while(i < n){
    80004ab2:	0d405163          	blez	s4,80004b74 <pipewrite+0xf6>
    80004ab6:	8ba6                	mv	s7,s1
  int i = 0;
    80004ab8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004aba:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004abc:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ac0:	21c48c13          	addi	s8,s1,540
    80004ac4:	a08d                	j	80004b26 <pipewrite+0xa8>
      release(&pi->lock);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	1c2080e7          	jalr	450(ra) # 80000c8a <release>
      return -1;
    80004ad0:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ad2:	854a                	mv	a0,s2
    80004ad4:	70a6                	ld	ra,104(sp)
    80004ad6:	7406                	ld	s0,96(sp)
    80004ad8:	64e6                	ld	s1,88(sp)
    80004ada:	6946                	ld	s2,80(sp)
    80004adc:	69a6                	ld	s3,72(sp)
    80004ade:	6a06                	ld	s4,64(sp)
    80004ae0:	7ae2                	ld	s5,56(sp)
    80004ae2:	7b42                	ld	s6,48(sp)
    80004ae4:	7ba2                	ld	s7,40(sp)
    80004ae6:	7c02                	ld	s8,32(sp)
    80004ae8:	6ce2                	ld	s9,24(sp)
    80004aea:	6165                	addi	sp,sp,112
    80004aec:	8082                	ret
      wakeup(&pi->nread);
    80004aee:	8566                	mv	a0,s9
    80004af0:	ffffe097          	auipc	ra,0xffffe
    80004af4:	866080e7          	jalr	-1946(ra) # 80002356 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004af8:	85de                	mv	a1,s7
    80004afa:	8562                	mv	a0,s8
    80004afc:	ffffd097          	auipc	ra,0xffffd
    80004b00:	6d4080e7          	jalr	1748(ra) # 800021d0 <sleep>
    80004b04:	a839                	j	80004b22 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b06:	21c4a783          	lw	a5,540(s1)
    80004b0a:	0017871b          	addiw	a4,a5,1
    80004b0e:	20e4ae23          	sw	a4,540(s1)
    80004b12:	1ff7f793          	andi	a5,a5,511
    80004b16:	97a6                	add	a5,a5,s1
    80004b18:	f9f44703          	lbu	a4,-97(s0)
    80004b1c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b20:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b22:	03495d63          	bge	s2,s4,80004b5c <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b26:	2204a783          	lw	a5,544(s1)
    80004b2a:	dfd1                	beqz	a5,80004ac6 <pipewrite+0x48>
    80004b2c:	0309a783          	lw	a5,48(s3)
    80004b30:	fbd9                	bnez	a5,80004ac6 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b32:	2184a783          	lw	a5,536(s1)
    80004b36:	21c4a703          	lw	a4,540(s1)
    80004b3a:	2007879b          	addiw	a5,a5,512
    80004b3e:	faf708e3          	beq	a4,a5,80004aee <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b42:	4685                	li	a3,1
    80004b44:	01590633          	add	a2,s2,s5
    80004b48:	f9f40593          	addi	a1,s0,-97
    80004b4c:	0509b503          	ld	a0,80(s3)
    80004b50:	ffffd097          	auipc	ra,0xffffd
    80004b54:	b92080e7          	jalr	-1134(ra) # 800016e2 <copyin>
    80004b58:	fb6517e3          	bne	a0,s6,80004b06 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b5c:	21848513          	addi	a0,s1,536
    80004b60:	ffffd097          	auipc	ra,0xffffd
    80004b64:	7f6080e7          	jalr	2038(ra) # 80002356 <wakeup>
  release(&pi->lock);
    80004b68:	8526                	mv	a0,s1
    80004b6a:	ffffc097          	auipc	ra,0xffffc
    80004b6e:	120080e7          	jalr	288(ra) # 80000c8a <release>
  return i;
    80004b72:	b785                	j	80004ad2 <pipewrite+0x54>
  int i = 0;
    80004b74:	4901                	li	s2,0
    80004b76:	b7dd                	j	80004b5c <pipewrite+0xde>

0000000080004b78 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b78:	715d                	addi	sp,sp,-80
    80004b7a:	e486                	sd	ra,72(sp)
    80004b7c:	e0a2                	sd	s0,64(sp)
    80004b7e:	fc26                	sd	s1,56(sp)
    80004b80:	f84a                	sd	s2,48(sp)
    80004b82:	f44e                	sd	s3,40(sp)
    80004b84:	f052                	sd	s4,32(sp)
    80004b86:	ec56                	sd	s5,24(sp)
    80004b88:	e85a                	sd	s6,16(sp)
    80004b8a:	0880                	addi	s0,sp,80
    80004b8c:	84aa                	mv	s1,a0
    80004b8e:	892e                	mv	s2,a1
    80004b90:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	e2e080e7          	jalr	-466(ra) # 800019c0 <myproc>
    80004b9a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004b9c:	8b26                	mv	s6,s1
    80004b9e:	8526                	mv	a0,s1
    80004ba0:	ffffc097          	auipc	ra,0xffffc
    80004ba4:	036080e7          	jalr	54(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ba8:	2184a703          	lw	a4,536(s1)
    80004bac:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bb0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb4:	02f71463          	bne	a4,a5,80004bdc <piperead+0x64>
    80004bb8:	2244a783          	lw	a5,548(s1)
    80004bbc:	c385                	beqz	a5,80004bdc <piperead+0x64>
    if(pr->killed){
    80004bbe:	030a2783          	lw	a5,48(s4)
    80004bc2:	ebc1                	bnez	a5,80004c52 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc4:	85da                	mv	a1,s6
    80004bc6:	854e                	mv	a0,s3
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	608080e7          	jalr	1544(ra) # 800021d0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd0:	2184a703          	lw	a4,536(s1)
    80004bd4:	21c4a783          	lw	a5,540(s1)
    80004bd8:	fef700e3          	beq	a4,a5,80004bb8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bdc:	09505263          	blez	s5,80004c60 <piperead+0xe8>
    80004be0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004be2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004be4:	2184a783          	lw	a5,536(s1)
    80004be8:	21c4a703          	lw	a4,540(s1)
    80004bec:	02f70d63          	beq	a4,a5,80004c26 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004bf0:	0017871b          	addiw	a4,a5,1
    80004bf4:	20e4ac23          	sw	a4,536(s1)
    80004bf8:	1ff7f793          	andi	a5,a5,511
    80004bfc:	97a6                	add	a5,a5,s1
    80004bfe:	0187c783          	lbu	a5,24(a5)
    80004c02:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c06:	4685                	li	a3,1
    80004c08:	fbf40613          	addi	a2,s0,-65
    80004c0c:	85ca                	mv	a1,s2
    80004c0e:	050a3503          	ld	a0,80(s4)
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	a44080e7          	jalr	-1468(ra) # 80001656 <copyout>
    80004c1a:	01650663          	beq	a0,s6,80004c26 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1e:	2985                	addiw	s3,s3,1
    80004c20:	0905                	addi	s2,s2,1
    80004c22:	fd3a91e3          	bne	s5,s3,80004be4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c26:	21c48513          	addi	a0,s1,540
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	72c080e7          	jalr	1836(ra) # 80002356 <wakeup>
  release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	056080e7          	jalr	86(ra) # 80000c8a <release>
  return i;
}
    80004c3c:	854e                	mv	a0,s3
    80004c3e:	60a6                	ld	ra,72(sp)
    80004c40:	6406                	ld	s0,64(sp)
    80004c42:	74e2                	ld	s1,56(sp)
    80004c44:	7942                	ld	s2,48(sp)
    80004c46:	79a2                	ld	s3,40(sp)
    80004c48:	7a02                	ld	s4,32(sp)
    80004c4a:	6ae2                	ld	s5,24(sp)
    80004c4c:	6b42                	ld	s6,16(sp)
    80004c4e:	6161                	addi	sp,sp,80
    80004c50:	8082                	ret
      release(&pi->lock);
    80004c52:	8526                	mv	a0,s1
    80004c54:	ffffc097          	auipc	ra,0xffffc
    80004c58:	036080e7          	jalr	54(ra) # 80000c8a <release>
      return -1;
    80004c5c:	59fd                	li	s3,-1
    80004c5e:	bff9                	j	80004c3c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c60:	4981                	li	s3,0
    80004c62:	b7d1                	j	80004c26 <piperead+0xae>

0000000080004c64 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c64:	df010113          	addi	sp,sp,-528
    80004c68:	20113423          	sd	ra,520(sp)
    80004c6c:	20813023          	sd	s0,512(sp)
    80004c70:	ffa6                	sd	s1,504(sp)
    80004c72:	fbca                	sd	s2,496(sp)
    80004c74:	f7ce                	sd	s3,488(sp)
    80004c76:	f3d2                	sd	s4,480(sp)
    80004c78:	efd6                	sd	s5,472(sp)
    80004c7a:	ebda                	sd	s6,464(sp)
    80004c7c:	e7de                	sd	s7,456(sp)
    80004c7e:	e3e2                	sd	s8,448(sp)
    80004c80:	ff66                	sd	s9,440(sp)
    80004c82:	fb6a                	sd	s10,432(sp)
    80004c84:	f76e                	sd	s11,424(sp)
    80004c86:	0c00                	addi	s0,sp,528
    80004c88:	84aa                	mv	s1,a0
    80004c8a:	dea43c23          	sd	a0,-520(s0)
    80004c8e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	d2e080e7          	jalr	-722(ra) # 800019c0 <myproc>
    80004c9a:	892a                	mv	s2,a0

  begin_op();
    80004c9c:	fffff097          	auipc	ra,0xfffff
    80004ca0:	494080e7          	jalr	1172(ra) # 80004130 <begin_op>

  if((ip = namei(path)) == 0){
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	fffff097          	auipc	ra,0xfffff
    80004caa:	26e080e7          	jalr	622(ra) # 80003f14 <namei>
    80004cae:	c92d                	beqz	a0,80004d20 <exec+0xbc>
    80004cb0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cb2:	fffff097          	auipc	ra,0xfffff
    80004cb6:	a04080e7          	jalr	-1532(ra) # 800036b6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cba:	04000713          	li	a4,64
    80004cbe:	4681                	li	a3,0
    80004cc0:	e4840613          	addi	a2,s0,-440
    80004cc4:	4581                	li	a1,0
    80004cc6:	8526                	mv	a0,s1
    80004cc8:	fffff097          	auipc	ra,0xfffff
    80004ccc:	d48080e7          	jalr	-696(ra) # 80003a10 <readi>
    80004cd0:	04000793          	li	a5,64
    80004cd4:	00f51a63          	bne	a0,a5,80004ce8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cd8:	e4842703          	lw	a4,-440(s0)
    80004cdc:	464c47b7          	lui	a5,0x464c4
    80004ce0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ce4:	04f70463          	beq	a4,a5,80004d2c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ce8:	8526                	mv	a0,s1
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	cd4080e7          	jalr	-812(ra) # 800039be <iunlockput>
    end_op();
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	4be080e7          	jalr	1214(ra) # 800041b0 <end_op>
  }
  return -1;
    80004cfa:	557d                	li	a0,-1
}
    80004cfc:	20813083          	ld	ra,520(sp)
    80004d00:	20013403          	ld	s0,512(sp)
    80004d04:	74fe                	ld	s1,504(sp)
    80004d06:	795e                	ld	s2,496(sp)
    80004d08:	79be                	ld	s3,488(sp)
    80004d0a:	7a1e                	ld	s4,480(sp)
    80004d0c:	6afe                	ld	s5,472(sp)
    80004d0e:	6b5e                	ld	s6,464(sp)
    80004d10:	6bbe                	ld	s7,456(sp)
    80004d12:	6c1e                	ld	s8,448(sp)
    80004d14:	7cfa                	ld	s9,440(sp)
    80004d16:	7d5a                	ld	s10,432(sp)
    80004d18:	7dba                	ld	s11,424(sp)
    80004d1a:	21010113          	addi	sp,sp,528
    80004d1e:	8082                	ret
    end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	490080e7          	jalr	1168(ra) # 800041b0 <end_op>
    return -1;
    80004d28:	557d                	li	a0,-1
    80004d2a:	bfc9                	j	80004cfc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d2c:	854a                	mv	a0,s2
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	d56080e7          	jalr	-682(ra) # 80001a84 <proc_pagetable>
    80004d36:	8baa                	mv	s7,a0
    80004d38:	d945                	beqz	a0,80004ce8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d3a:	e6842983          	lw	s3,-408(s0)
    80004d3e:	e8045783          	lhu	a5,-384(s0)
    80004d42:	c7ad                	beqz	a5,80004dac <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d44:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d46:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d48:	6c85                	lui	s9,0x1
    80004d4a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d4e:	def43823          	sd	a5,-528(s0)
    80004d52:	a42d                	j	80004f7c <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d54:	00004517          	auipc	a0,0x4
    80004d58:	95450513          	addi	a0,a0,-1708 # 800086a8 <syscalls+0x288>
    80004d5c:	ffffb097          	auipc	ra,0xffffb
    80004d60:	7d4080e7          	jalr	2004(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d64:	8756                	mv	a4,s5
    80004d66:	012d86bb          	addw	a3,s11,s2
    80004d6a:	4581                	li	a1,0
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	ca2080e7          	jalr	-862(ra) # 80003a10 <readi>
    80004d76:	2501                	sext.w	a0,a0
    80004d78:	1aaa9963          	bne	s5,a0,80004f2a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d7c:	6785                	lui	a5,0x1
    80004d7e:	0127893b          	addw	s2,a5,s2
    80004d82:	77fd                	lui	a5,0xfffff
    80004d84:	01478a3b          	addw	s4,a5,s4
    80004d88:	1f897163          	bgeu	s2,s8,80004f6a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004d8c:	02091593          	slli	a1,s2,0x20
    80004d90:	9181                	srli	a1,a1,0x20
    80004d92:	95ea                	add	a1,a1,s10
    80004d94:	855e                	mv	a0,s7
    80004d96:	ffffc097          	auipc	ra,0xffffc
    80004d9a:	2ce080e7          	jalr	718(ra) # 80001064 <walkaddr>
    80004d9e:	862a                	mv	a2,a0
    if(pa == 0)
    80004da0:	d955                	beqz	a0,80004d54 <exec+0xf0>
      n = PGSIZE;
    80004da2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004da4:	fd9a70e3          	bgeu	s4,s9,80004d64 <exec+0x100>
      n = sz - i;
    80004da8:	8ad2                	mv	s5,s4
    80004daa:	bf6d                	j	80004d64 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dac:	4901                	li	s2,0
  iunlockput(ip);
    80004dae:	8526                	mv	a0,s1
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	c0e080e7          	jalr	-1010(ra) # 800039be <iunlockput>
  end_op();
    80004db8:	fffff097          	auipc	ra,0xfffff
    80004dbc:	3f8080e7          	jalr	1016(ra) # 800041b0 <end_op>
  p = myproc();
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	c00080e7          	jalr	-1024(ra) # 800019c0 <myproc>
    80004dc8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004dca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dce:	6785                	lui	a5,0x1
    80004dd0:	17fd                	addi	a5,a5,-1
    80004dd2:	993e                	add	s2,s2,a5
    80004dd4:	757d                	lui	a0,0xfffff
    80004dd6:	00a977b3          	and	a5,s2,a0
    80004dda:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004dde:	6609                	lui	a2,0x2
    80004de0:	963e                	add	a2,a2,a5
    80004de2:	85be                	mv	a1,a5
    80004de4:	855e                	mv	a0,s7
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	620080e7          	jalr	1568(ra) # 80001406 <uvmalloc>
    80004dee:	8b2a                	mv	s6,a0
  ip = 0;
    80004df0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df2:	12050c63          	beqz	a0,80004f2a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004df6:	75f9                	lui	a1,0xffffe
    80004df8:	95aa                	add	a1,a1,a0
    80004dfa:	855e                	mv	a0,s7
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	828080e7          	jalr	-2008(ra) # 80001624 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e04:	7c7d                	lui	s8,0xfffff
    80004e06:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e08:	e0043783          	ld	a5,-512(s0)
    80004e0c:	6388                	ld	a0,0(a5)
    80004e0e:	c535                	beqz	a0,80004e7a <exec+0x216>
    80004e10:	e8840993          	addi	s3,s0,-376
    80004e14:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e18:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	040080e7          	jalr	64(ra) # 80000e5a <strlen>
    80004e22:	2505                	addiw	a0,a0,1
    80004e24:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e28:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e2c:	13896363          	bltu	s2,s8,80004f52 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e30:	e0043d83          	ld	s11,-512(s0)
    80004e34:	000dba03          	ld	s4,0(s11)
    80004e38:	8552                	mv	a0,s4
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	020080e7          	jalr	32(ra) # 80000e5a <strlen>
    80004e42:	0015069b          	addiw	a3,a0,1
    80004e46:	8652                	mv	a2,s4
    80004e48:	85ca                	mv	a1,s2
    80004e4a:	855e                	mv	a0,s7
    80004e4c:	ffffd097          	auipc	ra,0xffffd
    80004e50:	80a080e7          	jalr	-2038(ra) # 80001656 <copyout>
    80004e54:	10054363          	bltz	a0,80004f5a <exec+0x2f6>
    ustack[argc] = sp;
    80004e58:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e5c:	0485                	addi	s1,s1,1
    80004e5e:	008d8793          	addi	a5,s11,8
    80004e62:	e0f43023          	sd	a5,-512(s0)
    80004e66:	008db503          	ld	a0,8(s11)
    80004e6a:	c911                	beqz	a0,80004e7e <exec+0x21a>
    if(argc >= MAXARG)
    80004e6c:	09a1                	addi	s3,s3,8
    80004e6e:	fb3c96e3          	bne	s9,s3,80004e1a <exec+0x1b6>
  sz = sz1;
    80004e72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e76:	4481                	li	s1,0
    80004e78:	a84d                	j	80004f2a <exec+0x2c6>
  sp = sz;
    80004e7a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e7c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e7e:	00349793          	slli	a5,s1,0x3
    80004e82:	f9040713          	addi	a4,s0,-112
    80004e86:	97ba                	add	a5,a5,a4
    80004e88:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004e8c:	00148693          	addi	a3,s1,1
    80004e90:	068e                	slli	a3,a3,0x3
    80004e92:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004e96:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004e9a:	01897663          	bgeu	s2,s8,80004ea6 <exec+0x242>
  sz = sz1;
    80004e9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea2:	4481                	li	s1,0
    80004ea4:	a059                	j	80004f2a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ea6:	e8840613          	addi	a2,s0,-376
    80004eaa:	85ca                	mv	a1,s2
    80004eac:	855e                	mv	a0,s7
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	7a8080e7          	jalr	1960(ra) # 80001656 <copyout>
    80004eb6:	0a054663          	bltz	a0,80004f62 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004eba:	058ab783          	ld	a5,88(s5)
    80004ebe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ec2:	df843783          	ld	a5,-520(s0)
    80004ec6:	0007c703          	lbu	a4,0(a5)
    80004eca:	cf11                	beqz	a4,80004ee6 <exec+0x282>
    80004ecc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ece:	02f00693          	li	a3,47
    80004ed2:	a029                	j	80004edc <exec+0x278>
  for(last=s=path; *s; s++)
    80004ed4:	0785                	addi	a5,a5,1
    80004ed6:	fff7c703          	lbu	a4,-1(a5)
    80004eda:	c711                	beqz	a4,80004ee6 <exec+0x282>
    if(*s == '/')
    80004edc:	fed71ce3          	bne	a4,a3,80004ed4 <exec+0x270>
      last = s+1;
    80004ee0:	def43c23          	sd	a5,-520(s0)
    80004ee4:	bfc5                	j	80004ed4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004ee6:	4641                	li	a2,16
    80004ee8:	df843583          	ld	a1,-520(s0)
    80004eec:	158a8513          	addi	a0,s5,344
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	f38080e7          	jalr	-200(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ef8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004efc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f00:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f04:	058ab783          	ld	a5,88(s5)
    80004f08:	e6043703          	ld	a4,-416(s0)
    80004f0c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f0e:	058ab783          	ld	a5,88(s5)
    80004f12:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f16:	85ea                	mv	a1,s10
    80004f18:	ffffd097          	auipc	ra,0xffffd
    80004f1c:	c08080e7          	jalr	-1016(ra) # 80001b20 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f20:	0004851b          	sext.w	a0,s1
    80004f24:	bbe1                	j	80004cfc <exec+0x98>
    80004f26:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f2a:	e0843583          	ld	a1,-504(s0)
    80004f2e:	855e                	mv	a0,s7
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	bf0080e7          	jalr	-1040(ra) # 80001b20 <proc_freepagetable>
  if(ip){
    80004f38:	da0498e3          	bnez	s1,80004ce8 <exec+0x84>
  return -1;
    80004f3c:	557d                	li	a0,-1
    80004f3e:	bb7d                	j	80004cfc <exec+0x98>
    80004f40:	e1243423          	sd	s2,-504(s0)
    80004f44:	b7dd                	j	80004f2a <exec+0x2c6>
    80004f46:	e1243423          	sd	s2,-504(s0)
    80004f4a:	b7c5                	j	80004f2a <exec+0x2c6>
    80004f4c:	e1243423          	sd	s2,-504(s0)
    80004f50:	bfe9                	j	80004f2a <exec+0x2c6>
  sz = sz1;
    80004f52:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f56:	4481                	li	s1,0
    80004f58:	bfc9                	j	80004f2a <exec+0x2c6>
  sz = sz1;
    80004f5a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f5e:	4481                	li	s1,0
    80004f60:	b7e9                	j	80004f2a <exec+0x2c6>
  sz = sz1;
    80004f62:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f66:	4481                	li	s1,0
    80004f68:	b7c9                	j	80004f2a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f6a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f6e:	2b05                	addiw	s6,s6,1
    80004f70:	0389899b          	addiw	s3,s3,56
    80004f74:	e8045783          	lhu	a5,-384(s0)
    80004f78:	e2fb5be3          	bge	s6,a5,80004dae <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f7c:	2981                	sext.w	s3,s3
    80004f7e:	03800713          	li	a4,56
    80004f82:	86ce                	mv	a3,s3
    80004f84:	e1040613          	addi	a2,s0,-496
    80004f88:	4581                	li	a1,0
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	a84080e7          	jalr	-1404(ra) # 80003a10 <readi>
    80004f94:	03800793          	li	a5,56
    80004f98:	f8f517e3          	bne	a0,a5,80004f26 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004f9c:	e1042783          	lw	a5,-496(s0)
    80004fa0:	4705                	li	a4,1
    80004fa2:	fce796e3          	bne	a5,a4,80004f6e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fa6:	e3843603          	ld	a2,-456(s0)
    80004faa:	e3043783          	ld	a5,-464(s0)
    80004fae:	f8f669e3          	bltu	a2,a5,80004f40 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fb2:	e2043783          	ld	a5,-480(s0)
    80004fb6:	963e                	add	a2,a2,a5
    80004fb8:	f8f667e3          	bltu	a2,a5,80004f46 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fbc:	85ca                	mv	a1,s2
    80004fbe:	855e                	mv	a0,s7
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	446080e7          	jalr	1094(ra) # 80001406 <uvmalloc>
    80004fc8:	e0a43423          	sd	a0,-504(s0)
    80004fcc:	d141                	beqz	a0,80004f4c <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004fce:	e2043d03          	ld	s10,-480(s0)
    80004fd2:	df043783          	ld	a5,-528(s0)
    80004fd6:	00fd77b3          	and	a5,s10,a5
    80004fda:	fba1                	bnez	a5,80004f2a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004fdc:	e1842d83          	lw	s11,-488(s0)
    80004fe0:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004fe4:	f80c03e3          	beqz	s8,80004f6a <exec+0x306>
    80004fe8:	8a62                	mv	s4,s8
    80004fea:	4901                	li	s2,0
    80004fec:	b345                	j	80004d8c <exec+0x128>

0000000080004fee <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004fee:	7179                	addi	sp,sp,-48
    80004ff0:	f406                	sd	ra,40(sp)
    80004ff2:	f022                	sd	s0,32(sp)
    80004ff4:	ec26                	sd	s1,24(sp)
    80004ff6:	e84a                	sd	s2,16(sp)
    80004ff8:	1800                	addi	s0,sp,48
    80004ffa:	892e                	mv	s2,a1
    80004ffc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80004ffe:	fdc40593          	addi	a1,s0,-36
    80005002:	ffffe097          	auipc	ra,0xffffe
    80005006:	a7c080e7          	jalr	-1412(ra) # 80002a7e <argint>
    8000500a:	04054063          	bltz	a0,8000504a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000500e:	fdc42703          	lw	a4,-36(s0)
    80005012:	47bd                	li	a5,15
    80005014:	02e7ed63          	bltu	a5,a4,8000504e <argfd+0x60>
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	9a8080e7          	jalr	-1624(ra) # 800019c0 <myproc>
    80005020:	fdc42703          	lw	a4,-36(s0)
    80005024:	01a70793          	addi	a5,a4,26
    80005028:	078e                	slli	a5,a5,0x3
    8000502a:	953e                	add	a0,a0,a5
    8000502c:	611c                	ld	a5,0(a0)
    8000502e:	c395                	beqz	a5,80005052 <argfd+0x64>
    return -1;
  if(pfd)
    80005030:	00090463          	beqz	s2,80005038 <argfd+0x4a>
    *pfd = fd;
    80005034:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005038:	4501                	li	a0,0
  if(pf)
    8000503a:	c091                	beqz	s1,8000503e <argfd+0x50>
    *pf = f;
    8000503c:	e09c                	sd	a5,0(s1)
}
    8000503e:	70a2                	ld	ra,40(sp)
    80005040:	7402                	ld	s0,32(sp)
    80005042:	64e2                	ld	s1,24(sp)
    80005044:	6942                	ld	s2,16(sp)
    80005046:	6145                	addi	sp,sp,48
    80005048:	8082                	ret
    return -1;
    8000504a:	557d                	li	a0,-1
    8000504c:	bfcd                	j	8000503e <argfd+0x50>
    return -1;
    8000504e:	557d                	li	a0,-1
    80005050:	b7fd                	j	8000503e <argfd+0x50>
    80005052:	557d                	li	a0,-1
    80005054:	b7ed                	j	8000503e <argfd+0x50>

0000000080005056 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005056:	1101                	addi	sp,sp,-32
    80005058:	ec06                	sd	ra,24(sp)
    8000505a:	e822                	sd	s0,16(sp)
    8000505c:	e426                	sd	s1,8(sp)
    8000505e:	1000                	addi	s0,sp,32
    80005060:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005062:	ffffd097          	auipc	ra,0xffffd
    80005066:	95e080e7          	jalr	-1698(ra) # 800019c0 <myproc>
    8000506a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000506c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffde0d0>
    80005070:	4501                	li	a0,0
    80005072:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005074:	6398                	ld	a4,0(a5)
    80005076:	cb19                	beqz	a4,8000508c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005078:	2505                	addiw	a0,a0,1
    8000507a:	07a1                	addi	a5,a5,8
    8000507c:	fed51ce3          	bne	a0,a3,80005074 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005080:	557d                	li	a0,-1
}
    80005082:	60e2                	ld	ra,24(sp)
    80005084:	6442                	ld	s0,16(sp)
    80005086:	64a2                	ld	s1,8(sp)
    80005088:	6105                	addi	sp,sp,32
    8000508a:	8082                	ret
      p->ofile[fd] = f;
    8000508c:	01a50793          	addi	a5,a0,26
    80005090:	078e                	slli	a5,a5,0x3
    80005092:	963e                	add	a2,a2,a5
    80005094:	e204                	sd	s1,0(a2)
      return fd;
    80005096:	b7f5                	j	80005082 <fdalloc+0x2c>

0000000080005098 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005098:	715d                	addi	sp,sp,-80
    8000509a:	e486                	sd	ra,72(sp)
    8000509c:	e0a2                	sd	s0,64(sp)
    8000509e:	fc26                	sd	s1,56(sp)
    800050a0:	f84a                	sd	s2,48(sp)
    800050a2:	f44e                	sd	s3,40(sp)
    800050a4:	f052                	sd	s4,32(sp)
    800050a6:	ec56                	sd	s5,24(sp)
    800050a8:	0880                	addi	s0,sp,80
    800050aa:	89ae                	mv	s3,a1
    800050ac:	8ab2                	mv	s5,a2
    800050ae:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050b0:	fb040593          	addi	a1,s0,-80
    800050b4:	fffff097          	auipc	ra,0xfffff
    800050b8:	e7e080e7          	jalr	-386(ra) # 80003f32 <nameiparent>
    800050bc:	892a                	mv	s2,a0
    800050be:	12050f63          	beqz	a0,800051fc <create+0x164>
    return 0;

  ilock(dp);
    800050c2:	ffffe097          	auipc	ra,0xffffe
    800050c6:	5f4080e7          	jalr	1524(ra) # 800036b6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050ca:	4601                	li	a2,0
    800050cc:	fb040593          	addi	a1,s0,-80
    800050d0:	854a                	mv	a0,s2
    800050d2:	fffff097          	auipc	ra,0xfffff
    800050d6:	b70080e7          	jalr	-1168(ra) # 80003c42 <dirlookup>
    800050da:	84aa                	mv	s1,a0
    800050dc:	c921                	beqz	a0,8000512c <create+0x94>
    iunlockput(dp);
    800050de:	854a                	mv	a0,s2
    800050e0:	fffff097          	auipc	ra,0xfffff
    800050e4:	8de080e7          	jalr	-1826(ra) # 800039be <iunlockput>
    ilock(ip);
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffe097          	auipc	ra,0xffffe
    800050ee:	5cc080e7          	jalr	1484(ra) # 800036b6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800050f2:	2981                	sext.w	s3,s3
    800050f4:	4789                	li	a5,2
    800050f6:	02f99463          	bne	s3,a5,8000511e <create+0x86>
    800050fa:	0444d783          	lhu	a5,68(s1)
    800050fe:	37f9                	addiw	a5,a5,-2
    80005100:	17c2                	slli	a5,a5,0x30
    80005102:	93c1                	srli	a5,a5,0x30
    80005104:	4705                	li	a4,1
    80005106:	00f76c63          	bltu	a4,a5,8000511e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000510a:	8526                	mv	a0,s1
    8000510c:	60a6                	ld	ra,72(sp)
    8000510e:	6406                	ld	s0,64(sp)
    80005110:	74e2                	ld	s1,56(sp)
    80005112:	7942                	ld	s2,48(sp)
    80005114:	79a2                	ld	s3,40(sp)
    80005116:	7a02                	ld	s4,32(sp)
    80005118:	6ae2                	ld	s5,24(sp)
    8000511a:	6161                	addi	sp,sp,80
    8000511c:	8082                	ret
    iunlockput(ip);
    8000511e:	8526                	mv	a0,s1
    80005120:	fffff097          	auipc	ra,0xfffff
    80005124:	89e080e7          	jalr	-1890(ra) # 800039be <iunlockput>
    return 0;
    80005128:	4481                	li	s1,0
    8000512a:	b7c5                	j	8000510a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000512c:	85ce                	mv	a1,s3
    8000512e:	00092503          	lw	a0,0(s2)
    80005132:	ffffe097          	auipc	ra,0xffffe
    80005136:	3ec080e7          	jalr	1004(ra) # 8000351e <ialloc>
    8000513a:	84aa                	mv	s1,a0
    8000513c:	c529                	beqz	a0,80005186 <create+0xee>
  ilock(ip);
    8000513e:	ffffe097          	auipc	ra,0xffffe
    80005142:	578080e7          	jalr	1400(ra) # 800036b6 <ilock>
  ip->major = major;
    80005146:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000514a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000514e:	4785                	li	a5,1
    80005150:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005154:	8526                	mv	a0,s1
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	496080e7          	jalr	1174(ra) # 800035ec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000515e:	2981                	sext.w	s3,s3
    80005160:	4785                	li	a5,1
    80005162:	02f98a63          	beq	s3,a5,80005196 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005166:	40d0                	lw	a2,4(s1)
    80005168:	fb040593          	addi	a1,s0,-80
    8000516c:	854a                	mv	a0,s2
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	ce4080e7          	jalr	-796(ra) # 80003e52 <dirlink>
    80005176:	06054b63          	bltz	a0,800051ec <create+0x154>
  iunlockput(dp);
    8000517a:	854a                	mv	a0,s2
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	842080e7          	jalr	-1982(ra) # 800039be <iunlockput>
  return ip;
    80005184:	b759                	j	8000510a <create+0x72>
    panic("create: ialloc");
    80005186:	00003517          	auipc	a0,0x3
    8000518a:	54250513          	addi	a0,a0,1346 # 800086c8 <syscalls+0x2a8>
    8000518e:	ffffb097          	auipc	ra,0xffffb
    80005192:	3a2080e7          	jalr	930(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    80005196:	04a95783          	lhu	a5,74(s2)
    8000519a:	2785                	addiw	a5,a5,1
    8000519c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051a0:	854a                	mv	a0,s2
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	44a080e7          	jalr	1098(ra) # 800035ec <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051aa:	40d0                	lw	a2,4(s1)
    800051ac:	00003597          	auipc	a1,0x3
    800051b0:	52c58593          	addi	a1,a1,1324 # 800086d8 <syscalls+0x2b8>
    800051b4:	8526                	mv	a0,s1
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	c9c080e7          	jalr	-868(ra) # 80003e52 <dirlink>
    800051be:	00054f63          	bltz	a0,800051dc <create+0x144>
    800051c2:	00492603          	lw	a2,4(s2)
    800051c6:	00003597          	auipc	a1,0x3
    800051ca:	51a58593          	addi	a1,a1,1306 # 800086e0 <syscalls+0x2c0>
    800051ce:	8526                	mv	a0,s1
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	c82080e7          	jalr	-894(ra) # 80003e52 <dirlink>
    800051d8:	f80557e3          	bgez	a0,80005166 <create+0xce>
      panic("create dots");
    800051dc:	00003517          	auipc	a0,0x3
    800051e0:	50c50513          	addi	a0,a0,1292 # 800086e8 <syscalls+0x2c8>
    800051e4:	ffffb097          	auipc	ra,0xffffb
    800051e8:	34c080e7          	jalr	844(ra) # 80000530 <panic>
    panic("create: dirlink");
    800051ec:	00003517          	auipc	a0,0x3
    800051f0:	50c50513          	addi	a0,a0,1292 # 800086f8 <syscalls+0x2d8>
    800051f4:	ffffb097          	auipc	ra,0xffffb
    800051f8:	33c080e7          	jalr	828(ra) # 80000530 <panic>
    return 0;
    800051fc:	84aa                	mv	s1,a0
    800051fe:	b731                	j	8000510a <create+0x72>

0000000080005200 <sys_dup>:
{
    80005200:	7179                	addi	sp,sp,-48
    80005202:	f406                	sd	ra,40(sp)
    80005204:	f022                	sd	s0,32(sp)
    80005206:	ec26                	sd	s1,24(sp)
    80005208:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000520a:	fd840613          	addi	a2,s0,-40
    8000520e:	4581                	li	a1,0
    80005210:	4501                	li	a0,0
    80005212:	00000097          	auipc	ra,0x0
    80005216:	ddc080e7          	jalr	-548(ra) # 80004fee <argfd>
    return -1;
    8000521a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000521c:	02054363          	bltz	a0,80005242 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005220:	fd843503          	ld	a0,-40(s0)
    80005224:	00000097          	auipc	ra,0x0
    80005228:	e32080e7          	jalr	-462(ra) # 80005056 <fdalloc>
    8000522c:	84aa                	mv	s1,a0
    return -1;
    8000522e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005230:	00054963          	bltz	a0,80005242 <sys_dup+0x42>
  filedup(f);
    80005234:	fd843503          	ld	a0,-40(s0)
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	37a080e7          	jalr	890(ra) # 800045b2 <filedup>
  return fd;
    80005240:	87a6                	mv	a5,s1
}
    80005242:	853e                	mv	a0,a5
    80005244:	70a2                	ld	ra,40(sp)
    80005246:	7402                	ld	s0,32(sp)
    80005248:	64e2                	ld	s1,24(sp)
    8000524a:	6145                	addi	sp,sp,48
    8000524c:	8082                	ret

000000008000524e <sys_read>:
{
    8000524e:	7179                	addi	sp,sp,-48
    80005250:	f406                	sd	ra,40(sp)
    80005252:	f022                	sd	s0,32(sp)
    80005254:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005256:	fe840613          	addi	a2,s0,-24
    8000525a:	4581                	li	a1,0
    8000525c:	4501                	li	a0,0
    8000525e:	00000097          	auipc	ra,0x0
    80005262:	d90080e7          	jalr	-624(ra) # 80004fee <argfd>
    return -1;
    80005266:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005268:	04054163          	bltz	a0,800052aa <sys_read+0x5c>
    8000526c:	fe440593          	addi	a1,s0,-28
    80005270:	4509                	li	a0,2
    80005272:	ffffe097          	auipc	ra,0xffffe
    80005276:	80c080e7          	jalr	-2036(ra) # 80002a7e <argint>
    return -1;
    8000527a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000527c:	02054763          	bltz	a0,800052aa <sys_read+0x5c>
    80005280:	fd840593          	addi	a1,s0,-40
    80005284:	4505                	li	a0,1
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	81a080e7          	jalr	-2022(ra) # 80002aa0 <argaddr>
    return -1;
    8000528e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005290:	00054d63          	bltz	a0,800052aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005294:	fe442603          	lw	a2,-28(s0)
    80005298:	fd843583          	ld	a1,-40(s0)
    8000529c:	fe843503          	ld	a0,-24(s0)
    800052a0:	fffff097          	auipc	ra,0xfffff
    800052a4:	49e080e7          	jalr	1182(ra) # 8000473e <fileread>
    800052a8:	87aa                	mv	a5,a0
}
    800052aa:	853e                	mv	a0,a5
    800052ac:	70a2                	ld	ra,40(sp)
    800052ae:	7402                	ld	s0,32(sp)
    800052b0:	6145                	addi	sp,sp,48
    800052b2:	8082                	ret

00000000800052b4 <sys_write>:
{
    800052b4:	7179                	addi	sp,sp,-48
    800052b6:	f406                	sd	ra,40(sp)
    800052b8:	f022                	sd	s0,32(sp)
    800052ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052bc:	fe840613          	addi	a2,s0,-24
    800052c0:	4581                	li	a1,0
    800052c2:	4501                	li	a0,0
    800052c4:	00000097          	auipc	ra,0x0
    800052c8:	d2a080e7          	jalr	-726(ra) # 80004fee <argfd>
    return -1;
    800052cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ce:	04054163          	bltz	a0,80005310 <sys_write+0x5c>
    800052d2:	fe440593          	addi	a1,s0,-28
    800052d6:	4509                	li	a0,2
    800052d8:	ffffd097          	auipc	ra,0xffffd
    800052dc:	7a6080e7          	jalr	1958(ra) # 80002a7e <argint>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e2:	02054763          	bltz	a0,80005310 <sys_write+0x5c>
    800052e6:	fd840593          	addi	a1,s0,-40
    800052ea:	4505                	li	a0,1
    800052ec:	ffffd097          	auipc	ra,0xffffd
    800052f0:	7b4080e7          	jalr	1972(ra) # 80002aa0 <argaddr>
    return -1;
    800052f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f6:	00054d63          	bltz	a0,80005310 <sys_write+0x5c>
  return filewrite(f, p, n);
    800052fa:	fe442603          	lw	a2,-28(s0)
    800052fe:	fd843583          	ld	a1,-40(s0)
    80005302:	fe843503          	ld	a0,-24(s0)
    80005306:	fffff097          	auipc	ra,0xfffff
    8000530a:	4fa080e7          	jalr	1274(ra) # 80004800 <filewrite>
    8000530e:	87aa                	mv	a5,a0
}
    80005310:	853e                	mv	a0,a5
    80005312:	70a2                	ld	ra,40(sp)
    80005314:	7402                	ld	s0,32(sp)
    80005316:	6145                	addi	sp,sp,48
    80005318:	8082                	ret

000000008000531a <sys_close>:
{
    8000531a:	1101                	addi	sp,sp,-32
    8000531c:	ec06                	sd	ra,24(sp)
    8000531e:	e822                	sd	s0,16(sp)
    80005320:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005322:	fe040613          	addi	a2,s0,-32
    80005326:	fec40593          	addi	a1,s0,-20
    8000532a:	4501                	li	a0,0
    8000532c:	00000097          	auipc	ra,0x0
    80005330:	cc2080e7          	jalr	-830(ra) # 80004fee <argfd>
    return -1;
    80005334:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005336:	02054463          	bltz	a0,8000535e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	686080e7          	jalr	1670(ra) # 800019c0 <myproc>
    80005342:	fec42783          	lw	a5,-20(s0)
    80005346:	07e9                	addi	a5,a5,26
    80005348:	078e                	slli	a5,a5,0x3
    8000534a:	97aa                	add	a5,a5,a0
    8000534c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005350:	fe043503          	ld	a0,-32(s0)
    80005354:	fffff097          	auipc	ra,0xfffff
    80005358:	2b0080e7          	jalr	688(ra) # 80004604 <fileclose>
  return 0;
    8000535c:	4781                	li	a5,0
}
    8000535e:	853e                	mv	a0,a5
    80005360:	60e2                	ld	ra,24(sp)
    80005362:	6442                	ld	s0,16(sp)
    80005364:	6105                	addi	sp,sp,32
    80005366:	8082                	ret

0000000080005368 <sys_fstat>:
{
    80005368:	1101                	addi	sp,sp,-32
    8000536a:	ec06                	sd	ra,24(sp)
    8000536c:	e822                	sd	s0,16(sp)
    8000536e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005370:	fe840613          	addi	a2,s0,-24
    80005374:	4581                	li	a1,0
    80005376:	4501                	li	a0,0
    80005378:	00000097          	auipc	ra,0x0
    8000537c:	c76080e7          	jalr	-906(ra) # 80004fee <argfd>
    return -1;
    80005380:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005382:	02054563          	bltz	a0,800053ac <sys_fstat+0x44>
    80005386:	fe040593          	addi	a1,s0,-32
    8000538a:	4505                	li	a0,1
    8000538c:	ffffd097          	auipc	ra,0xffffd
    80005390:	714080e7          	jalr	1812(ra) # 80002aa0 <argaddr>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005396:	00054b63          	bltz	a0,800053ac <sys_fstat+0x44>
  return filestat(f, st);
    8000539a:	fe043583          	ld	a1,-32(s0)
    8000539e:	fe843503          	ld	a0,-24(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	32a080e7          	jalr	810(ra) # 800046cc <filestat>
    800053aa:	87aa                	mv	a5,a0
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	60e2                	ld	ra,24(sp)
    800053b0:	6442                	ld	s0,16(sp)
    800053b2:	6105                	addi	sp,sp,32
    800053b4:	8082                	ret

00000000800053b6 <sys_link>:
{
    800053b6:	7169                	addi	sp,sp,-304
    800053b8:	f606                	sd	ra,296(sp)
    800053ba:	f222                	sd	s0,288(sp)
    800053bc:	ee26                	sd	s1,280(sp)
    800053be:	ea4a                	sd	s2,272(sp)
    800053c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053c2:	08000613          	li	a2,128
    800053c6:	ed040593          	addi	a1,s0,-304
    800053ca:	4501                	li	a0,0
    800053cc:	ffffd097          	auipc	ra,0xffffd
    800053d0:	6f6080e7          	jalr	1782(ra) # 80002ac2 <argstr>
    return -1;
    800053d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053d6:	10054e63          	bltz	a0,800054f2 <sys_link+0x13c>
    800053da:	08000613          	li	a2,128
    800053de:	f5040593          	addi	a1,s0,-176
    800053e2:	4505                	li	a0,1
    800053e4:	ffffd097          	auipc	ra,0xffffd
    800053e8:	6de080e7          	jalr	1758(ra) # 80002ac2 <argstr>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ee:	10054263          	bltz	a0,800054f2 <sys_link+0x13c>
  begin_op();
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	d3e080e7          	jalr	-706(ra) # 80004130 <begin_op>
  if((ip = namei(old)) == 0){
    800053fa:	ed040513          	addi	a0,s0,-304
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	b16080e7          	jalr	-1258(ra) # 80003f14 <namei>
    80005406:	84aa                	mv	s1,a0
    80005408:	c551                	beqz	a0,80005494 <sys_link+0xde>
  ilock(ip);
    8000540a:	ffffe097          	auipc	ra,0xffffe
    8000540e:	2ac080e7          	jalr	684(ra) # 800036b6 <ilock>
  if(ip->type == T_DIR){
    80005412:	04449703          	lh	a4,68(s1)
    80005416:	4785                	li	a5,1
    80005418:	08f70463          	beq	a4,a5,800054a0 <sys_link+0xea>
  ip->nlink++;
    8000541c:	04a4d783          	lhu	a5,74(s1)
    80005420:	2785                	addiw	a5,a5,1
    80005422:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	1c4080e7          	jalr	452(ra) # 800035ec <iupdate>
  iunlock(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	346080e7          	jalr	838(ra) # 80003778 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000543a:	fd040593          	addi	a1,s0,-48
    8000543e:	f5040513          	addi	a0,s0,-176
    80005442:	fffff097          	auipc	ra,0xfffff
    80005446:	af0080e7          	jalr	-1296(ra) # 80003f32 <nameiparent>
    8000544a:	892a                	mv	s2,a0
    8000544c:	c935                	beqz	a0,800054c0 <sys_link+0x10a>
  ilock(dp);
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	268080e7          	jalr	616(ra) # 800036b6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005456:	00092703          	lw	a4,0(s2)
    8000545a:	409c                	lw	a5,0(s1)
    8000545c:	04f71d63          	bne	a4,a5,800054b6 <sys_link+0x100>
    80005460:	40d0                	lw	a2,4(s1)
    80005462:	fd040593          	addi	a1,s0,-48
    80005466:	854a                	mv	a0,s2
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	9ea080e7          	jalr	-1558(ra) # 80003e52 <dirlink>
    80005470:	04054363          	bltz	a0,800054b6 <sys_link+0x100>
  iunlockput(dp);
    80005474:	854a                	mv	a0,s2
    80005476:	ffffe097          	auipc	ra,0xffffe
    8000547a:	548080e7          	jalr	1352(ra) # 800039be <iunlockput>
  iput(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	496080e7          	jalr	1174(ra) # 80003916 <iput>
  end_op();
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	d28080e7          	jalr	-728(ra) # 800041b0 <end_op>
  return 0;
    80005490:	4781                	li	a5,0
    80005492:	a085                	j	800054f2 <sys_link+0x13c>
    end_op();
    80005494:	fffff097          	auipc	ra,0xfffff
    80005498:	d1c080e7          	jalr	-740(ra) # 800041b0 <end_op>
    return -1;
    8000549c:	57fd                	li	a5,-1
    8000549e:	a891                	j	800054f2 <sys_link+0x13c>
    iunlockput(ip);
    800054a0:	8526                	mv	a0,s1
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	51c080e7          	jalr	1308(ra) # 800039be <iunlockput>
    end_op();
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	d06080e7          	jalr	-762(ra) # 800041b0 <end_op>
    return -1;
    800054b2:	57fd                	li	a5,-1
    800054b4:	a83d                	j	800054f2 <sys_link+0x13c>
    iunlockput(dp);
    800054b6:	854a                	mv	a0,s2
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	506080e7          	jalr	1286(ra) # 800039be <iunlockput>
  ilock(ip);
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	1f4080e7          	jalr	500(ra) # 800036b6 <ilock>
  ip->nlink--;
    800054ca:	04a4d783          	lhu	a5,74(s1)
    800054ce:	37fd                	addiw	a5,a5,-1
    800054d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	116080e7          	jalr	278(ra) # 800035ec <iupdate>
  iunlockput(ip);
    800054de:	8526                	mv	a0,s1
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	4de080e7          	jalr	1246(ra) # 800039be <iunlockput>
  end_op();
    800054e8:	fffff097          	auipc	ra,0xfffff
    800054ec:	cc8080e7          	jalr	-824(ra) # 800041b0 <end_op>
  return -1;
    800054f0:	57fd                	li	a5,-1
}
    800054f2:	853e                	mv	a0,a5
    800054f4:	70b2                	ld	ra,296(sp)
    800054f6:	7412                	ld	s0,288(sp)
    800054f8:	64f2                	ld	s1,280(sp)
    800054fa:	6952                	ld	s2,272(sp)
    800054fc:	6155                	addi	sp,sp,304
    800054fe:	8082                	ret

0000000080005500 <sys_unlink>:
{
    80005500:	7151                	addi	sp,sp,-240
    80005502:	f586                	sd	ra,232(sp)
    80005504:	f1a2                	sd	s0,224(sp)
    80005506:	eda6                	sd	s1,216(sp)
    80005508:	e9ca                	sd	s2,208(sp)
    8000550a:	e5ce                	sd	s3,200(sp)
    8000550c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000550e:	08000613          	li	a2,128
    80005512:	f3040593          	addi	a1,s0,-208
    80005516:	4501                	li	a0,0
    80005518:	ffffd097          	auipc	ra,0xffffd
    8000551c:	5aa080e7          	jalr	1450(ra) # 80002ac2 <argstr>
    80005520:	18054163          	bltz	a0,800056a2 <sys_unlink+0x1a2>
  begin_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	c0c080e7          	jalr	-1012(ra) # 80004130 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000552c:	fb040593          	addi	a1,s0,-80
    80005530:	f3040513          	addi	a0,s0,-208
    80005534:	fffff097          	auipc	ra,0xfffff
    80005538:	9fe080e7          	jalr	-1538(ra) # 80003f32 <nameiparent>
    8000553c:	84aa                	mv	s1,a0
    8000553e:	c979                	beqz	a0,80005614 <sys_unlink+0x114>
  ilock(dp);
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	176080e7          	jalr	374(ra) # 800036b6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005548:	00003597          	auipc	a1,0x3
    8000554c:	19058593          	addi	a1,a1,400 # 800086d8 <syscalls+0x2b8>
    80005550:	fb040513          	addi	a0,s0,-80
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	6d4080e7          	jalr	1748(ra) # 80003c28 <namecmp>
    8000555c:	14050a63          	beqz	a0,800056b0 <sys_unlink+0x1b0>
    80005560:	00003597          	auipc	a1,0x3
    80005564:	18058593          	addi	a1,a1,384 # 800086e0 <syscalls+0x2c0>
    80005568:	fb040513          	addi	a0,s0,-80
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	6bc080e7          	jalr	1724(ra) # 80003c28 <namecmp>
    80005574:	12050e63          	beqz	a0,800056b0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005578:	f2c40613          	addi	a2,s0,-212
    8000557c:	fb040593          	addi	a1,s0,-80
    80005580:	8526                	mv	a0,s1
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	6c0080e7          	jalr	1728(ra) # 80003c42 <dirlookup>
    8000558a:	892a                	mv	s2,a0
    8000558c:	12050263          	beqz	a0,800056b0 <sys_unlink+0x1b0>
  ilock(ip);
    80005590:	ffffe097          	auipc	ra,0xffffe
    80005594:	126080e7          	jalr	294(ra) # 800036b6 <ilock>
  if(ip->nlink < 1)
    80005598:	04a91783          	lh	a5,74(s2)
    8000559c:	08f05263          	blez	a5,80005620 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055a0:	04491703          	lh	a4,68(s2)
    800055a4:	4785                	li	a5,1
    800055a6:	08f70563          	beq	a4,a5,80005630 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055aa:	4641                	li	a2,16
    800055ac:	4581                	li	a1,0
    800055ae:	fc040513          	addi	a0,s0,-64
    800055b2:	ffffb097          	auipc	ra,0xffffb
    800055b6:	720080e7          	jalr	1824(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055ba:	4741                	li	a4,16
    800055bc:	f2c42683          	lw	a3,-212(s0)
    800055c0:	fc040613          	addi	a2,s0,-64
    800055c4:	4581                	li	a1,0
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	540080e7          	jalr	1344(ra) # 80003b08 <writei>
    800055d0:	47c1                	li	a5,16
    800055d2:	0af51563          	bne	a0,a5,8000567c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055d6:	04491703          	lh	a4,68(s2)
    800055da:	4785                	li	a5,1
    800055dc:	0af70863          	beq	a4,a5,8000568c <sys_unlink+0x18c>
  iunlockput(dp);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	3dc080e7          	jalr	988(ra) # 800039be <iunlockput>
  ip->nlink--;
    800055ea:	04a95783          	lhu	a5,74(s2)
    800055ee:	37fd                	addiw	a5,a5,-1
    800055f0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800055f4:	854a                	mv	a0,s2
    800055f6:	ffffe097          	auipc	ra,0xffffe
    800055fa:	ff6080e7          	jalr	-10(ra) # 800035ec <iupdate>
  iunlockput(ip);
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	3be080e7          	jalr	958(ra) # 800039be <iunlockput>
  end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	ba8080e7          	jalr	-1112(ra) # 800041b0 <end_op>
  return 0;
    80005610:	4501                	li	a0,0
    80005612:	a84d                	j	800056c4 <sys_unlink+0x1c4>
    end_op();
    80005614:	fffff097          	auipc	ra,0xfffff
    80005618:	b9c080e7          	jalr	-1124(ra) # 800041b0 <end_op>
    return -1;
    8000561c:	557d                	li	a0,-1
    8000561e:	a05d                	j	800056c4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005620:	00003517          	auipc	a0,0x3
    80005624:	0e850513          	addi	a0,a0,232 # 80008708 <syscalls+0x2e8>
    80005628:	ffffb097          	auipc	ra,0xffffb
    8000562c:	f08080e7          	jalr	-248(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005630:	04c92703          	lw	a4,76(s2)
    80005634:	02000793          	li	a5,32
    80005638:	f6e7f9e3          	bgeu	a5,a4,800055aa <sys_unlink+0xaa>
    8000563c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005640:	4741                	li	a4,16
    80005642:	86ce                	mv	a3,s3
    80005644:	f1840613          	addi	a2,s0,-232
    80005648:	4581                	li	a1,0
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	3c4080e7          	jalr	964(ra) # 80003a10 <readi>
    80005654:	47c1                	li	a5,16
    80005656:	00f51b63          	bne	a0,a5,8000566c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000565a:	f1845783          	lhu	a5,-232(s0)
    8000565e:	e7a1                	bnez	a5,800056a6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005660:	29c1                	addiw	s3,s3,16
    80005662:	04c92783          	lw	a5,76(s2)
    80005666:	fcf9ede3          	bltu	s3,a5,80005640 <sys_unlink+0x140>
    8000566a:	b781                	j	800055aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000566c:	00003517          	auipc	a0,0x3
    80005670:	0b450513          	addi	a0,a0,180 # 80008720 <syscalls+0x300>
    80005674:	ffffb097          	auipc	ra,0xffffb
    80005678:	ebc080e7          	jalr	-324(ra) # 80000530 <panic>
    panic("unlink: writei");
    8000567c:	00003517          	auipc	a0,0x3
    80005680:	0bc50513          	addi	a0,a0,188 # 80008738 <syscalls+0x318>
    80005684:	ffffb097          	auipc	ra,0xffffb
    80005688:	eac080e7          	jalr	-340(ra) # 80000530 <panic>
    dp->nlink--;
    8000568c:	04a4d783          	lhu	a5,74(s1)
    80005690:	37fd                	addiw	a5,a5,-1
    80005692:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005696:	8526                	mv	a0,s1
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	f54080e7          	jalr	-172(ra) # 800035ec <iupdate>
    800056a0:	b781                	j	800055e0 <sys_unlink+0xe0>
    return -1;
    800056a2:	557d                	li	a0,-1
    800056a4:	a005                	j	800056c4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056a6:	854a                	mv	a0,s2
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	316080e7          	jalr	790(ra) # 800039be <iunlockput>
  iunlockput(dp);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	30c080e7          	jalr	780(ra) # 800039be <iunlockput>
  end_op();
    800056ba:	fffff097          	auipc	ra,0xfffff
    800056be:	af6080e7          	jalr	-1290(ra) # 800041b0 <end_op>
  return -1;
    800056c2:	557d                	li	a0,-1
}
    800056c4:	70ae                	ld	ra,232(sp)
    800056c6:	740e                	ld	s0,224(sp)
    800056c8:	64ee                	ld	s1,216(sp)
    800056ca:	694e                	ld	s2,208(sp)
    800056cc:	69ae                	ld	s3,200(sp)
    800056ce:	616d                	addi	sp,sp,240
    800056d0:	8082                	ret

00000000800056d2 <sys_open>:

uint64
sys_open(void)
{
    800056d2:	7131                	addi	sp,sp,-192
    800056d4:	fd06                	sd	ra,184(sp)
    800056d6:	f922                	sd	s0,176(sp)
    800056d8:	f526                	sd	s1,168(sp)
    800056da:	f14a                	sd	s2,160(sp)
    800056dc:	ed4e                	sd	s3,152(sp)
    800056de:	e952                	sd	s4,144(sp)
    800056e0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056e2:	08000613          	li	a2,128
    800056e6:	f5040593          	addi	a1,s0,-176
    800056ea:	4501                	li	a0,0
    800056ec:	ffffd097          	auipc	ra,0xffffd
    800056f0:	3d6080e7          	jalr	982(ra) # 80002ac2 <argstr>
    return -1;
    800056f4:	597d                	li	s2,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f6:	14054a63          	bltz	a0,8000584a <sys_open+0x178>
    800056fa:	f4c40593          	addi	a1,s0,-180
    800056fe:	4505                	li	a0,1
    80005700:	ffffd097          	auipc	ra,0xffffd
    80005704:	37e080e7          	jalr	894(ra) # 80002a7e <argint>
    80005708:	14054163          	bltz	a0,8000584a <sys_open+0x178>

  begin_op();
    8000570c:	fffff097          	auipc	ra,0xfffff
    80005710:	a24080e7          	jalr	-1500(ra) # 80004130 <begin_op>

  if(omode & O_CREATE){
    80005714:	f4c42783          	lw	a5,-180(s0)
    80005718:	2007f793          	andi	a5,a5,512
    8000571c:	492d                	li	s2,11
    8000571e:	e3b5                	bnez	a5,80005782 <sys_open+0xb0>
      if((ip = namei(path)) == 0){
        end_op();
        return -1;
      }
      ilock(ip);
      if(ip->type == T_SYMLINK && (omode & O_NOFOLLOW) == 0) {
    80005720:	4a11                	li	s4,4
    80005722:	6985                	lui	s3,0x1
    80005724:	80098993          	addi	s3,s3,-2048 # 800 <_entry-0x7ffff800>
      if((ip = namei(path)) == 0){
    80005728:	f5040513          	addi	a0,s0,-176
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	7e8080e7          	jalr	2024(ra) # 80003f14 <namei>
    80005734:	84aa                	mv	s1,a0
    80005736:	c975                	beqz	a0,8000582a <sys_open+0x158>
      ilock(ip);
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	f7e080e7          	jalr	-130(ra) # 800036b6 <ilock>
      if(ip->type == T_SYMLINK && (omode & O_NOFOLLOW) == 0) {
    80005740:	04449783          	lh	a5,68(s1)
    80005744:	0007871b          	sext.w	a4,a5
    80005748:	13471563          	bne	a4,s4,80005872 <sys_open+0x1a0>
    8000574c:	f4c42783          	lw	a5,-180(s0)
    80005750:	00f9f7b3          	and	a5,s3,a5
    80005754:	efa1                	bnez	a5,800057ac <sys_open+0xda>
        if(++symlink_depth > 10) {
    80005756:	397d                	addiw	s2,s2,-1
    80005758:	0c090f63          	beqz	s2,80005836 <sys_open+0x164>
          // too many layer of symlinks, might be a loop
          iunlockput(ip);
          end_op();
          return -1;
        }
        if(readi(ip, 0, (uint64)path, 0, MAXPATH) < 0) {
    8000575c:	08000713          	li	a4,128
    80005760:	4681                	li	a3,0
    80005762:	f5040613          	addi	a2,s0,-176
    80005766:	4581                	li	a1,0
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	2a6080e7          	jalr	678(ra) # 80003a10 <readi>
    80005772:	0e054563          	bltz	a0,8000585c <sys_open+0x18a>
          iunlockput(ip);
          end_op();
          return -1;
        }
        iunlockput(ip);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	246080e7          	jalr	582(ra) # 800039be <iunlockput>
      if((ip = namei(path)) == 0){
    80005780:	b765                	j	80005728 <sys_open+0x56>
    ip = create(path, T_FILE, 0, 0);
    80005782:	4681                	li	a3,0
    80005784:	4601                	li	a2,0
    80005786:	4589                	li	a1,2
    80005788:	f5040513          	addi	a0,s0,-176
    8000578c:	00000097          	auipc	ra,0x0
    80005790:	90c080e7          	jalr	-1780(ra) # 80005098 <create>
    80005794:	84aa                	mv	s1,a0
    if(ip == 0){
    80005796:	c541                	beqz	a0,8000581e <sys_open+0x14c>
  //     end_op();
  //     return -1;
  //   }
  // }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005798:	04449703          	lh	a4,68(s1)
    8000579c:	478d                	li	a5,3
    8000579e:	00f71763          	bne	a4,a5,800057ac <sys_open+0xda>
    800057a2:	0464d703          	lhu	a4,70(s1)
    800057a6:	47a5                	li	a5,9
    800057a8:	0ee7e763          	bltu	a5,a4,80005896 <sys_open+0x1c4>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	d9c080e7          	jalr	-612(ra) # 80004548 <filealloc>
    800057b4:	89aa                	mv	s3,a0
    800057b6:	10050d63          	beqz	a0,800058d0 <sys_open+0x1fe>
    800057ba:	00000097          	auipc	ra,0x0
    800057be:	89c080e7          	jalr	-1892(ra) # 80005056 <fdalloc>
    800057c2:	892a                	mv	s2,a0
    800057c4:	10054163          	bltz	a0,800058c6 <sys_open+0x1f4>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057c8:	04449703          	lh	a4,68(s1)
    800057cc:	478d                	li	a5,3
    800057ce:	0cf70f63          	beq	a4,a5,800058ac <sys_open+0x1da>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d2:	4789                	li	a5,2
    800057d4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057d8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057dc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057e0:	f4c42783          	lw	a5,-180(s0)
    800057e4:	0017c713          	xori	a4,a5,1
    800057e8:	8b05                	andi	a4,a4,1
    800057ea:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ee:	0037f713          	andi	a4,a5,3
    800057f2:	00e03733          	snez	a4,a4
    800057f6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057fa:	4007f793          	andi	a5,a5,1024
    800057fe:	c791                	beqz	a5,8000580a <sys_open+0x138>
    80005800:	04449703          	lh	a4,68(s1)
    80005804:	4789                	li	a5,2
    80005806:	0af70a63          	beq	a4,a5,800058ba <sys_open+0x1e8>
    itrunc(ip);
  }

  iunlock(ip);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	f6c080e7          	jalr	-148(ra) # 80003778 <iunlock>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	99c080e7          	jalr	-1636(ra) # 800041b0 <end_op>

  return fd;
    8000581c:	a03d                	j	8000584a <sys_open+0x178>
      end_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	992080e7          	jalr	-1646(ra) # 800041b0 <end_op>
      return -1;
    80005826:	597d                	li	s2,-1
    80005828:	a00d                	j	8000584a <sys_open+0x178>
        end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	986080e7          	jalr	-1658(ra) # 800041b0 <end_op>
        return -1;
    80005832:	597d                	li	s2,-1
    80005834:	a819                	j	8000584a <sys_open+0x178>
          iunlockput(ip);
    80005836:	8526                	mv	a0,s1
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	186080e7          	jalr	390(ra) # 800039be <iunlockput>
          end_op();
    80005840:	fffff097          	auipc	ra,0xfffff
    80005844:	970080e7          	jalr	-1680(ra) # 800041b0 <end_op>
          return -1;
    80005848:	597d                	li	s2,-1
}
    8000584a:	854a                	mv	a0,s2
    8000584c:	70ea                	ld	ra,184(sp)
    8000584e:	744a                	ld	s0,176(sp)
    80005850:	74aa                	ld	s1,168(sp)
    80005852:	790a                	ld	s2,160(sp)
    80005854:	69ea                	ld	s3,152(sp)
    80005856:	6a4a                	ld	s4,144(sp)
    80005858:	6129                	addi	sp,sp,192
    8000585a:	8082                	ret
          iunlockput(ip);
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	160080e7          	jalr	352(ra) # 800039be <iunlockput>
          end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	94a080e7          	jalr	-1718(ra) # 800041b0 <end_op>
          return -1;
    8000586e:	597d                	li	s2,-1
    80005870:	bfe9                	j	8000584a <sys_open+0x178>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005872:	2781                	sext.w	a5,a5
    80005874:	4705                	li	a4,1
    80005876:	f2e791e3          	bne	a5,a4,80005798 <sys_open+0xc6>
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	d79d                	beqz	a5,800057ac <sys_open+0xda>
      iunlockput(ip);
    80005880:	8526                	mv	a0,s1
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	13c080e7          	jalr	316(ra) # 800039be <iunlockput>
      end_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	926080e7          	jalr	-1754(ra) # 800041b0 <end_op>
      return -1;
    80005892:	597d                	li	s2,-1
    80005894:	bf5d                	j	8000584a <sys_open+0x178>
    iunlockput(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	126080e7          	jalr	294(ra) # 800039be <iunlockput>
    end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	910080e7          	jalr	-1776(ra) # 800041b0 <end_op>
    return -1;
    800058a8:	597d                	li	s2,-1
    800058aa:	b745                	j	8000584a <sys_open+0x178>
    f->type = FD_DEVICE;
    800058ac:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058b0:	04649783          	lh	a5,70(s1)
    800058b4:	02f99223          	sh	a5,36(s3)
    800058b8:	b715                	j	800057dc <sys_open+0x10a>
    itrunc(ip);
    800058ba:	8526                	mv	a0,s1
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	f08080e7          	jalr	-248(ra) # 800037c4 <itrunc>
    800058c4:	b799                	j	8000580a <sys_open+0x138>
      fileclose(f);
    800058c6:	854e                	mv	a0,s3
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	d3c080e7          	jalr	-708(ra) # 80004604 <fileclose>
    iunlockput(ip);
    800058d0:	8526                	mv	a0,s1
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	0ec080e7          	jalr	236(ra) # 800039be <iunlockput>
    end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	8d6080e7          	jalr	-1834(ra) # 800041b0 <end_op>
    return -1;
    800058e2:	597d                	li	s2,-1
    800058e4:	b79d                	j	8000584a <sys_open+0x178>

00000000800058e6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058e6:	7175                	addi	sp,sp,-144
    800058e8:	e506                	sd	ra,136(sp)
    800058ea:	e122                	sd	s0,128(sp)
    800058ec:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	842080e7          	jalr	-1982(ra) # 80004130 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058f6:	08000613          	li	a2,128
    800058fa:	f7040593          	addi	a1,s0,-144
    800058fe:	4501                	li	a0,0
    80005900:	ffffd097          	auipc	ra,0xffffd
    80005904:	1c2080e7          	jalr	450(ra) # 80002ac2 <argstr>
    80005908:	02054963          	bltz	a0,8000593a <sys_mkdir+0x54>
    8000590c:	4681                	li	a3,0
    8000590e:	4601                	li	a2,0
    80005910:	4585                	li	a1,1
    80005912:	f7040513          	addi	a0,s0,-144
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	782080e7          	jalr	1922(ra) # 80005098 <create>
    8000591e:	cd11                	beqz	a0,8000593a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	09e080e7          	jalr	158(ra) # 800039be <iunlockput>
  end_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	888080e7          	jalr	-1912(ra) # 800041b0 <end_op>
  return 0;
    80005930:	4501                	li	a0,0
}
    80005932:	60aa                	ld	ra,136(sp)
    80005934:	640a                	ld	s0,128(sp)
    80005936:	6149                	addi	sp,sp,144
    80005938:	8082                	ret
    end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	876080e7          	jalr	-1930(ra) # 800041b0 <end_op>
    return -1;
    80005942:	557d                	li	a0,-1
    80005944:	b7fd                	j	80005932 <sys_mkdir+0x4c>

0000000080005946 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005946:	7135                	addi	sp,sp,-160
    80005948:	ed06                	sd	ra,152(sp)
    8000594a:	e922                	sd	s0,144(sp)
    8000594c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	7e2080e7          	jalr	2018(ra) # 80004130 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005956:	08000613          	li	a2,128
    8000595a:	f7040593          	addi	a1,s0,-144
    8000595e:	4501                	li	a0,0
    80005960:	ffffd097          	auipc	ra,0xffffd
    80005964:	162080e7          	jalr	354(ra) # 80002ac2 <argstr>
    80005968:	04054a63          	bltz	a0,800059bc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000596c:	f6c40593          	addi	a1,s0,-148
    80005970:	4505                	li	a0,1
    80005972:	ffffd097          	auipc	ra,0xffffd
    80005976:	10c080e7          	jalr	268(ra) # 80002a7e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597a:	04054163          	bltz	a0,800059bc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000597e:	f6840593          	addi	a1,s0,-152
    80005982:	4509                	li	a0,2
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	0fa080e7          	jalr	250(ra) # 80002a7e <argint>
     argint(1, &major) < 0 ||
    8000598c:	02054863          	bltz	a0,800059bc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005990:	f6841683          	lh	a3,-152(s0)
    80005994:	f6c41603          	lh	a2,-148(s0)
    80005998:	458d                	li	a1,3
    8000599a:	f7040513          	addi	a0,s0,-144
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	6fa080e7          	jalr	1786(ra) # 80005098 <create>
     argint(2, &minor) < 0 ||
    800059a6:	c919                	beqz	a0,800059bc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a8:	ffffe097          	auipc	ra,0xffffe
    800059ac:	016080e7          	jalr	22(ra) # 800039be <iunlockput>
  end_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	800080e7          	jalr	-2048(ra) # 800041b0 <end_op>
  return 0;
    800059b8:	4501                	li	a0,0
    800059ba:	a031                	j	800059c6 <sys_mknod+0x80>
    end_op();
    800059bc:	ffffe097          	auipc	ra,0xffffe
    800059c0:	7f4080e7          	jalr	2036(ra) # 800041b0 <end_op>
    return -1;
    800059c4:	557d                	li	a0,-1
}
    800059c6:	60ea                	ld	ra,152(sp)
    800059c8:	644a                	ld	s0,144(sp)
    800059ca:	610d                	addi	sp,sp,160
    800059cc:	8082                	ret

00000000800059ce <sys_chdir>:

uint64
sys_chdir(void)
{
    800059ce:	7135                	addi	sp,sp,-160
    800059d0:	ed06                	sd	ra,152(sp)
    800059d2:	e922                	sd	s0,144(sp)
    800059d4:	e526                	sd	s1,136(sp)
    800059d6:	e14a                	sd	s2,128(sp)
    800059d8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059da:	ffffc097          	auipc	ra,0xffffc
    800059de:	fe6080e7          	jalr	-26(ra) # 800019c0 <myproc>
    800059e2:	892a                	mv	s2,a0
  
  begin_op();
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	74c080e7          	jalr	1868(ra) # 80004130 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059ec:	08000613          	li	a2,128
    800059f0:	f6040593          	addi	a1,s0,-160
    800059f4:	4501                	li	a0,0
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	0cc080e7          	jalr	204(ra) # 80002ac2 <argstr>
    800059fe:	04054b63          	bltz	a0,80005a54 <sys_chdir+0x86>
    80005a02:	f6040513          	addi	a0,s0,-160
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	50e080e7          	jalr	1294(ra) # 80003f14 <namei>
    80005a0e:	84aa                	mv	s1,a0
    80005a10:	c131                	beqz	a0,80005a54 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	ca4080e7          	jalr	-860(ra) # 800036b6 <ilock>
  if(ip->type != T_DIR){
    80005a1a:	04449703          	lh	a4,68(s1)
    80005a1e:	4785                	li	a5,1
    80005a20:	04f71063          	bne	a4,a5,80005a60 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a24:	8526                	mv	a0,s1
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	d52080e7          	jalr	-686(ra) # 80003778 <iunlock>
  iput(p->cwd);
    80005a2e:	15093503          	ld	a0,336(s2)
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	ee4080e7          	jalr	-284(ra) # 80003916 <iput>
  end_op();
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	776080e7          	jalr	1910(ra) # 800041b0 <end_op>
  p->cwd = ip;
    80005a42:	14993823          	sd	s1,336(s2)
  return 0;
    80005a46:	4501                	li	a0,0
}
    80005a48:	60ea                	ld	ra,152(sp)
    80005a4a:	644a                	ld	s0,144(sp)
    80005a4c:	64aa                	ld	s1,136(sp)
    80005a4e:	690a                	ld	s2,128(sp)
    80005a50:	610d                	addi	sp,sp,160
    80005a52:	8082                	ret
    end_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	75c080e7          	jalr	1884(ra) # 800041b0 <end_op>
    return -1;
    80005a5c:	557d                	li	a0,-1
    80005a5e:	b7ed                	j	80005a48 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	f5c080e7          	jalr	-164(ra) # 800039be <iunlockput>
    end_op();
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	746080e7          	jalr	1862(ra) # 800041b0 <end_op>
    return -1;
    80005a72:	557d                	li	a0,-1
    80005a74:	bfd1                	j	80005a48 <sys_chdir+0x7a>

0000000080005a76 <sys_exec>:

uint64
sys_exec(void)
{
    80005a76:	7145                	addi	sp,sp,-464
    80005a78:	e786                	sd	ra,456(sp)
    80005a7a:	e3a2                	sd	s0,448(sp)
    80005a7c:	ff26                	sd	s1,440(sp)
    80005a7e:	fb4a                	sd	s2,432(sp)
    80005a80:	f74e                	sd	s3,424(sp)
    80005a82:	f352                	sd	s4,416(sp)
    80005a84:	ef56                	sd	s5,408(sp)
    80005a86:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a88:	08000613          	li	a2,128
    80005a8c:	f4040593          	addi	a1,s0,-192
    80005a90:	4501                	li	a0,0
    80005a92:	ffffd097          	auipc	ra,0xffffd
    80005a96:	030080e7          	jalr	48(ra) # 80002ac2 <argstr>
    return -1;
    80005a9a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a9c:	0c054a63          	bltz	a0,80005b70 <sys_exec+0xfa>
    80005aa0:	e3840593          	addi	a1,s0,-456
    80005aa4:	4505                	li	a0,1
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	ffa080e7          	jalr	-6(ra) # 80002aa0 <argaddr>
    80005aae:	0c054163          	bltz	a0,80005b70 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ab2:	10000613          	li	a2,256
    80005ab6:	4581                	li	a1,0
    80005ab8:	e4040513          	addi	a0,s0,-448
    80005abc:	ffffb097          	auipc	ra,0xffffb
    80005ac0:	216080e7          	jalr	534(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ac4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ac8:	89a6                	mv	s3,s1
    80005aca:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005acc:	02000a13          	li	s4,32
    80005ad0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ad4:	00391513          	slli	a0,s2,0x3
    80005ad8:	e3040593          	addi	a1,s0,-464
    80005adc:	e3843783          	ld	a5,-456(s0)
    80005ae0:	953e                	add	a0,a0,a5
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	f02080e7          	jalr	-254(ra) # 800029e4 <fetchaddr>
    80005aea:	02054a63          	bltz	a0,80005b1e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aee:	e3043783          	ld	a5,-464(s0)
    80005af2:	c3b9                	beqz	a5,80005b38 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	ff2080e7          	jalr	-14(ra) # 80000ae6 <kalloc>
    80005afc:	85aa                	mv	a1,a0
    80005afe:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b02:	cd11                	beqz	a0,80005b1e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b04:	6605                	lui	a2,0x1
    80005b06:	e3043503          	ld	a0,-464(s0)
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	f2c080e7          	jalr	-212(ra) # 80002a36 <fetchstr>
    80005b12:	00054663          	bltz	a0,80005b1e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b16:	0905                	addi	s2,s2,1
    80005b18:	09a1                	addi	s3,s3,8
    80005b1a:	fb491be3          	bne	s2,s4,80005ad0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1e:	10048913          	addi	s2,s1,256
    80005b22:	6088                	ld	a0,0(s1)
    80005b24:	c529                	beqz	a0,80005b6e <sys_exec+0xf8>
    kfree(argv[i]);
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	ec4080e7          	jalr	-316(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2e:	04a1                	addi	s1,s1,8
    80005b30:	ff2499e3          	bne	s1,s2,80005b22 <sys_exec+0xac>
  return -1;
    80005b34:	597d                	li	s2,-1
    80005b36:	a82d                	j	80005b70 <sys_exec+0xfa>
      argv[i] = 0;
    80005b38:	0a8e                	slli	s5,s5,0x3
    80005b3a:	fc040793          	addi	a5,s0,-64
    80005b3e:	9abe                	add	s5,s5,a5
    80005b40:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b44:	e4040593          	addi	a1,s0,-448
    80005b48:	f4040513          	addi	a0,s0,-192
    80005b4c:	fffff097          	auipc	ra,0xfffff
    80005b50:	118080e7          	jalr	280(ra) # 80004c64 <exec>
    80005b54:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b56:	10048993          	addi	s3,s1,256
    80005b5a:	6088                	ld	a0,0(s1)
    80005b5c:	c911                	beqz	a0,80005b70 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b5e:	ffffb097          	auipc	ra,0xffffb
    80005b62:	e8c080e7          	jalr	-372(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b66:	04a1                	addi	s1,s1,8
    80005b68:	ff3499e3          	bne	s1,s3,80005b5a <sys_exec+0xe4>
    80005b6c:	a011                	j	80005b70 <sys_exec+0xfa>
  return -1;
    80005b6e:	597d                	li	s2,-1
}
    80005b70:	854a                	mv	a0,s2
    80005b72:	60be                	ld	ra,456(sp)
    80005b74:	641e                	ld	s0,448(sp)
    80005b76:	74fa                	ld	s1,440(sp)
    80005b78:	795a                	ld	s2,432(sp)
    80005b7a:	79ba                	ld	s3,424(sp)
    80005b7c:	7a1a                	ld	s4,416(sp)
    80005b7e:	6afa                	ld	s5,408(sp)
    80005b80:	6179                	addi	sp,sp,464
    80005b82:	8082                	ret

0000000080005b84 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b84:	7139                	addi	sp,sp,-64
    80005b86:	fc06                	sd	ra,56(sp)
    80005b88:	f822                	sd	s0,48(sp)
    80005b8a:	f426                	sd	s1,40(sp)
    80005b8c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b8e:	ffffc097          	auipc	ra,0xffffc
    80005b92:	e32080e7          	jalr	-462(ra) # 800019c0 <myproc>
    80005b96:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b98:	fd840593          	addi	a1,s0,-40
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	f02080e7          	jalr	-254(ra) # 80002aa0 <argaddr>
    return -1;
    80005ba6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005ba8:	0e054063          	bltz	a0,80005c88 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bac:	fc840593          	addi	a1,s0,-56
    80005bb0:	fd040513          	addi	a0,s0,-48
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	d80080e7          	jalr	-640(ra) # 80004934 <pipealloc>
    return -1;
    80005bbc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bbe:	0c054563          	bltz	a0,80005c88 <sys_pipe+0x104>
  fd0 = -1;
    80005bc2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bc6:	fd043503          	ld	a0,-48(s0)
    80005bca:	fffff097          	auipc	ra,0xfffff
    80005bce:	48c080e7          	jalr	1164(ra) # 80005056 <fdalloc>
    80005bd2:	fca42223          	sw	a0,-60(s0)
    80005bd6:	08054c63          	bltz	a0,80005c6e <sys_pipe+0xea>
    80005bda:	fc843503          	ld	a0,-56(s0)
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	478080e7          	jalr	1144(ra) # 80005056 <fdalloc>
    80005be6:	fca42023          	sw	a0,-64(s0)
    80005bea:	06054863          	bltz	a0,80005c5a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bee:	4691                	li	a3,4
    80005bf0:	fc440613          	addi	a2,s0,-60
    80005bf4:	fd843583          	ld	a1,-40(s0)
    80005bf8:	68a8                	ld	a0,80(s1)
    80005bfa:	ffffc097          	auipc	ra,0xffffc
    80005bfe:	a5c080e7          	jalr	-1444(ra) # 80001656 <copyout>
    80005c02:	02054063          	bltz	a0,80005c22 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c06:	4691                	li	a3,4
    80005c08:	fc040613          	addi	a2,s0,-64
    80005c0c:	fd843583          	ld	a1,-40(s0)
    80005c10:	0591                	addi	a1,a1,4
    80005c12:	68a8                	ld	a0,80(s1)
    80005c14:	ffffc097          	auipc	ra,0xffffc
    80005c18:	a42080e7          	jalr	-1470(ra) # 80001656 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c1c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c1e:	06055563          	bgez	a0,80005c88 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c22:	fc442783          	lw	a5,-60(s0)
    80005c26:	07e9                	addi	a5,a5,26
    80005c28:	078e                	slli	a5,a5,0x3
    80005c2a:	97a6                	add	a5,a5,s1
    80005c2c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c30:	fc042503          	lw	a0,-64(s0)
    80005c34:	0569                	addi	a0,a0,26
    80005c36:	050e                	slli	a0,a0,0x3
    80005c38:	9526                	add	a0,a0,s1
    80005c3a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c3e:	fd043503          	ld	a0,-48(s0)
    80005c42:	fffff097          	auipc	ra,0xfffff
    80005c46:	9c2080e7          	jalr	-1598(ra) # 80004604 <fileclose>
    fileclose(wf);
    80005c4a:	fc843503          	ld	a0,-56(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	9b6080e7          	jalr	-1610(ra) # 80004604 <fileclose>
    return -1;
    80005c56:	57fd                	li	a5,-1
    80005c58:	a805                	j	80005c88 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c5a:	fc442783          	lw	a5,-60(s0)
    80005c5e:	0007c863          	bltz	a5,80005c6e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c62:	01a78513          	addi	a0,a5,26
    80005c66:	050e                	slli	a0,a0,0x3
    80005c68:	9526                	add	a0,a0,s1
    80005c6a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c6e:	fd043503          	ld	a0,-48(s0)
    80005c72:	fffff097          	auipc	ra,0xfffff
    80005c76:	992080e7          	jalr	-1646(ra) # 80004604 <fileclose>
    fileclose(wf);
    80005c7a:	fc843503          	ld	a0,-56(s0)
    80005c7e:	fffff097          	auipc	ra,0xfffff
    80005c82:	986080e7          	jalr	-1658(ra) # 80004604 <fileclose>
    return -1;
    80005c86:	57fd                	li	a5,-1
}
    80005c88:	853e                	mv	a0,a5
    80005c8a:	70e2                	ld	ra,56(sp)
    80005c8c:	7442                	ld	s0,48(sp)
    80005c8e:	74a2                	ld	s1,40(sp)
    80005c90:	6121                	addi	sp,sp,64
    80005c92:	8082                	ret

0000000080005c94 <sys_symlink>:

uint64
sys_symlink(void)
{
    80005c94:	712d                	addi	sp,sp,-288
    80005c96:	ee06                	sd	ra,280(sp)
    80005c98:	ea22                	sd	s0,272(sp)
    80005c9a:	e626                	sd	s1,264(sp)
    80005c9c:	1200                	addi	s0,sp,288
  struct inode *ip;
  char target[MAXPATH], path[MAXPATH];
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005c9e:	08000613          	li	a2,128
    80005ca2:	f6040593          	addi	a1,s0,-160
    80005ca6:	4501                	li	a0,0
    80005ca8:	ffffd097          	auipc	ra,0xffffd
    80005cac:	e1a080e7          	jalr	-486(ra) # 80002ac2 <argstr>
    return -1;
    80005cb0:	57fd                	li	a5,-1
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005cb2:	06054a63          	bltz	a0,80005d26 <sys_symlink+0x92>
    80005cb6:	08000613          	li	a2,128
    80005cba:	ee040593          	addi	a1,s0,-288
    80005cbe:	4505                	li	a0,1
    80005cc0:	ffffd097          	auipc	ra,0xffffd
    80005cc4:	e02080e7          	jalr	-510(ra) # 80002ac2 <argstr>
    return -1;
    80005cc8:	57fd                	li	a5,-1
  if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0)
    80005cca:	04054e63          	bltz	a0,80005d26 <sys_symlink+0x92>

  begin_op();
    80005cce:	ffffe097          	auipc	ra,0xffffe
    80005cd2:	462080e7          	jalr	1122(ra) # 80004130 <begin_op>

  ip = create(path, T_SYMLINK, 0, 0);
    80005cd6:	4681                	li	a3,0
    80005cd8:	4601                	li	a2,0
    80005cda:	4591                	li	a1,4
    80005cdc:	ee040513          	addi	a0,s0,-288
    80005ce0:	fffff097          	auipc	ra,0xfffff
    80005ce4:	3b8080e7          	jalr	952(ra) # 80005098 <create>
    80005ce8:	84aa                	mv	s1,a0
  if(ip == 0){
    80005cea:	c521                	beqz	a0,80005d32 <sys_symlink+0x9e>
    end_op();
    return -1;
  }

  // use the first data block to store target path.
  if(writei(ip, 0, (uint64)target, 0, strlen(target)) < 0) {
    80005cec:	f6040513          	addi	a0,s0,-160
    80005cf0:	ffffb097          	auipc	ra,0xffffb
    80005cf4:	16a080e7          	jalr	362(ra) # 80000e5a <strlen>
    80005cf8:	0005071b          	sext.w	a4,a0
    80005cfc:	4681                	li	a3,0
    80005cfe:	f6040613          	addi	a2,s0,-160
    80005d02:	4581                	li	a1,0
    80005d04:	8526                	mv	a0,s1
    80005d06:	ffffe097          	auipc	ra,0xffffe
    80005d0a:	e02080e7          	jalr	-510(ra) # 80003b08 <writei>
    80005d0e:	02054863          	bltz	a0,80005d3e <sys_symlink+0xaa>
    end_op();
    return -1;
  }

  iunlockput(ip);
    80005d12:	8526                	mv	a0,s1
    80005d14:	ffffe097          	auipc	ra,0xffffe
    80005d18:	caa080e7          	jalr	-854(ra) # 800039be <iunlockput>

  end_op();
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	494080e7          	jalr	1172(ra) # 800041b0 <end_op>
  return 0;
    80005d24:	4781                	li	a5,0
    80005d26:	853e                	mv	a0,a5
    80005d28:	60f2                	ld	ra,280(sp)
    80005d2a:	6452                	ld	s0,272(sp)
    80005d2c:	64b2                	ld	s1,264(sp)
    80005d2e:	6115                	addi	sp,sp,288
    80005d30:	8082                	ret
    end_op();
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	47e080e7          	jalr	1150(ra) # 800041b0 <end_op>
    return -1;
    80005d3a:	57fd                	li	a5,-1
    80005d3c:	b7ed                	j	80005d26 <sys_symlink+0x92>
    end_op();
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	472080e7          	jalr	1138(ra) # 800041b0 <end_op>
    return -1;
    80005d46:	57fd                	li	a5,-1
    80005d48:	bff9                	j	80005d26 <sys_symlink+0x92>
    80005d4a:	0000                	unimp
    80005d4c:	0000                	unimp
	...

0000000080005d50 <kernelvec>:
    80005d50:	7111                	addi	sp,sp,-256
    80005d52:	e006                	sd	ra,0(sp)
    80005d54:	e40a                	sd	sp,8(sp)
    80005d56:	e80e                	sd	gp,16(sp)
    80005d58:	ec12                	sd	tp,24(sp)
    80005d5a:	f016                	sd	t0,32(sp)
    80005d5c:	f41a                	sd	t1,40(sp)
    80005d5e:	f81e                	sd	t2,48(sp)
    80005d60:	fc22                	sd	s0,56(sp)
    80005d62:	e0a6                	sd	s1,64(sp)
    80005d64:	e4aa                	sd	a0,72(sp)
    80005d66:	e8ae                	sd	a1,80(sp)
    80005d68:	ecb2                	sd	a2,88(sp)
    80005d6a:	f0b6                	sd	a3,96(sp)
    80005d6c:	f4ba                	sd	a4,104(sp)
    80005d6e:	f8be                	sd	a5,112(sp)
    80005d70:	fcc2                	sd	a6,120(sp)
    80005d72:	e146                	sd	a7,128(sp)
    80005d74:	e54a                	sd	s2,136(sp)
    80005d76:	e94e                	sd	s3,144(sp)
    80005d78:	ed52                	sd	s4,152(sp)
    80005d7a:	f156                	sd	s5,160(sp)
    80005d7c:	f55a                	sd	s6,168(sp)
    80005d7e:	f95e                	sd	s7,176(sp)
    80005d80:	fd62                	sd	s8,184(sp)
    80005d82:	e1e6                	sd	s9,192(sp)
    80005d84:	e5ea                	sd	s10,200(sp)
    80005d86:	e9ee                	sd	s11,208(sp)
    80005d88:	edf2                	sd	t3,216(sp)
    80005d8a:	f1f6                	sd	t4,224(sp)
    80005d8c:	f5fa                	sd	t5,232(sp)
    80005d8e:	f9fe                	sd	t6,240(sp)
    80005d90:	b21fc0ef          	jal	ra,800028b0 <kerneltrap>
    80005d94:	6082                	ld	ra,0(sp)
    80005d96:	6122                	ld	sp,8(sp)
    80005d98:	61c2                	ld	gp,16(sp)
    80005d9a:	7282                	ld	t0,32(sp)
    80005d9c:	7322                	ld	t1,40(sp)
    80005d9e:	73c2                	ld	t2,48(sp)
    80005da0:	7462                	ld	s0,56(sp)
    80005da2:	6486                	ld	s1,64(sp)
    80005da4:	6526                	ld	a0,72(sp)
    80005da6:	65c6                	ld	a1,80(sp)
    80005da8:	6666                	ld	a2,88(sp)
    80005daa:	7686                	ld	a3,96(sp)
    80005dac:	7726                	ld	a4,104(sp)
    80005dae:	77c6                	ld	a5,112(sp)
    80005db0:	7866                	ld	a6,120(sp)
    80005db2:	688a                	ld	a7,128(sp)
    80005db4:	692a                	ld	s2,136(sp)
    80005db6:	69ca                	ld	s3,144(sp)
    80005db8:	6a6a                	ld	s4,152(sp)
    80005dba:	7a8a                	ld	s5,160(sp)
    80005dbc:	7b2a                	ld	s6,168(sp)
    80005dbe:	7bca                	ld	s7,176(sp)
    80005dc0:	7c6a                	ld	s8,184(sp)
    80005dc2:	6c8e                	ld	s9,192(sp)
    80005dc4:	6d2e                	ld	s10,200(sp)
    80005dc6:	6dce                	ld	s11,208(sp)
    80005dc8:	6e6e                	ld	t3,216(sp)
    80005dca:	7e8e                	ld	t4,224(sp)
    80005dcc:	7f2e                	ld	t5,232(sp)
    80005dce:	7fce                	ld	t6,240(sp)
    80005dd0:	6111                	addi	sp,sp,256
    80005dd2:	10200073          	sret
    80005dd6:	00000013          	nop
    80005dda:	00000013          	nop
    80005dde:	0001                	nop

0000000080005de0 <timervec>:
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	e10c                	sd	a1,0(a0)
    80005de6:	e510                	sd	a2,8(a0)
    80005de8:	e914                	sd	a3,16(a0)
    80005dea:	6d0c                	ld	a1,24(a0)
    80005dec:	7110                	ld	a2,32(a0)
    80005dee:	6194                	ld	a3,0(a1)
    80005df0:	96b2                	add	a3,a3,a2
    80005df2:	e194                	sd	a3,0(a1)
    80005df4:	4589                	li	a1,2
    80005df6:	14459073          	csrw	sip,a1
    80005dfa:	6914                	ld	a3,16(a0)
    80005dfc:	6510                	ld	a2,8(a0)
    80005dfe:	610c                	ld	a1,0(a0)
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	30200073          	mret
	...

0000000080005e0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e0a:	1141                	addi	sp,sp,-16
    80005e0c:	e422                	sd	s0,8(sp)
    80005e0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e10:	0c0007b7          	lui	a5,0xc000
    80005e14:	4705                	li	a4,1
    80005e16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e18:	c3d8                	sw	a4,4(a5)
}
    80005e1a:	6422                	ld	s0,8(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret

0000000080005e20 <plicinithart>:

void
plicinithart(void)
{
    80005e20:	1141                	addi	sp,sp,-16
    80005e22:	e406                	sd	ra,8(sp)
    80005e24:	e022                	sd	s0,0(sp)
    80005e26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b6c080e7          	jalr	-1172(ra) # 80001994 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e30:	0085171b          	slliw	a4,a0,0x8
    80005e34:	0c0027b7          	lui	a5,0xc002
    80005e38:	97ba                	add	a5,a5,a4
    80005e3a:	40200713          	li	a4,1026
    80005e3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e42:	00d5151b          	slliw	a0,a0,0xd
    80005e46:	0c2017b7          	lui	a5,0xc201
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	00052023          	sw	zero,0(a0)
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret

0000000080005e58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e58:	1141                	addi	sp,sp,-16
    80005e5a:	e406                	sd	ra,8(sp)
    80005e5c:	e022                	sd	s0,0(sp)
    80005e5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	b34080e7          	jalr	-1228(ra) # 80001994 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e68:	00d5179b          	slliw	a5,a0,0xd
    80005e6c:	0c201537          	lui	a0,0xc201
    80005e70:	953e                	add	a0,a0,a5
  return irq;
}
    80005e72:	4148                	lw	a0,4(a0)
    80005e74:	60a2                	ld	ra,8(sp)
    80005e76:	6402                	ld	s0,0(sp)
    80005e78:	0141                	addi	sp,sp,16
    80005e7a:	8082                	ret

0000000080005e7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e7c:	1101                	addi	sp,sp,-32
    80005e7e:	ec06                	sd	ra,24(sp)
    80005e80:	e822                	sd	s0,16(sp)
    80005e82:	e426                	sd	s1,8(sp)
    80005e84:	1000                	addi	s0,sp,32
    80005e86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	b0c080e7          	jalr	-1268(ra) # 80001994 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e90:	00d5151b          	slliw	a0,a0,0xd
    80005e94:	0c2017b7          	lui	a5,0xc201
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	c3c4                	sw	s1,4(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret

0000000080005ea6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ea6:	1141                	addi	sp,sp,-16
    80005ea8:	e406                	sd	ra,8(sp)
    80005eaa:	e022                	sd	s0,0(sp)
    80005eac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eae:	479d                	li	a5,7
    80005eb0:	06a7c963          	blt	a5,a0,80005f22 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005eb4:	00018797          	auipc	a5,0x18
    80005eb8:	14c78793          	addi	a5,a5,332 # 8001e000 <disk>
    80005ebc:	00a78733          	add	a4,a5,a0
    80005ec0:	6789                	lui	a5,0x2
    80005ec2:	97ba                	add	a5,a5,a4
    80005ec4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005ec8:	e7ad                	bnez	a5,80005f32 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005eca:	00451793          	slli	a5,a0,0x4
    80005ece:	0001a717          	auipc	a4,0x1a
    80005ed2:	13270713          	addi	a4,a4,306 # 80020000 <disk+0x2000>
    80005ed6:	6314                	ld	a3,0(a4)
    80005ed8:	96be                	add	a3,a3,a5
    80005eda:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ede:	6314                	ld	a3,0(a4)
    80005ee0:	96be                	add	a3,a3,a5
    80005ee2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005ee6:	6314                	ld	a3,0(a4)
    80005ee8:	96be                	add	a3,a3,a5
    80005eea:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005eee:	6318                	ld	a4,0(a4)
    80005ef0:	97ba                	add	a5,a5,a4
    80005ef2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005ef6:	00018797          	auipc	a5,0x18
    80005efa:	10a78793          	addi	a5,a5,266 # 8001e000 <disk>
    80005efe:	97aa                	add	a5,a5,a0
    80005f00:	6509                	lui	a0,0x2
    80005f02:	953e                	add	a0,a0,a5
    80005f04:	4785                	li	a5,1
    80005f06:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005f0a:	0001a517          	auipc	a0,0x1a
    80005f0e:	10e50513          	addi	a0,a0,270 # 80020018 <disk+0x2018>
    80005f12:	ffffc097          	auipc	ra,0xffffc
    80005f16:	444080e7          	jalr	1092(ra) # 80002356 <wakeup>
}
    80005f1a:	60a2                	ld	ra,8(sp)
    80005f1c:	6402                	ld	s0,0(sp)
    80005f1e:	0141                	addi	sp,sp,16
    80005f20:	8082                	ret
    panic("free_desc 1");
    80005f22:	00003517          	auipc	a0,0x3
    80005f26:	82650513          	addi	a0,a0,-2010 # 80008748 <syscalls+0x328>
    80005f2a:	ffffa097          	auipc	ra,0xffffa
    80005f2e:	606080e7          	jalr	1542(ra) # 80000530 <panic>
    panic("free_desc 2");
    80005f32:	00003517          	auipc	a0,0x3
    80005f36:	82650513          	addi	a0,a0,-2010 # 80008758 <syscalls+0x338>
    80005f3a:	ffffa097          	auipc	ra,0xffffa
    80005f3e:	5f6080e7          	jalr	1526(ra) # 80000530 <panic>

0000000080005f42 <virtio_disk_init>:
{
    80005f42:	1101                	addi	sp,sp,-32
    80005f44:	ec06                	sd	ra,24(sp)
    80005f46:	e822                	sd	s0,16(sp)
    80005f48:	e426                	sd	s1,8(sp)
    80005f4a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f4c:	00003597          	auipc	a1,0x3
    80005f50:	81c58593          	addi	a1,a1,-2020 # 80008768 <syscalls+0x348>
    80005f54:	0001a517          	auipc	a0,0x1a
    80005f58:	1d450513          	addi	a0,a0,468 # 80020128 <disk+0x2128>
    80005f5c:	ffffb097          	auipc	ra,0xffffb
    80005f60:	bea080e7          	jalr	-1046(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f64:	100017b7          	lui	a5,0x10001
    80005f68:	4398                	lw	a4,0(a5)
    80005f6a:	2701                	sext.w	a4,a4
    80005f6c:	747277b7          	lui	a5,0x74727
    80005f70:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f74:	0ef71163          	bne	a4,a5,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f78:	100017b7          	lui	a5,0x10001
    80005f7c:	43dc                	lw	a5,4(a5)
    80005f7e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f80:	4705                	li	a4,1
    80005f82:	0ce79a63          	bne	a5,a4,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f86:	100017b7          	lui	a5,0x10001
    80005f8a:	479c                	lw	a5,8(a5)
    80005f8c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f8e:	4709                	li	a4,2
    80005f90:	0ce79363          	bne	a5,a4,80006056 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f94:	100017b7          	lui	a5,0x10001
    80005f98:	47d8                	lw	a4,12(a5)
    80005f9a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f9c:	554d47b7          	lui	a5,0x554d4
    80005fa0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fa4:	0af71963          	bne	a4,a5,80006056 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa8:	100017b7          	lui	a5,0x10001
    80005fac:	4705                	li	a4,1
    80005fae:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb0:	470d                	li	a4,3
    80005fb2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fb4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fb6:	c7ffe737          	lui	a4,0xc7ffe
    80005fba:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdd75f>
    80005fbe:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fc0:	2701                	sext.w	a4,a4
    80005fc2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc4:	472d                	li	a4,11
    80005fc6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc8:	473d                	li	a4,15
    80005fca:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005fcc:	6705                	lui	a4,0x1
    80005fce:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fd4:	5bdc                	lw	a5,52(a5)
    80005fd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fd8:	c7d9                	beqz	a5,80006066 <virtio_disk_init+0x124>
  if(max < NUM)
    80005fda:	471d                	li	a4,7
    80005fdc:	08f77d63          	bgeu	a4,a5,80006076 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fe0:	100014b7          	lui	s1,0x10001
    80005fe4:	47a1                	li	a5,8
    80005fe6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fe8:	6609                	lui	a2,0x2
    80005fea:	4581                	li	a1,0
    80005fec:	00018517          	auipc	a0,0x18
    80005ff0:	01450513          	addi	a0,a0,20 # 8001e000 <disk>
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	cde080e7          	jalr	-802(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ffc:	00018717          	auipc	a4,0x18
    80006000:	00470713          	addi	a4,a4,4 # 8001e000 <disk>
    80006004:	00c75793          	srli	a5,a4,0xc
    80006008:	2781                	sext.w	a5,a5
    8000600a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000600c:	0001a797          	auipc	a5,0x1a
    80006010:	ff478793          	addi	a5,a5,-12 # 80020000 <disk+0x2000>
    80006014:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006016:	00018717          	auipc	a4,0x18
    8000601a:	06a70713          	addi	a4,a4,106 # 8001e080 <disk+0x80>
    8000601e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006020:	00019717          	auipc	a4,0x19
    80006024:	fe070713          	addi	a4,a4,-32 # 8001f000 <disk+0x1000>
    80006028:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000602a:	4705                	li	a4,1
    8000602c:	00e78c23          	sb	a4,24(a5)
    80006030:	00e78ca3          	sb	a4,25(a5)
    80006034:	00e78d23          	sb	a4,26(a5)
    80006038:	00e78da3          	sb	a4,27(a5)
    8000603c:	00e78e23          	sb	a4,28(a5)
    80006040:	00e78ea3          	sb	a4,29(a5)
    80006044:	00e78f23          	sb	a4,30(a5)
    80006048:	00e78fa3          	sb	a4,31(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret
    panic("could not find virtio disk");
    80006056:	00002517          	auipc	a0,0x2
    8000605a:	72250513          	addi	a0,a0,1826 # 80008778 <syscalls+0x358>
    8000605e:	ffffa097          	auipc	ra,0xffffa
    80006062:	4d2080e7          	jalr	1234(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006066:	00002517          	auipc	a0,0x2
    8000606a:	73250513          	addi	a0,a0,1842 # 80008798 <syscalls+0x378>
    8000606e:	ffffa097          	auipc	ra,0xffffa
    80006072:	4c2080e7          	jalr	1218(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006076:	00002517          	auipc	a0,0x2
    8000607a:	74250513          	addi	a0,a0,1858 # 800087b8 <syscalls+0x398>
    8000607e:	ffffa097          	auipc	ra,0xffffa
    80006082:	4b2080e7          	jalr	1202(ra) # 80000530 <panic>

0000000080006086 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006086:	7159                	addi	sp,sp,-112
    80006088:	f486                	sd	ra,104(sp)
    8000608a:	f0a2                	sd	s0,96(sp)
    8000608c:	eca6                	sd	s1,88(sp)
    8000608e:	e8ca                	sd	s2,80(sp)
    80006090:	e4ce                	sd	s3,72(sp)
    80006092:	e0d2                	sd	s4,64(sp)
    80006094:	fc56                	sd	s5,56(sp)
    80006096:	f85a                	sd	s6,48(sp)
    80006098:	f45e                	sd	s7,40(sp)
    8000609a:	f062                	sd	s8,32(sp)
    8000609c:	ec66                	sd	s9,24(sp)
    8000609e:	e86a                	sd	s10,16(sp)
    800060a0:	1880                	addi	s0,sp,112
    800060a2:	892a                	mv	s2,a0
    800060a4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800060a6:	00c52c83          	lw	s9,12(a0)
    800060aa:	001c9c9b          	slliw	s9,s9,0x1
    800060ae:	1c82                	slli	s9,s9,0x20
    800060b0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800060b4:	0001a517          	auipc	a0,0x1a
    800060b8:	07450513          	addi	a0,a0,116 # 80020128 <disk+0x2128>
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800060c4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060c6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800060c8:	00018b97          	auipc	s7,0x18
    800060cc:	f38b8b93          	addi	s7,s7,-200 # 8001e000 <disk>
    800060d0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    800060d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800060d4:	8a4e                	mv	s4,s3
    800060d6:	a051                	j	8000615a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    800060d8:	00fb86b3          	add	a3,s7,a5
    800060dc:	96da                	add	a3,a3,s6
    800060de:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800060e2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800060e4:	0207c563          	bltz	a5,8000610e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800060e8:	2485                	addiw	s1,s1,1
    800060ea:	0711                	addi	a4,a4,4
    800060ec:	25548063          	beq	s1,s5,8000632c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060f0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060f2:	0001a697          	auipc	a3,0x1a
    800060f6:	f2668693          	addi	a3,a3,-218 # 80020018 <disk+0x2018>
    800060fa:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060fc:	0006c583          	lbu	a1,0(a3)
    80006100:	fde1                	bnez	a1,800060d8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006102:	2785                	addiw	a5,a5,1
    80006104:	0685                	addi	a3,a3,1
    80006106:	ff879be3          	bne	a5,s8,800060fc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000610a:	57fd                	li	a5,-1
    8000610c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000610e:	02905a63          	blez	s1,80006142 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006112:	f9042503          	lw	a0,-112(s0)
    80006116:	00000097          	auipc	ra,0x0
    8000611a:	d90080e7          	jalr	-624(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    8000611e:	4785                	li	a5,1
    80006120:	0297d163          	bge	a5,s1,80006142 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006124:	f9442503          	lw	a0,-108(s0)
    80006128:	00000097          	auipc	ra,0x0
    8000612c:	d7e080e7          	jalr	-642(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    80006130:	4789                	li	a5,2
    80006132:	0097d863          	bge	a5,s1,80006142 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006136:	f9842503          	lw	a0,-104(s0)
    8000613a:	00000097          	auipc	ra,0x0
    8000613e:	d6c080e7          	jalr	-660(ra) # 80005ea6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006142:	0001a597          	auipc	a1,0x1a
    80006146:	fe658593          	addi	a1,a1,-26 # 80020128 <disk+0x2128>
    8000614a:	0001a517          	auipc	a0,0x1a
    8000614e:	ece50513          	addi	a0,a0,-306 # 80020018 <disk+0x2018>
    80006152:	ffffc097          	auipc	ra,0xffffc
    80006156:	07e080e7          	jalr	126(ra) # 800021d0 <sleep>
  for(int i = 0; i < 3; i++){
    8000615a:	f9040713          	addi	a4,s0,-112
    8000615e:	84ce                	mv	s1,s3
    80006160:	bf41                	j	800060f0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006162:	20058713          	addi	a4,a1,512
    80006166:	00471693          	slli	a3,a4,0x4
    8000616a:	00018717          	auipc	a4,0x18
    8000616e:	e9670713          	addi	a4,a4,-362 # 8001e000 <disk>
    80006172:	9736                	add	a4,a4,a3
    80006174:	4685                	li	a3,1
    80006176:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000617a:	20058713          	addi	a4,a1,512
    8000617e:	00471693          	slli	a3,a4,0x4
    80006182:	00018717          	auipc	a4,0x18
    80006186:	e7e70713          	addi	a4,a4,-386 # 8001e000 <disk>
    8000618a:	9736                	add	a4,a4,a3
    8000618c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006190:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006194:	7679                	lui	a2,0xffffe
    80006196:	963e                	add	a2,a2,a5
    80006198:	0001a697          	auipc	a3,0x1a
    8000619c:	e6868693          	addi	a3,a3,-408 # 80020000 <disk+0x2000>
    800061a0:	6298                	ld	a4,0(a3)
    800061a2:	9732                	add	a4,a4,a2
    800061a4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800061a6:	6298                	ld	a4,0(a3)
    800061a8:	9732                	add	a4,a4,a2
    800061aa:	4541                	li	a0,16
    800061ac:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800061ae:	6298                	ld	a4,0(a3)
    800061b0:	9732                	add	a4,a4,a2
    800061b2:	4505                	li	a0,1
    800061b4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800061b8:	f9442703          	lw	a4,-108(s0)
    800061bc:	6288                	ld	a0,0(a3)
    800061be:	962a                	add	a2,a2,a0
    800061c0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffdd00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800061c4:	0712                	slli	a4,a4,0x4
    800061c6:	6290                	ld	a2,0(a3)
    800061c8:	963a                	add	a2,a2,a4
    800061ca:	05890513          	addi	a0,s2,88
    800061ce:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800061d0:	6294                	ld	a3,0(a3)
    800061d2:	96ba                	add	a3,a3,a4
    800061d4:	40000613          	li	a2,1024
    800061d8:	c690                	sw	a2,8(a3)
  if(write)
    800061da:	140d0063          	beqz	s10,8000631a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800061de:	0001a697          	auipc	a3,0x1a
    800061e2:	e226b683          	ld	a3,-478(a3) # 80020000 <disk+0x2000>
    800061e6:	96ba                	add	a3,a3,a4
    800061e8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061ec:	00018817          	auipc	a6,0x18
    800061f0:	e1480813          	addi	a6,a6,-492 # 8001e000 <disk>
    800061f4:	0001a517          	auipc	a0,0x1a
    800061f8:	e0c50513          	addi	a0,a0,-500 # 80020000 <disk+0x2000>
    800061fc:	6114                	ld	a3,0(a0)
    800061fe:	96ba                	add	a3,a3,a4
    80006200:	00c6d603          	lhu	a2,12(a3)
    80006204:	00166613          	ori	a2,a2,1
    80006208:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000620c:	f9842683          	lw	a3,-104(s0)
    80006210:	6110                	ld	a2,0(a0)
    80006212:	9732                	add	a4,a4,a2
    80006214:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006218:	20058613          	addi	a2,a1,512
    8000621c:	0612                	slli	a2,a2,0x4
    8000621e:	9642                	add	a2,a2,a6
    80006220:	577d                	li	a4,-1
    80006222:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006226:	00469713          	slli	a4,a3,0x4
    8000622a:	6114                	ld	a3,0(a0)
    8000622c:	96ba                	add	a3,a3,a4
    8000622e:	03078793          	addi	a5,a5,48
    80006232:	97c2                	add	a5,a5,a6
    80006234:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006236:	611c                	ld	a5,0(a0)
    80006238:	97ba                	add	a5,a5,a4
    8000623a:	4685                	li	a3,1
    8000623c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000623e:	611c                	ld	a5,0(a0)
    80006240:	97ba                	add	a5,a5,a4
    80006242:	4809                	li	a6,2
    80006244:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006248:	611c                	ld	a5,0(a0)
    8000624a:	973e                	add	a4,a4,a5
    8000624c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006250:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006254:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006258:	6518                	ld	a4,8(a0)
    8000625a:	00275783          	lhu	a5,2(a4)
    8000625e:	8b9d                	andi	a5,a5,7
    80006260:	0786                	slli	a5,a5,0x1
    80006262:	97ba                	add	a5,a5,a4
    80006264:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006268:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000626c:	6518                	ld	a4,8(a0)
    8000626e:	00275783          	lhu	a5,2(a4)
    80006272:	2785                	addiw	a5,a5,1
    80006274:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006278:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000627c:	100017b7          	lui	a5,0x10001
    80006280:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006284:	00492703          	lw	a4,4(s2)
    80006288:	4785                	li	a5,1
    8000628a:	02f71163          	bne	a4,a5,800062ac <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000628e:	0001a997          	auipc	s3,0x1a
    80006292:	e9a98993          	addi	s3,s3,-358 # 80020128 <disk+0x2128>
  while(b->disk == 1) {
    80006296:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006298:	85ce                	mv	a1,s3
    8000629a:	854a                	mv	a0,s2
    8000629c:	ffffc097          	auipc	ra,0xffffc
    800062a0:	f34080e7          	jalr	-204(ra) # 800021d0 <sleep>
  while(b->disk == 1) {
    800062a4:	00492783          	lw	a5,4(s2)
    800062a8:	fe9788e3          	beq	a5,s1,80006298 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800062ac:	f9042903          	lw	s2,-112(s0)
    800062b0:	20090793          	addi	a5,s2,512
    800062b4:	00479713          	slli	a4,a5,0x4
    800062b8:	00018797          	auipc	a5,0x18
    800062bc:	d4878793          	addi	a5,a5,-696 # 8001e000 <disk>
    800062c0:	97ba                	add	a5,a5,a4
    800062c2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800062c6:	0001a997          	auipc	s3,0x1a
    800062ca:	d3a98993          	addi	s3,s3,-710 # 80020000 <disk+0x2000>
    800062ce:	00491713          	slli	a4,s2,0x4
    800062d2:	0009b783          	ld	a5,0(s3)
    800062d6:	97ba                	add	a5,a5,a4
    800062d8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800062dc:	854a                	mv	a0,s2
    800062de:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800062e2:	00000097          	auipc	ra,0x0
    800062e6:	bc4080e7          	jalr	-1084(ra) # 80005ea6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800062ea:	8885                	andi	s1,s1,1
    800062ec:	f0ed                	bnez	s1,800062ce <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062ee:	0001a517          	auipc	a0,0x1a
    800062f2:	e3a50513          	addi	a0,a0,-454 # 80020128 <disk+0x2128>
    800062f6:	ffffb097          	auipc	ra,0xffffb
    800062fa:	994080e7          	jalr	-1644(ra) # 80000c8a <release>
}
    800062fe:	70a6                	ld	ra,104(sp)
    80006300:	7406                	ld	s0,96(sp)
    80006302:	64e6                	ld	s1,88(sp)
    80006304:	6946                	ld	s2,80(sp)
    80006306:	69a6                	ld	s3,72(sp)
    80006308:	6a06                	ld	s4,64(sp)
    8000630a:	7ae2                	ld	s5,56(sp)
    8000630c:	7b42                	ld	s6,48(sp)
    8000630e:	7ba2                	ld	s7,40(sp)
    80006310:	7c02                	ld	s8,32(sp)
    80006312:	6ce2                	ld	s9,24(sp)
    80006314:	6d42                	ld	s10,16(sp)
    80006316:	6165                	addi	sp,sp,112
    80006318:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000631a:	0001a697          	auipc	a3,0x1a
    8000631e:	ce66b683          	ld	a3,-794(a3) # 80020000 <disk+0x2000>
    80006322:	96ba                	add	a3,a3,a4
    80006324:	4609                	li	a2,2
    80006326:	00c69623          	sh	a2,12(a3)
    8000632a:	b5c9                	j	800061ec <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000632c:	f9042583          	lw	a1,-112(s0)
    80006330:	20058793          	addi	a5,a1,512
    80006334:	0792                	slli	a5,a5,0x4
    80006336:	00018517          	auipc	a0,0x18
    8000633a:	d7250513          	addi	a0,a0,-654 # 8001e0a8 <disk+0xa8>
    8000633e:	953e                	add	a0,a0,a5
  if(write)
    80006340:	e20d11e3          	bnez	s10,80006162 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006344:	20058713          	addi	a4,a1,512
    80006348:	00471693          	slli	a3,a4,0x4
    8000634c:	00018717          	auipc	a4,0x18
    80006350:	cb470713          	addi	a4,a4,-844 # 8001e000 <disk>
    80006354:	9736                	add	a4,a4,a3
    80006356:	0a072423          	sw	zero,168(a4)
    8000635a:	b505                	j	8000617a <virtio_disk_rw+0xf4>

000000008000635c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000635c:	1101                	addi	sp,sp,-32
    8000635e:	ec06                	sd	ra,24(sp)
    80006360:	e822                	sd	s0,16(sp)
    80006362:	e426                	sd	s1,8(sp)
    80006364:	e04a                	sd	s2,0(sp)
    80006366:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006368:	0001a517          	auipc	a0,0x1a
    8000636c:	dc050513          	addi	a0,a0,-576 # 80020128 <disk+0x2128>
    80006370:	ffffb097          	auipc	ra,0xffffb
    80006374:	866080e7          	jalr	-1946(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006378:	10001737          	lui	a4,0x10001
    8000637c:	533c                	lw	a5,96(a4)
    8000637e:	8b8d                	andi	a5,a5,3
    80006380:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006382:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006386:	0001a797          	auipc	a5,0x1a
    8000638a:	c7a78793          	addi	a5,a5,-902 # 80020000 <disk+0x2000>
    8000638e:	6b94                	ld	a3,16(a5)
    80006390:	0207d703          	lhu	a4,32(a5)
    80006394:	0026d783          	lhu	a5,2(a3)
    80006398:	06f70163          	beq	a4,a5,800063fa <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000639c:	00018917          	auipc	s2,0x18
    800063a0:	c6490913          	addi	s2,s2,-924 # 8001e000 <disk>
    800063a4:	0001a497          	auipc	s1,0x1a
    800063a8:	c5c48493          	addi	s1,s1,-932 # 80020000 <disk+0x2000>
    __sync_synchronize();
    800063ac:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063b0:	6898                	ld	a4,16(s1)
    800063b2:	0204d783          	lhu	a5,32(s1)
    800063b6:	8b9d                	andi	a5,a5,7
    800063b8:	078e                	slli	a5,a5,0x3
    800063ba:	97ba                	add	a5,a5,a4
    800063bc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063be:	20078713          	addi	a4,a5,512
    800063c2:	0712                	slli	a4,a4,0x4
    800063c4:	974a                	add	a4,a4,s2
    800063c6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800063ca:	e731                	bnez	a4,80006416 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063cc:	20078793          	addi	a5,a5,512
    800063d0:	0792                	slli	a5,a5,0x4
    800063d2:	97ca                	add	a5,a5,s2
    800063d4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800063d6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063da:	ffffc097          	auipc	ra,0xffffc
    800063de:	f7c080e7          	jalr	-132(ra) # 80002356 <wakeup>

    disk.used_idx += 1;
    800063e2:	0204d783          	lhu	a5,32(s1)
    800063e6:	2785                	addiw	a5,a5,1
    800063e8:	17c2                	slli	a5,a5,0x30
    800063ea:	93c1                	srli	a5,a5,0x30
    800063ec:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063f0:	6898                	ld	a4,16(s1)
    800063f2:	00275703          	lhu	a4,2(a4)
    800063f6:	faf71be3          	bne	a4,a5,800063ac <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800063fa:	0001a517          	auipc	a0,0x1a
    800063fe:	d2e50513          	addi	a0,a0,-722 # 80020128 <disk+0x2128>
    80006402:	ffffb097          	auipc	ra,0xffffb
    80006406:	888080e7          	jalr	-1912(ra) # 80000c8a <release>
}
    8000640a:	60e2                	ld	ra,24(sp)
    8000640c:	6442                	ld	s0,16(sp)
    8000640e:	64a2                	ld	s1,8(sp)
    80006410:	6902                	ld	s2,0(sp)
    80006412:	6105                	addi	sp,sp,32
    80006414:	8082                	ret
      panic("virtio_disk_intr status");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	3c250513          	addi	a0,a0,962 # 800087d8 <syscalls+0x3b8>
    8000641e:	ffffa097          	auipc	ra,0xffffa
    80006422:	112080e7          	jalr	274(ra) # 80000530 <panic>
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
