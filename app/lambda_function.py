import json
import os
import boto3
from processa_preco_medio import calcular_medias_por_ano_e_marca

def lambda_handler(event, context):
    try:
        # Get bucket and key from S3 event
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = event['Records'][0]['s3']['object']['key']
        
        # Download CSV file
        s3 = boto3.client('s3')
        local_file = f"/tmp/{os.path.basename(key)}"
        s3.download_file(bucket, key, local_file)
        
        # Process file
        medias = calcular_medias_por_ano_e_marca(local_file)
        
        # Save and upload result
        output_file = local_file.replace('.csv', '.json')
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(medias, f, ensure_ascii=False, indent=2)
        
        output_bucket = os.environ.get('OUTPUT_BUCKET', bucket.replace('-input-', '-output-'))
        output_key = key.replace('.csv', '.json')
        s3.upload_file(output_file, output_bucket, output_key)
        
        return {'statusCode': 200, 'body': 'File processed successfully'}
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': str(e)}