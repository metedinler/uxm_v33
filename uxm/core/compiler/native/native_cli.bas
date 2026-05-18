' Auto-split by V3 modularization
Dim Shared PreprocIncludeCount As Long
Dim Shared PreprocIncludeSeen(1 To 4096) As String
Dim Shared PreprocIncludeActiveSp As Long
Dim Shared PreprocIncludeActive(1 To 128) As String

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
    PragmaNoZeroVars=0
    PragmaSecStack=0
    PreprocPlatform="x64"
    PreprocDestOS="windows"
    PreprocIncludeCount=0
    PreprocIncludeActiveSp=0
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
            ErrMsg="HATA: tape bellek ust siniri " + Str(UXM_MAX_TAPE_KB) + " KB. Verilen="+Str(TapeKB)+" KB. UXM V7 toplam bellek siniri 16 MB; alanlari byte/kb/mb olarak ayarlayabilirsin."
            Exit Sub
        End If
        If StackKB>UXM_MAX_STACK_KB Then
            HadError=1
            ErrMsg="HATA: stack bellek ust siniri " + Str(UXM_MAX_STACK_KB) + " KB. Verilen="+Str(StackKB)+" KB. UXM V7 toplam bellek siniri 16 MB; alanlari byte/kb/mb olarak ayarlayabilirsin."
            Exit Sub
        End If
        If DataKB>UXM_MAX_DATA_KB Then
            HadError=1
            ErrMsg="HATA: data bellek ust siniri " + Str(UXM_MAX_DATA_KB) + " KB. Verilen="+Str(DataKB)+" KB. UXM V7 toplam bellek siniri 16 MB; alanlari byte/kb/mb olarak ayarlayabilirsin."
            Exit Sub
        End If
        If QueueKB>UXM_MAX_QUEUE_KB Then
            HadError=1
            ErrMsg="HATA: queue/fifo bellek ust siniri " + Str(UXM_MAX_QUEUE_KB) + " KB. Verilen="+Str(QueueKB)+" KB. UXM V7 toplam bellek siniri 16 MB; alanlari byte/kb/mb olarak ayarlayabilirsin."
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

Function GetDirName(ByVal fileName As String) As String
    Dim i As Long
    Dim c As String
    For i=Len(fileName) To 1 Step -1
        c=Mid(fileName,i,1)
        If c="\" Or c="/" Then
            GetDirName=Left(fileName,i-1)
            Exit Function
        End If
    Next i
    GetDirName=CurDir
End Function

Function ParseQuotedValue(ByVal s As String) As String
    Dim i As Long
    Dim j As Long
    i=InStr(s,Chr(34))
    If i=0 Then ParseQuotedValue="":Exit Function
    j=InStr(i+1,s,Chr(34))
    If j=0 Then ParseQuotedValue="":Exit Function
    ParseQuotedValue=Mid(s,i+1,j-i-1)
End Function

Function EvalPreprocExpr(ByVal expr As String) As Long
    Dim e As String
    Dim v As String
    e=LowerNoSpace(expr)
    If e="" Then EvalPreprocExpr=0:Exit Function
    If e="1" Or e="true" Then EvalPreprocExpr=-1:Exit Function
    If e="0" Or e="false" Then EvalPreprocExpr=0:Exit Function

    If Left(e,10)="platform==" Then
        v=Mid(e,11)
        If Left(v,1)=Chr(34) And Right(v,1)=Chr(34) And Len(v)>=2 Then v=Mid(v,2,Len(v)-2)
        EvalPreprocExpr=IIf(v=LCase(PreprocPlatform),-1,0)
        Exit Function
    End If
    If Left(e,9)="platform=" Then
        v=Mid(e,10)
        If Left(v,1)=Chr(34) And Right(v,1)=Chr(34) And Len(v)>=2 Then v=Mid(v,2,Len(v)-2)
        EvalPreprocExpr=IIf(v=LCase(PreprocPlatform),-1,0)
        Exit Function
    End If
    If Left(e,8)="destos==" Then
        v=Mid(e,9)
        If Left(v,1)=Chr(34) And Right(v,1)=Chr(34) And Len(v)>=2 Then v=Mid(v,2,Len(v)-2)
        EvalPreprocExpr=IIf(v=LCase(PreprocDestOS),-1,0)
        Exit Function
    End If
    If Left(e,7)="destos=" Then
        v=Mid(e,8)
        If Left(v,1)=Chr(34) And Right(v,1)=Chr(34) And Len(v)>=2 Then v=Mid(v,2,Len(v)-2)
        EvalPreprocExpr=IIf(v=LCase(PreprocDestOS),-1,0)
        Exit Function
    End If

    EvalPreprocExpr=0
