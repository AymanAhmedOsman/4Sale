# Step 3: Create an EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.eks_role.arn
  version  = "1.30"

  vpc_config {
    subnet_ids              = [var.subnet-public-1-id , var.subnet-private-1-id , var.subnet-public-2-id, var.subnet-private-2-id]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids = [var.public-sg-name]
  }
  
}



# Step 4: Create IAM role for EKS
resource "aws_iam_role" "eks_role" {
  name               = "eks_role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# Step 5: Attach IAM policies to the EKS role
resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Step 6: Create a Load Balancer Controller IAM role
resource "aws_iam_role" "lb_controller_role" {
  name               = "lb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role_policy.json
}

# If you need to use Alb and change all lb to alb
# resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
#   role       = aws_iam_role.alb_controller_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancerControllerPolicy"
# }

data "aws_iam_policy_document" "lb_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# Step 9: Create an EKS Node Group
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.node-group-name
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [var.subnet-private-1-id , var.subnet-private-2-id]
  remote_access {
    ec2_ssh_key            = var.key_name
    source_security_group_ids = [ var.public-sg-name]

  }

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.medium"]
}

# Step 10: Create IAM role for EKS nodes
resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role_policy.json
}

data "aws_iam_policy_document" "eks_node_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Step 11: Attach policies to the EKS node role
resource "aws_iam_role_policy_attachment" "node_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "registry_policy_attachment" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Step 12: Configure Helm provider for Kubernetes
provider "kubernetes" {
  host                   = aws_eks_cluster.eks_cluster.endpoint
  token                  = data.aws_eks_cluster_auth.eks_auth.token
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks_cluster.certificate_authority[0].data)
}

data "aws_eks_cluster_auth" "eks_auth" {
  name = aws_eks_cluster.eks_cluster.name
}

#--------------------use ALB-------

resource "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancerControllerPolicy"
}

# data "aws_iam_policy_document" "lb_controller_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"] # for pods using IAM roles via IRSA, will update below
#     }
#   }
# }

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da0ecd4e0a4"] # AWS OIDC thumbprint
}


resource "kubernetes_service_account" "alb_controller" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
    }
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = aws_eks_cluster.eks_cluster.name
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.alb_controller.metadata[0].name
    }
  ]
}

