	.section	.cp.const4,	"acM",	@progbits, 4
.cc_top	.patterns.data
	.align	4


pp_1_one:
	.int	0xeeeeeeef
pp_1_zero:
	.int	0xaaaaaaab
pp_N_one_left:
	.int	0xeeeeeeef
pp_N_zero_left:
	.int	0xaaaaaaab
pp_N_one_right:
	.int	0xcccccccd
pp_N_zero_right:
	.int	0x88888889
bitmask_0:
	.int	0x00000001
bitmask_1:
	.int	0x00000002
bitmask_2:
	.int	0x00000004
bitmask_3:
	.int	0x00000008
bitmask_4:
	.int	0x00000010
bitmask_5:
	.int	0x00000020
bitmask_6:
	.int	0x00000040
bitmask_7:
	.int	0x00000080
bitmask_8:
	.int	0x00000100
bitmask_9:
	.int	0x00000200
bitmask_10:
	.int	0x00000400
bitmask_11:
	.int	0x00000800
bitmask_12:
	.int	0x00001000
bitmask_13:
	.int	0x00002000
bitmask_14:
	.int	0x00004000
bitmask_15:
	.int	0x00008000
bitmask_16:
	.int	0x00010000
bitmask_17:
	.int	0x00020000
bitmask_18:
	.int	0x00040000
bitmask_19:
	.int	0x00080000
bitmask_20:
	.int	0x00100000
bitmask_21:
	.int	0x00200000
bitmask_22:
	.int	0x00400000
bitmask_23:
	.int	0x00800000
bitmask_24:
	.int	0x01000000
bitmask_25:
	.int	0x02000000
bitmask_26:
	.int	0x04000000
bitmask_27:
	.int	0x08000000
bitmask_28:
	.int	0x10000000
bitmask_29:
	.int	0x20000000
bitmask_30:
	.int	0x40000000
bitmask_31:
	.int	0x80000000
sample_ones:
	.int	0xffffffff
sample_zeros:
	.int	0x00000000
.cc_bottom	.patterns.data


#define	PORT_S	0
#define	PORT_P	1
#define	TIMER_T	2
#define	ELAPSED_TIME	3
#define	END_TIME	4
#define	START_TIME	5
#define	PORT_S_2	6
#define	PORT_P_2	7
#define	R_PORT_S	r4
#define	R_PORT_P	r5



// void i2s_tdm_asm(out port p, in port s)
// sp[0]: port s
// sp[1]: port p
// sp[2]: timer t
// sp[3]: elapsed_time
// sp[4]: end_time
// sp[5]: start_time
// sp[6]: port s
// sp[7]: port p




.globl	i2s_tdm_asm
.type	i2s_tdm_asm, @function
.text

.cc_top	i2s_tdm_asm.func
.align	2


i2s_tdm_asm:
	entsp	0x9
	stw	r0, sp[PORT_P]
	stw	r1, sp[PORT_S]
	ldw	r0, sp[PORT_P]
	stw	r0, sp[PORT_P_2]
	ldw	r1, sp[PORT_S]
	stw	r1, sp[PORT_S_2]

	ldaw	r0, dp[0x3]
	get	r11, id
	ldw	r0, r0[r11]
	stw	r0, sp[TIMER_T]

	ldw	r6,cp[sample_ones]
	ldw	R_PORT_S,sp[PORT_S]
	ldw	R_PORT_P,sp[PORT_P]

i2s_tdm_asm_loop:
	ldw r0, sp[TIMER_T]
	setc	res[r0], 0x1
	in	r11, res[r0]
	stw	r11, sp[START_TIME]


	ldw	r7,cp[bitmask_0]
	and	r8,r6,r7
	bt	r8,p_0_one
	ldw	r8,cp[pp_1_zero]
	bu	p_0_in
p_0_one:
	ldw	r11,cp[pp_1_one]
p_0_in:
	and	r8,r6,r7
	bf	r8,p_0_out
	or	r3,r3,r8
p_0_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_1]
	and	r8,r6,r7
	bt	r8,p_1_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_1_in
p_1_one:
	ldw	r11,cp[pp_N_one_left]
p_1_in:
	and	r8,r6,r7
	bf	r8,p_1_out
	or	r3,r3,r8
p_1_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_2]
	and	r8,r6,r7
	bt	r8,p_2_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_2_in
p_2_one:
	ldw	r11,cp[pp_N_one_left]
