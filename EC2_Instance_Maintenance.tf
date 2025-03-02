resource "null_resource" "perform_maintenance" {
  triggers = {
    vm_id = aws_instance.vm.id
  }

  provisioner "local-exec" {
    command = "aws ec2 reboot-instances --instance-ids ${aws_instance.vm.id}"
  }
}
