# In the real repo this default is a committed plaintext password.
# Here it's an obvious placeholder, and the demo passes it via TF_VAR_db_password.
# The talk's point stands either way: a default value in variables.tf is a
# credential in git.
variable "db_password" {
  description = "RDS master password"
  type        = string
  sensitive   = true
  default     = "demo_password_not_a_real_secret"
}
