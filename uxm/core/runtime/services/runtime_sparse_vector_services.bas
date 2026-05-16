' UXM V3.3 Stage-13 Sparse Matrix + Vector Ops services
' Meta ranges:
'   @600..@619 Vector Ops V1
'   @640..@649 Sparse Matrix V1
'
' Vector descriptor in data[]:
'   base+0 = 8601 magic
'   base+1 = length
'   base+2 = data offset, currently 8
'   base+3 = status
'   base+8... values
'
' Sparse descriptor in data[]:
'   base+0  = 8602 magic
'   base+1  = rows
'   base+2  = cols
'   base+3  = nnz
'   base+4  = capacity
'   base+5  = triples offset, currently 16
'   base+6  = status
'   base+16 + k*3 + 0 = row
'   base+16 + k*3 + 1 = col
'   base+16 + k*3 + 2 = value

Const UX_VEC_MAGIC As LongInt = 8601
Const UX_VEC_DATA_OFFSET As LongInt = 8
Const UX_SPARSE_MAGIC As LongInt = 8602
Const UX_SPARSE_DATA_OFFSET As LongInt = 16

Declare Function UxAbsLI(ByVal x As LongInt) As LongInt
Declare Function VecIsValid(ByVal baseAddr As LongInt) As Long
Declare Function VecLen(ByVal baseAddr As LongInt) As LongInt
Declare Function VecIndex(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByRef ok As Long) As LongInt
Declare Sub VecInit(ByVal baseAddr As LongInt, ByVal n As LongInt)
Declare Sub VecSet(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
Declare Function VecGet(ByVal baseAddr As LongInt, ByVal idx As LongInt) As LongInt
Declare Sub VecFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
Declare Function VecSum(ByVal baseAddr As LongInt) As LongInt
Declare Function VecDot(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function VecNorm1(ByVal baseAddr As LongInt) As LongInt
Declare Function VecNorm2Sq(ByVal baseAddr As LongInt) As LongInt
Declare Sub VecAdd(ByVal dst As LongInt, ByVal aBase As LongInt, ByVal bBase As LongInt)
Declare Sub VecScale(ByVal dst As LongInt, ByVal src As LongInt, ByVal scalar As LongInt)
Declare Sub VecFromData(ByVal dst As LongInt, ByVal srcData As LongInt, ByVal n As LongInt)
Declare Sub VecToData(ByVal src As LongInt, ByVal dstData As LongInt)

Declare Function SparseIsValid(ByVal baseAddr As LongInt) As Long
Declare Function SparseRows(ByVal baseAddr As LongInt) As LongInt
Declare Function SparseCols(ByVal baseAddr As LongInt) As LongInt
Declare Function SparseNNZ(ByVal baseAddr As LongInt) As LongInt
Declare Function SparseCapacity(ByVal baseAddr As LongInt) As LongInt
Declare Function SparseTripleIndex(ByVal baseAddr As LongInt, ByVal k As LongInt, ByRef ok As Long) As LongInt
Declare Sub SparseInit(ByVal baseAddr As LongInt, ByVal rows As LongInt, ByVal cols As LongInt, ByVal capacity As LongInt)
Declare Sub SparseSetNNZ(ByVal baseAddr As LongInt, ByVal nnz As LongInt)
Declare Sub SparseSetEntry(ByVal baseAddr As LongInt, ByVal k As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
Declare Function SparseGetEntryValue(ByVal baseAddr As LongInt, ByVal k As LongInt) As LongInt
Declare Sub SparseMatVec(ByVal dstVec As LongInt, ByVal spBase As LongInt, ByVal xVec As LongInt)
Declare Sub SparseToDense(ByVal dstMat As LongInt, ByVal spBase As LongInt)
Declare Function SparseSumValues(ByVal baseAddr As LongInt) As LongInt
Declare Function SparseTrace(ByVal baseAddr As LongInt) As LongInt
Function UxAbsLI(ByVal x As LongInt) As LongInt
    If x<0 Then Return -x
    Return x
End Function

Function VecIsValid(ByVal baseAddr As LongInt) As Long
    If baseAddr<0 Or baseAddr+UX_VEC_DATA_OFFSET>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr)<>UX_VEC_MAGIC Then Return 0
    If CLngInt(ReadData(baseAddr+1))<0 Then Return 0
    Return -1
End Function

Function VecLen(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+1))
End Function

Function VecIndex(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByRef ok As Long) As LongInt
    Dim n As LongInt
    Dim dataOff As LongInt
    Dim p As LongInt
    If VecIsValid(baseAddr)=0 Then
        ok=0
        Return 0
    End If
    n=VecLen(baseAddr)
    dataOff=CLngInt(ReadData(baseAddr+2))
    If idx<0 Or idx>=n Then
        ok=0
        Return 0
    End If
    p=baseAddr+dataOff+idx
    If p<0 Or p>=CLngInt(ux_data_cells) Then
        ok=0
        Return 0
    End If
    ok=-1
    Return p
End Function

Sub VecInit(ByVal baseAddr As LongInt, ByVal n As LongInt)
    Dim i As LongInt
    If baseAddr<0 Or n<0 Or baseAddr+UX_VEC_DATA_OFFSET+n>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr, UX_VEC_MAGIC
    WriteData baseAddr+1, n
    WriteData baseAddr+2, UX_VEC_DATA_OFFSET
    WriteData baseAddr+3, STATUS_OK
    For i=0 To n-1
        WriteData baseAddr+UX_VEC_DATA_OFFSET+i, 0
    Next i
    SetStatus STATUS_OK
End Sub

Sub VecSet(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
    Dim ok As Long
    Dim p As LongInt
    p=VecIndex(baseAddr,idx,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData p,value
    SetStatus STATUS_OK
End Sub

Function VecGet(ByVal baseAddr As LongInt, ByVal idx As LongInt) As LongInt
    Dim ok As Long
    Dim p As LongInt
    p=VecIndex(baseAddr,idx,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    Return CLngInt(ReadData(p))
End Function

Sub VecFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If VecIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=VecLen(baseAddr)
    For i=0 To n-1
        VecSet baseAddr,i,value
    Next i
    SetStatus STATUS_OK
End Sub

Function VecSum(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim n As LongInt
    Dim s As LongInt
    If VecIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=VecLen(baseAddr)
    s=0
    For i=0 To n-1
        s=s+VecGet(baseAddr,i)
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Function VecDot(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
    Dim i As LongInt
    Dim n As LongInt
    Dim s As LongInt
    If VecIsValid(aBase)=0 Or VecIsValid(bBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=VecLen(aBase)
    If n<>VecLen(bBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For i=0 To n-1
        s=s+VecGet(aBase,i)*VecGet(bBase,i)
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Function VecNorm1(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim n As LongInt
    Dim s As LongInt
    If VecIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=VecLen(baseAddr)
    s=0
    For i=0 To n-1
        s=s+UxAbsLI(VecGet(baseAddr,i))
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Function VecNorm2Sq(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim n As LongInt
    Dim v As LongInt
    Dim s As LongInt
    If VecIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=VecLen(baseAddr)
    s=0
    For i=0 To n-1
        v=VecGet(baseAddr,i)
        s=s+v*v
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Sub VecAdd(ByVal dst As LongInt, ByVal aBase As LongInt, ByVal bBase As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If VecIsValid(aBase)=0 Or VecIsValid(bBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=VecLen(aBase)
    If n<>VecLen(bBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    VecInit dst,n
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To n-1
        VecSet dst,i,VecGet(aBase,i)+VecGet(bBase,i)
    Next i
    SetStatus STATUS_OK
End Sub

Sub VecScale(ByVal dst As LongInt, ByVal src As LongInt, ByVal scalar As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If VecIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=VecLen(src)
    VecInit dst,n
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To n-1
        VecSet dst,i,VecGet(src,i)*scalar
    Next i
    SetStatus STATUS_OK
End Sub

Sub VecFromData(ByVal dst As LongInt, ByVal srcData As LongInt, ByVal n As LongInt)
    Dim i As LongInt
    If srcData<0 Or n<0 Or srcData+n>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    VecInit dst,n
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To n-1
        VecSet dst,i,CLngInt(ReadData(srcData+i))
    Next i
    SetStatus STATUS_OK
End Sub

Sub VecToData(ByVal src As LongInt, ByVal dstData As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If VecIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=VecLen(src)
    If dstData<0 Or dstData+n>CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=0 To n-1
        WriteData dstData+i,VecGet(src,i)
    Next i
    SetStatus STATUS_OK
End Sub

Function SparseIsValid(ByVal baseAddr As LongInt) As Long
    If baseAddr<0 Or baseAddr+UX_SPARSE_DATA_OFFSET>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr)<>UX_SPARSE_MAGIC Then Return 0
    Return -1
End Function

Function SparseRows(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+1))
End Function

Function SparseCols(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+2))
End Function

Function SparseNNZ(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+3))
End Function

Function SparseCapacity(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+4))
End Function

Function SparseTripleIndex(ByVal baseAddr As LongInt, ByVal k As LongInt, ByRef ok As Long) As LongInt
    Dim p As LongInt
    If SparseIsValid(baseAddr)=0 Then
        ok=0
        Return 0
    End If
    If k<0 Or k>=SparseCapacity(baseAddr) Then
        ok=0
        Return 0
    End If
    p=baseAddr+UX_SPARSE_DATA_OFFSET+k*3
    If p<0 Or p+2>=CLngInt(ux_data_cells) Then
        ok=0
        Return 0
    End If
    ok=-1
    Return p
End Function

Sub SparseInit(ByVal baseAddr As LongInt, ByVal rows As LongInt, ByVal cols As LongInt, ByVal capacity As LongInt)
    Dim i As LongInt
    If baseAddr<0 Or rows<=0 Or cols<=0 Or capacity<0 Or baseAddr+UX_SPARSE_DATA_OFFSET+capacity*3>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr,UX_SPARSE_MAGIC
    WriteData baseAddr+1,rows
    WriteData baseAddr+2,cols
    WriteData baseAddr+3,0
    WriteData baseAddr+4,capacity
    WriteData baseAddr+5,UX_SPARSE_DATA_OFFSET
    WriteData baseAddr+6,STATUS_OK
    For i=0 To capacity*3-1
        WriteData baseAddr+UX_SPARSE_DATA_OFFSET+i,0
    Next i
    SetStatus STATUS_OK
End Sub

Sub SparseSetNNZ(ByVal baseAddr As LongInt, ByVal nnz As LongInt)
    If SparseIsValid(baseAddr)=0 Or nnz<0 Or nnz>SparseCapacity(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr+3,nnz
    SetStatus STATUS_OK
End Sub

Sub SparseSetEntry(ByVal baseAddr As LongInt, ByVal k As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
    Dim ok As Long
    Dim p As LongInt
    p=SparseTripleIndex(baseAddr,k,ok)
    If ok=0 Or r<0 Or c<0 Or r>=SparseRows(baseAddr) Or c>=SparseCols(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData p,r
    WriteData p+1,c
    WriteData p+2,value
    If k>=SparseNNZ(baseAddr) Then WriteData baseAddr+3,k+1
    SetStatus STATUS_OK
End Sub

Function SparseGetEntryValue(ByVal baseAddr As LongInt, ByVal k As LongInt) As LongInt
    Dim ok As Long
    Dim p As LongInt
    p=SparseTripleIndex(baseAddr,k,ok)
    If ok=0 Or k>=SparseNNZ(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    Return CLngInt(ReadData(p+2))
End Function

Sub SparseMatVec(ByVal dstVec As LongInt, ByVal spBase As LongInt, ByVal xVec As LongInt)
    Dim k As LongInt
    Dim p As LongInt
    Dim ok As Long
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    Dim cur As LongInt
    If SparseIsValid(spBase)=0 Or VecIsValid(xVec)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If VecLen(xVec)<>SparseCols(spBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    VecInit dstVec,SparseRows(spBase)
    If ux_status<>STATUS_OK Then Exit Sub
    For k=0 To SparseNNZ(spBase)-1
        p=SparseTripleIndex(spBase,k,ok)
        If ok<>0 Then
            r=CLngInt(ReadData(p))
            c=CLngInt(ReadData(p+1))
            v=CLngInt(ReadData(p+2))
            If r>=0 And r<SparseRows(spBase) And c>=0 And c<SparseCols(spBase) Then
                cur=VecGet(dstVec,r)
                VecSet dstVec,r,cur+v*VecGet(xVec,c)
            End If
        End If
    Next k
    SetStatus STATUS_OK
End Sub

Sub SparseToDense(ByVal dstMat As LongInt, ByVal spBase As LongInt)
    Dim k As LongInt
    Dim p As LongInt
    Dim ok As Long
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    If SparseIsValid(spBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dstMat,SparseRows(spBase),SparseCols(spBase),0,0
    If ux_status<>STATUS_OK Then Exit Sub
    For k=0 To SparseNNZ(spBase)-1
        p=SparseTripleIndex(spBase,k,ok)
        If ok<>0 Then
            r=CLngInt(ReadData(p))
            c=CLngInt(ReadData(p+1))
            v=CLngInt(ReadData(p+2))
            If r>=0 And r<SparseRows(spBase) And c>=0 And c<SparseCols(spBase) Then
                MatSet dstMat,r,c,v
            End If
        End If
    Next k
    SetStatus STATUS_OK
End Sub

Function SparseSumValues(ByVal baseAddr As LongInt) As LongInt
    Dim k As LongInt
    Dim p As LongInt
    Dim ok As Long
    Dim s As LongInt
    If SparseIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For k=0 To SparseNNZ(baseAddr)-1
        p=SparseTripleIndex(baseAddr,k,ok)
        If ok<>0 Then s=s+CLngInt(ReadData(p+2))
    Next k
    SetStatus STATUS_OK
    Return s
End Function

Function SparseTrace(ByVal baseAddr As LongInt) As LongInt
    Dim k As LongInt
    Dim p As LongInt
    Dim ok As Long
    Dim s As LongInt
    If SparseIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For k=0 To SparseNNZ(baseAddr)-1
        p=SparseTripleIndex(baseAddr,k,ok)
        If ok<>0 Then
            If CLngInt(ReadData(p))=CLngInt(ReadData(p+1)) Then s=s+CLngInt(ReadData(p+2))
        End If
    Next k
    SetStatus STATUS_OK
    Return s
End Function

Sub MetaSparseVector(ByVal metaId As ULongInt)
    Dim dst As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim p1 As LongInt
    Dim p2 As LongInt
    Dim r As LongInt
    dst=CLngInt(ReadTape(CLngInt(ux_ptr)-4))
    a=CLngInt(ReadTape(CLngInt(ux_ptr)-3))
    b=CLngInt(ReadTape(CLngInt(ux_ptr)-2))
    p1=CLngInt(ReadTape(CLngInt(ux_ptr)-1))
    p2=CLngInt(ReadTape(CLngInt(ux_ptr)))

    Select Case metaId
    Case 600
        VecInit dst,a
        SetResult ux_status
    Case 601
        VecSet dst,a,b
        SetResult ux_status
    Case 602
        r=VecGet(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 603
        VecFill dst,a
        SetResult ux_status
    Case 604
        r=VecSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 605
        r=VecDot(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 606
        r=VecNorm1(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 607
        r=VecNorm2Sq(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 608
        VecAdd dst,a,b
        SetResult ux_status
    Case 609
        VecScale dst,a,b
        SetResult ux_status
    Case 610
        VecFromData dst,a,b
        SetResult ux_status
    Case 611
        VecToData dst,a
        SetResult ux_status
    Case 619
        SetResult 130619
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 640
        SparseInit dst,a,b,p1
        SetResult ux_status
    Case 641
        SparseSetNNZ dst,a
        SetResult ux_status
    Case 642
        SparseSetEntry dst,a,b,p1,p2
        SetResult ux_status
    Case 643
        r=SparseGetEntryValue(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 644
        SparseMatVec dst,a,b
        SetResult ux_status
    Case 645
        SparseToDense dst,a
        SetResult ux_status
    Case 646
        SetResult ClampToCell(SparseNNZ(dst))
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 647
        r=SparseSumValues(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 648
        r=SparseTrace(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 649
        SetResult 130649
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
