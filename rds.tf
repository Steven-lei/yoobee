data "aws_secretsmanager_secret" "db_secret" {
  name = "rds/wordpress"
}
data "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = data.aws_secretsmanager_secret.db_secret.id
}
locals {
  secret_values = jsondecode(data.aws_secretsmanager_secret_version.db_secret_version.secret_string)
}

#update the dbhost after RDS created
resource "aws_secretsmanager_secret_version" "updated_db_secret" {
  secret_id     = data.aws_secretsmanager_secret.db_secret.id

  secret_string = jsonencode({
    username = local.secret_values.username
    password = local.secret_values.password
    db_name  = local.secret_values.db_name
    dbhost   = aws_db_instance.rds.endpoint
  })

  depends_on = [aws_db_instance.rds] # update after RDS Created
}


# Security group for the RDS instance
resource "aws_security_group" "rds_sg" {
  name        = "${var.prefix}-rds-sg"
  description = "Allow MySQL access from web server only"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # Allow traffic from web server SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.prefix}-rds-sg"
  }
}
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [for subnet in values(aws_subnet.private_subnets) : subnet.id]#values(aws_subnet.private_subnets)[*].id
}

#enforce ssl
resource "aws_db_parameter_group" "rds_ssl_enforce" {
  name        = "${var.prefix}-rds-ssl-enforce"
  family      = "mysql8.0"   
  description = "Parameter group to enforce SSL connections for MySQL"

  parameter {
    name  = "require_secure_transport"
    value = "1"
    apply_method = "pending-reboot"  # reboot to apply
  }
}
#relational database services
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"                     
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"              # free tier eligible
  identifier           = "${var.prefix}-db"
  username             = local.secret_values.username
  password             = local.secret_values.password
  db_name              = local.secret_values.db_name
  publicly_accessible  = false
  multi_az             = false
  backup_retention_period = 0
  skip_final_snapshot  = true
  delete_automated_backups = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  #allow ssl connection only
  #parameter_group_name = aws_db_parameter_group.rds_ssl_enforce.name
  tags = {
    Name = "Free RDS"
    Env  = "Dev"
  }
}

# resource "aws_db_instance" "rds" {
#   allocated_storage           = 20
#   storage_type                = "gp2"
#   engine                      = "mysql"                
#   engine_version              = "8.0"
#   instance_class              = "db.t3.medium"           # Multi-AZ requires at least t3.medium
#   identifier                  = "${var.prefix}-db"
# username             = local.secret_values.username
# password             = local.secret_values.password
#  db_name              = local.secret_values.db_name
#   publicly_accessible         = false
#   multi_az                    = true                     # Enables standby in another AZ
#   backup_retention_period     = 7                        # Recommended when multi_az = true
#   delete_automated_backups    = true
#   skip_final_snapshot         = true
# db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
# vpc_security_group_ids = [aws_security_group.rds_sg.id]
# #allow ssl connection only
# parameter_group_name = aws_db_parameter_group.rds_ssl_enforce.name
#   tags = {
#     Name = "MultiAZ-RDS"
#     Env  = "Production"
#   }
# }


# #run db init
# resource "null_resource" "db_init" {
#   depends_on = [aws_db_instance.mydb]

#   provisioner "local-exec" {
#     command = <<EOT
#     mysql -h ${aws_db_instance.rds.address} -u ${aws_db_instance.rds.username} -p${aws_db_instance.rds.password} ${aws_db_instance.rds.name} < ./init.sql
#     EOT
#   }
# }


# output "rds_endpoint" {
#   description = "The RDS endpoint"
#   value       = aws_db_instance.rds.endpoint
# }