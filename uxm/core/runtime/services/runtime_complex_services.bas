#ifndef UXM_RUNTIME_COMPLEX_SERVICES_BAS
#define UXM_RUNTIME_COMPLEX_SERVICES_BAS

' UXM V3.3 Stage-9 Complex Number Services
' Service range: @440..@459
' Complex block in data[]:
'   D:BASE+0 = 67 magic marker
'   D:BASE+1 = real scaled 1e6, signed
'   D:BASE+2 = imag scaled 1e6, signed
'   D:BASE+3 = local status

Const UXM_CPLX_SCALE As Double = 1000000.0
Dim Shared ux_cplx_status As ULongInt = 0

Sub CplxSetLocalStatus(ByVal st As ULongInt)
    ux_cplx_status = st
    If st = 0 Then SetStatus STATUS_OK Else SetStatus CByte(st And &HFF)
End Sub

Sub CplxStoreScaled(ByVal baseIndex As LongInt, ByVal realScaled As LongInt, ByVal imagScaled As LongInt)
    If baseIndex < 0 Or baseIndex + 3 >= CLngInt(ux_data_cells) Then
        CplxSetLocalStatus 31
        Exit Sub
    End If
    WriteData baseIndex, 67
    WriteData baseIndex + 1, FromSignedValue(realScaled)
    WriteData baseIndex + 2, FromSignedValue(imagScaled)
    WriteData baseIndex + 3, 0
    ux_cplx_status = 0
End Sub

Sub CplxGet(ByVal baseIndex As LongInt, ByRef realValue As Double, ByRef imagValue As Double)
    If baseIndex < 0 Or baseIndex + 3 >= CLngInt(ux_data_cells) Then
        realValue = 0
        imagValue = 0
        ux_cplx_status = 31
        Exit Sub
    End If
    realValue = CDbl(ToSignedValue(ReadData(baseIndex + 1))) / UXM_CPLX_SCALE
    imagValue = CDbl(ToSignedValue(ReadData(baseIndex + 2))) / UXM_CPLX_SCALE
    ux_cplx_status = 0
End Sub

Sub CplxStore(ByVal baseIndex As LongInt, ByVal realValue As Double, ByVal imagValue As Double)
    CplxStoreScaled baseIndex, CLngInt(realValue * UXM_CPLX_SCALE), CLngInt(imagValue * UXM_CPLX_SCALE)
End Sub

Function CplxArgValue(ByVal realValue As Double, ByVal imagValue As Double) As Double
    If realValue = 0 Then
        If imagValue > 0 Then Return PI_D / 2.0
        If imagValue < 0 Then Return -PI_D / 2.0
        Return 0
    End If
    If realValue > 0 Then Return Atn(imagValue / realValue)
    If imagValue >= 0 Then Return Atn(imagValue / realValue) + PI_D
    Return Atn(imagValue / realValue) - PI_D
End Function

Sub MetaComplex(ByVal metaId As ULongInt)
    Dim outBase As LongInt
    Dim aBase As LongInt
    Dim bBase As LongInt
    Dim ar As Double
    Dim ai As Double
    Dim br As Double
    Dim bi As Double
    Dim denomValue As Double
    Select Case metaId
    Case 440 ' CPLX_INIT: T-2 out, T-1 real_scaled, T imag_scaled
        CplxStoreScaled ToSignedValue(ReadTapeRel(-2)), ToSignedValue(ReadTapeRel(-1)), ToSignedValue(ReadTapeRel(0))
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 441 ' CPLX_ADD: T-2 out, T-1 aBase, T bBase
        outBase = ToSignedValue(ReadTapeRel(-2))
        aBase = ToSignedValue(ReadTapeRel(-1))
        bBase = ToSignedValue(ReadTapeRel(0))
        CplxGet aBase, ar, ai
        CplxGet bBase, br, bi
        CplxStore outBase, ar + br, ai + bi
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 442 ' CPLX_SUB
        outBase = ToSignedValue(ReadTapeRel(-2))
        aBase = ToSignedValue(ReadTapeRel(-1))
        bBase = ToSignedValue(ReadTapeRel(0))
        CplxGet aBase, ar, ai
        CplxGet bBase, br, bi
        CplxStore outBase, ar - br, ai - bi
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 443 ' CPLX_MUL
        outBase = ToSignedValue(ReadTapeRel(-2))
        aBase = ToSignedValue(ReadTapeRel(-1))
        bBase = ToSignedValue(ReadTapeRel(0))
        CplxGet aBase, ar, ai
        CplxGet bBase, br, bi
        CplxStore outBase, ar*br - ai*bi, ar*bi + ai*br
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 444 ' CPLX_DIV
        outBase = ToSignedValue(ReadTapeRel(-2))
        aBase = ToSignedValue(ReadTapeRel(-1))
        bBase = ToSignedValue(ReadTapeRel(0))
        CplxGet aBase, ar, ai
        CplxGet bBase, br, bi
        denomValue = br*br + bi*bi
        If Abs(denomValue) < 0.000000000001 Then
            SetResult 32
            CplxSetLocalStatus 32
        Else
            CplxStore outBase, (ar*br + ai*bi) / denomValue, (ai*br - ar*bi) / denomValue
            SetResult ux_cplx_status
            CplxSetLocalStatus ux_cplx_status
        End If
    Case 445 ' CPLX_CONJ: T-2 out, T-1 aBase
        outBase = ToSignedValue(ReadTapeRel(-2))
        aBase = ToSignedValue(ReadTapeRel(-1))
        CplxGet aBase, ar, ai
        CplxStore outBase, ar, -ai
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 446 ' CPLX_ABS: T-1 aBase -> T+1 scaled magnitude
        aBase = ToSignedValue(ReadTapeRel(-1))
        CplxGet aBase, ar, ai
        SetResult FromSignedValue(CLngInt(Sqr(ar*ar + ai*ai) * UXM_CPLX_SCALE))
        SetLogicFlags ResultValue()
        CplxSetLocalStatus ux_cplx_status
    Case 447 ' CPLX_ARG: T-1 aBase -> T+1 scaled radians
        aBase = ToSignedValue(ReadTapeRel(-1))
        CplxGet aBase, ar, ai
        SetResult FromSignedValue(CLngInt(CplxArgValue(ar, ai) * UXM_CPLX_SCALE))
        SetLogicFlags ResultValue()
        CplxSetLocalStatus ux_cplx_status
    Case 448 ' CPLX_EXP: T-2 out, T-1 aBase
        outBase = ToSignedValue(ReadTapeRel(-2))
        aBase = ToSignedValue(ReadTapeRel(-1))
        CplxGet aBase, ar, ai
        CplxStore outBase, Exp(ar) * Cos(ai), Exp(ar) * Sin(ai)
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 449 ' CPLX_FROM_POLAR: T-2 out, T-1 radius_scaled, T theta_scaled
        CplxStore ToSignedValue(ReadTapeRel(-2)), CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_CPLX_SCALE * Cos(CDbl(ToSignedValue(ReadTapeRel(0))) / UXM_CPLX_SCALE), CDbl(ToSignedValue(ReadTapeRel(-1))) / UXM_CPLX_SCALE * Sin(CDbl(ToSignedValue(ReadTapeRel(0))) / UXM_CPLX_SCALE)
        SetResult ux_cplx_status
        CplxSetLocalStatus ux_cplx_status
    Case 459 ' CPLX_STATUS
        SetResult ux_cplx_status
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
