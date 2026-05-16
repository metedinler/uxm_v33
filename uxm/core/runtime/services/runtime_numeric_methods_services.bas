#ifndef UXM_RUNTIME_NUMERIC_METHODS_SERVICES_BAS
#define UXM_RUNTIME_NUMERIC_METHODS_SERVICES_BAS

' UXM V3.3 Stage-9 Numerical Methods V1
' Service range: @420..@439
' Polynomial coefficients are stored in data[] as signed integers:
'   data[base+0]=degree, data[base+1+i]=coefficient for x^i
' Decimal inputs/outputs are scaled by 1,000,000.

Const UXM_NUM_SCALE As Double = 1000000.0
Dim Shared ux_num_status As ULongInt = 0

Sub NumSetLocalStatus(ByVal st As ULongInt)
    ux_num_status = st
    If st = 0 Then SetStatus STATUS_OK Else SetStatus CByte(st And &HFF)
End Sub

Function NumDataSigned(ByVal dataIndex As LongInt) As LongInt
    Return ToSignedValue(ReadData(dataIndex))
End Function

Function NumPolyEval(ByVal baseIndex As LongInt, ByVal xValue As Double) As Double
    Dim degreeValue As LongInt
    Dim loopIndex As LongInt
    Dim accumValue As Double
    If baseIndex < 0 Or baseIndex >= CLngInt(ux_data_cells) Then Return 0
    degreeValue = NumDataSigned(baseIndex)
    If degreeValue < 0 Then Return 0
    If baseIndex + degreeValue + 1 >= CLngInt(ux_data_cells) Then Return 0
    accumValue = 0
    For loopIndex = degreeValue To 0 Step -1
        accumValue = accumValue * xValue + CDbl(NumDataSigned(baseIndex + 1 + loopIndex))
    Next
    Return accumValue
End Function

Function NumPolyDerivEval(ByVal baseIndex As LongInt, ByVal xValue As Double) As Double
    Dim degreeValue As LongInt
    Dim loopIndex As LongInt
    Dim accumValue As Double
    If baseIndex < 0 Or baseIndex >= CLngInt(ux_data_cells) Then Return 0
    degreeValue = NumDataSigned(baseIndex)
    If degreeValue <= 0 Then Return 0
    If baseIndex + degreeValue + 1 >= CLngInt(ux_data_cells) Then Return 0
    accumValue = 0
    For loopIndex = degreeValue To 1 Step -1
        accumValue = accumValue * xValue + CDbl(loopIndex) * CDbl(NumDataSigned(baseIndex + 1 + loopIndex))
    Next
    Return accumValue
End Function

Function NumNewton(ByVal baseIndex As LongInt, ByVal x0 As Double, ByVal maxIter As LongInt, ByVal epsValue As Double, ByRef statusOut As ULongInt) As Double
    Dim xValue As Double
    Dim fxValue As Double
    Dim dfxValue As Double
    Dim nextValue As Double
    Dim loopIndex As LongInt
    xValue = x0
    statusOut = 0
    If maxIter <= 0 Then maxIter = 20
    If epsValue <= 0 Then epsValue = 0.000001
    For loopIndex = 1 To maxIter
        fxValue = NumPolyEval(baseIndex, xValue)
        dfxValue = NumPolyDerivEval(baseIndex, xValue)
        If Abs(dfxValue) < epsValue Then statusOut = 28: Return xValue
        nextValue = xValue - fxValue / dfxValue
        If Abs(nextValue - xValue) < epsValue Then Return nextValue
        xValue = nextValue
    Next
    statusOut = 28
    Return xValue
End Function

Function NumBisection(ByVal baseIndex As LongInt, ByVal aValue As Double, ByVal bValue As Double, ByVal maxIter As LongInt, ByVal epsValue As Double, ByRef statusOut As ULongInt) As Double
    Dim loValue As Double
    Dim hiValue As Double
    Dim faValue As Double
    Dim fbValue As Double
    Dim midValue As Double
    Dim fmValue As Double
    Dim loopIndex As LongInt
    If maxIter <= 0 Then maxIter = 30
    If epsValue <= 0 Then epsValue = 0.000001
    loValue = aValue
    hiValue = bValue
    faValue = NumPolyEval(baseIndex, loValue)
    fbValue = NumPolyEval(baseIndex, hiValue)
    If faValue * fbValue > 0 Then statusOut = 29: Return loValue
    statusOut = 0
    For loopIndex = 1 To maxIter
        midValue = (loValue + hiValue) / 2.0
        fmValue = NumPolyEval(baseIndex, midValue)
        If Abs(fmValue) < epsValue Or Abs(hiValue - loValue) < epsValue Then Return midValue
        If faValue * fmValue <= 0 Then
            hiValue = midValue
            fbValue = fmValue
        Else
            loValue = midValue
            faValue = fmValue
        End If
    Next
    Return (loValue + hiValue) / 2.0
