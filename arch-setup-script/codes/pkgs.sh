# Nội dung file pkgs.sh (tạo riêng bên cạnh script chính)
# Danh sách các gói cần cài đặt, được phân loại theo nhóm để dễ quản lý.
# Mỗi gói đi kèm comment giải thích công dụng, cách sử dụng cơ bản, mẹo sử dụng hiệu quả, và các xung đột (conflicts) có thể xảy ra.
# Lưu ý:
# - Một số gói từ AUR (Arch User Repository), cần công cụ như paru hoặc yay để cài đặt (ví dụ: paru -S gói_aur). Mẹo: Sử dụng paru nếu bạn thích giao diện thân thiện hơn yay, và luôn kiểm tra PKGBUILD trước khi cài để tránh mã độc.
# - Conflicts phổ biến: Một số gói có thể xung đột với các gói khác (ví dụ: pipewire với pulseaudio), hoặc yêu cầu cấu hình thủ công để tránh lỗi Wayland/X11. Mẹo: Sau khi cài, chạy pacman -Qdtq để kiểm tra gói thừa và xóa chúng để tránh xung đột không mong muốn.
# - Mẹo chung: Sử dụng pacman -Syu trước khi cài để cập nhật hệ thống, tránh conflicts do phiên bản cũ. Nếu có lỗi dependencies, thử --needed để chỉ cài gói thiếu. Với AUR, cập nhật thường xuyên bằng paru -Syu để tránh break system.
# - Để full chức năng Hyprland: Đảm bảo kernel hỗ trợ Wayland (như linux-zen cho hiệu suất tốt hơn), và cấu hình ~/.config/hypr/hyprland.conf đúng cách. Conflicts: Hyprland có thể xung đột với các WM khác như i3 hoặc GNOME nếu chạy cùng lúc; sử dụng display manager như SDDM để switch.
PKGS=(

# CORE SYSTEM, BOOT, DEV - Các gói cốt lõi cho hệ thống, boot và phát triển. Mẹo: Với boot, luôn backup /boot trước khi chỉnh grub. Conflicts: grub có thể xung đột với systemd-boot nếu dùng dual bootloader; chọn một cái duy nhất.
"grub" # Bootloader chuẩn cho UEFI/Legacy, dùng để boot Arch; cách dùng: sudo grub-install /dev/sdX, sudo grub-mkconfig -o /boot/grub/grub.cfg. Mẹo: Thêm GRUB_DISABLE_OS_PROBER=false vào /etc/default/grub nếu os-prober không detect OS khác. Conflicts: Có thể xung đột với secure boot nếu không sign kernel đúng cách.
"efibootmgr" # Quản lý EFI boot entries; cách dùng: sudo efibootmgr -c để tạo entry mới. Mẹo: Sử dụng efibootmgr -v để xem chi tiết entries. Conflicts: Yêu cầu EFI mode, không hoạt động trên legacy BIOS.
"dosfstools" # Tool tạo/sửa phân vùng FAT/EFI; cách dùng: sudo mkfs.fat -F32 /dev/sdX1. Mẹo: Sử dụng với -n để đặt label EFI. Conflicts: Không xung đột lớn, nhưng cẩn thận không format nhầm phân vùng.
"os-prober" # Phát hiện OS khác cho dualboot; cách dùng: tự động khi chạy grub-mkconfig. Mẹo: Mount các phân vùng OS khác trước khi chạy để detect chính xác. Conflicts: Có thể không detect nếu filesystem lạ hoặc encrypted.
"mtools" # Tool thao tác file MS-DOS/FAT; cách dùng: mcopy để copy file vào FAT. Mẹo: Hữu ích cho bootable USB. Conflicts: Ít dùng, nhưng không hỗ trợ NTFS.
"base-devel" # Bộ công cụ build gói (gcc, make,...), bắt buộc cho AUR; cách dùng: makepkg để build. Mẹo: Cài sớm để tránh lỗi khi build AUR. Conflicts: Có thể xung đột nếu bạn dùng chroot build, nhưng thường an toàn.
"git" # Quản lý mã nguồn, clone repo; cách dùng: git clone URL. Mẹo: Thiết lập git config --global user.name/email để commit. Conflicts: Không xung đột, nhưng cần ssh-key cho private repo.
"cmake" # Công cụ build cross-platform cho dự án C/C++; cách dùng: cmake -S . -B build, sau đó cmake --build build. Mẹo: Sử dụng ccmake cho giao diện config GUI, và -DCMAKE_BUILD_TYPE=Release cho optimize. Conflicts: Có thể xung đột với phiên bản cài từ source nếu không gỡ sạch, hoặc với make nếu config sai.
"meson" # Hệ thống build nhanh và hiện đại cho các dự án open source; cách dùng: meson setup build, sau đó meson compile -C build. Mẹo: Tích hợp tốt với ninja làm backend để build nhanh hơn, và sử dụng meson test để kiểm tra. Conflicts: Không xung đột lớn, nhưng yêu cầu python và ninja làm dependencies.
"cpio" # Công cụ sao chép và lưu trữ file qua pipe, thường dùng trong initramfs hoặc backup; cách dùng: find . | cpio -o > archive.cpio để tạo, cpio -id < archive.cpio để giải. Mẹo: Kết hợp với gzip để nén (cpio -o | gzip > archive.cpio.gz). Conflicts: Không xung đột, nhưng ít dùng hơn tar trong các script hiện đại.
"pkgconf" # Implementation của pkg-config để tra cứu thư viện và dependencies; cách dùng: pkg-config --libs library để lấy flags. Mẹo: Set biến PKG_CONFIG_PATH nếu thư viện custom, và sử dụng --cflags cho header. Conflicts: Thường là alias cho pkg-config trong base-devel, có thể xung đột nếu cài nhiều implementation.
"gcc" # Trình biên dịch C/C++ chuẩn GNU; cách dùng: gcc file.c -o out để biên dịch C, g++ file.cpp -o out cho C++. Mẹo: Thêm -O2 cho tối ưu hóa, và -Wall để cảnh báo lỗi. Conflicts: Xung đột nếu cài nhiều phiên bản (như gcc-multilib cho 32-bit), hoặc với clang nếu set default compiler.
"wget" # Tải file từ web; cách dùng: wget URL. Mẹo: Sử dụng -c để resume download. Conflicts: Không xung đột, nhưng curl linh hoạt hơn cho API.
"curl" # Tải file/API qua https; cách dùng: curl -O URL. Mẹo: Sử dụng -L để follow redirect. Conflicts: Không xung đột, nhưng cần ca-certificates cho https.
"bash-completion" # Tự động hoàn thành lệnh bash; cách dùng: tự động khi gõ tab. Mẹo: Source /etc/profile sau cài. Conflicts: Có thể xung đột với zsh nếu switch shell.
"linux-headers" # Kernel headers cần cho build module/driver; cách dùng: tự động cho dkms. Mẹo: Khớp phiên bản kernel hiện tại. Conflicts: Xung đột nếu kernel update mà không reinstall headers.
"ninja" # Build system nhanh, thường dùng với meson/cmake; cách dùng: ninja -C build. Mẹo: Parallel build với -j cores. Conflicts: Không xung đột lớn.
"python" # Ngôn ngữ lập trình, cần cho nhiều script/tool; cách dùng: python script.py. Mẹo: Virtualenv cho isolate. Conflicts: Xung đột nếu cài python2 legacy.

# GRAPHICS DRIVERS, NVIDIA - Các gói driver NVIDIA proprietary cho hỗ trợ GPU acceleration trên Wayland/Hyprland. Mẹo: Reboot sau khi cài và blacklist nouveau để tránh lỗi render. Conflicts: Xung đột với driver mã mở như nouveau hoặc phiên bản beta/legacy.
"nvidia" # Driver kernel module NVIDIA proprietary cho GeForce 8 series trở lên; cách dùng: tự động load sau cài, kiểm tra bằng nvidia-smi. Mẹo: Sử dụng cho kernel linux chuẩn, kết hợp với env variables trong hyprland.conf cho Wayland. Conflicts: Xung đột với nvidia-dkms (nếu dùng kernel custom thì dùng dkms thay thế), nouveau (blacklist trong /etc/modprobe.d).
"nvidia-utils" # Công cụ và thư viện user-space cho driver NVIDIA; cách dùng: nvidia-smi để monitor GPU, nvidia-settings để cấu hình. Mẹo: Tích hợp với waybar module cho hiển thị GPU usage. Conflicts: Có thể xung đột với phiên bản beta hoặc legacy driver, yêu cầu khớp phiên bản với nvidia.
"libva-nvidia-driver" # Implementation VA-API sử dụng NVDEC backend cho hardware video decode; cách dùng: tự động cho app như mpv hoặc ffmpeg với --hwdec=vaapi. Mẹo: Cải thiện playback video mượt mà trên NVIDIA, kiểm tra bằng vainfo. Conflicts: Yêu cầu NVIDIA driver series 515+, có thể xung đột nếu dùng backend khác như vdpau.
"egl-wayland" # Thư viện EGL external platform cho Wayland trên NVIDIA; cách dùng: tự động fix EGL issues trong compositor Wayland. Mẹo: Bắt buộc cho Hyprland/Kitty trên NVIDIA để tránh lỗi render offscreen. Conflicts: Không xung đột lớn, nhưng đảm bảo phiên bản driver NVIDIA tương thích (495+).
"mesa" # Driver đồ họa mã mở cho Intel/AMD, fallback cho NVIDIA; cách dùng: tự động cho OpenGL/Vulkan. Mẹo: Set env MESA_LOADER_DRIVER_OVERRIDE cho override. Conflicts: Xung đột nếu dùng proprietary driver hoàn toàn, nhưng cần cho hybrid GPU.
"libdrm" # Thư viện Direct Rendering Manager cho GPU access; cách dùng: tự động cho Hyprland/mesa. Mẹo: Cập nhật để fix bug render. Conflicts: Không xung đột, nhưng yêu cầu kernel mới.
"vulkan-icd-loader" # Loader cho Vulkan driver (Intel/AMD/NVIDIA); cách dùng: tự động cho app Vulkan. Mẹo: Kiểm tra vulkaninfo. Conflicts: Xung đột nếu driver không khớp (e.g., nvidia-utils).
"opengl-driver" # Driver OpenGL chung (kéo mesa hoặc proprietary); cách dùng: tự động. Mẹo: Cho game/app 3D. Conflicts: Chọn đúng cho hardware.

# FONT, ICON, CURSOR: Catppuccin Sakura Neon Pastel - Các gói liên quan đến font, icon và cursor với theme pastel neon. Mẹo: Chạy fc-cache -fv sau cài font để update cache. Conflicts: Theme GTK có thể không khớp nếu dùng Qt app; sử dụng kvantum để đồng bộ.
"ttf-jetbrains-mono-nerd" # Font code chính, hỗ trợ icon Nerd Font cho terminal/waybar; cách dùng: chọn trong kitty.conf hoặc ~/.config/waybar/config. Mẹo: Lý tưởng cho coding với ligatures. Conflicts: Không xung đột, nhưng cần Nerd Font patcher nếu custom.
"noto-fonts" # Font Unicode chuẩn cho UI/tiếng Việt; cách dùng: tự động fallback. Mẹo: Bao quát hầu hết ngôn ngữ. Conflicts: Dung lượng lớn, có thể chậm trên hệ thống yếu.
"noto-fonts-cjk" # Font cho Trung/Nhật/Hàn; cách dùng: tự động tránh lỗi ký tự vuông. Mẹo: Chỉ cài nếu cần, tiết kiệm dung lượng. Conflicts: Dung lượng rất lớn (~GB).
"catppuccin-gtk-theme-mocha" # GTK theme Catppuccin Mocha (AUR), nền pastel, border bo tròn; cách dùng: chọn qua lxappearance hoặc gsettings. Mẹo: Kết hợp với kvantum cho Qt. Conflicts: Có thể không tương thích hoàn toàn với một số app cũ.
"catppuccin-cursors-mocha" # Cursor pastel neon (AUR); cách dùng: chọn qua lxappearance hoặc export XCURSOR_THEME. Mẹo: Set HYPRCURSOR_THEME trong hyprland.conf cho Hyprland. Conflicts: Không hoạt động tốt trên X11 nếu không set đúng.
"papirus-icon-theme" # Icon hiện đại pastel, hỗ trợ nhiều app; cách dùng: chọn qua lxappearance. Mẹo: Có nhiều variant màu. Conflicts: Có thể xung đột icon fallback nếu nhiều theme cài cùng.
"adwaita-icon-theme" # Icon fallback GNOME; cách dùng: tự động nếu thiếu icon. Mẹo: Luôn giữ làm fallback. Conflicts: Không xung đột.
"breeze-icons" # Icon fallback KDE/Qt; cách dùng: tự động cho app Qt. Mẹo: Tốt cho app KDE. Conflicts: Không xung đột.
"hicolor-icon-theme" # Icon base fallback; cách dùng: tự động. Mẹo: Bắt buộc cho icon system. Conflicts: Không xung đột.
"ttf-font-awesome" # Font icon phổ biến cho UI và Waybar (bổ sung để hỗ trợ thêm biểu tượng trong thanh bar và launcher); cách dùng: tự động fallback trong các app hỗ trợ Nerd Fonts. Mẹo: Kết hợp với Nerd Fonts cho waybar modules. Conflicts: Có thể chồng chéo với nerd-fonts nếu cài đầy đủ.
"ttf-nerd-fonts-symbols" # Biểu tượng Nerd Fonts đầy đủ cho ricing (bổ sung để hỗ trợ icon trong waybar, terminal); cách dùng: tự động cho app hỗ trợ. Mẹo: Chọn variant mono cho space saving. Conflicts: Dung lượng lớn nếu cài full set.

# Input Method - Các gói cho bộ gõ tiếng Việt và input method. Mẹo: Thêm env GTK_IM_MODULE=fcitx5 vào hyprland.conf để tích hợp. Conflicts: Xung đột với ibus nếu cài song song; chọn một IM duy nhất.
"fcitx5" # Nhân bộ gõ Fcitx5; cách dùng: fcitx5 để chạy. Mẹo: Chạy daemon với fcitx5 -d. Conflicts: Cần restart session sau cài.
"fcitx5-unikey" # Bộ gõ tiếng Việt Unikey; cách dùng: cấu hình trong fcitx5-configtool. Mẹo: Set Telex/VNI theo sở thích. Conflicts: Không xung đột lớn.
"fcitx5-configtool" # GUI cấu hình Fcitx5; cách dùng: fcitx5-configtool để mở. Mẹo: Thêm addon nếu cần. Conflicts: Không xung đột.
"fcitx5-gtk" # Hỗ trợ GTK app (VSCode, Firefox); cách dùng: tự động. Mẹo: Set env cho app cụ thể nếu lỗi. Conflicts: Không xung đột.
"fcitx5-qt" # Hỗ trợ Qt app (Telegram); cách dùng: tự động. Mẹo: Tương tự GTK. Conflicts: Không xung đột.
"fcitx5-lua" # Hỗ trợ extension Lua; cách dùng: viết script Lua cho Fcitx5. Mẹo: Dùng cho custom macro. Conflicts: Không xung đột.
"libinput" # Thư viện xử lý input (keyboard/mouse/touchpad); cách dùng: tự động cho Hyprland. Mẹo: Cấu hình gesture trong hyprland.conf. Conflicts: Xung đột với evdev nếu dùng X11 legacy.

# HYPRLAND CORE, TOOLKIT, PORTAL - Các gói cốt lõi cho Hyprland WM và hỗ trợ Wayland. Mẹo: Build Hyprland từ git nếu cần feature mới. Conflicts: Xung đột với NVIDIA driver cũ; dùng nouveau hoặc proprietary mới.
"hyprland" # WM Wayland nhẹ, hiệu ứng đẹp; cách dùng: exec Hyprland trong ~/.xinitrc hoặc display manager. Mẹo: Bind key trong conf cho productivity. Conflicts: Không chạy tốt trên VM thiếu GPU accel.
"hyprcursor" # Theme/tool con trỏ Hyprland; cách dùng: hyprctl setcursor. Mẹo: Set size với HYPRCURSOR_SIZE. Conflicts: Không xung đột.
"hyprlock" # Khóa màn hình (AUR); cách dùng: hyprlock để khóa. Mẹo: Custom theme trong conf. Conflicts: Không xung đột.
"hyprpaper" # Wallpaper đa màn; cách dùng: hyprpaper & trong hyprland.conf. Mẹo: Preload image để nhanh. Conflicts: Không xung đột, nhưng swaybg thay thế nếu cần.
"hyprland-qt-support" # Fix scale/blur cho Qt; cách dùng: tự động. Mẹo: Set env QT_QPA_PLATFORM=wayland. Conflicts: Không xung đột.
"hyprutils" # Tool diagnostic (AUR); cách dùng: hyprctl cho debug. Mẹo: Hyprctl monitors để check display. Conflicts: Không xung đột.
"hyprgraphics" # Extension hiệu ứng (AUR); cách dùng: tích hợp vào hyprland.conf. Mẹo: Enable cho animation mượt. Conflicts: Có thể làm chậm hệ thống yếu.
"xdg-desktop-portal-hyprland" # Portal cho share màn/share file; cách dùng: tự động cho app. Mẹo: Restart pipewire sau cài. Conflicts: Xung đột nếu nhiều portal cài.
"xdg-desktop-portal" # Portal chung cho Flatpak; cách dùng: tự động. Mẹo: Bắt buộc cho flatpak. Conflicts: Chọn backend đúng.
"xdg-desktop-portal-gtk" # Portal GTK; cách dùng: tự động. Mẹo: Cho app GTK. Conflicts: Không xung đột.
"xdg-desktop-portal-wlr" # Portal cho WM khác; cách dùng: tự động. Mẹo: Fallback. Conflicts: Không xung đột.
"xorg-xwayland" # Chạy app X11 trên Wayland; cách dùng: tự động. Mẹo: Set env để force Wayland. Conflicts: Có thể gây lỗi scale trên high DPI.
"hypridle" # Quản lý idle cho Hyprland (bổ sung để tự động khóa màn hình khi idle, tương tự swayidle nhưng tích hợp tốt hơn với Hyprland); cách dùng: hypridle & trong hyprland.conf, chỉnh ~/.config/hypr/hypridle.conf. Mẹo: Set timeout hợp lý để tiết kiệm pin. Conflicts: Xung đột với swayidle nếu chạy cùng.
"hyprpicker" # Color picker cho Wayland (bổ sung để chọn màu từ màn hình, hữu ích cho chọn màu ricing và thiết kế); cách dùng: hyprpicker -a để copy màu vào clipboard. Mẹo: Bind key cho quick access. Conflicts: Không xung đột.
"aquamarine" # Thư viện rendering cho Hyprland; cách dùng: tự động. Mẹo: Cải thiện hiệu suất render. Conflicts: Không xung đột, dep của hyprland.
"cairo" # Thư viện vẽ 2D; cách dùng: tự động cho UI. Mẹo: Vector graphics. Conflicts: Không xung đột.
"glib2" # Core app libs; cách dùng: tự động. Mẹo: GObject system. Conflicts: Không xung đột.
"glslang" # Shader compiler; cách dùng: tự động cho Vulkan. Mẹo: GLSL to SPIR-V. Conflicts: Không xung đột.
"hyprlang" # Ngôn ngữ config cho Hyprland; cách dùng: tự động cho conf. Mẹo: Syntax highlight. Conflicts: Không xung đột.
"libdisplay-info" # Info display EDID; cách dùng: tự động cho monitors. Mẹo: Detect resolution. Conflicts: Không xung đột.
"libliftoff" # Layer allocation lib; cách dùng: tự động cho compositor. Mẹo: Optimize planes. Conflicts: Không xung đột.
"libxcomposite" # X11 composite; cách dùng: tự động cho XWayland. Mẹo: Transparency. Conflicts: Không xung đột.
"libxfixes" # X11 fixes; cách dùng: tự động. Mẹo: Bug fixes. Conflicts: Không xung đột.
"libxkbcommon" # Keyboard handling; cách dùng: tự động cho input. Mẹo: Layout switch. Conflicts: Không xung đột.
"libxkbcommon-x11" # X11 support cho xkb; cách dùng: tự động cho XWayland. Mẹo: Legacy app. Conflicts: Không xung đột.
"libxrender" # X11 render; cách dùng: tự động. Mẹo: Anti-aliasing. Conflicts: Không xung đột.
"pango" # Text layout; cách dùng: tự động cho fonts. Mẹo: Unicode render. Conflicts: Không xung đột.
"pixman" # Pixel manipulation; cách dùng: tự động cho cairo. Mẹo: Low-level graphics. Conflicts: Không xung đột.
"polkit" # Authorization framework; cách dùng: tự động cho privilege. Mẹo: Rules in /etc/polkit-1. Conflicts: Không xung đột.
"seatd" # Seat manager minimal; cách dùng: tự động cho Hyprland. Mẹo: Launch with seatd-launch. Conflicts: Xung đột logind nếu config sai.
"systemd-libs" # Core systemd libs; cách dùng: tự động. Mẹo: Journalctl. Conflicts: Không xung đột.
"wayland" # Core Wayland protocol; cách dùng: tự động cho compositor. Mẹo: Env WAYLAND_DISPLAY. Conflicts: Không xung đột.
"xcb-proto" # XCB protocols; cách dùng: tự động cho build. Mẹo: XML defs. Conflicts: Không xung đột.

# BAR, LAUNCHER, NOTIFY, CLIPBOARD, THEME - Các gói cho thanh bar, launcher, thông báo và clipboard. Mẹo: Custom CSS cho waybar để ricing. Conflicts: Dunst có thể xung đột với mako nếu dùng Sway.
"waybar" # Thanh bar Wayland, ricing mạnh; cách dùng: waybar & trong hyprland.conf, chỉnh ~/.config/waybar/config. Mẹo: Thêm modules custom. Conflicts: Cần font nerd cho icon.
"wofi" # Launcher nhẹ, đồng bộ icon; cách dùng: bindkey wofi --show drun. Mẹo: Custom style với CSS. Conflicts: Không xung đột.
"dunst" # Notification daemon, popup tùy biến; cách dùng: dunst & , chỉnh ~/.config/dunst/dunstrc. Mẹo: Set urgency cho notify. Conflicts: Không xung đột.
"wl-clipboard" # Copy/paste Wayland; cách dùng: wl-copy/wl-paste. Mẹo: Tích hợp với vim. Conflicts: Không hoạt động trên X11.
"grim" # Chụp màn Wayland; cách dùng: grim output.png. Mẹo: Kết hợp slurp cho region. Conflicts: Không xung đột.
"slurp" # Chọn vùng màn; cách dùng: grim -g "$(slurp)". Mẹo: Set border color. Conflicts: Không xung đột.
"swappy" # Annotate ảnh chụp; cách dùng: grim | swappy -f -. Mẹo: Custom tool trong conf. Conflicts: Không xung đột.
"cliphist" # Clipboard manager cho Wayland (bổ sung để lưu lịch sử copy/paste, xem và paste lại các item cũ); cách dùng: wl-paste --watch cliphist store, rồi cliphist list | wofi -d -p "Clipboard" | cliphist decode | wl-copy. Mẹo: Run daemon ở startup. Conflicts: Xung đột với gpaste nếu cài.

# SYSTEM INFO, MONITOR, ASCII/FUN - Các gói theo dõi hệ thống và công cụ vui ASCII. Mẹo: Alias fastfetch trong .bashrc cho startup. Conflicts: btop và htop tương tự, chọn một để tiết kiệm.
"fastfetch" # Show info hệ thống/logo; cách dùng: fastfetch. Mẹo: Custom logo. Conflicts: Không xung đột.
"htop" # Monitor tiến trình; cách dùng: htop. Mẹo: Sort bằng CPU. Conflicts: Không xung đột.
"btop" # Monitor CPU/RAM/NET/DISK; cách dùng: btop. Mẹo: Theme custom. Conflicts: Không xung đột.
"nvtop" # Monitor GPU; cách dùng: nvtop. Mẹo: Chỉ cho NVIDIA. Conflicts: Xung đột nếu không có NVIDIA.
"bashtop" # Monitor ascii; cách dùng: bashtop. Mẹo: Legacy của btop. Conflicts: Không xung đột.
"lm_sensors" # Nhiệt độ CPU/GPU; cách dùng: sensors. Mẹo: Cài fancontrol nếu cần. Conflicts: Cần kernel module.
"smartmontools" # Kiểm tra ổ cứng; cách dùng: smartctl -i /dev/sdX. Mẹo: Schedule test định kỳ. Conflicts: Không xung đột.
"gnome-calendar" # Ứng dụng lịch GNOME; cách dùng: gnome-calendar. Mẹo: Tích hợp tài khoản trực tuyến như Google. Conflicts: Cần các thư viện GNOME, có thể nặng nếu không dùng GNOME.
"xfce4-power-manager" # Quản lý năng lượng và DPMS; cách dùng: xfce4-power-manager-settings. Mẹo: Cấu hình brightness và suspend actions. Conflicts: Có thể xung đột với xscreensaver nếu cả hai quản lý blanking.
"cava" # Visualizer âm thanh terminal; cách dùng: cava. Mẹo: Tích hợp pipewire. Conflicts: Không xung đột.
"figlet" # In ascii text lớn; cách dùng: figlet Hello. Mẹo: Kết hợp lolcat. Conflicts: Không xung đột.
"toilet" # In ascii màu; cách dùng: toilet Hello. Mẹo: Font custom. Conflicts: Không xung đột.
"lolcat" # Gradient text; cách dùng: echo Hello | lolcat. Mẹo: Speed adjust. Conflicts: Không xung đột.
"hollywood" # Fake hacker terminal; cách dùng: hollywood. Mẹo: Fun only. Conflicts: Không xung đột.
"unimatrix" # Matrix digital rain với custom chars; cách dùng: unimatrix. Mẹo: -c cho character set tùy chỉnh, điều chỉnh speed với -s. Conflicts: Không xung đột.
"cbonsai" # Bonsai ASCII động; cách dùng: cbonsai. Mẹo: Grow tree. Conflicts: Không xung đột.
"cowsay" # Bò nói chuyện; cách dùng: cowsay Hello. Mẹo: Kết hợp fortune. Conflicts: Không xung đột.
"ponysay" # Pony nói (AUR); cách dùng: ponysay Hello. Mẹo: Pony list. Conflicts: Không xung đột.
"fortune-mod" # Random quote; cách dùng: fortune. Mẹo: Pipe cowsay. Conflicts: Không xung đột.
"sl" # Tàu hoả khi gõ nhầm ls; cách dùng: sl. Mẹo: Fun alias. Conflicts: Không xung đột.
"nyancat" # Mèo cầu vồng; cách dùng: nyancat. Mẹo: Infinite loop. Conflicts: Không xung đột.
"pipes-rs" # Ống nước ASCII Rust; cách dùng: pipes-rs. Mẹo: Color custom. Conflicts: Không xung đột.
"pipes.sh" # Ống nước bash; cách dùng: pipes.sh. Mẹo: Legacy. Conflicts: Không xung đột.
"asciiquarium" # Bể cá ASCII (AUR); cách dùng: asciiquarium. Mẹo: Add fish. Conflicts: Không xung đột.
"chafa" # Show ảnh ASCII; cách dùng: chafa image.jpg. Mẹo: Scale. Conflicts: Không xung đột.
"jp2a" # JPG thành ascii; cách dùng: jp2a image.jpg. Mẹo: Width adjust. Conflicts: Không xung đột.
"ytfzf" # Stream Youtube terminal (AUR); cách dùng: ytfzf query. Mẹo: Mp4 format. Conflicts: Cần yt-dlp.
"ueberzugpp" # Hiển thị ảnh trong terminal (AUR); cách dùng: tích hợp ranger. Mẹo: Ranger preview. Conflicts: Không hoạt động trên Wayland terminal.
"glow" # Markdown preview; cách dùng: glow file.md. Mẹo: Theme dark. Conflicts: Không xung đột.
"screenfetch" # System info retro; cách dùng: screenfetch. Mẹo: Legacy fastfetch. Conflicts: Không xung đột.

# BRIGHTNESS, AUDIO, POLKIT - Các gói điều chỉnh sáng, âm thanh và xác thực. Mẹo: Pipewire là future-proof, thay pulseaudio. Conflicts: Pipewire xung đột pulseaudio; remove pulse trước.
"brightnessctl" # Điều chỉnh sáng màn; cách dùng: brightnessctl s 50%. Mẹo: Bind key. Conflicts: Không hoạt động trên desktop không backlight.
"pipewire" # Core PipeWire framework; cách dùng: tự động. Mẹo: Enable service. Conflicts: Xung đột pulseaudio.
"pipewire-audio" # Audio server PipeWire; cách dùng: tự động. Mẹo: Như trên. Conflicts: Như trên.
"pipewire-pulse" # PulseAudio compatibility layer; cách dùng: tự động. Mẹo: Cho app cũ. Conflicts: Như trên.
"pipewire-alsa" # ALSA integration for PipeWire; cách dùng: tự động. Mẹo: Như trên. Conflicts: Như trên.
"wireplumber" # Audio session PipeWire; cách dùng: tự động. Mẹo: Thay jack nếu cần. Conflicts: Xung đột pipewire-jack.
"pavucontrol" # GUI volume; cách dùng: pavucontrol. Mẹo: Per-app volume. Conflicts: Không xung đột.
"pamixer" # CLI volume; cách dùng: pamixer -i 5. Mẹo: Script waybar. Conflicts: Không xung đột.
"alsa-utils" # ALSA tools; cách dùng: alsamixer. Mẹo: Unmute channel. Conflicts: Không xung đột.
"sof-firmware" # Firmware âm thanh Intel/AMD; cách dùng: tự động. Mẹo: Update kernel. Conflicts: Không xung đột nếu hardware khớp.
"polkit-kde-agent" # Auth agent Qt; cách dùng: tự động. Mẹo: Cho app Qt. Conflicts: Chọn một agent.
"polkit-gnome" # Auth agent GTK; cách dùng: tự động. Mẹo: Cho app GTK. Conflicts: Như trên.
"playerctl" # Điều khiển nhạc; cách dùng: playerctl play-pause. Mẹo: Waybar module. Conflicts: Không xung đột.
"gammastep" # Điều chỉnh gamma/nhiệt độ màu màn hình (bổ sung để giảm ánh sáng xanh ban đêm, tương tự Redshift cho Wayland); cách dùng: gammastep -O 4500 để set nhiệt độ màu. Mẹo: Geolocation auto. Conflicts: Không xung đột, nhưng trùng redshift nếu cài.

# TERMINAL, EDITOR, FILE MANAGER - Các gói terminal, editor và quản lý file. Mẹo: Kitty nhanh GPU. Conflicts: Thunar GTK, ark Qt; đồng bộ theme.
"kitty" # Terminal GPU hiện đại; cách dùng: kitty, chỉnh ~/.config/kitty/kitty.conf. Mẹo: Tab và split. Conflicts: Không xung đột.
"code" # Best Editor; cách dùng: code. Mẹo: Beginner friendly. Conflicts: Không xung đột.
"vim" # Editor mạnh; cách dùng: vim file. Mẹo: Plugin via vim-plug. Conflicts: Không xung đột.
"neovim" # Editor nâng cấp vim; cách dùng: nvim file. Mẹo: Lua config. Conflicts: Không xung đột.
"nano" # Editor đơn giản; cách dùng: nano file. Mẹo: Beginner friendly. Conflicts: Không xung đột.
"thunar" # File manager GTK; cách dùng: thunar. Mẹo: Custom action. Conflicts: Không xung đột.
"thunar-archive-plugin" # Plugin nén/giải nén cho Thunar; cách dùng: tự động right-click. Mẹo: Như trên. Conflicts: Không xung đột.
"thunar-volman" # Auto-mount USB cho Thunar; cách dùng: tự động. Mẹo: Như trên. Conflicts: Không xung đột.
"gvfs" # Mount ftp/smb/trash; cách dùng: tự động trong file manager. Mẹo: Network share. Conflicts: Không xung đột.
"gvfs-mtp" # Mount Android MTP; cách dùng: tự động. Mẹo: Android file. Conflicts: Không xung đột.
"tumbler" # Thumbnailer cho Thunar; cách dùng: tự động. Mẹo: Speed up preview. Conflicts: Không xung đột.
"ffmpegthumbnailer" # Thumbnail video; cách dùng: tự động. Mẹo: Video preview. Conflicts: Không xung đột.
"file-roller" # GUI nén/giải nén GTK; cách dùng: file-roller file.zip. Mẹo: Extract here. Conflicts: Không xung đột.
"ranger" # File manager terminal; cách dùng: ranger. Mẹo: Vim key. Conflicts: Không xung đột.
"lf" # File manager nhẹ (AUR); cách dùng: lf. Mẹo: Go-like. Conflicts: Không xung đột.
"bat" # Xem file highlight; cách dùng: bat file. Mẹo: Alias cat. Conflicts: Không xung đột.
"tree" # Cấu trúc thư mục CLI; cách dùng: tree. Mẹo: -L level. Conflicts: Không xung đột.
"font-manager" # Quản lý font GUI; cách dùng: font-manager. Mẹo: Install/uninstall font. Conflicts: Không xung đột.
"ark" # GUI nén Qt; cách dùng: ark file.zip. Mẹo: KDE style. Conflicts: Không xung đột.
"udiskie" # Auto-mount disks và USB (bổ sung để tự động mount ổ đĩa mà không cần file manager, hữu ích cho Hyprland); cách dùng: udiskie & trong hyprland.conf, udiskie-mount /dev/sdX để mount. Mẹo: Notify on mount. Conflicts: Xung đột gvfs nếu config sai.

# NETWORK, BLUETOOTH, SSH - Các gói mạng, Bluetooth và SSH. Mẹo: Nm-applet cho tray. Conflicts: Iwd vs wpa_supplicant; chọn iwd cho nhẹ.
"networkmanager" # Quản lý mạng wifi/eth; cách dùng: nmcli con up id. Mẹo: VPN support. Conflicts: Xung đột systemd-networkd nếu enable.
"network-manager-applet" # Systray icon NM; cách dùng: nm-applet &. Mẹo: Right click connect. Conflicts: Không xung đột.
"blueman" # Bluetooth GUI; cách dùng: blueman-manager. Mẹo: Pair device. Conflicts: Không xung đột.
"bluez" # Bluetooth stack; cách dùng: tự động. Mẹo: Enable service. Conflicts: Không xung đột.
"bluez-utils" # CLI bluez; cách dùng: bluetoothctl. Mẹo: Scan on. Conflicts: Không xung đột.
"iwd" # Backend WiFi nhẹ; cách dùng: iwctl. Mẹo: Faster than wpa. Conflicts: Xung đột wpa_supplicant.
"openssh" # SSH server/client; cách dùng: ssh user@host. Mẹo: Key auth. Conflicts: Không xung đột.
"firewalld" # GUI cấu hình firewall (bổ sung để quản lý tường lửa, tăng bảo mật cho hệ thống mạng); cách dùng: firewall-config để mở GUI. Mẹo: Add zone. Conflicts: Ufw vs firewalld; chọn một.

# MEDIA PLAYER, IMAGE VIEWER - Các gói phát media và xem ảnh. Mẹo: Mpv script cho sub. Conflicts: VLC nặng hơn mpv.
"mpv" # Player nhẹ; cách dùng: mpv file.mp4. Mẹo: Hardware decode. Conflicts: Không xung đột.
"vlc" # Player đa năng; cách dùng: vlc file.mp4. Mẹo: Network stream. Conflicts: Không xung đột.
"feh" # Xem ảnh X11; cách dùng: feh image.jpg. Mẹo: Slideshow. Conflicts: Không Wayland native.
"imv" # Xem ảnh Wayland; cách dùng: imv image.jpg. Mẹo: Zoom. Conflicts: Không xung đột.
"imagemagick" # Xử lý ảnh; cách dùng: convert image.jpg -resize 50% out.jpg. Mẹo: Batch process. Conflicts: Không xung đột.
"gimp" # Photoshop open source; cách dùng: gimp. Mẹo: Plugin. Conflicts: Dung lượng lớn.
"inkscape" # Vẽ vector; cách dùng: inkscape. Mẹo: SVG edit. Conflicts: Không xung đột.
"krita" # Digital painting; cách dùng: krita. Mẹo: Brush custom. Conflicts: Không xung đột.
"yt-dlp" # Download Youtube; cách dùng: yt-dlp URL. Mẹo: Best quality. Conflicts: Không xung đột.
"shotcut" # Video editor nhẹ; cách dùng: shotcut. Mẹo: Timeline. Conflicts: Không xung đột.
"kdenlive" # Video editor mạnh; cách dùng: kdenlive. Mẹo: Effect. Conflicts: Không xung đột.
"obs-studio" # Quay màn/livestream; cách dùng: obs. Mẹo: Wayland capture. Conflicts: Cần portal.
"ffmpeg" # Công cụ xử lý video/audio; cách dùng: ffmpeg -i input output. Mẹo: Encode/decode. Conflicts: Không xung đột, dep cho nhiều app.

# DISPLAY, MIRACAST, WAYLAND UTILITY - Các gói quản lý hiển thị và tiện ích Wayland. Mẹo: Wlr-randr cho scale. Conflicts: Multi-monitor cần config Hyprland.
"wdisplays" # Quản lý multi display; cách dùng: wdisplays. Mẹo: Arrange screen. Conflicts: Không xung đột.
"gnome-network-displays" # Miracast GUI; cách dùng: gnome-network-displays. Mẹo: Cast screen. Conflicts: Không xung đột.
"swaybg" # Wallpaper Wayland; cách dùng: swaybg -i image.jpg. Mẹo: Fallback hyprpaper. Conflicts: Không xung đột.
"swayidle" # Idle manager; cách dùng: swayidle -w timeout 300 'swaylock'. Mẹo: DPMS off. Conflicts: Xung đột hypridle.
"wayland-utils" # Debug Wayland; cách dùng: wayland-info. Mẹo: Check compositor. Conflicts: Không xung đột.
"waypipe" # Remote app Wayland (AUR); cách dùng: waypipe run command. Mẹo: SSH Wayland. Conflicts: Không xung đột.
"wlr-randr" # Set display scale; cách dùng: wlr-randr --output eDP-1 --scale 1.5. Mẹo: Fractional scale. Conflicts: Không xung đột.
"kanshi" # Quản lý profile màn hình động (bổ sung để tự động thay đổi cấu hình màn hình khi kết nối/disconnect external display); cách dùng: kanshi & trong hyprland.conf, chỉnh ~/.config/kanshi/config. Mẹo: Profile per display. Conflicts: Không xung đột.
"wayland-protocols" # Protocols mở rộng cho Wayland; cách dùng: tự động cho dev. Mẹo: Build deps. Conflicts: Không xung đột.

# GIẢI NÉN/ĐÓNG GÓI - Các gói nén và giải nén file. Mẹo: P7zip nhanh hơn zip. Conflicts: Unrar proprietary, nhưng cần cho rar.
"unzip" # Giải nén .zip; cách dùng: unzip file.zip. Mẹo: -d dir. Conflicts: Không xung đột.
"zip" # Đóng .zip; cách dùng: zip -r archive.zip dir. Mẹo: -9 max compress. Conflicts: Không xung đột.
"p7zip" # Nén/giải 7z/rar; cách dùng: 7z x file.7z. Mẹo: Multi-thread. Conflicts: Không xung đột.
"unrar" # Giải .rar; cách dùng: unrar x file.rar. Mẹo: Password support. Conflicts: Không xung đột.
"fuse" # Mount AppImage/zip; cách dùng: tự động cho AppImage. Mẹo: Fuse3 mới. Conflicts: Không xung đột.

# PDF, OFFICE, DOCUMENT - Các gói xem PDF và văn phòng. Mẹo: Zathura nhẹ nhất. Conflicts: Libreoffice lớn, onlyoffice cho docx tốt hơn.
"evince" # Xem PDF GTK; cách dùng: evince file.pdf. Mẹo: Annotate. Conflicts: Không xung đột.
"zathura" # PDF nhẹ vim-like; cách dùng: zathura file.pdf. Mẹo: Keybinding. Conflicts: Không xung đột.
"okular" # PDF KDE mạnh; cách dùng: okular file.pdf. Mẹo: Sign PDF. Conflicts: Không xung đột.
"libreoffice-fresh" # Office miễn phí; cách dùng: libreoffice. Mẹo: Template. Conflicts: Dung lượng lớn.
"libreoffice-fresh-vi" # Giao diện tiếng Việt; cách dùng: tự động. Mẹo: Language pack. Conflicts: Không xung đột.
"onlyoffice-bin" # Office chuẩn docx (AUR); cách dùng: onlyoffice-desktopeditors. Mẹo: Cloud integrate. Conflicts: Không xung đột.
"glow" # Markdown preview; cách dùng: glow file.md. Mẹo: TUI mode. Conflicts: Không xung đột.

# THEME/SETTING - Các gói theme và cấu hình giao diện. Mẹo: Lxappearance cho GTK, qt5ct cho Qt. Conflicts: Kvantum cần Qt5.
"kvantum-qt5" # Theme engine Qt blur; cách dùng: kvantummanager để chọn theme. Mẹo: Blur effect. Conflicts: Không xung đột.
"lxappearance" # GUI chọn theme GTK/icon/cursor; cách dùng: lxappearance. Mẹo: Apply system-wide. Conflicts: Không xung đột.
"qt5ct" # GUI chọn theme Qt; cách dùng: qt5ct. Mẹo: Env QT_QPA_PLATFORMTHEME=qt5ct. Conflicts: Không xung đột.

# BROWSER - Các gói trình duyệt web cơ bản (bổ sung nhóm mới vì thiếu trình duyệt là cần thiết cho hệ thống full chức năng). Mẹo: Firefox Wayland cho Hyprland. Conflicts: Chromium nặng RAM.
"firefox" # Trình duyệt web an toàn, hỗ trợ Wayland; cách dùng: firefox để mở, thêm --enable-wayland cho tối ưu. Mẹo: Profile manager. Conflicts: Không xung đột.

# POWER MANAGEMENT - Các gói quản lý năng lượng (bổ sung nhóm mới để hỗ trợ laptop, tiết kiệm pin và quản lý power). Mẹo: Tlp cho laptop. Conflicts: Tlp xung đột auto-cpufreq nếu dùng.
"upower" # Dịch vụ power management (bổ sung để theo dõi pin, suspend/resume); cách dùng: tự động, upower -e để liệt kê devices. Mẹo: Integrate waybar. Conflicts: Không xung đột.

# DISPLAY MANAGER - Các gói cho display manager để login vào Hyprland từ boot (bổ sung để chuyển từ minimal tty sang full desktop). Mẹo: Ly hỗ trợ Wayland tốt và lightweight. Conflicts: Xung đột nếu nhiều DM cài, chọn một.
"ly" # Display manager lightweight TUI-based (ncurses-like); cách dùng: systemctl enable ly. Mẹo: Custom config in /etc/ly/config.ini for themes and sessions. Conflicts: Xung đột lightdm/gdm nếu enable cùng.
)