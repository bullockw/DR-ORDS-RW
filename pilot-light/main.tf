// Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

terraform {
  required_version = ">= 0.12.0"

  backend "local" {
    path = "./state/terraform.tfstate"
  }
}

locals {
  availability_domain = lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")
  image_id = data.oci_core_images.oraclelinux.images.0.id

  dr_availability_domain = lookup(data.oci_identity_availability_domains.DR_ADs.availability_domains[0], "name")
  dr_image_id = data.oci_core_images.DR_oraclelinux.images.0.id
}


#################################################
### destination region resource provisioning ####
#################################################
module dr_network {
  source = "./modules/network"

  providers = {
      oci.destination    = "oci.dr"
  }

  tenancy_ocid           = var.tenancy_ocid
  compartment_id         = var.compartment_ocid
  vcn_name               = var.vcn_dns_label
  dns_label              = var.vcn_dns_label
  vcn_cidr_block         = var.dr_vcn_cidr_block
  remote_app_vcn_cidr    = var.vcn_cidr_block
  freeform_tags          = var.freeform_tags
  defined_tags           = var.defined_tags
  create_remote_peering  = true

  remote_peering_connection_id  = null
  remote_peering_connection_peer_region_name = null
}

module dr_bastion_instance {
  source = "./modules/bastion_instance"

  providers = {
      oci.destination = "oci.dr"
  }

  tenancy_ocid        = var.tenancy_ocid
  compartment_id      = var.compartment_ocid
  source_id           = local.dr_image_id
  subnet_id           = module.dr_network.dr_access_subnet_id
  availability_domain = local.dr_availability_domain
  ping_all_id         = module.dr_network.dr_ping_all_id
  dr_region           = var.dr_region
  shape               = var.bastion_server_shape

  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file

  freeform_tags          = var.freeform_tags
  defined_tags           = var.defined_tags
}

module dr_public_lb {
  source = "./modules/lb"

  providers = {
      oci.destination          = "oci.dr"
  }

  compartment_id      = var.compartment_ocid
  subnet_id           = module.dr_network.dr_lb_subnet_id
  display_name        = var.lb_display_name
  is_private          = var.is_private_lb
  shape               = var.lb_shape
  instance1_private_ip = null
  instance2_private_ip = null
  add_backend_set     = false
}



#############################################
### primary region resource provisioning ####
#############################################
module network {
  source = "./modules/network"

  providers = {
      oci.destination    = "oci"
  }

  tenancy_ocid           = var.tenancy_ocid
  compartment_id         = var.compartment_ocid
  vcn_name               = var.vcn_dns_label
  dns_label              = var.vcn_dns_label
  vcn_cidr_block         = var.vcn_cidr_block
  remote_app_vcn_cidr    = var.dr_vcn_cidr_block
  freeform_tags          = var.freeform_tags
  defined_tags           = var.defined_tags

  create_remote_peering  = false
  remote_peering_connection_id  = module.dr_network.dr_remote_peering_id
  remote_peering_connection_peer_region_name = var.dr_region
}

module bastion_instance {
  source = "./modules/bastion_instance"

  providers = {
      oci.destination = "oci"
  }

  tenancy_ocid        = var.tenancy_ocid
  compartment_id      = var.compartment_ocid
  source_id           = local.image_id
  subnet_id           = module.network.dr_access_subnet_id
  availability_domain = local.availability_domain
  ping_all_id         = module.network.dr_ping_all_id
  dr_region           = var.dr_region
  shape               = var.bastion_server_shape

  ssh_public_key_file  = var.ssh_public_key_file
  ssh_private_key_file = var.ssh_private_key_file

  freeform_tags          = var.freeform_tags
  defined_tags           = var.defined_tags
}

module app_server_1 {
  source = "./modules/server"

  providers = {
      oci.destination    = "oci"
  }

  tenancy_ocid        = var.tenancy_ocid
  compartment_id      = var.compartment_ocid
  source_id           = local.image_id
  subnet_id           = module.network.dr_app_subnet_id
  availability_domain = local.availability_domain
  bastion_ip          = module.bastion_instance.dr_instance_ip
  display_name        = var.appserver_1_display_name
  hostname_label      = var.appserver_1_display_name
  shape               = var.app_server_shape
  ping_all_id         = module.network.dr_ping_all_id

  ssh_private_key_file = var.ssh_private_key_file
  ssh_public_key_file   = var.ssh_public_key_file

}

module app_server_2 {
  source = "./modules/server"

  providers = {
      oci.destination    = "oci"
  }

  tenancy_ocid        = var.tenancy_ocid
  compartment_id      = var.compartment_ocid
  source_id           = local.image_id
  subnet_id           = module.network.dr_app_subnet_id
  availability_domain = local.availability_domain
  bastion_ip          = module.bastion_instance.dr_instance_ip
  display_name        = var.appserver_2_display_name
  hostname_label      = var.appserver_2_display_name
  shape               = var.app_server_shape
  ping_all_id         = module.network.dr_ping_all_id

  ssh_private_key_file = var.ssh_private_key_file
  ssh_public_key_file   = var.ssh_public_key_file
}

module public_lb {
  source = "./modules/lb"

  compartment_id      = var.compartment_ocid
  subnet_id           = module.network.dr_lb_subnet_id
  display_name        = var.lb_display_name
  is_private          = var.is_private_lb
  shape               = var.lb_shape
  instance1_private_ip = module.app_server_1.instance_ip
  instance2_private_ip = module.app_server_2.instance_ip
  add_backend_set     = true
}

module database {
  source = "./modules/dbaas"

  providers = {
      oci.destination    = "oci"
  }

  compartment_id      = var.compartment_ocid
  subnet_id           = module.network.dr_db_subnet_id
  availability_domain = local.availability_domain
  display_name        = var.db_display_name
  ping_all_id         = module.network.dr_ping_all_id
  ssh_public_keys     = file(var.ssh_public_key_file)
  db_system_shape     = var.db_system_shape
  db_admin_password   = var.db_admin_password

  remote_subnet_id    = module.dr_network.dr_db_subnet_id
  remote_nsg_ids      = module.dr_network.dr_ping_all_id
  remote_availability_domain = local.dr_availability_domain
}
##############################################
#### ORDS ######################

module "ords" {
  source = "./modules/ORDS"

  providers = {
    oci.destination = oci
  }

  compartment_id      = var.compartment_ocid
  availability_domain = local.availability_domain
  tenancy_ocid        = var.tenancy_ocid
  display_name        = "ORDS-Comp"
  hostname_label      = "ords-comp"
  subnet_id           = module.network.dr_access_subnet_id
  source_id           = local.image_id
  ssh_public_key      = file(var.ssh_public_key_file)
  ssh_private_key     = file(var.ssh_private_key_file)
  ZoneName = var.ZoneName
  api_private_key = var.private_key_path
  compartment_ocid = var.compartment_ocid
  fingerprint = var.fingerprint
  private_key_path = var.private_key_path
  region = var.region
  subnet_ocid = module.dr_network.dr_db_subnet_id
  target_db_admin_pw = var.db_admin_password
  target_db_ip = module.database.ip
  target_db_name = module.database.db_hostname
  target_db_srv_name = "${module.database.pdb_name}.${module.database.db_domain}"
  user_ocid = var.user_ocid
  pdb_name = module.database.pdb_name
  URL_ORDS_file = var.URL_ORDS_file
  URL_APEX_file = var.URL_APEX_file
}

