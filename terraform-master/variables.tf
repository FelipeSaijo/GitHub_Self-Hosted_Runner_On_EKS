### VPC VARIABLES ###
variable "availability_zones" {
    type        = list(string)
    description = "Availability Zones"
    default     = [ "us-east-1a", "us-east-1b" ]
}

variable "public_subnets_cidrs" {
    type        = list(string)
    description = "Public Subnets CIDR Blocks"
    default     = [ "10.132.1.0/24", "10.132.3.0/24" ]
}

variable "private_subnets_cidrs" {
    type        = list(string)
    description = "Private Subnets CIDR Blocks"
    default     = [ "10.132.2.0/24", "10.132.4.0/24" ]
}