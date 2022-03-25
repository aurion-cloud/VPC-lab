resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"

  tags = {
      Name = "talent-academy-vpc"
  }
}

# Creating Subnet for public
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.1.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true

    tags = {
        Name = "talent-academy-public-a"
    }
}


# Creating Subnet for PRIVATE

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.2.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "talent-academy-private-a"
    }
}


# Creating Subnet for DATA 

resource "aws_subnet" "database" {
    vpc_id = aws_vpc.main.id
    cidr_block = "192.168.3.0/24"
    availability_zone = "us-east-1a"

    tags = {
        Name = "talent-academy-database-a"
    }
}


# CREATING THE INTERNET GATEWAY
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "talent-academy-igw"
  }
}


resource "aws_eip" "nat_eip" {
  vpc = true
}


# CREATING THE NAT GATEWAY
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  connectivity_type = "public"
  subnet_id = aws_subnet.public.id

  tags = {
    Name = "Nat gw"
  }

    # terraform waits for all the resources . Since it is a square bracket it is a list of resources
  depends_on = [aws_internet_gateway.igw]
}




resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "nat-route-table"
  }
}

resource "aws_route_table" "igw_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "igw_route_table"
  }
}

# ASSOCIATE ROUTE TABLE -- APP LAYER
resource "aws_route_table_association" "internet_route_table_association_app" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.nat_route_table.id
}

# ASSOCIATE ROUTE TABLE -- DATA LAYER
resource "aws_route_table_association" "internet_route_table_association_public" {
  subnet_id      = aws_subnet.database.id
  route_table_id = aws_route_table.nat_route_table.id
}

# ASSOCIATE ROUTE TABLE -- PUBLIC LAYER
resource "aws_route_table_association" "internet_route_table_association_data" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.igw_route_table.id
}

