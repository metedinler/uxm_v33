#ifndef UXM_RUNTIME_STRING_EXT_SERVICES_BAS
#define UXM_RUNTIME_STRING_EXT_SERVICES_BAS

Function StrFindTextIndex(ByVal src As LongInt, ByVal srcLen As LongInt, ByVal needle As LongInt, ByVal needleLen As LongInt) As LongInt
    Dim i As LongInt, j As LongInt, ok As Long
    If needleLen = 0 Then Return 0
    If srcLen < needleLen Then Return -1
    If StrCheckRange(src, srcLen)=0 Or StrCheckRange(needle, needleLen)=0 Then Return -2
    For i = 0 To srcLen - needleLen
        ok = -1
        For j = 0 To needleLen - 1
            If StrCell8(src+i+j) <> StrCell8(needle+j) Then
                ok = 0
                Exit For
            End If
        Next j
        If ok <> 0 Then Return i
    Next i
    Return -1
End Function

Function StrIsNumericRange(ByVal src As LongInt, ByVal ln As LongInt) As Long
    Dim i As LongInt, c As ULongInt, digitCount As LongInt
    If ln <= 0 Then Return 0
    If StrCheckRange(src,ln)=0 Then Return 0
    i = 0
    digitCount = 0
    If StrCell8(src)=Asc("-") Or StrCell8(src)=Asc("+") Then i = 1
    While i < ln
        c = StrCell8(src+i)
        If c < Asc("0") Or c > Asc("9") Then Return 0
        digitCount = digitCount + 1
        i = i + 1
    Wend
    If digitCount = 0 Then Return 0
    Return -1
End Function

Function StrHexNibble(ByVal c As ULongInt) As LongInt
    c = c And &HFF
    If c >= Asc("0") And c <= Asc("9") Then Return CLngInt(c - Asc("0"))
    If c >= Asc("A") And c <= Asc("F") Then Return CLngInt(c - Asc("A") + 10)
    If c >= Asc("a") And c <= Asc("f") Then Return CLngInt(c - Asc("a") + 10)
    Return -1
End Function

Function StrHexChar(ByVal n As ULongInt) As ULongInt
    n = n And &HF
    If n < 10 Then Return Asc("0") + n
    Return Asc("A") + (n - 10)
End Function

Function StrUrlSafe(ByVal c As ULongInt) As Long
    c = c And &HFF
    If c >= Asc("A") And c <= Asc("Z") Then Return -1
    If c >= Asc("a") And c <= Asc("z") Then Return -1
    If c >= Asc("0") And c <= Asc("9") Then Return -1
    If c = Asc("-") Or c = Asc("_") Or c = Asc(".") Or c = Asc("~") Then Return -1
    Return 0
End Function

Sub UX_STR_FIND_TEXT()
    Dim src As LongInt, srcLen As LongInt, needle As LongInt, needleLen As LongInt, r As LongInt
    src=StrReadArgRel(-4): srcLen=StrReadArgRel(-3): needle=StrReadArgRel(-2): needleLen=StrReadArgRel(-1)
    r = StrFindTextIndex(src,srcLen,needle,needleLen)
    If r = -2 Then
        StrWriteResultRel 1, StrSignedResult(-1)
        StrSetStatus STATUS_STRING_BOUNDS_UXM
    Else
        StrWriteResultRel 1, StrSignedResult(r)
        StrSetStatus STATUS_OK
    End If
End Sub

Sub UX_STR_COUNT_TEXT()
    Dim src As LongInt, srcLen As LongInt, needle As LongInt, needleLen As LongInt
    Dim scanIdx As LongInt, cnt As LongInt, i As LongInt, j As LongInt, ok As Long
    src=StrReadArgRel(-4): srcLen=StrReadArgRel(-3): needle=StrReadArgRel(-2): needleLen=StrReadArgRel(-1)
    If needleLen <= 0 Or StrCheckRange(src,srcLen)=0 Or StrCheckRange(needle,needleLen)=0 Then
        StrWriteResultRel 1, 0
        StrSetStatus STATUS_STRING_BOUNDS_UXM
        Exit Sub
    End If
    cnt=0
    If srcLen >= needleLen Then
        For i=0 To srcLen-needleLen
            ok=-1
            For j=0 To needleLen-1
                If StrCell8(src+i+j)<>StrCell8(needle+j) Then ok=0:Exit For
            Next j
            If ok<>0 Then cnt=cnt+1
        Next i
    End If
    StrWriteResultRel 1, CULngInt(cnt)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_REPLACE_CHAR()
    Dim src As LongInt, ln As LongInt, oldCh As ULongInt, newCh As ULongInt, dst As LongInt, dstMax As LongInt
    Dim i As LongInt, n As LongInt, cnt As LongInt, c As ULongInt
    src=StrReadArgRel(-6): ln=StrReadArgRel(-5): oldCh=CULngInt(StrReadArgRel(-4)) And &HFF
    newCh=CULngInt(StrReadArgRel(-3)) And &HFF: dst=StrReadArgRel(-2): dstMax=StrReadArgRel(-1)
    n=ln: If n>dstMax Then n=dstMax
    If n<0 Or StrCheckRange(src,n)=0 Or StrCheckRange(dst,n)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    cnt=0
    For i=0 To n-1
        c=StrCell8(src+i)
        If c=oldCh Then c=newCh:cnt=cnt+1
        StrPutCell8 dst+i,c
    Next i
    StrWriteResultRel 1,CULngInt(cnt)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_STARTS_WITH()
    Dim src As LongInt, srcLen As LongInt, pre As LongInt, preLen As LongInt, i As LongInt
    src=StrReadArgRel(-4): srcLen=StrReadArgRel(-3): pre=StrReadArgRel(-2): preLen=StrReadArgRel(-1)
    If preLen>srcLen Or StrCheckRange(src,srcLen)=0 Or StrCheckRange(pre,preLen)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_OK:Exit Sub
    For i=0 To preLen-1
        If StrCell8(src+i)<>StrCell8(pre+i) Then StrWriteResultRel 1,0:StrSetStatus STATUS_OK:Exit Sub
    Next i
    StrWriteResultRel 1,1:StrSetStatus STATUS_OK
