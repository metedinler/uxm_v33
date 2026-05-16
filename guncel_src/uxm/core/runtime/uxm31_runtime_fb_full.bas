#Lang "fb"
Extern "C"
Declare Sub uxm_entry()
Declare Sub ux_putc(ByVal ch As ULongInt)
Declare Function ux_getc() As ULongInt
Declare Sub ux_print_data_string(ByVal startCell As ULongInt, ByVal cellBits As ULongInt)
Declare Sub ux_meta_call_ex(ByVal metaId As ULongInt, ByVal memPtr As UByte Ptr)
Declare Sub ux_runtime_error(ByVal code As ULongInt)
Extern ux_mem As UByte
Extern ux_status As UByte
Extern ux_flags As UShort
Extern ux_ptr As ULongInt
Extern ux_sp As ULongInt
Extern ux_cell_bits As ULong
Extern ux_cell_bytes As ULong
Extern ux_tape_cells As ULong
Extern ux_stack_cells As ULong
Extern ux_data_cells As ULong
Extern ux_queue_cells As ULong
Extern ux_stack_offset As ULong
Extern ux_data_offset As ULong
End Extern
Const FLAG_Z As UShort=&H0001
Const FLAG_C As UShort=&H0002
Const FLAG_O As UShort=&H0004
Const FLAG_S As UShort=&H0008
Const FLAG_SGN As UShort=&H0010
Const FLAG_END As UShort=&H0020
Const FLAG_WILD As UShort=&H0040
Const FLAG_BND As UShort=&H0080
Const FLAG_TRC As UShort=&H0100
Const FLAG_FIFO As UShort=&H0200
Const FLAG_ERR As UShort=&H0400
Const FLAG_DIRTY As UShort=&H0800
Const FLAG_PCHG As UShort=&H1000
Const STATUS_OK As UByte=0
Const STATUS_INVALID_META As UByte=5
Const STATUS_PTR_BOUNDS As UByte=10
Const STATUS_STACK_OVERFLOW As UByte=11
Const STATUS_STACK_UNDERFLOW As UByte=12
Const STATUS_OVERFLOW As UByte=13
Const STATUS_UNDERFLOW As UByte=14
Const STATUS_DIV_ZERO As UByte=15
Const STATUS_DATA_BOUNDS As UByte=16
Const STATUS_SAFE_DENY As UByte=23
Const STATUS_PROTECTED_META As UByte=24
Const STATUS_EOF As UByte=26
Const PI_D As Double=3.1415926535897932384626433832795
Const UXM_RUNTIME_MAX_TOTAL_KB As ULongInt=16384  ' 16 MB toplam UXM bellek ust siniri
Const FIFO_STORAGE_BYTES As ULongInt=16777216  ' 16 MB fiziksel FIFO/queue deposu
Dim Shared fifoMem(0 To FIFO_STORAGE_BYTES-1) As UByte
Dim Shared fifoHead As ULongInt
Dim Shared fifoTail As ULongInt
Dim Shared fifoCount As ULongInt
Declare Function MemBase() As UByte Ptr
Declare Function TapeBase() As UByte Ptr
Declare Function StackBase() As UByte Ptr
Declare Function DataBase() As UByte Ptr
Declare Function CellMask() As ULongInt
Declare Function CellSignBit() As ULongInt
Declare Function CellMaxSigned() As LongInt
Declare Function CellMinSigned() As LongInt
Declare Function CellBytes() As ULong
Declare Function ReadCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt) As ULongInt
Declare Sub WriteCell(ByVal basePtr As UByte Ptr, ByVal cellIndex As ULongInt, ByVal value As ULongInt)
Declare Function ReadTape(ByVal cellIndex As LongInt) As ULongInt
Declare Sub WriteTape(ByVal cellIndex As LongInt, ByVal value As ULongInt)
Declare Function ReadData(ByVal cellIndex As LongInt) As ULongInt
Declare Sub WriteData(ByVal cellIndex As LongInt, ByVal value As ULongInt)
Declare Function ReadTapeRel(ByVal rel As LongInt) As ULongInt
Declare Sub WriteTapeRel(ByVal rel As LongInt, ByVal value As ULongInt)
Declare Function ToSignedValue(ByVal value As ULongInt) As LongInt
Declare Function FromSignedValue(ByVal value As LongInt) As ULongInt
Declare Function IsSignedMode() As Long
Declare Function IsBigEndian() As Long
Declare Function IsWildMode() As Long
Declare Sub SetStatus(ByVal code As UByte)
Declare Sub ClearArithFlags()
Declare Sub SetZeroSignFlags(ByVal value As ULongInt)
Declare Sub SetLogicFlags(ByVal resultMasked As ULongInt)
Declare Sub SetAddFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetSubFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetMulFlags(ByVal a As ULongInt, ByVal b As ULongInt, ByVal resultFull As ULongInt, ByVal resultMasked As ULongInt)
Declare Sub SetCompareFlags(ByVal a As ULongInt, ByVal b As ULongInt)
Declare Function Arg1() As ULongInt
Declare Function Arg2() As ULongInt
Declare Function Arg0() As ULongInt
Declare Sub SetResult(ByVal value As ULongInt)
Declare Function ResultValue() As ULongInt
Declare Function StackRead(ByVal idx As ULongInt) As ULongInt
Declare Sub StackWrite(ByVal idx As ULongInt, ByVal value As ULongInt)
Declare Sub StackPush(ByVal value As ULongInt)
Declare Function StackPop() As ULongInt
Declare Sub FifoPush(ByVal value As ULongInt)
Declare Function FifoPop() As ULongInt
Declare Function FifoPeek() As ULongInt
Declare Function FifoLimit() As ULongInt
Declare Sub FifoClear()
Declare Sub PrintStatusMessage(ByVal code As ULongInt)
Declare Function ScaleFactor() As LongInt
Declare Function SinScaled(ByVal degree As Double) As LongInt
Declare Function CosScaled(ByVal degree As Double) As LongInt
Declare Function TanScaled(ByVal degree As Double) As LongInt
Declare Function SinhLocal(ByVal x As Double) As Double
Declare Function CoshLocal(ByVal x As Double) As Double
Declare Function TanhLocal(ByVal x As Double) As Double
Declare Function AsinLocal(ByVal x As Double) As Double
Declare Function AcosLocal(ByVal x As Double) As Double
Declare Function AsinhLocal(ByVal x As Double) As Double
Declare Function AcoshLocal(ByVal x As Double) As Double
Declare Function AtanhLocal(ByVal x As Double) As Double
Declare Function RandomByte() As ULongInt
Declare Sub PrintDecimalValue(ByVal value As ULongInt)
Declare Function ReadDecimalValue() As ULongInt
Declare Function ClampToCell(ByVal v As LongInt) As ULongInt
Declare Function ClampDoubleToCell(ByVal v As Double) As ULongInt
Declare Sub DataBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub DataBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub TapeBlockCopy(ByVal src As LongInt, ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub TapeBlockClear(ByVal dst As LongInt, ByVal count As LongInt)
Declare Sub SortTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Declare Sub SortData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal ascending As Long)
Declare Function LinearSearchTape(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Declare Function LinearSearchData(ByVal startIdx As LongInt, ByVal count As LongInt, ByVal target As ULongInt) As LongInt
Declare Sub WildLayoutChange()
Declare Sub MetaCore(ByVal metaId As ULongInt)
Declare Sub MetaArithmetic(ByVal metaId As ULongInt)
Declare Sub MetaMath(ByVal metaId As ULongInt)
Declare Sub MetaIO(ByVal metaId As ULongInt)
Declare Sub MetaPointerMemory(ByVal metaId As ULongInt)
Declare Sub MetaFifoDataSortWild(ByVal metaId As ULongInt)
Declare Sub MetaFlagsEndian(ByVal metaId As ULongInt)
Declare Sub MetaFloatingPoint(ByVal metaId As ULongInt)
Declare Sub MetaMathExtra(ByVal metaId As ULongInt)
Declare Sub MetaMatrix(ByVal metaId As ULongInt)
Declare Sub MetaString(ByVal metaId As ULongInt)
Declare Sub MetaStringExt(ByVal metaId As ULongInt)
Declare Sub MetaFile(ByVal metaId As ULongInt)
Declare Sub MetaBio(ByVal metaId As ULongInt)
Declare Sub MetaStatistics(ByVal metaId As ULongInt)
Declare Sub MetaProbability(ByVal metaId As ULongInt)
Declare Sub MetaNumericMethods(ByVal metaId As ULongInt)
Declare Sub MetaComplex(ByVal metaId As ULongInt)
Declare Sub MetaMatrixAdvancedTensor(ByVal metaId As ULongInt)
Declare Sub MetaLinalgAdvanced(ByVal metaId As ULongInt)
Declare Sub MetaSparseVector(ByVal metaId As ULongInt)
Declare Sub MetaMLDataPipeline(ByVal metaId As ULongInt)
Declare Function RuntimeHookDispatchExt(ByVal metaId As ULongInt) As Long

#Include Once "runtime_memory.bas"
#Include Once "runtime_status_flags.bas"
#Include Once "runtime_io.bas"
#Include Once "runtime_meta_dispatch.bas"
#Include Once "runtime_host.bas"
#Include Once "hooks/runtime_hook_dispatch_ext.bas"
#Include Once "services/runtime_fp_services.bas"
#Include Once "services/runtime_matrix_services.bas"
#Include Once "services/runtime_matrix_advanced_tensor_services.bas"
#Include Once "services/runtime_sparse_vector_services.bas"
#Include Once "services/runtime_linalg_advanced_services.bas"
#Include Once "services/runtime_ml_data_pipeline_services.bas"
#Include Once "services/runtime_math_services.bas"
#Include Once "services/runtime_string_services.bas"
#Include Once "services/runtime_string_ext_services.bas"
#Include Once "services/runtime_file_services.bas"
#Include Once "services/runtime_bio_services.bas"
#Include Once "services/runtime_statistics_services.bas"
#Include Once "services/runtime_probability_services.bas"
#Include Once "services/runtime_numeric_methods_services.bas"
#Include Once "services/runtime_complex_services.bas"
