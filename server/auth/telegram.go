package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"
)

var phoneNumber = regexp.MustCompile(`^\+[1-9][0-9]{6,14}$`)

func normalizedPhone(input string) string {
	return strings.NewReplacer(" ", "", "(", "", ")", "", "-", "").Replace(strings.TrimSpace(input))
}

var errDelivery = errors.New("verification delivery unavailable")

// Birka generates and verifies the code. The Gateway token stays on the server.
func telegramSender(token string, transport http.RoundTripper) func(context.Context, string, string) error {
	client := &http.Client{Timeout: 10 * time.Second, Transport: transport, CheckRedirect: func(*http.Request, []*http.Request) error { return http.ErrUseLastResponse }}
	return func(ctx context.Context, phone, code string) error {
		payload, err := json.Marshal(struct {
			Phone string `json:"phone_number"`
			Code  string `json:"code"`
			TTL   int    `json:"ttl"`
		}{phone, code, int(codeAge.Seconds())})
		if err != nil {
			return err
		}
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, "https://gatewayapi.telegram.org/sendVerificationMessage", bytes.NewReader(payload))
		if err != nil {
			return errDelivery
		}
		req.Header.Set("Authorization", "Bearer "+token)
		req.Header.Set("Content-Type", "application/json")
		r, err := client.Do(req)
		if err != nil {
			return errDelivery
		}
		defer r.Body.Close()
		if r.StatusCode == 429 {
			return errLimit
		}
		if r.StatusCode != 200 {
			return errDelivery
		}
		var result struct {
			OK     bool
			Result struct {
				ID string `json:"request_id"`
			}
		}
		if json.NewDecoder(io.LimitReader(r.Body, 64<<10)).Decode(&result) != nil || !result.OK || result.Result.ID == "" {
			return errDelivery
		}
		return nil
	}
}
