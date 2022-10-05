import os
import json
import base64
import functions_framework
import requests

TWILIO_TOKEN = os.environ['TWILIO_TOKEN']
ACCOUNT_SID = os.environ['ACCOUNT_SID']
FROM_NUMBER = os.environ['FROM_NUMBER'] # only one number for now

# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def send_message(cloud_event):
    """
        Package and emit a message from the completed work queue
    """
    # extract the message we want to send
    message_string = base64.b64decode(cloud_event.data["message"]["data"])
    message = json.loads(message_string)

    # construct a request to twilio
    TWILIO_SMS_URL = "https://api.twilio.com/2010-04-01/Accounts/%s/Messages.json"%ACCOUNT_SID
    payload = {
        "To": message["to_number"],
        "From": FROM_NUMBER,
        "Body": message["body"],
    }

    # send the message
    requests.post(TWILIO_SMS_URL, data=payload, auth=(ACCOUNT_SID, TWILIO_TOKEN))

    return ('', 200)
