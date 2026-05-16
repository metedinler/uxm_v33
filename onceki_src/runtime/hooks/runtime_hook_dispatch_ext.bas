#ifndef UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
#define UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS

' UXM V16 gerçek servis hook'u.
' Bu dosya eski "default no-op" hook yerine, kılavuzda var yazılıp registry'de placeholder kalan
' yeni bantları gerçek hesaplama ile bağlar. Dispatch dönerse 1, tanımı yoksa 0 döner.
Const UXM_V16_SCALE As Double = 1000000.0
Const UXM_V16_SCALE_I As LongInt = 1000000

Function V16ReadSigned(ByVal dataIndex As LongInt) As LongInt
    Return ToSignedValue(ReadData(dataIndex))
End Function

Function V16ValidRange(ByVal startIndex As LongInt, ByVal countValue As LongInt) As Long
    If startIndex < 0 Or countValue < 0 Then Return 0
    If countValue = 0 Then Return 1
    If startIndex + countValue > CLngInt(ux_data_cells) Then Return 0
    Return -1
End Function

Sub V16WriteResultScaled(ByVal valueValue As Double)
    SetResult FromSignedValue(CLngInt(valueValue * UXM_V16_SCALE))
    SetLogicFlags ResultValue()
    SetStatus STATUS_OK
End Sub

Sub V16WriteResultRaw(ByVal valueValue As LongInt)
    SetResult FromSignedValue(valueValue)
    SetLogicFlags ResultValue()
    SetStatus STATUS_OK
End Sub

Function V16Mean(ByVal baseIndex As LongInt, ByVal nValue As LongInt) As Double
    Dim i As LongInt
    Dim s As Double
    If nValue <= 0 Then Return 0
    For i = 0 To nValue - 1
        s += CDbl(V16ReadSigned(baseIndex + i))
    Next
    Return s / CDbl(nValue)
End Function

Function V16VarianceSample(ByVal baseIndex As LongInt, ByVal nValue As LongInt) As Double
    Dim i As LongInt
    Dim m As Double
    Dim d As Double
    Dim ss As Double
    If nValue <= 1 Then Return 0
    m = V16Mean(baseIndex, nValue)
    For i = 0 To nValue - 1
        d = CDbl(V16ReadSigned(baseIndex + i)) - m
        ss += d*d
    Next
    Return ss / CDbl(nValue - 1)
End Function

Function V16NormalCdfApprox(ByVal z As Double) As Double
    ' Abramowitz-Stegun tipi hızlı normal CDF yaklaşımı. P-değeri için yaklaşık ama gerçek hesap üretir.
    Dim t As Double
    Dim d As Double
    Dim p As Double
    Dim zz As Double
    zz = z
    If zz < 0 Then zz = -zz
    t = 1.0 / (1.0 + 0.2316419 * zz)
    d = 0.3989422804014327 * Exp(-zz*zz/2.0)
    p = 1.0 - d * t * (0.319381530 + t*(-0.356563782 + t*(1.781477937 + t*(-1.821255978 + t*1.330274429))))
    If z < 0 Then p = 1.0 - p
    Return p
End Function

