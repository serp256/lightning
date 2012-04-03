type error = [ SocialNetworkError of (string*string) | IOError | OAuthError of OAuth.error_response ];

type response = [ Data of Ojson.t | Error of error ];

type delegate = 
{
  on_success: (Ojson.t -> unit);
  on_error  : (error -> unit);
};

