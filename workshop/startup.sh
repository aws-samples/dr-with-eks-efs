#!/bin/bash

# Install gettext
sudo yum install -y gettext

# Install kubectx
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# Install eskctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Set kubeconfig

aws eks update-kubeconfig --name dr --region us-east-1
aws eks update-kubeconfig --name primary --region us-west-2

# Function to add or update an environment variable in .bashrc
add_or_update_env_var() {
    local var_name=$1
    local var_value=$2
    local bashrc_file=~/.bashrc
    sed -i "/export $var_name=/d" "$bashrc_file"
    echo "export $var_name=\"$var_value\"" >> "$bashrc_file"
}

# Add your environment variables here
add_or_update_env_var "AWS_DEFAULT_REGION" "us-west-2"
add_or_update_env_var "PRI_REGION" "us-west-2"
add_or_update_env_var "PRI_ENVIRONMENT_NAME" "primary"
add_or_update_env_var "PRI_CFN_NAME" "primary-workshop"
add_or_update_env_var "PRI_CLUSTER_NAME" "primary"
add_or_update_env_var "PRI_PRIVATE_SUBNET_1" "$(aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet1')].OutputValue" --output text --region $PRI_REGION)"
add_or_update_env_var "PRI_PRIVATE_SUBNET_2" "$(aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet2')].OutputValue" --output text --region $PRI_REGION)"

add_or_update_env_var "DR_REGION" "us-east-1"
add_or_update_env_var "DR_ENVIRONMENT_NAME" "dr"
add_or_update_env_var "DR_CFN_NAME" "dr"
add_or_update_env_var "DR_CLUSTER_NAME" "dr"
add_or_update_env_var "DR_PRIVATE_SUBNET_1" "$(aws cloudformation describe-stacks --stack-name $DR_CFN_NAME --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet1')].OutputValue" --output text --region $Dr_REGION)"
add_or_update_env_var "DR_PRIVATE_SUBNET_2" "$(aws cloudformation describe-stacks --stack-name $DR_CFN_NAME --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet2')].OutputValue" --output text --region $DR_REGION)"

# Add more variables as needed
# add_or_update_env_var "ANOTHER_VARIABLE" "another_value"

echo "Environment variables have been added/updated in ~/.bashrc"

# Source .bashrc to apply changes to the current session
source ~/.bashrc

echo "Changes have been applied to the current session"

# Optionally, print the new variables to verify
#echo "MY_VARIABLE is now set to: $MY_VARIABLE"



# Clone GitHub repo for the workshop

git clone https://github.com/aws-samples/dr-with-eks-efs.git
cd dr-with-eks-efs/workshop
