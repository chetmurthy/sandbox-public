def procmod: [.[] | .["name"]] ;
.[] | if .[0] == "executables" then . else empty end | {"names" : .[1]["names"], "modules": (.[1]["modules"] | procmod) }
