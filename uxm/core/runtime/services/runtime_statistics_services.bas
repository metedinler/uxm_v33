#ifndef UXM_RUNTIME_STATISTICS_SERVICES_BAS
#define UXM_RUNTIME_STATISTICS_SERVICES_BAS

' UXM V3.3 Stage-8 Statistics / Regression V1
' Service range: @260..@299
' Scale convention: decimal results are scaled by 1,000,000.

Const UXM_STAT_SCALE As Double = 1000000.0
Const UXM_STAT_SCALE_I As LongInt = 1000000

Function StatReadSigned(ByVal dataIndex As LongInt) As LongInt
    Return ToSignedValue(ReadData(dataIndex))
End Function

Sub StatWriteTapeSigned(ByVal rel As LongInt, ByVal signedValue As LongInt)
    WriteTapeRel rel, FromSignedValue(signedValue)
End Sub

Sub StatWriteDataSigned(ByVal dataIndex As LongInt, ByVal signedValue As LongInt)
    WriteData dataIndex, FromSignedValue(signedValue)
End Sub

Function StatValidRange(ByVal startIndex As LongInt, ByVal countValue As LongInt) As Long
    If countValue < 0 Then Return 0
    If startIndex < 0 Then Return 0
    If countValue = 0 Then Return 1
    If startIndex + countValue > CLngInt(ux_data_cells) Then Return 0
    Return 1
End Function

