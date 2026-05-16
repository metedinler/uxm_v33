' Auto-split by V3 modularization
Function MemBase() As UByte Ptr
Return @ux_mem
End Function

Function TapeBase() As UByte Ptr
Return @ux_mem
End Function

Function StackBase() As UByte Ptr
Return @ux_mem+ux_stack_offset
End Function

Function DataBase() As UByte Ptr
Return @ux_mem+ux_data_offset
End Function

Function CellBytes() As ULong
Select Case ux_cell_bits
Case 8
Return 1
Case 16
Return 2
Case 32
Return 4
Case Else
Return 1
End Select
End Function

Function CellMask() As ULongInt
Select Case ux_cell_bits
Case 8
Return &HFFull
Case 16
Return &HFFFFull
Case 32
Return &HFFFFFFFFull
Case Else
Return &HFFull
End Select
End Function

Function CellSignBit() As ULongInt
Select Case ux_cell_bits
Case 8
Return &H80ull
Case 16
Return &H8000ull
Case 32
Return &H80000000ull
Case Else
Return &H80ull
End Select
End Function

Function CellMaxSigned() As LongInt
Select Case ux_cell_bits
Case 8
Return 127
Case 16
Return 32767
Case 32
Return 2147483647
Case Else
Return 127
End Select
End Function

Function CellMinSigned() As LongInt
Select Case ux_cell_bits
Case 8
Return -128
Case 16
Return -32768
Case 32
Return -2147483648
Case Else
Return -128
End Select
End Function

Function ReadCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt) As ULongInt
Select Case ux_cell_bits
Case 8
Return CULngInt(basePtr[cellIndex])
Case 16
Return CULngInt(*Cast(UShort Ptr,basePtr+cellIndex*2))
Case 32
Return CULngInt(*Cast(ULong Ptr,basePtr+cellIndex*4))
Case Else
Return CULngInt(basePtr[cellIndex])
End Select
End Function

Sub WriteCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt, ByVal value As ULongInt)
value=value And CellMask()
Select Case ux_cell_bits
Case 8
basePtr[cellIndex]=CUByte(value And &HFF)
Case 16
*Cast(UShort Ptr,basePtr+cellIndex*2)=CUShort(value And &HFFFF)
Case 32
*Cast(ULong Ptr,basePtr+cellIndex*4)=CULng(value And &HFFFFFFFF)
Case Else
basePtr[cellIndex]=CUByte(value And &HFF)
End Select
ux_flags=ux_flags Or FLAG_DIRTY
End Sub

Function ReadTape(ByVal cellIndex As LongInt) As ULongInt
If cellIndex<0 Or cellIndex>=CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Return 0
End If
Return ReadCell(TapeBase(),CULngInt(cellIndex))
End Function

Sub WriteTape(ByVal cellIndex As LongInt, ByVal value As ULongInt)
If cellIndex<0 Or cellIndex>=CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
WriteCell TapeBase(),CULngInt(cellIndex),value
End Sub

Function ReadData(ByVal cellIndex As LongInt) As ULongInt
If cellIndex<0 Or cellIndex>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Return 0
End If
Return ReadCell(DataBase(),CULngInt(cellIndex))
End Function

Sub WriteData(ByVal cellIndex As LongInt, ByVal value As ULongInt)
If cellIndex<0 Or cellIndex>=CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
WriteCell DataBase(),CULngInt(cellIndex),value
End Sub

Function ReadTapeRel(ByVal rel As LongInt) As ULongInt
Return ReadTape(CLngInt(ux_ptr)+rel)
End Function

Sub WriteTapeRel(ByVal rel As LongInt, ByVal value As ULongInt)
WriteTape CLngInt(ux_ptr)+rel,value
End Sub

Function ToSignedValue(ByVal value As ULongInt) As LongInt
value=value And CellMask()
If (value And CellSignBit())<>0 Then
Return CLngInt(value)-CLngInt(CellMask()+1)
Else
Return CLngInt(value)
End If
End Function

Function FromSignedValue(ByVal value As LongInt) As ULongInt
Return CULngInt(value) And CellMask()
End Function

Function ClampToCell(ByVal v As LongInt) As ULongInt
If IsSignedMode() Then
If v>CellMaxSigned() Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_OVERFLOW
v=CellMaxSigned()
ElseIf v<CellMinSigned() Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
v=CellMinSigned()
End If
Return FromSignedValue(v)
Else
If v<0 Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
v=0
ElseIf CULngInt(v)>CellMask() Then
ux_flags=ux_flags Or FLAG_O Or FLAG_C
SetStatus STATUS_OVERFLOW
v=CLngInt(CellMask())
End If
Return CULngInt(v) And CellMask()
End If
End Function

