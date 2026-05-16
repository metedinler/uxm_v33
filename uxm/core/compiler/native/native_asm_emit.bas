' Auto-split by V3 modularization
Function CellSize() As Long
    Select Case CellBits
        Case 8
            CellSize=1
        Case 16
            CellSize=2
        Case 32
            CellSize=4
        Case Else
            CellSize=1
    End Select
End Function

Function MemSizePrefix() As String
    Select Case CellBits
        Case 8
            MemSizePrefix="byte"
        Case 16
            MemSizePrefix="word"
        Case 32
            MemSizePrefix="dword"
        Case Else
            MemSizePrefix="byte"
    End Select
End Function

Function Reg8(ByVal regName As String) As String
    Select Case LCase(regName)
        Case "rax":Reg8="al"
        Case "rbx":Reg8="bl"
        Case "rcx":Reg8="cl"
        Case "rdx":Reg8="dl"
        Case "rsi":Reg8="sil"
        Case "rdi":Reg8="dil"
        Case "r8":Reg8="r8b"
        Case "r9":Reg8="r9b"
        Case "r10":Reg8="r10b"
        Case "r11":Reg8="r11b"
        Case "r12":Reg8="r12b"
        Case "r13":Reg8="r13b"
        Case "r14":Reg8="r14b"
        Case "r15":Reg8="r15b"
        Case Else:Reg8="al"
    End Select
End Function

Function Reg16(ByVal regName As String) As String
    Select Case LCase(regName)
        Case "rax":Reg16="ax"
        Case "rbx":Reg16="bx"
        Case "rcx":Reg16="cx"
        Case "rdx":Reg16="dx"
        Case "rsi":Reg16="si"
        Case "rdi":Reg16="di"
        Case "r8":Reg16="r8w"
        Case "r9":Reg16="r9w"
        Case "r10":Reg16="r10w"
        Case "r11":Reg16="r11w"
        Case "r12":Reg16="r12w"
        Case "r13":Reg16="r13w"
        Case "r14":Reg16="r14w"
        Case "r15":Reg16="r15w"
        Case Else:Reg16="ax"
    End Select
End Function

Function Reg32(ByVal regName As String) As String
    Select Case LCase(regName)
        Case "rax":Reg32="eax"
        Case "rbx":Reg32="ebx"
        Case "rcx":Reg32="ecx"
        Case "rdx":Reg32="edx"
        Case "rsi":Reg32="esi"
        Case "rdi":Reg32="edi"
        Case "r8":Reg32="r8d"
        Case "r9":Reg32="r9d"
        Case "r10":Reg32="r10d"
        Case "r11":Reg32="r11d"
        Case "r12":Reg32="r12d"
        Case "r13":Reg32="r13d"
        Case "r14":Reg32="r14d"
        Case "r15":Reg32="r15d"
        Case Else:Reg32="eax"
    End Select
End Function

Function NewAsmId() As Long
    EmitLabelCounter=EmitLabelCounter+1
    NewAsmId=EmitLabelCounter
End Function

Sub GenerateASM()
    Dim i As Long
    OutFF=FreeFile
    Open OutAsm For Output As #OutFF
    EmitHeader()
    EmitStringInitializers()
    EmitDataInitializers()
    For i=1 To InstrCount
        EmitAsmLabelIfNeeded(i)
        EmitInstr(i)
    Next i
    EmitFooter()
    Close #OutFF
End Sub

Sub EmitLine(ByVal s As String)
    Print #OutFF,s
End Sub

