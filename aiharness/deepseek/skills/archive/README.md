# Archive — retired buffer files

**Read this when:** an index row points somewhere that no longer exists, or you are
looking for a feature context file that is no longer at the top level.

Files here were **retired from the cyclic buffer**: their feature shipped, and
whatever they taught that is true of the *system* was merged into `knowledge/` first.
They are un-indexed by design — the index row is the context cost, and dropping it is
the point of retiring.

**Nothing here is deleted.** These files stay readable and greppable, because a
retired file is often the only record of *why* a decision went the way it did, and
because several skill files are cited by path from `.lisp` headers and
`installation/` migrations — deleting one breaks those citations.

If you are looking for current knowledge, go back to `../README.md`. If you need
something from a file in here that turns out to still be true, **move it into the
owning `knowledge/` file** rather than re-activating the archived file.
