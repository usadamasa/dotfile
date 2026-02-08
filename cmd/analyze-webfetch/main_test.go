package main

import (
	"encoding/json"
	"testing"
)

func TestGenerateReport(t *testing.T) {
	t.Run("generates report with recommendations", func(t *testing.T) {
		scanResults := []ScanResult{
			{URL: "https://github.com/foo", Domain: "github.com", FilePath: "a.jsonl"},
			{URL: "https://github.com/bar", Domain: "github.com", FilePath: "a.jsonl"},
			{URL: "https://docs.new-lib.io/api", Domain: "docs.new-lib.io", FilePath: "a.jsonl"},
			{URL: "https://stackoverflow.com/q/123", Domain: "stackoverflow.com", FilePath: "b.jsonl"},
			{URL: "https://random-site.xyz/page", Domain: "random-site.xyz", FilePath: "b.jsonl"},
		}
		allowlist := []AllowlistEntry{
			{Tool: "WebFetch", Domain: "github.com"},
			{Tool: "WebFetch", Domain: "docs.unused.com"},
		}

		report := GenerateReport(scanResults, allowlist, 30, 2)

		// Verify metadata
		if report.Metadata.DaysAnalyzed != 30 {
			t.Errorf("expected days_analyzed=30, got %d", report.Metadata.DaysAnalyzed)
		}
		if report.Metadata.FilesScanned != 2 {
			t.Errorf("expected files_scanned=2, got %d", report.Metadata.FilesScanned)
		}
		if report.Metadata.WebFetchCalls != 5 {
			t.Errorf("expected webfetch_calls=5, got %d", report.Metadata.WebFetchCalls)
		}

		// Verify current allowlist
		if len(report.CurrentAllowlist) != 2 {
			t.Fatalf("expected 2 allowlist entries, got %d", len(report.CurrentAllowlist))
		}

		// Verify add recommendations (safe domains not in allowlist)
		foundNewLib := false
		for _, rec := range report.Recommendations.Add {
			if rec.Domain == "docs.new-lib.io" {
				foundNewLib = true
				if rec.Category != CategorySafe {
					t.Errorf("expected docs.new-lib.io to be safe, got %s", rec.Category)
				}
			}
		}
		if !foundNewLib {
			t.Error("expected docs.new-lib.io in add recommendations")
		}

		// Verify review recommendations (medium/review domains not in allowlist)
		foundSO := false
		for _, rec := range report.Recommendations.Review {
			if rec.Domain == "stackoverflow.com" {
				foundSO = true
			}
		}
		if !foundSO {
			t.Error("expected stackoverflow.com in review recommendations")
		}

		// Verify unused domains
		foundUnused := false
		for _, rec := range report.Recommendations.Unused {
			if rec.Domain == "docs.unused.com" {
				foundUnused = true
			}
		}
		if !foundUnused {
			t.Error("expected docs.unused.com in unused recommendations")
		}

		// Verify all_domains list
		if len(report.AllDomains) != 4 {
			t.Errorf("expected 4 domains in all_domains, got %d", len(report.AllDomains))
		}
	})

	t.Run("report is valid JSON", func(t *testing.T) {
		report := GenerateReport(nil, nil, 30, 0)

		data, err := json.Marshal(report)
		if err != nil {
			t.Fatalf("report is not valid JSON: %v", err)
		}
		if len(data) == 0 {
			t.Error("expected non-empty JSON output")
		}
	})
}
