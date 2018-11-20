LFILE = ms-meetup-nov18

all: knith 

knith: $(LFILE).Rmd
	echo "rmarkdown::render('$(LFILE).Rmd',output_file='$(LFILE).html')" | R --no-save -q

open: $(LFILE).html
	xdg-open $(LFILE).html &

deploy:
	rm docs/slides/img/*; \
	cp img/*.png docs/slides/img/.; \
	rm -r docs/slides/libs docs/slides/ms-meetup-nov18_cache; \
	rm -r docs/slides/ms-meetup-nov18_files; \
	rm docs/slides/xaringan-themer.css; \
	cp -r ms-meetup-nov18_cache docs/slides; \
	cp -r ms-meetup-nov18_files docs/slides; \
	cp -r libs docs/slides; \
	cp ms-meetup-nov18.html docs/slides/.; \
	cp xaringan-themer.css docs/slides/; \
	git add docs/slides/img/.; \
	git add docs/slides/ms-meetup-nov18_files/.; \
	git add docs/slides/ms-meetup-nov18_cache/.; \
	git add docs/slides/ms-meetup-nove18.html

clean:
	rm -rf *.html xaringan-themer.css *_cache *_files
