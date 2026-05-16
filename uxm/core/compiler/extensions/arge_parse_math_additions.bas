' Add these declarations to uxm31_compiler_final.bas
Declare Sub ParseArgeMathLine(ByVal lineText As String)
Declare Sub AddDataInit(ByVal dataIndex As Long, ByVal value As Long)
Declare Function SplitCsvCount(ByVal s As String) As Long
Declare Function SplitCsvValue(ByVal s As String, ByVal idx As Long) As Long
Declare Sub EmitDataInitializers()
Declare Function RpnTokenCode(ByVal tok As String) As Long
Declare Sub ParseExprRpn(ByVal baseAddr As Long, ByVal rpnText As String)
Declare Sub ParsePoly(ByVal baseAddr As Long, ByVal csvText As String)
Type TDataInit
    idx As Long
    value As Long
End Type
Dim Shared DataInit(1 To 200000) As TDataInit
Dim Shared DataInitCount As Long
' Call ParseArgeMathLine(lineText) inside ParsePragmas/ARGE line scanning when line starts with #poly or #expr-rpn
Sub ParseArgeMathLine(ByVal lineText As String)
    Dim low As String
    Dim pEq As Long
    Dim leftPart As String
    Dim rightPart As String
    Dim baseAddr As Long
    low=LCase(Trim(lineText))
    If Left(low,5)="#poly" Then
        pEq=InStr(lineText,"=")
        If pEq=0 Then Exit Sub
        leftPart=Trim(Left(lineText,pEq-1))
        rightPart=Trim(Mid(lineText,pEq+1))
        baseAddr=Val(Trim(Mid(leftPart,6)))
        ParsePoly baseAddr,rightPart
    ElseIf Left(low,9)="#expr-rpn" Then
        pEq=InStr(lineText,"=")
        If pEq=0 Then Exit Sub
        leftPart=Trim(Left(lineText,pEq-1))
        rightPart=Trim(Mid(lineText,pEq+1))
        baseAddr=Val(Trim(Mid(leftPart,10)))
        ParseExprRpn baseAddr,rightPart
    End If
End Sub
Sub AddDataInit(ByVal dataIndex As Long, ByVal value As Long)
    If dataIndex<0 Then Exit Sub
    DataInitCount=DataInitCount+1
    If DataInitCount>200000 Then Exit Sub
    DataInit(DataInitCount).idx=dataIndex
    DataInit(DataInitCount).value=value
End Sub
Function SplitCsvCount(ByVal s As String) As Long
    Dim i As Long
    Dim n As Long
    If Trim(s)="" Then Return 0
    n=1
    For i=1 To Len(s)
        If Mid(s,i,1)="," Then n=n+1
    Next
    Return n
End Function
Function SplitCsvValue(ByVal s As String, ByVal idx As Long) As Long
    Dim i As Long
    Dim cur As Long
    Dim part As String
    cur=0
    part=""
    For i=1 To Len(s)
        If Mid(s,i,1)="," Then
            If cur=idx Then Return Val(Trim(part))
            cur=cur+1
            part=""
        Else
            part=part+Mid(s,i,1)
        End If
    Next
    If cur=idx Then Return Val(Trim(part))
    Return 0
End Function
Sub ParsePoly(ByVal baseAddr As Long, ByVal csvText As String)
    Dim n As Long
    Dim i As Long
    n=SplitCsvCount(csvText)
    If n<=0 Then Exit Sub
    AddDataInit baseAddr+0,80
    AddDataInit baseAddr+1,1
    AddDataInit baseAddr+2,n-1
    AddDataInit baseAddr+3,0
    For i=0 To n-1
        AddDataInit baseAddr+4+i,SplitCsvValue(csvText,i)
    Next
End Sub
Function RpnTokenCode(ByVal tok As String) As Long
    tok=LCase(Trim(tok))
    Select Case tok
    Case "const":Return 1
    Case "x":Return 2
    Case "+","add":Return 10
    Case "-","sub":Return 11
    Case "*","mul":Return 12
    Case "/","div":Return 13
    Case "pow":Return 14
    Case "sin":Return 20
    Case "cos":Return 21
    Case "tan":Return 22
    Case "exp":Return 23
    Case "log":Return 24
    Case "sqrt":Return 25
    Case "neg":Return 30
    Case "abs":Return 31
    Case "end":Return 99
    End Select
    Return 1
End Function
Sub ParseExprRpn(ByVal baseAddr As Long, ByVal rpnText As String)
    Dim i As Long
    Dim tok As String
    Dim outIdx As Long
    Dim tokenCount As Long
    Dim code As Long
    outIdx=baseAddr+4
    tokenCount=0
    tok=""
    AddDataInit baseAddr+0,69
    AddDataInit baseAddr+1,1
    AddDataInit baseAddr+3,0
    For i=1 To Len(rpnText)+1
        If i>Len(rpnText) Or Mid(rpnText,i,1)=" " Or Mid(rpnText,i,1)=Chr(9) Then
            tok=Trim(tok)
            If tok<>"" Then
                If tok>="0" And tok<="9" Then
                    AddDataInit outIdx,1
                    AddDataInit outIdx+1,Val(tok)
                    outIdx=outIdx+2
                    tokenCount=tokenCount+2
                Else
                    code=RpnTokenCode(tok)
                    AddDataInit outIdx,code
                    outIdx=outIdx+1
                    tokenCount=tokenCount+1
                End If
            End If
            tok=""
        Else
            tok=tok+Mid(rpnText,i,1)
        End If
    Next
    AddDataInit outIdx,99
    tokenCount=tokenCount+1
    AddDataInit baseAddr+2,tokenCount
End Sub
' Call EmitDataInitializers() in EmitHeader after ux_mem initialization and before user instructions.
Sub EmitDataInitializers()
    Dim i As Long
    Dim off As Long
    For i=1 To DataInitCount
        off=DataOffset+DataInit(i).idx*CellSize()
        Print #OutFF,"    mov "+MemSizePrefix()+" [ux_mem + "+LTrim(Str(off))+"] , "+LTrim(Str(DataInit(i).value))
    Next
End Sub
