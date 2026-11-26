package main

import (
	"crypto/tls"
	"encoding/base64"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"net/smtp"
	"net/url"
	"os"
	"strconv"
	"strings"
	"time"
)

type mailer struct {
	address, from, user, password string
	local                         bool
}

func (m mailer) send(email, code, language string) error {
	host, _, err := net.SplitHostPort(m.address)
	if err != nil {
		return err
	}
	conn, err := net.DialTimeout("tcp", m.address, 5*time.Second)
	if err != nil {
		return err
	}
	defer conn.Close()
	if err = conn.SetDeadline(time.Now().Add(12 * time.Second)); err != nil {
		return err
	}
	c, err := smtp.NewClient(conn, host)
	if err != nil {
		return err
	}
	defer c.Close()
	if !m.local {
		if err = c.StartTLS(&tls.Config{ServerName: host, MinVersion: tls.VersionTLS12}); err != nil {
			return err
		}
	}
	if m.user != "" {
		if err = c.Auth(smtp.PlainAuth("", m.user, m.password, host)); err != nil {
			return err
		}
	}
	if err = c.Mail(m.from); err != nil {
		return err
	}
	if err = c.Rcpt(email); err != nil {
		return err
	}
	data, err := c.Data()
	if err != nil {
		return err
	}
	message := "Your Birka sign-in code is " + code + ". It expires in 10 minutes."
	if language == "ru" {
		message = "Ваш код для входа в Birka: " + code + ". Он действует 10 минут."
	}
	// Use a 7-bit-safe MIME body, including on SMTP relays without 8BITMIME.
	encoded := base64.StdEncoding.EncodeToString([]byte(message))
	var lines []string
	for len(encoded) > 76 {
		lines = append(lines, encoded[:76])
		encoded = encoded[76:]
	}
	lines = append(lines, encoded)
	_, err = fmt.Fprintf(data, "From: Birka <%s>\r\nTo: %s\r\nDate: %s\r\nSubject: Birka sign-in code\r\nMIME-Version: 1.0\r\nContent-Type: text/plain; charset=UTF-8\r\nContent-Transfer-Encoding: base64\r\n\r\n%s\r\n", m.from, email, time.Now().Format(time.RFC1123Z), strings.Join(lines, "\r\n"))
	if err != nil {
		return err
	}
	return data.Close()
}

func loopback(host string) bool { return host == "localhost" || net.ParseIP(host).IsLoopback() }

func run() error {
	local := os.Getenv("BIRKA_AUTH_LOCAL") == "1"
	listen := os.Getenv("BIRKA_AUTH_LISTEN")
	if listen == "" {
		listen = "127.0.0.1:8787"
	}
	bind, _, err := net.SplitHostPort(listen)
	if err != nil || !loopback(bind) {
		return errors.New("listen on loopback; terminate public HTTPS at the reverse proxy")
	}
	origin := os.Getenv("BIRKA_WEB_ORIGIN")
	u, err := url.Parse(origin)
	if err != nil || u.Host == "" || u.User != nil || u.Scheme+"://"+u.Host != origin || !(u.Scheme == "https" || local && u.Scheme == "http" && loopback(u.Hostname())) {
		return errors.New("set BIRKA_WEB_ORIGIN to the exact HTTPS site origin (HTTP loopback for local testing)")
	}
	m := mailer{os.Getenv("BIRKA_SMTP_ADDR"), os.Getenv("BIRKA_MAIL_FROM"), os.Getenv("BIRKA_SMTP_USER"), os.Getenv("BIRKA_SMTP_PASSWORD"), local}
	app := application{origin: origin, local: local, proxy: os.Getenv("BIRKA_TRUST_LOCAL_PROXY") == "1", telegramLimit: 60}
	if token := os.Getenv("BIRKA_TELEGRAM_GATEWAY_TOKEN"); token != "" {
		app.telegram = telegramSender(token, nil)
		if limit := os.Getenv("BIRKA_TELEGRAM_HOURLY_LIMIT"); limit != "" {
			app.telegramLimit, err = strconv.Atoi(limit)
			if err != nil || app.telegramLimit < 1 {
				return errors.New("invalid BIRKA_TELEGRAM_HOURLY_LIMIT")
			}
		}
	}
	if m.address != "" || m.from != "" || m.user != "" || m.password != "" {
		host, _, err := net.SplitHostPort(m.address)
		if err != nil || !validEmail(m.from) || local && !loopback(host) || (m.user == "") != (m.password == "") {
			return errors.New("invalid SMTP configuration; local delivery requires a loopback SMTP receiver")
		}
		app.send = m.send
	}
	if app.send == nil && app.telegram == nil {
		return errors.New("configure SMTP or BIRKA_TELEGRAM_GATEWAY_TOKEN")
	}
	key, err := base64.StdEncoding.DecodeString(os.Getenv("BIRKA_AUTH_KEY"))
	if err != nil || len(key) != 32 {
		return errors.New("BIRKA_AUTH_KEY must contain a base64-encoded 32-byte secret")
	}
	path := os.Getenv("BIRKA_AUTH_DB")
	if strings.TrimSpace(path) == "" {
		return errors.New("set BIRKA_AUTH_DB to a file in a private data directory")
	}
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	db, err := openAccounts(path, key)
	if err != nil {
		return err
	}
	defer db.db.Close()
	if err = db.cleanup(); err != nil {
		return err
	}
	ticker := time.NewTicker(time.Hour)
	defer ticker.Stop()
	go func() {
		for range ticker.C {
			if db.cleanup() != nil {
				log.Print("auth database maintenance failed")
			}
		}
	}()
	app.accounts = db
	server := http.Server{Addr: listen, Handler: app.handler(), ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 10 * time.Second, WriteTimeout: 20 * time.Second, IdleTimeout: 60 * time.Second, MaxHeaderBytes: 16 << 10}
	log.Printf("Birka account service listening on %s", listen)
	return server.ListenAndServe()
}

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}
