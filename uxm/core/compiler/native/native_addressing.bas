' Auto-split by V3 modularization
Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
    Dim startP As Long
    Dim body As String
    Dim bal As Long
    Dim c As String
    If p>Len(code) Then ParseAddress=0:Exit Function
    If Mid(code,p,1)<>"(" Then ParseAddress=0:Exit Function
    startP=p
    bal=0
    Do While p<=Len(code)
        c=Mid(code,p,1)
        If IsSpaceChar(c) Then
            SyntaxError("adresleme ifadesi icinde bosluk yasak",p)
            Exit Function
        End If
        If c="(" Then bal=bal+1
        If c=")" Then
            bal=bal-1
            If bal=0 Then Exit Do
        End If
        p=p+1
    Loop
    If p>Len(code) Or Mid(code,p,1)<>")" Then SyntaxError("adresleme parantezi kapanmadi",startP):Exit Function
    body=Mid(code,startP+1,p-startP-1)
    p=p+1
    If ParseAddressBody(body,kind,addrVal,addrVal2)=0 Then
        SyntaxError("gecersiz adresleme: ("+body+")",startP)
        Exit Function
    End If
    ParseAddress=1
End Function

Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
    Dim b As String
    Dim posx As Long
    Dim inner As String
    Dim rest As String
    Dim rel As Long
    Dim off As Long
    b=UCase(TrimAll(body))
    addrVal=0
    addrVal2=0
    If b="T" Then kind=ADDR_T:ParseAddressBody=1:Exit Function
    If b="SP" Then kind=ADDR_SP:ParseAddressBody=1:Exit Function
    If Left(b,3)="SP+" Then kind=ADDR_SP_REL:addrVal=Val(Mid(b,4)):ParseAddressBody=1:Exit Function
    If Left(b,3)="SP-" Then kind=ADDR_SP_REL:addrVal=-Val(Mid(b,4)):ParseAddressBody=1:Exit Function
    If b="P" Then kind=ADDR_P:ParseAddressBody=1:Exit Function
    If b="E" Then kind=ADDR_E:ParseAddressBody=1:Exit Function
    If b="F" Then kind=ADDR_F:ParseAddressBody=1:Exit Function
    If b="*T" Then kind=ADDR_IND_T:ParseAddressBody=1:Exit Function
    If Left(b,2)="T+" Then kind=ADDR_T_REL:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,2)="T-" Then kind=ADDR_T_REL:addrVal=-Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,2)="T:" Then
        If Right(b,2)="+P" Then
            kind=ADDR_T_BASE_P
            addrVal=Val(Mid(b,3,Len(b)-4))
            ParseAddressBody=1
            Exit Function
        End If
        kind=ADDR_T_ABS:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    End If
    If Left(b,2)="D:" Then
        If Right(b,2)="+P" Then
            kind=ADDR_D_BASE_P
            addrVal=Val(Mid(b,3,Len(b)-4))
            ParseAddressBody=1
            Exit Function
        End If
        kind=ADDR_D_ABS:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    End If
    If Left(b,4)="D@D:" Then kind=ADDR_D_AT_D_ABS:addrVal=Val(Mid(b,5)):ParseAddressBody=1:Exit Function
    If Left(b,4)="T@D:" Then kind=ADDR_T_AT_D_ABS:addrVal=Val(Mid(b,5)):ParseAddressBody=1:Exit Function
    If Left(b,2)="S:" Then kind=ADDR_S_ABS:addrVal=Val(Mid(b,3)):ParseAddressBody=1:Exit Function
    If Left(b,3)="D@T" Then
        kind=ADDR_D_AT_T_REL
        addrVal=0
        If Len(b)>3 Then
            If Mid(b,4,1)="+" Then addrVal2=Val(Mid(b,5)):ParseAddressBody=1:Exit Function
            If Mid(b,4,1)="-" Then addrVal2=-Val(Mid(b,5)):ParseAddressBody=1:Exit Function
            ParseAddressBody=0:Exit Function
        End If
        addrVal2=0
        ParseAddressBody=1
        Exit Function
    End If
    If Left(b,4)="D@(" Then
        posx=InStr(4,b,")")
        If posx=0 Then ParseAddressBody=0:Exit Function
        inner=Mid(b,4,posx-4)
        rest=Mid(b,posx+1)
        If ParseTapeRelInside(inner,rel)=0 Then ParseAddressBody=0:Exit Function
        off=0
        If rest<>"" Then
            If Left(rest,1)="+" Then
                off=Val(Mid(rest,2))
            ElseIf Left(rest,1)="-" Then
                off=-Val(Mid(rest,2))
            Else
                ParseAddressBody=0
                Exit Function
            End If
        End If
        kind=ADDR_D_AT_TBASE_REL
        addrVal=rel
        addrVal2=off
        ParseAddressBody=1
        Exit Function
    End If
    If Left(b,4)="*(T+" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:addrVal=Val(Mid(b,5,Len(b)-5)):ParseAddressBody=1:Exit Function
    If Left(b,4)="*(T-" And Right(b,1)=")" Then kind=ADDR_IND_T_REL:addrVal=-Val(Mid(b,5,Len(b)-5)):ParseAddressBody=1:Exit Function
    ParseAddressBody=0
