
exception Migration_error of string

let migration_error feature =
  raise (Migration_error feature)

type foo = [%import: Rec_types.A.foo]
and dir_t = Rec_types.A.dir_t
[@@deriving migrate
    { dispatch_type = dispatch_table_t
    ; dispatch_table_constructor = make_dt
    ; dispatchers = {
        migrate_foo = {
          srctype = [%typ: foo]
        ; dsttype = [%typ: Rec_types.B.bar]
        ; skip_fields = [ dropped ]
        ; custom_fields_code = {
            canceled = __dt__.aux
          }
        }
      ; migrate_dir_t = {
          srctype = [%typ: dir_t]
        ; dsttype = [%typ: Rec_types.B.dir_t]
        ; code = (fun __dt__ x -> x)
        }
      }
    }
]

