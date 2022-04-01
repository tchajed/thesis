func (l *Wal) Read(a uint64) Block {
	b, ok := l.ReadMem(a)
	if ok {
		return b
	}
	return l.ReadInstalled(a)
}

func (l *Wal) ReadMem(a) (Block, bool) {
	l.Lock()
	// get b from in-memory log, if present
	l.Unlock()
	return b, ok
}

func (l *Wal) ReadInstalled(a uint64) Block {
	return disk.Read(a)
}
