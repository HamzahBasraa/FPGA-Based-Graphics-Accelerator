; Small example program for driving the 
; video accelerator



li gp, 0x10000
li sp, 0x3000
li s0, 0

main   
    ; Setup video mode to 8 bit color @ 640 x 480
    li   t0, 0x10600
    li   t1, VDUC_MODE_8_640
    sw   t1, VDUC_MODE[t0]



    call loop_delay     
    call draw_clear
    call loop_delay 
    call draw_lines
    call loop_delay

    ; Setup video mode to 16 bit color @ 640 x 480
    li   t0, 0x10600
    li   t1, VDUC_MODE_16_640
    sw   t1, VDUC_MODE[t0]



    call draw_clear  
    call loop_delay
    call draw_gradient 
    call loop_delay
    call draw_lines
    call loop_delay

    J main


; Draw lines 
draw_lines
    li t0, 0x10800

    ; pass argument 
    li t1, 0x0064 
    li t2, 0x0064 
    li t3, 0x0280
    li t4, 0x0281
    li t5, 0xef2c 
    li t6, 0x2 
    li s0, 0x02f3

    sw t1, 0x0[t0]
    sw t2, 0x4[t0]
    sw t3, 0x8[t0]
    sw t4, 0xC[t0]
    sw t5, 0x10[t0]
    sw t6, 0x14[t0]
    sw s0, 0x18[t0]

    li t1, DRAWING_UNIT_LINE
    sw t1, 0x20[t0]

    ret    

draw_clear 
    ; pass arguments 
    li t0, 0x10800
    li t1, 0xf231  ; clear color
    li t2, DRAWING_UNIT_CLEAR

    sw t1, 0x0[t0]      
    sw t2, 0x20[t0] ; 
    ret

draw_gradient 
    ; pass arguments 
    li t0, 0x10800
    li t1, 0xFF1122  ; color A (24 bit)
    li t2, 0xa12b32  ; color B (24 bit)
    li t3, DRAWING_UNIT_GRADIENT

    sw t1, 0x0[t0]      
    sw t2, 0x0[t0]      
    sw t3, 0x20[t0] ; 
    ret

 
; Small delay 
loop_delay 
    li t0, 5000000         
loop_delay_a
    addi t0, t0, -1
    bne t0, x0, loop_delay_a
    ret

; Some useful defines   
DRAWING_UNIT_CLEAR      EQU 0 
DRAWING_UNIT_LINE       EQU 1
DRAWING_UNIT_GRADIENT   EQU 2
VDUC_MODE_16_640        EQU 1
VDUC_MODE_8_640         EQU 0 
VDUC_MODE               EQU 4