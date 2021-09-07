func Append(txns) {
  // write data
  hdr := ... // prepare header
  disk.Write(LOGHDR, hdr)
  ...
}