p_2_in:
	and	r8,r6,r7
	bf	r8,p_2_out
	or	r3,r3,r8
p_2_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_3]
	and	r8,r6,r7
	bt	r8,p_3_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_3_in
p_3_one:
	ldw	r11,cp[pp_N_one_left]
p_3_in:
	and	r8,r6,r7
	bf	r8,p_3_out
	or	r3,r3,r8
p_3_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_4]
	and	r8,r6,r7
	bt	r8,p_4_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_4_in
p_4_one:
	ldw	r11,cp[pp_N_one_left]
p_4_in:
	and	r8,r6,r7
	bf	r8,p_4_out
	or	r3,r3,r8
p_4_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_5]
	and	r8,r6,r7
	bt	r8,p_5_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_5_in
p_5_one:
	ldw	r11,cp[pp_N_one_left]
p_5_in:
	and	r8,r6,r7
	bf	r8,p_5_out
	or	r3,r3,r8
p_5_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_6]
	and	r8,r6,r7
	bt	r8,p_6_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_6_in
p_6_one:
	ldw	r11,cp[pp_N_one_left]
p_6_in:
	and	r8,r6,r7
	bf	r8,p_6_out
	or	r3,r3,r8
p_6_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_7]
	and	r8,r6,r7
	bt	r8,p_7_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_7_in
p_7_one:
	ldw	r11,cp[pp_N_one_left]
p_7_in:
	and	r8,r6,r7
	bf	r8,p_7_out
	or	r3,r3,r8
p_7_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_8]
	and	r8,r6,r7
	bt	r8,p_8_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_8_in
p_8_one:
	ldw	r11,cp[pp_N_one_left]
p_8_in:
	and	r8,r6,r7
	bf	r8,p_8_out
	or	r3,r3,r8
p_8_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_9]
	and	r8,r6,r7
	bt	r8,p_9_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_9_in
p_9_one:
	ldw	r11,cp[pp_N_one_left]
p_9_in:
	and	r8,r6,r7
	bf	r8,p_9_out
	or	r3,r3,r8
p_9_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_10]
	and	r8,r6,r7
	bt	r8,p_10_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_10_in
p_10_one:
	ldw	r11,cp[pp_N_one_left]
p_10_in:
	and	r8,r6,r7
	bf	r8,p_10_out
	or	r3,r3,r8
p_10_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_11]
	and	r8,r6,r7
	bt	r8,p_11_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_11_in
p_11_one:
	ldw	r11,cp[pp_N_one_left]
p_11_in:
	and	r8,r6,r7
	bf	r8,p_11_out
	or	r3,r3,r8
p_11_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_12]
	and	r8,r6,r7
	bt	r8,p_12_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_12_in
p_12_one:
	ldw	r11,cp[pp_N_one_left]
p_12_in:
	and	r8,r6,r7
	bf	r8,p_12_out
	or	r3,r3,r8
p_12_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_13]
	and	r8,r6,r7
	bt	r8,p_13_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_13_in
p_13_one:
	ldw	r11,cp[pp_N_one_left]
p_13_in:
	and	r8,r6,r7
	bf	r8,p_13_out
	or	r3,r3,r8
p_13_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_14]
	and	r8,r6,r7
	bt	r8,p_14_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_14_in
p_14_one:
	ldw	r11,cp[pp_N_one_left]
p_14_in:
	and	r8,r6,r7
	bf	r8,p_14_out
	or	r3,r3,r8
p_14_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_15]
	and	r8,r6,r7
	bt	r8,p_15_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_15_in
p_15_one:
	ldw	r11,cp[pp_N_one_left]
p_15_in:
	and	r8,r6,r7
	bf	r8,p_15_out
	or	r3,r3,r8
p_15_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_16]
	and	r8,r6,r7
	bt	r8,p_16_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_16_in
p_16_one:
	ldw	r11,cp[pp_N_one_left]
p_16_in:
	and	r8,r6,r7
	bf	r8,p_16_out
	or	r3,r3,r8
p_16_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_17]
	and	r8,r6,r7
	bt	r8,p_17_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_17_in
p_17_one:
	ldw	r11,cp[pp_N_one_left]
p_17_in:
	and	r8,r6,r7
	bf	r8,p_17_out
	or	r3,r3,r8
p_17_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_18]
	and	r8,r6,r7
	bt	r8,p_18_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_18_in
p_18_one:
	ldw	r11,cp[pp_N_one_left]
