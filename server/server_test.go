package server

import (
	"io"
	"log"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"

	"github.com/benbusby/farside/db"
)

const breezewikiTestSite = "https://breezewikitest.com"

func TestMain(m *testing.M) {
	err := db.InitializeDB()
	if err != nil {
		log.Fatalln("Failed to initialize database", err)
	}

	err = db.SetInstances("breezewiki", []string{breezewikiTestSite})
	if err != nil {
		log.Fatalln("Failed to set instances in db")
	}

	exitCode := m.Run()

	_ = db.CloseDB()
	os.Exit(exitCode)
}

func TestBaseRouting(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/fandom.com", nil)
	w := httptest.NewRecorder()

	baseRouting(w, req)

	res := w.Result()
	defer res.Body.Close()

	if res.StatusCode != http.StatusFound {
		t.Fatalf("Incorrect resp code (%d) in base routing", res.StatusCode)
	}

	expectedHost, _ := url.Parse(breezewikiTestSite)
	redirect, err := res.Location()
	if err != nil {
		t.Fatalf("Error retrieving direct from request: %v\n", err)
	} else if redirect.Host != expectedHost.Host {
		t.Fatalf("Incorrect redirect site -- expected: %s, actual: %s\n",
			expectedHost.Host,
			redirect.Host)
	}
}

func TestJSRouting(t *testing.T) {
	req := httptest.NewRequest(http.MethodGet, "/_/fandom.com", nil)
	w := httptest.NewRecorder()

	jsRouting(w, req)

	res := w.Result()
	defer res.Body.Close()

	if res.StatusCode != http.StatusOK {
		t.Fatalf("Incorrect resp code (%d) in base routing", res.StatusCode)
	}

	data, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatalf("Error reading response body: %v", err)
	}

	if !strings.Contains(string(data), breezewikiTestSite) {
		t.Fatalf("%s not found in response body (%s)", breezewikiTestSite, string(data))
	}
}
