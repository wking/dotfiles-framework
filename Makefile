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

fixup:
	./fixup.sh

update:
	./update.sh

merge:
	./merge.sh

override:
	./fixup.sh --force

# Print a diff between the local installation and .dotfiles
# i.e. What changes will `make override' effect
localdiff:
	./diff.sh --local

# Save a diff between .dotfiles and the local installation
# i.e. What specialization do I want compared to the central .dotfiles
localpatch:
	./diff.sh > local.patch
