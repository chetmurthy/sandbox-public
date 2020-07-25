
## `Camlp5 (8.00~alpha01)` and `pa_ppx (0.01)`

I'm pleased to announce the release of two related projects:

1. [Camlp5](https://github.com/camlp5/camlp5): version 8.00~alpha01 is
an alpha release of Camlp5, with full support for OCaml syntax up to
version 4.10.0, as well as minimal compatibility with version 4.11.0.
In particular there is full support for PPX attributes and extensions.

2. [pa_ppx](https://github.com/chetmurthy/pa_ppx): version 0.01 is a
re-implementation of a large number of PPX rewriters
(e.g. ppx_deriving (std (show, eq, map, etc), yojson, sexp, etc),
ppx_import, ppx_assert, others) on top of Camlp5, along with an
infrastructure for developing new ones.

This allows projects to combine the existing style of Camlp5 syntax
extension, with PPX rewriting, without having to jump thru hoops to
invoke camlp5 on some files, and PPX processors on others.

Camlp5 alone is not compatible with existing PPX rewriters: Camlp5
syntax-extensions (e.g. "stream parsers") would be rejected by the
OCaml parser, and PPX extensions/attributes are ignored by Camlp5
(again, without `pa_ppx`).  `pa_ppx` provides Camlp5-compatible
versions of many existing PPX rewriters, as well as new ones, so that
one can use Camlp5 syntax extensions as well as PPX rewriters.  In
addition, some of the re-implemented rewriters are more-powerful than
their original namesakes, and there are new ones that add interesting
functionality.

## For democratizing macro-extension-authoring in OCaml

TL;DR Writing OCaml PPX rewriters is **hard work**.  There is a
complicated infrastructure that is hard to explain, there are multiple
such incompatible infrastructures (maybe these are merging?) and it is
hard enough that most Ocaml programmers do not write macro-extensions
as a part of their projects.  I believe that using Camlp5 and pa_ppx
can make it easier to write macro-extensions, via:

1. providing a simple way of thinking about adding your extension to
the parsing process.

2. providing transparent tools (e.g. quotations) for
pattern-matching/constructing AST fragments

Explained below in [Macro Extensions with Pa_ppx](#macro-extensions-with-pa_ppx).

### The original arguments against Camlp4

The original argument against using Camlp4 as a basis for
macro-preprocessing in Ocaml, had several points (I can't find the
original document, but from memory):

1. *syntax-extension* as the basis of macro-extension leads to brittle
syntax: multiple syntax extensions often do not combine well.

2. a different AST type than the Ocaml AST

3. a different parsing/pretty-printing infrastructure, which must be
maintained alongside of Ocaml's own parser/pretty-printer.

4. A new and complicated set of APIs are required to write syntax
extensions.

To this, I'll add

5. Camlp4 was *forked* from Camlp5, things were changed, and hence,
Camlp4 lost the contribution of its original author.  Hence,
maintaining Camlp4 was always labor that fell on the Ocaml
team. [Maybe this doesn't matter, but it counts for something.]

### Assessing the arguments, with some hindsight

1. *syntax-extension* as the basis of macro-extension leads to brittle
syntax: multiple syntax extensions often do not combine well.

In retrospect, this is quite valid: even if one prefers and enjoys
LL(1) grammars and parsing, when multiple authors write
grammar-extensions which are only combined by third-party projects,
the conditions are perfect for chaos, and of a sort that
project-authors simply shouldn't have to sort out.  And this chaos is
of a different form, than merely having two PPX rewriters use the same
attribute/extension-names (which is, arguably, easily detectable with
some straightforward predeclaration).

2. Camlp4/5 has a different AST type than the Ocaml AST

Over time, the PPX authors themselves have slowly started to conclude
that the current reliance on the Ocaml AST is fraught with problems.
The "Future of PPX" discussion thread talks about using something like
s-expressions, and more generally about a more-flexible AST type.

3. a different parsing/pretty-printing infrastructure, which must be
maintained alongside of Ocaml's own parser/pretty-printer.

A different AST type necessarily means a different
parser/pretty-printer.  Of course, one could modify Ocaml's YACC
parser to produce Camlp5 ASTs, but this is a minor point.

4. A new and complicated set of APIs are required to write syntax
extensions.

With time, it's clear that PPX has produced the same thing.

5. Maintaining Camlp4 was always labor that fell on the Ocaml team.

The same argument (that each change to the Ocaml AST requires work to
update Camlp5) can be made for PPX (specifically, this is the raison
d'etre of ocaml-migrate-parsetree).  Amusingly, one could imagine
using ocaml-migrate-parsetree as the basis for making Camlp5
OCaml-version-independent, too.  That is, the "backend" of Camlp5
could use ocaml-migrate-parsetree to produce ASTs for a version of
OCaml different from the one on which it was compiled.

## Arguments against the current API(s) of PPX rewriting

The overall argument is that it's too complicated for most OCaml
programmers to write their own extensions; what we see instead of a
healthy ecosystem of many authors writing and helping-improve PPX
rewriters, is a small number of rewriters, mostly written by Jane
Street and perhaps one or two other shops.  There are a few big
reasons why this is the case (which correspond to the responses
above), but one that isn't mentioned is:

6. When the "extra data" of a PPX extension or attribute is
easily-expressed with the fixed syntax of PPX payloads, all is
~~well~~ ok, but certainly not in great shape.  Here's an example:

```
type package_type =
[%import: Parsetree.package_type
          [@with core_type    := Parsetree.core_type [@printer Pprintast.core_type];
                 Asttypes.loc := Asttypes.loc [@polyprinter fun pp fmt x -> pp fmt x.Asttypes.txt];
                 Longident.t  := Longident.t [@printer pp_longident]]]
[@@deriving show]
```

The expression-syntax of assignment is used to express type-expression
rewrites.  And this is necesarily limited, because we cannot (for
example) specify left-hand-sizes that are type-expressions with
variables.  It's a perversion of the syntax, when what we really want
to have is something that is precise: "map this type-expression to
that type-expression".

Now, with the new Ocaml 4.11.0 syntax, there's a (partial) solution:
use "raw-string-extensions" like `{%foo|argle|}`.  This is the same as
`[%foo {|argle|}]`.  This relies on the PPX extension to parse the
payload.  But there are problems:

1. Of course, there's no equivalent `{@foo|argle|}` (and "@@", "@@@"
of course) for attributes.

2. If the payload in that string doesn't *itself* correspond to some
parseable Ocaml AST type, then again, we're stuck: we have to cobble
together a parser instead of being able to merely extend the parser of
Ocaml to deal with the case.

Note well that I'm not saying that we should extend the parsing rules
of the Ocaml language.  Rather, that with an *extensible parser*
(hence, LL(1)) we can add new nonterminals, add rules that reference
existing nonterminals, and thereby get an exact syntax (e.g.) for the
`ppx_import` example above.  That new nonterminal is used *only* in
parsing the payload -- nowhere else -- so we haven't introduced
examples of objection #1 above.

And it's not even very hard.

## Macro Extensions with Pa_ppx

The basic thesis of `pa_ppx` is "let's not throw the baby out with the
bathwater".  Camlp5 has a lot of very valuable infrastructure that can
be used to make writing macro-preprocessors much easier.  `pa_ppx`
adds a few more.

1. Quotations for patterns and expressions over all important OCaml
AST types.

2. "extensible functions" to make the process of recursing down the
AST transparent, and the meaning of adding code to that process
equally transparent.

3. `pa_ppx` introduces "passes" and allows each extension to register
which other extensions it must follow, and which may follow it; then
`pa_ppx` topologically sorts them, so there's no need for
project-authors to figure out how to order their PPX extension
invocations.

As an example of a PPX rewriter based on `pa_ppx`, here's
[pa_ppx.here](https://pa-ppx.readthedocs.io/en/latest/tutorial.html#an-example-ppx-rewriter-based-on-pa-ppx)
from the `pa_ppx` tutorial.  In that example, you'll see that Camlp5
infrastructure is used to make things easy:

1. quotations are used to both build the output AST fragment, and to
pattern-match on inputs.

2. the "extensible functions" are used to add our little bit of
rewriter to the top-down recursion.

3. and we declare our rewriter to the infrastructure (we don't specify
what passes it must come before or after, since `pa_ppx.here` is so
simple).

## Conclusion

I'm not trying to convince you to switch away from PPX to Camlp5.
Perhaps, I'm not even merely arguing that you should use `pa_ppx` and
author new macro-extensions on it.  But I *am* arguing that the features of

1. quotations, with antiquotations in as many places as possible

2. facilities like "extensible functions", with syntax support for
them

3. a new AST type, that is suitable for macro-preprocessing, but isn't
merely "s-expression" (after all, there's a reason we all use
strongly-typed languages)

3. an extensible parser for the Ocaml language, usable in PPX
attribute/extension payloads

are important and valuable, and a PPX rewriter infrastructure that
makes it possible for the masses to write their own macro-extensions,
is going to incorporate these things.

Fin.
