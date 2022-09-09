LFILE = README
VIGNETTE = notyet

all: init readme # vignette

init:
	echo "pkgdown::init_site()" | R --no-save -q

readme:
	echo "pkgdown::build_home(preview=FALSE,,quiet=FALSE)" | R --no-save -q

vignette:
	echo "pkgdown::build_article('$(VIGNETTE)',quiet=FALSE)" | R --no-save -q


knith: $(LFILE).Rmd
	echo "rmarkdown::render('$(LFILE).Rmd',output_file='$(LFILE).html')" | R --no-save -q

knitr: $(LFILE).Rmd
	echo "rmarkdown::render('$(LFILE).Rmd',output_format=rmarkdown::md_document(variant='gfm'))" | R --no-save -q

open:
	xdg-open docs/index.html &

check:
	Rscript -e 'library(pkgcheck); checks <- pkgcheck(); print(checks); summary (checks)'

insert: $(YFILE).R
	Rscript $(YFILE).R

clean:
	rm -rf *.html *.png README_cache docs
