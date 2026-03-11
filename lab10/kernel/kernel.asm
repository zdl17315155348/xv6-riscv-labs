
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
    80000068:	03c78793          	addi	a5,a5,60 # 800060a0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7ff>
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
    80000122:	518080e7          	jalr	1304(ra) # 80002636 <either_copyin>
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
    800001ba:	91e080e7          	jalr	-1762(ra) # 80001ad4 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00002097          	auipc	ra,0x2
    800001ca:	1b8080e7          	jalr	440(ra) # 8000237e <sleep>
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
    80000206:	3de080e7          	jalr	990(ra) # 800025e0 <either_copyout>
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
    800002e8:	3a8080e7          	jalr	936(ra) # 8000268c <procdump>
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
    8000043c:	0cc080e7          	jalr	204(ra) # 80002504 <wakeup>
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
    8000046a:	0002d797          	auipc	a5,0x2d
    8000046e:	e9678793          	addi	a5,a5,-362 # 8002d300 <devsw>
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
    80000896:	c72080e7          	jalr	-910(ra) # 80002504 <wakeup>
    
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
    80000922:	a60080e7          	jalr	-1440(ra) # 8000237e <sleep>
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
    800009fe:	00031797          	auipc	a5,0x31
    80000a02:	60278793          	addi	a5,a5,1538 # 80032000 <end>
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
    80000ace:	00031517          	auipc	a0,0x31
    80000ad2:	53250513          	addi	a0,a0,1330 # 80032000 <end>
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
    80000b74:	f48080e7          	jalr	-184(ra) # 80001ab8 <mycpu>
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
    80000ba6:	f16080e7          	jalr	-234(ra) # 80001ab8 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	f0a080e7          	jalr	-246(ra) # 80001ab8 <mycpu>
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
    80000bca:	ef2080e7          	jalr	-270(ra) # 80001ab8 <mycpu>
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
    80000c0a:	eb2080e7          	jalr	-334(ra) # 80001ab8 <mycpu>
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
    80000c36:	e86080e7          	jalr	-378(ra) # 80001ab8 <mycpu>
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
    80000e90:	c1c080e7          	jalr	-996(ra) # 80001aa8 <cpuid>
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
    80000eac:	c00080e7          	jalr	-1024(ra) # 80001aa8 <cpuid>
    80000eb0:	85aa                	mv	a1,a0
    80000eb2:	00007517          	auipc	a0,0x7
    80000eb6:	20650513          	addi	a0,a0,518 # 800080b8 <digits+0x78>
    80000eba:	fffff097          	auipc	ra,0xfffff
    80000ebe:	6c0080e7          	jalr	1728(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	0d8080e7          	jalr	216(ra) # 80000f9a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eca:	00002097          	auipc	ra,0x2
    80000ece:	902080e7          	jalr	-1790(ra) # 800027cc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ed2:	00005097          	auipc	ra,0x5
    80000ed6:	20e080e7          	jalr	526(ra) # 800060e0 <plicinithart>
  }

  scheduler();        
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	1c4080e7          	jalr	452(ra) # 8000209e <scheduler>
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
    80000f2e:	424080e7          	jalr	1060(ra) # 8000134e <kvminit>
    kvminithart();   // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	068080e7          	jalr	104(ra) # 80000f9a <kvminithart>
    procinit();      // process table
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	ad6080e7          	jalr	-1322(ra) # 80001a10 <procinit>
    trapinit();      // trap vectors
    80000f42:	00002097          	auipc	ra,0x2
    80000f46:	862080e7          	jalr	-1950(ra) # 800027a4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	882080e7          	jalr	-1918(ra) # 800027cc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f52:	00005097          	auipc	ra,0x5
    80000f56:	178080e7          	jalr	376(ra) # 800060ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f5a:	00005097          	auipc	ra,0x5
    80000f5e:	186080e7          	jalr	390(ra) # 800060e0 <plicinithart>
    binit();         // buffer cache
    80000f62:	00002097          	auipc	ra,0x2
    80000f66:	fd0080e7          	jalr	-48(ra) # 80002f32 <binit>
    iinit();         // inode cache
    80000f6a:	00002097          	auipc	ra,0x2
    80000f6e:	660080e7          	jalr	1632(ra) # 800035ca <iinit>
    fileinit();      // file table
    80000f72:	00003097          	auipc	ra,0x3
    80000f76:	612080e7          	jalr	1554(ra) # 80004584 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f7a:	00005097          	auipc	ra,0x5
    80000f7e:	288080e7          	jalr	648(ra) # 80006202 <virtio_disk_init>
    userinit();      // first user process
    80000f82:	00001097          	auipc	ra,0x1
    80000f86:	e62080e7          	jalr	-414(ra) # 80001de4 <userinit>
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

0000000080001064 <vmaunmap>:
{
    80001064:	715d                	addi	sp,sp,-80
    80001066:	e486                	sd	ra,72(sp)
    80001068:	e0a2                	sd	s0,64(sp)
    8000106a:	fc26                	sd	s1,56(sp)
    8000106c:	f84a                	sd	s2,48(sp)
    8000106e:	f44e                	sd	s3,40(sp)
    80001070:	f052                	sd	s4,32(sp)
    80001072:	ec56                	sd	s5,24(sp)
    80001074:	e85a                	sd	s6,16(sp)
    80001076:	e45e                	sd	s7,8(sp)
    80001078:	e062                	sd	s8,0(sp)
    8000107a:	0880                	addi	s0,sp,80
  for(a = va; a < va + nbytes; a += PGSIZE){
    8000107c:	00c58a33          	add	s4,a1,a2
    80001080:	0f45f063          	bgeu	a1,s4,80001160 <vmaunmap+0xfc>
    80001084:	8aaa                	mv	s5,a0
    80001086:	892e                	mv	s2,a1
    80001088:	8c36                	mv	s8,a3
    if(PTE_FLAGS(*pte) == PTE_V)
    8000108a:	4b85                	li	s7,1
        } else if(aoff + PGSIZE > v->sz){  // if the last page is not a full 4k page
    8000108c:	6b05                	lui	s6,0x1
    8000108e:	a899                	j	800010e4 <vmaunmap+0x80>
      panic("sys_munmap: not a leaf");
    80001090:	00007517          	auipc	a0,0x7
    80001094:	04850513          	addi	a0,a0,72 # 800080d8 <digits+0x98>
    80001098:	fffff097          	auipc	ra,0xfffff
    8000109c:	498080e7          	jalr	1176(ra) # 80000530 <panic>
          writei(v->f->ip, 0, pa, v->offset + aoff, PGSIZE);
    800010a0:	028c3683          	ld	a3,40(s8)
    800010a4:	018c3503          	ld	a0,24(s8)
    800010a8:	875a                	mv	a4,s6
    800010aa:	9ebd                	addw	a3,a3,a5
    800010ac:	864e                	mv	a2,s3
    800010ae:	4581                	li	a1,0
    800010b0:	6d08                	ld	a0,24(a0)
    800010b2:	00003097          	auipc	ra,0x3
    800010b6:	abc080e7          	jalr	-1348(ra) # 80003b6e <writei>
        iunlock(v->f->ip);
    800010ba:	018c3783          	ld	a5,24(s8)
    800010be:	6f88                	ld	a0,24(a5)
    800010c0:	00002097          	auipc	ra,0x2
    800010c4:	7c4080e7          	jalr	1988(ra) # 80003884 <iunlock>
        end_op();
    800010c8:	00003097          	auipc	ra,0x3
    800010cc:	14c080e7          	jalr	332(ra) # 80004214 <end_op>
      kfree((void*)pa);
    800010d0:	854e                	mv	a0,s3
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	918080e7          	jalr	-1768(ra) # 800009ea <kfree>
      *pte = 0;
    800010da:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + nbytes; a += PGSIZE){
    800010de:	995a                	add	s2,s2,s6
    800010e0:	09497063          	bgeu	s2,s4,80001160 <vmaunmap+0xfc>
    if((pte = walk(pagetable, a, 0)) == 0)
    800010e4:	4601                	li	a2,0
    800010e6:	85ca                	mv	a1,s2
    800010e8:	8556                	mv	a0,s5
    800010ea:	00000097          	auipc	ra,0x0
    800010ee:	ed4080e7          	jalr	-300(ra) # 80000fbe <walk>
    800010f2:	84aa                	mv	s1,a0
    800010f4:	d56d                	beqz	a0,800010de <vmaunmap+0x7a>
    if(PTE_FLAGS(*pte) == PTE_V)
    800010f6:	611c                	ld	a5,0(a0)
    800010f8:	3ff7f713          	andi	a4,a5,1023
    800010fc:	f9770ae3          	beq	a4,s7,80001090 <vmaunmap+0x2c>
    if(*pte & PTE_V){
    80001100:	0017f713          	andi	a4,a5,1
    80001104:	df69                	beqz	a4,800010de <vmaunmap+0x7a>
      uint64 pa = PTE2PA(*pte);
    80001106:	00a7d993          	srli	s3,a5,0xa
    8000110a:	09b2                	slli	s3,s3,0xc
      if((*pte & PTE_D) && (v->flags & MAP_SHARED)) { // dirty, need to write back to disk
    8000110c:	0807f793          	andi	a5,a5,128
    80001110:	d3e1                	beqz	a5,800010d0 <vmaunmap+0x6c>
    80001112:	024c2783          	lw	a5,36(s8)
    80001116:	8b85                	andi	a5,a5,1
    80001118:	dfc5                	beqz	a5,800010d0 <vmaunmap+0x6c>
        begin_op();
    8000111a:	00003097          	auipc	ra,0x3
    8000111e:	07a080e7          	jalr	122(ra) # 80004194 <begin_op>
        ilock(v->f->ip);
    80001122:	018c3783          	ld	a5,24(s8)
    80001126:	6f88                	ld	a0,24(a5)
    80001128:	00002097          	auipc	ra,0x2
    8000112c:	69a080e7          	jalr	1690(ra) # 800037c2 <ilock>
        uint64 aoff = a - v->vastart; // offset relative to the start of memory range
    80001130:	008c3783          	ld	a5,8(s8)
    80001134:	40f907b3          	sub	a5,s2,a5
        } else if(aoff + PGSIZE > v->sz){  // if the last page is not a full 4k page
    80001138:	010c3703          	ld	a4,16(s8)
    8000113c:	016786b3          	add	a3,a5,s6
    80001140:	f6d770e3          	bgeu	a4,a3,800010a0 <vmaunmap+0x3c>
          writei(v->f->ip, 0, pa, v->offset + aoff, v->sz - aoff);
    80001144:	028c3683          	ld	a3,40(s8)
    80001148:	018c3503          	ld	a0,24(s8)
    8000114c:	9f1d                	subw	a4,a4,a5
    8000114e:	9ebd                	addw	a3,a3,a5
    80001150:	864e                	mv	a2,s3
    80001152:	4581                	li	a1,0
    80001154:	6d08                	ld	a0,24(a0)
    80001156:	00003097          	auipc	ra,0x3
    8000115a:	a18080e7          	jalr	-1512(ra) # 80003b6e <writei>
    8000115e:	bfb1                	j	800010ba <vmaunmap+0x56>
}
    80001160:	60a6                	ld	ra,72(sp)
    80001162:	6406                	ld	s0,64(sp)
    80001164:	74e2                	ld	s1,56(sp)
    80001166:	7942                	ld	s2,48(sp)
    80001168:	79a2                	ld	s3,40(sp)
    8000116a:	7a02                	ld	s4,32(sp)
    8000116c:	6ae2                	ld	s5,24(sp)
    8000116e:	6b42                	ld	s6,16(sp)
    80001170:	6ba2                	ld	s7,8(sp)
    80001172:	6c02                	ld	s8,0(sp)
    80001174:	6161                	addi	sp,sp,80
    80001176:	8082                	ret

0000000080001178 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001178:	57fd                	li	a5,-1
    8000117a:	83e9                	srli	a5,a5,0x1a
    8000117c:	00b7f463          	bgeu	a5,a1,80001184 <walkaddr+0xc>
    return 0;
    80001180:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001182:	8082                	ret
{
    80001184:	1141                	addi	sp,sp,-16
    80001186:	e406                	sd	ra,8(sp)
    80001188:	e022                	sd	s0,0(sp)
    8000118a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000118c:	4601                	li	a2,0
    8000118e:	00000097          	auipc	ra,0x0
    80001192:	e30080e7          	jalr	-464(ra) # 80000fbe <walk>
  if(pte == 0)
    80001196:	c105                	beqz	a0,800011b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001198:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000119a:	0117f693          	andi	a3,a5,17
    8000119e:	4745                	li	a4,17
    return 0;
    800011a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011a2:	00e68663          	beq	a3,a4,800011ae <walkaddr+0x36>
}
    800011a6:	60a2                	ld	ra,8(sp)
    800011a8:	6402                	ld	s0,0(sp)
    800011aa:	0141                	addi	sp,sp,16
    800011ac:	8082                	ret
  pa = PTE2PA(*pte);
    800011ae:	00a7d513          	srli	a0,a5,0xa
    800011b2:	0532                	slli	a0,a0,0xc
  return pa;
    800011b4:	bfcd                	j	800011a6 <walkaddr+0x2e>
    return 0;
    800011b6:	4501                	li	a0,0
    800011b8:	b7fd                	j	800011a6 <walkaddr+0x2e>

00000000800011ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ba:	715d                	addi	sp,sp,-80
    800011bc:	e486                	sd	ra,72(sp)
    800011be:	e0a2                	sd	s0,64(sp)
    800011c0:	fc26                	sd	s1,56(sp)
    800011c2:	f84a                	sd	s2,48(sp)
    800011c4:	f44e                	sd	s3,40(sp)
    800011c6:	f052                	sd	s4,32(sp)
    800011c8:	ec56                	sd	s5,24(sp)
    800011ca:	e85a                	sd	s6,16(sp)
    800011cc:	e45e                	sd	s7,8(sp)
    800011ce:	0880                	addi	s0,sp,80
    800011d0:	8aaa                	mv	s5,a0
    800011d2:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011d4:	777d                	lui	a4,0xfffff
    800011d6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011da:	167d                	addi	a2,a2,-1
    800011dc:	00b609b3          	add	s3,a2,a1
    800011e0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011e4:	893e                	mv	s2,a5
    800011e6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011ea:	6b85                	lui	s7,0x1
    800011ec:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011f0:	4605                	li	a2,1
    800011f2:	85ca                	mv	a1,s2
    800011f4:	8556                	mv	a0,s5
    800011f6:	00000097          	auipc	ra,0x0
    800011fa:	dc8080e7          	jalr	-568(ra) # 80000fbe <walk>
    800011fe:	c51d                	beqz	a0,8000122c <mappages+0x72>
    if(*pte & PTE_V)
    80001200:	611c                	ld	a5,0(a0)
    80001202:	8b85                	andi	a5,a5,1
    80001204:	ef81                	bnez	a5,8000121c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001206:	80b1                	srli	s1,s1,0xc
    80001208:	04aa                	slli	s1,s1,0xa
    8000120a:	0164e4b3          	or	s1,s1,s6
    8000120e:	0014e493          	ori	s1,s1,1
    80001212:	e104                	sd	s1,0(a0)
    if(a == last)
    80001214:	03390863          	beq	s2,s3,80001244 <mappages+0x8a>
    a += PGSIZE;
    80001218:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000121a:	bfc9                	j	800011ec <mappages+0x32>
      panic("remap");
    8000121c:	00007517          	auipc	a0,0x7
    80001220:	ed450513          	addi	a0,a0,-300 # 800080f0 <digits+0xb0>
    80001224:	fffff097          	auipc	ra,0xfffff
    80001228:	30c080e7          	jalr	780(ra) # 80000530 <panic>
      return -1;
    8000122c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000122e:	60a6                	ld	ra,72(sp)
    80001230:	6406                	ld	s0,64(sp)
    80001232:	74e2                	ld	s1,56(sp)
    80001234:	7942                	ld	s2,48(sp)
    80001236:	79a2                	ld	s3,40(sp)
    80001238:	7a02                	ld	s4,32(sp)
    8000123a:	6ae2                	ld	s5,24(sp)
    8000123c:	6b42                	ld	s6,16(sp)
    8000123e:	6ba2                	ld	s7,8(sp)
    80001240:	6161                	addi	sp,sp,80
    80001242:	8082                	ret
  return 0;
    80001244:	4501                	li	a0,0
    80001246:	b7e5                	j	8000122e <mappages+0x74>

0000000080001248 <kvmmap>:
{
    80001248:	1141                	addi	sp,sp,-16
    8000124a:	e406                	sd	ra,8(sp)
    8000124c:	e022                	sd	s0,0(sp)
    8000124e:	0800                	addi	s0,sp,16
    80001250:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001252:	86b2                	mv	a3,a2
    80001254:	863e                	mv	a2,a5
    80001256:	00000097          	auipc	ra,0x0
    8000125a:	f64080e7          	jalr	-156(ra) # 800011ba <mappages>
    8000125e:	e509                	bnez	a0,80001268 <kvmmap+0x20>
}
    80001260:	60a2                	ld	ra,8(sp)
    80001262:	6402                	ld	s0,0(sp)
    80001264:	0141                	addi	sp,sp,16
    80001266:	8082                	ret
    panic("kvmmap");
    80001268:	00007517          	auipc	a0,0x7
    8000126c:	e9050513          	addi	a0,a0,-368 # 800080f8 <digits+0xb8>
    80001270:	fffff097          	auipc	ra,0xfffff
    80001274:	2c0080e7          	jalr	704(ra) # 80000530 <panic>

0000000080001278 <kvmmake>:
{
    80001278:	1101                	addi	sp,sp,-32
    8000127a:	ec06                	sd	ra,24(sp)
    8000127c:	e822                	sd	s0,16(sp)
    8000127e:	e426                	sd	s1,8(sp)
    80001280:	e04a                	sd	s2,0(sp)
    80001282:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001284:	00000097          	auipc	ra,0x0
    80001288:	862080e7          	jalr	-1950(ra) # 80000ae6 <kalloc>
    8000128c:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000128e:	6605                	lui	a2,0x1
    80001290:	4581                	li	a1,0
    80001292:	00000097          	auipc	ra,0x0
    80001296:	a40080e7          	jalr	-1472(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000129a:	4719                	li	a4,6
    8000129c:	6685                	lui	a3,0x1
    8000129e:	10000637          	lui	a2,0x10000
    800012a2:	100005b7          	lui	a1,0x10000
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	fa0080e7          	jalr	-96(ra) # 80001248 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b0:	4719                	li	a4,6
    800012b2:	6685                	lui	a3,0x1
    800012b4:	10001637          	lui	a2,0x10001
    800012b8:	100015b7          	lui	a1,0x10001
    800012bc:	8526                	mv	a0,s1
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f8a080e7          	jalr	-118(ra) # 80001248 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012c6:	4719                	li	a4,6
    800012c8:	004006b7          	lui	a3,0x400
    800012cc:	0c000637          	lui	a2,0xc000
    800012d0:	0c0005b7          	lui	a1,0xc000
    800012d4:	8526                	mv	a0,s1
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	f72080e7          	jalr	-142(ra) # 80001248 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012de:	00007917          	auipc	s2,0x7
    800012e2:	d2290913          	addi	s2,s2,-734 # 80008000 <etext>
    800012e6:	4729                	li	a4,10
    800012e8:	80007697          	auipc	a3,0x80007
    800012ec:	d1868693          	addi	a3,a3,-744 # 8000 <_entry-0x7fff8000>
    800012f0:	4605                	li	a2,1
    800012f2:	067e                	slli	a2,a2,0x1f
    800012f4:	85b2                	mv	a1,a2
    800012f6:	8526                	mv	a0,s1
    800012f8:	00000097          	auipc	ra,0x0
    800012fc:	f50080e7          	jalr	-176(ra) # 80001248 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001300:	4719                	li	a4,6
    80001302:	46c5                	li	a3,17
    80001304:	06ee                	slli	a3,a3,0x1b
    80001306:	412686b3          	sub	a3,a3,s2
    8000130a:	864a                	mv	a2,s2
    8000130c:	85ca                	mv	a1,s2
    8000130e:	8526                	mv	a0,s1
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f38080e7          	jalr	-200(ra) # 80001248 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001318:	4729                	li	a4,10
    8000131a:	6685                	lui	a3,0x1
    8000131c:	00006617          	auipc	a2,0x6
    80001320:	ce460613          	addi	a2,a2,-796 # 80007000 <_trampoline>
    80001324:	040005b7          	lui	a1,0x4000
    80001328:	15fd                	addi	a1,a1,-1
    8000132a:	05b2                	slli	a1,a1,0xc
    8000132c:	8526                	mv	a0,s1
    8000132e:	00000097          	auipc	ra,0x0
    80001332:	f1a080e7          	jalr	-230(ra) # 80001248 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001336:	8526                	mv	a0,s1
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	642080e7          	jalr	1602(ra) # 8000197a <proc_mapstacks>
}
    80001340:	8526                	mv	a0,s1
    80001342:	60e2                	ld	ra,24(sp)
    80001344:	6442                	ld	s0,16(sp)
    80001346:	64a2                	ld	s1,8(sp)
    80001348:	6902                	ld	s2,0(sp)
    8000134a:	6105                	addi	sp,sp,32
    8000134c:	8082                	ret

000000008000134e <kvminit>:
{
    8000134e:	1141                	addi	sp,sp,-16
    80001350:	e406                	sd	ra,8(sp)
    80001352:	e022                	sd	s0,0(sp)
    80001354:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001356:	00000097          	auipc	ra,0x0
    8000135a:	f22080e7          	jalr	-222(ra) # 80001278 <kvmmake>
    8000135e:	00008797          	auipc	a5,0x8
    80001362:	cca7b123          	sd	a0,-830(a5) # 80009020 <kernel_pagetable>
}
    80001366:	60a2                	ld	ra,8(sp)
    80001368:	6402                	ld	s0,0(sp)
    8000136a:	0141                	addi	sp,sp,16
    8000136c:	8082                	ret

000000008000136e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000136e:	715d                	addi	sp,sp,-80
    80001370:	e486                	sd	ra,72(sp)
    80001372:	e0a2                	sd	s0,64(sp)
    80001374:	fc26                	sd	s1,56(sp)
    80001376:	f84a                	sd	s2,48(sp)
    80001378:	f44e                	sd	s3,40(sp)
    8000137a:	f052                	sd	s4,32(sp)
    8000137c:	ec56                	sd	s5,24(sp)
    8000137e:	e85a                	sd	s6,16(sp)
    80001380:	e45e                	sd	s7,8(sp)
    80001382:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001384:	03459793          	slli	a5,a1,0x34
    80001388:	e795                	bnez	a5,800013b4 <uvmunmap+0x46>
    8000138a:	8a2a                	mv	s4,a0
    8000138c:	892e                	mv	s2,a1
    8000138e:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001390:	0632                	slli	a2,a2,0xc
    80001392:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001396:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001398:	6b05                	lui	s6,0x1
    8000139a:	0735e863          	bltu	a1,s3,8000140a <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000139e:	60a6                	ld	ra,72(sp)
    800013a0:	6406                	ld	s0,64(sp)
    800013a2:	74e2                	ld	s1,56(sp)
    800013a4:	7942                	ld	s2,48(sp)
    800013a6:	79a2                	ld	s3,40(sp)
    800013a8:	7a02                	ld	s4,32(sp)
    800013aa:	6ae2                	ld	s5,24(sp)
    800013ac:	6b42                	ld	s6,16(sp)
    800013ae:	6ba2                	ld	s7,8(sp)
    800013b0:	6161                	addi	sp,sp,80
    800013b2:	8082                	ret
    panic("uvmunmap: not aligned");
    800013b4:	00007517          	auipc	a0,0x7
    800013b8:	d4c50513          	addi	a0,a0,-692 # 80008100 <digits+0xc0>
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	174080e7          	jalr	372(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800013c4:	00007517          	auipc	a0,0x7
    800013c8:	d5450513          	addi	a0,a0,-684 # 80008118 <digits+0xd8>
    800013cc:	fffff097          	auipc	ra,0xfffff
    800013d0:	164080e7          	jalr	356(ra) # 80000530 <panic>
      panic("uvmunmap: not mapped");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d5450513          	addi	a0,a0,-684 # 80008128 <digits+0xe8>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	154080e7          	jalr	340(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf");
    800013e4:	00007517          	auipc	a0,0x7
    800013e8:	d5c50513          	addi	a0,a0,-676 # 80008140 <digits+0x100>
    800013ec:	fffff097          	auipc	ra,0xfffff
    800013f0:	144080e7          	jalr	324(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    800013f4:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013f6:	0532                	slli	a0,a0,0xc
    800013f8:	fffff097          	auipc	ra,0xfffff
    800013fc:	5f2080e7          	jalr	1522(ra) # 800009ea <kfree>
    *pte = 0;
    80001400:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001404:	995a                	add	s2,s2,s6
    80001406:	f9397ce3          	bgeu	s2,s3,8000139e <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000140a:	4601                	li	a2,0
    8000140c:	85ca                	mv	a1,s2
    8000140e:	8552                	mv	a0,s4
    80001410:	00000097          	auipc	ra,0x0
    80001414:	bae080e7          	jalr	-1106(ra) # 80000fbe <walk>
    80001418:	84aa                	mv	s1,a0
    8000141a:	d54d                	beqz	a0,800013c4 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000141c:	6108                	ld	a0,0(a0)
    8000141e:	00157793          	andi	a5,a0,1
    80001422:	dbcd                	beqz	a5,800013d4 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001424:	3ff57793          	andi	a5,a0,1023
    80001428:	fb778ee3          	beq	a5,s7,800013e4 <uvmunmap+0x76>
    if(do_free){
    8000142c:	fc0a8ae3          	beqz	s5,80001400 <uvmunmap+0x92>
    80001430:	b7d1                	j	800013f4 <uvmunmap+0x86>

0000000080001432 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000143c:	fffff097          	auipc	ra,0xfffff
    80001440:	6aa080e7          	jalr	1706(ra) # 80000ae6 <kalloc>
    80001444:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001446:	c519                	beqz	a0,80001454 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001448:	6605                	lui	a2,0x1
    8000144a:	4581                	li	a1,0
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	886080e7          	jalr	-1914(ra) # 80000cd2 <memset>
  return pagetable;
}
    80001454:	8526                	mv	a0,s1
    80001456:	60e2                	ld	ra,24(sp)
    80001458:	6442                	ld	s0,16(sp)
    8000145a:	64a2                	ld	s1,8(sp)
    8000145c:	6105                	addi	sp,sp,32
    8000145e:	8082                	ret

0000000080001460 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001460:	7179                	addi	sp,sp,-48
    80001462:	f406                	sd	ra,40(sp)
    80001464:	f022                	sd	s0,32(sp)
    80001466:	ec26                	sd	s1,24(sp)
    80001468:	e84a                	sd	s2,16(sp)
    8000146a:	e44e                	sd	s3,8(sp)
    8000146c:	e052                	sd	s4,0(sp)
    8000146e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001470:	6785                	lui	a5,0x1
    80001472:	04f67863          	bgeu	a2,a5,800014c2 <uvminit+0x62>
    80001476:	8a2a                	mv	s4,a0
    80001478:	89ae                	mv	s3,a1
    8000147a:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    8000147c:	fffff097          	auipc	ra,0xfffff
    80001480:	66a080e7          	jalr	1642(ra) # 80000ae6 <kalloc>
    80001484:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001486:	6605                	lui	a2,0x1
    80001488:	4581                	li	a1,0
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	848080e7          	jalr	-1976(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001492:	4779                	li	a4,30
    80001494:	86ca                	mv	a3,s2
    80001496:	6605                	lui	a2,0x1
    80001498:	4581                	li	a1,0
    8000149a:	8552                	mv	a0,s4
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	d1e080e7          	jalr	-738(ra) # 800011ba <mappages>
  memmove(mem, src, sz);
    800014a4:	8626                	mv	a2,s1
    800014a6:	85ce                	mv	a1,s3
    800014a8:	854a                	mv	a0,s2
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	888080e7          	jalr	-1912(ra) # 80000d32 <memmove>
}
    800014b2:	70a2                	ld	ra,40(sp)
    800014b4:	7402                	ld	s0,32(sp)
    800014b6:	64e2                	ld	s1,24(sp)
    800014b8:	6942                	ld	s2,16(sp)
    800014ba:	69a2                	ld	s3,8(sp)
    800014bc:	6a02                	ld	s4,0(sp)
    800014be:	6145                	addi	sp,sp,48
    800014c0:	8082                	ret
    panic("inituvm: more than a page");
    800014c2:	00007517          	auipc	a0,0x7
    800014c6:	c9650513          	addi	a0,a0,-874 # 80008158 <digits+0x118>
    800014ca:	fffff097          	auipc	ra,0xfffff
    800014ce:	066080e7          	jalr	102(ra) # 80000530 <panic>

00000000800014d2 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014d2:	1101                	addi	sp,sp,-32
    800014d4:	ec06                	sd	ra,24(sp)
    800014d6:	e822                	sd	s0,16(sp)
    800014d8:	e426                	sd	s1,8(sp)
    800014da:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014dc:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014de:	00b67d63          	bgeu	a2,a1,800014f8 <uvmdealloc+0x26>
    800014e2:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014e4:	6785                	lui	a5,0x1
    800014e6:	17fd                	addi	a5,a5,-1
    800014e8:	00f60733          	add	a4,a2,a5
    800014ec:	767d                	lui	a2,0xfffff
    800014ee:	8f71                	and	a4,a4,a2
    800014f0:	97ae                	add	a5,a5,a1
    800014f2:	8ff1                	and	a5,a5,a2
    800014f4:	00f76863          	bltu	a4,a5,80001504 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014f8:	8526                	mv	a0,s1
    800014fa:	60e2                	ld	ra,24(sp)
    800014fc:	6442                	ld	s0,16(sp)
    800014fe:	64a2                	ld	s1,8(sp)
    80001500:	6105                	addi	sp,sp,32
    80001502:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001504:	8f99                	sub	a5,a5,a4
    80001506:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001508:	4685                	li	a3,1
    8000150a:	0007861b          	sext.w	a2,a5
    8000150e:	85ba                	mv	a1,a4
    80001510:	00000097          	auipc	ra,0x0
    80001514:	e5e080e7          	jalr	-418(ra) # 8000136e <uvmunmap>
    80001518:	b7c5                	j	800014f8 <uvmdealloc+0x26>

000000008000151a <uvmalloc>:
  if(newsz < oldsz)
    8000151a:	0ab66163          	bltu	a2,a1,800015bc <uvmalloc+0xa2>
{
    8000151e:	7139                	addi	sp,sp,-64
    80001520:	fc06                	sd	ra,56(sp)
    80001522:	f822                	sd	s0,48(sp)
    80001524:	f426                	sd	s1,40(sp)
    80001526:	f04a                	sd	s2,32(sp)
    80001528:	ec4e                	sd	s3,24(sp)
    8000152a:	e852                	sd	s4,16(sp)
    8000152c:	e456                	sd	s5,8(sp)
    8000152e:	0080                	addi	s0,sp,64
    80001530:	8aaa                	mv	s5,a0
    80001532:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001534:	6985                	lui	s3,0x1
    80001536:	19fd                	addi	s3,s3,-1
    80001538:	95ce                	add	a1,a1,s3
    8000153a:	79fd                	lui	s3,0xfffff
    8000153c:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001540:	08c9f063          	bgeu	s3,a2,800015c0 <uvmalloc+0xa6>
    80001544:	894e                	mv	s2,s3
    mem = kalloc();
    80001546:	fffff097          	auipc	ra,0xfffff
    8000154a:	5a0080e7          	jalr	1440(ra) # 80000ae6 <kalloc>
    8000154e:	84aa                	mv	s1,a0
    if(mem == 0){
    80001550:	c51d                	beqz	a0,8000157e <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001552:	6605                	lui	a2,0x1
    80001554:	4581                	li	a1,0
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	77c080e7          	jalr	1916(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000155e:	4779                	li	a4,30
    80001560:	86a6                	mv	a3,s1
    80001562:	6605                	lui	a2,0x1
    80001564:	85ca                	mv	a1,s2
    80001566:	8556                	mv	a0,s5
    80001568:	00000097          	auipc	ra,0x0
    8000156c:	c52080e7          	jalr	-942(ra) # 800011ba <mappages>
    80001570:	e905                	bnez	a0,800015a0 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001572:	6785                	lui	a5,0x1
    80001574:	993e                	add	s2,s2,a5
    80001576:	fd4968e3          	bltu	s2,s4,80001546 <uvmalloc+0x2c>
  return newsz;
    8000157a:	8552                	mv	a0,s4
    8000157c:	a809                	j	8000158e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000157e:	864e                	mv	a2,s3
    80001580:	85ca                	mv	a1,s2
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	f4e080e7          	jalr	-178(ra) # 800014d2 <uvmdealloc>
      return 0;
    8000158c:	4501                	li	a0,0
}
    8000158e:	70e2                	ld	ra,56(sp)
    80001590:	7442                	ld	s0,48(sp)
    80001592:	74a2                	ld	s1,40(sp)
    80001594:	7902                	ld	s2,32(sp)
    80001596:	69e2                	ld	s3,24(sp)
    80001598:	6a42                	ld	s4,16(sp)
    8000159a:	6aa2                	ld	s5,8(sp)
    8000159c:	6121                	addi	sp,sp,64
    8000159e:	8082                	ret
      kfree(mem);
    800015a0:	8526                	mv	a0,s1
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	448080e7          	jalr	1096(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015aa:	864e                	mv	a2,s3
    800015ac:	85ca                	mv	a1,s2
    800015ae:	8556                	mv	a0,s5
    800015b0:	00000097          	auipc	ra,0x0
    800015b4:	f22080e7          	jalr	-222(ra) # 800014d2 <uvmdealloc>
      return 0;
    800015b8:	4501                	li	a0,0
    800015ba:	bfd1                	j	8000158e <uvmalloc+0x74>
    return oldsz;
    800015bc:	852e                	mv	a0,a1
}
    800015be:	8082                	ret
  return newsz;
    800015c0:	8532                	mv	a0,a2
    800015c2:	b7f1                	j	8000158e <uvmalloc+0x74>

00000000800015c4 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015c4:	7179                	addi	sp,sp,-48
    800015c6:	f406                	sd	ra,40(sp)
    800015c8:	f022                	sd	s0,32(sp)
    800015ca:	ec26                	sd	s1,24(sp)
    800015cc:	e84a                	sd	s2,16(sp)
    800015ce:	e44e                	sd	s3,8(sp)
    800015d0:	e052                	sd	s4,0(sp)
    800015d2:	1800                	addi	s0,sp,48
    800015d4:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015d6:	84aa                	mv	s1,a0
    800015d8:	6905                	lui	s2,0x1
    800015da:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015dc:	4985                	li	s3,1
    800015de:	a821                	j	800015f6 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e0:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e2:	0532                	slli	a0,a0,0xc
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	fe0080e7          	jalr	-32(ra) # 800015c4 <freewalk>
      pagetable[i] = 0;
    800015ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015f0:	04a1                	addi	s1,s1,8
    800015f2:	03248163          	beq	s1,s2,80001614 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015f6:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015f8:	00f57793          	andi	a5,a0,15
    800015fc:	ff3782e3          	beq	a5,s3,800015e0 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001600:	8905                	andi	a0,a0,1
    80001602:	d57d                	beqz	a0,800015f0 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001604:	00007517          	auipc	a0,0x7
    80001608:	b7450513          	addi	a0,a0,-1164 # 80008178 <digits+0x138>
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	f24080e7          	jalr	-220(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    80001614:	8552                	mv	a0,s4
    80001616:	fffff097          	auipc	ra,0xfffff
    8000161a:	3d4080e7          	jalr	980(ra) # 800009ea <kfree>
}
    8000161e:	70a2                	ld	ra,40(sp)
    80001620:	7402                	ld	s0,32(sp)
    80001622:	64e2                	ld	s1,24(sp)
    80001624:	6942                	ld	s2,16(sp)
    80001626:	69a2                	ld	s3,8(sp)
    80001628:	6a02                	ld	s4,0(sp)
    8000162a:	6145                	addi	sp,sp,48
    8000162c:	8082                	ret

000000008000162e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000162e:	1101                	addi	sp,sp,-32
    80001630:	ec06                	sd	ra,24(sp)
    80001632:	e822                	sd	s0,16(sp)
    80001634:	e426                	sd	s1,8(sp)
    80001636:	1000                	addi	s0,sp,32
    80001638:	84aa                	mv	s1,a0
  if(sz > 0)
    8000163a:	e999                	bnez	a1,80001650 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000163c:	8526                	mv	a0,s1
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	f86080e7          	jalr	-122(ra) # 800015c4 <freewalk>
}
    80001646:	60e2                	ld	ra,24(sp)
    80001648:	6442                	ld	s0,16(sp)
    8000164a:	64a2                	ld	s1,8(sp)
    8000164c:	6105                	addi	sp,sp,32
    8000164e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001650:	6605                	lui	a2,0x1
    80001652:	167d                	addi	a2,a2,-1
    80001654:	962e                	add	a2,a2,a1
    80001656:	4685                	li	a3,1
    80001658:	8231                	srli	a2,a2,0xc
    8000165a:	4581                	li	a1,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	d12080e7          	jalr	-750(ra) # 8000136e <uvmunmap>
    80001664:	bfe1                	j	8000163c <uvmfree+0xe>

0000000080001666 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001666:	c679                	beqz	a2,80001734 <uvmcopy+0xce>
{
    80001668:	715d                	addi	sp,sp,-80
    8000166a:	e486                	sd	ra,72(sp)
    8000166c:	e0a2                	sd	s0,64(sp)
    8000166e:	fc26                	sd	s1,56(sp)
    80001670:	f84a                	sd	s2,48(sp)
    80001672:	f44e                	sd	s3,40(sp)
    80001674:	f052                	sd	s4,32(sp)
    80001676:	ec56                	sd	s5,24(sp)
    80001678:	e85a                	sd	s6,16(sp)
    8000167a:	e45e                	sd	s7,8(sp)
    8000167c:	0880                	addi	s0,sp,80
    8000167e:	8b2a                	mv	s6,a0
    80001680:	8aae                	mv	s5,a1
    80001682:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001684:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001686:	4601                	li	a2,0
    80001688:	85ce                	mv	a1,s3
    8000168a:	855a                	mv	a0,s6
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	932080e7          	jalr	-1742(ra) # 80000fbe <walk>
    80001694:	c531                	beqz	a0,800016e0 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001696:	6118                	ld	a4,0(a0)
    80001698:	00177793          	andi	a5,a4,1
    8000169c:	cbb1                	beqz	a5,800016f0 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000169e:	00a75593          	srli	a1,a4,0xa
    800016a2:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016a6:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016aa:	fffff097          	auipc	ra,0xfffff
    800016ae:	43c080e7          	jalr	1084(ra) # 80000ae6 <kalloc>
    800016b2:	892a                	mv	s2,a0
    800016b4:	c939                	beqz	a0,8000170a <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016b6:	6605                	lui	a2,0x1
    800016b8:	85de                	mv	a1,s7
    800016ba:	fffff097          	auipc	ra,0xfffff
    800016be:	678080e7          	jalr	1656(ra) # 80000d32 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016c2:	8726                	mv	a4,s1
    800016c4:	86ca                	mv	a3,s2
    800016c6:	6605                	lui	a2,0x1
    800016c8:	85ce                	mv	a1,s3
    800016ca:	8556                	mv	a0,s5
    800016cc:	00000097          	auipc	ra,0x0
    800016d0:	aee080e7          	jalr	-1298(ra) # 800011ba <mappages>
    800016d4:	e515                	bnez	a0,80001700 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016d6:	6785                	lui	a5,0x1
    800016d8:	99be                	add	s3,s3,a5
    800016da:	fb49e6e3          	bltu	s3,s4,80001686 <uvmcopy+0x20>
    800016de:	a081                	j	8000171e <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016e0:	00007517          	auipc	a0,0x7
    800016e4:	aa850513          	addi	a0,a0,-1368 # 80008188 <digits+0x148>
    800016e8:	fffff097          	auipc	ra,0xfffff
    800016ec:	e48080e7          	jalr	-440(ra) # 80000530 <panic>
      panic("uvmcopy: page not present");
    800016f0:	00007517          	auipc	a0,0x7
    800016f4:	ab850513          	addi	a0,a0,-1352 # 800081a8 <digits+0x168>
    800016f8:	fffff097          	auipc	ra,0xfffff
    800016fc:	e38080e7          	jalr	-456(ra) # 80000530 <panic>
      kfree(mem);
    80001700:	854a                	mv	a0,s2
    80001702:	fffff097          	auipc	ra,0xfffff
    80001706:	2e8080e7          	jalr	744(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000170a:	4685                	li	a3,1
    8000170c:	00c9d613          	srli	a2,s3,0xc
    80001710:	4581                	li	a1,0
    80001712:	8556                	mv	a0,s5
    80001714:	00000097          	auipc	ra,0x0
    80001718:	c5a080e7          	jalr	-934(ra) # 8000136e <uvmunmap>
  return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6161                	addi	sp,sp,80
    80001732:	8082                	ret
  return 0;
    80001734:	4501                	li	a0,0
}
    80001736:	8082                	ret

0000000080001738 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001738:	1141                	addi	sp,sp,-16
    8000173a:	e406                	sd	ra,8(sp)
    8000173c:	e022                	sd	s0,0(sp)
    8000173e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001740:	4601                	li	a2,0
    80001742:	00000097          	auipc	ra,0x0
    80001746:	87c080e7          	jalr	-1924(ra) # 80000fbe <walk>
  if(pte == 0)
    8000174a:	c901                	beqz	a0,8000175a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000174c:	611c                	ld	a5,0(a0)
    8000174e:	9bbd                	andi	a5,a5,-17
    80001750:	e11c                	sd	a5,0(a0)
}
    80001752:	60a2                	ld	ra,8(sp)
    80001754:	6402                	ld	s0,0(sp)
    80001756:	0141                	addi	sp,sp,16
    80001758:	8082                	ret
    panic("uvmclear");
    8000175a:	00007517          	auipc	a0,0x7
    8000175e:	a6e50513          	addi	a0,a0,-1426 # 800081c8 <digits+0x188>
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	dce080e7          	jalr	-562(ra) # 80000530 <panic>

000000008000176a <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176a:	c6bd                	beqz	a3,800017d8 <copyout+0x6e>
{
    8000176c:	715d                	addi	sp,sp,-80
    8000176e:	e486                	sd	ra,72(sp)
    80001770:	e0a2                	sd	s0,64(sp)
    80001772:	fc26                	sd	s1,56(sp)
    80001774:	f84a                	sd	s2,48(sp)
    80001776:	f44e                	sd	s3,40(sp)
    80001778:	f052                	sd	s4,32(sp)
    8000177a:	ec56                	sd	s5,24(sp)
    8000177c:	e85a                	sd	s6,16(sp)
    8000177e:	e45e                	sd	s7,8(sp)
    80001780:	e062                	sd	s8,0(sp)
    80001782:	0880                	addi	s0,sp,80
    80001784:	8b2a                	mv	s6,a0
    80001786:	8c2e                	mv	s8,a1
    80001788:	8a32                	mv	s4,a2
    8000178a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000178c:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000178e:	6a85                	lui	s5,0x1
    80001790:	a015                	j	800017b4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001792:	9562                	add	a0,a0,s8
    80001794:	0004861b          	sext.w	a2,s1
    80001798:	85d2                	mv	a1,s4
    8000179a:	41250533          	sub	a0,a0,s2
    8000179e:	fffff097          	auipc	ra,0xfffff
    800017a2:	594080e7          	jalr	1428(ra) # 80000d32 <memmove>

    len -= n;
    800017a6:	409989b3          	sub	s3,s3,s1
    src += n;
    800017aa:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800017ac:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b0:	02098263          	beqz	s3,800017d4 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017b4:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017b8:	85ca                	mv	a1,s2
    800017ba:	855a                	mv	a0,s6
    800017bc:	00000097          	auipc	ra,0x0
    800017c0:	9bc080e7          	jalr	-1604(ra) # 80001178 <walkaddr>
    if(pa0 == 0)
    800017c4:	cd01                	beqz	a0,800017dc <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017c6:	418904b3          	sub	s1,s2,s8
    800017ca:	94d6                	add	s1,s1,s5
    if(n > len)
    800017cc:	fc99f3e3          	bgeu	s3,s1,80001792 <copyout+0x28>
    800017d0:	84ce                	mv	s1,s3
    800017d2:	b7c1                	j	80001792 <copyout+0x28>
  }
  return 0;
    800017d4:	4501                	li	a0,0
    800017d6:	a021                	j	800017de <copyout+0x74>
    800017d8:	4501                	li	a0,0
}
    800017da:	8082                	ret
      return -1;
    800017dc:	557d                	li	a0,-1
}
    800017de:	60a6                	ld	ra,72(sp)
    800017e0:	6406                	ld	s0,64(sp)
    800017e2:	74e2                	ld	s1,56(sp)
    800017e4:	7942                	ld	s2,48(sp)
    800017e6:	79a2                	ld	s3,40(sp)
    800017e8:	7a02                	ld	s4,32(sp)
    800017ea:	6ae2                	ld	s5,24(sp)
    800017ec:	6b42                	ld	s6,16(sp)
    800017ee:	6ba2                	ld	s7,8(sp)
    800017f0:	6c02                	ld	s8,0(sp)
    800017f2:	6161                	addi	sp,sp,80
    800017f4:	8082                	ret

00000000800017f6 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017f6:	c6bd                	beqz	a3,80001864 <copyin+0x6e>
{
    800017f8:	715d                	addi	sp,sp,-80
    800017fa:	e486                	sd	ra,72(sp)
    800017fc:	e0a2                	sd	s0,64(sp)
    800017fe:	fc26                	sd	s1,56(sp)
    80001800:	f84a                	sd	s2,48(sp)
    80001802:	f44e                	sd	s3,40(sp)
    80001804:	f052                	sd	s4,32(sp)
    80001806:	ec56                	sd	s5,24(sp)
    80001808:	e85a                	sd	s6,16(sp)
    8000180a:	e45e                	sd	s7,8(sp)
    8000180c:	e062                	sd	s8,0(sp)
    8000180e:	0880                	addi	s0,sp,80
    80001810:	8b2a                	mv	s6,a0
    80001812:	8a2e                	mv	s4,a1
    80001814:	8c32                	mv	s8,a2
    80001816:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001818:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181a:	6a85                	lui	s5,0x1
    8000181c:	a015                	j	80001840 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000181e:	9562                	add	a0,a0,s8
    80001820:	0004861b          	sext.w	a2,s1
    80001824:	412505b3          	sub	a1,a0,s2
    80001828:	8552                	mv	a0,s4
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	508080e7          	jalr	1288(ra) # 80000d32 <memmove>

    len -= n;
    80001832:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001836:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001838:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000183c:	02098263          	beqz	s3,80001860 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001840:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001844:	85ca                	mv	a1,s2
    80001846:	855a                	mv	a0,s6
    80001848:	00000097          	auipc	ra,0x0
    8000184c:	930080e7          	jalr	-1744(ra) # 80001178 <walkaddr>
    if(pa0 == 0)
    80001850:	cd01                	beqz	a0,80001868 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001852:	418904b3          	sub	s1,s2,s8
    80001856:	94d6                	add	s1,s1,s5
    if(n > len)
    80001858:	fc99f3e3          	bgeu	s3,s1,8000181e <copyin+0x28>
    8000185c:	84ce                	mv	s1,s3
    8000185e:	b7c1                	j	8000181e <copyin+0x28>
  }
  return 0;
    80001860:	4501                	li	a0,0
    80001862:	a021                	j	8000186a <copyin+0x74>
    80001864:	4501                	li	a0,0
}
    80001866:	8082                	ret
      return -1;
    80001868:	557d                	li	a0,-1
}
    8000186a:	60a6                	ld	ra,72(sp)
    8000186c:	6406                	ld	s0,64(sp)
    8000186e:	74e2                	ld	s1,56(sp)
    80001870:	7942                	ld	s2,48(sp)
    80001872:	79a2                	ld	s3,40(sp)
    80001874:	7a02                	ld	s4,32(sp)
    80001876:	6ae2                	ld	s5,24(sp)
    80001878:	6b42                	ld	s6,16(sp)
    8000187a:	6ba2                	ld	s7,8(sp)
    8000187c:	6c02                	ld	s8,0(sp)
    8000187e:	6161                	addi	sp,sp,80
    80001880:	8082                	ret

0000000080001882 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001882:	c6c5                	beqz	a3,8000192a <copyinstr+0xa8>
{
    80001884:	715d                	addi	sp,sp,-80
    80001886:	e486                	sd	ra,72(sp)
    80001888:	e0a2                	sd	s0,64(sp)
    8000188a:	fc26                	sd	s1,56(sp)
    8000188c:	f84a                	sd	s2,48(sp)
    8000188e:	f44e                	sd	s3,40(sp)
    80001890:	f052                	sd	s4,32(sp)
    80001892:	ec56                	sd	s5,24(sp)
    80001894:	e85a                	sd	s6,16(sp)
    80001896:	e45e                	sd	s7,8(sp)
    80001898:	0880                	addi	s0,sp,80
    8000189a:	8a2a                	mv	s4,a0
    8000189c:	8b2e                	mv	s6,a1
    8000189e:	8bb2                	mv	s7,a2
    800018a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800018a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018a4:	6985                	lui	s3,0x1
    800018a6:	a035                	j	800018d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800018a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800018ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800018ae:	0017b793          	seqz	a5,a5
    800018b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800018b6:	60a6                	ld	ra,72(sp)
    800018b8:	6406                	ld	s0,64(sp)
    800018ba:	74e2                	ld	s1,56(sp)
    800018bc:	7942                	ld	s2,48(sp)
    800018be:	79a2                	ld	s3,40(sp)
    800018c0:	7a02                	ld	s4,32(sp)
    800018c2:	6ae2                	ld	s5,24(sp)
    800018c4:	6b42                	ld	s6,16(sp)
    800018c6:	6ba2                	ld	s7,8(sp)
    800018c8:	6161                	addi	sp,sp,80
    800018ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800018cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018d0:	c8a9                	beqz	s1,80001922 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018d6:	85ca                	mv	a1,s2
    800018d8:	8552                	mv	a0,s4
    800018da:	00000097          	auipc	ra,0x0
    800018de:	89e080e7          	jalr	-1890(ra) # 80001178 <walkaddr>
    if(pa0 == 0)
    800018e2:	c131                	beqz	a0,80001926 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018e4:	41790833          	sub	a6,s2,s7
    800018e8:	984e                	add	a6,a6,s3
    if(n > max)
    800018ea:	0104f363          	bgeu	s1,a6,800018f0 <copyinstr+0x6e>
    800018ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018f0:	955e                	add	a0,a0,s7
    800018f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018f6:	fc080be3          	beqz	a6,800018cc <copyinstr+0x4a>
    800018fa:	985a                	add	a6,a6,s6
    800018fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018fe:	41650633          	sub	a2,a0,s6
    80001902:	14fd                	addi	s1,s1,-1
    80001904:	9b26                	add	s6,s6,s1
    80001906:	00f60733          	add	a4,a2,a5
    8000190a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffcd000>
    8000190e:	df49                	beqz	a4,800018a8 <copyinstr+0x26>
        *dst = *p;
    80001910:	00e78023          	sb	a4,0(a5)
      --max;
    80001914:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001918:	0785                	addi	a5,a5,1
    while(n > 0){
    8000191a:	ff0796e3          	bne	a5,a6,80001906 <copyinstr+0x84>
      dst++;
    8000191e:	8b42                	mv	s6,a6
    80001920:	b775                	j	800018cc <copyinstr+0x4a>
    80001922:	4781                	li	a5,0
    80001924:	b769                	j	800018ae <copyinstr+0x2c>
      return -1;
    80001926:	557d                	li	a0,-1
    80001928:	b779                	j	800018b6 <copyinstr+0x34>
  int got_null = 0;
    8000192a:	4781                	li	a5,0
  if(got_null){
    8000192c:	0017b793          	seqz	a5,a5
    80001930:	40f00533          	neg	a0,a5
}
    80001934:	8082                	ret

0000000080001936 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001936:	1101                	addi	sp,sp,-32
    80001938:	ec06                	sd	ra,24(sp)
    8000193a:	e822                	sd	s0,16(sp)
    8000193c:	e426                	sd	s1,8(sp)
    8000193e:	1000                	addi	s0,sp,32
    80001940:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	21a080e7          	jalr	538(ra) # 80000b5c <holding>
    8000194a:	c909                	beqz	a0,8000195c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000194c:	749c                	ld	a5,40(s1)
    8000194e:	00978f63          	beq	a5,s1,8000196c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001952:	60e2                	ld	ra,24(sp)
    80001954:	6442                	ld	s0,16(sp)
    80001956:	64a2                	ld	s1,8(sp)
    80001958:	6105                	addi	sp,sp,32
    8000195a:	8082                	ret
    panic("wakeup1");
    8000195c:	00007517          	auipc	a0,0x7
    80001960:	87c50513          	addi	a0,a0,-1924 # 800081d8 <digits+0x198>
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	bcc080e7          	jalr	-1076(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000196c:	4c98                	lw	a4,24(s1)
    8000196e:	4785                	li	a5,1
    80001970:	fef711e3          	bne	a4,a5,80001952 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001974:	4789                	li	a5,2
    80001976:	cc9c                	sw	a5,24(s1)
}
    80001978:	bfe9                	j	80001952 <wakeup1+0x1c>

000000008000197a <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000197a:	7139                	addi	sp,sp,-64
    8000197c:	fc06                	sd	ra,56(sp)
    8000197e:	f822                	sd	s0,48(sp)
    80001980:	f426                	sd	s1,40(sp)
    80001982:	f04a                	sd	s2,32(sp)
    80001984:	ec4e                	sd	s3,24(sp)
    80001986:	e852                	sd	s4,16(sp)
    80001988:	e456                	sd	s5,8(sp)
    8000198a:	e05a                	sd	s6,0(sp)
    8000198c:	0080                	addi	s0,sp,64
    8000198e:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80001990:	00010497          	auipc	s1,0x10
    80001994:	d2848493          	addi	s1,s1,-728 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    80001998:	8b26                	mv	s6,s1
    8000199a:	00006a97          	auipc	s5,0x6
    8000199e:	666a8a93          	addi	s5,s5,1638 # 80008000 <etext>
    800019a2:	04000937          	lui	s2,0x4000
    800019a6:	197d                	addi	s2,s2,-1
    800019a8:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019aa:	00021a17          	auipc	s4,0x21
    800019ae:	70ea0a13          	addi	s4,s4,1806 # 800230b8 <tickslock>
    char *pa = kalloc();
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	134080e7          	jalr	308(ra) # 80000ae6 <kalloc>
    800019ba:	862a                	mv	a2,a0
    if(pa == 0)
    800019bc:	c131                	beqz	a0,80001a00 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800019be:	416485b3          	sub	a1,s1,s6
    800019c2:	858d                	srai	a1,a1,0x3
    800019c4:	000ab783          	ld	a5,0(s5)
    800019c8:	02f585b3          	mul	a1,a1,a5
    800019cc:	2585                	addiw	a1,a1,1
    800019ce:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019d2:	4719                	li	a4,6
    800019d4:	6685                	lui	a3,0x1
    800019d6:	40b905b3          	sub	a1,s2,a1
    800019da:	854e                	mv	a0,s3
    800019dc:	00000097          	auipc	ra,0x0
    800019e0:	86c080e7          	jalr	-1940(ra) # 80001248 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e4:	46848493          	addi	s1,s1,1128
    800019e8:	fd4495e3          	bne	s1,s4,800019b2 <proc_mapstacks+0x38>
}
    800019ec:	70e2                	ld	ra,56(sp)
    800019ee:	7442                	ld	s0,48(sp)
    800019f0:	74a2                	ld	s1,40(sp)
    800019f2:	7902                	ld	s2,32(sp)
    800019f4:	69e2                	ld	s3,24(sp)
    800019f6:	6a42                	ld	s4,16(sp)
    800019f8:	6aa2                	ld	s5,8(sp)
    800019fa:	6b02                	ld	s6,0(sp)
    800019fc:	6121                	addi	sp,sp,64
    800019fe:	8082                	ret
      panic("kalloc");
    80001a00:	00006517          	auipc	a0,0x6
    80001a04:	7e050513          	addi	a0,a0,2016 # 800081e0 <digits+0x1a0>
    80001a08:	fffff097          	auipc	ra,0xfffff
    80001a0c:	b28080e7          	jalr	-1240(ra) # 80000530 <panic>

0000000080001a10 <procinit>:
{
    80001a10:	7139                	addi	sp,sp,-64
    80001a12:	fc06                	sd	ra,56(sp)
    80001a14:	f822                	sd	s0,48(sp)
    80001a16:	f426                	sd	s1,40(sp)
    80001a18:	f04a                	sd	s2,32(sp)
    80001a1a:	ec4e                	sd	s3,24(sp)
    80001a1c:	e852                	sd	s4,16(sp)
    80001a1e:	e456                	sd	s5,8(sp)
    80001a20:	e05a                	sd	s6,0(sp)
    80001a22:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80001a24:	00006597          	auipc	a1,0x6
    80001a28:	7c458593          	addi	a1,a1,1988 # 800081e8 <digits+0x1a8>
    80001a2c:	00010517          	auipc	a0,0x10
    80001a30:	87450513          	addi	a0,a0,-1932 # 800112a0 <pid_lock>
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	112080e7          	jalr	274(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a3c:	00010497          	auipc	s1,0x10
    80001a40:	c7c48493          	addi	s1,s1,-900 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    80001a44:	00006b17          	auipc	s6,0x6
    80001a48:	7acb0b13          	addi	s6,s6,1964 # 800081f0 <digits+0x1b0>
      p->kstack = KSTACK((int) (p - proc));
    80001a4c:	8aa6                	mv	s5,s1
    80001a4e:	00006a17          	auipc	s4,0x6
    80001a52:	5b2a0a13          	addi	s4,s4,1458 # 80008000 <etext>
    80001a56:	04000937          	lui	s2,0x4000
    80001a5a:	197d                	addi	s2,s2,-1
    80001a5c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5e:	00021997          	auipc	s3,0x21
    80001a62:	65a98993          	addi	s3,s3,1626 # 800230b8 <tickslock>
      initlock(&p->lock, "proc");
    80001a66:	85da                	mv	a1,s6
    80001a68:	8526                	mv	a0,s1
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	0dc080e7          	jalr	220(ra) # 80000b46 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a72:	415487b3          	sub	a5,s1,s5
    80001a76:	878d                	srai	a5,a5,0x3
    80001a78:	000a3703          	ld	a4,0(s4)
    80001a7c:	02e787b3          	mul	a5,a5,a4
    80001a80:	2785                	addiw	a5,a5,1
    80001a82:	00d7979b          	slliw	a5,a5,0xd
    80001a86:	40f907b3          	sub	a5,s2,a5
    80001a8a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a8c:	46848493          	addi	s1,s1,1128
    80001a90:	fd349be3          	bne	s1,s3,80001a66 <procinit+0x56>
}
    80001a94:	70e2                	ld	ra,56(sp)
    80001a96:	7442                	ld	s0,48(sp)
    80001a98:	74a2                	ld	s1,40(sp)
    80001a9a:	7902                	ld	s2,32(sp)
    80001a9c:	69e2                	ld	s3,24(sp)
    80001a9e:	6a42                	ld	s4,16(sp)
    80001aa0:	6aa2                	ld	s5,8(sp)
    80001aa2:	6b02                	ld	s6,0(sp)
    80001aa4:	6121                	addi	sp,sp,64
    80001aa6:	8082                	ret

0000000080001aa8 <cpuid>:
{
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e422                	sd	s0,8(sp)
    80001aac:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aae:	8512                	mv	a0,tp
}
    80001ab0:	2501                	sext.w	a0,a0
    80001ab2:	6422                	ld	s0,8(sp)
    80001ab4:	0141                	addi	sp,sp,16
    80001ab6:	8082                	ret

0000000080001ab8 <mycpu>:
mycpu(void) {
    80001ab8:	1141                	addi	sp,sp,-16
    80001aba:	e422                	sd	s0,8(sp)
    80001abc:	0800                	addi	s0,sp,16
    80001abe:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ac0:	2781                	sext.w	a5,a5
    80001ac2:	079e                	slli	a5,a5,0x7
}
    80001ac4:	0000f517          	auipc	a0,0xf
    80001ac8:	7f450513          	addi	a0,a0,2036 # 800112b8 <cpus>
    80001acc:	953e                	add	a0,a0,a5
    80001ace:	6422                	ld	s0,8(sp)
    80001ad0:	0141                	addi	sp,sp,16
    80001ad2:	8082                	ret

0000000080001ad4 <myproc>:
myproc(void) {
    80001ad4:	1101                	addi	sp,sp,-32
    80001ad6:	ec06                	sd	ra,24(sp)
    80001ad8:	e822                	sd	s0,16(sp)
    80001ada:	e426                	sd	s1,8(sp)
    80001adc:	1000                	addi	s0,sp,32
  push_off();
    80001ade:	fffff097          	auipc	ra,0xfffff
    80001ae2:	0ac080e7          	jalr	172(ra) # 80000b8a <push_off>
    80001ae6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ae8:	2781                	sext.w	a5,a5
    80001aea:	079e                	slli	a5,a5,0x7
    80001aec:	0000f717          	auipc	a4,0xf
    80001af0:	7b470713          	addi	a4,a4,1972 # 800112a0 <pid_lock>
    80001af4:	97ba                	add	a5,a5,a4
    80001af6:	6f84                	ld	s1,24(a5)
  pop_off();
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	132080e7          	jalr	306(ra) # 80000c2a <pop_off>
}
    80001b00:	8526                	mv	a0,s1
    80001b02:	60e2                	ld	ra,24(sp)
    80001b04:	6442                	ld	s0,16(sp)
    80001b06:	64a2                	ld	s1,8(sp)
    80001b08:	6105                	addi	sp,sp,32
    80001b0a:	8082                	ret

0000000080001b0c <forkret>:
{
    80001b0c:	1141                	addi	sp,sp,-16
    80001b0e:	e406                	sd	ra,8(sp)
    80001b10:	e022                	sd	s0,0(sp)
    80001b12:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b14:	00000097          	auipc	ra,0x0
    80001b18:	fc0080e7          	jalr	-64(ra) # 80001ad4 <myproc>
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	16e080e7          	jalr	366(ra) # 80000c8a <release>
  if (first) {
    80001b24:	00007797          	auipc	a5,0x7
    80001b28:	d3c7a783          	lw	a5,-708(a5) # 80008860 <first.1697>
    80001b2c:	eb89                	bnez	a5,80001b3e <forkret+0x32>
  usertrapret();
    80001b2e:	00001097          	auipc	ra,0x1
    80001b32:	cb6080e7          	jalr	-842(ra) # 800027e4 <usertrapret>
}
    80001b36:	60a2                	ld	ra,8(sp)
    80001b38:	6402                	ld	s0,0(sp)
    80001b3a:	0141                	addi	sp,sp,16
    80001b3c:	8082                	ret
    first = 0;
    80001b3e:	00007797          	auipc	a5,0x7
    80001b42:	d207a123          	sw	zero,-734(a5) # 80008860 <first.1697>
    fsinit(ROOTDEV);
    80001b46:	4505                	li	a0,1
    80001b48:	00002097          	auipc	ra,0x2
    80001b4c:	a02080e7          	jalr	-1534(ra) # 8000354a <fsinit>
    80001b50:	bff9                	j	80001b2e <forkret+0x22>

0000000080001b52 <allocpid>:
allocpid() {
    80001b52:	1101                	addi	sp,sp,-32
    80001b54:	ec06                	sd	ra,24(sp)
    80001b56:	e822                	sd	s0,16(sp)
    80001b58:	e426                	sd	s1,8(sp)
    80001b5a:	e04a                	sd	s2,0(sp)
    80001b5c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b5e:	0000f917          	auipc	s2,0xf
    80001b62:	74290913          	addi	s2,s2,1858 # 800112a0 <pid_lock>
    80001b66:	854a                	mv	a0,s2
    80001b68:	fffff097          	auipc	ra,0xfffff
    80001b6c:	06e080e7          	jalr	110(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001b70:	00007797          	auipc	a5,0x7
    80001b74:	cf478793          	addi	a5,a5,-780 # 80008864 <nextpid>
    80001b78:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b7a:	0014871b          	addiw	a4,s1,1
    80001b7e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b80:	854a                	mv	a0,s2
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	108080e7          	jalr	264(ra) # 80000c8a <release>
}
    80001b8a:	8526                	mv	a0,s1
    80001b8c:	60e2                	ld	ra,24(sp)
    80001b8e:	6442                	ld	s0,16(sp)
    80001b90:	64a2                	ld	s1,8(sp)
    80001b92:	6902                	ld	s2,0(sp)
    80001b94:	6105                	addi	sp,sp,32
    80001b96:	8082                	ret

0000000080001b98 <proc_pagetable>:
{
    80001b98:	1101                	addi	sp,sp,-32
    80001b9a:	ec06                	sd	ra,24(sp)
    80001b9c:	e822                	sd	s0,16(sp)
    80001b9e:	e426                	sd	s1,8(sp)
    80001ba0:	e04a                	sd	s2,0(sp)
    80001ba2:	1000                	addi	s0,sp,32
    80001ba4:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	88c080e7          	jalr	-1908(ra) # 80001432 <uvmcreate>
    80001bae:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bb0:	c121                	beqz	a0,80001bf0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bb2:	4729                	li	a4,10
    80001bb4:	00005697          	auipc	a3,0x5
    80001bb8:	44c68693          	addi	a3,a3,1100 # 80007000 <_trampoline>
    80001bbc:	6605                	lui	a2,0x1
    80001bbe:	040005b7          	lui	a1,0x4000
    80001bc2:	15fd                	addi	a1,a1,-1
    80001bc4:	05b2                	slli	a1,a1,0xc
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	5f4080e7          	jalr	1524(ra) # 800011ba <mappages>
    80001bce:	02054863          	bltz	a0,80001bfe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bd2:	4719                	li	a4,6
    80001bd4:	05893683          	ld	a3,88(s2)
    80001bd8:	6605                	lui	a2,0x1
    80001bda:	020005b7          	lui	a1,0x2000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b6                	slli	a1,a1,0xd
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	5d6080e7          	jalr	1494(ra) # 800011ba <mappages>
    80001bec:	02054163          	bltz	a0,80001c0e <proc_pagetable+0x76>
}
    80001bf0:	8526                	mv	a0,s1
    80001bf2:	60e2                	ld	ra,24(sp)
    80001bf4:	6442                	ld	s0,16(sp)
    80001bf6:	64a2                	ld	s1,8(sp)
    80001bf8:	6902                	ld	s2,0(sp)
    80001bfa:	6105                	addi	sp,sp,32
    80001bfc:	8082                	ret
    uvmfree(pagetable, 0);
    80001bfe:	4581                	li	a1,0
    80001c00:	8526                	mv	a0,s1
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	a2c080e7          	jalr	-1492(ra) # 8000162e <uvmfree>
    return 0;
    80001c0a:	4481                	li	s1,0
    80001c0c:	b7d5                	j	80001bf0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c0e:	4681                	li	a3,0
    80001c10:	4605                	li	a2,1
    80001c12:	040005b7          	lui	a1,0x4000
    80001c16:	15fd                	addi	a1,a1,-1
    80001c18:	05b2                	slli	a1,a1,0xc
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	752080e7          	jalr	1874(ra) # 8000136e <uvmunmap>
    uvmfree(pagetable, 0);
    80001c24:	4581                	li	a1,0
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	a06080e7          	jalr	-1530(ra) # 8000162e <uvmfree>
    return 0;
    80001c30:	4481                	li	s1,0
    80001c32:	bf7d                	j	80001bf0 <proc_pagetable+0x58>

0000000080001c34 <proc_freepagetable>:
{
    80001c34:	1101                	addi	sp,sp,-32
    80001c36:	ec06                	sd	ra,24(sp)
    80001c38:	e822                	sd	s0,16(sp)
    80001c3a:	e426                	sd	s1,8(sp)
    80001c3c:	e04a                	sd	s2,0(sp)
    80001c3e:	1000                	addi	s0,sp,32
    80001c40:	84aa                	mv	s1,a0
    80001c42:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c44:	4681                	li	a3,0
    80001c46:	4605                	li	a2,1
    80001c48:	040005b7          	lui	a1,0x4000
    80001c4c:	15fd                	addi	a1,a1,-1
    80001c4e:	05b2                	slli	a1,a1,0xc
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	71e080e7          	jalr	1822(ra) # 8000136e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c58:	4681                	li	a3,0
    80001c5a:	4605                	li	a2,1
    80001c5c:	020005b7          	lui	a1,0x2000
    80001c60:	15fd                	addi	a1,a1,-1
    80001c62:	05b6                	slli	a1,a1,0xd
    80001c64:	8526                	mv	a0,s1
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	708080e7          	jalr	1800(ra) # 8000136e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c6e:	85ca                	mv	a1,s2
    80001c70:	8526                	mv	a0,s1
    80001c72:	00000097          	auipc	ra,0x0
    80001c76:	9bc080e7          	jalr	-1604(ra) # 8000162e <uvmfree>
}
    80001c7a:	60e2                	ld	ra,24(sp)
    80001c7c:	6442                	ld	s0,16(sp)
    80001c7e:	64a2                	ld	s1,8(sp)
    80001c80:	6902                	ld	s2,0(sp)
    80001c82:	6105                	addi	sp,sp,32
    80001c84:	8082                	ret

0000000080001c86 <freeproc>:
{
    80001c86:	7179                	addi	sp,sp,-48
    80001c88:	f406                	sd	ra,40(sp)
    80001c8a:	f022                	sd	s0,32(sp)
    80001c8c:	ec26                	sd	s1,24(sp)
    80001c8e:	e84a                	sd	s2,16(sp)
    80001c90:	e44e                	sd	s3,8(sp)
    80001c92:	1800                	addi	s0,sp,48
    80001c94:	892a                	mv	s2,a0
  if(p->trapframe)
    80001c96:	6d28                	ld	a0,88(a0)
    80001c98:	c509                	beqz	a0,80001ca2 <freeproc+0x1c>
    kfree((void*)p->trapframe);
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	d50080e7          	jalr	-688(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001ca2:	04093c23          	sd	zero,88(s2)
  for(int i = 0; i < NVMA; i++) {
    80001ca6:	16890493          	addi	s1,s2,360
    80001caa:	46890993          	addi	s3,s2,1128
    vmaunmap(p->pagetable, v->vastart, v->sz, v);
    80001cae:	86a6                	mv	a3,s1
    80001cb0:	6890                	ld	a2,16(s1)
    80001cb2:	648c                	ld	a1,8(s1)
    80001cb4:	05093503          	ld	a0,80(s2)
    80001cb8:	fffff097          	auipc	ra,0xfffff
    80001cbc:	3ac080e7          	jalr	940(ra) # 80001064 <vmaunmap>
  for(int i = 0; i < NVMA; i++) {
    80001cc0:	03048493          	addi	s1,s1,48
    80001cc4:	ff3495e3          	bne	s1,s3,80001cae <freeproc+0x28>
  if(p->pagetable)
    80001cc8:	05093503          	ld	a0,80(s2)
    80001ccc:	c519                	beqz	a0,80001cda <freeproc+0x54>
    proc_freepagetable(p->pagetable, p->sz);
    80001cce:	04893583          	ld	a1,72(s2)
    80001cd2:	00000097          	auipc	ra,0x0
    80001cd6:	f62080e7          	jalr	-158(ra) # 80001c34 <proc_freepagetable>
  p->pagetable = 0;
    80001cda:	04093823          	sd	zero,80(s2)
  p->sz = 0;
    80001cde:	04093423          	sd	zero,72(s2)
  p->pid = 0;
    80001ce2:	02092c23          	sw	zero,56(s2)
  p->parent = 0;
    80001ce6:	02093023          	sd	zero,32(s2)
  p->name[0] = 0;
    80001cea:	14090c23          	sb	zero,344(s2)
  p->chan = 0;
    80001cee:	02093423          	sd	zero,40(s2)
  p->killed = 0;
    80001cf2:	02092823          	sw	zero,48(s2)
  p->xstate = 0;
    80001cf6:	02092a23          	sw	zero,52(s2)
  p->state = UNUSED;
    80001cfa:	00092c23          	sw	zero,24(s2)
}
    80001cfe:	70a2                	ld	ra,40(sp)
    80001d00:	7402                	ld	s0,32(sp)
    80001d02:	64e2                	ld	s1,24(sp)
    80001d04:	6942                	ld	s2,16(sp)
    80001d06:	69a2                	ld	s3,8(sp)
    80001d08:	6145                	addi	sp,sp,48
    80001d0a:	8082                	ret

0000000080001d0c <allocproc>:
{
    80001d0c:	7179                	addi	sp,sp,-48
    80001d0e:	f406                	sd	ra,40(sp)
    80001d10:	f022                	sd	s0,32(sp)
    80001d12:	ec26                	sd	s1,24(sp)
    80001d14:	e84a                	sd	s2,16(sp)
    80001d16:	e44e                	sd	s3,8(sp)
    80001d18:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d1a:	00010497          	auipc	s1,0x10
    80001d1e:	99e48493          	addi	s1,s1,-1634 # 800116b8 <proc>
    80001d22:	00021997          	auipc	s3,0x21
    80001d26:	39698993          	addi	s3,s3,918 # 800230b8 <tickslock>
    acquire(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	eaa080e7          	jalr	-342(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001d34:	4c9c                	lw	a5,24(s1)
    80001d36:	cf81                	beqz	a5,80001d4e <allocproc+0x42>
      release(&p->lock);
    80001d38:	8526                	mv	a0,s1
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	f50080e7          	jalr	-176(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d42:	46848493          	addi	s1,s1,1128
    80001d46:	ff3492e3          	bne	s1,s3,80001d2a <allocproc+0x1e>
  return 0;
    80001d4a:	4481                	li	s1,0
    80001d4c:	a08d                	j	80001dae <allocproc+0xa2>
  p->pid = allocpid();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	e04080e7          	jalr	-508(ra) # 80001b52 <allocpid>
    80001d56:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	d8e080e7          	jalr	-626(ra) # 80000ae6 <kalloc>
    80001d60:	89aa                	mv	s3,a0
    80001d62:	eca8                	sd	a0,88(s1)
    80001d64:	cd29                	beqz	a0,80001dbe <allocproc+0xb2>
  p->pagetable = proc_pagetable(p);
    80001d66:	8526                	mv	a0,s1
    80001d68:	00000097          	auipc	ra,0x0
    80001d6c:	e30080e7          	jalr	-464(ra) # 80001b98 <proc_pagetable>
    80001d70:	89aa                	mv	s3,a0
    80001d72:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d74:	cd21                	beqz	a0,80001dcc <allocproc+0xc0>
  memset(&p->context, 0, sizeof(p->context));
    80001d76:	07000613          	li	a2,112
    80001d7a:	4581                	li	a1,0
    80001d7c:	06048513          	addi	a0,s1,96
    80001d80:	fffff097          	auipc	ra,0xfffff
    80001d84:	f52080e7          	jalr	-174(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001d88:	00000797          	auipc	a5,0x0
    80001d8c:	d8478793          	addi	a5,a5,-636 # 80001b0c <forkret>
    80001d90:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d92:	60bc                	ld	a5,64(s1)
    80001d94:	6705                	lui	a4,0x1
    80001d96:	97ba                	add	a5,a5,a4
    80001d98:	f4bc                	sd	a5,104(s1)
  for(int i=0;i<NVMA;i++) {
    80001d9a:	16848793          	addi	a5,s1,360
    80001d9e:	46848913          	addi	s2,s1,1128
    p->vmas[i].valid = 0;
    80001da2:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<NVMA;i++) {
    80001da6:	03078793          	addi	a5,a5,48
    80001daa:	ff279ce3          	bne	a5,s2,80001da2 <allocproc+0x96>
}
    80001dae:	8526                	mv	a0,s1
    80001db0:	70a2                	ld	ra,40(sp)
    80001db2:	7402                	ld	s0,32(sp)
    80001db4:	64e2                	ld	s1,24(sp)
    80001db6:	6942                	ld	s2,16(sp)
    80001db8:	69a2                	ld	s3,8(sp)
    80001dba:	6145                	addi	sp,sp,48
    80001dbc:	8082                	ret
    release(&p->lock);
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	eca080e7          	jalr	-310(ra) # 80000c8a <release>
    return 0;
    80001dc8:	84ce                	mv	s1,s3
    80001dca:	b7d5                	j	80001dae <allocproc+0xa2>
    freeproc(p);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	eb8080e7          	jalr	-328(ra) # 80001c86 <freeproc>
    release(&p->lock);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	eb2080e7          	jalr	-334(ra) # 80000c8a <release>
    return 0;
    80001de0:	84ce                	mv	s1,s3
    80001de2:	b7f1                	j	80001dae <allocproc+0xa2>

0000000080001de4 <userinit>:
{
    80001de4:	1101                	addi	sp,sp,-32
    80001de6:	ec06                	sd	ra,24(sp)
    80001de8:	e822                	sd	s0,16(sp)
    80001dea:	e426                	sd	s1,8(sp)
    80001dec:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	f1e080e7          	jalr	-226(ra) # 80001d0c <allocproc>
    80001df6:	84aa                	mv	s1,a0
  initproc = p;
    80001df8:	00007797          	auipc	a5,0x7
    80001dfc:	22a7b823          	sd	a0,560(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e00:	03400613          	li	a2,52
    80001e04:	00007597          	auipc	a1,0x7
    80001e08:	a6c58593          	addi	a1,a1,-1428 # 80008870 <initcode>
    80001e0c:	6928                	ld	a0,80(a0)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	652080e7          	jalr	1618(ra) # 80001460 <uvminit>
  p->sz = PGSIZE;
    80001e16:	6785                	lui	a5,0x1
    80001e18:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e1a:	6cb8                	ld	a4,88(s1)
    80001e1c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e20:	6cb8                	ld	a4,88(s1)
    80001e22:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e24:	4641                	li	a2,16
    80001e26:	00006597          	auipc	a1,0x6
    80001e2a:	3d258593          	addi	a1,a1,978 # 800081f8 <digits+0x1b8>
    80001e2e:	15848513          	addi	a0,s1,344
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	ff6080e7          	jalr	-10(ra) # 80000e28 <safestrcpy>
  p->cwd = namei("/");
    80001e3a:	00006517          	auipc	a0,0x6
    80001e3e:	3ce50513          	addi	a0,a0,974 # 80008208 <digits+0x1c8>
    80001e42:	00002097          	auipc	ra,0x2
    80001e46:	136080e7          	jalr	310(ra) # 80003f78 <namei>
    80001e4a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e4e:	4789                	li	a5,2
    80001e50:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e52:	8526                	mv	a0,s1
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	e36080e7          	jalr	-458(ra) # 80000c8a <release>
}
    80001e5c:	60e2                	ld	ra,24(sp)
    80001e5e:	6442                	ld	s0,16(sp)
    80001e60:	64a2                	ld	s1,8(sp)
    80001e62:	6105                	addi	sp,sp,32
    80001e64:	8082                	ret

0000000080001e66 <growproc>:
{
    80001e66:	1101                	addi	sp,sp,-32
    80001e68:	ec06                	sd	ra,24(sp)
    80001e6a:	e822                	sd	s0,16(sp)
    80001e6c:	e426                	sd	s1,8(sp)
    80001e6e:	e04a                	sd	s2,0(sp)
    80001e70:	1000                	addi	s0,sp,32
    80001e72:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e74:	00000097          	auipc	ra,0x0
    80001e78:	c60080e7          	jalr	-928(ra) # 80001ad4 <myproc>
    80001e7c:	892a                	mv	s2,a0
  sz = p->sz;
    80001e7e:	652c                	ld	a1,72(a0)
    80001e80:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e84:	00904f63          	bgtz	s1,80001ea2 <growproc+0x3c>
  } else if(n < 0){
    80001e88:	0204cc63          	bltz	s1,80001ec0 <growproc+0x5a>
  p->sz = sz;
    80001e8c:	1602                	slli	a2,a2,0x20
    80001e8e:	9201                	srli	a2,a2,0x20
    80001e90:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e94:	4501                	li	a0,0
}
    80001e96:	60e2                	ld	ra,24(sp)
    80001e98:	6442                	ld	s0,16(sp)
    80001e9a:	64a2                	ld	s1,8(sp)
    80001e9c:	6902                	ld	s2,0(sp)
    80001e9e:	6105                	addi	sp,sp,32
    80001ea0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ea2:	9e25                	addw	a2,a2,s1
    80001ea4:	1602                	slli	a2,a2,0x20
    80001ea6:	9201                	srli	a2,a2,0x20
    80001ea8:	1582                	slli	a1,a1,0x20
    80001eaa:	9181                	srli	a1,a1,0x20
    80001eac:	6928                	ld	a0,80(a0)
    80001eae:	fffff097          	auipc	ra,0xfffff
    80001eb2:	66c080e7          	jalr	1644(ra) # 8000151a <uvmalloc>
    80001eb6:	0005061b          	sext.w	a2,a0
    80001eba:	fa69                	bnez	a2,80001e8c <growproc+0x26>
      return -1;
    80001ebc:	557d                	li	a0,-1
    80001ebe:	bfe1                	j	80001e96 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ec0:	9e25                	addw	a2,a2,s1
    80001ec2:	1602                	slli	a2,a2,0x20
    80001ec4:	9201                	srli	a2,a2,0x20
    80001ec6:	1582                	slli	a1,a1,0x20
    80001ec8:	9181                	srli	a1,a1,0x20
    80001eca:	6928                	ld	a0,80(a0)
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	606080e7          	jalr	1542(ra) # 800014d2 <uvmdealloc>
    80001ed4:	0005061b          	sext.w	a2,a0
    80001ed8:	bf55                	j	80001e8c <growproc+0x26>

0000000080001eda <fork>:
{
    80001eda:	7139                	addi	sp,sp,-64
    80001edc:	fc06                	sd	ra,56(sp)
    80001ede:	f822                	sd	s0,48(sp)
    80001ee0:	f426                	sd	s1,40(sp)
    80001ee2:	f04a                	sd	s2,32(sp)
    80001ee4:	ec4e                	sd	s3,24(sp)
    80001ee6:	e852                	sd	s4,16(sp)
    80001ee8:	e456                	sd	s5,8(sp)
    80001eea:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001eec:	00000097          	auipc	ra,0x0
    80001ef0:	be8080e7          	jalr	-1048(ra) # 80001ad4 <myproc>
    80001ef4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    80001ef6:	00000097          	auipc	ra,0x0
    80001efa:	e16080e7          	jalr	-490(ra) # 80001d0c <allocproc>
    80001efe:	12050b63          	beqz	a0,80002034 <fork+0x15a>
    80001f02:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f04:	0489b603          	ld	a2,72(s3)
    80001f08:	692c                	ld	a1,80(a0)
    80001f0a:	0509b503          	ld	a0,80(s3)
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	758080e7          	jalr	1880(ra) # 80001666 <uvmcopy>
    80001f16:	04054863          	bltz	a0,80001f66 <fork+0x8c>
  np->sz = p->sz;
    80001f1a:	0489b783          	ld	a5,72(s3)
    80001f1e:	04fa3423          	sd	a5,72(s4)
  np->parent = p;
    80001f22:	033a3023          	sd	s3,32(s4)
  *(np->trapframe) = *(p->trapframe);
    80001f26:	0589b683          	ld	a3,88(s3)
    80001f2a:	87b6                	mv	a5,a3
    80001f2c:	058a3703          	ld	a4,88(s4)
    80001f30:	12068693          	addi	a3,a3,288
    80001f34:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f38:	6788                	ld	a0,8(a5)
    80001f3a:	6b8c                	ld	a1,16(a5)
    80001f3c:	6f90                	ld	a2,24(a5)
    80001f3e:	01073023          	sd	a6,0(a4)
    80001f42:	e708                	sd	a0,8(a4)
    80001f44:	eb0c                	sd	a1,16(a4)
    80001f46:	ef10                	sd	a2,24(a4)
    80001f48:	02078793          	addi	a5,a5,32
    80001f4c:	02070713          	addi	a4,a4,32
    80001f50:	fed792e3          	bne	a5,a3,80001f34 <fork+0x5a>
  np->trapframe->a0 = 0;
    80001f54:	058a3783          	ld	a5,88(s4)
    80001f58:	0607b823          	sd	zero,112(a5)
    80001f5c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f60:	15000913          	li	s2,336
    80001f64:	a03d                	j	80001f92 <fork+0xb8>
    freeproc(np);
    80001f66:	8552                	mv	a0,s4
    80001f68:	00000097          	auipc	ra,0x0
    80001f6c:	d1e080e7          	jalr	-738(ra) # 80001c86 <freeproc>
    release(&np->lock);
    80001f70:	8552                	mv	a0,s4
    80001f72:	fffff097          	auipc	ra,0xfffff
    80001f76:	d18080e7          	jalr	-744(ra) # 80000c8a <release>
    return -1;
    80001f7a:	54fd                	li	s1,-1
    80001f7c:	a055                	j	80002020 <fork+0x146>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f7e:	00002097          	auipc	ra,0x2
    80001f82:	698080e7          	jalr	1688(ra) # 80004616 <filedup>
    80001f86:	009a07b3          	add	a5,s4,s1
    80001f8a:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f8c:	04a1                	addi	s1,s1,8
    80001f8e:	01248763          	beq	s1,s2,80001f9c <fork+0xc2>
    if(p->ofile[i])
    80001f92:	009987b3          	add	a5,s3,s1
    80001f96:	6388                	ld	a0,0(a5)
    80001f98:	f17d                	bnez	a0,80001f7e <fork+0xa4>
    80001f9a:	bfcd                	j	80001f8c <fork+0xb2>
  np->cwd = idup(p->cwd);
    80001f9c:	1509b503          	ld	a0,336(s3)
    80001fa0:	00001097          	auipc	ra,0x1
    80001fa4:	7e4080e7          	jalr	2020(ra) # 80003784 <idup>
    80001fa8:	14aa3823          	sd	a0,336(s4)
  for(i = 0; i < NVMA; i++) {
    80001fac:	16898493          	addi	s1,s3,360
    80001fb0:	168a0913          	addi	s2,s4,360
    80001fb4:	46898a93          	addi	s5,s3,1128
    80001fb8:	a835                	j	80001ff4 <fork+0x11a>
      np->vmas[i] = *v;
    80001fba:	6088                	ld	a0,0(s1)
    80001fbc:	648c                	ld	a1,8(s1)
    80001fbe:	6890                	ld	a2,16(s1)
    80001fc0:	6c94                	ld	a3,24(s1)
    80001fc2:	7098                	ld	a4,32(s1)
    80001fc4:	749c                	ld	a5,40(s1)
    80001fc6:	00a93023          	sd	a0,0(s2)
    80001fca:	00b93423          	sd	a1,8(s2)
    80001fce:	00c93823          	sd	a2,16(s2)
    80001fd2:	00d93c23          	sd	a3,24(s2)
    80001fd6:	02e93023          	sd	a4,32(s2)
    80001fda:	02f93423          	sd	a5,40(s2)
      filedup(v->f);
    80001fde:	6c88                	ld	a0,24(s1)
    80001fe0:	00002097          	auipc	ra,0x2
    80001fe4:	636080e7          	jalr	1590(ra) # 80004616 <filedup>
  for(i = 0; i < NVMA; i++) {
    80001fe8:	03048493          	addi	s1,s1,48
    80001fec:	03090913          	addi	s2,s2,48
    80001ff0:	01548563          	beq	s1,s5,80001ffa <fork+0x120>
    if(v->valid) {
    80001ff4:	409c                	lw	a5,0(s1)
    80001ff6:	dbed                	beqz	a5,80001fe8 <fork+0x10e>
    80001ff8:	b7c9                	j	80001fba <fork+0xe0>
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ffa:	4641                	li	a2,16
    80001ffc:	15898593          	addi	a1,s3,344
    80002000:	158a0513          	addi	a0,s4,344
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	e24080e7          	jalr	-476(ra) # 80000e28 <safestrcpy>
  pid = np->pid;
    8000200c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80002010:	4789                	li	a5,2
    80002012:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002016:	8552                	mv	a0,s4
    80002018:	fffff097          	auipc	ra,0xfffff
    8000201c:	c72080e7          	jalr	-910(ra) # 80000c8a <release>
}
    80002020:	8526                	mv	a0,s1
    80002022:	70e2                	ld	ra,56(sp)
    80002024:	7442                	ld	s0,48(sp)
    80002026:	74a2                	ld	s1,40(sp)
    80002028:	7902                	ld	s2,32(sp)
    8000202a:	69e2                	ld	s3,24(sp)
    8000202c:	6a42                	ld	s4,16(sp)
    8000202e:	6aa2                	ld	s5,8(sp)
    80002030:	6121                	addi	sp,sp,64
    80002032:	8082                	ret
    return -1;
    80002034:	54fd                	li	s1,-1
    80002036:	b7ed                	j	80002020 <fork+0x146>

0000000080002038 <reparent>:
{
    80002038:	7179                	addi	sp,sp,-48
    8000203a:	f406                	sd	ra,40(sp)
    8000203c:	f022                	sd	s0,32(sp)
    8000203e:	ec26                	sd	s1,24(sp)
    80002040:	e84a                	sd	s2,16(sp)
    80002042:	e44e                	sd	s3,8(sp)
    80002044:	e052                	sd	s4,0(sp)
    80002046:	1800                	addi	s0,sp,48
    80002048:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000204a:	0000f497          	auipc	s1,0xf
    8000204e:	66e48493          	addi	s1,s1,1646 # 800116b8 <proc>
      pp->parent = initproc;
    80002052:	00007a17          	auipc	s4,0x7
    80002056:	fd6a0a13          	addi	s4,s4,-42 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000205a:	00021997          	auipc	s3,0x21
    8000205e:	05e98993          	addi	s3,s3,94 # 800230b8 <tickslock>
    80002062:	a029                	j	8000206c <reparent+0x34>
    80002064:	46848493          	addi	s1,s1,1128
    80002068:	03348363          	beq	s1,s3,8000208e <reparent+0x56>
    if(pp->parent == p){
    8000206c:	709c                	ld	a5,32(s1)
    8000206e:	ff279be3          	bne	a5,s2,80002064 <reparent+0x2c>
      acquire(&pp->lock);
    80002072:	8526                	mv	a0,s1
    80002074:	fffff097          	auipc	ra,0xfffff
    80002078:	b62080e7          	jalr	-1182(ra) # 80000bd6 <acquire>
      pp->parent = initproc;
    8000207c:	000a3783          	ld	a5,0(s4)
    80002080:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002082:	8526                	mv	a0,s1
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	c06080e7          	jalr	-1018(ra) # 80000c8a <release>
    8000208c:	bfe1                	j	80002064 <reparent+0x2c>
}
    8000208e:	70a2                	ld	ra,40(sp)
    80002090:	7402                	ld	s0,32(sp)
    80002092:	64e2                	ld	s1,24(sp)
    80002094:	6942                	ld	s2,16(sp)
    80002096:	69a2                	ld	s3,8(sp)
    80002098:	6a02                	ld	s4,0(sp)
    8000209a:	6145                	addi	sp,sp,48
    8000209c:	8082                	ret

000000008000209e <scheduler>:
{
    8000209e:	711d                	addi	sp,sp,-96
    800020a0:	ec86                	sd	ra,88(sp)
    800020a2:	e8a2                	sd	s0,80(sp)
    800020a4:	e4a6                	sd	s1,72(sp)
    800020a6:	e0ca                	sd	s2,64(sp)
    800020a8:	fc4e                	sd	s3,56(sp)
    800020aa:	f852                	sd	s4,48(sp)
    800020ac:	f456                	sd	s5,40(sp)
    800020ae:	f05a                	sd	s6,32(sp)
    800020b0:	ec5e                	sd	s7,24(sp)
    800020b2:	e862                	sd	s8,16(sp)
    800020b4:	e466                	sd	s9,8(sp)
    800020b6:	1080                	addi	s0,sp,96
    800020b8:	8792                	mv	a5,tp
  int id = r_tp();
    800020ba:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020bc:	00779c13          	slli	s8,a5,0x7
    800020c0:	0000f717          	auipc	a4,0xf
    800020c4:	1e070713          	addi	a4,a4,480 # 800112a0 <pid_lock>
    800020c8:	9762                	add	a4,a4,s8
    800020ca:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800020ce:	0000f717          	auipc	a4,0xf
    800020d2:	1f270713          	addi	a4,a4,498 # 800112c0 <cpus+0x8>
    800020d6:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800020d8:	4a89                	li	s5,2
        c->proc = p;
    800020da:	079e                	slli	a5,a5,0x7
    800020dc:	0000fb17          	auipc	s6,0xf
    800020e0:	1c4b0b13          	addi	s6,s6,452 # 800112a0 <pid_lock>
    800020e4:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	00021a17          	auipc	s4,0x21
    800020ea:	fd2a0a13          	addi	s4,s4,-46 # 800230b8 <tickslock>
    int nproc = 0;
    800020ee:	4c81                	li	s9,0
    800020f0:	a8a1                	j	80002148 <scheduler+0xaa>
        p->state = RUNNING;
    800020f2:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    800020f6:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    800020fa:	06048593          	addi	a1,s1,96
    800020fe:	8562                	mv	a0,s8
    80002100:	00000097          	auipc	ra,0x0
    80002104:	63a080e7          	jalr	1594(ra) # 8000273a <swtch>
        c->proc = 0;
    80002108:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000210c:	8526                	mv	a0,s1
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	b7c080e7          	jalr	-1156(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002116:	46848493          	addi	s1,s1,1128
    8000211a:	01448d63          	beq	s1,s4,80002134 <scheduler+0x96>
      acquire(&p->lock);
    8000211e:	8526                	mv	a0,s1
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	ab6080e7          	jalr	-1354(ra) # 80000bd6 <acquire>
      if(p->state != UNUSED) {
    80002128:	4c9c                	lw	a5,24(s1)
    8000212a:	d3ed                	beqz	a5,8000210c <scheduler+0x6e>
        nproc++;
    8000212c:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000212e:	fd579fe3          	bne	a5,s5,8000210c <scheduler+0x6e>
    80002132:	b7c1                	j	800020f2 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002134:	013aca63          	blt	s5,s3,80002148 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002138:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000213c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002140:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002144:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002148:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000214c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002150:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002154:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	56248493          	addi	s1,s1,1378 # 800116b8 <proc>
        p->state = RUNNING;
    8000215e:	4b8d                	li	s7,3
    80002160:	bf7d                	j	8000211e <scheduler+0x80>

0000000080002162 <sched>:
{
    80002162:	7179                	addi	sp,sp,-48
    80002164:	f406                	sd	ra,40(sp)
    80002166:	f022                	sd	s0,32(sp)
    80002168:	ec26                	sd	s1,24(sp)
    8000216a:	e84a                	sd	s2,16(sp)
    8000216c:	e44e                	sd	s3,8(sp)
    8000216e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002170:	00000097          	auipc	ra,0x0
    80002174:	964080e7          	jalr	-1692(ra) # 80001ad4 <myproc>
    80002178:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	9e2080e7          	jalr	-1566(ra) # 80000b5c <holding>
    80002182:	c93d                	beqz	a0,800021f8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002184:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002186:	2781                	sext.w	a5,a5
    80002188:	079e                	slli	a5,a5,0x7
    8000218a:	0000f717          	auipc	a4,0xf
    8000218e:	11670713          	addi	a4,a4,278 # 800112a0 <pid_lock>
    80002192:	97ba                	add	a5,a5,a4
    80002194:	0907a703          	lw	a4,144(a5)
    80002198:	4785                	li	a5,1
    8000219a:	06f71763          	bne	a4,a5,80002208 <sched+0xa6>
  if(p->state == RUNNING)
    8000219e:	4c98                	lw	a4,24(s1)
    800021a0:	478d                	li	a5,3
    800021a2:	06f70b63          	beq	a4,a5,80002218 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021aa:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021ac:	efb5                	bnez	a5,80002228 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021ae:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021b0:	0000f917          	auipc	s2,0xf
    800021b4:	0f090913          	addi	s2,s2,240 # 800112a0 <pid_lock>
    800021b8:	2781                	sext.w	a5,a5
    800021ba:	079e                	slli	a5,a5,0x7
    800021bc:	97ca                	add	a5,a5,s2
    800021be:	0947a983          	lw	s3,148(a5)
    800021c2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021c4:	2781                	sext.w	a5,a5
    800021c6:	079e                	slli	a5,a5,0x7
    800021c8:	0000f597          	auipc	a1,0xf
    800021cc:	0f858593          	addi	a1,a1,248 # 800112c0 <cpus+0x8>
    800021d0:	95be                	add	a1,a1,a5
    800021d2:	06048513          	addi	a0,s1,96
    800021d6:	00000097          	auipc	ra,0x0
    800021da:	564080e7          	jalr	1380(ra) # 8000273a <swtch>
    800021de:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021e0:	2781                	sext.w	a5,a5
    800021e2:	079e                	slli	a5,a5,0x7
    800021e4:	97ca                	add	a5,a5,s2
    800021e6:	0937aa23          	sw	s3,148(a5)
}
    800021ea:	70a2                	ld	ra,40(sp)
    800021ec:	7402                	ld	s0,32(sp)
    800021ee:	64e2                	ld	s1,24(sp)
    800021f0:	6942                	ld	s2,16(sp)
    800021f2:	69a2                	ld	s3,8(sp)
    800021f4:	6145                	addi	sp,sp,48
    800021f6:	8082                	ret
    panic("sched p->lock");
    800021f8:	00006517          	auipc	a0,0x6
    800021fc:	01850513          	addi	a0,a0,24 # 80008210 <digits+0x1d0>
    80002200:	ffffe097          	auipc	ra,0xffffe
    80002204:	330080e7          	jalr	816(ra) # 80000530 <panic>
    panic("sched locks");
    80002208:	00006517          	auipc	a0,0x6
    8000220c:	01850513          	addi	a0,a0,24 # 80008220 <digits+0x1e0>
    80002210:	ffffe097          	auipc	ra,0xffffe
    80002214:	320080e7          	jalr	800(ra) # 80000530 <panic>
    panic("sched running");
    80002218:	00006517          	auipc	a0,0x6
    8000221c:	01850513          	addi	a0,a0,24 # 80008230 <digits+0x1f0>
    80002220:	ffffe097          	auipc	ra,0xffffe
    80002224:	310080e7          	jalr	784(ra) # 80000530 <panic>
    panic("sched interruptible");
    80002228:	00006517          	auipc	a0,0x6
    8000222c:	01850513          	addi	a0,a0,24 # 80008240 <digits+0x200>
    80002230:	ffffe097          	auipc	ra,0xffffe
    80002234:	300080e7          	jalr	768(ra) # 80000530 <panic>

0000000080002238 <exit>:
{
    80002238:	7179                	addi	sp,sp,-48
    8000223a:	f406                	sd	ra,40(sp)
    8000223c:	f022                	sd	s0,32(sp)
    8000223e:	ec26                	sd	s1,24(sp)
    80002240:	e84a                	sd	s2,16(sp)
    80002242:	e44e                	sd	s3,8(sp)
    80002244:	e052                	sd	s4,0(sp)
    80002246:	1800                	addi	s0,sp,48
    80002248:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000224a:	00000097          	auipc	ra,0x0
    8000224e:	88a080e7          	jalr	-1910(ra) # 80001ad4 <myproc>
    80002252:	89aa                	mv	s3,a0
  if(p == initproc)
    80002254:	00007797          	auipc	a5,0x7
    80002258:	dd47b783          	ld	a5,-556(a5) # 80009028 <initproc>
    8000225c:	0d050493          	addi	s1,a0,208
    80002260:	15050913          	addi	s2,a0,336
    80002264:	02a79363          	bne	a5,a0,8000228a <exit+0x52>
    panic("init exiting");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	ff050513          	addi	a0,a0,-16 # 80008258 <digits+0x218>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2c0080e7          	jalr	704(ra) # 80000530 <panic>
      fileclose(f);
    80002278:	00002097          	auipc	ra,0x2
    8000227c:	3f0080e7          	jalr	1008(ra) # 80004668 <fileclose>
      p->ofile[fd] = 0;
    80002280:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002284:	04a1                	addi	s1,s1,8
    80002286:	01248563          	beq	s1,s2,80002290 <exit+0x58>
    if(p->ofile[fd]){
    8000228a:	6088                	ld	a0,0(s1)
    8000228c:	f575                	bnez	a0,80002278 <exit+0x40>
    8000228e:	bfdd                	j	80002284 <exit+0x4c>
  begin_op();
    80002290:	00002097          	auipc	ra,0x2
    80002294:	f04080e7          	jalr	-252(ra) # 80004194 <begin_op>
  iput(p->cwd);
    80002298:	1509b503          	ld	a0,336(s3)
    8000229c:	00001097          	auipc	ra,0x1
    800022a0:	6e0080e7          	jalr	1760(ra) # 8000397c <iput>
  end_op();
    800022a4:	00002097          	auipc	ra,0x2
    800022a8:	f70080e7          	jalr	-144(ra) # 80004214 <end_op>
  p->cwd = 0;
    800022ac:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800022b0:	00007497          	auipc	s1,0x7
    800022b4:	d7848493          	addi	s1,s1,-648 # 80009028 <initproc>
    800022b8:	6088                	ld	a0,0(s1)
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	91c080e7          	jalr	-1764(ra) # 80000bd6 <acquire>
  wakeup1(initproc);
    800022c2:	6088                	ld	a0,0(s1)
    800022c4:	fffff097          	auipc	ra,0xfffff
    800022c8:	672080e7          	jalr	1650(ra) # 80001936 <wakeup1>
  release(&initproc->lock);
    800022cc:	6088                	ld	a0,0(s1)
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9bc080e7          	jalr	-1604(ra) # 80000c8a <release>
  acquire(&p->lock);
    800022d6:	854e                	mv	a0,s3
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	8fe080e7          	jalr	-1794(ra) # 80000bd6 <acquire>
  struct proc *original_parent = p->parent;
    800022e0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800022e4:	854e                	mv	a0,s3
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	9a4080e7          	jalr	-1628(ra) # 80000c8a <release>
  acquire(&original_parent->lock);
    800022ee:	8526                	mv	a0,s1
    800022f0:	fffff097          	auipc	ra,0xfffff
    800022f4:	8e6080e7          	jalr	-1818(ra) # 80000bd6 <acquire>
  acquire(&p->lock);
    800022f8:	854e                	mv	a0,s3
    800022fa:	fffff097          	auipc	ra,0xfffff
    800022fe:	8dc080e7          	jalr	-1828(ra) # 80000bd6 <acquire>
  reparent(p);
    80002302:	854e                	mv	a0,s3
    80002304:	00000097          	auipc	ra,0x0
    80002308:	d34080e7          	jalr	-716(ra) # 80002038 <reparent>
  wakeup1(original_parent);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	628080e7          	jalr	1576(ra) # 80001936 <wakeup1>
  p->xstate = status;
    80002316:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000231a:	4791                	li	a5,4
    8000231c:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002320:	8526                	mv	a0,s1
    80002322:	fffff097          	auipc	ra,0xfffff
    80002326:	968080e7          	jalr	-1688(ra) # 80000c8a <release>
  sched();
    8000232a:	00000097          	auipc	ra,0x0
    8000232e:	e38080e7          	jalr	-456(ra) # 80002162 <sched>
  panic("zombie exit");
    80002332:	00006517          	auipc	a0,0x6
    80002336:	f3650513          	addi	a0,a0,-202 # 80008268 <digits+0x228>
    8000233a:	ffffe097          	auipc	ra,0xffffe
    8000233e:	1f6080e7          	jalr	502(ra) # 80000530 <panic>

0000000080002342 <yield>:
{
    80002342:	1101                	addi	sp,sp,-32
    80002344:	ec06                	sd	ra,24(sp)
    80002346:	e822                	sd	s0,16(sp)
    80002348:	e426                	sd	s1,8(sp)
    8000234a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	788080e7          	jalr	1928(ra) # 80001ad4 <myproc>
    80002354:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000235e:	4789                	li	a5,2
    80002360:	cc9c                	sw	a5,24(s1)
  sched();
    80002362:	00000097          	auipc	ra,0x0
    80002366:	e00080e7          	jalr	-512(ra) # 80002162 <sched>
  release(&p->lock);
    8000236a:	8526                	mv	a0,s1
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
}
    80002374:	60e2                	ld	ra,24(sp)
    80002376:	6442                	ld	s0,16(sp)
    80002378:	64a2                	ld	s1,8(sp)
    8000237a:	6105                	addi	sp,sp,32
    8000237c:	8082                	ret

000000008000237e <sleep>:
{
    8000237e:	7179                	addi	sp,sp,-48
    80002380:	f406                	sd	ra,40(sp)
    80002382:	f022                	sd	s0,32(sp)
    80002384:	ec26                	sd	s1,24(sp)
    80002386:	e84a                	sd	s2,16(sp)
    80002388:	e44e                	sd	s3,8(sp)
    8000238a:	1800                	addi	s0,sp,48
    8000238c:	89aa                	mv	s3,a0
    8000238e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	744080e7          	jalr	1860(ra) # 80001ad4 <myproc>
    80002398:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000239a:	05250663          	beq	a0,s2,800023e6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	838080e7          	jalr	-1992(ra) # 80000bd6 <acquire>
    release(lk);
    800023a6:	854a                	mv	a0,s2
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8e2080e7          	jalr	-1822(ra) # 80000c8a <release>
  p->chan = chan;
    800023b0:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800023b4:	4785                	li	a5,1
    800023b6:	cc9c                	sw	a5,24(s1)
  sched();
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	daa080e7          	jalr	-598(ra) # 80002162 <sched>
  p->chan = 0;
    800023c0:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8c4080e7          	jalr	-1852(ra) # 80000c8a <release>
    acquire(lk);
    800023ce:	854a                	mv	a0,s2
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
}
    800023d8:	70a2                	ld	ra,40(sp)
    800023da:	7402                	ld	s0,32(sp)
    800023dc:	64e2                	ld	s1,24(sp)
    800023de:	6942                	ld	s2,16(sp)
    800023e0:	69a2                	ld	s3,8(sp)
    800023e2:	6145                	addi	sp,sp,48
    800023e4:	8082                	ret
  p->chan = chan;
    800023e6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800023ea:	4785                	li	a5,1
    800023ec:	cd1c                	sw	a5,24(a0)
  sched();
    800023ee:	00000097          	auipc	ra,0x0
    800023f2:	d74080e7          	jalr	-652(ra) # 80002162 <sched>
  p->chan = 0;
    800023f6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800023fa:	bff9                	j	800023d8 <sleep+0x5a>

00000000800023fc <wait>:
{
    800023fc:	715d                	addi	sp,sp,-80
    800023fe:	e486                	sd	ra,72(sp)
    80002400:	e0a2                	sd	s0,64(sp)
    80002402:	fc26                	sd	s1,56(sp)
    80002404:	f84a                	sd	s2,48(sp)
    80002406:	f44e                	sd	s3,40(sp)
    80002408:	f052                	sd	s4,32(sp)
    8000240a:	ec56                	sd	s5,24(sp)
    8000240c:	e85a                	sd	s6,16(sp)
    8000240e:	e45e                	sd	s7,8(sp)
    80002410:	e062                	sd	s8,0(sp)
    80002412:	0880                	addi	s0,sp,80
    80002414:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	6be080e7          	jalr	1726(ra) # 80001ad4 <myproc>
    8000241e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002420:	8c2a                	mv	s8,a0
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	7b4080e7          	jalr	1972(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000242a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000242c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000242e:	00021997          	auipc	s3,0x21
    80002432:	c8a98993          	addi	s3,s3,-886 # 800230b8 <tickslock>
        havekids = 1;
    80002436:	4a85                	li	s5,1
    havekids = 0;
    80002438:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000243a:	0000f497          	auipc	s1,0xf
    8000243e:	27e48493          	addi	s1,s1,638 # 800116b8 <proc>
    80002442:	a08d                	j	800024a4 <wait+0xa8>
          pid = np->pid;
    80002444:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002448:	000b0e63          	beqz	s6,80002464 <wait+0x68>
    8000244c:	4691                	li	a3,4
    8000244e:	03448613          	addi	a2,s1,52
    80002452:	85da                	mv	a1,s6
    80002454:	05093503          	ld	a0,80(s2)
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	312080e7          	jalr	786(ra) # 8000176a <copyout>
    80002460:	02054263          	bltz	a0,80002484 <wait+0x88>
          freeproc(np);
    80002464:	8526                	mv	a0,s1
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	820080e7          	jalr	-2016(ra) # 80001c86 <freeproc>
          release(&np->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	81a080e7          	jalr	-2022(ra) # 80000c8a <release>
          release(&p->lock);
    80002478:	854a                	mv	a0,s2
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
          return pid;
    80002482:	a8a9                	j	800024dc <wait+0xe0>
            release(&np->lock);
    80002484:	8526                	mv	a0,s1
    80002486:	fffff097          	auipc	ra,0xfffff
    8000248a:	804080e7          	jalr	-2044(ra) # 80000c8a <release>
            release(&p->lock);
    8000248e:	854a                	mv	a0,s2
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	7fa080e7          	jalr	2042(ra) # 80000c8a <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	a089                	j	800024dc <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000249c:	46848493          	addi	s1,s1,1128
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xcc>
      if(np->parent == p){
    800024a4:	709c                	ld	a5,32(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xa0>
        acquire(&np->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	72a080e7          	jalr	1834(ra) # 80000bd6 <acquire>
        if(np->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f94787e3          	beq	a5,s4,80002444 <wait+0x48>
        release(&np->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7ce080e7          	jalr	1998(ra) # 80000c8a <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xa0>
    if(!havekids || p->killed){
    800024c8:	c701                	beqz	a4,800024d0 <wait+0xd4>
    800024ca:	03092783          	lw	a5,48(s2)
    800024ce:	c785                	beqz	a5,800024f6 <wait+0xfa>
      release(&p->lock);
    800024d0:	854a                	mv	a0,s2
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7b8080e7          	jalr	1976(ra) # 80000c8a <release>
      return -1;
    800024da:	59fd                	li	s3,-1
}
    800024dc:	854e                	mv	a0,s3
    800024de:	60a6                	ld	ra,72(sp)
    800024e0:	6406                	ld	s0,64(sp)
    800024e2:	74e2                	ld	s1,56(sp)
    800024e4:	7942                	ld	s2,48(sp)
    800024e6:	79a2                	ld	s3,40(sp)
    800024e8:	7a02                	ld	s4,32(sp)
    800024ea:	6ae2                	ld	s5,24(sp)
    800024ec:	6b42                	ld	s6,16(sp)
    800024ee:	6ba2                	ld	s7,8(sp)
    800024f0:	6c02                	ld	s8,0(sp)
    800024f2:	6161                	addi	sp,sp,80
    800024f4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800024f6:	85e2                	mv	a1,s8
    800024f8:	854a                	mv	a0,s2
    800024fa:	00000097          	auipc	ra,0x0
    800024fe:	e84080e7          	jalr	-380(ra) # 8000237e <sleep>
    havekids = 0;
    80002502:	bf1d                	j	80002438 <wait+0x3c>

0000000080002504 <wakeup>:
{
    80002504:	7139                	addi	sp,sp,-64
    80002506:	fc06                	sd	ra,56(sp)
    80002508:	f822                	sd	s0,48(sp)
    8000250a:	f426                	sd	s1,40(sp)
    8000250c:	f04a                	sd	s2,32(sp)
    8000250e:	ec4e                	sd	s3,24(sp)
    80002510:	e852                	sd	s4,16(sp)
    80002512:	e456                	sd	s5,8(sp)
    80002514:	0080                	addi	s0,sp,64
    80002516:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002518:	0000f497          	auipc	s1,0xf
    8000251c:	1a048493          	addi	s1,s1,416 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002520:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002522:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002524:	00021917          	auipc	s2,0x21
    80002528:	b9490913          	addi	s2,s2,-1132 # 800230b8 <tickslock>
    8000252c:	a821                	j	80002544 <wakeup+0x40>
      p->state = RUNNABLE;
    8000252e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002532:	8526                	mv	a0,s1
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	756080e7          	jalr	1878(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000253c:	46848493          	addi	s1,s1,1128
    80002540:	01248e63          	beq	s1,s2,8000255c <wakeup+0x58>
    acquire(&p->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	690080e7          	jalr	1680(ra) # 80000bd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000254e:	4c9c                	lw	a5,24(s1)
    80002550:	ff3791e3          	bne	a5,s3,80002532 <wakeup+0x2e>
    80002554:	749c                	ld	a5,40(s1)
    80002556:	fd479ee3          	bne	a5,s4,80002532 <wakeup+0x2e>
    8000255a:	bfd1                	j	8000252e <wakeup+0x2a>
}
    8000255c:	70e2                	ld	ra,56(sp)
    8000255e:	7442                	ld	s0,48(sp)
    80002560:	74a2                	ld	s1,40(sp)
    80002562:	7902                	ld	s2,32(sp)
    80002564:	69e2                	ld	s3,24(sp)
    80002566:	6a42                	ld	s4,16(sp)
    80002568:	6aa2                	ld	s5,8(sp)
    8000256a:	6121                	addi	sp,sp,64
    8000256c:	8082                	ret

000000008000256e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000256e:	7179                	addi	sp,sp,-48
    80002570:	f406                	sd	ra,40(sp)
    80002572:	f022                	sd	s0,32(sp)
    80002574:	ec26                	sd	s1,24(sp)
    80002576:	e84a                	sd	s2,16(sp)
    80002578:	e44e                	sd	s3,8(sp)
    8000257a:	1800                	addi	s0,sp,48
    8000257c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000257e:	0000f497          	auipc	s1,0xf
    80002582:	13a48493          	addi	s1,s1,314 # 800116b8 <proc>
    80002586:	00021997          	auipc	s3,0x21
    8000258a:	b3298993          	addi	s3,s3,-1230 # 800230b8 <tickslock>
    acquire(&p->lock);
    8000258e:	8526                	mv	a0,s1
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	646080e7          	jalr	1606(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002598:	5c9c                	lw	a5,56(s1)
    8000259a:	01278d63          	beq	a5,s2,800025b4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000259e:	8526                	mv	a0,s1
    800025a0:	ffffe097          	auipc	ra,0xffffe
    800025a4:	6ea080e7          	jalr	1770(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a8:	46848493          	addi	s1,s1,1128
    800025ac:	ff3491e3          	bne	s1,s3,8000258e <kill+0x20>
  }
  return -1;
    800025b0:	557d                	li	a0,-1
    800025b2:	a829                	j	800025cc <kill+0x5e>
      p->killed = 1;
    800025b4:	4785                	li	a5,1
    800025b6:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800025b8:	4c98                	lw	a4,24(s1)
    800025ba:	4785                	li	a5,1
    800025bc:	00f70f63          	beq	a4,a5,800025da <kill+0x6c>
      release(&p->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	6c8080e7          	jalr	1736(ra) # 80000c8a <release>
      return 0;
    800025ca:	4501                	li	a0,0
}
    800025cc:	70a2                	ld	ra,40(sp)
    800025ce:	7402                	ld	s0,32(sp)
    800025d0:	64e2                	ld	s1,24(sp)
    800025d2:	6942                	ld	s2,16(sp)
    800025d4:	69a2                	ld	s3,8(sp)
    800025d6:	6145                	addi	sp,sp,48
    800025d8:	8082                	ret
        p->state = RUNNABLE;
    800025da:	4789                	li	a5,2
    800025dc:	cc9c                	sw	a5,24(s1)
    800025de:	b7cd                	j	800025c0 <kill+0x52>

00000000800025e0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025e0:	7179                	addi	sp,sp,-48
    800025e2:	f406                	sd	ra,40(sp)
    800025e4:	f022                	sd	s0,32(sp)
    800025e6:	ec26                	sd	s1,24(sp)
    800025e8:	e84a                	sd	s2,16(sp)
    800025ea:	e44e                	sd	s3,8(sp)
    800025ec:	e052                	sd	s4,0(sp)
    800025ee:	1800                	addi	s0,sp,48
    800025f0:	84aa                	mv	s1,a0
    800025f2:	892e                	mv	s2,a1
    800025f4:	89b2                	mv	s3,a2
    800025f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	4dc080e7          	jalr	1244(ra) # 80001ad4 <myproc>
  if(user_dst){
    80002600:	c08d                	beqz	s1,80002622 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002602:	86d2                	mv	a3,s4
    80002604:	864e                	mv	a2,s3
    80002606:	85ca                	mv	a1,s2
    80002608:	6928                	ld	a0,80(a0)
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	160080e7          	jalr	352(ra) # 8000176a <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002612:	70a2                	ld	ra,40(sp)
    80002614:	7402                	ld	s0,32(sp)
    80002616:	64e2                	ld	s1,24(sp)
    80002618:	6942                	ld	s2,16(sp)
    8000261a:	69a2                	ld	s3,8(sp)
    8000261c:	6a02                	ld	s4,0(sp)
    8000261e:	6145                	addi	sp,sp,48
    80002620:	8082                	ret
    memmove((char *)dst, src, len);
    80002622:	000a061b          	sext.w	a2,s4
    80002626:	85ce                	mv	a1,s3
    80002628:	854a                	mv	a0,s2
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	708080e7          	jalr	1800(ra) # 80000d32 <memmove>
    return 0;
    80002632:	8526                	mv	a0,s1
    80002634:	bff9                	j	80002612 <either_copyout+0x32>

0000000080002636 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002636:	7179                	addi	sp,sp,-48
    80002638:	f406                	sd	ra,40(sp)
    8000263a:	f022                	sd	s0,32(sp)
    8000263c:	ec26                	sd	s1,24(sp)
    8000263e:	e84a                	sd	s2,16(sp)
    80002640:	e44e                	sd	s3,8(sp)
    80002642:	e052                	sd	s4,0(sp)
    80002644:	1800                	addi	s0,sp,48
    80002646:	892a                	mv	s2,a0
    80002648:	84ae                	mv	s1,a1
    8000264a:	89b2                	mv	s3,a2
    8000264c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000264e:	fffff097          	auipc	ra,0xfffff
    80002652:	486080e7          	jalr	1158(ra) # 80001ad4 <myproc>
  if(user_src){
    80002656:	c08d                	beqz	s1,80002678 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002658:	86d2                	mv	a3,s4
    8000265a:	864e                	mv	a2,s3
    8000265c:	85ca                	mv	a1,s2
    8000265e:	6928                	ld	a0,80(a0)
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	196080e7          	jalr	406(ra) # 800017f6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002668:	70a2                	ld	ra,40(sp)
    8000266a:	7402                	ld	s0,32(sp)
    8000266c:	64e2                	ld	s1,24(sp)
    8000266e:	6942                	ld	s2,16(sp)
    80002670:	69a2                	ld	s3,8(sp)
    80002672:	6a02                	ld	s4,0(sp)
    80002674:	6145                	addi	sp,sp,48
    80002676:	8082                	ret
    memmove(dst, (char*)src, len);
    80002678:	000a061b          	sext.w	a2,s4
    8000267c:	85ce                	mv	a1,s3
    8000267e:	854a                	mv	a0,s2
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	6b2080e7          	jalr	1714(ra) # 80000d32 <memmove>
    return 0;
    80002688:	8526                	mv	a0,s1
    8000268a:	bff9                	j	80002668 <either_copyin+0x32>

000000008000268c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000268c:	715d                	addi	sp,sp,-80
    8000268e:	e486                	sd	ra,72(sp)
    80002690:	e0a2                	sd	s0,64(sp)
    80002692:	fc26                	sd	s1,56(sp)
    80002694:	f84a                	sd	s2,48(sp)
    80002696:	f44e                	sd	s3,40(sp)
    80002698:	f052                	sd	s4,32(sp)
    8000269a:	ec56                	sd	s5,24(sp)
    8000269c:	e85a                	sd	s6,16(sp)
    8000269e:	e45e                	sd	s7,8(sp)
    800026a0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026a2:	00006517          	auipc	a0,0x6
    800026a6:	a2650513          	addi	a0,a0,-1498 # 800080c8 <digits+0x88>
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	ed0080e7          	jalr	-304(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b2:	0000f497          	auipc	s1,0xf
    800026b6:	15e48493          	addi	s1,s1,350 # 80011810 <proc+0x158>
    800026ba:	00021917          	auipc	s2,0x21
    800026be:	b5690913          	addi	s2,s2,-1194 # 80023210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026c2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800026c4:	00006997          	auipc	s3,0x6
    800026c8:	bb498993          	addi	s3,s3,-1100 # 80008278 <digits+0x238>
    printf("%d %s %s", p->pid, state, p->name);
    800026cc:	00006a97          	auipc	s5,0x6
    800026d0:	bb4a8a93          	addi	s5,s5,-1100 # 80008280 <digits+0x240>
    printf("\n");
    800026d4:	00006a17          	auipc	s4,0x6
    800026d8:	9f4a0a13          	addi	s4,s4,-1548 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026dc:	00006b97          	auipc	s7,0x6
    800026e0:	bdcb8b93          	addi	s7,s7,-1060 # 800082b8 <states.1737>
    800026e4:	a00d                	j	80002706 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026e6:	ee06a583          	lw	a1,-288(a3)
    800026ea:	8556                	mv	a0,s5
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	e8e080e7          	jalr	-370(ra) # 8000057a <printf>
    printf("\n");
    800026f4:	8552                	mv	a0,s4
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	e84080e7          	jalr	-380(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026fe:	46848493          	addi	s1,s1,1128
    80002702:	03248163          	beq	s1,s2,80002724 <procdump+0x98>
    if(p->state == UNUSED)
    80002706:	86a6                	mv	a3,s1
    80002708:	ec04a783          	lw	a5,-320(s1)
    8000270c:	dbed                	beqz	a5,800026fe <procdump+0x72>
      state = "???";
    8000270e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002710:	fcfb6be3          	bltu	s6,a5,800026e6 <procdump+0x5a>
    80002714:	1782                	slli	a5,a5,0x20
    80002716:	9381                	srli	a5,a5,0x20
    80002718:	078e                	slli	a5,a5,0x3
    8000271a:	97de                	add	a5,a5,s7
    8000271c:	6390                	ld	a2,0(a5)
    8000271e:	f661                	bnez	a2,800026e6 <procdump+0x5a>
      state = "???";
    80002720:	864e                	mv	a2,s3
    80002722:	b7d1                	j	800026e6 <procdump+0x5a>
  }
}
    80002724:	60a6                	ld	ra,72(sp)
    80002726:	6406                	ld	s0,64(sp)
    80002728:	74e2                	ld	s1,56(sp)
    8000272a:	7942                	ld	s2,48(sp)
    8000272c:	79a2                	ld	s3,40(sp)
    8000272e:	7a02                	ld	s4,32(sp)
    80002730:	6ae2                	ld	s5,24(sp)
    80002732:	6b42                	ld	s6,16(sp)
    80002734:	6ba2                	ld	s7,8(sp)
    80002736:	6161                	addi	sp,sp,80
    80002738:	8082                	ret

000000008000273a <swtch>:
    8000273a:	00153023          	sd	ra,0(a0)
    8000273e:	00253423          	sd	sp,8(a0)
    80002742:	e900                	sd	s0,16(a0)
    80002744:	ed04                	sd	s1,24(a0)
    80002746:	03253023          	sd	s2,32(a0)
    8000274a:	03353423          	sd	s3,40(a0)
    8000274e:	03453823          	sd	s4,48(a0)
    80002752:	03553c23          	sd	s5,56(a0)
    80002756:	05653023          	sd	s6,64(a0)
    8000275a:	05753423          	sd	s7,72(a0)
    8000275e:	05853823          	sd	s8,80(a0)
    80002762:	05953c23          	sd	s9,88(a0)
    80002766:	07a53023          	sd	s10,96(a0)
    8000276a:	07b53423          	sd	s11,104(a0)
    8000276e:	0005b083          	ld	ra,0(a1)
    80002772:	0085b103          	ld	sp,8(a1)
    80002776:	6980                	ld	s0,16(a1)
    80002778:	6d84                	ld	s1,24(a1)
    8000277a:	0205b903          	ld	s2,32(a1)
    8000277e:	0285b983          	ld	s3,40(a1)
    80002782:	0305ba03          	ld	s4,48(a1)
    80002786:	0385ba83          	ld	s5,56(a1)
    8000278a:	0405bb03          	ld	s6,64(a1)
    8000278e:	0485bb83          	ld	s7,72(a1)
    80002792:	0505bc03          	ld	s8,80(a1)
    80002796:	0585bc83          	ld	s9,88(a1)
    8000279a:	0605bd03          	ld	s10,96(a1)
    8000279e:	0685bd83          	ld	s11,104(a1)
    800027a2:	8082                	ret

00000000800027a4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027a4:	1141                	addi	sp,sp,-16
    800027a6:	e406                	sd	ra,8(sp)
    800027a8:	e022                	sd	s0,0(sp)
    800027aa:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027ac:	00006597          	auipc	a1,0x6
    800027b0:	b3458593          	addi	a1,a1,-1228 # 800082e0 <states.1737+0x28>
    800027b4:	00021517          	auipc	a0,0x21
    800027b8:	90450513          	addi	a0,a0,-1788 # 800230b8 <tickslock>
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	38a080e7          	jalr	906(ra) # 80000b46 <initlock>
}
    800027c4:	60a2                	ld	ra,8(sp)
    800027c6:	6402                	ld	s0,0(sp)
    800027c8:	0141                	addi	sp,sp,16
    800027ca:	8082                	ret

00000000800027cc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027cc:	1141                	addi	sp,sp,-16
    800027ce:	e422                	sd	s0,8(sp)
    800027d0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027d2:	00004797          	auipc	a5,0x4
    800027d6:	83e78793          	addi	a5,a5,-1986 # 80006010 <kernelvec>
    800027da:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027de:	6422                	ld	s0,8(sp)
    800027e0:	0141                	addi	sp,sp,16
    800027e2:	8082                	ret

00000000800027e4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027e4:	1141                	addi	sp,sp,-16
    800027e6:	e406                	sd	ra,8(sp)
    800027e8:	e022                	sd	s0,0(sp)
    800027ea:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	2e8080e7          	jalr	744(ra) # 80001ad4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027f4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027f8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027fa:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027fe:	00005617          	auipc	a2,0x5
    80002802:	80260613          	addi	a2,a2,-2046 # 80007000 <_trampoline>
    80002806:	00004697          	auipc	a3,0x4
    8000280a:	7fa68693          	addi	a3,a3,2042 # 80007000 <_trampoline>
    8000280e:	8e91                	sub	a3,a3,a2
    80002810:	040007b7          	lui	a5,0x4000
    80002814:	17fd                	addi	a5,a5,-1
    80002816:	07b2                	slli	a5,a5,0xc
    80002818:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000281a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000281e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002820:	180026f3          	csrr	a3,satp
    80002824:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002826:	6d38                	ld	a4,88(a0)
    80002828:	6134                	ld	a3,64(a0)
    8000282a:	6585                	lui	a1,0x1
    8000282c:	96ae                	add	a3,a3,a1
    8000282e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002830:	6d38                	ld	a4,88(a0)
    80002832:	00000697          	auipc	a3,0x0
    80002836:	13868693          	addi	a3,a3,312 # 8000296a <usertrap>
    8000283a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000283c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000283e:	8692                	mv	a3,tp
    80002840:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002842:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002846:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000284a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000284e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002852:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002854:	6f18                	ld	a4,24(a4)
    80002856:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000285a:	692c                	ld	a1,80(a0)
    8000285c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000285e:	00005717          	auipc	a4,0x5
    80002862:	83270713          	addi	a4,a4,-1998 # 80007090 <userret>
    80002866:	8f11                	sub	a4,a4,a2
    80002868:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000286a:	577d                	li	a4,-1
    8000286c:	177e                	slli	a4,a4,0x3f
    8000286e:	8dd9                	or	a1,a1,a4
    80002870:	02000537          	lui	a0,0x2000
    80002874:	157d                	addi	a0,a0,-1
    80002876:	0536                	slli	a0,a0,0xd
    80002878:	9782                	jalr	a5
}
    8000287a:	60a2                	ld	ra,8(sp)
    8000287c:	6402                	ld	s0,0(sp)
    8000287e:	0141                	addi	sp,sp,16
    80002880:	8082                	ret

0000000080002882 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002882:	1101                	addi	sp,sp,-32
    80002884:	ec06                	sd	ra,24(sp)
    80002886:	e822                	sd	s0,16(sp)
    80002888:	e426                	sd	s1,8(sp)
    8000288a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000288c:	00021497          	auipc	s1,0x21
    80002890:	82c48493          	addi	s1,s1,-2004 # 800230b8 <tickslock>
    80002894:	8526                	mv	a0,s1
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	340080e7          	jalr	832(ra) # 80000bd6 <acquire>
  ticks++;
    8000289e:	00006517          	auipc	a0,0x6
    800028a2:	79250513          	addi	a0,a0,1938 # 80009030 <ticks>
    800028a6:	411c                	lw	a5,0(a0)
    800028a8:	2785                	addiw	a5,a5,1
    800028aa:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	c58080e7          	jalr	-936(ra) # 80002504 <wakeup>
  release(&tickslock);
    800028b4:	8526                	mv	a0,s1
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	3d4080e7          	jalr	980(ra) # 80000c8a <release>
}
    800028be:	60e2                	ld	ra,24(sp)
    800028c0:	6442                	ld	s0,16(sp)
    800028c2:	64a2                	ld	s1,8(sp)
    800028c4:	6105                	addi	sp,sp,32
    800028c6:	8082                	ret

00000000800028c8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028c8:	1101                	addi	sp,sp,-32
    800028ca:	ec06                	sd	ra,24(sp)
    800028cc:	e822                	sd	s0,16(sp)
    800028ce:	e426                	sd	s1,8(sp)
    800028d0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028d6:	00074d63          	bltz	a4,800028f0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028da:	57fd                	li	a5,-1
    800028dc:	17fe                	slli	a5,a5,0x3f
    800028de:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028e0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028e2:	06f70363          	beq	a4,a5,80002948 <devintr+0x80>
  }
}
    800028e6:	60e2                	ld	ra,24(sp)
    800028e8:	6442                	ld	s0,16(sp)
    800028ea:	64a2                	ld	s1,8(sp)
    800028ec:	6105                	addi	sp,sp,32
    800028ee:	8082                	ret
     (scause & 0xff) == 9){
    800028f0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028f4:	46a5                	li	a3,9
    800028f6:	fed792e3          	bne	a5,a3,800028da <devintr+0x12>
    int irq = plic_claim();
    800028fa:	00004097          	auipc	ra,0x4
    800028fe:	81e080e7          	jalr	-2018(ra) # 80006118 <plic_claim>
    80002902:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002904:	47a9                	li	a5,10
    80002906:	02f50763          	beq	a0,a5,80002934 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000290a:	4785                	li	a5,1
    8000290c:	02f50963          	beq	a0,a5,8000293e <devintr+0x76>
    return 1;
    80002910:	4505                	li	a0,1
    } else if(irq){
    80002912:	d8f1                	beqz	s1,800028e6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002914:	85a6                	mv	a1,s1
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	9d250513          	addi	a0,a0,-1582 # 800082e8 <states.1737+0x30>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c5c080e7          	jalr	-932(ra) # 8000057a <printf>
      plic_complete(irq);
    80002926:	8526                	mv	a0,s1
    80002928:	00004097          	auipc	ra,0x4
    8000292c:	814080e7          	jalr	-2028(ra) # 8000613c <plic_complete>
    return 1;
    80002930:	4505                	li	a0,1
    80002932:	bf55                	j	800028e6 <devintr+0x1e>
      uartintr();
    80002934:	ffffe097          	auipc	ra,0xffffe
    80002938:	066080e7          	jalr	102(ra) # 8000099a <uartintr>
    8000293c:	b7ed                	j	80002926 <devintr+0x5e>
      virtio_disk_intr();
    8000293e:	00004097          	auipc	ra,0x4
    80002942:	cde080e7          	jalr	-802(ra) # 8000661c <virtio_disk_intr>
    80002946:	b7c5                	j	80002926 <devintr+0x5e>
    if(cpuid() == 0){
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	160080e7          	jalr	352(ra) # 80001aa8 <cpuid>
    80002950:	c901                	beqz	a0,80002960 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002952:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002956:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002958:	14479073          	csrw	sip,a5
    return 2;
    8000295c:	4509                	li	a0,2
    8000295e:	b761                	j	800028e6 <devintr+0x1e>
      clockintr();
    80002960:	00000097          	auipc	ra,0x0
    80002964:	f22080e7          	jalr	-222(ra) # 80002882 <clockintr>
    80002968:	b7ed                	j	80002952 <devintr+0x8a>

000000008000296a <usertrap>:
{
    8000296a:	1101                	addi	sp,sp,-32
    8000296c:	ec06                	sd	ra,24(sp)
    8000296e:	e822                	sd	s0,16(sp)
    80002970:	e426                	sd	s1,8(sp)
    80002972:	e04a                	sd	s2,0(sp)
    80002974:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002976:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000297a:	1007f793          	andi	a5,a5,256
    8000297e:	e3ad                	bnez	a5,800029e0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002980:	00003797          	auipc	a5,0x3
    80002984:	69078793          	addi	a5,a5,1680 # 80006010 <kernelvec>
    80002988:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000298c:	fffff097          	auipc	ra,0xfffff
    80002990:	148080e7          	jalr	328(ra) # 80001ad4 <myproc>
    80002994:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002996:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002998:	14102773          	csrr	a4,sepc
    8000299c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029a2:	47a1                	li	a5,8
    800029a4:	04f71c63          	bne	a4,a5,800029fc <usertrap+0x92>
    if(p->killed)
    800029a8:	591c                	lw	a5,48(a0)
    800029aa:	e3b9                	bnez	a5,800029f0 <usertrap+0x86>
    p->trapframe->epc += 4;
    800029ac:	6cb8                	ld	a4,88(s1)
    800029ae:	6f1c                	ld	a5,24(a4)
    800029b0:	0791                	addi	a5,a5,4
    800029b2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029b8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10079073          	csrw	sstatus,a5
    syscall();
    800029c0:	00000097          	auipc	ra,0x0
    800029c4:	304080e7          	jalr	772(ra) # 80002cc4 <syscall>
  if(p->killed)
    800029c8:	589c                	lw	a5,48(s1)
    800029ca:	ebd5                	bnez	a5,80002a7e <usertrap+0x114>
  usertrapret();
    800029cc:	00000097          	auipc	ra,0x0
    800029d0:	e18080e7          	jalr	-488(ra) # 800027e4 <usertrapret>
}
    800029d4:	60e2                	ld	ra,24(sp)
    800029d6:	6442                	ld	s0,16(sp)
    800029d8:	64a2                	ld	s1,8(sp)
    800029da:	6902                	ld	s2,0(sp)
    800029dc:	6105                	addi	sp,sp,32
    800029de:	8082                	ret
    panic("usertrap: not from user mode");
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	92850513          	addi	a0,a0,-1752 # 80008308 <states.1737+0x50>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	b48080e7          	jalr	-1208(ra) # 80000530 <panic>
      exit(-1);
    800029f0:	557d                	li	a0,-1
    800029f2:	00000097          	auipc	ra,0x0
    800029f6:	846080e7          	jalr	-1978(ra) # 80002238 <exit>
    800029fa:	bf4d                	j	800029ac <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	ecc080e7          	jalr	-308(ra) # 800028c8 <devintr>
    80002a04:	892a                	mv	s2,a0
    80002a06:	e92d                	bnez	a0,80002a78 <usertrap+0x10e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a08:	14302573          	csrr	a0,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0c:	14202773          	csrr	a4,scause
    if((r_scause() == 13 || r_scause() == 15)){ // vma lazy allocation
    80002a10:	47b5                	li	a5,13
    80002a12:	04f70d63          	beq	a4,a5,80002a6c <usertrap+0x102>
    80002a16:	14202773          	csrr	a4,scause
    80002a1a:	47bd                	li	a5,15
    80002a1c:	04f70863          	beq	a4,a5,80002a6c <usertrap+0x102>
    80002a20:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a24:	5c90                	lw	a2,56(s1)
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	90250513          	addi	a0,a0,-1790 # 80008328 <states.1737+0x70>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b4c080e7          	jalr	-1204(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a36:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a3a:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a3e:	00006517          	auipc	a0,0x6
    80002a42:	91a50513          	addi	a0,a0,-1766 # 80008358 <states.1737+0xa0>
    80002a46:	ffffe097          	auipc	ra,0xffffe
    80002a4a:	b34080e7          	jalr	-1228(ra) # 8000057a <printf>
      p->killed = 1;
    80002a4e:	4785                	li	a5,1
    80002a50:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a52:	557d                	li	a0,-1
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	7e4080e7          	jalr	2020(ra) # 80002238 <exit>
  if(which_dev == 2)
    80002a5c:	4789                	li	a5,2
    80002a5e:	f6f917e3          	bne	s2,a5,800029cc <usertrap+0x62>
    yield();
    80002a62:	00000097          	auipc	ra,0x0
    80002a66:	8e0080e7          	jalr	-1824(ra) # 80002342 <yield>
    80002a6a:	b78d                	j	800029cc <usertrap+0x62>
      if(!vmatrylazytouch(va)) {
    80002a6c:	00003097          	auipc	ra,0x3
    80002a70:	3ba080e7          	jalr	954(ra) # 80005e26 <vmatrylazytouch>
    80002a74:	f931                	bnez	a0,800029c8 <usertrap+0x5e>
    80002a76:	b76d                	j	80002a20 <usertrap+0xb6>
  if(p->killed)
    80002a78:	589c                	lw	a5,48(s1)
    80002a7a:	d3ed                	beqz	a5,80002a5c <usertrap+0xf2>
    80002a7c:	bfd9                	j	80002a52 <usertrap+0xe8>
    80002a7e:	4901                	li	s2,0
    80002a80:	bfc9                	j	80002a52 <usertrap+0xe8>

0000000080002a82 <kerneltrap>:
{
    80002a82:	7179                	addi	sp,sp,-48
    80002a84:	f406                	sd	ra,40(sp)
    80002a86:	f022                	sd	s0,32(sp)
    80002a88:	ec26                	sd	s1,24(sp)
    80002a8a:	e84a                	sd	s2,16(sp)
    80002a8c:	e44e                	sd	s3,8(sp)
    80002a8e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a90:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a94:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a98:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a9c:	1004f793          	andi	a5,s1,256
    80002aa0:	cb85                	beqz	a5,80002ad0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aa2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aa6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aa8:	ef85                	bnez	a5,80002ae0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	e1e080e7          	jalr	-482(ra) # 800028c8 <devintr>
    80002ab2:	cd1d                	beqz	a0,80002af0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab4:	4789                	li	a5,2
    80002ab6:	06f50a63          	beq	a0,a5,80002b2a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002aba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002abe:	10049073          	csrw	sstatus,s1
}
    80002ac2:	70a2                	ld	ra,40(sp)
    80002ac4:	7402                	ld	s0,32(sp)
    80002ac6:	64e2                	ld	s1,24(sp)
    80002ac8:	6942                	ld	s2,16(sp)
    80002aca:	69a2                	ld	s3,8(sp)
    80002acc:	6145                	addi	sp,sp,48
    80002ace:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ad0:	00006517          	auipc	a0,0x6
    80002ad4:	8a850513          	addi	a0,a0,-1880 # 80008378 <states.1737+0xc0>
    80002ad8:	ffffe097          	auipc	ra,0xffffe
    80002adc:	a58080e7          	jalr	-1448(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	8c050513          	addi	a0,a0,-1856 # 800083a0 <states.1737+0xe8>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	a48080e7          	jalr	-1464(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    80002af0:	85ce                	mv	a1,s3
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	8ce50513          	addi	a0,a0,-1842 # 800083c0 <states.1737+0x108>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a80080e7          	jalr	-1408(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b06:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b0a:	00006517          	auipc	a0,0x6
    80002b0e:	8c650513          	addi	a0,a0,-1850 # 800083d0 <states.1737+0x118>
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	a68080e7          	jalr	-1432(ra) # 8000057a <printf>
    panic("kerneltrap");
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	8ce50513          	addi	a0,a0,-1842 # 800083e8 <states.1737+0x130>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a0e080e7          	jalr	-1522(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	faa080e7          	jalr	-86(ra) # 80001ad4 <myproc>
    80002b32:	d541                	beqz	a0,80002aba <kerneltrap+0x38>
    80002b34:	fffff097          	auipc	ra,0xfffff
    80002b38:	fa0080e7          	jalr	-96(ra) # 80001ad4 <myproc>
    80002b3c:	4d18                	lw	a4,24(a0)
    80002b3e:	478d                	li	a5,3
    80002b40:	f6f71de3          	bne	a4,a5,80002aba <kerneltrap+0x38>
    yield();
    80002b44:	fffff097          	auipc	ra,0xfffff
    80002b48:	7fe080e7          	jalr	2046(ra) # 80002342 <yield>
    80002b4c:	b7bd                	j	80002aba <kerneltrap+0x38>

0000000080002b4e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	1000                	addi	s0,sp,32
    80002b58:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b5a:	fffff097          	auipc	ra,0xfffff
    80002b5e:	f7a080e7          	jalr	-134(ra) # 80001ad4 <myproc>
  switch (n) {
    80002b62:	4795                	li	a5,5
    80002b64:	0497e163          	bltu	a5,s1,80002ba6 <argraw+0x58>
    80002b68:	048a                	slli	s1,s1,0x2
    80002b6a:	00006717          	auipc	a4,0x6
    80002b6e:	8b670713          	addi	a4,a4,-1866 # 80008420 <states.1737+0x168>
    80002b72:	94ba                	add	s1,s1,a4
    80002b74:	409c                	lw	a5,0(s1)
    80002b76:	97ba                	add	a5,a5,a4
    80002b78:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b7a:	6d3c                	ld	a5,88(a0)
    80002b7c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b7e:	60e2                	ld	ra,24(sp)
    80002b80:	6442                	ld	s0,16(sp)
    80002b82:	64a2                	ld	s1,8(sp)
    80002b84:	6105                	addi	sp,sp,32
    80002b86:	8082                	ret
    return p->trapframe->a1;
    80002b88:	6d3c                	ld	a5,88(a0)
    80002b8a:	7fa8                	ld	a0,120(a5)
    80002b8c:	bfcd                	j	80002b7e <argraw+0x30>
    return p->trapframe->a2;
    80002b8e:	6d3c                	ld	a5,88(a0)
    80002b90:	63c8                	ld	a0,128(a5)
    80002b92:	b7f5                	j	80002b7e <argraw+0x30>
    return p->trapframe->a3;
    80002b94:	6d3c                	ld	a5,88(a0)
    80002b96:	67c8                	ld	a0,136(a5)
    80002b98:	b7dd                	j	80002b7e <argraw+0x30>
    return p->trapframe->a4;
    80002b9a:	6d3c                	ld	a5,88(a0)
    80002b9c:	6bc8                	ld	a0,144(a5)
    80002b9e:	b7c5                	j	80002b7e <argraw+0x30>
    return p->trapframe->a5;
    80002ba0:	6d3c                	ld	a5,88(a0)
    80002ba2:	6fc8                	ld	a0,152(a5)
    80002ba4:	bfe9                	j	80002b7e <argraw+0x30>
  panic("argraw");
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	85250513          	addi	a0,a0,-1966 # 800083f8 <states.1737+0x140>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	982080e7          	jalr	-1662(ra) # 80000530 <panic>

0000000080002bb6 <fetchaddr>:
{
    80002bb6:	1101                	addi	sp,sp,-32
    80002bb8:	ec06                	sd	ra,24(sp)
    80002bba:	e822                	sd	s0,16(sp)
    80002bbc:	e426                	sd	s1,8(sp)
    80002bbe:	e04a                	sd	s2,0(sp)
    80002bc0:	1000                	addi	s0,sp,32
    80002bc2:	84aa                	mv	s1,a0
    80002bc4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	f0e080e7          	jalr	-242(ra) # 80001ad4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bce:	653c                	ld	a5,72(a0)
    80002bd0:	02f4f863          	bgeu	s1,a5,80002c00 <fetchaddr+0x4a>
    80002bd4:	00848713          	addi	a4,s1,8
    80002bd8:	02e7e663          	bltu	a5,a4,80002c04 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bdc:	46a1                	li	a3,8
    80002bde:	8626                	mv	a2,s1
    80002be0:	85ca                	mv	a1,s2
    80002be2:	6928                	ld	a0,80(a0)
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	c12080e7          	jalr	-1006(ra) # 800017f6 <copyin>
    80002bec:	00a03533          	snez	a0,a0
    80002bf0:	40a00533          	neg	a0,a0
}
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	64a2                	ld	s1,8(sp)
    80002bfa:	6902                	ld	s2,0(sp)
    80002bfc:	6105                	addi	sp,sp,32
    80002bfe:	8082                	ret
    return -1;
    80002c00:	557d                	li	a0,-1
    80002c02:	bfcd                	j	80002bf4 <fetchaddr+0x3e>
    80002c04:	557d                	li	a0,-1
    80002c06:	b7fd                	j	80002bf4 <fetchaddr+0x3e>

0000000080002c08 <fetchstr>:
{
    80002c08:	7179                	addi	sp,sp,-48
    80002c0a:	f406                	sd	ra,40(sp)
    80002c0c:	f022                	sd	s0,32(sp)
    80002c0e:	ec26                	sd	s1,24(sp)
    80002c10:	e84a                	sd	s2,16(sp)
    80002c12:	e44e                	sd	s3,8(sp)
    80002c14:	1800                	addi	s0,sp,48
    80002c16:	892a                	mv	s2,a0
    80002c18:	84ae                	mv	s1,a1
    80002c1a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c1c:	fffff097          	auipc	ra,0xfffff
    80002c20:	eb8080e7          	jalr	-328(ra) # 80001ad4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c24:	86ce                	mv	a3,s3
    80002c26:	864a                	mv	a2,s2
    80002c28:	85a6                	mv	a1,s1
    80002c2a:	6928                	ld	a0,80(a0)
    80002c2c:	fffff097          	auipc	ra,0xfffff
    80002c30:	c56080e7          	jalr	-938(ra) # 80001882 <copyinstr>
  if(err < 0)
    80002c34:	00054763          	bltz	a0,80002c42 <fetchstr+0x3a>
  return strlen(buf);
    80002c38:	8526                	mv	a0,s1
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	220080e7          	jalr	544(ra) # 80000e5a <strlen>
}
    80002c42:	70a2                	ld	ra,40(sp)
    80002c44:	7402                	ld	s0,32(sp)
    80002c46:	64e2                	ld	s1,24(sp)
    80002c48:	6942                	ld	s2,16(sp)
    80002c4a:	69a2                	ld	s3,8(sp)
    80002c4c:	6145                	addi	sp,sp,48
    80002c4e:	8082                	ret

0000000080002c50 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c50:	1101                	addi	sp,sp,-32
    80002c52:	ec06                	sd	ra,24(sp)
    80002c54:	e822                	sd	s0,16(sp)
    80002c56:	e426                	sd	s1,8(sp)
    80002c58:	1000                	addi	s0,sp,32
    80002c5a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c5c:	00000097          	auipc	ra,0x0
    80002c60:	ef2080e7          	jalr	-270(ra) # 80002b4e <argraw>
    80002c64:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c66:	4501                	li	a0,0
    80002c68:	60e2                	ld	ra,24(sp)
    80002c6a:	6442                	ld	s0,16(sp)
    80002c6c:	64a2                	ld	s1,8(sp)
    80002c6e:	6105                	addi	sp,sp,32
    80002c70:	8082                	ret

0000000080002c72 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c72:	1101                	addi	sp,sp,-32
    80002c74:	ec06                	sd	ra,24(sp)
    80002c76:	e822                	sd	s0,16(sp)
    80002c78:	e426                	sd	s1,8(sp)
    80002c7a:	1000                	addi	s0,sp,32
    80002c7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	ed0080e7          	jalr	-304(ra) # 80002b4e <argraw>
    80002c86:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c88:	4501                	li	a0,0
    80002c8a:	60e2                	ld	ra,24(sp)
    80002c8c:	6442                	ld	s0,16(sp)
    80002c8e:	64a2                	ld	s1,8(sp)
    80002c90:	6105                	addi	sp,sp,32
    80002c92:	8082                	ret

0000000080002c94 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	e426                	sd	s1,8(sp)
    80002c9c:	e04a                	sd	s2,0(sp)
    80002c9e:	1000                	addi	s0,sp,32
    80002ca0:	84ae                	mv	s1,a1
    80002ca2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ca4:	00000097          	auipc	ra,0x0
    80002ca8:	eaa080e7          	jalr	-342(ra) # 80002b4e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cac:	864a                	mv	a2,s2
    80002cae:	85a6                	mv	a1,s1
    80002cb0:	00000097          	auipc	ra,0x0
    80002cb4:	f58080e7          	jalr	-168(ra) # 80002c08 <fetchstr>
}
    80002cb8:	60e2                	ld	ra,24(sp)
    80002cba:	6442                	ld	s0,16(sp)
    80002cbc:	64a2                	ld	s1,8(sp)
    80002cbe:	6902                	ld	s2,0(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret

0000000080002cc4 <syscall>:
[SYS_munmap]  sys_munmap,
};

void
syscall(void)
{
    80002cc4:	1101                	addi	sp,sp,-32
    80002cc6:	ec06                	sd	ra,24(sp)
    80002cc8:	e822                	sd	s0,16(sp)
    80002cca:	e426                	sd	s1,8(sp)
    80002ccc:	e04a                	sd	s2,0(sp)
    80002cce:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cd0:	fffff097          	auipc	ra,0xfffff
    80002cd4:	e04080e7          	jalr	-508(ra) # 80001ad4 <myproc>
    80002cd8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cda:	05853903          	ld	s2,88(a0)
    80002cde:	0a893783          	ld	a5,168(s2)
    80002ce2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ce6:	37fd                	addiw	a5,a5,-1
    80002ce8:	4759                	li	a4,22
    80002cea:	00f76f63          	bltu	a4,a5,80002d08 <syscall+0x44>
    80002cee:	00369713          	slli	a4,a3,0x3
    80002cf2:	00005797          	auipc	a5,0x5
    80002cf6:	74678793          	addi	a5,a5,1862 # 80008438 <syscalls>
    80002cfa:	97ba                	add	a5,a5,a4
    80002cfc:	639c                	ld	a5,0(a5)
    80002cfe:	c789                	beqz	a5,80002d08 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d00:	9782                	jalr	a5
    80002d02:	06a93823          	sd	a0,112(s2)
    80002d06:	a839                	j	80002d24 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d08:	15848613          	addi	a2,s1,344
    80002d0c:	5c8c                	lw	a1,56(s1)
    80002d0e:	00005517          	auipc	a0,0x5
    80002d12:	6f250513          	addi	a0,a0,1778 # 80008400 <states.1737+0x148>
    80002d16:	ffffe097          	auipc	ra,0xffffe
    80002d1a:	864080e7          	jalr	-1948(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d1e:	6cbc                	ld	a5,88(s1)
    80002d20:	577d                	li	a4,-1
    80002d22:	fbb8                	sd	a4,112(a5)
  }
}
    80002d24:	60e2                	ld	ra,24(sp)
    80002d26:	6442                	ld	s0,16(sp)
    80002d28:	64a2                	ld	s1,8(sp)
    80002d2a:	6902                	ld	s2,0(sp)
    80002d2c:	6105                	addi	sp,sp,32
    80002d2e:	8082                	ret

0000000080002d30 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d30:	1101                	addi	sp,sp,-32
    80002d32:	ec06                	sd	ra,24(sp)
    80002d34:	e822                	sd	s0,16(sp)
    80002d36:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d38:	fec40593          	addi	a1,s0,-20
    80002d3c:	4501                	li	a0,0
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	f12080e7          	jalr	-238(ra) # 80002c50 <argint>
    return -1;
    80002d46:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d48:	00054963          	bltz	a0,80002d5a <sys_exit+0x2a>
  exit(n);
    80002d4c:	fec42503          	lw	a0,-20(s0)
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	4e8080e7          	jalr	1256(ra) # 80002238 <exit>
  return 0;  // not reached
    80002d58:	4781                	li	a5,0
}
    80002d5a:	853e                	mv	a0,a5
    80002d5c:	60e2                	ld	ra,24(sp)
    80002d5e:	6442                	ld	s0,16(sp)
    80002d60:	6105                	addi	sp,sp,32
    80002d62:	8082                	ret

0000000080002d64 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d64:	1141                	addi	sp,sp,-16
    80002d66:	e406                	sd	ra,8(sp)
    80002d68:	e022                	sd	s0,0(sp)
    80002d6a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	d68080e7          	jalr	-664(ra) # 80001ad4 <myproc>
}
    80002d74:	5d08                	lw	a0,56(a0)
    80002d76:	60a2                	ld	ra,8(sp)
    80002d78:	6402                	ld	s0,0(sp)
    80002d7a:	0141                	addi	sp,sp,16
    80002d7c:	8082                	ret

0000000080002d7e <sys_fork>:

uint64
sys_fork(void)
{
    80002d7e:	1141                	addi	sp,sp,-16
    80002d80:	e406                	sd	ra,8(sp)
    80002d82:	e022                	sd	s0,0(sp)
    80002d84:	0800                	addi	s0,sp,16
  return fork();
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	154080e7          	jalr	340(ra) # 80001eda <fork>
}
    80002d8e:	60a2                	ld	ra,8(sp)
    80002d90:	6402                	ld	s0,0(sp)
    80002d92:	0141                	addi	sp,sp,16
    80002d94:	8082                	ret

0000000080002d96 <sys_wait>:

uint64
sys_wait(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d9e:	fe840593          	addi	a1,s0,-24
    80002da2:	4501                	li	a0,0
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	ece080e7          	jalr	-306(ra) # 80002c72 <argaddr>
    80002dac:	87aa                	mv	a5,a0
    return -1;
    80002dae:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002db0:	0007c863          	bltz	a5,80002dc0 <sys_wait+0x2a>
  return wait(p);
    80002db4:	fe843503          	ld	a0,-24(s0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	644080e7          	jalr	1604(ra) # 800023fc <wait>
}
    80002dc0:	60e2                	ld	ra,24(sp)
    80002dc2:	6442                	ld	s0,16(sp)
    80002dc4:	6105                	addi	sp,sp,32
    80002dc6:	8082                	ret

0000000080002dc8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dc8:	7179                	addi	sp,sp,-48
    80002dca:	f406                	sd	ra,40(sp)
    80002dcc:	f022                	sd	s0,32(sp)
    80002dce:	ec26                	sd	s1,24(sp)
    80002dd0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dd2:	fdc40593          	addi	a1,s0,-36
    80002dd6:	4501                	li	a0,0
    80002dd8:	00000097          	auipc	ra,0x0
    80002ddc:	e78080e7          	jalr	-392(ra) # 80002c50 <argint>
    80002de0:	87aa                	mv	a5,a0
    return -1;
    80002de2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002de4:	0207c063          	bltz	a5,80002e04 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	cec080e7          	jalr	-788(ra) # 80001ad4 <myproc>
    80002df0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002df2:	fdc42503          	lw	a0,-36(s0)
    80002df6:	fffff097          	auipc	ra,0xfffff
    80002dfa:	070080e7          	jalr	112(ra) # 80001e66 <growproc>
    80002dfe:	00054863          	bltz	a0,80002e0e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e02:	8526                	mv	a0,s1
}
    80002e04:	70a2                	ld	ra,40(sp)
    80002e06:	7402                	ld	s0,32(sp)
    80002e08:	64e2                	ld	s1,24(sp)
    80002e0a:	6145                	addi	sp,sp,48
    80002e0c:	8082                	ret
    return -1;
    80002e0e:	557d                	li	a0,-1
    80002e10:	bfd5                	j	80002e04 <sys_sbrk+0x3c>

0000000080002e12 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e12:	7139                	addi	sp,sp,-64
    80002e14:	fc06                	sd	ra,56(sp)
    80002e16:	f822                	sd	s0,48(sp)
    80002e18:	f426                	sd	s1,40(sp)
    80002e1a:	f04a                	sd	s2,32(sp)
    80002e1c:	ec4e                	sd	s3,24(sp)
    80002e1e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e20:	fcc40593          	addi	a1,s0,-52
    80002e24:	4501                	li	a0,0
    80002e26:	00000097          	auipc	ra,0x0
    80002e2a:	e2a080e7          	jalr	-470(ra) # 80002c50 <argint>
    return -1;
    80002e2e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e30:	06054563          	bltz	a0,80002e9a <sys_sleep+0x88>
  acquire(&tickslock);
    80002e34:	00020517          	auipc	a0,0x20
    80002e38:	28450513          	addi	a0,a0,644 # 800230b8 <tickslock>
    80002e3c:	ffffe097          	auipc	ra,0xffffe
    80002e40:	d9a080e7          	jalr	-614(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e44:	00006917          	auipc	s2,0x6
    80002e48:	1ec92903          	lw	s2,492(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002e4c:	fcc42783          	lw	a5,-52(s0)
    80002e50:	cf85                	beqz	a5,80002e88 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e52:	00020997          	auipc	s3,0x20
    80002e56:	26698993          	addi	s3,s3,614 # 800230b8 <tickslock>
    80002e5a:	00006497          	auipc	s1,0x6
    80002e5e:	1d648493          	addi	s1,s1,470 # 80009030 <ticks>
    if(myproc()->killed){
    80002e62:	fffff097          	auipc	ra,0xfffff
    80002e66:	c72080e7          	jalr	-910(ra) # 80001ad4 <myproc>
    80002e6a:	591c                	lw	a5,48(a0)
    80002e6c:	ef9d                	bnez	a5,80002eaa <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e6e:	85ce                	mv	a1,s3
    80002e70:	8526                	mv	a0,s1
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	50c080e7          	jalr	1292(ra) # 8000237e <sleep>
  while(ticks - ticks0 < n){
    80002e7a:	409c                	lw	a5,0(s1)
    80002e7c:	412787bb          	subw	a5,a5,s2
    80002e80:	fcc42703          	lw	a4,-52(s0)
    80002e84:	fce7efe3          	bltu	a5,a4,80002e62 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e88:	00020517          	auipc	a0,0x20
    80002e8c:	23050513          	addi	a0,a0,560 # 800230b8 <tickslock>
    80002e90:	ffffe097          	auipc	ra,0xffffe
    80002e94:	dfa080e7          	jalr	-518(ra) # 80000c8a <release>
  return 0;
    80002e98:	4781                	li	a5,0
}
    80002e9a:	853e                	mv	a0,a5
    80002e9c:	70e2                	ld	ra,56(sp)
    80002e9e:	7442                	ld	s0,48(sp)
    80002ea0:	74a2                	ld	s1,40(sp)
    80002ea2:	7902                	ld	s2,32(sp)
    80002ea4:	69e2                	ld	s3,24(sp)
    80002ea6:	6121                	addi	sp,sp,64
    80002ea8:	8082                	ret
      release(&tickslock);
    80002eaa:	00020517          	auipc	a0,0x20
    80002eae:	20e50513          	addi	a0,a0,526 # 800230b8 <tickslock>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	dd8080e7          	jalr	-552(ra) # 80000c8a <release>
      return -1;
    80002eba:	57fd                	li	a5,-1
    80002ebc:	bff9                	j	80002e9a <sys_sleep+0x88>

0000000080002ebe <sys_kill>:

uint64
sys_kill(void)
{
    80002ebe:	1101                	addi	sp,sp,-32
    80002ec0:	ec06                	sd	ra,24(sp)
    80002ec2:	e822                	sd	s0,16(sp)
    80002ec4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ec6:	fec40593          	addi	a1,s0,-20
    80002eca:	4501                	li	a0,0
    80002ecc:	00000097          	auipc	ra,0x0
    80002ed0:	d84080e7          	jalr	-636(ra) # 80002c50 <argint>
    80002ed4:	87aa                	mv	a5,a0
    return -1;
    80002ed6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ed8:	0007c863          	bltz	a5,80002ee8 <sys_kill+0x2a>
  return kill(pid);
    80002edc:	fec42503          	lw	a0,-20(s0)
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	68e080e7          	jalr	1678(ra) # 8000256e <kill>
}
    80002ee8:	60e2                	ld	ra,24(sp)
    80002eea:	6442                	ld	s0,16(sp)
    80002eec:	6105                	addi	sp,sp,32
    80002eee:	8082                	ret

0000000080002ef0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ef0:	1101                	addi	sp,sp,-32
    80002ef2:	ec06                	sd	ra,24(sp)
    80002ef4:	e822                	sd	s0,16(sp)
    80002ef6:	e426                	sd	s1,8(sp)
    80002ef8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002efa:	00020517          	auipc	a0,0x20
    80002efe:	1be50513          	addi	a0,a0,446 # 800230b8 <tickslock>
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	cd4080e7          	jalr	-812(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f0a:	00006497          	auipc	s1,0x6
    80002f0e:	1264a483          	lw	s1,294(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f12:	00020517          	auipc	a0,0x20
    80002f16:	1a650513          	addi	a0,a0,422 # 800230b8 <tickslock>
    80002f1a:	ffffe097          	auipc	ra,0xffffe
    80002f1e:	d70080e7          	jalr	-656(ra) # 80000c8a <release>
  return xticks;
}
    80002f22:	02049513          	slli	a0,s1,0x20
    80002f26:	9101                	srli	a0,a0,0x20
    80002f28:	60e2                	ld	ra,24(sp)
    80002f2a:	6442                	ld	s0,16(sp)
    80002f2c:	64a2                	ld	s1,8(sp)
    80002f2e:	6105                	addi	sp,sp,32
    80002f30:	8082                	ret

0000000080002f32 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f32:	7179                	addi	sp,sp,-48
    80002f34:	f406                	sd	ra,40(sp)
    80002f36:	f022                	sd	s0,32(sp)
    80002f38:	ec26                	sd	s1,24(sp)
    80002f3a:	e84a                	sd	s2,16(sp)
    80002f3c:	e44e                	sd	s3,8(sp)
    80002f3e:	e052                	sd	s4,0(sp)
    80002f40:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f42:	00005597          	auipc	a1,0x5
    80002f46:	5b658593          	addi	a1,a1,1462 # 800084f8 <syscalls+0xc0>
    80002f4a:	00020517          	auipc	a0,0x20
    80002f4e:	18650513          	addi	a0,a0,390 # 800230d0 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	bf4080e7          	jalr	-1036(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f5a:	00028797          	auipc	a5,0x28
    80002f5e:	17678793          	addi	a5,a5,374 # 8002b0d0 <bcache+0x8000>
    80002f62:	00028717          	auipc	a4,0x28
    80002f66:	3d670713          	addi	a4,a4,982 # 8002b338 <bcache+0x8268>
    80002f6a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f6e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f72:	00020497          	auipc	s1,0x20
    80002f76:	17648493          	addi	s1,s1,374 # 800230e8 <bcache+0x18>
    b->next = bcache.head.next;
    80002f7a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f7c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f7e:	00005a17          	auipc	s4,0x5
    80002f82:	582a0a13          	addi	s4,s4,1410 # 80008500 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f86:	2b893783          	ld	a5,696(s2)
    80002f8a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f8c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f90:	85d2                	mv	a1,s4
    80002f92:	01048513          	addi	a0,s1,16
    80002f96:	00001097          	auipc	ra,0x1
    80002f9a:	4c4080e7          	jalr	1220(ra) # 8000445a <initsleeplock>
    bcache.head.next->prev = b;
    80002f9e:	2b893783          	ld	a5,696(s2)
    80002fa2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fa4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fa8:	45848493          	addi	s1,s1,1112
    80002fac:	fd349de3          	bne	s1,s3,80002f86 <binit+0x54>
  }
}
    80002fb0:	70a2                	ld	ra,40(sp)
    80002fb2:	7402                	ld	s0,32(sp)
    80002fb4:	64e2                	ld	s1,24(sp)
    80002fb6:	6942                	ld	s2,16(sp)
    80002fb8:	69a2                	ld	s3,8(sp)
    80002fba:	6a02                	ld	s4,0(sp)
    80002fbc:	6145                	addi	sp,sp,48
    80002fbe:	8082                	ret

0000000080002fc0 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fc0:	7179                	addi	sp,sp,-48
    80002fc2:	f406                	sd	ra,40(sp)
    80002fc4:	f022                	sd	s0,32(sp)
    80002fc6:	ec26                	sd	s1,24(sp)
    80002fc8:	e84a                	sd	s2,16(sp)
    80002fca:	e44e                	sd	s3,8(sp)
    80002fcc:	1800                	addi	s0,sp,48
    80002fce:	89aa                	mv	s3,a0
    80002fd0:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fd2:	00020517          	auipc	a0,0x20
    80002fd6:	0fe50513          	addi	a0,a0,254 # 800230d0 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	bfc080e7          	jalr	-1028(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fe2:	00028497          	auipc	s1,0x28
    80002fe6:	3a64b483          	ld	s1,934(s1) # 8002b388 <bcache+0x82b8>
    80002fea:	00028797          	auipc	a5,0x28
    80002fee:	34e78793          	addi	a5,a5,846 # 8002b338 <bcache+0x8268>
    80002ff2:	02f48f63          	beq	s1,a5,80003030 <bread+0x70>
    80002ff6:	873e                	mv	a4,a5
    80002ff8:	a021                	j	80003000 <bread+0x40>
    80002ffa:	68a4                	ld	s1,80(s1)
    80002ffc:	02e48a63          	beq	s1,a4,80003030 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003000:	449c                	lw	a5,8(s1)
    80003002:	ff379ce3          	bne	a5,s3,80002ffa <bread+0x3a>
    80003006:	44dc                	lw	a5,12(s1)
    80003008:	ff2799e3          	bne	a5,s2,80002ffa <bread+0x3a>
      b->refcnt++;
    8000300c:	40bc                	lw	a5,64(s1)
    8000300e:	2785                	addiw	a5,a5,1
    80003010:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003012:	00020517          	auipc	a0,0x20
    80003016:	0be50513          	addi	a0,a0,190 # 800230d0 <bcache>
    8000301a:	ffffe097          	auipc	ra,0xffffe
    8000301e:	c70080e7          	jalr	-912(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003022:	01048513          	addi	a0,s1,16
    80003026:	00001097          	auipc	ra,0x1
    8000302a:	46e080e7          	jalr	1134(ra) # 80004494 <acquiresleep>
      return b;
    8000302e:	a8b9                	j	8000308c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003030:	00028497          	auipc	s1,0x28
    80003034:	3504b483          	ld	s1,848(s1) # 8002b380 <bcache+0x82b0>
    80003038:	00028797          	auipc	a5,0x28
    8000303c:	30078793          	addi	a5,a5,768 # 8002b338 <bcache+0x8268>
    80003040:	00f48863          	beq	s1,a5,80003050 <bread+0x90>
    80003044:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003046:	40bc                	lw	a5,64(s1)
    80003048:	cf81                	beqz	a5,80003060 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000304a:	64a4                	ld	s1,72(s1)
    8000304c:	fee49de3          	bne	s1,a4,80003046 <bread+0x86>
  panic("bget: no buffers");
    80003050:	00005517          	auipc	a0,0x5
    80003054:	4b850513          	addi	a0,a0,1208 # 80008508 <syscalls+0xd0>
    80003058:	ffffd097          	auipc	ra,0xffffd
    8000305c:	4d8080e7          	jalr	1240(ra) # 80000530 <panic>
      b->dev = dev;
    80003060:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003064:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003068:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000306c:	4785                	li	a5,1
    8000306e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003070:	00020517          	auipc	a0,0x20
    80003074:	06050513          	addi	a0,a0,96 # 800230d0 <bcache>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	c12080e7          	jalr	-1006(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003080:	01048513          	addi	a0,s1,16
    80003084:	00001097          	auipc	ra,0x1
    80003088:	410080e7          	jalr	1040(ra) # 80004494 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000308c:	409c                	lw	a5,0(s1)
    8000308e:	cb89                	beqz	a5,800030a0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003090:	8526                	mv	a0,s1
    80003092:	70a2                	ld	ra,40(sp)
    80003094:	7402                	ld	s0,32(sp)
    80003096:	64e2                	ld	s1,24(sp)
    80003098:	6942                	ld	s2,16(sp)
    8000309a:	69a2                	ld	s3,8(sp)
    8000309c:	6145                	addi	sp,sp,48
    8000309e:	8082                	ret
    virtio_disk_rw(b, 0);
    800030a0:	4581                	li	a1,0
    800030a2:	8526                	mv	a0,s1
    800030a4:	00003097          	auipc	ra,0x3
    800030a8:	2a2080e7          	jalr	674(ra) # 80006346 <virtio_disk_rw>
    b->valid = 1;
    800030ac:	4785                	li	a5,1
    800030ae:	c09c                	sw	a5,0(s1)
  return b;
    800030b0:	b7c5                	j	80003090 <bread+0xd0>

00000000800030b2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030b2:	1101                	addi	sp,sp,-32
    800030b4:	ec06                	sd	ra,24(sp)
    800030b6:	e822                	sd	s0,16(sp)
    800030b8:	e426                	sd	s1,8(sp)
    800030ba:	1000                	addi	s0,sp,32
    800030bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030be:	0541                	addi	a0,a0,16
    800030c0:	00001097          	auipc	ra,0x1
    800030c4:	46e080e7          	jalr	1134(ra) # 8000452e <holdingsleep>
    800030c8:	cd01                	beqz	a0,800030e0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030ca:	4585                	li	a1,1
    800030cc:	8526                	mv	a0,s1
    800030ce:	00003097          	auipc	ra,0x3
    800030d2:	278080e7          	jalr	632(ra) # 80006346 <virtio_disk_rw>
}
    800030d6:	60e2                	ld	ra,24(sp)
    800030d8:	6442                	ld	s0,16(sp)
    800030da:	64a2                	ld	s1,8(sp)
    800030dc:	6105                	addi	sp,sp,32
    800030de:	8082                	ret
    panic("bwrite");
    800030e0:	00005517          	auipc	a0,0x5
    800030e4:	44050513          	addi	a0,a0,1088 # 80008520 <syscalls+0xe8>
    800030e8:	ffffd097          	auipc	ra,0xffffd
    800030ec:	448080e7          	jalr	1096(ra) # 80000530 <panic>

00000000800030f0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	e426                	sd	s1,8(sp)
    800030f8:	e04a                	sd	s2,0(sp)
    800030fa:	1000                	addi	s0,sp,32
    800030fc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030fe:	01050913          	addi	s2,a0,16
    80003102:	854a                	mv	a0,s2
    80003104:	00001097          	auipc	ra,0x1
    80003108:	42a080e7          	jalr	1066(ra) # 8000452e <holdingsleep>
    8000310c:	c92d                	beqz	a0,8000317e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000310e:	854a                	mv	a0,s2
    80003110:	00001097          	auipc	ra,0x1
    80003114:	3da080e7          	jalr	986(ra) # 800044ea <releasesleep>

  acquire(&bcache.lock);
    80003118:	00020517          	auipc	a0,0x20
    8000311c:	fb850513          	addi	a0,a0,-72 # 800230d0 <bcache>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	ab6080e7          	jalr	-1354(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003128:	40bc                	lw	a5,64(s1)
    8000312a:	37fd                	addiw	a5,a5,-1
    8000312c:	0007871b          	sext.w	a4,a5
    80003130:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003132:	eb05                	bnez	a4,80003162 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003134:	68bc                	ld	a5,80(s1)
    80003136:	64b8                	ld	a4,72(s1)
    80003138:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000313a:	64bc                	ld	a5,72(s1)
    8000313c:	68b8                	ld	a4,80(s1)
    8000313e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003140:	00028797          	auipc	a5,0x28
    80003144:	f9078793          	addi	a5,a5,-112 # 8002b0d0 <bcache+0x8000>
    80003148:	2b87b703          	ld	a4,696(a5)
    8000314c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000314e:	00028717          	auipc	a4,0x28
    80003152:	1ea70713          	addi	a4,a4,490 # 8002b338 <bcache+0x8268>
    80003156:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003158:	2b87b703          	ld	a4,696(a5)
    8000315c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000315e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003162:	00020517          	auipc	a0,0x20
    80003166:	f6e50513          	addi	a0,a0,-146 # 800230d0 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	b20080e7          	jalr	-1248(ra) # 80000c8a <release>
}
    80003172:	60e2                	ld	ra,24(sp)
    80003174:	6442                	ld	s0,16(sp)
    80003176:	64a2                	ld	s1,8(sp)
    80003178:	6902                	ld	s2,0(sp)
    8000317a:	6105                	addi	sp,sp,32
    8000317c:	8082                	ret
    panic("brelse");
    8000317e:	00005517          	auipc	a0,0x5
    80003182:	3aa50513          	addi	a0,a0,938 # 80008528 <syscalls+0xf0>
    80003186:	ffffd097          	auipc	ra,0xffffd
    8000318a:	3aa080e7          	jalr	938(ra) # 80000530 <panic>

000000008000318e <bpin>:

void
bpin(struct buf *b) {
    8000318e:	1101                	addi	sp,sp,-32
    80003190:	ec06                	sd	ra,24(sp)
    80003192:	e822                	sd	s0,16(sp)
    80003194:	e426                	sd	s1,8(sp)
    80003196:	1000                	addi	s0,sp,32
    80003198:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000319a:	00020517          	auipc	a0,0x20
    8000319e:	f3650513          	addi	a0,a0,-202 # 800230d0 <bcache>
    800031a2:	ffffe097          	auipc	ra,0xffffe
    800031a6:	a34080e7          	jalr	-1484(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800031aa:	40bc                	lw	a5,64(s1)
    800031ac:	2785                	addiw	a5,a5,1
    800031ae:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031b0:	00020517          	auipc	a0,0x20
    800031b4:	f2050513          	addi	a0,a0,-224 # 800230d0 <bcache>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	ad2080e7          	jalr	-1326(ra) # 80000c8a <release>
}
    800031c0:	60e2                	ld	ra,24(sp)
    800031c2:	6442                	ld	s0,16(sp)
    800031c4:	64a2                	ld	s1,8(sp)
    800031c6:	6105                	addi	sp,sp,32
    800031c8:	8082                	ret

00000000800031ca <bunpin>:

void
bunpin(struct buf *b) {
    800031ca:	1101                	addi	sp,sp,-32
    800031cc:	ec06                	sd	ra,24(sp)
    800031ce:	e822                	sd	s0,16(sp)
    800031d0:	e426                	sd	s1,8(sp)
    800031d2:	1000                	addi	s0,sp,32
    800031d4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031d6:	00020517          	auipc	a0,0x20
    800031da:	efa50513          	addi	a0,a0,-262 # 800230d0 <bcache>
    800031de:	ffffe097          	auipc	ra,0xffffe
    800031e2:	9f8080e7          	jalr	-1544(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031e6:	40bc                	lw	a5,64(s1)
    800031e8:	37fd                	addiw	a5,a5,-1
    800031ea:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ec:	00020517          	auipc	a0,0x20
    800031f0:	ee450513          	addi	a0,a0,-284 # 800230d0 <bcache>
    800031f4:	ffffe097          	auipc	ra,0xffffe
    800031f8:	a96080e7          	jalr	-1386(ra) # 80000c8a <release>
}
    800031fc:	60e2                	ld	ra,24(sp)
    800031fe:	6442                	ld	s0,16(sp)
    80003200:	64a2                	ld	s1,8(sp)
    80003202:	6105                	addi	sp,sp,32
    80003204:	8082                	ret

0000000080003206 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003206:	1101                	addi	sp,sp,-32
    80003208:	ec06                	sd	ra,24(sp)
    8000320a:	e822                	sd	s0,16(sp)
    8000320c:	e426                	sd	s1,8(sp)
    8000320e:	e04a                	sd	s2,0(sp)
    80003210:	1000                	addi	s0,sp,32
    80003212:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003214:	00d5d59b          	srliw	a1,a1,0xd
    80003218:	00028797          	auipc	a5,0x28
    8000321c:	5947a783          	lw	a5,1428(a5) # 8002b7ac <sb+0x1c>
    80003220:	9dbd                	addw	a1,a1,a5
    80003222:	00000097          	auipc	ra,0x0
    80003226:	d9e080e7          	jalr	-610(ra) # 80002fc0 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000322a:	0074f713          	andi	a4,s1,7
    8000322e:	4785                	li	a5,1
    80003230:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003234:	14ce                	slli	s1,s1,0x33
    80003236:	90d9                	srli	s1,s1,0x36
    80003238:	00950733          	add	a4,a0,s1
    8000323c:	05874703          	lbu	a4,88(a4)
    80003240:	00e7f6b3          	and	a3,a5,a4
    80003244:	c69d                	beqz	a3,80003272 <bfree+0x6c>
    80003246:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003248:	94aa                	add	s1,s1,a0
    8000324a:	fff7c793          	not	a5,a5
    8000324e:	8ff9                	and	a5,a5,a4
    80003250:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003254:	00001097          	auipc	ra,0x1
    80003258:	118080e7          	jalr	280(ra) # 8000436c <log_write>
  brelse(bp);
    8000325c:	854a                	mv	a0,s2
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	e92080e7          	jalr	-366(ra) # 800030f0 <brelse>
}
    80003266:	60e2                	ld	ra,24(sp)
    80003268:	6442                	ld	s0,16(sp)
    8000326a:	64a2                	ld	s1,8(sp)
    8000326c:	6902                	ld	s2,0(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret
    panic("freeing free block");
    80003272:	00005517          	auipc	a0,0x5
    80003276:	2be50513          	addi	a0,a0,702 # 80008530 <syscalls+0xf8>
    8000327a:	ffffd097          	auipc	ra,0xffffd
    8000327e:	2b6080e7          	jalr	694(ra) # 80000530 <panic>

0000000080003282 <balloc>:
{
    80003282:	711d                	addi	sp,sp,-96
    80003284:	ec86                	sd	ra,88(sp)
    80003286:	e8a2                	sd	s0,80(sp)
    80003288:	e4a6                	sd	s1,72(sp)
    8000328a:	e0ca                	sd	s2,64(sp)
    8000328c:	fc4e                	sd	s3,56(sp)
    8000328e:	f852                	sd	s4,48(sp)
    80003290:	f456                	sd	s5,40(sp)
    80003292:	f05a                	sd	s6,32(sp)
    80003294:	ec5e                	sd	s7,24(sp)
    80003296:	e862                	sd	s8,16(sp)
    80003298:	e466                	sd	s9,8(sp)
    8000329a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000329c:	00028797          	auipc	a5,0x28
    800032a0:	4f87a783          	lw	a5,1272(a5) # 8002b794 <sb+0x4>
    800032a4:	cbd1                	beqz	a5,80003338 <balloc+0xb6>
    800032a6:	8baa                	mv	s7,a0
    800032a8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032aa:	00028b17          	auipc	s6,0x28
    800032ae:	4e6b0b13          	addi	s6,s6,1254 # 8002b790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032b4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032b8:	6c89                	lui	s9,0x2
    800032ba:	a831                	j	800032d6 <balloc+0x54>
    brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	e32080e7          	jalr	-462(ra) # 800030f0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c6:	015c87bb          	addw	a5,s9,s5
    800032ca:	00078a9b          	sext.w	s5,a5
    800032ce:	004b2703          	lw	a4,4(s6)
    800032d2:	06eaf363          	bgeu	s5,a4,80003338 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032d6:	41fad79b          	sraiw	a5,s5,0x1f
    800032da:	0137d79b          	srliw	a5,a5,0x13
    800032de:	015787bb          	addw	a5,a5,s5
    800032e2:	40d7d79b          	sraiw	a5,a5,0xd
    800032e6:	01cb2583          	lw	a1,28(s6)
    800032ea:	9dbd                	addw	a1,a1,a5
    800032ec:	855e                	mv	a0,s7
    800032ee:	00000097          	auipc	ra,0x0
    800032f2:	cd2080e7          	jalr	-814(ra) # 80002fc0 <bread>
    800032f6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f8:	004b2503          	lw	a0,4(s6)
    800032fc:	000a849b          	sext.w	s1,s5
    80003300:	8662                	mv	a2,s8
    80003302:	faa4fde3          	bgeu	s1,a0,800032bc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003306:	41f6579b          	sraiw	a5,a2,0x1f
    8000330a:	01d7d69b          	srliw	a3,a5,0x1d
    8000330e:	00c6873b          	addw	a4,a3,a2
    80003312:	00777793          	andi	a5,a4,7
    80003316:	9f95                	subw	a5,a5,a3
    80003318:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000331c:	4037571b          	sraiw	a4,a4,0x3
    80003320:	00e906b3          	add	a3,s2,a4
    80003324:	0586c683          	lbu	a3,88(a3)
    80003328:	00d7f5b3          	and	a1,a5,a3
    8000332c:	cd91                	beqz	a1,80003348 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332e:	2605                	addiw	a2,a2,1
    80003330:	2485                	addiw	s1,s1,1
    80003332:	fd4618e3          	bne	a2,s4,80003302 <balloc+0x80>
    80003336:	b759                	j	800032bc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003338:	00005517          	auipc	a0,0x5
    8000333c:	21050513          	addi	a0,a0,528 # 80008548 <syscalls+0x110>
    80003340:	ffffd097          	auipc	ra,0xffffd
    80003344:	1f0080e7          	jalr	496(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003348:	974a                	add	a4,a4,s2
    8000334a:	8fd5                	or	a5,a5,a3
    8000334c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003350:	854a                	mv	a0,s2
    80003352:	00001097          	auipc	ra,0x1
    80003356:	01a080e7          	jalr	26(ra) # 8000436c <log_write>
        brelse(bp);
    8000335a:	854a                	mv	a0,s2
    8000335c:	00000097          	auipc	ra,0x0
    80003360:	d94080e7          	jalr	-620(ra) # 800030f0 <brelse>
  bp = bread(dev, bno);
    80003364:	85a6                	mv	a1,s1
    80003366:	855e                	mv	a0,s7
    80003368:	00000097          	auipc	ra,0x0
    8000336c:	c58080e7          	jalr	-936(ra) # 80002fc0 <bread>
    80003370:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003372:	40000613          	li	a2,1024
    80003376:	4581                	li	a1,0
    80003378:	05850513          	addi	a0,a0,88
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	956080e7          	jalr	-1706(ra) # 80000cd2 <memset>
  log_write(bp);
    80003384:	854a                	mv	a0,s2
    80003386:	00001097          	auipc	ra,0x1
    8000338a:	fe6080e7          	jalr	-26(ra) # 8000436c <log_write>
  brelse(bp);
    8000338e:	854a                	mv	a0,s2
    80003390:	00000097          	auipc	ra,0x0
    80003394:	d60080e7          	jalr	-672(ra) # 800030f0 <brelse>
}
    80003398:	8526                	mv	a0,s1
    8000339a:	60e6                	ld	ra,88(sp)
    8000339c:	6446                	ld	s0,80(sp)
    8000339e:	64a6                	ld	s1,72(sp)
    800033a0:	6906                	ld	s2,64(sp)
    800033a2:	79e2                	ld	s3,56(sp)
    800033a4:	7a42                	ld	s4,48(sp)
    800033a6:	7aa2                	ld	s5,40(sp)
    800033a8:	7b02                	ld	s6,32(sp)
    800033aa:	6be2                	ld	s7,24(sp)
    800033ac:	6c42                	ld	s8,16(sp)
    800033ae:	6ca2                	ld	s9,8(sp)
    800033b0:	6125                	addi	sp,sp,96
    800033b2:	8082                	ret

00000000800033b4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033b4:	7179                	addi	sp,sp,-48
    800033b6:	f406                	sd	ra,40(sp)
    800033b8:	f022                	sd	s0,32(sp)
    800033ba:	ec26                	sd	s1,24(sp)
    800033bc:	e84a                	sd	s2,16(sp)
    800033be:	e44e                	sd	s3,8(sp)
    800033c0:	e052                	sd	s4,0(sp)
    800033c2:	1800                	addi	s0,sp,48
    800033c4:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c6:	47ad                	li	a5,11
    800033c8:	04b7fe63          	bgeu	a5,a1,80003424 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033cc:	ff45849b          	addiw	s1,a1,-12
    800033d0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d4:	0ff00793          	li	a5,255
    800033d8:	0ae7e363          	bltu	a5,a4,8000347e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033dc:	08052583          	lw	a1,128(a0)
    800033e0:	c5ad                	beqz	a1,8000344a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033e2:	00092503          	lw	a0,0(s2)
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	bda080e7          	jalr	-1062(ra) # 80002fc0 <bread>
    800033ee:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033f0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033f4:	02049593          	slli	a1,s1,0x20
    800033f8:	9181                	srli	a1,a1,0x20
    800033fa:	058a                	slli	a1,a1,0x2
    800033fc:	00b784b3          	add	s1,a5,a1
    80003400:	0004a983          	lw	s3,0(s1)
    80003404:	04098d63          	beqz	s3,8000345e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003408:	8552                	mv	a0,s4
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	ce6080e7          	jalr	-794(ra) # 800030f0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003412:	854e                	mv	a0,s3
    80003414:	70a2                	ld	ra,40(sp)
    80003416:	7402                	ld	s0,32(sp)
    80003418:	64e2                	ld	s1,24(sp)
    8000341a:	6942                	ld	s2,16(sp)
    8000341c:	69a2                	ld	s3,8(sp)
    8000341e:	6a02                	ld	s4,0(sp)
    80003420:	6145                	addi	sp,sp,48
    80003422:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003424:	02059493          	slli	s1,a1,0x20
    80003428:	9081                	srli	s1,s1,0x20
    8000342a:	048a                	slli	s1,s1,0x2
    8000342c:	94aa                	add	s1,s1,a0
    8000342e:	0504a983          	lw	s3,80(s1)
    80003432:	fe0990e3          	bnez	s3,80003412 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003436:	4108                	lw	a0,0(a0)
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	e4a080e7          	jalr	-438(ra) # 80003282 <balloc>
    80003440:	0005099b          	sext.w	s3,a0
    80003444:	0534a823          	sw	s3,80(s1)
    80003448:	b7e9                	j	80003412 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000344a:	4108                	lw	a0,0(a0)
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e36080e7          	jalr	-458(ra) # 80003282 <balloc>
    80003454:	0005059b          	sext.w	a1,a0
    80003458:	08b92023          	sw	a1,128(s2)
    8000345c:	b759                	j	800033e2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000345e:	00092503          	lw	a0,0(s2)
    80003462:	00000097          	auipc	ra,0x0
    80003466:	e20080e7          	jalr	-480(ra) # 80003282 <balloc>
    8000346a:	0005099b          	sext.w	s3,a0
    8000346e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003472:	8552                	mv	a0,s4
    80003474:	00001097          	auipc	ra,0x1
    80003478:	ef8080e7          	jalr	-264(ra) # 8000436c <log_write>
    8000347c:	b771                	j	80003408 <bmap+0x54>
  panic("bmap: out of range");
    8000347e:	00005517          	auipc	a0,0x5
    80003482:	0e250513          	addi	a0,a0,226 # 80008560 <syscalls+0x128>
    80003486:	ffffd097          	auipc	ra,0xffffd
    8000348a:	0aa080e7          	jalr	170(ra) # 80000530 <panic>

000000008000348e <iget>:
{
    8000348e:	7179                	addi	sp,sp,-48
    80003490:	f406                	sd	ra,40(sp)
    80003492:	f022                	sd	s0,32(sp)
    80003494:	ec26                	sd	s1,24(sp)
    80003496:	e84a                	sd	s2,16(sp)
    80003498:	e44e                	sd	s3,8(sp)
    8000349a:	e052                	sd	s4,0(sp)
    8000349c:	1800                	addi	s0,sp,48
    8000349e:	89aa                	mv	s3,a0
    800034a0:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800034a2:	00028517          	auipc	a0,0x28
    800034a6:	30e50513          	addi	a0,a0,782 # 8002b7b0 <icache>
    800034aa:	ffffd097          	auipc	ra,0xffffd
    800034ae:	72c080e7          	jalr	1836(ra) # 80000bd6 <acquire>
  empty = 0;
    800034b2:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034b4:	00028497          	auipc	s1,0x28
    800034b8:	31448493          	addi	s1,s1,788 # 8002b7c8 <icache+0x18>
    800034bc:	0002a697          	auipc	a3,0x2a
    800034c0:	d9c68693          	addi	a3,a3,-612 # 8002d258 <log>
    800034c4:	a039                	j	800034d2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c6:	02090b63          	beqz	s2,800034fc <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034ca:	08848493          	addi	s1,s1,136
    800034ce:	02d48a63          	beq	s1,a3,80003502 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034d2:	449c                	lw	a5,8(s1)
    800034d4:	fef059e3          	blez	a5,800034c6 <iget+0x38>
    800034d8:	4098                	lw	a4,0(s1)
    800034da:	ff3716e3          	bne	a4,s3,800034c6 <iget+0x38>
    800034de:	40d8                	lw	a4,4(s1)
    800034e0:	ff4713e3          	bne	a4,s4,800034c6 <iget+0x38>
      ip->ref++;
    800034e4:	2785                	addiw	a5,a5,1
    800034e6:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034e8:	00028517          	auipc	a0,0x28
    800034ec:	2c850513          	addi	a0,a0,712 # 8002b7b0 <icache>
    800034f0:	ffffd097          	auipc	ra,0xffffd
    800034f4:	79a080e7          	jalr	1946(ra) # 80000c8a <release>
      return ip;
    800034f8:	8926                	mv	s2,s1
    800034fa:	a03d                	j	80003528 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034fc:	f7f9                	bnez	a5,800034ca <iget+0x3c>
    800034fe:	8926                	mv	s2,s1
    80003500:	b7e9                	j	800034ca <iget+0x3c>
  if(empty == 0)
    80003502:	02090c63          	beqz	s2,8000353a <iget+0xac>
  ip->dev = dev;
    80003506:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000350a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000350e:	4785                	li	a5,1
    80003510:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003514:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003518:	00028517          	auipc	a0,0x28
    8000351c:	29850513          	addi	a0,a0,664 # 8002b7b0 <icache>
    80003520:	ffffd097          	auipc	ra,0xffffd
    80003524:	76a080e7          	jalr	1898(ra) # 80000c8a <release>
}
    80003528:	854a                	mv	a0,s2
    8000352a:	70a2                	ld	ra,40(sp)
    8000352c:	7402                	ld	s0,32(sp)
    8000352e:	64e2                	ld	s1,24(sp)
    80003530:	6942                	ld	s2,16(sp)
    80003532:	69a2                	ld	s3,8(sp)
    80003534:	6a02                	ld	s4,0(sp)
    80003536:	6145                	addi	sp,sp,48
    80003538:	8082                	ret
    panic("iget: no inodes");
    8000353a:	00005517          	auipc	a0,0x5
    8000353e:	03e50513          	addi	a0,a0,62 # 80008578 <syscalls+0x140>
    80003542:	ffffd097          	auipc	ra,0xffffd
    80003546:	fee080e7          	jalr	-18(ra) # 80000530 <panic>

000000008000354a <fsinit>:
fsinit(int dev) {
    8000354a:	7179                	addi	sp,sp,-48
    8000354c:	f406                	sd	ra,40(sp)
    8000354e:	f022                	sd	s0,32(sp)
    80003550:	ec26                	sd	s1,24(sp)
    80003552:	e84a                	sd	s2,16(sp)
    80003554:	e44e                	sd	s3,8(sp)
    80003556:	1800                	addi	s0,sp,48
    80003558:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000355a:	4585                	li	a1,1
    8000355c:	00000097          	auipc	ra,0x0
    80003560:	a64080e7          	jalr	-1436(ra) # 80002fc0 <bread>
    80003564:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003566:	00028997          	auipc	s3,0x28
    8000356a:	22a98993          	addi	s3,s3,554 # 8002b790 <sb>
    8000356e:	02000613          	li	a2,32
    80003572:	05850593          	addi	a1,a0,88
    80003576:	854e                	mv	a0,s3
    80003578:	ffffd097          	auipc	ra,0xffffd
    8000357c:	7ba080e7          	jalr	1978(ra) # 80000d32 <memmove>
  brelse(bp);
    80003580:	8526                	mv	a0,s1
    80003582:	00000097          	auipc	ra,0x0
    80003586:	b6e080e7          	jalr	-1170(ra) # 800030f0 <brelse>
  if(sb.magic != FSMAGIC)
    8000358a:	0009a703          	lw	a4,0(s3)
    8000358e:	102037b7          	lui	a5,0x10203
    80003592:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003596:	02f71263          	bne	a4,a5,800035ba <fsinit+0x70>
  initlog(dev, &sb);
    8000359a:	00028597          	auipc	a1,0x28
    8000359e:	1f658593          	addi	a1,a1,502 # 8002b790 <sb>
    800035a2:	854a                	mv	a0,s2
    800035a4:	00001097          	auipc	ra,0x1
    800035a8:	b4c080e7          	jalr	-1204(ra) # 800040f0 <initlog>
}
    800035ac:	70a2                	ld	ra,40(sp)
    800035ae:	7402                	ld	s0,32(sp)
    800035b0:	64e2                	ld	s1,24(sp)
    800035b2:	6942                	ld	s2,16(sp)
    800035b4:	69a2                	ld	s3,8(sp)
    800035b6:	6145                	addi	sp,sp,48
    800035b8:	8082                	ret
    panic("invalid file system");
    800035ba:	00005517          	auipc	a0,0x5
    800035be:	fce50513          	addi	a0,a0,-50 # 80008588 <syscalls+0x150>
    800035c2:	ffffd097          	auipc	ra,0xffffd
    800035c6:	f6e080e7          	jalr	-146(ra) # 80000530 <panic>

00000000800035ca <iinit>:
{
    800035ca:	7179                	addi	sp,sp,-48
    800035cc:	f406                	sd	ra,40(sp)
    800035ce:	f022                	sd	s0,32(sp)
    800035d0:	ec26                	sd	s1,24(sp)
    800035d2:	e84a                	sd	s2,16(sp)
    800035d4:	e44e                	sd	s3,8(sp)
    800035d6:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035d8:	00005597          	auipc	a1,0x5
    800035dc:	fc858593          	addi	a1,a1,-56 # 800085a0 <syscalls+0x168>
    800035e0:	00028517          	auipc	a0,0x28
    800035e4:	1d050513          	addi	a0,a0,464 # 8002b7b0 <icache>
    800035e8:	ffffd097          	auipc	ra,0xffffd
    800035ec:	55e080e7          	jalr	1374(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035f0:	00028497          	auipc	s1,0x28
    800035f4:	1e848493          	addi	s1,s1,488 # 8002b7d8 <icache+0x28>
    800035f8:	0002a997          	auipc	s3,0x2a
    800035fc:	c7098993          	addi	s3,s3,-912 # 8002d268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003600:	00005917          	auipc	s2,0x5
    80003604:	fa890913          	addi	s2,s2,-88 # 800085a8 <syscalls+0x170>
    80003608:	85ca                	mv	a1,s2
    8000360a:	8526                	mv	a0,s1
    8000360c:	00001097          	auipc	ra,0x1
    80003610:	e4e080e7          	jalr	-434(ra) # 8000445a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003614:	08848493          	addi	s1,s1,136
    80003618:	ff3498e3          	bne	s1,s3,80003608 <iinit+0x3e>
}
    8000361c:	70a2                	ld	ra,40(sp)
    8000361e:	7402                	ld	s0,32(sp)
    80003620:	64e2                	ld	s1,24(sp)
    80003622:	6942                	ld	s2,16(sp)
    80003624:	69a2                	ld	s3,8(sp)
    80003626:	6145                	addi	sp,sp,48
    80003628:	8082                	ret

000000008000362a <ialloc>:
{
    8000362a:	715d                	addi	sp,sp,-80
    8000362c:	e486                	sd	ra,72(sp)
    8000362e:	e0a2                	sd	s0,64(sp)
    80003630:	fc26                	sd	s1,56(sp)
    80003632:	f84a                	sd	s2,48(sp)
    80003634:	f44e                	sd	s3,40(sp)
    80003636:	f052                	sd	s4,32(sp)
    80003638:	ec56                	sd	s5,24(sp)
    8000363a:	e85a                	sd	s6,16(sp)
    8000363c:	e45e                	sd	s7,8(sp)
    8000363e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003640:	00028717          	auipc	a4,0x28
    80003644:	15c72703          	lw	a4,348(a4) # 8002b79c <sb+0xc>
    80003648:	4785                	li	a5,1
    8000364a:	04e7fa63          	bgeu	a5,a4,8000369e <ialloc+0x74>
    8000364e:	8aaa                	mv	s5,a0
    80003650:	8bae                	mv	s7,a1
    80003652:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003654:	00028a17          	auipc	s4,0x28
    80003658:	13ca0a13          	addi	s4,s4,316 # 8002b790 <sb>
    8000365c:	00048b1b          	sext.w	s6,s1
    80003660:	0044d593          	srli	a1,s1,0x4
    80003664:	018a2783          	lw	a5,24(s4)
    80003668:	9dbd                	addw	a1,a1,a5
    8000366a:	8556                	mv	a0,s5
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	954080e7          	jalr	-1708(ra) # 80002fc0 <bread>
    80003674:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003676:	05850993          	addi	s3,a0,88
    8000367a:	00f4f793          	andi	a5,s1,15
    8000367e:	079a                	slli	a5,a5,0x6
    80003680:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003682:	00099783          	lh	a5,0(s3)
    80003686:	c785                	beqz	a5,800036ae <ialloc+0x84>
    brelse(bp);
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	a68080e7          	jalr	-1432(ra) # 800030f0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003690:	0485                	addi	s1,s1,1
    80003692:	00ca2703          	lw	a4,12(s4)
    80003696:	0004879b          	sext.w	a5,s1
    8000369a:	fce7e1e3          	bltu	a5,a4,8000365c <ialloc+0x32>
  panic("ialloc: no inodes");
    8000369e:	00005517          	auipc	a0,0x5
    800036a2:	f1250513          	addi	a0,a0,-238 # 800085b0 <syscalls+0x178>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	e8a080e7          	jalr	-374(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    800036ae:	04000613          	li	a2,64
    800036b2:	4581                	li	a1,0
    800036b4:	854e                	mv	a0,s3
    800036b6:	ffffd097          	auipc	ra,0xffffd
    800036ba:	61c080e7          	jalr	1564(ra) # 80000cd2 <memset>
      dip->type = type;
    800036be:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036c2:	854a                	mv	a0,s2
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	ca8080e7          	jalr	-856(ra) # 8000436c <log_write>
      brelse(bp);
    800036cc:	854a                	mv	a0,s2
    800036ce:	00000097          	auipc	ra,0x0
    800036d2:	a22080e7          	jalr	-1502(ra) # 800030f0 <brelse>
      return iget(dev, inum);
    800036d6:	85da                	mv	a1,s6
    800036d8:	8556                	mv	a0,s5
    800036da:	00000097          	auipc	ra,0x0
    800036de:	db4080e7          	jalr	-588(ra) # 8000348e <iget>
}
    800036e2:	60a6                	ld	ra,72(sp)
    800036e4:	6406                	ld	s0,64(sp)
    800036e6:	74e2                	ld	s1,56(sp)
    800036e8:	7942                	ld	s2,48(sp)
    800036ea:	79a2                	ld	s3,40(sp)
    800036ec:	7a02                	ld	s4,32(sp)
    800036ee:	6ae2                	ld	s5,24(sp)
    800036f0:	6b42                	ld	s6,16(sp)
    800036f2:	6ba2                	ld	s7,8(sp)
    800036f4:	6161                	addi	sp,sp,80
    800036f6:	8082                	ret

00000000800036f8 <iupdate>:
{
    800036f8:	1101                	addi	sp,sp,-32
    800036fa:	ec06                	sd	ra,24(sp)
    800036fc:	e822                	sd	s0,16(sp)
    800036fe:	e426                	sd	s1,8(sp)
    80003700:	e04a                	sd	s2,0(sp)
    80003702:	1000                	addi	s0,sp,32
    80003704:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003706:	415c                	lw	a5,4(a0)
    80003708:	0047d79b          	srliw	a5,a5,0x4
    8000370c:	00028597          	auipc	a1,0x28
    80003710:	09c5a583          	lw	a1,156(a1) # 8002b7a8 <sb+0x18>
    80003714:	9dbd                	addw	a1,a1,a5
    80003716:	4108                	lw	a0,0(a0)
    80003718:	00000097          	auipc	ra,0x0
    8000371c:	8a8080e7          	jalr	-1880(ra) # 80002fc0 <bread>
    80003720:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003722:	05850793          	addi	a5,a0,88
    80003726:	40c8                	lw	a0,4(s1)
    80003728:	893d                	andi	a0,a0,15
    8000372a:	051a                	slli	a0,a0,0x6
    8000372c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000372e:	04449703          	lh	a4,68(s1)
    80003732:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003736:	04649703          	lh	a4,70(s1)
    8000373a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000373e:	04849703          	lh	a4,72(s1)
    80003742:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003746:	04a49703          	lh	a4,74(s1)
    8000374a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000374e:	44f8                	lw	a4,76(s1)
    80003750:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003752:	03400613          	li	a2,52
    80003756:	05048593          	addi	a1,s1,80
    8000375a:	0531                	addi	a0,a0,12
    8000375c:	ffffd097          	auipc	ra,0xffffd
    80003760:	5d6080e7          	jalr	1494(ra) # 80000d32 <memmove>
  log_write(bp);
    80003764:	854a                	mv	a0,s2
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	c06080e7          	jalr	-1018(ra) # 8000436c <log_write>
  brelse(bp);
    8000376e:	854a                	mv	a0,s2
    80003770:	00000097          	auipc	ra,0x0
    80003774:	980080e7          	jalr	-1664(ra) # 800030f0 <brelse>
}
    80003778:	60e2                	ld	ra,24(sp)
    8000377a:	6442                	ld	s0,16(sp)
    8000377c:	64a2                	ld	s1,8(sp)
    8000377e:	6902                	ld	s2,0(sp)
    80003780:	6105                	addi	sp,sp,32
    80003782:	8082                	ret

0000000080003784 <idup>:
{
    80003784:	1101                	addi	sp,sp,-32
    80003786:	ec06                	sd	ra,24(sp)
    80003788:	e822                	sd	s0,16(sp)
    8000378a:	e426                	sd	s1,8(sp)
    8000378c:	1000                	addi	s0,sp,32
    8000378e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003790:	00028517          	auipc	a0,0x28
    80003794:	02050513          	addi	a0,a0,32 # 8002b7b0 <icache>
    80003798:	ffffd097          	auipc	ra,0xffffd
    8000379c:	43e080e7          	jalr	1086(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037a0:	449c                	lw	a5,8(s1)
    800037a2:	2785                	addiw	a5,a5,1
    800037a4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037a6:	00028517          	auipc	a0,0x28
    800037aa:	00a50513          	addi	a0,a0,10 # 8002b7b0 <icache>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	4dc080e7          	jalr	1244(ra) # 80000c8a <release>
}
    800037b6:	8526                	mv	a0,s1
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6105                	addi	sp,sp,32
    800037c0:	8082                	ret

00000000800037c2 <ilock>:
{
    800037c2:	1101                	addi	sp,sp,-32
    800037c4:	ec06                	sd	ra,24(sp)
    800037c6:	e822                	sd	s0,16(sp)
    800037c8:	e426                	sd	s1,8(sp)
    800037ca:	e04a                	sd	s2,0(sp)
    800037cc:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ce:	c115                	beqz	a0,800037f2 <ilock+0x30>
    800037d0:	84aa                	mv	s1,a0
    800037d2:	451c                	lw	a5,8(a0)
    800037d4:	00f05f63          	blez	a5,800037f2 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037d8:	0541                	addi	a0,a0,16
    800037da:	00001097          	auipc	ra,0x1
    800037de:	cba080e7          	jalr	-838(ra) # 80004494 <acquiresleep>
  if(ip->valid == 0){
    800037e2:	40bc                	lw	a5,64(s1)
    800037e4:	cf99                	beqz	a5,80003802 <ilock+0x40>
}
    800037e6:	60e2                	ld	ra,24(sp)
    800037e8:	6442                	ld	s0,16(sp)
    800037ea:	64a2                	ld	s1,8(sp)
    800037ec:	6902                	ld	s2,0(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret
    panic("ilock");
    800037f2:	00005517          	auipc	a0,0x5
    800037f6:	dd650513          	addi	a0,a0,-554 # 800085c8 <syscalls+0x190>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d36080e7          	jalr	-714(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003802:	40dc                	lw	a5,4(s1)
    80003804:	0047d79b          	srliw	a5,a5,0x4
    80003808:	00028597          	auipc	a1,0x28
    8000380c:	fa05a583          	lw	a1,-96(a1) # 8002b7a8 <sb+0x18>
    80003810:	9dbd                	addw	a1,a1,a5
    80003812:	4088                	lw	a0,0(s1)
    80003814:	fffff097          	auipc	ra,0xfffff
    80003818:	7ac080e7          	jalr	1964(ra) # 80002fc0 <bread>
    8000381c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000381e:	05850593          	addi	a1,a0,88
    80003822:	40dc                	lw	a5,4(s1)
    80003824:	8bbd                	andi	a5,a5,15
    80003826:	079a                	slli	a5,a5,0x6
    80003828:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000382a:	00059783          	lh	a5,0(a1)
    8000382e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003832:	00259783          	lh	a5,2(a1)
    80003836:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000383a:	00459783          	lh	a5,4(a1)
    8000383e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003842:	00659783          	lh	a5,6(a1)
    80003846:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000384a:	459c                	lw	a5,8(a1)
    8000384c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000384e:	03400613          	li	a2,52
    80003852:	05b1                	addi	a1,a1,12
    80003854:	05048513          	addi	a0,s1,80
    80003858:	ffffd097          	auipc	ra,0xffffd
    8000385c:	4da080e7          	jalr	1242(ra) # 80000d32 <memmove>
    brelse(bp);
    80003860:	854a                	mv	a0,s2
    80003862:	00000097          	auipc	ra,0x0
    80003866:	88e080e7          	jalr	-1906(ra) # 800030f0 <brelse>
    ip->valid = 1;
    8000386a:	4785                	li	a5,1
    8000386c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000386e:	04449783          	lh	a5,68(s1)
    80003872:	fbb5                	bnez	a5,800037e6 <ilock+0x24>
      panic("ilock: no type");
    80003874:	00005517          	auipc	a0,0x5
    80003878:	d5c50513          	addi	a0,a0,-676 # 800085d0 <syscalls+0x198>
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	cb4080e7          	jalr	-844(ra) # 80000530 <panic>

0000000080003884 <iunlock>:
{
    80003884:	1101                	addi	sp,sp,-32
    80003886:	ec06                	sd	ra,24(sp)
    80003888:	e822                	sd	s0,16(sp)
    8000388a:	e426                	sd	s1,8(sp)
    8000388c:	e04a                	sd	s2,0(sp)
    8000388e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003890:	c905                	beqz	a0,800038c0 <iunlock+0x3c>
    80003892:	84aa                	mv	s1,a0
    80003894:	01050913          	addi	s2,a0,16
    80003898:	854a                	mv	a0,s2
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	c94080e7          	jalr	-876(ra) # 8000452e <holdingsleep>
    800038a2:	cd19                	beqz	a0,800038c0 <iunlock+0x3c>
    800038a4:	449c                	lw	a5,8(s1)
    800038a6:	00f05d63          	blez	a5,800038c0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00001097          	auipc	ra,0x1
    800038b0:	c3e080e7          	jalr	-962(ra) # 800044ea <releasesleep>
}
    800038b4:	60e2                	ld	ra,24(sp)
    800038b6:	6442                	ld	s0,16(sp)
    800038b8:	64a2                	ld	s1,8(sp)
    800038ba:	6902                	ld	s2,0(sp)
    800038bc:	6105                	addi	sp,sp,32
    800038be:	8082                	ret
    panic("iunlock");
    800038c0:	00005517          	auipc	a0,0x5
    800038c4:	d2050513          	addi	a0,a0,-736 # 800085e0 <syscalls+0x1a8>
    800038c8:	ffffd097          	auipc	ra,0xffffd
    800038cc:	c68080e7          	jalr	-920(ra) # 80000530 <panic>

00000000800038d0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038d0:	7179                	addi	sp,sp,-48
    800038d2:	f406                	sd	ra,40(sp)
    800038d4:	f022                	sd	s0,32(sp)
    800038d6:	ec26                	sd	s1,24(sp)
    800038d8:	e84a                	sd	s2,16(sp)
    800038da:	e44e                	sd	s3,8(sp)
    800038dc:	e052                	sd	s4,0(sp)
    800038de:	1800                	addi	s0,sp,48
    800038e0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038e2:	05050493          	addi	s1,a0,80
    800038e6:	08050913          	addi	s2,a0,128
    800038ea:	a021                	j	800038f2 <itrunc+0x22>
    800038ec:	0491                	addi	s1,s1,4
    800038ee:	01248d63          	beq	s1,s2,80003908 <itrunc+0x38>
    if(ip->addrs[i]){
    800038f2:	408c                	lw	a1,0(s1)
    800038f4:	dde5                	beqz	a1,800038ec <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038f6:	0009a503          	lw	a0,0(s3)
    800038fa:	00000097          	auipc	ra,0x0
    800038fe:	90c080e7          	jalr	-1780(ra) # 80003206 <bfree>
      ip->addrs[i] = 0;
    80003902:	0004a023          	sw	zero,0(s1)
    80003906:	b7dd                	j	800038ec <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003908:	0809a583          	lw	a1,128(s3)
    8000390c:	e185                	bnez	a1,8000392c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000390e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003912:	854e                	mv	a0,s3
    80003914:	00000097          	auipc	ra,0x0
    80003918:	de4080e7          	jalr	-540(ra) # 800036f8 <iupdate>
}
    8000391c:	70a2                	ld	ra,40(sp)
    8000391e:	7402                	ld	s0,32(sp)
    80003920:	64e2                	ld	s1,24(sp)
    80003922:	6942                	ld	s2,16(sp)
    80003924:	69a2                	ld	s3,8(sp)
    80003926:	6a02                	ld	s4,0(sp)
    80003928:	6145                	addi	sp,sp,48
    8000392a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000392c:	0009a503          	lw	a0,0(s3)
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	690080e7          	jalr	1680(ra) # 80002fc0 <bread>
    80003938:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000393a:	05850493          	addi	s1,a0,88
    8000393e:	45850913          	addi	s2,a0,1112
    80003942:	a811                	j	80003956 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003944:	0009a503          	lw	a0,0(s3)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	8be080e7          	jalr	-1858(ra) # 80003206 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003950:	0491                	addi	s1,s1,4
    80003952:	01248563          	beq	s1,s2,8000395c <itrunc+0x8c>
      if(a[j])
    80003956:	408c                	lw	a1,0(s1)
    80003958:	dde5                	beqz	a1,80003950 <itrunc+0x80>
    8000395a:	b7ed                	j	80003944 <itrunc+0x74>
    brelse(bp);
    8000395c:	8552                	mv	a0,s4
    8000395e:	fffff097          	auipc	ra,0xfffff
    80003962:	792080e7          	jalr	1938(ra) # 800030f0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003966:	0809a583          	lw	a1,128(s3)
    8000396a:	0009a503          	lw	a0,0(s3)
    8000396e:	00000097          	auipc	ra,0x0
    80003972:	898080e7          	jalr	-1896(ra) # 80003206 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003976:	0809a023          	sw	zero,128(s3)
    8000397a:	bf51                	j	8000390e <itrunc+0x3e>

000000008000397c <iput>:
{
    8000397c:	1101                	addi	sp,sp,-32
    8000397e:	ec06                	sd	ra,24(sp)
    80003980:	e822                	sd	s0,16(sp)
    80003982:	e426                	sd	s1,8(sp)
    80003984:	e04a                	sd	s2,0(sp)
    80003986:	1000                	addi	s0,sp,32
    80003988:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000398a:	00028517          	auipc	a0,0x28
    8000398e:	e2650513          	addi	a0,a0,-474 # 8002b7b0 <icache>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	244080e7          	jalr	580(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399a:	4498                	lw	a4,8(s1)
    8000399c:	4785                	li	a5,1
    8000399e:	02f70363          	beq	a4,a5,800039c4 <iput+0x48>
  ip->ref--;
    800039a2:	449c                	lw	a5,8(s1)
    800039a4:	37fd                	addiw	a5,a5,-1
    800039a6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039a8:	00028517          	auipc	a0,0x28
    800039ac:	e0850513          	addi	a0,a0,-504 # 8002b7b0 <icache>
    800039b0:	ffffd097          	auipc	ra,0xffffd
    800039b4:	2da080e7          	jalr	730(ra) # 80000c8a <release>
}
    800039b8:	60e2                	ld	ra,24(sp)
    800039ba:	6442                	ld	s0,16(sp)
    800039bc:	64a2                	ld	s1,8(sp)
    800039be:	6902                	ld	s2,0(sp)
    800039c0:	6105                	addi	sp,sp,32
    800039c2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c4:	40bc                	lw	a5,64(s1)
    800039c6:	dff1                	beqz	a5,800039a2 <iput+0x26>
    800039c8:	04a49783          	lh	a5,74(s1)
    800039cc:	fbf9                	bnez	a5,800039a2 <iput+0x26>
    acquiresleep(&ip->lock);
    800039ce:	01048913          	addi	s2,s1,16
    800039d2:	854a                	mv	a0,s2
    800039d4:	00001097          	auipc	ra,0x1
    800039d8:	ac0080e7          	jalr	-1344(ra) # 80004494 <acquiresleep>
    release(&icache.lock);
    800039dc:	00028517          	auipc	a0,0x28
    800039e0:	dd450513          	addi	a0,a0,-556 # 8002b7b0 <icache>
    800039e4:	ffffd097          	auipc	ra,0xffffd
    800039e8:	2a6080e7          	jalr	678(ra) # 80000c8a <release>
    itrunc(ip);
    800039ec:	8526                	mv	a0,s1
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	ee2080e7          	jalr	-286(ra) # 800038d0 <itrunc>
    ip->type = 0;
    800039f6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039fa:	8526                	mv	a0,s1
    800039fc:	00000097          	auipc	ra,0x0
    80003a00:	cfc080e7          	jalr	-772(ra) # 800036f8 <iupdate>
    ip->valid = 0;
    80003a04:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a08:	854a                	mv	a0,s2
    80003a0a:	00001097          	auipc	ra,0x1
    80003a0e:	ae0080e7          	jalr	-1312(ra) # 800044ea <releasesleep>
    acquire(&icache.lock);
    80003a12:	00028517          	auipc	a0,0x28
    80003a16:	d9e50513          	addi	a0,a0,-610 # 8002b7b0 <icache>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	1bc080e7          	jalr	444(ra) # 80000bd6 <acquire>
    80003a22:	b741                	j	800039a2 <iput+0x26>

0000000080003a24 <iunlockput>:
{
    80003a24:	1101                	addi	sp,sp,-32
    80003a26:	ec06                	sd	ra,24(sp)
    80003a28:	e822                	sd	s0,16(sp)
    80003a2a:	e426                	sd	s1,8(sp)
    80003a2c:	1000                	addi	s0,sp,32
    80003a2e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	e54080e7          	jalr	-428(ra) # 80003884 <iunlock>
  iput(ip);
    80003a38:	8526                	mv	a0,s1
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	f42080e7          	jalr	-190(ra) # 8000397c <iput>
}
    80003a42:	60e2                	ld	ra,24(sp)
    80003a44:	6442                	ld	s0,16(sp)
    80003a46:	64a2                	ld	s1,8(sp)
    80003a48:	6105                	addi	sp,sp,32
    80003a4a:	8082                	ret

0000000080003a4c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a4c:	1141                	addi	sp,sp,-16
    80003a4e:	e422                	sd	s0,8(sp)
    80003a50:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a52:	411c                	lw	a5,0(a0)
    80003a54:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a56:	415c                	lw	a5,4(a0)
    80003a58:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a5a:	04451783          	lh	a5,68(a0)
    80003a5e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a62:	04a51783          	lh	a5,74(a0)
    80003a66:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a6a:	04c56783          	lwu	a5,76(a0)
    80003a6e:	e99c                	sd	a5,16(a1)
}
    80003a70:	6422                	ld	s0,8(sp)
    80003a72:	0141                	addi	sp,sp,16
    80003a74:	8082                	ret

0000000080003a76 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a76:	457c                	lw	a5,76(a0)
    80003a78:	0ed7e963          	bltu	a5,a3,80003b6a <readi+0xf4>
{
    80003a7c:	7159                	addi	sp,sp,-112
    80003a7e:	f486                	sd	ra,104(sp)
    80003a80:	f0a2                	sd	s0,96(sp)
    80003a82:	eca6                	sd	s1,88(sp)
    80003a84:	e8ca                	sd	s2,80(sp)
    80003a86:	e4ce                	sd	s3,72(sp)
    80003a88:	e0d2                	sd	s4,64(sp)
    80003a8a:	fc56                	sd	s5,56(sp)
    80003a8c:	f85a                	sd	s6,48(sp)
    80003a8e:	f45e                	sd	s7,40(sp)
    80003a90:	f062                	sd	s8,32(sp)
    80003a92:	ec66                	sd	s9,24(sp)
    80003a94:	e86a                	sd	s10,16(sp)
    80003a96:	e46e                	sd	s11,8(sp)
    80003a98:	1880                	addi	s0,sp,112
    80003a9a:	8baa                	mv	s7,a0
    80003a9c:	8c2e                	mv	s8,a1
    80003a9e:	8ab2                	mv	s5,a2
    80003aa0:	84b6                	mv	s1,a3
    80003aa2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aa4:	9f35                	addw	a4,a4,a3
    return 0;
    80003aa6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aa8:	0ad76063          	bltu	a4,a3,80003b48 <readi+0xd2>
  if(off + n > ip->size)
    80003aac:	00e7f463          	bgeu	a5,a4,80003ab4 <readi+0x3e>
    n = ip->size - off;
    80003ab0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab4:	0a0b0963          	beqz	s6,80003b66 <readi+0xf0>
    80003ab8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aba:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003abe:	5cfd                	li	s9,-1
    80003ac0:	a82d                	j	80003afa <readi+0x84>
    80003ac2:	020a1d93          	slli	s11,s4,0x20
    80003ac6:	020ddd93          	srli	s11,s11,0x20
    80003aca:	05890613          	addi	a2,s2,88
    80003ace:	86ee                	mv	a3,s11
    80003ad0:	963a                	add	a2,a2,a4
    80003ad2:	85d6                	mv	a1,s5
    80003ad4:	8562                	mv	a0,s8
    80003ad6:	fffff097          	auipc	ra,0xfffff
    80003ada:	b0a080e7          	jalr	-1270(ra) # 800025e0 <either_copyout>
    80003ade:	05950d63          	beq	a0,s9,80003b38 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	60c080e7          	jalr	1548(ra) # 800030f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aec:	013a09bb          	addw	s3,s4,s3
    80003af0:	009a04bb          	addw	s1,s4,s1
    80003af4:	9aee                	add	s5,s5,s11
    80003af6:	0569f763          	bgeu	s3,s6,80003b44 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003afa:	000ba903          	lw	s2,0(s7)
    80003afe:	00a4d59b          	srliw	a1,s1,0xa
    80003b02:	855e                	mv	a0,s7
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	8b0080e7          	jalr	-1872(ra) # 800033b4 <bmap>
    80003b0c:	0005059b          	sext.w	a1,a0
    80003b10:	854a                	mv	a0,s2
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	4ae080e7          	jalr	1198(ra) # 80002fc0 <bread>
    80003b1a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1c:	3ff4f713          	andi	a4,s1,1023
    80003b20:	40ed07bb          	subw	a5,s10,a4
    80003b24:	413b06bb          	subw	a3,s6,s3
    80003b28:	8a3e                	mv	s4,a5
    80003b2a:	2781                	sext.w	a5,a5
    80003b2c:	0006861b          	sext.w	a2,a3
    80003b30:	f8f679e3          	bgeu	a2,a5,80003ac2 <readi+0x4c>
    80003b34:	8a36                	mv	s4,a3
    80003b36:	b771                	j	80003ac2 <readi+0x4c>
      brelse(bp);
    80003b38:	854a                	mv	a0,s2
    80003b3a:	fffff097          	auipc	ra,0xfffff
    80003b3e:	5b6080e7          	jalr	1462(ra) # 800030f0 <brelse>
      tot = -1;
    80003b42:	59fd                	li	s3,-1
  }
  return tot;
    80003b44:	0009851b          	sext.w	a0,s3
}
    80003b48:	70a6                	ld	ra,104(sp)
    80003b4a:	7406                	ld	s0,96(sp)
    80003b4c:	64e6                	ld	s1,88(sp)
    80003b4e:	6946                	ld	s2,80(sp)
    80003b50:	69a6                	ld	s3,72(sp)
    80003b52:	6a06                	ld	s4,64(sp)
    80003b54:	7ae2                	ld	s5,56(sp)
    80003b56:	7b42                	ld	s6,48(sp)
    80003b58:	7ba2                	ld	s7,40(sp)
    80003b5a:	7c02                	ld	s8,32(sp)
    80003b5c:	6ce2                	ld	s9,24(sp)
    80003b5e:	6d42                	ld	s10,16(sp)
    80003b60:	6da2                	ld	s11,8(sp)
    80003b62:	6165                	addi	sp,sp,112
    80003b64:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b66:	89da                	mv	s3,s6
    80003b68:	bff1                	j	80003b44 <readi+0xce>
    return 0;
    80003b6a:	4501                	li	a0,0
}
    80003b6c:	8082                	ret

0000000080003b6e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6e:	457c                	lw	a5,76(a0)
    80003b70:	10d7e863          	bltu	a5,a3,80003c80 <writei+0x112>
{
    80003b74:	7159                	addi	sp,sp,-112
    80003b76:	f486                	sd	ra,104(sp)
    80003b78:	f0a2                	sd	s0,96(sp)
    80003b7a:	eca6                	sd	s1,88(sp)
    80003b7c:	e8ca                	sd	s2,80(sp)
    80003b7e:	e4ce                	sd	s3,72(sp)
    80003b80:	e0d2                	sd	s4,64(sp)
    80003b82:	fc56                	sd	s5,56(sp)
    80003b84:	f85a                	sd	s6,48(sp)
    80003b86:	f45e                	sd	s7,40(sp)
    80003b88:	f062                	sd	s8,32(sp)
    80003b8a:	ec66                	sd	s9,24(sp)
    80003b8c:	e86a                	sd	s10,16(sp)
    80003b8e:	e46e                	sd	s11,8(sp)
    80003b90:	1880                	addi	s0,sp,112
    80003b92:	8b2a                	mv	s6,a0
    80003b94:	8c2e                	mv	s8,a1
    80003b96:	8ab2                	mv	s5,a2
    80003b98:	8936                	mv	s2,a3
    80003b9a:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b9c:	00e687bb          	addw	a5,a3,a4
    80003ba0:	0ed7e263          	bltu	a5,a3,80003c84 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ba4:	00043737          	lui	a4,0x43
    80003ba8:	0ef76063          	bltu	a4,a5,80003c88 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bac:	0c0b8863          	beqz	s7,80003c7c <writei+0x10e>
    80003bb0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bb6:	5cfd                	li	s9,-1
    80003bb8:	a091                	j	80003bfc <writei+0x8e>
    80003bba:	02099d93          	slli	s11,s3,0x20
    80003bbe:	020ddd93          	srli	s11,s11,0x20
    80003bc2:	05848513          	addi	a0,s1,88
    80003bc6:	86ee                	mv	a3,s11
    80003bc8:	8656                	mv	a2,s5
    80003bca:	85e2                	mv	a1,s8
    80003bcc:	953a                	add	a0,a0,a4
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	a68080e7          	jalr	-1432(ra) # 80002636 <either_copyin>
    80003bd6:	07950263          	beq	a0,s9,80003c3a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bda:	8526                	mv	a0,s1
    80003bdc:	00000097          	auipc	ra,0x0
    80003be0:	790080e7          	jalr	1936(ra) # 8000436c <log_write>
    brelse(bp);
    80003be4:	8526                	mv	a0,s1
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	50a080e7          	jalr	1290(ra) # 800030f0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bee:	01498a3b          	addw	s4,s3,s4
    80003bf2:	0129893b          	addw	s2,s3,s2
    80003bf6:	9aee                	add	s5,s5,s11
    80003bf8:	057a7663          	bgeu	s4,s7,80003c44 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bfc:	000b2483          	lw	s1,0(s6)
    80003c00:	00a9559b          	srliw	a1,s2,0xa
    80003c04:	855a                	mv	a0,s6
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	7ae080e7          	jalr	1966(ra) # 800033b4 <bmap>
    80003c0e:	0005059b          	sext.w	a1,a0
    80003c12:	8526                	mv	a0,s1
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	3ac080e7          	jalr	940(ra) # 80002fc0 <bread>
    80003c1c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1e:	3ff97713          	andi	a4,s2,1023
    80003c22:	40ed07bb          	subw	a5,s10,a4
    80003c26:	414b86bb          	subw	a3,s7,s4
    80003c2a:	89be                	mv	s3,a5
    80003c2c:	2781                	sext.w	a5,a5
    80003c2e:	0006861b          	sext.w	a2,a3
    80003c32:	f8f674e3          	bgeu	a2,a5,80003bba <writei+0x4c>
    80003c36:	89b6                	mv	s3,a3
    80003c38:	b749                	j	80003bba <writei+0x4c>
      brelse(bp);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	fffff097          	auipc	ra,0xfffff
    80003c40:	4b4080e7          	jalr	1204(ra) # 800030f0 <brelse>
  }

  if(off > ip->size)
    80003c44:	04cb2783          	lw	a5,76(s6)
    80003c48:	0127f463          	bgeu	a5,s2,80003c50 <writei+0xe2>
    ip->size = off;
    80003c4c:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c50:	855a                	mv	a0,s6
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	aa6080e7          	jalr	-1370(ra) # 800036f8 <iupdate>

  return tot;
    80003c5a:	000a051b          	sext.w	a0,s4
}
    80003c5e:	70a6                	ld	ra,104(sp)
    80003c60:	7406                	ld	s0,96(sp)
    80003c62:	64e6                	ld	s1,88(sp)
    80003c64:	6946                	ld	s2,80(sp)
    80003c66:	69a6                	ld	s3,72(sp)
    80003c68:	6a06                	ld	s4,64(sp)
    80003c6a:	7ae2                	ld	s5,56(sp)
    80003c6c:	7b42                	ld	s6,48(sp)
    80003c6e:	7ba2                	ld	s7,40(sp)
    80003c70:	7c02                	ld	s8,32(sp)
    80003c72:	6ce2                	ld	s9,24(sp)
    80003c74:	6d42                	ld	s10,16(sp)
    80003c76:	6da2                	ld	s11,8(sp)
    80003c78:	6165                	addi	sp,sp,112
    80003c7a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c7c:	8a5e                	mv	s4,s7
    80003c7e:	bfc9                	j	80003c50 <writei+0xe2>
    return -1;
    80003c80:	557d                	li	a0,-1
}
    80003c82:	8082                	ret
    return -1;
    80003c84:	557d                	li	a0,-1
    80003c86:	bfe1                	j	80003c5e <writei+0xf0>
    return -1;
    80003c88:	557d                	li	a0,-1
    80003c8a:	bfd1                	j	80003c5e <writei+0xf0>

0000000080003c8c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c8c:	1141                	addi	sp,sp,-16
    80003c8e:	e406                	sd	ra,8(sp)
    80003c90:	e022                	sd	s0,0(sp)
    80003c92:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c94:	4639                	li	a2,14
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	118080e7          	jalr	280(ra) # 80000dae <strncmp>
}
    80003c9e:	60a2                	ld	ra,8(sp)
    80003ca0:	6402                	ld	s0,0(sp)
    80003ca2:	0141                	addi	sp,sp,16
    80003ca4:	8082                	ret

0000000080003ca6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ca6:	7139                	addi	sp,sp,-64
    80003ca8:	fc06                	sd	ra,56(sp)
    80003caa:	f822                	sd	s0,48(sp)
    80003cac:	f426                	sd	s1,40(sp)
    80003cae:	f04a                	sd	s2,32(sp)
    80003cb0:	ec4e                	sd	s3,24(sp)
    80003cb2:	e852                	sd	s4,16(sp)
    80003cb4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cb6:	04451703          	lh	a4,68(a0)
    80003cba:	4785                	li	a5,1
    80003cbc:	00f71a63          	bne	a4,a5,80003cd0 <dirlookup+0x2a>
    80003cc0:	892a                	mv	s2,a0
    80003cc2:	89ae                	mv	s3,a1
    80003cc4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc6:	457c                	lw	a5,76(a0)
    80003cc8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cca:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ccc:	e79d                	bnez	a5,80003cfa <dirlookup+0x54>
    80003cce:	a8a5                	j	80003d46 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cd0:	00005517          	auipc	a0,0x5
    80003cd4:	91850513          	addi	a0,a0,-1768 # 800085e8 <syscalls+0x1b0>
    80003cd8:	ffffd097          	auipc	ra,0xffffd
    80003cdc:	858080e7          	jalr	-1960(ra) # 80000530 <panic>
      panic("dirlookup read");
    80003ce0:	00005517          	auipc	a0,0x5
    80003ce4:	92050513          	addi	a0,a0,-1760 # 80008600 <syscalls+0x1c8>
    80003ce8:	ffffd097          	auipc	ra,0xffffd
    80003cec:	848080e7          	jalr	-1976(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf0:	24c1                	addiw	s1,s1,16
    80003cf2:	04c92783          	lw	a5,76(s2)
    80003cf6:	04f4f763          	bgeu	s1,a5,80003d44 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfa:	4741                	li	a4,16
    80003cfc:	86a6                	mv	a3,s1
    80003cfe:	fc040613          	addi	a2,s0,-64
    80003d02:	4581                	li	a1,0
    80003d04:	854a                	mv	a0,s2
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	d70080e7          	jalr	-656(ra) # 80003a76 <readi>
    80003d0e:	47c1                	li	a5,16
    80003d10:	fcf518e3          	bne	a0,a5,80003ce0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d14:	fc045783          	lhu	a5,-64(s0)
    80003d18:	dfe1                	beqz	a5,80003cf0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d1a:	fc240593          	addi	a1,s0,-62
    80003d1e:	854e                	mv	a0,s3
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	f6c080e7          	jalr	-148(ra) # 80003c8c <namecmp>
    80003d28:	f561                	bnez	a0,80003cf0 <dirlookup+0x4a>
      if(poff)
    80003d2a:	000a0463          	beqz	s4,80003d32 <dirlookup+0x8c>
        *poff = off;
    80003d2e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d32:	fc045583          	lhu	a1,-64(s0)
    80003d36:	00092503          	lw	a0,0(s2)
    80003d3a:	fffff097          	auipc	ra,0xfffff
    80003d3e:	754080e7          	jalr	1876(ra) # 8000348e <iget>
    80003d42:	a011                	j	80003d46 <dirlookup+0xa0>
  return 0;
    80003d44:	4501                	li	a0,0
}
    80003d46:	70e2                	ld	ra,56(sp)
    80003d48:	7442                	ld	s0,48(sp)
    80003d4a:	74a2                	ld	s1,40(sp)
    80003d4c:	7902                	ld	s2,32(sp)
    80003d4e:	69e2                	ld	s3,24(sp)
    80003d50:	6a42                	ld	s4,16(sp)
    80003d52:	6121                	addi	sp,sp,64
    80003d54:	8082                	ret

0000000080003d56 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d56:	711d                	addi	sp,sp,-96
    80003d58:	ec86                	sd	ra,88(sp)
    80003d5a:	e8a2                	sd	s0,80(sp)
    80003d5c:	e4a6                	sd	s1,72(sp)
    80003d5e:	e0ca                	sd	s2,64(sp)
    80003d60:	fc4e                	sd	s3,56(sp)
    80003d62:	f852                	sd	s4,48(sp)
    80003d64:	f456                	sd	s5,40(sp)
    80003d66:	f05a                	sd	s6,32(sp)
    80003d68:	ec5e                	sd	s7,24(sp)
    80003d6a:	e862                	sd	s8,16(sp)
    80003d6c:	e466                	sd	s9,8(sp)
    80003d6e:	1080                	addi	s0,sp,96
    80003d70:	84aa                	mv	s1,a0
    80003d72:	8b2e                	mv	s6,a1
    80003d74:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d76:	00054703          	lbu	a4,0(a0)
    80003d7a:	02f00793          	li	a5,47
    80003d7e:	02f70363          	beq	a4,a5,80003da4 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d82:	ffffe097          	auipc	ra,0xffffe
    80003d86:	d52080e7          	jalr	-686(ra) # 80001ad4 <myproc>
    80003d8a:	15053503          	ld	a0,336(a0)
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	9f6080e7          	jalr	-1546(ra) # 80003784 <idup>
    80003d96:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d98:	02f00913          	li	s2,47
  len = path - s;
    80003d9c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d9e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003da0:	4c05                	li	s8,1
    80003da2:	a865                	j	80003e5a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003da4:	4585                	li	a1,1
    80003da6:	4505                	li	a0,1
    80003da8:	fffff097          	auipc	ra,0xfffff
    80003dac:	6e6080e7          	jalr	1766(ra) # 8000348e <iget>
    80003db0:	89aa                	mv	s3,a0
    80003db2:	b7dd                	j	80003d98 <namex+0x42>
      iunlockput(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	c6e080e7          	jalr	-914(ra) # 80003a24 <iunlockput>
      return 0;
    80003dbe:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	60e6                	ld	ra,88(sp)
    80003dc4:	6446                	ld	s0,80(sp)
    80003dc6:	64a6                	ld	s1,72(sp)
    80003dc8:	6906                	ld	s2,64(sp)
    80003dca:	79e2                	ld	s3,56(sp)
    80003dcc:	7a42                	ld	s4,48(sp)
    80003dce:	7aa2                	ld	s5,40(sp)
    80003dd0:	7b02                	ld	s6,32(sp)
    80003dd2:	6be2                	ld	s7,24(sp)
    80003dd4:	6c42                	ld	s8,16(sp)
    80003dd6:	6ca2                	ld	s9,8(sp)
    80003dd8:	6125                	addi	sp,sp,96
    80003dda:	8082                	ret
      iunlock(ip);
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	aa6080e7          	jalr	-1370(ra) # 80003884 <iunlock>
      return ip;
    80003de6:	bfe9                	j	80003dc0 <namex+0x6a>
      iunlockput(ip);
    80003de8:	854e                	mv	a0,s3
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	c3a080e7          	jalr	-966(ra) # 80003a24 <iunlockput>
      return 0;
    80003df2:	89d2                	mv	s3,s4
    80003df4:	b7f1                	j	80003dc0 <namex+0x6a>
  len = path - s;
    80003df6:	40b48633          	sub	a2,s1,a1
    80003dfa:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dfe:	094cd463          	bge	s9,s4,80003e86 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e02:	4639                	li	a2,14
    80003e04:	8556                	mv	a0,s5
    80003e06:	ffffd097          	auipc	ra,0xffffd
    80003e0a:	f2c080e7          	jalr	-212(ra) # 80000d32 <memmove>
  while(*path == '/')
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	01279763          	bne	a5,s2,80003e20 <namex+0xca>
    path++;
    80003e16:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e18:	0004c783          	lbu	a5,0(s1)
    80003e1c:	ff278de3          	beq	a5,s2,80003e16 <namex+0xc0>
    ilock(ip);
    80003e20:	854e                	mv	a0,s3
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	9a0080e7          	jalr	-1632(ra) # 800037c2 <ilock>
    if(ip->type != T_DIR){
    80003e2a:	04499783          	lh	a5,68(s3)
    80003e2e:	f98793e3          	bne	a5,s8,80003db4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e32:	000b0563          	beqz	s6,80003e3c <namex+0xe6>
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	d3cd                	beqz	a5,80003ddc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e3c:	865e                	mv	a2,s7
    80003e3e:	85d6                	mv	a1,s5
    80003e40:	854e                	mv	a0,s3
    80003e42:	00000097          	auipc	ra,0x0
    80003e46:	e64080e7          	jalr	-412(ra) # 80003ca6 <dirlookup>
    80003e4a:	8a2a                	mv	s4,a0
    80003e4c:	dd51                	beqz	a0,80003de8 <namex+0x92>
    iunlockput(ip);
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	bd4080e7          	jalr	-1068(ra) # 80003a24 <iunlockput>
    ip = next;
    80003e58:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e5a:	0004c783          	lbu	a5,0(s1)
    80003e5e:	05279763          	bne	a5,s2,80003eac <namex+0x156>
    path++;
    80003e62:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e64:	0004c783          	lbu	a5,0(s1)
    80003e68:	ff278de3          	beq	a5,s2,80003e62 <namex+0x10c>
  if(*path == 0)
    80003e6c:	c79d                	beqz	a5,80003e9a <namex+0x144>
    path++;
    80003e6e:	85a6                	mv	a1,s1
  len = path - s;
    80003e70:	8a5e                	mv	s4,s7
    80003e72:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e74:	01278963          	beq	a5,s2,80003e86 <namex+0x130>
    80003e78:	dfbd                	beqz	a5,80003df6 <namex+0xa0>
    path++;
    80003e7a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e7c:	0004c783          	lbu	a5,0(s1)
    80003e80:	ff279ce3          	bne	a5,s2,80003e78 <namex+0x122>
    80003e84:	bf8d                	j	80003df6 <namex+0xa0>
    memmove(name, s, len);
    80003e86:	2601                	sext.w	a2,a2
    80003e88:	8556                	mv	a0,s5
    80003e8a:	ffffd097          	auipc	ra,0xffffd
    80003e8e:	ea8080e7          	jalr	-344(ra) # 80000d32 <memmove>
    name[len] = 0;
    80003e92:	9a56                	add	s4,s4,s5
    80003e94:	000a0023          	sb	zero,0(s4)
    80003e98:	bf9d                	j	80003e0e <namex+0xb8>
  if(nameiparent){
    80003e9a:	f20b03e3          	beqz	s6,80003dc0 <namex+0x6a>
    iput(ip);
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	adc080e7          	jalr	-1316(ra) # 8000397c <iput>
    return 0;
    80003ea8:	4981                	li	s3,0
    80003eaa:	bf19                	j	80003dc0 <namex+0x6a>
  if(*path == 0)
    80003eac:	d7fd                	beqz	a5,80003e9a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003eae:	0004c783          	lbu	a5,0(s1)
    80003eb2:	85a6                	mv	a1,s1
    80003eb4:	b7d1                	j	80003e78 <namex+0x122>

0000000080003eb6 <dirlink>:
{
    80003eb6:	7139                	addi	sp,sp,-64
    80003eb8:	fc06                	sd	ra,56(sp)
    80003eba:	f822                	sd	s0,48(sp)
    80003ebc:	f426                	sd	s1,40(sp)
    80003ebe:	f04a                	sd	s2,32(sp)
    80003ec0:	ec4e                	sd	s3,24(sp)
    80003ec2:	e852                	sd	s4,16(sp)
    80003ec4:	0080                	addi	s0,sp,64
    80003ec6:	892a                	mv	s2,a0
    80003ec8:	8a2e                	mv	s4,a1
    80003eca:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ecc:	4601                	li	a2,0
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	dd8080e7          	jalr	-552(ra) # 80003ca6 <dirlookup>
    80003ed6:	e93d                	bnez	a0,80003f4c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed8:	04c92483          	lw	s1,76(s2)
    80003edc:	c49d                	beqz	s1,80003f0a <dirlink+0x54>
    80003ede:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee0:	4741                	li	a4,16
    80003ee2:	86a6                	mv	a3,s1
    80003ee4:	fc040613          	addi	a2,s0,-64
    80003ee8:	4581                	li	a1,0
    80003eea:	854a                	mv	a0,s2
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	b8a080e7          	jalr	-1142(ra) # 80003a76 <readi>
    80003ef4:	47c1                	li	a5,16
    80003ef6:	06f51163          	bne	a0,a5,80003f58 <dirlink+0xa2>
    if(de.inum == 0)
    80003efa:	fc045783          	lhu	a5,-64(s0)
    80003efe:	c791                	beqz	a5,80003f0a <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f00:	24c1                	addiw	s1,s1,16
    80003f02:	04c92783          	lw	a5,76(s2)
    80003f06:	fcf4ede3          	bltu	s1,a5,80003ee0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f0a:	4639                	li	a2,14
    80003f0c:	85d2                	mv	a1,s4
    80003f0e:	fc240513          	addi	a0,s0,-62
    80003f12:	ffffd097          	auipc	ra,0xffffd
    80003f16:	ed8080e7          	jalr	-296(ra) # 80000dea <strncpy>
  de.inum = inum;
    80003f1a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f1e:	4741                	li	a4,16
    80003f20:	86a6                	mv	a3,s1
    80003f22:	fc040613          	addi	a2,s0,-64
    80003f26:	4581                	li	a1,0
    80003f28:	854a                	mv	a0,s2
    80003f2a:	00000097          	auipc	ra,0x0
    80003f2e:	c44080e7          	jalr	-956(ra) # 80003b6e <writei>
    80003f32:	872a                	mv	a4,a0
    80003f34:	47c1                	li	a5,16
  return 0;
    80003f36:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f38:	02f71863          	bne	a4,a5,80003f68 <dirlink+0xb2>
}
    80003f3c:	70e2                	ld	ra,56(sp)
    80003f3e:	7442                	ld	s0,48(sp)
    80003f40:	74a2                	ld	s1,40(sp)
    80003f42:	7902                	ld	s2,32(sp)
    80003f44:	69e2                	ld	s3,24(sp)
    80003f46:	6a42                	ld	s4,16(sp)
    80003f48:	6121                	addi	sp,sp,64
    80003f4a:	8082                	ret
    iput(ip);
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	a30080e7          	jalr	-1488(ra) # 8000397c <iput>
    return -1;
    80003f54:	557d                	li	a0,-1
    80003f56:	b7dd                	j	80003f3c <dirlink+0x86>
      panic("dirlink read");
    80003f58:	00004517          	auipc	a0,0x4
    80003f5c:	6b850513          	addi	a0,a0,1720 # 80008610 <syscalls+0x1d8>
    80003f60:	ffffc097          	auipc	ra,0xffffc
    80003f64:	5d0080e7          	jalr	1488(ra) # 80000530 <panic>
    panic("dirlink");
    80003f68:	00004517          	auipc	a0,0x4
    80003f6c:	7b850513          	addi	a0,a0,1976 # 80008720 <syscalls+0x2e8>
    80003f70:	ffffc097          	auipc	ra,0xffffc
    80003f74:	5c0080e7          	jalr	1472(ra) # 80000530 <panic>

0000000080003f78 <namei>:

struct inode*
namei(char *path)
{
    80003f78:	1101                	addi	sp,sp,-32
    80003f7a:	ec06                	sd	ra,24(sp)
    80003f7c:	e822                	sd	s0,16(sp)
    80003f7e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f80:	fe040613          	addi	a2,s0,-32
    80003f84:	4581                	li	a1,0
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	dd0080e7          	jalr	-560(ra) # 80003d56 <namex>
}
    80003f8e:	60e2                	ld	ra,24(sp)
    80003f90:	6442                	ld	s0,16(sp)
    80003f92:	6105                	addi	sp,sp,32
    80003f94:	8082                	ret

0000000080003f96 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f96:	1141                	addi	sp,sp,-16
    80003f98:	e406                	sd	ra,8(sp)
    80003f9a:	e022                	sd	s0,0(sp)
    80003f9c:	0800                	addi	s0,sp,16
    80003f9e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003fa0:	4585                	li	a1,1
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	db4080e7          	jalr	-588(ra) # 80003d56 <namex>
}
    80003faa:	60a2                	ld	ra,8(sp)
    80003fac:	6402                	ld	s0,0(sp)
    80003fae:	0141                	addi	sp,sp,16
    80003fb0:	8082                	ret

0000000080003fb2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fb2:	1101                	addi	sp,sp,-32
    80003fb4:	ec06                	sd	ra,24(sp)
    80003fb6:	e822                	sd	s0,16(sp)
    80003fb8:	e426                	sd	s1,8(sp)
    80003fba:	e04a                	sd	s2,0(sp)
    80003fbc:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fbe:	00029917          	auipc	s2,0x29
    80003fc2:	29a90913          	addi	s2,s2,666 # 8002d258 <log>
    80003fc6:	01892583          	lw	a1,24(s2)
    80003fca:	02892503          	lw	a0,40(s2)
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	ff2080e7          	jalr	-14(ra) # 80002fc0 <bread>
    80003fd6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fd8:	02c92683          	lw	a3,44(s2)
    80003fdc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fde:	02d05763          	blez	a3,8000400c <write_head+0x5a>
    80003fe2:	00029797          	auipc	a5,0x29
    80003fe6:	2a678793          	addi	a5,a5,678 # 8002d288 <log+0x30>
    80003fea:	05c50713          	addi	a4,a0,92
    80003fee:	36fd                	addiw	a3,a3,-1
    80003ff0:	1682                	slli	a3,a3,0x20
    80003ff2:	9281                	srli	a3,a3,0x20
    80003ff4:	068a                	slli	a3,a3,0x2
    80003ff6:	00029617          	auipc	a2,0x29
    80003ffa:	29660613          	addi	a2,a2,662 # 8002d28c <log+0x34>
    80003ffe:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004000:	4390                	lw	a2,0(a5)
    80004002:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004004:	0791                	addi	a5,a5,4
    80004006:	0711                	addi	a4,a4,4
    80004008:	fed79ce3          	bne	a5,a3,80004000 <write_head+0x4e>
  }
  bwrite(buf);
    8000400c:	8526                	mv	a0,s1
    8000400e:	fffff097          	auipc	ra,0xfffff
    80004012:	0a4080e7          	jalr	164(ra) # 800030b2 <bwrite>
  brelse(buf);
    80004016:	8526                	mv	a0,s1
    80004018:	fffff097          	auipc	ra,0xfffff
    8000401c:	0d8080e7          	jalr	216(ra) # 800030f0 <brelse>
}
    80004020:	60e2                	ld	ra,24(sp)
    80004022:	6442                	ld	s0,16(sp)
    80004024:	64a2                	ld	s1,8(sp)
    80004026:	6902                	ld	s2,0(sp)
    80004028:	6105                	addi	sp,sp,32
    8000402a:	8082                	ret

000000008000402c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402c:	00029797          	auipc	a5,0x29
    80004030:	2587a783          	lw	a5,600(a5) # 8002d284 <log+0x2c>
    80004034:	0af05d63          	blez	a5,800040ee <install_trans+0xc2>
{
    80004038:	7139                	addi	sp,sp,-64
    8000403a:	fc06                	sd	ra,56(sp)
    8000403c:	f822                	sd	s0,48(sp)
    8000403e:	f426                	sd	s1,40(sp)
    80004040:	f04a                	sd	s2,32(sp)
    80004042:	ec4e                	sd	s3,24(sp)
    80004044:	e852                	sd	s4,16(sp)
    80004046:	e456                	sd	s5,8(sp)
    80004048:	e05a                	sd	s6,0(sp)
    8000404a:	0080                	addi	s0,sp,64
    8000404c:	8b2a                	mv	s6,a0
    8000404e:	00029a97          	auipc	s5,0x29
    80004052:	23aa8a93          	addi	s5,s5,570 # 8002d288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004056:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004058:	00029997          	auipc	s3,0x29
    8000405c:	20098993          	addi	s3,s3,512 # 8002d258 <log>
    80004060:	a035                	j	8000408c <install_trans+0x60>
      bunpin(dbuf);
    80004062:	8526                	mv	a0,s1
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	166080e7          	jalr	358(ra) # 800031ca <bunpin>
    brelse(lbuf);
    8000406c:	854a                	mv	a0,s2
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	082080e7          	jalr	130(ra) # 800030f0 <brelse>
    brelse(dbuf);
    80004076:	8526                	mv	a0,s1
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	078080e7          	jalr	120(ra) # 800030f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004080:	2a05                	addiw	s4,s4,1
    80004082:	0a91                	addi	s5,s5,4
    80004084:	02c9a783          	lw	a5,44(s3)
    80004088:	04fa5963          	bge	s4,a5,800040da <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000408c:	0189a583          	lw	a1,24(s3)
    80004090:	014585bb          	addw	a1,a1,s4
    80004094:	2585                	addiw	a1,a1,1
    80004096:	0289a503          	lw	a0,40(s3)
    8000409a:	fffff097          	auipc	ra,0xfffff
    8000409e:	f26080e7          	jalr	-218(ra) # 80002fc0 <bread>
    800040a2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040a4:	000aa583          	lw	a1,0(s5)
    800040a8:	0289a503          	lw	a0,40(s3)
    800040ac:	fffff097          	auipc	ra,0xfffff
    800040b0:	f14080e7          	jalr	-236(ra) # 80002fc0 <bread>
    800040b4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040b6:	40000613          	li	a2,1024
    800040ba:	05890593          	addi	a1,s2,88
    800040be:	05850513          	addi	a0,a0,88
    800040c2:	ffffd097          	auipc	ra,0xffffd
    800040c6:	c70080e7          	jalr	-912(ra) # 80000d32 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040ca:	8526                	mv	a0,s1
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	fe6080e7          	jalr	-26(ra) # 800030b2 <bwrite>
    if(recovering == 0)
    800040d4:	f80b1ce3          	bnez	s6,8000406c <install_trans+0x40>
    800040d8:	b769                	j	80004062 <install_trans+0x36>
}
    800040da:	70e2                	ld	ra,56(sp)
    800040dc:	7442                	ld	s0,48(sp)
    800040de:	74a2                	ld	s1,40(sp)
    800040e0:	7902                	ld	s2,32(sp)
    800040e2:	69e2                	ld	s3,24(sp)
    800040e4:	6a42                	ld	s4,16(sp)
    800040e6:	6aa2                	ld	s5,8(sp)
    800040e8:	6b02                	ld	s6,0(sp)
    800040ea:	6121                	addi	sp,sp,64
    800040ec:	8082                	ret
    800040ee:	8082                	ret

00000000800040f0 <initlog>:
{
    800040f0:	7179                	addi	sp,sp,-48
    800040f2:	f406                	sd	ra,40(sp)
    800040f4:	f022                	sd	s0,32(sp)
    800040f6:	ec26                	sd	s1,24(sp)
    800040f8:	e84a                	sd	s2,16(sp)
    800040fa:	e44e                	sd	s3,8(sp)
    800040fc:	1800                	addi	s0,sp,48
    800040fe:	892a                	mv	s2,a0
    80004100:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004102:	00029497          	auipc	s1,0x29
    80004106:	15648493          	addi	s1,s1,342 # 8002d258 <log>
    8000410a:	00004597          	auipc	a1,0x4
    8000410e:	51658593          	addi	a1,a1,1302 # 80008620 <syscalls+0x1e8>
    80004112:	8526                	mv	a0,s1
    80004114:	ffffd097          	auipc	ra,0xffffd
    80004118:	a32080e7          	jalr	-1486(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000411c:	0149a583          	lw	a1,20(s3)
    80004120:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004122:	0109a783          	lw	a5,16(s3)
    80004126:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004128:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000412c:	854a                	mv	a0,s2
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	e92080e7          	jalr	-366(ra) # 80002fc0 <bread>
  log.lh.n = lh->n;
    80004136:	4d3c                	lw	a5,88(a0)
    80004138:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000413a:	02f05563          	blez	a5,80004164 <initlog+0x74>
    8000413e:	05c50713          	addi	a4,a0,92
    80004142:	00029697          	auipc	a3,0x29
    80004146:	14668693          	addi	a3,a3,326 # 8002d288 <log+0x30>
    8000414a:	37fd                	addiw	a5,a5,-1
    8000414c:	1782                	slli	a5,a5,0x20
    8000414e:	9381                	srli	a5,a5,0x20
    80004150:	078a                	slli	a5,a5,0x2
    80004152:	06050613          	addi	a2,a0,96
    80004156:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004158:	4310                	lw	a2,0(a4)
    8000415a:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000415c:	0711                	addi	a4,a4,4
    8000415e:	0691                	addi	a3,a3,4
    80004160:	fef71ce3          	bne	a4,a5,80004158 <initlog+0x68>
  brelse(buf);
    80004164:	fffff097          	auipc	ra,0xfffff
    80004168:	f8c080e7          	jalr	-116(ra) # 800030f0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000416c:	4505                	li	a0,1
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	ebe080e7          	jalr	-322(ra) # 8000402c <install_trans>
  log.lh.n = 0;
    80004176:	00029797          	auipc	a5,0x29
    8000417a:	1007a723          	sw	zero,270(a5) # 8002d284 <log+0x2c>
  write_head(); // clear the log
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	e34080e7          	jalr	-460(ra) # 80003fb2 <write_head>
}
    80004186:	70a2                	ld	ra,40(sp)
    80004188:	7402                	ld	s0,32(sp)
    8000418a:	64e2                	ld	s1,24(sp)
    8000418c:	6942                	ld	s2,16(sp)
    8000418e:	69a2                	ld	s3,8(sp)
    80004190:	6145                	addi	sp,sp,48
    80004192:	8082                	ret

0000000080004194 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004194:	1101                	addi	sp,sp,-32
    80004196:	ec06                	sd	ra,24(sp)
    80004198:	e822                	sd	s0,16(sp)
    8000419a:	e426                	sd	s1,8(sp)
    8000419c:	e04a                	sd	s2,0(sp)
    8000419e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041a0:	00029517          	auipc	a0,0x29
    800041a4:	0b850513          	addi	a0,a0,184 # 8002d258 <log>
    800041a8:	ffffd097          	auipc	ra,0xffffd
    800041ac:	a2e080e7          	jalr	-1490(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041b0:	00029497          	auipc	s1,0x29
    800041b4:	0a848493          	addi	s1,s1,168 # 8002d258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b8:	4979                	li	s2,30
    800041ba:	a039                	j	800041c8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041bc:	85a6                	mv	a1,s1
    800041be:	8526                	mv	a0,s1
    800041c0:	ffffe097          	auipc	ra,0xffffe
    800041c4:	1be080e7          	jalr	446(ra) # 8000237e <sleep>
    if(log.committing){
    800041c8:	50dc                	lw	a5,36(s1)
    800041ca:	fbed                	bnez	a5,800041bc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041cc:	509c                	lw	a5,32(s1)
    800041ce:	0017871b          	addiw	a4,a5,1
    800041d2:	0007069b          	sext.w	a3,a4
    800041d6:	0027179b          	slliw	a5,a4,0x2
    800041da:	9fb9                	addw	a5,a5,a4
    800041dc:	0017979b          	slliw	a5,a5,0x1
    800041e0:	54d8                	lw	a4,44(s1)
    800041e2:	9fb9                	addw	a5,a5,a4
    800041e4:	00f95963          	bge	s2,a5,800041f6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041e8:	85a6                	mv	a1,s1
    800041ea:	8526                	mv	a0,s1
    800041ec:	ffffe097          	auipc	ra,0xffffe
    800041f0:	192080e7          	jalr	402(ra) # 8000237e <sleep>
    800041f4:	bfd1                	j	800041c8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041f6:	00029517          	auipc	a0,0x29
    800041fa:	06250513          	addi	a0,a0,98 # 8002d258 <log>
    800041fe:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	a8a080e7          	jalr	-1398(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004208:	60e2                	ld	ra,24(sp)
    8000420a:	6442                	ld	s0,16(sp)
    8000420c:	64a2                	ld	s1,8(sp)
    8000420e:	6902                	ld	s2,0(sp)
    80004210:	6105                	addi	sp,sp,32
    80004212:	8082                	ret

0000000080004214 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004214:	7139                	addi	sp,sp,-64
    80004216:	fc06                	sd	ra,56(sp)
    80004218:	f822                	sd	s0,48(sp)
    8000421a:	f426                	sd	s1,40(sp)
    8000421c:	f04a                	sd	s2,32(sp)
    8000421e:	ec4e                	sd	s3,24(sp)
    80004220:	e852                	sd	s4,16(sp)
    80004222:	e456                	sd	s5,8(sp)
    80004224:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004226:	00029497          	auipc	s1,0x29
    8000422a:	03248493          	addi	s1,s1,50 # 8002d258 <log>
    8000422e:	8526                	mv	a0,s1
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	9a6080e7          	jalr	-1626(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004238:	509c                	lw	a5,32(s1)
    8000423a:	37fd                	addiw	a5,a5,-1
    8000423c:	0007891b          	sext.w	s2,a5
    80004240:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004242:	50dc                	lw	a5,36(s1)
    80004244:	efb9                	bnez	a5,800042a2 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004246:	06091663          	bnez	s2,800042b2 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000424a:	00029497          	auipc	s1,0x29
    8000424e:	00e48493          	addi	s1,s1,14 # 8002d258 <log>
    80004252:	4785                	li	a5,1
    80004254:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004256:	8526                	mv	a0,s1
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	a32080e7          	jalr	-1486(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004260:	54dc                	lw	a5,44(s1)
    80004262:	06f04763          	bgtz	a5,800042d0 <end_op+0xbc>
    acquire(&log.lock);
    80004266:	00029497          	auipc	s1,0x29
    8000426a:	ff248493          	addi	s1,s1,-14 # 8002d258 <log>
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	966080e7          	jalr	-1690(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004278:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffe097          	auipc	ra,0xffffe
    80004282:	286080e7          	jalr	646(ra) # 80002504 <wakeup>
    release(&log.lock);
    80004286:	8526                	mv	a0,s1
    80004288:	ffffd097          	auipc	ra,0xffffd
    8000428c:	a02080e7          	jalr	-1534(ra) # 80000c8a <release>
}
    80004290:	70e2                	ld	ra,56(sp)
    80004292:	7442                	ld	s0,48(sp)
    80004294:	74a2                	ld	s1,40(sp)
    80004296:	7902                	ld	s2,32(sp)
    80004298:	69e2                	ld	s3,24(sp)
    8000429a:	6a42                	ld	s4,16(sp)
    8000429c:	6aa2                	ld	s5,8(sp)
    8000429e:	6121                	addi	sp,sp,64
    800042a0:	8082                	ret
    panic("log.committing");
    800042a2:	00004517          	auipc	a0,0x4
    800042a6:	38650513          	addi	a0,a0,902 # 80008628 <syscalls+0x1f0>
    800042aa:	ffffc097          	auipc	ra,0xffffc
    800042ae:	286080e7          	jalr	646(ra) # 80000530 <panic>
    wakeup(&log);
    800042b2:	00029497          	auipc	s1,0x29
    800042b6:	fa648493          	addi	s1,s1,-90 # 8002d258 <log>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffe097          	auipc	ra,0xffffe
    800042c0:	248080e7          	jalr	584(ra) # 80002504 <wakeup>
  release(&log.lock);
    800042c4:	8526                	mv	a0,s1
    800042c6:	ffffd097          	auipc	ra,0xffffd
    800042ca:	9c4080e7          	jalr	-1596(ra) # 80000c8a <release>
  if(do_commit){
    800042ce:	b7c9                	j	80004290 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042d0:	00029a97          	auipc	s5,0x29
    800042d4:	fb8a8a93          	addi	s5,s5,-72 # 8002d288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042d8:	00029a17          	auipc	s4,0x29
    800042dc:	f80a0a13          	addi	s4,s4,-128 # 8002d258 <log>
    800042e0:	018a2583          	lw	a1,24(s4)
    800042e4:	012585bb          	addw	a1,a1,s2
    800042e8:	2585                	addiw	a1,a1,1
    800042ea:	028a2503          	lw	a0,40(s4)
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	cd2080e7          	jalr	-814(ra) # 80002fc0 <bread>
    800042f6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042f8:	000aa583          	lw	a1,0(s5)
    800042fc:	028a2503          	lw	a0,40(s4)
    80004300:	fffff097          	auipc	ra,0xfffff
    80004304:	cc0080e7          	jalr	-832(ra) # 80002fc0 <bread>
    80004308:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000430a:	40000613          	li	a2,1024
    8000430e:	05850593          	addi	a1,a0,88
    80004312:	05848513          	addi	a0,s1,88
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	a1c080e7          	jalr	-1508(ra) # 80000d32 <memmove>
    bwrite(to);  // write the log
    8000431e:	8526                	mv	a0,s1
    80004320:	fffff097          	auipc	ra,0xfffff
    80004324:	d92080e7          	jalr	-622(ra) # 800030b2 <bwrite>
    brelse(from);
    80004328:	854e                	mv	a0,s3
    8000432a:	fffff097          	auipc	ra,0xfffff
    8000432e:	dc6080e7          	jalr	-570(ra) # 800030f0 <brelse>
    brelse(to);
    80004332:	8526                	mv	a0,s1
    80004334:	fffff097          	auipc	ra,0xfffff
    80004338:	dbc080e7          	jalr	-580(ra) # 800030f0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000433c:	2905                	addiw	s2,s2,1
    8000433e:	0a91                	addi	s5,s5,4
    80004340:	02ca2783          	lw	a5,44(s4)
    80004344:	f8f94ee3          	blt	s2,a5,800042e0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	c6a080e7          	jalr	-918(ra) # 80003fb2 <write_head>
    install_trans(0); // Now install writes to home locations
    80004350:	4501                	li	a0,0
    80004352:	00000097          	auipc	ra,0x0
    80004356:	cda080e7          	jalr	-806(ra) # 8000402c <install_trans>
    log.lh.n = 0;
    8000435a:	00029797          	auipc	a5,0x29
    8000435e:	f207a523          	sw	zero,-214(a5) # 8002d284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004362:	00000097          	auipc	ra,0x0
    80004366:	c50080e7          	jalr	-944(ra) # 80003fb2 <write_head>
    8000436a:	bdf5                	j	80004266 <end_op+0x52>

000000008000436c <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000436c:	1101                	addi	sp,sp,-32
    8000436e:	ec06                	sd	ra,24(sp)
    80004370:	e822                	sd	s0,16(sp)
    80004372:	e426                	sd	s1,8(sp)
    80004374:	e04a                	sd	s2,0(sp)
    80004376:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004378:	00029717          	auipc	a4,0x29
    8000437c:	f0c72703          	lw	a4,-244(a4) # 8002d284 <log+0x2c>
    80004380:	47f5                	li	a5,29
    80004382:	08e7c063          	blt	a5,a4,80004402 <log_write+0x96>
    80004386:	84aa                	mv	s1,a0
    80004388:	00029797          	auipc	a5,0x29
    8000438c:	eec7a783          	lw	a5,-276(a5) # 8002d274 <log+0x1c>
    80004390:	37fd                	addiw	a5,a5,-1
    80004392:	06f75863          	bge	a4,a5,80004402 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004396:	00029797          	auipc	a5,0x29
    8000439a:	ee27a783          	lw	a5,-286(a5) # 8002d278 <log+0x20>
    8000439e:	06f05a63          	blez	a5,80004412 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043a2:	00029917          	auipc	s2,0x29
    800043a6:	eb690913          	addi	s2,s2,-330 # 8002d258 <log>
    800043aa:	854a                	mv	a0,s2
    800043ac:	ffffd097          	auipc	ra,0xffffd
    800043b0:	82a080e7          	jalr	-2006(ra) # 80000bd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800043b4:	02c92603          	lw	a2,44(s2)
    800043b8:	06c05563          	blez	a2,80004422 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043bc:	44cc                	lw	a1,12(s1)
    800043be:	00029717          	auipc	a4,0x29
    800043c2:	eca70713          	addi	a4,a4,-310 # 8002d288 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043c8:	4314                	lw	a3,0(a4)
    800043ca:	04b68d63          	beq	a3,a1,80004424 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043ce:	2785                	addiw	a5,a5,1
    800043d0:	0711                	addi	a4,a4,4
    800043d2:	fec79be3          	bne	a5,a2,800043c8 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043d6:	0621                	addi	a2,a2,8
    800043d8:	060a                	slli	a2,a2,0x2
    800043da:	00029797          	auipc	a5,0x29
    800043de:	e7e78793          	addi	a5,a5,-386 # 8002d258 <log>
    800043e2:	963e                	add	a2,a2,a5
    800043e4:	44dc                	lw	a5,12(s1)
    800043e6:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	da4080e7          	jalr	-604(ra) # 8000318e <bpin>
    log.lh.n++;
    800043f2:	00029717          	auipc	a4,0x29
    800043f6:	e6670713          	addi	a4,a4,-410 # 8002d258 <log>
    800043fa:	575c                	lw	a5,44(a4)
    800043fc:	2785                	addiw	a5,a5,1
    800043fe:	d75c                	sw	a5,44(a4)
    80004400:	a83d                	j	8000443e <log_write+0xd2>
    panic("too big a transaction");
    80004402:	00004517          	auipc	a0,0x4
    80004406:	23650513          	addi	a0,a0,566 # 80008638 <syscalls+0x200>
    8000440a:	ffffc097          	auipc	ra,0xffffc
    8000440e:	126080e7          	jalr	294(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    80004412:	00004517          	auipc	a0,0x4
    80004416:	23e50513          	addi	a0,a0,574 # 80008650 <syscalls+0x218>
    8000441a:	ffffc097          	auipc	ra,0xffffc
    8000441e:	116080e7          	jalr	278(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004422:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004424:	00878713          	addi	a4,a5,8
    80004428:	00271693          	slli	a3,a4,0x2
    8000442c:	00029717          	auipc	a4,0x29
    80004430:	e2c70713          	addi	a4,a4,-468 # 8002d258 <log>
    80004434:	9736                	add	a4,a4,a3
    80004436:	44d4                	lw	a3,12(s1)
    80004438:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000443a:	faf607e3          	beq	a2,a5,800043e8 <log_write+0x7c>
  }
  release(&log.lock);
    8000443e:	00029517          	auipc	a0,0x29
    80004442:	e1a50513          	addi	a0,a0,-486 # 8002d258 <log>
    80004446:	ffffd097          	auipc	ra,0xffffd
    8000444a:	844080e7          	jalr	-1980(ra) # 80000c8a <release>
}
    8000444e:	60e2                	ld	ra,24(sp)
    80004450:	6442                	ld	s0,16(sp)
    80004452:	64a2                	ld	s1,8(sp)
    80004454:	6902                	ld	s2,0(sp)
    80004456:	6105                	addi	sp,sp,32
    80004458:	8082                	ret

000000008000445a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000445a:	1101                	addi	sp,sp,-32
    8000445c:	ec06                	sd	ra,24(sp)
    8000445e:	e822                	sd	s0,16(sp)
    80004460:	e426                	sd	s1,8(sp)
    80004462:	e04a                	sd	s2,0(sp)
    80004464:	1000                	addi	s0,sp,32
    80004466:	84aa                	mv	s1,a0
    80004468:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000446a:	00004597          	auipc	a1,0x4
    8000446e:	20658593          	addi	a1,a1,518 # 80008670 <syscalls+0x238>
    80004472:	0521                	addi	a0,a0,8
    80004474:	ffffc097          	auipc	ra,0xffffc
    80004478:	6d2080e7          	jalr	1746(ra) # 80000b46 <initlock>
  lk->name = name;
    8000447c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004480:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004484:	0204a423          	sw	zero,40(s1)
}
    80004488:	60e2                	ld	ra,24(sp)
    8000448a:	6442                	ld	s0,16(sp)
    8000448c:	64a2                	ld	s1,8(sp)
    8000448e:	6902                	ld	s2,0(sp)
    80004490:	6105                	addi	sp,sp,32
    80004492:	8082                	ret

0000000080004494 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004494:	1101                	addi	sp,sp,-32
    80004496:	ec06                	sd	ra,24(sp)
    80004498:	e822                	sd	s0,16(sp)
    8000449a:	e426                	sd	s1,8(sp)
    8000449c:	e04a                	sd	s2,0(sp)
    8000449e:	1000                	addi	s0,sp,32
    800044a0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044a2:	00850913          	addi	s2,a0,8
    800044a6:	854a                	mv	a0,s2
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	72e080e7          	jalr	1838(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044b0:	409c                	lw	a5,0(s1)
    800044b2:	cb89                	beqz	a5,800044c4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044b4:	85ca                	mv	a1,s2
    800044b6:	8526                	mv	a0,s1
    800044b8:	ffffe097          	auipc	ra,0xffffe
    800044bc:	ec6080e7          	jalr	-314(ra) # 8000237e <sleep>
  while (lk->locked) {
    800044c0:	409c                	lw	a5,0(s1)
    800044c2:	fbed                	bnez	a5,800044b4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044c4:	4785                	li	a5,1
    800044c6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044c8:	ffffd097          	auipc	ra,0xffffd
    800044cc:	60c080e7          	jalr	1548(ra) # 80001ad4 <myproc>
    800044d0:	5d1c                	lw	a5,56(a0)
    800044d2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044d4:	854a                	mv	a0,s2
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
}
    800044de:	60e2                	ld	ra,24(sp)
    800044e0:	6442                	ld	s0,16(sp)
    800044e2:	64a2                	ld	s1,8(sp)
    800044e4:	6902                	ld	s2,0(sp)
    800044e6:	6105                	addi	sp,sp,32
    800044e8:	8082                	ret

00000000800044ea <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	e04a                	sd	s2,0(sp)
    800044f4:	1000                	addi	s0,sp,32
    800044f6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044f8:	00850913          	addi	s2,a0,8
    800044fc:	854a                	mv	a0,s2
    800044fe:	ffffc097          	auipc	ra,0xffffc
    80004502:	6d8080e7          	jalr	1752(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004506:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000450a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000450e:	8526                	mv	a0,s1
    80004510:	ffffe097          	auipc	ra,0xffffe
    80004514:	ff4080e7          	jalr	-12(ra) # 80002504 <wakeup>
  release(&lk->lk);
    80004518:	854a                	mv	a0,s2
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	770080e7          	jalr	1904(ra) # 80000c8a <release>
}
    80004522:	60e2                	ld	ra,24(sp)
    80004524:	6442                	ld	s0,16(sp)
    80004526:	64a2                	ld	s1,8(sp)
    80004528:	6902                	ld	s2,0(sp)
    8000452a:	6105                	addi	sp,sp,32
    8000452c:	8082                	ret

000000008000452e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000452e:	7179                	addi	sp,sp,-48
    80004530:	f406                	sd	ra,40(sp)
    80004532:	f022                	sd	s0,32(sp)
    80004534:	ec26                	sd	s1,24(sp)
    80004536:	e84a                	sd	s2,16(sp)
    80004538:	e44e                	sd	s3,8(sp)
    8000453a:	1800                	addi	s0,sp,48
    8000453c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000453e:	00850913          	addi	s2,a0,8
    80004542:	854a                	mv	a0,s2
    80004544:	ffffc097          	auipc	ra,0xffffc
    80004548:	692080e7          	jalr	1682(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000454c:	409c                	lw	a5,0(s1)
    8000454e:	ef99                	bnez	a5,8000456c <holdingsleep+0x3e>
    80004550:	4481                	li	s1,0
  release(&lk->lk);
    80004552:	854a                	mv	a0,s2
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	736080e7          	jalr	1846(ra) # 80000c8a <release>
  return r;
}
    8000455c:	8526                	mv	a0,s1
    8000455e:	70a2                	ld	ra,40(sp)
    80004560:	7402                	ld	s0,32(sp)
    80004562:	64e2                	ld	s1,24(sp)
    80004564:	6942                	ld	s2,16(sp)
    80004566:	69a2                	ld	s3,8(sp)
    80004568:	6145                	addi	sp,sp,48
    8000456a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000456c:	0284a983          	lw	s3,40(s1)
    80004570:	ffffd097          	auipc	ra,0xffffd
    80004574:	564080e7          	jalr	1380(ra) # 80001ad4 <myproc>
    80004578:	5d04                	lw	s1,56(a0)
    8000457a:	413484b3          	sub	s1,s1,s3
    8000457e:	0014b493          	seqz	s1,s1
    80004582:	bfc1                	j	80004552 <holdingsleep+0x24>

0000000080004584 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004584:	1141                	addi	sp,sp,-16
    80004586:	e406                	sd	ra,8(sp)
    80004588:	e022                	sd	s0,0(sp)
    8000458a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000458c:	00004597          	auipc	a1,0x4
    80004590:	0f458593          	addi	a1,a1,244 # 80008680 <syscalls+0x248>
    80004594:	00029517          	auipc	a0,0x29
    80004598:	e0c50513          	addi	a0,a0,-500 # 8002d3a0 <ftable>
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	5aa080e7          	jalr	1450(ra) # 80000b46 <initlock>
}
    800045a4:	60a2                	ld	ra,8(sp)
    800045a6:	6402                	ld	s0,0(sp)
    800045a8:	0141                	addi	sp,sp,16
    800045aa:	8082                	ret

00000000800045ac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045ac:	1101                	addi	sp,sp,-32
    800045ae:	ec06                	sd	ra,24(sp)
    800045b0:	e822                	sd	s0,16(sp)
    800045b2:	e426                	sd	s1,8(sp)
    800045b4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045b6:	00029517          	auipc	a0,0x29
    800045ba:	dea50513          	addi	a0,a0,-534 # 8002d3a0 <ftable>
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	618080e7          	jalr	1560(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c6:	00029497          	auipc	s1,0x29
    800045ca:	df248493          	addi	s1,s1,-526 # 8002d3b8 <ftable+0x18>
    800045ce:	0002a717          	auipc	a4,0x2a
    800045d2:	d8a70713          	addi	a4,a4,-630 # 8002e358 <ftable+0xfb8>
    if(f->ref == 0){
    800045d6:	40dc                	lw	a5,4(s1)
    800045d8:	cf99                	beqz	a5,800045f6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045da:	02848493          	addi	s1,s1,40
    800045de:	fee49ce3          	bne	s1,a4,800045d6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045e2:	00029517          	auipc	a0,0x29
    800045e6:	dbe50513          	addi	a0,a0,-578 # 8002d3a0 <ftable>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6a0080e7          	jalr	1696(ra) # 80000c8a <release>
  return 0;
    800045f2:	4481                	li	s1,0
    800045f4:	a819                	j	8000460a <filealloc+0x5e>
      f->ref = 1;
    800045f6:	4785                	li	a5,1
    800045f8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045fa:	00029517          	auipc	a0,0x29
    800045fe:	da650513          	addi	a0,a0,-602 # 8002d3a0 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	688080e7          	jalr	1672(ra) # 80000c8a <release>
}
    8000460a:	8526                	mv	a0,s1
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6105                	addi	sp,sp,32
    80004614:	8082                	ret

0000000080004616 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004616:	1101                	addi	sp,sp,-32
    80004618:	ec06                	sd	ra,24(sp)
    8000461a:	e822                	sd	s0,16(sp)
    8000461c:	e426                	sd	s1,8(sp)
    8000461e:	1000                	addi	s0,sp,32
    80004620:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004622:	00029517          	auipc	a0,0x29
    80004626:	d7e50513          	addi	a0,a0,-642 # 8002d3a0 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	5ac080e7          	jalr	1452(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004632:	40dc                	lw	a5,4(s1)
    80004634:	02f05263          	blez	a5,80004658 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004638:	2785                	addiw	a5,a5,1
    8000463a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000463c:	00029517          	auipc	a0,0x29
    80004640:	d6450513          	addi	a0,a0,-668 # 8002d3a0 <ftable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	646080e7          	jalr	1606(ra) # 80000c8a <release>
  return f;
}
    8000464c:	8526                	mv	a0,s1
    8000464e:	60e2                	ld	ra,24(sp)
    80004650:	6442                	ld	s0,16(sp)
    80004652:	64a2                	ld	s1,8(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret
    panic("filedup");
    80004658:	00004517          	auipc	a0,0x4
    8000465c:	03050513          	addi	a0,a0,48 # 80008688 <syscalls+0x250>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	ed0080e7          	jalr	-304(ra) # 80000530 <panic>

0000000080004668 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004668:	7139                	addi	sp,sp,-64
    8000466a:	fc06                	sd	ra,56(sp)
    8000466c:	f822                	sd	s0,48(sp)
    8000466e:	f426                	sd	s1,40(sp)
    80004670:	f04a                	sd	s2,32(sp)
    80004672:	ec4e                	sd	s3,24(sp)
    80004674:	e852                	sd	s4,16(sp)
    80004676:	e456                	sd	s5,8(sp)
    80004678:	0080                	addi	s0,sp,64
    8000467a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000467c:	00029517          	auipc	a0,0x29
    80004680:	d2450513          	addi	a0,a0,-732 # 8002d3a0 <ftable>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	552080e7          	jalr	1362(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000468c:	40dc                	lw	a5,4(s1)
    8000468e:	06f05163          	blez	a5,800046f0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004692:	37fd                	addiw	a5,a5,-1
    80004694:	0007871b          	sext.w	a4,a5
    80004698:	c0dc                	sw	a5,4(s1)
    8000469a:	06e04363          	bgtz	a4,80004700 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000469e:	0004a903          	lw	s2,0(s1)
    800046a2:	0094ca83          	lbu	s5,9(s1)
    800046a6:	0104ba03          	ld	s4,16(s1)
    800046aa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046b2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046b6:	00029517          	auipc	a0,0x29
    800046ba:	cea50513          	addi	a0,a0,-790 # 8002d3a0 <ftable>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	5cc080e7          	jalr	1484(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046c6:	4785                	li	a5,1
    800046c8:	04f90d63          	beq	s2,a5,80004722 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046cc:	3979                	addiw	s2,s2,-2
    800046ce:	4785                	li	a5,1
    800046d0:	0527e063          	bltu	a5,s2,80004710 <fileclose+0xa8>
    begin_op();
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	ac0080e7          	jalr	-1344(ra) # 80004194 <begin_op>
    iput(ff.ip);
    800046dc:	854e                	mv	a0,s3
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	29e080e7          	jalr	670(ra) # 8000397c <iput>
    end_op();
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	b2e080e7          	jalr	-1234(ra) # 80004214 <end_op>
    800046ee:	a00d                	j	80004710 <fileclose+0xa8>
    panic("fileclose");
    800046f0:	00004517          	auipc	a0,0x4
    800046f4:	fa050513          	addi	a0,a0,-96 # 80008690 <syscalls+0x258>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	e38080e7          	jalr	-456(ra) # 80000530 <panic>
    release(&ftable.lock);
    80004700:	00029517          	auipc	a0,0x29
    80004704:	ca050513          	addi	a0,a0,-864 # 8002d3a0 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	582080e7          	jalr	1410(ra) # 80000c8a <release>
  }
}
    80004710:	70e2                	ld	ra,56(sp)
    80004712:	7442                	ld	s0,48(sp)
    80004714:	74a2                	ld	s1,40(sp)
    80004716:	7902                	ld	s2,32(sp)
    80004718:	69e2                	ld	s3,24(sp)
    8000471a:	6a42                	ld	s4,16(sp)
    8000471c:	6aa2                	ld	s5,8(sp)
    8000471e:	6121                	addi	sp,sp,64
    80004720:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004722:	85d6                	mv	a1,s5
    80004724:	8552                	mv	a0,s4
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	34c080e7          	jalr	844(ra) # 80004a72 <pipeclose>
    8000472e:	b7cd                	j	80004710 <fileclose+0xa8>

0000000080004730 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004730:	715d                	addi	sp,sp,-80
    80004732:	e486                	sd	ra,72(sp)
    80004734:	e0a2                	sd	s0,64(sp)
    80004736:	fc26                	sd	s1,56(sp)
    80004738:	f84a                	sd	s2,48(sp)
    8000473a:	f44e                	sd	s3,40(sp)
    8000473c:	0880                	addi	s0,sp,80
    8000473e:	84aa                	mv	s1,a0
    80004740:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004742:	ffffd097          	auipc	ra,0xffffd
    80004746:	392080e7          	jalr	914(ra) # 80001ad4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000474a:	409c                	lw	a5,0(s1)
    8000474c:	37f9                	addiw	a5,a5,-2
    8000474e:	4705                	li	a4,1
    80004750:	04f76763          	bltu	a4,a5,8000479e <filestat+0x6e>
    80004754:	892a                	mv	s2,a0
    ilock(f->ip);
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	06a080e7          	jalr	106(ra) # 800037c2 <ilock>
    stati(f->ip, &st);
    80004760:	fb840593          	addi	a1,s0,-72
    80004764:	6c88                	ld	a0,24(s1)
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	2e6080e7          	jalr	742(ra) # 80003a4c <stati>
    iunlock(f->ip);
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	114080e7          	jalr	276(ra) # 80003884 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004778:	46e1                	li	a3,24
    8000477a:	fb840613          	addi	a2,s0,-72
    8000477e:	85ce                	mv	a1,s3
    80004780:	05093503          	ld	a0,80(s2)
    80004784:	ffffd097          	auipc	ra,0xffffd
    80004788:	fe6080e7          	jalr	-26(ra) # 8000176a <copyout>
    8000478c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004790:	60a6                	ld	ra,72(sp)
    80004792:	6406                	ld	s0,64(sp)
    80004794:	74e2                	ld	s1,56(sp)
    80004796:	7942                	ld	s2,48(sp)
    80004798:	79a2                	ld	s3,40(sp)
    8000479a:	6161                	addi	sp,sp,80
    8000479c:	8082                	ret
  return -1;
    8000479e:	557d                	li	a0,-1
    800047a0:	bfc5                	j	80004790 <filestat+0x60>

00000000800047a2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047a2:	7179                	addi	sp,sp,-48
    800047a4:	f406                	sd	ra,40(sp)
    800047a6:	f022                	sd	s0,32(sp)
    800047a8:	ec26                	sd	s1,24(sp)
    800047aa:	e84a                	sd	s2,16(sp)
    800047ac:	e44e                	sd	s3,8(sp)
    800047ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047b0:	00854783          	lbu	a5,8(a0)
    800047b4:	c3d5                	beqz	a5,80004858 <fileread+0xb6>
    800047b6:	84aa                	mv	s1,a0
    800047b8:	89ae                	mv	s3,a1
    800047ba:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047bc:	411c                	lw	a5,0(a0)
    800047be:	4705                	li	a4,1
    800047c0:	04e78963          	beq	a5,a4,80004812 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c4:	470d                	li	a4,3
    800047c6:	04e78d63          	beq	a5,a4,80004820 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ca:	4709                	li	a4,2
    800047cc:	06e79e63          	bne	a5,a4,80004848 <fileread+0xa6>
    ilock(f->ip);
    800047d0:	6d08                	ld	a0,24(a0)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	ff0080e7          	jalr	-16(ra) # 800037c2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047da:	874a                	mv	a4,s2
    800047dc:	5094                	lw	a3,32(s1)
    800047de:	864e                	mv	a2,s3
    800047e0:	4585                	li	a1,1
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	292080e7          	jalr	658(ra) # 80003a76 <readi>
    800047ec:	892a                	mv	s2,a0
    800047ee:	00a05563          	blez	a0,800047f8 <fileread+0x56>
      f->off += r;
    800047f2:	509c                	lw	a5,32(s1)
    800047f4:	9fa9                	addw	a5,a5,a0
    800047f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047f8:	6c88                	ld	a0,24(s1)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	08a080e7          	jalr	138(ra) # 80003884 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004802:	854a                	mv	a0,s2
    80004804:	70a2                	ld	ra,40(sp)
    80004806:	7402                	ld	s0,32(sp)
    80004808:	64e2                	ld	s1,24(sp)
    8000480a:	6942                	ld	s2,16(sp)
    8000480c:	69a2                	ld	s3,8(sp)
    8000480e:	6145                	addi	sp,sp,48
    80004810:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004812:	6908                	ld	a0,16(a0)
    80004814:	00000097          	auipc	ra,0x0
    80004818:	3c8080e7          	jalr	968(ra) # 80004bdc <piperead>
    8000481c:	892a                	mv	s2,a0
    8000481e:	b7d5                	j	80004802 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004820:	02451783          	lh	a5,36(a0)
    80004824:	03079693          	slli	a3,a5,0x30
    80004828:	92c1                	srli	a3,a3,0x30
    8000482a:	4725                	li	a4,9
    8000482c:	02d76863          	bltu	a4,a3,8000485c <fileread+0xba>
    80004830:	0792                	slli	a5,a5,0x4
    80004832:	00029717          	auipc	a4,0x29
    80004836:	ace70713          	addi	a4,a4,-1330 # 8002d300 <devsw>
    8000483a:	97ba                	add	a5,a5,a4
    8000483c:	639c                	ld	a5,0(a5)
    8000483e:	c38d                	beqz	a5,80004860 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004840:	4505                	li	a0,1
    80004842:	9782                	jalr	a5
    80004844:	892a                	mv	s2,a0
    80004846:	bf75                	j	80004802 <fileread+0x60>
    panic("fileread");
    80004848:	00004517          	auipc	a0,0x4
    8000484c:	e5850513          	addi	a0,a0,-424 # 800086a0 <syscalls+0x268>
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	ce0080e7          	jalr	-800(ra) # 80000530 <panic>
    return -1;
    80004858:	597d                	li	s2,-1
    8000485a:	b765                	j	80004802 <fileread+0x60>
      return -1;
    8000485c:	597d                	li	s2,-1
    8000485e:	b755                	j	80004802 <fileread+0x60>
    80004860:	597d                	li	s2,-1
    80004862:	b745                	j	80004802 <fileread+0x60>

0000000080004864 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004864:	715d                	addi	sp,sp,-80
    80004866:	e486                	sd	ra,72(sp)
    80004868:	e0a2                	sd	s0,64(sp)
    8000486a:	fc26                	sd	s1,56(sp)
    8000486c:	f84a                	sd	s2,48(sp)
    8000486e:	f44e                	sd	s3,40(sp)
    80004870:	f052                	sd	s4,32(sp)
    80004872:	ec56                	sd	s5,24(sp)
    80004874:	e85a                	sd	s6,16(sp)
    80004876:	e45e                	sd	s7,8(sp)
    80004878:	e062                	sd	s8,0(sp)
    8000487a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000487c:	00954783          	lbu	a5,9(a0)
    80004880:	10078663          	beqz	a5,8000498c <filewrite+0x128>
    80004884:	892a                	mv	s2,a0
    80004886:	8aae                	mv	s5,a1
    80004888:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000488a:	411c                	lw	a5,0(a0)
    8000488c:	4705                	li	a4,1
    8000488e:	02e78263          	beq	a5,a4,800048b2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004892:	470d                	li	a4,3
    80004894:	02e78663          	beq	a5,a4,800048c0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004898:	4709                	li	a4,2
    8000489a:	0ee79163          	bne	a5,a4,8000497c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000489e:	0ac05d63          	blez	a2,80004958 <filewrite+0xf4>
    int i = 0;
    800048a2:	4981                	li	s3,0
    800048a4:	6b05                	lui	s6,0x1
    800048a6:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048aa:	6b85                	lui	s7,0x1
    800048ac:	c00b8b9b          	addiw	s7,s7,-1024
    800048b0:	a861                	j	80004948 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048b2:	6908                	ld	a0,16(a0)
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	22e080e7          	jalr	558(ra) # 80004ae2 <pipewrite>
    800048bc:	8a2a                	mv	s4,a0
    800048be:	a045                	j	8000495e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048c0:	02451783          	lh	a5,36(a0)
    800048c4:	03079693          	slli	a3,a5,0x30
    800048c8:	92c1                	srli	a3,a3,0x30
    800048ca:	4725                	li	a4,9
    800048cc:	0cd76263          	bltu	a4,a3,80004990 <filewrite+0x12c>
    800048d0:	0792                	slli	a5,a5,0x4
    800048d2:	00029717          	auipc	a4,0x29
    800048d6:	a2e70713          	addi	a4,a4,-1490 # 8002d300 <devsw>
    800048da:	97ba                	add	a5,a5,a4
    800048dc:	679c                	ld	a5,8(a5)
    800048de:	cbdd                	beqz	a5,80004994 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048e0:	4505                	li	a0,1
    800048e2:	9782                	jalr	a5
    800048e4:	8a2a                	mv	s4,a0
    800048e6:	a8a5                	j	8000495e <filewrite+0xfa>
    800048e8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ec:	00000097          	auipc	ra,0x0
    800048f0:	8a8080e7          	jalr	-1880(ra) # 80004194 <begin_op>
      ilock(f->ip);
    800048f4:	01893503          	ld	a0,24(s2)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	eca080e7          	jalr	-310(ra) # 800037c2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004900:	8762                	mv	a4,s8
    80004902:	02092683          	lw	a3,32(s2)
    80004906:	01598633          	add	a2,s3,s5
    8000490a:	4585                	li	a1,1
    8000490c:	01893503          	ld	a0,24(s2)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	25e080e7          	jalr	606(ra) # 80003b6e <writei>
    80004918:	84aa                	mv	s1,a0
    8000491a:	00a05763          	blez	a0,80004928 <filewrite+0xc4>
        f->off += r;
    8000491e:	02092783          	lw	a5,32(s2)
    80004922:	9fa9                	addw	a5,a5,a0
    80004924:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004928:	01893503          	ld	a0,24(s2)
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	f58080e7          	jalr	-168(ra) # 80003884 <iunlock>
      end_op();
    80004934:	00000097          	auipc	ra,0x0
    80004938:	8e0080e7          	jalr	-1824(ra) # 80004214 <end_op>

      if(r != n1){
    8000493c:	009c1f63          	bne	s8,s1,8000495a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004940:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004944:	0149db63          	bge	s3,s4,8000495a <filewrite+0xf6>
      int n1 = n - i;
    80004948:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000494c:	84be                	mv	s1,a5
    8000494e:	2781                	sext.w	a5,a5
    80004950:	f8fb5ce3          	bge	s6,a5,800048e8 <filewrite+0x84>
    80004954:	84de                	mv	s1,s7
    80004956:	bf49                	j	800048e8 <filewrite+0x84>
    int i = 0;
    80004958:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000495a:	013a1f63          	bne	s4,s3,80004978 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000495e:	8552                	mv	a0,s4
    80004960:	60a6                	ld	ra,72(sp)
    80004962:	6406                	ld	s0,64(sp)
    80004964:	74e2                	ld	s1,56(sp)
    80004966:	7942                	ld	s2,48(sp)
    80004968:	79a2                	ld	s3,40(sp)
    8000496a:	7a02                	ld	s4,32(sp)
    8000496c:	6ae2                	ld	s5,24(sp)
    8000496e:	6b42                	ld	s6,16(sp)
    80004970:	6ba2                	ld	s7,8(sp)
    80004972:	6c02                	ld	s8,0(sp)
    80004974:	6161                	addi	sp,sp,80
    80004976:	8082                	ret
    ret = (i == n ? n : -1);
    80004978:	5a7d                	li	s4,-1
    8000497a:	b7d5                	j	8000495e <filewrite+0xfa>
    panic("filewrite");
    8000497c:	00004517          	auipc	a0,0x4
    80004980:	d3450513          	addi	a0,a0,-716 # 800086b0 <syscalls+0x278>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	bac080e7          	jalr	-1108(ra) # 80000530 <panic>
    return -1;
    8000498c:	5a7d                	li	s4,-1
    8000498e:	bfc1                	j	8000495e <filewrite+0xfa>
      return -1;
    80004990:	5a7d                	li	s4,-1
    80004992:	b7f1                	j	8000495e <filewrite+0xfa>
    80004994:	5a7d                	li	s4,-1
    80004996:	b7e1                	j	8000495e <filewrite+0xfa>

0000000080004998 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004998:	7179                	addi	sp,sp,-48
    8000499a:	f406                	sd	ra,40(sp)
    8000499c:	f022                	sd	s0,32(sp)
    8000499e:	ec26                	sd	s1,24(sp)
    800049a0:	e84a                	sd	s2,16(sp)
    800049a2:	e44e                	sd	s3,8(sp)
    800049a4:	e052                	sd	s4,0(sp)
    800049a6:	1800                	addi	s0,sp,48
    800049a8:	84aa                	mv	s1,a0
    800049aa:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049ac:	0005b023          	sd	zero,0(a1)
    800049b0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	bf8080e7          	jalr	-1032(ra) # 800045ac <filealloc>
    800049bc:	e088                	sd	a0,0(s1)
    800049be:	c551                	beqz	a0,80004a4a <pipealloc+0xb2>
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	bec080e7          	jalr	-1044(ra) # 800045ac <filealloc>
    800049c8:	00aa3023          	sd	a0,0(s4)
    800049cc:	c92d                	beqz	a0,80004a3e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	118080e7          	jalr	280(ra) # 80000ae6 <kalloc>
    800049d6:	892a                	mv	s2,a0
    800049d8:	c125                	beqz	a0,80004a38 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049da:	4985                	li	s3,1
    800049dc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049e0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049e4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049e8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ec:	00004597          	auipc	a1,0x4
    800049f0:	cd458593          	addi	a1,a1,-812 # 800086c0 <syscalls+0x288>
    800049f4:	ffffc097          	auipc	ra,0xffffc
    800049f8:	152080e7          	jalr	338(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049fc:	609c                	ld	a5,0(s1)
    800049fe:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a02:	609c                	ld	a5,0(s1)
    80004a04:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a08:	609c                	ld	a5,0(s1)
    80004a0a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a0e:	609c                	ld	a5,0(s1)
    80004a10:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a14:	000a3783          	ld	a5,0(s4)
    80004a18:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a1c:	000a3783          	ld	a5,0(s4)
    80004a20:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a24:	000a3783          	ld	a5,0(s4)
    80004a28:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a2c:	000a3783          	ld	a5,0(s4)
    80004a30:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a34:	4501                	li	a0,0
    80004a36:	a025                	j	80004a5e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a38:	6088                	ld	a0,0(s1)
    80004a3a:	e501                	bnez	a0,80004a42 <pipealloc+0xaa>
    80004a3c:	a039                	j	80004a4a <pipealloc+0xb2>
    80004a3e:	6088                	ld	a0,0(s1)
    80004a40:	c51d                	beqz	a0,80004a6e <pipealloc+0xd6>
    fileclose(*f0);
    80004a42:	00000097          	auipc	ra,0x0
    80004a46:	c26080e7          	jalr	-986(ra) # 80004668 <fileclose>
  if(*f1)
    80004a4a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a4e:	557d                	li	a0,-1
  if(*f1)
    80004a50:	c799                	beqz	a5,80004a5e <pipealloc+0xc6>
    fileclose(*f1);
    80004a52:	853e                	mv	a0,a5
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	c14080e7          	jalr	-1004(ra) # 80004668 <fileclose>
  return -1;
    80004a5c:	557d                	li	a0,-1
}
    80004a5e:	70a2                	ld	ra,40(sp)
    80004a60:	7402                	ld	s0,32(sp)
    80004a62:	64e2                	ld	s1,24(sp)
    80004a64:	6942                	ld	s2,16(sp)
    80004a66:	69a2                	ld	s3,8(sp)
    80004a68:	6a02                	ld	s4,0(sp)
    80004a6a:	6145                	addi	sp,sp,48
    80004a6c:	8082                	ret
  return -1;
    80004a6e:	557d                	li	a0,-1
    80004a70:	b7fd                	j	80004a5e <pipealloc+0xc6>

0000000080004a72 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a72:	1101                	addi	sp,sp,-32
    80004a74:	ec06                	sd	ra,24(sp)
    80004a76:	e822                	sd	s0,16(sp)
    80004a78:	e426                	sd	s1,8(sp)
    80004a7a:	e04a                	sd	s2,0(sp)
    80004a7c:	1000                	addi	s0,sp,32
    80004a7e:	84aa                	mv	s1,a0
    80004a80:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a82:	ffffc097          	auipc	ra,0xffffc
    80004a86:	154080e7          	jalr	340(ra) # 80000bd6 <acquire>
  if(writable){
    80004a8a:	02090d63          	beqz	s2,80004ac4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a8e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a92:	21848513          	addi	a0,s1,536
    80004a96:	ffffe097          	auipc	ra,0xffffe
    80004a9a:	a6e080e7          	jalr	-1426(ra) # 80002504 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a9e:	2204b783          	ld	a5,544(s1)
    80004aa2:	eb95                	bnez	a5,80004ad6 <pipeclose+0x64>
    release(&pi->lock);
    80004aa4:	8526                	mv	a0,s1
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	1e4080e7          	jalr	484(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	ffffc097          	auipc	ra,0xffffc
    80004ab4:	f3a080e7          	jalr	-198(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004ab8:	60e2                	ld	ra,24(sp)
    80004aba:	6442                	ld	s0,16(sp)
    80004abc:	64a2                	ld	s1,8(sp)
    80004abe:	6902                	ld	s2,0(sp)
    80004ac0:	6105                	addi	sp,sp,32
    80004ac2:	8082                	ret
    pi->readopen = 0;
    80004ac4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ac8:	21c48513          	addi	a0,s1,540
    80004acc:	ffffe097          	auipc	ra,0xffffe
    80004ad0:	a38080e7          	jalr	-1480(ra) # 80002504 <wakeup>
    80004ad4:	b7e9                	j	80004a9e <pipeclose+0x2c>
    release(&pi->lock);
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	1b2080e7          	jalr	434(ra) # 80000c8a <release>
}
    80004ae0:	bfe1                	j	80004ab8 <pipeclose+0x46>

0000000080004ae2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ae2:	7159                	addi	sp,sp,-112
    80004ae4:	f486                	sd	ra,104(sp)
    80004ae6:	f0a2                	sd	s0,96(sp)
    80004ae8:	eca6                	sd	s1,88(sp)
    80004aea:	e8ca                	sd	s2,80(sp)
    80004aec:	e4ce                	sd	s3,72(sp)
    80004aee:	e0d2                	sd	s4,64(sp)
    80004af0:	fc56                	sd	s5,56(sp)
    80004af2:	f85a                	sd	s6,48(sp)
    80004af4:	f45e                	sd	s7,40(sp)
    80004af6:	f062                	sd	s8,32(sp)
    80004af8:	ec66                	sd	s9,24(sp)
    80004afa:	1880                	addi	s0,sp,112
    80004afc:	84aa                	mv	s1,a0
    80004afe:	8aae                	mv	s5,a1
    80004b00:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b02:	ffffd097          	auipc	ra,0xffffd
    80004b06:	fd2080e7          	jalr	-46(ra) # 80001ad4 <myproc>
    80004b0a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	0c8080e7          	jalr	200(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b16:	0d405163          	blez	s4,80004bd8 <pipewrite+0xf6>
    80004b1a:	8ba6                	mv	s7,s1
  int i = 0;
    80004b1c:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b1e:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b20:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b24:	21c48c13          	addi	s8,s1,540
    80004b28:	a08d                	j	80004b8a <pipewrite+0xa8>
      release(&pi->lock);
    80004b2a:	8526                	mv	a0,s1
    80004b2c:	ffffc097          	auipc	ra,0xffffc
    80004b30:	15e080e7          	jalr	350(ra) # 80000c8a <release>
      return -1;
    80004b34:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b36:	854a                	mv	a0,s2
    80004b38:	70a6                	ld	ra,104(sp)
    80004b3a:	7406                	ld	s0,96(sp)
    80004b3c:	64e6                	ld	s1,88(sp)
    80004b3e:	6946                	ld	s2,80(sp)
    80004b40:	69a6                	ld	s3,72(sp)
    80004b42:	6a06                	ld	s4,64(sp)
    80004b44:	7ae2                	ld	s5,56(sp)
    80004b46:	7b42                	ld	s6,48(sp)
    80004b48:	7ba2                	ld	s7,40(sp)
    80004b4a:	7c02                	ld	s8,32(sp)
    80004b4c:	6ce2                	ld	s9,24(sp)
    80004b4e:	6165                	addi	sp,sp,112
    80004b50:	8082                	ret
      wakeup(&pi->nread);
    80004b52:	8566                	mv	a0,s9
    80004b54:	ffffe097          	auipc	ra,0xffffe
    80004b58:	9b0080e7          	jalr	-1616(ra) # 80002504 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b5c:	85de                	mv	a1,s7
    80004b5e:	8562                	mv	a0,s8
    80004b60:	ffffe097          	auipc	ra,0xffffe
    80004b64:	81e080e7          	jalr	-2018(ra) # 8000237e <sleep>
    80004b68:	a839                	j	80004b86 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b6a:	21c4a783          	lw	a5,540(s1)
    80004b6e:	0017871b          	addiw	a4,a5,1
    80004b72:	20e4ae23          	sw	a4,540(s1)
    80004b76:	1ff7f793          	andi	a5,a5,511
    80004b7a:	97a6                	add	a5,a5,s1
    80004b7c:	f9f44703          	lbu	a4,-97(s0)
    80004b80:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b84:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b86:	03495d63          	bge	s2,s4,80004bc0 <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b8a:	2204a783          	lw	a5,544(s1)
    80004b8e:	dfd1                	beqz	a5,80004b2a <pipewrite+0x48>
    80004b90:	0309a783          	lw	a5,48(s3)
    80004b94:	fbd9                	bnez	a5,80004b2a <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b96:	2184a783          	lw	a5,536(s1)
    80004b9a:	21c4a703          	lw	a4,540(s1)
    80004b9e:	2007879b          	addiw	a5,a5,512
    80004ba2:	faf708e3          	beq	a4,a5,80004b52 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba6:	4685                	li	a3,1
    80004ba8:	01590633          	add	a2,s2,s5
    80004bac:	f9f40593          	addi	a1,s0,-97
    80004bb0:	0509b503          	ld	a0,80(s3)
    80004bb4:	ffffd097          	auipc	ra,0xffffd
    80004bb8:	c42080e7          	jalr	-958(ra) # 800017f6 <copyin>
    80004bbc:	fb6517e3          	bne	a0,s6,80004b6a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004bc0:	21848513          	addi	a0,s1,536
    80004bc4:	ffffe097          	auipc	ra,0xffffe
    80004bc8:	940080e7          	jalr	-1728(ra) # 80002504 <wakeup>
  release(&pi->lock);
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	0bc080e7          	jalr	188(ra) # 80000c8a <release>
  return i;
    80004bd6:	b785                	j	80004b36 <pipewrite+0x54>
  int i = 0;
    80004bd8:	4901                	li	s2,0
    80004bda:	b7dd                	j	80004bc0 <pipewrite+0xde>

0000000080004bdc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bdc:	715d                	addi	sp,sp,-80
    80004bde:	e486                	sd	ra,72(sp)
    80004be0:	e0a2                	sd	s0,64(sp)
    80004be2:	fc26                	sd	s1,56(sp)
    80004be4:	f84a                	sd	s2,48(sp)
    80004be6:	f44e                	sd	s3,40(sp)
    80004be8:	f052                	sd	s4,32(sp)
    80004bea:	ec56                	sd	s5,24(sp)
    80004bec:	e85a                	sd	s6,16(sp)
    80004bee:	0880                	addi	s0,sp,80
    80004bf0:	84aa                	mv	s1,a0
    80004bf2:	892e                	mv	s2,a1
    80004bf4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	ede080e7          	jalr	-290(ra) # 80001ad4 <myproc>
    80004bfe:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c00:	8b26                	mv	s6,s1
    80004c02:	8526                	mv	a0,s1
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	fd2080e7          	jalr	-46(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c0c:	2184a703          	lw	a4,536(s1)
    80004c10:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c14:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c18:	02f71463          	bne	a4,a5,80004c40 <piperead+0x64>
    80004c1c:	2244a783          	lw	a5,548(s1)
    80004c20:	c385                	beqz	a5,80004c40 <piperead+0x64>
    if(pr->killed){
    80004c22:	030a2783          	lw	a5,48(s4)
    80004c26:	ebc1                	bnez	a5,80004cb6 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c28:	85da                	mv	a1,s6
    80004c2a:	854e                	mv	a0,s3
    80004c2c:	ffffd097          	auipc	ra,0xffffd
    80004c30:	752080e7          	jalr	1874(ra) # 8000237e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c34:	2184a703          	lw	a4,536(s1)
    80004c38:	21c4a783          	lw	a5,540(s1)
    80004c3c:	fef700e3          	beq	a4,a5,80004c1c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c40:	09505263          	blez	s5,80004cc4 <piperead+0xe8>
    80004c44:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c46:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c48:	2184a783          	lw	a5,536(s1)
    80004c4c:	21c4a703          	lw	a4,540(s1)
    80004c50:	02f70d63          	beq	a4,a5,80004c8a <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c54:	0017871b          	addiw	a4,a5,1
    80004c58:	20e4ac23          	sw	a4,536(s1)
    80004c5c:	1ff7f793          	andi	a5,a5,511
    80004c60:	97a6                	add	a5,a5,s1
    80004c62:	0187c783          	lbu	a5,24(a5)
    80004c66:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c6a:	4685                	li	a3,1
    80004c6c:	fbf40613          	addi	a2,s0,-65
    80004c70:	85ca                	mv	a1,s2
    80004c72:	050a3503          	ld	a0,80(s4)
    80004c76:	ffffd097          	auipc	ra,0xffffd
    80004c7a:	af4080e7          	jalr	-1292(ra) # 8000176a <copyout>
    80004c7e:	01650663          	beq	a0,s6,80004c8a <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c82:	2985                	addiw	s3,s3,1
    80004c84:	0905                	addi	s2,s2,1
    80004c86:	fd3a91e3          	bne	s5,s3,80004c48 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c8a:	21c48513          	addi	a0,s1,540
    80004c8e:	ffffe097          	auipc	ra,0xffffe
    80004c92:	876080e7          	jalr	-1930(ra) # 80002504 <wakeup>
  release(&pi->lock);
    80004c96:	8526                	mv	a0,s1
    80004c98:	ffffc097          	auipc	ra,0xffffc
    80004c9c:	ff2080e7          	jalr	-14(ra) # 80000c8a <release>
  return i;
}
    80004ca0:	854e                	mv	a0,s3
    80004ca2:	60a6                	ld	ra,72(sp)
    80004ca4:	6406                	ld	s0,64(sp)
    80004ca6:	74e2                	ld	s1,56(sp)
    80004ca8:	7942                	ld	s2,48(sp)
    80004caa:	79a2                	ld	s3,40(sp)
    80004cac:	7a02                	ld	s4,32(sp)
    80004cae:	6ae2                	ld	s5,24(sp)
    80004cb0:	6b42                	ld	s6,16(sp)
    80004cb2:	6161                	addi	sp,sp,80
    80004cb4:	8082                	ret
      release(&pi->lock);
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	fd2080e7          	jalr	-46(ra) # 80000c8a <release>
      return -1;
    80004cc0:	59fd                	li	s3,-1
    80004cc2:	bff9                	j	80004ca0 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cc4:	4981                	li	s3,0
    80004cc6:	b7d1                	j	80004c8a <piperead+0xae>

0000000080004cc8 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cc8:	df010113          	addi	sp,sp,-528
    80004ccc:	20113423          	sd	ra,520(sp)
    80004cd0:	20813023          	sd	s0,512(sp)
    80004cd4:	ffa6                	sd	s1,504(sp)
    80004cd6:	fbca                	sd	s2,496(sp)
    80004cd8:	f7ce                	sd	s3,488(sp)
    80004cda:	f3d2                	sd	s4,480(sp)
    80004cdc:	efd6                	sd	s5,472(sp)
    80004cde:	ebda                	sd	s6,464(sp)
    80004ce0:	e7de                	sd	s7,456(sp)
    80004ce2:	e3e2                	sd	s8,448(sp)
    80004ce4:	ff66                	sd	s9,440(sp)
    80004ce6:	fb6a                	sd	s10,432(sp)
    80004ce8:	f76e                	sd	s11,424(sp)
    80004cea:	0c00                	addi	s0,sp,528
    80004cec:	84aa                	mv	s1,a0
    80004cee:	dea43c23          	sd	a0,-520(s0)
    80004cf2:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cf6:	ffffd097          	auipc	ra,0xffffd
    80004cfa:	dde080e7          	jalr	-546(ra) # 80001ad4 <myproc>
    80004cfe:	892a                	mv	s2,a0

  begin_op();
    80004d00:	fffff097          	auipc	ra,0xfffff
    80004d04:	494080e7          	jalr	1172(ra) # 80004194 <begin_op>

  if((ip = namei(path)) == 0){
    80004d08:	8526                	mv	a0,s1
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	26e080e7          	jalr	622(ra) # 80003f78 <namei>
    80004d12:	c92d                	beqz	a0,80004d84 <exec+0xbc>
    80004d14:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	aac080e7          	jalr	-1364(ra) # 800037c2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d1e:	04000713          	li	a4,64
    80004d22:	4681                	li	a3,0
    80004d24:	e4840613          	addi	a2,s0,-440
    80004d28:	4581                	li	a1,0
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	d4a080e7          	jalr	-694(ra) # 80003a76 <readi>
    80004d34:	04000793          	li	a5,64
    80004d38:	00f51a63          	bne	a0,a5,80004d4c <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d3c:	e4842703          	lw	a4,-440(s0)
    80004d40:	464c47b7          	lui	a5,0x464c4
    80004d44:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d48:	04f70463          	beq	a4,a5,80004d90 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d4c:	8526                	mv	a0,s1
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	cd6080e7          	jalr	-810(ra) # 80003a24 <iunlockput>
    end_op();
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	4be080e7          	jalr	1214(ra) # 80004214 <end_op>
  }
  return -1;
    80004d5e:	557d                	li	a0,-1
}
    80004d60:	20813083          	ld	ra,520(sp)
    80004d64:	20013403          	ld	s0,512(sp)
    80004d68:	74fe                	ld	s1,504(sp)
    80004d6a:	795e                	ld	s2,496(sp)
    80004d6c:	79be                	ld	s3,488(sp)
    80004d6e:	7a1e                	ld	s4,480(sp)
    80004d70:	6afe                	ld	s5,472(sp)
    80004d72:	6b5e                	ld	s6,464(sp)
    80004d74:	6bbe                	ld	s7,456(sp)
    80004d76:	6c1e                	ld	s8,448(sp)
    80004d78:	7cfa                	ld	s9,440(sp)
    80004d7a:	7d5a                	ld	s10,432(sp)
    80004d7c:	7dba                	ld	s11,424(sp)
    80004d7e:	21010113          	addi	sp,sp,528
    80004d82:	8082                	ret
    end_op();
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	490080e7          	jalr	1168(ra) # 80004214 <end_op>
    return -1;
    80004d8c:	557d                	li	a0,-1
    80004d8e:	bfc9                	j	80004d60 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d90:	854a                	mv	a0,s2
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	e06080e7          	jalr	-506(ra) # 80001b98 <proc_pagetable>
    80004d9a:	8baa                	mv	s7,a0
    80004d9c:	d945                	beqz	a0,80004d4c <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9e:	e6842983          	lw	s3,-408(s0)
    80004da2:	e8045783          	lhu	a5,-384(s0)
    80004da6:	c7ad                	beqz	a5,80004e10 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004da8:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004daa:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004dac:	6c85                	lui	s9,0x1
    80004dae:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004db2:	def43823          	sd	a5,-528(s0)
    80004db6:	a42d                	j	80004fe0 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004db8:	00004517          	auipc	a0,0x4
    80004dbc:	91050513          	addi	a0,a0,-1776 # 800086c8 <syscalls+0x290>
    80004dc0:	ffffb097          	auipc	ra,0xffffb
    80004dc4:	770080e7          	jalr	1904(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dc8:	8756                	mv	a4,s5
    80004dca:	012d86bb          	addw	a3,s11,s2
    80004dce:	4581                	li	a1,0
    80004dd0:	8526                	mv	a0,s1
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	ca4080e7          	jalr	-860(ra) # 80003a76 <readi>
    80004dda:	2501                	sext.w	a0,a0
    80004ddc:	1aaa9963          	bne	s5,a0,80004f8e <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004de0:	6785                	lui	a5,0x1
    80004de2:	0127893b          	addw	s2,a5,s2
    80004de6:	77fd                	lui	a5,0xfffff
    80004de8:	01478a3b          	addw	s4,a5,s4
    80004dec:	1f897163          	bgeu	s2,s8,80004fce <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004df0:	02091593          	slli	a1,s2,0x20
    80004df4:	9181                	srli	a1,a1,0x20
    80004df6:	95ea                	add	a1,a1,s10
    80004df8:	855e                	mv	a0,s7
    80004dfa:	ffffc097          	auipc	ra,0xffffc
    80004dfe:	37e080e7          	jalr	894(ra) # 80001178 <walkaddr>
    80004e02:	862a                	mv	a2,a0
    if(pa == 0)
    80004e04:	d955                	beqz	a0,80004db8 <exec+0xf0>
      n = PGSIZE;
    80004e06:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e08:	fd9a70e3          	bgeu	s4,s9,80004dc8 <exec+0x100>
      n = sz - i;
    80004e0c:	8ad2                	mv	s5,s4
    80004e0e:	bf6d                	j	80004dc8 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e10:	4901                	li	s2,0
  iunlockput(ip);
    80004e12:	8526                	mv	a0,s1
    80004e14:	fffff097          	auipc	ra,0xfffff
    80004e18:	c10080e7          	jalr	-1008(ra) # 80003a24 <iunlockput>
  end_op();
    80004e1c:	fffff097          	auipc	ra,0xfffff
    80004e20:	3f8080e7          	jalr	1016(ra) # 80004214 <end_op>
  p = myproc();
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	cb0080e7          	jalr	-848(ra) # 80001ad4 <myproc>
    80004e2c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e2e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e32:	6785                	lui	a5,0x1
    80004e34:	17fd                	addi	a5,a5,-1
    80004e36:	993e                	add	s2,s2,a5
    80004e38:	757d                	lui	a0,0xfffff
    80004e3a:	00a977b3          	and	a5,s2,a0
    80004e3e:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e42:	6609                	lui	a2,0x2
    80004e44:	963e                	add	a2,a2,a5
    80004e46:	85be                	mv	a1,a5
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	6d0080e7          	jalr	1744(ra) # 8000151a <uvmalloc>
    80004e52:	8b2a                	mv	s6,a0
  ip = 0;
    80004e54:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e56:	12050c63          	beqz	a0,80004f8e <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e5a:	75f9                	lui	a1,0xffffe
    80004e5c:	95aa                	add	a1,a1,a0
    80004e5e:	855e                	mv	a0,s7
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	8d8080e7          	jalr	-1832(ra) # 80001738 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e68:	7c7d                	lui	s8,0xfffff
    80004e6a:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6c:	e0043783          	ld	a5,-512(s0)
    80004e70:	6388                	ld	a0,0(a5)
    80004e72:	c535                	beqz	a0,80004ede <exec+0x216>
    80004e74:	e8840993          	addi	s3,s0,-376
    80004e78:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e7c:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	fdc080e7          	jalr	-36(ra) # 80000e5a <strlen>
    80004e86:	2505                	addiw	a0,a0,1
    80004e88:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e90:	13896363          	bltu	s2,s8,80004fb6 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e94:	e0043d83          	ld	s11,-512(s0)
    80004e98:	000dba03          	ld	s4,0(s11)
    80004e9c:	8552                	mv	a0,s4
    80004e9e:	ffffc097          	auipc	ra,0xffffc
    80004ea2:	fbc080e7          	jalr	-68(ra) # 80000e5a <strlen>
    80004ea6:	0015069b          	addiw	a3,a0,1
    80004eaa:	8652                	mv	a2,s4
    80004eac:	85ca                	mv	a1,s2
    80004eae:	855e                	mv	a0,s7
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	8ba080e7          	jalr	-1862(ra) # 8000176a <copyout>
    80004eb8:	10054363          	bltz	a0,80004fbe <exec+0x2f6>
    ustack[argc] = sp;
    80004ebc:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec0:	0485                	addi	s1,s1,1
    80004ec2:	008d8793          	addi	a5,s11,8
    80004ec6:	e0f43023          	sd	a5,-512(s0)
    80004eca:	008db503          	ld	a0,8(s11)
    80004ece:	c911                	beqz	a0,80004ee2 <exec+0x21a>
    if(argc >= MAXARG)
    80004ed0:	09a1                	addi	s3,s3,8
    80004ed2:	fb3c96e3          	bne	s9,s3,80004e7e <exec+0x1b6>
  sz = sz1;
    80004ed6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eda:	4481                	li	s1,0
    80004edc:	a84d                	j	80004f8e <exec+0x2c6>
  sp = sz;
    80004ede:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee0:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee2:	00349793          	slli	a5,s1,0x3
    80004ee6:	f9040713          	addi	a4,s0,-112
    80004eea:	97ba                	add	a5,a5,a4
    80004eec:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ef0:	00148693          	addi	a3,s1,1
    80004ef4:	068e                	slli	a3,a3,0x3
    80004ef6:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004efa:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004efe:	01897663          	bgeu	s2,s8,80004f0a <exec+0x242>
  sz = sz1;
    80004f02:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f06:	4481                	li	s1,0
    80004f08:	a059                	j	80004f8e <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f0a:	e8840613          	addi	a2,s0,-376
    80004f0e:	85ca                	mv	a1,s2
    80004f10:	855e                	mv	a0,s7
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	858080e7          	jalr	-1960(ra) # 8000176a <copyout>
    80004f1a:	0a054663          	bltz	a0,80004fc6 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f1e:	058ab783          	ld	a5,88(s5)
    80004f22:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f26:	df843783          	ld	a5,-520(s0)
    80004f2a:	0007c703          	lbu	a4,0(a5)
    80004f2e:	cf11                	beqz	a4,80004f4a <exec+0x282>
    80004f30:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f32:	02f00693          	li	a3,47
    80004f36:	a029                	j	80004f40 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f38:	0785                	addi	a5,a5,1
    80004f3a:	fff7c703          	lbu	a4,-1(a5)
    80004f3e:	c711                	beqz	a4,80004f4a <exec+0x282>
    if(*s == '/')
    80004f40:	fed71ce3          	bne	a4,a3,80004f38 <exec+0x270>
      last = s+1;
    80004f44:	def43c23          	sd	a5,-520(s0)
    80004f48:	bfc5                	j	80004f38 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f4a:	4641                	li	a2,16
    80004f4c:	df843583          	ld	a1,-520(s0)
    80004f50:	158a8513          	addi	a0,s5,344
    80004f54:	ffffc097          	auipc	ra,0xffffc
    80004f58:	ed4080e7          	jalr	-300(ra) # 80000e28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5c:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f60:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f64:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f68:	058ab783          	ld	a5,88(s5)
    80004f6c:	e6043703          	ld	a4,-416(s0)
    80004f70:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f7a:	85ea                	mv	a1,s10
    80004f7c:	ffffd097          	auipc	ra,0xffffd
    80004f80:	cb8080e7          	jalr	-840(ra) # 80001c34 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f84:	0004851b          	sext.w	a0,s1
    80004f88:	bbe1                	j	80004d60 <exec+0x98>
    80004f8a:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f8e:	e0843583          	ld	a1,-504(s0)
    80004f92:	855e                	mv	a0,s7
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	ca0080e7          	jalr	-864(ra) # 80001c34 <proc_freepagetable>
  if(ip){
    80004f9c:	da0498e3          	bnez	s1,80004d4c <exec+0x84>
  return -1;
    80004fa0:	557d                	li	a0,-1
    80004fa2:	bb7d                	j	80004d60 <exec+0x98>
    80004fa4:	e1243423          	sd	s2,-504(s0)
    80004fa8:	b7dd                	j	80004f8e <exec+0x2c6>
    80004faa:	e1243423          	sd	s2,-504(s0)
    80004fae:	b7c5                	j	80004f8e <exec+0x2c6>
    80004fb0:	e1243423          	sd	s2,-504(s0)
    80004fb4:	bfe9                	j	80004f8e <exec+0x2c6>
  sz = sz1;
    80004fb6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fba:	4481                	li	s1,0
    80004fbc:	bfc9                	j	80004f8e <exec+0x2c6>
  sz = sz1;
    80004fbe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fc2:	4481                	li	s1,0
    80004fc4:	b7e9                	j	80004f8e <exec+0x2c6>
  sz = sz1;
    80004fc6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fca:	4481                	li	s1,0
    80004fcc:	b7c9                	j	80004f8e <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fce:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd2:	2b05                	addiw	s6,s6,1
    80004fd4:	0389899b          	addiw	s3,s3,56
    80004fd8:	e8045783          	lhu	a5,-384(s0)
    80004fdc:	e2fb5be3          	bge	s6,a5,80004e12 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fe0:	2981                	sext.w	s3,s3
    80004fe2:	03800713          	li	a4,56
    80004fe6:	86ce                	mv	a3,s3
    80004fe8:	e1040613          	addi	a2,s0,-496
    80004fec:	4581                	li	a1,0
    80004fee:	8526                	mv	a0,s1
    80004ff0:	fffff097          	auipc	ra,0xfffff
    80004ff4:	a86080e7          	jalr	-1402(ra) # 80003a76 <readi>
    80004ff8:	03800793          	li	a5,56
    80004ffc:	f8f517e3          	bne	a0,a5,80004f8a <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005000:	e1042783          	lw	a5,-496(s0)
    80005004:	4705                	li	a4,1
    80005006:	fce796e3          	bne	a5,a4,80004fd2 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    8000500a:	e3843603          	ld	a2,-456(s0)
    8000500e:	e3043783          	ld	a5,-464(s0)
    80005012:	f8f669e3          	bltu	a2,a5,80004fa4 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005016:	e2043783          	ld	a5,-480(s0)
    8000501a:	963e                	add	a2,a2,a5
    8000501c:	f8f667e3          	bltu	a2,a5,80004faa <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005020:	85ca                	mv	a1,s2
    80005022:	855e                	mv	a0,s7
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	4f6080e7          	jalr	1270(ra) # 8000151a <uvmalloc>
    8000502c:	e0a43423          	sd	a0,-504(s0)
    80005030:	d141                	beqz	a0,80004fb0 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005032:	e2043d03          	ld	s10,-480(s0)
    80005036:	df043783          	ld	a5,-528(s0)
    8000503a:	00fd77b3          	and	a5,s10,a5
    8000503e:	fba1                	bnez	a5,80004f8e <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005040:	e1842d83          	lw	s11,-488(s0)
    80005044:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005048:	f80c03e3          	beqz	s8,80004fce <exec+0x306>
    8000504c:	8a62                	mv	s4,s8
    8000504e:	4901                	li	s2,0
    80005050:	b345                	j	80004df0 <exec+0x128>

0000000080005052 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005052:	7179                	addi	sp,sp,-48
    80005054:	f406                	sd	ra,40(sp)
    80005056:	f022                	sd	s0,32(sp)
    80005058:	ec26                	sd	s1,24(sp)
    8000505a:	e84a                	sd	s2,16(sp)
    8000505c:	1800                	addi	s0,sp,48
    8000505e:	892e                	mv	s2,a1
    80005060:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005062:	fdc40593          	addi	a1,s0,-36
    80005066:	ffffe097          	auipc	ra,0xffffe
    8000506a:	bea080e7          	jalr	-1046(ra) # 80002c50 <argint>
    8000506e:	04054063          	bltz	a0,800050ae <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005072:	fdc42703          	lw	a4,-36(s0)
    80005076:	47bd                	li	a5,15
    80005078:	02e7ed63          	bltu	a5,a4,800050b2 <argfd+0x60>
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	a58080e7          	jalr	-1448(ra) # 80001ad4 <myproc>
    80005084:	fdc42703          	lw	a4,-36(s0)
    80005088:	01a70793          	addi	a5,a4,26
    8000508c:	078e                	slli	a5,a5,0x3
    8000508e:	953e                	add	a0,a0,a5
    80005090:	611c                	ld	a5,0(a0)
    80005092:	c395                	beqz	a5,800050b6 <argfd+0x64>
    return -1;
  if(pfd)
    80005094:	00090463          	beqz	s2,8000509c <argfd+0x4a>
    *pfd = fd;
    80005098:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000509c:	4501                	li	a0,0
  if(pf)
    8000509e:	c091                	beqz	s1,800050a2 <argfd+0x50>
    *pf = f;
    800050a0:	e09c                	sd	a5,0(s1)
}
    800050a2:	70a2                	ld	ra,40(sp)
    800050a4:	7402                	ld	s0,32(sp)
    800050a6:	64e2                	ld	s1,24(sp)
    800050a8:	6942                	ld	s2,16(sp)
    800050aa:	6145                	addi	sp,sp,48
    800050ac:	8082                	ret
    return -1;
    800050ae:	557d                	li	a0,-1
    800050b0:	bfcd                	j	800050a2 <argfd+0x50>
    return -1;
    800050b2:	557d                	li	a0,-1
    800050b4:	b7fd                	j	800050a2 <argfd+0x50>
    800050b6:	557d                	li	a0,-1
    800050b8:	b7ed                	j	800050a2 <argfd+0x50>

00000000800050ba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050ba:	1101                	addi	sp,sp,-32
    800050bc:	ec06                	sd	ra,24(sp)
    800050be:	e822                	sd	s0,16(sp)
    800050c0:	e426                	sd	s1,8(sp)
    800050c2:	1000                	addi	s0,sp,32
    800050c4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	a0e080e7          	jalr	-1522(ra) # 80001ad4 <myproc>
    800050ce:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050d0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffcd0d0>
    800050d4:	4501                	li	a0,0
    800050d6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050d8:	6398                	ld	a4,0(a5)
    800050da:	cb19                	beqz	a4,800050f0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050dc:	2505                	addiw	a0,a0,1
    800050de:	07a1                	addi	a5,a5,8
    800050e0:	fed51ce3          	bne	a0,a3,800050d8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050e4:	557d                	li	a0,-1
}
    800050e6:	60e2                	ld	ra,24(sp)
    800050e8:	6442                	ld	s0,16(sp)
    800050ea:	64a2                	ld	s1,8(sp)
    800050ec:	6105                	addi	sp,sp,32
    800050ee:	8082                	ret
      p->ofile[fd] = f;
    800050f0:	01a50793          	addi	a5,a0,26
    800050f4:	078e                	slli	a5,a5,0x3
    800050f6:	963e                	add	a2,a2,a5
    800050f8:	e204                	sd	s1,0(a2)
      return fd;
    800050fa:	b7f5                	j	800050e6 <fdalloc+0x2c>

00000000800050fc <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050fc:	715d                	addi	sp,sp,-80
    800050fe:	e486                	sd	ra,72(sp)
    80005100:	e0a2                	sd	s0,64(sp)
    80005102:	fc26                	sd	s1,56(sp)
    80005104:	f84a                	sd	s2,48(sp)
    80005106:	f44e                	sd	s3,40(sp)
    80005108:	f052                	sd	s4,32(sp)
    8000510a:	ec56                	sd	s5,24(sp)
    8000510c:	0880                	addi	s0,sp,80
    8000510e:	89ae                	mv	s3,a1
    80005110:	8ab2                	mv	s5,a2
    80005112:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005114:	fb040593          	addi	a1,s0,-80
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	e7e080e7          	jalr	-386(ra) # 80003f96 <nameiparent>
    80005120:	892a                	mv	s2,a0
    80005122:	12050f63          	beqz	a0,80005260 <create+0x164>
    return 0;

  ilock(dp);
    80005126:	ffffe097          	auipc	ra,0xffffe
    8000512a:	69c080e7          	jalr	1692(ra) # 800037c2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000512e:	4601                	li	a2,0
    80005130:	fb040593          	addi	a1,s0,-80
    80005134:	854a                	mv	a0,s2
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	b70080e7          	jalr	-1168(ra) # 80003ca6 <dirlookup>
    8000513e:	84aa                	mv	s1,a0
    80005140:	c921                	beqz	a0,80005190 <create+0x94>
    iunlockput(dp);
    80005142:	854a                	mv	a0,s2
    80005144:	fffff097          	auipc	ra,0xfffff
    80005148:	8e0080e7          	jalr	-1824(ra) # 80003a24 <iunlockput>
    ilock(ip);
    8000514c:	8526                	mv	a0,s1
    8000514e:	ffffe097          	auipc	ra,0xffffe
    80005152:	674080e7          	jalr	1652(ra) # 800037c2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005156:	2981                	sext.w	s3,s3
    80005158:	4789                	li	a5,2
    8000515a:	02f99463          	bne	s3,a5,80005182 <create+0x86>
    8000515e:	0444d783          	lhu	a5,68(s1)
    80005162:	37f9                	addiw	a5,a5,-2
    80005164:	17c2                	slli	a5,a5,0x30
    80005166:	93c1                	srli	a5,a5,0x30
    80005168:	4705                	li	a4,1
    8000516a:	00f76c63          	bltu	a4,a5,80005182 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000516e:	8526                	mv	a0,s1
    80005170:	60a6                	ld	ra,72(sp)
    80005172:	6406                	ld	s0,64(sp)
    80005174:	74e2                	ld	s1,56(sp)
    80005176:	7942                	ld	s2,48(sp)
    80005178:	79a2                	ld	s3,40(sp)
    8000517a:	7a02                	ld	s4,32(sp)
    8000517c:	6ae2                	ld	s5,24(sp)
    8000517e:	6161                	addi	sp,sp,80
    80005180:	8082                	ret
    iunlockput(ip);
    80005182:	8526                	mv	a0,s1
    80005184:	fffff097          	auipc	ra,0xfffff
    80005188:	8a0080e7          	jalr	-1888(ra) # 80003a24 <iunlockput>
    return 0;
    8000518c:	4481                	li	s1,0
    8000518e:	b7c5                	j	8000516e <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005190:	85ce                	mv	a1,s3
    80005192:	00092503          	lw	a0,0(s2)
    80005196:	ffffe097          	auipc	ra,0xffffe
    8000519a:	494080e7          	jalr	1172(ra) # 8000362a <ialloc>
    8000519e:	84aa                	mv	s1,a0
    800051a0:	c529                	beqz	a0,800051ea <create+0xee>
  ilock(ip);
    800051a2:	ffffe097          	auipc	ra,0xffffe
    800051a6:	620080e7          	jalr	1568(ra) # 800037c2 <ilock>
  ip->major = major;
    800051aa:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051ae:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051b2:	4785                	li	a5,1
    800051b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051b8:	8526                	mv	a0,s1
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	53e080e7          	jalr	1342(ra) # 800036f8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051c2:	2981                	sext.w	s3,s3
    800051c4:	4785                	li	a5,1
    800051c6:	02f98a63          	beq	s3,a5,800051fa <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ca:	40d0                	lw	a2,4(s1)
    800051cc:	fb040593          	addi	a1,s0,-80
    800051d0:	854a                	mv	a0,s2
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	ce4080e7          	jalr	-796(ra) # 80003eb6 <dirlink>
    800051da:	06054b63          	bltz	a0,80005250 <create+0x154>
  iunlockput(dp);
    800051de:	854a                	mv	a0,s2
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	844080e7          	jalr	-1980(ra) # 80003a24 <iunlockput>
  return ip;
    800051e8:	b759                	j	8000516e <create+0x72>
    panic("create: ialloc");
    800051ea:	00003517          	auipc	a0,0x3
    800051ee:	4fe50513          	addi	a0,a0,1278 # 800086e8 <syscalls+0x2b0>
    800051f2:	ffffb097          	auipc	ra,0xffffb
    800051f6:	33e080e7          	jalr	830(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    800051fa:	04a95783          	lhu	a5,74(s2)
    800051fe:	2785                	addiw	a5,a5,1
    80005200:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005204:	854a                	mv	a0,s2
    80005206:	ffffe097          	auipc	ra,0xffffe
    8000520a:	4f2080e7          	jalr	1266(ra) # 800036f8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000520e:	40d0                	lw	a2,4(s1)
    80005210:	00003597          	auipc	a1,0x3
    80005214:	4e858593          	addi	a1,a1,1256 # 800086f8 <syscalls+0x2c0>
    80005218:	8526                	mv	a0,s1
    8000521a:	fffff097          	auipc	ra,0xfffff
    8000521e:	c9c080e7          	jalr	-868(ra) # 80003eb6 <dirlink>
    80005222:	00054f63          	bltz	a0,80005240 <create+0x144>
    80005226:	00492603          	lw	a2,4(s2)
    8000522a:	00003597          	auipc	a1,0x3
    8000522e:	4d658593          	addi	a1,a1,1238 # 80008700 <syscalls+0x2c8>
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c82080e7          	jalr	-894(ra) # 80003eb6 <dirlink>
    8000523c:	f80557e3          	bgez	a0,800051ca <create+0xce>
      panic("create dots");
    80005240:	00003517          	auipc	a0,0x3
    80005244:	4c850513          	addi	a0,a0,1224 # 80008708 <syscalls+0x2d0>
    80005248:	ffffb097          	auipc	ra,0xffffb
    8000524c:	2e8080e7          	jalr	744(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005250:	00003517          	auipc	a0,0x3
    80005254:	4c850513          	addi	a0,a0,1224 # 80008718 <syscalls+0x2e0>
    80005258:	ffffb097          	auipc	ra,0xffffb
    8000525c:	2d8080e7          	jalr	728(ra) # 80000530 <panic>
    return 0;
    80005260:	84aa                	mv	s1,a0
    80005262:	b731                	j	8000516e <create+0x72>

0000000080005264 <sys_dup>:
{
    80005264:	7179                	addi	sp,sp,-48
    80005266:	f406                	sd	ra,40(sp)
    80005268:	f022                	sd	s0,32(sp)
    8000526a:	ec26                	sd	s1,24(sp)
    8000526c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000526e:	fd840613          	addi	a2,s0,-40
    80005272:	4581                	li	a1,0
    80005274:	4501                	li	a0,0
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	ddc080e7          	jalr	-548(ra) # 80005052 <argfd>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005280:	02054363          	bltz	a0,800052a6 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005284:	fd843503          	ld	a0,-40(s0)
    80005288:	00000097          	auipc	ra,0x0
    8000528c:	e32080e7          	jalr	-462(ra) # 800050ba <fdalloc>
    80005290:	84aa                	mv	s1,a0
    return -1;
    80005292:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005294:	00054963          	bltz	a0,800052a6 <sys_dup+0x42>
  filedup(f);
    80005298:	fd843503          	ld	a0,-40(s0)
    8000529c:	fffff097          	auipc	ra,0xfffff
    800052a0:	37a080e7          	jalr	890(ra) # 80004616 <filedup>
  return fd;
    800052a4:	87a6                	mv	a5,s1
}
    800052a6:	853e                	mv	a0,a5
    800052a8:	70a2                	ld	ra,40(sp)
    800052aa:	7402                	ld	s0,32(sp)
    800052ac:	64e2                	ld	s1,24(sp)
    800052ae:	6145                	addi	sp,sp,48
    800052b0:	8082                	ret

00000000800052b2 <sys_read>:
{
    800052b2:	7179                	addi	sp,sp,-48
    800052b4:	f406                	sd	ra,40(sp)
    800052b6:	f022                	sd	s0,32(sp)
    800052b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ba:	fe840613          	addi	a2,s0,-24
    800052be:	4581                	li	a1,0
    800052c0:	4501                	li	a0,0
    800052c2:	00000097          	auipc	ra,0x0
    800052c6:	d90080e7          	jalr	-624(ra) # 80005052 <argfd>
    return -1;
    800052ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052cc:	04054163          	bltz	a0,8000530e <sys_read+0x5c>
    800052d0:	fe440593          	addi	a1,s0,-28
    800052d4:	4509                	li	a0,2
    800052d6:	ffffe097          	auipc	ra,0xffffe
    800052da:	97a080e7          	jalr	-1670(ra) # 80002c50 <argint>
    return -1;
    800052de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e0:	02054763          	bltz	a0,8000530e <sys_read+0x5c>
    800052e4:	fd840593          	addi	a1,s0,-40
    800052e8:	4505                	li	a0,1
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	988080e7          	jalr	-1656(ra) # 80002c72 <argaddr>
    return -1;
    800052f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f4:	00054d63          	bltz	a0,8000530e <sys_read+0x5c>
  return fileread(f, p, n);
    800052f8:	fe442603          	lw	a2,-28(s0)
    800052fc:	fd843583          	ld	a1,-40(s0)
    80005300:	fe843503          	ld	a0,-24(s0)
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	49e080e7          	jalr	1182(ra) # 800047a2 <fileread>
    8000530c:	87aa                	mv	a5,a0
}
    8000530e:	853e                	mv	a0,a5
    80005310:	70a2                	ld	ra,40(sp)
    80005312:	7402                	ld	s0,32(sp)
    80005314:	6145                	addi	sp,sp,48
    80005316:	8082                	ret

0000000080005318 <sys_write>:
{
    80005318:	7179                	addi	sp,sp,-48
    8000531a:	f406                	sd	ra,40(sp)
    8000531c:	f022                	sd	s0,32(sp)
    8000531e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005320:	fe840613          	addi	a2,s0,-24
    80005324:	4581                	li	a1,0
    80005326:	4501                	li	a0,0
    80005328:	00000097          	auipc	ra,0x0
    8000532c:	d2a080e7          	jalr	-726(ra) # 80005052 <argfd>
    return -1;
    80005330:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005332:	04054163          	bltz	a0,80005374 <sys_write+0x5c>
    80005336:	fe440593          	addi	a1,s0,-28
    8000533a:	4509                	li	a0,2
    8000533c:	ffffe097          	auipc	ra,0xffffe
    80005340:	914080e7          	jalr	-1772(ra) # 80002c50 <argint>
    return -1;
    80005344:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005346:	02054763          	bltz	a0,80005374 <sys_write+0x5c>
    8000534a:	fd840593          	addi	a1,s0,-40
    8000534e:	4505                	li	a0,1
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	922080e7          	jalr	-1758(ra) # 80002c72 <argaddr>
    return -1;
    80005358:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000535a:	00054d63          	bltz	a0,80005374 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000535e:	fe442603          	lw	a2,-28(s0)
    80005362:	fd843583          	ld	a1,-40(s0)
    80005366:	fe843503          	ld	a0,-24(s0)
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	4fa080e7          	jalr	1274(ra) # 80004864 <filewrite>
    80005372:	87aa                	mv	a5,a0
}
    80005374:	853e                	mv	a0,a5
    80005376:	70a2                	ld	ra,40(sp)
    80005378:	7402                	ld	s0,32(sp)
    8000537a:	6145                	addi	sp,sp,48
    8000537c:	8082                	ret

000000008000537e <sys_close>:
{
    8000537e:	1101                	addi	sp,sp,-32
    80005380:	ec06                	sd	ra,24(sp)
    80005382:	e822                	sd	s0,16(sp)
    80005384:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005386:	fe040613          	addi	a2,s0,-32
    8000538a:	fec40593          	addi	a1,s0,-20
    8000538e:	4501                	li	a0,0
    80005390:	00000097          	auipc	ra,0x0
    80005394:	cc2080e7          	jalr	-830(ra) # 80005052 <argfd>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000539a:	02054463          	bltz	a0,800053c2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000539e:	ffffc097          	auipc	ra,0xffffc
    800053a2:	736080e7          	jalr	1846(ra) # 80001ad4 <myproc>
    800053a6:	fec42783          	lw	a5,-20(s0)
    800053aa:	07e9                	addi	a5,a5,26
    800053ac:	078e                	slli	a5,a5,0x3
    800053ae:	97aa                	add	a5,a5,a0
    800053b0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053b4:	fe043503          	ld	a0,-32(s0)
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	2b0080e7          	jalr	688(ra) # 80004668 <fileclose>
  return 0;
    800053c0:	4781                	li	a5,0
}
    800053c2:	853e                	mv	a0,a5
    800053c4:	60e2                	ld	ra,24(sp)
    800053c6:	6442                	ld	s0,16(sp)
    800053c8:	6105                	addi	sp,sp,32
    800053ca:	8082                	ret

00000000800053cc <sys_fstat>:
{
    800053cc:	1101                	addi	sp,sp,-32
    800053ce:	ec06                	sd	ra,24(sp)
    800053d0:	e822                	sd	s0,16(sp)
    800053d2:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d4:	fe840613          	addi	a2,s0,-24
    800053d8:	4581                	li	a1,0
    800053da:	4501                	li	a0,0
    800053dc:	00000097          	auipc	ra,0x0
    800053e0:	c76080e7          	jalr	-906(ra) # 80005052 <argfd>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e6:	02054563          	bltz	a0,80005410 <sys_fstat+0x44>
    800053ea:	fe040593          	addi	a1,s0,-32
    800053ee:	4505                	li	a0,1
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	882080e7          	jalr	-1918(ra) # 80002c72 <argaddr>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053fa:	00054b63          	bltz	a0,80005410 <sys_fstat+0x44>
  return filestat(f, st);
    800053fe:	fe043583          	ld	a1,-32(s0)
    80005402:	fe843503          	ld	a0,-24(s0)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	32a080e7          	jalr	810(ra) # 80004730 <filestat>
    8000540e:	87aa                	mv	a5,a0
}
    80005410:	853e                	mv	a0,a5
    80005412:	60e2                	ld	ra,24(sp)
    80005414:	6442                	ld	s0,16(sp)
    80005416:	6105                	addi	sp,sp,32
    80005418:	8082                	ret

000000008000541a <sys_link>:
{
    8000541a:	7169                	addi	sp,sp,-304
    8000541c:	f606                	sd	ra,296(sp)
    8000541e:	f222                	sd	s0,288(sp)
    80005420:	ee26                	sd	s1,280(sp)
    80005422:	ea4a                	sd	s2,272(sp)
    80005424:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005426:	08000613          	li	a2,128
    8000542a:	ed040593          	addi	a1,s0,-304
    8000542e:	4501                	li	a0,0
    80005430:	ffffe097          	auipc	ra,0xffffe
    80005434:	864080e7          	jalr	-1948(ra) # 80002c94 <argstr>
    return -1;
    80005438:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543a:	10054e63          	bltz	a0,80005556 <sys_link+0x13c>
    8000543e:	08000613          	li	a2,128
    80005442:	f5040593          	addi	a1,s0,-176
    80005446:	4505                	li	a0,1
    80005448:	ffffe097          	auipc	ra,0xffffe
    8000544c:	84c080e7          	jalr	-1972(ra) # 80002c94 <argstr>
    return -1;
    80005450:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005452:	10054263          	bltz	a0,80005556 <sys_link+0x13c>
  begin_op();
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	d3e080e7          	jalr	-706(ra) # 80004194 <begin_op>
  if((ip = namei(old)) == 0){
    8000545e:	ed040513          	addi	a0,s0,-304
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	b16080e7          	jalr	-1258(ra) # 80003f78 <namei>
    8000546a:	84aa                	mv	s1,a0
    8000546c:	c551                	beqz	a0,800054f8 <sys_link+0xde>
  ilock(ip);
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	354080e7          	jalr	852(ra) # 800037c2 <ilock>
  if(ip->type == T_DIR){
    80005476:	04449703          	lh	a4,68(s1)
    8000547a:	4785                	li	a5,1
    8000547c:	08f70463          	beq	a4,a5,80005504 <sys_link+0xea>
  ip->nlink++;
    80005480:	04a4d783          	lhu	a5,74(s1)
    80005484:	2785                	addiw	a5,a5,1
    80005486:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	26c080e7          	jalr	620(ra) # 800036f8 <iupdate>
  iunlock(ip);
    80005494:	8526                	mv	a0,s1
    80005496:	ffffe097          	auipc	ra,0xffffe
    8000549a:	3ee080e7          	jalr	1006(ra) # 80003884 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000549e:	fd040593          	addi	a1,s0,-48
    800054a2:	f5040513          	addi	a0,s0,-176
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	af0080e7          	jalr	-1296(ra) # 80003f96 <nameiparent>
    800054ae:	892a                	mv	s2,a0
    800054b0:	c935                	beqz	a0,80005524 <sys_link+0x10a>
  ilock(dp);
    800054b2:	ffffe097          	auipc	ra,0xffffe
    800054b6:	310080e7          	jalr	784(ra) # 800037c2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ba:	00092703          	lw	a4,0(s2)
    800054be:	409c                	lw	a5,0(s1)
    800054c0:	04f71d63          	bne	a4,a5,8000551a <sys_link+0x100>
    800054c4:	40d0                	lw	a2,4(s1)
    800054c6:	fd040593          	addi	a1,s0,-48
    800054ca:	854a                	mv	a0,s2
    800054cc:	fffff097          	auipc	ra,0xfffff
    800054d0:	9ea080e7          	jalr	-1558(ra) # 80003eb6 <dirlink>
    800054d4:	04054363          	bltz	a0,8000551a <sys_link+0x100>
  iunlockput(dp);
    800054d8:	854a                	mv	a0,s2
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	54a080e7          	jalr	1354(ra) # 80003a24 <iunlockput>
  iput(ip);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	498080e7          	jalr	1176(ra) # 8000397c <iput>
  end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	d28080e7          	jalr	-728(ra) # 80004214 <end_op>
  return 0;
    800054f4:	4781                	li	a5,0
    800054f6:	a085                	j	80005556 <sys_link+0x13c>
    end_op();
    800054f8:	fffff097          	auipc	ra,0xfffff
    800054fc:	d1c080e7          	jalr	-740(ra) # 80004214 <end_op>
    return -1;
    80005500:	57fd                	li	a5,-1
    80005502:	a891                	j	80005556 <sys_link+0x13c>
    iunlockput(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	51e080e7          	jalr	1310(ra) # 80003a24 <iunlockput>
    end_op();
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	d06080e7          	jalr	-762(ra) # 80004214 <end_op>
    return -1;
    80005516:	57fd                	li	a5,-1
    80005518:	a83d                	j	80005556 <sys_link+0x13c>
    iunlockput(dp);
    8000551a:	854a                	mv	a0,s2
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	508080e7          	jalr	1288(ra) # 80003a24 <iunlockput>
  ilock(ip);
    80005524:	8526                	mv	a0,s1
    80005526:	ffffe097          	auipc	ra,0xffffe
    8000552a:	29c080e7          	jalr	668(ra) # 800037c2 <ilock>
  ip->nlink--;
    8000552e:	04a4d783          	lhu	a5,74(s1)
    80005532:	37fd                	addiw	a5,a5,-1
    80005534:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	1be080e7          	jalr	446(ra) # 800036f8 <iupdate>
  iunlockput(ip);
    80005542:	8526                	mv	a0,s1
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	4e0080e7          	jalr	1248(ra) # 80003a24 <iunlockput>
  end_op();
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	cc8080e7          	jalr	-824(ra) # 80004214 <end_op>
  return -1;
    80005554:	57fd                	li	a5,-1
}
    80005556:	853e                	mv	a0,a5
    80005558:	70b2                	ld	ra,296(sp)
    8000555a:	7412                	ld	s0,288(sp)
    8000555c:	64f2                	ld	s1,280(sp)
    8000555e:	6952                	ld	s2,272(sp)
    80005560:	6155                	addi	sp,sp,304
    80005562:	8082                	ret

0000000080005564 <sys_unlink>:
{
    80005564:	7151                	addi	sp,sp,-240
    80005566:	f586                	sd	ra,232(sp)
    80005568:	f1a2                	sd	s0,224(sp)
    8000556a:	eda6                	sd	s1,216(sp)
    8000556c:	e9ca                	sd	s2,208(sp)
    8000556e:	e5ce                	sd	s3,200(sp)
    80005570:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005572:	08000613          	li	a2,128
    80005576:	f3040593          	addi	a1,s0,-208
    8000557a:	4501                	li	a0,0
    8000557c:	ffffd097          	auipc	ra,0xffffd
    80005580:	718080e7          	jalr	1816(ra) # 80002c94 <argstr>
    80005584:	18054163          	bltz	a0,80005706 <sys_unlink+0x1a2>
  begin_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	c0c080e7          	jalr	-1012(ra) # 80004194 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005590:	fb040593          	addi	a1,s0,-80
    80005594:	f3040513          	addi	a0,s0,-208
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	9fe080e7          	jalr	-1538(ra) # 80003f96 <nameiparent>
    800055a0:	84aa                	mv	s1,a0
    800055a2:	c979                	beqz	a0,80005678 <sys_unlink+0x114>
  ilock(dp);
    800055a4:	ffffe097          	auipc	ra,0xffffe
    800055a8:	21e080e7          	jalr	542(ra) # 800037c2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ac:	00003597          	auipc	a1,0x3
    800055b0:	14c58593          	addi	a1,a1,332 # 800086f8 <syscalls+0x2c0>
    800055b4:	fb040513          	addi	a0,s0,-80
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	6d4080e7          	jalr	1748(ra) # 80003c8c <namecmp>
    800055c0:	14050a63          	beqz	a0,80005714 <sys_unlink+0x1b0>
    800055c4:	00003597          	auipc	a1,0x3
    800055c8:	13c58593          	addi	a1,a1,316 # 80008700 <syscalls+0x2c8>
    800055cc:	fb040513          	addi	a0,s0,-80
    800055d0:	ffffe097          	auipc	ra,0xffffe
    800055d4:	6bc080e7          	jalr	1724(ra) # 80003c8c <namecmp>
    800055d8:	12050e63          	beqz	a0,80005714 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055dc:	f2c40613          	addi	a2,s0,-212
    800055e0:	fb040593          	addi	a1,s0,-80
    800055e4:	8526                	mv	a0,s1
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	6c0080e7          	jalr	1728(ra) # 80003ca6 <dirlookup>
    800055ee:	892a                	mv	s2,a0
    800055f0:	12050263          	beqz	a0,80005714 <sys_unlink+0x1b0>
  ilock(ip);
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	1ce080e7          	jalr	462(ra) # 800037c2 <ilock>
  if(ip->nlink < 1)
    800055fc:	04a91783          	lh	a5,74(s2)
    80005600:	08f05263          	blez	a5,80005684 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005604:	04491703          	lh	a4,68(s2)
    80005608:	4785                	li	a5,1
    8000560a:	08f70563          	beq	a4,a5,80005694 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000560e:	4641                	li	a2,16
    80005610:	4581                	li	a1,0
    80005612:	fc040513          	addi	a0,s0,-64
    80005616:	ffffb097          	auipc	ra,0xffffb
    8000561a:	6bc080e7          	jalr	1724(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000561e:	4741                	li	a4,16
    80005620:	f2c42683          	lw	a3,-212(s0)
    80005624:	fc040613          	addi	a2,s0,-64
    80005628:	4581                	li	a1,0
    8000562a:	8526                	mv	a0,s1
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	542080e7          	jalr	1346(ra) # 80003b6e <writei>
    80005634:	47c1                	li	a5,16
    80005636:	0af51563          	bne	a0,a5,800056e0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000563a:	04491703          	lh	a4,68(s2)
    8000563e:	4785                	li	a5,1
    80005640:	0af70863          	beq	a4,a5,800056f0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	3de080e7          	jalr	990(ra) # 80003a24 <iunlockput>
  ip->nlink--;
    8000564e:	04a95783          	lhu	a5,74(s2)
    80005652:	37fd                	addiw	a5,a5,-1
    80005654:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005658:	854a                	mv	a0,s2
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	09e080e7          	jalr	158(ra) # 800036f8 <iupdate>
  iunlockput(ip);
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	3c0080e7          	jalr	960(ra) # 80003a24 <iunlockput>
  end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	ba8080e7          	jalr	-1112(ra) # 80004214 <end_op>
  return 0;
    80005674:	4501                	li	a0,0
    80005676:	a84d                	j	80005728 <sys_unlink+0x1c4>
    end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	b9c080e7          	jalr	-1124(ra) # 80004214 <end_op>
    return -1;
    80005680:	557d                	li	a0,-1
    80005682:	a05d                	j	80005728 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005684:	00003517          	auipc	a0,0x3
    80005688:	0a450513          	addi	a0,a0,164 # 80008728 <syscalls+0x2f0>
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	ea4080e7          	jalr	-348(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005694:	04c92703          	lw	a4,76(s2)
    80005698:	02000793          	li	a5,32
    8000569c:	f6e7f9e3          	bgeu	a5,a4,8000560e <sys_unlink+0xaa>
    800056a0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056a4:	4741                	li	a4,16
    800056a6:	86ce                	mv	a3,s3
    800056a8:	f1840613          	addi	a2,s0,-232
    800056ac:	4581                	li	a1,0
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	3c6080e7          	jalr	966(ra) # 80003a76 <readi>
    800056b8:	47c1                	li	a5,16
    800056ba:	00f51b63          	bne	a0,a5,800056d0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056be:	f1845783          	lhu	a5,-232(s0)
    800056c2:	e7a1                	bnez	a5,8000570a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056c4:	29c1                	addiw	s3,s3,16
    800056c6:	04c92783          	lw	a5,76(s2)
    800056ca:	fcf9ede3          	bltu	s3,a5,800056a4 <sys_unlink+0x140>
    800056ce:	b781                	j	8000560e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056d0:	00003517          	auipc	a0,0x3
    800056d4:	07050513          	addi	a0,a0,112 # 80008740 <syscalls+0x308>
    800056d8:	ffffb097          	auipc	ra,0xffffb
    800056dc:	e58080e7          	jalr	-424(ra) # 80000530 <panic>
    panic("unlink: writei");
    800056e0:	00003517          	auipc	a0,0x3
    800056e4:	07850513          	addi	a0,a0,120 # 80008758 <syscalls+0x320>
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	e48080e7          	jalr	-440(ra) # 80000530 <panic>
    dp->nlink--;
    800056f0:	04a4d783          	lhu	a5,74(s1)
    800056f4:	37fd                	addiw	a5,a5,-1
    800056f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	ffc080e7          	jalr	-4(ra) # 800036f8 <iupdate>
    80005704:	b781                	j	80005644 <sys_unlink+0xe0>
    return -1;
    80005706:	557d                	li	a0,-1
    80005708:	a005                	j	80005728 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000570a:	854a                	mv	a0,s2
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	318080e7          	jalr	792(ra) # 80003a24 <iunlockput>
  iunlockput(dp);
    80005714:	8526                	mv	a0,s1
    80005716:	ffffe097          	auipc	ra,0xffffe
    8000571a:	30e080e7          	jalr	782(ra) # 80003a24 <iunlockput>
  end_op();
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	af6080e7          	jalr	-1290(ra) # 80004214 <end_op>
  return -1;
    80005726:	557d                	li	a0,-1
}
    80005728:	70ae                	ld	ra,232(sp)
    8000572a:	740e                	ld	s0,224(sp)
    8000572c:	64ee                	ld	s1,216(sp)
    8000572e:	694e                	ld	s2,208(sp)
    80005730:	69ae                	ld	s3,200(sp)
    80005732:	616d                	addi	sp,sp,240
    80005734:	8082                	ret

0000000080005736 <sys_open>:

uint64
sys_open(void)
{
    80005736:	7131                	addi	sp,sp,-192
    80005738:	fd06                	sd	ra,184(sp)
    8000573a:	f922                	sd	s0,176(sp)
    8000573c:	f526                	sd	s1,168(sp)
    8000573e:	f14a                	sd	s2,160(sp)
    80005740:	ed4e                	sd	s3,152(sp)
    80005742:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005744:	08000613          	li	a2,128
    80005748:	f5040593          	addi	a1,s0,-176
    8000574c:	4501                	li	a0,0
    8000574e:	ffffd097          	auipc	ra,0xffffd
    80005752:	546080e7          	jalr	1350(ra) # 80002c94 <argstr>
    return -1;
    80005756:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005758:	0c054163          	bltz	a0,8000581a <sys_open+0xe4>
    8000575c:	f4c40593          	addi	a1,s0,-180
    80005760:	4505                	li	a0,1
    80005762:	ffffd097          	auipc	ra,0xffffd
    80005766:	4ee080e7          	jalr	1262(ra) # 80002c50 <argint>
    8000576a:	0a054863          	bltz	a0,8000581a <sys_open+0xe4>

  begin_op();
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	a26080e7          	jalr	-1498(ra) # 80004194 <begin_op>

  if(omode & O_CREATE){
    80005776:	f4c42783          	lw	a5,-180(s0)
    8000577a:	2007f793          	andi	a5,a5,512
    8000577e:	cbdd                	beqz	a5,80005834 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005780:	4681                	li	a3,0
    80005782:	4601                	li	a2,0
    80005784:	4589                	li	a1,2
    80005786:	f5040513          	addi	a0,s0,-176
    8000578a:	00000097          	auipc	ra,0x0
    8000578e:	972080e7          	jalr	-1678(ra) # 800050fc <create>
    80005792:	892a                	mv	s2,a0
    if(ip == 0){
    80005794:	c959                	beqz	a0,8000582a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005796:	04491703          	lh	a4,68(s2)
    8000579a:	478d                	li	a5,3
    8000579c:	00f71763          	bne	a4,a5,800057aa <sys_open+0x74>
    800057a0:	04695703          	lhu	a4,70(s2)
    800057a4:	47a5                	li	a5,9
    800057a6:	0ce7ec63          	bltu	a5,a4,8000587e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	e02080e7          	jalr	-510(ra) # 800045ac <filealloc>
    800057b2:	89aa                	mv	s3,a0
    800057b4:	10050263          	beqz	a0,800058b8 <sys_open+0x182>
    800057b8:	00000097          	auipc	ra,0x0
    800057bc:	902080e7          	jalr	-1790(ra) # 800050ba <fdalloc>
    800057c0:	84aa                	mv	s1,a0
    800057c2:	0e054663          	bltz	a0,800058ae <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057c6:	04491703          	lh	a4,68(s2)
    800057ca:	478d                	li	a5,3
    800057cc:	0cf70463          	beq	a4,a5,80005894 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057d0:	4789                	li	a5,2
    800057d2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057d6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057da:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057de:	f4c42783          	lw	a5,-180(s0)
    800057e2:	0017c713          	xori	a4,a5,1
    800057e6:	8b05                	andi	a4,a4,1
    800057e8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ec:	0037f713          	andi	a4,a5,3
    800057f0:	00e03733          	snez	a4,a4
    800057f4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057f8:	4007f793          	andi	a5,a5,1024
    800057fc:	c791                	beqz	a5,80005808 <sys_open+0xd2>
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	4789                	li	a5,2
    80005804:	08f70f63          	beq	a4,a5,800058a2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	07a080e7          	jalr	122(ra) # 80003884 <iunlock>
  end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	a02080e7          	jalr	-1534(ra) # 80004214 <end_op>

  return fd;
}
    8000581a:	8526                	mv	a0,s1
    8000581c:	70ea                	ld	ra,184(sp)
    8000581e:	744a                	ld	s0,176(sp)
    80005820:	74aa                	ld	s1,168(sp)
    80005822:	790a                	ld	s2,160(sp)
    80005824:	69ea                	ld	s3,152(sp)
    80005826:	6129                	addi	sp,sp,192
    80005828:	8082                	ret
      end_op();
    8000582a:	fffff097          	auipc	ra,0xfffff
    8000582e:	9ea080e7          	jalr	-1558(ra) # 80004214 <end_op>
      return -1;
    80005832:	b7e5                	j	8000581a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005834:	f5040513          	addi	a0,s0,-176
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	740080e7          	jalr	1856(ra) # 80003f78 <namei>
    80005840:	892a                	mv	s2,a0
    80005842:	c905                	beqz	a0,80005872 <sys_open+0x13c>
    ilock(ip);
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	f7e080e7          	jalr	-130(ra) # 800037c2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000584c:	04491703          	lh	a4,68(s2)
    80005850:	4785                	li	a5,1
    80005852:	f4f712e3          	bne	a4,a5,80005796 <sys_open+0x60>
    80005856:	f4c42783          	lw	a5,-180(s0)
    8000585a:	dba1                	beqz	a5,800057aa <sys_open+0x74>
      iunlockput(ip);
    8000585c:	854a                	mv	a0,s2
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	1c6080e7          	jalr	454(ra) # 80003a24 <iunlockput>
      end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	9ae080e7          	jalr	-1618(ra) # 80004214 <end_op>
      return -1;
    8000586e:	54fd                	li	s1,-1
    80005870:	b76d                	j	8000581a <sys_open+0xe4>
      end_op();
    80005872:	fffff097          	auipc	ra,0xfffff
    80005876:	9a2080e7          	jalr	-1630(ra) # 80004214 <end_op>
      return -1;
    8000587a:	54fd                	li	s1,-1
    8000587c:	bf79                	j	8000581a <sys_open+0xe4>
    iunlockput(ip);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	1a4080e7          	jalr	420(ra) # 80003a24 <iunlockput>
    end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	98c080e7          	jalr	-1652(ra) # 80004214 <end_op>
    return -1;
    80005890:	54fd                	li	s1,-1
    80005892:	b761                	j	8000581a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005894:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005898:	04691783          	lh	a5,70(s2)
    8000589c:	02f99223          	sh	a5,36(s3)
    800058a0:	bf2d                	j	800057da <sys_open+0xa4>
    itrunc(ip);
    800058a2:	854a                	mv	a0,s2
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	02c080e7          	jalr	44(ra) # 800038d0 <itrunc>
    800058ac:	bfb1                	j	80005808 <sys_open+0xd2>
      fileclose(f);
    800058ae:	854e                	mv	a0,s3
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	db8080e7          	jalr	-584(ra) # 80004668 <fileclose>
    iunlockput(ip);
    800058b8:	854a                	mv	a0,s2
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	16a080e7          	jalr	362(ra) # 80003a24 <iunlockput>
    end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	952080e7          	jalr	-1710(ra) # 80004214 <end_op>
    return -1;
    800058ca:	54fd                	li	s1,-1
    800058cc:	b7b9                	j	8000581a <sys_open+0xe4>

00000000800058ce <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058ce:	7175                	addi	sp,sp,-144
    800058d0:	e506                	sd	ra,136(sp)
    800058d2:	e122                	sd	s0,128(sp)
    800058d4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	8be080e7          	jalr	-1858(ra) # 80004194 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058de:	08000613          	li	a2,128
    800058e2:	f7040593          	addi	a1,s0,-144
    800058e6:	4501                	li	a0,0
    800058e8:	ffffd097          	auipc	ra,0xffffd
    800058ec:	3ac080e7          	jalr	940(ra) # 80002c94 <argstr>
    800058f0:	02054963          	bltz	a0,80005922 <sys_mkdir+0x54>
    800058f4:	4681                	li	a3,0
    800058f6:	4601                	li	a2,0
    800058f8:	4585                	li	a1,1
    800058fa:	f7040513          	addi	a0,s0,-144
    800058fe:	fffff097          	auipc	ra,0xfffff
    80005902:	7fe080e7          	jalr	2046(ra) # 800050fc <create>
    80005906:	cd11                	beqz	a0,80005922 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005908:	ffffe097          	auipc	ra,0xffffe
    8000590c:	11c080e7          	jalr	284(ra) # 80003a24 <iunlockput>
  end_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	904080e7          	jalr	-1788(ra) # 80004214 <end_op>
  return 0;
    80005918:	4501                	li	a0,0
}
    8000591a:	60aa                	ld	ra,136(sp)
    8000591c:	640a                	ld	s0,128(sp)
    8000591e:	6149                	addi	sp,sp,144
    80005920:	8082                	ret
    end_op();
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	8f2080e7          	jalr	-1806(ra) # 80004214 <end_op>
    return -1;
    8000592a:	557d                	li	a0,-1
    8000592c:	b7fd                	j	8000591a <sys_mkdir+0x4c>

000000008000592e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000592e:	7135                	addi	sp,sp,-160
    80005930:	ed06                	sd	ra,152(sp)
    80005932:	e922                	sd	s0,144(sp)
    80005934:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	85e080e7          	jalr	-1954(ra) # 80004194 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000593e:	08000613          	li	a2,128
    80005942:	f7040593          	addi	a1,s0,-144
    80005946:	4501                	li	a0,0
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	34c080e7          	jalr	844(ra) # 80002c94 <argstr>
    80005950:	04054a63          	bltz	a0,800059a4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005954:	f6c40593          	addi	a1,s0,-148
    80005958:	4505                	li	a0,1
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	2f6080e7          	jalr	758(ra) # 80002c50 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005962:	04054163          	bltz	a0,800059a4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005966:	f6840593          	addi	a1,s0,-152
    8000596a:	4509                	li	a0,2
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	2e4080e7          	jalr	740(ra) # 80002c50 <argint>
     argint(1, &major) < 0 ||
    80005974:	02054863          	bltz	a0,800059a4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005978:	f6841683          	lh	a3,-152(s0)
    8000597c:	f6c41603          	lh	a2,-148(s0)
    80005980:	458d                	li	a1,3
    80005982:	f7040513          	addi	a0,s0,-144
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	776080e7          	jalr	1910(ra) # 800050fc <create>
     argint(2, &minor) < 0 ||
    8000598e:	c919                	beqz	a0,800059a4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	094080e7          	jalr	148(ra) # 80003a24 <iunlockput>
  end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	87c080e7          	jalr	-1924(ra) # 80004214 <end_op>
  return 0;
    800059a0:	4501                	li	a0,0
    800059a2:	a031                	j	800059ae <sys_mknod+0x80>
    end_op();
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	870080e7          	jalr	-1936(ra) # 80004214 <end_op>
    return -1;
    800059ac:	557d                	li	a0,-1
}
    800059ae:	60ea                	ld	ra,152(sp)
    800059b0:	644a                	ld	s0,144(sp)
    800059b2:	610d                	addi	sp,sp,160
    800059b4:	8082                	ret

00000000800059b6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059b6:	7135                	addi	sp,sp,-160
    800059b8:	ed06                	sd	ra,152(sp)
    800059ba:	e922                	sd	s0,144(sp)
    800059bc:	e526                	sd	s1,136(sp)
    800059be:	e14a                	sd	s2,128(sp)
    800059c0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059c2:	ffffc097          	auipc	ra,0xffffc
    800059c6:	112080e7          	jalr	274(ra) # 80001ad4 <myproc>
    800059ca:	892a                	mv	s2,a0
  
  begin_op();
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	7c8080e7          	jalr	1992(ra) # 80004194 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059d4:	08000613          	li	a2,128
    800059d8:	f6040593          	addi	a1,s0,-160
    800059dc:	4501                	li	a0,0
    800059de:	ffffd097          	auipc	ra,0xffffd
    800059e2:	2b6080e7          	jalr	694(ra) # 80002c94 <argstr>
    800059e6:	04054b63          	bltz	a0,80005a3c <sys_chdir+0x86>
    800059ea:	f6040513          	addi	a0,s0,-160
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	58a080e7          	jalr	1418(ra) # 80003f78 <namei>
    800059f6:	84aa                	mv	s1,a0
    800059f8:	c131                	beqz	a0,80005a3c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	dc8080e7          	jalr	-568(ra) # 800037c2 <ilock>
  if(ip->type != T_DIR){
    80005a02:	04449703          	lh	a4,68(s1)
    80005a06:	4785                	li	a5,1
    80005a08:	04f71063          	bne	a4,a5,80005a48 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	e76080e7          	jalr	-394(ra) # 80003884 <iunlock>
  iput(p->cwd);
    80005a16:	15093503          	ld	a0,336(s2)
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	f62080e7          	jalr	-158(ra) # 8000397c <iput>
  end_op();
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	7f2080e7          	jalr	2034(ra) # 80004214 <end_op>
  p->cwd = ip;
    80005a2a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a2e:	4501                	li	a0,0
}
    80005a30:	60ea                	ld	ra,152(sp)
    80005a32:	644a                	ld	s0,144(sp)
    80005a34:	64aa                	ld	s1,136(sp)
    80005a36:	690a                	ld	s2,128(sp)
    80005a38:	610d                	addi	sp,sp,160
    80005a3a:	8082                	ret
    end_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7d8080e7          	jalr	2008(ra) # 80004214 <end_op>
    return -1;
    80005a44:	557d                	li	a0,-1
    80005a46:	b7ed                	j	80005a30 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a48:	8526                	mv	a0,s1
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	fda080e7          	jalr	-38(ra) # 80003a24 <iunlockput>
    end_op();
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	7c2080e7          	jalr	1986(ra) # 80004214 <end_op>
    return -1;
    80005a5a:	557d                	li	a0,-1
    80005a5c:	bfd1                	j	80005a30 <sys_chdir+0x7a>

0000000080005a5e <sys_exec>:

uint64
sys_exec(void)
{
    80005a5e:	7145                	addi	sp,sp,-464
    80005a60:	e786                	sd	ra,456(sp)
    80005a62:	e3a2                	sd	s0,448(sp)
    80005a64:	ff26                	sd	s1,440(sp)
    80005a66:	fb4a                	sd	s2,432(sp)
    80005a68:	f74e                	sd	s3,424(sp)
    80005a6a:	f352                	sd	s4,416(sp)
    80005a6c:	ef56                	sd	s5,408(sp)
    80005a6e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a70:	08000613          	li	a2,128
    80005a74:	f4040593          	addi	a1,s0,-192
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	21a080e7          	jalr	538(ra) # 80002c94 <argstr>
    return -1;
    80005a82:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a84:	0c054a63          	bltz	a0,80005b58 <sys_exec+0xfa>
    80005a88:	e3840593          	addi	a1,s0,-456
    80005a8c:	4505                	li	a0,1
    80005a8e:	ffffd097          	auipc	ra,0xffffd
    80005a92:	1e4080e7          	jalr	484(ra) # 80002c72 <argaddr>
    80005a96:	0c054163          	bltz	a0,80005b58 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a9a:	10000613          	li	a2,256
    80005a9e:	4581                	li	a1,0
    80005aa0:	e4040513          	addi	a0,s0,-448
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	22e080e7          	jalr	558(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005aac:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ab0:	89a6                	mv	s3,s1
    80005ab2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ab4:	02000a13          	li	s4,32
    80005ab8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005abc:	00391513          	slli	a0,s2,0x3
    80005ac0:	e3040593          	addi	a1,s0,-464
    80005ac4:	e3843783          	ld	a5,-456(s0)
    80005ac8:	953e                	add	a0,a0,a5
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	0ec080e7          	jalr	236(ra) # 80002bb6 <fetchaddr>
    80005ad2:	02054a63          	bltz	a0,80005b06 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ad6:	e3043783          	ld	a5,-464(s0)
    80005ada:	c3b9                	beqz	a5,80005b20 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	00a080e7          	jalr	10(ra) # 80000ae6 <kalloc>
    80005ae4:	85aa                	mv	a1,a0
    80005ae6:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005aea:	cd11                	beqz	a0,80005b06 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aec:	6605                	lui	a2,0x1
    80005aee:	e3043503          	ld	a0,-464(s0)
    80005af2:	ffffd097          	auipc	ra,0xffffd
    80005af6:	116080e7          	jalr	278(ra) # 80002c08 <fetchstr>
    80005afa:	00054663          	bltz	a0,80005b06 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005afe:	0905                	addi	s2,s2,1
    80005b00:	09a1                	addi	s3,s3,8
    80005b02:	fb491be3          	bne	s2,s4,80005ab8 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b06:	10048913          	addi	s2,s1,256
    80005b0a:	6088                	ld	a0,0(s1)
    80005b0c:	c529                	beqz	a0,80005b56 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b0e:	ffffb097          	auipc	ra,0xffffb
    80005b12:	edc080e7          	jalr	-292(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b16:	04a1                	addi	s1,s1,8
    80005b18:	ff2499e3          	bne	s1,s2,80005b0a <sys_exec+0xac>
  return -1;
    80005b1c:	597d                	li	s2,-1
    80005b1e:	a82d                	j	80005b58 <sys_exec+0xfa>
      argv[i] = 0;
    80005b20:	0a8e                	slli	s5,s5,0x3
    80005b22:	fc040793          	addi	a5,s0,-64
    80005b26:	9abe                	add	s5,s5,a5
    80005b28:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b2c:	e4040593          	addi	a1,s0,-448
    80005b30:	f4040513          	addi	a0,s0,-192
    80005b34:	fffff097          	auipc	ra,0xfffff
    80005b38:	194080e7          	jalr	404(ra) # 80004cc8 <exec>
    80005b3c:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3e:	10048993          	addi	s3,s1,256
    80005b42:	6088                	ld	a0,0(s1)
    80005b44:	c911                	beqz	a0,80005b58 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	ea4080e7          	jalr	-348(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4e:	04a1                	addi	s1,s1,8
    80005b50:	ff3499e3          	bne	s1,s3,80005b42 <sys_exec+0xe4>
    80005b54:	a011                	j	80005b58 <sys_exec+0xfa>
  return -1;
    80005b56:	597d                	li	s2,-1
}
    80005b58:	854a                	mv	a0,s2
    80005b5a:	60be                	ld	ra,456(sp)
    80005b5c:	641e                	ld	s0,448(sp)
    80005b5e:	74fa                	ld	s1,440(sp)
    80005b60:	795a                	ld	s2,432(sp)
    80005b62:	79ba                	ld	s3,424(sp)
    80005b64:	7a1a                	ld	s4,416(sp)
    80005b66:	6afa                	ld	s5,408(sp)
    80005b68:	6179                	addi	sp,sp,464
    80005b6a:	8082                	ret

0000000080005b6c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b6c:	7139                	addi	sp,sp,-64
    80005b6e:	fc06                	sd	ra,56(sp)
    80005b70:	f822                	sd	s0,48(sp)
    80005b72:	f426                	sd	s1,40(sp)
    80005b74:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b76:	ffffc097          	auipc	ra,0xffffc
    80005b7a:	f5e080e7          	jalr	-162(ra) # 80001ad4 <myproc>
    80005b7e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b80:	fd840593          	addi	a1,s0,-40
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	0ec080e7          	jalr	236(ra) # 80002c72 <argaddr>
    return -1;
    80005b8e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b90:	0e054063          	bltz	a0,80005c70 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b94:	fc840593          	addi	a1,s0,-56
    80005b98:	fd040513          	addi	a0,s0,-48
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	dfc080e7          	jalr	-516(ra) # 80004998 <pipealloc>
    return -1;
    80005ba4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ba6:	0c054563          	bltz	a0,80005c70 <sys_pipe+0x104>
  fd0 = -1;
    80005baa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bae:	fd043503          	ld	a0,-48(s0)
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	508080e7          	jalr	1288(ra) # 800050ba <fdalloc>
    80005bba:	fca42223          	sw	a0,-60(s0)
    80005bbe:	08054c63          	bltz	a0,80005c56 <sys_pipe+0xea>
    80005bc2:	fc843503          	ld	a0,-56(s0)
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	4f4080e7          	jalr	1268(ra) # 800050ba <fdalloc>
    80005bce:	fca42023          	sw	a0,-64(s0)
    80005bd2:	06054863          	bltz	a0,80005c42 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bd6:	4691                	li	a3,4
    80005bd8:	fc440613          	addi	a2,s0,-60
    80005bdc:	fd843583          	ld	a1,-40(s0)
    80005be0:	68a8                	ld	a0,80(s1)
    80005be2:	ffffc097          	auipc	ra,0xffffc
    80005be6:	b88080e7          	jalr	-1144(ra) # 8000176a <copyout>
    80005bea:	02054063          	bltz	a0,80005c0a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bee:	4691                	li	a3,4
    80005bf0:	fc040613          	addi	a2,s0,-64
    80005bf4:	fd843583          	ld	a1,-40(s0)
    80005bf8:	0591                	addi	a1,a1,4
    80005bfa:	68a8                	ld	a0,80(s1)
    80005bfc:	ffffc097          	auipc	ra,0xffffc
    80005c00:	b6e080e7          	jalr	-1170(ra) # 8000176a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c04:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c06:	06055563          	bgez	a0,80005c70 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c0a:	fc442783          	lw	a5,-60(s0)
    80005c0e:	07e9                	addi	a5,a5,26
    80005c10:	078e                	slli	a5,a5,0x3
    80005c12:	97a6                	add	a5,a5,s1
    80005c14:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c18:	fc042503          	lw	a0,-64(s0)
    80005c1c:	0569                	addi	a0,a0,26
    80005c1e:	050e                	slli	a0,a0,0x3
    80005c20:	9526                	add	a0,a0,s1
    80005c22:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c26:	fd043503          	ld	a0,-48(s0)
    80005c2a:	fffff097          	auipc	ra,0xfffff
    80005c2e:	a3e080e7          	jalr	-1474(ra) # 80004668 <fileclose>
    fileclose(wf);
    80005c32:	fc843503          	ld	a0,-56(s0)
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	a32080e7          	jalr	-1486(ra) # 80004668 <fileclose>
    return -1;
    80005c3e:	57fd                	li	a5,-1
    80005c40:	a805                	j	80005c70 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c42:	fc442783          	lw	a5,-60(s0)
    80005c46:	0007c863          	bltz	a5,80005c56 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c4a:	01a78513          	addi	a0,a5,26
    80005c4e:	050e                	slli	a0,a0,0x3
    80005c50:	9526                	add	a0,a0,s1
    80005c52:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c56:	fd043503          	ld	a0,-48(s0)
    80005c5a:	fffff097          	auipc	ra,0xfffff
    80005c5e:	a0e080e7          	jalr	-1522(ra) # 80004668 <fileclose>
    fileclose(wf);
    80005c62:	fc843503          	ld	a0,-56(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	a02080e7          	jalr	-1534(ra) # 80004668 <fileclose>
    return -1;
    80005c6e:	57fd                	li	a5,-1
}
    80005c70:	853e                	mv	a0,a5
    80005c72:	70e2                	ld	ra,56(sp)
    80005c74:	7442                	ld	s0,48(sp)
    80005c76:	74a2                	ld	s1,40(sp)
    80005c78:	6121                	addi	sp,sp,64
    80005c7a:	8082                	ret

0000000080005c7c <sys_mmap>:

// kernel/sysfile.c

uint64
sys_mmap(void)
{
    80005c7c:	715d                	addi	sp,sp,-80
    80005c7e:	e486                	sd	ra,72(sp)
    80005c80:	e0a2                	sd	s0,64(sp)
    80005c82:	fc26                	sd	s1,56(sp)
    80005c84:	0880                	addi	s0,sp,80
  uint64 addr, sz, offset;
  int prot, flags, fd; struct file *f;

  if(argaddr(0, &addr) < 0 || argaddr(1, &sz) < 0 || argint(2, &prot) < 0
    80005c86:	fd840593          	addi	a1,s0,-40
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	fe6080e7          	jalr	-26(ra) # 80002c72 <argaddr>
    80005c94:	10054f63          	bltz	a0,80005db2 <sys_mmap+0x136>
    80005c98:	fd040593          	addi	a1,s0,-48
    80005c9c:	4505                	li	a0,1
    80005c9e:	ffffd097          	auipc	ra,0xffffd
    80005ca2:	fd4080e7          	jalr	-44(ra) # 80002c72 <argaddr>
    80005ca6:	10054c63          	bltz	a0,80005dbe <sys_mmap+0x142>
    80005caa:	fc440593          	addi	a1,s0,-60
    80005cae:	4509                	li	a0,2
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	fa0080e7          	jalr	-96(ra) # 80002c50 <argint>
    80005cb8:	10054563          	bltz	a0,80005dc2 <sys_mmap+0x146>
    || argint(3, &flags) < 0 || argfd(4, &fd, &f) < 0 || argaddr(5, &offset) < 0 || sz == 0)
    80005cbc:	fc040593          	addi	a1,s0,-64
    80005cc0:	450d                	li	a0,3
    80005cc2:	ffffd097          	auipc	ra,0xffffd
    80005cc6:	f8e080e7          	jalr	-114(ra) # 80002c50 <argint>
    80005cca:	0e054e63          	bltz	a0,80005dc6 <sys_mmap+0x14a>
    80005cce:	fb040613          	addi	a2,s0,-80
    80005cd2:	fbc40593          	addi	a1,s0,-68
    80005cd6:	4511                	li	a0,4
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	37a080e7          	jalr	890(ra) # 80005052 <argfd>
    80005ce0:	0e054563          	bltz	a0,80005dca <sys_mmap+0x14e>
    80005ce4:	fc840593          	addi	a1,s0,-56
    80005ce8:	4515                	li	a0,5
    80005cea:	ffffd097          	auipc	ra,0xffffd
    80005cee:	f88080e7          	jalr	-120(ra) # 80002c72 <argaddr>
    80005cf2:	0c054e63          	bltz	a0,80005dce <sys_mmap+0x152>
    80005cf6:	fd043783          	ld	a5,-48(s0)
    80005cfa:	cfe1                	beqz	a5,80005dd2 <sys_mmap+0x156>
    return -1;
  
  if((!f->readable && (prot & (PROT_READ)))
    80005cfc:	fb043703          	ld	a4,-80(s0)
    80005d00:	00874683          	lbu	a3,8(a4)
    80005d04:	e689                	bnez	a3,80005d0e <sys_mmap+0x92>
    80005d06:	fc442683          	lw	a3,-60(s0)
    80005d0a:	8a85                	andi	a3,a3,1
    80005d0c:	e6e9                	bnez	a3,80005dd6 <sys_mmap+0x15a>
     || (!f->writable && (prot & PROT_WRITE) && !(flags & MAP_PRIVATE)))
    80005d0e:	00974703          	lbu	a4,9(a4)
    80005d12:	eb09                	bnez	a4,80005d24 <sys_mmap+0xa8>
    80005d14:	fc442703          	lw	a4,-60(s0)
    80005d18:	8b09                	andi	a4,a4,2
    80005d1a:	c709                	beqz	a4,80005d24 <sys_mmap+0xa8>
    80005d1c:	fc042703          	lw	a4,-64(s0)
    80005d20:	8b09                	andi	a4,a4,2
    80005d22:	cf45                	beqz	a4,80005dda <sys_mmap+0x15e>
    return -1;
  
  sz = PGROUNDUP(sz);
    80005d24:	6705                	lui	a4,0x1
    80005d26:	177d                	addi	a4,a4,-1
    80005d28:	97ba                	add	a5,a5,a4
    80005d2a:	777d                	lui	a4,0xfffff
    80005d2c:	8ff9                	and	a5,a5,a4
    80005d2e:	fcf43823          	sd	a5,-48(s0)

  struct proc *p = myproc();
    80005d32:	ffffc097          	auipc	ra,0xffffc
    80005d36:	da2080e7          	jalr	-606(ra) # 80001ad4 <myproc>
  // map the file
  // our implementation maps file right below where the trapframe is,
  // from high addresses to low addresses.

  // Find a free vma, and calculate where to map the file along the way.
  for(int i=0;i<NVMA;i++) {
    80005d3a:	16850793          	addi	a5,a0,360
    80005d3e:	46850693          	addi	a3,a0,1128
  uint64 vaend = MMAPEND; // non-inclusive
    80005d42:	020005b7          	lui	a1,0x2000
    80005d46:	15fd                	addi	a1,a1,-1
    80005d48:	05b6                	slli	a1,a1,0xd
  struct vma *v = 0;
    80005d4a:	4481                	li	s1,0
        v = &p->vmas[i];
        // found free vma;
        v->valid = 1;
      }
    } else if(vv->vastart < vaend) {
      vaend = PGROUNDDOWN(vv->vastart);
    80005d4c:	757d                	lui	a0,0xfffff
        v->valid = 1;
    80005d4e:	4805                	li	a6,1
    80005d50:	a811                	j	80005d64 <sys_mmap+0xe8>
    } else if(vv->vastart < vaend) {
    80005d52:	6798                	ld	a4,8(a5)
    80005d54:	00b77463          	bgeu	a4,a1,80005d5c <sys_mmap+0xe0>
      vaend = PGROUNDDOWN(vv->vastart);
    80005d58:	00a775b3          	and	a1,a4,a0
  for(int i=0;i<NVMA;i++) {
    80005d5c:	03078793          	addi	a5,a5,48
    80005d60:	00d78963          	beq	a5,a3,80005d72 <sys_mmap+0xf6>
    if(vv->valid == 0) {
    80005d64:	4398                	lw	a4,0(a5)
    80005d66:	f775                	bnez	a4,80005d52 <sys_mmap+0xd6>
      if(v == 0) {
    80005d68:	f8f5                	bnez	s1,80005d5c <sys_mmap+0xe0>
        v->valid = 1;
    80005d6a:	0107a023          	sw	a6,0(a5)
        v = &p->vmas[i];
    80005d6e:	84be                	mv	s1,a5
    80005d70:	b7f5                	j	80005d5c <sys_mmap+0xe0>
    }
  }

  if(v == 0){
    80005d72:	c885                	beqz	s1,80005da2 <sys_mmap+0x126>
    panic("mmap: no free vma");
  }
  
  v->vastart = vaend - sz;
    80005d74:	fd043783          	ld	a5,-48(s0)
    80005d78:	8d9d                	sub	a1,a1,a5
    80005d7a:	e48c                	sd	a1,8(s1)
  v->sz = sz;
    80005d7c:	e89c                	sd	a5,16(s1)
  v->prot = prot;
    80005d7e:	fc442783          	lw	a5,-60(s0)
    80005d82:	d09c                	sw	a5,32(s1)
  v->flags = flags;
    80005d84:	fc042783          	lw	a5,-64(s0)
    80005d88:	d0dc                	sw	a5,36(s1)
  v->f = f; // assume f->type == FD_INODE
    80005d8a:	fb043503          	ld	a0,-80(s0)
    80005d8e:	ec88                	sd	a0,24(s1)
  v->offset = offset;
    80005d90:	fc843783          	ld	a5,-56(s0)
    80005d94:	f49c                	sd	a5,40(s1)

  filedup(v->f);
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	880080e7          	jalr	-1920(ra) # 80004616 <filedup>

  return v->vastart;
    80005d9e:	6488                	ld	a0,8(s1)
    80005da0:	a811                	j	80005db4 <sys_mmap+0x138>
    panic("mmap: no free vma");
    80005da2:	00003517          	auipc	a0,0x3
    80005da6:	9c650513          	addi	a0,a0,-1594 # 80008768 <syscalls+0x330>
    80005daa:	ffffa097          	auipc	ra,0xffffa
    80005dae:	786080e7          	jalr	1926(ra) # 80000530 <panic>
    return -1;
    80005db2:	557d                	li	a0,-1
}
    80005db4:	60a6                	ld	ra,72(sp)
    80005db6:	6406                	ld	s0,64(sp)
    80005db8:	74e2                	ld	s1,56(sp)
    80005dba:	6161                	addi	sp,sp,80
    80005dbc:	8082                	ret
    return -1;
    80005dbe:	557d                	li	a0,-1
    80005dc0:	bfd5                	j	80005db4 <sys_mmap+0x138>
    80005dc2:	557d                	li	a0,-1
    80005dc4:	bfc5                	j	80005db4 <sys_mmap+0x138>
    80005dc6:	557d                	li	a0,-1
    80005dc8:	b7f5                	j	80005db4 <sys_mmap+0x138>
    80005dca:	557d                	li	a0,-1
    80005dcc:	b7e5                	j	80005db4 <sys_mmap+0x138>
    80005dce:	557d                	li	a0,-1
    80005dd0:	b7d5                	j	80005db4 <sys_mmap+0x138>
    80005dd2:	557d                	li	a0,-1
    80005dd4:	b7c5                	j	80005db4 <sys_mmap+0x138>
    return -1;
    80005dd6:	557d                	li	a0,-1
    80005dd8:	bff1                	j	80005db4 <sys_mmap+0x138>
    80005dda:	557d                	li	a0,-1
    80005ddc:	bfe1                	j	80005db4 <sys_mmap+0x138>

0000000080005dde <findvma>:
// find a vma using a virtual address inside that vma.
struct vma *findvma(struct proc *p, uint64 va) {
    80005dde:	1141                	addi	sp,sp,-16
    80005de0:	e422                	sd	s0,8(sp)
    80005de2:	0800                	addi	s0,sp,16
  for(int i=0;i<NVMA;i++) {
    80005de4:	16850793          	addi	a5,a0,360
    80005de8:	4701                	li	a4,0
    struct vma *vv = &p->vmas[i];
    if(vv->valid == 1 && va >= vv->vastart && va < vv->vastart + vv->sz) {
    80005dea:	4805                	li	a6,1
  for(int i=0;i<NVMA;i++) {
    80005dec:	48c1                	li	a7,16
    80005dee:	a031                	j	80005dfa <findvma+0x1c>
    80005df0:	2705                	addiw	a4,a4,1
    80005df2:	03078793          	addi	a5,a5,48
    80005df6:	03170463          	beq	a4,a7,80005e1e <findvma+0x40>
    if(vv->valid == 1 && va >= vv->vastart && va < vv->vastart + vv->sz) {
    80005dfa:	4394                	lw	a3,0(a5)
    80005dfc:	ff069ae3          	bne	a3,a6,80005df0 <findvma+0x12>
    80005e00:	6794                	ld	a3,8(a5)
    80005e02:	fed5e7e3          	bltu	a1,a3,80005df0 <findvma+0x12>
    80005e06:	6b90                	ld	a2,16(a5)
    80005e08:	96b2                	add	a3,a3,a2
    80005e0a:	fed5f3e3          	bgeu	a1,a3,80005df0 <findvma+0x12>
    struct vma *vv = &p->vmas[i];
    80005e0e:	00171793          	slli	a5,a4,0x1
    80005e12:	97ba                	add	a5,a5,a4
    80005e14:	0792                	slli	a5,a5,0x4
    80005e16:	16878793          	addi	a5,a5,360
    80005e1a:	953e                	add	a0,a0,a5
    80005e1c:	a011                	j	80005e20 <findvma+0x42>
      return vv;
    }
  }
  return 0;
    80005e1e:	4501                	li	a0,0
}
    80005e20:	6422                	ld	s0,8(sp)
    80005e22:	0141                	addi	sp,sp,16
    80005e24:	8082                	ret

0000000080005e26 <vmatrylazytouch>:

// finds out whether a page is previously lazy-allocated for a vma
// and needed to be touched before use.
// if so, touch it so it's mapped to an actual physical page and contains
// content of the mapped file.
int vmatrylazytouch(uint64 va) {
    80005e26:	7179                	addi	sp,sp,-48
    80005e28:	f406                	sd	ra,40(sp)
    80005e2a:	f022                	sd	s0,32(sp)
    80005e2c:	ec26                	sd	s1,24(sp)
    80005e2e:	e84a                	sd	s2,16(sp)
    80005e30:	e44e                	sd	s3,8(sp)
    80005e32:	e052                	sd	s4,0(sp)
    80005e34:	1800                	addi	s0,sp,48
    80005e36:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	c9c080e7          	jalr	-868(ra) # 80001ad4 <myproc>
    80005e40:	8a2a                	mv	s4,a0
  struct vma *v = findvma(p, va);
    80005e42:	85ca                	mv	a1,s2
    80005e44:	00000097          	auipc	ra,0x0
    80005e48:	f9a080e7          	jalr	-102(ra) # 80005dde <findvma>
  if(v == 0) {
    80005e4c:	c945                	beqz	a0,80005efc <vmatrylazytouch+0xd6>
    80005e4e:	84aa                	mv	s1,a0
  }

  // printf("vma mapping: %p => %d\n", va, v->offset + PGROUNDDOWN(va - v->vastart));

  // allocate physical page
  void *pa = kalloc();
    80005e50:	ffffb097          	auipc	ra,0xffffb
    80005e54:	c96080e7          	jalr	-874(ra) # 80000ae6 <kalloc>
    80005e58:	89aa                	mv	s3,a0
  if(pa == 0) {
    80005e5a:	c149                	beqz	a0,80005edc <vmatrylazytouch+0xb6>
    panic("vmalazytouch: kalloc");
  }
  memset(pa, 0, PGSIZE);
    80005e5c:	6605                	lui	a2,0x1
    80005e5e:	4581                	li	a1,0
    80005e60:	ffffb097          	auipc	ra,0xffffb
    80005e64:	e72080e7          	jalr	-398(ra) # 80000cd2 <memset>
  
  // read data from disk
  begin_op();
    80005e68:	ffffe097          	auipc	ra,0xffffe
    80005e6c:	32c080e7          	jalr	812(ra) # 80004194 <begin_op>
  ilock(v->f->ip);
    80005e70:	6c9c                	ld	a5,24(s1)
    80005e72:	6f88                	ld	a0,24(a5)
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	94e080e7          	jalr	-1714(ra) # 800037c2 <ilock>
  readi(v->f->ip, 0, (uint64)pa, v->offset + PGROUNDDOWN(va - v->vastart), PGSIZE);
    80005e7c:	649c                	ld	a5,8(s1)
    80005e7e:	40f907bb          	subw	a5,s2,a5
    80005e82:	76fd                	lui	a3,0xfffff
    80005e84:	8ff5                	and	a5,a5,a3
    80005e86:	7494                	ld	a3,40(s1)
    80005e88:	6c88                	ld	a0,24(s1)
    80005e8a:	6705                	lui	a4,0x1
    80005e8c:	9ebd                	addw	a3,a3,a5
    80005e8e:	864e                	mv	a2,s3
    80005e90:	4581                	li	a1,0
    80005e92:	6d08                	ld	a0,24(a0)
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	be2080e7          	jalr	-1054(ra) # 80003a76 <readi>
  iunlock(v->f->ip);
    80005e9c:	6c9c                	ld	a5,24(s1)
    80005e9e:	6f88                	ld	a0,24(a5)
    80005ea0:	ffffe097          	auipc	ra,0xffffe
    80005ea4:	9e4080e7          	jalr	-1564(ra) # 80003884 <iunlock>
  end_op();
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	36c080e7          	jalr	876(ra) # 80004214 <end_op>
  if(v->prot & PROT_WRITE)
    perm |= PTE_W;
  if(v->prot & PROT_EXEC)
    perm |= PTE_X;

  if(mappages(p->pagetable, va, PGSIZE, (uint64)pa, PTE_R | PTE_W | PTE_U) < 0) {
    80005eb0:	4759                	li	a4,22
    80005eb2:	86ce                	mv	a3,s3
    80005eb4:	6605                	lui	a2,0x1
    80005eb6:	85ca                	mv	a1,s2
    80005eb8:	050a3503          	ld	a0,80(s4)
    80005ebc:	ffffb097          	auipc	ra,0xffffb
    80005ec0:	2fe080e7          	jalr	766(ra) # 800011ba <mappages>
    80005ec4:	87aa                	mv	a5,a0
    panic("vmalazytouch: mappages");
  }

  return 1;
    80005ec6:	4505                	li	a0,1
  if(mappages(p->pagetable, va, PGSIZE, (uint64)pa, PTE_R | PTE_W | PTE_U) < 0) {
    80005ec8:	0207c263          	bltz	a5,80005eec <vmatrylazytouch+0xc6>
}
    80005ecc:	70a2                	ld	ra,40(sp)
    80005ece:	7402                	ld	s0,32(sp)
    80005ed0:	64e2                	ld	s1,24(sp)
    80005ed2:	6942                	ld	s2,16(sp)
    80005ed4:	69a2                	ld	s3,8(sp)
    80005ed6:	6a02                	ld	s4,0(sp)
    80005ed8:	6145                	addi	sp,sp,48
    80005eda:	8082                	ret
    panic("vmalazytouch: kalloc");
    80005edc:	00003517          	auipc	a0,0x3
    80005ee0:	8a450513          	addi	a0,a0,-1884 # 80008780 <syscalls+0x348>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	64c080e7          	jalr	1612(ra) # 80000530 <panic>
    panic("vmalazytouch: mappages");
    80005eec:	00003517          	auipc	a0,0x3
    80005ef0:	8ac50513          	addi	a0,a0,-1876 # 80008798 <syscalls+0x360>
    80005ef4:	ffffa097          	auipc	ra,0xffffa
    80005ef8:	63c080e7          	jalr	1596(ra) # 80000530 <panic>
    return 0;
    80005efc:	4501                	li	a0,0
    80005efe:	b7f9                	j	80005ecc <vmatrylazytouch+0xa6>

0000000080005f00 <sys_munmap>:

uint64
sys_munmap(void)
{
    80005f00:	7139                	addi	sp,sp,-64
    80005f02:	fc06                	sd	ra,56(sp)
    80005f04:	f822                	sd	s0,48(sp)
    80005f06:	f426                	sd	s1,40(sp)
    80005f08:	f04a                	sd	s2,32(sp)
    80005f0a:	ec4e                	sd	s3,24(sp)
    80005f0c:	e852                	sd	s4,16(sp)
    80005f0e:	0080                	addi	s0,sp,64
  uint64 addr, sz;

  if(argaddr(0, &addr) < 0 || argaddr(1, &sz) < 0 || sz == 0)
    80005f10:	fc840593          	addi	a1,s0,-56
    80005f14:	4501                	li	a0,0
    80005f16:	ffffd097          	auipc	ra,0xffffd
    80005f1a:	d5c080e7          	jalr	-676(ra) # 80002c72 <argaddr>
    return -1;
    80005f1e:	54fd                	li	s1,-1
  if(argaddr(0, &addr) < 0 || argaddr(1, &sz) < 0 || sz == 0)
    80005f20:	0a054d63          	bltz	a0,80005fda <sys_munmap+0xda>
    80005f24:	fc040593          	addi	a1,s0,-64
    80005f28:	4505                	li	a0,1
    80005f2a:	ffffd097          	auipc	ra,0xffffd
    80005f2e:	d48080e7          	jalr	-696(ra) # 80002c72 <argaddr>
    80005f32:	0c054663          	bltz	a0,80005ffe <sys_munmap+0xfe>
    80005f36:	fc043783          	ld	a5,-64(s0)
    80005f3a:	c3c5                	beqz	a5,80005fda <sys_munmap+0xda>

  struct proc *p = myproc();
    80005f3c:	ffffc097          	auipc	ra,0xffffc
    80005f40:	b98080e7          	jalr	-1128(ra) # 80001ad4 <myproc>
    80005f44:	8a2a                	mv	s4,a0

  struct vma *v = findvma(p, addr);
    80005f46:	fc843983          	ld	s3,-56(s0)
    80005f4a:	85ce                	mv	a1,s3
    80005f4c:	00000097          	auipc	ra,0x0
    80005f50:	e92080e7          	jalr	-366(ra) # 80005dde <findvma>
    80005f54:	892a                	mv	s2,a0
  if(v == 0) {
    80005f56:	c555                	beqz	a0,80006002 <sys_munmap+0x102>
    return -1;
  }

  if(addr > v->vastart && addr + sz < v->vastart + v->sz) {
    80005f58:	651c                	ld	a5,8(a0)
    80005f5a:	0137ff63          	bgeu	a5,s3,80005f78 <sys_munmap+0x78>
    80005f5e:	fc043703          	ld	a4,-64(s0)
    80005f62:	974e                	add	a4,a4,s3
    80005f64:	6914                	ld	a3,16(a0)
    80005f66:	97b6                	add	a5,a5,a3
    80005f68:	06f76963          	bltu	a4,a5,80005fda <sys_munmap+0xda>
    return -1;
  }

  uint64 addr_aligned = addr;
  if(addr > v->vastart) {
    addr_aligned = PGROUNDUP(addr);
    80005f6c:	6585                	lui	a1,0x1
    80005f6e:	15fd                	addi	a1,a1,-1
    80005f70:	95ce                	add	a1,a1,s3
    80005f72:	77fd                	lui	a5,0xfffff
    80005f74:	8dfd                	and	a1,a1,a5
    80005f76:	a011                	j	80005f7a <sys_munmap+0x7a>
  uint64 addr_aligned = addr;
    80005f78:	85ce                	mv	a1,s3
  }

  int nunmap = sz - (addr_aligned-addr); // nbytes to unmap
    80005f7a:	fc043603          	ld	a2,-64(s0)
    80005f7e:	0136063b          	addw	a2,a2,s3
    80005f82:	9e0d                	subw	a2,a2,a1
  if(nunmap < 0)
    nunmap = 0;
  
  vmaunmap(p->pagetable, addr_aligned, nunmap, v); // custom memory page unmap routine for mmapped pages.
    80005f84:	0006079b          	sext.w	a5,a2
    80005f88:	fff7c793          	not	a5,a5
    80005f8c:	97fd                	srai	a5,a5,0x3f
    80005f8e:	8e7d                	and	a2,a2,a5
    80005f90:	86ca                	mv	a3,s2
    80005f92:	2601                	sext.w	a2,a2
    80005f94:	050a3503          	ld	a0,80(s4)
    80005f98:	ffffb097          	auipc	ra,0xffffb
    80005f9c:	0cc080e7          	jalr	204(ra) # 80001064 <vmaunmap>

  if(addr <= v->vastart && addr + sz > v->vastart) { // unmap at the beginning
    80005fa0:	00893703          	ld	a4,8(s2)
    80005fa4:	fc843783          	ld	a5,-56(s0)
    80005fa8:	02f76063          	bltu	a4,a5,80005fc8 <sys_munmap+0xc8>
    80005fac:	fc043683          	ld	a3,-64(s0)
    80005fb0:	97b6                	add	a5,a5,a3
    80005fb2:	00f77b63          	bgeu	a4,a5,80005fc8 <sys_munmap+0xc8>
    v->offset += addr + sz - v->vastart;
    80005fb6:	02893683          	ld	a3,40(s2)
    80005fba:	96be                	add	a3,a3,a5
    80005fbc:	40e68733          	sub	a4,a3,a4
    80005fc0:	02e93423          	sd	a4,40(s2)
    v->vastart = addr + sz;
    80005fc4:	00f93423          	sd	a5,8(s2)
  }
  v->sz -= sz;
    80005fc8:	01093483          	ld	s1,16(s2)
    80005fcc:	fc043783          	ld	a5,-64(s0)
    80005fd0:	8c9d                	sub	s1,s1,a5
    80005fd2:	00993823          	sd	s1,16(s2)

  if(v->sz <= 0) {
    80005fd6:	c899                	beqz	s1,80005fec <sys_munmap+0xec>
    fileclose(v->f);
    v->valid = 0;
  }

  return 0;  
    80005fd8:	4481                	li	s1,0
}
    80005fda:	8526                	mv	a0,s1
    80005fdc:	70e2                	ld	ra,56(sp)
    80005fde:	7442                	ld	s0,48(sp)
    80005fe0:	74a2                	ld	s1,40(sp)
    80005fe2:	7902                	ld	s2,32(sp)
    80005fe4:	69e2                	ld	s3,24(sp)
    80005fe6:	6a42                	ld	s4,16(sp)
    80005fe8:	6121                	addi	sp,sp,64
    80005fea:	8082                	ret
    fileclose(v->f);
    80005fec:	01893503          	ld	a0,24(s2)
    80005ff0:	ffffe097          	auipc	ra,0xffffe
    80005ff4:	678080e7          	jalr	1656(ra) # 80004668 <fileclose>
    v->valid = 0;
    80005ff8:	00092023          	sw	zero,0(s2)
    80005ffc:	bff9                	j	80005fda <sys_munmap+0xda>
    return -1;
    80005ffe:	54fd                	li	s1,-1
    80006000:	bfe9                	j	80005fda <sys_munmap+0xda>
    return -1;
    80006002:	54fd                	li	s1,-1
    80006004:	bfd9                	j	80005fda <sys_munmap+0xda>
	...

0000000080006010 <kernelvec>:
    80006010:	7111                	addi	sp,sp,-256
    80006012:	e006                	sd	ra,0(sp)
    80006014:	e40a                	sd	sp,8(sp)
    80006016:	e80e                	sd	gp,16(sp)
    80006018:	ec12                	sd	tp,24(sp)
    8000601a:	f016                	sd	t0,32(sp)
    8000601c:	f41a                	sd	t1,40(sp)
    8000601e:	f81e                	sd	t2,48(sp)
    80006020:	fc22                	sd	s0,56(sp)
    80006022:	e0a6                	sd	s1,64(sp)
    80006024:	e4aa                	sd	a0,72(sp)
    80006026:	e8ae                	sd	a1,80(sp)
    80006028:	ecb2                	sd	a2,88(sp)
    8000602a:	f0b6                	sd	a3,96(sp)
    8000602c:	f4ba                	sd	a4,104(sp)
    8000602e:	f8be                	sd	a5,112(sp)
    80006030:	fcc2                	sd	a6,120(sp)
    80006032:	e146                	sd	a7,128(sp)
    80006034:	e54a                	sd	s2,136(sp)
    80006036:	e94e                	sd	s3,144(sp)
    80006038:	ed52                	sd	s4,152(sp)
    8000603a:	f156                	sd	s5,160(sp)
    8000603c:	f55a                	sd	s6,168(sp)
    8000603e:	f95e                	sd	s7,176(sp)
    80006040:	fd62                	sd	s8,184(sp)
    80006042:	e1e6                	sd	s9,192(sp)
    80006044:	e5ea                	sd	s10,200(sp)
    80006046:	e9ee                	sd	s11,208(sp)
    80006048:	edf2                	sd	t3,216(sp)
    8000604a:	f1f6                	sd	t4,224(sp)
    8000604c:	f5fa                	sd	t5,232(sp)
    8000604e:	f9fe                	sd	t6,240(sp)
    80006050:	a33fc0ef          	jal	ra,80002a82 <kerneltrap>
    80006054:	6082                	ld	ra,0(sp)
    80006056:	6122                	ld	sp,8(sp)
    80006058:	61c2                	ld	gp,16(sp)
    8000605a:	7282                	ld	t0,32(sp)
    8000605c:	7322                	ld	t1,40(sp)
    8000605e:	73c2                	ld	t2,48(sp)
    80006060:	7462                	ld	s0,56(sp)
    80006062:	6486                	ld	s1,64(sp)
    80006064:	6526                	ld	a0,72(sp)
    80006066:	65c6                	ld	a1,80(sp)
    80006068:	6666                	ld	a2,88(sp)
    8000606a:	7686                	ld	a3,96(sp)
    8000606c:	7726                	ld	a4,104(sp)
    8000606e:	77c6                	ld	a5,112(sp)
    80006070:	7866                	ld	a6,120(sp)
    80006072:	688a                	ld	a7,128(sp)
    80006074:	692a                	ld	s2,136(sp)
    80006076:	69ca                	ld	s3,144(sp)
    80006078:	6a6a                	ld	s4,152(sp)
    8000607a:	7a8a                	ld	s5,160(sp)
    8000607c:	7b2a                	ld	s6,168(sp)
    8000607e:	7bca                	ld	s7,176(sp)
    80006080:	7c6a                	ld	s8,184(sp)
    80006082:	6c8e                	ld	s9,192(sp)
    80006084:	6d2e                	ld	s10,200(sp)
    80006086:	6dce                	ld	s11,208(sp)
    80006088:	6e6e                	ld	t3,216(sp)
    8000608a:	7e8e                	ld	t4,224(sp)
    8000608c:	7f2e                	ld	t5,232(sp)
    8000608e:	7fce                	ld	t6,240(sp)
    80006090:	6111                	addi	sp,sp,256
    80006092:	10200073          	sret
    80006096:	00000013          	nop
    8000609a:	00000013          	nop
    8000609e:	0001                	nop

00000000800060a0 <timervec>:
    800060a0:	34051573          	csrrw	a0,mscratch,a0
    800060a4:	e10c                	sd	a1,0(a0)
    800060a6:	e510                	sd	a2,8(a0)
    800060a8:	e914                	sd	a3,16(a0)
    800060aa:	6d0c                	ld	a1,24(a0)
    800060ac:	7110                	ld	a2,32(a0)
    800060ae:	6194                	ld	a3,0(a1)
    800060b0:	96b2                	add	a3,a3,a2
    800060b2:	e194                	sd	a3,0(a1)
    800060b4:	4589                	li	a1,2
    800060b6:	14459073          	csrw	sip,a1
    800060ba:	6914                	ld	a3,16(a0)
    800060bc:	6510                	ld	a2,8(a0)
    800060be:	610c                	ld	a1,0(a0)
    800060c0:	34051573          	csrrw	a0,mscratch,a0
    800060c4:	30200073          	mret
	...

00000000800060ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ca:	1141                	addi	sp,sp,-16
    800060cc:	e422                	sd	s0,8(sp)
    800060ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060d0:	0c0007b7          	lui	a5,0xc000
    800060d4:	4705                	li	a4,1
    800060d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060d8:	c3d8                	sw	a4,4(a5)
}
    800060da:	6422                	ld	s0,8(sp)
    800060dc:	0141                	addi	sp,sp,16
    800060de:	8082                	ret

00000000800060e0 <plicinithart>:

void
plicinithart(void)
{
    800060e0:	1141                	addi	sp,sp,-16
    800060e2:	e406                	sd	ra,8(sp)
    800060e4:	e022                	sd	s0,0(sp)
    800060e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060e8:	ffffc097          	auipc	ra,0xffffc
    800060ec:	9c0080e7          	jalr	-1600(ra) # 80001aa8 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060f0:	0085171b          	slliw	a4,a0,0x8
    800060f4:	0c0027b7          	lui	a5,0xc002
    800060f8:	97ba                	add	a5,a5,a4
    800060fa:	40200713          	li	a4,1026
    800060fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006102:	00d5151b          	slliw	a0,a0,0xd
    80006106:	0c2017b7          	lui	a5,0xc201
    8000610a:	953e                	add	a0,a0,a5
    8000610c:	00052023          	sw	zero,0(a0)
}
    80006110:	60a2                	ld	ra,8(sp)
    80006112:	6402                	ld	s0,0(sp)
    80006114:	0141                	addi	sp,sp,16
    80006116:	8082                	ret

0000000080006118 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006118:	1141                	addi	sp,sp,-16
    8000611a:	e406                	sd	ra,8(sp)
    8000611c:	e022                	sd	s0,0(sp)
    8000611e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006120:	ffffc097          	auipc	ra,0xffffc
    80006124:	988080e7          	jalr	-1656(ra) # 80001aa8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006128:	00d5179b          	slliw	a5,a0,0xd
    8000612c:	0c201537          	lui	a0,0xc201
    80006130:	953e                	add	a0,a0,a5
  return irq;
}
    80006132:	4148                	lw	a0,4(a0)
    80006134:	60a2                	ld	ra,8(sp)
    80006136:	6402                	ld	s0,0(sp)
    80006138:	0141                	addi	sp,sp,16
    8000613a:	8082                	ret

000000008000613c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000613c:	1101                	addi	sp,sp,-32
    8000613e:	ec06                	sd	ra,24(sp)
    80006140:	e822                	sd	s0,16(sp)
    80006142:	e426                	sd	s1,8(sp)
    80006144:	1000                	addi	s0,sp,32
    80006146:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	960080e7          	jalr	-1696(ra) # 80001aa8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006150:	00d5151b          	slliw	a0,a0,0xd
    80006154:	0c2017b7          	lui	a5,0xc201
    80006158:	97aa                	add	a5,a5,a0
    8000615a:	c3c4                	sw	s1,4(a5)
}
    8000615c:	60e2                	ld	ra,24(sp)
    8000615e:	6442                	ld	s0,16(sp)
    80006160:	64a2                	ld	s1,8(sp)
    80006162:	6105                	addi	sp,sp,32
    80006164:	8082                	ret

0000000080006166 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006166:	1141                	addi	sp,sp,-16
    80006168:	e406                	sd	ra,8(sp)
    8000616a:	e022                	sd	s0,0(sp)
    8000616c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000616e:	479d                	li	a5,7
    80006170:	06a7c963          	blt	a5,a0,800061e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006174:	00029797          	auipc	a5,0x29
    80006178:	e8c78793          	addi	a5,a5,-372 # 8002f000 <disk>
    8000617c:	00a78733          	add	a4,a5,a0
    80006180:	6789                	lui	a5,0x2
    80006182:	97ba                	add	a5,a5,a4
    80006184:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006188:	e7ad                	bnez	a5,800061f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000618a:	00451793          	slli	a5,a0,0x4
    8000618e:	0002b717          	auipc	a4,0x2b
    80006192:	e7270713          	addi	a4,a4,-398 # 80031000 <disk+0x2000>
    80006196:	6314                	ld	a3,0(a4)
    80006198:	96be                	add	a3,a3,a5
    8000619a:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffcd000>
  disk.desc[i].len = 0;
    8000619e:	6314                	ld	a3,0(a4)
    800061a0:	96be                	add	a3,a3,a5
    800061a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800061a6:	6314                	ld	a3,0(a4)
    800061a8:	96be                	add	a3,a3,a5
    800061aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800061ae:	6318                	ld	a4,0(a4)
    800061b0:	97ba                	add	a5,a5,a4
    800061b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800061b6:	00029797          	auipc	a5,0x29
    800061ba:	e4a78793          	addi	a5,a5,-438 # 8002f000 <disk>
    800061be:	97aa                	add	a5,a5,a0
    800061c0:	6509                	lui	a0,0x2
    800061c2:	953e                	add	a0,a0,a5
    800061c4:	4785                	li	a5,1
    800061c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800061ca:	0002b517          	auipc	a0,0x2b
    800061ce:	e4e50513          	addi	a0,a0,-434 # 80031018 <disk+0x2018>
    800061d2:	ffffc097          	auipc	ra,0xffffc
    800061d6:	332080e7          	jalr	818(ra) # 80002504 <wakeup>
}
    800061da:	60a2                	ld	ra,8(sp)
    800061dc:	6402                	ld	s0,0(sp)
    800061de:	0141                	addi	sp,sp,16
    800061e0:	8082                	ret
    panic("free_desc 1");
    800061e2:	00002517          	auipc	a0,0x2
    800061e6:	5ce50513          	addi	a0,a0,1486 # 800087b0 <syscalls+0x378>
    800061ea:	ffffa097          	auipc	ra,0xffffa
    800061ee:	346080e7          	jalr	838(ra) # 80000530 <panic>
    panic("free_desc 2");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	5ce50513          	addi	a0,a0,1486 # 800087c0 <syscalls+0x388>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	336080e7          	jalr	822(ra) # 80000530 <panic>

0000000080006202 <virtio_disk_init>:
{
    80006202:	1101                	addi	sp,sp,-32
    80006204:	ec06                	sd	ra,24(sp)
    80006206:	e822                	sd	s0,16(sp)
    80006208:	e426                	sd	s1,8(sp)
    8000620a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000620c:	00002597          	auipc	a1,0x2
    80006210:	5c458593          	addi	a1,a1,1476 # 800087d0 <syscalls+0x398>
    80006214:	0002b517          	auipc	a0,0x2b
    80006218:	f1450513          	addi	a0,a0,-236 # 80031128 <disk+0x2128>
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	92a080e7          	jalr	-1750(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006224:	100017b7          	lui	a5,0x10001
    80006228:	4398                	lw	a4,0(a5)
    8000622a:	2701                	sext.w	a4,a4
    8000622c:	747277b7          	lui	a5,0x74727
    80006230:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006234:	0ef71163          	bne	a4,a5,80006316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006238:	100017b7          	lui	a5,0x10001
    8000623c:	43dc                	lw	a5,4(a5)
    8000623e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006240:	4705                	li	a4,1
    80006242:	0ce79a63          	bne	a5,a4,80006316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006246:	100017b7          	lui	a5,0x10001
    8000624a:	479c                	lw	a5,8(a5)
    8000624c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000624e:	4709                	li	a4,2
    80006250:	0ce79363          	bne	a5,a4,80006316 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006254:	100017b7          	lui	a5,0x10001
    80006258:	47d8                	lw	a4,12(a5)
    8000625a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000625c:	554d47b7          	lui	a5,0x554d4
    80006260:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006264:	0af71963          	bne	a4,a5,80006316 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006268:	100017b7          	lui	a5,0x10001
    8000626c:	4705                	li	a4,1
    8000626e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006270:	470d                	li	a4,3
    80006272:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006274:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006276:	c7ffe737          	lui	a4,0xc7ffe
    8000627a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc75f>
    8000627e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006280:	2701                	sext.w	a4,a4
    80006282:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006284:	472d                	li	a4,11
    80006286:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006288:	473d                	li	a4,15
    8000628a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000628c:	6705                	lui	a4,0x1
    8000628e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006290:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006294:	5bdc                	lw	a5,52(a5)
    80006296:	2781                	sext.w	a5,a5
  if(max == 0)
    80006298:	c7d9                	beqz	a5,80006326 <virtio_disk_init+0x124>
  if(max < NUM)
    8000629a:	471d                	li	a4,7
    8000629c:	08f77d63          	bgeu	a4,a5,80006336 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062a0:	100014b7          	lui	s1,0x10001
    800062a4:	47a1                	li	a5,8
    800062a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800062a8:	6609                	lui	a2,0x2
    800062aa:	4581                	li	a1,0
    800062ac:	00029517          	auipc	a0,0x29
    800062b0:	d5450513          	addi	a0,a0,-684 # 8002f000 <disk>
    800062b4:	ffffb097          	auipc	ra,0xffffb
    800062b8:	a1e080e7          	jalr	-1506(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800062bc:	00029717          	auipc	a4,0x29
    800062c0:	d4470713          	addi	a4,a4,-700 # 8002f000 <disk>
    800062c4:	00c75793          	srli	a5,a4,0xc
    800062c8:	2781                	sext.w	a5,a5
    800062ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800062cc:	0002b797          	auipc	a5,0x2b
    800062d0:	d3478793          	addi	a5,a5,-716 # 80031000 <disk+0x2000>
    800062d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800062d6:	00029717          	auipc	a4,0x29
    800062da:	daa70713          	addi	a4,a4,-598 # 8002f080 <disk+0x80>
    800062de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800062e0:	0002a717          	auipc	a4,0x2a
    800062e4:	d2070713          	addi	a4,a4,-736 # 80030000 <disk+0x1000>
    800062e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800062ea:	4705                	li	a4,1
    800062ec:	00e78c23          	sb	a4,24(a5)
    800062f0:	00e78ca3          	sb	a4,25(a5)
    800062f4:	00e78d23          	sb	a4,26(a5)
    800062f8:	00e78da3          	sb	a4,27(a5)
    800062fc:	00e78e23          	sb	a4,28(a5)
    80006300:	00e78ea3          	sb	a4,29(a5)
    80006304:	00e78f23          	sb	a4,30(a5)
    80006308:	00e78fa3          	sb	a4,31(a5)
}
    8000630c:	60e2                	ld	ra,24(sp)
    8000630e:	6442                	ld	s0,16(sp)
    80006310:	64a2                	ld	s1,8(sp)
    80006312:	6105                	addi	sp,sp,32
    80006314:	8082                	ret
    panic("could not find virtio disk");
    80006316:	00002517          	auipc	a0,0x2
    8000631a:	4ca50513          	addi	a0,a0,1226 # 800087e0 <syscalls+0x3a8>
    8000631e:	ffffa097          	auipc	ra,0xffffa
    80006322:	212080e7          	jalr	530(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	4da50513          	addi	a0,a0,1242 # 80008800 <syscalls+0x3c8>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	202080e7          	jalr	514(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    80006336:	00002517          	auipc	a0,0x2
    8000633a:	4ea50513          	addi	a0,a0,1258 # 80008820 <syscalls+0x3e8>
    8000633e:	ffffa097          	auipc	ra,0xffffa
    80006342:	1f2080e7          	jalr	498(ra) # 80000530 <panic>

0000000080006346 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006346:	7159                	addi	sp,sp,-112
    80006348:	f486                	sd	ra,104(sp)
    8000634a:	f0a2                	sd	s0,96(sp)
    8000634c:	eca6                	sd	s1,88(sp)
    8000634e:	e8ca                	sd	s2,80(sp)
    80006350:	e4ce                	sd	s3,72(sp)
    80006352:	e0d2                	sd	s4,64(sp)
    80006354:	fc56                	sd	s5,56(sp)
    80006356:	f85a                	sd	s6,48(sp)
    80006358:	f45e                	sd	s7,40(sp)
    8000635a:	f062                	sd	s8,32(sp)
    8000635c:	ec66                	sd	s9,24(sp)
    8000635e:	e86a                	sd	s10,16(sp)
    80006360:	1880                	addi	s0,sp,112
    80006362:	892a                	mv	s2,a0
    80006364:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006366:	00c52c83          	lw	s9,12(a0)
    8000636a:	001c9c9b          	slliw	s9,s9,0x1
    8000636e:	1c82                	slli	s9,s9,0x20
    80006370:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006374:	0002b517          	auipc	a0,0x2b
    80006378:	db450513          	addi	a0,a0,-588 # 80031128 <disk+0x2128>
    8000637c:	ffffb097          	auipc	ra,0xffffb
    80006380:	85a080e7          	jalr	-1958(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006384:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006386:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006388:	00029b97          	auipc	s7,0x29
    8000638c:	c78b8b93          	addi	s7,s7,-904 # 8002f000 <disk>
    80006390:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006392:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006394:	8a4e                	mv	s4,s3
    80006396:	a051                	j	8000641a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006398:	00fb86b3          	add	a3,s7,a5
    8000639c:	96da                	add	a3,a3,s6
    8000639e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800063a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800063a4:	0207c563          	bltz	a5,800063ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800063a8:	2485                	addiw	s1,s1,1
    800063aa:	0711                	addi	a4,a4,4
    800063ac:	25548063          	beq	s1,s5,800065ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800063b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800063b2:	0002b697          	auipc	a3,0x2b
    800063b6:	c6668693          	addi	a3,a3,-922 # 80031018 <disk+0x2018>
    800063ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800063bc:	0006c583          	lbu	a1,0(a3)
    800063c0:	fde1                	bnez	a1,80006398 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800063c2:	2785                	addiw	a5,a5,1
    800063c4:	0685                	addi	a3,a3,1
    800063c6:	ff879be3          	bne	a5,s8,800063bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800063ca:	57fd                	li	a5,-1
    800063cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800063ce:	02905a63          	blez	s1,80006402 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063d2:	f9042503          	lw	a0,-112(s0)
    800063d6:	00000097          	auipc	ra,0x0
    800063da:	d90080e7          	jalr	-624(ra) # 80006166 <free_desc>
      for(int j = 0; j < i; j++)
    800063de:	4785                	li	a5,1
    800063e0:	0297d163          	bge	a5,s1,80006402 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063e4:	f9442503          	lw	a0,-108(s0)
    800063e8:	00000097          	auipc	ra,0x0
    800063ec:	d7e080e7          	jalr	-642(ra) # 80006166 <free_desc>
      for(int j = 0; j < i; j++)
    800063f0:	4789                	li	a5,2
    800063f2:	0097d863          	bge	a5,s1,80006402 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800063f6:	f9842503          	lw	a0,-104(s0)
    800063fa:	00000097          	auipc	ra,0x0
    800063fe:	d6c080e7          	jalr	-660(ra) # 80006166 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006402:	0002b597          	auipc	a1,0x2b
    80006406:	d2658593          	addi	a1,a1,-730 # 80031128 <disk+0x2128>
    8000640a:	0002b517          	auipc	a0,0x2b
    8000640e:	c0e50513          	addi	a0,a0,-1010 # 80031018 <disk+0x2018>
    80006412:	ffffc097          	auipc	ra,0xffffc
    80006416:	f6c080e7          	jalr	-148(ra) # 8000237e <sleep>
  for(int i = 0; i < 3; i++){
    8000641a:	f9040713          	addi	a4,s0,-112
    8000641e:	84ce                	mv	s1,s3
    80006420:	bf41                	j	800063b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006422:	20058713          	addi	a4,a1,512
    80006426:	00471693          	slli	a3,a4,0x4
    8000642a:	00029717          	auipc	a4,0x29
    8000642e:	bd670713          	addi	a4,a4,-1066 # 8002f000 <disk>
    80006432:	9736                	add	a4,a4,a3
    80006434:	4685                	li	a3,1
    80006436:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000643a:	20058713          	addi	a4,a1,512
    8000643e:	00471693          	slli	a3,a4,0x4
    80006442:	00029717          	auipc	a4,0x29
    80006446:	bbe70713          	addi	a4,a4,-1090 # 8002f000 <disk>
    8000644a:	9736                	add	a4,a4,a3
    8000644c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006450:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006454:	7679                	lui	a2,0xffffe
    80006456:	963e                	add	a2,a2,a5
    80006458:	0002b697          	auipc	a3,0x2b
    8000645c:	ba868693          	addi	a3,a3,-1112 # 80031000 <disk+0x2000>
    80006460:	6298                	ld	a4,0(a3)
    80006462:	9732                	add	a4,a4,a2
    80006464:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006466:	6298                	ld	a4,0(a3)
    80006468:	9732                	add	a4,a4,a2
    8000646a:	4541                	li	a0,16
    8000646c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000646e:	6298                	ld	a4,0(a3)
    80006470:	9732                	add	a4,a4,a2
    80006472:	4505                	li	a0,1
    80006474:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006478:	f9442703          	lw	a4,-108(s0)
    8000647c:	6288                	ld	a0,0(a3)
    8000647e:	962a                	add	a2,a2,a0
    80006480:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffcc00e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006484:	0712                	slli	a4,a4,0x4
    80006486:	6290                	ld	a2,0(a3)
    80006488:	963a                	add	a2,a2,a4
    8000648a:	05890513          	addi	a0,s2,88
    8000648e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006490:	6294                	ld	a3,0(a3)
    80006492:	96ba                	add	a3,a3,a4
    80006494:	40000613          	li	a2,1024
    80006498:	c690                	sw	a2,8(a3)
  if(write)
    8000649a:	140d0063          	beqz	s10,800065da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000649e:	0002b697          	auipc	a3,0x2b
    800064a2:	b626b683          	ld	a3,-1182(a3) # 80031000 <disk+0x2000>
    800064a6:	96ba                	add	a3,a3,a4
    800064a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064ac:	00029817          	auipc	a6,0x29
    800064b0:	b5480813          	addi	a6,a6,-1196 # 8002f000 <disk>
    800064b4:	0002b517          	auipc	a0,0x2b
    800064b8:	b4c50513          	addi	a0,a0,-1204 # 80031000 <disk+0x2000>
    800064bc:	6114                	ld	a3,0(a0)
    800064be:	96ba                	add	a3,a3,a4
    800064c0:	00c6d603          	lhu	a2,12(a3)
    800064c4:	00166613          	ori	a2,a2,1
    800064c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064cc:	f9842683          	lw	a3,-104(s0)
    800064d0:	6110                	ld	a2,0(a0)
    800064d2:	9732                	add	a4,a4,a2
    800064d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800064d8:	20058613          	addi	a2,a1,512
    800064dc:	0612                	slli	a2,a2,0x4
    800064de:	9642                	add	a2,a2,a6
    800064e0:	577d                	li	a4,-1
    800064e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064e6:	00469713          	slli	a4,a3,0x4
    800064ea:	6114                	ld	a3,0(a0)
    800064ec:	96ba                	add	a3,a3,a4
    800064ee:	03078793          	addi	a5,a5,48
    800064f2:	97c2                	add	a5,a5,a6
    800064f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800064f6:	611c                	ld	a5,0(a0)
    800064f8:	97ba                	add	a5,a5,a4
    800064fa:	4685                	li	a3,1
    800064fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064fe:	611c                	ld	a5,0(a0)
    80006500:	97ba                	add	a5,a5,a4
    80006502:	4809                	li	a6,2
    80006504:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006508:	611c                	ld	a5,0(a0)
    8000650a:	973e                	add	a4,a4,a5
    8000650c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006510:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006514:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006518:	6518                	ld	a4,8(a0)
    8000651a:	00275783          	lhu	a5,2(a4)
    8000651e:	8b9d                	andi	a5,a5,7
    80006520:	0786                	slli	a5,a5,0x1
    80006522:	97ba                	add	a5,a5,a4
    80006524:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006528:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000652c:	6518                	ld	a4,8(a0)
    8000652e:	00275783          	lhu	a5,2(a4)
    80006532:	2785                	addiw	a5,a5,1
    80006534:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006538:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000653c:	100017b7          	lui	a5,0x10001
    80006540:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006544:	00492703          	lw	a4,4(s2)
    80006548:	4785                	li	a5,1
    8000654a:	02f71163          	bne	a4,a5,8000656c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000654e:	0002b997          	auipc	s3,0x2b
    80006552:	bda98993          	addi	s3,s3,-1062 # 80031128 <disk+0x2128>
  while(b->disk == 1) {
    80006556:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006558:	85ce                	mv	a1,s3
    8000655a:	854a                	mv	a0,s2
    8000655c:	ffffc097          	auipc	ra,0xffffc
    80006560:	e22080e7          	jalr	-478(ra) # 8000237e <sleep>
  while(b->disk == 1) {
    80006564:	00492783          	lw	a5,4(s2)
    80006568:	fe9788e3          	beq	a5,s1,80006558 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000656c:	f9042903          	lw	s2,-112(s0)
    80006570:	20090793          	addi	a5,s2,512
    80006574:	00479713          	slli	a4,a5,0x4
    80006578:	00029797          	auipc	a5,0x29
    8000657c:	a8878793          	addi	a5,a5,-1400 # 8002f000 <disk>
    80006580:	97ba                	add	a5,a5,a4
    80006582:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006586:	0002b997          	auipc	s3,0x2b
    8000658a:	a7a98993          	addi	s3,s3,-1414 # 80031000 <disk+0x2000>
    8000658e:	00491713          	slli	a4,s2,0x4
    80006592:	0009b783          	ld	a5,0(s3)
    80006596:	97ba                	add	a5,a5,a4
    80006598:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000659c:	854a                	mv	a0,s2
    8000659e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065a2:	00000097          	auipc	ra,0x0
    800065a6:	bc4080e7          	jalr	-1084(ra) # 80006166 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065aa:	8885                	andi	s1,s1,1
    800065ac:	f0ed                	bnez	s1,8000658e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065ae:	0002b517          	auipc	a0,0x2b
    800065b2:	b7a50513          	addi	a0,a0,-1158 # 80031128 <disk+0x2128>
    800065b6:	ffffa097          	auipc	ra,0xffffa
    800065ba:	6d4080e7          	jalr	1748(ra) # 80000c8a <release>
}
    800065be:	70a6                	ld	ra,104(sp)
    800065c0:	7406                	ld	s0,96(sp)
    800065c2:	64e6                	ld	s1,88(sp)
    800065c4:	6946                	ld	s2,80(sp)
    800065c6:	69a6                	ld	s3,72(sp)
    800065c8:	6a06                	ld	s4,64(sp)
    800065ca:	7ae2                	ld	s5,56(sp)
    800065cc:	7b42                	ld	s6,48(sp)
    800065ce:	7ba2                	ld	s7,40(sp)
    800065d0:	7c02                	ld	s8,32(sp)
    800065d2:	6ce2                	ld	s9,24(sp)
    800065d4:	6d42                	ld	s10,16(sp)
    800065d6:	6165                	addi	sp,sp,112
    800065d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800065da:	0002b697          	auipc	a3,0x2b
    800065de:	a266b683          	ld	a3,-1498(a3) # 80031000 <disk+0x2000>
    800065e2:	96ba                	add	a3,a3,a4
    800065e4:	4609                	li	a2,2
    800065e6:	00c69623          	sh	a2,12(a3)
    800065ea:	b5c9                	j	800064ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065ec:	f9042583          	lw	a1,-112(s0)
    800065f0:	20058793          	addi	a5,a1,512
    800065f4:	0792                	slli	a5,a5,0x4
    800065f6:	00029517          	auipc	a0,0x29
    800065fa:	ab250513          	addi	a0,a0,-1358 # 8002f0a8 <disk+0xa8>
    800065fe:	953e                	add	a0,a0,a5
  if(write)
    80006600:	e20d11e3          	bnez	s10,80006422 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006604:	20058713          	addi	a4,a1,512
    80006608:	00471693          	slli	a3,a4,0x4
    8000660c:	00029717          	auipc	a4,0x29
    80006610:	9f470713          	addi	a4,a4,-1548 # 8002f000 <disk>
    80006614:	9736                	add	a4,a4,a3
    80006616:	0a072423          	sw	zero,168(a4)
    8000661a:	b505                	j	8000643a <virtio_disk_rw+0xf4>

000000008000661c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000661c:	1101                	addi	sp,sp,-32
    8000661e:	ec06                	sd	ra,24(sp)
    80006620:	e822                	sd	s0,16(sp)
    80006622:	e426                	sd	s1,8(sp)
    80006624:	e04a                	sd	s2,0(sp)
    80006626:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006628:	0002b517          	auipc	a0,0x2b
    8000662c:	b0050513          	addi	a0,a0,-1280 # 80031128 <disk+0x2128>
    80006630:	ffffa097          	auipc	ra,0xffffa
    80006634:	5a6080e7          	jalr	1446(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006638:	10001737          	lui	a4,0x10001
    8000663c:	533c                	lw	a5,96(a4)
    8000663e:	8b8d                	andi	a5,a5,3
    80006640:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006642:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006646:	0002b797          	auipc	a5,0x2b
    8000664a:	9ba78793          	addi	a5,a5,-1606 # 80031000 <disk+0x2000>
    8000664e:	6b94                	ld	a3,16(a5)
    80006650:	0207d703          	lhu	a4,32(a5)
    80006654:	0026d783          	lhu	a5,2(a3)
    80006658:	06f70163          	beq	a4,a5,800066ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000665c:	00029917          	auipc	s2,0x29
    80006660:	9a490913          	addi	s2,s2,-1628 # 8002f000 <disk>
    80006664:	0002b497          	auipc	s1,0x2b
    80006668:	99c48493          	addi	s1,s1,-1636 # 80031000 <disk+0x2000>
    __sync_synchronize();
    8000666c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006670:	6898                	ld	a4,16(s1)
    80006672:	0204d783          	lhu	a5,32(s1)
    80006676:	8b9d                	andi	a5,a5,7
    80006678:	078e                	slli	a5,a5,0x3
    8000667a:	97ba                	add	a5,a5,a4
    8000667c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000667e:	20078713          	addi	a4,a5,512
    80006682:	0712                	slli	a4,a4,0x4
    80006684:	974a                	add	a4,a4,s2
    80006686:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000668a:	e731                	bnez	a4,800066d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000668c:	20078793          	addi	a5,a5,512
    80006690:	0792                	slli	a5,a5,0x4
    80006692:	97ca                	add	a5,a5,s2
    80006694:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006696:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000669a:	ffffc097          	auipc	ra,0xffffc
    8000669e:	e6a080e7          	jalr	-406(ra) # 80002504 <wakeup>

    disk.used_idx += 1;
    800066a2:	0204d783          	lhu	a5,32(s1)
    800066a6:	2785                	addiw	a5,a5,1
    800066a8:	17c2                	slli	a5,a5,0x30
    800066aa:	93c1                	srli	a5,a5,0x30
    800066ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800066b0:	6898                	ld	a4,16(s1)
    800066b2:	00275703          	lhu	a4,2(a4)
    800066b6:	faf71be3          	bne	a4,a5,8000666c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800066ba:	0002b517          	auipc	a0,0x2b
    800066be:	a6e50513          	addi	a0,a0,-1426 # 80031128 <disk+0x2128>
    800066c2:	ffffa097          	auipc	ra,0xffffa
    800066c6:	5c8080e7          	jalr	1480(ra) # 80000c8a <release>
}
    800066ca:	60e2                	ld	ra,24(sp)
    800066cc:	6442                	ld	s0,16(sp)
    800066ce:	64a2                	ld	s1,8(sp)
    800066d0:	6902                	ld	s2,0(sp)
    800066d2:	6105                	addi	sp,sp,32
    800066d4:	8082                	ret
      panic("virtio_disk_intr status");
    800066d6:	00002517          	auipc	a0,0x2
    800066da:	16a50513          	addi	a0,a0,362 # 80008840 <syscalls+0x408>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	e52080e7          	jalr	-430(ra) # 80000530 <panic>
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
