package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/readpref"
)

const (
	dbConnectTimeout = 10 * time.Second
	mongoUri         = "mongodb://localhost:27017"
)

var (
	dbConn *mongo.Client
)

type model struct {
	ID   *primitive.ObjectID `bson:"_id,omitempty"`
	Live bool                `bson:"live"`
	Name string              `bson:"name"`
}

// .
func init() {

	opt := options.Client().
		SetAppName("test").
		ApplyURI(strings.Trim(strings.TrimSpace(mongoUri), "\n"))

	ctx, cancel := context.WithTimeout(context.Background(), dbConnectTimeout)
	defer cancel()

	fmt.Printf("Connecting to Mongo - %s\n", mongoUri)

	cli, err := mongo.Connect(ctx, opt)
	if err == nil {
		err = cli.Ping(ctx, readpref.Primary())
	}
	dbConn = cli
	coll := dbConn.Database("test").Collection("test")
	filter := bson.M{"live": true}
	res := coll.FindOne(ctx, filter)
	if res.Err() == nil {
		myModel := &model{}
		fmt.Printf("Connecting to Mongo - %s\n", res.Decode(myModel))
		fmt.Printf("Got name - %s\n", myModel.Name)

	}
}

func main() {
	r := mux.NewRouter()

	r.HandleFunc("/movies/{id}", getMovie).Methods("GET")
	fmt.Printf("Starting server at port 8010\n")
	log.Fatal(http.ListenAndServe(":8010", r))
}

func getMovie(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Content-Type", "appliaction/json")
	coll := dbConn.Database("test").Collection("test")
	filter := bson.M{"live": "true"}
	ctx, _ := context.WithTimeout(context.Background(), dbConnectTimeout)
	res := coll.FindOne(ctx, filter)
	myModel := &model{}
	fmt.Printf("Connecting to Mongo - %s\n", res.Decode(myModel))
}
