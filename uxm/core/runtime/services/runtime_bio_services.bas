#ifndef UXM_RUNTIME_BIO_SERVICES_BAS
#define UXM_RUNTIME_BIO_SERVICES_BAS

Const STATUS_BIO_BOUNDS_UXM As UByte = 29
Const STATUS_BIO_INVALID_BASE_UXM As UByte = 30
Const STATUS_BIO_INVALID_CODON_UXM As UByte = 31

Dim Shared ux_bio_last_status As UByte = STATUS_OK

Sub BioSetStatus(ByVal code As UByte)
    ux_bio_last_status = code
    SetStatus code
End Sub

Function BioReadArgRel(ByVal rel As LongInt) As LongInt
    Return CLngInt(ReadTape(CLngInt(ux_ptr) + rel))
End Function

Sub BioWriteResultRel(ByVal rel As LongInt, ByVal value As ULongInt)
    WriteTape CLngInt(ux_ptr) + rel, value And CellMask()
End Sub

Function BioCheckDataRange(ByVal startIdx As LongInt, ByVal countVal As LongInt) As Long
    If startIdx < 0 Then Return 0
    If countVal < 0 Then Return 0
    If startIdx > CLngInt(ux_data_cells) Then Return 0
    If startIdx + countVal > CLngInt(ux_data_cells) Then Return 0
    Return -1
End Function

Function BioCell8(ByVal dataIdx As LongInt) As ULongInt
    Return ReadData(dataIdx) And &HFF
End Function

Sub BioPutCell8(ByVal dataIdx As LongInt, ByVal value As ULongInt)
    WriteData dataIdx, value And &HFF
End Sub

Function BioBaseCode(ByVal ch As ULongInt) As LongInt
    ch = ch And &HFF
    Select Case ch
    Case Asc("A"), Asc("a")
        Return 0
    Case Asc("C"), Asc("c")
        Return 1
    Case Asc("G"), Asc("g")
        Return 2
    Case Asc("T"), Asc("t"), Asc("U"), Asc("u")
        Return 3
    Case Else
        Return -1
    End Select
End Function

Function BioBaseFromCode(ByVal codeVal As LongInt) As ULongInt
    Select Case codeVal And 3
    Case 0
        Return Asc("A")
    Case 1
        Return Asc("C")
    Case 2
        Return Asc("G")
    Case Else
        Return Asc("T")
    End Select
End Function

Function BioCodonIdFromChars(ByVal b1 As ULongInt, ByVal b2 As ULongInt, ByVal b3 As ULongInt) As LongInt
    Dim c1 As LongInt, c2 As LongInt, c3 As LongInt
    c1 = BioBaseCode(b1)
    c2 = BioBaseCode(b2)
    c3 = BioBaseCode(b3)
    If c1 < 0 Or c2 < 0 Or c3 < 0 Then Return -1
    Return c1 * 16 + c2 * 4 + c3
End Function

Function BioAaFromCodonId(ByVal codonId As LongInt) As ULongInt
    If codonId < 0 Or codonId > 63 Then Return Asc("?")
    Dim b1 As LongInt, b2 As LongInt, b3 As LongInt
    b1 = (codonId \ 16) And 3
    b2 = (codonId \ 4) And 3
    b3 = codonId And 3

    ' Base order: A=0, C=1, G=2, T/U=3. Standard genetic code, DNA T accepted.
    Select Case b1
    Case 0 ' Axx
        Select Case b2
        Case 0 ' AAU/AAC Asn, AAA/AAG Lys
            If b3 < 2 Then Return Asc("N") Else Return Asc("K")
        Case 1 ' ACx Thr
            Return Asc("T")
        Case 2 ' AGU/AGC Ser, AGA/AGG Arg
            If b3 < 2 Then Return Asc("S") Else Return Asc("R")
        Case 3 ' AUU/AUC/AUA Ile, AUG Met
            If b3 = 3 Then Return Asc("M") Else Return Asc("I")
        End Select
    Case 1 ' Cxx
        Select Case b2
        Case 0 ' CAU/CAC His, CAA/CAG Gln
            If b3 < 2 Then Return Asc("H") Else Return Asc("Q")
        Case 1 ' CCx Pro
            Return Asc("P")
        Case 2 ' CGx Arg
            Return Asc("R")
        Case 3 ' CUx Leu
            Return Asc("L")
        End Select
    Case 2 ' Gxx
        Select Case b2
        Case 0 ' GAU/GAC Asp, GAA/GAG Glu
            If b3 < 2 Then Return Asc("D") Else Return Asc("E")
        Case 1 ' GCx Ala
            Return Asc("A")
        Case 2 ' GGx Gly
            Return Asc("G")
        Case 3 ' GUx Val
            Return Asc("V")
        End Select
    Case 3 ' T/Uxx
        Select Case b2
        Case 0 ' UAU/UAC Tyr, UAA/UAG Stop
            If b3 < 2 Then Return Asc("Y") Else Return Asc("*")
        Case 1 ' UCx Ser
            Return Asc("S")
        Case 2 ' UGU/UGC Cys, UGA Stop, UGG Trp
            If b3 < 2 Then Return Asc("C")
            If b3 = 2 Then Return Asc("*")
            Return Asc("W")
        Case 3 ' UUU/UUC Phe, UUA/UUG Leu
            If b3 < 2 Then Return Asc("F") Else Return Asc("L")
        End Select
    End Select
    Return Asc("?")
