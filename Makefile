TITLE   := $(shell basename $(shell pwd))
IMAGE   := petewilcox/texlive:latest
LOGFILE := build.log
SRCDIR  := $(abspath $(CURDIR)/src)
IGNORE  := -n36 -n22 -n30
CMD     := pdflatex -synctex=1 -interaction=nonstopmode -shell-escape src

default: all

all: pull lint build clean

pull:
	docker pull ${IMAGE}

lint: pull
	echo "Linting..."; \
	for f in "${SRCDIR}/*.tex"; do \
		echo "- $f"; \
		docker run --rm \
			--name latex \
			-v "$(abspath $(CURDIR))"/:/mnt \
			--entrypoint=/bin/bash \
			${IMAGE} -c \
			"chktex -eall -I ${IGNORE} /mnt/$f" | tee chktex.log; \
	done

build:
	echo "Building..."; \
	docker run --rm \
		--name latex \
		-v "$(abspath $(CURDIR))"/:/mnt \
		-w /mnt/src \
		--entrypoint=/bin/bash \
		${IMAGE} -c \
		"${CMD}; ${CMD}; ${CMD}" | tee build.log
	mv ${SRCDIR}/src.pdf ${TITLE}.pdf
	echo "SUCCESS"

clean:
	@-rm -f ${SRCDIR}/_minted-src
	@-rm -f ${SRCDIR}/*.aux
	@-rm -f ${SRCDIR}/*.bbl
	@-rm -f ${SRCDIR}/*.blg
	@-rm -f ${SRCDIR}/*.synctex.gz
	@-rm -f ${SRCDIR}/*.log
	@-rm -f ${SRCDIR}/*.out

.PHONY: default build clean all pull lint
