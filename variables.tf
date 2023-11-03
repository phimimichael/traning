variable "region" {
  default = "ap-south-1"
}
variable "main_network" {
  default = "172.16.0.0/16"
}

variable "project_name" {
  description = "project_name"
  type        = string
  default     = "Wordpress"
}

variable "project_env" {
  description = "project_env"
  type        = string
  default     = "prod"
}

variable "instance_type" {
  description = "instance_type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "ami_id"
  type        = string
  default     = "ami-057752b3f1d6c4d6c"
}

