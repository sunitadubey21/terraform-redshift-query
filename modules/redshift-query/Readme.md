### Generating token

```shell
# example values
CLIENT_ID='5u0tpifcvdd6iaavnjhfh9v1c1'
USER_NAME='cencosud-uid-1'
PASSWORD='@Password1234'
NAME='Cencosud Cencosud'
EMAIL='cencosud-uid-1@cencosud.com'
POOL_ID='ap-south-1_zqs2uXBM6'

# register user
aws cognito-idp sign-up \
  --client-id ${CLIENT_ID} \
  --username ${USER_NAME} \
  --password ${PASSWORD} \
  --user-attributes Name=name,Value=${NAME} Name=email,Value=${EMAIL}

# verify user
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id ${POOL_ID} \
  --username ${USER_NAME}

# Get Token
aws cognito-idp initiate-auth \
 --client-id ${CLIENT_ID} \
 --auth-flow USER_PASSWORD_AUTH \
 --auth-parameters USERNAME=${USER_NAME},PASSWORD=${PASSWORD} \
 --query 'AuthenticationResult.IdToken' \
 --output text
```

### Redshift query
```shell
# Create query
QUERY_ID=$(aws redshift-data execute-statement \
  --cluster-identifier tf-redshift-cluster \
  --database mydb \
  --sql 'SELECT id, "name", email FROM public.users' \
  --query 'Id' \
  --output text)

# Describing statement for status
aws redshift-data describe-statement \
  --id ${QUERY_ID}
  
# Getting result
aws redshift-data get-statement-result \
  --id ${QUERY_ID}
```

### Requirements related to Lambda and DynamoDB

1. The dynamodb document will include the (parameterizable) query to execute, the arn of the redshift to which it must connect and the name of the user with which the lambda will authenticate to redshift, it is important to consider that the index is made up of host + API path.

2. Regarding IAM, there must be at least one role for each redshift, We must consider that IAM authentication will work as cross account, this implies that the lambda must assume a role in the other account


