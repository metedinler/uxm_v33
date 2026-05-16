
' UXM V19 - Remaining real statistics / probability / numeric services
' Meta range handled here: @274..@280 and @283..@289
' This file is intended to be included from uxm31_runtime_fb_full.bas.

Declare Sub MetaStatsNumericV19(ByVal metaId As ULongInt)
Declare Function V19DataLong(ByVal idx As LongInt) As LongInt
Declare Sub V19SetLongResult(ByVal v As LongInt)
Declare Function V19MedianSorted(ByRef arr() As LongInt, ByVal n As LongInt) As LongInt
Declare Sub V19SortLong(ByRef arr() As LongInt, ByVal n As LongInt)
Declare Function V19Comb(ByVal n As LongInt, ByVal k As LongInt) As Double
Declare Function V19NormalCdf(ByVal z As Double) As Double

Function V19DataLong(ByVal idx As LongInt) As LongInt
    Return CLngInt(ReadData(idx))
End Function

Sub V19SetLongResult(ByVal v As LongInt)
    SetResult ClampToCell(v)
    SetLogicFlags ResultValue()
End Sub

Sub V19SortLong(ByRef arr() As LongInt, ByVal n As LongInt)
    Dim i As LongInt, j As LongInt, t As LongInt
    If n<=1 Then Exit Sub
    For i=0 To n-2
        For j=i+1 To n-1
            If arr(j)<arr(i) Then
                t=arr(i): arr(i)=arr(j): arr(j)=t
            End If
        Next j
    Next i
End Sub

Function V19MedianSorted(ByRef arr() As LongInt, ByVal n As LongInt) As LongInt
    If n<=0 Then Return 0
    If (n Mod 2)=1 Then
        Return arr(n\2)
    Else
        Return (arr(n\2-1)+arr(n\2))\2
    End If
End Function

Function V19Comb(ByVal n As LongInt, ByVal k As LongInt) As Double
    Dim i As LongInt
    Dim r As Double
    If k<0 Or k>n Then Return 0.0
    If k>n-k Then k=n-k
    r=1.0
    For i=1 To k
        r=r*CDbl(n-k+i)/CDbl(i)
    Next i
    Return r
End Function

Function V19NormalCdf(ByVal z As Double) As Double
    ' Abramowitz-Stegun style approximation for normal CDF.
    Dim t As Double, d As Double, p As Double
    Dim signv As Long
    signv=1
    If z<0 Then signv=-1: z=-z
    t=1.0/(1.0+0.2316419*z)
    d=0.3989422804014327*Exp(-z*z/2.0)
    p=1.0-d*t*(0.319381530+t*(-0.356563782+t*(1.781477937+t*(-1.821255978+t*1.330274429))))
    If signv<0 Then p=1.0-p
    If p<0 Then p=0
    If p>1 Then p=1
    Return p
End Function

