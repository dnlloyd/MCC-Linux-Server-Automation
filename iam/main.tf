# https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-restrict-access-quickstart.html

variable "canvas_students_file" {}

locals {
  ec2_read_only_grp_id = "b4b82408-9031-705b-0563-76bec015e192"
  students = jsondecode(file(var.canvas_students_file))
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

data "aws_ssoadmin_instances" "this" {}

resource "aws_identitystore_user" "student" {
  for_each = local.students

  identity_store_id = local.identity_store_id

  display_name = each.value["full_name"]
  user_name    = each.key

  name {
    given_name  = each.value["first_name"]
    family_name = each.value["last_name"]
  }

  emails {
    value = each.value["email"]
    primary = true
  }
}

resource "aws_identitystore_group_membership" "students_to_ec2_ro" {
  for_each = aws_identitystore_user.student

  identity_store_id = local.identity_store_id
  # TODO: Automate this group created in identity store to allow association of permission sets
  group_id          = local.ec2_read_only_grp_id
  member_id         = each.value.user_id
}
