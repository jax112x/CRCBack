import json
import boto3
import botocore.exceptions

client = boto3.resource('dynamodb')
table = client.Table('WebVisitorCounter')

def lambda_handler(event, context):
    try:
        data = table.get_item(
            Key={
            'id' : 1
            }
        )
        
        visitor_count = data['Item']['count'] + 1
        
        table.update_item(
            Key={
            'id' : 1
            },
            UpdateExpression='SET #visitor_count = :visitor_count',
            ExpressionAttributeNames={'#visitor_count': 'count'},
            ExpressionAttributeValues={':visitor_count': visitor_count}
        )

        return {
            'statusCode': 200,
            'body': json.dumps({
                'count' :  f"{visitor_count}" 
            })
        }
    except botocore.exceptions.ClientError as error:
        print(error.response)
        return {
            'statusCode': 500,
            'body': json.dumps("error")
        }