End Function

Function PreprocIsActive(ByVal ifSp As Long, ByVal ifTake As Long Ptr) As Long
    Dim i As Long
    For i=0 To ifSp-1
        If ifTake[i]=0 Then PreprocIsActive=0:Exit Function
    Next i
    PreprocIsActive=-1
End Function

Function NormalizePathLower(ByVal fileName As String) As String
    Dim t As String
    Dim i As Long
    Dim c As String
    t=LCase(TrimAll(fileName))
    For i=1 To Len(t)
        c=Mid(t,i,1)
        If c="/" Then Mid(t,i,1)="\\"
    Next i
    NormalizePathLower=t
End Function

Function PreprocSeenInclude(ByVal normalizedFile As String) As Long
    Dim i As Long
    If normalizedFile="" Then PreprocSeenInclude=0:Exit Function
    For i=1 To PreprocIncludeCount
        If PreprocIncludeSeen(i)=normalizedFile Then
            PreprocSeenInclude=-1
            Exit Function
        End If
    Next i
    PreprocSeenInclude=0
End Function

Sub PreprocMarkInclude(ByVal normalizedFile As String)
    If normalizedFile="" Then Exit Sub
    If PreprocSeenInclude(normalizedFile)<>0 Then Exit Sub
    If PreprocIncludeCount<UBound(PreprocIncludeSeen) Then
        PreprocIncludeCount=PreprocIncludeCount+1
        PreprocIncludeSeen(PreprocIncludeCount)=normalizedFile
    End If
End Sub

Function PreprocIsActiveInclude(ByVal normalizedFile As String) As Long
    Dim i As Long
    If normalizedFile="" Then PreprocIsActiveInclude=0:Exit Function
    For i=1 To PreprocIncludeActiveSp
        If PreprocIncludeActive(i)=normalizedFile Then
            PreprocIsActiveInclude=-1
            Exit Function
        End If
    Next i
    PreprocIsActiveInclude=0
End Function

Sub PreprocPushActive(ByVal normalizedFile As String)
    If normalizedFile="" Then Exit Sub
    If PreprocIncludeActiveSp<UBound(PreprocIncludeActive) Then
        PreprocIncludeActiveSp=PreprocIncludeActiveSp+1
        PreprocIncludeActive(PreprocIncludeActiveSp)=normalizedFile
    End If
End Sub

Sub PreprocPopActive()
    If PreprocIncludeActiveSp>0 Then
        PreprocIncludeActive(PreprocIncludeActiveSp)=""
        PreprocIncludeActiveSp=PreprocIncludeActiveSp-1
    End If
End Sub

