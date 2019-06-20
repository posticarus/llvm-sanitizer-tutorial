; NOTE: Assertions have been autogenerated by utils/update_mir_test_checks.py
; RUN: llc -O0 -mtriple=mipsel-linux-gnu -global-isel -stop-after=irtranslator -verify-machineinstrs %s -o - | FileCheck %s -check-prefixes=MIPS32

@.str = private unnamed_addr constant [11 x i8] c"hello %d \0A\00"

define i32 @main() {
  ; MIPS32-LABEL: name: main
  ; MIPS32: bb.1.entry:
  ; MIPS32:   [[GV:%[0-9]+]]:_(p0) = G_GLOBAL_VALUE @.str
  ; MIPS32:   [[COPY:%[0-9]+]]:_(p0) = COPY [[GV]](p0)
  ; MIPS32:   [[C:%[0-9]+]]:_(s32) = G_CONSTANT i32 1234567890
  ; MIPS32:   [[C1:%[0-9]+]]:_(s32) = G_CONSTANT i32 0
  ; MIPS32:   ADJCALLSTACKDOWN 16, 0, implicit-def $sp, implicit $sp
  ; MIPS32:   $a0 = COPY [[COPY]](p0)
  ; MIPS32:   $a1 = COPY [[C]](s32)
  ; MIPS32:   JAL @printf, csr_o32, implicit-def $ra, implicit-def $sp, implicit $a0, implicit $a1, implicit-def $v0
  ; MIPS32:   [[COPY1:%[0-9]+]]:_(s32) = COPY $v0
  ; MIPS32:   ADJCALLSTACKUP 16, 0, implicit-def $sp, implicit $sp
  ; MIPS32:   $v0 = COPY [[C1]](s32)
  ; MIPS32:   RetRA implicit $v0
entry:
  %call = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([11 x i8], [11 x i8]* @.str, i32 0, i32 0), i32 signext 1234567890)
  ret i32 0
}

declare i32 @printf(i8*, ...)
