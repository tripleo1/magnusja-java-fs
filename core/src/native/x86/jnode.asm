; -----------------------------------------------
; $Id$
;
; JNode Assembler image
;
; Author       : E. Prangsma
; -----------------------------------------------

%define TRACE_ABSTRACT              1
%define TRACE_ATHROW                0
%define TRACE_INVOKE                0
%define TRACE_UNHANDLED_EXCEPTION	0
%define TRACE_INTERRUPTS			0
    
%define FAIL_ON_ABSTRACT			1	; Should the VM stop on abstract methods (1), or throw an AbstractMethodError (0)

MAX_STACK_TRACE_LENGTH		equ 30	; Maximum methods shown in a low-level stacktrace

bits 32
 
%include "rmconfig.h"
 
%define KERNEL_STACKEND		(kernel_stack + VmThread_STACK_OVERFLOW_LIMIT)
 
	section .text

kernel_begin:
    
%include "i386.h"
%include "cmos.h"
%include "syscall.h"
%include "lock.h"
%include "java.inc"
%include "console.h"

; ----------------------
; JNode specifics
; ----------------------

; Default Page flags
PF_DEFAULT		equ iPF_PRESENT|iPF_WRITE|iPF_USER
PF_DEFAULT_RO	equ iPF_PRESENT|iPF_USER

; Segment selectors
KERNEL_CS   equ 0x08
KERNEL_DS   equ 0x10
USER_CS     equ 0x1B
USER_DS     equ 0x23
%ifdef BITS32
TSS_DS      equ 0x28
CURPROC_FS  equ 0x33
%else
KERNEL32_CS	equ 0x28
KERNEL32_DS	equ 0x30
TSS_DS		equ 0x38
%endif

%macro LOOPDIE 0
%%l:
	jmp %%l
%endmacro

%macro FLUSH 0
	jmp %%l
%%l:
%endmacro

%macro GLABEL 1
	global %1
%1:
%endmacro

%include "kernel.asm"
%include "cpu.asm"
%include "cpu32.asm"
%ifdef BITS32
  %include "ints32.asm"
  %include "mm32.asm"
%else  
  %include "ints64.asm"
%endif
%include "console.asm"
%include "ints.asm"
%include "version.asm"
%include "syscall.asm" 

%ifdef BITS32
	%define THREADSWITCHINDICATOR	dword[fs:VmProcessor_THREADSWITCHINDICATOR_OFS]
	%define CURRENTPROCESSOR		dword[fs:VmProcessor_ME_OFS]
	%define CURRENTTHREAD			dword[fs:VmProcessor_CURRENTTHREAD_OFS]
	%define NEXTTHREAD				dword[fs:VmProcessor_NEXTTHREAD_OFS]
	%define STACKEND 				dword[fs:VmProcessor_STACKEND_OFS]
	%define STATICSTABLE			dword[fs:VmProcessor_STATICSTABLE_OFS]
	%define IRQCOUNT				dword[fs:VmX86Processor_IRQCOUNT_OFS]
	%define DEADLOCKCOUNTER			dword[fs:VmX86Processor_DEADLOCKCOUNTER_OFS]
	%define DEVICENACOUNTER			dword[fs:VmX86Processor_DEVICENACOUNTER_OFS]
	%define FXSAVECOUNTER			dword[fs:VmX86Processor_FXSAVECOUNTER_OFS]
	%define FXRESTORECOUNTER		dword[fs:VmX86Processor_FXRESTORECOUNTER_OFS]
%else
	%define THREADSWITCHINDICATOR	dword[r15+VmProcessor_THREADSWITCHINDICATOR_OFS]
	%define CURRENTPROCESSOR		qword[r15+VmProcessor_ME_OFS]
	%define CURRENTTHREAD			qword[r15+VmProcessor_CURRENTTHREAD_OFS]
	%define NEXTTHREAD				qword[r15+VmProcessor_NEXTTHREAD_OFS]
	%define STACKEND 				qword[r15+VmProcessor_STACKEND_OFS]
	%define STATICSTABLE			qword[r15+VmProcessor_STATICSTABLE_OFS]
	%define IRQCOUNT				qword[r15+VmX86Processor_IRQCOUNT_OFS]
	%define DEADLOCKCOUNTER			qword[r15+VmX86Processor_DEADLOCKCOUNTER_OFS]
	%define DEVICENACOUNTER			qword[r15+VmX86Processor_DEVICENACOUNTER_OFS]
	%define FXSAVECOUNTER			qword[r15+VmX86Processor_FXSAVECOUNTER_OFS]
	%define FXRESTORECOUNTER		qword[r15+VmX86Processor_FXRESTORECOUNTER_OFS]
%endif

; Invoke the method in EAX
%macro INVOKE_JAVA_METHOD 0
	call [AAX+VmMethod_NATIVECODE_OFS]
%endmacro

%include "unsafe.asm"
%include "unsafe-binop.asm"
%include "unsafe-setmulti.asm"
%include "unsafe-cpuid.asm"
%include "unsafex86.asm"
%include "vm.asm"
%include "vm-invoke.asm"
%include "vm-ints.asm"
%include "vm-compile.asm"
%include "vm-jumptable.asm"
%include "ap-boot.asm"

		align 4096
kernel_end:

extern Luser_esp

scr_ofs:		DA 0
hexchars: 		db '0123456789ABCDEF' 
SPINLOCK		console_lock
jnodeFinished:	DA 0

		align 4096
	global vm_start
vm_start:

