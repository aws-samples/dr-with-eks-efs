# Install gettext
sudo yum install -y gettext

# Install eskctl
curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz"
tar -xzf eksctl_Linux_amd64.tar.gz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Set kubeconfig

aws eks update-kubeconfig --name dr --region us-east-1
aws eks update-kubeconfig --name primary --region us-west-2



# Clone workshop repo

git clone https://github.com/aws-samples/dr-with-eks-efs.git
cd dr-with-eks-efs/workshop

#!/bin/bash

# Function to add or update an environment variable in .bashrc
add_or_update_env_var() {
    local var_name=$1
    local var_value=$2
    local bashrc_file=~/.bashrc

    # Check if the variable already exists in .bashrc
    if grep -q "export $var_name=" "$bashrc_file"; then
        # Update existing variable
        sed -i "s|export $var_name=.*|export $var_name=\"$var_value\"|" "$bashrc_file"
    else
        # Add new variable
        echo "export $var_name=\"$var_value\"" >> "$bashrc_file"
    fi
}

# Add your environment variables here
add_or_update_env_var

add_or_update_env_var "MY_VARIABLE" "my_value"
add_or_update_env_var "AWS_DEFAULT_REGION" "us-west-2"

# Add more variables as needed
# add_or_update_env_var "ANOTHER_VARIABLE" "another_value"

echo "Environment variables have been added/updated in ~/.bashrc"

# Source .bashrc to apply changes to the current session
source ~/.bashrc

echo "Changes have been applied to the current session"

# Optionally, print the new variables to verify
echo "MY_VARIABLE is now set to: $MY_VARIABLE"
echo "AWS_DEFAULT_REGION is now set to: $AWS_DEFAULT_REGION"
