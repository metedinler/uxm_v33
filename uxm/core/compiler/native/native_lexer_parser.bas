' Auto-split by V3 modularization
Sub ParseProgram(ByRef code As String, ByVal depth As Long)
    Dim p As Long
    If depth>32 Then
        HadError=1
        ErrMsg="HATA: macro expansion derinligi 32'yi asti."
        Exit Sub
    End If
    p=1
    Do While p<=Len(code) And HadError=0
        If IsSpaceChar(Mid(code,p,1)) Then
            p=p+1
        ElseIf Mid(code,p,1)="#" Then
            SkipLine(code,p)
        ElseIf (Mid(code,p,1)="r" Or Mid(code,p,1)="R") And p+2<=Len(code) And LCase(Mid(code,p,3))="rem" Then
            If p+3>Len(code) Or IsSpaceChar(Mid(code,p+3,1)) Then
                SkipLine(code,p)
            Else
                ParseOneInstruction(code,p,depth)
            End If
        ElseIf Mid(code,p,1)="s" Or Mid(code,p,1)="S" Then
            ParseStringDef(code,p)
        ElseIf Mid(code,p,1)="m" Or Mid(code,p,1)="M" Then
            ParseMacroDef(code,p)
        Else
            ParseOneInstruction(code,p,depth)
        End If
    Loop
End Sub

