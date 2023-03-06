package cmw

import "errors"

type Type uint

const (
	JSONArray = Type(iota)
	CBORArray
	CBORTag
	Unknown
)

func identify(b []byte) Type {
	if len(b) == 0 {
		return Unknown
	}

	switch b[0] {
	case 0x82:
		return CBORArray
	case 0xda:
		return CBORTag
	case 0x5b:
		return JSONArray
	}

	return Unknown
}

const CMWMinSize = 10

type CMW struct {
	Type  interface{}
	Value []byte
}

func cborArrayDecode(b []byte) (CMW, error) {
	return CMW{}, errors.New("TODO")
}

func jsonArrayDecode(b []byte) (CMW, error) {
	return CMW{}, errors.New("TODO")
}

func cborTagDecode(b []byte) (CMW, error) {
	return CMW{}, errors.New("TODO")
}

func CMWDecode(b []byte) (CMW, error) {
	if len(b) < CMWMinSize {
		return CMW{}, errors.New("CMW too short")
	}

	switch b[0] {
	case 0x82:
		return cborArrayDecode(b)
	case 0x5b:
		return jsonArrayDecode(b)
	default:
		return cborTagDecode(b)
	}
}
