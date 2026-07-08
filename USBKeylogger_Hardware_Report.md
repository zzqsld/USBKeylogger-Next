# USBKeylogger 硬件报告 V1.0

> 项目名称：硬件键盘记录器 USBKeylogger
> 硬件版本：V1（小型Dongle版）
> 报告日期：2026-07-08
> 来源：https://oshwhub.com/pusheax/USBKeylogger | https://github.com/Push3AX/USBKeylogger

---

## 1. 系统架构概述

```
[USB键盘] → [USB-A母座] → [CH9350L U6 HID→UART] → [ESP-07S ESP8266]
                                                          ↓ Wi-Fi
[USB主机/PC] ← [USB-A公座] ← [CH9350L U5 UART→HID] ← [Web管理界面]
```

- **CH9350L U6 (HID2UART)**：接收键盘USB HID信号，转换为UART串口数据发送给ESP-07S
- **ESP-07S (主控)**：解析键盘数据、记录日志到Flash文件系统、运行Web管理界面、提供Wi-Fi远程控制
- **CH9350L U5 (UART2HID)**：将ESP-07S输出的UART数据转换为USB HID信号发送给主机

---

## 2. 核心芯片/模块清单

| 位号 | 型号 | 功能 | 封装 | 供电电压 | 备注 |
|------|------|------|------|----------|------|
| U1/U6 | CH9350L | HID转UART芯片 | LQFP-48 (7×7mm) | +5V | 键盘侧，接收USB键盘输入 |
| U2/U5 | CH9350L | UART转HID芯片 | LQFP-48 (7×7mm) | +5V | 主机侧，输出到PC |
| MK2 | ESP-07S | Wi-Fi主控模块 (ESP8266) | SMD-16 (16×17×3mm) | +3.3V | 外接IPEX天线，4MB Flash |
| U4 | AMS1117-3.3 | 3.3V LDO稳压 | SOT-223 | +5V→+3.3V | 为ESP-07S供电 |

---

## 3. 引脚接线详细表

### 3.1 ESP-07S (MK2) 引脚分配

| 引脚号 | 引脚名 | 方向 | 连接目标 | 功能说明 | 代码注意事项 |
|--------|--------|------|----------|----------|-------------|
| 1 | RST | — | +3.3V（上拉） | 复位引脚，高电平正常工作 | 外部复位按钮也可接此引脚 |
| 2 | ADC | — | NC | 模拟输入，未使用 | 不可用作GPIO |
| 3 | EN | — | +3.3V | 芯片使能，**必须高电平** | 低电平=芯片关闭 |
| 4 | IO16 | — | NC | GPIO16，未使用 | DeepSleep唤醒时需接RST |
| 5 | IO14 | — | NC | GPIO14/HSPI_CLK | 可作为额外GPIO使用 |
| 6 | IO12 | — | NC | GPIO12/HSPI_MISO | **启动时内部上拉**，勿接低电平 |
| 7 | IO13 | — | NC | GPIO13/HSPI_MOSI | 可作为额外GPIO使用 |
| 8 | VCC | — | +3.3V | 模块供电 | AMS1117-3.3输出 |
| 9 | GND | — | GND | 地 | — |
| 10 | IO15 | — | GND（下拉） | GPIO15/HSPI_CS | **启动时必须为低电平** |
| 11 | IO2 | — | NC | GPIO2/UART1_TXD | **启动时内部上拉**，勿接低电平；板载LED通常在此 |
| 12 | **IO0** | 输出 | **CH9350 RST** | **控制CH9350复位/模式切换** | 关键引脚：LOW=复位/下载模式，HIGH=正常运行 |
| 13 | IO4 | — | NC | GPIO4 | 可作为额外GPIO使用 |
| 14 | IO5 | — | NC | GPIO5 | 可作为额外GPIO使用 |
| 15 | **RXD** | 输入 | **CH9350 TXD** | UART0接收，接收键盘HID数据 | Serial.begin() 配置此串口 |
| 16 | **TXD** | 输出 | **CH9350 RXD** | UART0发送，发送HID数据到主机 | 与RXD配对使用 |

### 3.2 ESP-07S ↔ CH9350L 接线关系

