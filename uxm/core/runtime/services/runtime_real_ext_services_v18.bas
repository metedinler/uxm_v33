
#ifndef UXM_RUNTIME_REAL_EXT_SERVICES_V18_BAS
#define UXM_RUNTIME_REAL_EXT_SERVICES_V18_BAS

' UXM V18 real extension services.
' These services are intentionally active implementations. They compute deterministic numeric results.
' Scale convention: 1,000,000 for fractional values.

Const UXM_V18_SCALE As Double = 1000000.0
Const UXM_V18_SCALE_I As LongInt = 1000000

Function V18S(ByVal dataIndex As LongInt) As LongInt
    Return ToSignedValue(ReadData(dataIndex))
End Function

Sub V18SetResultSigned(ByVal v As LongInt)
    SetResult FromSignedValue(v)
    SetLogicFlags ResultValue()
    SetStatus STATUS_OK
End Sub

Function V18ValidData(ByVal baseIndex As LongInt, ByVal countValue As LongInt) As Long
    If baseIndex < 0 Or countValue < 0 Then Return 0
    If countValue = 0 Then Return -1
    If baseIndex + countValue > CLngInt(ux_data_cells) Then Return 0
    Return -1
End Function

Function V18Sum(ByVal baseIndex As LongInt, ByVal countValue As LongInt) As Double
    Dim i As LongInt, s As Double
    s = 0
    For i=0 To countValue-1
        s += CDbl(V18S(baseIndex+i))
    Next
    Return s
End Function

Function V18Mean(ByVal baseIndex As LongInt, ByVal countValue As LongInt) As Double
    If countValue <= 0 Then Return 0
    Return V18Sum(baseIndex,countValue) / CDbl(countValue)
End Function

Function V18Var(ByVal baseIndex As LongInt, ByVal countValue As LongInt) As Double
    Dim i As LongInt, m As Double, d As Double, ss As Double
    If countValue <= 1 Then Return 0
    m = V18Mean(baseIndex,countValue)
    ss = 0
    For i=0 To countValue-1
        d = CDbl(V18S(baseIndex+i)) - m
        ss += d*d
    Next
    Return ss / CDbl(countValue-1)
End Function

