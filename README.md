# 🎨 Grub With Flair

A modern, interactive TUI (Terminal User Interface) for installing and previewing GRUB2 themes. This project enhances the GRUB theme installation experience with a beautiful, user-friendly interface.

## ✨ Features

- 📺 Live theme previews (requires Kitty terminal)
- 🎯 Interactive theme selection
- 🚀 Easy one-click installation
- 🛡️ Automatic backup of GRUB configuration
- 📦 Multiple theme support
- 🎨 Beautiful TUI with colors and borders
- 🔍 Automatic OS detection support (via os-prober)

## 📋 Requirements

- GRUB2
- Kitty terminal (for image previews)
- sudo privileges

## 🚀 Installation

1. Clone this repository:
```bash
git clone https://github.com/yourusername/grub_with_flair.git
cd grub_with_flair
```

2. Make the scripts executable:
```bash
chmod +x tui.sh install.sh
```

3. Run the TUI as root:
```bash
sudo ./tui.sh
```

## 🛠️ Additional Features

### OS Detection
The script automatically checks for and helps you install `os-prober` if it's not present on your system. This ensures that:
- All operating systems on your computer are detected
- GRUB shows boot options for all installed operating systems
- The GRUB configuration is properly set up for OS detection

## 🤝 Acknowledgments

- Special thanks to [Chris Titus](https://github.com/ChrisTitusTech) for the original install script which formed the base of this project. Check out his work at [CTT-GRUB-THEMES](https://github.com/ChrisTitusTech/CTT-GRUB-Themes).

### Theme Credits

The themes included in this project come from various creators:

- [Stylish Theme](https://github.com/vinceliuice/grub2-themes)
- [Vimix Theme](https://github.com/vinceliuice/grub2-themes)
- [Tela Theme](https://github.com/vinceliuice/grub2-themes)
- [CyberRe Theme](https://github.com/vandalsoul/grub2-themes)
- [Fallout Theme](https://github.com/shvchk/fallout-grub-theme)

*Note: Please check each theme's repository for their specific licenses and terms of use.*

## ⭐ Support

If you find this project helpful, please consider giving it a star on GitHub! Your support helps make open source projects like this possible.

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