Sub EmitHeader()
    EmitLine("; UX-MINIMA x64 V3.3-stage12 generated NASM")
    EmitLine("default rel")
    EmitLine("global uxm_entry")
    EmitLine("global ux_mem")
    EmitLine("global ux_status")
    EmitLine("global ux_flags")
    EmitLine("global ux_ptr")
    EmitLine("global ux_sp")
    EmitLine("global ux_cell_bits")
    EmitLine("global ux_cell_bytes")
    EmitLine("global ux_tape_cells")
    EmitLine("global ux_stack_cells")
    EmitLine("global ux_data_cells")
    EmitLine("global ux_queue_cells")
    EmitLine("global ux_stack_offset")
    EmitLine("global ux_data_offset")
    EmitLine("global ux_pragma_seed_enabled")
    EmitLine("global ux_pragma_seed_value")
    EmitLine("global ux_pragma_arge_json")
    EmitLine("global ux_pragma_arge_interpreter")
    EmitLine("global ux_pragma_arge_step")
    EmitLine("global ux_pragma_arge_trace")
    EmitLine("global ux_pragma_arge_watch")
    EmitLine("extern ux_putc")
    EmitLine("extern ux_getc")
    EmitLine("extern ux_print_data_string")
    EmitLine("extern ux_meta_call_ex")
    EmitLine("extern ux_runtime_error")
    EmitLine("%define UXM_TOTAL_BYTES "+LTrim(Str(TapeBytes+StackBytes+DataBytes)))
    EmitLine("%define TAPE_BYTES "+LTrim(Str(TapeBytes)))
    EmitLine("%define STACK_BYTES "+LTrim(Str(StackBytes)))
    EmitLine("%define DATA_BYTES "+LTrim(Str(DataBytes)))
    EmitLine("%define QUEUE_BYTES "+LTrim(Str(QueueBytes)))
    EmitLine("%define STACK_OFFSET "+LTrim(Str(StackOffset)))
    EmitLine("%define DATA_OFFSET "+LTrim(Str(DataOffset)))
    EmitLine("%define TAPE_CELLS "+LTrim(Str(TapeCells)))
    EmitLine("%define STACK_CELLS "+LTrim(Str(StackCells)))
    EmitLine("%define DATA_CELLS "+LTrim(Str(DataCells)))
    EmitLine("%define QUEUE_CELLS "+LTrim(Str(QueueCells)))
    EmitLine("%define CELL_BITS "+LTrim(Str(CellBits)))
    EmitLine("%define CELL_BYTES "+LTrim(Str(CellSize())))
    EmitLine("%define FLAG_Z 1")
    EmitLine("%define FLAG_C 2")
    EmitLine("%define FLAG_O 4")
    EmitLine("%define FLAG_S 8")
    EmitLine("%define FLAG_SGN 16")
    EmitLine("%define FLAG_END 32")
    EmitLine("%define FLAG_WILD 64")
    EmitLine("%define FLAG_BND 128")
    EmitLine("%define FLAG_TRC 256")
    EmitLine("%define FLAG_FIFO 512")
    EmitLine("%define FLAG_ERR 1024")
    EmitLine("%define FLAG_DIRTY 2048")
    EmitLine("%define FLAG_PCHG 4096")
    EmitLine("section .bss")
    EmitLine("align 16")
    EmitLine("ux_mem: resb UXM_TOTAL_BYTES")
    EmitLine("ux_status: resb 1")
    EmitLine("ux_flags: resw 1")
    EmitLine("ux_ptr: resq 1")
    EmitLine("ux_sp: resq 1")
    EmitLine("ux_cell_bits: resd 1")
    EmitLine("ux_cell_bytes: resd 1")
    EmitLine("ux_tape_cells: resd 1")
    EmitLine("ux_stack_cells: resd 1")
    EmitLine("ux_data_cells: resd 1")
    EmitLine("ux_queue_cells: resd 1")
    EmitLine("ux_stack_offset: resd 1")
    EmitLine("ux_data_offset: resd 1")
    EmitLine("ux_pragma_seed_enabled: resd 1")
    EmitLine("ux_pragma_seed_value: resd 1")
    EmitLine("ux_pragma_arge_json: resd 1")
    EmitLine("ux_pragma_arge_interpreter: resd 1")
    EmitLine("ux_pragma_arge_step: resd 1")
    EmitLine("ux_pragma_arge_trace: resd 1")
    EmitLine("ux_pragma_arge_watch: resd 1")
    EmitLine("section .text")
    EmitLine("uxm_entry:")
    EmitLine("    push rbp")
    EmitLine("    mov rbp, rsp")
    EmitLine("    push rbx")
    EmitLine("    push r12")
    EmitLine("    push r13")
    EmitLine("    push r14")
    EmitLine("    push r15")
    EmitLine("    sub rsp, 40")
    EmitLine("    mov dword [ux_cell_bits], CELL_BITS")
    EmitLine("    mov dword [ux_cell_bytes], CELL_BYTES")
    EmitLine("    mov dword [ux_tape_cells], TAPE_CELLS")
    EmitLine("    mov dword [ux_stack_cells], STACK_CELLS")
    EmitLine("    mov dword [ux_data_cells], DATA_CELLS")
    EmitLine("    mov dword [ux_queue_cells], QUEUE_CELLS")
    EmitLine("    mov dword [ux_stack_offset], STACK_OFFSET")
    EmitLine("    mov dword [ux_data_offset], DATA_OFFSET")
    EmitLine("    mov dword [ux_pragma_seed_enabled], "+LTrim(Str(PragmaSeedEnabled)))
    EmitLine("    mov dword [ux_pragma_seed_value], "+LTrim(Str(PragmaSeedValue)))
    EmitLine("    mov dword [ux_pragma_arge_json], "+LTrim(Str(PragmaArgeJson)))
    EmitLine("    mov dword [ux_pragma_arge_interpreter], "+LTrim(Str(PragmaArgeInterpreter)))
    EmitLine("    mov dword [ux_pragma_arge_step], "+LTrim(Str(PragmaArgeStep)))
    EmitLine("    mov dword [ux_pragma_arge_trace], "+LTrim(Str(PragmaArgeTrace)))
    EmitLine("    mov dword [ux_pragma_arge_watch], "+LTrim(Str(PragmaArgeWatch)))
    EmitLine("    lea r12, [ux_mem]")
    EmitLine("    xor rbx, rbx")
    EmitLine("    lea r13, [ux_mem + STACK_OFFSET]")
    EmitLine("    xor r14, r14")
    EmitLine("    mov qword [ux_ptr], rbx")
    EmitLine("    mov qword [ux_sp], r14")
    EmitLine("    mov byte [ux_status], 0")
    EmitLine("    mov word [ux_flags], 0")
    If BoundsOn Then EmitLine("    or word [ux_flags], FLAG_BND")
    If DefaultSigned Then EmitLine("    or word [ux_flags], FLAG_SGN")
    If DefaultBigEndian Then EmitLine("    or word [ux_flags], FLAG_END")
    If Mode=MODE_WILD Then EmitLine("    or word [ux_flags], FLAG_WILD")
