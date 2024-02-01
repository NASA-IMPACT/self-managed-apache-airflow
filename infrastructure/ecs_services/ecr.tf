
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
  for_each = toset([aws_ecr_repository.airflow.name, aws_ecr_repository.worker_airflow.name])
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
locals {

build_path = "../${path.root}/airflow_services"
  dag_folder_path = "../${path.root}/dags"
  scripts_path = "../${path.root}/scripts"
  config_path = "../${path.root}/configuration"
  worker_build_path = "../${path.root}/airflow_worker"
}


resource "null_resource" "build_ecr_image" {
  triggers = {
    build_path = sha1(join("", [for f in fileset(local.build_path, "**") : filesha1("${local.build_path}/${f}")]))
    scripts_path = sha1(join("", [for f in fileset(local.scripts_path, "**") : filesha1("${local.scripts_path}/${f}")]))
    dag_folder_path       = sha1(join("", [for f in fileset(local.dag_folder_path, "**") : filesha1("${local.dag_folder_path}/${f}")]))
    config_folder_path       = sha1(join("", [for f in fileset(local.config_path, "**") : filesha1("${local.config_path}/${f}")]))


  }

  provisioner "local-exec" {
    command = <<EOF
          cd ../${path.root}
          aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
          docker buildx build -t ${aws_ecr_repository.airflow.repository_url}:latest -f airflow_services/Dockerfile --platform linux/amd64 .
          docker push ${aws_ecr_repository.airflow.repository_url}:latest
          cd -
       EOF
  }
}


resource "null_resource" "build_worker_ecr_image" {
  triggers = {
    build_path_worker = sha1(join("", [for f in fileset(local.worker_build_path, "**") : filesha1("${local.worker_build_path}/${f}")]))
    dag_folder_path       = sha1(join("", [for f in fileset(local.dag_folder_path, "**") : filesha1("${local.dag_folder_path}/${f}")]))
  }

  provisioner "local-exec" {
    command = <<EOF
          cd ../${path.root}
          aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
          docker buildx build -t ${aws_ecr_repository.worker_airflow.repository_url}:latest -f airflow_worker/Dockerfile --platform linux/amd64 .
          docker push ${aws_ecr_repository.worker_airflow.repository_url}:latest
          cd -
       EOF
  }
}


