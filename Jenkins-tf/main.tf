resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "Main"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_default_route_table.example.id
}

resource "aws_default_security_group" "default_sg" {
  vpc_id = aws_vpc.main.id

  ingress = [
    for port in [22, 80, 443, 8080, 9000, 3000] : {
      description      = "TLS from VPC"
      from_port        = port
      to_port          = port
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "default_sg"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0c7217cdde317cfec"   #change ami id for different region
  instance_type          = "t2.large"
  key_name               = "mynewkey"
  vpc_security_group_ids = [aws_default_security_group.default_sg.id]
  subnet_id = aws_subnet.main.id
  user_data              = templatefile("./install.sh", {})

  tags = {
    Name = "Jenkins-sonarqube"
  }

  root_block_device {
    volume_size = 30
  }
}
