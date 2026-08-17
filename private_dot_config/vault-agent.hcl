vault {
  address = "http://127.0.0.1:8200"
}

auto_auth {
  method "file" {
    config {
      secret_path = "/home/{{ .chezmoi.username }}/.vault/token"
      remove_token_file = false
    }
  }
}

cache {
  use_auto_auth_token = true
}
