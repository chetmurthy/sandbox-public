
This post is about PPX rewriters, using multiple of them in sequence,
using one rewriter in implementing others, and getting to something
.... somewhat surprisingly complex, in simple steps.  All of this has
been doing using PPX rewriters based on `camlp5` (and `pa_ppx`), but
should in principle be doable on `ppxlib` (the standard support
infrastructure for PPX rewriters).

I should note that the portions regarding hash-consing are all a
pretty faithful re-implementation and mechanization of the paper of
Filliatre and Conchon:
[Type-Safe Modular Hash-Consing](https://www.lri.fr/~filliatr/ftp/publis/hash-consing2.pdf).

TL;DR This post describes how, starting with an AST type and a parser
for it, we can more-or-less automatically generate hash-consed
versions of the AST, functions back-and-forth, and surface-syntax
"quotation" expanders for both types, so that code doesn't need to
manipulate the AST directly, but can instead use the surface syntax
(hence being more-or-less indifferent to whether it's applied to the
original or hashconsed version of the AST).

All of the code discussed here is available on github at: `camlp5`,
`camlp5/pa_ppx`, `camlp5/pa_ppx_{migrate,hashcons,q_ast}`.  The
working examples described can be found at `camlp5/pa_ppx_q_ast/tests`.

# Introduction: the Problem We're Solving

A while back in the "Future of PPX" post (
https://discuss.ocaml.org/t/the-future-of-ppx/3766 ) there was some
discussion of hash-consing for ASTs, and the complexities of achieving
it.  I wrote a follow-up post "Hashconsing an AST via PPX" (
https://discuss.ocaml.org/t/hashconsing-an-ast-via-ppx/5558 ) where I
discussed how one could use a PPX rewriter to automate the task of
"re-sharing" an AST when writing a top-down/bottom-up rewriter for an
AST. (That is, you're walking an AST, making small modifications, but
most of it stays the same; so in principle, at a node `Add(Mul(e1,e2),
e3)` when rewriting `e3` actually changes it visibly, but `Mul(e1,e2)`
doesn't, we might want that the result value's first subtree is shared
with that of the input's first subtree.)  I called this "rehascons"ing
(admittedly not a great name).  The idea being, we're not trying to
hash-cons, but only to restore whatever sharing was there originally,
to whatever extent that's possible.

But this is neither sufficient in all cases, nor real hash-consing.
The problem with hash-consing is::

A. If you start with an AST type that doesn't have the various bits
   needed for hash-consing (at a minimum, a type `'a node = { it : 'a
   ; hashcode : int }` and its use at each spot where we want to
   hash-cons) then you have *produce a new AST type* with those bits
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
manipulate the hashconsed data-type as if it were normal type, and
have the messy bits filled-in for us.

This post is about how to achieve that.

# A plan for how to achieve reasonably transparent hash-consing

1. Suppose that we already have a syntax for writing expressions and
   patterns over our AST type, which is processed by a PPX rewriter
   (or equivalent) to produce the actual OCaml expressions/patterns.
   
   Then (assuming that we insert hash-consing bits in well-understood
   locations *in the AST type-definition*) we could instruct this
   rewriter to insert bits in the corresponding places in *in
   expressions/patterns*.
   
2. Suppose we have a PPX rewriter that will solve problems #A,#B from
   above: given a "normal" type and some succinct specification of
   where hash-consing should be applied (or maybe better, where it
   should *not* be applied) it will generate the hashconsed type and
   all the necessary boilerplate code for constructors, as well as for
   memoizing functions of various (also-specified) types.

3. Then suppose we have a PPX rewriter that, given succinct
   specification of two families of types, can generate a
   recursive-walk "map" function (in the style of `ppx_deriving.map`)
   from one type-family to the other.  Where the two type-families
   differ, some succinct specification can be given to guide the
   "migration" rewriter on code to generate.
   
4. Finally, for step #1, suppose that we can *generate* the rewriter
   that is used there, again from the type-declarations of normal and
   hashconsed types.

5. In implementing the above, we're describing complex tasks, so it's
   possible that when not automatically inferrable from types, the
   "hints" we might need to give will be complex.  It would be nice if
   there were a way to automatically generate code to parse such
   specifications.  If we were writing some other application, we
   might want to use `ppx_deriving.yojson` (or our equivalent,
   `pa_ppx.deriving_plugins.yojson`) and write our specification in
   JSON.  But since we're writing a PPX rewriter, the specification
   will come in the payload of a PPX attribute/extension.  Since our
   "hints" might need to contain types and expressions, we'd probably
   like the payload to be real expressions and types.  So what we need
   is a type-driven mapping from expression-ASTs, to expressions.
   
   Then, when implementing a PPX rewriter, we can write down the type
   of its "params", and from that generate the function that will
   convert expression-ASTs to that type.

The implementation of the above, is what I will describe in the rest of
this note.  I've applied it to a couple of simple examples
(s-expressions and deBruijn lambda-terms) and am in-process of
applying it to Camlp5's own AST type.

A note: I'm not trying to convince any of you reading this to use
`camlp5` and `pa_ppx`.  I *am* arguing that these sorts of PPX
rewriters should be easy to implement (all of this code is barely a
month old) and not the domain of cognoscenti.

# A Worked Example: deBruijn Lambda Terms

In this section, I'll work thru how to apply the ideas above,
step-by-step, to deBruijn lambda-terms.

### Write the AST types (with antiquotation markers)

Here is the type definition for our AST.

```
type term =
    Ref of int vala
  | Abs of term vala
  | App of term vala * term vala
```
(the `vala` type-constructors are the antiquotation markers)

The surface syntax we'll use is
```
term ::= int | term term | "[]"term | "(" term ")"
```
with the obvious meaning.

### Generate a Hashconsed version of the AST, with some memo functions

This is the input to the `camlp5/pa_ppx_hashcons` PPX rewriter.  This
rewriter implements the method of Jean-Christophe Filliatre and
Sylvain Conchon, from their paper
[Type-Safe Modular Hash-Consing](https://www.lri.fr/~filliatr/ftp/publis/hash-consing2.pdf).
In short, we specify a few module-names, equality and hash functions
for external type-constructors (which necessarily cannot participate
in hash-consing) and the type-signatures of memo-izers we wish
generated.  In this case, we'd like to memoize functions of the following types:
```
term -> 'a
int -> term -> 'a
term -> term -> 'a
```

Here's the actual code:

```
[%%import: Debruijn.term]
[@@deriving hashcons { hashconsed_module_name = HC
                     ; normal_module_name = OK
                     ; memo = {
                         memo_term = [%typ: term]
                       ; memo2_int_term = [%typ: int * term]
                       ; memo2_term_term = [%typ: term * term]
                       ; memo_int = [%typ: int]
                       }
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
                         term = {
                           hashcons_module = Term
                         ; hashcons_constructor = term
                         }
                       }
                     }]
```

The resulting OCaml module will contain two new modules: `OK` (which
contains a copy of the original AST) and `HC` (which contains the
hashconsed AST, as well as functions for hash-consing, memoizing, etc).

### Write the Parser

Below is an LL(1) parser for our lambda-terms.  There's nothing special
going on, except for the `V` symbols, which are how we indicate to the
parser where anti-quotations are allowed.  The syntax and semantics of
these parsers is explained in the Camlp5 documentation.

The last line of this parser code defines an entry `term_hashcons_eoi`
that parses a term, and using the migration code above, promotes it to
a hashconsed AST value.

```
value term_eoi = Grammar.Entry.create gram "term_eoi";
value term_hashcons_eoi = Grammar.Entry.create gram "term_hashcons_eoi";

EXTEND
  GLOBAL: term_eoi term_hashcons_eoi;

  term: [
    "apply" LEFTA
    [ l = LIST1 (V (term LEVEL "abs") "term") ->
      Pcaml.unvala (List.fold_left (fun lhs rhs -> <:vala< App lhs rhs >>) (List.hd l) (List.tl l)) ]
  | "abs"
    [ "["; "]" ; e = V (term LEVEL "abs") "term" -> Abs e ]
  |  "var" [ n = V INT "ref" -> Ref (vala_map int_of_string n)
    | "(" ; e = SELF ; ")" -> e
    ]
  ]
  ;

  term_eoi: [ [ x = term; EOI -> x ] ];
  term_hashcons_eoi: [ [ x = term; EOI -> Debruijn_migrate.Inject.inject x ] ];

END;
```

### Generate functions back-and-forth between "normal" and "hashconsed" versions of the AST

Here's the input to a `pa_ppx_migrate` PPX rewriter, that generates migration functions from the "normal" (`OK`) to the "hashconsed" (`HC`) AST.  The reverse direction isn't much different.

```
[%%import: Debruijn_hashcons.OK.term]
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
      ; migrate_term_node = {
          srctype = [%typ: term_node]
        ; dsttype = [%typ: Debruijn_hashcons.HC.term_node]
        }
      ; migrate_term = {
          srctype = [%typ: term]
        ; dsttype = [%typ: Debruijn_hashcons.HC.term]
        ; code = (fun __dt__ x ->
            Debruijn_hashcons.HC.term (__dt__.migrate_term_node __dt__ x)
          )
        }
      }
    }
]
```
To invoke the generated code, one writes
```
let dt = make_dt ()
let inject x = dt.migrate_term dt x
```

### Generate quotations for the "normal" AST

In Camlp5, "quotations" are a mechanism for writing expressions in the
surface syntax of some language, and having them expanded into
equivalent expressions (or patterns).  These quotations can contain
"holes" (anti-quotations) which are preserved, allowing to use
quotations in writing OCaml code.

To generate an "okdebruijn" quotation, we use the `pa_ppx_q_ast` PPX
rewriter with input
```
[%%import: Debruijn_hashcons.OK.term]
[@@deriving q_ast {
    data_source_module = Debruijn_hashcons.OK
  ; expr_meta_module = MetaE
  ; patt_meta_module = MetaP
  }]

Quotation.add "okdebruijn"
  (apply_entry Pa_debruijn.term_eoi E.term P.term)

```

(there is a little more code, but it's to deal with primitive types).

This generates the code that converts values of the AST type to OCaml
expressions and patterns, and then installs those values, along with a
parser, into the quotation machinery.

### Using quotations over "normal" ASTs

Here is an example of code using these quotations.  It's not much more
succinct than the raw OCaml code one might write, but it *is* more
comprehensible (assuming one is already familiar with the surface
syntax of the AST).

```
let rec copy = function
    <:okdebruijn:< $ref:x$ >> -> <:okdebruijn:< $ref:x$ >>
  | <:okdebruijn:< $term:_M$ $term:_N$ >> -> <:okdebruijn:< $term:copy _M$ $term:copy _N$ >>
  | <:okdebruijn:< []$term:_M$ >> -> <:okdebruijn:< []$term:copy _M$ >>
end
```
and one can also write more-complex expressions, like:
```
let v1 = <:debruijn< [][]1 >>
```
(for the "K" combinator).

### Generate quotations for "hashconsed" ASTs

Quotations over hashconsed ASTs are generated pretty much the same as over normal ASTs:
```
[%%import: Debruijn_hashcons.HC.term]
[@@deriving q_ast {
    data_source_module = Debruijn_hashcons.HC
  ; quotation_source_module = Debruijn_migrate.Project
  ; expr_meta_module = MetaE
  ; patt_meta_module = MetaP
  ; hashconsed = true
  }]

Quotation.add "hcdebruijn"
  (apply_entry Pa_debruijn.term_hashcons_eoi E.term P.term)

```

and again, there's a little code left out, but nothing specific to
this example.  This generates and installs a "hcdebruijn" quotation.

### Using quotations over "hashconsed" ASTs

And finally, here's the same "copy" function, but this time over
hashconsed ASTs.  Notice that it's almost the same as before:

```
let rec copy = function
    <:hcdebruijn:< $ref:x$ >> -> <:hcdebruijn:< $ref:x$ >>
  | <:hcdebruijn:< $term:_M$ $term:_N$ >> -> <:hcdebruijn:< $term:copy _M$ $term:copy _N$ >>
  | <:hcdebruijn:< []$term:_M$ >> -> <:hcdebruijn:< []$term:copy _M$ >>
```

# Discussion

I've also applied this same methodology to the entire OCaml AST in
Camlp5 (for which there is a parser, as part of Camlp5) and verified
that the quotations thus generated pass the same tests as the
hand-written quotations provided as part of Camlp5.

The quotations of Camlp5 are substantial, and cover almost all of the
OCaml language.  I believe that this means it is possible to both
provide full hash-consing support for a very complex AST type, and
full quotation support both for the AST type, and for its
automatically-generated hashconsed variant.
