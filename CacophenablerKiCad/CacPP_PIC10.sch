EESchema Schematic File Version 4
LIBS:CacPP_PIC10-cache
EELAYER 29 0
EELAYER END
$Descr A4 11693 8268
encoding utf-8
Sheet 1 1
Title ""
Date ""
Rev ""
Comp ""
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
$Comp
L Device:Q_PMOS_GSD Q1
U 1 1 5D231FFA
P 6850 1900
F 0 "Q1" V 7193 1900 50  0000 C CNN
F 1 "FDN340P" V 7102 1900 50  0000 C CNN
F 2 "Package_TO_SOT_SMD:SOT-23" H 7050 2000 50  0001 C CNN
F 3 "~" H 6850 1900 50  0001 C CNN
	1    6850 1900
	0    1    -1   0   
$EndComp
$Comp
L power:GND #PWR06
U 1 1 5D23560B
P 9500 5350
F 0 "#PWR06" H 9500 5100 50  0001 C CNN
F 1 "GND" H 9505 5177 50  0000 C CNN
F 2 "" H 9500 5350 50  0001 C CNN
F 3 "" H 9500 5350 50  0001 C CNN
	1    9500 5350
	1    0    0    -1  
$EndComp
$Comp
L Device:CP C1
U 1 1 5D235C63
P 2850 3150
F 0 "C1" H 2968 3196 50  0000 L CNN
F 1 "1uF 10V" H 2968 3105 50  0000 L CNN
F 2 "Capacitor_SMD:C_0603_1608Metric_Pad1.05x0.95mm_HandSolder" H 2888 3000 50  0001 C CNN
F 3 "~" H 2850 3150 50  0001 C CNN
	1    2850 3150
	1    0    0    -1  
$EndComp
$Comp
L SamacSys_Parts:2410_06-SamacSys_Parts J3
U 1 1 5D39450B
P 8500 1800
F 0 "J3" H 8900 2065 50  0000 C CNN
F 1 "2410_06" H 8900 1974 50  0000 C CNN
F 2 "KiCad:2410_06" H 9150 1900 50  0001 L CNN
F 3 "http://downloads.lumberg.com/datenblaetter/2410_06.pdf" H 9150 1800 50  0001 L CNN
F 4 "Horizontal USB chassis socket Type A SMT Lumberg Right Angle Version 2.0 Type A USB Connector SMT Socket, 750 V, 1A" H 9150 1700 50  0001 L CNN "Description"
F 5 "" H 9150 1600 50  0001 L CNN "Height"
F 6 "7378791" H 9150 1500 50  0001 L CNN "RS Part Number"
F 7 "https://uk.rs-online.com/web/p/products/7378791" H 9150 1400 50  0001 L CNN "RS Price/Stock"
F 8 "LUMBERG" H 9150 1300 50  0001 L CNN "Manufacturer_Name"
F 9 "2410 06" H 9150 1200 50  0001 L CNN "Manufacturer_Part_Number"
	1    8500 1800
	1    0    0    -1  
$EndComp
$Comp
L Device:R R6
U 1 1 5D3F9A2B
P 5750 5000
F 0 "R6" H 5820 5046 50  0000 L CNN
F 1 "33K" H 5820 4955 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 5680 5000 50  0001 C CNN
F 3 "~" H 5750 5000 50  0001 C CNN
	1    5750 5000
	1    0    0    -1  
$EndComp
$Comp
L Device:R R5
U 1 1 5D3F9BD7
P 5750 4350
F 0 "R5" H 5820 4396 50  0000 L CNN
F 1 "10K NF" H 5820 4305 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 5680 4350 50  0001 C CNN
F 3 "~" H 5750 4350 50  0001 C CNN
	1    5750 4350
	1    0    0    -1  
$EndComp
$Comp
L Device:R R1
U 1 1 5D3FA22E
P 2250 3200
F 0 "R1" H 2320 3246 50  0000 L CNN
F 1 "4M7 NF" H 2320 3155 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 2180 3200 50  0001 C CNN
F 3 "~" H 2250 3200 50  0001 C CNN
	1    2250 3200
	1    0    0    -1  