Sub MetaHypothesisRealV18(ByVal metaId As ULongInt)
    ' Frame: T-4=aBase, T-3=bBase or expectedBase, T-2=countA, T-1=countB/option, T0=param_scaled
    Dim aBase As LongInt, bBase As LongInt, nA As LongInt, nB As LongInt, param As LongInt
    Dim mA As Double, mB As Double, vA As Double, vB As Double, res As Double, chi As Double
    Dim i As LongInt, obs As Double, expv As Double
    aBase = ToSignedValue(ReadTapeRel(-4))
    bBase = ToSignedValue(ReadTapeRel(-3))
    nA = ToSignedValue(ReadTapeRel(-2))
    nB = ToSignedValue(ReadTapeRel(-1))
    param = ToSignedValue(ReadTapeRel(0))
    Select Case metaId
    Case 760 ' one sample t: DATA[a], nA, param=mu_scaled/raw -> t_scaled
        If V18ValidData(aBase,nA)=0 Or nA<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        mA = V18Mean(aBase,nA)
        vA = V18Var(aBase,nA)
        If vA <= 0 Then V18SetResultSigned(0): Exit Sub
        res = (mA - CDbl(param)/UXM_V18_SCALE) / (Sqr(vA) / Sqr(CDbl(nA)))
        V18SetResultSigned CLngInt(res * UXM_V18_SCALE)
    Case 761 ' independent t: DATA[a], DATA[b], nA,nB -> t_scaled
        If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nB)=0 Or nA<=1 Or nB<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        mA=V18Mean(aBase,nA): mB=V18Mean(bBase,nB): vA=V18Var(aBase,nA): vB=V18Var(bBase,nB)
        If (vA/CDbl(nA)+vB/CDbl(nB))<=0 Then V18SetResultSigned(0): Exit Sub
        res=(mA-mB)/Sqr(vA/CDbl(nA)+vB/CDbl(nB))
        V18SetResultSigned CLngInt(res*UXM_V18_SCALE)
    Case 762 ' paired t: DATA[a], DATA[b], nA -> t_scaled
        If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nA)=0 Or nA<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        Dim dsum As Double, dmean As Double, dss As Double, d As Double
        dsum=0
        For i=0 To nA-1: dsum += CDbl(V18S(aBase+i)-V18S(bBase+i)): Next
        dmean=dsum/CDbl(nA): dss=0
        For i=0 To nA-1: d=CDbl(V18S(aBase+i)-V18S(bBase+i))-dmean: dss += d*d: Next
        If dss<=0 Then V18SetResultSigned(0): Exit Sub
        res=dmean/(Sqr(dss/CDbl(nA-1))/Sqr(CDbl(nA)))
        V18SetResultSigned CLngInt(res*UXM_V18_SCALE)
    Case 763 ' one sample z: DATA[a], nA, param=mu_scaled, T-1 used as sigma_scaled when >0
        If V18ValidData(aBase,nA)=0 Or nA<=0 Or nB=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        mA=V18Mean(aBase,nA)
        res=(mA-CDbl(param)/UXM_V18_SCALE)/(CDbl(nB)/UXM_V18_SCALE/Sqr(CDbl(nA)))
        V18SetResultSigned CLngInt(res*UXM_V18_SCALE)
    Case 764 ' two sample z: same as independent t using supplied variances in nB/param when set; fallback to sample variances
        If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nB)=0 Or nA<=1 Or nB<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        mA=V18Mean(aBase,nA): mB=V18Mean(bBase,nB): vA=V18Var(aBase,nA): vB=V18Var(bBase,nB)
        If (vA/CDbl(nA)+vB/CDbl(nB))<=0 Then V18SetResultSigned(0): Exit Sub
        res=(mA-mB)/Sqr(vA/CDbl(nA)+vB/CDbl(nB))
        V18SetResultSigned CLngInt(res*UXM_V18_SCALE)
    Case 765 ' F variance ratio scaled
        If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nB)=0 Or nA<=1 Or nB<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        vA=V18Var(aBase,nA): vB=V18Var(bBase,nB)
        If vB=0 Then SetStatus STATUS_DIV_ZERO: SetResult STATUS_DIV_ZERO: Exit Sub
        V18SetResultSigned CLngInt((vA/vB)*UXM_V18_SCALE)
    Case 766 ' one-way ANOVA two groups: returns F scaled
        If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nB)=0 Or nA<=1 Or nB<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        mA=V18Mean(aBase,nA): mB=V18Mean(bBase,nB)
        Dim grand As Double, ssb As Double, ssw As Double
        grand=(V18Sum(aBase,nA)+V18Sum(bBase,nB))/CDbl(nA+nB)
        ssb=CDbl(nA)*(mA-grand)*(mA-grand)+CDbl(nB)*(mB-grand)*(mB-grand)
        ssw=V18Var(aBase,nA)*CDbl(nA-1)+V18Var(bBase,nB)*CDbl(nB-1)
        If ssw=0 Then V18SetResultSigned(0): Exit Sub
        res=(ssb/1.0)/(ssw/CDbl(nA+nB-2))
        V18SetResultSigned CLngInt(res*UXM_V18_SCALE)
    Case 767,768 ' chi-square: obs at aBase, expected at bBase, nA -> chi scaled
        If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nA)=0 Or nA<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        chi=0
        For i=0 To nA-1
            obs=CDbl(V18S(aBase+i)): expv=CDbl(V18S(bBase+i))
            If expv<>0 Then chi += (obs-expv)*(obs-expv)/expv
        Next
        V18SetResultSigned CLngInt(chi*UXM_V18_SCALE)
    Case 769 ' hypothesis status/check
        V18SetResultSigned CLngInt(ux_status)
    Case Else
        SetStatus STATUS_INVALID_META: SetResult STATUS_INVALID_META
    End Select
End Sub

Sub MetaPosthocRealV18(ByVal metaId As ULongInt)
    ' Conservative posthoc effect gate. Frame: T-4=aBase,T-3=bBase,T-2=nA,T-1=nB,T0=threshold_scaled.
    Dim aBase As LongInt, bBase As LongInt, nA As LongInt, nB As LongInt, thr As LongInt
    Dim mA As Double, mB As Double, se As Double, diff As Double, vA As Double, vB As Double, score As Double
    aBase=ToSignedValue(ReadTapeRel(-4)): bBase=ToSignedValue(ReadTapeRel(-3)): nA=ToSignedValue(ReadTapeRel(-2)): nB=ToSignedValue(ReadTapeRel(-1)): thr=ToSignedValue(ReadTapeRel(0))
    If V18ValidData(aBase,nA)=0 Or V18ValidData(bBase,nB)=0 Or nA<=1 Or nB<=1 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
    mA=V18Mean(aBase,nA): mB=V18Mean(bBase,nB): vA=V18Var(aBase,nA): vB=V18Var(bBase,nB)
    se=Sqr(vA/CDbl(nA)+vB/CDbl(nB))
    If se=0 Then V18SetResultSigned(0): Exit Sub
    diff=Abs(mA-mB): score=(diff/se)*UXM_V18_SCALE
    Select Case metaId
    Case 790,791,792,793,794,795
        If thr<=0 Then
            V18SetResultSigned CLngInt(score)
        Else
            If CLngInt(score)>=thr Then V18SetResultSigned(1) Else V18SetResultSigned(0)
        End If
    Case Else
        SetStatus STATUS_INVALID_META: SetResult STATUS_INVALID_META
    End Select