End Sub

Sub EmitStringInitializers()
    Dim i As Long
    Dim j As Long
    Dim ch As Long
    Dim byteOff As Long
    If StrCount=0 Then Exit Sub
    EmitLine("    ; data string initializers")
    For i=1 To StrCount
        For j=1 To Len(StrText(i))
            ch=Asc(Mid(StrText(i),j,1)) And &HFF
            byteOff=DataOffset+(StrStart(i)+j-1)*CellSize()
            EmitLine("    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(byteOff))+"], "+LTrim(Str(ch)))
        Next j
        byteOff=DataOffset+(StrStart(i)+Len(StrText(i)))*CellSize()
        EmitLine("    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(byteOff))+"], 0")
    Next i
End Sub

Sub EmitAsmLabelIfNeeded(ByVal i As Long)
    If i>=1 And i<=MAX_LABELS Then
        If NeedLabel(i)<>0 Then EmitLine("__ux_ip_"+LTrim(Str(i))+":")
    End If
End Sub

Sub EmitInstr(ByVal i As Long)
    Dim idx As Long
    Select Case IOp(i)
        Case OP_RIGHT
            EmitLine("    ; "+IText(i))
            If IAmt(i)=1 Then EmitLine("    inc rbx") Else EmitLine("    add rbx, "+LTrim(Str(IAmt(i))))
            If BoundsOn Then EmitLine("    cmp rbx, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Case OP_LEFT
            EmitLine("    ; "+IText(i))
            If IAmt(i)=1 Then EmitLine("    dec rbx") Else EmitLine("    sub rbx, "+LTrim(Str(IAmt(i))))
            If BoundsOn Then EmitLine("    cmp rbx, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
        Case OP_INC
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    add rax, "+LTrim(Str(IAmt(i))))
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_DEC
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    sub rax, "+LTrim(Str(IAmt(i))))
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_CLEAR
            EmitLine("    ; "+IText(i))
            EmitLine("    xor rax, rax")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_PUTC
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    mov ecx, eax")
            EmitLine("    call ux_putc")
        Case OP_GETC
            EmitLine("    ; "+IText(i))
            EmitLine("    call ux_getc")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_PUSH
            EmitLine("    ; "+IText(i))
            EmitLine("    cmp r14, STACK_CELLS")
            EmitLine("    jae __ux_err_stack_over")
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            Select Case CellBits
                Case 8
                    EmitLine("    mov byte [r13 + r14], al")
                Case 16
                    EmitLine("    mov word [r13 + r14*2], ax")
                Case 32
                    EmitLine("    mov dword [r13 + r14*4], eax")
            End Select
            EmitLine("    inc r14")
        Case OP_POP
            EmitLine("    ; "+IText(i))
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    dec r14")
            Select Case CellBits
                Case 8
                    EmitLine("    movzx rax, byte [r13 + r14]")
                Case 16
                    EmitLine("    movzx rax, word [r13 + r14*2]")
                Case 32
                    EmitLine("    mov eax, dword [r13 + r14*4]")
            End Select
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_EQ,OP_GT,OP_LT,OP_AND,OP_OR,OP_XOR
            EmitLine("    ; "+IText(i))
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    dec r14")
            Select Case CellBits
                Case 8
                    EmitLine("    movzx r15, byte [r13 + r14]")
                Case 16
                    EmitLine("    movzx r15, word [r13 + r14*2]")
                Case 32
                    EmitLine("    mov r15d, dword [r13 + r14*4]")
            End Select
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            If IOp(i)=OP_EQ Then
                EmitLine("    cmp r15, rax")
                EmitLine("    sete al")
                EmitLine("    movzx rax, al")
            ElseIf IOp(i)=OP_GT Then
                EmitLine("    cmp r15, rax")
                EmitLine("    seta al")
                EmitLine("    movzx rax, al")
            ElseIf IOp(i)=OP_LT Then
                EmitLine("    cmp r15, rax")
                EmitLine("    setb al")
                EmitLine("    movzx rax, al")
            ElseIf IOp(i)=OP_AND Then
                EmitLine("    and rax, r15")
            ElseIf IOp(i)=OP_OR Then
                EmitLine("    or rax, r15")
            ElseIf IOp(i)=OP_XOR Then
                EmitLine("    xor rax, r15")
            End If
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_NOT
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    not rax")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_SHL
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    shl rax, 1")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_SHR
            EmitLine("    ; "+IText(i))
            EmitAddrLoad(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitLine("    shr rax, 1")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_STATUS
            EmitLine("    ; "+IText(i))
            EmitLine("    movzx rax, byte [ux_status]")
            EmitAddrStore(IAddrKind(i),IAddrVal(i),IAddrVal2(i),"rax")
            EmitSetFlagsFromRAX()
        Case OP_LOOP_BEG
            EmitLoopBegin(i)
        Case OP_LOOP_END
            EmitLoopEnd(i)
        Case OP_META
            EmitLine("    ; "+IText(i))
            EmitMetaCall(IMetaId(i),IMetaDyn(i),IMetaForce(i),IAddrKind(i),IAddrVal(i),IAddrVal2(i))
        Case OP_BRANCH
            EmitBranch(i)
        Case OP_PRINT_STRING
            idx=FindStringIndex(IAmt(i))
            EmitLine("    ; "+IText(i))
            EmitLine("    mov ecx, "+LTrim(Str(StrStart(idx))))
            EmitLine("    mov edx, CELL_BITS")
            EmitLine("    call ux_print_data_string")
        Case Else
            EmitLine("    nop")
    End Select
End Sub

Sub EmitAddrLoad(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
    EmitAddrPtr(addrKind,addrVal,addrVal2,"r11")
    Select Case CellBits
        Case 8
            EmitLine("    movzx "+regName+", byte [r11]")
        Case 16
            EmitLine("    movzx "+regName+", word [r11]")
        Case 32
            If LCase(regName)="rax" Then EmitLine("    mov eax, dword [r11]") Else EmitLine("    mov "+Reg32(regName)+", dword [r11]")
    End Select
End Sub

Sub EmitAddrStore(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
    EmitAddrPtr(addrKind,addrVal,addrVal2,"r11")
    Select Case CellBits
        Case 8
            EmitLine("    mov byte [r11], "+Reg8(regName))
        Case 16
            EmitLine("    mov word [r11], "+Reg16(regName))
        Case 32
            EmitLine("    mov dword [r11], "+Reg32(regName))
    End Select
End Sub

Sub EmitAddrPtr(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal outReg As String)
    Select Case addrKind
        Case ADDR_T
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rbx]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rbx*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rbx*4]")
            End Select
        Case ADDR_T_REL
            If BoundsOn Then
                EmitLine("    mov r10, rbx")
                If addrVal>=0 Then EmitLine("    add r10, "+LTrim(Str(addrVal))) Else EmitLine("    sub r10, "+LTrim(Str(Abs(addrVal))))
                EmitLine("    cmp r10, TAPE_CELLS")
                EmitLine("    jae __ux_err_ptr")
                Select Case CellBits
                    Case 8
                        EmitLine("    lea "+outReg+", [r12 + r10]")
                    Case 16
                        EmitLine("    lea "+outReg+", [r12 + r10*2]")
                    Case 32
                        EmitLine("    lea "+outReg+", [r12 + r10*4]")
                End Select
            Else
                Select Case CellBits
                    Case 8
                        If addrVal>=0 Then EmitLine("    lea "+outReg+", [r12 + rbx + "+LTrim(Str(addrVal))+"]") Else EmitLine("    lea "+outReg+", [r12 + rbx - "+LTrim(Str(Abs(addrVal)))+"]")
                    Case 16
                        If addrVal>=0 Then EmitLine("    lea "+outReg+", [r12 + rbx*2 + "+LTrim(Str(addrVal*2))+"]") Else EmitLine("    lea "+outReg+", [r12 + rbx*2 - "+LTrim(Str(Abs(addrVal*2)))+"]")
                    Case 32
                        If addrVal>=0 Then EmitLine("    lea "+outReg+", [r12 + rbx*4 + "+LTrim(Str(addrVal*4))+"]") Else EmitLine("    lea "+outReg+", [r12 + rbx*4 - "+LTrim(Str(Abs(addrVal*4)))+"]")
                End Select
            End If
        Case ADDR_T_ABS
            If BoundsOn Then
                If addrVal<0 Or addrVal>=TapeCells Then EmitLine("    jmp __ux_err_ptr")
            End If
            EmitLine("    lea "+outReg+", [r12 + "+LTrim(Str(addrVal*CellSize()))+"]")
        Case ADDR_D_ABS
            If BoundsOn Then
                If addrVal<0 Or addrVal>=DataCells Then EmitLine("    jmp __ux_err_data")
            End If
            EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + "+LTrim(Str(addrVal*CellSize()))+"]")
        Case ADDR_D_AT_T_REL
            EmitAddrLoad(ADDR_T,0,0,"rax")
            If addrVal2>=0 Then
                EmitLine("    add rax, "+LTrim(Str(addrVal2)))
            Else
                EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
            End If
            If BoundsOn Then EmitLine("    cmp rax, DATA_CELLS"):EmitLine("    jae __ux_err_data")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
            End Select
        Case ADDR_D_AT_TBASE_REL
            EmitAddrLoad(ADDR_T_REL,addrVal,0,"rax")
            If addrVal2>=0 Then
                EmitLine("    add rax, "+LTrim(Str(addrVal2)))
            Else
                EmitLine("    sub rax, "+LTrim(Str(Abs(addrVal2))))
            End If
            If BoundsOn Then EmitLine("    cmp rax, DATA_CELLS"):EmitLine("    jae __ux_err_data")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
            End Select
        Case ADDR_D_BASE_P
            EmitLine("    mov r10, rbx")
            If addrVal>=0 Then EmitLine("    add r10, "+LTrim(Str(addrVal))) Else EmitLine("    sub r10, "+LTrim(Str(Abs(addrVal))))
            If BoundsOn Then EmitLine("    cmp r10, DATA_CELLS"):EmitLine("    jae __ux_err_data")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + r10]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + r10*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + r10*4]")
            End Select
        Case ADDR_T_BASE_P
            EmitLine("    mov r10, rbx")
            If addrVal>=0 Then EmitLine("    add r10, "+LTrim(Str(addrVal))) Else EmitLine("    sub r10, "+LTrim(Str(Abs(addrVal))))
            If BoundsOn Then EmitLine("    cmp r10, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + r10]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + r10*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + r10*4]")
            End Select
        Case ADDR_D_AT_D_ABS
            EmitAddrLoad(ADDR_D_ABS,addrVal,0,"rax")
            If BoundsOn Then EmitLine("    cmp rax, DATA_CELLS"):EmitLine("    jae __ux_err_data")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + DATA_OFFSET + rax*4]")
            End Select
        Case ADDR_T_AT_D_ABS
            EmitAddrLoad(ADDR_D_ABS,addrVal,0,"rax")
            If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rax*4]")
            End Select
        Case ADDR_S_ABS
            If BoundsOn Then
                If addrVal<0 Or addrVal>=StackCells Then EmitLine("    jmp __ux_err_stack_over")
            End If
            EmitLine("    lea "+outReg+", [r13 + "+LTrim(Str(addrVal*CellSize()))+"]")
        Case ADDR_SP
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    mov r10, r14")
            EmitLine("    dec r10")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r13 + r10]")
                Case 16
                    EmitLine("    lea "+outReg+", [r13 + r10*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r13 + r10*4]")
            End Select
        Case ADDR_SP_REL
            EmitLine("    cmp r14, 0")
            EmitLine("    je __ux_err_stack_under")
            EmitLine("    mov r10, r14")
            EmitLine("    dec r10")
            If addrVal>=0 Then EmitLine("    add r10, "+LTrim(Str(addrVal))) Else EmitLine("    sub r10, "+LTrim(Str(Abs(addrVal))))
            If BoundsOn Then EmitLine("    cmp r10, STACK_CELLS"):EmitLine("    jae __ux_err_stack_over")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r13 + r10]")
                Case 16
                    EmitLine("    lea "+outReg+", [r13 + r10*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r13 + r10*4]")
            End Select
        Case ADDR_E
            EmitLine("    lea "+outReg+", [ux_status]")
        Case ADDR_F
            EmitLine("    lea "+outReg+", [ux_flags]")
        Case ADDR_P
            EmitLine("    lea "+outReg+", [ux_ptr]")
        Case ADDR_IND_T
            EmitAddrLoad(ADDR_T,0,0,"rax")
            If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rax*4]")
            End Select
        Case ADDR_IND_T_REL
            EmitAddrLoad(ADDR_T_REL,addrVal,0,"rax")
            If BoundsOn Then EmitLine("    cmp rax, TAPE_CELLS"):EmitLine("    jae __ux_err_ptr")
            Select Case CellBits
                Case 8
                    EmitLine("    lea "+outReg+", [r12 + rax]")
                Case 16
                    EmitLine("    lea "+outReg+", [r12 + rax*2]")
                Case 32
                    EmitLine("    lea "+outReg+", [r12 + rax*4]")
            End Select
        Case Else
            EmitLine("    lea "+outReg+", [r12 + rbx]")
    End Select