```
ESP-07S                    CH9350L U6 (HID→UART)      CH9350L U5 (UART→HID)
─────────                  ─────────────────────      ─────────────────────
Pin15 RXD  ←────────────── TXD Pin27                  TXD Pin27
Pin16 TXD  ───────────────→ RXD Pin26                  RXD Pin26
Pin12 IO0  ───────────────→ RST Pin3  (同时控制U6和U5)  RST Pin3
+3.3V      ─────────────── VCC3 Pin17                  VCC3 Pin17
GND        ─────────────── GND                         GND
                           VCC  Pin28 ← +5V            VCC  Pin28 ← +5V
                           USB  D+/D- → 键盘母座       USB  D+/D- → 主机公座
```

### 3.3 电源接线

```
USB-A公座(HOST) +5V ──┬──→ AMS1117-3.3 IN  ──→ +3.3V ──→ ESP-07S VCC
                      │                          ↓
                      │                    C8(1uF) C9(100nF) 输入滤波
                      │                    C7(1uF) C10(100nF) 输出滤波
                      │
                      ├──→ CH9350 U6 VCC (+5V)
                      ├──→ CH9350 U5 VCC (+5V)
                      │
                      └──→ GND网络
```

### 3.4 其他外设接线

| 外设 | 连接引脚 | 说明 |
|------|----------|------|
| KEY模式按钮 | ESP-07S 某GPIO (需代码确认) | 短按切换CH9350工作模式 |
| RST复位按钮 | ESP-07S RST引脚 | 硬件复位 |
| CH9350 U6 LED1/LED2 | U6 Pin5/Pin6 | 状态指示灯（USB-RX/状态） |
| CH9350 U5 LED1/LED2 | U5 Pin5/Pin6 | 状态指示灯 |
| IPEX天线座 | ESP-07S 天线焊盘 | Wi-Fi外接天线 |

---

## 4. CH9350L 通信协议

### 4.1 UART参数
- **接口**：UART0（Serial）
- **波特率**：921600 bps（推测，需代码确认；也可能是115200）
- **数据位**：8
- **停止位**：1
- **校验**：无
- **流控**：无

### 4.2 数据帧格式（键盘上报方向）

ESP-07S通过RXD接收来自U6的键盘数据，帧结构如下：

```
+--------+--------+--------+--------+-----+-----------+-----+-----+
| SYNC1  | SYNC2  |  CMD   |  LEN   | RID | HID Data  | SN  | SUM |
|  0x57  |  0xAB  |  0x83  |  0x0C  |0x01 | 8 bytes   | 1B  | 1B  |
+--------+--------+--------+--------+-----+-----------+-----+-----+
  同步头1   同步头2   命令码    长度    报告ID  键值数据    序号   校验和
```

- **校验和计算**：RID + HID 8字节 + SN，累加和取低8位
- **HID Data格式**：标准USB HID报告，8字节 = [Modifier, Reserved, Key0, Key1, Key2, Key3, Key4, Key5]

### 4.3 Boot Keyboard帧格式（备选模式）

```
+--------+--------+--------+-----+-----------+-----+-----+
| SYNC1  | SYNC2  |  CMD   | LEN | HID Data  | SN  | SUM |
|  0x57  |  0xAB  |  0x88  |0x0B | 8 bytes   | 1B  | 1B  |
+--------+--------+--------+-----+-----------+-----+-----+
```
- 校验和：HID 8字节 + SN

### 4.4 CH9350控制引脚（GPIO0）

```
ESP-07S IO0 = HIGH (3.3V) → CH9350 正常运行模式
ESP-07S IO0 = LOW  (0V)   → CH9350 复位/配置模式
```

**模式切换时序要求**：
1. IO0置LOW，保持至少10ms
2. 等待CH9350复位完成（约100-200ms）
3. IO0置HIGH，恢复正常运行
4. 代码中通过`digitalWrite(0, LOW/HIGH)`控制

---

## 5. ESP8266启动模式说明

ESP-07S上电启动时，以下引脚电平决定启动模式，**硬件已固定接好**：

| 引脚 | 上电状态 | 作用 |
|------|----------|------|
| EN (Pin3) | HIGH (+3.3V) | 芯片使能，必须高 |
| GPIO15 (Pin10) | LOW (GND) | **必须为LOW才能正常启动** |
| GPIO0 (Pin12) | HIGH/LOW | HIGH=正常启动，LOW=下载模式 |
| GPIO2 (Pin11) | HIGH（内部上拉）| **必须高电平才能启动** |

