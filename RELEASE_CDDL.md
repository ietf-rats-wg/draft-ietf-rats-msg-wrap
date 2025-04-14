The CDDL files produced by the build and test machinery can be made into downloadable artefacts using the following procedure:

## Create a git tag

To trigger the "CDDL release" action, the tag must start with "`cddl-`".

### I-D CDDL files

When releasing the CDDL files associated with the given I-D version, use the convention:

```sh
RELTAG=cddl-draft-ietf-rats-corim-<nn>
git tag -a $RELTAG
```

Where `<nn>` is the draft version number.

### HEAD CDDL files

When releasing the current HEAD, use:

```sh
RELTAG=cddl-$(git rev-parse --short HEAD)
git tag -a $RELTAG
```

## Push the tag to origin

```sh
git push origin $RELTAG
```

Pushing the tag to origin will trigger the associate GitHub action.

## Inspect the release files

If everyhing goes as planned, the 5 "autogen" CDDL files will be available for download from the following locations:

```
https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/releases/download/cddl-.../cddl/cmw-autogen.cddl
https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/releases/download/cddl-.../cddl/collected-cddl-autogen.cddl
https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/releases/download/cddl-.../cddl/eat-autogen.cddl
https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/releases/download/cddl-.../cddl/signed-cbor-cmw-autogen.cddl
https://github.com/ietf-rats-wg/draft-ietf-rats-msg-wrap/releases/download/cddl-.../cddl/signed-json-cmw-autogen.cddl
```
