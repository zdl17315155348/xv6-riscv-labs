mit6.s081 xv6-riscv

sth about os-kernel


# Lab1

	N = 10,000  ticks = 165  exchanges/sec = 6060

	N = 100,000 ticks = 1668 exchanges/sec = 5995

	N = 500,000 ticks = 8115 exchanges/sec = 6161



# Lab2：用 GDB 观察 xv6 第一次从 Kernel Mode 切换到 User Mode

## 1. 本 Lab 想让我学会什么

本实验的核心目标不是“会用 gdb”，而是用调试证据把 **RISC-V 特权级切换** 和 **xv6 的首次用户态启动链路** 串起来，具体包括：

- 理解 **S-mode → U-mode** 的关键指令 `sret` 的作用
- 知道 `sret` 返回到哪里由 **`sepc`** 决定（首次通常是 `0x0`，即 `initcode` 用户入口）
- 理解 **trampoline** 的角色：在固定高地址处完成 trap/返回的寄存器恢复、切页表、执行 `sret`
- 学会用 gdb 在边界点（`sret` 前）停住，并用寄存器/反汇编验证“正在发生切换”
- 认识到调试环境限制（远程断点/内存不可访问/符号与架构问题）并能定位原因

---

## 2. 实验现象与关键证据

### 2.1 找到 `sret` 并在其处停住
在 trampoline 附近反汇编可看到 `sret`：

- `0x3ffffff11c: sret`

这表示 CPU 即将从 S-mode 返回到 U-mode（前提：`sstatus.SPP=0`，xv6 会确保这一点）。

### 2.2 `sepc = 0x0` 的含义
在 `sret` 前检查：

- `$sepc = 0x0`

这意味着：`sret` 执行后，PC 会被设置为 `0x0`，也就是 xv6 第一个用户程序 `initcode.S` 的入口虚拟地址。

> 这一步是本实验最硬的“证据链”：
> **`sret` + `sepc=0x0` ⇒ 返回用户态从 0x0 开始执行。**

---

## 3. 我在这个 Lab 里真正学到的点（心得）

### 3.1 “第一次用户态执行”不是抽象概念，而是可观测的状态切换
以前只知道“内核启动完会跑 init”，但通过 `sret` 断点我明确看到：
- 切换发生在 trampoline 的 `sret`
- 跳转目标由 `sepc` 指定（首次就是 `0x0`）

### 3.2 trampoline
trampoline 处会做大量寄存器恢复（`ld ... (a0)`），最后才执行 `sret`。
手册里给的地址可能因版本偏移不一致，但用反汇编向前/向后找 `sret` 一定能定位到“真正的切换点”。


这让我意识到：远程 stub/页表映射时机/断点实现方式都会影响调试行为。
因此本实验更可靠的验证方式是：
- 在 `sret` 前验证 `sepc`
- 结合后续 trap（如 `usertrap/syscall`）观察 `sepc` 是否来自低地址用户空间，形成闭环证据

---



--lab3

--lab4

--lab5

--lab6

--lab7

--lab8

--lab9

