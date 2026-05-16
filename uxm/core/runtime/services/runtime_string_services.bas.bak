#ifndef UXM_RUNTIME_STRING_SERVICES_BAS
#define UXM_RUNTIME_STRING_SERVICES_BAS

Const STATUS_STRING_BOUNDS_UXM As UByte = 19
Const STATUS_META_ARG_ERROR_UXM As UByte = 24
Const STATUS_PATTERN_MISS_UXM As UByte = 28

Dim Shared ux_str_last_status As UByte = STATUS_OK

Sub StrSetStatus(ByVal code As UByte)
    ux_str_last_status = code
    SetStatus code
End Sub

Function StrCheckRange(ByVal startIdx As LongInt, ByVal count As LongInt) As Long
    If startIdx < 0 Then Return 0
    If count < 0 Then Return 0
    If startIdx > CLngInt(ux_data_cells) Then Return 0
    If startIdx + count > CLngInt(ux_data_cells) Then Return 0
    Return -1
End Function

Function StrReadArgRel(ByVal rel As LongInt) As LongInt
    Return CLngInt(ReadTape(CLngInt(ux_ptr) + rel))
End Function

Sub StrWriteResultRel(ByVal rel As LongInt, ByVal value As ULongInt)
    WriteTape CLngInt(ux_ptr) + rel, value And CellMask()
End Sub

Function StrCell8(ByVal idx As LongInt) As ULongInt
    Return ReadData(idx) And &HFF
End Function

Sub StrPutCell8(ByVal idx As LongInt, ByVal value As ULongInt)
    WriteData idx, value And &HFF
End Sub

Function StrSignedResult(ByVal v As LongInt) As ULongInt
    If v < 0 Then
        Return CellMask()
    End If
    Return CULngInt(v) And CellMask()
End Function

Function StrAsciiUpper(ByVal c As ULongInt) As ULongInt
    c = c And &HFF
    If c >= Asc("a") And c <= Asc("z") Then
        c = c - 32
    End If
    Return c
End Function

Function StrAsciiLower(ByVal c As ULongInt) As ULongInt
    c = c And &HFF
    If c >= Asc("A") And c <= Asc("Z") Then
        c = c + 32
    End If
    Return c
End Function

Function StrIsSpace(ByVal c As ULongInt) As Long
    c = c And &HFF
    If c = 32 Or c = 9 Or c = 10 Or c = 13 Then
        Return -1
    End If
    Return 0
End Function

