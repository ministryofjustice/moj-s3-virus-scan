# MoJ S3 Virus Scanner

A service to scan viruses automatically in S3 buckets.

This project is a service to provide automatic virus scanning for files in AWS
S3 buckets. The intended way to use this service is via an event attached to an
S3 bucket which calls a Lambda function, which in turn makes an HTTP request to
an instance of this application which then performs the scan and updates tags on
the file in S3 to indicate whether it has passed or failed the virus scan.

![Architecture Diagram](docs/architecture.png)

When a file is uploaded to an S3 bucket, a on-create event is triggered and runs
a lambda function which begins the virus scan on the newly created file. Once
the file is scanned it is tagged according to whether it passed the scan or not,
and these tags can be used to determine whether the file is safe to present to
the user or not.

This approach is an adaptation of the [bucket-antivirus-function approach
presented by Upside Travel]
(https://github.com/upsidetravel/bucket-antivirus-function), but allows the
scanning to be performed much more quickly (1s-2s vs 10s-20s). It is
particularly well suited to use with services that do direct uploads to S3, e.g.
using Dropzone, but works equally well with any service that needs virus scanning.

## Scanning Application

The scanning is preformed by the application in this repository which provides
the endpoint `/scan` to perform the scan. It takes the request params `bucket`
and `key` to specify which object to scan and requires permissions to access the
bucket provided.

## Lambda Function

To perform the scan a lambda function must be created as a bit of glue between
the S3 bucket and the scanning application. The steps to create this are:

### Creation

1. Go to the Lambda section in the Amazon console.
2. Create a new function:
   * Select "Author from scratch"
   * Give the function name e.g. moj-s3-virus-scan
   * Select a Python 3.x runtime
   * Select "Create new role from template"
   * Give the role a name, e.g. moj-s3-virus-scan-role
   * Select the policy template "Amazon S3 object read-only permissions"
3. Once created, select the function in the Designer to modify it.
4. Ensure in the Function Code section the option "Edit code inline" is selected.
5. Paste in the following code:
```
import urllib.parse as urlparse
import json

def lambda_handler(event, context):
    for record in event["Records"]:
        key    = record["s3"]["object"]["key"]
        bucket = record["s3"]["bucket"]["name"]
        url    = "https://moj-s3-virus-scan.dsd.io/scan?" + urlparse.urlencode({"key": key, "bucket": bucket})
        print("url: " + url)
        http.client.HTTPConnection.request("GET", url)
    return {
        'statusCode': 200,
        'body': json.dumps('OK')
    }
```
6. Increase the timeout on the "Basic Settings" to 30s.
7. Click on "Save" to save the function.

This function will need to be used with the `on-create` event to work, see the
section on configuring the S3 bucket.

## S3 Bucket

### Event Hook Configuration

To trigger the scan an event hook needs to be added to the S3 bucket where the
files-to-be-scanned are created. Navigate to the bucket in the S3 console and then:

1. Click on "Properties".
2. Click on "Events".
3. Click on "Add Notification".
4. Give the notification a name, e.g. `moj-s3-virus-scan`
5. Select "All object create events".
6. Select "Lambda Function" in the "Send To" option.
7. Select the lambda function that was created previously, e.g. `moj-s3-virus-scan`.

Note: any bucket that uses this service will need to give permissions to the
application to read object and to tag them.