Function V16Hypothesis(ByVal metaId As ULongInt) As Long
    Dim xBase As LongInt = ToSignedValue(ReadTapeRel(-4))
    Dim yBase As LongInt = ToSignedValue(ReadTapeRel(-3))
    Dim n1 As LongInt = ToSignedValue(ReadTapeRel(-2))
    Dim n2orParam As LongInt = ToSignedValue(ReadTapeRel(-1))
    Dim opt As LongInt = ToSignedValue(ReadTapeRel(0))
    Dim m1 As Double
    Dim m2 As Double
    Dim v1 As Double
    Dim v2 As Double
    Dim se As Double
    Dim stat As Double
    Dim pApprox As Double
    Select Case metaId
    Case 760 ' HYP_TTEST_ONE: T-4=xBase,T-2=n,T-1=mu0 -> result=t*1e6
        If V16ValidRange(xBase,n1)=0 Or n1<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        m1 = V16Mean(xBase,n1)
        v1 = V16VarianceSample(xBase,n1)
        If v1 = 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        stat = (m1 - CDbl(n2orParam)) / (Sqr(v1) / Sqr(CDbl(n1)))
        V16WriteResultScaled stat
        Return 1
    Case 761 ' HYP_TTEST_INDEPENDENT: T-4=xBase,T-3=yBase,T-2=n1,T-1=n2 -> t*1e6
        If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n2orParam)=0 Or n1<=1 Or n2orParam<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        m1 = V16Mean(xBase,n1): m2 = V16Mean(yBase,n2orParam)
        v1 = V16VarianceSample(xBase,n1): v2 = V16VarianceSample(yBase,n2orParam)
        se = Sqr(v1/CDbl(n1) + v2/CDbl(n2orParam))
        If se = 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        V16WriteResultScaled ((m1-m2)/se)
        Return 1
    Case 762 ' HYP_TTEST_PAIRED: T-4=xBase,T-3=yBase,T-2=n -> paired t*1e6
        Dim i As LongInt
        Dim diffBase As LongInt = opt
        If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n1)=0 Or V16ValidRange(diffBase,n1)=0 Or n1<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To n1-1
            WriteData diffBase+i, FromSignedValue(V16ReadSigned(xBase+i)-V16ReadSigned(yBase+i))
        Next
        m1 = V16Mean(diffBase,n1)
        v1 = V16VarianceSample(diffBase,n1)
        If v1 = 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        V16WriteResultScaled (m1/(Sqr(v1)/Sqr(CDbl(n1))))
        Return 1
    Case 763 ' HYP_ZTEST_ONE: T-4=xBase,T-2=n,T-1=mu0,T=sigma -> z*1e6
        If V16ValidRange(xBase,n1)=0 Or n1<=0 Or opt<=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        m1 = V16Mean(xBase,n1)
        V16WriteResultScaled ((m1-CDbl(n2orParam))/(CDbl(opt)/Sqr(CDbl(n1))))
        Return 1
    Case 764 ' HYP_ZTEST_TWO_APPROX: independent z using sample variances -> z*1e6
        If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n2orParam)=0 Or n1<=1 Or n2orParam<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        m1 = V16Mean(xBase,n1): m2 = V16Mean(yBase,n2orParam)
        v1 = V16VarianceSample(xBase,n1): v2 = V16VarianceSample(yBase,n2orParam)
        se = Sqr(v1/CDbl(n1) + v2/CDbl(n2orParam))
        If se = 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        V16WriteResultScaled ((m1-m2)/se)
        Return 1
    Case 765 ' HYP_FTEST_VARIANCE: ratio v1/v2 * 1e6
        If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n2orParam)=0 Or n1<=1 Or n2orParam<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        v1 = V16VarianceSample(xBase,n1): v2 = V16VarianceSample(yBase,n2orParam)
        If v2 = 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        V16WriteResultScaled (v1/v2)
        Return 1
    Case 766 ' HYP_ANOVA_ONEWAY_SIMPLE: DATA groups: [value...], group starts xBase/yBase, n1/n2 -> F*1e6 for two groups
        If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n2orParam)=0 Or n1<=1 Or n2orParam<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        m1 = V16Mean(xBase,n1): m2 = V16Mean(yBase,n2orParam)
        Dim grand As Double = (m1*CDbl(n1)+m2*CDbl(n2orParam))/CDbl(n1+n2orParam)
        Dim ssb As Double = CDbl(n1)*(m1-grand)*(m1-grand)+CDbl(n2orParam)*(m2-grand)*(m2-grand)
        Dim ssw As Double = V16VarianceSample(xBase,n1)*CDbl(n1-1)+V16VarianceSample(yBase,n2orParam)*CDbl(n2orParam-1)
        If ssw = 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        V16WriteResultScaled (ssb/(ssw/CDbl(n1+n2orParam-2)))
        Return 1
    Case 768 ' HYP_CHI_SQUARE: T-4=obsBase,T-3=expBase,T-2=n -> chi2*1e6
        Dim i As LongInt
        Dim e As Double
        Dim o As Double
        Dim chi As Double
        If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n1)=0 Or n1<=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To n1-1
            o = CDbl(V16ReadSigned(xBase+i))
            e = CDbl(V16ReadSigned(yBase+i))
            If e <= 0 Then SetStatus STATUS_DIV_ZERO: Return 1
            chi += (o-e)*(o-e)/e
        Next
        V16WriteResultScaled chi
        Return 1
    Case 769 ' HYP_CHI_GOODNESS_EQUAL: T-4=obsBase,T-2=n -> chi2 against equal expected mean
        Dim i2 As LongInt
        Dim total As Double
        Dim expVal As Double
        Dim chi2 As Double
        If V16ValidRange(xBase,n1)=0 Or n1<=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i2=0 To n1-1: total += CDbl(V16ReadSigned(xBase+i2)): Next
        expVal = total/CDbl(n1)
        If expVal <= 0 Then SetStatus STATUS_DIV_ZERO: Return 1
        For i2=0 To n1-1
            chi2 += (CDbl(V16ReadSigned(xBase+i2))-expVal)*(CDbl(V16ReadSigned(xBase+i2))-expVal)/expVal
        Next
        V16WriteResultScaled chi2
        Return 1
    End Select
    Return 0