$EndComp
$Comp
L Device:D D2
U 1 1 5D3FCB03
P 5800 2150
F 0 "D2" V 5754 2229 50  0000 L CNN
F 1 "1N4148" V 5845 2229 50  0000 L CNN
F 2 "Diode_SMD:D_SOD-123" H 5800 2150 50  0001 C CNN
F 3 "~" H 5800 2150 50  0001 C CNN
	1    5800 2150
	0    1    1    0   
$EndComp
$Comp
L power:GND #PWR03
U 1 1 5D40160F
P 2850 5350
F 0 "#PWR03" H 2850 5100 50  0001 C CNN
F 1 "GND" H 2855 5177 50  0000 C CNN
F 2 "" H 2850 5350 50  0001 C CNN
F 3 "" H 2850 5350 50  0001 C CNN
	1    2850 5350
	1    0    0    -1  
$EndComp
$Comp
L power:GND #PWR04
U 1 1 5D401CBA
P 5750 5350
F 0 "#PWR04" H 5750 5100 50  0001 C CNN
F 1 "GND" H 5755 5177 50  0000 C CNN
F 2 "" H 5750 5350 50  0001 C CNN
F 3 "" H 5750 5350 50  0001 C CNN
	1    5750 5350
	1    0    0    -1  
$EndComp
Wire Wire Line
	2850 3300 2850 3850
$Comp
L +My_Library:USB_A_plug J1
U 1 1 5D407111
P 1500 2000
F 0 "J1" H 1557 2467 50  0000 C CNN
F 1 "USB_A" H 1557 2376 50  0000 C CNN
F 2 "KiCad:USB_A_Molex_48037_2200" H 1650 1950 50  0001 C CNN
F 3 " ~" H 1650 1950 50  0001 C CNN
	1    1500 2000
	1    0    0    -1  
$EndComp
$Comp
L Connector_Generic:Conn_01x05 J2
U 1 1 5D407A3A
P 7500 3850
F 0 "J2" H 7580 3892 50  0000 L CNN
F 1 "ICSP interface" H 7580 3801 50  0000 L CNN
F 2 "Connector_Harwin:Harwin_M20-89005xx_1x05_P2.54mm_Horizontal" H 7500 3850 50  0001 C CNN
F 3 "~" H 7500 3850 50  0001 C CNN
	1    7500 3850
	1    0    0    -1  
$EndComp
$Comp
L +My_Library:PIC10F220-IOT U1
U 1 1 5D40A3CE
P 4350 3850
F 0 "U1" H 4350 4417 50  0000 C CNN
F 1 "PIC10F220-IOT" H 4350 4326 50  0000 C CNN
F 2 "Package_TO_SOT_SMD:SOT-23-6" H 4400 4500 50  0001 L CIN
F 3 "http://ww1.microchip.com/downloads/en/DeviceDoc/41270E.pdf" H 4350 3850 50  0001 C CNN
	1    4350 3850
	1    0    0    -1  
$EndComp
Wire Wire Line
	4950 3850 5100 3850
Wire Wire Line
	5100 3850 5100 2600
Wire Wire Line
	5100 2600 2850 2600
Connection ~ 2850 2600
Wire Wire Line
	2850 2600 2850 3000
Wire Wire Line
	2250 2600 2850 2600
Wire Wire Line
	2250 2600 2250 3050
Wire Wire Line
	3750 3850 2850 3850
Connection ~ 2850 3850
Wire Wire Line
	2850 3850 2850 5350
Wire Wire Line
	2250 3350 2250 3850
Wire Wire Line
	4950 3650 5800 3650
Wire Wire Line
	5800 3650 5800 2600
Wire Wire Line
	5800 2000 5800 1800
Connection ~ 5800 1800
Wire Wire Line
	5800 1800 6650 1800
Wire Wire Line
	4950 4050 5750 4050
Wire Wire Line
	5750 4050 5750 4200
Wire Wire Line
	5750 4500 5750 4700
Wire Wire Line
	5750 5150 5750 5350
Connection ~ 5750 4700
Wire Wire Line
	5750 4700 5750 4850
Wire Wire Line
	5100 2600 5300 2600
Connection ~ 5100 2600
Wire Wire Line
	5600 2600 5800 2600
Connection ~ 5800 2600
Wire Wire Line
	5800 2600 5800 2300