End Sub

Sub UX_STR_ENDS_WITH()
    Dim src As LongInt, srcLen As LongInt, suf As LongInt, sufLen As LongInt, i As LongInt, off As LongInt
    src=StrReadArgRel(-4): srcLen=StrReadArgRel(-3): suf=StrReadArgRel(-2): sufLen=StrReadArgRel(-1)
    If sufLen>srcLen Or StrCheckRange(src,srcLen)=0 Or StrCheckRange(suf,sufLen)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_OK:Exit Sub
    off=srcLen-sufLen
    For i=0 To sufLen-1
        If StrCell8(src+off+i)<>StrCell8(suf+i) Then StrWriteResultRel 1,0:StrSetStatus STATUS_OK:Exit Sub
    Next i
    StrWriteResultRel 1,1:StrSetStatus STATUS_OK
End Sub

Sub UX_STR_CONTAINS()
    Dim r As LongInt
    r = StrFindTextIndex(StrReadArgRel(-4), StrReadArgRel(-3), StrReadArgRel(-2), StrReadArgRel(-1))
    If r >= 0 Then StrWriteResultRel 1,1 Else StrWriteResultRel 1,0
    If r = -2 Then StrSetStatus STATUS_STRING_BOUNDS_UXM Else StrSetStatus STATUS_OK
End Sub

Sub UX_STR_NORMALIZE_SPACES()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, outLen As LongInt, inSpace As Long
    Dim c As ULongInt
    src=StrReadArgRel(-4): ln=StrReadArgRel(-3): dst=StrReadArgRel(-2): dstMax=StrReadArgRel(-1)
    If dstMax<0 Or StrCheckRange(src,ln)=0 Or StrCheckRange(dst,dstMax)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    outLen=0:inSpace=0
    For i=0 To ln-1
        c=StrCell8(src+i)
        If StrIsSpace(c)<>0 Then
            If outLen>0 And inSpace=0 And outLen<dstMax Then StrPutCell8 dst+outLen,Asc(" "):outLen=outLen+1
            inSpace=-1
        Else
            If outLen<dstMax Then StrPutCell8 dst+outLen,c:outLen=outLen+1
            inSpace=0
        End If
    Next i
    If outLen>0 And StrCell8(dst+outLen-1)=Asc(" ") Then outLen=outLen-1
    StrWriteResultRel 1,CULngInt(outLen)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_IS_NUMERIC()
    If StrIsNumericRange(StrReadArgRel(-2), StrReadArgRel(-1))<>0 Then StrWriteResultRel 1,1 Else StrWriteResultRel 1,0
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_PARSE_DECIMAL()
    UX_STR_TO_INT()
End Sub

Sub UX_STR_FORMAT_INT()
    UX_STR_FROM_INT()
End Sub

