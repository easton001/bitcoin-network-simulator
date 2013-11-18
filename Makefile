COFFEE := coffee

coffee_files := $(shell find src -iname "*.coffee")
js_files := $(patsubst src/%.coffee,build/node/%.js,$(coffee_files)) build/package.js
static_files := $(shell find static -iname '*.js')
html_source_files := $(shell find www -iname '*.html')
html_files := $(patsubst www/%.html,build/%.html,$(html_source_files))

all : $(js_files) $(html_files)

build:
	mkdir -p build

build/node/%.js: src/%.coffee | build
	$(COFFEE) -o build -c $^

build/package.js: $(coffee_files) $(static_files) build.coffee | build
	$(COFFEE) build.coffee

build/%.html: www/%.html | build
	cp $^ $@

clean:
	rm -rf build

.PHONY: all clean
