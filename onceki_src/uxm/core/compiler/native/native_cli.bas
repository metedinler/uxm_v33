' Auto-split by V3 modularization
Sub InitDefaults()
    CellBits=8
    TapeKB=UXM_DEFAULT_TAPE_KB
    StackKB=UXM_DEFAULT_STACK_KB
    DataKB=UXM_DEFAULT_DATA_KB
    QueueKB=UXM_DEFAULT_QUEUE_KB
    MemoryPolicy=UXM_MEMORY_POLICY_BOUNDED
    MemoryTotalLimitKB=UXM_MAX_TOTAL_KB
    Mode=MODE_NORMAL
    BoundsOn=1
    OverflowCheck=0
    DefaultSigned=0
    DefaultBigEndian=0
    PragmaSeedEnabled=0
    PragmaSeedValue=1
    PragmaArgeJson=0
    PragmaArgeInterpreter=0
    PragmaArgeStep=0
    PragmaArgeTrace=0
    PragmaArgeWatch=0
    ApplyMemoryModel()
End Sub

Sub ApplyMemoryModel()
    TapeBytes=TapeKB*1024
    StackBytes=StackKB*1024
    DataBytes=DataKB*1024
    QueueBytes=QueueKB*1024

    If CellBits<>8 And CellBits<>16 And CellBits<>32 Then
        HadError=1
        ErrMsg="HATA: cell byte/word/dword olmali."
        Exit Sub
    End If

    If TapeKB<=0 Or StackKB<=0 Or DataKB<=0 Or QueueKB<=0 Then
        HadError=1
        ErrMsg="HATA: #memory alanlari KB cinsinden 1 veya daha buyuk olmali. Tape="+Str(TapeKB)+" Stack="+Str(StackKB)+" Data="+Str(DataKB)+" Queue="+Str(QueueKB)
        Exit Sub
    End If

    If MemoryTotalLimitKB<=0 Or MemoryTotalLimitKB>UXM_MAX_TOTAL_KB Then MemoryTotalLimitKB=UXM_MAX_TOTAL_KB

    If MemoryPolicy=UXM_MEMORY_POLICY_BOUNDED Then
        If TapeKB>UXM_MAX_TAPE_KB Then
            HadError=1
            ErrMsg="HATA: tape bellek ust siniri " + Str(UXM_MAX_TAPE_KB) + " KB. Verilen="+Str(TapeKB)+" KB. Toplam-politika icin #memory policy=total kullan."
            Exit Sub
        End If
        If StackKB>UXM_MAX_STACK_KB Then
            HadError=1
            ErrMsg="HATA: stack bellek ust siniri " + Str(UXM_MAX_STACK_KB) + " KB. Verilen="+Str(StackKB)+" KB. Toplam-politika icin #memory policy=total kullan."
            Exit Sub
        End If
        If DataKB>UXM_MAX_DATA_KB Then
            HadError=1
            ErrMsg="HATA: data bellek ust siniri " + Str(UXM_MAX_DATA_KB) + " KB. Verilen="+Str(DataKB)+" KB. Toplam-politika icin #memory policy=total kullan."
            Exit Sub
        End If
        If QueueKB>UXM_MAX_QUEUE_KB Then
            HadError=1
            ErrMsg="HATA: queue/fifo bellek ust siniri " + Str(UXM_MAX_QUEUE_KB) + " KB. Verilen="+Str(QueueKB)+" KB. Toplam-politika icin #memory policy=total kullan."
            Exit Sub
        End If
    End If

    If TapeKB+StackKB+DataKB+QueueKB>MemoryTotalLimitKB Then
        HadError=1
        ErrMsg="HATA: toplam UXM bellek " + Str(MemoryTotalLimitKB) + " KB ust sinirini asiyor. Tape+Stack+Data+Queue="+Str(TapeKB+StackKB+DataKB+QueueKB)+" KB"
        Exit Sub
    End If

    StackOffset=TapeBytes
    DataOffset=TapeBytes+StackBytes
    TapeCells=TapeBytes\CellSize()
    StackCells=StackBytes\CellSize()
    DataCells=DataBytes\CellSize()
    QueueCells=QueueBytes\CellSize()
    If QueueCells<1 Then QueueCells=1
