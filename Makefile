BASEDIR=$(CURDIR)
OUTPUTDIR=$(BASEDIR)/public
GITHUB_PAGES_BRANCH=master

github: publish
	ghp-import -m "Generate Hugo site" -b $(GITHUB_PAGES_BRANCH) $(OUTPUTDIR)
	git push origin $(GITHUB_PAGES_BRANCH)

.PHONY: github
