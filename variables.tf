variable "aws_region" {
  default = "us-east-1"
}

variable "account_id" {
  type    = string
  default = "350711180666"
}

variable "tags" {
  type        = map(string)
  description = "Tags default Redshift"
  default     = {
  }
}

variable "nombre" {
  type = string
}

variable "propietario" {
  type = string
}

variable "ceco" {
  type = string
}

variable "aplicacion" {
  type = string
}

variable "ambiente" {
  type = string
}

variable "proyecto" {
  type = string
}

variable "pais" {
  type = string
}

variable "cuenta" {
  type = number
}

variable "pep" {
  type = string
}
