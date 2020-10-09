This post is about PPX rewriters, using multiple of them in sequence,
using one rewriter in implementing others, and getting to something
.... somewhat surprisingly complex, in simple steps.  All of this has
been done using PPX rewriters based on `camlp5` (and `pa_ppx`), but
should in principle be doable on `ppxlib` (the standard support
infrastructure for PPX rewriters).

I should note that the portions regarding hash-consing are all a
pretty faithful re-implementation and mechanization of the paper of
Filliatre and Conchon:
[Type-Safe Modular Hash-Consing](https://www.lri.fr/~filliatr/ftp/publis/hash-consing2.pdf).
All errors are mine, of course.

TL;DR This post describes how, starting with an AST type and a parser
for it, we can more-or-less automatically generate

* hash-consed versions of the AST,
* functions back-and-forth,
* and surface-syntax "quotation" expanders for both types

so that code doesn't need to manipulate the AST directly, but can
instead use the surface syntax (hence being more-or-less indifferent
to whether it's applied to the original or hashconsed version of the
AST).

All of the code discussed here is available on github at:
https://github.com/camlp5 , in projects `camlp5/pa_ppx`,
`camlp5/pa_ppx_{migrate,hashcons,q_ast,params}`.  The latter ones are
not (yet) released on OPAM, but will be soon.  I apologize in advance
for the nonexistent-to-poor documentation: I'm working on it!  Working
code for everything described below can be found at
`camlp5/pa_ppx_q_ast/tests`, in the directories `sexp_example` and
`eg_sexp_example`.

# Motivation (a Concrete Example)

The ability to transparently introduce hash-consing into a complex
collection of AST types should need no argument.  The ability to use
"quotations" over such an AST type might need some motivation.  So
consider a type of s-expressions, viz

```
type sexp =
    Atom of string
  | Cons of sexp * sexp
  | Nil
```

with the obvious parsing that we're all used-to from LISP/Scheme.  The
hashconsed version of this type is

```
    type sexp_node =
        Atom of string
      | Cons of sexp * sexp
      | Nil
    and sexp = sexp_node hash_consed
```

with (from the opam package `hashcons`)
```
type +'a hash_consed = private {
  hkey : int;
  tag : int;
  node : 'a }
```

NOTE: there is a nuance here that I'll address at the end of ths post
in the section "Appendix B: Types with and without `vala`".

Let's suppose we want to write the function `atoms : sexp -> string
list` that returns the list of `string` (those wrapped by `Atom`) at the
leaves of the s-expression.  The code is easy enough (just rotate
left-child cons-nodes to the right, until we get an atom (or Nil) and
then move on to the cdr.  This is a good example to consider, because
it requires multi-level pattern-matching and multi-level
constructor-expressions.  So the introduction of meaningless
bureaucracy will be palpable.

```
let rec atoms =
  function
    Nil -> []
  | Atom a -> [a]
  | Cons(Cons(caar, cdar), cdr) ->
      atoms (Cons(caar, Cons (cdar, cdr)))
  | Cons(Nil, cdr) -> atoms cdr
  | Cons(Atom a, cdr) -> a :: atoms cdr

```


and the hashconsed version is

```
    let rec atoms =
      function
        {node = Nil} -> []
      | {node = Atom a} -> [a]
      | {node = Cons({node = Nil}, cdr)} -> atoms cdr
      | {node = Cons({node = Atom a}, cdr)} -> a :: atoms cdr
      | {node = Cons ({node = Cons (caar, cdar)}, cdr)} ->
          atoms (make_sexp (Cons (caar, (make_sexp (Cons (cdar, cdr))))))
```

As you can see, there are extra patterns `{ node = ...}` and a new
constructor `make_sexp` (to perform the actual hashtable lookup &
consing).  And these extra bits appear at multiple levels in both
patterns and expressions.

Wouldn't it be nice, if we could write one version of this code, viz.

```
let rec atoms = function
    <:sexp< () >> -> []
  | <:sexp< $atom:a$ >> -> [a]
  | <:sexp< ( () . $exp:cdr$ ) >> -> atoms cdr
  | <:sexp< ( $atom:a$ . $exp:cdr$ ) >> -> a::(atoms cdr)
  | <:sexp< ( ( $exp:caar$ . $exp:cdar$ ) . $exp:cdr$ ) >> ->
    atoms <:sexp< ( $exp:caar$ . ( $exp:cdar$ . $exp:cdr$ ) ) >>
```

and merely by changing "<:sexp<" to "<:hcsexp<" get a version of the
function that works on hashconsed s-expressions?  The text within
`<:sexp< .... >>` is called a "quotation" in Camlp5, and is similar to
the same concept in `ppx_metaquot` and the much older LISP idea of
"quasi-quotation".  The contained text is parsed with a parser for
s-expressions, slightly modified to have indications for where the
text `$...$` may appear -- these are called "anti-quotations', and can
contain OCaml source code (e.g. variables) albeit not quotations (so
no arbitrary nesting).  The "quotation expander" parses this text to
AST and applies a converter to produce an OCaml expression or pattern
AST that does what the quotation intends.  The lovely thing is, by
changing out the quotation-expander (replace "sexp" with "hcsexp") we
can change the code that is generated, and if the quotation-expander
is generated from the type definition, it's not actually any work for
the programmer to achieve this.

NOTE: Unlike with `ppx_metaquot`, the antiquotations can be placed in
nearly-arbitrary positions in the parse-tree (hence, in the AST):
there is no requirement that they correspond to variable-names or
identifiers in the OCaml AST: indeed, our running example will *not*
be the OCaml AST, even though all of this machinery has been
applied-to the OCaml AST successfully.

In this post I'll walk you thru how to achieve this goal: building up
the machinery, step-by-step, to allow one to write basically arbitrary
expressions in your AST's surface syntax, and automatically get either
"normal' (no hash-consing) or "hashconsed" patterns & expressions.

# A High-Level Plan of Attack

A while back in the "Future of PPX" post (
https://discuss.ocaml.org/t/the-future-of-ppx/3766 ) there was some
discussion of hash-consing for ASTs, and the complexities of achieving
it.  I wrote a reply post "Hashconsing an AST via PPX" (
https://discuss.ocaml.org/t/hashconsing-an-ast-via-ppx/5558 ) where I
showed how one could use a PPX rewriter to automate the task of
"re-sharing" an AST when writing a top-down/bottom-up rewriter for an
AST. (That is, you're walking an AST, making small modifications, but
most of it stays the same; so in principle, at a node `Add(Mul(e1,e2),
e3)` when rewriting `e3` actually changes it visibly, but `Mul(e1,e2)`
doesn't, we might want the output value's first subtree to be
pointer-equal to the input's first subtree.)  I called this
"rehashcons"ing (admittedly not a great name).  The idea being,
`rehashcons` is not trying to hash-cons, but only to restore whatever
sharing was there originally, to whatever extent that's possible.

But this is neither sufficient in all cases, nor real hash-consing.
The problem with hash-consing is::

A. If you start with an AST type that doesn't have the various bits
   needed for hash-consing (at a minimum, a type `'a node = { it : 'a
   ; hashcode : int }` and its use at each spot where we want to
   hash-cons) then you have to first *produce a new AST type* with those bits
   inserted.  Let's call these the "normal" and "hashconsed" ASTs.
   
B. You have to write tons of boilerplate code: first, to map
   to-and-from these two type-families, and second to *implement* the
   hash-consing (special constructors, (ephemeral) hashtables
   here-and-there, etc). Then perhaps you'd like to memoize functions
   over these hash-consed ASTs, and that's more boilerplate.
   
C. And then, when it comes to writing expressions and patterns over
   this new AST type, you have to remember where the "special bits" go
   -- where to insert the special constructors, and where to add
   `{it=....}` to patterns.
   
It's all a bit of a tedious bother, when what we *want* is to just
manipulate the hashconsed data-type as if it were the "normal" type,
and have the messy bits filled-in for us.

This post is about how to achieve that.

# A plan for how to achieve reasonably transparent hash-consing

Let's first map out the plan of attack:

0. Start with an AST type (or types) for our language, and a parser
   (in this case, written using Camlp5's grammar machinery).

1. Add to the AST type some indications for where antiquotations may
   go, and modify the parser to parse these antiquotations.  We'll
   call this the "normal" AST type.  Note that this is the version
   *with* antiquotation markers.
   
2. [`pa_ppx_hashcons`] Generate a *hashconsed version of the AST type* from the
   "normal" AST type.

3. [`pa_ppx_migrate`] Generate functions back-and-forth between "normal" and "hashconsed"
   versions of the AST type.  So we're hashconsing the version *with*
   antiquotation markers.  We could hashcons the version without
   antiquotation markers, and everything here would still work out
   ... but it would be more complicated to explain.

4. [`pa_ppx_q_ast`] From each of the "normal" and "hashconsed" AST types, generate
   functions that can take values of the type and generate OCaml code
   for patterns and expressions that correspond to those values.

5. [`pa_ppx.deriving_plugins.params`] In implementing the above, we're
   describing complex tasks, so it's possible that when not
   automatically inferrable from types, the "hints" we might need to
   give will be complex.  It would be nice if there were a way to
   automatically generate code to parse such specifications.  If we
   were writing some other application, we might want to use
   `ppx_deriving.yojson` (or our equivalent,
   `pa_ppx.deriving_plugins.yojson`) and write our specification in
   JSON.  But since we're writing a PPX rewriter, the specification
   will come in the payload of a PPX attribute/extension.  Since our
   "hints" might need to contain types and expressions, we'd probably
   like the payload to be real expressions and types.  So what we need
   is a type-driven mapping from expression-ASTs, to expressions.
   
   Then, when implementing a PPX rewriter, we can write down the type
   of its "params", and from that generate the function that will
   convert expression-ASTs to that type.

The implementation of all of the above, is what I will describe in the
rest of this note.  I've applied it to

* (simple) s-expressions
* (simple) deBruijn lambda-terms
* (simple) named-variable lambda-terms
* (complex and comprehensive) the entire OCaml AST in Camlp5.

# A Worked Example: s-expressions.

In this section, I'll work thru how to apply the ideas above,
step-by-step, to s-expressions.  Everything described here is working
code, documented and tested in
`camlp5/pa_ppx_q_ast/tests/{sexp_example,eg_sexp_example}`.

### 0. Write the AST type (without antiquotations)

Copying from above

```
type sexp =
    Atom of string
  | Cons of sexp * sexp
  | Nil
