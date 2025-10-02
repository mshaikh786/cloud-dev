# IAM Role for EC2 instances
resource "aws_iam_role" "rke2_instance_role" {
  count = var.create_custom_iam_role && var.existing_iam_instance_profile_name == null ? 1 : 0

  name = "${var.iam_role_name_prefix}${var.cluster_name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = local.common_tags
}

# Attach SSM policy for instance management
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  count = var.create_custom_iam_role && var.existing_iam_instance_profile_name == null ? 1 : 0

  role       = aws_iam_role.rke2_instance_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach additional IAM policies if specified
resource "aws_iam_role_policy_attachment" "additional_policies" {
  count = var.create_custom_iam_role && var.existing_iam_instance_profile_name == null ? length(var.additional_iam_policies) : 0

  role       = aws_iam_role.rke2_instance_role[0].name
  policy_arn = var.additional_iam_policies[count.index]
}



# Create Iam Policy for Karpenter
resource "aws_iam_policy" "karpenter_controller_policy" {
  count = var.create_custom_iam_role && var.existing_iam_instance_profile_name == null ? 1 : 0
  name        = "${var.cluster_name}-KarpenterControllerPolicy"
  description = "Karpenter controller policy for RKE2"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "ec2:TerminateInstances",
          "ec2:Describe*",
          "ec2:DeleteLaunchTemplate",
          "ssm:GetParameter",
          "iam:PassRole",
          "pricing:GetProducts",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        Resource = "*"
      }
    ]
  })

  tags = local.common_tags
}

# Attach Karpenter controller role to RKE2 instance profile
resource "aws_iam_role_policy_attachment" "karpenter_controller_to_rke2" {
  count = var.create_custom_iam_role && var.existing_iam_instance_profile_name == null ? 1 : 0
  
  role       = aws_iam_role.rke2_instance_role[0].name
  policy_arn = aws_iam_policy.karpenter_controller_policy[0].arn
}


# Create instance profile for EC2 instances
resource "aws_iam_instance_profile" "rke2_instance_profile" {
  count = var.create_custom_iam_role && var.existing_iam_instance_profile_name == null ? 1 : 0

  name = "${var.iam_role_name_prefix}${var.cluster_name}-instance-profile"
  role = aws_iam_role.rke2_instance_role[0].name
}

