terraform {
  backend "s3" {
    region         = "us-west-2"
    bucket         = "smallsat-tf-shared-state"
    key            = "airflow-sm2a"
    dynamodb_table = "smallsat-tf-sm2a"
  }
}

