' UX-MAT V1 runtime services for uxm31_runtime_fb_full.bas
' Meta range: 160..199

Declare Function MatPow10(ByVal n As LongInt) As LongInt
Declare Function MatIsValid(ByVal baseAddr As LongInt) As Long
Declare Sub MatWriteStatus(ByVal baseAddr As LongInt, ByVal code As UByte)
Declare Function MatRows(ByVal baseAddr As LongInt) As LongInt
Declare Function MatCols(ByVal baseAddr As LongInt) As LongInt
Declare Function MatType(ByVal baseAddr As LongInt) As LongInt
Declare Function MatScale(ByVal baseAddr As LongInt) As LongInt
Declare Function MatIndex(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByRef ok As Long) As LongInt
Declare Function MatFixedMul(ByVal a As LongInt, ByVal b As LongInt, ByVal scale As LongInt) As LongInt
Declare Function MatFixedToText(ByVal v As LongInt, ByVal scale As LongInt) As String
Declare Sub MatInit(ByVal baseAddr As LongInt, ByVal rows As LongInt, ByVal cols As LongInt, ByVal typ As LongInt, ByVal scale As LongInt)
Declare Sub MatClear(ByVal baseAddr As LongInt)
Declare Sub MatSet(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
Declare Function MatGet(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
Declare Sub MatFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
Declare Sub MatCopy(ByVal dst As LongInt, ByVal src As LongInt)
Declare Sub MatPrint(ByVal baseAddr As LongInt)
Declare Sub MatPrintRaw(ByVal baseAddr As LongInt)
Declare Sub MatAdd(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
Declare Sub MatSub(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
Declare Sub MatScalarMul(ByVal dst As LongInt, ByVal a As LongInt, ByVal scalar As LongInt)
Declare Sub MatMul(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
Declare Sub MatTransposeCopy(ByVal dst As LongInt, ByVal src As LongInt)
Declare Sub MatIdentity(ByVal baseAddr As LongInt, ByVal sizeN As LongInt, ByVal typ As LongInt, ByVal scale As LongInt)
Declare Function MatTrace(ByVal baseAddr As LongInt) As LongInt
Declare Function MatDet2(ByVal baseAddr As LongInt) As LongInt
Declare Sub MatShape(ByVal baseAddr As LongInt)

Function MatPow10(ByVal n As LongInt) As LongInt
    Dim i As LongInt
    Dim p As LongInt
    p=1
    If n<=0 Then Return 1
    For i=1 To n
        p=p*10
    Next i
    Return p
End Function

Function MatIsValid(ByVal baseAddr As LongInt) As Long
    If baseAddr<0 Or baseAddr+15>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr+0)<>77 Then Return 0
    If ReadData(baseAddr+1)<>1 Then Return 0
    If ReadData(baseAddr+2)<>2 Then Return 0
    If ReadData(baseAddr+5)<=0 Or ReadData(baseAddr+6)<=0 Then Return 0
    Return -1
End Function

Sub MatWriteStatus(ByVal baseAddr As LongInt, ByVal code As UByte)
    If baseAddr>=0 And baseAddr+14<CLngInt(ux_data_cells) Then
        WriteData baseAddr+14,code
    End If
End Sub

Function MatRows(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+5))
End Function

Function MatCols(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+6))
End Function

Function MatType(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+3))
End Function

Function MatScale(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+7))
End Function

Function MatIndex(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByRef ok As Long) As LongInt
    Dim rows As LongInt
    Dim cols As LongInt
    Dim idx As LongInt
    rows=MatRows(baseAddr)
    cols=MatCols(baseAddr)
    If r<0 Or c<0 Or r>=rows Or c>=cols Then
        ok=0
        Return 0
    End If
    idx=baseAddr+CLngInt(ReadData(baseAddr+9))+r*CLngInt(ReadData(baseAddr+12))+c*CLngInt(ReadData(baseAddr+13))
    If idx<0 Or idx>=CLngInt(ux_data_cells) Then
        ok=0
        Return 0
    End If
    ok=-1
    Return idx
End Function

Function MatFixedMul(ByVal a As LongInt, ByVal b As LongInt, ByVal scale As LongInt) As LongInt
    Dim den As LongInt
    den=MatPow10(scale)
    If den<=0 Then den=1
    Return (a*b)\den
End Function

Function MatFixedToText(ByVal v As LongInt, ByVal scale As LongInt) As String
    Dim neg As Long
    Dim p As LongInt
    Dim absv As LongInt
    Dim hi As LongInt
    Dim lo As LongInt
    Dim sLo As String
    If scale<=0 Then Return LTrim(Str(v))
    neg=0
    If v<0 Then
        neg=-1
        absv=-v
    Else
        absv=v
    End If
    p=MatPow10(scale)
    If p<=0 Then p=1
    hi=absv\p
    lo=absv Mod p
    sLo=LTrim(Str(lo))
    Do While Len(sLo)<scale
        sLo="0"+sLo
    Loop
    If neg<>0 Then
        Return "-"+LTrim(Str(hi))+"."+sLo
    Else
        Return LTrim(Str(hi))+"."+sLo
    End If
