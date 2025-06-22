# MTSP - Music Terminal Shell Player

```
███╗   ███╗████████╗███████╗██████╗
████╗ ████║╚══██╔══╝██╔════╝██╔══██╗
██╔████╔██║   ██║   ███████╗██████╔╝
██║╚██╔╝██║   ██║   ╚════██║██╔═══╝
██║ ╚═╝ ██║   ██║   ███████║██║
╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝
```

**Version:** 0.3.8  
**License:** Open Source  
**Platform:** Linux Terminal

## Overview

**MTSP** (Music Terminal Shell Player) is a powerful, lightweight command-line music player designed for Linux systems. It provides an intuitive terminal-based interface for playing local music files, streaming online content, and managing playlists with advanced features like shuffle, repeat, and interactive file browsing.

## Screenshots

![MTSP Main Interface](https://github.com/almezali/mtsp-0.3.0/blob/main/mtsp-0.3.8/0-Screenshot.png)

## ✨ Key Features

### 🎵 Audio Playback
- **Multi-format Support**: Play `.mp3`, `.wav`, `.flac`, `.m4a`, and `.ogg` files
- **Local File Playback**: Load individual files or entire folders
- **Streaming Support**: Play online URLs and streams
- **SoundCloud Integration**: Direct streaming from SoundCloud URLs
- **Radio Stations**: Built-in Egyptian radio stations (Tes3enat FM, Nogoum FM, Cairo Q FM)

### 📁 Playlist Management
- **Dynamic Playlists**: Create and manage playlists on-the-fly
- **M3U/M3U8 Support**: Load and play standard playlist formats
- **Interactive File Browser**: Navigate and select files using `fzf`
- **Batch File Addition**: Add multiple files simultaneously
- **Playlist Persistence**: Maintain playlist state during session

### 🎛️ Playback Controls
- **Standard Controls**: Play, pause, next, previous
- **Volume Control**: Increase/decrease volume with `+/-` keys
- **Shuffle Mode**: Randomized track playback
- **Repeat Mode**: Loop entire playlist
- **Track History**: Keep track of recently played tracks (up to 50)

### 📊 Visual Interface
- **Colored Output**: Intuitive color-coded interface
- **ASCII Art Banner**: Stylish terminal presentation
- **Playlist Display**: Tabular view of current playlist with status indicators
- **Real-time Status**: Show currently playing track and playback state

### 🌐 Online Features
- **URL Streaming**: Direct playback from HTTP/HTTPS URLs
- **M3U Playlist Streaming**: Load online M3U/M3U8 playlists
- **SoundCloud Integration**: Fetch track metadata and stream directly
- **Radio Station Presets**: Quick access to popular radio stations

## 📋 Requirements

### System Dependencies
MTSP requires the following packages to be installed on your Linux system:

| Package | Purpose | Required |
|---------|---------|----------|
| `mpv` | Audio/video player engine | ✅ Yes |
| `socat` | Inter-process communication | ✅ Yes |
| `jq` | JSON parsing and processing | ✅ Yes |
| `youtube-dl` | SoundCloud URL processing | ✅ Yes |
| `fzf` | Interactive file browser | ✅ Yes |
| `curl` | HTTP requests for online content | ✅ Yes |

### Installation Commands

**Debian/Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install mpv socat jq youtube-dl fzf curl
```

**Fedora:**
```bash
sudo dnf install mpv socat jq youtube-dl fzf curl
```

**Arch Linux:**
```bash
sudo pacman -S mpv socat jq youtube-dl fzf curl
```

**OpenSUSE:**
```bash
sudo zypper install mpv socat jq youtube-dl fzf curl
```

## 🚀 Installation & Setup

1. **Download the script:**
   ```bash
   wget https://github.com/almezali/mtsp-0.3.0/raw/main/mtsp-0.3.8/mt-music-player.sh
   ```

2. **Make it executable:**
   ```bash
   chmod +x mt-music-player.sh
   ```

3. **Run the player:**
   ```bash
   ./mt-music-player.sh
   ```

4. **Optional - Add to PATH:**
   ```bash
   sudo cp mt-music-player.sh /usr/local/bin/mtsp
   sudo chmod +x /usr/local/bin/mtsp
   ```

## 🎹 Controls & Usage

### Basic Controls
| Key | Action | Description |
|-----|--------|-------------|
| `p` | Play/Pause | Toggle playback of current track |
| `n` | Next Track | Skip to next track in playlist |
| `b` | Previous Track | Go back to previous track |
| `+` | Volume Up | Increase volume by 5% |
| `-` | Volume Down | Decrease volume by 5% |
| `q` | Quit | Exit the player |

### Radio Stations
| Key | Station | Description |
|-----|---------|-------------|
| `1` | Tes3enat FM | Egyptian radio station |
| `2` | Nogoum FM | Popular Egyptian music station |
| `3` | Cairo Q FM | Cairo-based radio station |

### Playlist Management
| Key | Action | Description |
|-----|--------|-------------|
| `f` | Load Folder | Load all music files from a directory |
| `a` | Add Files | Add individual files using interactive browser |
| `l` | Load Playlist | Load M3U/M3U8 playlist files |
| `m` | Browse Files | Interactive file browser with multi-selection |
| `v` | View Playlist | Display current playlist with status |
| `c` | Clear Playlist | Remove all tracks from playlist |

### Online Features
| Key | Action | Description |
|-----|--------|-------------|
| `u` | Add SoundCloud URL | Stream directly from SoundCloud |
| `o` | Online URL/M3U | Play online streams or M3U playlists |

### Playback Modes
| Key | Action | Description |
|-----|--------|-------------|
| `r` | Toggle Repeat | Enable/disable playlist repeat |
| `s` | Toggle Shuffle | Enable/disable random track order |
| `h` | Show Help | Display all available controls |

## 📁 File Structure

```
MTSP/
├── mt-music-player.sh      # Main executable script
├── README.md               # This documentation
├── /tmp/mpvsocket         # MPV IPC socket (auto-created)
└── ~/Music/               # Default music directory
```

## 🔧 Configuration

### Default Music Directory
By default, MTSP looks for music in `~/Music/`. You can change this by modifying the `MUSIC_DIR` variable in the script:

```bash
MUSIC_DIR="$HOME/Music"  # Change to your preferred directory
```

### Supported Audio Formats
MTSP supports the following audio formats:
- **MP3** (.mp3)
- **WAV** (.wav)
- **FLAC** (.flac)
- **M4A** (.m4a)
- **OGG** (.ogg)

### Radio Station Customization
To add your own radio stations, modify the arrays in the script:

```bash
RADIO_URLS=(
    "http://your-radio-url.com/stream"
    "https://another-station.com/live"
)
RADIO_NAMES=(
    "Your Radio Station"
    "Another Station"
)
```

## 🌟 Advanced Features

### Interactive File Browser
The interactive file browser (`m` key) provides:
- **Visual Navigation**: Browse directories with folder and file icons
- **Multi-Selection**: Select multiple files and folders simultaneously
- **Smart Filtering**: Only shows supported audio files and playlists
- **Recursive Loading**: Automatically loads all music files from selected folders

### Playlist Features
- **Smart Title Display**: Shows track titles or filenames intelligently
- **Status Indicators**: Visual indicators for currently playing/paused tracks
- **Auto-progression**: Automatically plays next track when current finishes
- **History Tracking**: Maintains history of last 50 played tracks

### SoundCloud Integration
- **Metadata Fetching**: Automatically retrieves track titles and information
- **Direct Streaming**: No download required, streams directly
- **Queue Integration**: SoundCloud tracks integrate seamlessly with local playlists

## 🔍 Troubleshooting

### Common Issues

**1. "Command not found" errors:**
```bash
# Check if dependencies are installed
which mpv socat jq youtube-dl fzf
# Install missing dependencies using your package manager
```

**2. No audio output:**
```bash
# Check audio system
pulseaudio --check
# Or for ALSA
aplay -l
```

**3. SoundCloud URLs not working:**
```bash
# Update youtube-dl
sudo pip install --upgrade youtube-dl
# Or use yt-dlp as alternative
sudo pip install yt-dlp
```

**4. Permission issues:**
```bash
# Make script executable
chmod +x mt-music-player.sh
# Check file permissions
ls -la mt-music-player.sh
```

### Debug Mode
To run MTSP with debug output:
```bash
bash -x ./mt-music-player.sh
```

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork the repository**
2. **Create a feature branch**
3. **Make your changes**
4. **Test thoroughly**
5. **Submit a pull request**

### Development Guidelines
- Follow existing code style and conventions
- Add comments for complex functionality
- Test with various audio formats and sources
- Ensure compatibility with major Linux distributions

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

## 🙏 Acknowledgments

- **MPV** - Powerful media player engine
- **FZF** - Command-line fuzzy finder
- **SoundCloud** - Music streaming platform
- **Community Contributors** - For feedback and improvements

## 📞 Support

For issues, questions, or feature requests:
- **GitHub Issues**: [Create an issue](https://github.com/almezali/mtsp-0.3.0/issues)
- **Documentation**: Check this README for common solutions
- **Community**: Share experiences with other users

## 🔄 Version History

- **v0.3.8** - Current version with full feature set
- **v0.3.0** - Added interactive file browser and M3U support
- **v0.2.x** - SoundCloud integration and playlist management
- **v0.1.x** - Initial release with basic playback features

---

**MTSP** - Bringing powerful music playback to the Linux terminal. Enjoy your music! 🎵
