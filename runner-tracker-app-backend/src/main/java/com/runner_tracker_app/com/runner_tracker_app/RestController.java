package com.runner_tracker_app.com.runner_tracker_app;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.dynamodb.model.AttributeValue;
import software.amazon.awssdk.services.dynamodb.model.ScanRequest;
import software.amazon.awssdk.services.dynamodb.model.ScanResponse;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@org.springframework.web.bind.annotation.RestController
@RequestMapping("/api/distance")
public class RestController{
    @GetMapping
    public ResponseEntity<List<DataEntryPoint>> returnRandomString() {
        String tableName = "DistanceRan";
        String dateKeyName = "Date";
        String distanceKeyName = "Distance";
        ArrayList<DataEntryPoint> dataEntryPoints = new ArrayList<>();

        // for (int i = 0; i < 10; i++) {
        //     dataEntryPoints.add(DataEntryPoint.builder().Date(Integer.toString(i)).Distance(Integer.toString(i*6-i)).build());
        // }
        System.out.println("I have been called");
        // return ResponseEntity.ok(dataEntryPoints);

       DynamoDbClient client = DynamoDbClient.builder()
               .region(Region.EU_WEST_2)
               .build();

       ScanRequest scanRequest = ScanRequest.builder()
               .tableName(tableName)
               .attributesToGet(dateKeyName,distanceKeyName)
               .build();

       ScanResponse items = client.scan(scanRequest);

      for (Map<String,AttributeValue> val : items.items()) {
          dataEntryPoints.add(DataEntryPoint.builder()
                  .Date(val.get(dateKeyName).s())
                  .Distance(val.get(distanceKeyName).s())
                  .build());
      }

      return ResponseEntity.ok(dataEntryPoints);
    }
}
