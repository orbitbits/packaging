BRANCH := $(shell git branch --show-current 2>/dev/null || echo "unknown")
REMOTES := $(shell git remote 2>/dev/null || echo "")
.DEFAULT_GOAL := help

.PHONY: help build apt rpm index jekyll-build jekyll-serve clean serve push push-lease

help:
	@echo "Options:"
	@echo
	@echo "  make build      -> Build package repositories and Jekyll site into public/"
	@echo "  make apt        -> Build only the APT repository"
	@echo "  make rpm        -> Build only the RPM repository"
	@echo "  make index      -> Generate directory index.html files"
	@echo "  make jekyll-build -> Build only the Jekyll site"
	@echo "  make jekyll-serve -> Serve Jekyll locally"
	@echo "  make serve      -> Alias for make jekyll-serve"
	@echo "  make clean      -> Remove generated output"
	@echo
	@echo "  make push       -> Push the current branch to all remotes"
	@echo "  make push-lease -> Force-push with lease to all remotes"

build:
	@ruby tools/rb/build_all.rb
	@$(MAKE) jekyll-build

apt:
	@ruby tools/rb/build_apt_repo.rb

rpm:
	@ruby tools/rb/build_rpm_repo.rb

index:
	@$(MAKE) jekyll-build

jekyll-build:
	@ruby tools/rb/generate_directory_pages.rb public _pages
	@bundle exec jekyll build

jekyll-serve:
	@ruby tools/rb/generate_directory_pages.rb public _pages
	@bundle exec jekyll serve --livereload

serve: jekyll-serve

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
