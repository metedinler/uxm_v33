
#ifndef UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
#define UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
' V18 hook: real extension services. Returns non-zero when handled.
Function RuntimeHookDispatchExt(ByVal metaId As ULongInt) As Long
    Select Case metaId
    Case 416,417,418,419
        MetaFileExtRealV18 metaId
        Return -1
    Case 760 To 769
        MetaHypothesisRealV18 metaId
        Return -1
    Case 320 To 325, 790 To 795
        MetaPosthocRealV18 metaId
        Return -1
    Case 340 To 356, 810 To 823
        MetaAIRealV18 metaId
        Return -1
    Case Else
        Return 0
    End Select
End Function
#endif
