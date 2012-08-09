#
# Octave script which reads commands from a named pipe.
#

# If the variable 'fifofile' exists, then use it, so that we
# can continue to use the same pipe.
# Otherwise, create a file with a random name.
# In both cases, tell the user the name of the pipe.
if exist('fifofile','var')
	fifofile
else
	fifofile = sprintf('/tmp/%06d.fifo',floor(rand*1000000))
endif
fflush(stdout);

# If the pipe exists, remove it.
if exist(fifofile,'file')
	unlink(fifofile);
endif

# Create the pipe and open it.
mkfifo(fifofile,420);
f = fopen(fifofile,'r');

# Continually read from the pipe and eval each line.
while ~feof(f)
	line = fgetl(f);
	eval(line);
	fflush(stdout);
end

# Close and remove the pipe.
fclose(f);
unlink(fifofile);
