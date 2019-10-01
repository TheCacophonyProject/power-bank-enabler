; pic10F220PPctrl.asm
;
; Function:
; PIC10F220 for control of Power Pack (PP)
; Reference:
;	"CacophonyPowerpackController.docx"
;	KiCad PCB project: "CacPP_PIC10.pro"
;
; Designed to operate with Kogan power bank model KAPBQCPD20A
; which has a battery capacity = 20Ah @ 3.7V and rated capacity = 14Ah @ 5V, 1A
;
; PP 5V output (USB connector) automatically shuts down to standby mode after 30 seconds when output current < ~60mA
; When PP switches its 5V output off the voltage goes to 0V for 130 ms then takes about 30 ms to rise to 2.3V
; (measured with PIC circuit connected)
; In standby mode the PP output is 2.35V OC and has an internal resistance of ~10K
; With PIC10 connected the standby voltage is ~2.34V at PP and 2.29V at PIC Vcc (50mV drop across BAT54)
;
; In order to turn on the PP output the load current must first drop to below 10uA
; PP output turns on when load current increases from < 10uA to > 10uA
;
; A pFET in series with the PP output allows the external load to be isolated.
; The PIC10 circuit is powered directly via Schottky diode from the non-isolated PP output (normally 2.35V)
; and draws 1.5 uA average.
;
; The PIC10 is normally in SLEEP mode with its WDT running and wakes up every ~3.2s when the WDT expires
; Every 22s (approx) an ADC conversion is done to read the internal 0.6V reference from which the voltage at Vcc
; can be tested. The 22s interval between reads ensures that if the 5V is turned on manually then the pFET will
; be enabled within the 30s period before the 5V automatically shuts down.
;
; The PIC10 periodically (every 24 hours) turns on the pFET in order to allow an external device (phone)
; to top up its own battery from the PP. On turning on the pFET if the load exceeds 60mA then the PP will keep its
; output enabled at 5V but the PP will turn off automatically once the load has dropped below 60mA for 30s.
; When the PP output turns off a diode from GP3/MCLR to Vin causes the PIC10 to immediately wake up (pin change)
; so that it can turn off the pFET before the PP output starts to rise back to 2.3V (else it will be retriggered).
; The PIC then starts timing the next power cycle.
;
; At power up the resistor from GP0 to 0V is tested (forms resistor divide with 10K pullup to GP2)
; and used to select the cycle period (default = open cct)
;
; NB. Unlike most PICs the PIC10F22x WDT wakeup generates a RESET so operation always starts from the RESET vector
; Firmware must read the STATUS bits (PD* and TO*) to determine the cause of the RESET
; For power on reset the PD* and TO* bits will both be 1
; For WDT reset from sleep the PD* and TO* bits will both be 0
; The clrwdt instruction sets PD* = 1 and TO* = 1
; The sleep instruction sets PD* = 0 and TO* = 1
;
; author	Ewen Fraser, ArchEng Designs Ltd.
; 07 Jul 2019	original
; 22 Jul 2019	enable AN0 (GP0 = input only) & use for programmable cycle time
;		weak pullup typ = 250uA @ 5V (100uA @ 2V)?
;		enable weak pullup & read AN0 (voltage due to weak PU through R to 0V)
;		-> select cycle time in range 1 hour to 24 hour. This method is probably too variable!
;		debug_out now a subroutine
; 23 Jul 2019	connect GP2 to GP0 with 100K and use as pullup of R-divider to set cyclemax
;		save a 2nd copy of cyclemax and use to verify initialisation was done
;		use clrwdt to set PD* = TO* = 1 as a precaution
;		debug_out final high bit is 4 us (not cut short) 
; 24 Jul 2019	reduce resistor divider values to meet ADC requirement, pullup = 10K
;		weak pullup on GP_TEST not used
;		change to single pulse at power up and 3 pulses at cycle end
;		go_2_sleep ensures GP_DEBUG and GP_TEST are both output low to prevent floating
;		always output Vref to DEBUG pin
; 27 Jul 2019	make GP3/MCLR a digital input so can wakeup on pin change using capacitor to Vin
;		Wakeup on change & weak pullup enabled for GP3 input while 5V is on
;		defined flags.fl_5Von and use to control OPTION bits GPPU and GPWU
;		only make GP_TEST an input (no weak pullup) for AN0 measurement in powerup
;		ok to drive GP_DEBUG high while GP_TEST = output low (10K -> 230uA @ 2.3V, 500uA @ 5V)
; 29 Jul 2019	changed ADC_5VTHR from 48 to 49 to reflect typical Vcc levels
;		renamed cyclemax,cyclemax2 to cycleprd,cycleprd2
;		defined CYCLEMAX, CYCLEMIN
; 05 Aug 2019	defined TM60MIN, changed tmr30min to tmr60min
;		changed programmed cycle periods, min = 1 hour, max = 72 hours, default = 36 hours
; 10 Sep 2019	changed default to 24 hours (pulldown only) and use 10K/33K for 36 hours
; 12 Sep 2019	change behaviour to work with other power packs with slower turn off:
;		WDT period reduced to 17ms while 5V is on
;		rename fl_5Von to fl_pFETon
;		rename check_5V to check_Vcc
;		While pFET is on check Vref every WDT period instead of every 22s
;		change ADC_5VTHR from 49 to 38 for fast detection of falling voltage at end of charge cycle.
;		defined SWVERS = 100 & output to debug pin
; 13 Sep 2019	SWVERS = 101
;		goto start_pwr_cycle when pFET is turned off as a result of Vcc dropping below 4V
;		so treated same as for wakeup on pin change
;
; CPU = PIC10F220 - operates 2.0 - 5.5V & has ADC with 0.6V ref
;
; Operate CPU at Fosc = 8MHz (Tosc = 125 ns)
; => Fosc/4 = 2MHz
; tcyc = 4 * Tosc = 0.5us
;
;
;****************************************************************************