p_18_in:
	and	r8,r6,r7
	bf	r8,p_18_out
	or	r3,r3,r8
p_18_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_19]
	and	r8,r6,r7
	bt	r8,p_19_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_19_in
p_19_one:
	ldw	r11,cp[pp_N_one_left]
p_19_in:
	and	r8,r6,r7
	bf	r8,p_19_out
	or	r3,r3,r8
p_19_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_20]
	and	r8,r6,r7
	bt	r8,p_20_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_20_in
p_20_one:
	ldw	r11,cp[pp_N_one_left]
p_20_in:
	and	r8,r6,r7
	bf	r8,p_20_out
	or	r3,r3,r8
p_20_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_21]
	and	r8,r6,r7
	bt	r8,p_21_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_21_in
p_21_one:
	ldw	r11,cp[pp_N_one_left]
p_21_in:
	and	r8,r6,r7
	bf	r8,p_21_out
	or	r3,r3,r8
p_21_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_22]
	and	r8,r6,r7
	bt	r8,p_22_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_22_in
p_22_one:
	ldw	r11,cp[pp_N_one_left]
p_22_in:
	and	r8,r6,r7
	bf	r8,p_22_out
	or	r3,r3,r8
p_22_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_23]
	and	r8,r6,r7
	bt	r8,p_23_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_23_in
p_23_one:
	ldw	r11,cp[pp_N_one_left]
p_23_in:
	and	r8,r6,r7
	bf	r8,p_23_out
	or	r3,r3,r8
p_23_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_24]
	and	r8,r6,r7
	bt	r8,p_24_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_24_in
p_24_one:
	ldw	r11,cp[pp_N_one_left]
p_24_in:
	and	r8,r6,r7
	bf	r8,p_24_out
	or	r3,r3,r8
p_24_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_25]
	and	r8,r6,r7
	bt	r8,p_25_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_25_in
p_25_one:
	ldw	r11,cp[pp_N_one_left]
p_25_in:
	and	r8,r6,r7
	bf	r8,p_25_out
	or	r3,r3,r8
p_25_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_26]
	and	r8,r6,r7
	bt	r8,p_26_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_26_in
p_26_one:
	ldw	r11,cp[pp_N_one_left]
p_26_in:
	and	r8,r6,r7
	bf	r8,p_26_out
	or	r3,r3,r8
p_26_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_27]
	and	r8,r6,r7
	bt	r8,p_27_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_27_in
p_27_one:
	ldw	r11,cp[pp_N_one_left]
p_27_in:
	and	r8,r6,r7
	bf	r8,p_27_out
	or	r3,r3,r8
p_27_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_28]
	and	r8,r6,r7
	bt	r8,p_28_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_28_in
p_28_one:
	ldw	r11,cp[pp_N_one_left]
p_28_in:
	and	r8,r6,r7
	bf	r8,p_28_out
	or	r3,r3,r8
p_28_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_29]
	and	r8,r6,r7
	bt	r8,p_29_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_29_in
p_29_one:
	ldw	r11,cp[pp_N_one_left]
p_29_in:
	and	r8,r6,r7
	bf	r8,p_29_out
	or	r3,r3,r8
p_29_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_30]
	and	r8,r6,r7
	bt	r8,p_30_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_30_in
p_30_one:
	ldw	r11,cp[pp_N_one_left]
p_30_in:
	and	r8,r6,r7
	bf	r8,p_30_out
	or	r3,r3,r8
p_30_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_31]
	and	r8,r6,r7
	bt	r8,p_31_one
	ldw	r8,cp[pp_N_zero_left]
	bu	p_31_in
p_31_one:
	ldw	r11,cp[pp_N_one_left]
p_31_in:
	and	r8,r6,r7
	bf	r8,p_31_out
	or	r3,r3,r8
p_31_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_0]
	and	r8,r6,r7
	bt	r8,p_32_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_32_in
p_32_one:
	ldw	r11,cp[pp_N_one_right]
p_32_in:
	and	r8,r6,r7
	bf	r8,p_32_out
	or	r3,r3,r8
p_32_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_1]
	and	r8,r6,r7
	bt	r8,p_33_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_33_in
p_33_one:
	ldw	r11,cp[pp_N_one_right]
p_33_in:
	and	r8,r6,r7
	bf	r8,p_33_out
	or	r3,r3,r8
p_33_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_2]
	and	r8,r6,r7
	bt	r8,p_34_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_34_in