Function ClampDoubleToCell(ByVal v As Double) As ULongInt
If v>CDbl(CellMask()) Then
ux_flags=ux_flags Or FLAG_O Or FLAG_C
SetStatus STATUS_OVERFLOW
Return CellMask()
End If
If v<0 And IsSignedMode()=0 Then
ux_flags=ux_flags Or FLAG_O
SetStatus STATUS_UNDERFLOW
Return 0
End If
Return ClampToCell(CLngInt(v))
End Function

Sub DataBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If src<0 Or dst<0 Or count<0 Or src+count>CLngInt(ux_data_cells) Or dst+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteData dst+i,ReadData(src+i)
Next i
SetStatus STATUS_OK
End Sub

Sub DataBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If dst<0 Or count<0 Or dst+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteData dst+i,0
Next i
SetStatus STATUS_OK
End Sub

Sub TapeBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If src<0 Or dst<0 Or count<0 Or src+count>CLngInt(ux_tape_cells) Or dst+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteTape dst+i,ReadTape(src+i)
Next i
SetStatus STATUS_OK
End Sub

Sub TapeBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Dim i As LongInt
If dst<0 Or count<0 Or dst+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
For i=0 To count-1
WriteTape dst+i,0
Next i
SetStatus STATUS_OK
End Sub

Sub SortTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Dim i As LongInt
Dim j As LongInt
Dim a As ULongInt
Dim b As ULongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Exit Sub
End If
For i=0 To count-2
For j=0 To count-2-i
a=ReadTape(startIdx+j)
b=ReadTape(startIdx+j+1)
If (ascending<>0 And a>b) Or (ascending=0 And a<b) Then
WriteTape startIdx+j,b
WriteTape startIdx+j+1,a
End If
Next j
Next i
SetStatus STATUS_OK
End Sub

Sub SortData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Dim i As LongInt
Dim j As LongInt
Dim a As ULongInt
Dim b As ULongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
For i=0 To count-2
For j=0 To count-2-i
a=ReadData(startIdx+j)
b=ReadData(startIdx+j+1)
If (ascending<>0 And a>b) Or (ascending=0 And a<b) Then
WriteData startIdx+j,b
WriteData startIdx+j+1,a
End If
Next j
Next i
SetStatus STATUS_OK
End Sub

Function LinearSearchTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Dim i As LongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_tape_cells) Then
SetStatus STATUS_PTR_BOUNDS
Return -1
End If
For i=0 To count-1
If ReadTape(startIdx+i)=target Then
SetStatus STATUS_OK
Return i
End If
Next i
SetStatus STATUS_OK
Return -1
End Function

Function LinearSearchData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Dim i As LongInt
If startIdx<0 Or count<0 Or startIdx+count>CLngInt(ux_data_cells) Then
SetStatus STATUS_DATA_BOUNDS
Return -1
End If
For i=0 To count-1
If ReadData(startIdx+i)=target Then
SetStatus STATUS_OK
Return i
End If
Next i
SetStatus STATUS_OK
Return -1
End Function

Sub WildLayoutChange()
Dim t As ULongInt
Dim s As ULongInt
Dim d As ULongInt
Dim q As ULongInt
Dim totalKB As ULongInt
If IsWildMode()=0 Then
SetStatus STATUS_SAFE_DENY
Exit Sub
End If

' Legacy runtime layout service: Arg1=tapeKB, Arg2=stackKB, Arg0=dataKB.
' UXM V7: eski 64 KB zorunlulugu kaldirildi; toplam 16 MB sinir uygulanir.
' FIFO/queue compile-time #memory fifo=/queue= ile ayarlanir; runtime servis mevcut queue alanini korur.
t=Arg1()
s=Arg2()
d=Arg0()
q=(ux_queue_cells*CellBytes())\1024
If q<1 Then q=1

totalKB=t+s+d+q
If t=0 Or s=0 Or d=0 Or totalKB>UXM_RUNTIME_MAX_TOTAL_KB Then
SetStatus STATUS_DATA_BOUNDS
Exit Sub
End If
ux_tape_cells=(t*1024)\CellBytes()
ux_stack_cells=(s*1024)\CellBytes()
ux_data_cells=(d*1024)\CellBytes()
ux_stack_offset=t*1024
ux_data_offset=(t+s)*1024
If ux_ptr>=ux_tape_cells Then ux_ptr=0
If ux_sp>=ux_stack_cells Then ux_sp=0
If fifoHead>=FifoLimit() Or fifoTail>=FifoLimit() Or fifoCount>FifoLimit() Then FifoClear
ux_flags=ux_flags Or FLAG_PCHG
SetStatus STATUS_OK
End Sub
Extern "C"

