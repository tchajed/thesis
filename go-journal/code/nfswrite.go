func NFS3_WRITE(args WRITE3args) WRITE3res {
  inum := fh2ino(args.File)
  if !validInum(inum) {
    return WRITE3res{Status: NFS3ERR_INVAL}
  }
  inode_locks.Acquire(inum)
  reply := NFS3_WRITE_locked(args, inum)
  inode_locks.Release(inum)
  return reply
}

func NFS3_WRITE_locked(args WRITE3args,
    inum Inum) (reply WRITE3res) {
  op := Begin()
  if !NFS3_WRITE_op(op, args, inum, &reply) {
    return
  }
  if txn.Commit(true) {
    reply.Status = NFS3_OK
  } else {
    reply.Status = NFS3ERR_SERVERFAULT
  }
  return
}