p_34_one:
	ldw	r11,cp[pp_N_one_right]
p_34_in:
	and	r8,r6,r7
	bf	r8,p_34_out
	or	r3,r3,r8
p_34_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_3]
	and	r8,r6,r7
	bt	r8,p_35_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_35_in
p_35_one:
	ldw	r11,cp[pp_N_one_right]
p_35_in:
	and	r8,r6,r7
	bf	r8,p_35_out
	or	r3,r3,r8
p_35_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_4]
	and	r8,r6,r7
	bt	r8,p_36_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_36_in
p_36_one:
	ldw	r11,cp[pp_N_one_right]
p_36_in:
	and	r8,r6,r7
	bf	r8,p_36_out
	or	r3,r3,r8
p_36_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_5]
	and	r8,r6,r7
	bt	r8,p_37_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_37_in
p_37_one:
	ldw	r11,cp[pp_N_one_right]
p_37_in:
	and	r8,r6,r7
	bf	r8,p_37_out
	or	r3,r3,r8
p_37_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_6]
	and	r8,r6,r7
	bt	r8,p_38_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_38_in
p_38_one:
	ldw	r11,cp[pp_N_one_right]
p_38_in:
	and	r8,r6,r7
	bf	r8,p_38_out
	or	r3,r3,r8
p_38_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_7]
	and	r8,r6,r7
	bt	r8,p_39_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_39_in
p_39_one:
	ldw	r11,cp[pp_N_one_right]
p_39_in:
	and	r8,r6,r7
	bf	r8,p_39_out
	or	r3,r3,r8
p_39_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_8]
	and	r8,r6,r7
	bt	r8,p_40_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_40_in
p_40_one:
	ldw	r11,cp[pp_N_one_right]
p_40_in:
	and	r8,r6,r7
	bf	r8,p_40_out
	or	r3,r3,r8
p_40_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_9]
	and	r8,r6,r7
	bt	r8,p_41_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_41_in
p_41_one:
	ldw	r11,cp[pp_N_one_right]
p_41_in:
	and	r8,r6,r7
	bf	r8,p_41_out
	or	r3,r3,r8
p_41_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_10]
	and	r8,r6,r7
	bt	r8,p_42_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_42_in
p_42_one:
	ldw	r11,cp[pp_N_one_right]
p_42_in:
	and	r8,r6,r7
	bf	r8,p_42_out
	or	r3,r3,r8
p_42_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_11]
	and	r8,r6,r7
	bt	r8,p_43_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_43_in
p_43_one:
	ldw	r11,cp[pp_N_one_right]
p_43_in:
	and	r8,r6,r7
	bf	r8,p_43_out
	or	r3,r3,r8
p_43_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_12]
	and	r8,r6,r7
	bt	r8,p_44_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_44_in
p_44_one:
	ldw	r11,cp[pp_N_one_right]
p_44_in:
	and	r8,r6,r7
	bf	r8,p_44_out
	or	r3,r3,r8
p_44_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_13]
	and	r8,r6,r7
	bt	r8,p_45_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_45_in
p_45_one:
	ldw	r11,cp[pp_N_one_right]
p_45_in:
	and	r8,r6,r7
	bf	r8,p_45_out
	or	r3,r3,r8
p_45_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_14]
	and	r8,r6,r7
	bt	r8,p_46_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_46_in
p_46_one:
	ldw	r11,cp[pp_N_one_right]
p_46_in:
	and	r8,r6,r7
	bf	r8,p_46_out
	or	r3,r3,r8
p_46_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_15]
	and	r8,r6,r7
	bt	r8,p_47_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_47_in
p_47_one:
	ldw	r11,cp[pp_N_one_right]
p_47_in:
	and	r8,r6,r7
	bf	r8,p_47_out
	or	r3,r3,r8
p_47_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_16]
	and	r8,r6,r7
	bt	r8,p_48_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_48_in
p_48_one:
	ldw	r11,cp[pp_N_one_right]
p_48_in:
	and	r8,r6,r7
	bf	r8,p_48_out
	or	r3,r3,r8
p_48_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_17]
	and	r8,r6,r7
	bt	r8,p_49_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_49_in
p_49_one:
	ldw	r11,cp[pp_N_one_right]
p_49_in:
	and	r8,r6,r7
	bf	r8,p_49_out
	or	r3,r3,r8
p_49_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_18]
	and	r8,r6,r7
	bt	r8,p_50_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_50_in
