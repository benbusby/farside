package services

import (
	"errors"
	"math/rand"
	"regexp"
)

type RegexMapping struct {
	Pattern *regexp.Regexp
	Targets []string
}

var regexMap = []RegexMapping{
	{
		// YouTube
		Pattern: regexp.MustCompile(`youtu(\.be|be\.com)|invidious|piped`),
		Targets: []string{"piped", "invidious"},
	},
	{
		// Twitter / X
		Pattern: regexp.MustCompile(`twitter\.com|x\.com|nitter`),
		Targets: []string{"nitter"},
	},
	{
		// Reddit
		Pattern: regexp.MustCompile(`reddit\.com|libreddit|redlib|teddit`),
		Targets: []string{"libreddit", "redlib", "teddit"},
	},
	{
		// Google Search
		Pattern: regexp.MustCompile(`google\.com|whoogle|searx|searxng`),
		Targets: []string{"whoogle", "searx", "searxng"},
	},
	{
		// Instagram
		Pattern: regexp.MustCompile(`instagram\.com|proxigram`),
		Targets: []string{"proxigram"},
	},
	{
		// Wikipedia
		Pattern: regexp.MustCompile(`wikipedia\.org|wikiless`),
		Targets: []string{"wikiless"},
	},
	{
		// Medium
		Pattern: regexp.MustCompile(`medium\.com|scribe`),
		Targets: []string{"scribe"},
	},
	{
		// Odysee
		Pattern: regexp.MustCompile(`odysee\.com|librarian`),
		Targets: []string{"librarian"},
	},
	{
		// Imgur
		Pattern: regexp.MustCompile(`imgur\.com|rimgo`),
		Targets: []string{"rimgo"},
	},
	{
		// Google Translate
		Pattern: regexp.MustCompile(`translate\.google\.com|lingva|simplytranslate`),
		Targets: []string{"lingva", "simplytranslate"},
	},
	{
		// TikTok
		Pattern: regexp.MustCompile(`tiktok\.com|proxitok`),
		Targets: []string{"proxitok"},
	},
	{
		// Fandom
		Pattern: regexp.MustCompile(`.*fandom\.com|breezewiki`),
		Targets: []string{"breezewiki"},
	},
	{
		// IMDB
		Pattern: regexp.MustCompile(`imdb\.com|libremdb`),
		Targets: []string{"libremdb"},
	},
	{
		// Quora
		Pattern: regexp.MustCompile(`quora\.com|quetre`),
		Targets: []string{"quetre"},
	},
	{
		// GitHub
		Pattern: regexp.MustCompile(`github\.com|gothub`),
		Targets: []string{"gothub"},
	},
	{
		// StackOverflow
		Pattern: regexp.MustCompile(`stackoverflow\.com|anonymousoverflow`),
		Targets: []string{"anonymousoverflow"},
	},
	{
		// Genius
		Pattern: regexp.MustCompile(`genius\.com|dumb`),
		Targets: []string{"dumb"},
	},
}

func MatchRequest(service string) (string, error) {
	for _, mapping := range regexMap {
		hasMatch := mapping.Pattern.MatchString(service)
		if !hasMatch {
			continue
		}

		index := rand.Intn(len(mapping.Targets))
		value := mapping.Targets[index]
		return value, nil
	}

	return "", errors.New("no match found")
}