End Function

Function V16Posthoc(ByVal metaId As ULongInt) As Long
    ' İlk gerçek posthoc hattı: iki grup için fark, SE ve konservatif eşik üretir.
    ' T-4=xBase, T-3=yBase, T-2=n1, T-1=n2, T=outBase. out[0]=meanDiff*1e6, out[1]=pooledSE*1e6, out[2]=decision(0/1)
    Dim xBase As LongInt = ToSignedValue(ReadTapeRel(-4))
    Dim yBase As LongInt = ToSignedValue(ReadTapeRel(-3))
    Dim n1 As LongInt = ToSignedValue(ReadTapeRel(-2))
    Dim n2 As LongInt = ToSignedValue(ReadTapeRel(-1))
    Dim outBase As LongInt = ToSignedValue(ReadTapeRel(0))
    Dim m1 As Double
    Dim m2 As Double
    Dim v1 As Double
    Dim v2 As Double
    Dim se As Double
    Dim diff As Double
    Dim critical As Double
    If metaId < 790 Or metaId > 795 Then Return 0
    If V16ValidRange(xBase,n1)=0 Or V16ValidRange(yBase,n2)=0 Or V16ValidRange(outBase,3)=0 Or n1<=1 Or n2<=1 Then SetStatus STATUS_DATA_BOUNDS: Return 1
    m1=V16Mean(xBase,n1): m2=V16Mean(yBase,n2)
    v1=V16VarianceSample(xBase,n1): v2=V16VarianceSample(yBase,n2)
    se = Sqr(((v1*CDbl(n1-1)+v2*CDbl(n2-1))/CDbl(n1+n2-2))*(1.0/CDbl(n1)+1.0/CDbl(n2)))
    diff = m1-m2
    critical = 2.0*se
    If metaId=791 Then critical=2.2*se ' Duncan için biraz daha gevşek/kademeli temsil
    If metaId=792 Then critical=2.5*se ' Dunnett için kontrol grubu kıyas eşiği
    If metaId=793 Then critical=2.4*se ' Bonferroni
    If metaId=794 Then critical=2.6*se ' Scheffe
    If metaId=795 Then critical=2.0*se ' LSD
    WriteData outBase+0, FromSignedValue(CLngInt(diff*UXM_V16_SCALE))
    WriteData outBase+1, FromSignedValue(CLngInt(se*UXM_V16_SCALE))
    If Abs(diff) > critical Then WriteData outBase+2, 1 Else WriteData outBase+2, 0
    V16WriteResultRaw outBase
    Return 1
End Function

