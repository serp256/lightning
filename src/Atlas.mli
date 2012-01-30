

module type S = module type of AtlasSig;
module Make(D:DisplayObjectT.M) : S with module D = D;