$Comp
L power:GND #PWR01
U 1 1 5D4217AB
P 1500 5350
F 0 "#PWR01" H 1500 5100 50  0001 C CNN
F 1 "GND" H 1505 5177 50  0000 C CNN
F 2 "" H 1500 5350 50  0001 C CNN
F 3 "" H 1500 5350 50  0001 C CNN
	1    1500 5350
	1    0    0    -1  
$EndComp
Wire Wire Line
	1800 2000 2300 2000
Wire Wire Line
	2300 2000 2300 1100
Wire Wire Line
	8350 1100 8350 1900
Wire Wire Line
	8350 1900 8500 1900
Wire Wire Line
	9300 1800 9450 1800
Wire Wire Line
	2450 2100 1800 2100
Wire Wire Line
	9500 5350 9500 1900
Wire Wire Line
	9500 1900 9300 1900
Wire Wire Line
	3750 4050 3350 4050
Wire Wire Line
	3350 4050 3350 3150
Wire Wire Line
	3350 3150 6850 3150
Wire Wire Line
	6850 3150 6850 2100
$Comp
L Device:R R4
U 1 1 5D2487DF
P 5450 2600
F 0 "R4" V 5550 2550 50  0000 L CNN
F 1 "10K NF" V 5350 2450 50  0000 L CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 5380 2600 50  0001 C CNN
F 3 "~" H 5450 2600 50  0001 C CNN
	1    5450 2600
	0    1    1    0   
$EndComp
$Comp
L Device:R R7
U 1 1 5D42C56A
P 8900 1100
F 0 "R7" V 8693 1100 50  0000 C CNN
F 1 "200" V 8784 1100 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 8830 1100 50  0001 C CNN
F 3 "~" H 8900 1100 50  0001 C CNN
	1    8900 1100
	0    1    1    0   
$EndComp
$Comp
L Device:R R2
U 1 1 5D42C820
P 4500 1100
F 0 "R2" V 4293 1100 50  0000 C CNN
F 1 "0 NF" V 4384 1100 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 4430 1100 50  0001 C CNN
F 3 "~" H 4500 1100 50  0001 C CNN
	1    4500 1100
	0    1    1    0   
$EndComp
$Comp
L Device:R R3
U 1 1 5D42D19A
P 4500 1400
F 0 "R3" V 4293 1400 50  0000 C CNN
F 1 "0 NF" V 4384 1400 50  0000 C CNN
F 2 "Resistor_SMD:R_0603_1608Metric_Pad1.05x0.95mm_HandSolder" V 4430 1400 50  0001 C CNN
F 3 "~" H 4500 1400 50  0001 C CNN
	1    4500 1400
	0    1    1    0   
$EndComp
Wire Wire Line
	4650 1100 8350 1100
Wire Wire Line
	4650 1400 9450 1400
Wire Wire Line
	9450 1400 9450 1800
Wire Wire Line
	2300 1100 4350 1100
Wire Wire Line
	4350 1400 2450 1400
Wire Wire Line
	2450 1400 2450 2100
Wire Wire Line
	8350 1100 8750 1100
Connection ~ 8350 1100
Wire Wire Line
	9050 1100 9450 1100
Wire Wire Line
	9450 1100 9450 1400
Connection ~ 9450 1400
Text Notes 8600 2100 0    50   ~ 0
USB output socket
Text Notes 1300 1350 0    50   ~ 0
USB input plug
Wire Wire Line
	5800 3650 7300 3650
Connection ~ 5800 3650
Wire Wire Line
	5500 3750 5500 3850
Wire Wire Line
	5500 3850 5100 3850
Connection ~ 5100 3850
$Comp
L power:GND #PWR05
U 1 1 5D43F1F1
P 6650 5350
F 0 "#PWR05" H 6650 5100 50  0001 C CNN
F 1 "GND" H 6655 5177 50  0000 C CNN
F 2 "" H 6650 5350 50  0001 C CNN
F 3 "" H 6650 5350 50  0001 C CNN
	1    6650 5350
	1    0    0    -1  
$EndComp
Wire Wire Line
	6650 3850 6650 5350
Wire Wire Line
	6400 3950 6400 4700
Wire Wire Line
	6400 4700 5750 4700
