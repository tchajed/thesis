type Update struct {
	Addr uint64
	Data Block
}

func (l *Wal) install() {
	l.Lock()
	installEnd := l.diskEnd
	// grab all the logged updates from memory
	var bufs []Update = l.memLog.takeTill(installEnd)
	l.Unlock()

	// install bufs to data region lock-free
	installBlocks(bufs)
	// trim the circular buffer lock-free
	circ.Advance(installEnd)

	l.Lock()
	// now trim the in-memory log
	l.memLog.trimTill(installEnd)
	l.Unlock()
}
