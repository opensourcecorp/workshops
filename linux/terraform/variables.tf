variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "event" {
  description = "Name of the event that the workshop is being run for"
  default     = "testing"
  type        = string
}