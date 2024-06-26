export AccountId=$(aws sts get-caller-identity --query "Account" --output text)

export PRI_ENVIRONMENT_NAME=$(aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[0].Parameters[?ParameterKey == 'EnvironmentName'].ParameterValue" --output text --region $PRI_REGION)

export PRI_PRIVATE_SUBNET_1=$(aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet1')].OutputValue" --output text --region $PRI_REGION)

export PRI_PRIVATE_SUBNET_2=$(aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet2')].OutputValue" --output text --region $PRI_REGION)

export PRI_EFS_ID=$(aws cloudformation describe-stacks --stack-name $PRI_CFN_NAME --query "Stacks[].Outputs[?contains(OutputKey, 'EFS')].OutputValue" --output text --region $PRI_REGION)
