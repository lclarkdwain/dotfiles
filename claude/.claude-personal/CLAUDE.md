# Global instructions

## Git commits

Do not add a `Co-Authored-By` trailer, or any other AI attribution, to commit
messages or PR bodies.

Reason: these repositories are not set up to surface agent involvement in their
history yet. Introducing it in a commit means rewriting published history to
remove it, which cannot be done cleanly once a PR exists.

Scoped globally rather than per-repo on purpose: omitting the trailer is
harmless, whereas adding an unwanted one is expensive to undo. Narrow this to
specific repos, or drop it, once a repo is ready.

@RTK.md
