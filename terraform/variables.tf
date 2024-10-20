variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "custom_security_group_ingress" {
  description = "Additional Security Group ingress rules to be appended to defaults. Useful if you need to punch holes open for inconsistent public IPs of participants"
  type = list(object({
    from_port   = number,
    to_port     = number,
    protocol    = string,
    description = string,
    cidr_blocks = string
  }))
  default = []
}

variable "event_name" {
  description = "Name of the event that the workshop is being run for, e.g. 'STL-Public-Library-Hackathon'"
  type        = string
}

variable "num_teams" {
  description = "How many teams will be participating in the workshop"
  type        = number
  default     = 1
}

variable "ssh_local_key_path" {
  description = "Local path to the admin's SSH public (NOT private) key for instance access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}
