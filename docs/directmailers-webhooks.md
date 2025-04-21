WebhooksWebhooks are actioned for every step of an object lifecycle. To enable webhooks and configure POSTing URL please visit the account settings page in your Dashboard
Event	Description
NewPrintObject	Event is actioned when a new print object is posted.
PrintObjectInProduction	Event is actioned when a print object enters the production phase.
MailFoundInMailstream	Event is actioned when a print object is found in the postal carrier's mailsteam.
MailScanUpdate	Event is actioned every time a new tracking object is received from postal carrier.
MailOutForDelivery	Event is actioned when a print object is out for final delivery.
MailForwardNotice	Event is actioned when a print object is forwarded to a new address by the postal carrier.
MailReturnToSenderNotice	Event is actioned when a print object is returned to sender by the postal carrier.
Example webhook posting for MailScanUpdate event.Response 200 (application/json)          {
          "Event": "MailScanUpdate",
          "Object": "Letter",
          "Data": [
          {
          "PrintRecord": "5e10adc4-0282-44c4-9911-2942ff21136a",
          "Created": "2017-08-29T15:16:21+0000",
          "MailingDate": "2017-08-30T00:00:00+0000",
          "Canceled": false,
          "Status": "In Mailstream",
          "Description": "For Chris",
          "Medium": "Letter",
          "Size": "8.5x14",
          "Back": null,
          "VariablePayload": {
          "FirstName": "Chris",
          "AmountDue": "1024.56"
          },
          "PdfPages": 1,
          "PrintPages": 1,
          "Duplex": false,
          "BlankFirstPage": false,
          "Cost": 0.83,
          "DryRun": false,
          "RenderedPdf": "https://dmprint.s3-us-west-2.amazonaws.com/assets/289fd6cbf734859fb6db66ed7f39cc90b6b0f2736b0280257f1566736a25e9d6.pdf?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAINYRYKOPG5CLM5LA%2F20170830%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20170830T080007Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604800&X-Amz-Signature=328fc79c7b7a930f08d04a58a614ddc88a9a8ca0faa13a008c831437f8415e11",
          "BackThumbnailSmall": null,
          "BackThumbnailMedium": null,
          "BackThumbnailLarge": null,
          "PostalCarrier": "USPS",
          "PostalClass": "First Class",
          "Data": "6c328b3c-b2ca-4974-b2a6-7ad71dc4d26d",
          "To": {
          "Name": "Joe Smith",
          "AddressLine1": "128 North 64th St",
          "AddressLine2": "",
          "City": "Redmond",
          "State": "WA",
          "Zip": "98052"
          },
          "From": {
          "Name": "Jane Smith",
          "AddressLine1": "1024 East 128th St.",
          "AddressLine2": "",
          "City": "Phoenix",
          "State": "AZ",
          "Zip": "85085"
          },
          "Thumbnails": {
          "Small": "https://dmprint.s3-us-west-2.amazonaws.com/assets/59b4b20ddcc8fff7b70630c8d7eace531e782befd1daa873024fd5447c02977e.jpg?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAINYRYKOPG5CLM5LA%2F20170830%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20170830T080007Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604800&X-Amz-Signature=9be575c9a4d8d4c8fe809322cb29137323b6eb42d211ecc5e550afefda1af944",
          "Medium": "https://dmprint.s3-us-west-2.amazonaws.com/assets/29845c60a47fe0db6d25817983543384d3bc6c677c9826f067c0f9ff0e3f6273.jpg?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAINYRYKOPG5CLM5LA%2F20170830%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20170830T080007Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604800&X-Amz-Signature=991d23715b44dbe02ba6f1537596675434a5fec75230eb525024b9e5367b2351",
          "Large": "https://dmprint.s3-us-west-2.amazonaws.com/assets/46e01be96da5ae4f36f57a9cef45d77853b9eee20057d2ee34fa4e536afdfe4e.jpg?X-Amz-Content-Sha256=UNSIGNED-PAYLOAD&X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAINYRYKOPG5CLM5LA%2F20170830%2Fus-west-2%2Fs3%2Faws4_request&X-Amz-Date=20170830T080007Z&X-Amz-SignedHeaders=host&X-Amz-Expires=604800&X-Amz-Signature=e009ee62f34ff7005fe681baa17f28d47e1479b7190a95c7d88bd59afaeb9ffc"
          },
          "TrackingEvents": [
          {
          "ScanTime": "2017-08-30T06:31:42+0000",
          "TrackingOperationCode": "891",
          "Description": "Processing at USPS Origin Facility",
          "City": "Phoenix",
          "State": "AZ",
          "Latitude": 33.45,
          "Longitude": -111.97
          },
          {
          "ScanTime": "2017-08-30T03:07:28+0000",
          "TrackingOperationCode": "004",
          "Description": "Initial Processing at USPS Origin Facility",
          "City": "Phoenix",
          "State": "AZ",
          "Latitude": 33.45,
          "Longitude": -111.97
          }
          ],
          "EstimatedDeliveryDate": "2017-08-31T00:00:00+0000",
          "ActualDeliveryDate": null
          }
          ]
          }
