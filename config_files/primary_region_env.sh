export AccountId=$(aws sts get-caller-identity --query "Account" --output text)

export EnvironmentNamePrimary=$(aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].Parameters[?ParameterKey == 'EnvironmentName'].ParameterValue" --output text --region $AWS_REGION_PRIMARY)

export PrivateSubnet1Primary=$(aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet1')].OutputValue" --output text --region $AWS_REGION_PRIMARY)

export PrivateSubnet2Primary=$(aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet2')].OutputValue" --output text --region $AWS_REGION_PRIMARY)

export ClusterPrimary=clusterprimary
