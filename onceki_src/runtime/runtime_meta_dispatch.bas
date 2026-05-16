' Auto-split by V3 modularization
Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr) Export
If metaId<20 Then
MetaCore metaId
ElseIf metaId<40 Then
MetaArithmetic metaId
ElseIf metaId<60 Then
MetaMath metaId
ElseIf metaId<80 Then
MetaIO metaId
ElseIf metaId<90 Then
MetaPointerMemory metaId
ElseIf metaId<128 Then
MetaFifoDataSortWild metaId
ElseIf metaId>=150 And metaId<=159 Then
	MetaFlagsEndian metaId
ElseIf metaId>=160 And metaId<=199 Then
MetaMatrix metaId
ElseIf metaId>=200 And metaId<=239 Then
MetaFloatingPoint metaId
ElseIf metaId>=240 And metaId<=254 Then
MetaMathExtra metaId
ElseIf metaId>=260 And metaId<=299 Then
MetaStatistics metaId
ElseIf metaId>=300 And metaId<=319 Then
MetaString metaId
ElseIf metaId>=340 And metaId<=379 Then
MetaStringExt metaId
ElseIf metaId>=380 And metaId<=389 Then
MetaProbability metaId
ElseIf metaId>=400 And metaId<=415 Then
MetaFile metaId
ElseIf metaId>=420 And metaId<=439 Then
MetaNumericMethods metaId
ElseIf metaId>=440 And metaId<=459 Then
MetaComplex metaId
ElseIf metaId>=480 And metaId<=511 Then
MetaBio metaId
ElseIf metaId>=512 And metaId<=519 Then
MetaMatrixAdvancedTensor metaId
ElseIf metaId>=520 And metaId<=539 Then
MetaLinalgAdvanced metaId
ElseIf metaId>=540 And metaId<=599 Then
MetaMatrixAdvancedTensor metaId
ElseIf metaId>=600 And metaId<=679 Then
MetaSparseVector metaId
ElseIf metaId>=700 And metaId<=759 Then
MetaMLDataPipeline metaId
ElseIf RuntimeHookDispatchExt(metaId)<>0 Then
' Extension hook handled the service.
Else
SetStatus STATUS_INVALID_META
End If
End Sub
End Extern

Sub MetaCore(ByVal metaId As ULongInt)
Select Case metaId
Case 0
SetStatus STATUS_OK
Case 1
Cls
SetStatus STATUS_OK
Case 2
Locate 1,1
SetStatus STATUS_OK
Case 3
SetResult RandomByte()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 4
SetResult CULngInt(Timer*1000) And CellMask()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 5
Print
SetStatus STATUS_OK
Case 6
Print "[UXM META]";
SetStatus STATUS_OK
Case 7
SetResult 7
SetLogicFlags 7
SetStatus STATUS_OK
Case 8
SetResult 8
SetLogicFlags 8
SetStatus STATUS_OK
Case 9
SetResult ux_status
SetLogicFlags ux_status
Case 10
SetStatus STATUS_OK
Case 11
SetStatus CByte(Arg1() And &HFF)
Case 12
PrintStatusMessage ux_status
Case 13
If ux_status=0 Then SetStatus 1 Else SetStatus ux_status
Case 14
SetStatus STATUS_OK
Case 15
If (ux_flags And FLAG_ERR)<>0 Then
SetResult 1
SetLogicFlags 1
Else
SetResult 0
SetLogicFlags 0
End If
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub

