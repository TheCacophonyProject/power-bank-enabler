PIC for control of Power Pack (PP)

CPU = PIC10F220 (used PIC10F222 for prototype)

Originally used PIC10F320 (see F320PPctrl_proto)
But PIC10F22x operates over 2.0 to 5.5V so better choice

Notes:
Build project using MPLabX IDE (load PIC10 project group)
Running at 8MHz
Program using MPLab IPE
NB. Power supplied by PICkit3 (has to be enabled under power settings)

Determine how low Vcc can go before PIC stops working - check for the 3 pulses at startup (RESET)

With PIC10F22x can clear PSA bit so WDT has no prescaler -> 18ms timeout

When powerpack switches its 5V output off the voltage goes to 0V for ~130 ms
then takes about ~30 ms to rise to 2.3V
Need diode in series to prevent PIC supply from dropping

21/07/2019
Measured 1.5uA from 2.3V
5uA from 5V
Vcc = 2.29V when Vin = 2.34V

Problem:
1uF cap takes ~1s to discharge below 1V, >4s to drop to 0.5V
CPU doesn't get a POR unless Vcc is below 0.5V

put 100nF // 2M2 between Vcc and 0V
no good Vcc dips to ~1V when 5V turns off

put 1uF // 2M2 between Vcc and 0V
When 5V turns off Vcc drops smoothly to 2.3V

now draws 20uA while 5V is on, dropping to 5uA then 2uA when 5V is off ?
Try removing the 2M2 again:
Check that actually always starts executing even though doesn't initialise if power is briefly lost
? 

Vin at 2.35V
If Vcc is shorted to 0V to discharge cap then first debug pulse is 3.5 - 4ms after MCLR rises
and debug is high for 4.7us then low 2us then the expected powerup sequence of 1us pulses
However if Vcc is not discharged then just see the expected powerup 1us pulse sequence and this is 1.8ms after MCLR rises

Vin at 5V
Same behaviour but only 1ms between MCLR rising and first pulse

Extra 4.7us pulse must be due to GPIO latch being undefined at POR

The initialisation (as below) is 13 tcyc from reset to powerup (including movlw at 0xFF) = 6.5us
assuming the test of countwdt fails so goto powerup is taken
	ORG	0
	
	movwf	OSCCAL		; write osc calibration value (in w)

	movlw	OPTION_INIT
	OPTION

	movlw	TRIS_INIT
	TRIS	GPIO		<< start of 4.7us pulse DEBUG pin high

	movlw	ADCON0_INIT
	movwf	ADCON0

	; As a precaution, in case initialisation wasn't done
	movf	countwdt, w
	andlw	0xF0
	btfss	STATUS, Z		; upper nibble should be 0
	goto	powerup      << must come here for 9 tcyc pulse

	btfss	STATUS, NOT_PD		; PD* = 0 after sleep
	goto	wake_up

powerup:
	movlw	GPIO_INIT
	movwf	GPIO		<< end of 4.7us pulse, DEBUG pin low
		
Tried 100pF cap on TEST - would need much longer than a few uS to charge
With 22pF charged fully
TODO try R divider with DEBUG - 1M - TEST - varR - 0V

