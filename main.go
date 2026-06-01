package main

import (
	"crypto/tls"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
)

const port = "3000"

var target = func() string {
	if t := os.Getenv("TARGET_URL"); t != "" {
		return t
	}
	return "https://api-copilot.x5.ru/aigw/v1/chat/completions"
}()

var client = &http.Client{
	Transport: &http.Transport{
		TLSClientConfig: &tls.Config{InsecureSkipVerify: true}, // корп. сертификат X5
	},
}

func handler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "POST, OPTIONS")
	w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, HTTP-Referer, X-Title")

	if r.Method == http.MethodOptions {
		w.WriteHeader(http.StatusOK)
		return
	}

	if r.Method != http.MethodPost {
		http.Error(w, `{"error":"method not allowed"}`, http.StatusMethodNotAllowed)
		return
	}

	req, err := http.NewRequest("POST", target, r.Body)
	if err != nil {
		http.Error(w, `{"error":"failed to create request"}`, http.StatusInternalServerError)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", r.Header.Get("Authorization"))

	resp, err := client.Do(req)
	if err != nil {
		log.Printf("Proxy error: %v", err)
		http.Error(w, fmt.Sprintf(`{"error":"%v"}`, err), http.StatusInternalServerError)
		return
	}
	defer resp.Body.Close()

	w.Header().Set("Content-Type", resp.Header.Get("Content-Type"))
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("X-Accel-Buffering", "no")
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Printf("✅ Прокси запущен: http://localhost:%s\n", port)
	fmt.Printf("→ Проксирует на: %s\n", target)
	fmt.Printf("\nВ плагине укажи API URL:\nhttp://localhost:%s/\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
