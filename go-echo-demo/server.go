package main

import (
	"github.com/labstack/echo/v4"
	"net/http"
	"time"
)

func main() {
	e := echo.New()

	e.GET("/demo/sum", func(c echo.Context) (err error) {
		// Bind request
		req := new(SumRequest)
		if err = c.Bind(req); err != nil {
			return echo.NewHTTPError(http.StatusBadRequest, err.Error())
		}

		// Blocking operation
		time.Sleep(100 * time.Millisecond)
		sum := req.Value1 + req.Value2

		// Return response
		return c.JSON(http.StatusOK, SumResponse{Result: sum})
	})

	e.Logger.Fatal(e.Start(":8080"))
}

type SumRequest struct {
	Value1 int64 `query:"value1"`
	Value2 int64 `query:"value2"`
}

type SumResponse struct {
	Result int64 `json:"result"`
}