Sub MetaArithmetic(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim r As ULongInt
Dim full As ULongInt
Dim sf As LongInt
Dim sb As LongInt
a=Arg1()
b=Arg2()
Select Case metaId
Case 20
full=a+b
r=full And CellMask()
SetResult r
SetAddFlags a,b,full,r
SetStatus STATUS_OK
Case 21
r=(a-b) And CellMask()
SetResult r
SetSubFlags a,b,r
SetStatus STATUS_OK
Case 22
full=a*b
r=full And CellMask()
SetResult r
SetMulFlags a,b,full,r
If full>CellMask() Then SetStatus STATUS_OVERFLOW Else SetStatus STATUS_OK
Case 23
If b=0 Then
SetResult 0
ux_flags=ux_flags Or FLAG_O Or FLAG_C Or FLAG_Z Or FLAG_ERR
SetStatus STATUS_DIV_ZERO
Else
If IsSignedMode() Then
sf=ToSignedValue(a)
sb=ToSignedValue(b)
If sb=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
r=FromSignedValue(sf\sb)
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
Else
r=(a\b) And CellMask()
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
End If
Case 24
If b=0 Then
SetResult 0
ux_flags=ux_flags Or FLAG_O Or FLAG_C Or FLAG_Z Or FLAG_ERR
SetStatus STATUS_DIV_ZERO
Else
If IsSignedMode() Then
sf=ToSignedValue(a)
sb=ToSignedValue(b)
If sb=0 Then
SetResult 0
SetStatus STATUS_DIV_ZERO
Else
r=FromSignedValue(sf Mod sb)
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
Else
r=(a Mod b) And CellMask()
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
End If
End If
Case 25
If a<b Then r=a Else r=b
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 26
If a>b Then r=a Else r=b
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 27
If IsSignedMode() Then
sf=ToSignedValue(b)
If sf<0 Then sf=-sf
r=FromSignedValue(sf)
Else
r=b
End If
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 28
sf=ToSignedValue(b)
r=FromSignedValue(-sf)
SetResult r
SetLogicFlags r
SetStatus STATUS_OK
Case 29
SetCompareFlags a,b
If a=b Then
r=0
ElseIf a>b Then
r=1
Else
r=CellMask()
End If
SetResult r
SetStatus STATUS_OK
Case 30
	If b<a Then
		SetResult a
		SetLogicFlags ResultValue()
		SetStatus STATUS_OK
	Else
		SetResult CULngInt(Int(Rnd*(b-a+1))+a) And CellMask()
		SetLogicFlags ResultValue()
		SetStatus STATUS_OK
	End If
Case 31
	Randomize CInt(b)
	SetStatus STATUS_OK
Case 32
	SetResult ClampToCell(CLngInt(Rnd*ScaleFactor()))
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 33
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=(a\b) And CellMask():SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case 34
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=FromSignedValue(ToSignedValue(a)\ToSignedValue(b)):SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case 35
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=(a Mod b) And CellMask():SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case 36
If b=0 Then SetResult 0:SetStatus STATUS_DIV_ZERO Else r=FromSignedValue(ToSignedValue(a) Mod ToSignedValue(b)):SetResult r:SetLogicFlags r:SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub

Sub MetaMath(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim x As Double
a=Arg1()
b=Arg2()
Select Case metaId
Case 40
SetResult ClampToCell(SinScaled(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 41
SetResult ClampToCell(CosScaled(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 42
If (b Mod 180)=90 Then
SetResult 0
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_OVERFLOW
Else
SetResult ClampToCell(TanScaled(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 43
SetResult ClampDoubleToCell(Sqr(CDbl(a)*CDbl(a)+CDbl(b)*CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 44
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
SetResult ClampToCell(CLngInt(AsinLocal(x)*180.0/PI_D))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 45
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
SetResult ClampToCell(CLngInt(AcosLocal(x)*180.0/PI_D))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 46
SetResult ClampDoubleToCell(Sqr(CDbl(b)))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 47
SetResult ClampDoubleToCell(SinhLocal(CDbl(b)*PI_D/180.0)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 48
SetResult ClampDoubleToCell(CoshLocal(CDbl(b)*PI_D/180.0)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 49
SetResult ClampDoubleToCell(TanhLocal(CDbl(b)*PI_D/180.0)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 52
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
SetResult ClampDoubleToCell(AsinhLocal(x)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 53
x=CDbl(b)/CDbl(ScaleFactor())
If x<1.0 Then
SetResult 0
SetStatus STATUS_UNDERFLOW
Else
SetResult ClampDoubleToCell(AcoshLocal(x)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 54
x=CDbl(ToSignedValue(b))/CDbl(ScaleFactor())
If Abs(x)>=1.0 Then
SetResult 0
SetStatus STATUS_OVERFLOW
Else
SetResult ClampDoubleToCell(AtanhLocal(x)*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 55
If b=0 Then
SetResult 0
SetStatus STATUS_UNDERFLOW
Else
SetResult ClampDoubleToCell(Log(CDbl(b))*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
End If
Case 56
SetResult ClampDoubleToCell(Exp(CDbl(ToSignedValue(b))/CDbl(ScaleFactor()))*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 57
SetResult ClampDoubleToCell(CDbl(a)^CDbl(b))
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 58
SetResult ClampDoubleToCell(CDbl(b)*PI_D/180.0*ScaleFactor())
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 59
SetResult ClampDoubleToCell(CDbl(b)/CDbl(ScaleFactor())*180.0/PI_D)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub

Sub MetaIO(ByVal metaId As ULongInt)
Select Case metaId
Case 60
PrintDecimalValue Arg2()
SetStatus STATUS_OK
Case 61
PrintDecimalValue ResultValue()
SetStatus STATUS_OK
Case 62
PrintDecimalValue StackPop()
Case 63
SetResult ReadDecimalValue()
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 64
Print " ";
SetStatus STATUS_OK
Case 67
Print Hex(Arg2());
SetStatus STATUS_OK
Case 68
Print Bin(Arg2());
SetStatus STATUS_OK
Case 69
Print Chr(Arg2() And &HFF);
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub

Sub MetaPointerMemory(ByVal metaId As ULongInt)
Dim a As ULongInt
a=Arg2()
Select Case metaId
Case 80
If a>=ux_tape_cells Then
SetStatus STATUS_PTR_BOUNDS
Else
ux_ptr=a
ux_flags=ux_flags Or FLAG_PCHG
SetStatus STATUS_OK
End If
Case 81
If ux_ptr+a>=ux_tape_cells Then
SetStatus STATUS_PTR_BOUNDS
Else
ux_ptr=ux_ptr+a
ux_flags=ux_flags Or FLAG_PCHG
SetStatus STATUS_OK
End If
Case 82
SetResult ux_ptr
SetLogicFlags ux_ptr
SetStatus STATUS_OK
Case 83
If ux_ptr<ux_tape_cells Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 84
SetResult ux_tape_cells
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 85
SetResult ux_data_cells
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 86
SetResult ux_stack_cells
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 87
SetResult ux_cell_bits
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 88
SetResult ux_cell_bytes
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 89
Print "[UXM layout tape=";ux_tape_cells;" stack=";ux_stack_cells;" data=";ux_data_cells;" cellbits=";ux_cell_bits;"]"
SetStatus STATUS_OK
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub

Sub MetaFifoDataSortWild(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim c As ULongInt
Dim r As LongInt
a=Arg1()
b=Arg2()
c=Arg0()
Select Case metaId
Case 90
FifoPush b
Case 91
SetResult FifoPop()
SetLogicFlags ResultValue()
Case 92
SetResult FifoPeek()
SetLogicFlags ResultValue()
Case 93
SetResult fifoCount
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 94
FifoClear()
Case 95
SetResult ReadData(b)
SetLogicFlags ResultValue()
Case 96
WriteData a,b
SetStatus STATUS_OK
Case 97
b=ReadData(b)
If b>=48 And b<=57 Then
SetResult b-48
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Else
SetResult 0
SetStatus STATUS_UNDERFLOW
End If
Case 98
DataBlockCopy a,b,c
Case 99
DataBlockClear a,b
Case 100
SortTape a,b,1
Case 101
SortTape a,b,0
Case 102
SortData a,b,1
Case 103
SortData a,b,0
Case 104
r=LinearSearchTape(a,b,c)
If r<0 Then SetResult CellMask() Else SetResult CULngInt(r)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 105
r=LinearSearchData(a,b,c)
If r<0 Then SetResult CellMask() Else SetResult CULngInt(r)
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 106
TapeBlockCopy a,b,c
Case 107
TapeBlockClear a,b
Case 120
ux_flags=ux_flags And Not FLAG_SGN
SetStatus STATUS_OK
Case 121
ux_flags=ux_flags Or FLAG_SGN
SetStatus STATUS_OK
Case 122
If IsSignedMode() Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 123
ux_flags=ux_flags And Not FLAG_END
SetStatus STATUS_OK
Case 124
ux_flags=ux_flags Or FLAG_END
SetStatus STATUS_OK
Case 125
If IsBigEndian() Then SetResult 1 Else SetResult 0
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 126
SetResult ux_flags
SetLogicFlags ResultValue()
SetStatus STATUS_OK
Case 127
WildLayoutChange()
Case Else
SetStatus STATUS_INVALID_META
End Select
End Sub

Sub MetaFlagsEndian(ByVal metaId As ULongInt)
Dim a As ULongInt
Dim b As ULongInt
Dim r As ULongInt
a=Arg1()
b=Arg2()
Select Case metaId
Case 120
	ux_flags=ux_flags And Not FLAG_SGN
	SetStatus STATUS_OK
Case 121
	ux_flags=ux_flags Or FLAG_SGN
	SetStatus STATUS_OK
Case 122
	If IsSignedMode() Then SetResult 1 Else SetResult 0
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 130
	If a=b Then r=1 Else r=0
	SetResult r
	SetCompareFlags a,b
	SetStatus STATUS_OK
Case 131
	If a>b Then r=1 Else r=0
	SetResult r
	SetCompareFlags a,b
	SetStatus STATUS_OK
Case 132
	If a<b Then r=1 Else r=0
	SetResult r
	SetCompareFlags a,b
	SetStatus STATUS_OK
Case 133
	If ToSignedValue(a)=ToSignedValue(b) Then r=1 Else r=0
	SetResult r
	SetCompareFlags a,b
	SetStatus STATUS_OK
Case 134
	If ToSignedValue(a)>ToSignedValue(b) Then r=1 Else r=0
	SetResult r
	SetCompareFlags a,b
	SetStatus STATUS_OK
Case 135
	If ToSignedValue(a)<ToSignedValue(b) Then r=1 Else r=0
	SetResult r
	SetCompareFlags a,b
	SetStatus STATUS_OK
Case 140
	If (ux_flags And FLAG_C)<>0 Then SetResult 1 Else SetResult 0
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 141
	ux_flags=ux_flags Or FLAG_C
	SetStatus STATUS_OK
Case 142
	ux_flags=ux_flags And Not FLAG_C
	SetStatus STATUS_OK
Case 143
	If (ux_flags And FLAG_O)<>0 Then SetResult 1 Else SetResult 0
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 144
	ux_flags=ux_flags Or FLAG_O
	SetStatus STATUS_OK
Case 145
	ux_flags=ux_flags And Not FLAG_O
	SetStatus STATUS_OK
Case 146
	If (ux_flags And FLAG_Z)<>0 Then SetResult 1 Else SetResult 0
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 147
	If (ux_flags And FLAG_S)<>0 Then SetResult 1 Else SetResult 0
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 148
	ux_flags=ux_flags And Not (FLAG_Z Or FLAG_C Or FLAG_O Or FLAG_S)
	SetStatus STATUS_OK
Case 149
	SetResult ux_flags
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 150
	ux_flags=ux_flags And Not FLAG_END
	SetStatus STATUS_OK
Case 151
	ux_flags=ux_flags Or FLAG_END
	SetStatus STATUS_OK
Case 152
	If IsBigEndian() Then SetResult 1 Else SetResult 0
	SetLogicFlags ResultValue()
	SetStatus STATUS_OK
Case 153
	If IsBigEndian() Then
		WriteTapeRel 1,(b Shr 8) And &HFF
		WriteTapeRel 2,b And &HFF
	Else
		WriteTapeRel 1,b And &HFF
		WriteTapeRel 2,(b Shr 8) And &HFF
	End If
	SetStatus STATUS_OK
Case 154
	If IsBigEndian() Then
		r=((ReadTapeRel(1) And &HFF) Shl 8) Or (ReadTapeRel(2) And &HFF)
	Else
		r=(ReadTapeRel(1) And &HFF) Or ((ReadTapeRel(2) And &HFF) Shl 8)
	End If
	SetResult r
	SetLogicFlags r
	SetStatus STATUS_OK
Case 155
	If IsBigEndian() Then
		WriteTapeRel 1,(b Shr 24) And &HFF
		WriteTapeRel 2,(b Shr 16) And &HFF
		WriteTapeRel 3,(b Shr 8) And &HFF
		WriteTapeRel 4,b And &HFF
	Else
		WriteTapeRel 1,b And &HFF
		WriteTapeRel 2,(b Shr 8) And &HFF
		WriteTapeRel 3,(b Shr 16) And &HFF
		WriteTapeRel 4,(b Shr 24) And &HFF
	End If
	SetStatus STATUS_OK
Case 156
	If IsBigEndian() Then
		r=((ReadTapeRel(1) And &HFF) Shl 24) Or ((ReadTapeRel(2) And &HFF) Shl 16) Or ((ReadTapeRel(3) And &HFF) Shl 8) Or (ReadTapeRel(4) And &HFF)
	Else
		r=(ReadTapeRel(1) And &HFF) Or ((ReadTapeRel(2) And &HFF) Shl 8) Or ((ReadTapeRel(3) And &HFF) Shl 16) Or ((ReadTapeRel(4) And &HFF) Shl 24)
	End If
	SetResult r
	SetLogicFlags r
	SetStatus STATUS_OK
Case Else
	SetStatus STATUS_INVALID_META
End Select
End Sub
#Include Once "services/runtime_fp_services.bas"
#Include Once "services/runtime_matrix_services.bas"
#Include Once "services/runtime_math_services.bas"
Randomize Timer
fifoHead=0
fifoTail=0
fifoCount=0
ux_cell_bits=8
ux_cell_bytes=1
ux_tape_cells=32768
ux_stack_cells=8192
ux_data_cells=24576
ux_stack_offset=32768
ux_data_offset=40960
ux_flags=FLAG_BND
ux_status=0
ux_ptr=0
ux_sp=0
uxm_entry()
Print
Print "[UXM program derlendi.]"
If ux_status<>0 Then
Print "Final status: ";ux_status;" ";
PrintStatusMessage ux_status
End If

