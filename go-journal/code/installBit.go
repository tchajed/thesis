// Install 1 bit from src into dst, at offset bit. return new dst.
func installOneBit(src byte, dst byte, bit uint64) byte {
	var new byte = dst
	if src&(1<<bit) != dst&(1<<bit) {
		if src&(1<<bit) == 0 {
			// dst is 1, but should be 0
			new = new & ^(1 << bit)
		} else {
			// dst is 0, but should be 1
			new = new | (1 << bit)
		}
	}
	return new
}
