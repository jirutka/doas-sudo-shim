SCRIPT_NAME  := sudo

prefix       := $(or $(prefix),$(PREFIX),/usr/local)
bindir       := $(prefix)/bin
mandir       := $(prefix)/share/man

ASCIIDOCTOR  := asciidoctor
INSTALL      := install
GIT          := git
SED          := sed

MAKEFILE_PATH = $(lastword $(MAKEFILE_LIST))


#: Print list of targets.
help:
	@printf '%s\n\n' 'List of targets:'
	@$(SED) -En '/^#:.*/{ N; s/^#: (.*)\n([A-Za-z0-9_-]+).*/\2 \1/p }' $(MAKEFILE_PATH) \
		| while read label desc; do printf '%-15s %s\n' "$$label" "$$desc"; done

#: Install the script and man page into $DESTDIR/$prefix.
install: install-exec install-man

#: Install the script into $DESTDIR/$bindir.
install-exec:
	mkdir -p $(DESTDIR)$(bindir)
	install -m 755 $(SCRIPT_NAME) $(DESTDIR)$(bindir)/$(SCRIPT_NAME)

#: Install the man page into $DESTDIR/$mandir/man1.
install-man: $(SCRIPT_NAME).1
	mkdir -p $(DESTDIR)$(mandir)/man1
	install -m 644 $(SCRIPT_NAME).1 $(DESTDIR)$(mandir)/man1/$(SCRIPT_NAME).1

#: Generate a man page (requires asciidoctor).
man: $(SCRIPT_NAME).1

#: Uninstall the script from $DESTDIR.
uninstall:
	rm -f "$(DESTDIR)$(bindir)/$(SCRIPT_NAME)"
	rm -f "$(DESTDIR)$(mandir)/man1/$(SCRIPT_NAME).1"

#: Update version in README.adoc to $VERSION.
bump-version:
	test -n "$(VERSION)"  # $$VERSION
	$(SED) -E -i "s/^(:version:).*/\1 $(VERSION)/" README.adoc

#: Bump version to $VERSION, create release commit and tag.
release: .check-git-clean | bump-version
	test -n "$(VERSION)"  # $$VERSION
	$(GIT) add .
	$(GIT) commit -m "Release version $(VERSION)"
	$(GIT) tag -s v$(VERSION) -m v$(VERSION)


# Convert a man page.
$(SCRIPT_NAME).1: $(SCRIPT_NAME).1.adoc
	$(ASCIIDOCTOR) -b manpage $(SCRIPT_NAME).1.adoc

# Target for compatibility with GNU convention.
install-data: install-man

.check-git-clean:
	@test -z "$(shell $(GIT) status --porcelain)" \
		|| { echo 'You have uncommitted changes!' >&2; exit 1; }

.PHONY: help install install-exec install-man man uninstall bump-version \
	release .check-git-clean
