(define-module (gurov packages equicord)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system go)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (gnu packages golang-xyz))

(define go-github-com-protonmail-go-appdir
  (package
    (name "go-github-com-protonmail-go-appdir")
    (version "1.1.0")
    (source (origin
              (method git-fetch)
              (uri (git-reference
                    (url "https://github.com/ProtonMail/go-appdir")
                    (commit (string-append "v" version))))
              (file-name (git-file-name name version))
              (sha256
               (base32 "1pl43h5f79g2r0z98glrxasbb69yzigpd85csl7zmyhg63vzbkqw"))))
    (build-system go-build-system)
    (arguments (list #:import-path "github.com/ProtonMail/go-appdir"))
    (home-page "https://github.com/ProtonMail/go-appdir")
    (synopsis "Application directory paths for Go")
    (description
     "This Go library provides application configuration and cache directory
paths.")
    (license license:expat)))

(define-public equicord-installer
  (package
    (name "equicord-installer")
    (version "2.3.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://github.com/Equicord/Equilotl/archive/refs/tags/v"
                    version ".tar.gz"))
              (sha256
               (base32 "1dn7rgfgdvmv287j69wm71fj9blph56wkg4nc5r5c40cdv681h8x"))))
    (build-system go-build-system)
    (arguments
     (list #:import-path "equilotl"
           #:phases
           #~(modify-phases %standard-phases
               (replace 'check
                 (lambda _
                   ;; Upstream's dynamic log format fails Go vet.
                   (invoke "go" "test" "-vet=off" "-tags=cli"
                           "equilotl/..."))))
           #:build-flags #~(list "-tags=cli"
                                 (string-append
                                  "-ldflags=-X=equilotl/buildinfo.InstallerTag=v"
                                  #$version))))
    (inputs (list go-github-com-protonmail-go-appdir
                  go-github-com-fatih-color
                  go-github-com-manifoldco-promptui))
    (home-page "https://github.com/Equicord/Equilotl")
    (synopsis "Equilotl command-line installer for Equicord")
    (description
     "Equilotl installs, repairs, and removes the Equicord Discord client
modification.  This package provides its command-line interface.")
    (license license:gpl3+)))
