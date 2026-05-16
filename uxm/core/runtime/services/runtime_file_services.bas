#ifndef UXM_RUNTIME_FILE_SERVICES_BAS
#define UXM_RUNTIME_FILE_SERVICES_BAS

' UXM V3.3 Stage-5 FILE V1 services
' Service range: @400..@415
'
' Calling convention uses tape cells around current pointer:
'   @400/@401/@402/@403/@404: (T-1)=pathZ data start -> (T+1)=handle
'   @405: (T-1)=handle -> (T+1)=1/0
'   @406: (T-1)=handle -> (T+1)=byte, status EOF on end
'   @407: (T-2)=handle, (T-1)=byte -> (T+1)=1/0
'   @408: (T-3)=handle, (T-2)=dst data start, (T-1)=max -> (T+1)=count
'   @409: (T-2)=handle, (T-1)=src data start -> (T+1)=count
'   @413: (T-1)=handle -> (T+1)=file position
'   @414: (T-1)=handle -> (T+1)=1 if EOF else 0
'   @415: -> (T+1)=last file status

Const UXM_FILE_MAX_HANDLES As Integer = 16
Const UXM_FILE_STATUS_OK As UByte = 0
Const UXM_FILE_STATUS_BAD_HANDLE As UByte = 24
Const UXM_FILE_STATUS_IO_ERROR As UByte = 2
Const UXM_FILE_STATUS_EOF As UByte = 26
Const UXM_FILE_STATUS_BOUNDS As UByte = 16

Dim Shared ux_file_num(1 To UXM_FILE_MAX_HANDLES) As Integer
Dim Shared ux_file_open(1 To UXM_FILE_MAX_HANDLES) As Integer
Dim Shared ux_file_last_status As UByte = UXM_FILE_STATUS_OK

Sub FileSetStatus(ByVal code As UByte)
    ux_file_last_status = code
    SetStatus code
End Sub

Function FileReadArgRel(ByVal rel As LongInt) As LongInt
    Return CLngInt(ReadTape(CLngInt(ux_ptr) + rel))
End Function

Sub FileWriteResultRel(ByVal rel As LongInt, ByVal value As ULongInt)
    WriteTape CLngInt(ux_ptr) + rel, value And CellMask()
End Sub

Function FileCell8(ByVal idx As LongInt) As ULongInt
    Return ReadData(idx) And &HFF
End Function

Sub FilePutCell8(ByVal idx As LongInt, ByVal value As ULongInt)
    WriteData idx, value And &HFF
End Sub

Function FileDataZToString(ByVal startIdx As LongInt) As String
    Dim s As String
    Dim i As LongInt
    Dim c As ULongInt
    s = ""
    If startIdx < 0 Or startIdx >= CLngInt(ux_data_cells) Then
        FileSetStatus UXM_FILE_STATUS_BOUNDS
        Return ""
    End If
    For i = startIdx To CLngInt(ux_data_cells) - 1
        c = FileCell8(i)
        If c = 0 Then Exit For
        s &= Chr(CInt(c And &HFF))
    Next i
    Return s
End Function

Sub FileStringToDataZ(ByVal s As String, ByVal dst As LongInt, ByVal maxLen As LongInt)
    Dim i As LongInt
    Dim n As LongInt
    If dst < 0 Or maxLen < 1 Or dst >= CLngInt(ux_data_cells) Then
        FileSetStatus UXM_FILE_STATUS_BOUNDS
        Exit Sub
    End If
    n = Len(s)
    If n > maxLen - 1 Then n = maxLen - 1
    If dst + n >= CLngInt(ux_data_cells) Then
        n = CLngInt(ux_data_cells) - dst - 1
    End If
    If n < 0 Then n = 0
    For i = 0 To n - 1
        FilePutCell8 dst + i, Asc(Mid(s, i + 1, 1))
    Next i
    If dst + n < CLngInt(ux_data_cells) Then FilePutCell8 dst + n, 0
End Sub

Function FileAllocHandle(ByVal ff As Integer) As LongInt
    Dim i As Integer
    For i = 1 To UXM_FILE_MAX_HANDLES
        If ux_file_open(i) = 0 Then
            ux_file_num(i) = ff
            ux_file_open(i) = -1
            Return i
        End If
    Next i
    Return 0
End Function

Function FileHandleValid(ByVal h As LongInt) As Long
    If h < 1 Or h > UXM_FILE_MAX_HANDLES Then Return 0
    If ux_file_open(h) = 0 Then Return 0
    Return -1
End Function

