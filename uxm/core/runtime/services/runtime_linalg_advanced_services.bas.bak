 ' UXM V3.3 Stage-14 Linear Algebra Advanced services
' Meta range: @520..@539
'
' Uses existing UX-MAT V1 descriptors and Stage-13 vector descriptors.
' No MetaLinalgAdvanced declaration here: declaration belongs to uxm31_runtime_fb_full.bas.

Const UX_LINALG_MAX_N As LongInt = 8

Declare Function LinalgAbsLI(ByVal x As LongInt) As LongInt
Declare Function LinalgRoundToLong(ByVal x As Double) As LongInt
Declare Function LinalgMatrixSquareOk(ByVal baseAddr As LongInt, ByVal n As LongInt) As Long
Declare Function LinalgDetN(ByVal baseAddr As LongInt, ByVal n As LongInt) As LongInt
Declare Function LinalgRank(ByVal baseAddr As LongInt) As LongInt
Declare Sub LinalgUpperTriangular(ByVal dst As LongInt, ByVal src As LongInt)
Declare Function LinalgDiagProduct(ByVal baseAddr As LongInt) As LongInt
Declare Sub LinalgInverseNxN(ByVal dst As LongInt, ByVal src As LongInt, ByVal n As LongInt)
Declare Sub LinalgSolveNxN(ByVal dstVec As LongInt, ByVal matA As LongInt, ByVal vecB As LongInt, ByVal n As LongInt)
Declare Sub LinalgMatVec(ByVal dstVec As LongInt, ByVal matA As LongInt, ByVal vecX As LongInt)
Declare Function LinalgIsIdentity(ByVal baseAddr As LongInt) As LongInt
Declare Function LinalgIsSymmetric(ByVal baseAddr As LongInt) As LongInt
Declare Function LinalgRowSum(ByVal baseAddr As LongInt, ByVal rr As LongInt) As LongInt
Declare Function LinalgColSum(ByVal baseAddr As LongInt, ByVal cc As LongInt) As LongInt
Declare Sub LinalgSwapRows(ByVal baseAddr As LongInt, ByVal r1 As LongInt, ByVal r2 As LongInt)
Declare Sub LinalgScaleRow(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal scalar As LongInt)
Declare Sub LinalgAddRowMultiple(ByVal baseAddr As LongInt, ByVal targetRow As LongInt, ByVal srcRow As LongInt, ByVal scalar As LongInt)
Declare Sub LinalgMatSetDirect(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
Declare Sub LinalgVecSetDirect(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByVal value As LongInt)

Function LinalgAbsLI(ByVal x As LongInt) As LongInt
    If x<0 Then Return -x
    Return x
End Function

Function LinalgRoundToLong(ByVal x As Double) As LongInt
    If x>=0 Then
        Return CLngInt(x+0.5)
    Else
        Return CLngInt(x-0.5)
    End If
End Function

Function LinalgMatrixSquareOk(ByVal baseAddr As LongInt, ByVal n As LongInt) As Long
    If MatIsValid(baseAddr)=0 Then Return 0
    If n<=0 Or n>UX_LINALG_MAX_N Then Return 0
    If MatRows(baseAddr)<>n Or MatCols(baseAddr)<>n Then Return 0
    Return -1
End Function

Function LinalgDetN(ByVal baseAddr As LongInt, ByVal n As LongInt) As LongInt
    Dim tmp(0 To 7,0 To 7) As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim pivot As LongInt
    Dim sign As LongInt
    Dim prev As LongInt
    Dim tempVal As LongInt
    If LinalgMatrixSquareOk(baseAddr,n)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If n=1 Then
        SetStatus STATUS_OK
        Return MatGet(baseAddr,0,0)
    End If
    For i=0 To n-1
        For j=0 To n-1
            tmp(i,j)=MatGet(baseAddr,i,j)
        Next j
    Next i
    sign=1
    prev=1
    For k=0 To n-2
        pivot=k
        Do While pivot<n And tmp(pivot,k)=0
            pivot=pivot+1
        Loop
        If pivot>=n Then
            SetStatus STATUS_OK
            Return 0
        End If
        If pivot<>k Then
            For j=0 To n-1
                tempVal=tmp(k,j)
                tmp(k,j)=tmp(pivot,j)
                tmp(pivot,j)=tempVal
            Next j
            sign=-sign
        End If
        For i=k+1 To n-1
            For j=k+1 To n-1
                tmp(i,j)=(tmp(i,j)*tmp(k,k)-tmp(i,k)*tmp(k,j))\prev
            Next j
        Next i
        prev=tmp(k,k)
        For i=k+1 To n-1
            tmp(i,k)=0
        Next i
        If prev=0 Then
            SetStatus STATUS_OK
            Return 0
        End If
    Next k
    SetStatus STATUS_OK
    Return sign*tmp(n-1,n-1)
End Function

Function LinalgRank(ByVal baseAddr As LongInt) As LongInt
    Dim tmp(0 To 7,0 To 7) As Double
    Dim rows As LongInt
    Dim cols As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim i As LongInt
    Dim j As LongInt
    Dim pivot As LongInt
    Dim rankVal As LongInt
    Dim factor As Double
    Dim tv As Double
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    rows=MatRows(baseAddr)
    cols=MatCols(baseAddr)
    If rows<=0 Or cols<=0 Or rows>UX_LINALG_MAX_N Or cols>UX_LINALG_MAX_N Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    For i=0 To rows-1
        For j=0 To cols-1
            tmp(i,j)=CDbl(MatGet(baseAddr,i,j))
        Next j
    Next i
    rankVal=0
    r=0
    For c=0 To cols-1
        pivot=r
        Do While pivot<rows And Abs(tmp(pivot,c))<0.0000001
            pivot=pivot+1
        Loop
        If pivot<rows Then
            If pivot<>r Then
                For j=0 To cols-1
                    tv=tmp(r,j)
                    tmp(r,j)=tmp(pivot,j)
                    tmp(pivot,j)=tv
                Next j
            End If
            For i=r+1 To rows-1
                If Abs(tmp(r,c))>=0.0000001 Then
                    factor=tmp(i,c)/tmp(r,c)
                    For j=c To cols-1
                        tmp(i,j)=tmp(i,j)-factor*tmp(r,j)
                    Next j
                End If
            Next i
            rankVal=rankVal+1
            r=r+1
            If r>=rows Then Exit For
        End If
    Next c
    SetStatus STATUS_OK
    Return rankVal
End Function

Sub LinalgUpperTriangular(ByVal dst As LongInt, ByVal src As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    If MatIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatCopy dst,src
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(dst)-1
        For c=0 To MatCols(dst)-1
            If r>c Then MatSet dst,r,c,0
        Next c
    Next r
    SetStatus STATUS_OK
End Sub

Function LinalgDiagProduct(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim n As LongInt
    Dim p As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=MatRows(baseAddr)
    If MatCols(baseAddr)<n Then n=MatCols(baseAddr)
    p=1
    For i=0 To n-1
        p=p*MatGet(baseAddr,i,i)
    Next i
    SetStatus STATUS_OK
    Return p
End Function

Sub LinalgInverseNxN(ByVal dst As LongInt, ByVal src As LongInt, ByVal n As LongInt)
    Dim aug(0 To 7,0 To 15) As Double
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim pivot As LongInt
    Dim factor As Double
    Dim divv As Double
    Dim tv As Double
    If LinalgMatrixSquareOk(src,n)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=0 To n-1
        For j=0 To n-1
            aug(i,j)=CDbl(MatGet(src,i,j))
            If i=j Then
                aug(i,n+j)=1.0
            Else
                aug(i,n+j)=0.0
            End If
        Next j
    Next i
    For k=0 To n-1
        pivot=k
        Do While pivot<n And Abs(aug(pivot,k))<0.0000001
            pivot=pivot+1
        Loop
        If pivot>=n Then
            SetStatus STATUS_DIV_ZERO
            Exit Sub
        End If
        If pivot<>k Then
            For j=0 To 2*n-1
                tv=aug(k,j)
                aug(k,j)=aug(pivot,j)
                aug(pivot,j)=tv
            Next j
        End If
        divv=aug(k,k)
        If Abs(divv)<0.0000001 Then
            SetStatus STATUS_DIV_ZERO
            Exit Sub
        End If
        For j=0 To 2*n-1
            aug(k,j)=aug(k,j)/divv
        Next j
        For i=0 To n-1
            If i<>k Then
                factor=aug(i,k)
                For j=0 To 2*n-1
                    aug(i,j)=aug(i,j)-factor*aug(k,j)
                Next j
            End If
        Next i
    Next k
    MatInit dst,n,n,0,0
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To n-1
        For j=0 To n-1
            LinalgMatSetDirect dst,i,j,LinalgRoundToLong(aug(i,n+j))
        Next j
    Next i
    SetStatus STATUS_OK
End Sub

Sub LinalgSolveNxN(ByVal dstVec As LongInt, ByVal matA As LongInt, ByVal vecB As LongInt, ByVal n As LongInt)
    Dim aug(0 To 7,0 To 8) As Double
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim pivot As LongInt
    Dim factor As Double
    Dim divv As Double
    Dim tv As Double
    If LinalgMatrixSquareOk(matA,n)=0 Or VecIsValid(vecB)=0 Or VecLen(vecB)<>n Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For i=0 To n-1
        For j=0 To n-1
            aug(i,j)=CDbl(MatGet(matA,i,j))
        Next j
        aug(i,n)=CDbl(VecGet(vecB,i))
    Next i
    For k=0 To n-1
        pivot=k
        Do While pivot<n And Abs(aug(pivot,k))<0.0000001
            pivot=pivot+1
        Loop
        If pivot>=n Then
            SetStatus STATUS_DIV_ZERO
            Exit Sub
        End If
        If pivot<>k Then
            For j=0 To n
                tv=aug(k,j)
                aug(k,j)=aug(pivot,j)
                aug(pivot,j)=tv
            Next j
        End If
        divv=aug(k,k)
        If Abs(divv)<0.0000001 Then
            SetStatus STATUS_DIV_ZERO
            Exit Sub
        End If
        For j=k To n
            aug(k,j)=aug(k,j)/divv
        Next j
        For i=0 To n-1
            If i<>k Then
                factor=aug(i,k)
                For j=k To n
                    aug(i,j)=aug(i,j)-factor*aug(k,j)
                Next j
            End If
        Next i
    Next k
    VecInit dstVec,n
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To n-1
        LinalgVecSetDirect dstVec,i,LinalgRoundToLong(aug(i,n))
    Next i
    SetStatus STATUS_OK
End Sub

Sub LinalgMatVec(ByVal dstVec As LongInt, ByVal matA As LongInt, ByVal vecX As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim s As LongInt
    If MatIsValid(matA)=0 Or VecIsValid(vecX)=0 Or MatCols(matA)<>VecLen(vecX) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    VecInit dstVec,MatRows(matA)
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(matA)-1
        s=0
        For c=0 To MatCols(matA)-1
            s=s+MatGet(matA,r,c)*VecGet(vecX,c)
        Next c
        LinalgVecSetDirect dstVec,r,s
    Next r
    SetStatus STATUS_OK
End Sub

Function LinalgIsIdentity(ByVal baseAddr As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    If MatIsValid(baseAddr)=0 Or MatRows(baseAddr)<>MatCols(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    For r=0 To MatRows(baseAddr)-1
        For c=0 To MatCols(baseAddr)-1
            If r=c Then
                If MatGet(baseAddr,r,c)<>1 Then
                    SetStatus STATUS_OK
                    Return 0
                End If
            Else
                If MatGet(baseAddr,r,c)<>0 Then
                    SetStatus STATUS_OK
                    Return 0
                End If
            End If
        Next c
    Next r
    SetStatus STATUS_OK
    Return 1
End Function

Function LinalgIsSymmetric(ByVal baseAddr As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    If MatIsValid(baseAddr)=0 Or MatRows(baseAddr)<>MatCols(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    For r=0 To MatRows(baseAddr)-1
        For c=r+1 To MatCols(baseAddr)-1
            If MatGet(baseAddr,r,c)<>MatGet(baseAddr,c,r) Then
                SetStatus STATUS_OK
                Return 0
            End If
        Next c
    Next r
    SetStatus STATUS_OK
    Return 1
End Function

Function LinalgRowSum(ByVal baseAddr As LongInt, ByVal rr As LongInt) As LongInt
    Dim c As LongInt
    Dim s As LongInt
    If MatIsValid(baseAddr)=0 Or rr<0 Or rr>=MatRows(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For c=0 To MatCols(baseAddr)-1
        s=s+MatGet(baseAddr,rr,c)
    Next c
    SetStatus STATUS_OK
    Return s
End Function

Function LinalgColSum(ByVal baseAddr As LongInt, ByVal cc As LongInt) As LongInt
    Dim r As LongInt
    Dim s As LongInt
    If MatIsValid(baseAddr)=0 Or cc<0 Or cc>=MatCols(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To MatRows(baseAddr)-1
        s=s+MatGet(baseAddr,r,cc)
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Sub LinalgSwapRows(ByVal baseAddr As LongInt, ByVal r1 As LongInt, ByVal r2 As LongInt)
    Dim c As LongInt
    Dim v As LongInt
    If MatIsValid(baseAddr)=0 Or r1<0 Or r2<0 Or r1>=MatRows(baseAddr) Or r2>=MatRows(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For c=0 To MatCols(baseAddr)-1
        v=MatGet(baseAddr,r1,c)
        MatSet baseAddr,r1,c,MatGet(baseAddr,r2,c)
        MatSet baseAddr,r2,c,v
    Next c
    SetStatus STATUS_OK
End Sub

Sub LinalgScaleRow(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal scalar As LongInt)
    Dim c As LongInt
    If MatIsValid(baseAddr)=0 Or rr<0 Or rr>=MatRows(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For c=0 To MatCols(baseAddr)-1
        MatSet baseAddr,rr,c,MatGet(baseAddr,rr,c)*scalar
    Next c
    SetStatus STATUS_OK
End Sub

Sub LinalgAddRowMultiple(ByVal baseAddr As LongInt, ByVal targetRow As LongInt, ByVal srcRow As LongInt, ByVal scalar As LongInt)
    Dim c As LongInt
    If MatIsValid(baseAddr)=0 Or targetRow<0 Or srcRow<0 Or targetRow>=MatRows(baseAddr) Or srcRow>=MatRows(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For c=0 To MatCols(baseAddr)-1
        MatSet baseAddr,targetRow,c,MatGet(baseAddr,targetRow,c)+MatGet(baseAddr,srcRow,c)*scalar
    Next c
    SetStatus STATUS_OK
End Sub


Sub LinalgMatSetDirect(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
    Dim cols As LongInt
    Dim dataOff As LongInt
    Dim idx As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If r<0 Or c<0 Or r>=MatRows(baseAddr) Or c>=MatCols(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        MatWriteStatus baseAddr,STATUS_DATA_BOUNDS
        Exit Sub
    End If
    cols=CLngInt(ReadData(baseAddr+6))
    dataOff=CLngInt(ReadData(baseAddr+9))
    If dataOff<=0 Then dataOff=16
    idx=baseAddr+dataOff+r*cols+c
    WriteData idx,ClampToCell(value)
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub LinalgVecSetDirect(ByVal baseAddr As LongInt, ByVal idx As LongInt, ByVal value As LongInt)
    Dim off As LongInt
    If VecIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If idx<0 Or idx>=VecLen(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    off=CLngInt(ReadData(baseAddr+2))
    If off<=0 Then off=8
    WriteData baseAddr+off+idx,ClampToCell(value)
    SetStatus STATUS_OK
End Sub

Sub MetaLinalgAdvanced(ByVal metaId As ULongInt)
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
    Case 520
        r=LinalgDetN(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 521
        r=LinalgRank(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 522
        LinalgUpperTriangular dst,a
        SetResult ux_status
    Case 523
        r=LinalgDiagProduct(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 524
        LinalgInverseNxN dst,a,b
        SetResult ux_status
    Case 525
        LinalgSolveNxN dst,a,b,p1
        SetResult ux_status
    Case 526
        LinalgMatVec dst,a,b
        SetResult ux_status
    Case 527
        r=LinalgIsIdentity(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 528
        r=LinalgIsSymmetric(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 529
        r=LinalgRowSum(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 530
        r=LinalgColSum(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 531
        LinalgSwapRows dst,a,b
        SetResult ux_status
    Case 532
        LinalgScaleRow dst,a,b
        SetResult ux_status
    Case 533
        LinalgAddRowMultiple dst,a,b,p1
        SetResult ux_status
    Case 539
        SetResult 14520
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
