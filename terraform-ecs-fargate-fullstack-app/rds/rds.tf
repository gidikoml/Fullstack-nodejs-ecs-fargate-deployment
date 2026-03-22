

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



resource "aws_db_instance" "rds" {
  allocated_storage       = 20
  identifier              = "book-rds"
  db_subnet_group_name    = aws_db_subnet_group.sub-grp.id
  engine                  = "mysql"
  engine_version          = "8.4.7"
  instance_class          = "db.t3.micro"
  multi_az                = true
  db_name                 = "mydb"
  username                = "admin"
  password                = "Yaswanth123reddy"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [data.aws_security_group.sg.id]
  depends_on              = [aws_db_subnet_group.sub-grp]
  publicly_accessible     = true # Make RDS publicly accessible
  backup_retention_period = 7
  apply_immediately       = true # ✅ this is the key


  tags = {
    DB_identifier = "book-rds"
  }
}

resource "aws_db_subnet_group" "sub-grp" {
  name       = "rds"
  subnet_ids = [data.aws_subnet.private1.id, data.aws_subnet.private2.id]

  tags = {
    Name = "My-DB-subnet-group"
  }
}


output "rds_address" {
  value = aws_db_instance.rds.address
}
