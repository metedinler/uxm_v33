' UX-FP V1 runtime services for uxm31_runtime_fb_full.bas
Declare Sub FPInit(ByVal baseAddr As LongInt, ByVal prec As LongInt)
Declare Sub FPZero(ByVal baseAddr As LongInt)
Declare Sub FPCopy(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Declare Sub FPFromInt(ByVal baseAddr As LongInt, ByVal value As LongInt)
Declare Sub FPFromDecString(ByVal baseAddr As LongInt, ByVal dataStart As LongInt)
Declare Sub FPToDecString(ByVal baseAddr As LongInt, ByVal dataStart As LongInt)
Declare Sub FPPrintDecimal(ByVal baseAddr As LongInt)
Declare Function FPFormatDecimal(ByVal baseAddr As LongInt) As String
Declare Function FPSignedExp(ByVal baseAddr As LongInt) As LongInt
Declare Sub FPSetSignedExp(ByVal baseAddr As LongInt, ByVal e As LongInt)
Declare Function FPMantissaString(ByVal baseAddr As LongInt) As String
Declare Sub FPStoreMantExp(ByVal baseAddr As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
Declare Sub FPRoundFrac(ByVal baseAddr As LongInt, ByVal prec As LongInt)
Declare Sub FPTrunc(ByVal baseAddr As LongInt)
Declare Function FPCompareAbs(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function FPCompare(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function BigTrim(ByVal s As String) As String
Declare Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
Declare Function BigAdd(ByVal a As String, ByVal b As String) As String
Declare Function BigSubAbs(ByVal a As String, ByVal b As String) As String
Declare Function BigMul(ByVal a As String, ByVal b As String) As String
Declare Function BigDivInt(ByVal numer As String, ByVal denom As String) As String
Declare Function BigShift10(ByVal s As String, ByVal n As LongInt) As String
Declare Function DataString(ByVal startCell As LongInt) As String
Declare Sub WriteDataString(ByVal startCell As LongInt, ByVal s As String)

Sub MetaFloatingPoint(ByVal metaId As ULongInt)
    Dim rBase As LongInt
    Dim aBase As LongInt
    Dim bBase As LongInt
    Dim aMant As String
    Dim bMant As String
    Dim rMant As String
    Dim expA As LongInt
    Dim expB As LongInt
    Dim expR As LongInt
    Dim signA As LongInt
    Dim signB As LongInt
    Dim signR As LongInt
    Dim cmp As LongInt
    Dim scaleDigits As LongInt
    Dim q As String
    rBase=CLngInt(Arg1())
    aBase=CLngInt(Arg2())
    bBase=CLngInt(Arg0())
    Select Case metaId
    Case 200
        FPInit rBase,16
        SetResult 0
    Case 201
        FPInit rBase,32
        SetResult 0
    Case 202
        FPZero rBase
        SetResult 0
    Case 203
        FPCopy rBase,aBase
        SetResult 0
    Case 204
        FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)
        SetResult 0
    Case 205
        SetResult FromSignedValue(CLngInt(Val(FPFormatDecimal(aBase))))
        SetLogicFlags ResultValue()
    Case 206
        If FPMantissaString(aBase)="0" Then
            SetResult 1
        Else
            SetResult 0
        End If
        SetLogicFlags ResultValue()
    Case 207
        If FPMantissaString(aBase)="0" Then
            SetResult 0
        ElseIf ReadData(aBase+2)<>0 Then
            SetResult CellMask()
        Else
            SetResult 1
        End If
        SetLogicFlags ResultValue()
    Case 208
        SetResult Abs(CLngInt(Val(FPFormatDecimal(aBase)))) And CellMask()
        SetLogicFlags ResultValue()
    Case 209
        Print "FP RAW baseAddr=";aBase;" sign=";ReadData(aBase+2);" exp=";FPSignedExp(aBase);" mant=";FPMantissaString(aBase)
        SetResult 0
    Case 210
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        If expA>expB Then
            aMant=BigShift10(aMant,expA-expB)
            expR=expB
        ElseIf expB>expA Then
            bMant=BigShift10(bMant,expB-expA)
            expR=expA
        Else
            expR=expA
        End If
        If signA=signB Then
            rMant=BigAdd(aMant,bMant)
            signR=signA
        Else
            cmp=BigCmp(aMant,bMant)
            If cmp=0 Then
                rMant="0"
                signR=0
                expR=0
            ElseIf cmp>0 Then
                rMant=BigSubAbs(aMant,bMant)
                signR=signA
            Else
                rMant=BigSubAbs(bMant,aMant)
                signR=signB
            End If
        End If
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 211
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2) Xor 1
        If expA>expB Then
            aMant=BigShift10(aMant,expA-expB)
            expR=expB
        ElseIf expB>expA Then
            bMant=BigShift10(bMant,expB-expA)
            expR=expA
        Else
            expR=expA
        End If
        If signA=signB Then
            rMant=BigAdd(aMant,bMant)
            signR=signA
        Else
            cmp=BigCmp(aMant,bMant)
            If cmp=0 Then
                rMant="0"
                signR=0
                expR=0
            ElseIf cmp>0 Then
                rMant=BigSubAbs(aMant,bMant)
                signR=signA
            Else
                rMant=BigSubAbs(bMant,aMant)
                signR=signB
            End If
        End If
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 212
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        rMant=BigMul(aMant,bMant)
        expR=expA+expB
        signR=signA Xor signB
        FPStoreMantExp rBase,signR,rMant,expR
        SetResult 0
    Case 213
        aMant=FPMantissaString(aBase)
        bMant=FPMantissaString(bBase)
        If bMant="0" Then
            WriteData rBase+6,4
            SetStatus STATUS_DIV_ZERO
            SetResult STATUS_DIV_ZERO
            Exit Sub
        End If
        expA=FPSignedExp(aBase)
        expB=FPSignedExp(bBase)
        signA=ReadData(aBase+2)
        signB=ReadData(bBase+2)
        If ReadData(rBase+1)=32 Then
            scaleDigits=64
        Else
            scaleDigits=32
        End If
        q=BigDivInt(BigShift10(aMant,scaleDigits),bMant)
        expR=expA-expB-scaleDigits
        signR=signA Xor signB
        FPStoreMantExp rBase,signR,q,expR
        If ReadData(rBase+1)=32 Then
            FPRoundFrac rBase,32
        Else
            FPRoundFrac rBase,16
        End If
        SetResult 0
    Case 214
        cmp=FPCompare(aBase,bBase)
        If cmp=0 Then
            SetResult 0
        ElseIf cmp>0 Then
            SetResult 1
        Else
            SetResult CellMask()
        End If
        SetLogicFlags ResultValue()
    Case 215
        FPCopy rBase,aBase
        WriteData rBase+2,0
        SetResult 0
    Case 216
        FPCopy rBase,aBase
        If FPMantissaString(rBase)<>"0" Then WriteData rBase+2,ReadData(rBase+2) Xor 1
        SetResult 0
    Case 217
        FPRoundFrac rBase,16
        SetResult 0
    Case 218
        FPRoundFrac rBase,32
        SetResult 0
    Case 219
        FPTrunc rBase
        SetResult 0
    Case 220
        FPFromInt rBase,aBase
        SetResult 0
    Case 221
        FPFromDecString rBase,aBase
        SetResult 0
    Case 222
        FPToDecString rBase,aBase
        SetResult 0
    Case 223
        FPPrintDecimal aBase
        SetResult 0
    Case 224
        FPStoreMantExp rBase,ReadData(rBase+2),FPMantissaString(rBase),FPSignedExp(rBase)+aBase
        SetResult 0
    Case 230,231,232,233,234
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub

Sub FPInit(ByVal baseAddr As LongInt, ByVal prec As LongInt)
    Dim maxCells As LongInt
    If prec=32 Then maxCells=40 Else maxCells=24
    If baseAddr<0 Or baseAddr+maxCells>=CLngInt(ux_data_cells) Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    WriteData baseAddr+0,70
    WriteData baseAddr+1,prec
    WriteData baseAddr+2,0
    WriteData baseAddr+3,0
    WriteData baseAddr+4,0
    WriteData baseAddr+5,1
    WriteData baseAddr+6,0
    WriteData baseAddr+7,0
    WriteData baseAddr+8,0
    SetStatus STATUS_OK
End Sub

Sub FPZero(ByVal baseAddr As LongInt)
    WriteData baseAddr+2,0
    WriteData baseAddr+3,0
    WriteData baseAddr+4,0
    WriteData baseAddr+5,1
    WriteData baseAddr+6,0
    WriteData baseAddr+8,0
    SetStatus STATUS_OK
End Sub

Sub FPCopy(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
    Dim prec As LongInt
    Dim maxCells As LongInt
    Dim i As LongInt
    prec=ReadData(srcBase+1)
    If prec=32 Then maxCells=40 Else maxCells=24
    If dstBase<0 Or srcBase<0 Or dstBase+maxCells>=CLngInt(ux_data_cells) Or srcBase+maxCells>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=0 To maxCells-1
        WriteData dstBase+i,ReadData(srcBase+i)
    Next i
    SetStatus STATUS_OK
End Sub

Sub FPFromInt(ByVal baseAddr As LongInt, ByVal value As LongInt)
    Dim sign As LongInt
    Dim v As LongInt
    Dim mant As String
    sign=0
    v=value
    If v<0 Then sign=1:v=-v
    mant=LTrim(Str(v))
    FPStoreMantExp baseAddr,sign,mant,0
End Sub

Function FPSignedExp(ByVal baseAddr As LongInt) As LongInt
    Dim es As LongInt
    Dim ea As LongInt
    es=ReadData(baseAddr+3)
    ea=ReadData(baseAddr+4)
    If es<>0 Then Return -ea
    Return ea
End Function

Sub FPSetSignedExp(ByVal baseAddr As LongInt, ByVal e As LongInt)
    If e<0 Then
        WriteData baseAddr+3,1
        WriteData baseAddr+4,Abs(e)
    Else
        WriteData baseAddr+3,0
        WriteData baseAddr+4,e
    End If
End Sub

Function FPMantissaString(ByVal baseAddr As LongInt) As String
    Dim used As LongInt
    Dim i As LongInt
    Dim limb As LongInt
    Dim s As String
    Dim part As String
    used=ReadData(baseAddr+5)
    If used<=0 Then Return "0"
    s=""
    For i=used-1 To 0 Step -1
        limb=ReadData(baseAddr+8+i)
        If i=used-1 Then
            s=s+LTrim(Str(limb))
        Else
            part=LTrim(Str(limb))
            If Len(part)=1 Then part="0"+part
            s=s+part
        End If
    Next i
    Return BigTrim(s)
End Function

Sub FPStoreMantExp(ByVal baseAddr As LongInt, ByVal sign As LongInt, ByVal mant As String, ByVal exp10 As LongInt)
    Dim prec As LongInt
    Dim maxLimbs As LongInt
    Dim maxDigits As LongInt
    Dim used As LongInt
    Dim i As LongInt
    Dim part As String
    Dim origMant As String
    mant=BigTrim(mant)
    Do While Len(mant)>1 And Right(mant,1)="0"
        mant=Left(mant,Len(mant)-1)
        exp10=exp10+1
    Loop
    origMant=mant
    prec=ReadData(baseAddr+1)
    If prec<>16 And prec<>32 Then prec=16
    If prec=16 Then maxLimbs=16 Else maxLimbs=32
    maxDigits=maxLimbs*2
    If Len(mant)>maxDigits Then
        mant=Left(mant,maxDigits)
        origMant=mant
        WriteData baseAddr+6,6
    Else
        WriteData baseAddr+6,0
    End If
    For i=0 To maxLimbs-1
        WriteData baseAddr+8+i,0
    Next i
    used=0
    Do While Len(mant)>0
        If Len(mant)>=2 Then
            part=Right(mant,2)
            mant=Left(mant,Len(mant)-2)
        Else
            part=mant
            mant=""
        End If
        WriteData baseAddr+8+used,Val(part)
        used=used+1
        If used>=maxLimbs Then Exit Do
    Loop
    If used=0 Then used=1
    WriteData baseAddr+0,70
    WriteData baseAddr+1,prec
    If BigTrim(origMant)="0" Then sign=0
    WriteData baseAddr+2,sign
    FPSetSignedExp baseAddr,exp10
    WriteData baseAddr+5,used
    SetStatus STATUS_OK
End Sub

Function DataString(ByVal startCell As LongInt) As String
    Dim s As String
    Dim i As LongInt
    Dim v As ULongInt
    s=""
    i=startCell
    Do While i>=0 And i<CLngInt(ux_data_cells)
        v=ReadData(i)
        If v=0 Then Exit Do
        s=s+Chr(v And &HFF)
        i=i+1
    Loop
    Return s
End Function

Sub WriteDataString(ByVal startCell As LongInt, ByVal s As String)
    Dim i As LongInt
    If startCell<0 Or startCell+Len(s)>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=1 To Len(s)
        WriteData startCell+i-1,Asc(Mid(s,i,1)) And &HFF
    Next i
    WriteData startCell+Len(s),0
    SetStatus STATUS_OK
End Sub

Sub FPFromDecString(ByVal baseAddr As LongInt, ByVal dataStart As LongInt)
    Dim s As String
    Dim i As LongInt
    Dim c As String
    Dim sign As LongInt
    Dim mant As String
    Dim fracCount As LongInt
    Dim afterDot As Long
    s=DataString(dataStart)
    s=Trim(s)
    sign=0
    mant=""
    fracCount=0
    afterDot=0
    If Left(s,1)="-" Then
        sign=1
        s=Mid(s,2)
    ElseIf Left(s,1)="+" Then
        s=Mid(s,2)
    End If
    For i=1 To Len(s)
        c=Mid(s,i,1)
        If c="." Or c="," Then
            afterDot=1
        ElseIf c>="0" And c<="9" Then
            mant=mant+c
            If afterDot<>0 Then fracCount=fracCount+1
        End If
    Next i
    If mant="" Then mant="0"
    FPStoreMantExp baseAddr,sign,mant,-fracCount
End Sub

Sub FPToDecString(ByVal baseAddr As LongInt, ByVal dataStart As LongInt)
    WriteDataString dataStart,FPFormatDecimal(baseAddr)
End Sub

Sub FPPrintDecimal(ByVal baseAddr As LongInt)
    Print FPFormatDecimal(baseAddr);
End Sub

Function FPFormatDecimal(ByVal baseAddr As LongInt) As String
    Dim mant As String
    Dim exp10 As LongInt
    Dim sign As LongInt
    Dim prec As LongInt
    Dim pointPos As LongInt
    Dim intPart As String
    Dim fracPart As String
    Dim outS As String
    mant=FPMantissaString(baseAddr)
    exp10=FPSignedExp(baseAddr)
    sign=ReadData(baseAddr+2)
    prec=ReadData(baseAddr+1)
    If prec<>16 And prec<>32 Then prec=16
    outS=""
    If sign<>0 And mant<>"0" Then outS="-"
    If exp10>=0 Then
        outS=outS+mant+String(exp10,"0")
        If prec>0 Then outS=outS+"."+String(prec,"0")
        FPFormatDecimal=outS
        Exit Function
    End If
    pointPos=Len(mant)+exp10
    If pointPos>0 Then
        intPart=Left(mant,pointPos)
        fracPart=Mid(mant,pointPos+1)
    Else
        intPart="0"
        fracPart=String(Abs(pointPos),"0")+mant
    End If
    If Len(fracPart)<prec Then fracPart=fracPart+String(prec-Len(fracPart),"0")
    If Len(fracPart)>prec Then fracPart=Left(fracPart,prec)
    outS=outS+intPart+"."+fracPart
    FPFormatDecimal=outS
End Function

Sub FPRoundFrac(ByVal baseAddr As LongInt, ByVal prec As LongInt)
    Dim mant As String
    Dim exp10 As LongInt
    Dim sign As LongInt
    Dim drop As LongInt
    Dim keepLen As LongInt
    Dim kept As String
    Dim nextDigit As LongInt
    mant=FPMantissaString(baseAddr)
    exp10=FPSignedExp(baseAddr)
    sign=ReadData(baseAddr+2)
    If exp10>=-prec Then
        WriteData baseAddr+1,prec
        Exit Sub
    End If
    drop=(-prec)-exp10
    If drop<=0 Then
        WriteData baseAddr+1,prec
        Exit Sub
    End If
    If drop>=Len(mant) Then
        mant="0"
        exp10=-prec
        FPStoreMantExp baseAddr,0,mant,exp10
        WriteData baseAddr+1,prec
        Exit Sub
    End If
    keepLen=Len(mant)-drop
    kept=Left(mant,keepLen)
    nextDigit=Val(Mid(mant,keepLen+1,1))
    If nextDigit>=5 Then kept=BigAdd(kept,"1")
    exp10=exp10+drop
    FPStoreMantExp baseAddr,sign,kept,exp10
    WriteData baseAddr+1,prec
    SetStatus STATUS_OK
End Sub

Sub FPTrunc(ByVal baseAddr As LongInt)
    Dim mant As String
    Dim exp10 As LongInt
    Dim sign As LongInt
    Dim drop As LongInt
    Dim keepLen As LongInt
    mant=FPMantissaString(baseAddr)
    exp10=FPSignedExp(baseAddr)
    sign=ReadData(baseAddr+2)
    If exp10>=0 Then Exit Sub
    drop=-exp10
    If drop>=Len(mant) Then
        FPStoreMantExp baseAddr,0,"0",0
        Exit Sub
    End If
    keepLen=Len(mant)-drop
    mant=Left(mant,keepLen)
    FPStoreMantExp baseAddr,sign,mant,0
    SetStatus STATUS_OK
End Sub

Function FPCompareAbs(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
    Dim aMant As String
    Dim bMant As String
    Dim expA As LongInt
    Dim expB As LongInt
    aMant=FPMantissaString(aBase)
    bMant=FPMantissaString(bBase)
    expA=FPSignedExp(aBase)
    expB=FPSignedExp(bBase)
    If expA>expB Then
        aMant=BigShift10(aMant,expA-expB)
    ElseIf expB>expA Then
        bMant=BigShift10(bMant,expB-expA)
    End If
    Return BigCmp(aMant,bMant)
End Function

Function FPCompare(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
    Dim signA As LongInt
    Dim signB As LongInt
    Dim cmp As LongInt
    signA=ReadData(aBase+2)
    signB=ReadData(bBase+2)
    If FPMantissaString(aBase)="0" And FPMantissaString(bBase)="0" Then Return 0
    If signA=0 And signB<>0 Then Return 1
    If signA<>0 And signB=0 Then Return -1
    cmp=FPCompareAbs(aBase,bBase)
    If signA<>0 Then cmp=-cmp
    Return cmp
End Function

Function BigTrim(ByVal s As String) As String
    Do While Len(s)>1 And Left(s,1)="0"
        s=Mid(s,2)
    Loop
    If s="" Then s="0"
    Return s
End Function

Function BigShift10(ByVal s As String, ByVal n As LongInt) As String
    s=BigTrim(s)
    If s="0" Then Return "0"
    If n<=0 Then Return s
    Return s+String(n,"0")
End Function

Function BigCmp(ByVal a As String, ByVal b As String) As LongInt
    a=BigTrim(a)
    b=BigTrim(b)
    If Len(a)>Len(b) Then Return 1
    If Len(a)<Len(b) Then Return -1
    If a>b Then Return 1
    If a<b Then Return -1
    Return 0
End Function

Function BigAdd(ByVal a As String, ByVal b As String) As String
    Dim ia As LongInt
    Dim ib As LongInt
    Dim carry As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim sum As LongInt
    Dim r As String
    a=BigTrim(a)
    b=BigTrim(b)
    ia=Len(a)
    ib=Len(b)
    carry=0
    r=""
    Do While ia>0 Or ib>0 Or carry>0
        da=0
        db=0
        If ia>0 Then da=Val(Mid(a,ia,1)):ia=ia-1
        If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
        sum=da+db+carry
        r=Chr(48+(sum Mod 10))+r
        carry=sum\10
    Loop
    Return BigTrim(r)
End Function

Function BigSubAbs(ByVal a As String, ByVal b As String) As String
    Dim ia As LongInt
    Dim ib As LongInt
    Dim borrow As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim d As LongInt
    Dim r As String
    If BigCmp(a,b)<0 Then Return "0"
    a=BigTrim(a)
    b=BigTrim(b)
    ia=Len(a)
    ib=Len(b)
    borrow=0
    r=""
    Do While ia>0
        da=Val(Mid(a,ia,1))-borrow
        db=0
        If ib>0 Then db=Val(Mid(b,ib,1)):ib=ib-1
        If da<db Then
            da=da+10
            borrow=1
        Else
            borrow=0
        End If
        d=da-db
        r=Chr(48+d)+r
        ia=ia-1
    Loop
    Return BigTrim(r)
End Function

Function BigMul(ByVal a As String, ByVal b As String) As String
    Dim la As LongInt
    Dim lb As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim ai As LongInt
    Dim bj As LongInt
    Dim p As LongInt
    Dim carry As LongInt
    Dim arr(0 To 511) As LongInt
    Dim r As String
    a=BigTrim(a)
    b=BigTrim(b)
    If a="0" Or b="0" Then Return "0"
    la=Len(a)
    lb=Len(b)
    For i=0 To 511
        arr(i)=0
    Next i
    For i=la To 1 Step -1
        ai=Val(Mid(a,i,1))
        carry=0
        For j=lb To 1 Step -1
            bj=Val(Mid(b,j,1))
            p=(la-i)+(lb-j)
            arr(p)=arr(p)+ai*bj+carry
            carry=arr(p)\10
            arr(p)=arr(p) Mod 10
        Next j
        p=(la-i)+lb
        Do While carry>0
            arr(p)=arr(p)+carry
            carry=arr(p)\10
            arr(p)=arr(p) Mod 10
            p=p+1
        Loop
    Next i
    r=""
    For i=511 To 0 Step -1
        If r<>"" Or arr(i)<>0 Then r=r+Chr(48+arr(i))
    Next i
    If r="" Then r="0"
    Return BigTrim(r)
End Function

Function BigDivInt(ByVal numer As String, ByVal denom As String) As String
    Dim i As LongInt
    Dim digit As LongInt
    Dim rems As String
    Dim q As String
    Dim c As String
    numer=BigTrim(numer)
    denom=BigTrim(denom)
    If denom="0" Then Return "0"
    If BigCmp(numer,denom)<0 Then Return "0"
    rems="0"
    q=""
    For i=1 To Len(numer)
        c=Mid(numer,i,1)
        If rems="0" Then
            rems=c
        Else
            rems=rems+c
        End If
        rems=BigTrim(rems)
        digit=0
        Do While BigCmp(rems,denom)>=0
            rems=BigSubAbs(rems,denom)
            digit=digit+1
        Loop
        q=q+Chr(48+digit)
    Next i
    Return BigTrim(q)
End Function

