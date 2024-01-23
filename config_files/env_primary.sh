export AccountId=$(aws sts get-caller-identity --query "Account" --output text)

export AWS_REGION_Primary=$(aws ec2 describe-availability-zones --output text --query "AvailabilityZones[0].[RegionName]")

export EnvironmentNamePrimary=$(aws cloudformation describe-stacks --stack-name primary --query "Stacks[0].Parameters[?ParameterKey == 'EnvironmentName'].ParameterValue" --output text)

export PrivateSubnet1Primary=$(aws cloudformation describe-stacks --stack-name awsblogstack --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet1')].OutputValue" --output text)

export PrivateSubnet2Primary=$(aws cloudformation describe-stacks --stack-name awsblogstack --query "Stacks[0].Outputs[?contains(OutputKey, 'PrivateSubnet2')].OutputValue" --output text)

export ClusterPrimary=clusterprimary
