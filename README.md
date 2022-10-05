![A diagram illustrating the below description](https://github.com/cr0ax/gcp-message-passing/blob/main/static/diagram.png?raw=true)

#### Message passing architecture


Contains some example code for receiving, processing, and sending text messages from twilio, as well as a terraform module for getting it up and running.

* client sends/emits messages - (text, discord, ...)
* the _Receiver_ service processes them into a work queue
* the work queue is emptied by the _Worker_ service
* the _Sender_ service formats them into the preferred output format

This is a very flexible building block for small asynchronous workflows. Components can be combined, duplicated, or outright replaced as needed. For instance, twilio is not strictly necessary (I may replace this version with one using Discord in the near future), and the sample python code can be adapted or replaced.

#### Getting started

* sign-up for a twilio account, get a number and account credentials
* create your project in google cloud provider and authorize the necessary apis
* login by doing something like `gcloud auth application-default login`
* fill out `cloud/variables.tfvars` with the required variables
* run `terraform apply -var-file=variables.tfvars`
* Setup incoming messages webhook in twilio to the url of the receiver that was output in the previous step
