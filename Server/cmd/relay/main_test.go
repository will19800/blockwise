package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealth(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	response := httptest.NewRecorder()

	newHandler().ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}

	const expectedBody = "{\"status\":\"ok\"}\n"
	if response.Body.String() != expectedBody {
		t.Fatalf("body = %q, want %q", response.Body.String(), expectedBody)
	}

	if contentType := response.Header().Get("Content-Type"); contentType != "application/json" {
		t.Fatalf("Content-Type = %q, want application/json", contentType)
	}
}

func TestHealthRejectsOtherMethods(t *testing.T) {
	t.Parallel()

	request := httptest.NewRequest(http.MethodPost, "/healthz", nil)
	response := httptest.NewRecorder()

	newHandler().ServeHTTP(response, request)

	if response.Code != http.StatusMethodNotAllowed {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusMethodNotAllowed)
	}
}

func TestAddressFromEnvironment(t *testing.T) {
	t.Setenv("BLOCKWISE_RELAY_ADDR", "127.0.0.1:9090")

	if address := addressFromEnvironment(); address != "127.0.0.1:9090" {
		t.Fatalf("address = %q, want 127.0.0.1:9090", address)
	}
}
