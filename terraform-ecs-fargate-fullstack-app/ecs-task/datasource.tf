

provider "aws" {
  region = "us-east-1"

}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["ecs-vpc"]
  }
}

data "aws_subnet" "private1" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "us-east-1a"

  filter {
    name   = "tag:Name"
    values = ["ecs-private1"]
  }
}

data "aws_subnet" "private2" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "us-east-1b"

  filter {
    name   = "tag:Name"
    values = ["ecs-private2"]
  }
}

data "aws_security_group" "sg" {
  vpc_id = data.aws_vpc.vpc.id

  filter {
    name   = "tag:Name"
    values = ["lb-sg"]
  }
}

data "aws_subnet" "public1" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "us-east-1a"

  filter {
    name   = "tag:Name"
    values = ["ecs-public1"]
  }
}

data "aws_subnet" "public2" {
  vpc_id            = data.aws_vpc.vpc.id
  availability_zone = "us-east-1b"

  filter {
    name   = "tag:Name"
    values = ["ecs-public2"]
  }
}
