' Auto-split by V3 modularization
Function IsSignedMode() As Long
If (ux_flags And FLAG_SGN)<>0 Then Return -1 Else Return 0
End Function

Function IsBigEndian() As Long
If (ux_flags And FLAG_END)<>0 Then Return -1 Else Return 0
End Function

Function IsWildMode() As Long
If (ux_flags And FLAG_WILD)<>0 Then Return -1 Else Return 0
End Function

Sub SetStatus(ByVal code As UByte)
ux_status=code
If code=0 Then
ux_flags=ux_flags And Not FLAG_ERR
Else
ux_flags=ux_flags Or FLAG_ERR
End If
End Sub

Sub ClearArithFlags()
ux_flags=ux_flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
End Sub

Sub SetZeroSignFlags(ByVal value As ULongInt)
ux_flags=ux_flags And Not (FLAG_Z Or FLAG_S)
value=value And CellMask()
If value=0 Then ux_flags=ux_flags Or FLAG_Z
If (value And CellSignBit())<>0 Then ux_flags=ux_flags Or FLAG_S
End Sub

Sub SetLogicFlags(ByVal resultMasked As ULongInt)
ClearArithFlags()
SetZeroSignFlags resultMasked
End Sub

Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Dim sa As LongInt
Dim sb As LongInt
Dim sr As LongInt
ClearArithFlags()
SetZeroSignFlags resultMasked
If resultFull>CellMask() Then ux_flags=ux_flags Or FLAG_C
sa=ToSignedValue(a)
sb=ToSignedValue(b)
sr=ToSignedValue(resultMasked)
If ((sa>=0 And sb>=0 And sr<0) Or (sa<0 And sb<0 And sr>=0)) Then ux_flags=ux_flags Or FLAG_O
End Sub

Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultMasked As ULongInt)
Dim sa As LongInt
Dim sb As LongInt
Dim sr As LongInt
ClearArithFlags()
SetZeroSignFlags resultMasked
If a>=b Then ux_flags=ux_flags Or FLAG_C
sa=ToSignedValue(a)
sb=ToSignedValue(b)
sr=ToSignedValue(resultMasked)
If ((sa>=0 And sb<0 And sr<0) Or (sa<0 And sb>=0 And sr>=0)) Then ux_flags=ux_flags Or FLAG_O
End Sub

Sub SetMulFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
ClearArithFlags()
SetZeroSignFlags resultMasked
If resultFull>CellMask() Then ux_flags=ux_flags Or FLAG_C Or FLAG_O
End Sub

Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
Dim r As ULongInt
r=(a-b) And CellMask()
ClearArithFlags()
If a=b Then ux_flags=ux_flags Or FLAG_Z
If a>=b Then ux_flags=ux_flags Or FLAG_C
If (r And CellSignBit())<>0 Then ux_flags=ux_flags Or FLAG_S
End Sub

Function Arg1() As ULongInt
Return ReadTape(CLngInt(ux_ptr)-2)
End Function

Function Arg2() As ULongInt
Return ReadTape(CLngInt(ux_ptr)-1)
End Function

Function Arg0() As ULongInt
Return ReadTape(CLngInt(ux_ptr))
End Function

Sub SetResult(ByVal value As ULongInt)
WriteTape CLngInt(ux_ptr)+1,value
End Sub

Function ResultValue() As ULongInt
Return ReadTape(CLngInt(ux_ptr)+1)
End Function

