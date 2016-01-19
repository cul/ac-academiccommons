class UserSession < Authlogic::Session::Base 
  unloadable
  
  wind_host "cas.columbia.edu/cas"
  wind_service "cul_headcount"
  auto_register true
  login_only_with_wind true
end