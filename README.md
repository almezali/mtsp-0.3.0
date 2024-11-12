.
.
.
.
.


███╗   ███╗████████╗███████╗██████╗"
████╗ ████║╚══██╔══╝██╔════╝██╔══██╗"
██╔████╔██║   ██║   ███████╗██████╔╝"
██║╚██╔╝██║   ██║   ╚════██║██╔═══╝"
██║ ╚═╝ ██║   ██║   ███████║██║"
╚═╝     ╚═╝   ╚═╝   ╚══════╝╚═╝"
Music Terminal Shell Player
.
.
.
.
.
.
.
.
.
.



# MTSP - Music Terminal Shell Player

**MTSP** (Music Terminal Shell Player) is a command-line music player designed for Linux, providing a simple, efficient interface to play music directly from the terminal. It supports local playlists and SoundCloud streaming, offering playback features like shuffle, repeat, and volume control.

![MTSP Banner](https://ibb.co/ZcPx3Cj) <!-- Optional: Add a path to a banner image here -->

### Features
- **Play Local Music**: Load and play audio files from local directories with supported formats: `.mp3`, `.wav`, `.flac`, `.m4a`, and `.ogg`.
- **SoundCloud Integration**: Add and stream SoundCloud tracks directly by URL.
- **Control Options**: Play, pause, next, previous, volume control, shuffle, and repeat.
- **Playlist Management**: Easily load folders or individual files into a playlist.
- **Track History**: Keeps track of recently played tracks.

### Requirements
To run **MTSP**, ensure the following dependencies are installed:
- `mpv`: For audio playback.
- `socat`: For inter-process communication.
- `jq`: For JSON parsing.
- `youtube-dl` (or `yt-dlp` as an alternative): Required for SoundCloud URL support.

#### Installation of Dependencies
Install dependencies based on your Linux distribution:

On Debian/Ubuntu:
```bash
sudo apt-get install mpv socat jq youtube-dl

On Fedora:
sudo dnf install mpv socat jq youtube-dl

On Arch Linux:
sudo pacman -S mpv socat jq youtube-dl


Make the Script Executable:
chmod +x mt-music-player.sh

Run the Player:
./mt-music-player.sh

====
Usage
Once the player is running, you can use the following controls:

p: Play/Pause
n: Next track
b: Previous track
+ / -: Increase/Decrease volume
r: Toggle repeat mode
s: Toggle shuffle mode
f: Load music from a folder
a: Add individual files
u: Add SoundCloud URL to the playlist
c: Clear playlist
v: View current playlist
h: Show controls
q: Quit the player
Adding SoundCloud Tracks
To add a track from SoundCloud, use the u key and provide a SoundCloud URL. MTSP will fetch and add the track to your playlist

