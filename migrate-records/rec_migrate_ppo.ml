
exception Migration_error of string

let migration_error feature = raise (Migration_error feature)

type foo =
  Rec_types.A.foo =
    { dir : dir_t; quantity : int; price : float; dropped : bool }
and dir_t =
  Rec_types.A.dir_t[@@deriving_inline migrate
    {dispatch_type = dispatch_table_t; dispatch_table_constructor = make_dt;
     dispatchers =
       {migrate_foo =
         {srctype = [%typ: foo]; dsttype = [%typ: Rec_types.B.bar];
          skip_fields = [dropped];
          custom_fields_code = {canceled = __dt__.aux}};
        migrate_dir_t =
          {srctype = [%typ: dir_t]; dsttype = [%typ: Rec_types.B.dir_t];
           code = fun __dt__ x -> x}}}]

type 'aux dispatch_table_t =
  { aux : 'aux;
    migrate_dir_t : ('aux, Rec_types.A.dir_t, Rec_types.B.dir_t) migrater_t;
    migrate_foo : ('aux, Rec_types.A.foo, Rec_types.B.bar) migrater_t }
and ('aux, 'a, 'b) migrater_t = 'aux dispatch_table_t -> 'a -> 'b

let rec (migrate_dir_t :
 ('aux, Rec_types.A.dir_t, Rec_types.B.dir_t) migrater_t) =
  fun __dt__ x -> x
and (migrate_foo : ('aux, Rec_types.A.foo, Rec_types.B.bar) migrater_t) =
  fun __dt__
      {dir = dir; quantity = quantity; price = price; dropped = dropped} ->
    {Rec_types.B.dir = (fun __dt__ -> __dt__.migrate_dir_t __dt__) __dt__ dir;
     Rec_types.B.quantity = (fun __dt__ x -> x) __dt__ quantity;
     Rec_types.B.price = (fun __dt__ x -> x) __dt__ price;
     Rec_types.B.canceled = __dt__.aux}

let make_dt aux =
  {aux = aux; migrate_dir_t = migrate_dir_t; migrate_foo = migrate_foo}

[@@@end]

