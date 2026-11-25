# guix-channel

Personal GNU Guix channel for packages.

Add to your `channels.scm`:

```scheme
(channel
  (name 'gurov)
  (url "https://github.com/Gur0v/guix-channel.git")
  (branch "main"))
```

Package modules live in `gurov/packages/`.