Sub MetaStatsNumericV19(ByVal metaId As ULongInt)
    Dim baseAddr As LongInt, n As LongInt, i As LongInt, j As LongInt
    Dim a As LongInt, b As LongInt, c As LongInt
    Dim mn As LongInt, mx As LongInt, v As LongInt
    Dim vals(0 To 511) As LongInt
    Dim vals2(0 To 511) As LongInt
    Dim countBest As LongInt, bestVal As LongInt, cnt As LongInt
    Dim med As LongInt
    Dim sumX As Double, sumY As Double, meanX As Double, meanY As Double, cov As Double
    Dim prodLog As Double, invSum As Double
    Dim x As Double, mu As Double, sigma As Double, pdf As Double, cdf As Double
    Dim k As LongInt, nn As LongInt, p As Double, lam As Double, pmf As Double
    Dim denom As LongInt

    a=CLngInt(Arg1())
    b=CLngInt(Arg2())
    c=CLngInt(Arg0())

    Select Case metaId
    Case 274 ' STAT_MODE: a=base, b=count
        baseAddr=a: n=b
        If n<=0 Or n>512 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        For i=0 To n-1: vals(i)=V19DataLong(baseAddr+i): Next i
        bestVal=vals(0): countBest=0
        For i=0 To n-1
            cnt=0
            For j=0 To n-1
                If vals(j)=vals(i) Then cnt=cnt+1
            Next j
            If cnt>countBest Then countBest=cnt: bestVal=vals(i)
        Next i
        SetStatus STATUS_OK: V19SetLongResult bestVal

    Case 275 ' STAT_RANGE: a=base, b=count
        baseAddr=a: n=b
        If n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        mn=V19DataLong(baseAddr): mx=mn
        For i=1 To n-1
            v=V19DataLong(baseAddr+i)
            If v<mn Then mn=v
            If v>mx Then mx=v
        Next i
        SetStatus STATUS_OK: V19SetLongResult mx-mn

    Case 276 ' STAT_IQR: a=base, b=count
        baseAddr=a: n=b
        If n<4 Or n>512 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        For i=0 To n-1: vals(i)=V19DataLong(baseAddr+i): Next i
        V19SortLong vals(),n
        Dim q1 As LongInt, q3 As LongInt
        q1=vals(n\4)
        q3=vals((3*n)\4)
        SetStatus STATUS_OK: V19SetLongResult q3-q1

    Case 277 ' STAT_MAD: a=base, b=count
        baseAddr=a: n=b
        If n<=0 Or n>512 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        For i=0 To n-1: vals(i)=V19DataLong(baseAddr+i): Next i
        V19SortLong vals(),n
        med=V19MedianSorted(vals(),n)
        For i=0 To n-1
            vals2(i)=Abs(V19DataLong(baseAddr+i)-med)
        Next i
        V19SortLong vals2(),n
        SetStatus STATUS_OK: V19SetLongResult V19MedianSorted(vals2(),n)

    Case 278 ' STAT_GEOMEAN: a=base, b=count
        baseAddr=a: n=b
        If n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        prodLog=0.0
        For i=0 To n-1
            v=V19DataLong(baseAddr+i)
            If v<=0 Then SetStatus STATUS_UNDERFLOW: SetResult 0: Exit Sub
            prodLog=prodLog+Log(CDbl(v))
        Next i
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(Exp(prodLog/CDbl(n))+0.5))

    Case 279 ' STAT_HARMEAN: a=base, b=count
        baseAddr=a: n=b
        If n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        invSum=0.0
        For i=0 To n-1
            v=V19DataLong(baseAddr+i)
            If v<=0 Then SetStatus STATUS_UNDERFLOW: SetResult 0: Exit Sub
            invSum=invSum+1.0/CDbl(v)
        Next i
        If invSum=0.0 Then SetStatus STATUS_DIV_ZERO: SetResult 0: Exit Sub
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(CDbl(n)/invSum+0.5))

    Case 280 ' STAT_COVARIANCE: a=xBase, b=yBase, c=count
        n=c
        If n<2 Or n>512 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        sumX=0.0: sumY=0.0
        For i=0 To n-1
            sumX=sumX+CDbl(V19DataLong(a+i))
            sumY=sumY+CDbl(V19DataLong(b+i))
        Next i
        meanX=sumX/CDbl(n): meanY=sumY/CDbl(n)
        cov=0.0
        For i=0 To n-1
            cov=cov+(CDbl(V19DataLong(a+i))-meanX)*(CDbl(V19DataLong(b+i))-meanY)
        Next i
        cov=cov/CDbl(n-1)
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(cov+0.5))

    Case 283 ' NORMAL_PDF_SCALED: a=xMilli, b=muMilli, c=sigmaMilli, result=pdf*1000000
        If c<=0 Then SetStatus STATUS_DIV_ZERO: SetResult 0: Exit Sub
        x=CDbl(a)/1000.0: mu=CDbl(b)/1000.0: sigma=CDbl(c)/1000.0
        pdf=(1.0/(sigma*Sqr(2.0*PI_D)))*Exp(-0.5*((x-mu)/sigma)*((x-mu)/sigma))
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(pdf*1000000.0+0.5))

    Case 284 ' NORMAL_CDF_SCALED: a=xMilli, b=muMilli, c=sigmaMilli, result=cdf*1000000
        If c<=0 Then SetStatus STATUS_DIV_ZERO: SetResult 0: Exit Sub
        x=CDbl(a)/1000.0: mu=CDbl(b)/1000.0: sigma=CDbl(c)/1000.0
        cdf=V19NormalCdf((x-mu)/sigma)
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(cdf*1000000.0+0.5))

    Case 285 ' BINOM_PMF_SCALED: a=k, b=pPermille, c=n, result=pmf*1000000
        k=a: nn=c
        If nn<0 Or k<0 Or k>nn Or b<0 Or b>1000 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        p=CDbl(b)/1000.0
        pmf=V19Comb(nn,k)*(p^k)*((1.0-p)^(nn-k))
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(pmf*1000000.0+0.5))

    Case 286 ' POISSON_PMF_SCALED: a=k, b=lambdaMilli, result=pmf*1000000
        k=a
        If k<0 Or b<0 Then SetStatus STATUS_DATA_BOUNDS: SetResult 0: Exit Sub
        lam=CDbl(b)/1000.0
        pmf=Exp(-lam)
        For i=1 To k
            pmf=pmf*lam/CDbl(i)
        Next i
        SetStatus STATUS_OK: V19SetLongResult CLngInt(Int(pmf*1000000.0+0.5))

    Case 287 ' LERP_PERMILLE: a=start, b=end, c=tPermille
        v=a+((b-a)*c)\1000
        SetStatus STATUS_OK: V19SetLongResult v

    Case 288 ' CLAMP_VALUE: a=min, b=max, c=value
        v=c
        If b<a Then mn=b: mx=a Else mn=a: mx=b
        If v<mn Then v=mn
        If v>mx Then v=mx
        SetStatus STATUS_OK: V19SetLongResult v

    Case 289 ' MAP_RANGE_DATA: a=x, b=base; DATA[base+0]=inMin, +1=inMax, +2=outMin, +3=outMax
        Dim inMin As LongInt, inMax As LongInt, outMin As LongInt, outMax As LongInt
        inMin=V19DataLong(b)
        inMax=V19DataLong(b+1)
        outMin=V19DataLong(b+2)
        outMax=V19DataLong(b+3)
        denom=inMax-inMin
        If denom=0 Then SetStatus STATUS_DIV_ZERO: SetResult 0: Exit Sub
        v=outMin+((a-inMin)*(outMax-outMin))\denom
        SetStatus STATUS_OK: V19SetLongResult v

    Case Else
        SetStatus STATUS_INVALID_META
        SetResult 0
    End Select
End Sub
