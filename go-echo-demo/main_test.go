package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/labstack/echo/v5"
)

func setupTestServer() *echo.Echo {
	e := echo.New()
	benchmarkGroup := e.Group("/benchmark")

	benchmarkGroup.GET("/io-bound", func(c *echo.Context) error {
		req := IoBenchmarkRequest{DelayMs: 100}
		if err := c.Bind(&req); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}
		if req.DelayMs > 0 {
			time.Sleep(time.Duration(req.DelayMs) * time.Millisecond)
		}
		sum := req.Value1 + req.Value2
		return c.JSON(http.StatusOK, IoBenchmarkResponse{
			Result:  sum,
			DelayMs: req.DelayMs,
		})
	})

	benchmarkGroup.GET("/cpu-bound", func(c *echo.Context) error {
		req := CpuBenchmarkRequest{Iterations: 10000}
		if err := c.Bind(&req); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}
		data := []byte("load-test-benchmark-seed-data")
		for i := 0; i < req.Iterations; i++ {
			h := sha256.Sum256(data)
			data = h[:]
		}
		return c.JSON(http.StatusOK, CpuBenchmarkResponse{
			Hash:       hex.EncodeToString(data),
			Iterations: req.Iterations,
		})
	})

	return e
}

func TestIoBoundEndpoint(t *testing.T) {
	e := setupTestServer()

	req := httptest.NewRequest(http.MethodGet, "/benchmark/io-bound?value1=3&value2=5&delay=0", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}

	var resp IoBenchmarkResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal JSON: %v", err)
	}

	if resp.Result != 8 {
		t.Errorf("expected result 8, got %d", resp.Result)
	}
}

func TestCpuBoundEndpoint(t *testing.T) {
	e := setupTestServer()

	req := httptest.NewRequest(http.MethodGet, "/benchmark/cpu-bound?iterations=100", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", rec.Code)
	}

	var resp CpuBenchmarkResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &resp); err != nil {
		t.Fatalf("failed to unmarshal JSON: %v", err)
	}

	if len(resp.Hash) != 64 {
		t.Errorf("expected 64-character hex hash, got %s", resp.Hash)
	}
	if resp.Iterations != 100 {
		t.Errorf("expected iterations 100, got %d", resp.Iterations)
	}
}
