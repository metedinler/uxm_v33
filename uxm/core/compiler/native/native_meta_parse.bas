' Auto-split by V3 modularization
Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
    Dim startP As Long
    Dim ok As Long
    Dim id As Long
    Dim idx As Long
    Dim forceHost As Long
    Dim kind As Long
    Dim addrVal As Long
    Dim addrVal2 As Long
    startP=p
    p=p+1
    forceHost=0
    If p<=Len(code) Then
        If Mid(code,p,1)="!" Then
            forceHost=1
            p=p+1
        End If
    End If
    If p>Len(code) Then SyntaxError("@ sonrasi meta id, # veya adresleme bekleniyor",p):Exit Sub
    If Mid(code,p,1)="#" Then
        p=p+1
        If forceHost Then
            AddMetaAddrInstr(-1,1,forceHost,"@!#",ADDR_T,0,0)
        Else
            AddMetaAddrInstr(-1,1,forceHost,"@#",ADDR_T,0,0)
        End If
        Exit Sub
    End If
    If Mid(code,p,1)="(" Then
        If ParseAddress(code,p,kind,addrVal,addrVal2)=0 Then Exit Sub
        AddMetaAddrInstr(-1,1,forceHost,Mid(code,startP,p-startP),kind,addrVal,addrVal2)
        Exit Sub
    End If
    id=ParseUnsignedLong(code,p,ok)
    If ok=0 Then SyntaxError("@ sonrasi meta id bekleniyor",p):Exit Sub
    If id<0 Or id>65535 Then SyntaxError("meta id 0..65535 araliginda olmali",startP):Exit Sub
    idx=FindMacroIndex(id)
    If idx<>0 And forceHost=0 Then
        ParseProgram(MacroText(idx),depth+1)
    Else
        AddMetaInstr(id,0,forceHost,Mid(code,startP,p-startP))
    End If
End Sub

Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
    AddMetaAddrInstr(metaId,dynamicFlag,forceHost,txt,ADDR_T,0,0)
End Sub

Sub AddMetaAddrInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long)
    AddInstr(OP_META,0,addrKind,addrVal,addrVal2,txt)
    IMetaId(InstrCount)=metaId
    IMetaDyn(InstrCount)=dynamicFlag
    IMetaForce(InstrCount)=forceHost
End Sub

