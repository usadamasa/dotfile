package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"time"
)

// Report is the top-level output structure.
type Report struct {
	Metadata        ReportMetadata   `json:"metadata"`
	CurrentAllowlist []string        `json:"current_allowlist"`
	Recommendations Recommendations  `json:"recommendations"`
	AllDomains      []DomainSummary  `json:"all_domains"`
}

// ReportMetadata holds summary statistics about the analysis.
type ReportMetadata struct {
	AnalysisDate  string `json:"analysis_date"`
	DaysAnalyzed  int    `json:"days_analyzed"`
	FilesScanned  int    `json:"files_scanned"`
	WebFetchCalls int    `json:"webfetch_calls"`
}

// Recommendations contains categorized domain suggestions.
type Recommendations struct {
	Add    []DomainRecommendation `json:"add"`
	Review []DomainRecommendation `json:"review"`
	Unused []UnusedDomain         `json:"unused"`
}

// DomainRecommendation represents a domain suggested for addition or review.
type DomainRecommendation struct {
	Domain   string   `json:"domain"`
	Count    int      `json:"count"`
	Category Category `json:"category"`
	Reason   string   `json:"reason"`
}

// UnusedDomain represents an allowlisted domain not seen in recent usage.
type UnusedDomain struct {
	Domain      string `json:"domain"`
	InAllowlist bool   `json:"in_allowlist"`
	Count       int    `json:"count"`
	Note        string `json:"note"`
}

// DomainSummary is a combined view of a domain's usage and status.
type DomainSummary struct {
	Domain      string   `json:"domain"`
	Count       int      `json:"count"`
	Category    Category `json:"category"`
	InAllowlist bool     `json:"in_allowlist"`
}

// GenerateReport creates a Report from scan results and the current allowlist.
func GenerateReport(scanResults []ScanResult, allowlist []AllowlistEntry, days int, filesScanned int) Report {
	// Count domains.
	domainCounts := make(map[string]int)
	for _, r := range scanResults {
		domainCounts[r.Domain]++
	}

	// Build allowlist lookup.
	allowlistSet := make(map[string]bool)
	var allowlistDomains []string
	for _, e := range allowlist {
		allowlistSet[e.Domain] = true
		allowlistDomains = append(allowlistDomains, e.Domain)
	}
	sort.Strings(allowlistDomains)

	// Classify all domains.
	var allDomains []DomainSummary
	var addRecs []DomainRecommendation
	var reviewRecs []DomainRecommendation

	for domain, count := range domainCounts {
		cat := CategorizeDomain(domain)
		inAllowlist := domainMatchesAllowlist(domain, allowlistSet)

		allDomains = append(allDomains, DomainSummary{
			Domain:      domain,
			Count:       count,
			Category:    cat.Category,
			InAllowlist: inAllowlist,
		})

		if !inAllowlist {
			rec := DomainRecommendation{
				Domain:   domain,
				Count:    count,
				Category: cat.Category,
				Reason:   cat.Reason,
			}
			switch cat.Category {
			case CategorySafe:
				addRecs = append(addRecs, rec)
			case CategoryMedium, CategoryReview:
				reviewRecs = append(reviewRecs, rec)
			}
		}
	}

	// Find unused allowlist entries.
	var unusedRecs []UnusedDomain
	for _, domain := range allowlistDomains {
		if domainCounts[domain] == 0 {
			unusedRecs = append(unusedRecs, UnusedDomain{
				Domain:      domain,
				InAllowlist: true,
				Count:       0,
				Note:        fmt.Sprintf("過去%d日間使用なし", days),
			})
		}
	}

	// Sort outputs for deterministic results.
	sort.Slice(allDomains, func(i, j int) bool { return allDomains[i].Count > allDomains[j].Count })
	sort.Slice(addRecs, func(i, j int) bool { return addRecs[i].Count > addRecs[j].Count })
	sort.Slice(reviewRecs, func(i, j int) bool { return reviewRecs[i].Count > reviewRecs[j].Count })

	return Report{
		Metadata: ReportMetadata{
			AnalysisDate:  time.Now().Format("2006-01-02"),
			DaysAnalyzed:  days,
			FilesScanned:  filesScanned,
			WebFetchCalls: len(scanResults),
		},
		CurrentAllowlist: allowlistDomains,
		Recommendations: Recommendations{
			Add:    addRecs,
			Review: reviewRecs,
			Unused: unusedRecs,
		},
		AllDomains: allDomains,
	}
}

// domainMatchesAllowlist checks if a domain is covered by any entry in the allowlist,
// including wildcard entries like *.example.com.
func domainMatchesAllowlist(domain string, allowlistSet map[string]bool) bool {
	if allowlistSet[domain] {
		return true
	}
	// Check wildcard entries.
	parts := splitDomain(domain)
	for i := 1; i < len(parts); i++ {
		wildcard := "*." + joinDomain(parts[i:])
		if allowlistSet[wildcard] {
			return true
		}
	}
	return false
}

func splitDomain(domain string) []string {
	var parts []string
	for _, p := range filepath.SplitList(domain) {
		for _, s := range split(p, '.') {
			parts = append(parts, s)
		}
	}
	return parts
}

func joinDomain(parts []string) string {
	result := ""
	for i, p := range parts {
		if i > 0 {
			result += "."
		}
		result += p
	}
	return result
}

func split(s string, sep byte) []string {
	var parts []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == sep {
			parts = append(parts, s[start:i])
			start = i + 1
		}
	}
	parts = append(parts, s[start:])
	return parts
}

// countUniqueFiles counts the number of unique file paths in scan results.
func countUniqueFiles(results []ScanResult) int {
	seen := make(map[string]bool)
	for _, r := range results {
		seen[r.FilePath] = true
	}
	return len(seen)
}

func main() {
	days := flag.Int("days", 30, "集計期間(日数)")
	settingsPath := flag.String("settings", "", "settings.json パス (デフォルト: ~/.claude/settings.json)")
	flag.Parse()

	if *settingsPath == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintf(os.Stderr, "ホームディレクトリの取得に失敗: %v\n", err)
			os.Exit(1)
		}
		*settingsPath = filepath.Join(home, ".claude", "settings.json")
	}

	projectsDir := filepath.Join(filepath.Dir(*settingsPath), "projects")

	// Load current allowlist.
	allowlist, err := LoadAllowlist(*settingsPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "settings.json の読み込みに失敗: %v\n", err)
		os.Exit(1)
	}

	// Scan JSONL files.
	scanResults, err := ScanJSONLFiles(projectsDir, *days)
	if err != nil {
		fmt.Fprintf(os.Stderr, "JSONL ファイルの走査に失敗: %v\n", err)
		os.Exit(1)
	}

	filesScanned := countUniqueFiles(scanResults)

	// Generate and output report.
	report := GenerateReport(scanResults, allowlist, *days, filesScanned)

	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		fmt.Fprintf(os.Stderr, "レポートの出力に失敗: %v\n", err)
		os.Exit(1)
	}
}