End Function

Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
    s=UCase(TrimAll(s))
    baseRel=0
    If s="T" Then baseRel=0:ParseTapeRelInside=1:Exit Function
    If Left(s,2)="T+" Then baseRel=Val(Mid(s,3)):ParseTapeRelInside=1:Exit Function
    If Left(s,2)="T-" Then baseRel=-Val(Mid(s,3)):ParseTapeRelInside=1:Exit Function
    ParseTapeRelInside=0
End Function

Function AddressText(ByVal kind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long) As String
    Select Case kind
        Case ADDR_T
            AddressText="(T)"
        Case ADDR_T_REL
            If addrVal>=0 Then AddressText="(T+"+LTrim(Str(addrVal))+")" Else AddressText="(T"+LTrim(Str(addrVal))+")"
        Case ADDR_T_ABS
            AddressText="(T:"+LTrim(Str(addrVal))+")"
        Case ADDR_D_ABS
            AddressText="(D:"+LTrim(Str(addrVal))+")"
        Case ADDR_D_AT_T_REL
            If addrVal2=0 Then
                AddressText="(D@T)"
            ElseIf addrVal2>0 Then
                AddressText="(D@T+"+LTrim(Str(addrVal2))+")"
            Else
                AddressText="(D@T"+LTrim(Str(addrVal2))+")"
            End If
        Case ADDR_D_AT_TBASE_REL
            If addrVal2>=0 Then
                AddressText="(D@(T"+IIf(addrVal>=0,"+","")+LTrim(Str(addrVal))+")+"+LTrim(Str(addrVal2))+")"
            Else
                AddressText="(D@(T"+IIf(addrVal>=0,"+","")+LTrim(Str(addrVal))+")"+LTrim(Str(addrVal2))+")"
            End If
        Case ADDR_S_ABS
            AddressText="(S:"+LTrim(Str(addrVal))+")"
        Case ADDR_SP
            AddressText="(SP)"
        Case ADDR_SP_REL
            If addrVal>=0 Then AddressText="(SP+"+LTrim(Str(addrVal))+")" Else AddressText="(SP"+LTrim(Str(addrVal))+")"
        Case ADDR_D_BASE_P
            AddressText="(D:"+LTrim(Str(addrVal))+"+P)"
        Case ADDR_T_BASE_P
            AddressText="(T:"+LTrim(Str(addrVal))+"+P)"
        Case ADDR_D_AT_D_ABS
            AddressText="(D@D:"+LTrim(Str(addrVal))+")"
        Case ADDR_T_AT_D_ABS
            AddressText="(T@D:"+LTrim(Str(addrVal))+")"
        Case ADDR_P
            AddressText="(P)"
        Case ADDR_E
            AddressText="(E)"
        Case ADDR_F
            AddressText="(F)"
        Case ADDR_IND_T
            AddressText="(*T)"
        Case ADDR_IND_T_REL
            If addrVal>=0 Then AddressText="(*(T+"+LTrim(Str(addrVal))+"))" Else AddressText="(*(T"+LTrim(Str(addrVal))+"))"
        Case Else
            AddressText="(?)"
    End Select
End Function

