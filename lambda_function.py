import json
import boto3
import os
from datetime import datetime
import logging

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB client
dynamodb = boto3.resource('dynamodb')
table_name = os.environ.get('DYNAMODB_TABLE_NAME', 'password-generator-counter')
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    """
    Lambda function to handle password counter operations
    """
    try:
        # Parse the HTTP method and path
        http_method = event.get('httpMethod', 'GET')
        path = event.get('path', '/')
        
        # Set CORS headers
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
        }
        
        # Handle preflight OPTIONS request
        if http_method == 'OPTIONS':
            return {
                'statusCode': 200,
                'headers': headers,
                'body': json.dumps({'message': 'OK'})
            }
        
        # Route based on HTTP method
        if http_method == 'GET':
            return get_counter(headers)
        elif http_method == 'POST':
            return update_counter(event, headers)
        else:
            return {
                'statusCode': 405,
                'headers': headers,
                'body': json.dumps({'error': 'Method not allowed'})
            }
            
    except Exception as e:
        logger.error(f"Error in lambda_handler: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'GET,POST,OPTIONS'
            },
            'body': json.dumps({'error': 'Internal server error'})
        }

def get_counter(headers):
    """
    Get the current password counter from DynamoDB
    """
    try:
        # Get the counter item from DynamoDB
        response = table.get_item(
            Key={
                'id': 'password_counter'
            }
        )
        
        # If item doesn't exist, create it with count 0
        if 'Item' not in response:
            table.put_item(
                Item={
                    'id': 'password_counter',
                    'count': 0,
                    'last_updated': datetime.utcnow().isoformat()
                }
            )
            count = 0
        else:
            count = response['Item'].get('count', 0)
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'count': count,
                'message': 'Counter retrieved successfully'
            })
        }
        
    except Exception as e:
        logger.error(f"Error getting counter: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': 'Failed to retrieve counter'})
        }

def update_counter(event, headers):
    """
    Update the password counter in DynamoDB
    """
    try:
        # Parse the request body
        body = json.loads(event.get('body', '{}'))
        new_count = body.get('count', 0)
        
        # Validate the count
        if not isinstance(new_count, int) or new_count < 0:
            return {
                'statusCode': 400,
                'headers': headers,
                'body': json.dumps({'error': 'Invalid count value'})
            }
        
        # Update the counter in DynamoDB
        table.put_item(
            Item={
                'id': 'password_counter',
                'count': new_count,
                'last_updated': datetime.utcnow().isoformat()
            }
        )
        
        return {
            'statusCode': 200,
            'headers': headers,
            'body': json.dumps({
                'count': new_count,
                'message': 'Counter updated successfully'
            })
        }
        
    except json.JSONDecodeError:
        return {
            'statusCode': 400,
            'headers': headers,
            'body': json.dumps({'error': 'Invalid JSON in request body'})
        }
    except Exception as e:
        logger.error(f"Error updating counter: {str(e)}")
        return {
            'statusCode': 500,
            'headers': headers,
            'body': json.dumps({'error': 'Failed to update counter'})
        } 