Function PreprocessExpand(ByVal text As String, ByVal currentDir As String, ByVal depth As Long) As String
    Dim p As Long
    Dim startP As Long
    Dim lineText As String
    Dim trimmed As String
    Dim low As String
    Dim outText As String
    Dim ifTake(1 To 64) As Long
    Dim ifParent(1 To 64) As Long
    Dim ifElseSeen(1 To 64) As Long
    Dim ifSp As Long
    Dim active As Long
    Dim parentActive As Long
    Dim expr As String
    Dim cond As Long
    Dim includeRel As String
    Dim includeAbs As String
    Dim includeNorm As String
    Dim includeText As String
    Dim ff As Integer
    Dim sz As Long
    Dim valText As String
    Dim msgText As String

    If depth>16 Then
        HadError=1
        ErrMsg="HATA: %%INCLUDE derinligi 16 seviyesini asti."
        PreprocessExpand=""
        Exit Function
    End If

    outText=""
    ifSp=0
    p=1
    Do While p<=Len(text)
        startP=p
        Do While p<=Len(text)
            If Mid(text,p,1)=Chr(10) Then Exit Do
            p=p+1
        Loop
        lineText=Mid(text,startP,p-startP)
        trimmed=TrimAll(lineText)
        low=LowerNoSpace(trimmed)

        If Left(low,4)="%%if" Then
            expr=TrimAll(Mid(trimmed,5))
            cond=EvalPreprocExpr(expr)
            parentActive=PreprocIsActive(ifSp,@ifTake(1))
            ifSp=ifSp+1
            If ifSp>64 Then
                HadError=1
                ErrMsg="HATA: %%IF nesting 64 seviyeyi asti."
                PreprocessExpand=""
                Exit Function
            End If
            ifParent(ifSp)=parentActive
            ifElseSeen(ifSp)=0
            If parentActive<>0 And cond<>0 Then ifTake(ifSp)=-1 Else ifTake(ifSp)=0
            p=p+1
            Continue Do
        End If

        If low="%%else" Then
            If ifSp<=0 Then
                HadError=1
                ErrMsg="HATA: %%ELSE icin acik %%IF bulunamadi."
                PreprocessExpand=""
                Exit Function
            End If
            If ifElseSeen(ifSp)<>0 Then
                HadError=1
                ErrMsg="HATA: Ayni %%IF blogunda birden fazla %%ELSE kullanildi."
                PreprocessExpand=""
                Exit Function
            End If
            ifElseSeen(ifSp)=-1
            If ifParent(ifSp)=0 Then
                ifTake(ifSp)=0
            Else
                If ifTake(ifSp)=0 Then ifTake(ifSp)=-1 Else ifTake(ifSp)=0
            End If
            p=p+1
            Continue Do
        End If

        If low="%%endif" Then
            If ifSp<=0 Then
                HadError=1
                ErrMsg="HATA: %%ENDIF icin acik %%IF bulunamadi."
                PreprocessExpand=""
                Exit Function
            End If
            ifSp=ifSp-1
            p=p+1
            Continue Do
        End If

        active=PreprocIsActive(ifSp,@ifTake(1))
        If active=0 Then
            p=p+1
            Continue Do
        End If

        If Left(low,9)="%%include" Then
            includeRel=ParseQuotedValue(trimmed)
            If includeRel="" Then
                HadError=1
                ErrMsg="HATA: %%INCLUDE icin ""dosya"" bekleniyor."
                PreprocessExpand=""
                Exit Function
            End If
            If (Len(includeRel)>=2 And Mid(includeRel,2,1)=":") Or Left(includeRel,2)="\\" Then
                includeAbs=includeRel
            ElseIf currentDir<>"" Then
                includeAbs=currentDir+"\"+includeRel
            Else
                includeAbs=includeRel
            End If
            includeNorm=NormalizePathLower(includeAbs)
            If PreprocIsActiveInclude(includeNorm)<>0 Then
                HadError=1
                ErrMsg="HATA: %%INCLUDE dongusu algilandi: "+includeAbs
                PreprocessExpand=""
                Exit Function
            End If
            If PreprocSeenInclude(includeNorm)<>0 Then
                p=p+1
                Continue Do
            End If
            PreprocMarkInclude(includeNorm)
            PreprocPushActive(includeNorm)
            If Len(Dir(includeAbs))=0 Then
                HadError=1
                ErrMsg="HATA: %%INCLUDE dosyasi bulunamadi: "+includeAbs
                PreprocessExpand=""
                Exit Function
            End If
            ff=FreeFile
            Open includeAbs For Binary Access Read As #ff
            sz=Lof(ff)
            If sz>MAX_SRC Then
                Close #ff
                HadError=1
                ErrMsg="HATA: %%INCLUDE dosyasi cok buyuk: "+includeAbs
                PreprocessExpand=""
                Exit Function
            End If
            If sz>0 Then
                includeText=Space(sz)
                Get #ff,,includeText
            Else
                includeText=""
            End If
            Close #ff
            includeText=RemoveBOM(includeText)
            includeText=PreprocessExpand(includeText,GetDirName(includeAbs),depth+1)
            PreprocPopActive()
            If HadError Then PreprocessExpand="":Exit Function
            outText=outText+includeText+Chr(10)
            p=p+1
            Continue Do
        End If

        If Left(LCase(trimmed),7)="include" Then
            If Len(trimmed)=7 Or IsSpaceChar(Mid(trimmed,8,1))<>0 Then
                includeRel=ParseQuotedValue(trimmed)
                If includeRel="" Then
                    HadError=1
                    ErrMsg="HATA: INCLUDE icin ""dosya"" bekleniyor."
                    PreprocessExpand=""
                    Exit Function
                End If
                If (Len(includeRel)>=2 And Mid(includeRel,2,1)=":") Or Left(includeRel,2)="\\" Then
                    includeAbs=includeRel
                ElseIf currentDir<>"" Then
                    includeAbs=currentDir+"\"+includeRel
                Else
                    includeAbs=includeRel
                End If
                includeNorm=NormalizePathLower(includeAbs)
                If PreprocIsActiveInclude(includeNorm)<>0 Then
                    HadError=1
                    ErrMsg="HATA: INCLUDE dongusu algilandi: "+includeAbs
                    PreprocessExpand=""
                    Exit Function
                End If
                If PreprocSeenInclude(includeNorm)<>0 Then
                    p=p+1
                    Continue Do
                End If
                PreprocMarkInclude(includeNorm)
                PreprocPushActive(includeNorm)
                If Len(Dir(includeAbs))=0 Then
                    HadError=1
                    ErrMsg="HATA: INCLUDE dosyasi bulunamadi: "+includeAbs
                    PreprocessExpand=""
                    Exit Function
                End If
                ff=FreeFile
                Open includeAbs For Binary Access Read As #ff
                sz=Lof(ff)
                If sz>MAX_SRC Then
                    Close #ff
                    HadError=1
                    ErrMsg="HATA: INCLUDE dosyasi cok buyuk: "+includeAbs
                    PreprocessExpand=""
                    Exit Function
                End If
                If sz>0 Then
                    includeText=Space(sz)
                    Get #ff,,includeText
                Else
                    includeText=""
                End If
                Close #ff
                includeText=RemoveBOM(includeText)
                includeText=PreprocessExpand(includeText,GetDirName(includeAbs),depth+1)
                PreprocPopActive()
                If HadError Then PreprocessExpand="":Exit Function
                outText=outText+includeText+Chr(10)
                p=p+1
                Continue Do
            End If
        End If

        If Left(low,10)="%%platform" Then
            valText=TrimAll(Mid(trimmed,11))
            If valText<>"" Then PreprocPlatform=LCase(valText)
            p=p+1
            Continue Do
        End If

        If Left(low,8)="%%destos" Then
            valText=TrimAll(Mid(trimmed,9))
            If valText<>"" Then PreprocDestOS=LCase(valText)
            p=p+1
            Continue Do
        End If

        If Left(low,12)="%%nozerovars" Then
            If InStr(low,"on")>0 Then PragmaNoZeroVars=1
            If InStr(low,"off")>0 Then PragmaNoZeroVars=0
            p=p+1
            Continue Do
        End If

        If Left(low,10)="%%secstack" Then
            If InStr(low,"on")>0 Then PragmaSecStack=1
            If InStr(low,"off")>0 Then PragmaSecStack=0
            p=p+1
            Continue Do
        End If

        If low="%%endcomp" Then
            Exit Do
        End If

        If Left(low,14)="%%errorendcomp" Then
            msgText=ParseQuotedValue(trimmed)
            If msgText="" Then msgText="%%ERRORENDCOMP tetiklendi."
            HadError=1
            ErrMsg="HATA: "+msgText
            PreprocessExpand=""
            Exit Function
        End If

        If Left(low,2)="%%" Then
            p=p+1
            Continue Do
        End If

        outText=outText+lineText+Chr(10)
        If Len(outText)>MAX_SRC Then
            HadError=1
            ErrMsg="HATA: preprocessor sonrasi kaynak boyutu limiti asti."
            PreprocessExpand=""
            Exit Function
        End If

        p=p+1
    Loop

    If ifSp<>0 Then
        HadError=1
        ErrMsg="HATA: kapanmamis %%IF blogu var."
        PreprocessExpand=""
        Exit Function
    End If

    PreprocessExpand=outText
