

resource "null_resource" "destroy_time_script" {

  provisioner "local-exec" {
    when    = destroy
    command = "bash ../templates/BashScripts/remove_remaining_buckets.sh"
  }
}

