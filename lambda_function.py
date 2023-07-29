import boto3
from PIL import Image, ImageDraw, ImageFont
import io
# import matplotlib.font_manager

# checking available font files
# print(matplotlib.font_manager.findSystemFonts(fontpaths=None, fontext='ttf'))

# Define the valid image extensions to process
valid_extensions = ('.jpg', '.jpeg', '.png')

# Create an S3 client
s3 = boto3.client('s3')

# Create a Lambda clients
lambda_client = boto3.client('lambda')

# Define the Lambda function to watermark the images


def lambda_handler(event, context):
    # Print event details
    print(event)

    # Get watermark S3 bucket
    watermarked_bucket_name = 'terra-watermarked-photos-bucket'

    # Get bucket name
    bucketName = event['Records'][0]['s3']['bucket']['name']
    objectKey = event['Records'][0]['s3']['object']['key']

    print("Original Bucket name without watermark::"+bucketName)
    print("Bucket object of Original Bucket::"+objectKey)

    for record in event['Records']:
        # Get the object key from the event record
        object_key = record['s3']['object']['key']

        print("Debug::"+object_key)

        # Check if the object has a valid image extension
        if not object_key.lower().endswith(valid_extensions):
            continue

        # Get the image file from S3
        response = s3.get_object(Bucket=bucketName, Key=object_key)
        image_content = response['Body'].read()

        # Add the watermark to the image
        watermark_text = "PKW"
        image = Image.open(io.BytesIO(image_content)).convert('RGB')
        draw = ImageDraw.Draw(image)
        font = ImageFont.truetype('DejaVuSansCondensed.ttf', size=80)

        # Set the watermark color, position and opacity
        width, height = image.size
        text_width, text_height = draw.textsize(watermark_text, font)
        x = width / 2 - text_width / 2
        y = height / 2 - text_height / 2
        opacity = 60
        fill_color = (162, 205, 210, opacity)
        draw.text((x, y), watermark_text, font=font,
                  fill=fill_color)

        # Save the watermarked image to a buffer
        watermarked_image_content = io.BytesIO()
        image.save(watermarked_image_content, format='JPEG')

        # Put the watermarked image in the watermarked bucket
        s3.put_object(Bucket=watermarked_bucket_name, Key=object_key,
                      Body=watermarked_image_content.getvalue(), ContentType='image/jpeg')

    return {'status_code': 200}

# # Configure the S3 bucket event to trigger the Lambda function
# s3.put_bucket_notification_configuration(
#     Bucket=original_bucket_name,
#     NotificationConfiguration={
#         'LambdaFunctionConfigurations': [
#             {
#                 'LambdaFunctionArn': 'arn:aws:lambda:us-west-2:123456789012:function:watermark_photos',
#                 'Events': ['s3:ObjectCreated:*']
#             }
#         ]
#     }
# )
