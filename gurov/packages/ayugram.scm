(define-module (gurov packages ayugram)
  #:use-module (gnu packages telegram)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages linux)
  #:use-module (guix build-system gnu)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module (guix utils))

(define-public tlottie
  (let ((commit "31f1b542f8")
        (revision "0"))
    (package
      (name "tlottie")
      (version (git-version "0.1.0" revision commit))
      (source
       (origin
         (method git-fetch)
         (uri (git-reference
               (url "https://github.com/dkaraush/tlottie.git")
               (commit commit)))
         (file-name (git-file-name name version))
         (sha256
          (base32 "0v3vj6ifgssipcackpajy7p80mscp1c7pa86hcnphkfqaz8l3i16"))))
      (build-system gnu-build-system)
      (native-inputs (list rust))
      (arguments
       (list #:phases
             #~(modify-phases %standard-phases
                 (delete 'configure)
                 (replace 'build
                   (lambda _
                     (invoke "rustc" "--edition=2021" "--crate-name" "tlottie"
                             "--crate-type" "staticlib" "-C" "opt-level=3"
                             "--cfg" "feature=\"std\"" "--cfg" "feature=\"cpu\""
                             "--cfg" "feature=\"c-api\"" "src/lib.rs")))
                 (replace 'check
                   (lambda _
                     (invoke "rustc" "--edition=2021" "--test"
                             "--cfg" "feature=\"std\"" "--cfg" "feature=\"cpu\""
                             "--cfg" "feature=\"c-api\"" "src/lib.rs"
                             "-o" "tlottie-tests")
                     (invoke "./tlottie-tests" "--skip"
                             (string-append
                              "dos::renderer_rejects_generated_work_"
                              "after_successful_parse"))))
                 (replace 'install
                   (lambda _
                     (install-file "libtlottie.a" (string-append #$output "/lib"))
                     (install-file "include/tlottie.h"
                                   (string-append #$output "/include/tlottie")))))))
      (home-page "https://github.com/dkaraush/tlottie")
      (synopsis "Lottie animation renderer")
      (description "Tlottie renders Lottie animations using a CPU renderer.")
      (license license:expat))))

(define-public ayugram-desktop
  (package
    (inherit telegram-desktop)
    (name "ayugram-desktop")
    (version "7.2.9")
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/AyuGram/AyuGramDesktop.git")
             (commit "d4b7546e77f93ac4c9bb53a3fcf7e9ffbbecf1b5")
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256
        (base32 "1y93sa7nbyh034ya0haymqxpynkwwjvi8kya1jh9lx6nwwkmcmi6"))))
    (inputs (modify-inputs (package-inputs telegram-desktop)
              (append tlottie eudev)))
    (arguments
     (substitute-keyword-arguments (package-arguments telegram-desktop)
       ((#:phases phases)
        #~(modify-phases #$phases
            (delete 'unpack-additional-sources)
            (add-after 'unpack 'make-sources-writable
              (lambda _
                (for-each make-file-writable (find-files "."))))
            (add-after 'make-sources-writable 'patch-ayugram-cppgir
              (lambda _
                (substitute* "cmake/external/glib/generate_cppgir.cmake"
                  (("\\$\\{cppgir_loc\\}/data")
                   (string-append #$(this-package-input "cppgir-for-telegram-desktop")
                                  "/share/cppgir")))))))))
    (home-page "https://github.com/AyuGram/AyuGramDesktop")
    (synopsis "Telegram desktop client with customization features")
    (description
     "AyuGram Desktop is a Telegram client based on Telegram Desktop.  It
provides customizable appearance and additional messaging features.")
    (license (cons license:x11 (package-license telegram-desktop)))))
