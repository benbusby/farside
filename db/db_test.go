package db

import (
	"log"
	"os"
	"slices"
	"testing"
)

func TestMain(m *testing.M) {
	err := InitializeDB()
	if err != nil {
		log.Fatalln("Failed to initialize database")
	}

	exitCode := m.Run()

	_ = CloseDB()
	os.Exit(exitCode)
}

func TestDatabase(t *testing.T) {
	var (
		service = "test"
		siteA   = "a.com"
		siteB   = "b.com"
		siteC   = "c.com"
	)
	instances := []string{siteA, siteB, siteC}
	err := SetInstances(service, instances)
	if err != nil {
		t.Fatalf("Failed to set instances: %v\n", err)
	}

	dbInstances, err := GetAllInstances(service)
	if err != nil {
		t.Fatalf("Failed to retrieve instances: %v\n", err)
	}

	for _, instance := range instances {
		idx := slices.Index(dbInstances, instance)
		if idx < 0 {
			t.Fatalf("Failed to find instance in list")
		}
	}

	firstInstance, err := GetInstance(service)
	if err != nil {
		t.Fatalf("Failed to fetch single instance: %v\n", err)
	}

	secondInstance, err := GetInstance(service)
	if err != nil {
		t.Fatalf("Failed to fetch single instance (second): %v\n", err)
	} else if firstInstance == secondInstance {
		t.Fatalf("Same instance was selected twice")
	}

	_ = CloseDB()
}
