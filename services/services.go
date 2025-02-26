package services

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
)

var (
	ServiceList []Service
	FallbackMap map[string]string
)

const (
	baseRepoLink = "https://git.sr.ht/~benbusby/farside/blob/main/"

	noCFServicesJSON = "services.json"
	fullServicesJSON = "services-full.json"
)

type Service struct {
	Type      string   `json:"type"`
	TestURL   string   `json:"test_url,omitempty"`
	Fallback  string   `json:"fallback,omimtempty"`
	Instances []string `json:"instances"`
}

func ingestServicesList(servicesBytes []byte) error {
	err := json.Unmarshal(servicesBytes, &ServiceList)
	return err
}

func GetServicesFileName() string {
	cloudflareEnabled := false

	cfEnabledVar := os.Getenv("FARSIDE_CF_ENABLED")
	if len(cfEnabledVar) > 0 && cfEnabledVar == "1" {
		cloudflareEnabled = true
	}

	serviceJSON := noCFServicesJSON
	if cloudflareEnabled {
		serviceJSON = fullServicesJSON
	}

	return serviceJSON
}

func FetchServicesFile(serviceJSON string) ([]byte, error) {
	resp, err := http.Get(baseRepoLink + serviceJSON)
	if err != nil {
		return nil, err
	}

	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	err = os.WriteFile(serviceJSON, bodyBytes, 0666)
	if err != nil {
		return nil, err
	}

	return bodyBytes, nil
}

func InitializeServices() error {
	serviceJSON := GetServicesFileName()
	fileBytes, err := os.ReadFile(serviceJSON)
	if err != nil {
		fileBytes, err = FetchServicesFile(serviceJSON)
		if err != nil {
			return err
		}
	}

	err = ingestServicesList(fileBytes)
	if err != nil {
		return err
	}

	FallbackMap = make(map[string]string)
	for _, serviceElement := range ServiceList {
		FallbackMap[serviceElement.Type] = serviceElement.Fallback
	}

	return nil
}
