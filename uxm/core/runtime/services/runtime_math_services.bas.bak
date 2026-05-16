' UX-MATH V1 runtime services for uxm31_runtime_fb_full.bas
' Add routing inside ux_meta_call_ex:
' ElseIf metaId>=240 And metaId<=254 Then
'     MetaMathExtra metaId
' Declarations:
Declare Sub MetaPolynomial(ByVal metaId As ULongInt)
Declare Sub MetaExpression(ByVal metaId As ULongInt)
Declare Sub PolyDerivative(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
Declare Sub PolyIntegral(ByVal dstBase As LongInt, ByVal srcBase As LongInt, ByVal constantC As LongInt)
Declare Function PolyEval(ByVal srcBase As LongInt, ByVal x As LongInt) As LongInt
Declare Sub PolyPrint(ByVal srcBase As LongInt)
Declare Sub PolyClear(ByVal baseAddr As LongInt, ByVal count As LongInt)
Declare Function ReadPolyCoeff(ByVal baseAddr As LongInt, ByVal idx As LongInt) As LongInt
Declare Sub WritePolyCoeff(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
Declare Function ExprEval(ByVal exprBase As LongInt, ByVal x As LongInt) As LongInt
Declare Sub ExprPrintRpn(ByVal exprBase As LongInt)
Declare Function NumDeriv(ByVal exprBase As LongInt, ByVal x As LongInt, ByVal h As LongInt) As LongInt
Declare Function NumIntegralTrap(ByVal exprBase As LongInt, ByVal a As LongInt, ByVal b As LongInt, ByVal n As LongInt) As LongInt
Declare Function NumIntegralSimpson(ByVal exprBase As LongInt, ByVal a As LongInt, ByVal b As LongInt, ByVal n As LongInt) As LongInt
Sub MetaMathExtra(ByVal metaId As ULongInt)
    If metaId>=240 And metaId<=244 Then
        MetaPolynomial metaId
    ElseIf metaId>=250 And metaId<=254 Then
        MetaExpression metaId
    Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End If
End Sub
Sub MetaPolynomial(ByVal metaId As ULongInt)
    Dim dstBase As LongInt
    Dim srcBase As LongInt
    Dim param As LongInt
    Dim r As LongInt
    dstBase=CLngInt(Arg1())
    srcBase=CLngInt(Arg2())
    param=CLngInt(Arg0())
    Select Case metaId
    Case 240
        PolyDerivative dstBase,srcBase
        SetResult ux_status
    Case 241
        PolyIntegral dstBase,srcBase,param
        SetResult ux_status
    Case 242
        r=PolyEval(dstBase,srcBase)
        SetResult r
        SetLogicFlags ResultValue()
    Case 243
        PolyPrint srcBase
        SetResult ux_status
    Case 244
        PolyClear dstBase,srcBase
        SetResult ux_status
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
Function ReadPolyCoeff(ByVal baseAddr As LongInt, ByVal idx As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+4+idx))
End Function
Sub WritePolyCoeff(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
    WriteData baseAddr+4+idx,value
End Sub
Sub PolyDerivative(ByVal dstBase As LongInt, ByVal srcBase As LongInt)
    Dim deg As LongInt
    Dim scale As LongInt
    Dim i As LongInt
    Dim c As LongInt
    If ReadData(srcBase)<>80 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    deg=ReadData(srcBase+2)
    scale=ReadData(srcBase+3)
    WriteData dstBase+0,80
    WriteData dstBase+1,1
    If deg<=0 Then
        WriteData dstBase+2,0
        WriteData dstBase+3,scale
        WriteData dstBase+4,0
        SetStatus STATUS_OK
        Exit Sub
    End If
    WriteData dstBase+2,deg-1
    WriteData dstBase+3,scale
    For i=1 To deg
        c=ReadPolyCoeff(srcBase,i)
        WritePolyCoeff dstBase,i-1,c*i
    Next i
    SetStatus STATUS_OK
End Sub
Sub PolyIntegral(ByVal dstBase As LongInt, ByVal srcBase As LongInt, ByVal constantC As LongInt)
    Dim deg As LongInt
    Dim scale As LongInt
    Dim i As LongInt
    Dim c As LongInt
    Dim denom As LongInt
    If ReadData(srcBase)<>80 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    deg=ReadData(srcBase+2)
    scale=ReadData(srcBase+3)
    WriteData dstBase+0,80
    WriteData dstBase+1,1
    WriteData dstBase+2,deg+1
    WriteData dstBase+3,scale
    WritePolyCoeff dstBase,0,constantC
    For i=0 To deg
        c=ReadPolyCoeff(srcBase,i)
        denom=i+1
        WritePolyCoeff dstBase,i+1,c\denom
    Next i
    SetStatus STATUS_OK
End Sub
Function PolyEval(ByVal srcBase As LongInt, ByVal x As LongInt) As LongInt
    Dim deg As LongInt
    Dim i As LongInt
    Dim acc As LongInt
    If ReadData(srcBase)<>80 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    deg=ReadData(srcBase+2)
    acc=0
    For i=deg To 0 Step -1
        acc=acc*x+ReadPolyCoeff(srcBase,i)
    Next i
    SetStatus STATUS_OK
    Return acc
End Function
Sub PolyPrint(ByVal srcBase As LongInt)
    Dim deg As LongInt
    Dim i As LongInt
    Dim c As LongInt
    If ReadData(srcBase)<>80 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    deg=ReadData(srcBase+2)
    For i=0 To deg
        c=ReadPolyCoeff(srcBase,i)
        If i=0 Then
            Print LTrim(Str(c));
        Else
            Print " + ";LTrim(Str(c));"x";
            If i>1 Then Print "^";LTrim(Str(i));
        End If
    Next i
    SetStatus STATUS_OK
End Sub
Sub PolyClear(ByVal baseAddr As LongInt, ByVal count As LongInt)
    Dim i As LongInt
    For i=0 To count-1
        WriteData baseAddr+i,0
    Next i
    SetStatus STATUS_OK
End Sub
Sub MetaExpression(ByVal metaId As ULongInt)
    Dim exprBase As LongInt
    Dim x As LongInt
    Dim h As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim n As LongInt
    Dim r As LongInt
    Select Case metaId
    Case 250
        exprBase=CLngInt(Arg1())
        x=CLngInt(Arg2())
        r=ExprEval(exprBase,x)
        SetResult r
        SetLogicFlags ResultValue()
    Case 251
        exprBase=CLngInt(Arg1())
        x=CLngInt(Arg2())
        h=CLngInt(Arg0())
        r=NumDeriv(exprBase,x,h)
        SetResult r
        SetLogicFlags ResultValue()
    Case 252
        exprBase=CLngInt(ReadTape(CLngInt(ux_ptr)-4))
        a=CLngInt(ReadTape(CLngInt(ux_ptr)-3))
        b=CLngInt(ReadTape(CLngInt(ux_ptr)-2))
        n=CLngInt(ReadTape(CLngInt(ux_ptr)-1))
        r=NumIntegralTrap(exprBase,a,b,n)
        SetResult r
        SetLogicFlags ResultValue()
    Case 253
        exprBase=CLngInt(ReadTape(CLngInt(ux_ptr)-4))
        a=CLngInt(ReadTape(CLngInt(ux_ptr)-3))
        b=CLngInt(ReadTape(CLngInt(ux_ptr)-2))
        n=CLngInt(ReadTape(CLngInt(ux_ptr)-1))
        r=NumIntegralSimpson(exprBase,a,b,n)
        SetResult r
        SetLogicFlags ResultValue()
    Case 254
        exprBase=CLngInt(Arg2())
        ExprPrintRpn exprBase
        SetResult ux_status
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
Sub ExprPush(ByVal stack As Long Ptr, ByRef sp As LongInt, ByVal v As LongInt)
    sp=sp+1
    stack[sp]=v
End Sub
Function ExprPop(ByVal stack As Long Ptr, ByRef sp As LongInt) As LongInt
    If sp<=0 Then
        SetStatus STATUS_STACK_UNDERFLOW
        Return 0
    End If
    ExprPop=stack[sp]
    sp=sp-1
End Function
Function ExprEval(ByVal exprBase As LongInt, ByVal x As LongInt) As LongInt
    Dim tokenCount As LongInt
    Dim ip As LongInt
    Dim tok As LongInt
    Dim stack(0 To 255) As Long
    Dim sp As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim p As LongInt
    Dim r As LongInt
    If ReadData(exprBase)<>69 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    tokenCount=ReadData(exprBase+2)
    ip=exprBase+4
    sp=0
    Do
        tok=ReadData(ip)
        ip=ip+1
        Select Case tok
        Case 1
            ExprPush @stack(0),sp,CLngInt(ReadData(ip))
            ip=ip+1
        Case 2
            ExprPush @stack(0),sp,x
        Case 10
            b=ExprPop(@stack(0),sp):a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,a+b
        Case 11
            b=ExprPop(@stack(0),sp):a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,a-b
        Case 12
            b=ExprPop(@stack(0),sp):a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,a*b
        Case 13
            b=ExprPop(@stack(0),sp):a=ExprPop(@stack(0),sp)
            If b=0 Then SetStatus STATUS_DIV_ZERO:Return 0 Else ExprPush @stack(0),sp,a\b
        Case 14
            b=ExprPop(@stack(0),sp):a=ExprPop(@stack(0),sp)
            r=1
            For p=1 To b
                r=r*a
            Next p
            ExprPush @stack(0),sp,r
        Case 20
            a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,CLngInt(Sin(CDbl(a)*PI_D/180.0)*100.0)
        Case 21
            a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,CLngInt(Cos(CDbl(a)*PI_D/180.0)*100.0)
        Case 22
            a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,CLngInt(Tan(CDbl(a)*PI_D/180.0)*100.0)
        Case 23
            a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,CLngInt(Exp(CDbl(a)))
        Case 24
            a=ExprPop(@stack(0),sp):If a<=0 Then SetStatus STATUS_UNDERFLOW:Return 0 Else ExprPush @stack(0),sp,CLngInt(Log(CDbl(a)))
        Case 25
            a=ExprPop(@stack(0),sp):If a<0 Then SetStatus STATUS_UNDERFLOW:Return 0 Else ExprPush @stack(0),sp,CLngInt(Sqr(CDbl(a)))
        Case 30
            a=ExprPop(@stack(0),sp):ExprPush @stack(0),sp,-a
        Case 31
            a=ExprPop(@stack(0),sp):If a<0 Then a=-a
            ExprPush @stack(0),sp,a
        Case 99
            Exit Do
        Case Else
            SetStatus STATUS_INVALID_META
            Return 0
        End Select
        If ip>=exprBase+4+tokenCount+16 Then Exit Do
    Loop
    If sp<=0 Then SetStatus STATUS_STACK_UNDERFLOW:Return 0
    SetStatus STATUS_OK
    Return stack(sp)
End Function
Function NumDeriv(ByVal exprBase As LongInt, ByVal x As LongInt, ByVal h As LongInt) As LongInt
    Dim fp As LongInt
    Dim fm As LongInt
    If h=0 Then h=1
    fp=ExprEval(exprBase,x+h)
    fm=ExprEval(exprBase,x-h)
    NumDeriv=(fp-fm)\(2*h)
    SetStatus STATUS_OK
End Function
Function NumIntegralTrap(ByVal exprBase As LongInt, ByVal a As LongInt, ByVal b As LongInt, ByVal n As LongInt) As LongInt
    Dim h As LongInt
    Dim i As LongInt
    Dim x As LongInt
    Dim sum As LongInt
    If n<=0 Then SetStatus STATUS_DIV_ZERO:Return 0
    h=(b-a) \ n
    If h=0 Then h=1
    sum=(ExprEval(exprBase,a)+ExprEval(exprBase,b))\2
    For i=1 To n-1
        x=a+i*h
        sum=sum+ExprEval(exprBase,x)
    Next i
    SetStatus STATUS_OK
    Return sum*h
End Function
Function NumIntegralSimpson(ByVal exprBase As LongInt, ByVal a As LongInt, ByVal b As LongInt, ByVal n As LongInt) As LongInt
    Dim h As LongInt
    Dim i As LongInt
    Dim x As LongInt
    Dim sum As LongInt
    If n<=0 Or (n Mod 2)<>0 Then SetStatus STATUS_INVALID_META:Return 0
    h=(b-a) \ n
    If h=0 Then h=1
    sum=ExprEval(exprBase,a)+ExprEval(exprBase,b)
    For i=1 To n-1
        x=a+i*h
        If (i Mod 2)=0 Then
            sum=sum+2*ExprEval(exprBase,x)
        Else
            sum=sum+4*ExprEval(exprBase,x)
        End If
    Next i
    SetStatus STATUS_OK
    Return (sum*h)\3
End Function
Sub ExprPrintRpn(ByVal exprBase As LongInt)
    Dim tokenCount As LongInt
    Dim ip As LongInt
    Dim tok As LongInt
    If ReadData(exprBase)<>69 Then SetStatus STATUS_DATA_BOUNDS:Exit Sub
    tokenCount=ReadData(exprBase+2)
    ip=exprBase+4
    Do
        tok=ReadData(ip)
        ip=ip+1
        Select Case tok
        Case 1
            Print "CONST(";ReadData(ip);") ";
            ip=ip+1
        Case 2:Print "X ";
        Case 10:Print "ADD ";
        Case 11:Print "SUB ";
        Case 12:Print "MUL ";
        Case 13:Print "DIV ";
        Case 14:Print "POW ";
        Case 20:Print "SIN ";
        Case 21:Print "COS ";
        Case 22:Print "TAN ";
        Case 23:Print "EXP ";
        Case 24:Print "LOG ";
        Case 25:Print "SQRT ";
        Case 30:Print "NEG ";
        Case 31:Print "ABS ";
        Case 99:Print "END";:Exit Do
        Case Else:Print "? ";
        End Select
        If ip>=exprBase+4+tokenCount+16 Then Exit Do
    Loop
    SetStatus STATUS_OK
End Sub

