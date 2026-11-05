import json

with open('swagger_spec.json', 'r', encoding='utf-8') as f:
    spec = json.load(f)

# Read ApiConstants
with open('lib/core/constants/api_constants.dart', 'r', encoding='utf-8') as f:
    api_constants = f.read()

# Read services
service_files = [
    'lib/core/services/auth_api_service.dart',
    'lib/core/services/customer_api_service.dart',
    'lib/core/services/catalog_api_service.dart',
    'lib/core/services/store_api_service.dart',
    'lib/core/services/cart_order_api_service.dart',
    'lib/core/services/review_api_service.dart',
    'lib/core/services/notification_api_service.dart',
    'lib/core/services/websocket_tracking_service.dart',
    'lib/core/services/razorpay_service.dart',
]

services_content = {}
for sf in service_files:
    with open(sf, 'r', encoding='utf-8') as f:
        services_content[sf] = f.read()

all_services_text = "\n".join(services_content.values())

print("==================== AUDIT REPORT ====================")
discrepancies = []

for path, methods in spec['paths'].items():
    for method, op in methods.items():
        summary = op.get('summary', '')
        params = op.get('parameters', [])
        req_body = op.get('requestBody', {})
        responses = op.get('responses', {})
        
        base_path = path.split('{')[0]
        matched_in_constants = base_path in api_constants
                
        if not matched_in_constants:
            discrepancies.append(f"MISSING IN ApiConstants: {method.upper()} {path} ({summary})")

        query_required = [p['name'] for p in params if p.get('in') == 'query' and p.get('required')]
        query_all = [p['name'] for p in params if p.get('in') == 'query']
        
        body_props = []
        body_required = []
        if req_body:
            schema = req_body.get('content', {}).get('application/json', {}).get('schema', {})
            body_props = list(schema.get('properties', {}).keys())
            body_required = schema.get('required', [])

        print(f"[{method.upper():6}] {path}")
        print(f"  Summary: {summary}")
        if query_required:
            print(f"  Required Query Params: {query_required}")
        if query_all:
            print(f"  All Query Params: {query_all}")
        if body_required:
            print(f"  Required Body Props: {body_required}")
        if body_props:
            print(f"  Optional/All Body Props: {body_props}")

print("\n--- Discrepancies in ApiConstants ---")
for d in discrepancies:
    print(d)
if not discrepancies:
    print("ALL 41 endpoints mapped in ApiConstants!")