```

### 1. Add antiquotation markers and add a parser

```
type sexp =
    Atom of (string vala)
  | Cons of (sexp vala) * (sexp vala)
  | Nil
```

The type ` 'a vala` is a Camlp5 type-constructor.  It contains either
a value of type ` 'a`, or an antiquotation.  A short argument for why
antiquotations markers are necessary, can be found in "Appendix C: Is
`vala` Necessary?"

Here's the parser:

```
  sexp: [
    [
      a = V atom "atom" -> sexp_atom a
    | "(" ; l1 = LIST1 v_sexp ; opt_e2 = OPT [ "." ; e2 = v_sexp -> e2 ] ; ")" ->
      match opt_e2 with [
        None -> List.fold_right (fun vse1 se2 -> Sexp.Cons vse1 <:vala< se2 >>) l1 sexp_nil
      | Some ve2 ->
         let (last, l1) = sep_last l1 in
         List.fold_right (fun vse1 se2 -> Sexp.Cons vse1 <:vala< se2 >>) l1
           (Sexp.Cons last ve2)
      ]
    | "(" ; ")" ->
        sexp_nil
    ]
  ]
  ;

  v_sexp: [[ v = V sexp "exp" -> v ]];

  atom: [[ i = LIDENT -> i | i = UIDENT -> i | i = INT -> i ]] ;

  sexp_eoi: [ [ x = sexp; EOI -> x ] ];
```

