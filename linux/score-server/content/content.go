// Package content provides an importable embed.FS for other, outer packages to use
package content

import "embed"

//go:embed all:*
var Content embed.FS
