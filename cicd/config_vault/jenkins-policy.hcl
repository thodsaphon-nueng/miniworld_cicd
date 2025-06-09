
path "secret/data/myapp" {
  capabilities = ["read", "list"]
}


path "secret/data/myapp" {
  capabilities = ["create", "update"]
}



path "secret/data/myapp_main" {
  capabilities = ["read", "list"]
}


path "secret/data/myapp_main" {
  capabilities = ["create", "update"]
}


path "auth/token/lookup-self" {
  capabilities = ["read"]
}