package ru.redspell.lightning;

import java.io.FileDescriptor;
import ru.redspell.lightning.utils.Log;


class ResourceParams {
	public FileDescriptor fd;
	public long startOffset;
	public long length;

	public ResourceParams(FileDescriptor fd,long startOffset,long length) {
		this.fd = fd;
		this.startOffset = startOffset;
		this.length = length;
		Log.d("RESPARAMS","startOffset: " + this.startOffset + ", length: " + this.length);
	}

}