Sub UX_STR_LEN_Z()
    Dim startIdx As LongInt
    Dim i As LongInt
    Dim n As LongInt
    startIdx = StrReadArgRel(-1)
    If startIdx < 0 Or startIdx >= CLngInt(ux_data_cells) Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    n = 0
    For i = startIdx To CLngInt(ux_data_cells) - 1
        If StrCell8(i) = 0 Then Exit For
        n = n + 1
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_COPY()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt
    Dim i As LongInt, n As LongInt
    src = StrReadArgRel(-4)
    ln = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    n = ln
    If n > dstMax Then n = dstMax
    If n < 0 Or StrCheckRange(src,n)=0 Or StrCheckRange(dst,n)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To n - 1
        StrPutCell8 dst+i, StrCell8(src+i)
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_CLEAR()
    Dim startIdx As LongInt, ln As LongInt, i As LongInt
    startIdx = StrReadArgRel(-2)
    ln = StrReadArgRel(-1)
    If StrCheckRange(startIdx,ln)=0 Then
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To ln - 1
        StrPutCell8 startIdx+i, 0
    Next i
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_FILL()
    Dim startIdx As LongInt, ln As LongInt, ch As ULongInt, i As LongInt
    startIdx = StrReadArgRel(-3)
    ln = StrReadArgRel(-2)
    ch = CULngInt(StrReadArgRel(-1)) And &HFF
    If StrCheckRange(startIdx,ln)=0 Then
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To ln - 1
        StrPutCell8 startIdx+i, ch
    Next i
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_COMPARE()
    Dim s1 As LongInt, l1 As LongInt, s2 As LongInt, l2 As LongInt
    Dim i As LongInt, mn As LongInt, r As LongInt
    Dim c1 As ULongInt, c2 As ULongInt
    s1 = StrReadArgRel(-4)
    l1 = StrReadArgRel(-3)
    s2 = StrReadArgRel(-2)
    l2 = StrReadArgRel(-1)
    If StrCheckRange(s1,l1)=0 Or StrCheckRange(s2,l2)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    mn = l1
    If l2 < mn Then mn = l2
    r = 0
    For i = 0 To mn - 1
        c1 = StrCell8(s1+i)
        c2 = StrCell8(s2+i)
        If c1 < c2 Then
            r = -1
            Exit For
        End If
        If c1 > c2 Then
            r = 1
            Exit For
        End If
    Next i
    If r = 0 Then
        If l1 < l2 Then r = -1
        If l1 > l2 Then r = 1
    End If
    StrWriteResultRel 1, StrSignedResult(r)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_EQUALS()
    Dim s1 As LongInt, l1 As LongInt, s2 As LongInt, l2 As LongInt
    Dim i As LongInt
    s1 = StrReadArgRel(-4)
    l1 = StrReadArgRel(-3)
    s2 = StrReadArgRel(-2)
    l2 = StrReadArgRel(-1)
    If l1 <> l2 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_OK
        Exit Sub
    End If
    If StrCheckRange(s1,l1)=0 Or StrCheckRange(s2,l2)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To l1 - 1
        If StrCell8(s1+i) <> StrCell8(s2+i) Then
            StrWriteResultRel 1, 0
            StrSetStatus STATUS_OK
            Exit Sub
        End If
    Next i
    StrWriteResultRel 1, 1
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_FIND_CHAR()
    Dim startIdx As LongInt, ln As LongInt, ch As ULongInt, i As LongInt
    startIdx = StrReadArgRel(-3)
    ln = StrReadArgRel(-2)
    ch = CULngInt(StrReadArgRel(-1)) And &HFF
    If StrCheckRange(startIdx,ln)=0 Then
        StrWriteResultRel 1, StrSignedResult(-1)
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To ln - 1
        If StrCell8(startIdx+i) = ch Then
            StrWriteResultRel 1, CULngInt(i)
            StrSetStatus STATUS_OK
            Exit Sub
        End If
    Next i
    StrWriteResultRel 1, StrSignedResult(-1)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_COUNT_CHAR()
    Dim startIdx As LongInt, ln As LongInt, ch As ULongInt, i As LongInt, cnt As LongInt
    startIdx = StrReadArgRel(-3)
    ln = StrReadArgRel(-2)
    ch = CULngInt(StrReadArgRel(-1)) And &HFF
    If StrCheckRange(startIdx,ln)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    cnt = 0
    For i = 0 To ln - 1
        If StrCell8(startIdx+i) = ch Then cnt = cnt + 1
    Next i
    StrWriteResultRel 1, CULngInt(cnt)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_TO_UPPER()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, n As LongInt
    src = StrReadArgRel(-4)
    ln = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    n = ln
    If n > dstMax Then n = dstMax
    If n < 0 Or StrCheckRange(src,n)=0 Or StrCheckRange(dst,n)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To n - 1
        StrPutCell8 dst+i, StrAsciiUpper(StrCell8(src+i))
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_TO_LOWER()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, n As LongInt
    src = StrReadArgRel(-4)
    ln = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    n = ln
    If n > dstMax Then n = dstMax
    If n < 0 Or StrCheckRange(src,n)=0 Or StrCheckRange(dst,n)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To n - 1
        StrPutCell8 dst+i, StrAsciiLower(StrCell8(src+i))
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_TRIM_SPACES()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt
    Dim a As LongInt, b As LongInt, n As LongInt, i As LongInt
    src = StrReadArgRel(-4)
    ln = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    a = 0
    While a < ln And StrIsSpace(StrCell8(src+a))
        a = a + 1
    Wend
    b = ln - 1
    While b >= a And StrIsSpace(StrCell8(src+b))
        b = b - 1
    Wend
    n = b - a + 1
    If n < 0 Then n = 0
    If n > dstMax Then n = dstMax
    If StrCheckRange(dst,n)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To n - 1
        StrPutCell8 dst+i, StrCell8(src+a+i)
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_CONCAT()
    Dim s1 As LongInt, l1 As LongInt, s2 As LongInt, l2 As LongInt, dst As LongInt, dstMax As LongInt
    Dim i As LongInt, outLen As LongInt
    s1 = StrReadArgRel(-6)
    l1 = StrReadArgRel(-5)
    s2 = StrReadArgRel(-4)
    l2 = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    If StrCheckRange(s1,l1)=0 Or StrCheckRange(s2,l2)=0 Or StrCheckRange(dst,dstMax)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    outLen = 0
    For i = 0 To l1 - 1
        If outLen >= dstMax Then Exit For
        StrPutCell8 dst+outLen, StrCell8(s1+i)
        outLen = outLen + 1
    Next i
    For i = 0 To l2 - 1
        If outLen >= dstMax Then Exit For
        StrPutCell8 dst+outLen, StrCell8(s2+i)
        outLen = outLen + 1
    Next i
    StrWriteResultRel 1, CULngInt(outLen)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_SUBSTR()
    Dim src As LongInt, srcLen As LongInt, startOff As LongInt, takeLen As LongInt, dst As LongInt, dstMax As LongInt
    Dim i As LongInt, n As LongInt
    src = StrReadArgRel(-6)
    srcLen = StrReadArgRel(-5)
    startOff = StrReadArgRel(-4)
    takeLen = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    If startOff < 0 Or takeLen < 0 Or startOff > srcLen Or StrCheckRange(src,srcLen)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    n = takeLen
    If startOff + n > srcLen Then n = srcLen - startOff
    If n > dstMax Then n = dstMax
    If StrCheckRange(dst,n)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To n - 1
        StrPutCell8 dst+i, StrCell8(src+startOff+i)
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_PRINT()
    Dim startIdx As LongInt
    startIdx = StrReadArgRel(-1)
    If startIdx < 0 Or startIdx >= CLngInt(ux_data_cells) Then
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    ux_print_data_string CULngInt(startIdx), ux_cell_bits
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_READ_CONSOLE()
    Dim dst As LongInt, dstMax As LongInt, s As String, i As LongInt, n As LongInt
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    If dstMax < 1 Or StrCheckRange(dst,dstMax)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    Line Input s
    n = Len(s)
    If n > dstMax - 1 Then n = dstMax - 1
    For i = 0 To n - 1
        StrPutCell8 dst+i, Asc(Mid(s,i+1,1))
    Next i
    StrPutCell8 dst+n, 0
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_FROM_INT()
    Dim value As ULongInt, dst As LongInt, dstMax As LongInt, s As String, i As LongInt, n As LongInt
    value = CULngInt(StrReadArgRel(-3))
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    If dstMax < 1 Or StrCheckRange(dst,dstMax)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    s = Str(value)
    s = LTrim(s)
    n = Len(s)
    If n > dstMax - 1 Then n = dstMax - 1
    For i = 0 To n - 1
        StrPutCell8 dst+i, Asc(Mid(s,i+1,1))
    Next i
    StrPutCell8 dst+n, 0
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_TO_INT()
    Dim src As LongInt, ln As LongInt, i As LongInt, sign As LongInt, v As LongInt, c As ULongInt
    src = StrReadArgRel(-2)
    ln = StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    sign = 1
    v = 0
    i = 0
    If ln > 0 And StrCell8(src) = Asc("-") Then
        sign = -1
        i = 1
    End If
    While i < ln
        c = StrCell8(src+i)
        If c < Asc("0") Or c > Asc("9") Then Exit While
        v = v * 10 + CLngInt(c - Asc("0"))
        i = i + 1
    Wend
    StrWriteResultRel 1, ClampToCell(v * sign)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_APPEND_CHAR()
    Dim dst As LongInt, dstMax As LongInt, ch As ULongInt, ln As LongInt
    dst = StrReadArgRel(-3)
    dstMax = StrReadArgRel(-2)
    ch = CULngInt(StrReadArgRel(-1)) And &HFF
    If dstMax < 2 Or StrCheckRange(dst,dstMax)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    ln = 0
    While ln < dstMax And StrCell8(dst+ln) <> 0
        ln = ln + 1
    Wend
    If ln >= dstMax - 1 Then
        StrWriteResultRel 1, CULngInt(ln)
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    StrPutCell8 dst+ln, ch
    StrPutCell8 dst+ln+1, 0
    StrWriteResultRel 1, CULngInt(ln+1)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_REVERSE()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, n As LongInt
    src = StrReadArgRel(-4)
    ln = StrReadArgRel(-3)
    dst = StrReadArgRel(-2)
    dstMax = StrReadArgRel(-1)
    n = ln
    If n > dstMax Then n = dstMax
    If n < 0 Or StrCheckRange(src,n)=0 Or StrCheckRange(dst,n)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    For i = 0 To n - 1
        StrPutCell8 dst+i, StrCell8(src+n-1-i)
    Next i
    StrWriteResultRel 1, CULngInt(n)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_STATUS()
    StrWriteResultRel 1, ux_str_last_status
    SetLogicFlags ux_str_last_status
    SetStatus STATUS_OK
End Sub

Sub MetaString(ByVal metaId As ULongInt)
    Select Case metaId
    Case 300
        UX_STR_LEN_Z()
    Case 301
        UX_STR_COPY()
    Case 302
        UX_STR_CLEAR()
    Case 303
        UX_STR_FILL()
    Case 304
        UX_STR_COMPARE()
    Case 305
        UX_STR_EQUALS()
    Case 306
        UX_STR_FIND_CHAR()
    Case 307
        UX_STR_COUNT_CHAR()
    Case 308
        UX_STR_TO_UPPER()
    Case 309
        UX_STR_TO_LOWER()
    Case 310
        UX_STR_TRIM_SPACES()
    Case 311
        UX_STR_CONCAT()
    Case 312
        UX_STR_SUBSTR()
    Case 313
        UX_STR_PRINT()
    Case 314
        UX_STR_READ_CONSOLE()
    Case 315
        UX_STR_FROM_INT()
    Case 316
        UX_STR_TO_INT()
    Case 317
        UX_STR_APPEND_CHAR()
    Case 318
        UX_STR_REVERSE()
    Case 319
        UX_STR_STATUS()
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
