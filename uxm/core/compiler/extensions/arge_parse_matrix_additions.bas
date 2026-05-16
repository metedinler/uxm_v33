' UX-MAT V1 compiler ARGE additions
Declare Sub ParseArgeMatrixLine(ByVal lineText As String)
Declare Function MatrixNextToken(ByVal s As String, ByRef p As Long) As String
Declare Function MatrixFixedToScaled(ByVal s As String, ByVal scale As Long) As Long
Declare Function MatrixCsvItem(ByVal s As String, ByVal idx As Long) As String
Declare Sub MatrixEmitHeader(ByVal baseAddr As Long, ByVal rows As Long, ByVal cols As Long, ByVal typ As Long, ByVal scale As Long)
Declare Sub MatrixEmitValues(ByVal baseAddr As Long, ByVal csvText As String, ByVal rows As Long, ByVal cols As Long, ByVal scale As Long, ByVal isFixed As Long)

Function MatrixNextToken(ByVal s As String, ByRef p As Long) As String
    Dim tok As String
    tok=""
    Do While p<=Len(s)
        If Mid(s,p,1)<>" " And Mid(s,p,1)<>Chr(9) Then Exit Do
        p=p+1
    Loop
    Do While p<=Len(s)
        If Mid(s,p,1)=" " Or Mid(s,p,1)=Chr(9) Then Exit Do
        tok=tok+Mid(s,p,1)
        p=p+1
    Loop
    Return tok
End Function

Function MatrixFixedToScaled(ByVal s As String, ByVal scale As Long) As Long
    Dim p As Double
    p=1.0
    If scale<0 Then scale=0
    Do While scale>0
        p=p*10.0
        scale=scale-1
    Loop
    Return CLng(Val(Trim(s))*p)
End Function

Function MatrixCsvItem(ByVal s As String, ByVal idx As Long) As String
    Dim i As Long
    Dim cur As Long
    Dim part As String
    cur=0
    part=""
    For i=1 To Len(s)
        If Mid(s,i,1)="," Then
            If cur=idx Then Return Trim(part)
            cur=cur+1
            part=""
        Else
            part=part+Mid(s,i,1)
        End If
    Next
    If cur=idx Then Return Trim(part)
    Return ""
End Function

Sub MatrixEmitHeader(ByVal baseAddr As Long, ByVal rows As Long, ByVal cols As Long, ByVal typ As Long, ByVal scale As Long)
    Dim totalElements As Long
    Dim totalCells As Long
    Dim flags As Long
    totalElements=rows*cols
    totalCells=16+totalElements
    flags=0
    If typ=1 Then flags=flags Or 1
    If typ=2 Then flags=flags Or 2

    AddDataInit baseAddr+0,77
    AddDataInit baseAddr+1,1
    AddDataInit baseAddr+2,2
    AddDataInit baseAddr+3,typ
    AddDataInit baseAddr+4,flags
    AddDataInit baseAddr+5,rows
    AddDataInit baseAddr+6,cols
    AddDataInit baseAddr+7,scale
    AddDataInit baseAddr+8,1
    AddDataInit baseAddr+9,16
    AddDataInit baseAddr+10,totalElements
    AddDataInit baseAddr+11,totalCells
    AddDataInit baseAddr+12,cols
    AddDataInit baseAddr+13,1
    AddDataInit baseAddr+14,0
    AddDataInit baseAddr+15,0
End Sub

Sub MatrixEmitValues(ByVal baseAddr As Long, ByVal csvText As String, ByVal rows As Long, ByVal cols As Long, ByVal scale As Long, ByVal isFixed As Long)
    Dim i As Long
    Dim n As Long
    Dim needN As Long
    Dim v As Long
    n=SplitCsvCount(csvText)
    needN=rows*cols
    If n<=0 Then Exit Sub
    If n<needN Then needN=n
    For i=0 To needN-1
        If isFixed<>0 Then
            v=MatrixFixedToScaled(MatrixCsvItem(csvText,i),scale)
        Else
            v=Val(MatrixCsvItem(csvText,i))
        End If
        AddDataInit baseAddr+16+i,v
    Next i
