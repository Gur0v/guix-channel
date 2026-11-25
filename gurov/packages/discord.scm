(define-module (gurov packages discord)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (nonguix build-system binary)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages xorg))

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
    (inputs (list (list gcc "lib") libx11 libxcursor libxi libxcb))
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
                          (dir (string-append out "/lib/discord")))
                     (substitute* (string-append dir "/discord")
                       (("/usr/share/\\$BOOTSTRAP_SUFFIX")
                        (string-append dir "/updater_bootstrap")))
                     (mkdir-p (string-append out "/bin"))
                     (symlink (string-append dir "/discord")
                              (string-append out "/bin/discord"))
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
