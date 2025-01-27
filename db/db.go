package db

import (
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math/rand"
	"os"
	"slices"
	"strings"
	"time"

	"github.com/benbusby/farside/services"
	"github.com/dgraph-io/badger/v4"
)

var (
	badgerDB     *badger.DB
	selectionMap map[string]string

	cachedServiceList []services.Service
	cacheUpdated      time.Time
)

func InitializeDB() error {
	var err error

	dbDir := os.Getenv("FARSIDE_DB_DIR")
	if len(dbDir) == 0 {
		dbDir = "./badger-db"
	}

	badgerDB, err = badger.Open(badger.DefaultOptions(dbDir))
	if err != nil {
		return err
	}

	return nil
}

func SetInstances(service string, instances []string) error {
	instancesBytes, err := json.Marshal(instances)
	if err != nil {
		return err
	}

	err = badgerDB.Update(func(txn *badger.Txn) error {
		err := txn.Set([]byte(service), instancesBytes)
		return err
	})

	if err != nil {
		return err
	}

	return nil
}

func GetInstance(service, path string) (string, error) {
	instances, err := GetAllInstances(service)
	if err != nil || len(instances) == 0 {
		if err != nil {
			log.Println("DB err:", err)
		}

		link, ok := services.FallbackMap[service]
		if !ok {
			return "", errors.New("invalid service")
		}

		return link, nil
	}

	previous, ok := selectionMap[service]
	if ok && len(instances) > 2 {
		instances = slices.DeleteFunc(instances, func(i string) bool {
			return i == previous
		})
	}

	index := rand.Intn(len(instances))
	value := instances[index]
	selectionMap[service] = value

	if len(path) > 0 {
		value = strings.TrimSuffix(value, "/")
		value = fmt.Sprintf("%s/%s", value, path)
	}

	return value, nil
}

func GetAllInstances(service string) ([]string, error) {
	var instances []string
	err := badgerDB.View(func(txn *badger.Txn) error {
		item, err := txn.Get([]byte(service))
		if err != nil {
			return err
		}

		err = item.Value(func(val []byte) error {
			err := json.Unmarshal(val, &instances)
			return err
		})

		return err
	})

	return instances, err
}

func GetServiceList() []services.Service {
	if cacheUpdated.Add(5 * time.Minute).After(time.Now().UTC()) {
		return cachedServiceList
	}

	canCache := true

	var serviceList []services.Service
	for _, service := range services.ServiceList {
		instances, err := GetAllInstances(service.Type)
		if err != nil {
			canCache = false
			instances = []string{service.Fallback}
		}

		storedService := services.Service{
			Type:      service.Type,
			Instances: instances,
		}

		serviceList = append(serviceList, storedService)
	}

	if canCache {
		cachedServiceList = serviceList
		cacheUpdated = time.Now().UTC()
	}

	return serviceList
}

func CloseDB() error {
	log.Println("Closing database...")
	err := badgerDB.Close()
	if err != nil {
		log.Println("Error closing database", err)
		return err
	}

	log.Println("Database closed!")
	return nil
}

func init() {
	selectionMap = make(map[string]string)
}