End Sub

Sub ParseArgeMatrixLine(ByVal lineText As String)
    Dim low As String
    Dim pEq As Long
    Dim leftPart As String
    Dim rightPart As String
    Dim p As Long
    Dim cmd As String
    Dim t1 As String
    Dim t2 As String
    Dim t3 As String
    Dim t4 As String
    Dim baseAddr As Long
    Dim rows As Long
    Dim cols As Long
    Dim scale As Long
    Dim sizeN As Long
    Dim i As Long

    low=LCase(Trim(lineText))
    If Left(low,7)<>"#matrix" And Left(low,9)<>"#identity" And Left(low,6)<>"#zeros" And Left(low,5)<>"#ones" Then Exit Sub

    pEq=InStr(lineText,"=")
    leftPart=lineText
    rightPart=""
    If pEq>0 Then
        leftPart=Trim(Left(lineText,pEq-1))
        rightPart=Trim(Mid(lineText,pEq+1))
    End If

    p=1
    cmd=LCase(MatrixNextToken(leftPart,p))
    If cmd="#matrix" Or cmd="#matrix-signed" Then
        t1=MatrixNextToken(leftPart,p)
        t2=MatrixNextToken(leftPart,p)
        t3=MatrixNextToken(leftPart,p)
        baseAddr=Val(t1)
        rows=Val(t2)
        cols=Val(t3)
        If rows<=0 Or cols<=0 Then Exit Sub
        If cmd="#matrix-signed" Then
            MatrixEmitHeader baseAddr,rows,cols,1,0
        Else
            MatrixEmitHeader baseAddr,rows,cols,0,0
        End If
        MatrixEmitValues baseAddr,rightPart,rows,cols,0,0
    ElseIf cmd="#matrix-fixed" Then
        t1=MatrixNextToken(leftPart,p)
        t2=MatrixNextToken(leftPart,p)
        t3=MatrixNextToken(leftPart,p)
        t4=MatrixNextToken(leftPart,p)
        baseAddr=Val(t1)
        rows=Val(t2)
        cols=Val(t3)
        scale=Val(t4)
        If rows<=0 Or cols<=0 Then Exit Sub
        MatrixEmitHeader baseAddr,rows,cols,2,scale
        MatrixEmitValues baseAddr,rightPart,rows,cols,scale,-1
    ElseIf cmd="#identity" Then
        t1=MatrixNextToken(leftPart,p)
        t2=MatrixNextToken(leftPart,p)
        baseAddr=Val(t1)
        sizeN=Val(t2)
        If sizeN<=0 Then Exit Sub
        MatrixEmitHeader baseAddr,sizeN,sizeN,0,0
        For i=0 To sizeN-1
            AddDataInit baseAddr+16+i*sizeN+i,1
        Next i
    ElseIf cmd="#zeros" Then
        t1=MatrixNextToken(leftPart,p)
        t2=MatrixNextToken(leftPart,p)
        t3=MatrixNextToken(leftPart,p)
        baseAddr=Val(t1)
        rows=Val(t2)
        cols=Val(t3)
        If rows<=0 Or cols<=0 Then Exit Sub
        MatrixEmitHeader baseAddr,rows,cols,0,0
    ElseIf cmd="#ones" Then
        t1=MatrixNextToken(leftPart,p)
        t2=MatrixNextToken(leftPart,p)
        t3=MatrixNextToken(leftPart,p)
        baseAddr=Val(t1)
        rows=Val(t2)
        cols=Val(t3)
        If rows<=0 Or cols<=0 Then Exit Sub
        MatrixEmitHeader baseAddr,rows,cols,0,0
        For i=0 To rows*cols-1
            AddDataInit baseAddr+16+i,1
        Next i
    End If
End Sub
