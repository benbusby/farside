package server

import (
	_ "embed"
	"encoding/json"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/benbusby/farside/db"
	"github.com/benbusby/farside/services"
)

//go:embed index.html
var indexHTML string

//go:embed route.html
var routeHTML string

type indexData struct {
	LastUpdated time.Time
	ServiceList []services.Service
}

type routeData struct {
	InstanceURL string
}

func home(w http.ResponseWriter, r *http.Request) {
	serviceList := db.GetServiceList()
	data := indexData{
		LastUpdated: db.LastUpdate,
		ServiceList: serviceList,
	}

	tmpl, err := template.New("").Parse(indexHTML)
	if err != nil {
		log.Println(err)
		http.Error(w, "Error parsing template", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/html")

	err = tmpl.Execute(w, data)
	if err != nil {
		log.Println(err)
		http.Error(w, "Error executing template", http.StatusInternalServerError)
	}
}

func state(w http.ResponseWriter, r *http.Request) {
	storedServices := db.GetServiceList()
	jsonData, _ := json.Marshal(storedServices)
	w.Header().Set("Content-Type", "application/json")
	_, _ = w.Write(jsonData)
}

func baseRouting(w http.ResponseWriter, r *http.Request) {
	routing(w, r, false)
}

func jsRouting(w http.ResponseWriter, r *http.Request) {
	r.URL.Path = strings.Replace(r.URL.Path, "/_", "", 1)
	routing(w, r, true)
}

func routing(w http.ResponseWriter, r *http.Request, jsEnabled bool) {
	value := r.PathValue("routing")
	if len(value) == 0 {
		value = r.URL.Path
	}

	url, _ := url.Parse(value)
	path := strings.TrimPrefix(url.Path, "/")
	segments := strings.Split(path, "/")

	target, err := services.MatchRequest(segments[0])
	if err != nil {
		log.Printf("Error during match request: %v\n", err)
		http.Error(w, "No routing found for "+target, http.StatusBadRequest)
		return
	}

	var servicePath string
	if target == "breezewiki" {
		// Breezewiki requires the subdomain of the instance to be
		// preserved for correct routing
		splitDomain := strings.Split(path, ".")
		if len(splitDomain) > 2 {
			servicePath = strings.Split(path, ".")[0]
		}
	}

	instance, err := db.GetInstance(target, servicePath)
	if err != nil {
		log.Printf("Error fetching instance from db: %v\n", err)
		http.Error(
			w,
			"Error fetching instance for "+target,
			http.StatusInternalServerError)
		return
	}

	if len(segments) > 1 {
		targetPath := strings.Join(segments[1:], "/")
		instance = instance + "/" + targetPath
	}

	w.Header().Set("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
	w.Header().Set("Pragma", "no-cache")
	w.Header().Set("Expires", "0")

	if jsEnabled {
		data := routeData{
			InstanceURL: instance,
		}
		tmpl, _ := template.New("").Parse(routeHTML)
		w.Header().Set("Content-Type", "text/html")
		_ = tmpl.Execute(w, data)
	} else {
		http.Redirect(w, r, instance, http.StatusFound)
	}
}

func RunServer() {
	mux := http.NewServeMux()
	mux.HandleFunc("/{$}", home)
	mux.HandleFunc("/state/{$}", state)
	mux.HandleFunc("/{routing...}", baseRouting)
	mux.HandleFunc("/_/{routing...}", jsRouting)

	port := os.Getenv("FARSIDE_PORT")
	if len(port) == 0 {
		port = "4001"
	}

	log.Println("Starting server on http://localhost:" + port)

	err := http.ListenAndServe(":"+port, mux)
	if err != nil {
		log.Fatal(err)
	}
}
