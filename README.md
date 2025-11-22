# Verysync

A powerful file synchronization tool that allows you to sync files across multiple devices quickly and securely.

## Version Information

This project starts with version `v2.21.3` of the upstream Verysync repository.

## Overview

Verysync is a cross-platform file synchronization application designed to keep your files in sync across all your devices. It offers fast synchronization speeds, secure data transfer, and easy-to-use interface.

## Features

- **Cross-platform support**: Works on Windows, Linux, macOS, iOS, and NAS devices
- **Fast synchronization**: Optimized for speed and performance
- **Secure transfer**: Data is encrypted during transfer
- **Real-time sync**: Files are synced immediately when changes are detected
- **Web interface**: Manage synchronization through a user-friendly web interface
- **Low resource consumption**: Runs quietly in the background

## Installation

### Linux AMD64 (Current Build)

The `verysync-linux-amd64/` directory contains the pre-built Verysync binary for Linux AMD64:

1. Navigate to the AMD64 directory:
   ```bash
   cd verysync-linux-amd64
   ```

2. Make the binary executable:
   ```bash
   chmod +x verysync
   ```

3. Run Verysync:
   ```bash
   ./verysync
   ```

4. Access the web interface at `http://localhost:8886`

### Linux ARM64 (Current Build)

The `verysync-linux-arm64/` directory contains the pre-built Verysync binary for Linux ARM64:

1. Navigate to the ARM64 directory:
   ```bash
   cd verysync-linux-arm64
   ```

2. Make the binary executable:
   ```bash
   chmod +x verysync
   ```

3. Run Verysync:
   ```bash
   ./verysync
   ```

4. Access the web interface at `http://localhost:8886`



### Automatic Installation

#### Linux (amd64/arm64)

For automatic installation on Linux systems:

**Note:** The installer will automatically detect your system architecture (amd64/arm64) and download the appropriate package.

```bash
# (If you need to specify the index location, add -d path at the end, e.g., -d /data/verysync)
curl -k https://github.com/chancejiang/verysync/raw/master/verysync-linux-installer.sh > verysync-linux-installer.sh
chmod +x verysync-linux-installer.sh
./verysync-linux-installer.sh
```

After installation, you can access the web interface at `http://your-ip-address:8886` to manage your Verysync content.

#### Installer Parameters (Linux)

```bash
./verysync-linux-installer.sh [-h] [-c] [--remove] [-p proxy] [-f] [--version vx.y.z] [-l file] [-d index location] [-u user]
  -h, --help            Show help
  -p, --proxy           Set proxy server (e.g., -p socks5://127.0.0.1:1080 or -p http://127.0.0.1:3128)
  -f, --force           Force installation
      --version         Install specific version (e.g., --version v2.21.3)
  -l, --local           Install from a local file (absolute path required)
      --remove          Uninstall Verysync
  -c, --check           Check for updates
  -d  --home            Set Verysync index location (default: ~/.config/verysync)
  -u  --user            Set user to run Verysync service (default: root)
```


This script will automatically install the following files:
- `/usr/bin/verysync/verysync`: Verysync main program
- `/usr/bin/verysync/start-stop-daemon`: daemon management program (pre-built for i386, amd64, arm, arm64 architectures on CentOS)

The installer will configure automatic startup scripts that will run Verysync automatically after system reboot. Currently, the automatic startup scripts only support systems with Systemd or init.d, including all Debian/Ubuntu series.

Tested systems: CentOS 6.5 (init.d), CentOS 7.5 (systemd), Debian 7.11 (systemv), Debian 9.5 (systemd)

Since the default CentOS repository doesn't have the daemon package, this repository comes with pre-built start-stop-daemon programs for i386, amd64, arm, and arm64 architectures to avoid system compilation. If you use other architectures, you need to compile the daemon package yourself. [https://gist.github.com/yuuichi-fujioka/c4388cc672a3c8188423](https://gist.github.com/yuuichi-fujioka/c4388cc672a3c8188423)

## System Service Setup

The `etc/` directory inside the architecture-specific folders contains system service scripts for various Linux distributions.

### systemd (Recommended for modern systems)

#### System-wide service:
```bash
# For AMD64:
sudo cp verysync-linux-amd64/etc/linux-systemd/system/verysync@.service /etc/systemd/system/

# For ARM64:
sudo cp verysync-linux-arm64/etc/linux-systemd/system/verysync@.service /etc/systemd/system/

# Then enable and start the service:
sudo systemctl enable verysync@<username>
sudo systemctl start verysync@<username>
```

#### User-level service:
```bash
mkdir -p ~/.config/systemd/user/

# For AMD64:
cp verysync-linux-amd64/etc/linux-systemd/user/verysync.service ~/.config/systemd/user/

# For ARM64:
cp verysync-linux-arm64/etc/linux-systemd/user/verysync.service ~/.config/systemd/user/

# Then enable and start the service:
systemctl --user enable verysync
systemctl --user start verysync
```

### init.d (Legacy systems)

```bash
# For AMD64:
sudo cp verysync-linux-amd64/etc/linux-init.d/verysync /etc/init.d/

# For ARM64:
sudo cp verysync-linux-arm64/etc/linux-init.d/verysync /etc/init.d/

# Then set permissions and start the service:
sudo chmod +x /etc/init.d/verysync
sudo update-rc.d verysync defaults
sudo service verysync start
```

### runit

```bash
# For AMD64:
sudo cp -r verysync-linux-amd64/etc/linux-runit/ /etc/sv/verysync/

# For ARM64:
sudo cp -r verysync-linux-arm64/etc/linux-runit/ /etc/sv/verysync/

# Then create symlink:
sudo ln -s /etc/sv/verysync/ /etc/service/
```


## Configuration

### Linux File Watch Limit

Linux usually limits the number of files that can be watched by a user (typically 8192). When you need to handle more files simultaneously, you need to adjust this number:

In many Linux distributions, you can adjust it by running:
```bash
echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

On Arch Linux and other distributions, it's better to write this line to a separate file. You should run:
```bash
echo "fs.inotify.max_user_watches=204800" | sudo tee -a /etc/sysctl.d/90-override.conf
```

The above changes take effect after a reboot. If you don't want to reboot, you can execute:
```bash
sudo sh -c 'echo 204800 > /proc/sys/fs/inotify/max_user_watches'
```

### Web Interface

After starting Verysync, access the web interface at:
- Local: `http://localhost:8886`
- Network: `http://<your-ip-address>:8886`

## Other Platforms

- **Windows**: Download from [verysync.com](http://www.verysync.com/download.html) and run the executable
- **macOS**: Download the DMG file and drag to Applications folder
- **iOS**: Install from App Store search "微力同步" or "verysync"
- **NAS**: Follow platform-specific instructions on the [official documentation](https://www.verysync.com/manual/install/)

## Documentation

For complete documentation, visit the [Verysync Manual](https://www.verysync.com/manual/)

## Support

- Official website: [verysync.com](http://www.verysync.com/)
- Documentation: [https://www.verysync.com/manual/](https://www.verysync.com/manual/)
