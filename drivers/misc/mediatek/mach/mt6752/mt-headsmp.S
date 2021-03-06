#include <linux/linkage.h>
#include <linux/init.h>

    __CPUINIT

CCI400_SI3_SNOOP_CONTROL:
.long 0x10394000
CCI400_STATUS:
.long 0x1039000C
MP1_AXI_CONFIG:
.long 0x1020022C

ENTRY(mt_secondary_startup)
/*
    @XXX: temporary solution for enable smp
    MRRC    p15, 1, r0, r1, c15             @ read cpu extended control register
    ORR     r0, r0, #0x040
    MCRR    p15, 1, r0, r1, c15             @ write cpu extended control register
    DSB
    ISB
*/
    /* CONFIG_ARM_ERRATA_836870, prevent software livelock */
    mrc     p15, 0, r9, c0, c0, 0           @ MIDR
    movw    r10, #0xfff0
    movt    r10, #0xff0f
    and     r9, r10
    movw    r10, #0xD030
    movt    r10, #0x410F
    teq     r9, r10
    bne     1f

    mrrc    p15, 0, r0, r1, c15             @ Read CPU Auxiliary Control Register
    orr     r0, r0, #0x01000000             @ set CPUACTLR[24] = 1
    mcrr    p15, 0, r0, r1, c15             @ Write CPU Auxiliary Control Register
    dsb
    isb
1:

    mrc     p15, 0, r0, c0, c0, 5           @ MPIDR
    ubfx    r1, r0, #8, #4                  @ Cluster ID
    cmp     r1, #0                          @ Cluster 1
    beq     end
    ubfx    r1, r0, #0, #2                  @ CPU ID
    cmp     r1, #0                          @ CPU 0 (aka CPU4)
    bne     end

#ifdef CONFIG_ARM_ERRATA_826319
    mrc     p15, 1, r5, c15, c0, 0          @ Read L2ACTLR into Rt
    bic     r5, r5, #0x4000                 @ Set Bit[14]=0, Disables UniqueClean evictions with data
    orr     r5, r5, #0x8                    @ Set Bit[3]=1, Disables clean/evict from being pushed to external
    mcr     p15, 1, r5, c15, c0, 0          @ Write Rt to L2ACTLR
    isb
#endif

#if !defined(CONFIG_ARM_PSCI) && !defined(CONFIG_MTK_PSCI)
    ldr     r3, MP1_AXI_CONFIG
    ldr     r2, [r3]
    bic     r2, r2, #0x10
    str     r2, [r3]
    ldr     r3, CCI400_SI3_SNOOP_CONTROL
    ldr     r2, [r3]
    orr     r2, r2, #0x3
    str     r2, [r3]
    ldr     r3, CCI400_STATUS
    b       1f
0:
    dsb
1:
    ldr     r2, [r3]
    tst     r2, #1
    bne     0b
#endif

end:
    b secondary_startup
END(mt_secondary_startup)