This is an LL(1) grammar, interpreted by Camlp5, and the marker for
antiquotations is "V".  Full details of the grammar language can be
found in the Camlp5 documentation.  You can see in it, that we've used
`V sexp "exp"` (renamed for convenience to "v_sexp") everywhere
internally, and that `Atom` is parsed by `V atom "atom"` (again,
giving an antiquotation position.).

### 2. Generate a Hashconsed version of the AST type

This is the input to the `camlp5/pa_ppx_hashcons` PPX rewriter.  This
rewriter implements the method of Jean-Christophe Filliatre and
Sylvain Conchon, from their paper
[Type-Safe Modular Hash-Consing](https://www.lri.fr/~filliatr/ftp/publis/hash-consing2.pdf).
In short, we specify a few module-names, equality and hash functions
for external type-constructors (which necessarily cannot participate
in hash-consing) and the type-signatures of memo-izers we wish
generated.  The rewriter generates efficient hash-constructors and
hash/equality-functions: consult the paper for details.


Here's the actual code:

```
[%%import: Sexp.sexp]
[@@deriving hashcons { hashconsed_module_name = HC
                     ; normal_module_name = OK
                     ; external_types = {
                         Ploc.vala = {
                           preeq = (fun f x y -> match (x,y) with
                               (Ploc.VaAnt s1, Ploc.VaAnt s2) -> s1=s2
                             | (Ploc.VaVal v1, Ploc.VaVal v2) -> f v1 v2
                             )
                         ; prehash = (fun f x -> match x with
                             Ploc.VaAnt s -> Hashtbl.hash s
                           | Ploc.VaVal v -> f v
                           )
                         }
                       }
                     ; pertype_customization = {
                         sexp = {
                           hashcons_constructor = sexp
                         }
                       }
                     }]
```

The resulting OCaml module will contain two new modules: `OK` (which
contains a copy of the original AST) and `HC` (which contains the
hashconsed AST, as well as functions for hash-consing, memoizing,
etc).  The hashconsed AST type is as described in the previous
section.

### Generate functions back-and-forth between "normal" and "hashconsed" versions of the AST type.

To generate functions back-and-forth between the two versions of the
AST type, we use the `pa_ppx_migrate` PPX rewriter. Here is the input
for generating the function from the "normal" (`OK`) to the
"hashconsed" (`HC`) AST.  The reverse direction isn't much different.
Notice that we don't actually write any migration code, except for
external types (`vala`).  In much-more-complicated examples, the
succinctness of this method over the actual code can be quite
significant.  It has been applied to the 10 versions of the OCaml AST
(to generate something quasi-equivalent to `ocaml-migrate-parsetree`,
and the succinctness gains there are significant.

```
[%%import: Sexp_hashcons.OK.sexp]
[@@deriving migrate
    { dispatch_type = dispatch_table_t
    ; dispatch_table_constructor = make_dt
    ; dispatchers = {
        migrate_vala = {
          srctype = [%typ: 'a Ploc.vala]
        ; dsttype = [%typ: 'b Ploc.vala]
        ; subs = [ ([%typ: 'a], [%typ: 'b]) ]
        ; code = _migrate_vala
        }
      ; migrate_sexp_node = {
          srctype = [%typ: sexp_node]
        ; dsttype = [%typ: Sexp_hashcons.HC.sexp_node]
        }
      ; migrate_sexp = {
          srctype = [%typ: sexp]
        ; dsttype = [%typ: Sexp_hashcons.HC.sexp]
        ; code = (fun __dt__ x ->
            Sexp_hashcons.HC.sexp (__dt__.migrate_sexp_node __dt__ x)
          )
        }
      }
    }
]
```

### 4. Generate functions to map (parsed) values to OCaml AST expressions/patterns

We use the `pa_ppx_q_ast` PPX rewriter, and invoke it twice: once with
the "normal" AST type (`Sexp.sexp`) and once with the hashconsed type
(`Sexp_hashcons.HC.sexp`).  The two quotation-expanders are named,
respectively, "sexp" and "hcsexp" (the names are chosen only for this
presentation and are not significant).

```
module Regular = struct
type sexp = [%import: Sexp.sexp]
[@@deriving q_ast { data_source_module = Sexp }]

Quotation.add "sexp"
  (apply_entry Pa_sexp.sexp_eoi E.sexp P.sexp)
end

module Hashcons = struct

[%%import: Sexp_hashcons.HC.sexp]
[@@deriving q_ast {
    data_source_module = Sexp_hashcons.HC
  ; quotation_source_module = Sexp_migrate.FromHC
  ; hashconsed = true
  }]

Quotation.add "hcsexp"
  (apply_entry Pa_sexp.sexp_hashcons_eoi E.sexp P.sexp)
end

```

### Putting it all together

So: we start with an AST type and a parser, to which antiquotation
markers have been added.  We generate a hashconsed version of the AST
type, and functions back-and-forth to the "normal" version of the
type.  Since we have a parser for the "normal" version, we now have a
parser for the "hashconsed" version.

The fancy bit is that Camlp5 has built-in machinery to map values of
types in the OCaml AST of Camlp5 (which is a different recursive type,
but more-or-less equivalent to the official OCaml AST) to expressions
and patterns that correspond to those values.  So the actual AST
*value* corresponding to `x + 1` can be mapped to either an expression
(that when evaluated, produces that value) or a pattern (that matches
that value).  But since our AST type contains antiquotation markers,
the AST value corresponding to `$x$ + 1` can *also* be mapped to an
expression/pattern, only this time, with OCaml variable `x` as the
first argument to `(+)`.

The `pa_ppx_q_ast` PPX rewriter generalizes this and makes it possible
to apply to any AST type (and also to apply to the OCaml AST type in
Camlp5, so nothing has been lost).

### Using the quotations

And finally, we can use those quotations:

```
let rec atoms = function
    <:sexp< () >> -> []
  | <:sexp< $atom:a$ >> -> [a]
  | <:sexp< ( () . $exp:cdr$ ) >> -> atoms cdr
  | <:sexp< ( $atom:a$ . $exp:cdr$ ) >> -> a::(atoms cdr)
  | <:sexp< ( ( $exp:caar$ . $exp:cdar$ ) . $exp:cdr$ ) >> ->
    atoms <:sexp< ( $exp:caar$ . ( $exp:cdar$ . $exp:cdr$ ) ) >>

let rec atoms = function
    <:hcsexp< () >> -> []
  | <:hcsexp< $atom:a$ >> -> [a]
  | <:hcsexp< ( () . $exp:cdr$ ) >> -> atoms cdr
  | <:hcsexp< ( $atom:a$ . $exp:cdr$ ) >> -> a::(atoms cdr)
  | <:hcsexp< ( ( $exp:caar$ . $exp:cdar$ ) . $exp:cdr$ ) >> ->
    atoms <:hcsexp< ( $exp:caar$ . ( $exp:cdar$ . $exp:cdr$ ) ) >>
```

# Discussion

I've also applied this same methodology to the entire OCaml AST in
Camlp5 (for which there is a parser, as part of Camlp5) and verified
that the quotations thus generated pass the same tests as the
hand-implemented quotations provided as part of Camlp5.

The quotations of Camlp5 are substantial, and cover almost all of the
OCaml language.  I believe that this means it is possible to both
provide full hash-consing support for a very complex AST type, and
full quotation support both for the AST type, and for its
automatically-generated hashconsed variant.

# Appendix A: Parameter-parsing for PPX Rewriters

I've shown three different PPX rewriters (`migrate`, `hashcons`, and
`q_ast`) and in some of their invocations, there are nontrivial OCaml
expressions to supply as options.  Writing the code that converts
these options (OCaml expressions) into values of meaningful types (for
the rewriter code) is unutterably boring, time-consuming, and error-prone: it is
effectively a *demarshalling* problem.  So I wrote a PPX rewriter,
that automates this task, and in fact that is what is used to generate
the demarshallers used in these PPX rewriters.  Here is an example:
the `params` PPX rewriter as used by `pa_ppx_migrate` to generate
its options demarshaller:
```
type tyarg_t =
  { srctype : ctyp;
    dsttype : ctyp;
    raw_dstmodule : longid option
      [@name dstmodule];
    dstmodule : longid option
      [@computed longid_of_dstmodule dsttype raw_dstmodule];
    inherit_code : expr option;
    code : expr option;
    custom_branches_code : expr option;
    custom_branches : (lident, case_branch) alist
      [@computed extract_case_branches custom_branches_code];
    custom_fields_code : (lident, expr) alist [@default []];
    skip_fields : lident list [@default []];
    subs : (ctyp * ctyp) list [@default []];
    type_vars : string list
      [@computed compute_type_vars srctype dsttype subs];
    subs_types : ctyp list
      [@computed compute_subs_types loc subs]
}
[@@deriving params]

type default_dispatcher_t =
  { srcmod : longid;
    dstmod : longid;
    types : lident list;
    inherit_code : (lident, expr) alist[@default []]
  }
[@@deriving params]

type t =
  { optional : bool
  ; plugin_name : string
  ; inherit_type : ctyp option;
    dispatch_type_name : lident[@name dispatch_type];
    dispatch_table_constructor : lident;
    declared_dispatchers : (lident, Dispatch1.tyarg_t) alist
      [@default []] [@name dispatchers];
    default_dispatchers : default_dispatcher_t list[@default []];
    dispatchers : (lident, Dispatch1.tyarg_t) alist
      [@computed compute_dispatchers loc type_decls declared_dispatchers default_dispatchers];
    type_decls : (string * MLast.type_decl) list
      [@computed type_decls];
    pretty_rewrites : (string * Prettify.t) list
      [@computed Prettify.mk_from_type_decls type_decls] }
[@@deriving params {formal_args = {t = [type_decls]}}]

```

This generates a function `params : (string * MLast.type_decl) list ->
MLast.expr -> t` that performs the entire demarshalling task.  At a
couple of points, we supply functions to handle custom demarshalling
operations, but the vast majority of the code (and work) is handled
automatically.  This is *liberating*: it means that there is no cost
to being precise in describing the data one needs as input, and no need
to "encode" arguments into easy-to-parse form.  A good comparison is
with the "@with" syntax of the `ppx_import` PPX rewriter, where it's
clear that they're shoe-horning types into expression syntax, for want
of a nicer syntax that is still easily to manipulate.

# Appendix B: Types with without `vala`

In the "Motivation" section, I introduced a type of `sexp`, and then
the hashconsed version of the type.  Neither type had `vala` markings
in it.  The mechanism described in this post can equally well work to
produce quotation-expanders that work over types without `vala`.  The
only difficulty, is that the *parser* still needs to be defined over a
version of the type with `vala`, because it will be used to parse
quotations (which must necessarily contain antiquotations).  But
everything else works, and in
`camlp5/pa_ppx_q_ast/tests/{sexp_example,eg_sexp_example}` you will
find the definition and use of "sexpnovala", a quotation expander for
the first `sexp` type we defined in this post.  I didn't bother
building the quotation expander for "hcsexpnovala", but it's a
straightforward exercise.

In short, the choice of whether your AST type needs to have `vala`
markings in it, is independent of hash-consing.  You only need to
supply a version of your AST type with `vala`, along with a parser,
for the quotation machinery.

# Appendix C: Is `vala` Necessary?

Consider that `sexp` type

```
type sexp =
    Atom of string
  | Cons of sexp * sexp
  | Nil
```

If we want to provide a `ppx_metaquot`-like facility for this type,
perhaps we can overload the meaning of the strings in atoms.  So the
s-expression

```
( _A . foo )
```

that expands to

```
Cons(Atom "_A", Atom "foo")
```

could mean an s-expression with a single meta-variable, `_A`.  But
this meta-variable is necessarily a variable that can only denote an
s-expression, and not a string.  More generally, in an AST type if
metavariables are merely overloaded variables, anyplace that a
variable cannot appear, cannot be subject to meta-variable-based
pattern-matching/substitution.  So it's not possible to match on the
list of types or expressions in a tuple type/expression, nor the list
of branches in a match-with.  And on and on.  This is why the version
of the `sexp` type with antiquotation markers

```
type sexp =
    Atom of (string vala)
  | Cons of (sexp vala) * (sexp vala)
  | Nil
```

includes `Atom of (string vala)`.  This allows us to write a pattern
with a metavariable that matches an s-expression, e.g.

```
Cons (VaVal x, VaVal (Atom (VaVal "foo")))
```

(in quotation syntax, `<:sexp< ( $exp:x$ . bar ) >>`) or a
metavariable that matches the `string` in an `Atom`,
e.g.

```
Cons
  (VaVal (Atom (VaVal x)),
   VaVal (Atom (VaVal "foo")))
```

And this is a general issue in all (meta-)quotation support, not
merely for the OCaml AST.  If we want high-quality quotation support
for our data-types, we need to build high-quality suppot for
antiquotations.
