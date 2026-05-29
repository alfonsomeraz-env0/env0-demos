import json
import os
import uuid
import boto3
from datetime import datetime, timezone

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    http = event.get("requestContext", {}).get("http", {})
    method = http.get("method", "")
    path = event.get("rawPath", "")
    path_params = event.get("pathParameters") or {}

    if method == "GET" and path == "/items":
        return get_items()
    elif method == "GET" and path_params.get("id"):
        return get_item(path_params["id"])
    elif method == "POST" and path == "/items":
        body = json.loads(event.get("body") or "{}")
        return create_item(body)
    elif method == "DELETE" and path_params.get("id"):
        return delete_item(path_params["id"])
    else:
        return _response(404, {"error": "Not found", "path": path, "method": method})


def get_items():
    result = table.scan()
    items = sorted(result.get("Items", []), key=lambda x: x.get("created_at", ""))
    return _response(200, {"items": items, "count": len(items)})


def get_item(item_id):
    result = table.get_item(Key={"id": item_id})
    item = result.get("Item")
    if not item:
        return _response(404, {"error": f"Item {item_id} not found"})
    return _response(200, item)


def create_item(body):
    if not body.get("name"):
        return _response(400, {"error": "name is required"})

    item = {
        "id": str(uuid.uuid4()),
        "name": body["name"],
        "status": body.get("status", "active"),
        "created_at": datetime.now(timezone.utc).isoformat(),
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
    }
    table.put_item(Item=item)
    return _response(201, item)


def delete_item(item_id):
    table.delete_item(Key={"id": item_id})
    return _response(200, {"deleted": item_id})


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=str),
    }
