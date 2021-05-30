variable "prefix" {
  description = "The prefix which should be used for all resources in this example"
  default = "nauran"
}

variable "reason"{
  description = "The reason for creating this resources"
  default = "udacity-project"
}

variable "location" {
  description = "The Azure Region in which all resources in this template should be created."
  default = "West US" 
}

variable "username"{
  default = "naurandevops"
}

variable "password"{
  default= "Admin123"
}

variable "server_names"{
  type = list
  default = ["hamming","wilkes"]
}

variable "packerImageId"{
  default = "/subscriptions/cd100e65-a83e-459c-ad08-34bc29cc5182/resourceGroups/nauran-devops/providers/Microsoft.Compute/images/WebServerLinux"
}

variable "vm_count"{
  default = "2"
}