Wire Wire Line
	7300 4050 6850 4050
Wire Wire Line
	6850 4050 6850 3150
Connection ~ 6850 3150
Text Label 6950 4050 0    50   ~ 0
ICSPCLK
Text Label 6950 3950 0    50   ~ 0
ICSPDAT
Text Label 6950 3850 0    50   ~ 0
GND
Text Label 6950 3750 0    50   ~ 0
VCC
Text Label 6950 3650 0    50   ~ 0
MCLR
Text Label 5250 4050 0    50   ~ 0
DEBUG
Text Label 3600 3650 0    50   ~ 0
AN0
NoConn ~ 1400 2400
$Comp
L Device:D_Schottky_AAK D1
U 1 1 5D495B72
P 2850 2250
F 0 "D1" V 2921 2162 50  0000 R CNN
F 1 "BAT54C" V 2830 2162 50  0000 R CNN
F 2 "Package_TO_SOT_SMD:SOT-23" H 2850 2250 50  0001 C CNN
F 3 "~" H 2850 2250 50  0001 C CNN
	1    2850 2250
	0    -1   -1   0   
$EndComp
Wire Wire Line
	2850 2400 2850 2600
Wire Wire Line
	2850 2050 2850 1950
Connection ~ 2850 1800
Wire Wire Line
	2850 1800 3300 1800
Wire Wire Line
	1800 1800 2850 1800
Wire Wire Line
	2750 2050 2750 1950
Wire Wire Line
	2750 1950 2850 1950
Connection ~ 2850 1950
Wire Wire Line
	2850 1950 2850 1800
$Comp
L Connector:TestPoint TP2
U 1 1 5D427293
P 3300 1700
F 0 "TP2" H 3358 1818 50  0000 L CNN
F 1 "Vin" H 3358 1727 50  0000 L CNN
F 2 "KiCad:SolderWirePad_1x01_SMD_1.5x5mm" H 3500 1700 50  0001 C CNN
F 3 "~" H 3500 1700 50  0001 C CNN
	1    3300 1700
	1    0    0    -1  
$EndComp
Wire Wire Line
	3300 1700 3300 1800
Connection ~ 3300 1800
Wire Wire Line
	1150 3000 1150 3150
Wire Wire Line
	1150 3150 1500 3150
Wire Wire Line
	2850 3850 2250 3850
Wire Wire Line
	3500 3650 3500 4700
Wire Wire Line
	3500 3650 3750 3650
Wire Wire Line
	3500 4700 5750 4700
Connection ~ 1500 3150
Wire Wire Line
	1500 2400 1500 3150
Wire Wire Line
	3300 1800 5800 1800
Wire Wire Line
	1500 3150 1500 5350
$Comp
L Connector:TestPoint TP1
U 1 1 5D4756FA
P 1150 3000
F 0 "TP1" H 1208 3118 50  0000 L CNN
F 1 "0V_in" H 1208 3027 50  0000 L CNN
F 2 "KiCad:SolderWirePad_1x01_SMD_1.5x5mm" H 1350 3000 50  0001 C CNN
F 3 "~" H 1350 3000 50  0001 C CNN
	1    1150 3000
	1    0    0    -1  
$EndComp
Wire Wire Line
	7050 1800 8500 1800
Text Label 2000 1800 0    50   ~ 0
Vin
Text Label 7650 1800 0    50   ~ 0
Vout
$Comp
L Connector:TestPoint TP3
U 1 1 5D4C346F
P 6000 4050
F 0 "TP3" H 6058 4168 50  0000 L CNN
F 1 "Debug" H 6058 4077 50  0000 L CNN
F 2 "TestPoint:TestPoint_Pad_D1.5mm" H 6200 4050 50  0001 C CNN
F 3 "~" H 6200 4050 50  0001 C CNN
	1    6000 4050
	1    0    0    -1  
$EndComp
Wire Wire Line
	6000 4050 5750 4050
Connection ~ 5750 4050
Wire Wire Line
	7300 3750 5500 3750
Wire Wire Line
	7300 3850 6650 3850
Wire Wire Line
	7300 3950 6400 3950
Text Notes 4450 2150 0    50   ~ 0
Fit D2 after programming PIC
$EndSCHEMATC
