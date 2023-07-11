import collections
import json
import logging
import os
import time

import boto3
from botocore.exceptions import ClientError

__version__ = "2.0"
logger = logging.getLogger(__name__)


def get_env_var(name):
    return os.environ[name] if name in os.environ else None


REDSHIFT_CLUSTER = get_env_var('REDSHIFT_CLUSTER')
REDSHIFT_DATABASE = get_env_var('REDSHIFT_DATABASE')
REDSHIFT_DATABASE_USER = get_env_var('REDSHIFT_DATABASE_USER')
DYNAMODB_TABLE = get_env_var('DYNAMODB_TABLE')
ASSUME_ROLE_ARN = get_env_var('ASSUME_ROLE_ARN')


def query_dynamo_db(_full_api_url):
    dynamodb_resource = boto3.resource('dynamodb')
    dynamodb_table = dynamodb_resource.Table(DYNAMODB_TABLE)

    try:
        response = dynamodb_table.get_item(
            Key={'full_api_url': _full_api_url},
            AttributesToGet=['redshift_query', 'redshift_user']
        )
    except ClientError as err:
        logger.error(
            "Couldn't get redshift query with url %s from table %s. Here's why: %s: %s",
            _full_api_url,
            DYNAMODB_TABLE,
            err.response['Error']['Code'],
            err.response['Error']['Message']
        )
        raise err
    else:
        item = response.get('Item')
        if item:
            return item.get('redshift_query'), item.get('redshift_user')
        else:
            raise Exception("Item doesn't exists")


def query_redshift(_request_id, queries, user, query_string_parameters=None, db_cluster=None, db_workgroup=None):
    sts_client = boto3.client('sts')
    assumed_role_object = sts_client.assume_role(
        RoleArn=ASSUME_ROLE_ARN,
        RoleSessionName=_request_id
    )

    credentials = assumed_role_object['Credentials']
    redshift_data_client = boto3.client(
        'redshift-data',
        aws_access_key_id=credentials['AccessKeyId'],
        aws_secret_access_key=credentials['SecretAccessKey'],
        aws_session_token=credentials['SessionToken'],
    )

    try:
        if db_cluster is not None:
            logger.info("Connecting to cluster: " + db_cluster)
            sql_query = queries
            if query_string_parameters is not None and len(query_string_parameters) != 0:
                sql_query += ' ' + ' AND '.join(
                    [f'{key} = \'{query_string_parameters[key]}\'' for key in query_string_parameters])
            logger.info("SQL query..." + sql_query)
            response = redshift_data_client.execute_statement(
                ClusterIdentifier=db_cluster,
                Database=REDSHIFT_DATABASE,
                DbUser=user,  # REDSHIFT_DATABASE_USER,
                Sql=sql_query,
                StatementName="QMRNotificationUtility-v%s" % __version__,
                WithEvent=False
            )
        elif db_workgroup is not None:
            logger.info("Connecting to workgroup: " + db_workgroup)
            response = redshift_data_client.execute_statement(
                WorkgroupName=db_workgroup,
                Database=REDSHIFT_DATABASE,
                Sql=queries,
                StatementName="QMRNotificationUtility-v%s" % __version__,
                WithEvent=False
            )
        else:
            logger.warning("Neither DB cluster or workgroup specified")
            return None

        response_id = response['Id']
        logger.info("Query response id: " + str(response_id))

        statement_finished = False
        response_data = None

        while statement_finished is False:
            # Sleep and poll for 5 seconds
            logger.info("Sleeping...")
            time.sleep(1)

            response_data = redshift_data_client.describe_statement(Id=response_id)

            if response_data['Status'] == 'FINISHED':
                statement_finished = True
            elif response_data['Status'] == 'FAILED':
                logger.error(response_data)
                statement_finished = True
            else:
                logger.warning(response_data['Status'])

        # Now get the results
        result_rows = response_data["ResultRows"]
        has_results = response_data["HasResultSet"]

        results = []

        # For response schema https://docs.aws.amazon.com/redshift-data/latest/APIReference/API_GetStatementResult.html
        # TODO: Haven't implemented cursor with NextToken
        if result_rows > 0 and has_results:
            # Return the data
            query_results = redshift_data_client.get_statement_result(
                Id=response_id
            )
            column_metadata = query_results['ColumnMetadata']
            query_column_labels = list(map(lambda x: x['label'], column_metadata))

            for row in query_results["Records"]:
                out_row = collections.OrderedDict()
                for idx, column in enumerate(row):
                    column_name = query_column_labels[idx]
                    if 'isNull' in column:
                        out_row[column_name] = None
                    else:
                        out_row[column_name] = next(iter(column.values()))
                results.append(out_row)

        return results
    except Exception as e:
        logger.error('Redshift Connection Failed: exception %s' % e)
        raise e


def lambda_handler(event, context):
    print(event)
    request_context = event['requestContext']
    full_api_url = '{}{}'.format(request_context['domainName'], request_context['resourcePath'])
    request_id = request_context['requestId']
    query_string_params = event['queryStringParameters']
    print(full_api_url)
    logger.info("full API URL.." + full_api_url)
    redshift_query, redshift_user = query_dynamo_db(full_api_url)
    results = query_redshift(request_id, redshift_query, redshift_user, query_string_params, db_cluster=REDSHIFT_CLUSTER)

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(results)
    }
