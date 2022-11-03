type dir_t =  Buy | Sell

type foo = {
  dir : dir_t;
  quantity : int;
  price : float ;
  dropped : bool
}

type bar = {
  dir : dir_t;
  quantity : int;
  price : float;
  canceled: bool
  }
