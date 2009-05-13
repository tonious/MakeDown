# -----------------------------------------------------------------------------------------------
# Tony's Massive Makefile.
# tony@thompson.name
#
# v 1.0 Initial Release
#
# This Makefile is intended to build largish PDF and HTML documents from
# markdown source.  It relies heavily on implicit rules; in most cases
# one must only specify dependancies.
#
# This is a non-recursive build system; only one instance of make is needed.
# The main advantage of this approach is that dependancy information is
# constant throughout the entire tree; this can lead to a substantial reduction
# in compie times.  Also, there are fewer spawned processes.  The disadvantage
# is that all make instantiations must be done from the root of the tree, i.e.:
# from this make file, not from any of the child makefiles.
# 
# Requires:
#   * LaTeX
#   * BibTeX
#   * pandoc
#   * bibtex2html
#
# Good to have:
#   * dot (graphviz)
#   * eps2pdf
#   * ps2pdf
#   * mini-httpd for built in web preview.


# -----------------------------------------------------------------------------------------------
# Global Variables

# List of all targets.  These will be built by 'make all', and deleted by 'make distclean'.
TARGETS :=

# List of files to clean with 'make clean'
CLEAN := 

# Set any global options here.
DOT_OPT	:= -Gfontname=Futura -Nfontname=Futura -Efontname=Futura

# Here to make it the first target.
# Reset at the bottom of this file.
all: $(TARGETS)


# -----------------------------------------------------------------------------------------------
# Recursion

# To include a subdirectory. 
#
# dir:=subdir
# include ($dir)/MakeFile

# In the included Makefile: 
# # Update recursion variables.
# d := $(dir)            # The path of the current working dir.
# sp := $(sp).x          # Stack index.
# dirstack_$(sp) := $(d) # Stack of directories.
#
# TARGET += object.o 
#
# $(d)/object.o: %d/object.c
#	cc $< -o $@
#
# # Recurse back up.
# sp := $(basename $(sp))
# d := $(dirstack_$(sp))

# -----------------------------------------------------------------------------------------------
# Cleaning and utility functions.

clean:
	$(RM) $(CLEAN)

distclean: 
	$(RM) $(CLEAN) $(TARGETS) 


# -----------------------------------------------------------------------------------------------
# File Converters for LaTeX

%.tex: %.mdwn
	 sed -e 's/\(cite:\)\([a-z0-9,]*\)/\\cite{\2}/' $< | pandoc -t latex -o $@ 

%.pdf: %.eps
	epstopdf $< > $@

%.eps: %.ps
	ps2eps -f -l -B $<

%.pdf: %.dot
	dot -Tpdf $(DOT_OPT) -o $@ $<

%.png: %.dot
	dot -Tpng $(DOT_OPT) -o $@ $<


# -----------------------------------------------------------------------------------------------
#  LaTeX itself.

REFGREP := grep "^LaTeX Warning: Label(s) may have changed."
BIBGREP := grep "^LaTeX Warning: There were undefined references."

%.aux %.pdf: %.tex 
	cd $(dir $*) && pdflatex $(notdir $*)
	cd $(dir $*) && (if $(BIBGREP) $(notdir $*.log); then bibtex $(notdir $*); pdflatex $(notdir $*); fi)
	cd $(dir $*) && (if $(BIBGREP) $(notdir $*.log); then pdflatex $(notdir $*); fi)
	cd $(dir $*) && (while $(REFGREP) $(notdir $*.log); do pdflatex $(notdir $*); done)


# -----------------------------------------------------------------------------------------------
# File Convertors for HTML 

%.html: %.mdwn
	pandoc -s -S $< -o $@

%.html %_abstracts.html %_bib.html: %.bib
	# Bibtex2html includes it's output path in relative URLs.
	cd $(dir $<) && bibtex2html -nofooter -a --use-keys --both --note annote -s apa $(notdir $<)

.html: %.aux
	aux2bib $< | bibtex2html -o $* -nofooter -s apa


# -----------------------------------------------------------------------------------------------
# Webserver for easy visualization.

startweb: 
	mini-httpd -p 8080 -d . -i web.pid
	
stopweb: web.pid
	kill `cat web.pid` && rm -f web.pid


# -----------------------------------------------------------------------------------------------
# This makes sure that all targets are still made.
all: $(TARGETS)
