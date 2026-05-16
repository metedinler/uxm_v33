#Lang "fb"
Const UXM_VERSION As String="3.3-stage15-16-ml-data-mem16m"
Const MAX_SRC As Long=2000000
Const MAX_INSTR As Long=200000
Const MAX_STRINGS As Long=1024
Const MAX_MACROS As Long=128
Const MAX_LOOP As Long=8192
Const MAX_LABELS As Long=200000
Const UXM_DEFAULT_TAPE_KB As Long=32
Const UXM_DEFAULT_STACK_KB As Long=4
Const UXM_DEFAULT_DATA_KB As Long=16
Const UXM_DEFAULT_QUEUE_KB As Long=4
Const UXM_MAX_TAPE_KB As Long=16384
Const UXM_MAX_STACK_KB As Long=16384
Const UXM_MAX_DATA_KB As Long=16384
Const UXM_MAX_QUEUE_KB As Long=16384
Const UXM_MAX_TOTAL_KB As Long=16384
Const UXM_MEMORY_POLICY_BOUNDED As Long=0
Const UXM_MEMORY_POLICY_TOTAL As Long=1
Const OP_NOP As Long=0
Const OP_RIGHT As Long=1
Const OP_LEFT As Long=2
Const OP_INC As Long=3
Const OP_DEC As Long=4
Const OP_CLEAR As Long=5
Const OP_PUTC As Long=6
Const OP_GETC As Long=7
Const OP_LOOP_BEG As Long=8
Const OP_LOOP_END As Long=9
Const OP_PUSH As Long=10
Const OP_POP As Long=11
Const OP_EQ As Long=12
Const OP_GT As Long=13
Const OP_LT As Long=14
Const OP_AND As Long=15
Const OP_OR As Long=16
Const OP_XOR As Long=17
Const OP_NOT As Long=18
Const OP_SHL As Long=19
Const OP_SHR As Long=20
Const OP_STATUS As Long=21
Const OP_META As Long=22
Const OP_BRANCH As Long=23
Const OP_PRINT_STRING As Long=24
Const ADDR_T As Long=0
Const ADDR_T_REL As Long=1
Const ADDR_T_ABS As Long=2
Const ADDR_D_ABS As Long=3
Const ADDR_S_ABS As Long=4
Const ADDR_SP As Long=5
Const ADDR_P As Long=6
Const ADDR_E As Long=7
Const ADDR_F As Long=8
Const ADDR_IND_T As Long=9
Const ADDR_IND_T_REL As Long=10
Const ADDR_D_AT_T_REL As Long=11
Const ADDR_D_AT_TBASE_REL As Long=12
Const ADDR_SP_REL As Long=13
Const ADDR_D_BASE_P As Long=14
Const ADDR_T_BASE_P As Long=15
Const ADDR_D_AT_D_ABS As Long=16
Const ADDR_T_AT_D_ABS As Long=17
Const BR_CUR_NZ As Long=1
Const BR_CUR_Z As Long=2
Const BR_ALWAYS As Long=3
Const BR_Z_SET As Long=4
Const BR_Z_CLR As Long=5
Const BR_C_SET As Long=6
Const BR_C_CLR As Long=7
Const BR_O_SET As Long=8
Const BR_O_CLR As Long=9
Const BR_S_SET As Long=10
Const BR_S_CLR As Long=11
Const MODE_SAFE As Long=0
Const MODE_NORMAL As Long=1
Const MODE_WILD As Long=2
Declare Sub Main()
Declare Sub InitDefaults()
Declare Sub ReadFileToSrc(ByVal fileName As String)
Declare Sub FirstPassDefinitions()
Declare Sub ParsePragmas()
Declare Sub ApplyMemoryModel()
Declare Sub ParseProgram(ByRef code As String, ByVal depth As Long)
Declare Sub ParseOneInstruction(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseStringDef(ByRef code As String, ByRef p As Long)
Declare Sub ParseMacroDef(ByRef code As String, ByRef p As Long)
Declare Sub ParsePrintString(ByRef code As String, ByRef p As Long)
Declare Sub ParseMeta(ByRef code As String, ByRef p As Long, ByVal depth As Long)
Declare Sub ParseBranch(ByRef code As String, ByRef p As Long)
Declare Sub AddInstr(ByVal op As Long, ByVal amount As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal txt As String)
Declare Sub AddMetaInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String)
Declare Sub AddMetaAddrInstr(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal txt As String, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long)
Declare Sub AddBranchInstr(ByVal cond As Long, ByVal brDir As Long, ByVal dist As Long, ByVal txt As String)
Declare Sub AddStringDef(ByVal id As Long, ByVal startCell As Long, ByVal txt As String)
Declare Sub AddMacroDef(ByVal id As Long, ByVal txt As String)
Declare Sub SkipLine(ByRef code As String, ByRef p As Long)
Declare Sub SyntaxError(ByVal msg As String, ByVal p As Long)
Declare Sub ValidateBranches()
Declare Sub GenerateASM()
Declare Sub EmitHeader()
Declare Sub EmitStringInitializers()
Declare Sub EmitInstr(ByVal i As Long)
Declare Sub EmitFooter()
Declare Sub EmitLine(ByVal s As String)
Declare Sub EmitAddrLoad(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
Declare Sub EmitAddrStore(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal regName As String)
Declare Sub EmitAddrPtr(ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long, ByVal outReg As String)
Declare Sub EmitSetFlagsFromRAX()
Declare Sub EmitMetaCall(ByVal metaId As Long, ByVal dynamicFlag As Long, ByVal forceHost As Long, ByVal addrKind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long)
Declare Sub EmitBranch(ByVal i As Long)
Declare Sub EmitLoopBegin(ByVal i As Long)
Declare Sub EmitLoopEnd(ByVal i As Long)
Declare Sub EmitAsmLabelIfNeeded(ByVal i As Long)
Declare Function ParseUnsignedLong(ByRef code As String, ByRef p As Long, ByRef ok As Long) As Long
Declare Function ParseBracedText(ByRef code As String, ByRef p As Long, ByRef ok As Long) As String
Declare Function ParseAddress(ByRef code As String, ByRef p As Long, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
Declare Function ParseAddressBody(ByVal body As String, ByRef kind As Long, ByRef addrVal As Long, ByRef addrVal2 As Long) As Long
Declare Function ParseTapeRelInside(ByVal s As String, ByRef baseRel As Long) As Long
Declare Function FindStringIndex(ByVal id As Long) As Long
Declare Function FindMacroIndex(ByVal id As Long) As Long
Declare Function IsDigitChar(ByVal c As String) As Long
Declare Function IsSpaceChar(ByVal c As String) As Long
Declare Function IsCommandChar(ByVal c As String) As Long
Declare Function CellSize() As Long
Declare Function MemSizePrefix() As String
Declare Function Reg8(ByVal regName As String) As String
Declare Function Reg16(ByVal regName As String) As String
Declare Function Reg32(ByVal regName As String) As String
Declare Function TrimAll(ByVal s As String) As String
Declare Function AddressText(ByVal kind As Long, ByVal addrVal As Long, ByVal addrVal2 As Long) As String
Declare Function RemoveBOM(ByVal s As String) As String
Declare Function NewAsmId() As Long
Declare Function LowerNoSpace(ByVal s As String) As String
Declare Function GetPragmaValue(ByVal lineText As String, ByVal keyName As String) As String
Declare Function ParseSizeKB(ByVal s As String, ByVal defaultKB As Long) As Long
Dim Shared Src As String
Dim Shared InFile As String
Dim Shared OutAsm As String
Dim Shared HadError As Long
Dim Shared ErrMsg As String
Dim Shared InstrCount As Long
Dim Shared IOp(1 To MAX_INSTR) As Long
Dim Shared IAmt(1 To MAX_INSTR) As Long
Dim Shared IAddrKind(1 To MAX_INSTR) As Long
Dim Shared IAddrVal(1 To MAX_INSTR) As Long
Dim Shared IAddrVal2(1 To MAX_INSTR) As Long
Dim Shared IText(1 To MAX_INSTR) As String
Dim Shared IMetaId(1 To MAX_INSTR) As Long
Dim Shared IMetaDyn(1 To MAX_INSTR) As Long
Dim Shared IMetaForce(1 To MAX_INSTR) As Long
Dim Shared IBrCond(1 To MAX_INSTR) As Long
Dim Shared IBrDir(1 To MAX_INSTR) As Long
Dim Shared IBrDist(1 To MAX_INSTR) As Long
Dim Shared IBrTarget(1 To MAX_INSTR) As Long
Dim Shared NeedLabel(1 To MAX_LABELS) As Long
Dim Shared StrCount As Long
Dim Shared StrId(1 To MAX_STRINGS) As Long
Dim Shared StrStart(1 To MAX_STRINGS) As Long
Dim Shared StrText(1 To MAX_STRINGS) As String
Dim Shared MacroCount As Long
Dim Shared MacroId(1 To MAX_MACROS) As Long
Dim Shared MacroText(1 To MAX_MACROS) As String
Dim Shared LoopStack(1 To MAX_LOOP) As Long
Dim Shared LoopSP As Long
Dim Shared LoopId(1 To MAX_INSTR) As Long
Dim Shared LoopCounter As Long
Dim Shared CellBits As Long
Dim Shared TapeKB As Long
Dim Shared StackKB As Long
Dim Shared DataKB As Long
Dim Shared QueueKB As Long
Dim Shared MemoryPolicy As Long
Dim Shared MemoryTotalLimitKB As Long
Dim Shared TapeCells As Long
Dim Shared StackCells As Long
Dim Shared DataCells As Long
Dim Shared QueueCells As Long
Dim Shared TapeBytes As Long
Dim Shared StackBytes As Long
Dim Shared DataBytes As Long
Dim Shared QueueBytes As Long
Dim Shared DataOffset As Long
Dim Shared StackOffset As Long
Dim Shared Mode As Long
Dim Shared BoundsOn As Long
Dim Shared OverflowCheck As Long
Dim Shared DefaultSigned As Long
Dim Shared DefaultBigEndian As Long
Dim Shared PragmaSeedEnabled As Long
Dim Shared PragmaSeedValue As Long
Dim Shared PragmaArgeJson As Long
Dim Shared PragmaArgeInterpreter As Long
Dim Shared PragmaArgeStep As Long
Dim Shared PragmaArgeTrace As Long
Dim Shared PragmaArgeWatch As Long
Dim Shared OutFF As Long
Dim Shared EmitLabelCounter As Long
#Include Once "../extensions/arge_parse_math_additions.bas"
#Include Once "../extensions/arge_parse_matrix_additions.bas"

#Include Once "native_cli.bas"
#Include Once "native_lexer_parser.bas"
#Include Once "native_addressing.bas"
#Include Once "native_meta_parse.bas"
#Include Once "native_validation.bas"
#Include Once "native_asm_emit.bas"
#Include Once "native_main.bas"

Main()
End