End Function

Function BioFindTextIndex(ByVal src As LongInt, ByVal srcLen As LongInt, ByVal motif As LongInt, ByVal motifLen As LongInt) As LongInt
    Dim i As LongInt, j As LongInt, sameFlag As Long
    If motifLen <= 0 Then Return 0
    If srcLen < motifLen Then Return -1
    If BioCheckDataRange(src, srcLen)=0 Or BioCheckDataRange(motif, motifLen)=0 Then Return -2
    For i = 0 To srcLen - motifLen
        sameFlag = -1
        For j = 0 To motifLen - 1
            If BioCell8(src+i+j) <> BioCell8(motif+j) Then
                sameFlag = 0
                Exit For
            End If
        Next j
        If sameFlag <> 0 Then Return i
    Next i
    Return -1
End Function

Sub UX_BIO_BASE_ENCODE()
    Dim codeVal As LongInt
    codeVal = BioBaseCode(BioReadArgRel(-1))
    If codeVal < 0 Then
        BioWriteResultRel 1, 255
        BioSetStatus STATUS_BIO_INVALID_BASE_UXM
    Else
        BioWriteResultRel 1, CULngInt(codeVal)
        BioSetStatus STATUS_OK
    End If
End Sub

Sub UX_BIO_CODON_ENCODE()
    Dim codonId As LongInt
    codonId = BioCodonIdFromChars(BioReadArgRel(-3), BioReadArgRel(-2), BioReadArgRel(-1))
    If codonId < 0 Then
        BioWriteResultRel 1, 255
        BioSetStatus STATUS_BIO_INVALID_BASE_UXM
    Else
        BioWriteResultRel 1, CULngInt(codonId)
        BioSetStatus STATUS_OK
    End If
End Sub

Sub UX_BIO_CODON_TO_AA()
    Dim codonId As LongInt, aa As ULongInt
    codonId = BioReadArgRel(-1)
    If codonId < 0 Or codonId > 63 Then
        BioWriteResultRel 1, Asc("?")
        BioSetStatus STATUS_BIO_INVALID_CODON_UXM
    Else
        aa = BioAaFromCodonId(codonId)
        BioWriteResultRel 1, aa
        BioSetStatus STATUS_OK
    End If
End Sub

Sub UX_BIO_TRANSLATE()
    Dim src As LongInt, srcLen As LongInt, dst As LongInt, dstMax As LongInt
    Dim i As LongInt, outLen As LongInt, codonId As LongInt, errFlag As Long, aa As ULongInt
    src = BioReadArgRel(-4)
    srcLen = BioReadArgRel(-3)
    dst = BioReadArgRel(-2)
    dstMax = BioReadArgRel(-1)
    If dstMax < 0 Or BioCheckDataRange(src, srcLen)=0 Or BioCheckDataRange(dst, dstMax)=0 Then
        BioWriteResultRel 1, 0
        BioSetStatus STATUS_BIO_BOUNDS_UXM
        Exit Sub
    End If
    outLen = 0
    errFlag = 0
    i = 0
    While i + 2 < srcLen And outLen < dstMax
        codonId = BioCodonIdFromChars(BioCell8(src+i), BioCell8(src+i+1), BioCell8(src+i+2))
        If codonId < 0 Then
            errFlag = -1
            BioSetStatus STATUS_BIO_INVALID_BASE_UXM
            Exit While
        End If
        aa = BioAaFromCodonId(codonId)
        BioPutCell8 dst + outLen, aa
        outLen = outLen + 1
        i = i + 3
    Wend
    If outLen < dstMax Then BioPutCell8 dst + outLen, 0
    BioWriteResultRel 1, CULngInt(outLen)
    If errFlag = 0 Then BioSetStatus STATUS_OK