End Sub

Sub MetaAIRealV18(ByVal metaId As ULongInt)
    ' Frame mostly DATA-based: T-4=aBase,T-3=bBase,T-2=count,T-1=outBase,T0=option.
    Dim aBase As LongInt, bBase As LongInt, n As LongInt, outBase As LongInt, opt As LongInt
    Dim i As LongInt, tp As LongInt, tn As LongInt, fp As LongInt, fn As LongInt, correct As LongInt
    Dim p As LongInt, y As LongInt, sumv As Double, maxv As Double, ev As Double, d As Double, bestI As LongInt, bestD As Double
    aBase=ToSignedValue(ReadTapeRel(-4)): bBase=ToSignedValue(ReadTapeRel(-3)): n=ToSignedValue(ReadTapeRel(-2)): outBase=ToSignedValue(ReadTapeRel(-1)): opt=ToSignedValue(ReadTapeRel(0))
    Select Case metaId
    Case 810 ' accuracy: predicted vs actual -> scaled
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Or n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        correct=0
        For i=0 To n-1: If V18S(aBase+i)=V18S(bBase+i) Then correct+=1
        Next
        V18SetResultSigned CLngInt((CDbl(correct)/CDbl(n))*UXM_V18_SCALE)
    Case 811 ' binary confusion matrix -> data[out..out+3]=tp,tn,fp,fn
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Or V18ValidData(outBase,4)=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        tp=0:tn=0:fp=0:fn=0
        For i=0 To n-1
            p=V18S(aBase+i): y=V18S(bBase+i)
            If p<>0 And y<>0 Then tp+=1 ElseIf p=0 And y=0 Then tn+=1 ElseIf p<>0 And y=0 Then fp+=1 Else fn+=1
        Next
        WriteData outBase,FromSignedValue(tp): WriteData outBase+1,FromSignedValue(tn): WriteData outBase+2,FromSignedValue(fp): WriteData outBase+3,FromSignedValue(fn)
        V18SetResultSigned tp+tn+fp+fn
    Case 812 ' precision scaled
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Or n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        tp=0:fp=0
        For i=0 To n-1: p=V18S(aBase+i): y=V18S(bBase+i): If p<>0 And y<>0 Then tp+=1 ElseIf p<>0 And y=0 Then fp+=1
        Next
        If tp+fp=0 Then V18SetResultSigned(0) Else V18SetResultSigned CLngInt((CDbl(tp)/CDbl(tp+fp))*UXM_V18_SCALE)
    Case 813 ' recall scaled
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Or n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        tp=0:fn=0
        For i=0 To n-1: p=V18S(aBase+i): y=V18S(bBase+i): If p<>0 And y<>0 Then tp+=1 ElseIf p=0 And y<>0 Then fn+=1
        Next
        If tp+fn=0 Then V18SetResultSigned(0) Else V18SetResultSigned CLngInt((CDbl(tp)/CDbl(tp+fn))*UXM_V18_SCALE)
    Case 814 ' F1 scaled
        Dim pr As Double, rc As Double
        tp=0:fp=0:fn=0
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Or n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        For i=0 To n-1: p=V18S(aBase+i): y=V18S(bBase+i): If p<>0 And y<>0 Then tp+=1 ElseIf p<>0 And y=0 Then fp+=1 ElseIf p=0 And y<>0 Then fn+=1
        Next
        If tp+fp=0 Or tp+fn=0 Then V18SetResultSigned(0): Exit Sub
        pr=CDbl(tp)/CDbl(tp+fp): rc=CDbl(tp)/CDbl(tp+fn)
        If pr+rc=0 Then V18SetResultSigned(0) Else V18SetResultSigned CLngInt((2.0*pr*rc/(pr+rc))*UXM_V18_SCALE)
    Case 815 ' euclidean distance scaled
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        sumv=0
        For i=0 To n-1: d=CDbl(V18S(aBase+i)-V18S(bBase+i)): sumv += d*d: Next
        V18SetResultSigned CLngInt(Sqr(sumv)*UXM_V18_SCALE)
    Case 816 ' manhattan distance scaled
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        sumv=0
        For i=0 To n-1: sumv += Abs(CDbl(V18S(aBase+i)-V18S(bBase+i))): Next
        V18SetResultSigned CLngInt(sumv*UXM_V18_SCALE)
    Case 817 ' cosine similarity scaled
        Dim dotv As Double, na As Double, nb As Double
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        dotv=0:na=0:nb=0
        For i=0 To n-1: dotv += CDbl(V18S(aBase+i))*CDbl(V18S(bBase+i)): na += CDbl(V18S(aBase+i))*CDbl(V18S(aBase+i)): nb += CDbl(V18S(bBase+i))*CDbl(V18S(bBase+i)): Next
        If na=0 Or nb=0 Then V18SetResultSigned(0) Else V18SetResultSigned CLngInt((dotv/Sqr(na*nb))*UXM_V18_SCALE)
    Case 818 ' onehot: aBase value, outBase class count -> one-hot data
        If outBase<0 Or opt<=0 Or outBase+opt>CLngInt(ux_data_cells) Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        For i=0 To opt-1: If i=V18S(aBase) Then WriteData outBase+i,1 Else WriteData outBase+i,0
        Next
        V18SetResultSigned(1)
    Case 819 ' deterministic train count = floor(n*option_scaled)
        If n<0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        If opt<=0 Then opt=700000
        V18SetResultSigned CLngInt(CDbl(n)*CDbl(opt)/UXM_V18_SCALE)
    Case 820 ' deterministic reverse copy shuffle: data a->out
        If V18ValidData(aBase,n)=0 Or V18ValidData(outBase,n)=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        For i=0 To n-1: WriteData outBase+i, ReadData(aBase+n-1-i): Next
        V18SetResultSigned n
    Case 821 ' 1D nearest neighbor: data a values, data b labels, opt=query -> label
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Or n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        bestI=0: bestD=Abs(CDbl(V18S(aBase)-opt))
        For i=1 To n-1: d=Abs(CDbl(V18S(aBase+i)-opt)): If d<bestD Then bestD=d: bestI=i
        Next
        V18SetResultSigned V18S(bBase+bestI)
    Case 822 ' linear layer y=sum(x*w)+bias(opt)
        If V18ValidData(aBase,n)=0 Or V18ValidData(bBase,n)=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        sumv=CDbl(opt)
        For i=0 To n-1: sumv += CDbl(V18S(aBase+i))*CDbl(V18S(bBase+i)): Next
        V18SetResultSigned CLngInt(sumv)
    Case 823 ' softmax: input a, out outBase, n; output scaled int probabilities, returns sum
        If V18ValidData(aBase,n)=0 Or V18ValidData(outBase,n)=0 Or n<=0 Then SetStatus STATUS_DATA_BOUNDS: SetResult STATUS_DATA_BOUNDS: Exit Sub
        maxv=CDbl(V18S(aBase)): For i=1 To n-1: If CDbl(V18S(aBase+i))>maxv Then maxv=CDbl(V18S(aBase+i))
        Next
        sumv=0
        For i=0 To n-1: sumv += Exp(CDbl(V18S(aBase+i))-maxv): Next
        For i=0 To n-1: ev=Exp(CDbl(V18S(aBase+i))-maxv): WriteData outBase+i, FromSignedValue(CLngInt((ev/sumv)*UXM_V18_SCALE)): Next
        V18SetResultSigned n
    Case Else
        SetStatus STATUS_INVALID_META: SetResult STATUS_INVALID_META
    End Select
