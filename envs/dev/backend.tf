terraform {
  backend "gcs" {
    bucket = "my-terraform-state"
    prefix = "dev"
  }
}
