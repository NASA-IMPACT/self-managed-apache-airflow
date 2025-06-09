locals {
  subdomain           = var.subdomain == "null" ? var.stage : var.subdomain
  services_build_path = "../${path.root}/airflow_services"
  dag_folder_path     = "../${path.root}/dags"
  scripts_path        = "../${path.root}/scripts"
  config_path         = "../${path.root}/infrastructure/configuration"
  worker_build_path   = "../${path.root}/airflow_worker"
  config_files        = [for f in fileset(local.config_path, "**") : f if f != "airflow.cfg"]
}



locals {

  services_build_path_hash = sha1(join("", [for f in fileset(local.services_build_path, "**") : filesha1("${local.services_build_path}/${f}")]))
  dag_folder_hash          = sha1(join("", [for f in fileset(local.dag_folder_path, "**") : filesha1("${local.dag_folder_path}/${f}")]))
  scripts_folder_hash      = sha1(join("", [for f in fileset(local.scripts_path, "**") : filesha1("${local.scripts_path}/${f}")]))
  config_folder_hash       = sha1(join("", [for f in local.config_files : filesha1("${local.config_path}/${f}")]))
  worker_folder_hash       = sha1(join("", [for f in fileset(local.worker_build_path, "**") : filesha1("${local.worker_build_path}/${f}")]))
}


locals {

  services_hashes = [local.scripts_folder_hash, local.dag_folder_hash, local.config_folder_hash, local.services_build_path_hash]
  workers_hashes  = [local.dag_folder_hash, local.config_folder_hash, local.worker_folder_hash]

}


