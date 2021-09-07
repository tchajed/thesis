func NFS3_WRITE_op(op *Op, args WRITE3args,
    inum Inum, reply *WRITE3res) bool {
  ip := ReadInode(op, inum)
  count, ok := ip.Write(op, args.Offset,
        args.Count, args.Data)
  ... // set count and status
}

func (ip *Inode) Write(op *Op, off uint64,
    count uint64, data []byte) (uint64, bool) {
  if count != uint64(len(data)) ||
     util.SumOverflows(off, count) ||
     off+count > disk.BlockSize ||
     off > ip.Size {
    return 0, false
  }

  buf := op.ReadBuf(block2addr(ip.Data),
        NBITBLOCK)
  copy(buf.Data[off:], data)
  buf.SetDirty()
  if off+count > ip.Size {
    ip.Size = off + count
    ip.WriteInode(op)
  }
  return count, true
}

func (ip *Inode) WriteInode(op *Op) {
  op.OverWrite(inum2Addr(ip.Inum),
    INODESZ*8, ip.Encode())
}