Sub ParseOneInstruction(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim c As String
    Dim kind As Long
    Dim addrVal As Long
    Dim addrVal2 As Long
    Dim hasAddr As Long
    Dim amt As Long
    Dim ok As Long
    Dim startP As Long
    Dim c2 As String
    Dim p2 As Long
    Dim amt2 As Long
    Dim ok2 As Long
    startP=p
    c=Mid(code,p,1)
    If c="p" Or c="P" Then
        ParsePrintString(code,p)
        Exit Sub
    End If
    If c="@" Then
        ParseMeta(code,p,depth)
        Exit Sub
    End If
    If c=":" Then
        ParseBranch(code,p)
        Exit Sub
    End If
    If IsCommandChar(c)=0 Then
        SyntaxError("gecersiz komut karakteri: "+c,p)
        Exit Sub
    End If
    p=p+1
    kind=ADDR_T
    addrVal=0
    addrVal2=0
    amt=1
    If c="+" Or c="-" Then
        If p<=Len(code) Then
            If Mid(code,p,1)="k" Or Mid(code,p,1)="K" Then
                p=p+1
                amt=ParseUnsignedLong(code,p,ok)
                If ok=0 Then SyntaxError("k sonrasi sayi bekleniyor",p):Exit Sub
            End If
        End If
    End If
    hasAddr=ParseAddress(code,p,kind,addrVal,addrVal2)
    If HadError Then Exit Sub
    Select Case c
        Case ">"
            If hasAddr Then SyntaxError("> adresleme alamaz",startP):Exit Sub
            AddInstr(OP_RIGHT,amt,ADDR_T,0,0,Mid(code,startP,p-startP))
        Case "<"
            If hasAddr Then SyntaxError("< adresleme alamaz",startP):Exit Sub
            AddInstr(OP_LEFT,amt,ADDR_T,0,0,Mid(code,startP,p-startP))
        Case "+"
            AddInstr(OP_INC,amt,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "-"
            AddInstr(OP_DEC,amt,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "0"
            AddInstr(OP_CLEAR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
            If p<=Len(code) Then
                If Mid(code,p,1)="+" Or Mid(code,p,1)="-" Then
                    c2=Mid(code,p,1)
                    p2=p+1
                    amt2=1
                    ok2=0
                    If p2<=Len(code) Then
                        If Mid(code,p2,1)="k" Or Mid(code,p2,1)="K" Then
                            p2=p2+1
                            amt2=ParseUnsignedLong(code,p2,ok2)
                            If ok2=0 Then SyntaxError("0(addr)+kN kisminda sayi bekleniyor",p2):Exit Sub
                            If c2="+" Then
                                AddInstr(OP_INC,amt2,kind,addrVal,addrVal2,"+k"+LTrim(Str(amt2))+" inherit "+AddressText(kind,addrVal,addrVal2))
                            Else
                                AddInstr(OP_DEC,amt2,kind,addrVal,addrVal2,"-k"+LTrim(Str(amt2))+" inherit "+AddressText(kind,addrVal,addrVal2))
                            End If
                            p=p2
                        End If
                    End If
                End If
            End If
        Case "."
            AddInstr(OP_PUTC,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case ","
            AddInstr(OP_GETC,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "["
            If hasAddr Then SyntaxError("[ adresleme alamaz; loop aktif hucreye gore calisir",startP):Exit Sub
            AddInstr(OP_LOOP_BEG,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "]"
            If hasAddr Then SyntaxError("] adresleme alamaz",startP):Exit Sub
            AddInstr(OP_LOOP_END,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "$"
            AddInstr(OP_PUSH,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "%"
            AddInstr(OP_POP,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "?"
            AddInstr(OP_EQ,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "!"
            AddInstr(OP_GT,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case ";"
            AddInstr(OP_LT,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "&"
            AddInstr(OP_AND,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "|"
            AddInstr(OP_OR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "^"
            AddInstr(OP_XOR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "~"
            AddInstr(OP_NOT,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "{"
            AddInstr(OP_SHL,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "}"
            AddInstr(OP_SHR,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case "e","E"
            AddInstr(OP_STATUS,0,kind,addrVal,addrVal2,Mid(code,startP,p-startP))
        Case Else
            SyntaxError("beklenmeyen komut: "+c,startP)
    End Select
End Sub

Sub ParseStringDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim startCell As Long
    Dim txt As String
    p=p+1
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("sN taniminda N bekleniyor",p):Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError("sN taniminda '=' bekleniyor",p):Exit Sub
    p=p+1
    startCell=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("sN baslangic hucre no bekleniyor",p):Exit Sub
    If p>Len(code) Or Mid(code,p,1)<>"," Then SyntaxError("sN taniminda ',' bekleniyor",p):Exit Sub
    p=p+1
    txt=ParseBracedText(code,p,ok)
    If ok=0 Then SyntaxError("sN taniminda {metin} bekleniyor",p):Exit Sub
    AddStringDef(id,startCell,txt)
End Sub

Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim txt As String
    p=p+1
    Do While p<=Len(code) And IsSpaceChar(Mid(code,p,1))
        p=p+1
    Loop
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("mN taniminda N bekleniyor",p):Exit Sub
    If id<128 Or id>255 Then SyntaxError("mN kullanici macro id 128..255 araliginda olmali",p):Exit Sub
    Do While p<=Len(code) And IsSpaceChar(Mid(code,p,1))
        p=p+1
    Loop
    If p>Len(code) Or Mid(code,p,1)<>"=" Then SyntaxError("mN taniminda '=' bekleniyor",p):Exit Sub
    p=p+1
    Do While p<=Len(code) And IsSpaceChar(Mid(code,p,1))
        p=p+1
    Loop
    txt=ParseBracedText(code,p,ok)
    If ok=0 Then SyntaxError("mN taniminda {UXM kodu} bekleniyor",p):Exit Sub
    AddMacroDef(id,txt)
End Sub

Sub ParsePrintString(ByRef code As String, ByRef p As Long)
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim startP As Long
    startP=p
    p=p+1
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("pN komutunda N bekleniyor",p):Exit Sub
    idx=FindStringIndex(id)
    If idx=0 Then SyntaxError("tanimlanmamis string: p"+LTrim(Str(id)),startP):Exit Sub
    AddInstr(OP_PRINT_STRING,id,ADDR_T,0,0,Mid(code,startP,p-startP))
End Sub

Sub ParseBranch(ByRef code As String, ByRef p As Long)
    Dim startP As Long
    Dim cond As Long
    Dim brDir As Long
    Dim dist As Long
    Dim ok As Long
    Dim c As String
    startP=p
    p=p+1
    If p>Len(code) Then SyntaxError(": sonrasi branch govdesi bekleniyor",p):Exit Sub
    c=Mid(code,p,1)
    If c=":" Then
        cond=BR_ALWAYS
        p=p+1
    ElseIf c="0" Then
        cond=BR_CUR_Z
        p=p+1
    ElseIf c="z" Then
        cond=BR_Z_SET
        p=p+1
    ElseIf c="Z" Then
        cond=BR_Z_CLR
        p=p+1
    ElseIf c="c" Then
        cond=BR_C_SET
        p=p+1
    ElseIf c="C" Then
        cond=BR_C_CLR
        p=p+1
    ElseIf c="o" Then
        cond=BR_O_SET
        p=p+1
    ElseIf c="O" Then
        cond=BR_O_CLR
        p=p+1
    ElseIf c="s" Then
        cond=BR_S_SET
        p=p+1
    ElseIf c="S" Then
        cond=BR_S_CLR
        p=p+1
    ElseIf c="+" Or c="-" Then
        cond=BR_CUR_NZ
    Else
        SyntaxError("gecersiz branch tipi",p)
        Exit Sub
    End If
    If p>Len(code) Then SyntaxError("branch yonu bekleniyor",p):Exit Sub
    c=Mid(code,p,1)
    If c="+" Then
        brDir=1
    ElseIf c="-" Then
        brDir=-1
    Else
        SyntaxError("branch icin + veya - yonu bekleniyor",p)
        Exit Sub
    End If
    p=p+1
    dist=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("branch mesafesi bekleniyor",p):Exit Sub
    If dist<=0 Then SyntaxError("branch mesafesi 1 veya daha buyuk olmali",p):Exit Sub
    AddBranchInstr(cond,brDir,dist,Mid(code,startP,p-startP))
End Sub

Sub SkipLine(ByRef code As String, ByRef p As Long)
    Do While p<=Len(code)
        If Mid(code,p,1)=Chr(10) Then
            p=p+1
            Exit Sub
        End If
        p=p+1
    Loop
End Sub

Function ParseUnsignedLong(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
    Dim s As String
    s=""
    ok=0
    Do While p<=Len(code)
        If IsDigitChar(Mid(code,p,1))=0 Then Exit Do
        s=s+Mid(code,p,1)
        p=p+1
    Loop
    If Len(s)=0 Then
        ParseUnsignedLong=0
    Else
        ok=1
        ParseUnsignedLong=Val(s)
    End If
End Function

Function ParseBracedText(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
    Dim r As String
    Dim c As String
    Dim n As String
    r=""
    ok=0
    If p>Len(code) Then Exit Function
    If Mid(code,p,1)<>"{" Then Exit Function
    p=p+1
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If c="\" Then
            If p+1<=Len(code) Then
                n=Mid(code,p+1,1)
                Select Case n
                    Case "n"
                        r=r+Chr(10)
                    Case "r"
                        r=r+Chr(13)
                    Case "t"
                        r=r+Chr(9)
                    Case "{"
                        r=r+"{"
                    Case "}"
                        r=r+"}"
                    Case "\"
                        r=r+"\"
                    Case Else
                        r=r+n
                End Select
                p=p+2
            Else
                r=r+c
                p=p+1
            End If
        ElseIf c="}" Then
            p=p+1
            ok=1
            ParseBracedText=r
            Exit Function
        Else
            r=r+c
            p=p+1
        End If
    Loop
    ParseBracedText=r
End Function