End Sub

Sub EmitSetFlagsFromRAX()
    Dim id As Long
    id=NewAsmId()
    EmitLine("    push rax")
    EmitLine("    mov dx, word [ux_flags]")
    EmitLine("    and dx, 0FFF0h")
    EmitLine("    cmp rax, 0")
    EmitLine("    jne __ux_noz_"+LTrim(Str(id)))
    EmitLine("    or dx, FLAG_Z")
    EmitLine("__ux_noz_"+LTrim(Str(id))+":")
    Select Case CellBits
        Case 8
            EmitLine("    test al, 80h")
        Case 16
            EmitLine("    test ax, 8000h")
        Case 32
            EmitLine("    test eax, 80000000h")
    End Select
    EmitLine("    jz __ux_nos_"+LTrim(Str(id)))
    EmitLine("    or dx, FLAG_S")
    EmitLine("__ux_nos_"+LTrim(Str(id))+":")
    EmitLine("    mov word [ux_flags], dx")
    EmitLine("    pop rax")
End Sub

Sub EmitMetaCall(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long)
    EmitLine("    mov qword [ux_ptr], rbx")
    EmitLine("    mov qword [ux_sp], r14")
    If dynamicFlag Then
        EmitAddrLoad(addrKind,addrVal,addrVal2,"rax")
        EmitLine("    mov ecx, eax")
    Else
        EmitLine("    mov ecx, "+LTrim(Str(metaId)))
    End If
    EmitLine("    lea rdx, [ux_mem]")
    EmitLine("    call ux_meta_call_ex")
    EmitLine("    mov rbx, qword [ux_ptr]")
    EmitLine("    mov r14, qword [ux_sp]")