- **正常启动**：GPIO0=HIGH, GPIO15=LOW, GPIO2=HIGH
- **固件下载**：GPIO0=LOW, GPIO15=LOW, GPIO2=HIGH（需外接USB转TTL工具）

> ⚠️ **重要**：GPIO12在原理图上标记为"NC"，但ESP8266启动时内部会短暂上拉此引脚。如果外部接了下拉电阻或低电平设备，可能导致启动失败。**确保GPIO12不接任何会拉低电平的器件**。

---

## 6. 存储空间分配

| 区域 | 大小 | 用途 |
|------|------|------|
| Flash总容量 | 4MB (32Mbit) | ESP-07S内置SPI Flash |
| 程序区 | ~1MB | Arduino编译后的固件 |
| LittleFS文件系统 | ~3MB | 日志存储、配置文件、Web静态资源 |
| 日志文件 | 动态 | /keyLog.txt（当前日志），支持8个轮转槽 |
| 配置文件 | ~1KB | /config.json（Wi-Fi、推送等配置） |

---

## 7. 功耗与电源预算

| 模块 | 典型电流 | 峰值电流 | 供电 |
|------|----------|----------|------|
| ESP-07S (Wi-Fi传输) | ~80mA | **~500mA** | 3.3V |
| ESP-07S (Light Sleep) | ~2mA | — | 3.3V |
| ESP-07S (Deep Sleep) | ~20μA | — | 3.3V |
| CH9350L ×2 | ~30mA | ~50mA | 5V |
| **整机总计** | **~150mA** | **~600mA** | — |

> USB 2.0接口可提供最大500mA@5V，正常使用时功耗在USB供电能力范围内。Wi-Fi传输峰值期间可能接近上限。

---

## 8. 代码开发关键注意事项

### 8.1 必须使用的Arduino库
```cpp
#include <FS.h>
#include <LittleFS.h>
#include <ESP8266WiFi.h>
#include <ESPAsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <ESPAsyncDNSServer.h>
#include <ESP8266HTTPClient.h>
#include <Updater.h>          // OTA升级
```

### 8.2 串口初始化
```cpp
// 在setup()中初始化与CH9350通信的串口
// 波特率需与CH9350实际配置一致（常见115200或921600）
Serial.begin(921600);  // 或 115200，需实测确认
```

### 8.3 GPIO0控制CH9350复位
```cpp
#define CH9350_RST_PIN 0  // GPIO0控制CH9350复位

// CH9350复位函数
void resetCH9350() {
    pinMode(CH9350_RST_PIN, OUTPUT);
    digitalWrite(CH9350_RST_PIN, LOW);
    delay(20);           // 保持低电平至少10ms
    digitalWrite(CH9350_RST_PIN, HIGH);
    delay(200);          // 等待CH9350复位完成
}
```

### 8.4 ESP-07S启动引脚状态（代码中不可更改这些引脚的启动状态）
```cpp
// 以下引脚在setup()之前已由硬件固定，代码中不可改变：
// GPIO15 (Pin10) = LOW  → 已由硬件接GND
// GPIO0  (Pin12) = HIGH → 正常启动，CH9350正常运行
// GPIO2  (Pin11) = HIGH → 内部上拉，不可接低电平

// 如果需要进入下载模式烧录固件：
// 需外部将GPIO0拉低后再复位
```

### 8.5 未使用GPIO的可用性
以下GPIO在硬件上已引出但当前未使用，可用于扩展功能：
- **GPIO14 (Pin5)**：可用作通用GPIO / SPI时钟
- **GPIO13 (Pin7)**：可用作通用GPIO / SPI数据
- **GPIO4 (Pin13)**：可用作通用GPIO / I2C
- **GPIO5 (Pin14)**：可用作通用GPIO / I2C
- **ADC (Pin2)**：10位ADC，输入范围0-1V

> 注意：GPIO6-GPIO11用于内部SPI Flash通信，不可使用。

### 8.6 Wi-Fi相关
- **AP模式**：默认IP `192.168.5.1`，子网掩码 `255.255.255.0`
- **STA模式**：连接路由器获取IP
- **DNS服务器**：AP模式下使用ESPAsyncDNSServer提供captive portal功能
- **mDNS**：可启用 `usbkeylogger.local` 域名访问

