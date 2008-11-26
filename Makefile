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
	./fixup.sh -f

localdiff:
	./diff.sh
