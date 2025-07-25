[![Join the chat at https://gitter.im/rene-dev/stmbl](https://badges.gitter.im/rene-dev/stmbl.svg)](https://gitter.im/rene-dev/stmbl?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge) <a href="https://matrix.to/#/@stmbl:freakontrol.com"><img src="https://img.shields.io/badge/order%20-stmbl-green.svg"/></a>

DISCLAIMER
===

THE AUTHORS OF THIS SOFTWARE ACCEPT ABSOLUTELY NO LIABILITY FOR
ANY HARM OR LOSS RESULTING FROM ITS USE.  IT IS _EXTREMELY_ UNWISE
TO RELY ON SOFTWARE ALONE FOR SAFETY.  Any machinery capable of
harming persons must have provisions for completely removing power
from all motors, etc, before persons enter any danger area.  All
machinery must be designed to comply with local and national safety
codes, and the authors of this software can not, and do not, take
any responsibility for such compliance.

This software is released under the GPLv3.

STMBL
=====

This Repository is a fork of the original project [STMBL](https://github.com/rene-dev/stmbl), an open-source servo drive designed for Retrofitting CNC machines and Robots. It supports Industrial AC and DC servos.

You can read the [documentation](https://freakontrol.github.io/stmbl/) to learn more about this project.

We are proposing a new revision of the project making significant improvements and updates:

- H-bridge
- Power connectors
- Bulk Capacitor
- Heat dissipation components and case
- Other obsolete components

<img src="./img/stmbl_case.jpg" alt="image" width="640"/> 

<img src="./img/front.jpg" alt="image" width="300"/> <img src="./img/back.jpg" alt="image" width="335"/> 

## H-Bridge
First we needed to replace the original and obsolete H-bridge IRAM256 with a more powerful and easily available one.
We chose the [Infineon IKCM30F60GD](https://www.mouser.it/datasheet/2/196/Infineon_IKCM30F60GD_DataSheet_v02_05_EN-3361791.pdf) capable of peak output currents up to 60Amps instead of 30 of the original bridge.

## Upgrading Power connectors
During our tests with earlier prototypes we noticed that the original power connectors overheated and even got damaged when the board drove big loads.

<img src="./img/old_damag_connector.jpg" alt="image" width="300"/> 

So we decided to replace power connectors, both HV DC input and 3 Phase output with golden plated XT60PW and MR60PW connectors from Amass®, designed for high current up to 60Amps.

## Bulk Capacitor

We have relocated big bulk capacitors outside in a rectifier module as close as possible to the drives. 
Instead internally we kept a more compact MKP Polypropylene snubber capacitor for decoupling the bridge HV power supply.

<img src="./img/pfc.excalidraw.png" alt="image" width="400"/> 

## Heat dissipation components and case

We also optimized heat dissipation components and layout, reducing overall volume by half compared to the original design.

<img src="./img/airflow1.png" alt="image" width="600"/> 
<img src="./img/copper.png" alt="image" width="600"/> 


## Other obsolete components

there were several other components that have been replaced because they have become obsolete:

- ACT4088US-T (DC/DC converter) replaced with [RT8259GE](https://www.mouser.it/datasheet/2/1458/DS8259_03-3104661.pdf) from Richtek.
- With DC/DC converters, the power inductors have also been updated to:
    - [ME3220-472MLC 4.7uH ](https://www.mouser.it/ProductDetail/994-ME3220-472MLC)
    - [ME3220-682MLC 6.8uH](https://www.mouser.it/ProductDetail/994-ME3220-682MLC)
    - [ME3220-103KLC 10uH](https://www.mouser.it/ProductDetail/994-ME3220-103KLC)
- ZLDO1117G33TA (LDO 3.3V 1A) replaced with its new version [LDL1117S33R](https://www.mouser.it/ProductDetail/511-LDL1117S33R) from STMicroelettronics
- both microUSB connectors have been updated to the more modern USBc

* * * 
## Ethercat board
- `/stmbl/lib/soes-esi/` 
STMBL_ECAT.xml - Description of Ethercat device
eeprom.bin - EEPROM file for this configuratio of AX58100


# CiA 402 dummy servo drive

## Using AX58100 EtherCAT board with STM32 over SPI

This project is CiA 402 csp dummy on STM32F405x. Dummy as in loopback: does nothing, received target position is reported as actual position. CiA 402 is implemented,>

The stuff I am doing aims at STMBL rather than ODrive (hence I started with oldschool StdPeriph libs), but both projects use STM32F405. One EtherCAT codebase done pr>

I have been working on that for some time now, and this is where I got:
- software licensing prohibits us from using Beckhoff SSC for open source, it leaves us SOES with GPL. For code generation tool, one can purchase EtherCAT SDK from r>
- hardware (boards designed by me) seems to be working. Slave nodes are reaching OP on both LAN9252 and AX58100
- measured performance shows that we better focus on AX58100. In freerun, with STM32F40x SPI1 at max speed, ecat_slv() loop takes < 20 us so we can easily get linuxc>
Just check out https://github.com/OpenEtherCATsociety/SOES/blob/master/soes/hal/rt-kernel-twrk60/esc_hw.c (ET1100 code) vs https://github.com/OpenEtherCATsociety/SOE>
- CiA 402 is implemented and works with TwinCAT NC, SOES works in mixed mode with DC sync

## Project layout 

- `/esi_ref` contains relevant ESI file examples from misc sources
- `/lib/cia402` is CiA 402 servodrive state machine implementation, indepenent from used CANopen implementation
- `/lib/soes` is copied OpenEthercatSociety/SOES/soes content for easier future upgradeability.
- `/lib/soes/hal/ax58100` has added HAL for AX58100 over SPI
- `/lib/soes_hal_bsp` contains PDI drivers (for STM32F4 SPI with StdPeriph)
- `/lib/soes-esi` contains CoE Object Dictionary (OD), and EtherCAT Slave Info (ESI)
- `/lib/soes-esi/ax58100_patched` contains ESI files prepared for ASIX 58100 ESC by running `patch_esi.py` script


## Hardware

This projec uses AX58100 - SPI breakout rev 1

# STMBL pinout

|STM32 | AX58100 | 12p | 12p | AX58100 | STM32          |
|______|_________|_____|_____|_________|________________|
|                |+24V | +5V |         |                |
|                | GND | SCK | SYNC1   | SWD SCK (PA14) |
| PD0  |  SINT   | CRX | GND |         |                |
| PD1  |  SYNC0  | CTX |SWDIO| NSS     | SWD IO (PA13)  |
| PB4  |  MISO   | MISO| NRST|         |                |
| PB5  |  MOSI   | MOSI| SCK | SCLK    | PB3            |



If you want to get a prototype of this board contact us [here](https://matrix.to/#/@stmbl:freakontrol.com).  
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://www.buymeacoffee.com/freakontrol)