Sub UX_FILE_OPEN_READ()
    Dim pathStart As LongInt
    Dim path As String
    Dim ff As Integer
    Dim h As LongInt
    pathStart = FileReadArgRel(-1)
    path = FileDataZToString(pathStart)
    If ux_file_last_status <> UXM_FILE_STATUS_OK Then
        FileWriteResultRel 1, 0
        Exit Sub
    End If
    ff = FreeFile
    If Open(path For Input As #ff) <> 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    h = FileAllocHandle(ff)
    If h = 0 Then
        Close #ff
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    FileWriteResultRel 1, CULngInt(h)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_OPEN_WRITE()
    Dim pathStart As LongInt
    Dim path As String
    Dim ff As Integer
    Dim h As LongInt
    pathStart = FileReadArgRel(-1)
    path = FileDataZToString(pathStart)
    If ux_file_last_status <> UXM_FILE_STATUS_OK Then
        FileWriteResultRel 1, 0
        Exit Sub
    End If
    ff = FreeFile
    If Open(path For Output As #ff) <> 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    h = FileAllocHandle(ff)
    If h = 0 Then
        Close #ff
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    FileWriteResultRel 1, CULngInt(h)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_OPEN_APPEND()
    Dim pathStart As LongInt
    Dim path As String
    Dim ff As Integer
    Dim h As LongInt
    pathStart = FileReadArgRel(-1)
    path = FileDataZToString(pathStart)
    If ux_file_last_status <> UXM_FILE_STATUS_OK Then
        FileWriteResultRel 1, 0
        Exit Sub
    End If
    ff = FreeFile
    If Open(path For Append As #ff) <> 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    h = FileAllocHandle(ff)
    If h = 0 Then
        Close #ff
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    FileWriteResultRel 1, CULngInt(h)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_OPEN_BINARY_READ()
    Dim pathStart As LongInt
    Dim path As String
    Dim ff As Integer
    Dim h As LongInt
    pathStart = FileReadArgRel(-1)
    path = FileDataZToString(pathStart)
    If ux_file_last_status <> UXM_FILE_STATUS_OK Then
        FileWriteResultRel 1, 0
        Exit Sub
    End If
    ff = FreeFile
    If Open(path For Binary Access Read As #ff) <> 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    h = FileAllocHandle(ff)
    If h = 0 Then
        Close #ff
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    FileWriteResultRel 1, CULngInt(h)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_OPEN_BINARY_WRITE()
    Dim pathStart As LongInt
    Dim path As String
    Dim ff As Integer
    Dim h As LongInt
    pathStart = FileReadArgRel(-1)
    path = FileDataZToString(pathStart)
    If ux_file_last_status <> UXM_FILE_STATUS_OK Then
        FileWriteResultRel 1, 0
        Exit Sub
    End If
    ff = FreeFile
    If Open(path For Binary Access Write As #ff) <> 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    h = FileAllocHandle(ff)
    If h = 0 Then
        Close #ff
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_IO_ERROR
        Exit Sub
    End If
    FileWriteResultRel 1, CULngInt(h)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_CLOSE()
    Dim h As LongInt
    h = FileReadArgRel(-1)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    Dim ffClose As Integer
    ffClose = ux_file_num(h)
    Close #ffClose
    ux_file_open(h) = 0
    ux_file_num(h) = 0
    FileWriteResultRel 1, 1
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_READ_BYTE()
    Dim h As LongInt
    Dim b As UByte
    h = FileReadArgRel(-1)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    Dim ffReadByte As Integer
    ffReadByte = ux_file_num(h)
    If Eof(ffReadByte) Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_EOF
        Exit Sub
    End If
    Get #ffReadByte, , b
    FileWriteResultRel 1, CULngInt(b)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_WRITE_BYTE()
    Dim h As LongInt
    Dim b As UByte
    h = FileReadArgRel(-2)
    b = CUByte(FileReadArgRel(-1) And &HFF)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    Dim ffWriteByte As Integer
    ffWriteByte = ux_file_num(h)
    Put #ffWriteByte, , b
    FileWriteResultRel 1, 1
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_READ_LINE()
    Dim h As LongInt
    Dim dst As LongInt
    Dim maxLen As LongInt
    Dim s As String
    h = FileReadArgRel(-3)
    dst = FileReadArgRel(-2)
    maxLen = FileReadArgRel(-1)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    Dim ffReadLine As Integer
    ffReadLine = ux_file_num(h)
    If Eof(ffReadLine) Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_EOF
        Exit Sub
    End If
    Line Input #ffReadLine, s
    FileStringToDataZ s, dst, maxLen
    FileWriteResultRel 1, CULngInt(Len(s))
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_WRITE_LINE()
    Dim h As LongInt
    Dim src As LongInt
    Dim s As String
    h = FileReadArgRel(-2)
    src = FileReadArgRel(-1)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    s = FileDataZToString(src)
    If ux_file_last_status <> UXM_FILE_STATUS_OK Then
        FileWriteResultRel 1, 0
        Exit Sub
    End If
    Dim ffWriteLine As Integer
    ffWriteLine = ux_file_num(h)
    Print #ffWriteLine, s
    FileWriteResultRel 1, CULngInt(Len(s))
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_TELL()
    Dim h As LongInt
    h = FileReadArgRel(-1)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 0
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    Dim ffTell As Integer
    ffTell = ux_file_num(h)
    FileWriteResultRel 1, CULngInt(Loc(ffTell))
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_EOF()
    Dim h As LongInt
    h = FileReadArgRel(-1)
    If FileHandleValid(h) = 0 Then
        FileWriteResultRel 1, 1
        FileSetStatus UXM_FILE_STATUS_BAD_HANDLE
        Exit Sub
    End If
    Dim ffEof As Integer
    ffEof = ux_file_num(h)
    If Eof(ffEof) Then
        FileWriteResultRel 1, 1
    Else
        FileWriteResultRel 1, 0
    End If
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_STATUS()
    FileWriteResultRel 1, ux_file_last_status
    SetLogicFlags ux_file_last_status
    SetStatus UXM_FILE_STATUS_OK
End Sub



Sub UX_FILE_READ_BLOCK()
    ' @410: T-4=handle, T-3=dst data start, T-2=max bytes, T-1=aux-slot -> T+1=count
    Dim h As LongInt, dst As LongInt, maxBytes As LongInt, ff As Integer, i As LongInt, c As UByte
    h=FileReadArgRel(-4): dst=FileReadArgRel(-3): maxBytes=FileReadArgRel(-2)
    If FileHandleValid(h)=0 Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_BAD_HANDLE: Exit Sub
    If dst<0 Or maxBytes<0 Or dst+maxBytes>CLngInt(ux_data_cells) Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_BOUNDS: Exit Sub
    ff=ux_file_num(h): i=0
    Do While i<maxBytes And Not Eof(ff)
        Get #ff,,c
        If Eof(ff) And i=0 Then Exit Do
        FilePutCell8 dst+i,c
        i+=1
    Loop
    FileWriteResultRel 1,CULngInt(i)
    If i=0 And Eof(ff) Then FileSetStatus UXM_FILE_STATUS_EOF Else FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_WRITE_BLOCK()
    ' @411: T-4=handle, T-3=src data start, T-2=count, T-1=aux-slot -> T+1=count
    Dim h As LongInt, src As LongInt, countBytes As LongInt, ff As Integer, i As LongInt, c As UByte
    h=FileReadArgRel(-4): src=FileReadArgRel(-3): countBytes=FileReadArgRel(-2)
    If FileHandleValid(h)=0 Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_BAD_HANDLE: Exit Sub
    If src<0 Or countBytes<0 Or src+countBytes>CLngInt(ux_data_cells) Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_BOUNDS: Exit Sub
    ff=ux_file_num(h)
    For i=0 To countBytes-1
        c=CUByte(FileCell8(src+i))
        Put #ff,,c
    Next
    FileWriteResultRel 1,CULngInt(countBytes)
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub UX_FILE_SEEK()
    ' @412: T-2=handle, T-1=1-based byte position -> T+1=position
    Dim h As LongInt, posv As LongInt, ff As Integer
    h=FileReadArgRel(-2): posv=FileReadArgRel(-1)
    If FileHandleValid(h)=0 Then FileWriteResultRel 1,0: FileSetStatus UXM_FILE_STATUS_BAD_HANDLE: Exit Sub
    If posv<1 Then posv=1
    ff=ux_file_num(h)
    Seek #ff, posv
    FileWriteResultRel 1, CULngInt(Seek(ff))
    FileSetStatus UXM_FILE_STATUS_OK
End Sub

Sub MetaFile(ByVal metaId As ULongInt)
    Select Case metaId
    Case 400
        UX_FILE_OPEN_READ()
    Case 401
        UX_FILE_OPEN_WRITE()
    Case 402
        UX_FILE_OPEN_APPEND()
    Case 403
        UX_FILE_OPEN_BINARY_READ()
    Case 404
        UX_FILE_OPEN_BINARY_WRITE()
    Case 405
        UX_FILE_CLOSE()
    Case 406
        UX_FILE_READ_BYTE()
    Case 407
        UX_FILE_WRITE_BYTE()
    Case 408
        UX_FILE_READ_LINE()
    Case 409
        UX_FILE_WRITE_LINE()
    Case 410
        UX_FILE_READ_BLOCK()
    Case 411
        UX_FILE_WRITE_BLOCK()
    Case 412
        UX_FILE_SEEK()
    Case 413
        UX_FILE_TELL()
    Case 414
        UX_FILE_EOF()
    Case 415
        UX_FILE_STATUS()
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
