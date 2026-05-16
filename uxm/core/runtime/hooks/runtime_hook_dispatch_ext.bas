
#ifndef UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
#define UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
' V18 hook: real extension services. Returns non-zero when handled.
Function RuntimeHookDispatchExt(ByVal metaId As ULongInt) As Long
    Select Case metaId
    Case 416,417,418,419
        MetaFileExtRealV18 metaId
        Return -1
    Case 760 To 769
        MetaHypothesisRealV18 metaId
        Return -1
    Case 320 To 325, 790 To 795
        MetaPosthocRealV18 metaId
        Return -1
    Case 340 To 356, 810 To 823
        MetaAIRealV18 metaId
        Return -1

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
    Case Else
        Return 0
    End Select
End Function
#endif
