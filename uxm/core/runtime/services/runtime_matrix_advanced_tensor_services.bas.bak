' UXM V3.3 Stage-10 Matrix Advanced + Tensor Basic Services
' Meta range: @512..@599
'
' Matrix advanced uses the existing UX-MAT descriptor from runtime_matrix_services.bas.
' Frame convention follows MetaMatrix:
'   T-4 = dst/out descriptor base
'   T-3 = A/base descriptor
'   T-2 = B/aux descriptor
'   T-1 = p1 / row / option
'   T   = p2 / col / value
'   T+1 = scalar result/status
'
' Tensor basic descriptor layout in data[]:
'   base+0  magic = 8401
'   base+1  ndims = 2 in Stage-10
'   base+2  dim0
'   base+3  dim1
'   base+4  total elements
'   base+5  data offset = 16
'   base+6  status
'   base+16 values row-major

Const TENSOR_MAGIC As LongInt = 8401
Const TENSOR_DATA_OFFSET As LongInt = 16

Declare Function MatAdvRoundLong(ByVal x As Double) As LongInt
Declare Function MatAdvDetN(ByVal baseAddr As LongInt) As LongInt
Declare Function MatAdvRank(ByVal baseAddr As LongInt) As LongInt
Declare Function MatAdvNormInf(ByVal baseAddr As LongInt) As LongInt
Declare Function MatAdvFrobenius2(ByVal baseAddr As LongInt) As LongInt
Declare Sub MatAdvInverse2(ByVal dst As LongInt, ByVal a As LongInt)
Declare Sub MatAdvLU2(ByVal lBase As LongInt, ByVal uBase As LongInt, ByVal aBase As LongInt)
Declare Function TensorIsValid(ByVal baseAddr As LongInt) As Long
Declare Function TensorIndex2(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByRef ok As Long) As LongInt
Declare Sub TensorInit2D(ByVal baseAddr As LongInt, ByVal dim0 As LongInt, ByVal dim1 As LongInt)
Declare Sub TensorSet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
Declare Function TensorGet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
Declare Sub TensorFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
Declare Function TensorSum(ByVal baseAddr As LongInt) As LongInt
Declare Sub TensorShape(ByVal baseAddr As LongInt)

Const TENSOR_ND_MAGIC As LongInt = 8402