End Function

Sub PreprocessSource(ByVal sourceFile As String)
    Dim rootNorm As String
    If HadError Then Exit Sub
    PreprocIncludeCount=0
    PreprocIncludeActiveSp=0
    rootNorm=NormalizePathLower(sourceFile)
    If rootNorm<>"" Then
        PreprocMarkInclude(rootNorm)
        PreprocPushActive(rootNorm)
    End If
    Src=PreprocessExpand(Src,GetDirName(sourceFile),0)
    If rootNorm<>"" Then PreprocPopActive()
End Sub

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
    Dim n As Double
    Dim raw As String
    Dim kb As Long
    Dim bytesVal As LongInt
    raw=LCase(TrimAll(s))
    If raw="" Then ParseSizeKB=defaultKB:Exit Function
    n=Val(raw)
    If n<=0 Then
        ParseSizeKB=defaultKB
        Exit Function
    End If

    ' UXM V7 memory unit parser:
    '   bare number => KB (legacy compatible)
    '   b / byte / bytes => byte, KB'ye yukari yuvarlanir
    '   k / kb / kbyte => KB
    '   m / mb / mbyte => MB
    If InStr(raw,"mb")>0 Or InStr(raw,"mbyte")>0 Or Right(raw,1)="m" Then
        kb=CLng(n*1024.0)
    ElseIf InStr(raw,"kb")>0 Or InStr(raw,"kbyte")>0 Or Right(raw,1)="k" Then
        kb=CLng(n)
    ElseIf InStr(raw,"byte")>0 Or (Right(raw,1)="b" And InStr(raw,"kb")=0 And InStr(raw,"mb")=0) Then
        bytesVal=CLngInt(n)
        kb=CLng((bytesVal+1023) \ 1024)
        If kb<1 Then kb=1
    Else
        ' Sayilar varsayilan olarak KB kabul edilir: tape=32 => 32 KB
        kb=CLng(n)
    End If

    If kb<1 Then kb=1
    ParseSizeKB=kb
End Function

