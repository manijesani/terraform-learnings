output "aws_instance_ip" {
    value = module.myapp-server.instance.public_ip
}