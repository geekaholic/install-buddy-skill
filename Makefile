DIST_DIR := dist
BUNDLE   := $(DIST_DIR)/install-buddy.tar.gz
SOURCES  := SKILL.md \
            scripts/detect_os.sh \
            assets/example-config.yaml \
            references/package-name-map.md \
            references/safeguards.md

.PHONY: bundle clean check-bundle

bundle: $(BUNDLE)

$(BUNDLE): $(SOURCES) | $(DIST_DIR)
	@tmpdir=$$(mktemp -d); \
	mkdir -p "$$tmpdir/install-buddy/scripts" \
	         "$$tmpdir/install-buddy/assets" \
	         "$$tmpdir/install-buddy/references"; \
	cp SKILL.md                         "$$tmpdir/install-buddy/"; \
	cp scripts/detect_os.sh             "$$tmpdir/install-buddy/scripts/"; \
	chmod +x "$$tmpdir/install-buddy/scripts/detect_os.sh"; \
	cp assets/example-config.yaml       "$$tmpdir/install-buddy/assets/"; \
	cp references/package-name-map.md   "$$tmpdir/install-buddy/references/"; \
	cp references/safeguards.md         "$$tmpdir/install-buddy/references/"; \
	tar -czf $(BUNDLE) -C "$$tmpdir" install-buddy; \
	rm -rf "$$tmpdir"
	@echo "Built: $(BUNDLE)"

$(DIST_DIR):
	mkdir -p $(DIST_DIR)

clean:
	rm -f $(BUNDLE)

check-bundle: $(BUNDLE)
	@tar -tzf $(BUNDLE) | sort
