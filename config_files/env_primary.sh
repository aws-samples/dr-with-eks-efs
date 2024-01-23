export AccountId=$(aws sts get-caller-identity --query "Account" --output text)

export EnvironmentNamePrimary=$(aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].Parameters[?ParameterKey == 'EnvironmentName'].ParameterValue" --output text)

export AWS_REGION_Primary=eu-west-1

export PrivateSubnet1Primary=$(aws cloudformation describe-stacks --stack-name awsblogstack --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet1')].OutputValue" --output text)

export PrivateSubnet2Primary=$(aws cloudformation describe-stacks --stack-name awsblogstack --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet2')].OutputValue" --output text)

export ClusterPrimary=clusterprimary
