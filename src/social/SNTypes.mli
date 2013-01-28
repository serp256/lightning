type error = [ SocialNetworkError of (string*string) | IOError | OAuthError of OAuth.error_response ];

type response = [ Data of Ojson.json | Error of error ];

type delegate = 
{
  on_success: (Ojson.json -> unit);
  on_error  : (error -> unit);
};

