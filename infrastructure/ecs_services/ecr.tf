
resource "aws_ecr_repository" "airflow" {
  name = "${var.prefix}-sm2a"
  image_scanning_configuration {
    scan_on_push = false
  }
}


resource "aws_ecr_repository" "worker_airflow" {
  name = "${var.prefix}-sm2a-worker"
  image_scanning_configuration {
    scan_on_push = false
  }
}


resource "aws_ecr_lifecycle_policy" "ecr_policy" {
  for_each   = toset([aws_ecr_repository.airflow.name, aws_ecr_repository.worker_airflow.name])
  repository = each.value
  policy = jsonencode({
    "rules" = [
      {
        "rulePriority" = 1,
        "description"  = "Expire images older than 14 days",
        "selection" : {
          "tagStatus"   = "untagged",
          "countType"   = "sinceImagePushed",
          "countUnit"   = "days",
          "countNumber" = 10
        },
        "action" : {
          "type" = "expire"
        }
      }
    ]
  })

}
resource "null_resource" "build_ecr_image" {
  triggers = {
    services_build_path_hash         = local.services_build_path_hash
    scripts_folder_hash       = local.scripts_folder_hash
    dag_folder_hash    = local.dag_folder_hash
    config_folder_hash = local.config_folder_hash
  }

  provisioner "local-exec" {
    command = <<EOF
          cd ../${path.root}
          aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
          docker buildx build --platform linux/amd64,linux/arm64 -t ${aws_ecr_repository.airflow.repository_url}:latest -f airflow_services/Dockerfile .
          docker push ${aws_ecr_repository.airflow.repository_url}:latest
          cd -
       EOF
  }
}


resource "null_resource" "build_worker_ecr_image" {
  triggers = {
    worker_folder_hash = local.worker_folder_hash
    dag_folder_hash    = local.dag_folder_hash
  }

  provisioner "local-exec" {
    command = <<EOF
          cd ../${path.root}
          aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
          docker buildx build --platform linux/amd64,linux/arm64 -t ${aws_ecr_repository.worker_airflow.repository_url}:latest -f airflow_worker/Dockerfile .
          docker push ${aws_ecr_repository.worker_airflow.repository_url}:latest
          cd -
       EOF
  }
}