End Sub

Sub MetaFileExtRealV18(ByVal metaId As ULongInt)
    ' PathZ-based file ops for 416..419. Frames use DATA path strings.
    Dim p1 As String, p2 As String
    Select Case metaId
    Case 416 ' delete: T-1 pathZ -> T+1 1/0
        p1=FileDataZToString(FileReadArgRel(-1))
        If ux_file_last_status<>UXM_FILE_STATUS_OK Then FileWriteResultRel 1,0: Exit Sub
        If Kill(p1)<>0 Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_IO_ERROR Else FileWriteResultRel 1,1: FileSetStatus UXM_FILE_STATUS_OK
    Case 417 ' rename: T-2 oldPathZ, T-1 newPathZ
        p1=FileDataZToString(FileReadArgRel(-2)): p2=FileDataZToString(FileReadArgRel(-1))
        If ux_file_last_status<>UXM_FILE_STATUS_OK Then FileWriteResultRel 1,0: Exit Sub
        If Name(p1,p2)<>0 Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_IO_ERROR Else FileWriteResultRel 1,1: FileSetStatus UXM_FILE_STATUS_OK
    Case 418 ' mkdir: T-1 pathZ
        p1=FileDataZToString(FileReadArgRel(-1))
        If ux_file_last_status<>UXM_FILE_STATUS_OK Then FileWriteResultRel 1,0: Exit Sub
        If MkDir(p1)<>0 Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_IO_ERROR Else FileWriteResultRel 1,1: FileSetStatus UXM_FILE_STATUS_OK
    Case 419 ' exists: T-1 pathZ -> 1/0
        p1=FileDataZToString(FileReadArgRel(-1))
        If ux_file_last_status<>UXM_FILE_STATUS_OK Then FileWriteResultRel 1,0: Exit Sub
        If Len(Dir(p1))>0 Then FileWriteResultRel 1,1 Else FileWriteResultRel 1,0
        FileSetStatus UXM_FILE_STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
