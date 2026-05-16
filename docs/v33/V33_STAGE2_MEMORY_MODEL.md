# UX-MINIMA V3.3 Stage-2 Memory Model

Bu hamlede eski `Tape+Stack+Data == 64 KB` zorunlulugu kaldirildi.

## Varsayilanlar

```text
#memory tape=32,stack=4,data=16,queue=4
```

## Ust sinirlar

```text
tape  <= 512 KB
stack <= 256 KB
data  <= 256 KB
queue <= 256 KB
toplam <= 1536 KB
```

`queue` ve `fifo` pragma anahtarlari es anlamlidir.

## Davranis

- Tape/Stack/Data ayni `ux_mem` blogunda tutulur.
- Queue/FIFO runtime tarafindaki ayri FIFO deposunu kullanir.
- ASM icinde `ux_queue_cells` global degeri uretilir.
- Runtime FIFO islemleri artik sabit `FIFO_MAX` yerine `ux_queue_cells` limitini kullanir.
