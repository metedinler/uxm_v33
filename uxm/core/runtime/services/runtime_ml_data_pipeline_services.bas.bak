 ' UXM V3.3 Stage-15 + Stage-16 ML Basic + AI/Data Pipeline services
' Meta ranges:
'   @700..@719 ML Basic Runtime V1
'   @730..@759 AI/Data Pipeline V1
'
' No MetaMLDataPipeline declaration here: declaration belongs to uxm31_runtime_fb_full.bas.
'
' Dataset descriptor in data[]:
'   base+0  = 8701 magic
'   base+1  = rows
'   base+2  = cols
'   base+3  = x offset, currently 16
'   base+4  = y offset, x offset + rows*cols
'   base+5  = cursor
'   base+6  = status
'   base+16 + row*cols + col = X[row,col]
'   base+yOff + row = Y[row]

Const UX_DATASET_MAGIC As LongInt = 8701
Const UX_DATASET_X_OFFSET As LongInt = 16

Declare Function MLAbsLI(ByVal x As LongInt) As LongInt
Declare Function MLSafeLen2(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
Declare Function MLDotBias(ByVal xBase As LongInt, ByVal wBase As LongInt, ByVal biasVal As LongInt) As LongInt
Declare Function MLMse(ByVal predBase As LongInt, ByVal targetBase As LongInt) As LongInt
Declare Function MLMae(ByVal predBase As LongInt, ByVal targetBase As LongInt) As LongInt
Declare Function MLArgMax(ByVal vecBase As LongInt) As LongInt
Declare Function MLClamp(ByVal valueVal As LongInt, ByVal minVal As LongInt, ByVal maxVal As LongInt) As LongInt
Declare Sub MLPerceptronUpdate(ByVal wBase As LongInt, ByVal xBase As LongInt, ByVal targetVal As LongInt, ByVal predVal As LongInt, ByVal lrVal As LongInt, ByRef errVal As LongInt)
Declare Sub MLLinearGradStep(ByVal wBase As LongInt, ByVal xBase As LongInt, ByVal yVal As LongInt, ByVal predVal As LongInt, ByVal lrVal As LongInt, ByRef errVal As LongInt)

Declare Function DsIsValid(ByVal baseAddr As LongInt) As Long
Declare Function DsRows(ByVal baseAddr As LongInt) As LongInt
Declare Function DsCols(ByVal baseAddr As LongInt) As LongInt
Declare Function DsXOff(ByVal baseAddr As LongInt) As LongInt
Declare Function DsYOff(ByVal baseAddr As LongInt) As LongInt
Declare Function DsXIndex(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal cc As LongInt, ByRef ok As Long) As LongInt
Declare Function DsYIndex(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByRef ok As Long) As LongInt
Declare Sub DsInit(ByVal baseAddr As LongInt, ByVal rowsVal As LongInt, ByVal colsVal As LongInt)
Declare Sub DsSetX(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal cc As LongInt, ByVal valueVal As LongInt)
Declare Function DsGetX(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal cc As LongInt) As LongInt
Declare Sub DsSetY(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal valueVal As LongInt)
Declare Function DsGetY(ByVal baseAddr As LongInt, ByVal rr As LongInt) As LongInt
Declare Sub DsRowToVec(ByVal dstVec As LongInt, ByVal dsBase As LongInt, ByVal rr As LongInt)
Declare Function DsRowDotVec(ByVal dsBase As LongInt, ByVal rr As LongInt, ByVal vecBase As LongInt, ByVal biasVal As LongInt) As LongInt
Declare Function DsColSum(ByVal dsBase As LongInt, ByVal cc As LongInt) As LongInt
Declare Function DsYSum(ByVal dsBase As LongInt) As LongInt
Declare Function DsBatchYSum(ByVal dsBase As LongInt, ByVal startRow As LongInt, ByVal countVal As LongInt) As LongInt
Declare Function DsFeatureTotal(ByVal dsBase As LongInt) As LongInt
Declare Sub DsScaleFeatures(ByVal dsBase As LongInt, ByVal scalarVal As LongInt)
Declare Sub DsToDenseMatrix(ByVal matBase As LongInt, ByVal dsBase As LongInt)
Declare Function DsEvalLinearMSE(ByVal dsBase As LongInt, ByVal wBase As LongInt, ByVal biasVal As LongInt) As LongInt
Declare Function PipeLinearPredictData(ByVal dataStart As LongInt, ByVal n As LongInt, ByVal wBase As LongInt, ByVal biasVal As LongInt) As LongInt

Function MLAbsLI(ByVal x As LongInt) As LongInt
    If x<0 Then Return -x
    Return x
End Function

Function MLSafeLen2(ByVal aBase As LongInt, ByVal bBase As LongInt) As LongInt
    If VecIsValid(aBase)=0 Or VecIsValid(bBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return -1
    End If
    If VecLen(aBase)<>VecLen(bBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Return -1
    End If
    Return VecLen(aBase)
End Function

Function MLDotBias(ByVal xBase As LongInt, ByVal wBase As LongInt, ByVal biasVal As LongInt) As LongInt
    Dim n As LongInt
    n=MLSafeLen2(xBase,wBase)
    If n<0 Then Return 0
    SetStatus STATUS_OK
    Return VecDot(xBase,wBase)+biasVal
End Function

Function MLMse(ByVal predBase As LongInt, ByVal targetBase As LongInt) As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim d As LongInt
    Dim s As LongInt
    n=MLSafeLen2(predBase,targetBase)
    If n<=0 Then Return 0
    s=0
    For i=0 To n-1
        d=VecGet(predBase,i)-VecGet(targetBase,i)
        s=s+d*d
    Next i
    SetStatus STATUS_OK
    Return s \ n
End Function

Function MLMae(ByVal predBase As LongInt, ByVal targetBase As LongInt) As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim d As LongInt
    Dim s As LongInt
    n=MLSafeLen2(predBase,targetBase)
    If n<=0 Then Return 0
    s=0
    For i=0 To n-1
        d=VecGet(predBase,i)-VecGet(targetBase,i)
        s=s+MLAbsLI(d)
    Next i
    SetStatus STATUS_OK
    Return s \ n
End Function

Function MLArgMax(ByVal vecBase As LongInt) As LongInt
    Dim n As LongInt
    Dim i As LongInt
    Dim bestIdx As LongInt
    Dim bestVal As LongInt
    If VecIsValid(vecBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    n=VecLen(vecBase)
    If n<=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    bestIdx=0
    bestVal=VecGet(vecBase,0)
    For i=1 To n-1
        If VecGet(vecBase,i)>bestVal Then
            bestVal=VecGet(vecBase,i)
            bestIdx=i
        End If
    Next i
    SetStatus STATUS_OK
    Return bestIdx
End Function

Function MLClamp(ByVal valueVal As LongInt, ByVal minVal As LongInt, ByVal maxVal As LongInt) As LongInt
    If valueVal<minVal Then Return minVal
    If valueVal>maxVal Then Return maxVal
    Return valueVal
End Function

Sub MLPerceptronUpdate(ByVal wBase As LongInt, ByVal xBase As LongInt, ByVal targetVal As LongInt, ByVal predVal As LongInt, ByVal lrVal As LongInt, ByRef errVal As LongInt)
    Dim n As LongInt
    Dim i As LongInt
    Dim newVal As LongInt
    n=MLSafeLen2(wBase,xBase)
    If n<0 Then
        errVal=0
        Exit Sub
    End If
    errVal=targetVal-predVal
    For i=0 To n-1
        newVal=VecGet(wBase,i)+lrVal*errVal*VecGet(xBase,i)
        VecSet wBase,i,newVal
    Next i
    SetStatus STATUS_OK
End Sub

Sub MLLinearGradStep(ByVal wBase As LongInt, ByVal xBase As LongInt, ByVal yVal As LongInt, ByVal predVal As LongInt, ByVal lrVal As LongInt, ByRef errVal As LongInt)
    Dim n As LongInt
    Dim i As LongInt
    Dim newVal As LongInt
    n=MLSafeLen2(wBase,xBase)
    If n<0 Then
        errVal=0
        Exit Sub
    End If
    errVal=yVal-predVal
    For i=0 To n-1
        newVal=VecGet(wBase,i)+lrVal*errVal*VecGet(xBase,i)
        VecSet wBase,i,newVal
    Next i
    SetStatus STATUS_OK
End Sub

Function DsIsValid(ByVal baseAddr As LongInt) As Long
    If baseAddr<0 Or baseAddr+UX_DATASET_X_OFFSET>=CLngInt(ux_data_cells) Then Return 0
    If ReadData(baseAddr)<>UX_DATASET_MAGIC Then Return 0
    Return -1
End Function

Function DsRows(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+1))
End Function

Function DsCols(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+2))
End Function

Function DsXOff(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+3))
End Function

Function DsYOff(ByVal baseAddr As LongInt) As LongInt
    Return CLngInt(ReadData(baseAddr+4))
End Function

Function DsXIndex(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal cc As LongInt, ByRef ok As Long) As LongInt
    Dim rowsVal As LongInt
    Dim colsVal As LongInt
    Dim p As LongInt
    ok=0
    If DsIsValid(baseAddr)=0 Then Return 0
    rowsVal=DsRows(baseAddr)
    colsVal=DsCols(baseAddr)
    If rr<0 Or rr>=rowsVal Or cc<0 Or cc>=colsVal Then Return 0
    p=baseAddr+DsXOff(baseAddr)+rr*colsVal+cc
    If p<0 Or p>=CLngInt(ux_data_cells) Then Return 0
    ok=-1
    Return p
End Function

Function DsYIndex(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByRef ok As Long) As LongInt
    Dim rowsVal As LongInt
    Dim p As LongInt
    ok=0
    If DsIsValid(baseAddr)=0 Then Return 0
    rowsVal=DsRows(baseAddr)
    If rr<0 Or rr>=rowsVal Then Return 0
    p=baseAddr+DsYOff(baseAddr)+rr
    If p<0 Or p>=CLngInt(ux_data_cells) Then Return 0
    ok=-1
    Return p
End Function

Sub DsInit(ByVal baseAddr As LongInt, ByVal rowsVal As LongInt, ByVal colsVal As LongInt)
    Dim i As LongInt
    Dim total As LongInt
    Dim yOff As LongInt
    If rowsVal<0 Or colsVal<0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    yOff=UX_DATASET_X_OFFSET+rowsVal*colsVal
    total=yOff+rowsVal
    If baseAddr<0 Or baseAddr+total>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData baseAddr, UX_DATASET_MAGIC
    WriteData baseAddr+1, rowsVal
    WriteData baseAddr+2, colsVal
    WriteData baseAddr+3, UX_DATASET_X_OFFSET
    WriteData baseAddr+4, yOff
    WriteData baseAddr+5, 0
    WriteData baseAddr+6, STATUS_OK
    For i=0 To total-1
        WriteData baseAddr+UX_DATASET_X_OFFSET+i, 0
    Next i
    SetStatus STATUS_OK
End Sub

Sub DsSetX(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal cc As LongInt, ByVal valueVal As LongInt)
    Dim ok As Long
    Dim p As LongInt
    p=DsXIndex(baseAddr,rr,cc,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData p,valueVal
    SetStatus STATUS_OK
End Sub

Function DsGetX(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal cc As LongInt) As LongInt
    Dim ok As Long
    Dim p As LongInt
    p=DsXIndex(baseAddr,rr,cc,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    Return CLngInt(ReadData(p))
End Function

Sub DsSetY(ByVal baseAddr As LongInt, ByVal rr As LongInt, ByVal valueVal As LongInt)
    Dim ok As Long
    Dim p As LongInt
    p=DsYIndex(baseAddr,rr,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    WriteData p,valueVal
    SetStatus STATUS_OK
End Sub

Function DsGetY(ByVal baseAddr As LongInt, ByVal rr As LongInt) As LongInt
    Dim ok As Long
    Dim p As LongInt
    p=DsYIndex(baseAddr,rr,ok)
    If ok=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    SetStatus STATUS_OK
    Return CLngInt(ReadData(p))
End Function

Sub DsRowToVec(ByVal dstVec As LongInt, ByVal dsBase As LongInt, ByVal rr As LongInt)
    Dim colsVal As LongInt
    Dim c As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    colsVal=DsCols(dsBase)
    VecInit dstVec,colsVal
    For c=0 To colsVal-1
        VecSet dstVec,c,DsGetX(dsBase,rr,c)
    Next c
    SetStatus STATUS_OK
End Sub

Function DsRowDotVec(ByVal dsBase As LongInt, ByVal rr As LongInt, ByVal vecBase As LongInt, ByVal biasVal As LongInt) As LongInt
    Dim c As LongInt
    Dim s As LongInt
    If DsIsValid(dsBase)=0 Or VecIsValid(vecBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If rr<0 Or rr>=DsRows(dsBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If DsCols(dsBase)<>VecLen(vecBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=biasVal
    For c=0 To DsCols(dsBase)-1
        s=s+DsGetX(dsBase,rr,c)*VecGet(vecBase,c)
    Next c
    SetStatus STATUS_OK
    Return s
End Function

Function DsColSum(ByVal dsBase As LongInt, ByVal cc As LongInt) As LongInt
    Dim r As LongInt
    Dim s As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To DsRows(dsBase)-1
        s=s+DsGetX(dsBase,r,cc)
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Function DsYSum(ByVal dsBase As LongInt) As LongInt
    Dim r As LongInt
    Dim s As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To DsRows(dsBase)-1
        s=s+DsGetY(dsBase,r)
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Function DsBatchYSum(ByVal dsBase As LongInt, ByVal startRow As LongInt, ByVal countVal As LongInt) As LongInt
    Dim r As LongInt
    Dim lastRow As LongInt
    Dim s As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If startRow<0 Or countVal<0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    lastRow=startRow+countVal-1
    If lastRow>=DsRows(dsBase) Then lastRow=DsRows(dsBase)-1
    s=0
    For r=startRow To lastRow
        s=s+DsGetY(dsBase,r)
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Function DsFeatureTotal(ByVal dsBase As LongInt) As LongInt
    Dim r As LongInt
    Dim c As LongInt
    Dim s As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To DsRows(dsBase)-1
        For c=0 To DsCols(dsBase)-1
            s=s+DsGetX(dsBase,r,c)
        Next c
    Next r
    SetStatus STATUS_OK
    Return s
End Function

Sub DsScaleFeatures(ByVal dsBase As LongInt, ByVal scalarVal As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    Dim v As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    For r=0 To DsRows(dsBase)-1
        For c=0 To DsCols(dsBase)-1
            v=DsGetX(dsBase,r,c)*scalarVal
            DsSetX dsBase,r,c,v
        Next c
    Next r
    SetStatus STATUS_OK
End Sub

Sub DsToDenseMatrix(ByVal matBase As LongInt, ByVal dsBase As LongInt)
    Dim r As LongInt
    Dim c As LongInt
    If DsIsValid(dsBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Exit Sub
    End If
    MatInit matBase,DsRows(dsBase),DsCols(dsBase),0,0
    For r=0 To DsRows(dsBase)-1
        For c=0 To DsCols(dsBase)-1
            MatSet matBase,r,c,DsGetX(dsBase,r,c)
        Next c
    Next r
    SetStatus STATUS_OK
End Sub

Function DsEvalLinearMSE(ByVal dsBase As LongInt, ByVal wBase As LongInt, ByVal biasVal As LongInt) As LongInt
    Dim r As LongInt
    Dim p As LongInt
    Dim y As LongInt
    Dim d As LongInt
    Dim s As LongInt
    If DsIsValid(dsBase)=0 Or VecIsValid(wBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If DsCols(dsBase)<>VecLen(wBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=0
    For r=0 To DsRows(dsBase)-1
        p=DsRowDotVec(dsBase,r,wBase,biasVal)
        y=DsGetY(dsBase,r)
        d=p-y
        s=s+d*d
    Next r
    If DsRows(dsBase)>0 Then s=s \ DsRows(dsBase)
    SetStatus STATUS_OK
    Return s
End Function

Function PipeLinearPredictData(ByVal dataStart As LongInt, ByVal n As LongInt, ByVal wBase As LongInt, ByVal biasVal As LongInt) As LongInt
    Dim i As LongInt
    Dim s As LongInt
    If VecIsValid(wBase)=0 Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If n<>VecLen(wBase) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    If dataStart<0 Or dataStart+n>=CLngInt(ux_data_cells) Then
        SetStatus STATUS_DATA_BOUNDS
        Return 0
    End If
    s=biasVal
    For i=0 To n-1
        s=s+CLngInt(ReadData(dataStart+i))*VecGet(wBase,i)
    Next i
    SetStatus STATUS_OK
    Return s
End Function

Sub MetaMLDataPipeline(ByVal metaId As ULongInt)
    Dim dst As LongInt
    Dim a As LongInt
    Dim b As LongInt
    Dim p1 As LongInt
    Dim p2 As LongInt
    Dim r As LongInt
    Dim n As LongInt
    dst=CLngInt(ReadTape(CLngInt(ux_ptr)-4))
    a=CLngInt(ReadTape(CLngInt(ux_ptr)-3))
    b=CLngInt(ReadTape(CLngInt(ux_ptr)-2))
    p1=CLngInt(ReadTape(CLngInt(ux_ptr)-1))
    p2=CLngInt(ReadTape(CLngInt(ux_ptr)))

    Select Case metaId
    Case 700
        If dst<0 Then r=0 Else r=dst
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 701
        If dst>=0 Then r=1 Else r=0
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 702
        If dst>=0 Then
            r=500+(dst*500) \ (dst+10)
        Else
            r=500-(MLAbsLI(dst)*500) \ (MLAbsLI(dst)+10)
        End If
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 703
        r=MLDotBias(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 704
        r=MLDotBias(dst,a,b)
        If r>=0 Then r=1 Else r=0
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 705
        r=MLMse(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 706
        r=MLMae(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 707
        r=MLArgMax(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 708
        MLPerceptronUpdate dst,a,b,p1,p2,r
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 709
        MLLinearGradStep dst,a,b,p1,p2,r
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 710
        r=MLClamp(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 719
        SetResult 151619
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 730
        DsInit dst,a,b
        SetResult ux_status
    Case 731
        DsSetX dst,a,b,p1
        SetResult ux_status
    Case 732
        r=DsGetX(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 733
        DsSetY dst,a,b
        SetResult ux_status
    Case 734
        r=DsGetY(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 735
        DsRowToVec dst,a,b
        SetResult ux_status
    Case 736
        r=DsRowDotVec(dst,a,b,p1)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 737
        r=DsColSum(dst,a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 738
        r=DsYSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 739
        SetResult 161739
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 740
        VecFromData dst,a,b
        r=VecSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 741
        VecToData dst,a
        r=VecSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 742
        r=PipeLinearPredictData(dst,a,b,p1)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 743
        r=DsEvalLinearMSE(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 744
        r=DsBatchYSum(dst,a,b)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 745
        DsRowToVec dst,a,b
        r=VecSum(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 746
        DsScaleFeatures dst,a
        r=DsFeatureTotal(dst)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 747
        DsToDenseMatrix dst,a
        r=0
        If ux_status=STATUS_OK Then r=DsFeatureTotal(a)
        SetResult ClampToCell(r)
        SetLogicFlags ResultValue()
    Case 748
        SetResult ux_status
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case 759
        SetResult 161759
        SetLogicFlags ResultValue()
        SetStatus STATUS_OK
    Case Else
        SetStatus STATUS_INVALID_META
        SetResult STATUS_INVALID_META
    End Select
End Sub