Sub UX_STR_HASH8()
    Dim src As LongInt, ln As LongInt, i As LongInt, h As ULongInt
    src=StrReadArgRel(-2): ln=StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    h=0
    For i=0 To ln-1
        h=(h + StrCell8(src+i)) And &HFF
    Next i
    StrWriteResultRel 1,h
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_HASH32()
    Dim src As LongInt, ln As LongInt, i As LongInt, h As ULongInt
    src=StrReadArgRel(-2): ln=StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    h=CULngInt(&H811C9DC5)
    For i=0 To ln-1
        h = (h Xor (StrCell8(src+i) And &HFF)) * CULngInt(&H01000193)
    Next i
    StrWriteResultRel 1,h And CellMask()
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_HEX_ENCODE()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, outLen As LongInt, c As ULongInt
    src=StrReadArgRel(-4): ln=StrReadArgRel(-3): dst=StrReadArgRel(-2): dstMax=StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Or StrCheckRange(dst,dstMax)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    outLen=0
    For i=0 To ln-1
        If outLen+2>dstMax Then Exit For
        c=StrCell8(src+i)
        StrPutCell8 dst+outLen,StrHexChar(c\16):outLen=outLen+1
        StrPutCell8 dst+outLen,StrHexChar(c And &HF):outLen=outLen+1
    Next i
    StrWriteResultRel 1,CULngInt(outLen)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_HEX_DECODE()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, outLen As LongInt, hi As LongInt, lo As LongInt
    src=StrReadArgRel(-4): ln=StrReadArgRel(-3): dst=StrReadArgRel(-2): dstMax=StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Or StrCheckRange(dst,dstMax)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    outLen=0:i=0
    While i+1<ln And outLen<dstMax
        hi=StrHexNibble(StrCell8(src+i)):lo=StrHexNibble(StrCell8(src+i+1))
        If hi<0 Or lo<0 Then Exit While
        StrPutCell8 dst+outLen, CULngInt(hi*16+lo)
        outLen=outLen+1:i=i+2
    Wend
    StrWriteResultRel 1,CULngInt(outLen)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_URL_ENCODE()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, outLen As LongInt, c As ULongInt
    src=StrReadArgRel(-4): ln=StrReadArgRel(-3): dst=StrReadArgRel(-2): dstMax=StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Or StrCheckRange(dst,dstMax)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    outLen=0
    For i=0 To ln-1
        c=StrCell8(src+i)
        If StrUrlSafe(c)<>0 Then
            If outLen+1>dstMax Then Exit For
            StrPutCell8 dst+outLen,c:outLen=outLen+1
        Else
            If outLen+3>dstMax Then Exit For
            StrPutCell8 dst+outLen,Asc("%"):outLen=outLen+1
            StrPutCell8 dst+outLen,StrHexChar(c\16):outLen=outLen+1
            StrPutCell8 dst+outLen,StrHexChar(c And &HF):outLen=outLen+1
        End If
    Next i
    StrWriteResultRel 1,CULngInt(outLen)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_URL_DECODE()
    Dim src As LongInt, ln As LongInt, dst As LongInt, dstMax As LongInt, i As LongInt, outLen As LongInt, hi As LongInt, lo As LongInt, c As ULongInt
    src=StrReadArgRel(-4): ln=StrReadArgRel(-3): dst=StrReadArgRel(-2): dstMax=StrReadArgRel(-1)
    If StrCheckRange(src,ln)=0 Or StrCheckRange(dst,dstMax)=0 Then StrWriteResultRel 1,0:StrSetStatus STATUS_STRING_BOUNDS_UXM:Exit Sub
    outLen=0:i=0
    While i<ln And outLen<dstMax
        c=StrCell8(src+i)
        If c=Asc("%") And i+2<ln Then
            hi=StrHexNibble(StrCell8(src+i+1)):lo=StrHexNibble(StrCell8(src+i+2))
            If hi>=0 And lo>=0 Then
                StrPutCell8 dst+outLen,CULngInt(hi*16+lo):outLen=outLen+1:i=i+3
            Else
                StrPutCell8 dst+outLen,c:outLen=outLen+1:i=i+1
            End If
        ElseIf c=Asc("+") Then
            StrPutCell8 dst+outLen,Asc(" "):outLen=outLen+1:i=i+1
        Else
            StrPutCell8 dst+outLen,c:outLen=outLen+1:i=i+1
        End If
    Wend
    StrWriteResultRel 1,CULngInt(outLen)
    StrSetStatus STATUS_OK
End Sub

Sub UX_STR_TEXT_STATUS()
    UX_STR_STATUS()
End Sub

Sub MetaStringExt(ByVal metaId As ULongInt)
    Select Case metaId
    Case 340
        UX_STR_FIND_TEXT()
    Case 341
        UX_STR_COUNT_TEXT()
    Case 342
        UX_STR_REPLACE_CHAR()
    Case 346
        UX_STR_STARTS_WITH()
    Case 347
        UX_STR_ENDS_WITH()
    Case 348
        UX_STR_CONTAINS()
    Case 354
        UX_STR_NORMALIZE_SPACES()
    Case 355
        UX_STR_IS_NUMERIC()
    Case 356
        UX_STR_PARSE_DECIMAL()
    Case 357
        UX_STR_FORMAT_INT()
    Case 358
        UX_STR_HASH8()
    Case 359
        UX_STR_HASH32()
    Case 370
        UX_STR_HEX_ENCODE()
    Case 371
        UX_STR_HEX_DECODE()
    Case 372
        UX_STR_URL_ENCODE()
    Case 373
        UX_STR_URL_DECODE()
    Case 379
        UX_STR_TEXT_STATUS()
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
