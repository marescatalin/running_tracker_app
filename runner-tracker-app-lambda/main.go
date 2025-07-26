package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
)

// Item represents the data structure for DynamoDB item
type Item struct {
	Date     string `json:"date"`
	Distance string `json:"distance"`
}

type TokenResponse struct {
	TokenType    string `json:"token_type"`
	AccessToken  string `json:"access_token"`
	ExpiresAt    int    `json:"expires_at"`
	ExpiresIn    int    `json:"expires_in"`
	RefreshToken string `json:"refresh_token"`
}

type GetAuthenticatedAthleteResponse struct {
	Id       int     `json:id`
	Username string  `json:"username"`
	Weight   float64 `json:"weight"`
}

// Define a struct for the totals
type Totals struct {
	Count         int     `json:"count"`
	Distance      float64 `json:"distance"`
	MovingTime    float64 `json:"moving_time"`
	ElapsedTime   float64 `json:"elapsed_time"`
	ElevationGain float64 `json:"elevation_gain"`
}

// Define a struct that matches the JSON response structure
type ActivityTotals struct {
	RecentRunTotals Totals `json:"recent_run_totals"`
	AllRunTotals    Totals `json:"all_run_totals"`
	YtdRunTotals    Totals `json:"ytd_run_totals"`
}

func handleRequest(ctx context.Context, event json.RawMessage) error {
	client := &http.Client{}

	// Step 1 Generate a new access token via oauth (hack)
	cid := "150355"

	cs := os.Getenv("CLIENT_SECRET")
	gt := "refresh_token"
	rt := os.Getenv("REFRESH_TOKEN")
	authUrl := fmt.Sprintf("https://www.strava.com/oauth/token?client_id=%s&client_secret=%s&grant_type=%s&refresh_token=%s", cid, cs, gt, rt)
	postMethod := "POST"

	authReq, err := http.NewRequest(postMethod, authUrl, nil)

	if err != nil {
		fmt.Println(err)
		return err
	}

	authRes, err := client.Do(authReq)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer authRes.Body.Close()

	// Use json.NewDecoder to decode the response body directly
	var tokenResponse TokenResponse
	if err := json.NewDecoder(authRes.Body).Decode(&tokenResponse); err != nil {
		fmt.Println("Error parsing JSON:", err)
		return err
	}

	// Step 2 Now we will get the logged in athlete

	athleteUrl := "https://www.strava.com/api/v3/athlete"
	getMethod := "GET"

	getAthleteReq, err := http.NewRequest(getMethod, athleteUrl, nil)

	if err != nil {
		fmt.Println(err)
		return err
	}
	getAthleteReq.Header.Add("Authorization", fmt.Sprintf("Bearer %s", tokenResponse.AccessToken))

	getAthleteRes, err := client.Do(getAthleteReq)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer getAthleteRes.Body.Close()

	// Use json.NewDecoder to decode the response body directly
	var getAuthenticatedAthleteResponse GetAuthenticatedAthleteResponse
	if err := json.NewDecoder(getAthleteRes.Body).Decode(&getAuthenticatedAthleteResponse); err != nil {
		fmt.Println("Error parsing JSON:", err)
		return err
	}

	// Print the parsed response
	fmt.Printf("id: %d\n", getAuthenticatedAthleteResponse.Id)
	fmt.Printf("Username: %s\n", getAuthenticatedAthleteResponse.Username)
	fmt.Printf("Weight: %.1f\n", getAuthenticatedAthleteResponse.Weight)

	// Step 3 Now we will get the stats of the athlete

	athletesUrl := fmt.Sprintf("https://www.strava.com/api/v3/athletes/%d/stats", getAuthenticatedAthleteResponse.Id)

	getAthletesStatsReq, err := http.NewRequest(getMethod, athletesUrl, nil)

	if err != nil {
		fmt.Println(err)
		return err
	}
	getAthletesStatsReq.Header.Add("Authorization", fmt.Sprintf("Bearer %s", tokenResponse.AccessToken))

	getAthletesStatsRes, err := client.Do(getAthletesStatsReq)
	if err != nil {
		fmt.Println(err)
		return err
	}
	defer getAthletesStatsRes.Body.Close()

	// Use json.NewDecoder to decode the response body directly
	var totals ActivityTotals
	if err := json.NewDecoder(getAthletesStatsRes.Body).Decode(&totals); err != nil {
		fmt.Println("Error parsing JSON:", err)
		return err
	}

	fmt.Printf("YTD Run Totals Distance: %.1f\n", totals.YtdRunTotals.Distance)

	// Write to dynamodb

	// Convert the Unix timestamp to a string
	epochTimeString := strconv.FormatInt(time.Now().Unix(), 10)
	distanceAsString := strconv.FormatFloat(totals.YtdRunTotals.Distance, 'f', 0, 64)

	// Create DynamoDB client

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("eu-west-2"))
	if err != nil {
		return err
	}
	svc := dynamodb.NewFromConfig(cfg)

	// Define the item to be put in the table
	input := &dynamodb.PutItemInput{
		TableName: aws.String("DistanceRan"),
		Item: map[string]types.AttributeValue{
			"Date":     &types.AttributeValueMemberS{Value: epochTimeString},
			"Distance": &types.AttributeValueMemberS{Value: distanceAsString},
		},
	}

	// Put the item into the DynamoDB table
	_, err = svc.PutItem(ctx, input)
	if err != nil {
		return err
	}

	fmt.Println("Successfully added item to DynamoDB")
	return nil
}

func main() {
	lambda.Start(handleRequest)
}