Declare Function TensorNDIsValid(ByVal baseAddr As LongInt) As Long
Declare Function TensorNDDataOffset(ByVal baseAddr As LongInt) As LongInt
Declare Function TensorNDTotal(ByVal baseAddr As LongInt) As LongInt
Declare Function TensorNDDim(ByVal baseAddr As LongInt, ByVal axis As LongInt) As LongInt
Declare Function TensorNDFlatFromData(ByVal baseAddr As LongInt, ByVal idxBase As LongInt, ByRef ok As Long) As LongInt
Declare Function TensorNDFlat3(ByVal baseAddr As LongInt, ByVal i0 As LongInt, ByVal i1 As LongInt, ByVal i2 As LongInt, ByRef ok As Long) As LongInt
Declare Sub TensorInit3D(ByVal baseAddr As LongInt, ByVal d0 As LongInt, ByVal d1 As LongInt, ByVal d2 As LongInt)
Declare Sub TensorInit4D(ByVal baseAddr As LongInt, ByVal dimsBase As LongInt)
Declare Sub TensorSet3D(ByVal baseAddr As LongInt, ByVal i0 As LongInt, ByVal i1 As LongInt, ByVal i2 As LongInt, ByVal value As LongInt)
Declare Function TensorGet3D(ByVal baseAddr As LongInt, ByVal i0 As LongInt, ByVal i1 As LongInt, ByVal i2 As LongInt) As LongInt
Declare Sub TensorSet4D(ByVal baseAddr As LongInt, ByVal idxBase As LongInt, ByVal value As LongInt)
Declare Function TensorGet4D(ByVal baseAddr As LongInt, ByVal idxBase As LongInt) As LongInt
Declare Sub TensorNDCopy(ByVal dst As LongInt, ByVal src As LongInt)
Declare Sub TensorSlice3DAxis0(ByVal dst2d As LongInt, ByVal src3d As LongInt, ByVal idx0 As LongInt)
Declare Sub TensorNDAddScalar(ByVal dst As LongInt, ByVal src As LongInt, ByVal scalar As LongInt)
Declare Sub TensorNDAddSame(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
Declare Function TensorNDSum(ByVal baseAddr As LongInt) As LongInt
Declare Sub TensorNDShape(ByVal baseAddr As LongInt)
Declare Function TensorNDCalcTotalFromDims(ByVal dimsBase As LongInt, ByVal nd As LongInt, ByRef ok As Long) As LongInt
Declare Sub TensorNDInitFromDims(ByVal baseAddr As LongInt, ByVal dimsBase As LongInt, ByVal nd As LongInt, ByVal clearData As Long)
Declare Sub TensorNDReshape(ByVal dst As LongInt, ByVal src As LongInt, ByVal dimsBase As LongInt, ByVal nd As LongInt, ByVal inferFlag As Long)
Declare Sub TensorNDFlattenTo2D(ByVal dst As LongInt, ByVal src As LongInt, ByVal rows As LongInt)
Declare Sub TensorNDFlatten1D(ByVal dst As LongInt, ByVal src As LongInt)
Declare Sub TensorSlice3DAxis1(ByVal dst2d As LongInt, ByVal src3d As LongInt, ByVal idx1 As LongInt)
Declare Sub TensorSlice3DAxis2(ByVal dst2d As LongInt, ByVal src3d As LongInt, ByVal idx2 As LongInt)
Declare Sub TensorNDBroadcastShape(ByVal outBase As LongInt, ByVal a As LongInt, ByVal b As LongInt)
Declare Sub TensorNDBroadcastAdd(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)

Function MatAdvRoundLong(ByVal x As Double) As LongInt
    If x>=0 Then
        Return CLngInt(x+0.5)
    Else
        Return CLngInt(x-0.5)
    End If
End Function

Function MatAdvDetN(ByVal baseAddr As LongInt) As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim piv As LongInt
    Dim best As Double
    Dim tmp As Double
    Dim factor As Double
    Dim det As Double
    Dim sign As Double
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=MatRows(baseAddr)
    If n<>MatCols(baseAddr) Or n<1 Or n>8 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    Dim a(0 To 7,0 To 7) As Double
    For i=0 To n-1
        For j=0 To n-1
            a(i,j)=CDbl(MatGet(baseAddr,i,j))
        Next j
    Next i
    det=1.0
    sign=1.0
    For k=0 To n-1
        piv=k
        best=Abs(a(k,k))
        For i=k+1 To n-1
            If Abs(a(i,k))>best Then
                best=Abs(a(i,k))
                piv=i
            End If
        Next i
        If best<0.000000001 Then
            SetStatus STATUS_OK
            Return 0
        End If
        If piv<>k Then
            For j=0 To n-1
                tmp=a(k,j)
                a(k,j)=a(piv,j)
                a(piv,j)=tmp
            Next j
            sign=-sign
        End If
        det=det*a(k,k)
        For i=k+1 To n-1
            factor=a(i,k)/a(k,k)
            For j=k+1 To n-1
                a(i,j)=a(i,j)-factor*a(k,j)
            Next j
        Next i
    Next k
    SetStatus STATUS_OK
    Return MatAdvRoundLong(det*sign)
End Function

Function MatAdvRank(ByVal baseAddr As LongInt) As LongInt
    Dim m As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim rowIdx As LongInt
    Dim colIdx As LongInt
    Dim piv As LongInt
    Dim best As Double
    Dim pv As Double
    Dim f As Double
    Dim tmp As Double
    Dim rank As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    m=MatRows(baseAddr)
    n=MatCols(baseAddr)
    If m<1 Or n<1 Or m>8 Or n>8 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    Dim a(0 To 7,0 To 7) As Double
    For i=0 To m-1
        For j=0 To n-1
            a(i,j)=CDbl(MatGet(baseAddr,i,j))
        Next j
    Next i
    rowIdx=0
    rank=0
    For colIdx=0 To n-1
        piv=rowIdx
        best=0.0
        For i=rowIdx To m-1
            If Abs(a(i,colIdx))>best Then
                best=Abs(a(i,colIdx))
                piv=i
            End If
        Next i
        If best>0.000000001 Then
            For j=colIdx To n-1
                tmp=a(rowIdx,j)
                a(rowIdx,j)=a(piv,j)
                a(piv,j)=tmp
            Next j
            pv=a(rowIdx,colIdx)
            For j=colIdx To n-1
                a(rowIdx,j)=a(rowIdx,j)/pv
            Next j
            For i=0 To m-1
                If i<>rowIdx Then
                    f=a(i,colIdx)
                    For j=colIdx To n-1
                        a(i,j)=a(i,j)-f*a(rowIdx,j)
                    Next j
                End If
            Next i
            rowIdx=rowIdx+1
            rank=rank+1
            If rowIdx=m Then Exit For
        End If
    Next colIdx
    SetStatus STATUS_OK
    Return rank
End Function

Function MatAdvNormInf(ByVal baseAddr As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim s As LongInt
    Dim best As LongInt
    Dim v As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    best=0
    For r=0 To MatRows(baseAddr)-1
        s=0
        For c=0 To MatCols(baseAddr)-1
            v=MatGet(baseAddr,r,c)
            If v<0 Then v=-v
            s=s+v
        Next c
        If s>best Then best=s
    Next r
    SetStatus STATUS_OK
    Return best
End Function

Function MatAdvFrobenius2(ByVal baseAddr As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    Dim s As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To MatRows(baseAddr)-1
        For c=0 To MatCols(baseAddr)-1
            v=MatGet(baseAddr,r,c)
            s=s+v*v
        Next c
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Sub MatAdvInverse2(ByVal dst As LongInt, ByVal a As LongInt)
    Dim a00 As LongInt
    Dim a01 As LongInt
    Dim a10 As LongInt
    Dim a11 As LongInt
    Dim det As LongInt
    If MatIsValid(a)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatRows(a)<>2 Or MatCols(a)<>2 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    a00=MatGet(a,0,0)
    a01=MatGet(a,0,1)
    a10=MatGet(a,1,0)
    a11=MatGet(a,1,1)
    det=a00*a11-a01*a10
    If det=0 Then
        SetStatus STATUS_DIV_ZERO
        Exit Sub
    End If
    MatInit dst,2,2,MatType(a),MatScale(a)
    If ux_status<>STATUS_OK Then Exit Sub
    ' Exact integer inverse for unimodular/simple matrices. Fractional inverse is reserved for fixed-point matrix type.
    MatSet dst,0,0,a11\det
    MatSet dst,0,1,(-a01)\det
    MatSet dst,1,0,(-a10)\det
    MatSet dst,1,1,a00\det
    SetStatus STATUS_OK
End Sub

Sub MatAdvLU2(ByVal lBase As LongInt, ByVal uBase As LongInt, ByVal aBase As LongInt)
    Dim a00 As LongInt
    Dim a01 As LongInt
    Dim a10 As LongInt
    Dim a11 As LongInt
    Dim l10 As LongInt
    Dim u11 As LongInt
    If MatIsValid(aBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatRows(aBase)<>2 Or MatCols(aBase)<>2 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    a00=MatGet(aBase,0,0)
    a01=MatGet(aBase,0,1)
    a10=MatGet(aBase,1,0)
    a11=MatGet(aBase,1,1)
    If a00=0 Then
        SetStatus STATUS_DIV_ZERO
        Exit Sub
    End If
    l10=a10\a00
    u11=a11-l10*a01
    MatInit lBase,2,2,MatType(aBase),MatScale(aBase)
    MatInit uBase,2,2,MatType(aBase),MatScale(aBase)
    If ux_status<>STATUS_OK Then Exit Sub
    MatSet lBase,0,0,1
    MatSet lBase,0,1,0
    MatSet lBase,1,0,l10
    MatSet lBase,1,1,1
    MatSet uBase,0,0,a00
    MatSet uBase,0,1,a01
    MatSet uBase,1,0,0
    MatSet uBase,1,1,u11
    SetStatus STATUS_OK
End Sub

Function TensorIsValid(ByVal baseAddr As LongInt) As Long
    If baseAddr<0 Or baseAddr+TENSOR_DATA_OFFSET>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr)<>TENSOR_MAGIC Then Return 0
    If ReadData(baseAddr+1)<>2 Then Return 0
    If ReadData(baseAddr+2)<=0 Or ReadData(baseAddr+3)<=0 Then Return 0
    Return -1
End Function

Function TensorIndex2(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByRef ok As Long) As LongInt
    Dim dim0 As LongInt
    Dim dim1 As LongInt
    Dim idx As LongInt
    ok=0
    If TensorIsValid(baseAddr)=0 Then Return 0
    dim0=CLngInt(ReadData(baseAddr+2))
    dim1=CLngInt(ReadData(baseAddr+3))
    If r<0 Or c<0 Or r>=dim0 Or c>=dim1 Then Return 0
    idx=baseAddr+TENSOR_DATA_OFFSET+r*dim1+c
    If idx<0 Or idx>=CLngInt(ux_data_cells) Then Return 0
    ok=-1
    Return idx
End Function

Sub TensorInit2D(ByVal baseAddr As LongInt, ByVal dim0 As LongInt, ByVal dim1 As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    If baseAddr<0 Or dim0<=0 Or dim1<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=dim0*dim1
    If baseAddr+TENSOR_DATA_OFFSET+total>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr+0,TENSOR_MAGIC
    WriteData baseAddr+1,2
    WriteData baseAddr+2,dim0
    WriteData baseAddr+3,dim1
    WriteData baseAddr+4,total
    WriteData baseAddr+5,TENSOR_DATA_OFFSET
    WriteData baseAddr+6,0
    For i=0 To total-1
        WriteData baseAddr+TENSOR_DATA_OFFSET+i,0
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorSet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
    Dim idx As LongInt
    Dim ok As Long
    idx=TensorIndex2(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData idx,ClampToCell(value)
    SetStatus STATUS_OK
End Sub

Function TensorGet2D(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
    Dim idx As LongInt
    Dim ok As Long
    idx=TensorIndex2(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    Return CLngInt(ReadData(idx))
End Function

Sub TensorFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    If TensorIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=CLngInt(ReadData(baseAddr+4))
    For i=0 To total-1
        WriteData baseAddr+TENSOR_DATA_OFFSET+i,ClampToCell(value)
    Next i
    SetStatus STATUS_OK
End Sub

Function TensorSum(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim total As LongInt
    Dim s As LongInt
    If TensorIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    total=CLngInt(ReadData(baseAddr+4))
    s=0
    For i=0 To total-1
        s=s+CLngInt(ReadData(baseAddr+TENSOR_DATA_OFFSET+i))
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Sub TensorShape(ByVal baseAddr As LongInt)
    If TensorIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteTape CLngInt(ux_ptr)+1,ReadData(baseAddr+2)
    WriteTape CLngInt(ux_ptr)+2,ReadData(baseAddr+3)
    WriteTape CLngInt(ux_ptr)+3,ReadData(baseAddr+4)
    SetStatus STATUS_OK
End Sub


Function TensorNDIsValid(ByVal baseAddr As LongInt) As Long
    Dim nd As LongInt
    Dim total As LongInt
    Dim off As LongInt
    If baseAddr<0 Or baseAddr+16>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr)<>TENSOR_ND_MAGIC Then Return 0
    nd=CLngInt(ReadData(baseAddr+1))
    If nd<3 Or nd>4 Then Return 0
    If ReadData(baseAddr+2)<=0 Or ReadData(baseAddr+3)<=0 Then Return 0
    If ReadData(baseAddr+4)<=0 Then Return 0
    If nd=4 And ReadData(baseAddr+5)<=0 Then Return 0
    total=CLngInt(ReadData(baseAddr+6))
    off=CLngInt(ReadData(baseAddr+7))
    If off<=0 Then off=TENSOR_DATA_OFFSET
    If total<=0 Then Return 0
    If baseAddr+off+total>CLngInt(ux_data_cells) Then Return 0
    Return -1
End Function

Function TensorNDDataOffset(ByVal baseAddr As LongInt) As LongInt
    Dim off As LongInt
    off=CLngInt(ReadData(baseAddr+7))
    If off<=0 Then off=TENSOR_DATA_OFFSET
    Return off
End Function

Function TensorNDTotal(ByVal baseAddr As LongInt) As LongInt
    If TensorNDIsValid(baseAddr)=0 Then Return 0
    Return CLngInt(ReadData(baseAddr+6))
End Function

Function TensorNDDim(ByVal baseAddr As LongInt, ByVal axis As LongInt) As LongInt
    If TensorNDIsValid(baseAddr)=0 Then Return 0
    If axis<0 Or axis>=CLngInt(ReadData(baseAddr+1)) Then Return 0
    Return CLngInt(ReadData(baseAddr+2+axis))
End Function

Function TensorNDFlatFromData(ByVal baseAddr As LongInt, ByVal idxBase As LongInt, ByRef ok As Long) As LongInt
    Dim nd As LongInt
    Dim axis As LongInt
    Dim idxVal As LongInt
    Dim dimVal As LongInt
    Dim flat As LongInt
    ok=0
    If TensorNDIsValid(baseAddr)=0 Then Return 0
    nd=CLngInt(ReadData(baseAddr+1))
    If idxBase<0 Or idxBase+nd>CLngInt(ux_data_cells) Then Return 0
    flat=0
    For axis=0 To nd-1
        idxVal=CLngInt(ReadData(idxBase+axis))
        dimVal=CLngInt(ReadData(baseAddr+2+axis))
        If idxVal<0 Or idxVal>=dimVal Then Return 0
        flat=flat*dimVal+idxVal
    Next axis
    ok=-1
    Return flat
End Function

Function TensorNDFlat3(ByVal baseAddr As LongInt, ByVal i0 As LongInt, ByVal i1 As LongInt, ByVal i2 As LongInt, ByRef ok As Long) As LongInt
    Dim d0 As LongInt
    Dim d1 As LongInt
    Dim d2 As LongInt
    ok=0
    If TensorNDIsValid(baseAddr)=0 Then Return 0
    If ReadData(baseAddr+1)<>3 Then Return 0
    d0=CLngInt(ReadData(baseAddr+2))
    d1=CLngInt(ReadData(baseAddr+3))
    d2=CLngInt(ReadData(baseAddr+4))
    If i0<0 Or i1<0 Or i2<0 Then Return 0
    If i0>=d0 Or i1>=d1 Or i2>=d2 Then Return 0
    ok=-1
    Return (i0*d1*d2)+(i1*d2)+i2
End Function

Sub TensorInit3D(ByVal baseAddr As LongInt, ByVal d0 As LongInt, ByVal d1 As LongInt, ByVal d2 As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    If baseAddr<0 Or d0<=0 Or d1<=0 Or d2<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=d0*d1*d2
    If baseAddr+TENSOR_DATA_OFFSET+total>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr+0,TENSOR_ND_MAGIC
    WriteData baseAddr+1,3
    WriteData baseAddr+2,d0
    WriteData baseAddr+3,d1
    WriteData baseAddr+4,d2
    WriteData baseAddr+5,1
    WriteData baseAddr+6,total
    WriteData baseAddr+7,TENSOR_DATA_OFFSET
    WriteData baseAddr+8,0
    For i=0 To total-1
        WriteData baseAddr+TENSOR_DATA_OFFSET+i,0
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorInit4D(ByVal baseAddr As LongInt, ByVal dimsBase As LongInt)
    Dim d0 As LongInt
    Dim d1 As LongInt
    Dim d2 As LongInt
    Dim d3 As LongInt
    Dim i As LongInt
    Dim total As LongInt
    If dimsBase<0 Or dimsBase+4>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    d0=CLngInt(ReadData(dimsBase+0))
    d1=CLngInt(ReadData(dimsBase+1))
    d2=CLngInt(ReadData(dimsBase+2))
    d3=CLngInt(ReadData(dimsBase+3))
    If baseAddr<0 Or d0<=0 Or d1<=0 Or d2<=0 Or d3<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=d0*d1*d2*d3
    If baseAddr+TENSOR_DATA_OFFSET+total>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr+0,TENSOR_ND_MAGIC
    WriteData baseAddr+1,4
    WriteData baseAddr+2,d0
    WriteData baseAddr+3,d1
    WriteData baseAddr+4,d2
    WriteData baseAddr+5,d3
    WriteData baseAddr+6,total
    WriteData baseAddr+7,TENSOR_DATA_OFFSET
    WriteData baseAddr+8,0
    For i=0 To total-1
        WriteData baseAddr+TENSOR_DATA_OFFSET+i,0
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorSet3D(ByVal baseAddr As LongInt, ByVal i0 As LongInt, ByVal i1 As LongInt, ByVal i2 As LongInt, ByVal value As LongInt)
    Dim ok As Long
    Dim flat As LongInt
    Dim off As LongInt
    flat=TensorNDFlat3(baseAddr,i0,i1,i2,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    off=TensorNDDataOffset(baseAddr)
    WriteData baseAddr+off+flat,ClampToCell(value)
    SetStatus STATUS_OK
End Sub

Function TensorGet3D(ByVal baseAddr As LongInt, ByVal i0 As LongInt, ByVal i1 As LongInt, ByVal i2 As LongInt) As LongInt
    Dim ok As Long
    Dim flat As LongInt
    Dim off As LongInt
    flat=TensorNDFlat3(baseAddr,i0,i1,i2,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    off=TensorNDDataOffset(baseAddr)
    SetStatus STATUS_OK
    Return CLngInt(ReadData(baseAddr+off+flat))
End Function

Sub TensorSet4D(ByVal baseAddr As LongInt, ByVal idxBase As LongInt, ByVal value As LongInt)
    Dim ok As Long
    Dim flat As LongInt
    Dim off As LongInt
    flat=TensorNDFlatFromData(baseAddr,idxBase,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    off=TensorNDDataOffset(baseAddr)
    WriteData baseAddr+off+flat,ClampToCell(value)
    SetStatus STATUS_OK
End Sub

Function TensorGet4D(ByVal baseAddr As LongInt, ByVal idxBase As LongInt) As LongInt
    Dim ok As Long
    Dim flat As LongInt
    Dim off As LongInt
    flat=TensorNDFlatFromData(baseAddr,idxBase,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    off=TensorNDDataOffset(baseAddr)
    SetStatus STATUS_OK
    Return CLngInt(ReadData(baseAddr+off+flat))
End Function

Sub TensorNDCopy(ByVal dst As LongInt, ByVal src As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    Dim offSrc As LongInt
    Dim offDst As LongInt
    If TensorNDIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=TensorNDTotal(src)
    If dst<0 Or dst+TENSOR_DATA_OFFSET+total>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=0 To TENSOR_DATA_OFFSET-1
        WriteData dst+i,ReadData(src+i)
    Next i
    offSrc=TensorNDDataOffset(src)
    offDst=TensorNDDataOffset(dst)
    For i=0 To total-1
        WriteData dst+offDst+i,ReadData(src+offSrc+i)
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorSlice3DAxis0(ByVal dst2d As LongInt, ByVal src3d As LongInt, ByVal idx0 As LongInt)
    Dim d0 As LongInt
    Dim d1 As LongInt
    Dim d2 As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim valCell As LongInt
    If TensorNDIsValid(src3d)=0 Or ReadData(src3d+1)<>3 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    d0=CLngInt(ReadData(src3d+2))
    d1=CLngInt(ReadData(src3d+3))
    d2=CLngInt(ReadData(src3d+4))
    If idx0<0 Or idx0>=d0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    TensorInit2D dst2d,d1,d2
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To d1-1
        For c=0 To d2-1
            valCell=TensorGet3D(src3d,idx0,r,c)
            TensorSet2D dst2d,r,c,valCell
        Next c
    Next r
    SetStatus STATUS_OK
End Sub

Sub TensorNDAddScalar(ByVal dst As LongInt, ByVal src As LongInt, ByVal scalar As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    Dim offSrc As LongInt
    Dim offDst As LongInt
    Dim v As LongInt
    TensorNDCopy dst,src
    If ux_status<>STATUS_OK Then Exit Sub
    total=TensorNDTotal(dst)
    offSrc=TensorNDDataOffset(src)
    offDst=TensorNDDataOffset(dst)
    For i=0 To total-1
        v=CLngInt(ReadData(src+offSrc+i))+scalar
        WriteData dst+offDst+i,ClampToCell(v)
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorNDAddSame(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim i As LongInt
    Dim nd As LongInt
    Dim total As LongInt
    Dim offA As LongInt
    Dim offB As LongInt
    Dim offDst As LongInt
    Dim v As LongInt
    If TensorNDIsValid(a)=0 Or TensorNDIsValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    nd=CLngInt(ReadData(a+1))
    If nd<>CLngInt(ReadData(b+1)) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=0 To nd-1
        If ReadData(a+2+i)<>ReadData(b+2+i) Then
            SetStatus STATUS_DATA_BOUNDS
            Exit Sub
        End If
    Next i
    TensorNDCopy dst,a
    If ux_status<>STATUS_OK Then Exit Sub
    total=TensorNDTotal(a)
    offA=TensorNDDataOffset(a)
    offB=TensorNDDataOffset(b)
    offDst=TensorNDDataOffset(dst)
    For i=0 To total-1
        v=CLngInt(ReadData(a+offA+i))+CLngInt(ReadData(b+offB+i))
        WriteData dst+offDst+i,ClampToCell(v)
    Next i
    SetStatus STATUS_OK
End Sub

Function TensorNDSum(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim total As LongInt
    Dim off As LongInt
    Dim s As LongInt
    If TensorNDIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    total=TensorNDTotal(baseAddr)
    off=TensorNDDataOffset(baseAddr)
    s=0
    For i=0 To total-1
        s=s+CLngInt(ReadData(baseAddr+off+i))
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Sub TensorNDShape(ByVal baseAddr As LongInt)
    Dim nd As LongInt
    If TensorNDIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    nd=CLngInt(ReadData(baseAddr+1))
    WriteTape CLngInt(ux_ptr)+1,nd
    WriteTape CLngInt(ux_ptr)+2,ReadData(baseAddr+2)
    WriteTape CLngInt(ux_ptr)+3,ReadData(baseAddr+3)
    WriteTape CLngInt(ux_ptr)+4,ReadData(baseAddr+4)
    If nd=4 Then WriteTape CLngInt(ux_ptr)+5,ReadData(baseAddr+5)
    SetStatus STATUS_OK
End Sub


Function TensorNDCalcTotalFromDims(ByVal dimsBase As LongInt, ByVal nd As LongInt, ByRef ok As Long) As LongInt
    Dim axis As LongInt
    Dim d As LongInt
    Dim total As LongInt
    ok=0
    If nd<3 Or nd>4 Then Return 0
    If dimsBase<0 Or dimsBase+nd>CLngInt(ux_data_cells) Then Return 0
    total=1
    For axis=0 To nd-1
        d=CLngInt(ReadData(dimsBase+axis))
        If d<=0 Then Return 0
        total=total*d
    Next axis
    ok=-1
    Return total
End Function

Sub TensorNDInitFromDims(ByVal baseAddr As LongInt, ByVal dimsBase As LongInt, ByVal nd As LongInt, ByVal clearData As Long)
    Dim axis As LongInt
    Dim total As LongInt
    Dim ok As Long
    Dim i As LongInt
    total=TensorNDCalcTotalFromDims(dimsBase,nd,ok)
    If ok=0 Or baseAddr<0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If baseAddr+TENSOR_DATA_OFFSET+total>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr+0,TENSOR_ND_MAGIC
    WriteData baseAddr+1,nd
    For axis=0 To 3
        If axis<nd Then
            WriteData baseAddr+2+axis,ReadData(dimsBase+axis)
        Else
            WriteData baseAddr+2+axis,1
        End If
    Next axis
    WriteData baseAddr+6,total
    WriteData baseAddr+7,TENSOR_DATA_OFFSET
    WriteData baseAddr+8,0
    If clearData<>0 Then
        For i=0 To total-1
            WriteData baseAddr+TENSOR_DATA_OFFSET+i,0
        Next i
    End If
    SetStatus STATUS_OK
End Sub

Sub TensorNDReshape(ByVal dst As LongInt, ByVal src As LongInt, ByVal dimsBase As LongInt, ByVal nd As LongInt, ByVal inferMode As Long)
    Dim srcTotal As LongInt
    Dim known As LongInt
    Dim inferAxis As LongInt
    Dim axis As LongInt
    Dim d As LongInt
    Dim total As LongInt
    Dim i As LongInt
    Dim offSrc As LongInt
    Dim offDst As LongInt
    Dim ok As Long
    If TensorNDIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If nd<3 Or nd>4 Or dimsBase<0 Or dimsBase+nd>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    srcTotal=TensorNDTotal(src)
    known=1
    inferAxis=-1
    For axis=0 To nd-1
        d=CLngInt(ReadData(dimsBase+axis))
        If d=0 And inferMode<>0 Then
            If inferAxis<>-1 Then
                SetStatus STATUS_DATA_BOUNDS
                Exit Sub
            End If
            inferAxis=axis
        ElseIf d<=0 Then
            SetStatus STATUS_DATA_BOUNDS
            Exit Sub
        Else
            known=known*d
        End If
    Next axis
    If inferAxis<>-1 Then
        If known<=0 Or (srcTotal Mod known)<>0 Then
            SetStatus STATUS_DATA_BOUNDS
            Exit Sub
        End If
        WriteData dimsBase+inferAxis,srcTotal\known
    End If
    total=TensorNDCalcTotalFromDims(dimsBase,nd,ok)
    If ok=0 Or total<>srcTotal Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    TensorNDInitFromDims dst,dimsBase,nd,-1
    If ux_status<>STATUS_OK Then Exit Sub
    offSrc=TensorNDDataOffset(src)
    offDst=TensorNDDataOffset(dst)
    For i=0 To srcTotal-1
        WriteData dst+offDst+i,ReadData(src+offSrc+i)
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorNDFlattenTo2D(ByVal dst As LongInt, ByVal src As LongInt, ByVal rows As LongInt)
    Dim total As LongInt
    Dim cols As LongInt
    Dim i As LongInt
    Dim offSrc As LongInt
    If TensorNDIsValid(src)=0 Or rows<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=TensorNDTotal(src)
    If (total Mod rows)<>0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    cols=total\rows
    TensorInit2D dst,rows,cols
    If ux_status<>STATUS_OK Then Exit Sub
    offSrc=TensorNDDataOffset(src)
    For i=0 To total-1
        WriteData dst+TENSOR_DATA_OFFSET+i,ReadData(src+offSrc+i)
    Next i
    SetStatus STATUS_OK
End Sub

Sub TensorNDFlatten1D(ByVal dst As LongInt, ByVal src As LongInt)
    If TensorNDIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    TensorNDFlattenTo2D dst,src,1
End Sub

Sub TensorSlice3DAxis1(ByVal dst2d As LongInt, ByVal src3d As LongInt, ByVal idx1 As LongInt)
    Dim d0 As LongInt
    Dim d1 As LongInt
    Dim d2 As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim valCell As LongInt
    If TensorNDIsValid(src3d)=0 Or ReadData(src3d+1)<>3 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    d0=CLngInt(ReadData(src3d+2))
    d1=CLngInt(ReadData(src3d+3))
    d2=CLngInt(ReadData(src3d+4))
    If idx1<0 Or idx1>=d1 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    TensorInit2D dst2d,d0,d2
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To d0-1
        For c=0 To d2-1
            valCell=TensorGet3D(src3d,r,idx1,c)
            TensorSet2D dst2d,r,c,valCell
        Next c
    Next r
    SetStatus STATUS_OK
End Sub

Sub TensorSlice3DAxis2(ByVal dst2d As LongInt, ByVal src3d As LongInt, ByVal idx2 As LongInt)
    Dim d0 As LongInt
    Dim d1 As LongInt
    Dim d2 As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim valCell As LongInt
    If TensorNDIsValid(src3d)=0 Or ReadData(src3d+1)<>3 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    d0=CLngInt(ReadData(src3d+2))
    d1=CLngInt(ReadData(src3d+3))
    d2=CLngInt(ReadData(src3d+4))
    If idx2<0 Or idx2>=d2 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    TensorInit2D dst2d,d0,d1
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To d0-1
        For c=0 To d1-1
            valCell=TensorGet3D(src3d,r,c,idx2)
            TensorSet2D dst2d,r,c,valCell
        Next c
    Next r
    SetStatus STATUS_OK
End Sub

Sub TensorNDBroadcastShape(ByVal outBase As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim nd As LongInt
    Dim axis As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim od As LongInt
    Dim total As LongInt
    If TensorNDIsValid(a)=0 Or TensorNDIsValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    nd=CLngInt(ReadData(a+1))
    If nd<>CLngInt(ReadData(b+1)) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If outBase<0 Or outBase+nd+1>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData outBase,nd
    total=1
    For axis=0 To nd-1
        da=CLngInt(ReadData(a+2+axis))
        db=CLngInt(ReadData(b+2+axis))
        If da=db Then
            od=da
        ElseIf da=1 Then
            od=db
        ElseIf db=1 Then
            od=da
        Else
            SetStatus STATUS_DATA_BOUNDS
            Exit Sub
        End If
        WriteData outBase+1+axis,od
        total=total*od
    Next axis
    WriteData outBase+1+nd,total
    SetStatus STATUS_OK
End Sub

Sub TensorNDBroadcastAdd(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim nd As LongInt
    Dim axis As LongInt
    Dim da As LongInt
    Dim db As LongInt
    Dim outDim(0 To 3) As LongInt
    Dim idx(0 To 3) As LongInt
    Dim idxA As LongInt
    Dim idxB As LongInt
    Dim total As LongInt
    Dim flat As LongInt
    Dim remVal As LongInt
    Dim flatA As LongInt
    Dim flatB As LongInt
    Dim offA As LongInt
    Dim offB As LongInt
    Dim offDst As LongInt
    Dim v As LongInt
    If TensorNDIsValid(a)=0 Or TensorNDIsValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    nd=CLngInt(ReadData(a+1))
    If nd<>CLngInt(ReadData(b+1)) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    total=1
    For axis=0 To nd-1
        da=CLngInt(ReadData(a+2+axis))
        db=CLngInt(ReadData(b+2+axis))
        If da=db Then
            outDim(axis)=da
        ElseIf da=1 Then
            outDim(axis)=db
        ElseIf db=1 Then
            outDim(axis)=da
        Else
            SetStatus STATUS_DATA_BOUNDS
            Exit Sub
        End If
        total=total*outDim(axis)
    Next axis
    If dst<0 Or dst+TENSOR_DATA_OFFSET+total>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData dst+0,TENSOR_ND_MAGIC
    WriteData dst+1,nd
    For axis=0 To 3
        If axis<nd Then
            WriteData dst+2+axis,outDim(axis)
        Else
            WriteData dst+2+axis,1
        End If
    Next axis
    WriteData dst+6,total
    WriteData dst+7,TENSOR_DATA_OFFSET
    WriteData dst+8,0
    offA=TensorNDDataOffset(a)
    offB=TensorNDDataOffset(b)
    offDst=TensorNDDataOffset(dst)
    For flat=0 To total-1
        remVal=flat
        For axis=nd-1 To 0 Step -1
            idx(axis)=remVal Mod outDim(axis)
            remVal=remVal\outDim(axis)
        Next axis
        flatA=0
        flatB=0
        For axis=0 To nd-1
            da=CLngInt(ReadData(a+2+axis))
            db=CLngInt(ReadData(b+2+axis))
            If da=1 Then idxA=0 Else idxA=idx(axis)
            If db=1 Then idxB=0 Else idxB=idx(axis)
            flatA=flatA*da+idxA
            flatB=flatB*db+idxB
        Next axis
        v=CLngInt(ReadData(a+offA+flatA))+CLngInt(ReadData(b+offB+flatB))
        WriteData dst+offDst+flat,ClampToCell(v)
    Next flat
    SetStatus STATUS_OK
End Sub

Sub MetaMatrixAdvancedTensor(ByVal metaId As ULongInt)
    Dim dst As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim p1 As LongInt
    Dim p2 As LongInt
    Dim r As LongInt
    Dim tFlatOk As Long
    dst=CLngInt(ReadTape(CLngInt(ux_ptr)-4))
    a=CLngInt(ReadTape(CLngInt(ux_ptr)-3))
    b=CLngInt(ReadTape(CLngInt(ux_ptr)-2))
    p1=CLngInt(ReadTape(CLngInt(ux_ptr)-1))
    p2=CLngInt(ReadTape(CLngInt(ux_ptr)))

    Select Case metaId
    Case 512
        r=MatAdvDetN(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 513
        MatAdvInverse2 dst,a
        SetResult ux_status
    Case 514
        r=MatAdvRank(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 516
        r=MatAdvNormInf(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 517
        r=MatAdvFrobenius2(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 518
        MatAdvLU2 dst,b,a
        SetResult ux_status
    Case 519
        Print "[UXM MATADV] @512 detN, @513 inv2, @514 rank, @516 normInf, @517 frob2, @518 lu2; @540.. tensor2d"
        SetStatus STATUS_OK
        SetResult STATUS_OK
    Case 540
        TensorInit2D dst,a,b
        SetResult ux_status
    Case 541
        TensorSet2D dst,a,b,p1
        SetResult ux_status
    Case 542
        r=TensorGet2D(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 543
        TensorFill dst,a
        SetResult ux_status
    Case 544
        r=TensorSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 545
        TensorShape dst
        SetResult ux_status
    Case 559
        Print "[UXM TENSOR] @540..@545 2D; @560..@573 ND tensor; @599 info"
        SetStatus STATUS_OK
        SetResult STATUS_OK
    Case 560
        TensorInit3D dst,a,b,p1
        SetResult ux_status
    Case 561
        TensorSet3D dst,a,b,p1,p2
        SetResult ux_status
    Case 562
        r=TensorGet3D(dst,a,b,p1)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 563
        TensorInit4D dst,a
        SetResult ux_status
    Case 564
        TensorSet4D dst,a,b
        SetResult ux_status
    Case 565
        r=TensorGet4D(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 566
        r=TensorNDFlatFromData(dst,a,tFlatOk)
        If tFlatOk=0 Then
            SetStatus STATUS_DATA_BOUNDS
            SetResult 0
        Else
            SetResult ClampToCell(r)
            SetLogicFlags ResultValue()
            SetStatus STATUS_OK
        End If
    Case 567
        TensorNDCopy dst,a
        SetResult ux_status
    Case 568
        If b<>0 Then
            SetStatus STATUS_DATA_BOUNDS
            SetResult ux_status
        Else
            TensorSlice3DAxis0 dst,a,p1
            SetResult ux_status
        End If
    Case 570
        TensorNDAddScalar dst,a,b
        SetResult ux_status
    Case 571
        TensorNDAddSame dst,a,b
        SetResult ux_status
    Case 573
        r=TensorNDSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 574
        TensorNDShape dst
        SetResult ux_status
    Case 575
        TensorNDReshape dst,a,b,p1,0
        SetResult ux_status
    Case 576
        TensorNDFlattenTo2D dst,a,b
        SetResult ux_status
    Case 577
        TensorSlice3DAxis1 dst,a,p1
        SetResult ux_status
    Case 578
        TensorSlice3DAxis2 dst,a,p1
        SetResult ux_status
    Case 581
        TensorNDBroadcastAdd dst,a,b
        SetResult ux_status
    Case 582
        TensorNDBroadcastShape dst,a,b
        SetResult ux_status
    Case 583
        TensorNDReshape dst,a,b,p1,-1
        SetResult ux_status
    Case 584
        TensorNDFlatten1D dst,a
        SetResult ux_status
    Case 599
        Print "[UXM TENSOR ADV] @560..@574 tensor adv v1; @575 reshape, @576 flatten2d, @577/@578 slice axis1/2, @581 broadcast add, @582 broadcast shape, @583 reshape infer, @584 flatten1d"
        SetStatus STATUS_OK
        SetResult STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
