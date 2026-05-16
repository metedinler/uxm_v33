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


' UXM V16 GERCEK KOD EKLERI
' Kılavuzda "var" görünen ama önceki registry'de placeholder kalan istatistik servislerini
' gerçek hesaplama fonksiyonlarına bağlar. Tüm kesirli sonuçlar UXM_STAT_SCALE ile ölçeklenir.
Function StatSortedValue(ByVal startIndex As LongInt, ByVal countValue As LongInt, ByVal sortedIndex As LongInt) As LongInt
    Dim values(0 To 2047) As LongInt
    Dim loopIndex As LongInt
    Dim sortIndex As LongInt
    Dim tmpValue As LongInt
    Dim cappedCount As LongInt
    If countValue <= 0 Then Return 0
    cappedCount = countValue
    If cappedCount > 2048 Then cappedCount = 2048
    If sortedIndex < 0 Then sortedIndex = 0
    If sortedIndex >= cappedCount Then sortedIndex = cappedCount - 1
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
    Return values(sortedIndex)
End Function

Function StatPercentileScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt, ByVal percentileValue As LongInt) As LongInt
    Dim posValue As Double
    Dim loIndex As LongInt
    Dim hiIndex As LongInt
    Dim fracValue As Double
    Dim loValue As Double
    Dim hiValue As Double
    If countValue <= 0 Then Return 0
    If percentileValue < 0 Then percentileValue = 0
    If percentileValue > 100 Then percentileValue = 100
    If countValue = 1 Then Return CLngInt(CDbl(StatSortedValue(startIndex, countValue, 0)) * UXM_STAT_SCALE)
    posValue = (CDbl(countValue - 1) * CDbl(percentileValue)) / 100.0
    loIndex = CLngInt(Int(posValue))
    hiIndex = loIndex + 1
    If hiIndex >= countValue Then hiIndex = countValue - 1
    fracValue = posValue - CDbl(loIndex)
    loValue = CDbl(StatSortedValue(startIndex, countValue, loIndex))
    hiValue = CDbl(StatSortedValue(startIndex, countValue, hiIndex))
    Return CLngInt((loValue + (hiValue - loValue) * fracValue) * UXM_STAT_SCALE)
End Function

Function StatQuartileScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt, ByVal quartileIndex As LongInt) As LongInt
    If quartileIndex < 1 Then quartileIndex = 2
    If quartileIndex > 3 Then quartileIndex = 3
    Return StatPercentileScaled(startIndex, countValue, quartileIndex * 25)
End Function

Function StatSkewnessScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim meanValue As Double
    Dim deltaValue As Double
    Dim m2 As Double
    Dim m3 As Double
    If countValue <= 2 Then Return 0
    meanValue = CDbl(StatSumSigned(startIndex, countValue)) / CDbl(countValue)
    m2 = 0
    m3 = 0
    For loopIndex = 0 To countValue - 1
        deltaValue = CDbl(StatReadSigned(startIndex + loopIndex)) - meanValue
        m2 += deltaValue * deltaValue
        m3 += deltaValue * deltaValue * deltaValue
    Next
    m2 = m2 / CDbl(countValue)
    m3 = m3 / CDbl(countValue)
    If m2 = 0 Then Return 0
    Return CLngInt((m3 / (Sqr(m2) * m2)) * UXM_STAT_SCALE)
End Function

