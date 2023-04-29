variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "event" {
  description = "Name of the event that the workshop is being run for"
  type        = string
  default     = "testing"
}

variable "num_teams" {
  description = "How many teams will be participating in the workshop"
  type        = number
  default     = 1
}

variable "ssh_local_key_path" {
  description = "Local path to your SSH private key for instance access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
