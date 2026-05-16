@echo off
REM V18 gerçek servis testleri. Derleme yok için -k kullanabilirsiniz.
python araclar\uxm_test_kosucu.py --kok . --test-dir uxm\tests\stage23_placeholder_real --out-root sonuclar_stage23 %*
