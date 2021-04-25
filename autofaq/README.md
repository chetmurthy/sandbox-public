
### Prerequisites

1. "jq" (typically available on Linux distros as the "jq" package)

2. OCaml and some packages
   - ocaml itself
   - the "ocamlfind" tool
   - the module "fmt"
   - the module "yojson"

I typically install ocaml with the "opam" manager.

### Instructions for use

1. run extract.jq on the JSON files

```
jq -f extract.jq 2021*.json > xx.json
```

2. then process xx.json with the `convert1` tool, which you can build
   by running `make` in this directory.

```
./convert 100 < xx.json
```

This will produce files consecutively-numbered starting at `100.txt`.
