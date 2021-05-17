# Variable Declarations

variable "resource_group_name" {
  type = string
}

variable "RGlocation" {
  type = string
}

variable "mgmt_subnet_id" {
  type = string
}

variable "int_subnet_id" {
  type = string
}

variable "ext_subnet_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "source_resource_id" {
  type = string
}