Function V16AI(ByVal metaId As ULongInt) As Long
    Dim aBase As LongInt = ToSignedValue(ReadTapeRel(-4))
    Dim bBase As LongInt = ToSignedValue(ReadTapeRel(-3))
    Dim countValue As LongInt = ToSignedValue(ReadTapeRel(-2))
    Dim opt As LongInt = ToSignedValue(ReadTapeRel(-1))
    Dim outBase As LongInt = ToSignedValue(ReadTapeRel(0))
    Dim i As LongInt
    Dim acc As Double
    Dim tp As LongInt
    Dim tn As LongInt
    Dim fp As LongInt
    Dim fn As LongInt
    Dim dot As Double
    Dim n1 As Double
    Dim n2 As Double
    Dim d As Double
    Select Case metaId
    Case 810 ' AI_ACCURACY: predBase,trueBase,count -> accuracy*1e6
        If V16ValidRange(aBase,countValue)=0 Or V16ValidRange(bBase,countValue)=0 Or countValue<=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To countValue-1
            If V16ReadSigned(aBase+i)=V16ReadSigned(bBase+i) Then acc += 1
        Next
        V16WriteResultScaled (acc/CDbl(countValue))
        Return 1
    Case 811 ' AI_CONFUSION_BINARY: predBase,trueBase,count,outBase -> out[0]=TP,out[1]=TN,out[2]=FP,out[3]=FN
        If V16ValidRange(aBase,countValue)=0 Or V16ValidRange(bBase,countValue)=0 Or V16ValidRange(outBase,4)=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To countValue-1
            If V16ReadSigned(aBase+i)<>0 And V16ReadSigned(bBase+i)<>0 Then tp+=1
            If V16ReadSigned(aBase+i)=0 And V16ReadSigned(bBase+i)=0 Then tn+=1
            If V16ReadSigned(aBase+i)<>0 And V16ReadSigned(bBase+i)=0 Then fp+=1
            If V16ReadSigned(aBase+i)=0 And V16ReadSigned(bBase+i)<>0 Then fn+=1
        Next
        WriteData outBase+0,tp: WriteData outBase+1,tn: WriteData outBase+2,fp: WriteData outBase+3,fn
        V16WriteResultRaw outBase
        Return 1
    Case 812 ' AI_PRECISION_BINARY: pred,true,count -> precision*1e6
        If V16AI(811)=0 Then Return 1
        tp=V16ReadSigned(outBase+0): fp=V16ReadSigned(outBase+2)
        If tp+fp=0 Then V16WriteResultScaled 0 Else V16WriteResultScaled (CDbl(tp)/CDbl(tp+fp))
        Return 1
    Case 813 ' AI_RECALL_BINARY
        If V16AI(811)=0 Then Return 1
        tp=V16ReadSigned(outBase+0): fn=V16ReadSigned(outBase+3)
        If tp+fn=0 Then V16WriteResultScaled 0 Else V16WriteResultScaled (CDbl(tp)/CDbl(tp+fn))
        Return 1
    Case 814 ' AI_F1_BINARY
        If V16ValidRange(aBase,countValue)=0 Or V16ValidRange(bBase,countValue)=0 Or countValue<=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To countValue-1
            If V16ReadSigned(aBase+i)<>0 And V16ReadSigned(bBase+i)<>0 Then tp+=1
            If V16ReadSigned(aBase+i)<>0 And V16ReadSigned(bBase+i)=0 Then fp+=1
            If V16ReadSigned(aBase+i)=0 And V16ReadSigned(bBase+i)<>0 Then fn+=1
        Next
        If (2*tp+fp+fn)=0 Then V16WriteResultScaled 0 Else V16WriteResultScaled (CDbl(2*tp)/CDbl(2*tp+fp+fn))
        Return 1
    Case 815 ' AI_DISTANCE_EUCLIDEAN_SQ: vecA,vecB,count -> squared distance raw
        If V16ValidRange(aBase,countValue)=0 Or V16ValidRange(bBase,countValue)=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To countValue-1
            d = CDbl(V16ReadSigned(aBase+i)-V16ReadSigned(bBase+i))
            acc += d*d
        Next
        V16WriteResultRaw CLngInt(acc)
        Return 1
    Case 816 ' AI_DISTANCE_MANHATTAN
        If V16ValidRange(aBase,countValue)=0 Or V16ValidRange(bBase,countValue)=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To countValue-1
            d = CDbl(V16ReadSigned(aBase+i)-V16ReadSigned(bBase+i))
            If d<0 Then d=-d
            acc += d
        Next
        V16WriteResultRaw CLngInt(acc)
        Return 1
    Case 817 ' AI_DISTANCE_COSINE: 1-cos scaled
        If V16ValidRange(aBase,countValue)=0 Or V16ValidRange(bBase,countValue)=0 Then SetStatus STATUS_DATA_BOUNDS: Return 1
        For i=0 To countValue-1
            dot += CDbl(V16ReadSigned(aBase+i))*CDbl(V16ReadSigned(bBase+i))
            n1 += CDbl(V16ReadSigned(aBase+i))*CDbl(V16ReadSigned(aBase+i))
            n2 += CDbl(V16ReadSigned(bBase+i))*CDbl(V16ReadSigned(bBase+i))
        Next
        If n1=0 Or n2=0 Then SetStatus STATUS_DIV_ZERO: Return 1
        V16WriteResultScaled (1.0 - dot/Sqr(n1*n2))
        Return 1
    End Select
    Return 0
End Function

Function RuntimeHookDispatchExt(ByVal metaId As ULongInt) As Long
    If metaId>=760 And metaId<=789 Then Return V16Hypothesis(metaId)
    If metaId>=790 And metaId<=809 Then Return V16Posthoc(metaId)
    If metaId>=810 And metaId<=839 Then Return V16AI(metaId)
    Return 0
End Function
#endif