End Sub

Sub ReadFileToSrc(ByVal fileName As String)
    Dim ff As Integer
    Dim sz As Long
    If Len(Dir(fileName))=0 Then
        HadError=1
        ErrMsg="HATA: kaynak dosya bulunamadi: "+fileName
        Exit Sub
    End If
    ff=FreeFile
    Open fileName For Binary Access Read As #ff
    sz=Lof(ff)
    If sz>MAX_SRC Then
        Close #ff
        HadError=1
        ErrMsg="HATA: kaynak dosya cok buyuk."
        Exit Sub
    End If
    If sz>0 Then
        Src=Space(sz)
        Get #ff,,Src
    Else
        Src=""
    End If
    Close #ff
    Src=RemoveBOM(Src)
End Sub

Function RemoveBOM(ByVal s As String) As String
    If Len(s)>=3 Then
        If (Asc(Mid(s,1,1)) And &HFF)=&HEF And (Asc(Mid(s,2,1)) And &HFF)=&HBB And (Asc(Mid(s,3,1)) And &HFF)=&HBF Then
            RemoveBOM=Mid(s,4)
            Exit Function
        End If
    End If
    RemoveBOM=s
End Function

Sub ParsePragmas()
    Dim p As Long
    Dim startP As Long
    Dim lineText As String
    Dim low As String
    Dim v As String
    p=1
    Do While p<=Len(Src)
        startP=p
        Do While p<=Len(Src)
            If Mid(Src,p,1)=Chr(10) Then Exit Do
            p=p+1
        Loop
        lineText=Mid(Src,startP,p-startP)
        If Left(TrimAll(lineText),1)="#" Then
            low=LowerNoSpace(lineText)
            If InStr(low,"#mode")=1 Then
                If InStr(low,"safe")>0 Then Mode=MODE_SAFE
                If InStr(low,"normal")>0 Then Mode=MODE_NORMAL
                If InStr(low,"wild")>0 Then Mode=MODE_WILD
            ElseIf InStr(low,"#cell")=1 Then
                If InStr(low,"byte")>0 Then CellBits=8
                If InStr(low,"word")>0 Then CellBits=16
                If InStr(low,"dword")>0 Then CellBits=32
            ElseIf InStr(low,"#bounds")=1 Then
                If InStr(low,"off")>0 Then BoundsOn=0
                If InStr(low,"on")>0 Then BoundsOn=1
            ElseIf InStr(low,"#overflow")=1 Then
                If InStr(low,"check")>0 Then OverflowCheck=1
                If InStr(low,"wrap")>0 Then OverflowCheck=0
            ElseIf InStr(low,"#compare")=1 Then
                If InStr(low,"signed")>0 Then DefaultSigned=1
                If InStr(low,"unsigned")>0 Then DefaultSigned=0
            ElseIf InStr(low,"#endian")=1 Then
                If InStr(low,"big")>0 Then DefaultBigEndian=1
                If InStr(low,"little")>0 Then DefaultBigEndian=0
            ElseIf InStr(low,"#memory")=1 Then
                v=GetPragmaValue(low,"tape")
                If v<>"" Then TapeKB=ParseSizeKB(v,TapeKB)
                v=GetPragmaValue(low,"stack")
                If v<>"" Then StackKB=ParseSizeKB(v,StackKB)
                v=GetPragmaValue(low,"data")
                If v<>"" Then DataKB=ParseSizeKB(v,DataKB)
                v=GetPragmaValue(low,"queue")
                If v<>"" Then QueueKB=ParseSizeKB(v,QueueKB)
                v=GetPragmaValue(low,"fifo")
                If v<>"" Then QueueKB=ParseSizeKB(v,QueueKB)
                v=GetPragmaValue(low,"policy")
                If v<>"" Then
                    v=LCase(TrimAll(v))
                    If v="total" Or v="sum" Or v="toplam" Then MemoryPolicy=UXM_MEMORY_POLICY_TOTAL
                    If v="bounded" Or v="area" Or v="perarea" Or v="sinirli" Or v="ustsinir" Then MemoryPolicy=UXM_MEMORY_POLICY_BOUNDED
                End If
                v=GetPragmaValue(low,"limit")
                If v<>"" Then
                    v=LCase(TrimAll(v))
                    If v="total" Or v="sum" Or v="toplam" Then MemoryPolicy=UXM_MEMORY_POLICY_TOTAL
                    If v="bounded" Or v="area" Or v="perarea" Or v="sinirli" Or v="ustsinir" Then MemoryPolicy=UXM_MEMORY_POLICY_BOUNDED
                End If
                v=GetPragmaValue(low,"total")
                If v<>"" Then MemoryTotalLimitKB=ParseSizeKB(v,MemoryTotalLimitKB)
                v=GetPragmaValue(low,"max")
                If v<>"" Then MemoryTotalLimitKB=ParseSizeKB(v,MemoryTotalLimitKB)
            ElseIf InStr(low,"#seed")=1 Then
                v=TrimAll(Mid(lineText,6))
                If v="" Then
                    PragmaSeedValue=1
                Else
                    PragmaSeedValue=Val(v)
                End If
                PragmaSeedEnabled=1
            ElseIf InStr(low,"#arge")=1 Then
                If InStr(low,"json")>0 Then PragmaArgeJson=1
                If InStr(low,"interpreter")>0 Then PragmaArgeInterpreter=1
                If InStr(low,"step")>0 Then PragmaArgeStep=1
                If InStr(low,"trace")>0 Then PragmaArgeTrace=1
                If InStr(low,"watch")>0 Then PragmaArgeWatch=1
            ElseIf InStr(low,"#poly")=1 Or InStr(low,"#expr-rpn")=1 Then
                ParseArgeMathLine lineText
            ElseIf InStr(low,"#matrix")=1 Or InStr(low,"#identity")=1 Or InStr(low,"#zeros")=1 Or InStr(low,"#ones")=1 Then
                ParseArgeMatrixLine lineText
            End If
        End If
        p=p+1
    Loop