End Sub

Sub EmitBranch(ByVal i As Long)
    Dim target As Long
    target=IBrTarget(i)
    EmitLine("    ; "+IText(i)+" -> __ux_ip_"+LTrim(Str(target)))
    Select Case IBrCond(i)
        Case BR_CUR_NZ
            EmitAddrLoad(ADDR_T,0,0,"rax")
            EmitLine("    cmp rax, 0")
            EmitLine("    jne __ux_ip_"+LTrim(Str(target)))
        Case BR_CUR_Z
            EmitAddrLoad(ADDR_T,0,0,"rax")
            EmitLine("    cmp rax, 0")
            EmitLine("    je __ux_ip_"+LTrim(Str(target)))
        Case BR_ALWAYS
            EmitLine("    jmp __ux_ip_"+LTrim(Str(target)))
        Case BR_Z_SET
            EmitLine("    test word [ux_flags], FLAG_Z")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_Z_CLR
            EmitLine("    test word [ux_flags], FLAG_Z")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
        Case BR_C_SET
            EmitLine("    test word [ux_flags], FLAG_C")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_C_CLR
            EmitLine("    test word [ux_flags], FLAG_C")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
        Case BR_O_SET
            EmitLine("    test word [ux_flags], FLAG_O")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_O_CLR
            EmitLine("    test word [ux_flags], FLAG_O")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
        Case BR_S_SET
            EmitLine("    test word [ux_flags], FLAG_S")
            EmitLine("    jnz __ux_ip_"+LTrim(Str(target)))
        Case BR_S_CLR
            EmitLine("    test word [ux_flags], FLAG_S")
            EmitLine("    jz __ux_ip_"+LTrim(Str(target)))
    End Select