End Sub

Sub UX_BIO_GC_CONTENT()
    Dim src As LongInt, srcLen As LongInt, i As LongInt, validCount As LongInt, gcCount As LongInt, bcode As LongInt
    src = BioReadArgRel(-2)
    srcLen = BioReadArgRel(-1)
    If BioCheckDataRange(src, srcLen)=0 Then
        BioWriteResultRel 1, 0
        BioSetStatus STATUS_BIO_BOUNDS_UXM
        Exit Sub
    End If
    validCount = 0
    gcCount = 0
    For i = 0 To srcLen - 1
        bcode = BioBaseCode(BioCell8(src+i))
        If bcode >= 0 Then
            validCount = validCount + 1
            If bcode = 1 Or bcode = 2 Then gcCount = gcCount + 1
        End If
    Next i
    If validCount = 0 Then
        BioWriteResultRel 1, 0
    Else
        BioWriteResultRel 1, CULngInt((gcCount * 100) \ validCount)
    End If
    BioSetStatus STATUS_OK
End Sub

Sub UX_BIO_ORF_FIND()
    Dim src As LongInt, srcLen As LongInt, i As LongInt, codonId As LongInt
    src = BioReadArgRel(-2)
    srcLen = BioReadArgRel(-1)
    If BioCheckDataRange(src, srcLen)=0 Then
        BioWriteResultRel 1, CellMask()
        BioSetStatus STATUS_BIO_BOUNDS_UXM
        Exit Sub
    End If
    i = 0
    While i + 2 < srcLen
        codonId = BioCodonIdFromChars(BioCell8(src+i), BioCell8(src+i+1), BioCell8(src+i+2))
        If codonId = 14 Then
            BioWriteResultRel 1, CULngInt(i)
            BioSetStatus STATUS_OK
            Exit Sub
        End If
        i = i + 1
    Wend
    BioWriteResultRel 1, CellMask()
    BioSetStatus STATUS_OK
End Sub

Sub UX_BIO_AA_COUNT()
    Dim src As LongInt, srcLen As LongInt, targetAa As ULongInt, i As LongInt, cnt As LongInt
    src = BioReadArgRel(-3)
    srcLen = BioReadArgRel(-2)
    targetAa = CULngInt(BioReadArgRel(-1)) And &HFF
    If BioCheckDataRange(src, srcLen)=0 Then
        BioWriteResultRel 1, 0
        BioSetStatus STATUS_BIO_BOUNDS_UXM
        Exit Sub
    End If
    cnt = 0
    For i = 0 To srcLen - 1
        If BioCell8(src+i) = targetAa Then cnt = cnt + 1
    Next i
    BioWriteResultRel 1, CULngInt(cnt)
    BioSetStatus STATUS_OK
End Sub

Sub UX_BIO_MOTIF_FIND()
    Dim r As LongInt
    r = BioFindTextIndex(BioReadArgRel(-4), BioReadArgRel(-3), BioReadArgRel(-2), BioReadArgRel(-1))
    If r < 0 Then
        BioWriteResultRel 1, CellMask()
        If r = -2 Then BioSetStatus STATUS_BIO_BOUNDS_UXM Else BioSetStatus STATUS_OK
    Else
        BioWriteResultRel 1, CULngInt(r)
        BioSetStatus STATUS_OK
    End If
End Sub

Sub UX_BIO_STATUS()
    BioWriteResultRel 1, ux_bio_last_status
    SetStatus STATUS_OK
End Sub

Sub MetaBio(ByVal metaId As ULongInt)
    Select Case metaId
    Case 480
        UX_BIO_BASE_ENCODE()
    Case 481
        UX_BIO_CODON_ENCODE()
    Case 482
        UX_BIO_CODON_TO_AA()
    Case 483
        UX_BIO_TRANSLATE()
    Case 484
        UX_BIO_GC_CONTENT()
    Case 485
        UX_BIO_ORF_FIND()
    Case 486
        UX_BIO_AA_COUNT()
    Case 487
        UX_BIO_MOTIF_FIND()
    Case 511
        UX_BIO_STATUS()
    Case Else
        SetStatus STATUS_INVALID_META
    End Select
End Sub

#endif
