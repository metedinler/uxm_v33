#ifndef UXM_RUNTIME_PROBABILITY_SERVICES_BAS
#define UXM_RUNTIME_PROBABILITY_SERVICES_BAS

' UXM V3.3 Stage-9 Probability / Random Services
' Service range: @380..@389
' All scaled decimal values use 1,000,000.

Const UXM_PROB_SCALE As Double = 1000000.0
Const UXM_PROB_OK As UByte = 0
Const UXM_PROB_PARAM_ERR As UByte = 27

Dim Shared ux_prob_state As ULongInt = 2463534242
Dim Shared ux_prob_status As ULongInt = 0

Sub ProbSetLocalStatus(ByVal st As ULongInt)
    ux_prob_status = st
    If st = 0 Then SetStatus STATUS_OK Else SetStatus CByte(st And &HFF)
End Sub

Sub ProbSeed(ByVal seedValue As ULongInt)
    If seedValue = 0 Then seedValue = 2463534242
    ux_prob_state = seedValue
End Sub

Function ProbRand32() As ULongInt
    Dim x As ULongInt
    x = ux_prob_state
    x = x Xor (x Shl 13)
    x = x Xor (x Shr 17)
    x = x Xor (x Shl 5)
    ux_prob_state = x
    Return x
End Function

Function ProbRand01() As Double
    Return CDbl(ProbRand32()) / 4294967296.0
End Function

Function ProbNormal(ByVal mu As Double, ByVal sigma As Double) As Double
    Dim u1 As Double
    Dim u2 As Double
    Dim z0 As Double
    If sigma <= 0 Then Return mu
    u1 = ProbRand01()
    u2 = ProbRand01()
    If u1 < 0.0000000001 Then u1 = 0.0000000001
    z0 = Sqr(-2.0 * Log(u1)) * Cos(6.2831853071795864769 * u2)
    Return mu + sigma * z0
End Function

Function ProbPoisson(ByVal lambdaValue As Double) As LongInt
    Dim limitValue As Double
    Dim kValue As LongInt
    Dim productValue As Double
    If lambdaValue <= 0 Then Return 0
    If lambdaValue > 50.0 Then
        Dim approxValue As Double
        approxValue = ProbNormal(lambdaValue, Sqr(lambdaValue))
        If approxValue < 0 Then approxValue = 0
        Return CLngInt(approxValue + 0.5)
    End If
    limitValue = Exp(-lambdaValue)
    kValue = 0
    productValue = 1.0
    Do
        kValue += 1
        productValue *= ProbRand01()
    Loop While productValue > limitValue
    Return kValue - 1
End Function

Function ProbBinomial(ByVal nValue As LongInt, ByVal pValue As Double) As LongInt
    Dim loopIndex As LongInt
    Dim countValue As LongInt
    If nValue <= 0 Then Return 0
    If pValue <= 0 Then Return 0
    If pValue >= 1 Then Return nValue
    countValue = 0
    For loopIndex = 1 To nValue
        If ProbRand01() < pValue Then countValue += 1
    Next
    Return countValue
End Function

Function ProbWeightedIndex(ByVal startIndex As LongInt, ByVal countValue As LongInt) As LongInt
    Dim loopIndex As LongInt
    Dim totalWeight As Double
    Dim selectedValue As Double
    Dim accumWeight As Double
    Dim weightValue As Double
    If countValue <= 0 Then Return -1
    If startIndex < 0 Then Return -1
    If startIndex + countValue > CLngInt(ux_data_cells) Then Return -1
    totalWeight = 0
    For loopIndex = 0 To countValue - 1
        weightValue = CDbl(ToSignedValue(ReadData(startIndex + loopIndex)))
        If weightValue > 0 Then totalWeight += weightValue
    Next
    If totalWeight <= 0 Then Return -1
    selectedValue = ProbRand01() * totalWeight
    accumWeight = 0
    For loopIndex = 0 To countValue - 1
        weightValue = CDbl(ToSignedValue(ReadData(startIndex + loopIndex)))
        If weightValue > 0 Then
            accumWeight += weightValue
            If selectedValue <= accumWeight Then Return loopIndex
        End If
    Next
    Return countValue - 1
End Function

Sub ProbShuffleData(ByVal startIndex As LongInt, ByVal countValue As LongInt)
    Dim loopIndex As LongInt
    Dim swapIndex As LongInt
    Dim tempValue As ULongInt
    If countValue <= 1 Then Exit Sub
    If startIndex < 0 Then Exit Sub
    If startIndex + countValue > CLngInt(ux_data_cells) Then Exit Sub
    For loopIndex = countValue - 1 To 1 Step -1
        swapIndex = CInt(ProbRand01() * CDbl(loopIndex + 1))
        tempValue = ReadData(startIndex + loopIndex)
        WriteData startIndex + loopIndex, ReadData(startIndex + swapIndex)
        WriteData startIndex + swapIndex, tempValue
    Next
End Sub

Sub MetaProbability(ByVal metaId As ULongInt)
    Dim aValue As LongInt
    Dim bValue As LongInt
    Select Case metaId
    Case 380 ' RAND_SEED: T-1 seed
        ProbSeed CULngInt(ReadTapeRel(-1))
        SetResult 0
        ProbSetLocalStatus 0
    Case 381 ' RAND_UNIFORM_01: T+1 scaled 0..999999
        SetResult CULngInt(ProbRand01() * UXM_PROB_SCALE) And CellMask()
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 382 ' RAND_INT_RANGE: T-2 min, T-1 max -> T+1
        aValue = ToSignedValue(ReadTapeRel(-2))
        bValue = ToSignedValue(ReadTapeRel(-1))
        If bValue < aValue Then
            Dim tmpRange As LongInt
            tmpRange = aValue
            aValue = bValue
            bValue = tmpRange
        End If
        SetResult FromSignedValue(aValue + CLngInt(Int(ProbRand01() * CDbl(bValue - aValue + 1))))
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 383 ' RAND_BERNOULLI: T-1 probability_scaled -> T+1 0/1
        If ProbRand01() < (CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_PROB_SCALE) Then
            SetResult 1
        Else
            SetResult 0
        End If
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 384 ' RAND_POISSON: T-1 lambda_scaled -> T+1 count
        SetResult FromSignedValue(ProbPoisson(CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_PROB_SCALE))
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 385 ' RAND_BINOMIAL: T-2 n, T-1 p_scaled -> T+1 count
        SetResult FromSignedValue(ProbBinomial(ToSignedValue(ReadTapeRel(-2)), CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_PROB_SCALE))
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 386 ' RAND_WEIGHTED: T-2 data_start, T-1 count -> T+1 index
        SetResult FromSignedValue(ProbWeightedIndex(ToSignedValue(ReadTapeRel(-2)), ToSignedValue(ReadTapeRel(-1))))
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 387 ' RAND_SHUFFLE_DATA: T-2 data_start, T-1 count -> T+1 status
        ProbShuffleData ToSignedValue(ReadTapeRel(-2)), ToSignedValue(ReadTapeRel(-1))
        SetResult 0
        ProbSetLocalStatus 0
    Case 388 ' RAND_NORMAL_SCALED: T-2 mean_scaled, T-1 sd_scaled -> T+1 scaled
        SetResult FromSignedValue(CLngInt(ProbNormal(CDbl(ToSignedValue(ReadTapeRel(-2))) / UXM_PROB_SCALE, CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_PROB_SCALE) * UXM_PROB_SCALE))
        SetLogicFlags ResultValue()
        ProbSetLocalStatus 0
    Case 389 ' RAND_STATUS
        SetResult ux_prob_status
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
