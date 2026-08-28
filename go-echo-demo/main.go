package main

import (
	"context"
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

	e.GET("/demo/sum", func(c *echo.Context) error {
		// Bind request
		req := new(SumRequest)
		if err := c.Bind(req); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}

		// Blocking operation
		time.Sleep(100 * time.Millisecond)
		sum := req.Value1 + req.Value2

		// Return response
		return c.JSON(http.StatusOK, SumResponse{Result: sum})
	})

	ctx, cancel := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer cancel()

	sc := echo.StartConfig{
		Address:         ":8080",
		GracefulTimeout: 10 * time.Second,
		BeforeServeFunc: func(s *http.Server) error {
			timeTaken := fmt.Sprintf("%.3fms", float64(time.Since(startTime).Nanoseconds())/1e6)
			e.Logger.Info("started application", "pid", os.Getpid(), "address", s.Addr, "timeTaken", timeTaken)
			return nil
		},
	}

	e.Logger.Info("starting application", "pid", os.Getpid(), "address", sc.Address)

	if err := sc.Start(ctx, e); err != nil && !errors.Is(err, http.ErrServerClosed) {
		e.Logger.Error("failed to start server", "error", err)
	}
}

type SumRequest struct {
	Value1 int64 `query:"value1"`
	Value2 int64 `query:"value2"`
}

type SumResponse struct {
	Result int64 `json:"result"`
}
