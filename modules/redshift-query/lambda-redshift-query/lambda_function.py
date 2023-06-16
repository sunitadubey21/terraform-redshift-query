import collections
import json
import logging
import os
import pprint
import sys
import time

import boto3
from boto3 import dynamodb
from botocore.exceptions import ClientError

__version__ = "2.0"
logger = logging.getLogger(__name__)


##################

def get_env_var(name):
    return os.environ[name] if name in os.environ else None


REDSHIFT_CLUSTER = get_env_var('REDSHIFT_CLUSTER')
REDSHIFT_DATABASE = get_env_var('REDSHIFT_DATABASE')
DYNAMODB_TABLE = get_env_var('DYNAMODB_TABLE')
ASSUME_ROLE_ARN = get_env_var('ASSUME_ROLE_ARN')


def dynamo_db_query(_full_api_url):
    dynamodb_resource = boto3.resource('dynamodb')
    dynamodb_table = dynamodb_resource.Table(DYNAMODB_TABLE)

    try:
        response = dynamodb_table.get_item(
            Key={'full_api_url': _full_api_url},
            AttributesToGet=['redshift_query']
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
        return response['Item']['redshift_query']


# Use Data API to obtain credentials
def execute_api_sql(_request_id, queries, db_cluster=None, db_workgroup=None, db_user=None):
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

    # New process - use Data API with temporary credentials
    try:
        if db_cluster is not None:
            logger.info("Connecting to cluster: " + db_cluster)
            response = redshift_data_client.execute_statement(
                ClusterIdentifier=db_cluster,
                Database=REDSHIFT_DATABASE,
                DbUser=db_user,
                Sql=queries,
                StatementName="QMRNotificationUtility-v%s" % __version__,
                WithEvent=False
            )
        elif db_workgroup is not None:
            logger.info("Connecting to workgroup: " + db_workgroup)
            response = redshift_data_client.execute_statement(
                WorkgroupName=db_workgroup,  # Required for serverless
                Database=REDSHIFT_DATABASE,
                Sql=queries,
                StatementName="QMRNotificationUtility-v%s" % __version__,
                WithEvent=False
            )
        else:
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

            pprint.pprint(response_data)

            if response_data['Status'] == 'FINISHED':
                statement_finished = True
            elif response_data['Status'] == 'FAILED':
                # logger.info(json.dumps(response_data, indent=4,default=str))
                logger.error(response_data)
                statement_finished = True
            else:
                # logger.info("Statement status: " + response_data['Status'])
                logger.warning(response_data['Status'])

        # Now get the results
        result_rows = response_data["ResultRows"]
        has_results = response_data["HasResultSet"]

        if result_rows > 0 and has_results == True:
            # Return the data
            query_results = redshift_data_client.get_statement_result(
                Id=response_id
            )
            return query_results["Records"]

        else:
            return None
    except Exception as e:
        logger.error('Redshift Connection Failed: exception %s' % sys.exc_info()[1])
        raise e


def query_redshift(_request_id, _sql_query):
    try:
        # Use Data API function to connect to Redshift
        logger.info("Connecting to Redshift")
        result_rows = execute_api_sql(_request_id, _sql_query, db_cluster=REDSHIFT_CLUSTER)

        objects_list = []

        if result_rows is None or len(result_rows) == 0:
            logger.debug("No results from QMR query")
            return objects_list

        # Get the results from the returned dictionary
        # TODO: Update rows
        for row in result_rows:
            logger.info(row)
            userid, query, service_class, rule, action, recordtime = row
            d = collections.OrderedDict()
            d['clusterid'] = REDSHIFT_CLUSTER
            d['database'] = REDSHIFT_DATABASE
            d['userid'] = userid
            d['query'] = query
            d['service_class'] = service_class
            d['rule'] = rule
            d['action'] = action
            d['recordtime'] = recordtime  # --.isoformat()

            objects_list.append(d)

        logger.debug('Completed Successfully')
        return objects_list
    except Exception as e:
        logger.error('Query Failed: exception %s' % e)
        raise e


def lambda_handler(event, context):
    request_context = event['requestContext']
    full_api_url = '{}{}'.format(request_context['domainName'], request_context['resourcePath'])
    request_id = request_context['requestId']

    redshift_query = dynamo_db_query(full_api_url)
    # objects_list = query_redshift(request_id, redshift_query)

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            'query': redshift_query
        })
    }
