provider "aws" {
  region = "us-east-1"
}

provider "local" {
  version = "~> 1.4"
}

provider "template" {
  version = "~> 2.1"
}
