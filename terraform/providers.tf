provider "aws" {
  region = "${var.region}"
  version = "~> 2.66"
}

provider "local" {
  version = "~> 1.4"
}

provider "template" {
  version = "~> 2.1"
}
