((executables
  ((names (ydump))
   (requires (6cb9b3db2f333fbd2eed4eb5aff6a0a8))
   (modules
    (((name Ydump)
      (impl (_build/default/bin/ydump.ml))
      (intf ())
      (cmt (_build/default/bin/.ydump.eobjs/byte/ydump.cmt))
      (cmti ()))))
   (include_dirs (_build/default/bin/.ydump.eobjs/byte))))
 (executables
  ((names (filtering))
   (requires (6cb9b3db2f333fbd2eed4eb5aff6a0a8))
   (modules
    (((name Filtering)
      (impl (_build/default/examples/filtering.ml))
      (intf ())
      (cmt (_build/default/examples/.filtering.eobjs/byte/filtering.cmt))
      (cmti ()))))
   (include_dirs (_build/default/examples/.filtering.eobjs/byte))))
 (executables
  ((names (constructing))
   (requires (6cb9b3db2f333fbd2eed4eb5aff6a0a8))
   (modules
    (((name Constructing)
      (impl (_build/default/examples/constructing.ml))
      (intf ())
      (cmt
       (_build/default/examples/.constructing.eobjs/byte/constructing.cmt))
      (cmti ()))))
   (include_dirs (_build/default/examples/.constructing.eobjs/byte))))
 (executables
  ((names
    (test atd))
   (requires (6cb9b3db2f333fbd2eed4eb5aff6a0a8))
   (modules
    (((name Test)
      (impl (_build/default/test/pretty/test.ml))
      (intf ())
      (cmt (_build/default/test/pretty/.test.eobjs/byte/test.cmt))
      (cmti ()))
     ((name Atd)
      (impl (_build/default/test/pretty/atd.ml))
      (intf ())
      (cmt (_build/default/test/pretty/.test.eobjs/byte/atd.cmt))
      (cmti ()))))
   (include_dirs (_build/default/test/pretty/.test.eobjs/byte))))
 (library
  ((name seq)
   (uid 092c274fe179bf76244efc6236abbb42)
   (local false)
   (requires ())
   (source_dir /home/chet/Hack/Opam-2.1.2/GENERIC/4.14.0/lib/seq)
   (modules ())
   (include_dirs (/home/chet/Hack/Opam-2.1.2/GENERIC/4.14.0/lib/seq))))
 (library
  ((name yojson)
   (uid 6cb9b3db2f333fbd2eed4eb5aff6a0a8)
   (local true)
   (requires (092c274fe179bf76244efc6236abbb42))
   (source_dir _build/default/lib)
   (modules
    (((name Yojson)
      (impl (_build/default/lib/yojson.ml))
      (intf (_build/default/lib/yojson.mli))
      (cmt (_build/default/lib/.yojson.objs/byte/yojson.cmt))
      (cmti (_build/default/lib/.yojson.objs/byte/yojson.cmti)))))
   (include_dirs (_build/default/lib/.yojson.objs/byte)))))
