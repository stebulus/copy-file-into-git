A simple working example of using [gitlib][1].

To build:

    git clone https://github.com/stebulus/copy-file-into-git
    cd copy-file-into-git
    cabal build

To test, create a throwaway git repo with a branch:

    pushd ~
    mkdir whatever
    pushd whatever
    git init .
    echo stuff >stuff
    git add stuff
    git commit -m "added stuff"
    git branch some-branch
    popd
    popd

Then "copy a file into git":

    dist/build/copy-file-into-git/copy-file-into-git some-branch README.md ~/whatever/some/place/a-file

The git history in `~/whatever` will now show a commit
on the branch `some-branch` adding the file `some/place/a-file`.

Bugs:

1. It doesn't understand bare repositories.

2. If you copy a file into the branch that's currently checked out,
the working copy doesn't get updated, so git will claim that the
working copy has deleted files.

[1]: http://hackage.haskell.org/package/gitlib
