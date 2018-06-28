/*
* Tencent is pleased to support the open source community by making Libco available.

* Copyright (C) 2014 THL A29 Limited, a Tencent company. All rights reserved.
*
* Licensed under the Apache License, Version 2.0 (the "License"); 
* you may not use this file except in compliance with the License. 
* You may obtain a copy of the License at
*
*	http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, 
* software distributed under the License is distributed on an "AS IS" BASIS, 
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. 
* See the License for the specific language governing permissions and 
* limitations under the License.
*/

// AT&T  : mov src dst
// INTEL : MOV DST SRC

/*
 https://blog.csdn.net/hit_shaoqi/article/details/50938602 参考文章
-------------  ebp 
   s1_var_a
   s1_var_b
   s1_var_c
-------------  esp

调用某个函数后,栈就变成这样了

pushl %ebp 
movl %esp,%ebp 

-------------
   s1_var_a
   s1_var_b
   s1_var_c
   push ebp
-------------  ebp
   s2_var_a
-------------

*/
.globl coctx_swap
#if !defined( __APPLE__ ) && !defined( __FreeBSD__ )
.type  coctx_swap, @function
#endif
coctx_swap:

#if defined(__i386__)
	leal 4(%esp), %eax //sp 
	movl 4(%esp), %esp 
	leal 32(%esp), %esp //parm a : &regs[7] + sizeof(void*)

	pushl %eax //esp ->parm a 

	pushl %ebp
	pushl %esi
	pushl %edi
	pushl %edx
	pushl %ecx
	pushl %ebx
	pushl -4(%eax)

	
	movl 4(%eax), %esp //parm b -> &regs[0]

	popl %eax  //ret func addr
	popl %ebx  
	popl %ecx
	popl %edx
	popl %edi
	popl %esi
	popl %ebp
	popl %esp
	pushl %eax //set ret func addr

	xorl %eax, %eax
	ret

#elif defined(__x86_64__)
    // EIP保存了当前指令的地址,CPU执行一条指令EIP++
    // rdi rsi rdx rcx r8 r9 存放1-6个参数, 超过7个从右往左入栈
    // https://blog.csdn.net/kingzone_2008/article/details/44544285  (AT&T汇编指令enter、leave、call、ret)
    // 还有点似懂非懂
    // 外层调用的时候call co_swap, eip放在了rsp+8的位置
	leaq 8(%rsp),%rax // 把rsp+8的地址赋值到rax寄存器中
	leaq 112(%rdi),%rsp // 把rdi+112的地址赋值到rsp寄存器中, 这里把栈指针修改到了第一个参数的112/8=14偏移量位置
    // 保存当前寄存器的值
	pushq %rax // 把rax寄存器内容压栈 [pushq 相当于rsp=rsp-8 rsp=xxx]
	pushq %rbx
	pushq %rcx
	pushq %rdx

	pushq -8(%rax) //ret func addr,不能只保存函数入口,而是要保存EIP的值,函数入口是第一次makecontext的时候才保存的,比如半路有IO了, co_resume进来后, 再yield出去后,要返回到调用之前的地方

	pushq %rsi
	pushq %rdi
	pushq %rbp
	pushq %r8
	pushq %r9
	pushq %r12
	pushq %r13
	pushq %r14
	pushq %r15
	
	movq %rsi, %rsp // 这一行把栈指针改写到了rsi(第二参数)的地址了,然后下面的popq恢复寄存器
    // 恢复寄存器
	popq %r15
	popq %r14
	popq %r13
	popq %r12
	popq %r9
	popq %r8
	popq %rbp
	popq %rdi
	popq %rsi
	popq %rax //ret func addr, 初始化的时候就把函数入口set进来了
	popq %rdx
	popq %rcx
	popq %rbx
	popq %rsp
	pushq %rax
	
	xorl %eax, %eax // eax寄存器清零, eax保存返回值
	ret
#endif
