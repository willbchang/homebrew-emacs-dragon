# coding: utf-8
class EmacsDragon < Formula
  desc "YAMAMOTO Mitsuharu's Mac port of GNU Emacs"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://bitbucket.org/mituharu/emacs-mac/get/emacs-28.1-mac-9.0.tar.gz"
  version "emacs-28.1-mac-9.0"
  sha256 "967d5642ca47ae3de2626f0fc7163424e36925642827e151c3906179020dd90e"

  head "https://bitbucket.org/mituharu/emacs-mac.git", branch: "work"

  option "with-native-comp", "Build with native compilation"

  resource "emacs-dragon-icon" do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/icons/emacs-dragon-icon.icns"
    sha256 "a0a624e6a08971f2f9220d2a3aaa79e1f8aecc85df8a522ebb40310c54699c40"
  end

  depends_on "autoconf"
  depends_on "automake"
  depends_on "gnutls"
  depends_on "librsvg"
  depends_on "pkg-config"
  depends_on "texinfo"
  depends_on "jansson" => :recommended
  depends_on "libxml2" => :recommended
  depends_on "glib" => :optional
  depends_on "imagemagick" => :optional
  depends_on "rg"
  depends_on "fd"
  depends_on "cmake"
  depends_on "libvterm"

  # depends_on cask: "font-roboto-mono"
  if `system_profiler SPFontsDataType | grep 'RobotoMono.*\.ttf'`.empty?
    `/usr/local/bin/brew tap homebrew/cask-fonts`
    `/usr/local/bin/brew --cask install font-roboto-mono`
  end

  patch do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/emacs-mac-title-bar-9.0.patch"
    sha256 "4c719da92bf7744bb7931315ddcca78b190d7513adf49f86e7c2ae93dacfc68b"
  end

  # patch for multi-tty support, see the following links for details
  # https://bitbucket.org/mituharu/emacs-mac/pull-requests/2/add-multi-tty-support-to-be-on-par-with/diff
  # https://ylluminarious.github.io/2019/05/23/how-to-fix-the-emacs-mac-port-for-multi-tty-access/
  patch do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/multi-tty-27.diff"
    sha256 "2a5121169a2442ea93611994a448a0035ccfaf1344e7ee1ff3cd94d914747625"
  end

  # Suppress Messages
  patch do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/suppress-message.patch"
    sha256 "c1077cc2bf5bd46414f8bc53c284f9105f1afd574a8b96d7f24218d09d814075"
  end

  # Mac Native keybindings
  patch do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/mac-native-keybindings.patch"
    sha256 "ba29b0a8801b62931df75c5b83f3f274c9419427b2c8ad5d9e0958cad2d31ca9"
  end

  # Mac Font
  patch do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/mac-font.patch"
    sha256 "356642613d90311061d22b4d0d961c16338129fd73d4147b8c10524c5b634362"
  end


  # Better Default UI
  patch do
    url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/better-default-UI.patch"
    sha256 "8eca17bd4404672ee341932b6158ef8132783534c6a419cabeccca92dbb4d373"
  end

#   stable do
#     patch do
#       url "https://raw.githubusercontent.com/willbchang/homebrew-emacs-dragon/master/patches/mac-arm-fix.diff"
#       sha256 "9b58a61931e79863caa5c310a7ec290cc7b84c78aa0086d0ba7192756c370db8"
#     end
#   end

  head do
    if build.with? "native-comp"
      opoo "native-comp option only works with --HEAD, check issue \#274 before installation"
      depends_on "libgccjit" => :recommended
      depends_on "gcc" => :build
    end
  end

  def install
    args = [
      "--enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp",
      "--infodir=#{info}/emacs",
      "--prefix=#{prefix}",
      "--with-mac",
      "--enable-mac-app=#{prefix}",
      "--with-gnutls",
      "--with-modules",
      "--with-rsvg",
    ]
    args << "--with-native-compilation" if build.with? "native-comp"

    if build.with? "native-comp"
      gcc_ver = Formula["gcc"].any_installed_version
      gcc_ver_major = gcc_ver.major
      gcc_lib="#{HOMEBREW_PREFIX}/lib/gcc/#{gcc_ver_major}"

      ENV.append "CFLAGS", "-I#{Formula["gcc"].include}"
      ENV.append "CFLAGS", "-I#{Formula["libgccjit"].include}"

      ENV.append "LDFLAGS", "-L#{gcc_lib}"
      ENV.append "LDFLAGS", "-I#{Formula["gcc"].include}"
      ENV.append "LDFLAGS", "-I#{Formula["libgccjit"].include}"
    end

    icons_dir = buildpath/"mac/Emacs.app/Contents/Resources"
    resource("emacs-dragon-icon").stage do
      icons_dir.install Dir["*.icns*"].first => "Emacs.icns"
    end

    system "./autogen.sh"
    system "./configure", *args
    system "make"
    system "make", "install"
    prefix.install "NEWS-mac"

    # Follow Homebrew and don't install ctags from Emacs. This allows Vim
    # and Emacs and exuberant ctags to play together without violence.
    if build.without? "ctags"
      (bin/"ctags").unlink
      (share/man/man1/"ctags.1.gz").unlink
    end

    # Replace the symlink with one that starts GUI
    # alignment the behavior with cask
    # borrow the idea from emacs-plus
    (bin/"emacs").unlink
    (bin/"emacs").write <<~EOS
      #!/bin/bash
      exec #{prefix}/Emacs.app/Contents/MacOS/Emacs.sh "$@"
    EOS
  end

  def post_install
    if build.head? and build.with? "native-comp"
      ln_sf "#{Dir[opt_prefix/"lib/emacs/*"].first}/native-lisp", "#{opt_prefix}/Emacs.app/Contents/native-lisp"
    end
  end

  def caveats
    # TODO: Check if there is a Emacs
    `osascript -e 'tell application "Finder" to make alias file to POSIX file "#{prefix}/Emacs.app" at POSIX file "/Applications"'`

    <<~EOS
      This is YAMAMOTO Mitsuharu's "Mac port" addition to
      GNU Emacs 27. This provides a native GUI support for Mac OS X
      10.6 - 12. After installing, see README-mac and NEWS-mac
      in #{prefix} for the port details.

      Emacs.app was installed to:
        #{prefix}

    EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