;	PROCESSOR	10F220		; this is specified in MPLabX Project properties, Device
;	RADIX		dec		; this is specified in MPLabX Project properties, mpasm


	#include <p10F220.inc>        ; processor specific variable definitions
;	#include <p10F222.inc>        ; for prototype only

	INCLUDE	MACRO.asm

; RAM is just 16 bytes (18 in PIC10F222)

RAMBEG		equ	H'0010'	; start of g.p. registers
RAMEND		equ	H'001F'	; end of g.p. registers

; define direction bit (lower case)...
w	equ	0	; selects destination = working register
self	equ	1	; selects destination = file register

;****************************************************************************

; Configuration bits:

; Fosc = 8MHz
; GP3 = digital input
; WDT is enabled
; Code is protected

	__CONFIG	_IOSCFS_8MHZ & _MCPU_OFF & _WDTE_ON & _CP_ON & _MCLRE_OFF

;****************************************************************************

; Constants, Port definitions, SFR initial values

; GPIO pin definitions
; Port direction (0 = output, 1 = input) is controlled by TRIS GPIO instruction

				; (x) = pin # (SOT23-6)
GP_3		equ	3	; (6) GP3/MCLR*/VPP = digital input
				; (5) Vdd (min 2.0V, max 5.5V, abs max 6.5v)
GP_DEBUG	equ	2	; (4) GP2/T0CKI/FOSC4 = Debug output
GP_PFET		equ	1	; (3) GP1/AN1/ICSPCLK = pFET gate, 0 = pFET on
				; (2) Vss (0V)
GP_TEST		equ	0	; (1) GP0/AN0/ICSPDAT = Test input/analog input


