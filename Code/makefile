# =============================================================================
# Project makefile
# =============================================================================

# Settings
objs = keyb.obj gfx.obj fileh.obj genl.obj rand.obj project.obj
dest = project.exe

# =============================================================================
# Do NOT edit this section, unless you know what you are doing.
# =============================================================================
.asm.obj
  tasm /ml /m2 /w2 /z /zi /p /jIDEAL $<

$(dest): $(objs)
#  wlink option quiet system pmodew name $@ file {$(objs)}
  wlink option quiet system pmodew name $@ file *.obj

clean: .symbolic
  del *.obj
  del $(dest)

.silent
debug: $(objs) .symbolic
  wlink debug watcom lines option Q,C system pmodew name $(dest) file *.obj
  wd /tr=rsi /li=43 $(dest)