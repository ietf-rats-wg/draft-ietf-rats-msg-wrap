package cmw

import "testing"

func Test_identify(t *testing.T) {
	type args struct {
		b []byte
	}
	tests := []struct {
		name string
		args args
		want Type
	}{
		{
			"JSON array with CoAP C-F",
			args{[]byte(`[30001, "3q2+7w"]`)},
			JSONArray,
		},
		{
			"JSON array with media type string",
			args{[]byte(`["application/vnd.intel.sgx", "3q2+7w"]`)},
			JSONArray,
		},
		{
			"CBOR array with CoAP C-F",
			// echo "[30001, h'deadbeef']" | diag2cbor.rb | xxd -p -i
			args{[]byte{0x82, 0x19, 0x75, 0x31, 0x44, 0xde, 0xad, 0xbe, 0xef}},
			CBORArray,
		},
		{
			"CBOR array with media type string",
			// echo "[\"application/vnd.intel.sgx\", h'deadbeef']" | diag2cbor.rb | xxd -p -i
			args{
				[]byte{
					0x82, 0x78, 0x19, 0x61, 0x70, 0x70, 0x6c, 0x69, 0x63, 0x61,
					0x74, 0x69, 0x6f, 0x6e, 0x2f, 0x76, 0x6e, 0x64, 0x2e, 0x69,
					0x6e, 0x74, 0x65, 0x6c, 0x2e, 0x73, 0x67, 0x78, 0x44, 0xde,
					0xad, 0xbe, 0xef,
				},
			},
			CBORArray,
		},
		{
			"CBOR tag",
			// echo "1668576818(h'deadbeef')" | diag2cbor.rb| xxd -p -i
			args{
				[]byte{
					0xda, 0x63, 0x74, 0x76, 0x32, 0x44, 0xde, 0xad, 0xbe, 0xef,
				},
			},
			CBORTag,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := identify(tt.args.b); got != tt.want {
				t.Errorf("[TC: %s] identify() = %v, want %v", tt.name, got, tt.want)
			}
		})
	}
}
