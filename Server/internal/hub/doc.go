// Package hub will own per-document sequencing and client fan-out.
//
// The relay deliberately treats operation payloads as opaque bytes. No CRDT state or
// merge behavior belongs in this package.
package hub