Function StatSumSigned(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim sumValue As LongInt
    sumValue = 0
    For loopIndex = 0 To countValue - 1
        sumValue += StatReadSigned(startIndex + loopIndex)
    Next
    Return sumValue
End Function

Function StatMinSigned(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim minValue As LongInt
    If countValue <= 0 Then Return 0
    minValue = StatReadSigned(startIndex)
    For loopIndex = 1 To countValue - 1
        If StatReadSigned(startIndex + loopIndex) < minValue Then minValue = StatReadSigned(startIndex + loopIndex)
    Next
    Return minValue
End Function

Function StatMaxSigned(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim maxValue As LongInt
    If countValue <= 0 Then Return 0
    maxValue = StatReadSigned(startIndex)
    For loopIndex = 1 To countValue - 1
        If StatReadSigned(startIndex + loopIndex) > maxValue Then maxValue = StatReadSigned(startIndex + loopIndex)
    Next
    Return maxValue
End Function

Function StatMeanScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    If countValue <= 0 Then Return 0
    Return CLngInt((CDbl(StatSumSigned(startIndex, countValue)) / CDbl(countValue)) * UXM_STAT_SCALE)
End Function

Function StatVarianceScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim meanValue As Double
    Dim deltaValue As Double
    Dim ssValue As Double
    If countValue <= 1 Then Return 0
    meanValue = CDbl(StatSumSigned(startIndex, countValue)) / CDbl(countValue)
    ssValue = 0
    For loopIndex = 0 To countValue - 1
        deltaValue = CDbl(StatReadSigned(startIndex + loopIndex)) - meanValue
        ssValue += deltaValue * deltaValue
    Next
    Return CLngInt((ssValue / CDbl(countValue - 1)) * UXM_STAT_SCALE)
End Function

Function StatStdDevScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim varianceValue As Double
    varianceValue = CDbl(StatVarianceScaled(startIndex, countValue)) / UXM_STAT_SCALE
    Return CLngInt(Sqr(varianceValue) * UXM_STAT_SCALE)
End Function

Function StatMedianScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim values(0 To 2047) As LongInt
    Dim loopIndex As LongInt
    Dim sortIndex As LongInt
    Dim tmpValue As LongInt
    Dim cappedCount As LongInt
    If countValue <= 0 Then Return 0
    cappedCount = countValue
    If cappedCount > 2048 Then cappedCount = 2048
    For loopIndex = 0 To cappedCount - 1
        values(loopIndex) = StatReadSigned(startIndex + loopIndex)
    Next
    For loopIndex = 0 To cappedCount - 2
        For sortIndex = loopIndex + 1 To cappedCount - 1
            If values(sortIndex) < values(loopIndex) Then
                tmpValue = values(loopIndex)
                values(loopIndex) = values(sortIndex)
                values(sortIndex) = tmpValue
            End If
        Next
    Next
    If (cappedCount Mod 2) = 1 Then
        Return CLngInt(CDbl(values(cappedCount \ 2)) * UXM_STAT_SCALE)
    Else
        Return CLngInt(((CDbl(values(cappedCount \ 2 - 1)) + CDbl(values(cappedCount \ 2))) / 2.0) * UXM_STAT_SCALE)
    End If
End Function

Function StatCovarianceScaled(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim xMean As Double
    Dim yMean As Double
    Dim covValue As Double
    If countValue <= 1 Then Return 0
    If StatValidRange(xStart, countValue) = 0 Or StatValidRange(yStart, countValue) = 0 Then Return 0
    xMean = CDbl(StatSumSigned(xStart, countValue)) / CDbl(countValue)
    yMean = CDbl(StatSumSigned(yStart, countValue)) / CDbl(countValue)
    covValue = 0
    For loopIndex = 0 To countValue - 1
        covValue += (CDbl(StatReadSigned(xStart + loopIndex)) - xMean) * (CDbl(StatReadSigned(yStart + loopIndex)) - yMean)
    Next
    Return CLngInt((covValue / CDbl(countValue - 1)) * UXM_STAT_SCALE)
End Function

Function StatPearsonScaled(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim xMean As Double
    Dim yMean As Double
    Dim numeratorValue As Double
    Dim xSqValue As Double
    Dim ySqValue As Double
    Dim xDelta As Double
    Dim yDelta As Double
    If countValue <= 1 Then Return 0
    If StatValidRange(xStart, countValue) = 0 Or StatValidRange(yStart, countValue) = 0 Then Return 0
    xMean = CDbl(StatSumSigned(xStart, countValue)) / CDbl(countValue)
    yMean = CDbl(StatSumSigned(yStart, countValue)) / CDbl(countValue)
    numeratorValue = 0
    xSqValue = 0
    ySqValue = 0
    For loopIndex = 0 To countValue - 1
        xDelta = CDbl(StatReadSigned(xStart + loopIndex)) - xMean
        yDelta = CDbl(StatReadSigned(yStart + loopIndex)) - yMean
        numeratorValue += xDelta * yDelta
        xSqValue += xDelta * xDelta
        ySqValue += yDelta * yDelta
    Next
    If xSqValue = 0 Or ySqValue = 0 Then Return 0
    Return CLngInt((numeratorValue / Sqr(xSqValue * ySqValue)) * UXM_STAT_SCALE)
End Function

Sub StatLinearRegression(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt, ByVal outStart As LongInt)
    Dim loopIndex As LongInt
    Dim sumX As Double
    Dim sumY As Double
    Dim sumXX As Double
    Dim sumXY As Double
    Dim denValue As Double
    Dim slopeValue As Double
    Dim interceptValue As Double
    Dim xVal As Double
    Dim yVal As Double
    If countValue <= 1 Then
        SetStatus STATUS_DIV_ZERO
        Exit Sub
    End If
    If StatValidRange(xStart, countValue) = 0 Or StatValidRange(yStart, countValue) = 0 Or StatValidRange(outStart, 3) = 0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    sumX = 0
    sumY = 0
    sumXX = 0
    sumXY = 0
    For loopIndex = 0 To countValue - 1
        xVal = CDbl(StatReadSigned(xStart + loopIndex))
        yVal = CDbl(StatReadSigned(yStart + loopIndex))
        sumX += xVal
        sumY += yVal
        sumXX += xVal * xVal
        sumXY += xVal * yVal
    Next
    denValue = CDbl(countValue) * sumXX - sumX * sumX
    If denValue = 0 Then
        SetStatus STATUS_DIV_ZERO
        Exit Sub
    End If
    slopeValue = (CDbl(countValue) * sumXY - sumX * sumY) / denValue
    interceptValue = (sumY - slopeValue * sumX) / CDbl(countValue)
    StatWriteDataSigned outStart + 0, CLngInt(interceptValue * UXM_STAT_SCALE)
    StatWriteDataSigned outStart + 1, CLngInt(slopeValue * UXM_STAT_SCALE)
    StatWriteDataSigned outStart + 2, StatPearsonScaled(xStart, yStart, countValue)
    SetStatus STATUS_OK
End Sub



' --- V18 real statistical extensions: active implementations ---
Function StatPercentileScaledV18(ByVal startIndex As LongInt, ByVal countValue As LongInt, ByVal percentileScaled As LongInt) As LongInt
    Dim values(0 To 2047) As LongInt
    Dim i As LongInt, j As LongInt, tmp As LongInt, n As LongInt
    Dim pos As Double, lo As LongInt, hi As LongInt, frac As Double, val As Double
    If countValue <= 0 Then Return 0
    n=countValue: If n>2048 Then n=2048
    For i=0 To n-1: values(i)=StatReadSigned(startIndex+i): Next
    For i=0 To n-2
        For j=i+1 To n-1
            If values(j)<values(i) Then tmp=values(i): values(i)=values(j): values(j)=tmp
        Next
    Next
    If percentileScaled<0 Then percentileScaled=0
    If percentileScaled>1000000 Then percentileScaled=1000000
    If n=1 Then Return CLngInt(CDbl(values(0))*UXM_STAT_SCALE)
    pos=(CDbl(percentileScaled)/1000000.0)*CDbl(n-1)
    lo=CLngInt(Int(pos)): hi=lo+1: If hi>=n Then hi=n-1
    frac=pos-CDbl(lo)
    val=CDbl(values(lo))*(1.0-frac)+CDbl(values(hi))*frac
    Return CLngInt(val*UXM_STAT_SCALE)
End Function

Function StatSkewnessScaledV18(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim i As LongInt, mean As Double, m2 As Double, m3 As Double, d As Double, sd As Double
    If countValue<=2 Then Return 0
    mean=CDbl(StatSumSigned(startIndex,countValue))/CDbl(countValue)
    m2=0:m3=0
    For i=0 To countValue-1: d=CDbl(StatReadSigned(startIndex+i))-mean: m2+=d*d: m3+=d*d*d: Next
    If m2=0 Then Return 0
    sd=Sqr(m2/CDbl(countValue))
    Return CLngInt((m3/CDbl(countValue))/(sd*sd*sd)*UXM_STAT_SCALE)
End Function

Function StatKurtosisScaledV18(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim i As LongInt, mean As Double, m2 As Double, m4 As Double, d As Double
    If countValue<=3 Then Return 0
    mean=CDbl(StatSumSigned(startIndex,countValue))/CDbl(countValue)
    m2=0:m4=0
    For i=0 To countValue-1: d=CDbl(StatReadSigned(startIndex+i))-mean: m2+=d*d: m4+=d*d*d*d: Next
    If m2=0 Then Return 0
    Return CLngInt(((m4/CDbl(countValue))/((m2/CDbl(countValue))*(m2/CDbl(countValue)))-3.0)*UXM_STAT_SCALE)
End Function

Function StatRankOfV18(ByVal baseIndex As LongInt, ByVal countValue As LongInt, ByVal idx As LongInt) As Double
    Dim i As LongInt, less As LongInt, equal As LongInt, v As LongInt
    v=StatReadSigned(baseIndex+idx): less=0: equal=0
    For i=0 To countValue-1
        If StatReadSigned(baseIndex+i)<v Then less+=1
        If StatReadSigned(baseIndex+i)=v Then equal+=1
    Next
    Return CDbl(less)+((CDbl(equal)+1.0)/2.0)
End Function

Function StatSpearmanScaledV18(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt) As LongInt
    Dim i As LongInt, sx As Double, sy As Double, sxx As Double, syy As Double, sxy As Double, rx As Double, ry As Double, mx As Double, my As Double
    If countValue<=1 Then Return 0
    mx=0:my=0
    For i=0 To countValue-1: mx+=StatRankOfV18(xStart,countValue,i): my+=StatRankOfV18(yStart,countValue,i): Next
    mx/=CDbl(countValue): my/=CDbl(countValue)
    sxx=0:syy=0:sxy=0
    For i=0 To countValue-1
        rx=StatRankOfV18(xStart,countValue,i)-mx: ry=StatRankOfV18(yStart,countValue,i)-my
        sxx+=rx*rx: syy+=ry*ry: sxy+=rx*ry
    Next
    If sxx=0 Or syy=0 Then Return 0
    Return CLngInt((sxy/Sqr(sxx*syy))*UXM_STAT_SCALE)
End Function

Function StatKendallScaledV18(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt) As LongInt
    Dim i As LongInt, j As LongInt, concord As LongInt, discord As LongInt, dx As LongInt, dy As LongInt, pairs As LongInt
    If countValue<=1 Then Return 0
    concord=0:discord=0
    For i=0 To countValue-2
        For j=i+1 To countValue-1
            dx=StatReadSigned(xStart+i)-StatReadSigned(xStart+j)
            dy=StatReadSigned(yStart+i)-StatReadSigned(yStart+j)
            If dx*dy>0 Then concord+=1 ElseIf dx*dy<0 Then discord+=1
        Next
    Next
    pairs=countValue*(countValue-1)\2
    If pairs=0 Then Return 0
    Return CLngInt((CDbl(concord-discord)/CDbl(pairs))*UXM_STAT_SCALE)
End Function

Sub StatRegressionMultipleV18(ByVal xStart As LongInt, ByVal zStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt, ByVal outStart As LongInt)
    ' Two predictor least squares: y = b0 + b1*x + b2*z. Inputs: T-4=xStart, T-3=zStart, T-2=yStart, T-1=count, T0=outStart.
    Dim i As LongInt
    Dim sx As Double, sz As Double, sy As Double, sxx As Double, szz As Double, sxz As Double, sxy As Double, szy As Double
    Dim a00 As Double, a01 As Double, a02 As Double, a11 As Double, a12 As Double, a22 As Double
    Dim det As Double, b0 As Double, b1 As Double, b2 As Double
    If countValue<3 Or StatValidRange(xStart,countValue)=0 Or StatValidRange(zStart,countValue)=0 Or StatValidRange(yStart,countValue)=0 Or StatValidRange(outStart,3)=0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
    sx=0:sz=0:sy=0:sxx=0:szz=0:sxz=0:sxy=0:szy=0
    For i=0 To countValue-1
        Dim x As Double, z As Double, y As Double
        x=CDbl(StatReadSigned(xStart+i)): z=CDbl(StatReadSigned(zStart+i)): y=CDbl(StatReadSigned(yStart+i))
        sx+=x: sz+=z: sy+=y: sxx+=x*x: szz+=z*z: sxz+=x*z: sxy+=x*y: szy+=z*y
    Next
    a00=CDbl(countValue): a01=sx: a02=sz: a11=sxx: a12=sxz: a22=szz
    det=a00*(a11*a22-a12*a12)-a01*(a01*a22-a12*a02)+a02*(a01*a12-a11*a02)
    If Abs(det)<0.0000001 Then SetStatus STATUS_DIV_ZERO: Exit Sub
    b0=(sy*(a11*a22-a12*a12)-a01*(sxy*a22-a12*szy)+a02*(sxy*a12-a11*szy))/det
    b1=(a00*(sxy*a22-a12*szy)-sy*(a01*a22-a12*a02)+a02*(a01*szy-sxy*a02))/det
    b2=(a00*(a11*szy-sxy*a12)-a01*(a01*szy-sxy*a02)+sy*(a01*a12-a11*a02))/det
    StatWriteDataSigned outStart, CLngInt(b0*UXM_STAT_SCALE): StatWriteDataSigned outStart+1, CLngInt(b1*UXM_STAT_SCALE): StatWriteDataSigned outStart+2, CLngInt(b2*UXM_STAT_SCALE)
    SetStatus STATUS_OK
End Sub


Sub MetaStatistics(ByVal metaId As ULongInt)
    Dim startA As LongInt
    Dim startB As LongInt
    Dim countValue As LongInt
    Dim optionValue As LongInt
    Dim minValue As LongInt
    Dim maxValue As LongInt
    Dim meanScaled As LongInt
    Dim stdScaled As LongInt
    Dim zValue As Double
    Dim predX As Double
    Dim interceptScaled As Double
    Dim slopeScaled As Double
    Dim corrScaled As Double

    startA = CLngInt(ReadTapeRel(-3))
    startB = CLngInt(ReadTapeRel(-2))
    countValue = CLngInt(ReadTapeRel(-1))
    optionValue = CLngInt(ReadTapeRel(0))

    Select Case metaId
    Case 260 ' STAT_COUNT
        StatWriteTapeSigned 1, countValue
        SetStatus STATUS_OK
    Case 261 ' STAT_SUM
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatSumSigned(startA, countValue)
        SetStatus STATUS_OK
    Case 262 ' STAT_MEAN
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatMeanScaled(startA, countValue)
        SetStatus STATUS_OK
    Case 263 ' STAT_MIN
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatMinSigned(startA, countValue)
        SetStatus STATUS_OK
    Case 264 ' STAT_MAX
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatMaxSigned(startA, countValue)
        SetStatus STATUS_OK
    Case 265 ' STAT_RANGE
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        minValue = StatMinSigned(startA, countValue)
        maxValue = StatMaxSigned(startA, countValue)
        StatWriteTapeSigned 1, maxValue - minValue
        SetStatus STATUS_OK
    Case 266 ' STAT_VARIANCE
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatVarianceScaled(startA, countValue)
        SetStatus STATUS_OK
    Case 267 ' STAT_STDDEV
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatStdDevScaled(startA, countValue)
        SetStatus STATUS_OK
    Case 268 ' STAT_MEDIAN
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatMedianScaled(startA, countValue)
        SetStatus STATUS_OK

    Case 270 ' STAT_QUARTILE: option=1/2/3 -> quartile scaled
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        If optionValue <= 1 Then
            StatWriteTapeSigned 1, StatPercentileScaledV18(startA,countValue,250000)
        ElseIf optionValue = 2 Then
            StatWriteTapeSigned 1, StatPercentileScaledV18(startA,countValue,500000)
        Else
            StatWriteTapeSigned 1, StatPercentileScaledV18(startA,countValue,750000)
        End If
        SetStatus STATUS_OK
    Case 271 ' STAT_PERCENTILE: option = percentile scaled 0..1000000
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatPercentileScaledV18(startA,countValue,optionValue)
        SetStatus STATUS_OK
    Case 272 ' STAT_SKEWNESS
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatSkewnessScaledV18(startA,countValue)
        SetStatus STATUS_OK
    Case 273 ' STAT_KURTOSIS
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatKurtosisScaledV18(startA,countValue)
        SetStatus STATUS_OK
    Case 281 ' CORR_SPEARMAN
        If StatValidRange(startA, countValue) = 0 Or StatValidRange(startB, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatSpearmanScaledV18(startA,startB,countValue)
        SetStatus STATUS_OK
    Case 282 ' CORR_KENDALL
        If StatValidRange(startA, countValue) = 0 Or StatValidRange(startB, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatKendallScaledV18(startA,startB,countValue)
        SetStatus STATUS_OK
    Case 291 ' REG_MULTIPLE: T-4=x,T-3=z,T-2=y,T-1=count,T0=out
        StatRegressionMultipleV18 CLngInt(ReadTapeRel(-4)), CLngInt(ReadTapeRel(-3)), CLngInt(ReadTapeRel(-2)), CLngInt(ReadTapeRel(-1)), CLngInt(ReadTapeRel(0))
        SetResult ux_status
    Case 292 ' REG_POLYNOMIAL: quadratic simplified to linear fallback output b0,b1,b2=0
        StatLinearRegression CLngInt(ReadTapeRel(-4)), CLngInt(ReadTapeRel(-3)), CLngInt(ReadTapeRel(-2)), CLngInt(ReadTapeRel(0))
        StatWriteDataSigned CLngInt(ReadTapeRel(0))+3, 0
        SetResult ux_status
    Case 293 ' REG_LOGISTIC: one predictor probability at option x; writes scaled sigmoid(linear prediction)
        StatLinearRegression CLngInt(ReadTapeRel(-4)), CLngInt(ReadTapeRel(-3)), CLngInt(ReadTapeRel(-2)), CLngInt(ReadTapeRel(0))
        If ux_status=STATUS_OK Then
            Dim zz As Double
            zz = CDbl(ToSignedValue(ReadData(CLngInt(ReadTapeRel(0))))) / UXM_STAT_SCALE + (CDbl(ToSignedValue(ReadData(CLngInt(ReadTapeRel(0))+1))) / UXM_STAT_SCALE) * CDbl(ReadTapeRel(-1))
            StatWriteTapeSigned 1, CLngInt((1.0/(1.0+Exp(-zz)))*UXM_STAT_SCALE)
        End If
        SetResult ux_status

    Case 274 ' STAT_COVARIANCE
        StatWriteTapeSigned 1, StatCovarianceScaled(startA, startB, countValue)
        SetStatus STATUS_OK
    Case 275 ' STAT_ZSCORE
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        meanScaled = StatMeanScaled(startA, countValue)
        stdScaled = StatStdDevScaled(startA, countValue)
        If stdScaled = 0 Then
            StatWriteTapeSigned 1, 0
        Else
            zValue = ((CDbl(optionValue) * UXM_STAT_SCALE) - CDbl(meanScaled)) / CDbl(stdScaled)
            StatWriteTapeSigned 1, CLngInt(zValue * UXM_STAT_SCALE)
        End If
        SetStatus STATUS_OK
    Case 280 ' CORR_PEARSON
        StatWriteTapeSigned 1, StatPearsonScaled(startA, startB, countValue)
        SetStatus STATUS_OK
    Case 290 ' REG_LINEAR
        StatLinearRegression startA, startB, countValue, optionValue
        StatWriteTapeSigned 1, optionValue
    Case 298 ' REG_PREDICT: T-1=x, T=modelStart -> T+1=y_scaled
        If StatValidRange(optionValue, 2) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        predX = CDbl(countValue)
        interceptScaled = CDbl(StatReadSigned(optionValue + 0))
        slopeScaled = CDbl(StatReadSigned(optionValue + 1))
        StatWriteTapeSigned 1, CLngInt(interceptScaled + slopeScaled * predX)
        SetStatus STATUS_OK
    Case 299 ' REG_R2: T=modelStart -> T+1=r2_scaled
        If StatValidRange(optionValue, 3) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        corrScaled = CDbl(StatReadSigned(optionValue + 2)) / UXM_STAT_SCALE
        StatWriteTapeSigned 1, CLngInt(corrScaled * corrScaled * UXM_STAT_SCALE)
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
