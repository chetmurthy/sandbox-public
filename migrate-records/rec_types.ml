
module A = struct
type dir_t =  [ `Buy | `Sell ]
type foo = {
  dir : dir_t;
  quantity : int;
  price : float ;
  dropped : bool
}
end

module B = struct
type dir_t =  [ `Buy | `Sell ]
type bar = {
  dir : dir_t;
  quantity : int;
  price : float;
  canceled: bool
  }
end
