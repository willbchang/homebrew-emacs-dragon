# coding: utf-8
class EmacsMac < Formula
  desc "YAMAMOTO Mitsuharu's Mac port of GNU Emacs"
  homepage "https://www.gnu.org/software/emacs/"
  url "https://bitbucket.org/mituharu/emacs-mac/get/emacs-28.1-mac-9.0.tar.gz"
  version "emacs-28.1-mac-9.0"
  sha256 "967d5642ca47ae3de2626f0fc7163424e36925642827e151c3906179020dd90e"

  head "https://bitbucket.org/mituharu/emacs-mac.git", branch: "work"

  option "with-rsvg", "Build with rsvg support"
  option "with-starter", "Build with a starter script to start emacs GUI from CLI"
  option "with-mac-metal", "use Metal framework in application-side double buffering (experimental)"
  option "with-native-comp", "Build with native compilation"

  # Emacs Dragon Icon
  resource do
    url "https://raw.githubusercontent.com/willbchang/brew-emacs-dragon/main/icons/emacs-dragon-icon.icns"
    sha256 "a0a624e6a08971f2f9220d2a3aaa79e1f8aecc85df8a522ebb40310c54699c40"
  end

  depends_on "autoconf"
  depends_on "automake"
  depends_on "gnutls"
  depends_on "librsvg" if build.with? "rsvg"
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
  depends_on cask: "font-roboto-mono"

  patch do
    url "https://raw.githubusercontent.com/willbchang/brew-emacs-dragon/main/patches/emacs-mac-title-bar-9.0.patch"
    sha256 "4c719da92bf7744bb7931315ddcca78b190d7513adf49f86e7c2ae93dacfc68b"
  end

  if build.with? "native-comp"
    depends_on "libgccjit" => :recommended
    depends_on "gcc" => :build
  end

  # patch for multi-tty support, see the following links for details
  # https://bitbucket.org/mituharu/emacs-mac/pull-requests/2/add-multi-tty-support-to-be-on-par-with/diff
  # https://ylluminarious.github.io/2019/05/23/how-to-fix-the-emacs-mac-port-for-multi-tty-access/
  patch do
    url "https://raw.githubusercontent.com/railwaycat/homebrew-emacsmacport/667f0efc08506facfc6963ac1fd1d5b9b777e094/patches/multi-tty-27.diff"
    sha256 "5a13e83e79ce9c4a970ff0273e9a3a07403cc07f7333a0022b91c191200155a1"
  end

  def install
    args = [
      "--enable-locallisppath=#{HOMEBREW_PREFIX}/share/emacs/site-lisp",
      "--infodir=#{info}/emacs",
      "--prefix=#{prefix}",
      "--with-mac",
      "--enable-mac-app=#{prefix}",
      "--with-gnutls",
    ]
    args << "--with-modules"
    args << "--with-rsvg" if build.with? "rsvg"
    args << "--with-mac-metal" if build.with? "mac-metal"
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
    rm "#{icons_dir}/Emacs.icns"
    resource("emacs-dragon-icon").stage do
      icons_dir.install Dir["*.icns*"].first => "Emacs.icns"
    end

    system "./autogen.sh"
    system "./configure", *args
    system "make"
    system "make", "install"
    prefix.install "NEWS-mac"

    if build.with? "starter"
      # Replace the symlink with one that starts GUI
      # alignment the behavior with cask
      # borrow the idea from emacs-plus
      (bin/"emacs").unlink
      (bin/"emacs").write <<~EOS
        #!/bin/bash
        exec #{prefix}/Emacs.app/Contents/MacOS/Emacs.sh "$@"
      EOS
    end
  end

  def post_install
    if build.with? "native-comp"
      ln_sf "#{Dir[opt_prefix/"lib/emacs/*"].first}/native-lisp", "#{opt_prefix}/Emacs.app/Contents/native-lisp"
    end
  end

  def caveats
    <<~EOS
      This is YAMAMOTO Mitsuharu's "Mac port" addition to
      GNU Emacs 28. This provides a native GUI support for Mac OS X
      10.10 - 12. After installing, see README-mac and NEWS-mac
      in #{prefix} for the port details.

      Emacs.app was installed to:
        #{prefix}

      To link the application to default Homebrew App location:
        osascript -e 'tell application "Finder" to make alias file to POSIX file "#{prefix}/Emacs.app" at POSIX file "/Applications"'
      You can use ln -s, but symlinks created this way don't show up in Spotlight:
        ln -s #{prefix}/Emacs.app /Applications

      If you are using Doom Emacs, be sure to run doom sync:
        ~/.emacs.d/bin/doom sync

      For an Emacs.app CLI starter, see:
        https://gist.github.com/4043945

      Emacs mac port also available on MacPorts with name "emacs-mac-app" and "emacs-mac-app-devel", but they are not maintained by the maintainer of this formula.
    EOS
  end

  test do
    assert_equal "4", shell_output("#{bin}/emacs --batch --eval=\"(print (+ 2 2))\"").strip
  end
end
