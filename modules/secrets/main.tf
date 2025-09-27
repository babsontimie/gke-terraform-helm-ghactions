resource "google_secret_manager_secret" "example" {
  secret_id = var.secret_name
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "example" {
  secret      = google_secret_manager_secret.example.id
  secret_data = var.secret_value
}