p_50_one:
	ldw	r11,cp[pp_N_one_right]
p_50_in:
	and	r8,r6,r7
	bf	r8,p_50_out
	or	r3,r3,r8
p_50_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_19]
	and	r8,r6,r7
	bt	r8,p_51_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_51_in
p_51_one:
	ldw	r11,cp[pp_N_one_right]
p_51_in:
	and	r8,r6,r7
	bf	r8,p_51_out
	or	r3,r3,r8
p_51_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_20]
	and	r8,r6,r7
	bt	r8,p_52_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_52_in
p_52_one:
	ldw	r11,cp[pp_N_one_right]
p_52_in:
	and	r8,r6,r7
	bf	r8,p_52_out
	or	r3,r3,r8
p_52_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_21]
	and	r8,r6,r7
	bt	r8,p_53_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_53_in
p_53_one:
	ldw	r11,cp[pp_N_one_right]
p_53_in:
	and	r8,r6,r7
	bf	r8,p_53_out
	or	r3,r3,r8
p_53_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_22]
	and	r8,r6,r7
	bt	r8,p_54_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_54_in
p_54_one:
	ldw	r11,cp[pp_N_one_right]
p_54_in:
	and	r8,r6,r7
	bf	r8,p_54_out
	or	r3,r3,r8
p_54_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_23]
	and	r8,r6,r7
	bt	r8,p_55_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_55_in
p_55_one:
	ldw	r11,cp[pp_N_one_right]
p_55_in:
	and	r8,r6,r7
	bf	r8,p_55_out
	or	r3,r3,r8
p_55_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_24]
	and	r8,r6,r7
	bt	r8,p_56_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_56_in
p_56_one:
	ldw	r11,cp[pp_N_one_right]
p_56_in:
	and	r8,r6,r7
	bf	r8,p_56_out
	or	r3,r3,r8
p_56_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_25]
	and	r8,r6,r7
	bt	r8,p_57_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_57_in
p_57_one:
	ldw	r11,cp[pp_N_one_right]
p_57_in:
	and	r8,r6,r7
	bf	r8,p_57_out
	or	r3,r3,r8
p_57_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_26]
	and	r8,r6,r7
	bt	r8,p_58_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_58_in
p_58_one:
	ldw	r11,cp[pp_N_one_right]
p_58_in:
	and	r8,r6,r7
	bf	r8,p_58_out
	or	r3,r3,r8
p_58_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_27]
	and	r8,r6,r7
	bt	r8,p_59_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_59_in
p_59_one:
	ldw	r11,cp[pp_N_one_right]
p_59_in:
	and	r8,r6,r7
	bf	r8,p_59_out
	or	r3,r3,r8
p_59_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_28]
	and	r8,r6,r7
	bt	r8,p_60_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_60_in
p_60_one:
	ldw	r11,cp[pp_N_one_right]
p_60_in:
	and	r8,r6,r7
	bf	r8,p_60_out
	or	r3,r3,r8
p_60_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_29]
	and	r8,r6,r7
	bt	r8,p_61_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_61_in
p_61_one:
	ldw	r11,cp[pp_N_one_right]
p_61_in:
	and	r8,r6,r7
	bf	r8,p_61_out
	or	r3,r3,r8
p_61_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_30]
	and	r8,r6,r7
	bt	r8,p_62_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_62_in
p_62_one:
	ldw	r11,cp[pp_N_one_right]
p_62_in:
	and	r8,r6,r7
	bf	r8,p_62_out
	or	r3,r3,r8
p_62_out:
	out	res[R_PORT_P],r11


	ldw	r7,cp[bitmask_31]
	and	r8,r6,r7
	bt	r8,p_63_one
	ldw	r8,cp[pp_N_zero_right]
	bu	p_63_in
p_63_one:
	ldw	r11,cp[pp_N_one_right]
p_63_in:
	and	r8,r6,r7
	bf	r8,p_63_out
	or	r3,r3,r8
p_63_out:
	out	res[R_PORT_P],r11


// t :> end_time;
	setc	res[r0], 0x1
	in	r0, res[r0]
	stw	r0, sp[END_TIME]
// elapsed_time = end_time - start_time;
	ldw	r1, sp[START_TIME]
	sub	r0, r0, r1
	stw	r0, sp[ELAPSED_TIME]


	bu	i2s_tdm_asm_loop


.cc_bottom	i2s_tdm_asm.func


