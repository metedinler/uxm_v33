' Auto-split by V3 modularization
Sub FirstPassDefinitions()
    Dim p As Long
    Dim c As String
    Dim lineStart As Long
    p=1
    Do While p<=Len(Src) And HadError=0
        c=Mid(Src,p,1)
        If IsSpaceChar(c) Then
            p=p+1
        ElseIf c="#" Then
            SkipLine(Src,p)
        ElseIf (c="r" Or c="R") And p+2<=Len(Src) And LCase(Mid(Src,p,3))="rem" Then
            If p+3>Len(Src) Or IsSpaceChar(Mid(Src,p+3,1)) Then
                SkipLine(Src,p)
            Else
                SkipLine(Src,p)
            End If
        ElseIf c="s" Or c="S" Then
            ParseStringDef(Src,p)
        ElseIf c="m" Or c="M" Then
            ParseMacroDef(Src,p)
        Else
            ' V3.3: First pass only collects top-level sN/mN definitions.
            ' Do not walk inside normal code, otherwise (SP-1) can be seen as sN.
            SkipLine(Src,p)
        End If
    Loop
End Sub

Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
    If InstrCount>=MAX_INSTR Then SyntaxError("instruction limiti doldu",1):Exit Sub
    InstrCount=InstrCount+1
    IOp(InstrCount)=op
    IAmt(InstrCount)=amount
    IAddrKind(InstrCount)=addrKind
    IAddrVal(InstrCount)=addrVal
    IAddrVal2(InstrCount)=addrVal2
    IText(InstrCount)=txt
End Sub

Sub AddBranchInstr(ByVal cond As Long, ByVal brDir As Long, ByVal dist As Long, ByVal txt As String)
    AddInstr(OP_BRANCH,0,ADDR_T,0,0,txt)
    IBrCond(InstrCount)=cond
    IBrDir(InstrCount)=brDir
    IBrDist(InstrCount)=dist
End Sub

Sub AddStringDef(ByVal id As Long, ByVal startCell As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To StrCount
        If StrId(i)=id Then Exit Sub
    Next i
    If StrCount>=MAX_STRINGS Then HadError=1:ErrMsg="HATA: string tablosu doldu.":Exit Sub
    StrCount=StrCount+1
    StrId(StrCount)=id
    StrStart(StrCount)=startCell
    StrText(StrCount)=txt
End Sub

Sub AddMacroDef(ByVal id As Long, ByVal txt As String)
    Dim i As Long
    For i=1 To MacroCount
        If MacroId(i)=id Then
            MacroText(i)=txt
            Exit Sub
        End If
    Next i
    If MacroCount>=MAX_MACROS Then HadError=1:ErrMsg="HATA: macro tablosu doldu.":Exit Sub
    MacroCount=MacroCount+1
    MacroId(MacroCount)=id
    MacroText(MacroCount)=txt
End Sub

Function FindStringIndex(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To StrCount
        If StrId(i)=id Then FindStringIndex=i:Exit Function
    Next i
    FindStringIndex=0
End Function

Function FindMacroIndex(ByVal id As Long) As Long
    Dim i As Long
    For i=1 To MacroCount
        If MacroId(i)=id Then FindMacroIndex=i:Exit Function
    Next i
    FindMacroIndex=0
End Function

Sub SyntaxError(ByVal msg As String, ByVal p As Long)
    HadError=1
    ErrMsg="SYNTAX ERROR @"+LTrim(Str(p))+": "+msg
End Sub

Function IsDigitChar(ByVal c As String) As Long
    If Len(c)=0 Then
        IsDigitChar=0
    ElseIf c>="0" And c<="9" Then
        IsDigitChar=1
    Else
        IsDigitChar=0
    End If
End Function

Function IsSpaceChar(ByVal c As String) As Long
    If c=" " Or c=Chr(9) Or c=Chr(10) Or c=Chr(13) Then IsSpaceChar=1 Else IsSpaceChar=0
End Function

Function IsCommandChar(ByVal c As String) As Long
    If InStr("><+-0.,[]$%?!;&|^~{}eE",c)>0 Then IsCommandChar=1 Else IsCommandChar=0
End Function

Function TrimAll(ByVal s As String) As String
    TrimAll=LTrim(RTrim(s))
End Function

Sub ValidateBranches()
    Dim i As Long
    Dim target As Long
    LoopSP=0
    LoopCounter=0
    For i=1 To InstrCount
        If IOp(i)=OP_LOOP_BEG Then
            LoopCounter=LoopCounter+1
            LoopId(i)=LoopCounter
            LoopSP=LoopSP+1
            If LoopSP>MAX_LOOP Then HadError=1:ErrMsg="HATA: loop stack doldu.":Exit Sub
            LoopStack(LoopSP)=i
        ElseIf IOp(i)=OP_LOOP_END Then
            If LoopSP<=0 Then HadError=1:ErrMsg="HATA: fazla ] bulundu.":Exit Sub
            LoopId(i)=LoopId(LoopStack(LoopSP))
            LoopSP=LoopSP-1
        End If
    Next i
    If LoopSP<>0 Then HadError=1:ErrMsg="HATA: kapanmamis [ var.":Exit Sub
    For i=1 To InstrCount
        If IOp(i)=OP_BRANCH Then
            target=i+(IBrDir(i)*IBrDist(i))
            If target<1 Or target>InstrCount Then HadError=1:ErrMsg="HATA: branch hedefi token disina cikiyor: "+IText(i):Exit Sub
            IBrTarget(i)=target
            NeedLabel(target)=1
        End If
    Next i
End Sub