End Function

Sub MatInit(ByVal baseAddr As LongInt, ByVal rows As LongInt, ByVal cols As LongInt, ByVal typ As LongInt, ByVal scale As LongInt)
    Dim totalElements As LongInt
    Dim totalCells As LongInt
    Dim i As LongInt
    If baseAddr<0 Or rows<=0 Or cols<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        MatWriteStatus baseAddr,STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If typ<0 Or typ>2 Then
        SetStatus STATUS_INVALID_META
        MatWriteStatus baseAddr,STATUS_INVALID_META
        Exit Sub
    End If
    totalElements=rows*cols
    totalCells=16+totalElements
    If baseAddr+totalCells-1>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        MatWriteStatus baseAddr,STATUS_DATA_BOUNDS
        Exit Sub
    End If

    WriteData baseAddr+0,77
    WriteData baseAddr+1,1
    WriteData baseAddr+2,2
    WriteData baseAddr+3,typ
    If typ=1 Then
        WriteData baseAddr+4,1
    ElseIf typ=2 Then
        WriteData baseAddr+4,2
    Else
        WriteData baseAddr+4,0
    End If
    WriteData baseAddr+5,rows
    WriteData baseAddr+6,cols
    WriteData baseAddr+7,scale
    WriteData baseAddr+8,1
    WriteData baseAddr+9,16
    WriteData baseAddr+10,totalElements
    WriteData baseAddr+11,totalCells
    WriteData baseAddr+12,cols
    WriteData baseAddr+13,1
    WriteData baseAddr+14,0
    WriteData baseAddr+15,0

    For i=0 To totalElements-1
        WriteData baseAddr+16+i,0
    Next i

    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub MatClear(ByVal baseAddr As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=CLngInt(ReadData(baseAddr+10))
    For i=0 To n-1
        WriteData baseAddr+16+i,0
    Next i
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub MatSet(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt, ByVal value As LongInt)
    Dim idx As LongInt
    Dim ok As Long
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    idx=MatIndex(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        MatWriteStatus baseAddr,STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData idx,ClampToCell(value)
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Function MatGet(ByVal baseAddr As LongInt, ByVal r As LongInt, ByVal c As LongInt) As LongInt
    Dim idx As LongInt
    Dim ok As Long
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    idx=MatIndex(baseAddr,r,c,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        MatWriteStatus baseAddr,STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
    Return CLngInt(ReadData(idx))
End Function

Sub MatFill(ByVal baseAddr As LongInt, ByVal value As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=CLngInt(ReadData(baseAddr+10))
    For i=0 To n-1
        WriteData baseAddr+16+i,ClampToCell(value)
    Next i
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub MatCopy(ByVal dst As LongInt, ByVal src As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    If MatIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dst,MatRows(src),MatCols(src),MatType(src),MatScale(src)
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(src)-1
        For c=0 To MatCols(src)-1
            MatSet dst,r,c,MatGet(src,r,c)
        Next c
    Next r
    SetStatus STATUS_OK
    MatWriteStatus dst,STATUS_OK
End Sub

Sub MatPrint(ByVal baseAddr As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For r=0 To MatRows(baseAddr)-1
        Print "[";
        For c=0 To MatCols(baseAddr)-1
            v=MatGet(baseAddr,r,c)
            If MatType(baseAddr)=2 Then
                Print MatFixedToText(v,MatScale(baseAddr));
            Else
                Print LTrim(Str(v));
            End If
            If c<MatCols(baseAddr)-1 Then Print " ";
        Next c
        Print "]"
    Next r
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub MatPrintRaw(ByVal baseAddr As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    n=CLngInt(ReadData(baseAddr+10))
    For i=0 To n-1
        Print LTrim(Str(ReadData(baseAddr+16+i)));
        If i<n-1 Then Print ",";
    Next i
    Print
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub MatAdd(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    If MatIsValid(a)=0 Or MatIsValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatRows(a)<>MatRows(b) Or MatCols(a)<>MatCols(b) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dst,MatRows(a),MatCols(a),MatType(a),MatScale(a)
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(a)-1
        For c=0 To MatCols(a)-1
            v=MatGet(a,r,c)+MatGet(b,r,c)
            MatSet dst,r,c,v
        Next c
    Next r
    SetStatus STATUS_OK
    MatWriteStatus dst,STATUS_OK
End Sub

Sub MatSub(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    If MatIsValid(a)=0 Or MatIsValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatRows(a)<>MatRows(b) Or MatCols(a)<>MatCols(b) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dst,MatRows(a),MatCols(a),MatType(a),MatScale(a)
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(a)-1
        For c=0 To MatCols(a)-1
            v=MatGet(a,r,c)-MatGet(b,r,c)
            MatSet dst,r,c,v
        Next c
    Next r
    SetStatus STATUS_OK
    MatWriteStatus dst,STATUS_OK
End Sub

Sub MatScalarMul(ByVal dst As LongInt, ByVal a As LongInt, ByVal scalar As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    If MatIsValid(a)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dst,MatRows(a),MatCols(a),MatType(a),MatScale(a)
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(a)-1
        For c=0 To MatCols(a)-1
            If MatType(a)=2 Then
                v=MatFixedMul(MatGet(a,r,c),scalar,MatScale(a))
            Else
                v=MatGet(a,r,c)*scalar
            End If
            MatSet dst,r,c,v
        Next c
    Next r
    SetStatus STATUS_OK
    MatWriteStatus dst,STATUS_OK
End Sub

Sub MatMul(ByVal dst As LongInt, ByVal a As LongInt, ByVal b As LongInt)
    Dim i As LongInt
    Dim j As LongInt
    Dim k As LongInt
    Dim sum As LongInt
    Dim av As LongInt
    Dim bv As LongInt
    If MatIsValid(a)=0 Or MatIsValid(b)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    If MatCols(a)<>MatRows(b) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dst,MatRows(a),MatCols(b),MatType(a),MatScale(a)
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To MatRows(a)-1
        For j=0 To MatCols(b)-1
            sum=0
            For k=0 To MatCols(a)-1
                av=MatGet(a,i,k)
                bv=MatGet(b,k,j)
                If MatType(a)=2 Then
                    sum=sum+MatFixedMul(av,bv,MatScale(a))
                Else
                    sum=sum+av*bv
                End If
            Next k
            MatSet dst,i,j,sum
        Next j
    Next i
    SetStatus STATUS_OK
    MatWriteStatus dst,STATUS_OK
End Sub

Sub MatTransposeCopy(ByVal dst As LongInt, ByVal src As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    If MatIsValid(src)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit dst,MatCols(src),MatRows(src),MatType(src),MatScale(src)
    If ux_status<>STATUS_OK Then Exit Sub
    For r=0 To MatRows(src)-1
        For c=0 To MatCols(src)-1
            MatSet dst,c,r,MatGet(src,r,c)
        Next c
    Next r
    SetStatus STATUS_OK
    MatWriteStatus dst,STATUS_OK
End Sub

Sub MatIdentity(ByVal baseAddr As LongInt, ByVal sizeN As LongInt, ByVal typ As LongInt, ByVal scale As LongInt)
    Dim i As LongInt
    MatInit baseAddr,sizeN,sizeN,typ,scale
    If ux_status<>STATUS_OK Then Exit Sub
    For i=0 To sizeN-1
        If typ=2 Then
            MatSet baseAddr,i,i,MatPow10(scale)
        Else
            MatSet baseAddr,i,i,1
        End If
    Next i
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Function MatTrace(ByVal baseAddr As LongInt) As LongInt
    Dim i As LongInt
    Dim s As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If MatRows(baseAddr)<>MatCols(baseAddr) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For i=0 To MatRows(baseAddr)-1
        s=s+MatGet(baseAddr,i,i)
    Next i
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
    Return s
End Function

Function MatDet2(ByVal baseAddr As LongInt) As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim c As LongInt
    Dim d As LongInt
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If MatRows(baseAddr)<>2 Or MatCols(baseAddr)<>2 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    a=MatGet(baseAddr,0,0)
    b=MatGet(baseAddr,0,1)
    c=MatGet(baseAddr,1,0)
    d=MatGet(baseAddr,1,1)
    If MatType(baseAddr)=2 Then
        MatDet2=MatFixedMul(a,d,MatScale(baseAddr))-MatFixedMul(b,c,MatScale(baseAddr))
    Else
        MatDet2=a*d-b*c
    End If
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Function

Sub MatShape(ByVal baseAddr As LongInt)
    If MatIsValid(baseAddr)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteTape CLngInt(ux_ptr)+1,MatRows(baseAddr)
    WriteTape CLngInt(ux_ptr)+2,MatCols(baseAddr)
    SetStatus STATUS_OK
    MatWriteStatus baseAddr,STATUS_OK
End Sub

Sub MetaMatrix(ByVal metaId As ULongInt)
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
    Case 160
        MatInit dst,a,b,p1,p2
        SetResult ux_status
    Case 161
        MatClear dst
        SetResult ux_status
    Case 162
        MatSet dst,a,b,p1
        SetResult ux_status
    Case 163
        SetResult ClampToCell(MatGet(dst,a,b))
        SetLogicFlags ResultValue()
    Case 164
        MatFill dst,a
        SetResult ux_status
    Case 165
        MatCopy dst,a
        SetResult ux_status
    Case 166
        MatPrint a
        SetResult ux_status
    Case 167
        MatAdd dst,a,b
        SetResult ux_status
    Case 168
        MatSub dst,a,b
        SetResult ux_status
    Case 169
        MatScalarMul dst,a,b
        SetResult ux_status
    Case 170
        MatMul dst,a,b
        SetResult ux_status
    Case 171
        MatTransposeCopy dst,a
        SetResult ux_status
    Case 172
        MatIdentity dst,a,b,p1
        SetResult ux_status
    Case 173
        r=MatTrace(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 174
        MatShape a
        SetResult ux_status
    Case 175
        r=MatDet2(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 176
        MatPrintRaw a
        SetResult ux_status
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