End Function

Function NumTrapezoid(ByVal baseIndex As LongInt, ByVal aValue As Double, ByVal bValue As Double, ByVal nValue As LongInt) As Double
    Dim hValue As Double
    Dim sumValue As Double
    Dim loopIndex As LongInt
    If nValue < 1 Then nValue = 1
    hValue = (bValue - aValue) / CDbl(nValue)
    sumValue = 0.5 * (NumPolyEval(baseIndex, aValue) + NumPolyEval(baseIndex, bValue))
    For loopIndex = 1 To nValue - 1
        sumValue += NumPolyEval(baseIndex, aValue + CDbl(loopIndex) * hValue)
    Next
    Return sumValue * hValue
End Function

Function NumSimpson(ByVal baseIndex As LongInt, ByVal aValue As Double, ByVal bValue As Double, ByVal nValue As LongInt) As Double
    Dim hValue As Double
    Dim sumValue As Double
    Dim loopIndex As LongInt
    Dim coefValue As Double
    If nValue < 2 Then nValue = 2
    If (nValue Mod 2) = 1 Then nValue += 1
    hValue = (bValue - aValue) / CDbl(nValue)
    sumValue = NumPolyEval(baseIndex, aValue) + NumPolyEval(baseIndex, bValue)
    For loopIndex = 1 To nValue - 1
        If (loopIndex Mod 2) = 0 Then coefValue = 2.0 Else coefValue = 4.0
        sumValue += coefValue * NumPolyEval(baseIndex, aValue + CDbl(loopIndex) * hValue)
    Next
    Return sumValue * hValue / 3.0
End Function

Function NumLinearInterp(ByVal xBase As LongInt, ByVal yBase As LongInt, ByVal countValue As LongInt, ByVal xValue As Double, ByRef statusOut As ULongInt) As Double
    Dim loopIndex As LongInt
    Dim x0 As Double
    Dim x1 As Double
    Dim y0 As Double
    Dim y1 As Double
    statusOut = 30
    If countValue < 2 Then Return 0
    If xBase < 0 Or yBase < 0 Then Return 0
    If xBase + countValue > CLngInt(ux_data_cells) Or yBase + countValue > CLngInt(ux_data_cells) Then Return 0
    For loopIndex = 0 To countValue - 2
        x0 = CDbl(NumDataSigned(xBase + loopIndex))
        x1 = CDbl(NumDataSigned(xBase + loopIndex + 1))
        If (xValue >= x0 And xValue <= x1) Or (xValue >= x1 And xValue <= x0) Then
            y0 = CDbl(NumDataSigned(yBase + loopIndex))
            y1 = CDbl(NumDataSigned(yBase + loopIndex + 1))
            statusOut = 0
            If x1 = x0 Then Return y0
            Return y0 + (y1 - y0) * (xValue - x0) / (x1 - x0)
        End If
    Next
    Return 0
End Function

Function NumBezierQuadratic(ByVal p0 As Double, ByVal p1 As Double, ByVal p2 As Double, ByVal tValue As Double) As Double
    Dim uValue As Double
    uValue = 1.0 - tValue
    Return uValue*uValue*p0 + 2.0*uValue*tValue*p1 + tValue*tValue*p2
End Function

Function NumRK4Linear(ByVal y0 As Double, ByVal aValue As Double, ByVal dtValue As Double, ByVal stepsValue As LongInt) As Double
    Dim yValue As Double
    Dim k1 As Double
    Dim k2 As Double
    Dim k3 As Double
    Dim k4 As Double
    Dim loopIndex As LongInt
    yValue = y0
    If stepsValue < 0 Then stepsValue = 0
    For loopIndex = 1 To stepsValue
        k1 = aValue * yValue
        k2 = aValue * (yValue + 0.5 * dtValue * k1)
        k3 = aValue * (yValue + 0.5 * dtValue * k2)
        k4 = aValue * (yValue + dtValue * k3)
        yValue += dtValue * (k1 + 2.0*k2 + 2.0*k3 + k4) / 6.0
    Next
    Return yValue
