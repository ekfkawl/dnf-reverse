unit SkillHook;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, dialogs, Charicter, MemAPI;

var
  tbbmalloc, scalable_freeRetn, scalable_freeRef: DWORD64;

  procedure Init;

implementation
  uses Main;

procedure f(Obj: TCharicter; v: DWORD64); stdcall;
begin

end;

procedure scalable_freeHook;
asm
  mov rax, [rsp+$B0]
  cmp rax, [dwSkillHook]
  jne @next

  push rcx
  push rdx
  mov rcx, r14  // rsi -> object
  mov rdx, rbp  // skill id
  call f
  pop rdx
  pop rcx

  @next:
  push rsi
  push rdi
  push r14
  push rbp
  sub rsp,$48
  mov r14,rcx
  mov rdi,[scalable_freeRef]
  mov rdi,[rdi]
  test rdi,rdi

  jmp [scalable_freeRetn]
end;

procedure Init;
begin
  showmessage(Inject(@scalable_freeHook).ToHexString);
  exit;

  tbbmalloc:= p.GetModuleBase('tbbmalloc.dll');

  scalable_freeRetn:= tbbmalloc + $11C50 + $16;
  scalable_freeRef:= tbbmalloc + $29328;

  const org = scalable_freeRetn - $16;
  JumpHook64(org, DWORD64(@scalable_freeHook));
end;

end.