Function StatKurtosisScaled(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim meanValue As Double
    Dim deltaValue As Double
    Dim m2 As Double
    Dim m4 As Double
    If countValue <= 3 Then Return 0
    meanValue = CDbl(StatSumSigned(startIndex, countValue)) / CDbl(countValue)
    m2 = 0
    m4 = 0
    For loopIndex = 0 To countValue - 1
        deltaValue = CDbl(StatReadSigned(startIndex + loopIndex)) - meanValue
        m2 += deltaValue * deltaValue
        m4 += deltaValue * deltaValue * deltaValue * deltaValue
    Next
    m2 = m2 / CDbl(countValue)
    m4 = m4 / CDbl(countValue)
    If m2 = 0 Then Return 0
    Return CLngInt(((m4 / (m2 * m2)) - 3.0) * UXM_STAT_SCALE)
End Function

Sub StatRanks(ByVal startIndex As LongInt, ByVal countValue As LongInt, ByRef ranks() As Double)
    Dim i As LongInt
    Dim j As LongInt
    Dim lessCount As LongInt
    Dim equalCount As LongInt
    For i = 0 To countValue - 1
        lessCount = 0
        equalCount = 0
        For j = 0 To countValue - 1
            If StatReadSigned(startIndex + j) < StatReadSigned(startIndex + i) Then lessCount += 1
            If StatReadSigned(startIndex + j) = StatReadSigned(startIndex + i) Then equalCount += 1
        Next
        ranks(i) = CDbl(lessCount) + (CDbl(equalCount) + 1.0) / 2.0
    Next
End Sub

Function StatSpearmanScaled(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt) As LongInt
    Dim rx(0 To 2047) As Double
    Dim ry(0 To 2047) As Double
    Dim i As LongInt
    Dim mx As Double
    Dim my As Double
    Dim num As Double
    Dim sx As Double
    Dim sy As Double
    Dim dx As Double
    Dim dy As Double
    If countValue <= 1 Then Return 0
    If countValue > 2048 Then countValue = 2048
    StatRanks xStart, countValue, rx()
    StatRanks yStart, countValue, ry()
    mx = (CDbl(countValue) + 1.0) / 2.0
    my = mx
    For i = 0 To countValue - 1
        dx = rx(i) - mx
        dy = ry(i) - my
        num += dx * dy
        sx += dx * dx
        sy += dy * dy
    Next
    If sx = 0 Or sy = 0 Then Return 0
    Return CLngInt((num / Sqr(sx * sy)) * UXM_STAT_SCALE)
End Function

Function StatKendallScaled(ByVal xStart As LongInt, ByVal yStart As LongInt, ByVal countValue As LongInt) As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim dx As LongInt
    Dim dy As LongInt
    Dim concordant As Double
    Dim discordant As Double
    Dim tieX As Double
    Dim tieY As Double
    Dim den As Double
    If countValue <= 1 Then Return 0
    If countValue > 2048 Then countValue = 2048
    For i = 0 To countValue - 2
        For j = i + 1 To countValue - 1
            dx = StatReadSigned(xStart + i) - StatReadSigned(xStart + j)
            dy = StatReadSigned(yStart + i) - StatReadSigned(yStart + j)
            If dx = 0 And dy = 0 Then
                ' both tied: tau-b denominator handles it; numerator unchanged
            ElseIf dx = 0 Then
                tieX += 1
            ElseIf dy = 0 Then
                tieY += 1
            ElseIf (dx > 0 And dy > 0) Or (dx < 0 And dy < 0) Then
                concordant += 1
            Else
                discordant += 1
            End If
        Next
    Next
    den = Sqr((concordant + discordant + tieX) * (concordant + discordant + tieY))
    If den = 0 Then Return 0
    Return CLngInt(((concordant - discordant) / den) * UXM_STAT_SCALE)
End Function

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
    Case 270 ' STAT_QUARTILE: T-3=start, T-1=count, T=quartile(1..3) -> T+1 scaled
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatQuartileScaled(startA, countValue, optionValue)
        SetStatus STATUS_OK
    Case 271 ' STAT_PERCENTILE: T-3=start, T-1=count, T=percentile(0..100) -> T+1 scaled
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatPercentileScaled(startA, countValue, optionValue)
        SetStatus STATUS_OK
    Case 272 ' STAT_SKEWNESS: population skewness scaled
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatSkewnessScaled(startA, countValue)
        SetStatus STATUS_OK
    Case 273 ' STAT_KURTOSIS: excess kurtosis scaled
        If StatValidRange(startA, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatKurtosisScaled(startA, countValue)
        SetStatus STATUS_OK
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
    Case 281 ' CORR_SPEARMAN: rank correlation scaled
        If StatValidRange(startA, countValue) = 0 Or StatValidRange(startB, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatSpearmanScaled(startA, startB, countValue)
        SetStatus STATUS_OK
    Case 282 ' CORR_KENDALL: Kendall tau-b scaled
        If StatValidRange(startA, countValue) = 0 Or StatValidRange(startB, countValue) = 0 Then SetStatus STATUS_DATA_BOUNDS: Exit Sub
        StatWriteTapeSigned 1, StatKendallScaled(startA, startB, countValue)
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
