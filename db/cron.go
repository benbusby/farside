package db

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/benbusby/farside/services"
	"github.com/robfig/cron/v3"
)

const defaultPrimary = "https://farside.link/state"
const defaultCFPrimary = "https://cf.farside.link/state"

var LastUpdate time.Time

func InitCronTasks() {
	log.Println("Initializing cron tasks...")

	cronDisabled := os.Getenv("FARSIDE_CRON")
	if len(cronDisabled) == 0 || cronDisabled == "1" {
		c := cron.New()
		c.AddFunc("@every 10m", queryServiceInstances)
		c.AddFunc("@daily", updateServiceList)
		c.Start()
	}

	queryServiceInstances()
}

func updateServiceList() {
	fileName := services.GetServicesFileName()
	_, _ = services.FetchServicesFile(fileName)
	services.InitializeServices()
}

func queryServiceInstances() {
	log.Println("Starting instance queries...")

	isPrimary := os.Getenv("FARSIDE_PRIMARY")
	if len(isPrimary) == 0 || isPrimary != "1" {
		remoteServices, err := fetchInstancesFromPrimary()
		if err != nil {
			log.Println("Unable to fetch instances from primary", err)
		}

		for _, service := range remoteServices {
			SetInstances(service.Type, service.Instances)
		}

		return
	}

	for _, service := range services.ServiceList {
		fmt.Printf("===== %s =====\n", service.Type)
		var instances []string
		for _, instance := range service.Instances {
			testURL := strings.ReplaceAll(
				service.TestURL,
				"<%=query%>",
				"current+weather")
			available := queryServiceInstance(
				instance,
				testURL,
			)

			if available {
				instances = append(instances, instance)
			}
		}

		SetInstances(service.Type, instances)
	}

	LastUpdate = time.Now().UTC()
}

func fetchInstancesFromPrimary() ([]services.Service, error) {
	primaryURL := defaultPrimary
	useCF := os.Getenv("FARSIDE_CF_ENABLED")
	if len(useCF) > 0 && useCF == "1" {
		primaryURL = defaultCFPrimary
	}

	resp, err := http.Get(primaryURL)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var serviceList []services.Service
	err = json.Unmarshal(bodyBytes, &serviceList)
	return serviceList, err
}

func queryServiceInstance(instance, testURL string) bool {
	testMode := os.Getenv("FARSIDE_TEST")
	if len(testMode) > 0 && testMode == "1" {
		return true
	}

	ua := "Mozilla/5.0 (compatible; Farside/1.0.0; +https://farside.link)"
	url := instance + testURL

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		fmt.Println("    [ERRO] Failed to create new http request!", err)
		return false
	}

	req.Header.Set("User-Agent", ua)
	client := &http.Client{
		Timeout: 10 * time.Second,
	}
	resp, err := client.Do(req)

	if err != nil {
		fmt.Println("    [ERRO] Error fetching instance:", err)
		return false
	} else if resp.StatusCode != http.StatusOK {
		fmt.Printf("    [WARN] Received non-200 status for %s\n", url)
		return false
	} else {
		fmt.Printf("    [INFO] Received 200 status for %s\n", url)
	}

	return true
}
