' Auto-split by V3 modularization
Function StackRead(ByVal idx As ULongInt) As ULongInt
If idx>=ux_stack_cells Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
Return ReadCell(StackBase(),idx)
End Function

Sub StackWrite(ByVal idx As ULongInt, ByVal value As ULongInt)
If idx>=ux_stack_cells Then
SetStatus STATUS_STACK_OVERFLOW
Exit Sub
End If
WriteCell StackBase(),idx,value
End Sub

Sub StackPush(ByVal value As ULongInt)
If ux_sp>=ux_stack_cells Then
SetStatus STATUS_STACK_OVERFLOW
Exit Sub
End If
StackWrite ux_sp,value
ux_sp=ux_sp+1
SetStatus STATUS_OK
End Sub

Function StackPop() As ULongInt
If ux_sp=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
ux_sp=ux_sp-1
SetStatus STATUS_OK
Return StackRead(ux_sp)
End Function

Function FifoLimit() As ULongInt
Dim lim As ULongInt
Dim physCells As ULongInt
lim=ux_queue_cells
If lim<1 Then lim=1
physCells=FIFO_STORAGE_BYTES\CellBytes()
If physCells<1 Then physCells=1
If lim>physCells Then lim=physCells
Return lim
End Function

Function FifoBase() As UByte Ptr
Return @fifoMem(0)
End Function

Function FifoReadCell(ByVal idx As ULongInt) As ULongInt
Return ReadCell(FifoBase(), idx)
End Function

Sub FifoWriteCell(ByVal idx As ULongInt, ByVal value As ULongInt)
WriteCell FifoBase(), idx, value
End Sub

Sub FifoPush(ByVal value As ULongInt)
Dim lim As ULongInt
lim=FifoLimit()
If fifoCount>=lim Then
SetStatus STATUS_STACK_OVERFLOW
Exit Sub
End If
FifoWriteCell fifoTail,value
fifoTail=(fifoTail+1) Mod lim
fifoCount=fifoCount+1
ux_flags=ux_flags Or FLAG_FIFO
SetStatus STATUS_OK
End Sub

Function FifoPop() As ULongInt
Dim v As ULongInt
If fifoCount=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
v=FifoReadCell(fifoHead)
fifoHead=(fifoHead+1) Mod FifoLimit()
fifoCount=fifoCount-1
SetStatus STATUS_OK
Return v
End Function

Function FifoPeek() As ULongInt
If fifoCount=0 Then
SetStatus STATUS_STACK_UNDERFLOW
Return 0
End If
SetStatus STATUS_OK
Return FifoReadCell(fifoHead)
End Function

Sub FifoClear()
fifoHead=0
fifoTail=0
fifoCount=0
SetStatus STATUS_OK
End Sub

Sub PrintStatusMessage(ByVal code As ULongInt)
Select Case code
Case 0
Print "OK"
Case 5
Print "Invalid meta id"
Case 10
Print "Pointer out of bounds"
Case 11
Print "Stack overflow"
Case 12
Print "Stack underflow"
Case 13
Print "Arithmetic overflow"
Case 14
Print "Arithmetic underflow"
Case 15
Print "Division by zero"
Case 16
Print "Data bounds error"
Case 23
Print "Operation denied outside wild mode"
Case 24
Print "Protected meta id"
Case 26
Print "EOF"
Case Else
Print "Unknown status"
End Select
End Sub

Function ScaleFactor() As LongInt
Select Case ux_cell_bits
Case 8
Return 100
Case 16
Return 1000
Case 32
Return 10000
Case Else
Return 100
End Select
End Function

Function SinScaled(ByVal degree As Double) As LongInt
Return CLngInt(Sin(degree*PI_D/180.0)*ScaleFactor())
End Function

Function CosScaled(ByVal degree As Double) As LongInt
Return CLngInt(Cos(degree*PI_D/180.0)*ScaleFactor())
End Function

Function TanScaled(ByVal degree As Double) As LongInt
Return CLngInt(Tan(degree*PI_D/180.0)*ScaleFactor())
End Function

Function SinhLocal(ByVal x As Double) As Double
Return (Exp(x)-Exp(-x))/2.0
End Function

Function CoshLocal(ByVal x As Double) As Double
Return (Exp(x)+Exp(-x))/2.0
End Function

Function TanhLocal(ByVal x As Double) As Double
Dim c As Double
c=CoshLocal(x)
If c=0.0 Then Return 0.0
Return SinhLocal(x)/c
End Function

Function AsinLocal(ByVal x As Double) As Double
If x>=1.0 Then Return PI_D/2.0
If x<=-1.0 Then Return -PI_D/2.0
Return Atn(x/Sqr(1.0-x*x))
End Function

Function AcosLocal(ByVal x As Double) As Double
Return PI_D/2.0-AsinLocal(x)
End Function

Function AsinhLocal(ByVal x As Double) As Double
Return Log(x+Sqr(x*x+1.0))
End Function

Function AcoshLocal(ByVal x As Double) As Double
If x<1.0 Then Return 0.0
Return Log(x+Sqr(x*x-1.0))
End Function

Function AtanhLocal(ByVal x As Double) As Double
If x>=1.0 Or x<=-1.0 Then Return 0.0
Return 0.5*Log((1.0+x)/(1.0-x))
End Function

Function RandomByte() As ULongInt
Return CULngInt(Int(Rnd*256)) And &HFF
End Function

Sub PrintDecimalValue(ByVal value As ULongInt)
If IsSignedMode() Then
Print LTrim(Str(ToSignedValue(value)));
Else
Print LTrim(Str(value And CellMask()));
End If
End Sub

Function ReadDecimalValue() As ULongInt
Dim s As String
Line Input s
If IsSignedMode() Then
Return FromSignedValue(CLngInt(Val(s)))
Else
Return CULngInt(Val(s)) And CellMask()
End If
End Function

Sub ux_putc(ByVal ch As ULongInt) Export
Print Chr(ch And &HFF);
End Sub

Function ux_getc() As ULongInt Export
Dim s As String
s=Inkey
Do While Len(s)=0
Sleep 10
s=Inkey
Loop
ux_status=0
Return CULngInt(Asc(Left(s,1))) And &HFF
End Function

Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt) Export
Dim oldBits As ULong
Dim i As ULongInt
Dim v As ULongInt
oldBits=ux_cell_bits
If cellBits=8 Or cellBits=16 Or cellBits=32 Then ux_cell_bits=cellBits
i=startCell
Do
If i>=ux_data_cells Then
SetStatus STATUS_DATA_BOUNDS
Exit Do
End If
v=ReadCell(DataBase(),i)
If v=0 Then Exit Do
Print Chr(v And &HFF);
i=i+1
Loop
ux_cell_bits=oldBits
End Sub

Sub ux_runtime_error(ByVal code As ULongInt) Export
ux_status=code And &HFF
ux_flags=ux_flags Or FLAG_ERR
Print
Print "[UXM runtime error ";Str(code);"] ";
PrintStatusMessage code
End Sub

