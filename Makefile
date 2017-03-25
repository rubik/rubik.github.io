BASEDIR=$(CURDIR)
OUTPUTDIR=$(BASEDIR)/public

HUGO=hugo
HUGO_THEME=hugo-zen

GITHUB_PAGES_BRANCH=master

publish:
	$(HUGO) $(BASEDIR) -o $(OUTPUTDIR) -t $(HUGO_THEME)

github: publish
	ghp-import -m "Generate Hugo site" -b $(GITHUB_PAGES_BRANCH) $(OUTPUTDIR)
	git push origin $(GITHUB_PAGES_BRANCH)

.PHONY: publish github
