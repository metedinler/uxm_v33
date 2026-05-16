#ifndef UXM_HOOK_PARSER_EXT_BAS
#define UXM_HOOK_PARSER_EXT_BAS
' V3.3 hook: parser extension point. Default no-op.
Function UxmHookParserExt(ByRef code As String, ByRef p As Long) As Long
    Return 0
End Function
#endif
