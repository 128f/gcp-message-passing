import os
import json
import functions_framework
from twilio.request_validator import RequestValidator
from google.cloud import pubsub_v1

TWILIO_TOKEN = os.environ['TWILIO_TOKEN']
PUB_SUB_TOPIC = os.environ['PUB_SUB_TOPIC']

validator = RequestValidator(TWILIO_TOKEN)
publisher = pubsub_v1.PublisherClient()

@functions_framework.http
def text_received(request: functions_framework.flask.Request):
    """
        Unpack and publish the received message to the topic
    """
    signature = request.headers.get('X-Twilio-Signature')
    url = request.url.replace("http", "https") # hack to get it to match

    if not validator.validate(url, request.form, signature):
       return ('', 400)

    message = json.dumps({
        "from": request.form["From"],
        "body": request.form["Body"]
    }).encode('utf-8')

    publisher.publish(PUB_SUB_TOPIC, message)
    return ('', 200)
