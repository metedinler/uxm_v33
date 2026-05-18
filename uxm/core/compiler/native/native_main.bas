' Auto-split by V3 modularization
Function FileStem(ByVal fileName As String) As String
    Dim i As Long
    Dim baseName As String
    baseName=fileName
    For i=Len(baseName) To 1 Step -1
        If Mid(baseName,i,1)="\" Or Mid(baseName,i,1)="/" Then
            baseName=Mid(baseName,i+1)
            Exit For
        End If
    Next i
    For i=Len(baseName) To 1 Step -1
        If Mid(baseName,i,1)="." Then
            baseName=Left(baseName,i-1)
            Exit For
        End If
    Next i
    FileStem=baseName
End Function

Sub WriteCliArtifact(ByVal fileName As String, ByVal content As String)
    Dim ff As Integer
    If TrimAll(fileName)="" Then Exit Sub
    ff=FreeFile
    Open fileName For Output As #ff
    Print #ff, content;
    Close #ff
End Sub

Sub PrintCliHelp()
    Print "UXM Native Compiler (uxm-a=uxmv33=uxm)"
    Print "Kullanim:"
    Print "  uxm_native.exe kaynak.uxm [out.asm]"
    Print "  uxm_native.exe -i kaynak.uxm --asm build\asm\program.asm"
    Print "Secenekler:"
    Print "  -i, --input <file>      Kaynak .uxm dosyasi"
    Print "  -o, --out <dir>         Cikti klasoru (ASM icin)"
    Print "  -x, --generic-output    Cikti adini program.asm yap"
    Print "  --asm <file>            ASM cikti yolu"
    Print "  --mode <compile|interpret|step|all>"
    Print "  --diag <file>           Diagnostics JSON (stub)"
    Print "  --uir <file>            UIR JSON (stub)"
    Print "  --opt <file>            Optimizer raporu JSON (stub)"
    Print "  --trace <file>          Trace NDJSON (stub)"
    Print "  --no-native             ASM uretmeden parse/validate yap"
    Print "  --safe | --normal | --wild"
    Print "  -v, --version"
    Print "  -h, --help"
End Sub

