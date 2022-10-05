import os
import json
import base64
import functions_framework
from google.cloud import pubsub_v1

# destination topic for outgoing messages
DESTINATION_TOPIC = os.environ["DESTINATION_TOPIC"] # "projects/$GCP_PROJECT/topics/messages_snd"

# the only number we will accept messages from
ADMIN_NUMBER = os.environ['ADMIN_NUMBER'] # "+1xxxxxxxx"

publisher = pubsub_v1.PublisherClient()

# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def work_published(cloud_event):
    """
        Proof of concept -
        just append "echo" to the message and send it back
        in practice this could be a pull subscription on a vm
    """
    message_string = base64.b64decode(cloud_event.data["message"]["data"])
    message = json.loads(message_string)

    if(message["from"] != ADMIN_NUMBER):
        return ('', 400)

    to_send = json.dumps({
        "to_number": message["from"],
        "body": "echo " + message["body"]
    }).encode('utf-8')

    publisher.publish(DESTINATION_TOPIC, to_send)

    return ('', 200)
