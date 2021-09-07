func (op *Op) installBufsMap(bufs []*Buf) map[Bnum]Block {
	blks := make(map[Bnum]Block)

	for _, b := range bufs {
		// no need to read the old block if writing a whole block
		if b.Sz == NBITBLOCK {
			blks[b.Addr.Blkno] = b.Data
		} else {
			var blk Block
			mapblk, ok := blks[b.Addr.Blkno]
			if ok {
				// we've already read this block, update it again in-place
				blk = mapblk
			} else {
				// read this address for the first time and cache it
				blk = op.log.Read(b.Addr.Blkno)
				blks[b.Addr.Blkno] = blk
			}
			// write the data in b to the correct offset in blk
			b.Install(blk)
		}
	}

	return blks
}
