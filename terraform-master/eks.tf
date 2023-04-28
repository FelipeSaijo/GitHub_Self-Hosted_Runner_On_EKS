################################
#                              #
#      EKS Cluster Config      #
#                              #
################################

resource "aws_eks_cluster" "project_cluster" {
  name                      = "FS-Github-Runner"
  role_arn                  = aws_iam_role.eks_cluster_role.arn
  
  vpc_config {
    subnet_ids              = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
    endpoint_public_access  = true
  }   
  
  depends_on = [
    aws_iam_role_policy_attachment.EKS_Cluster_Policy,
    aws_iam_role_policy_attachment.EKS_VPC_Resource_Controller,
  ]
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    effect = "Allow"  
  
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    } 
  
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "EKS_Cluster_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "EKS_VPC_Resource_Controller" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

################################
#                              #
#       EKS Node Config        #
#                              #
################################

resource "aws_eks_node_group" "cluster_node_github_runner" {
  cluster_name    = aws_eks_cluster.project_cluster.name
  node_group_name = "FS_GitHub_runner_Node"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private_subnet[*].id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  } 

  ami_type       = "AL2_x86_64"
  instance_types = ["t3a.medium"]
  capacity_type  = "ON_DEMAND"
  disk_size      = 20

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.EKS-Worker-Node-Policy,
    aws_iam_role_policy_attachment.EKS-CNI-Policy,
    aws_iam_role_policy_attachment.EC2Container-Registry-ReadOnly,
  ]
}

resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "EKS-Worker-Node-Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "EKS-CNI-Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "EC2Container-Registry-ReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}