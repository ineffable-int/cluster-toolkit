mock_provider "google" {}
mock_provider "google-beta" {}
mock_provider "null" {}
mock_provider "helm" {}
mock_provider "http" {}
mock_provider "kubernetes" {}
mock_provider "time" {}

override_module {
  target = module.kubectl_apply
}

override_module {
  target = module.dranet_template_apply
}

override_data {
  target = data.google_container_cluster.gke_cluster
  values = {
    networking_mode   = "VPC_NATIVE"
    datapath_provider = "ADVANCED_DATAPATH"
  }
}

variables {
  labels                  = {}
  project_id              = "test-project"
  cluster_id              = "projects/test-project/locations/us-central1/clusters/test-cluster"
  internal_ghpc_module_id = "test-pool"
  gke_version             = "1.34.0-gke.0"
  machine_type            = "n2-standard-4"
  zones                   = ["us-central1-a"]
  static_node_count       = 18
  num_node_pools          = 2
}

run "terraform_manages_count_by_default" {
  command = plan

  assert {
    condition     = alltrue([for pool in google_container_node_pool.node_pool : pool.ignore_node_count_changes == false && pool.node_count == 18 && length(pool.autoscaling) == 0])
    error_message = "Static pools must continue to manage node count by default, with GKE autoscaling disabled."
  }
}

run "external_controller_manages_count" {
  command = plan

  variables {
    ignore_node_count_changes = true
  }

  assert {
    condition     = length(google_container_node_pool.node_pool) == 2 && alltrue([for pool in google_container_node_pool.node_pool : pool.ignore_node_count_changes == true && pool.node_count == 18 && length(pool.autoscaling) == 0])
    error_message = "Every replica must ignore external resizing while retaining its creation count and disabling GKE autoscaling."
  }
}
