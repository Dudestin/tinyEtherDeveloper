View this project on [CADLAB.io](https://cadlab.io/project/25780). 
Contact : ![@mozc_channel](https://twitter.com/mozc_channel)

# tinyEtherDeveloper
Inexpensive FPGA board-based Ethernet evaluation board project.  
Consists mostly of DIP components and uses Tang PriMER. It can be built for about only $50.

## About
**5,000円程度**でほとんどの部品が秋葉原で揃う, Ethernetポートを**4つ**備えた評価ボードです. 10BASE-Tに対応しています.  
はんだ付けが苦手な方でも容易に実装できるよう, 極力面実装部品の仕様は控えています.  
FPGAボードには, SipeedのTang PriMERを用いており, そこそこ豊富なBRAMを備えるため, 様々な応用が可能です.

| Overview | Overview2 | PCB Layout |
| --- | --- |  --- |
| ![assembleBoard](photo.jpg) | ![image](https://user-images.githubusercontent.com/11572379/177893836-ef3590b5-e114-4030-a8f4-406668eed1c5.png) |![image](https://user-images.githubusercontent.com/11572379/177893259-ae57e3e7-09b9-4d4e-ae43-94de1321b457.png) |
## Usages and Applications
- Repeater Hub
- Video Broadcasting (Use with MIPI Camera)
- NTP Server
- L2 Switch
- L3 Switch
- Hardware VPN router

## Where to get parts
[部品表](https://partscabi.net/list/92284b79-cc50-4855-a5a0-e0b6e620e11a), [RTL8201CP](https://jp.rs-online.com/web/p/ethernet-interface-ics/0419952) (PHYチップ)
