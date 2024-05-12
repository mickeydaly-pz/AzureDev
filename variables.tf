variable "resource_group_location" {
  default     = "canadacentral"
  description = "Location of the resource group."
}

variable "customer_prefix" {
  type        = string
  default     = "PZ"
  description = "Prefix of the resource name"
}

variable "dc_main_prefix" {
    type        = string
    default     = "PZ-DC1"
    description = "Prefix of the resource name"
}

variable "dc_backup_prefix" {
    type        = string
    default     = "PZ-DC2"
    description = "Prefix of the resource name"
}

variable "source_ip" {
    type = string
    default = "24.109.16.62/32"
    description = "Source IP prefix"
}