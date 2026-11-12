import 'package:flutter_test/flutter_test.dart';
import 'package:tadbeer/features/audio/desktop_player.dart';

void main() {
  test('names the libmpv package of each Linux family', () {
    expect(
      mpvInstallCommand('NAME="Fedora Linux"\nID=fedora\nVERSION_ID=44\n'),
      'sudo dnf install mpv-libs',
    );
    expect(
      mpvInstallCommand('ID=linuxmint\nID_LIKE="ubuntu debian"\n'),
      'sudo apt install libmpv2',
    );
    expect(
      mpvInstallCommand('ID=manjaro\nID_LIKE=arch\n'),
      'sudo pacman -S mpv',
    );
    expect(
      mpvInstallCommand('ID="opensuse-tumbleweed"\nID_LIKE="opensuse suse"\n'),
      'sudo zypper install libmpv2',
    );
    expect(mpvInstallCommand(''), 'libmpv (mpv)');
  });
}
