import json

def lambda_handler(event, context):
    print(f"call plot")
    try:
        data = [
            {"id": 1, "name": "Alice", "age": 30},
            {"id": 2, "name": "Bob", "age": 40},
            {"id": 3, "name": "Charlie", "age": 50}
        ]
    
        # JSONレスポンスを作成
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "data": data,
                "message": "Plot created successfully",
            }),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "message": f"Failed to download file: {str(e)}"
            }),
        }
