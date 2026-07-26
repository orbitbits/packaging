BRANCH := $(shell git branch --show-current 2>/dev/null || echo "unknown")
REMOTES := $(shell git remote 2>/dev/null || echo "")
.DEFAULT_GOAL := help

.PHONY: help build apt rpm index clean serve push push-lease

help:
	@echo "Options:"
	@echo
	@echo "  make build      -> Build package repositories and Jekyll site into public/"
	@echo "  make apt        -> Build only the APT repository"
	@echo "  make rpm        -> Build only the RPM repository"
	@echo "  make index      -> Generate directory index.html files"
	@echo "  make serve      -> Serve public/ locally on port 8080"
	@echo "  make clean      -> Remove generated output"
	@echo
	@echo "  make push       -> Push the current branch to all remotes"
	@echo "  make push-lease -> Force-push with lease to all remotes"

build:
	@ruby tools/rb/build_all.rb
	@ruby tools/rb/generate_directory_pages.rb public _pages
	@bundle exec jekyll build

apt:
	@ruby tools/rb/build_apt_repo.rb

rpm:
	@ruby tools/rb/build_rpm_repo.rb

index:
	@ruby tools/rb/generate_directory_pages.rb public _pages
	@bundle exec jekyll build

serve:
	@cd public && python3 -m http.server 8080

clean:
	@rm -rf public

push:
	@echo "Push normal -> branch: $(BRANCH)"
	@for remote in $(REMOTES); do \
		echo "  pushing to $$remote..."; \
		git push $$remote $(BRANCH); \
	done

push-lease:
	@echo "Push --force-with-lease -> branch: $(BRANCH)"
	@for remote in $(REMOTES); do \
		echo "  pushing to $$remote..."; \
		git push --force-with-lease $$remote $(BRANCH); \
	done
