# ~/.dotfiles/Makefile
#
# all:
# Link all the files we have in this directory into the parent.
#
# clean:
# Clean editted files.
#
# Original by Steve Kemp (http://www.steve.org.uk)

all: fixup

clean:
	find . -name '*~' -exec rm -f \{\} \;
	find . -name '.#*' -exec rm -f \{\} \;

diff:
	git diff

# Link each _FILE in the current directory to ~/.FILE
fixup: update
	./fixup.sh

# By default, fixup only replaces missing files and simlinks.  You can
# optionally overwrite any local files and directories by passing the
# --force option.
override:
	./fixup.sh --force

# Get the current dotfiles from the server using a variety of methods.
update:
	./update.sh

# Print a diff between the local installation and .dotfiles
# i.e. What changes will `make override' effect
localdiff:
	./diff.sh --local

# Save a diff between .dotfiles and the local installation
# i.e. What specialization do I want compared to the central .dotfiles
localpatch:
	./diff.sh > local.patch

# No Remove this computer from the auto-updates list
disconnect:
	./disconnect.sh
