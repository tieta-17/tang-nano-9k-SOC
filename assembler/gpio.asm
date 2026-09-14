ADDI x1, x0, 3
SW x1, 1040(x0)              ; gpio_enable = 3, both pins output

ADDI x1, x0, 1                 ; start asymmetric: pin0=1, pin1=0

loop:
XORI x1, x1, 3
SW x1, 1044(x0)                  ; toggle both bits together — always opposite

ADDI x2, x0, 6750
outer:
ADDI x3, x0, 1000
inner:
SUBI x3, x3, 1
BNE x3, x0, inner
SUBI x2, x2, 1
BNE x2, x0, outer

BEQ x0, x0, loop