with 1M between GP2 and GP0 takes too long for voltage to rise at AN0
Try 180K (1M//220K) => ~1.5V ADC value = 0xAD = 173/255 = 0.68
Current is now ~1uA
Test with 100K pullup and various resistors from TEST to 0V
100K - O/C  => xE6 = 230/255 = 0.90 -> 48 = 24h
100K - 270K => xAA = 170/255 = 0.66 -> 24 = 12h
100K - 220K => xA3 = 163/255 = 0.63 -> 12 = 6h
100K - 150K => x92 = 146/255 = 0.57 -> 12 = 6h
100K - 100K => x7E = 126/255 = 0.49 -> 6 = 3h
100K - 56K  => x5C = 92/255 = 0.36 -> 2 = 1h
100K - 33K  => x40 = 64/255 = 0.25 -> 1 = 30min
These are in reasonable agreement with expected thresholds
but thresholds for Rvar > 100K need to be reduced slightly
or higher value resistors used

TODO:
Test current with min Rvar (33K)
Test digital level of GP_TEST - low to enable output of Vref values?
Expect to need < 50K to get logic low (100K//113K) @ 2V
but < 20K at 5V
Is 2us long enough ??
Retest ADC values vs Rvar at 5V
? Could temporarily turn on weak pullup to speed up powerup
? could wait a few more us to see if Van0 rises further
? add large R 3M3? from Vcc to 0V - check time to discharge < 0.4V

24/7/2019
Use weak pullup as well as 100K to pull up AN0 then turn off WPU
3us delay after ADON before start ADC
Test thresholds using 500K pot

270K C8 200	24h
250K C6 198	24h
240K C0 192	12h
170K AF 175	12h
150K A4 164	12h
140K A0 160	6h
120K 96 150	6h
105K 8D 141	6h
100K 8B 139	6h


; 470K   0.82    210  -------------- threshold
; 330K   0.77    196  -------------- threshold
; 270K   0.73    186  24 => 12 hours
; 220K   0.69    176  24 => 12 hours
; 180K   0.64    164  -------------- threshold
; 150K   0.60    153  12 => 6 hours
; 120K   0.55    139  -------------- threshold
; 100K   0.50    128  6 => 3 hours
; 82K    0.45    115  -------------- threshold
; 56K    0.36     92  2 => 1 hour
; 47K    0.32     81  -------------- threshold
; 33K    0.25     63  1 => 30 min

fit 4M7 from Vcc to 0V to discharge 1uF cap
no longer use weak pullup
no delay between ADON and ADC

100K 5V x80-x83 = 128-131
100K 2V x8B-x90 = 139-144
add 100pF across Rvar to 0V
100K 7F at 5V and 2V
56K x5F-x68 at 2V, x5A at 5V   90-104
33K x4E-x53 at 2V, x41 at 5V   65-83

Best results when 5V is turned on

Try 10K pullup GP2 to GP0
Tested with 100K pot to 0V
All AN0 ADC readings are close to expected and correct cycle times result
Set new thresholds based on 10K pullup and pulldowns in range 10K to 100K
all working reliably
Current = 1.2uA at 2V
~ 10uA when 5V is on

26/07/2019
Discovered that all testing had been with an LED and resistor as a dummy load
With an additional resistor (500K) the PP turns back on again almost immediately after turning off
When 5V turns off and goes to 0V the pFET is still on (for up to 20s) and the the small load current
from the 500K resistor is enough to turn the PP back on when its output rises back to 2.3V
TODO - test to find out exactly when the output turns on again

Possible solutions:
1. Diode + small cap in series from MCLR* to Vin so when Vin drops suddenly from 5V to 0V the PIC will be reset
Modify the startup code to test for a MCLR RESET and immediately turn off pFET and begin the next 24h cycle.

2. Simply remove the BAT54C diode so that PIC looses power and resets when 5V turns off.
Is that guaranteed to turn off the pFET? MCLR reset should make all GPi = inputs but pFET gate won't have a pullup

3. Don't go to sleep if 5V is on - keep checking Vcc - but would need to read Vcc every 50ms or faster to detect 5V drop
This would use more power though only while 5V is on

4. Can wakeup on port change be used? Probably could if don't use resistors for setting cycle time
Could configure GP3/MCLR as digital input with wake up on pin change - ? easier to distinguish from other resets
as there is a dedicated STATUS bit (GPWUF)
But all resets other than WDT reset will cause TRIS to go to 1111 (all inputs) so pFET gate will be floating
- how long does it take pFET to turn off when GP1 = input? (weak pullup disabled)
But MCLR reset is probably just as good as pin change?

Options 1 or 4 are best
Already checking RAM (cyclemax, cyclemax2). Need a different indication on debug if go to powerup from RAM test rather than from POR
Could add more RAM to test (16 bit pattern?)
Could add an operating state variable? INIT=waiting for first short cycle to end, 2V = FET off, 5V = FET on
Is the test of TO*, PD* needed?
MCLR allows up to 13V wrt Vss so ok to capacitively couple without diode to Vin which can be 3V higher than Vcc when 5 turns on

27/07/2019
Test WU on pin change:
Load = LED + R // 1K5 (3mA @5V)
Need diode from GP3 to Vin as Vin drops too slowly (though probably ok if load is closer to 60mA limit)
See 3x 2 pulses about 32us apart = wakeup on pin change as Vgp3 is hovering close to logic threshold (Vcc/2)
Add 150R load (~35mA) Vgp3 drops from 5V to ~1V in ~0.8ms but decays very slowly after that so due to GP3 being very close to logic
threshold there are 3 wakeup on pin change events ~32 - 35us apart
The first WUPin change is ~800 us after 5V begins to turn off and pFET is turned off at same time

If weak pullup OR wakeup on change or both are enabled ONLY when 5V is turned on then expect to get only one
wakeup on change event

TODO:
Try turning off GPWU and GPPU when go to sleep if Vcc = 2V
Only need to turn these on prior to sleep when 5V
That will mean there is no WPU on TEST when reading R divider

Problem: now seeing 200uA if R divider is fitted 10K,33K - seems to be due to GP0 being input most of the time ?
Fix: GP0 now only input for AN0 reading else output low
Current now 1.2uA @2.3V and ~10uA @5V
Tested all nominal Rvar values at 2v and 5V using PP and all give expected values within +/- 2 ADC counts

Problem: Cannot program in situ with 1N4148 diode on MCLR - need to fit after ICSP (note on schematic)

? Need to reduce the 4M7 so cap discharges faster - very slow once gets to 0.5V
Can reduce Vcc to 0V by adding 10K between Vcc and GP3/MCLR - GP3 must sink current since 1N4148 won't
However on prototype unit (in tiny plastic box) Vcc continues to discharge below 0.5V and after 5-6 seconds
it always resets with POR (starts at powerup:)
However the prototype often powers up with GP_DEBUG (GP2) high for 5.5 us and GP_TEST (GP0) high for 4.5 us before powerup
code initialises GPIO to GPIO_INIT when the pins go low (in 20 ns).
4.5 us before GPIO_INIT corresponds with TRIS_INIT (GP0 -> output)
5.5 us before GPIO_INIT corresponds with OPTION_INIT (T0CS -> 0 => GP2 -> output)
RESET typically > 3 ms after plugging in (~ 1ms after Vcc reaches 2V) 
After the single 1 us pulse on GP_DEBUG it goes high for 15.5 us as expected.

On prototype with no resistors on TEST pin the AN0 reading can sometimes be > 81 (floating!!!)
so fit a 100K pulldown from TEST to 0V: Now always selects 24h as required
If load (LED+330 // 1K5 // 150) is connected when plug into PP the 5V output normally turns on immediately
If load is connected after PP connection then startup sequence is as expected with 5V turning on after 1 minute
when pFET is enabled. Need to describe the plug in sequence in documentation

See scope captures

Tested with my cellphone:
Doesn't charge even though 5V on
USB + and - are not connected. Must need to be
With USB bus connected the iPhone charges but need to check if PP turns off and on again
Refer USB charging specifications - eg. see TPS2513A in Reference\USB 
Isolate D+ and D- from PP but connect 200 ohm between D+ and D- on output (USB socket)
Now iPhone charges

My iPhone charging at 90% charged = 400mA (need to use 10A range on meter else charging stops)
Charge current = 600 - 700mA when phone battery is low

Testing with bird recorder for a few days suggests that the top up cycle could be longer than 24 hours.
Idea: Increase the 30 min internal timer to 60 min to double all times & allow up to 72 hr cycle

10 Sep 2019
Load first PCB with PIC10F220
Programmed then fitted 1N4148 diode
R5 = NF, R6 = 33K -> AN0 = 0V -> default = 24 hours
R1 = 2M2 as don't have any larger value SMD resistors
Test:
GP2 goes high for 5.5us before the 1us POR pulse
AN0 value is 0x00 and cycle value is 0x18 = 24 hours as expected
At 2V the Vcc ADC reading is 0x42 = 66 as expected
At 5V the Vcc ADC reading is 0x1F = 31 as expected
All good so far

PROBLEM 1:
With Large Solar powered pack (model ES982S) with minimum load (180R = 28mA) to cause PP to automatically go to standby after 30s:
When 5V turns off the voltage drops too slowly: 2ms to drop from 5V to 2V
As a consequence of the slow drop, the change of state of port GP3 is not detected so PIC doesn't wakeup
and voltage continues to drop as does the PIC supply voltage (though more slowly at about 1V per 6ms)
The PIC supply can fall below the operating voltage before the PIC wakes up due to WDT
With no load at cct output the PP output drops from 5V to 2V in ~4ms and to ~0.4V after ~50ms
The output stays at 0.4V for 500ms then ramps up to 2.3V in about 50ms
cf Kogan power bank which turns off 5V -> 2V in ~200us and triggers a change of state (COS) wakeup in ~700us

NB. The reason that Vcc drops quickly is because the internal weak pullup is enabled while 5V is on and so GP3 can source ~250uA
when Vin < Vcc (Vgp3). It is essential that the weak internal pullup is turned off as soon as possible after Vin drops so that Vcc
is not discharged.

The smaller solar PP (SUNSAVER) does work (triggers a COS wakeup on turning off 5V) although its turn off is still slower than
the Kogan power bank taking about 2ms to drop 5V to 2V and triggers COS wakeup after ~13.5ms

Tried replacing diode D2 with a pFET (FDN338P 1=gate=Vin, 2=S=GP3, 3=D=0V) in attempt to switch GP3 low with falling Vin but GP3
still falls too slowly to generate a COS wakeup. Instead got a COS wakeup almost immediately after Q1 was turned on at end of cycle.

PROBLEM 2:
At present the weak pullp is enabled as soon as the pFET turns on at the end of each power cycle.
But the PP takes 372ms (Kogan) or longer to turn on its 5V and during that time Vin = 0V so Vcc will discharge via D2 if GP3 weak
pullpup is enabled.

SOLUTION:
While 5V is on the PIC either stays awake or reduce WDT period to minimum (18ms) so PIC can constantly monitor its supply more often
If Vcc drops then treat this as power pack having gone to standby
Don't enable weak internal pullup on GP3 until after 5V has turned on
?BETTER:
Remove diode D2 (don't use GP3, leave internal pullup off) and instead rely on short WDT period to sample Vcc more often
Without the pullup enabled Vcc will discharge much slower so WDT period can be > 18ms
But pFET must be turned off within ~100ms of 5V turning off to ensure that load is removed well before the PP starts to ramp
back to 2.3V else it may retrigger its 5V output

1uF cap discharges from 5V to 2V in ~700ms => ~430mV per 100ms
WDT prescale divider 1:1 -> 17ms (DS says 18ms typ. but also has graph of WDT vs voltage that suggests 17ms at 5V)

Test new firmware V1.00
Now outputs SWVER (0x64) after cycle value at end of powerup
When pFET is on WDT period = 17ms as expected
Reads and outputs Vref value every 17ms and when 5V turns off the value slowly increases from 0x1F -> 0x26
With diode D2 NOT fitted:
Typically 4 x 17ms WDT periods (70ms) but can be > 100ms after 5V turns off before Vcc drops to 4V threshold (ADC_5VTHR equ 38 =0x26)
and pFET is turned off
With diode D2 fitted (weak pullup current causes Vcc to discharge faster):
About 9 - 24ms after 5V turns off before Vcc drops to 4V and pFET is turned off

Problem:
When pFET is turned on the ES982S PP output drops from 2V to 0V for 442ms before 5V turns on - see later!!!
During this time the PIC (1uA) and R1 (0.5uA) cause Vcc (C1) to discharge below 2V
Testing with R1 = 2M2 instead of 4M7 -> 2uA total load on Vcc => Vcc drops to ~1.5V before 5V turns on
Remove R1 -> Vcc discharges to ~1.8V before 5V turns on
R1 is only used to discharge C1 faster when device is unplugged. Can omit R1 as long as device is unplugged for say 10s before plugging in again.

May need to increase C1 to 2u2?

Later:
Discovered that with a phone instead of a 180R resistor Vin doesn't collapse to 0V on pFET turn on so Vcc only drops slowly to about 2V
before 5V turns on

Idea:
Could set FET switching Vcc threshold to say 5 or 6 ADC counts (bits) higher than the actual (or minimum) reading at 5V to allow for
variation in internal reference and Vcc voltage. <<--- NOT implemented as fixed threshold (4.0V) works well

Updated firmware to V1.01 (101 = 0x65)
Jumps to start_pwr_cycle when pFET is turned off as a result of Vcc dropping below 4.0V

Test with BAT54 across D2
Now see COS when 5V turns off - typically 4ms after 5V starts to turn off
In hindsight a BAT54 would have been better than 1N4148 (though I was concerned by reverse leakage/noise through Schottky especially
since GP3 was asumed to be configured as MCLR when PCB was designed)
If a suitable 2-pin SOD123 Schottky can be found then can replace the 1N4148

Test all 10 units:
Verify POR sequence (0x00, 0x18, 0x65)
Verify 2V AN0 reading 0x41
Verify end cycle 3 pulses, 5V on
Verify 18ms 5V readings 0x1F
Verify 2 pulses at start of cycle, 5V off
R1 (4M7) not fitted for first 10 devices
All work as expected

Ideas:
Could increase C1 from 1uF to 2uF to reduce Vcc drop while PP is transitioning from 2V to 5V
May need to fit R1 (4M7) to make power up more reliable?
A larger C1 may make wakeup on pin change more likely?
