# On `break`, `continue`, and `return`

One often sees teachers who categorically refuse to use `break` and
`continue`, not to speak of exiting a loop with a `return`.  This is a
shame, and I will argue in favor of these three constructions.

Everything I'm going to say below applies equally to exiting a loop
with `break`, using `continue`, or the early exit of a function with
`return` (including from inside a loop).

1. When we use a language, and especially when we teach it, it must be
  done **idiomatically**.  We do our students ill-service, when we
  fail to teach them idiomatic usage: both because it is what they'll
  find in the standard library (and in code written by others) and
  because it's probably what is compiled most efficiently (otherwise,
  it wouldn't be idiomatic).

2. To do without `break/continue/return` when writing loops requires
   **contortions**, usually based on Boolean variables, which

		* obscures the code for the programmer as well as the reader
		
		* greatly increases the risk of error

   Beyond these two phenomena, the code is generally longer, which is
   also unfortunate.

3. In the same vein, these three constructions allow us to **simplify
   control-flow, keeping it as linear as possible**.  For example a
   `return` can allow us to avoid a superfluous `else`:

```
  def f(x):
    if x == 0: return 1
    ...
```

[I'll use Python for examples, but nearly any language with `break/continue/return` would do.] 

   Note that we don't need to indent code following the `return`,
   something especially valuable when the function is large.  And this
   works equally well with an exception:

```
  def f(x):
    if x < 0: raise ValueError
    ...
```

   The same thing works for `continue`: it's much nicer to write

```
  while len(q) > 0:
    x = q.pop()
    if x in vus: continue
    ...
```

   than to put the (possibly large) contents of `...` into a new
   indented block.

4. Finally, `break/continue/return` have **simple semantics**.
   Learning a little about compilation, we discover quickly that these
   constructs are easy-to-compile (a simple jump to a place statically
   known, easily identified.)  Programming languages all contain lots
   of subtleties and I understand that as teachers we deliberately
   eschew the sordid aspects (I do this myself when teaching
   beginners). But why discard simple constructions, which also make
   the code more elegant ?

While `break/continue/return` are present in most imperative
languages, they're generally absent in functional languages like
Haskell, OCaml, Standard ML, F#, etc.  Technically, this can be
explained by the fact that in functional languages it's common to use
a (tail-)recursive function rather than a loop.  So an early exit is
trivial: it suffices to not make a recursive call.  In OCaml I can
find the first zero value in an array with a recursive function:

```
  let rec cherche a i =
    if i = Array.length n then raise Not_found;
    if a.(i) = 0 then i else cherche a (i + 1) in
  cherche a 0
```

Functional languages typically optimize tail calls (e.g. in OCaml)
which means this function `cherche` is compiled exactly like the loop

```
  i = 0
  while i < len(a):
    if a[i] == 0: return i
    i += 1
  raise NotFound
```

which contains an early `return`.  In other words, functional
languages don't need such constructs. (That being said, I'd love to
have them in OCaml!)  In imperative languages, by contrast, it's not
common to use recursive functions instead of loops and more
importantly (perhaps for this reason) tail-calls are rarely optimized
(e.g. never in Java/Python), which can lead to stack-overflows.


*My thanks to Alexandre Casamayou who convinced me to write and
publish this note.*