End Function

Sub MetaNumericMethods(ByVal metaId As ULongInt)
    Dim statusValue As ULongInt
    Select Case metaId
    Case 420 ' NUM_POLY_EVAL: T-2 polyBase, T-1 x_scaled -> T+1 y_scaled
        SetResult FromSignedValue(CLngInt(NumPolyEval(ToSignedValue(ReadTapeRel(-2)), CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_NUM_SCALE) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus 0
    Case 421 ' NUM_NEWTON: T-4 polyBase,T-3 x0_scaled,T-2 maxIter,T-1 eps_scaled -> T+1 root_scaled
        SetResult FromSignedValue(CLngInt(NumNewton(ToSignedValue(ReadTapeRel(-4)), CDbl(ToSignedValue(ReadTapeRel(-3))) / UXM_NUM_SCALE, ToSignedValue(ReadTapeRel(-2)), CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_NUM_SCALE, statusValue) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus statusValue
    Case 422 ' NUM_BISECTION: T-4 polyBase,T-3 a_scaled,T-2 b_scaled,T-1 maxIter -> T+1 root_scaled
        SetResult FromSignedValue(CLngInt(NumBisection(ToSignedValue(ReadTapeRel(-4)), CDbl(ToSignedValue(ReadTapeRel(-3))) / UXM_NUM_SCALE, CDbl(ToSignedValue(ReadTapeRel(-2))) / UXM_NUM_SCALE, ToSignedValue(ReadTapeRel(-1)), 0.000001, statusValue) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus statusValue
    Case 423 ' NUM_TRAPEZOID_POLY: T-4 polyBase,T-3 a_scaled,T-2 b_scaled,T-1 n -> area_scaled
        SetResult FromSignedValue(CLngInt(NumTrapezoid(ToSignedValue(ReadTapeRel(-4)), CDbl(ToSignedValue(ReadTapeRel(-3))) / UXM_NUM_SCALE, CDbl(ToSignedValue(ReadTapeRel(-2))) / UXM_NUM_SCALE, ToSignedValue(ReadTapeRel(-1))) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus 0
    Case 424 ' NUM_SIMPSON_POLY
        SetResult FromSignedValue(CLngInt(NumSimpson(ToSignedValue(ReadTapeRel(-4)), CDbl(ToSignedValue(ReadTapeRel(-3))) / UXM_NUM_SCALE, CDbl(ToSignedValue(ReadTapeRel(-2))) / UXM_NUM_SCALE, ToSignedValue(ReadTapeRel(-1))) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus 0
    Case 425 ' NUM_INTERP_LINEAR: T-4 xBase,T-3 yBase,T-2 count,T-1 x_raw -> y_raw_scaled
        SetResult FromSignedValue(CLngInt(NumLinearInterp(ToSignedValue(ReadTapeRel(-4)), ToSignedValue(ReadTapeRel(-3)), ToSignedValue(ReadTapeRel(-2)), CDbl(ToSignedValue(ReadTapeRel(-1))), statusValue) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus statusValue
    Case 426 ' NUM_BEZIER_QUADRATIC: T-4 p0,T-3 p1,T-2 p2,T-1 t_scaled -> result_scaled
        SetResult FromSignedValue(CLngInt(NumBezierQuadratic(CDbl(ToSignedValue(ReadTapeRel(-4))), CDbl(ToSignedValue(ReadTapeRel(-3))), CDbl(ToSignedValue(ReadTapeRel(-2))), CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_NUM_SCALE) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus 0
    Case 427 ' NUM_RK4_LINEAR: T-4 y0,T-3 a_scaled,T-2 dt_scaled,T-1 steps -> y_scaled
        SetResult FromSignedValue(CLngInt(NumRK4Linear(CDbl(ToSignedValue(ReadTapeRel(-4))), CDbl(ToSignedValue(ReadTapeRel(-3))) / UXM_NUM_SCALE, CDbl(ToSignedValue(ReadTapeRel(-2))) / UXM_NUM_SCALE, ToSignedValue(ReadTapeRel(-1))) * UXM_NUM_SCALE))
        SetLogicFlags ResultValue()
        NumSetLocalStatus 0
    Case 439 ' NUM_STATUS
        SetResult ux_num_status
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