resource "aws_iam_policy" "alb_controller_policy" {
  name        = "AWSLoadBalancerControllerIAMPolicy"
  description = "IAM policy for AWS Load Balancer Controller"
  # policy      = file("iam-policy.json")
  policy      = <<EOT
/*
Note: This is a generated HCL content from the JSON input which is based on the latest API version available.
To import the resource, please run the following command:
terraform import azapi_resource. ?api-version=TODO

Or add the below config:
import {
  id = "?api-version=TODO"
  to = azapi_resource.
}
*/

resource "azapi_resource" "" {
  type      = "@TODO"
  parent_id = "/subscriptions/$${var.subscriptionId}/resourceGroups/$${var.resourceGroupName}"
  name      = ""
  body = {
    Statement = [{
      Action = ["iam:CreateServiceLinkedRole"]
      Condition = {
        StringEquals = {
          "iam:AWSServiceName" = "elasticloadbalancing.amazonaws.com"
        }
      }
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["ec2:DescribeAccountAttributes", "ec2:DescribeAddresses", "ec2:DescribeAvailabilityZones", "ec2:DescribeInternetGateways", "ec2:DescribeVpcs", "ec2:DescribeVpcPeeringConnections", "ec2:DescribeSubnets", "ec2:DescribeSecurityGroups", "ec2:DescribeInstances", "ec2:DescribeNetworkInterfaces", "ec2:DescribeTags", "ec2:GetCoipPoolUsage", "ec2:DescribeCoipPools", "ec2:GetSecurityGroupsForVpc", "ec2:DescribeIpamPools", "ec2:DescribeRouteTables", "elasticloadbalancing:DescribeLoadBalancers", "elasticloadbalancing:DescribeLoadBalancerAttributes", "elasticloadbalancing:DescribeListeners", "elasticloadbalancing:DescribeListenerCertificates", "elasticloadbalancing:DescribeSSLPolicies", "elasticloadbalancing:DescribeRules", "elasticloadbalancing:DescribeTargetGroups", "elasticloadbalancing:DescribeTargetGroupAttributes", "elasticloadbalancing:DescribeTargetHealth", "elasticloadbalancing:DescribeTags", "elasticloadbalancing:DescribeTrustStores", "elasticloadbalancing:DescribeListenerAttributes", "elasticloadbalancing:DescribeCapacityReservation"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["cognito-idp:DescribeUserPoolClient", "acm:ListCertificates", "acm:DescribeCertificate", "iam:ListServerCertificates", "iam:GetServerCertificate", "waf-regional:GetWebACL", "waf-regional:GetWebACLForResource", "waf-regional:AssociateWebACL", "waf-regional:DisassociateWebACL", "wafv2:GetWebACL", "wafv2:GetWebACLForResource", "wafv2:AssociateWebACL", "wafv2:DisassociateWebACL", "shield:GetSubscriptionState", "shield:DescribeProtection", "shield:CreateProtection", "shield:DeleteProtection"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["ec2:CreateSecurityGroup"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action = ["ec2:CreateTags"]
      Condition = {
        Null = {
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
        StringEquals = {
          "ec2:CreateAction" = "CreateSecurityGroup"
        }
      }
      Effect   = "Allow"
      Resource = "arn:aws:ec2:*:*:security-group/*"
      }, {
      Action = ["ec2:CreateTags", "ec2:DeleteTags"]
      Condition = {
        Null = {
          "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
      Effect   = "Allow"
      Resource = "arn:aws:ec2:*:*:security-group/*"
      }, {
      Action = ["ec2:AuthorizeSecurityGroupIngress", "ec2:RevokeSecurityGroupIngress", "ec2:DeleteSecurityGroup"]
      Condition = {
        Null = {
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action = ["elasticloadbalancing:CreateLoadBalancer", "elasticloadbalancing:CreateTargetGroup"]
      Condition = {
        Null = {
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action   = ["elasticloadbalancing:CreateListener", "elasticloadbalancing:DeleteListener", "elasticloadbalancing:CreateRule", "elasticloadbalancing:DeleteRule"]
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action = ["elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags"]
      Condition = {
        Null = {
          "aws:RequestTag/elbv2.k8s.aws/cluster"  = "true"
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
      Effect   = "Allow"
      Resource = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*", "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*", "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"]
      }, {
      Action   = ["elasticloadbalancing:AddTags", "elasticloadbalancing:RemoveTags"]
      Effect   = "Allow"
      Resource = ["arn:aws:elasticloadbalancing:*:*:listener/net/*/*/*", "arn:aws:elasticloadbalancing:*:*:listener/app/*/*/*", "arn:aws:elasticloadbalancing:*:*:listener-rule/net/*/*/*", "arn:aws:elasticloadbalancing:*:*:listener-rule/app/*/*/*"]
      }, {
      Action = ["elasticloadbalancing:ModifyLoadBalancerAttributes", "elasticloadbalancing:SetIpAddressType", "elasticloadbalancing:SetSecurityGroups", "elasticloadbalancing:SetSubnets", "elasticloadbalancing:DeleteLoadBalancer", "elasticloadbalancing:ModifyTargetGroup", "elasticloadbalancing:ModifyTargetGroupAttributes", "elasticloadbalancing:DeleteTargetGroup", "elasticloadbalancing:ModifyListenerAttributes", "elasticloadbalancing:ModifyCapacityReservation", "elasticloadbalancing:ModifyIpPools"]
      Condition = {
        Null = {
          "aws:ResourceTag/elbv2.k8s.aws/cluster" = "false"
        }
      }
      Effect   = "Allow"
      Resource = "*"
      }, {
      Action = ["elasticloadbalancing:AddTags"]
      Condition = {
        Null = {
          "aws:RequestTag/elbv2.k8s.aws/cluster" = "false"
        }
        StringEquals = {
          "elasticloadbalancing:CreateAction" = ["CreateTargetGroup", "CreateLoadBalancer"]
        }
      }
      Effect   = "Allow"
      Resource = ["arn:aws:elasticloadbalancing:*:*:targetgroup/*/*", "arn:aws:elasticloadbalancing:*:*:loadbalancer/net/*/*", "arn:aws:elasticloadbalancing:*:*:loadbalancer/app/*/*"]
      }, {
      Action   = ["elasticloadbalancing:RegisterTargets", "elasticloadbalancing:DeregisterTargets"]
      Effect   = "Allow"
      Resource = "arn:aws:elasticloadbalancing:*:*:targetgroup/*/*"
      }, {
      Action   = ["elasticloadbalancing:SetWebAcl", "elasticloadbalancing:ModifyListener", "elasticloadbalancing:AddListenerCertificates", "elasticloadbalancing:RemoveListenerCertificates", "elasticloadbalancing:ModifyRule", "elasticloadbalancing:SetRulePriorities"]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  }
}

  EOT
}

resource "aws_iam_role_policy_attachment" "alb_controller_policy_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

