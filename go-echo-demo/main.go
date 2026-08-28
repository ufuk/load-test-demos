package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/labstack/echo/v5"
)

func main() {
	startTime := time.Now()

	e := echo.New()

	benchmarkGroup := e.Group("/benchmark")

	// I/O-bound endpoint (simulating DB/network latency)
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

	// CPU-bound endpoint (simulating CPU-heavy SHA-256 cryptographic hashing iterations)
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

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	address := ":8080"
	sc := echo.StartConfig{
		Address:         address,
		GracefulTimeout: 10 * time.Second,
		BeforeServeFunc: func(s *http.Server) error {
			timeTaken := fmt.Sprintf("%.3fms", float64(time.Since(startTime).Nanoseconds())/1e6)
			e.Logger.Info("started application", "pid", os.Getpid(), "address", address, "timeTaken", timeTaken)
			return nil
		},
	}

	e.Logger.Info("starting application", "pid", os.Getpid(), "address", address)

	if err := sc.Start(ctx, e); err != nil && !errors.Is(err, http.ErrServerClosed) {
		e.Logger.Error("failed to start server", "error", err)
	}
}

type IoBenchmarkRequest struct {
	Value1  int64 `query:"value1"`
	Value2  int64 `query:"value2"`
	DelayMs int64 `query:"delay"`
}

type IoBenchmarkResponse struct {
	Result  int64 `json:"result"`
	DelayMs int64 `json:"delayMs"`
}

type CpuBenchmarkRequest struct {
	Iterations int `query:"iterations"`
}

type CpuBenchmarkResponse struct {
	Hash       string `json:"hash"`
	Iterations int    `json:"iterations"`
}