GPIO_INIT	equ	b'00000010'	; GPIO (0x006)
					; DEBUG low, pFET off
					; (3) GP3/MCLR* = 0, (don't care)
					; (2) GP_DEBUG = 0
					; (1) GP_PFET = 1, pFET off
					; (0) GP_TEST = 0, (output low)

; Make GP_TEST an output low in case no resistors are fitted
; to avoid floating and unpredicatable ADC reading at power up

TRIS_INIT	equ	b'00001000'	; GPIO (0x06)
					; (3) GP3/MCLR* = 1, input
					; (2) GP_DEBUG = 0, output
					; (1) GP_PFET = 0, output
					; (0) GP_TEST = 0, output

; Make GP_TEST an input prior to reading R divider at AN0
 
TRIS_TEST	equ	b'00001001'	; GPIO (0x06)
					; (3) GP3/MCLR* = 1, input
					; (2) GP_DEBUG = 0, output
					; (1) GP_PFET = 0, output
					; (0) GP_TEST = 1, input

;	----------------------------------------------------

; OPTION_REG written by OPTION instruction 

OPTION_INIT	equ	b'11011111'	; OPTION_REG
					; (7) GPWU* = 1, disable wakeup on change
					; (6) GPPU* = 1, disable weak pullups
					; (5) T0CS = 0, TMR0 clk = Fosc/4 (don't select T0CKI) *3
					; (4) T0SE = 1, TMR0 src edge (don't care)
					; (3) PSA = 1, prescaler assigned to WDT
					; (2:0) PS[2:0] = 111, WDT prescaler 1:128 (~3.2s @2V)

; Prior to going to sleep when 5V is turned on enable wakeup on (GP3) pin change
; and enable weak pullup (on GP3) so that 5V turn-off falling edge is detected
; Set WDT prescaler to 000 (1:1) for nominal 17ms period in case COS wakeup fails
; This allows pFET to be turned off as soon as possible after 5V is turned off
; to prevent the load retriggering the PP as its output rises again from 0V towards 2.35V

OPTION_5V	equ	b'00011000'	; OPTION_REG
					; (7) GPWU* = 0, enable wakeup on change *1
					; (6) GPPU* = 0, enable weak pullups *1 *2
					; (5) T0CS = 0, TMR0 clk = Fosc/4 (don't select T0CKI) *3
					; (4) T0SE = 1, TMR0 src edge (don't care)
					; (3) PSA = 1, prescaler assigned to WDT
					; (2:0) PS[2:0] = 000, WDT prescaler 1:1 (~17ms @5V)

; *1 Wakeup on change & weak pullup enabled specifically for GP3 input
; *2 Weak pullup typ = 113K @ 2V, typ = 22K @ 5V (datasheet table 10-1, p56)
; *3 T0CS = 1 would select T0CKI as TMR0 clock source and override TRIS for GP2 to make T0CKI an input

;	----------------------------------------------------

; Watchdog and Timer 0

; A single prescaler can be assigned to either the Watchdog timer or to TMR0
; With no prescaler (assigned to TMR0) the watchdog timeout period is nominally 17ms @ 5V
; but is typically 25ms at 2.25V (datasheet fig 11-7)
; Watchdog prescaler can be set to 1,2,4,8,16,32,64 or 128
; Maximum watchdog timeout period (prescaler = 128) is 2.2 seconds (at 5V)
; Maximum watchdog timeout period (prescaler = 128) is 3.2 seconds (at 2.25V)
;
; Timer 0 clock source is either osc/4 or the external clock input T0CKI
; The clock source can be scaled down by 1,2,4,8,16,32,64,128 or 256
;
; Timer 0 free-runs (increments) unless the PIC is in sleep mode
;
; For this application:
; TMR0 is not used
; WDT is enabled with period ~3.2s while pFET is off (2V)
; WDT is enabled with period ~17ms while pFET is on (5V)

;	----------------------------------------------------

; A/D converter config

; The ADC has a fixed clock (INTOSC/4) and a conversion takes 13 TAD = 13 tcyc
; Voltage reference = Vss (fixed)

ADCON0_INIT	equ	b'00000000'	; ADCON0 (0x007)
					; (7) ANS1 = 0, GP1 = digital i/o
					; (6) ANS0 = 0, GP0 = digital i/o
					; (5,4) undefined
					; (3,2) CHS[1,0] = 00, select AN0
					; (1) GO_NOT_DONE = 0
					; (0) ADON = 0, ADC disabled

; Voltage at AN0 is read at power up with 10K pullup to GP2
; Resistor between AN0 and 0V determines cycle period

ADCON0_TEST	equ	b'01000001'	; ADCON0 (0x007)
					; (7) ANS1 = 0, GP1 = digital i/o
					; (6) ANS0 = 1, GP0 = AN0
					; (5,4) undefined
					; (3,2) CHS[1,0] = 00, select AN0
					; (1) GO_NOT_DONE = 0
					; (0) ADON = 1, ADC enabled

; Internal 0.6V reference is read every 23s to determine if 5V is on or off

ADCON0_VREF	equ	b'00001101'	; ADCON0 (0x007)
					; (7) ANS1 = 0, GP1 = digital i/o
					; (6) ANS0 = 0, GP0 = digital i/o
					; (5,4) undefined
					; (3,2) CHS[1,0] = 11, 0.6V reference
					; (1) GO_NOT_DONE = 0
					; (0) ADON = 1, ADC enabled


;****************************************************************************
;
;	RAM definitions
;
;****************************************************************************

; RAM occupies only one bank (bank 0)

	CBLOCK	RAMBEG		; start of general purpose RAM
countwdt:	1	; WDT cycle counter (only used if pFET is off)
tmr60min:	1	; approximate 60 minute timer
cyclecnt:	1	; power cycle counter (x 60min)
cycleprd:	1	; cycle period (x 60min) = cyclecnt re-load value
testvolts:	1	; voltage at AN0 at power up - sets cycle time
refvolts:	1	; internal voltage reference
dbg_byte:	1	; for debugging
count:		1	; general purpose loop counter
cycleprd2:	1	; copy of cycle time for RAM test
flags:		1	; only 1 bit for now
spare:		6	; unused
endmark:	0
	ENDC

	if endmark-1 > RAMEND
	error "RAM overflow"
	endif

; flags bits:
fl_pFETon	equ	0	; pFET is turned on



;****************************************************************************
;
;	Constants
;
;****************************************************************************

SWVERS	equ	101	; S/W version 1.01

; WDT period varies with Vcc, being longer at lower voltage (datasheet fig 11-7)
; Since the power cycle period is measured from when the pFET is turned off it is only during the PP standby
; when Vcc ~2.3V that the WDT period is important for timer maintenance

CNTWD2V	equ	7	; x 3.2s (WDT period at 2.3V ~25ms x 128) = 22.4s

TM60MIN	equ	161	; x 22.4s = ~60min

; Power cycle period is a multiple of 60 min (tmr60min)
; Determined by resistor(s):
; Fixed 10K pullup (R5) from GP_DEBUG to GP_TEST (AN0), not fitted for default
; Varied pulldown (R6) from GP_TEST (AN0) to 0V, or 33K for default (0V)
;
; For default period:
; With neither R5 nor R6 fitted AN0 is floating (GP0 WPU is disabled)
; However measurements show ADC values typically << 80 but can be higher so for default
; a pulldown (R6) is fitted to ensure that ADC reading is close to 0
;
; If 10K pullup is fitted but R6 is NOT fitted then ADC value will be close to 0xFF

; At POR, with GP_DEBUG driven high the voltage at AN0 is read and from the ADC value
; a cycle period is selected.
;
; Ideal values:
; R6  ratio  ADC : hex  Cycle period (multiples of 60 min)
;                         T6 = 72 hours
; 90K   0.90   230 = xE6  -------------- threshold 6
; 56K   0.85   216 = xD8  T5 = 48 hours
; 42K   0.81   206 = xCE  -------------- threshold 5
; 33K   0.77   196 = xC4  T4 = 36 hours
; 27K   0.73   186 = xBA  -------------- threshold 4
; 22K   0.69   175 = xAF  T3 = 12 hours
; 18K   0.64   164 = xA4  -------------- threshold 3
; 15K   0.60   153 = x99  T2 = 6 hours
; 12K2  0.55   140 = x8C  -------------- threshold 2
; 10K   0.50   128 = x80  T1 = 1 hour
; 4K6   0.32    81 = x51  -------------- threshold 1
;                         T0 = 24 hours (default)

; ADC thresholds as above:
AN0_THR6	equ	230
AN0_THR5	equ	206
AN0_THR4	equ	186
AN0_THR3	equ	164
AN0_THR2	equ	140
AN0_THR1	equ	81

; Cycle periods (in hours) corresponding to the ADC regions:
CYCLET6		equ	72
CYCLET5		equ	48
CYCLET4		equ	36
CYCLET3		equ	12
CYCLET2		equ	6
CYCLET1		equ	1
CYCLET0		equ	24	; default

CYCLEMAX	equ	72	; hours
CYCLEMIN	equ	1	; hour


; ADC thresholds for determining Vcc and hence checking if Vin is at 5V or 2V
; The value of Vcc is determined by reading the 0.6V internal reference
; Vref ADC value = 255 * 0.6 / Vcc
; When 5V is turned on Vcc ~ 4.95
; When 5V is turned off Vcc ~ 2.29V
;
; Vcc	ADC value
; 4.95	31 expected value when 5V is on
; 4.50	34
; 4.00	38
; 3.62	42 midpoint of voltage range
; 3.50	44
; 3.00	51
; 2.50	61
; 2.29	67 expected value when 5V is off

; Set threshold for switching pFET on/off
ADC_5VTHR	equ	38	; 4.0V


;****************************************************************************
;
;	Code starts here
;
;****************************************************************************

; Device Reset Timer (DRT) holds CPU in reset for ~1.125 ms after MCLR* reaches 
; Measured ~1.8 ms from MCLR* high till first pulse on debug pin

; Note. PIC10F220 reset vector is at 0x00FF
; This location contains a factory programmed movlw xx instruction
; with xx = OSC calibration value
; After executing the movlw xx instruction the program counter wraps to 0x0000


	ORG	0

	andlw	b'11111110'		; FOSC4 = 0 (redundant, should already be 0)	
	movwf	OSCCAL			; write OSC calibration value (in w)

	movlw	OPTION_INIT		; select maximum WDT period, disable weak pullup
	OPTION

	movlw	TRIS_INIT
	TRIS	GPIO

	movlw	ADCON0_INIT		; disable ADC, GP0,GP1 = digital i/o
	movwf	ADCON0

	; Check for wakeup from sleep
	; The STATUS bits (GPWUF, TO* and PD*) indicate the cause of the RESET
	; GPWUF = 1 if woke up due to pin change
	; For power on reset the TO* and PD* bits will both be 1
	; For WDT reset from sleep the TO* and PD* bits will both be 0
	; The clrwdt instruction sets TO* = 1 and PD* = 1
	; The sleep instruction sets TO* = 1 and PD* = 0
	; TO* -> 1 by POR, clrwdt instruction or sleep instruction and -> 0 by WDT
	; PD* -> by POR or clrwdt instruction and -> 0 by sleep instruction
	;
	; GPWUF TO* PD*	cause of RESET
	;   1   1   0   wakeup on pin change (requires GPWU* = 0)
	;   0   1   1   POR
	;   0   0   0   WDT wakeup from sleep
	;   0   0   1   WDT reset not from sleep (assumes PD* was set by POR or clrwdt)
	;   0   1   0   MCLR wakeup from sleep (**)
	;   0   u   u   MCLR reset not from sleep (u = unchanged, **)
	;
	; ** MCLR reset is not possible since MCLR is disabled (_MCLRE_OFF)

	btfsc	STATUS, GPWUF		; GPWUF = 1 if woke up due to pin change
	goto	wake_change

	; Only go to wake_up if both bits are 0
	; otherwise treat as POR

	btfss	STATUS, NOT_PD		; PD* = 0 after sleep
	btfsc	STATUS, NOT_TO		; TO* = 0 after WDT reset
	goto	powerup

	; PD* = TO* = 0
	clrwdt				; set PD* = TO* = 1

	goto	wake_up

;	-----------------------------------------------

	; Here for Wake up on (GP3) pin change
	; Only GP3/MCLR* is an input during sleep
	; Reason for wakeup = step change in Vin 5V -> 0V as PP turns off
	; 2V -> 5V step will not trigger a change as GPWU* = 1
	; Turn off pFET immediately

wake_change:
	clrwdt				; set PD* = TO* = 1

	; Here also after wakeup if Vcc has fallen below ADC_5VTHR while pFET was on

start_pwr_cycle:
	movlw	GPIO_INIT		; DEBUG low, pFET off
	movwf	GPIO			; initialise port data latch

	bcf	flags, fl_pFETon	; pFET is OFF

	; 2x 1 us pulses to indicate start of power cycle

	bsf	GPIO, GP_DEBUG
	nop
	bcf	GPIO, GP_DEBUG
	nop
	bsf	GPIO, GP_DEBUG
	nop
	bcf	GPIO, GP_DEBUG

	; Re-load timers for next power cycle

	movlw	OPTION_INIT		; select maximum WDT period, disable weak pullup
	OPTION

	movlw	CNTWD2V			; restart 22s timer
	movwf	countwdt

	movlw	TM60MIN			; restart 60min timer
	movwf	tmr60min

	; As a precaution check for corrupt (or uninitialised RAM)
	; cycleprd & cycleprd2 must be equal and > CYCLEMIN-1 and < CYCLEMAX+1
	; if not then do initialisation as for POR

	if (CYCLEMIN-1)
	error "assumed by code"
	endif

	movf	cycleprd, w
	btfsc	STATUS, Z		; zero?
	goto	powerup

	xorwf	cycleprd2, w
	btfss	STATUS, Z		; different?
	goto	powerup
	
	bgek	cycleprd, CYCLEMAX+1, powerup

	; cycle period is valid
	movf	cycleprd, w		; restart cycle count
	movwf	cyclecnt

	goto	go_2_sleep		; go back to sleep

;	-----------------------------------------------

	; Here for Power on Reset (POR)
	; Initialise pins, RAM variables
	; Test resistor divider at AN0 to select cycle period

powerup:
	clrwdt				; set PD* = TO* = 1

	movlw	GPIO_INIT		; DEBUG low, pFET off
	movwf	GPIO			; initialise port data latch

	bcf	flags, fl_pFETon	; pFET is OFF

	; single 1 us pulse to indicate POR

	bsf	GPIO, GP_DEBUG
	nop
	bcf	GPIO, GP_DEBUG

	; make GP_TEST an input prior to AN0 ADC reading so that pin voltage
	; reaches expected level based on resistive divider

	movlw	TRIS_TEST
	TRIS	GPIO

	; Put GP_DEBUG (GP2) high again to enable resistor divider at AN0
	; A second resistor (R6) from GP_TEST to 0V sets the voltage at AN0
	; GP2 - R5 - AN0 - R6 - 0V

	bsf	GPIO, GP_DEBUG		; 15 us pulse

	movlw	ADCON0_TEST		; enable ADC for GP_TEST = AN0
	movwf	ADCON0

	; allow 6 us acquisition time
	call	delay_2us
	call	delay_2us
	call	delay_2us

	bsf	ADCON0, GO_NOT_DONE	; start a/d conversion

	; Wait for A/D conversion to complete (GO = 0, 13 tcyc = 6.5us)
wt4adc_lp1:
	btfsc	ADCON0, GO_NOT_DONE
	goto	wt4adc_lp1

	bcf	GPIO, GP_DEBUG

	movlw	ADCON0_INIT		; disable ADC, GP0,GP1 = digital i/o
	movwf	ADCON0

	movlw	TRIS_INIT		; TEST = output low
	TRIS	GPIO

	movf	ADRES, w		; get a/d result
	movwf	testvolts		; save AN0 voltage
	call	debug_out		; output to debug pin (so can verify with scope)

	; Determine power cycle period from AN0 value

	bgek	testvolts, AN0_THR6, cycle_T6	; pulldown > 100K or open circuit
	bgek	testvolts, AN0_THR5, cycle_T5
	bgek	testvolts, AN0_THR4, cycle_T4
	bgek	testvolts, AN0_THR3, cycle_T3
	bgek	testvolts, AN0_THR2, cycle_T2
	bltk	testvolts, AN0_THR1, cycle_T0	; no 10K pullup OR < 4K7 pulldown

;cycle_T1:
	movlw	CYCLET1
	goto	cycle_time

cycle_T2:
	movlw	CYCLET2
	goto	cycle_time

cycle_T3:
	movlw	CYCLET3
	goto	cycle_time

cycle_T4:
	movlw	CYCLET4
	goto	cycle_time

cycle_T5:
	movlw	CYCLET5
	goto	cycle_time

cycle_T6:
	movlw	CYCLET6
	goto	cycle_time

cycle_T0:
	movlw	CYCLET0			; default cycle count
cycle_time:
	movwf	cycleprd
	movwf	cycleprd2		; copy for RAM test

	call	debug_out		; output to debug pin (so can verify with scope)

	; Initialise timers for power cycle

	; first 5V check is ~ 22s after power up (assuming 5V is off)
	; will be sooner due to faster WDT if 5V is on
	movlw	CNTWD2V			; start 22s timer
	movwf	countwdt

	; first pFET cycle starts ~ 1 minute after power up
	; nominally 3 *22s = 66s
	movlw	3 
	movwf	tmr60min

	movlw	1			; so times out at first update
	movwf	cyclecnt

	movlw	SWVERS			; S/W version
	call	debug_out		; output to debug pin (so can verify with scope)

;****************************************************************************
;
;			Main loop
;
;****************************************************************************

go_2_sleep:
	movf	GPIO, w			; dummy read to arm pin-change wakeup
	sleep				; sets PD* = 0 and TO* = 1

;	zzzzzzzzzzzzzzzz............ZZZZZZZZZZZZZZZZ

;	-----------------------------------------------

; Wake from sleep (WDT wakeup)
; PIC10F22x WDT wakeup from sleep generates a RESET which means PC always starts from reset vector
; Need to jump here after wakeup, having checked PD* = TO* = 0

; OPTION_REG has already been loaded assuming 2V (standby) mode
;
; If pFET is off:
; Maintain WDT count (countwdt) and wait for time out before
;	Restart countwdt
;	Check Vcc and maintain timers (tmr60min and cyclecnt)
;
; If pFET is on:
; Reload OPTION_REG for short WDT period & weak pullup on & wakeup on pin change
; Check Vcc


wake_up:
	btfss	flags, fl_pFETon	; Check if pFET is on
	goto	wu_standby

	; pFET is on (expect Vcc to be 5V)

	movlw	OPTION_5V		; select short WDT period, enable weak pullup & wakeup on pin change
	OPTION

	goto	check_Vcc		; check Vcc every wakeup 


; pFET is off (power pack in standby, Vin ~ 2.3V)

wu_standby:
	decfsz	countwdt, self
	goto	go_2_sleep		; go back to sleep

	; every 22s ...

	movlw	CNTWD2V			; restart 22s timer
	movwf	countwdt

	; Maintain 60 min timer

	decfsz	tmr60min, self
	goto	check_Vcc

	; every 60 minutes ...
		
	movlw	TM60MIN			; restart 60 min timer
	movwf	tmr60min

	; Maintain power cycle timer

	decfsz	cyclecnt, self
	goto	check_Vcc

	; Power cycle has ended ...
	; Cycle period will be restarted (again) when PP turns off so this is
	; somewhat redundant

	movf	cycleprd, w		; restart cycle count
	movwf	cyclecnt

	bsf	GPIO, GP_DEBUG		; 3 pulses (1 us) at cycle end
	nop
	bcf	GPIO, GP_DEBUG
	nop
	bsf	GPIO, GP_DEBUG
	nop
	bcf	GPIO, GP_DEBUG
	nop
	bsf	GPIO, GP_DEBUG
	nop
	bcf	GPIO, GP_DEBUG

	; Turn on pFET to force 5V to turn on
	; The power pack doesn't immediately put its output to 5V
	; Vin will drop from 2.3V depending on load and may go to 0V for 300ms or more before switching to 5V
	; Vcc will drop slowly and typically reaches 2V before the 5V is turned on
	; and Vcc rapidly increases to nearly 5V
	; During this transition to 5V keep WDT period at maximum (~3.2s) so that 5V will
	; have been established well before Vcc is next checked
	; Don't enable weak pullup or wakeup on pin change until 5V is established
	; else Vcc will discharge through diode D2
	; The pFET will stay on until either a wakeup on pin change (if 5V drops fast enough)
	; or Vref reading (check_Vcc) shows that the Vcc has dropped below ADC_5VTHR
	 
	bcf	GPIO, GP_PFET		; put PFET gate low to turn it on
	bsf	flags, fl_pFETon	; pFET is now on

	goto	go_2_sleep		; go back to sleep

;	-----------------------------------------------

	; Test the value of Vcc by reading 0.6V internal reference to determine if 5V is turned on
	; If ADC reading < ADC_5VTHR turn on pFET else turn off pFET

	; No need for hysteresis since Vcc will normally be close to 5V or close to 2.3V
	; and transitions through the threshold should be smooth

check_Vcc:
	movlw	ADCON0_VREF		; enable ADC for 0.6V ref
	movwf	ADCON0

	; allow 6 us acquisition time
	call	delay_2us

	; 1x 2.5 us  pulse takes 4 us
	bsf	GPIO, GP_DEBUG
	call	delay_2us
	bcf	GPIO, GP_DEBUG
	nop				; 1 tcyc
	nop				; 1 tcyc

	bsf	ADCON0, GO_NOT_DONE	; start a/d conversion

	; Wait for A/D conversion to complete (GO = 0, 13 tcyc = 6.5us)
wt4adc_lp2:
	btfsc	ADCON0, GO_NOT_DONE
	goto	wt4adc_lp2

	movlw	ADCON0_INIT		; disable ADC, GP0,GP1 = digital i/o
	movwf	ADCON0

	movf	ADRES, w		; get a/d result
	movwf	refvolts		; save int ref voltage

	bltk	refvolts, ADC_5VTHR, fet_on

	; 5V is off so turn off the pFET (if not already off)
	; If pFET is currently on then restart cycle time
	
	bsf	GPIO, GP_PFET		; put PFET gate high to turn it off

	btfsc	flags, fl_pFETon	; if pFET has just been turned off 
	goto	start_pwr_cycle		; start a new power cycle

	movlw	OPTION_INIT		; select maximum WDT period, disable weak pullup
	OPTION

	movlw	CNTWD2V			; start 22s timer
	movwf	countwdt

	goto	output_Vref

	; 5V is on so turn on the pFET (if not already on)
	; NB. PP 5V may have been turned on manually with PP button
fet_on:
	bcf	GPIO, GP_PFET		; put PFET gate low to turn it on
	bsf	flags, fl_pFETon	; pFET is ON

	movlw	OPTION_5V		; select short WDT period, enable weak pullup & wakeup on pin change
	OPTION

	; Output the ADC reading on debug pin

output_Vref:
	movf	refvolts, w		; get ref voltage
	call	debug_out

	goto	go_2_sleep		; go back to sleep

;	-----------------------------------------------

	; Debug output:
	; Write byte (in w) to GP_DEBUG pin MSbit first
	; Each bit is preceded by a high pulse lasting 2 tcyc (1 us)
	; followed by actual bit level for ~4 us
	; observed values:
	; 0x1F (31) when 5V is on
	; 0x42 (66) when 5V is off

debug_out:
	movwf	dbg_byte		; save byte to output
	movlw	8			; 8 bits to send
	movwf	count

dbg_wr_lp:
	bsf	GPIO, GP_DEBUG		; start with a high pulse 2 tcyc
	rlf	dbg_byte, self		; bit 7 first
	bcf	GPIO, GP_DEBUG
	btfss	STATUS, C		; 1/2 tcyc
	goto	bitend			; 2 tcyc

	; data bit = 1
	bsf	GPIO, GP_DEBUG		; 1 tcyc
bitend:
	nop				; 1 tcyc
	nop				; 1 tcyc
	decfsz	count, self		; 1 tcyc
	goto	dbg_wr_lp		; 2 tcyc

	; delay so final high is also 4 us

	nop				; 1 tcyc
	nop				; 1 tcyc
	nop				; 1 tcyc
	bcf	GPIO, GP_DEBUG		; pin low at end
	
	; call + retlw = 4 tcyc = 2 us
delay_2us:
	retlw	0

;-----------------------------------------------------------------

; Check if code has exceeded program memory (MPLABX does this!)

	if $ > 0xFE
	error	"code overflow"
	endif

;	-----------------------------------------------


	END


