(define-module (gurov packages xlibre)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages xorg)
  #:use-module (guix build-system meson)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix packages))

(define-public xlibre-server
  (package
    (inherit xorg-server)
    (name "xlibre-server")
    (version "25.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/X11Libre/xserver/archive/refs/tags/"
                           "xlibre-xserver-" version ".tar.gz"))
       (sha256
        (base32 "1hrfhvmqkgfb6y57vp2922hamcbnsdr4qyxxv42nhzbp1cwi7x9n"))))
    (build-system meson-build-system)
    (native-inputs
     (append `(("xdpyinfo" ,xdpyinfo) ("xrandr" ,xrandr) ("xvinfo" ,xvinfo))
             (package-native-inputs xorg-server)))
    (arguments
     (list
      #:configure-flags
      #~(list (string-append "-Dxkb_dir="
                             (assoc-ref %build-inputs "xkeyboard-config")
                             "/share/X11/xkb")
              "-Dxkb_output_dir=/tmp"
              (string-append "-Dxkb_bin_dir="
                             (assoc-ref %build-inputs "xkbcomp") "/bin")
              "-Ddefault_font_path="
              "-Dxcsecurity=true"
              "-Dlocalstatedir=/var"
              "-Dxephyr=true"
              "-Dxvfb=true"
              "-Dxnest=true"
              "-Dglamor=true"
              "-Dsystemd_logind=true"
              "-Dsystemd_notify=false")
      #:phases
      #~(modify-phases %standard-phases
          (add-before 'configure 'patch-shell-paths
            (lambda _
              (substitute* (find-files "." "\\.c$")
                (("/bin/sh") (which "sh"))))))))
    (home-page "https://github.com/X11Libre/xserver")
    (synopsis "XLibre implementation of the X Window System")
    (description
     "XLibre is a fork of the Xorg X server.  It accepts requests from X client
programs and displays their windows on the screen.")))

(define-public xlibre-input-libinput
  (package
    (inherit xf86-input-libinput)
    (name "xlibre-input-libinput")
    (version "25.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://github.com/X11Libre/xf86-input-libinput/"
                           "archive/refs/tags/xlibre-xf86-input-libinput-"
                           version ".tar.gz"))
       (sha256
        (base32 "0i3ar7p83g3ni7rz5zv9ls7frh74lim74fv0bfd4a0wsdxmj9nfp"))))
    (arguments
     (list #:configure-flags
           #~(list (string-append "--with-xorg-module-dir="
                                  #$output "/lib/xorg/modules/xlibre-25/drivers")
                   (string-append "--with-sdkdir=" #$output "/include/xorg"))))
    (native-inputs
     (modify-inputs (package-native-inputs xf86-input-libinput)
       (prepend autoconf automake libtool util-macros)))
    (inputs
     (modify-inputs (package-inputs xf86-input-libinput)
       (replace "xorg-server" xlibre-server)
       (prepend libxfont2)))
    (home-page "https://github.com/X11Libre/xf86-input-libinput")
    (synopsis "Libinput input driver for XLibre")
    (description
     "This package provides an XLibre input driver based on libinput.")))