End Sub

Function LowerNoSpace(ByVal s As String) As String
    Dim i As Long
    Dim c As String
    Dim r As String
    r=""
    For i=1 To Len(s)
        c=LCase(Mid(s,i,1))
        If c<>" " And c<>Chr(9) And c<>Chr(13) Then r=r+c
    Next i
    LowerNoSpace=r
End Function

Function GetPragmaValue(ByVal lineText As String, ByVal keyName As String) As String
    Dim hitPos As Long
    Dim p As Long
    Dim r As String
    hitPos=InStr(lineText,keyName+"=")
    If hitPos=0 Then
        GetPragmaValue=""
        Exit Function
    End If
    p=hitPos+Len(keyName)+1
    r=""
    Do While p<=Len(lineText)
        If Mid(lineText,p,1)="," Then Exit Do
        r=r+Mid(lineText,p,1)
        p=p+1
    Loop
    GetPragmaValue=r
End Function

Function ParseSizeKB(ByVal s As String, ByVal defaultKB As Long) As Long
    Dim n As Long
    Dim raw As String
    raw=LCase(TrimAll(s))
    If raw="" Then ParseSizeKB=defaultKB:Exit Function
    n=Val(raw)
    If n<=0 Then
        ParseSizeKB=defaultKB
        Exit Function
    End If
    If InStr(raw,"mb")>0 Or InStr(raw,"m")=Len(raw) Then
        ParseSizeKB=n*1024
    Else
        ' Sayilar varsayilan olarak KB kabul edilir: tape=32 => 32 KB
        ParseSizeKB=n
    End If
End Function

