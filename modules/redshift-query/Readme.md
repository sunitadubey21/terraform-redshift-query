### Register User

```
aws cognito-idp sign-up \
  --client-id ${CLIENT_ID} \
  --username ${USER_NAME} \
  --password ${PASSWORD} \ 
  --user-attributes Name=name,Value=${NAME} Name=email,Value=${EMAIL}
```

```
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id ${POOL_ID} \
  --username ${USER_NAME}
```


### Get Token

```
aws cognito-idp initiate-auth \
 --client-id ${CLIENT_ID} \
 --auth-flow USER_PASSWORD_AUTH \
 --auth-parameters USERNAME=${USER_NAME},PASSWORD=${PASSWORD} \
 --query 'AuthenticationResult.IdToken' \
 --output text
```

### Requirements related to Lambda and DynamoDB

1. The dynamodb document will include the (parameterizable) query to execute, the arn of the redshift to which it must connect and the name of the user with which the lambda will authenticate to redshift, it is important to consider that the index is made up of host + API path.

2. Regarding IAM, there must be at least one role for each redshift, We must consider that IAM authentication will work as cross account, this implies that the lambda must assume a role in the other account