Sub Main()
    Dim i As Long
    Dim argText As String
    Dim argLow As String
    Dim outDir As String
    Dim asmPath As String
    Dim modeArg As String
    Dim diagPath As String
    Dim uirPath As String
    Dim optPath As String
    Dim tracePath As String
    Dim ideInPath As String
    Dim ideOutPath As String
    Dim genericOutput As Long
    Dim noNative As Long
    Dim baseName As String

    InitDefaults()

    i=1
    Do While Command(i)<>""
        argText=TrimAll(Command(i))
        argLow=LCase(argText)

        Select Case argLow
            Case "-h","--help"
                PrintCliHelp()
                End
            Case "-v","--version"
                Print "UX-MINIMA x64 "+UXM_VERSION
                End
            Case "-i","--input"
                i=i+1
                If Command(i)="" Then Print "HATA: "+argText+" sonrasi dosya bekleniyor.":End 1
                InFile=TrimAll(Command(i))
            Case "-o","--out"
                i=i+1
                If Command(i)="" Then Print "HATA: "+argText+" sonrasi klasor bekleniyor.":End 1
                outDir=TrimAll(Command(i))
            Case "--asm"
                i=i+1
                If Command(i)="" Then Print "HATA: --asm sonrasi dosya bekleniyor.":End 1
                asmPath=TrimAll(Command(i))
            Case "-x","--generic-output"
                genericOutput=1
            Case "--mode"
                i=i+1
                If Command(i)="" Then Print "HATA: --mode sonrasi deger bekleniyor.":End 1
                modeArg=LCase(TrimAll(Command(i)))
            Case "--safe"
                Mode=MODE_SAFE
            Case "--normal"
                Mode=MODE_NORMAL
            Case "--wild"
                Mode=MODE_WILD
            Case "--diag"
                i=i+1
                If Command(i)="" Then Print "HATA: --diag sonrasi dosya bekleniyor.":End 1
                diagPath=TrimAll(Command(i))
            Case "--uir"
                i=i+1
                If Command(i)="" Then Print "HATA: --uir sonrasi dosya bekleniyor.":End 1
                uirPath=TrimAll(Command(i))
            Case "--opt"
                i=i+1
                If Command(i)="" Then Print "HATA: --opt sonrasi dosya bekleniyor.":End 1
                optPath=TrimAll(Command(i))
            Case "--trace"
                i=i+1
                If Command(i)="" Then Print "HATA: --trace sonrasi dosya bekleniyor.":End 1
                tracePath=TrimAll(Command(i))
            Case "--ide-in"
                i=i+1
                If Command(i)="" Then Print "HATA: --ide-in sonrasi dosya bekleniyor.":End 1
                ideInPath=TrimAll(Command(i))
            Case "--ide-out"
                i=i+1
                If Command(i)="" Then Print "HATA: --ide-out sonrasi dosya bekleniyor.":End 1
                ideOutPath=TrimAll(Command(i))
            Case "--obj","--exe","--max-steps","--legacy-run-trace","--legacy-export-uir","--legacy-export-opt"
                i=i+1
                If Command(i)="" Then Print "HATA: "+argText+" sonrasi deger bekleniyor.":End 1
            Case "--asm-only","--obj-only","--exe-only","--no-link","--run","--no-run","--trace-on","--trace-off","--diag-on","--diag-off","--uir-on","--uir-off","--opt-report","--no-opt","--allow-native-wild","--compare-legacy"
                ' UXM-A CLI uyumlulugu icin kabul edilir; native derleyici tarafinda ek isleme gerek yok.
            Case "--no-native"
                noNative=1
            Case Else
                If Left(argText,1)="-" Then
                    Print "HATA: bilinmeyen arguman: ";argText
                    End 1
                End If
                If InFile="" Then
                    InFile=argText
                ElseIf OutAsm="" Then
                    OutAsm=argText
                End If
        End Select

        i=i+1
    Loop

    If InFile="" Then
        Print "UX-MINIMA x64 "+UXM_VERSION+" FreeBASIC compiler"
        Print "Kaynak .uxm dosyasi: ";
        Line Input InFile
        InFile=TrimAll(InFile)
    End If

    If InFile="" Then
        Print "HATA: kaynak dosya verilmedi."
        End
    End If

    If asmPath<>"" Then
        OutAsm=asmPath
    ElseIf OutAsm<>"" Then
        OutAsm=TrimAll(OutAsm)
    ElseIf outDir<>"" Then
        baseName=FileStem(InFile)
        If genericOutput<>0 Then baseName="program"
        OutAsm=outDir+"\"+baseName+".asm"
    ElseIf genericOutput<>0 Then
        OutAsm="program.asm"
    Else
        OutAsm=InFile+".asm"
    End If

    If modeArg<>"" Then
        If modeArg<>"compile" And modeArg<>"interpret" And modeArg<>"step" And modeArg<>"all" Then
            Print "HATA: --mode degeri gecersiz: ";modeArg
            End 1
        End If
    End If

    ReadFileToSrc(InFile)
    If HadError Then Print ErrMsg:End 1
    PreprocessSource(InFile)
    If HadError Then Print ErrMsg:End 1
    ParsePragmas()
    If HadError Then Print ErrMsg:End 1
    ApplyMemoryModel()
    If HadError Then Print ErrMsg:End 1
    FirstPassDefinitions()
    If HadError Then Print ErrMsg:End 1
    ParseProgram(Src,0)
    If HadError Then Print ErrMsg:End 1
    ValidateBranches()
    If HadError Then Print ErrMsg:End 1

    If noNative=0 Then
        GenerateASM()
        If HadError Then Print ErrMsg:End 1
        Print "ASM uretildi: ";OutAsm
        Print "[V3.3-stage15-16] Native ASM hazir. Link islemi build_one_native.bat tarafindan yurutulur."
    Else
        Print "Native ASM uretimi --no-native nedeniyle atlandi."
    End If

    If modeArg<>"" And modeArg<>"compile" Then
        Print "Not: native compiler mode="+modeArg+" icin parse/validate uyumluluk calismasi yapti."
    End If

    If tracePath<>"" Then WriteCliArtifact(tracePath,"{""event"":""native_compile"",""ok"":true}"+Chr(10))
    If diagPath<>"" Then WriteCliArtifact(diagPath,"{""schema"":""uxm.diag.v1"",""ok"":true}")
    If uirPath<>"" Then WriteCliArtifact(uirPath,"{""schema"":""uxm.uir.v1"",""kind"":""native-asm-only""}")
    If optPath<>"" Then WriteCliArtifact(optPath,"{""schema"":""uxm.opt.v1"",""note"":""optimizer-report-not-available""}")
    If ideOutPath<>"" Then WriteCliArtifact(ideOutPath,"{""ok"":false,""error"":""ide_mode_not_supported_in_native_compiler""}")
    If ideInPath<>"" Then
        ' IDE request dosyasi varligi kabul edilir; native compiler parse edebilir ama ide protokolu uygulamaz.
    End If
End Sub