---

## 9. BOM（关键物料清单）

| 位号 | 名称 | 型号/规格 | 封装 | 数量 |
|------|------|-----------|------|------|
| MK2 | Wi-Fi模块 | ESP-07S (ESP8266, 4MB Flash, IPEX) | SMD-16 | 1 |
| U1/U6 | HID芯片 | CH9350L HID2UART | LQFP-48 | 1 |
| U2/U5 | HID芯片 | CH9350L UART2HID | LQFP-48 | 1 |
| U4 | LDO | AMS1117-3.3 | SOT-223 | 1 |
| USB3 | USB母座 | USB-A 90° 母座 | 插件 | 1 |
| USB4 | USB公座 | USB-A 90° 公座 | 插件 | 1 |
| C7,C8 | 电解电容 | 1μF | SMD | 2 |
| C9,C10,C11,C12 | 陶瓷电容 | 100nF (104) | 0603 | 4 |
| — | 按钮 | 轻触开关 | SMD | 2 |
| — | IPEX天线 | 2.4G Wi-Fi天线 | IPEX接口 | 1 |

---

## 10. 烧录与调试接口

ESP-07S模块**没有引出专门的烧录引脚**，需要通过以下方式烧录固件：

### 10.1 首次烧录（需要拆焊或使用夹具）
- 工具：USB转TTL模块（CH340/CP2102）
- 接线：
  ```
  USB转TTL          ESP-07S
  ────────          ───────
  3.3V      ──────→ VCC (Pin8)
  GND       ──────→ GND (Pin9)
  TX        ──────→ RXD (Pin15)
  RX        ──────→ TXD (Pin16)
  GND       ────┬─→ GPIO0 (Pin12) [烧录时拉低]
                └──→ GPIO15 (Pin10) [已硬件接地]
  ```
- 流程：GPIO0接GND → 通电复位 → 进入下载模式 → 上传固件

### 10.2 OTA升级（推荐，烧录一次后使用）
固件已支持OTA（Over-The-Air）升级，首次烧录带OTA功能的固件后，后续可通过Wi-Fi无线推送更新。

---

## 11. 关键时序与电气约束

| 参数 | 值 | 说明 |
|------|-----|------|
| CH9350复位脉冲宽度 | ≥10ms | GPIO0低电平保持时间 |
| CH9350复位恢复时间 | ~200ms | 复位后到正常工作 |
| ESP8266启动时间 | ~300ms | 从上电到运行setup() |
| Wi-Fi AP启动时间 | ~2s | 首次配置热点可用时间 |
| UART波特率 | 115200/921600 | 需与CH9350配置匹配 |
| 3.3V LDO输出电流 | ≥500mA | AMS1117需满足ESP8266峰值需求 |
| 输入电压范围 | 4.5V-5.5V | USB标准供电 |

---

## 12. 源码中硬件相关常量速查

```cpp
// 从USBKeylogger.ino V1.3.1提取

// CH9350帧解析状态机
enum ParserState {
    WAIT_SYNC1,     // 等待 0x57
    WAIT_SYNC2,     // 等待 0xAB
    WAIT_CMD,       // 等待键盘上行命令
    WAIT_LEN,       // 读取长度字节
    READ_PAYLOAD    // 读取并验证完整CH9350载荷
};

// 帧格式常量（来自代码注释）
// Report-ID帧:  57 AB 83 0C 12 01 [8-byte HID] SN SUM
// Boot帧:       57 AB 88 0B 10    [8-byte HID] SN SUM

// Wi-Fi网络配置
IPAddress IPAddr(192, 168, 5, 1);
IPAddress subnet(255, 255, 255, 0);

// Web服务器
AsyncWebServer webServer(80);

// 文件系统
const char* logFile_Path   = "/keyLog.txt";    // 活动日志（槽0）
const char* configFile_Path = "/config.json";   // 配置文件
const char* versionFile_Path = "/fw_ver.txt";   // 固件版本标记
const int LOG_SLOT_COUNT = 8;                    // 日志轮转槽数量
```

---

*此报告由原理图和源代码分析生成，供固件开发/优化参考。如有硬件修改需求，请务必对照原理图验证接线。*
