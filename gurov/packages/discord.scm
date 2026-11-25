(define-module (gurov packages discord)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (nonguix build-system binary)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bash)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages fontutils)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages nss)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages web)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xml))

(define-public discord
  (package
    (name "discord")
    (version "1.0.170")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://stable.dl2.discordapp.net/apps/linux/"
                                  version "/discord-" version ".tar.gz"))
              (sha256
               (base32 "130ccrq1svj0kxzwfssd27np0qw28gn6qvy82ifb4wbhdv0ki7qj"))))
    (build-system binary-build-system)
    (supported-systems '("x86_64-linux"))
    (inputs (list (list gcc "lib") libx11 libxcursor libxi libxcb
                  alsa-lib at-spi2-core cairo cups dbus eudev expat glib
                  gtk+ libxcomposite libxdamage libxext libxfixes libxrandr
                  libxkbcommon mesa nspr nss pango patchelf pulseaudio))
    (arguments
     (list #:patchelf-plan
           #~'(("updater_bootstrap"
                ("gcc" "libx11" "libxcursor" "libxi" "libxcb")))
           #:install-plan
           #~'(("discord" "lib/discord/")
               ("updater_bootstrap" "lib/discord/")
               ("discord.desktop" "share/applications/")
               ("discord.png" "share/icons/hicolor/256x256/apps/"))
           #:phases
           #~(modify-phases %standard-phases
               (add-after 'install 'install-launcher
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (dir (string-append out "/lib/discord"))
                          (launcher (string-append out "/bin/discord"))
                          (opener-dir (string-append dir "/bin"))
                          (libraries
                           (string-append
                            (string-join
                             (map (lambda (input)
                                    (string-append (cdr input) "/lib"))
                                  %build-inputs) ":")
                            ":" #$nss "/lib/nss")))
                     (mkdir-p (string-append out "/bin"))
                     (copy-file #$(local-file "discord-launcher.sh") launcher)
                     (chmod launcher #o755)
                     (mkdir-p opener-dir)
                     (symlink (string-append #$xdg-utils "/bin/xdg-mime")
                              (string-append opener-dir "/xdg-mime"))
                     (call-with-output-file (string-append opener-dir "/xdg-open")
                       (lambda (port)
                         (format port "#!/bin/sh~%unset LD_LIBRARY_PATH~%")
                         (format port "exec ~a/bin/xdg-open \"$@\"~%"
                                 #$xdg-utils)))
                     (chmod (string-append opener-dir "/xdg-open") #o755)
                     (patch-shebang (string-append opener-dir "/xdg-open"))
                     (substitute* launcher
                       (("@opener-dir@") opener-dir)
                       (("@tools@")
                        (string-append #$coreutils "/bin:"
                                       #$findutils "/bin:"
                                       #$bash-minimal "/bin"))
                       (("@bootstrap@") (string-append dir "/updater_bootstrap"))
                       (("@patchelf@") (string-append #$patchelf "/bin/patchelf"))
                       (("@jq@") (string-append #$jq "/bin/jq"))
                       (("@interpreter@")
                        (string-append #$glibc "/lib/ld-linux-x86-64.so.2"))
                       (("@libraries@") libraries))
                     (patch-shebang launcher)
                     (substitute* (string-append out
                                                 "/share/applications/discord.desktop")
                       (("Exec=/usr/bin/discord")
                        (string-append "Exec=" out "/bin/discord"))
                       (("Path=/usr/bin\n") ""))))))))
    (home-page "https://discord.com/")
    (synopsis "Nonfree Discord client bootstrapper")
    (description
     "This package provides Discord's nonfree bootstrapper.  It downloads and
runs a mutable Discord client in the user's configuration directory.  The
client is not managed by Guix and may require additional runtime support.")
    (license (license:license "Proprietary" "https://discord.com/terms" #f))))