End Sub

Sub EmitLoopBegin(ByVal i As Long)
    Dim id As Long
    id=LoopId(i)
    EmitLine("__ux_loop_beg_"+LTrim(Str(id))+":")
    EmitAddrLoad(ADDR_T,0,0,"rax")
    EmitLine("    cmp rax, 0")
    EmitLine("    je __ux_loop_end_"+LTrim(Str(id)))
End Sub

Sub EmitLoopEnd(ByVal i As Long)
    Dim id As Long
    id=LoopId(i)
    EmitLine("    jmp __ux_loop_beg_"+LTrim(Str(id)))
    EmitLine("__ux_loop_end_"+LTrim(Str(id))+":")
End Sub

Sub EmitFooter()
    EmitLine("__ux_ok_exit:")
    EmitLine("    add rsp, 40")
    EmitLine("    pop r15")
    EmitLine("    pop r14")
    EmitLine("    pop r13")
    EmitLine("    pop r12")
    EmitLine("    pop rbx")
    EmitLine("    pop rbp")
    EmitLine("    ret")
    EmitLine("__ux_err_ptr:")
    EmitLine("    mov byte [ux_status], 10")
    EmitLine("    mov ecx, 10")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
    EmitLine("__ux_err_stack_over:")
    EmitLine("    mov byte [ux_status], 11")
    EmitLine("    mov ecx, 11")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
    EmitLine("__ux_err_stack_under:")
    EmitLine("    mov byte [ux_status], 12")
    EmitLine("    mov ecx, 12")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
    EmitLine("__ux_err_data:")
    EmitLine("    mov byte [ux_status], 16")
    EmitLine("    mov ecx, 16")
    EmitLine("    call ux_runtime_error")
    EmitLine("    jmp __ux_ok_exit")
End Sub



