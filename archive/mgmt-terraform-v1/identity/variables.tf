variable "project_id" {
  description = "The GCP Project ID hosting the management plane"
  type        = string
  default     = "ait-brainlab-mgmt"
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "asia-southeast1"
}

variable "domain" {
  description = "Base domain name for AIT Brainlab"
  type        = string
  default     = "brain.cs.ait.ac.th"
}

variable "lldap_http_url" {
  description = "The HTTPS Web API endpoint for LLDAP"
  type        = string
  default     = "https://authen2.brain.cs.ait.ac.th"
}

variable "lldap_ldap_url" {
  description = "The LDAP protocol endpoint for LLDAP"
  type        = string
  default     = "ldap://authen2.brain.cs.ait.ac.th:3890"
}

variable "lldap_admin_user" {
  description = "LLDAP Administrative username"
  type        = string
  default     = "admin"
}

variable "base_dn" {
  description = "LLDAP Base Distinguished Name"
  type        = string
  default     = "dc=brain,dc=cs,dc=ait,dc=ac,dc=th"
}
