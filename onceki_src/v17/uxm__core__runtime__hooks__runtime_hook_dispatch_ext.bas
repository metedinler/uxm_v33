#ifndef UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
#define UXM_RUNTIME_HOOK_DISPATCH_EXT_BAS
' V3.3 hook: external runtime service dispatch extension point. Default no-op.
Function RuntimeHookDispatchExt(ByVal metaId As ULongInt) As Long
    Return 0
End Function
#endif
